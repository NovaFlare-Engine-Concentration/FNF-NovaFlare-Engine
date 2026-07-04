package substates;

/*
	ResultsScreen made by NF|beihu (北狐丶逐梦)
	bilibili: https://b23.tv/SnqG443
	youtube: https://youtube.com/@beihu235?si=NHnWxcUWPS46EqUt
	discord: @beihu235

	you can use it but must give me credit(dont forget my icon)
	logic is very easy so I think everyone can understand it

	Who cares about rudy's hscript so I continue to choose to use my lua logic
	Her hscript weren't worth stole and I didn't stole it

	by the way dont move this to hscript,I dont allow it
 */

import openfl.display.BitmapData;
import openfl.display.Shape;
import openfl.display.Bitmap;
import openfl.utils.Assets;
import openfl.filters.ShaderFilter;

import flixel.math.FlxRect;
import flixel.util.FlxSpriteUtil;
import flixel.addons.display.FlxRuntimeShader;

import general.objects.state.ResultShape;

import states.freeplayState.FreeplayState;
import states.freeplayState.shader.BlurFilter;
import states.mainMenuState.MainMenuState;

import games.backend.Highscore;
import games.backend.diffCalc.DiffRating;
import games.backend.Song;
import games.backend.Replay;
import games.backend.Replay.StateRecord;
import states.loadingState.LoadingState;

class ResultsScreen extends MusicBeatSubstate
{
	static public var isFromFreeplay:Bool = false;
	static public var freeplayRecord:StateRecord = null;
	static public var savedModDir:String = '';

	var background:FlxSprite;

	// BG
	var modsBG:FlxSprite;
	var modsMenu:FlxSprite;
	var modsText:FlxText;

	// Results for what mod you played
	var mesBG:FlxSprite;
	var mesTextNumber:FlxTypedGroup<FlxText>;

	// Results for song message
	var scBG:FlxSprite;
	var scTextNumber:FlxTypedGroup<FlxText>;

	// Results for score
	var opBG:FlxSprite;
	var opTextNumber:FlxTypedGroup<FlxText>;

	// Results for option
	var graphBG:FlxSprite;
	var graphNote:FlxSprite;

	// Results for note offset
	var percentBG:FlxSprite;
	var percentRectNumber:FlxTypedGroup<FlxSprite>;
	var percentRectBGNumber:FlxTypedGroup<FlxSprite>;
	var percentTextNumber:FlxTypedGroup<FlxText>;

	// Results for note rate percent
	var backRect:PressButton;
	// back
	var replayRect:PressButton;
	var saveReplayRect:PressButton;

	public var camBase:FlxCamera;
	public var camBG:FlxCamera;

	var filter:ShaderFilter;

	static public var camOther:FlxCamera;

	// camera
	var game:Dynamic;

	var ColorArray:Array<FlxColor> = [
		0xFFFFFF00, // marvelous
		0xFF00FFFF, // sick
		0xFF00FF00, // good
		0xFFFF7F00, // bad
		0xFFFF5858, // shit
		0xFFFF0000 // miss
	];
	var ColorArrayAlpha:Array<FlxColor> = [
		0x7FFFFF00, // marvelous
		0x7F00FFFF, // sick
		0x7F00FF00, // good
		0x7FFF7F00, // bad
		0x7FFF5858, // shit
		0x7FFF0000 // miss
	];

	var safeZoneOffset:Float = (ClientPrefs.data.safeFrames / 60) * 1000;

