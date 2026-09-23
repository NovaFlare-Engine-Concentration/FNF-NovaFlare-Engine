package options.objects;

import flixel.graphics.FlxGraphic;
import options.FontFallback;

/**
 * 语言面板：**左侧一列「国旗 + 母语名」，右侧一段该语言的示例文本**。
 *
 * ── 为什么不再用「一列文字」选语言 ──────────────────────────────────────
 *   原来是侧边栏底部竖着一列语言名。问题有两个：
 *   ① 竖栏底部空间有限，语言一多就得把行高压到 LANG_MIN_ROW，字小到看不清；
 *   ② 文字本身不直观 —— 「Português (Brasil)」和「Portuguese (Brazil)」在玩家眼里
 *      没有区别，而一面国旗是一眼的事。
 *   所以改成独立面板，挂在侧边栏**最上面**（见 OptionsState.create 里
 *   `groups.insert(0, 'Language')`）。
 *
 * ── 右侧的示例文本 ────────────────────────────────────────────────────
 *   每种语言在各自的 `main/main.lang` 里写一行 `langPreview => …`（没写就退回中文原文）。
 *   文本本身是同一句话的各语言译文，**并且用该语言自己的字体渲染** ——
 *   于是切语言前就能看到"这个语言读起来是什么样"。
 *
 * ── 坐标约定（很重要）────────────────────────────────────────────────
 *   本类是 FlxSpriteGroup，子元素存的是**屏幕绝对坐标**（FlxSpriteGroup.preAdd 会
 *   `sprite.x += x`）。本面板自己被加到 OptionCata 之后，cata 的布局会把面板整体
 *   平移过去，所以 layoutTo() 里定位子元素时一律写 `this.x + 局部偏移`。
 */
class LanguagePanel extends FlxSpriteGroup
{
	inline static var HIDDEN_ALPHA:Float = 0.0000001;

	/** 左栏（国旗列）宽 / 面板总宽 */
	inline static var LEFT_W:Float = 0.36;
	/** 左右栏之间的缝隙 / 面板总宽 */
	inline static var COL_GAP:Float = 0.05;
	/** 卡片之间的缝隙 / 卡片高 */
	inline static var CARD_GAP:Float = 0.22;
	/** 卡片高上限 / 面板可用高（语言少的时候别让卡片长得像广告牌） */
	inline static var CARD_H_MAX:Float = 0.25;

	public var langs:Array<String> = [];
	var cards:Array<LangCard> = [];

	var previewBg:Rect;
	var previewTitle:FlxText;
	var previewText:FlxText;

	/** 内容淡入淡出系数（0 = 完全隐去），由 OptionCata.setFade 驱动 */
	public var fade:Float = 1;

	var lastW:Float = -1;
	var lastH:Float = -1;

	/** 中文原文 —— 任何语言包没写 `langPreview` 时的兜底 */
	public static inline var FALLBACK_PREVIEW:String =
		'当你在设置中调整语言然后看这条消息的时候，你发现你成功设置了语言。于是你再次切换语言——哦不为什么看不懂了。';

	public function new(?dirs:Array<String>)
	{
		super(0, 0);

		langs = (dirs != null) ? dirs : OptionsState.instance.getLanguageList();
		build();
		refresh();
	}

	function build():Void
	{
		previewBg = new Rect(0, 0, 10, 10, 10, 10, 0xFFFFFF, 0.045);
		add(previewBg);

		previewTitle = new FlxText(0, 0, 0, '', 20);
		previewTitle.borderStyle = NONE;
		previewTitle.antialiasing = ClientPrefs.data.antialiasing;
		add(previewTitle);

		previewText = new FlxText(0, 0, 0, '', 20);
		previewText.borderStyle = NONE;
		previewText.antialiasing = ClientPrefs.data.antialiasing;
		previewText.wordWrap = true;
		add(previewText);

		for (d in langs)
		{
			var c:LangCard = new LangCard(d, this);
			add(c);
			cards.push(c);
		}
	}

	/**
	 * 换一份语言列表（`Ctrl+F10` 唤出隐藏的测试语言时用，见 OptionsState.toggleTestLanguage）。
	 *
	 * 卡片是按 `langs` 一次性建出来的，所以换列表＝**重建卡片**；
	 * 建好后把 lastW/lastH 作废，等下一帧 `update()` 重新排布。
	 */
	public function setLangs(list:Array<String>):Void
	{
		if (list == null) return;
		langs = list;

		for (c in cards)
		{
			remove(c, true);
			c.destroy();
		}
		cards = [];

		for (d in langs)
		{
			var c:LangCard = new LangCard(d, this);
			add(c);
			cards.push(c);
		}

		lastW = -1;
		lastH = -1;
		refresh();
	}

