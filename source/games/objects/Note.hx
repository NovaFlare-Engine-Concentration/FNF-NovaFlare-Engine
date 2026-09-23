package games.objects;

import flixel.math.FlxRect;

import general.backend.animation.PsychAnimationController;

import general.shaders.RGBPalette;
import general.shaders.ColorSwap;
import general.shaders.RGBPalette.RGBShaderReference;

import developer.editors.EditorPlayState;

import games.backend.NoteTypesConfig;
import games.objects.StrumNote;

typedef EventNote =
{
	strumTime:Float,
	event:String,
	value1:String,
	value2:String
}

typedef NoteSplashData =
{
	disabled:Bool,
	texture:String,
	useGlobalShader:Bool, // breaks r/g/b/a but makes it copy default colors for your custom note
	useRGBShader:Bool,
	antialiasing:Bool,
	r:FlxColor,
	g:FlxColor,
	b:FlxColor,
	a:Float
}

/**
 * The note object used as a data structure to spawn and manage notes during gameplay.
 * 
 * If you want to make a custom note type, you should search for: "function set_noteType"
**/
class Note extends FlxSprite
{
	// This is needed for the hardcoded note types to appear on the Chart Editor,
	// It's also used for backwards compatibility with 0.1 - 0.3.2 charts.
	public static final defaultNoteTypes:Array<String> = [
		'', // Always leave this one empty pls
		'Alt Animation',
		'Hey!',
		'Hurt Note',
		'GF Sing',
		'No Animation'
	];

	static var follow:Dynamic = null;

	public var extraData:Map<String, Dynamic> = new Map<String, Dynamic>();

	public var strumTime:Float = 0;
	public var noteData:Int = 0;

	/**
	 * 生成期该音符所属「段」的 mania（每侧键数 - 1）。
	 * 由 PlayState.generateSong 按 KeyChange(MoreKey) 事件时间线传入；
	 * -1 = 未指定（整谱单键数/编辑器等），此时一切逻辑回退到 PlayState.SONG.mania。
	 * 用于保证 mid-song 换键时：颜色/方向/缩放按音符自己那段正确渲染，
	 * 共享 RGB shader 槽不会被不同键数段的音符互相污染（RGBShaderReference
	 * 会在颜色不一致时自动克隆私有 palette）。
	 */
	public var generatedMania:Int = -1;

	public var mustPress:Bool = false;
	public var canBeHit:Bool = false;
	public var tooLate:Bool = false;

	public var wasGoodHit:Bool = false;
	public var missed:Bool = false;

	public var ignoreNote:Bool = false;
	public var hitByOpponent:Bool = false;
	public var noteWasHit:Bool = false;
	public var prevNote:Note;
	public var nextNote:Note;

	public var spawned:Bool = false;

	public var tail:Array<Note> = []; // for sustains
	public var killTail:Bool = false;
	public var parent:Note;
	public var blockHit:Bool = false; // only works for player

	public var sustainLength:Float = 0;
	public var canHold:Bool = false;
	public var isSustainNote:Bool = false;
	public var noteType(default, set):String = null;

	public var eventName:String = '';
	public var eventLength:Int = 0;
	public var eventVal1:String = '';
	public var eventVal2:String = '';

	public var rgbShader:RGBShaderReference;

	public static var globalRgbShaders:Array<RGBPalette> = [];

	/**
	 * `globalRgbShaders` 的槽位上限。
	 * 键数上限是 10K（10 条轨道），留出余量取 32；超出者一律按轨道 0 处理，
	 * 避免外部传入的超大 noteData 把调色板数组撑爆（每个槽位一个 FlxShader）。
	 */
	public static inline var MAX_RGB_SLOTS:Int = 32;

	public var colorSwap:ColorSwap;

	public var inEditor:Bool = false;

	public var animSuffix:String = '';
	public var gfNote:Bool = false;
	public var earlyHitMult:Float = 1;
	public var lateHitMult:Float = 1;
	public var lowPriority:Bool = false;

	public static var SUSTAIN_SIZE:Int = 44;
	public static var swagWidth:Float = 160 * 0.7;
	public static var swagWidthUnscaled:Float = 160;
	public static var colArray:Array<String> = ['purple', 'blue', 'green', 'red'];
	public static var defaultNoteSkin:String = 'noteSkins/NOTE_assets';

	public var noteSplashData:NoteSplashData = {
		disabled: false,
		texture: null,
		antialiasing: !PlayState.isPixelStage,
		useGlobalShader: false,
		// ★ 逐音符的溅射 RGB 初值必须走统一策略（谱面 disableNoteRGB + 玩家 splashRGB +
		//   色相替换模式），此前只看了谱面开关 → 玩家「Splash RGB」选项形同虚设，
		//   而谱面禁用 RGB 时溅射却依旧上色。
		useRGBShader: splashRGBAllowed(null),
		r: -1,
		g: -1,
		b: -1,
		a: ClientPrefs.data.splashAlpha
	};

	public var trackedScale:Float = 0.7; // PsychEK的箭头缩放似乎存在问题，尝试使用这个改善

	public var offsetX:Float = 0;
	public var offsetY:Float = 0;
	public var offsetAngle:Float = 0;
	public var multAlpha:Float = 1;
	public var multSpeed(default, set):Float = 1;

