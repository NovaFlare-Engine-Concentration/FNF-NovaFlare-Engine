package options.base;

import lime.system.Clipboard;
import general.backend.language.Language;
import general.backend.Mods;
#if sys
import sys.io.File;
import sys.FileSystem;
import haxe.io.Path;
import haxe.Json;
import openfl.utils.AssetType;
#end

import flixel.addons.display.FlxBackdrop;
import flixel.addons.display.FlxGridOverlay;
import flixel.addons.display.shapes.FlxShapeCircle;
import flixel.input.keyboard.FlxKey;
import flixel.input.gamepad.FlxGamepadInputID;
import flixel.util.FlxGradient;
import flixel.addons.ui.FlxUIInputText;

import general.shaders.RGBPalette;
import general.shaders.RGBPalette.RGBShaderReference;

import games.objects.StrumNote;
import games.objects.Note;

class NotesSubState extends MusicBeatSubstate
{
	var onModeColumn:Bool = true;
	var curSelectedMode:Int = 0;
	var curSelectedNote:Int = 0;
	var onPixel:Bool = false;
	var dataArray:Array<Array<FlxColor>>;                 // 当前模式的工作副本（会话内编辑不直接写 ClientPrefs）
	var workNormal:Array<Array<FlxColor>>;               // ★ 常规样式组：进入时的深拷贝，保存时才写回
	var workPixel:Array<Array<FlxColor>>;                // ★ 像素样式组：同上
	static var _pmTog:Int = 0;                           // ★ 诊断：模式切换累计计数（第 8 轮定位 lane 0 发黑）
	var _enterPixelStage:Bool = false;                   // ★ 进入子状态时 PlayState.isPixelStage 快照，切换贴图后用于安全恢复全局
	var _dbgTick:Int = 0;                                // ★ 诊断：update 节流计数器（第 8 轮定位 lane 0 发黑）

	var copyButton:FlxSprite;
	var pasteButton:FlxSprite;

	var colorGradient:FlxSprite;
	var colorGradientSelector:FlxSprite;
	var colorPalette:FlxSprite;
	var colorWheel:FlxSprite;
	var colorWheelSelector:FlxSprite;

	var alphabetR:Alphabet;
	var alphabetG:Alphabet;
	var alphabetB:Alphabet;

	var modeBG:FlxSprite;
	var notesBG:FlxSprite;

	// controller support
	var controllerPointer:FlxSprite;
	var _lastControllerMode:Bool = false;
	var tipTxt:FlxText;

	var AndroidColorGet:FlxUIInputText;
	var underline_text_BG:FlxSprite;
	var LengthCheck:String = '';
	var ColorCheck:String = '';

	// ============================================================
	// v3 新版 UI（HTML 原型移植）— 不删改既有元素，仅新增/重定位
	// ============================================================
	static var KEY_LABELS:Array<String> = ["A","S","D","F","V","N","J","K","L",";","SCROLL","Z","X","C","SPACE","ENTER"];
	static var ATTRS:Array<String> = ["内色", "描边", "外轮廓"];
	static inline var LEFT_ANCHOR_PX:Int = 5;        // ★ 第 1 条 note 距窗口左边缘 5px
	static var _pixelCopyPromptShown:Bool = false;   // ★ 幽灵弹窗修复：复制提示每次会话只弹一次

	var origNormal:Array<Array<Int>> = [];
	var origPixel:Array<Array<Int>> = [];
	var applied:Bool = false;
	var showOrig:Bool = false;
	var dirty:Bool = false;
	var brightness:Float = 1;
	var compact:Bool = false;

	// —— 布局缓存 ——
	var uiRightX:Float = 0; var uiRightW:Float = 0;
	var editX:Float = 0; var editW:Float = 0;
	var contentX:Float = 0; var contentW:Float = 0;
	var laneX:Float = 0; var laneW:Float = 0; var laneTop:Float = 30; var laneH:Float = 0; var laneTotalW:Float = 0;
	var secAttrsY:Float = 0; var tileY:Float = 0; var tileH:Float = 86; var tileW:Float = 0;
	var toolsY:Float = 0; var toolsBottom:Float = 0;
	var hexHelpY:Float = 0; var rgbY:Float = 0; var hexLineY:Float = 0;
	var paletteY:Float = 0; var paletteTipY:Float = 0; var pickY:Float = 0;
	var wheelSize:Float = 0; var wheelX:Float = 0; var wheelY:Float = 0;
	var gradX:Float = 0; var gradY:Float = 0;
	var skinNotePos:{x:Float, y:Float} = {x:0, y:0};
	var modeNotePos:Array<{x:Float, y:Float}> = [];

	// —— 左区轨道（10 轨）——
	var laneBGs:Array<FlxSprite> = [];
	var laneNos:Array<FlxText> = [];
	var laneNoteTop:Array<StrumNote> = [];
	var laneNoteMid:Array<StrumNote> = [];
	var laneSustains:Array<Array<FlxSprite>> = [];
	var lanePal:Array<RGBPalette> = [];
	var lanePalOrig:Array<RGBPalette> = [];   // ★ 下排箭头专用：始终显示默认（进入前）样式
	var laneKeyBG:Array<FlxSprite> = [];
	var laneKeyTxt:Array<FlxText> = [];
	var leftPaneBG:FlxSprite; var leftSkyline:FlxSprite; var judgeLine:FlxSprite;
	var leftTitle:FlxText; var leftHint:FlxText; var leftTips:FlxText; var leftEsc:FlxText; var previewHint:FlxText;

	// —— 右区框架 ——
	var rightPaneBG:FlxSprite; var divider:FlxSprite; var rHeader:FlxSprite; var rHeaderLine:FlxSprite;
	var rTitle:FlxText; var rSub:FlxText;
	var applyBox:UIBox; var applyTxt:FlxText; var applyDot:FlxSprite;
	var exitBox:UIBox; var exitTxt:FlxText;
	// ★ 样式对照列已删除：对照功能并入左区两排箭头（上排=当前样式，下排=默认样式）

	// —— 编辑列 ——
	var secAttrsTxt:FlxText;
	var tileBox:Array<UIBox> = []; var tileName:Array<FlxText> = []; var tileSw:Array<FlxSprite> = [];
	var tileHex:Array<FlxText> = []; var tileRgb:Array<FlxText> = [];
	var tileResetBox:Array<UIBox> = []; var tileResetTxt:Array<FlxText> = [];
	var modeSegBox:Array<UIBox> = []; var modeSegTxt:Array<FlxText> = [];
	var hexLabel:FlxText; var curSwatch:FlxSprite; var hexHelp:FlxText;
	var paletteTip:FlxText;
	var footerBG:FlxSprite; var dirtyBadge:FlxText; var selInfo:FlxText;
	var toastBox:UIBox; var toastTxt:FlxText; var toastTimer:Float = 0;

	// —— 弹窗 ——
	var exitDim:FlxSprite; var exitModalBox:UIBox; var exitTitle:FlxText; var exitMsg:FlxText;
	var btnSaveQuitBox:UIBox; var btnSaveQuitTxt:FlxText;
	var btnDiscQuitBox:UIBox; var btnDiscQuitTxt:FlxText;
	var btnOopsBox:UIBox; var btnOopsTxt:FlxText;
	var saveDim:FlxSprite; var saveModalBox:UIBox; var saveOk:FlxText; var saveTitle:FlxText; var saveMsg:FlxText;
	var btnOkBox:UIBox; var btnOkTxt:FlxText;
	var exitModalOpen:Bool = false; var saveModalOpen:Bool = false;

	#if sys
	var copyPromptOpen:Bool = false;
	var copyPromptMembers:Array<FlxSprite> = [];
	var copyPromptYes:FlxSprite;
	var copyPromptNo:FlxSprite;
	var _missingImages:Array<String> = [];
	var _missingData:Bool = false;
	var _missingModDir:String = '';
	// ★ 黑色弹窗彻底移除：缺资源时静默自动复制，用轻提示告知（不再全屏打断）
	var copyToast:FlxText;
	var copyToastTimer:Float = 0;
	#end

	public function new()
	{
		_enterPixelStage = PlayState.isPixelStage;
		PlayState.SONG = {
			song: 'Test',
			notes: [],
			events: [],
			bpm: 150.0,
			mania: ExtraKeysHandler.instance.data.maxKeys,
			needsVoices: true,
			player1: 'bf',
			player2: 'dad',
			gfVersion: 'gf',
			speed: 1,
			format: 'na',
			stage: 'stage'
		};

		super();

		#if DISCORD_ALLOWED
		DiscordClient.changePresence("Note Colors Menu", null);
		#end

		Note.init();

		// ---------- 布局计算（仅一次）----------
		computeLayout();

		var bg:FlxSprite = new FlxSprite(0, 0).makeGraphic(FlxG.width, FlxG.height, FlxColor.WHITE);
		bg.scrollFactor.set();
		bg.alpha = 0.5;
		add(bg);

		modeNotes = new FlxTypedGroup<FlxSprite>();
		add(modeNotes);

		myNotes = new FlxTypedGroup<StrumNote>();
		add(myNotes);

		// 章节底（复用既有 modeBG/notesBG 字段，重定位为「属性区 / 轨道区」底）
		modeBG = new FlxSprite(contentX + 6, tileY - 6).makeGraphic(Math.floor(tileW * 3 + 16), Math.floor(tileH + 12), 0xFF000000);
		modeBG.visible = false; modeBG.alpha = 0.22; add(modeBG);
		notesBG = new FlxSprite(laneX - 3, laneTop - 3).makeGraphic(Math.floor(laneTotalW + 6), Math.floor(laneH + 6), 0xFF000000);
		notesBG.visible = false; notesBG.alpha = 0.16; add(notesBG);

		// 框架 / 右区 / 对照（v3 新增）
		buildFrameUI();
		buildEditColumn();
		// ★ 对照列已删除（buildCompareColumn），样式对照由左区两排箭头呈现

		// 既有取色控件在 buildEditColumn 末尾已构建（buildColorTools），此处不再重复

		captureOrig();

		leftHint = mkTxt(16, 10, uiRightX - 32, "轨道预览 / 点击轨道以编辑该轨样式组", 12, 0xFF7F8898);
		leftHint.text = "轨道预览 / 点击轨道以编辑该轨样式组";

		spawnNotes();
		buildModals();
		buildToast();
		updateNotes(true);
		refreshDirty();
		syncPanel();
		FlxG.sound.play(Paths.sound('scrollMenu'), 0.6);

		var tipText:String = controls.mobileC
			? "点击 C 重置所选音符部件。"
			: "按住 " + (!controls.controllerMode ? "Shift" : "左肩键") + " + 按 RESET 键完全重置所选音符。";
		tipTxt = mkTxt(16, FlxG.height - 54, uiRightX - 32, tipText, 14, 0xFFFFFFFF, true);
		updateTip();

		controllerPointer = new FlxShapeCircle(0, 0, 20, {thickness: 0}, FlxColor.WHITE);
		controllerPointer.offset.set(20, 20);
		controllerPointer.screenCenter();
		controllerPointer.alpha = 0.6;
		add(controllerPointer);

		FlxG.mouse.visible = !ClientPrefs.data.needMobileControl && !controls.controllerMode;
		controllerPointer.visible = controls.controllerMode;
		_lastControllerMode = controls.controllerMode;

		// ★ 面板内禁用音量热键：flixel 默认把数字 0 绑成"静音"，
		//   用户在 HEX 输入框里敲 0 会顺带把声音关掉。销毁时恢复。
		ClientPrefs.toggleVolumeKeys(false);

		addVirtualPad(NONE, B_C);
		virtualPad.buttonC.x = 0;
		virtualPad.buttonC.y = FlxG.height - 135;
		virtualPad.buttonB.x = FlxG.width - virtualPad.buttonB.width;

		#if sys
		checkAndPromptPixelArrowAssets();
		#end
	}

	function updateTip()
	{
		if (controls.mobileC)
		{
			// do sex
		}
		else
		{
			tipTxt.text = 'Hold ' + (!controls.controllerMode ? 'Shift' : 'Left Shoulder Button') + ' + Press RESET key to fully reset the selected Note.';
		}
	}

	var _storedColor:FlxColor;
	var changingNote:Bool = false;
	var holdingOnObj:FlxSprite;
	var allowedTypeKeys:Map<FlxKey, String> = [
		ZERO => '0',
		ONE => '1',
		TWO => '2',
		THREE => '3',
		FOUR => '4',
		FIVE => '5',
		SIX => '6',
		SEVEN => '7',
		EIGHT => '8',
		NINE => '9',
		NUMPADZERO => '0',
		NUMPADONE => '1',
		NUMPADTWO => '2',
		NUMPADTHREE => '3',
		NUMPADFOUR => '4',
		NUMPADFIVE => '5',
		NUMPADSIX => '6',
		NUMPADSEVEN => '7',
		NUMPADEIGHT => '8',
		NUMPADNINE => '9',
		A => 'A',
		B => 'B',
		C => 'C',
		D => 'D',
		E => 'E',
		F => 'F'
	];

