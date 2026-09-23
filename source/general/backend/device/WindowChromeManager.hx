package general.backend.device;

import flixel.FlxG;
import flixel.FlxState;
import lime.app.Application;

import general.objects.WindowBarMode;
import general.objects.WindowControlBar;

import developer.editors.CharacterEditorState;
import developer.editors.ChartingState;
import developer.editors.DialogueCharacterEditorState;
import developer.editors.DialogueEditorState;
import developer.editors.NoteSplashEditorState;
import developer.editors.StageEditorState;
import states.modsMenuState.ModsMenuState;

/**
 * 沉浸式窗口 chrome 管理（全自绘、全界面统一方案）：
 *
 * - 除 `keepChromeScreens` 明确列出的界面外，**所有界面**都隐藏系统标题栏：
 *   窗口外框与位置不变，客户端向上扩一条；项目原生 `FullScreenScaleMode`
 *   负责全屏缩放逻辑，画面满幅铺满（原标题栏区域显示游戏内容，无黑边）。
 * - 除编辑器外，每个界面都会自动挂载一条 AUTO_HIDE 自绘窗口控制条
 *   （`WindowControlBar`）：平时不可见，鼠标靠近窗口顶部时平滑滑入
 *   （含 - □ × 与拖拽区），移开后自动滑出。
 * - 编辑器（Chart/Character/Stage）不挂 AUTO_HIDE 条，由各编辑器自行添加
 *   常驻的 `EditorChromeUI`（WindowControlBar 的 CONSTANT 模式，融入菜单栏）。
 * - 时机：chrome / 视口切换在 flixel `preStateCreate`（状态 create 之前，
 *   保证 UI 用扩展后的逻辑尺寸布局）；AUTO_HIDE 条在 `postStateSwitch`
 *   （create 完成之后，保证渲染在最顶层）。
 */
class WindowChromeManager
{
	/** 少数希望保留系统标题栏的界面（默认无）。可自由增删。 */
	public static var keepChromeScreens:Array<Class<Dynamic>> = [];

	/** 不自动挂载 AUTO_HIDE 条的界面（它们自带 CONSTANT 窗口条） */
	public static var editorScreens:Array<Class<Dynamic>> = [
		ChartingState, CharacterEditorState, StageEditorState,
		DialogueEditorState, DialogueCharacterEditorState, NoteSplashEditorState,
		// ★ Mods 菜单（新界面）也自建 CONSTANT 条：它要在条上挂 9 个工具按钮 +
		//   搜索框 + 打开文件夹/退出，需要拿到 bar 的引用（titleAnchorX()），
		//   所以从 constantBarScreens 移到这里，由 ModsMenuState 自己 new。
		ModsMenuState
	];

	/**
	 * ★ 使用**常驻**（CONSTANT）窗口条的界面：窗口条始终显示、可交互，
	 * 全屏下也不受"仅开发工具/Mods 可用"的限制。
	 *
	 * 默认（不在列表里的界面）挂 AUTO_HIDE 条：平时隐藏、鼠标贴顶唤出；
	 * **全屏时完全禁用**（唤不出、点不到），退出全屏用 F11。
	 */
	public static var constantBarScreens:Array<Class<Dynamic>> = [];

	/** 当前状态是否属于沉浸界面 */
	public static var immersive:Bool = false;
	/** 系统标题栏当前是否显示（沉浸界面里恒为 false） */
	public static var chromeVisible:Bool = true;

	static var inited:Bool = false;
	static var lastState:FlxState = null;
	static var lastBarHeight:Int = 0;

	static var lastWindowMode:Int = -1;
	static var barRefreshPending:Float = -1;

	// ★ 曾尝试 Windows 禁用 lime 多线程渲染(RenderThread),经控制变量测试
	//   (WCM 全禁用 → F11 正常)确认:多线程渲染本身是稳定的,反而是禁用它
	//   (切单线程)会破坏全屏切换后的呈现。不再干预渲染线程,保持默认。

	// ★ 控制变量测试结论(2026-09-05):
	//   主动 remeasure(FlxG.resizeGame)在全屏切换后二次重排会破坏呈现
	//   (SDL 正规 fullscreen 的事件链本身完整,无需兜底重排)。
	//   因此:窗口尺寸变化完全交给 SDL→stage→flixel 事件链,
	//   WCM 只负责标题栏显示/隐藏与自绘条的挂载/刷新,不再主动调 resizeGame。

