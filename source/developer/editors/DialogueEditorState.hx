package developer.editors;

import openfl.net.FileReference;
import openfl.events.Event;
import openfl.events.IOErrorEvent;
import openfl.net.FileFilter;
import haxe.Json;

import flixel.addons.ui.FlxUIInputText;
import flixel.addons.ui.FlxUINumericStepper;
import flixel.addons.ui.FlxUICheckBox;
import flixel.addons.ui.FlxUI;
import flixel.group.FlxSpriteGroup;
import flixel.text.FlxText;

import general.objects.TypedAlphabet;

import games.cutscenes.DialogueBoxPsych;
import games.cutscenes.DialogueCharacter;

/**
 * 对话编辑器（NovaFlare 新版 UI）：
 *  - Adobe 风格顶栏菜单（DialogueEditorMenuBar）+ 底部状态栏 + EditorChromeUI 窗口栏
 *  - 对白预览区保留在主相机（角色/气泡/打字文字），可 A/D/W/S 切换行/表情
 *  - 所有字段编辑收进顶栏菜单；原生 FlxUI 控件只作数据源（隐藏），由菜单自绘接管
 */
class DialogueEditorState extends MusicBeatState
{
	var character:DialogueCharacter;
	var box:FlxSprite;
	var daText:TypedAlphabet;

	var defaultLine:DialogueLine;
	var dialogueFile:DialogueFile = null;
	var unsavedProgress:Bool = false;

	var camGame:FlxCamera;
	var camHUD:FlxCamera;

	// ===== 顶栏菜单（Adobe 风格）=====
	var menuBar:DialogueEditorMenuBar;
	#if (cpp && windows)
	var windowChrome:EditorChromeUI;
	var modInfoPopup:general.objects.ModInfoPopup;
	#end

	// ★ 双层方案（同一 camHUD）：uiLayer 底层（菜单等 UI），overlayLayer 顶层（widget / 输入覆盖层）
	var uiLayer:FlxSpriteGroup;
	var overlayLayer:FlxSpriteGroup;

	// ===== 原生控件（只作数据源，不渲染；由 menuBar 自绘接管显示）=====
	var w_char:FlxUIInputText;   // 角色文件
	var w_text:FlxUIInputText;   // 对白文本
	var w_sound:FlxUIInputText;  // 打字音效
	var w_speed:FlxUINumericStepper; // 打字速度
	var w_angry:FlxUICheckBox;   // 生气气泡

	// 程序化同步控件值时置 true，避免误触发 unsavedProgress
	var syncingWidgets:Bool = false;

	// 诊断标记：曾在每次调用（含 update() 每帧一次）时同步 append 'ui_mark.log'。
	// 该写盘已移除；函数保留为空 inline，使全部调用点在编译期消失，
	// 调用点仍用于标注 create() 的装配顺序，便于后续排查。
	static inline function mark(s:String):Void {}
	var curSelected:Int = 0;
	var curAnim:Int = 0;
	var transitioning:Bool = false;

