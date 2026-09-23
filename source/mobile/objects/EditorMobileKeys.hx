package mobile.objects;

import haxe.io.Path;
import flixel.FlxG;
import general.backend.ClientPrefs;
import general.backend.MusicBeatState;
import mobile.server.EditorKeyServer;

/**
 * “调整移动端各Editor键位”功能的总管理（静态）。
 *
 * 开启（维护设置里的 adjustMobileEditorKeys）后：
 *  - 所有 Editor 的默认虚拟按键被暂时隐藏（隐藏其可视与输入，保留对象避免 NPE）；
 *  - 同时把 Controls.mobileC 视为 false，让 Editor 内部走键盘分支 ——
 *    这样自定义按键注入的 FlxG.keys（组合键）能驱动 Editor 的全部操作；
 *  - 在每个 Editor 里挂一个 EditorMobileKeyOverlay：从
 *    FuckYouNFEMobile/<EditorId>NewFuckingButtonMobile.json 读取自定义按键，
 *    按 x/y/color/click（可组合键）渲染，支持父键 CanSwitch/SwitchNum 切换子键输出；
 *  - 内置本地 HTTP 服务（127.0.0.1:1146）供外部浏览器窗口创建/删除/保存按键，
 *    保存后 Editor 内约 1 秒自动热重载。
 *
 * 目录规则：
 *  - Windows/桌面：运行目录（cwd）下的 FuckYouNFEMobile/
 *  - 移动端：存储根目录（即 .NovaFlare Engine1.2.0 这类点文件夹，Sys.setCwd 后即为 cwd）
 *    下的 FuckYouNFEMobile/
 */
class EditorMobileKeys
{
	public static inline final FOLDER_NAME:String = 'FuckYouNFEMobile';

	/** 外部窗口默认打开的 Editor（最近一次进入的 Editor） */
	public static var lastEditorId(default, null):String = 'ChartEditor';

	static var activeEditorState:MusicBeatState = null;
	static var activeEditorId:String = null;
	static var enabledOnceShown:Bool = false; // 本次启用里是否已弹过浏览器
	static var lastServerTry:Float = -99; // ensureServerRunning 的重试节流

	// “从默认键位生成”模板：FlxVirtualPad 涉及渲染资源，必须在主线程预生成后缓存，
	// HTTP 服务线程只读缓存。
	static var templateCache:Map<String, String> = new Map();

	public static function prepareTemplates():Void
	{
		templateCache = new Map();
		for (entry in EditorMobileKeyData.EDITORS)
		{
			try
			{
				templateCache.set(entry.id, EditorMobileKeyData.buildTemplateJson(entry.id));
			}
			catch (e:Dynamic)
			{
				trace('[EditorMobileKeys] template failed for ${entry.id}: $e');
			}
		}
	}

	public static function getTemplateJson(editorId:String):Null<String>
	{
		return templateCache.get(editorId);
	}

	public static function isEnabled():Bool
	{
		return ClientPrefs.data.adjustMobileEditorKeys == true;
	}

	// ==================== 目录 / 文件 ====================

	/** FuckYouNFEMobile 文件夹（自动补尾斜杠，统一 '/'） */
	public static function getFileDir():String
	{
		var base:String = Sys.getCwd();
		base = base.split('\\').join('/');
		if (!StringTools.endsWith(base, '/'))
			base += '/';
		return base + FOLDER_NAME + '/';
	}

	public static function ensureFolder():Bool
	{
		var dir:String = getFileDir();
		try
		{
			if (!FileSystem.exists(dir))
				FileSystem.createDirectory(dir);
			return FileSystem.exists(dir);
		}
		catch (e:Dynamic)
		{
			trace('[EditorMobileKeys] cannot create folder: $dir ($e)');
			return false;
		}
	}

	public static function getFilePath(editorId:String):String
	{
		return getFileDir() + EditorMobileKeyData.fileNameOf(editorId);
	}

	public static function fileExists(editorId:String):Bool
	{
		return FileSystem.exists(getFilePath(editorId));
	}