	override function update(elapsed:Float)
	{
		#if sys
		if (copyPromptOpen)
		{
			handleCopyPromptInput();
			super.update(elapsed);
			return;
		}
		// ★ 轻提示淡出
		if (copyToastTimer > 0 && copyToast != null)
		{
			copyToastTimer -= elapsed;
			copyToast.alpha = Math.max(0, Math.min(1, copyToastTimer / 1.5));
		}
		#end

		LengthCheck = AndroidColorGet.text;
		// ★ 强制白名单清洗：无论输入来自键盘、剪贴板还是 IME，一律剥掉非 0-9/A-F 字符。
		//   （flixel-ui 的 filter 只挂在 onKeyDown 上，IME/textInput 路径会漏进来非法字符）
		if (AndroidColorGet != null && LengthCheck != null && LengthCheck.length > 0)
		{
			var clean:String = ~/[^0-9a-fA-F]/g.replace(LengthCheck, "");
			clean = clean.toUpperCase();
			if (clean.length > 6) clean = clean.substring(0, 6);
			if (clean != LengthCheck)
			{
				AndroidColorGet.text = clean;
				AndroidColorGet.caretIndex = clean.length;
				LengthCheck = clean;
			}
		}

		for (i in 0...myNotes.members.length) {
			var note = myNotes.members[i];
			var targetY = i - curSelectedNote;
			var lerpVal:Float = Math.exp(-elapsed * 9.6);
			var diffX:Float = 225;
			var diffY:Float = 200;
			if (targetY < 0) diffY = -200;

			note.x = FlxMath.lerp((targetY * diffX) + (notesBG.x + ((notesBG.width / 2) - (note.width / 2))), note.x, lerpVal);
			note.y = FlxMath.lerp((targetY * 1.3 * diffY) + (notesBG.y + ((notesBG.height / 2) - (note.height / 2))), note.y, lerpVal);
		}

		// ★ HEX 输入框聚焦时，ESC/退格属于文本编辑，不触发退出弹窗（用户报告：退格反复弹窗）
		var inputFocused:Bool = (AndroidColorGet != null && AndroidColorGet.hasFocus);
		if (controls.BACK && !inputFocused)
		{
			if (exitModalOpen)
				closeExitModal();
			else if (saveModalOpen)
				closeSaveModal();
			else
				askExit();
		}

		// ★ 弹窗开启时独占输入：仅处理弹窗，跳过其余交互
		if (exitModalOpen || saveModalOpen)
		{
			handleModalInput();
			super.update(elapsed);
			return;
		}

		super.update(elapsed);

		// Early controller checking
		if (FlxG.gamepads.anyJustPressed(ANY))
			controls.controllerMode = true;
		else if (FlxG.mouse.justPressed || FlxG.mouse.deltaScreenX != 0 || FlxG.mouse.deltaScreenY != 0)
			controls.controllerMode = false;
		//

		var changedToController:Bool = false;
		if (controls.controllerMode != _lastControllerMode)
		{
			// trace('changed controller mode');
			FlxG.mouse.visible = !ClientPrefs.data.needMobileControl && !controls.controllerMode;
			controllerPointer.visible = controls.controllerMode;

			// changed to controller mid state
			if (controls.controllerMode)
			{
				controllerPointer.x = FlxG.mouse.x;
				controllerPointer.y = FlxG.mouse.y;
				changedToController = true;
			}
			// changed to keyboard mid state
			/*else
				{
					FlxG.mouse.x = controllerPointer.x;
					FlxG.mouse.y = controllerPointer.y;
				}
				// apparently theres no easy way to change mouse position that i know, oh well
			 */
			_lastControllerMode = controls.controllerMode;
			updateTip();
		}

		// controller things
		var analogX:Float = 0;
		var analogY:Float = 0;
		var analogMoved:Bool = false;
		if (controls.controllerMode && (changedToController || FlxG.gamepads.anyInput()))
		{
			for (gamepad in FlxG.gamepads.getActiveGamepads())
			{
				analogX = gamepad.getXAxis(LEFT_ANALOG_STICK);
				analogY = gamepad.getYAxis(LEFT_ANALOG_STICK);
				analogMoved = (analogX != 0 || analogY != 0);
				if (analogMoved)
					break;
			}
			controllerPointer.x = Math.max(0, Math.min(FlxG.width, controllerPointer.x + analogX * 1000 * elapsed));
			controllerPointer.y = Math.max(0, Math.min(FlxG.height, controllerPointer.y + analogY * 1000 * elapsed));
		}
		var controllerPressed:Bool = (controls.controllerMode && controls.ACCEPT);
		//

		if (FlxG.keys.justPressed.CONTROL && !inputFocused)
			setPixelMode(!onPixel);

		if (LengthCheck.length == 6 && ColorCheck != LengthCheck)
		{
			ColorCheck = LengthCheck;
			applyColor(LengthCheck);
			updateColors();
		}

		// ★ 方向键换轨/换属性已移除：鼠标点击轨道即可选择（用户要求），
		//   且输入框内方向键是移动光标，不应抢走。
		//   （原 hexTypeNum 光标逻辑随大字号 HEX 显示一并废弃）

		// Copy/Paste buttons
		var generalMoved:Bool = (FlxG.mouse.justMoved || analogMoved);
		var generalPressed:Bool = (FlxG.mouse.justPressed || controllerPressed);
		if (generalMoved)
		{
			copyButton.alpha = 0.6;
			pasteButton.alpha = 0.6;
		}

		if (pointerOverlaps(copyButton))
		{
			copyButton.alpha = 1;
			if (generalPressed)
			{
				Clipboard.text = getShaderColor().toHexString(false, false);
				FlxG.sound.play(Paths.sound('scrollMenu'), 0.6);
				trace('copied: ' + Clipboard.text);
			}
		}
		else if (pointerOverlaps(pasteButton))
		{
			pasteButton.alpha = 1;
			if (generalPressed)
			{
				var formattedText = Clipboard.text.trim().toUpperCase().replace('#', '').replace('0x', '');
				var newColor:Null<FlxColor> = FlxColor.fromString('#' + formattedText);
				// trace('#${Clipboard.text.trim().toUpperCase()}');
				if (newColor != null && formattedText.length == 6)
				{
					setShaderColor(newColor);
					FlxG.sound.play(Paths.sound('scrollMenu'), 0.6);
					_storedColor = getShaderColor();
					updateColors();
				}
				else // errored
					FlxG.sound.play(Paths.sound('cancelMenu'), 0.6);
			}
		}

		// Click
		if (generalPressed)
		{
			if (!handleV3Click())
			{
				if (pointerOverlaps(modeNotes) && modeNotes.visible)
				{
					modeNotes.forEachAlive(function(note:FlxSprite)
					{
						if (curSelectedMode != note.ID && pointerOverlaps(note))
						{
							modeBG.visible = notesBG.visible = false;
							curSelectedMode = note.ID;
							onModeColumn = true;
							updateNotes();
							FlxG.sound.play(Paths.sound('scrollMenu'), 0.6);
						}
					});
				}
				else if (pointerOverlaps(myNotes) && myNotes.visible)
				{
					myNotes.forEachAlive(function(note:StrumNote)
					{
						if (curSelectedNote != note.ID && pointerOverlaps(note))
						{
							modeBG.visible = notesBG.visible = false;
							curSelectedNote = note.ID;
							onModeColumn = false;
							// ★ 防御：note.ID 若越界 globalRgbShaders 长度，.shader 直接 NPE；
							//   调 initializeGlobalRGBShader 后再赋值。
							var sh2 = Note.initializeGlobalRGBShader(note.ID);
							if (sh2 != null && bigNote != null) bigNote.rgbShader.parent = sh2;
							if (sh2 != null && bigNote != null) bigNote.shader = sh2.shader;
							updateNotes();
							FlxG.sound.play(Paths.sound('scrollMenu'), 0.6);
						}
					});
				}
				else if (pointerOverlaps(colorWheel))
				{
					_storedColor = getShaderColor();
					holdingOnObj = colorWheel;
				}
				else if (pointerOverlaps(colorGradient))
				{
					_storedColor = getShaderColor();
					holdingOnObj = colorGradient;
				}
				else if (pointerOverlaps(colorPalette))
				{
					var col = colorPalette.pixels.getPixel32(Std.int((pointerX() - colorPalette.x) / colorPalette.scale.x),
						Std.int((pointerY() - colorPalette.y) / colorPalette.scale.y));
					applyColor(hexStr(col));
					FlxG.sound.play(Paths.sound('scrollMenu'), 0.6);
				}
				else if (pointerOverlaps(skinNote) && skinNote.visible)
				{
					setPixelMode(!onPixel);
				}
				else
					holdingOnObj = null;
			}
		}
		// holding
		if (holdingOnObj != null)
		{
			if (FlxG.mouse.justReleased || (controls.controllerMode && controls.justReleased('accept')))
			{
				holdingOnObj = null;
				_storedColor = getShaderColor();
				updateColors();
				FlxG.sound.play(Paths.sound('scrollMenu'), 0.6);
			}
			else if (generalMoved || generalPressed)
			{
				if (holdingOnObj == colorGradient)
				{
					var newBrightness = 1 - FlxMath.bound((pointerY() - colorGradient.y) / colorGradient.height, 0, 1);
					_storedColor.alpha = 1;
					if (_storedColor.brightness == 0) // prevent bug
						applyColor(hexStr(FlxColor.fromRGBFloat(newBrightness, newBrightness, newBrightness)));
					else
						applyColor(hexStr(FlxColor.fromHSB(_storedColor.hue, _storedColor.saturation, newBrightness)));
					updateColors();
				}
				else if (holdingOnObj == colorWheel)
				{
					var center:FlxPoint = FlxPoint.weak(colorWheel.x + colorWheel.width / 2, colorWheel.y + colorWheel.height / 2);
					var mouse:FlxPoint = pointerFlxPoint();
					var hue:Float = FlxMath.wrap(FlxMath.wrap(Std.int(mouse.degreesTo(center)), 0, 360) - 90, 0, 360);
					var sat:Float = FlxMath.bound(mouse.dist(center) / colorWheel.width * 2, 0, 1);
					// trace('$hue, $sat');
					if (sat != 0)
						applyColor(hexStr(FlxColor.fromHSB(hue, sat, _storedColor.brightness)));
					else
						applyColor(hexStr(FlxColor.fromRGBFloat(_storedColor.brightness, _storedColor.brightness, _storedColor.brightness)));
					updateColors();
				}
			}
		}
		else if (virtualPad.buttonC.justPressed || controls.RESET)
		{
			var shift:Bool = FlxG.keys.pressed.SHIFT || FlxG.gamepads.anyJustPressed(LEFT_SHOULDER);
			resetAttrV3(curSelectedMode, shift);
		}

		// 以下诊断块在每帧 update() 中无条件执行：3 轨 × (3 次 try/catch + 最多 9 次数组读 + 字符串拼接)，
		// 240TPS 下每秒上千次无谓分配。它只服务于「lane 0 随切换变黑」的定向排查，
		// 因此改为默认关闭；需要时用 -D NF_LANE_DEBUG 编译。
		#if NF_LANE_DEBUG
		// ★★★ 诊断（第 8 轮）：每帧实测 lane 0 上/下排箭头的【实时渲染状态】，
		//   捕捉 refreshLaneColors 之后、渲染之前的任何 shader/tint/alpha 篡改。
		//   只打前 3 轨（laneNoteTop/Mid 与 lanePal/lanePalOrig 严格对应），异常立即打、正常每 45 帧抽样。
		_dbgTick = (_dbgTick + 1) % 45;
		if (laneNoteTop != null && laneNoteTop.length > 0 && lanePal.length > 0)
		{
			for (di in 0...3)
			{
				var top:StrumNote = (di < laneNoteTop.length) ? laneNoteTop[di] : null;
				var mid:StrumNote = (di < laneNoteMid.length) ? laneNoteMid[di] : null;
				var pal:RGBPalette = (di < lanePal.length) ? lanePal[di] : null;
				var po:RGBPalette = (di < lanePalOrig.length) ? lanePalOrig[di] : null;
			if (top != null && pal != null)
			{
				var topMatch = (top.shader == pal.shader);
				var topCol = top.color;
				var topRv:String = '?', topGv:String = '?', topBv:String = '?';
				try { topRv = '[' + pal.shader.r.value[0] + ',' + pal.shader.r.value[1] + ',' + pal.shader.r.value[2] + ']'; } catch (e:Dynamic) {}
				try { topGv = '[' + pal.shader.g.value[0] + ',' + pal.shader.g.value[1] + ',' + pal.shader.g.value[2] + ']'; } catch (e:Dynamic) {}
				try { topBv = '[' + pal.shader.b.value[0] + ',' + pal.shader.b.value[1] + ',' + pal.shader.b.value[2] + ']'; } catch (e:Dynamic) {}
				var topFW:Int = top.frameWidth;
				var topFrames:Bool = (top.frames != null);
				var topTex:String = top.texture;
				var topBad = !topMatch || topCol != 0xFFFFFFFF || !top.exists || !top.visible || !topFrames || topFW <= 0;
				if (_dbgTick == 0 || topBad)
					trace('[Lane0Live] i=$di TOP match=$topMatch col=0x${StringTools.hex(topCol & 0xFFFFFFFF, 8)} alpha=${top.alpha} exist=${top.exists} vis=${top.visible} '
						+ 'fw=$topFW frames=$topFrames tex=$topTex isoPix=${PlayState.isPixelStage} onPixel=$onPixel '
						+ 'palR=$topRv palG=$topGv palB=$topBv');
			}
				if (mid != null && po != null)
				{
					var midMatch = (mid.shader == po.shader);
					var midCol = mid.color;
					var midBad = !midMatch || midCol != 0xFFFFFFFF || !mid.exists || !mid.visible;
					if (_dbgTick == 0 || midBad)
						trace('[Lane0Live] i=$di MID match=$midMatch col=0x${StringTools.hex(midCol & 0xFFFFFFFF, 8)} alpha=${mid.alpha} exist=${mid.exists} vis=${mid.visible}');
				}
			}
		}
		#end
	}

