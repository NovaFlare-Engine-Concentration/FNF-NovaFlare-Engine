package options;

import states.mainMenuState.MainMenuState;
import states.freeplayState.FreeplayState;

import options.base.NewControlsSubState;
import options.base.KeyBindsSubState;

import mobile.substates.MobileControlSelectSubState;
import mobile.substates.MobileExtraControl;
#if mobile
import mobile.states.CopyState;
#end

import games.backend.StageData;
import general.backend.ui.PsychUIInputText;

import options.objects.Option.OptionType;

import openfl.Lib;
import openfl.display.BitmapData;
import openfl.geom.Matrix;
import openfl.geom.Rectangle;
import openfl.utils.ByteArray;

import flixel.graphics.FlxGraphic;
import flixel.math.FlxRect;

/**
 * 新版设置界面。
 *
 * 布局与 HTML 原型一致：
 *   · 左侧竖栏（17% 宽，展开时 18.5%）/ 顶部横栏（7vh 高）二选一，用品牌行右侧的按钮切换
 *   · 语言不再单独占一个分类，改成「维护设置」下面的 CN / EN 胶囊
 *   · 点分类时播放三段动画：① 从该菜单行向右延伸 → ② 一分为二 → ③ 拉高到 100%
 *     切换分类时先反跑 ③②① 再对新分类重跑 ①②③
 *   · 返回按钮固定在左下角
 *
 * 设置项内容沿用原有体系（OptionCata / Option / groupData / backend 控件），
 * 所有分类的 OptionCata 都预先摆在同一个面板内容区、只切换可见性 ——
 * 因为 Option.update() 每帧只同步 followX/followY 而不会自己搬位置，
 * 所以「不移动、只显隐」是最省事也不会出错的做法。
 */
class OptionsState extends MusicBeatState
{
	public static var instance:OptionsState;
	/** 检测到底退回到哪个界面 */
	public static var stateType:Int = 0;

	///////////////////////////////////////////////////////////////////////////////
	// 布局比例（与 HTML 原型一致）
	///////////////////////////////////////////////////////////////////////////////

	inline static var SB_W:Float = 0.17;        // 竖向侧边栏宽
	inline static var SB_W_OPEN:Float = 0.185;  // 展开后（吸收缝隙）
	inline static var P_LEFT_START:Float = 0.17; // 面板起点左缘 = 侧边栏右缘
	inline static var P_LEFT_OPEN:Float = 0.20;  // 面板展开后左缘
	inline static var P_RIGHT:Float = 0.08;      // 面板右留白
	inline static var BAR_H:Float = 0.07;        // 横向顶栏高
	inline static var BOTTOM_H:Float = 0.1;      // 底部「返回」栏高（见 buildBottomBar）
	inline static var TIP_LINES:Int = 2;         // 底部「选项说明」最多显示几行（放不下就滚）
	inline static var TIP_X:Float = 0.19;        // 底部说明文本的左缘（避让左下角的「返回」按钮）
	inline static var BAR_GAP:Float = 0.016;     // 顶栏与面板之间的缝隙
	inline static var BAR_SIDE:Float = 0.08;     // 横向模式左右留白（按宽度）
	inline static var HEAD_H:Float = 0.105;      // 面板标题栏高
	inline static var MIN_W:Float = 3;           // 面板动画起点宽度（不能是 0，圆角会算成负数）

	/**
	 * 磨砂面板「玻璃底」的不透明度（HTML 原型：rgba(44,43,56,.64) → rgba(23,22,30,.74)）。
	 * ★ 这是「材质」的透明度，和 setPanelAlpha 的「整体可见度」是两回事，
	 *   以前两者共用一个 alpha，展开时把面板写成了完全不透明，磨砂效果就没了。
	 */
	inline static var GLASS_ALPHA:Float = 0.74;
	/**
	 * 模糊贴图的短边像素数（越小越糊）。
	 *
	 * ★★ 这个值直接决定「磨砂是玻璃还是一片马赛克」★★
	 *   取 160 时，1280 宽的画面要走 8 倍放大 —— 模糊图上的**每一个像素都会变成
	 *   屏幕上 8×8 的方格**。方框模糊只是把格子内部抹平，格子的**边**还在，
	 *   于是整块玻璃变成一张"低分辨率马赛克"，也就是用户说的"好大的 haze"。
	 *   取 256 时倍率降到 2.8×，格子在屏幕上只有 2~3 px，肉眼已经看不出来。
	 *
	 *   源图是 menuDesat（本身就是「模糊 + 去饱和」的 1286×730 贴图），
	 *   所以这里只需要补上「抗锯齿级」的模糊 + 提一点饱和。
	 */
	inline static var FROST_MIN_SIDE:Int = 256;
	/**
	 * 模糊图上的方框模糊半径（像素）。
	 * σ = sqrt(passes) × sqrt(r(r+1)/3)，256 短边时缩放 ×2.84，
	 * 取 r=10 / passes=2 → σ ≈ 8.6 × 2.84 ≈ 24px，正好是原型的 blur(24px)。
	 *
	 * ★ 半径不要缩水：半径太小（以前是 2）压不掉降采样残留的低频格子，
	 *   放大回去就是"方块感"的来源。
	 */
	inline static var FROST_BLUR_RADIUS:Int = 10;
	/** 方框模糊串联次数（2 次已经够接近高斯，且比 3 次省 1/3 时间） */
	inline static var FROST_BLUR_PASSES:Int = 2;
	/**
	 * 提饱和倍数。
	 *
	 * ★ 原型的 saturate(160%) 是作用在**真实页面背景**上的；而这里的源图
	 *   menuDesat **本身就已经是引擎去饱和过的**版本，再乘 1.55 等于把去饱和
	 *   的操作反着做一遍 —— 结果就是那块玻璃上浮出蓝/绿/紫的**花斑**。
	 *   取 1.22：比 1.10 多给一点彩度，但远不到"花斑"的程度（见 FROST_HAZE 的说明）。
	 */
	inline static var FROST_SATURATE:Float = 1.22;

	/**
	 * 模糊图的「反差」倍数（围绕各自通道均值做线性拉伸）。
	 *
	 * ★★ 这是"磨砂看得见 / 看不见"的关键，而它和模糊是一对反作用力 ★★
	 *   模糊的数学本质就是**加权平均**，平均必然把反差压下去：源图本身越平，
	 *   模糊完就越接近一块常数。源图 menuDesat 的中间区域本来就又暗又平
	 *   （wtf 壁纸的左半边是深色天空），σ≈24px 一糊 —— 剩下一条几乎恒定的
	 *   深蓝，透过 74% 的玻璃底之后肉眼就只剩"一块深色板"。
	 *
	 *   所以这里把模糊**之后**的反差拉回来：c' = mean + (c - mean) * k。
	 *   k=1.35 时，模糊后的微弱起伏会被放大 1.35 倍 —— 玻璃上才认得出"形状"。
	 *   上限不能太大：k 过大会让平坦区域也出现色带（banding）。
	 */
	inline static var FROST_CONTRAST:Float = 1.35;

	/**
	 * 雾面提亮（往白里混的比例）。
	 *
	 * ★ 真实磨砂玻璃不是"变模糊的透明玻璃"，它是**散射**：表面那层微结构会把
	 *   一部分光散射回眼睛，所以毛玻璃永远比它背后的东西**更亮、更灰**。
	 *   只做 blur 不做提亮，结果就是"半透明深色板"而不是"毛玻璃"。
	 *
	 *   0.09 ≈ 往白里混 9%：只抬亮一点点，但对"这是玻璃"的判断非常关键。
	 *   数值压得比直觉小 —— 磨砂层在屏幕上只以 26~36% 的权重露出来
	 *   （玻璃底不透明度 0.74 / 0.70），这里放大 1 等于屏幕上放大 0.26。
	 */
	inline static var FROST_HAZE:Float = 0.09;

	/**
	 * 内容区里旧版的大标题（每个分类的第一个 TITLE 项，画的是分类名 + 强调条 + 分隔线）
	 * 要不要藏掉。
	 *
	 * ★ 面板标题栏（panelTitle / panelSub）显示的已经是同一个分类名，
	 *   两者叠在一起就是「常规设置 / General / 常规设置」三段（图1、图4 的样子）。
	 *   HTML 原型里内容区的小节标题是小号强调色文字，分类名只出现在标题栏 ——
	 *   所以这里把旧版大标题整块藏掉，内容区从标题栏下面开始。
	 *   想恢复旧观感就把这个改成 false（内容区会重新空出那段高度）。
	 */
	inline static var HIDE_LEGACY_CATA_TITLE:Bool = true;

	// ★ 硬规则：**任何一组动画的总时长都不超过 0.5s**。
	//   ★★ 关键：`showContent()` 结尾的 `fadeContent(1, …)` 是**串行**接在结构补间后面的，
	//      它必须一起算进这一组的预算里 —— 否则「0.5s 的结构 + 0.22s 的淡入 = 0.72s」，
	//      看着就是"动画没变快"（本轮实测竖→横 0.81s 就是这么来的）。
	//   所以结构三段压到 0.38s，给收尾淡入留 REVEAL = 0.10s，合计 0.48s。
	//   - 展开   = A1+A2+A3 = 0.16+0.11+0.11 = 0.38  (+REVEAL 0.10) = 0.48 ✓
	//   - 模式切换 = MA+MB   = 0.19+0.19      = 0.38  (+REVEAL 0.10) = 0.48 ✓
	//   - 收起   = R1+R2+R3 = 0.25                     （后面没有淡入）  = 0.25 ✓
	//   - 普通换分类 = 卡片补间 0.5 ∥ 淡入 0.22（并行，取大者）        = 0.50 ✓
	//   侧栏列表的展开/收起（NaviGroup 的 LIST_DUR + LIST_STAGGER × 间隔数）
	//   和卡片自己的补间（Option/OptionCata 的默认 time）同样按这条线卡。
	//   改任何一个分段的时长，都要回来核对它所在的**整条链**总和。
	inline static var A1:Float = 0.16;
	inline static var A2:Float = 0.11;
	inline static var A3:Float = 0.11;
	inline static var R1:Float = 0.085;
	inline static var R2:Float = 0.075;
	inline static var R3:Float = 0.09;
	inline static var MA:Float = 0.19;
	inline static var MB:Float = 0.19;

	/** 结构动画（展开 / 模式切换）收尾时内容淡入的时长 —— 串行加在结构补间之后，必须计入 0.5s 预算 */
	inline static var REVEAL:Float = 0.10;

	/** 一级分类顺序（语言已移出，见侧边栏 CN / EN） */
	public static var CATA_NAMES:Array<String> = [
		'General', 'User Interface', 'GamePlay', 'Game UI', 'Skin', 'Input', 'Audio', 'Graphics', 'Maintenance'
	];

	///////////////////////////////////////////////////////////////////////////////

	public var baseColor = 0x302E3A;
	public var mainColor = 0x24232C;

	public var mouseEvent:MouseEvent;
	public var stringCount:Array<StringSelect> = [];

	/** 下面三个字段大量控件类都会读（判断「鼠标是否压在 UI 上」「是否正在滚动」），必须保留 */
	public var specBG:Rect;
	public var downBG:Rect;
	public var cataMove:MouseMove;

	var naviArray:Array<NaviData> = [];
	public var cataGroup:Array<OptionCata> = [];

	var barV:NaviGroup;
	var barH:NaviGroup;
	/** 面板的磨砂玻璃底：整块「一个 quad」的直角平板（见 Slab 的注释，为什么不用 RoundRect） */
	var panelBG:Slab;

	/** 磨砂玻璃层：背景的模糊版，用 clipRect 裁到面板 / 两条栏的范围 */
	var frostGfx:FlxGraphic;
	var frostPanel:FlxSprite;
	var frostBarV:FlxSprite;
	var frostBarH:FlxSprite;
	var frostCache:Map<FlxSprite, FlxRect> = new Map();
	var panelTitle:FlxText;
	var panelSub:FlxText;
	var panelCount:FlxText;
	var headLine:Rect;
	var backButton:GeneralBack;
	var tipText:FlxText;
	/**
	 * 底部「选项说明」的滚动状态。
	 *
	 * ★ 这里显示的是 `Option.tips`（真正的解释），不是卡片里的 `Option.description`
	 *   （那只是简称/选项名）。鼠标在一个设置项上停 0.2s 后由 `Option.update()`
	 *   调 `changeTip()` 把它送过来。
	 *   原来 tipText 是 `new FlxText(0, 0, 0, ...)` —— fieldWidth = 0，
	 *   永远只有一行，长说明一路冲出屏幕右缘（用户报的"说明文本还是一行"）。
	 */
	var tipMaxScroll:Int = 0;
	var tipScrollV:Int = 0;
	/** 说明文本的"两行窗口"是懒量的：文本刚 set 时 textHeight 还没算出来 */
	var tipNeedFit:Bool = false;
	var tipFitDelay:Int = 0;
	var hintText:FlxText;
	var hintSub:FlxText;
	var hintMark:FlxText;
	var resetButton:ResetButton;

	/**
	 * 背景压暗遮罩（对应原型 `#bgTint`）。
	 *
	 * ★ 原型的背景从来不是"原图直出"：`#bgTint` 在背景之上盖了两层**同色**
	 *   （rgba(11,10,17,·)）的渐变 —— 一圈径向 + 一条竖向。少了它，背景里那片
	 *   高亮天空会亮到"顶穿"玻璃：侧栏与面板之间那道 19px 的设计缝里，露出的是
	 *   未经压暗的生蓝天，夹在两块深色玻璃中间，看起来就是一条发光的穿模竖线。
	 *   底部同理 —— 原型靠"底部压暗 42%"让画面自然沉下去，而不是靠一块
	 *   不透明的深色横条（那是旧 downBG 的做法，见 buildBottomBar）。
	 */
	var bgTint:FlxSprite;

	/** 'v' 竖向侧边栏 / 'h' 横向顶栏 */
	public var mode:String = 'v';
	var currentCata:OptionCata = null;

	var panelX:Float = 0;
	var panelY:Float = 0;
	var panelW:Float = 0;
	var panelH:Float = 0;
	var originRowY:Float = 0;
	var originRowH:Float = 0;

	/** 动画播放期间锁输入 */
	public var inputLocked:Bool = false;
	var seqToken:Int = 0;
	var pendingCata:String = '';

