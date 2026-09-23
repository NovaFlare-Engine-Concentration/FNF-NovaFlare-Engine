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

	/**
	 * 【实验开关】是否"以屏幕原生分辨率创建舞台"。
	 *
	 * 背景（已在 openfl 9.5.1 源码中确认）：
	 *   `Stage.__setLogicalSize()` 只在窗口创建时被调用一次
	 *   （openfl/display/Window.hx:65 -> attributes.width/height），
	 *   之后 `Stage.__resize()` 走的是 `stageWidth = __logicalWidth` 分支。
	 *   也就是说窗口即使被铺满到 1920x1080，舞台逻辑尺寸仍然焊死在创建时的
	 *   1280x720，OpenFL 只能用 displayMatrix 把整幅画面放大 1.5 倍输出
	 *   —— 这正是"以 1280 渲染再放大"的确切来源。
	 *
	 * 打开 NOVAF_RES=native 后，舞台逻辑尺寸在启动时就被设成屏幕分辨率，
	 * 全屏时 displayMatrix 即为 1:1，不再有任何放大。
	 *
	 * 两种模式用同一个 exe、只靠环境变量切换，便于同机对照。
	 */
	public static function nativeResRequested():Bool
	{
		#if nativeres
		return true;
		#end
		#if sys
		try
		{
			final v:String = Sys.getEnv('NOVAF_RES');
			return v == 'native' || v == '2k';
		}
		catch (e:Dynamic) {}
		#end
		return false;
	}

	/**
	 * 实验模式的"设计/渲染分辨率"。
	 *
	 * NOVAF_RES=native → 用屏幕原生分辨率（1920x1080 上即 1:1，无任何缩放）
	 * NOVAF_RES=2k     → 用 2560x1440 渲染，屏幕 1920 时净效果是 0.75 倍缩小
	 *                    （真正的超采样：几何边缘在 2560 下光栅化后降采样到 1920）
	 *
	 * 注意：设计分辨率一旦提高，代码里所有"绝对尺寸"（字号、makeGraphic 尺寸、
	 * 硬编码的 1280/720）不会自动跟着放大，画面会等比缩小到
	 * 设计分辨率/屏幕分辨率。要让视觉大小保持不变，这些绝对尺寸必须同倍放大。
	 * 使用 `FlxG.width` 之类的相对布局则会自动适配。
	 */
	public static function nativeResSize():Null<{w:Int, h:Int}>
	{
		if (!nativeResRequested()) return null;
		#if sys
		try
		{
			final mode:String = Sys.getEnv('NOVAF_RES');
			if (mode == '2k') return {w: 2560, h: 1440};

			final disp = LimeSystem.getDisplay(0);
			if (disp != null)
				return {w: Std.int(disp.bounds.width), h: Std.int(disp.bounds.height)};
		}
		catch (e:Dynamic) {}
		#end
		return null;
	}

	/** applyNativeLogicalSize() 的执行结果（诊断用）。 */
	public static var nativeResApplyLog:String = 'not-called';

	/** 启动时把舞台逻辑尺寸设为实验分辨率。 */
	public static function applyNativeLogicalSize():Void
	{
		#if sys
		try
		{
			final size = nativeResSize();
			if (size == null)
			{
				nativeResApplyLog = 'size-null';
				return;
			}
			if (Lib.current == null || Lib.current.stage == null)
			{
				nativeResApplyLog = 'stage-null';
				return;
			}
			final w:Int = size.w;
			final h:Int = size.h;
			final st = Lib.current.stage;
			@:privateAccess st.__setLogicalSize(w, h);

			var lw:Int = 0, lh:Int = 0;
			@:privateAccess {
				lw = st.__logicalWidth;
				lh = st.__logicalHeight;
			}
			nativeResApplyLog = 'ok want=' + w + 'x' + h + ' logical=' + lw + 'x' + lh + ' stage=' + st.stageWidth + 'x' + st.stageHeight;
		}
		catch (e:Dynamic)
		{
			nativeResApplyLog = 'EXC ' + Std.string(e);
		}
		#end
	}

	/** 实验模式下游戏逻辑分辨率（见 nativeResSize 的说明）；否则返回 null。 */

	#if mobile
	public static final platform:String = "Phones";
	#else
	public static final platform:String = "PCs";
	#end

	// You can pretty much ignore everything from here on - your code should go in your states.

	public static function main():Void
	{
		// ★ 中文 / 非 ASCII 路径兼容自检：只有设了 NOVAF_PATHTEST=1 才跑，
		//   结果写到工作目录的 nova_pathtest.txt。放在最早期执行，早于 lime/openfl，
		//   这样测到的就是「文件系统 + LuaJIT + 进程代码页」的裸行为。
		general.backend.NovaPathTest.runIfRequested();

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

		// 【实验】"以屏幕原生分辨率创建"模式。
		// 必须在 FlxGame 构造之前：FlxG.init() 会立刻用 stage 尺寸计算 scaleMode。
		var gameW:Int = 1280;
		var gameH:Int = 720;
		#if (openfl < "9.2.0")
		gameW = gameConfig.width;
		gameH = gameConfig.height;
		#end

		final nativeRes = nativeResSize();
		if (nativeRes != null)
		{
			applyNativeLogicalSize();
			gameW = nativeRes.w;
			gameH = nativeRes.h;
		}

		var flxGame:FlxGame = new FlxGame(gameW, gameH, gameConfig.initialState, #if (flixel < "5.0.0") gameConfig.zoom, #end gameConfig.framerate, gameConfig.framerate, gameConfig.skipSplash, gameConfig.startFullscreen);
		addChild(flxGame);

		fpsVar = new FPSViewer(0, 0);
		FlxG.addChildBelowMouse(fpsVar);
		FlxG.spriteBelowMouse.push(fpsVar);
		
		Lib.current.stage.align = "tl";
		// 默认 NO_SCALE：舞台尺寸跟随窗口，由窗口 resize 事件驱动。
		// 【实验】nativeRes 模式改用 SHOW_ALL：此时 Stage.__resize() 走
		// `stageWidth = __logicalWidth` 分支，而我们已把 __logicalWidth 设成
		// 屏幕分辨率，displayMatrix 恒为 1:1，画面不再被任何缩放或拉伸。
		Lib.current.stage.scaleMode = nativeResRequested() ? StageScaleMode.SHOW_ALL : StageScaleMode.NO_SCALE;

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
		var flxGame:codename.funkin.backend.system.FunkinGame = new codename.funkin.backend.system.FunkinGame(1280, 720, CodeNameIntroState, gameConfig.framerate,
			gameConfig.framerate, true, false);
		loadNovaFlareOverlayPrefs();
		flxGame.deferBitmapCacheClearOnStateSwitch = true;
		codename.funkin.backend.system.Main.game = flxGame;
		codenamechain.CodeNameScriptRuntime.init();

		addChild(flxGame);
		#if android
		// The Codename chain bypasses NF's InitState, so install the Android
		// BACK-key policy here before any Codename menu starts handling it.
		FlxG.android.preventDefaultKeys = [BACK];
		#end
		// CNE normally boots straight into MainState, which initializes Conductor
		// before the first Framerate update. NF's CNE intro delays MainState, so
		// seed the default BPM map before ConductorInfo reads Conductor.bpm.
		// Main.loadGameSettings() will still run Conductor.init() and reset it.
		codename.funkin.backend.system.Conductor.changeBPM();
		addChild(codename.funkin.backend.system.Main.framerateSprite = new codename.funkin.backend.system.framerate.Framerate());
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
		Lib.current.stage.window.title = "NovaFlare Engine";
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
		{
			// 自管窗口模式：全屏 = SetWindowPos 铺满显示器（不切 SDL 全屏）
			#if (cpp && windows)
			var m:Int = general.backend.device.Native.windowMode();
			general.backend.device.Native.windowApplyMode(m == 2 ? 0 : 2);
			#end
		}
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

