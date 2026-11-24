package general.backend;

import lime.system.System;
import openfl.display.Stage;

private typedef ResolutionBounds = {
	final label:String;
	final width:Int;
	final height:Int;
}

class RenderResolution
{
	static final presets:Array<ResolutionBounds> = [
		{label: '360P', width: 640, height: 360},
		{label: '480P', width: 854, height: 480},
		{label: '540P', width: 960, height: 540},
		{label: '720P', width: 1280, height: 720},
		{label: '768P', width: 1366, height: 768},
		{label: '900P', width: 1600, height: 900},
		{label: '1080P', width: 1920, height: 1080},
		{label: '1440P (2K)', width: 2560, height: 1440},
		{label: '1600P', width: 2560, height: 1600},
		{label: '1800P', width: 3200, height: 1800},
		{label: '2160P (4K)', width: 3840, height: 2160}
	];
	static final nativeBounds:ResolutionBounds = {label: 'Native', width: 0, height: 0};

	public static function choices():Array<String>
	{
		var display = System.getDisplay(0);
		var maximumPixels = display == null ? 0 : display.bounds.width * display.bounds.height;
		var labels = [for (preset in presets) if (preset.width * preset.height <= maximumPixels) preset.label];
		labels.push('Native');
		return labels;
	}

	public static function normalize(value:String):String
	{
		return findPreset(value).label;
	}

	public static function configureStage(stage:Stage):Void
	{
		#if nova_stage_render_target
		#if mobile
		var display = System.getDisplay(0);
		if (display != null && display.bounds.width > 0 && display.bounds.height > 0)
		{
			stage.setLogicalSize(Std.int(display.bounds.width), Std.int(display.bounds.height));
			return;
		}
		#end
		stage.setLogicalSize(1280, 720);
		#end
	}

	public static function apply(stage:Stage, savedPreset:String):Void
	{
		var selected = findPreset(savedPreset);
		#if nova_stage_render_target
		#if sys
		var overrideValue = Sys.getEnv('NOVAFLARE_RENDER_RESOLUTION');
		if (overrideValue != null)
		{
			var dimensions = ~/^([1-9][0-9]{0,3})[xX]([1-9][0-9]{0,3})$/;
			if (dimensions.match(overrideValue))
				selected = {label: overrideValue, width: Std.parseInt(dimensions.matched(1)), height: Std.parseInt(dimensions.matched(2))};
			else if (overrideValue.toLowerCase() == 'native')
				selected = nativeBounds;
			else
			{
				var overridePreset = findPreset(overrideValue);
				if (overridePreset != nativeBounds) selected = overridePreset;
			}
		}
		#end
		var trace = #if (android && novaflare_render_target_trace)
			true;
		#elseif sys
			Sys.getEnv('NOVAFLARE_FRAME_TIMELINE') != null || Sys.getEnv('NOVAFLARE_RENDER_TARGET_TRACE') == '1';
		#else
			false;
		#end
		stage.setRenderResolution(selected.width, selected.height, trace);
		#else
		if (selected != nativeBounds)
		{
			stage.setLogicalSize(selected.width, selected.height);
			return;
		}
		var display = System.getDisplay(0);
		if (display != null && display.bounds.width > 0 && display.bounds.height > 0)
			stage.setLogicalSize(Std.int(display.bounds.width), Std.int(display.bounds.height));
		else
			stage.setLogicalSize(1280, 720);
		#end
	}

	static function findPreset(value:String):ResolutionBounds
	{
		for (preset in presets)
			if (preset.label == value) return preset;
		return nativeBounds;
	}
}
