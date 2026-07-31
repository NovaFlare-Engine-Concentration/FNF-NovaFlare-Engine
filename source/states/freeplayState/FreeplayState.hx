package states.freeplayState;

import haxe.Json;
import haxe.ds.ArraySort;

import sys.thread.Mutex;
import sys.io.File;

import openfl.system.System;
import openfl.display.BitmapData;
import openfl.display.BitmapDataChannel;
import openfl.geom.Point;
import openfl.geom.Rectangle;
import flixel.graphics.FlxGraphic;

import developer.editors.ChartingState;

import options.OptionsState;

import states.mainMenuState.MainMenuState;
import states.storyMenuState.StoryMenuState;
import states.modsMenuState.ModsMenuState;
import states.freeplayState.backend.*;
import states.freeplayState.objects.detail.*;
import states.freeplayState.objects.down.*;
import states.freeplayState.objects.others.*;
import states.freeplayState.objects.select.*;
import states.freeplayState.objects.song.*;
import states.freeplayState.objects.replay.*;

import states.freeplayState.objects.replay.ReplayRect.ReplaySortMode;
import states.freeplayState.objects.replay.ReplayRect.ReplayData;

import substates.GameplayChangersSubstate;
import substates.ResetScoreSubState;

import games.backend.WeekData;
import games.backend.Highscore;
import games.backend.Song;
import games.backend.Song.SwagSong;
import games.backend.StageData;
import games.backend.Replay;
import games.backend.Replay.StateRecord;
import substates.ResultsScreen;
import games.backend.diffCalc.DiffRating;
import general.shapeEx.RoundRect;
import general.shapeEx.RoundRect.OriginType;
import general.objects.screen.MouseEffect;

class FreeplayState extends MusicBeatState
{
	static public var filePath:String = 'menuExtendHide/freeplay/';
	static public var instance:FreeplayState;
	
	static public var curSelected:Int = 0;
	static public var curDifficulty:Int = -1;
	public var curFunc:Int = -1;
	static public var curFuncBack:Int = 0;

	public var keyboardState:Int = 0;

	public var stopAll:Bool = false;

	///////////////////////////////////////////////////////////////////////////////////////////////

	var songsData:Array<SongMetadata> = [];

	public var songGroup:Array<SongRect> = [];
	public var songsMove:MouseMove;

	var camBG:FlxCamera;
	var camSongs:FlxCamera;
	var camReplay:FlxCamera;
	var camAfter:FlxCamera;

	public static var vocalsPlayer1:FlxSound;
	public static var vocalsPlayer2:FlxSound;

	public var mouseEvent:MouseEvent;

	///////////////////////////////////////////////////////////////////////////////////////////////

	var background:ChangeSprite;
	var intendedColor:Int;
	var backgroundRequestId:Int = 0;
	var backgroundLoadTimer:FlxTimer;
	var selectedBackgroundGraphic:FlxGraphic;
	var detailRequestId:Int = 0;
	var detailLoadTimer:FlxTimer;
	var stateDestroyed:Bool = false;

	var detailRect:DetailRect;

	var detailSongName:FlxText;
	var detailMusican:FlxText;

	var detailPlaySign:FlxSprite;
	var detailPlayText:FlxText;

	var detailTimeSign:FlxSprite;
	var detailTimeText:FlxText;

	var detailBpmSign:FlxSprite;
	var detailBpmText:FlxText;

	var detailRate:StarRect;
	var detailMapper:FlxText;

	var noteData:DataDis;
	var holdNoteData:DataDis;
	var speedData:DataDis;
	var keyCountData:DataDis;

	///////////////////////////////////////////////////////////////////////////////////////////////

	var replayGroup:Array<ReplayRect> = [];
	public var replayMove:MouseMove;
	public var replaySortMode:ReplaySortMode = DATE_DESC;
	public var replayPosiData:Float = 0;
	public var replayStartX:Float = 15;
	public var replayStartY:Float = 300;
	public var replaySlope:Float = 0.20;

	var replaySortBtn:Array<RoundRect> = [];
	var replaySortLabel:Array<FlxText> = [];
	var replaySortText:FlxText;
	var replayNoDataText:FlxText;
	var replayTitleText:FlxText;

	///////////////////////////////////////////////////////////////////////////////////////////////

	var funcData:Array<String> = ['options', 'mod', 'changer', 'editor', 'reset', 'random'];
	var funcColors:Array<FlxColor> = [0x63d6ff, 0xd1fc52, 0xff354e, 0xff617e, 0xfd6dff, 0x6dff6d];
	var downBG:Rect;
	var backRect:BackButton;
	var funcGroup:Array<FuncButton> = [];

	///////////////////////////////////////////////////////////////////////////////////////////////

	var selectedBG:SkewRoundRect;
	public var searchButton:SearchButton;

	public var isSearchActive:Bool = false;
	public var searchJustUnfocused:Bool = false;

	var noMatchText:FlxText;
	var searchCountText:FlxText;

