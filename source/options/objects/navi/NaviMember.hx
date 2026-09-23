package options.objects.navi;

import options.FontFallback;

// 侧边栏里的一个设置分类项。
//
// 同一个分类会创建两份实例：一份给垂直侧边栏、一份给横向顶栏 ——
// 因为两者的尺寸不同，而 Rect 的贴图尺寸在构造时就定死了、之后改不了。
// 用 horizontal 标记区分两种排布：
//   垂直：贴左侧栏，左对齐，左边一条竖强调条 + 一个圆点
//   横向：压在顶栏里横排，文字居中，底边一条横强调条（宽度按文字自适应）
class NaviMember extends FlxSpriteGroup
{
	/** Rect 参与命中判定需要 alpha>0，但这里只要它当命中区、不要可见 */
	inline static var HIDDEN_ALPHA:Float = 0.0000001;

	// 横向栏里每一项的紧凑比例（都按"项高"换算，对齐 web 原型 .nav-item.hm：
	// 高 4.9vh、字号 1.42vh、左右内边距 1.1vh）
	inline static var HF_FONT:Float = 0.26;      // 字号 / 项高
	inline static var HF_PAD:Float = 0.2;        // 单侧内边距 / 项高
	inline static var HF_ICON_GAP:Float = 0.2;   // 图标与文字间距 / 项高

	public var optionSort:Int;
	public var memberName:String;
	public var horizontal:Bool;

	var background:Rect;
	var specRect:Rect;
	var icon:FlxSprite;
	var textDis:FlxText;

	/** 整项宽高（不要用 FlxSpriteGroup.width，那个由成员推导、不可直接写） */
	public var mainWidth:Float;
	public var mainHeight:Float;
	public var mainX:Float;
	public var mainY:Float;
	/** 展开状态下的基准 x，折叠动画从这里滑出去 */
	public var baseX:Float = 0;

	public var onFocus:Bool = false;
	public var cataChoose:Bool = false;

	///////////////////////////////////////////////////////////////////////////////

	public function new(name:String, sort:Int, horizontal:Bool, X:Float, Y:Float, width:Float, height:Float)
	{
		super(X, Y);

		this.memberName = name;
		this.optionSort = sort;
		this.horizontal = horizontal;
		this.mainHeight = height;

		var fontSize:Int = Std.int(height * (horizontal ? 0.36 : 0.35));

		// 先建文字：横向模式下整项宽度要按文字宽自适应
		textDis = new FlxText(0, 0, 0, Language.get(name, 'options'), fontSize);
		// ★ 分类名（"常规设置"…）**在任何语言包里都是中文**，而界面切到 English 时
		//   当前字体是纯拉丁的 chillax（没有汉字字形）—— 所以必须按**这段文本**
		//   去挑字体，而不是按"当前语言"。见 FontFallback。
		textDis.setFormat(FontFallback.uiFont(textDis.text), fontSize,
			FlxColor.WHITE, horizontal ? CENTER : LEFT);
		textDis.borderStyle = NONE;
		textDis.antialiasing = ClientPrefs.data.antialiasing;

		if (horizontal) width = Math.max(width, textDis.width + height * 0.95);
		mainWidth = width;

		// 悬停高亮（同时充当命中区）
		background = new Rect(0, 0, width, height, height / 5, height / 5, EngineSet.mainColor, HIDDEN_ALPHA);
		add(background);

		// 选中强调条：垂直在左侧竖着、横向在底部横着
		// （scale 见 update()，那里每帧跟着 cataChoose 平滑伸缩）
		if (horizontal)
		{
			var th:Float = Math.max(2, height * 0.07);
			specRect = new Rect(0, 0, height * 0.75, th, 0, 0, EngineSet.mainColor);
			specRect.scale.x = 0;
		}
		else
		{
			var tw:Float = Math.max(2, height * 0.06);
			specRect = new Rect(0, 0, tw, height * 0.47, 0, 0, EngineSet.mainColor);
			specRect.scale.y = 0;
		}
		specRect.alpha = 0;
		specRect.antialiasing = ClientPrefs.data.antialiasing;
		// ★ 缩放锚点在贴图中心：先 updateHitbox 把 offset/origin 归一，之后
		//   改 scale 才会"从左上角长出来"而不是"从中心往两边长"。
		specRect.updateHitbox();
		add(specRect);

		// 分类图标：由 NewOptionState.htm 里的内联 SVG 批量导出（纯白 + 透明底），
		// 这里染色成主题色；文件名必须与分类名完全一致，引擎就是按名字找图的
		icon = new FlxSprite().loadGraphic(Paths.image('menuExtend/OptionsState/icons/' + name));
		icon.setGraphicSize(Std.int(height * (horizontal ? 0.52 : 0.58)));
		icon.updateHitbox();
		icon.antialiasing = ClientPrefs.data.antialiasing;
		icon.color = horizontal ? EngineSet.mainColor : 0x9BA1B8;
		add(icon);

		add(textDis);
		layoutContent();
		centerSpec();
		if (horizontal) refreshWidth();   // 图标建好后再把整项宽度补足
	}

