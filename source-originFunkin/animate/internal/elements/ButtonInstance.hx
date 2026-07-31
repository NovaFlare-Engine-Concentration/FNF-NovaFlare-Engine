package animate.internal.elements;

import animate.FlxAnimateJson;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.math.FlxMath;
import flixel.math.FlxMatrix;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.system.FlxAssets.FlxShader;
import flixel.util.FlxDestroyUtil;
import flixel.util.FlxSignal;
import openfl.display.BlendMode;
import openfl.geom.ColorTransform;

using flixel.util.FlxColorTransformUtil;

#if FLX_DEBUG
import flixel.util.FlxColor;
#end

class ButtonInstance extends SymbolInstance
{
	/**
	 * The current state of the button. Updated on draw passes.
	 * Use ``updateButtonState`` to update it on command.
	 */
	public var curButtonState(default, null):ButtonState;

	/**
	 * A signal that gets called when the button is clicked.
	 */
	public var onClick:FlxSignal;

	public function new(?data:SymbolInstanceJson, ?parent:FlxAnimateFrames, ?frame:Frame)
	{
		super(data, parent, frame);

		this.elementType = BUTTON;
		this.curButtonState = ButtonState.UP;
		this.onClick = new FlxSignal();
		this._hitbox = FlxRect.get();
	}

	override function getBounds(frameIndex:Int, ?rect:FlxRect, ?matrix:FlxMatrix, ?includeFilters:Bool = true, ?useCachedBounds:Bool = false):FlxRect
	{
		var boundsIndex = FlxMath.minInt(ButtonState.HIT, this.libraryItem.timeline.frameCount - 1);
		var bounds = this.libraryItem.timeline.getBounds(boundsIndex, false, rect, this.matrix, false, useCachedBounds);
		Timeline.applyMatrixToRect(bounds, matrix);
		return bounds;
	}

	override function getFrameIndex(index:Int, frameIndex:Int = 0):Int
	{
		return FlxMath.minInt(curButtonState, this.libraryItem.timeline.frameCount - 1);
	}

	override function draw(camera:FlxCamera, index:Int, frameIndex:Int, parentMatrix:FlxMatrix, ?transform:ColorTransform, ?blend:BlendMode,
			?antialiasing:Bool, ?shader:FlxShader)
	{
		updateButtonState(camera, parentMatrix);

		super.draw(camera, index, frameIndex, parentMatrix, transform, blend, antialiasing, shader);

		#if FLX_DEBUG
		if (FlxG.debugger.drawDebug && FlxAnimate.drawDebugLimbs)
			AtlasInstance.drawBoundingBox(camera, _hitbox, FlxColor.PURPLE);
		#end
	}

	var _hitbox:FlxRect;

	function updateButtonState(camera:FlxCamera, drawMatrix:FlxMatrix):Void
	{
		_hitbox = getBounds(0, _hitbox, drawMatrix);

		#if FLX_MOUSE
		var mousePos = #if (flixel >= "5.9.0") FlxG.mouse.getViewPosition(camera,
			FlxPoint.get()); #else FlxG.mouse.getScreenPosition(camera, FlxPoint.get()); #end

		var xPos = mousePos.x;
		var yPos = mousePos.y;
		var isOverlaped = xPos >= _hitbox.left && xPos <= _hitbox.right && yPos >= _hitbox.top && yPos <= _hitbox.bottom;
		mousePos.put();

		if (isOverlaped)
		{
			this.curButtonState = FlxG.mouse.pressed ? ButtonState.DOWN : ButtonState.OVER;
			if (FlxG.mouse.justPressed)
				onClick.dispatch();
		}
		else
		{
			this.curButtonState = ButtonState.UP;
		}
		#elseif FLX_TOUCH
		var touchPos = #if (flixel >= "5.9.0") FlxG.touches.getFirst()?.getViewPosition(camera,
			FlxPoint.get()); #else FlxG.touches.getFirst()?.getScreenPosition(camera, FlxPoint.get()); #end
		if (touchPos != null)
		{
			var xPos = touchPos.x;
			var yPos = touchPos.y;
			var isOverlaped = xPos >= _hitbox.left && xPos <= _hitbox.right && yPos >= _hitbox.top && yPos <= _hitbox.bottom;
			touchPos.put();
			if (isOverlaped)
			{
				this.curButtonState = FlxG.touches.getFirst()?.pressed ? ButtonState.DOWN : ButtonState.OVER;
				if (FlxG.touches.getFirst()?.justPressed)
					onClick.dispatch();
			}
			else
			{
				this.curButtonState = ButtonState.UP;
			}
		}
		else
		{
			this.curButtonState = ButtonState.UP;
		}
		#end
	}

	override function destroy():Void
	{
		super.destroy();
		_hitbox = FlxDestroyUtil.put(_hitbox);
		onClick = null;
	}

	override function toString():String
	{
		return '{name: ${libraryItem.name}, matrix: $matrix, curButtonState: $curButtonState}';
	}
}

enum abstract ButtonState(Int) to Int
{
	var UP = 0;
	var OVER = 1;
	var DOWN = 2;
	var HIT = 3;

	public inline function toString():String
	{
		return switch (cast this)
		{
			case UP: "UP";
			case OVER: "OVER";
			case DOWN: "DOWN";
			case HIT: "HIT";
		}
	}
}
