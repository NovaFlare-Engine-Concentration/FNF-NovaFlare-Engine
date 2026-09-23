package options.objects.navi;

import flixel.math.FlxRect;

// 一条完整的侧边栏（垂直或横向）。
//
// ══════════════════════════════════════════════════════════════════════════
//  坐标约定（踩过的坑，改动前务必先读这段）
// ══════════════════════════════════════════════════════════════════════════
//  FlxSpriteGroup 的子元素保存的是**屏幕绝对坐标**：
//    · add() 时做一次  sprite.x += group.x   （FlxSpriteGroup.preAdd）
//    · 之后改 group.x / group.y 会把所有子元素整体平移（set_x → transformChildren）
//  一旦"用 group.y 把整条栏移出屏幕"和"给子元素写绝对坐标"两种做法混用，就会出：
//    · 底板被移出屏幕、菜单项却还浮在屏幕上（从屏幕外漏出来）
//    · 每切换一次横/竖模式，整条栏的内容漂移一个栏高的距离
//
//  所以本类把 group 自身的 x / y 永远固定在 (0,0)，
//  改用 offX / offY 表示"整条栏在屏幕上的偏移"，靠 setOff() 统一驱动，
//  子元素位置一律是屏幕绝对坐标。隐藏整条栏 = 把 off 设到屏幕外。
//
// ══════════════════════════════════════════════════════════════════════════
//  尺寸约定（第二个坑）
// ══════════════════════════════════════════════════════════════════════════
//  ★ 垂直栏的布局比例一律以**视口高度**为基准（对照 HTML 原型的 vh）。
//    以前竖向分支把整个「品牌行高 9vh」当成了 1 个单位，
//    于是 baseHeight*0.74 想要的是"6.6vh"，实际算出来却是 0.74 × 1080 = 799px，
//    菜单项被推到 y≈1145 的屏幕外，语言下拉更是跑到了 y≈8240。
//  ★ 横向栏的比例以**栏高**（baseHeight）为基准，这部分原来是对的，保持不动。
class NaviGroup extends FlxSpriteGroup
{
	inline static var HIDDEN_ALPHA:Float = 0.0000001;
	/**
	 * 一级列表展开/收起：整列向左侧滑 + 逐项错开。
	 *
	 * ★ 总时长 = LIST_DUR + LIST_STAGGER × 最后一个间隔的序号，必须 ≤ 0.5s
	 *   （OptionsState.hx 里那条"动画组总时长不超过半秒"的硬规则）。
	 *   最长的情况是 10 个分类项 + 4 个语言行 = 13 个间隔：
	 *   0.30 + 13 × 0.015 = 0.495s ✓
	 */
	inline static var LIST_DUR:Float = 0.30;
	inline static var LIST_STAGGER:Float = 0.015;
	/** 相邻语言条目的间距（占视口高的比例） */
	inline static var LANG_GAP_V:Float = 0.004;
	/** 语言条目的最小可读高度（px）；语言特别多时宁可挤一点也不能溢出到「返回」栏下面 */
	inline static var LANG_MIN_ROW:Float = 18;

	// ── 垂直栏：以视口高 H 为基准（括号里是 HTML 原型里的值）──────────
	inline static var V_PAD_TOP:Float = 0.015;     // 1.5vh  顶部内边距
	inline static var V_BRAND_H:Float = 0.09;      // 9vh    品牌行高 .nav-group
	inline static var V_BRAND_GAP:Float = 0.009;   // 0.9vh  品牌行下边距
	inline static var V_MEMBER_H:Float = 0.066;    // 6.6vh  分类项高 .nav-item
	inline static var V_LANG_GAP:Float = 0.015;    // 1.5vh  语言按钮上边距
	inline static var V_ICON:Float = 0.044;        // 4.4vh  .gicon / .mode-btn
	inline static var V_NAME:Float = 0.018;        // ≈1.7vh 品牌名字号
	inline static var V_TAG:Float = 0.0124;        // ≈1.14vh 副标题
	inline static var V_CHEV:Float = 0.021;        // 2.1vh  折叠箭头 .chev
	inline static var V_SIDE_PAD:Float = 0.055;    // 侧边距（占栏宽）

	// ── 横向栏：以栏高 baseHeight 为基准 ────────────────────────────
	inline static var H_PAD:Float = 0.14;
	inline static var H_ICON:Float = 0.5;          // 3.5vh / 7vh
	inline static var H_NAME:Float = 0.24;         // 1.5vh / 7vh
	inline static var H_MEMBER_H:Float = 0.7;      // 4.9vh / 7vh

	///////////////////////////////////////////////////////////////////////////////

	public var horizontal:Bool;
	public var isOpened:Bool = true;

	/**
	 * 侧边栏底部那列「语言名」还要不要建。
	 *
	 * ★ 现在是 false：语言已经改成侧边栏**最上面**的独立面板
	 *   （LanguageGroup / LanguagePanel：左侧各国国旗 + 母语名，右侧该语言的示例文本），
	 *   比一列小字直观得多。
	 *
	 *   原来那套代码（buildLangList / layoutLangItems / updateLangRows /
	 *   langSwallowsMouse …）全部保留：它们都以 langRowBg 为空数组为前提安全空转，
	 *   万一要退回"一列文字"只需把这个开关改回 true。
	 */
	inline static var USE_INLINE_LANG_LIST:Bool = false;

	/** 分类项顺序与 OptionsState.addCata 的顺序一致 */
	public var parent:Array<NaviMember> = [];

	/** 整条栏在屏幕上的偏移。隐藏 = 把它设到屏幕外（见 setOff） */
	public var offX:Float = 0;
	public var offY:Float = 0;

	/** 栏的磨砂底：整块直角平板（见 Slab —— 用 RoundRect 的 9-slice 会有拼接缝） */
	var barBG:Slab;
	var brandIcon:FlxSprite;
	var brandName:FlxText;
	var brandTag:FlxText;
	var chevron:FlxText;          // 折叠箭头
	var brandHit:Rect;            // 品牌行命中区（点击 = 折叠/展开）

