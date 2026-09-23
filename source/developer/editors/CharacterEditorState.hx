package developer.editors;

import lime.system.Clipboard;

import openfl.net.FileReference;
import openfl.events.Event;
import openfl.events.IOErrorEvent;
import openfl.utils.Assets;

import flixel.FlxObject;
import flixel.graphics.FlxGraphic;
import flixel.animation.FlxAnimation;
import flixel.addons.ui.*;
import flixel.math.FlxPoint;
import flixel.ui.FlxButton;

import general.backend.language.Language;

import games.objects.Character;
import games.objects.HealthIcon;
import games.objects.Bar;

// flixel 5.7.0+ fix
#if (FLX_DEBUG || flixel < version("5.7.0"))
typedef PointerGraphic = flixel.system.debug.interaction.tools.Pointer.GraphicCursorCross;
#else
@:bitmap("assets/images/debugger/cursorCross.png")
class PointerGraphic extends openfl.display.BitmapData
{
}
#end

class CharacterEditorState extends MusicBeatState
{
	var character:Character;
	var ghost:FlxSprite;
	#if flxanimate
	var animateGhost:FlxAnimate;
	var animateGhostImage:String;
	#end
	var cameraFollowPointer:FlxSprite;
	var isAnimateSprite:Bool = false;

	var silhouettes:FlxSpriteGroup;
	var dadPosition = FlxPoint.weak();
	var bfPosition = FlxPoint.weak();

	var healthBar:Bar;
	var healthIcon:HealthIcon;

	var copiedOffset:Array<Float> = [0, 0];
	var undoOffsets:Array<Float> = null; // Ctrl+Z 撤销用（保存撤销前的值）
	var _char:String = null;
	var _goToPlayState:Bool = false;

	var anims = null;
	var curAnim = 0;

	private var camEditor:FlxCamera;
	private var camHUD:FlxCamera;

	// ===== 顶栏菜单（Adobe 风格，与 ChartEditorMenuBar 同架构）=====
	var menuBar:CharacterEditorMenuBar;
	#if (cpp && windows)
	var windowChrome:EditorChromeUI;
	var modInfoPopup:general.objects.ModInfoPopup;
	#end

	// ★ 双图层方案（同一 camHUD 相机）：
	//   uiLayer —— 底层：菜单/动画列表/血条等全部 UI
	//   overlayLayer —— 顶层：输入覆盖层（widget / stepper 覆盖层），最后挂载 → 渲染在菜单之上
	var uiLayer:FlxSpriteGroup;
	var overlayLayer:FlxSpriteGroup;

	// ===== 原生控件引用（只作数据源，不渲染；由 menuBar 自绘接管显示）=====
	// Ghost
	var highlightGhost:FlxUICheckBox;
	var ghostAlphaSlider:FlxUISlider;
	// Settings
	var check_player:FlxUICheckBox;
	var charDropDown:FlxUIDropDownMenu;
	// Animations
	var animationDropDown:FlxUIDropDownMenu;
	var animationInputText:FlxUIInputText;
	var animationNameInputText:FlxUIInputText;
	var animationIndicesInputText:FlxUIInputText;
	var animationFramerate:FlxUINumericStepper;
	var animationLoopCheckBox:FlxUICheckBox;
	// Character
	var imageInputText:FlxUIInputText;
	var healthIconInputText:FlxUIInputText;
	var vocalsInputText:FlxUIInputText;
	var singDurationStepper:FlxUINumericStepper;
	var scaleStepper:FlxUINumericStepper;
	var positionXStepper:FlxUINumericStepper;
	var positionYStepper:FlxUINumericStepper;
	var positionCameraXStepper:FlxUINumericStepper;
	var positionCameraYStepper:FlxUINumericStepper;
	var flipXCheckBox:FlxUICheckBox;
	var noAntialiasingCheckBox:FlxUICheckBox;
	var healthColorStepperR:FlxUINumericStepper;
	var healthColorStepperG:FlxUINumericStepper;
	var healthColorStepperB:FlxUINumericStepper;

	public function new(char:String = null, goToPlayState:Bool = false)
	{
		this._char = char;
		this._goToPlayState = goToPlayState;
		if (this._char == null)
			this._char = Character.DEFAULT_CHARACTER;

		super();
	}

	override function create()
	{
		if (ClientPrefs.data.cacheOnGPU)
			Paths.clearStoredMemory();

		// 强制刷新语言数据，确保 character 等新分组被正确加载
		Language.resetData();

		FlxG.sound.music.stop();
		camEditor = initPsychCamera();

		camHUD = new FlxCamera();
		camHUD.bgColor.alpha = 0;
		FlxG.cameras.add(camHUD, false);

		// ★ 双图层：uiLayer 底层（所有 UI），overlayLayer 顶层（输入覆盖层，最后挂载）
		uiLayer = new FlxSpriteGroup();
		uiLayer.cameras = [camHUD];
		uiLayer.scrollFactor.set();
		add(uiLayer);

		loadBG();

		silhouettes = new FlxSpriteGroup();
		add(silhouettes);

		var dad:FlxSprite = new FlxSprite(dadPosition.x, dadPosition.y).loadGraphic(Paths.image('editors/silhouetteDad'));
		dad.antialiasing = ClientPrefs.data.antialiasing;
		dad.active = false;
		dad.offset.set(-4, 1);
		silhouettes.add(dad);

		var boyfriend:FlxSprite = new FlxSprite(bfPosition.x, bfPosition.y + 350).loadGraphic(Paths.image('editors/silhouetteBF'));
		boyfriend.antialiasing = ClientPrefs.data.antialiasing;
		boyfriend.active = false;
		boyfriend.offset.set(-6, 2);
		silhouettes.add(boyfriend);

		silhouettes.alpha = 0.25;

		ghost = new FlxSprite();
		ghost.visible = false;
		ghost.alpha = ghostAlpha;
		add(ghost);

		addCharacter();

		cameraFollowPointer = new FlxSprite(FlxGraphic.fromClass(PointerGraphic));
		cameraFollowPointer.setGraphicSize(40, 40);
		cameraFollowPointer.updateHitbox();
		add(cameraFollowPointer);

		// ===== 血条 + 图标（恢复原版：屏幕底部，icon 在血条上方）=====
		// ★ 必须在此处（早期）创建：放在 create 末尾会导致 FlxUIInputText 构造崩溃（已实测）
		healthBar = new Bar(30, FlxG.height - 75);
		healthBar.scrollFactor.set();
		uiLayer.add(healthBar);
		healthBar.cameras = [camHUD];

		healthIcon = new HealthIcon(character.healthIcon, false, false);
		healthIcon.y = FlxG.height - 150;
		uiLayer.add(healthIcon);
		healthIcon.cameras = [camHUD];

		// ===== 动画列表（状态栏下方，可滚动/可点击）=====
		setupAnimList();
		updateAnimList(); // addCharacter 时列表 UI 尚未创建，这里补刷一次

		FlxG.mouse.visible = true;
		FlxG.camera.zoom = 1;

		// ===== UI 控件创建（只作数据源，不渲染）=====
		addGhostUI();
		addSettingsUI();
		addAnimationsUI();
		addCharacterUI();

		// ===== 顶栏菜单栏（Adobe 风格）+ 状态栏 =====
		setupMenuBar();

		// ★ 顶层覆盖层容器（在菜单之后挂载 → 渲染在菜单之上）
		setupOverlayLayer();

		// ★ 控件挂到顶层覆盖层：输入覆盖层（openInputOverlay）显示在菜单之上
		addLegacyWidgetsToScene();
		hideAllLegacyWidgets();

		updatePointerPos();
		updateHealthBar();
		character.finishAnimation();

		addVirtualPad(LEFT_FULL, CHARACTER_EDITOR);
		addVirtualPadCamera(false);

		#if (cpp && windows)
		// 引擎自绘窗口控制组（右上角：图标+标题 / - □ ×，可拖动窗口）
		// 必须与新版 UI 同相机（camHUD），否则点击判定/层级全乱
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
		// 顶栏左侧「退出 角色编辑器」按钮
		windowChrome.setupExitButton('characterEditor', doExitEditor);
		#end

		if (ClientPrefs.data.cacheOnGPU)
			Paths.clearUnusedMemory();

		super.create();
	}

