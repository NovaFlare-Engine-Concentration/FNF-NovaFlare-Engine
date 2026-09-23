package developer.editors;

import haxe.Json;
import haxe.format.JsonParser;
import haxe.io.Bytes;

import lime.media.AudioBuffer;

import openfl.utils.Assets;
import openfl.events.Event;
import openfl.events.IOErrorEvent;
import openfl.media.Sound;
import openfl.geom.Rectangle;
import openfl.net.FileReference;
import openfl.system.System;
import openfl.media.Sound;

import flixel.FlxObject;
import flixel.addons.display.FlxGridOverlay;
import flixel.addons.ui.FlxUI;
import flixel.addons.ui.FlxUICheckBox;
import flixel.addons.ui.FlxUIInputText;
import flixel.addons.ui.FlxUIDropDownMenu;
import flixel.addons.ui.FlxUINumericStepper;
import flixel.addons.ui.FlxUISlider;
import flixel.addons.ui.FlxUITabMenu;
import flixel.group.FlxGroup;
import flixel.ui.FlxButton;
import flixel.util.FlxSort;
import flixel.util.FlxStringUtil;

import general.objects.AttachedSprite;

import substates.Prompt;
import mobile.objects.EditorMobileKeys;

import games.backend.Song;
import games.backend.Section;
import games.backend.StageData;
import games.objects.Note;
import games.objects.StrumNote;
import games.objects.NoteSplash;
import games.objects.HealthIcon;
import games.objects.Character;

@:access(flixel.sound.FlxSound._sound)
@:access(openfl.media.Sound.__buffer)
class ChartingState extends MusicBeatState
{
	public static var noteTypeList:Array<String> = // Used for backwards compatibility with 0.1 - 0.3.2 charts, though, you should add your hardcoded custom note types here too.
		['', 'Alt Animation', 'Hey!', 'Hurt Note', 'GF Sing', 'No Animation'];

	public var ignoreWarnings = false;

	var curNoteTypes:Array<String> = [];
	var undos = [];
	var redos = [];
	var eventStuff:Array<Dynamic> = [
		['', "Nothing. Yep, that's right."],
		[
			'Dadbattle Spotlight',
			"Used in Dad Battle,\nValue 1: 0/1 = ON/OFF,\n2 = Target Dad\n3 = Target BF"
		],
		[
			'Hey!',
			"Plays the \"Hey!\" animation from Bopeebo,\nValue 1: BF = Only Boyfriend, GF = Only Girlfriend,\nSomething else = Both.\nValue 2: Custom animation duration,\nleave it blank for 0.6s"
		],
		[
			'Set GF Speed',
			"Sets GF head bopping speed,\nValue 1: 1 = Normal speed,\n2 = 1/2 speed, 4 = 1/4 speed etc.\nUsed on Fresh during the beatbox parts.\n\nWarning: Value must be integer!"
		],
		[
			'Philly Glow',
			"Exclusive to Week 3\nValue 1: 0/1/2 = OFF/ON/Reset Gradient\n \nNo, i won't add it to other weeks."
		],
		['Kill Henchmen', "For Mom's songs, don't use this please, i love them :("],
		[
			'Add Camera Zoom',
			"Used on MILF on that one \"hard\" part\nValue 1: Camera zoom add (Default: 0.015)\nValue 2: UI zoom add (Default: 0.03)\nLeave the values blank if you want to use Default."
		],
		['BG Freaks Expression', "Should be used only in \"school\" Stage!"],
		['Trigger BG Ghouls', "Should be used only in \"schoolEvil\" Stage!"],
		[
			'Play Animation',
			"Plays an animation on a Character,\nonce the animation is completed,\nthe animation changes to Idle\n\nValue 1: Animation to play.\nValue 2: Character (Dad, BF, GF)"
		],
		[
			'Camera Follow Pos',
			"Value 1: X\nValue 2: Y\n\nThe camera won't change the follow point\nafter using this, for getting it back\nto normal, leave both values blank."
		],
		[
			'Alt Idle Animation',
			"Sets a specified suffix after the idle animation name.\nYou can use this to trigger 'idle-alt' if you set\nValue 2 to -alt\n\nValue 1: Character to set (Dad, BF or GF)\nValue 2: New suffix (Leave it blank to disable)"
		],
		[
			'Screen Shake',
			"Value 1: Camera shake\nValue 2: HUD shake\n\nEvery value works as the following example: \"1, 0.05\".\nThe first number (1) is the duration.\nThe second number (0.05) is the intensity."
		],
		[
			'Change Character',
			"Value 1: Character to change (Dad, BF, GF)\nValue 2: New character's name"
		],
		[
			'Change Scroll Speed',
			"Value 1: Scroll Speed Multiplier (1 is default)\nValue 2: Time it takes to change fully in seconds."
		],
		['Set Property', "Value 1: Variable name\nValue 2: New value"],
		[
			'Play Sound',
			"Value 1: Sound file name\nValue 2: Volume (Default: 1), ranges from 0 to 1"
		],
		[
			'Key change(more key)',
			"Changes the visible key count during gameplay.\nValue 1: Number of keys to display (e.g., 10 for 10K)\nValue 2: Transition time in seconds (Default: 1s)"
		]
	];

	var _file:FileReference;

	var UI_box:FlxUITabMenu;

	public static var isFreePlay:Bool = false;
	public static var goToPlayState:Bool = false;

	/**
	 * Array of notes showing when each section STARTS in STEPS
	 * Usually rounded up??
	 */
	public static var curSec:Int = 0;

	public static var lastSection:Int = 0;
	private static var lastSong:String = '';

	var bpmTxt:FlxText;

	// 提升为类变量的 UI 控件（用于注册到菜单系统）
	var songBpmStepper:FlxUINumericStepper;
	var stepperSpeed:FlxUINumericStepper;
	var stepperMania:FlxUINumericStepper;
	var player1DropDown:FlxUIDropDownMenu;
	var gfVersionDropDown:FlxUIDropDownMenu;
	var player2DropDown:FlxUIDropDownMenu;
	var selectedEventIdx:Int = -1;

	var camPos:FlxObject;
	var strumLine:FlxSprite;
	var quant:AttachedSprite;
	var strumLineNotes:FlxTypedGroup<StrumNote>;
	var curSong:String = 'Test';
	var amountSteps:Int = 0;
	var bullshitUI:FlxGroup;

	var highlight:FlxSprite;

	public static var GRID_SIZE:Int = 40;

	var CAM_OFFSET:Int = 360;

	var eventIcon:FlxSprite;
	var dummyArrow:FlxSprite;

	var curRenderedSustains:FlxTypedGroup<FlxSprite>;
	var curRenderedNotes:FlxTypedGroup<Note>;
	var curRenderedNoteType:FlxTypedGroup<FlxText>;

	var nextRenderedSustains:FlxTypedGroup<FlxSprite>;
	var nextRenderedNotes:FlxTypedGroup<Note>;

	var gridBG:FlxSprite;
	var nextGridBG:FlxSprite;

	var daquantspot = 0;
	var curEventSelected:Int = 0;
	var curUndoIndex = 0;
	var curRedoIndex = 0;
	// 事件类型下拉：当前 hover 的选项索引（-1 = 未 hover），菜单里显示事件信息用
	var hoveringEventIdx:Int = -1;
	var _song:SwagSong;
	/*
	 * WILL BE THE CURRENT / LAST PLACED NOTE
	**/
	var curSelectedNote:Array<Dynamic> = null;

	var playbackSpeed:Float = 1;

	var vocals:FlxSound = null;
	var opponentVocals:FlxSound = null;

	var leftIcon:HealthIcon;
	var rightIcon:HealthIcon;

	var value1InputText:FlxUIInputText;
	var value2InputText:FlxUIInputText;
	var currentSongName:String;

	var zoomTxt:FlxText;

	// Adobe 风格顶栏菜单（替代 zoomTxt 的零散显示）
	var menuBar:ChartEditorMenuBar;
	#if (cpp && windows)
	var windowChrome:EditorChromeUI;
	var modInfoPopup:general.objects.ModInfoPopup;
	var camHUD:flixel.FlxCamera;
	#end

	var zoomList:Array<Float> = [0.25, 0.5, 1, 2, 3, 4, 6, 8, 12, 16, 24];
	var curZoom:Int = 2;

	private var blockPressWhileTypingOn:Array<FlxUIInputText> = [];
	private var blockPressWhileTypingOnStepper:Array<FlxUINumericStepper> = [];
	private var blockPressWhileScrolling:Array<FlxUIDropDownMenu> = [];

	var waveformSprite:FlxSprite;
	var gridLayer:FlxTypedGroup<FlxSprite>;

	public static var quantization:Int = 16;
	public static var curQuant = 3;

	public var quantizations:Array<Int> = [4, 8, 12, 16, 20, 24, 32, 48, 64, 96, 192];

	var text:String = "";

	public static var vortex:Bool = false;

	var leftKeys:Int = 4;
	var rightKeys:Int = 4;
	var totalKeys:Int = 8;
	var gridOffsetX:Float = 0;

	public var mouseQuant:Bool = false;

	override function create()
	{
		// 强制刷新语言数据，确保 charting 等新分组被正确加载
		general.backend.language.Language.resetData();

		if (PlayState.SONG != null)
		{
			_song = PlayState.SONG;
		}
		else
		{
			Difficulty.resetList();
			_song = {
				song: 'Test',
				notes: [],
				events: [],
				bpm: 150.0,
				needsVoices: true,
				player1: 'bf',
				player2: 'dad',
				gfVersion: 'gf',
				speed: 1,
				stage: 'stage',
				mania: 3,
				format: 'na'
			};
			addSection();
			PlayState.SONG = _song;
		}

		// ★ 进入编辑器时数据与 mania 视为配套：先按数据自检 mania（防 json 缺 mania 字段默认 4K），
		//   再只重算键数——绝不平移数据（平移只用于用户主动改 mania，见 updateKeyAmounts）
		autoFixManiaFromData();
		recalcKeyAmounts();

		new FlxTimer().start(60, function(tmr:FlxTimer)
		{
			timeCheck = true;
		}, 0);

		// Paths.clearMemory();

		#if DISCORD_ALLOWED
		// Updating Discord Rich Presence
		DiscordClient.changePresence("Chart Editor", StringTools.replace(_song.song, '-', ' '));
		#end

		vortex = FlxG.save.data.chart_vortex;
		ignoreWarnings = FlxG.save.data.ignoreWarnings;
		var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.antialiasing = ClientPrefs.data.antialiasing;
		bg.scrollFactor.set();
		bg.color = 0xFF12141A; // ★ NovaFlare 规范：页面底层背景
		add(bg);

		gridLayer = new FlxTypedGroup<FlxSprite>();
		add(gridLayer);

		waveformSprite = new FlxSprite(GRID_SIZE, 0).makeGraphic(1, 1, 0x00FFFFFF);
		add(waveformSprite);

		eventIcon = new FlxSprite(-GRID_SIZE - 5, -90).loadGraphic(Paths.image('eventArrow'));
		eventIcon.antialiasing = ClientPrefs.data.antialiasing;
		leftIcon = new HealthIcon('bf');
		rightIcon = new HealthIcon('dad');
		eventIcon.scrollFactor.set(1, 1);
		leftIcon.scrollFactor.set(1, 1);
		rightIcon.scrollFactor.set(1, 1);

		eventIcon.setGraphicSize(30, 30);
		leftIcon.setGraphicSize(0, 45);
		rightIcon.setGraphicSize(0, 45);

		add(eventIcon);
		add(leftIcon);
		add(rightIcon);

		// ★ 头像初始位置统一由 positionSideIcons 负责（makeStrumNotes / reloadGridLayer / updateHeads 都会调用）
		positionSideIcons();

		curRenderedSustains = new FlxTypedGroup<FlxSprite>();
		curRenderedNotes = new FlxTypedGroup<Note>();
		curRenderedNoteType = new FlxTypedGroup<FlxText>();

		nextRenderedSustains = new FlxTypedGroup<FlxSprite>();
		nextRenderedNotes = new FlxTypedGroup<Note>();

		FlxG.mouse.visible = true;
		// FlxG.save.bind('funkin', CoolUtil.getSavePath());

		// addSection();

		// sections = _song.notes;

		updateJsonData();
		currentSongName = Paths.formatToSongPath(_song.song);
		loadSong();
		// ★ 先预热 Note 贴图/动画缓存：reloadGridLayer 内部的 updateGrid 会创建 Note，
		//   若此时 loadedNote 还是空的，reloadPath('') 会算出空 skin 并缓存空贴图 →
		//   启动后第一次打开编谱器时所有音符显示第一帧（全左箭头）。
		//   （原顺序：makeStrumNotes 里的 StrumNote 才会触发 Note.init，但它在 reloadGridLayer 之后）
		Note.init();
		reloadGridLayer();
		Conductor.bpm = _song.bpm;
		Conductor.mapBPMChanges(_song);
		if (curSec >= _song.notes.length)
			curSec = _song.notes.length - 1;

		// 原生谱面信息文本（时间/Section/Beat/Step/Beat Snap/Move）已由顶栏状态栏替代，直接隐藏
		bpmTxt = new FlxText(10, 75, 0, "", 16);
		bpmTxt.scrollFactor.set();
		bpmTxt.visible = false;
		add(bpmTxt);

		strumLine = new FlxSprite(0, 50).makeGraphic(Std.int(GRID_SIZE * (totalKeys + 1)), 4);
		add(strumLine);

		quant = new AttachedSprite('chart_quant', 'chart_quant');
		quant.animation.addByPrefix('q', 'chart_quant', 0, false);
		quant.animation.play('q', true, false, 0);
		quant.sprTracker = strumLine;
		quant.xAdd = -32;
		quant.yAdd = 8;
		add(quant);

		strumLineNotes = new FlxTypedGroup<StrumNote>();
		makeStrumNotes();
		add(strumLineNotes);

		camPos = new FlxObject(0, 0, 1, 1);
		camPos.setPosition(strumLine.x + CAM_OFFSET, strumLine.y);

		dummyArrow = new FlxSprite().makeGraphic(GRID_SIZE, GRID_SIZE);
		dummyArrow.antialiasing = ClientPrefs.data.antialiasing;
		add(dummyArrow);

		var tabs = [
			{name: "Song", label: 'Song'},
			{name: "Section", label: 'Section'},
			{name: "Note", label: 'Note'},
			{name: "Events", label: 'Events'},
			{name: "Charting", label: 'Charting'},
			{name: "Data", label: 'Data'},
		];

		// ★ UI_box 仅存为逻辑引用（tab 管理），不加入场景，不渲染
		// widget 全部独立存在，不依赖 FlxGroup 容器
		UI_box = new FlxUITabMenu(null, tabs, true);
		UI_box.resize(300, 400);

		if (controls.mobileC)
		{
			text = "Up/Down - Change Conductor's strum time
		\nLeft/Right - Go to the previous/next section
		\nHold Y to move 4x faster
		\nZ/D - Zoom in/out
		\n
		\nC - Test your chart inside Chart Editor
		\nA - Play your chart
		\nUp/Down (right) - Decrease/Increase Note Sustain Length
		\nX - Stop/Resume song";
		}
		else
		{
			text = "W/S or Mouse Wheel - Change Conductor's strum time
		\nA/D - Go to the previous/next section
		\nLeft/Right - Change Snap
		\nUp/Down - Change Conductor's Strum Time with Snapping"
				+ #if FLX_PITCH "\nLeft Bracket / Right Bracket - Change Song Playback Rate (SHIFT to go Faster)
		\nALT + Left Bracket / Right Bracket - Reset Song Playback Rate"
				+ #end "\nHold Shift to move 4x faster
		\nZ/X - Zoom in/out
		\n
		\nEsc - Test your chart inside Chart Editor
		\nEnter - Play your chart
		\nQ/E - Decrease/Increase Note Sustain Length
		\nSpace - Stop/Resume song";
		}

		// 操作提示已移到【帮助】菜单，不再在屏幕上显示 tipText

		addSongUI();
		addSectionUI();
		addNoteUI();
		addEventsUI();
		addChartingUI();
		addDataUI();
		updateHeads();
		updateWaveform();

		// ===== 旧 FlxUITabMenu 不再加入场景，无需显式隐藏 =====

		add(curRenderedSustains);
		add(curRenderedNotes);
		add(curRenderedNoteType);
		add(nextRenderedSustains);
		add(nextRenderedNotes);

		if (lastSong != currentSongName)
		{
			changeSection();
		}
		lastSong = currentSongName;

		// 原版 zoomTxt（屏幕左上角单独一行）已废弃；改为整条顶栏 + 状态栏
		// zoomTxt 字段仍保留，updateZoom() 内会更新 menuBar.statusBar 的 zoom 显示
		zoomTxt = new FlxText(10, 10, 0, "Zoom: 1 / 1", 16);
		zoomTxt.scrollFactor.set();
		zoomTxt.visible = false;
		add(zoomTxt);

		// ===== 顶栏菜单栏（Adobe 风格）=====
		menuBar = new ChartEditorMenuBar();
		menuBar.scrollFactor.set();
		menuBar.uiCamera = FlxG.camera;
		menuBar.onSelectTab = function(idx:Int) {
			UI_box.selected_tab = idx;
		};
		menuBar.onPlaytest = function(testMode:Bool) {
			if (testMode) startPlaytest();
			else startNormalPlay();
		};
		menuBar.onAction = function(actionKey:String) {
			handleMenuAction(actionKey);
		};
		// ★ 事件下拉 hover：悬停在选项上时在菜单里显示该事件的名字+描述
		menuBar.onDropdownHoverOption = function(ctrl:Dynamic, optIdx:Int) {
			if (ctrl == null || ctrl.key != 'w_event_type') return;
			hoveringEventIdx = optIdx;
			menuBar.refreshDynTexts();
		};
		// ★ 事件信息动态文本行（菜单里事件类型下拉下方）
		menuBar.registerDynText('dyn_event_info', function():String {
			var idx:Int = hoveringEventIdx;
			if (idx < 0)
			{
				idx = 0;
				var parsed:Null<Int> = null;
				try { parsed = Std.parseInt(eventDropDown.selectedId); } catch (e:Dynamic) {}
				if (parsed != null) idx = parsed;
			}
			if (idx < 0 || idx >= eventStuff.length) return '';
			var name:String = eventStuff[idx][0];
			var desc:String = eventStuff[idx][1];
			if (desc == null) desc = '';
			// ★ 描述完整返回（右侧信息面板高度弹性自适应，不截断成 …）
			return (name != null && name != '') ? (name + '\n' + desc) : desc;
		});
		// ★ 菜单打开后刷新 widget 显示值
		//   widget 在 visible=false 时被赋值后显示不会刷新，需要在菜单打开时强制同步
		menuBar.onMenuOpened = function(menuKey:String) {
			refreshMenuWidgets(menuKey);
		};
		// 不再需要 onRequestUIBox —— menuBar 自己管理 widget 面板的显示/隐藏

		// 注册 widget 引用（仅用于下拉菜单显示状态文本）
		menuBar.registerWidget('w_metronome', metronome);
		menuBar.registerWidget('w_autoscroll', disableAutoScrolling);
		menuBar.registerWidget('w_waveform_inst', waveformUseInstrumental);
		menuBar.registerWidget('w_waveform_main', waveformUseVoices);
		menuBar.registerWidget('w_waveform_opp', waveformUseOppVoices);
		menuBar.registerWidget('w_mute_inst', check_mute_inst);
		menuBar.registerWidget('w_mute_main', check_mute_vocals);
		menuBar.registerWidget('w_mute_opp', check_mute_vocals_opponent);
		menuBar.registerWidget('w_vortex', check_vortex);
		menuBar.registerWidget('w_ignore_warnings', check_warnings);
		menuBar.registerWidget('w_sfx_bf', playSoundBf);
		menuBar.registerWidget('w_sfx_opp', playSoundDad);
		menuBar.registerWidget('w_no_rgb', check_disableNoteRGB);
		menuBar.registerWidget('w_must_hit', check_mustHitSection);
		menuBar.registerWidget('w_gf_section', check_gfSection);
		menuBar.registerWidget('w_alt_anim', check_altAnim);
		menuBar.registerWidget('w_change_bpm', check_changeBPM);
		menuBar.registerWidget('w_include_notes', check_notesSec);
		menuBar.registerWidget('w_include_events', check_eventsSec);
		menuBar.registerWidget('w_has_voice', check_voices);

		menuBar.registerWidget('w_bpm_stepper', metronomeStepper);
		menuBar.registerWidget('w_metronome_offset', metronomeOffsetStepper);
		menuBar.registerWidget('w_inst_volume', instVolume);
		menuBar.registerWidget('w_voices_volume', voicesVolume);
		menuBar.registerWidget('w_voices_opp_volume', voicesOppVolume);
		menuBar.registerWidget('w_beats_per_section', stepperBeats);
		menuBar.registerWidget('w_section_bpm', stepperSectionBPM);
		menuBar.registerWidget('w_copy_beat', copyBeatStepper);
		menuBar.registerWidget('w_sus_length', stepperSusLength);
		menuBar.registerWidget('w_strum_time', strumTimeInputText);
		menuBar.registerWidget('w_note_type', noteTypeDropDown);
		menuBar.registerWidget('w_event_type', eventDropDown);
		menuBar.registerWidget('w_value1', value1InputText);
		menuBar.registerWidget('w_value2', value2InputText);
		menuBar.registerWidget('w_song_title', UI_songTitle);
		menuBar.registerWidget('w_bpm', songBpmStepper);
		menuBar.registerWidget('w_speed', stepperSpeed);
		menuBar.registerWidget('w_mania', stepperMania);
		menuBar.registerWidget('w_stage', stageDropDown);
		menuBar.registerWidget('w_player1', player1DropDown);
		menuBar.registerWidget('w_gf', gfVersionDropDown);
		menuBar.registerWidget('w_player2', player2DropDown);
		menuBar.registerWidget('w_go_char', gameOverCharacterInputText);
		menuBar.registerWidget('w_go_sound', gameOverSoundInputText);
		menuBar.registerWidget('w_go_loop', gameOverLoopInputText);
		menuBar.registerWidget('w_go_end', gameOverEndInputText);
		menuBar.registerWidget('w_note_skin', noteSkinInputText);
		menuBar.registerWidget('w_note_splash', noteSplashesInputText);
		menuBar.registerWidget('w_difficulty', difficultyInputText);

		add(menuBar);

		// ===== 控件加入场景 =====
		addLegacyWidgetsToScene();
		// ===== 自绘菜单系统接管 UI：旧 6 列布局的原生控件全部隐藏（只作数据源）=====
		hideAllLegacyWidgets();

		updateGrid();

		addVirtualPad(ChartingStateC, ChartingStateC);

		super.create();

		#if (cpp && windows)
		// Charting 主相机跟随网格滚动，自绘窗口条必须挂独立的固定 HUD 相机。
		// 注意：必须在 super.create() 之后创建 —— MusicBeatState.create 里的
		// initPsychCamera() 会 FlxG.cameras.reset，提前创建会被清掉。
		camHUD = new flixel.FlxCamera();
		camHUD.bgColor.alpha = 0;
		flixel.FlxG.cameras.add(camHUD, false);

		// 引擎自绘窗口控制组（右上角：图标+标题 / - □ ×，可拖动窗口）
		windowChrome = new EditorChromeUI();
		windowChrome.scrollFactor.set();
		windowChrome.cameras = [camHUD];
		add(windowChrome);
		// 点击标题 → Mod 信息下拉面板
		modInfoPopup = new general.objects.ModInfoPopup();
		modInfoPopup.scrollFactor.set();
		modInfoPopup.cameras = [camHUD];
		add(modInfoPopup);
		windowChrome.onTitleClick = () -> modInfoPopup.openUnder(windowChrome);
		// 顶栏左侧「退出 编谱器」按钮
		windowChrome.setupExitButton('chartEditor', doExitEditor);
		#end
	}

	/** 6 列从左到右，每列控件纯纵向排列。不用容器，直接裸坐标。 */
	function layoutAllWidgetsVertical():Void
	{
		var colCount:Int = 6;
		var colW:Float = FlxG.width / colCount;
		var startY:Float = ChartEditorMenuBar.BAR_HEIGHT + ChartEditorMenuBar.STATUS_HEIGHT + 8;
		var gapY:Float = 26;
		var cursors:Array<Float> = [startY, startY, startY, startY, startY, startY];

		function placeIn(col:Int, w:Dynamic):Void {
			if (w == null) return;
			try {
				try { w.scrollFactor.set(0, 0); } catch(e:Dynamic) {}
				try { w.setScrollFactor(0, 0); } catch(e:Dynamic) {}
				w.x = col * colW + 8;
				w.y = cursors[col];
				w.visible = true;
				cursors[col] += Math.max(w.height + 4, gapY);
			} catch(e:Dynamic) {}
		}

		// col 0 (最左): 歌曲
		placeIn(0, UI_songTitle);
		placeIn(0, check_voices);
		placeIn(0, songBpmStepper);
		placeIn(0, stepperSpeed);
		placeIn(0, stepperMania);
		placeIn(0, stageDropDown);
		placeIn(0, player1DropDown);
		placeIn(0, gfVersionDropDown);
		placeIn(0, player2DropDown);

		// col 1: 小节
		placeIn(1, check_mustHitSection);
		placeIn(1, check_gfSection);
		placeIn(1, check_altAnim);
		placeIn(1, stepperBeats);
		placeIn(1, check_changeBPM);
		placeIn(1, stepperSectionBPM);
		placeIn(1, check_notesSec);
		placeIn(1, check_eventsSec);

		// col 2: 音符
		placeIn(2, stepperSusLength);
		placeIn(2, strumTimeInputText);
		placeIn(2, noteTypeDropDown);

		// col 3: 事件
		placeIn(3, eventDropDown);
		placeIn(3, value1InputText);
		placeIn(3, value2InputText);

		// col 4: 谱面
		placeIn(4, metronome);
		placeIn(4, disableAutoScrolling);
		placeIn(4, metronomeStepper);
		placeIn(4, metronomeOffsetStepper);
		placeIn(4, waveformUseInstrumental);
		placeIn(4, waveformUseVoices);
		placeIn(4, waveformUseOppVoices);
		placeIn(4, check_mute_inst);
		placeIn(4, check_mute_vocals);
		placeIn(4, check_mute_vocals_opponent);
		placeIn(4, check_vortex);
		placeIn(4, check_warnings);
		placeIn(4, playSoundBf);
		placeIn(4, playSoundDad);
		placeIn(4, instVolume);
		placeIn(4, voicesVolume);
		placeIn(4, voicesOppVolume);

		// col 5 (最右): 数据
		placeIn(5, gameOverCharacterInputText);
		placeIn(5, gameOverSoundInputText);
		placeIn(5, gameOverLoopInputText);
		placeIn(5, gameOverEndInputText);
		placeIn(5, check_disableNoteRGB);
		placeIn(5, noteSkinInputText);
		placeIn(5, noteSplashesInputText);
	}
	function hideAllLegacyWidgets():Void
	{
		// ---- CheckBox ----
		var checks:Array<Dynamic> = [
			check_mute_inst, check_mute_vocals, check_mute_vocals_opponent,
			check_vortex, check_warnings, playSoundBf, playSoundDad,
			check_voices, check_eventsSec, check_notesSec, check_disableNoteRGB,
			waveformUseInstrumental, waveformUseVoices, waveformUseOppVoices,
			check_mustHitSection, check_gfSection, check_altAnim, check_changeBPM,
			metronome, disableAutoScrolling, mouseScrollingQuant
		];
		for (c in checks) if (c != null) EditorInputStyle.deepHide(c);

		// ---- InputText ----
		var inputs:Array<Dynamic> = [
			UI_songTitle, difficultyInputText, value1InputText, value2InputText, strumTimeInputText,
			gameOverCharacterInputText, gameOverSoundInputText, gameOverLoopInputText, gameOverEndInputText,
			noteSkinInputText, noteSplashesInputText
		];
		for (i in inputs) if (i != null) EditorInputStyle.deepHide(i);

		// ---- NumericStepper ----
		var steppers:Array<Dynamic> = [
			songBpmStepper, stepperSpeed, stepperMania,
			metronomeStepper, metronomeOffsetStepper,
			instVolume, voicesVolume, voicesOppVolume,
			stepperBeats, stepperSectionBPM, stepperSusLength
		];
		for (s in steppers) if (s != null) EditorInputStyle.deepHide(s);

		// ---- DropDown ----
		var drops:Array<Dynamic> = [
			player1DropDown, gfVersionDropDown, player2DropDown,
			stageDropDown, noteTypeDropDown, eventDropDown
		];
		for (d in drops) if (d != null) EditorInputStyle.deepHide(d);

		// ---- 零散 FlxText（事件描述等） ----
		if (descText != null) { descText.visible = false; descText.active = false; }
		if (selectedEventText != null) { selectedEventText.visible = false; selectedEventText.active = false; }
		// sliderRate（如果有）
		#if FLX_PITCH
		if (sliderRate != null) try { sliderRate.visible = false; sliderRate.active = false; } catch(e) {}
		#end
	}

