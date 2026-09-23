package developer.editors;

import flash.net.FileFilter;

import openfl.display.Sprite;
import openfl.net.FileReference;
import openfl.net.FileReferenceList;
import openfl.events.Event;
import openfl.events.IOErrorEvent;

import flixel.FlxBasic;
import flixel.FlxObject;
import flixel.addons.display.FlxBackdrop;
import flixel.addons.display.FlxGridOverlay;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxRect;
import flixel.util.FlxAxes;

import flixel.addons.ui.FlxUICheckBox;
import flixel.addons.ui.FlxUIDropDownMenu;
import flixel.addons.ui.FlxUIInputText;
import flixel.addons.ui.FlxUINumericStepper;

import flixel.graphics.frames.FlxAtlasFrames;
import openfl.display.BitmapData;

import general.backend.PsychCamera;
import general.backend.ui.PsychUIEventHandler;
import general.backend.language.Language;

import mobile.flixel.FlxButton as MobileButton;

// 引入模块级 typedef（StageMenuItemDef / StageMenuDef）
import developer.editors.StageEditorMenuBar;

import scripts.lua.LuaUtils;
import scripts.lua.ModchartSprite;

import games.PlayState;
import games.objects.Character;
import games.objects.Note;
import games.backend.Song;
import games.backend.StageData;
import games.stages.base.BaseStage;

import substates.GameOverSubstate;

#if sys
import sys.io.File;
#end

class StageEditorState extends MusicBeatState implements PsychUIEventHandler.PsychUIEvent
{
	final minZoom = 0.1;
	final maxZoom = 2;

	var gf:Character;
	var dad:Character;
	var boyfriend:Character;
	var stageJson:StageFile;

	#if FLX_DEBUG
	var camGame:FlxCamera;
	#else
	var camGame:DebugCamera;
	#end

	public var camHUD:FlxCamera;

	var UI_stagebox:PsychUIBox;
	var UI_box:PsychUIBox;
	var spriteList_box:PsychUIBox;
	var stageSprites:Array<StageEditorMetaSprite> = [];

	public function new(stageToLoad:String = 'stage', cachedJson:StageFile = null)
	{
		lastLoadedStage = stageToLoad;
		stageJson = cachedJson;
		super();
	}

	var lastLoadedStage:String;
	var camFollow:FlxObject = new FlxObject(0, 0, 1, 1);
	// 进入编辑器前的 Paths.currentLevel / StageData.forceNextDirectory / Mods.currentModDirectory（destroy 时恢复，防止污染游戏）
	var _savedCurrentLevel:String;
	var _savedForceNextDir:String;
	var _savedModDir:String;

	var helpBg:FlxSprite;
	var helpTexts:FlxSpriteGroup;
	var tutorialBg:FlxSprite;
	var tutorialTexts:FlxSpriteGroup;
	var posTxt:FlxText;
	var errorTxt:FlxText;

	var animationEditor:StageEditorAnimationSubstate;
	var unsavedProgress:Bool = false;

	// ===== 旧 PsychUI 控件引用（旧 UI 全程不可见，但保留功能，由新 UI 菜单驱动）=====
	var buttonMoveUp:PsychUIButton;
	var buttonMoveDown:PsychUIButton;
	var buttonCreate:PsychUIButton;
	var buttonDuplicate:PsychUIButton;
	var buttonDelete:PsychUIButton;
	var buttonAnimations:PsychUIButton;
	var popupNoAnimBtn:PsychUIButton;
	var popupAnimBtn:PsychUIButton;
	var popupSquareBtn:PsychUIButton;
	var globalLowQualityCheckbox:PsychUICheckBox;
	var globalHighQualityCheckbox:PsychUICheckBox;
	var bottomBarBg:FlxSprite;
	var tipText:FlxText;
	var targetTxt:FlxText;
	var visibilityFilterUpdate:Void->Void;
	// ===== 剪贴板 / 撤销（桌面快捷键 Ctrl+C/X/V/Z、Delete）=====
	var clipboardMeta:StageEditorMetaSprite; // 剪贴板内容（深拷贝元数据）
	var undoStack:Array<String> = []; // stageJson 快照（JSON 字符串），修改操作前入栈
	static final UNDO_LIMIT:Int = 50;

	// ===== BaseStage 兼容成员（供 games.stages.* 舞台类在本编辑器中渲染背景）=====
	public var paused:Bool = false;
	public var songName:String = 'stage';
	public var defaultCamZoom:Float = 0.9;
	public var boyfriendGroup:FlxSpriteGroup;
	public var gfGroup:FlxSpriteGroup;
	public var dadGroup:FlxSpriteGroup;
	public var unspawnNotes:Array<Note> = [];
	public var camOther:FlxCamera;
	var _songWasNull:Bool = false;
	// Stage 类创建并 add 到 state 的背景精灵，用于切换舞台时清理重建
	var stageBgMembers:Array<FlxBasic> = [];
	// 延迟销毁队列：精灵先离开渲染循环，下一帧 update 的安全点再真正 destroy，
	// 避免"已销毁的精灵还在渲染队列里"导致的崩溃
	var _pendingDestroy:Array<FlxBasic> = [];
	var _diagFrames:Int = 0;
	// 分步加载：Stage 精灵创建后先隐藏，每帧预上传几个纹理（getTexture），
	// 全部就绪后再显示，避免渲染管线中同步上传大纹理导致崩溃
	var _pendingUpload:Array<FlxSprite> = [];
	var _uploadingStage:Bool = false;
	var _uploadTotal:Int = 0;
	var _loadingBg:FlxSprite;
	var _loadingText:FlxText;
	// 帧阶段诊断：环形标记 update/draw 各阶段，定期写文件，崩溃时定位阶段
	var _diagBuf:String = '';
	var _diagBufCount:Int = 0;

	// ===== 新 UI：顶栏菜单 + 状态栏 =====
	var menuBar:StageEditorMenuBar;
	#if (cpp && windows)
	var windowChrome:EditorChromeUI;
	var modInfoPopup:general.objects.ModInfoPopup;
	#end
	var overlayLayer:FlxSpriteGroup;
	// FlxUI 原生控件（只作数据源，显示由 menuBar 自绘接管）
	var uiStageDropDown:FlxUIDropDownMenu;
	var uiDirectoryInput:FlxUIDropDownMenu;
	var uiHideGfCheck:FlxUICheckBox;
	var uiDefaultZoomStepper:FlxUINumericStepper;
	var uiCamSpeedStepper:FlxUINumericStepper;
	var uiCamZoomStepper:FlxUINumericStepper;
	var uiCamTargetDropDown:FlxUIDropDownMenu;
	var uiCamBfX:FlxUINumericStepper;
	var uiCamBfY:FlxUINumericStepper;
	var uiCamDadX:FlxUINumericStepper;
	var uiCamDadY:FlxUINumericStepper;
	var uiCamGfX:FlxUINumericStepper;
	var uiCamGfY:FlxUINumericStepper;
	var uiLowQualityCheck:FlxUICheckBox;
	var uiHighQualityCheck:FlxUICheckBox;
	// 对象菜单右侧的角色显示/隐藏勾选
	var uiShowBfCheck:FlxUICheckBox;
	var uiShowDadCheck:FlxUICheckBox;
	var uiShowGfCheck:FlxUICheckBox;
	// 舞台切换状态机：0=空闲, 1=分步销毁旧舞台, 2=分步加载新舞台
	var _transitionState:Int = 0;
	var _transitionStage:String = '';
	var _transitionJson:StageFile = null;
	var _clearingQueue:Array<FlxBasic> = [];
	var _clearingTotal:Int = 0;
	var _clearedCount:Int = 0;
	// 每帧处理量（销毁/上传），稳定优先
	static final TRANSITION_PER_FRAME:Int = 2;

	override function create()
	{
		// 强制刷新语言数据，确保 stage 分组被加载
		Language.resetData();
		try
		{
			stageLog('语言检查: menu_stage="' + Language.get('menu_stage', 'stage') + '" help_camera="' + Language.get('help_camera', 'stage') + '"');
		}
		catch (e:Dynamic) {}

		Paths.clearStoredMemory();
		Paths.clearUnusedMemory();

		#if FLX_DEBUG
		camGame = initPsychCamera();
		#else
		camGame = new DebugCamera();
		FlxG.cameras.reset(camGame);
		FlxG.cameras.setDefaultDrawTarget(camGame, true);
		_psychCameraInitialized = true;
		#end

		camHUD = new FlxCamera();
		camHUD.bgColor.alpha = 0;
		FlxG.cameras.add(camHUD, false);

		if (stageJson == null)
			stageJson = StageData.getStageFile(lastLoadedStage);
		FlxG.camera.follow(null, LOCKON, 0);

		// 保存全局 currentLevel（编辑器会改成 week1/week4…），退出时恢复，
		// 防止泄漏到游戏：PlayState 从不设置 currentLevel，残留值会导致
		// 游戏里图片按错误的周目录解析（mod 舞台/游戏资源加载异常）
		_savedCurrentLevel = Paths.currentLevel;
		// 同样保存 StageData.forceNextDirectory（LoadingState 会消费它决定 currentLevel）
		_savedForceNextDir = StageData.forceNextDirectory;
		// 以及 Mods.currentModDirectory（mod 图片查找的关键，防止编辑器会话改变它）
		_savedModDir = Mods.currentModDirectory;
		loadJsonAssetDirectory();
		// 导入素材临时目录（按舞台名隔离，保存时随 JSON 输出到 saves/stage/<名字>/）
		StageEditorMetaSprite.tempImageDir = Sys.getCwd().replace('\\', '/') + 'temp/stage_editor/' + lastLoadedStage + '/images/';
		gf = new Character(0, 0, stageJson._editorMeta != null ? stageJson._editorMeta.gf : 'gf');
		gf.visible = !(stageJson.hide_girlfriend);
		gf.scrollFactor.set(0.95, 0.95);
		dad = new Character(0, 0, stageJson._editorMeta != null ? stageJson._editorMeta.dad : 'dad');
		boyfriend = new Character(0, 0, stageJson._editorMeta != null ? stageJson._editorMeta.boyfriend : 'bf', true);

		// 角色占位组：兼容 BaseStage 的 addBehindGF / addBehindBF / addBehindDad 层级插入
		gfGroup = new FlxSpriteGroup();
		dadGroup = new FlxSpriteGroup();
		boyfriendGroup = new FlxSpriteGroup();
		add(gfGroup);
		add(dadGroup);
		add(boyfriendGroup);

		camOther = new FlxCamera();
		camOther.bgColor.alpha = 0;
		FlxG.cameras.add(camOther, false);

		FlxG.camera.zoom = stageJson.defaultZoom;
		defaultCamZoom = stageJson.defaultZoom;
		loadStageBackgrounds();
		repositionGirlfriend();
		repositionDad();
		repositionBoyfriend();
		var point = focusOnTarget('boyfriend');
		FlxG.camera.scroll.set(point.x - FlxG.width / 2, point.y - FlxG.height / 2);

		screenUI();
		spriteCreatePopup();
		editorUI();
		hideOldUI();

		// 舞台分步加载指示条
		_loadingBg = new FlxSprite().makeGraphic(FlxG.width, 32, 0xCC000000);
		_loadingBg.scrollFactor.set();
		_loadingBg.cameras = [camHUD];
		_loadingBg.screenCenter();
		_loadingBg.visible = false;
		add(_loadingBg);

		_loadingText = new FlxText(0, 0, FlxG.width, '', 16);
		_loadingText.setFormat(Paths.font(Language.get('fontName', 'main') + '.ttf'), 16, FlxColor.WHITE, CENTER);
		_loadingText.scrollFactor.set();
		_loadingText.cameras = [camHUD];
		_loadingText.screenCenter();
		_loadingText.visible = false;
		add(_loadingText);

		// ===== 新 UI：顶栏菜单 + 状态栏（与制谱器/角色编辑器同款）=====
		overlayLayer = new FlxSpriteGroup();
		overlayLayer.cameras = [camHUD];
		overlayLayer.scrollFactor.set();
		add(overlayLayer);

		buildMenuBarWidgets();

		menuBar = new StageEditorMenuBar();
		menuBar.scrollFactor.set();
		menuBar.uiCamera = camHUD;
		menuBar.cameras = [camHUD];
		menuBar.onAction = onMenuAction;
		menuBar.onMenuOpened = onMenuOpened;
		menuBar.registerWidget('w_stage_select', uiStageDropDown);
		menuBar.registerWidget('w_directory', uiDirectoryInput);
		menuBar.registerWidget('w_hide_gf', uiHideGfCheck);
		menuBar.registerWidget('w_default_zoom', uiDefaultZoomStepper);
		menuBar.registerWidget('w_cam_speed', uiCamSpeedStepper);
		menuBar.registerWidget('w_cam_zoom', uiCamZoomStepper);
		menuBar.registerWidget('w_cam_target', uiCamTargetDropDown);
		menuBar.registerWidget('w_cam_bf_x', uiCamBfX);
		menuBar.registerWidget('w_cam_bf_y', uiCamBfY);
		menuBar.registerWidget('w_cam_dad_x', uiCamDadX);
		menuBar.registerWidget('w_cam_dad_y', uiCamDadY);
		menuBar.registerWidget('w_cam_gf_x', uiCamGfX);
		menuBar.registerWidget('w_cam_gf_y', uiCamGfY);
		menuBar.registerWidget('w_low_quality', uiLowQualityCheck);
		menuBar.registerWidget('w_high_quality', uiHighQualityCheck);
		menuBar.registerWidget('w_show_bf', uiShowBfCheck);
		menuBar.registerWidget('w_show_dad', uiShowDadCheck);
		menuBar.registerWidget('w_show_gf', uiShowGfCheck);
		menuBar.registerDynText('obj_name', () -> getSelectedObjName());
		menuBar.registerDynText('obj_type', () -> getSelectedObjType());
		menuBar.registerDynText('obj_image', () -> getSelectedObjImage());
		menuBar.registerDynText('obj_pos', () -> getSelectedObjPos());
		menuBar.registerDynText('obj_scale', () -> getSelectedObjScale());
		menuBar.registerDynText('obj_alpha', () -> getSelectedObjAlpha());
		menuBar.registerDynText('obj_angle', () -> getSelectedObjAngle());

		// 对象菜单动态列表：每次打开现场生成（与旧 Sprite List 同序：列表顶部=渲染最上层）
		menuBar.dynamicMenuKey = 'object';
		menuBar.dynamicItems = function():Array<StageMenuItemDef>
		{
			var rows:Array<StageMenuItemDef> = [];
			var labelsLen:Int = spriteListRadioGroup.labels.length;
			for (i in 0...stageSprites.length)
			{
				var spr = stageSprites[i];
				if (spr == null)
					continue;
				var displayName:String = switch (spr.type)
				{
					case 'gf': '- Girlfriend -';
					case 'boyfriend': '- Boyfriend -';
					case 'dad': '- Opponent -';
					default: spr.name;
				}
				var radioIdx:Int = labelsLen - 1 - i;
				rows.push({
					type: RawCmd,
					labelKey: 'obj_list',
					descKey: 'desc_obj_list_item',
					rawText: displayName,
					getChecked: function() return spriteListRadioGroup.checked == radioIdx,
					onCheck: null,
					onClick: function()
					{
						if (radioIdx >= 0 && radioIdx < labelsLen)
						{
							spriteListRadioGroup.checked = radioIdx;
							checkUIOnObject();
							updateSelectedUI();
							if (menuBar != null)
								menuBar.refreshDynTexts();
						}
					},
					widgetKey: null
				});
			}
			return rows;
		};
		add(menuBar);
		menuBar.overlayLayer = overlayLayer;
		// ★ 菜单栏独立驱动 update：StageEditorState.update 有提前 return 路径
		//   （如 PsychUIInputText.focusOn != null），会跳过 super.update → menuBar 不响应点击。
		//   这里禁用它自身的 state 更新，改由 update() 开头手动调用。
		menuBar.active = false;
		hideMenuBarWidgets();

		add(camFollow);
		updateSpriteList();

		addHelpScreen();
		addTutorialScreen();
		FlxG.mouse.visible = true;
		destroySubStates = false;
		animationEditor = new StageEditorAnimationSubstate();

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
		// 顶栏左侧「退出 舞台编辑器」按钮
		windowChrome.setupExitButton('stageEditor', doExitEditor);
		#end

		super.create();
	}

	function loadJsonAssetDirectory()
	{
		var directory:String = 'shared';
		var weekDir:String = stageJson.directory;
		if (weekDir != null && weekDir.length > 0 && weekDir != '')
			directory = weekDir;

		Paths.setCurrentLevel(directory);
		trace('Setting asset folder to ' + directory);
	}

	/**
	 * 原版舞台（stage/spooky/philly/limo 等）的背景精灵是写在 Stage 类代码里的，
	 * 不在 stage JSON 的 objects 数组里，而 StageEditor 不运行 lua / 不执行 Stage 类，
	 * 所以背景一直显示不出来。这里直接实例化对应的 Stage 类，让背景在编辑器中可见（方便调试）。
	 * - 不调用 stage.update()/beatHit() 等运行时逻辑，只显示静态背景
	 * - 实例化失败只记录日志，不影响编辑器其余功能
	 * - Stage 类创建的精灵会移动到 members 最底层，避免盖住角色和 UI
	 */
	/** 舞台加载诊断日志（logs/stage_editor.log），用于排查舞台加载/崩溃问题。 */
	function stageLog(msg:String):Void
	{
		trace('StageEditor: ' + msg);
		#if sys
		try
		{
			if (!FileSystem.exists('logs'))
				FileSystem.createDirectory('logs');
			var f = File.append('logs/stage_editor.log', false);
			f.writeString(Date.now().toString() + ' ' + msg + '\n');
			f.close();
		}
		catch (e:Dynamic) {}
		#end
	}