	/**
	 * 本帧「语言区块是否吃掉鼠标」（两条栏任一命中即为真）。
	 * 每帧只算一次，供 NaviMember 让开 hover 高亮与点击 ——
	 * 见 NaviGroup.langSwallowsMouse()。
	 */
	public var langBlockSwallow:Bool = false;

	/** 内容滚动量，由 cataMove 通过反射写入（与原实现保持同一套做法） */
	static public var contentScrollPos:Float = 0;
	var contentBaseY:Float = 0;
	/** 内容可视区的左缘（= 分类的 x；横向模式面板摊开后内容要在面板里居中，所以它不是常量） */
	var contentBaseX:Float = 0;
	var contentMaxScroll:Float = 0;

	var headH(get, never):Float;
	inline function get_headH():Float return FlxG.height * HEAD_H;

	/**
	 * 内容可视区上下再留一点呼吸空间。
	 *
	 * ★ 不留的话，滚到顶时第一行会紧贴标题栏的分割线、滚到底时最后一行紧贴
	 *   底部「返回」栏 —— 观感上就是"选项被上下挤住了"。这个 padding 同时用在
	 *   裁剪区（refreshContentLayout）和可滚范围（measureContent）上，两者必须一致，
	 *   否则滚到底还会差这么一截。
	 */
	inline function contentPad():Float return Math.max(4, FlxG.height * 0.008);

	/** 内容可视区上缘（面板标题栏下沿 + padding） */
	function contentViewTop():Float
		return (panelW > MIN_W ? panelY : 0) + headH + contentPad();

	/** 内容可视区下缘（面板底 / 返回栏上沿取小者 − padding） */
	function contentViewBottom():Float
		return Math.min((panelW > MIN_W ? panelY : 0) + panelH, bottomBarTop()) - contentPad();

	///////////////////////////////////////////////////////////////////////////////
	// 构建
	///////////////////////////////////////////////////////////////////////////////

	override function create()
	{
		if (stateType != 2)
		{
			Paths.clearStoredMemory();
			Paths.clearUnusedMemory();
		}

		FlxG.mouse.visible = !ClientPrefs.data.needMobileControl;
		persistentUpdate = persistentDraw = true;
		instance = this;
		contentScrollPos = 0;

		mouseEvent = new MouseEvent();
		add(mouseEvent);

		// ★ 背景图和磨砂层用同一个"自愈"取图入口（见 frostSource 的注释）：
		//   直接 Paths.image() 有可能拿到一张已经释放掉的死图 —— 那就是
		//   "第二次进设置背景变成一块纯色、磨砂整层消失"的来源。
		var background = new ChangeSprite(0, 0).load(frostSource(), 1.05);
		background.antialiasing = ClientPrefs.data.antialiasing;
		add(background);

		// ★ 背景压暗层（原型 #bgTint）：必须在背景之后、磨砂玻璃层（buildFrost）之前。
		//   玻璃底只透 30~40%（原型 --glass-a/-b 的 alpha 是 .60/.70），那个透出率是
		//   按**压暗后的背景**调的；顺序颠倒的话玻璃会透出一整片过亮的背景。
		bgTint = buildBgTint();
		if (bgTint != null) add(bgTint);

		// 磨砂玻璃层必须铺在面板与两条栏的下面，所以先 add
		buildFrost();
		buildPanel();
		buildHint();

		// 收集分类：引擎自带的 9 个 + mod 在 stageScripts/options 下提供的
		// ★ 「语言」插到**最前面**（常规设置之上）：它现在是一块独立面板
		//   （左侧各国国旗 + 右侧该语言的示例文本，见 LanguageGroup / LanguagePanel），
		//   比原来侧栏底部那列小字直观得多。
		var groups:Array<String> = CATA_NAMES.copy();
		groups.insert(0, 'Language');
		naviArray = [new NaviData('NovaFlare Engine', groups)];
		collectModGroups(groups);

		// 两条侧边栏（竖向 / 横向），内容相同、排布不同
		// ★ 两条栏的 x/y 永远是 0：FlxSpriteGroup 的子元素存的是屏幕绝对坐标，
		//   用 group.y 隐藏会在下一次布局时被绝对值覆盖（顶部浮出菜单项）。
		//   隐藏统一走 setOff / hideNow。
		barV = new NaviGroup(false, FlxG.width * SB_W, FlxG.height, mainColor);
		add(barV);
		barH = new NaviGroup(true, FlxG.width, FlxG.height * BAR_H, mainColor);
		add(barH);

		barV.buildMembers(naviArray[0].group);
		barH.buildMembers(naviArray[0].group);
		// 必须在 buildMembers 之后才隐藏：布局函数写的是屏幕绝对坐标
		barH.hideNow();

		// 两条栏的语言条目在进入时必须是"展开态"（isOpened=true → alpha=1）。
		//   setListOpen(true, false) 会把分类项 + 语言条目一次性硬落到展开位置，
		//   省得还要单独记一套"语言条目的初始 alpha"。
		barH.setListOpen(true, false);
		barV.setListOpen(true, false);

		// 所有分类的内容都建出来，统一摆到面板内容区，只切可见性
		for (data in naviArray)
		{
			for (i in 0...data.group.length)
			{
				if (data.extraPath != '') addCata(data.group[i], barV, barV.parent[i], data.extraPath);
				else addCata(data.group[i], barV, barV.parent[i]);
			}
		}
		for (c in cataGroup)
		{
			c.visible = c.active = false;
			c.bg.alpha = 0.0000001;   // 面板底由 panelBG 统一画，分类自带的底只留命中判定
		}
		resetContentPosition();

		buildBottomBar();

		// 内容滚动（原实现里控件会读 cataMove.velocity / inputAllow）
		contentMaxScroll = 0;
		cataMove = new MouseMove(OptionsState, 'contentScrollPos',
			[0, 0],
			[
				[FlxG.width * P_LEFT_START, FlxG.width],
				[FlxG.height * HEAD_H, FlxG.height]
			],
			contentScrollEvent);
		add(cataMove);

		// 面板标题栏的命中区：控件用它判断「鼠标压在 UI 上」
		specBG = new Rect(0, 0, FlxG.width, headH, 0, 0, mainColor, 0.0000001);
		add(specBG);

		// 初始状态：只有两条栏 + 中间提示，面板不可见
		setPanelAlpha(0);
		setPanel(FlxG.width * SB_W, FlxG.height * 0.3, MIN_W, FlxG.height * 0.0675);

		updateStaticText();
		super.create();
	}

	function collectModGroups(groups:Array<String>)
	{
		var path = Paths.mods('stageScripts/options/');
		if (FileSystem.exists(path) && FileSystem.isDirectory(path))
		{
			var data = new NaviData('Global mod', []);
			var list:Array<String> = [];
			for (file in FileSystem.readDirectory(path))
				if (file.toLowerCase().endsWith('.hx')) list.push(StringTools.replace(file, '.hx', ''));
			data.group = list;
			data.extraPath = path;
			naviArray.push(data);
		}
		for (mod in Mods.parseList().enabled)
		{
			var p = Paths.mods(mod + '/stageScripts/options/');
			if (FileSystem.exists(p) && FileSystem.isDirectory(p))
			{
				var data = new NaviData(mod, []);
				var list:Array<String> = [];
				for (file in FileSystem.readDirectory(p))
					if (file.toLowerCase().endsWith('.hx')) list.push(StringTools.replace(file, '.hx', ''));
				data.group = list;
				data.extraPath = p;
				naviArray.push(data);
			}
		}
	}

	///////////////////////////////////////////////////////////////////////////////
	// 磨砂玻璃
	//
	// Flixel 没有 CSS 的 backdrop-filter，所以这里自己造一张「背景的模糊版」：
	//   原始背景图 → 降采样到短边 FROST_MIN_SIDE
	//   → 可分离方框模糊（半径 FROST_BLUR_RADIUS，串联 FROST_BLUR_PASSES 次）
	//   → 轻微提饱和 → 放大回全屏（双线性）→ 一张永久可用的模糊贴图。
	// 然后用 clipRect 把这张贴图分别裁成「面板」「竖向栏」「横向栏」三块，
	// 画在半透明玻璃底（panelBG / barBG）的下面，就得到磨砂效果。
	//
	// ★★ 分辨率是这里的第一原则 ★★
	//   放大倍率 = 屏幕宽 / 短边。倍率 8×（短边 160）时，模糊图的每个像素都会
	//   变成屏幕上 8×8 的方格，方框模糊只抹平格子内部、抹不掉格子的边 ——
	//   看上去就是一张低分辨率马赛克（"好大的 haze"）。倍率压到 ~3× 后才真正像玻璃。
	//
	// 这一步只在 create() 里做一次，之后每帧只是比较矩形有没有变化。
	///////////////////////////////////////////////////////////////////////////////

	///////////////////////////////////////////////////////////////////////////////
	// 背景压暗（原型 #bgTint）
	///////////////////////////////////////////////////////////////////////////////

	/**
	 * 生成背景压暗遮罩。
	 *
	 * 两层渐变**颜色相同**（rgba(11,10,17,·)），所以不必真叠两张贴图 ——
	 * 直接按 alpha 合成即可（下层是竖向、上层是径向）：
	 *     a = aRadial + aLinear * (1 - aRadial)
	 *
	 * 数值逐字搬原型 CSS：
	 *   · 径向 `radial-gradient(115% 85% at 16% 50%, .60 → .20@52% → .02)`
	 *     —— 中心在"左侧 16%、垂直中点"，所以左半边（侧栏那侧）压得最狠
	 *   · 竖向 `linear-gradient(180deg, .34 → .05@26% → .10@72% → .42)`
	 *     —— 顶和底各自压暗，中间几乎不压
	 *
	 * ★ 只按 1/DIV 分辨率逐像素算一次，再靠 scale 放大到全屏。这是大面积的
	 *   平滑渐变，放大后看不出颗粒，而循环次数从 92 万降到 5.6 万。
	 * ★ 新建的 BitmapData 一定 readable —— 不会踩到"贴图上传 GPU 后 CPU 像素
	 *   被释放、setPixels 只写进空气"那个坑（见 frostSource 的注释）。
	 * ★ 注意 BitmapData 的字节序是 **BGRA**（不是 ARGB），见 saturateSmall 的写法。
	 */
	function buildBgTint():FlxSprite
	{
		final DIV:Int = 4;
		final COL_R:Int = 11, COL_G:Int = 10, COL_B:Int = 17;   // rgba(11,10,17)
		var W:Float = FlxG.width;
		var H:Float = FlxG.height;
		var w:Int = Math.ceil(W / DIV);
		var h:Int = Math.ceil(H / DIV);

		var bmd:BitmapData = new BitmapData(w, h, true, 0x00000000);
		var bytes:ByteArray = new ByteArray();
		bytes.length = w * h * 4;

		for (py in 0...h)
		{
			var y:Float = py * DIV;
			var t:Float = y / H;

			// 竖向分段线性：0% → .34；26% → .05；72% → .10；100% → .42
			var aLin:Float =
				(t < 0.26) ? 0.34 + (0.05 - 0.34) * (t / 0.26) :
				(t < 0.72) ? 0.05 + (0.10 - 0.05) * ((t - 0.26) / 0.46) :
				             0.10 + (0.42 - 0.10) * ((t - 0.72) / 0.28);

			var dy:Float = (y - H * 0.50) / (H * 0.85);
			var dy2:Float = dy * dy;

			for (px in 0...w)
			{
				var x:Float = px * DIV;
				var dx:Float = (x - W * 0.16) / (W * 1.15);
				var d:Float = Math.sqrt(dx * dx + dy2);
				// radial-gradient 的最后一段颜色会一直延伸到无穷远，所以要夹到 1
				if (d > 1) d = 1;

				// 径向分段线性：0% → .60；52% → .20；100% → .02
				var aRad:Float =
					(d <= 0.52) ? 0.60 + (0.20 - 0.60) * (d / 0.52) :
					             0.20 + (0.02 - 0.20) * ((d - 0.52) / 0.48);

				var a:Float = aRad + aLin * (1 - aRad);
				if (a < 0) a = 0 else if (a > 1) a = 1;

				var o:Int = (py * w + px) * 4;
				bytes[o + 0] = COL_B;                 // BGRA
				bytes[o + 1] = COL_G;
				bytes[o + 2] = COL_R;
				bytes[o + 3] = Std.int(a * 255);
			}
		}
		bmd.setPixels(bmd.rect, bytes);

		var g:FlxGraphic = FlxGraphic.fromBitmapData(bmd, true, null, true);
		var spr:FlxSprite = new FlxSprite(0, 0, g);
		spr.scale.set(DIV, DIV);
		spr.updateHitbox();
		spr.scrollFactor.set(0, 0);
		return spr;
	}

	function buildFrost()
	{
		var tex:FlxGraphic = frostSource();
		if (tex == null || tex.bitmap == null) return;

		var small:BitmapData = downscale(tex.bitmap, FROST_MIN_SIDE);
		if (small == null) return;

		// ★ 关键：小图上再做几次可分离方框模糊。
		//   降采样只做「平均」，不做「模糊」：残留的高频在放大回去之后就是
		//   一片方块状的脏噪点（侧边栏那块看起来像"脏抹布"而不是玻璃）。
		//   半径必须够大（这里 σ ≈ 24px 全分辨率）才能把低频格子一起抹掉。
		blurSmall(small, FROST_BLUR_RADIUS, FROST_BLUR_PASSES);
		// ★★ 模糊之后必须补两步，否则玻璃上只剩一条几乎恒定的深色 ★★
		//   ① contrastSmall：模糊 = 加权平均，必然压反差。源图那段本来就平，
		//      不拉回来就真的是一块常数。
		//   ② hazeSmall：真实毛玻璃是"散射"，比背后的东西更亮更灰；只 blur
		//      不提亮，眼睛看到的是"半透明深色板"，不是"磨砂"。
		contrastSmall(small, FROST_CONTRAST);
		// 原型是 backdrop-filter:blur(..) saturate(160%)；但源图 menuDesat 本身
		// 已经是去饱和版本，这里只做轻提饱和（见 FROST_SATURATE 的注释）。
		saturateSmall(small, FROST_SATURATE);
		hazeSmall(small, FROST_HAZE);

		// 按背景图同样的「cover + 居中」铺法放大回全屏，保证和背景对得上位置
		var full = new BitmapData(FlxG.width, FlxG.height, true, 0xFF121118);
		var s:Float = Math.max(FlxG.width * 1.05 / small.width, FlxG.height * 1.05 / small.height);
		var dw:Float = small.width * s;
		var dh:Float = small.height * s;
		var m = new Matrix();
		m.scale(s, s);
		m.translate((FlxG.width - dw) * 0.5, (FlxG.height - dh) * 0.5);
		full.draw(small, m, null, null, null, true);
		small.dispose();

		frostGfx = FlxGraphic.fromBitmapData(full);
		frostGfx.persist = true;

		frostPanel = makeFrostSprite();
		frostBarV = makeFrostSprite();
		frostBarH = makeFrostSprite();
	}

