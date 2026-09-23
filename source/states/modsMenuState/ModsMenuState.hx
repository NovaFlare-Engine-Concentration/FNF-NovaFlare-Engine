package states.modsMenuState;

import flixel.graphics.FlxGraphic;
import flixel.input.touch.FlxTouch;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.util.FlxSpriteUtil;

import general.shapeEx.Rect; // 设置界面 BoolButton 用的圆角矩形控件（详情右上角开关直接复用它）
import general.objects.WindowControlBar;
import general.objects.WindowBarMode;

import options.base.ModSettingsSubState;

import states.mainMenuState.MainMenuState;
import states.titleState.TitleState;
import states.freeplayState.FreeplayState;

/**
 * Mods 菜单（新界面 · 2026-09-19 重写）
 *
 * 由 `NewModsMenuState.htm` 原型 1:1 移植：
 *  - 自绘窗口条（CONSTANT）承载 9 个工具按钮 + [打开 mods 文件夹] + 搜索框 + [退出 mod 列表]，
 *    右侧是引擎原有的 [恢复默认][−][□][×]（窗口条由本状态自建，见 WindowChromeManager.editorScreens）；
 *  - 左侧 30%（0..384）＝ 顶部【已启用】【已禁用】标签 + 列表（pack 图标 | 名称 / 文件夹名）
 *    + 底部 RELOAD / 全部启用 / 全部禁用；
 *  - 右侧 70%（384..1280）＝ 详情（pack 大图 / 名称 / 元信息 / 徽章 / 右上角【启用 禁用】/
 *    可滚动描述 / 重启提示）；
 *  - 所有元素贴屏幕边缘，无外边距；
 *  - 长按 1 秒拖动排序（不足 1 秒松开 = 选中；先移动 = 滚动列表）；
 *  - 超长名字走马灯：只往一个方向滑（32px/s、起点停 0.9s、无缝循环）。Flixel 实现方式是
 *    「文本拼接两份 + 裁剪窗横移（clipRect）」—— 与原型里"两份文本"等价且不会折行；
 *  - pack 显示逻辑与原版完全一致（pack.png → pack-pixel.png → unknownMod.png，150px 切帧）。
 *
 * 保留的旧语义：`isFreePlay`、`waitingToRestart`、`modsList.txt` 读写、`Mods.currentModDirectory`、
 * 空列表每秒轮询、退出时 FlxG.resetGame()、设置按钮打开 ModSettingsSubState。
 */
class ModsMenuState extends MusicBeatState
{
	// ═══════════════ 静态 ═══════════════
	/** 是否从选歌界面进入（退出时回选歌而不是主菜单） */
	public static var isFreePlay:Bool = false;

	/** 长名字走马灯总开关（false = 直接按列宽裁断） */
	public static var marqueeEnabled:Bool = true;

	/**
	 * 文件调试日志开关：仅在 NF_BOOT_MODS=1（调试引导）时写入 <cwd>/modsmenu_debug.log。
	 * 为什么不用 trace()：1145 trace 端口在本机环境下只能收到连接时那句问候，
	 * 之后的 trace 全部到不了客户端（见 _dsh_tools 里的调试记录），
	 * 而调试需要确定性的反馈通道，所以走文件。
	 */
	public static var debugLog:Bool = false;
	static var debugPath:String = 'modsmenu_debug.log';

	public static function dbg(msg:String):Void
	{
		if (!debugLog) return;
		try
		{
			var f = sys.io.File.append(debugPath, false);
			f.writeString('[' + Date.now().toString() + '] ' + msg + '\n');
			f.close();
		}
		catch (e:Dynamic) {}
	}

	// ═══════════════ 指针：鼠标 + 触点统一入口 ═══════════════
	/**
	 * 为什么需要这一层：
	 *  ① 引擎默认把鼠标光标藏起来（`ClientPrefs.needMobileControl` 默认就是 true，
	 *     而 MainMenuState 里写的是 `FlxG.mouse.visible = !needMobileControl`）。
	 *     老代码把 `FlxG.mouse.visible` 当命中开关（`var over = FlxG.mouse.visible && ...`），
	 *     于是手机上（以及桌面开了"虚拟按键"时）**整个自绘界面都点不动** ——
	 *     没有模组时最明显：满屏按钮一个都点不了（用户报的就是这个）。
	 *  ② 移动端引擎自己的按钮走的是 `FlxG.touches`（见 source/mobile/flixel/FlxButton.hx），
	 *     这里一并支持触点，不依赖 OpenFL 的 touch→mouse 合成。
	 * 坐标统一取 `FlxG.camera` 的世界坐标：手机宽屏的黑边由 lime 缩放处理，
	 * `gameX/gameY` 已经算进去了，和自绘界面用的 1280×720 舞台坐标一致。
	 */
	static var ptrP:FlxPoint = FlxPoint.get();

	/** 当前活动触点（按下 / 刚按下 / 刚抬起）；桌面返回 null */
	static function activeTouch():FlxTouch
	{
		for (t in FlxG.touches.list)
			if (t.pressed || t.justPressed || t.justReleased) return t;
		return null;
	}

	public static function pointerPressed():Bool
	{
		var t = activeTouch();
		if (t != null) return t.pressed;
		return (FlxG.mouse != null) && FlxG.mouse.pressed;
	}

	public static function pointerJustPressed():Bool
	{
		var t = activeTouch();
		if (t != null) return t.justPressed;
		return (FlxG.mouse != null) && FlxG.mouse.justPressed;
	}

	public static function pointerJustReleased():Bool
	{
		var t = activeTouch();
		if (t != null) return t.justReleased;
		return (FlxG.mouse != null) && FlxG.mouse.justReleased;
	}

	public static function pointerX():Float
	{
		var t = activeTouch();
		if (t != null) return t.getWorldPosition(FlxG.camera, ptrP).x;
		return (FlxG.mouse != null) ? FlxG.mouse.viewX : 0;
	}

	public static function pointerY():Float
	{
		var t = activeTouch();
		if (t != null) return t.getWorldPosition(FlxG.camera, ptrP).y;
		return (FlxG.mouse != null) ? FlxG.mouse.viewY : 0;
	}

	/** 指针是否落在矩形内（所有悬停/命中判定统一走这里） */
	public static function pointerOver(px:Float, py:Float, pw:Float, ph:Float):Bool
	{
		var t = activeTouch();
		if (t != null)
		{
			var p = t.getWorldPosition(FlxG.camera, ptrP);
			return p.x >= px && p.x < px + pw && p.y >= py && p.y < py + ph;
		}
		if (FlxG.mouse == null) return false;
		// 没有光标时，"正在按 / 刚按下"也算命中（桌面关掉光标同样能用）
		if (!FlxG.mouse.visible && !FlxG.mouse.pressed && !FlxG.mouse.justPressed) return false;
		return FlxG.mouse.viewX >= px && FlxG.mouse.viewX < px + pw && FlxG.mouse.viewY >= py && FlxG.mouse.viewY < py + ph;
	}

	/** 滚轮（移动端没有滚轮 → 0） */
	public static function pointerWheel():Int
	{
		return (FlxG.mouse != null) ? FlxG.mouse.wheel : 0;
	}

	// ═══════════════ 布局常量（1280×720，全部贴边） ═══════════════
	public static inline var BAR_H:Int = 36;
	public static inline var LEFT_W:Int = 384; // 30%
	public static inline var TAB_H:Int = 40;
	public static inline var FOOT_H:Int = 40;
	public static inline var ROW_H:Int = 56;
	public static inline var LIST_TOP:Int = BAR_H + TAB_H; // 76
	public static inline var LIST_H:Int = 720 - LIST_TOP - FOOT_H; // 604
	public static inline var RIGHT_X:Int = LEFT_W;
	public static inline var RIGHT_W:Int = 1280 - LEFT_W; // 896
	public static inline var DESC_BASE_Y:Int = BAR_H + 170; // 描述正文的基准 y

	// 交互常量
	static inline var LONG_PRESS:Float = 1.0; // 长按判定（秒）
	static inline var SCROLL_TOL:Float = 18; // 先移动超过这个距离 = 拖动列表滚动（不再长按）
	public static inline var MARQ_SPEED:Float = 32; // 走马灯速度 px/s（对齐 CharacterEditorMenuBar）
	public static inline var MARQ_HOLD:Float = 0.9; // 走马灯起点停留秒数
	public static inline var MARQ_END_HOLD:Float = 0.9; // 滑到底后的停留秒数

	// 滚动条
	static inline var SB_W:Int = 6; // 滑块宽
	static inline var SB_PAD:Int = 3; // 距列表右边缘
	static inline var SB_MIN:Float = 36; // 滑块最小高度

	// 颜色（NovaFlare 深色规范）
	public static inline var C_TEXT:FlxColor = 0xFFEDEFF7;
	public static inline var C_DIM:FlxColor = 0xFF9BA1B8;
	public static inline var C_HINT:FlxColor = 0xFF6F7690;
	public static inline var C_ACCENT:FlxColor = 0xFF96B5FF;
	public static inline var C_OK:FlxColor = 0xFF22C55E;
	public static inline var C_WARN:FlxColor = 0xFFF59E0B;
	public static inline var C_DANGER:FlxColor = 0xFFEF4444;
	static inline var C_PANEL:FlxColor = 0x66090A0F;
	static inline var C_BAR:FlxColor = 0xF20E0F15;
	// 行底色：白底靠 alpha 控制深浅（选中 ~0.20 / 未选中 ~0.03）
	public static inline var ROW_BG_A:Float = 0.03;
	public static inline var ROW_SEL_A:Float = 0.20;

	// ═══════════════ 数据 ═══════════════
	var modsList:ModsList = null;
	var rows:Array<ModRow> = [];
	var sel:Int = 0;
	var zone:Int = 0; // 0 = 列表 / 1 = 工具条
	var toolSel:Int = 0;
	var filter:Int = 0; // 0 = 已启用 / 1 = 已禁用 / 2 = 全部（再点当前标签 = 切到全部）
	var query:String = '';
	var dirty:Int = 0;
	var waitingToRestart:Bool = false; // 原字段：有改动 → 退出时整局重启
	var startMod:String = null;

	// 滚动
	var scrollY:Float = 0;
	var holdTime:Float = 0;

	// 长按 / 拖拽
	var pressIdx:Int = -1;
	var pressTimer:Float = 0;
	var pressMouseX:Float = 0;
	var pressMouseY:Float = 0;
	var pressMoved:Bool = false;
	var dragging:Bool = false;
	var dragSlot:Int = -1;
	var dragOffsetY:Float = 0; // 被拖行相对光标的偏移（跟手）
	var scrollDrag:Bool = false; // 先移动 = 拖动列表滚动
	var scrollDragBase:Float = 0; // 进入拖动滚动时的 scrollY
	var scrollDragMouseY:Float = 0;
	var holdBar:FlxSprite; // 长按进度条（原型 .bl-row.pressing::after）
	var pressHintBg:FlxSprite; // 光标旁提示气泡
	var pressHintTxt:FlxText;

	// 滚动条
	var sbTrack:FlxSprite;
	var sbThumb:FlxSprite;
	var sbThumbH:Float = SB_MIN;
	var sbDrag:Bool = false;
	var sbDragOfs:Float = 0;
	var dbgSb:String = '';

	// 相机
	var camHUD:FlxCamera;
	var listCam:FlxCamera;
	var camTop:FlxCamera;

	// 背景
	var bg:FlxSprite;

	// 窗口条
	var chrome:WindowControlBar = null;
	var barBg:FlxSprite;
	var barLine:FlxSprite;
	var tools:Array<BarButton> = [];
	var btnFolder:FlatButton = null;
	var btnExit:FlatButton = null;
	var searchBox:PsychUIInputText = null;
	var searchBg:FlxSprite = null;
	var searchPlaceholder:FlxText = null;
	var hintTxt:FlxText;
	var hintDefault:String = '';
	var lastBarW:Int = -1;

	// 左栏
	var tabOn:TabButton = null;
	var tabOff:TabButton = null;
	var tabLine:FlxSprite;
	var tabBottom:FlxSprite;
	var listBg:FlxSprite;
	var listDiv:FlxSprite;
	var footTop:FlxSprite;
	/** 空状态（没有任何模组）：常规界面整片收起，只留空状态卡片 */
	var emptyMode:Bool = false;
	var dropLine:FlxSprite;
	var filterEmptyTxt:FlxText;
	var footReload:FlatButton = null;
	var footEnableAll:FlatButton = null;
	var footDisableAll:FlatButton = null;

	// 右栏
	var detailBg:FlxSprite;
	var detailLine:FlxSprite;
	var dIcon:FlxSprite;
	var dName:FlxText; // 23px（对齐原型 #dName），原先误用 Alphabet → 字体过大
	var dMetaTxt:FlxText;
	var dBadgeTxt:FlxText;
	var dBadgeBg:FlxSprite;
	var dToggle:SwitchButton = null;
	var dDescLabel:FlxText;
	var dDesc:FlxText;
	var dDescClip:FlxRect = null;
	var descScrollY:Float = 0;
	var descMaxScroll:Float = 0;
	var descDragging:Bool = false;
	var descDragY:Float = 0;
	var restartHint:FlxText;
	var footNote:FlxText;

	// 空状态 / 确认 / 提示
	var emptyGfx:Array<FlxSprite> = [];
	var emptyTitle:FlxText;
	var emptyBody:FlxText;
	var emptyScan:FlxText;
	var emptyEgg:FlxText;
	var emptyFolderBtn:FlatButton = null;
	var emptyExitBtn:FlatButton = null;
	var scanTimer:Float = 0;
	var noModsSine:Float = 0;

	var maskSpr:FlxSprite;
	var confirmBg:FlxSprite;
	var confirmTitle:FlxText;
	var confirmBody:FlxText;
	var confirmYes:FlatButton = null;
	var confirmStay:FlatButton = null;