	static function tickChrome():Void
	{
		#if (cpp && windows)
		// chromeCam 视口恒对齐当前逻辑尺寸（窗口条/按钮基于 FlxG.width 布局，
		// 相机视口若不一致会出现条与按钮“分离”）
		if (chromeCam != null && FlxG.cameras != null && FlxG.cameras.list != null
			&& FlxG.cameras.list.contains(chromeCam)
			&& (chromeCam.width != FlxG.width || chromeCam.height != FlxG.height))
		{
			chromeCam.width = FlxG.width;
			chromeCam.height = FlxG.height;
		}

		// 窗口模式切换（普通/最大化/全屏）：等 resize 链稳定后强制重建窗口条
		var wm:Int = Native.windowMode();
		if (wm != lastWindowMode)
		{
			lastWindowMode = wm;
			barRefreshPending = 0.4;
		}
		if (barRefreshPending >= 0)
		{
			barRefreshPending -= FlxG.elapsed;
			if (barRefreshPending < 0)
			{
				barRefreshPending = -1;
				general.objects.WindowControlBar.refreshAllBars();
			}
		}
		#end
	}

	/** 顶层 chrome 相机：永远加在 FlxG.cameras.list 末尾（最后绘制），
	 *  自绘窗口条挂它，保证不被任何状态的 UI / 分层相机（如 Freeplay 的
	 *  camSongs/camAfter）盖住。编辑器会 reset 相机列表，所以每次取用时
	 *  都要确认它还在列表里。 */
	static var chromeCam:flixel.FlxCamera = null;

	static function getChromeCam():flixel.FlxCamera
	{
		#if (cpp && windows)
		if (chromeCam == null || FlxG.cameras == null || FlxG.cameras.list == null
			|| !FlxG.cameras.list.contains(chromeCam))
		{
			chromeCam = new flixel.FlxCamera();
			chromeCam.bgColor.alpha = 0;
			FlxG.cameras.add(chromeCam, false);
			// 对齐当前逻辑分辨率（编辑器 reset 后重建时也要同步）
			if (FlxG.width > 0 && FlxG.height > 0)
			{
				chromeCam.width = FlxG.width;
				chromeCam.height = FlxG.height;
			}
		}
		return chromeCam;
		#else
		return null;
		#end
	}

	/**
	 * 每次 MusicBeatState.create 时调用：惰性初始化 + 首个状态兜底
	 * （InitState 的 preStateCreate 发生在注册之前）。
	 */
	public static function onStateChanged(state:FlxState):Void
	{
		#if (cpp && windows)
		ensureInit();
		lastState = state;
		applyChromeForState(state);
		#end
	}

	/**
	 * flixel 在状态 create() 之前（旧状态已销毁）触发：在这里切换系统标题栏
	 * 与视口，使新状态的 UI 从一开始就按正确的逻辑尺寸布局。
	 */
	static function onPreStateCreate(state:FlxState):Void
	{
		#if (cpp && windows)
		lastState = state;
		applyChromeForState(state);
		#end
	}

	/** 状态 create 完成后触发：挂载/更新该界面的自绘窗口条。 */
	static function onPostStateSwitch():Void
	{
		#if (cpp && windows)
		if (FlxG.state == null)
			return;
		var state:FlxState = FlxG.state;

		if (isStateIn(state, editorScreens))
			return; // 编辑器自带 CONSTANT 窗口条

		// 上一个状态的条已随旧状态销毁，这里总是挂新的。
		// Mods 等 constantBarScreens 界面用常驻条（全屏下也可用）；
		// 其余界面 AUTO_HIDE（平时隐藏，全屏时完全禁用）。
		var barMode:WindowBarMode = isStateIn(state, constantBarScreens) ? WindowBarMode.CONSTANT : WindowBarMode.AUTO_HIDE;
		var bar:WindowControlBar = new WindowControlBar(barMode);
		bar.scrollFactor.set();

		// 统一挂到顶层 chrome 相机（FlxG.cameras 列表末尾，最后绘制）。
		// 不能用 state.camHUD / FlxG.camera：部分界面（如 Freeplay）用显式
		// 分层相机（camSongs/camAfter 等），默认相机的内容会被它们盖住。
		bar.cameras = [getChromeCam()];

		state.add(bar);
		// 置顶渲染（放到 members 末尾，避免被状态 UI 遮挡）
		if (state.members != null && state.members.remove(bar))
			state.members.push(bar);
		#end
	}

	/**
	 * 全屏状态变化 / 窗口 resize 后由事件调用：把系统栏与视口重新校准到
	 * 当前期望状态（SDL 在全屏切换时会自己恢复标题栏样式）。
	 */
	public static function reassert():Void
	{
		#if (cpp && windows)
		if (lastState == null)
			return;
		applyChromeForState(lastState);
		#end
	}

	static function applyChromeForState(state:FlxState):Void
	{
		#if (cpp && windows)
		immersive = !isStateIn(state, keepChromeScreens);

		// 非沉浸界面：系统标题栏常显
		if (!immersive)
		{
			setSystemChrome(true);
			return;
		}

		// 沉浸界面：隐藏系统栏（由自绘条接管窗口控制）。
		// 全屏/最大化已是自管模式（SetWindowPos 铺满），窗口样式始终是
		// 普通沉浸窗口，无需按 FlxG.fullscreen 分支处理。
		setSystemChrome(false);
		#end
	}

