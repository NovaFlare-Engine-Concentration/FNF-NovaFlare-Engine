package games;

import openfl.Lib;
import gameanalytics.GABridge;

import haxe.Timer;
import haxe.Json;

import cpp.vm.Gc;

import openfl.utils.Assets;
import openfl.events.KeyboardEvent;

import flixel.FlxBasic;
import flixel.FlxObject;
import flixel.FlxSubState;
import flixel.util.FlxSort;
import flixel.util.FlxStringUtil;
import flixel.util.FlxSave;
import flixel.input.keyboard.FlxKey;
import flixel.animation.FlxAnimationController;
import flixel.input.touch.FlxTouch;
import flixel.graphics.FlxGraphic;

import modchart.Manager;

import general.objects.AttachedSprite;
import general.backend.DeepDebugTracker;

import states.storyMenuState.StoryMenuState;
import states.freeplayState.FreeplayState;

import developer.editors.ChartingState;
import developer.editors.CharacterEditorState;

import substates.PauseSubState;
import substates.GameOverSubstate;
import substates.ResultsScreen;

import general.shaders.ErrorHandledShader;

import games.stages.*;

import games.objects.*;
import games.objects.Note.EventNote;
import games.objects.StrumNote.KeybindShowcase;
import games.objects.StrumNote.StrumBoundaries;

import games.backend.Highscore;
import games.backend.StageData;
import games.backend.WeekData;
import games.backend.Song;
import games.backend.Section;
import games.backend.Rating;
import games.backend.Replay;
import games.backend.TimingSystem;

import games.cutscenes.CutsceneHandler;
import games.cutscenes.DialogueBoxPsych;

#if CUSTOM_SHADERS_ALLOWED
import general.shaders.CustomShaders;
import general.shaders.openfl.filters.ShaderFilter as CustomShaderFilter;
import openfl.filters.BitmapFilter;
#end

#if LUA_ALLOWED
import scripts.lua.*;
#else
import scripts.lua.LuaUtils;
#end

#if HSCRIPT_ALLOWED
import scripts.hscript.HScript;
import scripts.hscript.HScriptPack;
import crowplexus.hscript.Expr.Error as IrisError;
import crowplexus.hscript.Printer;
#end

@:allow(games.backend.Replay)
/**
 * This is where all the Gameplay stuff happens and is managed
 *
 * here's some useful tips if you are making a mod in source:
 *
 * If you want to add your stage to the game, copy states/stages/Template.hx,
 * and put your stage code there, then, on PlayState, search for
 * "switch (curStage)", and add your stage to that list.
 *
 * If you want to code Events, you can either code it on a Stage file or on PlayState, if you're doing the latter, search for:
 *
 * "function eventPushed" - Only called *one time* when the game loads, use it for precaching events that use the same assets, no matter the values
 * "function eventPushedUnique" - Called one time per event, use it for precaching events that uses different assets based on its values
 * "function eventEarlyTrigger" - Used for making your event start a few MILLISECONDS earlier
 * "function triggerEvent" - Called when the song hits your event's timestamp, this is probably what you were looking for
**/
class PlayState extends MusicBeatState
{
	public static var STRUM_X = 48.5;
	public static var STRUM_X_MIDDLESCROLL = -278;

	public static var ratingStuff:Array<Dynamic> = [
		['You Suck!', 0.2], // From 0% to 19%
		['Shit', 0.4], // From 20% to 39%
		['Bad', 0.5], // From 40% to 49%
		['Bruh', 0.6], // From 50% to 59%
		['Meh', 0.69], // From 60% to 68%
		['Nice', 0.7], // 69%
		['Good', 0.8], // From 70% to 79%
		['Great', 0.9], // From 80% to 89%
		['Sick!', 1], // From 90% to 99%
		['Perfect!!', 1] // The value on this one isn't used actually, since Perfect is always "1"
	];

	// event variables
	private var isCameraOnForcedPos:Bool = false;

	public var boyfriendMap:Map<String, Character> = new Map<String, Character>();
	public var dadMap:Map<String, Character> = new Map<String, Character>();
	public var gfMap:Map<String, Character> = new Map<String, Character>();

	#if HSCRIPT_ALLOWED
	public var hscriptArray:Array<HScript> = [];
	public var instancesExclude:Array<String> = [];
	public var hscriptGrp:HScriptPack;
	#end

	#if LUA_ALLOWED
	public var modchartTweens:Map<String, FlxTween> = new Map<String, FlxTween>();
	public var modchartSprites:Map<String, ModchartSprite> = new Map<String, ModchartSprite>();
	public var modchartTimers:Map<String, FlxTimer> = new Map<String, FlxTimer>();
	public var modchartSounds:Map<String, FlxSound> = new Map<String, FlxSound>();
	public var modchartTexts:Map<String, FlxText> = new Map<String, FlxText>();
	public var modchartSaves:Map<String, FlxSave> = new Map<String, FlxSave>();
	#if CUSTOM_SHADERS_ALLOWED
	public var modchartShader:Map<String, Effect> = new Map<String, Effect>();
	public var shaderUpdates:Array<Float->Void> = [];
	#end
	#end
	public var BF_X:Float = 770;
	public var BF_Y:Float = 100;
	public var DAD_X:Float = 100;
	public var DAD_Y:Float = 100;
	public var GF_X:Float = 400;
	public var GF_Y:Float = 130;

	public var songSpeedTween:FlxTween;
	public var songSpeed(default, set):Float = 1;
	public var songSpeedType:String = "multiplicative";
	public var noteKillOffset:Float = 350;

    public var playbackRate(default, set):Float = 1;
    public var timing:TimingSystem;
    public var timingDebug:FlxText;

	public var boyfriendGroup:FlxSpriteGroup;
	public var dadGroup:FlxSpriteGroup;
	public var gfGroup:FlxSpriteGroup;

	public static var curStage:String = '';
	public static var stageUI:String = "normal";
	public static var isPixelStage(get, never):Bool;

	@:noCompletion
	static function get_isPixelStage():Bool
		return stageUI == "pixel" || stageUI.endsWith("-pixel");

	public static var SONG:SwagSong = null;
	public static var isStoryMode:Bool = false;
	public static var storyWeek:Int = 0;
	public static var storyPlaylist:Array<String> = [];
	public static var storyDifficulty:Int = 1;

	public var spawnTime:Float = 2000;

	public var inst:FlxSound;
	public var vocals:FlxSound;
	public var opponentVocals:FlxSound;
	public var splitVocals:Bool = false;

	public var dad:Character = null;
	public var gf:Character = null;
	public var boyfriend:Character = null;

	public var notes:FlxTypedGroup<Note>;
	public var killNotes:Array<Note> = [];
	public var killNotesBudget:Int = 20;
	public var unspawnNotes:Array<Note> = [];
	public var eventNotes:Array<EventNote> = [];
	public var tempNotes:Array<Note> = [];

	public var camFollow:FlxObject;
	private static var prevCamFollow:FlxObject;

	public var strumLineNotes:FlxTypedGroup<StrumNote>;
	public var opponentStrums:FlxTypedGroup<StrumNote>;
	public var playerStrums:FlxTypedGroup<StrumNote>;
	public var grpNoteSplashes:FlxTypedGroup<NoteSplash>;
	public var sustainLayer:FlxTypedGroup<Note>;
	public var tapLayer:FlxTypedGroup<Note>;

	public var camZooming:Bool = false;
	public var camZoomingMult:Float = 1;
	public var camZoomingDecay:Float = 1;

	private var curSong:String = "";

	public var gfSpeed:Int = 1;
	public var health(default, set):Float = 1;
	public var combo:Int = 0;
	public var highestCombo:Int = 0;

	public var NoteMs:Array<Float> = [];
	public var NoteTime:Array<Float> = [];

	var numItems:FlxTypedGroup<FlxSprite>;
	var onUpdateArgs:Array<Dynamic> = [0.0];
	var onUpdatePostArgs:Array<Dynamic> = [0.0];
	var spawnNoteArgs:Array<Dynamic> = [0, 0, null, false, 0.0];
	var singleArg:Array<Dynamic> = [null];

	var comboOffsetFix:Array<Array<Int>> = [
		[0, 0], // num0
		[-2, -1], // num1
		[-6, 6], // num2
		[-4, 6], // num3
		[-2, 9], // num4
		[-12, 12], // num5
		[-11, 8], // num6
		[1, -2], // num7
		[2, -2], // num8
		[1, -1] // num9
	];

	var notesHitArray:Array<Date> = [];
	var nps:Int = 0;
	var maxNPS:Int = 0;
	var npsCheck:Int = 0;

	public var healthBar:Bar;
	public var timeBar:Bar;
	public var healthBarBG:AttachedSprite;
	public var timeBarBG:AttachedSprite; // 修复那傻逼lua

	var songPercent:Float = 0;

	public var keyboardViewer:KeyboardViewer;

	public var ratingsData:Array<Rating> = Rating.loadDefault();

	private var generatedMusic:Bool = false;

	public var endingSong:Bool = false;
	public var startingSong:Bool = false;

	private var updateTime:Bool = true;

	public static var changedDifficulty:Bool = false;
	public static var chartingMode:Bool = false;

	// Gameplay settings
	public var healthGain:Float = 1;
	public var healthLoss:Float = 1;

	public var guitarHeroSustains:Bool = false;
	public var instakillOnMiss:Bool = false;
	public var cpuControlled:Bool = false;
	public var cpuControlled_opponent:Bool = false;
	public var practiceMode:Bool = false;
	
	public static var replayMode:Bool = false;
	private var replayExam:Replay;

	public var txtSine:Float = 0;
	public var botplayTxt:FlxText;
	public var replayTxt:FlxText;

	public var iconP1:HealthIcon;
	public var iconP2:HealthIcon;
	public var camHUD:FlxCamera;
	public var camGame:FlxCamera;
	public var camOther:FlxCamera;
	public var luaVpadCam:FlxCamera;
	public var camPause:FlxCamera;
	public var cameraSpeed:Float = 1;

	public var songScore:Int = 0;
	public var songHits:Int = 0;
	public var songMisses:Int = 0;
	public var scoreTxt:FlxText;
	public var judgementCounter_S:JudgementCounter; // add _S is make sure nobody make a new one broken this

	var timeTxt:FlxText;
	var scoreTxtTween:FlxTween;

	public var pauseButton_menu:TouchSpriteButton;

	public static var campaignScore:Int = 0;
	public static var campaignMisses:Int = 0;
	public static var seenCutscene:Bool = false;
	public static var deathCounter:Int = 0;

	public var defaultCamZoom:Float = 1.05;

	// how big to stretch the pixel art assets
	public static var daPixelZoom:Float = 6;

	private var singAnimations:Array<String> = ['singLEFT', 'singDOWN', 'singUP', 'singRIGHT'];

	public var inCutscene:Bool = false;
	public var skipCountdown:Bool = false;
	public var songLength:Float = 0;

	public var boyfriendCameraOffset:Array<Float> = null;
	public var opponentCameraOffset:Array<Float> = null;
	public var girlfriendCameraOffset:Array<Float> = null;

	#if DISCORD_ALLOWED
	// Discord RPC variables
	var storyDifficultyText:String = "";
	var detailsText:String = "";
	var detailsPausedText:String = "";
	#end

	// Achievement shit
	var keysPressed:Array<Int> = [];
	var boyfriendIdleTime:Float = 0.0;
	var boyfriendIdled:Bool = false;

	// Lua shit
	public static var instance:PlayState;

	#if LUA_ALLOWED public var luaArray:Array<FunkinLua> = []; #end

	#if (LUA_ALLOWED || HSCRIPT_ALLOWED)
	private var luaDebugGroup:FlxTypedGroup<DebugLuaText>;
	#end

	public var introSoundsSuffix:String = '';

	// Less laggy controls
	public var keysArray:Array<String>;
	public var songName:String;

	// Callbacks for stages
	public var startCallback:Void->Void = null;
	public var endCallback:Void->Void = null;

	public var luaVirtualPad:FlxVirtualPad;

	var diffBotplay:Bool;

	var _hold:Array<Bool> = [];
	var _press:Array<Bool> = [];
	var _release:Array<Bool> = [];

	public function new()
	{
		super();
	}
	
	override public function create()
	{
		if (ClientPrefs.data.deepDebug && !DeepDebugTracker.active && SONG != null)
			DeepDebugTracker.begin(SONG.song, Mods.currentModDirectory, Difficulty.getString());

		// LoadingState clears caches when the song/mod context changes. A restart
		// bypasses LoadingState intentionally so the same decoded audio, frames,
		// and animations can be reused instead of rebuilt synchronously.
		GCManager.enable(false);
		
		startCallback = startCountdown;
		endCallback = endSong;
		
		// for lua
		instance = this;
		hscriptGrp = new HScriptPack();
		hscriptArray = hscriptGrp.scriptMembers;

		PauseSubState.songName = null; // Reset to default
		playbackRate = ClientPrefs.getGameplaySetting('songspeed');

		if (SONG.mania != 3)
		{
			keysArray = [];
			for (i in 0...SONG.mania + 1)
			{
				keysArray.push(SONG.mania + '_key_$i');
			}
		}
		else keysArray = ['note_left', 'note_down', 'note_up', 'note_right'];

		_hold = [];
		_press = [];
		_release = [];
		for (i in 0...keysArray.length)
		{
			_hold.push(false);
			_press.push(false);
			_release.push(false);
		}

        if (FlxG.sound.music != null)
            FlxG.sound.music.stop();
        if (timing != null) timing.pause();

		// Gameplay settings
		healthGain = ClientPrefs.getGameplaySetting('healthgain');
		healthLoss = ClientPrefs.getGameplaySetting('healthloss');
		instakillOnMiss = ClientPrefs.getGameplaySetting('instakill');
		practiceMode = ClientPrefs.getGameplaySetting('practice');
		cpuControlled = ClientPrefs.getGameplaySetting('botplay');
		cpuControlled_opponent = ClientPrefs.getGameplaySetting('botplay');
		guitarHeroSustains = ClientPrefs.data.guitarHeroSustains;
		if (ClientPrefs.data.playOpponent)
			cpuControlled = ClientPrefs.data.botOpponentFix;

		replayExam = new Replay(this);
		add(replayExam);

		camGame = initPsychCamera();
		camHUD = new FlxCamera();
		camOther = new FlxCamera();
		luaVpadCam = new FlxCamera();
		camPause = new FlxCamera();

		camHUD.bgColor.alpha = 0;
		camOther.bgColor.alpha = 0;
		luaVpadCam.bgColor.alpha = 0;
		camPause.bgColor.alpha = 0;

		FlxG.cameras.add(camHUD, false);
		FlxG.cameras.add(camOther, false);
		FlxG.cameras.add(luaVpadCam, false);
		FlxG.cameras.add(camPause, false);
		grpNoteSplashes = new FlxTypedGroup<NoteSplash>();

		persistentUpdate = persistentDraw = true;

        Conductor.mapBPMChanges(SONG);
        Conductor.bpm = SONG.bpm;
        timing = new TimingSystem();
        timing.setRate(playbackRate);

		#if DISCORD_ALLOWED
		// String that contains the mode defined here so it isn't necessary to call changePresence for each mode
		storyDifficultyText = Difficulty.getString();

		if (isStoryMode)
			detailsText = "Story Mode: " + WeekData.getCurrentWeek().weekName;
		else
			detailsText = "Freeplay";

		// String for when the game is paused
		detailsPausedText = "Paused - " + detailsText;
		#end

		GameOverSubstate.resetVariables();
		songName = Paths.formatToSongPath(SONG.song);
		if (SONG.stage == null || SONG.stage.length < 1)
		{
			SONG.stage = StageData.vanillaSongStage(songName);
		}
		curStage = SONG.stage;

		var stageData:StageFile = StageData.getStageFile(curStage);
		if (stageData == null)
		{ // Stage couldn't be found, create a dummy stage for preventing a crash
			stageData = StageData.dummy();
		}

		defaultCamZoom = stageData.defaultZoom;

		stageUI = "normal";
		if (stageData.stageUI != null && stageData.stageUI.trim().length > 0)
			stageUI = stageData.stageUI;
		else
		{
			if (stageData.isPixelStage)
				stageUI = "pixel";
		}

		BF_X = stageData.boyfriend[0];
		BF_Y = stageData.boyfriend[1];
		GF_X = stageData.girlfriend[0];
		GF_Y = stageData.girlfriend[1];
		DAD_X = stageData.opponent[0];
		DAD_Y = stageData.opponent[1];

		if (stageData.camera_speed != null)
			cameraSpeed = stageData.camera_speed;

		boyfriendCameraOffset = stageData.camera_boyfriend;
		if (boyfriendCameraOffset == null) // Fucks sake should have done it since the start :rolling_eyes:
			boyfriendCameraOffset = [0, 0];

		opponentCameraOffset = stageData.camera_opponent;
		if (opponentCameraOffset == null)
			opponentCameraOffset = [0, 0];

		girlfriendCameraOffset = stageData.camera_girlfriend;
		if (girlfriendCameraOffset == null)
			girlfriendCameraOffset = [0, 0];

		boyfriendGroup = new FlxSpriteGroup(BF_X, BF_Y);
		dadGroup = new FlxSpriteGroup(DAD_X, DAD_Y);
		gfGroup = new FlxSpriteGroup(GF_X, GF_Y);

		switch (curStage)
		{
			case 'stage':
				new StageWeek1(); // Week 1
			case 'spooky':
				new Spooky(); // Week 2
			case 'philly':
				new Philly(); // Week 3
			case 'limo':
				new Limo(); // Week 4
			case 'mall':
				new Mall(); // Week 5 - Cocoa, Eggnog
			case 'mallEvil':
				new MallEvil(); // Week 5 - Winter Horrorland
			case 'school':
				new School(); // Week 6 - Senpai, Roses
			case 'schoolEvil':
				new SchoolEvil(); // Week 6 - Thorns
			case 'tank':
				new Tank(); // Week 7 - Ugh, Guns, Stress
			case 'phillyStreets':
				new PhillyStreets(); // Weekend 1 - Darnell, Lit Up, 2Hot
			case 'phillyBlazin':
				new PhillyBlazin(); // Weekend 1 - Blazin
			case _: //custom class
				if(Reflect.hasField(stageData, "specifyClass") && stageData.specifyClass != null) {
					if(scripts.scriptClasses.ScriptedBaseStage.__sc_scriptClassLists().contains(stageData.specifyClass)) {
						scripts.scriptClasses.ScriptedBaseStage.createScriptClassInstance(stageData.specifyClass);
					} else {
						var resolve:Dynamic = Type.resolveClass(stageData.specifyClass);
						if(resolve != null) Type.createInstance(cast resolve, []);
					}
				}
		}

		if (isPixelStage)
		{
			introSoundsSuffix = '-pixel';
		}

		if (stageData.objects != null && stageData.objects.length > 0)
		{
			var list:Map<String, FlxSprite> = StageData.addObjectsToState(stageData.objects, !stageData.hide_girlfriend ? gfGroup : null, dadGroup,
				boyfriendGroup, this);
			for (key => spr in list)
				if (!StageData.reservedNames.contains(key))
					variables.set(key, spr);
		}
		else
		{
			add(gfGroup);
			add(dadGroup);
			add(boyfriendGroup);
		}

		#if (LUA_ALLOWED || HSCRIPT_ALLOWED)
		luaDebugGroup = new FlxTypedGroup<DebugLuaText>();
		luaDebugGroup.cameras = [camOther];
		add(luaDebugGroup);
		#end

		// "GLOBAL" SCRIPTS
		#if ((LUA_ALLOWED || HSCRIPT_ALLOWED) && sys)
		for (folder in Mods.directoriesWithFile(Paths.getSharedPath(), 'scripts/'))
			for (file in FileSystem.readDirectory(folder))
			{
				#if LUA_ALLOWED
				if (file.toLowerCase().endsWith('.lua'))
					new FunkinLua(folder + file);
				#end

				#if HSCRIPT_ALLOWED
				if (file.toLowerCase().endsWith('.hx'))
					initHScript(folder + file);
				#end
			}
		#end

		// STAGE SCRIPTS
		#if LUA_ALLOWED
		startLuasNamed('stages/' + curStage + '.lua');
		#end

		#if HSCRIPT_ALLOWED
		startHScriptsNamed('stages/' + curStage + '.hx');
		#end

		if (!stageData.hide_girlfriend)
		{
			if (SONG.gfVersion == null || SONG.gfVersion.length < 1)
				SONG.gfVersion = 'gf'; // Fix for the Chart Editor
			gf = new Character(0, 0, SONG.gfVersion);
			startCharacterPos(gf);
			gf.scrollFactor.set(0.95, 0.95);
			gfGroup.add(gf);
			startCharacterScripts(gf.curCharacter);
		}

		dad = new Character(0, 0, SONG.player2);
		startCharacterPos(dad, true);
		dadGroup.add(dad);
		startCharacterScripts(dad.curCharacter);

		boyfriend = new Character(0, 0, SONG.player1, true);
		startCharacterPos(boyfriend);
		boyfriendGroup.add(boyfriend);
		startCharacterScripts(boyfriend.curCharacter);

		var camPos:FlxPoint = FlxPoint.get(girlfriendCameraOffset[0], girlfriendCameraOffset[1]);
		if (gf != null)
		{
			camPos.x += gf.getGraphicMidpoint().x + gf.cameraPosition[0];
			camPos.y += gf.getGraphicMidpoint().y + gf.cameraPosition[1];
		}

		if (dad.curCharacter.startsWith('gf'))
		{
			dad.setPosition(GF_X, GF_Y);
			if (gf != null)
				gf.visible = false;
		}

		comboGroup = new FlxSpriteGroup();
		add(comboGroup);
		cachePopUpScore();

		uiGroup = new FlxSpriteGroup();
		add(uiGroup);

		Conductor.songPosition = -5000 / Conductor.songPosition;
		var showTime:Bool = (ClientPrefs.data.timeBarType != 'Disabled');
        timeTxt = new FlxText(STRUM_X + (FlxG.width / 2) - 248, 19, 400, "", 32);
		timeTxt.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		timeTxt.scrollFactor.set();
		timeTxt.alpha = 0;
		timeTxt.borderSize = 2;
		timeTxt.visible = updateTime = showTime;
		if (ClientPrefs.data.downScroll)
			timeTxt.y = FlxG.height - 44;
		if (ClientPrefs.data.timeBarType == 'Song Name')
			timeTxt.text = SONG.song;

		timeBarBG = new AttachedSprite('timeBar');
		timeBarBG.visible = false;
		add(timeBarBG);

		timeBar = new Bar(0, timeTxt.y + (timeTxt.height / 4), 'timeBar', function() return songPercent, 0, 1);
		timeBar.scrollFactor.set();
		timeBar.screenCenter(X);
		timeBar.alpha = 0;
		timeBar.visible = showTime;
		timeBarBG.sprTracker = timeBar;
		add(timeBar);
		add(timeTxt);

		healthBarBG = new AttachedSprite('healthBar');
		healthBarBG.visible = false;
		add(healthBarBG);

		healthBar = new Bar(0, FlxG.height * (!ClientPrefs.data.downScroll ? 0.89 : 0.11), 'healthBar', function() return health, 0, 2,
			ClientPrefs.data.oldHealthBarVersion);
		healthBar.screenCenter(X);
		healthBar.leftToRight = ClientPrefs.data.playOpponent;
		healthBar.scrollFactor.set();
		healthBar.visible = !ClientPrefs.data.hideHud;
		healthBar.alpha = ClientPrefs.data.healthBarAlpha;
		reloadHealthBarColors();
		add(healthBar);
		healthBarBG.sprTracker = healthBar;

		iconP1 = new HealthIcon(boyfriend.healthIcon, true);
		iconP1.y = healthBar.y - 75;
		iconP1.visible = !ClientPrefs.data.hideHud;
		iconP1.alpha = ClientPrefs.data.healthBarAlpha;
		add(iconP1);

		iconP2 = new HealthIcon(dad.healthIcon, false);
		iconP2.y = healthBar.y - 75;
		iconP2.visible = !ClientPrefs.data.hideHud;
		iconP2.alpha = ClientPrefs.data.healthBarAlpha;
		add(iconP2);

		scoreTxt = new FlxText(0, healthBar.y + 40, FlxG.width, "", 20);
		scoreTxt.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		scoreTxt.scrollFactor.set();
		scoreTxt.borderSize = 1.25;
		scoreTxt.visible = !ClientPrefs.data.hideHud;
		add(scoreTxt);

		judgementCounter_S = new JudgementCounter(10, 0);
		judgementCounter_S.visible = (ClientPrefs.data.judgementCounter
			&& !ClientPrefs.data.hideHud
			&& !ClientPrefs.getGameplaySetting('botplay'));
		judgementCounter_S.cameras = [camHUD];
		add(judgementCounter_S);
		judgementCounter_S.y = FlxG.height / 2 - judgementCounter_S.height / 2;
		
		healthBar.cameras = [camHUD];
		healthBarBG.cameras = [camHUD];
		iconP1.cameras = [camHUD];
		iconP2.cameras = [camHUD];
		scoreTxt.cameras = [camHUD];
		timeBar.cameras = [camHUD];
		timeBarBG.cameras = [camHUD];
        timeTxt.cameras = [camHUD];

		if (ClientPrefs.data.pauseButton)
		{
			pauseButton_menu = new TouchSpriteButton(2, 2);
			pauseButton_menu.loadGraphic(Paths.image('menuExtend/PlayState/pauseButton'));
			pauseButton_menu.setGraphicSize(100, 100);
			pauseButton_menu.alpha = 0.5;
			pauseButton_menu.visible = false;
			pauseButton_menu.scrollFactor.set();
			add(pauseButton_menu);
			pauseButton_menu.updateHitbox();
			pauseButton_menu.camera = camPause;
		}

		noteGroup = new FlxTypedGroup<FlxBasic>();
		add(noteGroup);

		sustainLayer = new FlxTypedGroup<Note>();
		tapLayer = new FlxTypedGroup<Note>();
		strumLineNotes = new FlxTypedGroup<StrumNote>();
		noteGroup.add(sustainLayer);
		noteGroup.add(strumLineNotes);
		noteGroup.add(tapLayer);

		NoteSplash.init();
		var splash:NoteSplash = new NoteSplash(100, 100);
		splash.setupNoteSplash(100, 100);
		grpNoteSplashes.add(splash);
		noteGroup.add(grpNoteSplashes);
		splash.alpha = 0.000001; // cant make it invisible or it won't allow precaching

		opponentStrums = new FlxTypedGroup<StrumNote>();
		playerStrums = new FlxTypedGroup<StrumNote>();

		botplayTxt = new FlxText(400, timeBar.y + 55, FlxG.width - 800, "BOTPLAY", 32);
		botplayTxt.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		botplayTxt.scrollFactor.set();
		botplayTxt.borderSize = 1.25;
		botplayTxt.visible = ClientPrefs.data.playOpponent ? cpuControlled_opponent : cpuControlled;
		add(botplayTxt);
		if (ClientPrefs.data.downScroll)
			botplayTxt.y = timeBar.y - 78;

		replayTxt = new FlxText(400, timeBar.y + 55, FlxG.width - 800, "REPLAY", 32);
		replayTxt.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		replayTxt.scrollFactor.set();
		replayTxt.borderSize = 1.25;
		replayTxt.visible = replayMode;
		add(replayTxt);
		if (ClientPrefs.data.downScroll)
			replayTxt.y = timeBar.y - 78;

		if (Main.getReplayOverlay() != null)
		{
			if (replayMode && ClientPrefs.data.showReplayWatermark)
				Main.getReplayOverlay().showOverlay();
			else
				Main.getReplayOverlay().hideOverlay();
		}

		if (ClientPrefs.data.timeBarType == 'Song Name'){
			timeTxt.size = 24;
			timeTxt.y += 3;
		}
		botplayTxt.cameras = [camHUD];
		replayTxt.cameras = [camHUD];

		generateSong(SONG.song);

		if (replayMode) {
			replayExam.load();
		}

		keyboardViewer = new KeyboardViewer(ClientPrefs.data.comboOffset[4], ClientPrefs.data.comboOffset[5]);
		keyboardViewer.antialiasing = ClientPrefs.data.antialiasing;
		keyboardViewer.visible = ClientPrefs.data.keyboardViewer;
		add(keyboardViewer);
		keyboardViewer.cameras = [camHUD];

		camFollow = new FlxObject(0, 0, 1, 1);
		camFollow.setPosition(camPos.x, camPos.y);
		camPos.put();

		if (prevCamFollow != null)
		{
			camFollow = prevCamFollow;
			prevCamFollow = null;
		}
		add(camFollow);

		FlxG.camera.follow(camFollow, LOCKON, 0);
		FlxG.camera.zoom = defaultCamZoom;
		FlxG.camera.snapToTarget();

		FlxG.worldBounds.set(0, 0, FlxG.width, FlxG.height);
		moveCameraSection();

		uiGroup.cameras = [camHUD];
		noteGroup.cameras = [camHUD];
		comboGroup.cameras = [camHUD];

		startingSong = true;

		#if LUA_ALLOWED
		for (notetype in noteTypes)
			startLuasNamed('custom_notetypes/' + notetype + '.lua');
		for (event in eventsPushed)
			startLuasNamed('custom_events/' + event + '.lua');
		#end

		#if HSCRIPT_ALLOWED
		for (notetype in noteTypes)
			startHScriptsNamed('custom_notetypes/' + notetype + '.hx');
		for (event in eventsPushed)
			startHScriptsNamed('custom_events/' + event + '.hx');
		#end
		noteTypes = null;
		eventsPushed = null;

		if (eventNotes.length > 1)
		{
			for (event in eventNotes)
				event.strumTime -= eventEarlyTrigger(event);
			eventNotes.sort(sortByTime);
		}

		// SONG SPECIFIC SCRIPTS
		#if ((LUA_ALLOWED || HSCRIPT_ALLOWED) && sys)
		for (folder in Mods.directoriesWithFile(Paths.getSharedPath(), 'data/$songName/'))
			for (file in FileSystem.readDirectory(folder))
			{
				#if LUA_ALLOWED
				if (file.toLowerCase().endsWith('.lua'))
					new FunkinLua(folder + file);
				#end

				#if HSCRIPT_ALLOWED
				if (file.toLowerCase().endsWith('.hx'))
					initHScript(folder + file);
				#end
			}
		#end
		hscriptGrp.execute();
		hscriptGrp.call("onCreate");

		addMobileControls(false);

		startCallback();
		RecalculateRating();

		// PRECACHING THINGS THAT GET USED FREQUENTLY TO AVOID LAGSPIKES
		if (ClientPrefs.data.hitsoundVolume > 0)
			Paths.sound('hitsound');
		for (i in 1...4)
			Paths.sound('missnote$i');
		Paths.image('alphabet');

		if (PauseSubState.songName != null)
			Paths.music(PauseSubState.songName);
		else if (Paths.formatToSongPath(ClientPrefs.data.pauseMusic) != 'none')
			Paths.music(Paths.formatToSongPath(ClientPrefs.data.pauseMusic));

		resetRPC();

		setOnScripts('mania', SONG.mania);

		stagesFunc(function(stage:BaseStage) stage.createPost());
		
		callOnScripts('onCreatePost');

		cacheCountdown();

		super.create();

		callOnScripts('onCreateFinal');

		GCManager.enable(true);
		Paths.clearUnusedMemory(false);

		if (eventNotes.length < 1)
			checkEventNote();

		allowMinorGc = true;
	}