	override function create()
	{
		super.create();

		Song.forceEngineVersion = null;

		instance = this;
		// The global star trail is implemented as a separate OpenFL display
		// list.  On this shader-heavy page it made a 1000 Hz mouse allocate
		// roughly 25 MB/s extra and reduced the measured frame rate to ~100.
		// Click feedback remains active and other states still use the trail.
		MouseEffect.trailEnabled = false;

		FlxG.mouse.visible = !ClientPrefs.data.needMobileControl;

		mouseEvent = new MouseEvent();
		add(mouseEvent);

		persistentUpdate = true;
		PlayState.isStoryMode = false;
		WeekData.reloadWeekFiles(false);

		#if DISCORD_ALLOWED
		// Updating Discord Rich Presence
		DiscordClient.changePresence("In the Menus", null);
		#end
		
		for (i in 0...WeekData.weeksList.length)
		{
			if (weekIsLocked(WeekData.weeksList[i]))
				continue;

			var leWeek:WeekData = WeekData.weeksLoaded.get(WeekData.weeksList[i]);

			WeekData.setDirectoryFromWeek(leWeek);
			
			for (song in leWeek.songs)
			{
				var colors:Array<Int> = song[2];
				if (colors == null || colors.length < 3)
				{
					colors = [146, 113, 253];
				}
				var muscan:String = song[3];
				if (song[3] == null)
					muscan = 'N/A';
				var charter:Array<String> = song[4];
				if (song[4] == null)
					charter = ['N/A', 'N/A', 'N/A'];
				songsData.push(new SongMetadata(song[0], i, song[1], muscan, charter, colors));
			}
		}

		Mods.loadTopMod();
		
		//////////////////////////////////////////////////////////////////////////////////////////

		// Reuse the state's existing camera for the background.  The old layout
		// kept that camera alive and then added four more full-screen render
		// surfaces, so every Freeplay frame cleared/composited five 1280x720
		// layers even though only three independent layer groups are required.
		camBG = FlxG.camera;
		camBG.bgColor = 0x00000000;
		camSongs = new FlxCamera();
		camSongs.bgColor = 0x00000000;
		// These are explicit layer cameras, not default draw targets.  Replay
		// objects are created after song rows, so sharing their camera preserves
		// the original visual order without another full-screen surface.
		FlxG.cameras.add(camSongs, false);
		camReplay = camSongs;
		camAfter = new FlxCamera();
		camAfter.bgColor = 0x00000000;
		FlxG.cameras.add(camAfter, false);
		// These four OpenFL sprites are render surfaces, not UI controls. Leaving
		// them mouse-enabled makes Stage hit-test every full-screen camera layer
		// for each MOUSE_MOVE before Flixel receives the same global coordinates.
		for (renderCamera in [camBG, camSongs, camAfter])
		{
			renderCamera.flashSprite.mouseEnabled = false;
			renderCamera.flashSprite.mouseChildren = false;
		}

		background = new ChangeSprite(0, 0).load(Paths.image('menuDesat'), 1.05);
		background.antialiasing = ClientPrefs.data.antialiasing;
		background.camera = camBG;
		add(background);
		// Selected backgrounds are blurred once on the loader thread. Rendering
		// the Gaussian kernel as a full-screen sprite shader cost nine texture
		// reads per pixel forever (eighteen during a cross-fade), which limited
		// this otherwise static menu to tens of frames per second.
		background.setAllowMove(false);

		detailRect = new DetailRect(0, 0);
		detailRect.camera = camAfter;
		add(detailRect);

		detailSongName = new FlxText(0, 0, 0, 'songName', Std.int(detailRect.bg1.height * 0.25));
		detailSongName.setFormat(Paths.font(Language.get('fontName', 'main') + '.ttf'), Std.int(detailRect.bg1.height * 0.15), 0xFFFFFFFF, LEFT, FlxTextBorderStyle.OUTLINE, 0xFFFFFFFF);
        detailSongName.borderStyle = NONE;
		detailSongName.antialiasing = ClientPrefs.data.antialiasing;
		detailSongName.x = 10;
		detailSongName.camera = camAfter;
		add(detailSongName);

		detailMusican = new FlxText(0, 0, 0, 'musican', Std.int(detailRect.bg1.height * 0.25));
		detailMusican.setFormat(Paths.font(Language.get('fontName', 'main') + '.ttf'), Std.int(detailRect.bg1.height * 0.09), 0xFFFFFFFF, LEFT, FlxTextBorderStyle.OUTLINE, 0xFFFFFFFF);
        detailMusican.borderStyle = NONE;
		detailMusican.antialiasing = ClientPrefs.data.antialiasing;
		detailMusican.x = detailSongName.x;
		detailMusican.y = detailSongName.y + detailSongName.textField.textHeight;
		detailMusican.camera = camAfter;
		add(detailMusican);

		detailPlaySign = new FlxSprite(0).loadGraphic(Paths.image(filePath + 'playedCount'));
		detailPlaySign.setGraphicSize(25, 25);
		detailPlaySign.updateHitbox();
		detailPlaySign.antialiasing = ClientPrefs.data.antialiasing;
		detailPlaySign.x = detailSongName.x;
		detailPlaySign.y = detailMusican.y + detailMusican.height + 5;
		detailPlaySign.camera = camAfter;
		//detailPlaySign.offset.set(0,0);
		add(detailPlaySign);

		detailPlayText = new FlxText(0, 0, 0, '0', Std.int(detailRect.bg1.height * 0.25));
		detailPlayText.setFormat(Paths.font(Language.get('fontName', 'main') + '.ttf'), Std.int(detailRect.bg1.height * 0.09), 0xFFFFFFFF, LEFT, FlxTextBorderStyle.OUTLINE, 0xFFFFFFFF);
        detailPlayText.borderStyle = NONE;
		detailPlayText.antialiasing = ClientPrefs.data.antialiasing;
		detailPlayText.x = detailPlaySign.x + detailPlaySign.width + 5;
		detailPlayText.y = detailPlaySign.y + (detailPlaySign.height - detailPlayText.height) / 2;
		detailPlayText.camera = camAfter;
		add(detailPlayText);

		detailTimeSign = new FlxSprite(0).loadGraphic(Paths.image(filePath + 'songTime'));
		detailTimeSign.setGraphicSize(25, 25);
		detailTimeSign.updateHitbox();
		detailTimeSign.antialiasing = ClientPrefs.data.antialiasing;
		detailTimeSign.x = detailSongName.x + 150;
		detailTimeSign.camera = camAfter;
		detailTimeSign.y = detailPlaySign.y;
		//detailTimeSign.offset.set(0,0);
		add(detailTimeSign);

		detailTimeText = new FlxText(0, 0, 0, '1:00', Std.int(detailRect.bg1.height * 0.25));
		detailTimeText.setFormat(Paths.font(Language.get('fontName', 'main') + '.ttf'), Std.int(detailRect.bg1.height * 0.09), 0xFFFFFFFF, LEFT, FlxTextBorderStyle.OUTLINE, 0xFFFFFFFF);
        detailTimeText.borderStyle = NONE;
		detailTimeText.antialiasing = ClientPrefs.data.antialiasing;
		detailTimeText.x = detailTimeSign.x + detailTimeSign.width + 5;
		detailTimeText.y = detailTimeSign.y + (detailTimeSign.height - detailTimeText.height) / 2;
		detailTimeText.camera = camAfter;
		add(detailTimeText);

		detailBpmSign = new FlxSprite(0).loadGraphic(Paths.image(filePath + 'bpmCount'));
		detailBpmSign.setGraphicSize(25, 25);
		detailBpmSign.updateHitbox();
		detailBpmSign.antialiasing = ClientPrefs.data.antialiasing;
		detailBpmSign.x = detailSongName.x + 300;
		detailBpmSign.camera = camAfter;
		detailBpmSign.y = detailPlaySign.y;
		//detailBpmSign.offset.set(0,0);
		add(detailBpmSign);

		detailBpmText = new FlxText(0, 0, 0, '300', Std.int(detailRect.bg1.height * 0.25));
		detailBpmText.setFormat(Paths.font(Language.get('fontName', 'main') + '.ttf'), Std.int(detailRect.bg1.height * 0.09), 0xFFFFFFFF, LEFT, FlxTextBorderStyle.OUTLINE, 0xFFFFFFFF);
        detailBpmText.borderStyle = NONE;
		detailBpmText.antialiasing = ClientPrefs.data.antialiasing;
		detailBpmText.x = detailBpmSign.x + detailBpmSign.width + 5;
		detailBpmText.y = detailBpmSign.y + (detailBpmSign.height - detailBpmText.height) / 2;
		detailBpmText.camera = camAfter;
		add(detailBpmText);

		detailRate = new StarRect(detailSongName.x, detailRect.bg2.y, 80, (detailRect.bg2.height - detailRect.bg3.height) * 0.7);
		detailRate.y += (detailRect.bg2.height - detailRect.bg3.height) * 0.5 - detailRate.height * 0.5;
		add(detailRate);

		detailMapper = new FlxText(0, 0, 0, 'Rate 0.99 mapped by test', Std.int(detailRect.bg1.height * 0.25));
		detailMapper.setFormat(Paths.font(Language.get('fontName', 'main') + '.ttf'), Std.int((detailRect.bg2.height - detailRect.bg3.height) * 0.7 * 0.6), 0xFFFFFFFF, LEFT, FlxTextBorderStyle.OUTLINE, 0xFFFFFFFF);
        detailMapper.borderStyle = NONE;
		detailMapper.antialiasing = ClientPrefs.data.antialiasing;
		detailMapper.x = detailRate.x + detailRate.width + 10;
		detailMapper.y = detailRect.bg2.y + (detailRect.bg2.height - detailRect.bg3.height) * 0.5 - detailMapper.height * 0.5;
		detailMapper.camera = camAfter;
		detailMapper.color = 0x9bff7a;
		add(detailMapper);


		noteData = new DataDis(10, detailRect.bg3.y + 5, 120, 5, 'Notes', 0, 100, 0);
		noteData.camera = camAfter;
		noteData.allowTweenDecimal = noteData.allowDecimal = false;
		add(noteData);

		holdNoteData = new DataDis(noteData.x + noteData.lineDis.width * 1.2, detailRect.bg3.y + 8, 120, 5, 'Hold Notes', 0, 100, 0);
		holdNoteData.camera = camAfter;
		holdNoteData.allowTweenDecimal = holdNoteData.allowDecimal = false;
		add(holdNoteData);

		speedData = new DataDis(holdNoteData.x + holdNoteData.lineDis.width * 1.2, detailRect.bg3.y + 8, 120, 5, 'Speed', 0, 4, 0);
		speedData.camera = camAfter;
		add(speedData);

		keyCountData = new DataDis(speedData.x + speedData.lineDis.width * 1.2, detailRect.bg3.y + 8, 120, 5, 'Key count', 0, 9, 0);
		keyCountData.camera = camAfter;
		keyCountData.allowTweenDecimal = keyCountData.allowDecimal = false;
		add(keyCountData);

		//////////////////////////////////////////////////////////////////////////////////////////

		for (i in 0...songsData.length)
		{
			Mods.currentModDirectory = songsData[i].folder;
			var data = songsData[i];
			var rect = new SongRect(data.songName, data.songCharacter, data.songMusican, data.songCharter, data.color);
			rect.id = i;
			add(rect);
			songGroup.push(rect);
			rect.camera = camSongs;
		}

		songsMove = new MouseMove(FreeplayState, 'songPosiData', 
								[songPosiData - (songGroup.length + 1) * SongRect.fixHeight, FlxG.height * 0.5 - SongRect.fixHeight * 0.5],
								[	
									[FlxG.width * 0.6, FlxG.width], 
									[0, FlxG.height]
								],
								songMoveEvent);
		songsMove.useLerp = true;
		songsMove.lerpSmooth = 8;
		songsMove.forceUpdateEvent = false;
		add(songsMove);

		////////////////////////////////////////////////////////////////////////////////////////////////////////////////

				//////////////////////////////////////////////////////////////////////////////////////////

		replayTitleText = new FlxText(replayStartX, replayStartY - 50, 300, 'Local Replays', 18);
		replayTitleText.setFormat(Paths.font(Language.get('fontName', 'main') + '.ttf'), 18, 0xFFFFFFFF, LEFT);
		replayTitleText.borderStyle = NONE;
		replayTitleText.antialiasing = ClientPrefs.data.antialiasing;
		replayTitleText.cameras = [camReplay];
		add(replayTitleText);

		var sortModes:Array<{label:String, mode:ReplaySortMode}> = [
			{label: 'Date', mode: DATE_DESC},
			{label: 'Score', mode: SCORE_DESC},
			{label: 'Acc', mode: ACC_DESC},
			{label: 'Combo', mode: COMBO_DESC},
		];
		for (i in 0...sortModes.length)
		{
			var btnX:Float = replayStartX + 225 + i * 100;
			var btnY:Float = replayStartY - 52;
			var sel:Bool = (replaySortMode == sortModes[i].mode);
			var btn:RoundRect = new RoundRect(btnX, btnY, 80, 24, 8, OriginType.LEFT_UP, 0xFFFFFFFF);
			btn.alpha = sel ? 1.0 : 0.35;
			btn.cameras = [camReplay];
			btn.ID = i;
			add(btn);
			replaySortBtn.push(btn);

			var label:FlxText = new FlxText(btnX, btnY, 80, sortModes[i].label, 12);
			label.setFormat(Paths.font(Language.get('fontName', 'main') + '.ttf'), 12, sel ? 0xFF000000 : 0xFFFFFFFF, CENTER);
			label.borderStyle = NONE;
			label.antialiasing = ClientPrefs.data.antialiasing;
			label.cameras = [camReplay];
			label.alignment = CENTER;
			label.y += (24 - label.height) / 2;
			add(label);
			replaySortLabel.push(label);
		}

		replaySortText = new FlxText(replayStartX, replayStartY - 20, 620, '', 13);
		replaySortText.setFormat(Paths.font(Language.get('fontName', 'main') + '.ttf'), 13, 0x88FFFFFF, LEFT);
		replaySortText.borderStyle = NONE;
		replaySortText.antialiasing = ClientPrefs.data.antialiasing;
		replaySortText.cameras = [camReplay];
		add(replaySortText);

		replayNoDataText = new FlxText(replayStartX, replayStartY + 10, ReplayRect.fixWidth, 'No replays found', 16);
		replayNoDataText.setFormat(Paths.font(Language.get('fontName', 'main') + '.ttf'), 16, 0x55FFFFFF, CENTER);
		replayNoDataText.borderStyle = NONE;
		replayNoDataText.antialiasing = ClientPrefs.data.antialiasing;
		replayNoDataText.cameras = [camReplay];
		replayNoDataText.visible = false;
		add(replayNoDataText);

		replayMove = new MouseMove(this, 'replayPosiData',
			[0, 0],
			[[replayStartX, replayStartX + ReplayRect.fixWidth], [replayStartY, FlxG.height - 60]]);
		replayMove.useLerp = true;
		replayMove.lerpSmooth = 10;
		replayMove.mouseWheelSensitivity = -1000;
		replayMove.event = replayMoveEvent;
		replayMove.forceUpdateEvent = false;
		add(replayMove);

		//////////////////////////////////////////////////////////////////////////////////////////
		
		selectedBG = new SkewRoundRect(0, -20, 680, 90, 20, 20, -10, 0, 0x000000, 0.4);
        selectedBG.antialiasing = ClientPrefs.data.antialiasing;
		selectedBG.x += FlxG.width - selectedBG.width + 95;
        add(selectedBG);
		selectedBG.cameras = [camAfter];

		searchButton = new SearchButton(695, 5);
		add(searchButton);
		searchButton.cameras = [camAfter];
		searchButton.onSearchChange = startSearch;

		noMatchText = new FlxText(searchButton.x, searchButton.y + searchButton.height + 15, 0, 'No songs matched', 24);
		noMatchText.setFormat(Paths.font(Language.get('fontName', 'main') + '.ttf'), 24, 0xFFFFFFFF, LEFT, FlxTextBorderStyle.OUTLINE, 0xFFFFFFFF);
		noMatchText.borderStyle = NONE;
		noMatchText.antialiasing = ClientPrefs.data.antialiasing;
		noMatchText.alpha = 0.6;
		noMatchText.cameras = [camAfter];
		noMatchText.visible = false;
		add(noMatchText);

		searchCountText = new FlxText(searchButton.x, searchButton.y + searchButton.height + 10, 0, '', 16);
		searchCountText.setFormat(Paths.font(Language.get('fontName', 'main') + '.ttf'), 16, 0x88FFFFFF, RIGHT);
		searchCountText.borderStyle = NONE;
		searchCountText.antialiasing = ClientPrefs.data.antialiasing;
		searchCountText.cameras = [camAfter];
		searchCountText.visible = true;
		searchCountText.text = '${songGroup.length} charts';
		add(searchCountText);

		//////////////////////////////////////////////////////////////////////////////////////////

		downBG = new Rect(0, FlxG.height - 49, FlxG.width + 10, 51, 0, 0, 0.8); //嗯卧槽怎么全屏会漏
		downBG.color = 0x242A2E;
		add(downBG);
		downBG.cameras = [camAfter];

		backRect = new BackButton(0, FlxG.height - 65, 195, 65);
		add(backRect);
		backRect.cameras = [camAfter];

		detailRate.camera = camAfter;

		for (data in 0...funcData.length)
		{
			var button = new FuncButton(backRect.x + backRect.width + 10 + (140 + 20) * data, backRect.y, funcData[data], funcColors[data]);
			add(button);
			funcGroup.push(button);
			button.id = data;
			button.cameras = [camAfter];
			button.event = outputEvent(funcData[data]);
		}

		//////////////////////////////////////////////////////////////////////////////////////////

		// These fields are retained as LoadingState's legacy preview sentinel.
		// They are not separate players: preview vocals are synchronized tracks
		// inside FlxG.sound.music's AudioGroup.
		vocalsPlayer1 = FlxG.sound.music;
		vocalsPlayer2 = null;

		//////////////////////////////////////////////////////////////////////////////////////////

		WeekData.setDirectoryFromWeek();
		if (songGroup != null && songGroup[curSelected] != null) songGroup[curSelected].changeSelectAll(true);

		#if windows
		var currentWindow = lime.app.Application.current.window;
		currentWindow.title = "NovaFlare Engine";
		#end
	}

