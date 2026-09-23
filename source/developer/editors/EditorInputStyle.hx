package developer.editors;

import general.backend.language.Language;
import general.backend.Paths;

/**
 * 各编辑器输入框统一「灰底白字」外观。
 *
 * 结论（经 WeekEditor 验证 + 诊断）：
 *  引擎 tile 渲染下原生控件文本不可靠的根源是 set_color 的白色早退 + TextField
 *  反射不可用。可靠做法 = 【构建期】直接改 flixel 持有的 _defaultFormat
 *  （haxe 对象，反射可写）把文本颜色设为白，让后续每次文本渲染都用白色格式；
 *  运行时弹层只做同样的直改 + _regen 标记。
 *
 * 背景/边框/caret 走官方 setter（calcFrame 会重建对应 sprite）。
 */
class EditorInputStyle
{
	public static final BG:Int = 0xFF12141A;
	public static final BORDER:Int = 0x26FFFFFF;

	/** 当前语言对应的字体文件名（读 main 语言组 fontName，缺失时按语言兜底） */
	public static function langFontFileName():String
	{
		var n:String = 'chillax';
		try { n = Language.get('fontName', 'main'); } catch (e:Dynamic) {}
		if (n == null || n == '' || n.indexOf('fontName') != -1 || n.indexOf('404') != -1)
			n = (ClientPrefs.data.language == 'Chinese') ? 'Lang-ZH' : 'chillax';
		return n + '.ttf';
	}

	/**
	 * 把输入控件染成灰底白字（构建期与弹层期均可调用，幂等）：
	 *  - 字体 = 对应语言的字体（main 组 fontName，如中文 Lang-ZH）
	 *  - 直接写 _defaultFormat.color = 白（绕过 FlxText.set_color 的白色早退）
	 *  - 背景灰 / 边框浅灰 / 光标白 / 字号 12
	 */
	public static function apply(w:Dynamic, ?fieldW:Float):Void
	{
		if (w == null) return;

		// ★ 字体：对应语言的字体（与菜单文本同一来源）
		try { w.font = Paths.font(langFontFileName()); } catch (e:Dynamic) {}

		// ★ 文本颜色：直接改 flixel 持有的 TextFormat（haxe 对象，Dynamic 可靠）
		try
		{
			var df:Dynamic = Reflect.field(w, '_defaultFormat');
			if (df != null)
				df.color = 0xFFFFFF;
		}
		catch (e:Dynamic) {}
		// 同步 color 字段（FlxSprite tint 用；不依赖其 setter 是否早退）
		try { w.color = 0xFFFFFFFF; } catch (e:Dynamic) {}

		try { w.backgroundColor = BG; } catch (e:Dynamic) {}
		try { w.fieldBorderColor = BORDER; } catch (e:Dynamic) {}
		try { w.caretColor = 0xFFFFFFFF; } catch (e:Dynamic) {}
		try { w.size = 12; } catch (e:Dynamic) {}
		if (fieldW != null)
		{
			try { w.fieldWidth = fieldW; } catch (e:Dynamic) {}
		}
		// 标记文本重渲（由绘制/后续 set_text 触发 calcFrame）
		try { Reflect.setField(w, '_regen', true); } catch (e:Dynamic) {}
	}

	/**
	 * 类型化设置 FlxInputText 的 hasFocus（必须走 setter）。
	 *
	 * set_hasFocus 内 `#if mobile` 会执行 window.textInputEnabled = true/false
	 * （SDL 弹/收安卓软键盘）。若用 Dynamic 赋值 `w.hasFocus = true` 会绕过
	 * setter 直接写字段 → 桌面一切正常（字符走 stage KEY_DOWN），安卓却永远
	 * 弹不出软键盘。
	 */
	public static function setInputFocus(w:Dynamic, focus:Bool):Void
	{
		if (w == null)
			return;
		if (Std.isOfType(w, flixel.addons.ui.FlxInputText))
		{
			var fi:flixel.addons.ui.FlxInputText = cast w;
			@:privateAccess fi.hasFocus = focus;
			return;
		}
		// 兜底：非 FlxInputText 的控件直接写字段
		try
		{
			Reflect.setProperty(w, 'hasFocus', focus);
		}
		catch (e:Dynamic) {}
	}

	/**
	 * 深递归把一个原生 FlxUI 控件整棵子树隐藏（visible=false + active=false）。
	 *
	 *  为什么要深递归：
	 *   - FlxUICheckBox.set_visible 是 `// don't cascade to my members` 的特制版，
	 *     设父 visible=false 不会带动 button 子对象隐藏；
	 *   - FlxUIDropDownMenu.set_visible 会保留子按钮原本的可见状态再恢复 →
	 *     visible=false 同样不会隐藏 list 子按钮 / dropPanel；
	 *   - FlxUIGroup / FlxSpriteGroup 子对象 `active=true` 时还会持续抢鼠标
	 *     事件，即使父对象 visible=false 也不行。
	 *
	 *  调用方在编辑器 create() 里统一调一次，把所有原生 widget 子树
	 * 彻底隐藏、改由自绘控件承担交互。
	 */
	public static function deepHide(w:Dynamic):Void
	{
		if (w == null) return;
		try { w.visible = false; } catch (e:Dynamic) {}
		try { w.active = false; } catch (e:Dynamic) {}
		// 1) FlxUICheckBox / FlxUIButton 等持有 `button` / `box` / `mark` 子对象
		try
		{
			for (fieldName in ['button', 'box', 'mark'])
			{
				var sub:Dynamic = Reflect.field(w, fieldName);
				if (sub != null) deepHide(sub);
			}
		}
		catch (e:Dynamic) {}
		// 2) FlxUIDropDownMenu 持有 `header` / `dropPanel` / `list` 子对象
		try
		{
			var header:Dynamic = Reflect.field(w, 'header');
			if (header != null) deepHide(header);
			var dropPanel:Dynamic = Reflect.field(w, 'dropPanel');
			if (dropPanel != null) deepHide(dropPanel);
			var list:Dynamic = Reflect.field(w, 'list');
			if (list != null)
			{
				try
				{
					for (item in (list:Array<Dynamic>))
						if (item != null) deepHide(item);
				}
				catch (e:Dynamic) {}
			}
		}
		catch (e:Dynamic) {}
		// 3) FlxSpriteGroup / FlxUIGroup 持有 `members` 列表
		try
		{
			var members:Dynamic = Reflect.field(w, 'members');
			if (members != null)
			{
				try
				{
					for (m in (members:Array<Dynamic>))
						if (m != null) deepHide(m);
				}
				catch (e:Dynamic) {}
			}
		}
		catch (e:Dynamic) {}
	}
}