	override function create()
	{
		persistentUpdate = persistentDraw = true;
		mark('DE.create:persist');

		camGame = initPsychCamera();
		mark('DE.create:initPsychCamera');
		camGame.bgColor = FlxColor.fromHSL(0, 0, 0.5);
		camHUD = new FlxCamera();
		camHUD.bgColor.alpha = 0;
		FlxG.cameras.add(camHUD, false);
		mark('DE:camHUD_added');

		defaultLine = {
			portrait: DialogueCharacter.DEFAULT_CHARACTER,
			expression: 'talk',
			text: DEFAULT_TEXT,
			boxState: DEFAULT_BUBBLETYPE,
			speed: 0.05,
			sound: ''
		};

		dialogueFile = {
			dialogue: [
				copyDefaultLine()
			]
		};

		// ===== 预览区（主相机）=====
		character = new DialogueCharacter();
		mark('DE:pre_char');
		character.scrollFactor.set();
		character.cameras = [camGame];
		add(character);

		box = new FlxSprite(70, 370);
		mark('DE:pre_box');
		box.antialiasing = ClientPrefs.data.antialiasing;
		box.frames = Paths.getSparrowAtlas('speech_bubble');
		box.scrollFactor.set();
		box.animation.addByPrefix('normal', 'speech bubble normal', 24);
		box.animation.addByPrefix('angry', 'AHH speech bubble', 24);
		box.animation.addByPrefix('center', 'speech bubble middle', 24);
		box.animation.addByPrefix('center-angry', 'AHH Speech Bubble middle', 24);
		box.animation.play('normal', true);
		box.setGraphicSize(Std.int(box.width * 0.9));
		box.updateHitbox();
		box.cameras = [camGame];
		add(box);

		daText = new TypedAlphabet(DialogueBoxPsych.DEFAULT_TEXT_X, DialogueBoxPsych.DEFAULT_TEXT_Y, DEFAULT_TEXT);
		mark('DE:pre_daText');
		daText.setScale(0.7);
		daText.cameras = [camGame];
		add(daText);

		// ===== UI 层（camHUD）=====
		uiLayer = new FlxSpriteGroup();
		mark('DE:uiLayer');
		uiLayer.cameras = [camHUD];
		uiLayer.scrollFactor.set();
		add(uiLayer);

		createLegacyWidgets();
		mark('DE.create:widgetsCreated');
		setupMenuBar();
		mark('DE.create:menuBarSetup');
		setupOverlayLayer();
		addLegacyWidgetsToScene();
		hideAllLegacyWidgets();

		#if (cpp && windows)
		// 引擎自绘窗口控制组（右上角：图标+标题 / - □ ×，可拖动窗口）
		windowChrome = new EditorChromeUI();
		windowChrome.scrollFactor.set();
		windowChrome.cameras = [camHUD];
		add(windowChrome);
		// 点击标题 → Mod 信息弹窗
		modInfoPopup = new general.objects.ModInfoPopup();
		modInfoPopup.scrollFactor.set();
		modInfoPopup.cameras = [camHUD];
		add(modInfoPopup);
		windowChrome.onTitleClick = () -> modInfoPopup.openUnder(windowChrome);
		// 顶栏左侧「退出 对话编辑器」按钮
		windowChrome.setupExitButton('dialogueEditor', doExit);
		#end

		FlxG.mouse.visible = true;
		mark('DE.create:mouseVisible');
		changeText();
		mark('DE.create:changeText');
		super.create();
		mark('DE.create:superCreate');
	}

	// ============ 顶栏菜单（Adobe 风格，与 CharacterEditorMenuBar 同架构）============
	function setupMenuBar():Void
	{
		menuBar = new DialogueEditorMenuBar();
		menuBar.scrollFactor.set();
		menuBar.uiCamera = camHUD;
		menuBar.cameras = [camHUD];
		menuBar.onAction = function(actionKey:String) {
			handleMenuAction(actionKey);
		};
		menuBar.onMenuOpened = function(menuKey:String) {
			refreshMenuWidgets(menuKey);
		};

		// 注册 widget 引用（仅用于下拉菜单显示状态文本）
		menuBar.registerWidget('w_char', w_char);
		menuBar.registerWidget('w_angry', w_angry);
		menuBar.registerWidget('w_speed', w_speed);
		menuBar.registerWidget('w_sound', w_sound);
		menuBar.registerWidget('w_text', w_text);

		uiLayer.add(menuBar);
	}

	/** 创建顶层覆盖层容器（输入覆盖层挂这里，渲染在所有 UI 之上） */
	function setupOverlayLayer():Void
	{
		overlayLayer = new FlxSpriteGroup();
		overlayLayer.cameras = [camHUD];
		overlayLayer.scrollFactor.set();
		add(overlayLayer);
		menuBar.overlayLayer = overlayLayer;
	}

	// ============ 隐藏的原生控件（只作数据源）============
	function createLegacyWidgets():Void
	{
		w_char = new FlxUIInputText(0, 0, 100, DialogueCharacter.DEFAULT_CHARACTER, 8);
		mark('DE:w_char');
		w_text = new FlxUIInputText(0, 0, 300, DEFAULT_TEXT, 8);
		w_sound = new FlxUIInputText(0, 0, 120, '', 8);
		w_speed = new FlxUINumericStepper(0, 0, 0.005, 0.05, 0, 0.5, 3);
		mark('DE:w_speed');
		w_angry = new FlxUICheckBox(0, 0, null, null, "Angry Bubble", 100);
		mark('DE:w_angry');

		// 生气气泡切换
		w_angry.callback = function()
		{
			if (syncingWidgets) return;
			var wantAngry:Bool = (dialogueFile.dialogue[curSelected].boxState == 'angry');
			if (w_angry.checked != wantAngry)
			{
				dialogueFile.dialogue[curSelected].boxState = (w_angry.checked ? 'angry' : 'normal');
				updateTextBox();
				unsavedProgress = true;
			}
		};
	}

