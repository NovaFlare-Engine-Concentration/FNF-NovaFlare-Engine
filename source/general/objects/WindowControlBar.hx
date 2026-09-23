package general.objects;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.group.FlxSpriteGroup;
import flixel.graphics.FlxGraphic;
import flixel.math.FlxPoint;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import lime.graphics.Image;
import openfl.display.BitmapData;
import openfl.utils.Assets;
#if sys
import sys.io.File;
import sys.FileSystem;
#end

import general.backend.Paths;
import general.backend.Mods;
import general.backend.language.Language;
import general.backend.device.Native;

/**
 * 引擎自绘的“窗口控制条”（替代系统标题栏）。
 *
 * 两种模式：
 *  - CONSTANT（编辑器等）：常驻显示在界面顶栏右侧 —— [图标 NovaFlare Engine] │ - □ ×
 *  - AUTO_HIDE（所有普通界面）：平时完全隐藏，鼠标靠近窗口顶部时平滑滑入
 *    一条标题栏（含图标标题与 - □ × 与拖拽区），离开后自动滑出。
 *
 * 功能与系统标题栏一致：
 *  - 最小化 / 最大化还原 / 关闭（悬停高亮，Win11 风格，× 悬停变红）
 *  - 按住空白处拖动窗口、双击最大化 / 还原
 *
 * 组件由 `FlxG.signals.postUpdate` 全局驱动（不依赖具体状态的 update 链），
 * 只要游戏主循环在跑，按钮就始终响应。
 */
class WindowControlBar extends FlxSpriteGroup
{
	public static final BAR_HEIGHT:Int = 36;
	public static final BTN_W:Int = 46;

	/**
	 * AUTO_HIDE 条的「唤出触发带」（逻辑像素）：只有光标进入窗口顶部这么窄的
	 * 一条，才会把条拉出来。
	 *
	 * 原实现复用「条高 + 12」（=48px）当触发带：鼠标在窗口上部随便一晃就会
	 * 弹出条，误触严重。改为贴边 5px —— 只有真正把光标顶到窗口上沿（或全屏
	 * 时甩到屏幕顶端）才会唤出。
	 */
	public static final REVEAL_STRIP:Float = 5;

	/**
	 * 展开后的「保持带」余量：条已经拉出来后，光标只要停在条体
	 * （BAR_HEIGHT）加这点余量以内就不会自动回缩 —— 否则 5px 的触发带会让
	 * 光标一往下移去点按钮，条就立刻收回去，按钮根本点不到。
	 */
	static final KEEP_STRIP:Float = 4;

	// 悬停按钮的用途
	static final BTN_NONE:Int = 0;
	static final BTN_MIN:Int = 1;
	static final BTN_MAX:Int = 2;
	static final BTN_CLOSE:Int = 3;
	static final BTN_RESTORE:Int = 4; // 恢复到默认窗口大小/位置

	/** 全局每帧驱动 */
	static var tickers:Array<WindowControlBar> = [];
	static var tickHook:Bool = false;

	public var mode:WindowBarMode;

	// ---- 视觉元素 ----
	var iconSpr:FlxSprite;
	var titleTxt:FlxText;
	var sepLine:FlxSprite;
	var barBg:FlxSprite; // AUTO_HIDE 的整条背景
	var bottomLine:FlxSprite; // AUTO_HIDE 的底部分隔线
	var minHover:FlxSprite;
	var maxHover:FlxSprite;
	var closeHover:FlxSprite;
	var restoreHover:FlxSprite;
	var glyphGroup:FlxSpriteGroup;

	// ---- 布局（逻辑坐标） ----
	var minX:Float = 0;
	var maxX:Float = 0;
	var closeX:Float = 0;
	var restoreX:Float = 0;
	var lastLayoutW:Int = -1;

	// ---- 交互状态 ----
	var hoverBtn:Int = BTN_NONE;
	var isMaximized:Bool = false;
	var isFullscreen:Bool = false;
	var maxStateTimer:Float = 0;
	var lastClickTime:Float = -1;
	var lastClickX:Float = -99999;
	var lastClickY:Float = -99999;
	// 单击（标题区）与拖窗的区分
	var dragCandidate:Bool = false;
	var dragDownX:Float = 0;
	var dragDownY:Float = 0;
	var clickPending:Bool = false;
	var clickPendingTimer:Float = 0;
	var clickPendingX:Float = 0;
	var clickPendingY:Float = 0;

	// ===== 退出按钮（CONSTANT 模式：标题「NovaFlare Engine」左侧） =====
	public var onExitClick:Void->Void = null;
	var exitText:String = null;
	var exitBg:FlxSprite;
	var exitTxt:FlxText;
	var hoverExit:Bool = false;

	// ---- 退出按钮「二次确认」状态 ----
	/** 首次点击后的确认窗口（秒）：这之内再点一次才真正退出 */
	public static final EXIT_CONFIRM_TIME:Float = 1.0;
	/** 原色：半透明白叠层（0x2EFFFFFF 的 RGB + alpha 拆开存放） */
	static final EXIT_BG_NORMAL_COLOR:FlxColor = 0xFFFFFFFF;
	/** 0x2E / 255，写成字面量避免 static final 非恒定初始化 */
	static final EXIT_BG_NORMAL_ALPHA:Float = 0.180392;
	/** 警示色：与 × 悬停红一致 */
	static final EXIT_BG_ARM_COLOR:FlxColor = 0xFFC42B1C;
	static final EXIT_TXT_NORMAL:FlxColor = 0xFFE8E8E8;
	static final EXIT_TXT_ARM:FlxColor = 0xFFFFFFFF;

	/** 已进入「点击一次、等待确认」状态 */
	var exitArmed:Bool = false;
	/** 确认状态已流逝时间（0 → EXIT_CONFIRM_TIME） */
	var exitArmTimer:Float = 0;