	function makeFrostSprite():FlxSprite
	{
		var s = new FlxSprite(0, 0);
		s.loadGraphic(frostGfx);
		s.antialiasing = true;
		s.scrollFactor.set(0, 0);
		s.visible = false;
		add(s);
		return s;
	}

	/**
	 * 取一张「像素真的能读」的 menuDesat。
	 *
	 * ══════════════════════════════════════════════════════════════════════════
	 *  ★★ 第 8 轮的真凶：磨砂消失 = 源图变成了 hardware-only ★★
	 * ══════════════════════════════════════════════════════════════════════════
	 *  贴图上传给渲染器之后，引擎会把 **CPU 侧那份像素缓冲释放掉**，
	 *  于是这个 BitmapData 变成「只存在于显存里」：
	 *      openfl.display.BitmapData.readable == false
	 *  此时（openfl 9.5.2 源码 BitmapData.hx:2188 / 359 / 720）：
	 *      · getPixel32() 恒定返回 0（!readable 直接 return 0）
	 *      · getPixels()  返回 null
	 *      · **draw() 直接 return** —— 一行都不画
	 *  但**精灵照样能正常显示**，因为它走的是渲染器里的那张贴图。
	 *
	 *  磨砂管线恰好完全建立在「读 CPU 像素 + draw」之上，于是：
	 *      downscale → resizeBitmap 里 next.draw(src) 什么都没画（源不可读）
	 *      → 小图全透明 → blurSmall / saturateSmall 仍然全透明
	 *      → buildFrost 最后 full.draw(small) 还是什么都没画
	 *      → 磨砂贴图 = 兜底色 #121118 的**一整块平色**
	 *  表现：背景看得见（贴图正常），玻璃后面却是一块死板的深灰，
	 *  也就是用户说的「磨砂材质全没了，变成 100% 不透明背景」。
	 *
	 *  所以这里不能只判 null / isDestroyed，必须判 **readable**；
	 *  不可读就绕开缓存、直接从磁盘重新解码一张（新解码的一定可读）。
	 */
	function frostSource():FlxGraphic
	{
		var g:FlxGraphic = Paths.image('menuDesat');
		if (g != null && !g.isDestroyed && g.bitmap != null && g.bitmap.readable) return g;

		var fresh:FlxGraphic = decodeMenuDesatFromDisk();
		if (fresh != null) return fresh;

		// 兜底（针对"缓存里有死图"那条路）：摘掉同名缓存条目再取一次
		purgeCachedMenuDesat();
		var retry:FlxGraphic = Paths.image('menuDesat');
		if (retry != null && !retry.isDestroyed && retry.bitmap != null) return retry;
		return null;
	}

	/**
	 * 直接从磁盘把 menuDesat 解码成一张**全新的** FlxGraphic。
	 *
	 * `BitmapData.fromFile()` 走的是 `Image.fromFile()`，一定会带回 CPU 像素，
	 * 和引擎缓存里那份（可能已经 hardware-only 的）完全无关。
	 * 新图用 unique=true 建 FlxGraphic，避免又被塞回同一套缓存、被同一套逻辑拆掉 CPU 像素。
	 */
	function decodeMenuDesatFromDisk():FlxGraphic
	{
		var path:String = null;
		try
		{
			path = Paths.getPath('images/menuDesat.png');
		}
		catch (e:Dynamic) {}
		if (path == null) return null;

		var bmd:BitmapData = null;
		try
		{
			if (FileSystem.exists(path)) bmd = BitmapData.fromFile(path);
		}
		catch (e:Dynamic) {}
		if (bmd == null || !bmd.readable)
		{
			// 移动端 / 打包资源：走资源清单（useCache=false，强制重新解码）
			try
			{
				bmd = openfl.utils.Assets.getBitmapData(path, false);
			}
			catch (e:Dynamic) {}
		}
		if (bmd == null || bmd.width < 2 || !bmd.readable) return null;

		return FlxGraphic.fromBitmapData(bmd, true, null, true);
	}

	function purgeCachedMenuDesat():Void
	{
		var keys:Array<String> = [];
		#if MODS_ALLOWED
		var mk:String = Paths.modsImages('menuDesat');
		if (mk != null) keys.push(mk);
		#end
		@:privateAccess
		for (k in FlxG.bitmap._cache.keys())
			if (k != null && k.indexOf('menuDesat') >= 0) keys.push(k);
		for (k in keys)
		{
			if (k == null) continue;
			Cache.currentTrackedAssets.remove(k);
			@:privateAccess FlxG.bitmap._cache.remove(k);
		}
	}

	/**
	 * 降采样到短边 ≈ minSide：每一级都是严格的 1/2 双线性（等价 2×2 平均，
	 * 不会产生摩尔纹），最后再用一次双线性缩到目标尺寸。
	 */
	function downscale(src:BitmapData, minSide:Int):BitmapData
	{
		var cur:BitmapData = src;
		var w:Int = src.width;
		var h:Int = src.height;
		var guard:Int = 0;

		while (Std.int(w * 0.5) >= minSide && Std.int(h * 0.5) >= minSide && guard < 12)
		{
			cur = resizeBitmap(cur, Std.int(w * 0.5), Std.int(h * 0.5), cur != src);
			w = cur.width;
			h = cur.height;
			guard++;
		}

		if (w > minSide && h > minSide)
		{
			var k:Float = minSide / Math.min(w, h);
			cur = resizeBitmap(cur, Std.int(Math.max(1, Math.round(w * k))), Std.int(Math.max(1, Math.round(h * k))), cur != src);
		}
		return cur;
	}

	/** 用双线性重画一张图（smooth=true）；disposeSrc 表示旧图可以释放 */
	function resizeBitmap(src:BitmapData, w:Int, h:Int, disposeSrc:Bool):BitmapData
	{
		var next = new BitmapData(w, h, true, 0);
		var m = new Matrix();
		m.scale(w / src.width, h / src.height);
		next.draw(src, m, null, null, null, true);
		if (disposeSrc) src.dispose();
		return next;
	}

	/**
	 * 可分离方框模糊（横一遍 + 竖一遍 = 一次 pass），重复 passes 次。
	 * 全程只做读写 ByteArray + 一趟滑动窗口，160×90 这种尺寸的开销可以忽略。
	 * 边界用「钳制到最近像素」，所以四周不会发暗。
	 */
	function blurSmall(bmd:BitmapData, radius:Int, passes:Int):Void
	{
		var w:Int = bmd.width;
		var h:Int = bmd.height;
		if (radius < 1 || passes < 1 || w < 3 || h < 3) return;

		var rect = new Rectangle(0, 0, w, h);
		var bytes:ByteArray = bmd.getPixels(rect);
		var n:Int = w * h;

		var a:Array<Float> = [for (i in 0...(n * 3)) 0.0];
		var b:Array<Float> = [for (i in 0...(n * 3)) 0.0];
		// openfl 的 getPixels 是 BGRA 顺序
		for (i in 0...n)
		{
			a[i * 3 + 0] = bytes[i * 4 + 2];
			a[i * 3 + 1] = bytes[i * 4 + 1];
			a[i * 3 + 2] = bytes[i * 4 + 0];
		}

		for (p in 0...passes)
		{
			// 横向：同一行里相邻像素在数组里相隔 3
			var y:Int = 0;
			while (y < h)
			{
				var base:Int = y * w * 3;
				blurLine(a, b, w, 3, base, radius);
				blurLine(a, b, w, 3, base + 1, radius);
				blurLine(a, b, w, 3, base + 2, radius);
				y++;
			}
			var t0:Array<Float> = a; a = b; b = t0;

			// 纵向：同一列里相邻像素相隔 w*3
			var x:Int = 0;
			while (x < w)
			{
				var base:Int = x * 3;
				blurLine(a, b, h, w * 3, base, radius);
				blurLine(a, b, h, w * 3, base + 1, radius);
				blurLine(a, b, h, w * 3, base + 2, radius);
				x++;
			}
			var t1:Array<Float> = a; a = b; b = t1;
		}

		for (i in 0...n)
		{
			bytes[i * 4 + 2] = clampByte(a[i * 3 + 0]);
			bytes[i * 4 + 1] = clampByte(a[i * 3 + 1]);
			bytes[i * 4 + 0] = clampByte(a[i * 3 + 2]);
		}
		bmd.setPixels(rect, bytes);
	}

	/** 在 count 个元素上做一次滑动窗口平均（元素 k 的下标是 base + k*stride） */
	function blurLine(src:Array<Float>, dst:Array<Float>, count:Int, stride:Int, base:Int, radius:Int):Void
	{
		var win:Float = radius * 2 + 1;
		var sum:Float = 0;
		var j:Int = -radius;
		while (j <= radius)
		{
			var k:Int = clampInt(j, 0, count - 1);
			sum += src[base + k * stride];
			j++;
		}
		var k:Int = 0;
		while (k < count)
		{
			dst[base + k * stride] = sum / win;
			var outK:Int = clampInt(k - radius, 0, count - 1);
			var inK:Int = clampInt(k + radius + 1, 0, count - 1);
			sum += src[base + inK * stride] - src[base + outK * stride];
			k++;
		}
	}

	/** 提饱和：newC = gray + (C - gray) * sat（对应 CSS 的 saturate()） */
	function saturateSmall(bmd:BitmapData, sat:Float):Void
	{
		if (sat <= 1.001) return;
		var w:Int = bmd.width;
		var h:Int = bmd.height;
		var rect = new Rectangle(0, 0, w, h);
		var bytes:ByteArray = bmd.getPixels(rect);
		var n:Int = w * h;
		for (i in 0...n)
		{
			var o:Int = i * 4;
			var r:Float = bytes[o + 2];
			var g:Float = bytes[o + 1];
			var b:Float = bytes[o];
			var gray:Float = 0.299 * r + 0.587 * g + 0.114 * b;
			bytes[o + 2] = clampByte(gray + (r - gray) * sat);
			bytes[o + 1] = clampByte(gray + (g - gray) * sat);
			bytes[o + 0] = clampByte(gray + (b - gray) * sat);
		}
		bmd.setPixels(rect, bytes);
	}

	/**
	 * 提反差：按**各自通道的均值**做线性拉伸，c' = mean + (c - mean) * k。
	 *
	 * 为什么用"各通道均值"而不是"统一亮度均值"：
	 *   统一均值会把 R/G/B 一起往同一个方向拉，等于连带改变了色相与饱和度，
	 *   深蓝的天空被拉一下就可能偏紫。逐通道拉只改"起伏幅度"，颜色关系基本不动。
	 *
	 * ★ 这一步要放在 blurSmall **之后**：先拉反差再模糊，等于白拉（又被平均掉）。
	 */
	function contrastSmall(bmd:BitmapData, k:Float):Void
	{
		if (k <= 1.001) return;
		var w:Int = bmd.width;
		var h:Int = bmd.height;
		var rect = new Rectangle(0, 0, w, h);
		var bytes:ByteArray = bmd.getPixels(rect);
		var n:Int = w * h;
		if (n < 1) return;

		// 先求通道均值（openfl 的 getPixels 是 BGRA 顺序）
		var sr:Float = 0, sg:Float = 0, sb:Float = 0;
		for (i in 0...n)
		{
			var o:Int = i * 4;
			sb += bytes[o + 0];
			sg += bytes[o + 1];
			sr += bytes[o + 2];
		}
		var mr:Float = sr / n, mg:Float = sg / n, mb:Float = sb / n;

		for (i in 0...n)
		{
			var o:Int = i * 4;
			bytes[o + 2] = clampByte(mr + (bytes[o + 2] - mr) * k);
			bytes[o + 1] = clampByte(mg + (bytes[o + 1] - mg) * k);
			bytes[o + 0] = clampByte(mb + (bytes[o + 0] - mb) * k);
		}
		bmd.setPixels(rect, bytes);
	}

	/**
	 * 雾面提亮：c' = c + (255 - c) * haze，即"往白里混 haze 比例"。
	 *
	 * 这一步是"毛玻璃"与"半透明玻璃"的分界线（见 FROST_HAZE 的注释）。
	 * 放在最后 = 在已经定型的模糊+反差结果上统一罩一层雾，不会把反差又压回去。
	 */
	function hazeSmall(bmd:BitmapData, haze:Float):Void
	{
		if (haze <= 0.0001) return;
		var w:Int = bmd.width;
		var h:Int = bmd.height;
		var rect = new Rectangle(0, 0, w, h);
		var bytes:ByteArray = bmd.getPixels(rect);
		var n:Int = w * h;
		for (i in 0...n)
		{
			var o:Int = i * 4;
			bytes[o + 2] = clampByte(bytes[o + 2] + (255 - bytes[o + 2]) * haze);
			bytes[o + 1] = clampByte(bytes[o + 1] + (255 - bytes[o + 1]) * haze);
			bytes[o + 0] = clampByte(bytes[o + 0] + (255 - bytes[o + 0]) * haze);
		}
		bmd.setPixels(rect, bytes);
	}

	inline function clampByte(v:Float):Int return Std.int(Math.max(0, Math.min(255, v)));

	inline function clampInt(v:Int, lo:Int, hi:Int):Int return v < lo ? lo : (v > hi ? hi : v);

	/** 把某个矩形范围套到磨砂层上；矩形没变化就不重建 FlxRect（clipRect 每次赋值都会重算帧） */
	function setFrostRect(spr:FlxSprite, x:Float, y:Float, w:Float, h:Float):Void
	{
		if (spr == null) return;

		// 和 Slab 一样取整：磨砂层必须和面板底/栏底落在同一个整像素栅格上，
		// 否则磨砂会从边缘露出不到 1px 的模糊描边
		x = Math.floor(x);
		y = Math.floor(y);
		w = Math.floor(w);
		h = Math.floor(h);

		var on:Bool = (w > 1 && h > 1);
		var prev:FlxRect = frostCache.get(spr);

		if (!on)
		{
			spr.visible = false;
			if (prev != null) frostCache.remove(spr);
			return;
		}

		if (prev != null && Math.abs(prev.x - x) < 0.5 && Math.abs(prev.y - y) < 0.5
			&& Math.abs(prev.width - w) < 0.5 && Math.abs(prev.height - h) < 0.5)
		{
			spr.visible = true;
			return;
		}

		spr.visible = true;
		spr.clipRect = new FlxRect(x, y, w, h);
		frostCache.set(spr, new FlxRect(x, y, w, h));
	}

