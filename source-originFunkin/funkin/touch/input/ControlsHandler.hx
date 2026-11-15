package funkin.touch.input;

/** Origin preview's device query, backed by NovaFlare's existing mobile handler. */
@:keep
class ControlsHandler
{
  public static var hasExternalInputDevice(get, never):Bool;

  @:keep
  static function get_hasExternalInputDevice():Bool
  {
    #if mobile
    return funkin.mobile.input.ControlsHandler.hasExternalInputDevice;
    #else
    return flixel.FlxG.gamepads.numActiveGamepads > 0;
    #end
  }
}
