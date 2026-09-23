package developer.editors;

import games.objects.HealthIcon;
import flixel.graphics.FlxGraphic;
import openfl.display.BitmapData;
import openfl.display.BitmapDataChannel;
import openfl.geom.Matrix;
import openfl.geom.Point;
import openfl.geom.Rectangle;

import states.freeplayState.backend.PreThreadLoad;

import general.backend.language.Language;
import general.backend.Paths;
import general.backend.Cache;
import general.backend.ClientPrefs;
import general.backend.Mods;

/**
 * 歌曲卡片 —— 直接以 states.freeplayState.objects.song.SongRect 为底复制。
 *
 * 与原版的差异（仅适配编辑器环境，视觉/动效保持一致）：
 *  - 去掉难度条（DiffRect/Difficulty）、搜索、播放/选歌流程；
 *  - FreeplayState.instance / songsMove 依赖改为注入：
 *      frameTime  每帧的平滑时间（等价 songsMove.saveElapsed * lerpSmooth）
 *      isFocused  当前是否选中（等价 FreeplayState.curSelected == id）
 *      onCardClick 点击卡片回调（原版内部 changeSelectAll）
 *  - beatHit() 保留（选中闪白，编辑器内手动调用）
 */
class WeekSongRect extends FlxSpriteGroup
{
	static public final fixWidth:Int = 560;
	static public final fixHeight:Int = #if mobile 80 #else 70 #end;

	public var id:Int = 0;
	public var onCardClick:Int->Void = null; // 点击回调（参数 id）
	public var frameTime:Float = 0.016; // 外部每帧注入（平滑系数同原版 lerpSmooth≈8）

	public var onFocus(get, set):Bool; // 选中态（驱动 chooseX 左凸与光效）
	var _onFocus:Bool = false;

	public var bgPath:String;
	public var songNameSt:String = '';
	public var songMusican:String = '';

	var selectShow:Rect;
	private var bg:FlxSprite;
	private var black:SegmentGradientRoundRect;
	private var light:SegmentGradientRoundRect;
	private var icon:HealthIcon;
	private var songName:FlxText;
	private var musican:FlxText;
	private var selectLight:Rect;
	private var _songColor:FlxColor;

	public function new(songNameSt:String, songIcon:String, songMusican:String, songCharter:Array<String>, songColor:Array<Int>)
	{
		super(0, 0);

		this.songNameSt = songNameSt;
		this.songMusican = songMusican;

		selectShow = new Rect(2, 0, fixWidth, fixHeight, fixHeight / 4, fixHeight / 4, FlxColor.WHITE, 1, 0, 0xFF96B5FF);
		selectShow.antialiasing = ClientPrefs.data.antialiasing;
		selectShow.alpha = 0;
		add(selectShow);

		var path:String = PreThreadLoad.bgPathCheck(Mods.currentModDirectory, 'data/${songNameSt}/bg');
		bgPath = path;

		bg = new FlxSprite();
		if (Cache.checkFrame(path))
			bg.frames = Cache.getFrame(path);
		else
		{
			var placeholder:FlxGraphic = getCardPlaceholder(Paths.image('menuDesat'), selectShow.pixels);
			if (placeholder != null)
				bg.frames = placeholder.imageFrame;
			else
				bg.loadGraphic(Paths.image('menuDesat'));
		}
		bg.setGraphicSize(fixWidth, fixHeight);
		bg.updateHitbox();
		bg.antialiasing = ClientPrefs.data.antialiasing;
		if (!Cache.checkFrame(path) || path.indexOf('menuDesat') != -1)
			bg.color = FlxColor.fromRGB(songColor[0], songColor[1], songColor[2]);
		add(bg);

		_songColor = FlxColor.fromRGB(songColor[0], songColor[1], songColor[2]);

		black = new SegmentGradientRoundRect(0, 0, Std.int(selectShow.width), Std.int(selectShow.height), fixHeight / 4, FlxColor.BLACK, [[0, 0.5, 0.3], [0.7, 0.5, 0]], 1);
		black.antialiasing = ClientPrefs.data.antialiasing;
		add(black);

		light = new SegmentGradientRoundRect(0, 0, Std.int(selectShow.width), Std.int(selectShow.height), fixHeight / 4, FlxColor.WHITE, [[0.3, 0.5, 0], [1, 0.5, 0.3]], 1);
		light.antialiasing = ClientPrefs.data.antialiasing;
		light.blend = ADD;
		light.alpha = 0;
		add(light);

		icon = new HealthIcon(songIcon, false, false);
		icon.setGraphicSize(Std.int(bg.height * 0.8));
		icon.x += bg.height / 2 - icon.height / 2;
		icon.y += bg.height / 2 - icon.height / 2;
		icon.updateHitbox();
		add(icon);

		songName = new FlxText(0, 0, 0, songNameSt, 20);
		songName.setFormat(Paths.font(EditorInputStyle.langFontFileName()), Std.int(selectShow.height * 0.3), 0xFFFFFFFF, LEFT, FlxTextBorderStyle.OUTLINE, 0xFFFFFFFF);
		songName.borderStyle = NONE;
		songName.antialiasing = ClientPrefs.data.antialiasing;
		songName.x += bg.height / 2 - icon.height / 2 + icon.width * 1.1;
		add(songName);

		musican = new FlxText(0, 0, 0, songMusican, 20);
		musican.setFormat(Paths.font(EditorInputStyle.langFontFileName()), Std.int(selectShow.height * 0.2), 0xFFFFFFFF, LEFT, FlxTextBorderStyle.OUTLINE, 0xFFFFFFFF);
		musican.borderStyle = NONE;
		musican.antialiasing = ClientPrefs.data.antialiasing;
		musican.x += bg.height / 2 - icon.height / 2 + icon.width * 1.1;
		musican.y += songName.textField.textHeight;
		add(musican);

		selectLight = new Rect(0, 0, Std.int(selectShow.width + 50), Std.int(selectShow.height), fixHeight / 4, fixHeight / 4, 0xFFFFFF, 0);
		selectLight.antialiasing = ClientPrefs.data.antialiasing;
		selectLight.blend = ADD;
		selectLight.alpha = 0;
		add(selectLight);
	}