	function addLegacyWidgetsToScene():Void
	{
		function addOne(w:Dynamic):Void {
			if (w == null) return;
			try { overlayLayer.add(w); } catch (e:Dynamic) {}
			try { w.scrollFactor.set(0, 0); } catch (e:Dynamic) {}
			try { w.setScrollFactor(0, 0); } catch (e:Dynamic) {}
			try { w.cameras = [camHUD]; } catch (e:Dynamic) {}
			try { w.visible = false; } catch (e:Dynamic) {}
			try { w.active = true; } catch (e:Dynamic) {}
		}
		addOne(w_char);
		addOne(w_text);
		addOne(w_sound);
		addOne(w_speed);
		addOne(w_angry);
	}

	function hideAllLegacyWidgets():Void
	{
		var all:Array<Dynamic> = [w_char, w_text, w_sound, w_speed, w_angry];
		for (w in all)
			EditorInputStyle.deepHide(w);
	}

	// ============ 菜单动作分发 ============
	function handleMenuAction(actionKey:String):Void
	{
		switch (actionKey)
		{
			case 'prev_line':
				changeText(-1);
			case 'next_line':
				changeText(1);
			case 'add_line':
				dialogueFile.dialogue.insert(curSelected + 1, copyDefaultLine());
				changeText(1);
				unsavedProgress = true;
			case 'remove_line':
				dialogueFile.dialogue.remove(dialogueFile.dialogue[curSelected]);
				if (dialogueFile.dialogue.length < 1)
				{
					dialogueFile.dialogue = [copyDefaultLine()];
				}
				changeText();
		mark('DE.create:changeText');
				unsavedProgress = true;
			case 'replay_text':
				reloadText(false);
			case 'prev_anim':
				scrollAnim(-1);
			case 'next_anim':
				scrollAnim(1);
			case 'load':
				loadDialogue();
			case 'save':
				saveDialogue();
			case 'exit':
				doExit();
		}
	}

	/** 菜单打开后刷新 widget 显示值（从当前对白行数据同步） */
	function refreshMenuWidgets(menuKey:String):Void
	{
		syncWidgetsFromLine();
	}

	function syncWidgetsFromLine():Void
	{
		if (dialogueFile == null || dialogueFile.dialogue.length < 1) return;
		var line:DialogueLine = dialogueFile.dialogue[curSelected];
		syncingWidgets = true;
		w_char.text = line.portrait;
		w_text.text = line.text;
		w_sound.text = line.sound;
		w_speed.value = line.speed;
		w_angry.checked = (line.boxState == 'angry');
		syncingWidgets = false;
	}

	// ============ 对白行工具 ============
	function copyDefaultLine():DialogueLine {
		var copyLine:DialogueLine = {
			portrait: defaultLine.portrait,
			expression: defaultLine.expression,
			text: defaultLine.text,
			boxState: defaultLine.boxState,
			speed: defaultLine.speed,
			sound: ''
		};
		return copyLine;
	}

	function updateTextBox() {
		box.flipX = false;
		var isAngry:Bool = (dialogueFile.dialogue[curSelected].boxState == 'angry');
		var anim:String = isAngry ? 'angry' : 'normal';

		switch(character.jsonFile.dialogue_pos) {
			case 'left':
				box.flipX = true;
			case 'center':
				if(isAngry) {
					anim = 'center-angry';
				} else {
					anim = 'center';
				}
		}
		box.animation.play(anim, true);
		DialogueBoxPsych.updateBoxOffsets(box);
	}

