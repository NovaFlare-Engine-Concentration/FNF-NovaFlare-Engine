package originfunkin.compat;

import flxanimate.animate.FlxAnim;
import flixel.util.FlxSignal;
import flixel.util.FlxSignal.FlxTypedSignal;

class AnimationCallbacksState
{
  public var complete:Null<Void->Void>;
  public var completeOrigin:Null<String>;
  public var completeSignal:Null<FlxSignal>;
  public var frame:Null<(String, Int)->Void>;
  public var frameListener:Null<Int->Void>;
  public var frameSignal:Null<FlxTypedSignal<Int->Void>>;
  public function new() {}
}

/** Old function properties share the native signals without replacing their other listeners. */
@:access(flxanimate.animate.FlxAnim)
class LegacyAnimationCallbacks
{
  public static function hasValue(target:Dynamic, field:String, origin:Null<String>):Bool
  {
    // This hook runs for every interpreted property read, including ordinary
    // gameplay fields. Only resolve mod policy for the two animation properties.
    if ((field != 'callback' && field != 'onComplete') || !Std.isOfType(target, FlxAnim)) return false;
    if (!LegacyRuntime.isLegacyOrigin(origin)) return false;
    if (field == 'callback') return true;
    var anim:FlxAnim = cast target;
    return field == 'onComplete' && (LegacyRuntime.usesAnimationCallbacks(origin)
      || (anim.originLegacyCallbacks != null && anim.originLegacyCallbacks.completeOrigin == origin));
  }

  public static function getValue(target:Dynamic, field:String):Dynamic
  {
    var anim:FlxAnim = cast target;
    return field == 'callback' ? anim.originLegacyCallbacks?.frame : anim.originLegacyCallbacks?.complete;
  }

  public static function trySet(target:Dynamic, field:String, value:Dynamic, origin:Null<String>):Bool
  {
    if (!Std.isOfType(target, FlxAnim) || (field != 'onComplete' && field != 'callback')) return false;
    var anim:FlxAnim = cast target;
    var state = anim.originLegacyCallbacks;
    if (value != null && !Reflect.isFunction(value))
    {
      if (field == 'onComplete' && Std.isOfType(value, flixel.util.FlxSignal.IFlxSignal) && state != null)
      {
        if (state.complete != null && state.completeSignal != null) state.completeSignal.remove(state.complete);
        state.complete = null;
        state.completeOrigin = null;
        state.completeSignal = null;
      }
      return false;
    }
    if (field == 'onComplete' && value == null && !LegacyRuntime.usesAnimationCallbacks(origin)
      && (state == null || state.completeOrigin != origin)) return false;
    if (state == null) anim.originLegacyCallbacks = state = new AnimationCallbacksState();
    if (field == 'onComplete')
    {
      if (state.complete != null && state.completeSignal != null) state.completeSignal.remove(state.complete);
      state.complete = cast value;
      state.completeOrigin = origin;
      state.completeSignal = anim.onComplete;
      if (state.complete != null && state.completeSignal != null) state.completeSignal.add(state.complete);
    }
    else
    {
      if (state.frameListener != null && state.frameSignal != null) state.frameSignal.remove(state.frameListener);
      state.frame = cast value;
      state.frameSignal = anim.onFrame;
      state.frameListener = value == null ? null : frame ->
      {
        if (state.frame != null) state.frame(anim.curSymbol?.name, frame);
      };
      if (state.frameListener != null && state.frameSignal != null) state.frameSignal.add(state.frameListener);
    }
    return true;
  }

  public static function clear(anim:FlxAnim):Void
  {
    var state = anim.originLegacyCallbacks;
    if (state == null) return;
    if (state.complete != null && state.completeSignal != null) state.completeSignal.remove(state.complete);
    if (state.frameListener != null && state.frameSignal != null) state.frameSignal.remove(state.frameListener);
    state.complete = null;
    state.completeOrigin = null;
    state.completeSignal = null;
    state.frame = null;
    state.frameListener = null;
    state.frameSignal = null;
    anim.originLegacyCallbacks = null;
  }
}
