package animate.internal.filters;

import openfl.display.BitmapData;
import openfl.filters.BlurFilter;
import openfl.geom.Point;

#if lime
class StackBlur
{
	public static function applyFilter(bitmap:BitmapData, filter:BlurFilter, point:Point)
	{
		#if (web && html5)
		@:privateAccess
		lime._internal.graphics.ImageDataUtil.gaussianBlur(bitmap.image, bitmap.image, bitmap.rect.__toLimeRectangle(), point.__toLimeVector2(), filter.blurX,
			filter.blurY, filter.quality);
		#else
		blur(bitmap, filter.blurX, filter.blurY, filter.quality);
		#end
	}

	// TODO: do this with cpp bindings instead of haxe code
	public static function blur(bitmap:BitmapData, blurX:Float, blurY:Float, quality:Int)
	{
		@:privateAccess
		var MUL_TABLE = lime._internal.graphics.StackBlur.MUL_TABLE;
		@:privateAccess
		var SHG_TABLE = lime._internal.graphics.StackBlur.SHG_TABLE;

		var radiusX = Math.round(blurX) >> 1;
		var radiusY = Math.round(blurY) >> 1;

		if (MUL_TABLE == null)
			return; // can be null due to static initialization order
		if (radiusX >= MUL_TABLE.length)
			radiusX = MUL_TABLE.length - 1;
		if (radiusY >= MUL_TABLE.length)
			radiusY = MUL_TABLE.length - 1;
		if (radiusX < 0 || radiusY < 0)
			return;

		var iterations = quality;
		if (iterations < 1)
			iterations = 1;
		if (iterations > 3)
			iterations = 3;

		var px = bitmap.image.data;
		var y:Int, i:Int, p:Int, yp:Int, yi:Int, yw:Int;
		var r:Int, g:Int, b:Int, a:Int, pr:Int, pg:Int, pb:Int, pa:Int;

		var divx:Int = (radiusX + radiusX + 1);
		var divy:Int = (radiusY + radiusY + 1);
		var w:Int = bitmap.width;
		var h:Int = bitmap.height;

		var w1:Int = w - 1;
		var h1:Int = h - 1;
		var rxp1:Int = radiusX + 1;
		var ryp1:Int = radiusY + 1;

		var ssx = new BlurStack();
		var sx = ssx;
		for (i in 1...divx)
		{
			sx = sx.n = new BlurStack();
		}
		sx.n = ssx;

		var ssy = new BlurStack();
		var sy = ssy;
		for (i in 1...divy)
		{
			sy = sy.n = new BlurStack();
		}
		sy.n = ssy;

		var si = null;

		var mtx = MUL_TABLE[radiusX];
		var stx = SHG_TABLE[radiusX];
		var mty = MUL_TABLE[radiusY];
		var sty = SHG_TABLE[radiusY];

		while (iterations > 0)
		{
			iterations--;
			yw = yi = 0;
			var ms = mtx;
			var ss = stx;
			y = h;
			do
			{
				r = rxp1 * (pr = px[yi]);
				g = rxp1 * (pg = px[yi + 1]);
				b = rxp1 * (pb = px[yi + 2]);
				a = rxp1 * (pa = px[yi + 3]);
				sx = ssx;
				i = rxp1;
				do
				{
					sx.r = pr;
					sx.g = pg;
					sx.b = pb;
					sx.a = pa;
					sx = sx.n;
				}
				while (--i > -1);

				for (i in 1...rxp1)
				{
					p = yi + ((w1 < i ? w1 : i) << 2);
					r += (sx.r = px[p]);
					g += (sx.g = px[p + 1]);
					b += (sx.b = px[p + 2]);
					a += (sx.a = px[p + 3]);
					sx = sx.n;
				}

				si = ssx;
				for (x in 0...w)
				{
					px[yi] = (r * ms) >>> ss;
					px[yi + 1] = (g * ms) >>> ss;
					px[yi + 2] = (b * ms) >>> ss;
					px[yi + 3] = (a * ms) >>> ss;
					yi += 4;
					p = (yw + ((p = x + radiusX + 1) < w1 ? p : w1)) << 2;
					r -= si.r - (si.r = px[p]);
					g -= si.g - (si.g = px[p + 1]);
					b -= si.b - (si.b = px[p + 2]);
					a -= si.a - (si.a = px[p + 3]);
					si = si.n;
				}
				yw += w;
			}
			while (--y > 0);

			ms = mty;
			ss = sty;
			for (x in 0...w)
			{
				yi = x << 2;
				r = ryp1 * (pr = px[yi]);
				g = ryp1 * (pg = px[yi + 1]);
				b = ryp1 * (pb = px[yi + 2]);
				a = ryp1 * (pa = px[yi + 3]);
				sy = ssy;
				for (i in 0...ryp1)
				{
					sy.r = pr;
					sy.g = pg;
					sy.b = pb;
					sy.a = pa;
					sy = sy.n;
				}
				yp = w;
				for (i in 1...(radiusY + 1))
				{
					yi = (yp + x) << 2;
					r += (sy.r = px[yi]);
					g += (sy.g = px[yi + 1]);
					b += (sy.b = px[yi + 2]);
					a += (sy.a = px[yi + 3]);
					sy = sy.n;
					if (i < h1)
					{
						yp += w;
					}
				}
				yi = x;
				si = ssy;

				for (y in 0...h)
				{
					p = yi << 2;

					px[p] = (r * ms) >>> ss;
					px[p + 1] = (g * ms) >>> ss;
					px[p + 2] = (b * ms) >>> ss;
					px[p + 3] = (a * ms) >>> ss;

					p = (x + (((p = y + ryp1) < h1 ? p : h1) * w)) << 2;
					r -= si.r - (si.r = px[p]);
					g -= si.g - (si.g = px[p + 1]);
					b -= si.b - (si.b = px[p + 2]);
					a -= si.a - (si.a = px[p + 3]);
					si = si.n;
					yi += w;
				}
			}
		}
	}
}

@:unreflective
class BlurStack
{
	public var r:Int;
	public var g:Int;
	public var b:Int;
	public var a:Int;
	public var n:BlurStack;

	public function new()
	{
		this.r = 0;
		this.g = 0;
		this.b = 0;
		this.a = 0;
		this.n = null;
	}
}
#else
typedef StackBlur = Dynamic;
#end