	/** CONSTANT 模式：单击标题/图标区（未拖动）时触发（如弹出 Mod 信息） */
	public var onTitleClick:Void->Void = null;

	/** 标题块（图标 + 标题文本）的左缘 X（逻辑坐标，供下拉面板对齐） */
	public function titleAnchorX():Float
	{
		return (iconSpr != null) ? iconSpr.x : 0;
	}

	/** 标题块宽度（图标 + 标题文本 + 间距） */
	public function titleBlockWidth():Float
	{
		if (titleTxt == null)
			return 0;
		var right:Float = titleTxt.x + titleTxt.width;
		return (right - titleAnchorX()) + 4;
	}

	// ---- AUTO_HIDE 动画状态 ----
	var slideY:Float = 0; // 0=完全展开, -BAR_HEIGHT=完全隐藏
	var showTimer:Float = 0;
	var hideTimer:Float = 0;
	var revealed:Bool = false; // 是否处于“唤出”状态

	// ---- 关闭淡出动效状态 ----
	var fadeOutState:Int = 0; // 0=无 1=淡出中 2=已透明，等待 1s 后关闭
	var fadeOutTimer:Float = 0;


	// ================= 构造 =================

	public function new(?mode:WindowBarMode = null)
	{
		if (mode == null)
			mode = WindowBarMode.CONSTANT;
		super();
		this.mode = mode;
		scrollFactor.set();
		#if (cpp && windows)
		if (!tickHook)
		{
			tickHook = true;
			FlxG.signals.postUpdate.add(tickAll);
		}
		tickers.push(this);

		buildUI();
		relayout();

		if (mode == WindowBarMode.AUTO_HIDE)
		{
			slideY = -BAR_HEIGHT;
			visible = false;
		}
		#end
	}

	static function tickAll():Void
	{
		var dt:Float = FlxG.elapsed;
		var i:Int = tickers.length - 1;
		while (i >= 0)
		{
			var bar:WindowControlBar = tickers[i];
			if (bar != null)
				bar.updateTick(dt);
			i--;
		}
	}

	/**
	 * 窗口模式（普通/最大化/全屏）切换后由 WindowChromeManager 调用：
	 * 强制重排并重建按钮图形、清空 hover 状态 —— 切换瞬间的 resize 事件
	 * 风暴可能让条内部的布局/高亮状态残留（表现为按钮消失/错位/全亮）。
	 */
	public static function refreshAllBars():Void
	{
		for (bar in tickers)
		{
			if (bar != null && bar.exists)
			{
				bar.relayout();
				bar.hoverBtn = BTN_NONE;
				if (bar.restoreHover != null) bar.restoreHover.visible = false;
				if (bar.minHover != null) bar.minHover.visible = false;
				if (bar.maxHover != null) bar.maxHover.visible = false;
				if (bar.closeHover != null) bar.closeHover.visible = false;
				bar.hoverExit = false;
				if (bar.exitBg != null) bar.exitBg.visible = false;
			}
		}
	}

	// ================= 构建 =================

	function buildUI():Void
	{
		if (mode == WindowBarMode.AUTO_HIDE)
		{
			// 整条深色背景（模拟标题栏）+ 底部 1px 亮线
			barBg = new FlxSprite().makeGraphic(1, BAR_HEIGHT, 0xFF202020);
			barBg.x = 0;
			barBg.y = 0;
			add(barBg);
			bottomLine = new FlxSprite().makeGraphic(1, 1, 0xFF4A4A4A);
			bottomLine.x = 0;
			bottomLine.y = BAR_HEIGHT - 1;
			add(bottomLine);
		}

		// 引擎图标（优先当前 mod 的 pack 图标，其次 icon.ico，最后内置渐变兜底）
		iconSpr = new FlxSprite();
		loadBarIcon();
		iconSpr.y = (BAR_HEIGHT - iconSpr.height) / 2;
		add(iconSpr);

		titleTxt = new FlxText(0, 0, 0, "NovaFlare Engine");
		titleTxt.setFormat(Assets.getFont("assets/fonts/montserrat.ttf").fontName, 13, 0xFFBDBDBD);
		titleTxt.antialiasing = true;
		titleTxt.y = (BAR_HEIGHT - titleTxt.height) / 2;
		add(titleTxt);

		sepLine = new FlxSprite().makeGraphic(1, BAR_HEIGHT - 12, 0xFF4A4A4A);
		sepLine.y = 6;
		add(sepLine);

		// ★ 退出按钮：CONSTANT 模式显示在「NovaFlare Engine」标题左侧（divider 左边）
		//   默认不可见；调用 setExitButton() 后才会渲染并响应点击。
		//   底色用「白色位图 + color/alpha 染色」而不是直接 bake 颜色：
		//   二次确认的红色渐隐动画每帧只改 colorTransform，不重建位图。
		exitBg = new FlxSprite().makeGraphic(1, BAR_HEIGHT, FlxColor.WHITE);
		exitBg.visible = false;
		applyExitVisual(1);
		add(exitBg);
		exitTxt = new FlxText(0, 0, 0, '');
		exitTxt.setFormat(Paths.font(uiLabelFontFileName()), 12, EXIT_TXT_NORMAL);
		exitTxt.antialiasing = true;
		exitTxt.visible = false;
		add(exitTxt);

		// hover 高亮层
		restoreHover = new FlxSprite().makeGraphic(BTN_W, BAR_HEIGHT, 0x26FFFFFF);
		minHover = new FlxSprite().makeGraphic(BTN_W, BAR_HEIGHT, 0x26FFFFFF);
		maxHover = new FlxSprite().makeGraphic(BTN_W, BAR_HEIGHT, 0x26FFFFFF);
		closeHover = new FlxSprite().makeGraphic(BTN_W, BAR_HEIGHT, 0xFFC42B1C);
		restoreHover.visible = false;
		minHover.visible = false;
		maxHover.visible = false;
		closeHover.visible = false;
		add(restoreHover);
		add(minHover);
		add(maxHover);
		add(closeHover);

		glyphGroup = new FlxSpriteGroup();
		add(glyphGroup);
	}