	public var copyX:Bool = true;
	public var copyY:Bool = true;
	public var copyAngle:Bool = true;
	public var copyAlpha:Bool = true;

	public var hitHealth:Float = 0.023;
	public var missHealth:Float = 0.0475;
	public var rating:String = 'unknown';
	public var ratingMod:Float = 0; // 9 = unknown, 0.25 = shit, 0.5 = bad, 0.75 = good, 1 = sick
	public var ratingDisabled:Bool = false;

	public var texture(default, set):String = null;
	public var noteSplashTexture:String = null; // just use fix old mods  XD

	public var noAnimation:Bool = false;
	public var noMissAnimation:Bool = false;
	public var hitCausesMiss:Bool = false;
	public var distance:Float = 2000; // plan on doing scroll directions soon -bb

	public var hitsoundDisabled:Bool = false;
	public var hitsoundChartEditor:Bool = true;
	public var hitsound:String = 'hitsound';

	public var noteSplashBrt:Float = 0;
	public var noteSplashSat:Float = 0;
	public var noteSplashHue:Float = 0;

	private function set_multSpeed(value:Float):Float
	{
		resizeByRatio(value / multSpeed);
		multSpeed = value;
		return value;
	}

	public function resizeByRatio(ratio:Float) // haha funny twitter shit
	{
		if (isSustainNote && animation.curAnim != null && !animation.curAnim.name.endsWith('end'))
		{
			scale.y *= ratio;
			updateHitbox();
		}
	}

	private function set_texture(value:String):String
	{
		if (texture != value)
			reloadNote(value);

		texture = value;
		return value;
	}

	public function defaultRGB()
	{
		if (rgbShader == null || noteData < 0)
			return;

		var arr:Array<FlxColor> = colorRow(curMania(), noteData);
		if (arr == null || arr.length < 3)
			return;

		rgbShader.r = arr[0];
		rgbShader.g = arr[1];
		rgbShader.b = arr[2];
	}

	// ==================================================================================
	// RGB 渲染策略 —— 单一事实来源
	//
	// 以前「是否给音符/受体/溅射上色」的判断散落在 Note / StrumNote / NoteSplash 三处，
	// 各自只看了部分条件，于是：
	//   · 谱面 disableNoteRGB 打开后，NoteSplash 仍然给溅射上色；
	//   · 玩家选项「Splash RGB」从来没有任何代码读取（完全无效）；
	//   · 色相替换模式（noteColorSwap）与 RGB 着色器抢同一个 shader 槽，状态互相打架。
	// 现在统一收口到下面两个函数，任何需要判断的地方都必须调用它们。
	// ==================================================================================

	/** 谱面 json 是否禁用了音符 RGB（谱面设置里的 "Disable Note RGB"） */
	public static function chartDisablesRGB():Bool
	{
		return (PlayState.SONG != null && PlayState.SONG.disableNoteRGB == true);
	}

	/**
	 * 音符（含长条与受体箭头）是否应启用 RGB 调色板着色。
	 * 三个条件任一成立即关闭：谱面 disableNoteRGB / 玩家 noteRGB 关 / 正在用色相替换。
	 */
	public static function noteRGBAllowed():Bool
	{
		if (chartDisablesRGB()) return false;
		if (ClientPrefs.data.noteColorSwap) return false; // 色相替换与 RGB 着色器抢占同一 shader 槽
		if (!ClientPrefs.data.noteRGB) return false;
		return true;
	}

	/**
	 * 音符溅射是否应启用 RGB 调色板着色。
	 * `note` 传入时会额外尊重逐音符类型数据里的 `noteSplashData.useRGBShader`。
	 */
	public static function splashRGBAllowed(?note:Note = null):Bool
	{
		if (chartDisablesRGB()) return false;
		if (ClientPrefs.data.noteColorSwap) return false;
		if (!ClientPrefs.data.splashRGB) return false;
		if (note != null && !note.noteSplashData.useRGBShader) return false;
		return true;
	}

	// ----------------------------------------------------------------------------------
	// Extra Keys（>4K）轨道 → 配色索引
	//
	// `extrakeys.json` 的 keys[mania].notes 把「按键轨号」映射到「视觉轨号」，而
	// arrowRGB / arrowRGBPixel / animations 都是按视觉轨号索引的；例如 10K 的
	// notes = [0,1,2,3,4,9,5,6,7,8]，6K 的 notes = [0,2,3,5,1,8]。
	// 旧代码在多处直接用 `noteData % 4` / `noteData % Note.colArray.length` 取色，
	// 6K/10K 的高轨全部串到错误的颜色（溅射、色相替换尤其明显）。
	// ----------------------------------------------------------------------------------

	/**
	 * 把「按键轨号」翻成「视觉轨号」。mania/keys/notes 任一环节缺失或越界一律返回 0，
	 * 绝不返回负数、绝不越界读（KeyChange 中段、旧存档残值、事件音符 noteData=-1 都会走到这里）。
	 */
	public static function visualLane(mania:Int, noteData:Int):Int
	{
		var ek = ExtraKeysHandler.instance;
		if (ek == null || ek.data == null) return 0;
		var d = ek.data;
		if (d.keys == null || mania < 0 || mania >= d.keys.length) return 0;
		var mode = d.keys[mania];
		if (mode == null || mode.notes == null) return 0;
		if (noteData < 0 || noteData >= mode.notes.length) return 0;
		var v:Int = mode.notes[noteData];
		return (v < 0) ? 0 : v;
	}

