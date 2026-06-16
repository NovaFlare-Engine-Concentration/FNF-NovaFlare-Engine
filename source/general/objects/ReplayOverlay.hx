package general.objects;

import openfl.display.Sprite;
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.text.TextFieldAutoSize;
import openfl.Lib;

class ReplayOverlay extends Sprite
{
	private var textField:TextField;
	private var hue:Float = 0;
	private var colorSpeed:Float = 0.6; // hue change per frame

	public function new()
	{
		super();

		textField = new TextField();
		textField.text = "NovaFlare Replay";
		textField.selectable = false;
		textField.mouseEnabled = false;

		var format:TextFormat = new TextFormat();
		format.font = "_sans";
		format.size = 16;
		format.bold = true;
		textField.defaultTextFormat = format;
		textField.setTextFormat(format);
		textField.autoSize = TextFieldAutoSize.LEFT;

		// Position at top center
		textField.x = (Lib.current.stage.stageWidth - textField.width) / 2;
		textField.y = Lib.current.stage.stageHeight - 80;

		addChild(textField);
		this.visible = false;
	}

	public function showOverlay():Void
	{
		this.visible = true;
	}

	public function hideOverlay():Void
	{
		this.visible = false;
	}

	private override function __enterFrame(deltaTime:Float):Void
	{
		if (!visible)
			return;

		hue += colorSpeed;
		if (hue >= 360)
			hue -= 360;

		var color:Int = hslToRgb(hue, 1.0, 0.5);

		var format:TextFormat = new TextFormat();
		format.color = color;
		format.font = "_sans";
		format.size = 16;
		format.bold = true;
		textField.setTextFormat(format);

		// Update position in case window size changed
		textField.x = Lib.current.stage.stageWidth - textField.width;
		textField.y = Lib.current.stage.stageHeight - textField.height;
	}

	/**
	 * Convert HSL to RGB integer color
	 */
	private function hslToRgb(h:Float, s:Float, l:Float):Int
	{
		var r:Float, g:Float, b:Float;

		if (s == 0)
		{
			r = g = b = l;
		}
		else
		{
			var hue2rgb:Float->Float->Float->Float = function(p:Float, q:Float, t:Float):Float
			{
				if (t < 0) t += 1;
				if (t > 1) t -= 1;
				if (t < 1 / 6) return p + (q - p) * 6 * t;
				if (t < 1 / 2) return q;
				if (t < 2 / 3) return p + (q - p) * (2 / 3 - t) * 6;
				return p;
			};

			var q:Float = l < 0.5 ? l * (1 + s) : l + s - l * s;
			var p:Float = 2 * l - q;
			r = hue2rgb(p, q, h / 360 + 1 / 3);
			g = hue2rgb(p, q, h / 360);
			b = hue2rgb(p, q, h / 360 - 1 / 3);
		}

		var ri:Int = Math.round(r * 255);
		var gi:Int = Math.round(g * 255);
		var bi:Int = Math.round(b * 255);

		return (0xFF << 24) | (ri << 16) | (gi << 8) | bi;
	}
}
