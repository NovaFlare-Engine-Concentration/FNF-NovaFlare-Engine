package developer.editors;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.ui.FlxUI;
import flixel.addons.ui.FlxUIDropDownMenu;
import flixel.addons.ui.FlxUIInputText;
import flixel.addons.ui.FlxUINumericStepper;
import flixel.addons.ui.FlxUISlider;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.util.FlxDestroyUtil;

import general.backend.language.Language;
import general.backend.ClientPrefs;
import general.backend.Paths;

/**
 * Adobe 风格的角色编辑器顶栏菜单（与 ChartEditorMenuBar 同一套自绘架构）。
 *
 * 设计：
 *  - 顶栏 6 个菜单按钮：角色 / 动画 / 设置 / 外观 / 文件 / 帮助
 *  - 点击按钮 → 弹出下拉浮窗，包含若干行
 *  - 行类型：sep / cmd / widget / label_widget / text
 *  - hover 行 → 底部描述条显示该项说明（弹性换行）
 *  - 自绘控件：stepper（[+]/[-]）、dropdown（▼ 展开面板）、input（点击弹原生覆盖层）、
 *    slider（拖拽滑块，新增能力，用于 Ghost 透明度等）
 *
 * 所有原生控件（checkbox、输入框、下拉列表、数字步进器、滑块）只作数据源，
 * 外观完全自绘。CharacterEditorState 通过 registerWidget 注册控件。
 */
class CharacterEditorMenuBar extends FlxSpriteGroup
{
	// ============ 颜色常量（NovaFlare 设计规范 · 深色模式 · AARRGGBB）============
	// ---- 中性色 ----
	static final C_PAGE_BG:FlxColor = 0xFF12141A;      // 页面底层背景
	static final C_CARD_BG:FlxColor = 0xFF1C1F28;      // 卡片面板背景
	static final C_FIELD_BG:FlxColor = 0xFF12141A;     // 内嵌输入/控件区域（比卡片更深，内凹感）
	static final C_HOVER_OVERLAY:FlxColor = 0x147C7FFF; // Hover 通用底色（半透明）
	static final C_BORDER:FlxColor = 0x14FFFFFF;        // 分割/边框（半透明白）
	static final C_BORDER_STRONG:FlxColor = 0x26FFFFFF; // 模拟边框（更明显）
	static final C_TEXT_MAIN:FlxColor = 0xFFF2F3F5;    // 主文字
	static final C_TEXT_SEC:FlxColor = 0xFFC9CDD4;     // 次级文字
	static final C_TEXT_HINT:FlxColor = 0xFF86909C;    // 提示文字

	// ---- 一级主菜单（顶栏）----
	static final C_MENU_IDLE:FlxColor = 0xFFC9CDD4;      // 未选中文字
	static final C_MENU_SEL_A:FlxColor = 0xFF4F46E5;     // 选中渐变起点（indigo）
	static final C_MENU_SEL_B:FlxColor = 0xFF7C3AED;     // 选中渐变终点（violet）
	static final C_MENU_SEL_TEXT:FlxColor = 0xFFFFFFFF;  // 选中文字
	static final C_MENU_ACCENT:FlxColor = 0xFFA78BFA;    // 左侧装饰条 / 强调（light violet）

	// ---- 二级子菜单（下拉行）----
	static final C_SUB_TEXT:FlxColor = 0xFFC9CDD4;       // 未选中文字
	static final C_SUB_HOVER:FlxColor = 0x0F8B5CF6;      // hover 底色（半透明）
	static final C_SUB_SEL_BG:FlxColor = 0x268B5CF6;     // 选中底色（半透明）
	static final C_SUB_SEL_TEXT:FlxColor = 0xFFA78BFA;   // 选中文字

	// ---- 主按钮（渐变）----
	static final C_PRIMARY_A:FlxColor = 0xFF6366F1;      // 默认渐变起点
	static final C_PRIMARY_B:FlxColor = 0xFF8B5CF6;      // 默认渐变终点
	static final C_PRIMARY_HOVER_A:FlxColor = 0xFF4F46E5; // hover 渐变起点
	static final C_PRIMARY_HOVER_B:FlxColor = 0xFF7C3AED; // hover 渐变终点
	static final C_HOVER_LIFT:FlxColor = 0x1AFFFFFF;     // hover 提亮覆盖（叠在渐变上）

	// ---- 危险 ----
	static final C_DANGER:FlxColor = 0xFFEF4444;         // 危险文字/渐变起点
	static final C_DANGER_B:FlxColor = 0xFFDC2626;       // 危险渐变终点

	// ---- 状态反馈色 ----
	static final C_SUCCESS:FlxColor = 0xFF22C55E;
	static final C_WARN:FlxColor = 0xFFF59E0B;
	static final C_INFO:FlxColor = 0xFF3B82F6;

	// ============ 布局常量 ============
	public static final BAR_HEIGHT:Int = 36;
	public static final STATUS_HEIGHT:Int = 25;
	public static final MENU_W:Int = 88;
	// ★ 所有菜单下拉统一宽度（= DROP_MAX_W）：保证各菜单的输入框/控件区宽度一致，不再长短不一
	public static final DROP_MIN_W:Int = 420;
	public static final DROP_MAX_W:Int = 420;
	public static final DESC_MAX_W:Int = 620;
	public static final ROW_H:Int = 22;
	public static final ROW_PAD_X:Int = 10;
	// 自绘下拉选项列表：每项高度 / 最多同时显示项数
	static final DROP_OPT_H:Int = 20;
	static final MAX_DROP_OPT:Int = 20;

	// 走马灯：长文本滚动速度（px/s）与两端停留秒数
	static final TEXT_SCROLL_SPEED:Float = 32;
	static final TEXT_SCROLL_HOLD:Float = 0.9;

	// ============ 菜单定义 ============
	public var menus:Array<CharacterMenuDef> = [];
	public var activeMenu:Int = -1;

	// ============ 顶栏视觉元素 ============
	var barBg:FlxSprite;
	var menuTitleSprites:Array<FlxText> = [];
	var menuTitleHits:Array<FlxSprite> = [];  // 透明 hitbox
	var menuTabActives:Array<FlxSprite> = []; // 选中渐变背景（每按钮一个，左→右 indigo→violet）
	var menuTabHovers:Array<FlxSprite> = [];  // hover 底色（每按钮一个，通用 hover 半透明蓝）
	var menuUnderline:FlxSprite;              // 选中装饰条（A78BFA，选中项下缘）

	// ============ 下拉浮窗 ============
	var dropGroup:FlxSpriteGroup;
	var dropBg:FlxSprite;
	var dropBorder:FlxSprite;
	var dropRows:Array<CharacterDropdownRow> = [];
	// 跟踪所有加进 dropGroup 的东西（widget、文本、分隔线等），cleanup 时一起搞掉
	var dropGroupMembers:Array<Dynamic> = [];
	// ★ LabelWidget 的 FlxUI 控件绝不塞进 dropGroup（FlxUIGroup ≠ FlxSprite，parent 链会炸）
	//   独立跟踪，只做定位+显隐
	var activeLabelWidgets:Array<Dynamic> = [];
	// ★ 自绘控件（stepper / dropdown / input / slider）：用纯 FlxSprite/FlxText 画外观 + 自己处理点击，
	//   原生 FlxUI 控件只留作数据源，绝不渲染
	var customControls:Array<CharacterCustomControl> = [];
	// DynText 动态文本行：key -> 渲染出来的 FlxText（重建菜单时刷新），内容由外部 provider 提供
	var dynTexts:Map<String, FlxText> = [];
	var dynTextProviders:Map<String, Void->String> = [];

	// hover 切换守卫：只在 hover 索引变化时才 openMenu，不每帧重建
	var lastHoverSwitchIdx:Int = -1;

	// ============ 描述条 ============
	var descBg:FlxSprite;
	var descIcon:FlxText;
	var descText:FlxText;
	var curDescKey:String = '';
	// ★ 弹性背景缓存：文本 / 高度 / 位置都没变就跳过重建（updateDescBar 每帧都会被调用）
	var lastDescCacheKey:String = '';
	var lastDescH:Int = 0;

	// ============ 状态栏（独立组件） ============
	public var statusBar:CharacterEditorStatusBar;

	// ============ 当前临时弹出编辑的原生 widget（LabelWidget 点击时显示） ============
	var activeEditWidget:Dynamic = null;
	var activeEditPrevX:Float = 0;
	var activeEditPrevY:Float = 0;
	var activeEditPrevVisible:Bool = false;

	// ============ stepper 数字输入覆盖层（点击数值文本直接键入） ============
	// 覆盖层是独立创建的 FlxUIInputText（不依赖外部注册的 input widget），
	// 打开时定位到 stepper 文本区并聚焦，回车/失焦提交（解析数字写回原生 stepper）
	var stepperOverlay:FlxUIInputText = null;
	var stepperOverlayCtrl:CharacterCustomControl = null;

	// ★ 鼠标在 uiCamera 视图空间的坐标（每帧 update 开头算一次，内部统一使用）。
	//   菜单组件挂在独立 HUD 相机（camHUD）上，不能直接用 FlxG.mouse.viewX（那是主相机的视图坐标，
	//   主相机缩放/滚动时会导致 UI 命中判定错乱）
	var mViewX:Float = 0;
	var mViewY:Float = 0;

	// ============ 下拉面板拖拽滚动状态 ============
	// 按下在展开的面板内 → 记录（可能是点击选择，也可能是拖拽开始）；
	// 移动超过阈值 → 拖拽滚动；松开且未拖动 → 视为点击（选择选项）
	var panelPressCtrl:CharacterCustomControl = null; // 按下时点中的展开面板
	var panelPressY:Float = 0;                        // 按下时鼠标 y
	var panelPressScroll:Int = 0;                     // 按下时 scrollIdx
	var panelDragMoved:Bool = false;                  // 是否已进入拖拽

	// ============ 外部回调 ============
	/** 操作回调，参数是 action key（如 'save'、'anim_add_update' 等） */
	public var onAction:String->Void = null;
	/** 菜单打开后回调，用于让外部（CharacterEditorState）刷新 widget 的值 */
	public var onMenuOpened:String->Void = null;

	/** 当前用于鼠标判定的摄像机，默认 FlxG.camera；CharacterEditorState 可在 create 末尾覆盖。 */
	public var uiCamera:flixel.FlxCamera;

	/** 顶层覆盖层容器（CharacterEditorState 赋值）：stepper 覆盖层挂这里，渲染在菜单之上 */
	public var overlayLayer:FlxSpriteGroup = null;

	public function new()
	{
		super();
		scrollFactor.set();
		uiCamera = flixel.FlxG.camera;

		// 先添加状态栏，确保下拉菜单和描述条在其之上渲染
		statusBar = new CharacterEditorStatusBar();
		statusBar.scrollFactor.set();
		add(statusBar);

		buildMenuBar();
		buildDropdown();
		buildDescBar();

		buildMenus();
		applyLang();
	}

	/** 按当前客户端语言返回合适的字体文件名（读 main 语言组配置，非硬编码） */
	public static function langFont():String
	{
		return EditorInputStyle.langFontFileName();
	}

	// ============ 渐变工具（与 ChartEditorMenuBar 同款：逐像素 setPixel32 生成）============
	/** 生成 上→下 / 左→右 线性渐变位图 sprite（默认竖直） */
	static function makeGradSprite(w:Int, h:Int, c1:Int, c2:Int, horizontal:Bool = false):FlxSprite
	{
		var s:FlxSprite = new FlxSprite().makeGraphic(w, h, FlxColor.WHITE);
		var bd:openfl.display.BitmapData = s.pixels;
		if (bd != null)
		{
			bd.lock();
			for (y in 0...h)
			{
				for (x in 0...w)
				{
					var t:Float = 0;
					if (horizontal && w > 1) t = x / (w - 1);
					else if (h > 1) t = y / (h - 1);
					bd.setPixel32(x, y, FlxColor.interpolate(c1, c2, t));
				}
			}
			bd.unlock();
			s.dirty = true;
		}
		return s;
	}