	static inline final ICON_SIZE:Int = 18; // 条内图标显示尺寸

	/**
	 * 加载条上的引擎 / 模组图标：
	 * 1. 当前 mod 的 pack.png / pack-pixel.png（150px 帧；图片宽 >150 时按
	 *    150x150 从左到右、从上到下切帧循环播放 —— 与 Mod 选择界面一致）
	 * 2. 引擎 icon.ico（提取其中最大的 PNG 帧）
	 * 3. 官方小组图标兜底
	 * 4. 蓝紫渐变兜底
	 */
	function loadBarIcon():Void
	{
		// 1) 当前 mod 的 pack 图标
		var folder:String = Mods.currentModDirectory;
		var graphic:FlxGraphic = null;
		var pixelArt:Bool = false;
		if (folder != null && folder.length > 0)
		{
			graphic = Paths.cacheBitmap(Paths.mods('$folder/pack.png'));
			if (graphic == null)
			{
				graphic = Paths.cacheBitmap(Paths.mods('$folder/pack-pixel.png'));
				pixelArt = graphic != null;
			}
		}

		if (graphic != null)
		{
			iconSpr.loadGraphic(graphic, true, 150, 150);
			iconSpr.antialiasing = !pixelArt;
			var frames:Int = Math.floor(graphic.width / 150) * Math.floor(graphic.height / 150);
			if (frames < 1) frames = 1;
			if (frames > 1)
			{
				iconSpr.animation.add('icon', [for (i in 0...frames) i], 10);
				iconSpr.animation.play('icon');
			}
			iconSpr.setGraphicSize(ICON_SIZE, ICON_SIZE);
			iconSpr.updateHitbox();
			return;
		}

		// 2) 引擎 icon.ico（游戏运行目录）
		graphic = loadIcoGraphic();
		if (graphic != null)
		{
			iconSpr.loadGraphic(graphic);
			iconSpr.antialiasing = true;
			iconSpr.setGraphicSize(ICON_SIZE, ICON_SIZE);
			iconSpr.updateHitbox();
			return;
		}

		// 3) 官方小组图标
		graphic = Paths.cacheBitmap(Paths.getSharedPath('images/menuExtend/CreditsState/groupIcon/NovaFlare Engine.png'));
		if (graphic != null)
		{
			iconSpr.loadGraphic(graphic);
			iconSpr.antialiasing = true;
			iconSpr.setGraphicSize(ICON_SIZE, ICON_SIZE);
			iconSpr.updateHitbox();
			return;
		}

		// 4) 蓝紫渐变兜底
		iconSpr.makeGraphic(ICON_SIZE, ICON_SIZE, FlxColor.TRANSPARENT, true);
		var pix = iconSpr.pixels;
		for (y in 0...ICON_SIZE)
		{
			var t:Float = y / (ICON_SIZE - 1);
			var r:Int = Std.int(0x4F + (0x7C - 0x4F) * t);
			var g:Int = Std.int(0xC3 + (0x4D - 0xC3) * t);
			var b:Int = Std.int(0xF7 + (0xFF - 0xF7) * t);
			for (x in 0...ICON_SIZE)
				pix.setPixel32(x, y, (0xFF << 24) | (r << 16) | (g << 8) | b);
		}
		iconSpr.antialiasing = true;
	}

	/** 从运行目录 icon.ico 提取最大的 PNG 帧 */
	static function loadIcoGraphic():FlxGraphic
	{
		#if sys
		try
		{
			if (!FileSystem.exists('icon.ico'))
				return null;
			var bytes = File.getBytes('icon.ico');
			if (bytes.length < 6)
				return null;
			var count:Int = bytes.get(4) | (bytes.get(5) << 8);
			var bestSize:Int = 0;
			var bestOff:Int = -1;
			var bestLen:Int = 0;
			for (i in 0...count)
			{
				var p:Int = 6 + i * 16;
				if (p + 16 > bytes.length)
					break;
				var w:Int = bytes.get(p);
				if (w == 0) w = 256;
				var h:Int = bytes.get(p + 1);
				if (h == 0) h = 256;
				var len:Int = bytes.get(p + 8) | (bytes.get(p + 9) << 8) | (bytes.get(p + 10) << 16) | (bytes.get(p + 11) << 24);
				var off:Int = bytes.get(p + 12) | (bytes.get(p + 13) << 8) | (bytes.get(p + 14) << 16) | (bytes.get(p + 15) << 24);
				if (len > 0 && off + len <= bytes.length && w * h >= bestSize)
				{
					bestSize = w * h;
					bestOff = off;
					bestLen = len;
				}
			}
			if (bestOff < 0)
				return null;
			var data = bytes.sub(bestOff, bestLen);
			// 只支持 PNG 编码的 ICO 帧（现代 .ico 常见）
			if (data.length < 8 || data.get(0) != 0x89 || data.get(1) != 0x50 || data.get(2) != 0x4E || data.get(3) != 0x47)
				return null;
			var img:Image = Image.fromBytes(data);
			var bd:BitmapData = BitmapData.fromImage(img);
			return FlxGraphic.fromBitmapData(bd);
		}
		catch (e:Dynamic) {}
		#end
		return null;
	}

	// ================= 退出按钮 =================

