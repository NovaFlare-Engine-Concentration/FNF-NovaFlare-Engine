package general.shapeEx;

import flixel.graphics.FlxGraphic;
import openfl.display.BitmapData;

/**
 * web 原型里的 `#panel` / `.slab`：一整块磨砂平板（**直角**，带可选 1px 边线）。
 *
 * ══════════════════════════════════════════════════════════════════════════
 *  为什么不再用 RoundRect（「切换时边框割裂」的根因）
 * ══════════════════════════════════════════════════════════════════════════
 *  RoundRect 是「4 个圆角 sprite + 3 段中间块 sprite」拼出来的 9-slice：
 *    · 改宽度 → 中间块靠 `scale.x` 拉伸 + 两个圆角靠 `setX` 挪位
 *    · 改高度 → 中段靠 `scale.y` 拉伸 + 下排靠 `setY` 挪位
 *  动画期间目标尺寸是**小数**（补间每帧算出来的），于是拼接处落在非整数像素上：
 *  相邻两块各自只覆盖边缘像素的一部分 → 之间露出 1px 的缝；圆角与直边的接缝
 *  还会因为取整方向不同而错开。竖栏/横栏切换、一级/二级菜单切换时面板尺寸一直在变，
 *  所以缝一直在动 —— 看上去就是「边框被割裂」。
 *
 *  web 那边一个 `<div>` + `border` 永远不会这样，因为它是**一个**元素、一条边。
 *
 *  这里就照这个思路：一个「纯色 quad」（1×1 白贴图按 scale 铺开）当整块板，
 *  边线是独立的 1×1 quad。所以：
 *    · 主体只有一个 quad —— 不存在任何拼接，结构上不可能有缝
 *    · setRect 对坐标/尺寸**取整** —— 边线落在整像素上，不会半透明
 *    · 面板/两条栏的背景从 8+8+8=24 个 sprite 降到 2/2/2 个，draw call 也少了
 * ══════════════════════════════════════════════════════════════════════════
 */
class Slab extends FlxSpriteGroup
{
	/** 玻璃底（主体） */
	var body:FlxSprite;
	/** 边线：web 原型里 #panel 的 inset 顶边、#sideV 的 border-right、#sideH 的 border-bottom */
	var edges:Array<FlxSprite> = [];
	/** 边线相对主体的 alpha 比例（主体淡出时边线跟着等比淡出） */
	var edgeRatio:Float = 0;
	/** 主体的「材质」不透明度基准值（setAlpha 的 1 倍） */
	public var baseAlpha(default, null):Float = 1;

	public function new(color:FlxColor, alpha:Float, ?edgeColor:FlxColor = 0xFFFFFF, edgeAlpha:Float = 0,
		edgeTop:Bool = false, edgeBottom:Bool = false, edgeLeft:Bool = false, edgeRight:Bool = false)
	{
		super(0, 0);

		baseAlpha = alpha;
		body = gradientQuad(color, alpha);
		add(body);

		if (edgeAlpha > 0)
		{
			edgeRatio = edgeAlpha / alpha;
			if (edgeTop) addEdge(quad(edgeColor, edgeAlpha));
			if (edgeBottom) addEdge(quad(edgeColor, edgeAlpha));
			if (edgeLeft) addEdge(quad(edgeColor, edgeAlpha));
			if (edgeRight) addEdge(quad(edgeColor, edgeAlpha));
		}
	}

	function addEdge(s:FlxSprite):Void
	{
		edges.push(s);
		add(s);
	}

	/**
	 * 取「共享的静态贴图」，但如果它被销毁了就重建。
	 *
	 * ★★ 为什么必须判 isDestroyed ★★
	 *   gradGfx / whiteGfx 是用 `FlxGraphic.fromBitmapData()` 自己建的，**不在
	 *   Paths 的 tracked-assets 名单里**。而 `Paths.clearStoredMemory()` 会把所有
	 *   不在名单里的缓存贴图交给 `releaseGraphicWhenUnused()`：那个函数会
	 *   **强行把 persist 清掉**（`graphic.persist = false`）并设
	 *   `destroyOnNoUse = true`。于是：
	 *     · 第 1 次进设置：贴图刚建、引用有效 → 一切正常
	 *     · 离开设置（旧状态销毁 → useCount 归 0）→ 贴图**被销毁**
	 *     · 第 2 次进设置：`if (xxx == null)` 只看引用、不看是否已销毁 →
	 *       **复用一个已销毁的贴图** → 所有玻璃板退化成空白/极小贴图，
	 *       整屏发灰发绿、低分辨率（用户报的「二次进入变糊」的根因）
	 *   `persist = true` 挡不住这条路（会被 overwrite），所以必须显式重建。
	 */
	inline static function gfxAlive(g:FlxGraphic):Bool
		return g != null && !g.isDestroyed && g.bitmap != null;

	/** 1×1 白贴图（全 Slab 共用）：边线用，靠 color 染色 */
	static var whiteGfx:FlxGraphic = null;

	static function whiteQuadGfx():FlxGraphic
	{
		if (!gfxAlive(whiteGfx))
		{
			var bmd = new BitmapData(1, 1, true, 0xFFFFFFFF);
			whiteGfx = FlxGraphic.fromBitmapData(bmd, true);
			whiteGfx.persist = true;
		}
		return whiteGfx;
	}

	/** 1×1 白贴图 + color 染色 = 一个纯色矩形，靠 scale 铺成任意尺寸 */
	static function quad(color:FlxColor, alpha:Float):FlxSprite
	{
		var s = new FlxSprite();
		s.loadGraphic(whiteQuadGfx());
		s.color = color;
		s.alpha = alpha;
		s.antialiasing = false;   // 纯色块/1px 线不需要抗锯齿，关掉边缘更实
		return s;
	}