	/**
	 * 图标 + 文字的排布：竖向靠左、横向作为整体居中。
	 *
	 * ★★ 必须加上组自身的 (x, y) ★★
	 *   本类是 FlxSpriteGroup，子元素（icon/textDis/specRect/background）存的是
	 *   **屏幕绝对坐标**（FlxSpriteGroup.preAdd 会 `sprite.x += x`，set_x 也按增量
	 *   平移子元素）。所以这里写 icon.x 时必须写 (组.x + 局部偏移)。
	 *
	 *   旧实现直接写局部偏移 —— 只有在「组刚好在 (0,0)」时才碰巧正确：
	 *   构造函数里确实在 (0,0)，可横向栏每次重新排（setBarHeight → layoutMembers →
	 *   applyFit → layoutContent）都会把子元素**打回原点附近**；
	 *   而此时 m.x 已经是 313 之类的值没变，`m.x = x` 就不会再触发增量平移，
	 *   于是 9 个分类的图标/文字全部堆在 (22,69) 这种位置上 —— 既不在栏里、
	 *   还压在品牌区上（用户报的"横向栏里根本没有分类项"）。
	 */
	function layoutContent()
	{
		var ox:Float = x;   // 组自身的屏幕位置；子元素按绝对坐标定位
		var oy:Float = y;
		var gap:Float = mainHeight * 0.22;
		icon.y = oy + mainHeight / 2 - icon.height / 2;
		textDis.y = oy + mainHeight / 2 - textDis.height / 2;
		if (horizontal)
		{
			var total:Float = icon.width + gap + textDis.width;
			icon.x = ox + (mainWidth - total) / 2;
			textDis.x = icon.x + icon.width + gap;
		}
		else
		{
			icon.x = ox + mainHeight * 0.52;
			textDis.x = icon.x + icon.width + mainHeight * 0.34;
		}
	}

	///////////////////////////////////////////////////////////////////////////////

	/**
	 * 强调条跟着整项走：横向贴底边、以中心左右伸缩；竖向贴左边、以中心上下伸缩。
	 * 两边都读 specRect.width/height（= 贴图尺寸 × 当前 scale，updateHitbox 之后才准），
	 * 所以伸缩过程中始终"以自身中心对齐整项中心"。
	 */
	function centerSpec()
	{
		if (horizontal)
		{
			specRect.x = x + (mainWidth - specRect.width) / 2;
			specRect.y = y + mainHeight - specRect.height;
		}
		else
		{
			specRect.x = x + mainHeight * 0.22;
			specRect.y = y + (mainHeight - specRect.height) / 2;
		}
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		mainX = this.x;
		mainY = this.y;

		var mouse = OptionsState.instance.mouseEvent;
		// ★ 语言区块（展开的列表 / 语言按钮）盖在分类项上面时，分类项必须让开：
		//   否则鼠标移到语言列表上，下面的分类项照样亮起 hover 高亮、
		//   视觉上像"同时选中了别的元素"（点击由 onMemberClick 里的
		//   langSwallowsMouse() 兜住，这里补的是 hover 高亮）。
		onFocus = !OptionsState.instance.langBlockSwallow && mouse.overlaps(background);

		// 选中强调条平滑伸缩，避免切换时硬跳
		//
		// ★ 步长必须做有限性矫正：EngineSet.FPSfix = data * 60 / DataCalc.updateFPS，
		//   而启动头几帧 updateFPS 还是 0 → 得到 Infinity；此时 (target - alpha) 也是 0，
		//   0 * Infinity = NaN，写进 alpha/scale 之后就**永远是 NaN**（NaN += x 恒为 NaN）。
		//   结果选中强调条整条不显示（横向/竖向都中招），这里顺手把已有污染也洗掉。
		var step:Float = EngineSet.FPSfix(0.18);
		if (!Math.isFinite(step) || step <= 0) step = 0.18;
		if (!Math.isFinite(specRect.alpha)) specRect.alpha = 0;
		if (!Math.isFinite(specRect.scale.x)) specRect.scale.x = 0;
		if (!Math.isFinite(specRect.scale.y)) specRect.scale.y = 0;

		var target:Float = cataChoose ? 1 : 0;
		if (horizontal) specRect.scale.x += (target - specRect.scale.x) * step;
		else specRect.scale.y += (target - specRect.scale.y) * step;
		specRect.alpha += (target - specRect.alpha) * step;
		if (Math.abs(specRect.alpha) < 0.02 && target == 0) specRect.alpha = 0;
		specRect.updateHitbox();   // 改完 scale 必须更新，否则强调条会从中心往两边长/缩
		centerSpec();

		var bStep:Float = EngineSet.FPSfix(0.012);
		if (!Math.isFinite(bStep) || bStep <= 0) bStep = 0.012;

		if (onFocus)
		{
			if (background.alpha < 0.16) background.alpha += bStep;
			if (mouse.justReleased && !OptionsState.instance.inputLocked) OptionsState.instance.onMemberClick(this);
		}
		else if (background.alpha > HIDDEN_ALPHA)
		{
			background.alpha = Math.max(HIDDEN_ALPHA, background.alpha - bStep);
		}
	}

