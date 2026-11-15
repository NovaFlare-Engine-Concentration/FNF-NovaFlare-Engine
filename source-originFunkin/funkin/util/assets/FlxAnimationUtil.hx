package funkin.util.assets;

import flixel.FlxSprite;
import funkin.graphics.FunkinSprite;
import flixel.graphics.frames.FlxFramesCollection;
import funkin.data.animation.AnimationData;

@:nullSafety
class FlxAnimationUtil
{
  /**
   * Properly adds an animation to a sprite based on the provided animation data.
   */
  public static function addAtlasAnimation(target:FlxSprite, anim:AnimationData):Void
  {
    if (anim.prefix == null) return;

    var frameRate:Int = anim.frameRate ?? 24;
    var looped:Bool = anim.looped ?? false;
    var flipX:Bool = anim.flipX ?? false;
    var flipY:Bool = anim.flipY ?? false;

    if (anim.frameIndices != null && anim.frameIndices.length > 0)
    {
      var previous:Null<flixel.animation.FlxAnimation> = target.animation.getByName(anim.name);
      target.animation.addByIndices(anim.name, anim.prefix, anim.frameIndices, '', frameRate, looped, flipX, flipY);

      // Some legacy atlases have an extra exported number between the prefix
      // and frame number, while their data uses positions in the animation.
      // Only try positions when Flixel could not register any exact indices.
      if (target.animation.getByName(anim.name) == previous)
      {
        var temporaryName = '__origin_index_probe';
        while (target.animation.getByName(temporaryName) != null) temporaryName += '_';
        target.animation.addByPrefix(temporaryName, anim.prefix, frameRate, looped, flipX, flipY);
        var probe:Null<flixel.animation.FlxAnimation> = target.animation.getByName(temporaryName);
        if (probe != null)
        {
          var frames:Array<Int> = [];
          for (index in anim.frameIndices)
          {
            if (index < 0 || index >= probe.frames.length)
            {
              frames = [];
              break;
            }
            frames.push(probe.frames[index]);
          }
          if (frames.length == anim.frameIndices.length)
          {
            target.animation.add(anim.name, frames, frameRate, looped, flipX, flipY);
            #if CODENAME_ENGINE_COMPAT
            var restored:Null<flixel.animation.FlxAnimation> = target.animation.getByName(anim.name);
            if (restored != null)
            {
              restored.prefix = anim.prefix;
              restored.usesIndices = true;
            }
            #end
          }
          target.animation.remove(temporaryName);
        }
      }
    }
    else
    {
      target.animation.addByPrefix(anim.name, anim.prefix, frameRate, looped, flipX, flipY);
    }
  }

  /**
   * Properly adds an animation to a texture atlas sprite based on the provided animation data.
   */
  public static function addTextureAtlasAnimation(target:FunkinSprite, anim:AnimationData):Void
  {
    if (!target.isAnimate) return;
    if (anim.prefix == null) return;

    var frameRate:Int = anim.frameRate ?? 24;
    var looped:Bool = anim.looped ?? false;
    var flipX:Bool = anim.flipX ?? false;
    var flipY:Bool = anim.flipY ?? false;
    var animType:String = anim.animType ?? "framelabel";

    if (anim.frameIndices != null && anim.frameIndices.length > 0)
    {
      switch (animType)
      {
        case "framelabel":
          target.anim.addByFrameLabelIndices(anim.name, anim.prefix, anim.frameIndices, frameRate, looped, flipX, flipY);
        case "symbol":
          target.anim.addBySymbolIndices(anim.name, anim.prefix, anim.frameIndices, frameRate, looped, flipX, flipY);
      }
    }
    else
    {
      switch (animType)
      {
        case "framelabel":
          target.anim.addByFrameLabel(anim.name, anim.prefix, frameRate, looped, flipX, flipY);
        case "symbol":
          target.anim.addBySymbol(anim.name, anim.prefix, frameRate, looped, flipX, flipY);
      }
    }
  }

