package games.objects;

import general.backend.animation.PsychAnimationController;
import general.shaders.RGBPalette;
import general.shaders.ColorSwap;
import general.shaders.NoteHSV;
import general.backend.NoteSkinStyle;
import flixel.system.FlxAssets.FlxShader;

typedef RGB = {
	r:Null<Int>,
	g:Null<Int>,
	b:Null<Int>
}

typedef NoteSplashAnim = {
	name:String,
	noteData:Int,
	prefix:String,
	indices:Array<Int>,
	offsets:Array<Float>,
	fps:Array<Int>
}

typedef NoteSplashConfig = {
	animations:Map<String, NoteSplashAnim>,
	scale:Float,
	allowRGB:Bool,
	allowPixel:Bool,
	rgb:Array<Null<RGB>>
}

class NoteSplash extends FlxSprite
{
	public var rgbShader:PixelSplashShaderRef;
	// 保留字段供旧模组读取；着色已统一走 allowRGBShader() + shaders.NoteHSV，不再每实例建 ColorSwap
	public var colorSwap:ColorSwap = null;
	public var texture:String;
	// 本次 loadSplash 被请求的皮肤名（可能与最终解析出的 texture 不同，见 loadSplash 的回退链）
	public var requestedSplash:String;
	public var config(default, set):NoteSplashConfig;
	public var babyArrow:StrumNote;
	public var noteData:Int = 0;

	public var copyX:Bool = true;
	public var copyY:Bool = true;
	public var inEditor:Bool = false;

	var spawned:Bool = false;
	var noteDataMap:Map<Int, String> = new Map();

	public static var defaultNoteSplash(default, never):String = "noteSplashes/noteSplashes";
	public static var configs:Map<String, NoteSplashConfig> = new Map();

	public function new(?x:Float = 0, ?y:Float = 0, ?splash:String)
	{
		super(x, y);

		animation = new PsychAnimationController(this);

		rgbShader = new PixelSplashShaderRef();
		shader = rgbShader.shader;

		loadSplash(splash);
	}