	var modeBg:Rect;              // 模式切换按钮底
	var modeBar:Rect;             // 模式图标：条
	var modeBlock:Rect;           // 模式图标：块
	var modeHit:Rect;
	var modeSize:Float = 0;

	// ── 语言列表（常态显示：每个可选语言一个条目，视觉与分类项一致）──
	//
	// ★ 以前这里是一个「白底灰字 + 下拉箭头」的按钮，点开才浮出一张列表。三个问题：
	//   ① 不点开就看不见有哪些语言可选；
	//   ② 白底灰字和侧边栏里深色条目完全是两个风格；
	//   ③ 浮层会盖住分类项 → "点语言却切了分类"/"下面的分类项还亮着"一串连锁问题。
	//   现在改成「常态可见的一列语言条目」：没有展开/收起、没有浮层，
	//   条目本身就是分类项那套视觉（悬停高亮 + 选中强调条 + 白色文字）。
	var langList:Array<String> = [];       // 可选语言（只扫一次目录，见 buildLangList）
	var langRowBg:Array<Rect> = [];        // 条目底：悬停高亮，同时充当命中区
	var langRowSpec:Array<Rect> = [];      // 选中强调条（竖栏贴左侧、横栏贴底边）
	var langRowText:Array<FlxText> = [];   // 语言名（字面量，不走 Language.get）
	var langRowBaseX:Array<Float> = [];    // 展开态的基准 x（折叠动画从这里滑出去）
	var langRowH:Float = 0;                // 条目高：建的时候就要定死（Rect 的贴图尺寸不可变）
	var langRowW:Float = 0;               // 条目宽：竖向 = 栏宽 96%；横向按最长语言名量，整组统一
	var langFocus:Int = -1;                // 本帧悬停到的条目下标
	var langBuilt:Bool = false;

	/**
	 * 一级列表「折叠/展开」派生出来的所有补间。
	 *
	 * ★ 必须能取消 —— 每个成员都带 startDelay（逐项错开 30ms），快速连点时
	 *   早先那批「收起」补间会在新的「展开」补间**之后**才落地：
	 *   每个补间每帧都往同一个字段写值，最后写的那次就是最终位置，
	 *   于是会出现「状态已经展开、却有前几项还藏在栏外」/ 反过来「已收起却留了几项」。
	 *   所以每次改变展开状态前，先把上一批全部 cancel 掉。
	 */
	var listTweens:Array<FlxTween> = [];

	function killListTweens():Void
	{
		for (t in listTweens)
			if (t != null && t.active) t.cancel();
		listTweens = [];
	}

	inline function keepTween(t:FlxTween):FlxTween
	{
		if (t != null) listTweens.push(t);
		return t;
	}

	/** 栏的基准尺寸（后续动画都以它为基准算） */
	public var baseWidth:Float;
	public var baseHeight:Float;

	/** 横向栏里分类项这一行的实际右缘（布局诊断用；装不下时可能略超内边距） */
	public var hStripRight:Float = 0;

	/** 栏在当前时刻的实际像素尺寸 */
	public function getBarW():Float return horizontal ? FlxG.width : baseWidth;
	public function getBarH():Float return horizontal ? baseHeight : FlxG.height;

	///////////////////////////////////////////////////////////////////////////////

	public function new(horizontal:Bool, width:Float, height:Float, color:FlxColor)
	{
		super(0, 0);
		this.horizontal = horizontal;
		this.baseWidth = width;
		this.baseHeight = height;

		// 磨砂底：Flixel 没有 backdrop-blur，这里用半透明色块近似；
		// 真正的模糊层由 OptionsState 生成的 frost 贴图铺在它下面。
		// 边线照 web 原型：#sideV 的 border-right、#sideH 的 border-bottom
		//
		// ★ alpha 对齐原型 .slab 的 linear-gradient(180deg,
		//   rgba(41,40,52,.60), rgba(24,23,31,.70))：Slab 内部的竖向渐变是
		//   「基准 α × 0.86 → 基准 α」，所以基准取 0.70 才能得到 .60→.70。
		//   以前写 0.62（= .53→.62），比原型透，模糊层透出来太多就成了"一片雾"。
		barBG = new Slab(color, 0.70, 0xFFFFFF, horizontal ? 0.07 : 0.06,
			false, horizontal, false, !horizontal);
		add(barBG);
		barBG.setRect(0, 0, width, height);

		buildBrand();
		buildModeButton();
		// ★ 语言条目不在这里建：它的行高要看「分类项有几条」才能算出来（见 buildLangList），
		//   而分类项是 OptionsState 拿到分类列表之后才调 buildMembers() 建的。
	}

	///////////////////////////////////////////////////////////////////////////////

	function buildBrand()
	{
		var iconSize:Float = horizontal ? baseHeight * H_ICON : FlxG.height * V_ICON;

		brandIcon = new FlxSprite().loadGraphic(Paths.image('menuExtend/OptionsState/icons/NovaFlare Engine'));
		brandIcon.setGraphicSize(Std.int(iconSize));
		brandIcon.updateHitbox();
		brandIcon.antialiasing = ClientPrefs.data.antialiasing;
		brandIcon.color = EngineSet.mainColor;
		add(brandIcon);

		var nameSize:Int = Std.int(horizontal ? baseHeight * H_NAME : FlxG.height * V_NAME);

		brandName = new FlxText(0, 0, 0, 'NovaFlare Engine', nameSize);
		brandName.setFormat(Paths.font(Language.get('fontName', 'main') + '.ttf'), nameSize, FlxColor.WHITE, LEFT);
		brandName.borderStyle = NONE;
		brandName.antialiasing = ClientPrefs.data.antialiasing;
		add(brandName);

		if (horizontal)
		{
			brandTag = new FlxText(0, 0, 0, '', 1);  // 横向栏高度有限，不显示副标题
			brandTag.visible = false;
		}
		else
		{
			brandTag = new FlxText(0, 0, 0, 'v1.2.2', Std.int(FlxG.height * V_TAG));
			brandTag.setFormat(Paths.font(Language.get('fontName', 'main') + '.ttf'), Std.int(FlxG.height * V_TAG), 0x9BA1B8, LEFT);
			brandTag.borderStyle = NONE;
			brandTag.antialiasing = ClientPrefs.data.antialiasing;
		}
		add(brandTag);

		// 折叠箭头：用文字字符，避免额外素材
		var chevSize:Int = Std.int(horizontal ? baseHeight * 0.2 : FlxG.height * V_CHEV);
		chevron = new FlxText(0, 0, 0, 'v', chevSize);
		chevron.setFormat(Paths.font(Language.get('fontName', 'main') + '.ttf'), chevSize, 0x9BA1B8, LEFT);
		chevron.borderStyle = NONE;
		chevron.antialiasing = ClientPrefs.data.antialiasing;
		add(chevron);

		// 品牌行命中区（点击折叠/展开列表）
		brandHit = new Rect(0, 0, 40, 40, 0, 0, 0xFFFFFF, HIDDEN_ALPHA);
		add(brandHit);

		layoutBrand();
	}