	// ===== 缩略底图占位（照抄原版：menuDesat 居中裁切 + copyChannel 蒙版进缓存） =====
	static function getCardPlaceholder(source:FlxGraphic, mask:BitmapData):FlxGraphic
	{
		if (source == null || source.bitmap == null || source.width <= 0 || source.height <= 0)
			return null;

		var cacheKey:String = 'weekeditor-freeplay-card-placeholder:' + source.key;
		if (Cache.checkFrame(cacheKey))
			return Cache.currentTrackedFrames.get(cacheKey).graphic;

		try
		{
			var scale:Float = Math.max(fixWidth / source.width, fixHeight / source.height);
			var matrix:Matrix = new Matrix();
			matrix.scale(scale, scale);
			matrix.translate(
				-(source.width * scale - fixWidth) * 0.5,
				-(source.height * scale - fixHeight) * 0.5);

			var thumbnail:BitmapData = new BitmapData(fixWidth, fixHeight, true, 0x00000000);
			thumbnail.draw(source.bitmap, matrix, null, null, null, ClientPrefs.data.antialiasing);
			if (mask != null)
				thumbnail.copyChannel(mask,
					new Rectangle(0, 0, fixWidth, fixHeight),
					new Point(), BitmapDataChannel.ALPHA, BitmapDataChannel.ALPHA);

			var graphic:FlxGraphic = FlxGraphic.fromBitmapData(thumbnail, false, cacheKey);
			Cache.setFrame(cacheKey, {graphic: graphic, frame: null});
			return graphic;
		}
		catch (e:Dynamic)
		{
			return null;
		}
	}

	/** 选中/节拍闪白（编辑器在切换选中时手动调用，等价原版 beatHit） */
	public function beatHit():Void
	{
		light.alpha = 1;
	}

	/** 更换图标（编辑图标名后刷新卡片） */
	public function changeIcon(newIcon:String):Void
	{
		icon.changeIcon(newIcon);
	}

	/** 更换歌曲主题色（RGB 编辑时同步卡片：占位缩略底跟随着色，真实 bg 图保持原样） */
	public function setCardColor(rgb:Array<Int>):Void
	{
		if (rgb == null || rgb.length < 3)
			return;
		_songColor = FlxColor.fromRGB(rgb[0], rgb[1], rgb[2]);
		if (bgPath == null || bgPath.indexOf('menuDesat') != -1)
			bg.color = _songColor;
	}

	override function update(elapsed:Float):Void
	{
		// 选中态：悬停 / 常亮柔光（同原版 update 逻辑，去掉 diff/搜索分支）
		if (onFocus)
		{
			selectLight.alpha = 0.1;
		}
		else
		{
			selectLight.alpha -= elapsed;
		}

		// 鼠标悬停/点击（原版走 mouseEvent.overlaps，这里用 FlxG.mouse.overlaps 等效）
		var my:Float = FlxG.mouse.y;
		if (my < FlxG.height - 65 && my > 70 && this.visible)
		{
			if (FlxG.mouse.overlaps(black, FlxG.camera))
			{
				if (!onFocus)
					selectLight.alpha = 0.1;
				if (FlxG.mouse.justReleased)
				{
					if (onCardClick != null)
						onCardClick(id);
				}
			}
		}

		super.update(elapsed);

		if (light.alpha > 0)
		{
			var decay:Float = (Conductor.crochet > 0) ? (Conductor.crochet * 2 / 1000) : 0.5;
			light.alpha -= elapsed / decay;
		}
	}

	// ===== 位置/弧线（照抄原版 calcX/moveY，diff/search 分支移除） =====

	public var realX:Float = 0;
	public var realY:Float = 0;
	public var moveX:Float = 0;
	public var chooseX:Float = 0;

	public function calcX():Void
	{
		moveX = Math.pow(Math.abs(realY + selectShow.height / 2 - FlxG.height / 2) / (FlxG.height / 2) * 10, 1.8);

		var chooseTar:Float = onFocus ? -20 : 0;
		if (Math.abs(chooseX - chooseTar) > 1)
			chooseX = FlxMath.lerp(chooseTar, chooseX, Math.exp(-frameTime));
		else
			chooseX = chooseTar;

		// 原版：realX = width - selectShow.width + 80 + moveX + chooseX...
		// 编辑器无右侧 replay 面板，改为贴右对齐，弧线位移保留
		realX = FlxG.width - selectShow.width - 6 + moveX + chooseX;
	}

	public function moveY(startY:Float):Void
	{
		realY = startY;
	}

	override function draw():Void
	{
		this.x = realX;
		this.y = realY;
		super.draw();
	}

	function get_onFocus():Bool
	{
		return _onFocus;
	}

	function set_onFocus(value:Bool):Bool
	{
		if (_onFocus == value)
			return _onFocus;
		_onFocus = value;
		return value;
	}
}