	public var maxAnims(default, set):Int = 0;
	public function loadSplash(?splash:String)
	{
		config = null;
		maxAnims = 0;

		// 与 FE 一致：没指定、或者指定的贴图磁盘上根本不存在，都重新走三级回退
		if (splash == null || splash.length < 1 || !NoteSkinStyle.exists(splash, false))
		{
			// 三级回退（note type 指定 → 谱面 splashSkin → 引擎自带旧版图集 → 默认 + 玩家后缀）
			splash = resolveSplashTexture();
		}

		requestedSplash = splash;
		texture = splash;
		frames = Paths.getSparrowAtlas(texture);
		if (frames == null)
		{
			texture = defaultNoteSplash + getSplashSkinPostfix();
			frames = Paths.getSparrowAtlas(texture);
			if (frames == null)
			{
				texture = defaultNoteSplash;
				frames = Paths.getSparrowAtlas(texture);
			}
		}
		// 更老版本的 splash 是扁平素材 images/noteSplashes.png：既不在子目录里，也没有 json/txt 配置
		if (frames == null && Paths.fileExists('images/noteSplashes.png', IMAGE))
		{
			texture = 'noteSplashes';
			frames = Paths.getSparrowAtlas(texture);
		}

		var path:String = 'images/$texture';
		if (configs.exists(path))
		{
			this.config = configs.get(path);
			for (anim in this.config.animations)
			{
				if (anim.noteData % 4 == 0)
					maxAnims++;
			}
			return;
		}
		else if (Paths.fileExists('$path.json', TEXT))
		{
			var config:Dynamic = haxe.Json.parse(Paths.getTextFromFile('$path.json'));
			if (config != null)
			{
				var tempConfig:NoteSplashConfig = {
					animations: new Map(),
					scale: config.scale,
					allowRGB: config.allowRGB,
					allowPixel: config.allowPixel,
					rgb: config.rgb
				}

				for (i in Reflect.fields(config.animations))
				{
					var anim:NoteSplashAnim = Reflect.field(config.animations, i);
					tempConfig.animations.set(i, anim);
					if (anim.noteData % 4 == 0)
						maxAnims++;
				}

				this.config = tempConfig;
				configs.set(path, this.config);
				return;
			}
		}

		// Splashes with no json
		var tempConfig:NoteSplashConfig = createConfig();
		var anim:String = 'note splash';
		var fps:Array<Null<Int>> = [22, 26];
		var offsets:Array<Array<Float>> = [[0, 0]];
		if (Paths.fileExists('$path.txt', TEXT)) // Backwards compatibility with 0.7 splash txts
		{
			var configFile:Array<String> = CoolUtil.listFromString(Paths.getTextFromFile('$path.txt'));
			if (configFile.length > 0)
			{
				anim = configFile[0];
				if (configFile.length > 1)
				{
					var framerates:Array<String> = configFile[1].split(' ');
					fps = [Std.parseInt(framerates[0]), Std.parseInt(framerates[1])];
					if (fps[0] == null) fps[0] = 22;
					if (fps[1] == null) fps[1] = 26;

					if (configFile.length > 2)
					{
						offsets = [];
						for (i in 2...configFile.length)
						{
							if (configFile[i].trim() != '')
							{
								var animOffs:Array<String> = configFile[i].split(' ');
								var x:Float = Std.parseFloat(animOffs[0]);
								var y:Float = Std.parseFloat(animOffs[1]);
								if (Math.isNaN(x)) x = 0;
								if (Math.isNaN(y)) y = 0;
								offsets.push([x, y]);
							}
						}
					}
				}
			}
		}

		var failedToFind:Bool = false;
		while (true)
		{
			for (v in Note.colArray)
			{
				if (!checkForAnim('$anim $v ${maxAnims+1}'))
				{
					failedToFind = true;
					break;
				}
			}
			if (failedToFind) break;
			maxAnims++;
		}

		for (animNum in 0...maxAnims)
		{
			for (i => col in Note.colArray)
			{
				var data:Int = i % Note.colArray.length + (animNum * Note.colArray.length);
				var name:String = animNum > 0 ? '$col' + (animNum + 1) : col;
				var offset:Array<Float> = offsets[FlxMath.wrap(data, 0, Std.int(offsets.length-1))];
				addAnimationToConfig(tempConfig, 1, name, '$anim $col ${animNum + 1}', fps, offset, [], data);
			}
		}

		this.config = tempConfig;
		configs.set(path, this.config);
	}

