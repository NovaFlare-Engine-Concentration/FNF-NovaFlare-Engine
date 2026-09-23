package developer.editors;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.ui.FlxUI;
import flixel.addons.ui.FlxUIDropDownMenu;
import flixel.addons.ui.FlxUIInputText;
import flixel.addons.ui.FlxUINumericStepper;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.util.FlxDestroyUtil;

import general.backend.language.Language;
import general.backend.ClientPrefs;
import general.backend.Paths;

/**
 * Adobe 风格的谱面编辑器顶栏菜单。
 *
 * 设计：
 *  - 顶栏 8 个菜单按钮：谱面 / 数据 / 事件 / 音符 / 小节 / 歌曲 / 测试 / 帮助
 *  - 点击按钮 → 弹出下拉浮窗，包含若干行
 *  - 行类型：sep / cmd / check / widget / label_widget
 *  - hover 行 → 底部描述条显示该项说明（弹性换行）
 *
 * 所有原生控件（checkbox、输入框、下拉列表、数字步进器）直接嵌入下拉菜单，
 * 不再依赖 UI_box 的 tab group。ChartingState 通过 registerWidget 注册控件。
 */
class ChartEditorMenuBar extends FlxSpriteGroup
{
	// ============ 颜色常量（NovaFlare 设计规范：AARRGGBB，深色模式） ============
	// —— 中性色 ——
	static final C_PAGE_BG:FlxColor = 0xFF12141A;      // 页面底层背景
	static final C_CARD_BG:FlxColor = 0xFF1C1F28;      // 卡片面板背景
	static final C_HOVER_NEUTRAL:FlxColor = 0x147C7FFF; // Hover 通用底色（半透明蓝）
	static final C_BORDER:FlxColor = 0x14FFFFFF;       // 分割/边框（半透明白）
	static final C_TEXT_MAIN:FlxColor = 0xFFF2F3F5;    // 主文字
	static final C_TEXT_SEC:FlxColor = 0xFFC9CDD4;     // 次级文字
	static final C_TEXT_HINT:FlxColor = 0xFF86909C;    // 提示文字
	// —— 一级主菜单 ——
	static final C_MENU_G1:FlxColor = 0xFF4F46E5;      // 选中渐变起点
	static final C_MENU_G2:FlxColor = 0xFF7C3AED;      // 选中渐变终点
	static final C_ACCENT_BAR:FlxColor = 0xFFA78BFA;   // 装饰条/选中紫
	// —— 二级子菜单 ——
	static final C_ROW_SELECTED:FlxColor = 0x268B5CF6; // 选中底色
	static final C_ROW_SELECTED_TEXT:FlxColor = 0xFFA78BFA; // 选中文字
	// —— 按钮 ——
	static final C_PRIMARY_G1:FlxColor = 0xFF6366F1;   // 主按钮渐变（默认）
	static final C_PRIMARY_G2:FlxColor = 0xFF8B5CF6;
	static final C_SEC_BORDER:FlxColor = 0x26FFFFFF;   // 次要按钮模拟边框
	static final C_DANGER_RED:FlxColor = 0xFFEF4444;   // 危险按钮默认
	// —— 状态反馈 ——
	static final C_OK:FlxColor = 0xFF22C55E;
	static final C_WARN:FlxColor = 0xFFF59E0B;
	static final C_INFO:FlxColor = 0xFF3B82F6;

	// —— 旧名兼容（值已全部映射到上述规范） ——
	static final C_BG_TOP:FlxColor = 0xFF1C1F28;       // 顶栏 = 卡片面板背景
	static final C_BG_BOTTOM:FlxColor = 0xFF12141A;    // （未用）页面底层背景
	static final C_TITLE:FlxColor = 0xFFC9CDD4;        // 一级菜单未选中文字（次级）
	static final C_TITLE_HOVER:FlxColor = 0xFFFFFFFF;  // 选中文字（白）
	static final C_TITLE_BG_HOVER:FlxColor = 0x147C7FFF; // 顶栏 hover 底色（通用 hover）
	static final C_ACCENT:FlxColor = 0xFF8B5CF6;       // 强调紫（主渐变终点）
	static final C_TEST_ACCENT:FlxColor = 0xFFF59E0B;  // （保留）测试菜单提醒橙
	static final C_DROP_BG:FlxColor = 0xFF1C1F28;      // 下拉面板背景 = 卡片
	static final C_DROP_BORDER:FlxColor = 0x14FFFFFF;  // 面板边框 = 分割/边框
	static final C_ROW_TEXT:FlxColor = 0xFFF2F3F5;     // 行主文字
	static final C_ROW_TEXT_DIM:FlxColor = 0xFF86909C; // 行提示文字
	static final C_ROW_HOVER:FlxColor = 0x0F8B5CF6;    // 行 hover 底（二级子菜单）
	static final C_SEP:FlxColor = 0x14FFFFFF;          // 分隔线
	static final C_DESC_BG:FlxColor = 0xFF1C1F28;      // 描述条/事件面板 = 卡片
	static final C_DESC_TEXT:FlxColor = 0xFF86909C;    // 描述文字（提示色）
	static final C_DANGER:FlxColor = 0xFFEF4444;       // 危险文字（红）
	static final C_HOVER:FlxColor = 0x0F8B5CF6;        // hover 底色
	static final C_BG_2:FlxColor = 0xFF2A2E3A;         // 控件底/勾选方块未选中底

	// ============ 布局常量 ============
	public static final BAR_HEIGHT:Int = 36;
	public static final STATUS_HEIGHT:Int = 25;
	public static final MENU_W:Int = 88;
	public static final DROP_MIN_W:Int = 280;
	public static final DROP_MAX_W:Int = 420;
	public static final DESC_MAX_W:Int = 620;
	public static final ROW_H:Int = 22;
	public static final ROW_PAD_X:Int = 10;
	// 自绘下拉选项列表：每项高度 / 最多同时显示项数
	static final DROP_OPT_H:Int = 18;
	static final MAX_DROP_OPT:Int = 20;

	// 走马灯：长文本滚动速度（px/s）与两端停留秒数
	static final TEXT_SCROLL_SPEED:Float = 32;
	static final TEXT_SCROLL_HOLD:Float = 0.9;

	// ============ 菜单定义 ============
	public var menus:Array<MenuDef> = [];
	public var activeMenu:Int = -1;

	// ============ 顶栏视觉元素 ============
	var barBg:FlxSprite;
	var menuTitleSprites:Array<FlxText> = [];
	var menuTitleHits:Array<FlxSprite> = []; // 透明 hitbox
	var menuTabActives:Array<FlxSprite> = []; // 选中态渐变背景
	var menuTabHovers:Array<FlxSprite> = [];  // hover 底色背景
	var menuUnderline:FlxSprite;

	// ============ 下拉浮窗 ============
	var dropGroup:FlxSpriteGroup;
	var dropBg:FlxSprite;
	var dropBorder:FlxSprite;
	var dropRows:Array<DropdownRow> = [];
	// 跟踪所有加进 dropGroup 的东西（widget、文本、分隔线等），cleanup 时一起搞掉
	var dropGroupMembers:Array<Dynamic> = [];
	// ★ LabelWidget 的 FlxUI 控件绝不塞进 dropGroup（FlxUIGroup ≠ FlxSprite，parent 链会炸）
	//   独立跟踪，只做定位+显隐
	var activeLabelWidgets:Array<Dynamic> = [];
	// ★ 自绘控件（stepper / dropdown / input）：用纯 FlxSprite/FlxText 画外观 + 自己处理点击，
	//   原生 FlxUI 控件只留作数据源，绝不渲染
	var customControls:Array<CustomControl> = [];
	// DynText 动态文本行：key -> 渲染出来的 FlxText（重建菜单时刷新），内容由外部 provider 提供
	var dynTexts:Map<String, FlxText> = [];
	var dynTextProviders:Map<String, Void->String> = [];
	// ★ 事件下拉 hover 回调：hover 展开面板的选项行时触发 (ctrl, optIdx)，移出触发 (ctrl, -1)
	public var onDropdownHoverOption:Dynamic = null;
	// 跟踪每个 dropdown 上一次 hover 的选项，避免每帧重复触发
	var lastHoverOpt:Map<String, Int> = [];
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

	// ============ 事件描述浮动面板（事件下拉列表右侧） ============
	static final EVENT_INFO_W:Int = 300; // 面板宽度
	static final EVENT_INFO_PAD:Int = 10; // 内边距
	var eventInfoBg:FlxSprite;
	var eventInfoTitle:FlxText;
	var eventInfoBody:FlxText;
	var eventInfoShown:Bool = false;

	// ============ 状态栏（独立组件） ============
	public var statusBar:ChartEditorStatusBar;

	// ============ 当前临时弹出编辑的原生 widget（LabelWidget 点击时显示） ============
	var activeEditWidget:Dynamic = null;
	var activeEditPrevX:Float = 0;
	var activeEditPrevY:Float = 0;
	var activeEditPrevVisible:Bool = false;

	// ============ 外部回调 ============
	/** 切换 tab 回调，参数是 tab index（0=Song, 1=Section, 2=Note, 3=Event, 4=Charting, 5=Data） */
	public var onSelectTab:Int->Void = null;
	/** 操作回调，参数是 action key（如 'save', 'clear_events' 等） */
	public var onAction:String->Void = null;
	/** 试玩回调：true=测试模式（EditorPlayState），false=正常模式（PlayState） */
	public var onPlaytest:Bool->Void = null;
	/** 请求显示 UI_box 面板回调，参数是 (menuIdx, widgetKey) */
	public var onRequestUIBox:Int->String->Void = null;
	/** 菜单打开后回调，用于让外部（ChartingState）刷新 widget 的值 */
	public var onMenuOpened:String->Void = null;