	function updateFrost()
	{
		if (frostPanel == null) return;

		// 面板：只在真正可见时铺
		if (panelBG.glassAlpha > 0.02 && panelW > MIN_W)
			setFrostRect(frostPanel, panelX, panelY, panelW, panelH);
		else
			setFrostRect(frostPanel, 0, 0, 0, 0);

		// 两条栏：哪个在屏幕内就铺哪条（切换动画期间两条可能各露一部分）
		applyBarFrost(frostBarV, barV);
		applyBarFrost(frostBarH, barH);
	}

	function applyBarFrost(spr:FlxSprite, bar:NaviGroup)
	{
		if (spr == null || bar == null) return;
		var x:Float = bar.offX;
		var y:Float = bar.offY;
		var w:Float = bar.getBarW();
		var h:Float = bar.getBarH();
		// 完全在屏幕外就不铺
		if (x + w < 0 || y + h < 0 || x > FlxG.width || y > FlxG.height) setFrostRect(spr, 0, 0, 0, 0);
		else setFrostRect(spr, x, y, w, h);
	}

	function buildPanel()
	{
		// 直角平板 + 顶边 1px 高光（web 原型 #panel 的 inset 0 1px 0 rgba(255,255,255,.07)）
		panelBG = new Slab(mainColor, GLASS_ALPHA, 0xFFFFFF, 0.07, true, false, false, false);
		add(panelBG);

		panelTitle = new FlxText(0, 0, 0, '', Std.int(headH * 0.42));
		panelTitle.setFormat(Paths.font(Language.get('fontName', 'main') + '.ttf'), Std.int(headH * 0.42), FlxColor.WHITE, LEFT);
		panelTitle.borderStyle = NONE;
		panelTitle.antialiasing = ClientPrefs.data.antialiasing;
		add(panelTitle);

		panelSub = new FlxText(0, 0, 0, '', Std.int(headH * 0.2));
		panelSub.setFormat(Paths.font(Language.get('fontName', 'main') + '.ttf'), Std.int(headH * 0.2), 0x9BA1B8, LEFT);
		panelSub.borderStyle = NONE;
		panelSub.antialiasing = ClientPrefs.data.antialiasing;
		add(panelSub);

		panelCount = new FlxText(0, 0, 0, '', Std.int(headH * 0.2));
		panelCount.setFormat(Paths.font(Language.get('fontName', 'main') + '.ttf'), Std.int(headH * 0.2), 0x9BA1B8, RIGHT);
		panelCount.borderStyle = NONE;
		panelCount.antialiasing = ClientPrefs.data.antialiasing;
		add(panelCount);

		headLine = new Rect(0, 0, 1, 1, 0, 0, 0x96B5FF, 0.18);
		add(headLine);
	}

	function buildHint()
	{
		hintMark = new FlxText(0, 0, 0, '<', Std.int(FlxG.height * 0.07));
		hintMark.setFormat(Paths.font(Language.get('fontName', 'main') + '.ttf'), Std.int(FlxG.height * 0.07), 0x96B5FF, CENTER);
		hintMark.borderStyle = NONE;
		hintMark.antialiasing = ClientPrefs.data.antialiasing;
		add(hintMark);

		hintText = new FlxText(0, 0, 0, '', Std.int(FlxG.height * 0.024));
		hintText.setFormat(Paths.font(Language.get('fontName', 'main') + '.ttf'), Std.int(FlxG.height * 0.024), 0xF0F2FA, CENTER);
		hintText.borderStyle = NONE;
		hintText.antialiasing = ClientPrefs.data.antialiasing;
		add(hintText);

		hintSub = new FlxText(0, 0, 0, '', Std.int(FlxG.height * 0.016));
		hintSub.setFormat(Paths.font(Language.get('fontName', 'main') + '.ttf'), Std.int(FlxG.height * 0.016), 0x9BA1B8, CENTER);
		hintSub.borderStyle = NONE;
		hintSub.antialiasing = ClientPrefs.data.antialiasing;
		add(hintSub);
	}

	function buildBottomBar()
	{
		var barH:Float = FlxG.height * BOTTOM_H;

		// ★ 这一块**故意不画**。
		//   原型里底部根本不存在独立底板：`#footV`（"返回"按钮区）只是 `#sideV`
		//   这个 flex 容器里的一个子项，和侧栏共用同一块 `.slab` 玻璃底；屏幕右侧
		//   的底部就是纯背景。而这里原本压的是一块 **全屏宽、alpha .75 的纯色矩形**，
		//   等于把"侧栏玻璃的下沿"和"右侧背景的下沿"一起盖住 ——
		//   画面最下面 10% 变成一条死板的深色横带，就是"最下面被遮挡了"。
		//   竖向栏的玻璃底本来就铺满全高（barBG.setRect(.., FlxG.height)），
		//   底部只需要"返回"按钮本身，不需要再加一层板。
		//   对象保留下来只为给 tipText 提供 y 基准与几何。
		downBG = new Rect(0, FlxG.height - barH, FlxG.width * SB_W, barH, 0, 0, mainColor, 0.75);
		downBG.visible = false;
		add(downBG);

		// 返回按钮固定在左下角
		backButton = new GeneralBack(FlxG.height * 0.012, FlxG.height - barH + FlxG.height * 0.012,
			FlxG.width * 0.17, barH - FlxG.height * 0.024, Language.get('back', 'main'), EngineSet.mainColor, backMenu);
		add(backButton);

		tipText = new FlxText(0, 0, 0, '', Std.int(barH * 0.3));
		tipText.setFormat(Paths.font(Language.get('fontName', 'main') + '.ttf'), Std.int(barH * 0.3), 0xD8DCEA, LEFT);
		tipText.borderStyle = NONE;
		tipText.antialiasing = ClientPrefs.data.antialiasing;
		tipText.x = FlxG.width * TIP_X;
		// ★ 这里**必须**给一个真实宽度。
		//   `fieldWidth = 0` 的 FlxText 宽度是"跟着文字长"的：长说明永远只有一行，
		//   一路铺出屏幕右缘被切断（用户报的「选项说明的文本还是一行」就是这个）。
		//   宽度取到面板右缘（同样的 P_RIGHT 留白），和上面板内容区右边对齐。
		tipText.fieldWidth = FlxG.width * (1 - P_RIGHT) - FlxG.width * TIP_X;
		add(tipText);
		layoutTip();

		resetButton = new ResetButton(FlxG.width - FlxG.width * 0.16 - headH * 0.12, 0, FlxG.width * 0.16, headH * 0.62);
		add(resetButton);
	}

	///////////////////////////////////////////////////////////////////////////////
	// 面板几何：面板用 x/y/宽/高 描述，四段动画各只改其中一条边
	///////////////////////////////////////////////////////////////////////////////

	function setPanel(x:Float, y:Float, w:Float, h:Float)
	{
		// ★ 在这里统一取整：面板底、磨砂层、内容区、标题栏都读 panelX/Y/W/H，
		//   取整一次就能保证它们落在同一个整像素栅格上 —— 半像素正是「边缘/边线
		//   发虚、两条边之间露细缝」的来源（web 用一个元素 + border 天然不会这样）。
		panelX = Math.floor(x);
		panelY = Math.floor(y);
		panelW = Math.floor(w);
		panelH = Math.floor(h);

		panelBG.setRect(panelX, panelY, panelW, panelH);

		// ★ 玻璃底必须在**这里**点亮 —— setPanel() 是唯一一处真正写面板几何的地方，
		//   所有展开路径最终都要过它。以前 setPanelAlpha(1) 只写在
		//   openVertical / openHorizontal 里，于是这两类路径会漏掉：
		//     · toVertical() / toHorizontal() 模式切换（create() 初始化模式时就会跑），
		//       面板被它们的补间直接撑开，玻璃底却一直停在 create() 里设的 0；
		//     · 于是 ① 面板区只剩背景和控件，看不出"玻璃"；
		//       ② updateFrost() 的 `glassAlpha > 0.02` 判定不过 → 磨砂层整层不铺。
		//   合起来正是用户报的「磨砂效果全没了，只剩下 100% 不透明的背景」。
		//   收起时 closePanel 结尾会再 setPanelAlpha(0)，所以这里只在上坡时点亮。
		if (panelW > MIN_W && panelBG.glassAlpha < 0.02) setPanelAlpha(1);

		layoutPanelChrome();
	}

	function tweenPanel(x:Float, y:Float, w:Float, h:Float, dur:Float, ease:Float->Float, ?done:Void->Void)
	{
		var x0 = panelX, y0 = panelY, w0 = panelW, h0 = panelH;
		FlxTween.num(0, 1, dur, {
			ease: ease,
			onComplete: function(_) { if (done != null) done(); }
		}, function(t) {
			setPanel(x0 + (x - x0) * t, y0 + (y - y0) * t, w0 + (w - w0) * t, h0 + (h - h0) * t);
		});
	}

	/** 标题栏与计数跟着面板走 */
	function layoutPanelChrome()
	{
		var pad:Float = headH * 0.3;
		if (panelTitle != null)
		{
			panelTitle.x = panelX + pad;
			panelSub.x = panelTitle.x;
			// ★ 副标题（英文名）必须收在标题栏里：从「标题栏底」往上反推位置，
			//   而不是从标题底往下推。后者（旧实现 panelSub.y = 标题底 + 6% 头高）
			//   会让副标题越过 headH 探进内容区，和第一行设置的
			//   「变量名称: xxx」叠在一起（用户报的二级菜单里那处文字重叠）。
			panelSub.y = panelY + headH * 0.90 - panelSub.height;
			panelTitle.y = panelSub.y - panelTitle.height - headH * 0.02;
			headLine.x = panelX + pad;
			headLine.y = panelY + headH;
			headLine.scale.x = Math.max(1, (panelW - pad * 2) / headLine.frameWidth);
			// ★ 缩放锚在贴图中心：headLine 的贴图只有 1×1，放大 1100 多倍后
			//   不更新 hitbox 的话整条线会左移约 (宽-1)/2 ≈ 557px —— 直接横穿侧边栏。
			headLine.updateHitbox();
			if (resetButton != null)
			{
				resetButton.x = panelX + panelW - resetButton.width - pad;
				resetButton.y = panelY + headH * 0.2;
			}
			// ★ 计数（「11 项」）的定位：必须让「右缘」贴着重置按钮的左边，
			//   而不是把「左缘」放到面板右缘附近。旧写法 panelCount.x = 面板右缘 - 2%宽
			//   会让这段文字从面板边界溢出去、并被重置按钮整个压住（用户截图里面的那两个
			//   数字）。原型 NewOptionState.htm 的 .phead 是 [图标][标题/副标题 flex:1]
			//   [.pcount 徽章][关闭按钮]，徽章永远排在按钮左边，所以这里按同一规则反推左缘。
			//   autoSize 的 FlxText（构造时 fieldWidth<=0）width 即文字实际宽度。
			panelCount.y = panelTitle.y + panelTitle.height * 0.35;
			var countRight:Float = panelX + panelW - pad;
			if (resetButton != null) countRight = resetButton.x - headH * 0.18;
			panelCount.x = countRight - panelCount.width;
			if (specBG != null)
			{
				specBG.x = panelX;
				specBG.y = panelY;
				specBG.scale.x = Math.max(1, panelW / specBG.frameWidth);
				specBG.scale.y = Math.max(1, headH / specBG.frameHeight);
				// 同上：不更新的话标题栏命中区整体左移，标题栏左半边点不到
				specBG.updateHitbox();
			}
		}
	}

	function resetContentPosition()
	{
		contentScrollPos = 0;
		layoutContent();
	}

	/** 分类内容区的宽度（= 建分类时用的宽度；模式切换不重建分类，所以这个值全程不变） */
	public inline function contentWidth():Float return FlxG.width * (1 - P_LEFT_OPEN - P_RIGHT);

	/**
	 * 自绘内容（语言面板）可用的宽 / 高 —— 就是「内容可视区」。
	 *
	 * ★ 面板几何是补间动画出来的，没有"布局完成"回调，所以自绘内容只能每帧
	 *   拿这两个值自己去对齐（LanguagePanel.update）。
	 */
	public function contentAreaW():Float return contentWidth();

	/** 内容可视区左缘 —— 自绘内容（语言面板）的定位基准 */
	public inline function contentAreaX():Float return contentBaseX;

	/** 内容可视区上缘 —— 同上 */
	public inline function contentAreaTop():Float return contentViewTop();

	public function contentAreaH():Float
	{
		if (currentCata == null) return 0;
		return Math.max(0, contentViewBottom() - contentViewTop());
	}

	/**
	 * 把内容区对齐到「当前面板几何」。
	 *
	 * ★ 横向模式的面板左右都摊开了（左缘 8%，不是竖栏的 20%），
	 *   内容必须跟着面板走 —— 以前内容死死钉在竖栏时代的 20% / headH 上，
	 *   于是横向时缩在面板左半边、还顶到标题栏上面去（图3、图4）。
	 *   内容宽度不随模式变（分类是同一次建好的，重建代价太大），所以在面板里居中。
	 *
	 * 面板还没几何（create 阶段）时退回竖向的默认值。
	 */
	function layoutContent()
	{
		var hasPanel:Bool = panelW > MIN_W;
		var baseX:Float = hasPanel ? panelX : FlxG.width * P_LEFT_OPEN;
		var availW:Float = hasPanel ? panelW : contentWidth();

		// ★ 起点统一用「内容可视区上缘」contentViewTop()。
		//   以前这里写的是 baseY + headH（正好贴着标题栏分割线），于是每一页的
		//   第一行都被 applyContentClip 裁掉 padding 那 6px（圆角顶被削平），
		//   看着仍像"往上顶出去了"。内容的静止位就该落在可视区上缘。
		var topY:Float = contentViewTop();

		// ★ 上移量用**当前分类自己**的第一个 TITLE 高度（见 OptionCata.titleH）。
		//   注意每个分类的值不同，所以下面循环里要各算各的 —— 不能只算一个 contentBaseY。
		var curTitleH:Float = (currentCata != null) ? currentCata.titleH : 0;
		contentBaseY = topY - curTitleH;
		var cx:Float = baseX + (availW - contentWidth()) * 0.5;
		contentBaseX = cx;

		for (c in cataGroup)
		{
			c.x = cx;
			c.y = topY - c.titleH + (c == currentCata ? contentScrollPos : 0);
		}
		refreshContentLayout();
	}

