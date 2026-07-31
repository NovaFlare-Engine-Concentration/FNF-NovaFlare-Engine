package animate.internal.elements;

import flixel.FlxCamera;
import flixel.math.FlxMatrix;
import flixel.math.FlxRect;
import flixel.system.FlxAssets.FlxShader;
import flixel.util.FlxDestroyUtil;
import openfl.display.BlendMode;
import openfl.geom.ColorTransform;

using flixel.util.FlxColorTransformUtil;

typedef Element = AnimateElement<Dynamic>;

class AnimateElement<T> implements IFlxDestroyable
{
	public var matrix:FlxMatrix;
	public var visible:Bool;
	public var elementType(default, null):ElementType;
	public var parentFrame:Frame;

	var _mat:FlxMatrix;

	public function new(?data:T, ?parent:FlxAnimateFrames, ?frame:Frame)
	{
		_mat = new FlxMatrix();
		parentFrame = frame;
		visible = true;
	}

	/**
	 * Returns the bounds of the element at a specific frame index.
	 *
	 * @param frameIndex			The frame index where to calculate the bounds from.
	 * @param rect					Optional, the rectangle used to input the final calculated values.
	 * @param matrix				Optional, the matrix to apply to the bounds calculation.
	 * @param includeFilters		Optional, if to include filtered bounds in the calculation or use the unfilitered ones (true to Flash's bounds).
	 * @return						A ``FlxRect`` with the complete frames's bounds at an index, empty if no elements were found.
	 */
	public function getBounds(frameIndex:Int, ?rect:FlxRect, ?matrix:FlxMatrix, ?includeFilters:Bool = true, ?useCachedBounds:Bool = false):FlxRect
	{
		return rect ?? FlxRect.get();
	}

	public function draw(camera:FlxCamera, index:Int, frameIndex:Int, parentMatrix:FlxMatrix, ?transform:ColorTransform, ?blend:BlendMode, ?antialiasing:Bool,
		?shader:FlxShader):Void {}

	public inline function toSymbolInstance():SymbolInstance
		return cast this;

	public inline function toMovieClipInstance():MovieClipInstance
		return cast this;

	public inline function toAtlasInstance():AtlasInstance
		return cast this;

	public inline function toButtonInstance():ButtonInstance
		return cast this;

	public inline function toTextFieldInstance():TextFieldInstance
		return cast this;

	public function destroy()
	{
		_mat = null;
		matrix = null;
		parentFrame = null;
	}
}

enum abstract ElementType(String) to String
{
	var ATLAS = "atlas";
	var GRAPHIC = "graphic";
	var MOVIECLIP = "movieclip";
	var BUTTON = "button";
	var TEXT = "text";
}