	public function new(x:Float, y:Float)
	{
		super();

		if (isFromFreeplay && freeplayRecord != null)
		{
			game = cast freeplayRecord;
			var pct:Float = freeplayRecord.ratingPercent * 100;
			game.ratingName = (pct >= 100) ? 'SS' : (pct >= 95) ? 'S' : (pct >= 90) ? 'A' : (pct >= 80) ? 'B' : (pct >= 70) ? 'C' : 'D';
			game.nowTime = freeplayRecord.playDate;
			game.opponent = freeplayRecord.playOpponent;
			game.NoteTime = freeplayRecord.hitMapTime;
			game.NoteMs = freeplayRecord.hitMapMs;
			game.replayExam = null;
		}
		else
		{
			game = PlayState.instance;
		}

		camBG = new FlxCamera();
		camBG.bgColor.alpha = 0;
		FlxG.cameras.add(camBG,false);

		camBase = new FlxCamera();
		camBase.bgColor.alpha = 0;
		FlxG.cameras.add(camBase,false);

		cameras = [camBase];

		camOther = new FlxCamera();
		camOther.bgColor.alpha = 0;
		FlxG.cameras.add(camOther,false);		

		var extraLoad:Bool = false;
		var filesLoad = 'data/' + game.songName + '/background';
		if (FileSystem.exists(Paths.modFolders(filesLoad + '.png')))
		{
			extraLoad = true;
		}
		else
		{
			filesLoad = 'menuBG';
			extraLoad = false;
		}

		background = new FlxSprite(0, 0).loadGraphic(Paths.imageEX(filesLoad, null, false, false));
		background.scale.x = FlxG.width * 1.05 / background.width;
		background.scale.y = FlxG.height * 1.05 / background.height;
		background.updateHitbox();
		background.antialiasing = ClientPrefs.data.antialiasing;
		background.screenCenter();
		background.camera = camBG;
		add(background);

		var bgBlur = new BlurFilter(15.0);
		bgBlur.apply(camBG);

		//--------------------------

		modsBG = new FlxSprite(20, 20).makeGraphic(600, 340 + 20, FlxColor.BLACK);
		modsBG.alpha = 0;
		add(modsBG);

		modsMenu = new FlxSprite(20, 20).loadGraphic(Paths.image(filesLoad, null, true, extraLoad));
		modsMenu.scale.x = 600 / modsMenu.width;
		modsMenu.scale.y = 338 / modsMenu.height;
		modsMenu.offset.x = 0;
		modsMenu.offset.y = 0;
		modsMenu.updateHitbox();
		modsMenu.antialiasing = ClientPrefs.data.antialiasing;
		modsMenu.alpha = 0;
		add(modsMenu);

		modsText = new FlxText(20, 20 + modsMenu.height, 0, 'Mod name: ' + Mods.currentModDirectory);
		modsText.size = 16;
		modsText.font = Paths.font('vcr.ttf');
		modsText.setBorderStyle(FlxTextBorderStyle.OUTLINE, FlxColor.BLACK, 1, 1);
		modsText.antialiasing = ClientPrefs.data.antialiasing;
		modsText.alignment = CENTER;
		modsText.alpha = 0;
		add(modsText);
		modsText.x += modsBG.width / 2 - modsText.width / 2;
		if (modsText.width > 600)
			modsText.scale.x = 600 / modsText.width;
		modsText.offset.x = 0;

		//-------------------------

		mesBG = new FlxSprite(20, 20 + modsBG.height + 20).makeGraphic(600, 75, FlxColor.BLACK);
		mesBG.alpha = 0;
		add(mesBG);

		mesTextNumber = new FlxTypedGroup<FlxText>();
		add(mesTextNumber);

		mesTextAdd('SongName: ' + PlayState.SONG.song + ' - ' + Difficulty.getString());
		if (isFromFreeplay)
			mesTextAdd('Played Time: ' + game.nowTime);
		else if (!PlayState.replayMode)
			mesTextAdd('Played Time: ' + Date.now().toString());
		else
			mesTextAdd('Played Time: ' + game.nowTime);

		var poop:String = Highscore.formatSong(game.songName.toLowerCase(), PlayState.storyDifficulty);
		var formattedFolder:String = Paths.formatToSongPath(game.songName.toLowerCase());
		var formattedSong:String = Paths.formatToSongPath(poop);

		if (FileSystem.exists(Paths.modsJson(formattedFolder + '/' + formattedSong)))
		{
			var rate:Float = DiffRating.calcForSong(Song.loadFromJson(poop, game.songName.toLowerCase())) / 5;
			mesTextAdd('Difficult: ' + Math.ceil(rate * 100) / 100);
		}
		else
		{
			mesTextAdd('Difficult: N/A');
		}

		//-------------------------

		scBG = new FlxSprite(20, 20 + modsBG.height + 20 + mesBG.height + 20).makeGraphic(600, 75, FlxColor.BLACK);
		scBG.alpha = 0;
		add(scBG);

		scTextNumber = new FlxTypedGroup<FlxText>();
		add(scTextNumber);

		scTextAdd('Score: ' + game.songScore, 1);
		scTextAdd('Highest Combe: ' + game.highestCombo, 2);
		scTextAdd('Accuracy: ' + Math.ceil(game.ratingPercent * 10000) / 100 + '%', 1);
		if (game.ratingFC == '')
			scTextAdd('Rank: N/A', 2);
		else
			scTextAdd('Rank: ' + game.ratingName + ' - ' + game.ratingFC, 2);
		scTextAdd('Hits: ' + game.songHits, 1);
		scTextAdd('Combo Break: ' + game.songMisses, 2);

		//-------------------------

		opBG = new FlxSprite(20, 20 + modsBG.height + 20 + mesBG.height + 20 + scBG.height + 20).makeGraphic(600, 125, FlxColor.BLACK);
		opBG.alpha = 0;
		add(opBG);

		opTextNumber = new FlxTypedGroup<FlxText>();
		add(opTextNumber);

		opTextAdd('HealthGain: X' + game.healthGain, 1);
		opTextAdd('HealthLoss: X' + game.healthLoss, 2);

		opTextAdd('SongSpeed: ' + game.songSpeed, 1);
		opTextAdd('PlaybackRate: X' + game.playbackRate, 2);

		var botplay:String = 'Disable';
		if (game.cpuControlled)
			botplay = 'Enable';
		var practice:String = 'Disable';
		if (game.practiceMode)
			practice = 'Enable';
		var instakill:String = 'Disable';
		if (game.instakillOnMiss)
			instakill = 'Enable';

		opTextAdd('PracticeMode: ' + practice, 1);
		opTextAdd('Instakill: ' + instakill, 2);
		opTextAdd('Botplay: ' + botplay, 1);
		opTextAdd('', 2);

		var opponent:String = 'Disable';
		if (isFromFreeplay)
		{
			if (game.opponent)
				opponent = 'Enable';
		}
		else if (PlayState.replayMode)
		{
			if (game.opponent)
				opponent = 'Enable';
		}
		else
		{
			if (ClientPrefs.data.playOpponent)
				opponent = 'Enable';
		}
		var flipChart:String = 'Disable';

		if (isFromFreeplay)
		{
			if (game.flipChart)
				flipChart = 'Enable';
		}
		else if (PlayState.replayMode)
		{
			if (game.flipChart)
				flipChart = 'Enable';
		}
		else
		{
			if (ClientPrefs.data.flipChart)
				flipChart = 'Enable';
		}
		opTextAdd('PlayOpponent: ' + opponent, 1);
		opTextAdd('FlipChart: ' + flipChart, 2);

		//-------------------------

		graphBG = new FlxSprite(20 + 640, 20).makeGraphic(600, 300, FlxColor.BLACK);
		graphBG.alpha = 0;
		add(graphBG);

		graphNote = new FlxSprite(20 + 640, 20).makeGraphic(600, 300, FlxColor.TRANSPARENT);
		graphNote.alpha = 0;
		add(graphNote);

		graphNoteDraw();

		//-------------------------

		percentBG = new FlxSprite(20 + 640, 20 + 300 + 20).makeGraphic(600, 300, FlxColor.BLACK);
		percentBG.alpha = 0;
		add(percentBG);

		percentRectBGNumber = new FlxTypedGroup<FlxSprite>();
		add(percentRectBGNumber);

		percentRectNumber = new FlxTypedGroup<FlxSprite>();
		add(percentRectNumber);

		percentTextNumber = new FlxTypedGroup<FlxText>();
		add(percentTextNumber);

		percentRateAdd();

		//-------------------------

		if (!isFromFreeplay)
		{
			replayRect = new PressButton(20 + 640, 20 + 300 + 20 + 300 + 20, 190, 60, 'Replay', 0.5, replayFunction);
			replayRect.alpha = 0;
			add(replayRect);

			saveReplayRect = new PressButton(20 + 640 + 190 + 10, 20 + 300 + 20 + 300 + 20, 190, 60, 'Save Rep.', 0.5, saveFunction);
			saveReplayRect.alpha = 0;
			add(saveReplayRect);

			backRect = new PressButton(20 + 640 + 190 + 10 + 190 + 10, 20 + 300 + 20 + 300 + 20, 190, 60, 'Back', 0.5, backFunction);
		}
		else
		{
			backRect = new PressButton(20 + 640, 20 + 300 + 20 + 300 + 20, 600, 60, 'Back', 0.5, backFunction);
		}
		backRect.alpha = 0;
		add(backRect);

		//-------------------------

		startTween();

		FlxG.mouse.visible = !ClientPrefs.data.needMobileControl;
	}