	function weekIsLocked(name:String):Bool
	{
		var leWeek:WeekData = WeekData.weeksLoaded.get(name);
		return (!leWeek.startUnlocked
			&& leWeek.weekBefore.length > 0
			&& (!StoryMenuState.weekCompleted.exists(leWeek.weekBefore) || !StoryMenuState.weekCompleted.get(leWeek.weekBefore)));
	}

	function outputEvent(name:String):() -> Void {
		switch (name) {
			case 'options':
				return function() { 
				stopAll = true; 
				OptionsState.stateType = 1; 
				MusicBeatState.switchState(new OptionsState()); 
			};
			case 'mod':
				return function() { 
				stopAll = true; 
				ModsMenuState.isFreePlay = true;
				MusicBeatState.switchState(new ModsMenuState()); 			
			};
			case 'changer':
				return function() { 
				persistentUpdate = false;
				openSubState(new GameplayChangersSubstate()); 
			};
			case 'editor':
				return function() { 
				stopAll = true; 
				MusicBeatState.switchState(new ChartingState()); 
			};
			case 'reset':
				return function() { 
				persistentUpdate = false;
				openSubState(new ResetScoreSubState(songsData[curSelected].songName, curDifficulty, songsData[curSelected].songCharacter, -1)); };
			case 'random':
				return function() { 
				curSelected = FlxG.random.int(0, songGroup.length - 1); 
				changeSelection(); 
				songGroup[curSelected].changeSelectAll();
			};
		}
		return null;
	}