	/**
	 * 当前语言对应的控件文本字体（与编辑器自绘菜单条 `EditorInputStyle.langFontFileName`
	 * 同一逻辑）：读 main 语言组 `fontName`；缺键时若当前语言是 Chinese → Lang-ZH，
	 * 否则 chillax。
	 */
	static function uiLabelFontFileName():String
	{
		var n:String = 'chillax';
		try { n = Language.get('fontName', 'main'); } catch (e:Dynamic) {}
		if (n == null || n == '' || n.indexOf('fontName') != -1 || n.indexOf('404') != -1)
			n = (general.backend.ClientPrefs.data.language == 'Chinese') ? 'Lang-ZH' : 'chillax';
		return n + '.ttf';
	}

	/**
	 * 设置「NovaFlare Engine」标题左侧的退出按钮：
	 *   label = 文案（null/空 → 隐藏按钮）
	 *   cb    = 点击触发
	 * AUTO_HIDE 模式始终隐藏（仅供编辑器 CONSTANT 模式使用）。
	 */
	public function setExitButton(?label:String = null, ?cb:Void->Void = null):Void
	{
		exitText = (label != null && label.length > 0) ? label : null;
		onExitClick = exitText == null ? null : cb;
		resetExitArm();
		if (exitTxt == null) return;
		if (exitText == null)
		{
			exitTxt.visible = false;
			if (exitBg != null) exitBg.visible = false;
			hoverExit = false;
			return;
		}
		exitTxt.text = exitText;
		exitTxt.visible = true;
		hoverExit = false;
		relayout();
	}

	// ================= 退出按钮：二次确认 =================

	/**
	 * 退出按钮底色：t = 0 纯警示红（刚点过第一下、等待确认），t = 1 原始半透明白。
	 * 只改 `color` / `alpha`（等价于更新 colorTransform），每帧调用无分配开销。
	 */
	function applyExitVisual(t:Float):Void
	{
		if (exitBg == null) return;
		if (t < 0) t = 0;
		if (t > 1) t = 1;
		exitBg.color = FlxColor.interpolate(EXIT_BG_ARM_COLOR, EXIT_BG_NORMAL_COLOR, t);
		exitBg.alpha = EXIT_BG_NORMAL_ALPHA + (1 - t) * (1 - EXIT_BG_NORMAL_ALPHA);
	}

	/** 清掉「等待确认」状态，恢复原色（重设按钮文案 / 布局重建后调用） */
	function resetExitArm():Void
	{
		exitArmed = false;
		exitArmTimer = 0;
		if (exitTxt != null) exitTxt.color = EXIT_TXT_NORMAL;
		applyExitVisual(1);
	}

	/** 每帧推进确认动画：1 秒内底色由红渐隐回原样，超时自动解除待确认 */
	function updateExitArm(elapsed:Float):Void
	{
		if (!exitArmed) return;
		exitArmTimer += elapsed;
		if (exitArmTimer >= EXIT_CONFIRM_TIME)
			resetExitArm();
		else
			applyExitVisual(exitArmTimer / EXIT_CONFIRM_TIME);
	}

	/**
	 * 退出按钮点击：
	 *   - 第 1 次：进入待确认状态（底色变红，并在 1 秒内渐隐回原色），不退出；
	 *   - 1 秒之内再点第 2 次：执行 `onExitClick` 真正退出。
	 *   超出 1 秒未再点击 → 自动回到未确认状态，需重新点两下。
	 */
	function handleExitPress():Void
	{
		if (onExitClick == null) return;
		if (exitArmed)
		{
			resetExitArm();
			onExitClick();
			return;
		}
		exitArmed = true;
		exitArmTimer = 0;
		if (exitTxt != null) exitTxt.color = EXIT_TXT_ARM;
		applyExitVisual(0);
	}

	// ================= 布局 =================

	function relayout(?layoutW:Int = 0):Void
	{
		var w:Float = (layoutW > 0) ? layoutW : FlxG.width;

		closeX = w - BTN_W;
		maxX = closeX - BTN_W;
		minX = maxX - BTN_W;

		restoreX = minX - BTN_W;

		if (mode == WindowBarMode.AUTO_HIDE)
		{
			// 整条背景 + 底部线拉满，标题靠左
			barBg.makeGraphic(Std.int(w), BAR_HEIGHT, 0xFF202020);
			barBg.x = 0;
			bottomLine.makeGraphic(Std.int(w), 1, 0xFF4A4A4A);
			bottomLine.x = 0;
			titleTxt.x = 46;
			iconSpr.x = 16;
			sepLine.visible = false;
			sepLine.x = 0;
		}
		else
		{
			// CONSTANT：标题右对齐到"恢复默认"按钮左侧
			var titleRight:Float = restoreX - 16;
			titleTxt.x = titleRight - titleTxt.width;
			iconSpr.x = titleTxt.x - 22;
			sepLine.x = iconSpr.x - 12;
			sepLine.visible = true;

			// 退出按钮：放在分隔线（divider）左侧 12 像素外
			//   —— 编辑器退出按钮总是紧邻「NovaFlare Engine」左边
			if (exitTxt != null && exitText != null && exitText.length > 0)
			{
				var padL:Int = 14, padR:Int = 16;
				var bw:Int = Std.int(exitTxt.width) + padL + padR;
				// 白底位图 + color/alpha 染色（makeGraphic 会把 color/alpha 复位，
				// 所以重建后要重新套用当前状态色，否则待确认的红会丢）
				exitBg.makeGraphic(bw, BAR_HEIGHT, FlxColor.WHITE);
				applyExitVisual(exitArmed ? (exitArmTimer / EXIT_CONFIRM_TIME) : 1);
				exitBg.x = sepLine.x - 12 - bw;
				exitBg.y = 0;
				exitBg.visible = hoverExit || exitArmed;
				exitTxt.x = exitBg.x + padL;
				exitTxt.y = (BAR_HEIGHT - exitTxt.height) / 2;
				exitTxt.visible = true;
			}
			else
			{
				if (exitBg != null) exitBg.visible = false;
				if (exitTxt != null) exitTxt.visible = false;
			}
		}

		restoreHover.x = restoreX;
		minHover.x = minX;
		maxHover.x = maxX;
		closeHover.x = closeX;

		rebuildGlyphs();
		lastLayoutW = Std.int(w);
	}

