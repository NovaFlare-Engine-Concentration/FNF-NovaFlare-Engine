package animate.internal;

import animate.internal.elements.ButtonInstance;
import animate.internal.elements.Element.ElementType;
import animate.internal.elements.MovieClipInstance;
import animate.internal.elements.SymbolInstance;
import flixel.FlxG;
import flixel.math.FlxMatrix;
import flixel.math.FlxPoint;
import flixel.util.FlxDestroyUtil;

class SymbolItem implements IFlxDestroyable
{
	public var name:String;
	public var timeline:Timeline;

	public function new(timeline:Timeline)
	{
		this.timeline = timeline;
		this.timeline.libraryItem = this;
		this.name = timeline.name;

		@:privateAccess {
			if (timeline?.parent?._settings?.onSymbolCreate != null)
				timeline.parent._settings.onSymbolCreate(this);
		}
	}

	public function destroy():Void
	{
		timeline = FlxDestroyUtil.destroy(timeline);
	}

	public function toString():String
	{
		return '{name: $name}';
	}

	/**
	 * Creates an instance of the symbol item object.
	 *
	 * @param type 	Optional, type of symbol instance to create (``GRAPHIC``, ``MOVIECLIP``, ``BUTTON``).
	 * @return		A new symbol instance of the library symbol item.
	 */
	@:access(animate.internal.elements.SymbolInstance)
	public function createInstance(?type:ElementType = GRAPHIC):Null<SymbolInstance>
	{
		var instance:SymbolInstance;
		switch (type)
		{
			case ElementType.GRAPHIC:
				instance = new SymbolInstance();
			case ElementType.MOVIECLIP:
				instance = new MovieClipInstance();
			case ElementType.BUTTON:
				instance = new ButtonInstance();
			default:
				FlxG.log.warn('Invalid Symbol Instance type "$type".');
				return null;
		}

		instance.libraryItem = this;
		instance.matrix = new FlxMatrix();
		instance.transformationPoint = FlxPoint.get();
		instance.loopType = LOOP;
		instance.firstFrame = 0;
		instance.setColorTransform(1, 1, 1, 1, 0, 0, 0, 0);
		return instance;
	}
}
