package developer.display;

class FPSCounter extends Sprite
{
	public var data:TextField;
	public var title:TextField;

	public var bgSprite:FPSBG;

	public function new(x:Float = 10, y:Float = 10)
	{
		super();

		this.x = x;
		this.y = y;

		bgSprite = new FPSBG();
		addChild(bgSprite);

		this.data = new TextField();
		this.title = new TextField();

		for (label in [this.data, this.title])
		{
			label.x = 0;
			label.y = 0;
			label.defaultTextFormat = new TextFormat(Assets.getFont("assets/fonts/FPS.ttf").fontName, label == this.data ? 36 : 16, 0xFFFFFFFF, false, null,
				null, label == this.data ? CENTER : RIGHT, 0, 0);
			label.multiline = label.wordWrap = false;
			label.selectable = false;
			label.mouseEnabled = false;
			addChild(label);
		}

		this.title.x += this.data.width / 2 - 2;

		this.data.y -= 1;
		this.title.y += 6;

		this.data.text = "0";
		this.title.text = "FPS \n " + "/ " + ClientPrefs.data.framerate + ' \n';

		this.data.x += 4;
		this.title.x -= 12;
	}

	public function update():Void
	{
		for (label in [this.data, this.title])
		{
			if (ClientPrefs.data.rainbowFPS)
			{
				label.textColor = ColorReturn.transfer(DataCalc.drawFPS, ClientPrefs.data.drawFramerate);
			}
			else
			{
				label.textColor = 0xFFFFFFFF;
			}

			if (!ClientPrefs.data.rainbowFPS && DataCalc.updateFPS <= ClientPrefs.data.framerate / 2)
			{
				label.textColor = 0xFFFF0000;
			}
		}

		if (ClientPrefs.data.fpsDisplayMode == 'TPS')
		{
			this.title.text = "TPS \n " + "/ " + ClientPrefs.data.framerate + ' \n';
			this.data.text = Std.string(DataCalc.updateFPS) + " ";
		}
		else
		{
			this.title.text = "FPS \n " + "/ " + ClientPrefs.data.drawFramerate + ' \n';
			this.data.text = Std.string(DataCalc.drawFPS) + " ";
		}
	}
}