	// ============ 动画列表（屏幕右侧，可滚动/可点击，保留高亮与 offset 显示） ============
	static final ANIM_LIST_Y:Int = 68; // 顶栏 + 状态栏下方
	static final ANIM_LIST_W:Int = 300;
	static final ANIM_LIST_ROW_H:Int = 20;
	static final ANIM_LIST_VISIBLE:Int = 20;

	var animListX:Float = 10; // 运行时计算（屏幕右侧）
	var animListBg:FlxSprite;
	var animListBorder:FlxSprite; // 卡片边框
	var animListTexts:Array<FlxText> = [];
	var animListHits:Array<FlxSprite> = [];
	var animListHoverBgs:Array<FlxSprite> = []; // 行 hover 底色（0x0F8B5CF6）
	var animListSelBgs:Array<FlxSprite> = [];   // 当前动画行选中底色（0x268B5CF6）
	var animListScroll:Int = 0;
	var animListHoverIdx:Int = -1; // 当前 hover 的行（相对可见区）
	// 动画列表拖拽状态（按下记录，移动超阈值 → 拖动滚动；松开且未拖动 → 点击选中）
	var animListPressActive:Bool = false;
	var animListPressY:Float = 0;
	var animListPressScroll:Int = 0;
	var animListDragMoved:Bool = false;

	function setupAnimList():Void
	{
		animListX = FlxG.width - ANIM_LIST_W - 14;
		// ★ 设计规范：卡片面板背景 + 半透明白边框
		animListBorder = new FlxSprite().makeGraphic(ANIM_LIST_W + 10, ANIM_LIST_VISIBLE * ANIM_LIST_ROW_H + 10, 0x26FFFFFF);
		animListBorder.x = animListX - 5;
		animListBorder.y = ANIM_LIST_Y - 5;
		animListBorder.scrollFactor.set();
		animListBorder.cameras = [camHUD];
		animListBorder.active = false;
		uiLayer.add(animListBorder);

		animListBg = new FlxSprite().makeGraphic(ANIM_LIST_W + 8, ANIM_LIST_VISIBLE * ANIM_LIST_ROW_H + 8, 0xFF1C1F28);
		animListBg.x = animListX - 4;
		animListBg.y = ANIM_LIST_Y - 4;
		animListBg.scrollFactor.set();
		animListBg.cameras = [camHUD];
		animListBg.active = false;
		uiLayer.add(animListBg);

		for (i in 0...ANIM_LIST_VISIBLE)
		{
			// hover 底色（加在文本之下）
			var hoverBg:FlxSprite = new FlxSprite().makeGraphic(ANIM_LIST_W, ANIM_LIST_ROW_H, 0x0F8B5CF6);
			hoverBg.x = animListX;
			hoverBg.y = ANIM_LIST_Y + i * ANIM_LIST_ROW_H;
			hoverBg.scrollFactor.set();
			hoverBg.cameras = [camHUD];
			hoverBg.visible = false;
			hoverBg.active = false;
			uiLayer.add(hoverBg);
			animListHoverBgs.push(hoverBg);

			// 当前动画行选中底色
			var selBg:FlxSprite = new FlxSprite().makeGraphic(ANIM_LIST_W, ANIM_LIST_ROW_H, 0x268B5CF6);
			selBg.x = animListX;
			selBg.y = ANIM_LIST_Y + i * ANIM_LIST_ROW_H;
			selBg.scrollFactor.set();
			selBg.cameras = [camHUD];
			selBg.visible = false;
			selBg.active = false;
			uiLayer.add(selBg);
			animListSelBgs.push(selBg);

			var t:FlxText = new FlxText(animListX + 6, ANIM_LIST_Y + i * ANIM_LIST_ROW_H, ANIM_LIST_W - 10, '', 14);
			t.setFormat(null, 14, 0xFFC9CDD4, LEFT, NONE, 0x00000000);
			t.scrollFactor.set();
			t.cameras = [camHUD];
			t.active = false;
			uiLayer.add(t);
			animListTexts.push(t);

			var hit:FlxSprite = new FlxSprite().makeGraphic(ANIM_LIST_W, ANIM_LIST_ROW_H, FlxColor.TRANSPARENT);
			hit.x = animListX;
			hit.y = ANIM_LIST_Y + i * ANIM_LIST_ROW_H;
			hit.scrollFactor.set();
			hit.cameras = [camHUD];
			uiLayer.add(hit);
			animListHits.push(hit);
		}
	}

	/** 刷新动画列表可见行（滚动偏移 + 当前动画高亮 + hover 底色 + offset 显示） */
	function updateAnimList():Void
	{
		if (anims == null) return;
		var maxScroll:Int = Std.int(Math.max(0, anims.length - ANIM_LIST_VISIBLE));
		animListScroll = Std.int(FlxMath.bound(animListScroll, 0, maxScroll));

		for (i in 0...ANIM_LIST_VISIBLE)
		{
			// 列表 UI 尚未创建时（addCharacter 先于 setupAnimList）直接跳过
			if (i >= animListTexts.length || i >= animListHits.length) break;
			var idx:Int = animListScroll + i;
			var t:FlxText = animListTexts[i];
			if (idx < anims.length)
			{
				var anim:AnimArray = anims[idx];
				t.text = anim.anim + ': ' + anim.offsets;
				// ★ 设计规范：当前动画行 = 选中态（紫字）；其余 = 次级文字
				t.color = (idx == curAnim) ? 0xFFA78BFA : 0xFFC9CDD4;
				t.visible = true;
			}
			else
			{
				t.text = '';
				t.visible = false;
			}
			var rowVisible:Bool = (idx < anims.length);
			animListHits[i].visible = rowVisible;
			if (animListHoverBgs.length > i)
			{
				animListHoverBgs[i].visible = rowVisible && (i == animListHoverIdx) && (idx != curAnim);
				animListSelBgs[i].visible = rowVisible && (idx == curAnim);
			}
		}
	}

	/** 点击列表行 → 选中动画（播放 + 高亮 + 同步动画编辑框） */
	function selectAnimFromList(idx:Int):Void
	{
		if (idx < 0 || idx >= anims.length) return;
		curAnim = idx;
		character.playAnim(anims[idx].anim, true);
		updateTextColors();
		// 同步动画菜单的编辑框（等价于在动画下拉里选中）
		var anim:AnimArray = anims[idx];
		animationInputText.text = anim.anim;
		animationNameInputText.text = anim.name;
		animationLoopCheckBox.checked = anim.loop;
		animationFramerate.value = anim.fps;
		var indicesStr:String = anim.indices.toString();
		animationIndicesInputText.text = indicesStr.substr(1, indicesStr.length - 2);
		try { animationDropDown.selectedLabel = anim.anim; } catch (e:Dynamic) {}
	}

	function addCharacter(reload:Bool = false)
	{
		var pos:Int = -1;
		if (character != null)
		{
			pos = members.indexOf(character);
			remove(character);
			character.destroy();
		}

		var isPlayer = (reload ? character.isPlayer : !predictCharacterIsNotPlayer(_char));
		character = new Character(0, 0, _char, isPlayer);
		if (!reload && character.editorIsPlayer != null && isPlayer != character.editorIsPlayer)
		{
			character.isPlayer = !character.isPlayer;
			character.flipX = (character.originalFlipX != character.isPlayer);
			if (check_player != null)
				check_player.checked = character.isPlayer;
		}
		character.debugMode = true;

		if (pos > -1)
			insert(pos, character);
		else
			add(character);
		updateCharacterPositions();
		reloadAnimList();
		if (healthBar != null && healthIcon != null)
			updateHealthBar();
	}