	public function spawnSplashNote(?x:Float = 0, ?y:Float = 0, ?noteData:Int = 0, ?note:Note, ?randomize:Bool = true)
	{
		if (note != null && note.noteSplashData.disabled)
			return;

		aliveTime = 0;

		if (!inEditor)
		{
			var loadedTexture:String = resolveSplashTexture(note);
			if (requestedSplash != loadedTexture) loadSplash(loadedTexture);
		}

		setPosition(x, y);

		if (babyArrow != null)
			setPosition(babyArrow.x - Note.swagWidth * 0.95, babyArrow.y - Note.swagWidth); // To prevent it from being misplaced for one game tick

		if (note != null)
			noteData = note.noteData;

		// 捕获原始 lane（在下面随机化 variant 之前）：splash 的颜色必须锁定 lane，
		// 不能拿被随机序号污染的 noteData 取色，否则同一个键每次的颜色都不一样
		final noteLane:Int = noteData % Note.colArray.length;

		if (randomize && maxAnims > 1)
			noteData = noteLane + (FlxG.random.int(0, maxAnims - 1) * Note.colArray.length);

		this.noteData = noteData;
		var anim:String = playDefaultAnim();

		var tempShader:RGBPalette = null;
		// 着色体系：RGB（通道重映射）/ legacy（HSV 整体偏移，0.6.3 行为）。见 NoteSplash.allowRGBShader()
		var rgbAllowed:Bool = NoteSplash.allowRGBShader(note, config, inEditor, texture);
		if (rgbAllowed)
		{
			final lane:Int = noteLane;
			Note.initializeGlobalRGBShader(lane);
			// 只要允许 RGB 就必须给一份调色板：tempShader 留 null 会让 copyValues 把 mult 归零，
			// 于是"强制 RGB"看起来完全没生效（旧代码的内层条件正是这个坑，这里按 FE 去掉）
			tempShader = new RGBPalette();
			// If Note RGB is enabled:
			if ((note == null || !note.noteSplashData.useGlobalShader) || inEditor)
			{
				var colors = config.rgb;
				if (colors != null)
				{
					for (i in 0...colors.length)
					{
						if (i > 2) break;

						var arr:Array<FlxColor> = ClientPrefs.data.arrowRGB[lane];
						if (PlayState.isPixelStage) arr = ClientPrefs.data.arrowRGBPixel[lane];

						var rgb = colors[i];
						if (rgb == null)
						{
							if (i == 0) tempShader.r = arr[0];
							else if (i == 1) tempShader.g = arr[1];
							else if (i == 2) tempShader.b = arr[2];
							continue;
						}

						var r:Null<Int> = rgb.r;
						var g:Null<Int> = rgb.g;
						var b:Null<Int> = rgb.b;

						if (r == null || Math.isNaN(r) || r < 0) r = arr[0];
						if (g == null || Math.isNaN(g) || g < 0) g = arr[1];
						if (b == null || Math.isNaN(b) || b < 0) b = arr[2];

						var color:FlxColor = FlxColor.fromRGB(r, g, b);
						if (i == 0) tempShader.r = color;
						else if (i == 1) tempShader.g = color;
						else if (i == 2) tempShader.b = color;
					}
				}
				else tempShader.copyValues(Note.globalRgbShaders[lane]);

				if (note != null)
				{
					if (note.noteSplashData.r != -1) tempShader.r = note.noteSplashData.r;
					if (note.noteSplashData.g != -1) tempShader.g = note.noteSplashData.g;
					if (note.noteSplashData.b != -1) tempShader.b = note.noteSplashData.b;
				}
			}
			else tempShader.copyValues(Note.globalRgbShaders[lane]);
		}
		rgbShader.copyValues(tempShader);
		if (!config.allowPixel) rgbShader.pixelAmount = 1;
		else if (PlayState.isPixelStage) rgbShader.pixelAmount = 6;

		// 着色体系：RGB（通道重映射）/ legacy（HSV 整体偏移，0.6.3 行为）/ 原图。
		// 池对象复用会带着上一轮的 shader，所以两条分支都要显式写一次。
		if (rgbAllowed) shader = rgbShader.shader;
		else if (!NoteHSV.apply(this, noteLane)) shader = rgbShader.shader;

		offset.set(10, 10);
		var conf:NoteSplashAnim = config.animations.get(anim);
		var offsets:Array<Float> = [0, 0];
		if (conf != null) offsets = conf.offsets;
		if (offsets != null)
		{
			offset.x += offsets[0];
			offset.y += offsets[1];
		}

		animation.finishCallback = function(name:String) {
			kill();
			spawned = false;
		}

		alpha = ClientPrefs.data.splashAlpha;
		if (note != null) alpha = note.noteSplashData.a;

		antialiasing = ClientPrefs.data.antialiasing;
		if (note != null) antialiasing = note.noteSplashData.antialiasing;
		if (PlayState.isPixelStage && config.allowPixel) antialiasing = false;

		var minFps:Int = 22;
		var maxFps:Int = 26;
		if (conf != null)
		{
			minFps = conf.fps[0];
			if (minFps < 0) minFps = 0;

			maxFps = conf.fps[1];
			if (maxFps < 0) maxFps = 0;
		}

		if (animation.curAnim != null)
			animation.curAnim.frameRate = FlxG.random.int(minFps, maxFps);

		spawned = true;
	}
	
	public function playDefaultAnim()
	{
		var anim:String = noteDataMap.get(noteData);
		if (anim != null && animation.exists(anim))
			animation.play(anim, true);

		return anim;
	}

