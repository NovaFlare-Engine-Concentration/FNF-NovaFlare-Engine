package states.backend.initState;

import sys.thread.Thread;

import lime.app.Application;
import lime.system.System as LimeSystem;
import lime.graphics.opengl.GL;
import lime.graphics.Image;

import openfl.display.Bitmap;
import openfl.display.BitmapData;
import openfl.events.KeyboardEvent;

import flixel.input.gamepad.FlxGamepad;

import states.storyMenuState.StoryMenuState;
import states.backend.flashingState.FlashingState;
import states.backend.outdatedState.OutdatedState;
import states.mainMenuState.MainMenuState;
import states.freeplayState.FreeplayState;
import states.titleState.TitleState;

import scripts.init.InitScriptData;

import general.shaders.ColorblindFilter;
import gameanalytics.GABridge;

import games.backend.WeekData;
import games.backend.Highscore;
import games.backend.Song;

#if mobile
import mobile.states.CopyState;
#end

#if hxvlc
import hxvlc.flixel.FlxVideoSprite;
#end

#if android
import general.backend.device.AppData;
import states.backend.pirateState.PirateState;
#end

class InitState extends MusicBeatState
{
	var skipVideo:FlxText;

	var mustUpdate:Bool = false;

	public static var updateVersion:String = '';

	public static var ignoreCopy = false; //用于copystate，别删

	override public function create()
	{
		FlxTransitionableState.skipNextTransIn = true;
		FlxTransitionableState.skipNextTransOut = true;

		FlxG.fixedTimestep = false;
		FlxG.game.focusLostFramerate = 60;
		FlxG.keys.preventDefaultKeys = [TAB];

		super.create();

		FlxG.save.bind('funkin', CoolUtil.getSavePath());

		ClientPrefs.loadPrefs();

		#if ACHIEVEMENTS_ALLOWED Achievements.load(); #end
		GABridge.init();

		switch (ClientPrefs.data.gameQuality)
		{
			case 0:
				FlxG.game.stage.quality = openfl.display.StageQuality.LOW;
			case 1:
				FlxG.game.stage.quality = openfl.display.StageQuality.HIGH;
			case 2:
				FlxG.game.stage.quality = openfl.display.StageQuality.MEDIUM;
			case 3:
				FlxG.game.stage.quality = openfl.display.StageQuality.BEST;
		}

		#if mobile
		FlxG.fullscreen = true;
		#end

		#if desktop FlxG.stage.addEventListener(KeyboardEvent.KEY_UP, Main.toggleFullScreen); #end

		#if android FlxG.android.preventDefaultKeys = [BACK]; #end

		#if mobile
		LimeSystem.allowScreenTimeout = ClientPrefs.data.screensaver;
		#end

		#if html5
		FlxG.autoPause = false;
		FlxG.mouse.visible = false;
		#end

		// shader coords fix
		FlxG.signals.gameResized.add(function(w, h)
		{
			if (FlxG.cameras != null)
			{
				for (cam in FlxG.cameras.list)
				{
					if (cam != null && cam.filters != null)
						Main.resetSpriteCache(cam.flashSprite);
				}
			}

			if (FlxG.game != null)
				Main.resetSpriteCache(FlxG.game);
		});		

		var maxTextureSize:Int = GL.getParameter(GL.MAX_TEXTURE_SIZE);
		trace('maxTextureSize: ' + maxTextureSize);
		Image.setMaxTextureSize(maxTextureSize);

		trace("GL_VENDOR=" + GL.getString(GL.VENDOR));
		trace("GL_RENDERER=" + GL.getString(GL.RENDERER));
		trace("GL_VERSION=" + GL.getString(GL.VERSION));

		Language.resetData();

		#if CHECK_FOR_UPDATES
		if (ClientPrefs.data.checkForUpdates)
		{
			var thread = Thread.create(() ->
        	{
				try
				{
					trace('checking for update');
					var http = new haxe.Http("https://raw.githubusercontent.com/NovaFlare-Engine-Concentration/FNF-NovaFlare-Engine/refs/heads/main/gitVersion.txt");
		
					http.onData = function(data:String)
					{
						updateVersion = data.split('\n')[0].trim();
						var curVersion:Float = MainMenuState.novaFlareEngineDataVersion;
						trace('version online: ' + data.split('\n')[0].trim() + ', your version: ' + MainMenuState.novaFlareEngineVersion);
						if (Std.parseFloat(updateVersion) > curVersion)
						{
							trace('versions arent matching!');
							mustUpdate = true;
						}
					}
		
					http.onError = function(error)
					{
						trace('error: $error');
					}
		
					http.request();
				}
			});
		}
		#end

		#if mobile
		if (ClientPrefs.data.filesCheck)
		{
			if (!CopyState.checkExistingFiles())
			{
				FlxG.switchState(new CopyState());
				return;
			}
		}

        // 检查assets/version.txt存不存在且里面保存的上一个版本号与当前的版本号一不一致，如果不一致或不存在，强制启动copy。
        if (!FileSystem.exists(Paths.getSharedPath('version.txt')))
        {
            sys.io.File.saveContent(Paths.getSharedPath('version.txt'), 'now version: ' + Std.string(states.mainMenuState.MainMenuState.novaFlareEngineVersion) + '\n' + 'commit: ' + Std.string(states.mainMenuState.MainMenuState.novaFlareEngineCommit));
            FlxG.switchState(new CopyState(true));
            return;
        }
        else
        {
            var expectedContent = 'now version: ' + Std.string(states.mainMenuState.MainMenuState.novaFlareEngineVersion) + '\n' + 'commit: ' + Std.string(states.mainMenuState.MainMenuState.novaFlareEngineCommit);
            var actualContent = sys.io.File.getContent(Paths.getSharedPath('version.txt'));
            
            if (actualContent != expectedContent)
            {
                sys.io.File.saveContent(Paths.getSharedPath('version.txt'), expectedContent);
                FlxG.switchState(new CopyState(true));
                return;
            }
        }

		#end

		Highscore.load();

		#if LUA_ALLOWED
		#if (android && EXTERNAL || MEDIA)
		try
		{
		#end
			Mods.pushGlobalMods();
		#if (android && EXTERNAL || MEDIA)
		}
		catch (e:Dynamic)
		{
			SUtil.showPopUp("permission is not obtained, restart the application", "Error!");
			Sys.exit(1);
		}
		#end
		#end

		Mods.loadTopMod();

		if (FlxG.save.data != null && FlxG.save.data.fullscreen)
		{
			FlxG.fullscreen = FlxG.save.data.fullscreen;
			// trace('LOADED FULLSCREEN SETTING!!');
		}
		persistentUpdate = true;
		persistentDraw = true;

		InitScriptData.init();
		Main.initScriptModules();
		#if HSCRIPT_ALLOWED
		scripts.stages.modules.ModuleHandler.init();
		scripts.stages.GlobalHandler.init();
		#end

		ColorblindFilter.UpdateColors();
	
		if (FlxG.save.data.weekCompleted != null)
		{
			StoryMenuState.weekCompleted = FlxG.save.data.weekCompleted;
		}

		#if sys
		if (startDiagnosticGameplay())
			return;
		#end
	
		FlxG.mouse.visible = false;
		#if FREEPLAY
		MusicBeatState.switchState(new FreeplayState());
		#elseif CHARTING
		MusicBeatState.switchState(new ChartingState());
		#else
		if (FlxG.save.data.openedFlash == null)
		{
			FlxG.save.data.openedFlash = true;
			//ClientPrefs.saveSettings();
			FlxTransitionableState.skipNextTransIn = true;
			FlxTransitionableState.skipNextTransOut = true;
			MusicBeatState.switchState(new FlashingState());
		}
		else
		{
			startCutscenesIn();
		}
		#end
	}