	/** 品牌行各元素的位置：垂直时整行占满栏宽，横向时按内容紧凑排布 */
	function layoutBrand()
	{
		if (horizontal)
		{
			var pad:Float = baseHeight * H_PAD;
			brandIcon.x = offX + pad;
			brandIcon.y = offY + (baseHeight - brandIcon.height) / 2;
			brandName.x = brandIcon.x + brandIcon.width + baseHeight * 0.14;
			brandName.y = offY + (baseHeight - brandName.height) / 2;
			brandHit.x = offX + pad * 0.5;
			brandHit.y = offY + baseHeight * 0.05;
			brandHit.scale.set(Math.max(1, (brandName.x - offX + brandName.width + baseHeight * 0.2) / brandHit.frameWidth),
				Math.max(1, baseHeight * 0.9 / brandHit.frameHeight));
			// ★ 缩放是以 origin（贴图中心）为锚点的：不更新 hitbox 的话命中区会
			//   往左上偏移半个放大后的身位（1×1/小贴图放得越大偏得越狠），
			//   点品牌行折叠列表就会点不到。
			brandHit.updateHitbox();
		}
		else
		{
			var H:Float = FlxG.height;
			var top:Float = H * V_PAD_TOP;
			var rowH:Float = H * V_BRAND_H;
			var side:Float = baseWidth * V_SIDE_PAD;

			brandIcon.x = offX + side;
			brandIcon.y = offY + top + (rowH - brandIcon.height) / 2;

			// 名称 + 副标题两行在品牌行里整体垂直居中
			var blockH:Float = brandName.height + brandTag.height + H * 0.002;
			var blockY:Float = offY + top + (rowH - blockH) / 2;

			brandName.x = brandIcon.x + brandIcon.width + H * 0.009;
			brandName.y = blockY;

			brandTag.x = brandName.x;
			brandTag.y = blockY + brandName.height + H * 0.002;

			brandHit.x = offX + baseWidth * 0.02;
			brandHit.y = offY + top;
			brandHit.scale.set(Math.max(1, baseWidth * 0.96 / brandHit.frameWidth), Math.max(1, rowH / brandHit.frameHeight));
			brandHit.updateHitbox();   // 同横向：不更新的话命中区整体左移（见上面的注释）
		}
		layoutChevron();
	}

	/**
	 * 箭头贴着模式按钮左边，不跟它重叠。
	 *
	 * ★ 这里用公式算出模式按钮的左缘，而不是读 modeBg.x ——
	 *   buildBrand()（建箭头）在 buildModeButton()（建 modeBg）**之前**执行，
	 *   直接读 modeBg.x 在构造阶段会拿到 null。
	 */
	function layoutChevron()
	{
		if (horizontal)
		{
			chevron.x = brandName.x + brandName.width + baseHeight * 0.1;
			chevron.y = offY + baseHeight / 2 - chevron.height / 2;
		}
		else
		{
			var H:Float = FlxG.height;
			var modeLeft:Float = offX + baseWidth - baseWidth * V_SIDE_PAD - H * V_ICON;
			chevron.x = modeLeft - H * 0.012 - chevron.width;
			chevron.y = offY + H * V_PAD_TOP + H * V_BRAND_H / 2 - chevron.height / 2;
		}
	}

	///////////////////////////////////////////////////////////////////////////////

	function buildModeButton()
	{
		modeSize = horizontal ? baseHeight * H_ICON : FlxG.height * V_ICON;

		modeBg = new Rect(0, 0, modeSize, modeSize, modeSize * 0.25, modeSize * 0.25, EngineSet.mainColor, 0.35);
		add(modeBg);

		// 图标：一条「栏」+ 一块「内容区」，模拟竖栏/横栏两种布局
		modeBar = new Rect(0, 0, modeSize * 0.62, modeSize * 0.24, 2, 2, EngineSet.mainColor);
		modeBlock = new Rect(0, 0, modeSize * 0.62, modeSize * 0.34, 2, 2, EngineSet.mainColor, 0.45);
		add(modeBar);
		add(modeBlock);

		modeHit = new Rect(0, 0, modeSize * 0.94, modeSize * 0.94, 0, 0, 0x1A1A22, HIDDEN_ALPHA);
		add(modeHit);

		layoutModeButton();
	}

