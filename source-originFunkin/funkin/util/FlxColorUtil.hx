package funkin.util;

import flixel.util.FlxColor;

/** Non-inline color interpolation used by historical Origin scripts. */
class FlxColorUtil
{
  public static function interpolate(color1:FlxColor, color2:FlxColor, factor:Float = 0.5):FlxColor
  {
    return FlxColor.interpolate(color1, color2, factor);
  }
}