	///////////////////////////////////////////////////////////////////////////////
	// 内容：所有分类都摆在同一个位置，只切显隐
	///////////////////////////////////////////////////////////////////////////////

	/**
	 * 显示某个分类的内容。
	 *
	 * `reveal` 是**收尾淡入**的时长。它串行接在调用方的结构补间之后，所以：
	 *   - 普通换分类（没有结构补间，卡片补间 0.5s 与它并行）→ 默认 0.22 即可，不额外占时间；
	 *   - 展开 / 模式切换（前面已有 0.38s 结构补间）→ 调用方传 REVEAL(0.10)，
	 *     保证「结构 + 淡入」合计不超过 0.5s 的硬线。
	 */
	function showContent(cata:OptionCata, ?reveal:Float = 0.22)
	{
		for (c in cataGroup)
			if (c != cata)
			{
				c.visible = c.active = false;
				// 顺手把裁剪也摘掉：分类自己的 clipRect 会跟着它残留下去，
				// 下次以别的几何显示时（模式切换）就裁错地方了
				c.clipRect = null;
			}

		// ★★ 换了分类必须回到顶部 ★★
		//   contentScrollPos 是 **static** 的（cataMove 通过反射写它），之前切分类
		//   只换显隐、不重置它 —— 于是在一个长分类里滚到底、再点开另一个分类，
		//   新分类会直接以"滚到一半"的状态出现：第一项藏在标题栏后面、
		//   底部空出一大块，看着像内容错乱。（本轮抓图时就是这么发现的）
		//   注意只在**真的换了分类**时重置：模式切换会带着同一个 cata 再调一次
		//   showContent，那种情况必须保住用户的滚动位置。
		//
		// ★★ 必须用 MouseMove.resetTo(0)，不能只写 `tweenData = 0` ★★
		//   滚轮滚到底时 MouseMove 的 `target` 停在 -144 之类的位置，而且
		//   `velocity` 还有几千的余量要慢慢衰减；`applyInertia` 每帧改一次 `target`
		//   就会把那个旧值**反射写回 contentScrollPos**。于是这里刚置的 0
		//   下一帧就被顶回去 —— 新分类一进来就是"滚到底"的样子（本轮实测）。
		//   resetTo 会把 target/__target/velocity/补间一起清掉并当场落位。
		if (currentCata != cata)
		{
			contentScrollPos = 0;
			lastScrollApplied = Math.NaN;
			if (cataMove != null) cataMove.resetTo(0);
		}

		// 换了分类 = 裁剪区要重算（applyContentClip 的整数缓存失效）
		clipKeyY = Math.NaN;
		clipKeyH = Math.NaN;
		currentCata = cata;
		cata.visible = true;
		cata.active = true;
		// 内容区跟着面板走（面板几何在模式切换后会变，每次显示内容都重新对齐一次）
		layoutContent();
		// ★ 可滚范围要用「这个分类自己的高度」+「返回栏上缘」来算，所以必须在这里算
		//   （调用方手里没有 contentBaseY，在 showContent 之前算会拿到上一轮的面板几何）
		measureContent(cata);
		// 夹紧后的滚动量要重新落到 y 上：layoutContent 用的是夹紧前的值
		currentCata.y = contentBaseY + contentScrollPos;
		lastScrollApplied = contentScrollPos;
		refreshContentLayout();
		panelTitle.text = Language.get(cata.cataName, 'options');
		panelSub.text = cata.cataName;
		// 计数只数「可调的项」：旧版大标题不是设置项（它现在也被藏起来了）
		var itemCount:Int = 0;
		for (op in cata.optionArray) if (!HIDE_LEGACY_CATA_TITLE || op.type != TITLE) itemCount++;
		panelCount.text = Std.string(itemCount) + (ClientPrefs.data.language == 'Chinese' ? ' 项' : ' items');

		// ★ 同上：分类名是中文、计数带" 项"，都要按文本挑字体。
		//   必须在 layoutPanelChrome() 之前 —— 它按文字宽度把 count 右对齐。
		panelTitle.font = FontFallback.uiFont(panelTitle.text);
		panelSub.font = FontFallback.uiFont(panelSub.text);
		panelCount.font = FontFallback.uiFont(panelCount.text);

	layoutPanelChrome();
	// ★ 时长由调用方按「是不是结构动画的收尾」决定，见函数注释里的 0.5s 预算
	fadeContent(1, reveal);
}

	/** 内容区当前的淡入淡出系数（1 常态 / 0 完全隐去），由 fadeContent 的补间驱动 */
	var contentFade:Float = 1;
	var contentFadeTween:FlxTween = null;

	/**
	 * 内容整体淡入 / 淡出。
	 *
	 * ★★ 不要写 `FlxTween.tween(op, {alpha: a}, ...)` ★★
	 *   FlxSpriteGroup 的 alpha 是「把变化比例乘到每个子元素」上，而且对 alpha==0
	 *   的子元素会写 `1 / 比例`（flixel alphaTransform 里那句 "direct set to avoid
	 *   stuck sprites"）。一次 0.12s 的淡出 + 淡入就能把子元素的 alpha 放大到 1 以上：
	 *     · 设置项卡片底 baseBG（0.05）→ 1：整块卡片变实心
	 *     · 下拉列表底板 select.bg（0）→ 0.6+：收起状态的深色面板凭空显形
	 *   这就是用户看到的「切换时二级菜单里的选项卡变黑、下拉列表默认展开」。
	 *
	 *   现在改成：驱动一个 0→1 的标量，再让每个设置项按自己的**基准 alpha**缩放
	 *   （见 Option.setFade / OptionCata.setFade），永远不会越界。
	 */
	function fadeContent(a:Float, dur:Float)
	{
		if (currentCata == null) return;
		var cata:OptionCata = currentCata;

		if (contentFadeTween != null)
		{
			contentFadeTween.cancel();
			contentFadeTween = null;
		}

		if (dur <= 0)
		{
			contentFade = a;
			cata.setFade(a);
		}
		else
		{
			var from:Float = contentFade;
			contentFadeTween = FlxTween.num(from, a, dur, {
				ease: FlxEase.expoOut,
				onComplete: function(_) { contentFadeTween = null; }
			}, function(v) {
				contentFade = v;
				cata.setFade(v);
			});
		}

		// 标题栏 / 计数 / 重置按钮：普通精灵或自带安全淡出的对象，逐个处理
		FlxTween.tween(panelTitle, {alpha: a}, dur, {ease: FlxEase.expoOut});
		FlxTween.tween(panelSub, {alpha: a}, dur, {ease: FlxEase.expoOut});
		FlxTween.tween(panelCount, {alpha: a}, dur, {ease: FlxEase.expoOut});
		FlxTween.tween(headLine, {alpha: a * 0.18}, dur, {ease: FlxEase.expoOut});
		// ★ 重置按钮是 FlxSpriteGroup，同样不能整体补间 alpha（会把它那块底板
		//   从 0.045 放大成 1 → 一个纯白方块）。改成走它自己的安全淡出。
		if (resetButton != null) resetButton.setFade(a);
	}

	/**
	 * 内容区滚动。由 cataMove 的 drawUpdate 每帧回调（MouseMove.forceUpdateEvent），
	 * 但滚动量没变时什么都不用做 —— 原来每帧都跑一遍 refreshContentLayout()。
	 */
	var lastScrollApplied:Float = Math.NaN;

	function contentScrollEvent()
	{
		if (currentCata == null) return;
		if (lastScrollApplied == contentScrollPos) return;
		lastScrollApplied = contentScrollPos;
		var target:Float = contentBaseY + contentScrollPos;
		for (c in cataGroup) if (c == currentCata) c.y = target;
		refreshContentLayout();
	}

	/** 面板外的条目直接不渲染，剩下的整体裁到可视区（见 applyContentClip） */
	function refreshContentLayout()
	{
		if (currentCata == null) return;

		var top:Float = contentViewTop();
		// ★ 下界还要卡在底部「返回」栏上缘：返回栏是最后 add 的半透明板子，
		//   内容如果落进那 10%，会从栏底后面透出来（"选项卡铺到返回栏上了"）。
		var bot:Float = contentViewBottom();
		if (bot <= top) return;

		for (op in currentCata.optionArray)
		{
			// 旧版大标题：整项强制隐藏（分类名由面板标题栏负责显示）。
			// ★ 必须在这里显式置回 false —— FlxSpriteGroup.visible 会向下传播，
			//   切换分类时 cata.visible = true 会把它连带点亮。
			if (HIDE_LEGACY_CATA_TITLE && op.type == TITLE)
			{
				op.visible = false;
				continue;
			}
			var oy:Float = op.y;
			op.visible = (oy + op.saveHeight > top) && (op.y < bot);
		}

		applyContentClip(top, bot);
	}

	/** applyContentClip 的上一次结果（只在整数像素变化时才重新赋值，见下） */
	var clipKeyY:Float = Math.NaN;
	var clipKeyH:Float = Math.NaN;

	/**
	 * 把整块分类内容裁到 [top, bot]（屏幕坐标）。
	 *
	 * ★★ 为什么必须裁 ★★
	 *   内容是可滚动的，而面板标题栏（headH）和底部「返回」栏是画在内容**之上**的
	 *   chrome。不裁的话，滚动中正好压在边界上的那两项会直接画进这两块区域里 ——
	 *   就是用户报的「最上面和最下面的选项被上下遮挡了」。光靠上面的 `op.visible`
	 *   判断挡不住：它只能整项显隐，边界上那半截项照样会探出去。
	 *
	 * ★★ 为什么给分类顶层设一次就够了 ★★
	 *   `FlxSpriteGroup` 重写了 `set_clipRect`，会把矩形**换算成每个子级的局部坐标**
	 *   再逐个写下去（flixel/group/FlxSpriteGroup.hx 的 clipRectTransform），
	 *   子级本身又是 group 的话会继续往下传 —— 自动递归。
	 *   而叶子精灵的 `clipRect` 走的是 `FlxFrame.clipTo()`：与自身 frame 求交集，
	 *   **交集为空 → 生成一个 EMPTY frame，直接不画**。所以"完全在区外"的项
	 *   不需要额外处理。
	 *
	 * ⚠ 代价：`set_clipRect` 会 round + 递归传播 + 重算帧，滚动时每帧都调很贵。
	 *   所以这里缓存了上一次的整数结果，只在裁剪区**跨过像素边界**时才重新赋值。
	 */
	function applyContentClip(top:Float, bot:Float):Void
	{
		var cata:OptionCata = currentCata;
		if (cata == null || !cata.exists) return;

		var w:Float = contentWidth();
		var ly:Float = top - cata.y;
		var lh:Float = bot - top;
		if (w <= 0 || lh <= 0) return;

		if (cata.clipRect != null && !Math.isNaN(clipKeyY) && Math.floor(clipKeyY) == Math.floor(ly)
			&& Math.floor(clipKeyH) == Math.floor(lh)) return;

		clipKeyY = ly;
		clipKeyH = lh;

		if (cata.clipRect == null) cata.clipRect = new FlxRect(0, ly, w, lh);
		else
		{
			cata.clipRect.set(0, ly, w, lh);
			// ★ 就地改属性不会生效，必须重新赋值（flixel 在 clipRect 的文档里写明了）
			cata.clipRect = cata.clipRect;
		}
	}

	/**
	 * 自绘内容（语言面板）挪动过子元素之后调用：按当前视图重新裁一次。
	 *
	 * ★ 为什么需要它：`clipRect` 是**赋值那一刻**换算到每个子元素的局部坐标的
	 *   （clipRectTransform），之后子元素自己挪了，那份裁剪矩形就过期了 ——
	 *   表现为「切到横向后语言面板整块消失」。这里把缓存键作废旧再利用即可。
	 */
	public function reclipContent():Void
	{
		if (currentCata == null) return;
		clipKeyY = Math.NaN;
		clipKeyH = Math.NaN;
		applyContentClip(contentViewTop(), contentViewBottom());
	}

	/**
	 * 计算内容区可滚范围（contentMaxScroll，非正值）。
	 *
	 * ★ 以前这里是「取所有分类里最高的那个当总高」+「可视高 = 面板高 − 标题栏」，
	 *   两处都不对，合起来就是用户报的
	 *   「二级选项卡没有最高高度限制，能一直滚到全部选项卡都跑到上面去」：
	 *   ① **总高必须用当前分类的 heightSet**。用"最高的那个分类"当总高，
	 *      短分类就凭空多出一大截可滚空间 —— 滚到底时整块内容跑到面板上方。
	 *   ② **可视下界要停在底部「返回」栏的上缘**（bottomBarTop()）。返回栏是最后 add 的、
	 *      盖在面板之上，内容一旦滚进那 10% 就会从半透明栏底后面透出来，
	 *      看起来就是"选项卡铺到返回栏上了"。
	 *
	 * 因此直接按几何算：内容底 = contentBaseY + titleH + heightSet + scroll，
	 * 要求它不小于可视区下缘 → scroll ≥ contentViewBottom() − contentBaseY − titleH − heightSet。
	 *
	 * ★★ 这里的 `+ titleH` 是**必须**的，漏了它每页都差这么一截滚不到底 ★★
	 *   `contentBaseY` 已经为了抵掉藏起来的旧大标题而上移了 titleH；而 optionArray
	 *   里各项的 y 是**原始累计**（第一个非 TITLE 项的 y 恰好等于 titleH）。
	 *   两个效果不抵消：上移量作用在整块上，各项的相对 y 却没跟着减小 ——
	 *   所以真实的底 = contentBaseY + titleH + heightSet。
	 *   旧公式少加这一个 titleH，可滚范围就短了这么多：滚到底时最后一行仍然躲在
	 *   底部「返回」栏后面看不见，正是用户报的"最下面被遮挡"。
	 */
	function measureContent(?cata:OptionCata)
	{
		var c:OptionCata = (cata != null) ? cata : currentCata;
		var total:Float = (c != null) ? c.heightSet : 0;
		var cataT:Float = (c != null) ? c.titleH : 0;
		contentMaxScroll = Math.min(0, contentViewBottom() - (contentBaseY + cataT + total));
		if (cataMove != null)
		{
			cataMove.moveLimit = [contentMaxScroll, 0];
			// ★ 越界了要**当场落位**（resetTo），绝不能写 `tweenData`：
			//   写 tweenData 会把 allowLerp 打开，drawUpdate 会持续把 target 往那个值上拽，
			//   滚动中的惯性就被"回弹"掉了（和 update() 里滚轮那段是同一个坑）。
			var t:Float = FlxMath.bound(cataMove.target, contentMaxScroll, 0);
			if (t != cataMove.target) cataMove.resetTo(t);
		}
		contentScrollPos = FlxMath.bound(contentScrollPos, contentMaxScroll, 0);
	}