	/** 图标方向随目标模式变化：竖向时显示「切到横向」的示意图，反之亦然 */
	function layoutModeButton()
	{
		var size:Float = modeSize;
		var bx:Float;
		var by:Float;

		if (horizontal)
		{
			bx = chevron.x + chevron.width + baseHeight * 0.32;
			by = offY + (baseHeight - size) / 2;
		}
		else
		{
			var H:Float = FlxG.height;
			bx = offX + baseWidth - baseWidth * V_SIDE_PAD - size;
			by = offY + H * V_PAD_TOP + (H * V_BRAND_H - size) / 2;
		}

		modeBg.x = bx;
		modeBg.y = by;
		modeHit.x = bx;
		modeHit.y = by;

		var cx:Float = bx + (size - modeBar.width) / 2;
		var cy:Float = by + (size - (modeBar.height + modeBlock.height + 2)) / 2;

		if (horizontal)
		{
			// 目标是竖向：左窄条 + 右宽块
			modeBar.setGraphicSize(Std.int(size * 0.24), Std.int(size * 0.62));
			modeBlock.setGraphicSize(Std.int(size * 0.34), Std.int(size * 0.62));
			modeBar.updateHitbox();
			modeBlock.updateHitbox();
			modeBar.x = cx - modeBar.width / 2 - 1;
			modeBar.y = cy;
			modeBlock.x = modeBar.x + modeBar.width + 2;
			modeBlock.y = cy;
		}
		else
		{
			// 目标是横向：上窄条 + 下宽块
			modeBar.setGraphicSize(Std.int(size * 0.62), Std.int(size * 0.24));
			modeBlock.setGraphicSize(Std.int(size * 0.62), Std.int(size * 0.34));
			modeBar.updateHitbox();
			modeBlock.updateHitbox();
			modeBar.x = cx;
			modeBar.y = cy - modeBar.height / 2 - 1;
			modeBlock.x = cx;
			modeBlock.y = modeBar.y + modeBar.height + 2;
		}
	}

	///////////////////////////////////////////////////////////////////////////////

	///////////////////////////////////////////////////////////////////////////////
	// 语言列表（常态可见，不是下拉）
	///////////////////////////////////////////////////////////////////////////////

	/**
	 * 建语言条目。**必须在分类项建完之后调** —— 行高由"分类项占掉多少"倒推。
	 *
	 * ★ 行高为什么必须在这里定死：Rect 的贴图尺寸在构造时就写进缓存 key 了
	 *   （见 Rect.hx 的 addCache），之后只能靠 scale 拉伸、拉多了圆角会糊。
	 *   所以宁可在这里算准，也不要先建后改。横向模式下高度直接跟分类项一致。
	 */
	function buildLangList()
	{
		if (langBuilt) return;

		langList = OptionsState.instance.getLanguageList();
		var n:Int = langList.length;
		if (n == 0) return;

		langRowH = langRowHeight(n);
		langRowW = horizontal ? 1 : baseWidth * 0.96;
		var fs:Int = Std.int(langRowH * 0.44);

		for (i in 0...n)
		{
			var bg = new Rect(0, 0, Math.max(1, langRowW), langRowH, langRowH * 0.2, langRowH * 0.2,
				EngineSet.mainColor, HIDDEN_ALPHA);
			add(bg);
			langRowBg.push(bg);
			langRowBaseX.push(0);

			// 选中强调条：竖栏贴左侧、横栏贴底边 —— 和 NaviMember 的 specRect 同一套语言
			var spec = horizontal
				? new Rect(0, 0, langRowH * 0.9, Math.max(2, langRowH * 0.08), 0, 0, EngineSet.mainColor)
				: new Rect(0, 0, Math.max(2, langRowH * 0.08), langRowH * 0.5, 0, 0, EngineSet.mainColor);
			spec.alpha = 0;
			spec.antialiasing = ClientPrefs.data.antialiasing;
			spec.updateHitbox();
			add(spec);
			langRowSpec.push(spec);

			// 语言名一律左对齐写死，位置由 placeLangRow() 摆（横向居中、竖向左侧内缩）
			//
			// ★ 字体按「这一条语言自己声明的字体」取（含 CJK 的用 Lang-ZH）：
			//   这一列会把所有语言同时列出来，用当前语言的字体画的话，
			//   切到英文后「中文」两条就是豆腐块。见 OptionsState.getLanguageFont。
			var t = new FlxText(0, 0, 0, langLabel(i), fs);
			t.setFormat(Paths.font(OptionsState.instance.getLanguageFont(langList[i]) + '.ttf'), fs,
				FlxColor.WHITE, horizontal ? CENTER : LEFT);
			t.borderStyle = NONE;
			t.antialiasing = ClientPrefs.data.antialiasing;
			add(t);
			langRowText.push(t);
		}
		langBuilt = true;
	}

	/**
	 * 条目上显示的文字：竖向空间够 → 完整语言名；横向 → 短名（见 shortLangName）。
	 * 名字用各语言包的 `languageName`（母语写法：中文 / English / Português (Brasil)），
	 * 不是目录名 —— 目录名是给代码用的。
	 */
	function langLabel(i:Int):String
	{
		var dir:String = langList[i];
		var disp:String = OptionsState.instance.getLanguageLabel(dir);
		return horizontal ? shortLangName(dir, disp) : disp;
	}

	/**
	 * 横向栏专用的短名。
	 *
	 * ★ 顶栏只有 7vh 高，还要塞下 9 个分类项 —— 完整语言名（"Português (Brasil)"
	 *   在 15px 字号下接近 150px）会把分类项一路挤到 5~6px 字，根本看不清。
	 *   所以横向只显示一个 2~4 字的标记，竖向栏（下面空间足够）仍然显示完整名字。
	 *   CJK 名本身就很短（中文 / 不是人话）直接原样用；拉丁名才缩成 2 字母代号。
	 */
	static function shortLangName(dir:String, display:String):String
	{
		if (OptionsState.hasCJK(display) && display.length <= 4) return display;
		switch (dir)
		{
			case 'English': return 'EN';
			case 'Portuguese (Brazil)': return 'PT';
			case 'JustSay': return 'JS';
		}
		// mod 新增语言：去掉括号注释、截断到 4 字
		var s:String = display;
		var p:Int = s.indexOf('(');
		if (p > 0) s = s.substr(0, p);
		s = StringTools.trim(s);
		return s.length > 4 ? s.substr(0, 4) : s;
	}