	function set_songSpeed(value:Float):Float
	{
		if (generatedMusic)
		{
			var ratio:Float = value / songSpeed; // funny word huh
			if (ratio != 1)
			{
				for (note in notes.members)
					note.resizeByRatio(ratio);
				for (note in unspawnNotes)
					note.resizeByRatio(ratio);
			}
		}
		songSpeed = value;
		noteKillOffset = Math.max(Conductor.stepCrochet, 350 / songSpeed * playbackRate);
		return value;
	}

	function set_playbackRate(value:Float):Float
	{
		#if FLX_PITCH
		if (generatedMusic)
		{
			vocals.pitch = value;
			opponentVocals.pitch = value;
			FlxG.sound.music.pitch = value;

			var ratio:Float = playbackRate / value; // funny word huh
			if (ratio != 1)
			{
				for (note in notes.members)
					note.resizeByRatio(ratio);
				for (note in unspawnNotes)
					note.resizeByRatio(ratio);
			}
		}
        playbackRate = value;
        FlxG.animationTimeScale = value;
        Conductor.safeZoneOffset = (ClientPrefs.data.safeFrames / 60) * 1000 * value;
        setOnScripts('playbackRate', playbackRate);
        if (timing != null) timing.setPrimaryRate(playbackRate);
        #else
        playbackRate = 1.0; // ensuring -Crow
        #end
        return playbackRate;
    }

	#if (LUA_ALLOWED || HSCRIPT_ALLOWED)
	public function addTextToDebug(text:String, color:FlxColor)
	{
		if (!ClientPrefs.data.developerMode) return;
		var newText:DebugLuaText = luaDebugGroup.recycle(DebugLuaText);
		newText.text = text;
		#if android
		newText.text = StringTools.replace(text, "/storage/emulated/0/.NovaFlare Engine/", ""); // delete stupid path
		#end
		newText.color = color;
		newText.disableTime = 6;
		newText.alpha = 1;
		newText.setPosition(10, 8 - newText.height);

		luaDebugGroup.forEachAlive(function(spr:DebugLuaText)
		{
			spr.y += newText.height + 2;
		});
		luaDebugGroup.add(newText);
		#if sys
		Sys.println(text);
		#else
		trace(text);
		#end
	}
	#end

	public function reloadHealthBarColors()
	{
		healthBar.setColors(FlxColor.fromRGB(dad.healthColorArray[0], dad.healthColorArray[1], dad.healthColorArray[2]),
			FlxColor.fromRGB(boyfriend.healthColorArray[0], boyfriend.healthColorArray[1], boyfriend.healthColorArray[2]));
	}

	public function addCharacterToList(newCharacter:String, type:Int)
	{
		switch (type)
		{
			case 0:
				if (!boyfriendMap.exists(newCharacter))
				{
					var newBoyfriend:Character = new Character(0, 0, newCharacter, true);
					boyfriendMap.set(newCharacter, newBoyfriend);
					boyfriendGroup.add(newBoyfriend);
					startCharacterPos(newBoyfriend);
					newBoyfriend.alpha = 0.00001;
					startCharacterScripts(newBoyfriend.curCharacter);
				}

			case 1:
				if (!dadMap.exists(newCharacter))
				{
					var newDad:Character = new Character(0, 0, newCharacter);
					dadMap.set(newCharacter, newDad);
					dadGroup.add(newDad);
					startCharacterPos(newDad, true);
					newDad.alpha = 0.00001;
					startCharacterScripts(newDad.curCharacter);
				}

			case 2:
				if (gf != null && !gfMap.exists(newCharacter))
				{
					var newGf:Character = new Character(0, 0, newCharacter);
					newGf.scrollFactor.set(0.95, 0.95);
					gfMap.set(newCharacter, newGf);
					gfGroup.add(newGf);
					startCharacterPos(newGf);
					newGf.alpha = 0.00001;
					startCharacterScripts(newGf.curCharacter);
				}
		}
	}

	function startCharacterScripts(name:String)
	{
		// Lua
		#if LUA_ALLOWED
		var doPush:Bool = false;
		var luaFile:String = 'characters/$name.lua';
		#if MODS_ALLOWED
		var replacePath:String = Paths.modFolders(luaFile);
		if (FileSystem.exists(replacePath))
		{
			luaFile = replacePath;
			doPush = true;
		}
		else
		{
			luaFile = Paths.getSharedPath(luaFile);
			if (FileSystem.exists(luaFile))
				doPush = true;
		}
		#else
		luaFile = Paths.getSharedPath(luaFile);
		if (Assets.exists(luaFile))
			doPush = true;
		#end

		if (doPush)
		{
			for (script in luaArray)
			{
				if (script.scriptName == luaFile)
				{
					doPush = false;
					break;
				}
			}
			if (doPush)
				new FunkinLua(luaFile);
		}
		#end

		// HScript
		#if HSCRIPT_ALLOWED
		var doPush:Bool = false;
		var scriptFile:String = 'characters/' + name + '.hx';
		#if MODS_ALLOWED
		var replacePath:String = Paths.modFolders(scriptFile);
		if (FileSystem.exists(replacePath))
		{
			scriptFile = replacePath;
			doPush = true;
		}
		else
		#end
		{
			scriptFile = Paths.getSharedPath(scriptFile);
			if (FileSystem.exists(scriptFile))
				doPush = true;
		}

		if (doPush)
		{
			if (HScript.instances.exists(scriptFile))
				doPush = false;

			if (doPush)
				initHScript(scriptFile);
		}
		#end
	}

	public function getLuaObject(tag:String, text:Bool = true):FlxSprite
	{
		#if LUA_ALLOWED
		if (modchartSprites.exists(tag))
			return modchartSprites.get(tag);
		if (text && modchartTexts.exists(tag))
			return modchartTexts.get(tag);
		if (variables.exists(tag))
			return variables.get(tag);
		#end
		return null;
	}

	function startCharacterPos(char:Character, ?gfCheck:Bool = false)
	{
		if (gfCheck && char.curCharacter.startsWith('gf'))
		{ // IF DAD IS GIRLFRIEND, HE GOES TO HER POSITION
			char.setPosition(GF_X, GF_Y);
			char.scrollFactor.set(0.95, 0.95);
			char.danceEveryNumBeats = 2;
		}
		char.x += char.positionArray[0];
		char.y += char.positionArray[1];
	}

	public var videoCutscene:VideoSprite = null;

	public function startVideo(name:String, forMidSong:Bool = false, canSkip:Bool = true, loop:Bool = false, playOnLoad:Bool = true)
	{
		#if VIDEOS_ALLOWED
		inCutscene = !forMidSong;
		canPause = forMidSong;

		var foundFile:Bool = false;
		var fileName:String = Paths.video(name);

		#if sys
		if (FileSystem.exists(fileName))
		#else
		if (OpenFlAssets.exists(fileName))
		#end
		foundFile = true;

		if (foundFile)
		{
			videoCutscene = new VideoSprite(fileName, forMidSong, canSkip, loop);

			// Finish callback
			if (!forMidSong)
			{
				function onVideoEnd()
				{
					if (!isDead && generatedMusic && PlayState.SONG.notes[Std.int(curStep / 16)] != null && !endingSong && !isCameraOnForcedPos)
					{
						moveCameraSection();
						FlxG.camera.snapToTarget();
					}
					videoCutscene = null;
					new FlxTimer().start(0.00001, function(tmr:FlxTimer)
					{
						canPause = true;
						inCutscene = false;
						startAndEnd();
					}, 1);
				}
				videoCutscene.finishCallback = onVideoEnd;
				videoCutscene.onSkip = onVideoEnd;
			}
			add(videoCutscene);

			if (playOnLoad)
				videoCutscene.videoSprite.play();
			return videoCutscene;
		}
		#if (LUA_ALLOWED || HSCRIPT_ALLOWED)
		else
			addTextToDebug("Video not found: " + fileName, FlxColor.RED);
		#else
		else
			FlxG.log.error("Video not found: " + fileName);
		#end
		#else
		FlxG.log.warn('Platform not supported!');
		startAndEnd();
		#end
		return null;
	}

	function startAndEnd()
	{
		if (endingSong)
			endSong();
		else
			startCountdown();
	}

	var dialogueCount:Int = 0;

	public var psychDialogue:DialogueBoxPsych;

	// You don't have to add a song, just saying. You can just do "startDialogue(DialogueBoxPsych.parseDialogue(Paths.json(songName + '/dialogue')))" and it should load dialogue.json
	public function startDialogue(dialogueFile:DialogueFile, ?song:String = null):Void
	{
		// TO DO: Make this more flexible, maybe?
		if (psychDialogue != null)
			return;

		if (dialogueFile.dialogue.length > 0)
		{
			inCutscene = true;
			psychDialogue = new DialogueBoxPsych(dialogueFile, song);
			psychDialogue.scrollFactor.set();
			if (endingSong)
			{
				psychDialogue.finishThing = function()
				{
					psychDialogue = null;
					endSong();
				}
			}
			else
			{
				psychDialogue.finishThing = function()
				{
					psychDialogue = null;
					startCountdown();
				}
			}
			psychDialogue.nextDialogueThing = startNextDialogue;
			psychDialogue.skipDialogueThing = skipDialogue;
			psychDialogue.cameras = [camHUD];
			add(psychDialogue);
		}
		else
		{
			FlxG.log.warn('Your dialogue file is badly formatted!');
			startAndEnd();
		}
	}

	var startTimer:FlxTimer;
	var finishTimer:FlxTimer = null;
    

	// For being able to mess with the sprites on Lua
	public var countdownReady:FlxSprite;
	public var countdownSet:FlxSprite;
	public var countdownGo:FlxSprite;

	public static var startOnTime:Float = 0;

	function cacheCountdown()
	{
		var introAssets:Map<String, Array<String>> = new Map<String, Array<String>>();
		var introImagesArray:Array<String> = switch (stageUI)
		{
			case "pixel": ['${stageUI}UI/ready-pixel', '${stageUI}UI/set-pixel', '${stageUI}UI/date-pixel'];
			case "normal": ["ready", "set", "go"];
			default: ['${stageUI}UI/ready', '${stageUI}UI/set', '${stageUI}UI/go'];
		}
		introAssets.set(stageUI, introImagesArray);
		var introAlts:Array<String> = introAssets.get(stageUI);
		for (asset in introAlts)
			Paths.image(asset);

		Paths.sound('intro3' + introSoundsSuffix);
		Paths.sound('intro2' + introSoundsSuffix);
		Paths.sound('intro1' + introSoundsSuffix);
		Paths.sound('introGo' + introSoundsSuffix);
	}

	//var funkin_modchart_instance:Manager;
	public function startCountdown()
	{
		if (ClientPrefs.data.pauseButton)
			pauseButton_menu.visible = true;

		if (startedCountdown)
		{
			callOnScripts('onStartCountdown');
			return false;
		}

		seenCutscene = true;
		inCutscene = false;
		var ret:Dynamic = callOnScripts('onStartCountdown', null, true);
		if (ret != LuaUtils.Function_Stop)
		{
			if (skipCountdown || startOnTime > 0) skipArrowStartTween = true;

			canPause = true;
			generateStaticArrows(0);
			generateStaticArrows(1);

			//funkin_modchart_instance = new Manager();
			//addManager(funkin_modchart_instance);

			for (i in 0...playerStrums.length)
			{
				setOnScripts('defaultPlayerStrumX' + i, playerStrums.members[i].x);
				setOnScripts('defaultPlayerStrumY' + i, playerStrums.members[i].y);
			}
			for (i in 0...opponentStrums.length)
			{
				setOnScripts('defaultOpponentStrumX' + i, opponentStrums.members[i].x);
				setOnScripts('defaultOpponentStrumY' + i, opponentStrums.members[i].y);
				// if(ClientPrefs.data.middleScroll) opponentStrums.members[i].visible = false;
			}

            startedCountdown = true;
            Conductor.songPosition = -Conductor.crochet * 5;

			setOnScripts('startedCountdown', true);
			callOnScripts('onCountdownStarted');

			var swagCounter:Int = 0;
			if (startOnTime > 0)
			{
				clearNotesBefore(startOnTime);
				setSongTime(startOnTime - 350);
				return true;
			}
			else if (skipCountdown)
			{
				setSongTime(0);
				return true;
			}
			moveCameraSection();

			
            //callOnHScript('onModChartStart', [modchart]);
            

			startTimer = new FlxTimer().start(Conductor.crochet / 1000 / playbackRate, function(tmr:FlxTimer)
			{
				characterBopper(tmr.loopsLeft);

				var introAssets:Map<String, Array<String>> = new Map<String, Array<String>>();
				var introImagesArray:Array<String> = switch (stageUI)
				{
					case "pixel": ['${stageUI}UI/ready-pixel', '${stageUI}UI/set-pixel', '${stageUI}UI/date-pixel'];
					case "normal": ["ready", "set", "go"];
					default: ['${stageUI}UI/ready', '${stageUI}UI/set', '${stageUI}UI/go'];
				}
				introAssets.set(stageUI, introImagesArray);

				var introAlts:Array<String> = introAssets.get(stageUI);
				var antialias:Bool = (ClientPrefs.data.antialiasing && !isPixelStage);
				var tick:Countdown = THREE;

				switch (swagCounter)
				{
					case 0:
						FlxG.sound.play(Paths.sound('intro3' + introSoundsSuffix), 0.6);
						tick = THREE;
					case 1:
						countdownReady = createCountdownSprite(introAlts[0], antialias);
						FlxG.sound.play(Paths.sound('intro2' + introSoundsSuffix), 0.6);
						tick = TWO;
					case 2:
						countdownSet = createCountdownSprite(introAlts[1], antialias);
						FlxG.sound.play(Paths.sound('intro1' + introSoundsSuffix), 0.6);
						tick = ONE;
					case 3:
						countdownGo = createCountdownSprite(introAlts[2], antialias);
						FlxG.sound.play(Paths.sound('introGo' + introSoundsSuffix), 0.6);
						tick = GO;
					case 4:
						tick = START;
				}

				if (notes.length > 0)
				{
					var len:Int = notes.length;
					var i:Int = 0;
					while (i < len)
					{
						var note:Note = cast notes.members[i];
						if (note != null && note.exists && note.alive)
						{
							if (ClientPrefs.data.opponentStrums || note.mustPress)
							{
								note.copyAlpha = false;
								note.alpha = note.multAlpha;
								if ((ClientPrefs.data.middleScroll && !note.mustPress && !ClientPrefs.data.playOpponent)
									|| (ClientPrefs.data.middleScroll && note.mustPress && ClientPrefs.data.playOpponent))
									note.alpha *= 0.35;
							}
						}
						i++;
					}
				}

				stagesFunc(function(stage:BaseStage) stage.countdownTick(tick, swagCounter));
				callOnLuas('onCountdownTick', [swagCounter]);
				callOnHScript('onCountdownTick', [tick, swagCounter]);

				swagCounter += 1;
			}, 5);
		}
		return true;
	}