	// ============ 构建顶栏 ============
	function buildMenuBar():Void
	{
		barBg = new FlxSprite().makeGraphic(FlxG.width, BAR_HEIGHT, C_PAGE_BG);
		barBg.x = 0;
		barBg.y = 0;
		add(barBg);

		// 顶栏底部 1px 分隔线（半透明白边框）
		var bottomLine:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, 1, C_BORDER);
		bottomLine.y = BAR_HEIGHT - 1;
		add(bottomLine);
	}

	// ============ 构建下拉浮窗（复用容器） ============
	function buildDropdown():Void
	{
		dropGroup = new FlxSpriteGroup();
		dropGroup.visible = false;
		add(dropGroup);

		dropBorder = new FlxSprite().makeGraphic(1, 1, C_BORDER_STRONG);
		dropGroup.add(dropBorder);
		dropBg = new FlxSprite().makeGraphic(1, 1, C_CARD_BG);
		dropGroup.add(dropBg);
	}

	// ============ 构建描述条 ============
	function buildDescBar():Void
	{
		descBg = new FlxSprite().makeGraphic(1, 1, C_PAGE_BG);
		descBg.visible = false;
		add(descBg);
		descIcon = new FlxText(0, 0, 0, '[i]', 12);
		descIcon.setFormat(Paths.font(langFont()), 12, C_MENU_ACCENT, LEFT);
		descIcon.visible = false;
		add(descIcon);
		descText = new FlxText(0, 0, DESC_MAX_W, '', 12);
		descText.setFormat(Paths.font(langFont()), 12, C_TEXT_HINT, LEFT);
		descText.visible = false;
		descText.alignment = LEFT;
		add(descText);
	}

	// ============ 菜单数据定义 ============
	public function buildMenus():Void
	{
		menus = [
			{key: 'char', isTest: false, items: [
				item_label_widget('w_char_select', 'label_char_select', 'desc_char_select'),
				item_label_widget('w_image', 'label_image', 'desc_image'),
				item_cmd('reload_image', 'desc_reload_image', () -> callAction('reload_image')),
				item_label_widget('w_health_icon', 'label_health_icon', 'desc_health_icon'),
				item_cmd('get_icon_color', 'desc_get_icon_color', () -> callAction('get_icon_color')),
				item_label_widget('w_vocals', 'label_vocals', 'desc_vocals'),
			]},
			{key: 'anim', isTest: false, items: [
				item_label_widget('w_anim_select', 'label_anim_select', 'desc_anim_select'),
				item_label_widget('w_anim_name', 'label_anim_name', 'desc_anim_name'),
				item_label_widget('w_anim_symbol', 'label_anim_symbol', 'desc_anim_symbol'),
				item_label_widget('w_anim_fps', 'label_anim_fps', 'desc_anim_fps'),
				item_widget('w_anim_loop', 'desc_anim_loop'),
				item_label_widget('w_anim_indices', 'label_anim_indices', 'desc_anim_indices'),
				SEP,
				item_cmd('anim_add_update', 'desc_anim_add_update', () -> callAction('anim_add_update')),
				item_cmd('anim_remove', 'desc_anim_remove', () -> callAction('anim_remove')),
			]},
			{key: 'settings', isTest: false, items: [
				item_widget('w_playable', 'desc_playable'),
				SEP,
				item_widget('w_flip_x', 'desc_flip_x'),
				item_widget('w_no_aa', 'desc_no_aa'),
				item_label_widget('w_scale', 'label_scale', 'desc_scale'),
				item_label_widget('w_sing_duration', 'label_sing_duration', 'desc_sing_duration'),
				SEP,
				item_label_widget('w_pos_x', 'label_pos_x', 'desc_pos_x'),
				item_label_widget('w_pos_y', 'label_pos_y', 'desc_pos_y'),
				item_label_widget('w_cam_x', 'label_cam_x', 'desc_cam_x'),
				item_label_widget('w_cam_y', 'label_cam_y', 'desc_cam_y'),
				SEP,
				item_label_widget('w_health_r', 'label_health_r', 'desc_healthbar_colors'),
				item_label_widget('w_health_g', 'label_health_g', 'desc_healthbar_colors'),
				item_label_widget('w_health_b', 'label_health_b', 'desc_healthbar_colors'),
			]},
			{key: 'ghost', isTest: false, items: [
				item_cmd('make_ghost', 'desc_make_ghost', () -> callAction('make_ghost')),
				item_widget('w_highlight_ghost', 'desc_highlight_ghost'),
				item_label_widget('w_ghost_alpha', 'label_ghost_alpha', 'desc_ghost_alpha'),
			]},
			{key: 'file', isTest: false, items: [
				item_cmd('save', 'desc_save', () -> callAction('save')),
				item_cmd('load_template', 'desc_load_template', () -> callAction('load_template')),
				item_cmd('reload_char', 'desc_reload_char', () -> callAction('reload_char')),
			]},
			{key: 'help', isTest: false, items: [
				item_text('help_camera', 'desc_help_camera'),
				item_text('help_cam_zoom', 'desc_help_cam_zoom'),
				item_text('help_cam_move', 'desc_help_cam_move'),
				item_text('help_cam_reset', 'desc_help_cam_reset'),
				SEP,
				item_text('help_char', 'desc_help_char'),
				item_text('help_char_anim', 'desc_help_char_anim'),
				item_text('help_char_offset', 'desc_help_char_offset'),
				item_text('help_char_offset_keys', 'desc_help_char_offset_keys'),
				item_text('help_char_replay', 'desc_help_char_replay'),
				item_text('help_char_frame', 'desc_help_char_frame'),
				SEP,
				item_text('help_other', 'desc_help_other'),
				item_text('help_other_sil', 'desc_help_other_sil'),
				item_text('help_other_shift', 'desc_help_other_shift'),
				item_text('help_other_ctrl', 'desc_help_other_ctrl'),
				item_text('help_other_help', 'desc_help_other_help'),
				item_text('help_other_exit', 'desc_help_other_exit'),
			]},
		];
	}

	// ============ 行类型辅助函数 ============
	static var SEP:CharacterMenuItemDef = {type: Sep, labelKey: null, descKey: null, getChecked: null, onCheck: null, onClick: null};

	function item_cmd(labelKey:String, descKey:String, onClick:Void->Void):CharacterMenuItemDef
	{
		return {type: Cmd, labelKey: labelKey, descKey: descKey, getChecked: null, onCheck: null, onClick: onClick};
	}

	function item_widget(widgetKey:String, descKey:String):CharacterMenuItemDef
	{
		return {type: Widget, labelKey: widgetKey, descKey: descKey, getChecked: null, onCheck: null, onClick: null, widgetKey: widgetKey};
	}

	function item_label_widget(widgetKey:String, labelKey:String, descKey:String):CharacterMenuItemDef
	{
		return {type: LabelWidget, labelKey: labelKey, descKey: descKey, getChecked: null, onCheck: null, onClick: null, widgetKey: widgetKey};
	}

	function item_text(textKey:String, descKey:String):CharacterMenuItemDef
	{
		return {type: TextLine, labelKey: textKey, descKey: descKey, getChecked: null, onCheck: null, onClick: null};
	}

	function item_dyn_text(dynKey:String, descKey:String):CharacterMenuItemDef
	{
		return {type: DynText, labelKey: dynKey, descKey: descKey, getChecked: null, onCheck: null, onClick: null};
	}

	// ============ 翻译 key 转换 ============
	// ★ dev 模式下 Language.get 找不到 key 会返回 'key (404)'，必须同时拦截。
	/** Widget 类型：w_metronome -> item_metronome */
	function translateItemKey(key:String):String
	{
		var itemKey = key;
		if (key.indexOf('w_') == 0)
			itemKey = 'item_' + key.substring(2);
		var translated = Language.get(itemKey, 'character');
		if (translated == itemKey || translated.indexOf('(404)') != -1) {
			// 尝试不带 item_ 前缀
			translated = Language.get(key.substring(2), 'character');
		}
		return translated;
	}

	/** LabelWidget 类型：label_bpm -> label_bpm (直接查) */
	function translateLabelKey(key:String):String
	{
		var translated = Language.get(key, 'character');
		if (translated == key || translated.indexOf('(404)') != -1) {
			// 尝试带 label_ 前缀
			translated = Language.get('label_' + key, 'character');
		}
		if (translated == 'label_' + key || translated.indexOf('(404)') != -1) {
			// 还是找不到，就用原始 key
			translated = key;
		}
		return translated;
	}

	// ============ 语言切换时刷新 ============
	public function applyLang():Void
	{
		// 重建顶栏按钮
		while (menuTitleSprites.length > 0)
		{
			var t = menuTitleSprites.pop();
			remove(t, true);
			t.destroy();
		}
		while (menuTitleHits.length > 0)
		{
			var h = menuTitleHits.pop();
			remove(h, true);
			h.destroy();
		}
		while (menuTabActives.length > 0)
		{
			var s = menuTabActives.pop();
			remove(s, true);
			s.destroy();
		}
		while (menuTabHovers.length > 0)
		{
			var s = menuTabHovers.pop();
			remove(s, true);
			s.destroy();
		}
		if (menuUnderline != null)
		{
			remove(menuUnderline, true);
			menuUnderline.destroy();
			menuUnderline = null;
		}

		for (i in 0...menus.length)
		{
			// ★ 选中态：主渐变背景（4F46E5 → 7C3AED，左→右），每按钮预生成一个（与 ChartEditor 一致）
			var activeBg:FlxSprite = makeGradSprite(MENU_W, BAR_HEIGHT, C_MENU_SEL_A, C_MENU_SEL_B, true);
			activeBg.x = i * MENU_W;
			activeBg.y = 0;
			activeBg.visible = false;
			add(activeBg);
			menuTabActives.push(activeBg);

			// hover 底色（通用 hover 半透明蓝）
			var hoverBg:FlxSprite = new FlxSprite().makeGraphic(MENU_W, BAR_HEIGHT, C_HOVER_OVERLAY);
			hoverBg.x = i * MENU_W;
			hoverBg.y = 0;
			hoverBg.visible = false;
			add(hoverBg);
			menuTabHovers.push(hoverBg);

			var m = menus[i];
			var txt:FlxText = new FlxText(i * MENU_W, 0, MENU_W, Language.get('menu_' + m.key, 'character'), 14);
			txt.setFormat(Paths.font(langFont()), 14, C_MENU_IDLE, CENTER);
			txt.borderStyle = NONE;
			txt.y = (BAR_HEIGHT - txt.height) / 2;
			add(txt);
			menuTitleSprites.push(txt);

			// hitbox（透明）
			var hit:FlxSprite = new FlxSprite().makeGraphic(MENU_W, BAR_HEIGHT, FlxColor.TRANSPARENT);
			hit.x = i * MENU_W;
			hit.y = 0;
			add(hit);
			menuTitleHits.push(hit);
		}
		// 选中装饰条（A78BFA，位于选中项下缘，与 ChartEditor 一致）
		menuUnderline = new FlxSprite().makeGraphic(MENU_W - 24, 2, C_MENU_ACCENT);
		menuUnderline.visible = false;
		add(menuUnderline);

		// 状态栏也刷新
		if (statusBar != null)
			statusBar.applyLang();
	}

	// ============ CharacterEditorState 提供的辅助方法（外部赋值） ============
	/**
	 * 注册原生控件（FlxUICheckBox / FlxUIInputText / FlxUINumericStepper / FlxUIDropDownMenu / FlxUISlider 等）到菜单系统。
	 * key 必须和 buildMenus() 中 widget / label_widget 项的 key 一致。
	 * 控件生命周期由 CharacterEditorState 管理，菜单只负责 add/remove 到 dropGroup。
	 */
	var widgetRefs:Map<String, Dynamic> = [];
	public function registerWidget(key:String, widget:Dynamic):Void
	{
		widgetRefs.set(key, widget);
	}

	/** 注册动态文本行（DynText）的内容提供器。key 必须和 buildMenus() 中 item_dyn_text 的 key 一致。 */
	public function registerDynText(key:String, provider:Void->String):Void
	{
		dynTextProviders.set(key, provider);
	}

	/** 刷新所有 DynText 行的显示文本（provider 内容变化时调用）。 */
	public function refreshDynTexts():Void
	{
		for (key in dynTexts.keys())
		{
			var t:FlxText = dynTexts.get(key);
			if (t == null) continue;
			var txt:String = '';
			if (dynTextProviders.exists(key) && dynTextProviders.get(key) != null)
			{
				try { txt = dynTextProviders.get(key)(); } catch (e:Dynamic) { txt = ''; }
			}
			if (txt == null) txt = '';
			if (t.text != txt)
				t.text = txt;
		}
	}

	function callAction(actionKey:String):Void
	{
		if (onAction != null) onAction(actionKey);
		// 帮助菜单的文本行不需要关闭
		if (menus[activeMenu].key != 'help')
			closeMenu();
	}

	// ============ 每帧更新 ============
	override function update(elapsed:Float):Void
	{
		super.update(elapsed);

		// ★ 鼠标视图坐标：以 uiCamera（独立 HUD 相机）为准，每帧算一次。
		//   menuBar 所有 sprite 用 scrollFactor.set()=0（不随相机 scroll 移动），
		//   sprite.x 是世界坐标，但因为 scrollFactor=0，等价于视图空间坐标。
		//   HUD 相机 zoom=1/scroll=0，所以这里是纯屏幕坐标，不受主相机缩放影响。
		var mp:FlxPoint = FlxG.mouse.getViewPosition(uiCamera);
		mViewX = mp.x;
		mViewY = mp.y;
		mp.put();

		// 鼠标在顶栏按钮上 hover
		var hoverIdx:Int = -1;
		var hoverMx:Float = mViewX;
		var hoverMy:Float = mViewY;
		for (i in 0...menuTitleHits.length)
		{
			var h = menuTitleHits[i];
			if (hoverMx >= h.x && hoverMx <= h.x + h.width && hoverMy >= h.y && hoverMy <= h.y + h.height)
			{
				hoverIdx = i;
				break;
			}
		}

		// Adobe 风格：当菜单已经展开时，hover 其他菜单项直接切换（不用再点）
		// 但只在 hover 索引变化时触发一次，不每帧重建
		if (activeMenu >= 0 && hoverIdx >= 0 && hoverIdx != activeMenu && hoverIdx != lastHoverSwitchIdx && !FlxG.mouse.justPressed)
		{
			lastHoverSwitchIdx = hoverIdx;
			openMenu(hoverIdx);
		}
		if (hoverIdx < 0) lastHoverSwitchIdx = -1;

		if (FlxG.mouse.justPressed)
		{
			var mx:Float = mViewX;
			var my:Float = mViewY;
			var insideUI:Bool = isMouseInsideUI(mx, my);

			if (hoverIdx >= 0)
			{
				// 点在顶栏按钮上：切换菜单
				if (activeMenu == hoverIdx)
					closeMenu();
				else
					openMenu(hoverIdx);
			}
			else if (activeMenu >= 0)
			{
				if (insideUI)
				{
					// ★ 点在列表/描述条/嵌入控件上 → 不关闭，不抢事件
					// ① 输入覆盖层正在编辑中：点覆盖层内部 → 不抢，让输入框处理
					if (isOverActiveEditWidget(mx, my))
					{
						// 啥都不做
					}
					else
					{
						// 点覆盖层之外 → 失焦收回（覆盖层 active=false 后不会自己失焦，得手动收）
						if (activeEditWidget != null)
							clearActiveEditWidget();
						// ② 展开的 dropdown 面板点击优先（面板选项行不在 dropRows 里，得单独判）
						var panelHandled:Bool = handleDropdownPanelClick(mx, my);
						if (!panelHandled)
						{
							// ③ 普通行点击
							var hitRow:CharacterDropdownRow = null;
							for (row in dropRows)
							{
								if (row.hit != null)
								{
									var h = row.hit;
									if (mx >= h.x && mx <= h.x + h.width && my >= h.y && my <= h.y + h.height)
									{
										hitRow = row;
										break;
									}
								}
							}
							if (hitRow != null)
							{
								var handled:Bool = false;
								// LabelWidget 行：先走自绘控件点击（stepper [+]/[-]、dropdown、input、slider）
								if (hitRow.def.type == LabelWidget)
									handled = handleCharacterCustomControlClick(hitRow);
								if (!handled)
								{
									activateRow(hitRow);
									// Cmd 点完关菜单；Widget/LabelWidget 保持打开
									var rowType = hitRow.def.type;
									if (rowType == Cmd || rowType == Check)
										closeMenu();
								}
							}
							else
							{
								// 点菜单空白区域（描述条 / 行间隙）→ 收起所有展开的下拉面板
								closeCustomDropdowns();
							}
						}
					}
				}
				else
				{
					// 点在 menuBar 任何 UI 之外 → 关闭列表
					closeMenu();
				}
			}
		}

		// ===== 一级主菜单视觉：选中渐变背景 + hover 底色 + 下缘装饰条（每按钮数组，直接切 visible）=====
		for (i in 0...menuTabActives.length)
		{
			if (menuTabActives[i] != null)
				menuTabActives[i].visible = (i == activeMenu);
		}
		for (i in 0...menuTabHovers.length)
		{
			if (menuTabHovers[i] != null)
				menuTabHovers[i].visible = (i == hoverIdx && i != activeMenu);
		}
		if (menuUnderline != null)
		{
			menuUnderline.visible = (activeMenu >= 0 && activeMenu < menus.length);
			if (menuUnderline.visible)
			{
				menuUnderline.x = activeMenu * MENU_W + 12;
				menuUnderline.y = BAR_HEIGHT - 2;
			}
		}
		// 按钮文字颜色：选中/悬停 → 白；否则次级色
		for (i in 0...menuTitleSprites.length)
		{
			var t = menuTitleSprites[i];
			var isActive = (i == activeMenu);
			var isHover = (i == hoverIdx);
			t.color = (isActive || isHover) ? C_MENU_SEL_TEXT : C_MENU_IDLE;
		}

		// 下拉行 hover → 更新描述条 + 绘制/清除 hover 背景
		if (activeMenu >= 0 && dropGroup.visible)
		{
			var hoverRow:CharacterDropdownRow = null;
			for (row in dropRows)
			{
				if (row.type == Sep || row.hit == null) continue;
				if (FlxG.mouse.overlaps(row.hit, uiCamera))
				{
					hoverRow = row;
					break;
				}
			}
			// 更新每行 hover 背景的可见性
			for (row in dropRows)
			{
				if (row.hoverBg != null)
					row.hoverBg.visible = (row == hoverRow);
			}
			updateDescBar(hoverRow);

			// ★ 自绘 dropdown 展开面板：选项行 hover 视觉
			var pMx:Float = mViewX;
			var pMy:Float = mViewY;
			for (ctrl in customControls)
			{
				if (ctrl.ctype != 'dropdown') continue;
				if (ctrl.open == true && ctrl.panelRows != null)
				{
					for (pr in ctrl.panelRows)
					{
						var hov = pointInSprite(pMx, pMy, pr.hit);
						// 当前选中项底色常显（不随 hover 关闭）
						if (pr.bg != null) pr.bg.visible = (pr.isSelected == true) || hov;
					}
				}
			}

			// ★ 自绘 dropdown 展开面板：鼠标滚轮滚动
			if (FlxG.mouse.wheel != 0)
			{
				for (ctrl in customControls)
				{
					if (ctrl.ctype != 'dropdown' || ctrl.open != true) continue;
					if (ctrl.panelBg == null || !pointInSprite(pMx, pMy, ctrl.panelBg)) continue;
					var total:Int = (ctrl.options != null) ? ctrl.options.length : 0;
					var maxScroll:Int = Std.int(Math.max(0, total - MAX_DROP_OPT));
					ctrl.scrollIdx = Std.int(FlxMath.bound(ctrl.scrollIdx - FlxG.mouse.wheel, 0, maxScroll));
					clearDropdownPanel(ctrl);
					renderCharacterDropdownOptions(ctrl);
					break;
				}
			}
		}

		// ★ 下拉面板拖拽滚动：按住面板上下拖动（移动超阈值后按 DROP_OPT_H 每项滚动）
		if (panelPressCtrl != null && FlxG.mouse.pressed)
		{
			var dy:Float = mViewY - panelPressY;
			if (!panelDragMoved && Math.abs(dy) > 6)
				panelDragMoved = true;
			if (panelDragMoved)
			{
				var ctrl:CharacterCustomControl = panelPressCtrl;
				var total:Int = (ctrl.options != null) ? ctrl.options.length : 0;
				var maxScroll:Int = Std.int(Math.max(0, total - MAX_DROP_OPT));
				var newScroll:Int = Std.int(FlxMath.bound(panelPressScroll - Std.int(dy / DROP_OPT_H), 0, maxScroll));
				if (newScroll != ctrl.scrollIdx)
				{
					ctrl.scrollIdx = newScroll;
					clearDropdownPanel(ctrl);
					renderCharacterDropdownOptions(ctrl);
					// 重新基准：拖拽过程平滑跟随
					panelPressScroll = newScroll;
					panelPressY = mViewY;
				}
			}
		}
		// ★ 松开：未拖动 → 执行面板点击（选选项/收起）
		if (panelPressCtrl != null && FlxG.mouse.justReleased)
		{
			releaseDropdownPanelClick();
			panelPressCtrl = null;
			panelDragMoved = false;
		}

		// ★ 自绘 slider 拖动跟随
		for (ctrl in customControls)
		{
			if (ctrl.ctype != 'slider' || ctrl.dragging != true) continue;
			if (FlxG.mouse.pressed)
				sliderDrag(ctrl, mViewX);
			else
				ctrl.dragging = false;
		}

		// ★ stepper 数字输入覆盖层：回车提交 / 失焦提交
		if (stepperOverlayCtrl != null)
		{
			// ★ 输入时 regen 会重置背景宽度，每帧保持撑满 box
			stretchOverlayBackground(stepperOverlay, stepperOverlayCtrl.box.width);
			var stillFocused:Bool = false;
			try { stillFocused = stepperOverlay.hasFocus; } catch (e:Dynamic) {}
			if (!stillFocused || FlxG.keys.justPressed.ENTER)
				commitStepperOverlay();
		}

		// ★ 输入覆盖层：每帧把正在输入的原生文本实时同步到自绘显示（否则输入时看起来"没反应"）
		if (activeEditWidget != null)
		{
			for (ctrl in customControls)
			{
				if (ctrl.ctype == 'input' && ctrl.widget == activeEditWidget)
				{
					var curText:String = '';
					try { curText = activeEditWidget.text; } catch (e:Dynamic) {}
					if (ctrl.text != null && ctrl.text.text != curText)
						updateInputDisplay(ctrl);
					// ★ 输入时 regen 会重置背景宽度，每帧保持撑满 box
					stretchOverlayBackground(activeEditWidget, ctrl.box.width);
				}
			}
			// 失焦检测：原生输入框失去焦点 → 收回覆盖层
			var stillFocused:Bool = false;
			try { stillFocused = activeEditWidget.hasFocus; } catch (e:Dynamic) {}
			if (!stillFocused)
			{
				// 失焦前把原生输入框的最终文本同步回自绘显示
				for (ctrl in customControls)
				{
					if (ctrl.ctype == 'input' && ctrl.widget == activeEditWidget)
						updateInputDisplay(ctrl);
				}
				clearActiveEditWidget();
			}
		}

		// 走马灯：超宽文本从右往左滚动（广告牌效果）
		for (ctrl in customControls)
		{
			if (ctrl.isScrolling == true && ctrl.text != null && ctrl.text.textField != null)
			{
				var maxScroll:Float = ctrl.text.textField.textWidth - ctrl.text.fieldWidth;
				if (maxScroll > 0)
				{
					ctrl.scrollDelay -= elapsed;
					if (ctrl.scrollDelay <= 0)
					{
						ctrl.scrollT += elapsed;
						applyTextScroll(ctrl.text, Std.int(ctrl.scrollT * TEXT_SCROLL_SPEED));
						if (ctrl.scrollT * TEXT_SCROLL_SPEED >= maxScroll)
						{
							// 滚到尾部 → 回起点，两端各停留 TEXT_SCROLL_HOLD 秒
							applyTextScroll(ctrl.text, 0);
							ctrl.scrollT = 0;
							ctrl.scrollDelay = TEXT_SCROLL_HOLD;
						}
					}
				}
			}
		}
	}

	// ============ 自绘控件：显示刷新（从原生控件读数据） ============
	function refreshCharacterCustomControlDisplays():Void
	{
		for (ctrl in customControls)
		{
			if (ctrl.ctype == 'stepper') updateStepperDisplay(ctrl);
			else if (ctrl.ctype == 'dropdown') updateDropdownDisplay(ctrl);
			else if (ctrl.ctype == 'input') updateInputDisplay(ctrl);
			else if (ctrl.ctype == 'slider') updateSliderDisplay(ctrl);
		}
		refreshDynTexts();
	}

	function updateStepperDisplay(ctrl:CharacterCustomControl):Void
	{
		var txt:String = '';
		try { txt = Std.string(ctrl.widget.value); } catch (e:Dynamic) {}
		setControlText(ctrl, txt);
	}

	/** 文本强制单行（FlxText 默认 wordWrap=true 会换行）。超宽内容交给走马灯滚动，
	    不走滚动逻辑的（如下拉面板选项）会被 canvas 的 fieldWidth 边界自然裁剪。 */
	function fitTextOneLine(t:FlxText):Void
	{
		if (t == null) return;
		t.wordWrap = false;
	}

	/** 设置自绘控件显示文本；超宽自动进入走马灯（从右往左滚动） */
	function setControlText(ctrl:CharacterCustomControl, txt:String):Void
	{
		if (ctrl.text == null) return;
		ctrl.text.wordWrap = false;
		ctrl.text.text = txt;
		ctrl.isScrolling = (ctrl.text.textField != null && ctrl.text.textField.textWidth > ctrl.text.fieldWidth);
		ctrl.scrollT = 0;
		ctrl.scrollDelay = TEXT_SCROLL_HOLD;
		if (ctrl.text.textField != null)
			ctrl.text.textField.scrollH = 0;
		Reflect.setField(ctrl.text, '_regen', true);
	}

	/** 应用走马灯滚动偏移：textField.scrollH 移动内容（canvas 固定 fieldWidth 宽会被裁剪），
	    强制 _regen=true 让 draw() 重新生成 canvas。 */
	function applyTextScroll(t:FlxText, scrollH:Int):Void
	{
		if (t == null || t.textField == null) return;
		// 偏移没变化就不重绘，避免每帧 _regen 烧 CPU
		if (t.textField.scrollH == scrollH) return;
		t.textField.scrollH = scrollH;
		Reflect.setField(t, '_regen', true);
	}

	function updateDropdownDisplay(ctrl:CharacterCustomControl):Void
	{
		var lbl:String = '';
		// ★ selectedLabel 的 getter 是 private，隐藏状态下反射读恒为空；
		//   header.text.text 是 public 链路（header:FlxUIDropDownHeader → text:FlxUIText），
		//   直接读原生头部实际渲染的选中文本，最可靠。
		try { lbl = ctrl.widget.header.text.text; } catch (e:Dynamic) {}
		if (lbl == null || lbl == '')
		{
			try { lbl = ctrl.widget.selectedLabel; } catch (e:Dynamic) {}
		}
		if (lbl == null) lbl = '';
		setControlText(ctrl, lbl);
		// 同步选项列表（自绘面板展开用）
		ctrl.options = [];
		try
		{
			var list:Array<Dynamic> = ctrl.widget.list;
			if (list != null)
				for (b in list)
					if (b != null && b.label != null) ctrl.options.push(b.label.text);
		}
		catch (e:Dynamic) {}
	}

	function updateInputDisplay(ctrl:CharacterCustomControl):Void
	{
		var txt:String = '';
		try { txt = ctrl.widget.text; } catch (e:Dynamic) {}
		if (txt == null) txt = '';
		setControlText(ctrl, txt);
	}

	/** 读取 slider 当前值：优先从绑定对象反射读（原生 update 被 active=false 停掉后 value 字段不刷新）。 */
	function readSliderValue(ctrl:CharacterCustomControl):Float
	{
		var v:Float = 0;
		try { v = ctrl.widget.value; } catch (e:Dynamic) {}
		try
		{
			var obj:Dynamic = Reflect.field(ctrl.widget, '_object');
			var vs:String = Reflect.field(ctrl.widget, 'varString');
			if (obj != null && vs != null && vs.length > 0)
			{
				var rv:Dynamic = Reflect.getProperty(obj, vs);
				if (rv != null && !Math.isNaN(Std.parseFloat(Std.string(rv))))
					v = Std.parseFloat(Std.string(rv));
			}
		}
		catch (e:Dynamic) {}
		return v;
	}

	function updateSliderDisplay(ctrl:CharacterCustomControl):Void
	{
		if (ctrl.track == null) return;
		var minV:Float = 0;
		var maxV:Float = 1;
		try { minV = ctrl.widget.minValue; } catch (e:Dynamic) {}
		try { maxV = ctrl.widget.maxValue; } catch (e:Dynamic) {}
		var v:Float = readSliderValue(ctrl);
		var rel:Float = (maxV != minV) ? (v - minV) / (maxV - minV) : 0;
		rel = FlxMath.bound(rel, 0, 1);

		if (ctrl.fill != null)
		{
			ctrl.fill.x = ctrl.track.x;
			// ★ origin 已设为左上角（见 rebuildDropdown），scale.x 只向右拉伸，不会向两边扩
			ctrl.fill.scale.x = ctrl.track.width * rel;
		}
		if (ctrl.thumb != null)
			ctrl.thumb.x = ctrl.track.x + rel * ctrl.track.width - ctrl.thumb.width / 2;
		if (ctrl.text != null)
			ctrl.text.text = Std.string(FlxMath.roundDecimal(v, 2));
	}

	// ============ 自绘控件：点击交互 ============
	function pointInSprite(mx:Float, my:Float, s:FlxSprite):Bool
	{
		if (s == null) return false;
		return mx >= s.x && mx <= s.x + s.width && my >= s.y && my <= s.y + s.height;
	}

	/** LabelWidget 行的自绘控件点击。返回 true 表示已消费（菜单保持打开）。 */
	function handleCharacterCustomControlClick(row:CharacterDropdownRow):Bool
	{
		var ctrl:CharacterCustomControl = null;
		for (c in customControls)
		{
			if (c.row == row) { ctrl = c; break; }
		}
		if (ctrl == null) return false;

		var mx:Float = mViewX;
		var my:Float = mViewY;

		if (ctrl.ctype == 'stepper')
		{
			// 若该 stepper 的覆盖层正开着，先提交键入的值，避免被按钮步进覆盖
			if (stepperOverlayCtrl == ctrl)
				commitStepperOverlay();
			if (ctrl.btnPlus != null && pointInSprite(mx, my, ctrl.btnPlus)) { stepperPlus(ctrl); return true; }
			if (ctrl.btnMinus != null && pointInSprite(mx, my, ctrl.btnMinus)) { stepperMinus(ctrl); return true; }
			// 点数值文本区 → 弹出数字输入覆盖层（支持直接键入）
			if (ctrl.box != null && pointInSprite(mx, my, ctrl.box)) { openStepperOverlay(ctrl); return true; }
			return false;
		}
		if (ctrl.ctype == 'dropdown')
		{
			if (ctrl.box != null && pointInSprite(mx, my, ctrl.box))
			{
				if (ctrl.open == true) { clearDropdownPanel(ctrl); ctrl.open = false; }
				else { closeCustomDropdowns(); ctrl.open = true; renderCharacterDropdownOptions(ctrl); }
				return true;
			}
			return false;
		}
		if (ctrl.ctype == 'input')
		{
			if (ctrl.box != null && pointInSprite(mx, my, ctrl.box))
			{
				openInputOverlay(ctrl);
				return true;
			}
			return false;
		}
		if (ctrl.ctype == 'slider')
		{
			// 点击滑块区域（整个 box 都是命中区，thumb 比 track 高）→ 开始拖动
			if (ctrl.box != null && pointInSprite(mx, my, ctrl.box))
			{
				ctrl.dragging = true;
				sliderDrag(ctrl, mx);
				return true;
			}
			return false;
		}
		return false;
	}

	// ============ stepper 数字输入覆盖层 ============
	/** 点击 stepper 文本区 → 弹出独立 FlxUIInputText 覆盖层直接键入数字 */
	function openStepperOverlay(ctrl:CharacterCustomControl):Void
	{
		// 先收掉其他覆盖层（input 覆盖层 / 已有 stepper 覆盖层）
		if (activeEditWidget != null)
			clearActiveEditWidget();
		if (stepperOverlayCtrl != null)
			commitStepperOverlay();

		if (ctrl.widget == null || ctrl.box == null) return;
		if (stepperOverlay == null)
		{
			stepperOverlay = new FlxUIInputText(0, 0, 60, '', 8);
			try { stepperOverlay.scrollFactor.set(0, 0); } catch (e:Dynamic) {}
			// ★ 双相机：camHUD 与菜单同层（不缩放），主相机兜底（输入覆盖层实测在主相机可见）
			try { stepperOverlay.cameras = [uiCamera, FlxG.camera]; } catch (e:Dynamic) {}
			// 挂到顶层覆盖层容器（渲染在菜单之上）；无容器时挂 state
			var st:Dynamic = FlxG.state;
			try { if (overlayLayer != null) overlayLayer.add(stepperOverlay); else st.add(stepperOverlay); } catch (e:Dynamic) {}
		}

		stepperOverlayCtrl = ctrl;
		// 定位到数值文本区（左侧，让出右侧 +/- 按钮）
		stepperOverlay.x = ctrl.box.x + 2;
		stepperOverlay.y = ctrl.box.y - 1;
		// ★ 强制重建 graphic（同 openInputOverlay：隐藏后 graphic 可能被清，frame EMPTY 不渲染）
		try { Reflect.setField(stepperOverlay, '_regen', true); } catch (e:Dynamic) {}
		try { stepperOverlay.drawFrame(true); } catch (e:Dynamic) {}
		// ★ 覆盖层字号调大 + fieldWidth 撑满，避免"超小号输入框"
		try { stepperOverlay.size = 12; } catch (e:Dynamic) {}
		try { stepperOverlay.fieldWidth = ctrl.box.width - 40; } catch (e:Dynamic) {}
		// ★ fieldWidth 后强制 regen（背景按新宽度重建）
		try { Reflect.setField(stepperOverlay, '_regen', true); } catch (e:Dynamic) {}
		try { stepperOverlay.drawFrame(true); } catch (e:Dynamic) {}
		// ★ 背景/边框撑满 box（同 input 覆盖层）
		stretchOverlayBackground(stepperOverlay, ctrl.box.width);
		stepperOverlay.text = Std.string(ctrl.widget.value);
		try { stepperOverlay.visible = true; } catch (e:Dynamic) {}
		// ★ active=false：与 input 覆盖层同理，避免 FlxInputText.update 的 overlaps 焦点判定秒清焦点
		try { stepperOverlay.active = false; } catch (e:Dynamic) {}
		// ★ 提升绘制层级（overlayLayer 内移到末尾，渲染在菜单之上）
		try { if (overlayLayer != null) { overlayLayer.remove(stepperOverlay, true); overlayLayer.add(stepperOverlay); } } catch (e:Dynamic) {}
		// 聚焦（hasFocus setter 是 private，Dynamic 赋值绕过）
		try { EditorInputStyle.setInputFocus(stepperOverlay, true); } catch (e:Dynamic) {}
		try
		{
			var caretSprite:Dynamic = Reflect.field(stepperOverlay, 'caret');
			if (caretSprite != null) caretSprite.visible = true;
		}
		catch (e:Dynamic) {}
	}

	/** 提交 stepper 覆盖层：解析数字写回原生 stepper 并广播 CHANGE_EVENT */
	function commitStepperOverlay():Void
	{
		if (stepperOverlayCtrl == null) return;
		var ctrl:CharacterCustomControl = stepperOverlayCtrl;
		stepperOverlayCtrl = null;

		var w:Dynamic = ctrl.widget;
		if (w != null && stepperOverlay != null)
		{
			var parsed:Float = Std.parseFloat(stepperOverlay.text);
			if (!Math.isNaN(parsed))
			{
				// clamp 到 min/max
				try { var mn:Float = w.min; parsed = Math.max(parsed, mn); } catch (e:Dynamic) {}
				try { var mx:Float = w.max; parsed = Math.min(parsed, mx); } catch (e:Dynamic) {}
				try { w.value = parsed; } catch (e:Dynamic) {}
				// 广播 CHANGE_EVENT 让 CharacterEditorState.getEvent 更新数据
				try { FlxUI.event(FlxUINumericStepper.CHANGE_EVENT, w, w.value, w.params); } catch (e:Dynamic) {}
			}
			updateStepperDisplay(ctrl);
		}

		if (stepperOverlay != null)
		{
			try { stepperOverlay.visible = false; } catch (e:Dynamic) {}
			try { EditorInputStyle.setInputFocus(stepperOverlay, false); } catch (e:Dynamic) {}
		}
	}

	/** 拖拽滑块：按鼠标 x 计算相对位置 → 写原生 widget 值 + 反射绑定字段 + 触发 callback 与 CHANGE_EVENT */
	function sliderDrag(ctrl:CharacterCustomControl, mx:Float):Void
	{
		if (ctrl.track == null) return;
		var rel:Float = (mx - ctrl.track.x) / ctrl.track.width;
		rel = FlxMath.bound(rel, 0, 1);

		var w:Dynamic = ctrl.widget;
		if (w != null)
		{
			var minV:Float = 0;
			var maxV:Float = 1;
			try { minV = w.minValue; } catch (e:Dynamic) {}
			try { maxV = w.maxValue; } catch (e:Dynamic) {}
			var v:Float = minV + rel * (maxV - minV);
			// 写原生数据源
			try { w.value = v; } catch (e:Dynamic) {}
			// 反射写绑定字段（模拟原生 setVariable 行为）
			try
			{
				var obj:Dynamic = Reflect.field(w, '_object');
				var vs:String = Reflect.field(w, 'varString');
				if (obj != null && vs != null && vs.length > 0)
					Reflect.setProperty(obj, vs, v);
			}
			catch (e:Dynamic) {}
			// 手动触发 callback（参数是 relativePos，与原 FlxSlider.updateValue 一致）
			try { if (w.callback != null) w.callback(rel); } catch (e:Dynamic) {}
			// 广播 CHANGE_EVENT 给 state.getEvent
			try { FlxUI.event(FlxUISlider.CHANGE_EVENT, w, v, null); } catch (e:Dynamic) {}
		}
		// 更新自绘显示
		if (ctrl.fill != null)
		{
			ctrl.fill.x = ctrl.track.x;
			// ★ origin 已设为左上角（见 rebuildDropdown），scale.x 只向右拉伸，不会向两边扩
			ctrl.fill.scale.x = ctrl.track.width * rel;
		}
		if (ctrl.thumb != null)
			ctrl.thumb.x = ctrl.track.x + rel * ctrl.track.width - ctrl.thumb.width / 2;
		if (ctrl.text != null)
		{
			var v2:Float = 0;
			try { v2 = ctrl.widget.value; } catch (e:Dynamic) {}
			ctrl.text.text = Std.string(FlxMath.roundDecimal(v2, 2));
		}
	}

	/** 展开中的 dropdown 面板点击优先处理（面板选项行不在 dropRows 里）。返回 true 表示已消费。 */
	/**
	 * 按下时点在展开的 dropdown 面板上：只记录按下状态（可能是点击选择，也可能是拖拽开始）。
	 * 真正"选择选项"推迟到鼠标松开且未拖动时（见 update 里的 panelPressCtrl 处理），
	 * 这样按住拖动滚动不会误选。
	 * 返回 true 表示已消费（不处理下层行点击）。
	 */
	function handleDropdownPanelClick(mx:Float, my:Float):Bool
	{
		for (ctrl in customControls)
		{
			if (ctrl.ctype != 'dropdown' || ctrl.open != true) continue;
			if (ctrl.panelBg != null && pointInSprite(mx, my, ctrl.panelBg))
			{
				panelPressCtrl = ctrl;
				panelPressY = my;
				panelPressScroll = ctrl.scrollIdx;
				panelDragMoved = false;
				return true;
			}
		}
		return false;
	}

	/** 松开时（未拖动）执行面板点击：选项行 → 选中；空白 → 收起 */
	function releaseDropdownPanelClick():Void
	{
		if (panelPressCtrl == null) return;
		var ctrl:CharacterCustomControl = panelPressCtrl;
		panelPressCtrl = null;
		if (panelDragMoved) return; // 拖拽过 → 不当作点击

		var mx:Float = mViewX;
		var my:Float = mViewY;
		// 选项行点击 → 选中
		if (ctrl.panelRows != null)
		{
			for (pr in ctrl.panelRows)
			{
				if (pr.hit != null && pointInSprite(mx, my, pr.hit))
				{
					selectCharacterDropdownOption(ctrl, pr.idx);
					return;
				}
			}
		}
		// 面板内非选项区域（边框等）→ 收起
		if (ctrl.panelBg != null && pointInSprite(mx, my, ctrl.panelBg))
		{
			clearDropdownPanel(ctrl);
			ctrl.open = false;
		}
	}

	/** 选中 dropdown 的某个选项：直接调原生列表按钮的 onUp（内部会 selectSomething + callback + 广播事件） */
	function selectCharacterDropdownOption(ctrl:CharacterCustomControl, optIdx:Int):Void
	{
		var pickedLabel:String = '';
		try
		{
			var list:Array<Dynamic> = ctrl.widget.list;
			if (list != null && optIdx >= 0 && optIdx < list.length)
			{
				var b:Dynamic = list[optIdx];
				if (b != null)
				{
					if (b.onUp != null && b.onUp.callback != null)
					{
						b.onUp.callback();
						// ★ 兜底：不依赖 selectedLabel（反射读不出来），直接读按钮 label（public 链路）
						try { pickedLabel = b.label.text; } catch (e:Dynamic) {}
						if (pickedLabel == null || pickedLabel == '') pickedLabel = b.name;
						if (pickedLabel == null) pickedLabel = '';
					}
				}
			}
		}
		catch (e:Dynamic) {}
		clearDropdownPanel(ctrl);
		ctrl.open = false;
		updateDropdownDisplay(ctrl);
		refreshDynTexts();
		// 若原生头部也读不到，用按钮 label 兜底（同 menu，避免误写别的 key）
		if (ctrl.text != null && (ctrl.text.text == null || ctrl.text.text == ''))
		{
			if (pickedLabel != null && pickedLabel != '')
				setControlText(ctrl, pickedLabel);
		}
	}

	function renderCharacterDropdownOptions(ctrl:CharacterCustomControl):Void
	{
		if (ctrl.box == null) return;
		var opts:Array<String> = (ctrl.options != null) ? ctrl.options : [];
		var visCount:Int = Std.int(Math.min(opts.length, MAX_DROP_OPT));
		if (visCount < 1) return;

		var px:Float = ctrl.box.x;
		var py:Float = ctrl.box.y + ctrl.box.height + 1;
		var pw:Float = ctrl.box.width;

		var pBorder:FlxSprite = new FlxSprite().makeGraphic(Std.int(pw) + 2, visCount * DROP_OPT_H + 2, C_BORDER_STRONG);
		pBorder.x = Std.int(px) - 1;
		pBorder.y = Std.int(py) - 1;
		pBorder.antialiasing = ClientPrefs.data.antialiasing;
		addToDrop(pBorder, false);
		// ★ 边框也要登记进 ctrl，否则 clearDropdownPanel 只清行/背景，边框残留成"只剩背景"的僵尸
		ctrl.panelBorder = pBorder;

		var pBg:FlxSprite = new FlxSprite().makeGraphic(Std.int(pw), visCount * DROP_OPT_H, C_CARD_BG);
		pBg.x = Std.int(px);
		pBg.y = Std.int(py);
		pBg.antialiasing = ClientPrefs.data.antialiasing;
		addToDrop(pBg, false);

		ctrl.panelBg = pBg;
		ctrl.panelH = visCount * DROP_OPT_H;

		var rows:Array<CharacterDropdownOption> = [];
		// 当前选中文本（用于高亮当前项）：自绘头部显示的内容
		var curSelectedText:String = (ctrl.text != null) ? ctrl.text.text : '';
		for (i in 0...visCount)
		{
			var optIdx:Int = ctrl.scrollIdx + i;
			if (optIdx < 0 || optIdx >= opts.length) continue;
			var oy:Float = py + i * DROP_OPT_H;
			var isSelected:Bool = (curSelectedText != '' && opts[optIdx] == curSelectedText);

			// 行底色：hover 反馈用 hover 色（update 里切 visible）；当前选中项用选中底色（常显）
			var bg:FlxSprite = new FlxSprite().makeGraphic(Std.int(pw), DROP_OPT_H, isSelected ? C_SUB_SEL_BG : C_SUB_HOVER);
			bg.x = Std.int(px);
			bg.y = Std.int(oy);
			bg.visible = isSelected;
			bg.antialiasing = ClientPrefs.data.antialiasing;
			addToDrop(bg, false);

			var t:FlxText = new FlxText(0, 0, Std.int(pw) - 10, opts[optIdx], 11);
			t.setFormat(Paths.font(langFont()), 11, isSelected ? C_SUB_SEL_TEXT : C_TEXT_SEC, LEFT);
			fitTextOneLine(t);
			t.x = Std.int(px + 5);
			t.y = Std.int(oy + (DROP_OPT_H - t.height) / 2);
			addToDrop(t, false);

			var hit:FlxSprite = new FlxSprite().makeGraphic(Std.int(pw), DROP_OPT_H, FlxColor.TRANSPARENT);
			hit.x = Std.int(px);
			hit.y = Std.int(oy);
			addToDrop(hit, false);

			rows.push({bg: bg, txt: t, hit: hit, idx: optIdx, isSelected: isSelected});
		}
		ctrl.panelRows = rows;
	}

	function clearDropdownPanel(ctrl:CharacterCustomControl):Void
	{
		if (ctrl.panelRows != null)
		{
			for (pr in ctrl.panelRows)
			{
				removeFromDrop(pr.bg);
				removeFromDrop(pr.txt);
				removeFromDrop(pr.hit);
			}
			ctrl.panelRows = null;
		}
		if (ctrl.panelBg != null)
		{
			removeFromDrop(ctrl.panelBg);
			ctrl.panelBg = null;
		}
		if (ctrl.panelBorder != null)
		{
			removeFromDrop(ctrl.panelBorder);
			ctrl.panelBorder = null;
		}
	}

	function closeCustomDropdowns():Void
	{
		for (ctrl in customControls)
		{
			if (ctrl.ctype != 'dropdown' || ctrl.open != true) continue;
			clearDropdownPanel(ctrl);
			ctrl.open = false;
		}
	}

	function removeFromDrop(s:Dynamic):Void
	{
		if (s == null) return;
		try { dropGroup.remove(s, false); } catch (e:Dynamic) {}
		FlxDestroyUtil.destroy(s);
		var i:Int = dropGroupMembers.length - 1;
		while (i >= 0)
		{
			if (dropGroupMembers[i].sprite == s)
			{
				dropGroupMembers.splice(i, 1);
				break;
			}
			i--;
		}
	}

	// ============ 自绘控件：数值 / 输入覆盖层 ============
	function stepperPlus(ctrl:CharacterCustomControl):Void
	{
		stepperStep(ctrl, 1);
	}

	function stepperMinus(ctrl:CharacterCustomControl):Void
	{
		stepperStep(ctrl, -1);
	}

	function stepperStep(ctrl:CharacterCustomControl, dir:Int):Void
	{
		var w:Dynamic = ctrl.widget;
		if (w == null) return;
		try
		{
			var step:Float = 1;
			try { step = w.stepSize; } catch (e:Dynamic) {}
			// ★ 按住 Shift 微调：
			//   位置/相机 stepper（w_pos_x 等，stepSize=5）→ ±1；
			//   其他 stepper → 步进减半（0.1 → 0.05 等精细微调）
			if (FlxG.keys.pressed.SHIFT)
			{
				if (ctrl.key == 'w_pos_x' || ctrl.key == 'w_pos_y' || ctrl.key == 'w_cam_x' || ctrl.key == 'w_cam_y')
					step = 1;
				else
					step = step / 2;
			}
			w.value = w.value + step * dir; // setter 自动 clamp min/max 并更新文本
			// 原生 set_value 只改文本不广播事件，手动补一发 CHANGE_EVENT 让 CharacterEditorState 更新数据
			try { FlxUI.event(FlxUINumericStepper.CHANGE_EVENT, w, w.value, w.params); } catch (e:Dynamic) {}
		}
		catch (e:Dynamic) {}
		updateStepperDisplay(ctrl);
	}

	// ============ 覆盖层背景撑宽 ============
	/** 覆盖层背景/边框 sprite 撑满自绘 box。
	 *  OpenFL TextField.get_width() 返回文本内容宽度（不是布局宽度），
	 *  FlxText 的背景/边框 sprite 按它生成 → 短文本时覆盖层比 box 短一截。
	 *  这里反射拿到背景/边框 sprite 手动撑宽。
	 *  ★ 缩放前必须把 origin 设为左上角：FlxSprite 的 origin 默认在中心（updateHitbox 设置），
	 *    setGraphicSize 围绕中心缩放会向两边扩展 → 背景左边超出 box（看起来"向左移动"） */
	function stretchOverlayBackground(w:Dynamic, boxW:Float):Void
	{
		if (w == null) return;
		try
		{
			var bs:Dynamic = Reflect.field(w, 'backgroundSprite');
			if (bs != null && bs.visible)
			{
				bs.origin.set(0, 0); // 缩放围绕左上角，只向右延伸
				var targetW:Int = Std.int(boxW - 4);
				if (Std.int(bs.width) != targetW)
					bs.setGraphicSize(targetW, Std.int(bs.height));
			}
		}
		catch (e:Dynamic) {}
		try
		{
			var fs:Dynamic = Reflect.field(w, 'fieldBorderSprite');
			if (fs != null && fs.visible)
			{
				fs.origin.set(0, 0); // 同上，只向右延伸
				var targetW:Int = Std.int(boxW - 2);
				if (Std.int(fs.width) != targetW)
					fs.setGraphicSize(targetW, Std.int(fs.height));
			}
		}
		catch (e:Dynamic) {}
	}

	/** 点击 input 自绘区域 → 弹出原生输入覆盖层（定位到自绘 box 区域并聚焦） */
	function openInputOverlay(ctrl:CharacterCustomControl):Void
	{
		var w:Dynamic = ctrl.widget;
		clearActiveEditWidget();
		if (stepperOverlayCtrl != null)
			commitStepperOverlay();
		if (w == null || ctrl.box == null) return;
		// 保存原位置/显隐（供 clearActiveEditWidget 还原）
		try { activeEditPrevX = w.x; } catch (e:Dynamic) {}
		try { activeEditPrevY = w.y; } catch (e:Dynamic) {}
		try { activeEditPrevVisible = w.visible; } catch (e:Dynamic) {}
		// 定位到自绘控件区域并显示
		try { w.x = ctrl.box.x; } catch (e:Dynamic) {}
		try { w.y = ctrl.box.y; } catch (e:Dynamic) {}
		try { w.visible = true; } catch (e:Dynamic) {}
		// ★ 统一灰底白字外观（文字白 / 背景灰 / 边框浅灰 / 字号 12）+ 强制重建纹理
		EditorInputStyle.apply(w);
		// ★ 强制重建 graphic：widget 平时隐藏，graphic 可能已被内存清理（frame EMPTY 时
		//   FlxInputText.draw 会直接 return → 覆盖层完全不可见）。
		//   drawFrame(true) 强制 _regen=true 并重建纹理
		try { Reflect.setField(w, '_regen', true); } catch (e:Dynamic) {}
		try { w.drawFrame(true); } catch (e:Dynamic) {}
		// ★ 覆盖层字号调大（8 → 12）+ 宽度撑满自绘 box：
		//   set_fieldWidth 会设置 textField.width（布局宽度），regen 背景按它生成，
		//   输入时 textField.width 保持不变，宽度稳定（不会缩回文本宽度）
		try { w.size = 12; } catch (e:Dynamic) {}
		try { w.fieldWidth = ctrl.box.width - 6; } catch (e:Dynamic) {}
		// ★ fieldWidth 设置后强制 regen：set_fieldWidth 只改 textField.width 不重建背景，
		//   不强制 regen 的话背景还是旧宽度（文本宽/创建宽）→ 各输入框长短不一
		try { Reflect.setField(w, '_regen', true); } catch (e:Dynamic) {}
		try { w.drawFrame(true); } catch (e:Dynamic) {}
		// ★ 背景/边框 sprite 手动撑满 box：OpenFL TextField.get_width 返回文本内容宽度
		//   （不是布局宽度），FlxText 背景永远跟随文本 → 短文本时覆盖层比 box 短一截
		stretchOverlayBackground(w, ctrl.box.width);
		// ★ 必须保持 active=false：FlxInputText.update() 每次鼠标点击都会用 overlaps(this)
		//   判定焦点，而原生覆盖层比自绘 box 矮，点击 box 下半区就会被判成"点在框外"把 hasFocus 秒清。
		//   键盘输入走 stage 级 KEY_DOWN 监听，不依赖 update()，所以不跑 update 完全没问题。
		try { w.active = false; } catch (e:Dynamic) {}
		// ★ 提升绘制层级：移到 overlayLayer 末尾（顶层容器内最上，渲染在菜单之上）
		try { if (overlayLayer != null) { overlayLayer.remove(w, true); overlayLayer.add(w); } } catch (e:Dynamic) {}
		activeEditWidget = w;
		// ★ FlxInputText 没有 startFocus() 方法（编译过但运行时空调用被 try 吞掉 → 点了没反应）。
		//   hasFocus 的 setter 是 private，用 Dynamic 赋值绕过可见性检查直接聚焦。
		try { EditorInputStyle.setInputFocus(w, true); } catch (e:Dynamic) {}
		// 兜底：确保 caret 可见（caret 是私有 FlxSprite，反射拿过来点亮）
		try
		{
			var caretSprite:Dynamic = Reflect.field(w, 'caret');
			if (caretSprite != null) caretSprite.visible = true;
		}
		catch (e:Dynamic) {}
	}

	// ============ 清理临时弹出编辑的原生 widget ============
	function clearActiveEditWidget():Void
	{
		if (activeEditWidget != null)
		{
			// 失焦前把原生输入框的最终文本同步回自绘显示
			for (ctrl in customControls)
			{
				if (ctrl.ctype == 'input' && ctrl.widget == activeEditWidget)
					updateInputDisplay(ctrl);
			}
			try
			{
				activeEditWidget.x = activeEditPrevX;
				activeEditWidget.y = activeEditPrevY;
				activeEditWidget.visible = activeEditPrevVisible;
				activeEditWidget.active = false;
			}
			catch (e:Dynamic) {}
			// 与 openInputOverlay 对称：FlxInputText 无 endFocus()，直接清 hasFocus
			try { EditorInputStyle.setInputFocus(activeEditWidget, false); } catch (e:Dynamic) {}
			activeEditWidget = null;
		}
	}

	/** 检查点 (mx, my) 是否落在 widget 的包围盒内（用于让点击穿透到 widget，不被 menuBar 的关闭逻辑吃掉） */
	function pointInWidget(mx:Float, my:Float, w:Dynamic):Bool
	{
		if (w == null) return false;
		try
		{
			var wx:Float = w.x;
			var wy:Float = w.y;
			var ww:Float = w.width;
			var wh:Float = w.height;
			return mx >= wx && mx <= wx + ww && my >= wy && my <= wy + wh;
		}
		catch (e:Dynamic) {}
		return false;
	}

	/** 检查点是否落在"正在编辑的覆盖层"区域：
	 *  优先用自绘 box 判定（FlxUIInputText 的 width 是文本渲染宽度，点击文本区外的空白会误判为"框外"导致覆盖层被收回） */
	function isOverActiveEditWidget(mx:Float, my:Float):Bool
	{
		if (activeEditWidget == null) return false;
		for (ctrl in customControls)
		{
			if (ctrl.ctype == 'input' && ctrl.widget == activeEditWidget)
				return (ctrl.box != null && pointInSprite(mx, my, ctrl.box));
		}
		return pointInWidget(mx, my, activeEditWidget);
	}

	/**
	 * 检查屏幕坐标 (mx, my) 是否落在 menuBar 任何 UI 元素上：
	 * 顶栏 / 下拉浮窗 / 描述条 / 临时弹出 widget / 嵌入的 LabelWidget 控件。
	 * CharacterEditorState.update 开头用这个判断点击是否在"列表内"，不在就强制 closeMenu。
	 */
	public function isMouseInsideUI(mx:Float, my:Float):Bool
	{
		// 1. 顶栏区域（整条 BAR_HEIGHT 高度）
		if (my >= 0 && my < BAR_HEIGHT) return true;

		// 2. 下拉浮窗区域（包括 border）
		if (dropGroup != null && dropGroup.visible && dropBg != null)
		{
			if (mx >= dropBorder.x && mx <= dropBorder.x + dropBorder.width
				&& my >= dropBorder.y && my <= dropBorder.y + dropBorder.height)
				return true;

			// 3. 描述条（紧贴下拉底部）
			if (descBg != null && descBg.visible)
			{
				if (mx >= descBg.x && mx <= descBg.x + descBg.width
					&& my >= descBg.y && my <= descBg.y + descBg.height)
					return true;
			}
		}

		// 4. 临时弹出的编辑 widget
		if (isOverActiveEditWidget(mx, my))
			return true;

		// 6. LabelWidget 行嵌入的自绘控件区域（DropDownMenu 展开列表可能超出 dropBg 范围）
		// ★ 必须用自绘 box 判定：原生控件的 x/y 是创建时的旧布局坐标（不在屏幕上），
		//   用它判定会导致点击输入框行被误判为"菜单外"→ 菜单被关闭
		for (ctrl in customControls)
		{
			if (ctrl.box != null && pointInSprite(mx, my, ctrl.box))
				return true;
		}

		// 7. 自绘 dropdown 展开的选项面板（超出 dropBg 范围）
		for (ctrl in customControls)
		{
			if (ctrl.ctype != 'dropdown' || ctrl.open != true) continue;
			if (ctrl.panelBg != null && pointInSprite(mx, my, ctrl.panelBg))
				return true;
		}

		return false;
	}

	// ============ 打开 / 关闭菜单 ============
	public function openMenu(idx:Int):Void
	{
		// 切换菜单时，先把上一个菜单弹出的编辑 widget / stepper 覆盖层收回去
		clearActiveEditWidget();
		if (stepperOverlayCtrl != null)
			commitStepperOverlay();
		panelPressCtrl = null;
		panelDragMoved = false;
		activeMenu = idx;

		var menuKey = menus[idx].key;

		// ★ 初始化顺序（重要）：必须先让外部把 widget 的数据刷新到位（读取），
		//   再 rebuildDropdown 渲染（渲染时读到的才是最新值）。
		if (onMenuOpened != null)
			onMenuOpened(menuKey);

		// ★ 必须先置可见、再渲染：FlxSpriteGroup.set_visible 在 visible 从 false→true 时
		//   会把 dropGroup 的所有子成员 visible 级联改成 true。
		//   若在渲染之后才设 visible=true，刚按 isChecked 设好的 checkTxt.visible 会被
		//   全部覆盖成 true → 菜单一打开所有勾选框都显示 √。
		//   （hover 切换菜单时 visible 已是 true 不触发级联，所以滑走再滑回反而正常）
		dropGroup.visible = true;

		rebuildDropdown();

		// ★ onMenuOpened 会刷新原生 widget 的值，自绘显示要跟着同步
		refreshCharacterCustomControlDisplays();
	}

	public function closeMenu():Void
	{
		clearActiveEditWidget();
		if (stepperOverlayCtrl != null)
			commitStepperOverlay();
		panelPressCtrl = null;
		panelDragMoved = false;
		activeMenu = -1;
		lastHoverSwitchIdx = -1;
		dropGroup.visible = false;
		clearCharacterDropdownRows();
		hideDescBar();
	}

	// ============ 重建下拉浮窗内容 ============
	function rebuildDropdown():Void
	{
		clearCharacterDropdownRows();

		if (activeMenu < 0 || activeMenu >= menus.length) return;
		var m = menus[activeMenu];
		var items = m.items;

		// 第一遍：计算总高度和最大宽度
		var dropW:Int = DROP_MIN_W;
		var totalH = 8;
		for (it in items)
		{
			if (it.type == Sep)
			{
				totalH += 9;
				continue;
			}
			if (it.type == Widget || it.type == LabelWidget)
			{
				var wKey = it.type == LabelWidget ? it.widgetKey : it.labelKey;
				var w = widgetRefs.get(wKey);
				var wh = (w != null) ? Std.int(w.height) : ROW_H;
				if (wh < ROW_H) wh = ROW_H;
				wh += 4;
				totalH += wh;
				if (w != null)
				{
					var ww = Std.int(w.width);
					// NumericStepper 右侧横向两个 +/- 按钮额外占空间
					if (Std.is(w, FlxUINumericStepper)) ww += 42;
					// LabelWidget：标签 120 + 6 间距 + widget.width + 10 两侧边距
					var neededW = (it.type == LabelWidget) ? (120 + 6 + ww + 20) : (ww + 40);
					if (neededW > dropW) dropW = neededW;
					if (dropW > DROP_MAX_W) dropW = DROP_MAX_W;
				}
				if (it.type == LabelWidget)
				{
					// 标签最小宽度
					var lbl = Language.get(it.labelKey, 'character');
					var approxW = lbl.length * 8 + 140;
					if (approxW > dropW) dropW = approxW;
					if (dropW > DROP_MAX_W) dropW = DROP_MAX_W;
				}
			}
			else if (it.type == TextLine)
			{
				var txt = Language.get('item_' + it.labelKey, 'character');
				var lineH = 16;
				// 估算文本行数
				var charW = 7;
				var approxLines = Math.ceil((txt.length * charW) / (DROP_MAX_W - ROW_PAD_X * 2));
				if (approxLines < 1) approxLines = 1;
				if (approxLines > 3) approxLines = 3; // 最多3行
				totalH += approxLines * lineH + 2;
				var approxW = txt.length * charW + 20;
				if (approxW > dropW) dropW = approxW;
				if (dropW > DROP_MAX_W) dropW = DROP_MAX_W;
			}
			else if (it.type == DynText)
			{
				// 动态文本行：内容由 provider 决定，预留 4 行高度
				totalH += 4 * 14 + 4;
				if (dropW < 380) dropW = 380;
				if (dropW > DROP_MAX_W) dropW = DROP_MAX_W;
			}
			else
			{
				var lbl = Language.get('item_' + it.labelKey, 'character');
				var approxW = lbl.length * 8 + 60;
				if (approxW > dropW) dropW = approxW;
				if (dropW > DROP_MAX_W) dropW = DROP_MAX_W;
				totalH += ROW_H;
			}
		}
		totalH += 4;

		// 位置：在状态栏下方
		var dropX = Std.int(activeMenu * MENU_W);
		var dropY = Std.int(BAR_HEIGHT + STATUS_HEIGHT + 2);

		// ★ 不在第一遍创建背景/边框 —— 因为第一遍估算的高度可能不准
		//   改为在第二遍构建完成后用实际高度创建

		// 第二遍：实际渲染行
		var curY = dropY + 4;
		for (it in items)
		{
			if (it.type == Sep)
			{
				var sepLine = new FlxSprite(Std.int(dropX + 6), Std.int(curY + 3)).makeGraphic(Std.int(dropW - 12), 2, C_BORDER_STRONG);
				sepLine.antialiasing = ClientPrefs.data.antialiasing;
				addToDrop(sepLine, false);
				curY += 9;
				continue;
			}

			if (it.type == Widget || it.type == LabelWidget)
			{
				var wKey = it.type == LabelWidget ? it.widgetKey : it.labelKey;
				var widget:Dynamic = widgetRefs.get(wKey);
				// ★ 构建期统一灰底白字（直改 _defaultFormat.color，WeekEditor 验证过的可靠路径）
				if (widget != null && it.type == LabelWidget)
					EditorInputStyle.apply(widget);
				var rowH:Int = ROW_H;

				// ===== 计算行高 & 行需要的 widget 占位宽度 =====
				var widgetW:Int = 0;
				if (widget != null)
				{
					try
					{
						widgetW = Std.int(widget.width);
						// 放一点额外边距防止贴得太近
						rowH = Std.int(Math.max(ROW_H, Std.int(widget.height) + 4));
						// NumericStepper 右侧横向两个 +/- 按钮额外占空间
						if (Std.is(widget, FlxUINumericStepper)) widgetW += 42;
					}
					catch (e:Dynamic) {}
				}

				// ===== hover 背景（先加） =====
				var hoverBg:FlxSprite = new FlxSprite().makeGraphic(Std.int(dropW - 4), rowH, C_SUB_HOVER);
				hoverBg.visible = false;
				hoverBg.x = Std.int(dropX + 2);
				hoverBg.y = Std.int(curY);
				hoverBg.antialiasing = ClientPrefs.data.antialiasing;
				addToDrop(hoverBg, false);

				if (it.type == Widget)
				{
					// ===== Widget = CheckBox 行：干净标签（左） + 装饰性勾选框（右） =====
					// 原生 checkbox 只作数据源，隐藏 + 禁用（否则旧布局位置还残留一个克隆控件）
					try { widget.visible = false; } catch (e:Dynamic) {}
					try { widget.active = false; } catch (e:Dynamic) {}
					var labelForDisplay = translateItemKey(it.labelKey);
					var isChecked = false;
					try { if (widget != null) isChecked = widget.checked; } catch(e:Dynamic) {}

					// 标签（左）—— 纯文本，勾选状态只由右侧勾选框表达
					var lbl = new FlxText(0, 0, Std.int(dropW - 50), labelForDisplay, 12);
					lbl.setFormat(Paths.font(langFont()), 12, C_TEXT_SEC, LEFT);
					lbl.x = Std.int(dropX + ROW_PAD_X);
					lbl.y = Std.int(curY + (rowH - lbl.height) / 2);
					addToDrop(lbl, false);

					// 装饰性勾选方块（右）—— toggle 时通过 row.checkIcon 更新颜色
					var checkIcon:FlxSprite = new FlxSprite().makeGraphic(14, 14, C_FIELD_BG);
					checkIcon.antialiasing = ClientPrefs.data.antialiasing;
					checkIcon.color = isChecked ? C_MENU_ACCENT : C_FIELD_BG;
					checkIcon.x = Std.int(dropX + dropW - 18 - ROW_PAD_X);
					checkIcon.y = Std.int(curY + (rowH - 14) / 2);
					addToDrop(checkIcon, false);

					// 勾选标记 √（始终创建；★ 文本内容 + visible 双保险控制：
					//   即使 visible 被 FlxSpriteGroup 级联误改成 true，空文本也不会画出 √）
					var checkTxt = new FlxText(0, 0, 14, isChecked ? '√' : '', 11);
					checkTxt.setFormat(Paths.font(langFont()), 11, FlxColor.WHITE, CENTER);
					checkTxt.x = checkIcon.x;
					checkTxt.y = checkIcon.y - 1;
					checkTxt.visible = isChecked;
					addToDrop(checkTxt, false);

					// 整行 hitbox（最上层，透明）
					var hit = new FlxSprite().makeGraphic(Std.int(dropW - 4), rowH, FlxColor.TRANSPARENT);
					hit.x = Std.int(dropX + 2);
					hit.y = Std.int(curY);
					addToDrop(hit, false);

					dropRows.push({
						type: it.type,
						labelKey: it.labelKey,
						descKey: it.descKey,
						def: it,
						hit: hit,
						checkIcon: checkIcon,
						checkTxt: checkTxt,
						label: lbl,
						hoverBg: hoverBg,
						widget: widget
					});
				}
				else // LabelWidget
				{
					// ===== LabelWidget 行：标签（左） + 自绘控件（右） =====
					// ★ 原生 FlxUI 控件只当数据源，绝不渲染。
					//   我们直接用 FlxSprite/FlxText 画控件外观，点击也自己判。
					var labelForDisplay = translateLabelKey(it.labelKey);

					// 标签（左，固定宽度 120）
					var lbl = new FlxText(0, 0, 120, labelForDisplay + ':', 12);
					lbl.setFormat(Paths.font(langFont()), 12, C_TEXT_HINT, LEFT);
					lbl.x = Std.int(dropX + ROW_PAD_X);
					lbl.y = Std.int(curY + (rowH - lbl.height) / 2);
					addToDrop(lbl, false);

					var ctrl:CharacterCustomControl = null;
					if (widget != null)
					{
						var ctrlX:Int = Std.int(dropX + ROW_PAD_X + 120 + 6);
						var ctrlY:Int = Std.int(curY + 2);
						var ctrlH:Int = Std.int(Math.max(ROW_H - 4, 18));
						var ctrlW:Int = Std.int(dropX + dropW - ROW_PAD_X - ctrlX);
						if (ctrlW < 40) ctrlW = 40;

						// 底板 + 1px 边框
						var border:FlxSprite = new FlxSprite().makeGraphic(ctrlW, ctrlH, C_BORDER_STRONG);
						border.x = ctrlX;
						border.y = ctrlY;
						border.antialiasing = ClientPrefs.data.antialiasing;
						addToDrop(border, false);

						var box:FlxSprite = new FlxSprite().makeGraphic(ctrlW - 2, ctrlH - 2, C_FIELD_BG);
						box.x = ctrlX + 1;
						box.y = ctrlY + 1;
						box.antialiasing = ClientPrefs.data.antialiasing;
						addToDrop(box, false);

						var txt:FlxText = new FlxText(ctrlX + 6, 0, ctrlW - 26, '', 12);
						txt.setFormat(Paths.font(langFont()), 12, C_TEXT_SEC, LEFT);
						txt.wordWrap = false; // 强制单行，防止长文本换行把 y 对齐撑乱
						txt.y = Std.int(ctrlY + (ctrlH - txt.height) / 2);
						addToDrop(txt, false);

						if (Std.is(widget, FlxUINumericStepper))
						{
							// ---- 数字步进器：右侧横向 [-] [+]（照顾移动端，竖排俩按钮太挤）----
							var btnW:Int = 14;
							var btnGap:Int = 3;
							var btnH:Int = Std.int(ctrlH - 2);
							var btnPlusX:Int = ctrlX + ctrlW - btnW - 2;
							var btnMinusX:Int = btnPlusX - btnGap - btnW;

							// 文本宽度让出两个按钮 + 间距
							txt.fieldWidth = Std.int(ctrlW - (btnW * 2 + btnGap) - 12);

							// ★ 步进按钮：主按钮渐变，竖直方向（与 ChartEditor 一致）
							var btnPlus:FlxSprite = makeGradSprite(btnW, btnH, C_PRIMARY_A, C_PRIMARY_B, false);
							btnPlus.x = btnPlusX;
							btnPlus.y = ctrlY + 1;
							btnPlus.antialiasing = ClientPrefs.data.antialiasing;
							addToDrop(btnPlus, false);
							var plusTxt = new FlxText(0, 0, btnW, '+', 12);
							plusTxt.setFormat(Paths.font(langFont()), 12, FlxColor.WHITE, CENTER);
							plusTxt.x = btnPlusX;
							plusTxt.y = btnPlus.y + (btnH - plusTxt.height) / 2 - 1;
							addToDrop(plusTxt, false);

							var btnMinus:FlxSprite = makeGradSprite(btnW, btnH, C_PRIMARY_A, C_PRIMARY_B, false);
							btnMinus.x = btnMinusX;
							btnMinus.y = ctrlY + 1;
							btnMinus.antialiasing = ClientPrefs.data.antialiasing;
							addToDrop(btnMinus, false);
							var minusTxt = new FlxText(0, 0, btnW, '-', 12);
							minusTxt.setFormat(Paths.font(langFont()), 12, FlxColor.WHITE, CENTER);
							minusTxt.x = btnMinusX;
							minusTxt.y = btnMinus.y + (btnH - minusTxt.height) / 2 - 1;
							addToDrop(minusTxt, false);

							ctrl = {key: wKey, ctype: 'stepper', widget: widget, box: box, text: txt, row: null,
								btnMinus: btnMinus, btnPlus: btnPlus};
							updateStepperDisplay(ctrl);
						}
						else if (Std.is(widget, FlxUIDropDownMenu))
						{
							// ---- 下拉列表：右侧 ▼ 箭头 ----
							var arrow:FlxText = new FlxText(0, 0, 18, '▼', 10);
							arrow.setFormat(Paths.font(langFont()), 10, C_TEXT_HINT, CENTER);
							arrow.x = ctrlX + ctrlW - 18;
							arrow.y = Std.int(ctrlY + (ctrlH - arrow.height) / 2);
							addToDrop(arrow, false);

							ctrl = {key: wKey, ctype: 'dropdown', widget: widget, box: box, text: txt, row: null,
								arrow: arrow, open: false, options: [], scrollIdx: 0, panelBg: null, panelRows: null, panelH: 0};
							updateDropdownDisplay(ctrl);
						}
						else if (Std.is(widget, FlxUIInputText))
						{
							// ---- 输入框：自绘显示，点击时弹出原生输入覆盖层 ----
							ctrl = {key: wKey, ctype: 'input', widget: widget, box: box, text: txt, row: null};
							updateInputDisplay(ctrl);
						}
						else if (Std.is(widget, FlxUISlider))
						{
							// ---- 滑块：自绘 track + fill + thumb，拖拽交互 ----
							var trackH:Int = 4;
							var trackX:Int = ctrlX + 6;
							var trackY:Int = Std.int(ctrlY + (ctrlH - trackH) / 2);
							var trackW:Int = ctrlW - 52; // 右侧留数值文本
							if (trackW < 40) trackW = 40;

							var track:FlxSprite = new FlxSprite().makeGraphic(trackW, trackH, C_BORDER_STRONG);
							track.x = trackX;
							track.y = trackY;
							track.antialiasing = ClientPrefs.data.antialiasing;
							addToDrop(track, false);

							// fill 用 1px 宽纯色 + scale.x 拉伸（纯色无失真）
							// ★ origin 必须设为左上角：FlxSprite 缩放默认绕中心，1px 宽放大时会向两边扩
							//   （"=] -> [===]"）；origin=(0,0) 后只从 track 起点向右填充（"=] -> ===]"）
							var fill:FlxSprite = new FlxSprite().makeGraphic(1, trackH, C_MENU_ACCENT);
							fill.origin.set(0, 0);
							fill.x = trackX;
							fill.y = trackY;
							fill.antialiasing = ClientPrefs.data.antialiasing;
							addToDrop(fill, false);

							var thumb:FlxSprite = new FlxSprite().makeGraphic(8, ctrlH - 2, C_MENU_SEL_TEXT);
							thumb.x = trackX;
							thumb.y = ctrlY + 1;
							thumb.antialiasing = ClientPrefs.data.antialiasing;
							addToDrop(thumb, false);

							// 数值文本（track 右侧）
							txt.x = ctrlX + trackW + 14;
							txt.y = Std.int(ctrlY + (ctrlH - txt.height) / 2);
							txt.fieldWidth = 38;

							ctrl = {key: wKey, ctype: 'slider', widget: widget, box: box, text: txt, row: null,
								track: track, fill: fill, thumb: thumb, dragging: false};
							updateSliderDisplay(ctrl);
						}
						else
						{
							txt.text = '(?)';
						}

						// 原生控件本体只作数据源，永远隐藏（active=false 防止隐藏时还抢鼠标/键盘事件）
						try { widget.visible = false; } catch (e:Dynamic) {}
						try { widget.active = false; } catch (e:Dynamic) {}
					}

					// hitbox：覆盖整行（自绘控件点击在 handleCharacterCustomControlClick 里先消费）
					var hit = new FlxSprite().makeGraphic(Std.int(dropW - ROW_PAD_X * 2 + 2), rowH, FlxColor.TRANSPARENT);
					hit.x = Std.int(dropX + ROW_PAD_X - 2);
					hit.y = Std.int(curY);
					addToDrop(hit, false);

					var row:CharacterDropdownRow = {
						type: it.type,
						labelKey: it.labelKey,
						descKey: it.descKey,
						def: it,
						hit: hit,
						checkIcon: null,
						label: lbl,
						hoverBg: hoverBg,
						widget: widget
					};
					dropRows.push(row);
					if (ctrl != null)
					{
						ctrl.row = row;
						customControls.push(ctrl);
					}
				}

				curY += rowH;
				continue;
			}

			if (it.type == TextLine)
			{
				var txt = Language.get('item_' + it.labelKey, 'character');
				var isHeader = (it.labelKey == 'help_camera' || it.labelKey == 'help_char' || it.labelKey == 'help_other');

				// 文本行（帮助菜单用）
				var txtLabel = new FlxText(0, 0, Std.int(dropW - ROW_PAD_X * 2), txt, isHeader ? 12 : 11);
				txtLabel.setFormat(Paths.font(langFont()), isHeader ? 12 : 11, isHeader ? C_MENU_SEL_TEXT : C_TEXT_HINT, LEFT);
				if (isHeader) txtLabel.bold = true;
				txtLabel.alignment = LEFT;
				txtLabel.x = Std.int(dropX + ROW_PAD_X);
				txtLabel.y = Std.int(curY);
				addToDrop(txtLabel, false);

				var lineH = isHeader ? 18 : 16;
				// 估算实际行数
				var charW = isHeader ? 7 : 6.5;
				var approxLines = Math.ceil((txt.length * charW) / (dropW - ROW_PAD_X * 2));
				if (approxLines < 1) approxLines = 1;
				if (approxLines > 3) approxLines = 3;
				var totalLineH = approxLines * lineH;

				dropRows.push({
					type: TextLine,
					labelKey: it.labelKey,
					descKey: it.descKey,
					def: it,
					hit: null,
					checkIcon: null,
					label: null,
					hoverBg: null
				});
				curY += totalLineH + 2;
				continue;
			}

			if (it.type == DynText)
			{
				// 动态文本行：内容由外部 provider 提供，固定占 4 行
				var txtLabel = new FlxText(0, 0, Std.int(dropW - ROW_PAD_X * 2), ' ', 11);
				txtLabel.setFormat(Paths.font(langFont()), 11, C_TEXT_SEC, LEFT);
				txtLabel.alignment = LEFT;
				txtLabel.wordWrap = true;
				txtLabel.x = Std.int(dropX + ROW_PAD_X);
				txtLabel.y = Std.int(curY);
				addToDrop(txtLabel, false);
				dynTexts.set(it.labelKey, txtLabel);

				// 用当前内容初始化显示
				if (dynTextProviders.exists(it.labelKey) && dynTextProviders.get(it.labelKey) != null)
				{
					try
					{
						var firstText:String = dynTextProviders.get(it.labelKey)();
						if (firstText != null) txtLabel.text = firstText;
					}
					catch (e:Dynamic) {}
				}

				dropRows.push({
					type: DynText,
					labelKey: it.labelKey,
					descKey: it.descKey,
					def: it,
					hit: null,
					checkIcon: null,
					label: txtLabel,
					hoverBg: null
				});
				curY += 4 * 14 + 4;
				continue;
			}

			// === Cmd 行 ===
			var labelStr = Language.get('item_' + it.labelKey, 'character');
			var isDanger = (it.labelKey == 'anim_remove');
			var isPrimary = (it.labelKey == 'save'); // 保存角色 = 主按钮风格（渐变）

			// 背景层：主按钮行常显渐变（indigo→violet，左→右，与 ChartEditor 一致）；普通/危险行无常态背景
			if (isPrimary)
			{
				var gradBg:FlxSprite = makeGradSprite(Std.int(dropW) - 4, ROW_H, C_PRIMARY_A, C_PRIMARY_B, true);
				gradBg.x = Std.int(dropX + 2);
				gradBg.y = Std.int(curY);
				gradBg.antialiasing = ClientPrefs.data.antialiasing;
				addToDrop(gradBg, false);
			}
			// hover 反馈层：主按钮 → 白色提亮；危险 → 红色半透明；普通 → 子菜单 hover 紫
			var hoverBg:FlxSprite = new FlxSprite(Std.int(dropX + 2), Std.int(curY));
			if (isPrimary)
				hoverBg.makeGraphic(Std.int(dropW) - 4, ROW_H, C_HOVER_LIFT);
			else if (isDanger)
				hoverBg.makeGraphic(Std.int(dropW) - 4, ROW_H, 0x1AEF4444);
			else
				hoverBg.makeGraphic(Std.int(dropW) - 4, ROW_H, C_SUB_HOVER);
			hoverBg.antialiasing = ClientPrefs.data.antialiasing;
			hoverBg.visible = false;
			addToDrop(hoverBg, false);

			// 标签（后加，渲染在 hoverBg 之上）
			var lbl = new FlxText(0, 0, Std.int(dropW - ROW_PAD_X * 2 - 20), labelStr, 12);
			lbl.setFormat(Paths.font(langFont()), 12, isPrimary ? FlxColor.WHITE : (isDanger ? C_DANGER : C_TEXT_SEC), LEFT);
			lbl.x = Std.int(dropX + ROW_PAD_X);
			lbl.y = Std.int(curY + 3);
			addToDrop(lbl, false);

			// hitbox（最上层但透明）
			var hit = new FlxSprite().makeGraphic(Std.int(dropW) - 4, ROW_H, FlxColor.TRANSPARENT);
			hit.x = Std.int(dropX + 2);
			hit.y = Std.int(curY);
			addToDrop(hit, false);

			dropRows.push({
				type: Cmd,
				labelKey: it.labelKey,
				descKey: it.descKey,
				def: it,
				hit: hit,
				checkIcon: null,
				label: lbl,
				hoverBg: hoverBg
			});
			curY += ROW_H;
		}

		// ★ 第二遍构建完成后，用实际高度创建背景和边框
		var finalH = Std.int(curY - dropY + 2);
		dropBg.makeGraphic(Std.int(dropW), finalH, C_CARD_BG);
		dropBg.antialiasing = ClientPrefs.data.antialiasing;
		dropBg.x = dropX;
		dropBg.y = dropY;
		dropBorder.makeGraphic(Std.int(dropW) + 2, finalH + 2, C_BORDER_STRONG);
		dropBorder.antialiasing = ClientPrefs.data.antialiasing;
		dropBorder.x = dropX - 1;
		dropBorder.y = dropY - 1;
	}

	function refreshCheckIcon(icon:FlxText, it:CharacterMenuItemDef):Void
	{
		if (it.getChecked == null) return;
		icon.text = it.getChecked() ? '√' : '';
	}

	/** 把 widget 定位到视图坐标 (vx, vy)。scrollFactor 已在创建时归零。 */
	function positionWidget(widget:Dynamic, vx:Float, vy:Float):Void
	{
		if (widget == null) return;
		try { widget.x = vx; } catch(e:Dynamic) {}
		try { widget.y = vy; } catch(e:Dynamic) {}
		try { widget.visible = true; } catch(e:Dynamic) {}
	}

	/** 把一个 sprite/widget 加进 dropGroup 并登记，cleanup 时会自动处理。
	 *  @param  s      要加入的 sprite 或 widget
	 *  @param  keepAlive 若 true，cleanup 时只从 dropGroup 移除但不 destroy（用于 widget）
	 */
	function addToDrop(s:Dynamic, ?keepAlive:Bool):Void
	{
		dropGroup.add(s);
		var k = keepAlive != null ? keepAlive : false;
		dropGroupMembers.push({sprite: s, keepAlive: k});
	}

	function clearCharacterDropdownRows():Void
	{
		// ★ 隐藏独立跟踪的 FlxUI 控件（不折腾 parent）
		for (w in activeLabelWidgets)
		{
			if (w == null) continue;
			try { w.visible = false; } catch(e) {}
		}
		activeLabelWidgets = [];

		// 安全清理：先收集所有 keepAlive widget，隐藏它们
		// 然后用 dropGroup.clear() 整体清理（避免逐个 remove 对已销毁对象操作导致崩溃）
		for (m in dropGroupMembers)
		{
			var s:Dynamic = m.sprite;
			if (s == null) continue;
			if (m.keepAlive)
			{
				// widget：从 dropGroup 安全移除（不 destroy），然后隐藏
				try { dropGroup.remove(s, false); } catch(e) {}
				try { s.visible = false; } catch(e) {}
			}
		}
		// 彻底清空 dropGroup 中残留的临时 sprite（分隔线、标签等）
		// 先把 border 和 bg 拿出来，清空后再加回去
		if (dropGroup.members != null)
		{
			dropGroup.remove(dropBorder, false);
			dropGroup.remove(dropBg, false);
			// ★ FlxTypedGroup.clear() 只设 this.length=0，不截断底层 Array。
			//    后续 add() 用 push 追加到数组末尾，旧元素变僵尸每帧迭代。
			//    手动 splice 清空底层数组。
			try { dropGroup.clear(); } catch(e) {}
			while (dropGroup.members.length > 0)
				dropGroup.members.pop();
			dropGroup.add(dropBorder);
			dropGroup.add(dropBg);
		}
		dropGroupMembers = [];
		dropRows = [];
		customControls = [];
		dynTexts = [];
	}

	function activateRow(row:CharacterDropdownRow):Void
	{
		if (row.def == null) return;
		var it = row.def;
		switch (it.type)
		{
			case Cmd:
				if (it.onClick != null) it.onClick();
			case Check:
				if (it.onCheck != null)
				{
					var curV = (it.getChecked != null) ? it.getChecked() : false;
					it.onCheck(!curV);
					if (row.checkIcon != null) refreshCheckIcon(row.checkIcon, it);
				}
			case Sep:
			case TextLine:
			case DynText:
				// 这些类型不需要 activate 操作
			case Widget:
				// CheckBox widget：toggle 原 widget.checked 并触发 callback
				if (row.widget != null)
				{
					var beforeChecked = false;
					try { beforeChecked = row.widget.checked; } catch(e:Dynamic) {}
					try { row.widget.checked = !beforeChecked; } catch(e:Dynamic) {}
					// ★ 程序性改 checked 不会自动触发 callback，得手动调一下
					// 用 Reflect.field 取（dynamic function 在 Haxe 里 Reflect.hasField 可能误判）
					try
					{
						var cb:Dynamic = Reflect.field(row.widget, 'callback');
						if (cb != null)
							cb();
					}
					catch (e:Dynamic) {}
					// 刷新显示（标签保持纯文本，勾选状态由右侧勾选框表达）
					if (row.label != null)
					{
						var newLabel = translateItemKey(it.labelKey);
						row.label.text = newLabel;
					}
					// 装饰性 checkbox 图标也更新一下（用背景色切换）
					if (row.checkIcon != null)
					{
						var w = row.widget;
						var isChecked = false;
						try { isChecked = w.checked; } catch(e:Dynamic) {}
						row.checkIcon.color = isChecked ? C_MENU_ACCENT : C_FIELD_BG;
					}
					// ★ √ 文本也切 visible + 文本内容（双保险，防 FlxSpriteGroup 级联覆盖 visible）
					if (row.checkTxt != null)
					{
						var w = row.widget;
						var isChecked = false;
						try { isChecked = w.checked; } catch(e:Dynamic) {}
						row.checkTxt.visible = isChecked;
						row.checkTxt.text = isChecked ? '√' : '';
					}
				}
			case LabelWidget:
				// 交互已由 handleCharacterCustomControlClick（自绘控件）接管：
				// stepper 的 [+]/[-]、dropdown 的展开/选值、input 的覆盖层弹出、slider 的拖拽
				// 点标签文字区域 → 不处理，保持菜单打开
		}
	}

	// ============ 描述条 ============
	function updateDescBar(row:CharacterDropdownRow):Void
	{
		if (row == null || row.def == null || row.def.descKey == null)
		{
			hideDescBar();
			return;
		}
		var txt = Language.get(row.def.descKey, 'character');
		if (txt == row.def.descKey) { hideDescBar(); return; }
		// Language.get 在开发者模式下找不到 key 时返回 "key (404)"，跟 key 本身不同，会继续显示
		// 这里再拦截一次，避免 (404) 出现在描述条里
		if (txt.indexOf(' (404)') == txt.length - 6) { hideDescBar(); return; }

		descText.text = txt;
		descText.color = C_TEXT_HINT;
		// 测量并定位
		// 简单策略：描述条放在下拉浮窗底部下方
		var descW = DROP_MAX_W;
		if (descW > DROP_MAX_W) descW = DROP_MAX_W;
		descText.fieldWidth = descW - 24;
		// ★ 弹性背景：直接用 openfl textField 的实际布局高度（getter 内部会强制 __updateLayout），
		//   不再用字符数估算 —— 之前估算对中文（12px 全角）偏小，3 行文本只给到 2 行背景。
		var realH:Float = 18;
		try { realH = descText.textField.textHeight; } catch (e:Dynamic) {}
		if (realH < 18) realH = 18;
		var descH = Std.int(realH) + 16; // 上下各 8px padding

		// ★ 缓存：内容、高度、位置都没变就跳过重建（每帧调用也不烧 GC）
		var cacheKey = txt + '|' + descH + '|' + Std.int(dropBg.x) + '|' + Std.int(dropBg.y + dropBg.height);
		if (cacheKey == lastDescCacheKey)
		{
			// 没变化，直接返回（背景/文本已经在上一帧摆好）
			return;
		}
		lastDescCacheKey = cacheKey;
		lastDescH = descH;

		descBg.makeGraphic(descW, descH, C_PAGE_BG);
		descBg.x = dropBg.x;
		descBg.y = dropBg.y + dropBg.height + 4;
		descBg.visible = true;

		descIcon.x = descBg.x + 8;
		descIcon.y = descBg.y + 6;
		descIcon.visible = true;

		descText.x = descBg.x + 24;
		descText.y = descBg.y + 6;
		descText.visible = true;
	}

	function hideDescBar():Void
	{
		descBg.visible = false;
		descIcon.visible = false;
		descText.visible = false;
		// 隐藏后清掉缓存，下次显示强制重建（位置可能已变）
		lastDescCacheKey = '';
	}

	// ============ 销毁 ============
	override function destroy():Void
	{
		super.destroy();
		widgetRefs.clear();
	}
}

