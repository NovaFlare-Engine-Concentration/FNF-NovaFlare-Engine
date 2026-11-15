package funkin.play.character;

import funkin.graphics.FunkinSprite;
import funkin.util.assets.FlxAnimationUtil;
import animate.FlxAnimateFrames;
import flixel.graphics.frames.FlxAtlasFrames;
import funkin.modding.events.ScriptEvent;
import funkin.data.animation.AnimationData;
import funkin.data.character.CharacterData.CharacterRenderType;

/**
 * This render type is the most complex, and is used by characters which use
 * multiple Adobe Animate texture atlases. This render type concatenates multiple
 * texture atlases into a single sprite.
 *
 * BaseCharacter has game logic, MultiAnimateAtlasCharacter has only rendering logic.
 * KEEP THEM SEPARATE!
 */
class MultiAnimateAtlasCharacter extends BaseCharacter
{
  var _atlasLease:CharacterAtlasLease = new CharacterAtlasLease();
  var _ownedFrames:Null<BorrowedAnimateFrames>;
  var _animateSources:Map<String, FlxAnimateFrames> = [];
  var _sparrowSources:Map<String, FlxAtlasFrames> = [];

  public function new(id:String)
  {
    super(id, CharacterRenderType.MultiAnimateAtlas);
  }

  override function onCreate(event:ScriptEvent):Void
  {
    // Display a custom scope for debugging purposes.
    #if FEATURE_DEBUG_TRACY
    cpp.vm.tracy.TracyProfiler.zoneScoped('MultiAnimateAtlasCharacter.create(${this.characterId})');
    #end

    log('Loading assets for Multi-Animate Atlas character "${characterId}"');
    loadAtlases();
    loadAnimations();

    log('Successfully loaded texture atlases for ${characterId} with ${_data.animations.length} animations.');
    super.onCreate(event);
  }

  function loadAtlases():Void
  {
    log('Loading texture atlases for ${characterId}.');

    var textureList:Array<FlxAtlasFrames> = [];
    var addedAssetPaths:Array<String> = [];

    var assetPath:String = funkin.assets.Paths.formatRelative(_data.assetPath, 'gameplay/characters/$characterId');

    var baseAssetLibrary:String = Paths.getLibrary(assetPath);
    var baseAssetPath:String = Paths.stripLibrary(assetPath);

    var mainTexture:FlxAnimateFrames = Paths.getAnimateAtlas(baseAssetPath, baseAssetLibrary, getAtlasSettings());
    textureList.push(mainTexture);

    this.useRenderTexture = getAtlasSettings().useRenderTexture;
    this.applyStageMatrix = getAtlasSettings().applyStageMatrix;

    _atlasLease.hold(mainTexture.parent);

    for (animation in _data.animations)
    {
      if (animation.assetPath == null) continue;
      // Sparrow images and Animate directories can share the same logical path.
      var assetKey = (animation.renderType == "sparrow" ? "sparrow:" : "animateatlas:") + animation.assetPath;
      if (addedAssetPaths.contains(assetKey)) continue;

      switch (animation.renderType)
      {
        case "sparrow":
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
            log('Multi-Animate atlas could not load subtexture: ${animation.assetPath}');
            FlxG.log.error('Multi-Animate atlas could not load subtexture: ${animation.assetPath}');
            continue;
          }
          else
          {
            log('Concatenating sparrow atlas: ${animation.assetPath}');
            _atlasLease.hold(subTexture.parent);
            // This breaks mix-and-match for some reason.
            // TODO: Re-enable this line once a proper fix is found.
            // - Abnormal
            // funkin.assets.Assets.cacheFlxGraphic(Paths.image(animation.assetPath));
          }

          textureList.push(subTexture);
          _sparrowSources.set(animation.assetPath, subTexture);

        default:
          var atlasPath:String = funkin.assets.Paths.formatRelative(animation.assetPath, 'gameplay/characters/$characterId');

          var subAssetLibrary:String = Paths.getLibrary(atlasPath);
          var subAssetPath:String = Paths.stripLibrary(atlasPath);

          var subTexture:Null<FlxAnimateFrames> = null;
          try subTexture = Paths.getAnimateAtlas(subAssetPath, subAssetLibrary, cast animation.atlasSettings ?? getAtlasSettings())
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

          // The combined frame collection is character-owned, not the cached source.
          if (subTexture != mainTexture) textureList.push(subTexture);
      }

      addedAssetPaths.push(assetKey);
    }

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

    _ownedFrames = new BorrowedAnimateFrames(mainTexture);
    textureList[0] = _ownedFrames;
    this.frames = FlxAnimateFrames.combineAtlas(textureList);
    this.setScale(_data.scale);
  }

  function loadAnimations():Void
  {
    log('Loading ${_data.animations.length} animations for ${characterId}');

    for (anim in _data.animations)
    {
      switch (anim.renderType)
      {
        case "sparrow":
          var source = anim.assetPath == null ? null : _sparrowSources.get(anim.assetPath);
          if (source == null || !SparrowAnimationSource.register(this, anim, source)) FlxAnimationUtil.addAtlasAnimation(this, anim);
        default:
          FlxAnimationUtil.addTextureAtlasAnimationFromSource(this, anim, anim.assetPath == null ? null : _animateSources.get(anim.assetPath));
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
    log('Successfully loaded ${animationNames.length} animations for ${characterId}');
  }

  /**
   * Get the configuration for the texture atlas.
   * @return The configuration for the texture atlas.
   */
  public function getAtlasSettings():AtlasSpriteSettings
  {
    return cast _data.atlasSettings;
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
    _animateSources.clear();
    _sparrowSources.clear();

    super.destroy();
    _atlasLease.release();
  }

  public override function toString():String
  {
    return 'MultiAnimateAtlasCharacter($characterName ($characterId), pos=[$x, $y])';
  }
}