	function checkForAnim(anim:String)
	{
		var animFrames = [];
		@:privateAccess
		animation.findByPrefix(animFrames, anim); // adds valid frames to animFrames

		return animFrames.length > 0;
	}

	var aliveTime:Float = 0;
	static var buggedKillTime:Float = 0.5; //automatically kills note splashes if they break to prevent it from flooding your HUD
	override function update(elapsed:Float)
	{
		if (spawned)
		{
			aliveTime += elapsed;
			if (animation.curAnim == null && aliveTime >= buggedKillTime)
			{
				kill();
				spawned = false;
			}
		}

		if (babyArrow != null)
		{
			if (copyX)
				x = babyArrow.x - Note.swagWidth * 0.95;

			if (copyY)
				y = babyArrow.y - Note.swagWidth;
		}
		super.update(elapsed);
	}

	public static function getSplashSkinPostfix()
	{
		var skin:String = '';
		if (ClientPrefs.data.splashSkin != ClientPrefs.defaultData.splashSkin)
			skin = '-' + ClientPrefs.data.splashSkin.trim().toLowerCase().replace(' ', '_');
		return skin;
	}

	/**
	 * 该用哪张 splash 贴图。三级回退：
	 *   1. note type 自己指定的 / 谱面 splashSkin（文件存在才算数）；
	 *   2. 引擎自带的旧版图集 images/noteSplashes.png（仅 legacy 体系；它在 images 根目录，不在 noteSplashes/ 里）；
	 *   3. 都没有才退回默认（RGB）splash + 玩家后缀。
	 * new 体系跳过谱面 splashSkin 这一级（Note.set_noteType 已经不写它了），note type 的显式指定仍然优先。
	 */
	public static function resolveSplashTexture(?note:Note):String
	{
		var fallback:String = defaultNoteSplash + getSplashSkinPostfix();

		var custom:String = (note != null) ? note.noteSplashData.texture : null;
		if (custom != null && custom.length > 0 && NoteSkinStyle.exists(custom, false)) return custom;

		var mode:String = NoteSkinStyle.splashMode();
		if (mode == NoteSkinStyle.NEW) return fallback;

		var songSplash:String = (PlayState.SONG != null) ? PlayState.SONG.splashSkin : null;
		if (NoteSkinStyle.exists(songSplash, false)) return songSplash;

		if (mode == NoteSkinStyle.LEGACY && NoteSkinStyle.exists(NoteSkinStyle.LEGACY_SPLASH_SKIN, false))
			return NoteSkinStyle.LEGACY_SPLASH_SKIN;

		return fallback;
	}

	/**
	 * 这一下 splash 用 RGB 还是 HSV。
	 * 溅射体系（ClientPrefs.splashSystem）最高优先：new → RGB；
	 * legacy → 只有真的拿到旧版图集（第 1/2 级）才 HSV，落到默认 RGB splash 时按 RGB；
	 * auto 时看 note type 的显式覆盖（noteSplashData.useRGBShader = false）、splash json 的 allowRGB、
	 * 以及音符贴图体系 —— legacy（烤色）贴图只能用 HSV，否则 splash 颜色会和箭头对不上。
	 */
	public static function allowRGBShader(?note:Note, ?config:NoteSplashConfig, ?inEditor:Bool = false, ?texture:String = null):Bool
	{
		// 编辑器里一直用 RGB 预览（沿用原行为），这样调色板改动能即时看到
		if (inEditor) return true;

		var mode:String = NoteSkinStyle.splashMode();
		if (mode == NoteSkinStyle.NEW) return true;
		if (mode == NoteSkinStyle.LEGACY)
			return (texture == null || texture.length < 1 || texture.indexOf(defaultNoteSplash) == 0);

		if (config != null && !config.allowRGB) return false;
		if (note != null && !note.noteSplashData.useRGBShader) return false;

		var style:String = (note != null) ? note.noteStyle : Note.getNoteStyle(Note.getNoteSkinPath());
		return style != NoteSkinStyle.LEGACY;
	}

	public static function createConfig():NoteSplashConfig
	{
		return {
			animations: new Map(),
			scale: 1,
			allowRGB: true,
			allowPixel: true,
			rgb: null
		}
	}