	/**
	 * 原版舞台（stage/spooky/philly/limo 等）的背景精灵是写在 Stage 类代码里的，
	 * 不在 stage JSON 的 objects 数组里，而 StageEditor 不运行 lua / 不执行 Stage 类，
	 * 所以背景一直显示不出来。这里直接实例化对应的 Stage 类，让背景在编辑器中可见（方便调试）。
	 * - 不调用 stage.update()/beatHit() 等运行时逻辑，只显示静态背景
	 * - 实例化失败只记录日志，不影响编辑器其余功能
	 * - Stage 类创建的精灵会移动到 members 最底层，避免盖住角色和 UI
	 * - 会保存/恢复 Stage 类修改的全局状态（PlayState.SONG、GameOverSubstate），
	 *   避免退出编辑器后污染游戏（如 "pico miss" 死亡画面）
	 */
	function loadStageBackgrounds():Void
	{
		// 确保 currentLevel 与当前舞台的 directory 同步（stage→week1、limo→week4…），
		// 否则 Paths.image 会在错误的周目录里找图，全部变成 haxe logo
		loadJsonAssetDirectory();

		// 保存 Stage 类会修改的全局状态，加载完恢复
		var savedSong:SwagSong = PlayState.SONG;
		var savedGfVersion:Dynamic = (savedSong != null ? savedSong.gfVersion : null);
		var savedChar:String = GameOverSubstate.characterName;
		var savedDeath:String = GameOverSubstate.deathSoundName;
		var savedLoop:String = GameOverSubstate.loopSoundName;
		var savedEnd:String = GameOverSubstate.endSoundName;
		var savedStoryMode:Bool = PlayState.isStoryMode;
		var savedMusic:flixel.sound.FlxSound = FlxG.sound.music;

		// 强制非故事模式：防止 School/SchoolEvil 触发 cutscene 分支（initDoof 对话盒/半透明立绘/开场音效）
		PlayState.isStoryMode = false;

		if (PlayState.SONG == null)
		{
			_songWasNull = true;
			PlayState.SONG = cast {song: 'test', gfVersion: '', notes: [{mustHitSection: true}]};
		}

		var startLen:Int = members.length;
		stageLog('加载舞台背景: ' + lastLoadedStage + ' (directory=' + stageJson.directory + ')');

		try
		{
			switch (lastLoadedStage)
			{
				case 'stage':
					try { new games.stages.StageWeek1(); } catch (e:Dynamic) stageLog('StageWeek1 失败: ' + e);
				case 'spooky':
					try { new games.stages.Spooky(); } catch (e:Dynamic) stageLog('Spooky 失败: ' + e);
				case 'philly':
					try { new games.stages.Philly(); } catch (e:Dynamic) stageLog('Philly 失败: ' + e);
				case 'limo':
					try { new games.stages.Limo(); } catch (e:Dynamic) stageLog('Limo 失败: ' + e);
				case 'mall':
					try { new games.stages.Mall(); } catch (e:Dynamic) stageLog('Mall 失败: ' + e);
				case 'mallEvil':
					try { new games.stages.MallEvil(); } catch (e:Dynamic) stageLog('MallEvil 失败: ' + e);
				case 'school':
					try { new games.stages.School(); } catch (e:Dynamic) stageLog('School 失败: ' + e);
				case 'schoolEvil':
					try { new games.stages.SchoolEvil(); } catch (e:Dynamic) stageLog('SchoolEvil 失败: ' + e);
				case 'tank':
					try { new games.stages.Tank(); } catch (e:Dynamic) stageLog('Tank 失败: ' + e);
				case 'phillyStreets':
					try { new games.stages.PhillyStreets(); } catch (e:Dynamic) stageLog('PhillyStreets 失败: ' + e);
				case 'phillyBlazin':
					try { new games.stages.PhillyBlazin(); } catch (e:Dynamic) stageLog('PhillyBlazin 失败: ' + e);
				default:
					// 无 Stage 类的舞台：尝试解析同目录 .lua 里的背景创建（纯 lua 舞台）
					loadLuaStageBackgrounds();
					if (stageJson.specifyClass != null && stageJson.specifyClass.length > 0)
					{
						var cls:Class<Dynamic> = Type.resolveClass(stageJson.specifyClass);
						if (cls != null)
							Type.createInstance(cls, []);
					}
			}

			// createPost（Limo 的 fastCar/limoDrive、Tank 的前景等在这里创建）
			for (st in stages)
			{
				try
				{
					st.createPost();
				}
				catch (e:Dynamic)
					stageLog('createPost 失败: ' + e);
			}
		}
		catch (e:Dynamic)
		{
			stageLog('舞台类加载异常: ' + e);
			// 回滚已添加的成员，避免半加载状态
			while (members.length > startLen)
				remove(members[members.length - 1], true);
			stages = [];
			stageBgMembers = [];
		}

		// 恢复全局状态，避免污染游戏（setDefaultGF 改 SONG.gfVersion、Stage create 改 GameOverSubstate 等）
		PlayState.SONG = savedSong;
		if (savedSong != null)
			savedSong.gfVersion = savedGfVersion;
		GameOverSubstate.characterName = savedChar;
		GameOverSubstate.deathSoundName = savedDeath;
		GameOverSubstate.loopSoundName = savedLoop;
		GameOverSubstate.endSoundName = savedEnd;
		PlayState.isStoryMode = savedStoryMode;

		// 恢复音乐：SchoolEvil 等 Stage 会无条件 playMusic 换掉当前音乐（"冤魂附体"），
		// 停掉它播放的新音乐并还原之前的音乐
		if (FlxG.sound.music != savedMusic)
		{
			var stageMusic:flixel.sound.FlxSound = FlxG.sound.music;
			FlxG.sound.music = savedMusic;
			if (stageMusic != null)
				stageMusic.stop();
		}

		// 清理相机滤镜（PhillyStreets/PhillyBlazin 的 rainShader 会挂到相机上并污染后续画面）
		FlxG.camera.setFilters(null);

		// 防 NaN：某些 Stage 类（如 MallEvil 的 focusOn/zoom 操作）可能把相机状态搞坏，
		// NaN 会导致渲染数学异常崩溃
		if (FlxG.camera.zoom != FlxG.camera.zoom || FlxG.camera.scroll.x != FlxG.camera.scroll.x
			|| FlxG.camera.scroll.y != FlxG.camera.scroll.y)
		{
			stageLog('相机状态异常（NaN），重置为舞台默认值');
			FlxG.camera.zoom = stageJson.defaultZoom;
			FlxG.camera.scroll.set(0, 0);
		}

		// 把 Stage 类添加的背景精灵移到最底层，避免盖住角色和 UI（角色由 draw() 手动画在最上层）
		var added:Array<FlxBasic> = members.slice(startLen);
		stageBgMembers = added.copy();
		for (i in 0...added.length)
		{
			remove(added[i], true);
			insert(i, added[i]);
		}

		// 清空 stages，避免 MusicBeatState.update 每帧调用 stage.update()
		// （Tank/Limo 等的 update 依赖 PlayState 运行环境，在编辑器里会崩）。
		// 精灵已经 add 到 state，背景显示不受影响。
		stages = [];

		// 分步加载：收集所有新精灵，暂时隐藏，逐帧预上传纹理后再显示
		_pendingUpload = [];
		for (m in stageBgMembers)
		{
			m.visible = false;
			collectSprites(m, _pendingUpload);
		}
		_uploadTotal = _pendingUpload.length;
		_uploadingStage = _uploadTotal > 0;
		if (_uploadingStage && _loadingText != null)
		{
			_loadingText.text = 'Loading stage... 0/' + _uploadTotal;
			_loadingText.visible = true;
			_loadingBg.visible = true;
		}
		stageLog('舞台背景加载完成: ' + lastLoadedStage + ' (精灵数=' + stageBgMembers.length + ', 待上传纹理=' + _uploadTotal + ')');
	}

	/** 递归收集精灵（FlxTypedGroup 的成员也要处理）。 */
	function collectSprites(m:FlxBasic, out:Array<FlxSprite>):Void
	{
		if (Std.isOfType(m, FlxTypedGroup))
		{
			var grp:FlxTypedGroup<Dynamic> = cast m;
			for (member in grp.members)
				if (member != null)
					collectSprites(member, out);
		}
		else if (Std.isOfType(m, FlxSprite))
		{
			var spr:FlxSprite = cast m;
			if (spr.graphic != null)
				out.push(spr);
		}
	}