	function hLine(w:Int, color:FlxColor, parent:FlxSpriteGroup):FlxSprite
	{
		var s = new FlxSprite().makeGraphic(w, 1, color);
		parent.add(s);
		return s;
	}

	function vLine(h:Int, color:FlxColor, parent:FlxSpriteGroup):FlxSprite
	{
		var s = new FlxSprite().makeGraphic(1, h, color);
		parent.add(s);
		return s;
	}

	function rebuildGlyphs():Void
	{
		while (glyphGroup.members.length > 0)
			glyphGroup.remove(glyphGroup.members[0], true);

		// ★ 条隐藏/滑入过程中重建时，glyph 的 y 必须加上当前滑动偏移：
		//   FlxSpriteGroup 的成员是"场景坐标"，条 y=slideY 只是批量平移成员；
		//   这里新建的成员不会自动继承平移，若在 slideY≠0 时重建（如全屏切换
		//   后 0.25s 的 □ 状态重建恰逢条滑入），按钮组会与条背景错位一个条高。
		var yOff:Float = (mode == WindowBarMode.AUTO_HIDE) ? slideY : 0;

		// —— 恢复到默认窗口大小：外框 + 中心小方块
		{
			var ox:Float = restoreX + (BTN_W - 12) / 2;
			var oy:Float = (BAR_HEIGHT - 12) / 2 + yOff;
			var t = hLine(12, 0xFFD8D8D8, glyphGroup); t.x = ox; t.y = oy;
			var b = hLine(12, 0xFFD8D8D8, glyphGroup); b.x = ox; b.y = oy + 11;
			var l = vLine(12, 0xFFD8D8D8, glyphGroup); l.x = ox; l.y = oy;
			var r = vLine(12, 0xFFD8D8D8, glyphGroup); r.x = ox + 11; r.y = oy;
			var dot = new FlxSprite().makeGraphic(4, 4, 0xFFD8D8D8);
			dot.x = ox + 4;
			dot.y = oy + 4;
			glyphGroup.add(dot);
		}

		// —— 最小化：横线
		var minLine = hLine(10, 0xFFD8D8D8, glyphGroup);
		minLine.x = minX + (BTN_W - 10) / 2;
		minLine.y = BAR_HEIGHT / 2 + yOff;

		// —— 最大化 / 还原（AUTO_HIDE 的 □ 表示全屏切换，状态看 isFullscreen）
		if (mode == WindowBarMode.AUTO_HIDE ? isFullscreen : isMaximized)
		{
			// 还原：外框 + 内框错位
			// （oy 用 12 与"最大化单框"同基准：全屏时 □ 变还原图标后整体下移
			//   半个图标高，与 - / × 及切换前位置对齐，不会显得偏高）
			var ox:Float = maxX + 13;
			var oy:Float = 12 + yOff;
			var t1 = hLine(10, 0xFFD8D8D8, glyphGroup); t1.x = ox; t1.y = oy;
			var b1 = hLine(10, 0xFFD8D8D8, glyphGroup); b1.x = ox; b1.y = oy + 9;
			var l1 = vLine(9, 0xFFD8D8D8, glyphGroup); l1.x = ox; l1.y = oy;
			var r1 = vLine(9, 0xFFD8D8D8, glyphGroup); r1.x = ox + 9; r1.y = oy;
			var t2 = hLine(7, 0xFFD8D8D8, glyphGroup); t2.x = ox + 2; t2.y = oy + 2;
			var b2 = hLine(7, 0xFFD8D8D8, glyphGroup); b2.x = ox + 2; b2.y = oy + 11;
			var l2 = vLine(6, 0xFFD8D8D8, glyphGroup); l2.x = ox + 2; l2.y = oy + 2;
			var r2 = vLine(6, 0xFFD8D8D8, glyphGroup); r2.x = ox + 9; r2.y = oy + 2;
			// 用深色条盖住外框被内框穿过的部分，模拟层级
			var cover = new FlxSprite().makeGraphic(3, 2, mode == WindowBarMode.AUTO_HIDE ? 0xFF202020 : 0xFF3A3A3A);
			cover.x = ox + 2;
			cover.y = oy + 8;
			glyphGroup.add(cover);
		}
		else
		{
			var ox:Float = maxX + (BTN_W - 12) / 2;
			var oy:Float = (BAR_HEIGHT - 12) / 2 + yOff;
			var t = hLine(12, 0xFFD8D8D8, glyphGroup); t.x = ox; t.y = oy;
			var b = hLine(12, 0xFFD8D8D8, glyphGroup); b.x = ox; b.y = oy + 11;
			var l = vLine(12, 0xFFD8D8D8, glyphGroup); l.x = ox; l.y = oy;
			var r = vLine(12, 0xFFD8D8D8, glyphGroup); r.x = ox + 11; r.y = oy;
		}

		// —— 关闭：×（两条 45° 线，绕自身中心旋转）
		var c1 = hLine(10, 0xFFD8D8D8, glyphGroup);
		c1.x = closeX + (BTN_W - 10) / 2;
		c1.y = BAR_HEIGHT / 2 + yOff;
		c1.origin.set(5, 0.5);
		c1.angle = 45;
		var c2 = hLine(10, 0xFFD8D8D8, glyphGroup);
		c2.x = closeX + (BTN_W - 10) / 2;
		c2.y = BAR_HEIGHT / 2 + yOff;
		c2.origin.set(5, 0.5);
		c2.angle = -45;
	}