// ============ 类型定义 ============
enum CharacterItemType
{
	Sep;
	Cmd;
	Check; // 已废弃，使用 Widget 类型直接嵌入 FlxUICheckBox
	Widget; // 直接嵌入原生控件（FlxUICheckBox 等，无标签）
	LabelWidget; // 带标签的原生控件（FlxUIInputText/FlxUINumericStepper/FlxUIDropDownMenu/FlxUISlider）
	TextLine; // 纯文本行（帮助菜单用）
	DynText; // 动态文本行（内容由外部注册 provider 提供）
}

typedef CharacterMenuItemDef =
{
	type:CharacterItemType,
	labelKey:String, // Widget: 用作 widgetKey; LabelWidget/TextLine/Cmd: 用作翻译key
	descKey:String,
	?getChecked:Void->Bool,
	?onCheck:Bool->Void,
	?onClick:Void->Void,
	?widgetKey:String // LabelWidget 类型时从 widgetRefs 获取控件
};

typedef CharacterMenuDef =
{
	key:String,
	isTest:Bool,
	items:Array<CharacterMenuItemDef>
};

typedef CharacterDropdownRow =
{
	type:CharacterItemType,
	labelKey:String,
	descKey:String,
	def:CharacterMenuItemDef,
	hit:FlxSprite,
	?checkIcon:Dynamic, // 勾选框背景 FlxSprite（Widget 类型用，toggle 时变色）
	?checkTxt:FlxText,  // √ 文本（始终创建，toggle 时切 visible）
	?label:FlxText,
	?hoverBg:FlxSprite,
	?widget:Dynamic // Widget/LabelWidget 类型时保存原生控件引用
};