	public function changeLanguage()
	{
		var fontSize:Int = Std.int(mainHeight * (horizontal ? 0.36 : 0.35));
		textDis.text = Language.get(memberName, 'options');
		textDis.setFormat(FontFallback.uiFont(textDis.text), fontSize,
			FlxColor.WHITE, horizontal ? CENTER : LEFT);
		textDis.borderStyle = NONE;
		if (horizontal) refreshWidth(); else layoutContent();
	}

	/** 横向模式下文字长度会变（换语言），整项宽度要跟着重算 */
	public function refreshWidth()
	{
		if (!horizontal) { layoutContent(); return; }
		mainWidth = Math.max(mainWidth, icon.width + textDis.width + mainHeight * 1.05);
		fitBackground();
		layoutContent();
		centerSpec();
	}

	/**
	 * 横向栏专用：按字号系数 f 重新排版，并**从零**量出整项宽度。
	 *
	 * 为什么需要它：横向栏要把所有分类挤进一行（web 原型是 flex + overflow-x 滚动）。
	 * 以前每项的宽度是 `文字 + 项高*0.95` 再取 max，字号 0.36*项高 —— 9 个中文分类
	 * 总宽就能超过整条屏幕，于是最后几项被挤出右边界、还压到品牌/模式/语言按钮上。
	 * 现在改成"紧凑比例 + 可缩放"：layoutHorizontalMembers() 从 f=1 逐档往下试，
	 * 保证整行永远收在 [条左, 条右] 之内。
	 *
	 * 注意用的是赋值（不是 Math.max），才能既放大也**缩小**。
	 */
	public function applyFit(f:Float):Void
	{
		if (!horizontal) return;

		var fs:Int = Std.int(Math.max(6, mainHeight * HF_FONT * f));
		textDis.setFormat(FontFallback.uiFont(textDis.text), fs, FlxColor.WHITE, CENTER);
		textDis.borderStyle = NONE;

		var pad:Float = mainHeight * HF_PAD * f;
		var gap:Float = mainHeight * HF_ICON_GAP * f;
		mainWidth = Math.ceil(pad * 2 + icon.width + gap + textDis.width);

		if (background != null && background.frameWidth > 0)
			fitBackground();
		layoutContent();
		centerSpec();
	}

	/**
	 * 把悬停高亮/命中区拉到当前项宽。
	 * 横向栏项宽是量出来的（会随字号档位变），而高亮的贴图宽是构造时定死的，
	 * 只能靠 scale.x 拉。
	 *
	 * ★ 必须 updateHitbox()：缩放锚在贴图中心，不更新的话高亮会往左偏
	 *   (mainWidth - frameWidth)/2 —— 命中判定也跟着偏，鼠标放在右半边点不中。
	 */
	function fitBackground():Void
	{
		if (background == null || background.frameWidth <= 0) return;
		background.scale.x = Math.max(0.05, mainWidth / background.frameWidth);
		background.updateHitbox();
	}
}