	// ================= 每帧驱动 =================

	function updateTick(elapsed:Float):Void
	{
		#if (cpp && windows)
		// 保持渲染在最顶层（TitleState 的视频、状态后期 add 的 UI 不会盖住窗口条）
		keepOnTop();

		// 布局基准：FlxG.width（沉浸视口在窗口尺寸变化时由 onMeasure 更新，
		// 按钮组自动贴紧右缘）。不做额外的物理换算，避免抖动。
		if (FlxG.width != lastLayoutW)
			relayout();

		// 窗口按钮状态图标（节流）：□ 反映"非窗口化"（全屏/最大化，显示还原图标）。
		// 注意：沉浸窗口是无边框(WS_POPUP/borderless)，系统 ShowWindow(SW_MAXIMIZE)
		// 会把窗口铺满整个屏幕(=全屏 mode 2)，不存在"工作区最大化(mode 1)"，
		// 所以 CONSTANT 的 □ 语义与 AUTO_HIDE 相同：全屏切换，状态看 windowMode()==2。
		maxStateTimer -= elapsed;
		if (maxStateTimer <= 0)
		{
			maxStateTimer = 0.25;
			var nowFs:Bool = Native.windowMode() == 2;
			if (mode == WindowBarMode.AUTO_HIDE)
			{
				if (nowFs != isFullscreen)
				{
					isFullscreen = nowFs;
					rebuildGlyphs();
				}
			}
			else
			{
				if (nowFs != isMaximized)
				{
					isMaximized = nowFs;
					rebuildGlyphs();
				}
			}
		}

		if (mode == WindowBarMode.AUTO_HIDE)
		{
			updateAutoHide(elapsed);
			y = slideY;
		}
		else
		{
			y = 0;
		}

		// （窗口缩放动画已废弃：最大化/还原直接走系统 ShowWindow，
		//   视口同步由 WindowChromeManager 的轮询对账负责）

		// 关闭淡出：整个窗口透明度 255 → 0（0.45s）→ 保持全透明 0.4s → 真正退出。
		// 用 WS_EX_LAYERED + SetLayeredWindowAttributes 做整窗合成透明度，
		// 淡出的是“程序窗口”本身而不是画面里的元素。
		if (fadeOutState > 0)
		{
			if (fadeOutState == 1)
			{
				// 全屏下 layered 透明度不可靠：先还原窗口再开始淡出
				if (Native.windowMode() != 0)
					Native.windowApplyMode(0);
				else
				{
					fadeOutTimer += elapsed;
					var t:Float = Math.min(1, fadeOutTimer / 0.45);
					Native.windowSetAlpha(Std.int(255 * (1 - t)));
					if (fadeOutTimer >= 0.45)
					{
						Native.windowSetAlpha(0);
						fadeOutState = 2;
						fadeOutTimer = 0;
					}
				}
			}
			else if (fadeOutState == 2)
			{
				fadeOutTimer += elapsed;
				if (fadeOutTimer >= 0.4)
				{
					fadeOutState = 0;
					Native.windowClose();
				}
			}
			return;
		}

		// 退出按钮「二次确认」计时：首次点击后 1 秒内底色由红渐隐回原色。
		// 放在 interaction 之前且不受"光标是否在窗口内"影响，保证动画不被中断。
		updateExitArm(elapsed);

		updateInteraction(elapsed);

		// ★ SpriteGroup 的 visible 切换（AUTO_HIDE 滑入/滑出）会把所有子对象
		//   visible 置 true —— hover 高亮层会被一起点亮。这里每帧无条件按
		//   hoverBtn 校正它们的可见性（不能只靠 clearHover：hoverBtn 为
		//   NONE 时它不会执行）。
		restoreHover.visible = (hoverBtn == BTN_RESTORE);
		minHover.visible = (hoverBtn == BTN_MIN);
		maxHover.visible = (hoverBtn == BTN_MAX);
		closeHover.visible = (hoverBtn == BTN_CLOSE);
		if (sepLine != null)
			sepLine.visible = (mode == WindowBarMode.CONSTANT);
		// 退出按钮背景：CONSTANT 模式 +（鼠标悬停 或 待二次确认）+ 已设置文案时可见
		if (exitBg != null)
			exitBg.visible = (hoverExit || exitArmed) && exitText != null && mode == WindowBarMode.CONSTANT;
		#end
	}

	/** 开始关闭淡出流程：整个窗口透明度逐渐变为 0，然后退出 */
	function startFadeOut():Void
	{
		if (fadeOutState > 0)
			return;
		fadeOutState = 1;
		fadeOutTimer = 0;
	}

	/** 把自己挪到父状态 members 的末尾（最顶层） */
	function keepOnTop():Void
	{
		var st:FlxState = FlxG.state;
		if (st == null || st.members == null || st.members.length == 0)
			return;
		if (st.members[st.members.length - 1] == this)
			return;
		if (st.members.remove(this))
			st.members.push(this);
	}

	/** 光标在窗口内的物理坐标（原生轮询，不依赖鼠标事件）；不在窗口内返回 null */
	function cursorPhys():FlxPoint
	{
		var cx:Int = Native.cursorClientX();
		var cy:Int = Native.cursorClientY();
		if (cx < 0 || cy < 0)
			return null;
		return FlxPoint.get(cx, cy);
	}

	/** 逻辑 X → 渲染后的物理 X（与相机渲染同公式：× scale + 游戏偏移） */
	function physX(logicalX:Float):Float
	{
		var sx:Float = FlxG.scaleMode.scale.x;
		if (sx <= 0) sx = 1;
		return logicalX * sx + FlxG.game.x;
	}

