package funkin.play.character;

import flixel.graphics.frames.FlxAtlasFrames;
import flixel.graphics.frames.FlxFramesCollection;
import animate.FlxAnimateFrames;
import funkin.graphics.FunkinSprite;
import funkin.data.animation.AnimationData;
import funkin.modding.events.ScriptEvent;
import funkin.util.assets.FlxAnimationUtil;
import funkin.data.character.CharacterData.CharacterRenderType;

/**
 * For some characters which use Sparrow atlases, the spritesheets need to be split
 * into multiple files. This character renderer concatenates these together into a single sprite.
 *
 * Examples in base game include BF Holding GF (most of the sprites are in one file
 * but the death animation is in a separate file).
 * Only example I can think of in mods is Tricky (which has a separate file for each animation).
 *
 * BaseCharacter has game logic, MultiSparrowCharacter has only rendering logic.
 * KEEP THEM SEPARATE!
 */
class MultiSparrowCharacter extends BaseCharacter
{
  var _atlasLease:CharacterAtlasLease = new CharacterAtlasLease();
  var _sparrowSources:Map<String, FlxAtlasFrames> = [];
  var _primarySparrow:Null<FlxAtlasFrames>;
  var _ownedFrames:Null<FlxAtlasFrames>;
  var _animateSources:Map<String, FlxAnimateFrames> = [];

  public function new(id:String)
  {
    super(id, CharacterRenderType.MultiSparrow);
  }

  override function onCreate(event:ScriptEvent):Void
  {
    // Display a custom scope for debugging purposes.
    #if FEATURE_DEBUG_TRACY
    cpp.vm.tracy.TracyProfiler.zoneScoped('MultiSparrowCharacter.create(${this.characterId})');
    #end

    buildSprites();
    super.onCreate(event);
  }

  function buildSprites():Void
  {
    buildSpritesheet();
    buildAnimations();

    if (_data.isPixel)
    {
      this.isPixel = true;
      this.antialiasing = false;
    }
    else
    {
      this.isPixel = false;
      this.antialiasing = true;
    }
  }

  function buildSpritesheet():Void
  {
    log('Loading assets for Multi-Sparrow character "${characterId}"');

    var textureList:Array<FlxAtlasFrames> = [];
    var addedAssetPaths:Array<String> = [];

    var assetPath:String = funkin.assets.Paths.formatRelative(_data.assetPath, 'gameplay/characters/$characterId', Constants.EXT_IMAGE);
    var mainTexture:FlxAtlasFrames = Paths.getSparrowAtlas(assetPath);
    if (mainTexture == null)
    {
      log('Multi-Sparrow atlas could not load PRIMARY texture: ${_data.assetPath}');
      FlxG.log.error('Multi-Sparrow atlas could not load PRIMARY texture: ${_data.assetPath}');
      return;
    }
    else
    {
      log('Creating multi-sparrow atlas: ${_data.assetPath}');
      _primarySparrow = mainTexture;
      _atlasLease.hold(mainTexture.parent);
    }

    var hasTextureAtlas:Bool = false;

    for (anim in _data.animations)
    {
      if (anim.renderType == "animateatlas")
      {
        hasTextureAtlas = true;
        break;
      }
    }

    for (animation in _data.animations)
    {
      if (animation.assetPath == null) continue;
      // Sparrow images and Animate directories can share the same logical path.
      var assetKey = (animation.renderType == "animateatlas" ? "animateatlas:" : "sparrow:") + animation.assetPath;
      if (addedAssetPaths.contains(assetKey)) continue;

      switch (animation.renderType)
      {
        case "animateatlas":
          var atlasPath:String = funkin.assets.Paths.formatRelative(animation.assetPath, 'gameplay/characters/$characterId');
          var subAssetLibrary:String = Paths.getLibrary(atlasPath);
          var subAssetPath:String = Paths.stripLibrary(atlasPath);

          var subTexture:Null<FlxAnimateFrames> = null;
          try subTexture = Paths.getAnimateAtlas(subAssetPath, subAssetLibrary, cast animation.atlasSettings ?? _data.atlasSettings)
          catch (error:Dynamic)
          {
            log('Could not load Animate subtexture ${animation.assetPath}: $error');
            continue;
          }
          if (subTexture == null)
          {
            log('Could not load Animate subtexture ${animation.assetPath}');
            continue;
          }

          log('Concatenating texture atlas: ${animation.assetPath}');
          _animateSources.set(animation.assetPath, subTexture);
          _atlasLease.hold(subTexture.parent);

          textureList.push(subTexture);
        default:
          var sparrowPath:String = funkin.assets.Paths.formatRelative(animation.assetPath, 'gameplay/characters/$characterId', Constants.EXT_IMAGE);
          var subTexture:Null<FlxAtlasFrames> = null;
          try subTexture = Paths.getSparrowAtlas(sparrowPath)
          catch (error:Dynamic)
          {
            log('Could not load Sparrow subtexture ${animation.assetPath}: $error');
            continue;
          }
          // If we don't do this, the unused textures will be removed as soon as they're loaded.

          if (subTexture == null)
          {
            log('Multi-Sparrow atlas could not load subtexture: ${animation.assetPath}');
            FlxG.log.error('Multi-Sparrow atlas could not load subtexture: ${animation.assetPath}');
            continue;
          }
          else
          {
            log('Concatenating multi-sparrow atlas: ${animation.assetPath}');
            _atlasLease.hold(subTexture.parent);

            // Only cache the texture if we don't have a texture atlas animation.
            // Caching sparrows breaks mix-and-match and I wanna fix it at some point...
            // TODO: Re-enable this line once a proper fix is found.
            // - Abnormal
            if (!hasTextureAtlas)
            {
              funkin.assets.Assets.cacheFlxGraphic(funkin.assets.Paths.image(sparrowPath));
            }
          }

          textureList.push(subTexture);
          _sparrowSources.set(animation.assetPath, subTexture);

      }

      addedAssetPaths.push(assetKey);
    }

    // Finally, add the main texture to the list
    // Prevents sub-textures from overriding the the frames of the main texture
    textureList.push(mainTexture);

    // A declared Animate atlas may have failed to load. Select the combined
    // representation from the collections that actually survived loading.
    var hasLoadedTextureAtlas = false;
    for (texture in textureList)
      if (Std.isOfType(texture, FlxAnimateFrames))
      {
        hasLoadedTextureAtlas = true;
        break;
      }
    if (!hasLoadedTextureAtlas)
    {
      var combined = new BorrowedSparrowFrames(mainTexture.parent, mainTexture.border.clone());
      combined.graphicScale = mainTexture.graphicScale;
      var i = textureList.length;
      while (i-- > 0) combined.addAtlas(textureList[i]);
      _ownedFrames = combined;
      this.frames = combined;
    }
    else
    {
      var firstIndex = 0;
      while (!Std.isOfType(textureList[firstIndex], FlxAnimateFrames)) firstIndex++;
      var firstAnimate:FlxAnimateFrames = cast textureList[firstIndex];
      var combined = new BorrowedAnimateFrames(firstAnimate);
      var before = firstIndex;
      while (before-- > 0) combined.addAtlas(textureList[before]);
      for (index in firstIndex + 1...textureList.length) if (textureList[index] != firstAnimate) combined.addAtlas(textureList[index]);
      _ownedFrames = combined;
      this.frames = combined;
    }
    this.setScale(_data.scale);
  }