	/** 当前生效的配色表：像素舞台用 arrowRGBPixel（缺失时回退常规表），可能为 null */
	public static function colorTable():Array<Array<FlxColor>>
	{
		var a:Array<Array<FlxColor>> = PlayState.isPixelStage ? ClientPrefs.data.arrowRGBPixel : ClientPrefs.data.arrowRGB;
		if (a == null || a.length < 1) a = PlayState.isPixelStage ? ClientPrefs.data.arrowRGB : ClientPrefs.data.arrowRGBPixel;
		if (a == null || a.length < 1) a = ClientPrefs.data.arrowRGB;
		return a;
	}

	/** 轨道的配色行下标（已按配色表长度 clamp），表为空时返回 0 */
	public static function colorIndex(mania:Int, noteData:Int):Int
	{
		var tbl:Array<Array<FlxColor>> = colorTable();
		if (tbl == null || tbl.length < 1) return 0;
		var v:Int = visualLane(mania, noteData);
		if (v >= tbl.length) v = tbl.length - 1;
		if (v < 0) v = 0;
		return v;
	}

	/** 轨道的配色行 [内色, 边色, 描边色]；表为空/行缺失时返回 null（调用方必须判空） */
	public static function colorRow(mania:Int, noteData:Int):Array<FlxColor>
	{
		var tbl:Array<Array<FlxColor>> = colorTable();
		if (tbl == null || tbl.length < 1) return null;
		return tbl[colorIndex(mania, noteData)];
	}

	/**
	 * 轨道对应的「基础 4 色」下标（0=紫/1=蓝/2=绿/3=红）。
	 * 仅用于 arrowHSV 这类固定 4 项的表：视觉轨号到基础色的准确映射来自
	 * EKAnimation.pixel（extrakeys.json 的 animations[].pixel 就是这个字段，
	 * 例如视觉轨 4 是绿色 → pixel=2，而 `4 % 4 = 0` 会错误地算成紫色）。
	 */
	public static function baseColorIndex(mania:Int, noteData:Int):Int
	{
		var v:Int = visualLane(mania, noteData);
		var ek = ExtraKeysHandler.instance;
		if (ek != null && ek.data != null && ek.data.animations != null && v >= 0 && v < ek.data.animations.length)
		{
			var anim = ek.data.animations[v];
			if (anim != null && anim.pixel >= 0) return anim.pixel;
		}
		return v % colArray.length;
	}

	/** 轨道的 arrowHSV 行 [h, s, b]；表缺失/越界返回 null（调用方判空后跳过） */
	public static function hsvRow(mania:Int, noteData:Int):Array<Float>
	{
		var hsv:Array<Array<Float>> = ClientPrefs.data.arrowHSV;
		if (hsv == null || hsv.length < 1) return null;
		var i:Int = baseColorIndex(mania, noteData) % hsv.length;
		if (i < 0) i = 0;
		return hsv[i];
	}

	private function set_noteType(value:String):String
	{
		noteSplashData.texture = PlayState.SONG != null ? PlayState.SONG.splashSkin : 'noteSplashes';
		defaultRGB();
		if (ClientPrefs.data.noteColorSwap){
			// ★ 以前写死 `noteData % 4`：>4K 时按键轨号并不等于基础色下标
			//   （6K 的 notes=[0,2,3,5,1,8]、10K 的 [0,1,2,3,4,9,5,6,7,8]），
			//   高轨会套用错误的 HSV，色相替换模式下颜色明显错乱。
			var hsv:Array<Float> = hsvRow(curMania(), noteData);
			if (hsv != null && hsv.length > 2)
			{
				colorSwap.hue = hsv[0] / 360;
				colorSwap.saturation = hsv[1] / 100;
				colorSwap.brightness = hsv[2] / 100;
			}
		}
		if (noteData > -1 && noteType != value)
		{
			switch (value)
			{
				case 'Hurt Note':
					ignoreNote = mustPress;
					// this used to change the note texture to HURTNOTE_assets.png,
					// but i've changed it to something more optimized with the implementation of RGBPalette:

					// note colors
					rgbShader.r = 0xFF101010;
					rgbShader.g = 0xFFFF0000;
					rgbShader.b = 0xFF990022;

					// splash data and colors
					noteSplashData.r = 0xFFFF0000;
					noteSplashData.g = 0xFF101010;
					noteSplashData.texture = 'noteSplashes/noteSplashes-electric';

					// gameplay data
					lowPriority = true;
					missHealth = isSustainNote ? 0.25 : 0.1;
					hitCausesMiss = true;
					hitsound = 'cancelMenu';
					hitsoundChartEditor = false;
				case 'Alt Animation':
					animSuffix = '-alt';
				case 'No Animation':
					noAnimation = true;
					noMissAnimation = true;
				case 'GF Sing':
					gfNote = true;
			}
			if (value != null && value.length > 1)
				NoteTypesConfig.applyNoteTypeData(this, value);
			if (hitsound != 'hitsound' && ClientPrefs.data.hitsoundVolume > 0)
				Paths.sound(hitsound); // precache new sound for being idiot-proof
			noteType = value;
		}
		if (ClientPrefs.data.noteColorSwap){
			noteSplashHue = colorSwap.hue;
			noteSplashSat = colorSwap.saturation;
			noteSplashBrt = colorSwap.brightness;
		}
		return value;
	}

