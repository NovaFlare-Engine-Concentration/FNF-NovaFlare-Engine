package games.objects;

import flixel.FlxBasic;

import general.backend.InputFormatter;
import general.backend.animation.PsychAnimationController;

import general.shaders.RGBPalette;
import general.shaders.RGBPalette.RGBShaderReference;
import general.shaders.ColorSwap;
import general.shaders.NoteHSV;
import general.backend.NoteSkinStyle;

class StrumNote extends FlxSprite
{
	public var rgbShader:RGBShaderReference;

	public var resetAnim:Float = 0;
	// 保留字段供旧模组读取；着色已统一走 playAnim() + shaders.NoteHSV，不再每实例建 ColorSwap
	public var colorSwap:ColorSwap;
	private var noteData:Int = 0;

	public var direction:Float = 90; // plan on doing scroll directions soon -bb
	public var downScroll:Bool = false; // plan on doing scroll directions soon -bb
	public var sustainReduce:Bool = true;

	public var trackedScale:Float = 0.7;
	public var player:Int;
	private var initialWidth:Float = 0;

	public var texture(default, set):String = null;

	private function set_texture(value:String):String
	{
		if (texture != value)
		{
			texture = value;
			reloadNote();
		}
		return value;
	}

	public var useRGBShader:Bool = true;
	public var noteStyle:String = NoteSkinStyle.RGB;
	// legacy 体系的 HSV 只在生成时挂一次（0.6.x 行为），之后 playAnim 不再碰 shader 槽位
	var hsvAttached:Bool = false;
	// auto + 谱面 disableNoteRGB：RGB、HSV 都不挂
	var shaderDisabled:Bool = false;

	/** forceSkin：直接指定贴图（编辑器预览用，绕过谱面 arrowSkin / 玩家皮肤解析） */
	public function new(x:Float, y:Float, leData:Int, player:Int, ?forceSkin:String = null)
	{
		animation = new PsychAnimationController(this);

		rgbShader = new RGBShaderReference(this, Note.initializeGlobalRGBShader(leData));
		rgbShader.enabled = false;
		//先不改mania，要魔改的玩意好像还不少呢，先加上再说		//算了懒了，能跑起来就不改了————卡昔233
		var mania = 3;
		if (PlayState.SONG != null)
			mania = PlayState.SONG.mania;

		var arrowRGBIndex = getIndex(mania, leData);

		var arr:Array<FlxColor> = ClientPrefs.data.arrowRGB[arrowRGBIndex];

		if (PlayState.isPixelStage)
			arr = ClientPrefs.data.arrowRGBPixel[arrowRGBIndex];

		@:bypassAccessor
		{
			rgbShader.r = arr[0];
			rgbShader.g = arr[1];
			rgbShader.b = arr[2];
		}

		noteData = leData;
		this.player = player;
		this.noteData = leData;
		super(x, y);

		var skin:String = null;
		var pixelPath:String = PlayState.isPixelStage ? 'pixelUI/' : '';

		if (forceSkin != null && forceSkin.length > 0)
		{
			// 编辑器预览：直接指定贴图，绕过谱面 arrowSkin / 玩家皮肤后缀解析
			skin = pixelPath + forceSkin;
		}
		else
		{
			// 与 FE 一致：直接用同一套三级回退解析，不依赖 Note 的缓存表
			var baseSkin:String = Note.getNoteSkinPath();
			var customSkin:String = baseSkin + Note.getNoteSkinPostfix();
			if (Paths.fileExists('images/' + customSkin + '.png', IMAGE)) baseSkin = customSkin;

			skin = pixelPath + baseSkin;
		}

		texture = skin; // Load texture and anims
		scrollFactor.set();

		playAnim('static');
	}

