package games.objects;

import flixel.FlxBasic;

import general.backend.InputFormatter;
import general.backend.animation.PsychAnimationController;

import general.shaders.RGBPalette;
import general.shaders.RGBPalette.RGBShaderReference;
import general.shaders.ColorSwap;

class StrumNote extends FlxSprite
{
	public var rgbShader:RGBShaderReference;

	public var resetAnim:Float = 0;
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

	/**
	 * 该 strum 生效的 mania（每侧键数 - 1）；-1 = 跟随 PlayState.SONG.mania。
	 * KeyChange(MoreKey) 场景：运行期重建/编辑器预览/试玩时按段传入，
	 * 保证方向帧、颜色、缩放与排布在该段键数下正确。
	 */
	public var strumMania:Int = -1;

	/** 取生效 mania：优先 strumMania（段覆盖），否则当前谱面 mania */
	inline function curMania():Int
	{
		if (strumMania >= 0)
			return strumMania;
		return (PlayState.SONG != null) ? PlayState.SONG.mania : 3;
	}

	public function new(x:Float, y:Float, leData:Int, player:Int, ?maniaOverride:Int = -1)
	{
		animation = new PsychAnimationController(this);

		strumMania = maniaOverride;

		rgbShader = new RGBShaderReference(this, Note.initializeGlobalRGBShader(leData, curMania()));
		rgbShader.enabled = false;
		// ★ 统一策略：谱面 disableNoteRGB / 玩家 noteRGB / 色相替换模式 任一命中即不启用 RGB
		//   （旧代码在构造器里用 SONG.mania 建调色板、却用 strumMania 取色，两者不一致时
		//    RGBShaderReference 会克隆私有调色板并把着色器挂回 → 关掉 RGB 的谱面受体照样染色）
		useRGBShader = Note.noteRGBAllowed();
		if (ClientPrefs.data.noteColorSwap){
		colorSwap = new ColorSwap();
		shader = colorSwap.shader;
		}

		// ★ 取色改用统一的 Extra Keys 映射（旧代码用 getIndex() 直读，越界直接 NPE；
		//   且 clamp 规则与 Note.buildGlobalPalette 不一致 → 额外触发无谓的 palette 克隆）
		var arr:Array<FlxColor> = Note.colorRow(curMania(), leData);
		if (arr != null && arr.length > 2)
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

		if (Note.loadedNote.get(Note.getLoadDataKey(Note.defaultNoteSkin, '')) == null || Note.loadedNote.get(Note.getLoadDataKey(Note.defaultNoteSkin, '')).skin == null)
			Note.init();

		skin = pixelPath + Note.loadedNote.get(Note.getLoadDataKey(Note.defaultNoteSkin, '')).skin + Note.loadedNote.get(Note.getLoadDataKey(Note.defaultNoteSkin, '')).skinPostfix;
			
		texture = skin; // Load texture and anims
		scrollFactor.set();

		shaderInit();
	}