	public function getIndex(mania:Int, note:Int):Int
	{
		return ExtraKeysHandler.instance.data.keys[mania].notes[note];
	}

	public function getAnimSet(index:Int):EKAnimation
	{
		return ExtraKeysHandler.instance.data.animations[index];
	}

	/**
	 * 越界安全的 EKAnimation 读取（mania/note/animations 越界返回 null，绝不抛异常）：
	 * 用于自绘预览/KeyChange 中段加载等高风险路径，避免 getAnimSet(...).note NPE。
	 */
	public function tryGetAnimSet(mania:Int, note:Int):EKAnimation
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

	/** 该音符生效的 mania：优先生成期所属段（generatedMania），否则当前谱面 mania */
	inline function curMania():Int
	{
		if (generatedMania >= 0)
			return generatedMania;
		return (PlayState.SONG != null) ? PlayState.SONG.mania : 3;
	}
	

	public function new(strumTime:Float, noteData:Int, ?prevNote:Note, ?sustainNote:Bool = false, ?inEditor:Bool = false, ?createdFrom:Dynamic = null, ?generatedMania:Int = -1)
	{
		super();

		this.generatedMania = generatedMania;

		if (PlayState.SONG != null)
		{
			// ★ 防御：ExtraKeysHandler/scales 可能与 PlayState.SONG.mania 不一致（KeyChange 中段加载、
			//   编辑器预览、老存档残值等），mania 越界会读 scales/pixelScales 之外的内存 → NPE/AV。
			//   越界时 clamp 到 [0, length-1]，且数组为 null/空时整体跳过。
			if (ExtraKeysHandler.instance != null && ExtraKeysHandler.instance.data != null)
			{
				var safeMania:Int = curMania();
				var ek = ExtraKeysHandler.instance.data;
				if (ek.scales != null && safeMania >= 0 && safeMania < ek.scales.length)
				{
					trackedScale = ek.scales[safeMania];
					if (PlayState.isPixelStage && ek.pixelScales != null && safeMania < ek.pixelScales.length)
						trackedScale = ek.pixelScales[safeMania];
				}
			}
		}

		if (ClientPrefs.data.hitsoundType != ClientPrefs.defaultData.hitsoundType)
			hitsound = 'hitsounds/' + ClientPrefs.data.hitsoundType;

		animation = new PsychAnimationController(this);

		antialiasing = ClientPrefs.data.antialiasing;
		if (createdFrom == null)
			createdFrom = PlayState.instance;

		if (prevNote == null)
			prevNote = this;

		this.prevNote = prevNote;
		isSustainNote = sustainNote;
		this.inEditor = inEditor;
		this.moves = false;

		x += (ClientPrefs.data.middleScroll ? PlayState.STRUM_X_MIDDLESCROLL : PlayState.STRUM_X) + 50;
		// MAKE SURE ITS DEFINITELY OFF SCREEN?
		y -= 2000;
		this.strumTime = strumTime;
		if (!inEditor)
			this.strumTime += ClientPrefs.data.noteOffset;

		this.noteData = noteData;

		if (noteData > -1)
		{
			try {
				texture = '';
			} catch (e:Dynamic) {
				trace('Error loading note skin: ' + e);
				//reloadNote();
			}

			rgbShader = new RGBShaderReference(this, initializeGlobalRGBShader(noteData, curMania()));
			if (!noteRGBAllowed())
				rgbShader.enabled = false;
			if (ClientPrefs.data.noteColorSwap){
			colorSwap = new ColorSwap();
			shader = colorSwap.shader;

			}
			x += swagWidth * (noteData);
			if (!isSustainNote /* && noteData < colArray.length*/)
			{ // Doing this 'if' check to fix the warnings on Senpai songs
				// ★ 防御：getIndex/getAnimSet 越界时 EKAnimation 引用 null → .note 字段访问 NPE
				var animSet = tryGetAnimSet(curMania(), noteData);
				var animToPlay:String = (animSet != null && animSet.note != null) ? animSet.note : '';
				if (animToPlay != '') animation.play(animToPlay + 'Scroll');
			}
		}

		if (prevNote != null)
			prevNote.nextNote = this;

		if (isSustainNote && prevNote != null)
		{
			alpha = 0.6;
			multAlpha = 0.6;
			hitsoundDisabled = true;
			if (ClientPrefs.data.downScroll)
				flipY = true;

			offsetX += width / 2;
			//copyAngle = false;

			var animToPlay:String = noteAnimPrefix();
			animation.play(animToPlay + 'holdend');

			updateHitbox();

			offsetX -= width / 2;

			if (PlayState.isPixelStage)
				offsetX += 30;

			if (prevNote.isSustainNote)
			{
				prevNote.animation.play(animToPlay + 'hold');

				prevNote.scale.y *= Conductor.stepCrochet / 100 * 1.05;
				if (createdFrom != null && createdFrom.songSpeed != null)
					prevNote.scale.y *= createdFrom.songSpeed;

				if (PlayState.isPixelStage)
				{
					prevNote.scale.y *= 1.19;
					prevNote.scale.y *= (6 / height); // Auto adjust note size
				}
				prevNote.updateHitbox();
				// prevNote.setGraphicSize();
			}

			if (PlayState.isPixelStage)
			{
				scale.y *= PlayState.daPixelZoom;
				updateHitbox();
			}
		}
		else if (!isSustainNote)
		{
			centerOffsets();
			centerOrigin();
		}
		x += offsetX;
	}