	public static function addAnimationToConfig(config:NoteSplashConfig, scale:Float, name:String, prefix:String, fps:Array<Int>, offsets:Array<Float>, indices:Array<Int>, noteData:Int):NoteSplashConfig
	{
		if (config == null) config = createConfig();

		config.animations.set(name, {name: name, noteData: noteData, prefix: prefix, indices: indices, offsets: offsets, fps: fps});
		config.scale = scale;
		return config;
	}

	function set_config(value:NoteSplashConfig):NoteSplashConfig 
	{
		if (value == null) value = createConfig();

		@:privateAccess
		animation.clearAnimations();
		noteDataMap.clear();

		for (i in value.animations)
		{
			var key:String = i.name;
			if (i.prefix.length > 0 && key != null && key.length > 0)
			{
				if (i.indices != null && i.indices.length > 0)
					animation.addByIndices(key, i.prefix, i.indices, "", i.fps[1], false);
				else
					animation.addByPrefix(key, i.prefix, i.fps[1], false);

				noteDataMap.set(i.noteData, key);
			}
		}

		scale.set(value.scale, value.scale);
		return config = value;
	}

	function set_maxAnims(value:Int)
	{
		if (value > 0)
			noteData = Std.int(FlxMath.wrap(noteData, 0, (value * Note.colArray.length) - 1));
		else
			noteData = 0;

		return maxAnims = value;
	}
}

class PixelSplashShaderRef 
{
	public var shader:PixelSplashShader = new PixelSplashShader();
	public var enabled(default, set):Bool = true;
	public var pixelAmount(default, set):Float = 1;

	public function copyValues(tempShader:RGBPalette)
	{
		if (tempShader != null)
		{
			for (i in 0...3)
			{
				shader.r.value[i] = tempShader.shader.r.value[i];
				shader.g.value[i] = tempShader.shader.g.value[i];
				shader.b.value[i] = tempShader.shader.b.value[i];
			}
			shader.mult.value[0] = tempShader.shader.mult.value[0];
		}
		else enabled = false;
	}

	public function set_enabled(value:Bool)
	{
		enabled = value;
		shader.mult.value = [value ? 1 : 0];
		return value;
	}

	public function set_pixelAmount(value:Float)
	{
		pixelAmount = value;
		shader.uBlocksize.value = [value, value];
		return value;
	}

	public function reset()
	{
		shader.r.value = [0, 0, 0];
		shader.g.value = [0, 0, 0];
		shader.b.value = [0, 0, 0];
	}

	public function new()
	{
		reset();
		enabled = true;

		if (!PlayState.isPixelStage) pixelAmount = 1;
		else pixelAmount = PlayState.daPixelZoom;
		//trace('Created shader ' + Conductor.songPosition);
	}
}

class PixelSplashShader extends FlxShader
{
	@:glFragmentHeader('
		#pragma header

		uniform vec3 r;
		uniform vec3 g;
		uniform vec3 b;
		uniform float mult;
		uniform vec2 uBlocksize;

		vec4 flixel_texture2DCustom(sampler2D bitmap, vec2 coord) {
			vec2 blocks = openfl_TextureSize / uBlocksize;
			vec4 color = flixel_texture2D(bitmap, floor(coord * blocks) / blocks);
			if (!hasTransform) {
				return color;
			}

			if (color.a == 0.0 || mult == 0.0) {
				return color * openfl_Alphav;
			}

			vec4 newColor = color;
			newColor.rgb = min(color.r * r + color.g * g + color.b * b, vec3(1.0));
			newColor.a = color.a;

			color = mix(color, newColor, mult);

			if (color.a > 0.0) {
				return vec4(color.rgb, color.a);
			}
			return vec4(0.0, 0.0, 0.0, 0.0);
		}')

	@:glFragmentSource('
		#pragma header

		void main() {
			gl_FragColor = flixel_texture2DCustom(bitmap, openfl_TextureCoordv);
		}')

	public function new()
	{
		super();
	}
}