	public function reloadNote()
	{
		var lastAnim:String = null;
		if (animation.curAnim != null)
			lastAnim = animation.curAnim.name;

		var mania:Int = curMania();

		if (PlayState.isPixelStage)
		{
			// ★ 防御：皮肤缺像素版贴图时 Paths.image 返回 null，逐级回退到默认像素贴图
			//   （注意默认皮肤路径含 noteSkins/ 前缀，写错会导致箭头变"空气"）
			var g = Paths.image(texture);
			if (g == null) g = Paths.image('pixelUI/noteSkins/NOTE_assets');
			if (g != null)
			{
				loadGraphic(g);
				width = width / 4;	//idk
				height = height / 5;
				loadGraphic(g, true, Math.floor(width), Math.floor(height));
			}

			antialiasing = false;

			antialiasing = false;

			initialWidth = width;
			//trace(initialWidth);

			var pixelScale:Float = ExtraKeysHandler.instance.data.pixelScales != null && mania < ExtraKeysHandler.instance.data.pixelScales.length ? ExtraKeysHandler.instance.data.pixelScales[mania] : 0.7;
			setGraphicSize((width * (pixelScale + 0.3)) * PlayState.daPixelZoom);
			trackedScale = pixelScale;

			// ★ 防御：getAnimSet 越界 → .pixel NPE；用 tryGetAnimSet 兜底（取不到时退到 0）
			var pixelAnimSet:Dynamic = tryGetAnimSet(mania, noteData);
			var noteAnimInt:Int = (pixelAnimSet != null) ? pixelAnimSet.pixel : 0;

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

			// ★ 防御：getAnimSet 越界会 NPE；用 tryGetAnimSet 兜底（动画名取不到时跳过 addByPrefix 即可）
			var animSet:Dynamic = tryGetAnimSet(mania, noteData);
			if (animSet != null && animSet.strum != null)
				animation.addByPrefix('static', 'arrow${animSet.strum}');
			if (animSet != null && animSet.anim != null)
			{
				animation.addByPrefix('pressed', '${animSet.anim} press', 24, false);
				animation.addByPrefix('confirm', '${animSet.anim} confirm', 24, false);
			}

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
		updateHitbox();
		postAddedToGroup();
	}

	public function postAddedToGroup()
	{
		playAnim('static');
		var padding:Float = 0;
		var minPaddingStartThresh:Int = 4;
		// if (PlayState.isPixelStage) minPaddingStartThresh = 3;
		if (curMania() > minPaddingStartThresh)
		{
			padding = 4 * (curMania() - minPaddingStartThresh);
			if (padding > 8)
				padding = 8;
		}
		// trace(padding);

		// x = StrumBoundaries.getMiddlePoint().x;
		// x += ((Note.swagWidthUnscaled * trackedScale) - padding) * (-((curMania() + 1) / 2) + noteData);
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
		var m:Int = curMania();
		var sWidth = /*(PlayState.isPixelStage && m > maniaThresh) ? (180 + ((10 + (5 * (m - maniaThresh))) * (m - maniaThresh))) : */ Note.swagWidthUnscaled;
		if (!ClientPrefs.data.middleScroll)
		{
			x = player == 0 ? 320 : 960;
			x += ((sWidth * trackedScale) - padding) * (-((m + 1) / 2) + noteData);
		}
		else
		{
			x = player == 0 ? 320 : 640;
			if (player == 0)
			{
				if (noteData > Math.floor((m / 2)))
					x = 960;
			}
			x += ((sWidth * trackedScale) - padding) * (-((m + 1) / 2) + noteData);
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

		var isStatic:Bool = (animation.curAnim == null || animation.curAnim.name == 'static');

		if (useRGBShader)
		{
			rgbShader.enabled = !isStatic;
		}
		else if (ClientPrefs.data.noteColorSwap && colorSwap != null)
		{
			// 色相替换模式：RGB 着色器必须让位（两者抢同一个 sprite.shader 槽）
			if (rgbShader.enabled) rgbShader.enabled = false;
			if (shader != colorSwap.shader) shader = colorSwap.shader;

			// ★ 旧代码写死 `noteData % 4`：>4K 时按键轨号 ≠ 基础色下标（见 Note.baseColorIndex）
			var hsv:Array<Float> = Note.hsvRow(curMania(), noteData);
			if (isStatic || hsv == null || hsv.length < 3)
			{
				colorSwap.hue = 0;
				colorSwap.saturation = 0;
				colorSwap.brightness = 0;
			}
			else
			{
				colorSwap.hue = hsv[0] / 360;
				colorSwap.saturation = hsv[1] / 100;
				colorSwap.brightness = hsv[2] / 100;
			}
		}
		else
		{
			// 谱面 disableNoteRGB / 玩家 noteRGB 关闭：确保着色器彻底摘除。
			// 这是「RGB 关不掉」的第二道保险（第一道在 RGBShaderReference.cloneOriginal）。
			if (rgbShader.enabled) rgbShader.enabled = false;
		}
	}

	/**
	 * RGB 开关（谱面 disableNoteRGB / 玩家选项）在运行期变化后重新套用策略。
	 * 图表编辑器勾选 "Disable Note RGB" 重建 strumline、或脚本改了 ClientPrefs 之后调用。
	 */
	public function applyRGBPolicy():Void
	{
		useRGBShader = Note.noteRGBAllowed();
		var isStatic:Bool = (animation.curAnim == null || animation.curAnim.name == 'static');

		if (useRGBShader)
		{
			rgbShader.enabled = !isStatic;
		}
		else
		{
			rgbShader.enabled = false;
			if (ClientPrefs.data.noteColorSwap && colorSwap != null && shader != colorSwap.shader)
				shader = colorSwap.shader;
		}
	}
	
	public function getIndex(mania:Int, note:Int) {
		return ExtraKeysHandler.instance.data.keys[mania].notes[note];
	}

	public function getAnimSet(index:Int) {
		return ExtraKeysHandler.instance.data.animations[index];
	}

	/**
	 * 越界安全的 EKAnimation 读取（mania/note/animations 越界返回 null，绝不抛异常）。
	 * reloadNote 之类的热点路径上避免 `getAnimSet(...).strum` 在 KeyChange 中段/老存档残值时 NPE。
	 */
	public function tryGetAnimSet(mania:Int, note:Int):Dynamic
	{
		if (ExtraKeysHandler.instance == null || ExtraKeysHandler.instance.data == null) return null;
		var data = ExtraKeysHandler.instance.data;
		if (data.keys == null || data.animations == null) return null;
		if (mania < 0 || mania >= data.keys.length) return null;
		var notesArr:Array<Int> = data.keys[mania].notes;
		if (notesArr == null || note < 0 || note >= notesArr.length) return null;
		var visIdx:Int = notesArr[note];
		if (visIdx < 0 || visIdx >= data.animations.length) return null;
		return data.animations[visIdx];
	}

	private function shaderInit() {
		if (useRGBShader)
			rgbShader.enabled = false;
		else if (ClientPrefs.data.noteColorSwap && colorSwap != null)
		{
			// ★ `shader = colorSwap.shader` 在构造器里、super() 之前就赋过了；这里再确认一次，
			//   防止中途被 RGB 分支或脚本覆盖（两者抢同一个 shader 槽）。
			if (shader != colorSwap.shader) shader = colorSwap.shader;
			colorSwap.hue = 0;
			colorSwap.saturation = 0;
			colorSwap.brightness = 0;
		}
		else
		{
			// 谱面 disableNoteRGB / 玩家 noteRGB 关闭：静态箭头绝不能带着 RGB 着色器
			rgbShader.enabled = false;
		}
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
		keyText.setFormat(Paths.font(Language.get('fontName', 'main') + '.ttf'), size, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
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