	///////////////////////////////////////////////////////////////////////////////
	// 三段展开 / 反向
	///////////////////////////////////////////////////////////////////////////////

	function stale(token:Int):Bool return token != seqToken;

	/** 竖向：① 右缘向右延伸 → ② 一分为二 → ③ 上下缘拉满 */
	function openVertical(cata:OptionCata, keepSb:Bool, token:Int)
	{
		var W:Float = FlxG.width;
		var H:Float = FlxG.height;
		var sbW:Float = keepSb ? W * SB_W_OPEN : W * SB_W;
		var right:Float = W * P_RIGHT;

		setPanel(sbW, originRowY, MIN_W, originRowH);
		setPanelAlpha(1);
		if (!keepSb) setSidebarWidth(W * SB_W, false);

		tweenPanel(sbW, originRowY, W - sbW - right, originRowH, A1, FlxEase.expoInOut, function() {
			if (stale(token)) return;
			tweenPanel(W * P_LEFT_OPEN, originRowY, W - W * P_LEFT_OPEN - right, originRowH, A2, FlxEase.expoOut, function() {
				if (stale(token)) return;
				tweenPanel(W * P_LEFT_OPEN, 0, W - W * P_LEFT_OPEN - right, H, A3, FlxEase.expoInOut, function() {
					if (stale(token)) return;
					inputLocked = false;
					showContent(cata, REVEAL);   // 结构三段(0.38s)之后收尾淡入 0.10s，合计 0.48s
				});
			});
			setSidebarWidth(W * SB_W_OPEN, true);
		});
	}

	/** 横向：① 下缘向下延伸 → ② 一分为二 → ③ 左右缘铺开（下缘贴屏幕底边） */
	function openHorizontal(cata:OptionCata, keepBar:Bool, token:Int)
	{
		var W:Float = FlxG.width;
		var H:Float = FlxG.height;
		var barNow:Float = keepBar ? H * (BAR_H + BAR_GAP) : H * BAR_H;
		var side:Float = W * BAR_SIDE;

		setPanel(side, barNow, W - side * 2, MIN_W);
		setPanelAlpha(1);
		if (!keepBar) setBarHeight(H * BAR_H, false);

		tweenPanel(side, barNow, W - side * 2, H - barNow, A1, FlxEase.expoInOut, function() {
			if (stale(token)) return;
			tweenPanel(side, H * (BAR_H + BAR_GAP * 2), W - side * 2, H - H * (BAR_H + BAR_GAP * 2), A2, FlxEase.expoOut, function() {
				if (stale(token)) return;
				tweenPanel(side, H * (BAR_H + BAR_GAP * 2), W - side * 2, H - H * (BAR_H + BAR_GAP * 2), A3, FlxEase.expoInOut, function() {
					if (stale(token)) return;
					inputLocked = false;
					showContent(cata, REVEAL);
				});
			});
			setBarHeight(H * (BAR_H + BAR_GAP), true);
		});
	}

	function setPanelAlpha(a:Float)
	{
		// ★ a 是「面板整体可见度」（0 = 收起，1 = 完全显示），
		//   玻璃底的不透明度是 GLASS_ALPHA，两者相乘。
		//   以前这里写的是 panelBG.alpha = a，而 openVertical/openHorizontal 传的是 1，
		//   于是磨砂面板被写成了**完全不透明**的色块，背景一点也透不过来（图3 的问题）。
		panelBG.glassAlpha = GLASS_ALPHA * a;
		panelTitle.alpha = a;
		panelSub.alpha = a;
		panelCount.alpha = a;
		headLine.alpha = a * 0.18;
		resetButton.alpha = a;
	}

	/** 反向：③ 收高 → ② 合回 → ① 缩回（共 0.25s） */
	function closePanel(keepOpenBar:Bool, token:Int, done:Void->Void)
	{
		// 关面板同样要先把展开中的下拉列表收掉：它会跟着分类一起被"隐藏-再点亮"，
		// 留在展开态的话，下次打开这个分类会直接看到一块深色列表底板
		closeAllStringSelects();
		if (currentCata != null) fadeContent(0, 0.12);
		var x0 = panelX, y0 = panelY, w0 = panelW, h0 = panelH;

		tweenPanel(x0, originRowY, w0, originRowH, R1, FlxEase.expoInOut, function() {
			if (stale(token)) { done(); return; }
			var backX:Float = keepOpenBar
				? (mode == 'v' ? FlxG.width * SB_W_OPEN : FlxG.width * BAR_SIDE)
				: (mode == 'v' ? FlxG.width * P_LEFT_START : FlxG.width * BAR_SIDE);
			var backW:Float = keepOpenBar && mode == 'v' ? 0 : 0;
			tweenPanel(backX, originRowY, panelW, originRowH, R2, FlxEase.expoOut, function() {
				if (stale(token)) { done(); return; }
				tweenPanel(backX, originRowY, MIN_W, originRowH, R3, FlxEase.expoInOut, function() {
					setPanelAlpha(0);
					if (currentCata != null)
					{
						currentCata.visible = currentCata.active = false;
						currentCata.clipRect = null;   // 裁剪别留着，下次以新几何打开会裁错地方
					}
					currentCata = null;
					clipKeyY = Math.NaN;
					clipKeyH = Math.NaN;
					if (!keepOpenBar && mode == 'v') setSidebarWidth(FlxG.width * SB_W, true);
					if (!keepOpenBar && mode == 'h') setBarHeight(FlxG.height * BAR_H, true);
					done();
				});
			});
		});
	}

	function setSidebarWidth(w:Float, animate:Bool)
	{
		if (animate) FlxTween.num(barV.baseWidth, w, R2, {ease: FlxEase.expoOut}, function(v) {
			barV.baseWidth = v;
			barV.setBarWidth(v);
		});
		else { barV.baseWidth = w; barV.setBarWidth(w); }
	}

	function setBarHeight(h:Float, animate:Bool)
	{
		if (animate) FlxTween.num(barH.baseHeight, h, A2, {ease: FlxEase.expoOut}, function(v) {
			barH.baseHeight = v;
			barH.setBarHeight(v);
		});
		else { barH.baseHeight = h; barH.setBarHeight(h); }
	}

	///////////////////////////////////////////////////////////////////////////////
	// 模式切换：竖向 ⇄ 横向
	// 整条链 = MA + MB + showContent 的收尾淡入 = 0.19 + 0.19 + 0.10 = 0.48s ≤ 0.5s
	///////////////////////////////////////////////////////////////////////////////

	public function toggleMode()
	{
		if (inputLocked) return;
		inputLocked = true;

		// ★ 切模式前先把所有展开的下拉列表**立刻**收起来。
		//   正常收起是"补间淡出 → onComplete 里才真正隐藏"，而模式切换会把面板
		//   整体重排、内容重算一次，那条补间跑不完 —— 下拉列表就留在展开态，
		//   变成一块深色底板 + 一列选项浮在新面板上（用户报的"切模式时下拉框不隐藏"）。
		closeAllStringSelects();

		if (mode == 'v') toHorizontal(); else toVertical();
	}

	/**
	 * 把所有下拉框**硬关**一次（切模式 / 换分类 / 内容重新显示前必须调）。
	 *
	 * ★★ 为什么不看 `stringRect.isOpend` ★★
	 *   `StringRect.change()` 收起时 `isOpend` 是**立刻**置 false 的，但
	 *   `select.visible` 要等那条 0.45s 淡出补间 **onComplete** 才变 false。
	 *   在这 0.45s 的窗口里，判据 `isOpend` 已经是 false → 这里会**漏掉
	 *   这个正在收起的下拉列表**；紧跟着模式切换的整体重排 / 补间取消
	 *   一打断，深色底板 + 一列选项就停在展开态浮在新面板上 ——
	 *   也就是用户报的「切竖/横侧边栏时 Tap to choose 与下拉列表没正确隐藏」。
	 *   → 改成无条件对每个下拉框调一次 `forceClose()`。它是幂等的
	 *     （内部只在"确实开着"时才还版面），130 个设置项循环一次开销可忽略。
	 */
	public function closeAllStringSelects():Void
	{
		for (c in cataGroup)
			for (op in c.optionArray)
				if (op.stringRect != null) op.stringRect.forceClose();
	}

	/**
	 * 鼠标是不是正停在「能滑动的描述文本」上（见 Option.descMaxScroll）。
	 * 内容区的滚轮要据此让开：那一下是滚描述，不是翻页。
	 */
	function descUnderMouse():Bool
	{
		if (currentCata == null) return false;
		for (op in currentCata.optionArray)
			if (op.descMaxScroll > 0 && op.baseDesc != null && op.visible && FlxG.mouse.overlaps(op.baseDesc)) return true;
		return false;
	}

	/**
	 * 竖向 → 横向：① 竖向栏滑出 + 面板横着摊开 → ② 横栏滑入 + 面板上缘下移、下缘贴底。
	 *
	 * ★ 切模式必须先把终点算清楚，再让补间从「当前几何」插值过去。
	 *   旧实现把「当前 panelW」写进了宽度公式里，而 setPanel() 每帧又在改 panelW ——
	 *   公式读到的是被自己改过的值，几帧之内就发散成负数：面板整块消失
	 *   （磨砂层因为 panelW < MIN_W 也不再铺），标题栏右侧的「数据重置」「N 项」
	 *   被推到屏幕外（就是图2 的样子）。toVertical 则漏了把宽度写回竖向的值，
	 *   切回来后面板比屏幕还宽、右侧元素全部出屏（图4）。
	 */
	function toHorizontal()
	{
		var wasOpen:Bool = currentCata != null;
		if (wasOpen) fadeContent(0, 0.12);

		var x0:Float = panelX;
		var y0:Float = panelY;
		var w0:Float = panelW;
		var h0:Float = panelH;

		// 终点（面板右缘在整段动画里保持不动：8% + 84% = 20% + 72% = 92%）
		// ★ 面板**没打开**时不能被模式切换撑开。以前这里无条件撑到全宽，只是玻璃底
		//   alpha 停在 0 而一直看不出来；把玻璃底点亮之后，它就变成一块盖住整个
		//   内容区的暗板（横向模式下面板区亮度从 104 掉到 33，且之后点不回竖向设置）。
		//   未打开时四边都保持当前收起几何。
		var tx:Float = wasOpen ? FlxG.width * BAR_SIDE : x0;
		var ty:Float = wasOpen ? FlxG.height * (BAR_H + BAR_GAP * 2) : y0;
		var tw:Float = wasOpen ? FlxG.width * (1 - BAR_SIDE * 2) : MIN_W;
		var th:Float = wasOpen ? (FlxG.height - ty) : h0;

		// 阶段A（190ms）：竖向栏向左滑出屏幕（用 setOff，不再动 group.x）
		var sx0:Float = barV.offX;
		var sx1:Float = -barV.getBarW() * 1.1;
		FlxTween.num(0, 1, MA, {ease: FlxEase.expoInOut}, function(t) { barV.setOff(sx0 + (sx1 - sx0) * t, 0); });

	FlxTween.num(0, 1, MA, {
		ease: FlxEase.expoInOut,
		onComplete: function(_) {
			mode = 'h';
			updateStaticText();
				// ★ 竖栏已经整体移出屏幕，顺手把一级列表**硬收起**（不走补间）。
				//   列表项用的是绝对坐标，只要还停在"展开"状态，任何一个之后的
				//   布局重算（layoutMembers 写绝对值）都可能把它们甩回屏幕里，
				//   而这时栏底磨砂早就移走了 —— 屏幕上会剩下一排行分类项飘在背景上。
				//   收起来（alpha=0 + 滑到栏外）就等于双保险；切回竖栏时
				//   toVertical 末尾会再无条件落一次"展开"。
				barV.setListOpen(false, false);
				// 横栏高度按「面板是否打开」复位：否则面板没打开时第一次点分类，
				// openHorizontal 会先把它压回 bar 再撑开，视觉上"收一下又恢复"
				setBarHeight(FlxG.height * (wasOpen ? BAR_H + BAR_GAP : BAR_H), false);

				// 阶段B（190ms）：横向栏从屏幕上方滑入；面板上缘下移、下缘贴屏幕底边
				var sy0:Float = -barH.getBarH() * 1.1;
				barH.setOff(0, sy0);
				FlxTween.num(0, 1, MB, {
					ease: FlxEase.expoOut,
					onComplete: function(_) {
						if (currentCata != null)
						{
							showContent(currentCata, REVEAL);
						}
						inputLocked = false;
					}
				}, function(t) {
					barH.setOff(0, sy0 * (1 - t));
					setPanel(tx, y0 + (ty - y0) * t, tw, h0 + (th - h0) * t);
				});
			}
		}, function(t) {
			setPanel(x0 + (tx - x0) * t, y0, w0 + (tw - w0) * t, h0);
		});
	}