	///////////////////////////////////////////////////////////////////////////////
	// 排布
	///////////////////////////////////////////////////////////////////////////////

	/**
	 * 按面板可用尺寸重排。由 OptionCata 在布局后调用（每帧比对尺寸，变了才重排）。
	 *
	 * ★ 返回 Bool：这一趟**真的重排了**吗（用来决定要不要让 OptionsState 重裁，
	 *   见 OptionsState.reclipContent —— 子元素挪过位置旧的 clipRect 就过期了）。
	 */
	public function layoutTo(w:Float, h:Float):Bool
	{
		if (w <= 8 || h <= 8) return false;
		if (Math.abs(w - lastW) < 0.5 && Math.abs(h - lastH) < 0.5) return false;
		lastW = w;
		lastH = h;

		var ox:Float = x;
		var oy:Float = y;

		var lw:Float = w * LEFT_W;
		var rx:Float = ox + lw + w * COL_GAP;
		var rw:Float = w - lw - w * COL_GAP;

		// ── 左栏：国旗卡片竖排 ───────────────────────────────────────────
		var n:Int = cards.length;
		if (n > 0)
		{
			var chMax:Float = h * CARD_H_MAX;
			var chByFill:Float = (h - chMax * CARD_GAP * (n - 1)) / n;
			var ch:Float = Math.min(chMax, chByFill);
			if (ch < 8) ch = 8;
			var gap:Float = ch * CARD_GAP;
			var total:Float = ch * n + gap * (n - 1);
			var cy:Float = oy + (h - total) / 2;

			for (i in 0...n)
			{
				cards[i].layoutTo(ox, cy, lw, ch);
				cy += ch + gap;
			}
		}

		// ── 右栏：示例文本 ──────────────────────────────────────────────
		var pad:Float = Math.max(12, rw * 0.06);
		var tx:Float = rx + pad;
		var tw:Float = Math.max(40, rw - pad * 2);

		previewTitle.x = tx;
		previewTitle.y = oy + pad * 0.9;

		previewText.x = tx;
		previewText.fieldWidth = tw;
		previewText.y = previewTitle.y + previewTitle.height + pad * 0.5;

		previewBg.x = rx;
		previewBg.y = oy;
		previewBg.scale.x = Math.max(0.05, rw / previewBg.frameWidth);
		previewBg.scale.y = Math.max(0.05, h / previewBg.frameHeight);
		previewBg.updateHitbox();
		return true;
	}

	///////////////////////////////////////////////////////////////////////////////
	// 选中态 / 预览文案 / 淡入淡出
	///////////////////////////////////////////////////////////////////////////////

	/**
	 * 整块内容的淡入淡出。**必须参与** —— 模式切换 / 关面板时会先把内容淡掉再重排，
	 * 本面板不跟着淡的话会孤零零地留在屏幕上（其它内容都没了，它还整块亮着）。
	 *
	 * ★ 同样不能改 group 自己的 alpha（FlxSpriteGroup.alpha 是乘法且会把 alpha==0
	 *   的子元素写成 1/比例，见 OptionCata.setFade 的注释）；这里驱动一个标量，
	 *   各子元素按自己的**基准值 × 标量**记，永远不越界。
	 */
	public function setFade(v:Float):Void
	{
		fade = v;
		// 不通过 rightFade() 做补间的那几个（标题 / 正文 / 底板）得手动写回去
		previewBg.alpha = 0.045 * v;
		previewTitle.alpha = v;
		previewText.alpha = v;
		// 卡片的 alpha 是在 LangCard.update 里每帧算的，那里乘这个标量即可
	}