	public static function readFile(editorId:String):Null<String>
	{
		var path:String = getFilePath(editorId);
		try
		{
			if (FileSystem.exists(path))
				return sys.io.File.getContent(path);
		}
		catch (e:Dynamic)
		{
			trace('[EditorMobileKeys] read failed $path: $e');
		}
		return null;
	}

	/**
	 * 读取键位配置，带内置回退：
	 *  1) 存储目录里用户保存的文件；
	 *  2) APK 内置配置（EditorMobileKeyDefaults，Windows 上配好随包发布的 4 个 Editor）；
	 *  3) 默认模板键位（buildTemplateJson，与原 FlxVirtualPad 布局等价的按钮）。
	 * 保证任何 Editor 在开关开启时都有一组可用键位（“装上就有 / 其余 Editor 默认”）。
	 */
	public static function readFileWithFallback(editorId:String):Null<String>
	{
		var text:Null<String> = readFile(editorId);
		if (text != null && text.length > 0) return text;

		var builtin:Null<String> = null;
		#if mobile
		builtin = EditorMobileKeyDefaults.get(editorId);
		#end
		if (builtin != null && builtin.length > 0) return builtin;

		var tpl:Null<String> = getTemplateJson(editorId);
		if (tpl != null && tpl.length > 0) return tpl;

		// 模板缓存未就绪时现场构建（主线程，与 prepareTemplates 相同路径）
		try
		{
			tpl = EditorMobileKeyData.buildTemplateJson(editorId);
		}
		catch (e:Dynamic)
		{
			trace('[EditorMobileKeys] fallback template failed for $editorId: $e');
		}
		return tpl;
	}

	/** 写入文件，返回是否成功 */
	public static function writeFile(editorId:String, content:String):Bool
	{
		if (!ensureFolder()) return false;
		var path:String = getFilePath(editorId);
		try
		{
			sys.io.File.saveContent(path, content);
			trace('[EditorMobileKeys] saved $path');
			return true;
		}
		catch (e:Dynamic)
		{
			trace('[EditorMobileKeys] write failed $path: $e');
			return false;
		}
	}

	// ==================== 开关 ====================

	/** 维护设置里的开关回调（openBrowser=false 供 -emk 调试/自动化验证用） */
	public static function setEnabled(value:Bool, ?openBrowser:Bool = true):Void
	{
		if (ClientPrefs.data.adjustMobileEditorKeys == value)
		{
			// 状态未变化（例如存档里已经是开启、或重复点击）：
			// 仍要保证服务在跑；只在“刚打开”时弹一次浏览器。
			if (value)
			{
				ensureServerRunning();
				if (openBrowser && !enabledOnceShown) tryOpenWindow();
			}
			return;
		}
		ClientPrefs.data.adjustMobileEditorKeys = value;
		try
		{
			ClientPrefs.saveSettings();
		}
		catch (e:Dynamic) {}

		if (value)
		{
			ensureServerRunning();
			if (openBrowser) tryOpenWindow();
			else enabledOnceShown = true; // 调试模式不弹浏览器
		}
		else
		{
			enabledOnceShown = false;
			EditorKeyServer.stopServer();
		}
	}

	/** 功能开着但没有服务时补启动（游戏重启后开关存档为开的情况也会自动恢复） */
	public static function ensureServerRunning():Void
	{
		if (!ClientPrefs.data.adjustMobileEditorKeys) return;
		if (EditorKeyServer.isRunning()) return;
		var now:Float = haxe.Timer.stamp();
		if (now - lastServerTry < 3) return; // 启动失败时避免每帧重试
		lastServerTry = now;
		ensureFolder();
		prepareTemplates();
		EditorKeyServer.startServer();
	}

	static function tryOpenWindow():Void
	{
		if (enabledOnceShown) return;
		enabledOnceShown = true;
		var port:Int = EditorKeyServer.getPort();
		if (port > 0)
		{
			FlxG.openURL('http://127.0.0.1:$port/');
			trace('[EditorMobileKeys] external key editor window: http://127.0.0.1:$port/');
		}
	}