	/** 切换系统标题栏显示状态（隐藏时扩展视口，显示时恢复 1280x720）。 */
	public static function setSystemChrome(show:Bool):Void
	{
		#if (cpp && windows)
		if (show == chromeVisible)
		{
			// 状态没变，但系统栏可能被 SDL 改过（如退出全屏），强制校准一次
			if (!show)
				Native.setWindowChromeVisible(false);
			// 即使 chrome 状态未变，窗口大小可能已改变（如全屏切换），
			// 强制重排一次确保视口与窗口客户区一致，避免裁切/偏移。
			remeasure();
			return;
		}
		chromeVisible = show;

		// 1. 系统标题栏（外框不变，客户端伸缩）
		Native.setWindowChromeVisible(show);
		lastBarHeight = Native.titleBarHeightPx();

		// 1b. 隐藏标题栏后，客户区会扩成 SDL 初始的"外框"（1280x720 的
		//     请求会变成 1296x759 的窗口）。把客户区重置为 fixScaling 的
		//     目标尺寸，并重新记录"默认窗口矩形"（供恢复默认按钮使用）。
		if (!show && Native.defaultClientW > 0 && Native.defaultClientH > 0)
		{
			Native.windowSetClientSize(Native.defaultClientW, Native.defaultClientH);
			Native.captureDefaultWindowRect();
		}

		// 2. 视口：FullScreenScaleMode 负责全屏缩放逻辑（adjustGameSize 扩展
		//    逻辑尺寸、cutout 处理等），WindowChromeManager 只需触发 remeasure。
		remeasure();
		#end
	}

	// ________________________________________________________________________

	/**
	 * 视口重排请求。
	 *
	 * 控制变量测试结论：窗口尺寸变化（含全屏切换）完全由
	 * SDL → stage resize → flixel 事件链驱动（FlxGame.onResize →
	 * resizeGame → scaleMode/cameras/gameResized），链是完整的。
	 * 若这里再主动调 FlxG.resizeGame，会在全屏切换后二次重排并破坏
	 * 呈现（画面停回旧尺寸/拉伸）。因此本函数不再做任何事，仅保留
	 * 调用点以便将来需要时恢复。
	 */
	static function remeasure():Void
	{
		#if (cpp && windows)
		// 不做任何主动重排(见上方注释)。
		#end
	}

	static function ensureInit():Void
	{
		#if (cpp && windows)
		if (inited)
			return;
		inited = true;

		// 不替换 FlxG.scaleMode：项目原生 FullScreenScaleMode 负责全屏缩放逻辑
		// （mustAwait 机制、adjustGameSize 逻辑尺寸扩展、cutout 处理等）。
		// WindowChromeManager 只负责窗口 chrome 显示/隐藏和视口同步对账。

		// 窗口事件：全屏/样式切换后重新校准标题栏状态
		// （SDL 全屏切换会自己改窗口样式，退出后需要按当前状态重新隐藏/显示）
		var win = (Application.current != null) ? Application.current.window : null;
		if (win != null)
		{
			win.onResize.add(function(w:Int, h:Int)
			{
				reassert();
			});
			win.onFullscreen.add(function() reassert());
		}

		// 状态 create 之前：先切好系统栏与视口，让状态 UI 用正确的逻辑尺寸布局
		FlxG.signals.preStateCreate.add(function(s:FlxState) onPreStateCreate(s));

		// 状态 create 完成后：挂载自绘窗口条
		FlxG.signals.postStateSwitch.add(function() onPostStateSwitch());

		// 每帧：chrome 相机对齐 + 窗口模式变化时刷新自绘条
		FlxG.signals.postUpdate.add(function() tickChrome());
		#end
	}

	/**
	 * 强制按当前真实客户区重排视口。
	 *
	 * 最大化/还原动画会在一两百毫秒内连续 SetWindowPos（resize 事件风暴），
	 * 最后一步的 SDL resize 事件可能被吞掉，导致 flixel 视口停在动画前的旧
	 * 尺寸 —— 表现就是窗口已 1920x1080 但画面只显示/拉伸 800x600 区域。
	 * 动画结束（与全屏退出）后调用本函数兜底一次。
	 */
	public static function syncViewportToWindow():Void
	{
		#if (cpp && windows)
		remeasure();
		#end
	}

	static function isStateIn(state:FlxState, list:Array<Class<Dynamic>>):Bool
	{
		for (clazz in list)
		{
			if (clazz != null && Std.isOfType(state, clazz))
				return true;
		}
		return false;
	}
}