	// ============================================================
	// v3 新版 UI 构建 / 同步（HTML 原型移植）
	// ============================================================

	function mkTxt(x:Float, y:Float, w:Float, text:String, size:Float, color:Int, ?outline:Bool = false):FlxText
	{
		var t:FlxText = new FlxText(x, y, w, text, Std.int(size));
		t.setFormat(Paths.font(Language.get('fontName', 'main') + '.ttf'), Std.int(size), color);
		if (outline) t.setBorderStyle(FlxTextBorderStyle.OUTLINE, 0xFF000000, 2);
		t.scrollFactor.set();
		add(t);
		return t;
	}

	function makeBox(w:Float, h:Float, fill:Int, border:Int, ?borderAlpha:Float = 1, ?fillAlpha:Float = 1):UIBox
	{
		var b:UIBox = new UIBox();
		b.border = new FlxSprite(0, 0).makeGraphic(Math.floor(w) + 2, Math.floor(h) + 2, 0xFFFFFFFF);
		b.border.color = border; b.border.alpha = borderAlpha;
		b.fill = new FlxSprite(0, 0).makeGraphic(Math.floor(w), Math.floor(h), 0xFFFFFFFF);
		b.fill.color = fill; b.fill.alpha = fillAlpha;
		add(b.border); add(b.fill);
		return b;
	}
	function boxPos(b:UIBox, x:Float, y:Float)
	{
		b.border.setPosition(x - 1, y - 1);
		b.fill.setPosition(x, y);
	}
	function boxColors(b:UIBox, fill:Int, border:Int)
	{
		b.fill.color = fill; b.border.color = border;
	}
	function overBox(b:UIBox):Bool
	{
		return pointerOverlaps(b.border) || pointerOverlaps(b.fill);
	}

	function computeLayout()
	{
		var W:Float = FlxG.width, H:Float = FlxG.height;
		uiRightW = W * 0.34;
		if (uiRightW < 480) uiRightW = 480;
		if (uiRightW > 680) uiRightW = 680;
		if (uiRightW > W - 520) uiRightW = W - 520;
		if (uiRightW < 300) uiRightW = 300;
		uiRightX = W - uiRightW;

		// ★ 对照列已并入左区两排箭头，编辑区直接贴住蓝灰分隔线（divider 5px）
		editX = uiRightX + 5;
		editW = W - editX;
		contentX = editX + 12;
		contentW = editW - 24;
		compact = contentW < 360;

		laneTop = 30;
		laneH = H - 30 - 64;
		var n:Int = laneCount();
		laneW = Math.floor((uiRightX - LEFT_ANCHOR_PX - 8) / n);
		if (laneW < 40) laneW = 40;
		if (laneW > 200) laneW = 200;
		laneTotalW = laneW * n;
		laneX = LEFT_ANCHOR_PX;
		var maxX = uiRightX - laneTotalW - 4;
		if (maxX < 4) maxX = 4;
		if (laneX > maxX) laneX = maxX;

		// ★ 页眉压缩后（34px），属性区上移、卡片加高，腾出更多空间给三个设置项
		secAttrsY = 10;
		tileH = compact ? 96 : 104;
		tileW = (contentW - 16) / 3;
		tileY = secAttrsY + 20;
		toolsY = tileY + tileH + 10;
	}
	function laneCount():Int
	{
		var a = ClientPrefs.data.arrowRGB;
		if (a == null || a.length < 1) a = ClientPrefs.data.arrowRGBPixel;
		if (a == null || a.length < 1) return 1;
		return a.length;
	}

	function buildFrameUI()
	{
		leftPaneBG = new FlxSprite(0, 0).makeGraphic(Math.floor(uiRightX), FlxG.height, 0xFF0A0D13);
		leftPaneBG.alpha = 0.92; add(leftPaneBG);
		leftSkyline = new FlxSprite(0, FlxG.height - 110).makeGraphic(Math.floor(uiRightX), 110, 0xFF141C2C);
		leftSkyline.alpha = 0.22; add(leftSkyline);

		rightPaneBG = new FlxSprite(uiRightX + 5, 0).makeGraphic(Math.floor(uiRightW - 5), FlxG.height, 0xFF12151D);
		rightPaneBG.alpha = 0.98; add(rightPaneBG);
		divider = new FlxSprite(uiRightX, 0).makeGraphic(5, FlxG.height, 0xFF64769E); add(divider);
		rHeader = new FlxSprite(uiRightX + 5, 0).makeGraphic(Math.floor(uiRightW - 5), 34, 0xFF151922);
		rHeader.alpha = 0.98; add(rHeader);
		rHeaderLine = new FlxSprite(uiRightX + 5, 34).makeGraphic(Math.floor(uiRightW - 5), 1, 0xFFFFFFFF);
		rHeaderLine.alpha = 0.08; add(rHeaderLine);

		// ★ 标题与「暂应用 / 退出」按钮整体移到左下提示行右侧，
		//   右区顶部空间让给 NOTE 属性三卡（用户要求）
		var bw:Float = compact ? 112 : 132;
		var exitW:Float = 68;
		var bottomY:Float = FlxG.height - 36;

		exitBox = makeBox(exitW, 32, 0xFF3A2228, 0xFF8A4A52);
		boxPos(exitBox, uiRightX - 16 - exitW, bottomY);
		exitTxt = mkTxt(exitBox.fill.x, bottomY, exitW, "退出", 13, 0xFFFFC2C2); exitTxt.alignment = CENTER;

		applyBox = makeBox(bw, 32, 0xFF2C3140, 0xFF4C5468);
		boxPos(applyBox, exitBox.fill.x - 8 - bw, bottomY);
		applyTxt = mkTxt(applyBox.fill.x, bottomY, bw, "暂应用", 13, 0xFFCFD6E4); applyTxt.alignment = CENTER;
		applyDot = new FlxSprite(applyBox.fill.x + 10, bottomY + 13).makeGraphic(7, 7, 0xFF8B93A6); add(applyDot);

		// 标题 + 副标题：紧贴按钮左侧，右对齐
		rTitle = mkTxt(applyBox.fill.x - 8 - 80, FlxG.height - 31, 80, "颜色设置", 14, 0xFFEEF1F6);
		rTitle.alignment = RIGHT;
		rSub = mkTxt(rTitle.x - 8 - 178, FlxG.height - 29, 178, "Note Color Style / 样式组编辑器", 11, 0xFF7D8698);
		rSub.alignment = RIGHT; rSub.wordWrap = false;

		// 左下操作提示：宽度让位给标题/按钮，空间不足时隐藏
		leftTips = mkTxt(16, FlxG.height - 28, Math.max(rSub.x - 16 - 24, 0), "R=重置所选部件 / Shift+R=整轨重置（鼠标点击选择轨道与属性）", 11, 0xFFFFFFFF, true);
		leftTips.wordWrap = false;
		leftTips.alpha = 0.62;
		if (leftTips.width < 130) leftTips.visible = false;
		leftEsc = mkTxt(uiRightX - 154, 10, 146, "ESC = 退出（将询问是否保存）", 11, 0xFF7F8898);
		leftEsc.alignment = RIGHT;
		previewHint = mkTxt(16, 30, uiRightX - 32, "当前预览：原样式（未修改）", 12, 0xFFC3CAD6, true);
	}

	function buildEditColumn()
	{
		secAttrsTxt = mkTxt(contentX, secAttrsY, contentW, "NOTE 属性 — 三种颜色（内色 / 描边 / 外轮廓）", compact ? 13 : 14, 0xFF8B95A8);

		for (a in 0...3)
		{
			var bx = contentX + a * (tileW + 8);
			var b = makeBox(tileW, tileH, 0xFF1A1F2A, 0xFF2B3242);
			boxPos(b, bx, tileY);
			tileBox.push(b);

			var name = mkTxt(bx + 8, tileY + 6, tileW - 14, (a + 1) + " / " + ATTRS[a], compact ? 13.5 : 15, 0xFFAAB3C4);
			tileName.push(name);

			// ★ 色块/HEX/RGB 紧跟标题排布（此前贴卡片底部，tileH 加高后中间空一大截）
			var swY:Float = tileY + 30;
			var sw = new FlxSprite(bx + 8, swY).makeGraphic(compact ? 24 : 28, compact ? 24 : 28, 0xFFFFFFFF);
			add(sw); tileSw.push(sw);

			var hex = mkTxt(bx + 42, swY + 2, tileW - 48, "", compact ? 13.5 : 15, 0xFFEEF2F9);
			hex.wordWrap = false; // ★ 卡片窄，7 位 hex 文本不许换行叠字
			tileHex.push(hex);
			var rgb = mkTxt(bx + 42, swY + 19, tileW - 48, "", 12.5, 0xFF79839A);
			rgb.wordWrap = false;
			tileRgb.push(rgb);

			var rb = makeBox(22, 22, 0xFF1A1F2A, 0xFF39415A);
			boxPos(rb, bx + tileW - 27, tileY + 5);
			tileResetBox.push(rb);
			tileResetTxt.push(mkTxt(rb.fill.x, tileY + 5, 22, "↺", 13, 0xFF9AA4B8));
		}

		// 工具行（流式，超宽自动换行）
		var x = contentX;
		var y = toolsY;
		var rh = compact ? 34 : 36;
		var gap = 6;
		function place(w:Float):Float
		{
			if (x + w > contentX + contentW + 0.5) { x = contentX; y += rh + 8; }
			var px = x; x += w + gap; return px;
		}
		skinNotePos = {x: place(36), y: y};
		var segW = (compact ? 46 : 62) * 2;
		var segX = place(segW);
		for (m in 0...2)
		{
			var mb = makeBox(compact ? 46 : 62, rh, 0xFF1A1F2A, 0xFF39415A);
			boxPos(mb, segX + m * (compact ? 46 : 62), y);
			modeSegBox.push(mb);
			modeSegTxt.push(mkTxt(mb.fill.x, y, compact ? 46 : 62, m == 0 ? "常规" : "像素", compact ? 13 : 14.5, 0xFF98A2B5));
			modeSegTxt[m].alignment = CENTER;
		}
		var copyX = place(40);
		copyButton = new FlxSprite(copyX, y).loadGraphic(Paths.image('noteColorMenu/copy'));
		copyButton.setGraphicSize(40, 36); copyButton.updateHitbox(); copyButton.alpha = 0.6; add(copyButton);
		var pasteX = place(40);
		pasteButton = new FlxSprite(pasteX, y).loadGraphic(Paths.image('noteColorMenu/paste'));
		pasteButton.setGraphicSize(40, 36); pasteButton.updateHitbox(); pasteButton.alpha = 0.6; add(pasteButton);

		var hexInputW = compact ? 104 : 120;
		var swatchW = compact ? 38 : 44;
		var unitW = 34 + 8 + hexInputW + 8 + swatchW;
		var unitX = place(unitW);
		hexLabel = mkTxt(unitX, y + (rh - 14) / 2, 34, "HEX", compact ? 13 : 14.5, 0xFF8B95A8);
		AndroidColorGet = new FlxUIInputText(unitX + 34 + 8, y + (rh - (compact ? 34 : 36)) / 2, hexInputW, '', compact ? 20 : 24);
		AndroidColorGet.focusGained = () -> FlxG.stage.window.textInputEnabled = true;
		// ★ 顺序不能反：customFilterPattern 的 setter 内部会把 filterMode 置为 CUSTOM_FILTER；
		//   而 set_filterMode 会立刻调用 filter()，其中 `pattern.replace(...)` 无判空。
		//   若先设 filterMode = CUSTOM_FILTER，此时 pattern 仍为 null → EReg.replace(null) 崩溃
		//   （EXCEPTION_ACCESS_VIOLATION 读 0x8）。故先给 pattern，再设 filterMode。
		// ★ 半角取反字符集 + 全局标志：flixel-ui 的 filter() 是“把匹配到的字符删掉”，
		//   所以模式必须是“非法字符集合”。原来写成 ~/[0-9a-fA-F]/ 语义完全反了 ——
		//   A-F/0-9 会被当成非法字符删掉（表现为键盘敲不进任何字符），
		//   而非法字符因不匹配被原样注入。正确写法：~/[^0-9a-fA-F]/g
		AndroidColorGet.customFilterPattern = ~/[^0-9a-fA-F]/g;
		AndroidColorGet.filterMode = 4; // FlxInputText.CUSTOM_FILTER（此时 pattern 已就绪）
		AndroidColorGet.forceCase = 2; // FlxInputText.UPPER_CASE
		AndroidColorGet.maxLength = 6;
		AndroidColorGet.backgroundColor = 0xFF0D1016;
		AndroidColorGet.fieldBorderColor = 0xFF4A5468;
		AndroidColorGet.fieldBorderThickness = 2;
		AndroidColorGet.color = 0xFFF2F6FC;      // ★ 默认是黑色文字，深色框上不可见
		AndroidColorGet.caretColor = 0xFFF2F6FC;
		AndroidColorGet.wordWrap = false;        // ★ 防止 6 位 HEX 换行溢出
		AndroidColorGet.font = Paths.font(Language.get('fontName', 'main') + '.ttf');
		AndroidColorGet.antialiasing = ClientPrefs.data.antialiasing;
		add(AndroidColorGet);
		curSwatch = new FlxSprite(unitX + 34 + 8 + hexInputW + 8, y).makeGraphic(swatchW, rh, 0xFFFFFFFF);
		curSwatch.color = 0xFF000000; add(curSwatch);
		LengthCheck = AndroidColorGet.text;

		toolsBottom = y + rh;
		hexHelpY = toolsBottom + 6;
		hexHelp = mkTxt(contentX, hexHelpY, contentW, "0-9 A-F（大小写均可）/ 点击不清空 / 满 6 位自动应用 / Enter 应用", 13, 0xFF8D97AA);
		hexHelp.wordWrap = true; hexHelp.autoSize = false;

		rgbY = hexHelpY + (compact ? 32 : 36);
		// ★ 重复的大字号 HEX 显示已删除：HEX 值直接由输入框渲染（未聚焦时同步显示当前值）。
		//   RGB 数字按用户要求缩小（makeColorAlphabet 缩放 0.45 → 0.34）。
		var rlabel = mkTxt(contentX, rgbY + 10, contentW, "RGB", 13, 0xFF8D97AA);

		alphabetR = makeColorAlphabet(contentX + 44, rgbY + 4);
		alphabetG = makeColorAlphabet(contentX + 130, rgbY + 4);
		alphabetB = makeColorAlphabet(contentX + 216, rgbY + 4);

		paletteY = rgbY + 50;
		paletteTipY = paletteY + 72 + 6;
		paletteTip = mkTxt(contentX, paletteTipY, contentW, "色板（点击取色）/ 复用原新版色图布局", 13, 0xFF8D97AA);
		pickY = paletteTipY + 18 + 10;

		var maxH = FlxG.height - 36 - 8 - pickY;
		wheelSize = contentW - 20 - 10;
		if (wheelSize > maxH) wheelSize = maxH;
		if (wheelSize < 120) wheelSize = 120;
		gradX = contentX; gradY = pickY;
		wheelX = contentX + 20 + 10; wheelY = pickY;

		// 底部信息条
		footerBG = new FlxSprite(editX, FlxG.height - 36).makeGraphic(Math.floor(editW - 24), 36, 0xFF0D0F14);
		footerBG.alpha = 0.9; add(footerBG);
		dirtyBadge = mkTxt(editX + 12, FlxG.height - 30, 140, "● 有未保存修改", 13, 0xFFFFB454);
		dirtyBadge.visible = false;
		selInfo = mkTxt(editX + 12, FlxG.height - 30, editW - 24, "", 13, 0xFFA5AEC0);
		selInfo.alignment = RIGHT;

		// 取色控件（色轮 / 渐变条 / 色板 / 字母）
		buildColorTools();
	}