	/**
	 * 取（必要时新建）该轨道的全局 RGB 调色板槽。
	 *
	 * ★★ 关键修复：旧实现「越界（含 lane >= 已分配槽位数）一律返回共享的
	 *    globalRgbShaders[0]，且**从不 grow 数组**」，注释声称「拿到共享槽后各自赋值
	 *    r/g/b，由 RGBShaderReference 自动克隆私有 palette」—— 但克隆会把 shader
	 *    重新挂回 sprite，于是只要谱面关闭了 RGB，音符/受体依旧被染色（RGB 关不掉）。
	 *    实测路径：开局 `globalRgbShaders = []`，第一条音符建出 [slot0]；此后 lane 1、2、3
	 *    乃至所有轨道都拿到 slot0，`defaultRGB()` 一赋真实颜色（≠ slot0 的紫色）就克隆 →
	 *    着色器被挂回。所以「进过配色面板（它会把数组撑到 10）再进游戏就正常、直接进游戏
	 *    就翻车」这种玄学现象完全可复现。
	 *
	 *    现在按轨道建槽并按「像素模式 + mania + 该轨配色」上下文取色，颜色一次到位，
	 *    正常情况下完全不会触发克隆；不同键数段共用同一槽位而需要不同颜色时，
	 *    RGBShaderReference 仍会克隆出正确的私有调色板（且不再复活着色器）。
	 *
	 * @param mania 该 sprite 生效的 mania（Note 用 generatedMania、StrumNote 用 strumMania）；
	 *              负数表示「跟随 PlayState.SONG.mania」。
	 */
	public static function initializeGlobalRGBShader(noteData:Int, ?mania:Int = -1):RGBPalette
	{
		if (mania < 0)
			mania = (PlayState.SONG != null) ? PlayState.SONG.mania : 3;
		if (mania < 0) mania = 0;

		// ★ 槽位号必须夹住上限。
		//   键数映射本身不会超过 MAX_RGB_SLOTS（10K 也只有 10 条轨道），但 noteData
		//   会从编辑器/脚本里传进任意值 —— 例如 NoteSplash 调试面板的 noteData 步进器
		//   允许 0..999。不夹的话下面这个 while 一次预览就能把数组撑到上千个 RGBPalette，
		//   而每个 RGBPalette 都自带一个 FlxShader —— 正是本工程反复强调过的
		//   「shader 实例暴涨 → GL uniform 状态被冲垮 → 画面染色异常」事故。
		//   超出上限的轨道在 visualLane() 里本来就一律落到 0，夹到 0 语义完全一致。
		if (noteData < 0 || noteData >= MAX_RGB_SLOTS)
			noteData = 0;

		if (globalRgbShaders == null) globalRgbShaders = [];

		while (globalRgbShaders.length <= noteData)
			globalRgbShaders.push(null);

		var palette:RGBPalette = globalRgbShaders[noteData];
		if (palette == null)
		{
			palette = new RGBPalette();
			globalRgbShaders[noteData] = palette;
		}

		refreshGlobalPalette(palette, noteData, mania);
		return palette;
	}

	/**
	 * 按「像素模式 + mania + 该轨配色」上下文给共享槽取色（原地刷新，绝不新建 shader 实例）。
	 * 上下文与槽位记录一致时直接返回 —— 这样选项里的配色编辑器（NotesSubState）
	 * 往槽位里写的会话工作副本不会被无意覆盖。
	 */
	static function refreshGlobalPalette(palette:RGBPalette, noteData:Int, mania:Int):Void
	{
		if (palette == null) return;

		var row:Array<FlxColor> = colorRow(mania, noteData);

		var ctx:Int = PlayState.isPixelStage ? 1 : 2;
		ctx = ctx * 131 + (mania + 2);
		ctx = ctx * 131 + ((row != null && row.length > 0) ? row[0] : 0);
		ctx = ctx * 131 + ((row != null && row.length > 1) ? row[1] : 0);
		ctx = ctx * 131 + ((row != null && row.length > 2) ? row[2] : 0);
		if (ctx == 0) ctx = -1; // 0 = 「从未取过色」的哨兵值

		if (palette.context == ctx) return;

		if (row != null && row.length > 2)
		{
			palette.r = row[0];
			palette.g = row[1];
			palette.b = row[2];
		}
		palette.mult = 1.0;
		palette.context = ctx;
	}

	var _lastNoteOffX:Float = 0;

	public var originalHeight:Float = 6;
	public var correctionOffset:Float = 0; // dont mess with this