/** 自绘控件（LabelWidget 行）：纯 FlxSprite/FlxText 画外观，点击自己判。
 *  原生 FlxUI 控件只作数据源（stepper 的值、dropdown 的选项、input 的文本、slider 的值），绝不渲染。 */
typedef CharacterCustomControl =
{
	key:String,
	ctype:String, // 'stepper' | 'dropdown' | 'input' | 'slider'
	widget:Dynamic,
	box:FlxSprite,
	text:FlxText,
	row:CharacterDropdownRow,
	// stepper
	?btnMinus:FlxSprite,
	?btnPlus:FlxSprite,
	// dropdown 展开面板
	?arrow:FlxText,
	?open:Bool,
	?options:Array<String>,
	?scrollIdx:Int,
	?panelBorder:FlxSprite,
	?panelBg:FlxSprite,
	?panelRows:Array<CharacterDropdownOption>,
	?panelH:Int,
	// slider
	?track:FlxSprite,
	?fill:FlxSprite,
	?thumb:FlxSprite,
	?dragging:Bool,
	// 走马灯（长文本从右往左滚动）
	?isScrolling:Bool,
	?scrollT:Float,
	?scrollDelay:Float
}

/** dropdown 展开面板的单个选项行 */
typedef CharacterDropdownOption =
{
	bg:FlxSprite,
	txt:FlxText,
	hit:FlxSprite,
	idx:Int,
	?isSelected:Bool // 当前选中项（底色常显，不随 hover 关闭）
}
