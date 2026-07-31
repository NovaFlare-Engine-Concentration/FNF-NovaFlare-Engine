package animate.internal.filters;

import flixel.math.FlxMath;
import openfl.filters.ColorMatrixFilter;

class AdjustColorFilter
{
	public var filter:ColorMatrixFilter;

	public function new()
	{
		filter = new ColorMatrixFilter();
	}

	public inline function set(brightness:Float, hue:Float, contrast:Float, saturation:Float)
	{
		filter.matrix = getColorMatrix(brightness, hue, contrast, saturation);
	}

	static function getColorMatrix(brightness:Float, hue:Float, contrast:Float, saturation:Float):Array<Float>
	{
		var b:Float = brightness;
		var h:Float = hue * Math.PI / 180;
		var c:Float = contrast / 100 + 1;
		var s:Float = saturation / 100 + 1;

		var lumR:Float = 0.3086;
		var lumG:Float = 0.6094;
		var lumB:Float = 0.0820;

		var cosH:Float = FlxMath.fastCos(h);
		var sinH:Float = FlxMath.fastSin(h);

		var hMat:Array<Float> = [
			   lumR + cosH * (1 - lumR) + sinH * (-lumR),    lumG + cosH * (-lumG) + sinH * (-lumG), lumB + cosH * (-lumB) + sinH * (1 - lumB), 0, 0,
			      lumR + cosH * (-lumR) + sinH * (0.143), lumG + cosH * (1 - lumG) + sinH * (0.140),   lumB + cosH * (-lumB) + sinH * (-0.283), 0, 0,
			lumR + cosH * (-lumR) + sinH * (-(1 - lumR)),     lumG + cosH * (-lumG) + sinH * (lumG),  lumB + cosH * (1 - lumB) + sinH * (lumB), 0, 0,
			                                           0,                                         0,                                         0, 1, 0
		];

		var sMat:Array<Float> = [
			lumR * (1 - s) + s,     lumG * (1 - s),     lumB * (1 - s), 0, 0,
			    lumR * (1 - s), lumG * (1 - s) + s,     lumB * (1 - s), 0, 0,
			    lumR * (1 - s),     lumG * (1 - s), lumB * (1 - s) + s, 0, 0,
			                 0,                  0,                  0, 1, 0
		];

		var cMat:Array<Float> = [
			c, 0, 0, 0, 128 * (1 - c),
			0, c, 0, 0, 128 * (1 - c),
			0, 0, c, 0, 128 * (1 - c),
			0, 0, 0, 1,             0
		];

		var bMat:Array<Float> = [
			1, 0, 0, 0, b,
			0, 1, 0, 0, b,
			0, 0, 1, 0, b,
			0, 0, 0, 1, 0
		];

		return multiplyMatrices(multiplyMatrices(multiplyMatrices(bMat, cMat), sMat), hMat);
	}

	static function multiplyMatrices(a:Array<Float>, b:Array<Float>):Array<Float>
	{
		var result:Array<Float> = [];
		for (i in 0...4)
		{
			for (j in 0...5)
			{
				result[i * 5 + j] = a[i * 5] * b[j]
					+ a[i * 5 + 1] * b[j + 5] + a[i * 5 + 2] * b[j + 10] + a[i * 5 + 3] * b[j + 15] + (j == 4 ? a[i * 5 + 4] : 0);
			}
		}
		return result;
	}
}