	function buildColorTools()
	{
		colorGradient = FlxGradient.createGradientFlxSprite(20, Math.floor(wheelSize), [FlxColor.WHITE, FlxColor.BLACK]);
		colorGradient.setPosition(gradX, gradY); add(colorGradient);
		colorGradientSelector = new FlxSprite(gradX - 7, gradY).makeGraphic(34, 12, FlxColor.WHITE);
		colorGradientSelector.offset.y = 6; add(colorGradientSelector);

		colorPalette = new FlxSprite(contentX, paletteY).loadGraphic(Paths.image('noteColorMenu/palette', false));
		colorPalette.scale.set(contentW / 16, 72 / 4);
		colorPalette.updateHitbox();
		colorPalette.antialiasing = false; add(colorPalette);

		colorWheel = new FlxSprite(wheelX, wheelY).loadGraphic(Paths.image('noteColorMenu/colorWheel'));
		colorWheel.setGraphicSize(Math.floor(wheelSize), Math.floor(wheelSize));
		colorWheel.updateHitbox(); add(colorWheel);
		colorWheelSelector = new FlxShapeCircle(0, 0, 8, {thickness: 0}, FlxColor.WHITE);
		colorWheelSelector.offset.set(8, 8); colorWheelSelector.alpha = 0.6; add(colorWheelSelector);

		for (l in alphabetR.letters) l.color = 0xFFFFFFFF;
		for (l in alphabetG.letters) l.color = 0xFFFFFFFF;
		for (l in alphabetB.letters) l.color = 0xFFFFFFFF;
	}

	// ★ buildCompareColumn 已删除：样式对照并入左区两排箭头（上=当前，下=默认）

	function buildModals()
	{
		exitDim = new FlxSprite(0, 0).makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		exitDim.alpha = 0.6; exitDim.visible = false; add(exitDim);
		exitModalBox = makeBox(460, 200, 0xFF171B24, 0xFF39415A);
		boxPos(exitModalBox, FlxG.width / 2 - 230, FlxG.height / 2 - 100);
		exitModalBox.border.visible = false; exitModalBox.fill.visible = false;
		exitTitle = mkTxt(exitModalBox.fill.x + 16, exitModalBox.fill.y + 14, 428, "是否保存样式组？", 19, 0xFFFFFFFF);
		exitMsg = mkTxt(exitModalBox.fill.x + 16, exitModalBox.fill.y + 56, 428, "当前样式组存在未保存的修改。\n【保存并退出】写入修改；【不保存并退出】还原为进入前的样式。", 14, 0xFF98A2B5);
		exitMsg.wordWrap = true; exitMsg.autoSize = false; exitMsg.height = 60;
		btnSaveQuitBox = makeBox(130, 38, 0xFF2E8B57, 0xFF2E8B57);
		boxPos(btnSaveQuitBox, exitModalBox.fill.x + 28, exitModalBox.fill.y + 140);
		btnSaveQuitTxt = mkTxt(btnSaveQuitBox.fill.x, exitModalBox.fill.y + 144, 130, "保存并退出", 14, 0xFFFFFFFF); btnSaveQuitTxt.alignment = CENTER;
		btnDiscQuitBox = makeBox(130, 38, 0xFFA34444, 0xFFA34444);
		boxPos(btnDiscQuitBox, exitModalBox.fill.x + 170, exitModalBox.fill.y + 140);
		btnDiscQuitTxt = mkTxt(btnDiscQuitBox.fill.x, exitModalBox.fill.y + 144, 130, "不保存并退出", 14, 0xFFFFFFFF); btnDiscQuitTxt.alignment = CENTER;
		btnOopsBox = makeBox(110, 38, 0xFF495160, 0xFF495160);
		boxPos(btnOopsBox, exitModalBox.fill.x + 312, exitModalBox.fill.y + 140);
		btnOopsTxt = mkTxt(btnOopsBox.fill.x, exitModalBox.fill.y + 144, 110, "误触了", 14, 0xFFCFD6E2); btnOopsTxt.alignment = CENTER;

		saveDim = new FlxSprite(0, 0).makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		saveDim.alpha = 0.6; saveDim.visible = false; add(saveDim);
		saveModalBox = makeBox(360, 170, 0xFF171B24, 0xFF39415A);
		boxPos(saveModalBox, FlxG.width / 2 - 180, FlxG.height / 2 - 85);
		saveModalBox.border.visible = false; saveModalBox.fill.visible = false;
		saveOk = mkTxt(saveModalBox.fill.x + (360 - 44) / 2, saveModalBox.fill.y + 14, 44, "✓", 44, 0xFF5DFF9C);
		saveOk.alignment = CENTER;
		saveTitle = mkTxt(saveModalBox.fill.x + 16, saveModalBox.fill.y + 66, 328, "保存成功", 19, 0xFF5DFF9C);
		saveTitle.alignment = CENTER;
		saveMsg = mkTxt(saveModalBox.fill.x + 16, saveModalBox.fill.y + 92, 328, "样式组已保存", 14, 0xFF98A2B5);
		saveMsg.alignment = CENTER;
		btnOkBox = makeBox(120, 38, 0xFF2E8B57, 0xFF2E8B57);
		boxPos(btnOkBox, saveModalBox.fill.x + 120, saveModalBox.fill.y + 120);
		btnOkTxt = mkTxt(btnOkBox.fill.x, saveModalBox.fill.y + 124, 120, "确定", 14, 0xFFFFFFFF); btnOkTxt.alignment = CENTER;

		setModalVisible(false);
	}
	function setModalVisible(v:Bool)
	{
		exitDim.visible = v && exitModalOpen;
		exitModalBox.border.visible = v && exitModalOpen; exitModalBox.fill.visible = v && exitModalOpen;
		exitTitle.visible = exitModalBox.fill.visible; exitMsg.visible = exitModalBox.fill.visible;
		btnSaveQuitBox.border.visible = exitModalBox.fill.visible; btnSaveQuitBox.fill.visible = exitModalBox.fill.visible;
		btnSaveQuitTxt.visible = exitModalBox.fill.visible;
		btnDiscQuitBox.border.visible = exitModalBox.fill.visible; btnDiscQuitBox.fill.visible = exitModalBox.fill.visible;
		btnDiscQuitTxt.visible = exitModalBox.fill.visible;
		btnOopsBox.border.visible = exitModalBox.fill.visible; btnOopsBox.fill.visible = exitModalBox.fill.visible;
		btnOopsTxt.visible = exitModalBox.fill.visible;

		saveDim.visible = v && saveModalOpen;
		saveModalBox.border.visible = v && saveModalOpen; saveModalBox.fill.visible = v && saveModalOpen;
		saveOk.visible = saveModalBox.fill.visible; saveTitle.visible = saveModalBox.fill.visible;
		saveMsg.visible = saveModalBox.fill.visible;
		btnOkBox.border.visible = saveModalBox.fill.visible; btnOkBox.fill.visible = saveModalBox.fill.visible;
		btnOkTxt.visible = saveModalBox.fill.visible;
	}

	function buildToast()
	{
		toastBox = makeBox(260, 36, 0xFF10141C, 0xFF3A4358);
		boxPos(toastBox, FlxG.width / 2 - 130, 70);
		toastBox.border.visible = false; toastBox.fill.visible = false;
		toastTxt = mkTxt(toastBox.fill.x, 70 + 8, 260, "", 13, 0xFFE8EDF6);
		toastTxt.alignment = CENTER; toastTxt.visible = false;
	}

	function captureOrig()
	{
		origNormal = copyInts(ClientPrefs.data.arrowRGB);
		origPixel = copyInts(ClientPrefs.data.arrowRGBPixel);
		// ★ 会话内工作副本：所有编辑只落在副本上，保存时才写回 ClientPrefs。
		//   （此前 dataArray 直接引用 ClientPrefs 数组，未保存的编辑会实时漏进内存配置，
		//     任何其他路径触发 saveSettings 都会把未保存的修改写进磁盘）
		workNormal = copyColors(ClientPrefs.data.arrowRGB);
		workPixel = copyColors(ClientPrefs.data.arrowRGBPixel);
	}
	/** 深拷贝配色表，并把 null 通道清洗为白色（null 经 Int 强转会变 0 = 纯黑，绝不能放进调色板） */
	function copyColors(a:Array<Array<FlxColor>>):Array<Array<FlxColor>>
	{
		var out:Array<Array<FlxColor>> = [];
		if (a == null) return out;
		for (row in a)
		{
			var r:Array<FlxColor> = [];
			if (row != null) for (c in row) { var ci:Int = c; r.push(ci == 0 ? 0xFFFFFFFF : c); }			out.push(r);
		}
		return out;
	}
	function copyInts(a:Array<Array<FlxColor>>):Array<Array<Int>>
	{
		var out:Array<Array<Int>> = [];
		if (a == null) return out;
		for (row in a)
		{
			var r:Array<Int> = [];
			if (row != null) for (c in row) { var ci:Int = c; r.push(ci == 0 ? 0xFFFFFFFF : c); } // ★ 0/null→白，绝不进 0（纯黑）
			out.push(r);
		}
		return out;
	}
	function intsOf(a:Array<Array<FlxColor>>):Array<Array<Int>>
	{
		return copyInts(a);
	}
	function applyOrigToPrefs(src:Array<Array<Int>>, dst:Array<Array<FlxColor>>)
	{
		if (dst == null || src == null) return;
		for (i in 0...dst.length)
		{
			if (i >= src.length) break;
			for (j in 0...dst[i].length)
			{
				if (j >= src[i].length) break;
				dst[i][j] = src[i][j];
			}
		}
	}
	function arraysEqualInt(a:Array<Array<Int>>, b:Array<Array<Int>>):Bool
	{
		if (a == null || b == null) return a == b;
		if (a.length != b.length) return false;
		for (i in 0...a.length)
		{
			if (a[i].length != b[i].length) return false;
			for (j in 0...a[i].length) if (a[i][j] != b[i][j]) return false;
		}
		return true;
	}
	function refreshDirty()
	{
		// ★ dirty 现在对比工作副本（编辑不再直接写 ClientPrefs）
		dirty = !arraysEqualInt(origNormal, intsOf(workNormal))
			|| !arraysEqualInt(origPixel, intsOf(workPixel));
		dirtyBadge.visible = dirty;
	}

