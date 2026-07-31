package animate.internal.elements;

import animate.FlxAnimateJson.TextFieldInstanceJson;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.math.FlxMatrix;
import flixel.system.FlxAssets.FlxShader;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.util.FlxDestroyUtil;
import openfl.display.BlendMode;
import openfl.geom.ColorTransform;
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.text.TextFormatAlign;

class TextFieldInstance extends AtlasInstance
{
	/**
	 * The currently displayed text of the textfield.
	 * Requires a redraw when changed.
	 */
	public var text(get, set):String;

	// Couldve used FlxText but it wasnt working well with flash so eh fuck it
	// This probably is a better long term solution either way
	var field:TextField;
	var format:TextFormat;
	var _dirty:Bool = false;

	public function new(data:TextFieldInstanceJson, parent:FlxAnimateFrames, ?frame:Frame)
	{
		super(null, null, frame);

		this.elementType = TEXT;
		this.matrix = data.MX.toMatrix();

		field = new TextField();
		format = new TextFormat();

		var atr = data.ATR[0];
		if (atr != null)
		{
			format.size = atr.SZ;
			format.letterSpacing = atr.CSP;
			format.font = atr.F;
			format.bold = atr.BL;
			format.italic = atr.IT;
			format.align = switch (atr.ALN)
			{
				case "left": TextFormatAlign.LEFT;
				case "right": TextFormatAlign.RIGHT;
				case "justify": TextFormatAlign.JUSTIFY;
				case _: TextFormatAlign.LEFT;
			}
			format.color = FlxColor.fromString(atr.C);
		}

		if (data.BRD)
		{
			// format.borderSize = data.ALTHK;
		}

		field.text = data.TXT;

		redraw();
	}

	inline function redraw()
	{
		if (frame != null)
		{
			FlxG.bitmap.remove(frame.parent);
			frame = FlxDestroyUtil.destroy(frame);
		}

		field.setTextFormat(format);

		var width = Math.ceil(field.textWidth);
		var height = Math.ceil(field.textHeight);

		field.width = width;
		field.height = height;

		var graphic = FlxG.bitmap.create(width, height, 0, true);
		graphic.bitmap.draw(field, null, null, null, graphic.bitmap.rect);
		frame = graphic.imageFrame.frame;
	}

	inline function get_text():String
	{
		return field.text;
	}

	inline function set_text(text:String):String
	{
		if (text != field.text)
		{
			field.text = text;
			_dirty = true;
		}

		return text;
	}

	override function draw(camera:FlxCamera, index:Int, frameIndex:Int, parentMatrix:FlxMatrix, ?transform:ColorTransform, ?blend:BlendMode,
			?antialiasing:Bool, ?shader:FlxShader)
	{
		if (_dirty)
		{
			redraw();
			_dirty = false;
		}

		super.draw(camera, index, frameIndex, parentMatrix, transform, blend, antialiasing, shader);
	}

	override function destroy()
	{
		super.destroy();
		field = null;
		format = null;
	}
}