  /** Register an Animate animation from its declared sub-atlas when possible. */
  public static function addTextureAtlasAnimationFromSource(target:FunkinSprite, anim:AnimationData, source:Null<animate.FlxAnimateFrames>):Void
  {
    var handled = false;
    if (source != null && anim.prefix != null)
    {
      var frameRate = anim.frameRate ?? 24;
      var looped = anim.looped ?? false;
      var flipX = anim.flipX ?? false;
      var flipY = anim.flipY ?? false;
      var indices = anim.frameIndices;
      var type = anim.animType ?? 'framelabel';
      var labels = type == 'framelabel' ? target.anim.findFrameLabelIndices(anim.prefix, source.timeline) : [];
      if (labels.length > 0)
      {
        if (indices != null && indices.length > 0)
          target.anim.addByFrameLabelIndices(anim.name, anim.prefix, indices, frameRate, looped, flipX, flipY, source.timeline);
        else
          target.anim.addByFrameLabel(anim.name, anim.prefix, frameRate, looped, flipX, flipY, source.timeline);
        handled = true;
      }
      else if (type == 'symbol' || type == 'framelabel')
      {
        var symbol = source.getSymbol(anim.prefix);
        if (symbol != null)
        {
          if (indices != null && indices.length > 0)
            target.anim.addByTimelineIndices(anim.name, symbol.timeline, indices, frameRate, looped, flipX, flipY);
          else
            target.anim.addByTimeline(anim.name, symbol.timeline, frameRate, looped, flipX, flipY);
          handled = true;
        }
      }
    }
    if (!handled) FlxAnimationUtil.addTextureAtlasAnimation(target, anim);
    // Match the single-atlas character fallback when an animation prefix
    // names a symbol and the requested frame label has no frames.
    var loaded:Null<flixel.animation.FlxAnimation> = target.animation.getByName(anim.name);
    if ((loaded == null || loaded.numFrames == 0) && anim.animType != 'symbol' && anim.prefix != null
      && target.library != null && target.library.getSymbol(anim.prefix) != null)
    {
      var frameRate = anim.frameRate ?? 24;
      var looped = anim.looped ?? false;
      var flipX = anim.flipX ?? false;
      var flipY = anim.flipY ?? false;
      if (anim.frameIndices != null && anim.frameIndices.length > 0)
        target.anim.addBySymbolIndices(anim.name, anim.prefix, anim.frameIndices, frameRate, looped, flipX, flipY);
      else
        target.anim.addBySymbol(anim.name, anim.prefix, frameRate, looped, flipX, flipY);
    }
  }

  /**
   * Properly adds multiple animations to a sprite based on the provided animation data.
   */
  public static function addAtlasAnimations(target:FlxSprite, animations:Array<AnimationData>):Void
  {
    for (anim in animations)
    {
      addAtlasAnimation(target, anim);
    }
  }

  /**
   * Properly adds multiple animations to a texture atlas sprite based on the provided animation data.
   */
  public static function addTextureAtlasAnimations(target:FunkinSprite, animations:Array<AnimationData>):Void
  {
    for (anim in animations)
    {
      addTextureAtlasAnimation(target, anim);
    }
  }

  /**
   * Combine two FlxFramesCollection objects into one.
   * @param a The first FlxFramesCollection
   * @param b The second FlxFramesCollection
   * @return FlxFramesCollection The combined FlxFramesCollection
   */
  public static function combineFramesCollections(a:FlxFramesCollection, b:FlxFramesCollection):FlxFramesCollection
  {
    @:nullSafety(Off)
    var result:FlxFramesCollection = new FlxFramesCollection(null, ATLAS, null);

    for (frame in a.frames)
    {
      result.pushFrame(frame);
    }
    for (frame in b.frames)
    {
      result.pushFrame(frame);
    }

    return result;
  }
}