	public function reloadNote(texture:String = null, postfix:String = null)
	{
		reloadPath(texture, postfix);

		var lastScaleY:Float = scale.y;

		var animName:String = null;
		if (animation.curAnim != null)
		{
			animName = animation.curAnim.name;
		}

		if (PlayState.isPixelStage)
		{
			skinPixel = skin;

			// ★ 防御：当前皮肤可能没有像素版贴图（Paths.image 返回 null），
			//   直接读 graphic.width/height 会空指针崩溃，逐级回退到默认像素贴图。
			if (isSustainNote)
			{
				var graphic = Paths.image('pixelUI/' + skinPixel + 'ENDS' + skinPostfix, null, false);
				if (graphic == null) graphic = Paths.image('pixelUI/noteSkins/NOTE_assetsENDS' + skinPostfix, null, false);
				if (graphic == null) graphic = Paths.image('pixelUI/noteSkins/NOTE_assetsENDS', null, false);
				if (graphic != null)
				{
					loadGraphic(graphic, true, Math.floor(graphic.width / 4), Math.floor(graphic.height / 2));
					originalHeight = graphic.height / 2;
				}
			}
			else
			{
				var graphic = Paths.image('pixelUI/' + skinPixel + skinPostfix, null, false);
				if (graphic == null) graphic = Paths.image('pixelUI/noteSkins/NOTE_assets' + skinPostfix, null, false);
				if (graphic == null) graphic = Paths.image('pixelUI/noteSkins/NOTE_assets', null, false);
				if (graphic != null)
					loadGraphic(graphic, true, Math.floor(graphic.width / 4), Math.floor(graphic.height / 5));
			}

			var cm:Int = curMania();
			if (cm >= ExtraKeysHandler.instance.data.pixelScales.length)
				cm = ExtraKeysHandler.instance.data.pixelScales.length - 1;
			setGraphicSize((width * (ExtraKeysHandler.instance.data.pixelScales[cm] + 0.3)) * PlayState.daPixelZoom);

			loadPixelNoteAnims();
			antialiasing = false;

			if (isSustainNote)
			{
				offsetX += _lastNoteOffX;
				_lastNoteOffX = (width - 7) * (PlayState.daPixelZoom / 2);
				offsetX -= _lastNoteOffX;
			}
		}
		else
		{
			if (!Cache.checkFrame(skin + skinPostfix)) addSkinCache(skin + skinPostfix);
				
			frames = Cache.getFrame(skin + skinPostfix);

			if (Cache.currentTrackedAnims.get(skin + skinPostfix) != null) {
			    animation.copyFrom(Cache.currentTrackedAnims.get(skin + skinPostfix));
            	setGraphicSize(Std.int(width * trackedScale));	//等下这都没改吗
				updateHitbox();
			}
			else loadNoteAnims();

			if (!isSustainNote)
			{
				centerOffsets();
				centerOrigin();
			}
		}

		if (isSustainNote)
		{
			scale.y = lastScaleY;
		}
		updateHitbox();

		if (animName != null)
			animation.play(animName, true);
	}

	public static var loadedNote:Map<String, {texture:String, postfix:String, skin:String, skinPostfix:String}> = new Map<String, {texture:String, postfix:String, skin:String, skinPostfix:String}>();
	public static final initSkin:String = 'noteSkins/NOTE_assets';
	static var skin:String;
	static var oldMod:Bool = false;
	var skinPixel:String; //像素箭头路径（数据保存形式类似于defaultNoteSkin）
	static var skinPostfix:String = ''; //箭头设置给的后缀

	public static function reloadPath(texture:String = '', postfix:String = '')
	{
		if (texture == null || texture.length < 1)
			texture = defaultNoteSkin;
		if (postfix == null || postfix.length < 1)
			postfix = '';

		var currentKey = getLoadDataKey(texture, postfix);
		if (loadedNote.exists(currentKey)) {
			skin = loadedNote.get(currentKey).skin;
			skinPostfix = loadedNote.get(currentKey).skinPostfix;
			return;
		}

		var pathPixel = PlayState.isPixelStage ? 'pixelUI/' : '';

		skin = texture + postfix;
		if (skin == defaultNoteSkin) //如果是默认箭头路径
		{
			skin = PlayState.SONG != null ? PlayState.SONG.arrowSkin : null; //兼容了铺面json设置的箭头
			if (skin != null && skin.length > 0) {//当发现铺面json的箭头读取没问题时
				if (Paths.fileExists('images/' + skin + '.png', IMAGE)) {
					skinPostfix = ''; //返回为默认贴图
					loadedNote.set(currentKey, {texture: texture, postfix: postfix, skin: skin, skinPostfix: skinPostfix});
					return; //直接跳过后续读取,获取为铺面json的路径
				} 
			}
			skin = defaultNoteSkin;
		}

		skinPostfix = getNoteSkinPostfix(skin);

		if (!Paths.fileExists('images/' + pathPixel + skin + skinPostfix + '.png', IMAGE)) {
			skinPostfix = '';
		}

		loadedNote.set(currentKey, {texture: texture, postfix: postfix, skin: skin, skinPostfix: skinPostfix});
	}

	public static function getNoteSkinPostfix(?texture:String = ''):String
	{
		if (texture == '') texture = defaultNoteSkin;
		var skin:String = '';
		if (ClientPrefs.data.noteSkin != ClientPrefs.defaultData.noteSkin && texture == initSkin)
			skin = '-' + ClientPrefs.data.noteSkin.trim().toLowerCase().replace(' ', '_');
		return skin;
	}

	public static function getLoadDataKey(texture:String, postfix:String):String
	{
		// ★ key 必须包含 像素/普通 状态：否则在常规模式缓存了 skinPostfix 后切到像素模式，
		//   缓存直接命中并跳过“像素贴图不存在则清空 postfix”的回退检查，
		//   导致 Paths.image('pixelUI/...' + postfix) 返回 null → reloadNote 读 graphic.width 崩溃
		//   （EXCEPTION_ACCESS_VIOLATION，如 -Classic/-Stepmania 皮肤没有像素版）。
		return '${texture}::${postfix}::' + (PlayState.isPixelStage ? 'P' : 'N');
	}