	///////////////////////////////////////////////////////////////////////////////////

	public final songPosiStart:Float = 720 * 0.3;
	public static var songPosiData:Float = 720 * 0.3; //神人haxe不能用FlxG.height
	public var rectInter:Float = 0.97;
	public function songMoveEvent(){
		if (songGroup.length <= 0) return;
		var scrolling:Bool = songsMove != null && songsMove.state != 'stop';
		for (i in 0...songGroup.length) {
			songGroup[i].moveY(songPosiData + getEffectiveId(songGroup[i].id) * SongRect.fixHeight * rectInter);
			// Horizontal arc easing is only visible for rows in the viewport.
			// Avoid pow/lerp work for the other ~50 mod rows on every drag frame.
			if (updateSongVisibility(songGroup[i])) {
				songGroup[i].calcX();
				songGroup[i].setScrollRendering(scrolling);
			}
		}
	}

	public function getEffectiveId(id:Int):Int {
		if (!isSearchActive) return id;
		var count = 0;
		for (j in 0...id) {
			if (songGroup[j].searchMatch) count++;
		}
		return count;
	}

	var holdTime:Float = 0;
	var childUpdateElapsed:Float = 0;
	var lastChildUpdateTick:Int = -1;

	public var allowUpdate:Bool = false;
	override function update(elapsed:Float)
	{
		if (FlxG.sound.music != null)
			Conductor.songPosition = FlxG.sound.music.time;

		// Native scheduling runs at up to 2000 Hz, but Freeplay contains dozens
		// of nested sprite groups whose animations and hit tests do not need to
		// be traversed more than 250 times per second.  Keep this state's input
		// logic responsive on every native tick while advancing its child tree
		// in accumulated, lossless steps.  Mouse edges force an immediate pass
		// so a short click can never be missed.
		childUpdateElapsed += elapsed;
		var nowTick:Int = FlxG.game.ticks;
		var forceChildUpdate:Bool = FlxG.mouse.justPressed || FlxG.mouse.justReleased || FlxG.mouse.wheel != 0;
		if (lastChildUpdateTick < 0 || nowTick - lastChildUpdateTick >= 4 || forceChildUpdate)
		{
			var childElapsed:Float = childUpdateElapsed;
			childUpdateElapsed = 0;
			lastChildUpdateTick = nowTick;
			super.update(childElapsed);
		}
		
		if (stopAll) return;

		if (keyboardState == 0) 
		{
			if (FlxG.keys.justPressed.T)
			{
				searchButton.focusSearch();
				return;
			}

			if (FlxG.keys.justPressed.M)
			{
				keyboardState = 2;
				curFunc = curFuncBack;
				FlxG.sound.play(Paths.sound('scrollMenu'));
				return;
			}

			var shiftMult:Int = 1;
			if (FlxG.keys.pressed.SHIFT)
				shiftMult = 3;

			if (songGroup.length > 1)
			{
				if (FlxG.keys.justPressed.HOME)
				{
					curSelected = 0;
					changeSelection();
					holdTime = 0;
				}
				else if (FlxG.keys.justPressed.END)
				{
					curSelected = songGroup.length - 1;
					changeSelection();
					holdTime = 0;
				}
				if (controls.UI_UP_P)
				{
					holdTime = 0;
					if (curSelected != SongRect.openRect.id) {
						var newCurSelected:Int = FlxMath.wrap(curSelected - shiftMult, 0, songGroup.length - 1);
						if (newCurSelected == SongRect.openRect.id) {
							curDifficulty = Difficulty.list.length - 1;
							songGroup[newCurSelected].diffFouceUpdate();
							curSelected = newCurSelected;
							FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
							changeSelection();
							songsMove.tweenData = FlxG.height * 0.5 - SongRect.fixHeight * 0.5 - getEffectiveId(curSelected) * SongRect.fixHeight * rectInter - (curDifficulty+1) * DiffRect.fixHeight * 1.05;
						} else {
							curDifficulty = -1;
							songGroup[curSelected].diffFouceUpdate();
							changeSelection(-shiftMult);
						}
					} else {
						if (curDifficulty >= 0) {
							curDifficulty--;
							songGroup[curSelected].diffFouceUpdate();
							FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
							if (curDifficulty >= 0) songsMove.tweenData = FlxG.height * 0.5 - SongRect.fixHeight * 0.5 - getEffectiveId(curSelected) * SongRect.fixHeight * rectInter - (curDifficulty+1) * DiffRect.fixHeight * 1.05;
							else songsMove.tweenData = FlxG.height * 0.5 - SongRect.fixHeight * 0.5 - getEffectiveId(curSelected) * SongRect.fixHeight * rectInter;
						} else {
							curDifficulty = -1;
							songGroup[curSelected].diffFouceUpdate();
							changeSelection(-shiftMult);
						}
					}
				}
				if (controls.UI_DOWN_P)
				{
					holdTime = 0;
					if (curSelected != SongRect.openRect.id)
						changeSelection(shiftMult);
					else {
						if (curDifficulty < Difficulty.list.length - 1) {
							curDifficulty++;
							songGroup[curSelected].diffFouceUpdate();
							FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
							songsMove.tweenData = FlxG.height * 0.5 - SongRect.fixHeight * 0.5 - getEffectiveId(curSelected) * SongRect.fixHeight * rectInter - (curDifficulty+1) * DiffRect.fixHeight * 1.05;
						} else {
							curDifficulty = -1;
							songGroup[curSelected].diffFouceUpdate();
							changeSelection(shiftMult);
						}
					}
				}

				if (controls.UI_DOWN || controls.UI_UP)
				{
					var checkLastHold:Int = Math.floor((holdTime - 0.5) * 30);
					holdTime += elapsed;
					var checkNewHold:Int = Math.floor((holdTime - 0.5) * 30);

					if (holdTime > 0.5 && checkNewHold - checkLastHold > 0) {
						curDifficulty = -1;
						SongRect.openRect.diffFouceUpdate();
						changeSelection((checkNewHold - checkLastHold) * (controls.UI_UP ? -shiftMult : shiftMult));
					}
				}
				
				if (controls.ACCEPT) 			
				{
					if (curSelected != SongRect.openRect.id) {
						songGroup[curSelected].changeSelectAll();
						//initSongsData();
					} else {
						startGame();
					}
				}
			}
		} else if (keyboardState == 1) {
		
		} else {
			if (FlxG.keys.justPressed.M)
			{
				keyboardState = 0;
				curFunc = -1;
				FlxG.sound.play(Paths.sound('cancelMenu'));
				return;
			}

			if (controls.UI_RIGHT_P)
			{
				curFunc = FlxMath.wrap(curFunc + 1, 0, funcGroup.length - 1);
				FlxG.sound.play(Paths.sound('scrollMenu'));
				curFuncBack = curFunc;
			}

			if (controls.UI_LEFT_P)
			{
				curFunc = FlxMath.wrap(curFunc - 1, 0, funcGroup.length - 1);
				FlxG.sound.play(Paths.sound('scrollMenu'));
				curFuncBack = curFunc;
			}

			if (controls.ACCEPT) 			
			{
				if (curFunc >= 0) {
					funcGroup[curFunc].event();
				}
			}
		}

		// replay hover & sort button handling
		if (keyboardState == 0 && !stopAll
			&& (FlxG.mouse.justMoved || FlxG.mouse.justPressed || FlxG.mouse.justReleased))
		{
			var mouseX:Float = FlxG.mouse.x;
			var mouseY:Float = FlxG.mouse.y;

			for (btn in replaySortBtn)
			{
				// RoundRect is a FlxSpriteGroup, so its inherited width/height
				// getters rescan every child.  The shape already maintains exact
				// cached bounds; use them in this per-frame hover loop.
				if (mouseX >= btn.x && mouseX <= btn.x + btn.realWidth
					&& mouseY >= btn.y && mouseY <= btn.y + btn.realHeight
					&& FlxG.mouse.justPressed)
				{
					var sortModes:Array<ReplaySortMode> = [DATE_DESC, SCORE_DESC, ACC_DESC, COMBO_DESC];
					if (btn.ID >= 0 && btn.ID < sortModes.length)
						toggleReplaySort(sortModes[btn.ID]);
				}
			}

			for (r in replayGroup)
			{
				r.updateHover(mouseX, mouseY);
			}
		}

		searchJustUnfocused = false;
	}