	function physY(logicalY:Float):Float
	{
		var sy:Float = FlxG.scaleMode.scale.y;
		if (sy <= 0) sy = 1;
		return logicalY * sy + FlxG.game.y;
	}

	/** AUTO_HIDE：靠近顶部唤出 / 离开隐藏 + 滑入滑出动画 */
	function updateAutoHide(elapsed:Float):Void
	{
		// ★ 全屏时默认禁止唤出（AUTO_HIDE 条只在窗口化/最大化下可用）：
		//   直接强制收起并跳过唤出判定，条永不可见。
		//   常驻条（编辑器 / Mods 的 CONSTANT 模式）不受影响。
		if (Native.windowMode() == 2)
		{
			revealed = false;
			showTimer = 0;
			hideTimer = 0;
			slideY += (-BAR_HEIGHT - slideY) * Math.min(1, elapsed * 18);
			if (slideY <= -BAR_HEIGHT + 0.05)
				visible = false;
			else
				visible = true;
			return;
		}

		// 原生轮询只用于"光标是否在窗口上 / 是否贴近顶部条带"（物理判定）
		var pos:FlxPoint = cursorPhys();
		var over:Bool = pos != null;
		var myPhys:Float = (pos != null) ? pos.y : 999999;
		if (pos != null)
			pos.put();

		// 唤出触发带 = 窗口顶部 REVEAL_STRIP 逻辑像素的渲染物理高度（贴边 5px）；
		// 已展开后放宽到条体高度 + 余量，保证光标能顺利移到按钮上点击。
		var revealPhys:Float = physY(REVEAL_STRIP) - FlxG.game.y;
		var keepPhys:Float = physY(BAR_HEIGHT + KEEP_STRIP) - FlxG.game.y;
		var inZone:Bool = over && myPhys < (revealed ? keepPhys : revealPhys);

		// 拖动中保持展开
		if (Native.windowDragging())
		{
			showTimer = 0;
			hideTimer = 0;
		}
		else if (inZone)
		{
			// 光标贴到窗口顶部 → 唤出
			showTimer += elapsed;
			hideTimer = 0;
			if (showTimer >= 0.12)
				revealed = true;
		}
		else
		{
			// 光标离开条带 → 收起
			showTimer = 0;
			if (revealed)
			{
				hideTimer += elapsed;
				if (hideTimer >= 0.5)
					revealed = false;
			}
			else
				hideTimer = 0;
		}

		// 滑入 / 滑出动画
		var targetY:Float = revealed ? 0 : -BAR_HEIGHT;
		slideY += (targetY - slideY) * Math.min(1, elapsed * 18);

		if (slideY > -BAR_HEIGHT * 0.98)
			visible = true;
		else if (slideY <= -BAR_HEIGHT + 0.05)
			visible = false;
	}