	///////////////////////////////////////////////////////////////////////////////
	// 玻璃底的竖向渐变
	///////////////////////////////////////////////////////////////////////////////

	/**
	 * web 原型的玻璃底是**竖向渐变**而不是纯色：
	 *   `.slab  { background:linear-gradient(180deg, rgba(41,40,52,.60), rgba(24,23,31,.70)) }`
	 *   `#panel { background:linear-gradient(158deg, rgba(44,43,56,.64), rgba(23,22,30,.74)) }`
	 * 上浅下深 —— 这是"玻璃有厚度"的关键，纯色平板看起来就是一块塑料。
	 *
	 * 这里把渐变烘焙进一张 1×N 的贴图（alpha 从 0.86 线性涨到 1.0，
	 * 相对量正好是原型的 .60→.70 / .64→.74），再用 color 染色、用 alpha 统一控制。
	 * 贴图全 Slab 共用（被引擎清缓存销毁时会自动重建，见 gfxAlive）。
	 */
	inline static var GRAD_STEPS:Int = 64;
	/** 顶部相对底部的 alpha 比例（.60/.70 = 0.857） */
	inline static var GRAD_TOP:Float = 0.86;

	static var gradGfx:FlxGraphic = null;

	static function gradientQuad(color:FlxColor, alpha:Float):FlxSprite
	{
		// ★ 见 gfxAlive() 的注释：不能只判 null，必须判「是否已被销毁」
		if (!gfxAlive(gradGfx))
		{
			var bmd = new BitmapData(1, GRAD_STEPS, true, 0);
			for (y in 0...GRAD_STEPS)
			{
				var t:Float = GRAD_STEPS > 1 ? y / (GRAD_STEPS - 1) : 0;
				var a:Int = Std.int(Math.round(255 * (GRAD_TOP + (1 - GRAD_TOP) * t)));
				bmd.setPixel32(0, y, (a << 24) | 0xFFFFFF);
			}
			gradGfx = FlxGraphic.fromBitmapData(bmd, true);
			gradGfx.persist = true;
		}

		var s = new FlxSprite();
		s.loadGraphic(gradGfx);
		s.color = color;
		s.alpha = alpha;
		s.antialiasing = false;
		return s;
	}

	/**
	 * 摆到 (x, y)、尺寸 (w, h)。坐标与尺寸一律取整（floor），
	 * 半像素是「边缘/1px 线看起来发虚、发脏」的另一个来源。
	 *
	 * ★ 每次都无条件写入（不做「值没变就跳过」的优化）：因为调用方
	 *   （NaviGroup.setOff）会把整条栏的子元素整体平移，缓存的值会和实际
	 *   渲染位置脱节；这里写的是绝对坐标，直接覆盖才不会漂。
	 */
	public function setRect(x:Float, y:Float, w:Float, h:Float):Void
	{
		var ix:Float = Math.floor(x);
		var iy:Float = Math.floor(y);
		var iw:Float = Math.max(1, Math.floor(w));
		var ih:Float = Math.max(1, Math.floor(h));

		place(body, ix, iy, iw, ih);

		var n:Int = edges.length;
		// 顺序：top / bottom / left / right（只创建需要的那些）
		if (n > 0) place(edges[0], ix, iy, iw, 1);
		if (n > 1) place(edges[1], ix, iy + ih - 1, iw, 1);
		if (n > 2) place(edges[2], ix, iy, 1, ih);
		if (n > 3) place(edges[3], ix + iw - 1, iy, 1, ih);
	}

	/**
	 * 摆到 (x, y)、尺寸 (w, h)。
	 *
	 * ★★ 必须 updateHitbox() ★★ —— FlxSprite 的缩放是**以 origin 为锚点**的，
	 *   而 makeGraphic() 把 origin 留在了贴图中心（1×1 贴图 → (0.5, 0.5)）。
	 *   只写 scale 不更新 hitbox 的话，这个 quad 会「从中心放大」：
	 *   面板/侧边栏会被整个推向左上半个身位 —— 屏幕上只剩右下四分之一
	 *   （108×360 而不是 217×720、640 宽而不是 1280 宽的顶栏）。
	 *   updateHitbox() 会把 offset 补成 -0.5*(w-1)、origin 归到中心，
	 *   两者相抵正好把左上角钉回 (x, y)（flixel 自己的 makeSolid() 就是这么做的）。
	 */
	inline function place(s:FlxSprite, x:Float, y:Float, w:Float, h:Float):Void
	{
		s.setPosition(x, y);
		// ★ scale 是乘在**贴图尺寸**上的，所以必须除掉帧本身的宽高。
		//   边线用的是 1×1 quad（帧就是 1×1），而主体现在是一张 1×64 的竖向
		//   渐变贴图 —— 直接写 scale.set(w, h) 会把它拉成 1 宽的 w × 64h。
		s.scale.set(w / Math.max(1, s.frameWidth), h / Math.max(1, s.frameHeight));
		s.updateHitbox();
	}

	/**
	 * 玻璃底的不透明度（绝对值，读法沿用原来 `panelBG.alpha`）。
	 * 写的时候边线按比例跟随，所以整体淡出时 1px 边线不会「留一条白边」。
	 */
	public var glassAlpha(get, set):Float;

	inline function get_glassAlpha():Float return body.alpha;

	function set_glassAlpha(v:Float):Float
	{
		body.alpha = v;
		if (edges.length > 0)
		{
			var e:Float = v * edgeRatio;
			for (s in edges) s.alpha = e;
		}
		return v;
	}

}