	var toastBg:FlxSprite;
	var toastTxt:FlxText;
	var toastTimer:Float = 0;

	// 每帧统一驱动悬停/点击
	public var allButtons:Array<FlatButton> = [];
	var bgColorTween:FlxTween = null;

	public function new(startMod:String = null)
	{
		this.startMod = startMod;
		super();
	}

	// ══════════════════════════════════════════════════════════════════════
	// create
	// ══════════════════════════════════════════════════════════════════════
	override function create()
	{
		Paths.clearStoredMemory();
		Paths.clearUnusedMemory();
		persistentUpdate = false;

		modsList = Mods.parseList();
		Mods.currentModDirectory = modsList.all[0] != null ? modsList.all[0] : '';

		#if DISCORD_ALLOWED
		DiscordClient.changePresence("In the Menus", null);
		#end

		// 背景（原版：menuDesat + 当前 mod 的 pack.color 补间）
		bg = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.color = 0xFF665AFF;
		bg.antialiasing = ClientPrefs.data.antialiasing;
		bg.screenCenter();
		add(bg);

		super.create(); // ★ 必须先 super：initPsychCamera() 会重置相机列表

		camHUD = new FlxCamera();
		camHUD.bgColor.alpha = 0;
		FlxG.cameras.add(camHUD, false);

		// 列表专用相机：视口 = 列表矩形 → 天然完成"裁剪 + 滚动"
		listCam = new FlxCamera(0, LIST_TOP, LEFT_W, LIST_H);
		listCam.bgColor.alpha = 0;
		FlxG.cameras.add(listCam, false);

		// 顶层相机（在 listCam 之后加入 → 永远画在列表之上）：
		// 滚动条、长按提示气泡、确认框、toast 都放这里，否则会被列表行盖住
		camTop = new FlxCamera();
		camTop.bgColor.alpha = 0;
		FlxG.cameras.add(camTop, false);

		buildChrome();
		buildLeftPanel();
		buildDetailPanel();
		buildRows();
		buildEmptyState();
		buildConfirmOverlay();
		buildToast();

		// 插入指示线要在列表行之上（同一相机内后加 = 后画）
		remove(dropLine, false);
		add(dropLine);

		sel = 0;
		if (startMod != null)
		{
			for (i in 0...modsList.all.length)
				if (modsList.all[i] == startMod) sel = i;
		}

		FlxG.autoPause = false; // 空列表时要能"边开着菜单边往 mods/ 丢文件"
		lastBarW = -1;
		relayoutBar();
		refreshAll();
		updateEmptyStateVisibility();

		if (Sys.getEnv('NF_BOOT_MODS') == '1') debugLog = true;
		dbg('=== ModsMenuState.create: mods=' + modsList.all.length + ' enabled=' + modsList.enabled.length
			+ ' disabled=' + modsList.disabled.length + ' rows=' + rows.length + ' sel=' + sel
			+ ' screen=' + FlxG.width + 'x' + FlxG.height
			+ ' list=(0,' + LIST_TOP + ',' + LEFT_W + ',' + LIST_H + ')'
			+ ' exitBtnX=' + (btnExit != null ? Std.int(btnExit.x) : -1)
			+ ' chrome=' + (chrome != null) + ' ===');
		dbg('  buttons=' + allButtons.length + ' tools=' + tools.length);
	}

	// ══════════════════════════════════════════════════════════════════════
	// 构建：窗口条
	// ══════════════════════════════════════════════════════════════════════
	function buildChrome()
	{
		barBg = new FlxSprite(0, 0).makeGraphic(1280, BAR_H, C_BAR);
		addHud(barBg);

		barLine = new FlxSprite(0, BAR_H - 1).makeGraphic(1280, 1, 0x22FFFFFF);
		addHud(barLine);

		// 9 个工具按钮（原版 modsMenuButtons.png 帧：0=置顶 1=置底 4=上移 5=下移 2=上一个 3=下一个 6=设置 7=开关 8=退出）
		var frames:Array<Int> = [0, 1, 4, 5, 2, 3, 6, 7, 8];
		var keys:Array<String> = ['toolTop', 'toolBottom', 'toolUp', 'toolDown', 'toolPrev', 'toolNext', 'toolSettings', 'toolToggle', 'toolExit'];
		for (i in 0...frames.length)
		{
			var b = new BarButton(12 + i * 29, 5, frames[i], keys[i], function() toolAction(i));
			b.addTo(this, camHUD);
			tools.push(b);
		}

		btnFolder = new FlatButton(0, 5, Language.get('openFolderShort', 'mods'), function() openModsFolder());
		btnFolder.dbgName = 'bar:folder';
		btnFolder.addTo(this, camHUD);
		btnExit = new FlatButton(0, 5, Language.get('exitListShort', 'mods'), function() exitMenu());
		btnExit.dbgName = 'bar:exit';
		btnExit.addTo(this, camHUD);

		// 搜索框（引擎自绘 PsychUIInputText —— 与选歌界面同一个控件）
		searchBg = FlxSpriteUtil.drawRoundRect(new FlxSprite(0, 5).makeGraphic(196, 26, FlxColor.TRANSPARENT), 0, 0, 196, 26, 7, 7, 0xFF06070B);
		searchBg.alpha = 0.9;
		addHud(searchBg);

		searchBox = new PsychUIInputText(0, 10, 176, '', 12);
		searchBox.bg.visible = false;
		searchBox.behindText.alpha = 0;
		searchBox.textObj.font = Paths.font(Language.get('fontName', 'main') + '.ttf');
		searchBox.textObj.antialiasing = ClientPrefs.data.antialiasing;
		searchBox.textObj.color = C_TEXT;
		searchBox.caret.color = 0x727E7E7E;
		searchBox.onChange = function(old:String, cur:String)
		{
			query = (cur == null) ? '' : cur;
			if (searchPlaceholder != null) searchPlaceholder.visible = (query.length < 1);
			scrollY = 0;
			var vis = visibleIndices();
			if (vis.length > 0 && vis.indexOf(sel) < 0) sel = vis[0];
			refreshList();
			refreshDetail();
		}
		searchBox.unfocus = function()
		{
			if (searchPlaceholder != null) searchPlaceholder.visible = (query.length < 1);
		}
		searchBox.cameras = [camHUD];
		searchBox.scrollFactor.set();
		add(searchBox);

		searchPlaceholder = new FlxText(0, 12, 0, Language.get('search', 'mods'), 12);
		searchPlaceholder.setFormat(Paths.font(Language.get('fontName', 'main') + '.ttf'), 12, C_HINT);
		addHud(searchPlaceholder);

		hintDefault = Language.get('hintBar', 'mods');
		hintTxt = new FlxText(288, 11, 400, hintDefault, 11);
		hintTxt.setFormat(Paths.font(Language.get('fontName', 'main') + '.ttf'), 11, C_HINT);
		addHud(hintTxt);

		// 引擎自绘窗口条（CONSTANT：分隔线 + 图标标题 + [恢复默认][−][□][×]）
		#if (cpp && windows)
		chrome = new WindowControlBar(WindowBarMode.CONSTANT);
		chrome.scrollFactor.set();
		chrome.cameras = [camHUD];
		add(chrome);
		#end
	}

	function toolAction(i:Int):Void
	{
		switch (i)
		{
			case 0: moveModToPosition(null, 0);
			case 1: moveModToPosition(null, modsList.all.length - 1);
			case 2: moveModToPosition(null, sel - 1);
			case 3: moveModToPosition(null, sel + 1);
			case 4: selectStep(-1);
			case 5: selectStep(1);
			case 6: openModSettings();
			case 7: toggleMod(sel);
			case 8: exitMenu();
		}
	}

	/** 按窗口宽度重排窗口条上的自定义控件（右边锚定 bar.titleAnchorX() - 11，避开拖窗区） */
	function relayoutBar()
	{
		lastBarW = FlxG.width;
		var w:Float = FlxG.width;

		barBg.makeGraphic(Std.int(w), BAR_H, C_BAR);
		barLine.makeGraphic(Std.int(w), 1, 0x22FFFFFF);
		barLine.x = 0;
		barLine.y = BAR_H - 1;

		var right:Float = w - 184 - 16 - titleWidth() - 22 - 11 - 12;
		if (right > w - 300) right = w - 300;
		if (right < 640) right = 640;

		btnExit.setX(right - btnExit.w);
		btnFolder.setX(btnExit.x - 8 - btnFolder.w);
		searchBg.x = btnFolder.x - 8 - 196;
		searchBox.x = searchBg.x + 10;
		searchPlaceholder.x = searchBg.x + 10;
		hintTxt.x = 288;
		// ★ 提示栏宽度按实际可用空间给：太窄就换短文案，绝不让文字被裁断
		var avail:Float = Math.max(100, searchBg.x - 300);
		hintTxt.fieldWidth = avail;
		hintTxt.text = hintFor(avail);
	}

	/** 按可用宽度挑提示文案（长版放不下就用短版） */
	function hintFor(avail:Float):String
	{
		if (dirty > 0) return fmt(Language.get('dirty', 'mods'), 'n', Std.string(dirty));
		var full:String = Language.get('hintBar', 'mods');
		if (full.length * 11 <= avail) return full;
		var short:String = Language.get('hintBarShort', 'mods');
		if (short.length * 11 <= avail) return short;
		return short;
	}

	function titleWidth():Float
	{
		#if (cpp && windows)
		if (chrome != null) return chrome.titleBlockWidth();
		#end
		return 150; // 非 windows 目标没有自绘条
	}

	// ══════════════════════════════════════════════════════════════════════
	// 构建：左栏
	// ══════════════════════════════════════════════════════════════════════
	function buildLeftPanel()
	{
		listBg = new FlxSprite(0, BAR_H).makeGraphic(LEFT_W, 720 - BAR_H - FOOT_H, 0x55101319);
		addHud(listBg);

		listDiv = new FlxSprite(LEFT_W - 1, BAR_H).makeGraphic(1, 720 - BAR_H, 0x22FFFFFF);
		addHud(listDiv);

		// 筛选/搜索后没有可见行时的占位文案
		filterEmptyTxt = new FlxText(0, LIST_TOP + 40, LEFT_W, Language.get('filterNone', 'mods'), 12);
		filterEmptyTxt.setFormat(Paths.font(Language.get('fontName', 'main') + '.ttf'), 12, C_HINT, CENTER);
		addHud(filterEmptyTxt);
		filterEmptyTxt.visible = false;

		// 标签栏：整块扁平填充 + 状态圆点 + 数字胶囊 + 底部强调线（原型 .tab / .tab.on::after）
		tabOn = new TabButton(0, BAR_H, Std.int(LEFT_W / 2), TAB_H, 'tabEnabled', C_OK, function() setFilter(0));
		tabOn.dbgName = 'tab:enabled';
		tabOn.addTo(this, camHUD);

		tabOff = new TabButton(Std.int(LEFT_W / 2), BAR_H, Std.int(LEFT_W / 2), TAB_H, 'tabDisabled', C_DANGER, function() setFilter(1));
		tabOff.dbgName = 'tab:disabled';
		tabOff.addTo(this, camHUD);

		tabLine = new FlxSprite(0, BAR_H + TAB_H - 2).makeGraphic(Std.int(LEFT_W / 2), 2, C_ACCENT, true);
		addHud(tabLine);

		tabBottom = new FlxSprite(0, BAR_H + TAB_H - 1).makeGraphic(LEFT_W, 1, 0x22FFFFFF, true);
		addHud(tabBottom);

		// 拖拽插入指示线（挂在列表相机里 → 随滚动一起移动；不能设 scrollFactor(0,0)，否则不跟滚）
		dropLine = new FlxSprite(0, 0).makeGraphic(LEFT_W, 2, C_ACCENT, true);
		dropLine.cameras = [listCam];
		dropLine.visible = false;
		add(dropLine);

		// 长按进度条（按住时从行左侧长出来的下划线）
		holdBar = new FlxSprite(0, 0).makeGraphic(1, 2, C_ACCENT, true);
		addHud(holdBar);
		holdBar.visible = false;

		// 滚动条（原型 #listScroll 的 ::-webkit-scrollbar：轨道透明、滑块强调色）
		var trackH:Int = LIST_H - 8;
		sbTrack = new FlxSprite(LEFT_W - SB_W - SB_PAD, LIST_TOP + 4).makeGraphic(SB_W, trackH, 0x14FFFFFF, true);
		sbTrack.alpha = 0.9;
		addTop(sbTrack);
		sbThumb = new FlxSprite(sbTrack.x, sbTrack.y).makeGraphic(SB_W, Std.int(SB_MIN), 0x4296B5FF, true);
		// ★ origin 归零：Flixel 默认绕中心缩放，滑块会往上/下溢出到标签栏外面
		sbThumb.origin.set(0, 0);
		addTop(sbThumb);
		sbTrack.visible = sbThumb.visible = false;

		// 光标旁提示气泡（原型 #pressHint）
		pressHintBg = FlxSpriteUtil.drawRoundRect(new FlxSprite(0, 0).makeGraphic(1, 1, FlxColor.TRANSPARENT, true), 0, 0, 1, 1, 8, 8, 0xF208090D);
		pressHintTxt = new FlxText(0, 0, 0, '', 11);
		pressHintTxt.setFormat(Paths.font(Language.get('fontName', 'main') + '.ttf'), 11, C_TEXT);
		addTop(pressHintBg);
		addTop(pressHintTxt);
		pressHintBg.visible = pressHintTxt.visible = false;

		// 底部三个原版按钮
		var bw = Std.int(LEFT_W / 3);
		footReload = new FlatButton(0, 720 - FOOT_H, Language.get('reload', 'mods'), function() reload());
		footReload.setSize(bw, FOOT_H);
		footReload.flat = true;
		footReload.dbgName = 'foot:reload';
		footReload.addTo(this, camHUD);

		footEnableAll = new FlatButton(bw, 720 - FOOT_H, Language.get('enableAll', 'mods'), function() setAll(true));
		footEnableAll.setSize(bw, FOOT_H);
		footEnableAll.flat = true;
		footEnableAll.dbgName = 'foot:enableAll';
		footEnableAll.addTo(this, camHUD);

		footDisableAll = new FlatButton(bw * 2, 720 - FOOT_H, Language.get('disableAll', 'mods'), function() setAll(false));
		footDisableAll.setSize(bw, FOOT_H);
		footDisableAll.flat = true;
		footDisableAll.dbgName = 'foot:disableAll';
		footDisableAll.addTo(this, camHUD);

		footTop = new FlxSprite(0, 720 - FOOT_H).makeGraphic(LEFT_W, 1, 0x22FFFFFF);
		addHud(footTop);
	}

