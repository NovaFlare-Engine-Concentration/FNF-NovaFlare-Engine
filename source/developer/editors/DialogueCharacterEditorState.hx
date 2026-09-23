package developer.editors;

import openfl.net.FileReference;
import openfl.events.Event;
import openfl.events.IOErrorEvent;
import openfl.net.FileFilter;
import haxe.Json;
import lime.system.Clipboard;

import flixel.addons.ui.FlxUIInputText;
import flixel.addons.ui.FlxUINumericStepper;
import flixel.addons.ui.FlxUICheckBox;
import flixel.addons.ui.FlxUIDropDownMenu;
import flixel.group.FlxSpriteGroup;
import flixel.text.FlxText;

import general.objects.TypedAlphabet;

import games.cutscenes.DialogueBoxPsych;
import games.cutscenes.DialogueCharacter;

/**
 * 对话立绘编辑器（NovaFlare 新版 UI）：
 *  - Adobe 风格顶栏菜单（DialogueCharacterEditorMenuBar）+ 底部状态栏 + EditorChromeUI 窗口栏
 *  - 角色/双幽灵/气泡/打字文字预览保留，字段编辑收进顶栏菜单（原生 FlxUI 控件只作数据源）
 */
class DialogueCharacterEditorState extends MusicBeatState
{
	var box:FlxSprite;
	var daText:TypedAlphabet = null;

	var camGame:FlxCamera;
	var camHUD:FlxCamera;

	var mainGroup:FlxSpriteGroup;
	var hudGroup:FlxSpriteGroup;

	var character:DialogueCharacter;
	var ghostLoop:DialogueCharacter;
	var ghostIdle:DialogueCharacter;

	var curAnim:Int = 0;
	var unsavedProgress:Bool = false;

	// ===== 顶栏菜单 =====
	var menuBar:DialogueCharacterEditorMenuBar;
	#if (cpp && windows)
	var windowChrome:EditorChromeUI;
	var modInfoPopup:general.objects.ModInfoPopup;
	#end

	var uiLayer:FlxSpriteGroup;
	var overlayLayer:FlxSpriteGroup;

	// ===== 原生控件（只作数据源，不渲染）=====
	var w_image:FlxUIInputText;        // 图像文件
	var w_pos_x:FlxUINumericStepper;   // 位置偏移 X
	var w_pos_y:FlxUINumericStepper;   // 位置偏移 Y
	var w_scale:FlxUINumericStepper;   // 缩放
	var w_no_aa:FlxUICheckBox;         // 关闭抗锯齿
	var w_anim:FlxUIDropDownMenu;      // 动画列表
	var w_anim_name:FlxUIInputText;    // 动画名
	var w_loop_name:FlxUIInputText;    // 循环前缀
	var w_idle_name:FlxUIInputText;    // 待机前缀

	var syncingWidgets:Bool = false;

	// 偏移/动画状态文本（HUD 左下，避开顶栏）
	var offsetLoopText:FlxText;
	var offsetIdleText:FlxText;

	var curSelectedAnim:String;
	var currentGhosts:Int = 0;
	var transitioning:Bool = false;