	function hexStr(c:Int):String
	{
		return StringTools.hex(c & 0x00FFFFFF, 6).toUpperCase();
	}

	function rgbToHsv(r:Int, g:Int, b:Int):{h:Float, s:Float, v:Float}
	{
		var rf = r / 255.0, gf = g / 255.0, bf = b / 255.0;
		var mx = Math.max(rf, Math.max(gf, bf)), mn = Math.min(rf, Math.min(gf, bf));
		var dd = mx - mn, h = 0.0;
		if (dd != 0)
		{
			if (mx == rf) h = ((gf - bf) / dd) % 6;
			else if (mx == gf) h = (bf - rf) / dd + 2;
			else h = (rf - gf) / dd + 4;
			h *= 60; if (h < 0) h += 360;
		}
		return {h: h, s: mx == 0 ? 0 : dd / mx, v: mx};
	}
	function hsvToRgb(h:Float, s:Float, v:Float):FlxColor
	{
		h = (h % 360 + 360) % 360 / 360;
		var i = Math.floor(h * 6), f = h * 6 - i;
		var p = v * (1 - s), q = v * (1 - f * s), t = v * (1 - (1 - f) * s);
		var r:Float = 0, g:Float = 0, b:Float = 0;
		switch (i % 6)
		{
			case 0: r = v; g = t; b = p;
			case 1: r = q; g = v; b = p;
			case 2: r = p; g = v; b = t;
			case 3: r = p; g = q; b = v;
			case 4: r = t; g = p; b = v;
			default: r = v; g = p; b = q;
		}
		return FlxColor.fromRGB(Math.round(r * 255), Math.round(g * 255), Math.round(b * 255));
	}

	function pushAllGlobal()
	{
		applyWorkToGlobal();
	}
	/** 把 dataArray（会话工作副本）原地写入 globalRgbShaders：槽位不足时补建，多余时由调用方裁剪。 */
	function applyWorkToGlobal()
	{
		if (dataArray == null) return;
		if (Note.globalRgbShaders == null) Note.globalRgbShaders = [];
		for (i in 0...dataArray.length)
		{
			var p:RGBPalette = (i < Note.globalRgbShaders.length) ? Note.globalRgbShaders[i] : null;
			if (p == null) p = new RGBPalette();
			if (i < Note.globalRgbShaders.length) Note.globalRgbShaders[i] = p;
			else Note.globalRgbShaders.push(p);
			var row = dataArray[i];
			if (row != null && row.length > 2) { p.r = row[0]; p.g = row[1]; p.b = row[2]; }
		}
	}
	function refreshLaneColors()
	{
		var arr:Array<Array<Int>> = showOrig
			? (onPixel ? origPixel : origNormal)
			// ★ 数据源改为会话工作副本：此前读 ClientPrefs（进入时的旧值），编辑后轨道箭头
			//   不实时反映修改，且与右侧属性卡（读 dataArray）互相矛盾。
			: intsOf(onPixel ? workPixel : workNormal);
		var orig:Array<Array<Int>> = onPixel ? origPixel : origNormal;
		for (i in 0...lanePal.length)
		{
			var p = lanePal[i]; if (p == null) continue;
			if (i >= arr.length) break;
			var row = arr[i]; if (row == null || row.length < 3) continue;
			// ★ 损坏守卫：内/描/外全 0 的行 = 脏数据（null 经 Int 强转的产物），
			//   画出来是纯黑箭头。跳过并保持该轨当前颜色，同时打印诊断定位写入源。
			if (row[0] == 0 && row[1] == 0 && row[2] == 0)
			{
				trace('[NotesSubState] WARNING: all-zero color row at lane $i '
					+ '(source=' + (showOrig ? 'orig' : 'work') + ', onPixel=$onPixel)，已跳过');
				continue;
			}
			p.r = row[0]; p.g = row[1]; p.b = row[2];
			// ★ 长条：每轨 2 根（上/下）。上根=当前样式（随编辑变化），
			//   下根=默认样式（与下排对照箭头一致，不随编辑变化）。
			var bi:Int = i * 2;
			var orow:Array<Int> = (i < orig.length && orig[i] != null && orig[i].length > 2) ? orig[i] : row;
			if (orow[0] == 0 && orow[1] == 0 && orow[2] == 0)
				orow = row; // 默认样式行损坏 → 用当前行兜底，避免对照列全黑
			if (bi + 1 < laneSustains.length)
			{
				setSus(laneSustains[bi], p.r, p.g, p.b);
				setSus(laneSustains[bi + 1], orow[0], orow[1], orow[2]);
			}
			// ★ 下排箭头始终显示默认（进入前）样式 —— 样式对照并入左区
			var po = (i < lanePalOrig.length) ? lanePalOrig[i] : null;
			if (po != null)
			{
				po.r = orow[0]; po.g = orow[1]; po.b = orow[2];
			}
		}
		#if NF_LANE_DEBUG
		// ★★★ 诊断（第 8 轮定位 lane 0 随切换变黑）：打印前 3 轨调色板实际值与绑定关系
		// （refreshLaneColors 每次调用都无条件打 3 条 trace，默认关闭）
		for (dbg in 0...3)
		{
			if (dbg >= lanePal.length || lanePal[dbg] == null) continue;
			var p = lanePal[dbg];
			var bound = (dbg < laneNoteTop.length && laneNoteTop[dbg] != null) ? (laneNoteTop[dbg].shader == p.shader) : false;
			var w:Array<FlxColor> = (!onPixel && workNormal != null && dbg < workNormal.length && workNormal[dbg] != null) ? workNormal[dbg]
				: (onPixel && workPixel != null && dbg < workPixel.length && workPixel[dbg] != null) ? workPixel[dbg] : null;
		var rv:String = '?';
		try { rv = '[' + p.shader.r.value[0] + ',' + p.shader.r.value[1] + ',' + p.shader.r.value[2] + ']'; } catch (e:Dynamic) {}
		var gv:String = '?';
		try { gv = '[' + p.shader.g.value[0] + ',' + p.shader.g.value[1] + ',' + p.shader.g.value[2] + ']'; } catch (e:Dynamic) {}
		var bv:String = '?';
		try { bv = '[' + p.shader.b.value[0] + ',' + p.shader.b.value[1] + ',' + p.shader.b.value[2] + ']'; } catch (e:Dynamic) {}
		trace('[LaneDbg] i=$dbg onPixel=$onPixel '
			+ 'pal.r=${hexStr(p.r)} g=${hexStr(p.g)} b=${hexStr(p.b)} mult=${p.mult} '
			+ 'rArr=$rv gArr=$gv bArr=$bv glProgram=' + (p.shader.glProgram != null ? 'Y' : 'N')
			+ ' boundTop=$bound '
			+ 'work=' + (w != null ? '[${hexStr(w[0])},${hexStr(w[1])},${hexStr(w[2])}]' : 'null'));
		}
		#end
	}
	function syncLanes()
	{
		for (i in 0...laneBGs.length)
			laneBGs[i].alpha = (i == curSelectedNote) ? 1 : 0;
	}

	function syncPanel()
	{
		if (dataArray == null) return;
		for (a in 0...3)
		{
			var row = dataArray[curSelectedNote];
			var c:FlxColor = (row != null && a < row.length) ? row[a] : 0xFFFFFFFF;
			if (a < tileSw.length) { tileSw[a].color = c; tileHex[a].text = hexStr(c); tileRgb[a].text = Std.string(c.red) + " " + c.green + " " + c.blue; }
			if (a < tileName.length) tileName[a].color = (a == curSelectedMode) ? 0xFFFFFFFF : 0xFFAAB3C4;
			if (a < tileBox.length) boxColors(tileBox[a], a == curSelectedMode ? 0xFF1C2434 : 0xFF1A1F2A, a == curSelectedMode ? 0xFF7FC1FF : 0xFF2B3242);
		}
		if (AndroidColorGet != null && !AndroidColorGet.hasFocus)
			AndroidColorGet.text = hexStr(getShaderColor());
		var col = getShaderColor();
		if (alphabetR != null) { alphabetR.text = Std.string(col.red); alphabetG.text = Std.string(col.green); alphabetB.text = Std.string(col.blue); }

		// 暂应用按钮状态
		var on = applied && !showOrig;
		boxColors(applyBox, on ? 0xFF1F6B43 : 0xFF2C3140, on ? 0xFF2F9A61 : 0xFF4C5468);
		applyTxt.text = showOrig ? "返回新样式" : (applied ? "已暂应用" : "暂应用");
		applyTxt.color = on ? 0xFFD9FFE9 : 0xFFCFD6E4;
		applyDot.color = on ? 0xFF5DFF9C : 0xFF8B93A6;

		// 常规 / 像素
		boxColors(modeSegBox[0], !onPixel ? 0xFF2E6FCE : 0xFF1A1F2A, !onPixel ? 0xFF2E6FCE : 0xFF39415A);
		boxColors(modeSegBox[1], onPixel ? 0xFF2E6FCE : 0xFF1A1F2A, onPixel ? 0xFF2E6FCE : 0xFF39415A);
		modeSegTxt[0].color = !onPixel ? 0xFFFFFFFF : 0xFF98A2B5;
		modeSegTxt[1].color = onPixel ? 0xFFFFFFFF : 0xFF98A2B5;

		if (curSwatch != null) curSwatch.color = col;

		// ★ 底部"有未保存修改"徽章与轨道信息同排，徽章约 110px 宽；
		//   dirty 时用紧凑文案，避免两条文字互相重叠
		var laneLabel = '轨道 ' + (curSelectedNote + 1) + '（' + KEY_LABELS[curSelectedNote % KEY_LABELS.length] + '）';
		selInfo.text = dirty ? (laneLabel + ' / ' + ATTRS[curSelectedMode])
			: (laneLabel + ' / ' + ATTRS[curSelectedMode] + ' / ' + (onPixel ? '像素' : '常规') + '箭头'
			+ (showOrig ? ' / 预览原样式' : ''));

		if (previewHint != null)
			previewHint.text = showOrig ? "当前预览：原样式（对照中 / 再点「暂应用」返回新样式）"
				: (dirty ? "当前预览：新样式（修改即时生效）" : "当前预览：原样式（未修改）");
	}

	// ★ syncCompare 已删除：对照由左区两排箭头直接呈现（下排箭头绑定 lanePalOrig）

	function setSus(layer:Array<FlxSprite>, inner:Int, border:Int, outline:Int)
	{
		if (layer == null || layer.length < 3) return;
		layer[0].color = outline; layer[1].color = border; layer[2].color = inner;
	}

	function selectLane(i:Int)
	{
		if (dataArray == null || dataArray.length < 1) return;
		if (i < 0) i = dataArray.length - 1;
		if (i >= dataArray.length) i = 0;
		var sh = Note.initializeGlobalRGBShader(i);
		if (sh != null && bigNote != null) { bigNote.rgbShader.parent = sh; bigNote.shader = sh.shader; }
		if (i == curSelectedNote) { syncLanes(); syncPanel(); return; }
		curSelectedNote = i;
		modeBG.visible = false; notesBG.visible = true;
		syncLanes(); syncPanel();
	}
	function selectAttrTile(a:Int)
	{
		if (a < 0) a = 2;
		if (a > 2) a = 0;
		curSelectedMode = a;
		modeBG.visible = true; notesBG.visible = false;
		syncPanel();
	}

	function toggleApply()
	{
		if (!dirty) { toast("尚无修改：编辑颜色后将自动暂应用新样式"); return; }
		showOrig = !showOrig;
		refreshLaneColors(); refreshDirty(); syncPanel();
		toast(showOrig ? "正在预览原样式（对照）— 再点一次返回新样式" : "已返回新样式预览");
	}
	function applyColor(hexv:String)
	{
		setShaderColor(FlxColor.fromString('#' + hexv));
		if (!applied) { applied = true; toast("修改已实时生效（新样式已暂覆盖预览）", true); }
		refreshDirty(); pushAllGlobal(); refreshLaneColors(); syncPanel(); updateColors();
	}