	/** 重新把「当前语言」的选中态和右侧预览文本刷一遍 */
	public function refresh():Void
	{
		var cur:String = ClientPrefs.data.language;
		for (c in cards) c.setChosen(c.dir == cur);

		previewTitle.text = OptionsState.instance.getLanguageLabel(cur);
		previewText.text = previewOf(cur);

		// 字体：**用被预览的那个语言自己的字体** —— 这才是这个面板的意义。
		// （含 CJK 时 getLanguageFont 会自动挑 Lang-ZH，见 FontFallback）
		var f:String = Paths.font(OptionsState.instance.getLanguageFont(cur) + '.ttf');
		previewTitle.setFormat(f, previewTitle.size, 0xFFFFFF, LEFT);
		previewTitle.borderStyle = NONE;
		previewText.setFormat(f, previewText.size, 0xD8DCF0, LEFT);
		previewText.borderStyle = NONE;

		// 换过字体/换过文本 → 上一帧量的尺寸失效，强制重排一次
		lastW = -1;
		lastH = -1;
	}

	/** 某个语言的示例文本：读它自己 `main/main.lang` 里的 `langPreview`，没有就用中文原文 */
	public function previewOf(dir:String):String
	{
		var s:String = OptionsState.instance.getLanguagePreview(dir);
		return (s != null && s.length > 0) ? s : FALLBACK_PREVIEW;
	}

	/**
	 * 每帧拿「内容可视区」的尺寸对齐一次。
	 *
	 * ★ 为什么放在每帧而不是一次性布局：面板几何是**动画**出来的
	 *   （竖/横切换、展开收起都是一串补间），本面板拿不到"布局完成"的回调；
	 *   layoutTo 内部会比对尺寸，没变就立刻返回，所以空转成本只有一次比较。
	 *   面板还没展开时 contentAreaH() 会返回一个很小的值，layoutTo 直接跳过。
	 */
	override function update(elapsed:Float):Void
	{
		super.update(elapsed);
		var st:OptionsState = OptionsState.instance;
		if (st == null) return;

		// ★★ 位置不能用 this.x / this.y ★★
		//   FlxSpriteGroup 的子元素存的是**加入那一刻**的绝对坐标（preAdd 里 `sprite.x += x`），
		//   父容器（OptionCata）后来怎么动都不会带着它走。
		//   于是这块面板会永远停在 addCata 里那个初始位置上 —— 竖向看着还行，
		//   一切到横向（面板摊开、内容在面板里居中）就整体偏出 77px。
		//   所以每帧从 OptionsState 拿「内容可视区」的真实原点。
		var nx:Float = st.contentAreaX();
		var ny:Float = st.contentAreaTop();
		var moved:Bool = (Math.abs(nx - x) > 0.5 || Math.abs(ny - y) > 0.5);
		x = nx;
		y = ny;

		var did:Bool = layoutTo(st.contentAreaW(), st.contentAreaH());
		// 子元素被挪过 → 之前递归下去的那份 clipRect 已经指着别的地方了，作废重裁
		if (did || moved) st.reclipContent();
	}
}

///////////////////////////////////////////////////////////////////////////////

/** 语言面板里的一张「国旗卡片」 */
class LangCard extends FlxSpriteGroup
{
	inline static var HIDDEN_ALPHA:Float = 0.0000001;

	public var dir:String;

	var bg:Rect;
	var spec:Rect;
	var flag:FlxSprite;
	var nameText:FlxText;

	var follow:LanguagePanel;
	var chosen:Bool = false;
	var onFocus:Bool = false;

	public function new(dir:String, follow:LanguagePanel)
	{
		super(0, 0);
		this.dir = dir;
		this.follow = follow;

		bg = new Rect(0, 0, 10, 10, 10, 10, 0xFFFFFF, 0.05);
		add(bg);

		// 选中强调条：贴在卡片左边（和侧边栏 NaviMember 的 specRect 同一套语言）
		spec = new Rect(0, 0, 3, 10, 0, 0, EngineSet.mainColor);
		spec.alpha = 0;
		add(spec);

		flag = new FlxSprite();
		var g:FlxGraphic = null;
		try
		{
			g = Paths.image('menuExtendHide/option/nation/' + dir);
		}
		catch (e:Dynamic) {}
		if (g != null) flag.loadGraphic(g);
		flag.antialiasing = ClientPrefs.data.antialiasing;
		add(flag);
		flag.visible = (g != null);

		nameText = new FlxText(0, 0, 0, OptionsState.instance.getLanguageLabel(dir), 14);
		nameText.setFormat(Paths.font(OptionsState.instance.getLanguageFont(dir) + '.ttf'), 14, FlxColor.WHITE, CENTER);
		nameText.borderStyle = NONE;
		nameText.antialiasing = ClientPrefs.data.antialiasing;
		add(nameText);
	}