	public function initSongsData():Void {
		var requestId:Int = ++detailRequestId;
		if (detailLoadTimer != null)
		{
			detailLoadTimer.cancel();
			detailLoadTimer = null;
		}
		if (stateDestroyed || curDifficulty < 0 || curSelected < 0
			|| curSelected >= songsData.length || curSelected >= songGroup.length)
			return;

		var selected:Int = curSelected;
		var difficulty:Int = curDifficulty;
		var songLowercase:String = Paths.formatToSongPath(songsData[selected].songName);
		var poop:String = Highscore.formatSong(songLowercase, difficulty);
		var formattedSong:String = Paths.formatToSongPath(poop);
		var chartPath:String = Paths.json('$songLowercase/$formattedSong');

		// The row and difficulty callbacks can request the same chart in one
		// frame. Coalesce them and keep blocking I/O away from the render thread.
		// Song's global parse state is touched only by the newest main callback.
		detailLoadTimer = new FlxTimer().start(0.025, function(_):Void
		{
			detailLoadTimer = null;
			if (!isDetailRequestCurrent(requestId, selected, difficulty)) return;
			BackendThread.run(function():Void
			{
				var rawData:String = null;
				var loadError:Dynamic = null;
				try
				{
					if (FileSystem.exists(chartPath))
						rawData = File.getContent(chartPath);
					else
						rawData = openfl.utils.Assets.getText(chartPath);
				}
				catch (e:Dynamic)
				{
					loadError = e;
				}

				MainLoop.runInMainThread(function():Void
				{
					if (!isDetailRequestCurrent(requestId, selected, difficulty)) return;
					try
					{
						if (loadError != null) throw loadError;
						if (rawData == null) throw 'Missing chart: $chartPath';
						var loadedSong = Song.parseJSON(rawData, poop);
						if (loadedSong == null) throw 'Invalid chart: $chartPath';
						PlayState.SONG = loadedSong;
						Song.loadedSongName = songLowercase;
						Song.chartPath = chartPath;
						#if windows
						Song.chartPath = Song.chartPath.replace('/', '\\');
						#end
						StageData.loadDirectory(loadedSong);
						Conductor.bpm = loadedSong.bpm;
						var diffCalc = DiffRating.calcForSong(loadedSong);
						updateDetail(loadedSong, diffCalc, requestId, selected, difficulty);
					}
					catch (e:Dynamic)
					{
						trace('FREEPLAY CHART: $e');
						seedError(e, requestId, selected, difficulty);
					}
				});
			});
		});
	}

	inline function isDetailRequestCurrent(requestId:Int, selected:Int, difficulty:Int):Bool
	{
		return !stateDestroyed && instance == this && requestId == detailRequestId
			&& selected == curSelected && difficulty == curDifficulty;
	}

	function updateDetail(song:SwagSong, diffCalc:Float, requestId:Int, selected:Int, difficulty:Int):Void {
		if (!isDetailRequestCurrent(requestId, selected, difficulty)
			|| detailMapper == null || detailRate == null) return;
		diffCalc = Math.floor(diffCalc * 100) / 100;
		var selectedRect:SongRect = songGroup[selected];
		var charter:String = 'N/A';
		if (selectedRect._songCharter != null && difficulty >= 0
			&& difficulty < selectedRect._songCharter.length
			&& selectedRect._songCharter[difficulty] != null)
			charter = selectedRect._songCharter[difficulty];
		detailSongName.text = selectedRect.songNameSt;
		detailMusican.text = selectedRect.songMusican;
		detailPlayText.text = Std.string(Highscore.getPlayCount(selectedRect.songNameSt, difficulty));
		detailBpmText.text = Std.string(song.bpm);
		detailMapper.text = 'Rate ' + Std.string(diffCalc) + ' mapped by ' + charter;
		detailMapper.color = detailRate.getColorByValue(diffCalc / 10);
		detailRate.setRate(diffCalc);

		BackendThread.run(function():Void {
			var noteCount:Int = 0;
			var holdNoteCount:Int = 0;
			if (song != null && song.notes != null) {
				for (sec in song.notes) {
					if (sec == null || sec.sectionNotes == null) continue;
					for (n in sec.sectionNotes) {
						if (n == null || !Std.isOfType(n, Array)) continue;
						var arr:Array<Dynamic> = cast n;
						if (arr == null || arr.length < 2 || arr[1] == null) continue;
						var rawLane:Int = Std.int(arr[1]);
						if (rawLane < 0) continue;
						var gottaHitNote:Bool = sec.mustHitSection;
						if (rawLane > song.mania) gottaHitNote = !sec.mustHitSection;
						var isPlayerSide:Bool = ((gottaHitNote && !ClientPrefs.data.playOpponent)
							|| (!gottaHitNote && ClientPrefs.data.playOpponent));
						var isHold:Bool = (arr.length > 2 && arr[2] != null && arr[2] > 0);
						if (isPlayerSide) {
							noteCount++;
							if (isHold) holdNoteCount++;
						}
					}
				}
			}
			var speedValue:Float = (song != null) ? song.speed : 0;
			var keyCountValue:Float = (song != null) ? (song.mania + 1) : 0;

			MainLoop.runInMainThread(function():Void
			{
				if (!isDetailRequestCurrent(requestId, selected, difficulty)
					|| noteData == null || holdNoteData == null || speedData == null
					|| keyCountData == null) return;
				noteData.chanegData(noteCount);
				holdNoteData.chanegData(holdNoteCount);
				speedData.chanegData(speedValue);
				keyCountData.chanegData(keyCountValue);
			});
		});

		updateAudio(song, requestId);

		if (difficulty >= 0 && difficulty < Difficulty.list.length)
			loadReplaysForCurrentSong();
	}

	var allowPlayMusic:Bool = true;
	var alreadyLoadSongPath:String = '';
	var audioSwitchId:Int = 0;
	
	var audioFadeOutTime:Float = 0.12;
	var audioFadeInTime:Float = 0.18;