	/**
	 * 语言条目的高度。
	 *
	 * 竖向栏里语言列表紧跟在分类列表下面，而它下面还有一条「返回」栏压着
	 * （屏高 10%），所以可用高度 = bottomBarTop() − 语言列表起点。
	 * 4 个语言时约 30px/条，正好和旧的"白底按钮"（≈4.2vh）等高；
	 * 语言再多就自适应变矮，但不会低于 LANG_MIN_ROW，也不会比分类项还高。
	 */
	function langRowHeight(n:Int):Float
	{
		if (n <= 0) return 0;
		if (horizontal) return memberSizeY();

		var gap:Float = Math.max(2, FlxG.height * LANG_GAP_V);
		var top:Float = memberTopY() + parent.length * memberSizeY() + FlxG.height * V_LANG_GAP;
		var avail:Float = OptionsState.instance.bottomBarTop() - top;
		var h:Float = (avail - gap * (n - 1)) / n;

		var maxH:Float = memberSizeY() * 0.78;
		if (h > maxH) h = maxH;
		if (h < LANG_MIN_ROW) h = LANG_MIN_ROW;
		return h;
	}

	/** 竖向栏：语言列表紧跟在分类列表下面排成一列 */
	function layoutLangItems(topY:Float)
	{
		var n:Int = langRowBg.length;
		if (n == 0 || horizontal) return;

		var gap:Float = Math.max(2, FlxG.height * LANG_GAP_V);
		langRowW = baseWidth * 0.96;
		var bx:Float = offX + baseWidth * 0.02;
		var y:Float = offY + topY + FlxG.height * V_LANG_GAP;

		for (i in 0...n)
		{
			langRowBaseX[i] = bx;
			placeLangRow(i, bx, y);
			y += langRowH + gap;
		}
	}

	/** 摆一条语言条目（底 + 文字）。强调条每帧跟着底走，见 updateLangRows() */
	function placeLangRow(i:Int, x:Float, y:Float)
	{
		var bg = langRowBg[i];
		bg.x = x;
		bg.y = y;
		// 底贴图是构造时按当时的宽度画的，栏宽变了（setBarWidth / 横向量宽度）只能靠 scale 拉
		bg.scale.x = Math.max(0.05, langRowW / bg.frameWidth);
		bg.updateHitbox();

		var t = langRowText[i];
		// ★ 文字不透明度**不能**跟着底走：底的 alpha 是悬停高亮（HIDDEN_ALPHA ⇄ 0.16），
		//   绑上去的话文字几乎永远不可见。文字恒为 1，隐藏靠整行滑出栏外（见 applyLangRow）。
		// 对齐也在这里定：fitLangRows() 会把横向的文字改成 CENTER，横→竖切回来要改回 LEFT，
		// 否则 placeLangRow 按左内缩摆 x、文字却仍居中 → 整体左偏半个字宽。
		var want:FlxTextAlign = horizontal ? CENTER : LEFT;
		if (t.alignment != want) t.alignment = want;
		t.y = y + langRowH / 2 - t.height / 2;
		t.x = horizontal ? (x + langRowW / 2 - t.width / 2) : (x + langRowH * 0.5);
	}

	/**
	 * 横向栏专用：按字号系数 f 重新量一遍语言条目。
	 * 整组统一宽度（取最长的语言名），否则一排参差不齐的胶囊比分类项还乱。
	 */
	function fitLangRows(f:Float):Void
	{
		var n:Int = langRowText.length;
		if (n == 0) return;

		var pad:Float = langRowH * 0.4 * f;
		var fs:Int = Std.int(Math.max(6, langRowH * 0.44 * f));
		var maxW:Float = 1;

		for (i in 0...n)
		{
			var t = langRowText[i];
			t.setFormat(Paths.font(Language.get('fontName', 'main') + '.ttf'), fs, FlxColor.WHITE, CENTER);
			t.borderStyle = NONE;
			if (t.width > maxW) maxW = t.width;
		}

		langRowW = Math.ceil(maxW + pad * 2);
		for (i in 0...n)
		{
			var bg = langRowBg[i];
			bg.scale.x = Math.max(0.05, langRowW / bg.frameWidth);
			bg.updateHitbox();
		}
	}

	/**
	 * 鼠标是否落在**语言条目**上。
	 * 母层/成员层用它让开点击与 hover：分类项的 hover 高亮读的就是这个
	 * （见 NaviMember.update / OptionsState.onMemberClick）。
	 */
	/**
	 * 语言条目的矩形命中判定。
	 *
	 * ★ 为什么不用 `mouse.overlaps()`：条目底是用「贴图 + scale.x」拉出来的，
	 *   横向模式下贴图只有 **1×35**、scale.x ≈ 63（见 buildLangList / fitLangRows）。
	 *   缩放是以 origin（贴图中心）为锚点的，`updateHitbox()` 会写一个补偿 offset（≈ −31），
	 *   而 Flixel 的 `overlapsPoint` 只比 `x .. x+width`、渲染却还要叠上 offset/origin ——
	 *   两边在"贴图尺寸 ≠ 最终尺寸"时不重合，表现就是**看着点在条上却点不中**
	 *   （竖向模式贴图就是最终宽度、scale≈1，所以看起来只有横向出问题）。
	 *   这里直接用 `x / y / width / height`（`updateHitbox()` 之后就是"可见外框"那一套，两种
	 *   模式都自洽）做纯几何判定，不受缩放/原点影响。
	 */
	inline function inLangRow(bg:FlxSprite, mx:Float, my:Float):Bool
		return bg.visible && mx >= bg.x && mx < bg.x + bg.width && my >= bg.y && my < bg.y + bg.height;

	public function langSwallowsMouse():Bool
	{
		if (!isOpened) return false;
		var mx:Float = FlxG.mouse.x;
		var my:Float = FlxG.mouse.y;
		for (i in 0...langRowBg.length)
		{
			// ★ 这里**不能**加 alpha 门槛：底的 alpha 是悬停高亮，常态只有 HIDDEN_ALPHA，
			//   峰值也只有 0.16（和 NaviMember 同一套）。加了门槛就永远不成立 → 语言行点不动。
			//   收起时整行已经滑到栏外，几何判定自然为 false，不需要额外处理。
			if (inLangRow(langRowBg[i], mx, my)) return true;
		}
		return false;
	}

