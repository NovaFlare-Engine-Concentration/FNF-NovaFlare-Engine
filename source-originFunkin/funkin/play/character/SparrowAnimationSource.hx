package funkin.play.character;

import flixel.FlxSprite;
import flixel.graphics.frames.FlxAtlasFrames;
import funkin.data.animation.AnimationData;
import funkin.graphics.FunkinSprite;
import funkin.util.assets.FlxAnimationUtil;

/** Registers Sparrow frames from the atlas explicitly named by the animation. */
class SparrowAnimationSource
{
  public static function register(target:FunkinSprite, data:AnimationData, source:FlxAtlasFrames):Bool
  {
    if (source == null || target.frames == null) return false;
    var probe = new FlxSprite();
    probe.frames = source;
    FlxAnimationUtil.addAtlasAnimation(probe, data);
    var found = probe.animation.getByName(data.name);
    if (found != null)
    {
      var indices:Array<Int> = [];
      for (sourceIndex in found.frames)
      {
        var frame = source.frames[sourceIndex];
        var index = target.frames.frames.indexOf(frame);
        if (index < 0)
        {
          index = target.frames.frames.length;
          target.frames.frames.push(frame);
        }
        indices.push(index);
      }
      if (target.isAnimate)
      {
        var entry = new flixel.animation.FlxAnimation(target.animation, data.name, indices, data.frameRate ?? 24,
          data.looped ?? false, data.flipX ?? false, data.flipY ?? false);
        @:privateAccess target.animation._animations.set(data.name, entry);
      }
      else target.animation.add(data.name, indices, data.frameRate ?? 24, data.looped ?? false, data.flipX ?? false, data.flipY ?? false);
      #if CODENAME_ENGINE_COMPAT
      var loaded = target.animation.getByName(data.name);
      if (loaded != null)
      {
        loaded.prefix = data.prefix;
        loaded.usesIndices = data.frameIndices != null && data.frameIndices.length > 0;
      }
      #end
    }
    probe.destroy();
    return found != null;
  }
}