	/** 当前用于鼠标判定的摄像机，默认 FlxG.camera；ChartingState 可在 create 末尾覆盖。 */
	public var uiCamera:flixel.FlxCamera;

	public function new()
	{
		super();
		scrollFactor.set();
		uiCamera = flixel.FlxG.camera;

		// 先添加状态栏，确保下拉菜单和描述条在其之上渲染
		statusBar = new ChartEditorStatusBar();
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

	/** 生成 上→下 / 左→右 线性渐变位图（NovaFlare 规范渐变用） */
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
		barBg = new FlxSprite().makeGraphic(1, BAR_HEIGHT, FlxColor.WHITE);
		// 简单的双色渐变：上半深、下半更深
		// flixel 没有原生渐变 sprite，用 makeGraphic + 逐行画像素代价太大，
		// 这里用单色 + 底部 1px 高亮线模拟 Adobe 风格
		barBg.makeGraphic(FlxG.width, BAR_HEIGHT, C_BG_TOP);
		barBg.x = 0;
		barBg.y = 0;
		add(barBg);

		// 顶栏底部 1px 分隔线（NovaFlare 分割/边框色）
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

		dropBorder = new FlxSprite().makeGraphic(1, 1, C_DROP_BORDER);
		dropGroup.add(dropBorder);
		dropBg = new FlxSprite().makeGraphic(1, 1, C_DROP_BG);
		dropGroup.add(dropBg);
	}

	// ============ 构建描述条 ============
	function buildDescBar():Void
	{
		descBg = new FlxSprite().makeGraphic(1, 1, C_DESC_BG);
		descBg.visible = false;
		add(descBg);
		descIcon = new FlxText(0, 0, 0, '[i]', 12);
		descIcon.setFormat(Paths.font(langFont()), 12, C_INFO, LEFT);
		descIcon.visible = false;
		add(descIcon);
		descText = new FlxText(0, 0, DESC_MAX_W, '', 12);
		descText.setFormat(Paths.font(langFont()), 12, C_DESC_TEXT, LEFT);
		descText.visible = false;
		descText.alignment = LEFT;
		add(descText);
	}

	// ============ 菜单数据定义 ============
	public function buildMenus():Void
	{
		menus = [
			{key: 'charting', isTest: false, items: [
				item_widget('w_metronome', 'desc_metronome'),
				item_widget('w_autoscroll', 'desc_autoscroll'),
				SEP,
				item_label_widget('w_bpm_stepper', 'label_bpm', 'desc_bpm'),
				item_label_widget('w_metronome_offset', 'label_offset', 'desc_offset'),
				SEP,
				item_widget('w_waveform_inst', 'desc_waveform_inst', 'Alt+I'),
				item_widget('w_waveform_main', 'desc_waveform_main', 'Alt+U'),
				item_widget('w_waveform_opp', 'desc_waveform_opp', 'Alt+O'),
				SEP,
				item_widget('w_mute_inst', 'desc_mute_inst', 'Alt+Ctrl+I'),
				item_widget('w_mute_main', 'desc_mute_main', 'Alt+Ctrl+U'),
				item_widget('w_mute_opp', 'desc_mute_opp', 'Alt+Ctrl+O'),
				SEP,
				item_widget('w_vortex', 'desc_vortex', 'Ctrl+Shift+Tab'),
				item_widget('w_ignore_warnings', 'desc_ignore_warnings'),
				item_widget('w_sfx_bf', 'desc_sfx_bf', 'Ctrl+Shift+U'),
				item_widget('w_sfx_opp', 'desc_sfx_opp', 'Ctrl+Shift+O'),
				SEP,
				item_label_widget('w_inst_volume', 'label_inst_vol', 'desc_inst_vol'),
				item_label_widget('w_voices_volume', 'label_voices_vol', 'desc_voices_vol'),
				item_label_widget('w_voices_opp_volume', 'label_voices_opp_vol', 'desc_voices_opp_vol'),
			]},
			{key: 'data', isTest: false, items: [
				item_label_widget('w_go_char', 'label_go_char', 'desc_go_char'),
				item_label_widget('w_go_sound', 'label_go_sound', 'desc_go_sound'),
				item_label_widget('w_go_loop', 'label_go_loop', 'desc_go_loop'),
				item_label_widget('w_go_end', 'label_go_end', 'desc_go_end'),
				SEP,
				item_widget('w_no_rgb', 'desc_no_rgb'),
				SEP,
				item_label_widget('w_note_skin', 'label_note_skin', 'desc_note_skin'),
				item_label_widget('w_note_splash', 'label_note_splash', 'desc_note_splash'),
				item_cmd('apply_notes', 'desc_apply_notes', () -> callAction('apply_notes')),
			]},
			{key: 'event', isTest: false, items: [
				item_label_widget('w_event_type', 'label_event_type', 'desc_event_type'),
				// ★ 事件描述不再作为菜单内的一行（dyn_event_info），
				//   改为在事件下拉列表展开时显示在其右侧的浮动面板（showEventInfoPanel）
				SEP,
				item_label_widget('w_value1', 'label_value1', 'desc_value1'),
				item_label_widget('w_value2', 'label_value2', 'desc_value2'),
				SEP,
				item_cmd('add_event', 'desc_add_event', () -> callAction('add_event')),
				item_cmd('del_event', 'desc_del_event', () -> callAction('del_event')),
				item_cmd('prev_event', 'desc_prev_event', () -> callAction('prev_event')),
				item_cmd('next_event', 'desc_next_event', () -> callAction('next_event')),
			]},
			{key: 'note', isTest: false, items: [
				item_label_widget('w_sus_length', 'label_sustain_len', 'desc_sustain_len'),
				item_label_widget('w_strum_time', 'label_strum_time', 'desc_strum_time'),
				item_label_widget('w_note_type', 'label_note_type', 'desc_note_type'),
			]},
			{key: 'section', isTest: false, items: [
				item_widget('w_must_hit', 'desc_must_hit', 'U'),
				item_widget('w_gf_section', 'desc_gf_section', 'I'),
				item_widget('w_alt_anim', 'desc_alt_anim'),
				SEP,
				item_label_widget('w_beats_per_section', 'label_beats', 'desc_beats_per_section'),
				item_widget('w_change_bpm', 'desc_change_bpm'),
				item_label_widget('w_section_bpm', 'label_section_bpm', 'desc_section_bpm'),
				SEP,
				item_cmd('copy_section', 'desc_copy_section', () -> callAction('copy_section'), 'Ctrl+C'),
				item_cmd('paste_section', 'desc_paste_section', () -> callAction('paste_section'), 'Ctrl+V'),
				item_cmd('clear_section', 'desc_clear_section', () -> callAction('clear_section')),
				item_cmd('swap_section', 'desc_swap_section', () -> callAction('swap_section'), 'Ctrl+U'),
				item_label_widget('w_copy_beat', 'label_copy_beat', 'desc_copy_beat'),
				item_cmd('do_copy_beat', 'desc_do_copy_beat', () -> callAction('do_copy_beat')),
				item_cmd('duet_notes', 'desc_duet_notes', () -> callAction('duet_notes'), 'Ctrl+I'),
				item_cmd('mirror_notes', 'desc_mirror_notes', () -> callAction('mirror_notes'), 'Ctrl+O'),
				SEP,
				item_cmd('undo', 'desc_undo', () -> callAction('undo'), 'Ctrl+Z'),
				SEP,
				item_widget('w_include_notes', 'desc_include_notes'),
				item_widget('w_include_events', 'desc_include_events'),
			]},
			{key: 'song', isTest: false, items: [
				item_label_widget('w_song_title', 'label_song_title', 'desc_song_title'),
				item_label_widget('w_difficulty', 'label_difficulty', 'desc_difficulty'),
				item_widget('w_has_voice', 'desc_has_voice'),
				SEP,
				item_cmd('save', 'desc_save', () -> callAction('save'), 'Ctrl+S'),
				item_cmd('reload_audio', 'desc_reload_audio', () -> callAction('reload_audio'), 'Ctrl+Shift+Q'),
				item_cmd('reload_json', 'desc_reload_json', () -> callAction('reload_json'), 'Ctrl+Shift+W'),
				item_cmd('engine', 'desc_engine', () -> callAction('engine')),
				item_cmd('load_autosave', 'desc_load_autosave', () -> callAction('load_autosave'), 'Ctrl+Shift+E'),
				item_cmd('load_events', 'desc_load_events', () -> callAction('load_events'), 'Ctrl+Shift+R'),
				item_cmd('save_events', 'desc_save_events', () -> callAction('save_events'), 'Ctrl+Shift+S'),
				SEP,
				item_cmd('clear_events', 'desc_clear_events', () -> callAction('clear_events'), 'Shift+Del'),
				item_cmd('clear_notes', 'desc_clear_notes', () -> callAction('clear_notes'), 'Ctrl+Del'),
				SEP,
				item_label_widget('w_bpm', 'label_song_bpm', 'desc_bpm'),
				item_label_widget('w_speed', 'label_song_speed', 'desc_speed'),
				item_label_widget('w_mania', 'label_song_mania', 'desc_mania', 'K+数字'),
				SEP,
				item_label_widget('w_stage', 'label_stage', 'desc_stage'),
				item_label_widget('w_player1', 'label_player1', 'desc_opponent'),
				item_label_widget('w_gf', 'label_gf', 'desc_girlfriend'),
				item_label_widget('w_player2', 'label_player2', 'desc_player'),
			]},
			{key: 'test', isTest: true, items: [
				item_cmd('test_mode', 'desc_test_mode', () -> callPlaytest(true), 'Esc'),
				SEP,
				item_cmd('normal_mode', 'desc_normal_mode', () -> callPlaytest(false), 'Enter'),
			]},
			{key: 'help', isTest: false, items: [
				item_label_widget('help_nav', 'label_help_nav', 'desc_help_nav'),
				item_text('help_nav_ws', 'desc_help_nav_ws'),
				item_text('help_nav_ad', 'desc_help_nav_ad'),
				item_text('help_nav_lr', 'desc_help_nav_lr'),
				SEP,
				item_label_widget('help_note', 'label_help_note', 'desc_help_note'),
				item_text('help_note_add', 'desc_help_note_add'),
				item_text('help_note_move', 'desc_help_note_move'),
				item_text('help_note_del', 'desc_help_note_del'),
				item_text('help_note_sus', 'desc_help_note_sus'),
				SEP,
				item_label_widget('help_play', 'label_help_play', 'desc_help_play'),
				item_text('help_play_test', 'desc_help_play_test'),
				item_text('help_play_norm', 'desc_help_play_norm'),
				item_text('help_play_stop', 'desc_help_play_stop'),
				item_text('help_play_zoom', 'desc_help_play_zoom'),
				SEP,
				item_label_widget('help_edit', 'label_help_edit', 'desc_help_edit'),
				item_text('help_edit_undo', 'desc_help_edit_undo'),
				item_text('help_edit_save', 'desc_help_edit_save'),
				item_text('help_edit_section', 'desc_help_edit_section'),
			]},
		];
	}