	inline private function createCountdownSprite(image:String, antialias:Bool):FlxSprite
	{
		var spr:FlxSprite = new FlxSprite().loadGraphic(Paths.image(image));
		spr.cameras = [camHUD];
		spr.scrollFactor.set();
		spr.updateHitbox();

		if (PlayState.isPixelStage)
			spr.setGraphicSize(Std.int(spr.width * daPixelZoom));

		spr.screenCenter();
		spr.antialiasing = antialias;
		insert(members.indexOf(noteGroup), spr);
		FlxTween.tween(spr, {/*y: spr.y + 100,*/ alpha: 0}, Conductor.crochet / 1000, {
			ease: FlxEase.cubeInOut,
			onComplete: function(twn:FlxTween)
			{
				remove(spr);
				spr.destroy();
			}
		});
		return spr;
	}

	public function addBehindGF(obj:FlxBasic)
	{
		insert(members.indexOf(gfGroup), obj);
	}

	public function addBehindBF(obj:FlxBasic)
	{
		insert(members.indexOf(boyfriendGroup), obj);
	}

	public function addBehindDad(obj:FlxBasic)
	{
		insert(members.indexOf(dadGroup), obj);
	}
	
	public function addManager(obj:Manager)
	{
		if (obj.playfields == null || obj.playfields.length == 0)
			return;

		add(obj);
	}

	public function clearNotesBefore(time:Float)
	{
		var i:Int = unspawnNotes.length - 1;
		while (i >= 0)
		{
			var daNote:Note = unspawnNotes[i];
			if (daNote.strumTime - 350 < time)
			{
				daNote.active = false;
				daNote.visible = false;
				daNote.ignoreNote = true;

				if (!ClientPrefs.data.lowQuality || ClientPrefs.data.playOpponent ? !cpuControlled_opponent : !cpuControlled)
					daNote.kill();
				unspawnNotes.remove(daNote);
				daNote.destroy();
			}
			--i;
		}

		i = notes.length - 1;
		while (i >= 0)
		{
			var daNote:Note = notes.members[i];
			if (daNote.strumTime - 350 < time)
			{
				daNote.active = false;
				daNote.visible = false;
				daNote.ignoreNote = true;
				invalidateNote(daNote);
			}
			--i;
		}
	}

	// fun fact: Dynamic Functions can be overriden by just doing this
	// `updateScore = function(miss:Bool = false) { ... }
	// its like if it was a variable but its just a function!
	// cool right? -Crow
	public dynamic function updateScore(miss:Bool = false)
	{
		var ret:Dynamic = callOnScripts('preUpdateScore', [miss], true);
		if (ret == LuaUtils.Function_Stop)
			return;

		var str:String = ratingName;
		if (totalPlayed != 0)
		{
			var percent:Float = CoolUtil.floorDecimal(ratingPercent * 100, 2);
			str += ' (${percent}%) - ${ratingFC}';
		}

		scoreTxtUpdate();

		if (!miss && ClientPrefs.data.playOpponent ? !cpuControlled_opponent : !cpuControlled)
			doScoreBop();

		callOnScripts('onUpdateScore', [miss]);
	}

	public dynamic function fullComboFunction()
	{
		var sicks:Int = ratingsData[0].hits;
		var goods:Int = ratingsData[1].hits;
		var bads:Int = ratingsData[2].hits;
		var shits:Int = ratingsData[3].hits;
		var marvelous:Int = ClientPrefs.data.marvelousRating ? ratingsData[4].hits : 0;

		ratingFC = "";
		if (songMisses == 0)
		{
			if (bads > 0 || shits > 0)
				ratingFC = 'FC';
			else if (goods > 0)
				ratingFC = 'GFC';
			else if (sicks > 0)
				ratingFC = 'SFC';
			else if (marvelous > 0)
				ratingFC = 'MFC';
		}
		else
		{
			if (songMisses < 10)
				ratingFC = 'SDCB';
			else
				ratingFC = 'Clear';
		}
	}

	public function doScoreBop():Void
	{
		if (!ClientPrefs.data.scoreZoom)
			return;

		if (scoreTxtTween != null)
			scoreTxtTween.cancel();

		scoreTxt.scale.x = 1.075;
		scoreTxt.scale.y = 1.075;
		scoreTxtTween = FlxTween.tween(scoreTxt.scale, {x: 1, y: 1}, 0.2, {
			onComplete: function(twn:FlxTween)
			{
				scoreTxtTween = null;
			}
		});
	}

	public function setSongTime(time:Float)
	{
		if (time < 0)
			time = 0;

		FlxG.sound.music.pause();
		vocals.pause();
		opponentVocals.pause();
        if (videoCutscene != null)
        {
            videoCutscene.pause();
        };
        if (timing != null) timing.pause();

		FlxG.sound.music.time = time;
		#if FLX_PITCH FlxG.sound.music.pitch = playbackRate; #end
		FlxG.sound.music.play();

		#if FLX_PITCH
		vocals.pitch = playbackRate;
		opponentVocals.pitch = playbackRate;
		#end

		if (Conductor.songPosition <= vocals.length)
		{
			vocals.time = time;
			if (!vocals.playing) vocals.play();
		}
		else
		{
			vocals.stop();
		}

		if (Conductor.songPosition <= opponentVocals.length)
		{
			opponentVocals.time = time;
			if (!opponentVocals.playing) opponentVocals.play();
		}
		else
		{
			opponentVocals.stop();
		}
		if (videoCutscene != null)
		{
			videoCutscene.resume();
		};
		pausedTimePos = time;
        Conductor.songPosition = time;
        if (timing != null) {
			timing.setPosition(time);
		    timing.play();
		}
	}

	public function startNextDialogue()
	{
		dialogueCount++;
		callOnScripts('onNextDialogue', [dialogueCount]);
	}

	public function skipDialogue()
	{
		callOnScripts('onSkipDialogue', [dialogueCount]);
	}