	#if sys
	function startDiagnosticGameplay():Bool
	{
		var requestedSong:String = Sys.getEnv('NOVAFLARE_DIAGNOSTIC_SONG');
		if (requestedSong == null || requestedSong.trim().length == 0)
			return false;

		requestedSong = Paths.formatToSongPath(requestedSong.trim());

		var requestedMod:String = Sys.getEnv('NOVAFLARE_DIAGNOSTIC_MOD');
		if (requestedMod != null && requestedMod.trim().length > 0)
			Mods.currentModDirectory = requestedMod.trim();

		Difficulty.resetList();
		var difficulty:Int = 1;
		var requestedDifficulty:String = Sys.getEnv('NOVAFLARE_DIAGNOSTIC_DIFFICULTY');
		if (requestedDifficulty != null && requestedDifficulty.trim().length > 0)
		{
			var requestedDifficultyValue:String = requestedDifficulty.trim();
			var parsedDifficulty:Null<Int> = Std.parseInt(requestedDifficultyValue);
			if (parsedDifficulty != null)
				difficulty = parsedDifficulty;
			else
			{
				Difficulty.copyFrom([requestedDifficultyValue]);
				difficulty = 0;
			}
		}
		difficulty = Std.int(Math.max(0, Math.min(Difficulty.list.length - 1, difficulty)));

		var botplayValue:String = Sys.getEnv('NOVAFLARE_DIAGNOSTIC_BOTPLAY');
		var botplay:Bool = botplayValue == null
			|| !['0', 'false', 'off', 'no'].contains(botplayValue.trim().toLowerCase());

		try
		{
			PlayState.isStoryMode = false;
			PlayState.storyDifficulty = difficulty;
			PlayState.replayMode = false;
			PlayState.chartingMode = false;
			PlayState.changedDifficulty = false;
			PlayState.deathCounter = 0;
			PlayState.seenCutscene = true;
			PlayState.startOnTime = 0;
			ClientPrefs.data.gameplaySettings.set('practice', false);
			ClientPrefs.data.gameplaySettings.set('botplay', botplay);
			if (FlxG.sound.music == null)
				FlxG.sound.playMusic(Paths.music('none'), 0, true);

			var chartName:String = Highscore.formatSong(requestedSong, difficulty);
			PlayState.SONG = Song.loadFromJson(chartName, requestedSong);
			trace('diagnostic:gameplay prepared song=$requestedSong chart=$chartName '
				+ 'difficulty=$difficulty mod=${Mods.currentModDirectory} botplay=$botplay');

			LoadingState.prepareToSong();
			FlxTransitionableState.skipNextTransIn = true;
			FlxTransitionableState.skipNextTransOut = true;
			LoadingState.loadAndSwitchState(new PlayState());
			return true;
		}
		catch (error:Dynamic)
		{
			trace('diagnostic:gameplay error=$error stack=${haxe.CallStack.exceptionStack()}');
			throw error;
		}
	}
	#end
	