	public function updateAudio(?song:SwagSong, ?sourceDetailId:Int = -1):Void {
		if (stateDestroyed || song == null) return;
		if (FlxG.sound.music == null)
		{
			try
			{
				FlxG.sound.playMusic(Paths.music('freakyMenu'), 0, true);
			}
			catch (e:Dynamic)
			{
				trace('FREEPLAY PREVIEW: failed to create music channel: $e');
			}
		}
		if (FlxG.sound.music == null) return;

		var requestId:Int = ++audioSwitchId;
		var instTargetVolume:Float = 1;
		var songName:String = song.song;
		var instPath:String = Paths.songPath('${songName}/Inst');
		var voicesPath:String = Paths.songPath('${songName}/Voices');

		if (alreadyLoadSongPath == instPath)
		{
			if (!FlxG.sound.music.playing)
			{
				FlxG.sound.music.volume = instTargetVolume;
				FlxG.sound.music.play();
			}
			return;
		}

		alreadyLoadSongPath = '';
		var swapToNew:Void->Void = function() {
			if (!isAudioRequestCurrent(requestId, sourceDetailId)) return;
			allowPlayMusic = false;
			var instLoaded:Bool = false;
			var pendingStart:Bool = false;
			var started:Bool = false;
			var startPlayback:Void->Void = function() {
				if (started || !isAudioRequestCurrent(requestId, sourceDetailId)) return;
				started = true;
				FlxG.sound.music.volume = 0;
				FlxG.sound.music.play();
				FlxG.sound.music.fadeIn(audioFadeInTime, 0, instTargetVolume);
				FlxTimer.wait(0.05, function():Void {
					if (!isAudioRequestCurrent(requestId, sourceDetailId)
						|| detailTimeText == null || FlxG.sound.music == null) return;
					detailTimeText.text = DateTools.format(
						Date.fromTime(FlxG.sound.music.length), "%M:%S");
				});
			};

			try
			{
				FlxG.sound.music.stop();
				FlxG.sound.music.releaseMedia(1);
				FlxG.sound.music.releaseMedia(2);
				FlxG.sound.music.releaseMedia(3);

				if (FileSystem.exists(instPath))
				{
					FlxG.sound.music.loadStream(instPath, true, false, null, function()
					{
						if (!isAudioRequestCurrent(requestId, sourceDetailId)) return;
						instLoaded = true;
						if (pendingStart) startPlayback();
					});
					allowPlayMusic = true;
					alreadyLoadSongPath = instPath;
				}
				else
				{
					trace('FREEPLAY PREVIEW: missing $instPath');
				}

				if (song.needsVoices)
				{
					if (FileSystem.exists(voicesPath))
						FlxG.sound.music.addTrack(voicesPath, [":group-volume=0.8"], 2);
					else
					{
						var playerVocals:String = getVocalFromCharacter(song.player1, 'Player');
						var playerPath:String = Paths.songPath('${songName}/Voices${playerVocals}');
						if (FileSystem.exists(playerPath))
							FlxG.sound.music.addTrack(playerPath, [":group-volume=0.8"], 2);

						var opponentVocals:String = getVocalFromCharacter(song.player2, 'Opponent');
						var opponentPath:String = Paths.songPath('${songName}/Voices${opponentVocals}');
						if (FileSystem.exists(opponentPath))
							FlxG.sound.music.addTrack(opponentPath, [":group-volume=0.8"], 3);
					}
				}

				if (allowPlayMusic)
				{
					pendingStart = true;
					if (instLoaded) startPlayback();
				}
			}
			catch (e:Dynamic)
			{
				alreadyLoadSongPath = '';
				trace('FREEPLAY PREVIEW: failed to load $instPath because $e');
			}
		};

		if (FlxG.sound.music.playing && FlxG.sound.music.volume > 0)
		{
			FlxG.sound.music.fadeOut(audioFadeOutTime, 0, function(_)
			{
				if (isAudioRequestCurrent(requestId, sourceDetailId)) swapToNew();
			});
		}
		else
			swapToNew();
	}

	inline function isAudioRequestCurrent(requestId:Int, sourceDetailId:Int):Bool
	{
		return !stateDestroyed && instance == this && requestId == audioSwitchId
			&& (sourceDetailId < 0 || sourceDetailId == detailRequestId);
	}

	function seedError(e:Dynamic, requestId:Int, selected:Int, difficulty:Int):Void {
		if (!isDetailRequestCurrent(requestId, selected, difficulty)
			|| detailMapper == null || detailRate == null) return;
		detailPlayText.text = 'N/A';
		detailSongName.text = 'N/A';
		detailMusican.text = 'N/A';
		detailBpmText.text = 'N/A';
		detailMapper.text = 'No Chart Found';
		noteData.chanegData(0);
		holdNoteData.chanegData(0);
		speedData.chanegData(0);
		keyCountData.chanegData(0);
		detailRate.setRate(0);
		detailMapper.color = detailRate.getColorByValue(0);
		++audioSwitchId;
	}

	public function startGame() {
		if (curDifficulty >= 0 && curDifficulty < Difficulty.list.length) {
			var songLowercase:String = Paths.formatToSongPath(songsData[curSelected].songName);
			var poop:String = Highscore.formatSong(songLowercase, curDifficulty);

			try
			{
				ensureSelectedChartLoaded(poop, songLowercase);
				PlayState.isStoryMode = false;
				PlayState.storyDifficulty = curDifficulty;

				trace('CURRENT WEEK: ' + WeekData.getWeekFileName());
			}
			catch (e:Dynamic)
			{
				trace('ERROR! $e');

				var errorStr:String = e.toString();
				if (errorStr.startsWith('[lime.utils.Assets] ERROR:'))
					errorStr = 'Missing file: ' + errorStr.substring(errorStr.indexOf(songLowercase), errorStr.length - 1); // Missing chart

				trace(errorStr);
				FlxG.sound.play(Paths.sound('cancelMenu'));
				return;
			}

			Highscore.savePlayCount(songLowercase, curDifficulty);

			LoadingState.prepareToSong();
			if (ClientPrefs.data.loadingScreen)
			{
				FlxTransitionableState.skipNextTransIn = true;
				FlxTransitionableState.skipNextTransOut = true;
			}
			LoadingState.loadAndSwitchState(new PlayState());
		    stopAll = true;
			#if (MODS_ALLOWED && DISCORD_ALLOWED)
			DiscordClient.loadModRPC();
			#end
		}
	}

	public function watchReplay(rsdPath:String)
	{
		if (curDifficulty < 0 || curDifficulty >= Difficulty.list.length)
			return;

		var songLowercase:String = Paths.formatToSongPath(songsData[curSelected].songName);
		var poop:String = Highscore.formatSong(songLowercase, curDifficulty);

		try
		{
			ensureSelectedChartLoaded(poop, songLowercase);
			PlayState.isStoryMode = false;
			PlayState.storyDifficulty = curDifficulty;
			PlayState.replayMode = true;
			Replay.preparedPath = rsdPath;
		}
		catch (e:Dynamic)
		{
			trace('ERROR loading replay: $e');
			FlxG.sound.play(Paths.sound('cancelMenu'));
			return;
		}

		Highscore.savePlayCount(songLowercase, curDifficulty);

		LoadingState.prepareToSong();
		if (ClientPrefs.data.loadingScreen)
		{
			FlxTransitionableState.skipNextTransIn = true;
			FlxTransitionableState.skipNextTransOut = true;
		}
		LoadingState.loadAndSwitchState(new PlayState());
		stopAll = true;
		#if (MODS_ALLOWED && DISCORD_ALLOWED)
		DiscordClient.loadModRPC();
		#end
	}

	function ensureSelectedChartLoaded(jsonInput:String, songFolder:String):Void
	{
		var expectedPath:String = Paths.json(
			'${Paths.formatToSongPath(songFolder)}/${Paths.formatToSongPath(jsonInput)}');
		#if windows
		expectedPath = expectedPath.replace('/', '\\');
		#end
		if (PlayState.SONG != null && Song.loadedSongName == songFolder
			&& Song.chartPath == expectedPath)
		{
			// StageData.forceNextDirectory is consumed by LoadingState. Refresh
			// it even when the chart stays cached, otherwise replaying the same
			// song falls back to shared and loses its week-specific assets.
			StageData.loadDirectory(PlayState.SONG);
			return;
		}
		PlayState.SONG = Song.loadFromJson(jsonInput, songFolder);
		StageData.loadDirectory(PlayState.SONG);
	}

	public function openReplayResults(rsdPath:String)
	{
		#if sys
		BackendThread.run(() -> {
			var record:StateRecord = ReplayRect.loadStateRecord(rsdPath);
			MainLoop.runInMainThread(function():Void
			{
				if (record != null)
				{
					ResultsScreen.isFromFreeplay = true;
					ResultsScreen.freeplayRecord = record;
					persistentUpdate = false;
					openSubState(new ResultsScreen(0, 0));
				}
				else
				{
					FlxG.sound.play(Paths.sound('cancelMenu'));
				}
			});
		});
		#end
	}