	var closeCheck:Bool = false;
	var choose:Int = 1;

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (!closeCheck)
		{
			if (isFromFreeplay && FlxG.keys.justPressed.ESCAPE)
			{
				isFromFreeplay = false;
				freeplayRecord = null;
				close();
				return;
			}
			if (FlxG.keys.justPressed.LEFT)
			{
				choose = FlxMath.wrap(choose - 1, 0, 2);
				FlxG.sound.play(Paths.sound('scrollMenu'));
			}
			if (FlxG.keys.justPressed.RIGHT)
			{
				choose = FlxMath.wrap(choose + 1, 0, 2);
				FlxG.sound.play(Paths.sound('scrollMenu'));
			}
			if (FlxG.keys.justPressed.ENTER #if android || FlxG.android.justReleased.BACK #end)
			{
				switch (choose)
				{
					case 0: replayFunction();
					case 1: saveFunction();
					case 2: backFunction();
				}
			}
		}
	}

	var getReadyReplay:Bool = false;

	function replayFunction()
	{
		if (closeCheck)
			return;
		if (getReadyReplay)
		{
			saveReplayData();
			closeCheck = true;

			var songLowercase:String = Paths.formatToSongPath(PlayState.SONG.song);
			var diff:Int = PlayState.storyDifficulty;
			var poop:String = Highscore.formatSong(songLowercase, diff);
			Mods.currentModDirectory = savedModDir;
			PlayState.SONG = Song.loadFromJson(poop, songLowercase);
			PlayState.isStoryMode = false;
			PlayState.storyDifficulty = diff;
			PlayState.replayMode = true;

			LoadingState.prepareToSong();
			FlxTransitionableState.skipNextTransIn = true;
			FlxTransitionableState.skipNextTransOut = true;
			LoadingState.loadAndSwitchState(new PlayState());
		}
		else
		{
			getReadyReplay = true;
			FlxG.sound.play(Paths.sound('scrollMenu'));

			replayRect.text.text = 'Press Again';
			replayRect.text.x = replayRect.x + replayRect.background.width / 2 - replayRect.text.width / 2;
			replayRect.text.y = replayRect.y + replayRect.background.height / 2 - replayRect.text.height / 2;

			new FlxTimer().start(1, function(tmr:FlxTimer)
			{
				replayRect.text.text = 'Replay';
				replayRect.text.x = replayRect.x + replayRect.background.width / 2 - replayRect.text.width / 2;
				replayRect.text.y = replayRect.y + replayRect.background.height / 2 - replayRect.text.height / 2;

				getReadyReplay = false;
			});
		}
	}

	function saveFunction()
	{
		if (closeCheck)
			return;
		saveReplayData();
		FlxG.sound.play(Paths.sound('scrollMenu'));
		saveReplayRect.text.text = 'Saved!';
		saveReplayRect.text.x = saveReplayRect.x + saveReplayRect.background.width / 2 - saveReplayRect.text.width / 2;
		saveReplayRect.text.y = saveReplayRect.y + saveReplayRect.background.height / 2 - saveReplayRect.text.height / 2;

		new FlxTimer().start(1, function(tmr:FlxTimer)
		{
			saveReplayRect.text.text = 'Save Rep.';
			saveReplayRect.text.x = saveReplayRect.x + saveReplayRect.background.width / 2 - saveReplayRect.text.width / 2;
			saveReplayRect.text.y = saveReplayRect.y + saveReplayRect.background.height / 2 - saveReplayRect.text.height / 2;
		});
	}

