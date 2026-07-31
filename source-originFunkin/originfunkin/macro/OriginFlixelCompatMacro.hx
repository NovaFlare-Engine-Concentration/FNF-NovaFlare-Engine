package originfunkin.macro;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
#end

/**
 * Restores the harmless zIndex storage field supplied by FunkinCrew's Flixel
 * fork without editing NovaFlare's Flixel checkout.
 */
class OriginFlixelCompatMacro
{
	#if macro
	public static macro function addZIndex():Array<Field>
	{
		var fields:Array<Field> = Context.getBuildFields();
		for (field in fields)
		{
			if (field.name == "zIndex")
			{
				return fields;
			}
		}

		fields.push({
			name: "zIndex",
			access: [APublic],
			kind: FVar(macro : Int, macro 0),
			pos: Context.currentPos(),
			doc: "Compatibility draw-order value used by originFunkin 0.8.4."
		});
		return fields;
	}

	public static macro function addContainsExact():Array<Field>
	{
		var fields:Array<Field> = Context.getBuildFields();
		for (field in fields)
		{
			if (field.name == "containsExact")
			{
				return fields;
			}
		}

		var compatibilityField:Field = (macro class Compatibility
		{
			public static function containsExact<T>(values:Array<T>, value:T, equals:T->T->Bool):Bool
			{
				for (candidate in values)
				if (equals(candidate, value)) return true;
				return false;
			}
		}).fields[0];
		fields.push(compatibilityField);
		return fields;
	}

	/**
	 * Adds the movement values supplied by FunkinCrew's Flixel fork to NF's
	 * existing FlxTouch without changing the selected haxelib.
	 */
	public static macro function addTouchCompatibility():Array<Field>
	{
		var fields:Array<Field> = Context.getBuildFields();
		if (!Context.defined("FLX_TOUCH") || hasField(fields, "deltaViewX"))
		{
			return fields;
		}

		var compatibilityFields:Array<Field> = (macro class TouchCompatibility
		{
			public var justMovedUp(get, never):Bool;
			public var justMovedDown(get, never):Bool;
			public var justMovedLeft(get, never):Bool;
			public var justMovedRight(get, never):Bool;
			public var justMoved(get, never):Bool;
			public var deltaX(get, never):Float;
			public var deltaY(get, never):Float;
			public var deltaViewX(get, never):Float;
			public var deltaViewY(get, never):Float;
			public var ticksDeltaSincePress(get, never):Float;
			public var velocity:flixel.math.FlxPoint = flixel.math.FlxPoint.get();

			var _originTouchInitialized:Bool = false;
			var _originPrevX:Float = 0;
			var _originPrevY:Float = 0;
			var _originPrevViewX:Float = 0;
			var _originPrevViewY:Float = 0;
			var _startX:Float = 0;
			var _startY:Float = 0;

			inline function get_justMoved():Bool
			{
				return x != _originPrevX || y != _originPrevY;
			}

			inline function get_justMovedUp():Bool
			{
				var moved:Bool = viewY - _startY > flixel.FlxG.touches.swipeThreshold.y;
				if (moved) _startY = viewY;
				return moved;
			}

			inline function get_justMovedDown():Bool
			{
				var moved:Bool = viewY - _startY < -flixel.FlxG.touches.swipeThreshold.y;
				if (moved) _startY = viewY;
				return moved;
			}

			inline function get_justMovedLeft():Bool
			{
				var moved:Bool = viewX - _startX > flixel.FlxG.touches.swipeThreshold.x;
				if (moved) _startX = viewX;
				return moved;
			}

			inline function get_justMovedRight():Bool
			{
				var moved:Bool = viewX - _startX < -flixel.FlxG.touches.swipeThreshold.x;
				if (moved) _startX = viewX;
				return moved;
			}

			inline function get_deltaX():Float return x - _originPrevX;
			inline function get_deltaY():Float return y - _originPrevY;
			inline function get_deltaViewX():Float return viewX - _originPrevViewX;
			inline function get_deltaViewY():Float return viewY - _originPrevViewY;
			inline function get_ticksDeltaSincePress():Float return flixel.FlxG.game.ticks - justPressedTimeInTicks;
		}).fields;

		for (compatibilityField in compatibilityFields)
		{
			compatibilityField.pos = Context.currentPos();
			fields.push(compatibilityField);
		}

		for (field in fields)
		{
			switch (field.kind)
			{
				case FFun(fn):
					var original:Expr = fn.expr;
					switch (field.name)
					{
						case "setXY":
							fn.expr = macro
							{
								if (velocity == null) velocity = flixel.math.FlxPoint.get();
								if (_originTouchInitialized)
								{
									if (pressed) velocity.set(deltaViewX, deltaViewY);
									_originPrevX = x;
									_originPrevY = y;
									_originPrevViewX = viewX;
									_originPrevViewY = viewY;
								}
								$e{original};
								if (!_originTouchInitialized)
								{
									_originPrevX = x;
									_originPrevY = y;
									_originPrevViewX = viewX;
									_originPrevViewY = viewY;
									_startX = viewX;
									_startY = viewY;
									_originTouchInitialized = true;
								}
							};
						case "recycle":
							fn.expr = macro
							{
								_originTouchInitialized = false;
								$e{original};
							};
						case "handleInput":
							fn.expr = macro
							{
								$e{original};
								if (justPressed)
								{
									_startX = viewX;
									_startY = viewY;
								}
								if (justReleased)
								{
									flixel.FlxG.touches.flickManager.initFlick(touchPointID, velocity);
								}
								if (pressed)
								{
									flixel.FlxG.touches.flickManager.destroy();
								}
							};
						case "destroy":
							fn.expr = macro
							{
								if (velocity != null)
								{
									velocity = flixel.util.FlxDestroyUtil.put(velocity);
								}
								$e{original};
							};
						default:
					}
				default:
			}
		}

		return fields;
	}

	/**
	 * Adds only the touch gesture fields needed by FNF 0.8.4 to NF's current
	 * FlxTouchManager.
	 */
	public static macro function addTouchManagerCompatibility():Array<Field>
	{
		var fields:Array<Field> = Context.getBuildFields();
		if (!Context.defined("FLX_TOUCH") || hasField(fields, "flickManager"))
		{
			return fields;
		}

		var compatibilityFields:Array<Field> = (macro class TouchManagerCompatibility
		{
			public var flickManager:originfunkin.input.OriginFlick = new originfunkin.input.OriginFlick();
			public var invertX:Bool = true;
			public var invertY:Bool = true;
			public var swipeThreshold:flixel.math.FlxPoint = flixel.math.FlxPoint.get(100, 100);
		}).fields;

		for (compatibilityField in compatibilityFields)
		{
			compatibilityField.pos = Context.currentPos();
			fields.push(compatibilityField);
		}

		for (field in fields)
		{
			switch (field.kind)
			{
				case FFun(fn):
					var original:Expr = fn.expr;
					switch (field.name)
					{
						case "handleInput":
							fn.expr = macro
							{
								flickManager.update(flixel.FlxG.elapsed);
								$e{original};
							};
						case "reset" | "destroy":
							fn.expr = macro
							{
								flickManager.destroy();
								$e{original};
							};
						default:
					}
				default:
			}
		}

		return fields;
	}

	static function hasField(fields:Array<Field>, name:String):Bool
	{
		for (field in fields)
		{
			if (field.name == name) return true;
		}
		return false;
	}
	#end
}