	/** 按钮 hover / 点击 / 拖动。
	 *  鼠标位置用 `getWorldPosition(本条相机)` 换算 —— flixel 官方变换
	 *  （含相机 zoom / scroll / 视口偏移 / scaleMode），与渲染严格同源。 */
	function updateInteraction(elapsed:Float):Void
	{
		// ★ 全屏时 AUTO_HIDE 条完全禁用交互：条不显示、不 hover、不响应点击
		//   （避免游玩等界面被顶部条干扰；退出全屏用 F11）。
		//   常驻条（编辑器 / Mods 的 CONSTANT 模式）不受影响。
		if (mode == WindowBarMode.AUTO_HIDE && Native.windowMode() == 2)
		{
			clearHover();
			return;
		}

		// ★ 拖动中必须「最优先」处理，且要在一切基于光标位置/条可见性/窗口动画
		//   的判断之前：
		//   快速拖拽时光标会先于窗口移出客户区，此时 cursorPhys() 返回 null
		//   （cursorClientX/Y 用 WindowFromPoint 判定，光标不在本窗口即 -1），
		//   条本身也可能正处于滑动状态；原来这些分支排在前面并直接 return，
		//   导致 windowDragUpdate() 不再被调用 → 窗口停止跟随光标，表现为
		//   "按住拖到一半突然拖不动了/拖拽失效"。
		//   windowDragUpdate() 内部以物理左键状态（GetAsyncKeyState）为准，
		//   松开即自动结束拖动，所以这里不再用 FlxG.mouse.pressed 二次判定
		//   （事件丢失时它会滞后于真实状态，反而会误结束拖动）。
		if (Native.windowDragging())
		{
			Native.windowDragUpdate();
			clearHover();
			return;
		}

		// 窗口缩放动画进行中不响应点击/拖动
		if (Native.windowAnimRunning())
			return;

		// 光标不在窗口上 → 清除高亮，不处理
		var phys:FlxPoint = cursorPhys();
		if (phys == null)
		{
			clearHover();
			return;
		}
		phys.put();

		// ★ 条必须「基本展开」才响应 hover / 点击 / 拖动候选：
		//   AUTO_HIDE 条平时藏在屏幕上方（slideY≈-BAR_HEIGHT），只有鼠标贴顶
		//   才会滑入。若只排除"滑出过半"，则滑入动画进行中（条几乎还没露出来）
		//   时按钮判定已经生效——而下面的 my = 鼠标y - slideY 偏移又会把
		//   屏幕顶部（条尚未覆盖的区域）算进条内坐标，导致"看不到条也能按到
		//   右上角 - □ ×"。这里收紧为只有滑入到接近完整（slideY >= -2）才响应，
		//   与视觉一致（看到条才能点）。
		if (mode == WindowBarMode.AUTO_HIDE && slideY < -2)
		{
			clearHover();
			return;
		}

		// 鼠标在条所在相机里的世界坐标
		var cam:flixel.FlxCamera = (cameras != null && cameras.length > 0) ? cameras[0] : FlxG.camera;
		var mpos:FlxPoint = FlxG.mouse.getWorldPosition(cam);
		var mx:Float = mpos.x;
		var my:Float = mpos.y - ((mode == WindowBarMode.AUTO_HIDE) ? slideY : 0);
		mpos.put();

		// hover 高亮（光标必须在条的可视范围内）
		var overBtn:Int = BTN_NONE;
		if (my >= 0 && my < BAR_HEIGHT)
		{
			if (mx >= closeX && mx < closeX + BTN_W)
				overBtn = BTN_CLOSE;
			else if (mx >= maxX && mx < maxX + BTN_W)
				overBtn = BTN_MAX;
			else if (mx >= minX && mx < minX + BTN_W)
				overBtn = BTN_MIN;
			else if (mx >= restoreX && mx < restoreX + BTN_W)
				overBtn = BTN_RESTORE;
		}
		if (overBtn != hoverBtn)
		{
			hoverBtn = overBtn;
			restoreHover.visible = (hoverBtn == BTN_RESTORE);
			minHover.visible = (hoverBtn == BTN_MIN);
			maxHover.visible = (hoverBtn == BTN_MAX);
			closeHover.visible = (hoverBtn == BTN_CLOSE);
		}

		// 退出按钮 hover（divider 左侧）
		var overExit:Bool = false;
		if (exitBg != null && exitText != null && exitText.length > 0
			&& my >= 0 && my < BAR_HEIGHT
			&& mx >= exitBg.x && mx < exitBg.x + exitBg.width)
			overExit = true;
		if (overExit != hoverExit)
		{
			hoverExit = overExit;
			if (exitBg != null) exitBg.visible = overExit;
		}

		// —— 延迟单击触发（等待双击窗口结束）——
		if (clickPending)
		{
			clickPendingTimer += elapsed;
			if (clickPendingTimer >= 0.3)
			{
				clickPending = false;
				if (mode == WindowBarMode.CONSTANT && onTitleClick != null)
					onTitleClick();
			}
		}

		// —— 拖动候选：按住移动超过阈值才真正拖窗；原地松开视为单击 ——
		if (dragCandidate)
		{
			if (FlxG.mouse.justReleased)
			{
				dragCandidate = false;
				clickPending = true;
				clickPendingTimer = 0;
			}
			else if (!FlxG.mouse.pressed)
				dragCandidate = false;
			else if (Math.abs(mx - dragDownX) > 5 || Math.abs(my - dragDownY) > 5)
			{
				dragCandidate = false;
				Native.windowDragBegin();
			}
		}

		if (!FlxG.mouse.justPressed)
			return;

		// 新按下：取消待触发的单击（可能是双击）
		clickPending = false;

		// 退出按钮单击 —— 优先级最高，避免被当成窗口按钮或拖窗。
		// 首次点击只进入「待确认」（底色变红并 1 秒内渐隐回原色），
		// 1 秒内再点一次才真正执行退出回调（见 handleExitPress）。
		if (overExit && onExitClick != null)
		{
			handleExitPress();
			return;
		}

		if (overBtn == BTN_CLOSE)
		{
			// 关闭：画面淡出，等 1 秒后再真正退出
			startFadeOut();
		}
		else if (overBtn == BTN_MAX)
		{
			// □ = 全屏切换（无边框沉浸窗口的最大化即全屏，两种模式语义一致）
			Native.windowApplyMode(Native.windowMode() == 2 ? 0 : 2);
		}
		else if (overBtn == BTN_MIN)
		{
			// 最小化：直接系统最小化（不带自定义动画）
			Native.windowMinimize();
		}
		else if (overBtn == BTN_RESTORE)
		{
			// 恢复到默认窗口大小与位置（全屏/最大化下先还原再恢复默认）
			if (Native.windowMode() != 0)
				Native.windowApplyMode(0);
			Native.windowRestoreDefault();
		}
		else if (my >= 0 && my < BAR_HEIGHT && isDragZone(mx))
		{
			// 双击最大化 / 还原（无边框窗口的最大化即全屏，双击 = 全屏切换）
			var now:Float = FlxG.game.ticks / 1000;
			if (now - lastClickTime < 0.3 && Math.abs(mx - lastClickX) < 8 && Math.abs(my - lastClickY) < 8)
			{
				lastClickTime = -1;
				dragCandidate = false;
				clickPending = false;
				Native.windowApplyMode(Native.windowMode() == 2 ? 0 : 2);
			}
			else
			{
				lastClickTime = now;
				lastClickX = mx;
				lastClickY = my;
				// 先进入“候选拖动”
				dragCandidate = true;
				dragDownX = mx;
				dragDownY = my;
			}
		}
	}

	function isDragZone(mx:Float):Bool
	{
		// 全屏时窗口铺满屏幕，拖动移动没有意义（也容易误触），禁用拖拽
		if (Native.windowMode() == 2)
			return false;
		if (mode == WindowBarMode.AUTO_HIDE)
			return mx < restoreX; // AUTO_HIDE：除按钮区外整条可拖
		return mx >= sepLine.x + 1 && mx < restoreX; // CONSTANT：分隔线右侧、按钮左侧
	}

	function clearHover():Void
	{
		if (hoverBtn != BTN_NONE)
		{
			hoverBtn = BTN_NONE;
			restoreHover.visible = false;
			minHover.visible = false;
			maxHover.visible = false;
			closeHover.visible = false;
		}
		hoverExit = false;
		if (exitBg != null) exitBg.visible = false;
	}

	// ================= 生命周期 =================

	override function destroy()
	{
		#if (cpp && windows)
		tickers.remove(this);
		if (Native.windowDragging())
			Native.windowDragEnd();
		#end
		super.destroy();
	}
}