	// ==================== 状态挂接 ====================

	/** MusicBeatState.addVirtualPad 之后调用 */
	public static function onVirtualPadAdded(state:MusicBeatState):Void
	{
		if (!isEnabled()) return;
		var id:String = editorIdOf(state);
		if (id == null) return;
		lastEditorId = id;
		customizeState(state, id);
	}

	/** MusicBeatState.update 每帧调用 */
	public static function frameUpdate(state:MusicBeatState):Void
	{
		if (!isEnabled())
		{
			if (activeEditorState != null)
			{
				restoreState(activeEditorState);
				activeEditorState = null;
				activeEditorId = null;
			}
			return;
		}

		// 存档里开关为开但服务没在跑（重启/启动参数场景）时自动恢复服务
		ensureServerRunning();

		var id:String = editorIdOf(state);
		if (id == null)
		{
			if (activeEditorState != null && activeEditorState != state)
			{
				restoreState(activeEditorState);
			}
			activeEditorState = null;
			activeEditorId = null;
			return;
		}

		lastEditorId = id;
		if (activeEditorState != state || activeEditorId != id)
		{
			if (activeEditorState != null && activeEditorState != state)
				restoreState(activeEditorState);
			activeEditorState = state;
			activeEditorId = id;
		}

		// ★ 编辑器打开子状态（ESC 试玩 / 确认弹窗等）时挂起自定义按键：
		//   隐藏 overlay + 释放注入键，避免编辑器按键混进试玩界面、
		//   或按住中的 Ctrl/Shift 组合键残留导致后续网格点击被“消除”
		if (state.subState != null)
		{
			var overlay:EditorMobileKeyOverlay = state.editorMobileOverlay;
			if (overlay != null)
				overlay.suspend();
			return;
		}
		customizeState(state, id);
	}

	/** 把一个 Editor 状态切到“自定义键位”形态：隐藏默认 pad、确保 overlay 存在 */
	static function customizeState(state:MusicBeatState, editorId:String):Void
	{
		var pad:Dynamic = state.virtualPad;
		if (pad != null)
		{
			try
			{
				pad.visible = false;
				pad.active = false;
			}
			catch (e:Dynamic) {}
		}

		var overlay:EditorMobileKeyOverlay = state.editorMobileOverlay;
		if (overlay != null && overlay.editorId != editorId)
		{
			removeOverlay(state);
			overlay = null;
		}
		if (overlay == null)
		{
			overlay = new EditorMobileKeyOverlay(editorId);
			state.editorMobileOverlay = overlay;
			try
			{
				state.add(overlay);
			}
			catch (e:Dynamic)
			{
				trace('[EditorMobileKeys] add overlay failed: $e');
			}
		}
		overlay.refreshVisibility();
	}

	static function removeOverlay(state:MusicBeatState):Void
	{
		var overlay:EditorMobileKeyOverlay = state.editorMobileOverlay;
		state.editorMobileOverlay = null;
		if (overlay == null) return;
		try
		{
			if (state.exists)
				state.remove(overlay);
		}
		catch (e:Dynamic) {}
		try
		{
			overlay.destroy();
		}
		catch (e:Dynamic) {}
	}

	/** 恢复默认虚拟按键（关闭功能 / 离开 Editor 时） */
	static function restoreState(state:MusicBeatState):Void
	{
		try
		{
			removeOverlay(state);
			var pad:Dynamic = state.virtualPad;
			if (pad != null && state.exists)
			{
				var show:Bool = true;
				#if desktop
				show = ClientPrefs.data.needMobileControl;
				#end
				pad.visible = show;
				pad.active = show;
			}
		}
		catch (e:Dynamic) {}
	}

	// ==================== Editor 识别 ====================

	public static function editorIdOf(state:MusicBeatState):String
	{
		if (state == null) return null;
		var cls:String = Type.getClassName(Type.getClass(state));
		if (cls == null) return null;
		return EditorMobileKeyData.editorIdOfClassName(cls);
	}
}