	/** 横向 → 竖向：① 横栏收回上方 + 面板上下撑满 → ② 竖栏从左移回 + 面板左缘/宽度落回竖向值 */
	function toVertical()
	{
		var wasOpen:Bool = currentCata != null;
		if (wasOpen) fadeContent(0, 0.12);

		var x0:Float = panelX;
		var y0:Float = panelY;
		var w0:Float = panelW;
		var h0:Float = panelH;

		// ★ 同 toHorizontal()：面板没打开时保持收起几何，不要被模式切换撑开
		var tx:Float = wasOpen ? FlxG.width * P_LEFT_OPEN : x0;
		var ty:Float = wasOpen ? 0 : y0;
		var tw:Float = wasOpen ? FlxG.width * (1 - P_LEFT_OPEN - P_RIGHT) : MIN_W;
		var th:Float = wasOpen ? FlxG.height : h0;

		// 阶段A'（190ms）：横向栏收回屏幕上方
		var sy0:Float = barH.offY;
		var sy1:Float = -barH.getBarH() * 1.1;
		FlxTween.num(0, 1, MA, {ease: FlxEase.expoInOut}, function(t) { barH.setOff(0, sy0 + (sy1 - sy0) * t); });

	FlxTween.num(0, 1, MA, {
		ease: FlxEase.expoInOut,
		onComplete: function(_) {
			mode = 'v';
			updateStaticText();
				// 宽度同样按「面板是否打开」复位，否则会残留展开态的 18.5%
				setSidebarWidth(FlxG.width * (wasOpen ? SB_W_OPEN : SB_W), false);

				// 阶段B'（190ms）：竖向栏从左移回；面板左缘/宽度落到竖向目标
				var bx0:Float = barV.offX;
				FlxTween.num(0, 1, MB, {
					ease: FlxEase.expoOut,
					onComplete: function(_) {
						// ★ 竖栏滑回后把一级列表"复位成展开"（不走补间，直接落位）。
						//   列表项的坐标是绝对坐标（baseX），一旦在横栏期间被别的补间
						//   写过、或者整条栏平移过，这里无条件落一次就能保证
						//   「回来时侧边栏一定是完整可见的」，不会再出现空侧栏/漂在屏幕外。
						barV.setListOpen(true, false);
						if (currentCata != null) showContent(currentCata, REVEAL);
						inputLocked = false;
					}
				}, function(t) {
					barV.setOff(bx0 * (1 - t), 0);
					setPanel(x0 + (tx - x0) * t, ty, w0 + (tw - w0) * t, th);
				});
			}
		}, function(t) {
			setPanel(x0, y0 + (ty - y0) * t, w0, h0 + (th - h0) * t);
		});
	}

	///////////////////////////////////////////////////////////////////////////////
	// 交互
	///////////////////////////////////////////////////////////////////////////////

	public function onMemberClick(m:NaviMember)
	{
		if (inputLocked) return;
		// ★ 语言区块盖在上面的点击归语言区块所有。
		//   成员在 update 里先于 NaviGroup.update 跑（super.update 在最前），
		//   而语言列表会盖住它下面的分类项 —— 不让开就会"点语言却切了分类"。
		if (langBlockSwallow || barV.langSwallowsMouse() || barH.langSwallowsMouse()) return;
		if (mode == 'h' && !barH.isOpened) return;
		if (mode == 'v' && !barV.isOpened) return;

		var cata:OptionCata = null;
		var idx:Int = m.optionSort;
		if (idx >= 0 && idx < cataGroup.length) cata = cataGroup[idx];
		if (cata == null) return;
		if (cata == currentCata) return;

		originRowY = m.y;
		originRowH = m.mainHeight;
		seqToken++;
		var token:Int = seqToken;
		inputLocked = true;

		var hadOpen:Bool = currentCata != null;
		var keep:Bool = hadOpen;
		if (hadOpen)
		{
			closePanel(keep, token, function() {
				if (stale(token)) return;
				if (mode == 'v') openVertical(cata, keep, token);
				else openHorizontal(cata, keep, token);
			});
		}
		else
		{
			if (mode == 'v') openVertical(cata, false, token);
			else openHorizontal(cata, false, token);
		}
	}

	/**
	 * 可选语言列表：扫描 language 目录得到，与原 LanguageGroup 的规则一致
	 * （跳过 JustSay —— 那是给脚本用的，不是给玩家选的）。
	 * 这样 mod 往 language 里丢新语言目录也会自动出现在下拉里。
	 */
	/**
	 * 底部「返回」栏的上缘 y。
	 * 语言下拉往下展开时不能越过它 —— 底部栏是在两条 NaviGroup 之后 add 的，层级更高，
	 * 列表伸进去会被它盖住、点击也被它先吃掉（语言数 > 3 时的老 bug）。
	 */
	public function bottomBarTop():Float return FlxG.height * (1 - BOTTOM_H);

	public function getLanguageList():Array<String>
	{
		var out:Array<String> = [];
		var root:String = Paths.getPath('language');
		if (!FileSystem.exists(root) || !FileSystem.isDirectory(root)) return out;
		for (item in FileSystem.readDirectory(root))
		{
			if (item == 'JustSay') continue;
			// 测试用语言包默认藏起来（用户要求）：Ctrl+F10 才放出来，见 toggleTestLanguage()
			if (item == TEST_LANG_DIR && !showTestLang) continue;
			if (FileSystem.isDirectory(root + '/' + item)) out.push(item);
		}
		return out;
	}

	/**
	 * `Ctrl + F10`：唤出 / 收起「测试语言」。
	 *
	 * ── 为什么要有这个开关 ────────────────────────────────────────────
	 *   `language/I Dont Like Haxe` 是我自己用来压字体的测试包：
	 *   `fontName` 是个只有 8 个 cmap 区间的怪字体、选项名还塞了 emoji。
	 *   它出现在玩家的语言列表里既没用又容易误导（用户反馈"应该不显示"）。
	 *   但调试又少不了它，所以留成**隐藏开关**：默认不列，
	 *   Ctrl+F10 一按就出现在语言面板里（会话内有效，不写进存档）。
	 */
	public function toggleTestLanguage():Void
	{
		showTestLang = !showTestLang;
		var list:Array<String> = getLanguageList();
		for (c in cataGroup)
		{
			if (!Std.isOfType(c, LanguageGroup)) continue;
			var lg:LanguageGroup = cast c;
			if (lg.panel != null) lg.panel.setLangs(list);
		}
	}

	/** 当前是否放出了测试语言（Ctrl+F10 切换） */
	public static var showTestLang:Bool = false;

	/** 测试语言包的目录名（默认不显示） */
	public inline static var TEST_LANG_DIR:String = 'I Dont Like Haxe';

	///////////////////////////////////////////////////////////////////////////////
	// 语言条目的「母语名字」
	//
	// 目录名（Chinese / Portuguese (Brazil) / …）是给代码用的，不能直接当标签：
	// 那样玩家看到的是英文目录名。每个语言包自己的 `main/main.lang` 里就有一行
	//   languageName => 中文
	// 这正是各语言包给自己起的名字（英文包写 English、葡语包写 Portuguese (Brazil)），
	// 所以显示名统一读它 —— mod 往 language/ 丢一个新语言包，不用改引擎就能正确显示。
	//
	// ★ 字体的坑（本机实测字形表）：
	//   · chillax（英文包 / 葡语包用的字体）**没有中文字形**
	//   · Lang-ZH（中文包 / JustSay 用的字体）中英通吃（CJK + 拉丁 + ãêç）
	//   而这一列是「所有语言一起显示」的，切到英文后如果用当前语言字体（chillax），
	//   「中文」「不是人话」两条会变成豆腐块。所以含 CJK 的标签一律用 Lang-ZH。
	///////////////////////////////////////////////////////////////////////////////

	/** 全区通用的 CJK 兜底字体（见上面注释：拉丁字体没有中文字形） */
	inline static var CJK_FONT:String = 'Lang-ZH';

	/** 标签里是否含 CJK 字符（含中文标点、假名等） */
	public static function hasCJK(s:String):Bool
	{
		for (i in 0...s.length)
			if (s.charCodeAt(i) >= 0x2E80) return true;
		return false;
	}

	/** 目录名 → [显示名, 该语言包自己声明的字体名]（只读一次，之后走缓存） */
	var langMeta:Map<String, Array<String>> = null;

	function loadLangMeta(dir:String):Array<String>
	{
		if (langMeta == null) langMeta = new Map();
		var hit = langMeta.get(dir);
		if (hit != null) return hit;

		var name:String = dir;
		var font:String = '';
		var preview:String = '';
		var file:String = Paths.getPath('language') + '/' + dir + '/main/main.lang';

		var content:String = null;
		try
		{
			if (FileSystem.exists(file)) content = sys.io.File.getContent(file);
		}
		catch (e:Dynamic) {}
		if (content == null)
		{
			// 移动端 assets 不可直接读盘：走资源清单
			try
			{
				if (openfl.utils.Assets.exists(file)) content = openfl.utils.Assets.getText(file);
			}
			catch (e:Dynamic) {}
		}

		if (content != null)
		{
			for (line in content.split('\n'))
			{
				var s:String = StringTools.trim(line);
				var sep:Int = s.indexOf(' => ');
				if (sep < 0) continue;
				var key:String = s.substr(0, sep);
				var val:String = StringTools.trim(s.substr(sep + 4));
				if (val.length == 0) continue;
				if (key == 'languageName') name = val;
				else if (key == 'fontName') font = val;
				else if (key == 'langPreview') preview = val;
			}
		}

		var out:Array<String> = [name, font, preview];
		langMeta.set(dir, out);
		return out;
	}

	/**
	 * 某个语言在它的 `main.lang` 里写的那句「示例文本」（`langPreview => …`）。
	 * 语言面板右侧就用它 —— 让玩家在切之前先看到这个语言读起来什么样。
	 * 没写就返回空串，由 LanguagePanel 退回中文原文。
	 */
	public function getLanguagePreview(dir:String):String
	{
		return loadLangMeta(dir)[2];
	}

	/** 语言条目在侧边栏上显示的名字（母语写法，见上面注释） */
	public function getLanguageLabel(dir:String):String return loadLangMeta(dir)[0];

	/** 该语言条目该用哪个字体画（不含 '.ttf'，见上面字体的坑） */
	/**
	 * 该语言条目该用哪个字体画（不含 '.ttf'，见上面字体的坑）。
	 *
	 * ★ 判定方式从"手写码位范围"换成了**真的去问字体文件**：
	 *   解析该字体的 cmap 表，逐字符确认它到底认不认识这段文本
	 *   （见 FontFallback 的注释 —— OpenFL 没有 hasGlyphs 可用）。
	 *   所以判断依据是"**这段文本**"而不是"这个语言"，于是：
	 *     · `中文`            → chillax 不认识汉字 → 换成 Lang-ZH
	 *     · `Português`       → chillax 未必带 `ê`  → 换成 Lang-ZH
	 *     · `English`         → chillax 认识 → 就用 chillax（不白切）
	 *   条目怎么写都不会画成空白/豆腐块。
	 */
	public function getLanguageFont(dir:String):String
	{
		var meta:Array<String> = loadLangMeta(dir);
		var label:String = meta[0];
		var primary:String = (meta[1].length > 0) ? meta[1] : Language.get('fontName', 'main');
		// prefer 内部对"读不到的字体"一律判成能渲染，所以 Lang-ZH 被删也不会崩，
		// 最差就是退回 primary。
		return FontFallback.prefer(label, primary);
	}

	public function requestLanguage(langName:String)
	{
		if (ClientPrefs.data.language == langName) return;
		if (inputLocked) return;
		inputLocked = true;
		// 眨眼：面板内容先淡出，换完再淡入（HTML 原型的 #panelInner.blink）。
		//
		// ★ 不要对 barV / barH 整体做 alpha 补间：FlxSpriteGroup 的 alpha 是
		//   "按比例乘到每个子元素上"，淡出再淡入会把子元素各自的基准 alpha
		//   （例如语言按钮底的 0.07）冲成 1，颜色会永久变掉。
		//   而且 Flixel 里也没有 backdrop-blur 可以让底板"保持不动"。
		if (currentCata != null) fadeContent(0, 0.12);
		FlxTween.num(0, 1, 0.18, {ease: FlxEase.expoOut, onComplete: function(_) {
			ClientPrefs.data.language = langName;
			Language.resetData();
			changeLanguage();
			inputLocked = false;
		}}, function(_) {});
	}

	override function update(elapsed:Float)
	{
		// ★ 必须在 super.update() 之前算：NaviMember / NaviGroup 都在 super.update 里跑，
		//   它们要用这一帧的"语言区块是否吃掉鼠标"来决定让不让开 hover。
		if (barV != null && barH != null)
			langBlockSwallow = barV.langSwallowsMouse() || barH.langSwallowsMouse();

		// ★ 滚轮落在「能滑动的描述文本」上时，内容区整体让开（cataMove）：
		//   那一下是滚描述，不是翻页。见 Option.update 的 scrollDesc。
		//   底部「选项说明」同理（它也在底部栏里，见 tipUnderMouse）。
		// ★★ 滚轮**只有一个驱动**：MouseMove 的 velocity 惯性（MouseMove.update 的滚轮分支）。
		//   这里只决定"这一帧允不允许它吃滚轮"，不再自己动手改滚动量。
		//   以前这里自己还额外写过一次 `contentScrollPos += wheel*60` 并
		//   `cataMove.tweenData = contentScrollPos` —— 那是跟惯性抢同一个字段：
		//   写 `tweenData` 会顺带把 `allowLerp` 打开，于是 drawUpdate 里那句
		//   `target = FlxMath.lerp(tweenData, target, …)` 每帧把刚滚出去的位置**往回拽**，
		//   用户报的「没滚到顶也没到底、滚着滚着自己弹回去」就是这么来的。
		var onDesc:Bool = descUnderMouse();
		var onTip:Bool = tipUnderMouse();
		if (cataMove != null)
			cataMove.enableMouseWheel = !onDesc && !onTip && currentCata != null && !inputLocked
				&& FlxG.mouse.y > headH && FlxG.mouse.y < bottomBarTop() && FlxG.mouse.x > panelX;

		// 底部说明文本的「两行窗口」：换过文本的那一帧 textHeight 还没算出来，延后一帧量
		if (tipNeedFit && tipText != null)
		{
			if (tipFitDelay > 0) tipFitDelay--;
			else fitTipWindow();
		}
		// ★ 滚轮落在说明文本上 → 滚说明（最多两行，多出来的在这里滑）。
		//   放在 super.update() 之前，本帧就能把 scrollV 落下去。
		if (onTip && FlxG.mouse.wheel != 0) scrollTip(tipScrollV - Std.int(FlxG.mouse.wheel));

		// 隐藏测试语言「不是人话」：Ctrl+F10 唤出 / 再按收起（见 toggleTestLanguage）
		// ★ 用 FlxG.keys 而不是听文本事件 —— 它不受输入框焦点影响，`pressed` 也不会连发。
		if (!inputLocked && FlxG.keys.pressed.CONTROL && FlxG.keys.justPressed.F10) toggleTestLanguage();

		super.update(elapsed);

		cataMove.inputAllow = true;

		if (controls.BACK)
		{
			if (PsychUIInputText.focusOn != null)
			{
				if (!FlxG.keys.justPressed.BACKSPACE)
				{
					PsychUIInputText.focusOn = null;
					FlxG.sound.play(Paths.sound('cancelMenu'));
				}
			}
			else if (!inputLocked) backMenu();
		}

		// ★ 内容区的滚轮滚动**不在这里做**：唯一驱动是 cataMove（MouseMove 的惯性），
		//   本函数上面那段只负责开关它的 `enableMouseWheel`（标题栏 / 底部「返回」栏上不滚，
		//   描述 / 说明文本上让它们自己滚）。
		//   这里曾经再写一次 `contentScrollPos += wheel*60` + `tweenData = …` —— 两个驱动
		//   互抢同一个字段，而且 allowLerp 会把滚动量往回拽，就是"回弹"的来源，已删除。

		if (specBG != null) specBG.alpha = 0.0000001;
		updateHint();
		updateFrost();
		updateIndicator();
	}