	function askExit()
	{
		exitModalOpen = true; setModalVisible(true);
	}
	function closeExitModal()
	{
		exitModalOpen = false; setModalVisible(false);
	}
	function doQuit(save:Bool)
	{
		if (save)
		{
			// ★ 只有这里才把会话内副本写回 ClientPrefs 并落盘
			if (workNormal != null && workNormal.length > 0) ClientPrefs.data.arrowRGB = workNormal;
			if (workPixel != null && workPixel.length > 0) ClientPrefs.data.arrowRGBPixel = workPixel;
			ClientPrefs.saveSettings();
			pushAllGlobal();
			origNormal = copyInts(ClientPrefs.data.arrowRGB);
			origPixel = copyInts(ClientPrefs.data.arrowRGBPixel);
			applied = false; showOrig = false;
			exitModalOpen = false; saveModalOpen = true; setModalVisible(true);
		}
		else
		{
			// ★ 编辑从未写过 ClientPrefs（工作副本方案），无需恢复，直接退出
			//   （全局着色器在 switchState 后按 ClientPrefs 重建，无需手动回推）
			FlxTransitionableState.skipNextTransIn = true; FlxTransitionableState.skipNextTransOut = true;
			MusicBeatState.switchState(new options.OptionsState());
		}
	}
	function closeSaveModal()
	{
		saveModalOpen = false; setModalVisible(false);
		FlxTransitionableState.skipNextTransIn = true; FlxTransitionableState.skipNextTransOut = true;
		MusicBeatState.switchState(new options.OptionsState());
	}
	function handleModalInput()
	{
		var pressed = FlxG.mouse.justPressed;
		if (saveModalOpen)
		{
			if (pressed && overBox(btnOkBox)) closeSaveModal();
			if (FlxG.keys.justPressed.ENTER) closeSaveModal();
			return;
		}
		if (FlxG.keys.justPressed.ESCAPE) { closeExitModal(); return; }
		if (pressed)
		{
			if (overBox(btnSaveQuitBox)) doQuit(true);
			else if (overBox(btnDiscQuitBox)) doQuit(false);
			else if (overBox(btnOopsBox)) closeExitModal();
		}
		if (FlxG.keys.justPressed.ENTER) doQuit(true);
	}

	function toast(msg:String, ?good:Bool = false)
	{
		toastTxt.text = msg; toastTxt.color = good ? 0xFFB9F5CF : 0xFFE8EDF6;
		toastBox.border.color = good ? 0xFF2F9A61 : 0xFF3A4358;
		toastBox.border.visible = true; toastBox.fill.visible = true; toastTxt.visible = true;
		toastTimer = 1.8;
	}

	function setPixelMode(p:Bool)
	{
		if (onPixel == p) return;
		onPixel = p;
		// ★ 切换样式组后退出对照预览：预览的“原样式”只对切换前的那组有意义，
		//   跨组保留 showOrig 会让用户莫名其妙地卡在“预览原样式”（返回新样式）状态
		showOrig = false;
		spawnNotes();
		updateNotes(true);
		// ★★★ 核心修复（"逐轨变黑"）：
		//   旧实现每次切换都走 spawnNotes() → buildLaneGroup()，把 20 个 StrumNote +
		//   60 个 makeGraphic 精灵整体销毁重建。每个 makeGraphic 都会新建一个
		//   FlxGraphic，而每个 FlxGraphic 自带独立 FlxGraphicsShader；切换 N 次就凭空
		//   多出几百个着色器实例。GL 侧 "当前着色器/批次 uniform" 状态被这些不停换血的
		//   实例冲垮后，某些批次会以"上一次的（或全 0 的）uniform"绘制 —— 表现就是
		//   从第 1 轨开始逐轨发黑（箭头与长条一起黑，长条甚至不走调色板着色器）。
		//   修复：轨道预览组只构建一次，切换模式时【原地】重载两排箭头贴图并重新断言
		//   调色板颜色，不新建/销毁任何精灵与着色器。
		applyLaneMode();
		refreshLaneColors();
		refreshDirty();
		syncPanel();
		toast(p ? "已切换到像素箭头模式（arrowRGBPixel 样式组）" : "已切换到常规箭头模式（arrowRGB 样式组）");
	}

	/**
	 * 按当前 onPixel 原地重载左区两排箭头的贴图：
	 * StrumNote.reloadNote() 依据全局 PlayState.isPixelStage（= stageUI）选常规/像素分支，
	 * 所以这里临时把 stageUI 切到目标模式，重载完立刻还原（isPixelStage 是只读派生属性，
	 * 不能直接赋值）。
	 */
	function applyLaneMode()
	{
		var savedStage:String = PlayState.stageUI;
		PlayState.stageUI = onPixel ? "pixel" : "normal";
		var skin:String = laneArrowSkin();
		for (i in 0...laneNoteTop.length)
		{
			// ★ 切贴图后必须重新套用面板自己的尺寸/位置：
			//   StrumNote.reloadNote() 的像素分支会执行
			//   setGraphicSize((width * (pixelScale + 0.3)) * PlayState.daPixelZoom)，
			//   把 buildLaneGroup() 设好的 laneW*0.86 / laneW*0.70 覆盖掉 ——
			//   表现就是"像素模式下 note 明显过大"。
			var lx:Float = laneX + i * laneW;
			var cx:Float = lx + laneW / 2;

			var t:StrumNote = laneNoteTop[i];
			if (t != null)
			{
				t.texture = skin;
				var topSize:Float = laneW * 0.86;
				t.setGraphicSize(topSize);
				t.updateHitbox();
				t.setPosition(cx - topSize / 2, (laneTop + laneH * 0.16) - topSize / 2);
				if (i < lanePal.length && lanePal[i] != null) linkLaneNote(t, lanePal[i]);
			}
			var m:StrumNote = laneNoteMid[i];
			if (m != null)
			{
				m.texture = skin;
				var midSize:Float = laneW * 0.70;
				m.setGraphicSize(midSize);
				m.updateHitbox();
				m.setPosition(cx - midSize / 2, (laneTop + laneH * 0.50) - midSize / 2);
				if (i < lanePalOrig.length && lanePalOrig[i] != null) linkLaneNote(m, lanePalOrig[i]);
			}
		}
		PlayState.stageUI = savedStage;
	}

	/** 与 StrumNote 构造函数同源的箭头贴图路径（含 pixelUI 前缀），供原地换模式使用 */
	function laneArrowSkin():String
	{
		var prefix:String = onPixel ? 'pixelUI/' : '';
		if (Note.loadedNote == null || Note.defaultNoteSkin == null) return prefix + Note.initSkin;
		var d = Note.loadedNote.get(Note.getLoadDataKey(Note.defaultNoteSkin, ''));
		if (d == null || d.skin == null) return prefix + Note.initSkin;
		return prefix + d.skin + (d.skinPostfix != null ? d.skinPostfix : '');
	}
	function resetAttrV3(a:Int, all:Bool)
	{
		var defs = onPixel ? ClientPrefs.defaultData.arrowRGBPixel : ClientPrefs.defaultData.arrowRGB;
		if (defs == null || curSelectedNote >= defs.length) return;
		if (all)
		{
			for (k in 0...3) setColorSlot(curSelectedNote, k, defs[curSelectedNote][k]);
			toast("已整轨重置为默认样式（Shift+R）");
		}
		else
		{
			setColorSlot(curSelectedNote, a, defs[curSelectedNote][a]);
			toast("已重置 " + ATTRS[a] + "（R）");
		}
		curSelectedMode = a;
		refreshDirty(); pushAllGlobal(); refreshLaneColors(); syncPanel();
	}

	// ---------- 左区轨道（10 轨）构建 / 清理 ----------
	function clearBasic<T:flixel.FlxBasic>(arr:Array<T>)
	{
		for (o in arr) { if (o != null) { remove(o); o.destroy(); } }
		arr.splice(0, arr.length);
	}
	function clearLaneGroup()
	{
		clearBasic(laneBGs); clearBasic(laneNos);
		clearBasic(laneNoteTop); clearBasic(laneNoteMid);
		for (row in laneSustains) clearBasic(row);
		laneSustains.splice(0, laneSustains.length);
		// ★ lanePal / lanePalOrig 不在这里清空：调色板（及其 FlxShader）跨切换原地复用，
		//   避免每次切常规/像素都销毁重建 20 个 shader 实例（uniform 状态污染 → 发黑蔓延）。
		clearBasic(laneKeyBG); clearBasic(laneKeyTxt);
		if (judgeLine != null) { remove(judgeLine); judgeLine.destroy(); judgeLine = null; }
	}
	function makeSusBar(x:Float, y:Float, w:Float, h:Float):Array<FlxSprite>
	{
		var outline = new FlxSprite(x, y).makeGraphic(Math.floor(w), Math.floor(h), 0xFFFFFFFF);
		outline.alpha = 0.92; add(outline);
		var border = new FlxSprite(x + 2, y + 2).makeGraphic(Std.int(Math.max(1, Math.floor(w) - 4)), Std.int(Math.max(1, Math.floor(h) - 4)), 0xFFFFFFFF); add(border);
		var inner = new FlxSprite(x + 4, y + 4).makeGraphic(Std.int(Math.max(1, Math.floor(w) - 8)), Std.int(Math.max(1, Math.floor(h) - 8)), 0xFFFFFFFF); add(inner);
		return [outline, border, inner];
	}
	function linkLaneNote(note:StrumNote, pal:RGBPalette)
	{
		note.rgbShader.parent = pal;
		note.shader = pal.shader;
		note.rgbShader.enabled = true;
		note.animation.play('static', true);
		// 强制以左上角为锚点，避免 playAnim 内部 centerOffsets/centerOrigin 改变定位
		note.origin.set(0, 0);
		note.offset.set(0, 0);
		note.scrollFactor.set();
	}
	function buildLaneGroup()
	{
		if (dataArray == null) return;
		var n:Int = dataArray.length;
		// ★ 复用守卫（逐轨变黑修复）：轨道预览组只在首次构建、或轨道数变化时重建。
		//   常规/像素 切换不再 clearLaneGroup()+重建 —— 那会在每次切换时新建 20 个
		//   StrumNote 与 60+ 个 makeGraphic 精灵（每个都带新的 FlxGraphic/着色器实例），
		//   累积的着色器实例会把 GL 的当前着色器/uniform 状态冲垮，导致箭头逐轨发黑。
		if (laneNoteTop.length == n && laneNoteMid.length == n)
		{
			refreshLaneColors();
			syncLanes();
			return;
		}
		clearLaneGroup();
		// 判定线：贯穿全部轨道（受体位置）
		var judgeY:Float = laneTop + laneH * 0.82;
		judgeLine = new FlxSprite(laneX, judgeY).makeGraphic(Math.floor(laneTotalW), 2, 0xFFFFFFFF);
		judgeLine.alpha = 0.16; judgeLine.scrollFactor.set(); add(judgeLine);

		for (i in 0...n)
		{
			var lx:Float = laneX + i * laneW;
			var cx:Float = lx + laneW / 2;

			// 点击命中区（整条轨道）
			var bg = new FlxSprite(lx, laneTop).makeGraphic(Math.floor(laneW), Math.floor(laneH), 0xFF8B9098);
			bg.alpha = 0; bg.scrollFactor.set(); add(bg); laneBGs.push(bg);

			// 轨道编号
			var no = mkTxt(lx, laneTop + 2, laneW, Std.string(i + 1), 11, 0xFF4E5666);
			no.alignment = CENTER; laneNos.push(no);

			// 每轨独立调色板（上排=当前样式；下排=默认样式，对照用）
			// ★ 原地复用：lanePal/lanePalOrig 已有对应槽位（上一次构建留下的）则直接用，
			//   只在扩容/为 null 时新建 —— shader 实例数恒定，切换模式零新建。
			var pal:RGBPalette = (i < lanePal.length && lanePal[i] != null) ? lanePal[i] : new RGBPalette();
			if (i < lanePal.length) lanePal[i] = pal; else lanePal.push(pal);
			var palOrig:RGBPalette = (i < lanePalOrig.length && lanePalOrig[i] != null) ? lanePalOrig[i] : new RGBPalette();
			if (i < lanePalOrig.length) lanePalOrig[i] = palOrig; else lanePalOrig.push(palOrig);

			// 顶部箭头
			var topY:Float = laneTop + laneH * 0.16;
			var topSize:Float = laneW * 0.86;
			var topNote = new StrumNote(0, 0, i, 0, PlayState.SONG.mania);
			topNote.setGraphicSize(topSize); topNote.updateHitbox();
			linkLaneNote(topNote, pal);
			topNote.setPosition(cx - topSize / 2, topY - topSize / 2);
			add(topNote); laneNoteTop.push(topNote);

			// 中部箭头（下排）：绑定默认样式调色板
			var midY:Float = laneTop + laneH * 0.50;
			var midSize:Float = laneW * 0.70;
			var midNote = new StrumNote(0, 0, i, 0, PlayState.SONG.mania);
			midNote.setGraphicSize(midSize); midNote.updateHitbox();
			linkLaneNote(midNote, palOrig);
			midNote.setPosition(cx - midSize / 2, midY - midSize / 2);
			add(midNote); laneNoteMid.push(midNote);

			// 长条（内色填充 + 外轮廓描边 + 内衬描边）
			var barW:Float = laneW * 0.28;
			var barX:Float = lx + (laneW - barW) / 2;
			var topHalf:Float = topSize / 2, midHalf:Float = midSize / 2;
			var bar1Y:Float = topY + topHalf + 6;
			var bar1H:Float = (midY - midHalf) - bar1Y - 6;
			if (bar1H < 6) bar1H = 6;
			laneSustains.push(makeSusBar(barX, bar1Y, barW, bar1H));
			var bar2Y:Float = midY + midHalf + 6;
			var bar2H:Float = (judgeY - 6) - bar2Y - 6;
			if (bar2H < 6) bar2H = 6;
			laneSustains.push(makeSusBar(barX, bar2Y, barW, bar2H));

			// 按键芯片
			var kw:Float = laneW * 0.42, kh:Float = laneW * 0.36;
			var kb = new FlxSprite(lx + (laneW - kw) / 2, laneTop + laneH * 0.90).makeGraphic(Math.floor(kw), Math.floor(kh), 0xFF1A1F2A);
			kb.alpha = 0.6; kb.scrollFactor.set(); add(kb); laneKeyBG.push(kb);
			var kt = mkTxt(kb.x, kb.y, kw, KEY_LABELS[i % KEY_LABELS.length], 13, 0xFFFFFFFF); kt.alignment = CENTER; laneKeyTxt.push(kt);
		}
		refreshLaneColors();
		syncLanes();
	}

