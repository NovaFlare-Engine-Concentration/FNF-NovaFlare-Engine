package animate.internal.elements;

import animate.internal.filters.Blend;
import flixel.FlxBasic;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.math.FlxMatrix;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.system.FlxAssets.FlxShader;
import flixel.util.FlxDestroyUtil;
import openfl.display.BlendMode;
import openfl.geom.ColorTransform;

using flixel.util.FlxColorTransformUtil;

class FlxSpriteElement extends FlxTypedElement<FlxSprite>
{
	var _hasTransform:Bool;
	var _transform:ColorTransform;
	var _point:FlxPoint;
	var _screenPoint:FlxPoint;
	var _angle:Float;
	var _blend:BlendMode;

	public function new(?sprite:FlxSprite)
	{
		super(sprite);

		this._transform = new ColorTransform();
		this._point = FlxPoint.get();
		this._screenPoint = FlxPoint.get();
		this._angle = 0.0;
	}

	override function destroy():Void
	{
		super.destroy();
		_transform = null;
		_point = FlxDestroyUtil.put(_point);
		_point = FlxDestroyUtil.put(_screenPoint);
	}

	override function applyObjectTransform(camera:FlxCamera, parentMatrix:FlxMatrix, transform:ColorTransform, blend:BlendMode, antialiasing:Bool,
			shader:FlxShader)
	{
		var hasTransform = transform != null;
		if (hasTransform)
		{
			if (transform.alphaMultiplier <= 0.0)
				return;

			var color = basic.colorTransform;
			if (color == null)
			{
				_transform.setMultipliers(1, 1, 1, 1);
				_transform.setOffsets(0, 0, 0, 0);
			}
			else
			{
				_transform.redMultiplier = color.redMultiplier;
				_transform.greenMultiplier = color.greenMultiplier;
				_transform.blueMultiplier = color.blueMultiplier;
				_transform.alphaMultiplier = color.alphaMultiplier;

				_transform.redOffset = color.redOffset;
				_transform.greenOffset = color.greenOffset;
				_transform.blueOffset = color.blueOffset;
				_transform.alphaOffset = color.alphaOffset;
			}
		}

		_blend = basic.blend;
		_point.set(basic.x, basic.y);
		_angle = basic.angle;

		super.applyObjectTransform(camera, parentMatrix, transform, blend, antialiasing, shader);

		var x = parentMatrix.transformX(basic.x, basic.y);
		var y = parentMatrix.transformY(basic.x, basic.y);
		var b = Blend.resolve(basic.blend, blend);

		basic.setPosition(0, 0);
		var screenPoint = basic.getScreenPosition(_screenPoint, camera);
		basic.setPosition(x - screenPoint.x, y - screenPoint.y);

		basic.angle += Math.atan2(parentMatrix.b, parentMatrix.a) * 180 / Math.PI;
		if (_hasTransform)
			basic.colorTransform.concat(transform);
		basic.blend = b;
		// basic.antialiasing = antialiasing;
		basic.camera = camera;
	}

	override function resetObjectTransform()
	{
		super.resetObjectTransform();

		basic.setPosition(_point.x, _point.y);
		basic.angle = _angle;
		basic.blend = _blend;
		basic.camera = _camera;

		if (_hasTransform)
		{
			var transform = basic.colorTransform;
			transform.redMultiplier = _transform.redMultiplier;
			transform.greenMultiplier = _transform.greenMultiplier;
			transform.blueMultiplier = _transform.blueMultiplier;
			transform.alphaMultiplier = _transform.alphaMultiplier;

			transform.redOffset = _transform.redOffset;
			transform.greenOffset = _transform.greenOffset;
			transform.blueOffset = _transform.blueOffset;
			transform.alphaOffset = _transform.alphaOffset;
		}
	}

	override function draw(camera:FlxCamera, index:Int, frameIndex:Int, parentMatrix:FlxMatrix, ?transform:ColorTransform, ?blend:BlendMode,
			?antialiasing:Bool, ?shader:FlxShader)
	{
		if (basic == null || basic.alpha <= 0)
			return;

		super.draw(camera, index, frameIndex, parentMatrix, transform, blend, antialiasing, shader);
	}

	override function getObjectBounds(?result:FlxRect):FlxRect
	{
		#if (flixel >= "5.0.0")
		return basic.getScreenBounds(result);
		#else
		return (result != null) ? result.set() : FlxRect.get();
		#end
	}
}

typedef FlxBasicElement = FlxTypedElement<FlxBasic>;

class FlxTypedElement<T:FlxBasic> extends Element
{
	public var basic:T;
	public var active:Bool;

	var _camera:FlxCamera;

	public function new(?basic:T)
	{
		super(null, null, null);
		this.basic = basic;
		this.active = true;
	}

	override function destroy():Void
	{
		super.destroy();
		basic = null;
		_camera = null;
	}

	function applyObjectTransform(camera:FlxCamera, parentMatrix:FlxMatrix, transform:ColorTransform, blend:BlendMode, antialiasing:Bool, shader:FlxShader)
	{
		basic.camera = camera;
	}

	function resetObjectTransform()
	{
		basic.camera = _camera;
	}

	override function draw(camera:FlxCamera, index:Int, frameIndex:Int, parentMatrix:FlxMatrix, ?transform:ColorTransform, ?blend:BlendMode,
			?antialiasing:Bool, ?shader:FlxShader)
	{
		if (basic == null || !basic.visible)
			return;

		_camera = basic.camera;

		if (active)
			basic.update(FlxG.elapsed);

		applyObjectTransform(camera, parentMatrix, transform, blend, antialiasing, shader);

		basic.draw();

		resetObjectTransform();
	}

	function getObjectBounds(?result:FlxRect):FlxRect
	{
		return result;
	}

	override function getBounds(frameIndex:Int, ?rect:FlxRect, ?matrix:FlxMatrix, ?includeFilters:Bool = true, ?useCachedBounds:Bool = false):FlxRect
	{
		var bounds = super.getBounds(frameIndex, rect, matrix, includeFilters);

		if (basic != null)
			bounds = getObjectBounds(bounds);

		Timeline.applyMatrixToRect(bounds, matrix);

		return bounds;
	}
}
