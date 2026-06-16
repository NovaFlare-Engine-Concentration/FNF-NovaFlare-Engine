package options.groupData;

import lime.graphics.opengl.GL;
import lime.system.Display;

class GraphicsGroup extends OptionCata
{
	public function new(X:Float, Y:Float, width:Float, height:Float)
	{
		super(X, Y, width, height);

		var option:Option = new Option(this, 'Graphics', TITLE);
		addOption(option);

		//从常规移动的显示设置
		var option:Option = new Option(this, 'Rendering', TEXT);
		addOption(option);

		var option:Option = new Option(this, 'framerate', INT, [24, #if mobile 1000 #else 2000 #end, 'TPS']);
		addOption(option);
		option.onChange = onChangeFramerate;

		var option:Option = new Option(this, 'drawFramerate', INT, [24, #if mobile 240 #else 1000 #end, 'FPS']);
		addOption(option);
		option.onChange = onChangeDrawFramerate;

		var option:Option = new Option(this, 'lockRender', BOOL);
		addOption(option);
		option.onChange = onChangelockRender;

		var option:Option = new Option(this, 'renderThread', BOOL);
		addOption(option);
		option.onChange = onChangerenderThread;

		var option:Option = new Option(this, 'lowQuality', BOOL);
		addOption(option);

		var resolutionArray:Array<Array<String>> = resoData();
		var option:Option = new Option(this, 'resolution', STRING, resolutionArray);
		addOption(option);
		option.onChange = onChangeResolution;

		var option:Option = new Option(this, 'gameQuality', INT, [0, 3]);
		addOption(option);
		
		var option:Option = new Option(this, 'antialiasing', BOOL);
		addOption(option);

		var option:Option = new Option(this, 'flashing', BOOL);
		addOption(option);

		var option:Option = new Option(this, 'shaders', BOOL);
		addOption(option);

		var option:Option = new Option(this, 'cacheOnGPU', BOOL);
		addOption(option);

		/////--FPScounter--\\\\\

		var option:Option = new Option(this, 'FPScounter', TEXT);
		addOption(option);

		var option:Option = new Option(this, 'showFPS', BOOL);
		option.onChange = () -> changeWatermark();
		addOption(option);

		var option:Option = new Option(this, 'rainbowFPS', BOOL);
		addOption(option);

		var option:Option = new Option(this, 'fpsScale', FLOAT, [0, 5, 1]);
		option.onChange = () -> changeWatermark();
		addOption(option);
		
		/////--Watermark--\\\\\

		var option:Option = new Option(this, 'Watermark', TEXT);
		addOption(option);

		var option:Option = new Option(this, 'showWatermark', BOOL);
		option.onChange = () -> changeWatermark();
		addOption(option);

		var option:Option = new Option(this, 'watermarkScale', FLOAT, [0, 5, 1]);
		option.onChange = () -> changeWatermark();
		addOption(option);

		changeHeight(0); //初始化真正的height
	}

		function resoData():Array<Array<String>> {
		var display:Display = lime.system.System.getDisplay(0);
		var maxReso:Float = display.bounds.width * display.bounds.height;
		var displayOutput:Array<String> = [];

		var data:Array<Float> = [640 * 360, 854 * 480, 960 * 540, 1280 * 720, 1366 * 768, 1600 * 900, 1920 * 1080, 2560 * 1440, 2560 * 1600, 3200 * 1800, 3840 * 2160];
		var displayData:Array<String> = ["360P", "480P", "540P", "720P", "768P", "900P", "1080P", "1440P (2K)", "1600P", "1800P", "2160P (4K)"];
		
		for (i in 0...data.length)
		{
			if (maxReso > Math.floor(data[i]))
			{
				displayOutput.push(displayData[i]);
			} else {
				displayOutput.push("Native: " + display.bounds.width + "x" + display.bounds.height);
				break;
			}
		}

		return [displayOutput, displayOutput];
	}
	
	///////////////////////////////////////////////////////////////

	function onChangeFramerate()
	{
		if (ClientPrefs.data.framerate > FlxG.drawFramerate)
		{
			FlxG.updateFramerate = ClientPrefs.data.framerate;
			FlxG.drawFramerate = ClientPrefs.data.framerate;
		}
		else
		{
			FlxG.drawFramerate = ClientPrefs.data.framerate;
			FlxG.updateFramerate = ClientPrefs.data.framerate;
		}
	}

	function onChangeDrawFramerate()
	{
		FlxG.stage.application.window.drawFrameRate = ClientPrefs.data.drawFramerate;
	}

	function onChangelockRender()
	{
		FlxG.stage.application.window.lockRender = ClientPrefs.data.lockRender;
	}

	function onChangerenderThread()
	{
		GL.setMultiThreaded(ClientPrefs.data.renderThread);
	}

	function onChangeResolution()
	{
		var output:Array<Float> = [];
		switch(ClientPrefs.data.resolution) {
			case '360P':
				output = [640, 360];
			case '480P':
				output = [854, 480];
			case '540P':
				output = [960, 540];
			case '720P':
				output = [1280, 720];
			case '768P':
				output = [1366, 768];
			case '900P':
				output = [1600, 900];
			case '1080P':
				output = [1920, 1080];
			case '1440P (2K)':
				output = [2560, 1440];
			case '1600P':
				output = [2560, 1600];
			case '1800P':
				output = [3200, 1800];
			case '2160P (4K)':
				output = [3840, 2160];
			default:
				var display:Display = lime.system.System.getDisplay(0);
				output = [display.bounds.width, display.bounds.height];
		}
		openfl.Lib.current.stage.setLogicalSize(Std.int(output[0]), Std.int(output[1]));
	}

	function changeWatermark() {
		Main.fpsVar.visible = ClientPrefs.data.showFPS;
		Main.fpsVar.scaleX = Main.fpsVar.scaleY = ClientPrefs.data.fpsScale;
		//Main.fpsVar.change();
		if (Main.watermark != null)
		{
			Main.watermark.scaleX = Main.watermark.scaleY = ClientPrefs.data.watermarkScale;
			Main.watermark.y += (1 - ClientPrefs.data.watermarkScale) * Main.watermark.bitmapData.height;
			Main.watermark.visible = ClientPrefs.data.showWatermark;
		}
	}

}