	/**
	 * 解析 stages/<舞台名>.lua 里的背景创建调用（StageEditor 不运行 lua，
	 * 用静态解析模拟常见的背景创建写法），让纯 lua 驱动的背景也能在编辑器中显示。
	 * 支持：makeLuaSprite / makeAnimatedLuaSprite / makeGraphic / addLuaSprite /
	 * scaleObject / setScrollFactor / setLuaSpriteScrollFactor / setBlendMode /
	 * setProperty('x.alpha|flipX|flipY|angle', v) / setPropertyLuaSprite /
	 * addAnimationByPrefix / objectPlayAnimation / screenCenter。
	 * 注释行（--）会被跳过，因此已把背景移入 JSON objects 的舞台不会重复显示。
	 */
	function loadLuaStageBackgrounds():Void
	{
		var luaPath:String = 'stages/$lastLoadedStage.lua';
		var path:String = Paths.getPath(luaPath, TEXT, null, true);
		var lines:Array<String> = null;
		#if MODS_ALLOWED
		if (!FileSystem.exists(path))
			return;
		lines = File.getContent(path).split('\n');
		#else
		if (!Assets.exists(path, TEXT))
			return;
		lines = Assets.getText(path).split('\n');
		#end

		var sprites:Map<String, {
			img:String,
			x:Float,
			y:Float,
			scaleX:Float,
			scaleY:Float,
			alpha:Float,
			blend:String,
			animated:Bool,
			scrollX:Float,
			scrollY:Float,
			flipX:Bool,
			flipY:Bool,
			angle:Float,
			gfxW:Int,
			gfxH:Int,
			gfxColor:String,
			center:Bool,
			anims:Array<{name:String, prefix:String, fps:Int, loop:Bool}>,
			playAnim:String
		}> = [];
		var addOrder:Array<String> = [];
		var added:Map<String, Bool> = [];

		for (raw in lines)
		{
			// 去掉行内注释（lua 的 -- 注释）
			var line:String = raw.split('--')[0];
			line = StringTools.trim(line);
			if (line.length == 0)
				continue;

			// makeLuaSprite('name','image',x,y) / makeAnimatedLuaSprite(...)
			var makeRe = ~/(makeLuaSprite|makeAnimatedLuaSprite)\s*\(\s*['"]([^'"]+)['"]\s*,\s*['"]([^'"]*)['"]\s*,\s*(-?[0-9.]+)\s*,\s*(-?[0-9.]+)\s*\)/;
			if (makeRe.match(line))
			{
				var n:String = makeRe.matched(2);
				if (!sprites.exists(n))
				{
					sprites.set(n, {
						img: makeRe.matched(3),
						x: Std.parseFloat(makeRe.matched(4)),
						y: Std.parseFloat(makeRe.matched(5)),
						scaleX: 1,
						scaleY: 1,
						alpha: 1,
						blend: '',
						animated: makeRe.matched(1) == 'makeAnimatedLuaSprite',
						scrollX: 1,
						scrollY: 1,
						flipX: false,
						flipY: false,
						angle: 0,
						gfxW: 0,
						gfxH: 0,
						gfxColor: 'FFFFFF',
						center: false,
						anims: [],
						playAnim: null
					});
				}
				continue;
			}
			// addLuaSprite('name', front) / addLuaSprite('name')
			var addRe = ~/addLuaSprite\s*\(\s*['"]([^'"]+)['"]\s*(?:,\s*(?:true|false)\s*)?\)/;
			if (addRe.match(line))
			{
				var n:String = addRe.matched(1);
				if (!added.exists(n))
				{
					added.set(n, true);
					addOrder.push(n);
				}
				continue;
			}
			// scaleObject('name', sx, sy)
			var scaleRe = ~/scaleObject\s*\(\s*['"]([^'"]+)['"]\s*,\s*(-?[0-9.]+)\s*,\s*(-?[0-9.]+)\s*\)/;
			if (scaleRe.match(line))
			{
				var s = sprites.get(scaleRe.matched(1));
				if (s != null)
				{
					s.scaleX = Std.parseFloat(scaleRe.matched(2));
					s.scaleY = Std.parseFloat(scaleRe.matched(3));
				}
				continue;
			}
			// setScrollFactor('name', sx, sy) / setLuaSpriteScrollFactor
			var scrollRe = ~/(setScrollFactor|setLuaSpriteScrollFactor)\s*\(\s*['"]([^'"]+)['"]\s*,\s*(-?[0-9.]+)\s*,\s*(-?[0-9.]+)\s*\)/;
			if (scrollRe.match(line))
			{
				var s = sprites.get(scrollRe.matched(2));
				if (s != null)
				{
					s.scrollX = Std.parseFloat(scrollRe.matched(3));
					s.scrollY = Std.parseFloat(scrollRe.matched(4));
				}
				continue;
			}
			// setBlendMode('name','add'|'multiply'|'subtract'|...)
			var blendRe = ~/setBlendMode\s*\(\s*['"]([^'"]+)['"]\s*,\s*['"](\w+)['"]\s*\)/;
			if (blendRe.match(line))
			{
				var s = sprites.get(blendRe.matched(1));
				if (s != null)
					s.blend = blendRe.matched(2).toLowerCase();
				continue;
			}
			// makeGraphic('name', w, h, 'color')
			var gfxRe = ~/makeGraphic\s*\(\s*['"]([^'"]+)['"]\s*,\s*(\d+)\s*,\s*(\d+)\s*,\s*['"]([^'"]+)['"]\s*\)/;
			if (gfxRe.match(line))
			{
				var s = sprites.get(gfxRe.matched(1));
				if (s != null)
				{
					s.gfxW = Std.parseInt(gfxRe.matched(2));
					s.gfxH = Std.parseInt(gfxRe.matched(3));
					s.gfxColor = gfxRe.matched(4);
				}
				continue;
			}
			// addAnimationByPrefix('name','anim','prefix',fps,loop)
			var animRe = ~/addAnimationByPrefix\s*\(\s*['"]([^'"]+)['"]\s*,\s*['"]([^'"]+)['"]\s*,\s*['"]([^'"]+)['"]\s*,\s*(\d+)\s*,\s*(true|false)\s*\)/;
			if (animRe.match(line))
			{
				var s = sprites.get(animRe.matched(1));
				if (s != null)
					s.anims.push({name: animRe.matched(2), prefix: animRe.matched(3), fps: Std.parseInt(animRe.matched(4)), loop: animRe.matched(5) == 'true'});
				continue;
			}
			// objectPlayAnimation('name','anim',force)
			var playRe = ~/objectPlayAnimation\s*\(\s*['"]([^'"]+)['"]\s*,\s*['"]([^'"]+)['"]/;
			if (playRe.match(line))
			{
				var s = sprites.get(playRe.matched(1));
				if (s != null)
					s.playAnim = playRe.matched(2);
				continue;
			}
			// setProperty('name.alpha|flipX|flipY', v) / setPropertyLuaSprite
			var propRe = ~/setProperty(?:LuaSprite)?\s*\(\s*['"]([^'"]+)\.(alpha|flipX|flipY|angle)['"]\s*,\s*(-?[0-9.]+|true|false)\s*\)/;
			if (propRe.match(line))
			{
				var s = sprites.get(propRe.matched(1));
				if (s != null)
				{
					switch (propRe.matched(2))
					{
						case 'alpha': s.alpha = Std.parseFloat(propRe.matched(3));
						case 'flipX': s.flipX = propRe.matched(3) == 'true';
						case 'flipY': s.flipY = propRe.matched(3) == 'true';
						case 'angle': s.angle = Std.parseFloat(propRe.matched(3));
					}
				}
				continue;
			}
			// screenCenter('name')
			var centerRe = ~/screenCenter\s*\(\s*['"]([^'"]+)['"]\s*\)/;
			if (centerRe.match(line))
			{
				var s = sprites.get(centerRe.matched(1));
				if (s != null)
					s.center = true;
				continue;
			}
		}

		// 按 add 顺序创建精灵（先 add 的在下层）
		var addedCount:Int = 0;
		for (name in addOrder)
		{
			var s = sprites.get(name);
			if (s == null)
				continue;
			var spr:ModchartSprite = new ModchartSprite(s.x, s.y);
			try
			{
				if (s.gfxW > 0)
				{
					spr.makeGraphic(s.gfxW, s.gfxH, CoolUtil.colorFromString(s.gfxColor));
				}
				else if (s.animated)
				{
					var atl = Paths.getSparrowAtlas(s.img);
					if (atl == null || atl.parent == null || atl.parent.bitmap == null)
						continue;
					spr.frames = atl;
					if (s.anims.length > 0)
					{
						for (a in s.anims)
							spr.animation.addByPrefix(a.name, a.prefix, a.fps, a.loop);
						var toPlay:String = (s.playAnim != null ? s.playAnim : s.anims[0].name);
						spr.animation.play(toPlay, true);
					}
				}
				else if (s.img.length > 0)
				{
					spr.loadGraphic(Paths.image(s.img));
				}
				else
					continue;
			}
			catch (e:Dynamic)
			{
				continue;
			}
			spr.scale.set(s.scaleX, s.scaleY);
			spr.updateHitbox();
			spr.alpha = s.alpha;
			spr.scrollFactor.set(s.scrollX, s.scrollY);
			spr.flipX = s.flipX;
			spr.flipY = s.flipY;
			spr.angle = s.angle;
			switch (s.blend)
			{
				case 'add': spr.blend = openfl.display.BlendMode.ADD;
				case 'multiply': spr.blend = openfl.display.BlendMode.MULTIPLY;
				case 'subtract': spr.blend = openfl.display.BlendMode.SUBTRACT;
			}
			if (s.center)
				spr.screenCenter();
			add(spr);
			stageBgMembers.push(spr);
			addedCount++;
		}

		if (addedCount > 0)
			stageLog('lua 背景解析: ' + lastLoadedStage + ' -> ' + addedCount + ' 个精灵');
	}

	// ===== 新 UI：菜单栏控件与回调 =====

	/** 创建菜单栏用的 FlxUI 原生控件（只作数据源，由 menuBar 自绘接管显示）。 */
	function buildMenuBarWidgets():Void
	{
		var stageList:Array<String> = [];
		var foldersToCheck:Array<String> = Mods.directoriesWithFile(Paths.getSharedPath(), 'stages/');
		for (folder in foldersToCheck)
			for (file in FileSystem.readDirectory(folder))
				if (file.toLowerCase().endsWith('.json'))
				{
					var stageToCheck:String = file.substr(0, file.length - '.json'.length);
					if (!stageList.contains(stageToCheck))
						stageList.push(stageToCheck);
				}
		if (stageList.length < 1)
			stageList.push('');

		uiStageDropDown = new FlxUIDropDownMenu(0, 0, FlxUIDropDownMenu.makeStrIdLabelArray(stageList, true), function(pressed:String)
		{
			var selected:String = stageList[Std.parseInt(pressed)];
			if (selected != null && selected.length > 0 && selected != lastLoadedStage)
				MusicBeatState.switchState(new StageEditorState(selected, StageData.getStageFile(selected)));
		});
		uiStageDropDown.selectedLabel = lastLoadedStage;

		// 资源目录下拉：列出 assets 下可用的周目录（week1/week4/...）+ shared
		var dirList:Array<String> = ['shared'];
		var assetsRoot:String = Paths.getSharedPath();
		var checkDir:String = assetsRoot.substr(0, assetsRoot.indexOf('shared'));
		#if MODS_ALLOWED
		if (FileSystem.exists(checkDir))
		{
			for (entry in FileSystem.readDirectory(checkDir))
			{
				if (entry.toLowerCase().indexOf('week') == 0 && FileSystem.isDirectory(checkDir + entry))
					dirList.push(entry);
			}
		}
		#end
		uiDirectoryInput = new FlxUIDropDownMenu(0, 0, FlxUIDropDownMenu.makeStrIdLabelArray(dirList, true), function(pressed:String)
		{
			var idx:Int = Std.parseInt(pressed);
			if (idx >= 0 && idx < dirList.length)
			{
				var dir:String = dirList[idx];
				stageJson.directory = (dir == 'shared') ? '' : dir;
				unsavedProgress = true;
			}
		});
		uiDirectoryInput.selectedLabel = (stageJson.directory != null && stageJson.directory.length > 0) ? stageJson.directory : 'shared';

		uiHideGfCheck = new FlxUICheckBox(0, 0, null, null, '', 100);
		uiHideGfCheck.checked = stageJson.hide_girlfriend;
		uiHideGfCheck.callback = function()
		{
			stageJson.hide_girlfriend = uiHideGfCheck.checked;
			gf.visible = !stageJson.hide_girlfriend;
			unsavedProgress = true;
		};

		// 角色显示/隐藏勾选（对象菜单右侧）：直接控制角色可见性
		uiShowBfCheck = new FlxUICheckBox(0, 0, null, null, '', 100);
		uiShowBfCheck.checked = boyfriend.visible;
		uiShowBfCheck.callback = function() boyfriend.visible = uiShowBfCheck.checked;

		uiShowDadCheck = new FlxUICheckBox(0, 0, null, null, '', 100);
		uiShowDadCheck.checked = dad.visible;
		uiShowDadCheck.callback = function() dad.visible = uiShowDadCheck.checked;

		uiShowGfCheck = new FlxUICheckBox(0, 0, null, null, '', 100);
		uiShowGfCheck.checked = gf.visible;
		uiShowGfCheck.callback = function()
		{
			gf.visible = uiShowGfCheck.checked;
			// 与 Data 面板的 Hide Girlfriend 数据保持同步（存档的是 hide_girlfriend 字段）
			stageJson.hide_girlfriend = !uiShowGfCheck.checked;
			if (uiHideGfCheck != null)
				uiHideGfCheck.checked = !uiShowGfCheck.checked;
			unsavedProgress = true;
		};

		uiDefaultZoomStepper = new FlxUINumericStepper(0, 0, 0.05, stageJson.defaultZoom, minZoom, maxZoom, 2);
		uiCamSpeedStepper = new FlxUINumericStepper(0, 0, 0.1, stageJson.camera_speed != null ? stageJson.camera_speed : 1, 0, 10, 2);
		uiCamZoomStepper = new FlxUINumericStepper(0, 0, 0.05, FlxG.camera.zoom, minZoom, maxZoom, 2);

		uiCamTargetDropDown = new FlxUIDropDownMenu(0, 0, FlxUIDropDownMenu.makeStrIdLabelArray(['boyfriend', 'dad', 'gf'], true), function(pressed:String)
		{
			var target:Array<String> = ['boyfriend', 'dad', 'gf'];
			var idx:Int = Std.parseInt(pressed);
			if (idx >= 0 && idx < target.length)
			{
				var point = focusOnTarget(target[idx]);
				camFollow.setPosition(point.x, point.y);
				FlxG.camera.target = camFollow;
				if (focusRadioGroup != null)
					focusRadioGroup.checked = idx;
			}
		});

		function camOffsetStepper(initVal:Float):FlxUINumericStepper
		{
			return new FlxUINumericStepper(0, 0, 1, initVal, -9000, 9000, 0);
		}

		uiCamBfX = camOffsetStepper(stageJson.camera_boyfriend != null ? stageJson.camera_boyfriend[0] : 0);
		uiCamBfY = camOffsetStepper(stageJson.camera_boyfriend != null ? stageJson.camera_boyfriend[1] : 0);
		uiCamDadX = camOffsetStepper(stageJson.camera_opponent != null ? stageJson.camera_opponent[0] : 0);
		uiCamDadY = camOffsetStepper(stageJson.camera_opponent != null ? stageJson.camera_opponent[1] : 0);
		uiCamGfX = camOffsetStepper(stageJson.camera_girlfriend != null ? stageJson.camera_girlfriend[0] : 0);
		uiCamGfY = camOffsetStepper(stageJson.camera_girlfriend != null ? stageJson.camera_girlfriend[1] : 0);

		uiLowQualityCheck = new FlxUICheckBox(0, 0, null, null, '', 100);
		uiLowQualityCheck.checked = false;
		uiLowQualityCheck.callback = function()
		{
			curFilters = 0;
			if (uiLowQualityCheck.checked) curFilters |= LOW_QUALITY;
			if (uiHighQualityCheck.checked) curFilters |= HIGH_QUALITY;
			if (globalLowQualityCheckbox != null) globalLowQualityCheckbox.checked = uiLowQualityCheck.checked;
			if (globalHighQualityCheckbox != null) globalHighQualityCheckbox.checked = uiHighQualityCheck.checked;
		};

		uiHighQualityCheck = new FlxUICheckBox(0, 0, null, null, '', 100);
		uiHighQualityCheck.checked = true;
		uiHighQualityCheck.callback = function()
		{
			curFilters = 0;
			if (uiLowQualityCheck.checked) curFilters |= LOW_QUALITY;
			if (uiHighQualityCheck.checked) curFilters |= HIGH_QUALITY;
			if (globalLowQualityCheckbox != null) globalLowQualityCheckbox.checked = uiLowQualityCheck.checked;
			if (globalHighQualityCheckbox != null) globalHighQualityCheckbox.checked = uiHighQualityCheck.checked;
		};

		// 挂到 overlayLayer 并隐藏（只作数据源）
		var all:Array<Dynamic> = [uiStageDropDown, uiDirectoryInput, uiHideGfCheck, uiDefaultZoomStepper, uiCamSpeedStepper,
			uiCamZoomStepper, uiCamTargetDropDown, uiCamBfX, uiCamBfY, uiCamDadX, uiCamDadY, uiCamGfX, uiCamGfY,
			uiLowQualityCheck, uiHighQualityCheck, uiShowBfCheck, uiShowDadCheck, uiShowGfCheck];
		for (w in all)
		{
			try { overlayLayer.add(w); } catch (e:Dynamic) {}
			try { w.scrollFactor.set(0, 0); } catch (e:Dynamic) {}
			try { w.cameras = [camHUD]; } catch (e:Dynamic) {}
			try { w.visible = false; w.active = false; } catch (e:Dynamic) {}
		}
	}

	/** 隐藏所有菜单栏原生控件（显示由 menuBar 自绘接管）。 */
	function hideMenuBarWidgets():Void
	{
		var all:Array<Dynamic> = [uiStageDropDown, uiDirectoryInput, uiHideGfCheck, uiDefaultZoomStepper, uiCamSpeedStepper,
			uiCamZoomStepper, uiCamTargetDropDown, uiCamBfX, uiCamBfY, uiCamDadX, uiCamDadY, uiCamGfX, uiCamGfY,
			uiLowQualityCheck, uiHighQualityCheck, uiShowBfCheck, uiShowDadCheck, uiShowGfCheck];
		for (w in all)
			if (w != null) try { w.visible = false; w.active = false; } catch (e:Dynamic) {}
	}

	/**
	 * 与 ESC / B 键等价的退出动作（顶栏「退出 舞台编辑器」按钮共用）：
	 *   - 无未保存改动 → 直接回 MasterEditorMenu 并播 freakyMenu BGM
	 *   - 有未保存改动 → 弹未保存确认弹窗（确认由 ConfirmationPopupSubstate
	 *     内部处理，handleMenuAction 中 switching 主流程与本函数一致）
	 *
	 * 注：帮助/教程面板的"先关再退"逻辑只属于 ESC 修饰，本按钮不继承——
	 *     用户点「退出」是明确意图，无论浮层都应当走退出流程。
	 */
	function doExitEditor():Void
	{
		if (!unsavedProgress)
		{
			MusicBeatState.switchState(new developer.editors.MasterEditorMenu());
			FlxG.sound.playMusic(Paths.music('freakyMenu'));
		}
		else
			openSubState(new ConfirmationPopupSubstate());
	}

	/** 菜单动作回调：新 UI 只负责传数据，实际功能全部由旧 PsychUI 按钮的回调实现（旧 UI 不可见但保留）。 */
	function onMenuAction(actionKey:String):Void
	{
		stageLog('菜单动作: ' + actionKey + ' (checked=' + spriteListRadioGroup.checked + ')');
		switch (actionKey)
		{
			case 'reload_stage':
				// 原地重载（分步销毁+加载，不重建编辑器）
				requestStageSwitch(lastLoadedStage, StageData.getStageFile(lastLoadedStage));
			case 'load_template':
				// 毁灭性操作：先确认
				openSubState(new StageEditorConfirmSubstate('Load template?\nUnsaved changes will be lost!', function()
				{
					MusicBeatState.switchState(new StageEditorState(lastLoadedStage, StageData.dummy()));
				}));
			case 'save':
				saveData();
			// ===== 对象操作：触发旧 Sprite List 面板按钮的既有实现 =====
			case 'obj_new_sprite':
				pushUndo();
				if (popupNoAnimBtn != null)
					popupNoAnimBtn.onClick();
			case 'obj_new_animated':
				pushUndo();
				if (popupAnimBtn != null)
					popupAnimBtn.onClick();
			case 'obj_new_square':
				pushUndo();
				if (popupSquareBtn != null)
					popupSquareBtn.onClick();
			case 'obj_delete':
				// 带确认的删除（Ctrl+X/Delete 同一路径）
				deleteSelectedObject(true);
			case 'obj_duplicate':
				var sel = ensureEditableSelection();
				if (sel == null)
					showError('No object to duplicate! (characters cannot be duplicated)');
				else if (buttonDuplicate != null)
				{
					pushUndo();
					buttonDuplicate.onClick();
					unsavedProgress = true;
				}
			case 'obj_anim':
				// 动画编辑器是 substate（不属于旧面板），直接打开；
				// 允许任何选中对象（含角色，角色编辑内容不会写入 JSON）
				var target = getSelected(false);
				if (target != null)
				{
					animationEditor.target = target;
					unsavedProgress = true;
					openSubState(animationEditor);
				}
				else
					showError('No object selected!');
			case 'obj_move_up':
				if (buttonMoveUp != null)
				{
					pushUndo();
					buttonMoveUp.onClick();
				}
			case 'obj_move_down':
				if (buttonMoveDown != null)
				{
					pushUndo();
					buttonMoveDown.onClick();
				}
			case 'toggle_help':
				helpBg.visible = !helpBg.visible;
				helpTexts.visible = helpBg.visible;
				if (helpBg.visible)
					toggleTutorial(false);
			case 'tutorial':
				toggleTutorial(!tutorialBg.visible);
			case 'focus_bf':
				focusCameraOn('boyfriend');
			case 'focus_dad':
				focusCameraOn('dad');
			case 'focus_gf':
				focusCameraOn('gf');
		}
	}

	// ===== 剪贴板 / 撤销 / 删除（桌面快捷键 Ctrl+C/X/V/Z、Delete）=====

	/** 修改操作前调用：把当前 stageJson 快照压入撤销栈。 */
	function pushUndo():Void
	{
		try { undoStack.push(haxe.Json.stringify(stageJson)); } catch (e:Dynamic) {}
		while (undoStack.length > UNDO_LIMIT)
			undoStack.shift();
	}

	/** Ctrl+Z：弹出最近快照并原地重建舞台。 */
	function doUndo():Void
	{
		if (undoStack.length == 0)
		{
			showError('Nothing to undo!');
			return;
		}
		var snap:String = undoStack.pop();
		var restored:StageFile = null;
		try { restored = cast haxe.Json.parse(snap); } catch (e:Dynamic) {}
		if (restored == null)
		{
			showError('Undo failed!');
			return;
		}
		requestStageSwitch(lastLoadedStage, restored);
	}

	/** 深拷贝元数据（不含 sprite 实例，动画数组逐条拷贝）。
	 *  注意：必须带一个临时 sprite，因为 color/image/x/y 等属性的 setter 会写 sprite。 */
	function deepCopyMeta(src:StageEditorMetaSprite):StageEditorMetaSprite
	{
		var copy:StageEditorMetaSprite = new StageEditorMetaSprite(null, new ModchartSprite());
		for (field in Reflect.fields(src))
		{
			if (field == 'sprite')
				continue;
			try
			{
				var fld:Dynamic = Reflect.getProperty(src, field);
				if (fld is Array)
				{
					var arr:Array<Dynamic> = fld;
					arr = arr.copy();
					if (arr != null)
					{
						for (k => v in arr)
						{
							if (v == null)
								continue;
							var indices:Array<Int> = (v.indices != null) ? v.indices.copy() : null;
							var offs:Array<Int> = (v.offsets != null) ? v.offsets.copy() : null;
							arr[k] = {anim: v.anim, name: v.name, fps: v.fps, loop: v.loop, indices: indices, offsets: offs};
						}
					}
					fld = arr;
				}
				Reflect.setProperty(copy, field, fld);
			}
			catch (e:Dynamic) {}
		}
		return copy;
	}

	/** Ctrl+C：复制选中对象到剪贴板。 */
	function copySelectedToClipboard():Bool
	{
		var sel = getSelected();
		if (sel == null)
		{
			showError('No object selected to copy!');
			return false;
		}
		clipboardMeta = deepCopyMeta(sel);
		showToast('Copied "' + sel.name + '"', false);
		return true;
	}

	/** Ctrl+V：从剪贴板粘贴（插入到选中项下方，名字自动去重，位置偏移避免与原件重叠）。 */
	function pasteClipboard():Void
	{
		if (clipboardMeta == null)
		{
			showError('Clipboard is empty!');
			return;
		}
		pushUndo();
		var newSpr:ModchartSprite = new ModchartSprite();
		var meta:StageEditorMetaSprite = deepCopyMeta(clipboardMeta);
		meta.sprite = newSpr;

		// 位置偏移，避免粘贴对象与原件完全重叠（视觉上"没反应"）
		newSpr.setPosition(meta.x + 20, meta.y + 20);

		// 重建动画（与 Duplicate 按钮同一套逻辑）
		if (meta.animations != null)
		{
			for (num => anim in meta.animations)
			{
				if (anim == null || anim.anim == null)
					continue;
				if (anim.indices != null && anim.indices.length > 0)
					newSpr.animation.addByIndices(anim.anim, anim.name, anim.indices, '', anim.fps, anim.loop);
				else
					newSpr.animation.addByPrefix(anim.anim, anim.name, anim.fps, anim.loop);
				if (anim.offsets != null && anim.offsets.length > 1)
					newSpr.addOffset(anim.anim, anim.offsets[0], anim.offsets[1]);
				if (newSpr.animation.curAnim == null || meta.firstAnimation == anim.anim)
					newSpr.playAnim(anim.anim, true);
			}
		}
		// 图片（image setter 会触发 loadGraphic / getAtlas 加载纹理）
		if (meta.image != null && meta.image.length > 0 && meta.type != 'square')
			tryLoadImage(meta, meta.image);

		meta.name = findUnoccupiedName(meta.name + '_copy');
		meta.setScale(meta.scale[0], meta.scale[1]);
		meta.setScrollFactor(meta.scroll[0], meta.scroll[1]);
		insertMeta(meta, 1);
		showToast('Pasted "' + meta.name + '"', false);
	}

	/** Delete / 剪切共用：带确认的删除。 */
	function deleteSelectedObject(withConfirm:Bool):Void
	{
		var sel = ensureEditableSelection();
		if (sel == null)
		{
			showError('No editable object selected!');
			return;
		}
		pushUndo();
		var doDelete:Void->Void = function()
		{
			stageSprites.remove(sel);
			sel.sprite = FlxDestroyUtil.destroy(sel.sprite);
			updateSpriteListRadio();
			updateSelectedUI();
			unsavedProgress = true;
		};
		if (withConfirm)
			openSubState(new StageEditorConfirmSubstate('Delete "' + sel.name + '"?', doDelete));
		else
			doDelete();
	}

	/** Ctrl+X：复制到剪贴板 + 带确认的删除。 */
	function cutSelectedObject():Void
	{
		var sel = ensureEditableSelection();
		if (sel == null)
		{
			showError('No editable object selected!');
			return;
		}
		clipboardMeta = deepCopyMeta(sel);
		deleteSelectedObject(true);
	}

	/** 确保有可编辑对象被选中（菜单操作前调用）。 */
	function ensureEditableSelection():StageEditorMetaSprite
	{
		var selected = getSelected();
		if (selected != null && !StageData.reservedNames.contains(selected.type))
			return selected;

		// 没选中或选中的是角色：自动选中第一个可编辑对象
		var labelsLen:Int = spriteListRadioGroup.labels.length;
		for (i in 0...stageSprites.length)
		{
			var spr = stageSprites[i];
			if (spr != null && !StageData.reservedNames.contains(spr.type))
			{
				var target:Int = labelsLen - 1 - i;
				if (target >= 0 && target < labelsLen)
				{
					spriteListRadioGroup.checked = target;
					updateSelectedUI();
				}
				return spr;
			}
		}
		return null;
	}

	/** 菜单打开时刷新控件值（与当前舞台数据同步）。 */
	function onMenuOpened(menuKey:String):Void
	{
		if (uiDirectoryInput != null)
			uiDirectoryInput.selectedLabel = (stageJson.directory != null && stageJson.directory.length > 0) ? stageJson.directory : 'shared';
		if (uiHideGfCheck != null)
			uiHideGfCheck.checked = stageJson.hide_girlfriend;
		if (uiDefaultZoomStepper != null)
			uiDefaultZoomStepper.value = stageJson.defaultZoom;
		if (uiCamSpeedStepper != null)
			uiCamSpeedStepper.value = stageJson.camera_speed != null ? stageJson.camera_speed : 1;
		if (uiCamZoomStepper != null)
			uiCamZoomStepper.value = FlxG.camera.zoom;
		if (uiLowQualityCheck != null && globalLowQualityCheckbox != null)
			uiLowQualityCheck.checked = globalLowQualityCheckbox.checked;
		if (uiHighQualityCheck != null && globalHighQualityCheckbox != null)
			uiHighQualityCheck.checked = globalHighQualityCheckbox.checked;
		if (uiShowBfCheck != null)
			uiShowBfCheck.checked = boyfriend.visible;
		if (uiShowDadCheck != null)
			uiShowDadCheck.checked = dad.visible;
		if (uiShowGfCheck != null)
			uiShowGfCheck.checked = gf.visible;
	}

	/** 相机聚焦到目标角色（瞬时定位，不进入跟随模式，避免相机无限追 camFollow）。 */
	function focusCameraOn(target:String):Void
	{
		var point = focusOnTarget(target);
		FlxG.camera.target = null;
		FlxG.camera.scroll.set(point.x - FlxG.width / 2, point.y - FlxG.height / 2);
		var idx:Int = ['boyfriend', 'dad', 'gf'].indexOf(target);
		if (focusRadioGroup != null && idx >= 0)
			focusRadioGroup.checked = idx;
	}

	/** 一级菜单快捷键 F1~F6：打开/关闭对应下拉菜单。 */
	function toggleMenuHotkey(idx:Int):Void
	{
		if (menuBar == null || idx < 0 || idx >= menuBar.menus.length)
			return;
		if (menuBar.activeMenu == idx)
			menuBar.closeMenu();
		else
			menuBar.openMenu(idx);
	}

	/** 每帧刷新状态栏（由 update 调用）。 */
	function updateStatusBar():Void
	{
		if (menuBar == null || menuBar.statusBar == null)
			return;
		menuBar.statusBar.setStage(lastLoadedStage);
		menuBar.statusBar.setDirectory(stageJson.directory != null && stageJson.directory.length > 0 ? stageJson.directory : 'shared');
		var selected = getSelected(false);
		if (selected != null)
		{
			var displayX:Float = Math.round(selected.x);
			var displayY:Float = Math.round(selected.y);
			var char:Character = cast selected.sprite;
			if (char != null)
			{
				displayX -= char.positionArray[0];
				displayY -= char.positionArray[1];
			}
			menuBar.statusBar.setObject(selected.name != null ? selected.name : selected.type);
			menuBar.statusBar.setPos('$displayX / $displayY');
		}
		else
		{
			menuBar.statusBar.setObject('-');
			menuBar.statusBar.setPos('-');
		}
		menuBar.statusBar.setZoom(FlxMath.roundDecimal(FlxG.camera.zoom, 2) + 'x');
	}

	function getSelectedObjName():String
	{
		var selected = getSelected(false);
		return (selected != null) ? (selected.name != null ? selected.name : selected.type) : '-';
	}

	function getSelectedObjType():String
	{
		var selected = getSelected(false);
		return (selected != null) ? selected.type : '-';
	}

	function getSelectedObjImage():String
	{
		var selected = getSelected(false);
		return (selected != null) ? selected.image : '-';
	}

	function getSelectedObjPos():String
	{
		var selected = getSelected(false);
		return (selected != null) ? '${Math.round(selected.x)} / ${Math.round(selected.y)}' : '-';
	}

	function getSelectedObjScale():String
	{
		var selected = getSelected(false);
		return (selected != null) ? '${selected.scale[0]} / ${selected.scale[1]}' : '-';
	}

	function getSelectedObjAlpha():String
	{
		var selected = getSelected(false);
		return (selected != null) ? Std.string(Math.round(selected.alpha * 100)) + '%' : '-';
	}

	function getSelectedObjAngle():String
	{
		var selected = getSelected(false);
		return (selected != null) ? Std.string(Math.round(selected.angle)) + '\u00b0' : '-';
	}

	/** 请求切换舞台：先分步销毁旧背景，再分步加载新背景（稳定优先）。 */
	function requestStageSwitch(stageName:String, stageFile:StageFile):Void
	{
		// 中断进行中的上传
		_pendingUpload = [];
		_uploadingStage = false;
		_pendingDestroy = [];

		// 旧精灵进入分步销毁队列（先不 remove，分步 remove+destroy 分散 GPU 释放压力）
		_clearingQueue = stageBgMembers.copy();
		_clearingTotal = _clearingQueue.length;
		_clearedCount = 0;
		stageBgMembers = [];
		stages = [];

		_transitionStage = stageName;
		_transitionJson = stageFile;
		_transitionState = 1;
		// 切换舞台时同步临时素材目录
		StageEditorMetaSprite.tempImageDir = Sys.getCwd().replace('\\', '/') + 'temp/stage_editor/' + stageName + '/images/';

		if (_clearingTotal > 0 && _loadingText != null)
		{
			_loadingText.text = 'Clearing stage... 0/' + _clearingTotal;
			_loadingText.visible = true;
			_loadingBg.visible = true;
		}
	}

	/** 切换状态机驱动（update 中调用）：分步销毁 → 分步加载。 */
	function processTransition():Void
	{
		if (_transitionState == 0)
		{
			processPendingUpload();
			return;
		}

		if (_transitionState == 1)
		{
			// 分步销毁：每帧 remove + destroy 2 个旧精灵
			var done:Int = 0;
			while (_clearingQueue.length > 0 && done < TRANSITION_PER_FRAME)
			{
				var m:FlxBasic = _clearingQueue.shift();
				done++;
				_clearedCount++;
				if (m != null)
				{
					try
					{
						remove(m, true);
						FlxDestroyUtil.destroy(m);
					}
					catch (e:Dynamic) {}
				}
			}

			if (_clearingQueue.length > 0)
			{
				if (_loadingText != null)
					_loadingText.text = 'Clearing stage... ' + _clearedCount + '/' + _clearingTotal;
				return;
			}

			// 销毁完成 → 清理旧舞台的纹理缓存（模拟 PlayState 切换时的干净环境：
			// 编辑器反复切换会让 Paths 缓存累积所有舞台的图，显存越积越多导致渲染提交崩溃）
			stageLog('旧舞台销毁完成: ' + lastLoadedStage + '，清理缓存');
			try
			{
				Paths.clearUnusedMemory();
			}
			catch (e:Dynamic)
			{
				stageLog('缓存清理异常: ' + e);
			}
			lastLoadedStage = _transitionStage;
			stageJson = _transitionJson;
			loadJsonAssetDirectory();
			loadStageBackgrounds();
			_transitionState = 2;
			// loadStageBackgrounds 已填充 _pendingUpload 并显示加载进度条
			processPendingUpload();
			return;
		}

		// 状态 2：分步上传纹理（进度条）
		processPendingUpload();
		if (!_uploadingStage)
		{
			_transitionState = 0;
			// 切换完成后刷新编辑器 UI（角色、精灵列表、舞台下拉等）
			updateStageDataUI();
			reloadCharacters();
			updateSpriteList();
			reloadStageDropDown();
			stageLog('舞台切换完成: ' + lastLoadedStage);
		}
	}

	/** 每帧预上传 N 个纹理，全部完成后恢复显示。 */
	function processPendingUpload():Void
	{
		if (!_uploadingStage)
			return;

		var done:Int = 0;
		// 保守阈值：超过 2048 的纹理跳过预上传（走 Flixel 默认渲染路径，游戏里同样正常显示）
		var maxSize:Int = 2048;

		while (_pendingUpload.length > 0 && done < 2)
		{
			var spr:FlxSprite = _pendingUpload.shift();
			done++;
			if (spr == null || spr.graphic == null || spr.graphic.bitmap == null)
				continue;
			var bmp = spr.graphic.bitmap;
			// 超 GPU 上限的纹理跳过预上传（走 Flixel 默认渲染路径，游戏里同样正常显示）
			if (bmp.width > maxSize || bmp.height > maxSize)
			{
				stageLog('纹理超限，跳过预上传: ' + bmp.width + 'x' + bmp.height + ' (max=' + maxSize + ')');
				spr.visible = true;
				continue;
			}
			try
			{
				// 强制纹理上传（渲染管线内，与游戏一致），避免渲染时同步上传大纹理
				bmp.getTexture(FlxG.stage.context3D);
			}
			catch (e:Dynamic)
			{
				stageLog('纹理上传失败: ' + e);
			}
		}

		if (_pendingUpload.length > 0)
		{
			if (_loadingText != null)
				_loadingText.text = 'Loading stage... ' + (_uploadTotal - _pendingUpload.length) + '/' + _uploadTotal;
		}
		else
		{
			_uploadingStage = false;
			for (m in stageBgMembers)
				if (m != null)
					m.visible = true;
			if (_loadingText != null)
			{
				_loadingText.visible = false;
				_loadingBg.visible = false;
			}
			stageLog('舞台纹理上传完成: ' + lastLoadedStage);
		}
	}

	/** 销毁 Stage 类创建的背景精灵（切换舞台 / Reload 时调用）。延迟到下一帧安全点销毁。 */
	function clearStageBackgrounds():Void
	{
		// 中断进行中的分步上传，重置状态
		_pendingUpload = [];
		_uploadingStage = false;
		if (_loadingText != null)
		{
			_loadingText.visible = false;
			_loadingBg.visible = false;
		}

		for (m in stageBgMembers)
		{
			remove(m, true);
			_pendingDestroy.push(m);
		}
		stageBgMembers = [];
		stages = [];
	}

	/** 帧阶段诊断标记。 */
	function diagMark(mark:String):Void
	{
		_diagBuf += mark;
		_diagBufCount++;
		if (_diagBufCount >= 15)
		{
			_diagBufCount = 0;
			#if sys
			try
			{
				if (!FileSystem.exists('logs'))
					FileSystem.createDirectory('logs');
				File.saveContent('logs/stage_editor_frames.log', _diagBuf);
			}
			catch (e:Dynamic) {}
			#end
			_diagBuf = '';
		}
	}

	/** 处理延迟销毁队列 + 周期性检查坏精灵（诊断）。在 update() 开头调用。 */
	function processPendingDestroy():Void
	{
		if (_pendingDestroy.length > 0)
		{
			for (m in _pendingDestroy)
			{
				try
				{
					FlxDestroyUtil.destroy(m);
				}
				catch (e:Dynamic) {}
			}
			_pendingDestroy = [];
		}

		// 每 30 帧检查一次背景精灵的 graphic 是否已被销毁（bitmap=null），提前发现渲染崩溃源
		// 注意：不能用 animation==null 判断"已销毁"——FlxSpriteGroup 的 initVars 不创建
		// animation（正常状态就是 null），会把 PsychUIBox/FlxUI 等 UI 组误杀
		_diagFrames++;
		if (_diagFrames >= 30)
		{
			_diagFrames = 0;
			var bad:Int = 0;
			for (m in stageBgMembers)
			{
				if (Std.isOfType(m, FlxSprite))
				{
					var spr:FlxSprite = cast m;
					if (spr.graphic != null && spr.graphic.bitmap == null)
					{
						bad++;
						remove(m, true);
						_pendingDestroy.push(m);
					}
				}
			}
			if (bad > 0)
				stageLog('检测到 ' + bad + ' 个背景精灵的 graphic 已销毁，已移除');
		}
	}

	var showSelectionQuad:Bool = true;

	function addHelpScreen()
	{
		var str:Array<String> = controls.mobileC ? [
			"X/Y - Camera Zoom In/Out",
			"G + Arrow Buttons - Move Camera",
			"Z - Reset Camera Zoom",
			"Arrow Buttons/Drag - Move Object",
			"",
			"S - Toggle HUD",
			// "F12 - Toggle Selection Rectangle",
			// "Hold Control - Move Objects pixel-by-pixel and Camera 4x slower",
			"Hold C - Move Objects and Camera 4x faster"
		] : [
			"F1-F6 - Open Menus",
			"F7 - Help Overlay",
			"Ctrl+Z - Undo   Ctrl+C/X/V - Copy/Cut/Paste",
			"Delete - Delete Object (with confirm)",
			"",
			"E/Q - Camera Zoom In/Out",
			"J/K/L/I - Move Camera",
			"R - Reset Camera Zoom",
			"Arrow Keys/Mouse & Right Click - Move Object",
			"",
			"W/S - Select Object   F12 - Toggle Selection Rectangle",
			"Hold Shift - Move Objects and Camera 4x faster",
			"Hold Control - Move Objects pixel-by-pixel and Camera 4x slower"
			];

		helpBg = new FlxSprite().makeGraphic(1, 1, FlxColor.BLACK);
		helpBg.scale.set(FlxG.width, FlxG.height);
		helpBg.updateHitbox();
		helpBg.alpha = 0.6;
		helpBg.cameras = [camHUD];
		helpBg.active = helpBg.visible = false;
		add(helpBg);

		helpTexts = new FlxSpriteGroup();
		helpTexts.cameras = [camHUD];
		for (i => txt in str)
		{
			if (txt.length < 1)
				continue;

			var helpText:FlxText = new FlxText(0, 0, 680, txt, 16);
			helpText.setFormat(null, 16, FlxColor.WHITE, CENTER, OUTLINE_FAST, FlxColor.BLACK);
			helpText.borderColor = FlxColor.BLACK;
			helpText.scrollFactor.set();
			helpText.borderSize = 1;
			helpText.screenCenter();
			add(helpText);
			helpText.y += ((i - str.length / 2) * 32) + 16;
			helpText.active = false;
			helpTexts.add(helpText);
		}
		helpTexts.active = helpTexts.visible = false;
		add(helpTexts);
	}

	/** 新手教程浮层（帮助菜单 → 新手教程）。 */
	function addTutorialScreen()
	{
		tutorialBg = new FlxSprite().makeGraphic(1, 1, FlxColor.BLACK);
		tutorialBg.scale.set(FlxG.width, FlxG.height);
		tutorialBg.updateHitbox();
		tutorialBg.alpha = 0.8;
		tutorialBg.cameras = [camHUD];
		tutorialBg.active = tutorialBg.visible = false;
		add(tutorialBg);

		tutorialTexts = new FlxSpriteGroup();
		tutorialTexts.cameras = [camHUD];
		var str:Array<String> = [
			'★ 舞台背景设置教程 ★',
			'',
			'1. 新建背景：对象菜单 → 新建精灵（图片）/ 新建动画精灵 / 新建纯色方块',
			'2. 选择图片：可一次选择多个 PNG（可 Ctrl 多选），每个 PNG 会创建一个对象；',
			'    动画精灵会自动连带复制同目录同名的 XML/JSON/TXT 动画文件',
			'3. 任意位置的文件都会先导入到临时目录 temp，保存时输出到 saves/stage/<舞台名>/',
			'4. 移动对象：方向键移动 / 鼠标左键拖动 / 右键拖动',
			'5. 切换对象：W / S 键，或对象菜单底部的对象列表（点击选中）',
			'6. 渲染层级：对象菜单 → 上移一层 / 下移一层',
			'7. 相机：Q/E 缩放，J/K/L/I 移动，R 重置缩放；聚焦：视图菜单',
			'8. 复制粘贴：Ctrl+C/X/V，Delete 删除（有确认），Ctrl+Z 撤销',
			'9. 保存：文件 → 保存，直接写入 saves/stage/<舞台名>/（含图片素材）',
			'10. 角色可见性：对象菜单底部的显示玩家/对手/女友勾选',
			'',
			'按 Esc 关闭本教程'
		];
		for (i => txt in str)
		{
			if (txt.length < 1)
				continue;
			var t:FlxText = new FlxText(0, 0, 980, txt, 15);
			t.setFormat(Paths.font(Language.get('fontName', 'main') + '.ttf'), 15, FlxColor.WHITE, LEFT, OUTLINE_FAST, FlxColor.BLACK);
			t.borderColor = FlxColor.BLACK;
			t.borderSize = 1;
			t.scrollFactor.set();
			t.screenCenter(X);
			t.y = (FlxG.height / 2 - str.length * 11) + i * 22;
			t.active = false;
			tutorialTexts.add(t);
		}
		tutorialTexts.active = tutorialTexts.visible = false;
		add(tutorialTexts);
	}

	/** 切换新手教程浮层（与帮助浮层互斥）。 */
	function toggleTutorial(show:Bool):Void
	{
		tutorialBg.visible = tutorialTexts.visible = show;
		if (show && helpBg != null)
			helpBg.visible = helpTexts.visible = false;
	}

	function updateSpriteList()
	{
		for (spr in stageSprites)
			if (spr != null && !StageData.reservedNames.contains(spr.type))
			{
				if (spr.sprite != null)
					_pendingDestroy.push(spr.sprite);
				spr.sprite = null;
			}

		stageSprites = [];
		var list:Map<String, FlxSprite> = [];
		if (stageJson.objects != null && stageJson.objects.length > 0)
		{
			list = StageData.addObjectsToState(stageJson.objects, gf, dad, boyfriend, null, true);
			for (key => spr in list)
				stageSprites[spr.ID] = new StageEditorMetaSprite(stageJson.objects[spr.ID], spr);

			/*for (num => spr in stageSprites)
				trace('$num: ${spr.type}, ${spr.name}'); */
		}

		for (character in ['gf', 'dad', 'boyfriend'])
			if (!list.exists(character))
				stageSprites.push(new StageEditorMetaSprite({type: character}, Reflect.field(this, character)));

		updateSpriteListRadio();
	}

	var spriteListRadioGroup:PsychUIRadioGroup;
	var focusRadioGroup:PsychUIRadioGroup;

	function screenUI()
	{
		// 全局可见性过滤（低/高质量）——由新 UI 的 View 菜单控件驱动，旧 checkbox 只作数据源
		visibilityFilterUpdate = function()
		{
			curFilters = 0;
			if (globalLowQualityCheckbox != null && globalLowQualityCheckbox.checked)
				curFilters |= LOW_QUALITY;
			if (globalHighQualityCheckbox != null && globalHighQualityCheckbox.checked)
				curFilters |= HIGH_QUALITY;
		}

		spriteList_box = new PsychUIBox(25, 101, 250, 200, ['Sprite List']);
		spriteList_box.scrollFactor.set();
		spriteList_box.cameras = [camHUD];
		add(spriteList_box);
		addSpriteListBox();

		bottomBarBg = new FlxSprite(0, FlxG.height - 60).makeGraphic(1, 1, FlxColor.BLACK);
		bottomBarBg.cameras = [camHUD];
		bottomBarBg.alpha = 0.4;
		bottomBarBg.scale.set(FlxG.width, FlxG.height - bottomBarBg.y);
		bottomBarBg.updateHitbox();
		add(bottomBarBg);

		tipText = new FlxText(0, FlxG.height - 44, 300, 'Press ${controls.mobileC ? 'F' : 'F1'} for Help', 20);
		tipText.alignment = CENTER;
		tipText.cameras = [camHUD];
		tipText.scrollFactor.set();
		tipText.screenCenter(X);
		tipText.active = false;
		add(tipText);

		targetTxt = new FlxText(30, FlxG.height - 52, 300, 'Camera Target', 16);
		targetTxt.alignment = CENTER;
		targetTxt.cameras = [camHUD];
		targetTxt.scrollFactor.set();
		targetTxt.active = false;
		add(targetTxt);

		focusRadioGroup = new PsychUIRadioGroup(targetTxt.x, FlxG.height - 24, ['dad', 'boyfriend', 'gf'], 10, 0, true);
		focusRadioGroup.onClick = function()
		{
			// 瞬时定位（不进入跟随模式，避免相机无限追 camFollow）
			var target:String = focusRadioGroup.labels[focusRadioGroup.checked];
			focusCameraOn(target);
		}
		focusRadioGroup.radios[0].label = 'Opponent';
		focusRadioGroup.radios[1].label = 'Boyfriend';
		focusRadioGroup.radios[2].label = 'Girlfriend';

		for (radio in focusRadioGroup.radios)
			radio.text.size = 11;

		focusRadioGroup.cameras = [camHUD];
		add(focusRadioGroup);

		globalLowQualityCheckbox = new PsychUICheckBox(FlxG.width - 240, FlxG.height - 36, 'Can see Low Quality Sprites?', 90);
		globalLowQualityCheckbox.cameras = [camHUD];
		globalLowQualityCheckbox.onClick = visibilityFilterUpdate;
		globalLowQualityCheckbox.checked = false;
		add(globalLowQualityCheckbox);

		globalHighQualityCheckbox = new PsychUICheckBox(FlxG.width - 120, FlxG.height - 36, 'Can see High Quality Sprites?', 90);
		globalHighQualityCheckbox.cameras = [camHUD];
		globalHighQualityCheckbox.onClick = visibilityFilterUpdate;
		globalHighQualityCheckbox.checked = true;
		add(globalHighQualityCheckbox);
		visibilityFilterUpdate();

		posTxt = new FlxText(0, 70, 500, 'X: 0\nY: 0', 24);
		posTxt.setFormat(Paths.font(Language.get('fontName', 'main') + '.ttf'), 24, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		posTxt.borderSize = 2;
		posTxt.cameras = [camHUD];
		posTxt.screenCenter(X);
		posTxt.visible = false;
		add(posTxt);

		errorTxt = new FlxText(0, 0, 800, '', 24);
		errorTxt.alignment = CENTER;
		errorTxt.borderStyle = OUTLINE_FAST;
		errorTxt.borderSize = 1;
		errorTxt.color = 0xFFEF4444; // Danger（设计系统）
		errorTxt.cameras = [camHUD];
		errorTxt.screenCenter();
		errorTxt.alpha = 0;
		add(errorTxt);
	}

	function addSpriteListBox()
	{
		var tab_group = spriteList_box.getTab('Sprite List').menu;
		spriteListRadioGroup = new PsychUIRadioGroup(10, 10, [], 25, 18, false, 200);
		spriteListRadioGroup.cameras = [camHUD];
		spriteListRadioGroup.onClick = function()
		{
			trace('Selected sprite: ${spriteListRadioGroup.checkedRadio.label}');
			updateSelectedUI();
		}
		tab_group.add(spriteListRadioGroup);

		var buttonX = spriteList_box.x + spriteList_box.width - 10;
		var buttonY = spriteListRadioGroup.y - 30;
		buttonMoveUp = new PsychUIButton(buttonX, buttonY, 'Move Up', function()
		{
			var selected:Int = spriteListRadioGroup.checked;
			if (selected < 0)
				return;

			var selected:Int = spriteListRadioGroup.labels.length - selected - 1;
			var spr = stageSprites[selected];
			if (spr == null)
				return;

			var newSel:Int = Std.int(Math.min(stageSprites.length - 1, selected + 1));
			stageSprites.remove(spr);
			stageSprites.insert(newSel, spr);

			updateSpriteListRadio();
		});
		buttonMoveUp.cameras = [camHUD];
		tab_group.add(buttonMoveUp);

		buttonMoveDown = new PsychUIButton(buttonX, buttonY + 30, 'Move Down', function()
		{
			var selected:Int = spriteListRadioGroup.checked;
			if (selected < 0)
				return;

			var selected:Int = spriteListRadioGroup.labels.length - selected - 1;
			var spr = stageSprites[selected];
			if (spr == null)
				return;

			var newSel:Int = Std.int(Math.max(0, selected - 1));
			stageSprites.remove(spr);
			stageSprites.insert(newSel, spr);

			updateSpriteListRadio();
		});
		buttonMoveDown.cameras = [camHUD];
		tab_group.add(buttonMoveDown);

		buttonCreate = new PsychUIButton(buttonX, buttonY + 60, 'New', function() createPopup.visible = createPopup.active = true);
		buttonCreate.cameras = [camHUD];
		buttonCreate.normalStyle.bgColor = FlxColor.GREEN;
		buttonCreate.normalStyle.textColor = FlxColor.WHITE;
		tab_group.add(buttonCreate);

		buttonDuplicate = new PsychUIButton(buttonX, buttonY + 90, 'Duplicate', function()
		{
			var selected:Int = spriteListRadioGroup.checked;
			if (selected < 0)
				return;

			var selected:Int = spriteListRadioGroup.labels.length - selected - 1;
			var spr = stageSprites[selected];
			if (spr == null || StageData.reservedNames.contains(spr.type))
				return;

			var copiedSpr = new ModchartSprite();
			var copiedMeta:StageEditorMetaSprite = new StageEditorMetaSprite(null, copiedSpr);
			for (field in Reflect.fields(spr))
			{
				if (field == 'sprite')
					continue; // do NOT copy sprite or it might get messy

				try
				{
					var fld:Dynamic = Reflect.getProperty(spr, field);
					if (fld is Array)
					{
						var arr:Array<Dynamic> = fld;
						arr = arr.copy();
						if (arr != null)
						{
							for (k => v in arr)
							{
								var indices:Array<Int> = v.indices;
								if (indices != null)
									indices = indices.copy();

								var offs:Array<Int> = v.offsets;
								if (offs != null)
									offs = offs.copy();

								fld[k] = {
									anim: v.anim,
									name: v.name,
									fps: v.fps,
									loop: v.loop,
									indices: indices,
									offsets: offs
								}
							}
						}
						fld = arr;
					}

					Reflect.setProperty(copiedMeta, field, fld);
					// trace('success? $field');
				}
				catch (e:Dynamic)
				{
					// trace('failed: $field');
				}
			}

			// 无动画的对象 animations 为 null，遍历前必须检查
			if (copiedMeta.animations != null)
			{
				for (num => anim in copiedMeta.animations)
				{
					if (anim == null || anim.anim == null)
						continue;

					if (anim.indices != null && anim.indices.length > 0)
						copiedSpr.animation.addByIndices(anim.anim, anim.name, anim.indices, '', anim.fps, anim.loop);
					else
						copiedSpr.animation.addByPrefix(anim.anim, anim.name, anim.fps, anim.loop);

					if (anim.offsets != null && anim.offsets.length > 1)
						copiedSpr.addOffset(anim.anim, anim.offsets[0], anim.offsets[1]);

					if (copiedSpr.animation.curAnim == null || copiedMeta.firstAnimation == anim.anim)
						copiedSpr.playAnim(anim.anim, true);
				}
			}
			copiedMeta.setScale(copiedMeta.scale[0], copiedMeta.scale[1]);
			copiedMeta.setScrollFactor(copiedMeta.scroll[0], copiedMeta.scroll[1]);
			copiedMeta.name = findUnoccupiedName('${copiedMeta.name}_copy');
			insertMeta(copiedMeta, 1);
		});
		buttonDuplicate.cameras = [camHUD];
		buttonDuplicate.normalStyle.bgColor = FlxColor.BLUE;
		buttonDuplicate.normalStyle.textColor = FlxColor.WHITE;
		tab_group.add(buttonDuplicate);

		buttonDelete = new PsychUIButton(buttonX, buttonY + 120, 'Delete', function()
		{
			var selected:Int = spriteListRadioGroup.checked;
			if (selected < 0)
				return;

			var selected:Int = spriteListRadioGroup.labels.length - selected - 1;
			var spr = stageSprites[selected];
			if (spr == null || StageData.reservedNames.contains(spr.type))
				return;

			stageSprites.remove(spr);
			spr.sprite = FlxDestroyUtil.destroy(spr.sprite);

			updateSpriteListRadio();
		});
		buttonDelete.cameras = [camHUD];
		buttonDelete.normalStyle.bgColor = FlxColor.RED;
		buttonDelete.normalStyle.textColor = FlxColor.WHITE;
		tab_group.add(buttonDelete);
	}

	function showError(txt:String)
	{
		showToast(txt, true);
	}

	/** 屏幕中央提示：红=错误(Danger)，绿=成功(OK)——设计系统状态色。 */
	function showToast(txt:String, isError:Bool = true)
	{
		errorTxt.color = isError ? 0xFFEF4444 : 0xFF22C55E;
		errorTxt.text = txt;
		errorTime = 3;
	}

	var createPopup:FlxSpriteGroup;

	function findUnoccupiedName(prefix = 'sprite')
	{
		var num:Int = 1;
		var name:String = 'unnamed';
		while (true)
		{
			var cantUseName:Bool = false;

			name = prefix + num;
			for (basic in stageSprites)
			{
				if (basic.name == name)
				{
					cantUseName = true;
					break;
				}
			}

			if (cantUseName)
			{
				num++;
				continue;
			}
			break;
		}
		return name;
	}

	function insertMeta(meta, insertOffset:Int = 0)
	{
		var num:Int = Std.int(Math.max(0,
			Math.min(spriteListRadioGroup.labels.length, spriteListRadioGroup.labels.length - spriteListRadioGroup.checked - 1 + insertOffset)));
		stageSprites.insert(num, meta);
		updateSpriteListRadio();
		createPopup.visible = createPopup.active = false;
		spriteListRadioGroup.checked = spriteListRadioGroup.labels.length - num - 1;
		updateSelectedUI();
		unsavedProgress = true;
	}

	function spriteCreatePopup()
	{
		createPopup = new FlxSpriteGroup();
		createPopup.cameras = [camHUD];

		var bg:FlxSprite = new FlxSprite().makeGraphic(1, 1, FlxColor.BLACK);
		bg.alpha = 0.6;
		bg.scale.set(300, 240);
		bg.updateHitbox();
		bg.screenCenter();
		createPopup.add(bg);

		var txt:FlxText = new FlxText(0, bg.y + 10, 180, 'New Sprite', 24);
		txt.screenCenter(X);
		txt.alignment = CENTER;
		createPopup.add(txt);

		var btnY = 320;
		popupNoAnimBtn = new PsychUIButton(0, btnY, 'No Animation', function() loadImage('sprite'));
		popupNoAnimBtn.screenCenter(X);
		createPopup.add(popupNoAnimBtn);

		btnY += 50;
		popupAnimBtn = new PsychUIButton(0, btnY, 'Animated', function() loadImage('animatedSprite'));
		popupAnimBtn.screenCenter(X);
		createPopup.add(popupAnimBtn);

		btnY += 50;
		popupSquareBtn = new PsychUIButton(0, btnY, 'Solid Color', function()
		{
			var meta:StageEditorMetaSprite = new StageEditorMetaSprite({type: 'square', scale: [200, 200], name: findUnoccupiedName()}, new ModchartSprite());
			meta.sprite.makeGraphic(1, 1, FlxColor.WHITE);
			meta.sprite.scale.set(200, 200);
			meta.sprite.updateHitbox();
			meta.sprite.screenCenter();
			insertMeta(meta);
		});
		popupSquareBtn.screenCenter(X);
		createPopup.add(popupSquareBtn);
		add(createPopup);
		createPopup.visible = createPopup.active = false;
	}

	function updateSpriteListRadio()
	{
		var _sel:String = (spriteListRadioGroup.checkedRadio != null ? spriteListRadioGroup.checkedRadio.label : null);
		var nameList:Array<String> = [];
		for (spr in stageSprites)
		{
			if (spr == null)
				continue;

			switch (spr.type)
			{
				case 'gf':
					nameList.push('- Girlfriend -');
				case 'boyfriend':
					nameList.push('- Boyfriend -');
				case 'dad':
					nameList.push('- Opponent -');
				default:
					nameList.push(spr.name);
			}
		}
		nameList.reverse();

		spriteListRadioGroup.labels = nameList;
		for (radio in spriteListRadioGroup.radios)
		{
			if (radio.label == _sel)
			{
				spriteListRadioGroup.checkedRadio = radio;
				break;
			}
		}

		final maxNum:Int = 19;
		spriteList_box.resize(250, Std.int(Math.min(maxNum, spriteListRadioGroup.labels.length) * 25 + 35));
	}

	function editorUI()
	{
		UI_box = new PsychUIBox(FlxG.width - 225, 10, 200, 400, ['Meta', 'Data', 'Object']);
		UI_box.cameras = [camHUD];
		UI_box.scrollFactor.set();
		add(UI_box);
		UI_box.selectedName = 'Data';

		UI_stagebox = new PsychUIBox(FlxG.width - 275, 86, 250, 100, ['Stage']);
		UI_stagebox.cameras = [camHUD];
		UI_stagebox.scrollFactor.set();
		add(UI_stagebox);
		UI_box.y = UI_stagebox.y + UI_stagebox.height;

		addDataTab();
		addObjectTab();
		addMetaTab();
		addStageTab();
	}

	/**
	 * 旧 PsychUI 面板全程不可见（visible=false），但保留 active 与全部回调，
	 * 由新 UI 菜单栏负责传数据、触发旧按钮的 onClick 实现功能、并把结果反馈回状态栏/对象菜单。
	 */
	function hideOldUI():Void
	{
		// ★ 全部 active=false：PsychUI 控件的鼠标检测都在 update 里，
		//   隐藏后若仍 active 会"幽灵点击"（例如对象菜单面板正下方就是旧的
		//   Sprite List 按钮，点菜单时会误触发旧按钮/旧下拉导致编辑器重启）。
		//   所有旧功能都是程序调用路径（onClick 直接调 / value、text、checked
		//   setter / W、S 键盘选择），完全不依赖控件的 update。
		var hideList:Array<FlxBasic> = [
			spriteList_box, UI_box, UI_stagebox, createPopup, focusRadioGroup,
			globalLowQualityCheckbox, globalHighQualityCheckbox, posTxt,
			bottomBarBg, tipText, targetTxt
		];
		for (h in hideList)
		{
			if (h == null)
				continue;
			h.visible = false;
			h.active = false;
		}
		// 保险：清掉可能残留的输入框焦点，避免 StageEditorState.update 被提前 return 卡住
		try { PsychUIInputText.focusOn = null; } catch (e:Dynamic) {}
	}

	var directoryDropDown:PsychUIDropDownMenu;
	var uiInputText:PsychUIInputText;
	var hideGirlfriendCheckbox:PsychUICheckBox;
	var zoomStepper:PsychUINumericStepper;
	var cameraSpeedStepper:PsychUINumericStepper;
	var camDadStepperX:PsychUINumericStepper;
	var camDadStepperY:PsychUINumericStepper;
	var camGfStepperX:PsychUINumericStepper;
	var camGfStepperY:PsychUINumericStepper;
	var camBfStepperX:PsychUINumericStepper;
	var camBfStepperY:PsychUINumericStepper;

	function addDataTab()
	{
		var tab_group = UI_box.getTab('Data').menu;

		var objX = 10;
		var objY = 20;
		tab_group.add(new FlxText(objX, objY - 18, 150, 'Compiled Assets:'));

		var folderList:Array<String> = [''];
		#if sys
		for (folder in FileSystem.readDirectory('assets/'))
			if (FileSystem.isDirectory('assets/$folder') && folder != 'shared' && !Mods.ignoreModFolders.contains(folder))
				folderList.push(folder);
		#end

		var saveButton:PsychUIButton = new PsychUIButton(UI_box.width - 90, UI_box.height - 50, 'Save', function()
		{
			saveData();
		});
		tab_group.add(saveButton);

		directoryDropDown = new PsychUIDropDownMenu(objX, objY, folderList, function(sel:Int, selected:String)
		{
			stageLog('旧UI directoryDropDown 触发切换: ' + selected);
			stageJson.directory = selected;
			saveObjectsToJson();
			FlxTransitionableState.skipNextTransIn = FlxTransitionableState.skipNextTransOut = true;
			MusicBeatState.switchState(new StageEditorState(lastLoadedStage, stageJson));
		});
		directoryDropDown.selectedLabel = stageJson.directory;

		objY += 50;
		tab_group.add(new FlxText(objX, objY - 18, 100, 'UI Style:'));
		uiInputText = new PsychUIInputText(objX, objY, 100, stageJson.stageUI != null ? stageJson.stageUI : '', 8);
		uiInputText.onChange = function(old:String, cur:String) stageJson.stageUI = uiInputText.text;

		objY += 30;
		hideGirlfriendCheckbox = new PsychUICheckBox(objX, objY, 'Hide Girlfriend?', 100);
		hideGirlfriendCheckbox.onClick = function()
		{
			stageJson.hide_girlfriend = hideGirlfriendCheckbox.checked;
			gf.visible = !hideGirlfriendCheckbox.checked;
			if (focusRadioGroup.checked > -1)
			{
				var point = focusOnTarget(focusRadioGroup.labels[focusRadioGroup.checked]);
				camFollow.setPosition(point.x, point.y);
			}
		};
		hideGirlfriendCheckbox.checked = !gf.visible;

		objY += 50;
		tab_group.add(new FlxText(objX, objY - 18, 100, 'Camera Offsets:'));

		objY += 20;
		tab_group.add(new FlxText(objX, objY - 18, 100, 'Opponent:'));

		var cx:Float = 0;
		var cy:Float = 0;
		if (stageJson.camera_opponent != null && stageJson.camera_opponent.length > 1)
		{
			cx = stageJson.camera_opponent[0];
			cy = stageJson.camera_opponent[0];
		}
		camDadStepperX = new PsychUINumericStepper(objX, objY, 50, cx, -10000, 10000, 0);
		camDadStepperY = new PsychUINumericStepper(objX + 80, objY, 50, cy, -10000, 10000, 0);
		camDadStepperX.onValueChange = camDadStepperY.onValueChange = function()
		{
			if (stageJson.camera_opponent == null)
				stageJson.camera_opponent = [0, 0];
			stageJson.camera_opponent[0] = camDadStepperX.value;
			stageJson.camera_opponent[1] = camDadStepperY.value;
			_updateCamera();
		};

		objY += 40;
		var cx:Float = 0;
		var cy:Float = 0;
		if (stageJson.camera_girlfriend != null && stageJson.camera_girlfriend.length > 1)
		{
			cx = stageJson.camera_girlfriend[0];
			cy = stageJson.camera_girlfriend[0];
		}
		tab_group.add(new FlxText(objX, objY - 18, 100, 'Girlfriend:'));
		camGfStepperX = new PsychUINumericStepper(objX, objY, 50, cx, -10000, 10000, 0);
		camGfStepperY = new PsychUINumericStepper(objX + 80, objY, 50, cy, -10000, 10000, 0);
		camGfStepperX.onValueChange = camGfStepperY.onValueChange = function()
		{
			if (stageJson.camera_girlfriend == null)
				stageJson.camera_girlfriend = [0, 0];
			stageJson.camera_girlfriend[0] = camGfStepperX.value;
			stageJson.camera_girlfriend[1] = camGfStepperY.value;
			_updateCamera();
		};

		objY += 40;
		var cx:Float = 0;
		var cy:Float = 0;
		if (stageJson.camera_boyfriend != null && stageJson.camera_boyfriend.length > 1)
		{
			cx = stageJson.camera_boyfriend[0];
			cy = stageJson.camera_boyfriend[0];
		}
		tab_group.add(new FlxText(objX, objY - 18, 100, 'Boyfriend:'));
		camBfStepperX = new PsychUINumericStepper(objX, objY, 50, cx, -10000, 10000, 0);
		camBfStepperY = new PsychUINumericStepper(objX + 80, objY, 50, cy, -10000, 10000, 0);
		camBfStepperX.onValueChange = camBfStepperY.onValueChange = function()
		{
			if (stageJson.camera_boyfriend == null)
				stageJson.camera_boyfriend = [0, 0];
			stageJson.camera_boyfriend[0] = camBfStepperX.value;
			stageJson.camera_boyfriend[1] = camBfStepperY.value;
			_updateCamera();
		};

		objY += 50;
		tab_group.add(new FlxText(objX, objY - 18, 100, 'Camera Data:'));
		objY += 20;
		tab_group.add(new FlxText(objX, objY - 18, 100, 'Zoom:'));
		zoomStepper = new PsychUINumericStepper(objX, objY, 0.05, stageJson.defaultZoom, minZoom, maxZoom, 2);
		zoomStepper.onValueChange = function()
		{
			stageJson.defaultZoom = zoomStepper.value;
			FlxG.camera.zoom = stageJson.defaultZoom;
		};

		tab_group.add(new FlxText(objX + 80, objY - 18, 100, 'Speed:'));
		cameraSpeedStepper = new PsychUINumericStepper(objX + 80, objY, 0.1, stageJson.camera_speed != null ? stageJson.camera_speed : 1, 0, 10, 2);
		cameraSpeedStepper.onValueChange = function()
		{
			stageJson.camera_speed = cameraSpeedStepper.value;
			FlxG.camera.followLerp = 0.04 * stageJson.camera_speed;
		};
		FlxG.camera.followLerp = 0.04 * cameraSpeedStepper.value;

		tab_group.add(hideGirlfriendCheckbox);
		tab_group.add(camDadStepperX);
		tab_group.add(camDadStepperY);
		tab_group.add(camGfStepperX);
		tab_group.add(camGfStepperY);
		tab_group.add(camBfStepperX);
		tab_group.add(camBfStepperY);
		tab_group.add(zoomStepper);
		tab_group.add(cameraSpeedStepper);

		tab_group.add(uiInputText);
		tab_group.add(directoryDropDown);
	}

	function _updateCamera()
	{
		if (focusRadioGroup.checked > -1)
		{
			var point = focusOnTarget(focusRadioGroup.labels[focusRadioGroup.checked]);
			camFollow.setPosition(point.x, point.y);
		}
	}

	var colorInputText:PsychUIInputText;
	var nameInputText:PsychUIInputText;
	var imgTxt:FlxText;

	var scaleStepperX:PsychUINumericStepper;
	var scaleStepperY:PsychUINumericStepper;
	var scrollStepperX:PsychUINumericStepper;
	var scrollStepperY:PsychUINumericStepper;
	var angleStepper:PsychUINumericStepper;
	var alphaStepper:PsychUINumericStepper;

	var antialiasingCheckbox:PsychUICheckBox;
	var flipXCheckBox:PsychUICheckBox;
	var flipYCheckBox:PsychUICheckBox;
	var lowQualityCheckbox:PsychUICheckBox;
	var highQualityCheckbox:PsychUICheckBox;

	function getSelected(blockReserved:Bool = true)
	{
		var selected:Int = spriteListRadioGroup.checked;
		if (selected >= 0)
		{
			var spr = stageSprites[spriteListRadioGroup.labels.length - selected - 1];
			if (spr != null && (!blockReserved || !StageData.reservedNames.contains(spr.type)))
				return spr;
		}
		return null;
	}

	function addObjectTab()
	{
		var tab_group = UI_box.getTab('Object').menu;

		var objX = 10;
		var objY = 30;
		tab_group.add(new FlxText(objX, objY - 18, 150, 'Name (for Lua/HScript):'));
		nameInputText = new PsychUIInputText(objX, objY, 120, '', 8);
		nameInputText.customFilterPattern = ~/[^a-zA-Z0-9_\-]*/g;
		nameInputText.onChange = function(old:String, cur:String)
		{
			// change name
			var selected = getSelected();
			if (selected != null)
			{
				var changedName:String = nameInputText.text;
				if (changedName.length < 1)
				{
					showError('Sprite name cannot be empty!');
					return;
				}

				if (StageData.reservedNames.contains(changedName))
				{
					showError('To avoid conflicts, this name cannot be used!');
					return;
				}

				for (basic in stageSprites)
				{
					if (selected != basic && basic.name == changedName)
					{
						showError('Name "$changedName" is already in use!');
						return;
					}
				}

				selected.name = changedName;
				spriteListRadioGroup.checkedRadio.label = selected.name;
				errorTime = 0;
				errorTxt.alpha = 0;
			}
		};
		tab_group.add(nameInputText);

		objY += 35;
		imgTxt = new FlxText(objX, objY - 15, 200, 'Image: ', 8);
		var imgButton:PsychUIButton = new PsychUIButton(objX, objY, 'Change Image', function()
		{
			trace('attempt to load image');
			loadImage();
		});
		tab_group.add(imgButton);
		tab_group.add(imgTxt);

		buttonAnimations = new PsychUIButton(objX + 90, objY, 'Animations', function()
		{
			var selected = getSelected();
			if (selected == null)
				return;

			if (selected.type != 'animatedSprite')
			{
				showError('Only Animated Sprites can hold Animation data.');
				return;
			}

			persistentDraw = false;
			animationEditor.target = selected;
			unsavedProgress = true;
			openSubState(animationEditor);
		});
		tab_group.add(buttonAnimations);

		objY += 45;
		tab_group.add(new FlxText(objX, objY - 18, 80, 'Color:'));
		colorInputText = new PsychUIInputText(objX, objY, 80, 'FFFFFF', 8);
		colorInputText.filterMode = ONLY_ALPHANUMERIC;
		colorInputText.onChange = function(old:String, cur:String)
		{
			// change color
			var selected = getSelected();
			if (selected != null)
				selected.color = colorInputText.text;
		};
		tab_group.add(colorInputText);

		function updateScale()
		{
			// scale
			var selected = getSelected();
			if (selected != null)
				selected.setScale(scaleStepperX.value, scaleStepperY.value);
		}

		objY += 45;
		tab_group.add(new FlxText(objX, objY - 18, 100, 'Scale (X/Y):'));
		scaleStepperX = new PsychUINumericStepper(objX, objY, 0.05, 1, 0.05, 10, 2);
		scaleStepperY = new PsychUINumericStepper(objX + 70, objY, 0.05, 1, 0.05, 10, 2);
		scaleStepperX.onValueChange = scaleStepperY.onValueChange = updateScale;
		tab_group.add(scaleStepperX);
		tab_group.add(scaleStepperY);

		function updateScroll()
		{
			// scroll factor
			var selected = getSelected();
			if (selected != null)
				selected.setScrollFactor(scrollStepperX.value, scrollStepperY.value);
		}

		objY += 40;
		tab_group.add(new FlxText(objX, objY - 18, 150, 'Scroll Factor (X/Y):'));
		scrollStepperX = new PsychUINumericStepper(objX, objY, 0.05, 1, 0, 10, 2);
		scrollStepperY = new PsychUINumericStepper(objX + 70, objY, 0.05, 1, 0, 10, 2);
		scrollStepperX.onValueChange = scrollStepperY.onValueChange = updateScroll;
		tab_group.add(scrollStepperX);
		tab_group.add(scrollStepperY);

		objY += 40;
		tab_group.add(new FlxText(objX, objY - 18, 80, 'Opacity:'));
		alphaStepper = new PsychUINumericStepper(objX, objY, 0.1, 1, 0, 1, 2, true);
		alphaStepper.onValueChange = function()
		{
			// alpha/opacity
			var selected = getSelected();
			if (selected != null)
				selected.alpha = alphaStepper.value;
		};
		tab_group.add(alphaStepper);

		antialiasingCheckbox = new PsychUICheckBox(objX + 90, objY, 'Anti-Aliasing', 80);
		antialiasingCheckbox.onClick = function()
		{
			// antialiasing
			var selected = getSelected();
			if (selected != null)
			{
				if (selected.type != 'square')
					selected.antialiasing = antialiasingCheckbox.checked;
				else
				{
					antialiasingCheckbox.checked = false;
					selected.antialiasing = false;
				}
			}
		};
		tab_group.add(antialiasingCheckbox);

		objY += 40;
		tab_group.add(new FlxText(objX, objY - 18, 80, 'Angle:'));
		angleStepper = new PsychUINumericStepper(objX, objY, 10, 0, 0, 360, 0);
		angleStepper.onValueChange = function()
		{
			// alpha/opacity
			var selected = getSelected();
			if (selected != null)
				selected.angle = angleStepper.value;
		};
		tab_group.add(angleStepper);

		function updateFlip()
		{
			// flip X and flip Y
			var selected = getSelected();
			if (selected != null)
			{
				if (selected.type != 'square')
				{
					selected.flipX = flipXCheckBox.checked;
					selected.flipY = flipYCheckBox.checked;
				}
				else
				{
					flipXCheckBox.checked = flipYCheckBox.checked = false;
					selected.flipX = selected.flipY = false;
				}
			}
		}

		objY += 25;
		flipXCheckBox = new PsychUICheckBox(objX, objY, 'Flip X', 60);
		flipXCheckBox.onClick = updateFlip;
		flipYCheckBox = new PsychUICheckBox(objX + 90, objY, 'Flip Y', 60);
		flipYCheckBox.onClick = updateFlip;
		tab_group.add(flipXCheckBox);
		tab_group.add(flipYCheckBox);

		objY += 45;
		function recalcFilter()
		{
			// low and/or high quality
			var selected = getSelected();
			if (selected != null)
			{
				var filt = 0;
				if (lowQualityCheckbox.checked)
					filt |= LOW_QUALITY;
				if (highQualityCheckbox.checked)
					filt |= HIGH_QUALITY;
				selected.filters = filt;
			}
		};
		tab_group.add(new FlxText(objX + 60, objY - 18, 100, 'Visible in:'));
		lowQualityCheckbox = new PsychUICheckBox(objX, objY, 'Low Quality', 70);
		highQualityCheckbox = new PsychUICheckBox(objX + 90, objY, 'High Quality', 70);
		lowQualityCheckbox.onClick = recalcFilter;
		highQualityCheckbox.onClick = recalcFilter;
		tab_group.add(lowQualityCheckbox);
		tab_group.add(highQualityCheckbox);
	}

	var oppDropdown:PsychUIDropDownMenu;
	var gfDropdown:PsychUIDropDownMenu;
	var plDropdown:PsychUIDropDownMenu;

	function addMetaTab()
	{
		var tab_group = UI_box.getTab('Meta').menu;

		var characterList = Mods.mergeAllTextsNamed('data/characterList.txt');
		var foldersToCheck:Array<String> = Mods.directoriesWithFile(Paths.getSharedPath(), 'characters/');
		for (folder in foldersToCheck)
			for (file in FileSystem.readDirectory(folder))
				if (file.toLowerCase().endsWith('.json'))
				{
					var charToCheck:String = file.substr(0, file.length - 5);
					if (!characterList.contains(charToCheck))
						characterList.push(charToCheck);
				}

		if (characterList.length < 1)
			characterList.push(''); // Prevents crash

		var objX = 10;
		var objY = 20;

		function setMetaData(data:String, char:String)
		{
			if (stageJson._editorMeta == null)
				stageJson._editorMeta = {dad: 'dad', gf: 'gf', boyfriend: 'bf'};
			Reflect.setField(stageJson._editorMeta, data, char);
		}

		oppDropdown = new PsychUIDropDownMenu(objX, objY, characterList, function(sel:Int, selected:String)
		{
			if (selected == null || selected.length < 1)
				return;
			dad.changeCharacter(selected);
			setMetaData('dad', selected);
			repositionDad();
		});
		oppDropdown.selectedLabel = dad.curCharacter;

		objY += 80;
		gfDropdown = new PsychUIDropDownMenu(objX, objY, characterList, function(sel:Int, selected:String)
		{
			if (selected == null || selected.length < 1)
				return;
			gf.changeCharacter(selected);
			setMetaData('gf', selected);
			repositionGirlfriend();
		});
		gfDropdown.selectedLabel = gf.curCharacter;

		objY += 80;
		plDropdown = new PsychUIDropDownMenu(objX, objY, characterList, function(sel:Int, selected:String)
		{
			if (selected == null || selected.length < 1)
				return;
			boyfriend.changeCharacter(selected);
			setMetaData('boyfriend', selected);
			repositionBoyfriend();
		});
		plDropdown.selectedLabel = boyfriend.curCharacter;

		tab_group.add(new FlxText(plDropdown.x, plDropdown.y - 18, 100, 'Player:'));
		tab_group.add(plDropdown);
		tab_group.add(new FlxText(gfDropdown.x, gfDropdown.y - 18, 100, 'Girlfriend:'));
		tab_group.add(gfDropdown);
		tab_group.add(new FlxText(oppDropdown.x, oppDropdown.y - 18, 100, 'Opponent:'));
		tab_group.add(oppDropdown);
	}

	var stageDropDown:PsychUIDropDownMenu;

	function addStageTab()
	{
		var tab_group = UI_stagebox.getTab('Stage').menu;
		var reloadStage:PsychUIButton = new PsychUIButton(140, 10, 'Reload', function()
		{
			stageLog('旧UI Reload 按钮触发切换');
			// 稳定优先：重建整个编辑器状态（与 PlayState 相同的干净加载环境，
			// Flixel 状态转换会统一清理所有资源，避免原地切换的渲染管线崩溃）
			MusicBeatState.switchState(new StageEditorState(lastLoadedStage, StageData.getStageFile(lastLoadedStage)));
		});

		var dummyStage:PsychUIButton = new PsychUIButton(140, 40, 'Load Template', function()
		{
			stageLog('旧UI Load Template 按钮触发切换');
			// 稳定优先：重建整个编辑器状态（干净环境）
			MusicBeatState.switchState(new StageEditorState(lastLoadedStage, StageData.dummy()));
		});
		dummyStage.normalStyle.bgColor = FlxColor.RED;
		dummyStage.normalStyle.textColor = FlxColor.WHITE;

		stageDropDown = new PsychUIDropDownMenu(10, 30, [''], function(sel:Int, selected:String)
		{
			stageLog('旧UI stageDropDown 触发切换: ' + selected);
			var characterPath:String = 'stages/$selected.json';
			var path:String = Paths.getPath(characterPath, TEXT, null, true);
			#if MODS_ALLOWED
			if (FileSystem.exists(path))
			#else
			if (Assets.exists(path))
			#end
			{
				// 稳定优先：重建整个编辑器状态（干净环境，避免原地切换崩溃）
				MusicBeatState.switchState(new StageEditorState(selected, StageData.getStageFile(selected)));
			}
		else
		{
			FlxG.sound.play(Paths.sound('cancelMenu'));
			reloadStageDropDown();
		}
		});
		reloadStageDropDown();

		tab_group.add(new FlxText(stageDropDown.x, stageDropDown.y - 18, 60, 'Stage:'));
		tab_group.add(reloadStage);
		tab_group.add(dummyStage);
		tab_group.add(stageDropDown);
	}

	function updateStageDataUI()
	{
		// input texts
		uiInputText.text = (stageJson.stageUI != null ? stageJson.stageUI : '');
		// checkboxes
		hideGirlfriendCheckbox.checked = (stageJson.hide_girlfriend);
		gf.visible = !hideGirlfriendCheckbox.checked;
		// steppers
		zoomStepper.value = FlxG.camera.zoom = stageJson.defaultZoom;

		if (stageJson.camera_speed != null)
			cameraSpeedStepper.value = stageJson.camera_speed;
		else
			cameraSpeedStepper.value = 1;
		FlxG.camera.followLerp = 0.04 * cameraSpeedStepper.value;

		if (stageJson.camera_opponent != null && stageJson.camera_opponent.length > 1)
		{
			camDadStepperX.value = stageJson.camera_opponent[0];
			camDadStepperY.value = stageJson.camera_opponent[1];
		}
		else
			camDadStepperX.value = camDadStepperY.value = 0;

		if (stageJson.camera_girlfriend != null && stageJson.camera_girlfriend.length > 1)
		{
			camGfStepperX.value = stageJson.camera_girlfriend[0];
			camGfStepperY.value = stageJson.camera_girlfriend[1];
		}
		else
			camGfStepperX.value = camGfStepperY.value = 0;

		if (stageJson.camera_boyfriend != null && stageJson.camera_boyfriend.length > 1)
		{
			camBfStepperX.value = stageJson.camera_boyfriend[0];
			camBfStepperY.value = stageJson.camera_boyfriend[1];
		}
		else
			camBfStepperX.value = camBfStepperY.value = 0;

		if (focusRadioGroup.checked > -1)
		{
			var point = focusOnTarget(focusRadioGroup.labels[focusRadioGroup.checked]);
			camFollow.setPosition(point.x, point.y);
		}
		loadJsonAssetDirectory();
	}

	function updateSelectedUI()
	{
		var selected = getSelected(false);
		if (selected == null)
			return;

		// posTxt 已随旧 UI 隐藏，坐标由新 UI 状态栏显示

		var selected = getSelected();
		if (selected == null)
			return;

		// Texts/Input Texts
		colorInputText.text = selected.color;
		nameInputText.text = selected.name;
		imgTxt.text = 'Image: ' + selected.image;

		// Steppers
		if (selected.type != 'square')
		{
			scaleStepperX.decimals = scaleStepperY.decimals = 2;
			scaleStepperX.max = scaleStepperY.max = 10;
			scaleStepperX.min = scaleStepperY.min = 0.05;
			scaleStepperX.step = scaleStepperY.step = 0.05;
		}
		else
		{
			scaleStepperX.decimals = scaleStepperY.decimals = 0;
			scaleStepperX.max = scaleStepperY.max = 10000;
			scaleStepperX.min = scaleStepperY.min = 50;
			scaleStepperX.step = scaleStepperY.step = 50;
		}
		scaleStepperX.value = selected.scale[0];
		scaleStepperY.value = selected.scale[1];
		scrollStepperX.value = selected.scroll[0];
		scrollStepperY.value = selected.scroll[1];
		angleStepper.value = selected.angle;
		alphaStepper.value = selected.alpha;

		// Checkboxes
		antialiasingCheckbox.checked = selected.antialiasing;
		flipXCheckBox.checked = selected.flipX;
		flipYCheckBox.checked = selected.flipY;
		lowQualityCheckbox.checked = (selected.filters & LOW_QUALITY) == LOW_QUALITY;
		highQualityCheckbox.checked = (selected.filters & HIGH_QUALITY) == HIGH_QUALITY;
	}

	function reloadCharacters()
	{
		if (stageJson._editorMeta != null)
		{
			gf.changeCharacter(stageJson._editorMeta.gf);
			dad.changeCharacter(stageJson._editorMeta.dad);
			boyfriend.changeCharacter(stageJson._editorMeta.boyfriend);
		}
		repositionGirlfriend();
		repositionDad();
		repositionBoyfriend();

		focusRadioGroup.checked = -1;
		FlxG.camera.target = null;
		var point = focusOnTarget('boyfriend');
		FlxG.camera.scroll.set(point.x - FlxG.width / 2, point.y - FlxG.height / 2);
		FlxG.camera.zoom = stageJson.defaultZoom;
		oppDropdown.selectedLabel = dad.curCharacter;
		gfDropdown.selectedLabel = gf.curCharacter;
		plDropdown.selectedLabel = boyfriend.curCharacter;
	}

	function reloadStageDropDown()
	{
		var stageList:Array<String> = [];
		var foldersToCheck:Array<String> = Mods.directoriesWithFile(Paths.getSharedPath(), 'stages/');
		for (folder in foldersToCheck)
			for (file in FileSystem.readDirectory(folder))
				if (file.toLowerCase().endsWith('.json'))
				{
					var stageToCheck:String = file.substr(0, file.length - '.json'.length);
					if (!stageList.contains(stageToCheck))
						stageList.push(stageToCheck);
				}

		if (stageList.length < 1)
			stageList.push('');
		stageDropDown.list = stageList;
		stageDropDown.selectedLabel = lastLoadedStage;
		directoryDropDown.selectedLabel = stageJson.directory;
	}

	function checkUIOnObject()
	{
		if (UI_box.selectedName == 'Object')
		{
			var selected:Int = spriteListRadioGroup.checked;
			if (selected >= 0)
			{
				var spr = stageSprites[spriteListRadioGroup.labels.length - selected - 1];
				if (spr != null && StageData.reservedNames.contains(spr.type))
					UI_box.selectedName = 'Data';
			}
			else
				UI_box.selectedName = 'Data';
		}
	}

	/** 点击 UI_box 标签页时：允许打开 Object，若当前选中角色/无选中则自动选第一个可编辑对象。 */
	function onUITabClick():Void
	{
		if (UI_box.selectedName != 'Object')
			return;

		var labelsLen:Int = spriteListRadioGroup.labels.length;
		for (i in 0...stageSprites.length)
		{
			var spr = stageSprites[i];
			if (spr != null && !StageData.reservedNames.contains(spr.type))
			{
				var target:Int = labelsLen - 1 - i;
				if (target >= 0 && target < labelsLen && spriteListRadioGroup.checked != target)
				{
					spriteListRadioGroup.checked = target;
					updateSelectedUI();
				}
				return;
			}
		}
		// 没有任何可编辑对象：选中列表第一项（可能是角色），面板显示对应内容
		if (labelsLen > 0 && spriteListRadioGroup.checked < 0)
		{
			spriteListRadioGroup.checked = 0;
			updateSelectedUI();
		}
	}

	public function UIEvent(id:String, sender:Dynamic)
	{
		switch (id)
		{
			case PsychUIRadioGroup.CLICK_EVENT, PsychUIBox.CLICK_EVENT:
				if (sender == spriteListRadioGroup)
					checkUIOnObject();
				else if (sender == UI_box)
					onUITabClick();

			case PsychUICheckBox.CLICK_EVENT:
				unsavedProgress = true;

			case PsychUIInputText.CHANGE_EVENT, PsychUINumericStepper.CHANGE_EVENT:
				unsavedProgress = true;
		}
	}

	/** FlxUI 控件事件（新 UI 菜单栏的原生控件变化）。
	 *  架构：新 UI 只负责传数据——把值写入对应的旧 PsychUI 控件并显式调用其回调，
	 *  由旧控件回调（老 UI 的实现层）写 stageJson / 应用相机与缩放。 */
	override function getEvent(id:String, sender:Dynamic, data:Dynamic, ?params:Array<Dynamic>)
	{
		if (id != FlxUIInputText.CHANGE_EVENT && id != FlxUINumericStepper.CHANGE_EVENT)
			return;

		if (sender == uiDefaultZoomStepper)
		{
			if (zoomStepper != null)
			{
				zoomStepper.value = uiDefaultZoomStepper.value;
				if (zoomStepper.onValueChange != null)
					zoomStepper.onValueChange();
			}
			unsavedProgress = true;
		}
		else if (sender == uiCamSpeedStepper)
		{
			if (cameraSpeedStepper != null)
			{
				cameraSpeedStepper.value = uiCamSpeedStepper.value;
				if (cameraSpeedStepper.onValueChange != null)
					cameraSpeedStepper.onValueChange();
			}
			unsavedProgress = true;
		}
		else if (sender == uiCamZoomStepper)
		{
			FlxG.camera.zoom = uiCamZoomStepper.value;
		}
		else if (sender == uiCamBfX || sender == uiCamBfY)
		{
			if (camBfStepperX != null && camBfStepperY != null)
			{
				camBfStepperX.value = uiCamBfX.value;
				camBfStepperY.value = uiCamBfY.value;
				if (camBfStepperX.onValueChange != null)
					camBfStepperX.onValueChange();
			}
			unsavedProgress = true;
		}
		else if (sender == uiCamDadX || sender == uiCamDadY)
		{
			if (camDadStepperX != null && camDadStepperY != null)
			{
				camDadStepperX.value = uiCamDadX.value;
				camDadStepperY.value = uiCamDadY.value;
				if (camDadStepperX.onValueChange != null)
					camDadStepperX.onValueChange();
			}
			unsavedProgress = true;
		}
		else if (sender == uiCamGfX || sender == uiCamGfY)
		{
			if (camGfStepperX != null && camGfStepperY != null)
			{
				camGfStepperX.value = uiCamGfX.value;
				camGfStepperY.value = uiCamGfY.value;
				if (camGfStepperX.onValueChange != null)
					camGfStepperX.onValueChange();
			}
			unsavedProgress = true;
		}
	}

	var errorTime:Float = 0;

	override function update(elapsed:Float)
	{
		diagMark('u');
		// 菜单栏独立驱动（在提前 return 之前执行，保证始终响应）
		if (menuBar != null)
			menuBar.update(elapsed);
		processPendingDestroy();
		processTransition();

		if (createPopup.visible && (FlxG.mouse.justPressedRight || (FlxG.mouse.justPressed && !FlxG.mouse.overlaps(createPopup, camHUD))))
			createPopup.visible = createPopup.active = false;

		for (basic in stageSprites)
			basic.update(curFilters, elapsed);

		super.update(elapsed);

		errorTime = Math.max(0, errorTime - elapsed);
		errorTxt.alpha = errorTime;

		if (PsychUIInputText.focusOn != null)
			return;

		if (FlxG.keys.justPressed.ESCAPE #if android || FlxG.android.justPressed.BACK #end || virtualPad.buttonB.justPressed)
		{
			// 浮层优先：帮助/教程打开时 ESC 只关闭浮层，不退出编辑器
			if ((helpBg != null && helpBg.visible) || (tutorialBg != null && tutorialBg.visible))
			{
				if (helpBg != null && helpBg.visible)
					helpBg.visible = helpTexts.visible = false;
				if (tutorialBg != null && tutorialBg.visible)
					toggleTutorial(false);
				return;
			}
			if (!unsavedProgress)
			{
				MusicBeatState.switchState(new developer.editors.MasterEditorMenu());
				FlxG.sound.playMusic(Paths.music('freakyMenu'));
			}
			else
				openSubState(new ConfirmationPopupSubstate());
			return;
		}

		// 一级菜单快捷键 F1~F6（F1=舞台 F2=对象 F3=相机 F4=视图 F5=文件 F6=帮助）
		if (FlxG.keys.justPressed.F1) toggleMenuHotkey(0);
		else if (FlxG.keys.justPressed.F2) toggleMenuHotkey(1);
		else if (FlxG.keys.justPressed.F3) toggleMenuHotkey(2);
		else if (FlxG.keys.justPressed.F4) toggleMenuHotkey(3);
		else if (FlxG.keys.justPressed.F5) toggleMenuHotkey(4);
		else if (FlxG.keys.justPressed.F6) toggleMenuHotkey(5);

		// 剪贴板 / 撤销快捷键（桌面；菜单输入覆盖层活跃时跳过，避免与输入冲突）
		if (menuBar == null || !menuBar.isInputOverlayActive())
		{
			if (FlxG.keys.pressed.CONTROL)
			{
				if (FlxG.keys.justPressed.Z)
					doUndo();
				else if (FlxG.keys.justPressed.C)
					copySelectedToClipboard();
				else if (FlxG.keys.justPressed.X)
					cutSelectedObject();
				else if (FlxG.keys.justPressed.V)
					pasteClipboard();
			}
			if (FlxG.keys.justPressed.DELETE)
				deleteSelectedObject(true);
		}

		if (FlxG.keys.justPressed.W || virtualPad.buttonV.justPressed)
		{
			// 按 labels 边界 clamp（set_checked 只按 radios 数量 clamp，滚动列表时两者不一致）
			spriteListRadioGroup.checked = Std.int(Math.max(-1, spriteListRadioGroup.checked - 1));
			checkUIOnObject();
			updateSelectedUI();
		}
		else if (FlxG.keys.justPressed.S || virtualPad.buttonD.justPressed)
		{
			var maxChecked:Int = spriteListRadioGroup.labels.length - 1;
			spriteListRadioGroup.checked = Std.int(Math.min(maxChecked, spriteListRadioGroup.checked + 1));
			checkUIOnObject();
			updateSelectedUI();
		}

		// 帮助浮层：桌面改 F7（F1 已用于舞台菜单）；移动端保持虚拟键
		if ((FlxG.keys.justPressed.F7 || virtualPad.buttonF.justPressed) || (helpBg.visible && FlxG.keys.justPressed.ESCAPE))
		{
			if (controls.mobileC)
			{
				virtualPad.forEachAlive(function(button:MobileButton)
				{
					if (button.tag != 'F')
						button.visible = !button.visible;
				});
			}
			helpBg.visible = !helpBg.visible;
			helpTexts.visible = helpBg.visible;
			if (helpBg.visible)
				toggleTutorial(false);
		}
		// 教程浮层：Esc 关闭
		if (tutorialBg != null && tutorialBg.visible && FlxG.keys.justPressed.ESCAPE)
			toggleTutorial(false);

		// 旧 PsychUI 面板全程不可见（hideOldUI），F2/F3 不再切换显示

		if (FlxG.keys.justPressed.F12 || (virtualPad.buttonS.justPressed && !virtualPad.buttonG.justPressed))
			showSelectionQuad = !showSelectionQuad;

		var shiftMult:Float = 1;
		var ctrlMult:Float = 1;
		if (FlxG.keys.pressed.SHIFT || virtualPad.buttonC.pressed)
			shiftMult = 4;
		if (FlxG.keys.pressed.CONTROL)
			ctrlMult = 0.25;

		// CAMERA CONTROLS
		var camX:Float = 0;
		var camY:Float = 0;
		if (FlxG.keys.pressed.J || (virtualPad.buttonLeft.pressed && virtualPad.buttonG.pressed))
			camX -= elapsed * 500 * shiftMult * ctrlMult;
		if (FlxG.keys.pressed.K || (virtualPad.buttonDown.pressed && virtualPad.buttonG.pressed))
			camY += elapsed * 500 * shiftMult * ctrlMult;
		if (FlxG.keys.pressed.L || (virtualPad.buttonRight.pressed && virtualPad.buttonG.pressed))
			camX += elapsed * 500 * shiftMult * ctrlMult;
		if (FlxG.keys.pressed.I || (virtualPad.buttonUp.pressed && virtualPad.buttonG.pressed))
			camY -= elapsed * 500 * shiftMult * ctrlMult;

		if (camX != 0 || camY != 0)
		{
			FlxG.camera.scroll.x += camX;
			FlxG.camera.scroll.y += camY;
			if (FlxG.camera.target != null)
				FlxG.camera.target = null;
			if (focusRadioGroup.checked > -1)
				focusRadioGroup.checked = -1;
		}

		var lastZoom = FlxG.camera.zoom;
		if (FlxG.keys.justPressed.R || virtualPad.buttonZ.justPressed && !FlxG.keys.pressed.CONTROL)
			FlxG.camera.zoom = stageJson.defaultZoom;
		else if (FlxG.keys.pressed.E || virtualPad.buttonX.pressed && FlxG.camera.zoom < maxZoom)
			FlxG.camera.zoom = Math.min(maxZoom, FlxG.camera.zoom + elapsed * FlxG.camera.zoom * shiftMult * ctrlMult);
		else if (FlxG.keys.pressed.Q || virtualPad.buttonY.pressed && FlxG.camera.zoom > minZoom)
			FlxG.camera.zoom = Math.max(minZoom, FlxG.camera.zoom - elapsed * FlxG.camera.zoom * shiftMult * ctrlMult);

		// SPRITE X/Y
		var shiftMult:Float = 1;
		var ctrlMult:Float = 1;
		if (FlxG.keys.pressed.SHIFT || virtualPad.buttonC.pressed)
			shiftMult = 4;
		if (FlxG.keys.pressed.CONTROL)
			ctrlMult = 0.2;

		var moveX:Float = 0;
		var moveY:Float = 0;
		if (!virtualPad.buttonG.pressed)
		{
			if (FlxG.keys.justPressed.LEFT || virtualPad.buttonLeft.justPressed)
				moveX -= 5 * shiftMult * ctrlMult;
			if (FlxG.keys.justPressed.RIGHT || virtualPad.buttonRight.justPressed)
				moveX += 5 * shiftMult * ctrlMult;
			if (FlxG.keys.justPressed.UP || virtualPad.buttonUp.justPressed)
				moveY -= 5 * shiftMult * ctrlMult;
			if (FlxG.keys.justPressed.DOWN || virtualPad.buttonDown.justPressed)
				moveY += 5 * shiftMult * ctrlMult;
		}

		if (FlxG.mouse.pressedRight && (FlxG.mouse.deltaScreenX != 0 || FlxG.mouse.deltaScreenY != 0))
		{
			moveX += FlxG.mouse.deltaScreenX * ctrlMult;
			moveY += FlxG.mouse.deltaScreenY * ctrlMult;
			_updateCamera();
		}

		if (moveX != 0 || moveY != 0)
		{
			var selected:Int = spriteListRadioGroup.checked;
			if (selected < 0)
				return;

			var spr = stageSprites[spriteListRadioGroup.labels.length - selected - 1];
			if (spr != null)
			{
				var displayX:Float, displayY:Float;
				spr.x = displayX = Math.round(spr.x + moveX);
				spr.y = displayY = Math.round(spr.y + moveY);
				var char:Character = cast spr.sprite;
				switch (spr.type)
				{
					case 'boyfriend':
						stageJson.boyfriend[0] = displayX = spr.x - char.positionArray[0];
						stageJson.boyfriend[1] = displayY = spr.y - char.positionArray[1];
					case 'gf':
						stageJson.girlfriend[0] = displayX = spr.x - char.positionArray[0];
						stageJson.girlfriend[1] = displayY = spr.y - char.positionArray[1];
					case 'dad':
						stageJson.opponent[0] = displayX = spr.x - char.positionArray[0];
						stageJson.opponent[1] = displayY = spr.y - char.positionArray[1];
				}
				posTxt.text = 'X: $displayX\nY: $displayY';
			}
		}

		diagMark('U');
		super.update(elapsed);
		diagMark('u2');

		// 新 UI：状态栏 + 动态文本刷新
		if (menuBar != null)
		{
			updateStatusBar();
			menuBar.refreshDynTexts();
		}
	}

	var curFilters:LoadFilters = (LOW_QUALITY) | (HIGH_QUALITY);

	override function draw()
	{
		diagMark('d');
		#if !FLX_DEBUG
		camGame.debugLayer.graphics.clear();
		#end

		// 先画 members（Stage 类背景已在最底层），再画 stageSprites（角色等），
		// 否则同一相机下后画的背景会盖住角色
		super.draw();
		diagMark('P');

		if (persistentDraw || subState == null)
		{
			for (basic in stageSprites)
				if (basic.visible)
					basic.draw(curFilters);

			// 选中框：labels.length 与 stageSprites.length 可能不一致（稀疏数组/滚动列表），
			// checked 越界时 stageSprites[...] 返回 null，直接访问 .sprite 会崩，必须检查
			if (showSelectionQuad && spriteListRadioGroup.checked > -1)
			{
				var selIndex:Int = spriteListRadioGroup.labels.length - spriteListRadioGroup.checked - 1;
				if (selIndex >= 0 && selIndex < stageSprites.length && stageSprites[selIndex] != null)
					drawDebugOnCamera(stageSprites[selIndex].sprite);
			}
		}
		diagMark('D');
	}

	function focusOnTarget(target:String)
	{
		var focusPoint:FlxPoint = FlxPoint.weak(0, 0);
		switch (target)
		{
			case 'boyfriend':
				focusPoint.x += boyfriend.getMidpoint().x - boyfriend.cameraPosition[0] - 100;
				focusPoint.y += boyfriend.getMidpoint().y + boyfriend.cameraPosition[1] - 100;
				if (stageJson.camera_boyfriend != null && stageJson.camera_boyfriend.length > 1)
				{
					focusPoint.x += stageJson.camera_boyfriend[0];
					focusPoint.y += stageJson.camera_boyfriend[1];
				}
			case 'dad':
				focusPoint.x += dad.getMidpoint().x + dad.cameraPosition[0] + 150;
				focusPoint.y += dad.getMidpoint().y + dad.cameraPosition[1] - 100;
				if (stageJson.camera_opponent != null && stageJson.camera_opponent.length > 1)
				{
					focusPoint.x += stageJson.camera_opponent[0];
					focusPoint.y += stageJson.camera_opponent[1];
				}
			case 'gf':
				if (gf.visible)
				{
					focusPoint.x += gf.getMidpoint().x + gf.cameraPosition[0];
					focusPoint.y += gf.getMidpoint().y + gf.cameraPosition[1];
				}

				if (stageJson.camera_girlfriend != null && stageJson.camera_girlfriend.length > 1)
				{
					focusPoint.x += stageJson.camera_girlfriend[0];
					focusPoint.y += stageJson.camera_girlfriend[1];
				}
		}
		return focusPoint;
	}

	function repositionGirlfriend()
	{
		gf.setPosition(stageJson.girlfriend[0], stageJson.girlfriend[1]);
		gf.x += gf.positionArray[0];
		gf.y += gf.positionArray[1];
	}

	function repositionDad()
	{
		dad.setPosition(stageJson.opponent[0], stageJson.opponent[1]);
		dad.x += dad.positionArray[0];
		dad.y += dad.positionArray[1];
	}

	function repositionBoyfriend()
	{
		boyfriend.setPosition(stageJson.boyfriend[0], stageJson.boyfriend[1]);
		boyfriend.x += boyfriend.positionArray[0];
		boyfriend.y += boyfriend.positionArray[1];
	}

	// borrowing from flixel
	public function drawDebugOnCamera(spr:FlxSprite):Void
	{
		if (spr == null || !spr.isOnScreen(FlxG.camera))
			return;

		@:privateAccess
		var rect = spr.getBoundingBox(FlxG.camera);
		var gfx = camGame.debugLayer.graphics;
		gfx.lineStyle(3, FlxColor.LIME, 0.8);
		gfx.drawRect(rect.x, rect.y, rect.width, rect.height);
		gfx.endFill();
	}

	// save

	function saveObjectsToJson()
	{
		stageJson.objects = [];
		for (basic in stageSprites)
			stageJson.objects.push(basic.formatToJson());
	}

	function saveData()
	{
		if (_file != null)
			return;

		saveObjectsToJson();
		var data = haxe.Json.stringify(stageJson, '\t');
		#if mobile
		unsavedProgress = false;
		SUtil.saveContent(lastLoadedStage, '.json', data);
		#else
		// 直接保存到 saves/stage/<舞台名>/（含临时导入的图片/动画文件）
		try
		{
			var exePath = Sys.getCwd().replace('\\', '/');
			var saveDir:String = exePath + 'saves/stage/' + lastLoadedStage + '/';
			if (!FileSystem.exists(saveDir))
				FileSystem.createDirectory(saveDir);
			sys.io.File.saveContent(saveDir + lastLoadedStage + '.json', data);

			// 把临时目录里被对象引用的素材一并输出（图片 + 动画文件）
			var tempDir:String = (StageEditorMetaSprite.tempImageDir != null) ? StageEditorMetaSprite.tempImageDir : '';
			if (tempDir.length > 0 && FileSystem.exists(tempDir))
			{
				var imgDir:String = saveDir + 'images/';
				if (!FileSystem.exists(imgDir))
					FileSystem.createDirectory(imgDir);
				var copied:Array<String> = [];
				for (basic in stageSprites)
				{
					if (basic == null || basic.image == null || basic.image.length < 1)
						continue;
					if (copied.contains(basic.image))
						continue;
					var srcPng:String = tempDir + basic.image + '.png';
					if (FileSystem.exists(srcPng))
					{
						sys.io.File.copy(srcPng, imgDir + basic.image + '.png');
						copied.push(basic.image);
						// 动画文件一并复制
						for (ext in ['.xml', '.json', '.txt'])
						{
							var srcAnim:String = tempDir + basic.image + ext;
							if (FileSystem.exists(srcAnim))
								sys.io.File.copy(srcAnim, imgDir + basic.image + ext);
						}
					}
				}
			}
			unsavedProgress = false;
			showToast('Saved to saves/stage/' + lastLoadedStage + '/', false);
		}
		catch (e:Dynamic)
		{
			showError('Save failed: ' + e);
		}
		#end
	}

	var _file:FileReference;
	var _fileList:FileReferenceList;

	function onSaveComplete(_):Void
	{
		if (_file == null)
			return;
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
		FlxG.log.notice('Successfully saved file.');
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
		FlxG.log.error('Problem saving file');
	}

	var _makeNewSprite = null;

	public function loadImage(onNewSprite:String = null)
	{
		if (_file != null || _fileList != null)
			return;

		_makeNewSprite = onNewSprite;
		_fileList = new FileReferenceList();
		_fileList.addEventListener(Event.SELECT, onLoadComplete);
		_fileList.addEventListener(Event.CANCEL, onLoadCancel);
		_fileList.addEventListener(IOErrorEvent.IO_ERROR, onLoadError);

		final filters = [
			new FileFilter('PNG (Image)', '*.png'),
			new FileFilter('XML (Sparrow)', '*.xml'),
			new FileFilter('JSON (Aseprite)', '*.json'),
			new FileFilter('TXT (Packer)', '*.txt')
		];
		_fileList.browse(filters);
	}

	private function onLoadComplete(_):Void
	{
		if (_fileList == null)
			return;
		_fileList.removeEventListener(Event.SELECT, onLoadComplete);
		_fileList.removeEventListener(Event.CANCEL, onLoadCancel);
		_fileList.removeEventListener(IOErrorEvent.IO_ERROR, onLoadError);

		#if sys
		var paths:Array<String> = [];
		@:privateAccess
		for (fr in _fileList.fileList)
		{
			if (fr != null && fr.__path != null)
				paths.push(fr.__path.replace('\\', '/'));
		}
		if (paths.length > 0)
			processLoadedFiles(paths);
		#else
		trace('File couldn' t be loaded!You aren 't on Desktop, are you?');
		#end
		_fileList = null;
	}

	/** 批量导入用户选择的文件：
	 *  只处理 PNG（每张 PNG 在新建模式下创建一个对象，换图模式只用第一张）；
	 *  任意位置的 PNG 先复制到临时目录 temp/stage_editor/<舞台名>/images/
	 *  （同目录同名 .xml/.json/.txt 动画文件自动连带复制），
	 *  保存舞台时随 JSON 一起输出到 saves/stage/<舞台名>/。 */
	private function processLoadedFiles(paths:Array<String>):Void
	{
		var exePath = Sys.getCwd().replace('\\', '/');
		var imported:Int = 0;
		var firstDone:Bool = false;
		var failMsg:String = null;

		for (raw in paths)
		{
			var fullPath:String = raw.replace('\\', '/');
			if (!fullPath.toLowerCase().endsWith('.png'))
				continue; // 只处理 PNG（XML/JSON/TXT 作为关联动画文件自动连带复制）

			// 换图模式（_makeNewSprite == null）：只处理第一张 PNG
			if (_makeNewSprite == null && firstDone)
				continue;

			var imageToLoad:String = importToTemp(fullPath, exePath);
			if (imageToLoad == null)
			{
				failMsg = 'Failed to import one of the files!';
				continue;
			}

			if (_makeNewSprite == 'animatedSprite'
				&& !Paths.fileExists('images/$imageToLoad.xml', TEXT)
				&& !Paths.fileExists('images/$imageToLoad.json', TEXT)
				&& !Paths.fileExists('images/$imageToLoad.txt', TEXT))
			{
				failMsg = 'No Animation file found for: ' + imageToLoad;
				continue;
			}

			if (_makeNewSprite != null)
				insertMeta(new StageEditorMetaSprite({type: _makeNewSprite, name: findUnoccupiedName()}, new ModchartSprite()));
			var selected = getSelected();
			tryLoadImage(selected, imageToLoad);

			if (_makeNewSprite != null)
			{
				selected.sprite.x = Math.round(FlxG.camera.scroll.x + FlxG.width / 2 - selected.sprite.width / 2);
				selected.sprite.y = Math.round(FlxG.camera.scroll.y + FlxG.height / 2 - selected.sprite.height / 2);
			}
			firstDone = true;
			imported++;
		}
		_makeNewSprite = null;

		if (imported > 0)
			showToast('Imported ' + imported + ' image(s)', false);
		else if (failMsg != null)
			showError(failMsg);
		else
			showError('No PNG files selected!');
	}

	/** 把文件复制进临时 images 目录（如在 images/ 内则跳过复制），返回去扩展名的资源名。 */
	private function importToTemp(fullPath:String, exePath:String):String
	{
		var inAllowed:Bool = fullPath.startsWith(exePath + 'assets/images/') #if MODS_ALLOWED
			|| (fullPath.startsWith(exePath + 'mods/') && fullPath.contains('/images/')) #end;

		if (!inAllowed)
		{
			try
			{
				var fileName:String = fullPath.substr(fullPath.lastIndexOf('/') + 1);
				var tempDir:String = exePath + 'temp/stage_editor/' + lastLoadedStage + '/images/';
				if (!FileSystem.exists(tempDir))
					FileSystem.createDirectory(tempDir);
				sys.io.File.copy(fullPath, tempDir + fileName);
				showToast('Imported to temp: ' + fileName, false);

				// 同目录同名 .xml/.json/.txt 动画文件连带复制
				var base:String = fileName.substr(0, fileName.lastIndexOf('.'));
				for (ext in ['.xml', '.json', '.txt'])
				{
					var srcAnim:String = fullPath.substr(0, fullPath.lastIndexOf('/') + 1) + base + ext;
					if (FileSystem.exists(srcAnim))
					{
						try
						{
							sys.io.File.copy(srcAnim, tempDir + base + ext);
						}
						catch (e:Dynamic) {}
					}
				}
				fullPath = tempDir + fileName;
			}
			catch (e:Dynamic)
			{
				showError('Failed to copy file: ' + e);
				return null;
			}
		}

		return fullPath.substring(fullPath.indexOf('/images/') + '/images/'.length, fullPath.lastIndexOf('.'));
	}

	function tryLoadImage(spr:StageEditorMetaSprite, imgPath:String)
	{
		if (spr == null || StageData.reservedNames.contains(spr.type) || spr.type == 'square' || imgPath == null)
			return;

		spr.image = imgPath;
		updateSelectedUI();
	}

	/**
	 * Called when the save file dialog is cancelled.
	 */
	private function onLoadCancel(_):Void
	{
		if (_fileList == null)
			return;
		_fileList.removeEventListener(Event.SELECT, onLoadComplete);
		_fileList.removeEventListener(Event.CANCEL, onLoadCancel);
		_fileList.removeEventListener(IOErrorEvent.IO_ERROR, onLoadError);
		_fileList = null;
		_makeNewSprite = null;
		trace('Cancelled file loading.');
	}

	/**
	 * Called if there is an error while saving the gameplay recording.
	 */
	private function onLoadError(_):Void
	{
		if (_fileList == null)
			return;
		_fileList.removeEventListener(Event.SELECT, onLoadComplete);
		_fileList.removeEventListener(Event.CANCEL, onLoadCancel);
		_fileList.removeEventListener(IOErrorEvent.IO_ERROR, onLoadError);
		_fileList = null;
		_makeNewSprite = null;
		trace('Problem loading file');
	}

	override function destroy()
	{
		destroySubStates = true;
		animationEditor.destroy();
		for (m in _pendingDestroy)
		{
			try
			{
				FlxDestroyUtil.destroy(m);
			}
			catch (e:Dynamic) {}
		}
		_pendingDestroy = [];
		if (_songWasNull)
		{
			PlayState.SONG = null;
			_songWasNull = false;
		}
		// 恢复全局状态，防止泄漏到游戏（PlayState 从不设置这些静态）：
		// 1. Paths.currentLevel —— 残留 week1/week4 会让游戏图片解析错误
		// 2. StageData.forceNextDirectory —— LoadingState 消费它决定 currentLevel
		// 3. Mods.currentModDirectory —— mod 图片查找的关键
		// 4. StageEditorMetaSprite.tempImageDir —— 编辑器专用临时目录
		Paths.currentLevel = _savedCurrentLevel;
		StageData.forceNextDirectory = _savedForceNextDir;
		Mods.currentModDirectory = _savedModDir;
		StageEditorMetaSprite.tempImageDir = null;
		super.destroy();
	}
}

#if !FLX_DEBUG
class DebugCamera extends PsychCamera
{
	public var debugLayer:Sprite;

	public function new()
	{
		super();

		debugLayer = new Sprite();
		_scrollRect.addChild(debugLayer);
		updateInternalSpritePositions();
	}

	override function updateInternalSpritePositions()
	{
		super.updateInternalSpritePositions();

		if (canvas != null && debugLayer != null)
		{
			debugLayer.x = canvas.x;
			debugLayer.y = canvas.y;

			debugLayer.scaleX = totalScaleX;
			debugLayer.scaleY = totalScaleY;
		}
	}

	override function destroy()
	{
		FlxDestroyUtil.removeChild(_scrollRect, debugLayer);
		debugLayer = null;
		super.destroy();
	}
}
#end

class StageEditorMetaSprite
{
	public var sprite:FlxSprite;
	public var visible(get, set):Bool;

	function get_visible()
		return sprite.visible;

	function set_visible(v:Bool)
		return (sprite.visible = v);

	// basic variables for all types
	public var type:String;

	// variables for all types that aren't Character
	public var name:String;
	public var filters:LoadFilters = (LOW_QUALITY) | (HIGH_QUALITY);
	public var x(get, set):Float;
	public var y(get, set):Float;
	public var alpha(get, set):Float;
	public var angle(get, set):Float;

	function get_x()
		return sprite.x;

	function set_x(v:Float)
		return (sprite.x = v);

	function get_y()
		return sprite.y;

	function set_y(v:Float)
		return (sprite.y = v);

	function get_alpha()
		return sprite.alpha;

	function set_alpha(v:Float)
		return (sprite.alpha = v);

	function get_angle()
		return sprite.angle;

	function set_angle(v:Float)
		return (sprite.angle = v);

	public var color(default, set):String = 'FFFFFF';

	function set_color(v:String)
	{
		sprite.color = CoolUtil.colorFromString(v);
		return (color = v);
	}

	public var image(default, set):String = 'unknown';

	/**
	 * 导入素材的临时目录（形如 temp/stage_editor/<舞台名>/images/，末尾带 /）。
	 * 非 null 且存在同名文件时，set_image 优先从临时目录用 BitmapData 直接加载，
	 * 保存舞台时这些文件会随 JSON 一起输出到 saves/stage/<舞台名>/。
	 */
	public static var tempImageDir:String;

	function set_image(v:String)
	{
		try
		{
			switch (type)
			{
				case 'sprite':
					var tmpPng:String = (tempImageDir != null) ? tempImageDir + v + '.png' : null;
					if (tmpPng != null && FileSystem.exists(tmpPng))
						sprite.loadGraphic(BitmapData.fromFile(tmpPng));
					else
						sprite.loadGraphic(Paths.image(v));
				case 'animatedSprite':
					var tmpBase:String = (tempImageDir != null) ? tempImageDir + v : null;
					if (tmpBase != null && FileSystem.exists(tmpBase + '.png'))
					{
						var bmp:BitmapData = BitmapData.fromFile(tmpBase + '.png');
						if (FileSystem.exists(tmpBase + '.xml'))
							sprite.frames = FlxAtlasFrames.fromSparrow(bmp, Xml.parse(sys.io.File.getContent(tmpBase + '.xml')));
						else if (FileSystem.exists(tmpBase + '.json'))
							sprite.frames = FlxAtlasFrames.fromTexturePackerJson(bmp, haxe.Json.parse(sys.io.File.getContent(tmpBase + '.json')));
						else if (FileSystem.exists(tmpBase + '.txt'))
							sprite.frames = FlxAtlasFrames.fromSpriteSheetPacker(bmp, sys.io.File.getContent(tmpBase + '.txt'));
					}
					else
						sprite.frames = Paths.getAtlas(v);
			}
		}
		sprite.updateHitbox();
		return (image = v);
	}

	public var scroll:Array<Float> = [1, 1];

	public function setScrollFactor(scrX:Null<Float> = null, scrY:Null<Float> = null)
	{
		scroll[0] = (scrX != null ? scrX : scroll[0]);
		scroll[1] = (scrY != null ? scrY : scroll[1]);
		sprite.scrollFactor.set(scroll[0], scroll[1]);
	}

	public var scale:Array<Float> = [1, 1];
	public var antialiasing(default, set):Bool = true;

	function set_antialiasing(v:Bool)
	{
		sprite.antialiasing = (v && ClientPrefs.data.antialiasing);
		return (antialiasing = v);
	}

	public function setScale(wid:Null<Float> = null, hei:Null<Float> = null)
	{
		scale[0] = (wid != null ? wid : scale[0]);
		scale[1] = (hei != null ? hei : scale[1]);
		sprite.scale.set(scale[0], scale[1]);
		sprite.updateHitbox();
	}

	public var flipX(get, set):Bool;
	public var flipY(get, set):Bool;

	function get_flipX()
		return sprite.flipX;

	function set_flipX(v:Bool)
		return (sprite.flipX = (v && type != 'square'));

	function get_flipY()
		return sprite.flipY;

	function set_flipY(v:Bool)
		return (sprite.flipY = (v && type != 'square'));

	// "animatedSprite" only variables
	public var firstAnimation:String;
	public var animations:Array<AnimArray>;

	public function new(data:Dynamic, spr:FlxSprite)
	{
		this.sprite = spr;
		if (data == null)
			return;

		this.type = data.type;
		switch (this.type)
		{
			case 'sprite', 'square', 'animatedSprite':
				for (v in ['name', 'image', 'scale', 'scroll', 'color', 'filters', 'antialiasing'])
				{
					var dat:Dynamic = Reflect.field(data, v);
					if (dat != null)
						Reflect.setField(this, v, dat);
				}

				if (this.type == 'animatedSprite')
				{
					this.animations = data.animations;
					this.firstAnimation = data.firstAnimation;
				}
		}
	}

	public function formatToJson()
	{
		var obj:Dynamic = {type: type};
		switch (type)
		{
			case 'square', 'sprite', 'animatedSprite':
				obj.name = name;
				obj.x = x;
				obj.y = y;
				obj.scale = scale;
				obj.scroll = scroll;
				obj.alpha = alpha;
				obj.angle = angle;
				obj.color = color;
				obj.filters = filters;

				if (type != 'square')
				{
					obj.flipX = flipX;
					obj.flipY = flipY;
					obj.image = image;
					obj.antialiasing = antialiasing;
					if (type == 'animatedSprite')
					{
						obj.animations = animations;
						obj.firstAnimation = firstAnimation;
					}
				}
		}
		return obj;
	}

	public function update(curFilters:LoadFilters, elapsed:Float)
	{
		if ((curFilters & filters) != 0 || StageData.reservedNames.contains(type))
			sprite.update(elapsed);
	}

	public function draw(curFilters:LoadFilters)
	{
		if ((curFilters & filters) != 0 || StageData.reservedNames.contains(type))
			sprite.draw();
	}
}

class StageEditorAnimationSubstate extends MusicBeatSubstate
{
	var bg:FlxSprite;
	var originalZoom:Float;
	var originalCamPoint:FlxPoint;
	var originalPosition:FlxPoint;
	var originalCamTarget:FlxObject;
	var originalAlpha:Float = 1;

	public var target:StageEditorMetaSprite;

	var curAnim:Int = 0;
	var animsTxtGroup:FlxTypedGroup<FlxText>;

	var UI_animationbox:PsychUIBox;
	var camHUD:FlxCamera = cast(FlxG.state, StageEditorState).camHUD;

	public function new()
	{
		super();

		var grid:FlxBackdrop = new FlxBackdrop(FlxGridOverlay.createGrid(50, 50, 100, 100, true, 0xFFAAAAAA, 0xFF666666));
		add(grid);

		animsTxtGroup = new FlxTypedGroup<FlxText>();
		animsTxtGroup.cameras = [camHUD];
		add(animsTxtGroup);

		UI_animationbox = new PsychUIBox(FlxG.width - 320, 20, 300, 250, ['Animations']);
		UI_animationbox.cameras = [camHUD];
		UI_animationbox.scrollFactor.set();
		add(UI_animationbox);
		addAnimationsUI();

		openCallback = function()
		{
			curAnim = 0;
			originalZoom = FlxG.camera.zoom;
			originalCamPoint = FlxPoint.weak(FlxG.camera.scroll.x, FlxG.camera.scroll.y);
			originalPosition = FlxPoint.weak(target.x, target.y);
			originalCamTarget = FlxG.camera.target;
			originalAlpha = target.alpha;
			FlxG.camera.zoom = 0.5;
			FlxG.camera.scroll.set(0, 0);

			target.alpha = 1;
			target.sprite.screenCenter();
			add(target.sprite);
			reloadAnimList();
			trace('Opened substate');
		};

		closeCallback = function()
		{
			FlxG.camera.zoom = originalZoom;
			FlxG.camera.scroll.set(originalCamPoint.x, originalCamPoint.y);
			FlxG.camera.target = originalCamTarget;

			target.x = originalPosition.x;
			target.y = originalPosition.y;
			target.alpha = originalAlpha;
			remove(target.sprite);

			if (target.animations.length > 0)
			{
				if (target.firstAnimation == null)
					target.firstAnimation = target.animations[0].anim;
				playAnim(target.firstAnimation);
			}
		};
	}

	var animationDropDown:PsychUIDropDownMenu;
	var animationInputText:PsychUIInputText;
	var animationNameInputText:PsychUIInputText;
	var animationIndicesInputText:PsychUIInputText;
	var animationFramerate:PsychUINumericStepper;
	var animationLoopCheckBox:PsychUICheckBox;
	var mainAnimTxt:FlxText;

	function addAnimationsUI()
	{
		var tab_group = UI_animationbox.getTab('Animations').menu;

		animationInputText = new PsychUIInputText(15, 85, 80, '', 8);
		animationNameInputText = new PsychUIInputText(animationInputText.x, animationInputText.y + 35, 150, '', 8);
		animationIndicesInputText = new PsychUIInputText(animationNameInputText.x, animationNameInputText.y + 40, 250, '', 8);
		animationFramerate = new PsychUINumericStepper(animationInputText.x + 170, animationInputText.y, 1, 24, 0, 240, 0);
		animationLoopCheckBox = new PsychUICheckBox(animationNameInputText.x + 170, animationNameInputText.y - 1, 'Should it Loop?', 100);

		animationDropDown = new PsychUIDropDownMenu(15, animationInputText.y - 55, [''], function(selectedAnimation:Int, pressed:String)
		{
			var anim:AnimArray = target.animations[selectedAnimation];
			if (anim == null)
				return;

			animationInputText.text = anim.anim;
			animationNameInputText.text = anim.name;
			animationLoopCheckBox.checked = anim.loop;
			animationFramerate.value = anim.fps;

			var indicesStr:String = anim.indices.toString();
			animationIndicesInputText.text = indicesStr.substr(1, indicesStr.length - 2);
		});

		mainAnimTxt = new FlxText(160, animationDropDown.y - 18, 0, 'Main Anim.: ');
		var initAnimButton:PsychUIButton = new PsychUIButton(160, animationDropDown.y, 'Main Animation', function()
		{
			var anim:AnimArray = target.animations[curAnim];
			if (anim == null)
				return;

			mainAnimTxt.text = 'Main Anim.: ${anim.anim}';
			target.firstAnimation = anim.anim;
		});
		tab_group.add(mainAnimTxt);
		tab_group.add(initAnimButton);

		var addUpdateButton:PsychUIButton = new PsychUIButton(40, animationIndicesInputText.y + 35, 'Add/Update', function()
		{
			if (animationInputText.text == '')
				return;

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

			var lastAnim:String = (target.animations[curAnim] != null) ? target.animations[curAnim].anim : '';
			var lastOffsets:Array<Int> = null;
			for (anim in target.animations)
				if (animationInputText.text == anim.anim)
				{
					lastOffsets = anim.offsets;
					cast(target.sprite, ModchartSprite).animOffsets.remove(animationInputText.text);
					target.sprite.animation.remove(animationInputText.text);
					target.animations.remove(anim);
				}

			var addedAnim:AnimArray = {
				anim: animationInputText.text,
				name: animationNameInputText.text,
				fps: Math.round(animationFramerate.value),
				loop: animationLoopCheckBox.checked,
				indices: indices,
				offsets: lastOffsets
			};

			if (addedAnim.indices != null && addedAnim.indices.length > 0)
				target.sprite.animation.addByIndices(addedAnim.anim, addedAnim.name, addedAnim.indices, '', addedAnim.fps, addedAnim.loop);
			else
				target.sprite.animation.addByPrefix(addedAnim.anim, addedAnim.name, addedAnim.fps, addedAnim.loop);

			target.animations.push(addedAnim);
			reloadAnimList();
			playAnim(addedAnim.anim, true);

			curAnim = target.animations.length - 1;
			updateTextColors();
			trace('Added/Updated animation: ' + animationInputText.text);
		});

		var removeButton:PsychUIButton = new PsychUIButton(160, animationIndicesInputText.y + 35, 'Remove', function()
		{
			for (anim in target.animations)
			{
				if (animationInputText.text == anim.anim)
				{
					var targetSprite:ModchartSprite = cast(target.sprite, ModchartSprite);
					var resetAnim:Bool = false;
					if (targetSprite.animation.curAnim != null && anim.anim == targetSprite.animation.curAnim.name)
						resetAnim = true;

					if (targetSprite.animOffsets.exists(anim.anim))
						targetSprite.animOffsets.remove(anim.anim);

					target.animations.remove(anim);
					targetSprite.animation.remove(anim.anim);

					if (resetAnim && target.animations.length > 0)
					{
						curAnim = FlxMath.wrap(curAnim, 0, target.animations.length - 1);
						playAnim(target.animations[curAnim].anim, true);
						updateTextColors();
					}
					else if (target.animations.length < 1)
						target.sprite.animation.curAnim = null;

					trace('Removed animation: ' + animationInputText.text);
					reloadAnimList();
					break;
				}
			}
		});

		tab_group.add(new FlxText(animationDropDown.x, animationDropDown.y - 18, 0, 'Animations:'));
		tab_group.add(new FlxText(animationInputText.x, animationInputText.y - 18, 0, 'Animation name:'));
		tab_group.add(new FlxText(animationFramerate.x, animationFramerate.y - 18, 0, 'Framerate:'));
		tab_group.add(new FlxText(animationNameInputText.x, animationNameInputText.y - 18, 0, 'Animation Symbol Name/Tag:'));
		tab_group.add(new FlxText(animationIndicesInputText.x, animationIndicesInputText.y - 18, 0, 'ADVANCED - Animation Indices:'));

		tab_group.add(animationInputText);
		tab_group.add(animationNameInputText);
		tab_group.add(animationIndicesInputText);
		tab_group.add(animationFramerate);
		tab_group.add(animationLoopCheckBox);
		tab_group.add(addUpdateButton);
		tab_group.add(removeButton);
		tab_group.add(animationDropDown);
	}

	function reloadAnimList()
	{
		if (target.animations == null)
			target.animations = [];
		else if (target.animations.length > 0)
			playAnim(target.animations[0].anim, true);
		curAnim = 0;

		for (text in animsTxtGroup)
			text.kill();

		var spr:ModchartSprite = cast(target.sprite, ModchartSprite);
		if (target.animations.length > 0)
		{
			if (target.firstAnimation == null || !target.sprite.animation.exists(target.firstAnimation))
				target.firstAnimation = target.animations[0].anim;

			mainAnimTxt.text = 'Main Anim.: ${target.firstAnimation}';
		}
		else
		{
			target.firstAnimation = null;
			mainAnimTxt.text = '(No Main Animation)';
		}

		for (num => anim in target.animations)
		{
			var text:FlxText = animsTxtGroup.recycle(FlxText);
			text.x = 10;
			text.y = 32 + (20 * num);
			text.fieldWidth = 400;
			text.fieldHeight = 20;
			if (anim.offsets != null)
				text.text = '${anim.anim}: ${spr.animOffsets.get(anim.anim)}';
			else
				text.text = '${anim.anim}: No offsets';

			text.setFormat(null, 16, FlxColor.WHITE, LEFT, OUTLINE_FAST, FlxColor.BLACK);
			text.scrollFactor.set();
			text.borderSize = 1;
			animsTxtGroup.add(text);
		}
		updateTextColors();
		reloadAnimationDropDown();
	}

	function reloadAnimationDropDown()
	{
		var animList:Array<String> = [];
		for (anim in target.animations)
			animList.push(anim.anim);
		if (animList.length < 1)
			animList.push('NO ANIMATIONS'); // Prevents crash

		animationDropDown.list = animList;
	}

	inline function updateTextColors()
	{
		for (num => text in animsTxtGroup)
		{
			text.color = FlxColor.WHITE;
			if (num == curAnim)
				text.color = FlxColor.LIME;
		}
	}

	function playAnim(name:String, force:Bool = false)
	{
		var spr:ModchartSprite = cast(target.sprite, ModchartSprite);
		spr.playAnim(name, force);
		if (!spr.animOffsets.exists(name))
			spr.updateHitbox();
	}

	final minZoom = 0.25;
	final maxZoom = 2;
	var holdingArrowsTime:Float = 0;
	var holdingArrowsElapsed:Float = 0;
	var holdingFrameTime:Float = 0;
	var holdingFrameElapsed:Float = 0;

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (PsychUIInputText.focusOn != null)
			return;

		// ANIMATION SCROLLING
		if (target.animations.length > 1)
		{
			var changedAnim:Bool = false;
			if (FlxG.keys.justPressed.W || virtualPad.buttonUp.justPressed && (changedAnim = true))
				curAnim--;
			else if (FlxG.keys.justPressed.S || virtualPad.buttonDown.justPressed && (changedAnim = true))
				curAnim++;
			else if (FlxG.keys.justPressed.SPACE)
				changedAnim = true;

			if (changedAnim)
			{
				curAnim = FlxMath.wrap(curAnim, 0, target.animations.length - 1);
				playAnim(target.animations[curAnim].anim, true);
				updateTextColors();
			}
		}

		var shiftMult:Float = 1;
		var ctrlMult:Float = 1;
		var shiftMultBig:Float = 1;
		if (FlxG.keys.pressed.SHIFT || virtualPad.buttonC.pressed)
		{
			shiftMult = 4;
			shiftMultBig = 10;
		}
		if (FlxG.keys.pressed.CONTROL)
			ctrlMult = 0.25;

		// OFFSET
		if (target.sprite.animation.curAnim != null)
		{
			var spr:ModchartSprite = cast(target.sprite, ModchartSprite);
			var anim:String = spr.animation.curAnim.name;
			var changedOffset = false;
			var moveKeysP = controls.mobileC ? [
				virtualPad.buttonLeft.justPressed,
				virtualPad.buttonRight.justPressed,
				virtualPad.buttonUp.justPressed,
				virtualPad.buttonDown.justPressed
			] : [
				FlxG.keys.justPressed.LEFT,
				FlxG.keys.justPressed.RIGHT,
				FlxG.keys.justPressed.UP,
				FlxG.keys.justPressed.DOWN
				];
			var moveKeys = controls.mobileC ? [
				virtualPad.buttonLeft.pressed,
				virtualPad.buttonRight.pressed,
				virtualPad.buttonUp.pressed,
				virtualPad.buttonDown.pressed
			] : [
				FlxG.keys.pressed.LEFT,
				FlxG.keys.pressed.RIGHT,
				FlxG.keys.pressed.UP,
				FlxG.keys.pressed.DOWN
				];
			if (moveKeysP.contains(true) && !virtualPad.buttonG.pressed)
			{
				if (spr.animOffsets.get(anim) != null)
				{
					spr.offset.x += ((moveKeysP[0] ? 1 : 0) - (moveKeysP[1] ? 1 : 0)) * shiftMultBig;
					spr.offset.y += ((moveKeysP[2] ? 1 : 0) - (moveKeysP[3] ? 1 : 0)) * shiftMultBig;
				}
				else
					spr.offset.x = spr.offset.y = 0;
				changedOffset = true;
			}

			if (moveKeys.contains(true) && !virtualPad.buttonG.pressed)
			{
				holdingArrowsTime += elapsed;
				if (holdingArrowsTime > 0.6)
				{
					holdingArrowsElapsed += elapsed;
					while (holdingArrowsElapsed > (1 / 60))
					{
						if (spr.animOffsets.get(anim) != null)
						{
							spr.offset.x += ((moveKeys[0] ? 1 : 0) - (moveKeys[1] ? 1 : 0)) * shiftMultBig;
							spr.offset.y += ((moveKeys[2] ? 1 : 0) - (moveKeys[3] ? 1 : 0)) * shiftMultBig;
						}
						else
							spr.offset.x = spr.offset.y = 0;
						holdingArrowsElapsed -= (1 / 60);
						changedOffset = true;
					}
				}
			}
			else
				holdingArrowsTime = 0;

			if (FlxG.mouse.pressedRight && (FlxG.mouse.deltaScreenX != 0 || FlxG.mouse.deltaScreenY != 0))
			{
				spr.offset.x -= FlxG.mouse.deltaScreenX;
				spr.offset.y -= FlxG.mouse.deltaScreenY;
				changedOffset = true;
			}

			if (FlxG.keys.justPressed.R || virtualPad.buttonZ.justPressed && FlxG.keys.pressed.CONTROL || virtualPad.buttonC.pressed)
			{
				target.animations[curAnim].offsets = null;
				spr.animOffsets.remove(anim);
				spr.updateHitbox();
				animsTxtGroup.members[curAnim].text = '${anim}: No offsets';
			}

			if (changedOffset)
			{
				var offX = Math.round(spr.offset.x);
				var offY = Math.round(spr.offset.y);

				spr.addOffset(anim, offX, offY);
				target.animations[curAnim].offsets = [offX, offY];
				animsTxtGroup.members[curAnim].text = '${anim}: ${spr.animOffsets.get(anim)}';
			}
		}
		else
		{
			holdingArrowsTime = 0;
			holdingArrowsElapsed = 0;
		}

		// CAMERA CONTROLS
		var camX:Float = 0;
		var camY:Float = 0;
		if (FlxG.keys.pressed.J || (virtualPad.buttonLeft.pressed && virtualPad.buttonG.pressed))
			camX -= elapsed * 500 * shiftMult * ctrlMult;
		if (FlxG.keys.pressed.K || (virtualPad.buttonDown.pressed && virtualPad.buttonG.pressed))
			camY += elapsed * 500 * shiftMult * ctrlMult;
		if (FlxG.keys.pressed.L || (virtualPad.buttonRight.pressed && virtualPad.buttonG.pressed))
			camX += elapsed * 500 * shiftMult * ctrlMult;
		if (FlxG.keys.pressed.I || (virtualPad.buttonUp.pressed && virtualPad.buttonG.pressed))
			camY -= elapsed * 500 * shiftMult * ctrlMult;

		if (camX != 0 || camY != 0)
		{
			FlxG.camera.scroll.x += camX;
			FlxG.camera.scroll.y += camY;
		}

		var lastZoom = FlxG.camera.zoom;
		if (FlxG.keys.justPressed.R || virtualPad.buttonZ.justPressed && !FlxG.keys.pressed.CONTROL)
			FlxG.camera.zoom = 0.5;
		else if (FlxG.keys.pressed.E || virtualPad.buttonX.pressed && FlxG.camera.zoom < maxZoom)
			FlxG.camera.zoom = Math.min(maxZoom, FlxG.camera.zoom + elapsed * FlxG.camera.zoom * shiftMult * ctrlMult);
		else if (FlxG.keys.pressed.Q || virtualPad.buttonY.pressed && FlxG.camera.zoom > minZoom)
			FlxG.camera.zoom = Math.max(minZoom, FlxG.camera.zoom - elapsed * FlxG.camera.zoom * shiftMult * ctrlMult);

		if (FlxG.keys.justPressed.ESCAPE #if android || FlxG.android.justReleased.BACK #end || virtualPad.buttonB.justPressed)
		{
			persistentDraw = true;
			close();
		}
	}

	override function draw()
	{
		super.draw();
	}
}