	/** 创建顶栏菜单栏并注册所有控件（原生控件只作数据源） */
	function setupMenuBar():Void
	{
		menuBar = new CharacterEditorMenuBar();
		menuBar.scrollFactor.set();
		// ★ 菜单挂 HUD 相机：UI 不随主相机缩放（Q/E 缩放只影响舞台内容）
		menuBar.uiCamera = camHUD;
		menuBar.cameras = [camHUD];
		menuBar.onAction = function(actionKey:String) {
			handleMenuAction(actionKey);
		};
		// ★ 菜单打开后刷新 widget 显示值
		//   widget 在 visible=false 时被赋值后显示不会刷新，需要在菜单打开时强制同步
		menuBar.onMenuOpened = function(menuKey:String) {
			refreshMenuWidgets(menuKey);
		};

		// 注册 widget 引用（仅用于下拉菜单显示状态文本）
		menuBar.registerWidget('w_char_select', charDropDown);
		menuBar.registerWidget('w_image', imageInputText);
		menuBar.registerWidget('w_health_icon', healthIconInputText);
		menuBar.registerWidget('w_vocals', vocalsInputText);

		menuBar.registerWidget('w_anim_select', animationDropDown);
		menuBar.registerWidget('w_anim_name', animationInputText);
		menuBar.registerWidget('w_anim_symbol', animationNameInputText);
		menuBar.registerWidget('w_anim_fps', animationFramerate);
		menuBar.registerWidget('w_anim_loop', animationLoopCheckBox);
		menuBar.registerWidget('w_anim_indices', animationIndicesInputText);

		menuBar.registerWidget('w_playable', check_player);
		menuBar.registerWidget('w_flip_x', flipXCheckBox);
		menuBar.registerWidget('w_no_aa', noAntialiasingCheckBox);
		menuBar.registerWidget('w_scale', scaleStepper);
		menuBar.registerWidget('w_sing_duration', singDurationStepper);
		menuBar.registerWidget('w_pos_x', positionXStepper);
		menuBar.registerWidget('w_pos_y', positionYStepper);
		menuBar.registerWidget('w_cam_x', positionCameraXStepper);
		menuBar.registerWidget('w_cam_y', positionCameraYStepper);
		menuBar.registerWidget('w_health_r', healthColorStepperR);
		menuBar.registerWidget('w_health_g', healthColorStepperG);
		menuBar.registerWidget('w_health_b', healthColorStepperB);

		menuBar.registerWidget('w_highlight_ghost', highlightGhost);
		menuBar.registerWidget('w_ghost_alpha', ghostAlphaSlider);

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

	/** 菜单动作分发（Cmd 行点击回调） */
	function handleMenuAction(actionKey:String):Void
	{
		switch (actionKey)
		{
			case 'reload_image':
				var lastAnim = character.getAnimationName();
				character.imageFile = imageInputText.text;
				reloadCharacterImage();
				if (!character.isAnimationNull())
				{
					character.playAnim(lastAnim, true);
				}
			case 'get_icon_color':
				var coolColor:FlxColor = FlxColor.fromInt(CoolUtil.dominantColor(healthIcon));
				character.healthColorArray[0] = coolColor.red;
				character.healthColorArray[1] = coolColor.green;
				character.healthColorArray[2] = coolColor.blue;
				updateHealthBar();
			case 'anim_add_update':
				addUpdateCurrentAnimation();
			case 'anim_remove':
				removeCurrentAnimation();
			case 'make_ghost':
				makeGhost();
			case 'save':
				saveCharacter();
			case 'load_template':
				loadCharacterTemplate();
			case 'reload_char':
				addCharacter(true);
				updatePointerPos();
				reloadCharacterOptions();
				reloadCharacterDropDown();
		}
	}

	/** 菜单打开后刷新 widget 显示值（从当前角色数据同步） */
	function refreshMenuWidgets(menuKey:String):Void
	{
		reloadCharacterOptions();
		reloadCharacterDropDown();
		reloadAnimationDropDown();
	}

	/**
	 * 把所有原生 widget add 到场景，保证它们进入 FlxG.update() 循环。
	 * 之前只 new 不 add → widget 的 update() 从没被调 → 点了没反应，纯贴图。
	 * 用 try/catch 防御性处理重复 add 的情况。
	 */
	function addLegacyWidgetsToScene():Void
	{
		function addOne(w:Dynamic):Void {
			if (w == null) return;
			// ★ 挂到顶层覆盖层容器（overlayLayer）：输入覆盖层渲染在所有 UI 之上
			try { overlayLayer.add(w); } catch (e:Dynamic) {}
			// ★ 创建时就设 scrollFactor=0，之后 positionWidget 只需设坐标
			try { w.scrollFactor.set(0, 0); } catch (e:Dynamic) {}
			try { w.setScrollFactor(0, 0); } catch (e:Dynamic) {}
			try { w.cameras = [camHUD]; } catch (e:Dynamic) {}
		}
		// Ghost
		addOne(highlightGhost);
		addOne(ghostAlphaSlider);
		// Settings
		addOne(check_player);
		addOne(charDropDown);
		// Animations
		addOne(animationDropDown);
		addOne(animationInputText);
		addOne(animationNameInputText);
		addOne(animationIndicesInputText);
		addOne(animationFramerate);
		addOne(animationLoopCheckBox);
		// Character
		addOne(imageInputText);
		addOne(healthIconInputText);
		addOne(vocalsInputText);
		addOne(singDurationStepper);
		addOne(scaleStepper);
		addOne(positionXStepper);
		addOne(positionYStepper);
		addOne(positionCameraXStepper);
		addOne(positionCameraYStepper);
		addOne(flipXCheckBox);
		addOne(noAntialiasingCheckBox);
		addOne(healthColorStepperR);
		addOne(healthColorStepperG);
		addOne(healthColorStepperB);
	}

	/** 隐藏所有原生 widget（只作数据源，显示由 menuBar 自绘接管） */
	function hideAllLegacyWidgets():Void
	{
		var all:Array<Dynamic> = [
			highlightGhost, ghostAlphaSlider,
			check_player, charDropDown,
			animationDropDown, animationInputText, animationNameInputText, animationIndicesInputText,
			animationFramerate, animationLoopCheckBox,
			imageInputText, healthIconInputText, vocalsInputText,
			singDurationStepper, scaleStepper,
			positionXStepper, positionYStepper, positionCameraXStepper, positionCameraYStepper,
			flipXCheckBox, noAntialiasingCheckBox,
			healthColorStepperR, healthColorStepperG, healthColorStepperB
		];
		for (w in all)
			if (w != null) EditorInputStyle.deepHide(w);
	}

	/**
	 * 与 ESC / B 键等价的退出动作（顶栏「退出 角色编辑器」按钮共用）：
	 *   - _goToPlayState=true 时直接进入 PlayState（导出测试用）
	 *   - 否则回到 MasterEditorMenu 并播放 freakyMenu BGM
	 */
	function doExitEditor():Void
	{
		FlxG.mouse.visible = false;
		if (!_goToPlayState)
		{
			MusicBeatState.switchState(new developer.editors.MasterEditorMenu());
			FlxG.sound.playMusic(Paths.music('freakyMenu'));
		}
		else
			MusicBeatState.switchState(new PlayState());
	}

	/** 生成 Ghost 帧（原 Make Ghost 按钮逻辑） */
	function makeGhost():Void
	{
		var anim = anims[curAnim];
		if (!character.isAnimationNull())
		{
			var myAnim = anims[curAnim];
			if (!character.isAnimateAtlas)
			{
				ghost.loadGraphic(character.graphic);
				ghost.frames.frames = character.frames.frames;
				ghost.animation.copyFrom(character.animation);
				ghost.animation.play(character.animation.curAnim.name, true, false, character.animation.curAnim.curFrame);
				ghost.animation.pause();
			}
			else
				if (myAnim != null) // This is VERY unoptimized and bad, I hope to find a better replacement that loads only a specific frame as bitmap in the future.
			{
				#if flxanimate
				if (animateGhost == null) // If I created the animateGhost on create() and you didn't load an atlas, it would crash the game on destroy, so we create it here
				{
					animateGhost = new FlxAnimate(ghost.x, ghost.y);
					animateGhost.showPivot = false;
					insert(members.indexOf(ghost), animateGhost);
					animateGhost.active = false;
				}

				if (animateGhost == null || animateGhostImage != character.imageFile)
					Paths.loadAnimateAtlas(animateGhost, character.imageFile);

				if (myAnim.indices != null && myAnim.indices.length > 0)
					animateGhost.anim.addBySymbolIndices('anim', myAnim.name, myAnim.indices, 0, false);
				else
					animateGhost.anim.addBySymbol('anim', myAnim.name, 0, false);

				animateGhost.anim.play('anim', true, false, character.atlas.anim.curFrame);
				animateGhost.anim.pause();

				animateGhostImage = character.imageFile;
				#end
			}

			var spr:FlxSprite = #if flxanimate !character.isAnimateAtlas? #end
			ghost #if flxanimate :animateGhost #end;
			if (spr != null)
			{
				spr.setPosition(character.x, character.y);
				spr.antialiasing = character.antialiasing;
				spr.flipX = character.flipX;
				spr.alpha = ghostAlpha;

				spr.scale.set(character.scale.x, character.scale.y);
				spr.updateHitbox();

				spr.offset.set(character.offset.x, character.offset.y);
				spr.visible = true;

				var otherSpr:FlxSprite = #if flxanimate (spr == animateGhost) ? #end
				ghost #if flxanimate :animateGhost #end;
				if (otherSpr != null)
					otherSpr.visible = false;
			}
			trace('created ghost image');
		}
	}

	/** 添加/更新当前动画（原 Add/Update 按钮逻辑） */
	function addUpdateCurrentAnimation():Void
	{
		var indices:Array<Int> = [];
		var indicesStr:Array<String> = animationIndicesInputText.text.trim().split(',');
		if (indicesStr.length > 1)
		{
			for (i in 0...indicesStr.length)
			{
				var index:Int = Std.parseInt(indicesStr[i]);
				if (indicesStr[i] != null && indicesStr[i] != '' && !Math.isNaN(index) && index > -1)
				{
					indices.push(index);
				}
			}
		}

		var lastAnim:String = (character.animationsArray[curAnim] != null) ? character.animationsArray[curAnim].anim : '';
		var lastOffsets:Array<Int> = [0, 0];
		for (anim in character.animationsArray)
			if (animationInputText.text == anim.anim)
			{
				lastOffsets = anim.offsets;
				if (character.animOffsets.exists(animationInputText.text))
				{
					if (!character.isAnimateAtlas)
						character.animation.remove(animationInputText.text);
					#if flxanimate
					else
						@:privateAccess character.atlas.anim.animsMap.remove(animationInputText.text); #end
				}
				character.animationsArray.remove(anim);
			}

		var addedAnim:AnimArray = newAnim(animationInputText.text, animationNameInputText.text);
		addedAnim.fps = Math.round(animationFramerate.value);
		addedAnim.loop = animationLoopCheckBox.checked;
		addedAnim.indices = indices;
		addedAnim.offsets = lastOffsets;
		addAnimation(addedAnim.anim, addedAnim.name, addedAnim.fps, addedAnim.loop, addedAnim.indices);
		character.animationsArray.push(addedAnim);

		reloadAnimList();
		@:arrayAccess curAnim = Std.int(Math.max(0, character.animationsArray.indexOf(addedAnim)));
		character.playAnim(addedAnim.anim, true);
		trace('Added/Updated animation: ' + animationInputText.text);
	}

	/** 删除当前动画（原 Remove 按钮逻辑） */
	function removeCurrentAnimation():Void
	{
		for (anim in character.animationsArray)
			if (animationInputText.text == anim.anim)
			{
				var resetAnim:Bool = false;
				if (anim.anim == character.getAnimationName())
					resetAnim = true;
				if (character.animOffsets.exists(anim.anim))
				{
					if (!character.isAnimateAtlas)
						character.animation.remove(anim.anim);
					#if flxanimate
					else
						@:privateAccess character.atlas.anim.animsMap.remove(anim.anim); #end
					character.animOffsets.remove(anim.anim);
					character.animationsArray.remove(anim);
				}

				if (resetAnim && character.animationsArray.length > 0)
				{
					curAnim = FlxMath.wrap(curAnim, 0, anims.length - 1);
					character.playAnim(anims[curAnim].anim, true);
					updateTextColors();
				}
				reloadAnimList();
				trace('Removed animation: ' + animationInputText.text);
				break;
			}
	}

	/** 加载模板角色（原 Load Template 按钮逻辑） */
	function loadCharacterTemplate():Void
	{
		final _template:CharacterFile = {
			animations: [
				newAnim('idle', 'BF idle dance'),
				newAnim('singLEFT', 'BF NOTE LEFT0'),
				newAnim('singDOWN', 'BF NOTE DOWN0'),
				newAnim('singUP', 'BF NOTE UP0'),
				newAnim('singRIGHT', 'BF NOTE RIGHT0')
			],
			no_antialiasing: false,
			flip_x: false,
			healthicon: 'face',
			image: 'characters/BOYFRIEND',
			sing_duration: 4,
			scale: 1,
			healthbar_colors: [161, 161, 161],
			camera_position: [0, 0],
			position: [0, 0],
			vocals_file: null
		};

		character.loadCharacterFile(_template);
		character.color = FlxColor.WHITE;
		character.alpha = 1;
		reloadAnimList();
		reloadCharacterOptions();
		updateCharacterPositions();
		updatePointerPos();
		reloadCharacterDropDown();
		updateHealthBar();
	}

	var ghostAlpha:Float = 0.6;

	function addGhostUI()
	{
		highlightGhost = new FlxUICheckBox(10, 10, null, null, "Highlight Ghost", 100);
		highlightGhost.callback = function()
		{
			var value = highlightGhost.checked ? 125 : 0;
			ghost.colorTransform.redOffset = value;
			ghost.colorTransform.greenOffset = value;
			ghost.colorTransform.blueOffset = value;
			#if flxanimate
			if (animateGhost != null)
			{
				animateGhost.colorTransform.redOffset = value;
				animateGhost.colorTransform.greenOffset = value;
				animateGhost.colorTransform.blueOffset = value;
			}
			#end
		};

		ghostAlphaSlider = new FlxUISlider(this, 'ghostAlpha', 10, 40, 0, 1, 210, #if !hl null #else 0 #end, 5,
			FlxColor.WHITE, FlxColor.BLACK);
		ghostAlphaSlider.nameLabel.text = 'Opacity:';
		ghostAlphaSlider.decimals = 2;
		ghostAlphaSlider.callback = function(relativePos:Float)
		{
			ghost.alpha = ghostAlpha;
			#if flxanimate if (animateGhost != null)
				animateGhost.alpha = ghostAlpha; #end
		};
		ghostAlphaSlider.value = ghostAlpha;
	}

	function addSettingsUI()
	{
		check_player = new FlxUICheckBox(10, 10, null, null, "Playable Character", 100);
		check_player.checked = character.isPlayer;
		check_player.callback = function()
		{
			character.isPlayer = !character.isPlayer;
			character.flipX = !character.flipX;
			updateCharacterPositions();
			updatePointerPos(false);
		};

		charDropDown = new FlxUIDropDownMenu(10, 30, FlxUIDropDownMenu.makeStrIdLabelArray([''], true), function(index:String)
		{
			var intended = characterList[Std.parseInt(index)];
			if (intended == null || intended.length < 1)
				return;

			var characterPath:String = 'characters/$intended.json';
			var path:String = Paths.getPath(characterPath, TEXT, null, true);
			#if MODS_ALLOWED
			if (FileSystem.exists(path))
			#else
			if (Assets.exists(path))
			#end
			{
				_char = intended;
				check_player.checked = character.isPlayer;
				addCharacter();
				reloadCharacterOptions();
				reloadCharacterDropDown();
				updatePointerPos();
			}
		else
		{
			reloadCharacterDropDown();
			FlxG.sound.play(Paths.sound('cancelMenu'));
		}
		});
		reloadCharacterDropDown();
		charDropDown.selectedLabel = _char;
	}

	function addAnimationsUI()
	{
		animationInputText = new FlxUIInputText(15, 85, 80, '', 8);
		animationNameInputText = new FlxUIInputText(animationInputText.x, animationInputText.y + 35, 150, '', 8);
		animationIndicesInputText = new FlxUIInputText(animationNameInputText.x, animationNameInputText.y + 40, 250, '', 8);
		animationFramerate = new FlxUINumericStepper(animationInputText.x + 170, animationInputText.y, 1, 24, 0, 240, 0);
		animationLoopCheckBox = new FlxUICheckBox(animationNameInputText.x + 170, animationNameInputText.y - 1, null, null, "Should it Loop?", 100);

		animationDropDown = new FlxUIDropDownMenu(15, animationInputText.y - 55, FlxUIDropDownMenu.makeStrIdLabelArray([''], true), function(pressed:String)
		{
			var selectedAnimation:Int = Std.parseInt(pressed);
			var anim:AnimArray = character.animationsArray[selectedAnimation];
			animationInputText.text = anim.anim;
			animationNameInputText.text = anim.name;
			animationLoopCheckBox.checked = anim.loop;
			animationFramerate.value = anim.fps;

			var indicesStr:String = anim.indices.toString();
			animationIndicesInputText.text = indicesStr.substr(1, indicesStr.length - 2);
		});
		reloadAnimList();
		animationDropDown.selectedLabel = anims[0] != null ? anims[0].anim : '';
	}

	function addCharacterUI()
	{
		imageInputText = new FlxUIInputText(15, 30, 200, character.imageFile, 8);

		healthIconInputText = new FlxUIInputText(15, imageInputText.y + 35, 75, healthIcon.getCharacter(), 8);

		vocalsInputText = new FlxUIInputText(15, healthIconInputText.y + 35, 75, character.vocalsFile != null ? character.vocalsFile : '', 8);

		singDurationStepper = new FlxUINumericStepper(15, vocalsInputText.y + 45, 0.1, 4, 0, 999, 1);

		scaleStepper = new FlxUINumericStepper(15, singDurationStepper.y + 40, 0.1, 1, 0.05, 10, 1);

		flipXCheckBox = new FlxUICheckBox(singDurationStepper.x + 80, singDurationStepper.y, null, null, "Flip X", 50);
		flipXCheckBox.checked = character.flipX;
		if (character.isPlayer)
			flipXCheckBox.checked = !flipXCheckBox.checked;
		flipXCheckBox.callback = function()
		{
			character.originalFlipX = !character.originalFlipX;
			character.flipX = (character.originalFlipX != character.isPlayer);
		};

		noAntialiasingCheckBox = new FlxUICheckBox(flipXCheckBox.x, flipXCheckBox.y + 40, null, null, "No Antialiasing", 80);
		noAntialiasingCheckBox.checked = character.noAntialiasing;
		noAntialiasingCheckBox.callback = function()
		{
			character.antialiasing = false;
			if (!noAntialiasingCheckBox.checked && ClientPrefs.data.antialiasing)
			{
				character.antialiasing = true;
			}
			character.noAntialiasing = noAntialiasingCheckBox.checked;
		};

		// 位置/相机步进：默认 ±5（菜单里按住 Shift 变 ±1 微调）
		positionXStepper = new FlxUINumericStepper(flipXCheckBox.x + 110, flipXCheckBox.y, 5, character.positionArray[0], -9000, 9000, 0);
		positionYStepper = new FlxUINumericStepper(positionXStepper.x + 60, positionXStepper.y, 5, character.positionArray[1], -9000, 9000, 0);

		positionCameraXStepper = new FlxUINumericStepper(positionXStepper.x, positionXStepper.y + 40, 5, character.cameraPosition[0], -9000, 9000, 0);
		positionCameraYStepper = new FlxUINumericStepper(positionYStepper.x, positionYStepper.y + 40, 5, character.cameraPosition[1], -9000, 9000, 0);

		healthColorStepperR = new FlxUINumericStepper(singDurationStepper.x, positionCameraYStepper.y + 40, 20, character.healthColorArray[0], 0, 255, 0);
		healthColorStepperG = new FlxUINumericStepper(singDurationStepper.x + 65, positionCameraYStepper.y + 40, 20, character.healthColorArray[1], 0, 255, 0);
		healthColorStepperB = new FlxUINumericStepper(singDurationStepper.x + 130, positionCameraYStepper.y + 40, 20, character.healthColorArray[2], 0, 255, 0);
	}

	override function getEvent(id:String, sender:Dynamic, data:Dynamic, ?params:Array<Dynamic>)
	{
		if (id != FlxUIInputText.CHANGE_EVENT && id != FlxUINumericStepper.CHANGE_EVENT)
			return;

		if (sender is FlxUIInputText)
		{
			if (sender == healthIconInputText)
			{
				var lastIcon = healthIcon.getCharacter();
				healthIcon.changeIcon(healthIconInputText.text, false);
				character.healthIcon = healthIconInputText.text;
				if (lastIcon != healthIcon.getCharacter())
					updatePresence();
			}
			else if (sender == vocalsInputText)
				character.vocalsFile = vocalsInputText.text;
			else if (sender == imageInputText)
				character.imageFile = imageInputText.text;
		}
		else if (sender is FlxUINumericStepper)
		{
			if (sender == scaleStepper)
			{
				reloadCharacterImage();
				character.jsonScale = sender.value;
				character.scale.set(character.jsonScale, character.jsonScale);
				character.updateHitbox();
				updatePointerPos(false);
			}
			else if (sender == positionXStepper)
			{
				character.positionArray[0] = positionXStepper.value;
				updateCharacterPositions();
			}
			else if (sender == positionYStepper)
			{
				character.positionArray[1] = positionYStepper.value;
				updateCharacterPositions();
			}
			else if (sender == singDurationStepper)
			{
				character.singDuration = singDurationStepper.value;
			}
			else if (sender == positionCameraXStepper)
			{
				character.cameraPosition[0] = positionCameraXStepper.value;
				updatePointerPos();
			}
			else if (sender == positionCameraYStepper)
			{
				character.cameraPosition[1] = positionCameraYStepper.value;
				updatePointerPos();
			}
			else if (sender == healthColorStepperR)
			{
				character.healthColorArray[0] = Math.round(healthColorStepperR.value);
				updateHealthBar();
			}
			else if (sender == healthColorStepperG)
			{
				character.healthColorArray[1] = Math.round(healthColorStepperG.value);
				updateHealthBar();
			}
			else if (sender == healthColorStepperB)
			{
				character.healthColorArray[2] = Math.round(healthColorStepperB.value);
				updateHealthBar();
			}
		}
	}

	function reloadCharacterImage()
	{
		var lastAnim:String = character.getAnimationName();
		var anims:Array<AnimArray> = character.animationsArray.copy();

		character.atlas = FlxDestroyUtil.destroy(character.atlas);
		character.isAnimateAtlas = false;
		character.color = FlxColor.WHITE;
		character.alpha = 1;
		#if flxanimate
		if (Paths.fileExists('images/' + character.imageFile + '/Animation.json', TEXT))
		{
			character.atlas = new FlxAnimate();
			character.atlas.showPivot = false;
			try
			{
				Paths.loadAnimateAtlas(character.atlas, character.imageFile);
			}
			catch (e:Dynamic)
			{
				FlxG.log.warn('Could not load atlas ${character.imageFile}: $e');
			}
			character.isAnimateAtlas = true;
		}
		else
		#end if (Paths.fileExists('images/' + character.imageFile + '.txt', TEXT))
			character.frames = Paths.getPackerAtlas(character.imageFile);
	else if (Paths.fileExists('images/' + character.imageFile + '.json', TEXT))
			character.frames = Paths.getAsepriteAtlas(character.imageFile);
	else
			character.frames = Paths.getSparrowAtlas(character.imageFile);

		for (anim in anims)
		{
			var animAnim:String = '' + anim.anim;
			var animName:String = '' + anim.name;
			var animFps:Int = anim.fps;
			var animLoop:Bool = !!anim.loop; // Bruh
			var animIndices:Array<Int> = anim.indices;
			addAnimation(animAnim, animName, animFps, animLoop, animIndices);
		}

		if (anims.length > 0)
		{
			if (lastAnim != '')
				character.playAnim(lastAnim, true);
			else
				character.dance();
		}
	}

	function reloadCharacterOptions()
	{
		check_player.checked = character.isPlayer;
		imageInputText.text = character.imageFile;
		healthIconInputText.text = character.healthIcon;
		vocalsInputText.text = character.vocalsFile != null ? character.vocalsFile : '';
		singDurationStepper.value = character.singDuration;
		scaleStepper.value = character.jsonScale;
		flipXCheckBox.checked = character.originalFlipX;
		noAntialiasingCheckBox.checked = character.noAntialiasing;
		positionXStepper.value = character.positionArray[0];
		positionYStepper.value = character.positionArray[1];
		positionCameraXStepper.value = character.cameraPosition[0];
		positionCameraYStepper.value = character.cameraPosition[1];
		reloadAnimationDropDown();
		updateHealthBar();
	}

	var holdingArrowsTime:Float = 0;
	var holdingArrowsElapsed:Float = 0;
	var holdingFrameTime:Float = 0;
	var holdingFrameElapsed:Float = 0;

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		// ===== 顶栏状态栏更新（只显示变化，内部有缓存）=====
		if (menuBar != null && menuBar.statusBar != null)
		{
			menuBar.statusBar.setCharacter(_char);
			var animName:String = 'NO ANIM';
			var frames:Int = 0;
			var length:Int = 0;
			if (!character.isAnimationNull())
			{
				animName = character.getAnimationName();
				if (!character.isAnimateAtlas)
				{
					frames = character.animation.curAnim.curFrame;
					length = character.animation.curAnim.numFrames;
				}
				#if flxanimate
				else
				{
					frames = character.atlas.anim.curFrame;
					length = character.atlas.anim.length;
				}
				#end
			}
			menuBar.statusBar.setAnim(animName);
			menuBar.statusBar.setOffset(Std.int(character.offset.x) + ' / ' + Std.int(character.offset.y));
			menuBar.statusBar.setFrame('$frames / ${length - 1}');
			menuBar.statusBar.setZoom(FlxMath.roundDecimal(FlxG.camera.zoom, 2) + 'x');
		}

		if (animationInputText.hasFocus || animationNameInputText.hasFocus || animationIndicesInputText.hasFocus || imageInputText.hasFocus
			|| healthIconInputText.hasFocus || vocalsInputText.hasFocus)
		{
			ClientPrefs.toggleVolumeKeys(false);
			return;
		}
		ClientPrefs.toggleVolumeKeys(true);

		var shiftMult:Float = 1;
		var ctrlMult:Float = 1;
		var shiftMultBig:Float = 1;
		if (FlxG.keys.pressed.SHIFT || virtualPad.buttonC.pressed)
		{
			shiftMult = 4;
			shiftMultBig = 10;
		}
		if (FlxG.keys.pressed.CONTROL /*|| virtualPad.buttonC.pressed*/)
			ctrlMult = 0.25;

		// CAMERA CONTROLS
		if (FlxG.keys.pressed.J #if mobile || (virtualPad.buttonLeft.pressed && virtualPad.buttonG.pressed) #end)
			FlxG.camera.scroll.x -= elapsed * 500 * shiftMult * ctrlMult;
		if (FlxG.keys.pressed.K #if mobile || (virtualPad.buttonDown.pressed && virtualPad.buttonG.pressed) #end)
			FlxG.camera.scroll.y += elapsed * 500 * shiftMult * ctrlMult;
		if (FlxG.keys.pressed.L #if mobile || (virtualPad.buttonRight.pressed && virtualPad.buttonG.pressed) #end)
			FlxG.camera.scroll.x += elapsed * 500 * shiftMult * ctrlMult;
		if (FlxG.keys.pressed.I #if mobile || (virtualPad.buttonUp.pressed && virtualPad.buttonG.pressed) #end)
			FlxG.camera.scroll.y -= elapsed * 500 * shiftMult * ctrlMult;

		if (FlxG.keys.justPressed.R && !FlxG.keys.pressed.CONTROL || virtualPad.buttonZ.justPressed)
			FlxG.camera.zoom = 1;
		else if ((FlxG.keys.pressed.E || virtualPad.buttonX.pressed) && FlxG.camera.zoom < 3)
		{
			FlxG.camera.zoom += elapsed * FlxG.camera.zoom * shiftMult * ctrlMult;
			if (FlxG.camera.zoom > 3)
				FlxG.camera.zoom = 3;
		}
		else if ((FlxG.keys.pressed.Q || virtualPad.buttonY.pressed) && FlxG.camera.zoom > 0.1)
		{
			FlxG.camera.zoom -= elapsed * FlxG.camera.zoom * shiftMult * ctrlMult;
			if (FlxG.camera.zoom < 0.1)
				FlxG.camera.zoom = 0.1;
		}

		// Zoom 显示已由顶栏状态栏接管（update 开头更新）

		// CHARACTER CONTROLS
		var changedAnim:Bool = false;
		if (anims.length > 1)
		{
			if ((FlxG.keys.justPressed.W || virtualPad.buttonV.justPressed) && (changedAnim = true))
				curAnim--;
			else if ((FlxG.keys.justPressed.S || virtualPad.buttonD.justPressed) && (changedAnim = true))
				curAnim++;

			if (changedAnim)
			{
				undoOffsets = null;
				curAnim = FlxMath.wrap(curAnim, 0, anims.length - 1);
				character.playAnim(anims[curAnim].anim, true);
				updateTextColors();
			}
		}

		var changedOffset = false;
		var moveKeysP;
		var moveKeys;
		if (controls.mobileC)
		{
			moveKeysP = [
				virtualPad.buttonLeft.justPressed,
				virtualPad.buttonRight.justPressed,
				virtualPad.buttonUp.justPressed,
				virtualPad.buttonDown.justPressed
			];
			moveKeys = [
				virtualPad.buttonLeft.pressed,
				virtualPad.buttonRight.pressed,
				virtualPad.buttonUp.pressed,
				virtualPad.buttonDown.pressed
			];
		}
		else
		{
			moveKeysP = [
				FlxG.keys.justPressed.LEFT,
				FlxG.keys.justPressed.RIGHT,
				FlxG.keys.justPressed.UP,
				FlxG.keys.justPressed.DOWN
			];
			moveKeys = [
				FlxG.keys.pressed.LEFT,
				FlxG.keys.pressed.RIGHT,
				FlxG.keys.pressed.UP,
				FlxG.keys.pressed.DOWN
			];
		}
		if (moveKeysP.contains(true))
		{
			if (controls.mobileC && virtualPad.buttonG.pressed)
				return;
			character.offset.x += ((moveKeysP[0] ? 1 : 0) - (moveKeysP[1] ? 1 : 0)) * shiftMultBig;
			character.offset.y += ((moveKeysP[2] ? 1 : 0) - (moveKeysP[3] ? 1 : 0)) * shiftMultBig;
			changedOffset = true;
		}

		if (moveKeys.contains(true))
		{
			if (controls.mobileC && virtualPad.buttonG.pressed)
				return;
			holdingArrowsTime += elapsed;
			if (holdingArrowsTime > 0.6)
			{
				holdingArrowsElapsed += elapsed;
				while (holdingArrowsElapsed > (1 / 60))
				{
					character.offset.x += ((moveKeys[0] ? 1 : 0) - (moveKeys[1] ? 1 : 0)) * shiftMultBig;
					character.offset.y += ((moveKeys[2] ? 1 : 0) - (moveKeys[3] ? 1 : 0)) * shiftMultBig;
					holdingArrowsElapsed -= (1 / 60);
					changedOffset = true;
				}
			}
		}
		else
			holdingArrowsTime = 0;

		if (FlxG.mouse.pressedRight && (FlxG.mouse.deltaScreenX != 0 || FlxG.mouse.deltaScreenY != 0))
		{
			character.offset.x -= FlxG.mouse.deltaScreenX;
			character.offset.y -= FlxG.mouse.deltaScreenY;
			changedOffset = true;
		}

		if (FlxG.keys.pressed.CONTROL)
		{
			if (FlxG.keys.justPressed.C)
			{
				copiedOffset[0] = character.offset.x;
				copiedOffset[1] = character.offset.y;
				changedOffset = true;
			}
			else if (FlxG.keys.justPressed.V)
			{
				undoOffsets = [character.offset.x, character.offset.y];
				character.offset.x = copiedOffset[0];
				character.offset.y = copiedOffset[1];
				changedOffset = true;
			}
			else if (FlxG.keys.justPressed.R)
			{
				undoOffsets = [character.offset.x, character.offset.y];
				character.offset.set(0, 0);
				changedOffset = true;
			}
			else if (FlxG.keys.justPressed.Z && undoOffsets != null)
			{
				character.offset.x = undoOffsets[0];
				character.offset.y = undoOffsets[1];
				changedOffset = true;
			}
			else if (FlxG.keys.justPressed.S)
			{
				// Ctrl+S 快速保存角色
				saveCharacter();
			}
		}
		if (virtualPad.buttonA.justPressed)
		{
			undoOffsets = [character.offset.x, character.offset.y];
			character.offset.x = copiedOffset[0];
			character.offset.y = copiedOffset[1];
			changedOffset = true;
		}

		var anim = anims[curAnim];
		if (changedOffset && anim != null && anim.offsets != null)
		{
			anim.offsets[0] = Std.int(character.offset.x);
			anim.offsets[1] = Std.int(character.offset.y);

			updateAnimList(); // 刷新动画列表中的 offset 显示
			character.addOffset(anim.anim, character.offset.x, character.offset.y);
		}

		if (!character.isAnimationNull())
		{
			if (FlxG.keys.pressed.A || FlxG.keys.pressed.D)
			{
				holdingFrameTime += elapsed;
				if (holdingFrameTime > 0.5)
					holdingFrameElapsed += elapsed;
			}
			else
				holdingFrameTime = 0;

			if (FlxG.keys.justPressed.SPACE)
				character.playAnim(character.getAnimationName(), true);

			var frames:Int = 0;
			var length:Int = 0;
			if (!character.isAnimateAtlas)
			{
				frames = character.animation.curAnim.curFrame;
				length = character.animation.curAnim.numFrames;
			}
			#if flxanimate
			else
			{
				frames = character.atlas.anim.curFrame;
				length = character.atlas.anim.length;
			}
			#end

			if (FlxG.keys.justPressed.A || FlxG.keys.justPressed.D || holdingFrameTime > 0.5)
			{
				var isLeft = false;
				if ((holdingFrameTime > 0.5 && FlxG.keys.pressed.A) || FlxG.keys.justPressed.A)
					isLeft = true;
				character.animPaused = true;

				if (holdingFrameTime <= 0.5 || holdingFrameElapsed > 0.1)
				{
					frames = FlxMath.wrap(frames + Std.int(isLeft ? -shiftMult : shiftMult), 0, length - 1);
					if (!character.isAnimateAtlas)
						character.animation.curAnim.curFrame = frames;
					#if flxanimate
					else
						character.atlas.anim.curFrame = frames; #end
					holdingFrameElapsed -= 0.1;
				}
			}
		}

		// ===== 动画列表交互：滚轮滚动 + 拖拽滚动 + 点击选中（松开时判定；菜单展开时让位给菜单）=====
		var menuOpen:Bool = (menuBar != null && menuBar.activeMenu >= 0);
		var mp:FlxPoint = FlxG.mouse.getViewPosition(camHUD);
		var mX:Float = mp.x;
		var mY:Float = mp.y;
		mp.put();
		var inAnimList:Bool = (mX >= animListX && mX <= animListX + ANIM_LIST_W && mY >= ANIM_LIST_Y && mY <= ANIM_LIST_Y + ANIM_LIST_VISIBLE * ANIM_LIST_ROW_H);
		// 列表 hover 行检测（子菜单 hover 紫底）
		if (!menuOpen && inAnimList)
		{
			var hoverRow:Int = -1;
			for (i in 0...ANIM_LIST_VISIBLE)
			{
				var hit = animListHits[i];
				if (hit == null || !hit.visible) continue;
				if (mX >= hit.x && mX <= hit.x + hit.width && mY >= hit.y && mY <= hit.y + hit.height)
				{
					hoverRow = i;
					break;
				}
			}
			if (hoverRow != animListHoverIdx)
			{
				animListHoverIdx = hoverRow;
				updateAnimList();
			}
		}
		else if (animListHoverIdx != -1)
		{
			animListHoverIdx = -1;
			updateAnimList();
		}
		if (!menuOpen && inAnimList && FlxG.mouse.wheel != 0)
		{
			animListScroll -= FlxG.mouse.wheel;
			animListScroll = Std.int(FlxMath.bound(animListScroll, 0, Std.int(Math.max(0, anims.length - ANIM_LIST_VISIBLE))));
			updateAnimList();
		}
		// 拖拽滚动 + 点击选择（按下记录，移动超阈值 → 拖动；松开且未拖动 → 视为点击选中）
		if (!menuOpen && inAnimList)
		{
			if (FlxG.mouse.justPressed)
			{
				animListPressActive = true;
				animListDragMoved = false;
				animListPressY = mY;
				animListPressScroll = animListScroll;
			}
			if (animListPressActive && FlxG.mouse.pressed)
			{
				var dy:Float = mY - animListPressY;
				if (!animListDragMoved && Math.abs(dy) > 6)
					animListDragMoved = true;
				if (animListDragMoved)
				{
					var maxScroll:Int = Std.int(Math.max(0, anims.length - ANIM_LIST_VISIBLE));
					var newScroll:Int = Std.int(FlxMath.bound(animListPressScroll - Std.int(dy / ANIM_LIST_ROW_H), 0, maxScroll));
					if (newScroll != animListScroll)
					{
						animListScroll = newScroll;
						updateAnimList();
						// 重新基准：拖拽过程平滑跟随
						animListPressScroll = newScroll;
						animListPressY = mY;
					}
				}
			}
			if (animListPressActive && FlxG.mouse.justReleased)
			{
				if (!animListDragMoved)
				{
					// 点击选中：松开位置的行
					for (i in 0...ANIM_LIST_VISIBLE)
					{
						var hit = animListHits[i];
						if (hit == null || !hit.visible) continue;
						if (mX >= hit.x && mX <= hit.x + hit.width && mY >= hit.y && mY <= hit.y + hit.height)
						{
							selectAnimFromList(animListScroll + i);
							break;
						}
					}
				}
				animListPressActive = false;
			}
			// 按住但移出列表区域 → 取消本次按下
			if (animListPressActive && !inAnimList && !FlxG.mouse.pressed)
				animListPressActive = false;
		}
		else if (animListPressActive)
		{
			animListPressActive = false;
		}

		// OTHER CONTROLS
		if (FlxG.keys.justPressed.F12 || virtualPad.buttonS.justPressed)
			silhouettes.visible = !silhouettes.visible;

		if (FlxG.keys.justPressed.F1 || virtualPad.buttonF.justPressed)
		{
			// ★ 帮助已并入顶栏菜单：F1 直接打开【帮助】菜单
			var helpIdx:Int = -1;
			for (i in 0...menuBar.menus.length)
				if (menuBar.menus[i].key == 'help') { helpIdx = i; break; }
			if (helpIdx >= 0)
				menuBar.openMenu(helpIdx);
		}
		else if (FlxG.keys.justPressed.ESCAPE || virtualPad.buttonB.justPressed)
		{
			FlxG.mouse.visible = false;
			if (!_goToPlayState)
			{
				MusicBeatState.switchState(new developer.editors.MasterEditorMenu());
				FlxG.sound.playMusic(Paths.music('freakyMenu'));
			}
			else
				MusicBeatState.switchState(new PlayState());
			return;
		}
	}

	final assetFolder = 'week1'; // load from assets/week1/

	inline function loadBG()
	{
		var lastLoaded = Paths.currentLevel;
		Paths.currentLevel = assetFolder;

		/////////////
		// bg data //
		/////////////
		var bg:BGSprite = new BGSprite('stageback', -600, -200, 0.9, 0.9);
		add(bg);

		var stageFront:BGSprite = new BGSprite('stagefront', -650, 600, 0.9, 0.9);
		stageFront.setGraphicSize(Std.int(stageFront.width * 1.1));
		stageFront.updateHitbox();
		add(stageFront);

		dadPosition.set(100, 100);
		bfPosition.set(770, 100);
		/////////////

		Paths.currentLevel = lastLoaded;
	}

	inline function updatePointerPos(?snap:Bool = true)
	{
		var offX:Float = 0;
		var offY:Float = 0;
		if (!character.isPlayer)
		{
			offX = character.getMidpoint().x + 150 + character.cameraPosition[0];
			offY = character.getMidpoint().y - 100 + character.cameraPosition[1];
		}
		else
		{
			offX = character.getMidpoint().x - 100 - character.cameraPosition[0];
			offY = character.getMidpoint().y - 100 + character.cameraPosition[1];
		}
		cameraFollowPointer.setPosition(offX, offY);

		if (snap)
		{
			FlxG.camera.scroll.x = cameraFollowPointer.getMidpoint().x - FlxG.width / 2;
			FlxG.camera.scroll.y = cameraFollowPointer.getMidpoint().y - FlxG.height / 2;
		}
	}

	inline function updateHealthBar()
	{
		healthColorStepperR.value = character.healthColorArray[0];
		healthColorStepperG.value = character.healthColorArray[1];
		healthColorStepperB.value = character.healthColorArray[2];
		healthBar.leftBar.color = healthBar.rightBar.color = FlxColor.fromRGB(character.healthColorArray[0], character.healthColorArray[1],
			character.healthColorArray[2]);
		healthIcon.changeIcon(character.healthIcon, false);
		updatePresence();
	}

	inline function updatePresence()
	{
		#if DISCORD_ALLOWED
		// Updating Discord Rich Presence
		DiscordClient.changePresence("Character Editor", "Character: " + _char, healthIcon.getCharacter());
		#end
	}

	inline function reloadAnimList()
	{
		anims = character.animationsArray;
		if (anims.length > 0)
			character.playAnim(anims[0].anim, true);
		curAnim = 0;
		animListScroll = 0;

		updateAnimList();
		if (animationDropDown != null)
			reloadAnimationDropDown();
	}

	inline function updateTextColors()
	{
		// 颜色/高亮已由 updateAnimList 统一处理
		updateAnimList();
	}

	inline function updateCharacterPositions()
	{
		if ((character != null && !character.isPlayer) || (character == null && predictCharacterIsNotPlayer(_char)))
			character.setPosition(dadPosition.x, dadPosition.y);
		else
			character.setPosition(bfPosition.x, bfPosition.y);

		character.x += character.positionArray[0];
		character.y += character.positionArray[1];
	}

	inline function predictCharacterIsNotPlayer(name:String)
	{
		return (name != 'bf' && !name.startsWith('bf-') && !name.endsWith('-player') && !name.endsWith('-dead'))
			|| name.endsWith('-opponent')
			|| name.startsWith('gf-')
			|| name.endsWith('-gf')
			|| name == 'gf';
	}

	function addAnimation(anim:String, name:String, fps:Float, loop:Bool, indices:Array<Int>)
	{
		if (!character.isAnimateAtlas)
		{
			if (indices != null && indices.length > 0)
				character.animation.addByIndices(anim, name, indices, "", fps, loop);
			else
				character.animation.addByPrefix(anim, name, fps, loop);
		}
		#if flxanimate
		else
		{
			if (indices != null && indices.length > 0)
				character.atlas.anim.addBySymbolIndices(anim, name, indices, fps, loop);
			else
				character.atlas.anim.addBySymbol(anim, name, fps, loop);
		}
		#end

		if (!character.animOffsets.exists(anim))
			character.addOffset(anim, 0, 0);
	}

	inline function newAnim(anim:String, name:String):AnimArray
	{
		return {
			offsets: [0, 0],
			loop: false,
			fps: 24,
			anim: anim,
			indices: [],
			name: name
		};
	}

	var characterList:Array<String> = [];

	function reloadCharacterDropDown()
	{
		characterList = Mods.mergeAllTextsNamed('data/characterList.txt', Paths.getSharedPath());
		#if MODS_ALLOWED
		var foldersToCheck:Array<String> = Mods.directoriesWithFile(Paths.getSharedPath(), 'characters/');
		for (folder in foldersToCheck)
			for (file in FileSystem.readDirectory(folder))
				if (file.toLowerCase().endsWith('.json'))
				{
					var charToCheck:String = file.substr(0, file.length - 5);
					if (!characterList.contains(charToCheck))
						characterList.push(charToCheck);
				}
		#end
		if (characterList.length < 1)
			characterList.push('');
		charDropDown.setData(FlxUIDropDownMenu.makeStrIdLabelArray(characterList, true));
		charDropDown.selectedLabel = _char;
	}

	function reloadAnimationDropDown()
	{
		var animList:Array<String> = [];
		for (anim in anims)
			animList.push(anim.anim);
		if (animList.length < 1)
			animList.push('NO ANIMATIONS'); // Prevents crash

		animationDropDown.setData(FlxUIDropDownMenu.makeStrIdLabelArray(animList, true));
	}

	// save
	var _file:FileReference;

	function onSaveComplete(_):Void
	{
		if (_file == null)
			return;
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
		FlxG.log.notice("Successfully saved file.");
	}

	/**
	 * Called when the save file dialog is cancelled.
	 */
	function onSaveCancel(_):Void
	{
		if (_file == null)
			return;
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
	}

	/**
	 * Called if there is an error while saving the gameplay recording.
	 */
	function onSaveError(_):Void
	{
		if (_file == null)
			return;
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
		FlxG.log.error("Problem saving file");
	}

	function saveCharacter()
	{
		if (_file != null)
			return;

		var json:Dynamic = {
			"animations": character.animationsArray,
			"image": character.imageFile,
			"scale": character.jsonScale,
			"sing_duration": character.singDuration,
			"healthicon": character.healthIcon,

			"position": character.positionArray,
			"camera_position": character.cameraPosition,

			"flip_x": character.originalFlipX,
			"no_antialiasing": character.noAntialiasing,
			"healthbar_colors": character.healthColorArray,
			"vocals_file": character.vocalsFile,
			"_editor_isPlayer": character.isPlayer
		};

		var data:String = haxe.Json.stringify(json, "\t");

		if (data.length > 0)
		{
			#if mobile
			SUtil.saveContent('$_char', ".json", data);
			#else
			_file = new FileReference();
			_file.addEventListener(#if desktop Event.SELECT #else Event.COMPLETE #end, onSaveComplete);
			_file.addEventListener(Event.CANCEL, onSaveCancel);
			_file.addEventListener(IOErrorEvent.IO_ERROR, onSaveError);
			_file.save(data, '$_char.json');
			#end
		}
	}
}

