package options.groupData;

import general.backend.ImageCompression;

class GraphicsGroup extends OptionCata
{
	public function new(X:Float, Y:Float, width:Float, height:Float)
	{
		super(X, Y, width, height);

		var option:Option = new Option(this, 'Graphics', TITLE);
		addOption(option);

		var option:Option = new Option(this, 'gameQuality', INT, [0, 3]);
		addOption(option);

		var option:Option = new Option(this, 'maxImageSize', INT, [0, 32768, 'px']);
		option.onChange = ImageCompression.refreshPreferences;
		addOption(option);

		var thresholdLimit = imageCompressionThresholdLimit();
		ClientPrefs.data.minImageCompressionSize = Std.int(Math.max(0, Math.min(ClientPrefs.data.minImageCompressionSize, thresholdLimit)));
		var option:Option = new Option(this, 'minImageCompressionSize', INT, [0, thresholdLimit, 'px']);
		option.onChange = ImageCompression.refreshPreferences;
		addOption(option);

		final ratio = ClientPrefs.data.imageCompressionRatio;
		ClientPrefs.data.imageCompressionRatio = Math.isFinite(ratio) ? FlxMath.bound(ratio, 0.1, 1) : 1;
		var option:Option = new Option(this, 'imageCompressionRatio', FLOAT, [0.1, 1, 2]);
		option.onChange = ImageCompression.refreshPreferences;
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

		var option:Option = new Option(this, 'fpsDisplayMode', STRING, ['TPS', 'FPS']);
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

	function imageCompressionThresholdLimit():Int
	{
		if (ImageCompression.deviceLimit > 0) return ImageCompression.deviceLimit;
		#if FLX_OPENGL_AVAILABLE
		return Std.int(Math.max(0, FlxG.bitmap.maxTextureSize));
		#else
		return 0;
		#end
	}

	function changeWatermark() {
		Main.fpsVar.visible = ClientPrefs.data.showFPS;
		Main.fpsVar.scaleX = Main.fpsVar.scaleY = ClientPrefs.data.fpsScale;
		//Main.fpsVar.change();
		if (Main.watermark != null)
		{
			Main.watermark.updateLayout();
			Main.watermark.visible = ClientPrefs.data.showWatermark;
		}
	}
}
