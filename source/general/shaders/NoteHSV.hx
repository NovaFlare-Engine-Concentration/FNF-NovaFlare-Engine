package general.shaders;

import flixel.FlxSprite;

/**
 * legacy 音符贴图的 HSV 着色入口。
 *
 * 每条轨道共用一份 ColorSwap：arrowHSV 是全局偏好，同轨的 note / strum / splash 参数完全一致。
 * 共享实例和 Note.globalRgbShaders 一个思路 —— 否则一张 16K 谱要几百个 Shader 实例。
 * 参数全 0 时 apply() 直接返回 false（连 shader 都不挂），所以 legacy 皮肤默认就等于原图。
 */
class NoteHSV
{
	static var palettes:Array<ColorSwap> = [];

	public static function hasValues(lane:Int):Bool
	{
		var v:Array<Float> = valuesOf(lane);
		return v != null && (v[0] != 0 || v[1] != 0 || v[2] != 0);
	}

	/** 取该轨道的调色板（懒建）。参数全 0 也照样返回，供编辑器预览。 */
	public static function get(lane:Int):ColorSwap
	{
		var idx:Int = indexOf(lane);
		var palette:ColorSwap = palettes[idx];
		if (palette == null)
		{
			palette = new ColorSwap();
			palettes[idx] = palette;
		}

		var v:Array<Float> = valuesOf(idx);
		if (v != null)
		{
			palette.hue = v[0] / 360;
			palette.saturation = v[1] / 100;
			palette.brightness = v[2] / 100;
		}
		return palette;
	}

	/** 给 sprite 挂上该轨道的 HSV shader；参数全 0 时不动 sprite、返回 false。 */
	public static function apply(sprite:FlxSprite, lane:Int):Bool
	{
		if (sprite == null || !hasValues(lane)) return false;
		sprite.shader = get(lane).shader;
		return true;
	}

	/** 参数改动后把值重新推给已建好的调色板 —— 共享实例，引用它的 sprite 会立刻跟着变。 */
	public static function refresh():Void
	{
		for (i in 0...palettes.length)
			if (palettes[i] != null) get(i);
	}

	static function indexOf(lane:Int):Int
	{
		var len:Int = ClientPrefs.data.arrowHSV == null ? 0 : ClientPrefs.data.arrowHSV.length;
		if (len < 1) return 0;
		var idx:Int = lane % len;
		if (idx < 0) idx += len;
		return idx;
	}

	static function valuesOf(lane:Int):Array<Float>
	{
		var arr:Array<Array<Float>> = ClientPrefs.data.arrowHSV;
		if (arr == null || arr.length < 1) return null;
		var idx:Int = lane % arr.length;
		if (idx < 0) idx += arr.length;
		return arr[idx];
	}
}