	/** 换语言后：条目字号/宽度都要重算（不同语言用的字体不一样宽） */
	public function refreshLangVisual(animate:Bool)
	{
		if (!langBuilt) return;
		for (i in 0...langRowText.length)
			langRowText[i].text = langLabel(i);   // 语言名是字面量，不随当前语言变
		layoutMembers();
	}

	/** 本帧悬停到的语言条目（-1 = 没有）；顺便驱动悬停高亮 */
	function updateLangRows(mouse:MouseEvent):Void
	{
		var n:Int = langRowBg.length;
		if (n == 0) return;

		langFocus = -1;
		var locked:Bool = OptionsState.instance.inputLocked;
		var mx:Float = FlxG.mouse.x;
		var my:Float = FlxG.mouse.y;

		if (!locked && isOpened)
		{
			for (i in 0...n)
			{
				var bg = langRowBg[i];
				if (inLangRow(bg, mx, my))
				{
					langFocus = i;
					if (mouse.justReleased)
					{
						OptionsState.instance.requestLanguage(langList[i]);
						return;
					}
				}
			}
		}

		// 悬停高亮：和 NaviMember 一样是"每帧往目标插值"，不是硬切
		var bStep:Float = EngineSet.FPSfix(0.012);
		if (!Math.isFinite(bStep) || bStep <= 0) bStep = 0.012;

		var sStep:Float = EngineSet.FPSfix(0.18);
		if (!Math.isFinite(sStep) || sStep <= 0) sStep = 0.18;

		for (i in 0...n)
		{
			var bg = langRowBg[i];
			if (!Math.isFinite(bg.alpha)) bg.alpha = HIDDEN_ALPHA;

			var hi:Float = (i == langFocus) ? 0.16 : HIDDEN_ALPHA;
			if (bg.alpha < hi) bg.alpha = Math.min(hi, bg.alpha + bStep);
			else if (bg.alpha > hi) bg.alpha = Math.max(hi, bg.alpha - bStep);

			var spec = langRowSpec[i];
			if (!Math.isFinite(spec.alpha)) spec.alpha = 0;

			var target:Float = (langList[i] == ClientPrefs.data.language) ? 1 : 0;
			spec.alpha += (target - spec.alpha) * sStep;
			if (Math.abs(spec.alpha) < 0.02 && target == 0) spec.alpha = 0;

			// 强调条跟着条目底走（折叠动画会平移底，强调条不能留在原地）
			spec.x = bg.x + (horizontal ? (langRowW - spec.width) / 2 : langRowH * 0.22);
			spec.y = bg.y + (horizontal ? langRowH - spec.height : (langRowH - spec.height) / 2);
			spec.visible = spec.alpha > 0.01;
		}
	}

	///////////////////////////////////////////////////////////////////////////////

	/** 创建 9 个分类项并排布（由 OptionsState 在拿到分类列表后调用） */
	public function buildMembers(names:Array<String>)
	{
		for (i in 0...parent.length) remove(parent[i], true);
		parent = [];

		var mh:Float = memberSizeY();
		var mw:Float = memberSizeX();

		for (i in 0...names.length)
		{
			var m:NaviMember = new NaviMember(names[i], i, horizontal, 0, 0, mw, mh);
			add(m);
			parent.push(m);
		}
		// ★ 语言条目必须晚于分类项建：它的行高是从"分类项占掉多少"倒推的
		if (USE_INLINE_LANG_LIST) buildLangList();
		layoutMembers();
	}

	/** 分类项的尺寸：垂直按视口高，横向按栏高（横向项宽由文字宽度决定，见 NaviMember） */
	inline function memberSizeY():Float
		return horizontal ? baseHeight * H_MEMBER_H : FlxG.height * V_MEMBER_H;

	inline function memberSizeX():Float
		return horizontal ? baseHeight * 1.1 : baseWidth * 0.96;

	inline function memberTopY():Float
		return horizontal ? 0 : FlxG.height * (V_PAD_TOP + V_BRAND_H + V_BRAND_GAP);

	function layoutMembers()
	{
		if (horizontal)
		{
			layoutHorizontalMembers();
			return;
		}

		var y:Float = offY + memberTopY();
		for (m in parent)
		{
			m.baseX = offX + baseWidth * 0.02;
			m.x = m.baseX;
			m.y = y;
			y += m.mainHeight;
		}
		// 语言列表紧跟在分类列表下面（y 已经停在最后一项的底边）
		layoutLangItems(y - offY);
	}