	function saveReplayData()
	{
		if (game.replayExam == null) return;

		var record:StateRecord = {
			songName: game.songName,
			difficulty: Difficulty.getString().toUpperCase(),
			songLength: game.songLength,
			playDate: Date.now().toString(),
			modDir: Mods.currentModDirectory == '' ? 'originFunkin' : Mods.currentModDirectory,
			songSpeed: game.songSpeed,
			playbackRate: game.playbackRate,
			healthGain: game.healthGain,
			healthLoss: game.healthLoss,
			cpuControlled: game.cpuControlled,
			practiceMode: game.practiceMode,
			instakillOnMiss: game.instakillOnMiss,
			playOpponent: ClientPrefs.data.playOpponent,
			flipChart: ClientPrefs.data.flipChart,
			songScore: game.songScore,
			ratingPercent: game.ratingPercent,
			ratingFC: game.ratingFC,
			songHits: game.songHits,
			highestCombo: game.highestCombo,
			songMisses: game.songMisses,
			hitMapTime: game.NoteTime,
			hitMapMs: game.NoteMs,
			replayVersion: ClientPrefs.data.replayQuality ? 2 : 1,
			sickCount: game.ratingsData[0].hits,
			goodCount: game.ratingsData[1].hits,
			badCount: game.ratingsData[2].hits,
			shitCount: game.ratingsData[3].hits,
			mania: PlayState.SONG.mania,
			safeFrames: ClientPrefs.data.safeFrames,
			ratingOffset: ClientPrefs.data.ratingOffset,
			noteOffset: ClientPrefs.data.noteOffset,
			botPlay: ClientPrefs.getGameplaySetting('botplay', 'bool'),
			gameplaySettingsJson: haxe.Json.stringify(ClientPrefs.data.gameplaySettings)
		};
		game.replayExam.savePlayRecord(record);
	}

	var getReadyBack:Bool = false;

	function backFunction()
	{
		if (closeCheck)
			return;
		if (isFromFreeplay)
		{
			isFromFreeplay = false;
			freeplayRecord = null;
			close();
			return;
		}
		if (getReadyBack)
		{
			NewCustomFadeTransition(false);
			PlayState.replayMode = false;
		Replay.restoreSettings();
			closeCheck = true;
		}
		else
		{
			getReadyBack = true;
			FlxG.sound.play(Paths.sound('scrollMenu'));

			backRect.text.text = 'Press Again';
			backRect.text.x = backRect.x + backRect.background.width / 2 - backRect.text.width / 2;
			backRect.text.y = backRect.y + backRect.background.height / 2 - backRect.text.height / 2;

			new FlxTimer().start(1, function(tmr:FlxTimer)
			{
				backRect.text.text = 'Back';
				backRect.text.x = backRect.x + backRect.background.width / 2 - backRect.text.width / 2;
				backRect.text.y = backRect.y + backRect.background.height / 2 - backRect.text.height / 2;

				getReadyBack = false;
			});
		}
	}

	function mesTextAdd(text:String = '', sameLine:Int = 0)
	{
		TextAdd(mesBG, mesTextNumber, text, sameLine);
	}

	function scTextAdd(text:String = '', sameLine:Int = 0)
	{
		TextAdd(scBG, scTextNumber, text, sameLine);
	}

	function opTextAdd(text:String = '', sameLine:Int = 0)
	{
		TextAdd(opBG, opTextNumber, text, sameLine);
	}

	var textSize = 20;

	function TextAdd(BG:Dynamic, type:Dynamic, text:String = '', sameLine:Int = 0)
	{
		var textWidth = 600;
		var numberText = new FlxText(BG.x, BG.y, 0, text, textSize);
		if (sameLine > 0)
			numberText.y += Math.floor(type.length / 2) * 25;
		else
			numberText.y += type.length * textSize;
		if (sameLine > 0)
			numberText.x += (sameLine - 1) * 300;
		numberText.font = Paths.font('vcr.ttf');
		numberText.setBorderStyle(FlxTextBorderStyle.OUTLINE, FlxColor.BLACK, 1, 1);
		numberText.scrollFactor.set();
		numberText.antialiasing = ClientPrefs.data.antialiasing;
		numberText.alignment = LEFT;
		numberText.alpha = 0;
		if (sameLine > 0)
			textWidth = 300;
		if (numberText.width > textWidth)
			numberText.scale.x = (textWidth - 1) / numberText.width; // fix width problem
		numberText.offset.x = numberText.width * (1 - numberText.scale.x) / 2;
		type.add(numberText);
	}