	// ══════════════════════════════════════════════════════════════════════
	// 构建：右栏详情
	// ══════════════════════════════════════════════════════════════════════
	function buildDetailPanel()
	{
		detailBg = new FlxSprite(RIGHT_X, BAR_H).makeGraphic(RIGHT_W, 720 - BAR_H, C_PANEL);
		addHud(detailBg);

		dIcon = new FlxSprite(RIGHT_X + 20, BAR_H + 18);
		dIcon.antialiasing = ClientPrefs.data.antialiasing;
		addHud(dIcon);

		dName = new FlxText(RIGHT_X + 136, BAR_H + 30, 0, "", 23);
		dName.setFormat(Paths.font(Language.get('fontName', 'main') + '.ttf'), 23, C_TEXT);
		dName.bold = true;
		dName.wordWrap = false;
		addHud(dName);

		dMetaTxt = new FlxText(RIGHT_X + 136, BAR_H + 70, RIGHT_W - 200, "", 12);
		dMetaTxt.setFormat(Paths.font(Language.get('fontName', 'main') + '.ttf'), 12, C_DIM);
		addHud(dMetaTxt);

		dBadgeBg = new FlxSprite(RIGHT_X + 136, BAR_H + 92).makeGraphic(1, 24, 0x33FFFFFF);
		dBadgeBg.visible = false;
		addHud(dBadgeBg);

		dBadgeTxt = new FlxText(RIGHT_X + 146, BAR_H + 96, 0, "", 12);
		dBadgeTxt.setFormat(Paths.font(Language.get('fontName', 'main') + '.ttf'), 12, C_TEXT);
		addHud(dBadgeTxt);

		// 右上角【启用 / 禁用】：宽度自适应内容，右对齐到面板内边距
		dToggle = new SwitchButton(RIGHT_X + RIGHT_W - 24 - 200, BAR_H + 16, function() toggleMod(sel));
		dToggle.addTo(this, camHUD);
		dToggle.setRight(RIGHT_X + RIGHT_W - 24);

		detailLine = new FlxSprite(RIGHT_X, BAR_H + 132).makeGraphic(RIGHT_W, 1, 0x22FFFFFF);
		addHud(detailLine);

		dDescLabel = new FlxText(RIGHT_X + 20, BAR_H + 148, 0, Language.get('descLabel', 'mods'), 11);
		dDescLabel.setFormat(Paths.font(Language.get('fontName', 'main') + '.ttf'), 11, C_HINT);
		addHud(dDescLabel);

		dDesc = new FlxText(RIGHT_X + 20, DESC_BASE_Y, RIGHT_W - 56, "", 13);
		dDesc.setFormat(Paths.font(Language.get('fontName', 'main') + '.ttf'), 13, 0xFFD7DBE6);
		dDesc.wordWrap = true;
		addHud(dDesc);
		dDescClip = new FlxRect(0, 0, RIGHT_W - 56, 720 - DESC_BASE_Y - 60);
		dDesc.clipRect = dDescClip;

		restartHint = new FlxText(RIGHT_X + 20, 720 - 32, 0, Language.get('restartHint', 'mods'), 11);
		restartHint.setFormat(Paths.font(Language.get('fontName', 'main') + '.ttf'), 11, 0xFFF4C46B);
		addHud(restartHint);

		footNote = new FlxText(RIGHT_X + RIGHT_W - 24, 720 - 32, 0, "", 11);
		footNote.setFormat(Paths.font(Language.get('fontName', 'main') + '.ttf'), 11, C_HINT);
		addHud(footNote);
	}

	// ══════════════════════════════════════════════════════════════════════
	// 构建：列表行
	// ══════════════════════════════════════════════════════════════════════
	function buildRows()
	{
		rows = [];
		for (i in 0...modsList.all.length)
		{
			var r = new ModRow(modsList.all[i], LEFT_W);
			r.addTo(this, listCam);
			rows.push(r);
		}
	}

	// ══════════════════════════════════════════════════════════════════════
	// 构建：空状态 / 确认层 / toast
	// ══════════════════════════════════════════════════════════════════════
	function buildEmptyState()
	{
		var bgS = new FlxSprite(0, BAR_H).makeGraphic(1280, 720 - BAR_H, 0x99090A0F);
		bgS.cameras = [camHUD];
		bgS.scrollFactor.set();
		add(bgS);
		emptyGfx.push(bgS);

		var box = FlxSpriteUtil.drawRoundRect(new FlxSprite(0, 0).makeGraphic(88, 88, FlxColor.TRANSPARENT), 0, 0, 88, 88, 24, 24, 0x1A96B5FF);
		box.x = 640 - 44;
		box.y = 250;
		addHud(box);
		emptyGfx.push(box);

		emptyTitle = new FlxText(0, 360, 1280, Language.get('emptyTitle', 'mods'), 24);
		emptyTitle.setFormat(Paths.font(Language.get('fontName', 'main') + '.ttf'), 24, C_TEXT, CENTER);
		addHud(emptyTitle);
		emptyGfx.push(emptyTitle);

		emptyBody = new FlxText(320, 398, 640, Language.get('emptyBody1', 'mods') + '  mods/  ' + Language.get('emptyBody2', 'mods'), 13);
		emptyBody.setFormat(Paths.font(Language.get('fontName', 'main') + '.ttf'), 13, C_DIM, CENTER);
		emptyBody.wordWrap = true;
		addHud(emptyBody);
		emptyGfx.push(emptyBody);

		emptyEgg = new FlxText(0, 428, 1280, '', 13);
		emptyEgg.setFormat(Paths.font(Language.get('fontName', 'main') + '.ttf'), 13, 0xFFFF90DC, CENTER);
		addHud(emptyEgg);
		emptyGfx.push(emptyEgg);

		emptyFolderBtn = new FlatButton(0, 0, Language.get('openFolderShort', 'mods'), function() openModsFolder());
		emptyFolderBtn.setSize(180, 40);
		emptyFolderBtn.dbgName = 'empty:folder';
		emptyFolderBtn.addTo(this, camHUD);
		emptyExitBtn = new FlatButton(0, 0, Language.get('exitListShort', 'mods'), function() exitMenu());
		emptyExitBtn.setSize(160, 40);
		emptyExitBtn.dbgName = 'empty:exit';
		emptyExitBtn.addTo(this, camHUD);

		emptyScan = new FlxText(0, 496, 1280, Language.get('scanning', 'mods'), 12);
		emptyScan.setFormat(Paths.font(Language.get('fontName', 'main') + '.ttf'), 12, C_HINT, CENTER);
		addHud(emptyScan);
		emptyGfx.push(emptyScan);

		if (FlxG.random.bool(0.1)) emptyEgg.text = 'BITCH.'; // 原版彩蛋保留
	}

	function buildConfirmOverlay()
	{
		maskSpr = new FlxSprite(0, 0).makeGraphic(1280, 720, 0xA6050509, true);
		addTop(maskSpr);

		confirmBg = FlxSpriteUtil.drawRoundRect(new FlxSprite(0, 0).makeGraphic(460, 210, FlxColor.TRANSPARENT, true), 0, 0, 460, 210, 14, 14, 0xFF14141B);
		confirmBg.x = 640 - 230;
		confirmBg.y = 360 - 105;
		addTop(confirmBg);

		confirmTitle = new FlxText(confirmBg.x, confirmBg.y + 26, 460, Language.get('exitTitle', 'mods'), 18);
		confirmTitle.setFormat(Paths.font(Language.get('fontName', 'main') + '.ttf'), 18, C_TEXT, CENTER);
		addTop(confirmTitle);

		confirmBody = new FlxText(confirmBg.x + 24, confirmBg.y + 66, 412, Language.get('exitBody', 'mods'), 12);
		confirmBody.setFormat(Paths.font(Language.get('fontName', 'main') + '.ttf'), 12, C_DIM, CENTER);
		confirmBody.wordWrap = true;
		addTop(confirmBody);

		confirmYes = new FlatButton(confirmBg.x + 24, confirmBg.y + 150, Language.get('restartNow', 'mods'), function() doRestartNow());
		confirmYes.setSize(200, 42);
		confirmYes.dbgName = 'confirm:restart';
		confirmYes.highlight = true;
		confirmYes.addTo(this, camTop);

		confirmStay = new FlatButton(confirmBg.x + 236, confirmBg.y + 150, Language.get('stayHere', 'mods'), function() hideConfirm());
		confirmStay.setSize(200, 42);
		confirmStay.dbgName = 'confirm:stay';
		confirmStay.addTo(this, camTop);

		hideConfirm();
	}

	function buildToast()
	{
		toastBg = new FlxSprite(0, 0).makeGraphic(360, 32, FlxColor.TRANSPARENT, true);
		addTop(toastBg);
		toastTxt = new FlxText(0, 0, 360, '', 12);
		toastTxt.setFormat(Paths.font(Language.get('fontName', 'main') + '.ttf'), 12, C_TEXT, CENTER);
		addTop(toastTxt);
		toastBg.visible = false;
		toastTxt.visible = false;
	}

	inline function addHud(s:FlxSprite):Void
	{
		s.cameras = [camHUD];
		s.scrollFactor.set();
		add(s);
	}

	/** 画在列表之上的元素（滚动条 / 提示气泡 / 确认框 / toast） */
	inline function addTop(s:FlxSprite):Void
	{
		s.cameras = [camTop];
		s.scrollFactor.set();
		add(s);
	}

	// ══════════════════════════════════════════════════════════════════════
	// 刷新
	// ══════════════════════════════════════════════════════════════════════
	inline function isEnabled(m:ModRow):Bool
	{
		return !modsList.disabled.contains(m.folder);
	}

	function passFilter(m:ModRow):Bool
	{
		if (filter == 0 && !isEnabled(m)) return false;
		if (filter == 1 && isEnabled(m)) return false;
		if (query.length > 0)
		{
			var q = query.toLowerCase();
			if (m.name.toLowerCase().indexOf(q) < 0 && m.folder.toLowerCase().indexOf(q) < 0) return false;
		}
		return true;
	}

	function visibleIndices():Array<Int>
	{
		var vis:Array<Int> = [];
		for (i in 0...rows.length) if (passFilter(rows[i])) vis.push(i);
		return vis;
	}

	function listContentHeight():Float
	{
		return visibleIndices().length * ROW_H;
	}

	function refreshAll()
	{
		refreshTabs();
		refreshList();
		refreshDetail();
		refreshFooter();
		refreshDirty();
	}

	function refreshTabs()
	{
		var on = 0;
		for (m in modsList.all) if (!modsList.disabled.contains(m)) on++;
		var off = modsList.all.length - on;
		tabOn.setCount(on);
		tabOff.setCount(off);
		tabOn.setActive(filter == 0);
		tabOff.setActive(filter == 1);
		tabLine.visible = (filter != 2) && !emptyMode;
		tabLine.x = (filter == 1) ? LEFT_W / 2 : 0;
		dbg('tabs on=' + on + ' off=' + off + ' filter=' + filter + ' underline=' + (tabLine.visible ? Std.int(tabLine.x) + '..' + Std.int(tabLine.x + tabLine.width) : 'hidden')
			+ ' tabOn(count=' + on + ') tabOff(count=' + off + ')');
	}

	function refreshList()
	{
		var y = 0.0;
		for (i in 0...rows.length)
		{
			var r = rows[i];
			var vis = passFilter(r);
			r.setEnabledFlag(isEnabled(r));
			r.setVisible(vis);
			if (!vis) continue;
			r.index = i;
			r.setY(y);
			r.setSelected(i == sel && zone == 0);
			y += ROW_H;
		}

		// 筛选/搜索后一行都没有 → 显示占位文案（否则左栏会是一片空白）
		if (filterEmptyTxt != null)
		{
			var msg = (query.length > 0) ? Language.get('searchNone', 'mods') : Language.get('filterNone', 'mods');
			filterEmptyTxt.text = ModsMenuState.fmt(msg, 'q', query);
			filterEmptyTxt.visible = (modsList.all.length > 0 && y < 1);
		}

		var maxScroll = Math.max(0, listContentHeight() - LIST_H);
		if (scrollY > maxScroll) scrollY = maxScroll;
		if (scrollY < 0) scrollY = 0;
		listCam.scroll.y = scrollY;
		refreshScrollbar();
	}