	public function layoutTo(ox:Float, oy:Float, w:Float, h:Float):Void
	{
		bg.x = ox;
		bg.y = oy;
		bg.scale.x = Math.max(0.05, w / bg.frameWidth);
		bg.scale.y = Math.max(0.05, h / bg.frameHeight);
		bg.updateHitbox();

		spec.x = ox;
		spec.y = oy;
		spec.scale.y = Math.max(0.05, h / spec.frameHeight);
		spec.updateHitbox();

		// 文字先量一遍：字号跟着卡片高走，但**不能超过卡片宽**（"Português (Brasil)" 很长）。
		// ★ 量宽度用 `textField.textWidth` 而不是 `nameText.width`：FlxText 的 width 来自
		//   它那张贴图，要等 regenGraphic() 跑过才更新，而 setFormat 之后同一帧读到的是旧值。
		var fs:Int = Std.int(Math.max(9, h * 0.2));
		var font:String = Paths.font(OptionsState.instance.getLanguageFont(dir) + '.ttf');
		while (fs > 8)
		{
			nameText.setFormat(font, fs, FlxColor.WHITE, CENTER);
			nameText.borderStyle = NONE;
			if (nameText.textField.textWidth <= w * 0.92) break;
			fs--;
		}

		var pad:Float = h * 0.12;
		var nameH:Float = Math.max(fs * 1.35, nameText.textField.textHeight);
		var flagH:Float = Math.max(6, h - pad * 2 - nameH - h * 0.08);
		var flagW:Float = w * 0.74;

		if (flag.visible)
		{
			var sc:Float = Math.min(flagW / flag.frameWidth, flagH / flag.frameHeight);
			flag.scale.set(sc, sc);
			flag.updateHitbox();
			flag.x = ox + (w - flag.width) / 2;
			flag.y = oy + pad;
		}

		nameText.x = ox + (w - nameText.textField.textWidth) / 2;
		nameText.y = oy + pad + flagH + h * 0.08;
	}

	public function setChosen(v:Bool):Void
	{
		chosen = v;
	}

	override function update(elapsed:Float):Void
	{
		super.update(elapsed);

		// ★★ 国旗必须把「继承来的 clipRect」摘掉（用户报的"国旗显示不全"）★★
		//   FlxSpriteGroup 的 clipRect 会递归传给子元素，但换算公式
		//     child.clipRect = (ClipRect.x - child.x + group.x, …, ClipRect.width, ClipRect.height)
		//   **既没除缩放比、也没乘缩放比**（flixel/group/FlxSpriteGroup.hx 的
		//   clipRectTransform 一共就一行）。而 clipRect 的语义是「未缩放的帧像素」
		//   （FlxSprite.set_frame → FlxFrame.clipTo）。
		//   于是：放大的精灵（Rect 那种 10×10 拉成大板的）无所谓 —— 裁剪框比帧还大，
		//   交集就是整帧；但**缩小的精灵会被按比例切掉**：
		//   国旗是 2560px 的素材缩到 ~90px 显示（scale≈0.035），
		//   传下来的 921px 裁剪框进到帧坐标系里只覆盖 2560 的 36%，
		//   再乘上 0.035 → 屏幕上只剩左上角一小块，正是"国旗显示不全"。
		//   国旗不参与滚动、也永远在可视区内，直接不给它裁。
		if (flag != null && flag.clipRect != null) flag.clipRect = null;

		var fd:Float = follow.fade;
		if (flag != null) flag.alpha = fd;
		if (nameText != null) nameText.alpha = fd;

		var mouse:MouseEvent = OptionsState.instance.mouseEvent;
		onFocus = (mouse != null) && mouse.overlaps(bg);

		var want:Float = (chosen ? 1 : (onFocus ? 0.55 : 0)) * fd;
		spec.alpha += (want - spec.alpha) * EngineSet.FPSfix(0.2);
		if (spec.alpha < 0.01 && want == 0) spec.alpha = 0;
		spec.visible = spec.alpha > 0.01;

		var bgWant:Float = (chosen ? 0.16 : (onFocus ? 0.1 : 0.05)) * fd;
		bg.alpha += (bgWant - bg.alpha) * EngineSet.FPSfix(0.2);
		bg.visible = bg.alpha > 0.004;

		if (onFocus && mouse != null && mouse.justReleased) OptionsState.instance.requestLanguage(dir);
	}
}
