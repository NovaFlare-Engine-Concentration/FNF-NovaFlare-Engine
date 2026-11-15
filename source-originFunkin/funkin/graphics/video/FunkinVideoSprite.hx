package funkin.graphics.video;

#if hxvlc
import funkin.play.PlayState;
import hxvlc.flixel.FlxVideoSprite;

/**
 * Not to be confused with FlxVideo, this is a hxvlc based video class.
 */
@:nullSafety
class FunkinVideoSprite extends FlxVideoSprite
{
  override public function load(location:hxvlc.util.Location, ?options:Array<String>):Bool
  {
    return super.load(originfunkin.compat.LegacyVideoLocation.resolve(location), options);
  }

  public function new(x:Float = 0, y:Float = 0)
  {
    super(x, y);

    if (bitmap != null)
    {
      bitmap.onOpening.add(function():Void
      {
        if (bitmap != null)
        {
          if (PlayState.instance != null)
          {
            bitmap.rate = PlayState.instance.playbackRate;
          }
        }
      });
    }
  }
}
#end