	function graphNoteDraw()
	{
		FlxSpriteUtil.beginDraw(0xFFFFFFFF);

		var noteSize = 2.3;
		var MoveSize = 0.8;
		var color:FlxColor;

		for (i in 0...Math.floor(game.NoteTime.length - 1))
		{
			if (Math.abs(game.NoteMs[i]) <= ClientPrefs.data.marvelousWindow && ClientPrefs.data.marvelousRating)
				color = ColorArray[0];
			else if (Math.abs(game.NoteMs[i]) <= ClientPrefs.data.sickWindow)
				color = ColorArray[1];
			else if (Math.abs(game.NoteMs[i]) <= ClientPrefs.data.goodWindow)
				color = ColorArray[2];
			else if (Math.abs(game.NoteMs[i]) <= ClientPrefs.data.badWindow)
				color = ColorArray[3];
			else if (Math.abs(game.NoteMs[i]) <= safeZoneOffset)
				color = ColorArray[4];
			else
				color = ColorArray[5];

			if (Math.abs(game.NoteMs[i]) <= safeZoneOffset)
			{
				FlxSpriteUtil.drawCircle(graphNote, graphNote.width * (game.NoteTime[i] / game.songLength),
					graphNote.height * 0.5 + graphNote.height * 0.5 * MoveSize * (game.NoteMs[i] / safeZoneOffset), noteSize, color);
			}
			else
			{
				FlxSpriteUtil.drawCircle(graphNote, graphNote.width * (game.NoteTime[i] / game.songLength),
					graphNote.height * 0.5 + graphNote.height * 0.5 * 0.9, noteSize, color);
			}
		}

		FlxSpriteUtil.drawRect(graphNote, 0, graphNote.height * 0.5 - 1, graphNote.width, 2, 0x7FFFFFFF);

		if (ClientPrefs.data.marvelousRating)
		{
			FlxSpriteUtil.drawRect(graphNote, 0,
				graphNote.height * 0.5 + graphNote.height * 0.5 * MoveSize * (ClientPrefs.data.marvelousWindow / safeZoneOffset) - 1, graphNote.width, 2,
				ColorArrayAlpha[0]);
			FlxSpriteUtil.drawRect(graphNote, 0,
				graphNote.height * 0.5 - graphNote.height * 0.5 * MoveSize * (ClientPrefs.data.marvelousWindow / safeZoneOffset) - 1, graphNote.width, 2,
				ColorArrayAlpha[0]);
		} // marvelous

		if (!(ClientPrefs.data.marvelousWindow >= ClientPrefs.data.sickWindow && ClientPrefs.data.marvelousRating))
		{
			FlxSpriteUtil.drawRect(graphNote, 0,
				graphNote.height * 0.5 + graphNote.height * 0.5 * MoveSize * (ClientPrefs.data.sickWindow / safeZoneOffset) - 1, graphNote.width, 2,
				ColorArrayAlpha[1]);
			FlxSpriteUtil.drawRect(graphNote, 0,
				graphNote.height * 0.5 - graphNote.height * 0.5 * MoveSize * (ClientPrefs.data.sickWindow / safeZoneOffset) - 1, graphNote.width, 2,
				ColorArrayAlpha[1]);
		} // sick

		if ((ClientPrefs.data.marvelousWindow <= ClientPrefs.data.goodWindow && ClientPrefs.data.marvelousRating)
			|| ClientPrefs.data.sickWindow <= ClientPrefs.data.goodWindow)
		{
			FlxSpriteUtil.drawRect(graphNote, 0,
				graphNote.height * 0.5 + graphNote.height * 0.5 * MoveSize * (ClientPrefs.data.goodWindow / safeZoneOffset) - 1, graphNote.width, 2,
				ColorArrayAlpha[2]);
			FlxSpriteUtil.drawRect(graphNote, 0,
				graphNote.height * 0.5 - graphNote.height * 0.5 * MoveSize * (ClientPrefs.data.goodWindow / safeZoneOffset) - 1, graphNote.width, 2,
				ColorArrayAlpha[2]);
		} // good

		if ((ClientPrefs.data.marvelousWindow <= ClientPrefs.data.badWindow && ClientPrefs.data.marvelousRating)
			|| ClientPrefs.data.sickWindow <= ClientPrefs.data.badWindow
			|| ClientPrefs.data.goodWindow <= ClientPrefs.data.badWindow)
		{
			FlxSpriteUtil.drawRect(graphNote, 0,
				graphNote.height * 0.5 + graphNote.height * 0.5 * MoveSize * (ClientPrefs.data.badWindow / safeZoneOffset) - 1, graphNote.width, 2,
				ColorArrayAlpha[3]);
			FlxSpriteUtil.drawRect(graphNote, 0,
				graphNote.height * 0.5 - graphNote.height * 0.5 * MoveSize * (ClientPrefs.data.badWindow / safeZoneOffset) - 1, graphNote.width, 2,
				ColorArrayAlpha[3]);
		} // bad

		FlxSpriteUtil.drawRect(graphNote, 0, graphNote.height * 0.5 + graphNote.height * 0.5 * MoveSize - 1, graphNote.width, 2, ColorArrayAlpha[4]);
		FlxSpriteUtil.drawRect(graphNote, 0, graphNote.height * 0.5 - graphNote.height * 0.5 * MoveSize - 1, graphNote.width, 2, ColorArrayAlpha[4]);
		// shit

		FlxSpriteUtil.drawRect(graphNote, 0, graphNote.height * 0.5 + graphNote.height * 0.5 * 0.9 - 1, graphNote.width, 2, ColorArrayAlpha[3]);
		// miss

		graphNote.updateHitbox();
	}

	function percentRateAdd()
	{
		var numMarvelous:Int = 0;
		var numSicks:Int = 0;
		var numGoods:Int = 0;
		var numBads:Int = 0;
		var numShits:Int = 0;

		for (i in 0...Math.floor(game.NoteTime.length - 1))
		{
			if (Math.abs(game.NoteMs[i]) <= ClientPrefs.data.marvelousWindow && ClientPrefs.data.marvelousRating)
				numMarvelous++;
			else if (Math.abs(game.NoteMs[i]) <= ClientPrefs.data.sickWindow)
				numSicks++;
			else if (Math.abs(game.NoteMs[i]) <= ClientPrefs.data.goodWindow)
				numGoods++;
			else if (Math.abs(game.NoteMs[i]) <= ClientPrefs.data.badWindow)
				numBads++;
			else if (Math.abs(game.NoteMs[i]) <= safeZoneOffset)
				numShits++;
		}

		var height:Int = ClientPrefs.data.marvelousRating ? Std.int(300 / 5) : Std.int(300 / 4);
		if (ClientPrefs.data.marvelousRating)
			addRate(height, 'Marvelous', Reflect.field(ClientPrefs.data, 'marvelousWindow'), numMarvelous, ColorArray[0]);
		addRate(height, 'Sick', Reflect.field(ClientPrefs.data, 'sickWindow'), numSicks, ColorArray[1]);
		addRate(height, 'Good', Reflect.field(ClientPrefs.data, 'goodWindow'), numGoods, ColorArray[2]);
		addRate(height, 'Bad', Reflect.field(ClientPrefs.data, 'badWindow'), numBads, ColorArray[3]);
		addRate(height, 'Shit', (ClientPrefs.data.safeFrames / 60) * 1000, numShits, ColorArray[4]);
	}