	/**
	 * 横向栏：把分类项 + 语言条目排成一行，并且**保证收在 [条左边界, 屏幕右内边距] 之内**。
	 *
	 * web 原型那边是 `#membersH{flex:1 1 auto; overflow-x:auto}`（装不下就横向滚动），
	 * 这里换成"逐档缩字号"：从 1.0 倍降到 0.62 倍，每档重新量一次宽度，
	 * 直到整行装得下；还差一点就把间距压到最小。于是：
	 *   · 不会再溢出到屏幕外（用户报的"最后几项被切掉 / 压到 logo 上"）
	 *   · 分类多的时候只是字小一圈，全部仍然可见、可点
	 *
	 * ★ 语言条目**单独分预算**、不跟分类项挤同一个"缩字号"循环：
	 *   语言名（"Portuguese (Brazil)"）比分类名长得多，混在一起缩会把分类项
	 *   一起拖到看不清。所以先按 f=1 量出语言组想要的总宽、封顶 avail 的 45%，
	 *   分类项在剩下的宽度里自适应，语言组再在自己的预算里缩一次。
	 */
	function layoutHorizontalMembers()
	{
		var stripL:Float = langStripLeft();
		var stripR:Float = FlxG.width - baseHeight * 0.24;
		var avail:Float = Math.max(1, stripR - stripL);

		var nMem:Int = parent.length;
		var nLang:Int = langRowBg.length;
		var gap:Float = baseHeight * 0.09;
		var langGap:Float = baseHeight * 0.2;

		// ── 语言组先量"想要多宽"，并封顶 ──────────────────────────────
		var langBudget:Float = 0;
		if (nLang > 0)
		{
			fitLangRows(1);
			var want:Float = langRowW * nLang + gap * (nLang - 1);
			var cap:Float = avail * 0.45;
			langBudget = (want > cap) ? cap : want;
		}

		var memAvail:Float = Math.max(1, avail - langBudget - (nLang > 0 ? langGap : 0));

		var total:Float = 0;
		var f:Float = 1;
		while (true)
		{
			total = 0;
			for (m in parent)
			{
				m.applyFit(f);
				total += m.mainWidth;
			}
			if (nMem > 1) total += gap * (nMem - 1);
			if (total <= memAvail || f <= 0.62) break;
			f -= 0.06;
		}

		// 缩字号还差一点 → 把间距压到最小
		if (nMem > 1 && total > memAvail)
		{
			var itemsW:Float = total - gap * (nMem - 1);
			gap = Math.max(baseHeight * 0.02, (memAvail - itemsW) / (nMem - 1));
		}

		var x:Float = stripL;
		for (m in parent)
		{
			m.baseX = x;
			m.x = x;
			m.y = offY + (baseHeight - m.mainHeight) / 2;
			x += m.mainWidth + gap;
		}
		if (nMem > 0) x -= gap;
		hStripRight = x;

		// ── 语言组：贴着分类组右边，在自己那一份预算里再缩一次 ──────────
		if (nLang == 0) return;

		var lx:Float = (nMem > 0 ? x : stripL) + langGap;
		var lLimit:Float = Math.max(1, stripR - lx);
		var lf:Float = 1;
		while (true)
		{
			fitLangRows(lf);
			var w:Float = langRowW * nLang + gap * (nLang - 1);
			if (w <= lLimit || lf <= 0.55) break;
			lf -= 0.06;
		}

		var ly:Float = offY + (baseHeight - langRowH) / 2;
		for (i in 0...nLang)
		{
			langRowBaseX[i] = lx;
			placeLangRow(i, lx, ly);
			lx += langRowW + gap;
		}
	}

	/** 横向栏里分类/语言这一段的左边界：品牌 + 折叠箭头 + 模式按钮之后 */
	function langStripLeft():Float
	{
		if (!horizontal) return 0;
		return modeBg.x + modeSize + baseHeight * 0.3;
	}

	/** 折叠/展开一级列表：整列向左侧滑出去（高度不变），逐项错开 LIST_STAGGER(15ms) */
	public function setListOpen(open:Bool, animate:Bool)
	{
		if (isOpened == open && animate) return;
		isOpened = open;

		// ★ 先清掉上一批补间（含还没到 startDelay、尚未生效的那些），见 listTweens 的注释
		killListTweens();

		var n:Int = parent.length;
		var nL:Int = langRowBg.length;
		if (!animate)
		{
			for (i in 0...n) applyItemX(parent[i], open ? 1 : 0, i, n, false);
			for (i in 0...nL) applyLangRow(i, open ? 1 : 0, false);
			return;
		}

		for (i in 0...n)
		{
			var delay:Float = (open ? i : (n - 1 - i)) * LIST_STAGGER;
			applyItemX(parent[i], open ? 1 : 0, i, n, true, delay);
		}
		// 语言条目接着分类项的顺序往下错开（收起时反过来）
		for (i in 0...nL)
		{
			var delay:Float = (open ? (n + i) : (nL - 1 - i)) * LIST_STAGGER;
			applyLangRow(i, open ? 1 : 0, true, delay);
		}
	}

	/**
	 * 把一级列表硬落回当前 isOpened 对应的位置（不走补间）。
	 * 模式切换、以及补间可能被打断的地方用它兜底，保证「显示状态」和「实际几何」一致。
	 */
	public function settleList():Void
	{
		killListTweens();
		var n:Int = parent.length;
		for (i in 0...n) applyItemX(parent[i], isOpened ? 1 : 0, i, n, false);
		for (i in 0...langRowBg.length) applyLangRow(i, isOpened ? 1 : 0, false);
	}

	/** p=1 完全展开，p=0 完全滑出栏外 */
	function applyItemX(m:NaviMember, p:Float, idx:Int, n:Int, animate:Bool, ?delay:Float = 0)
	{
		var to:Float = m.baseX + (1 - p) * (-m.mainWidth - baseWidth * 0.12);
		if (!animate) { m.x = to; m.alpha = p; return; }
		keepTween(FlxTween.tween(m, {x: to}, LIST_DUR, {ease: FlxEase.expoInOut, startDelay: delay}));
		keepTween(FlxTween.tween(m, {alpha: p}, LIST_DUR * 0.7, {ease: FlxEase.expoOut, startDelay: delay}));
	}

	/**
	 * 语言条目跟着整条栏一起滑出去/滑回来。
	 *
	 * ★ 只 tween **x**，不碰 alpha。
	 *   底的 alpha 已经被 updateLangRows() 用作"悬停高亮"（HIDDEN_ALPHA ⇄ 0.16），
	 *   这里再补一条 alpha→p 的补间，两个写手每帧抢同一个字段，结果是
	 *   「收起动画做完、底却停在 0.16 的高亮上」「展开后底永远到不了 1」。
	 *   收起 = 整行滑到栏外（x 方向出屏），几何上已经看不见了，不需要 alpha。
	 *
	 * ★ 强调条也不参与：它的 alpha 由"是不是当前语言"驱动，
	 *   可见性由 updateLangRows() 里的 `spec.alpha > 0.01` 控制。
	 */
	function applyLangRow(i:Int, p:Float, animate:Bool, ?delay:Float = 0)
	{
		var bg = langRowBg[i];
		var t = langRowText[i];
		var tx:Float = langRowBaseX[i] + (langRowW / 2 - t.width / 2);
		var lx:Float = horizontal ? tx : (langRowBaseX[i] + langRowH * 0.5);
		var shift:Float = (1 - p) * (-langRowW - baseWidth * 0.12);
		var to:Float = langRowBaseX[i] + shift;
		var toText:Float = lx + shift;

		if (!animate)
		{
			bg.x = to;
			t.x = toText;
			return;
		}
		keepTween(FlxTween.tween(bg, {x: to}, LIST_DUR, {ease: FlxEase.expoInOut, startDelay: delay}));
		keepTween(FlxTween.tween(t, {x: toText}, LIST_DUR, {ease: FlxEase.expoInOut, startDelay: delay}));
	}