	/**
	 * 中间的「从左侧/上方选择调整项」提示。
	 * HTML 原型里是 #hint.hide（opacity:0 + scale(.97)），
	 * 以前这边从头到尾没让它消失过，于是面板打开后提示文字还压在设置项上面
	 * （图4 里那句 "AN ITEM ON THE LEFT" 就是它）。
	 */
	var hintShown:Bool = true;
	function updateHint()
	{
		// 动画期间（inputLocked）不要提前把提示放出来，否则切分类时会闪一下
		var want:Bool = (currentCata == null) && !inputLocked;
		if (want == hintShown) return;
		hintShown = want;
		var a:Float = want ? 1 : 0;
		FlxTween.tween(hintMark, {alpha: a}, 0.16, {ease: FlxEase.expoOut});
		FlxTween.tween(hintText, {alpha: a}, 0.16, {ease: FlxEase.expoOut});
		FlxTween.tween(hintSub, {alpha: a}, 0.16, {ease: FlxEase.expoOut});
	}

	/**
	 * 当前悬停项对应的分类高亮。
	 *
	 * ★ 只在「当前分类真的换了」的时候写一遍：分类切换是低频事件，
	 *   原来每帧把两条栏所有成员都写一次纯属白烧 CPU —— 在 TPS 拉到
	 *   很高的设置下（常规设置里那根 framerate(TPS) 滑条最大 2000），
	 *   这种「每帧固定开销」会被放大成实打实的掉帧。
	 */
	var indicatorName:String = null;

	/**
	 * 当前分类 → 侧边栏高亮。
	 *
	 * ★ 用**分类名**匹配，别拿 cataGroup 的下标去比：
	 *   member.optionSort 是"导航数据里的序号"，而 cataGroup 的压入顺序还要经过
	 *   多级 navi / mod extraPath 的追加（见 create 里的 naviArray 循环），两者
	 *   不保证一一对应；一旦错位，高亮就会落在旁边那一项上
	 *   （用户截图里「打开音频设置、高亮却停在常规设置」就是这个）。
	 */
	function updateIndicator()
	{
		var cur:String = (currentCata == null) ? null : currentCata.cataName;
		if (cur == indicatorName) return;
		indicatorName = cur;
		for (m in barV.parent) m.cataChoose = (cur != null && m.memberName == cur);
		for (m in barH.parent) m.cataChoose = (cur != null && m.memberName == cur);
	}

	///////////////////////////////////////////////////////////////////////////////
	// 兼容接口（其它类会调用）
	///////////////////////////////////////////////////////////////////////////////

	public function addCata(type:String, follow:NaviGroup, mem:NaviMember, extraPath:String = '')
	{
		var obj:OptionCata = null;
		var cx:Float = FlxG.width * P_LEFT_OPEN;
		var cw:Float = FlxG.width * (1 - P_LEFT_OPEN - P_RIGHT);
		var cy:Float = headH;
		var chh:Float = 200;

		switch (type)
		{
			case 'General': obj = new GeneralGroup(cx, cy, cw, chh);
			case 'Language': obj = new LanguageGroup(cx, cy, cw, chh);
			case 'User Interface': obj = new InterfaceGroup(cx, cy, cw, chh);
			case 'GamePlay': obj = new GamePlayGroup(cx, cy, cw, chh);
			case 'Game UI': obj = new UIGroup(cx, cy, cw, chh);
			case 'Skin': obj = new SkinGroup(cx, cy, cw, chh);
			case 'Input': obj = new InputGroup(cx, cy, cw, chh);
			case 'Audio': obj = new AudioGroup(cx, cy, cw, chh);
			case 'Graphics': obj = new GraphicsGroup(cx, cy, cw, chh);
			case 'Maintenance': obj = new MaintenanceGroup(cx, cy, cw, chh);
			default: obj = new HScriptGroup(cx, cy, cw, chh, type, extraPath, type);
		}
		cataGroup.push(obj);
		obj.cataName = type;
		obj.follow = follow;
		obj.mem = mem;

		// 面板标题栏已经显示分类名 → 内容区里旧版的大标题（分类的第一项，TITLE 类型）
		// 的高度要从内容总高里去掉；内容区起点也要相应上移（见 layoutContent）。
		// ★ 上移量用**本分类第一个 TITLE 的高度**，不是"所有分类里最大的那个"
		//   （全局取最大会把其它分类上移过头，第一项直接钻进标题栏）。
		if (HIDE_LEGACY_CATA_TITLE)
		{
			for (op in obj.optionArray)
			{
				if (op.type != TITLE) continue;
				if (obj.titleH <= 0) obj.titleH = op.saveHeight;
				obj.heightSet -= op.saveHeight;
			}
		}

		add(obj);
	}

	public function addMove(tar:MouseMove) add(tar);
	public function cataMoveChange() {}
	public function startSearch(text:String, time = 0.5) {}
	public function changeCata(cataSort:Int, memSort:Int) {}
	public function changeNavi(navi:NaviGroup, isOpened:Bool, naviTime:Float = 0.45) {}
	/**
	 * 底部「选项说明」的内容。
	 *
	 * 由 `Option.update()` 在鼠标停留 0.2s 后调用，送过来的是 **`Option.tips`（真正的解释）**，
	 * 不是卡片里的 `Option.description`（那只是简称/选项名，见 Option.hx 的字段注释）。
	 *
	 * ★ 只在这里 set 文本，**不**立刻量高度：文本刚写下去时 `textField.textHeight` 还是 0，
	 *   这时候写 `fieldHeight` 会把文本永久裁没（regenGraphic 拿 textHeight 算新高度，
	 *   0 + GUTTER 就剩几个像素）。所以只挂标记，交给 update() 下一帧量 —— 与
	 *   `Option.fitDescWindow` 是同一个坑。
	 */
	public function changeTip(str:String):Void
	{
		if (tipText == null) return;
		var clean:String = (str == null) ? '' : str;
		if (tipText.text == clean) return;
		tipText.text = clean;
		if (clean != '') tipText.font = FontFallback.uiFont(clean); // 文本定下来之后再挑字体
		tipScrollV = 0;
		tipMaxScroll = 0;
		tipNeedFit = true;
		tipFitDelay = 1;
	}

	/** 说明文本在底部栏里垂直居中（行数变了高度就变，所以每次量完都要重算） */
	function layoutTip():Void
	{
		if (tipText == null) return;
		var top:Float = bottomBarTop();
		tipText.y = top + (FlxG.height - top) / 2 - tipText.height / 2;
	}

	/**
	 * 量一次说明文本：超过 TIP_LINES 行就把文本框收成 TIP_LINES 行高，多出来的用滚轮滑。
	 * 与 `Option.fitDescWindow` 同构（同一个 FlxText 坑）。
	 */
	function fitTipWindow():Void
	{
		if (tipText == null || tipText.textField == null) return;
		var tf = tipText.textField;

		if (tf.text == null || tf.text == '')
		{
			tipText.fieldHeight = 0;   // 空说明 → 回到自动高度，什么都不显示
			tipMaxScroll = 0;
			tipScrollV = 0;
			tipNeedFit = false;
			layoutTip();
			return;
		}
		if (tf.textHeight <= 1)
		{
			tipFitDelay = 1;           // 还没排版完，下一帧再量
			return;
		}

		var lineH:Float = Math.max(1, tipText.size * 1.25);
		try
		{
			var m = tf.getLineMetrics(0);
			if (m != null && m.height > 1) lineH = m.height;
		}
		catch (e:Dynamic) {}

		var fullH:Float = tf.textHeight;
		var est:Float = fullH / lineH;
		var lines:Int = (est > 1) ? Std.int(est + 0.5) : 1;

		if (lines > TIP_LINES)
		{
			tipText.fieldHeight = Math.min(lineH * TIP_LINES, fullH) + 2;
			tipMaxScroll = lines - TIP_LINES;
			if (tipScrollV > tipMaxScroll) tipScrollV = tipMaxScroll;
			if (tipScrollV < 0) tipScrollV = 0;
			tf.scrollV = tipScrollV + 1;
		}
		else
		{
			tipText.fieldHeight = 0;
			tipMaxScroll = 0;
			tipScrollV = 0;
		}
		tipNeedFit = false;
		layoutTip();
	}

	function scrollTip(v:Int):Void
	{
		if (tipMaxScroll <= 0 || tipText == null || tipText.textField == null) return;
		if (v < 0) v = 0;
		if (v > tipMaxScroll) v = tipMaxScroll;
		if (v == tipScrollV) return;
		tipScrollV = v;
		tipText.textField.scrollV = v + 1;
	}

	/** 鼠标是不是停在「能滑动的说明文本」上（内容区的滚轮要据此让开） */
	function tipUnderMouse():Bool
		return tipMaxScroll > 0 && tipText != null && FlxG.mouse.overlaps(tipText);

	public function resetData()
	{
		if (currentCata != null) currentCata.resetData();
	}

	public function moveState(type:Int)
	{
		switch (type)
		{
			case 1: MusicBeatState.switchState(new NoteOffsetState());
			case 2:
				persistentUpdate = false;
				openSubState(new NotesSubState());
			case 3:
				persistentUpdate = false;
				openSubState(new KeyBindsSubState());
			case 4:
				persistentUpdate = false;
				openSubState(new MobileControlSelectSubState());
			case 5:
				persistentUpdate = false;
				openSubState(new MobileExtraControl());
			#if mobile
			case 6: MusicBeatState.switchState(new CopyState(true));
			#end
			case 7:
				persistentUpdate = false;
				openSubState(new NotesSubStateLegacy());
			case 8:
				persistentUpdate = false;
				openSubState(new SelectGameSubState());
		}
	}

	public function changeLanguage()
	{
		barV.changeLanguage();
		barH.changeLanguage();
		barV.refreshLangVisual(false);
		barH.refreshLangVisual(false);
		// ★ 内容区的文案也要跟着换：Option.changeLanguage() 会重写每一条的
		//   「变量名称: xxx」+ 描述文字，并重建字号/字体（中英文字宽不同）。
		//   以前漏了这一步，所以点语言按钮后侧边栏和标题栏立刻变了，二级菜单里的
		//   设置项还是旧语言 —— 用户反馈的「切换语言没有立即生效」。
		for (c in cataGroup) c.changeLanguage();
		if (currentCata != null)
		{
			showContent(currentCata);
		}
		resetButton.changeLanguage();
		backButton.changeLanguage();
		updateStaticText();
	}

	function updateStaticText()
	{
		var isV:Bool = (mode == 'v');
		var isCN:Bool = (ClientPrefs.data.language == 'Chinese');
		hintMark.text = isV ? '<' : '^';
		hintText.text = isV
			? (isCN ? '从左侧选择调整项后这里才会显示设置' : 'Select an item on the left to show its settings here')
			: (isCN ? '从上方选择调整项后这里才会显示设置' : 'Select an item above to show its settings here');
		hintSub.text = isV ? 'SELECT AN ITEM ON THE LEFT' : 'SELECT AN ITEM ABOVE';

		// ★ 文本定下来之后**再**挑字体 —— 判断依据是"这段文本"本身（见 FontFallback）。
		//   中文提示语在 English 界面下会撞上纯拉丁的 chillax，不做回退就是一片空白。
		//   ★ 必须放在 layoutHint() 之前：它按 hintText.width 居中，换字体会改宽度。
		hintMark.font = FontFallback.uiFont(hintMark.text);
		hintText.font = FontFallback.uiFont(hintText.text);
		hintSub.font = FontFallback.uiFont(hintSub.text);

		layoutHint();
	}

	function layoutHint()
	{
		var isV:Bool = (mode == 'v');
		var cx:Float = isV ? (FlxG.width * SB_W + FlxG.width) / 2 : FlxG.width / 2;
		var cy:Float = isV ? FlxG.height / 2 : (FlxG.height * (BAR_H + BAR_GAP * 2) + FlxG.height) / 2;
		hintMark.x = cx - hintMark.width / 2;
		hintMark.y = cy - FlxG.height * 0.11;
		hintText.x = cx - hintText.width / 2;
		hintText.y = cy - hintText.height / 2;
		hintSub.x = cx - hintSub.width / 2;
		hintSub.y = hintText.y + hintText.height + FlxG.height * 0.012;
	}

	override function closeSubState()
	{
		super.closeSubState();
		persistentUpdate = true;
	}

	///////////////////////////////////////////////////////////////////////////////

	var backCheck:Bool = false;
	function backMenu()
	{
		if (!backCheck)
		{
			backCheck = true;
			FlxG.sound.play(Paths.sound('cancelMenu'));
			ClientPrefs.saveSettings();
			Main.fpsVar.visible = ClientPrefs.data.showFPS;
			Main.fpsVar.scaleX = Main.fpsVar.scaleY = ClientPrefs.data.fpsScale;
			if (Main.watermark != null)
			{
				Main.watermark.scaleX = Main.watermark.scaleY = ClientPrefs.data.watermarkScale;
				Main.watermark.y = Lib.current.stage.stageHeight - 5 - Main.watermark.scaleY * Main.watermark.bitmapData.height;
				Main.watermark.visible = ClientPrefs.data.showWatermark;
			}
			// ★ 先把目标取出来、立刻把 static 归零，再执行跳转。
			//   原来是先 switch 再 `stateType = 0`：一旦 switch 过程中抛异常/提前返回，
			//   或者在 case 里插入了别的跳转，残留值就会带到下一次打开设置，
			//   导致「从主菜单进设置、退出却进了游戏」这类偶发问题。
			var backTo:Int = stateType;
			stateType = 0;
			switch (backTo)
			{
				case 0: MusicBeatState.switchState(new MainMenuState());
				case 1: MusicBeatState.switchState(new FreeplayState());
				case 2:
					MusicBeatState.switchState(new PlayState());
					FlxG.mouse.visible = false;
			}
		}
	}
}
