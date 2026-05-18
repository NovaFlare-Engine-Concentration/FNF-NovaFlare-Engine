package options.groupData;

import lime.graphics.opengl.GL;
import general.shaders.ColorblindFilter;
import lime.system.Display;

class GeneralGroup extends OptionCata
{
	public function new(X:Float, Y:Float, width:Float, height:Float)
	{
		super(X, Y, width, height);

		var option:Option = new Option(this, 'General', TITLE);
		addOption(option);

		var option:Option = new Option(this, 'Basic', TEXT);
		addOption(option);

		var langArray:Array<String> = languageArray();
		var option:Option = new Option(this, 'language', STRING, langArray);
		addOption(option);
		option.onChange = onChangeLanguage;

		var option:Option = new Option(this, 'autoPause', BOOL);
		addOption(option);
		option.onChange = onChangePause;

				
		/////--Watermark--\\\\\

		var option:Option = new Option(this, 'watermark', TEXT);
		addOption(option);

		var option:Option = new Option(this, 'showWatermark', BOOL);
		option.onChange = () -> changeWatermark();
		addOption(option);

		var option:Option = new Option(this, 'watermarkScale', FLOAT, [0, 5, 1]);
		option.onChange = () -> changeWatermark();
		addOption(option);

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

		changeHeight(0); //初始化真正的height
	}

	///////////////////////////////////////////////////////////////////////////

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

	function languageArray():Array<String> 
	{
		var output:Array<String> = [];
		var contents:Array<String> = FileSystem.readDirectory(Paths.getPath('language'));
		for (item in contents)
		{
			if (item == "JustSay")
				continue; // JustSay不能被读取为语言文件
			var itemPath = Paths.getPath('language') + '/' + item;
			if (FileSystem.isDirectory(itemPath))
			{
				output.push(item);
			}
		}
		Language.check();
		return output;
	}

	function onChangePause()
	{
		FlxG.autoPause = ClientPrefs.data.autoPause;
	}

	function onChangeLanguage()
	{
		Language.resetData();
		OptionsState.instance.changeLanguage();
	}

	function onChangeFilter()
	{
		ColorblindFilter.UpdateColors();
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