	/**
	 * 该音符的动画图集前缀（`note` 字段，如 purple/blue/green/red）。
	 *
	 * ★ 旧代码是三处裸写 `getAnimSet(getIndex(curMania(), noteData)).note`：
	 *   mania / keys[mania].notes / animations 任一环节越界，`getIndex` 会直接读越界内存，
	 *   `getAnimSet(...)` 会返回 null 继而 `.note` NPE/AV。KeyChange 中段、老存档残值、
	 *   事件音符 noteData=-1、模组自带 extrakeys.json 缺项都会命中。
	 *   这里逐级兜底：本轨 → 本 mania 的轨 0 → mania 0 的轨 0 → 默认色名。
	 */
	function noteAnimPrefix():String
	{
		var animSet = tryGetAnimSet(curMania(), noteData);
		if (animSet == null) animSet = tryGetAnimSet(curMania(), 0);
		if (animSet == null) animSet = tryGetAnimSet(0, 0);
		if (animSet != null && animSet.note != null && animSet.note.length > 0)
			return animSet.note;

		var n:Int = colArray.length;
		return colArray[((noteData % n) + n) % n];
	}

	/** 该音符的像素帧基号（EKAnimation.pixel），越界兜底 0 */
	function notePixelIndex():Int
	{
		var animSet = tryGetAnimSet(curMania(), noteData);
		if (animSet == null) animSet = tryGetAnimSet(curMania(), 0);
		if (animSet == null) animSet = tryGetAnimSet(0, 0);
		return (animSet != null && animSet.pixel >= 0) ? animSet.pixel : 0;
	}

	function loadNoteAnims()
	{
		var noteAnim:String = noteAnimPrefix();

		if (isSustainNote)
		{
			attemptToAddAnimationByPrefix('purpleholdend', 'pruple end hold', 24, true); // this fixes some retarded typo from the original note .FLA
			animation.addByPrefix(noteAnim + 'holdend', noteAnim + ' hold end', 24, true);
			animation.addByPrefix(noteAnim + 'hold', noteAnim + ' hold piece', 24, true);
		}
		else
			animation.addByPrefix(noteAnim + 'Scroll', noteAnim + '0');

		//setGraphicSize(width * ExtraKeysHandler.instance.data.scales[mania]);
		// trace(width, ExtraKeysHandler.instance.data.scales[mania]);
		
		// 改为使用trackedScale设置大小
		setGraphicSize(Std.int(width * trackedScale));

		updateHitbox();
	}

	function loadPixelNoteAnims()
	{
		var noteAnimStr:String = noteAnimPrefix();
		var noteAnimInt:Int = notePixelIndex();

		if (isSustainNote)
		{
			animation.add(noteAnimStr + 'holdend', [noteAnimInt + 4], 24, true);
			animation.add(noteAnimStr + 'hold', [noteAnimInt], 24, true);
		}
		else
			animation.add(noteAnimStr + 'Scroll', [noteAnimInt + 4], 24, true);
	}

	function attemptToAddAnimationByPrefix(name:String, prefix:String, framerate:Float = 24, doLoop:Bool = true)
	{
		var animFrames = [];
		@:privateAccess
		animation.findByPrefix(animFrames, prefix); // adds valid frames to animFrames
		if (animFrames.length < 1)
			return;

		animation.addByPrefix(name, prefix, framerate, doLoop);
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (mustPress)
		{
			if (!ClientPrefs.data.playOpponent)
			{
				canBeHit = (strumTime > Conductor.songPosition - (Conductor.safeZoneOffset * lateHitMult)
					&& strumTime < Conductor.songPosition + (Conductor.safeZoneOffset * earlyHitMult));

				if (strumTime < Conductor.songPosition - Conductor.safeZoneOffset && !wasGoodHit)
					tooLate = true;
			}
			else
			{
				canBeHit = false;

				if (strumTime < Conductor.songPosition + (Conductor.safeZoneOffset * earlyHitMult))
				{
					if ((isSustainNote && prevNote.wasGoodHit) || strumTime <= Conductor.songPosition)
						wasGoodHit = true;
				}
			}
		}
		else
		{
			if (ClientPrefs.data.playOpponent)
			{
				canBeHit = (strumTime > Conductor.songPosition - (Conductor.safeZoneOffset * lateHitMult)
					&& strumTime < Conductor.songPosition + (Conductor.safeZoneOffset * earlyHitMult));

				if (strumTime < Conductor.songPosition - Conductor.safeZoneOffset && !wasGoodHit)
					tooLate = true;
			}
			else
			{
				canBeHit = false;

				if (strumTime < Conductor.songPosition + (Conductor.safeZoneOffset * earlyHitMult))
				{
					if ((isSustainNote && prevNote.wasGoodHit) || strumTime <= Conductor.songPosition)
						wasGoodHit = true;
				}
			}
		}
	}

	override public function destroy()
	{
		super.destroy();
	}