	/**
	 * 与 BACKSPACE / B 键等价的退出动作（顶栏「退出 编谱器」按钮共用）：
	 *   - 自动 autosave 一份
	 *   - 还原 PlayState.chartingMode / isFreePlay 状态
	 *   - 回到 MasterEditorMenu 或 FreeplayState（取决于 isFreePlay）
	 *   - 播放 freakyMenu BGM
	 */
	function doExitEditor():Void
	{
		autosaveSong();
		PlayState.chartingMode = false;
		if (!isFreePlay)
			MusicBeatState.switchState(new developer.editors.MasterEditorMenu());
		else
			MusicBeatState.switchState(new states.freeplayState.FreeplayState());
		isFreePlay = false;
		FlxG.sound.playMusic(Paths.music('freakyMenu'));
		FlxG.mouse.visible = false;
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
			try { add(w); } catch (e:Dynamic) {}
			// ★ 创建时就设 scrollFactor=0，之后 positionWidget 只需设坐标
			try { w.scrollFactor.set(0, 0); } catch (e:Dynamic) {}
			try { w.setScrollFactor(0, 0); } catch (e:Dynamic) {}
		}
		// CheckBox
		addOne(check_mute_inst); addOne(check_mute_vocals); addOne(check_mute_vocals_opponent);
		addOne(check_vortex); addOne(check_warnings); addOne(playSoundBf); addOne(playSoundDad);
		addOne(check_voices); addOne(check_eventsSec); addOne(check_notesSec); addOne(check_disableNoteRGB);
		addOne(waveformUseInstrumental); addOne(waveformUseVoices); addOne(waveformUseOppVoices);
		addOne(check_mustHitSection); addOne(check_gfSection); addOne(check_altAnim); addOne(check_changeBPM);
		addOne(metronome); addOne(disableAutoScrolling); addOne(mouseScrollingQuant);
		// InputText
		addOne(UI_songTitle); addOne(difficultyInputText); addOne(value1InputText); addOne(value2InputText); addOne(strumTimeInputText);
		addOne(gameOverCharacterInputText); addOne(gameOverSoundInputText);
		addOne(gameOverLoopInputText); addOne(gameOverEndInputText);
		addOne(noteSkinInputText); addOne(noteSplashesInputText);
		// NumericStepper
		addOne(songBpmStepper); addOne(stepperSpeed); addOne(stepperMania);
		addOne(metronomeStepper); addOne(metronomeOffsetStepper);
		addOne(instVolume); addOne(voicesVolume); addOne(voicesOppVolume);
		addOne(stepperBeats); addOne(stepperSectionBPM); addOne(stepperSusLength);
		// DropDown
		addOne(player1DropDown); addOne(gfVersionDropDown); addOne(player2DropDown);
		addOne(stageDropDown); addOne(noteTypeDropDown); addOne(eventDropDown);
		// sliderRate
		#if FLX_PITCH
		addOne(sliderRate);
		#end
	}

	var check_mute_inst:FlxUICheckBox = null;
	var check_mute_vocals:FlxUICheckBox = null;
	var check_mute_vocals_opponent:FlxUICheckBox = null;
	var check_vortex:FlxUICheckBox = null;
	var check_warnings:FlxUICheckBox = null;
	var playSoundBf:FlxUICheckBox = null;
	var playSoundDad:FlxUICheckBox = null;
	// 以下 4 个原本是 add*UI 内的局部变量，为接通新顶栏菜单的 check 项提升为成员
	var check_voices:FlxUICheckBox = null;
	var check_eventsSec:FlxUICheckBox = null;
	var check_notesSec:FlxUICheckBox = null;
	var check_disableNoteRGB:FlxUICheckBox = null;
	// 波形图 3 个 checkbox，原是 addChartingUI 内的局部变量
	var waveformUseInstrumental:FlxUICheckBox = null;
	var waveformUseVoices:FlxUICheckBox = null;
	var waveformUseOppVoices:FlxUICheckBox = null;
	var UI_songTitle:FlxUIInputText;
	/** ★ 难度输入框（【歌曲】菜单）：留空 = 无难度后缀；填了如 Fuck →
	 *  保存为 song-Fuck.json，重载/打开也按 song-Fuck 加载 */
	var difficultyInputText:FlxUIInputText;
	var stageDropDown:FlxUIDropDownMenu;
	#if FLX_PITCH
	var sliderRate:FlxUISlider;
	#end

	function addSongUI():Void
	{
		UI_songTitle = new FlxUIInputText(10, 10, 70, _song.song, 8);
		// ★ 加入 blockPressWhileTypingOn，防止输入框内按 Backspace 触发全局退出快捷键
		blockPressWhileTypingOn.push(UI_songTitle);

		// ★ 难度输入框：初始取当前全局难度（非默认难度时带入，方便继续编辑该难度）
		var initDiff:String = '';
		try
		{
			var curDiff:String = Difficulty.getString();
			if (curDiff != null && curDiff != Difficulty.getDefault()) initDiff = curDiff;
		}
		catch (e:Dynamic) {}
		difficultyInputText = new FlxUIInputText(10, 55, 70, initDiff, 8);
		blockPressWhileTypingOn.push(difficultyInputText);

		check_voices = new FlxUICheckBox(10, 25, null, null, "Has voice track", 100);
		check_voices.checked = _song.needsVoices;
		// _song.needsVoices = check_voices.checked;
		check_voices.callback = function()
		{
			_song.needsVoices = check_voices.checked;
			// trace('CHECKED!');
		};

		var saveButton:FlxButton = new FlxButton(110, 8, "Save", function()
		{
			saveLevel();
		});

		var reloadSong:FlxButton = new FlxButton(saveButton.x + 90, saveButton.y, "Reload Audio", function()
		{
			currentSongName = Paths.formatToSongPath(UI_songTitle.text);
			updateJsonData();
			loadSong();
			updateWaveform();
		});

		var reloadSongJson:FlxButton = new FlxButton(reloadSong.x, saveButton.y + 30, "Reload JSON", function()
		{
			openSubState(new Prompt('This action will clear current progress.\n\nProceed?', 0, function()
			{
				loadJson(_song.song.toLowerCase());
			}, null, ignoreWarnings));
		});

		var engineBtn:FlxButton = new FlxButton(reloadSongJson.x, reloadSongJson.y + 30, 'Engine', function()
		{
			var nextEngine:String = (Song.chartEngineVersion == 'Pe-1.0.4') ? 'Pe-0.7.3' : 'Pe-1.0.4';
			Song.forceEngineVersion = nextEngine;
			var songName:String = Paths.formatToSongPath(_song.song);
			try { _song = Song.loadFromJson(songName, songName); } catch(e) {}
			autoFixManiaFromData(); // 重载的 json 可能缺 mania 字段 → 按数据恢复
			recalcKeyAmounts();
			reloadGridLayer();
			makeStrumNotes();
			changeSection(curSec);
		});
		engineBtn.label.setFormat(Paths.font(Language.get('fontName', 'main') + '.ttf'), 8, CENTER);

		var loadAutosaveBtn:FlxButton = new FlxButton(reloadSongJson.x, engineBtn.y + 30, 'Load Autosave', function()
		{
			PlayState.SONG = Song.parseJSON(FlxG.save.data.autosave);
			MusicBeatState.resetState();
		});

		var loadEventJson:FlxButton = new FlxButton(loadAutosaveBtn.x, loadAutosaveBtn.y + 30, 'Load Events', function()
		{
			var songName:String = Paths.formatToSongPath(_song.song);
			var file:String = Paths.json(songName + '/events');
			#if sys
			if (#if MODS_ALLOWED FileSystem.exists(Paths.modsJson(songName + '/events')) || #end FileSystem.exists(file))
			#else
			if (Assets.exists(file))
			#end
			{
				clearEvents();
				var savedFmt = Song.detectedFormat;
				var savedCE = Song.chartEngineVersion;
				var events:SwagSong = Song.loadFromJson('events', songName);
				Song.detectedFormat = savedFmt;
				Song.chartEngineVersion = savedCE;
				_song.events = events.events;
				changeSection(curSec);
			}
		});

		var saveEvents:FlxButton = new FlxButton(110, reloadSongJson.y, 'Save Events', function()
		{
			saveEvents();
		});

		var clear_events:FlxButton = new FlxButton(320, 310, 'Clear events', function()
		{
			openSubState(new Prompt('This action will clear current progress.\n\nProceed?', 0, clearEvents, null, ignoreWarnings));
		});
		clear_events.color = FlxColor.RED;
		clear_events.label.color = FlxColor.WHITE;

		var clear_notes:FlxButton = new FlxButton(320, clear_events.y + 30, 'Clear notes', function()
		{
			openSubState(new Prompt('This action will clear current progress.\n\nProceed?', 0, function()
			{
				for (sec in 0..._song.notes.length)
				{
					_song.notes[sec].sectionNotes = [];
				}
				updateGrid();
			}, null, ignoreWarnings));
		});
		clear_notes.color = FlxColor.RED;
		clear_notes.label.color = FlxColor.WHITE;

		songBpmStepper = new FlxUINumericStepper(10, 70, 1, 1, 1, 400, 3, FlxUINumericStepper.STACK_VERTICAL);
		songBpmStepper.value = Conductor.bpm;
		songBpmStepper.name = 'song_bpm';
		blockPressWhileTypingOnStepper.push(songBpmStepper);

		stepperSpeed = new FlxUINumericStepper(10, songBpmStepper.y + 35, 0.1, 1, 0.1, 10, 2, FlxUINumericStepper.STACK_VERTICAL);
		stepperSpeed.value = _song.speed;
		stepperSpeed.name = 'song_speed';
		blockPressWhileTypingOnStepper.push(stepperSpeed);

		// ★ mania 在 UI 上显示「键数」（4K=4），内部仍是「每边键数-1」（4K=mania 3）。
		//   stepper 范围也整体 +1，从「键数 1..10」而不是「mania 0..9」。
		// ★ Mania 步进器阈值：extrakeys.json 缺失时兜底 1~10，避免 ± 越界崩溃
		var maniaMinK:Int = 1;
		var maniaMaxK:Int = extraMaxKeys();
		stepperMania = new FlxUINumericStepper(100, stepperSpeed.y, 1, _song.mania + 1, maniaMinK + 1, maniaMaxK + 1, 1, FlxUINumericStepper.STACK_VERTICAL);
		stepperMania.value = _song.mania + 1;
		stepperMania.name = 'song_mania';
		blockPressWhileTypingOnStepper.push(stepperMania);

		#if MODS_ALLOWED
		var directories:Array<String> = [
			Paths.mods('characters/'),
			Paths.mods(Mods.currentModDirectory + '/characters/'),
			Paths.getSharedPath('characters/')
		];
		for (mod in Mods.getGlobalMods())
			directories.push(Paths.mods(mod + '/characters/'));
		#else
		var directories:Array<String> = [Paths.getSharedPath('characters/')];
		#end

		var tempArray:Array<String> = [];
		var characters:Array<String> = Mods.mergeAllTextsNamed('data/characterList.txt', Paths.getSharedPath());
		for (character in characters)
		{
			if (character.trim().length > 0)
				tempArray.push(character);
		}

		#if MODS_ALLOWED
		for (i in 0...directories.length)
		{
			var directory:String = directories[i];
			if (FileSystem.exists(directory))
			{
				for (file in FileSystem.readDirectory(directory))
				{
					var path = haxe.io.Path.join([directory, file]);
					if (!FileSystem.isDirectory(path) && file.endsWith('.json'))
					{
						var charToCheck:String = file.substr(0, file.length - 5);
						if (charToCheck.trim().length > 0 && !charToCheck.endsWith('-dead') && !tempArray.contains(charToCheck))
						{
							tempArray.push(charToCheck);
							characters.push(charToCheck);
						}
					}
				}
			}
		}
		#end
		tempArray = [];

		player1DropDown = new FlxUIDropDownMenu(10, stepperSpeed.y + 45, FlxUIDropDownMenu.makeStrIdLabelArray(characters, true),
			function(character:String)
			{
				_song.player1 = characters[Std.parseInt(character)];
				updateJsonData();
				updateHeads();
				reloadGridLayer(); // ★ 换角色后背景/波形颜色立即跟随
			});
		player1DropDown.selectedLabel = _song.player1;
		blockPressWhileScrolling.push(player1DropDown);

		gfVersionDropDown = new FlxUIDropDownMenu(player1DropDown.x, player1DropDown.y + 40, FlxUIDropDownMenu.makeStrIdLabelArray(characters, true),
			function(character:String)
			{
				_song.gfVersion = characters[Std.parseInt(character)];
				updateJsonData();
				updateHeads();
			});
		gfVersionDropDown.selectedLabel = _song.gfVersion;
		blockPressWhileScrolling.push(gfVersionDropDown);

		player2DropDown = new FlxUIDropDownMenu(player1DropDown.x, gfVersionDropDown.y + 40, FlxUIDropDownMenu.makeStrIdLabelArray(characters, true),
			function(character:String)
			{
				_song.player2 = characters[Std.parseInt(character)];
				updateJsonData();
				updateHeads();
				reloadGridLayer(); // ★ 换角色后背景/波形颜色立即跟随
			});
		player2DropDown.selectedLabel = _song.player2;
		blockPressWhileScrolling.push(player2DropDown);

		#if MODS_ALLOWED
		var directories:Array<String> = [
			Paths.mods('stages/'),
			Paths.mods(Mods.currentModDirectory + '/stages/'),
			Paths.getSharedPath('stages/')
		];
		for (mod in Mods.getGlobalMods())
			directories.push(Paths.mods(mod + '/stages/'));
		#else
		var directories:Array<String> = [Paths.getSharedPath('stages/')];
		#end

		var stageFile:Array<String> = Mods.mergeAllTextsNamed('data/stageList.txt', Paths.getSharedPath());
		var stages:Array<String> = [];
		for (stage in stageFile)
		{
			if (stage.trim().length > 0)
			{
				stages.push(stage);
			}
			tempArray.push(stage);
		}
		#if MODS_ALLOWED
		for (i in 0...directories.length)
		{
			var directory:String = directories[i];
			if (FileSystem.exists(directory))
			{
				for (file in FileSystem.readDirectory(directory))
				{
					var path = haxe.io.Path.join([directory, file]);
					if (!FileSystem.isDirectory(path) && file.endsWith('.json'))
					{
						var stageToCheck:String = file.substr(0, file.length - 5);
						if (stageToCheck.trim().length > 0 && !tempArray.contains(stageToCheck))
						{
							tempArray.push(stageToCheck);
							stages.push(stageToCheck);
						}
					}
				}
			}
		}
		#end

		if (stages.length < 1)
			stages.push('stage');

		stageDropDown = new FlxUIDropDownMenu(player1DropDown.x + 140, player1DropDown.y, FlxUIDropDownMenu.makeStrIdLabelArray(stages, true),
			function(character:String)
			{
				_song.stage = stages[Std.parseInt(character)];
			});
		stageDropDown.selectedLabel = _song.stage;
		blockPressWhileScrolling.push(stageDropDown);

		// 隐藏所有局部 FlxButton（只保留回调功能，不在旧 UI 上显示）
		var songButtons:Array<FlxButton> = [saveButton, reloadSong, reloadSongJson, engineBtn, loadAutosaveBtn, loadEventJson, saveEvents, clear_events, clear_notes];
		for (b in songButtons) if (b != null) try { b.visible = false; } catch(e) {}

		initPsychCamera().follow(camPos, LOCKON, 999);
	}

	var stepperBeats:FlxUINumericStepper;
	var check_mustHitSection:FlxUICheckBox;
	var check_gfSection:FlxUICheckBox;
	var check_changeBPM:FlxUICheckBox;
	var stepperSectionBPM:FlxUINumericStepper;
	var check_altAnim:FlxUICheckBox;

	var sectionToCopy:Int = 0;
	var notesCopied:Array<Dynamic>;

	function addSectionUI():Void
	{
		check_mustHitSection = new FlxUICheckBox(10, 15, null, null, "Must hit section", 100);
		check_mustHitSection.name = 'check_mustHit';
		check_mustHitSection.checked = _song.notes[curSec].mustHitSection;
		// ★ 新菜单系统不经过 UI_box 事件广播，必须在这里补 callback（原逻辑在 getEvent）
		check_mustHitSection.callback = function()
		{
			_song.notes[curSec].mustHitSection = check_mustHitSection.checked;
			updateHeads();
			reloadGridLayer(); // ★ 背景/网格/波形归属整体跟随 mustHit
		};

		check_gfSection = new FlxUICheckBox(10, check_mustHitSection.y + 22, null, null, "GF section", 100);
		check_gfSection.name = 'check_gf';
		check_gfSection.checked = _song.notes[curSec].gfSection;
		// _song.needsVoices = check_mustHit.checked;
		check_gfSection.callback = function()
		{
			_song.notes[curSec].gfSection = check_gfSection.checked;
			updateGrid();
			updateHeads();
		};

		check_altAnim = new FlxUICheckBox(check_gfSection.x + 120, check_gfSection.y, null, null, "Alt Animation", 100);
		check_altAnim.checked = _song.notes[curSec].altAnim;
		check_altAnim.callback = function()
		{
			_song.notes[curSec].altAnim = check_altAnim.checked;
		};

		stepperBeats = new FlxUINumericStepper(10, 100, 1, 4, 1, 7, 2, FlxUINumericStepper.STACK_VERTICAL);
		stepperBeats.value = getSectionBeats();
		stepperBeats.name = 'section_beats';
		blockPressWhileTypingOnStepper.push(stepperBeats);
		check_altAnim.name = 'check_altAnim';

		check_changeBPM = new FlxUICheckBox(10, stepperBeats.y + 30, null, null, 'Change BPM', 100);
		check_changeBPM.checked = _song.notes[curSec].changeBPM;
		check_changeBPM.name = 'check_changeBPM';
		// ★ 新菜单系统不经过 UI_box 事件广播，必须在这里补 callback（原逻辑在 getEvent）
		check_changeBPM.callback = function()
		{
			_song.notes[curSec].changeBPM = check_changeBPM.checked;
			if (check_changeBPM.checked)
				stepperSectionBPM.value = _song.notes[curSec].bpm;
			else
				stepperSectionBPM.value = Conductor.bpm;
		};

		stepperSectionBPM = new FlxUINumericStepper(10, check_changeBPM.y + 20, 1, Conductor.bpm, 0, 999, 1, FlxUINumericStepper.STACK_VERTICAL);
		if (check_changeBPM.checked)
		{
			stepperSectionBPM.value = _song.notes[curSec].bpm;
		}
		else
		{
			stepperSectionBPM.value = Conductor.bpm;
		}
		stepperSectionBPM.name = 'section_bpm';
		blockPressWhileTypingOnStepper.push(stepperSectionBPM);

		check_eventsSec = null;
		check_notesSec = null;
		var copyButton:FlxButton = new FlxButton(10, 190, "Copy Section", function()
		{
			notesCopied = [];
			sectionToCopy = curSec;
			for (i in 0..._song.notes[curSec].sectionNotes.length)
			{
				var note:Array<Dynamic> = _song.notes[curSec].sectionNotes[i];
				notesCopied.push(note);
			}

			var startThing:Float = sectionStartTime();
			var endThing:Float = sectionStartTime(1);
			for (event in _song.events)
			{
				var strumTime:Float = event[0];
				if (endThing > event[0] && event[0] >= startThing)
				{
					var copiedEventArray:Array<Dynamic> = [];
					for (i in 0...event[1].length)
					{
						var eventToPush:Array<Dynamic> = event[1][i];
						copiedEventArray.push([eventToPush[0], eventToPush[1], eventToPush[2]]);
					}
					notesCopied.push([strumTime, -1, copiedEventArray]);
				}
			}
		});

		var pasteButton:FlxButton = new FlxButton(copyButton.x + 100, copyButton.y, "Paste Section", function()
		{
			if (notesCopied == null || notesCopied.length < 1)
			{
				return;
			}

			var addToTime:Float = Conductor.stepCrochet * (getSectionBeats() * 4 * (curSec - sectionToCopy));
			// trace('Time to add: ' + addToTime);

			for (note in notesCopied)
			{
				var copiedNote:Array<Dynamic> = [];
				var newStrumTime:Float = note[0] + addToTime;
				if (note[1] < 0)
				{
					if (check_eventsSec.checked)
					{
						var copiedEventArray:Array<Dynamic> = [];
						for (i in 0...note[2].length)
						{
							var eventToPush:Array<Dynamic> = note[2][i];
							copiedEventArray.push([eventToPush[0], eventToPush[1], eventToPush[2]]);
						}
						_song.events.push([newStrumTime, copiedEventArray]);
					}
				}
				else
				{
					if (check_notesSec.checked)
					{
						if (note[4] != null)
							copiedNote = [newStrumTime, note[1], note[2], note[3], note[4]];
						else
							copiedNote = [newStrumTime, note[1], note[2], note[3]];

						_song.notes[curSec].sectionNotes.push(copiedNote);
					}
				}
			}
			updateGrid();
		});

		var clearSectionButton:FlxButton = new FlxButton(pasteButton.x + 100, pasteButton.y, "Clear", function()
		{
			if (check_notesSec.checked)
			{
				_song.notes[curSec].sectionNotes = [];
			}

			if (check_eventsSec.checked)
			{
				var i:Int = _song.events.length - 1;
				var startThing:Float = sectionStartTime();
				var endThing:Float = sectionStartTime(1);
				while (i > -1)
				{
					var event:Array<Dynamic> = _song.events[i];
					if (event != null && endThing > event[0] && event[0] >= startThing)
					{
						_song.events.remove(event);
					}
					--i;
				}
			}
			updateGrid();
			updateNoteUI();
		});
		clearSectionButton.color = FlxColor.RED;
		clearSectionButton.label.color = FlxColor.WHITE;

		check_notesSec = new FlxUICheckBox(10, clearSectionButton.y + 25, null, null, "Notes", 100);
		check_notesSec.checked = true;
		check_eventsSec = new FlxUICheckBox(check_notesSec.x + 100, check_notesSec.y, null, null, "Events", 100);
		check_eventsSec.checked = true;

		var swapSection:FlxButton = new FlxButton(10, check_notesSec.y + 40, "Swap section", function()
		{
			for (i in 0..._song.notes[curSec].sectionNotes.length)
			{
				var note:Array<Dynamic> = _song.notes[curSec].sectionNotes[i];
				note[1] = (note[1] + leftKeys) % totalKeys;
				_song.notes[curSec].sectionNotes[i] = note;
			}
			updateGrid();
		});

		var copyLastButton:FlxButton = new FlxButton(10, swapSection.y + 30, "Copy last section", function()
		{
			var value:Int = Std.int(copyBeatStepper.value);
			if (value == 0)
				return;

			var daSec = FlxMath.maxInt(curSec, value);

			for (note in _song.notes[daSec - value].sectionNotes)
			{
				var strum = note[0] + Conductor.stepCrochet * (getSectionBeats(daSec) * 4 * value);

				var copiedNote:Array<Dynamic> = [strum, note[1], note[2], note[3]];
				_song.notes[daSec].sectionNotes.push(copiedNote);
			}

			var startThing:Float = sectionStartTime(-value);
			var endThing:Float = sectionStartTime(-value + 1);
			for (event in _song.events)
			{
				var strumTime:Float = event[0];
				if (endThing > event[0] && event[0] >= startThing)
				{
					strumTime += Conductor.stepCrochet * (getSectionBeats(daSec) * 4 * value);
					var copiedEventArray:Array<Dynamic> = [];
					for (i in 0...event[1].length)
					{
						var eventToPush:Array<Dynamic> = event[1][i];
						copiedEventArray.push([eventToPush[0], eventToPush[1], eventToPush[2]]);
					}
					_song.events.push([strumTime, copiedEventArray]);
				}
			}
			updateGrid();
		});
		copyLastButton.setGraphicSize(80, 30);
		copyLastButton.updateHitbox();

		copyBeatStepper = new FlxUINumericStepper(copyLastButton.x + 100, copyLastButton.y, 1, 1, -99, 99, 0, FlxUINumericStepper.STACK_VERTICAL);
		blockPressWhileTypingOnStepper.push(copyBeatStepper);

		var duetButton:FlxButton = new FlxButton(10, copyLastButton.y + 45, "Duet Notes", function()
		{
			var duetNotes:Array<Array<Dynamic>> = [];
			for (note in _song.notes[curSec].sectionNotes)
			{
				var boob = note[1];
				if (boob >= leftKeys)
				{
					boob -= leftKeys;
				}
				else
				{
					boob += leftKeys;
				}

				var copiedNote:Array<Dynamic> = [note[0], boob, note[2], note[3]];
				duetNotes.push(copiedNote);
			}

			for (i in duetNotes)
			{
				_song.notes[curSec].sectionNotes.push(i);
			}

			updateGrid();
		});
		var mirrorButton:FlxButton = new FlxButton(duetButton.x + 100, duetButton.y, "Mirror Notes", function()
		{
			var duetNotes:Array<Array<Dynamic>> = [];
			for (note in _song.notes[curSec].sectionNotes)
			{
				var boob = note[1] % leftKeys;
				boob = (leftKeys - 1) - boob;
				if (note[1] >= leftKeys)
					boob += leftKeys;

				note[1] = boob;
				var copiedNote:Array<Dynamic> = [note[0], boob, note[2], note[3]];
				// duetNotes.push(copiedNote);
			}

			for (i in duetNotes)
			{
				// _song.notes[curSec].sectionNotes.push(i);
			}

			updateGrid();
		});

		// 隐藏所有局部 button/stepper（只保留回调功能，不在旧 UI 上显示）
		var sectionWidgets:Array<Dynamic> = [copyButton, pasteButton, clearSectionButton, swapSection, copyLastButton, duetButton, mirrorButton, copyBeatStepper];
		for (w in sectionWidgets) if (w != null) try { w.visible = false; } catch(e) {}
	}

	var stepperSusLength:FlxUINumericStepper;
	var copyBeatStepper:FlxUINumericStepper; // 复制节拍：相对当前小节的偏移（正数=从[N-数]拍复制过来，负数反之）
	var strumTimeInputText:FlxUIInputText; // I wanted to use a stepper but we can't scale these as far as i know :(
	var noteTypeDropDown:FlxUIDropDownMenu;
	var currentType:Int = 0;

	function addNoteUI():Void
	{
		stepperSusLength = new FlxUINumericStepper(10, 25, Conductor.stepCrochet / 2, 0, 0, Conductor.stepCrochet * 64, 1, FlxUINumericStepper.STACK_VERTICAL);
		stepperSusLength.value = 0;
		stepperSusLength.name = 'note_susLength';
		blockPressWhileTypingOnStepper.push(stepperSusLength);

		strumTimeInputText = new FlxUIInputText(10, 65, 180, "0");
		blockPressWhileTypingOn.push(strumTimeInputText);

		var key:Int = 0;
		while (key < noteTypeList.length)
		{
			curNoteTypes.push(noteTypeList[key]);
			key++;
		}

		#if sys
		var foldersToCheck:Array<String> = Mods.directoriesWithFile(Paths.getSharedPath(), 'custom_notetypes/');
		for (folder in foldersToCheck)
			for (file in FileSystem.readDirectory(folder))
			{
				var fileName:String = file.toLowerCase().trim();
				var wordLen:Int = 4; // length of word ".lua" and ".txt";
				if ((#if LUA_ALLOWED fileName.endsWith('.lua') || #end#if HSCRIPT_ALLOWED (fileName.endsWith('.hx') && (wordLen = 3) == 3)
					|| #end fileName.endsWith('.txt')) && fileName != 'readme.txt')
				{
					var fileToCheck:String = file.substr(0, file.length - wordLen);
					if (!curNoteTypes.contains(fileToCheck))
					{
						curNoteTypes.push(fileToCheck);
						key++;
					}
				}
			}
		#end

		var displayNameList:Array<String> = curNoteTypes.copy();
		for (i in 1...displayNameList.length)
		{
			displayNameList[i] = i + '. ' + displayNameList[i];
		}

		noteTypeDropDown = new FlxUIDropDownMenu(10, 105, FlxUIDropDownMenu.makeStrIdLabelArray(displayNameList, true), function(character:String)
		{
			currentType = Std.parseInt(character);
			if (curSelectedNote != null && curSelectedNote[1] > -1)
			{
				curSelectedNote[3] = curNoteTypes[currentType];
				updateGrid();
			}
		});
		blockPressWhileScrolling.push(noteTypeDropDown);

	}

	var eventDropDown:FlxUIDropDownMenu;
	var descText:FlxText;
	var selectedEventText:FlxText;

	function addEventsUI():Void
	{
		#if LUA_ALLOWED
		var eventPushedMap:Map<String, Bool> = new Map<String, Bool>();
		var directories:Array<String> = [];

		#if MODS_ALLOWED
		directories.push(Paths.mods('custom_events/'));
		directories.push(Paths.mods(Mods.currentModDirectory + '/custom_events/'));
		for (mod in Mods.getGlobalMods())
			directories.push(Paths.mods(mod + '/custom_events/'));
		#end

		for (i in 0...directories.length)
		{
			var directory:String = directories[i];
			if (FileSystem.exists(directory))
			{
				for (file in FileSystem.readDirectory(directory))
				{
					var path = haxe.io.Path.join([directory, file]);
					if (!FileSystem.isDirectory(path) && file != 'readme.txt' && file.endsWith('.txt'))
					{
						var fileToCheck:String = file.substr(0, file.length - 4);
						if (!eventPushedMap.exists(fileToCheck))
						{
							eventPushedMap.set(fileToCheck, true);
							eventStuff.push([fileToCheck, File.getContent(path)]);
						}
					}
				}
			}
		}
		eventPushedMap.clear();
		eventPushedMap = null;
		#end

		descText = new FlxText(20, 200, 0, eventStuff[0][0]);

		var leEvents:Array<String> = [];
		for (i in 0...eventStuff.length)
		{
			leEvents.push(eventStuff[i][0]);
		}

		var text:FlxText = new FlxText(20, 30, 0, "Event:");
		text.visible = false;
		eventDropDown = new FlxUIDropDownMenu(20, 50, FlxUIDropDownMenu.makeStrIdLabelArray(leEvents, true), function(pressed:String)
		{
			// ★ 防御：pressed 可能非数字 → Std.parseInt 返回 null → eventStuff[null] 空指针崩溃
			var selectedEvent:Null<Int> = null;
			try { selectedEvent = Std.parseInt(pressed); } catch(e:Dynamic) { selectedEvent = null; }
			if (selectedEvent == null || selectedEvent < 0 || selectedEvent >= eventStuff.length) return;
			descText.text = eventStuff[selectedEvent][1];
			if (curSelectedNote != null && eventStuff != null)
			{
				// ★ 事件音符判定用 [1] 是否为数组（[2]==null 对旧谱面普通音符不可靠 → 空指针崩溃）
				if (Std.is(curSelectedNote[1], Array))
				{
					var evGroup:Array<Dynamic> = cast curSelectedNote[1];
					if (evGroup != null && evGroup.length > 0
						&& curEventSelected >= 0 && curEventSelected < evGroup.length
						&& Std.is(evGroup[curEventSelected], Array))
					{
						evGroup[curEventSelected][0] = eventStuff[selectedEvent][0];
					}
				}
				updateGrid();
			}
		});
		blockPressWhileScrolling.push(eventDropDown);

		var text:FlxText = new FlxText(20, 90, 0, "Value 1:");
		text.visible = false;
		value1InputText = new FlxUIInputText(20, 110, 100, "");
		blockPressWhileTypingOn.push(value1InputText);

		var text:FlxText = new FlxText(20, 130, 0, "Value 2:");
		text.visible = false;
		value2InputText = new FlxUIInputText(20, 150, 100, "");
		blockPressWhileTypingOn.push(value2InputText);

		// New event buttons
		var removeButton:FlxButton = new FlxButton(eventDropDown.x + eventDropDown.width + 10, eventDropDown.y, '-', function()
		{
			// ★ 事件音符判定用 [1] 是否为数组（[2]==null 对旧谱面普通音符不可靠 → 空指针崩溃）
			if (curSelectedNote != null && Std.is(curSelectedNote[1], Array))
			{
				var eventsGroup:Array<Dynamic> = cast curSelectedNote[1];
				if (eventsGroup == null) return;
				if (eventsGroup.length < 2)
				{
					_song.events.remove(curSelectedNote);
					curSelectedNote = null;
				}
				else
				{
					eventsGroup.remove(eventsGroup[curEventSelected]);
				}

				--curEventSelected;
				if (curEventSelected < 0)
					curEventSelected = 0;
				else if (curSelectedNote != null && curEventSelected >= eventsGroup.length)
					curEventSelected = eventsGroup.length - 1;

				changeEventSelected();
				updateGrid();
			}
		});
		removeButton.setGraphicSize(Std.int(removeButton.height), Std.int(removeButton.height));
		removeButton.updateHitbox();
		removeButton.color = FlxColor.RED;
		removeButton.label.color = FlxColor.WHITE;
		removeButton.label.size = 12;
		setAllLabelsOffset(removeButton, -30, 0);

		var addButton:FlxButton = new FlxButton(removeButton.x + removeButton.width + 10, removeButton.y, '+', function()
		{
			// ★ 事件音符判定用 [1] 是否为数组（[2]==null 对旧谱面普通音符不可靠 → 空指针崩溃）
			if (curSelectedNote != null && Std.is(curSelectedNote[1], Array))
			{
				var eventsGroup:Array<Dynamic> = cast curSelectedNote[1];
				if (eventsGroup == null) return;
				eventsGroup.push(['', '', '']);

				changeEventSelected(1);
				updateGrid();
			}
		});
		addButton.setGraphicSize(Std.int(removeButton.width), Std.int(removeButton.height));
		addButton.updateHitbox();
		addButton.color = FlxColor.GREEN;
		addButton.label.color = FlxColor.WHITE;
		addButton.label.size = 12;
		setAllLabelsOffset(addButton, -30, 0);

		var moveLeftButton:FlxButton = new FlxButton(addButton.x + addButton.width + 20, addButton.y, '<', function()
		{
			changeEventSelected(-1);
		});
		moveLeftButton.setGraphicSize(Std.int(addButton.width), Std.int(addButton.height));
		moveLeftButton.updateHitbox();
		moveLeftButton.label.size = 12;
		setAllLabelsOffset(moveLeftButton, -30, 0);

		var moveRightButton:FlxButton = new FlxButton(moveLeftButton.x + moveLeftButton.width + 10, moveLeftButton.y, '>', function()
		{
			changeEventSelected(1);
		});
		moveRightButton.setGraphicSize(Std.int(moveLeftButton.width), Std.int(moveLeftButton.height));
		moveRightButton.updateHitbox();
		moveRightButton.label.size = 12;
		setAllLabelsOffset(moveRightButton, -30, 0);

		selectedEventText = new FlxText(addButton.x - 100, addButton.y + addButton.height + 6, (moveRightButton.x - addButton.x) + 186, 'Selected Event: None');
		selectedEventText.alignment = CENTER;

		// 隐藏所有局部 button（只保留回调功能，不在旧 UI 上显示）
		var eventButtons:Array<FlxButton> = [removeButton, addButton, moveLeftButton, moveRightButton];
		for (b in eventButtons) if (b != null) try { b.visible = false; } catch(e) {}
	}

	function changeEventSelected(change:Int = 0)
	{
		// ★ 事件音符判定用 [1] 是否为数组（[2]==null 不可靠，旧谱面普通音符 susLength 可能缺失）
		if (curSelectedNote != null && Std.is(curSelectedNote[1], Array))
		{
			var eventsGroup:Array<Dynamic> = cast curSelectedNote[1];
			if (eventsGroup == null || eventsGroup.length < 1)
			{
				curEventSelected = 0;
				selectedEventText.text = 'Selected Event: None';
			}
			else
			{
				curEventSelected += change;
				if (curEventSelected < 0)
					curEventSelected = eventsGroup.length - 1;
				else if (curEventSelected >= eventsGroup.length)
					curEventSelected = 0;
				selectedEventText.text = 'Selected Event: ' + (curEventSelected + 1) + ' / ' + eventsGroup.length;
			}
		}
		else
		{
			curEventSelected = 0;
			selectedEventText.text = 'Selected Event: None';
		}
		updateNoteUI();
	}

	function setAllLabelsOffset(button:FlxButton, x:Float, y:Float)
	{
		for (point in button.labelOffsets)
		{
			point.set(x, y);
		}
	}

	var metronome:FlxUICheckBox;
	var mouseScrollingQuant:FlxUICheckBox;
	var metronomeStepper:FlxUINumericStepper;
	var metronomeOffsetStepper:FlxUINumericStepper;
	var disableAutoScrolling:FlxUICheckBox;
	var instVolume:FlxUINumericStepper;
	var voicesVolume:FlxUINumericStepper;
	var voicesOppVolume:FlxUINumericStepper;

	function addChartingUI()
	{

		#if (desktop || mobile)
		if (FlxG.save.data.chart_waveformInst == null)
			FlxG.save.data.chart_waveformInst = false;
		if (FlxG.save.data.chart_waveformVoices == null)
			FlxG.save.data.chart_waveformVoices = false;
		if (FlxG.save.data.chart_waveformOppVoices == null)
			FlxG.save.data.chart_waveformOppVoices = false;

		// 这三个原是局部变量，提升到类成员以便顶栏菜单 registerCheck / toggle
		waveformUseInstrumental = null;
		waveformUseVoices = null;
		waveformUseOppVoices = null;

		waveformUseInstrumental = new FlxUICheckBox(10, 90, null, null, "Waveform\n(Instrumental)", 85);
		waveformUseInstrumental.checked = FlxG.save.data.chart_waveformInst;
		// ★ 互斥已取消：BF / Inst / Opp 波形可同时开启（BF 画左侧、Opp 画右侧、Inst 全宽）
		waveformUseInstrumental.callback = function()
		{
			FlxG.save.data.chart_waveformInst = waveformUseInstrumental.checked;
			updateWaveform();
		};

		waveformUseVoices = new FlxUICheckBox(waveformUseInstrumental.x + 100, waveformUseInstrumental.y, null, null, "Waveform\n(Main Vocals)", 85);
		waveformUseVoices.checked = FlxG.save.data.chart_waveformVoices;
		waveformUseVoices.callback = function()
		{
			FlxG.save.data.chart_waveformVoices = waveformUseVoices.checked;
			updateWaveform();
		};

		waveformUseOppVoices = new FlxUICheckBox(waveformUseInstrumental.x + 200, waveformUseInstrumental.y, null, null, "Waveform\n(Opp. Vocals)", 85);
		waveformUseOppVoices.checked = FlxG.save.data.chart_waveformOppVoices;
		waveformUseOppVoices.callback = function()
		{
			FlxG.save.data.chart_waveformOppVoices = waveformUseOppVoices.checked;
			updateWaveform();
		};
		#end

		check_mute_inst = new FlxUICheckBox(10, 280, null, null, "Mute Instrumental (in editor)", 100);
		check_mute_inst.checked = false;
		check_mute_inst.callback = function()
		{
			var vol:Float = instVolume.value;
			if (check_mute_inst.checked)
				vol = 0;

			FlxG.sound.music.volume = vol;
		};
		mouseScrollingQuant = new FlxUICheckBox(10, 190, null, null, "Mouse Scrolling Quantization", 100);
		if (FlxG.save.data.mouseScrollingQuant == null)
			FlxG.save.data.mouseScrollingQuant = false;
		mouseScrollingQuant.checked = FlxG.save.data.mouseScrollingQuant;

		mouseScrollingQuant.callback = function()
		{
			FlxG.save.data.mouseScrollingQuant = mouseScrollingQuant.checked;
			mouseQuant = FlxG.save.data.mouseScrollingQuant;
		};

		check_vortex = new FlxUICheckBox(10, 160, null, null, "Vortex Editor (BETA)", 100);
		if (FlxG.save.data.chart_vortex == null)
			FlxG.save.data.chart_vortex = false;
		check_vortex.checked = FlxG.save.data.chart_vortex;

		check_vortex.callback = function()
		{
			FlxG.save.data.chart_vortex = check_vortex.checked;
			vortex = FlxG.save.data.chart_vortex;
			reloadGridLayer();
		};

		check_warnings = new FlxUICheckBox(10, 120, null, null, "Ignore Progress Warnings", 100);
		if (FlxG.save.data.ignoreWarnings == null)
			FlxG.save.data.ignoreWarnings = false;
		check_warnings.checked = FlxG.save.data.ignoreWarnings;

		check_warnings.callback = function()
		{
			FlxG.save.data.ignoreWarnings = check_warnings.checked;
			ignoreWarnings = FlxG.save.data.ignoreWarnings;
		};

		check_mute_vocals = new FlxUICheckBox(check_mute_inst.x, check_mute_inst.y + 30, null, null, "Mute Main Vocals (in editor)", 100);
		check_mute_vocals.checked = false;
		check_mute_vocals.callback = function()
		{
			var vol:Float = voicesVolume.value;
			if (check_mute_vocals.checked)
				vol = 0;

			if (vocals != null)
				vocals.volume = vol;
		};
		check_mute_vocals_opponent = new FlxUICheckBox(check_mute_vocals.x + 120, check_mute_vocals.y, null, null, "Mute Opp. Vocals (in editor)", 100);
		check_mute_vocals_opponent.checked = false;
		check_mute_vocals_opponent.callback = function()
		{
			var vol:Float = voicesOppVolume.value;
			if (check_mute_vocals_opponent.checked)
				vol = 0;

			if (opponentVocals != null)
				opponentVocals.volume = vol;
		};

		playSoundBf = new FlxUICheckBox(check_mute_inst.x, check_mute_vocals.y + 30, null, null, 'Play Sound (Boyfriend notes)', 100, function()
		{
			FlxG.save.data.chart_playSoundBf = playSoundBf.checked;
		});
		if (FlxG.save.data.chart_playSoundBf == null)
			FlxG.save.data.chart_playSoundBf = false;
		playSoundBf.checked = FlxG.save.data.chart_playSoundBf;

		playSoundDad = new FlxUICheckBox(check_mute_inst.x + 120, playSoundBf.y, null, null, 'Play Sound (Opponent notes)', 100, function()
		{
			FlxG.save.data.chart_playSoundDad = playSoundDad.checked;
		});
		if (FlxG.save.data.chart_playSoundDad == null)
			FlxG.save.data.chart_playSoundDad = false;
		playSoundDad.checked = FlxG.save.data.chart_playSoundDad;

		metronome = new FlxUICheckBox(10, 15, null, null, "Metronome Enabled", 100, function()
		{
			FlxG.save.data.chart_metronome = metronome.checked;
		});
		if (FlxG.save.data.chart_metronome == null)
			FlxG.save.data.chart_metronome = false;
		metronome.checked = FlxG.save.data.chart_metronome;

		// ★ 节拍器 BPM：默认步长 1（Shift+点击 ±5 由菜单栏 stepperStep 处理），不再固定 ±5
		metronomeStepper = new FlxUINumericStepper(15, 55, 1, _song.bpm, 1, 1500, 1, FlxUINumericStepper.STACK_VERTICAL);
		metronomeOffsetStepper = new FlxUINumericStepper(metronomeStepper.x + 100, metronomeStepper.y, 25, 0, 0, 1000, 1, FlxUINumericStepper.STACK_VERTICAL);
		blockPressWhileTypingOnStepper.push(metronomeStepper);
		blockPressWhileTypingOnStepper.push(metronomeOffsetStepper);

		disableAutoScrolling = new FlxUICheckBox(metronome.x + 120, metronome.y, null, null, "Disable Autoscroll (Not Recommended)", 120, function()
		{
			FlxG.save.data.chart_noAutoScroll = disableAutoScrolling.checked;
		});
		if (FlxG.save.data.chart_noAutoScroll == null)
			FlxG.save.data.chart_noAutoScroll = false;
		disableAutoScrolling.checked = FlxG.save.data.chart_noAutoScroll;

		instVolume = new FlxUINumericStepper(metronomeStepper.x, 250, 0.1, 1, 0, 1, 1, FlxUINumericStepper.STACK_VERTICAL);
		instVolume.value = FlxG.sound.music.volume;
		instVolume.name = 'inst_volume';
		blockPressWhileTypingOnStepper.push(instVolume);

		voicesVolume = new FlxUINumericStepper(instVolume.x + 100, instVolume.y, 0.1, 1, 0, 1, 1, FlxUINumericStepper.STACK_VERTICAL);
		voicesVolume.value = vocals.volume;
		voicesVolume.name = 'voices_volume';
		blockPressWhileTypingOnStepper.push(voicesVolume);

		voicesOppVolume = new FlxUINumericStepper(instVolume.x + 200, instVolume.y, 0.1, 1, 0, 1, 1, FlxUINumericStepper.STACK_VERTICAL);
		voicesOppVolume.value = vocals.volume;
		voicesOppVolume.name = 'voices_opp_volume';
		blockPressWhileTypingOnStepper.push(voicesOppVolume);

		#if FLX_PITCH
		sliderRate = new FlxUISlider(this, 'playbackSpeed', 120, 120, 0.5, 3, 150, #if !hl null #else 0 #end, 5, FlxColor.WHITE, FlxColor.BLACK);
		sliderRate.nameLabel.text = 'Playback Rate';
		#end

	}

	var gameOverCharacterInputText:FlxUIInputText;
	var gameOverSoundInputText:FlxUIInputText;
	var gameOverLoopInputText:FlxUIInputText;
	var gameOverEndInputText:FlxUIInputText;

	var noteSkinInputText:FlxUIInputText;
	var noteSplashesInputText:FlxUIInputText;

	function addDataUI()
	{
		//
		gameOverCharacterInputText = new FlxUIInputText(10, 25, 150, _song.gameOverChar != null ? _song.gameOverChar : '', 8);
		blockPressWhileTypingOn.push(gameOverCharacterInputText);

		gameOverSoundInputText = new FlxUIInputText(10, gameOverCharacterInputText.y + 35, 150, _song.gameOverSound != null ? _song.gameOverSound : '', 8);
		blockPressWhileTypingOn.push(gameOverSoundInputText);

		gameOverLoopInputText = new FlxUIInputText(10, gameOverSoundInputText.y + 35, 150, _song.gameOverLoop != null ? _song.gameOverLoop : '', 8);
		blockPressWhileTypingOn.push(gameOverLoopInputText);

		gameOverEndInputText = new FlxUIInputText(10, gameOverLoopInputText.y + 35, 150, _song.gameOverEnd != null ? _song.gameOverEnd : '', 8);
		blockPressWhileTypingOn.push(gameOverEndInputText);
		//

		check_disableNoteRGB = new FlxUICheckBox(10, 170, null, null, "Disable Note RGB", 100);
		check_disableNoteRGB.checked = (_song.disableNoteRGB == true);
		check_disableNoteRGB.callback = function()
		{
			_song.disableNoteRGB = check_disableNoteRGB.checked;
			// ★ 必须同时重建网格音符与顶部受体箭头：只 updateGrid() 的话
			//   strumline 仍是勾选前的着色状态，勾上「禁用 RGB」看起来毫无效果。
			updateGrid();
			makeStrumNotes();
			// trace('CHECKED!');
		};

		//
		noteSkinInputText = new FlxUIInputText(10, 280, 150, _song.arrowSkin != null ? _song.arrowSkin : '', 8);
		blockPressWhileTypingOn.push(noteSkinInputText);

		noteSplashesInputText = new FlxUIInputText(noteSkinInputText.x, noteSkinInputText.y + 35, 150, _song.splashSkin != null ? _song.splashSkin : '', 8);
		blockPressWhileTypingOn.push(noteSplashesInputText);

		var reloadNotesButton:FlxButton = new FlxButton(noteSplashesInputText.x + 5, noteSplashesInputText.y + 20, 'Change Notes', function()
		{
			_song.arrowSkin = noteSkinInputText.text;
			updateGrid();
		});
		//
	}

	function disableAllOldUI():Void
	{
		// 不再需要 —— 旧 UI 体系已完全移除
	}

	function loadSong():Void
	{
		// ★ 重载音频 = 强制绕过声音缓存重新解码磁盘文件（否则改了 Inst/Voices 后点重载还是旧音频）
		Paths.forceReloadSounds = true;
		if (FlxG.sound.music != null)
			FlxG.sound.music.stop();

		if (vocals != null)
		{
			vocals.stop();
			vocals.destroy();
		}
		if (opponentVocals != null)
		{
			opponentVocals.stop();
			opponentVocals.destroy();
		}

		vocals = new FlxSound();
		opponentVocals = new FlxSound();
		try
		{
			var playerVocals = Paths.voices(currentSongName,
				(characterData.vocalsP1 == null || characterData.vocalsP1.length < 1) ? 'Player' : characterData.vocalsP1);
			vocals.loadEmbedded(playerVocals != null ? playerVocals : Paths.voices(currentSongName));
		}
		vocals.autoDestroy = false;
		FlxG.sound.list.add(vocals);

		opponentVocals = new FlxSound();
		try
		{
			var oppVocals = Paths.voices(currentSongName,
				(characterData.vocalsP2 == null || characterData.vocalsP2.length < 1) ? 'Opponent' : characterData.vocalsP2);
			if (oppVocals != null)
				opponentVocals.loadEmbedded(oppVocals);
		}
		opponentVocals.autoDestroy = false;
		FlxG.sound.list.add(opponentVocals);

		generateSong();
		FlxG.sound.music.pause();
		Conductor.songPosition = sectionStartTime();
		FlxG.sound.music.time = Conductor.songPosition;

		var curTime:Float = 0;
		if (_song.notes.length <= 1) // First load ever
		{
			while (curTime < FlxG.sound.music.length)
			{
				addSection();
				curTime += (60 / _song.bpm) * 4000;
			}
		}
		Paths.forceReloadSounds = false;
	}

	var playtesting:Bool = false;
	var playtestingTime:Float = 0;
	var playtestingOnComplete:Void->Void = null;

	override function closeSubState()
	{
		if (playtesting)
		{
			// ★ 一次性恢复：ESC 试玩结束只恢复这一次，随后必须复位标志——
			//   否则之后任何 substate 关闭（粘贴/清除等确认 Prompt）都会再次把
			//   播放位置跳回 ESC 试玩前的时刻（表现为"粘贴完回到测试那个小节"）
			playtesting = false;
			FlxG.sound.music.pause();
			FlxG.sound.music.time = playtestingTime;
			FlxG.sound.music.onComplete = playtestingOnComplete;
			if (instVolume != null)
				FlxG.sound.music.volume = instVolume.value;
			if (check_mute_inst != null && check_mute_inst.checked)
				FlxG.sound.music.volume = 0;

			if (vocals != null)
			{
				vocals.pause();
				vocals.time = playtestingTime;
				if (voicesVolume != null)
					vocals.volume = voicesVolume.value;
				if (check_mute_vocals != null && check_mute_vocals.checked)
					vocals.volume = 0;
			}

			if (opponentVocals != null)
			{
				opponentVocals.pause();
				opponentVocals.time = playtestingTime;
				if (voicesOppVolume != null)
					opponentVocals.volume = voicesOppVolume.value;
				if (check_mute_vocals_opponent != null && check_mute_vocals_opponent.checked)
					opponentVocals.volume = 0;
			}

			#if DISCORD_ALLOWED
			// Updating Discord Rich Presence
			DiscordClient.changePresence("Chart Editor", StringTools.replace(_song.song, '-', ' '));
			#end
		}
		removeVirtualPad();
		addVirtualPad(ChartingStateC, ChartingStateC);
		super.closeSubState();
	}

	function generateSong()
	{
		FlxG.sound.playMusic(Paths.inst(currentSongName), 0.6 /*, false*/);
		FlxG.sound.music.autoDestroy = false;
		if (instVolume != null)
			FlxG.sound.music.volume = instVolume.value;
		if (check_mute_inst != null && check_mute_inst.checked)
			FlxG.sound.music.volume = 0;

		FlxG.sound.music.onComplete = function()
		{
			FlxG.sound.music.pause();
			Conductor.songPosition = 0;
			if (vocals != null)
			{
				vocals.pause();
				vocals.time = 0;
			}
			if (opponentVocals != null)
			{
				opponentVocals.pause();
				opponentVocals.time = 0;
			}
			changeSection();
			curSec = 0;
			updateGrid();
			updateSectionUI();
			if (vocals != null)
				vocals.play();
			if (opponentVocals != null)
				opponentVocals.play();
		};
	}

	function generateUI():Void
	{
		while (bullshitUI.members.length > 0)
		{
			bullshitUI.remove(bullshitUI.members[0], true);
		}

		// general shit
		var title:FlxText = new FlxText(UI_box.x + 20, UI_box.y + 20, 0);
		bullshitUI.add(title);
	}

	override function getEvent(id:String, sender:Dynamic, data:Dynamic, ?params:Array<Dynamic>)
	{
		if (id == FlxUICheckBox.CLICK_EVENT)
		{
			var check:FlxUICheckBox = cast sender;
			var label = check.getLabel().text;
			switch (label)
			{
				case 'Must hit section':
					_song.notes[curSec].mustHitSection = check.checked;

					updateGrid();
					updateHeads();

				case 'GF section':
					_song.notes[curSec].gfSection = check.checked;

					updateGrid();
					updateHeads();

				case 'Change BPM':
					_song.notes[curSec].changeBPM = check.checked;
					FlxG.log.add('changed bpm shit');
				case "Alt Animation":
					_song.notes[curSec].altAnim = check.checked;
			}
		}
		else if (id == FlxUINumericStepper.CHANGE_EVENT && (sender is FlxUINumericStepper))
		{
			var nums:FlxUINumericStepper = cast sender;
			var wname = nums.name;
			// FlxG.log.add(wname);
			switch (wname)
			{
				case 'section_beats':
					_song.notes[curSec].sectionBeats = nums.value;
					reloadGridLayer();

				case 'song_speed':
					_song.speed = nums.value;

				case 'song_mania':
					// ★ UI 显示键数（4K=4），存内部 mania 要减一（4K=3）；阈值兜底防越界
					var maniaMinK:Int = 1;
					var maniaMaxK:Int = extraMaxKeys();
					nums.value = FlxMath.bound(nums.value, maniaMinK + 1, maniaMaxK + 1);
					_song.mania = Std.int(nums.value) - 1;
					updateKeyAmounts();
					reloadGridLayer();
					makeStrumNotes();

				case 'song_bpm':
					_song.bpm = nums.value;
					Conductor.mapBPMChanges(_song);
					Conductor.bpm = nums.value;
					stepperSusLength.stepSize = Math.ceil(Conductor.stepCrochet / 2);
					updateGrid();

				case 'note_susLength':
					if (curSelectedNote != null && curSelectedNote[2] != null)
					{
						curSelectedNote[2] = nums.value;
						updateGrid();
					}

				case 'section_bpm':
					_song.notes[curSec].bpm = nums.value;
					updateGrid();

				case 'inst_volume':
					FlxG.sound.music.volume = nums.value;
					if (check_mute_inst.checked)
						FlxG.sound.music.volume = 0;

				case 'voices_volume':
					vocals.volume = nums.value;
					if (check_mute_vocals.checked)
						vocals.volume = 0;

				case 'voices_opp_volume':
					opponentVocals.volume = nums.value;
					if (check_mute_vocals_opponent.checked)
						opponentVocals.volume = 0;
			}
		}
		else if (id == FlxUIInputText.CHANGE_EVENT && (sender is FlxUIInputText))
		{
			if (sender == noteSplashesInputText)
			{
				_song.splashSkin = noteSplashesInputText.text;
			}
			else if (sender == noteSkinInputText)
			{
				_song.arrowSkin = noteSkinInputText.text;
			}
			else if (sender == gameOverCharacterInputText)
			{
				_song.gameOverChar = gameOverCharacterInputText.text;
			}
			else if (sender == gameOverSoundInputText)
			{
				_song.gameOverSound = gameOverSoundInputText.text;
			}
			else if (sender == gameOverLoopInputText)
			{
				_song.gameOverLoop = gameOverLoopInputText.text;
			}
			else if (sender == gameOverEndInputText)
			{
				_song.gameOverEnd = gameOverEndInputText.text;
			}
			else if (curSelectedNote != null)
			{
				// ★ 防御：只有事件 note（[1] 为数组）才能编辑 value1/value2；
				//   普通 note 的 [1] 是轨道号 Int，直接索引会空指针崩溃（事件菜单编辑值时触发）
				var evGroupX:Array<Dynamic> = Std.is(curSelectedNote[1], Array) ? cast curSelectedNote[1] : null;
				if (sender == value1InputText)
				{
					if (evGroupX != null && curEventSelected >= 0 && curEventSelected < evGroupX.length
						&& evGroupX[curEventSelected] != null && Std.is(evGroupX[curEventSelected], Array))
					{
						evGroupX[curEventSelected][1] = value1InputText.text;
						updateGrid();
					}
				}
				else if (sender == value2InputText)
				{
					if (evGroupX != null && curEventSelected >= 0 && curEventSelected < evGroupX.length
						&& evGroupX[curEventSelected] != null && Std.is(evGroupX[curEventSelected], Array))
					{
						evGroupX[curEventSelected][2] = value2InputText.text;
						updateGrid();
					}
				}
				else if (sender == strumTimeInputText)
				{
					var value:Float = Std.parseFloat(strumTimeInputText.text);
					if (Math.isNaN(value))
						value = 0;
					curSelectedNote[0] = value;
					updateGrid();
				}
			}
		}
		else if (id == FlxUISlider.CHANGE_EVENT && (sender is FlxUISlider))
		{
			switch (sender)
			{
				case 'playbackSpeed':
					playbackSpeed = #if FLX_PITCH Std.int(sliderRate.value) #else 1.0 #end;
			}
		}

		// FlxG.log.add(id + " WEED " + sender + " WEED " + data + " WEED " + params);
	}

	var updatedSection:Bool = false;

	function sectionStartTime(add:Int = 0):Float
	{
		var daBPM:Float = _song.bpm;
		var daPos:Float = 0;
		for (i in 0...curSec + add)
		{
			if (_song.notes[i] != null)
			{
				if (_song.notes[i].changeBPM)
				{
					daBPM = _song.notes[i].bpm;
				}
				daPos += getSectionBeats(i) * (1000 * 60 / daBPM);
			}
		}
		return daPos;
	}

	var lastConductorPos:Float;
	var colorSine:Float = 0;

	var noteMove:Bool = false;
	var nowMoveNote = null;
	var timeCheck:Bool = false;

	override function update(elapsed:Float)
	{
		// ★ 菜单打开时，跳过所有鼠标相关的 grid 操作（addNote/deleteNote/noteMove 等）
		var menuBarOpen:Bool = (menuBar != null && menuBar.activeMenu >= 0);
		if (menuBarOpen)
		{
			// 不调任何 grid 鼠标逻辑，但其他业务（音乐时间、节拍）照常跑
		}

		curStep = recalculateSteps();

		if (FlxG.sound.music.time < 0)
		{
			FlxG.sound.music.pause();
			FlxG.sound.music.time = 0;
		}
		else if (FlxG.sound.music.time > FlxG.sound.music.length)
		{
			FlxG.sound.music.pause();
			FlxG.sound.music.time = 0;
			changeSection();
		}
		Conductor.songPosition = FlxG.sound.music.time;
		_song.song = UI_songTitle.text;

		strumLineUpdateY();
		for (i in 0...totalKeys)
		{
			strumLineNotes.members[i].y = strumLine.y;
		}

		FlxG.mouse.visible = true; // cause reasons. trust me
		camPos.y = strumLine.y;
		// ★ 相机目标 = 网格中心：让整张网格在屏幕上水平居中（原来用 CAM_OFFSET=360 固定偏移会偏左）
		camPos.x = strumLine.x + GRID_SIZE * (totalKeys + 1) / 2;
		if (!disableAutoScrolling.checked)
		{
			if (Math.ceil(strumLine.y) >= gridBG.height)
			{
				if (_song.notes[curSec + 1] == null)
				{
					addSection();
				}

				changeSection(curSec + 1, false);
			}
			else if (strumLine.y < -10)
			{
				changeSection(curSec - 1, false);
			}
		}
		FlxG.watch.addQuick('daBeat', curBeat);
		FlxG.watch.addQuick('daStep', curStep);

		if (virtualPad.buttonS.justPressed || FlxG.keys.justPressed.L)
		{
			if (noteMove)
			{
				noteMove = false;
			}
			else
			{
				noteMove = true;
			}
		}

		if (controls.mobileC)
		{
			for (touch in FlxG.touches.list)
			{
				// ★ 指针落在自定义移动按键上 → 该次触摸交给虚拟键，不处理网格
				if (pointerOnOverlay(touch.x, touch.y)) continue;
				// ★ 视图坐标：相机随 strumLine 纵向滚动，屏幕坐标须加 camera.scroll 才是网格坐标
				//  （否则 y → 时间的换算会整体偏移 → 音符放到错误的时间）
				var wx:Float = touch.x + FlxG.camera.scroll.x;
				var wy:Float = touch.y + FlxG.camera.scroll.y;
				if (touch.pressed
					&& noteMove
					&& wx > gridBG.x
					&& wx < gridBG.x + gridBG.width
					&& wy > gridBG.y
					&& wy < gridBG.y + (GRID_SIZE * getSectionBeats() * 4) * zoomList[curZoom])
				{
					if (touch.overlaps(curRenderedNotes))
					{
						curRenderedNotes.forEachAlive(function(note:Note)
						{
							if (touch.overlaps(note))
							{
								if (nowMoveNote == null)
								{
									nowMoveNote = note;
									selectNote(note);
								}
							}
						});
						nowMoveNote.y = wy;
					}
				}
				if (touch.justReleased && noteMove)
				{
					if (nowMoveNote != null
						&& wx > gridBG.x
						&& wx < gridBG.x + gridBG.width
						&& wy > gridBG.y
						&& wy < gridBG.y + (GRID_SIZE * getSectionBeats() * 4) * zoomList[curZoom])
					{
						addNote(null, nowMoveNote.noteData);
						deleteNote(nowMoveNote);
						nowMoveNote = null;
					}
				}
				if (touch.justReleased && !noteMove)
				{
					if (touch.overlaps(curRenderedNotes))
					{
						curRenderedNotes.forEachAlive(function(note:Note)
						{
							if (touch.overlaps(note))
							{
								deleteNote(note);
							}
						});
					}
					else
					{
						if (wx > gridBG.x
							&& wx < gridBG.x + gridBG.width
							&& wy > gridBG.y
							&& wy < gridBG.y + (GRID_SIZE * getSectionBeats() * 4) * zoomList[curZoom])
						{
							FlxG.log.add('added note');
							addNote();
						}
					}
				}

				if (wx > gridBG.x
					&& wx < gridBG.x + gridBG.width
					&& wy > gridBG.y
					&& wy < gridBG.y + (GRID_SIZE * getSectionBeats() * 4) * zoomList[curZoom])
				{
					dummyArrow.visible = true;
					dummyArrow.x = getGridX() + Math.floor((wx - getGridX()) / GRID_SIZE) * GRID_SIZE;
					if (FlxG.keys.pressed.SHIFT || virtualPad.buttonY.pressed)
						dummyArrow.y = wy;
					else
						dummyArrow.y = Math.floor(wy / GRID_SIZE) * GRID_SIZE;
				}
				else
				{
					dummyArrow.visible = false;
				}
			}
		}
		else
		{
			// ★ 菜单打开 / 指针落在自定义移动按键上时，整段 grid 鼠标操作跳过
			//   （noteMove / addNote / deleteNote / dummyArrow）
			if (!menuBarOpen && !pointerOnOverlay(FlxG.mouse.x, FlxG.mouse.y))
			{
			// ★ 鼠标用世界坐标（flixel 5.9.0 里 `FlxG.mouse.x/y` 已经 = getWorldPosition(cam)，
			//   含 camera.scroll；`viewX/Y` 只是屏幕坐标，跟 gridBG/getGridX 这些世界坐标混用
			//   会让高光方格相对鼠标固定偏移 camPos.x，滚轮改变 scroll.y 时偏移跟着变 → 视觉/交互错位）
			//   grid 网格坐标 = world 坐标；下面所有 mvx/mvy 都按世界坐标参与列号/行号换算。
			var mvx:Float = FlxG.mouse.x;
			var mvy:Float = FlxG.mouse.y;
			if (FlxG.mouse.pressedRight
				&& mvx > gridBG.x
				&& mvx < gridBG.x + gridBG.width
				&& mvy > gridBG.y
				&& mvy < gridBG.y + (GRID_SIZE * getSectionBeats() * 4) * zoomList[curZoom])
			{
				noteMove = true;
				if (FlxG.mouse.overlaps(curRenderedNotes))
				{
					curRenderedNotes.forEachAlive(function(note:Note)
					{
						if (FlxG.mouse.overlaps(note))
						{
							if (nowMoveNote == null)
							{
								nowMoveNote = note;
								selectNote(note);
							}
						}
					});
					nowMoveNote.y = mvy;
				}
			}
			if (FlxG.mouse.justReleasedRight)
			{
				noteMove = false;
				if (nowMoveNote != null
					&& mvx > gridBG.x
					&& mvx < gridBG.x + gridBG.width
					&& mvy > gridBG.y
					&& mvy < gridBG.y + (GRID_SIZE * getSectionBeats() * 4) * zoomList[curZoom])
				{
					addNote(null, nowMoveNote.noteData);
					deleteNote(nowMoveNote);
					nowMoveNote = null;
				}
			}

			// ★ 菜单栏下拉打开时已在外层 if (!menuBarOpen) 跳过整段
			if (FlxG.mouse.justPressed && !noteMove)
			{
				if (FlxG.mouse.overlaps(curRenderedNotes))
				{
					curRenderedNotes.forEachAlive(function(note:Note)
					{
						if (FlxG.mouse.overlaps(note))
						{
							// ★ 自定义移动键位模式（EditorMobileKeys）下忽略 Ctrl/Alt 点击修饰：
							//   虚拟修饰键可能残留/组合触发，会让"点击删除"变成选择 → 点击事件像被消除
							var useMods:Bool = (FlxG.keys.pressed.CONTROL || FlxG.keys.pressed.ALT) && !EditorMobileKeys.isEnabled();
							if (useMods && FlxG.keys.pressed.CONTROL)
							{
								selectNote(note);
							}
							else if (useMods && FlxG.keys.pressed.ALT)
							{
								selectNote(note);
								curSelectedNote[3] = curNoteTypes[currentType];
								updateGrid();
							}
							else
							{
								// trace('tryin to delete note...');
								deleteNote(note);
							}
						}
					});
				}
				else
				{
					if (mvx > gridBG.x
						&& mvx < gridBG.x + gridBG.width
						&& mvy > gridBG.y
						&& mvy < gridBG.y + (GRID_SIZE * getSectionBeats() * 4) * zoomList[curZoom])
					{
						FlxG.log.add('added note');
						addNote();
					}
				}
			}

			if (mvx > gridBG.x
				&& mvx < gridBG.x + gridBG.width
				&& mvy > gridBG.y
				&& mvy < gridBG.y + (GRID_SIZE * getSectionBeats() * 4) * zoomList[curZoom])
			{
				dummyArrow.visible = true;
				dummyArrow.x = getGridX() + Math.floor((mvx - getGridX()) / GRID_SIZE) * GRID_SIZE;
				if (FlxG.keys.pressed.SHIFT)
					dummyArrow.y = mvy;
				else
					dummyArrow.y = Math.floor(mvy / GRID_SIZE) * GRID_SIZE;
			}
			else
			{
				dummyArrow.visible = false;
			}
			} // end if (!menuBarOpen)
		}

		var blockInput:Bool = false;
		for (inputText in blockPressWhileTypingOn)
		{
			if (inputText.hasFocus)
			{
				ClientPrefs.toggleVolumeKeys(false);
				blockInput = true;
				break;
			}
		}

		if (!blockInput)
		{
			for (stepper in blockPressWhileTypingOnStepper)
			{
				@:privateAccess
				var leText:FlxUIInputText = cast(stepper.text_field, FlxUIInputText);
				if (leText.hasFocus)
				{
					ClientPrefs.toggleVolumeKeys(false);
					blockInput = true;
					break;
				}
			}
		}

		if (!blockInput)
		{
			ClientPrefs.toggleVolumeKeys(true);
			for (dropDownMenu in blockPressWhileScrolling)
			{
				if (dropDownMenu.dropPanel.visible)
				{
					blockInput = true;
					break;
				}
			}
		}

		if (!blockInput)
		{
			// ================= 全局快捷键（F1~F8 开菜单；其余在菜单打开时禁用） =================
			var menuOpen:Bool = (menuBar != null && menuBar.activeMenu >= 0);
			if (FlxG.keys.justPressed.F1) menuBar.openMenu(0);
			else if (FlxG.keys.justPressed.F2) menuBar.openMenu(1);
			else if (FlxG.keys.justPressed.F3) menuBar.openMenu(2);
			else if (FlxG.keys.justPressed.F4) menuBar.openMenu(3);
			else if (FlxG.keys.justPressed.F5) menuBar.openMenu(4);
			else if (FlxG.keys.justPressed.F6) menuBar.openMenu(5);
			else if (FlxG.keys.justPressed.F7) menuBar.openMenu(6);
			else if (FlxG.keys.justPressed.F8) menuBar.openMenu(7);
			else if (!menuOpen)
			{
				var ctrlHeld:Bool = FlxG.keys.pressed.CONTROL;
				var shiftHeld:Bool = FlxG.keys.pressed.SHIFT;
				var altHeld:Bool = FlxG.keys.pressed.ALT;

				// Shift+Del = 清空事件 / Ctrl+Del = 清空 Note（FlxKey 不区分左右，任意侧修饰键均可）
				if (FlxG.keys.justPressed.DELETE)
				{
					if (shiftHeld) { handleMenuAction('clear_events'); }
					else if (ctrlHeld) { handleMenuAction('clear_notes'); }
				}

				// Ctrl+Shift 组合：重载/载入/保存事件系列 + Vortex + 打击音
				if (ctrlHeld && shiftHeld && !altHeld)
				{
					if (FlxG.keys.justPressed.Q) handleMenuAction('reload_audio');
					else if (FlxG.keys.justPressed.W) handleMenuAction('reload_json');
					else if (FlxG.keys.justPressed.E) handleMenuAction('load_autosave');
					else if (FlxG.keys.justPressed.R) handleMenuAction('load_events');
					else if (FlxG.keys.justPressed.S) handleMenuAction('save_events');
					else if (FlxG.keys.justPressed.TAB) toggleVortexShortcut();
					else if (FlxG.keys.justPressed.U) toggleSfxShortcut('bf');
					else if (FlxG.keys.justPressed.O) toggleSfxShortcut('opp');
				}

				// Alt+Ctrl+U/I/O = 静音 BF / Inst / Opp；Alt+U/I/O = 波形图 BF / Inst / Opp
				if (altHeld && ctrlHeld && !shiftHeld)
				{
					if (FlxG.keys.justPressed.U) toggleMuteShortcut('bf');
					else if (FlxG.keys.justPressed.I) toggleMuteShortcut('inst');
					else if (FlxG.keys.justPressed.O) toggleMuteShortcut('opp');
				}
				if (altHeld && !ctrlHeld && !shiftHeld)
				{
					if (FlxG.keys.justPressed.U) toggleWaveformShortcut('bf');
					else if (FlxG.keys.justPressed.I) toggleWaveformShortcut('inst');
					else if (FlxG.keys.justPressed.O) toggleWaveformShortcut('opp');
				}

				// Ctrl 组合：U/I/O = 交换/二重奏/镜像；C/V = 复制/粘贴小节；S = 保存；Z = 撤销（下方原有）
				if (ctrlHeld && !shiftHeld && !altHeld)
				{
					if (FlxG.keys.justPressed.U) swapSectionSides();
					else if (FlxG.keys.justPressed.I) duetCurrentSection();
					else if (FlxG.keys.justPressed.O) mirrorCurrentSection();
					else if (FlxG.keys.justPressed.C) copyCurrentSection();
					else if (FlxG.keys.justPressed.V) pasteToCurrentSection();
					else if (FlxG.keys.justPressed.S) handleMenuAction('save');
				}

				// 单键：U = 玩家小节 / I = GF 小节 / O = Opponents 小节（★ 切换后立即刷新背景/波形归属）
				if (!ctrlHeld && !shiftHeld && !altHeld)
				{
					if (FlxG.keys.justPressed.U)
					{
						_song.notes[curSec].mustHitSection = true;
						check_mustHitSection.checked = true;
						updateHeads();
						reloadGridLayer();
					}
					else if (FlxG.keys.justPressed.I)
					{
						_song.notes[curSec].gfSection = !_song.notes[curSec].gfSection;
						check_gfSection.checked = _song.notes[curSec].gfSection;
						updateGrid();
						updateHeads();
					}
					else if (FlxG.keys.justPressed.O)
					{
						_song.notes[curSec].mustHitSection = false;
						check_mustHitSection.checked = false;
						updateHeads();
						reloadGridLayer();
					}
				}

				// 按住 K + 数字键 = 设置 Mania（`=1K、1=2K … 9=10K）
				if (FlxG.keys.pressed.K && !ctrlHeld && !shiftHeld && !altHeld)
				{
					if (FlxG.keys.justPressed.GRAVEACCENT) setManiaByKey(1);
					else if (FlxG.keys.justPressed.ONE) setManiaByKey(2);
					else if (FlxG.keys.justPressed.TWO) setManiaByKey(3);
					else if (FlxG.keys.justPressed.THREE) setManiaByKey(4);
					else if (FlxG.keys.justPressed.FOUR) setManiaByKey(5);
					else if (FlxG.keys.justPressed.FIVE) setManiaByKey(6);
					else if (FlxG.keys.justPressed.SIX) setManiaByKey(7);
					else if (FlxG.keys.justPressed.SEVEN) setManiaByKey(8);
					else if (FlxG.keys.justPressed.EIGHT) setManiaByKey(9);
					else if (FlxG.keys.justPressed.NINE) setManiaByKey(10);
				}
			}
			// ================= 快捷键结束 =================

			if (FlxG.keys.justPressed.ESCAPE || virtualPad.buttonC.justPressed)
			{
				startPlaytest();
			}
			else if (FlxG.keys.justPressed.ENTER || virtualPad.buttonA.justPressed)
			{
				startNormalPlay();
			}

			if (curSelectedNote != null && curSelectedNote[1] > -1)
			{
				if (FlxG.keys.justPressed.E || virtualPad.buttonE.justPressed)
				{
					changeNoteSustain(Conductor.stepCrochet);
				}
				if (FlxG.keys.justPressed.Q || virtualPad.buttonP.justPressed)
				{
					changeNoteSustain(-Conductor.stepCrochet);
				}
			}

			if (FlxG.keys.justPressed.BACKSPACE || virtualPad.buttonB.justPressed)
			{
				// Protect against lost data when quickly leaving the chart editor.
				autosaveSong();
				PlayState.chartingMode = false;
				if (!isFreePlay)
					MusicBeatState.switchState(new developer.editors.MasterEditorMenu());
				else
				{
					MusicBeatState.switchState(new states.freeplayState.FreeplayState());
				}
				isFreePlay = false;
				FlxG.sound.playMusic(Paths.music('freakyMenu'));
				FlxG.mouse.visible = false;
				return;
			}

			if (virtualPad.buttonV.justPressed || FlxG.keys.justPressed.Z && FlxG.keys.pressed.CONTROL)
			{
				undo();
			}

			// ★ Z/X 缩放：桌面与虚拟按键统一带边界守卫（原来桌面分支无守卫，
			//   在最小档再按 Z 会把 curZoom 减成 -1 → zoomList[-1] 越界 → 崩溃）
			if ((FlxG.keys.justPressed.Z || virtualPad.buttonZ.justPressed) && curZoom > 0 && !FlxG.keys.pressed.CONTROL)
			{
				--curZoom;
				updateZoom();
			}
			if ((FlxG.keys.justPressed.X || virtualPad.buttonD.justPressed) && curZoom < zoomList.length - 1)
			{
				curZoom++;
				updateZoom();
			}

			if (FlxG.keys.justPressed.TAB || virtualPad.buttonG.justPressed)
			{
				// 如果新菜单系统正在显示下拉菜单，拦截 TAB 键（防止切换旧 tab）
				if (menuBar != null && menuBar.activeMenu >= 0)
				{
					// 不做任何事，让 TAB 给下拉菜单里的 widget 使用
				}
				else
				{
					if (FlxG.keys.pressed.SHIFT)
					{
						UI_box.selected_tab -= 1;
						if (UI_box.selected_tab < 0)
							UI_box.selected_tab = 5;
					}
					else
					{
						UI_box.selected_tab += 1;
						if (UI_box.selected_tab > 5)
							UI_box.selected_tab = 0;
					}
				}
			}

			if (FlxG.keys.justPressed.SPACE || virtualPad.buttonX.justPressed)
			{
				if (vocals != null)
					vocals.play();
				if (opponentVocals != null)
					opponentVocals.play();
				pauseAndSetVocalsTime();
				if (!FlxG.sound.music.playing)
				{
					FlxG.sound.music.play();
					if (vocals != null)
						vocals.play();
					if (opponentVocals != null)
						opponentVocals.play();
				}
				else
					FlxG.sound.music.pause();
			}

			if (!FlxG.keys.pressed.ALT && FlxG.keys.justPressed.R)
			{
				if (FlxG.keys.pressed.SHIFT)
					resetSection(true);
				else
					resetSection();
			}

			// ★ 菜单（含下拉列表）打开时滚轮归菜单用，不再滚动谱面时间
			if (!controls.mobileC && !(menuBar != null && menuBar.activeMenu >= 0))
			{
				if (FlxG.mouse.wheel != 0)
				{
					FlxG.sound.music.pause();
					if (!mouseQuant)
						FlxG.sound.music.time -= (FlxG.mouse.wheel * Conductor.stepCrochet * 0.8);
					else
					{
						var time:Float = FlxG.sound.music.time;
						var beat:Float = curDecBeat;
						var snap:Float = quantization / 4;
						var increase:Float = 1 / snap;
						if (FlxG.mouse.wheel > 0)
						{
							var fuck:Float = CoolUtil.quantize(beat, snap) - increase;
							FlxG.sound.music.time = Conductor.beatToSeconds(fuck);
						}
						else
						{
							var fuck:Float = CoolUtil.quantize(beat, snap) + increase;
							FlxG.sound.music.time = Conductor.beatToSeconds(fuck);
						}
					}
					pauseAndSetVocalsTime();
				}
			}

			// ARROW VORTEX SHIT NO DEADASS

			// Vertical time scroll: W/S (desktop) or pad up/down (mobile)
			var vertUp = controls.mobileC ? virtualPad.buttonUp.pressed : FlxG.keys.pressed.W;
			var vertDown = controls.mobileC ? virtualPad.buttonDown.pressed : FlxG.keys.pressed.S;
			if (vertUp || vertDown)
			{
				FlxG.sound.music.pause();

				var holdingShift:Float = 1;
				if (FlxG.keys.pressed.CONTROL && !controls.mobileC)
					holdingShift = 0.25;
				else if (FlxG.keys.pressed.SHIFT || virtualPad.buttonY.pressed)
					holdingShift = 4;

				var daTime:Float = 700 * FlxG.elapsed * holdingShift;

				FlxG.sound.music.time += daTime * (vertUp ? -1 : 1);

				pauseAndSetVocalsTime();
			}

			if (!vortex)
			{
				if (FlxG.keys.justPressed.UP || FlxG.keys.justPressed.DOWN)
				{
					FlxG.sound.music.pause();
					updateCurStep();
					var time:Float = FlxG.sound.music.time;
					var beat:Float = curDecBeat;
					var snap:Float = quantization / 4;
					var increase:Float = 1 / snap;
					if (FlxG.keys.pressed.UP)
					{
						var fuck:Float = CoolUtil.quantize(beat, snap) - increase; // (Math.floor((beat+snap) / snap) * snap);
						FlxG.sound.music.time = Conductor.beatToSeconds(fuck);
					}
					else
					{
						var fuck:Float = CoolUtil.quantize(beat, snap) + increase; // (Math.floor((beat+snap) / snap) * snap);
						FlxG.sound.music.time = Conductor.beatToSeconds(fuck);
					}
				}
			}

			var style = currentType;

			if (FlxG.keys.pressed.SHIFT || virtualPad.buttonY.pressed)
			{
				style = 3;
			}

			var conductorTime = Conductor.songPosition; // + sectionStartTime();Conductor.songPosition / Conductor.stepCrochet;

			// AWW YOU MADE IT SEXY <3333 THX SHADMAR

			if (!blockInput)
			{
				if (FlxG.keys.justPressed.RIGHT && !FlxG.keys.pressed.CONTROL)
				{
					curQuant++;
					if (curQuant > quantizations.length - 1)
						curQuant = 0;

					quantization = quantizations[curQuant];
				}

				if (FlxG.keys.justPressed.LEFT && !FlxG.keys.pressed.CONTROL)
				{
					curQuant--;
					if (curQuant < 0)
						curQuant = quantizations.length - 1;

					quantization = quantizations[curQuant];
				}
				quant.animation.play('q', true, false, curQuant);
			}
			if (vortex && !blockInput)
			{
				var controlArray:Array<Bool> = [
					 FlxG.keys.justPressed.ONE, FlxG.keys.justPressed.TWO, FlxG.keys.justPressed.THREE, FlxG.keys.justPressed.FOUR,
					FlxG.keys.justPressed.FIVE, FlxG.keys.justPressed.SIX, FlxG.keys.justPressed.SEVEN, FlxG.keys.justPressed.EIGHT
				];

				if (controlArray.contains(true))
				{
					for (i in 0...controlArray.length)
					{
						if (controlArray[i])
							doANoteThing(conductorTime, i, style);
					}
				}

				var feces:Float;
				if (FlxG.keys.justPressed.UP || FlxG.keys.justPressed.DOWN)
				{
					FlxG.sound.music.pause();

					updateCurStep();
					// FlxG.sound.music.time = (Math.round(curStep/quants[curQuant])*quants[curQuant]) * Conductor.stepCrochet;

					// (Math.floor((curStep+quants[curQuant]*1.5/(quants[curQuant]/2))/quants[curQuant])*quants[curQuant]) * Conductor.stepCrochet;//snap into quantization
					var time:Float = FlxG.sound.music.time;
					var beat:Float = curDecBeat;
					var snap:Float = quantization / 4;
					var increase:Float = 1 / snap;
					if (FlxG.keys.pressed.UP)
					{
						var fuck:Float = CoolUtil.quantize(beat, snap) - increase;
						feces = Conductor.beatToSeconds(fuck);
					}
					else
					{
						var fuck:Float = CoolUtil.quantize(beat, snap) + increase; // (Math.floor((beat+snap) / snap) * snap);
						feces = Conductor.beatToSeconds(fuck);
					}
					FlxTween.tween(FlxG.sound.music, {time: feces}, 0.1, {ease: FlxEase.circOut});
					pauseAndSetVocalsTime();

					var dastrum = 0;

					if (curSelectedNote != null)
					{
						dastrum = curSelectedNote[0];
					}

					var secStart:Float = sectionStartTime();
					var datime = (feces - secStart) - (dastrum - secStart); // idk math find out why it doesn't work on any other section other than 0
					if (curSelectedNote != null)
					{
						var controlArray:Array<Bool> = [
							 FlxG.keys.pressed.ONE, FlxG.keys.pressed.TWO, FlxG.keys.pressed.THREE, FlxG.keys.pressed.FOUR,
							FlxG.keys.pressed.FIVE, FlxG.keys.pressed.SIX, FlxG.keys.pressed.SEVEN, FlxG.keys.pressed.EIGHT
						];

						if (controlArray.contains(true))
						{
							for (i in 0...controlArray.length)
							{
								if (controlArray[i])
									if (curSelectedNote[1] == i)
										curSelectedNote[2] += datime - curSelectedNote[2] - Conductor.stepCrochet;
							}
							updateGrid();
							updateNoteUI();
						}
					}
				}
			}
			var shiftThing:Int = 1;
			// ★ Alt = ×10 小节、Shift = ×4、默认 ×1
			if (FlxG.keys.pressed.ALT)
				shiftThing = 10;
			else if (FlxG.keys.pressed.SHIFT || virtualPad.buttonY.pressed)
				shiftThing = 4;

			if (FlxG.keys.justPressed.D || virtualPad.buttonRight.justPressed)
				changeSection(curSec + shiftThing);
			if (FlxG.keys.justPressed.A || virtualPad.buttonLeft.justPressed)
			{
				if (curSec <= 0)
				{
					changeSection(_song.notes.length - 1);
				}
				else
				{
					changeSection(curSec - shiftThing);
				}
			}
		}
		else if (FlxG.keys.justPressed.ENTER)
		{
			for (i in 0...blockPressWhileTypingOn.length)
			{
				if (blockPressWhileTypingOn[i].hasFocus)
				{
					blockPressWhileTypingOn[i].hasFocus = false;
				}
			}
		}

		strumLineNotes.visible = quant.visible = vortex;

		if (FlxG.sound.music.time < 0)
		{
			FlxG.sound.music.pause();
			FlxG.sound.music.time = 0;
		}
		else if (FlxG.sound.music.time > FlxG.sound.music.length)
		{
			FlxG.sound.music.pause();
			FlxG.sound.music.time = 0;
			changeSection();
		}
		Conductor.songPosition = FlxG.sound.music.time;
		strumLineUpdateY();
		camPos.y = strumLine.y;
		// ★ 相机目标 = 网格中心（保持屏幕水平居中）
		camPos.x = strumLine.x + GRID_SIZE * (totalKeys + 1) / 2;
		for (i in 0...totalKeys)
		{
			strumLineNotes.members[i].y = strumLine.y;
			strumLineNotes.members[i].alpha = FlxG.sound.music.playing ? 1 : 0.35;
		}

		#if FLX_PITCH
		// PLAYBACK SPEED CONTROLS //
		var holdingShift = FlxG.keys.pressed.SHIFT;
		var holdingLB = FlxG.keys.pressed.LBRACKET;
		var holdingRB = FlxG.keys.pressed.RBRACKET;
		var pressedLB = FlxG.keys.justPressed.LBRACKET;
		var pressedRB = FlxG.keys.justPressed.RBRACKET;

		if (!holdingShift && pressedLB || holdingShift && holdingLB)
			playbackSpeed -= 0.01;
		if (!holdingShift && pressedRB || holdingShift && holdingRB)
			playbackSpeed += 0.01;
		if (FlxG.keys.pressed.ALT && (pressedLB || pressedRB || holdingLB || holdingRB) || virtualPad.buttonV.pressed)
			playbackSpeed = 1;
		//

		if (playbackSpeed <= 0.5)
			playbackSpeed = 0.5;
		if (playbackSpeed >= 3)
			playbackSpeed = 3;

		FlxG.sound.music.pitch = playbackSpeed;
		vocals.pitch = playbackSpeed;
		opponentVocals.pitch = playbackSpeed;
		#end

		var curTimeSec:Float = FlxMath.roundDecimal(Conductor.songPosition / 1000, 2);
		var totalTimeSec:Float = FlxMath.roundDecimal(FlxG.sound.music.length / 1000, 2);

		// 同步到新顶栏状态栏（原生 bpmTxt 已隐藏，不再逐帧拼字符串）
		if (menuBar != null && menuBar.statusBar != null)
		{
			// ★ 秒数恒保留两位小数（尾数 0 也保留）：0 → "0.00"、1.5 → "1.50"
			menuBar.statusBar.setTempo(fmt2(curTimeSec) + 's / ' + fmt2(totalTimeSec) + 's');
			menuBar.statusBar.setClock(FlxStringUtil.formatTime(curTimeSec) + ' / ' + FlxStringUtil.formatTime(totalTimeSec));
			menuBar.statusBar.setSection(Std.string(curSec));
			menuBar.statusBar.setBeat(Std.string(curDecBeat).substring(0, 4));
			var snapSuffix = if ((quantization - 2) % 10 == 0 && quantization != 12) "nd"; else "th";
			menuBar.statusBar.setSnap(Std.string(quantization) + snapSuffix);
			menuBar.statusBar.setMove(Std.string(noteMove));
		}

		var playedSound:Array<Bool> = []; // Prevents ouchy GF sex sounds
		for (i in 0...totalKeys)
			playedSound.push(false);
		curRenderedNotes.forEachAlive(function(note:Note)
		{
			note.alpha = 1;
			if (curSelectedNote != null)
			{
				var noteDataToCheck:Int = note.noteData;
				if (noteDataToCheck > -1 && note.mustPress != _song.notes[curSec].mustHitSection)
					noteDataToCheck += leftKeys;

				if (curSelectedNote[0] == note.strumTime
					&& ((curSelectedNote[2] == null && noteDataToCheck < 0)
						|| (curSelectedNote[2] != null && curSelectedNote[1] == noteDataToCheck)))
				{
					colorSine += elapsed;
					var colorVal:Float = 0.7 + Math.sin(Math.PI * colorSine) * 0.3;
					note.color = FlxColor.fromRGBFloat(colorVal, colorVal, colorVal,
						0.999); // Alpha can't be 100% or the color won't be updated for some reason, guess i will die
				}
			}

			if (note.strumTime <= Conductor.songPosition)
			{
				note.alpha = 0.4;
				if (note.strumTime > lastConductorPos && FlxG.sound.music.playing && note.noteData > -1)
				{
					var data:Int = note.noteData % leftKeys;
					var noteDataToCheck:Int = note.noteData;
					if (noteDataToCheck > -1 && note.mustPress != _song.notes[curSec].mustHitSection)
						noteDataToCheck += 4;
					strumLineNotes.members[noteDataToCheck].playAnim('confirm', true);
					strumLineNotes.members[noteDataToCheck].resetAnim = ((note.sustainLength / 1000) + 0.15) / playbackSpeed;
					if (!playedSound[data])
					{
						if (note.hitsoundChartEditor
							&& ((playSoundBf.checked && note.mustPress) || (playSoundDad.checked && !note.mustPress)))
						{
							var soundToPlay = note.hitsound;
							if (_song.player1 == 'gf') // Easter egg
								soundToPlay = 'GF_' + Std.string(data + 1);

							FlxG.sound.play(Paths.sound(soundToPlay)).pan = note.noteData < leftKeys ? -0.3 : 0.3; // would be coolio
							playedSound[data] = true;
						}

						data = note.noteData;
						if (note.mustPress != _song.notes[curSec].mustHitSection)
						{
							data += leftKeys;
						}
					}
				}
			}
		});

		if (metronome.checked && lastConductorPos != Conductor.songPosition)
		{
			var metroInterval:Float = 60 / metronomeStepper.value;
			var metroStep:Int = Math.floor(((Conductor.songPosition + metronomeOffsetStepper.value) / metroInterval) / 1000);
			var lastMetroStep:Int = Math.floor(((lastConductorPos + metronomeOffsetStepper.value) / metroInterval) / 1000);
			if (metroStep != lastMetroStep)
			{
				FlxG.sound.play(Paths.sound('Metronome_Tick'));
				// trace('Ticked');
			}
		}
		lastConductorPos = Conductor.songPosition;
		super.update(elapsed);
	}

	function pauseAndSetVocalsTime()
	{
		if (vocals != null)
		{
			vocals.pause();
			vocals.time = FlxG.sound.music.time;
		}

		if (opponentVocals != null)
		{
			opponentVocals.pause();
			opponentVocals.time = FlxG.sound.music.time;
		}
	}

	/** 秒数格式化：恒保留两位小数（0 → "0.00"、1.5 → "1.50"） */
	function fmt2(v:Float):String
	{
		var neg:Bool = v < 0;
		if (neg) v = -v;
		var whole:Int = Math.floor(v);
		var frac:Int = Math.round((v - whole) * 100);
		if (frac >= 100) { frac -= 100; whole++; }
		var s:String = Std.string(whole) + '.' + (frac < 10 ? '0' : '') + Std.string(frac);
		return neg ? '-' + s : s;
	}

	/** ★ 自定义移动按键 overlay 是否命中了 (mx,my)（逻辑屏幕坐标）——
	 *  命中 = 该指针是点在虚拟键上，网格点击应跳过（避免放/删音符与虚拟键操作互相干扰） */
	function pointerOnOverlay(mx:Float, my:Float):Bool
	{
		var ov:Dynamic = editorMobileOverlay;
		if (ov == null) return false;
		try
		{
			if (ov.visible != true || ov.active != true) return false;
			return ov.hitTest(mx, my) == true;
		}
		catch (e:Dynamic) {}
		return false;
	}

	function updateZoom()
	{
		// ★ 双保险：curZoom 越界直接 clamp（防任何路径把索引改出界）
		curZoom = Std.int(FlxMath.bound(curZoom, 0, zoomList.length - 1));
		var daZoom:Float = zoomList[curZoom];
		var zoomThing:String = '1 / ' + daZoom;
		if (daZoom < 1)
			zoomThing = Math.round(1 / daZoom) + ' / 1';
		zoomTxt.text = 'Zoom: ' + zoomThing;
		// 同步到新顶栏菜单的状态栏
		if (menuBar != null && menuBar.statusBar != null)
			menuBar.statusBar.setZoom(zoomThing);
		reloadGridLayer();
	}

	override function destroy()
	{
		Note.globalRgbShaders = [];
		games.backend.NoteTypesConfig.clearNoteTypesData();
		super.destroy();
	}

	var lastSecBeats:Float = 0;
	var lastSecBeatsNext:Float = 0;

	/** 网格左缘 x：整张网格（含节拍列）相对屏幕水平居中 */
	function getGridX():Float
	{
		return (FlxG.width - GRID_SIZE * (totalKeys + 1)) / 2;
	}

	/** 角色 healthBarColor（Psych 标准角色名映射：bf=蓝、dad=紫红、gf=绿、monster=紫、pico=青、mom=粉…）。
	 *  ★ 未知角色返回 -1，由调用方用角色图标主色（dominantColor）兜底——不固定颜色，
	 *    换任何角色当 BF/Opp 时背景/波形颜色都会跟着变。 */
	public static function getCharHealthColor(char:String):Int
	{
		switch (char)
		{
			case 'bf' | 'bf-pixel' | 'bf-car' | 'bf-christmas' | 'bf-holding-gf': return 0xFF31B0D1;
			case 'dad' | 'dad-pixel' | 'dad-car' | 'dad-christmas' | 'dad-week1' | 'dad-week2' | 'dad-week3' | 'bf-pixel-opponent': return 0xFFA32E4B;
			case 'gf' | 'gf-pixel' | 'gf-christmas' | 'gf-car': return 0xFFA6E22E;
			case 'monster' | 'monster-pixel': return 0xFF8F6BFF;
			case 'pico' | 'pico-pixel': return 0xFF00E9FF;
			case 'mom' | 'mom-pixel': return 0xFFFF78BF;
			case 'spooky' | 'spooky-pixel': return 0xFF7C7C7C;
			case 'tankman' | 'tankman-pixel': return 0xFF4B4B4B;
			case 'face': return 0xFFFFE172;
			default: return -1;
		}
	}

	/** ★ 角色颜色 = 纯歌曲数据驱动，与屏幕上的头像状态完全无关（顺序无关、换曲即正确）：
	 *  1) 内置角色名映射 getCharHealthColor
	 *  2) 角色 JSON 的 healthbar_colors（updateJsonData 时缓存进 characterData）
	 *  3) 独立加载该角色图标提取主色（带缓存）——不再读 leftIcon/rightIcon 的显示状态，
	 *     否则小节换边/换曲时图标滞后会导致左右颜色错位或永远不更新
	 *  4) 兜底色 */
	function resolveCharColor(char:String, fallback:Int):Int
	{
		var mapped:Int = getCharHealthColor(char);
		if (mapped >= 0) return mapped;

		var slot:Int = 0;
		var iconName:String = null;
		var hb:Array<Int> = null;
		if (_song != null && characterData != null)
		{
			for (i in 1...3)
			{
				if (Reflect.field(_song, 'player$i') == char)
				{
					slot = i;
					break;
				}
			}
			if (slot > 0)
			{
				hb = Reflect.field(characterData, 'healthP$slot');
				iconName = Reflect.field(characterData, 'iconP$slot');
			}
		}
		if (hb != null && hb.length > 2)
			return 0xFF000000 | (Std.int(hb[0]) << 16) | (Std.int(hb[1]) << 8) | Std.int(hb[2]);
		if (iconName == null) iconName = char;
		if (charColorCache.exists(iconName)) return charColorCache.get(iconName);
		var col:Int = -1;
		try
		{
			var tmp:HealthIcon = new HealthIcon(iconName);
			if (tmp.graphic != null && tmp.graphic.bitmap != null)
				col = CoolUtil.dominantColor(tmp);
			tmp.destroy();
		}
		catch (e:Dynamic) {}
		charColorCache.set(iconName, col);
		return col >= 0 ? col : fallback;
	}

	function reloadGridLayer()
	{

		if (PlayState.SONG == null) {
			PlayState.SONG = {
				song: 'DUMMY',
				notes: [],
				events: [],
				bpm: 1,
				mania: _song.mania,
				needsVoices: true,
				player1: 'bf',
				player2: 'bf',
				gfVersion: 'bf',
				speed: 1,
				format: 'na',
				stage: 'stage'
			};
		} else {
			PlayState.SONG.mania = _song.mania;
		}

		gridLayer.clear();
		// ★ 网格背景分侧：每个 note 区间（轨道列）一块对应角色的 healthBarColor 半透明背景
		//   （角色原色，非反色）。★ 颜色跟随 mustHitSection：左区域 = 当前小节左侧角色（BF 小节=player1，
		//   对手小节=player2），右区域反之——换角色后颜色立即跟随（未知角色从图标提主色，绝不固定）。
		var bfSideL:Bool = (_song.notes[curSec].mustHitSection != false);
		var leftChar:String = bfSideL ? _song.player1 : _song.player2;
		var rightChar:String = bfSideL ? _song.player2 : _song.player1;
		// ★ 读取失败（找不到角色/文件/图标）一律用 #666666，不做任何猜测色
		var leftC:Int = resolveCharColor(leftChar, 0xFF666666);
		var rightC:Int = resolveCharColor(rightChar, 0xFF666666);

		// ★ 行数下限 1：防止 sectionBeats/zoom 异常时 0 行位图崩溃
		var gridRows:Int = Std.int(Math.max(1, getSectionBeats() * 4 * zoomList[curZoom]));
		gridBG = FlxGridOverlay.create(1, 1, totalKeys + 1, gridRows, false, 0xFFFFFFFF, 0xFFFFFFFF);
		gridBG.antialiasing = false;
		gridBG.scale.set(GRID_SIZE, GRID_SIZE);
		gridBG.updateHitbox();
		// ★ 网格水平居中（mania 变化时总宽变化，x 自动重新居中，不再向右延申）
		gridBG.x = getGridX();
		gridBG.alpha = 0; // 透明：范围判断与高度参考用

		// ★ 每轨背景块（跳过第一列节拍列；半透明角色原色）
		var gridH:Int = Std.int(gridBG.height);
		for (i in 0...totalKeys)
		{
			var laneBg:FlxSprite = new FlxSprite(gridBG.x + GRID_SIZE * (i + 1), gridBG.y);
			laneBg.makeGraphic(GRID_SIZE - 1, gridH, i < leftKeys ? leftC : rightC);
			laneBg.alpha = 0.35;
			laneBg.antialiasing = false;
			gridLayer.add(laneBg);
		}

		// ★ 每一格画横线（对位用，半透明白）
		var rowsN:Int = gridRows;
		for (r in 1...rowsN)
		{
			var hLine:FlxSprite = new FlxSprite(gridBG.x, GRID_SIZE * r).makeGraphic(Std.int(gridBG.width), 1, 0x33FFFFFF);
			hLine.antialiasing = false;
			gridLayer.add(hLine);
		}

		#if (desktop || mobile)
		if (FlxG.save.data.chart_waveformInst || FlxG.save.data.chart_waveformVoices || FlxG.save.data.chart_waveformOppVoices)
		{
			updateWaveform();
		}
		#end

		var leHeight:Int = Std.int(gridBG.height);
		var foundNextSec:Bool = false;
		if (sectionStartTime(1) <= FlxG.sound.music.length)
		{
			var nextRows:Int = Std.int(Math.max(1, getSectionBeats(curSec + 1) * 4 * zoomList[curZoom]));
			nextGridBG = FlxGridOverlay.create(1, 1, totalKeys + 1, nextRows);
			nextGridBG.antialiasing = false;
			nextGridBG.scale.set(GRID_SIZE, GRID_SIZE);
			nextGridBG.updateHitbox();
			nextGridBG.x = gridBG.x;
			nextGridBG.alpha = 0; // ★ 透明：下小节区域只保留黑色遮罩，避免旧棋盘残影（"滚木"）
			leHeight = Std.int(gridBG.height + nextGridBG.height);
			foundNextSec = true;
		}
		else
			nextGridBG = new FlxSprite().makeGraphic(1, 1, FlxColor.TRANSPARENT);
		nextGridBG.y = gridBG.height;

		gridLayer.add(nextGridBG);
		gridLayer.add(gridBG);

		if (foundNextSec)
		{
			var gridBlack:FlxSprite = new FlxSprite(gridBG.x, gridBG.height).makeGraphic(1, 1, FlxColor.BLACK);
			gridBlack.setGraphicSize(Std.int(GRID_SIZE * (totalKeys + 1)), Std.int(nextGridBG.height));
			gridBlack.updateHitbox();
			gridBlack.antialiasing = false;
			gridBlack.alpha = 0.4;
			gridLayer.add(gridBlack);
		}

		// ★ 波形图 sprite 跟随网格左缘（像素宽在 updateWaveform 里按 totalKeys 重建）
		waveformSprite.x = gridBG.x;

		// ★ 网格几何（键数/居中）变化后，头像随时重新居中，避免与轨道列错位
		positionSideIcons();

		var gridBlackLine:FlxSprite = new FlxSprite(gridBG.x + gridBG.width - (GRID_SIZE * leftKeys)).makeGraphic(1, 1, FlxColor.BLACK);
		gridBlackLine.setGraphicSize(2, leHeight);
		gridBlackLine.updateHitbox();
		gridBlackLine.antialiasing = false;
		gridLayer.add(gridBlackLine);

		for (i in 1...Std.int(getSectionBeats()))
		{
			var beatsep:FlxSprite = new FlxSprite(gridBG.x, (GRID_SIZE * (4 * zoomList[curZoom])) * i).makeGraphic(1, 1, 0x44FF0000);
			beatsep.scale.x = gridBG.width;
			beatsep.updateHitbox();
			if (vortex)
				gridLayer.add(beatsep);
		}

		var gridBlackLine:FlxSprite = new FlxSprite(gridBG.x + GRID_SIZE).makeGraphic(1, 1, FlxColor.BLACK);
		gridBlackLine.setGraphicSize(2, leHeight);
		gridBlackLine.updateHitbox();
		gridBlackLine.antialiasing = false;
		gridLayer.add(gridBlackLine);
		updateGrid();

		lastSecBeats = getSectionBeats();
		if (sectionStartTime(1) > FlxG.sound.music.length)
			lastSecBeatsNext = 0;
		else
			lastSecBeatsNext = getSectionBeats(curSec + 1); // ★ 原代码漏了赋值，导致长度比较永远误判
	}

	function strumLineUpdateY()
	{
		// ★ 防御：小节拍数异常（0 等）时避免除零
		var beatsDiv:Float = getSectionBeats() / 4;
		if (beatsDiv <= 0) beatsDiv = 1;
		strumLine.y = getYfromStrum((Conductor.songPosition - sectionStartTime()) / zoomList[curZoom] % (Conductor.stepCrochet * 16)) / beatsDiv;
	}

	var waveformPrinted:Bool = true;
	var wavData:Array<Array<Array<Float>>> = [[[0], [0]], [[0], [0]]];

	var lastWaveformHeight:Int = 0;
	var lastWaveformWidth:Int = 0;

	function updateWaveform()
	{
		#if (desktop || mobile)
		// ★ 宽度跟随 mania（总宽 = 节拍列 + totalKeys 轨），位置跟随网格左缘
		var width:Int = GRID_SIZE * (totalKeys + 1);
		var height:Int = Std.int(gridBG.height);
		if (waveformPrinted)
		{
			if ((lastWaveformHeight != height || lastWaveformWidth != width) && waveformSprite.pixels != null)
			{
				waveformSprite.pixels.dispose();
				waveformSprite.pixels.disposeImage();
				waveformSprite.makeGraphic(width, height, 0x00FFFFFF);
				lastWaveformHeight = height;
				lastWaveformWidth = width;
			}
			waveformSprite.pixels.fillRect(new Rectangle(0, 0, width, height), 0x00FFFFFF);
		}
		waveformPrinted = false;

		var instOn:Bool = (FlxG.save.data.chart_waveformInst == true);
		var bfOn:Bool = (FlxG.save.data.chart_waveformVoices == true);
		var oppOn:Bool = (FlxG.save.data.chart_waveformOppVoices == true);
		if (!instOn && !bfOn && !oppOn)
		{
			// trace('Epic fail on the waveform lol');
			return;
		}

		var steps:Int = Math.round(getSectionBeats() * 4);
		var st:Float = sectionStartTime();
		var et:Float = st + (Conductor.stepCrochet * steps);

		var size:Float = 1;
		var hFull:Int = Std.int(gridBG.height);

		// ★ 分区：第一列是节拍列（GRID_SIZE），之后 leftKeys 轨为 BF 侧、rightKeys 轨为 Opp 侧；
		//   跟随 mustHitSection：玩家小节时 BF 波形在左，对手小节时互换（音符归属也互换）
		var lane0:Int = GRID_SIZE;
		var bfLeft:Bool = (_song.notes[curSec].mustHitSection != false);
		var bfX:Int = bfLeft ? lane0 : lane0 + GRID_SIZE * leftKeys;
		var oppX:Int = bfLeft ? lane0 + GRID_SIZE * leftKeys : lane0;
		var bfW:Int = GRID_SIZE * leftKeys;
		var oppW:Int = GRID_SIZE * rightKeys;

		// ★ 颜色 = 对应角色的 healthBarColor（角色原色，纯数据驱动与头像无关）：
		//   BF 波形 = player1 的色；Opp 波形 = player2 的色；Inst 用绿色（避免与网格混淆）
		//   ★ 三个波形统一 50% 透明度（alpha 0x80），避免盖住音符看不清
		var bfColor:Int = (resolveCharColor(_song.player1, 0xFF666666) & 0x00FFFFFF) | 0x80000000;
		var oppColor:Int = (resolveCharColor(_song.player2, 0xFF666666) & 0x00FFFFFF) | 0x80000000;
		var instColor:Int = 0x806FCF6F;

		if (bfOn && vocals != null && vocals._sound != null && vocals._sound.__buffer != null)
		{
			var bytes:Bytes = vocals._sound.__buffer.data.toBytes();
			var wav:Array<Array<Array<Float>>> = waveformData(vocals._sound.__buffer, bytes, st, et, 1, null, hFull);
			drawWaveformBand(wav, bfX, bfX + bfW, bfColor, size);
		}
		if (oppOn && opponentVocals != null && opponentVocals._sound != null && opponentVocals._sound.__buffer != null)
		{
			var bytes:Bytes = opponentVocals._sound.__buffer.data.toBytes();
			var wav:Array<Array<Array<Float>>> = waveformData(opponentVocals._sound.__buffer, bytes, st, et, 1, null, hFull);
			drawWaveformBand(wav, oppX, oppX + oppW, oppColor, size);
		}
		if (instOn && FlxG.sound.music != null && FlxG.sound.music._sound != null && FlxG.sound.music._sound.__buffer != null)
		{
			var bytes:Bytes = FlxG.sound.music._sound.__buffer.data.toBytes();
			var wav:Array<Array<Array<Float>>> = waveformData(FlxG.sound.music._sound.__buffer, bytes, st, et, 1, null, hFull);
			// ★ Inst 波形居中显示（宽度 = 网格一半，居中放置），不占满全宽
			var instW:Int = Std.int(width / 2);
			var instX:Int = Std.int((width - instW) / 2);
			drawWaveformBand(wav, instX, instX + instW, instColor, size);
		}

		waveformPrinted = true;
		#end
	}

	/** 在 waveformSprite 上绘制一段波形带（xStart ~ xEnd，以带中心为轴）。 */
	function drawWaveformBand(wav:Array<Array<Array<Float>>>, xStart:Int, xEnd:Int, color:Int, size:Float):Void
	{
		var bandW:Int = xEnd - xStart;
		if (bandW < 1) return;
		var hSize:Int = Std.int(bandW / 2);

		var leftLength:Int = (wav[0][0].length > wav[0][1].length ? wav[0][0].length : wav[0][1].length);
		var rightLength:Int = (wav[1][0].length > wav[1][1].length ? wav[1][0].length : wav[1][1].length);
		var length:Int = leftLength > rightLength ? leftLength : rightLength;

		for (index in 0...length)
		{
			var lmin:Float = FlxMath.bound(((index < wav[0][0].length && index >= 0) ? wav[0][0][index] : 0) * (bandW / 1.12), -hSize, hSize) / 2;
			var lmax:Float = FlxMath.bound(((index < wav[0][1].length && index >= 0) ? wav[0][1][index] : 0) * (bandW / 1.12), -hSize, hSize) / 2;

			var rmin:Float = FlxMath.bound(((index < wav[1][0].length && index >= 0) ? wav[1][0][index] : 0) * (bandW / 1.12), -hSize, hSize) / 2;
			var rmax:Float = FlxMath.bound(((index < wav[1][1].length && index >= 0) ? wav[1][1][index] : 0) * (bandW / 1.12), -hSize, hSize) / 2;

			waveformSprite.pixels.fillRect(new Rectangle(xStart + hSize - (lmin + rmin), index * size, (lmin + rmin) + (lmax + rmax), size), color);
		}
	}

	function waveformData(buffer:AudioBuffer, bytes:Bytes, time:Float, endTime:Float, multiply:Float = 1, ?array:Array<Array<Array<Float>>>,
			?steps:Float):Array<Array<Array<Float>>>
	{
		#if (lime_cffi && !macro)
		if (buffer == null || buffer.data == null)
			return [[[0], [0]], [[0], [0]]];

		var khz:Float = (buffer.sampleRate / 1000);
		var channels:Int = buffer.channels;

		var index:Int = Std.int(time * khz);

		var samples:Float = ((endTime - time) * khz);

		if (steps == null)
			steps = 1280;

		var samplesPerRow:Float = samples / steps;
		var samplesPerRowI:Int = Std.int(samplesPerRow);

		var gotIndex:Int = 0;

		var lmin:Float = 0;
		var lmax:Float = 0;

		var rmin:Float = 0;
		var rmax:Float = 0;

		var rows:Float = 0;

		var simpleSample:Bool = true; // samples > 17200;
		var v1:Bool = false;

		if (array == null)
			array = [[[0], [0]], [[0], [0]]];

		while (index < (bytes.length - 1))
		{
			if (index >= 0)
			{
				var byte:Int = bytes.getUInt16(index * channels * 2);

				if (byte > 65535 / 2)
					byte -= 65535;

				var sample:Float = (byte / 65535);

				if (sample > 0)
					if (sample > lmax)
						lmax = sample;
					else if (sample < 0)
						if (sample < lmin)
							lmin = sample;

				if (channels >= 2)
				{
					byte = bytes.getUInt16((index * channels * 2) + 2);

					if (byte > 65535 / 2)
						byte -= 65535;

					sample = (byte / 65535);

					if (sample > 0)
					{
						if (sample > rmax)
							rmax = sample;
					}
					else if (sample < 0)
					{
						if (sample < rmin)
							rmin = sample;
					}
				}
			}

			v1 = samplesPerRowI > 0 ? (index % samplesPerRowI == 0) : false;
			while (simpleSample ? v1 : rows >= samplesPerRow)
			{
				v1 = false;
				rows -= samplesPerRow;

				gotIndex++;

				var lRMin:Float = Math.abs(lmin) * multiply;
				var lRMax:Float = lmax * multiply;

				var rRMin:Float = Math.abs(rmin) * multiply;
				var rRMax:Float = rmax * multiply;

				if (gotIndex > array[0][0].length)
					array[0][0].push(lRMin);
				else
					array[0][0][gotIndex - 1] = array[0][0][gotIndex - 1] + lRMin;

				if (gotIndex > array[0][1].length)
					array[0][1].push(lRMax);
				else
					array[0][1][gotIndex - 1] = array[0][1][gotIndex - 1] + lRMax;

				if (channels >= 2)
				{
					if (gotIndex > array[1][0].length)
						array[1][0].push(rRMin);
					else
						array[1][0][gotIndex - 1] = array[1][0][gotIndex - 1] + rRMin;

					if (gotIndex > array[1][1].length)
						array[1][1].push(rRMax);
					else
						array[1][1][gotIndex - 1] = array[1][1][gotIndex - 1] + rRMax;
				}
				else
				{
					if (gotIndex > array[1][0].length)
						array[1][0].push(lRMin);
					else
						array[1][0][gotIndex - 1] = array[1][0][gotIndex - 1] + lRMin;

					if (gotIndex > array[1][1].length)
						array[1][1].push(lRMax);
					else
						array[1][1][gotIndex - 1] = array[1][1][gotIndex - 1] + lRMax;
				}

				lmin = 0;
				lmax = 0;

				rmin = 0;
				rmax = 0;
			}

			index++;
			rows++;
			if (gotIndex > steps)
				break;
		}

		return array;
		#else
		return [[[0], [0]], [[0], [0]]];
		#end
	}

	function changeNoteSustain(value:Float):Void
	{
		if (curSelectedNote != null)
		{
			if (curSelectedNote[2] != null)
			{
				curSelectedNote[2] += Math.ceil(value);
				curSelectedNote[2] = Math.max(curSelectedNote[2], 0);
			}
		}

		updateNoteUI();
		updateGrid();
	}

	function recalculateSteps(add:Float = 0):Int
	{
		var lastChange:BPMChangeEvent = {
			stepTime: 0,
			songTime: 0,
			bpm: 0
		}
		for (i in 0...Conductor.bpmChangeMap.length)
		{
			if (FlxG.sound.music.time > Conductor.bpmChangeMap[i].songTime)
				lastChange = Conductor.bpmChangeMap[i];
		}

		curStep = lastChange.stepTime + Math.floor((FlxG.sound.music.time - lastChange.songTime + add) / Conductor.stepCrochet);
		updateBeat();

		return curStep;
	}

	function resetSection(songBeginning:Bool = false):Void
	{
		updateGrid();

		FlxG.sound.music.pause();
		// Basically old shit from changeSection???
		FlxG.sound.music.time = sectionStartTime();

		if (songBeginning)
		{
			FlxG.sound.music.time = 0;
			curSec = 0;
		}

		pauseAndSetVocalsTime();
		updateCurStep();

		updateGrid();
		updateSectionUI();
		updateWaveform();
	}

	function changeSection(sec:Int = 0, ?updateMusic:Bool = true):Void
	{
		var waveformChanged:Bool = false;
		if (_song.notes[sec] != null)
		{
			// ★ 记录进入前后是否换了边（BF↔对手）：小节等长时也必须整层重画，
			//   否则背景分色/波形归属沿用上个小节（旧逻辑只在小节长度变化时才 reload）
			var sideChanged:Bool = (sec != curSec && _song.notes[curSec] != null
				&& _song.notes[sec].mustHitSection != _song.notes[curSec].mustHitSection);
			curSec = sec;
			if (updateMusic)
			{
				FlxG.sound.music.pause();

				FlxG.sound.music.time = sectionStartTime();
				pauseAndSetVocalsTime();
				updateCurStep();
			}

			var blah1:Float = getSectionBeats();
			var blah2:Float = getSectionBeats(curSec + 1);
			if (sectionStartTime(1) > FlxG.sound.music.length)
				blah2 = 0;

			if (blah1 != lastSecBeats || blah2 != lastSecBeatsNext || sideChanged)
			{
				reloadGridLayer();
				waveformChanged = true;
			}
			else
			{
				updateGrid();
			}
			updateSectionUI();
		}
		else
		{
			changeSection();
		}
		Conductor.songPosition = FlxG.sound.music.time;
		if (!waveformChanged)
			updateWaveform();
	}

	function updateSectionUI():Void
	{
		var sec = _song.notes[curSec];

		stepperBeats.value = getSectionBeats();
		check_mustHitSection.checked = sec.mustHitSection;
		check_gfSection.checked = sec.gfSection;
		check_altAnim.checked = sec.altAnim;
		check_changeBPM.checked = sec.changeBPM;
		stepperSectionBPM.value = sec.bpm;

		updateHeads();
	}

	var characterData:Dynamic = {
		iconP1: null,
		iconP2: null,
		vocalsP1: null,
		vocalsP2: null,
		healthP1: null,
		healthP2: null
	};

	/** 角色颜色缓存：icon 名 → 主色（-1 = 未算出）。仅用于兜底，与屏幕头像状态无关 */
	var charColorCache:Map<String, Int> = new Map<String, Int>();

	function updateJsonData():Void
	{
		for (i in 1...3)
		{
			var data:CharacterFile = loadCharacterFile(Reflect.field(_song, 'player$i'));
			Reflect.setField(characterData, 'iconP$i', !characterFailed ? data.healthicon : 'face');
			Reflect.setField(characterData, 'vocalsP$i', data.vocals_file != null ? data.vocals_file : '');
			// ★ 缓存角色 JSON 的 healthbar_colors（Psych 标准），供背景/波形取色
			var hb:Array<Int> = null;
			if (!characterFailed && data.healthbar_colors != null && data.healthbar_colors.length > 2)
				hb = data.healthbar_colors;
			Reflect.setField(characterData, 'healthP$i', hb);
		}
	}

	function updateHeads():Void
	{
		if (_song.notes[curSec].mustHitSection)
		{
			leftIcon.changeIcon(characterData.iconP1);
			rightIcon.changeIcon(characterData.iconP2);
			if (_song.notes[curSec].gfSection)
				leftIcon.changeIcon('gf');
		}
		else
		{
			leftIcon.changeIcon(characterData.iconP2);
			rightIcon.changeIcon(characterData.iconP1);
			if (_song.notes[curSec].gfSection)
				leftIcon.changeIcon('gf');
		}
		positionSideIcons(); // ★ 换图后图标宽度可能变化，重新居中到各自轨道组
	}

	var characterFailed:Bool = false;

	function loadCharacterFile(char:String):CharacterFile
	{
		characterFailed = false;
		var characterPath:String = 'characters/' + char + '.json';
		#if MODS_ALLOWED
		var path:String = Paths.modFolders(characterPath);
		if (!FileSystem.exists(path))
		{
			path = Paths.getSharedPath(characterPath);
		}

		if (!FileSystem.exists(path))
		#else
		var path:String = Paths.getSharedPath(characterPath);
		if (!Assets.exists(path))
		#end
		{
			path = Paths.getSharedPath('characters/' + Character.DEFAULT_CHARACTER +
				'.json'); // If a character couldn't be found, change him to BF just to prevent a crash
			characterFailed = true;
		}

		#if MODS_ALLOWED
		var rawJson = File.getContent(path);
		#else
		var rawJson = Assets.getText(path);
		#end
		return cast Json.parse(rawJson);
	}

	function updateNoteUI():Void
	{
		if (curSelectedNote != null)
		{
			if (curSelectedNote[2] != null)
			{
				stepperSusLength.value = curSelectedNote[2];
				if (curSelectedNote[3] != null)
				{
					currentType = curNoteTypes.indexOf(curSelectedNote[3]);
					if (currentType <= 0)
					{
						noteTypeDropDown.selectedLabel = '';
					}
					else
					{
						noteTypeDropDown.selectedLabel = currentType + '. ' + curSelectedNote[3];
					}
				}
			}
			else if (Std.is(curSelectedNote[1], Array))
			{
				// ★ 崩溃防御：只有事件 note（[1] 为数组）才走事件读取，普通 note 的 [1] 是数字轨道号
				var evArr4:Array<Dynamic> = cast curSelectedNote[1];
				if (curEventSelected >= 0 && curEventSelected < evArr4.length && Std.is(evArr4[curEventSelected], Array))
				{
					var evD4:Array<Dynamic> = cast evArr4[curEventSelected];
					if (evD4.length > 0) eventDropDown.selectedLabel = evD4[0];
					var selected:Null<Int> = null;
					try { selected = Std.parseInt(eventDropDown.selectedId); } catch(e:Dynamic) { selected = null; }
					if (selected != null && selected >= 0 && selected < eventStuff.length)
					{
						descText.text = eventStuff[selected][1];
					}
					if (evD4.length > 1) value1InputText.text = evD4[1];
					if (evD4.length > 2) value2InputText.text = evD4[2];
				}
			}
			strumTimeInputText.text = '' + curSelectedNote[0];
		}
	}

	function updateGrid(?withNext:Bool = true):Void
	{
		curRenderedNotes.forEachAlive(function(spr:Note) spr.destroy());
		curRenderedNotes.clear();
		curRenderedSustains.forEachAlive(function(spr:FlxSprite) spr.destroy());
		curRenderedSustains.clear();
		curRenderedNoteType.forEachAlive(function(spr:FlxText) spr.destroy());
		curRenderedNoteType.clear();
		if (withNext)
		{
			nextRenderedNotes.forEachAlive(function(spr:Note) spr.destroy());
			nextRenderedNotes.clear();
			nextRenderedSustains.forEachAlive(function(spr:FlxSprite) spr.destroy());
			nextRenderedSustains.clear();
		}

		if (_song.notes[curSec].changeBPM && _song.notes[curSec].bpm > 0)
		{
			Conductor.bpm = _song.notes[curSec].bpm;
			// trace('BPM of this section:');
		}
		else
		{
			// get last bpm
			var daBPM:Float = _song.bpm;
			for (i in 0...curSec)
				if (_song.notes[i].changeBPM)
					daBPM = _song.notes[i].bpm;
			Conductor.bpm = daBPM;
		}

		// CURRENT SECTION
		var beats:Float = getSectionBeats();
		for (i in _song.notes[curSec].sectionNotes)
		{
			var note:Note = setupNoteData(i, false);
			curRenderedNotes.add(note);
			if (note.sustainLength > 0)
			{
				curRenderedSustains.add(setupSusNote(note, beats));
			}

			if (i[3] != null && note.noteType != null && note.noteType.length > 0)
			{
				var typeInt:Int = curNoteTypes.indexOf(i[3]);
				var theType:String = '' + typeInt;
				if (typeInt < 0)
					theType = '?';

				var daText:AttachedFlxText = new AttachedFlxText(0, 0, 100, theType, 24);
				daText.setFormat(Paths.font(Language.get('fontName', 'main') + '.ttf'), 24, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE_FAST, FlxColor.BLACK);
				daText.xAdd = -32;
				daText.yAdd = 6;
				daText.borderSize = 1;
				curRenderedNoteType.add(daText);
				daText.sprTracker = note;
			}
			note.mustPress = _song.notes[curSec].mustHitSection;
			if (i[1] >= leftKeys)
				note.mustPress = !note.mustPress;
		}

		// CURRENT EVENTS
		var startThing:Float = sectionStartTime();
		var endThing:Float = sectionStartTime(1);
		for (i in _song.events)
		{
			if (endThing > i[0] && i[0] >= startThing)
			{
				var note:Note = setupNoteData(i, false);
				curRenderedNotes.add(note);

				var text:String = 'Event: ' + note.eventName + ' (' + Math.floor(note.strumTime) + ' ms)' + '\nValue 1: ' + note.eventVal1 + '\nValue 2: '
					+ note.eventVal2;
				if (note.eventLength > 1)
					text = note.eventLength + ' Events:\n' + note.eventName;

				var daText:AttachedFlxText = new AttachedFlxText(0, 0, 400, text, 12);
				daText.setFormat(Paths.font(Language.get('fontName', 'main') + '.ttf'), 12, FlxColor.WHITE, RIGHT, FlxTextBorderStyle.OUTLINE_FAST, FlxColor.BLACK);
				daText.xAdd = -410;
				daText.borderSize = 1;
				if (note.eventLength > 1)
					daText.yAdd += 8;
				curRenderedNoteType.add(daText);
				daText.sprTracker = note;
				// trace('test: ' + i[0], 'startThing: ' + startThing, 'endThing: ' + endThing);
			}
		}

		// NEXT SECTION（withNext=false 时跳过：只改了当前小节时下一小节预览没变，避免重复重建）
		var beats:Float = getSectionBeats(1);
		if (withNext && curSec < _song.notes.length - 1)
		{
			for (i in _song.notes[curSec + 1].sectionNotes)
			{
				var note:Note = setupNoteData(i, true);
				note.alpha = 0.6;
				nextRenderedNotes.add(note);
				if (note.sustainLength > 0)
				{
					nextRenderedSustains.add(setupSusNote(note, beats));
				}
			}
		}

		// NEXT EVENTS
		var startThing:Float = sectionStartTime(1);
		var endThing:Float = sectionStartTime(2);
		if (withNext)
		{
			for (i in _song.events)
			{
				if (endThing > i[0] && i[0] >= startThing)
				{
					var note:Note = setupNoteData(i, true);
					note.alpha = 0.6;
					nextRenderedNotes.add(note);
				}
			}
		}
	}

	function setupNoteData(i:Array<Dynamic>, isNextSection:Bool):Note
	{
		var daNoteInfo = i[1];
		var daStrumTime = i[0];
		var daSus:Dynamic = i[2];

		// ★ 事件音符的 i[1] 是数组（[事件名, 值1, 值2 …]），旧代码直接 `daNoteInfo % leftKeys`
		//   对 Dynamic 取模，得到的轨号是垃圾值；它决定了构造期取哪条轨道的配色/缩放，
		//   随后虽然会被改回 -1，但构造期已经用错误轨号建过 RGB palette 与动画了。
		//   这里先归一成安全轨号（非数字一律 0）。
		var laneForNote:Int = 0;
		if (Std.isOfType(daNoteInfo, Int) || Std.isOfType(daNoteInfo, Float))
		{
			var laneNum:Int = Std.int(cast daNoteInfo);
			laneForNote = (leftKeys > 0) ? (laneNum % leftKeys) : 0;
			if (laneForNote < 0) laneForNote += leftKeys;
		}

		var note:Note = new Note(daStrumTime, laneForNote, null, null, true);
		if (daSus != null)
		{ // Common note
			if (!Std.isOfType(i[3], String)) // Convert old note type to new note type format
			{
				// ★ 防御：i[3] 可能是 null（旧谱面无类型字段）→ 不能直接索引 curNoteTypes
				var oldTypeIdx:Int = Std.is(i[3], Int) || Std.is(i[3], Float) ? Std.int(i[3]) : 0;
				if (oldTypeIdx >= 0 && oldTypeIdx < curNoteTypes.length)
					i[3] = curNoteTypes[oldTypeIdx];
				else
					i[3] = null;
			}
			if (i.length > 3 && (i[3] == null || i[3].length < 1))
			{
				i.remove(i[3]);
			}
			note.sustainLength = daSus;
			note.noteType = i[3];
		}
		else if (Std.is(i[1], Array))
		{ // Event note（★ 判定必须用 [1] 是否为数组：普通音符的 [1] 是轨道号 Int，
			//   [2]==null 不可靠——旧谱面普通音符 susLength 缺失时会把 Int 当数组 → 空指针崩溃）
			var evArr:Array<Dynamic> = cast i[1];
			if (evArr == null) evArr = [];
			note.loadGraphic(Paths.image('eventArrow'));
			note.rgbShader.enabled = false;
			note.eventName = getEventName(evArr);
			note.eventLength = evArr.length;
			if (evArr.length < 2 && evArr.length > 0 && Std.is(evArr[0], Array))
			{
				var ev0:Array<Dynamic> = cast evArr[0];
				if (ev0.length > 1) note.eventVal1 = ev0[1];
				if (ev0.length > 2) note.eventVal2 = ev0[2];
			}
			note.noteData = -1;
			daNoteInfo = -1;
		}
		else
		{ // 普通音符但 susLength 缺失（旧谱面）——按普通音符兜底，避免误入事件分支
			note.sustainLength = 0;
			note.noteData = daNoteInfo;
		}

		note.setGraphicSize(GRID_SIZE, GRID_SIZE);
		note.updateHitbox();
		note.x = getGridX() + Math.floor(daNoteInfo * GRID_SIZE) + GRID_SIZE;
		// ★ 下一小节换边预览：把下一小节音符整体镜像到另一侧（按当前每侧键数平移，
		//   不再写死 4K——mania 变化后写死平移会与轨道列错位；事件行 daNoteInfo=-1 不换）
		if (isNextSection && daNoteInfo >= 0 && _song.notes[curSec].mustHitSection != _song.notes[curSec + 1].mustHitSection)
		{
			note.x += (daNoteInfo >= leftKeys ? -1 : 1) * GRID_SIZE * leftKeys;
		}

		var beats:Float = getSectionBeats(isNextSection ? 1 : 0);
		note.y = getYfromStrumNotes(daStrumTime - sectionStartTime(), beats);
		// if(isNextSection) note.y += gridBG.height;
		if (note.y < -150)
			note.y = -150;
		return note;
	}

	function getEventName(names:Array<Dynamic>):String
	{
		var retStr:String = '';
		var addedOne:Bool = false;
		for (i in 0...names.length)
		{
			if (addedOne)
				retStr += ', ';
			retStr += names[i][0];
			addedOne = true;
		}
		return retStr;
	}

	function setupSusNote(note:Note, beats:Float):FlxSprite
	{
		var height:Int = Math.floor(FlxMath.remapToRange(note.sustainLength, 0, Conductor.stepCrochet * 16, 0, GRID_SIZE * 16 * zoomList[curZoom])
			+ (GRID_SIZE * zoomList[curZoom])
			- GRID_SIZE / 2);
		var minHeight:Int = Std.int((GRID_SIZE * zoomList[curZoom] / 2) + GRID_SIZE / 2);
		if (height < minHeight)
			height = minHeight;
		if (height < 1)
			height = 1; // Prevents error of invalid height

		var spr:FlxSprite = new FlxSprite(note.x + (GRID_SIZE * 0.5) - 4, note.y + GRID_SIZE / 2).makeGraphic(8, height);
		return spr;
	}

	private function addSection(sectionBeats:Float = 4):Void
	{
		var sec:SwagSection = {
			sectionBeats: sectionBeats,
			bpm: _song.bpm,
			changeBPM: false,
			mustHitSection: true,
			gfSection: false,
			sectionNotes: [],
			altAnim: false
		};

		_song.notes.push(sec);
	}

	function selectNote(note:Note):Void
	{
		var noteDataToCheck:Int = note.noteData;

		if (noteDataToCheck > -1)
		{
			if (note.mustPress != _song.notes[curSec].mustHitSection)
				noteDataToCheck += leftKeys;
			for (i in _song.notes[curSec].sectionNotes)
			{
				if (i != curSelectedNote && i.length > 2 && i[0] == note.strumTime && i[1] == noteDataToCheck)
				{
					curSelectedNote = i;
					break;
				}
			}
		}
		else
		{
			for (i in _song.events)
			{
				if (i != curSelectedNote && i[0] == note.strumTime)
				{
					curSelectedNote = i;
					// ★ 防御：事件音符 [1] 应为数组（谱面数据损坏时避免对 Int 取 length）
					if (Std.is(curSelectedNote[1], Array))
						curEventSelected = Std.int((cast curSelectedNote[1]:Array<Dynamic>).length) - 1;
					else
						curEventSelected = 0;
					break;
				}
			}
		}
		changeEventSelected();

		updateGrid();
		updateNoteUI();
	}

	function deleteNote(note:Note):Void
	{
		var noteDataToCheck:Int = note.noteData;
		if (noteDataToCheck > -1 && note.mustPress != _song.notes[curSec].mustHitSection)
			noteDataToCheck += leftKeys;

		if (note.noteData > -1) // Normal Notes
		{
			for (i in _song.notes[curSec].sectionNotes)
			{
				if (i[0] == note.strumTime && i[1] == noteDataToCheck)
				{
					if (i == curSelectedNote)
						curSelectedNote = null;
					// FlxG.log.add('FOUND EVIL NOTE');
					_song.notes[curSec].sectionNotes.remove(i);
					break;
				}
			}
		}
		else // Events
		{
			for (i in _song.events)
			{
				if (i[0] == note.strumTime)
				{
					if (i == curSelectedNote)
					{
						curSelectedNote = null;
						changeEventSelected();
					}
					// FlxG.log.add('FOUND EVIL EVENT');
					_song.events.remove(i);
					break;
				}
			}
		}

		updateGrid();
	}

	public function doANoteThing(cs, d, style)
	{
		var delnote = false;
		if (strumLineNotes.members[d].overlaps(curRenderedNotes))
		{
			curRenderedNotes.forEachAlive(function(note:Note)
			{
				if (note.overlapsPoint(FlxPoint.weak(strumLineNotes.members[d].x + 1, strumLine.y + 1)) && note.noteData == d % 4)
				{
					// trace('tryin to delete note...');
					if (!delnote)
						deleteNote(note);
					delnote = true;
				}
			});
		}

		if (!delnote)
		{
			addNote(cs, d, style);
		}
	}

	function clearSong():Void
	{
		for (daSection in 0..._song.notes.length)
		{
			_song.notes[daSection].sectionNotes = [];
		}

		updateGrid();
	}

	private function addNote(strum:Null<Float> = null, data:Null<Int> = null, type:Null<Int> = null):Void
	{
		// curUndoIndex++;
		// var newsong = _song.notes;
		//	undos.push(newsong);
		var noteStrum = getStrumTime(dummyArrow.y * (getSectionBeats() / 4), false) + sectionStartTime();
		var noteData = 0;
		// if (ClientPrefs.data.needMobileControl) {
		// for (touch in FlxG.touches.list){noteData = Math.floor((touch.x - GRID_SIZE) / GRID_SIZE);}
		// } else {
		noteData = Math.floor((FlxG.mouse.getWorldPosition(FlxG.camera).x - getGridX() - GRID_SIZE) / GRID_SIZE);
		// }
		var noteSus = 0;
		var daAlt = false;
		var daType = currentType;

		if (strum != null)
			noteStrum = strum;
		if (data != null)
			noteData = data;
		if (type != null)
			daType = type;

		if (noteData > -1)
		{
			_song.notes[curSec].sectionNotes.push([noteStrum, noteData, noteSus, curNoteTypes[daType]]);
			curSelectedNote = _song.notes[curSec].sectionNotes[_song.notes[curSec].sectionNotes.length - 1];
		}
		else
		{
			// ★ 防御：eventDropDown.selectedId 可能是空/非数字 → Std.parseInt 返回 null →
			//   eventStuff[null] 取 [0] 会空指针崩溃，先解析并校验索引
			var eventId:Null<Int> = null;
			try { eventId = Std.parseInt(eventDropDown.selectedId); } catch(e:Dynamic) { eventId = null; }
			var evName:String = '';
			if (eventId != null && eventId >= 0 && eventId < eventStuff.length)
				evName = eventStuff[eventId][0];
			var text1 = value1InputText.text;
			var text2 = value2InputText.text;
			_song.events.push([noteStrum, [[evName, text1, text2]]]);
			curSelectedNote = _song.events[_song.events.length - 1];
			curEventSelected = 0;
		}
		changeEventSelected();

		// ★ 自定义移动键位模式下不自动双放（Ctrl 来自虚拟组合键，同帧可能误触发对侧复制）
		if (FlxG.keys.pressed.CONTROL && noteData > -1 && !EditorMobileKeys.isEnabled())
		{
			_song.notes[curSec].sectionNotes.push([noteStrum, (noteData + leftKeys) % totalKeys, noteSus, curNoteTypes[daType]]);
		}

		// trace(noteData + ', ' + noteStrum + ', ' + curSec);
		strumTimeInputText.text = '' + curSelectedNote[0];

		updateGrid();
		updateNoteUI();
	}

	// 撤销系统：每次破坏性操作前 pushUndo() 存整份谱面快照，undo() 弹回上一步
	// ★ 快照用 haxe.Serializer（二进制式）而非 Json.stringify——大谱面（如 triple-trouble
	//   这类每小节几百音符）Json 序列化会卡顿数百 ms；Serializer 快一个量级且撤销栈只在内存里。
	function pushUndo():Void
	{
		if (undos == null) undos = [];
		undos.push(haxe.Serializer.run(_song.notes));
		if (undos.length > 50) undos.shift(); // 只保留最近 50 步
	}

	function redo()
	{
		// 暂时不做 redo（用户没要求）
	}

	function undo()
	{
		if (undos == null || undos.length <= 0)
		{
			return;
		}
		withMusicPaused(function()
		{
			var snapshot:String = undos.pop();
			var parsed:Dynamic = null;
			try { parsed = haxe.Unserializer.run(snapshot); } catch (e:Dynamic) {}
			if (parsed != null)
			{
				_song.notes = cast parsed;
				if (curSec >= _song.notes.length) curSec = _song.notes.length - 1;
				if (curSec < 0) curSec = 0;
				updateGrid();
				updateSectionUI();
			}
		});
	}

	function getStrumTime(yPos:Float, doZoomCalc:Bool = true):Float
	{
		var leZoom:Float = zoomList[curZoom];
		if (!doZoomCalc)
			leZoom = 1;
		return FlxMath.remapToRange(yPos, gridBG.y, gridBG.y + gridBG.height * leZoom, 0, 16 * Conductor.stepCrochet);
	}

	function getYfromStrum(strumTime:Float, doZoomCalc:Bool = true):Float
	{
		var leZoom:Float = zoomList[curZoom];
		if (!doZoomCalc)
			leZoom = 1;
		return FlxMath.remapToRange(strumTime, 0, 16 * Conductor.stepCrochet, gridBG.y, gridBG.y + gridBG.height * leZoom);
	}

	function getYfromStrumNotes(strumTime:Float, beats:Float):Float
	{
		// ★ 防御：beats/stepCrochet 异常时避免除零产生 NaN 坐标
		var denom:Float = beats * 4 * Conductor.stepCrochet;
		if (denom <= 0) denom = 1;
		var value:Float = strumTime / denom;
		return GRID_SIZE * beats * 4 * zoomList[curZoom] * value + gridBG.y;
	}

	function getNotes():Array<Dynamic>
	{
		var noteData:Array<Dynamic> = [];

		for (i in _song.notes)
		{
			noteData.push(i.sectionNotes);
		}

		return noteData;
	}

	var missingText:FlxText;
	var missingTextTimer:FlxTimer;

	function loadJson(song:String):Void
	{
		// ★ 难度后缀取自【歌曲】→「难度」输入框：填了 Fuck 就加载 song-Fuck.json（制作多难度用）；
		//   留空则加载无后缀文件（不再受全局 Difficulty 影响——之前会莫名拼难度后缀导致"重载无效"）
		try
		{
			var diff:String = (difficultyInputText != null && difficultyInputText.text != null) ? StringTools.trim(difficultyInputText.text) : '';
			if (diff.length > 0)
				PlayState.SONG = Song.loadFromJson(song.toLowerCase() + '-' + Paths.formatToSongPath(diff), song.toLowerCase());
			else
				PlayState.SONG = Song.loadFromJson(song.toLowerCase(), song.toLowerCase());
			MusicBeatState.resetState();
		}
		catch (e)
		{
			trace('ERROR! $e');

			var errorStr:String = e.toString();
			if (errorStr.startsWith('[file_contents,assets/data/'))
				errorStr = 'Missing file: ' + errorStr.substring(27, errorStr.length - 1); // Missing chart

			if (missingText == null)
			{
				missingText = new FlxText(50, 0, FlxG.width - 100, '', 24);
				missingText.setFormat(Paths.font(Language.get('fontName', 'main') + '.ttf'), 24, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
				missingText.scrollFactor.set();
				add(missingText);
			}
			else
				missingTextTimer.cancel();

			missingText.text = 'ERROR WHILE LOADING CHART:\n$errorStr';
			missingText.screenCenter(Y);

			missingTextTimer = new FlxTimer().start(5, function(tmr:FlxTimer)
			{
				remove(missingText);
				missingText.destroy();
			});
			FlxG.sound.play(Paths.sound('cancelMenu'));
		}
	}

	function autosaveSong():Void
	{
		FlxG.save.data.autosave = haxe.Json.stringify({
			"song": _song
		});
		FlxG.save.flush();
	}

	/**
	 * 以「测试模式」进入 EditorPlayState。
	 * 对应原版的 ESC，也对应新顶栏菜单 [测试] → 「以测试模式进行」。
	 */

	// ================= 快捷键辅助函数 =================
	/** Ctrl+Shift+Tab：打开/关闭 Vortex */
	function toggleVortexShortcut():Void
	{
		vortex = !vortex;
		FlxG.save.data.chart_vortex = vortex;
		if (check_vortex != null) check_vortex.checked = vortex;
		reloadGridLayer();
	}

	/** Ctrl+Shift+U / Ctrl+Shift+O：BF / Opp 打击音开关 */
	function toggleSfxShortcut(side:String):Void
	{
		if (side == 'bf')
		{
			if (playSoundBf == null) return;
			playSoundBf.checked = !playSoundBf.checked;
			if (playSoundBf.callback != null) playSoundBf.callback();
		}
		else
		{
			if (playSoundDad == null) return;
			playSoundDad.checked = !playSoundDad.checked;
			if (playSoundDad.callback != null) playSoundDad.callback();
		}
	}

	/** Alt+Ctrl+U/I/O：静音 BF / Inst / Opp（走各自 callback 同步音量） */
	function toggleMuteShortcut(side:String):Void
	{
		var cb:Dynamic = null;
		switch (side)
		{
			case 'bf': if (check_mute_vocals != null) { check_mute_vocals.checked = !check_mute_vocals.checked; cb = check_mute_vocals.callback; }
			case 'inst': if (check_mute_inst != null) { check_mute_inst.checked = !check_mute_inst.checked; cb = check_mute_inst.callback; }
			case 'opp': if (check_mute_vocals_opponent != null) { check_mute_vocals_opponent.checked = !check_mute_vocals_opponent.checked; cb = check_mute_vocals_opponent.callback; }
		}
		if (cb != null) try { cb(); } catch (e:Dynamic) {}
	}

	/** Alt+U/I/O：BF / Inst / Opp 波形图开关（互斥已取消，可同时开启） */
	function toggleWaveformShortcut(side:String):Void
	{
		switch (side)
		{
			case 'bf':
				if (waveformUseVoices == null) return;
				waveformUseVoices.checked = !waveformUseVoices.checked;
				FlxG.save.data.chart_waveformVoices = waveformUseVoices.checked;
				updateWaveform();
			case 'inst':
				if (waveformUseInstrumental == null) return;
				waveformUseInstrumental.checked = !waveformUseInstrumental.checked;
				FlxG.save.data.chart_waveformInst = waveformUseInstrumental.checked;
				updateWaveform();
			case 'opp':
				if (waveformUseOppVoices == null) return;
				waveformUseOppVoices.checked = !waveformUseOppVoices.checked;
				FlxG.save.data.chart_waveformOppVoices = waveformUseOppVoices.checked;
				updateWaveform();
		}
	}

	/** K+数字（`=1K ~ 9=10K）：设置 Mania 键数（带阈值 clamp，并同步到【歌曲】→【键数】步进器） */
	function setManiaByKey(displayKeys:Int):Void
	{
		var minK:Int = 1;
		var maxK:Int = extraMaxKeys();
		displayKeys = Std.int(FlxMath.bound(displayKeys, minK, maxK));
		_song.mania = displayKeys - 1;
		if (stepperMania != null) stepperMania.value = displayKeys; // ★ 同步回【键数】步进器
		updateKeyAmounts();
		reloadGridLayer();
		makeStrumNotes();
	}
	// ================= 快捷键辅助函数结束 =================

	// 处理菜单 action 项的回调
	function handleMenuAction(actionKey:String):Void
	{
		switch (actionKey)
		{
			case 'save':
				saveLevel();
			case 'reload_audio':
				// ★ 与 reload_json 一致：优先用【歌曲】标题输入框的内容（改了歌名后重载音频才生效），
				//   loadSong 内部会强制绕过声音缓存重新解码磁盘文件
				var wantedAudio:String = (UI_songTitle != null && UI_songTitle.text != null) ? StringTools.trim(UI_songTitle.text) : '';
				if (wantedAudio.length < 1) wantedAudio = _song.song;
				currentSongName = Paths.formatToSongPath(wantedAudio);
				loadSong();
			case 'reload_json':
				// ★ 用【歌曲】标题输入框的内容作为要加载的曲目（可输入新歌名如 "dad battle" 直接换曲），
				//   为空则保持当前曲目。之前写死 currentSongName → 输入什么都是重载当前曲
				var wantedSong:String = (UI_songTitle != null && UI_songTitle.text != null) ? StringTools.trim(UI_songTitle.text) : '';
				if (wantedSong.length < 1) wantedSong = _song.song;
				loadJson(Paths.formatToSongPath(wantedSong));
			case 'engine':
				var nextEngine:String = (Song.chartEngineVersion == 'Pe-1.0.4') ? 'Pe-0.7.3' : 'Pe-1.0.4';
				Song.forceEngineVersion = nextEngine;
				Song.chartEngineVersion = nextEngine;
				var songName:String = Paths.formatToSongPath(_song.song);
				// ★ 加载失败不再静默：trace 提示并保留当前谱面（避免"点了没反应"）
				try
				{
					var reloaded:SwagSong = Song.loadFromJson(songName, songName);
					if (reloaded != null) _song = reloaded;
				}
				catch (e:Dynamic)
				{
					trace('[charting] 引擎切换重载失败（保留当前谱面）：$e');
				}
				autoFixManiaFromData(); // 重载的 json 可能缺 mania 字段 → 按数据恢复
				recalcKeyAmounts();
				reloadGridLayer();
				makeStrumNotes();
				changeSection(curSec);
			case 'load_autosave':
				loadFromAutosave();
			case 'load_events':
				loadEventsFromFile();
			case 'save_events':
				saveEvents();
			case 'clear_events':
				openSubState(new Prompt('This action will clear current progress.\n\nProceed?', 0, clearEvents, null, ignoreWarnings));
			case 'clear_notes':
				openSubState(new Prompt('This action will clear current progress.\n\nProceed?', 0, function()
				{
					for (sec in 0..._song.notes.length)
					{
						_song.notes[sec].sectionNotes = [];
					}
					updateGrid();
				}, null, ignoreWarnings));
			case 'apply_notes':
				applyNoteSkinSelection();
			case 'copy_section':
				copyCurrentSection();
			case 'paste_section':
				openSubState(new Prompt(Language.get('prompt_paste_section', 'charting'), 0, function()
				{
					pasteToCurrentSection();
				}, null, ignoreWarnings));
			case 'clear_section':
				openSubState(new Prompt(Language.get('prompt_clear_section', 'charting'), 0, function()
				{
					clearCurrentSection();
				}, null, ignoreWarnings));
			case 'swap_section':
				openSubState(new Prompt(Language.get('prompt_swap_section', 'charting'), 0, function()
				{
					swapSectionSides();
				}, null, ignoreWarnings));
			case 'do_copy_beat':
				openSubState(new Prompt(Language.get('prompt_copy_beat', 'charting'), 0, function()
				{
					copyBeat();
				}, null, ignoreWarnings));
			case 'copy_last_section':
				copyLastSectionToCurrent();
			case 'duet_notes':
				openSubState(new Prompt(Language.get('prompt_duet_notes', 'charting'), 0, function()
				{
					duetCurrentSection();
				}, null, ignoreWarnings));
			case 'mirror_notes':
				openSubState(new Prompt(Language.get('prompt_mirror_notes', 'charting'), 0, function()
				{
					mirrorCurrentSection();
				}, null, ignoreWarnings));
			case 'undo':
				undo();
			case 'add_event':
				addNewEventToCurrentSection();
			case 'del_event':
				deleteSelectedEvent();
			case 'prev_event':
				selectPrevEvent();
			case 'next_event':
				selectNextEvent();
		}
	}

	/**
	 * 菜单打开后刷新 widget 显示值。
	 * widget 在 visible=false 时被 setter 赋值后，内部 text_field 可能不会立即刷新。
	 * 这里在 widget 已可见的状态下重新触发 setter，确保显示与数据同步。
	 */
	function refreshMenuWidgets(menuKey:String):Void
	{
		switch (menuKey)
		{
			case 'song':
				try { if (UI_songTitle != null) UI_songTitle.text = _song.song; } catch(e:Dynamic) {}
				try { if (songBpmStepper != null) songBpmStepper.value = _song.bpm; } catch(e:Dynamic) {}
				try { if (stepperSpeed != null) stepperSpeed.value = _song.speed; } catch(e:Dynamic) {}
				try { if (check_voices != null) check_voices.checked = _song.needsVoices; } catch(e:Dynamic) {}

			case 'section':
				try { if (stepperSectionBPM != null && _song.notes.length > curSec) stepperSectionBPM.value = _song.notes[curSec].bpm; } catch(e:Dynamic) {}
				// ★ 先读取：所有小节 checkbox 从谱面数据刷新（openMenu 先调这里再 rebuildDropdown 渲染）
				try { if (check_mustHitSection != null && _song.notes.length > curSec) check_mustHitSection.checked = _song.notes[curSec].mustHitSection; } catch(e:Dynamic) {}
				try { if (check_gfSection != null && _song.notes.length > curSec) check_gfSection.checked = _song.notes[curSec].gfSection; } catch(e:Dynamic) {}
				try { if (check_altAnim != null && _song.notes.length > curSec) check_altAnim.checked = _song.notes[curSec].altAnim; } catch(e:Dynamic) {}
				try { if (check_changeBPM != null && _song.notes.length > curSec) check_changeBPM.checked = _song.notes[curSec].changeBPM; } catch(e:Dynamic) {}
				// check_notesSec / check_eventsSec 是用户的复制设置，保持 toggle 状态，不刷新

			case 'note':
				if (curSelectedNote != null)
				{
					try { if (stepperSusLength != null && curSelectedNote.length > 2 && curSelectedNote[2] != null)
					{
						var curVal:Float = stepperSusLength.value;
						var targetVal:Float = curSelectedNote[2];
						if (curVal == targetVal) stepperSusLength.value = targetVal + 0.001;
						stepperSusLength.value = targetVal;
					}} catch(e:Dynamic) {}
					try { if (strumTimeInputText != null) strumTimeInputText.text = '' + curSelectedNote[0]; } catch(e:Dynamic) {}
				}

			case 'event':
				// ★ 崩溃修复：普通 note 的 curSelectedNote[1] 是轨道号数字（非数组），
				//   直接 [1][curEventSelected][1] 索引会对 Int 做动态访问 → 原生空指针 AV（try/catch 拦不住）
				if (curSelectedNote != null && curSelectedNote.length > 1 && Std.is(curSelectedNote[1], Array))
				{
					var evArr3:Array<Dynamic> = cast curSelectedNote[1];
					if (curEventSelected >= 0 && curEventSelected < evArr3.length)
					{
						var ev3:Dynamic = evArr3[curEventSelected];
						if (Std.is(ev3, Array))
						{
							var evD3:Array<Dynamic> = cast ev3;
							try { if (value1InputText != null && evD3.length > 1) value1InputText.text = evD3[1]; } catch(e:Dynamic) {}
							try { if (value2InputText != null && evD3.length > 2) value2InputText.text = evD3[2]; } catch(e:Dynamic) {}
						}
					}
				}

			case 'charting':
				// ★ 先读取：谱面菜单 checkbox 从存档刷新（openMenu 先调这里再 rebuildDropdown 渲染）
				try { if (metronome != null) metronome.checked = (FlxG.save.data.chart_metronome == true); } catch(e:Dynamic) {}
				try { if (disableAutoScrolling != null) disableAutoScrolling.checked = (FlxG.save.data.chart_noAutoScroll == true); } catch(e:Dynamic) {}
				try { if (waveformUseInstrumental != null) waveformUseInstrumental.checked = (FlxG.save.data.chart_waveformInst == true); } catch(e:Dynamic) {}
				try { if (waveformUseVoices != null) waveformUseVoices.checked = (FlxG.save.data.chart_waveformVoices == true); } catch(e:Dynamic) {}
				try { if (waveformUseOppVoices != null) waveformUseOppVoices.checked = (FlxG.save.data.chart_waveformOppVoices == true); } catch(e:Dynamic) {}
				try { if (check_vortex != null) check_vortex.checked = (FlxG.save.data.chart_vortex == true); } catch(e:Dynamic) {}
				try { if (check_warnings != null) check_warnings.checked = (FlxG.save.data.ignoreWarnings == true); } catch(e:Dynamic) {}
				try { if (playSoundBf != null) playSoundBf.checked = (FlxG.save.data.chart_playSoundBf == true); } catch(e:Dynamic) {}
				try { if (playSoundDad != null) playSoundDad.checked = (FlxG.save.data.chart_playSoundDad == true); } catch(e:Dynamic) {}
				// 静音类（mute_inst/main/opp）是运行时状态，由用户 toggle 实时生效，不在此刷新

			case 'data':
				try { if (gameOverCharacterInputText != null) gameOverCharacterInputText.text = _song.gameOverChar != null ? _song.gameOverChar : ''; } catch(e:Dynamic) {}
				try { if (gameOverSoundInputText != null) gameOverSoundInputText.text = _song.gameOverSound != null ? _song.gameOverSound : ''; } catch(e:Dynamic) {}
				try { if (gameOverLoopInputText != null) gameOverLoopInputText.text = _song.gameOverLoop != null ? _song.gameOverLoop : ''; } catch(e:Dynamic) {}
				try { if (gameOverEndInputText != null) gameOverEndInputText.text = _song.gameOverEnd != null ? _song.gameOverEnd : ''; } catch(e:Dynamic) {}
				// ★ 先读取：数据菜单 checkbox 从谱面数据刷新
				try { if (check_disableNoteRGB != null) check_disableNoteRGB.checked = (_song.disableNoteRGB == true); } catch(e:Dynamic) {}
		}
	}

	function loadEventsFromFile():Void
	{
		var songName = currentSongName;
		var file:String = Paths.json(songName + '/events');
		#if sys
		if (#if MODS_ALLOWED FileSystem.exists(Paths.modsJson(songName + '/events')) || #end FileSystem.exists(file))
		#else
		if (Assets.exists(file))
		#end
		{
			clearEvents();
			var savedFmt = Song.detectedFormat;
			var savedCE = Song.chartEngineVersion;
			var events:SwagSong = Song.loadFromJson('events', songName);
			Song.detectedFormat = savedFmt;
			Song.chartEngineVersion = savedCE;
			_song.events = events.events;
			changeSection(curSec);
		}
	}

	function loadFromAutosave():Void
	{
		PlayState.SONG = Song.parseJSON(FlxG.save.data.autosave);
		if (PlayState.SONG == null) return;
		_song = PlayState.SONG; // ★ 同步引用（autosave 是全新对象）
		if (curSec >= _song.notes.length) curSec = _song.notes.length - 1;
		if (curSec < 0) curSec = 0;
		// ★ 全套刷新：角色/mania 可能都变了 → 颜色、头像、轨道数全部按新曲目数据重建
		updateJsonData();
		autoFixManiaFromData(); // autosave 若缺 mania 字段 → 按数据恢复
		recalcKeyAmounts();
		reloadGridLayer();
		makeStrumNotes();
		updateHeads();
		changeSection(curSec);
	}

	function applyNoteSkinSelection():Void
	{
		// 把当前下拉选中的音符类型应用到谱面所有音符（原 apply_notes 是空壳）
		if (_song.notes == null || curNoteTypes == null) return;
		if (currentType < 0 || currentType >= curNoteTypes.length) return;
		var typeStr:String = curNoteTypes[currentType];
		pushUndo();
		for (sec in 0..._song.notes.length)
		{
			for (note in _song.notes[sec].sectionNotes)
			{
				note[3] = typeStr;
			}
		}
		updateGrid();
	}

	function copyCurrentSection():Void
	{
		if (curSec >= 0 && curSec < _song.notes.length)
		{
			// ★ 按「包含音符 / 包含事件」勾选状态过滤后再保存（作用于所有复制/粘贴）
			var secCopy:Dynamic = haxe.Json.parse(haxe.Json.stringify(_song.notes[curSec]));
			filterSectionByChecks(secCopy);
			FlxG.save.data.copiedSection = haxe.Json.stringify(secCopy);
			// ★ 记录复制时刻所在小节的时间起点，粘贴时用它计算偏移，
			//   否则粘到别的小节时 note 时间不挪，全部堆在源小节的位置（谱面外）
			FlxG.save.data.copiedSectionTime = sectionStartTime();
		}
	}

	/** 按「包含音符 / 包含事件」勾选状态过滤小节数据（Psych 格式：事件行 [1] == -1）。
	 *  就地修改传入的小节对象，返回同一对象。 */
	function filterSectionByChecks(sec:Dynamic):Void
	{
		if (sec == null || sec.sectionNotes == null) return;
		var includeNotes:Bool = (check_notesSec != null) ? check_notesSec.checked : true;
		var includeEvents:Bool = (check_eventsSec != null) ? check_eventsSec.checked : true;
		if (includeNotes && includeEvents) return; // 全选，无需过滤

		var filtered:Array<Dynamic> = [];
		for (note in (sec.sectionNotes:Array<Dynamic>))
		{
			if (note == null || !Std.is(note, Array)) continue;
			var arrNote:Array<Dynamic> = cast note;
			var isEventRow:Bool = (arrNote.length > 1 && arrNote[1] == -1);
			if (isEventRow)
			{
				if (includeEvents) filtered.push(note);
			}
			else
			{
				if (includeNotes) filtered.push(note);
			}
		}
		sec.sectionNotes = filtered;
	}

	/** ★ 把 parsed 小节的音符内容【追加】到当前小节（纯粘贴：不清除目标小节原有内容，
	 *  也不改动小节属性 mustHitSection/gfSection）。复制/粘贴 = 叠加内容。 */
	function appendSectionNotes(parsed:Dynamic):Void
	{
		if (parsed == null || _song.notes == null || curSec < 0 || curSec >= _song.notes.length) return;
		if (parsed.sectionNotes == null) return;
		var target:Array<Dynamic> = _song.notes[curSec].sectionNotes;
		if (target == null) target = [];
		for (n in (parsed.sectionNotes:Array<Dynamic>))
		{
			if (n != null && Std.is(n, Array)) target.push(n);
		}
		// 追加后按时间排序，保持渲染/选择稳定
		target.sort(function(a:Array<Dynamic>, b:Array<Dynamic>):Int
		{
			var ta:Float = (a != null && a.length > 0 && a[0] != null) ? Std.parseFloat(Std.string(a[0])) : 0;
			var tb:Float = (b != null && b.length > 0 && b[0] != null) ? Std.parseFloat(Std.string(b[0])) : 0;
			return ta < tb ? -1 : (ta > tb ? 1 : 0);
		});
		_song.notes[curSec].sectionNotes = target;
	}

	/** ★ 重活（粘贴/撤销等全量重建）期间若音乐在播放先暂停，结束后恢复——
	 *   大谱面重建会卡顿数百 ms，若不暂停，卡顿期间音乐时间照常前进，
	 *   恢复后 strumline/视图会瞬间跳变（表现为"网格疯狂滚动"）。
	 *   ★ 同时记录并强制恢复 music.time：防任何路径（如大谱面下耗时操作
	 *   触发的 onComplete 等）把播放位置归零，粘贴到 100+ 小节后视图倒退到 0:00。 */
	function withMusicPaused(fn:Void->Void):Void
	{
		var wasPlaying:Bool = (FlxG.sound.music != null && FlxG.sound.music.playing);
		var savedTime:Float = (FlxG.sound.music != null) ? FlxG.sound.music.time : -1;
		if (wasPlaying) FlxG.sound.music.pause();
		try { fn(); } catch (e:Dynamic) {}
		if (FlxG.sound.music != null)
		{
			if (savedTime >= 0) FlxG.sound.music.time = savedTime; // 兜底恢复播放位置
			if (wasPlaying) FlxG.sound.music.resume();
		}
	}

	function pasteToCurrentSection():Void
	{
		withMusicPaused(function()
		{
			var json:String = FlxG.save.data.copiedSection;
			if (json != null && json.length > 0 && curSec >= 0 && curSec < _song.notes.length)
			{
				var parsed:Dynamic = haxe.Json.parse(json);
				if (parsed != null)
				{
					pushUndo();
					// ★ 粘贴时也按勾选状态过滤（覆盖旧存档里未过滤的复制数据）
					filterSectionByChecks(parsed);
					// ★ 把每个 note 的 strumTime 从「复制小节的时间原点」平移到「当前小节的时间原点」
					var copiedTime:Float = FlxG.save.data.copiedSectionTime;
					var offset:Float = sectionStartTime() - copiedTime;
					if (parsed.sectionNotes != null)
					{
						for (note in (parsed.sectionNotes:Array<Dynamic>))
						{
							if (note != null && Std.is(note, Array) && note.length > 0 && note[0] != null)
								note[0] = note[0] + offset;
						}
					}
					appendSectionNotes(parsed); // ★ 纯粘贴：不清除目标原有内容、不改 mustHit/gf
					updateGrid(false); // 只重绘当前小节（下一小节预览未变，跳过省一半重建开销）
				}
			}
		});
	}

	function clearCurrentSection():Void
	{
		if (curSec >= 0 && curSec < _song.notes.length)
		{
			pushUndo();
			var sec = _song.notes[curSec];
			// ★ 清除语义（与旧版 Clear 按钮一致）：「包含音符/包含事件」勾选 = 该部分被清除；
			//   注意与 filterSectionByChecks（复制/粘贴用，勾选 = 保留）语义相反，不能混用！
			var includeNotes:Bool = (check_notesSec != null) ? check_notesSec.checked : true;
			var includeEvents:Bool = (check_eventsSec != null) ? check_eventsSec.checked : true;

			// 小节内 sectionNotes：清除勾选的部分（事件行 [1] == -1）
			if (sec.sectionNotes != null)
			{
				var kept:Array<Dynamic> = [];
				for (note in (sec.sectionNotes:Array<Dynamic>))
				{
					if (note == null || !Std.is(note, Array)) continue;
					var arrNote:Array<Dynamic> = cast note;
					var isEventRow:Bool = (arrNote.length > 1 && arrNote[1] == -1);
					if (isEventRow)
					{
						if (!includeEvents) kept.push(note); // 未勾选「包含事件」→ 保留事件行
					}
					else
					{
						if (!includeNotes) kept.push(note); // 未勾选「包含音符」→ 保留音符
					}
				}
				sec.sectionNotes = kept;
			}

			// 全局事件 _song.events：勾选「包含事件」时清除当前小节时间段内的事件（与旧版 Clear 一致）
			if (includeEvents && _song.events != null)
			{
				var i:Int = _song.events.length - 1;
				var startThing:Float = sectionStartTime();
				var endThing:Float = sectionStartTime(1);
				while (i > -1)
				{
					var event:Array<Dynamic> = _song.events[i];
					if (event != null && endThing > event[0] && event[0] >= startThing)
						_song.events.remove(event);
					--i;
				}
			}
			updateGrid();
		}
	}

	/** 交换当前小节内玩家（BF）与对手（opp）的 NOTE：键位在两侧对调。
	    ★ 注意：不翻转 mustHitSection——键位对调本身已让 BF 改接原 opp 的 note、
	      opp 改接原 BF 的 note；再翻转 mustHit 会把归属又换回去，还误改了「玩家小节」设置。
	      （角色头像位置由 mustHitSection 驱动，翻转会导致 bf/dad 位置互换） */
	function swapSectionSides():Void
	{
		if (curSec >= 0 && curSec < _song.notes.length)
		{
			pushUndo();
			var perSide:Int = _song.mania + 1;
			var notes = _song.notes[curSec].sectionNotes;
			for (note in notes)
			{
				if (note == null || !Std.is(note, Array)) continue;
				var arrNote:Array<Dynamic> = cast note;
				if (arrNote.length < 2 || arrNote[1] == null || !Std.is(arrNote[1], Int) && !Std.is(arrNote[1], Float)) continue;
				// 玩家侧 0..mania ⇄ 对手侧 (mania+1)..(mania*2+1)
				if (arrNote[1] < perSide) arrNote[1] += perSide;
				else arrNote[1] -= perSide;
			}
			updateGrid();
		}
	}

	function copyLastSectionToCurrent():Void
	{
		if (curSec > 0 && curSec < _song.notes.length)
		{
			withMusicPaused(function()
			{
				pushUndo();
				var parsed:Dynamic = haxe.Json.parse(haxe.Json.stringify(_song.notes[curSec - 1]));
				// ★ 按「包含音符 / 包含事件」勾选状态过滤
				filterSectionByChecks(parsed);
				// ★ 时间偏移：源小节(curSec-1)的 note 时间平移到当前小节，否则全部堆在源小节位置（谱面外）
				applySectionTimeOffset(parsed, sectionStartTime() - sectionStartTime(-1));
				appendSectionNotes(parsed); // ★ 纯粘贴：不清除目标原有内容、不改 mustHit/gf
				updateGrid(false); // 只重绘当前小节
			});
		}
	}

	/** 复制节拍：以当前小节 curSec 为基准，偏移 offset（stepper 值，可正可负），
	    把源小节 [curSec - offset] 复制覆盖到当前小节。offset=1 即原"复制上一小节"。 */
	function copyBeat():Void
	{
		if (copyBeatStepper == null || _song.notes == null) return;
		var offset:Int = Std.int(copyBeatStepper.value);
		if (offset == 0)
		{
			trace('[charting] 复制节拍失败：偏移量为 0（复制自己没意义），请在 stepper 里输入非零值');
			return;
		}
		var src:Int = curSec - offset;
		if (src >= 0 && src < _song.notes.length && curSec >= 0 && curSec < _song.notes.length)
		{
			withMusicPaused(function()
			{
				pushUndo();
				var parsed:Dynamic = haxe.Json.parse(haxe.Json.stringify(_song.notes[src]));
				// ★ 按「包含音符 / 包含事件」勾选状态过滤
				filterSectionByChecks(parsed);
				// ★ 时间偏移：把源小节 src 的 note 时间平移到当前小节（sectionStartTime 的 add 是相对 curSec 的偏移）
				applySectionTimeOffset(parsed, sectionStartTime() - sectionStartTime(src - curSec));
				appendSectionNotes(parsed); // ★ 纯粘贴：不清除目标原有内容、不改 mustHit/gf
				updateGrid(false); // 只重绘当前小节
			});
		}
		else
			trace('[charting] 复制节拍失败：源小节越界 src=$src（当前小节 curSec=$curSec）');
	}

	/** 把复制来的小节里每个 note 的 strumTime 整体平移 offset 毫秒。 */
	function applySectionTimeOffset(sec:Dynamic, offset:Float):Void
	{
		if (sec == null || sec.sectionNotes == null || offset == 0) return;
		for (note in (sec.sectionNotes:Array<Dynamic>))
		{
			if (note != null && Std.is(note, Array) && note.length > 0 && note[0] != null)
				note[0] = note[0] + offset;
		}
	}

	function duetCurrentSection():Void
	{
		if (curSec >= 0 && curSec < _song.notes.length)
		{
			pushUndo();
			var perSide:Int = _song.mania + 1;
			// ★ 二重奏 = 平衡两侧：谁多，就把多的那侧的每个音符复制一份给少的一侧，
			//   让两边数量相等（BF 16 个 + opp 8 个 → 二重奏后两边各 16 个）。
			//   只复制「多的一方」，少的一方保持不动。
			var playerNotes:Array<Array<Dynamic>> = [];
			var oppNotes:Array<Array<Dynamic>> = [];
			for (note in _song.notes[curSec].sectionNotes)
			{
				// 防御：可能混入 null / 非数组 / 事件 note（[1] 是数组）
				if (note == null || !Std.is(note, Array)) continue;
				var arrNote:Array<Dynamic> = cast note;
				if (arrNote.length < 2 || arrNote[1] == null || !Std.is(arrNote[1], Int) && !Std.is(arrNote[1], Float)) continue;
				// 先收集到快照再处理，避免遍历的同时 push 导致重复处理
				if (arrNote[1] < perSide) playerNotes.push(arrNote);
				else oppNotes.push(arrNote);
			}
			if (playerNotes.length > oppNotes.length)
			{
				// 玩家侧多 → 把玩家侧的复制到对手侧（键位平移 perSide，恰好落在对手键位区间）
				for (pn in playerNotes)
				{
					var newNote:Array<Dynamic> = pn.copy();
					newNote[1] = newNote[1] + perSide;
					_song.notes[curSec].sectionNotes.push(newNote);
				}
			}
			else if (oppNotes.length > playerNotes.length)
			{
				// 对手侧多 → 把对手侧的复制到玩家侧
				for (on in oppNotes)
				{
					var newNote:Array<Dynamic> = on.copy();
					newNote[1] = newNote[1] - perSide;
					_song.notes[curSec].sectionNotes.push(newNote);
				}
			}
			// 两侧数量相等时无需操作（本来就已经平衡）
			updateGrid();
		}
	}

	function mirrorCurrentSection():Void
	{
		if (curSec >= 0 && curSec < _song.notes.length)
		{
			pushUndo();
			var notes = _song.notes[curSec].sectionNotes;
			var keysPerPlayer = _song.mania;
			for (note in notes)
			{
				// ★ 同 duet：镜像操作的是键位 note[1]，跳过 null / 非数组 / 事件 note
				if (note == null || !Std.is(note, Array)) continue;
				var arrNote:Array<Dynamic> = cast note;
				if (arrNote.length < 2 || arrNote[1] == null || !Std.is(arrNote[1], Int) && !Std.is(arrNote[1], Float)) continue;
				arrNote[1] = (keysPerPlayer * 2 + 1) - arrNote[1];
			}
			updateGrid();
		}
	}

	function addNewEventToCurrentSection():Void
	{
		// 在当前选中的音符上添加事件
		// ★ 事件音符判定必须用 [1] 是否为数组：普通音符的 [1] 是轨道号（Int），
		//   旧谱面普通音符的 [2]（susLength）也可能为 null，用 [2]==null 判断会把普通音符
		//   误判成事件音符 → 对 Int 调 push → 空指针崩溃（ACCESS_VIOLATION read 0x0）。
		if (curSelectedNote != null && Std.is(curSelectedNote[1], Array))
		{
			var eventsGroup:Array<Dynamic> = cast curSelectedNote[1];
			if (eventsGroup == null) return;
			eventsGroup.push(['', '', '']);
			changeEventSelected(1);
			updateGrid();
		}
	}

	function deleteSelectedEvent():Void
	{
		// 删除当前选中的事件
		if (curSelectedNote != null && Std.is(curSelectedNote[1], Array))
		{
			var eventsGroup:Array<Dynamic> = cast curSelectedNote[1];
			if (eventsGroup == null || eventsGroup.length < 1) return;
			if (curEventSelected >= 0 && curEventSelected < eventsGroup.length)
			{
				eventsGroup.remove(eventsGroup[curEventSelected]);
				if (eventsGroup.length < 1)
				{
					// ★ 事件删空 → 顺带移除整个事件音符（与旧版「-」按钮行为一致，
					//   否则网格里会留下一个空事件箭头，看起来像没删掉）
					_song.events.remove(curSelectedNote);
					curSelectedNote = null;
					curEventSelected = 0;
				}
				else
				{
					if (curEventSelected >= eventsGroup.length)
						curEventSelected = eventsGroup.length - 1;
					if (curEventSelected < 0) curEventSelected = 0;
				}
				updateGrid();
			}
		}
	}

	function selectPrevEvent():Void
	{
		changeEventSelected(-1);
	}

	function selectNextEvent():Void
	{
		changeEventSelected(1);
	}

	function startPlaytest():Void
	{
		if (FlxG.sound.music != null)
			FlxG.sound.music.stop();

		if (vocals != null)
		{
			vocals.pause();
			vocals.volume = 0;
		}
		if (opponentVocals != null)
		{
			opponentVocals.pause();
			opponentVocals.volume = 0;
		}

		autosaveSong();
		playtesting = true;
		playtestingTime = Conductor.songPosition; // 试玩前位置（返回编辑器时恢复用）
		playtestingOnComplete = FlxG.sound.music.onComplete;
		// ★ 试玩从当前位置开始，但 EditorPlayState 内会先播放 3,2,1,GO 倒计时再开播
		removeVirtualPad();
		openSubState(new developer.editors.EditorPlayState(playbackSpeed));
	}

	/**
	 * 以「正常游玩模式」进入 PlayState。
	 * 对应原版的 ENTER，也对应新顶栏菜单 [测试] → 「以正常模式进行」。
	 */
	function startNormalPlay():Void
	{
		autosaveSong();
		FlxG.mouse.visible = false;
		PlayState.SONG = _song;
		FlxG.sound.music.stop();
		if (vocals != null)
			vocals.stop();
		if (opponentVocals != null)
			opponentVocals.stop();

		// if(_song.stage == null) _song.stage = stageDropDown.selectedLabel;
		StageData.loadDirectory(_song);
		LoadingState.loadAndSwitchState(new PlayState());
	}

	function clearEvents()
	{
		_song.events = [];
		updateGrid();
	}

	private function saveLevel()
	{
		if (_song.events != null && _song.events.length > 1)
			_song.events.sort(sortByTime);
		var json = {
			"song": _song
		};

		var data:String = haxe.Json.stringify(json, "\t");

		if ((data != null) && (data.length > 0))
		{
			// ★ 保存文件名自动带难度后缀：难度输入框填了 Fuck → 「歌曲名-Fuck.json」
			var saveName:String = Paths.formatToSongPath(_song.song);
			var diff:String = (difficultyInputText != null && difficultyInputText.text != null) ? StringTools.trim(difficultyInputText.text) : '';
			if (diff.length > 0)
				saveName += '-' + Paths.formatToSongPath(diff);
			#if mobile
			SUtil.saveContent(saveName, ".json", data.trim());
			#else
			_file = new FileReference();
			_file.addEventListener(#if desktop Event.SELECT #else Event.COMPLETE #end, onSaveComplete);
			_file.addEventListener(Event.CANCEL, onSaveCancel);
			_file.addEventListener(IOErrorEvent.IO_ERROR, onSaveError);
			_file.save(data.trim(), saveName + ".json");
			#end
		}
	}

	function sortByTime(Obj1:Array<Dynamic>, Obj2:Array<Dynamic>):Int
	{
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1[0], Obj2[0]);
	}

	private function saveEvents()
	{
		if (_song.events != null && _song.events.length > 1)
			_song.events.sort(sortByTime);
		var eventsSong:Dynamic = {
			events: _song.events,
			format: 'psych_v1'
		};
		var json = {
			"song": eventsSong
		}

		var data:String = haxe.Json.stringify(json, "\t");

		if ((data != null) && (data.length > 0))
		{
			#if mobile
			SUtil.saveContent("events", ".json", data.trim());
			#else
			_file = new FileReference();
			_file.addEventListener(#if desktop Event.SELECT #else Event.COMPLETE #end, onSaveComplete);
			_file.addEventListener(Event.CANCEL, onSaveCancel);
			_file.addEventListener(IOErrorEvent.IO_ERROR, onSaveError);
			_file.save(data.trim(), "events.json");
			#end
		}
	}

	function onSaveComplete(_):Void
	{
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
		FlxG.log.notice("Successfully saved LEVEL DATA.");
	}

	/**
	 * Called when the save file dialog is cancelled.
	 */
	function onSaveCancel(_):Void
	{
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
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
		FlxG.log.error("Problem saving Level data");
	}

	function getSectionBeats(?section:Null<Int> = null)
	{
		if (section == null)
			section = curSec;
		var val:Null<Float> = null;

		if (_song.notes[section] != null)
			val = _song.notes[section].sectionBeats;
		return val != null ? val : 4;
	}

	// ★ 网格左右平移（shiftGridX）已移除：谱面固定居中，gridOffsetX 恒为 0。

	/** ★ 只按 _song.mania 重算键数，不移动任何音符数据。
	 *   用于创建/载入/autosave/引擎切换等「数据与 mania 配套」的场景——
	 *   绝不能走 updateKeyAmounts 的平移逻辑：它以旧 totalKeys 为基准平移数据，
	 *   若字段默认 totalKeys=8 而谱面是非 4K，每次重建都会把已排好的数据二次平移错乱
	 *   （典型症状：前 4K 正常、其余键全部跑到对方/越界）。 */
	function recalcKeyAmounts():Void
	{
		leftKeys = _song.mania + 1;
		rightKeys = _song.mania + 1;
		totalKeys = leftKeys + rightKeys;
		gridOffsetX = 0; // re-anchor to left edge when key count changes
	}

	/** 用户主动改变 mania 时：重算键数并把音符数据从旧布局平移到新布局（缩小会裁剪越界音符） */
	function updateKeyAmounts():Void
	{
		var oldTotalKeys:Int = totalKeys;
		recalcKeyAmounts();
		
		if (totalKeys < oldTotalKeys)
		{
			var oldLeftKeys:Int = oldTotalKeys >> 1;
			var diff:Int = oldLeftKeys - leftKeys;
			for (section in _song.notes)
			{
				var i:Int = section.sectionNotes.length - 1;
				while (i >= 0)
				{
					var row:Dynamic = section.sectionNotes[i];
					// 防御：事件行 [1] 是数组、或 lane 非 Int → 不参与平移
					if (row == null || !Std.is(row, Array)) { i--; continue; }
					var rowArr:Array<Dynamic> = cast row;
					if (rowArr.length < 2 || rowArr[1] == null || Std.is(rowArr[1], Array)
						|| (!Std.is(rowArr[1], Int) && !Std.is(rowArr[1], Float))) { i--; continue; }
					var nd:Int = Std.int(rowArr[1]);
					// Remove rightmost diff lanes from each side
					if ((nd >= oldLeftKeys - diff && nd < oldLeftKeys) || nd >= oldTotalKeys - diff)
						section.sectionNotes.remove(section.sectionNotes[i]);
					// Shift remaining opponent notes left to fill the gap
					else if (nd >= oldLeftKeys)
						rowArr[1] = nd - diff;
					i--;
				}
			}
		}
		else if (totalKeys > oldTotalKeys)
		{
			var oldLeftKeys:Int = oldTotalKeys >> 1;
			var diff:Int = leftKeys - oldLeftKeys;
			// Shift opponent notes right by diff to make room for new player lanes
			for (section in _song.notes)
			{
				for (note in section.sectionNotes)
				{
					if (note == null || !Std.is(note, Array)) continue;
					var rowArr:Array<Dynamic> = cast note;
					if (rowArr.length < 2 || rowArr[1] == null || Std.is(rowArr[1], Array)
						|| (!Std.is(rowArr[1], Int) && !Std.is(rowArr[1], Float))) continue;
					if (Std.int(rowArr[1]) >= oldLeftKeys)
						rowArr[1] = Std.int(rowArr[1]) + diff;
				}
			}
		}
	}

	/** ★ 数据驱动的键数自检：谱面 json 缺 mania 字段时解析会默认 3（4K），
	 *   若音符数据实际占了更高的 lane（非 4K 谱），按数据提升 mania（只升不降），
	 *   避免"前 4K 正常、其余 key 全部判定到对方"的错位。数据本身按 lane 排布，无需平移。 */
	function autoFixManiaFromData():Void
	{
		if (_song == null || _song.notes == null) return;
		var maxLane:Int = -1;
		for (sec in _song.notes)
		{
			if (sec == null || sec.sectionNotes == null) continue;
			for (n in (sec.sectionNotes:Array<Dynamic>))
			{
				if (n == null || !Std.is(n, Array)) continue;
				var arr:Array<Dynamic> = cast n;
				if (arr.length < 2 || arr[1] == null) continue;
				// 事件行 [1] 是数组；普通音符 lane 是非负 Int
				if (Std.is(arr[1], Array)) continue;
				if (!Std.is(arr[1], Int) && !Std.is(arr[1], Float)) continue;
				var lane:Int = Std.int(arr[1]);
				if (lane >= 0 && lane > maxLane) maxLane = lane;
			}
		}
		if (maxLane < 0) return;
		// 需要每侧 needKeys 键才装得下 maxLane（lane 0..needKeys-1 玩家侧、needKeys.. 对手侧）
		var needKeys:Int = Std.int(maxLane / 2) + 1;
		var needMania:Int = needKeys - 1;
		if (needMania > _song.mania)
		{
			trace('[charting] mania 自检：数据最大 lane=$maxLane，当前 ${_song.mania + 1}K 装不下 → 提升为 ${needMania + 1}K');
			_song.mania = needMania;
		}
	}

	/** ExtraKeys 实际支持的键数上限：优先 keys 配置表长度（extrakeys.json 的 maxKeys=9
	 *  是过期值——keys 表有 10 项、实际支持 10K），其次 maxKeys 字段，最后兜底 10 */
	function extraMaxKeys():Int
	{
		var ek = ExtraKeysHandler.instance;
		if (ek != null && ek.data != null)
		{
			if (ek.data.keys != null && ek.data.keys.length > 0) return ek.data.keys.length;
			if (ek.data.maxKeys > 0) return ek.data.maxKeys;
		}
		return 10;
	}

	function makeStrumNotes():Void
	{
		strumLineNotes.clear();
		var gx:Float = getGridX();
		
		for (i in 0...totalKeys)
		{
			var note:StrumNote;
			var player:Int = i < leftKeys ? 1 : 0;
			var noteData:Int = i < leftKeys ? i : i - leftKeys;
			
			note = new StrumNote(gx + GRID_SIZE * (i + 1), strumLine.y, noteData, player);
			note.setGraphicSize(GRID_SIZE, GRID_SIZE);
			note.updateHitbox();
			note.playAnim('static', true);
			strumLineNotes.add(note);
			note.scrollFactor.set(1, 1);
		}
		
		if (strumLine != null)
		{
			strumLine.makeGraphic(Std.int(GRID_SIZE * (totalKeys + 1)), 4);
			strumLine.x = gx;
		}

		if (eventIcon != null)
		{
			eventIcon.x = gx - GRID_SIZE - 5;
		}
		
		positionSideIcons();
	}

	/** ★ 两个角色头像重新水平居中到各自一侧的 note 轨道组正上方（y 固定 -100 锚点）。
	 *  网格几何变化（mania 键数 / 水平居中偏移）或头像换图（宽度变化）后都必须调用，
	 *  否则头像停在旧位置，与轨道列错位。 */
	function positionSideIcons():Void
	{
		if (leftIcon == null || rightIcon == null) return;
		var gx:Float = getGridX();
		// 左组轨道列 x 跨度 [gx+GRID, gx+GRID*(leftKeys+1)] → 中心 = gx + GRID*(leftKeys+2)/2
		leftIcon.setPosition(gx + GRID_SIZE * (leftKeys + 2) / 2 - leftIcon.width / 2, -100);
		// 右组轨道列 x 跨度 [gx+GRID*(leftKeys+1), gx+GRID*(totalKeys+1)] → 中心 = gx + GRID*(leftKeys+totalKeys+2)/2
		rightIcon.setPosition(gx + GRID_SIZE * (leftKeys + totalKeys + 2) / 2 - rightIcon.width / 2, -100);
	}

}

class AttachedFlxText extends FlxText
{
	public var sprTracker:FlxSprite;
	public var xAdd:Float = 0;
	public var yAdd:Float = 0;

	public function new(X:Float = 0, Y:Float = 0, FieldWidth:Float = 0, ?Text:String, Size:Int = 8, EmbeddedFont:Bool = true)
	{
		super(X, Y, FieldWidth, Text, Size, EmbeddedFont);
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (sprTracker != null)
		{
			setPosition(sprTracker.x + xAdd, sprTracker.y + yAdd);
			angle = sprTracker.angle;
			alpha = sprTracker.alpha;
		}
	}
}

