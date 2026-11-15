package funkin.play.character;

import funkin.graphics.FunkinSprite;
import flixel.FlxCamera;
import flixel.math.FlxMatrix;
import flixel.math.FlxRect;
import funkin.util.assets.FlxAnimationUtil;
import funkin.modding.events.ScriptEvent;
import funkin.data.animation.AnimationData;
import funkin.data.character.CharacterData.CharacterRenderType;

/**
 * An AnimateAtlasCharacter is a Character which is rendered by
 * displaying an animation derived from an Adobe Animate texture atlas spritesheet file.
 *
 * BaseCharacter has game logic, AnimateAtlasCharacter has only rendering logic.
 * KEEP THEM SEPARATE!
 */
class AnimateAtlasCharacter extends BaseCharacter
{
  var legacyAtlasHasDrawn:Bool = false;
  var legacyPreviousWidth:Null<Float> = null;
  var legacyPreviousHeight:Null<Float> = null;

  public function new(id:String)
  {
    super(id, CharacterRenderType.AnimateAtlas);
  }

  override function onCreate(event:ScriptEvent):Void
  {
    // Display a custom scope for debugging purposes.
    #if FEATURE_DEBUG_TRACY
    cpp.vm.tracy.TracyProfiler.zoneScoped('AnimateAtlasCharacter.create(${this.characterId})');
    #end

    log('Loading assets for Animate Atlas character "${characterId}"');
    loadAtlas();
    loadAnimations();

    log('Successfully loaded texture atlas for ${characterId} with ${_data.animations.length} animations.');
    super.onCreate(event);
  }

  function loadAtlas():Void
  {
    log('Loading sprite atlas for ${characterId}.');
    var assetPath:String = Paths.stripLibrary(funkin.assets.Paths.formatRelative(_data.assetPath, 'gameplay/characters/$characterId'));

    loadTextureAtlas(assetPath, getAtlasSettings());

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

    this.setScale(_data.scale);
  }

  function loadAnimations():Void
  {
    log('Loading ${_data.animations.length} animations for ${characterId}');

    FlxAnimationUtil.addTextureAtlasAnimations(this, _data.animations);

    for (anim in _data.animations)
    {
      // Older Animate Atlas characters accepted either a frame label or a symbol
      // for the prefix. Some atlases register a missing label as zero frames.
      var loaded = animation.getByName(anim.name);
      if ((loaded == null || loaded.numFrames == 0) && anim.animType != 'symbol' && anim.prefix != null
        && library != null && library.getSymbol(anim.prefix) != null)
      {
        var frameRate = anim.frameRate ?? 24;
        var looped = anim.looped ?? false;
        var flipX = anim.flipX ?? false;
        var flipY = anim.flipY ?? false;
        if (anim.frameIndices != null && anim.frameIndices.length > 0)
          this.anim.addBySymbolIndices(anim.name, anim.prefix, anim.frameIndices, frameRate, looped, flipX, flipY);
        else
          this.anim.addBySymbol(anim.name, anim.prefix, frameRate, looped, flipX, flipY);
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
    log('[ATLASCHAR] Successfully loaded ${animationNames.length} animations for ${characterId}');
  }

  /**
   * Get the configuration for the texture atlas.
   * @return The configuration for the texture atlas.
   */
  public function getAtlasSettings():AtlasSpriteSettings
  {
    if (_data.legacyAtlasStageMatrix)
    {
      // The old child renderer drew in the exported stage coordinates.
      // Return a fresh object: the validated defaults are shared by characters.
      return {
        swfMode: true,
        applyStageMatrix: true,
        postStageMatrixApply: false
      };
    }
    return cast _data.atlasSettings;
  }

  override function prepareAnimateMatrix(matrix:FlxMatrix, camera:FlxCamera, bounds:FlxRect):Void
  {
    super.prepareAnimateMatrix(matrix, camera, bounds);
    // The old child renderer mirrored around its last drawn frame dimensions,
    // while the new renderer mirrors around the whole animation bounds.
    // Keep this correction to the axis-aligned, non-pixel-snapped path.
    if (_data?.legacyAtlasStageMatrix != true || !isAnimate || !applyStageMatrix || postStageMatrixApply || useRenderTexture
      || library == null || timeline == null || angle != 0 || skew.x != 0 || skew.y != 0
      || library.matrix.b != 0 || library.matrix.c != 0 || isPixelPerfectRender(camera)) return;

    var flipH = @:privateAccess checkFlipX();
    var flipV = @:privateAccess checkFlipY();
    if (!flipH && !flipV) return;

    // The old renderer used the dimensions left by the preceding draw.
    // The current-frame bounds are only a fallback before our first draw.
    var current:Null<FlxRect> = null;
    if ((flipH && legacyPreviousWidth == null) || (flipV && legacyPreviousHeight == null))
      current = timeline.getBounds(animation.frameIndex, false, null, null, true, true);
    if (flipH)
    {
      var oldWidth = legacyPreviousWidth ?? (current?.width ?? 0) * Math.abs(library.matrix.a * scale.x);
      var deltaX = (2 * (library.matrix.tx + library.matrix.a * bounds.x) + library.matrix.a * bounds.width - oldWidth) * scale.x;
      matrix.translate(-deltaX, 0);
    }
    if (flipV)
    {
      var oldHeight = legacyPreviousHeight ?? (current?.height ?? 0) * Math.abs(library.matrix.d * scale.y);
      var deltaY = (2 * (library.matrix.ty + library.matrix.d * bounds.y) + library.matrix.d * bounds.height - oldHeight) * scale.y;
      matrix.translate(0, -deltaY);
    }
    current?.put();
  }

  public override function updateHitbox():Void
  {
    super.updateHitbox();
    if (_data?.legacyAtlasPlacement != true) return;
    // The former parent sprite had no frame; its child supplied bounds only
    // after drawing. Stage placement and initial camera focus therefore used 0.
    origin.set(0, 0);
    offset.set(0, 0);
    if (!legacyAtlasHasDrawn)
    {
      width = 0;
      height = 0;
    }
  }

  public override function draw():Void
  {
    super.draw();
    if (_data?.legacyAtlasStageMatrix == true && isAnimate && applyStageMatrix && !postStageMatrixApply && !useRenderTexture
      && library != null && timeline != null && angle == 0 && skew.x == 0 && skew.y == 0
      && library.matrix.b == 0 && library.matrix.c == 0)
    {
      var drawn = timeline.getBounds(animation.frameIndex, false, null, null, true, true);
      legacyPreviousWidth = drawn.width * Math.abs(library.matrix.a * scale.x);
      legacyPreviousHeight = drawn.height * Math.abs(library.matrix.d * scale.y);
      drawn.put();
    }
    else
    {
      legacyPreviousWidth = null;
      legacyPreviousHeight = null;
    }
    if (_data?.legacyAtlasPlacement == true && !legacyAtlasHasDrawn)
    {
      legacyAtlasHasDrawn = true;
      width = Math.abs(scale.x) * frameWidth;
      height = Math.abs(scale.y) * frameHeight;
    }
  }

  static function log(message:String):Void
  {
    trace(' ATLASCHAR '.bold().bg_blue() + ' $message');
  }

  public override function toString():String
  {
    return 'AnimateAtlasCharacter($characterName ($characterId), pos=[$x, $y])';
  }
}