  function buildAnimations():Void
  {
    log('[MULTISPARROWCHAR] Loading ${_data.animations.length} animations for ${characterId}');

    // We need to swap to the proper frame collection before adding the animations, I think?
    for (anim in _data.animations)
    {
      switch (anim.renderType)
      {
        case "animateatlas":
          FlxAnimationUtil.addTextureAtlasAnimationFromSource(this, anim, anim.assetPath == null ? null : _animateSources.get(anim.assetPath));
        default:
          var source = anim.assetPath == null ? _primarySparrow : _sparrowSources.get(anim.assetPath);
          if (_ownedFrames == null || source == null || !addSourcedSparrowAnimation(anim, source))
            FlxAnimationUtil.addAtlasAnimation(this, anim);
      }

      if (anim.offsets == null)
      {
        setAnimationOffsets(anim.name, 0, 0);
      }
      else
      {
        setAnimationOffsets(anim.name, anim.offsets[0], anim.offsets[1]);
      }
    }

    var animationNames:Array<String> = this.animation.getNameList();
    log('[MULTISPARROWCHAR] Successfully loaded ${animationNames.length} animations for ${characterId}');
  }

  function addSourcedSparrowAnimation(data:AnimationData, source:FlxAtlasFrames):Bool
  {
    return SparrowAnimationSource.register(this, data, source);
  }

  static function log(message:String):Void
  {
    trace(' MULTIATLASCHAR '.bold().bg_blue() + ' $message');
  }

  override function destroy():Void
  {
    if (_ownedFrames != null)
    {
      _ownedFrames.destroy();
      _ownedFrames = null;
    }
    _sparrowSources.clear();
    _primarySparrow = null;
    _animateSources.clear();

    super.destroy();
    _atlasLease.release();
  }

  public override function toString():String
  {
    return 'MultiSparrowCharacter($characterName ($characterId), pos=[$x, $y])';
  }
}

/** A temporary collection whose frames are owned by the source atlases. */
private class BorrowedSparrowFrames extends FlxAtlasFrames
{
  var released:Bool = false;

  public function new(parent:flixel.graphics.FlxGraphic, border:flixel.math.FlxPoint)
  {
    super(parent, border);
  }

  override public function destroy():Void
  {
    if (released) return;
    released = true;
    // The parent graphic can destroy this collection before the character does.
    // FlxFramesCollection.destroy would otherwise destroy borrowed source frames.
    if (frames != null) frames.resize(0);
    super.destroy();
  }
}