	public function loadReplaysForCurrentSong()
	{
		for (r in replayGroup)
		{
			remove(r);
			r.destroy();
		}
		replayGroup = [];
		replayPosiData = 0;

		if (curDifficulty < 0 || curDifficulty >= Difficulty.list.length)
		{
			replayNoDataText.visible = true;
			if (replayMove != null)
				replayMove.moveLimit = [0, 0];
			return;
		}

		var diffName:String = Difficulty.list[curDifficulty];
		var data:Array<ReplayData> = ReplayRect.loadReplayData(songsData[curSelected].songName, diffName, songsData[curSelected].folder);

		if (data.length == 0)
		{
			replayNoDataText.visible = true;
			if (replayMove != null)
				replayMove.moveLimit = [0, 0];
			return;
		}

		ReplayRect.sortReplays(data, replaySortMode);

		replayNoDataText.visible = false;

		var startY:Float = replayStartY;
		for (i in 0...data.length)
		{
			var replayData:ReplayData = data[i];
			var baseY:Float = startY + i * ReplayRect.fixHeight * 1.3;
			var baseX:Float = replayStartX + 80 - (baseY - replayStartY) * replaySlope;
			var rect:ReplayRect = new ReplayRect(baseX, baseY, ReplayRect.fixWidth, ReplayRect.fixHeight, replayData);
			rect.cameras = [camReplay];
			rect.onClick = function()
			{
				watchReplay(replayData.rsdPath);
			};
			rect.onClickSettings = function()
			{
				openReplayResults(replayData.rsdPath);
			};
			add(rect);
			replayGroup.push(rect);
		}

		var maxScroll:Float = Math.max(0, data.length * ReplayRect.fixHeight * 1.3 - (FlxG.height - 60 - replayStartY));
		if (replayMove != null)
			replayMove.moveLimit = [0, maxScroll];

		updateReplaySortLabel();
	}

	public function replayMoveEvent()
	{
		for (i in 0...replayGroup.length)
		{
			var baseY:Float = replayStartY + i * ReplayRect.fixHeight * 1.3 - replayPosiData;
			replayGroup[i].moveY(baseY);
			replayGroup[i].x = replayStartX + 80 - (baseY - replayStartY) * replaySlope;
		}
	}

	function toggleReplaySort(mode:ReplaySortMode)
	{
		var nextMode:ReplaySortMode = mode;
		if (replaySortMode == mode)
		{
			nextMode = switch (mode)
			{
				case DATE_DESC: DATE_ASC;
				case DATE_ASC: DATE_DESC;
				case SCORE_DESC: SCORE_ASC;
				case SCORE_ASC: SCORE_DESC;
				case ACC_DESC: ACC_ASC;
				case ACC_ASC: ACC_DESC;
				case COMBO_DESC: COMBO_ASC;
				case COMBO_ASC: COMBO_DESC;
			}
		}
		replaySortMode = nextMode;
		updateSortBtnColors();
		loadReplaysForCurrentSong();
	}

	function updateSortBtnColors()
	{
		var sortModes:Array<{label:String, mode:ReplaySortMode}> = [
			{label: 'Date', mode: DATE_DESC},
			{label: 'Score', mode: SCORE_DESC},
			{label: 'Acc', mode: ACC_DESC},
			{label: 'Combo', mode: COMBO_DESC},
		];
		for (i in 0...replaySortBtn.length)
		{
			if (replaySortBtn[i] != null)
			{
				remove(replaySortBtn[i]);
				replaySortBtn[i].destroy();
			}
			if (replaySortLabel[i] != null)
			{
				remove(replaySortLabel[i]);
				replaySortLabel[i].destroy();
			}
		}
		replaySortBtn = [];
		replaySortLabel = [];

		for (i in 0...sortModes.length)
		{
			var btnX:Float = replayStartX + 225 + i * 100;
			var btnY:Float = replayStartY - 52;
			var sel:Bool = (replaySortMode == sortModes[i].mode);
			var btn:RoundRect = new RoundRect(btnX, btnY, 80, 24, 8, OriginType.LEFT_UP, 0xFFFFFFFF);
			btn.alpha = sel ? 1.0 : 0.35;
			btn.cameras = [camReplay];
			btn.ID = i;
			add(btn);
			replaySortBtn.push(btn);

			var label:FlxText = new FlxText(btnX, btnY, 80, sortModes[i].label, 12);
			label.setFormat(Paths.font(Language.get('fontName', 'main') + '.ttf'), 12, sel ? 0xFF000000 : 0xFFFFFFFF, CENTER);
			label.borderStyle = NONE;
			label.antialiasing = ClientPrefs.data.antialiasing;
			label.cameras = [camReplay];
			label.alignment = CENTER;
			label.y += (24 - label.height) / 2;
			add(label);
			replaySortLabel.push(label);
		}
	}

	function updateReplaySortLabel()
	{
		var label:String = switch (replaySortMode)
		{
			case DATE_DESC: 'Sort: Date (Newest)';
			case DATE_ASC: 'Sort: Date (Oldest)';
			case SCORE_DESC: 'Sort: Score (High)';
			case SCORE_ASC: 'Sort: Score (Low)';
			case ACC_DESC: 'Sort: Accuracy (High)';
			case ACC_ASC: 'Sort: Accuracy (Low)';
			case COMBO_DESC: 'Sort: Combo (High)';
			case COMBO_ASC: 'Sort: Combo (Low)';
		}
		if (replaySortText != null)
			replaySortText.text = label;
	}

	public function changeSelection(change:Int = 0, playSound:Bool = true)
	{
		if (isSearchActive && change != 0)
		{
			var step:Int = change > 0 ? 1 : -1;
			var remaining:Int = Std.int(Math.abs(change));
			var start:Int = curSelected;
			while (remaining > 0)
			{
				curSelected = FlxMath.wrap(curSelected + step, 0, songGroup.length - 1);
				if (curSelected == start) break;
				if (songGroup[curSelected].searchMatch) remaining--;
			}
		}
		else
		{
			curSelected = FlxMath.wrap(curSelected + change, 0, songGroup.length - 1);
		}

		Mods.currentModDirectory = songsData[curSelected].folder;
		PlayState.storyWeek = songsData[curSelected].week;

		songsMove.tweenData = FlxG.height * 0.5 - SongRect.fixHeight * 0.5 - getEffectiveId(curSelected) * SongRect.fixHeight * rectInter - (curSelected <= SongRect.openRect.id ? 0 : Difficulty.list.length * DiffRect.fixHeight * 1.05 + SongRect.fixHeight * (0.1 * 2));
		
		if (playSound) FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);

		requestSelectedBackground(songGroup[curSelected].bgPath);
		var colors:Array<Int> = songsData[curSelected].color;
		var newColor:Int = FlxColor.fromRGB(Std.int(colors[0] * 1.0), Std.int(colors[1] * 1.0), Std.int(colors[2] * 1.0));
		if (newColor != intendedColor)
		{
			intendedColor = newColor;
			background.changeColor(intendedColor);
		}