	/** 滚动条：内容装得下就整条隐藏（原型 #listScroll 的滚动条同义） */
	function refreshScrollbar()
	{
		if (sbTrack == null || sbThumb == null) return;
		var content = listContentHeight();
		var need = content > LIST_H + 0.5;
		sbTrack.visible = need;
		sbThumb.visible = need;
		if (!need) return;

		var trackH = sbTrack.height;
		var maxScroll = Math.max(1, content - LIST_H);
		var th = Math.max(SB_MIN, trackH * (LIST_H / content));
		var ty = sbTrack.y + (trackH - th) * Math.max(0, Math.min(1, scrollY / maxScroll));
		sbThumbH = th; // ★ scale 不会更新 sprite.height，命中判定必须用这个值
		sbThumb.y = ty;
		sbThumb.scale.y = th / Math.max(1, sbThumb.frameHeight);
		if (dbgSb != (need + ':' + Std.int(ty) + ':' + Std.int(th)))
		{
			dbgSb = need + ':' + Std.int(ty) + ':' + Std.int(th);
			dbg('scrollbar track=(' + Std.int(sbTrack.x) + ',' + Std.int(sbTrack.y) + ',' + SB_W + ',' + Std.int(trackH)
				+ ') thumb=(' + Std.int(sbThumb.x) + ',' + Std.int(ty) + ',' + SB_W + ',' + Std.int(th)
				+ ') content=' + Std.int(content) + ' scrollY=' + Std.int(scrollY) + '/' + Std.int(maxScroll));
		}
		var px:Float = ModsMenuState.pointerX();
		var py:Float = ModsMenuState.pointerY();
		var hot = (px > sbTrack.x - 10 && px < sbTrack.x + SB_W + 10 && py >= sbTrack.y - 6 && py <= sbTrack.y + trackH + 6);
		sbThumb.alpha = (hot || sbDrag) ? 1 : 0.72;
		sbTrack.alpha = (hot || sbDrag) ? 1 : 0.75;
	}

	/**
	 * 描述区滚动：与走马灯同一个坑 —— clipRect 会把画面整体下移 clip.y，
	 * 所以滚动时必须把文本精灵上移同样的距离，窗口才固定。
	 */
	function applyDescScroll()
	{
		descScrollY = Math.max(0, Math.min(descScrollY, descMaxScroll));
		dDescClip.y = descScrollY;
		dDesc.clipRect = dDescClip;
		dDesc.y = DESC_BASE_Y - descScrollY;
	}
	/** 光标旁的提示气泡（原型 #pressHint）：按住阶段 / 拖拽阶段两句文案 */
	function showPressHint(mx:Float, my:Float, holding:Bool)
	{
		var text = Language.get(holding ? 'pressHold' : 'pressDrag', 'mods');
		if (pressHintTxt.text != text)
		{
			pressHintTxt.text = text;
			var pw = Std.int(pressHintTxt.width) + 20;
			var ph = Std.int(pressHintTxt.height) + 10;
			pressHintBg.makeGraphic(pw, ph, FlxColor.TRANSPARENT, true);
			FlxSpriteUtil.drawRoundRect(pressHintBg, 0, 0, pw, ph, 8, 8, 0xF208090D);
			pressHintBg.visible = true;
			pressHintTxt.visible = true;
		}
		var px = Math.min(mx + 14, 1280 - pressHintBg.width - 6);
		var py = my + 18;
		if (py + pressHintBg.height > 716) py = my - pressHintBg.height - 10;
		pressHintBg.x = px - 6;
		pressHintBg.y = py - 4;
		pressHintTxt.x = px + 4;
		pressHintTxt.y = py + 1;
	}

	function hidePressHint()
	{
		if (pressHintTxt == null) return;
		pressHintTxt.visible = false;
		pressHintBg.visible = false;
	}

	function refreshDetail()
	{
		if (rows.length < 1 || sel < 0 || sel >= rows.length)
		{
			dName.text = '';
			dDesc.text = '';
			dMetaTxt.text = '';
			dBadgeTxt.text = '';
			dBadgeBg.visible = false;
			restartHint.visible = false;
			footNote.text = '';
			return;
		}
		var m:ModRow = rows[sel];

		// 背景染色（原版：FlxTween.color(bg, 1, bg.color, curMod.bgColor)）
		if (bgColorTween != null) bgColorTween.cancel();
		bgColorTween = FlxTween.color(bg, 0.7, bg.color, m.bgColor);

		if (m.iconGraphic != null)
		{
			dIcon.loadGraphic(m.iconGraphic, true, 150, 150);
			dIcon.antialiasing = m.iconAA && ClientPrefs.data.antialiasing;
			dIcon.scale.set(96 / 150, 96 / 150);
			dIcon.updateHitbox();
			if (m.frames > 1)
			{
				dIcon.animation.add('icon', [for (i in 0...m.frames) i], m.iconFps);
				dIcon.animation.play('icon');
			}
			else
			{
				dIcon.animation.stop();
			}
		}

		// 名称：23px（对齐原型 #dName），过长才缩字号，最小 15
		var fontName:String = Paths.font(Language.get('fontName', 'main') + '.ttf');
		dName.setFormat(fontName, 23, C_TEXT);
		dName.bold = true;
		dName.text = m.name;
		dName.updateHitbox();
		var maxNameW:Float = RIGHT_W - 320;
		if (dToggle != null) maxNameW = dToggle.left() - 16 - (RIGHT_X + 136); // 别撞上右上角的开关
		if (maxNameW < 120) maxNameW = 120;
		if (dName.width > maxNameW && dName.width > 0)
		{
			var s2:Int = Std.int(Math.max(15, 23 * (maxNameW / dName.width)));
			dName.setFormat(fontName, s2, C_TEXT);
			dName.bold = true;
			dName.updateHitbox();
		}
		dbg('detail sel=#' + pad2(sel + 1) + ' name="' + m.name + '" nameW=' + Std.int(dName.width) + ' nameH=' + Std.int(dName.height)
			+ ' fontSize=' + Std.int(dName.size) + ' text="' + dDesc.text.substr(0, 24) + '"');

		dMetaTxt.text = Language.get('chipFolder', 'mods') + ': ' + m.folder
			+ '    #' + pad2(sel + 1)
			+ '    ' + Language.get('chipIcon', 'mods') + ': ' + m.frames + 'f @' + m.iconFps + 'fps'
			+ '    ' + Language.get('chipColor', 'mods') + ': ' + hex6(m.bgColor);

		var badges = '';
		if (m.runsGlobally) badges += '[' + Language.get('badgeGlobal', 'mods') + ']   ';
		if (m.mustRestart) badges += '[' + Language.get('badgeRestart', 'mods') + ']   ';
		if (m.hasSettings) badges += '[' + Language.get('badgeSettings', 'mods') + ']   ';
		if (!isEnabled(m)) badges += '[' + Language.get('badgeDisabled', 'mods') + ']';
		dBadgeTxt.text = badges;
		dBadgeBg.visible = badges.length > 0;
		if (dBadgeBg.visible)
		{
			var bw = Std.int(dBadgeTxt.width) + 20;
			dBadgeBg.makeGraphic(bw, 24, 0x33FFFFFF);
			dBadgeBg.x = RIGHT_X + 136;
			dBadgeBg.y = BAR_H + 92;
			dBadgeTxt.x = RIGHT_X + 146;
			dBadgeTxt.y = BAR_H + 96;
		}

		if (dToggle != null) dToggle.setState(isEnabled(m));

		dDesc.text = (m.desc != null && m.desc.length > 0) ? m.desc : Language.get('noDesc', 'mods');
		dDesc.updateHitbox();
		descMaxScroll = Math.max(0, dDesc.height - dDescClip.height);
		applyDescScroll();

		restartHint.visible = m.mustRestart;
		footNote.text = 'mods/' + m.folder + '/pack.json';
		footNote.x = RIGHT_X + RIGHT_W - 24 - footNote.width;
	}

	function refreshFooter()
	{
		var anyOn = false, anyOff = false;
		for (m in modsList.all)
		{
			if (modsList.disabled.contains(m)) anyOff = true; else anyOn = true;
		}
		footEnableAll.setEnabled(anyOff);
		footDisableAll.setEnabled(anyOn);
		footReload.setEnabled(modsList.all.length > 0);
	}

	function refreshDirty()
	{
		hintTxt.color = (dirty > 0) ? 0xFFF4C46B : C_HINT;
		hintTxt.text = hintFor(hintTxt.fieldWidth);
	}

	// ══════════════════════════════════════════════════════════════════════
	// 行为
	// ══════════════════════════════════════════════════════════════════════
	function selectMod(i:Int)
	{
		if (modsList.all.length < 1) return;
		sel = Std.int(Math.max(0, Math.min(modsList.all.length - 1, i)));
		zone = 0;
		dbg('select #' + pad2(sel + 1) + ' ' + rows[sel].folder + ' (enabled=' + isEnabled(rows[sel]) + ')');
		refreshList();
		refreshDetail();
	}

	function selectStep(step:Int)
	{
		var vis = visibleIndices();
		if (vis.length < 1) return;
		var at = vis.indexOf(sel);
		if (at < 0) at = 0;
		else at = ((at + step) % vis.length + vis.length) % vis.length;
		selectMod(vis[at]);
		ensureVisible();
	}

	function ensureVisible()
	{
		var vis = visibleIndices();
		var at = vis.indexOf(sel);
		if (at < 0) return;
		var rowTop = at * ROW_H;
		if (rowTop < scrollY) scrollY = rowTop;
		else if (rowTop + ROW_H > scrollY + LIST_H) scrollY = rowTop + ROW_H - LIST_H;
		scrollY = Math.max(0, Math.min(scrollY, Math.max(0, listContentHeight() - LIST_H)));
		listCam.scroll.y = scrollY;
	}

	function setFilter(f:Int)
	{
		filter = (filter == f) ? 2 : f; // 再点当前标签 = 取消筛选（显示全部）
		var vis = visibleIndices();
		if (vis.length > 0 && vis.indexOf(sel) < 0) sel = vis[0];
		scrollY = 0;
		refreshTabs();
		refreshList();
		refreshDetail();
		dbg('setFilter -> filter=' + filter + ' visible=' + vis.length + '/' + rows.length + ' sel=' + sel);
	}

	function toggleMod(i:Int)
	{
		if (i < 0 || i >= rows.length) return;
		var folder = rows[i].folder;
		if (!modsList.disabled.contains(folder))
		{
			modsList.enabled.remove(folder);
			modsList.disabled.push(folder);
		}
		else
		{
			modsList.disabled.remove(folder);
			modsList.enabled.push(folder);
		}
		dirty++;
		waitingToRestart = true; // 与原版一致：任何开关都置位
		FlxG.sound.play(Paths.sound('scrollMenu'), 0.6);
		var vis = visibleIndices();
		if (vis.length > 0 && vis.indexOf(sel) < 0) sel = vis[0];
		refreshTabs();
		refreshList();
		refreshDetail();
		refreshFooter();
		refreshDirty();
		dbg('toggle ' + folder + ' -> ' + (isEnabled(rows[i]) ? 'ON' : 'OFF') + ' dirty=' + dirty);
	}

	function setAll(enabled:Bool)
	{
		dbg('setAll enabled=' + enabled);
		var changed = 0;
		for (m in modsList.all)
		{
			var isOff = modsList.disabled.contains(m);
			if (enabled && isOff)
			{
				modsList.disabled.remove(m);
				modsList.enabled.push(m);
				changed++;
			}
			else if (!enabled && !isOff)
			{
				modsList.enabled.remove(m);
				modsList.disabled.push(m);
				changed++;
			}
		}
		if (changed > 0)
		{
			dirty += changed;
			waitingToRestart = true;
			FlxG.sound.play(Paths.sound('scrollMenu'), 0.6);
		}
		var vis = visibleIndices();
		if (vis.length > 0 && vis.indexOf(sel) < 0) sel = vis[0];
		refreshAll();
	}

	/** 对应原版 moveModToPosition：改的是 modsList.all 的顺序（= 加载优先级） */
	function moveModToPosition(?mod:String = null, position:Int = 0)
	{
		if (modsList.all.length < 2) return;
		if (mod == null)
		{
			if (sel < 0 || sel >= modsList.all.length) return;
			mod = modsList.all[sel];
		}
		var id = modsList.all.indexOf(mod);
		if (id < 0) return;
		moveOrder(id, position);
	}

	/** 把 from 号行移动到 to 号位置（绝对下标） */
	function moveOrder(from:Int, to:Int)
	{
		if (modsList.all.length < 2) return;
		var n = modsList.all.length;
		to = Std.int(Math.max(0, Math.min(n - 1, to)));
		if (from == to || from < 0 || from >= n) return;

		var mod = modsList.all[from];
		var row = rows[from];
		modsList.all.remove(mod);
		rows.remove(row);
		modsList.all.insert(to, mod);
		rows.insert(to, row);

		sel = to;
		dirty++;
		waitingToRestart = true; // 与原版一致：排序也置位
		FlxG.sound.play(Paths.sound('scrollMenu'), 0.6);
		refreshList();
		refreshDetail();
		refreshDirty();
		ensureVisible();
		showToast('#' + pad2(from + 1) + ' → #' + pad2(to + 1));
		dbg('moveOrder ' + mod + ' : #' + pad2(from + 1) + ' -> #' + pad2(to + 1) + ' dirty=' + dirty);
	}

	function reload()
	{
		dbg('reload() dirty=' + dirty);
		saveTxt();
		FlxG.autoPause = ClientPrefs.data.autoPause;
		FlxTransitionableState.skipNextTransIn = true;
		FlxTransitionableState.skipNextTransOut = true;
		MusicBeatState.switchState(new ModsMenuState(rows.length > 0 ? rows[sel].folder : null));
	}

	function openModSettings()
	{
		dbg('openModSettings sel=' + sel);
		if (rows.length < 1 || sel < 0 || sel >= rows.length) return;
		var m = rows[sel];
		if (m.settings == null || m.settings.length < 1) return;
		openSubState(new ModSettingsSubState(m.settings, m.folder, m.name));
	}