	public function reloadNote()
	{
		var lastAnim:String = null;
		if (animation.curAnim != null)
			lastAnim = animation.curAnim.name;

		// 贴图换了就重新判定着色体系（与 Note 同一套判据）。texture 里带 pixelUI/ 前缀，
		// getNoteStyle 会自己补前缀，比对前先剥掉，否则会拼成 pixelUI/pixelUI/...
		var styleBase:String = texture;
		if (styleBase != null && PlayState.isPixelStage && styleBase.indexOf('pixelUI/') == 0)
			styleBase = styleBase.substr('pixelUI/'.length);
		noteStyle = Note.getNoteStyle(styleBase);
		useRGBShader = (noteStyle != NoteSkinStyle.LEGACY);
		// auto + 谱面 disableNoteRGB：谱面说啥就是啥，RGB、HSV 都不挂（与 Note.updateNoteShader 同一条规则）
		shaderDisabled = (NoteSkinStyle.noteMode() == NoteSkinStyle.AUTO
			&& PlayState.SONG != null && PlayState.SONG.disableNoteRGB);
		// 换了贴图，HSV 需要重新挂一次
		hsvAttached = false;

		var mania = 3;
		if (PlayState.SONG != null) mania = PlayState.SONG.mania;

		if (PlayState.isPixelStage)
		{
			loadGraphic(Paths.image(texture));
			width = width / 4;	//idk
			height = height / 5;
			loadGraphic(Paths.image(texture), true, Math.floor(width), Math.floor(height));

			antialiasing = false;

			antialiasing = false;

			initialWidth = width;
			//trace(initialWidth);

			var pixelScale:Float = ExtraKeysHandler.instance.data.pixelScales != null && mania < ExtraKeysHandler.instance.data.pixelScales.length ? ExtraKeysHandler.instance.data.pixelScales[mania] : 0.7;
			setGraphicSize((width * (pixelScale + 0.3)) * PlayState.daPixelZoom);
			trackedScale = pixelScale;

			var noteAnimInt = getAnimSet(getIndex(mania, noteData)).pixel;

			//animation.add('circle', [11]);
			//animation.add('rombus', [10]);
			animation.add('red', [9]);
			animation.add('green', [8]);
			animation.add('blue', [7]);
			animation.add('purple', [6]);

			animation.add('static', [noteAnimInt]);
			animation.add('pressed', [noteAnimInt + 4, noteAnimInt + 8], 12, false);
			animation.add('confirm', [noteAnimInt + 12, noteAnimInt + 16], 24, false);

		}
		else
		{
			frames = Paths.getSparrowAtlas(texture);
			animation.addByPrefix('green', 'arrowUP');
			animation.addByPrefix('blue', 'arrowDOWN');
			animation.addByPrefix('purple', 'arrowLEFT');
			animation.addByPrefix('red', 'arrowRIGHT');

			initialWidth = width;	//我勒个一行造成死循环————卡昔233

			antialiasing = ClientPrefs.data.antialiasing;
			trackedScale = ExtraKeysHandler.instance.data.scales != null && mania < ExtraKeysHandler.instance.data.scales.length ? ExtraKeysHandler.instance.data.scales[mania] : 0.7;
			setGraphicSize(width * trackedScale);

			animation.addByPrefix('static', 'arrow${getAnimSet(getIndex(mania, noteData)).strum}');
			animation.addByPrefix('pressed', '${getAnimSet(getIndex(mania, noteData)).anim} press', 24, false);
			animation.addByPrefix('confirm', '${getAnimSet(getIndex(mania, noteData)).anim} confirm', 24, false);

		}
		updateHitbox();

		if (lastAnim != null)
		{
			playAnim(lastAnim, true);
		}
	}

	public function retryBound()
	{
		trackedScale = trackedScale * 0.85;
		setGraphicSize(initialWidth * (trackedScale * (PlayState.isPixelStage ? PlayState.daPixelZoom /** (1/ExtraKeysHandler.instance.data.pixelScales[PlayState.SONG.mania])) */ : 1)));
		trace(trackedScale);
		updateHitbox();
		postAddedToGroup();
	}

	public function postAddedToGroup()
	{
		playAnim('static');
		var padding:Float = 0;
		var minPaddingStartThresh:Int = 4;
		// if (PlayState.isPixelStage) minPaddingStartThresh = 3;
		if (PlayState.SONG.mania > minPaddingStartThresh)
		{
			padding = 4 * (PlayState.SONG.mania - minPaddingStartThresh);
			if (padding > 8)
				padding = 8;
		}
		// trace(padding);

		// x = StrumBoundaries.getMiddlePoint().x;
		// x += ((Note.swagWidthUnscaled * trackedScale) - padding) * (-((PlayState.SONG.mania + 1) / 2) + noteData);
		// x += 25;
		// x += ((FlxG.width / 2) * player);
		ID = noteData;

		centerStrum(minPaddingStartThresh, padding);
	}

	/**
	 * Please refrain from asking me what happens here
	 * @param maniaThresh I don't know
	 * @param padding I don't know
	 */
	public function centerStrum(maniaThresh:Int, padding:Float)
	{
		var sWidth = /*(PlayState.isPixelStage && PlayState.SONG.mania > maniaThresh) ? (180 + ((10 + (5 * (PlayState.SONG.mania - maniaThresh))) * (PlayState.SONG.mania - maniaThresh))) : */ Note.swagWidthUnscaled;
		if (!ClientPrefs.data.middleScroll)
		{
			x = player == 0 ? 320 : 960;
			x += ((sWidth * trackedScale) - padding) * (-((PlayState.SONG.mania + 1) / 2) + noteData);
		}
		else
		{
			var controlledPlayer:Int = ClientPrefs.data.playOpponent ? 0 : 1;
			if (player == controlledPlayer)
				x = 640;
			else
			{
				x = 320;
				if (noteData > Math.floor((PlayState.SONG.mania / 2)))
					x = 960;
			}
			x += ((sWidth * trackedScale) - padding) * (-((PlayState.SONG.mania + 1) / 2) + noteData);
		}
		// trace(padding);
	}

