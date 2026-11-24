package general.shaders;

import openfl.filters.ColorMatrixFilter;
import openfl.filters.BitmapFilter;
import openfl.filters.ShaderFilter;

import flixel.graphics.tile.FlxGraphicsShader;
import flixel.system.FlxAssets.FlxShader;

import options.OptionsHelpers;

class ColorblindFilter
{
	public static var matrix:Array<Float>;
	public static var colorM:Array<Float>;
	// Keep only our own filter replaceable; scripts may have installed others.
	private static var appliedFilter:ColorMatrixFilter;
	#if (windows && cpp && novaflare_filter_ablation)
	private static final keepDisabledFilter = Sys.getEnv("NOVAFLARE_KEEP_DISABLED_COLOR_FILTER") == "1";
	#end

	public static function UpdateColors(?input:Array<BitmapFilter> = null):Void
	{
		var mode = ClientPrefs.data.colorblindMode;
		var a1:Float = 1;
		var a2:Float = 0;
		var a3:Float = 0;

		var b1:Float = 0;
		var b2:Float = 1;
		var b3:Float = 0;

		var c1:Float = 0;
		var c2:Float = 0;
		var c3:Float = 1;

		switch (mode)
		{
			case 'None':
				a1 = 1;
				b1 = 0;
				c1 = 0;
				a2 = 0;
				b2 = 1;
				c2 = 0;
				a3 = 0;
				b3 = 0;
				c3 = 1;
			case 'Protanopia':
				trace('Protanopia filter');
				a1 = 0.567;
				b1 = 0.433;
				c1 = 0;
				a2 = 0.558;
				b2 = 0.442;
				c2 = 0;
				a3 = 0;
				b3 = 0.242;
				c3 = 0.758;
			case 'Protanomaly':
				trace('Protanomaly filter');
				a1 = 0.817;
				b1 = 0.183;
				c1 = 0;
				a2 = 0.333;
				b2 = 0.667;
				c2 = 0;
				a3 = 0;
				b3 = 0.125;
				c3 = 0.875;
			case 'Deuteranopia':
				trace('Deuteranopia filter');
				a1 = 0.625;
				b1 = 0.375;
				c1 = 0;
				a2 = 0.7;
				b2 = 0.3;
				c2 = 0;
				a3 = 0;
				b3 = 0;
				c3 = 1.0;
			case 'Deuteranomaly':
				trace('Deuteranomaly filter');
				a1 = 0.8;
				b1 = 0.2;
				c1 = 0;
				a2 = 0.258;
				b2 = 0.742;
				c2 = 0;
				a3 = 0;
				b3 = 0.142;
				c3 = 0.858;
			case 'Tritanopia':
				trace('Tritanopia filter');
				a1 = 0.95;
				b1 = 0.05;
				c1 = 0;
				a2 = 0;
				b2 = 0.433;
				c2 = 0.567;
				a3 = 0;
				b3 = 0.475;
				c3 = 0.525;
			case 'Tritanomaly':
				trace('Tritanomaly filter');
				a1 = 0.967;
				b1 = 0.033;
				c1 = 0;
				a2 = 0;
				b2 = 0.733;
				c2 = 0.267;
				a3 = 0;
				b3 = 0.183;
				c3 = 0.817;
			case 'Achromatopsia':
				trace('Achromatopsia filter');
				a1 = 0.299;
				b1 = 0.587;
				c1 = 0.114;
				a2 = 0.299;
				b2 = 0.587;
				c2 = 0.114;
				a3 = 0.299;
				b3 = 0.587;
				c3 = 0.114;
			case 'Achromatomaly':
				trace('Achromatomaly filter');
				a1 = 0.618;
				b1 = 0.320;
				c1 = 0.062;
				a2 = 0.163;
				b2 = 0.775;
				c2 = 0.062;
				a3 = 0.163;
				b3 = 0.320;
				c3 = 0.516;
		}

		matrix = [
			a1 * 1, b1 * 1, c1 * 1, 0, 1,
			a2 * 1, b2 * 1, c2 * 1, 0, 1,
			a3 * 1, b3 * 1, c3 * 1, 0, 1,
			     0,      0,      0, 1, 0,
		];

		var applyFilter = mode != 'None';
		#if (windows && cpp && novaflare_filter_ablation)
		applyFilter = applyFilter || keepDisabledFilter;
		#end
		if (input != null)
		{
			if (applyFilter) input.push(new ColorMatrixFilter(matrix));
			return;
		}

		updateGameFilter(applyFilter);
	}

	private static function updateGameFilter(applyFilter:Bool):Void
	{
		if (!applyFilter && appliedFilter == null) return;

		// State/substate creation can run after mod onCreate/onCreatePost.
		// Only the filter installed by this class may be replaced or removed.
		var game = FlxG.game;
		@:privateAccess
		var current:Array<BitmapFilter> = game._filters;
		if (!applyFilter && (current == null || current.indexOf(appliedFilter) == -1))
		{
			appliedFilter = null;
			return;
		}

		var filters = current == null ? [] : current.copy();
		if (appliedFilter != null) filters.remove(appliedFilter);
		appliedFilter = null;
		if (applyFilter)
		{
			appliedFilter = new ColorMatrixFilter(matrix);
			filters.push(appliedFilter);
			game.filtersEnabled = true;
		}
		game.setFilters(filters);
	}
}