	function reloadCharacter() {
		character.frames = Paths.getSparrowAtlas('dialogue/' + character.jsonFile.image);
		character.jsonFile = character.jsonFile;
		character.reloadAnimations();
		character.setGraphicSize(Std.int(character.width * DialogueCharacter.DEFAULT_SCALE * character.jsonFile.scale));
		character.updateHitbox();
		character.x = DialogueBoxPsych.LEFT_CHAR_X;
		character.y = DialogueBoxPsych.DEFAULT_CHAR_Y;

		switch(character.jsonFile.dialogue_pos) {
			case 'right':
				character.x = FlxG.width - character.width + DialogueBoxPsych.RIGHT_CHAR_X;
			
			case 'center':
				character.x = FlxG.width / 2;
				character.x -= character.width / 2;
		}
		character.x += character.jsonFile.position[0];
		character.y += character.jsonFile.position[1];
		character.playAnim();
		characterAnimSpeed();
	}

	private static var DEFAULT_TEXT:String = "coolswag";
	private static var DEFAULT_SPEED:Float = 0.05;
	private static var DEFAULT_BUBBLETYPE:String = "normal";

	function reloadText(skipDialogue:Bool) {
		var textToType:String = w_text.text;
		if(textToType == null || textToType.length < 1) textToType = ' ';

		daText.text = textToType;

		if(skipDialogue) 
			daText.finishText();
		else if(daText.delay > 0)
		{
			if(character.jsonFile.animations.length > curAnim && character.jsonFile.animations[curAnim] != null) {
				character.playAnim(character.jsonFile.animations[curAnim].anim);
			}
			characterAnimSpeed();
		}

		daText.y = DialogueBoxPsych.DEFAULT_TEXT_Y;
		if(daText.rows > 2) daText.y -= DialogueBoxPsych.LONG_TEXT_ADD;

		#if DISCORD_ALLOWED
		// Updating Discord Rich Presence
		var rpcText:String = w_text.text;
		if(rpcText == null || rpcText.length < 1) rpcText = '(Empty)';
		if(rpcText.length < 3) rpcText += '   ';
		DiscordClient.changePresence("Dialogue Editor", rpcText);
		#end
	}

	// ============ FlxUI 控件变更（菜单自绘控件写回数据源后广播）============
	override function getEvent(id:String, sender:Dynamic, data:Dynamic, ?params:Array<Dynamic>)
	{
		if (syncingWidgets) return;

		if (id == FlxUIInputText.CHANGE_EVENT && (sender is FlxUIInputText))
		{
			if (sender == w_char)
			{
				character.reloadCharacterJson(w_char.text);
				reloadCharacter();
				dialogueFile.dialogue[curSelected].portrait = w_char.text;
				reloadText(false);
				updateTextBox();
			}
			else if (sender == w_text)
			{
				dialogueFile.dialogue[curSelected].text = w_text.text;
				daText.text = w_text.text;
				if(daText.text == null) daText.text = '';
				reloadText(true);
			}
			else if (sender == w_sound)
			{
				daText.finishText();
				dialogueFile.dialogue[curSelected].sound = w_sound.text;
				daText.sound = w_sound.text;
				if(daText.sound == null) daText.sound = '';
			}
			unsavedProgress = true;
		}
		else if (id == FlxUINumericStepper.CHANGE_EVENT && (sender == w_speed))
		{
			dialogueFile.dialogue[curSelected].speed = w_speed.value;
			if(Math.isNaN(dialogueFile.dialogue[curSelected].speed) || dialogueFile.dialogue[curSelected].speed == null || dialogueFile.dialogue[curSelected].speed < 0.001) {
				dialogueFile.dialogue[curSelected].speed = 0.0;
			}
			daText.delay = dialogueFile.dialogue[curSelected].speed;
			reloadText(false);
			unsavedProgress = true;
		}
	}