		////////////////////////////////////////////////////////////
	}

	function requestSelectedBackground(path:String):Void
	{
		var requestId:Int = ++backgroundRequestId;
		var selected:Int = curSelected;
		var targetWidth:Int = Std.int(FlxG.width * 1.05);
		var targetHeight:Int = Std.int(FlxG.height * 1.05);
		if (backgroundLoadTimer != null)
		{
			backgroundLoadTimer.cancel();
			backgroundLoadTimer = null;
		}

		// Decode only after the selection settles. Continuous scrolling used to
		// synchronously decode a full PNG on every step and caused the visible
		// frame-time spikes reported on this page.
		backgroundLoadTimer = new FlxTimer().start(0.12, function(_)
		{
			backgroundLoadTimer = null;
			if (stateDestroyed || instance != this || requestId != backgroundRequestId) return;
			BackendThread.run(function():Void
			{
				// Lime images own their pixel buffers and do not use OpenFL's
				// unsynchronised Matrix/Point object pools. Keep every worker-side
				// decode, resize and blur in that representation.
				var prepared = SongRect.createBackgroundImages(
					path,
					targetWidth,
					targetHeight);
				MainLoop.runInMainThread(function():Void
				{
					if (stateDestroyed || instance != this || requestId != backgroundRequestId || background == null)
						return;
					if (prepared == null || prepared.background == null)
						return;

					var bitmap:BitmapData = null;
					var thumbnail:BitmapData = null;
					try
					{
						// OpenFL wrappers and FlxGraphics are created only on the
						// render thread. This is the boundary that prevents the
						// OpenGLRenderer.__getMatrix access violation.
						bitmap = BitmapData.fromImage(prepared.background);
						if (prepared.thumbnail != null)
							thumbnail = BitmapData.fromImage(prepared.thumbnail);

						if (thumbnail != null)
						{
							// The selected full decode is already in memory, so derive the
							// list thumbnail from it instead of decoding the PNG a second time.
							var maskSource:SongRect = selected >= 0 && selected < songGroup.length
								? songGroup[selected] : null;
							if (maskSource != null && maskSource.selectShow != null)
								thumbnail.copyChannel(maskSource.selectShow.pixels,
									new Rectangle(0, 0, SongRect.fixWidth, SongRect.fixHeight),
									new Point(), BitmapDataChannel.ALPHA, BitmapDataChannel.ALPHA);
							var thumbnailGraphic:FlxGraphic = FlxGraphic.fromBitmapData(thumbnail);
							thumbnail = null;
							Cache.setFrame(path, {graphic: thumbnailGraphic, frame: null});
							for (rect in songGroup)
								if (rect != null && rect.bgPath == path)
									rect.applyThumbnailGraphic(thumbnailGraphic);
						}

						// Full-screen backgrounds are transient. Do not leave every
						// selected song in FlxG.bitmap after its cross-fade releases it.
						var nextGraphic:FlxGraphic = FlxGraphic.fromBitmapData(bitmap, false, null, false);
						bitmap = null;
						// bg1/bg2 keep FlxGraphic.useCount accurate throughout an
						// interrupted cross-fade. Let their frame setters release
						// the old graphic only after neither sprite references it.
						selectedBackgroundGraphic = nextGraphic;
						background.changeSprite(nextGraphic.imageFrame);
					}
					catch (e:Dynamic)
					{
						if (bitmap != null) bitmap.dispose();
						if (thumbnail != null) thumbnail.dispose();
						trace('FREEPLAY BG: failed to install $path because $e');
					}
				});
			});
		});
	}

	override function destroy():Void
	{
		MouseEffect.trailEnabled = true;
		stateDestroyed = true;
		++detailRequestId;
		++audioSwitchId;
		++backgroundRequestId;
		if (detailLoadTimer != null)
		{
			detailLoadTimer.cancel();
			detailLoadTimer = null;
		}
		if (backgroundLoadTimer != null)
		{
			backgroundLoadTimer.cancel();
			backgroundLoadTimer = null;
		}
		if (instance == this) instance = null;
		super.destroy();
		selectedBackgroundGraphic = null;
	}

	public function updateSongLayerOrder():Void
	{
		if (songGroup.length == 0 || SongRect.openRect == null) return;
		var start:Int = members.indexOf(songGroup[0]);
		if (start < 0) return;
		var sorted:Array<SongRect> = songGroup.copy();
		ArraySort.sort(sorted, function(a:SongRect, b:SongRect) {
			var da:Int = Std.int(Math.abs(a.id - SongRect.openRect.id));
			var db:Int = Std.int(Math.abs(b.id - SongRect.openRect.id));
			return db - da;
		});
		for (rect in songGroup) remove(rect, true);
		var idx:Int = start;
		for (rect in sorted) {
			insert(idx, rect);
			idx++;
		}
	}

	public function startSearch(text:String)
	{
		isSearchActive = (text != '');

		if (!isSearchActive)
		{
			noMatchText.visible = false;
			for (song in songGroup)
			{
				song.searchMatch = true;
			}
			searchCountText.text = '${songGroup.length} charts';
			searchCountText.visible = true;
			return;
		}

		var lowerText:String = text.toLowerCase();
		var firstMatch:Int = -1;
		var openStillMatches:Bool = false;

		for (song in songGroup)
		{
			var match:Bool = song.songNameSt.toLowerCase().indexOf(lowerText) >= 0
				|| song.songMusican.toLowerCase().indexOf(lowerText) >= 0;
			song.searchMatch = match;
			if (match && firstMatch < 0)
				firstMatch = song.id;
			if (match && song == SongRect.openRect && song.diffAdded)
				openStillMatches = true;
		}

		var matchCount:Int = 0;
		for (song in songGroup)
		{
			if (song.searchMatch) matchCount++;
		}
		searchCountText.text = '$matchCount / ${songGroup.length} charts found';
		searchCountText.visible = true;

		noMatchText.visible = (firstMatch < 0);

		if (!openStillMatches && firstMatch >= 0)
		{
			curSelected = firstMatch;
			songGroup[firstMatch].changeSelectAll(true);
		}
	}

	function rectOnScreen(r:SongRect):Bool {
		var cy:Float = camSongs.scroll.y;
		var ch:Float = camSongs.height;
		var ry:Float = r.realY;
		var rh:Float = r.selectShow.height;

		if (r == SongRect.openRect) {
			rh = r.selectShow.height + Difficulty.list.length * DiffRect.fixHeight * 1.05 + SongRect.fixHeight * (0.1 * 2);
		}
		return ry + rh > cy && ry < cy + ch;
	}

	public function updateSongVisibility(r:SongRect):Bool {
		if (r == null) return false;
		var ons:Bool = rectOnScreen(r);
		// FlxSpriteGroup propagates visible/active to every child. Repeating the
		// same assignment for all 61 rows was hundreds of needless writes per
		// rendered scroll step.
		if (r.visible != ons) r.visible = ons;
		if (r.active != ons) r.active = ons;
		return ons;
	}
	
	function changeDiff(change:Int = 0)
	{
		curDifficulty = FlxMath.wrap(curDifficulty + change, 0, Difficulty.list.length - 1);
	}

	override function beatHit()
	{
		super.beatHit();
		if (Std.int(Conductor.getBeat(Conductor.songPosition)) % 2 == 0 && SongRect.openRect != null) SongRect.openRect.beatHit();

		if (detailBpmSign != null)
		{
			detailBpmSign.flipX = !detailBpmSign.flipX;
			detailBpmSign.alpha = 0.4;
			FlxTween.tween(detailBpmSign, {alpha: 1}, 0.3);
		}
	}
	
	override function closeSubState()
	{
		super.closeSubState();
		persistentUpdate = true;
	}
	
	public static function destroyFreeplayVocals() {
		FlxG.sound.music.releaseMedia(1);
		FlxG.sound.music.releaseMedia(2);
		FlxG.sound.music.releaseMedia(3);
		FlxG.sound.music.stop();
		vocalsPlayer1 = null;
		vocalsPlayer2 = null;
	}

	function getVocalFromCharacter(char:String, fixName:String)
	{
		try
		{
			var path:String = Paths.getPath('characters/$char.json', TEXT);

			var character:Dynamic = null;
			#if MODS_ALLOWED
			if (FileSystem.exists(path))
			character = Json.parse(File.getContent(path));
			#else
			character = Json.parse(Assets.getText(path));
			#end
			if (character != null && character.vocals_file != null && character.vocals_file != "" && character.vocals_file.length > 0)
			return '-'+ character.vocals_file;
		}
		return '-'+fixName;
	}
}

class SongMetadata
{
	public var songName:String = "";
	public var week:Int = 0;
	public var songCharacter:String = "";
	public var color:Array<Int> = [0, 0, 0];
	public var folder:String = "";
	public var bg:Dynamic;
	public var searchnum:Int = 0;
	public var songMusican:String = 'N/A';
	public var songCharter:Array<String> = ['N/A', 'N/A', 'N/A'];

	public function new(song:String, week:Int, songCharacter:String, musican:String, charter:Array<String>, color:Array<Int>)
	{
		this.songName = song;
		this.week = week;
		this.songCharacter = songCharacter;
		this.color = color;
		this.folder = Mods.currentModDirectory;
		this.bg = Paths.image('menuDesat', null, false);
		this.searchnum = 0;
		this.songMusican = musican;
		this.songCharter = charter;
		if (this.folder == null)
			this.folder = '';
	}
}