	function openModsFolder()
	{
		var modFolder = Paths.mods();
		if (!FileSystem.exists(modFolder))
		{
			try FileSystem.createDirectory(modFolder) catch (e:Dynamic) { trace('create mods dir failed: $e'); }
		}
		#if mobile
		// ★ Android 上没有 explorer.exe / xdg-open：CoolUtil.openFolder 只在 Windows/Linux 生效，
		//   在手机上调用是个**静默空操作**（logcat 里只会留下 `explorer.exe \storage\...` 一行），
		//   用户点了"打开 mods 文件夹"就会觉得按钮坏了。这里改成把路径提示出来。
		showToast(ModsMenuState.fmt(Language.get('toastFolder', 'mods'), 'path', modFolder));
		#else
		CoolUtil.openFolder(modFolder);
		showToast(modFolder);
		#end
	}

	/** 退出：有改动 → 弹确认并整局重启；否则回主菜单 / 选歌（原版语义） */
	function exitMenu()
	{
		dbg('exitMenu dirty=' + dirty);
		if (dirty > 0)
		{
			showConfirm();
			return;
		}
		doExitToMenu();
	}

	function doExitToMenu()
	{
		dbg('doExitToMenu -> freeplay=' + isFreePlay);
		saveTxt();
		FlxG.sound.play(Paths.sound('cancelMenu'));
		if (!isFreePlay)
			MusicBeatState.switchState(new MainMenuState());
		else
			MusicBeatState.switchState(new FreeplayState());
		isFreePlay = false; // 原版在退出分支里复位
		persistentUpdate = false;
		FlxG.autoPause = ClientPrefs.data.autoPause;
	}

	function doRestartNow()
	{
		hideConfirm();
		saveTxt();
		dbg('doRestartNow: waitingToRestart=' + waitingToRestart + ' dirty=' + dirty);
		TitleState.initialized = false;
		TitleState.closedState = false;
		if (FlxG.sound.music != null) FlxG.sound.music.fadeOut(0.3);
		FlxG.camera.fade(FlxColor.BLACK, 0.5, false, FlxG.resetGame, false);
		isFreePlay = false;
	}

	function showConfirm()
	{
		dbg('showConfirm');
		maskSpr.visible = true;
		confirmBg.visible = true;
		confirmTitle.visible = true;
		confirmBody.visible = true;
		confirmYes.setVisible(true);
		confirmStay.setVisible(true);
	}

	function hideConfirm()
	{
		dbg('hideConfirm');
		maskSpr.visible = false;
		confirmBg.visible = false;
		confirmTitle.visible = false;
		confirmBody.visible = false;
		confirmYes.setVisible(false);
		confirmStay.setVisible(false);
	}

	function showToast(msg:String)
	{
		toastTxt.text = msg;
		toastTxt.updateHitbox();
		var w = Std.int(Math.max(120, toastTxt.width + 32));
		toastBg.makeGraphic(w, 32, FlxColor.TRANSPARENT);
		FlxSpriteUtil.drawRoundRect(toastBg, 0, 0, w, 32, 16, 16, 0xF208090D);
		toastBg.x = 640 - w / 2;
		toastBg.y = 720 - 60;
		toastTxt.x = toastBg.x;
		toastTxt.y = toastBg.y + 9;
		toastBg.visible = true;
		toastTxt.visible = true;
		toastBg.alpha = 1;
		toastTxt.alpha = 1;
		toastTimer = 1.9;
	}

	function updateEmptyStateVisibility()
	{
		var empty = (modsList.all.length < 1);
		emptyMode = empty;
		// ★ 空状态把常规界面（标签栏 / 底部三按钮 / 右栏详情 / 工具条）整片收起来，
		//   只留空状态卡片 + 顶部窗口条 —— 否则 60% 透明的遮罩下面会透出"一堆多余按钮"，
		//   而且那些按钮点了也没意义（它们都需要先选中某个模组）。
		setNormalUiVisible(!empty);
		for (s in emptyGfx) s.visible = empty;
		if (emptyEgg != null && emptyEgg.text.length < 1) emptyEgg.visible = false;
		emptyTitle.visible = emptyBody.visible = emptyScan.visible = empty;
		emptyFolderBtn.setVisible(empty);
		emptyExitBtn.setVisible(empty);
		layoutEmptyButtons();
	}

	/** 空状态两个按钮：正文下方居中排成一行（原型 #empty .row，间距 10）
	 *  ★ 老代码建完按钮后从没定位过，一直停在 (0,0) 互相重叠 —— 点一下会同时触发两个。 */
	function layoutEmptyButtons()
	{
		if (emptyFolderBtn == null || emptyExitBtn == null) return;
		var gap:Float = 10;
		var total:Float = emptyFolderBtn.w + gap + emptyExitBtn.w;
		var x0:Float = 640 - total / 2;
		emptyFolderBtn.setPos(x0, 470);
		emptyExitBtn.setPos(x0 + emptyFolderBtn.w + gap, 470);
	}

	/** 常规界面（无模组时整体隐藏） */
	function setNormalUiVisible(v:Bool)
	{
		// 结构性元素：空状态收起、有模组时展开
		var arr:Array<FlxSprite> = [listBg, listDiv, tabLine, tabBottom, footTop, detailBg, detailLine, dIcon, dName, dMetaTxt, dDescLabel,
			dDesc, footNote];
		for (s in arr)
			if (s != null) s.visible = v;
		// 这几个的显隐是按内容算的（refreshDetail / refreshList 负责）：只在收起时强制隐藏
		if (!v)
		{
			for (s in [dBadgeBg, dBadgeTxt, restartHint, filterEmptyTxt])
				if (s != null) s.visible = false;
		}
		if (tabOn != null) tabOn.setVisible(v);
		if (tabOff != null) tabOff.setVisible(v);
		if (dToggle != null) dToggle.setVisible(v);
		if (footReload != null) footReload.setVisible(v);
		if (footEnableAll != null) footEnableAll.setVisible(v);
		if (footDisableAll != null) footDisableAll.setVisible(v);
		for (b in tools)
			b.setVisible(v);
	}

	/** 写 modsList.txt（与原版 saveTxt 完全一致） */
	function saveTxt()
	{
		var fileStr:String = '';
		for (mod in modsList.all)
		{
			if (mod.trim().length < 1) continue;
			if (fileStr.length > 0) fileStr += '\n';
			var on = '1';
			if (modsList.disabled.contains(mod)) on = '0';
			fileStr += '$mod|$on';
		}
		File.saveContent('modsList.txt', fileStr);
	}

	// ══════════════════════════════════════════════════════════════════════
	// update
	// ══════════════════════════════════════════════════════════════════════
	override function update(elapsed:Float)
	{
		if (FlxG.width != lastBarW) relayoutBar();

		if (modsList.all.length < 1)
		{
			// 空列表：每秒轮询（原版行为）；同时让提示呼吸
			noModsSine += 180 * elapsed;
			emptyTitle.alpha = 0.55 + 0.45 * (1 - Math.sin((Math.PI * noModsSine) / 180));
			scanTimer -= elapsed;
			if (scanTimer < 0)
			{
				scanTimer = 1;
				@:privateAccess
				Mods.updateModList();
				modsList = Mods.parseList();
				if (modsList.all.length > 0)
				{
					trace('[ModsMenu] mod(s) found -> reloading menu');
					reload();
					return;
				}
			}
		}
		else
		{
			handleMouse(elapsed);
			handleKeys(elapsed);
		}

		// 列表行：走马灯 + 选中态
		for (r in rows) if (r.anyVisible()) r.updateVisual(elapsed);
		refreshScrollbar();

		// 自绘控件的悬停/点击（统一走 viewX/viewY 判定）
		for (b in allButtons) b.updateHover();
		if (tabOn != null) tabOn.updateHover();
		if (tabOff != null) tabOff.updateHover();
		for (i in 0...tools.length)
		{
			tools[i].setFocus(zone == 1 && i == toolSel); // 工具条焦点指示（键盘/手柄用）
			tools[i].updateHover();
		}
		if (dToggle != null) dToggle.updateHover();

		// 悬停工具按钮 → 提示栏显示它的名字
		if (modsList.all.length > 0 && dirty < 1)
		{
			for (i in 0...tools.length)
			{
				if (tools[i].hovered)
				{
					hintTxt.text = Language.get(tools[i].labelKey, 'mods');
					break;
				}
			}
		}

		// toast 淡出
		if (toastTimer > 0)
		{
			toastTimer -= elapsed;
			if (toastTimer < 0.4)
			{
				var a = Math.max(0, toastTimer / 0.4);
				toastBg.alpha = a;
				toastTxt.alpha = a;
			}
			if (toastTimer <= 0)
			{
				toastBg.visible = false;
				toastTxt.visible = false;
			}
		}

		// 鼠标一动就退出控制器模式（原版行为）
		// ★ 桌面端不再用 needMobileControl 卡住光标：本界面本来就是鼠标/触摸驱动的，
		//   而引擎默认把光标藏起来（needMobileControl 默认 true），否则桌面上连悬停高亮都没有。
		var mouseMoved:Bool = (FlxG.mouse != null) && (Math.abs(FlxG.mouse.deltaX) > 4 || Math.abs(FlxG.mouse.deltaY) > 4);
		if (mouseMoved) controls.controllerMode = false;
		#if !mobile
		if (mouseMoved && FlxG.mouse != null && !FlxG.mouse.visible) FlxG.mouse.visible = true;
		#end

		super.update(elapsed);
	}