	override function update(elapsed:Float) {
		mark('DE.update:frame');
		if(transitioning) {
			super.update(elapsed);
			return;
		}

		// 保持动画循环/打字状态
		if(character.animation.curAnim != null) {
			if(daText.finishedText) {
				if(character.animationIsLoop() && character.animation.curAnim.finished) {
					character.playAnim(character.animation.curAnim.name, true);
				}
			} else if(character.animation.curAnim.finished) {
				character.animation.curAnim.restart();
			}
		}

		// 输入框弹层打字时屏蔽编辑器热键
		var typing:Bool = false;
		try
		{
			var wc:Dynamic = w_char;
			var wt:Dynamic = w_text;
			var ws:Dynamic = w_sound;
			typing = (wc.hasFocus == true || wt.hasFocus == true || ws.hasFocus == true);
		}
		catch (e:Dynamic) {}

		if(!typing)
		{
			ClientPrefs.toggleVolumeKeys(true);
			if(FlxG.keys.justPressed.F1) openHelpMenu();
			if(FlxG.keys.justPressed.SPACE) {
				reloadText(false);
			}
			if(FlxG.keys.justPressed.ESCAPE) {
				if(!unsavedProgress)
				{
					MusicBeatState.switchState(new MasterEditorMenu());
					FlxG.sound.playMusic(Paths.music('freakyMenu'));
					transitioning = true;
				}
				else openSubState(new ConfirmationPopupSubstate(function() transitioning = true, {langGroup: 'dialogue', danger: true}));
				return;
			}

			var negaMult:Array<Int> = [1, -1];
			var controlAnim:Array<Bool> = [FlxG.keys.justPressed.W, FlxG.keys.justPressed.S];
			var controlText:Array<Bool> = [FlxG.keys.justPressed.D, FlxG.keys.justPressed.A];
			for (i in 0...controlAnim.length) {
				if(controlAnim[i]) {
					scrollAnim(-negaMult[i]);
				}
				if(controlText[i]) {
					changeText(negaMult[i]);
				}
			}

			if(FlxG.keys.justPressed.O) {
				dialogueFile.dialogue.remove(dialogueFile.dialogue[curSelected]);
				if(dialogueFile.dialogue.length < 1)
				{
					dialogueFile.dialogue = [
						copyDefaultLine()
					];
				}
				changeText();
		mark('DE.create:changeText');
				unsavedProgress = true;
			} else if(FlxG.keys.justPressed.P) {
				dialogueFile.dialogue.insert(curSelected + 1, copyDefaultLine());
				changeText(1);
				unsavedProgress = true;
			}
		}
		else ClientPrefs.toggleVolumeKeys(false);

		// 状态栏刷新
		if (menuBar != null && menuBar.statusBar != null)
		{
			menuBar.statusBar.setLine((curSelected + 1) + ' / ' + dialogueFile.dialogue.length);
			menuBar.statusBar.setChar(dialogueFile.dialogue[curSelected].portrait);
			var animName:String = '-';
			if (character.jsonFile.animations != null && character.jsonFile.animations.length > curAnim
				&& character.jsonFile.animations[curAnim] != null)
				animName = character.jsonFile.animations[curAnim].anim;
			menuBar.statusBar.setAnim(animName);
			menuBar.statusBar.setSpeed('' + dialogueFile.dialogue[curSelected].speed);
		}

		super.update(elapsed);
	}

	function scrollAnim(change:Int):Void
	{
		if (character.jsonFile.animations == null || character.jsonFile.animations.length < 1) return;
		curAnim -= change;
		if(curAnim < 0) curAnim = character.jsonFile.animations.length - 1;
		else if(curAnim >= character.jsonFile.animations.length) curAnim = 0;

		var animToPlay:String = character.jsonFile.animations[curAnim].anim;
		if(character.dialogueAnimations.exists(animToPlay)) {
			character.playAnim(animToPlay, daText.finishedText);
			dialogueFile.dialogue[curSelected].expression = animToPlay;
			unsavedProgress = true;
		}
	}

	function openHelpMenu():Void
	{
		if (menuBar == null) return;
		var helpIdx:Int = -1;
		for (i in 0...menuBar.menus.length)
			if (menuBar.menus[i].key == 'help') { helpIdx = i; break; }
		if (helpIdx > -1)
			menuBar.openMenu(helpIdx);
	}

	function doExit():Void
	{
		if(!unsavedProgress)
		{
			MusicBeatState.switchState(new MasterEditorMenu());
			FlxG.sound.playMusic(Paths.music('freakyMenu'));
			transitioning = true;
		}
		else openSubState(new ConfirmationPopupSubstate(function() transitioning = true, {langGroup: 'dialogue', danger: true}));
	}