	// v3 新交互分发（返回 true 表示已消费本次点击）
	function handleV3Click():Bool
	{
		if (exitModalOpen || saveModalOpen) { handleModalInput(); return true; }
		for (i in 0...laneBGs.length)
			if (pointerOverlaps(laneBGs[i])) { selectLane(i); return true; }
		if (overBox(applyBox)) { toggleApply(); return true; }
		if (overBox(exitBox)) { askExit(); return true; }
		if (overBox(modeSegBox[0])) { setPixelMode(false); return true; }
		if (overBox(modeSegBox[1])) { setPixelMode(true); return true; }
		for (a in 0...tileResetBox.length)
			if (overBox(tileResetBox[a])) { resetAttrV3(a, false); return true; }
		for (a in 0...tileBox.length)
			if (overBox(tileBox[a])) { selectAttrTile(a); return true; }
		return false;
	}

	/**
	 * 取 ClientPrefs.defaultData 里 (note, type) 的默认色，全链路越界兜底。
	 * 当前模组缺像素配色 / 老存档 / 下标越界时一律返回白，绝不 NPE。
	 */
	function defaultColorAt(note:Int, type:Int):FlxColor
	{
		var src:Array<Array<FlxColor>> = !onPixel ? ClientPrefs.defaultData.arrowRGB : ClientPrefs.defaultData.arrowRGBPixel;
		if (src == null) src = ClientPrefs.defaultData.arrowRGB;
		if (src == null || note < 0 || note >= src.length) return 0xFFFFFFFF;
		var slot:Array<FlxColor> = src[note];
		if (slot == null || type < 0 || type >= slot.length) return 0xFFFFFFFF;
		return slot[type];
	}

	/** 写 dataArray 的 (note, type) 槽位，越界静默忽略 */
	function setColorSlot(note:Int, type:Int, value:FlxColor)
	{
		if (dataArray == null || note < 0 || note >= dataArray.length) return;
		var slot:Array<FlxColor> = dataArray[note];
		if (slot == null || type < 0 || type >= slot.length) return;
		slot[type] = value;
	}

	function pointerOverlaps(obj:Dynamic)
	{
		if (!controls.controllerMode)
			return FlxG.mouse.overlaps(obj);
		return FlxG.overlap(controllerPointer, obj);
	}

	function pointerX():Float
	{
		if (!controls.controllerMode)
			return FlxG.mouse.x;
		return controllerPointer.x;
	}

	function pointerY():Float
	{
		if (!controls.controllerMode)
			return FlxG.mouse.y;
		return controllerPointer.y;
	}

	function pointerFlxPoint():FlxPoint
	{
		if (!controls.controllerMode)
			return FlxG.mouse.getScreenPosition();
		return controllerPointer.getScreenPosition();
	}

	function changeSelectionMode(change:Int = 0)
	{
		curSelectedMode += change;
		if (curSelectedMode < 0)
			curSelectedMode = 2;
		if (curSelectedMode >= 3)
			curSelectedMode = 0;

		modeBG.visible = true;
		notesBG.visible = false;
		updateNotes();
		FlxG.sound.play(Paths.sound('scrollMenu'));
	}

	function changeSelectionNote(change:Int = 0)
	{
		curSelectedNote += change;
		if (curSelectedNote < 0)
			curSelectedNote = dataArray.length - 1;
		if (curSelectedNote >= dataArray.length)
			curSelectedNote = 0;

		modeBG.visible = false;
		notesBG.visible = true;
		// ★ 防御：Note.globalRgbShaders[curSelectedNote] 可能为 null（旧版 initializeGlobalRGBShader
		//   不 grow 数组 + globalRgbShaders = [] 重置组合下，所有 curSelectedNote>=1 都会命中 null），
		//   取 .shader 直接 NPE。这里初始化该槽位再赋值。
		var sh = Note.initializeGlobalRGBShader(curSelectedNote);
		if (sh != null) bigNote.rgbShader.parent = sh;
		if (sh != null) bigNote.shader = sh.shader;
		updateNotes();
		FlxG.sound.play(Paths.sound('scrollMenu'));
	}

	// alphabets
	function makeColorAlphabet(x:Float = 0, y:Float = 0):Alphabet
	{
		var text:Alphabet = new Alphabet(x, y, '', true);
		text.alignment = CENTERED;
		text.setScale(0.34);
		add(text);
		return text;
	}

	// notes sprites functions
	var skinNote:FlxSprite;
	var modeNotes:FlxTypedGroup<FlxSprite>;
	var myNotes:FlxTypedGroup<StrumNote>;
	var bigNote:Note;

	public function spawnNotes()
	{
		// ★ 使用会话内副本（不直接引用 ClientPrefs，编辑只落副本、保存才写回）
		dataArray = !onPixel ? workNormal : workPixel;
		// ★ 防御：目标配色表为 null/空（当前模组缺像素配色、老存档、arrowRGBPixel.json 缺失）
		//   → 依次回退到另一套；两者都拿不到时用空表，避免 dataArray[x][y] 直接 NPE。
		if (dataArray == null || dataArray.length < 1)
			dataArray = workNormal;
		if (dataArray == null || dataArray.length < 1)
			dataArray = workPixel;
		if (dataArray == null)
			dataArray = [];
		// ★ 选中下标 clamp：配色表变短（切换像素/普通、缺配置）后旧下标会越界
		if (curSelectedNote >= dataArray.length) curSelectedNote = 0;
		if (curSelectedNote < 0) curSelectedNote = 0;
		if (curSelectedMode > 2 || curSelectedMode < 0) curSelectedMode = 0;
		// ★ 构建期间把全局舞台模式钉到当前预览模式（贴图分支/取色都按它走）；
		//   函数末尾恢复进入面板时的原值。旧代码无论进入时是什么模式都硬写 "normal"，
		//   会把「从像素关卡进入面板」的全局状态改坏并泄漏到之后的渲染。
		var savedStageUI:String = PlayState.stageUI;
		PlayState.stageUI = onPixel ? "pixel" : "normal";

		// clear groups
		modeNotes.forEachAlive(function(note:FlxSprite)
		{
			note.kill();
			note.destroy();
		});
		myNotes.forEachAlive(function(note:StrumNote)
		{
			note.kill();
			note.destroy();
		});
		modeNotes.clear();
		myNotes.clear();

		if (skinNote != null)
		{
			remove(skinNote);
			skinNote.destroy();
		}
		if (bigNote != null)
		{
			remove(bigNote);
			bigNote.destroy();
		}

		// respawn stuff
		var res:Int = onPixel ? 160 : 17;
		skinNote = new FlxSprite(48, 24).loadGraphic(Paths.image('noteColorMenu/' + (onPixel ? 'note' : 'notePixel')), true, res, res);
		skinNote.antialiasing = ClientPrefs.data.antialiasing;
		skinNote.setGraphicSize(68);
		skinNote.updateHitbox();
		skinNote.animation.add('anim', [0], 24, true);
		skinNote.animation.play('anim', true);
		if (!onPixel)
			skinNote.antialiasing = false;
		add(skinNote);

		res = !onPixel ? 160 : 17;
		for (i in 0...3)
		{
			var newNote:FlxSprite = new FlxSprite(230 + (100 * i),
				100).loadGraphic(Paths.image('noteColorMenu/' + (!onPixel ? 'note' : 'notePixel')), true, res, res);
			newNote.antialiasing = ClientPrefs.data.antialiasing;
			newNote.setGraphicSize(85);
			newNote.updateHitbox();
			newNote.animation.add('anim', [i], 24, true);
			newNote.animation.play('anim', true);
			newNote.ID = i;
			if (onPixel)
				newNote.antialiasing = false;
			modeNotes.add(newNote);
		}

		// ★ 手动为每条 lane 预分配「已按 dataArray 取好色」的全局 palette。
		//   不能只靠 Note.initializeGlobalRGBShader(i)：该函数保持原始语义
		//   （越界返回共享 globalRgbShaders[0] 且**不 grow 数组**），在 `= []` 之后
		//   循环调用只会填出 [0]，[1..N] 仍是 null → 后续 changeSelectionNote /
		//   点击 myNotes 访问 globalRgbShaders[idx].shader 直接 NPE。
		//   预先 push 满后，下面 StrumNote 构造里的 initializeGlobalRGBShader(i)
		//   会直接命中已存在的槽位（i < length 分支），行为不变且安全。
		// ★★ 原地复用调色板：不再 `globalRgbShaders = []` 重建。每次切换模式若整体销毁
		//   重建 40+ 个 FlxShader 实例（global + lanePal + lanePalOrig），它们在 OpenFL
		//   共享同一份按源码缓存的 GLProgram，疯狂切换会污染 uniform 状态 → 箭头“伽马
		//   值减少”式发黑且随切换蔓延。只更新 r/g/b，shader 实例数恒定。
		while (Note.globalRgbShaders != null && Note.globalRgbShaders.length > dataArray.length)
			Note.globalRgbShaders.pop();
		applyWorkToGlobal();
		if (Note.globalRgbShaders == null)
			Note.globalRgbShaders = [];
		if (Note.globalRgbShaders.length < 1)
			Note.globalRgbShaders.push(new RGBPalette());

		for (i in 0...dataArray.length)
		{
			Note.initializeGlobalRGBShader(i);
			var newNote:StrumNote = new StrumNote(150 + (480 / dataArray.length * i), 200, i, 0);
			newNote.setGraphicSize(102);
			newNote.useRGBShader = true;
			newNote.updateHitbox();
			newNote.ID = i;
			myNotes.add(newNote);
		}

		bigNote = new Note(0, 0, null, true);
		bigNote.setPosition(250, 325);
		bigNote.setGraphicSize(250);
		bigNote.updateHitbox();
		// ★ 防御：槽位可能仍为 null（dataArray 异常时）→ 走 initializeGlobalRGBShader 兜底
		var sh0:RGBPalette = Note.initializeGlobalRGBShader(curSelectedNote);
		if (sh0 != null) bigNote.rgbShader.parent = sh0;
		if (sh0 != null) bigNote.shader = sh0.shader;
		// ★ 越界安全：animations / keys[mania].notes 越界或 EKAnimation 为 null 时跳过，绝不 NPE
		if (ExtraKeysHandler.instance != null && ExtraKeysHandler.instance.data != null
			&& PlayState.SONG != null)
		{
			var ek = ExtraKeysHandler.instance.data;
			var m:Int = PlayState.SONG.mania;
			if (ek.keys != null && ek.animations != null && m >= 0 && m < ek.keys.length)
			{
				var notesArr:Array<Int> = ek.keys[m].notes;
				if (notesArr != null)
				{
					for (i in 0...notesArr.length)
					{
						var visIdx:Int = notesArr[i];
						if (visIdx < 0 || visIdx >= ek.animations.length) continue;
						var anim = ek.animations[visIdx];
						if (anim == null) continue;
						if (!onPixel)
						{
							if (anim.note != null)
								bigNote.animation.addByPrefix('note$i', anim.note + '0', 24, true);
						}
						else
						{
							bigNote.animation.add('note$i', [anim.pixel + 6], 24, true);
						}
					}
				}
			}
		}
		insert(members.indexOf(myNotes) + 1, bigNote);
		// ★ 防御：StrumNote 构造里的 rgbShader.r/g/b 赋值可能经 RGBShaderReference 写回
		//   共享槽（值相等时无感，值不等时克隆私有 palette）。这里再整体刷一遍工作副本，
		//   保证 globalRgbShaders 与 dataArray 严格一致（长条/箭头着色的最终依据）。
		applyWorkToGlobal();
		_storedColor = getShaderColor();

		// —— v3：构建左区 10 轨预览。旧 myNotes / modeNotes / skinNote / bigNote 仅作着色器持有者保留，隐藏不删 ——
		myNotes.visible = false;
		modeNotes.visible = false;
		if (skinNote != null) skinNote.visible = false;
		if (bigNote != null) bigNote.visible = false;
		buildLaneGroup();

		// ★ 恢复进入面板前的全局舞台模式（不再无条件写 "normal"，避免污染全局渲染状态）
		PlayState.stageUI = savedStageUI;
	}

