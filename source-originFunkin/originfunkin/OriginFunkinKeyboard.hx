package originfunkin;

import flixel.FlxG;
import flixel.input.keyboard.FlxKeyboard;
import openfl.events.KeyboardEvent;

/** Preserve taps that SDL2 delivers entirely between two game updates. */
@:access(flixel.input.FlxKeyManager)
class OriginFunkinKeyboard extends FlxKeyboard
{
  var pendingReleases:Array<Int> = [];

  public static function install():Void
  {
    if (Std.isOfType(FlxG.keys, OriginFunkinKeyboard)) return;
    var previous = FlxG.keys;
    var keyboard = new OriginFunkinKeyboard();
    keyboard.preventDefaultKeys = previous.preventDefaultKeys.copy();
    keyboard.enabled = previous.enabled;
    FlxG.inputs.replace(previous, keyboard, true);
    untyped FlxG.keys = keyboard;
  }

  override function onKeyDown(event:KeyboardEvent):Void
  {
    var code = resolveKeyCode(event);
    if (enabled && pendingReleases.remove(code))
    {
      // A second physical press can arrive before the first tap is consumed.
      // Keep the pending press visible and reflect the new held key.
      handlePreventDefaultKeys(code, event);
      return;
    }
    super.onKeyDown(event);
  }

  override function onKeyUp(event:KeyboardEvent):Void
  {
    var code = resolveKeyCode(event);
    var input = getKey(code);
    if (enabled && input != null && input.justPressed)
    {
      handlePreventDefaultKeys(code, event);
      if (!pendingReleases.contains(code)) pendingReleases.push(code);
      return;
    }
    super.onKeyUp(event);
  }

  override public function handleInput():Void
  {
    super.handleInput();
    if (pendingReleases.length == 0) return;
    for (code in pendingReleases.copy())
    {
      var input = getKey(code);
      if (input != null && input.justPressed) continue;
      if (input != null && input.pressed)
      {
        input.release();
        input.last = input.current;
      }
      pendingReleases.remove(code);
    }
  }

  override public function reset():Void
  {
    if (pendingReleases != null) pendingReleases.resize(0);
    super.reset();
  }
}