	// ── 鼠标 ──
	function handleMouse(elapsed:Float)
	{
		// ★ 统一走指针层：手机用触点、桌面用鼠标，且不再要求 mouse.visible
		var mx:Float = ModsMenuState.pointerX();
		var my:Float = ModsMenuState.pointerY();
		var wheel:Int = ModsMenuState.pointerWheel();
		var justPressed:Bool = ModsMenuState.pointerJustPressed();
		var pressedNow:Bool = ModsMenuState.pointerPressed();
		var justReleased:Bool = ModsMenuState.pointerJustReleased();

		if (wheel != 0)
			dbg('wheel=' + wheel + ' at(' + Std.int(mx) + ',' + Std.int(my) + ') overList=' + (mx < LEFT_W && my >= LIST_TOP && my < LIST_TOP + LIST_H));
		if (justPressed)
			dbg('press at(' + Std.int(mx) + ',' + Std.int(my) + ') listHit=' + (mx < LEFT_W && my >= LIST_TOP && my < LIST_TOP + LIST_H ? rowAtScreen(my) : -1));

		// 滚轮：列表 / 描述区（移动端没有滚轮，wheel 恒为 0）
		if (wheel != 0)
		{
			if (mx < LEFT_W && my >= LIST_TOP && my < LIST_TOP + LIST_H)
			{
				scrollY -= wheel * 34;
				scrollY = Math.max(0, Math.min(scrollY, Math.max(0, listContentHeight() - LIST_H)));
				listCam.scroll.y = scrollY;
			}
			else if (mx >= RIGHT_X && my > BAR_H + 170 && my < 720 - 50 && descMaxScroll > 0)
			{
				descScrollY -= wheel * 40;
				applyDescScroll();
			}
		}

		// 搜索框：点框内聚焦、点外面失焦
		if (justPressed)
		{
			var insideSearch = (mx >= searchBg.x - 6 && mx <= searchBg.x + 196 + 6 && my >= 2 && my <= 34);
			if (insideSearch) PsychUIInputText.focusOn = searchBox;
			else if (PsychUIInputText.focusOn == searchBox) PsychUIInputText.focusOn = null;
		}

		// ── 列表行：按下 → 1 秒长按 → 拖拽；不足 1 秒松开 = 选中；先移动 = 滚动列表 ──
		// ── 列表行：按下 → 1 秒长按 → 拖拽排序；不足 1 秒先移动 = 拖动列表滚动 ──
		var overSb = (sbThumb != null && sbThumb.visible && mx >= sbTrack.x - 6);
		var inList = (!overSb && mx < LEFT_W && my >= LIST_TOP && my < LIST_TOP + LIST_H);
		var hit = inList ? rowAtScreen(my) : -1;

		if (justPressed && hit >= 0)
		{
			pressIdx = hit;
			pressTimer = 0;
			pressMoved = false;
			dragging = false;
			scrollDrag = false;
			dragSlot = -1;
			dragOffsetY = 0;
			pressMouseX = mx;
			pressMouseY = my;
			scrollDragBase = scrollY;
			scrollDragMouseY = my;
		}

		if (pressIdx >= 0 && pressedNow)
		{
			var dx = Math.abs(mx - pressMouseX);
			var dy = Math.abs(my - pressMouseY);

			// ① 不到 1 秒就先移动 = 拖动列表滚动（并彻底取消长按）
			if (!dragging && !scrollDrag && (dx > SCROLL_TOL || dy > SCROLL_TOL))
			{
				scrollDrag = true;
				pressMoved = true;
				if (pressIdx < rows.length) rows[pressIdx].setHoldProgress(0);
				hidePressHint();
				dbg('scrollDrag start row=#' + pad2(pressIdx + 1) + ' d=(' + Std.int(dx) + ',' + Std.int(dy) + ') scrollY=' + Std.int(scrollY));
			}
			// ② 按住不动满 1 秒 = 进入排序拖拽
			else if (!dragging && !scrollDrag && pressTimer < LONG_PRESS)
			{
				pressTimer += elapsed;
				if (pressTimer >= LONG_PRESS)
				{
					dragging = true;
					FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
					if (pressIdx < rows.length) rows[pressIdx].setHoldProgress(0);
					dbg('longPress OK row=#' + pad2(pressIdx + 1) + ' ' + rows[pressIdx].folder);
				}
				else if (pressIdx < rows.length)
				{
					rows[pressIdx].setHoldProgress(pressTimer / LONG_PRESS);
					if (pressTimer > 0.22) showPressHint(mx, my, true);
				}
			}

			if (scrollDrag)
			{
				// 跟手滚动：光标往上 = 列表往下
				scrollY = scrollDragBase - (my - scrollDragMouseY);
				scrollY = Math.max(0, Math.min(scrollY, Math.max(0, listContentHeight() - LIST_H)));
				listCam.scroll.y = scrollY;
				refreshScrollbar();
			}
			else if (dragging)
			{
				if (my < LIST_TOP + 24) scrollY -= 7;
				else if (my > LIST_TOP + LIST_H - 24) scrollY += 7;
				scrollY = Math.max(0, Math.min(scrollY, Math.max(0, listContentHeight() - LIST_H)));
				listCam.scroll.y = scrollY;
				refreshScrollbar();

				var vis0 = visibleIndices();
				if (pressIdx < rows.length && vis0.indexOf(pressIdx) >= 0)
				{
					// 被拖行跟手（限制在列表可视区内，不会跑到面板外面）
					var base = vis0.indexOf(pressIdx) * ROW_H;
					var want = my - pressMouseY;
					want = Math.max(-base, Math.min(want, LIST_H - ROW_H - base));
					rows[pressIdx].setDragOffset(want);
				}

				dragSlot = dropSlotAt(my);
				var vis = visibleIndices();
				if (vis.length > 0)
				{
					var slot = Std.int(Math.max(0, Math.min(vis.length, dragSlot)));
					dropLine.y = slot * ROW_H - 1;
					dropLine.visible = true;
				}
				showPressHint(mx, my, false);
			}
		}

		if (justReleased && pressIdx >= 0)
		{
			dropLine.visible = false;
			hidePressHint();
			if (pressIdx < rows.length) rows[pressIdx].setHoldProgress(0);
			if (dragging)
			{
				var vis = visibleIndices();
				var from = pressIdx;
				var target = from;
				if (vis.length > 0)
				{
					var slot = Std.int(Math.max(0, Math.min(vis.length, dragSlot)));
					target = (slot >= vis.length) ? vis[vis.length - 1] : vis[slot];
					if (target > from) target -= 1; // 前插后行会前移一位（moveOrder 内部先删后插）
					if (target < 0) target = 0;
				}
				if (pressIdx < rows.length) rows[pressIdx].setDragOffset(0);
				if (target != from) moveOrder(from, target);
			}
			else if (!pressMoved)
			{
				selectMod(pressIdx);
			}
			if (scrollDrag) dbg('scrollDrag end scrollY=' + Std.int(scrollY));
			pressIdx = -1;
			dragging = false;
			scrollDrag = false;
			pressMoved = false;
		}

		// 滚动条：拖动滑块 / 点轨道跳转
		if (sbThumb != null && sbThumb.visible)
		{
			var trackTop = sbTrack.y;
			var trackH = sbTrack.height;
			var maxScroll = Math.max(1, listContentHeight() - LIST_H);
			var overThumb = (mx >= sbThumb.x - 4 && mx <= sbThumb.x + SB_W + 4 && my >= sbThumb.y && my <= sbThumb.y + sbThumbH);
			if (justPressed && overThumb)
			{
				sbDrag = true;
				sbDragOfs = my - sbThumb.y;
				dbg('sbDrag start y=' + Std.int(my) + ' thumbY=' + Std.int(sbThumb.y) + ' thumbH=' + Std.int(sbThumbH));
			}
			else if (justPressed && mx >= sbTrack.x - 6 && mx <= sbTrack.x + SB_W + 6 && my >= trackTop && my <= trackTop + trackH)
			{
				scrollY = ((my - trackTop - sbThumbH / 2) / Math.max(1, trackH - sbThumbH)) * maxScroll;
				scrollY = Math.max(0, Math.min(scrollY, maxScroll));
				listCam.scroll.y = scrollY;
				refreshScrollbar();
				dbg('sbJump y=' + Std.int(my) + ' -> scrollY=' + Std.int(scrollY));
			}
			if (sbDrag)
			{
				if (!pressedNow)
				{
					sbDrag = false;
					dbg('sbDrag end scrollY=' + Std.int(scrollY));
				}
				else
				{
					var frac = (my - sbDragOfs - trackTop) / Math.max(1, trackH - sbThumbH);
					scrollY = Math.max(0, Math.min(1, frac)) * maxScroll;
					listCam.scroll.y = scrollY;
					refreshScrollbar();
				}
			}
		}

		// 描述区：按住拖动滚动
		if (descDragging)
		{
			if (!pressedNow) descDragging = false;
			else
			{
				descScrollY += (descDragY - my);
				descDragY = my;
				applyDescScroll();
			}
		}
		else if (justPressed && mx >= RIGHT_X + 20 && my > BAR_H + 170 && my < 720 - 50 && descMaxScroll > 0)
		{
			descDragging = true;
			descDragY = my;
		}
	}

	function rowAtScreen(sy:Float):Int
	{
		var vis = visibleIndices();
		if (vis.length < 1) return -1;
		var local = sy - LIST_TOP + scrollY;
		var k = Std.int(local / ROW_H);
		if (k < 0 || k >= vis.length) return -1;
		return vis[k];
	}

	/** 返回插入槽位（0..可见行数） */
	function dropSlotAt(sy:Float):Int
	{
		var vis = visibleIndices();
		var local = sy - LIST_TOP + scrollY;
		var k = Std.int(local / ROW_H);
		if (local - k * ROW_H > ROW_H / 2) k++;
		return Std.int(Math.max(0, Math.min(vis.length, k)));
	}

	// ── 键盘（原版 controls 语义）──
	function handleKeys(elapsed:Float)
	{
		if (controls.ACCEPT || controls.BACK || controls.UI_UP_P || controls.UI_DOWN_P || controls.UI_LEFT_P || controls.UI_RIGHT_P)
			dbg('key ACCEPT=' + controls.ACCEPT + ' BACK=' + controls.BACK + ' U=' + controls.UI_UP_P + ' D=' + controls.UI_DOWN_P + ' L=' + controls.UI_LEFT_P + ' R=' + controls.UI_RIGHT_P);
		// 搜索框聚焦时把按键让给输入框（Esc 除外）
		if (PsychUIInputText.focusOn != null && !controls.BACK) return;

		if (maskSpr.visible)
		{
			if (controls.ACCEPT) doRestartNow();
			else if (controls.BACK) hideConfirm();
			return;
		}

		if (controls.BACK)
		{
			if (searchBox != null && PsychUIInputText.focusOn == searchBox) PsychUIInputText.focusOn = null;
			else if (zone == 1) zone = 0; // 工具条区按 BACK 只回列表（原版行为）
			else exitMenu();
			return;
		}

		if (controls.UI_DOWN_P || controls.UI_UP_P)
		{
			var down = controls.UI_DOWN_P;
			if (zone == 0) selectStep(Std.int((FlxG.keys.pressed.SHIFT ? 5 : 1) * (down ? 1 : -1)));
			else
			{
				var t = toolSel + (down ? 1 : -1);
				if (t < 0 || t >= tools.length) zone = 0;
				else toolSel = t;
			}
		}
		else if (controls.UI_LEFT_P || controls.UI_RIGHT_P)
		{
			if (zone == 0)
			{
				zone = 1;
				toolSel = 0;
			}
			else
			{
				var t = toolSel + (controls.UI_RIGHT_P ? 1 : -1);
				if (t < 0 || t >= tools.length) zone = 0;
				else toolSel = t;
			}
		}
		else if (controls.ACCEPT)
		{
			if (zone == 1) toolAction(toolSel);
		}
		else if (FlxG.keys.justPressed.TAB)
		{
			// Tab 键在【已启用】/【已禁用】之间切换（鼠标点标签的键盘等价物）
			setFilter(filter == 0 ? 1 : 0);
		}
		else if (FlxG.keys.justPressed.SPACE)
		{
			toggleMod(sel);
		}
		else if (FlxG.keys.justPressed.HOME)
		{
			var vis = visibleIndices();
			if (vis.length > 0) selectMod(vis[0]);
			scrollY = 0;
			listCam.scroll.y = 0;
		}
		else if (FlxG.keys.justPressed.END)
		{
			var vis = visibleIndices();
			if (vis.length > 0) selectMod(vis[vis.length - 1]);
			scrollY = Math.max(0, listContentHeight() - LIST_H);
			listCam.scroll.y = scrollY;
		}
		else if (FlxG.keys.pressed.SHIFT && (controls.UI_UP || controls.UI_DOWN))
		{
			holdTime += elapsed;
			if (holdTime > 0.5)
			{
				holdTime = 0;
				moveOrder(sel, controls.UI_UP ? sel - 1 : sel + 1);
			}
		}
		if (controls.UI_DOWN_R || controls.UI_UP_R) holdTime = 0;
	}

	override function destroy()
	{
		FlxG.autoPause = ClientPrefs.data.autoPause;
		super.destroy();
	}

	// ══════════════════════════════════════════════════════════════════════
	// 小工具
	// ══════════════════════════════════════════════════════════════════════
	public static inline function pad2(v:Int):String
	{
		return (v < 10) ? '0' + v : '' + v;
	}

	public static function fmt(s:String, key:String, value:String):String
	{
		return s.split('{' + key + '}').join(value);
	}

	public static function hex6(c:FlxColor):String
	{
		var digits = '0123456789ABCDEF';
		var r = (c >> 16) & 0xFF;
		var g = (c >> 8) & 0xFF;
		var b = c & 0xFF;
		return '#' + digits.charAt(r >> 4) + digits.charAt(r & 0xF)
			+ digits.charAt(g >> 4) + digits.charAt(g & 0xF)
			+ digits.charAt(b >> 4) + digits.charAt(b & 0xF);
	}
}

// ══════════════════════════════════════════════════════════════════════
// 列表行：pack 图标 | 名称 / 文件夹名（长名字走马灯）
// ══════════════════════════════════════════════════════════════════════
class ModRow
{
	public var folder:String;
	public var name:String = 'Unknown Mod';
	public var desc:String = 'No description provided.';
	public var mustRestart:Bool = false;
	public var runsGlobally:Bool = false;
	public var hasSettings:Bool = false;
	public var settings:Array<Dynamic> = null;
	public var iconFps:Int = 10;
	public var frames:Int = 0;
	public var bgColor:FlxColor = 0xFF665AFF;
	public var iconGraphic:FlxGraphic = null;
	public var iconAA:Bool = true;
	public var index:Int = 0;

	var rowW:Float;
	var bg:FlxSprite;
	var bar:FlxSprite;
	var icon:FlxSprite;
	var nameTxt:FlxText;
	var folderTxt:FlxText;
	var badgeTxt:FlxText;
	var nameClip:FlxRect;
	var folderClip:FlxRect;
	var nameCycle:Float = 0;
	var folderCycle:Float = 0;
	var nameDist:Float = 0;
	var folderDist:Float = 0;
	var nameTime:Float = 0;
	var folderTime:Float = 0;
	var colW:Float = 0;
	var nameBaseX:Float = 64;
	var folderBaseX:Float = 64;
	var nameOne:String = '';
	var folderOne:String = '';
	var holdProg:Float = 0;
	var holdSpr:FlxSprite;
	var dragOfs:Float = 0;
	var rowY:Float = 0;
	var sprites:Array<FlxSprite> = [];

	public function new(folder:String, rowW:Float)
	{
		this.folder = folder;
		this.rowW = rowW;

		// ── pack.json（与原版 ModItem 一致的读取顺序与兜底）──
		var pack:Dynamic = Mods.getPack(folder);

		// data/settings.json（与原版一致，TJSON）
		var setPath:String = Paths.mods('$folder/data/settings.json');
		if (FileSystem.exists(setPath))
		{
			try
			{
				settings = tjson.TJSON.parse(File.getContent(setPath));
			}
			catch (e:Dynamic)
			{
				trace('Mod settings parse failed: $folder - $e');
			}
		}
		hasSettings = (settings != null && settings.length > 0);

		// ★ pack 图标显示逻辑：pack.png → pack-pixel.png（关抗锯齿）→ unknownMod.png
		var isPixel = false;
		var bmp = Paths.cacheBitmap(Paths.mods('$folder/pack.png'));
		if (bmp == null)
		{
			bmp = Paths.cacheBitmap(Paths.mods('$folder/pack-pixel.png'));
			isPixel = true;
		}
		if (bmp != null)
		{
			iconGraphic = bmp;
			iconAA = !isPixel;
			frames = Std.int(Math.floor(bmp.width / 150) * Math.floor(bmp.height / 150));
		}
		else
		{
			iconGraphic = Paths.image('unknownMod');
			iconAA = true;
			frames = 1;
		}

		this.name = folder;
		if (pack != null)
		{
			if (pack.name != null) this.name = Std.string(pack.name);
			if (pack.description != null) this.desc = Std.string(pack.description);
			if (pack.iconFramerate != null) this.iconFps = Std.int(pack.iconFramerate);
			if (pack.restart == true) this.mustRestart = true;
			if (pack.runsGlobally == true) this.runsGlobally = true;
			if (pack.color != null)
			{
				this.bgColor = FlxColor.fromRGB(pack.color[0] != null ? pack.color[0] : 170, pack.color[1] != null ? pack.color[1] : 0,
					pack.color[2] != null ? pack.color[2] : 255);
			}
		}

		// ── 精灵 ──
		bg = new FlxSprite(0, 0).makeGraphic(Std.int(rowW), ModsMenuState.ROW_H, 0xFFFFFFFF);
		bg.alpha = ModsMenuState.ROW_BG_A;

		icon = new FlxSprite(12, 8);
		if (iconGraphic != null) icon.loadGraphic(iconGraphic, true, 150, 150);
		icon.antialiasing = iconAA && ClientPrefs.data.antialiasing;
		icon.scale.set(40 / 150, 40 / 150);
		icon.updateHitbox();
		if (frames > 1)
		{
			icon.animation.add('icon', [for (i in 0...frames) i], iconFps);
			icon.animation.play('icon');
		}

		// 文字列宽：原型里名字块是 flex:1（占满图标与徽章之外的全部宽度）。
		// 有徽章的行给右侧徽章区（rowW-160 起、右对齐）留 8px 空隙；没有徽章的行把整行都给文字。
		var badgeZone:Float = (runsGlobally || mustRestart || hasSettings) ? 168 : 22;
		colW = rowW - 64 - badgeZone;
		nameBaseX = 64;
		folderBaseX = 64;
		nameOne = this.name;
		folderOne = folder;
		nameTxt = new FlxText(nameBaseX, 11, 0, this.name, 13);
		nameTxt.setFormat(Paths.font(Language.get('fontName', 'main') + '.ttf'), 13, ModsMenuState.C_TEXT);
		nameTxt.wordWrap = false;

		folderTxt = new FlxText(folderBaseX, 32, 0, folder, 11);
		folderTxt.setFormat(Paths.font(Language.get('fontName', 'main') + '.ttf'), 11, ModsMenuState.C_HINT);
		folderTxt.wordWrap = false;

		badgeTxt = new FlxText(rowW - 160, 20, 148, '', 10);
		badgeTxt.setFormat(Paths.font(Language.get('fontName', 'main') + '.ttf'), 10, ModsMenuState.C_DIM, RIGHT);

		bar = new FlxSprite(rowW - 3, 10).makeGraphic(3, ModsMenuState.ROW_H - 20, ModsMenuState.C_DANGER, true);

		// 长按进度条：按住时从行左侧长出来（2px 强调线）
		holdSpr = new FlxSprite(0, ModsMenuState.ROW_H - 2).makeGraphic(1, 2, ModsMenuState.C_ACCENT, true);
		holdSpr.origin.set(0, 0); // ★ 归零 origin，否则 scale.x 会绕中心把进度条推到左边去
		holdSpr.visible = false;

		nameClip = new FlxRect(0, 0, colW, 18);
		folderClip = new FlxRect(0, 0, colW, 14);
		buildMarquee(nameTxt, true);
		buildMarquee(folderTxt, false);

		sprites = [bg, bar, icon, nameTxt, folderTxt, badgeTxt, holdSpr];
		setEnabledFlag(true);
	}

