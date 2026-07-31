package originfunkin.input;

import flixel.math.FlxPoint;

/**
 * Small compatibility implementation of the momentum object exposed by the
 * FunkinCrew Flixel fork. It is only injected into NF's touch manager on
 * mobile builds and does not replace NovaFlare's selected Flixel library.
 */
class OriginFlick
{
	public var ID(default, null):Int = -1;
	public var initialized(default, null):Bool = false;
	public var velocity(default, null):FlxPoint = FlxPoint.get();

	public function new() {}

	public function initFlick(ID:Int, startingVelocity:FlxPoint):Void
	{
		if (initialized || startingVelocity == null)
		{
			return;
		}

		this.ID = ID;
		velocity.set(startingVelocity.x, startingVelocity.y);
		if (Math.abs(velocity.x) <= 10) velocity.x = 0;
		if (Math.abs(velocity.y) <= 10) velocity.y = 0;
		initialized = velocity.x != 0 || velocity.y != 0;
	}

	public function update(elapsed:Float):Void
	{
		if (!initialized)
		{
			return;
		}

		velocity.x *= 0.95;
		velocity.y *= 0.95;
		if (Math.abs(velocity.x) + Math.abs(velocity.y) <= 1)
		{
			destroy();
		}
	}

	/**
	 * The upstream API names this reset operation destroy(). Keep the point
	 * allocated so the manager can safely be reused by later gestures.
	 */
	public function destroy():Void
	{
		velocity.set();
		initialized = false;
		ID = -1;
	}
}