	function addRate(height:Int, RateName:String, ms:Float, number:Int, color:FlxColor)
	{
		var numberBG:FlxSprite = new FlxSprite(percentBG.x + 5,
			percentBG.y + 5 + percentRectBGNumber.length * height).loadGraphic(createGraphic(Std.int(percentBG.width - 10), 30, 20, 20));
		numberBG.color = FlxColor.BLACK;
		numberBG.alpha = 0;
		numberBG.antialiasing = ClientPrefs.data.antialiasing;
		percentRectBGNumber.add(numberBG);

		var numberRect:FlxSprite = new FlxSprite(percentBG.x + 5,
			percentBG.y + 5 + percentRectNumber.length * height)
			.loadGraphic(createGraphic(Std.int((percentBG.width - 10) * (number / (game.NoteTime.length - 1))), 30, 20, 20));
		numberRect.color = color;
		numberRect.alpha = 0;
		numberRect.antialiasing = ClientPrefs.data.antialiasing;
		percentRectNumber.add(numberRect);

		var numberText = new FlxText(percentBG.x + 5, numberBG.y + numberBG.height, 0, RateName, 16);
		numberText.font = Paths.font('vcr.ttf');
		numberText.setBorderStyle(FlxTextBorderStyle.OUTLINE, FlxColor.BLACK, 1, 1);
		numberText.scrollFactor.set();
		numberText.antialiasing = ClientPrefs.data.antialiasing;
		numberText.alignment = LEFT;
		numberText.alpha = 0;
		numberText.color = color;
		percentTextNumber.add(numberText);

		var numberText = new FlxText(percentBG.x
			+ 5
			+ percentBG.width / 2, numberBG.y
			+ numberBG.height, 0,
			number
			+ '('
			+ Math.ceil(number / (game.NoteTime.length - 1) * 100 * 100) / 100
			+ '%)', 16);
		numberText.font = Paths.font('vcr.ttf');
		numberText.setBorderStyle(FlxTextBorderStyle.OUTLINE, FlxColor.BLACK, 1, 1);
		numberText.scrollFactor.set();
		numberText.antialiasing = ClientPrefs.data.antialiasing;
		numberText.alignment = LEFT;
		numberText.alpha = 0;
		numberText.color = color;
		numberText.x -= numberText.width * 0.5;
		percentTextNumber.add(numberText);

		var numberText = new FlxText(percentBG.x - 5 + percentBG.width, numberBG.y + numberBG.height, 0, Math.ceil(ms * 100) / 100 + 'MS', 16);
		numberText.font = Paths.font('vcr.ttf');
		numberText.setBorderStyle(FlxTextBorderStyle.OUTLINE, FlxColor.BLACK, 1, 1);
		numberText.scrollFactor.set();
		numberText.antialiasing = ClientPrefs.data.antialiasing;
		numberText.alignment = LEFT;
		numberText.alpha = 0;
		numberText.color = color;
		numberText.x -= numberText.width;
		percentTextNumber.add(numberText);
	}

	function createGraphic(Width:Int, Height:Int, ellipseWidth:Float, ellipseHeight:Float):BitmapData
	{
		var shape:Shape = new Shape();
		shape.graphics.beginFill(0xFFFFFF);
		shape.graphics.drawRoundRect(0, 0, Width, Height, ellipseWidth, ellipseHeight);
		shape.graphics.endFill();

		var bitmap:BitmapData = new BitmapData(Width, Height, true, 0);
		bitmap.draw(shape);
		return bitmap;
	}