	override function update(elapsed:Float)
	{
		if (resetAnim > 0)
		{
			resetAnim -= elapsed;
			if (resetAnim <= 0)
			{
				playAnim('static');
				resetAnim = 0;
			}
		}
		super.update(elapsed);
	}

	public function playAnim(anim:String, ?force:Bool = false)
	{
		animation.play(anim, force);
		if (animation.curAnim != null)
		{
			centerOffsets();
			centerOrigin();
		}

		if (shaderDisabled) return;

		if (useRGBShader)
		{
			// RGB 体系保持 0.7+ 行为：静态箭头是灰色占位不染色，按下/确认帧才挂 RGB。
			// 模组中途把 sprite.shader 换成自己的（轨道 glitch 之类）是模组自己的事，
			// confirm 时 set_enabled 会把槽位要回来 —— 那是 0.7 的固有语义，模组自己兼容。
			rgbShader.enabled = (animation.curAnim != null && animation.curAnim.name != 'static');
		}
		else if (!hsvAttached)
		{
			// legacy 体系保持 0.6.x 行为：HSV 只在生成时挂这一次（static 也挂），全 0 不挂；
			// 之后 playAnim 不再碰槽位，模组换 shader 引擎不抢。
			hsvAttached = true;
			NoteHSV.apply(this, noteData);
		}
	}
	
	public function getIndex(mania:Int, note:Int) {
		return ExtraKeysHandler.instance.data.keys[mania].notes[note];
	}

	public function getAnimSet(index:Int) {
		return ExtraKeysHandler.instance.data.animations[index];
	}
}

class StrumBoundaries {
	public static var minBoundaryOpponent:FlxPoint = new FlxPoint(30, 50);
	public static var maxBoundaryOpponent:FlxPoint = new FlxPoint(630, 160);

	public static function getMiddlePoint():FlxPoint {
		return new FlxPoint(Std.int(getBoundaryWidth().x/2),Std.int(getBoundaryWidth().y/2));
	}

	public static function getBoundaryWidth():FlxPoint {
		return new FlxPoint(Std.int((maxBoundaryOpponent.x - minBoundaryOpponent.x)),Std.int((maxBoundaryOpponent.y - minBoundaryOpponent.y)));
	}
}

class KeybindShowcase extends FlxTypedGroup<FlxBasic>
{
	public var background:FlxSprite;
	public var keyText:FlxText;
	public var keyCodes:Array<Int> = [];

	public var keystart1Timer:FlxTimer;
	public var keystart2Timer:FlxTimer;

	public var keytween1:FlxTween;
	public var keytween2:FlxTween;
	public var keytween3:FlxTween;

	public dynamic function onComplete():Void
	{
	}

	public function new(x:Float, y:Float, keyCodes:Array<Int>, camera:FlxCamera, strumHalved:Float, mania:Int)
	{
		super();

		this.keyCodes = keyCodes;

		var xOffset = x + strumHalved;

		var size = 20 - (mania - 3);

		keyText = new FlxText(xOffset + 4, y + 4, InputFormatter.getKeyName(keyCodes[0]));
		keyText.setFormat(Paths.font("vcr.ttf"), size, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		keyText.x -= keyText.width / 2;
		xOffset = keyText.x;

		background = new FlxSprite(xOffset - 4, y);
		background.makeGraphic(Std.int(keyText.width + 8), Std.int(keyText.height + 8), 0xFF000000);
		background.alpha = 0.5;

		add(background);
		add(keyText);

		background.cameras = [camera];
		keyText.cameras = [camera];

		if (keystart1Timer != null)
			keystart1Timer.cancel();
		if (keystart2Timer != null)
			keystart2Timer.cancel();

		if (keytween1 != null)
			keytween1.cancel();
		if (keytween2 != null)
			keytween2.cancel();
		if (keytween3 != null)
			keytween3.cancel();

		keystart1Timer = new FlxTimer().start(2, function(tmr:FlxTimer)
		{
			keytween1 = FlxTween.tween(keyText, {alpha: 0}, 0.5, {
				ease: FlxEase.linear,
				onComplete: function(t)
				{
					keytween1 = null;

					if (keyCodes.length > 1)
					{
						keyText.text = InputFormatter.getKeyName(keyCodes[1]);
					}
					else
					{
						keyText.text = '---';
					}

					keytween2 = FlxTween.tween(keyText, {alpha: 1}, 0.5);

					if (background.velocity != null)
					{
						keyText.x = x + strumHalved + 4;
						keyText.x -= keyText.width / 2;
						xOffset = keyText.x;
						background.x = xOffset - 4;
						background.makeGraphic(Std.int(keyText.width + 8), Std.int(keyText.height + 8), 0xFF000000);
						keystart2Timer = new FlxTimer().start(2.5, function(tmr:FlxTimer)
						{
							keytween3 = FlxTween.tween(keyText, {alpha: 0}, 0.5, {
								ease: FlxEase.linear,
								onComplete: function(t)
								{
									onComplete();

									keytween3 = null;
								}
							});
						});
					}
				}
			});
		});
	}
}

