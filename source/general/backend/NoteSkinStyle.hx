package general.backend;

import openfl.display.BitmapData;
import flixel.graphics.FlxGraphic;

/**
 * 音符贴图的着色体系判定。
 *
 * Psych 有两代音符贴图，两者的着色方式完全不能互换：
 *   rgb    —— 0.7 之后（1.0 / 1.1）：箭头本身是纯 R/G/B 三通道的掩码，颜色全部由 RGBPalette 决定；
 *   legacy —— 0.6.x 及更早、以及手绘皮肤：箭头颜色已经烤进贴图，只能用 ColorSwap 做 HSV 整体偏移。
 * 拿错体系的后果是花屏（RGB 打 legacy 会重映射通道；HSV 打掩码基本等于原图），所以必须判定。
 *
 * 判定顺序：
 *   1. images/&lt;skin&gt;.json 里的显式声明（皮肤作者说了算）；
 *   2. 自动甄别：取一张音符帧采样像素，纯通道像素占比够高就是 rgb。
 * 都定不下来时返回 null，由调用方（games.objects.Note.getNoteStyle）再退回谱面的 disableNoteRGB / 默认 rgb。
 *
 * 实测差异（2026-11，NovaFlare 自带皮肤）：
 *   noteSkins/NOTE_assets、-chip、-future   纯通道像素占 95.8~97.6%  → rgb
 *   noteSkins/NOTE_assets-Classic、-Stepmania 占 0%（白 5%~28%）     → legacy
 * 阈值取 35%，两头都留了足够余量。
 */
class NoteSkinStyle
{
	public static inline var RGB:String = 'rgb';
	public static inline var LEGACY:String = 'legacy';

	// 设置项（ClientPrefs.noteSystem / splashSystem）的三态取值。注意 RGB 是"体系名"，
	// 设置里存的第三项叫 new —— 两者语义相同，别混着比。
	public static inline var AUTO:String = 'auto';
	public static inline var NEW:String = 'new';

	// 引擎自带的旧版（0.6.x 布局）资源：**都在 images 根目录下**，不在 noteSkins/ / noteSplashes/ 里。
	// legacy 体系的第二级回退就是这两张：images/NOTE_assets.png、images/noteSplashes.png。
	public static inline var LEGACY_NOTE_SKIN:String = 'NOTE_assets';
	public static inline var LEGACY_SPLASH_SKIN:String = 'noteSplashes';

	/**
	 * images/&lt;skin&gt;.png 是否存在。回退链靠它判断"这一级能不能用"。
	 * pixel：null = 跟随 PlayState.isPixelStage（音符贴图在像素阶段带 pixelUI/ 前缀）；
	 *         splash 之类不走像素前缀的贴图显式传 false。
	 */
	public static function exists(skin:String, ?pixel:Bool = null):Bool
	{
		if (skin == null || skin.length < 1) return false;
		var usePixel:Bool = (pixel == null) ? PlayState.isPixelStage : pixel;
		var prefix:String = usePixel ? 'pixelUI/' : '';
		return Paths.fileExists('images/$prefix$skin.png', IMAGE);
	}

	/** 设置值 → 'auto' / 'legacy' / 'new'。认不出来（老存档 / 手改的 json）一律按 auto。 */
	public static function normalizeMode(value:String):String
	{
		if (value == null) return AUTO;
		switch (value.trim().toLowerCase())
		{
			case 'legacy', 'old', 'hsv': return LEGACY;
			case 'new', 'rgb', 'palette': return NEW;
		}
		return AUTO;
	}

	public static function noteMode():String return normalizeMode(ClientPrefs.data.noteSystem);
	public static function splashMode():String return normalizeMode(ClientPrefs.data.splashSystem);

	// 缓存里用 unknown 表示「判不出来」，避免每张音符都重算一遍
	static inline var UNKNOWN:String = 'unknown';

	static var cache:Map<String, String> = new Map();

	/** 只读皮肤 json 的显式声明，不做自动甄别。没有声明返回 null。 */
	public static function declared(skin:String):Null<String>
	{
		if (skin == null || skin.length < 1) return null;

		var cached:String = cache.get(skin);
		if (cached != null && cached != UNKNOWN) return cached;

		var style:String = readDeclared(skin);
		if (style == null) return null;

		cache.set(skin, style);
		return style;
	}

	/** 皮肤 json 的声明优先，其次自动甄别；都判不出来返回 null。结果按皮肤路径缓存。 */
	public static function resolve(skin:String):Null<String>
	{
		if (skin == null || skin.length < 1) return null;

		var cached:String = cache.get(skin);
		if (cached != null) return (cached == UNKNOWN) ? null : cached;

		var style:String = readDeclared(skin);
		if (style == null) style = detect(skin);

		cache.set(skin, style == null ? UNKNOWN : style);
		return style;
	}

	/** 皮肤声明变了（例如刚给皮肤补了 json）时清缓存；运行时基本用不到。 */
	public static function clearCache():Void cache.clear();

