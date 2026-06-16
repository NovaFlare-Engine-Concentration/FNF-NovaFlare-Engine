package states.mainMenuState;

import haxe.Json;

import sys.thread.Thread;
import sys.thread.Mutex;

import openfl.Lib;

import funkin.vis.dsp.MusicBPMDetector;

import flixel.FlxObject;
import flixel.effects.FlxFlicker;
import flixel.addons.display.FlxBackdrop;
import flixel.input.keyboard.FlxKey;
import flixel.ui.FlxButton;

import general.objects.AchievementPopup;

import developer.editors.MasterEditorMenu;

import options.OptionsState;

import games.backend.WeekData;

import states.storyMenuState.StoryMenuState;
import states.freeplayState.FreeplayState;
import states.modsMenuState.ModsMenuState;
import states.achievementsMenuState.AchievementsMenuState;
import states.creditsState.CreditsState;
import states.titleState.TitleState;

import cpp.Lib;

@:access(flixel.sound.FlxSound._sound)
@:access(openfl.media.Sound.__buffer)
class MainMenuState extends MusicBeatState
{
	public static var psychEngineVersion:String = '0.7.3'; // This is also used for Discord RPC
	public static var novaFlareEngineDataVersion:Float = 2.9;
	public static var novaFlareEngineVersion:String = '1.2.1';
	public static var novaFlareEngineCommit:String = 
	    #if commit_sha
            haxe.macro.Compiler.getDefine("commit_sha");
        #else
            "dev";
        #end

	public static var NovaFlareGithubAction:String = '????';
	public static var createTime:String = 'Time: ????';

	public static var curSelected:Int = 0;
	public static var saveCurSelected:Int = 0;

	var menuItems:FlxTypedGroup<FlxSprite>;

	public var camGame:FlxCamera;
	public var camHUD:FlxCamera;
	public var camOther:FlxCamera;

	var optionTween:Array<FlxTween> = [];
	var selectedTween:Array<FlxTween> = [];
	var cameraTween:Array<FlxTween> = [];
	var logoTween:FlxTween;

	var optionShit:Array<String> = [
		'story_mode',
		'freeplay',
		#if MODS_ALLOWED 'mods', #end
		#if ACHIEVEMENTS_ALLOWED 'awards', #end
		'credits',
		// #if !switch 'donate', #end
		'options'
	];

	var magenta:FlxSprite;
	var logoBl:FlxSprite;

	// var musicDisplay:SpectogramSprite;
	// var camFollow:FlxObject;
	var SoundTime:Float = 0;
	var BeatTime:Float = 0;

	var ColorArray:Array<Int> = [
		0xFF9400D3,
		0xFF4B0082,
		0xFF0000FF,
		0xFF00FF00,
		0xFFFFFF00,
		0xFFFF7F00,
		0xFFFF0000
	];

	public static var currentColor:Int = 1;
	public static var currentColorAgain:Int = 0;

	public static var Mainbpm:Float = 0;
	public static var bpm:Float = 0;

	var StatusIcon:FlxSprite;
	var ActionStatus:Dynamic;