	override function create()
	{
		persistentUpdate = persistentDraw = true;
		camGame = initPsychCamera();
		camGame.bgColor = FlxColor.fromHSL(0, 0, 0.5);
		camHUD = new FlxCamera();
		camHUD.bgColor.alpha = 0;
		FlxG.cameras.add(camHUD, false);

		mainGroup = new FlxSpriteGroup();
		mainGroup.cameras = [camGame];
		hudGroup = new FlxSpriteGroup();
		hudGroup.cameras = [camGame];
		add(mainGroup);
		add(hudGroup);

		character = new DialogueCharacter();
		character.scrollFactor.set();
		mainGroup.add(character);

		ghostLoop = new DialogueCharacter();
		ghostLoop.alpha = 0;
		ghostLoop.color = FlxColor.RED;
		ghostLoop.isGhost = true;
		ghostLoop.jsonFile = character.jsonFile;
		ghostLoop.cameras = [camGame];
		mainGroup.add(ghostLoop);

		ghostIdle = new DialogueCharacter();
		ghostIdle.alpha = 0;
		ghostIdle.color = FlxColor.BLUE;
		ghostIdle.isGhost = true;
		ghostIdle.jsonFile = character.jsonFile;
		ghostIdle.cameras = [camGame];
		mainGroup.add(ghostIdle);

		box = new FlxSprite(70, 370);
		box.antialiasing = ClientPrefs.data.antialiasing;
		box.frames = Paths.getSparrowAtlas('speech_bubble');
		box.scrollFactor.set();
		box.animation.addByPrefix('normal', 'speech bubble normal', 24);
		box.animation.addByPrefix('center', 'speech bubble middle', 24);
		box.animation.play('normal', true);
		box.setGraphicSize(Std.int(box.width * 0.9));
		box.updateHitbox();
		hudGroup.add(box);

		// 偏移数值文本（HUD 相机，顶栏下方）
		offsetLoopText = new FlxText(10, 46, 0, '', 20);
		offsetLoopText.setFormat(Paths.font(EditorInputStyle.langFontFileName()), 20, FlxColor.RED, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		offsetLoopText.cameras = [camHUD];
		offsetLoopText.scrollFactor.set();
		add(offsetLoopText);
		offsetLoopText.visible = false;

		offsetIdleText = new FlxText(10, 76, 0, '', 20);
		offsetIdleText.setFormat(Paths.font(EditorInputStyle.langFontFileName()), 20, FlxColor.CYAN, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		offsetIdleText.cameras = [camHUD];
		offsetIdleText.scrollFactor.set();
		add(offsetIdleText);
		offsetIdleText.visible = false;

		reloadCharacter();
		updateTextBox();

		daText = new TypedAlphabet(DialogueBoxPsych.DEFAULT_TEXT_X, DialogueBoxPsych.DEFAULT_TEXT_Y, '', 0.05, false);
		daText.setScale(0.7);
		daText.text = DEFAULT_TEXT;
		hudGroup.add(daText);

		// ===== UI 层 =====
		uiLayer = new FlxSpriteGroup();
		uiLayer.cameras = [camHUD];
		uiLayer.scrollFactor.set();
		add(uiLayer);

		createLegacyWidgets();
		setupMenuBar();
		setupOverlayLayer();
		addLegacyWidgetsToScene();
		hideAllLegacyWidgets();

		#if (cpp && windows)
		windowChrome = new EditorChromeUI();
		windowChrome.scrollFactor.set();
		windowChrome.cameras = [camHUD];
		add(windowChrome);
		modInfoPopup = new general.objects.ModInfoPopup();
		modInfoPopup.scrollFactor.set();
		modInfoPopup.cameras = [camHUD];
		add(modInfoPopup);
		windowChrome.onTitleClick = () -> modInfoPopup.openUnder(windowChrome);
		// 顶栏左侧「退出 对话立绘编辑器」按钮
		windowChrome.setupExitButton('dialoguePortraitEditor', doExit);
		#end

		FlxG.mouse.visible = true;
		refreshAll();
		super.create();
	}

	// ============ 顶栏菜单 ============
	function setupMenuBar():Void
	{
		menuBar = new DialogueCharacterEditorMenuBar();
		menuBar.scrollFactor.set();
		menuBar.uiCamera = camHUD;
		menuBar.cameras = [camHUD];
		menuBar.onAction = function(actionKey:String) {
			handleMenuAction(actionKey);
		};
		menuBar.onMenuOpened = function(menuKey:String) {
			syncWidgetsFromData();
		};

		menuBar.registerWidget('w_image', w_image);
		menuBar.registerWidget('w_pos_x', w_pos_x);
		menuBar.registerWidget('w_pos_y', w_pos_y);
		menuBar.registerWidget('w_scale', w_scale);
		menuBar.registerWidget('w_no_aa', w_no_aa);
		menuBar.registerWidget('w_anim', w_anim);
		menuBar.registerWidget('w_anim_name', w_anim_name);
		menuBar.registerWidget('w_loop_name', w_loop_name);
		menuBar.registerWidget('w_idle_name', w_idle_name);

		uiLayer.add(menuBar);
	}

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
		w_image = new FlxUIInputText(0, 0, 120, character.jsonFile.image, 8);
		w_pos_x = new FlxUINumericStepper(0, 0, 10, character.jsonFile.position[0], -2000, 2000, 0);
		w_pos_y = new FlxUINumericStepper(0, 0, 10, character.jsonFile.position[1], -2000, 2000, 0);
		w_scale = new FlxUINumericStepper(0, 0, 0.05, character.jsonFile.scale, 0.1, 10, 2);
		w_no_aa = new FlxUICheckBox(0, 0, null, null, "No Antialiasing", 80);
		w_anim = new FlxUIDropDownMenu(0, 0, FlxUIDropDownMenu.makeStrIdLabelArray([''], false), function(id:String) {
			if (syncingWidgets) return;
			selectAnim(w_anim.selectedLabel);
		});
		w_anim_name = new FlxUIInputText(0, 0, 100, '', 8);
		w_loop_name = new FlxUIInputText(0, 0, 150, '', 8);
		w_idle_name = new FlxUIInputText(0, 0, 150, '', 8);

		w_no_aa.callback = function()
		{
			if (syncingWidgets) return;
			character.jsonFile.no_antialiasing = w_no_aa.checked;
			character.antialiasing = !character.jsonFile.no_antialiasing;
			ghostLoop.antialiasing = character.antialiasing;
			ghostIdle.antialiasing = character.antialiasing;
			unsavedProgress = true;
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
		addOne(w_image);
		addOne(w_pos_x);
		addOne(w_pos_y);
		addOne(w_scale);
		addOne(w_no_aa);
		addOne(w_anim);
		addOne(w_anim_name);
		addOne(w_loop_name);
		addOne(w_idle_name);
	}

	function hideAllLegacyWidgets():Void
	{
		var all:Array<Dynamic> = [w_image, w_pos_x, w_pos_y, w_scale, w_no_aa, w_anim, w_anim_name, w_loop_name, w_idle_name];
		for (w in all)
			EditorInputStyle.deepHide(w);
	}

	// ============ 菜单动作分发 ============
	function handleMenuAction(actionKey:String):Void
	{
		switch (actionKey)
		{
			case 'side_left':
				setCharSide('left');
			case 'side_center':
				setCharSide('center');
			case 'side_right':
				setCharSide('right');
			case 'reload_image':
				reloadCharacter();
				updateTextBox();
			case 'load_char', 'load':
				loadCharacter();
			case 'save_char', 'save':
				saveCharacter();
			case 'exit':
				doExit();
			case 'anim_add_update':
				addUpdateCurrentAnimation();
			case 'anim_remove':
				removeCurrentAnimation();
			case 'view_reset':
				camGame.zoom = 1;
				mainGroup.setPosition(0, 0);
				hudGroup.visible = true;
				hudGroup.alpha = 1;
				mainGroup.alpha = 1;
				ghostLoop.alpha = 0;
				ghostIdle.alpha = 0;
				offsetLoopText.visible = false;
				offsetIdleText.visible = false;
				currentGhosts = 0;
			case 'view_bubble':
				hudGroup.visible = !hudGroup.visible;
			case 'view_ghost':
				cycleGhosts();
		}
	}

	function setCharSide(side:String):Void
	{
		if (character.jsonFile.dialogue_pos == side) return;
		character.jsonFile.dialogue_pos = side;
		unsavedProgress = true;
		reloadCharacter();
		updateTextBox();
	}

	function cycleGhosts():Void
	{
		currentGhosts++;
		if (currentGhosts > 2) currentGhosts = 0;

		ghostLoop.visible = (currentGhosts != 1);
		ghostIdle.visible = (currentGhosts != 2);
		ghostLoop.alpha = (currentGhosts == 2 ? 1 : 0.6);
		ghostIdle.alpha = (currentGhosts == 1 ? 1 : 0.6);
		offsetLoopText.visible = (currentGhosts != 1);
		offsetIdleText.visible = (currentGhosts != 2);
	}

	// ============ 数据 <-> 控件同步 ============
	function syncWidgetsFromData():Void
	{
		if (character.jsonFile == null) return;
		syncingWidgets = true;
		w_image.text = character.jsonFile.image;
		w_pos_x.value = character.jsonFile.position[0];
		w_pos_y.value = character.jsonFile.position[1];
		w_scale.value = character.jsonFile.scale;
		w_no_aa.checked = (character.jsonFile.no_antialiasing == true);

		// 动画下拉数据
		var names:Array<String> = [];
		if (character.jsonFile.animations != null)
			for (a in character.jsonFile.animations)
				if (a != null && a.anim != null) names.push(a.anim);
		if (names.length < 1) names.push('');
		w_anim.setData(FlxUIDropDownMenu.makeStrIdLabelArray(names, false));
		if (curSelectedAnim != null) w_anim.selectedLabel = curSelectedAnim;

		// 当前动画字段
		var animShit:DialogueAnimArray = (curSelectedAnim != null) ? character.dialogueAnimations.get(curSelectedAnim) : null;
		if (animShit != null)
		{
			w_anim_name.text = animShit.anim;
			w_loop_name.text = animShit.loop_name;
			w_idle_name.text = animShit.idle_name;
		}
		else
		{
			w_anim_name.text = '';
			w_loop_name.text = '';
			w_idle_name.text = '';
		}
		syncingWidgets = false;
	}

	function refreshAll():Void
	{
		syncWidgetsFromData();
		updateGhostPositions();
	}

	// ============ FlxUI 控件变更 ============
	override function getEvent(id:String, sender:Dynamic, data:Dynamic, ?params:Array<Dynamic>)
	{
		if (syncingWidgets) return;

		if (id == FlxUIInputText.CHANGE_EVENT && (sender is FlxUIInputText))
		{
			if (sender == w_image)
			{
				character.jsonFile.image = w_image.text;
				unsavedProgress = true;
			}
			else if (sender == w_anim_name || sender == w_loop_name || sender == w_idle_name)
			{
				if (curSelectedAnim != null && character.dialogueAnimations.exists(curSelectedAnim))
				{
					var animShit:DialogueAnimArray = character.dialogueAnimations.get(curSelectedAnim);
					animShit.anim = w_anim_name.text;
					animShit.loop_name = w_loop_name.text;
					animShit.idle_name = w_idle_name.text;
					if (sender == w_anim_name)
					{
						// 名字改动：重映射选择
						character.dialogueAnimations.remove(curSelectedAnim);
						curSelectedAnim = animShit.anim;
						character.dialogueAnimations.set(curSelectedAnim, animShit);
						for (i in 0...character.jsonFile.animations.length)
							if (character.jsonFile.animations[i] == animShit)
							{
								character.jsonFile.animations[i].anim = animShit.anim;
								break;
							}
						syncWidgetsFromData();
					}
					character.reloadAnimations();
					ghostLoop.reloadAnimations();
					ghostIdle.reloadAnimations();
					unsavedProgress = true;
				}
			}
		}
		else if (id == FlxUINumericStepper.CHANGE_EVENT && (sender is FlxUINumericStepper))
		{
			if (sender == w_pos_x)
			{
				character.jsonFile.position[0] = w_pos_x.value;
				reloadCharacter();
				unsavedProgress = true;
			}
			else if (sender == w_pos_y)
			{
				character.jsonFile.position[1] = w_pos_y.value;
				reloadCharacter();
				unsavedProgress = true;
			}
			else if (sender == w_scale)
			{
				character.jsonFile.scale = w_scale.value;
				reloadCharacter();
				unsavedProgress = true;
			}
		}
	}

	// ============ 动画选择 / 增删 ============
	function selectAnim(name:String):Void
	{
		if (!character.dialogueAnimations.exists(name)) return;
		curSelectedAnim = name;
		var animShit:DialogueAnimArray = character.dialogueAnimations.get(name);

		ghostLoop.playAnim(name);
		ghostIdle.playAnim(name, true);
		offsetLoopText.text = 'Loop: ' + animShit.loop_offsets;
		offsetIdleText.text = 'Idle: ' + animShit.idle_offsets;
		offsetLoopText.visible = (currentGhosts != 1);
		offsetIdleText.visible = (currentGhosts != 2);

		syncingWidgets = true;
		w_anim.selectedLabel = name;
		w_anim_name.text = animShit.anim;
		w_loop_name.text = animShit.loop_name;
		w_idle_name.text = animShit.idle_name;
		syncingWidgets = false;
		updateGhostPositions();
	}

	function addUpdateCurrentAnimation():Void
	{
		var theAnim:String = w_anim_name.text.trim();
		if (theAnim.length < 1) return;

		if (character.dialogueAnimations.exists(theAnim)) // Update
		{
			for (i in 0...character.jsonFile.animations.length)
			{
				var animArray:DialogueAnimArray = character.jsonFile.animations[i];
				if (animArray.anim.trim() == theAnim)
				{
					animArray.loop_name = w_loop_name.text;
					animArray.idle_name = w_idle_name.text;
					break;
				}
			}
			character.reloadAnimations();
			ghostLoop.reloadAnimations();
			ghostIdle.reloadAnimations();
			if (curSelectedAnim == theAnim)
			{
				ghostLoop.playAnim(theAnim);
				ghostIdle.playAnim(theAnim, true);
			}
		}
		else // Add
		{
			var newAnim:DialogueAnimArray = {
				anim: theAnim,
				loop_name: w_loop_name.text,
				loop_offsets: [0, 0],
				idle_name: w_idle_name.text,
				idle_offsets: [0, 0]
			}
			character.jsonFile.animations.push(newAnim);
			character.reloadAnimations();
			ghostLoop.reloadAnimations();
			ghostIdle.reloadAnimations();
		}
		curSelectedAnim = theAnim;
		syncWidgetsFromData();
		selectAnim(theAnim);
		unsavedProgress = true;
	}

	function removeCurrentAnimation():Void
	{
		var target:String = w_anim_name.text.trim();
		for (i in 0...character.jsonFile.animations.length)
		{
			var animArray:DialogueAnimArray = character.jsonFile.animations[i];
			if (animArray != null && animArray.anim.trim() == target)
			{
				character.jsonFile.animations.remove(animArray);
				character.reloadAnimations();
				ghostLoop.reloadAnimations();
				ghostIdle.reloadAnimations();
				if (character.jsonFile.animations.length > 0)
				{
					curSelectedAnim = character.jsonFile.animations[0].anim;
					selectAnim(curSelectedAnim);
				}
				else
				{
					curSelectedAnim = null;
					offsetLoopText.visible = false;
					offsetIdleText.visible = false;
				}
				syncWidgetsFromData();
				unsavedProgress = true;
				return;
			}
		}
	}

	// ============ 预览刷新 ============
	function reloadCharacter()
	{
		var charsArray:Array<DialogueCharacter> = [character, ghostLoop, ghostIdle];
		for (char in charsArray)
		{
			char.frames = Paths.getSparrowAtlas('dialogue/' + character.jsonFile.image);
			char.jsonFile = character.jsonFile;
			char.reloadAnimations();
			char.setGraphicSize(Std.int(char.width * DialogueCharacter.DEFAULT_SCALE * character.jsonFile.scale));
			char.updateHitbox();
		}
		character.antialiasing = !(character.jsonFile.no_antialiasing == true);
		ghostLoop.antialiasing = character.antialiasing;
		ghostIdle.antialiasing = character.antialiasing;

		character.x = DialogueBoxPsych.LEFT_CHAR_X;
		character.y = DialogueBoxPsych.DEFAULT_CHAR_Y;

		switch(character.jsonFile.dialogue_pos)
		{
			case 'right':
				character.x = FlxG.width - character.width + DialogueBoxPsych.RIGHT_CHAR_X;
			case 'center':
				character.x = FlxG.width / 2;
				character.x -= character.width / 2;
		}
		character.x += character.jsonFile.position[0] + mainGroup.x;
		character.y += character.jsonFile.position[1] + mainGroup.y;

		if (character.jsonFile.animations != null && character.jsonFile.animations.length > 0)
		{
			var firstAnim:String = character.jsonFile.animations[0].anim;
			character.playAnim(firstAnim);
			if (curSelectedAnim != null && character.dialogueAnimations.exists(curSelectedAnim))
			{
				ghostLoop.playAnim(curSelectedAnim);
				ghostIdle.playAnim(curSelectedAnim, true);
				var animShit:DialogueAnimArray = character.dialogueAnimations.get(curSelectedAnim);
				offsetLoopText.text = 'Loop: ' + animShit.loop_offsets;
				offsetIdleText.text = 'Idle: ' + animShit.idle_offsets;
			}
			else
			{
				curSelectedAnim = firstAnim;
				ghostLoop.playAnim(firstAnim);
				ghostIdle.playAnim(firstAnim, true);
			}
		}
		updateGhostPositions();
	}

	function updateTextBox()
	{
		box.flipX = false;
		var anim:String = 'normal';
		switch(character.jsonFile.dialogue_pos)
		{
			case 'left':
				box.flipX = true;
			case 'center':
				anim = 'center';
		}
		box.animation.play(anim, true);
		DialogueBoxPsych.updateBoxOffsets(box);
	}

	function updateGhostPositions():Void
	{
		ghostLoop.setPosition(character.x, character.y);
		ghostIdle.setPosition(character.x, character.y);
		hudGroup.x = mainGroup.x;
		hudGroup.y = mainGroup.y;
	}

	private static var DEFAULT_TEXT:String = 'Lorem ipsum dolor sit amet';

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		if(transitioning) return;

		if(character.animation.curAnim != null)
		{
			if(daText.finishedText)
			{
				if(character.animationIsLoop())
				{
					character.playAnim(character.animation.curAnim.name, true);
				}
			}
			else if(character.animation.curAnim.finished)
			{
				character.animation.curAnim.restart();
			}
		}

		// 输入弹层打字时屏蔽编辑器热键
		var typing:Bool = false;
		try
		{
			var wi:Dynamic = w_image;
			var wn:Dynamic = w_anim_name;
			var wl:Dynamic = w_loop_name;
			var wid:Dynamic = w_idle_name;
			typing = (wi.hasFocus == true || wn.hasFocus == true || wl.hasFocus == true || wid.hasFocus == true);
		}
		catch (e:Dynamic) {}

		if(!typing)
		{
			ClientPrefs.toggleVolumeKeys(true);

			if(FlxG.keys.justPressed.F1) openHelpMenu();

			if(FlxG.keys.justPressed.SPACE)
			{
				if(character.jsonFile.animations != null && character.jsonFile.animations.length > curAnim
					&& character.jsonFile.animations[curAnim] != null)
					character.playAnim(character.jsonFile.animations[curAnim].anim);
				daText.resetDialogue();
				updateTextBox();
			}

			// 相机平移 JKLI
			var speed:Float = 300;
			var offsetAdd:Int = 1;
			if(FlxG.keys.pressed.SHIFT) { speed = 1200; offsetAdd = 10; }

			var negaMult:Array<Int> = [1, 1, -1, -1];
			var controlArray:Array<Bool> = [FlxG.keys.pressed.J, FlxG.keys.pressed.I, FlxG.keys.pressed.L, FlxG.keys.pressed.K];
			for (i in 0...controlArray.length)
			{
				if(controlArray[i])
				{
					if(i % 2 == 1) mainGroup.y += speed * elapsed * negaMult[i];
					else mainGroup.x += speed * elapsed * negaMult[i];
				}
			}

			// 偏移微调（无页面概念，常开）：WASD = loop 偏移，方向键 = idle 偏移
			if(curSelectedAnim != null && character.dialogueAnimations.exists(curSelectedAnim))
			{
				var moved:Bool = false;
				var animShit:DialogueAnimArray = character.dialogueAnimations.get(curSelectedAnim);
				var controlArrayLoop:Array<Bool> = [FlxG.keys.justPressed.A, FlxG.keys.justPressed.W, FlxG.keys.justPressed.D, FlxG.keys.justPressed.S];
				var controlArrayIdle:Array<Bool> = [FlxG.keys.justPressed.LEFT, FlxG.keys.justPressed.UP, FlxG.keys.justPressed.RIGHT, FlxG.keys.justPressed.DOWN];
				for (i in 0...controlArrayLoop.length)
				{
					if(controlArrayLoop[i])
					{
						if(i % 2 == 1) animShit.loop_offsets[1] += offsetAdd * negaMult[i];
						else animShit.loop_offsets[0] += offsetAdd * negaMult[i];
						moved = true;
					}
				}
				for (i in 0...controlArrayIdle.length)
				{
					if(controlArrayIdle[i])
					{
						if(i % 2 == 1) animShit.idle_offsets[1] += offsetAdd * negaMult[i];
						else animShit.idle_offsets[0] += offsetAdd * negaMult[i];
						moved = true;
					}
				}

				if(moved)
				{
					offsetLoopText.text = 'Loop: ' + animShit.loop_offsets;
					offsetIdleText.text = 'Idle: ' + animShit.idle_offsets;
					ghostLoop.offset.set(animShit.loop_offsets[0], animShit.loop_offsets[1]);
					ghostIdle.offset.set(animShit.idle_offsets[0], animShit.idle_offsets[1]);
					unsavedProgress = true;
				}
			}

			if (FlxG.keys.pressed.Q && camGame.zoom > 0.1)
			{
				camGame.zoom -= elapsed * camGame.zoom;
				if(camGame.zoom < 0.1) camGame.zoom = 0.1;
			}
			if (FlxG.keys.pressed.E && camGame.zoom < 1)
			{
				camGame.zoom += elapsed * camGame.zoom;
				if(camGame.zoom > 1) camGame.zoom = 1;
			}
			if(FlxG.keys.justPressed.H) cycleGhosts();
			if(FlxG.keys.justPressed.R)
			{
				camGame.zoom = 1;
				mainGroup.setPosition(0, 0);
				hudGroup.visible = true;
				hudGroup.alpha = 1;
				mainGroup.alpha = 1;
				ghostLoop.alpha = 0;
				ghostIdle.alpha = 0;
				offsetLoopText.visible = false;
				offsetIdleText.visible = false;
				currentGhosts = 0;
			}

			if(FlxG.keys.justPressed.ESCAPE) doExit();

			updateGhostPositions();
		}
		else ClientPrefs.toggleVolumeKeys(false);

		// 状态栏刷新
		if (menuBar != null && menuBar.statusBar != null)
		{
			menuBar.statusBar.setSide(character.jsonFile.dialogue_pos);
			menuBar.statusBar.setImage(character.jsonFile.image);
			menuBar.statusBar.setAnim(curSelectedAnim != null ? curSelectedAnim : '-');
			var offStr:String = '-';
			if (curSelectedAnim != null && character.dialogueAnimations.exists(curSelectedAnim))
			{
				var a:DialogueAnimArray = character.dialogueAnimations.get(curSelectedAnim);
				offStr = 'L:' + a.loop_offsets[0] + ',' + a.loop_offsets[1] + ' I:' + a.idle_offsets[0] + ',' + a.idle_offsets[1];
			}
			menuBar.statusBar.setOffset(offStr);
			menuBar.statusBar.setScale(Std.string(character.jsonFile.scale));
		}
	}

	function openHelpMenu():Void
	{
		if (menuBar == null) return;
		var helpIdx:Int = -1;
		for (i in 0...menuBar.menus.length)
			if (menuBar.menus[i].key == 'help') { helpIdx = i; break; }
		if (helpIdx > -1) menuBar.openMenu(helpIdx);
	}

	function doExit():Void
	{
		if(!unsavedProgress)
		{
			MusicBeatState.switchState(new MasterEditorMenu());
			FlxG.sound.playMusic(Paths.music('freakyMenu'));
			transitioning = true;
		}
		else openSubState(new ConfirmationPopupSubstate(function() transitioning = true, {langGroup: 'dialoguechar', danger: true}));
	}

	// ============ 载入 / 保存 ============
	var _file:FileReference = null;
	function loadCharacter()
	{
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

		if(fullPath != null)
		{
			var rawJson:String = File.getContent(fullPath);
			if(rawJson != null)
			{
				var loadedChar:DialogueCharacterFile = cast Json.parse(rawJson);
				if(loadedChar.dialogue_pos != null)
				{
					character.jsonFile = loadedChar;
					curSelectedAnim = null;
					reloadCharacter();
					updateTextBox();
					daText.resetDialogue();
					unsavedProgress = false;
					refreshAll();
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
	}

	function onLoadError(_):Void
	{
		_file.removeEventListener(#if desktop Event.SELECT #else Event.COMPLETE #end, onLoadComplete);
		_file.removeEventListener(Event.CANCEL, onLoadCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onLoadError);
		_file = null;
	}

	function saveCharacter()
	{
		var data:String = haxe.Json.stringify(character.jsonFile, "\t");
		if (data.length > 0)
		{
			var splittedImage:Array<String> = w_image.text.trim().split('_');
			var characterName:String = splittedImage[0].toLowerCase().replace(' ', '');

			_file = new FileReference();
			_file.addEventListener(#if desktop Event.SELECT #else Event.COMPLETE #end, onSaveComplete);
			_file.addEventListener(Event.CANCEL, onSaveCancel);
			_file.addEventListener(IOErrorEvent.IO_ERROR, onSaveError);
			_file.save(data, characterName + ".json");
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