	function startCutscenesIn()
	{
		if (!ClientPrefs.data.skipTitleVideo)
			#if VIDEOS_ALLOWED
			startVideo('menuExtend/titleIntro');
			#else
			changeState();
			#end
		else
			changeState();
	}
	
	override function update(elapsed:Float)
	{
		if (FlxG.sound.music != null)
			Conductor.songPosition = FlxG.sound.music.time;
			
		var pressedEnter:Bool = FlxG.keys.justPressed.ENTER || controls.ACCEPT;
	
		#if ios
		for (touch in FlxG.touches.list)
		{
			if (touch.justPressed)
			{
				pressedEnter = true;
			}
		}
		#end
	
		#if android
		if (FlxG.android.justReleased.BACK)
			pressedEnter = true;
		#end
	
		var gamepad:FlxGamepad = FlxG.gamepads.lastActive;
	
		if (gamepad != null)
		{
			if (gamepad.justPressed.START)
				pressedEnter = true;
	
			#if switch
			if (gamepad.justPressed.B)
				pressedEnter = true;
			#end
		}
		
		if (pressedEnter)
		{
			changeState();
			return;
		}
	
		super.update(elapsed);
	}
	
	#if VIDEOS_ALLOWED
	var video:FlxVideoSprite;
	
	function startVideo(name:String)
	{
		skipVideo = new FlxText(0, FlxG.height - 26, 0, "Press " + #if android "Back on your Phone " #else "Enter " #end + "to skip", 18);
		skipVideo.setFormat(Assets.getFont("assets/fonts/montserrat.ttf").fontName, 18);
		skipVideo.alpha = 0;
		skipVideo.alignment = CENTER;
		skipVideo.screenCenter(X);
		skipVideo.scrollFactor.set();
		skipVideo.antialiasing = ClientPrefs.data.antialiasing;
	
		#if VIDEOS_ALLOWED
		var filepath:String = Paths.video(name);
		#if sys
		if (!FileSystem.exists(filepath))
		#else
		if (!OpenFlAssets.exists(filepath))
		#end
		{
			FlxG.log.warn('Couldnt find video file: ' + name);
			videoEnd();
			return;
		}
	
		video = new FlxVideoSprite(0, 0);
		video.antialiasing = true;
		if (!ClientPrefs.data.useFlixelCoords)
		{
			video.bitmap.x -= FlxG.game.x;
			video.bitmap.y -= FlxG.game.y;
		}
		video.bitmap.onFormatSetup.add(function():Void
		{
			if (video.bitmap != null && video.bitmap.bitmapData != null)
			{
				final scale:Float = Math.min(FlxG.width / video.bitmap.bitmapData.width, FlxG.height / video.bitmap.bitmapData.height);
	
				video.setGraphicSize(video.bitmap.bitmapData.width * scale, video.bitmap.bitmapData.height * scale);
				video.updateHitbox();
				video.screenCenter();
			}
		});
		video.bitmap.onEndReached.add(video.destroy);
		add(video);
		video.load(filepath);
		video.play();
	
		video.bitmap.onEndReached.add(function()
		{
			videoEnd();
		});
	
		showText();
		#else
		FlxG.log.warn('Platform not supported!');
		videoEnd();
		return;
		#end
	}
	
	function videoEnd()
	{
		if (skipVideo != null) skipVideo.visible = false;
		if (video != null) {
			video.stop();
			video.visible = false;
		}
		changeState();
		trace("end");
	}
	
	function showText()
	{
		add(skipVideo);
		FlxTween.tween(skipVideo, {alpha: 1}, 1, {ease: FlxEase.quadIn});
		FlxTween.tween(skipVideo, {alpha: 0}, 1, {ease: FlxEase.quadIn, startDelay: 4});
	}
	#end

	function changeState() {
		if (mustUpdate && !OutdatedState.leftState)
		{
			FlxTransitionableState.skipNextTransIn = true;
			FlxTransitionableState.skipNextTransOut = true;
			MusicBeatState.switchState(new OutdatedState());
		}
		else
		{
			FlxTransitionableState.skipNextTransIn = true;
			FlxTransitionableState.skipNextTransOut = true;
			MusicBeatState.switchState(new TitleState());
		}
	}
}
