package options.groupData;

import lime.graphics.opengl.GL;
import general.shaders.ColorblindFilter;
import general.backend.RenderResolution;

#if mobile
import general.objects.screen.MouseEffect;
import general.shaders.MobileShaderConverter;
#end

class GeneralGroup extends OptionCata
{
	#if cpp
	private var vsyncOption:Option;
	private var previousVSync:Bool;
	#end

	public function new(X:Float, Y:Float, width:Float, height:Float)
	{
		super(X, Y, width, height);

		var option:Option = new Option(this, 'General', TITLE);
		addOption(option);

		var option:Option = new Option(this, 'framerate', INT, [24, 2000, 'TPS']);
		addOption(option);
		option.onChange = onChangeFramerate;

		var option:Option = new Option(this, 'scriptUpdateRate', INT, [0, 2000, 'TPS']);
		addOption(option);

		var option:Option = new Option(this, 'scriptUpdateFrameLimit', BOOL);
		addOption(option);

		#if !ios
		var option:Option = new Option(this, 'drawFramerate', INT, [24, 2000, 'FPS']);
		addOption(option);
		option.onChange = onChangeDrawFramerate;

		var option:Option = new Option(this, 'lockRender', BOOL);
		addOption(option);
		option.onChange = onChangelockRender;
		#end

		var option:Option = new Option(this, 'renderThread', BOOL);
		addOption(option);
		option.onChange = onChangerenderThread;

		#if cpp
		vsyncOption = new Option(this, 'vsync', BOOL);
		addOption(vsyncOption);
		previousVSync = ClientPrefs.data.vsync;
		vsyncOption.onChange = onChangeVSync;
		#end

		#if android
		var option:Option = new Option(this, 'androidPerformanceHints', BOOL);
		addOption(option);
		option.onChange = () -> mobile.backend.AndroidPerformanceHints.setEnabled(ClientPrefs.data.androidPerformanceHints);
		#end

		#if (cpp && NOVAFLARE_GC_GENERATIONAL_PREFERENCE && !hxcpp_zgc)
		var option:Option = new Option(this, 'generationalGC', BOOL);
		addOption(option);
		#end

		var option:Option = new Option(this, 'lowQuality', BOOL);
		addOption(option);

		var resolutionArray:Array<Array<String>> = resoData();
		var option:Option = new Option(this, 'resolution', STRING, resolutionArray);
		addOption(option);
		option.onChange = onChangeResolution;

		var option:Option = new Option(this, 'antialiasing', BOOL);
		addOption(option);

		var option:Option = new Option(this, 'flashing', BOOL);
		addOption(option);

		var option:Option = new Option(this, 'shaders', BOOL);
		addOption(option);

		#if mobile
		var option:Option = new Option(this, 'autoShaderConversion', BOOL);
		addOption(option);
		option.onChange = onChangeAutoShaderConversion;

		var option:Option = new Option(this, 'mouseTrailEffect', BOOL);
		addOption(option);
		option.onChange = onChangeMouseEffects;
		#end

		var option:Option = new Option(this, 'cacheOnGPU', BOOL);
		addOption(option);

		var option:Option = new Option(this, 'autoPause', BOOL);
		addOption(option);
		option.onChange = onChangePause;

		var colorblindFilterArray:Array<String> = [
			'None',
			'Protanopia',
			'Protanomaly',
			'Deuteranopia',
			'Deuteranomaly',
			'Tritanopia',
			'Tritanomaly',
			'Achromatopsia',
			'Achromatomaly'
		];
		var colorblindDisplayArray:Array<String> = [
			'None',
			'Protanopia',
			'Protanomaly',
			'Deuteranopia',
			'Deuteranomaly',
			'Tritanopia',
			'Tritanomaly',
			'Achromatopsia',
			'Achromatomaly'
		];

		var option:Option = new Option(this, 'colorblindMode', STRING, [colorblindFilterArray, colorblindDisplayArray]);
		addOption(option);
		option.onChange = onChangeFilter;

		changeHeight(0);
	}

	///////////////////////////////////////////////////////////////////////////

	function resoData():Array<Array<String>>
	{
		var labels = RenderResolution.choices();
		return [labels, labels];
	}

	///////////////////////////////////////////////////////////////

	function onChangeFramerate()
	{
		FlxG.updateFramerate = ClientPrefs.data.framerate;
	}

	#if !ios
	function onChangeDrawFramerate()
	{
		FlxG.drawFramerate = ClientPrefs.data.drawFramerate;
	}

	function onChangelockRender()
	{
		var window = FlxG.stage.window;
		window.lockRender = ClientPrefs.data.lockRender;
		ClientPrefs.data.lockRender = window.lockRender;
	}
	#end

	#if cpp
	function onChangeVSync():Void
	{
		if (ClientPrefs.applyVSyncPreference())
		{
			previousVSync = ClientPrefs.data.vsync;
			return;
		}

		vsyncOption.setValue(previousVSync);
		@:privateAccess vsyncOption.boolButton.updateDisplay();
		trace('Could not change VSync mode');
	}
	#end

	function onChangerenderThread()
	{
		GL.setMultiThreaded(ClientPrefs.data.renderThread);
	}

	function onChangeResolution()
	{
		RenderResolution.apply(openfl.Lib.current.stage, ClientPrefs.data.resolution);
	}

	function onChangeFilter()
	{
		ColorblindFilter.UpdateColors();
	}

	function onChangePause()
	{
		FlxG.autoPause = ClientPrefs.data.autoPause;
	}

	#if mobile
	function onChangeAutoShaderConversion()
	{
		MobileShaderConverter.setEnabled(ClientPrefs.data.autoShaderConversion);
	}

	function onChangeMouseEffects()
	{
		MouseEffect.setUserEffectsEnabled(ClientPrefs.data.mouseTrailEffect);
	}
	#end
}