	///////////////////////////////////////////////////////////////////////////////
	// 整条栏的偏移：这是唯一的"隐藏/显示"手段
	///////////////////////////////////////////////////////////////////////////////

	/**
	 * 把整条栏平移到 (x, y)。传绝对值，补间里用 `setOff(x0 + (x1-x0)*t, ...)` 即可。
	 *
	 * 用增量平移而不是"重算布局"，是为了不和 setListOpen 的逐项补间打架；
	 * 但 RoundRect 子元素的定位基准（mainX/mainY）必须同步，否则下一次
	 * changeWidth / changeHeight 会把底板摆回原点。
	 */
	public function setOff(x:Float, y:Float)
	{
		var dx:Float = x - offX;
		var dy:Float = y - offY;
		offX = x;
		offY = y;
		if (dx == 0 && dy == 0) return;

		for (s in members)
		{
			if (s == null || s == barBG) continue;   // barBG 用绝对 setRect，不参与增量平移
			s.x += dx;
			s.y += dy;
		}
		for (m in parent) m.baseX += dx;
		for (i in 0...langRowBaseX.length) langRowBaseX[i] += dx;

		barBG.setRect(offX, offY, getBarW(), getBarH());
	}

	/** 栏的屏幕矩形（给磨砂层裁剪用） */
	public function getBarRect(?out:FlxRect):FlxRect
	{
		var r:FlxRect = (out == null) ? new FlxRect(0, 0, 0, 0) : out;
		r.set(offX, offY, getBarW(), getBarH());
		return r;
	}

	/** 立刻把整条栏推到屏幕外（初始化用，不走补间） */
	public function hideNow()
	{
		killListTweens();
		if (horizontal) setOff(0, -getBarH() * 1.1);
		else setOff(-getBarW() * 1.1, 0);
	}

	/** 栏底尺寸变化：竖向栏改宽、横向栏改高（展开时吸收与面板之间的缝隙） */
	public function setBarWidth(w:Float)
	{
		baseWidth = w;
		barBG.setRect(offX, offY, w, FlxG.height);
		if (!horizontal)
		{
			layoutBrand();
			layoutModeButton();
			layoutMembers();
		}
	}

	public function setBarHeight(h:Float)
	{
		baseHeight = h;
		barBG.setRect(offX, offY, FlxG.width, h);
		if (horizontal)
		{
			// 注意：modeSize 不跟着改 —— Rect 的贴图尺寸在构造时就定死了，
			// 只改这个数字会让按钮的"命中区/图标"和可见的底板对不上
			layoutBrand();
			layoutModeButton();
			layoutMembers();
		}
	}

	public var onFocus:Bool = false;
	public var chevronFocus:Bool = false;
	public var modeFocus:Bool = false;

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		var mouse = OptionsState.instance.mouseEvent;
		onFocus = mouse.overlaps(brandHit) || mouse.overlaps(modeHit);
		chevronFocus = mouse.overlaps(brandHit);
		modeFocus = mouse.overlaps(modeHit);

		// 语言条目的悬停高亮 / 点击切换（常态可见，没有下拉面板）
		updateLangRows(mouse);

		// 箭头随展开状态旋转（用缩放模拟，避免额外素材）
		chevron.scale.y = isOpened ? 1 : -1;

		if (OptionsState.instance.inputLocked) return;

		// ★ 两个命中区**必须互斥**（下面的 else if）。
		//   品牌行命中区在竖向模式下覆盖整条栏的顶部（x 3..212, y 32..86），
		//   而模式按钮就压在它的右端 —— 两者是重叠的。写成两个独立 if 时，
		//   一次点击会同时触发「折叠/展开列表」和「切换竖/横模式」：
		//   列表那条 setListOpen 补间写的是**绝对坐标** baseX，和模式切换的
		//   setOff(整条栏平移) 互相覆盖 —— 结果是横栏已经进来了，竖向的分类项
		//   却还留在屏幕左边（而且栏底磨砂已经移走，看起来像浮在背景上）。
		//   模式按钮是更小、更明确的目标，点击时优先它。
		if (modeFocus && mouse.justReleased)
			OptionsState.instance.toggleMode();
		else if (chevronFocus && mouse.justReleased)
			setListOpen(!isOpened, true);
	}

	///////////////////////////////////////////////////////////////////////////////

	/** 换语言后字号 / 文字宽度会变，品牌行、模式按钮、分类项、语言条目都要重排 */
	public function changeLanguage()
	{
		var nameSize:Int = Std.int(horizontal ? baseHeight * H_NAME : FlxG.height * V_NAME);
		brandName.setFormat(Paths.font(Language.get('fontName', 'main') + '.ttf'), nameSize, FlxColor.WHITE, LEFT);
		brandName.borderStyle = NONE;
		if (!horizontal)
		{
			brandTag.setFormat(Paths.font(Language.get('fontName', 'main') + '.ttf'), Std.int(FlxG.height * V_TAG), 0x9BA1B8, LEFT);
			brandTag.borderStyle = NONE;
		}
		for (m in parent) m.changeLanguage();
		// 顺序要紧：品牌名宽度变了 → 箭头位置变 → 模式按钮和整条内容条跟着挪
		layoutBrand();
		layoutModeButton();
		layoutMembers();
	}
}