	function startSong():Void
	{
		startingSong = false;
		GABridge.sendDesign("song:start", 1.0, {song: SONG.song.toLowerCase(), difficulty: Difficulty.getString(), storyMode: isStoryMode});

		@:privateAccess
		FlxG.sound.playMusic(inst._sound, 1, false);
		#if FLX_PITCH FlxG.sound.music.pitch = playbackRate; #end
		FlxG.sound.music.onComplete = () -> finishSong();
		vocals.play();
		opponentVocals.play();

		if (videoCutscene != null)
		{
			videoCutscene.resume();
		};

		if (startOnTime > 0)
			setSongTime(startOnTime - 500);
		startOnTime = 0;

		if (timing != null) {
			timing.setPosition(FlxG.sound.music.time);
			timing.play();
		}

		if (paused)
		{
			// trace('Oopsie doopsie! Paused sound');
			FlxG.sound.music.pause();
			vocals.pause();
			opponentVocals.pause();
			if (videoCutscene != null)
			{
				videoCutscene.pause();
			};
		}

		stagesFunc(function(stage:BaseStage) stage.startSong());

		// Song duration in a float, useful for the time left feature
		songLength = FlxG.sound.music.length;
		FlxTween.tween(timeBar, {alpha: 1}, 0.5, {ease: FlxEase.circOut});
		FlxTween.tween(timeTxt, {alpha: 1}, 0.5, {ease: FlxEase.circOut});

		#if DISCORD_ALLOWED
		// Updating Discord Rich Presence (with Time Left)
		if (autoUpdateRPC)
			DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter(), true, songLength);
		#end
		setOnScripts('songLength', songLength);
		callOnScripts('onSongStart');
	}

	var debugNum:Int = 0;
	private var noteTypes:Array<String> = [];
	private var eventsPushed:Array<String> = [];

	private function generateSong(dataPath:String):Void
	{
		// FlxG.log.add(ChartParser.parse());
		songSpeed = PlayState.SONG.speed;
		songSpeedType = ClientPrefs.getGameplaySetting('scrolltype');
		switch (songSpeedType)
		{
			case "multiplicative":
				songSpeed = SONG.speed * ClientPrefs.getGameplaySetting('scrollspeed');
			case "constant":
				songSpeed = ClientPrefs.getGameplaySetting('scrollspeed');
		}

		var songData = SONG;
		Conductor.bpm = songData.bpm;

		curSong = songData.song;

		vocals = new FlxSound();
		opponentVocals = new FlxSound();
		try
		{
			if (songData.needsVoices)
			{
				var playerVocals = Paths.voices(songData.song,
					(boyfriend.vocalsFile == null || boyfriend.vocalsFile.length < 1) ? 'Player' : boyfriend.vocalsFile);
				vocals.loadEmbedded(playerVocals != null ? playerVocals : Paths.voices(songData.song));

				var oppVocals = Paths.voices(songData.song, (dad.vocalsFile == null || dad.vocalsFile.length < 1) ? 'Opponent' : dad.vocalsFile);
				if (oppVocals != null)
				{
					opponentVocals.loadEmbedded(oppVocals);
					splitVocals = true;
				}
			}
		}
		catch (e:Dynamic)
		{
		}

		vocals.looped = opponentVocals.looped = false;

		#if FLX_PITCH
		vocals.pitch = playbackRate;
		opponentVocals.pitch = playbackRate;
		#end
		FlxG.sound.list.add(vocals);
		FlxG.sound.list.add(opponentVocals);

		inst = new FlxSound();
		try
		{
			inst.loadEmbedded(Paths.inst(songData.song));
		}
		catch (e:Dynamic)
		{
		}
		FlxG.sound.list.add(inst);

		@:privateAccess
		FlxG.sound.playMusic(inst._sound, 0, false);
		#if FLX_PITCH FlxG.sound.music.pitch = playbackRate; #end

		var vocalsVol:Float = vocals.volume;
		var opponentVocalsVol:Float = opponentVocals.volume;
		vocals.volume = 0;
		opponentVocals.volume = 0;

		vocals.play();
		opponentVocals.play();

		FlxG.sound.music.pause();
		vocals.pause();
		opponentVocals.pause();

		FlxG.sound.music.volume = 1;
		vocals.volume = vocalsVol;
		opponentVocals.volume = opponentVocalsVol;

		notes = new FlxTypedGroup<Note>();
		notes.active = true;
		notes.visible = false;
		//仅仅参加逻辑更新但是不参与渲染
		try
		{
			var eventsChart:SwagSong = Song.getChart('events', songName);
			if (eventsChart != null)
				for (event in eventsChart.events) // Event Notes
					for (i in 0...event[1].length)
						makeEvent(event, i);
		}
		catch (e:Dynamic)
		{
		}

		Note.init(instance);

		for (section in songData.notes)
		{
			for (songNotes in section.sectionNotes)
			{
				var daStrumTime:Float = songNotes[0];
				var daNoteData:Int = Std.int(songNotes[1] % (SONG.mania + 1));
				var gottaHitNote:Bool;

				var isPe104:Bool = (Song.chartEngineVersion == 'Pe-1.0.4');
				if (isPe104)
				{
					// Pe-1.0.4: lanes 0..mania = player, mania+1.. = opponent (no mustHitSection flip)
					gottaHitNote = (songNotes[1] < (SONG.mania + 1));
				}
				else
				{
					// Pe-0.7.3: mustHitSection determines base side, flipped for opponent-lane notes
					gottaHitNote = section.mustHitSection;
					if (songNotes[1] > SONG.mania)
						gottaHitNote = !section.mustHitSection;
				}

				if (ClientPrefs.data.flipChart)
					daNoteData -= Std.int((daNoteData - 1.5) * 2);

				var oldNote:Note;
				if (unspawnNotes.length > 0)
					oldNote = unspawnNotes[Std.int(unspawnNotes.length - 1)];
				else
					oldNote = null;

				var swagNote:Note = new Note(daStrumTime, daNoteData, oldNote);
				swagNote.mustPress = gottaHitNote;
				swagNote.sustainLength = songNotes[2];

				if (isPe104)
					swagNote.gfNote = (section.gfSection && gottaHitNote == section.mustHitSection);
				else
					swagNote.gfNote = (section.gfSection && (songNotes[1] < (SONG.mania + 1)));
				// Older Psych charts omit the fourth note entry for the default
				// note type.  The chart editor already normalizes that legacy form
				// to noteTypeList[0] (the empty string); gameplay must do the same.
				// Leaving it as null makes Lua receive nil, so scripts which route
				// ordinary and custom opponent notes with `noteType == ''` silently
				// disable one character's animations (Dual Demise is a real case).
				var rawNoteType:Dynamic = songNotes[3];
				if (Std.isOfType(rawNoteType, String))
					swagNote.noteType = rawNoteType;
				else
				{
					swagNote.noteType = ChartingState.noteTypeList[rawNoteType];
					if (swagNote.noteType == null)
						swagNote.noteType = '';
				}

				swagNote.scrollFactor.set();

				unspawnNotes.push(swagNote);

				final susLength:Float = swagNote.sustainLength / Conductor.stepCrochet;
				final floorSus:Int = Math.floor(susLength) - ClientPrefs.data.fixLNL;

				if (floorSus > 0)
				{
					for (susNote in 0...floorSus + 1)
					{
						oldNote = unspawnNotes[Std.int(unspawnNotes.length - 1)];

						var sustainNote:Note = new Note(daStrumTime + (Conductor.stepCrochet * susNote), daNoteData, oldNote, true);
						sustainNote.hitMultUpdate(susNote, floorSus);
						sustainNote.mustPress = gottaHitNote;
						sustainNote.gfNote = (section.gfSection && (songNotes[1]<(SONG.mania + 1)));
						sustainNote.noteType = swagNote.noteType;
						sustainNote.scrollFactor.set();
						sustainNote.parent = swagNote;
						unspawnNotes.push(sustainNote);
						swagNote.tail.push(sustainNote);

						sustainNote.correctionOffset = swagNote.height / 2;
						if (!PlayState.isPixelStage)
						{
							if (oldNote.isSustainNote)
							{
								oldNote.scale.y *= Note.SUSTAIN_SIZE / oldNote.frameHeight;
								oldNote.scale.y /= playbackRate;
								oldNote.updateHitbox();
							}

							if (ClientPrefs.data.downScroll)
								sustainNote.correctionOffset = 0;
						}
						else if (oldNote.isSustainNote)
						{
							oldNote.scale.y /= playbackRate;
							oldNote.updateHitbox();
						}

						if (sustainNote.mustPress)
							sustainNote.x += FlxG.width / 2; // general offset
						else if (ClientPrefs.data.middleScroll)
						{
							sustainNote.x += 310;
							if (daNoteData > 1) // Up and Right
								sustainNote.x += FlxG.width / 2 + 25;
						}
					}
				}

				//trace('work5');

				if (swagNote.mustPress)
				{
					swagNote.x += FlxG.width / 2; // general offset
				}
				else if (ClientPrefs.data.middleScroll)
				{
					swagNote.x += 310;
					if (daNoteData > 1) // Up and Right
					{
						swagNote.x += FlxG.width / 2 + 25;
					}
				}

				if (!noteTypes.contains(swagNote.noteType))
				{
					noteTypes.push(swagNote.noteType);
				}
			}
		}
		for (event in songData.events) // Event Notes
			for (i in 0...event[1].length)
				makeEvent(event, i);

		unspawnNotes.sort(sortByTime);

		generatedMusic = true;
	}

	// called only once per different event (Used for precaching)
	function eventPushed(event:EventNote)
	{
		eventPushedUnique(event);
		if (eventsPushed.contains(event.event))
		{
			return;
		}

		stagesFunc(function(stage:BaseStage) stage.eventPushed(event));
		eventsPushed.push(event.event);
	}

	// called by every event with the same name
	function eventPushedUnique(event:EventNote)
	{
		switch (event.event)
		{
			case "Change Character":
				var charType:Int = 0;
				switch (event.value1.toLowerCase())
				{
					case 'gf' | 'girlfriend':
						charType = 2;
					case 'dad' | 'opponent':
						charType = 1;
					default:
						var val1:Int = Std.parseInt(event.value1);
						if (Math.isNaN(val1))
							val1 = 0;
						charType = val1;
				}

				var newCharacter:String = event.value2;
				addCharacterToList(newCharacter, charType);

			case 'Play Sound':
				Paths.sound(event.value1); // Precache sound
		}
		stagesFunc(function(stage:BaseStage) stage.eventPushedUnique(event));
	}

	function eventEarlyTrigger(event:EventNote):Float
	{
		var returnedValue:Null<Float> = callOnScripts('eventEarlyTrigger', [event.event, event.value1, event.value2, event.strumTime], true, [], [0]);
		if (returnedValue != null && returnedValue != 0 && returnedValue != LuaUtils.Function_Continue)
		{
			return returnedValue;
		}

		switch (event.event)
		{
			case 'Kill Henchmen': // Better timing so that the kill sound matches the beat intended
				return 280; // Plays 280ms before the actual position
		}
		return 0;
	}

	public static function sortByTime(Obj1:Dynamic, Obj2:Dynamic):Int
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1.strumTime, Obj2.strumTime);

	function makeEvent(event:Array<Dynamic>, i:Int)
	{
		var subEvent:EventNote = {
			strumTime: event[0] + ClientPrefs.data.noteOffset,
			event: event[1][i][0],
			value1: event[1][i][1],
			value2: event[1][i][2]
		};
		eventNotes.push(subEvent);
		eventPushed(subEvent);
		callOnScripts('onEventPushed', [
			subEvent.event,
			subEvent.value1 != null ? subEvent.value1 : '',
			subEvent.value2 != null ? subEvent.value2 : '',
			subEvent.strumTime
		]);
	}

	#if CUSTOM_SHADERS_ALLOWED
	public function addShaderToObject(obj:String, effect:CustomShaderFilter)
	{
		if (obj == '')
		{
			@:privateAccess
			var curCamFilters:Array<BitmapFilter> = FlxG.game._filters;
			if (curCamFilters == null || curCamFilters.length == 0)
			{
				FlxG.game.setFilters([effect]);
				return;
			}
			curCamFilters.push(effect);
			FlxG.game.setFilters(curCamFilters);
			FlxG.game.filtersEnabled = ClientPrefs.data.shaders;
		}
		else
		{
			var camera:FlxCamera = LuaUtils.cameraFromString(obj);
			if (camera == null || (!obj.toLowerCase().contains('game') && camera == camGame))
			{
				if (Reflect.fields(this).contains(obj) && Std.isOfType(Reflect.field(this, obj), FlxSprite))
				{
					var gameObject = Reflect.field(this, obj);
					gameObject.shader = effect.shader;
					return;
				}
				var luaObject:FlxSprite = getLuaObject(obj);
				if (luaObject == null)
				{
					addTextToDebug('add shader function: NO OBJECT WITH A TAG OF \"$obj\" EXIST', FlxColor.RED);
					return;
				}
				luaObject.shader = effect.shader;
				return;
			}
			var curCamFilters:Array<BitmapFilter> = camera.filters;
			if (curCamFilters == null || curCamFilters.length == 0)
			{
				camera.filters = [effect];
				return;
			}
			curCamFilters.push(effect);
			camera.filters = curCamFilters;
			camera.filtersEnabled = ClientPrefs.data.shaders;
		}
	}

	public function removeShaderFromCamera(cam:String, effect:Dynamic)
	{
		var camera:Dynamic = (cam == '' ? FlxG.game : LuaUtils.cameraFromString(cam));
		if (camera == null)
		{
			addTextToDebug('shader remove function: ERROR THE CAMERA $cam DOES NOT EXIST', FlxColor.RED);
			return;
		}

		var filter:BitmapFilter = null;
		if (effect != null)
		{
			if (Std.isOfType(effect, BitmapFilter))
				filter = cast effect;
			else if (Reflect.hasField(effect, 'daShader'))
			{
				var daShader = Reflect.field(effect, 'daShader');
				if (Std.isOfType(daShader, BitmapFilter))
					filter = cast daShader;
			}
		}
		if (filter == null)
			return;

		if (cam == '')
		{
			@:privateAccess
			var curCamFilters:Array<BitmapFilter> = FlxG.game._filters;
			if (curCamFilters != null && curCamFilters.contains(filter))
			{
				curCamFilters.remove(filter);
				FlxG.game.setFilters(curCamFilters);
				FlxG.game.filtersEnabled = ClientPrefs.data.shaders;
			}
			return;
		}

		var flxCam:FlxCamera = cast camera;
		var curFilters:Array<BitmapFilter> = flxCam.filters;
		if (curFilters != null && curFilters.contains(filter))
		{
			curFilters.remove(filter);
			flxCam.filters = curFilters;
			flxCam.filtersEnabled = ClientPrefs.data.shaders;
		}
	}

	public function clearObjectShaders(obj:String)
	{
		if (obj == '')
		{
			FlxG.game.setFilters([]);
			FlxG.game.filtersEnabled = ClientPrefs.data.shaders;
		}
		else
		{
			var camera:FlxCamera = LuaUtils.cameraFromString(obj);
			if (camera == null || (!obj.toLowerCase().contains('game') && camera == camGame))
			{
				if (Reflect.fields(this).contains(obj) && Std.isOfType(Reflect.field(this, obj), FlxSprite))
				{
					var gameObject = Reflect.field(this, obj);
					gameObject.shader = null;
					return;
				}
				var luaObject:FlxSprite = getLuaObject(obj);
				if (luaObject == null)
				{
					addTextToDebug('shaders clear function: NO OBJECT WITH A TAG OF \"$obj\" EXIST', FlxColor.RED);
					return;
				}
				luaObject.shader = null;
				return;
			}
			camera.filters = [];
			camera.filtersEnabled = ClientPrefs.data.shaders;
		}
	}
	#end

	public var skipArrowStartTween:Bool = false; // for lua

	private function generateStaticArrows(player:Int):Void
	{
		var strumLineX:Float = ClientPrefs.data.middleScroll ? STRUM_X_MIDDLESCROLL : STRUM_X;
		var strumLineY:Float = ClientPrefs.data.downScroll ? (FlxG.height - 150) : 50;
		for (i in 0...PlayState.SONG.mania + 1)
		{
			// FlxG.log.add(i);
			var targetAlpha:Float = 1;
			if (!ClientPrefs.data.playOpponent)
			{
				if (player == 0)
				{
					if (!ClientPrefs.data.opponentStrums)
						targetAlpha = 0;
					else if (ClientPrefs.data.middleScroll)
						targetAlpha = 0.35;
				}
			}
			else
			{
				if (player == 1)
				{
					if (!ClientPrefs.data.opponentStrums)
						targetAlpha = 0;
					else if (ClientPrefs.data.middleScroll)
						targetAlpha = 0.35;
				}
			}

			var babyArrow:StrumNote = new StrumNote(strumLineX, strumLineY, i, player);
			babyArrow.downScroll = ClientPrefs.data.downScroll;
			if (!isStoryMode && !skipArrowStartTween)
			{
				// babyArrow.y -= 10;
				babyArrow.alpha = 0;
				FlxTween.tween(babyArrow, {/*y: babyArrow.y + 10,*/ alpha: targetAlpha}, 1, {ease: FlxEase.circOut, startDelay: 0.5 + (0.2 * i)});
			}
			else
				babyArrow.alpha = targetAlpha;

			if (player == 1)
			{
				if (ClientPrefs.data.middleScroll && ClientPrefs.data.playOpponent)
				{
					babyArrow.x += 310;
					babyArrow.x -= FlxG.width / 2;
					if (i > 1)
					{ // Up and Right
						babyArrow.x += FlxG.width / 2 + 25;
					}
				}
				playerStrums.add(babyArrow);
			}
			else
			{
				if (ClientPrefs.data.middleScroll && !ClientPrefs.data.playOpponent)
				{
					babyArrow.x += 310;
					if (i > 1)
					{ // Up and Right
						babyArrow.x += FlxG.width / 2 + 25;
					}
				}
				if (ClientPrefs.data.middleScroll && ClientPrefs.data.playOpponent)
				{
					babyArrow.x += FlxG.width / 2;
				}
				opponentStrums.add(babyArrow);
			}

			strumLineNotes.add(babyArrow);
			babyArrow.postAddedToGroup();
		}
		adaptStrumline(opponentStrums);
		adaptStrumline(playerStrums);

		if (ClientPrefs.data.showKeybinds)
		{
			for (i in 0...playerStrums.members.length)
			{
				var keyShowcase = new KeybindShowcase(playerStrums.members[i].x,
					ClientPrefs.data.downScroll ? playerStrums.members[i].y - 30 : playerStrums.members[i].y + playerStrums.members[i].height + 5,
					ClientPrefs.keyBinds.get(keysArray[i]), camHUD, playerStrums.members[i].width / 2, SONG.mania);
				keyShowcase.onComplete = function()
				{
					remove(keyShowcase);
				}
				add(keyShowcase);
			}
		}
	}

	public function adaptStrumline(strumline:FlxTypedGroup<StrumNote>)
	{
		var strumLineWidth:Float = 0;
		var strumLineIsBig:Bool = false;

		for (note in strumline.members)
			strumLineWidth += note.width;
		strumLineIsBig = strumLineWidth > StrumBoundaries.getBoundaryWidth().x;

		while (strumLineIsBig)
		{
			strumLineWidth = 0;
			for (note in strumline.members)
			{
				note.retryBound();
				strumLineWidth += note.width;
			}
			trace('Strumline is too big! Shrinking and retrying.');
			strumLineIsBig = strumLineWidth > StrumBoundaries.getBoundaryWidth().x;
		}
	}

	override function openSubState(SubState:FlxSubState)
	{
		stagesFunc(function(stage:BaseStage) stage.openSubState(SubState));
		if (paused)
		{
			if (FlxG.sound.music != null)
			{
				FlxG.sound.music.pause();
				vocals.pause();
				opponentVocals.pause();
				if (videoCutscene != null)
				{
					videoCutscene.pause();
				};
			}
			FlxTimer.globalManager.forEach(function(tmr:FlxTimer) if (!tmr.finished)
				tmr.active = false);
			FlxTween.globalManager.forEach(function(twn:FlxTween) if (!twn.finished)
				twn.active = false);
		}

		super.openSubState(SubState);
	}

	override function closeSubState()
	{
		stagesFunc(function(stage:BaseStage) stage.closeSubState());

		super.closeSubState();

		if (paused)
		{
			persistentUpdate = true;
			persistentDraw = true;
			if (FlxG.sound.music != null && !startingSong)
				resyncVocals(true, pausedTimePos);

			FlxTimer.globalManager.forEach(function(tmr:FlxTimer) if (!tmr.finished)
				tmr.active = true);
			FlxTween.globalManager.forEach(function(twn:FlxTween) if (!twn.finished)
				twn.active = true);

			paused = false;
			if (timing != null) timing.resume();
			if (mobileControls != null)
				mobileControls.visible = true;
			callOnScripts('onResume');
			resetRPC(startTimer != null && startTimer.finished);

			for (key in 0...keyboardViewer.keys) {
				if (!Controls.instance.pressed(keysArray[key])) {
					keyboardViewer.released(key);
					
					var spr:StrumNote = ClientPrefs.data.playOpponent ? opponentStrums.members[key] : playerStrums.members[key];
					if (spr != null)
					{
						spr.playAnim('static');
						spr.resetAnim = 0;
					}
				}
			}
			if (replayMode) @:privateAccess replayExam.blockKeys();
		}
	}

	override public function onFocus():Void
	{
		callOnScripts('onFocus');
		if (health > 0 && !paused)
			resetRPC(Conductor.songPosition > 0.0);
		if (timing != null) timing.onFocus();
		super.onFocus();
		callOnScripts('onFocusPost');
	}

	override public function onFocusLost():Void
	{
		callOnScripts('onFocusLost');
		#if DISCORD_ALLOWED
		if (health > 0 && !paused && autoUpdateRPC)
			DiscordClient.changePresence(detailsPausedText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter());

		if (FlxG.autoPause && startedCountdown && !paused && canPause)
		{
			var ret:Dynamic = callOnScripts('onPause', null, true);

			if (ret != LuaUtils.Function_Stop)
			{
				openPauseMenu();
			}
		}
		#end

		if (timing != null) timing.onFocusLost();
		super.onFocusLost();
		callOnScripts('onFocusLostPost');
	}

	// Updating Discord Rich Presence.
	public var autoUpdateRPC:Bool = true; // performance setting for custom RPC things

	function resetRPC(?showTime:Bool = false)
	{
		#if DISCORD_ALLOWED
		if (!autoUpdateRPC)
			return;

		if (showTime)
			DiscordClient.changePresence(detailsText, SONG.song
				+ " ("
				+ storyDifficultyText
				+ ")", iconP2.getCharacter(), true,
				songLength
				- Conductor.songPosition
				- ClientPrefs.data.noteOffset);
		else
			DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter());
		#end
	}

	function resyncVocals(?fixVocals:Bool = false, ?fixTime:Float):Void
	{
		if (finishTimer != null)
			return;
		
		if (fixVocals == null)
			fixVocals = false;

		if (ClientPrefs.data.developerMode) trace('resynced vocals at ' + Math.floor(Conductor.songPosition));
		fixDesyncedStep = 0;
		checkIfDesynced = false;
		lastDesyncCheckTime = Lib.getTimer();

		FlxG.sound.music.play();
		#if FLX_PITCH FlxG.sound.music.pitch = playbackRate; #end
		if (fixVocals && fixTime != null)
			FlxG.sound.music.time = Std.int(fixTime);
        Conductor.songPosition = FlxG.sound.music.time;
        if (timing != null) timing.setPosition(Conductor.songPosition);

		if (Conductor.songPosition <= vocals.length)
		{
			if (fixVocals)
				vocals.time = Conductor.songPosition;
			#if FLX_PITCH vocals.pitch = playbackRate; #end
		}

		if (Conductor.songPosition <= opponentVocals.length)
		{
			if (fixVocals)
				opponentVocals.time = Conductor.songPosition;
			#if FLX_PITCH opponentVocals.pitch = playbackRate; #end
		}
		vocals.play();
		opponentVocals.play();
		if (videoCutscene != null)
		{
			videoCutscene.resume();
		};
	}

	public var fixDesyncedStep:Int = 0;
	var lastDesyncCheckTime:Float = -1000;

	function musicCheck(music:FlxSound, getTime:Float, deviation:Float):Bool
	{
		if (music == null)
			return false;
		if (music.length > 0) {
			if (getTime > music.length) return false;
			if (Math.abs(music.time - getTime) > deviation) return true;
		}
		return false;
	}

	public var paused:Bool = false;
	public var canReset:Bool = true;

	var startedCountdown:Bool = false;
	var canPause:Bool = true;
	var freezeCamera:Bool = false;
	var allowDebugKeys:Bool = true;
	var pressPaue:Int = 0;

	public var pausedTimePos:Float = 0;

	override function handleInput(elapsed:Float)
	{
		if (startedCountdown && !paused)
        {
            if (Conductor.songPosition < 0)
                Conductor.songPosition += elapsed * 1000 * playbackRate;
            else if (timing != null && (timing.isPlaying || timing.tickEnabled))
                Conductor.songPosition = timing.getPositionMs();
            var desyncCheckTime:Float = Lib.getTimer();
            if (checkIfDesynced && Conductor.songPosition >= 0 &&
                desyncCheckTime - lastDesyncCheckTime >= 200)
                {
				lastDesyncCheckTime = desyncCheckTime;
				checkIfDesynced = false;
                var diff:Float = 50 * playbackRate; // 0.05秒的音乐延迟偏差
                var timeSub:Float = Conductor.songPosition - Conductor.offset;
				diff = 80 * playbackRate;

				if (Math.abs(FlxG.sound.music.time - timeSub) > diff
					|| musicCheck(vocals, timeSub, diff)
					|| (splitVocals && musicCheck(opponentVocals, timeSub, diff)))
				{
					if (++fixDesyncedStep >= 3)
					{
						resyncVocals(true);
					}
				}
				else
					fixDesyncedStep = 0;
			}
		}
		
		super.handleInput(elapsed);
	}

	override function update(elapsed:Float)
	{
		if (ClientPrefs.data.pauseButton)
		{
			var Pressed:Bool = (pauseButton_menu != null && pauseButton_menu.touchJustPressed(camPause));

			if (Pressed && (startedCountdown && canPause))
			{
				var ret:Dynamic = callOnScripts('onPause', null, true);
				if (ret != LuaUtils.Function_Stop)
				{
					openPauseMenu();
					super.update(elapsed);
					return;
				}
				else if (ret == LuaUtils.Function_Stop && ClientPrefs.data.compulsionPause)
				{
					if (pressPaue < ClientPrefs.data.compulsionPauseNumber)
					{
						pressPaue++;
					}
					else
					{
						pressPaue = 0;
						openPauseMenu();
						super.update(elapsed);
						return;
					}
				}
			}
		}

		if (!inCutscene && !paused && !freezeCamera)
		{
			FlxG.camera.followLerp = 2.4 * cameraSpeed * playbackRate;
			if (!startingSong && !endingSong && boyfriend.getAnimationName().startsWith('idle'))
			{
				boyfriendIdleTime += elapsed;
				if (boyfriendIdleTime >= 0.15)
				{ // Kind of a mercy thing for making the achievement easier to get as it's apparently frustrating to some playerss
					boyfriendIdled = true;
				}
			}
			else
			{
				boyfriendIdleTime = 0;
			}
		}
		else
			FlxG.camera.followLerp = 0;
		onUpdateArgs[0] = elapsed;
		callOnScripts('onUpdate', onUpdateArgs);

		super.update(elapsed);

		setOnScripts('curDecStep', curDecStep);
		setOnScripts('curDecBeat', curDecBeat);

		if (botplayTxt != null && botplayTxt.visible)
		{
			txtSine += 180 * elapsed;
			botplayTxt.alpha = 1 - Math.sin((Math.PI * txtSine) / 180);
		}

		if (replayTxt != null && replayTxt.visible)
		{
			txtSine += 180 * elapsed;
			replayTxt.alpha = 1 - Math.cos((Math.PI * txtSine) / 180);
		}

		if ((controls.PAUSE #if android || FlxG.android.justReleased.BACK #end) && (startedCountdown && canPause))
		{
			var ret:Dynamic = callOnScripts('onPause', null, true);
			if (ret != LuaUtils.Function_Stop)
			{
				openPauseMenu();
			}
		}

		if (!endingSong && !inCutscene && allowDebugKeys)
		{
			if (controls.justPressed('debug_1'))
				openChartEditor();
			else if (controls.justPressed('debug_2'))
				openCharacterEditor();
			#if debug
			//else if (controls.justPressed('debug_3'))
				//runAddBenchmarkSynthetic(2000);
			#end
		}

		if (healthBar.bounds.max != null && health > healthBar.bounds.max)
			health = healthBar.bounds.max;

		updateIconsScale(elapsed);
		updateIconsPosition();

		if (startingSong)
		{
            if (startedCountdown && Conductor.songPosition >= 0)
                startSong();
            else if (!startedCountdown)
                Conductor.songPosition = -Conductor.crochet * 5;
        }
		else if (!paused && updateTime)
		{
			var curTime:Float = Math.max(0, Conductor.songPosition - ClientPrefs.data.noteOffset); //待修改
			songPercent = (curTime / songLength);

			var songCalc:Float = (songLength - curTime);
			if (ClientPrefs.data.timeBarType == 'Time Elapsed')
				songCalc = curTime;

			var secondsTotal:Int = Math.floor(songCalc / 1000);
			if (secondsTotal < 0)
				secondsTotal = 0;

			if (ClientPrefs.data.timeBarType != 'Song Name')
				timeTxt.text = FlxStringUtil.formatTime(secondsTotal, false);
		}

		FlxG.watch.addQuick("secShit", curSection);
		FlxG.watch.addQuick("beatShit", curBeat);
		FlxG.watch.addQuick("stepShit", curStep);

		// RESET = Quick Game Over Screen
		if (!ClientPrefs.data.noReset && controls.RESET && canReset && !inCutscene && startedCountdown && !endingSong)
		{
			health = 0;
			trace("RESET = True");
		}
		doDeathCheck();

		var songPosForNotes:Float = replayMode ? @:privateAccess replayExam.time : Conductor.songPosition;
		if (unspawnNotes[0] != null)
		{
			var time:Float = spawnTime * playbackRate;
			if (songSpeed < 1)
				time /= songSpeed;
			if (unspawnNotes[0].multSpeed < 1)
				time /= unspawnNotes[0].multSpeed;
			var spawnCount:Int = 0;
			var lenUnspawn:Int = unspawnNotes.length;
			while (spawnCount < lenUnspawn && unspawnNotes[spawnCount].strumTime - songPosForNotes < time)
			{
				spawnCount++;
			}
			if (spawnCount > 0)
			{
				var k:Int = 0;
				while (k < spawnCount)
				{
					var dunceNote:Note = unspawnNotes[k];
					addNoteInternal(dunceNote);
					k++;
				}
				unspawnNotes.splice(0, spawnCount);
			}
		}

		if (generatedMusic)
		{
			if (!inCutscene)
			{
				if (!replayMode) {
					if (ClientPrefs.data.playOpponent ? !cpuControlled_opponent : !cpuControlled)
						keysCheck();
					else
						ClientPrefs.data.playOpponent ? opponentDance() : playerDance();
				}

				if (notes.length > 0)
				{
					if (startedCountdown)
					{
						var fakeCrochet:Float = (60 / SONG.bpm) * 1000;
						var len:Int = notes.length;
						var i:Int = 0;
						while (i < len)
						{
							var daNote:Note = cast notes.members[i];
							if (daNote != null && daNote.exists && daNote.alive)
							{
								var strumGroup:FlxTypedGroup<StrumNote> = daNote.mustPress ? playerStrums : opponentStrums;
								var strum:StrumNote = strumGroup.members[daNote.noteData];
								daNote.followStrumNote(strum, fakeCrochet, songSpeed / playbackRate);
								if (daNote.mustPress)
								{
									if (!ClientPrefs.data.playOpponent)
									{
										var canBeHitAt:Bool = replayMode ? (daNote.strumTime > songPosForNotes - (Conductor.safeZoneOffset * daNote.lateHitMult)
											&& daNote.strumTime < songPosForNotes + (Conductor.safeZoneOffset * daNote.earlyHitMult)) : daNote.canBeHit;
										if (cpuControlled && !daNote.blockHit && canBeHitAt && (daNote.isSustainNote || daNote.strumTime <= songPosForNotes))
											goodNoteHit(daNote);
									}
									else
									{
										if (daNote.wasGoodHit && !daNote.hitByOpponent && !daNote.ignoreNote)
											goodNoteHitForOpponent(daNote);
									}
								}
								else
								{
									if (!ClientPrefs.data.playOpponent)
									{
										if (daNote.wasGoodHit && !daNote.hitByOpponent && !daNote.ignoreNote)
											opponentNoteHit(daNote);
									}
									else
									{
										var canBeHitAt:Bool = replayMode ? (daNote.strumTime > songPosForNotes - (Conductor.safeZoneOffset * daNote.lateHitMult)
											&& daNote.strumTime < songPosForNotes + (Conductor.safeZoneOffset * daNote.earlyHitMult)) : daNote.canBeHit;
										if (cpuControlled_opponent && !daNote.blockHit && canBeHitAt && (daNote.isSustainNote || daNote.strumTime <= songPosForNotes))
											opponentNoteHitForOpponent(daNote);
									}
								}
								if (daNote.isSustainNote && strum.sustainReduce) daNote.clipToStrumNote(strum);
								if (songPosForNotes - daNote.strumTime > noteKillOffset * 1.5)
									invalidateNote(daNote);
								else if (songPosForNotes - daNote.strumTime > noteKillOffset)
								{
									var tooLateAt:Bool = daNote.strumTime < songPosForNotes - Conductor.safeZoneOffset && !daNote.wasGoodHit;
									if (((!daNote.mustPress && !cpuControlled_opponent && ClientPrefs.data.playOpponent) || (daNote.mustPress && !cpuControlled && !ClientPrefs.data.playOpponent))
										&& !daNote.ignoreNote && !endingSong && (replayMode ? (tooLateAt || daNote.wasGoodHit == false) : (daNote.tooLate == true || daNote.wasGoodHit == false)) && !daNote.missed)
										noteMiss(daNote, i);
								}
							}
							i++;
						}
					}
					else
					{
						var len2:Int = notes.length;
						var j:Int = 0;
						while (j < len2)
						{
							var daNote2:Note = cast notes.members[j];
							if (daNote2 != null && daNote2.exists && daNote2.alive)
							{
								daNote2.canBeHit = false;
								daNote2.wasGoodHit = false;
							}
							j++;
						}
					}
				}
			}
			checkEventNote();
		}

		destroyNotes();

		#if debug
		if (!endingSong && !startingSong)
		{
			if (FlxG.keys.justPressed.ONE)
			{
				KillNotes();
				FlxG.sound.music.onComplete();
			}
			if (FlxG.keys.justPressed.TWO)
			{ // Go 10 seconds into the future :O
				setSongTime(Conductor.songPosition + 10000);
				clearNotesBefore(Conductor.songPosition);
			}
		}
		#end

		setOnScripts('cameraX', camFollow.x);
		setOnScripts('cameraY', camFollow.y);
		setOnScripts('botPlay', cpuControlled);
		#if CUSTOM_SHADERS_ALLOWED
		for (shaderUpdate in shaderUpdates)
			shaderUpdate(elapsed);
		#end

		nps = notesHitArray.length;
		if (nps > maxNPS)
			maxNPS = nps;

		setOnLuas('nps', nps);
		setOnLuas('maxFPS', maxNPS);

		if (npsCheck != nps)
		{
			npsCheck = nps;
			scoreTxtUpdate();
		}

		onUpdatePostArgs[0] = elapsed;
		callOnScripts('onUpdatePost', onUpdatePostArgs);
	}

	override function drawUpdate(elapsed:Float) {

		{
			var balls = notesHitArray.length - 1;
			while (balls >= 0)
			{
				var cock:Date = notesHitArray[balls];
				if (cock != null && cock.getTime() + 1000 < Date.now().getTime())
					notesHitArray.remove(cock);
				else
					balls = 0;
				balls--;
			}
		}

		if (camZooming)
		{
			FlxG.camera.zoom = FlxMath.lerp(defaultCamZoom, FlxG.camera.zoom, Math.exp(-elapsed * 3.125 * camZoomingDecay * playbackRate));
			camHUD.zoom = FlxMath.lerp(1, camHUD.zoom, Math.exp(-elapsed * 3.125 * camZoomingDecay * playbackRate));
		}
		
		super.drawUpdate(elapsed);
	}

	#if debug
    // 性能测试：合成基准，验证 addNoteInternal 的吞吐效率与事件兼容性
    // 说明：生成轻量的临时 Note，执行 add/remove 流程并销毁，不影响实际游戏状态
    public function runAddBenchmarkSynthetic(count:Int = 2000):Void
    {
        var t0:Float = Sys.time();
        var i:Int = 0;
        while (i < count)
        {
            var fake:Note = new Note(Conductor.songPosition, 0, null, (i & 1) == 1);
            addNoteInternal(fake);
            notes.remove(fake, false);
            if (fake.isSustainNote) sustainLayer.remove(fake, false); else tapLayer.remove(fake, false);
            fake.destroy();
            i++;
        }
        var t1:Float = Sys.time();
        var ms:Int = Std.int((t1 - t0) * 1000);
        trace('AddBenchmarkSynthetic: ' + count + ' notes in ' + ms + ' ms');
    }
	#end

	public function scoreTxtUpdate()
	{
		scoreTxt.text = "NPS: " + nps + " (Max: " + maxNPS + ")";

		if (ClientPrefs.data.playOpponent ? !cpuControlled_opponent : !cpuControlled)
		{
			scoreTxt.text += " | " + "Score: " + songScore + " | Misses: " + songMisses + " | Accuracy: " + Math.ceil(ratingPercent * 10000) / 100 + '%'
				+ " | ";

			if (ratingName == 'N/A')
			{
				scoreTxt.text += 'N/A';
			}
			else
			{
				scoreTxt.text += '(' + ratingFC + ') ' + ratingName;
			}
		}
	}

	// Health icon updaters
	public dynamic function updateIconsScale(elapsed:Float)
	{
		var mult:Float = FlxMath.lerp(1, iconP1.scale.x, FlxMath.bound((1 - (elapsed * 13 * playbackRate)), 0, 1));
		iconP1.scale.set(mult, mult);
		iconP1.updateHitbox();

		var mult:Float = FlxMath.lerp(1, iconP2.scale.x, FlxMath.bound((1 - (elapsed * 13 * playbackRate)), 0, 1));
		iconP2.scale.set(mult, mult);
		iconP2.updateHitbox();
	}

	public dynamic function updateIconsPosition()
	{
		var iconOffset:Int = 26;
		iconP1.x = healthBar.barCenter + (150 * iconP1.scale.x - 150) / 2 - iconOffset;
		iconP2.x = healthBar.barCenter - (150 * iconP2.scale.x) / 2 - iconOffset * 2;
	}

	var iconsAnimations:Bool = true;

	function set_health(value:Float):Float // You can alter how icon animations work here
	{
		if (!iconsAnimations || healthBar == null || !healthBar.enabled || healthBar.valueFunction == null)
		{
			health = value;
			return health;
		}

		// update health bar
		health = value;
		var newPercent:Null<Float> = health / 2 * 100;
		healthBar.percent = (newPercent != null ? newPercent : 0);

		if (healthBar.percent < 20) // losing
		{
			if (ClientPrefs.data.playOpponent)
			{
				iconP1.animation.curAnim.curFrame = iconP1.numFrames > 2 ? 2 : 0;
				iconP2.animation.curAnim.curFrame = 1;
			}
			else
			{
				iconP1.animation.curAnim.curFrame = 1;
				iconP2.animation.curAnim.curFrame = iconP2.numFrames > 2 ? 2 : 0;
			}
		}
		else if (healthBar.percent > 80) // winning
		{
			if (!ClientPrefs.data.playOpponent)
			{
				iconP1.animation.curAnim.curFrame = iconP1.numFrames > 2 ? 2 : 0;
				iconP2.animation.curAnim.curFrame = 1;
			}
			else
			{
				iconP1.animation.curAnim.curFrame = 1;
				iconP2.animation.curAnim.curFrame = iconP2.numFrames > 2 ? 2 : 0;
			}
		}
		else // neutral
		{
			iconP1.animation.curAnim.curFrame = 0;
			iconP2.animation.curAnim.curFrame = 0;
		}
		return health;
	}

	function openPauseMenu()
	{
		FlxG.camera.followLerp = 0;
		persistentUpdate = false;
		persistentDraw = true;
		paused = true;
		if (timing != null) timing.pause();
		pausedTimePos = Conductor.songPosition;

		keyboardViewer.save();

		if (FlxG.sound.music != null)
		{
			FlxG.sound.music.pause();
			vocals.pause();
			opponentVocals.pause();
		}
		if (videoCutscene != null)
		{
			videoCutscene.pause();
		};

		if (replayMode) @:privateAccess replayExam.unblockKeys();
		openSubState(new PauseSubState());

		#if DISCORD_ALLOWED
		if (autoUpdateRPC)
			DiscordClient.changePresence(detailsPausedText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter());
		#end
	}

	public function openChartEditor()
	{
		FlxG.camera.followLerp = 0;
		persistentUpdate = false;
		paused = true;
		if (FlxG.sound.music != null)
			FlxG.sound.music.stop();
		chartingMode = true;

		if (videoCutscene != null)
		{
			videoCutscene.pause();
		};

		#if DISCORD_ALLOWED
		DiscordClient.changePresence("Chart Editor", null, null, true);
		DiscordClient.resetClientID();
		#end

		MusicBeatState.switchState(new ChartingState());
	}

	function openCharacterEditor()
	{
		FlxG.camera.followLerp = 0;
		persistentUpdate = false;
		paused = true;
		if (FlxG.sound.music != null)
			FlxG.sound.music.stop();

		if (videoCutscene != null)
		{
			videoCutscene.pause();
		};
		#if DISCORD_ALLOWED DiscordClient.resetClientID(); #end
		MusicBeatState.switchState(new CharacterEditorState(SONG.player2));
	}

	public var isDead:Bool = false; // Don't mess with this on Lua!!!

	function doDeathCheck(?skipHealthCheck:Bool = false)
	{
		if (((skipHealthCheck && instakillOnMiss) || health <= 0) && !practiceMode && !isDead && !replayMode)
		{
			var ret:Dynamic = callOnScripts('onGameOver', null, true);
			if (ret != LuaUtils.Function_Stop)
			{
				FlxG.animationTimeScale = 1;
				boyfriend.stunned = true;
				deathCounter++;

				paused = true;

				vocals.stop();
				opponentVocals.stop();
				FlxG.sound.music.stop();
				if (videoCutscene != null)
				{
					videoCutscene.pause();
				};

				persistentUpdate = false;
				persistentDraw = false;
				FlxTimer.globalManager.clear();
				FlxTween.globalManager.clear();
				#if LUA_ALLOWED
				modchartTimers.clear();
				modchartTweens.clear();
				#end

				#if VIDEOS_ALLOWED
				// i assume it's better removing the thing on gameover
				#end

				openSubState(new GameOverSubstate());

				// MusicBeatState.switchState(new GameOverState(boyfriend.getScreenPosition().x, boyfriend.getScreenPosition().y));

				#if DISCORD_ALLOWED
				// Game Over doesn't get his its variable because it's only used here
				if (autoUpdateRPC)
					DiscordClient.changePresence("Game Over - " + detailsText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter());
				#end
				isDead = true;
				return true;
			}
		}
		return false;
	}

	public function checkEventNote()
	{
		while (eventNotes.length > 0)
		{
			var leStrumTime:Float = eventNotes[0].strumTime;
			if (Conductor.songPosition < leStrumTime)
			{
				return;
			}

			var value1:String = '';
			if (eventNotes[0].value1 != null)
				value1 = eventNotes[0].value1;

			var value2:String = '';
			if (eventNotes[0].value2 != null)
				value2 = eventNotes[0].value2;

			triggerEvent(eventNotes[0].event, value1, value2, leStrumTime);
			eventNotes.shift();
		}
	}

	public function triggerEvent(eventName:String, value1:String, value2:String, strumTime:Float)
	{
		var flValue1:Null<Float> = Std.parseFloat(value1);
		var flValue2:Null<Float> = Std.parseFloat(value2);
		if (Math.isNaN(flValue1))
			flValue1 = null;
		if (Math.isNaN(flValue2))
			flValue2 = null;

		switch (eventName)
		{
			case 'Hey!':
				var value:Int = 2;
				switch (value1.toLowerCase().trim())
				{
					case 'bf' | 'boyfriend' | '0':
						value = 0;
					case 'gf' | 'girlfriend' | '1':
						value = 1;
				}

				if (flValue2 == null || flValue2 <= 0)
					flValue2 = 0.6;

				if (value != 0)
				{
					if (dad.curCharacter.startsWith('gf'))
					{ // Tutorial GF is actually Dad! The GF is an imposter!! ding ding ding ding ding ding ding, dindinding, end my suffering
						dad.playAnim('cheer', true);
						dad.specialAnim = true;
						dad.heyTimer = flValue2;
					}
					else if (gf != null)
					{
						gf.playAnim('cheer', true);
						gf.specialAnim = true;
						gf.heyTimer = flValue2;
					}
				}
				if (value != 1)
				{
					boyfriend.playAnim('hey', true);
					boyfriend.specialAnim = true;
					boyfriend.heyTimer = flValue2;
				}

			case 'Set GF Speed':
				if (flValue1 == null || flValue1 < 1)
					flValue1 = 1;
				gfSpeed = Math.round(flValue1);

			case 'Add Camera Zoom':
				if (ClientPrefs.data.camZooms && FlxG.camera.zoom < 1.35)
				{
					if (flValue1 == null)
						flValue1 = 0.015;
					if (flValue2 == null)
						flValue2 = 0.03;

					FlxG.camera.zoom += flValue1;
					camHUD.zoom += flValue2;
				}

			case 'Play Animation':
				// trace('Anim to play: ' + value1);
				var char:Character = dad;
				switch (value2.toLowerCase().trim())
				{
					case 'bf' | 'boyfriend':
						char = boyfriend;
					case 'gf' | 'girlfriend':
						char = gf;
					default:
						if (flValue2 == null)
							flValue2 = 0;
						switch (Math.round(flValue2))
						{
							case 1: char = boyfriend;
							case 2: char = gf;
						}
				}

				if (char != null)
				{
					char.playAnim(value1, true);
					char.specialAnim = true;
				}

			case 'Camera Follow Pos':
				if (camFollow != null)
				{
					isCameraOnForcedPos = false;
					if (flValue1 != null || flValue2 != null)
					{
						isCameraOnForcedPos = true;
						if (flValue1 == null)
							flValue1 = 0;
						if (flValue2 == null)
							flValue2 = 0;
						camFollow.x = flValue1;
						camFollow.y = flValue2;
					}
				}

			case 'Alt Idle Animation':
				var char:Character = dad;
				switch (value1.toLowerCase().trim())
				{
					case 'gf' | 'girlfriend':
						char = gf;
					case 'boyfriend' | 'bf':
						char = boyfriend;
					default:
						var val:Int = Std.parseInt(value1);
						if (Math.isNaN(val))
							val = 0;

						switch (val)
						{
							case 1: char = boyfriend;
							case 2: char = gf;
						}
				}

				if (char != null)
				{
					char.idleSuffix = value2;
					char.recalculateDanceIdle();
				}

			case 'Screen Shake':
				var valuesArray:Array<String> = [value1, value2];
				var targetsArray:Array<FlxCamera> = [camGame, camHUD];
				for (i in 0...targetsArray.length)
				{
					var split:Array<String> = valuesArray[i].split(',');
					var duration:Float = 0;
					var intensity:Float = 0;
					if (split[0] != null)
						duration = Std.parseFloat(split[0].trim());
					if (split[1] != null)
						intensity = Std.parseFloat(split[1].trim());
					if (Math.isNaN(duration))
						duration = 0;
					if (Math.isNaN(intensity))
						intensity = 0;

					if (duration > 0 && intensity != 0)
					{
						targetsArray[i].shake(intensity, duration);
					}
				}

			case 'Change Character':
				var charType:Int = 0;
				switch (value1.toLowerCase().trim())
				{
					case 'gf' | 'girlfriend':
						charType = 2;
					case 'dad' | 'opponent':
						charType = 1;
					default:
						charType = Std.parseInt(value1);
						if (Math.isNaN(charType)) charType = 0;
				}

				switch (charType)
				{
					case 0:
						if (boyfriend.curCharacter != value2)
						{
							if (!boyfriendMap.exists(value2))
							{
								addCharacterToList(value2, charType);
							}

							var lastAlpha:Float = boyfriend.alpha;
							boyfriend.alpha = 0.00001;
							boyfriend.visible = false;
							boyfriend = boyfriendMap.get(value2);
							boyfriend.visible = true;
							boyfriend.alpha = lastAlpha;
							iconP1.changeIcon(boyfriend.healthIcon);
						}
						setOnScripts('boyfriendName', boyfriend.curCharacter);

					case 1:
						if (dad.curCharacter != value2)
						{
							if (!dadMap.exists(value2))
							{
								addCharacterToList(value2, charType);
							}

							var wasGf:Bool = dad.curCharacter.startsWith('gf-') || dad.curCharacter == 'gf';
							var lastAlpha:Float = dad.alpha;
							dad.alpha = 0.00001;
							dad.visible = false;
							dad = dadMap.get(value2);
							dad.visible = true;
							if (!dad.curCharacter.startsWith('gf-') && dad.curCharacter != 'gf')
							{
								if (wasGf && gf != null)
								{
									gf.visible = true;
								}
							}
							else if (gf != null)
							{
								gf.visible = false;
							}
							dad.alpha = lastAlpha;
							iconP2.changeIcon(dad.healthIcon);
						}
						setOnScripts('dadName', dad.curCharacter);

					case 2:
						if (gf != null)
						{
							if (gf.curCharacter != value2)
							{
								if (!gfMap.exists(value2))
								{
									addCharacterToList(value2, charType);
								}

								var lastAlpha:Float = gf.alpha;
								gf.alpha = 0.00001;
								gf.visible = false;
								gf = gfMap.get(value2);
								gf.visible = true;
								gf.alpha = lastAlpha;
							}
							setOnScripts('gfName', gf.curCharacter);
						}
				}
				reloadHealthBarColors();

			case 'Change Scroll Speed':
				if (songSpeedType != "constant")
				{
					if (flValue1 == null)
						flValue1 = 1;
					if (flValue2 == null)
						flValue2 = 0;

					var newValue:Float = SONG.speed * ClientPrefs.getGameplaySetting('scrollspeed') * flValue1;
					if (flValue2 <= 0)
						songSpeed = newValue;
					else
						songSpeedTween = FlxTween.tween(this, {songSpeed: newValue}, flValue2 / playbackRate, {
							ease: FlxEase.linear,
							onComplete: function(twn:FlxTween)
							{
								songSpeedTween = null;
							}
						});
				}

			case 'Set Property':
				try
				{
					var split:Array<String> = value1.split('.');
					if (split.length > 1)
					{
						LuaUtils.setVarInArray(LuaUtils.getPropertyLoop(split), split[split.length - 1], value2);
					}
					else
					{
						LuaUtils.setVarInArray(this, value1, value2);
					}
				}
				catch (e:Dynamic)
				{
					var len:Int = e.message.indexOf('\n') + 1;
					if (len <= 0)
						len = e.message.length;
					#if (LUA_ALLOWED || HSCRIPT_ALLOWED)
					addTextToDebug('ERROR ("Set Property" Event) - ' + e.message.substr(0, len), FlxColor.RED);
					#else
					FlxG.log.warn('ERROR ("Set Property" Event) - ' + e.message.substr(0, len));
					#end
				}

			case 'Play Sound':
				if (flValue2 == null)
					flValue2 = 1;
				FlxG.sound.play(Paths.sound(value1), flValue2);
		}

		stagesFunc(function(stage:BaseStage) stage.eventCalled(eventName, value1, value2, flValue1, flValue2, strumTime));
		callOnScripts('onEvent', [eventName, value1, value2, strumTime]);
	}

	public function moveCameraSection(?sec:Null<Int>):Void
	{
		if (sec == null)
			sec = curSection;
		if (sec < 0)
			sec = 0;

		if (SONG.notes[sec] == null)
			return;

		if (gf != null && SONG.notes[sec].gfSection)
		{
			camFollow.setPosition(gf.getMidpoint().x, gf.getMidpoint().y);
			camFollow.x += gf.cameraPosition[0] + girlfriendCameraOffset[0] + gf.additionalX;
			camFollow.y += gf.cameraPosition[1] + girlfriendCameraOffset[1] + gf.additionalY;
			tweenCamIn();
			callOnScripts('onMoveCamera', ['gf']);
			return;
		}

		var isDad:Bool = (SONG.notes[sec].mustHitSection != true);
		moveCamera(isDad);
		callOnScripts('onMoveCamera', [isDad ? 'dad' : 'boyfriend']);
	}

	var cameraTwn:FlxTween;

	public function moveCamera(isDad:Bool)
	{
		if (isDad)
		{
			camFollow.setPosition(dad.getMidpoint().x + 150, dad.getMidpoint().y - 100);
			camFollow.x += dad.cameraPosition[0] + opponentCameraOffset[0] + dad.additionalX;
			camFollow.y += dad.cameraPosition[1] + opponentCameraOffset[1] + dad.additionalY;
			tweenCamIn();
		}
		else
		{
			camFollow.setPosition(boyfriend.getMidpoint().x - 100, boyfriend.getMidpoint().y - 100);
			camFollow.x -= boyfriend.cameraPosition[0] - boyfriendCameraOffset[0] - boyfriend.additionalX;
			camFollow.y += boyfriend.cameraPosition[1] + boyfriendCameraOffset[1] + boyfriend.additionalY;

			if (songName == 'tutorial' && cameraTwn == null && FlxG.camera.zoom != 1)
			{
				cameraTwn = FlxTween.tween(FlxG.camera, {zoom: 1}, (Conductor.stepCrochet * 4 / 1000), {
					ease: FlxEase.elasticInOut,
					onComplete: function(twn:FlxTween)
					{
						cameraTwn = null;
					}
				});
			}
		}
	}

	public function tweenCamIn()
	{
		if (songName == 'tutorial' && cameraTwn == null && FlxG.camera.zoom != 1.3)
		{
			cameraTwn = FlxTween.tween(FlxG.camera, {zoom: 1.3}, (Conductor.stepCrochet * 4 / 1000), {
				ease: FlxEase.elasticInOut,
				onComplete: function(twn:FlxTween)
				{
					cameraTwn = null;
				}
			});
		}
	}

	public function finishSong(?ignoreNoteOffset:Bool = false)
	{
		updateTime = false;
		FlxG.sound.music.volume = 0;

		vocals.volume = 0;
		vocals.pause();
		opponentVocals.volume = 0;
		opponentVocals.pause();

		if (ClientPrefs.data.noteOffset <= 0 || ignoreNoteOffset)
		{
			endCallback();
		}
		else
		{
			finishTimer = new FlxTimer().start(ClientPrefs.data.noteOffset / 1000, function(tmr:FlxTimer)
			{
				endCallback();
			});
		}
	}

	public var transitioning = false;

	public function endSong()
	{
		if (mobileControls != null)
			mobileControls.visible = false;
		// Should kill you if you tried to cheat
		if (!startingSong)
		{
			notes.forEach(function(daNote:Note)
			{
				if (daNote.strumTime < songLength - Conductor.safeZoneOffset)
				{
					health -= 0.05 * healthLoss;
				}
			});
			for (daNote in unspawnNotes)
			{
				if (daNote.strumTime < songLength - Conductor.safeZoneOffset)
				{
					health -= 0.05 * healthLoss;
				}
			}

			if (doDeathCheck())
			{
				return false;
			}
		}

		keyboardViewer.save();

		timeBar.visible = false;
		timeTxt.visible = false;
		canPause = false;
		endingSong = true;
		GABridge.sendProgression("Complete", "song", SONG.song.toLowerCase(), Difficulty.getString(), songScore, (isStoryMode ? 1 : 0));
		camZooming = false;
		inCutscene = false;
		updateTime = false;

		deathCounter = 0;
		seenCutscene = false;

		persistentUpdate = false;

		#if ACHIEVEMENTS_ALLOWED
		var weekNoMiss:String = WeekData.getWeekFileName() + '_nomiss';
		checkForAchievement([weekNoMiss, 'ur_bad', 'ur_good', 'hype', 'two_keys', 'toastie', 'debugger']);
		#end

		var ret:Dynamic = callOnScripts('onEndSong', null, true);
		if (ret != LuaUtils.Function_Stop && !transitioning)
		{
			DeepDebugTracker.finish('completed');

			#if !switch
			var percent:Float = ratingPercent;
			if (Math.isNaN(percent))
				percent = 0;
			if (!ClientPrefs.data.playOpponent && !replayMode)
			{
				var details:Array<Array<Dynamic>> = [
					[
						songName, songLength, Date.now().toString()
					],
					[
						songSpeed, playbackRate, healthGain, healthLoss,
						cpuControlled, practiceMode, instakillOnMiss, ClientPrefs.data.playOpponent, 
						ClientPrefs.data.flipChart,
					],
					[
						songScore, ratingPercent, ratingFC, songHits, highestCombo, songMisses
					],
					[
						NoteTime, NoteMs
					]
				];
				Highscore.saveGameData(SONG.song, storyDifficulty, details, null);
				
				var record:games.backend.Replay.StateRecord = {
					songName: songName,
					difficulty: Difficulty.getString().toUpperCase(),
					songLength: songLength,
					playDate: Date.now().toString(),
					modDir: Mods.currentModDirectory == '' ? 'originFunkin' : Mods.currentModDirectory,
					songSpeed: songSpeed,
					playbackRate: playbackRate,
					healthGain: healthGain,
					healthLoss: healthLoss,
					cpuControlled: cpuControlled,
					practiceMode: practiceMode,
					instakillOnMiss: instakillOnMiss,
					playOpponent: ClientPrefs.data.playOpponent,
					flipChart: ClientPrefs.data.flipChart,
					songScore: songScore,
					ratingPercent: ratingPercent,
					ratingFC: ratingFC,
					songHits: songHits,
					highestCombo: highestCombo,
					songMisses: songMisses,
					hitMapTime: NoteTime,
					hitMapMs: NoteMs,
					replayVersion: ClientPrefs.data.replayQuality ? 2 : 1,
					sickCount: ratingsData[0].hits,
					goodCount: ratingsData[1].hits,
					badCount: ratingsData[2].hits,
					shitCount: ratingsData[3].hits,
					mania: SONG.mania,
					safeFrames: ClientPrefs.data.safeFrames,
					ratingOffset: ClientPrefs.data.ratingOffset,
					noteOffset: ClientPrefs.data.noteOffset,
					botPlay: ClientPrefs.getGameplaySetting('botplay', 'bool'),
						gameplaySettingsJson: haxe.Json.stringify(ClientPrefs.data.gameplaySettings)
				};
				//replayExam.savePlayRecord(record);
			}
			#end
			playbackRate = 1;

			if (chartingMode)
			{
				openChartEditor();
				return false;
			}

			if (isStoryMode)
			{
				campaignScore += songScore;
				campaignMisses += songMisses;

				storyPlaylist.remove(storyPlaylist[0]);

				if (storyPlaylist.length <= 0)
				{
					Mods.loadTopMod();
					FlxG.sound.playMusic(Paths.music('freakyMenu'));
					#if DISCORD_ALLOWED DiscordClient.resetClientID(); #end

					MusicBeatState.switchState(new StoryMenuState());

					if (!ClientPrefs.getGameplaySetting('practice')
						&& !ClientPrefs.getGameplaySetting('botplay')
						&& !ClientPrefs.data.playOpponent)
					{
						StoryMenuState.weekCompleted.set(WeekData.weeksList[storyWeek], true);
						Highscore.saveWeekScore(WeekData.getWeekFileName(), campaignScore, storyDifficulty);

						FlxG.save.data.weekCompleted = StoryMenuState.weekCompleted;
						FlxG.save.flush();
					}
					changedDifficulty = false;
					transitioning = true;
					return true;
				}
				else
				{
					var difficulty:String = Difficulty.getFilePath();

					trace('LOADING NEXT SONG');
					trace(Paths.formatToSongPath(PlayState.storyPlaylist[0]) + difficulty);

					FlxTransitionableState.skipNextTransIn = true;
					FlxTransitionableState.skipNextTransOut = true;
					prevCamFollow = camFollow;

					PlayState.SONG = Song.loadFromJson(PlayState.storyPlaylist[0] + difficulty, PlayState.storyPlaylist[0]);
					FlxG.sound.music.stop();
					LoadingState.prepareToSong();
					LoadingState.loadAndSwitchState(new PlayState());
					transitioning = true;
					return true;
					}
			}
	}

		// Always show results after all scripts have run (even if Function_Stop was returned)
		if (!transitioning)
		{
			ResultsScreen.savedModDir = Mods.currentModDirectory;
			Mods.loadTopMod();
			#if DISCORD_ALLOWED DiscordClient.resetClientID(); #end

			if (ClientPrefs.data.resultsScreen)
			{
				openSubState(new ResultsScreen(boyfriend.getScreenPosition().x, boyfriend.getScreenPosition().y));
				FlxG.sound.playMusic(Paths.music('freakyMenu'), 0.7);
			}
			else
			{
				MusicBeatState.switchState(new FreeplayState());
				FlxG.sound.playMusic(Paths.music('freakyMenu'), 0);
				FlxG.sound.music.fadeIn(4, 0, 0.7);
			}
			changedDifficulty = false;
			transitioning = true;
		}
		return true;
	}

	public function KillNotes()
	{
		while (notes.length > 0)
		{
			var daNote:Note = notes.members[0];
			daNote.active = false;
			daNote.visible = false;
			invalidateNote(daNote);
		}
		unspawnNotes = [];
		eventNotes = [];
	}

	public var totalPlayed:Int = 0;
	public var totalNotesHit:Float = 0.0;

	public var showCombo:Bool = false;
	public var showComboNum:Bool = true;
	public var showRating:Bool = true;

	// Stores Ratings and Combo Sprites in a group
	public var comboGroup:FlxSpriteGroup;
	// Stores HUD Objects in a Group
	public var uiGroup:FlxSpriteGroup;
	// Stores Note Objects in a Group
	public var noteGroup:FlxTypedGroup<FlxBasic>;

	// it not use because new way
	var rateSpr_S:FlxSprite;
	var comboSpr_S:FlxSprite;
	var scoreRatingGraphics:Map<String, FlxGraphic> = new Map<String, FlxGraphic>();
	var scoreComboGraphic:FlxGraphic;
	var scoreNumberGraphics:Array<FlxGraphic> = [];

	var rateTween:FlxTween;
	var comboTween:FlxTween;
	var comboNumTween:Array<FlxTween> = [];

	var rateTweenScaleX:FlxTween;
	var comboTweenScaleX:FlxTween;
	var comboNumTweenScaleX:Array<FlxTween> = [];

	var rateTweenScaleY:FlxTween;
	var comboTweenScaleY:FlxTween;
	var comboNumTweenScaleY:Array<FlxTween> = [];

	var seperatedScore:Array<Int> = [];

	private function resolveScoreGraphic(candidates:Array<String>):FlxGraphic
	{
		var attempted:Array<String> = [];
		for (key in candidates)
		{
			if (key == null || key.length == 0 || attempted.contains(key))
				continue;

			attempted.push(key);
			var graphic:FlxGraphic = Paths.image(key);
			if (graphic != null)
				return graphic;
		}
		return null;
	}

	private function cachePopUpScore()
	{
		var uiPrefix:String = '';
		var uiSuffix:String = '';
		if (stageUI != "normal")
		{
			uiPrefix = '${stageUI}UI/';
			if (PlayState.isPixelStage)
				uiSuffix = '-pixel';
		}

		scoreRatingGraphics.clear();
		scoreNumberGraphics = [];
		var highestRatingImage:String = ratingsData.length > 0 ? ratingsData[0].image : 'sick';
		for (rating in ratingsData)
		{
			// Custom pixel UIs do not always provide every optional judgment
			// image (notably marvelous-pixel). Resolve that once while loading
			// the state, then reuse the FlxGraphic on every note. Repeating a
			// failed Paths.image lookup here used to allocate and log on every
			// hit, which caused audio resync storms on dense charts.
			var graphic:FlxGraphic = resolveScoreGraphic([
				uiPrefix + rating.image + uiSuffix,
				uiPrefix + highestRatingImage + uiSuffix,
				highestRatingImage,
				'sick'
			]);
			if (graphic == null)
				continue;

			scoreRatingGraphics.set(rating.name, graphic);
			var spr:FlxSprite = new FlxSprite().loadGraphic(graphic);
			rating.color = FlxColor.fromInt(CoolUtil.getComboColor(spr));
			spr.destroy();
		}

		for (i in 0...10)
			scoreNumberGraphics[i] = resolveScoreGraphic([uiPrefix + 'num' + i + uiSuffix, 'num' + i]);
		scoreComboGraphic = resolveScoreGraphic([uiPrefix + 'combo' + uiSuffix, 'combo']);

		var antialias:Bool = ClientPrefs.data.antialiasing;

		if (stageUI != "normal")
		{
			uiPrefix = '${stageUI}UI/';
			if (PlayState.isPixelStage)
				uiSuffix = '-pixel';
			antialias = !isPixelStage;
		}

		var placement:Float = FlxG.width * 0.35;

		var initialRatingGraphic:FlxGraphic = ratingsData.length > 0 ? scoreRatingGraphics.get(ratingsData[0].name) : null;
		rateSpr_S = new FlxSprite();
		if (initialRatingGraphic != null)
			rateSpr_S.loadGraphic(initialRatingGraphic);
		else
			rateSpr_S.makeGraphic(1, 1, FlxColor.TRANSPARENT);
		rateSpr_S.cameras = [camHUD];
		rateSpr_S.screenCenter();
		rateSpr_S.x = placement - 40;
		rateSpr_S.y -= 60;
		rateSpr_S.x += ClientPrefs.data.comboOffset[0];
		rateSpr_S.y -= ClientPrefs.data.comboOffset[1];
		if (!PlayState.isPixelStage)
		{
			rateSpr_S.setGraphicSize(Std.int(rateSpr_S.width * 0.7));
		}
		else
		{
			rateSpr_S.setGraphicSize(Std.int(rateSpr_S.width * daPixelZoom * 0.85));
		}
		rateSpr_S.updateHitbox();
		rateSpr_S.x += rateSpr_S.width / 2;
		rateSpr_S.y += rateSpr_S.height / 2;
		rateSpr_S.updateHitbox();
		rateSpr_S.antialiasing = antialias;
		rateSpr_S.alpha = 0.000001;
		rateSpr_S.visible = showRating;
		comboGroup.add(rateSpr_S);

		comboSpr_S = new FlxSprite();
		if (scoreComboGraphic != null)
			comboSpr_S.loadGraphic(scoreComboGraphic);
		else
			comboSpr_S.makeGraphic(1, 1, FlxColor.TRANSPARENT);
		comboSpr_S.cameras = [camHUD];
		comboSpr_S.screenCenter();
		comboSpr_S.x = placement;
		comboSpr_S.x += ClientPrefs.data.comboOffset[0];
		comboSpr_S.y -= ClientPrefs.data.comboOffset[1];
		comboSpr_S.antialiasing = antialias;
		comboSpr_S.y += 60;
		comboSpr_S.alpha = 0.000001;
		comboSpr_S.visible = showCombo;
		comboGroup.add(comboSpr_S);

		var xThing:Float = 0;

		numItems = new FlxTypedGroup<FlxSprite>();
		numItems.visible = showComboNum;
		add(numItems);
		numItems.cameras = [camHUD];

		for (comboNum in 0...4) // 9999 //why last get null?
		{
			var numScore:FlxSprite = new FlxSprite();
			if (scoreNumberGraphics[0] != null)
				numScore.loadGraphic(scoreNumberGraphics[0]);
			else
				numScore.makeGraphic(1, 1, FlxColor.TRANSPARENT);
			numScore.screenCenter();
			numScore.x = placement + (50 * (comboNum - 1)) - 90 + ClientPrefs.data.comboOffset[2];
			numScore.y += 80 - ClientPrefs.data.comboOffset[3];
			numScore.setGraphicSize(Std.int(numScore.width * 0.5));
			numScore.updateHitbox();
			numScore.y += numScore.width * 0.5;
			numScore.antialiasing = antialias;
			numScore.alpha = 0.000001;

			comboGroup.add(numScore);
			numItems.add(numScore);

			if (numScore.x > xThing)
				xThing = numScore.x;
		}

		comboSpr_S.x = xThing + 50 * 2;
	}

	private function popUpScore(note:Note = null):Void
	{
		var recordedJudgment:games.backend.Replay.NoteJudgment = null;
		if (replayMode && @:privateAccess replayExam.hasJudgments)
			recordedJudgment = @:privateAccess replayExam.getRecordedJudgment(note.strumTime, note.noteData);

		var noteDiff:Float;
		if (recordedJudgment != null)
		{
			// Use the original player's actual hit timing from recording
			noteDiff = recordedJudgment.hitDiff * playbackRate;
		}
		else
		{
			noteDiff = replayMode ? note.strumTime - @:privateAccess replayExam.time + ClientPrefs.data.ratingOffset :
				note.strumTime - Conductor.songPosition + ClientPrefs.data.ratingOffset;
		}

		if ((ClientPrefs.data.playOpponent && cpuControlled_opponent) || (!ClientPrefs.data.playOpponent && cpuControlled))
			noteDiff = 0;

		NoteMs.push(noteDiff / playbackRate);
		NoteTime.push(note.strumTime);

		vocals.volume = 1;

		var score:Int = 350;

		var daRating:Rating = null;
		if (recordedJudgment != null)
		{
			// Use the original recorded rating, not the engine's re-judgment
			for (r in ratingsData)
			{
				if (r.name == recordedJudgment.rating)
				{
					daRating = r;
					break;
				}
			}
			if (daRating == null) daRating = ratingsData[0];
			score = daRating.score;
			if (!note.ratingDisabled)
				daRating.hits++;
			note.rating = recordedJudgment.rating;
			note.ratingMod = daRating.ratingMod;
			totalNotesHit += daRating.ratingMod;
		}
		else
		{
			daRating = Conductor.judgeNote(ratingsData, Math.abs(noteDiff) / playbackRate);
			totalNotesHit += daRating.ratingMod;
			note.ratingMod = daRating.ratingMod;
			if (!note.ratingDisabled)
				daRating.hits++;
			note.rating = daRating.name;
			score = daRating.score;

			@:privateAccess replayExam.recordJudgment(note.strumTime, note.noteData, noteDiff / playbackRate, daRating.name, note.isSustainNote);
		}

		if (daRating.noteSplash && !note.noteSplashData.disabled)
			spawnNoteSplashOnNote(note);

		if (ClientPrefs.data.playOpponent ? !cpuControlled_opponent : !cpuControlled)
		{
			songScore += score;
			if (!note.ratingDisabled)
			{
				songHits++;
				totalPlayed++;
				RecalculateRating(false);
				judgementCounter_S.updateScore(daRating.name);
			}
		}

		//---------------------------------

		if (!ClientPrefs.data.showComboNum && !ClientPrefs.data.showRating)
			return;

		var uiPrefix:String = "";
		var uiSuffix:String = '';
		var antialias:Bool = ClientPrefs.data.antialiasing;

		if (stageUI != "normal")
		{
			uiPrefix = '${stageUI}UI/';
			if (PlayState.isPixelStage)
				uiSuffix = '-pixel';
			antialias = !isPixelStage;
		}

		var ratingGraphic:FlxGraphic = scoreRatingGraphics.get(daRating.name);
		rateSpr_S.visible = ClientPrefs.data.showRating && showRating && ratingGraphic != null;
		if (ratingGraphic != null)
			rateSpr_S.loadGraphic(ratingGraphic);
		rateSpr_S.antialiasing = antialias;

		comboSpr_S.visible = showCombo && scoreComboGraphic != null;
		if (scoreComboGraphic != null)
			comboSpr_S.loadGraphic(scoreComboGraphic);
		comboSpr_S.antialiasing = antialias;

		var scale:Float = 0;
		var numScale:Float = 0;
		if (!PlayState.isPixelStage)
		{
			rateSpr_S.setGraphicSize(Std.int(rateSpr_S.width * 0.7));
			comboSpr_S.setGraphicSize(Std.int(comboSpr_S.width * 0.6));
			scale = 0.7;
			numScale = 0.5;
		}
		else
		{
			rateSpr_S.setGraphicSize(Std.int(rateSpr_S.width * daPixelZoom * 0.85));
			comboSpr_S.setGraphicSize(Std.int(comboSpr_S.width * daPixelZoom * 0.85));
			scale = 0.85 * daPixelZoom;
			numScale = daPixelZoom;
		}

		comboSpr_S.updateHitbox();
		rateSpr_S.updateHitbox();

		seperatedScore.splice(0, seperatedScore.length);
		var startShow = 1; // use for combo 1000+
		if (combo >= 1000)
		{
			seperatedScore.push(Math.floor(combo / 1000) % 10);
			startShow = 0;
		}
		else
		{
			numItems.members[0].alpha = 0.00001;
		}

		seperatedScore.push(Math.floor(combo / 100) % 10);
		seperatedScore.push(Math.floor(combo / 10) % 10);
		seperatedScore.push(combo % 10);

		for (comboNum in 0...seperatedScore.length)
		{
			var numScore:FlxSprite = numItems.members[comboNum + startShow];
			var numberGraphic:FlxGraphic = scoreNumberGraphics[seperatedScore[comboNum]];
			numScore.visible = ClientPrefs.data.showComboNum && showComboNum && numberGraphic != null;
			if (numberGraphic != null)
				numScore.loadGraphic(numberGraphic);
			if (ClientPrefs.data.comboColor)
				numScore.color = daRating.color;
			else
				numScore.color = FlxColor.WHITE;

			if (!PlayState.isPixelStage)
				numScore.setGraphicSize(Std.int(numScore.width * 0.5));
			else
				numScore.setGraphicSize(Std.int(numScore.width * daPixelZoom));
			numScore.updateHitbox();
			numScore.antialiasing = antialias;

			if (comboNumTween[comboNum + startShow] != null)
				comboNumTween[comboNum + startShow].cancel();
			numScore.alpha = 1;
			comboNumTween[comboNum + startShow] = FlxTween.tween(numScore, {alpha: 0}, 0.4 / playbackRate, {
				startDelay: 0.6 / playbackRate
			});

			if (comboNumTweenScaleX[comboNum] != null)
				comboNumTweenScaleX[comboNum].cancel();
			numScore.scale.x = numScale + 0.07;
			numScore.scale.y = numScale + 0.07;
			comboNumTweenScaleX[comboNum] = FlxTween.tween(numScore.scale, {x: numScale, y: numScale}, 0.2 / playbackRate);

			if (ClientPrefs.data.comboOffsetFix)
			{
				numScore.offset.x -= comboOffsetFix[seperatedScore[comboNum]][0] * 0.5;
				numScore.offset.y += comboOffsetFix[seperatedScore[comboNum]][1] * 0.5;
			}
		}

		if (rateTween != null)
			rateTween.cancel();
		rateSpr_S.alpha = 1;
		rateTween = FlxTween.tween(rateSpr_S, {alpha: 0}, 0.4 / playbackRate, {
			startDelay: 0.6 / playbackRate
		});

		if (comboTween != null)
			comboTween.cancel();
		comboSpr_S.alpha = 1;
		comboTween = FlxTween.tween(comboSpr_S, {alpha: 0}, 0.4 / playbackRate, {
			startDelay: 0.6 / playbackRate
		});

		if (rateTweenScaleX != null)
			rateTweenScaleX.cancel();
		rateSpr_S.scale.x = scale + 0.07;
		rateSpr_S.scale.y = scale + 0.07;
		rateTweenScaleX = FlxTween.tween(rateSpr_S.scale, {x: scale, y: scale}, 0.2 / playbackRate);

		if (comboTweenScaleX != null)
			comboTweenScaleX.cancel();
		comboSpr_S.scale.x = scale + 0.07;
		comboSpr_S.scale.y = scale + 0.07;
		comboTweenScaleX = FlxTween.tween(comboSpr_S.scale, {x: scale, y: scale}, 0.2 / playbackRate);

		rateSpr_S.offset.x += rateSpr_S.width / 2;
		rateSpr_S.offset.y += rateSpr_S.height / 2;
	}

	public var strumsBlocked:Array<Bool> = [];

    inline private function addNoteInternal(dunceNote:Note):Void
    {
        notes.add(dunceNote);
        if (dunceNote.isSustainNote) sustainLayer.add(dunceNote); else tapLayer.add(dunceNote);
        dunceNote.spawned = true;
        spawnNoteArgs[0] = notes.length - 1;
        spawnNoteArgs[1] = dunceNote.noteData;
        spawnNoteArgs[2] = dunceNote.noteType;
        spawnNoteArgs[3] = dunceNote.isSustainNote;
        spawnNoteArgs[4] = dunceNote.strumTime;
        callOnLuas('onSpawnNote', spawnNoteArgs);
        singleArg[0] = dunceNote;
        callOnHScript('onSpawnNote', singleArg);
    }

	private function keyPressed(key:Int)
	{
		if (ClientPrefs.data.playOpponent ? cpuControlled_opponent : cpuControlled || paused || key < 0)
			return;
		var char:Character = ClientPrefs.data.playOpponent ? dad : boyfriend;
		if (!generatedMusic || endingSong || char.stunned)
			return;

		keyboardViewer.pressed(key);

		// had to name it like this else it'd break older scripts lol
		var ret:Dynamic = callOnScripts('preKeyPress', [key], true);

		var inputSongPos:Float = replayMode ? @:privateAccess replayExam.time : Conductor.songPosition;
		var bestNote:Note = null;
		var secondNote:Note = null;
		var i:Int = 0;
		while (i < notes.length)
		{
			var n:Note = notes.members[i];
			if (n != null)
			{
				var tooLateAt:Bool = n.strumTime < inputSongPos - Conductor.safeZoneOffset && !n.wasGoodHit;
				var canBeHitAt:Bool = (n.strumTime > inputSongPos - (Conductor.safeZoneOffset * n.lateHitMult)
					&& n.strumTime < inputSongPos + (Conductor.safeZoneOffset * n.earlyHitMult));
				var canHit:Bool = !strumsBlocked[n.noteData]
					&& ((n.mustPress && !ClientPrefs.data.playOpponent) || (!n.mustPress && ClientPrefs.data.playOpponent))
					&& canBeHitAt
					&& !tooLateAt
					&& !n.wasGoodHit
					&& !n.blockHit;
				if (canHit && !n.isSustainNote && n.noteData == key)
				{
					if (bestNote == null || n.strumTime < bestNote.strumTime)
					{
						secondNote = bestNote;
						bestNote = n;
					}
					else if (secondNote == null || n.strumTime < secondNote.strumTime)
					{
						secondNote = n;
					}
				}
			}
			i++;
		}

		var shouldMiss:Bool = !ClientPrefs.data.ghostTapping;

		if (bestNote != null)
		{ // slightly faster than doing `> 0` lol
			var funnyNote:Note = bestNote; // front note

			if (secondNote != null)
			{
				var doubleNote:Note = secondNote;

				if (doubleNote.noteData == funnyNote.noteData)
				{
					// if the note has a 0ms distance (is on top of the current note), kill it
					if (Math.abs(doubleNote.strumTime - funnyNote.strumTime) < 1.0) {
						doubleNote.killTail = true;
						invalidateNote(doubleNote);
					}	
					else if (doubleNote.strumTime > funnyNote.strumTime
						&& !doubleNote.hitCausesMiss
						&& !doubleNote.ignoreNote
						&& (funnyNote.hitCausesMiss || funnyNote.ignoreNote))
					{
						// replace the note if its ahead of time (or at least ensure "doubleNote" is ahead)
						funnyNote = doubleNote;
					}
				}
			}

			if (funnyNote.tail.length > 0)
			{
				for (childNote in funnyNote.tail)
				{
					childNote.canHold = true;
				}
			}
			if (!ClientPrefs.data.playOpponent)
				goodNoteHit(funnyNote);
			else
				opponentNoteHitForOpponent(funnyNote);
		}
		else
		{
			var holdNote:Note = null;
			var j:Int = 0;
			while (j < notes.length)
			{
				var n2:Note = notes.members[j];
				if (n2 != null)
				{
					var tooLateAt2:Bool = n2.strumTime < inputSongPos - Conductor.safeZoneOffset && !n2.wasGoodHit;
					var canBeHitAt2:Bool = (n2.strumTime > inputSongPos - (Conductor.safeZoneOffset * n2.lateHitMult)
						&& n2.strumTime < inputSongPos + (Conductor.safeZoneOffset * n2.earlyHitMult));
					var canHit2:Bool = !strumsBlocked[n2.noteData]
						&& ((n2.mustPress && !ClientPrefs.data.playOpponent) || (!n2.mustPress && ClientPrefs.data.playOpponent))
						&& canBeHitAt2
						&& !tooLateAt2
						&& !n2.wasGoodHit
						&& !n2.blockHit;
					if (canHit2 && n2.isSustainNote && n2.noteData == key)
					{
						holdNote = n2;
						break;
					}
				}
				j++;
			}

			if (holdNote != null && holdNote.parent != null)
			{
				var parentNote:Note = holdNote.parent;
				if (parentNote.tail.length > 0)
				{
					for (child in parentNote.tail)
					{
						if (child != null)
						{
							child.canHold = true;
						}
					}
				}
			}

			if (shouldMiss && !char.stunned)
			{
				callOnScripts('onGhostTap', [key]);
				noteMissPress(key);
			}
		}

		// Needed for the  "Just the Two of Us" achievement.
		//									- Shadow Mario
		if (!keysPressed.contains(key))
			keysPressed.push(key);

		var spr:StrumNote = ClientPrefs.data.playOpponent ? opponentStrums.members[key] : playerStrums.members[key];
		if (strumsBlocked[key] != true && spr != null && spr.animation.curAnim.name != 'confirm')
		{
			spr.playAnim('pressed');
			spr.resetAnim = 0;
		}
		callOnScripts('onKeyPress', [key]);
	}

	public static function sortHitNotes(a:Note, b:Note):Int
	{
		/*
			if (a.lowPriority && !b.lowPriority)
				return 1;
			else if (!a.lowPriority && b.lowPriority)
				return -1;
		 */
		// 在0.73这个玩意几乎没用而且已经被我的箭头优先级重写顶替了 --狐月影

		return FlxSort.byValues(FlxSort.ASCENDING, a.strumTime, b.strumTime);
	}

	public function keyReleased(key:Int)
	{
		if (ClientPrefs.data.playOpponent ? !cpuControlled_opponent : !cpuControlled && startedCountdown && !paused)
		{
			keyboardViewer.released(key);

			var spr:StrumNote = ClientPrefs.data.playOpponent ? opponentStrums.members[key] : playerStrums.members[key];
			if (spr != null)
			{
				spr.playAnim('static');
				spr.resetAnim = 0;
			}
			callOnScripts('onKeyRelease', [key]);
		}
	}

	public function replayApplyInput(frameTime:Float, pressLanes:Array<Int>, releaseLanes:Array<Int>, heldLanes:Array<Bool>):Void
	{
		var laneCount:Int = keysArray.length;
		for (i in 0...laneCount)
		{
			_hold[i] = (heldLanes != null && i < heldLanes.length) ? heldLanes[i] : false;
			_press[i] = false;
			_release[i] = false;
		}
		if (pressLanes != null)
		{
			for (lane in pressLanes)
			{
				if (lane >= 0 && lane < laneCount) _press[lane] = true;
			}
		}
		if (releaseLanes != null)
		{
			for (lane in releaseLanes)
			{
				if (lane >= 0 && lane < laneCount) _release[lane] = true;
			}
		}

		if (_press.contains(true))
			for (i in 0..._press.length)
				if (_press[i] && strumsBlocked[i] != true)
					keyPressed(i);

		var char:Character = ClientPrefs.data.playOpponent ? dad : boyfriend;
		if (startedCountdown && !char.stunned && generatedMusic)
		{
			var inputSongPos:Float = frameTime;
			if (notes.length > 0)
			{
				var len:Int = notes.length;
				var i:Int = 0;
				while (i < len)
				{
					var daNote:Note = cast notes.members[i];
					if (daNote != null && daNote.exists && daNote.alive)
					{
						var tooLateAt:Bool = daNote.strumTime < inputSongPos - Conductor.safeZoneOffset && !daNote.wasGoodHit;
						var canBeHitAt:Bool = (daNote.strumTime > inputSongPos - (Conductor.safeZoneOffset * daNote.lateHitMult)
							&& daNote.strumTime < inputSongPos + (Conductor.safeZoneOffset * daNote.earlyHitMult));
						if (strumsBlocked[daNote.noteData] != true
							&& daNote.isSustainNote
							&& _hold[daNote.noteData]
							&& canBeHitAt
							&& !tooLateAt
							&& !daNote.wasGoodHit
							&& !daNote.blockHit
							&& daNote.canHold)
						{
							if (daNote.mustPress && !ClientPrefs.data.playOpponent)
								goodNoteHit(daNote);
							if (!daNote.mustPress && ClientPrefs.data.playOpponent)
								opponentNoteHitForOpponent(daNote);
						}
					}
					i++;
				}
			}

			if (!_hold.contains(true) || endingSong)
				ClientPrefs.data.playOpponent ? opponentDance() : playerDance();
			#if ACHIEVEMENTS_ALLOWED
			else
				checkForAchievement(['oversinging']);
			#end
		}

		if (_release.contains(true))
			for (i in 0..._release.length)
				if (_release[i] || strumsBlocked[i] == true)
					keyReleased(i);
	}

	// Hold notes
	private function keysCheck():Void
	{
		for (i in 0...keysArray.length)
		{
			var key = keysArray[i];
			_hold[i] = controls.pressed(key);
			_press[i] = controls.justPressed(key);
			_release[i] = controls.justReleased(key);
		}

		if (_press.contains(true))
			for (i in 0..._press.length)
				if (_press[i] && strumsBlocked[i] != true)
					keyPressed(i);

		var char:Character = ClientPrefs.data.playOpponent ? dad : boyfriend;
		if (startedCountdown && !char.stunned && generatedMusic)
		{
			var inputSongPos:Float = replayMode ? @:privateAccess replayExam.time : Conductor.songPosition;
			// rewritten inputs???
			if (notes.length > 0)
			{
				var len:Int = notes.length;
				var i:Int = 0;
				while (i < len)
				{
					var daNote:Note = cast notes.members[i];
					if (daNote != null && daNote.exists && daNote.alive)
					{
						var tooLateAt:Bool = daNote.strumTime < inputSongPos - Conductor.safeZoneOffset && !daNote.wasGoodHit;
						var canBeHitAt:Bool = (daNote.strumTime > inputSongPos - (Conductor.safeZoneOffset * daNote.lateHitMult)
							&& daNote.strumTime < inputSongPos + (Conductor.safeZoneOffset * daNote.earlyHitMult));
						if (strumsBlocked[daNote.noteData] != true
							&& daNote.isSustainNote
							&& _hold[daNote.noteData]
							&& canBeHitAt
							&& !tooLateAt
							&& !daNote.wasGoodHit
							&& !daNote.blockHit
							&& daNote.canHold)
						{
							if (daNote.mustPress && !ClientPrefs.data.playOpponent)
								goodNoteHit(daNote);
							if (!daNote.mustPress && ClientPrefs.data.playOpponent)
								opponentNoteHitForOpponent(daNote);
						}
					}
					i++;
				}
			}

			if (!_hold.contains(true) || endingSong)
				ClientPrefs.data.playOpponent ? opponentDance() : playerDance();

			#if ACHIEVEMENTS_ALLOWED
			else
				checkForAchievement(['oversinging']);
			#end
		}

		if (_release.contains(true))
			for (i in 0..._release.length)
				if (_release[i] || strumsBlocked[i] == true)
					keyReleased(i);
	}

	public function noteMiss(daNote:Note, ?index:Int = -1):Void
	{ // You didn't hit the key and let it go offscreen, also used by Hurt Notes
		// Dupe note remove
		if (notes.length > 0)
		{
			if (index >= 0)
			{
				var start:Int = index - 8;
				if (start < 0) start = 0;
				var stop:Int = index + 8;
				if (stop > notes.length - 1) stop = notes.length - 1;
				var baseTime:Float = daNote.strumTime;
				var k:Int = start;
				while (k <= stop)
				{
					var note:Note = cast notes.members[k];
					if (note != null && note.exists && note.alive)
					{
						if (daNote != note
							&& (!daNote.mustPress && ClientPrefs.data.playOpponent || daNote.mustPress && !ClientPrefs.data.playOpponent)
							&& daNote.noteData == note.noteData
							&& daNote.isSustainNote == note.isSustainNote
							&& Math.abs(baseTime - note.strumTime) < 1)
							invalidateNote(note);
					}
					k++;
				}
			}
			else
			{
				var len:Int = notes.length;
				var i:Int = 0;
				while (i < len)
				{
					var note:Note = cast notes.members[i];
					if (note != null && note.exists && note.alive)
					{
						if (daNote != note
							&& (!daNote.mustPress && ClientPrefs.data.playOpponent || daNote.mustPress && !ClientPrefs.data.playOpponent)
							&& daNote.noteData == note.noteData
							&& daNote.isSustainNote == note.isSustainNote
							&& Math.abs(daNote.strumTime - note.strumTime) < 1)
							invalidateNote(note);
					}
					i++;
				}
			}
		}

		stagesFunc(function(stage:BaseStage) stage.noteMiss(daNote));
		noteMissCommon(daNote.noteData, daNote, index);
	}

	public function noteMissPress(direction:Int = 1):Void // You pressed a key when there was no notes to press for this key
	{
		if (ClientPrefs.data.ghostTapping)
			return; // fuck it

		noteMissCommon(direction);
		FlxG.sound.play(Paths.soundRandom('missnote', 1, 3), FlxG.random.float(0.1, 0.2));
		stagesFunc(function(stage:BaseStage) stage.noteMissPress(direction));
		callOnScripts('noteMissPress', [direction]);
	}

	public function noteMissCommon(direction:Int, note:Note = null, ?index:Int = -1)
	{
		// score and data
		var subtract:Float = 0.05;
		if (note != null)
			subtract = note.missHealth;

		// GUITAR HERO SUSTAIN CHECK LOL!!!!
		if (note != null && guitarHeroSustains && note.parent == null)
		{
			if (note.missed)
				return false;
			if (note.tail.length > 0)
			{
				for (childNote in note.tail)
				{
					childNote.alpha = note.alpha;
					childNote.missed = true;
					childNote.canBeHit = false;
					childNote.ignoreNote = true;
					childNote.tooLate = true;
					childNote.multAlpha = 0.3;
					childNote.alpha = 0.3;
				}
				note.missed = true;
				note.canBeHit = false;
			}
		}
		if (note != null && guitarHeroSustains && note.parent != null && note.isSustainNote)
		{
			if (note.missed)
				return false;

			var parentNote:Note = note.parent;
			if (parentNote != null && parentNote.missed)
			{
				note.missed = true;
				return false;
			}
			if (parentNote != null)
				parentNote.missed = true;
			if (parentNote.tail.length > 0)
			{
				for (child in parentNote.tail)
					if (child != note)
					{
						if (child != null)
						{
							child.missed = true;
							child.canBeHit = false;
							child.ignoreNote = true;
							child.tooLate = true;
							child.multAlpha = 0.3;
							child.alpha = 0.3;
						}
					}
			}

			NoteMs.push(167);
			NoteTime.push(note.strumTime); // it will work better for ResultsScreen
		}
		if (note != null)
			note.missed = true;

		if (instakillOnMiss)
		{
			vocals.volume = 0;
			opponentVocals.volume = 0;
			doDeathCheck(true);
		}

		var lastCombo:Int = combo;
		combo = 0;

		if (note != null && !note.isSustainNote)
		{
			NoteMs.push(167);
			NoteTime.push(note.strumTime);
		}

		health -= subtract * healthLoss;
		songScore -= 10;
		if (!endingSong)
			songMisses++;
		totalPlayed++;
		RecalculateRating(true);
		if (note != null) @:privateAccess replayExam.recordJudgment(note.strumTime, note.noteData, 0, 'miss', note.isSustainNote);
		if (note != null)
		{
			var noteIdx:Int = index;
			if (noteIdx < 0) noteIdx = notes.members.indexOf(note);
			var result:Dynamic = callOnLuas('noteMiss', [noteIdx, note.noteData, note.noteType, note.isSustainNote]);
			if (result != LuaUtils.Function_Stop && result != LuaUtils.Function_StopHScript && result != LuaUtils.Function_StopAll)
				callOnHScript('noteMiss', [note]);
		}
		// play character anims
		var char:Character = ClientPrefs.data.playOpponent ? dad : boyfriend;
		if ((note != null && note.gfNote) || (SONG.notes[curSection] != null && SONG.notes[curSection].gfSection))
			char = gf;

		if (char != null && (note == null || !note.noMissAnimation) && char.hasMissAnimations)
		{
			var suffix:String = '';
			if (note != null)
				suffix = note.animSuffix;

			var animToPlay:String = singAnimation(direction) + 'miss' + suffix;
			char.playAnim(animToPlay, true);

			if (char != gf && lastCombo > 5 && gf != null && gf.animOffsets.exists('sad'))
			{
				gf.playAnim('sad');
				gf.specialAnim = true;
			}
		}
		vocals.volume = 0;
		return true;
	}

	// OVERRIDE THIS IN HXSCRIPT OR SMTH
	// you can use it to handle extra animations like this
	// PlayState.instance.singAnimation = function (data:Int) {
	// 	return 'sing' + ['LEFT', 'DOWN', 'UP', 'RIGHT', 'FRONT', 'LEFT2', 'DOWN2', 'UP2', 'RIGHT2'][data];
	// }
	//上面的注释是PsychEK写的
	public dynamic function singAnimation(noteData:Int):String {
		return 'sing' + ExtraKeysHandler.instance.data.animations[ExtraKeysHandler.instance.data.keys[SONG.mania].notes[noteData]].sing;
	}

	public inline function opponentNoteHit(note:Note):Void
	{
		var result:Dynamic = callOnLuas('opponentNoteHitPre', [
			notes.members.indexOf(note),
			Math.abs(note.noteData),
			note.noteType,
			note.isSustainNote
		]);
		if (result != LuaUtils.Function_Stop && result != LuaUtils.Function_StopHScript && result != LuaUtils.Function_StopAll)
			callOnHScript('opponentNoteHitPre', [note]);

		if (songName != 'tutorial')
			camZooming = true;

		if (note.noteType == 'Hey!' && dad.animOffsets.exists('hey'))
		{
			dad.playAnim('hey', true);
			dad.specialAnim = true;
			dad.heyTimer = 0.6;
		}
		else if (!note.noAnimation)
		{
			var altAnim:String = note.animSuffix;

			if (SONG.notes[curSection] != null)
				if (SONG.notes[curSection].altAnim && !SONG.notes[curSection].gfSection)
					altAnim = '-alt';

			var char:Character = dad;
			var animToPlay:String = singAnimation(note.noteData) + altAnim;
			if (note.gfNote)
				char = gf;

			if (char != null)
			{
				char.playAnim(animToPlay, true);
				char.holdTimer = 0;
			}
		}

		if (ClientPrefs.data.healthDrainOPPO)
		{
			if (health > 0.4)
			{
				if (!(guitarHeroSustains && note.isSustainNote))
					health -= note.hitHealth * healthLoss * ClientPrefs.data.healthDrainOPPOMult;
				if (health <= 0.4)
					health = 0.4;
			}
		}

		if (!splitVocals)
			vocals.volume = 1;
		strumPlayAnim(true, Std.int(Math.abs(note.noteData)), Conductor.stepCrochet * 1.25 / 1000 / playbackRate);
		note.hitByOpponent = true;

		stagesFunc(function(stage:BaseStage) stage.opponentNoteHit(note));
		var result:Dynamic = callOnLuas('opponentNoteHit', [
			notes.members.indexOf(note),
			Math.abs(note.noteData),
			note.noteType,
			note.isSustainNote
		]);
		if (result != LuaUtils.Function_Stop && result != LuaUtils.Function_StopHScript && result != LuaUtils.Function_StopAll)
			callOnHScript('opponentNoteHit', [note]);

		if (!note.isSustainNote)
			invalidateNote(note);
	}

	public inline function opponentNoteHitForOpponent(note:Note):Void
	{
		if (note.wasGoodHit)
			return;
		if (cpuControlled_opponent && note.ignoreNote)
			return;

		var isSus:Bool = note.isSustainNote; // GET OUT OF MY HEAD, GET OUT OF MY HEAD, GET OUT OF MY HEAD
		var leData:Int = Math.round(Math.abs(note.noteData));
		var leType:String = note.noteType;

		var functionReturn:String = ClientPrefs.data.opponentCodeFix ? 'goodNoteHitPre' : 'opponentNoteHitPre';
		var result:Dynamic = callOnLuas(functionReturn, [notes.members.indexOf(note), leData, leType, isSus]);
		if (result != LuaUtils.Function_Stop && result != LuaUtils.Function_StopHScript && result != LuaUtils.Function_StopAll)
			callOnHScript(functionReturn, [note]);

		if (songName != 'tutorial')
			camZooming = true;

		note.wasGoodHit = true;

		if (ClientPrefs.data.hitsoundVolume > 0 && !note.hitsoundDisabled)
			FlxG.sound.play(Paths.sound(note.hitsound), ClientPrefs.data.hitsoundVolume);

		if (!note.noAnimation)
		{
			var altAnim:String = note.animSuffix;

			if (SONG.notes[curSection] != null)
			{
				if (SONG.notes[curSection].altAnim && !SONG.notes[curSection].gfSection)
				{
					altAnim = '-alt';
				}
			}

			var animToPlay:String = singAnimations[Std.int(Math.abs(Math.min(singAnimations.length - 1, note.noteData)))] + altAnim;

			var char:Character = dad;
			var animCheck:String = 'hey';
			if (note.gfNote)
			{
				char = gf;
				animCheck = 'cheer';
			}

			if (char != null)
			{
				char.playAnim(animToPlay + note.animSuffix, true);
				char.holdTimer = 0;

				if (note.noteType == 'Hey!')
				{
					if (char.animOffsets.exists(animCheck))
					{
						char.playAnim(animCheck, true);
						char.specialAnim = true;
						char.heyTimer = 0.6;
					}
				}
			}
		}

		if (!cpuControlled_opponent)
		{
			var spr = opponentStrums.members[note.noteData];
			if (spr != null)
				spr.playAnim('confirm', true);
		}
		else
			strumPlayAnim(true, Std.int(Math.abs(note.noteData)), Conductor.stepCrochet * 1.25 / 1000 / playbackRate);
		vocals.volume = 1;

		if (!note.isSustainNote)
		{
			combo++;
			if (combo > 9999)
				combo = 9999;
			if (combo > highestCombo)
				highestCombo = combo;
			notesHitArray.unshift(Date.now());
			popUpScore(note);
		}
		var gainHealth:Bool = true; // prevent health gain, *if* sustains are treated as a singular note
		if (guitarHeroSustains && note.isSustainNote)
			gainHealth = false;
		if (gainHealth)
			health += note.hitHealth * healthGain;

		stagesFunc(function(stage:BaseStage) stage.goodNoteHit(note));
		var functionReturn:String = ClientPrefs.data.opponentCodeFix ? 'goodNoteHit' : 'opponentNoteHit';
		var result:Dynamic = callOnLuas(functionReturn, [notes.members.indexOf(note), leData, leType, isSus]);
		if (result != LuaUtils.Function_Stop && result != LuaUtils.Function_StopHScript && result != LuaUtils.Function_StopAll)
			callOnHScript(functionReturn, [note]);

		if (!note.isSustainNote)
			invalidateNote(note);
	}

	function checkReplayForceMiss(note:Note):Bool
	{
		if (replayMode && @:privateAccess replayExam.hasJudgments)
		{
			var rec:games.backend.Replay.NoteJudgment = @:privateAccess replayExam.getRecordedJudgment(note.strumTime, note.noteData);
			if (rec != null && rec.rating == 'miss')
			{
				noteMiss(note);
				return true;
			}
		}
		return false;
	}

	public function goodNoteHit(note:Note):Void
	{
		if (note.wasGoodHit)
			return;
		if (cpuControlled && note.ignoreNote)
			return;
		if (checkReplayForceMiss(note))
			return;

		var isSus:Bool = note.isSustainNote; // GET OUT OF MY HEAD, GET OUT OF MY HEAD, GET OUT OF MY HEAD
		var leData:Int = Math.round(Math.abs(note.noteData));
		var leType:String = note.noteType;

		var result:Dynamic = callOnLuas('goodNoteHitPre', [notes.members.indexOf(note), leData, leType, isSus]);
		if (result != LuaUtils.Function_Stop && result != LuaUtils.Function_StopHScript && result != LuaUtils.Function_StopAll)
			callOnHScript('goodNoteHitPre', [note]);

		note.wasGoodHit = true;

		if (ClientPrefs.data.hitsoundVolume > 0 && !note.hitsoundDisabled)
			FlxG.sound.play(Paths.sound(note.hitsound), ClientPrefs.data.hitsoundVolume);

		if (note.hitCausesMiss)
		{
			if (!note.noMissAnimation)
			{
				switch (note.noteType)
				{
					case 'Hurt Note': // Hurt note
						if (boyfriend.animOffsets.exists('hurt'))
						{
							boyfriend.playAnim('hurt', true);
							boyfriend.specialAnim = true;
						}
				}
			}

			noteMiss(note);
			if (!note.noteSplashData.disabled && !note.isSustainNote)
				spawnNoteSplashOnNote(note);
			if (!note.isSustainNote)
				invalidateNote(note);
			return;
		}

		if (!note.noAnimation)
		{
			var animToPlay:String = singAnimation(note.noteData);

			var char:Character = boyfriend;
			var animCheck:String = 'hey';
			if (note.gfNote)
			{
				char = gf;
				animCheck = 'cheer';
			}

			if (char != null)
			{
				char.playAnim(animToPlay + note.animSuffix, true);
				char.holdTimer = 0;

				if (note.noteType == 'Hey!')
				{
					if (char.animOffsets.exists(animCheck))
					{
						char.playAnim(animCheck, true);
						char.specialAnim = true;
						char.heyTimer = 0.6;
					}
				}
			}
		}

		if (!cpuControlled)
		{
			var spr = playerStrums.members[note.noteData];
			if (spr != null)
				spr.playAnim('confirm', true);
		}
		else
			strumPlayAnim(false, Std.int(Math.abs(note.noteData)), Conductor.stepCrochet * 1.25 / 1000 / playbackRate);
		vocals.volume = 1;

		if (!note.isSustainNote)
		{
			combo++;
			if (combo > 9999)
				combo = 9999;
			if (combo > highestCombo)
				highestCombo = combo;
			notesHitArray.unshift(Date.now());
			popUpScore(note);
		}
		var gainHealth:Bool = true; // prevent health gain, *if* sustains are treated as a singular note
		if (guitarHeroSustains && note.isSustainNote)
			gainHealth = false;
		if (gainHealth)
			health += note.hitHealth * healthGain;

		stagesFunc(function(stage:BaseStage) stage.goodNoteHit(note));
		var result:Dynamic = callOnLuas('goodNoteHit', [notes.members.indexOf(note), leData, leType, isSus]);
		if (result != LuaUtils.Function_Stop && result != LuaUtils.Function_StopHScript && result != LuaUtils.Function_StopAll)
			callOnHScript('goodNoteHit', [note]);

		if (!note.isSustainNote)
			invalidateNote(note);
	}

	public inline function goodNoteHitForOpponent(note:Note):Void
	{
		var functionReturn:String = ClientPrefs.data.opponentCodeFix ? 'opponentNoteHitPre' : 'goodNoteHitPre';
		var result:Dynamic = callOnLuas(functionReturn, [
			notes.members.indexOf(note),
			Math.abs(note.noteData),
			note.noteType,
			note.isSustainNote
		]);
		if (result != LuaUtils.Function_Stop && result != LuaUtils.Function_StopHScript && result != LuaUtils.Function_StopAll)
			callOnHScript(functionReturn, [note]);

		if (note.noteType == 'Hey!' && boyfriend.animOffsets.exists('hey'))
		{
			boyfriend.playAnim('hey', true);
			boyfriend.specialAnim = true;
			boyfriend.heyTimer = 0.6;
		}
		else if (!note.noAnimation)
		{
			var char:Character = boyfriend;
			//var animToPlay:String = singAnimations[Std.int(Math.abs(Math.min(singAnimations.length - 1, note.noteData)))];
			var animToPlay:String = singAnimation(note.noteData);
			if (note.gfNote)
				char = gf;

			if (char != null)
			{
				char.playAnim(animToPlay, true);
				char.holdTimer = 0;
			}
		}

		if (ClientPrefs.data.healthDrainOPPO)
		{
			if (health > 0.4)
			{
				if (!(guitarHeroSustains && note.isSustainNote))
					health -= note.hitHealth * healthLoss * ClientPrefs.data.healthDrainOPPOMult;
				if (health <= 0.4)
					health = 0.4;
			}
		}

		if (!splitVocals)
			vocals.volume = 1;
		strumPlayAnim(false, Std.int(Math.abs(note.noteData)), Conductor.stepCrochet * 1.25 / 1000 / playbackRate);
		note.hitByOpponent = true;

		stagesFunc(function(stage:BaseStage) stage.opponentNoteHit(note));
		var functionReturn:String = ClientPrefs.data.opponentCodeFix ? 'opponentNoteHit' : 'goodNoteHit';
		var result:Dynamic = callOnLuas(functionReturn, [
			notes.members.indexOf(note),
			Math.abs(note.noteData),
			note.noteType,
			note.isSustainNote
		]);
		if (result != LuaUtils.Function_Stop && result != LuaUtils.Function_StopHScript && result != LuaUtils.Function_StopAll)
			callOnHScript(functionReturn, [note]);

		if (!note.isSustainNote)
			invalidateNote(note);
	}

	public function invalidateNote(note:Note):Void
	{
		killNotes.push(note); //为了防止某些神人用脚本调用这个函数我就保留了 -狐月影
	}

	public function destroyNotes():Void
	{
		var count:Int = killNotes.length;
		if (count == 0) return;
		var limit:Int = killNotesBudget;
		if (limit < 1) limit = count;
		if (limit > count) limit = count;
		var idx:Int = 0;
		while (idx < limit)
		{
			var note:Note = killNotes[idx];
			if (note != null)
			{
				if (note.tail.length != 0 && note.killTail)
				{
					var t:Int = 0;
					var tailLen:Int = note.tail.length;
					while (t < tailLen)
					{
						var sustain:Note = note.tail[t];
						if (sustain != null)
						{
							sustain.kill();
							notes.remove(sustain, true);
							sustainLayer.remove(sustain, true);
							sustain.destroy();
						}
						t++;
					}
				}
				note.kill();
				notes.remove(note, true);
				if (note.isSustainNote) sustainLayer.remove(note, true); else tapLayer.remove(note, true);
				note = FlxDestroyUtil.destroy(note);
			}
			idx++;
		}
		if (idx > 0) killNotes.splice(0, idx);
	}

	public function spawnNoteSplashOnNote(note:Note)
	{
		if (note != null)
		{
			var strum:StrumNote = ClientPrefs.data.playOpponent ? opponentStrums.members[note.noteData] : playerStrums.members[note.noteData];
			if (strum != null)
				spawnNoteSplash(strum.x, strum.y, note.noteData, note);
		}
	}

	public function spawnNoteSplash(x:Float, y:Float, data:Int, ?note:Note = null)
	{
		if (!ClientPrefs.data.showSplash)
			return;
		
		var splash:NoteSplash = grpNoteSplashes.recycle(NoteSplash);
		splash.setupNoteSplash(x, y, data, note);
		grpNoteSplashes.add(splash);
	}

	public inline function registerTempNote(note:Note):Void
	{
		if (note != null) tempNotes.push(note);
	}



	override function destroy()
	{
		if (DeepDebugTracker.active)
			DeepDebugTracker.finish(endingSong ? 'song_state_destroyed_after_end' : 'aborted_or_restarted');

		if (scripts.lua.CustomSubstate.instance != null)
		{
			closeSubState();
			resetSubState();
		}

		#if HSCRIPT_ALLOWED
		if (hscriptGrp != null)
			hscriptGrp.destroy(true);
		hscriptArray = null;
		hscriptGrp = null;
		#end

		#if LUA_ALLOWED
		for (lua in luaArray)
		{
			lua.call('onDestroy', []);
			lua.stop();
		}
		luaArray = [];
		FunkinLua.customFunctions.clear();
		#end

		stagesFunc(function(stage:BaseStage) stage.destroy());

		FlxG.animationTimeScale = 1;
		#if FLX_PITCH FlxG.sound.music.pitch = 1; #end
		Note.globalRgbShaders = [];
		games.backend.NoteTypesConfig.clearNoteTypesData();
		instance = null;

		if (Main.getReplayOverlay() != null)
			Main.getReplayOverlay().hideOverlay();

		@:privateAccess
		FlxG.game._filters = [];
		camGame.filters = camHUD.filters = camOther.filters = [];

		super.destroy();
	}

	var checkIfDesynced:Bool = false;
	var lastStepHit:Int = -1;

	override inline function stepHit()
	{
		if (FlxG.sound.music.time >= -ClientPrefs.data.noteOffset)
			checkIfDesynced = true;

		super.stepHit();

		if (curStep == lastStepHit)
		{
			return;
		}

		lastStepHit = curStep;
		setOnScripts('curStep', curStep);
		callOnScripts('onStepHit');
	}

	var lastBeatHit:Int = -1;

	override inline function beatHit()
	{
		if (lastBeatHit >= curBeat)
		{
			// trace('BEAT HIT: ' + curBeat + ', LAST HIT: ' + lastBeatHit);
			return;
		}

		iconP1.scale.set(1.3, 1.3);
		iconP2.scale.set(1.3, 1.3);

		iconP1.updateHitbox();
		iconP2.updateHitbox();

		characterBopper(curBeat);

		super.beatHit();
		lastBeatHit = curBeat;

		setOnScripts('curBeat', curBeat);
		callOnScripts('onBeatHit');
	}

	public function characterBopper(beat:Int):Void
	{
		if (gf != null
			&& beat % Math.round(gfSpeed * gf.danceEveryNumBeats) == 0
			&& !gf.getAnimationName().startsWith('sing')
			&& !gf.stunned)
			gf.dance();
		if (boyfriend != null
			&& beat % boyfriend.danceEveryNumBeats == 0
			&& !boyfriend.getAnimationName().startsWith('sing')
			&& !boyfriend.stunned)
			boyfriend.dance();
		if (dad != null && beat % dad.danceEveryNumBeats == 0 && !dad.getAnimationName().startsWith('sing') && !dad.stunned)
			dad.dance();
	}

	public function playerDance(force:Bool = false):Void
	{
		if (force
			|| boyfriend.animation.curAnim != null
			&& boyfriend.holdTimer > Conductor.stepCrochet * (0.0011 / FlxG.sound.music.pitch) * boyfriend.singDuration
				&& boyfriend.animation.curAnim.name.startsWith('sing')
				&& !boyfriend.animation.curAnim.name.endsWith('miss'))
			boyfriend.dance();
	}

	public function opponentDance(force:Bool = false):Void
	{
		if (force
			|| dad.animation.curAnim != null
			&& dad.holdTimer > Conductor.stepCrochet * (0.0011 / FlxG.sound.music.pitch) * dad.singDuration
				&& dad.animation.curAnim.name.startsWith('sing')
				&& !dad.animation.curAnim.name.endsWith('miss'))
			dad.dance();
	}

	override inline function sectionHit()
	{
		if (SONG.notes[curSection] != null)
		{
			if (generatedMusic && !endingSong && !isCameraOnForcedPos)
				moveCameraSection();

			if (camZooming && FlxG.camera.zoom < 1.35 && ClientPrefs.data.camZooms)
			{
				FlxG.camera.zoom += 0.015 * camZoomingMult;
				camHUD.zoom += 0.03 * camZoomingMult;
			}

			if (SONG.notes[curSection].changeBPM)
			{
				Conductor.bpm = SONG.notes[curSection].bpm;
				setOnScripts('curBpm', Conductor.bpm);
				setOnScripts('crochet', Conductor.crochet);
				setOnScripts('stepCrochet', Conductor.stepCrochet);
			}
			setOnScripts('mustHitSection', SONG.notes[curSection].mustHitSection);
			setOnScripts('altAnim', SONG.notes[curSection].altAnim);
			setOnScripts('gfSection', SONG.notes[curSection].gfSection);
		}
		super.sectionHit();

		setOnScripts('curSection', curSection);
		callOnScripts('onSectionHit');
	}

	#if LUA_ALLOWED
	public function startLuasNamed(luaFile:String)
	{
		#if MODS_ALLOWED
		var luaToLoad:String = Paths.modFolders(luaFile);
		if (!FileSystem.exists(luaToLoad))
			luaToLoad = Paths.getSharedPath(luaFile);

		if (FileSystem.exists(luaToLoad))
		#elseif sys
		var luaToLoad:String = Paths.getSharedPath(luaFile);
		if (Assets.exists(luaToLoad))
		#end
		{
			for (script in luaArray)
				if (script.scriptName == luaToLoad)
					return false;

			new FunkinLua(luaToLoad);
			return true;
		}
		return false;
	}
	#end

	#if HSCRIPT_ALLOWED
	public function startHScriptsNamed(scriptFile:String)
	{
		#if MODS_ALLOWED
		var scriptToLoad:String = Paths.modFolders(scriptFile);
		if (!FileSystem.exists(scriptToLoad))
			scriptToLoad = Paths.getSharedPath(scriptFile);
		#else
		var scriptToLoad:String = Paths.getSharedPath(scriptFile);
		#end

		if (FileSystem.exists(scriptToLoad))
		{
			initHScript(scriptToLoad);
			return true;
		}
		return false;
	}

	public function initHScript(file:String)
	{
		var newScript:HScript = new HScript(file, this);
		trace('initialized hscript interp successfully: $file');
		hscriptGrp.add(newScript);
	}
	#end

	public function callOnScripts(funcToCall:String, args:Array<Dynamic> = null, ignoreStops = false, exclusions:Array<String> = null,
			excludeValues:Array<Dynamic> = null):Dynamic
	{
		var returnVal:Dynamic = LuaUtils.Function_Continue;
		if (args == null)
			args = [];
		if (exclusions == null)
			exclusions = [];
		if (excludeValues == null)
			excludeValues = [LuaUtils.Function_Continue];

		var result:Dynamic = callOnLuas(funcToCall, args, ignoreStops, exclusions, excludeValues);
		if (result == null || excludeValues.contains(result))
			result = callOnHScript(funcToCall, args, ignoreStops, exclusions, excludeValues);
		return result;
	}

	public function callOnLuas(funcToCall:String, args:Array<Dynamic> = null, ignoreStops = false, exclusions:Array<String> = null,
			excludeValues:Array<Dynamic> = null):Dynamic
	{
		var returnVal:Dynamic = LuaUtils.Function_Continue;
		#if LUA_ALLOWED
		if (args == null)
			args = [];
		if (exclusions == null)
			exclusions = [];
		if (excludeValues == null)
			excludeValues = [LuaUtils.Function_Continue];

		var arr:Array<FunkinLua> = [];
		for (script in luaArray)
		{
			if (script.closed)
			{
				arr.push(script);
				continue;
			}

			if (exclusions.contains(script.scriptName))
				continue;

			var myValue:Dynamic = script.call(funcToCall, args);
			if ((myValue == LuaUtils.Function_StopLua || myValue == LuaUtils.Function_StopAll)
				&& !excludeValues.contains(myValue)
				&& !ignoreStops)
			{
				returnVal = myValue;
				break;
			}

			if (myValue != null && !excludeValues.contains(myValue))
				returnVal = myValue;

			if (script.closed)
				arr.push(script);
		}

		if (arr.length > 0)
			for (script in arr)
				luaArray.remove(script);
		#end
		return returnVal;
	}

	public function callOnHScript(funcToCall:String, args:Array<Dynamic> = null, ?ignoreStops:Bool = false, exclusions:Array<String> = null,
			excludeValues:Array<Dynamic> = null):Dynamic
	{
		var returnVal:Dynamic = LuaUtils.Function_Continue;

		#if HSCRIPT_ALLOWED
		if (exclusions == null)
			exclusions = new Array();
		if (excludeValues == null)
			excludeValues = new Array();
		excludeValues.push(LuaUtils.Function_Continue);

		var len:Int = hscriptArray.length;
		if (len < 1)
			return returnVal;

		for (script in hscriptArray)
		{
			@:privateAccess
			if (script == null || exclusions.contains(script.origin))
				continue;

			var myValue = script.call(funcToCall, args);
			{

				if ((myValue == LuaUtils.Function_StopHScript || myValue == LuaUtils.Function_StopAll)
					&& !excludeValues.contains(myValue)
					&& !ignoreStops)
				{
					returnVal = myValue;
					break;
				}

				if (myValue != null && !excludeValues.contains(myValue))
					returnVal = myValue;
			}
		}
		#end

		return returnVal;
	}

	public function setOnScripts(variable:String, arg:Dynamic, exclusions:Array<String> = null)
	{
		if (exclusions == null)
			exclusions = [];
		setOnLuas(variable, arg, exclusions);
		setOnHScript(variable, arg, exclusions);
	}

	public function setOnLuas(variable:String, arg:Dynamic, exclusions:Array<String> = null)
	{
		#if LUA_ALLOWED
		if (exclusions == null)
			exclusions = [];
		for (script in luaArray)
		{
			if (exclusions.contains(script.scriptName))
				continue;

			script.set(variable, arg);
		}
		#end
	}

	public function setOnHScript(variable:String, arg:Dynamic, exclusions:Array<String> = null)
	{
		#if HSCRIPT_ALLOWED
		if (exclusions == null)
			exclusions = [];
		for (script in hscriptArray)
		{
			if (exclusions.contains(script.origin))
				continue;

			if (!instancesExclude.contains(variable))
				instancesExclude.push(variable);
			script.set(variable, arg);
		}
		#end
	}

	function strumPlayAnim(isDad:Bool, id:Int, time:Float)
	{
		var spr:StrumNote = null;
		if (isDad)
		{
			spr = opponentStrums.members[id];
		}
		else
		{
			spr = playerStrums.members[id];
		}

		if (spr != null)
		{
			spr.playAnim('confirm', true);
			spr.resetAnim = time;
		}
	}

	public var ratingName:String = 'N/A';
	public var ratingPercent:Float;
	public var ratingFC:String;

	public function RecalculateRating(badHit:Bool = false)
	{
		setOnScripts('score', songScore);
		setOnScripts('misses', songMisses);
		setOnScripts('hits', songHits);
		setOnScripts('combo', combo);

		var ret:Dynamic = callOnScripts('onRecalculateRating', null, true);
		if (ret != LuaUtils.Function_Stop)
		{
			ratingName = 'N/A';
			if (totalPlayed != 0) // Prevent divide by 0
			{
				// Rating Percent
				ratingPercent = Math.min(1, Math.max(0, totalNotesHit / totalPlayed));
				// trace((totalNotesHit / totalPlayed) + ', Total: ' + totalPlayed + ', notes hit: ' + totalNotesHit);

				// Rating Name
				ratingName = ratingStuff[ratingStuff.length - 1][0]; // Uses last string
				if (ratingPercent < 1)
					for (i in 0...ratingStuff.length - 1)
						if (ratingPercent < ratingStuff[i][1])
						{
							ratingName = ratingStuff[i][0];
							break;
						}
			}
			fullComboFunction();
		}
		updateScore(badHit); // score will only update after rating is calculated, if it's a badHit, it shouldn't bounce
		setOnScripts('rating', ratingPercent);
		setOnScripts('ratingName', ratingName);
		setOnScripts('ratingFC', ratingFC);
	}

	#if ACHIEVEMENTS_ALLOWED
	private function checkForAchievement(achievesToCheck:Array<String> = null)
	{
		if (chartingMode)
			return;

		var usedPractice:Bool = (ClientPrefs.getGameplaySetting('practice') || ClientPrefs.getGameplaySetting('botplay'));
		if (ClientPrefs.data.playOpponent ? cpuControlled_opponent : cpuControlled)
			return;

		for (name in achievesToCheck)
		{
			if (!Achievements.exists(name))
				continue;

			var unlock:Bool = false;
			if (name != WeekData.getWeekFileName() + '_nomiss') // common achievements
			{
				switch (name)
				{
					case 'ur_bad':
						unlock = (ratingPercent < 0.2 && !practiceMode);

					case 'ur_good':
						unlock = (ratingPercent >= 1 && !usedPractice);

					case 'oversinging':
						unlock = (boyfriend.holdTimer >= 10 && !usedPractice);

					case 'hype':
						unlock = (!boyfriendIdled && !usedPractice);

					case 'two_keys':
						unlock = (!usedPractice && keysPressed.length <= 2);

					case 'toastie':
						unlock = (!ClientPrefs.data.cacheOnGPU && !ClientPrefs.data.shaders && ClientPrefs.data.lowQuality && !ClientPrefs.data.antialiasing);

					case 'debugger':
						unlock = (songName == 'test' && !usedPractice);
				}
			}
			else // any FC achievements, name should be "weekFileName_nomiss", e.g: "week3_nomiss";
			{
				if (isStoryMode
					&& campaignMisses + songMisses < 1
					&& Difficulty.getString().toUpperCase() == 'HARD'
					&& storyPlaylist.length <= 1
					&& !changedDifficulty
					&& !usedPractice)
					unlock = true;
			}

			if (unlock)
				Achievements.unlock(name);
		}
	}
	#end

	#if (!flash && sys)
	public var runtimeShaders:Map<String, Array<String>> = new Map<String, Array<String>>();

	public function createRuntimeShader(shaderName:String):ErrorHandledRuntimeShader
	{
		#if (!flash && sys)
		if (!ClientPrefs.data.shaders)
			return new ErrorHandledRuntimeShader(shaderName);

		if (!runtimeShaders.exists(shaderName) && !initLuaShader(shaderName))
		{
			FlxG.log.warn('Shader $shaderName is missing!');
			return new ErrorHandledRuntimeShader(shaderName);
		}

		var arr:Array<String> = runtimeShaders.get(shaderName);
		return new ErrorHandledRuntimeShader(shaderName, arr[0], arr[1]);
		#else
		FlxG.log.warn("Platform unsupported for Runtime Shaders!");
		return null;
		#end
	}

	public function initLuaShader(name:String, ?glslVersion:Int = 120)
	{
		if (!ClientPrefs.data.shaders)
			return false;

		#if (MODS_ALLOWED && !flash && sys)
		if (runtimeShaders.exists(name))
		{
			FlxG.log.warn('Shader $name was already initialized!');
			return true;
		}

		for (folder in Mods.directoriesWithFile(Paths.getSharedPath(), 'shaders/'))
		{
			var frag:String = folder + name + '.frag';
			var vert:String = folder + name + '.vert';
			var found:Bool = false;
			if (FileSystem.exists(frag))
			{
				frag = File.getContent(frag);
				found = true;
			}
			else
				frag = null;

			if (FileSystem.exists(vert))
			{
				vert = File.getContent(vert);
				found = true;
			}
			else
				vert = null;

			if (found)
			{
				runtimeShaders.set(name, [frag, vert]);
				// trace('Found shader $name!');
				return true;
			}
		}
		#if (LUA_ALLOWED || HSCRIPT_ALLOWED)
		addTextToDebug('Missing shader $name .frag AND .vert files!', FlxColor.RED);
		#else
		FlxG.log.warn("Missing shader $name .frag AND .vert files!");
		#end
		#else
		FlxG.log.warn("This platform doesn\'t support Runtime Shaders!");
		#end
		return false;
	}
	#end

	public function makeLuaVirtualPad(DPadMode:String, ActionMode:String)
	{
		if (members.contains(luaVirtualPad))
			return;

		if (!variables.exists("luaVirtualPad"))
			variables.set("luaVirtualPad", luaVirtualPad);

		luaVirtualPad = new FlxVirtualPad(Data.dpadMode.get(DPadMode), Data.actionMode.get(ActionMode));
		luaVirtualPad.alpha = ClientPrefs.data.controlsAlpha;
	}

	public function addLuaVirtualPad()
	{
		if (luaVirtualPad == null || members.contains(luaVirtualPad))
			return;

		var target = LuaUtils.getTargetInstance();
		target.insert(target.members.length + 1, luaVirtualPad);
	}

	public function addLuaVirtualPadCamera()
	{
		if (luaVirtualPad != null)
			luaVirtualPad.cameras = [luaVpadCam];
	}

	public function removeLuaVirtualPad()
	{
		if (luaVirtualPad != null)
		{
			luaVirtualPad.kill();
			luaVirtualPad.destroy();
			remove(luaVirtualPad);
			luaVirtualPad = null;
		}
	}

	public function luaVirtualPadPressed(button:Dynamic):Bool
	{
		if (luaVirtualPad != null)
		{
			if (Std.isOfType(button, String))
				return luaVirtualPad.buttonPressed(FlxKey.fromString(button));
			else if (Std.isOfType(button, Array))
			{
				var FUCK:Array<String> = button; // haxe said "You Can't Iterate On A Dyanmic Value Please Specificy Iterator or Iterable *insert ned emoji*" so that's the only i foud to fix
				var idArray:Array<FlxKey> = [];
				for (strId in FUCK)
					idArray.push(FlxKey.fromString(strId));
				return luaVirtualPad.anyPressed(idArray);
			}
			else
				return false;
		}
		return false;
	}

	public function luaVirtualPadJustPressed(button:Dynamic):Bool
	{
		if (luaVirtualPad != null)
		{
			if (Std.isOfType(button, String))
				return luaVirtualPad.buttonJustPressed(FlxKey.fromString(button));
			else if (Std.isOfType(button, Array))
			{
				var FUCK:Array<String> = button;
				var idArray:Array<FlxKey> = [];
				for (strId in FUCK)
					idArray.push(FlxKey.fromString(strId));
				return luaVirtualPad.anyJustPressed(idArray);
			}
			else
				return false;
		}
		return false;
	}

	public function luaVirtualPadJustReleased(button:Dynamic):Bool
	{
		if (luaVirtualPad != null)
		{
			if (Std.isOfType(button, String))
				return luaVirtualPad.buttonJustReleased(FlxKey.fromString(button));
			else if (Std.isOfType(button, Array))
			{
				var FUCK:Array<String> = button;
				var idArray:Array<FlxKey> = [];
				for (strId in FUCK)
					idArray.push(FlxKey.fromString(strId));
				return luaVirtualPad.anyJustReleased(idArray);
			}
			else
				return false;
		}
		return false;
	}
}