	/**
	 * 皮肤 json 的显式声明。三种写法都认：
	 *   { "noteStyle": "legacy" }   推荐
	 *   { "legacy": true }
	 *   { "rgb": false }
	 */
	static function readDeclared(skin:String):Null<String>
	{
		var jsonPath:String = 'images/$skin.json';
		if (!Paths.fileExists(jsonPath, TEXT)) return null;

		try
		{
			var data:Dynamic = haxe.Json.parse(Paths.getTextFromFile(jsonPath));
			if (data == null) return null;

			var style:Dynamic = Reflect.field(data, 'noteStyle');
			if (style != null)
			{
				switch (Std.string(style).toLowerCase())
				{
					case 'legacy', 'old', 'hsv': return LEGACY;
					case 'rgb', 'new', 'palette': return RGB;
				}
			}

			var legacy:Dynamic = Reflect.field(data, 'legacy');
			if (Std.isOfType(legacy, Bool)) return (legacy == true) ? LEGACY : RGB;

			var rgb:Dynamic = Reflect.field(data, 'rgb');
			if (Std.isOfType(rgb, Bool)) return (rgb == true) ? RGB : LEGACY;
		}
		catch (e:Dynamic)
		{
			trace('NoteSkinStyle: 解析 $jsonPath 失败 ($e)');
		}
		return null;
	}

	/**
	 * 像素甄别。优先用已经载入的贴图（预载路径 allowGPU=false，CPU 像素还在）；被 GPU Caching
	 * 摘掉 CPU 像素时再从磁盘临时解一份 —— 直接对不可读的 BitmapData 取像素会静默返回 0，
	 * 那样每张 RGB 皮肤都会被误判成 legacy。
	 */
	static function detect(skin:String):Null<String>
	{
		#if sys
		// 像素皮肤是 4×5 方格图集、没有 xml，且引擎一直按 RGB 处理，自动甄别交给 json 声明
		if (skin.indexOf('pixelUI/') >= 0) return null;

		var imagePath:String = Paths.getPath('images/$skin.png', IMAGE);
		if (imagePath == null || !FileSystem.exists(imagePath)) return null;

		var graphic:FlxGraphic = Paths.image(skin, null, false);
		var bitmap:BitmapData = (graphic != null && graphic.bitmap != null && graphic.bitmap.readable) ? graphic.bitmap : null;
		var temporary:Bool = false;

		if (bitmap == null)
		{
			try
			{
				bitmap = BitmapData.fromFile(imagePath);
			}
			catch (e:Dynamic)
			{
				return null;
			}
			temporary = true;
		}
		if (bitmap == null) return null;

		var rect:Array<Int> = findSampleFrame('images/$skin.xml', bitmap.width, bitmap.height);
		var style:Null<String> = analyze(bitmap, rect[0], rect[1], rect[2], rect[3]);
		if (temporary) bitmap.dispose();
		return style;
		#else
		return null;
		#end
	}

	/** 取一张音符帧的采样矩形；找不到 xml / 找不到帧就整图采样。 */
	static function findSampleFrame(xmlPath:String, width:Int, height:Int):Array<Int>
	{
		var rect:Array<Int> = [0, 0, width, height];
		if (!Paths.fileExists(xmlPath, TEXT)) return rect;

		var xml:String = Paths.getTextFromFile(xmlPath);
		if (xml == null || xml.length < 1) return rect;

		// 判据必须用音符帧（purple0 / blue0 …）：静态箭头（arrowLEFT）在两代皮肤里都是灰的，
		// 拿它采样会把 RGB 皮肤误判成 legacy。完全没有音符帧的皮肤才退回静态箭头。
		var prefixes:Array<String> = ['purple0', 'blue0', 'green0', 'red0', 'arrowLEFT'];
		for (prefix in prefixes)
		{
			var tagReg:EReg = new EReg('<SubTexture\\s+[^>]*name="' + prefix + '[^"]*"[^>]*>', '');
			if (!tagReg.match(xml)) continue;

			var tag:String = tagReg.matched(0);
			var nums:Array<Int> = [];
			var numReg:EReg = new EReg('\\s(?:x|y|width|height)="(-?\\d+)"', 'g');
			var rest:String = tag;
			while (numReg.match(rest))
			{
				nums.push(Std.parseInt(numReg.matched(1)));
				rest = numReg.matchedRight();
			}
			if (nums.length >= 4) return [nums[0], nums[1], nums[2], nums[3]];
		}
		return rect;
	}

	/** 采样统计：纯通道像素（两通道接近 0、第三通道接近 255）占比够高 = RGB 掩码贴图。 */
	static function analyze(bitmap:BitmapData, x:Int, y:Int, w:Int, h:Int):Null<String>
	{
		var step:Int = 2; // 150×150 的帧取 ~5600 个点就够，别逐像素跑
		var maxX:Int = Std.int(Math.min(x + w, bitmap.width));
		var maxY:Int = Std.int(Math.min(y + h, bitmap.height));

		var opaque:Int = 0;
		var pure:Int = 0;
		var white:Int = 0;
		var py:Int = y;
		while (py < maxY)
		{
			var px:Int = x;
			while (px < maxX)
			{
				var color:Int = bitmap.getPixel32(px, py);
				if ((color >>> 24) < 128)
				{
					px += step;
					continue;
				}

				opaque++;
				var r:Int = (color >> 16) & 0xFF;
				var g:Int = (color >> 8) & 0xFF;
				var b:Int = color & 0xFF;
				var hi:Int = Std.int(Math.max(r, Math.max(g, b)));
				var lo:Int = Std.int(Math.min(r, Math.min(g, b)));

				if (hi > 200 && lo > 200) white++;
				else if (hi > 200 && lo < 60)
				{
					var nearZero:Int = 0;
					if (r < 60) nearZero++;
					if (g < 60) nearZero++;
					if (b < 60) nearZero++;
					if (nearZero >= 2) pure++;
				}

				px += step;
			}
			py += step;
		}

		if (opaque < 50) return null;
		if (pure / opaque >= 0.35) return RGB;
		// 纯白箭头：HSV 对它毫无作用，按 RGB 处理才能被调色板染色
		if (white / opaque >= 0.6) return RGB;
		return LEGACY;
	}
}
