package;

import general.backend.ClientPrefs;
import haxe.io.Path;
import haxe.ui.Toolkit;

import openfl.Lib;
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.display.StageScaleMode;
import openfl.events.KeyboardEvent;
import openfl.utils.Assets;

import lime.system.System as LimeSystem;
import lime.app.Application;


import flixel.graphics.FlxGraphic;
import flixel.FlxGame;
import flixel.FlxState;
import flixel.util.FlxSave;

import originfunkin.OriginFunkinErrorState;
import originfunkin.OriginFunkinIntroState;
import originfunkin.OriginFunkinMode;

#if CODENAME_ENGINE_COMPAT
import codenamechain.CodeNameIntroState;
import codenamechain.CodeNameMode;
#end

import developer.display.FPSViewer;
import developer.display.Graphics;
import developer.console.TraceInterceptor;
import developer.console.Console;
import developer.console.ConsoleToggleButton;

import general.objects.screen.MouseEffect;
import general.objects.ReplayOverlay;
#if mobile
import general.shaders.MobileShaderConverter;
#end

import states.titleState.TitleState;
import states.backend.initState.InitState;
import states.backend.passState.PassState;

#if android
import general.backend.device.AppData;
import states.backend.pirateState.PirateState;
#end

#if desktop
import general.backend.device.ALSoftConfig;
#end
#if hl
import hl.Api;
#end
#if linux
import lime.graphics.Image;