	// ============ 切换对白行 ============
	function changeText(add:Int = 0) {
		curSelected = FlxMath.wrap(curSelected + add, 0, dialogueFile.dialogue.length - 1);

		syncWidgetsFromLine();
		curAnim = 0;

		var line:DialogueLine = dialogueFile.dialogue[curSelected];
		character.reloadCharacterJson(line.portrait);
		reloadCharacter();
		updateTextBox();

		if(character.jsonFile.animations != null && character.jsonFile.animations.length > 0)
		{
			for (num => animData in character.jsonFile.animations)
			{
				if(animData != null && animData.anim == line.expression)
				{
					curAnim = num;
					break;
				}
			}

			var selectedAnim:String = character.jsonFile.animations[curAnim].anim;
			character.playAnim(selectedAnim, daText.finishedText);
		}

		reloadText(false);
		characterAnimSpeed();
	}

	function characterAnimSpeed() {
		if(character.animation.curAnim != null) {
			var speed:Float = w_speed.value;
			var rate:Float = 24 - (((speed - 0.05) / 5) * 480);
			if(rate < 12) rate = 12;
			else if(rate > 48) rate = 48;
			character.animation.curAnim.frameRate = rate;
		}
	}

	// ============ 载入 / 保存 ============
	var _file:FileReference = null;
	function loadDialogue() {
		var jsonFilter:FileFilter = new FileFilter('JSON', 'json');
		_file = new FileReference();
		_file.addEventListener(#if desktop Event.SELECT #else Event.COMPLETE #end, onLoadComplete);
		_file.addEventListener(Event.CANCEL, onLoadCancel);
		_file.addEventListener(IOErrorEvent.IO_ERROR, onLoadError);
		_file.browse([#if !mac jsonFilter #end]);
	}

	function onLoadComplete(_):Void
	{
		_file.removeEventListener(#if desktop Event.SELECT #else Event.COMPLETE #end, onLoadComplete);
		_file.removeEventListener(Event.CANCEL, onLoadCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onLoadError);

		#if sys
		var fullPath:String = null;
		@:privateAccess
		if(_file.__path != null) fullPath = _file.__path;

		if(fullPath != null) {
			var rawJson:String = File.getContent(fullPath);
			if(rawJson != null) {
				var loadedDialog:DialogueFile = cast Json.parse(rawJson);
				if(loadedDialog.dialogue != null && loadedDialog.dialogue.length > 0)
				{
					var cutName:String = _file.name.substr(0, _file.name.length - 5);
					trace("Successfully loaded file: " + cutName);
					dialogueFile = loadedDialog;
					unsavedProgress = false;
					changeText();
		mark('DE.create:changeText');
					_file = null;
					return;
				}
			}
		}
		_file = null;
		#else
		trace("File couldn't be loaded! You aren't on Desktop, are you?");
		#end
	}

	function onLoadCancel(_):Void
	{
		_file.removeEventListener(#if desktop Event.SELECT #else Event.COMPLETE #end, onLoadComplete);
		_file.removeEventListener(Event.CANCEL, onLoadCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onLoadError);
		_file = null;
		trace("Cancelled file loading.");
	}

	function onLoadError(_):Void
	{
		_file.removeEventListener(#if desktop Event.SELECT #else Event.COMPLETE #end, onLoadComplete);
		_file.removeEventListener(Event.CANCEL, onLoadCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onLoadError);
		_file = null;
		trace("Problem loading file");
	}

	function saveDialogue() {
		var data:String = haxe.Json.stringify(dialogueFile, "\t");
		if (data.length > 0)
		{
			_file = new FileReference();
			_file.addEventListener(#if desktop Event.SELECT #else Event.COMPLETE #end, onSaveComplete);
			_file.addEventListener(Event.CANCEL, onSaveCancel);
			_file.addEventListener(IOErrorEvent.IO_ERROR, onSaveError);
			_file.save(data, "dialogue.json");
		}
	}

	function onSaveComplete(_):Void
	{
		_file.removeEventListener(#if desktop Event.SELECT #else Event.COMPLETE #end, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
		unsavedProgress = false;
		FlxG.log.notice("Successfully saved file.");
	}

	function onSaveCancel(_):Void
	{
		_file.removeEventListener(#if desktop Event.SELECT #else Event.COMPLETE #end, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
	}

	function onSaveError(_):Void
	{
		_file.removeEventListener(#if desktop Event.SELECT #else Event.COMPLETE #end, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
		FlxG.log.error("Problem saving file");
	}
}