	override function create()
	{
		Paths.clearStoredMemory();
		Paths.clearUnusedMemory();

		Mainbpm = TitleState.bpm;
		bpm = TitleState.bpm;

		#if MODS_ALLOWED
		Mods.pushGlobalMods();
		#end
		Mods.loadTopMod();

		#if DISCORD_ALLOWED
		// Updating Discord Rich Presence
		DiscordClient.changePresence("In the Menus", null);
		#end

		camGame = initPsychCamera();

		camHUD = new FlxCamera();
		camOther = new FlxCamera();

		camOther.bgColor.alpha = 0;
		camHUD.bgColor.alpha = 0;

		FlxG.cameras.add(camHUD, false);
		FlxG.cameras.add(camOther, false);

		persistentUpdate = persistentDraw = true;

		//Language.resetData();

		var yScroll:Float = Math.max(0.25 - (0.05 * (optionShit.length - 4)), 0.1);
		var bg:FlxSprite = new FlxSprite(-80).loadGraphic(Paths.image('menuBG', null, false));
		bg.scrollFactor.set(0, 0);
		bg.scale.x = FlxG.width / bg.width;
		bg.scale.y = FlxG.height / bg.height;
		bg.updateHitbox();
		bg.screenCenter();
		bg.antialiasing = ClientPrefs.data.antialiasing;
		add(bg);

		var test:AudioDisplay = new AudioDisplay(FlxG.sound.music, 0, FlxG.height, FlxG.width, Std.int(FlxG.height / 2), 100, 4, FlxColor.WHITE);
		add(test);
		test.alpha = 0.7;

		bg.scrollFactor.set(0, 0);

		logoBl = new FlxSprite(0, 0);
		logoBl.frames = Paths.getSparrowAtlas('logoBumpin');
		logoBl.antialiasing = ClientPrefs.data.antialiasing;
		logoBl.animation.addByPrefix('bump', 'logo bumpin', 24, false);
		logoBl.animation.play('bump');
		logoBl.offset.x = 0;
		logoBl.offset.y = 0;
		//trace(logoBl.frameWidth);
		logoBl.scale.x = (640 / logoBl.frameWidth);
		logoBl.scale.y = logoBl.scale.x;
		logoBl.updateHitbox();
		add(logoBl);
		logoBl.scrollFactor.set(0, 0);
		logoBl.x = 1280 + 320 - logoBl.width / 2;
		logoBl.y = 360 - logoBl.height / 2;
		logoTween = FlxTween.tween(logoBl, {x: 1280 - 320 - logoBl.width / 2}, 0.6, {ease: FlxEase.backInOut});

		menuItems = new FlxTypedGroup<FlxSprite>();
		add(menuItems);

		var scale:Float = 0.6;
		if (optionShit.length > 6)
		{
			scale = 6 / optionShit.length;
		}

		for (i in 0...optionShit.length)
		{
			var menuItem:FlxSprite = new FlxSprite(-600, 0);
			menuItem.scale.x = scale;
			menuItem.scale.y = scale;
			menuItem.frames = Paths.getSparrowAtlas('mainmenu/menu_' + optionShit[i]);
			menuItem.animation.addByPrefix('idle', optionShit[i] + " basic", 24);
			menuItem.animation.addByPrefix('selected', optionShit[i] + " white", 24);
			menuItem.animation.play('idle');
			menuItem.ID = i;

			menuItems.add(menuItem);
			var scr:Float = (optionShit.length - 4) * 0.135;
			if (optionShit.length < 6)
				scr = 0;
			menuItem.antialiasing = ClientPrefs.data.antialiasing;
			// menuItem.setGraphicSize(Std.int(menuItem.width * 0.58));
			menuItem.updateHitbox();

			if (menuItem.ID == curSelected)
			{
				menuItem.animation.play('selected');
				menuItem.updateHitbox();
			}
		}

		for (i in 0...optionShit.length)
		{
			var option:FlxSprite = menuItems.members[i];

			if (optionShit.length % 2 == 0)
			{
				option.y = 360 + (i - optionShit.length / 2) * 110;
				// option.y += 20;
			}
			else
			{
				option.y = 360 + (i - (optionShit.length / 2 + 0.5)) * 135;
			}
			optionTween[i] = FlxTween.tween(option, {x: 100}, 0.7 + 0.08 * i, {
				ease: FlxEase.backInOut
			});
		}

			/*
			var test = new RoundRect(200, 300, 300, 100, 20, LEFT_UP);
			test.alpha = 0.3;
			add(test);
			new FlxTimer().start(0.6, function(tmr:FlxTimer){
			test.changeWidth(100, 0.6);
			});		
			new FlxTimer().start(1.2, function(tmr:FlxTimer){
			test.changeWidth(500, 0.6);
			test.changeHeight(500, 0.6);
			});
			*/
		/*
		var thread = Thread.create(() ->
		{
			updateGitAction(function(result)
			{
				ActionStatus = result;
			});
			trace(NovaFlareGithubAction);
			try
			{
				createTime = StringTools.replace(createTime, "T", " ");
				createTime = StringTools.replace(createTime, "Z", " ");
				createTime = StringTools.replace(createTime, "U C", "UTC"); // fix
				var updateShit:FlxText = new FlxText(0, 10, 0, NovaFlareGithubAction + '\n' + createTime, 12);

				updateShit.setFormat(Paths.font('Lang-ZH.ttf'), 16, FlxColor.WHITE, RIGHT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
				updateShit.x = FlxG.width - updateShit.width - 10;
				updateShit.antialiasing = ClientPrefs.data.antialiasing;
				add(updateShit);
				updateShit.cameras = [camHUD];

				StatusIcon = new FlxSprite(0, 0);
				StatusIcon.frames = Paths.getSparrowAtlas('menuExtend/MainMenu/gitAction', null, false);
				StatusIcon.updateHitbox();

				StatusIcon.animation.addByPrefix('in_progress', "in_progress", 24);
				StatusIcon.animation.addByPrefix('queued', "queued", 24);
				StatusIcon.animation.addByPrefix('cancelled', "cancelled", 24);
				StatusIcon.animation.addByPrefix('failure', "failure", 24);
				StatusIcon.animation.addByPrefix('success', "success", 24);

				StatusIcon.cameras = [camHUD];
				add(StatusIcon);
				trace(ActionStatus.status);
				trace(ActionStatus.conclusion);
				if (ActionStatus.status == 'in_progress')
				{
					StatusIcon.animation.play('in_progress');
				}
				else if (ActionStatus.status == 'queued')
				{
					StatusIcon.animation.play('queued');
				}
				else if (ActionStatus.status == 'cancelled')
				{
					StatusIcon.animation.play('cancelled');
				}
				else if (ActionStatus.status == 'failure')
				{
					StatusIcon.animation.play('failure');
				}
				else if (ActionStatus.status == 'completed')
				{
					// complete只是标记这个工作流有没有完成
					if (ActionStatus.conclusion == 'success')
					{
						StatusIcon.animation.play('success');
					}
					else if (ActionStatus.conclusion == 'cancelled')
					{
						StatusIcon.animation.play('cancelled');
					}
					else if (ActionStatus.conclusion == 'failure')
					{
						StatusIcon.animation.play('failure');
					}
				}

				StatusIcon.scale.x = StatusIcon.scale.y = 0.5;
				StatusIcon.x = FlxG.width - StatusIcon.width * StatusIcon.scale.x / 2 * 3 - 10;
				StatusIcon.y = updateShit.height + 10 - StatusIcon.height * StatusIcon.scale.y / 2;
			}
		}); */

		var versionShit:FlxText = new FlxText(12, FlxG.height - 44, 400, Language.get('novaFlareEngine', 'mainmenu') + " v " + novaFlareEngineVersion, 12);
		versionShit.scrollFactor.set();
		versionShit.setFormat(Paths.font(Language.get('fontName', 'main') + '.ttf'), 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		versionShit.antialiasing = ClientPrefs.data.antialiasing;
		add(versionShit);
		versionShit.cameras = [camHUD];
		var versionShit:FlxText = new FlxText(12, FlxG.height - 24, 0, Language.get('fridayNightFunkin', 'mainmenu') + " v " + '0.2.8', 12);
		versionShit.scrollFactor.set();
		versionShit.setFormat(Paths.font(Language.get('fontName', 'main') + '.ttf'), 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		add(versionShit);
		versionShit.antialiasing = ClientPrefs.data.antialiasing;
		versionShit.cameras = [camHUD];

		checkChoose();

		#if ACHIEVEMENTS_ALLOWED
		// Unlocks "Freaky on a Friday Night" achievement if it's a Friday and between 18:00 PM and 23:59 PM
		var leDate = Date.now();
		if (leDate.getDay() == 5 && leDate.getHours() >= 18)
			Achievements.unlock('friday_night_play');

		#if MODS_ALLOWED
		Achievements.reloadList();
		#end
		#end

		FlxG.mouse.visible = !ClientPrefs.data.needMobileControl;

		addVirtualPad(MainMenuStateC, A_B_E);
		virtualPad.cameras = [camHUD];

		/*
		var soundBuffer = FlxG.sound.music;

		var detector = new MusicBPMDetector();
		var result = detector.detect(soundBuffer._sound.__buffer);

		trace("BPM Result: " + result.bpm);
		*/
		
		super.create();
	}

	var canClick:Bool = true;
	var canBeat:Bool = true;
	var usingMouse:Bool = true;

	var endCheck:Bool = false;

	override function update(elapsed:Float)
	{
		#if (debug && android)
		if (FlxG.android.justReleased.BACK)
			FlxG.debugger.visible = !FlxG.debugger.visible;
		#end

		if (ActionStatus != null)
			if (ActionStatus.status == 'in_progress')
				if (StatusIcon != null)
					StatusIcon.angle += 6 * (elapsed / (1 / 60));

		if (FlxG.sound.music.volume < 0.8)
		{
			FlxG.sound.music.volume += 0.5 * FlxG.elapsed;
		}

		FlxG.camera.followLerp = FlxMath.bound(elapsed * 9 / (FlxG.updateFramerate / 60), 0, 1);

		if (FlxG.mouse.justPressed)
			usingMouse = true;

		if (!endCheck)
		{
			if (controls.UI_UP_P)
			{
				usingMouse = false;
				FlxG.sound.play(Paths.sound('scrollMenu'));
				curSelected--;
				checkChoose();
			}

			if (controls.UI_DOWN_P)
			{
				usingMouse = false;
				FlxG.sound.play(Paths.sound('scrollMenu'));
				curSelected++;
				checkChoose();
			}

			if (controls.ACCEPT)
			{
				usingMouse = false;

				menuItems.forEach(function(spr:FlxSprite)
				{
					if (curSelected == spr.ID)
					{
						if (spr.animation.curAnim.name == 'selected')
						{
							canClick = false;
							checkChoose();
							selectSomething();
						}
						else
						{
							FlxG.sound.play(Paths.sound('scrollMenu'));
							spr.animation.play('selected');
						}
					}
				});
			}

			if (menuItems != null) menuItems.forEach(function(spr:FlxSprite)
			{
				if (usingMouse && canClick)
				{
					if (!FlxG.mouse.overlaps(spr))
					{
						if (FlxG.mouse.pressed #if mobile && !FlxG.mouse.overlaps(virtualPad.buttonA) #end)
						{
							spr.animation.play('idle');
						}
						if (FlxG.mouse.justReleased #if mobile && !FlxG.mouse.overlaps(virtualPad.buttonA) #end)
						{
							spr.animation.play('idle');
						} // work better for use virtual pad
					}
					if (FlxG.mouse.overlaps(spr))
					{
						if (FlxG.mouse.justPressed)
						{
							if (spr.animation.curAnim.name == 'selected')
								selectSomething();
							else
								spr.animation.play('idle');
						}
						curSelected = spr.ID;

						if (spr.animation.curAnim.name == 'idle')
						{
							FlxG.sound.play(Paths.sound('scrollMenu'));
							spr.animation.play('selected');
						}

						menuItems.forEach(function(spr:FlxSprite)
						{
							if (spr.ID != curSelected)
							{
								spr.animation.play('idle');
								spr.centerOffsets();
							}
						});
					}
					if (saveCurSelected != curSelected)
						checkChoose();
				}
			});

			if (controls.BACK)
			{
				endCheck = true;
				FlxG.sound.play(Paths.sound('cancelMenu'));
				MusicBeatState.switchState(new TitleState());
			}
			else if (controls.justPressed('debug_1') || virtualPad.buttonE.justPressed)
			{
				endCheck = true;
				MusicBeatState.switchState(new MasterEditorMenu());
			}
		}

		SoundTime = FlxG.sound.music.time / 1000;
		BeatTime = 60 / bpm;

		if (Math.floor(SoundTime / BeatTime) % 4 == 0 && canClick && canBeat)
		{
			canBeat = false;

			currentColor++;
			if (currentColor > 6)
				currentColor = 1;
			currentColorAgain = currentColor - 1;
			if (currentColorAgain <= 0)
				currentColorAgain = 6;

			logoBl.animation.play('bump');

			camGame.zoom = 1 + 0.015;
			cameraTween[0] = FlxTween.tween(camGame, {zoom: 1}, 0.6, {ease: FlxEase.cubeOut});

			menuItems.forEach(function(spr:FlxSprite)
			{
				spr.scale.x = 0.63;
				spr.scale.y = 0.63;
				FlxTween.tween(spr.scale, {x: 0.6}, 0.6, {ease: FlxEase.cubeOut});
				FlxTween.tween(spr.scale, {y: 0.6}, 0.6, {ease: FlxEase.cubeOut});
			});
		}
		if (Math.floor(SoundTime / BeatTime + 0.5) % 4 == 2)
			canBeat = true;

		menuItems.forEach(function(spr:FlxSprite)
		{
			spr.updateHitbox();
			spr.centerOffsets();
			spr.centerOrigin();
		});

		super.update(elapsed);
	}

	function selectSomething()
	{
		endCheck = true;
		FlxG.sound.play(Paths.sound('confirmMenu'));
		canClick = false;

		for (i in 0...optionShit.length)
		{
			var option:FlxSprite = menuItems.members[i];
			if (optionTween[i] != null)
				optionTween[i].cancel();
			if (i != curSelected)
				optionTween[i] = FlxTween.tween(option, {x: -800}, 0.6 + 0.1 * Math.abs(curSelected - i), {
					ease: FlxEase.backInOut,
					onComplete: function(twn:FlxTween)
					{
						option.kill();
					}
				});
		}

		if (cameraTween[0] != null)
			cameraTween[0].cancel();

		menuItems.forEach(function(spr:FlxSprite)
		{
			if (curSelected == spr.ID)
			{
				// spr.animation.play('selected');
				var scr:Float = (optionShit.length - 4) * 0.135;
				if (optionShit.length < 6)
					scr = 0;
				FlxTween.tween(spr, {y: 360 - spr.height / 2}, 0.6, {
					ease: FlxEase.backInOut
				});

				FlxTween.tween(spr, {x: 640 - spr.width / 2}, 0.6, {
					ease: FlxEase.backInOut
				});
			}
		});

		if (logoTween != null)
			logoTween.cancel();
		logoTween = FlxTween.tween(logoBl, {x: 1280 + 320 - logoBl.width / 2}, 0.6, {ease: FlxEase.backInOut});

		FlxTween.tween(camGame, {zoom: 2}, 1.2, {ease: FlxEase.cubeInOut});
		FlxTween.tween(camHUD, {zoom: 2}, 1.2, {ease: FlxEase.cubeInOut});
		FlxTween.tween(camGame, {angle: 0}, 0.8, { // not use for now
			ease: FlxEase.cubeInOut,
			onComplete: function(twn:FlxTween)
			{
				var daChoice:String = optionShit[curSelected];

				switch (daChoice)
				{
					case 'story_mode':
						MusicBeatState.switchState(new StoryMenuState());
					case 'freeplay':
							MusicBeatState.switchState(new FreeplayState());
					#if MODS_ALLOWED
					case 'mods':
						MusicBeatState.switchState(new ModsMenuState());
					#end
					case 'awards':
						MusicBeatState.switchState(new AchievementsMenuState());
					case 'credits':
						MusicBeatState.switchState(new CreditsState());
					case 'options':
						if (ClientPrefs.data.optionMusic != 'None')
						{
							FlxG.sound.playMusic(Paths.music('Options Screen/' + ClientPrefs.data.optionMusic), 0);
						}
						MusicBeatState.switchState(new OptionsState());
						// OptionsState.onPlayState = false;
						if (PlayState.SONG != null)
						{
							PlayState.SONG.arrowSkin = null;
							PlayState.SONG.splashSkin = null;
						}
				}
			}
		});
	}

	function checkChoose()
	{
		if (curSelected >= menuItems.length)
			curSelected = 0;
		if (curSelected < 0)
			curSelected = menuItems.length - 1;

		saveCurSelected = curSelected;

		menuItems.forEach(function(spr:FlxSprite)
		{
			if (spr.ID != curSelected)
			{
				spr.animation.play('idle');
				spr.centerOffsets();
			}

			if (spr.ID == curSelected && spr.animation.curAnim.name != 'selected')
			{
				spr.animation.play('selected');
				spr.centerOffsets();
			}

			spr.updateHitbox();
		});
	}

	function updateGitAction(callback:({status: String, conclusion: String}->Void)):Void
	{
		try
		{
			trace('checking for Github Action');
			var http = new haxe.Http("https://api.github.com/repos/beihu235/FNF-NovaFlare-Engine/actions/runs?per_page=1");
			http.setHeader("User-Agent", "NovaFlareEngine");

			http.onData = function(data:String)
			{
				var actionJson = Json.parse(data);
				MainMenuState.NovaFlareGithubAction = actionJson.workflow_runs[0].display_title;
				MainMenuState.createTime = 'UTC-' + actionJson.workflow_runs[0].updated_at + '\nBy ' + actionJson.workflow_runs[0].actor.login;
				var Sus = actionJson.workflow_runs[0].status;
				var Con = actionJson.workflow_runs[0].conclusion;
				callback({status: Sus, conclusion: Con});
			};

			http.onError = function(error)
			{
				MainMenuState.NovaFlareGithubAction = '$error';
				trace('error: $error');
				callback({status: "error", conclusion: "error"});
			};

			http.request();
		}
		catch (e:Dynamic)
		{
			trace('exception: $e');
			callback({status: "exception", conclusion: "exception"});
		}
	}
}