	function startTween()
	{
		FlxTween.tween(background, {alpha: 1}, 1);

		new FlxTimer().start(1, function(tmr:FlxTimer)
		{
			FlxTween.tween(modsBG, {alpha: 0.5}, 0.5);
			FlxTween.tween(mesBG, {alpha: 0.5}, 0.5);
			FlxTween.tween(scBG, {alpha: 0.5}, 0.5);
			FlxTween.tween(opBG, {alpha: 0.5}, 0.5);

			FlxTween.tween(graphBG, {alpha: 0.5}, 0.5);
			FlxTween.tween(percentBG, {alpha: 0.5}, 0.5);
		});

		new FlxTimer().start(1, function(tmr:FlxTimer)
		{
			FlxTween.tween(modsMenu, {alpha: 1}, 0.5);
			FlxTween.tween(modsText, {alpha: 1}, 0.5);
		});

		new FlxTimer().start(1, function(tmr:FlxTimer)
		{
			for (i in 0...mesTextNumber.length)
			{
				var tweenTimer:FlxTimer = new FlxTimer();
				tweenTimer.start((0.5 - 0.1) / mesTextNumber.length * i, function(tmr:FlxTimer)
				{
					FlxTween.tween(mesTextNumber.members[i], {alpha: 1}, 0.1);
				});
			}

			for (i in 0...scTextNumber.length)
			{
				var tweenTimer:FlxTimer = new FlxTimer();
				tweenTimer.start((0.5 - 0.1) / scTextNumber.length * i, function(tmr:FlxTimer)
				{
					FlxTween.tween(scTextNumber.members[i], {alpha: 1}, 0.1);
				});
			}

			for (i in 0...opTextNumber.length)
			{
				var tweenTimer:FlxTimer = new FlxTimer();
				tweenTimer.start((0.5 - 0.1) / opTextNumber.length * i, function(tmr:FlxTimer)
				{
					FlxTween.tween(opTextNumber.members[i], {alpha: 1}, 0.1);
				});
			}
		});

		new FlxTimer().start(1, function(tmr:FlxTimer)
		{
			FlxTween.tween(graphNote, {alpha: 1}, 0.5);

			for (i in 0...percentRectBGNumber.length)
			{
				FlxTween.tween(percentRectBGNumber.members[i], {alpha: 1}, 0.3);
			}

			for (i in 0...percentRectNumber.length)
			{
				rectTween(percentRectNumber.members[i]);
			}

			for (i in 0...percentRectNumber.length)
			{
				FlxTween.tween(percentRectNumber.members[i], {alpha: 1}, 0.3);
			}

			for (i in 0...percentTextNumber.length)
			{
				FlxTween.tween(percentTextNumber.members[i], {alpha: 1}, 0.5);
			}
		});

		new FlxTimer().start(1, function(tmr:FlxTimer)
		{
			FlxTween.tween(backRect, {alpha: 1}, 0.5);
			if (!isFromFreeplay)
			{
				FlxTween.tween(saveReplayRect, {alpha: 1}, 0.5);
				FlxTween.tween(replayRect, {alpha: 1}, 0.5);
			}
		});
	}

	var swagRect:FlxRect;

	function rectTween(sprite:FlxSprite, tweenHeight:Bool = false, width:Int = 0, height:Int = 0)
	{
		if (width == 0)
			width = Std.int(sprite.width);
		if (height == 0)
			height = Std.int(sprite.height);

		var time:Float = 0;
		var maxTime:Float = 0.5;

		var timerTween:FlxTimer;

		timerTween = new FlxTimer().start(0.0001, function(tmr:FlxTimer)
		{
			time += FlxG.elapsed;
			if (time > maxTime)
				time = maxTime;

			if (swagRect == null)
				swagRect = new FlxRect(0, 0, 0, 0);
			swagRect.x = 0;
			swagRect.y = 0;
			if (tweenHeight)
			{
				swagRect.width = width;
				swagRect.height = height * (time / maxTime);
			}
			else
			{
				swagRect.width = width * (time / maxTime);
				swagRect.height = height;
			}
			sprite.clipRect = swagRect;

			if (time == maxTime)
			{
				timerTween.cancel();
			}
		}, 0);
	}

	// NewCustomFadeTransition is work for better close Substate
	var finishCallback:Void->Void;
	private var leTween:FlxTween = null;

	var isTransIn:Bool = false;

	var loadLeft:FlxSprite;
	var loadRight:FlxSprite;
	var loadAlpha:FlxSprite;
	var WaterMark:FlxText;
	var EventText:FlxText;

	var loadLeftTween:FlxTween;
	var loadRightTween:FlxTween;
	var loadAlphaTween:FlxTween;
	var EventTextTween:FlxTween;
	var loadTextTween:FlxTween;

