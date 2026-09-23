package developer.editors;

import general.backend.language.Language;
import general.backend.ClientPrefs;
import general.objects.WindowBarMode;
import general.objects.WindowControlBar;

/**
 * 编辑器顶栏使用的常驻窗口控制组（ChartEditor / CharacterEditor / StageEditor /
 * DialogueEditor / DialogueCharacterEditor / NoteSplashEditor）。
 *
 * 系统标题栏在这些编辑器里被隐藏（沉浸式），由它在顶栏右上角接管窗口控制：
 *   [退出 Xxx] [图标 NovaFlare Engine] │ - □ ×
 *
 * 实际实现与交互逻辑在 `WindowControlBar`（CONSTANT 模式）：
 * 最小化 / 最大化还原 / 关闭、悬停高亮、按住拖动窗口、双击最大化。
 * 退出按钮由 `setupExitButton()` 安装；`Exit Xxx` 的 Xxx 来自 `editors`
 * 语言组里各编辑器显示名（chartEditor / characterEditor / ...）。
 */
class EditorChromeUI extends WindowControlBar
{
	public function new()
	{
		super(WindowBarMode.CONSTANT);
	}

	/**
	 * 在「NovaFlare Engine」标题左侧安装「退出 <编辑器名>」按钮。
	 * 文案自动按当前语言组拼：
	 *   - 中文：「退出 编谱器」「退出 角色编辑器」……
	 *   - 英文："Exit Chart Editor" "Exit Character Editor" ……
	 * 编辑器名优先取 `editors` 语言组（与 MasterEditorMenu 的入口同源），
	 * 找不到时回退到传入的 key 本身。
	 */
	public function setupExitButton(editorNameKey:String, onExit:Void->Void):Void
	{
		var name:String = '';
		try { name = Language.get(editorNameKey, 'editors'); } catch (e:Dynamic) {}
		if (name == null || name == '' || name.indexOf('(404)') != -1)
			name = editorNameKey;

		var zh:Bool = false;
		try { zh = (ClientPrefs.data.language == 'Chinese'); } catch (e:Dynamic) {}
		var verb:String = zh ? '退出 ' : 'Exit ';

		setExitButton(verb + name, onExit);
	}
}