	/**
	 * 走马灯（单向、无断层版）：
	 *   文案只有一份，裁剪窗从左往右扫过它（dist = 文本宽 - 列宽），滑到底停一下再瞬间回到起点。
	 *   ——为什么不用"两份文案无缝循环"：那样窗口扫过拼接处时，行里会同时出现
	 *     "名字的尾巴 + 一大段空白 + 名字的开头"（例如 "…i Fu DEMO      Shit night…"），
	 *     静态看就像文字断成两截（用户报的"走马灯出现新问题"就是这个）。
	 *   单份 + 到头重来则任何时刻都是连续文字，且依然只往一个方向移动。
	 *
	 * ★ Flixel 的 clipRect 不是"屏幕上的窗口"：FlxFrame.clipTo() 会把 frame.offset
	 *   设成裁剪矩形的原点，FlxCamera.copyPixels() 又按 destPoint + frame.offset 绘制，
	 *   于是整块文字会跟着 clip.x 一起右移。所以必须同时把文本左移 clip.x，
	 *   窗口才能固定在 [baseX, baseX+colW]。
	 */
	function buildMarquee(txt:FlxText, isName:Bool)
	{
		txt.wordWrap = false;
		txt.clipRect = null;
		var baseX = isName ? nameBaseX : folderBaseX;
		txt.x = baseX;
		var one = isName ? nameOne : folderOne;
		txt.text = one;
		var singleW = txt.width;
		var clip = isName ? nameClip : folderClip;
		clip.x = 0;

		if (!ModsMenuState.marqueeEnabled)
		{
			// 关掉走马灯：超出就按列宽裁断
			if (isName) nameCycle = 0; else folderCycle = 0;
			txt.clipRect = (singleW > colW) ? clip : null;
			return;
		}
		if (singleW <= colW)
		{
			// 放得下就不动、不裁
			if (isName) nameCycle = 0; else folderCycle = 0;
			return;
		}

		var dist = singleW - colW;
		var cycle = ModsMenuState.MARQ_HOLD + dist / ModsMenuState.MARQ_SPEED + ModsMenuState.MARQ_END_HOLD + 0.02;
		if (isName)
		{
			nameDist = dist;
			nameCycle = cycle;
			nameTime = 0;
			nameTxt.clipRect = clip;
		}
		else
		{
			folderDist = dist;
			folderCycle = cycle;
			folderTime = 0;
			folderTxt.clipRect = clip;
		}
		ModsMenuState.dbg('marquee[' + folder + '] ' + (isName ? 'name' : 'folder') + ' one=' + Std.int(singleW)
			+ ' colW=' + Std.int(colW) + ' dist=' + Std.int(dist) + ' cycle=' + Math.round(cycle * 100) / 100
			+ ' -> 窗口固定 ' + Std.int(baseX) + '..' + Std.int(baseX + colW) + '（单份无断层）');
	}

	/** 被拖拽时整行跟手（dy = 光标相对按下点的位移） */
	public function setDragOffset(dy:Float)
	{
		dragOfs = dy;
		applyY();
	}

	/** 长按进度 0..1（按住时行底部从左往右长的强调线） */
	public function setHoldProgress(p:Float)
	{
		holdProg = p;
		if (p <= 0)
		{
			holdSpr.visible = false;
			return;
		}
		holdSpr.visible = bg.visible;
		holdSpr.y = rowY + ModsMenuState.ROW_H - 2;
		// 底图是 1x2 → 直接用 scale.x 当宽度（不做 updateHitbox，否则会把缩放烘进尺寸）
		holdSpr.scale.x = Math.max(0.001, rowW * Math.min(1, p));
	}

	function applyY()
	{
		var y = rowY + dragOfs;
		bg.y = y;
		bar.y = y + 10;
		icon.y = y + 8;
		nameTxt.y = y + 11;
		folderTxt.y = y + 32;
		badgeTxt.y = y + 20;
		if (holdSpr.visible) holdSpr.y = y + ModsMenuState.ROW_H - 2;
	}

	public function addTo(state:FlxState, cam:FlxCamera)
	{
		for (s in sprites)
		{
			s.cameras = [cam];
			// ★ 不要 scrollFactor.set()：列表行必须跟随 listCam.scroll 才会真的滚动
			//   （scrollFactor(0,0) = 忽略相机滚动，列表看起来就是"冻住"的）
			state.add(s);
		}
	}

	public inline function anyVisible():Bool
	{
		return bg.visible;
	}

	public function setVisible(v:Bool)
	{
		for (s in sprites) s.visible = v;
		if (holdSpr != null) holdSpr.visible = v && holdProg > 0;
		if (!v) return;
		bar.visible = !enabled;
		badgeTxt.visible = (badgeTxt.text.length > 0);
	}

	public var enabled:Bool = true;

	public function setY(y:Float)
	{
		rowY = y;
		applyY();
	}

	public function setSelected(v:Bool)
	{
		// ★ 必须改 alpha 而不是 color：底图是 0x08FFFFFF（位图自带 alpha 0x08），
		//   而 FlxSprite.color 只乘 RGB、改不了位图 alpha —— 老写法选中态根本看不出来。
		bg.color = FlxColor.WHITE;
		bg.alpha = v ? ModsMenuState.ROW_SEL_A : ModsMenuState.ROW_BG_A;
	}

	/** 启用/禁用态的全部视觉（原版：图标染红 + 名称变灰；新版另加右侧红条与徽章） */
	public function setEnabledFlag(v:Bool)
	{
		enabled = v;
		nameTxt.color = v ? ModsMenuState.C_TEXT : 0xFF8A8F9E;
		folderTxt.color = v ? ModsMenuState.C_HINT : 0xFF6A6E7C;
		icon.color = v ? FlxColor.WHITE : 0xFFFF6666;
		bar.visible = bg.visible && !v;
		var b = '';
		if (runsGlobally) b += Language.get('badgeGlobal', 'mods') + '  ';
		if (mustRestart) b += Language.get('badgeRestart', 'mods') + '  ';
		if (hasSettings) b += Language.get('badgeSettings', 'mods');
		badgeTxt.text = b;
		badgeTxt.visible = bg.visible && b.length > 0;
	}

	/** 每帧：走马灯相位（单向；到尾停一下瞬间回到起点，中途永远是连续文字） */
	public function updateVisual(elapsed:Float)
	{
		if (nameCycle > 0)
		{
			nameTime += elapsed;
			var t = nameTime % nameCycle;
			var travel = nameDist / ModsMenuState.MARQ_SPEED;
			var x:Float = 0;
			if (t > ModsMenuState.MARQ_HOLD)
			{
				var t2 = t - ModsMenuState.MARQ_HOLD;
				x = (t2 < travel) ? (t2 * ModsMenuState.MARQ_SPEED) : nameDist;
			}
			nameClip.x = x;
			nameTxt.clipRect = nameClip;
			nameTxt.x = nameBaseX - x; // ★ 抵消 clipRect 带来的整体右移
		}
		if (folderCycle > 0)
		{
			folderTime += elapsed;
			var t3 = folderTime % folderCycle;
			var travel2 = folderDist / ModsMenuState.MARQ_SPEED;
			var x2:Float = 0;
			if (t3 > ModsMenuState.MARQ_HOLD)
			{
				var t4 = t3 - ModsMenuState.MARQ_HOLD;
				x2 = (t4 < travel2) ? (t4 * ModsMenuState.MARQ_SPEED) : folderDist;
			}
			folderClip.x = x2;
			folderTxt.clipRect = folderClip;
			folderTxt.x = folderBaseX - x2; // ★ 同上
		}
	}
}

// ══════════════════════════════════════════════════════════════════════
// 窗口条图标按钮（使用原版 modsMenuButtons.png 的帧）
// ══════════════════════════════════════════════════════════════════════
class BarButton
{
	public var labelKey:String;
	public var hovered:Bool = false;
	public var x:Float;
	public var y:Float;
	var bg:FlxSprite;
	var icon:FlxSprite;
	var onClick:Void->Void;

	public function new(x:Float, y:Float, frame:Int, labelKey:String, onClick:Void->Void)
	{
		this.x = x;
		this.y = y;
		this.labelKey = labelKey;
		this.onClick = onClick;

		bg = FlxSpriteUtil.drawRoundRect(new FlxSprite(x, y).makeGraphic(26, 26, FlxColor.TRANSPARENT), 0, 0, 26, 26, 7, 7, 0xFFFFFFFF);
		bg.alpha = 0;

		icon = new FlxSprite(x + 2, y + 2);
		var img = Paths.image('modsMenuButtons');
		if (img != null)
		{
			icon.loadGraphic(img, true, 54, 54);
			icon.animation.add('icon', [frame]);
			icon.animation.play('icon');
			icon.scale.set(22 / 54, 22 / 54);
			icon.updateHitbox();
		}
		else
		{
			icon.makeGraphic(22, 22, ModsMenuState.C_DIM);
		}
		icon.color = ModsMenuState.C_DIM;
	}

	public function addTo(state:FlxState, cam:FlxCamera)
	{
		for (s in [bg, icon])
		{
			s.cameras = [cam];
			s.scrollFactor.set();
			state.add(s);
		}
	}

	/** 工具条区域焦点（键盘/手柄选中）*/
	public function setFocus(v:Bool):Void
	{
		if (v == focused) return;
		focused = v;
		bg.alpha = v ? 0.26 : (hovered ? 0.16 : 0);
		icon.color = (v || hovered) ? FlxColor.WHITE : ModsMenuState.C_DIM;
	}

	/** 无模组时整条工具条一起隐藏 */
	public function setVisible(v:Bool):Void
	{
		bg.visible = v;
		icon.visible = v;
	}

	public var focused:Bool = false;

	public function updateHover()
	{
		if (!bg.visible) return; // 空状态工具条整条隐藏时不许再响应点击
		var over = ModsMenuState.pointerOver(x, y, 26, 26);
		if (over != hovered)
		{
			hovered = over;
			bg.alpha = over ? 0.16 : 0;
			icon.color = over ? FlxColor.WHITE : ModsMenuState.C_DIM;
		}
		if (hovered && ModsMenuState.pointerJustPressed())
		{
			ModsMenuState.dbg('  -> click [tool:' + labelKey + '] at(' + Std.int(ModsMenuState.pointerX()) + ',' + Std.int(ModsMenuState.pointerY()) + ')');
			onClick();
		}
	}
}

// ══════════════════════════════════════════════════════════════════════
// 左栏顶部标签按钮（原型 .tab：圆点 + 文字 + 数字胶囊 + 扁平选中填充）
// ══════════════════════════════════════════════════════════════════════
class TabButton
{
	public var x:Float;
	public var y:Float;
	public var w:Int;
	public var h:Int;
	public var hovered:Bool = false;
	public var dbgName:String = '';

	var bg:FlxSprite;
	var dot:FlxSprite;
	var label:FlxText;
	var countBg:FlxSprite;
	var countTxt:FlxText;
	var onClick:Void->Void;
	var active:Bool = false;
	var count:Int = 0;
	var labelKey:String;
	var sprites:Array<FlxSprite> = [];