	function NewCustomFadeTransition(isReplay:Bool = false)
	{
		var duration:Float = 0.6;
		var TransIn:Bool = false;

		isTransIn = TransIn;

		if (ClientPrefs.data.customFade == 'Move')
		{
			loadRight = new FlxSprite(isTransIn ? 0 : 1280, 0).loadGraphic(Paths.image('menuExtend/CustomFadeTransition/loadingR'));
			loadRight.scrollFactor.set();
			loadRight.antialiasing = ClientPrefs.data.antialiasing;
			add(loadRight);
			loadRight.cameras = [camOther];
			loadRight.setGraphicSize(FlxG.width, FlxG.height);
			loadRight.updateHitbox();

			loadLeft = new FlxSprite(isTransIn ? 0 : -1280, 0).loadGraphic(Paths.image('menuExtend/CustomFadeTransition/loadingL'));
			loadLeft.scrollFactor.set();
			loadLeft.antialiasing = ClientPrefs.data.antialiasing;
			add(loadLeft);
			loadLeft.cameras = [camOther];
			loadLeft.setGraphicSize(FlxG.width, FlxG.height);
			loadLeft.updateHitbox();

			WaterMark = new FlxText(isTransIn ? 50 : -1230, 720 - 50 - 50 * 2, 0, 'NF ENGINE V' + MainMenuState.novaFlareEngineVersion, 50);
			WaterMark.scrollFactor.set();
			WaterMark.setFormat(Assets.getFont("assets/fonts/loadText.ttf").fontName, 50, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			WaterMark.antialiasing = ClientPrefs.data.antialiasing;
			add(WaterMark);
			WaterMark.cameras = [camOther];

			EventText = new FlxText(isTransIn ? 50 : -1230, 720 - 50 - 50, 0, 'LOADING . . . . . . ', 50);
			EventText.scrollFactor.set();
			EventText.setFormat(Assets.getFont("assets/fonts/loadText.ttf").fontName, 50, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			EventText.antialiasing = ClientPrefs.data.antialiasing;
			add(EventText);
			EventText.cameras = [camOther];

			FlxG.sound.play(Paths.sound('loading_close_move'), ClientPrefs.data.customFadeSound);
			if (!ClientPrefs.data.customFadeText)
			{
				EventText.text = '';
				WaterMark.text = '';
			}
			loadLeftTween = FlxTween.tween(loadLeft, {x: 0}, duration, {
				onComplete: function(twn:FlxTween)
				{
					FlxTransitionableState.skipNextTransIn = true;
					if (isReplay)
					{
						MusicBeatState.resetState();
					}
					else
					{
						Mods.loadTopMod();
						MusicBeatState.switchState(new FreeplayState());
					}
				},
				ease: FlxEase.expoInOut
			});

			loadRightTween = FlxTween.tween(loadRight, {x: 0}, duration, {
				onComplete: function(twn:FlxTween)
				{
					if (finishCallback != null)
					{
						finishCallback();
					}
				},
				ease: FlxEase.expoInOut
			});

			loadTextTween = FlxTween.tween(WaterMark, {x: 50}, duration, {
				onComplete: function(twn:FlxTween)
				{
					if (finishCallback != null)
					{
						finishCallback();
					}
				},
				ease: FlxEase.expoInOut
			});

			EventTextTween = FlxTween.tween(EventText, {x: 50}, duration, {
				onComplete: function(twn:FlxTween)
				{
					if (finishCallback != null)
					{
						finishCallback();
					}
				},
				ease: FlxEase.expoInOut
			});
		}
		else
		{
			loadAlpha = new FlxSprite(0, 0).loadGraphic(Paths.image('menuExtend/CustomFadeTransition/loadingAlpha'));
			loadAlpha.scrollFactor.set();
			loadAlpha.antialiasing = ClientPrefs.data.antialiasing;
			add(loadAlpha);
			loadAlpha.cameras = [camOther];
			loadAlpha.setGraphicSize(FlxG.width, FlxG.height);
			loadAlpha.updateHitbox();

			WaterMark = new FlxText(50, 720 - 50 - 50 * 2, 0, 'NF ENGINE V' + MainMenuState.novaFlareEngineVersion, 50);
			WaterMark.scrollFactor.set();
			WaterMark.setFormat(Assets.getFont("assets/fonts/loadText.ttf").fontName, 50, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			WaterMark.antialiasing = ClientPrefs.data.antialiasing;
			add(WaterMark);
			WaterMark.cameras = [camOther];

			EventText = new FlxText(50, 720 - 50 - 50, 0, 'LOADING . . . . . . ', 50);
			EventText.scrollFactor.set();
			EventText.setFormat(Assets.getFont("assets/fonts/loadText.ttf").fontName, 50, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			EventText.antialiasing = ClientPrefs.data.antialiasing;
			add(EventText);
			EventText.cameras = [camOther];

			FlxG.sound.play(Paths.sound('loading_close_alpha'), ClientPrefs.data.customFadeSound);
			if (!ClientPrefs.data.customFadeText)
			{
				EventText.text = '';
				WaterMark.text = '';
			}
			WaterMark.alpha = 0;
			EventText.alpha = 0;
			loadAlpha.alpha = 0;
			loadAlphaTween = FlxTween.tween(loadAlpha, {alpha: 1}, duration, {
				onComplete: function(twn:FlxTween)
				{
					FlxTransitionableState.skipNextTransIn = true;
					if (isReplay)
					{
						MusicBeatState.resetState();
					}
					else
					{
						Mods.loadTopMod();
						MusicBeatState.switchState(new FreeplayState());
					}
				},
				ease: FlxEase.sineInOut
			});

			loadTextTween = FlxTween.tween(WaterMark, {alpha: 1}, duration, {
				onComplete: function(twn:FlxTween)
				{
					if (finishCallback != null)
					{
						finishCallback();
					}
				},
				ease: FlxEase.sineInOut
			});

			EventTextTween = FlxTween.tween(EventText, {alpha: 1}, duration, {
				onComplete: function(twn:FlxTween)
				{
					if (finishCallback != null)
					{
						finishCallback();
					}
				},
				ease: FlxEase.sineInOut
			});
		}
	}

	override function destroy()
	{
		if (leTween != null)
		{
			finishCallback();
			leTween.cancel();

			if (loadLeftTween != null)
				loadLeftTween.cancel();
			if (loadRightTween != null)
				loadRightTween.cancel();
			if (loadAlphaTween != null)
				loadAlphaTween.cancel();

			loadTextTween.cancel();
			EventTextTween.cancel();
		}
		super.destroy();
	}

	/*function loadBackShader()
	{
		var frag:String = "
		#pragma header

		// by HeiHua

		const vec2 blur_size = [100,100];

		const float sigma = 0.10132118364233777144387946320973;
		const float q = 1.5;

		void main()
		{
			vec2 uv = openfl_TextureCoordv;
			if (blur_size.x == 0.0 && blur_size.y == 0.0)
			{
				gl_FragColor = texture2D(bitmap, uv);
				return;
			}

			float kernelRadius = 1.0 / length(blur_size) * q;

			vec2 size = 1.0 / openfl_TextureSize * blur_size;
			float totalWeight = 0.0;
			vec4 accumColor = vec4(0.0);

			float twoSigma2 = 2.0 * sigma;
			float sqrtTwoPiSigma = sqrt(3.1415926 * twoSigma2);

			for (float i = -0.5; i <= 0.5; i += kernelRadius)
			{
				float weight = exp(-(i*i) / twoSigma2) / sqrtTwoPiSigma;
		
				vec2 offset = size * i;
				accumColor += texture2D(bitmap, uv + offset) * weight;
				totalWeight += weight;
			}

			gl_FragColor = accumColor / totalWeight;
		}";
		var shader = new FlxRuntimeShader(frag, null);

		filter = new ShaderFilter(shader);
		return filter;
	}
		*/
}