	function updateNotes(?instant:Bool = false)
	{
		// ★ 崩溃防御：doQuit → switchState 过渡期间本面板可能已进入销毁流程，
		//   bigNote/成员被 destroy 后 animation 为 null → 虚调用读 null（EXCEPTION_ACCESS_VIOLATION）。
		//   符号化定位：崩溃点在 updateNotes 内（RVA 0x1f83369，rcx=0）。
		if (bigNote == null || bigNote.animation == null) return;
		for (note in modeNotes)
		{
			if (note == null) continue;
			note.alpha = (curSelectedMode == note.ID) ? 1 : 0.6;
		}

		for (note in myNotes)
		{
			if (note == null || note.animation == null) continue;
			var newAnim:String = curSelectedNote == note.ID ? 'confirm' : 'pressed';
			note.alpha = (curSelectedNote == note.ID) ? 1 : 0.6;
			if (note.animation.curAnim == null || note.animation.curAnim.name != newAnim)
				note.playAnim(newAnim, true);
			if (instant && note.animation.curAnim != null)
				note.animation.curAnim.finish();
		}
		bigNote.animation.play('note$curSelectedNote', true);
		updateColors();
	}

	function updateColors(specific:Null<FlxColor> = null)
	{
		var color:FlxColor = getShaderColor();
		var wheelColor:FlxColor = specific == null ? getShaderColor() : specific;
		alphabetR.text = Std.string(color.red);
		alphabetG.text = Std.string(color.green);
		alphabetB.text = Std.string(color.blue);

		colorWheel.color = FlxColor.fromHSB(0, 0, color.brightness);
		colorWheelSelector.setPosition(colorWheel.x + colorWheel.width / 2, colorWheel.y + colorWheel.height / 2);
		if (wheelColor.brightness != 0)
		{
			var hueWrap:Float = wheelColor.hue * Math.PI / 180;
			colorWheelSelector.x += Math.sin(hueWrap) * colorWheel.width / 2 * wheelColor.saturation;
			colorWheelSelector.y -= Math.cos(hueWrap) * colorWheel.height / 2 * wheelColor.saturation;
		}
		colorGradientSelector.y = colorGradient.y + colorGradient.height * (1 - color.brightness);

		// ★ 防御：myNotes 数量少于 curSelectedNote+1（配色表变短/切换像素模式瞬间）时
		//   members[curSelectedNote] 为 null → .rgbShader NPE
		if (curSelectedNote < 0 || curSelectedNote >= myNotes.members.length)
			return;
		var curStrum:StrumNote = myNotes.members[curSelectedNote];
		if (curStrum == null || curStrum.rgbShader == null)
			return;
		var strumRGB:RGBShaderReference = curStrum.rgbShader;
		switch (curSelectedMode)
		{
			case 0:
				getShader().r = strumRGB.r = color;
			case 1:
				getShader().g = strumRGB.g = color;
			case 2:
				getShader().b = strumRGB.b = color;
		}
	}

	/** 取当前（note, mode）槽位的颜色；dataArray 异常时返回白，绝不 NPE */
	function getShaderColor():FlxColor
	{
		if (dataArray == null) return 0xFFFFFFFF;
		if (curSelectedNote < 0 || curSelectedNote >= dataArray.length) return 0xFFFFFFFF;
		var slot:Array<FlxColor> = dataArray[curSelectedNote];
		if (slot == null) return 0xFFFFFFFF;
		if (curSelectedMode < 0 || curSelectedMode >= slot.length) return 0xFFFFFFFF;
		return slot[curSelectedMode];
	}

	function setShaderColor(value:FlxColor)
	{
		if (dataArray == null) return;
		if (curSelectedNote < 0 || curSelectedNote >= dataArray.length) return;
		var slot:Array<FlxColor> = dataArray[curSelectedNote];
		if (slot == null) return;
		if (curSelectedMode < 0 || curSelectedMode >= slot.length) return;
		slot[curSelectedMode] = value;
	}

	/** 取当前 note 对应的全局 palette；越界时兜底到槽 0，绝不返回 null */
	function getShader():RGBPalette
	{
		var idx:Int = curSelectedNote;
		if (idx < 0 || idx >= Note.globalRgbShaders.length) idx = 0;
		if (idx >= Note.globalRgbShaders.length) return new RGBPalette();
		var p:RGBPalette = Note.globalRgbShaders[idx];
		return (p != null) ? p : new RGBPalette();
	}

	#if sys
	/** 进入时检测当前 mod 是否缺像素箭头资源（图片 + 配色数据），缺失则弹确认框询问是否复制 */
	function checkAndPromptPixelArrowAssets()
	{
		var modDir:String = Mods.currentModDirectory;
		if (modDir == null || modDir.length == 0) return;

		// 1) 图片资源：noteColorMenu 这套 UI 资源（“像素箭头”本体 notePixel + 配套图）
		var names:Array<String> = ['note', 'notePixel', 'copy', 'paste', 'palette', 'colorWheel'];
		_missingImages = [];
		for (name in names)
		{
			var modFile:String = Paths.mods(modDir + '/images/noteColorMenu/' + name + '.png');
			if (!FileSystem.exists(modFile))
				_missingImages.push(name);
		}

		// 2) 配色数据：mod 自带 extrakeys.json 但缺 pixelNoteColors
		_missingData = false;
		var modExtra:String = Paths.mods(modDir + '/data/extrakeys.json');
		if (FileSystem.exists(modExtra))
		{
			try
			{
				var obj:Dynamic = haxe.Json.parse(File.getContent(modExtra));
				var pc:Dynamic = (obj != null) ? obj.pixelNoteColors : null;
				if (pc == null || (cast pc).length == 0)
					_missingData = true;
			}
			catch (e:Dynamic) { _missingData = true; }
		}

		if (_missingImages.length > 0 || _missingData)
		{
			// ★ 不再弹全屏黑色确认框（用户反馈很反感）：检测到缺资源就直接静默复制，
			//   并在左上角给一条淡出的轻提示。每次会话只做一次。
			if (_pixelCopyPromptShown) return;
			_pixelCopyPromptShown = true;
			_missingModDir = modDir;
			doCopyPixelArrowAssets();
			showCopyToast();
		}
	}

	/** 静默复制完成后的轻提示（数秒淡出） */
	function showCopyToast()
	{
		if (copyToast == null)
		{
			copyToast = mkTxt(16, 50, uiRightX - 32, "", 12, 0xFF8FD8A0);
			copyToast.scrollFactor.set();
		}
		copyToast.text = "检测到当前 mod 缺少像素箭头资源，已自动从引擎复制默认资源";
		copyToast.alpha = 1;
		copyToastTimer = 4;
	}

	/** 弹出本地化确认框，询问是否把默认像素箭头资源复制到当前 mod */
	function showCopyPrompt()
	{
		copyPromptMembers = [];
		var cx:Float = FlxG.width / 2;
		var cy:Float = FlxG.height / 2;
		var bw:Int = 460;
		var bh:Int = 200;

		var dim:FlxSprite = new FlxSprite(0, 0).makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		dim.alpha = 0.55; dim.scrollFactor.set();
		add(dim); copyPromptMembers.push(dim);

		var box:FlxSprite = new FlxSprite(cx - bw / 2, cy - bh / 2).makeGraphic(bw, bh, FlxColor.fromRGB(20, 20, 30));
		box.alpha = 0.96; box.scrollFactor.set();
		add(box); copyPromptMembers.push(box);

		var title:FlxText = new FlxText(box.x + 16, box.y + 14, bw - 32, Language.get('pixelArrowMissingTitle', 'options'), 18);
		title.scrollFactor.set(); add(title); copyPromptMembers.push(title);

		var msg:FlxText = new FlxText(box.x + 16, box.y + 52, bw - 32, Language.get('pixelArrowMissingMsg', 'options'), 14);
		msg.scrollFactor.set(); add(msg); copyPromptMembers.push(msg);

		var yes:FlxText = new FlxText(box.x + bw - 150, box.y + bh - 44, 130, Language.get('pixelArrowCopy', 'options'), 18);
		yes.alignment = CENTER; yes.scrollFactor.set(); yes.setFormat(null, 18, FlxColor.YELLOW);
		add(yes); copyPromptMembers.push(yes);

		var no:FlxText = new FlxText(box.x + 20, box.y + bh - 44, 130, Language.get('pixelArrowCancel', 'options'), 18);
		no.alignment = CENTER; no.scrollFactor.set(); no.setFormat(null, 18, FlxColor.WHITE);
		add(no); copyPromptMembers.push(no);

		copyPromptYes = yes;
		copyPromptNo = no;
		copyPromptOpen = true;
	}

	function closeCopyPrompt()
	{
		for (m in copyPromptMembers) remove(m);
		copyPromptMembers = [];
		copyPromptOpen = false;
	}

	function handleCopyPromptInput()
	{
		if (FlxG.keys.justPressed.ESCAPE) { closeCopyPrompt(); return; }
		if (FlxG.keys.justPressed.ENTER) { doCopyPixelArrowAssets(); closeCopyPrompt(); return; }
		if (FlxG.mouse.justPressed)
		{
			if (pointerOverlaps(copyPromptYes)) { doCopyPixelArrowAssets(); closeCopyPrompt(); }
			else if (pointerOverlaps(copyPromptNo)) { closeCopyPrompt(); }
		}
	}

	/** 用户确认后：把默认像素箭头资源复制到当前 mod 目录（图片 + 配色数据） */
	function doCopyPixelArrowAssets()
	{
		var modDir:String = _missingModDir;
		if (modDir == null || modDir.length == 0) return;

		// 1) 图片：从引擎自带共享资源复制到 mod 的 images/noteColorMenu/
		for (name in _missingImages)
		{
			var modFile:String = Paths.mods(modDir + '/images/noteColorMenu/' + name + '.png');
			var src:String = Paths.getPath('images/noteColorMenu/' + name + '.png', AssetType.IMAGE, null, false); // 取共享（非 mod）路径
			if (!FileSystem.exists(modFile) && FileSystem.exists(src))
			{
				try
				{
					ensureDir(Path.directory(modFile));
					File.copy(src, modFile);
				}
				catch (e:Dynamic) { trace('[NotesSubState] copy pixel-arrow image failed: ' + name + ' -> ' + e); }
			}
		}

		// 2) 配色数据：把共享 extrakeys.json 的 pixelNoteColors 合并进 mod 的 extrakeys.json
		if (_missingData)
		{
			var modExtra:String = Paths.mods(modDir + '/data/extrakeys.json');
			var sharedPC:Dynamic = readSharedPixelNoteColors();
			if (sharedPC != null)
			{
				var obj:Dynamic = null;
				if (FileSystem.exists(modExtra))
				{
					try { obj = haxe.Json.parse(File.getContent(modExtra)); }
					catch (e:Dynamic) { obj = null; trace('[NotesSubState] extrakeys.json parse failed, data copy skipped to avoid corruption'); }
				}
				if (obj != null)
				{
					obj.pixelNoteColors = sharedPC;
					try
					{
						ensureDir(Path.directory(modExtra));
						File.saveContent(modExtra, haxe.Json.stringify(obj, null, '\t'));
					}
					catch (e:Dynamic) { trace('[NotesSubState] extrakeys.json write failed: ' + e); }
				}
			}
		}

		if (tipTxt != null)
		{
			tipTxt.text = Language.get('pixelArrowDone', 'options');
			tipTxt.visible = true;
		}
	}

	/** 读取引擎共享 extrakeys.json 中的 pixelNoteColors（绕过 mod 覆盖） */
	function readSharedPixelNoteColors():Dynamic
	{
		var sharedPath:String = Paths.getPath('data/extrakeys.json', AssetType.TEXT, null, false);
		if (!FileSystem.exists(sharedPath)) return null;
		try
		{
			var obj:Dynamic = haxe.Json.parse(File.getContent(sharedPath));
			return (obj != null) ? obj.pixelNoteColors : null;
		}
		catch (e:Dynamic) { return null; }
	}

	/** 递归创建目录（Windows '/' 与 '\' 均可） */
	static function ensureDir(dir:String)
	{
		if (dir == null || dir.length == 0 || dir == '.' || FileSystem.exists(dir)) return;
		ensureDir(Path.directory(dir));
		try { FileSystem.createDirectory(dir); } catch (e:Dynamic) {}
	}
	#end

	override function destroy()
	{
		// ★ 恢复面板内禁用的音量热键（数字 0 = 静音等）
		ClientPrefs.reloadVolumeKeys();
		super.destroy();
	}
}

/**
 * v3 自绘 UI 的「盒子」抽象：border（描边）+ fill（填充）两个 FlxSprite 组合，
 * 用来在 Flixel 里模拟 HTML 的 div / button。由 makeBox / boxPos / boxColors / overBox 操作。
 */
class UIBox
{
	public var border:FlxSprite;
	public var fill:FlxSprite;
	public function new() {}
}