@:cppInclude('./general/backend/external/gamemode_client.h')
@:cppFileCode('
	#define GAMEMODE_AUTO
')
#end

class Main extends Sprite
{
	private static var gameConfig = {
		width: 1280, // WINDOW width
		height: 720, // WINDOW height
		initialState: InitState,
		zoom: -1.0, // game state bounds
		framerate: #if desktop 240 #else 60 #end, // responsive bootstrap; ClientPrefs takes over in InitState
		skipSplash: true, // if the default flixel splash screen should be skipped
		startFullscreen: false // if the game should start at fullscreen mode
	};

	public static var fpsVar:FPSViewer;
	public static var watermark:Watermark;
	private static var replayOverlay:ReplayOverlay;

	#if android
	private var mobileViewportGame:FlxGame;
	#end

	public static function getReplayOverlay():ReplayOverlay
	{
		return replayOverlay;
	}

	#if mobile
	public static final platform:String = "Phones";
	#else
	public static final platform:String = "PCs";
	#end

	// You can pretty much ignore everything from here on - your code should go in your states.

	public static function main():Void
	{
		#if (sys && FEATURE_DEBUG_FUNCTIONS && CODENAME_ENGINE_COMPAT)
		// Explicit test launches redirect FlxSave before any engine initializes.
		// The marker must exist beside the copied executable; the real runtime
		// has no marker and cannot accidentally use this isolated save folder.
		if (Sys.args().contains("--cne-isolated-storage"))
		{
			var testRoot = haxe.io.Path.directory(Sys.programPath());
			var marker = haxe.io.Path.join([testRoot, ".codex-cne-isolated-runtime"]);
			var saves = haxe.io.Path.join([testRoot, ".isolated-saves"]);
			if (!sys.FileSystem.exists(marker) || !sys.FileSystem.exists(saves) || !sys.FileSystem.isDirectory(saves))
				throw "CNE isolated storage requires a marked test runtime and pre-existing save directory.";
			// FlxSave normalizes three parent segments from the Lime storage path.
			// Keep those parents inside the isolated tree, including legacy saves.
			var storage = haxe.io.Path.join([saves, "level-a", "level-b", "level-c"]);
			if (!sys.FileSystem.exists(storage) || !sys.FileSystem.isDirectory(storage))
				throw "CNE isolated storage requires its pre-created nested storage directory.";
			@:privateAccess lime.system.System.__applicationStorageDirectory = sys.FileSystem.fullPath(storage);
			trace('[CNE isolated test] FlxSave storage redirected to ' + sys.FileSystem.fullPath(storage));
		}
		#end
		OriginFunkinMode.detect();
		#if CODENAME_ENGINE_COMPAT
		CodeNameMode.detect();
		#end

		#if (cpp && windows)
		if (!OriginFunkinMode.active)
		{
			general.backend.device.Native.fixScaling();
			general.backend.device.Native.setWindowDarkMode(true, true);
		}
		#end
		
		Lib.current.addChild(new Main());
		#if cpp

		GCManager.enable(true); 
		#end
	}
	
	public function new()
	{
		super();
		#if android
		SUtil.doPermissionsShit();
		setupMobileStorage();
		mobile.backend.CrashHandler.refreshNativeCrashDirectory();
		#end
		mobile.backend.CrashHandler.init();
		gameanalytics.GAAppLifecycle.install();

		if (stage != null)
		{
			init();
		}
		else
		{
			addEventListener(Event.ADDED_TO_STAGE, init);
		}
		#if VIDEOS_ALLOWED
		hxvlc.util.Handle.init(#if (hxvlc >= "1.8.0") ['--no-lua'] #end);
		#end
	}

	private function init(?E:Event):Void
	{
		if (hasEventListener(Event.ADDED_TO_STAGE))
		{
			removeEventListener(Event.ADDED_TO_STAGE, init);
		}

		setupGame();
		#if (mobile && FLX_MOUSE)
		mobile.input.VirtualPointerOverlay.install(Lib.current.stage);
		#end

		#if (cpp && windows)
		if (!OriginFunkinMode.active)
		{
			general.backend.device.Native.applyStartupDarkMode();
		}
		#end
	}

	private function setupGame():Void
	{
		var stageWidth:Int = Lib.current.stage.stageWidth;
		var stageHeight:Int = Lib.current.stage.stageHeight;

		if (gameConfig.zoom == -1.0)
		{
			var ratioX:Float = stageWidth / gameConfig.width;
			var ratioY:Float = stageHeight / gameConfig.height;
			gameConfig.zoom = Math.min(ratioX, ratioY);
			gameConfig.width = Math.ceil(stageWidth / gameConfig.zoom);
			gameConfig.height = Math.ceil(stageHeight / gameConfig.zoom);
		}

		#if mobile
		// Install the compiled defaults before FlxGame creates OpenFL's first GL
		// programs. ClientPrefs.loadPrefs() reapplies the saved values later.
		MobileShaderConverter.setEnabled(ClientPrefs.data.autoShaderConversion);
		MouseEffect.setUserEffectsEnabled(ClientPrefs.data.mouseTrailEffect);

		setupMobileStorage();
		mobile.backend.CrashHandler.refreshNativeCrashDirectory();

		OriginFunkinMode.detect();
		#if CODENAME_ENGINE_COMPAT
		// main() runs before Android selects the external runtime directory, so
		// detect Codename again after chain.json has been reloaded from that path.
		CodeNameMode.detect();
		#end
		#end

		#if CODENAME_ENGINE_COMPAT
		if (CodeNameMode.active)
		{
			setupCodeNameGame();
			return;
		}
		#end

		if (OriginFunkinMode.active)
		{
			setupOriginFunkinGame();
			return;
		}

		Toolkit.init();

		#if LUA_ALLOWED llua.Lua.set_callbacks_function(cpp.Callable.fromStaticFunction(scripts.lua.CallbackHandler.call)); #end
		Controls.instance = new Controls();

		#if android
			if (AppData.getVersionName() != Application.current.meta.get('version')
				|| AppData.getAppName() != Application.current.meta.get('file')                                                                                                                                                                                                                                                                                                                                                                                                                         || !AppData.verifySignature()
				|| (AppData.getPackageName() != Application.current.meta.get('packageName')
					&& AppData.getPackageName() != Application.current.meta.get('packageName') + 'Backup1' // 共存
					&& AppData.getPackageName() != Application.current.meta.get('packageName') + 'Backup2' // 共存
					&& AppData.getPackageName() != 'com.antutu.ABenchMark' // 超频测试 安兔
					&& AppData.getPackageName() != 'com.ludashi.benchmark' // 超频测试 鲁大
				)) {
					FlxG.switchState(new PirateState());
					return;
				}
		#end

		///////////////////////////////////////////   --包含有读取文件的别在这个的上面运

		ExtraKeysHandler.instance = new ExtraKeysHandler();
		ClientPrefs.loadDefaultKeys();

		var flxGame:FlxGame = new FlxGame(#if (openfl >= "9.2.0") 1280, 720 #else gameConfig.width, gameConfig.height #end,gameConfig.initialState, #if (flixel < "5.0.0") gameConfig.zoom, #end gameConfig.framerate, gameConfig.framerate, gameConfig.skipSplash, gameConfig.startFullscreen);
		addChild(flxGame);

		fpsVar = new FPSViewer(0, 0);
		FlxG.addChildBelowMouse(fpsVar);
		FlxG.spriteBelowMouse.push(fpsVar);
		
		Lib.current.stage.align = "tl";
		Lib.current.stage.scaleMode = StageScaleMode.NO_SCALE;

		#if FLX_DEBUG
		flixel.system.debug.log.LogStyle.ERROR.openConsole = false;
		flixel.system.debug.log.LogStyle.WARNING.openConsole = false;
		#end

		var image:String = Paths.modFolders('images/menuExtend/Others/watermark.png');

		if (FileSystem.exists(image))
		{
			if (watermark != null)
				removeChild(watermark);
			watermark = new Watermark(5, Lib.current.stage.stageHeight - 5, 0.4);
			addChild(watermark);
			watermark.y -= watermark.bitmapData.height;
		}
		if (watermark != null)
		{
			watermark.scaleX = watermark.scaleY = ClientPrefs.data.watermarkScale;
			watermark.y = Lib.current.stage.stageHeight - 5 - watermark.scaleY * watermark.bitmapData.height;
			watermark.visible = ClientPrefs.data.showWatermark;
		}

		var effect = new MouseEffect();
		effect.mouseEnabled = false;
		effect.mouseChildren = false;
		addChild(effect);

		replayOverlay = new ReplayOverlay();
		addChild(replayOverlay);

		#if linux
		var icon = Image.fromFile("icon.png");
		Lib.current.stage.window.setIcon(icon);
		#end

		#if DISCORD_ALLOWED
		DiscordClient.prepare();
		#end

		#if mobile
		LimeSystem.allowScreenTimeout = ClientPrefs.data.screensaver;
		#end
		Data.setup();

		TraceInterceptor.init();
		addChild(ConsoleToggleButton.instance);
		addChild(Console.consoleInstance);
		Console.consoleInstance.visible = false;
		setChildIndex(effect, numChildren - 1);

		#if !debug
			//cpp.NativeGc.enterGCFreeZone();
		#end
	}

	#if mobile
	private function setupMobileStorage():Void
	{
		#if android
		var defaultFolder:String = Application.current.meta.get('file');
		var storageFolder:String = defaultFolder;

		// Read saved storage folder preference from config file.
		var configFile:String = AndroidEnvironment.getExternalStorageDirectory() + '/.novaflare_storage_config';
		try
		{
			if (FileSystem.exists(configFile))
			{
				var savedFolder:String = sys.io.File.getContent(configFile).trim();
				if (savedFolder != null && savedFolder != '')
				{
					storageFolder = savedFolder;
				}
			}
		}
		catch (error:Dynamic)
		{
			trace('Failed to read storage config: $error');
		}
		#end

		var storageDirectory:String = SUtil.getStorageDirectory(
			#if android EXTERNAL, storageFolder #else EXTERNAL #end
		);
		SUtil.mkDirs(storageDirectory);
		Sys.setCwd(storageDirectory);
		// Origin's startup choice lives in the selected engine runtime folder,
		// so reload it only after the legacy mobile storage setup has set cwd.
		originfunkin.OriginFunkinConfig.load(true);
	}

	#end

	private function setupOriginFunkinGame():Void
	{
		fpsVar = new FPSViewer(0, 0);
		var effect = new MouseEffect(
			Assets.getBitmapData('assets/shared/images/menuExtend/Others/click.png').clone(),
			Assets.getBitmapData('assets/shared/images/menuExtend/Others/circle.png').clone(),
			Assets.getBitmapData('assets/shared/images/menuExtend/Others/star.png').clone());
		effect.mouseEnabled = false;
		effect.mouseChildren = false;
		var originWatermarkBitmap = Assets.getBitmapData('assets/shared/images/menuExtend/Others/watermark.png').clone();

		var prepared:Bool = OriginFunkinMode.prepare();
		#if mobile
		if (prepared)
			MouseEffect.setUserEffectsEnabled(funkin.save.Save.instance.novaSettings.mouseEffects);
		#end
		var initialState:Class<FlxState> = OriginFunkinIntroState;
		var framerate:Int = prepared && funkin.Preferences.unlockedFramerate ? 0 : (prepared ? funkin.Preferences.framerate : 60);
		var startFullscreen:Bool = prepared
			&& (Lib.current.stage.window.fullscreen || funkin.Preferences.autoFullscreen);

		FlxG.fixedTimestep = false;
		var flxGame:FlxGame = new FlxGame(1280, 720, initialState, framerate, framerate, true, startFullscreen);

		if (prepared)
		{
			@:privateAccess
			flxGame._customSoundTray = funkin.ui.options.FunkinSoundTray;
		}

		addChild(flxGame);
		FlxG.addChildBelowMouse(fpsVar);
		FlxG.spriteBelowMouse.push(fpsVar);

		if (watermark != null && watermark.parent == this) removeChild(watermark);
		watermark = new Watermark(5, Lib.current.stage.stageHeight - 5, 0.4, originWatermarkBitmap);
		addChild(watermark);
		watermark.scaleX = watermark.scaleY = ClientPrefs.data.watermarkScale;
		watermark.visible = ClientPrefs.data.showWatermark;
		watermark.y = Lib.current.stage.stageHeight - 5 - watermark.scaleY * watermark.bitmapData.height;

		addChild(effect);

		Lib.current.stage.align = "tl";
		Lib.current.stage.scaleMode = StageScaleMode.NO_SCALE;
		Lib.current.stage.window.title = OriginFunkinMode.getWindowTitle();

		if (prepared)
		{
			FlxG.scaleMode = new funkin.ui.FullScreenScaleMode();
		}
	}

	#if CODENAME_ENGINE_COMPAT
	private function setupCodeNameGame():Void
	{
		// Release builds use the CNE/NF crash message boxes instead of a
		// permanently attached stdout window.
		#if debug
		codename.funkin.backend.utils.NativeAPI.allocConsole();
		#end
		fpsVar = new FPSViewer(0, 0);
		fpsVar.visible = false;
		var effect = new MouseEffect(
			Assets.getBitmapData('assets/shared/images/menuExtend/Others/click.png').clone(),
			Assets.getBitmapData('assets/shared/images/menuExtend/Others/circle.png').clone(),
			Assets.getBitmapData('assets/shared/images/menuExtend/Others/star.png').clone());
		effect.mouseEnabled = false;
		effect.mouseChildren = false;
		var codeNameWatermarkBitmap = Assets.getBitmapData('assets/shared/images/menuExtend/Others/watermark.png').clone();

		CodeNameMode.prepare();
		var codeNameMain = new codename.funkin.backend.system.Main(false);
		var flxGame:codename.funkin.backend.system.FunkinGame = new codename.funkin.backend.system.FunkinGame(1280, 720, CodeNameIntroState, gameConfig.framerate,
			gameConfig.framerate, true, false);
		loadNovaFlareOverlayPrefs();
		flxGame.deferBitmapCacheClearOnStateSwitch = true;
		codename.funkin.backend.system.Main.game = flxGame;
		codenamechain.CodeNameScriptRuntime.init();

		codeNameMain.addChild(flxGame);
		#if android
		FlxG.android.preventDefaultKeys = [BACK];
		#end

		codename.funkin.backend.system.Conductor.changeBPM();
		codeNameMain.addChild(codename.funkin.backend.system.Main.framerateSprite = new codename.funkin.backend.system.framerate.Framerate());
		addChild(codeNameMain);
		#if mobile
		codename.funkin.backend.system.Main.framerateSprite.setScale();
		Lib.current.stage.window.onResize.add((width:Int, height:Int) -> codename.funkin.backend.system.Main.framerateSprite.setScale());
		#end
		codename.funkin.backend.system.framerate.SystemInfo.init();

		if (watermark != null && watermark.parent == this) removeChild(watermark);
		watermark = new Watermark(5, Lib.current.stage.stageHeight - 5, 0.4, codeNameWatermarkBitmap);
		addChild(watermark);
		watermark.scaleX = watermark.scaleY = ClientPrefs.data.watermarkScale;
		watermark.visible = ClientPrefs.data.showWatermark;
		watermark.y = Lib.current.stage.stageHeight - 5 - watermark.scaleY * watermark.bitmapData.height;
		addChild(effect);

		Lib.current.stage.align = "tl";
		Lib.current.stage.scaleMode = StageScaleMode.NO_SCALE;
	}

	private static function loadNovaFlareOverlayPrefs():Void
	{
		var overlaySave:FlxSave = new FlxSave();
		try
		{
			if (overlaySave.bind('funkin', CoolUtil.getSavePath()))
			{
				var savedVisibility:Dynamic = Reflect.field(overlaySave.data, 'showWatermark');
				if (Std.isOfType(savedVisibility, Bool))
					ClientPrefs.data.showWatermark = savedVisibility;

				var savedScale:Dynamic = Reflect.field(overlaySave.data, 'watermarkScale');
				if (savedScale != null)
				{
					var parsedScale:Float = Std.parseFloat(Std.string(savedScale));
					if (!Math.isNaN(parsedScale))
						ClientPrefs.data.watermarkScale = Math.max(0, Math.min(5, parsedScale));
				}
			}
		}
		catch (error:Dynamic)
		{
			trace('[CodeName] Could not read NovaFlare overlay preferences: $error');
		}
		overlaySave.destroy();
	}
	#end

	@:allow(states.backend.initState.InitState)
	static function resetSpriteCache(sprite:Sprite):Void
	{
		@:privateAccess {
			sprite.__cacheBitmap = null;
			sprite.__cacheBitmapData = null;
		}
	}

	@:allow(states.backend.initState.InitState)
	private static function initScriptModules() {
		#if (MODS_ALLOWED && HSCRIPT_ALLOWED)
		var paths:Array<String> = [];

		for (folder in Mods.directoriesWithFile(Paths.getSharedPath(), 'stageScripts/modules/'))
			if(FileSystem.exists(folder) && FileSystem.isDirectory(folder)) {
				final path = Path.addTrailingSlash(folder);
				paths.push(path + "$" + Mods.toDisplayPath(path));
			}

		trace("scriptClass Paths: " + paths);
		scripts.stages.modules.ScriptedModuleNotify.init([scripts.stages.modules.ScriptedModule], paths, scripts.stages.modules.ModuleHandler.includeExtension, [
			// Extended Class
			"ScriptedState" => scripts.scriptClasses.ScriptedState,
			"ScriptedBaseStage" => scripts.scriptClasses.ScriptedBaseStage,
			"ScriptedGroup" => scripts.scriptClasses.ScriptedGroup,
			"ScriptedSprite" => scripts.scriptClasses.ScriptedSprite,
			"ScriptedSpriteGroup" => scripts.scriptClasses.ScriptedSpriteGroup,
			"ScriptedSubstate" => scripts.scriptClasses.ScriptedSubstate,

			// Flixel Something
			"FlxG" => flixel.FlxG,
			"FlxSprite" => flixel.FlxSprite,
			"FlxGroup" => flixel.group.FlxGroup,
			"FlxSpriteGroup" => flixel.group.FlxSpriteGroup,
			"FlxText" => flixel.text.FlxText,

			"MusicBeatState" => general.backend.MusicBeatState,
			"PlayState" => games.PlayState,
			"Application" => lime.app.Application,

			// Engine Something
			'Conductor' => general.backend.Conductor,
			"Paths" => general.backend.Paths,
			'ClientPrefs' => general.backend.ClientPrefs,
			#if ACHIEVEMENTS_ALLOWED
			'Achievements' => general.backend.Achievements,
			#end
		]);
		#end
	}

	@:allow(states.backend.initState.InitState)
	static function toggleFullScreen(event:KeyboardEvent)
	{
		if (Controls.instance.justReleased('fullscreen'))
			FlxG.fullscreen = !FlxG.fullscreen;
	}
}

/*
                   _ooOoo_
                  o8888888o
                  88" . "88
                  (| -_- |)
                  O\  =  /O
               ____/`---'\____
             .'  \\|     |//  `.
            /  \\|||  :  |||//  \
           /  _||||| -:- |||||-  \
           |   | \\\  -  /// |   |
           | \_|  ''\---/''  |   |
           \  .-\__  `-`  ___/-. /
         ___`. .'  /--.--\  `. . __
      ."" '<  `.___\_<|>_/___.'  >'"".
     | | :  `- \`.;`\ _ /`;.`/ - ` : | |
     \  \ `-.   \_ __\ /__ _/   .-` /  /
======`-.____`-.___\_____/___.-`____.-'======
                   `=---='
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
            佛祖保佑       永无BUG
                镇压hxcpp-zgc
              500年内无人能看得懂

May the Buddha bless you with no bugs forever
             Suppress hxcpp-zgc
No one will be able to understand it in 500 years
*/