	// ============ 行类型辅助函数 ============
	static var SEP:MenuItemDef = {type: Sep, labelKey: null, descKey: null, getChecked: null, onCheck: null, onClick: null};

	function item_cmd(labelKey:String, descKey:String, onClick:Void->Void, ?shortcut:String):MenuItemDef
	{
		return {type: Cmd, labelKey: labelKey, descKey: descKey, getChecked: null, onCheck: null, onClick: onClick, shortcut: shortcut};
	}

	function item_widget(widgetKey:String, descKey:String, ?shortcut:String):MenuItemDef
	{
		return {type: Widget, labelKey: widgetKey, descKey: descKey, getChecked: null, onCheck: null, onClick: null, widgetKey: widgetKey, shortcut: shortcut};
	}

	function item_label_widget(widgetKey:String, labelKey:String, descKey:String, ?shortcut:String):MenuItemDef
	{
		return {type: LabelWidget, labelKey: labelKey, descKey: descKey, getChecked: null, onCheck: null, onClick: null, widgetKey: widgetKey, shortcut: shortcut};
	}

	function item_text(textKey:String, descKey:String):MenuItemDef
	{
		return {type: TextLine, labelKey: textKey, descKey: descKey, getChecked: null, onCheck: null, onClick: null};
	}

	function item_dyn_text(dynKey:String, descKey:String):MenuItemDef
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
		var translated = Language.get(itemKey, 'charting');
		if (translated == itemKey || translated.indexOf('(404)') != -1) {
			// 尝试不带 item_ 前缀
			translated = Language.get(key.substring(2), 'charting');
		}
		return translated;
	}

	/** LabelWidget 类型：label_bpm -> label_bpm (直接查) */
	function translateLabelKey(key:String):String
	{
		var translated = Language.get(key, 'charting');
		if (translated == key || translated.indexOf('(404)') != -1) {
			// 尝试带 label_ 前缀
			translated = Language.get('label_' + key, 'charting');
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
			// 选中态：主渐变背景（4F46E5 → 7C3AED，左→右）
			var activeBg:FlxSprite = makeGradSprite(MENU_W, BAR_HEIGHT, C_MENU_G1, C_MENU_G2, true);
			activeBg.x = i * MENU_W;
			activeBg.y = 0;
			activeBg.visible = false;
			add(activeBg);
			menuTabActives.push(activeBg);

			// hover 底色（通用 hover 半透明蓝）
			var hoverBg:FlxSprite = new FlxSprite().makeGraphic(MENU_W, BAR_HEIGHT, C_TITLE_BG_HOVER);
			hoverBg.x = i * MENU_W;
			hoverBg.y = 0;
			hoverBg.visible = false;
			add(hoverBg);
			menuTabHovers.push(hoverBg);

			var m = menus[i];
			var txt:FlxText = new FlxText(i * MENU_W, 0, MENU_W, Language.get('menu_' + m.key, 'charting'), 14);
			txt.setFormat(Paths.font(langFont()), 14, C_TITLE, CENTER);
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
		// 选中装饰条（A78BFA，位于选中项下缘）
		menuUnderline = new FlxSprite().makeGraphic(MENU_W - 24, 2, C_ACCENT_BAR);
		menuUnderline.visible = false;
		add(menuUnderline);

		// 状态栏也刷新
		if (statusBar != null)
			statusBar.applyLang();
	}

	// ============ ChartingState 提供的辅助方法（外部赋值） ============
	/**
	 * 注册原生控件（FlxUICheckBox / FlxUIInputText / FlxUINumericStepper / FlxUIDropDownMenu 等）到菜单系统。
	 * key 必须和 buildMenus() 中 widget / label_widget 项的 key 一致。
	 * 控件生命周期由 ChartingState 管理，菜单只负责 add/remove 到 dropGroup。
	 */
	var widgetRefs:Map<String, Dynamic> = [];
	public function registerWidget(key:String, widget:Dynamic):Void
	{
		widgetRefs.set(key, widget);
		// ★ 不再设置 scrollFactor —— FlxUIGroup 的 scrollFactor 传播在嵌套层级中不可靠。
		//   改为在 rebuildDropdown 中手动用 camera.scroll 做世界坐标换算。
	}

	/** 注册动态文本行（DynText）的内容提供器。key 必须和 buildMenus() 中 item_dyn_text 的 key 一致。 */
	public function registerDynText(key:String, provider:Void->String):Void
	{
		dynTextProviders.set(key, provider);
	}

	/** 刷新所有 DynText 行的显示文本（provider 内容变化时调用，如事件 hover / 选中变化）。 */
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

	function callPlaytest(testMode:Bool):Void
	{
		if (onPlaytest != null) onPlaytest(testMode);
		closeMenu();
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

		// 鼠标在顶栏按钮上 hover
		// ★ menuBar 所有 sprite 用 scrollFactor.set()=0（不随相机 scroll 移动）
		//   sprite.x 是世界坐标，但因为 scrollFactor=0，等价于视图空间坐标
		//   鼠标用 viewX/viewY（视图空间）才能正确比较，不受相机 scroll 扭曲
		//   （旧代码用 screenX/Y 是死的——flixel 5.9.0 把它标 deprecated 且 setter=never）
		var hoverIdx:Int = -1;
		var hoverMx:Float = FlxG.mouse.viewX;
		var hoverMy:Float = FlxG.mouse.viewY;
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
			// ★ 用 viewX/viewY（相机视图空间坐标），与 sprite.x 直接可比
			//   旧代码用 screenX/Y 永远是 0（flixel 5.9.0 把它标 deprecated 且 setter=never）
			var mx:Float = FlxG.mouse.viewX;
			var my:Float = FlxG.mouse.viewY;
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
					// ★ 点在列表/描述条/事件面板/嵌入控件上 → 不关闭，不抢事件
					// ① 输入覆盖层正在编辑中：点覆盖层内部 → 不抢，让输入框处理
					if (activeEditWidget != null && pointInWidget(mx, my, activeEditWidget))
					{
						// 啥都不做
					}
					else
					{
						// 点覆盖层之外 → 失焦收回（覆盖层 active=false 后不会自己失焦，得手动收）
						if (activeEditWidget != null)
							clearActiveEditWidget();
						// ② 展开的 dropdown 面板按下：挂起（区分拖拽滚动与点击，释放时处理）
						var panelHandled:Bool = beginDropdownPress(mx, my);
						if (!panelHandled)
						{
							// ③ 普通行点击
							var hitRow:DropdownRow = null;
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
								// LabelWidget 行：先走自绘控件点击（stepper [+]/[-]、dropdown、input）
								if (hitRow.def.type == LabelWidget)
									handled = handleCustomControlClick(hitRow);
								if (!handled)
								{
									activateRow(hitRow);
									// Cmd/Check 点完关菜单；Widget/LabelWidget 保持打开
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

		// 更新顶栏按钮 hover / active 视觉
		for (i in 0...menuTitleSprites.length)
		{
			var t = menuTitleSprites[i];
			var isActive = (i == activeMenu);
			var isHover = (i == hoverIdx);
			// ★ NovaFlare 规范：选中 = 主渐变底 + 白字；hover = 通用 hover 底 + 白字
			if (i < menuTabActives.length) menuTabActives[i].visible = isActive;
			if (i < menuTabHovers.length) menuTabHovers[i].visible = !isActive && isHover;
			t.color = (isActive || isHover) ? C_TITLE_HOVER : C_TITLE;
		}
		if (menuUnderline != null)
		{
			if (activeMenu >= 0)
			{
				menuUnderline.x = activeMenu * MENU_W + 12;
				menuUnderline.y = BAR_HEIGHT - 2;
				menuUnderline.visible = true;
			}
			else
				menuUnderline.visible = false;
		}

		// 下拉行 hover → 更新描述条 + 绘制/清除 hover 背景
		if (activeMenu >= 0 && dropGroup.visible)
		{
			var hoverRow:DropdownRow = null;
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
					// ★ 勾选行已有选中底色，hover 不再叠加（避免盖住选中态）
					row.hoverBg.visible = (row == hoverRow && (row.selectedBg == null || !row.selectedBg.visible));
			}
			updateDescBar(hoverRow);

			// ★ 自绘 dropdown 展开面板：选项行 hover 视觉 + hover 回调
			var pMx:Float = FlxG.mouse.viewX;
			var pMy:Float = FlxG.mouse.viewY;
			for (ctrl in customControls)
			{
				if (ctrl.ctype != 'dropdown') continue;
				var hoverIdx:Int = -1;
				if (ctrl.open == true && ctrl.panelRows != null)
				{
					for (pr in ctrl.panelRows)
					{
						var hov = pointInSprite(pMx, pMy, pr.hit);
						if (pr.bg != null) pr.bg.visible = hov;
						if (hov) hoverIdx = pr.idx;
					}
				}
				// 只在 hover 变化时触发一次（事件信息显示用；-2 哨兵保证首帧必触发）
				var last:Int = lastHoverOpt.exists(ctrl.key) ? lastHoverOpt.get(ctrl.key) : -2;
				if (last != hoverIdx)
				{
					lastHoverOpt.set(ctrl.key, hoverIdx);
					if (onDropdownHoverOption != null)
					{
						try { onDropdownHoverOption(ctrl, hoverIdx); } catch (e:Dynamic) {}
					}
					// ★ 事件描述浮动面板：hover 选项 → 显示在列表右侧；移出 → 隐藏
					updateEventInfoPanel(ctrl, hoverIdx);
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
				// ★ 可见行数按实际面板（屏幕空间可能裁剪了 MAX_DROP_OPT）
				var visibleRows:Int = (ctrl.panelH != null && ctrl.panelH > 0) ? Std.int(Math.max(1, ctrl.panelH / DROP_OPT_H)) : MAX_DROP_OPT;
				var maxScroll:Int = Std.int(Math.max(0, total - visibleRows));
				ctrl.scrollIdx = Std.int(FlxMath.bound(ctrl.scrollIdx - FlxG.mouse.wheel, 0, maxScroll));
					clearDropdownPanel(ctrl);
					renderDropdownOptions(ctrl);
					// ★ 滚动会重建选项行，浮动面板被 clearDropdownPanel 隐藏；
					//   若鼠标仍在新列表上，立即恢复（hover 索引以新列表为准）
					if (ctrl.key == 'w_event_type')
					{
						var hovNow:Int = -1;
						if (ctrl.panelRows != null)
							for (pr in ctrl.panelRows)
								if (pointInSprite(pMx, pMy, pr.hit)) { hovNow = pr.idx; break; }
						if (hovNow >= 0)
						{
							lastHoverOpt.set(ctrl.key, hovNow);
							if (onDropdownHoverOption != null)
							{
								try { onDropdownHoverOption(ctrl, hovNow); } catch (e:Dynamic) {}
							}
						}
						updateEventInfoPanel(ctrl, hovNow);
					}
					break;
				}
			}
		}

		// ★ 展开 dropdown 的拖拽滚动/挂起点击（每帧处理，保证释放收尾）
		updateDropdownDrag();

		// ★ 输入覆盖层失焦检测：原生输入框失去焦点 → 收回覆盖层
		if (activeEditWidget != null)
		{
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
	function refreshCustomControlDisplays():Void
	{
		for (ctrl in customControls)
		{
			if (ctrl.ctype == 'stepper') updateStepperDisplay(ctrl);
			else if (ctrl.ctype == 'dropdown') updateDropdownDisplay(ctrl);
			else if (ctrl.ctype == 'input') updateInputDisplay(ctrl);
		}
		refreshDynTexts();
	}

	function updateStepperDisplay(ctrl:CustomControl):Void
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
	function setControlText(ctrl:CustomControl, txt:String):Void
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

	function updateDropdownDisplay(ctrl:CustomControl):Void
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

	function updateInputDisplay(ctrl:CustomControl):Void
	{
		var txt:String = '';
		try { txt = ctrl.widget.text; } catch (e:Dynamic) {}
		if (txt == null) txt = '';
		setControlText(ctrl, txt);
	}

	// ============ 自绘控件：点击交互 ============
	function pointInSprite(mx:Float, my:Float, s:FlxSprite):Bool
	{
		if (s == null) return false;
		return mx >= s.x && mx <= s.x + s.width && my >= s.y && my <= s.y + s.height;
	}

	/** LabelWidget 行的自绘控件点击。返回 true 表示已消费（菜单保持打开）。 */
	function handleCustomControlClick(row:DropdownRow):Bool
	{
		var ctrl:CustomControl = null;
		for (c in customControls)
		{
			if (c.row == row) { ctrl = c; break; }
		}
		if (ctrl == null) return false;

		var mx:Float = FlxG.mouse.viewX;
		var my:Float = FlxG.mouse.viewY;

		if (ctrl.ctype == 'stepper')
		{
			if (ctrl.btnPlus != null && pointInSprite(mx, my, ctrl.btnPlus)) { stepperPlus(ctrl); return true; }
			if (ctrl.btnMinus != null && pointInSprite(mx, my, ctrl.btnMinus)) { stepperMinus(ctrl); return true; }
			if (ctrl.box != null && pointInSprite(mx, my, ctrl.box)) return true;
			return false;
		}
		if (ctrl.ctype == 'dropdown')
		{
			if (ctrl.box != null && pointInSprite(mx, my, ctrl.box))
			{
				if (ctrl.open == true) { clearDropdownPanel(ctrl); ctrl.open = false; }
				else { closeCustomDropdowns(); ctrl.open = true; renderDropdownOptions(ctrl); }
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
		return false;
	}

	/** 展开中的 dropdown 面板按下：不立即选中/收起，先挂起（记录按下行与滚动起点），
	 *  由 update 里的拖拽检测决定是"拖动滚动"还是"单击选择"。返回 true 表示已消费。 */
	function beginDropdownPress(mx:Float, my:Float):Bool
	{
		var ctrl:CustomControl = null;
		for (c in customControls)
		{
			if (c.ctype == 'dropdown' && c.open == true) { ctrl = c; break; }
		}
		if (ctrl == null) return false;
		if (ctrl.panelBg == null || !pointInSprite(mx, my, ctrl.panelBg)) return false;

		ctrl.dragging = true;
		ctrl.dragY = my;
		ctrl.dragScroll0 = (ctrl.scrollIdx != null) ? ctrl.scrollIdx : 0;
		ctrl.dragMoved = false;
		ctrl.pressIdx = -1;
		if (ctrl.panelRows != null)
		{
			for (pr in ctrl.panelRows)
			{
				if (pointInSprite(mx, my, pr.hit)) { ctrl.pressIdx = pr.idx; break; }
			}
		}
		return true;
	}

	/** 每帧：处理展开 dropdown 面板上的拖拽滚动；释放时未拖动则执行挂起的点击。 */
	function updateDropdownDrag():Void
	{
		for (ctrl in customControls)
		{
			if (ctrl.ctype != 'dropdown' || ctrl.dragging != true) continue;

			var mx:Float = FlxG.mouse.viewX;
			var my:Float = FlxG.mouse.viewY;

			if (FlxG.mouse.pressed)
			{
				var dy:Float = my - ctrl.dragY;
				if (!ctrl.dragMoved && Math.abs(dy) >= 4) ctrl.dragMoved = true;
				if (ctrl.dragMoved)
				{
					// 内容跟随鼠标：向下拖 dy>0 → 往前翻（scrollIdx 减小）
					var deltaRows:Int = Math.round(dy / DROP_OPT_H);
					var total:Int = (ctrl.options != null) ? ctrl.options.length : 0;
					var visibleRows:Int = (ctrl.panelH != null && ctrl.panelH > 0) ? Std.int(Math.max(1, ctrl.panelH / DROP_OPT_H)) : MAX_DROP_OPT;
					var maxScroll:Int = Std.int(Math.max(0, total - visibleRows));
					var ns:Int = Std.int(FlxMath.bound(ctrl.dragScroll0 - deltaRows, 0, maxScroll));
					if (ns != ctrl.scrollIdx)
					{
						ctrl.scrollIdx = ns;
						clearDropdownPanel(ctrl);
						renderDropdownOptions(ctrl);
						refreshDropdownHover(ctrl, mx, my);
					}
				}
			}
			else if (FlxG.mouse.justReleased)
			{
				var wasDrag:Bool = (ctrl.dragMoved == true);
				var pressIdx:Int = (ctrl.pressIdx != null) ? ctrl.pressIdx : -1;
				var stillInside:Bool = (ctrl.panelBg != null && pointInSprite(mx, my, ctrl.panelBg));
				ctrl.dragging = false;
				ctrl.dragMoved = false;
				ctrl.pressIdx = -1;
				if (!wasDrag && stillInside)
				{
					// 未拖动 = 单击：按下在选项行 → 选中；在面板空白 → 收起
					if (pressIdx >= 0)
						selectDropdownOption(ctrl, pressIdx);
					else
					{
						clearDropdownPanel(ctrl);
						ctrl.open = false;
					}
				}
				// 拖拽过或移出面板释放 → 取消（不选中、不收起）
			}
		}
	}

	/** 面板滚动重建后：若鼠标仍悬在新选项行上，刷新 hover 回调与事件描述面板 */
	function refreshDropdownHover(ctrl:CustomControl, mx:Float, my:Float):Void
	{
		if (ctrl == null || ctrl.key != 'w_event_type') return;
		var hovNow:Int = -1;
		if (ctrl.panelRows != null)
			for (pr in ctrl.panelRows)
				if (pointInSprite(mx, my, pr.hit)) { hovNow = pr.idx; break; }
		if (hovNow >= 0)
		{
			lastHoverOpt.set(ctrl.key, hovNow);
			if (onDropdownHoverOption != null)
			{
				try { onDropdownHoverOption(ctrl, hovNow); } catch (e:Dynamic) {}
			}
		}
		updateEventInfoPanel(ctrl, hovNow);
	}

	/** 选中 dropdown 的某个选项：直接调原生列表按钮的 onUp（内部会 selectSomething + callback + 广播事件） */
	function selectDropdownOption(ctrl:CustomControl, optIdx:Int):Void
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

	function renderDropdownOptions(ctrl:CustomControl):Void
	{
		if (ctrl.box == null) return;
		var opts:Array<String> = (ctrl.options != null) ? ctrl.options : [];
		var visCount:Int = Std.int(Math.min(opts.length, MAX_DROP_OPT));
		if (visCount < 1) return;

		var px:Float = ctrl.box.x;
		var py:Float = ctrl.box.y + ctrl.box.height + 1;
		var pw:Float = ctrl.box.width;

		// ★ 面板自适应屏幕：向下展开会超出屏幕底部（长菜单里的下拉如角色列表）
		//   就向上展开；上下都不够时按可用空间削减可见行数，保证最下面的选项可选到
		var panelH:Int = visCount * DROP_OPT_H;
		var topLimit:Float = BAR_HEIGHT + STATUS_HEIGHT + 4; // 菜单区顶部
		if (py + panelH > FlxG.height - 4)
		{
			var upY:Float = ctrl.box.y - panelH - 1;
			if (upY >= topLimit)
				py = upY; // 向上展开
			else
			{
				// 上方空间不足：先尽量向上，再按上下可用空间裁行数
				var roomDown:Int = Std.int(FlxG.height - 4 - (ctrl.box.y + ctrl.box.height + 1));
				var roomUp:Int = Std.int(ctrl.box.y - topLimit);
				var maxRows:Int = Std.int(Math.max(0, Math.max(roomDown, roomUp)) / DROP_OPT_H);
				if (maxRows < visCount) visCount = maxRows;
				if (visCount < 1) visCount = 1;
				panelH = visCount * DROP_OPT_H;
				if (ctrl.box.y - panelH - 1 >= topLimit)
					py = ctrl.box.y - panelH - 1; // 向上
				else
					py = ctrl.box.y + ctrl.box.height + 1; // 保持向下（已裁到最小可见）
			}
		}

		// ★ 重新打开时旧 scrollIdx 可能超出新的可见范围 → clamp，避免行不足出现空白
		if (ctrl.scrollIdx != null)
		{
			if (ctrl.scrollIdx > opts.length - visCount) ctrl.scrollIdx = opts.length - visCount;
			if (ctrl.scrollIdx < 0) ctrl.scrollIdx = 0;
		}

		var pBorder:FlxSprite = new FlxSprite().makeGraphic(Std.int(pw) + 2, visCount * DROP_OPT_H + 2, C_DROP_BORDER);
		pBorder.x = Std.int(px) - 1;
		pBorder.y = Std.int(py) - 1;
		pBorder.antialiasing = ClientPrefs.data.antialiasing;
		addToDrop(pBorder, false);
		// ★ 边框也要登记进 ctrl，否则 clearDropdownPanel 只清行/背景，边框残留成"只剩背景"的僵尸
		ctrl.panelBorder = pBorder;

		var pBg:FlxSprite = new FlxSprite().makeGraphic(Std.int(pw), visCount * DROP_OPT_H, C_DROP_BG);
		pBg.x = Std.int(px);
		pBg.y = Std.int(py);
		pBg.antialiasing = ClientPrefs.data.antialiasing;
		addToDrop(pBg, false);

		ctrl.panelBg = pBg;
		ctrl.panelH = visCount * DROP_OPT_H;

		var rows:Array<DropdownOption> = [];
		for (i in 0...visCount)
		{
			var optIdx:Int = ctrl.scrollIdx + i;
			if (optIdx < 0 || optIdx >= opts.length) continue;
			var oy:Float = py + i * DROP_OPT_H;

			var bg:FlxSprite = new FlxSprite().makeGraphic(Std.int(pw), DROP_OPT_H, C_HOVER);
			bg.x = Std.int(px);
			bg.y = Std.int(oy);
			bg.visible = false;
			bg.antialiasing = ClientPrefs.data.antialiasing;
			addToDrop(bg, false);

			var t:FlxText = new FlxText(0, 0, Std.int(pw) - 10, opts[optIdx], 11);
			t.setFormat(Paths.font(langFont()), 11, C_TEXT_SEC, LEFT);
			fitTextOneLine(t);
			t.x = Std.int(px + 5);
			t.y = Std.int(oy + (DROP_OPT_H - t.height) / 2);
			addToDrop(t, false);

			var hit:FlxSprite = new FlxSprite().makeGraphic(Std.int(pw), DROP_OPT_H, FlxColor.TRANSPARENT);
			hit.x = Std.int(px);
			hit.y = Std.int(oy);
			addToDrop(hit, false);

			rows.push({bg: bg, txt: t, hit: hit, idx: optIdx});
		}
		ctrl.panelRows = rows;
	}

	function clearDropdownPanel(ctrl:CustomControl):Void
	{
		// ★ 事件描述面板常驻：收起下拉时切回当前选中事件的描述（不再隐藏；
		//   滚轮滚动重建时此调用会被后面的 updateEventInfoPanel(hovNow) 覆盖为 hover 项）
		if (ctrl != null && ctrl.key == 'w_event_type')
			updateEventInfoPanel(ctrl, -1);
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
	function stepperPlus(ctrl:CustomControl):Void
	{
		stepperStep(ctrl, 1);
	}

	function stepperMinus(ctrl:CustomControl):Void
	{
		stepperStep(ctrl, -1);
	}

	function stepperStep(ctrl:CustomControl, dir:Int):Void
	{
		var w:Dynamic = ctrl.widget;
		if (w == null) return;
		try
		{
			var step:Float = 1;
			try { step = w.stepSize; } catch (e:Dynamic) {}
			// ★ 按住 Alt 点击 = ×10 大步进；按住 Shift = ×5；否则用默认步长
			if (FlxG.keys.pressed.ALT)
				step *= 10;
			else if (FlxG.keys.pressed.SHIFT)
				step *= 5;
			w.value = w.value + step * dir; // setter 自动 clamp min/max 并更新文本
			// 原生 set_value 只改文本不广播事件，手动补一发 CHANGE_EVENT 让 ChartingState 更新数据
			try { FlxUI.event(FlxUINumericStepper.CHANGE_EVENT, w, w.value, w.params); } catch (e:Dynamic) {}
		}
		catch (e:Dynamic) {}
		updateStepperDisplay(ctrl);
	}

	/** 点击 input 自绘区域 → 弹出原生输入覆盖层（定位到自绘 box 区域并聚焦） */
	function openInputOverlay(ctrl:CustomControl):Void
	{
		var w:Dynamic = ctrl.widget;
		clearActiveEditWidget();
		if (w == null || ctrl.box == null) return;
		// 保存原位置/显隐（供 clearActiveEditWidget 还原）
		try { activeEditPrevX = w.x; } catch (e:Dynamic) {}
		try { activeEditPrevY = w.y; } catch (e:Dynamic) {}
		try { activeEditPrevVisible = w.visible; } catch (e:Dynamic) {}
		// 定位到自绘控件区域并显示
		try { w.x = ctrl.box.x; } catch (e:Dynamic) {}
		try { w.y = ctrl.box.y; } catch (e:Dynamic) {}
		try { w.visible = true; } catch (e:Dynamic) {}
		// ★ 统一灰底白字外观（文字白 / 背景灰 / 边框浅灰 / 字号 12 / main 字体）
		EditorInputStyle.apply(w);
		// 安全重渲（drawFrame 内部触发 calcFrame，直接 calcFrame 可能原生崩溃）
		try { Reflect.setField(w, '_regen', true); } catch (e:Dynamic) {}
		try { w.drawFrame(true); } catch (e:Dynamic) {}
		// ★ 必须保持 active=false：FlxInputText.update() 每次鼠标点击都会用 overlaps(this)
		//   判定焦点，而原生覆盖层比自绘 box 矮（字号 8 ≈ 10px 高 vs box 18px），
		//   点击 box 下半区就会被判成"点在框外"把 hasFocus 秒清 → 光标刚亮就灭。
		//   键盘输入走 stage 级 KEY_DOWN 监听，不依赖 update()，所以不跑 update 完全没问题。
		try { w.active = false; } catch (e:Dynamic) {}
		// 提升绘制层级：移到 state 成员末尾，确保覆盖层显示在菜单之上
		var st:Dynamic = FlxG.state;
		try { st.remove(w); } catch (e:Dynamic) {}
		try { st.add(w); } catch (e:Dynamic) {}
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

	/**
	 * 检查屏幕坐标 (mx, my) 是否落在 menuBar 任何 UI 元素上：
	 * 顶栏 / 下拉浮窗 / 描述条 / 事件面板 / 临时弹出 widget / 嵌入的 LabelWidget 控件。
	 * ChartingState.update 开头用这个判断点击是否在"列表内"，不在就强制 closeMenu。
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
		if (activeEditWidget != null && pointInWidget(mx, my, activeEditWidget))
			return true;

		// 6. LabelWidget 行嵌入的原生控件（DropDownMenu 展开列表可能超出 dropBg 范围）
		for (row in dropRows)
		{
			if (row.type == LabelWidget && row.widget != null && pointInWidget(mx, my, row.widget))
				return true;
		}

		// 7. 自绘 dropdown 展开的选项面板（超出 dropBg 范围）
		for (ctrl in customControls)
		{
			if (ctrl.ctype != 'dropdown' || ctrl.open != true) continue;
			if (ctrl.panelBg != null && pointInSprite(mx, my, ctrl.panelBg))
				return true;
		}

		// 8. 事件描述浮动面板（事件下拉列表右侧，点击不关闭菜单）
		if (eventInfoShown && eventInfoBg != null && pointInSprite(mx, my, eventInfoBg))
			return true;

		return false;
	}

	// ============ 打开 / 关闭菜单 ============
	public function openMenu(idx:Int):Void
	{
		// 切换菜单时，先把上一个菜单弹出的编辑 widget 收回去
		clearActiveEditWidget();
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
		refreshCustomControlDisplays();

		// ★ 事件描述面板常驻：打开事件菜单时立即显示当前选中事件的描述
		for (ctrl in customControls)
			updateEventInfoPanel(ctrl, -1);

		// 切换对应的 tab（如果有）
		var tabIdx = menuKeyToTabIdx(menuKey);
		if (tabIdx >= 0 && onSelectTab != null)
			onSelectTab(tabIdx);
	}

	// 将菜单 key 映射到 UI_box 的 tab index
	function menuKeyToTabIdx(key:String):Int
	{
		switch (key)
		{
			case 'song': return 0;
			case 'section': return 1;
			case 'note': return 2;
			case 'event': return 3;
			case 'charting': return 4;
			case 'data': return 5;
			default: return -1;
		}
	}

	/** 获取当前下拉菜单的矩形区域（用于定位 UI_box 面板） */
	public function getDropdownRect():{x:Int, y:Int, w:Int, h:Int}
	{
		if (activeMenu < 0 || activeMenu >= menus.length)
			return {x: 0, y: 0, w: 0, h: 0};
		var m = menus[activeMenu];
		var dropX = activeMenu * MENU_W + 4;
		var dropY = BAR_HEIGHT + STATUS_HEIGHT + 2;
		// 估算高度（至少 100px）
		var dropH = 100;
		for (it in m.items)
		{
			if (it.type == Sep) dropH += 9;
			else if (it.type == TextLine) dropH += 20;
			else dropH += ROW_H;
		}
		return {x: dropX, y: dropY, w: DROP_MAX_W, h: dropH};
	}

	public function closeMenu():Void
	{
		clearActiveEditWidget();
		activeMenu = -1;
		lastHoverSwitchIdx = -1;
		dropGroup.visible = false;
		clearDropdownRows();
		hideDescBar();
	}

	// ============ 重建下拉浮窗内容 ============
	function rebuildDropdown():Void
	{
		clearDropdownRows();

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
					var lbl = Language.get(it.labelKey, 'charting');
					var approxW = lbl.length * 8 + 140;
					if (approxW > dropW) dropW = approxW;
					if (dropW > DROP_MAX_W) dropW = DROP_MAX_W;
				}
			}
			else if (it.type == TextLine)
			{
				var txt = Language.get('item_' + it.labelKey, 'charting');
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
				// 动态文本行：内容由 provider 决定（事件名+描述），预留 4 行高度
				totalH += 4 * 14 + 4;
				// 描述信息需要更宽的显示区，事件菜单直接拉到最大宽度
				if (dropW < 380) dropW = 380;
				if (dropW > DROP_MAX_W) dropW = DROP_MAX_W;
			}
			else
			{
				var lbl = Language.get('item_' + it.labelKey, 'charting');
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
				var sepLine = new FlxSprite(Std.int(dropX + 6), Std.int(curY + 3)).makeGraphic(Std.int(dropW - 12), 2, C_SEP);
				sepLine.antialiasing = ClientPrefs.data.antialiasing;
				addToDrop(sepLine, false);
				curY += 9;
				continue;
			}

			if (it.type == Widget || it.type == LabelWidget)
			{
				var wKey = it.type == LabelWidget ? it.widgetKey : it.labelKey;
				var widget:Dynamic = widgetRefs.get(wKey);
				// ★ 构建期统一灰底白字（WeekEditor 验证过的可靠路径：直改 _defaultFormat.color）
				if (it.type == LabelWidget)
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
				var hoverBg:FlxSprite = new FlxSprite().makeGraphic(Std.int(dropW - 4), rowH, C_HOVER);
				hoverBg.visible = false;
				hoverBg.x = Std.int(dropX + 2);
				hoverBg.y = Std.int(curY);
				hoverBg.antialiasing = ClientPrefs.data.antialiasing;
				addToDrop(hoverBg, false);

				if (it.type == Widget)
				{
					// ===== Widget = CheckBox 行：标签（左） + 装饰性勾选框（右） =====
					// 原生 checkbox 只作数据源，隐藏 + 禁用（否则旧 6 列布局位置还残留一个克隆控件）
					try { widget.visible = false; } catch (e:Dynamic) {}
					try { widget.active = false; } catch (e:Dynamic) {}
					var labelForDisplay = translateItemKey(it.labelKey);

					// 勾选态底色（0x268B5CF6 淡紫，勾选行常显）
					var selectedBg:FlxSprite = new FlxSprite().makeGraphic(Std.int(dropW - 4), rowH, C_ROW_SELECTED);
					selectedBg.visible = false;
					selectedBg.x = Std.int(dropX + 2);
					selectedBg.y = Std.int(curY);
					selectedBg.antialiasing = ClientPrefs.data.antialiasing;
					addToDrop(selectedBg, false);

					// 选中装饰条（行左缘 3px A78BFA）
					var selBar:FlxSprite = new FlxSprite().makeGraphic(3, rowH - 6, C_ACCENT_BAR);
					selBar.visible = false;
					selBar.x = Std.int(dropX + 3);
					selBar.y = Std.int(curY + 3);
					selBar.antialiasing = ClientPrefs.data.antialiasing;
					addToDrop(selBar, false);

					// 标签（左）—— 纯文本，勾选状态由右侧勾选框 + 行底色表达
					var lbl = new FlxText(0, 0, Std.int(dropW - 50), labelForDisplay, 12);
					lbl.setFormat(Paths.font(langFont()), 12, C_TEXT_MAIN, LEFT);
					lbl.x = Std.int(dropX + ROW_PAD_X);
					lbl.y = Std.int(curY + (rowH - lbl.height) / 2);
					addToDrop(lbl, false);

					// 装饰性勾选方块（右）—— 白底，颜色由 refreshRowChecked 的 color tint 决定
					var checkIcon:FlxSprite = new FlxSprite().makeGraphic(14, 14, FlxColor.WHITE);
					checkIcon.antialiasing = ClientPrefs.data.antialiasing;
					checkIcon.x = Std.int(dropX + dropW - 18 - ROW_PAD_X);
					checkIcon.y = Std.int(curY + (rowH - 14) / 2);
					addToDrop(checkIcon, false);

					// 勾选标记 √（始终创建；★ 文本内容 + visible 双保险控制：
					//   即使 visible 被 FlxSpriteGroup 级联误改成 true，空文本也不会画出 √）
					var checkTxt = new FlxText(0, 0, 14, '', 11);
					checkTxt.setFormat(Paths.font(langFont()), 11, FlxColor.WHITE, CENTER);
					checkTxt.x = checkIcon.x;
					checkTxt.y = checkIcon.y - 1;
					checkTxt.visible = false;
					addToDrop(checkTxt, false);

					// 快捷键提示（提示文字色，位于勾选方块左侧）
					if (it.shortcut != null && it.shortcut != '')
					{
						var sc = new FlxText(0, 0, 0, it.shortcut, 10);
						sc.setFormat(Paths.font(langFont()), 10, C_TEXT_HINT, RIGHT);
						sc.x = checkIcon.x - 10 - sc.width;
						sc.y = Std.int(curY + (rowH - sc.height) / 2);
						addToDrop(sc, false);
					}

					// 整行 hitbox（最上层，透明）
					var hit = new FlxSprite().makeGraphic(Std.int(dropW - 4), rowH, FlxColor.TRANSPARENT);
					hit.x = Std.int(dropX + 2);
					hit.y = Std.int(curY);
					addToDrop(hit, false);

					var row:DropdownRow = {
						type: it.type,
						labelKey: it.labelKey,
						descKey: it.descKey,
						def: it,
						hit: hit,
						checkIcon: checkIcon,
						checkTxt: checkTxt,
						label: lbl,
						hoverBg: hoverBg,
						selectedBg: selectedBg,
						selBar: selBar,
						labelBase: C_TEXT_MAIN,
						widget: widget
					};
					dropRows.push(row);
					refreshRowChecked(row);
				}
				else // LabelWidget
				{
					// ===== LabelWidget 行：标签（左） + 自绘控件（右） =====
					// ★ 原生 FlxUI 控件只当数据源，绝不渲染（定位被父容器搞坏的老毛病）。
					//   我们直接用 FlxSprite/FlxText 画控件外观，点击也自己判。
					var labelForDisplay = translateLabelKey(it.labelKey);

					// 标签（左，固定宽度 120）—— 次级文字
					var lbl = new FlxText(0, 0, 120, labelForDisplay + ':', 12);
					lbl.setFormat(Paths.font(langFont()), 12, C_TEXT_SEC, LEFT);
					lbl.x = Std.int(dropX + ROW_PAD_X);
					lbl.y = Std.int(curY + (rowH - lbl.height) / 2);
					addToDrop(lbl, false);

					var ctrl:CustomControl = null;
					if (widget != null)
					{
						var ctrlX:Int = Std.int(dropX + ROW_PAD_X + 120 + 6);
						var ctrlY:Int = Std.int(curY + 2);
						var ctrlH:Int = Std.int(Math.max(ROW_H - 4, 18));
						var ctrlW:Int = Std.int(dropX + dropW - ROW_PAD_X - ctrlX);
						if (ctrlW < 40) ctrlW = 40;

						// 底板 + 1px 边框（次要按钮式：模拟边框 0x26FFFFFF）
						var border:FlxSprite = new FlxSprite().makeGraphic(ctrlW, ctrlH, C_SEC_BORDER);
						border.x = ctrlX;
						border.y = ctrlY;
						border.antialiasing = ClientPrefs.data.antialiasing;
						addToDrop(border, false);

						var box:FlxSprite = new FlxSprite().makeGraphic(ctrlW - 2, ctrlH - 2, C_PAGE_BG);
						box.x = ctrlX + 1;
						box.y = ctrlY + 1;
						box.antialiasing = ClientPrefs.data.antialiasing;
						addToDrop(box, false);

						var txt:FlxText = new FlxText(ctrlX + 6, 0, ctrlW - 26, '', 12);
						txt.setFormat(Paths.font(langFont()), 12, C_TEXT_MAIN, LEFT);
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

							var btnPlus:FlxSprite = makeGradSprite(btnW, btnH, C_PRIMARY_G1, C_PRIMARY_G2, false);
							btnPlus.x = btnPlusX;
							btnPlus.y = ctrlY + 1;
							btnPlus.antialiasing = ClientPrefs.data.antialiasing;
							addToDrop(btnPlus, false);
							var plusTxt = new FlxText(0, 0, btnW, '+', 12);
							plusTxt.setFormat(Paths.font(langFont()), 12, FlxColor.WHITE, CENTER);
							plusTxt.x = btnPlusX;
							plusTxt.y = btnPlus.y + (btnH - plusTxt.height) / 2 - 1;
							addToDrop(plusTxt, false);

							var btnMinus:FlxSprite = makeGradSprite(btnW, btnH, C_PRIMARY_G1, C_PRIMARY_G2, false);
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
							arrow.setFormat(Paths.font(langFont()), 10, C_ROW_TEXT_DIM, CENTER);
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
						else
						{
							txt.text = '(?)';
						}

						// 原生控件本体只作数据源，永远隐藏（active=false 防止隐藏时还抢鼠标/键盘事件）
						try { widget.visible = false; } catch (e:Dynamic) {}
						try { widget.active = false; } catch (e:Dynamic) {}
					}

					// hitbox：覆盖整行（自绘控件点击在 handleCustomControlClick 里先消费）
					var hit = new FlxSprite().makeGraphic(Std.int(dropW - ROW_PAD_X * 2 + 2), rowH, FlxColor.TRANSPARENT);
					hit.x = Std.int(dropX + ROW_PAD_X - 2);
					hit.y = Std.int(curY);
					addToDrop(hit, false);

					var row:DropdownRow = {
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
				var txt = Language.get('item_' + it.labelKey, 'charting');
				var isHeader = (it.labelKey == 'help_nav' || it.labelKey == 'help_note' || it.labelKey == 'help_play' || it.labelKey == 'help_edit');
				
				// 文本行（帮助菜单用）：标题 = 主文字（加粗），正文 = 提示文字
				var txtLabel = new FlxText(0, 0, Std.int(dropW - ROW_PAD_X * 2), txt, isHeader ? 12 : 11);
				txtLabel.setFormat(Paths.font(langFont()), isHeader ? 12 : 11, isHeader ? C_TEXT_MAIN : C_TEXT_HINT, LEFT);
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
				// 动态文本行：内容由外部 provider 提供（如事件名+描述），固定占 4 行
				var txtLabel = new FlxText(0, 0, Std.int(dropW - ROW_PAD_X * 2), ' ', 11);
				txtLabel.setFormat(Paths.font(langFont()), 11, C_ROW_TEXT, LEFT);
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
			var labelStr = Language.get('item_' + it.labelKey, 'charting');
			var isDanger = (it.labelKey == 'clear_section' || it.labelKey == 'clear_events' || it.labelKey == 'clear_notes' || it.labelKey == 'del_event');
			var isPrimary = (it.labelKey == 'test_mode');   // 主按钮样式（渐变整行）
			var isLink = (it.labelKey == 'normal_mode');    // 文字链接按钮样式
			var cmdTextColor:Int = isDanger ? C_DANGER : (isLink ? C_ACCENT_BAR : C_TEXT_SEC);
			if (isPrimary) cmdTextColor = 0xFFFFFFFF;

			// hover 背景（先加；主按钮行用提亮层代替）
			var hoverBg:FlxSprite = null;
			if (isPrimary)
			{
				// 主按钮：渐变底常显 + hover 提亮层
				var grad:FlxSprite = makeGradSprite(Std.int(dropW) - 4, ROW_H, C_PRIMARY_G1, C_PRIMARY_G2, true);
				grad.x = Std.int(dropX + 2);
				grad.y = Std.int(curY);
				grad.antialiasing = ClientPrefs.data.antialiasing;
				addToDrop(grad, false);
				hoverBg = new FlxSprite().makeGraphic(Std.int(dropW) - 4, ROW_H, 0x14FFFFFF);
				hoverBg.visible = false;
				hoverBg.x = Std.int(dropX + 2);
				hoverBg.y = Std.int(curY);
				hoverBg.antialiasing = ClientPrefs.data.antialiasing;
				addToDrop(hoverBg, false);
			}
			else
			{
				hoverBg = new FlxSprite().makeGraphic(Std.int(dropW) - 4, ROW_H, C_ROW_HOVER);
				hoverBg.antialiasing = ClientPrefs.data.antialiasing;
				hoverBg.x = Std.int(dropX + 2);
				hoverBg.y = Std.int(curY);
				hoverBg.visible = false;
				addToDrop(hoverBg, false);
			}

			// 标签（后加，渲染在 hoverBg 之上）
			var lbl = new FlxText(0, 0, Std.int(dropW - ROW_PAD_X * 2 - 20), labelStr, 12);
			lbl.setFormat(Paths.font(langFont()), 12, cmdTextColor, LEFT);
			lbl.x = Std.int(dropX + ROW_PAD_X);
			lbl.y = Std.int(curY + 3);
			addToDrop(lbl, false);

			// 快捷键提示（提示文字色，行右缘对齐；主按钮行上用半透明白）
			if (it.shortcut != null && it.shortcut != '')
			{
				var sc = new FlxText(0, 0, 0, it.shortcut, 10);
				sc.setFormat(Paths.font(langFont()), 10, isPrimary ? 0xCCFFFFFF : C_TEXT_HINT, RIGHT);
				sc.x = Std.int(dropX + dropW - ROW_PAD_X - 8);
				sc.y = Std.int(curY + (ROW_H - sc.height) / 2);
				addToDrop(sc, false);
			}

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
				hoverBg: hoverBg,
				labelBase: cmdTextColor
			});
			curY += ROW_H;
		}

		// ★ 第二遍构建完成后，用实际高度创建背景和边框
		var finalH = Std.int(curY - dropY + 2);
		dropBg.makeGraphic(Std.int(dropW), finalH, C_DROP_BG);
		dropBg.antialiasing = ClientPrefs.data.antialiasing;
		dropBg.x = dropX;
		dropBg.y = dropY;
		dropBorder.makeGraphic(Std.int(dropW) + 2, finalH + 2, C_DROP_BORDER);
		dropBorder.antialiasing = ClientPrefs.data.antialiasing;
		dropBorder.x = dropX - 1;
		dropBorder.y = dropY - 1;
	}

	function refreshCheckIcon(icon:FlxText, it:MenuItemDef):Void
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
	 *  @param s      要加入的 sprite 或 widget
	 *  @param keepAlive 若 true，cleanup 时只从 dropGroup 移除但不 destroy（用于 widget）
	 */
	function addToDrop(s:Dynamic, ?keepAlive:Bool):Void
	{
		dropGroup.add(s);
		var k = keepAlive != null ? keepAlive : false;
		dropGroupMembers.push({sprite: s, keepAlive: k});
	}

	function clearDropdownRows():Void
	{
		// ★ 事件描述浮动面板随菜单关闭/切换一起清掉
		hideEventInfoPanel();

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
		lastHoverOpt = [];
	}

	function activateRow(row:DropdownRow):Void
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
					try
					{
						var cb:Dynamic = Reflect.field(row.widget, 'callback');
						if (cb != null)
						{
							// FlxUICheckBox.callback 是 () -> Void，无参
							cb();
						}
					}
					catch (e:Dynamic) {}
					// ★ 勾选态视觉整体刷新（底色/装饰条/方块/√/文字色）
					refreshRowChecked(row);
				}
			case LabelWidget:
				// 交互已由 handleCustomControlClick（自绘控件）接管：
				// stepper 的 [+]/[-]、dropdown 的展开/选值、input 的覆盖层弹出
				// 点标签文字区域 → 不处理，保持菜单打开
		}
	}

	/** ★ 勾选行（Widget/CheckBox）选中态视觉：行底 0x268B5CF6 + 左缘 A78BFA 装饰条
	 *  + 方块主色 + √ + 标签文字 A78BFA（选中）/ 主文字（未选中） */
	function refreshRowChecked(row:DropdownRow):Void
	{
		if (row == null || row.def == null || row.def.type != Widget) return;
		var isChecked = false;
		if (row.widget != null) { try { isChecked = row.widget.checked; } catch(e:Dynamic) {} }
		if (row.selectedBg != null) row.selectedBg.visible = isChecked;
		if (row.selBar != null) row.selBar.visible = isChecked;
		if (row.checkIcon != null) row.checkIcon.color = isChecked ? C_ACCENT : C_BG_2;
		if (row.checkTxt != null)
		{
			row.checkTxt.visible = isChecked;
			row.checkTxt.text = isChecked ? '√' : '';
		}
		if (row.label != null)
		{
			var want:Int = isChecked ? C_ROW_SELECTED_TEXT : C_TEXT_MAIN;
			if (row.label.color != want) row.label.color = want;
			row.labelBase = want;
		}
	}

	// ============ 描述条 ============
	function updateDescBar(row:DropdownRow):Void
	{
		if (row == null || row.def == null || row.def.descKey == null)
		{
			hideDescBar();
			return;
		}
		var txt = Language.get(row.def.descKey, 'charting');
		if (txt == row.def.descKey) { hideDescBar(); return; }
		// Language.get 在开发者模式下找不到 key 时返回 "key (404)"，跟 key 本身不同，会继续显示
		// 这里再拦截一次，避免 (404) 出现在描述条里
		if (txt.indexOf(' (404)') == txt.length - 6) { hideDescBar(); return; }

		descText.text = txt;
		descText.color = C_DESC_TEXT;
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

		descBg.makeGraphic(descW, descH, C_DESC_BG);
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

	// ============ 事件描述浮动面板（事件下拉列表右侧，常驻显示） ============
	/** 更新事件描述浮动面板：hover 索引变化 / 选中变化 / 菜单打开时调用。
	 *  ★ 常驻显示：hover 选项显示 hover 项描述，移出/收起下拉/未展开时显示当前选中事件的描述。 */
	function updateEventInfoPanel(ctrl:CustomControl, hoverIdx:Int):Void
	{
		if (ctrl == null || ctrl.key != 'w_event_type') return;
		// hoverIdx < 0 时 provider 内部会 fallback 到当前选中事件
		showEventInfoPanel(ctrl, hoverIdx);
	}

	/** 显示事件描述浮动面板：位于事件列表/事件类型行右侧，背景与底部描述条同款（C_DESC_BG）且高度弹性。
	 *  内容复用 dyn_event_info provider（"事件名\n描述"）。optIdx < 0 时显示当前选中事件的描述。 */
	function showEventInfoPanel(ctrl:CustomControl, optIdx:Int):Void
	{
		hideEventInfoPanel();
		if (ctrl == null || ctrl.key != 'w_event_type') return;

		// 锚点：下拉展开时用选项面板右侧，未展开时用事件类型控件行右侧
		var anchorX:Float;
		var anchorY:Float;
		var anchorW:Float;
		var anchorH:Float;
		if (ctrl.panelBg != null)
		{
			anchorX = ctrl.panelBg.x;
			anchorY = ctrl.panelBg.y;
			anchorW = ctrl.panelBg.width;
			anchorH = ctrl.panelBg.height;
		}
		else if (ctrl.box != null)
		{
			anchorX = ctrl.box.x;
			anchorY = ctrl.box.y;
			anchorW = ctrl.box.width;
			anchorH = ctrl.box.height;
		}
		else
			return;

		// 从 provider 拿当前事件的名字+描述（hoveringEventIdx 已由 onDropdownHoverOption 更新；
		//  optIdx < 0 时 provider 内部 fallback 到当前选中事件）
		var txt:String = '';
		if (dynTextProviders.exists('dyn_event_info') && dynTextProviders.get('dyn_event_info') != null)
		{
			try { txt = dynTextProviders.get('dyn_event_info')(); } catch (e:Dynamic) { txt = ''; }
		}
		if (txt == null) txt = '';
		var name:String = txt;
		var desc:String = '';
		var nl:Int = txt.indexOf('\n');
		if (nl >= 0)
		{
			name = txt.substr(0, nl);
			desc = txt.substr(nl + 1);
		}
		if (name == '' && desc == '') return;

		// 文本宽度 = 面板宽 - 左右内边距
		var textW:Int = EVENT_INFO_W - EVENT_INFO_PAD * 2;

		eventInfoTitle = new FlxText(0, 0, textW, name, 12);
		eventInfoTitle.setFormat(Paths.font(langFont()), 12, C_TITLE_HOVER, LEFT);
		eventInfoTitle.bold = true;

		eventInfoBody = new FlxText(0, 0, textW, desc, 11);
		eventInfoBody.setFormat(Paths.font(langFont()), 11, C_DESC_TEXT, LEFT);
		eventInfoBody.wordWrap = true;

		// ★ 实测文本高度（openfl getter 内部强制 __updateLayout），背景弹性跟随
		var titleH:Float = 16;
		var bodyH:Float = 0;
		try { titleH = eventInfoTitle.textField.textHeight; } catch (e:Dynamic) {}
		try { bodyH = eventInfoBody.textField.textHeight; } catch (e:Dynamic) {}
		if (bodyH < 0) bodyH = 0;
		var panelH:Int = Std.int(titleH + bodyH + EVENT_INFO_PAD * 2);

		// 位置：锚点右侧；会超出屏幕底部时改为底部对齐，超出右缘时贴右缘
		var px:Float = anchorX + anchorW + 10;
		if (px + EVENT_INFO_W > FlxG.width - 4)
			px = FlxG.width - EVENT_INFO_W - 4;
		var py:Float = anchorY;
		if (py + panelH > FlxG.height - 4)
			py = Math.max(anchorY, anchorY + anchorH - panelH);

		eventInfoBg = new FlxSprite().makeGraphic(EVENT_INFO_W, panelH, C_DESC_BG);
		eventInfoBg.x = Std.int(px);
		eventInfoBg.y = Std.int(py);
		eventInfoBg.antialiasing = ClientPrefs.data.antialiasing;
		addToDrop(eventInfoBg, false);

		eventInfoTitle.x = Std.int(px + EVENT_INFO_PAD);
		eventInfoTitle.y = Std.int(py + EVENT_INFO_PAD - 2);
		addToDrop(eventInfoTitle, false);

		eventInfoBody.x = Std.int(px + EVENT_INFO_PAD);
		eventInfoBody.y = Std.int(py + EVENT_INFO_PAD + titleH - 2);
		addToDrop(eventInfoBody, false);

		eventInfoShown = true;
	}

	function hideEventInfoPanel():Void
	{
		if (!eventInfoShown) return;
		if (eventInfoBg != null) { removeFromDrop(eventInfoBg); eventInfoBg = null; }
		if (eventInfoTitle != null) { removeFromDrop(eventInfoTitle); eventInfoTitle = null; }
		if (eventInfoBody != null) { removeFromDrop(eventInfoBody); eventInfoBody = null; }
		eventInfoShown = false;
	}

	// ============ 销毁 ============
	override function destroy():Void
	{
		super.destroy();
		widgetRefs.clear();
	}
}

// ============ 类型定义 ============
enum ItemType
{
	Sep;
	Cmd;
	Check; // 已废弃，使用 Widget 类型直接嵌入 FlxUICheckBox
	Widget; // 直接嵌入原生控件（FlxUICheckBox 等，无标签）
	LabelWidget; // 带标签的原生控件（FlxUIInputText/FlxUINumericStepper/FlxUIDropDownMenu）
	TextLine; // 纯文本行（帮助菜单用）
	DynText; // 动态文本行（内容由外部注册 provider 提供，如事件名+描述）
}

typedef MenuItemDef =
{
	type:ItemType,
	labelKey:String, // Widget: 用作 widgetKey; LabelWidget/TextLine/Cmd: 用作翻译key
	descKey:String,
	?getChecked:Void->Bool,
	?onCheck:Bool->Void,
	?onClick:Void->Void,
	?widgetKey:String, // LabelWidget 类型时从 widgetRefs 获取控件
	?shortcut:String   // 快捷键提示（行右侧灰色小字）
};

typedef MenuDef =
{
	key:String,
	isTest:Bool,
	items:Array<MenuItemDef>
};

typedef DropdownRow =
{
	type:ItemType,
	labelKey:String,
	descKey:String,
	def:MenuItemDef,
	hit:FlxSprite,
	?checkIcon:Dynamic, // 勾选框背景 FlxSprite（Widget 类型用，toggle 时变色）
	?checkTxt:FlxText,  // √ 文本（始终创建，toggle 时切 visible）
	?label:FlxText,
	?hoverBg:FlxSprite,
	?selectedBg:FlxSprite, // 勾选/选中态底色（0x268B5CF6）
	?selBar:FlxSprite,     // 选中态左侧装饰条（A78BFA）
	?labelBase:Int,        // 行文字默认色（hover 变色后恢复用）
	?widget:Dynamic // Widget/LabelWidget 类型时保存原生控件引用
};

/** 自绘控件（LabelWidget 行）：纯 FlxSprite/FlxText 画外观，点击自己判。
 *  原生 FlxUI 控件只作数据源（stepper 的值、dropdown 的选项、input 的文本），绝不渲染。 */
typedef CustomControl =
{
	key:String,
	ctype:String, // 'stepper' | 'dropdown' | 'input'
	widget:Dynamic,
	box:FlxSprite,
	text:FlxText,
	row:DropdownRow,
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
	?panelRows:Array<DropdownOption>,
	?panelH:Int,
	// 面板拖拽滚动（按下挂起点击，移动超过阈值进入拖拽；释放未拖才执行点击）
	?dragging:Bool,
	?dragY:Float,
	?dragScroll0:Int,
	?dragMoved:Bool,
	?pressIdx:Int,
	// 走马灯（长文本从右往左滚动）
	?isScrolling:Bool,
	?scrollT:Float,
	?scrollDelay:Float
}

/** dropdown 展开面板的单个选项行 */
typedef DropdownOption =
{
	bg:FlxSprite,
	txt:FlxText,
	hit:FlxSprite,
	idx:Int
}