	public function new(x:Float, y:Float, w:Int, h:Int, labelKey:String, dotColor:FlxColor, onClick:Void->Void)
	{
		this.x = x;
		this.y = y;
		this.w = w;
		this.h = h;
		this.labelKey = labelKey;
		this.onClick = onClick;

		// 扁平填充（选中 12% / 悬停 5%），直角贴边 —— 不是圆角药丸
		bg = new FlxSprite(x, y).makeGraphic(w, h, 0xFFFFFFFF, true);
		bg.alpha = 0;

		// 状态圆点：8x8 圆角 = 圆形
		dot = FlxSpriteUtil.drawRoundRect(new FlxSprite(x, y).makeGraphic(8, 8, FlxColor.TRANSPARENT, true), 0, 0, 8, 8, 4, 4, dotColor);

		label = new FlxText(x, y, 0, Language.get(labelKey, 'mods'), 13);
		label.setFormat(Paths.font(Language.get('fontName', 'main') + '.ttf'), 13, ModsMenuState.C_TEXT);

		// 数字胶囊（原型 .tab .n）
		countBg = FlxSpriteUtil.drawRoundRect(new FlxSprite(x, y).makeGraphic(26, 17, FlxColor.TRANSPARENT, true), 0, 0, 26, 17, 8, 8, 0x1AFFFFFF);
		countTxt = new FlxText(x, y, 26, '0', 11);
		countTxt.setFormat(Paths.font(Language.get('fontName', 'main') + '.ttf'), 11, ModsMenuState.C_DIM, CENTER);

		sprites = [bg, dot, label, countBg, countTxt];
		layout();
		applyVisual();
	}

	/** 内容整体居中：[圆点] 7 [文字] 7 [胶囊] */
	function layout()
	{
		var total = 8 + 7 + label.width + 7 + 26;
		var cx = x + (w - total) / 2;
		dot.x = cx;
		dot.y = y + (h - 8) / 2;
		label.x = cx + 8 + 7;
		label.y = y + (h - label.height) / 2;
		countBg.x = cx + 8 + 7 + label.width + 7;
		countBg.y = y + (h - 17) / 2;
		countTxt.x = countBg.x;
		countTxt.y = countBg.y + 1;
	}

	public function setCount(v:Int)
	{
		if (count == v) return;
		count = v;
		countTxt.text = Std.string(v);
		layout();
	}

	public function setActive(v:Bool)
	{
		active = v;
		applyVisual();
	}

	function applyVisual()
	{
		bg.alpha = active ? 0.12 : (hovered ? 0.05 : 0);
		label.alpha = active ? 1 : 0.72;
		countBg.alpha = active ? 1 : 0.7;
		countTxt.alpha = active ? 1 : 0.8;
		countTxt.color = active ? ModsMenuState.C_TEXT : ModsMenuState.C_DIM;
	}

	public function addTo(state:ModsMenuState, cam:FlxCamera)
	{
		for (s in sprites)
		{
			s.cameras = [cam];
			s.scrollFactor.set();
			state.add(s);
		}
	}

	public function setVisible(v:Bool)
	{
		for (s in sprites) s.visible = v;
	}

	public function updateHover()
	{
		if (!bg.visible) return;
		var over = ModsMenuState.pointerOver(x, y, w, h);
		if (over != hovered)
		{
			hovered = over;
			label.color = over ? ModsMenuState.C_ACCENT : ModsMenuState.C_TEXT;
			applyVisual();
		}
		if (over && ModsMenuState.pointerJustPressed())
		{
			ModsMenuState.dbg('  -> click [' + dbgName + '] rect=(' + Std.int(x) + ',' + Std.int(y) + ',' + w + ',' + h + ')');
			onClick();
		}
	}
}

// ══════════════════════════════════════════════════════════════════════
// 通用文字按钮（底部三按钮 / 窗口条文字按钮 / 确认框按钮）
// ══════════════════════════════════════════════════════════════════════
class FlatButton
{
	public var x:Float;
	public var y:Float;
	public var w:Float = 120;
	public var h:Float = 26;
	public var highlight:Bool = false;
	public var hovered:Bool = false;
	public var active:Bool = false;
	/** 调试用名字（点击时写进 modsmenu_debug.log） */
	public var dbgName:String = '';

	/**
	 * true = 无底色（底部三按钮）。
	 * ★ 注意：必须是属性 —— 老代码里先 setSize() 再 `flat = true`，
	 *   而 setSize 时 flat 还是 false，于是把白色圆角矩形画进了底图（标签曾被画成药丸）。
	 */
	public var flat(default, set):Bool = false;

	function set_flat(v:Bool):Bool
	{
		if (flat == v) return v;
		flat = v;
		redrawBg();
		applyBg();
		return v;
	}

	var bg:FlxSprite;
	var txt:FlxText;
	var onClick:Void->Void;
	var enabled:Bool = true;

	public function new(x:Float, y:Float, text:String, onClick:Void->Void)
	{
		this.x = x;
		this.y = y;
		this.onClick = onClick;
		bg = new FlxSprite(x, y);
		txt = new FlxText(x, y + 6, 120, text, 12);
		txt.setFormat(Paths.font(Language.get('fontName', 'main') + '.ttf'), 12, ModsMenuState.C_TEXT, CENTER);
		redrawBg();
		applyBg();
	}

	/** ★ unique = true：FlxSprite.makeGraphic 会按「宽x高:颜色」缓存并共享同一张位图，
	 *  往共享位图上 drawRoundRect 会污染所有同尺寸精灵（老代码就是踩了这个坑）。 */
	function redrawBg()
	{
		var iw:Int = Std.int(Math.max(1, w));
		var ih:Int = Std.int(Math.max(1, h));
		bg.makeGraphic(iw, ih, FlxColor.TRANSPARENT, true);
		if (!flat && iw > 4) FlxSpriteUtil.drawRoundRect(bg, 0, 0, iw, ih, 7, 7, 0xFFFFFFFF);
	}

	public function setSize(w:Int, h:Int)
	{
		this.w = w;
		this.h = h;
		redrawBg();
		txt.x = x;
		txt.y = y + (h - txt.height) / 2;
		txt.fieldWidth = w;
		applyBg();
	}

	function applyBg()
	{
		if (!enabled) bg.alpha = 0.02;
		else if (flat) bg.alpha = hovered ? 0.10 : (active ? 0.14 : 0);
		else bg.alpha = hovered ? 0.16 : (active ? 0.14 : 0.06);
	}

	public function setText(s:String)
	{
		txt.text = s;
		txt.y = y + (h - txt.height) / 2;
	}

	/** 同时挪 x/y（空状态两个按钮要摆到正文下方居中） */
	public function setPos(nx:Float, ny:Float)
	{
		x = nx;
		y = ny;
		bg.setPosition(nx, ny);
		txt.x = nx;
		txt.y = ny + (h - txt.height) / 2;
	}

	public function setActive(v:Bool)
	{
		active = v;
		txt.alpha = v ? 1 : 0.75;
		applyBg();
	}

	public function setX(nx:Float)
	{
		x = nx;
		bg.x = nx;
		txt.x = nx;
	}

	public function setEnabled(v:Bool)
	{
		enabled = v;
		txt.alpha = v ? (active ? 1 : 0.95) : 0.35;
		applyBg();
	}

	public function setVisible(v:Bool)
	{
		bg.visible = v;
		txt.visible = v;
	}

	public function addTo(state:ModsMenuState, cam:FlxCamera)
	{
		for (s in [bg, txt])
		{
			s.cameras = [cam];
			s.scrollFactor.set();
			state.add(s);
		}
		state.allButtons.push(this);
	}

	public function updateHover()
	{
		if (!bg.visible) return;
		var over = ModsMenuState.pointerOver(x, y, w, h);
		if (over != hovered)
		{
			hovered = over;
			txt.color = over ? ModsMenuState.C_ACCENT : ModsMenuState.C_TEXT;
			applyBg();
		}
		if (over && enabled && ModsMenuState.pointerJustPressed())
		{
			ModsMenuState.dbg('  -> click [' + dbgName + '] rect=(' + Std.int(x) + ',' + Std.int(y) + ',' + Std.int(w) + ',' + Std.int(h) + ')');
			onClick();
		}
	}
}

// ══════════════════════════════════════════════════════════════════════
// 详情右上角【启用 / 禁用】开关
//   ★ 直接复用设置界面那个开关（source/options/objects/backend/BoolButton.hx）的
//     控件与参数：同一个 general.shapeEx.Rect 圆角矩形，同一个尺寸比例
//     （轨道宽:高 ≈ 4:1、滑块 = 轨道宽的一半）、同一组颜色
//     （关 = 0xFF6363 / 开 = 0x63FF75、滑块白 0.8、整体 alpha 0.8），
//     连滑块 0.2 秒 quadOut 的位移动画和每帧朝目标色插值的做法都照搬，
//     所以它看起来和设置里的一模一样。
//   右侧补一个状态文字 + 一句"点击切换启用状态"（模组菜单没有设置项那样的标题行）。
// ══════════════════════════════════════════════════════════════════════
class SwitchButton
{
	// 与 BoolButton 完全一致的两个目标色
	static inline var COL_OFF:FlxColor = 0xFF6363;
	static inline var COL_ON:FlxColor = 0x63FF75;
	// 轨道尺寸（≈4:1，和设置里一致）；滑块 = W/2-4 x H-6，位置 2 / W/2+1
	static inline var TRACK_W:Float = 112;
	static inline var TRACK_H:Float = 30;
	static inline var KNOB_PAD:Float = 2; // 滑块离轨道边 2px（BoolButton: x=2）
	static inline var KNOB_PAD_Y:Float = 3; // BoolButton: y=3

	var x:Float;
	var y:Float;
	var w:Int = 200;
	var h:Int = 30;
	var track:Rect;
	var knob:Rect;
	var txt:FlxText;
	var hint:FlxText;
	var onClick:Void->Void;
	var state:Bool = true;
	var hovered:Bool = false;
	var curCol:FlxColor = COL_ON; // 每帧朝目标色插值（同 BoolButton.updateBgColor）
	var knobTween:FlxTween = null;

	public function new(x:Float, y:Float, onClick:Void->Void)
	{
		this.x = x;
		this.y = y;
		this.onClick = onClick;

		var round:Float = TRACK_W / 20; // BoolButton: 圆角 = 宽/20
		track = new Rect(x, y, TRACK_W, TRACK_H, round, round, COL_ON, 0.8);
		knob = new Rect(x + KNOB_PAD, y + KNOB_PAD_Y, TRACK_W / 2 - KNOB_PAD * 2, TRACK_H - KNOB_PAD_Y * 2, round, round, FlxColor.WHITE, 0.8);

		txt = new FlxText(x, y, 0, Language.get('enabledLabel', 'mods'), 14);
		txt.setFormat(Paths.font(Language.get('fontName', 'main') + '.ttf'), 14, 0xFF7DE3A6);
		hint = new FlxText(x, y, 0, Language.get('toggleHint', 'mods'), 11);
		hint.setFormat(Paths.font(Language.get('fontName', 'main') + '.ttf'), 11, ModsMenuState.C_HINT);

		layout();
		setState(true, true);
	}

	/** 总宽 = [轨道][12][状态文字][10][提示] */
	function layout()
	{
		w = Std.int(TRACK_W + 12 + txt.width + 10 + hint.width);
		h = Std.int(TRACK_H);
		track.x = x;
		track.y = y;
		knob.y = y + KNOB_PAD_Y;
		txt.x = x + TRACK_W + 12;
		txt.y = y + (h - txt.height) / 2;
		hint.x = txt.x + txt.width + 10;
		hint.y = y + (h - hint.height) / 2;
	}

	public function addTo(state0:ModsMenuState, cam:FlxCamera)
	{
		for (s in [track, knob, txt, hint])
		{
			s.cameras = [cam];
			s.scrollFactor.set();
			state0.add(s);
		}
	}

	/** 右对齐用：左边界（详情标题据此决定可用宽度） */
	public function left():Float
	{
		return x;
	}

	/** 无模组时一起隐藏 */
	public function setVisible(v:Bool):Void
	{
		track.visible = v;
		knob.visible = v;
		txt.visible = v;
		hint.visible = v;
	}

	public function setRight(rx:Float)
	{
		setX(rx - w);
	}

	public function setX(nx:Float)
	{
		x = nx;
		layout();
	}

	/** 换状态：滑块 0.2 秒 quadOut 滑过去（BoolButton.updateDisplay 同款） */
	public function setState(v:Bool, instant:Bool = false)
	{
		state = v;
		txt.text = v ? Language.get('enabledLabel', 'mods') : Language.get('disabledLabel', 'mods');
		txt.color = v ? 0xFF7DE3A6 : 0xFFF79A9A;
		layout();

		var targetX:Float = v ? (x + TRACK_W / 2 + 1) : (x + KNOB_PAD);
		if (instant)
		{
			knob.x = targetX;
		}
		else
		{
			if (knobTween != null) knobTween.cancel();
			knobTween = FlxTween.tween(knob, {x: targetX}, 0.2, {ease: FlxEase.quadOut});
		}
		if (instant) curCol = v ? COL_ON : COL_OFF;
	}

	public function updateHover()
	{
		if (!track.visible) return; // 空状态整块隐藏时不许再响应点击
		var over = ModsMenuState.pointerOver(x, y, w, h);
		if (over != hovered)
		{
			hovered = over;
			txt.color = over ? ModsMenuState.C_ACCENT : (state ? 0xFF7DE3A6 : 0xFFF79A9A);
		}
		if (over && ModsMenuState.pointerJustPressed())
		{
			ModsMenuState.dbg('  -> click [detail:toggle] at(' + Std.int(ModsMenuState.pointerX()) + ',' + Std.int(ModsMenuState.pointerY()) + ')');
			onClick();
		}
		// 每帧朝目标色插值（复刻 BoolButton.updateBgColor；悬停时整体亮一点）
		var target:FlxColor = state ? COL_ON : COL_OFF;
		if (hovered) target = FlxColor.interpolate(target, FlxColor.WHITE, 0.18);
		curCol = FlxColor.interpolate(curCol, target, 0.2);
		track.color = curCol;
	}
}