	public function followStrumNote(myStrum:StrumNote, fakeCrochet:Float, songSpeed:Float = 1)
	{
		if (!FlxG.isFullFrame) return;

		var cm:Int = curMania();
		if (cm >= ExtraKeysHandler.instance.data.scales.length)
			cm = ExtraKeysHandler.instance.data.scales.length - 1;
		var Mscale = ExtraKeysHandler.instance.data.scales[cm];
		if (PlayState.isPixelStage) Mscale = ExtraKeysHandler.instance.data.pixelScales[cm];
		var sWidth = Note.swagWidthUnscaled * Mscale;

		var strumX:Float = myStrum.x;
		var strumY:Float = myStrum.y;
		var strumAngle:Float = myStrum.angle;
		var strumAlpha:Float = myStrum.alpha;
		var strumDirection:Float = myStrum.direction;

		distance = (0.45 * (Conductor.songPosition - strumTime) * songSpeed * multSpeed);
		if (!myStrum.downScroll)
			distance *= -1;

		var angleDir = strumDirection * Math.PI / 180;
		if (copyAngle) {
			if (!isSustainNote)
				angle = strumDirection - 90 + strumAngle + offsetAngle;
			else
				angle = strumDirection - 90 + offsetAngle;
		}

		if (copyAlpha)
			alpha = strumAlpha * multAlpha;

		if (copyX)
			x = strumX + offsetX + Math.cos(angleDir) * distance;

		if (copyY)
		{
			y = strumY + offsetY + correctionOffset + Math.sin(angleDir) * distance;
			if (myStrum.downScroll && isSustainNote)
			{
				if (PlayState.isPixelStage)
				{
					y -= PlayState.daPixelZoom * 9.5;
				}
				y -= (frameHeight * scale.y) - (sWidth / 2);
			}
		}
	}

	public function clipToStrumNote(myStrum:StrumNote)
	{
		if (!FlxG.isFullFrame) return;

		var cm:Int = curMania();
		if (cm >= ExtraKeysHandler.instance.data.scales.length)
			cm = ExtraKeysHandler.instance.data.scales.length - 1;
		var Mscale = ExtraKeysHandler.instance.data.scales[cm];
		if (PlayState.isPixelStage)
			Mscale = ExtraKeysHandler.instance.data.pixelScales[cm];

		var sWidth = Note.swagWidthUnscaled * Mscale;

		if (isSustainNote && (mustPress || !ignoreNote) && (!mustPress || (wasGoodHit || (prevNote.wasGoodHit && !canBeHit))))
		{
			var swagRect:FlxRect = clipRect;
			if (swagRect == null) swagRect = FlxRect.get(0, 0, frameWidth, frameHeight);
			
			var time:Float = FlxMath.bound((Conductor.songPosition - strumTime) / (swagRect.height * scale.y / (0.45 * FlxMath.roundDecimal(follow.songSpeed, 2))), 0, 1);
			if (time >= 1) {
				follow.invalidateNote(this);
				return;
			}

			swagRect.x = 0;
			swagRect.y = time * frameHeight;
			swagRect.width = frameWidth;
			swagRect.height = frameHeight;

			clipRect = swagRect;
		}
	}

	public function hitMultUpdate(number:Int = 0, maxNumber:Int = 0)
	{
		if (number == 0)
		{
			earlyHitMult = 0;
			lateHitMult = 1; // 写1而不是0.5是用于修复长条先miss问题
		}
		else if (number == maxNumber)
		{
			earlyHitMult = 0.75;
			lateHitMult = 0.25;
			noAnimation = true; // better anim play
		}
		else
		{
			earlyHitMult = 0.5;
			lateHitMult = 0.75;
		}
	} // this shit can make hold note work better

	@:noCompletion
	override function set_clipRect(rect:FlxRect):FlxRect
	{
		clipRect = rect;

		if (frames != null)
			frame = frames.frames[animation.frameIndex];

		return rect;
	}

	public static function init(target:Dynamic = null)
	{
		loadedNote = new Map<String, {texture:String, postfix:String, skin:String, skinPostfix:String}>();

		if (FileSystem.exists(Paths.mods(Mods.currentModDirectory + '/images/NOTE_assets.png')) && ClientPrefs.data.noteSkin == ClientPrefs.defaultData.noteSkin) {
			defaultNoteSkin = 'NOTE_assets';
			oldMod = true;
			reloadPath(defaultNoteSkin,'');
		} else {
			defaultNoteSkin = initSkin;
			oldMod = false;
			reloadPath(defaultNoteSkin);
		}

		addSkinCache(skin + skinPostfix);

		if (target != null) {
			follow = target;
		}
	}

	static function addSkinCache(skin:String)
	{
		//trace('add skin cache: ' + skin);
		var spr:FlxSprite = new FlxSprite();
		spr.frames = Paths.getSparrowAtlas(skin, null, false);

		for (data in 0...colArray.length)
		{
			if (data == 0) spr.animation.addByPrefix('purpleholdend', 'pruple end hold');
			spr.animation.addByPrefix(Note.colArray[data] + 'holdend', Note.colArray[data] + ' hold end');
			spr.animation.addByPrefix(Note.colArray[data] + 'hold', Note.colArray[data] + ' hold piece');
			spr.animation.addByPrefix(Note.colArray[data] + 'Scroll', Note.colArray[data] + '0');
		}
		Cache.setFrame(skin, {graphic:null, frame:spr.frames});
		Cache.currentTrackedAnims.set(skin, spr.animation);
	}
}

