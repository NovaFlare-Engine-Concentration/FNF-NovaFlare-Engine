package funkin.play.notes.notestyle;

import funkin.play.Countdown;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.graphics.frames.FlxFramesCollection;
import funkin.data.animation.AnimationData;
import funkin.data.IRegistryEntry;
import funkin.graphics.FunkinSprite;
import funkin.data.notestyle.NoteStyleData;
import funkin.data.notestyle.NoteStyleRegistry;
import funkin.util.assets.FlxAnimationUtil;

using funkin.data.animation.AnimationData.AnimationDataUtil;

/**
 * Holds the data for what assets to use for a note style,
 * and provides convenience methods for building sprites based on them.
 */
@:nullSafety
class NoteStyle implements IRegistryEntry<NoteStyleData>
{
  /**
   * Note style data as parsed from the JSON file.
   */
  public final _data:NoteStyleData;

  /**
   * The note style to use if this one doesn't have a certain asset.
   * This can be recursive, ehe.
   */
  var fallback(get, never):Null<NoteStyle>;

  function get_fallback():Null<NoteStyle>
  {
    if (_data == null || _data.fallback == null) return null;
    return NoteStyleRegistry.instance.fetchEntry(_data.fallback);
  }

  /**
   * Determine a list of the assets of the given type that are required to display this note style.
   * @param type The type of asset to query.
   * @return The list of assets to query.
   */
  public function queryAssets(type:funkin.assets.Assets.AssetType):Array<funkin.assets.Paths.AssetPath>
  {
    switch (type)
    {
      case IMAGE:
        var paths = [
          // TODO: Make these functions return asset paths directly, then rewrite queryAssets properly!

          // Note sprites
          getHoldNoteAssetPath(),

        ].filterNull().map((path) -> funkin.assets.Paths.image(path));

        var strumlinePath = getStrumlineAssetPath();
        if (strumlinePath != null) paths.push(funkin.assets.Paths.file(strumlinePath, 'png', true, getAssetLibrary(getStrumlineAssetPath(true))));
        var notePath = getNoteAssetPath();
        if (notePath != null) paths.push(funkin.assets.Paths.file(notePath, 'png', true, getAssetLibrary(getNoteAssetPath(true))));
        var splashPath = isNoteSplashEnabled() ? getSplashAssetPath() : null;
        if (splashPath != null) paths.push(funkin.assets.Paths.file(splashPath, 'png', true, getAssetLibrary(getSplashAssetPath(true))));
        if (isHoldNoteCoverEnabled())
        {
          for (direction in [NoteDirection.LEFT, NoteDirection.DOWN, NoteDirection.UP, NoteDirection.RIGHT])
          {
            var coverPath = getHoldCoverDirectionAssetPath(direction);
            if (coverPath != null) paths.push(funkin.assets.Paths.file(coverPath, 'png', true, getAssetLibrary(getHoldCoverDirectionAssetPath(direction, true))));
          }
        }

        for (step in [Countdown.CountdownStep.THREE, Countdown.CountdownStep.TWO, Countdown.CountdownStep.ONE, Countdown.CountdownStep.GO])
        {
          var countdownPath = buildCountdownSpritePath(step);
          if (countdownPath != null) paths.push(funkin.assets.Paths.file(countdownPath, 'png', true, buildCountdownSpriteLibrary(step)));
        }
        for (rating in ['sick', 'good', 'bad', 'shit'])
        {
          var judgementPath = buildJudgementSpritePath(rating);
          if (judgementPath != null) paths.push(funkin.assets.Paths.file(judgementPath, 'png', true, getAssetLibrary(buildJudgementSpritePath(rating, true))));
        }
        for (digit in 0...10)
        {
          var comboPath = buildComboNumSpritePath(digit);
          if (comboPath != null) paths.push(funkin.assets.Paths.file(comboPath, 'png', true, getAssetLibrary(buildComboNumSpritePath(digit, true))));
        }

        return paths;
      case XML:
        var paths:Array<funkin.assets.Paths.AssetPath> = [];
        var strumlinePath = getStrumlineAssetPath();
        if (strumlinePath != null) paths.push(funkin.assets.Paths.file(strumlinePath, 'xml', true, getAssetLibrary(getStrumlineAssetPath(true))));
        var notePath = getNoteAssetPath();
        if (notePath != null) paths.push(funkin.assets.Paths.file(notePath, 'xml', true, getAssetLibrary(getNoteAssetPath(true))));
        var splashPath = isNoteSplashEnabled() ? getSplashAssetPath() : null;
        if (splashPath != null) paths.push(funkin.assets.Paths.file(splashPath, 'xml', true, getAssetLibrary(getSplashAssetPath(true))));
        if (isHoldNoteCoverEnabled())
        {
          for (direction in [NoteDirection.LEFT, NoteDirection.DOWN, NoteDirection.UP, NoteDirection.RIGHT])
          {
            var coverPath = getHoldCoverDirectionAssetPath(direction);
            if (coverPath != null) paths.push(funkin.assets.Paths.file(coverPath, 'xml', true, getAssetLibrary(getHoldCoverDirectionAssetPath(direction, true))));
          }
        }
        return paths;
      case SOUND:
        return [getCountdownSoundPath(THREE), getCountdownSoundPath(TWO), getCountdownSoundPath(ONE), getCountdownSoundPath(GO)].map((path) ->
        {
          if (path == null) return null;
          return funkin.assets.Paths.sound(path);
        }).filterNull();
      default:
        return [];
    }
  }

  /**
   * @param id The ID of the JSON file to parse.
   */
  public function new(id:String, ?params:Dynamic)
  {
    this.id = id;
    _data = _fetchData(id);
  }

  /**
   * Get the readable name of the note style.
   * @return String
   */
  public function getName():String
  {
    return _data.name;
  }

  /**
   * Get the author of the note style.
   * @return String
   */
  public function getAuthor():String
  {
    return _data.author;
  }

  /**
   * Get the note style ID of the parent note style.
   * @return The string ID, or `null` if there is no parent.
   */
  public function getFallbackID():Null<String>
  {
    return _data.fallback;
  }

  public function buildNoteSprite(target:NoteSprite):Void
  {
    // Apply the note sprite frames.
    var atlas:Null<FlxAtlasFrames> = buildNoteFrames(false);

    if (atlas == null)
    {
      throw 'Could not load spritesheet for note style: $id';
    }

    var needsRebuild:Bool = target.frames != atlas || target.builtNoteStyleId != id || target.builtNoteStyle != this;

    if (needsRebuild)
    {
      target.frames = atlas;
    }

    target.antialiasing = !(_data.assets?.note?.isPixel ?? false);

    var noteOffsets:Array<Float> = getNoteOffsets();
    target.offset.set(noteOffsets[0], noteOffsets[1]);

    // Apply the animations.
    if (needsRebuild)
    {
      buildNoteAnimations(target);
      target.builtNoteStyleId = id;
      target.builtNoteStyle = this;
    }

    // Set the scale.
    var scale = getNoteScale();
    switch (_data.legacyNoteSizing)
    {
      case 1: target.setGraphicSize(Strumline.STRUMLINE_SIZE);
      case 2: target.setGraphicSize(Strumline.STRUMLINE_SIZE * scale);
      default: target.scale.set(scale, scale);
    }
    target.updateHitbox();
  }

  function getNoteAssetLibrary():Null<String>
  {
    // library:path
    var parts = getNoteAssetPath(true)?.split(Constants.LIBRARY_SEPARATOR) ?? [];
    if (parts.length == 0) return null;
    if (parts.length == 1) return null;
    return parts[0];
  }

  var noteFrames:Null<FlxAtlasFrames> = null;
  var noteFramesPath:Null<String> = null;
  var noteFramesLibrary:Null<String> = null;

  function buildNoteFrames(force:Bool = false):Null<FlxAtlasFrames>
  {
    var noteAssetPath = getNoteAssetPath();
    if (noteAssetPath == null)
    {
      FlxG.log.warn('Note asset path not found: ${id}');
      return null;
    }

    var noteLibrary = getAssetLibrary(getNoteAssetPath(true));
    if (!funkin.assets.Assets.isFlxGraphicCached(funkin.assets.Paths.file(noteAssetPath, 'png', true, noteLibrary)))
    {
      FlxG.log.warn('Note texture is not cached: ${noteAssetPath}');
    }

    // Purge the note frames if the cached atlas is invalid.
    @:nullSafety(Off)
    {
      if (noteFrames?.parent?.isDestroyed ?? true) noteFrames = null;
    }
    if (noteFramesPath != noteAssetPath || noteFramesLibrary != noteLibrary) noteFrames = null;

    if (noteFrames != null && !force) return noteFrames;

    noteFrames = Paths.getSparrowAtlas(noteAssetPath, noteLibrary);

    if (noteFrames == null)
    {
      throw 'Could not load note frames for note style: $id';
    }

    noteFramesPath = noteAssetPath;
    noteFramesLibrary = noteLibrary;
    return noteFrames;
  }

  /** Bridges for zero-argument 0.9 compiled scripts; old String methods remain unchanged. */
  @:keep
  public function __nfPreviewNoteAssetPath():Null<funkin.assets.Paths.AssetPath>
  {
    return cast originfunkin.compat.PreviewNoteStylePaths.resolve(this, 'getNoteAssetPath', []);
  }

  @:keep
  public function __nfPreviewStrumlineAssetPath():Null<funkin.assets.Paths.AssetPath>
  {
    return cast originfunkin.compat.PreviewNoteStylePaths.resolve(this, 'getStrumlineAssetPath', []);
  }

  /** One-argument 0.9 compiled path APIs; the historical String APIs remain available. */
  @:keep
  public function __nfPreviewCountdownSoundPath(step:Countdown.CountdownStep):Null<funkin.assets.Paths.AssetPath>
  {
    return cast originfunkin.compat.PreviewNoteStylePaths.resolve(this, 'getCountdownSoundPath', [step]);
  }

  @:keep
  public function __nfPreviewJudgementSpritePath(rating:String):Null<funkin.assets.Paths.AssetPath>
  {
    return cast originfunkin.compat.PreviewNoteStylePaths.resolve(this, 'buildJudgementSpritePath', [rating]);
  }

  @:keep
  public function __nfPreviewComboNumSpritePath(digit:Int):Null<funkin.assets.Paths.AssetPath>
  {
    return cast originfunkin.compat.PreviewNoteStylePaths.resolve(this, 'buildComboNumSpritePath', [digit]);
  }

  @:keep
  public function __nfPreviewHoldCoverDirectionAssetPath(direction:NoteDirection):Null<funkin.assets.Paths.AssetPath>
  {
    return cast originfunkin.compat.PreviewNoteStylePaths.resolve(this, 'getHoldCoverDirectionAssetPath', [direction]);
  }

  /** Bridge the zero-argument 0.9 compiled API without changing the historical String API. */
  @:keep
  public function __nfPreviewHoldNoteAssetPath():Null<funkin.assets.Paths.AssetPath>
  {
    return cast originfunkin.compat.PreviewNoteStylePaths.resolve(this, 'getHoldNoteAssetPath', []);
  }

  /** Resolve the public 0.9 path contract without changing historical callers. */
  @:nullSafety(Off)
  function resolvePreviewAssetPath(method:String, args:Array<Dynamic>, ?overridePath:String):Null<funkin.assets.Paths.AssetPath>
  {
    var raw = overridePath ?? resolvePreviewRawPath(method, args);
    if (raw == null) return null;
    var withoutExt = haxe.io.Path.withoutExtension(raw);
    var parts = withoutExt.split(Constants.LIBRARY_SEPARATOR);
    var library:Null<String> = null;
    var filePath = withoutExt;
    if (parts.length == 2)
    {
      library = parts[0];
      filePath = parts[1];
    }
    var ext = method == 'getCountdownSoundPath' ? Constants.EXT_SOUND : 'png';
    var asset = funkin.assets.Paths.file(filePath, ext, false, library);
    return asset.exists() ? asset : null;
  }

  /** Inspect data directly so a scripted override is not invoked a second time. */
  @:nullSafety(Off)
  function resolvePreviewRawPath(method:String, args:Array<Dynamic>):Null<String>
  {
    if (method == 'getHoldCoverDirectionAssetPath') return resolvePreviewHoldCoverRaw(cast args[0]);
    var field:Null<String> = switch (method)
    {
      case 'getNoteAssetPath': 'note';
      case 'getHoldNoteAssetPath': 'holdNote';
      case 'getStrumlineAssetPath': 'noteStrumline';
      case 'getSplashAssetPath': 'noteSplash';
      case 'buildJudgementSpritePath':
        switch (cast(args[0], String))
        {
          case 'sick': 'judgementSick';
          case 'good': 'judgementGood';
          case 'bad': 'judgementBad';
          case 'shit': 'judgementShit';
          default: null;
        }
      case 'buildComboNumSpritePath':
        var digit:Int = cast args[0];
        digit >= 0 && digit <= 9 ? 'comboNumber$digit' : null;
      case 'getCountdownSoundPath' | 'buildCountdownSpritePath':
        switch (cast(args[0], Countdown.CountdownStep))
        {
          case THREE: 'countdownThree';
          case TWO: 'countdownTwo';
          case ONE: 'countdownOne';
          case GO: 'countdownGo';
          default: null;
        }
      default: null;
    }
    if (field == null) return null;
    var assets:Dynamic = _data?.assets;
    var item:Dynamic = assets == null ? null : Reflect.field(assets, field);
    var raw:Null<String> = item == null ? null : method == 'getCountdownSoundPath'
      ? (item.data == null ? null : item.data.audioPath) : item.assetPath;
    return raw ?? fallback?.resolvePreviewRawPath(method, args);
  }

  @:nullSafety(Off)
  function resolvePreviewHoldCoverRaw(direction:NoteDirection):Null<String>
  {
    var path:Null<String> = switch (direction)
    {
      case LEFT: _data?.assets?.holdNoteCover?.data?.left?.assetPath;
      case DOWN: _data?.assets?.holdNoteCover?.data?.down?.assetPath;
      case UP: _data?.assets?.holdNoteCover?.data?.up?.assetPath;
      case RIGHT: _data?.assets?.holdNoteCover?.data?.right?.assetPath;
    };
    return path ?? resolvePreviewHoldCoverRootRaw();
  }

  @:nullSafety(Off)
  function resolvePreviewHoldCoverRootRaw():Null<String>
  {
    return _data?.assets?.holdNoteCover?.assetPath ?? fallback?.resolvePreviewHoldCoverRootRaw();
  }

  public function getNoteAssetPath(raw:Bool = false):Null<String>
  {
    if (raw)
    {
      var rawPath:Null<String> = _data?.assets?.note?.assetPath;
      if (rawPath == null) return fallback?.getNoteAssetPath(true);
      return rawPath;
    }

    // library:path
    var parts = getNoteAssetPath(true)?.split(Constants.LIBRARY_SEPARATOR) ?? [];
    if (parts.length == 0) return null;
    if (parts.length == 1) return getNoteAssetPath(true);
    return parts[1];
  }

  function buildNoteAnimations(target:NoteSprite):Void
  {
    var leftData:Null<AnimationData> = fetchNoteAnimationData(LEFT);
    if (leftData != null) target.animation.addByPrefix(
      'purpleScroll',
      leftData.prefix ?? '',
      leftData.frameRate ?? 24,
      leftData.looped ?? false,
      leftData.flipX,
      leftData.flipY
    );
    var downData:Null<AnimationData> = fetchNoteAnimationData(DOWN);
    if (downData != null) target.animation.addByPrefix(
      'blueScroll',
      downData.prefix ?? '',
      downData.frameRate ?? 24,
      downData.looped ?? false,
      downData.flipX,
      downData.flipY
    );
    var upData:Null<AnimationData> = fetchNoteAnimationData(UP);
    if (upData != null) target.animation.addByPrefix(
      'greenScroll',
      upData.prefix ?? '',
      upData.frameRate ?? 24,
      upData.looped ?? false,
      upData.flipX,
      upData.flipY
    );
    var rightData:Null<AnimationData> = fetchNoteAnimationData(RIGHT);
    if (rightData != null) target.animation.addByPrefix(
      'redScroll',
      rightData.prefix ?? '',
      rightData.frameRate ?? 24,
      rightData.looped ?? false,
      rightData.flipX,
      rightData.flipY
    );
  }

  public function isNoteAnimated():Bool
  {
    return _data.assets?.note?.animated ?? fallback?.isNoteAnimated() ?? false;
  }

  public function getNoteScale():Float
  {
    return _data.assets?.note?.scale ?? fallback?.getNoteScale() ?? 1.0;
  }

  static final ZERO_OFFSETS:Array<Float> = [0.0, 0.0];

  public function getNoteOffsets():Array<Float>
  {
    return _data?.assets?.note?.offsets ?? fallback?.getNoteOffsets() ?? ZERO_OFFSETS;
  }

  function fetchNoteAnimationData(dir:NoteDirection):Null<AnimationData>
  {
    var result:Null<AnimationData> = switch (dir)
    {
      case LEFT:
        _data.assets?.note?.data?.left?.toNamed();
      case DOWN:
        _data.assets?.note?.data?.down?.toNamed();
      case UP:
        _data.assets?.note?.data?.up?.toNamed();
      case RIGHT:
        _data.assets?.note?.data?.right?.toNamed();
    };

    return result ?? fallback?.fetchNoteAnimationData(dir);
  }

  public function getHoldNoteAssetPath(raw:Bool = false):Null<String>
  {
    if (raw)
    {
      var rawPath:Null<String> = _data?.assets?.holdNote?.assetPath;
      return rawPath ?? fallback?.getHoldNoteAssetPath(true);
    }

    // library:path
    var parts = getHoldNoteAssetPath(true)?.split(Constants.LIBRARY_SEPARATOR) ?? [];
    if (parts.length == 0) return null;
    if (parts.length == 1) return Paths.image(parts[0]);
    return Paths.image(parts[1], parts[0]);
  }

  public function isHoldNotePixel():Bool
  {
    return _data?.assets?.holdNote?.isPixel ?? fallback?.isHoldNotePixel() ?? false;
  }

  public function fetchHoldNoteScale():Float
  {
    return _data?.assets?.holdNote?.scale ?? fallback?.fetchHoldNoteScale() ?? 1.0;
  }

  public function getHoldNoteOffsets():Array<Float>
  {
    return _data?.assets?.holdNote?.offsets ?? fallback?.getHoldNoteOffsets() ?? ZERO_OFFSETS;
  }

  public function applyStrumlineFrames(target:StrumlineNote):Void
  {
    // TODO: Add support for multi-Sparrow.
    // Will be less annoying after this is merged: https://github.com/HaxeFlixel/flixel/pull/2772

    var assetPath = funkin.assets.Paths.file(getStrumlineAssetPath() ?? '', 'png', true, getAssetLibrary(getStrumlineAssetPath(true)));
    var noteFrames = funkin.assets.Assets.getSparrowAtlas(assetPath);

    if (noteFrames == null)
    {
      throw 'Could not load spritesheet for note style: $id';
    }

    target.frames = noteFrames;

    target.scale.set(_data.assets.noteStrumline?.scale ?? 1.0);
    target.antialiasing = !(_data.assets.noteStrumline?.isPixel ?? false);
  }

  public function getStrumlineAssetPath(raw:Bool = false):Null<String>
  {
    if (raw)
    {
      return _data?.assets?.noteStrumline?.assetPath ?? fallback?.getStrumlineAssetPath(true);
    }

    // library:path
    var parts = getStrumlineAssetPath(true)?.split(Constants.LIBRARY_SEPARATOR) ?? [];
    if (parts.length <= 1) return getStrumlineAssetPath(true);
    return parts[1];
  }

  public function applyStrumlineAnimations(target:StrumlineNote, dir:NoteDirection):Void
  {
    FlxAnimationUtil.addAtlasAnimations(target, getStrumlineAnimationData(dir));
  }

  /**
   * Fetch the animation data for the strumline.
   * NOTE: This function only queries the fallback note style if all the animations are missing for a given direction.
   *
   * @param dir The direction to fetch the animation data for.
   * @return The animation data for the strumline in that direction.
   */
  function getStrumlineAnimationData(dir:NoteDirection):Array<AnimationData>
  {
    var result:Array<Null<AnimationData>> = switch (dir)
    {
      case NoteDirection.LEFT:
        [
          _data.assets.noteStrumline?.data?.leftStatic?.toNamed('static'),
          _data.assets.noteStrumline?.data?.leftPress?.toNamed('press'),
          _data.assets.noteStrumline?.data?.leftConfirm?.toNamed('confirm'),
          _data.assets.noteStrumline?.data?.leftConfirmHold?.toNamed('confirm-hold'),
        ];
      case NoteDirection.DOWN:
        [
          _data.assets.noteStrumline?.data?.downStatic?.toNamed('static'),
          _data.assets.noteStrumline?.data?.downPress?.toNamed('press'),
          _data.assets.noteStrumline?.data?.downConfirm?.toNamed('confirm'),
          _data.assets.noteStrumline?.data?.downConfirmHold?.toNamed('confirm-hold'),
        ];
      case NoteDirection.UP:
        [
          _data.assets.noteStrumline?.data?.upStatic?.toNamed('static'),
          _data.assets.noteStrumline?.data?.upPress?.toNamed('press'),
          _data.assets.noteStrumline?.data?.upConfirm?.toNamed('confirm'),
          _data.assets.noteStrumline?.data?.upConfirmHold?.toNamed('confirm-hold'),
        ];
      case NoteDirection.RIGHT:
        [
          _data.assets.noteStrumline?.data?.rightStatic?.toNamed('static'),
          _data.assets.noteStrumline?.data?.rightPress?.toNamed('press'),
          _data.assets.noteStrumline?.data?.rightConfirm?.toNamed('confirm'),
          _data.assets.noteStrumline?.data?.rightConfirmHold?.toNamed('confirm-hold'),
        ];
      default:
        [];
    };

    // New variable so we can change the type.
    var filteredResult:Array<AnimationData> = thx.Arrays.filterNull(result);

    if (filteredResult.length == 0) return fallback?.getStrumlineAnimationData(dir) ?? [];

    return filteredResult;
  }

  public function getStrumlineOffsets():Array<Float>
  {
    return _data?.assets?.noteStrumline?.offsets ?? fallback?.getStrumlineOffsets() ?? [0.0, 0.0];
  }

  /** Convert historical target widths at the native rendering boundary. */
  public function getStrumlineScaleForFrame(frameWidth:Int):Float
  {
    var scale = getStrumlineScale();
    if ((_data.legacyNoteSizing == 1 || _data.legacyNoteSizing == 2) && frameWidth > 0)
      return Std.int(Strumline.STRUMLINE_SIZE * scale) / frameWidth;
    return scale;
  }

  public function applyStrumlineOffsets(target:StrumlineNote):Void
  {
    var offsets = getStrumlineOffsets();
    target.x += offsets[0];
    target.y += offsets[1];
  }

  public function getStrumlineScale():Float
  {
    return _data?.assets?.noteStrumline?.scale ?? fallback?.getStrumlineScale() ?? 1.0;
  }

  public function isNoteSplashEnabled():Bool
  {
    return _data?.assets?.noteSplash?.data?.enabled ?? fallback?.isNoteSplashEnabled() ?? false;
  }

  public function isHoldNoteCoverEnabled():Bool
  {
    return _data?.assets?.holdNoteCover?.data?.enabled ?? fallback?.isHoldNoteCoverEnabled() ?? false;
  }

  /**
   * Build a sprite for the given step of the countdown.
   * @param step
   * @return A `FunkinSprite`, or `null` if no graphic is available for this step.
   */
  public function buildCountdownSprite(step:Countdown.CountdownStep):Null<FunkinSprite>
  {
    var result = new FunkinSprite();

    switch (step)
    {
      case THREE:
        if (_data.assets.countdownThree == null) return fallback?.buildCountdownSprite(step);
        var assetPath = buildCountdownSpritePath(step);
        if (assetPath == null) return null;
        result.loadTexture(assetPath, buildCountdownSpriteLibrary(step));
        result.scale.x = _data.assets.countdownThree?.scale ?? 1.0;
        result.scale.y = _data.assets.countdownThree?.scale ?? 1.0;
      case TWO:
        if (_data.assets.countdownTwo == null) return fallback?.buildCountdownSprite(step);
        var assetPath = buildCountdownSpritePath(step);
        if (assetPath == null) return null;
        result.loadTexture(assetPath, buildCountdownSpriteLibrary(step));
        result.scale.x = _data.assets.countdownTwo?.scale ?? 1.0;
        result.scale.y = _data.assets.countdownTwo?.scale ?? 1.0;
      case ONE:
        if (_data.assets.countdownOne == null) return fallback?.buildCountdownSprite(step);
        var assetPath = buildCountdownSpritePath(step);
        if (assetPath == null) return null;
        result.loadTexture(assetPath, buildCountdownSpriteLibrary(step));
        result.scale.x = _data.assets.countdownOne?.scale ?? 1.0;
        result.scale.y = _data.assets.countdownOne?.scale ?? 1.0;
      case GO:
        if (_data.assets.countdownGo == null) return fallback?.buildCountdownSprite(step);
        var assetPath = buildCountdownSpritePath(step);
        if (assetPath == null) return null;
        result.loadTexture(assetPath, buildCountdownSpriteLibrary(step));
        result.scale.x = _data.assets.countdownGo?.scale ?? 1.0;
        result.scale.y = _data.assets.countdownGo?.scale ?? 1.0;
      default:
        // TODO: Do something here?
        return null;
    }

    result.scrollFactor.set(0, 0);
    result.antialiasing = !isCountdownSpritePixel(step);
    result.updateHitbox();

    return result;
  }

  public function buildCountdownSpritePath(step:Countdown.CountdownStep):Null<String>
  {
    var basePath:Null<String> = null;
    switch (step)
    {
      case THREE:
        basePath = _data.assets.countdownThree?.assetPath;
      case TWO:
        basePath = _data.assets.countdownTwo?.assetPath;
      case ONE:
        basePath = _data.assets.countdownOne?.assetPath;
      case GO:
        basePath = _data.assets.countdownGo?.assetPath;
      default:
        basePath = null;
    }

    if (basePath == null) return fallback?.buildCountdownSpritePath(step);

    var parts = basePath?.split(Constants.LIBRARY_SEPARATOR) ?? [];
    if (parts.length < 1) return null;
    if (parts.length == 1) return parts[0];

    return parts[1];
  }

  function buildCountdownSpriteLibrary(step:Countdown.CountdownStep):Null<String>
  {
    var basePath:Null<String> = null;
    switch (step)
    {
      case THREE:
        basePath = _data.assets.countdownThree?.assetPath;
      case TWO:
        basePath = _data.assets.countdownTwo?.assetPath;
      case ONE:
        basePath = _data.assets.countdownOne?.assetPath;
      case GO:
        basePath = _data.assets.countdownGo?.assetPath;
      default:
        basePath = null;
    }

    if (basePath == null) return fallback?.buildCountdownSpriteLibrary(step);

    var parts = basePath?.split(Constants.LIBRARY_SEPARATOR) ?? [];
    if (parts.length <= 1) return null;

    return parts[0];
  }

  public function isCountdownSpritePixel(step:Countdown.CountdownStep):Bool
  {
    switch (step)
    {
      case THREE:
        var result = _data.assets.countdownThree?.isPixel;
        if (result == null) result = fallback?.isCountdownSpritePixel(step) ?? false;
        return result;
      case TWO:
        var result = _data.assets.countdownTwo?.isPixel;
        if (result == null) result = fallback?.isCountdownSpritePixel(step) ?? false;
        return result;
      case ONE:
        var result = _data.assets.countdownOne?.isPixel;
        if (result == null) result = fallback?.isCountdownSpritePixel(step) ?? false;
        return result;
      case GO:
        var result = _data.assets.countdownGo?.isPixel;
        if (result == null) result = fallback?.isCountdownSpritePixel(step) ?? false;
        return result;
      default:
        return false;
    }
  }

  public function getCountdownSpriteOffsets(step:Countdown.CountdownStep):Array<Float>
  {
    switch (step)
    {
      case THREE:
        var result = _data.assets.countdownThree?.offsets;
        if (result == null) result = fallback?.getCountdownSpriteOffsets(step) ?? [0, 0];
        return result;
      case TWO:
        var result = _data.assets.countdownTwo?.offsets;
        if (result == null) result = fallback?.getCountdownSpriteOffsets(step) ?? [0, 0];
        return result;
      case ONE:
        var result = _data.assets.countdownOne?.offsets;
        if (result == null) result = fallback?.getCountdownSpriteOffsets(step) ?? [0, 0];
        return result;
      case GO:
        var result = _data.assets.countdownGo?.offsets;
        if (result == null) result = fallback?.getCountdownSpriteOffsets(step) ?? [0, 0];
        return result;
      default:
        return [0, 0];
    }
  }

  public function getCountdownSoundPath(step:Countdown.CountdownStep, raw:Bool = false):Null<String>
  {
    if (raw)
    {
      // TODO: figure out why ?. didn't work here
      var rawPath:Null<String> = switch (step)
      {
        case Countdown.CountdownStep.THREE:
          _data.assets.countdownThree?.data?.audioPath;
        case Countdown.CountdownStep.TWO:
          _data.assets.countdownTwo?.data?.audioPath;
        case Countdown.CountdownStep.ONE:
          _data.assets.countdownOne?.data?.audioPath;
        case Countdown.CountdownStep.GO:
          _data.assets.countdownGo?.data?.audioPath;
        default:
          null;
      }

      return (rawPath == null) ? fallback?.getCountdownSoundPath(step, true) : rawPath;
    }

    // library:path
    var parts = getCountdownSoundPath(step, true)?.split(Constants.LIBRARY_SEPARATOR) ?? [];
    if (parts.length == 0) return null;
    if (parts.length == 1) return Paths.sound(parts[0]);
    return Paths.sound(parts[1], parts[0]);
  }

  public function buildJudgementSprite(rating:String):Null<FunkinSprite>
  {
    var result = new FunkinSprite();

    switch (rating)
    {
      case "sick":
        if (_data.assets.judgementSick == null) return fallback?.buildJudgementSprite(rating);
        var assetPath = buildJudgementSpritePath(rating);
        if (assetPath == null) return null;
        result.loadTexture(assetPath, getAssetLibrary(buildJudgementSpritePath(rating, true)));
        result.scale.x = _data.assets.judgementSick?.scale ?? 1.0;
        result.scale.y = _data.assets.judgementSick?.scale ?? 1.0;
      case "good":
        if (_data.assets.judgementGood == null) return fallback?.buildJudgementSprite(rating);
        var assetPath = buildJudgementSpritePath(rating);
        if (assetPath == null) return null;
        result.loadTexture(assetPath, getAssetLibrary(buildJudgementSpritePath(rating, true)));
        result.scale.x = _data.assets.judgementGood?.scale ?? 1.0;
        result.scale.y = _data.assets.judgementGood?.scale ?? 1.0;
      case "bad":
        if (_data.assets.judgementBad == null) return fallback?.buildJudgementSprite(rating);
        var assetPath = buildJudgementSpritePath(rating);
        if (assetPath == null) return null;
        result.loadTexture(assetPath, getAssetLibrary(buildJudgementSpritePath(rating, true)));
        result.scale.x = _data.assets.judgementBad?.scale ?? 1.0;
        result.scale.y = _data.assets.judgementBad?.scale ?? 1.0;
      case "shit":
        if (_data.assets.judgementShit == null) return fallback?.buildJudgementSprite(rating);
        var assetPath = buildJudgementSpritePath(rating);
        if (assetPath == null) return null;
        result.loadTexture(assetPath, getAssetLibrary(buildJudgementSpritePath(rating, true)));
        result.scale.x = _data.assets.judgementShit?.scale ?? 1.0;
        result.scale.y = _data.assets.judgementShit?.scale ?? 1.0;
      default:
        return null;
    }

    result.scrollFactor.set(0.2, 0.2);
    var isPixel = isJudgementSpritePixel(rating);
    result.antialiasing = !isPixel;
    result.pixelPerfectRender = isPixel;
    result.pixelPerfectPosition = isPixel;
    result.updateHitbox();

    return result;
  }

  public function isJudgementSpritePixel(rating:String):Bool
  {
    switch (rating)
    {
      case "sick":
        var result = _data.assets.judgementSick?.isPixel;
        if (result == null) result = fallback?.isJudgementSpritePixel(rating) ?? false;
        return result;
      case "good":
        var result = _data.assets.judgementGood?.isPixel;
        if (result == null) result = fallback?.isJudgementSpritePixel(rating) ?? false;
        return result;
      case "bad":
        var result = _data.assets.judgementBad?.isPixel;
        if (result == null) result = fallback?.isJudgementSpritePixel(rating) ?? false;
        return result;
      case "shit":
        var result = _data.assets.judgementShit?.isPixel;
        if (result == null) result = fallback?.isJudgementSpritePixel(rating) ?? false;
        return result;
      default:
        return false;
    }
  }

  public function buildJudgementSpritePath(rating:String, raw:Bool = false):Null<String>
  {
    var basePath:Null<String> = null;

    switch (rating)
    {
      case "sick":
        basePath = _data.assets.judgementSick?.assetPath;
      case "good":
        basePath = _data.assets.judgementGood?.assetPath;
      case "bad":
        basePath = _data.assets.judgementBad?.assetPath;
      case "shit":
        basePath = _data.assets.judgementShit?.assetPath;
      default:
        basePath = null;
    }
    if (basePath == null) return fallback?.buildJudgementSpritePath(rating, raw);
    if (raw) return basePath;
    var parts = basePath?.split(Constants.LIBRARY_SEPARATOR) ?? [];

    if (parts.length < 1) return null;
    if (parts.length == 1) return parts[0];
    return parts[1];
  }

  public function getJudgementSpriteOffsets(rating:String):Array<Float>
  {
    switch (rating)
    {
      case "sick":
        var result = _data.assets.judgementSick?.offsets;
        if (result == null) result = fallback?.getJudgementSpriteOffsets(rating) ?? [0, 0];
        return result;
      case "good":
        var result = _data.assets.judgementGood?.offsets;
        if (result == null) result = fallback?.getJudgementSpriteOffsets(rating) ?? [0, 0];
        return result;
      case "bad":
        var result = _data.assets.judgementBad?.offsets;
        if (result == null) result = fallback?.getJudgementSpriteOffsets(rating) ?? [0, 0];
        return result;
      case "shit":
        var result = _data.assets.judgementShit?.offsets;
        if (result == null) result = fallback?.getJudgementSpriteOffsets(rating) ?? [0, 0];
        return result;
      default:
        return [0, 0];
    }
  }

  public function buildComboNumSprite(digit:Int):Null<FunkinSprite>
  {
    var result = new FunkinSprite();

    switch (digit)
    {
      case 0:
        if (_data.assets.comboNumber0 == null) return fallback?.buildComboNumSprite(digit);
        var assetPath = buildComboNumSpritePath(digit);
        if (assetPath == null) return null;
        result.loadTexture(assetPath, getAssetLibrary(buildComboNumSpritePath(digit, true)));
        result.scale.x = _data.assets.comboNumber0?.scale ?? 1.0;
        result.scale.y = _data.assets.comboNumber0?.scale ?? 1.0;
      case 1:
        if (_data.assets.comboNumber1 == null) return fallback?.buildComboNumSprite(digit);
        var assetPath = buildComboNumSpritePath(digit);
        if (assetPath == null) return null;
        result.loadTexture(assetPath, getAssetLibrary(buildComboNumSpritePath(digit, true)));
        result.scale.x = _data.assets.comboNumber1?.scale ?? 1.0;
        result.scale.y = _data.assets.comboNumber1?.scale ?? 1.0;
      case 2:
        if (_data.assets.comboNumber2 == null) return fallback?.buildComboNumSprite(digit);
        var assetPath = buildComboNumSpritePath(digit);
        if (assetPath == null) return null;
        result.loadTexture(assetPath, getAssetLibrary(buildComboNumSpritePath(digit, true)));
        result.scale.x = _data.assets.comboNumber2?.scale ?? 1.0;
        result.scale.y = _data.assets.comboNumber2?.scale ?? 1.0;
      case 3:
        if (_data.assets.comboNumber3 == null) return fallback?.buildComboNumSprite(digit);
        var assetPath = buildComboNumSpritePath(digit);
        if (assetPath == null) return null;
        result.loadTexture(assetPath, getAssetLibrary(buildComboNumSpritePath(digit, true)));
        result.scale.x = _data.assets.comboNumber3?.scale ?? 1.0;
        result.scale.y = _data.assets.comboNumber3?.scale ?? 1.0;
      case 4:
        if (_data.assets.comboNumber4 == null) return fallback?.buildComboNumSprite(digit);
        var assetPath = buildComboNumSpritePath(digit);
        if (assetPath == null) return null;
        result.loadTexture(assetPath, getAssetLibrary(buildComboNumSpritePath(digit, true)));
        result.scale.x = _data.assets.comboNumber4?.scale ?? 1.0;
        result.scale.y = _data.assets.comboNumber4?.scale ?? 1.0;
      case 5:
        if (_data.assets.comboNumber5 == null) return fallback?.buildComboNumSprite(digit);
        var assetPath = buildComboNumSpritePath(digit);
        if (assetPath == null) return null;
        result.loadTexture(assetPath, getAssetLibrary(buildComboNumSpritePath(digit, true)));
        result.scale.x = _data.assets.comboNumber5?.scale ?? 1.0;
        result.scale.y = _data.assets.comboNumber5?.scale ?? 1.0;
      case 6:
        if (_data.assets.comboNumber6 == null) return fallback?.buildComboNumSprite(digit);
        var assetPath = buildComboNumSpritePath(digit);
        if (assetPath == null) return null;
        result.loadTexture(assetPath, getAssetLibrary(buildComboNumSpritePath(digit, true)));
        result.scale.x = _data.assets.comboNumber6?.scale ?? 1.0;
        result.scale.y = _data.assets.comboNumber6?.scale ?? 1.0;
      case 7:
        if (_data.assets.comboNumber7 == null) return fallback?.buildComboNumSprite(digit);
        var assetPath = buildComboNumSpritePath(digit);
        if (assetPath == null) return null;
        result.loadTexture(assetPath, getAssetLibrary(buildComboNumSpritePath(digit, true)));
        result.scale.x = _data.assets.comboNumber7?.scale ?? 1.0;
        result.scale.y = _data.assets.comboNumber7?.scale ?? 1.0;
      case 8:
        if (_data.assets.comboNumber8 == null) return fallback?.buildComboNumSprite(digit);
        var assetPath = buildComboNumSpritePath(digit);
        if (assetPath == null) return null;
        result.loadTexture(assetPath, getAssetLibrary(buildComboNumSpritePath(digit, true)));
        result.scale.x = _data.assets.comboNumber8?.scale ?? 1.0;
        result.scale.y = _data.assets.comboNumber8?.scale ?? 1.0;
      case 9:
        if (_data.assets.comboNumber9 == null) return fallback?.buildComboNumSprite(digit);
        var assetPath = buildComboNumSpritePath(digit);
        if (assetPath == null) return null;
        result.loadTexture(assetPath, getAssetLibrary(buildComboNumSpritePath(digit, true)));
        result.scale.x = _data.assets.comboNumber9?.scale ?? 1.0;
        result.scale.y = _data.assets.comboNumber9?.scale ?? 1.0;
      default:
        return null;
    }

    var isPixel = isComboNumSpritePixel(digit);
    result.antialiasing = !isPixel;
    result.pixelPerfectRender = isPixel;
    result.pixelPerfectPosition = isPixel;
    result.updateHitbox();

    return result;
  }

  public function isComboNumSpritePixel(digit:Int):Bool
  {
    switch (digit)
    {
      case 0:
        var result = _data.assets.comboNumber0?.isPixel;
        if (result == null) result = fallback?.isComboNumSpritePixel(digit) ?? false;
        return result;
      case 1:
        var result = _data.assets.comboNumber1?.isPixel;
        if (result == null) result = fallback?.isComboNumSpritePixel(digit) ?? false;
        return result;
      case 2:
        var result = _data.assets.comboNumber2?.isPixel;
        if (result == null) result = fallback?.isComboNumSpritePixel(digit) ?? false;
        return result;
      case 3:
        var result = _data.assets.comboNumber3?.isPixel;
        if (result == null) result = fallback?.isComboNumSpritePixel(digit) ?? false;
        return result;
      case 4:
        var result = _data.assets.comboNumber4?.isPixel;
        if (result == null) result = fallback?.isComboNumSpritePixel(digit) ?? false;
        return result;
      case 5:
        var result = _data.assets.comboNumber5?.isPixel;
        if (result == null) result = fallback?.isComboNumSpritePixel(digit) ?? false;
        return result;
      case 6:
        var result = _data.assets.comboNumber6?.isPixel;
        if (result == null) result = fallback?.isComboNumSpritePixel(digit) ?? false;
        return result;
      case 7:
        var result = _data.assets.comboNumber7?.isPixel;
        if (result == null) result = fallback?.isComboNumSpritePixel(digit) ?? false;
        return result;
      case 8:
        var result = _data.assets.comboNumber8?.isPixel;
        if (result == null) result = fallback?.isComboNumSpritePixel(digit) ?? false;
        return result;
      case 9:
        var result = _data.assets.comboNumber9?.isPixel;
        if (result == null) result = fallback?.isComboNumSpritePixel(digit) ?? false;
        return result;
      default:
        return false;
    }
  }

  public function buildComboNumSpritePath(digit:Int, raw:Bool = false):Null<String>
  {
    var basePath:Null<String> = null;
    switch (digit)
    {
      case 0:
        basePath = _data.assets.comboNumber0?.assetPath;
      case 1:
        basePath = _data.assets.comboNumber1?.assetPath;
      case 2:
        basePath = _data.assets.comboNumber2?.assetPath;
      case 3:
        basePath = _data.assets.comboNumber3?.assetPath;
      case 4:
        basePath = _data.assets.comboNumber4?.assetPath;
      case 5:
        basePath = _data.assets.comboNumber5?.assetPath;
      case 6:
        basePath = _data.assets.comboNumber6?.assetPath;
      case 7:
        basePath = _data.assets.comboNumber7?.assetPath;
      case 8:
        basePath = _data.assets.comboNumber8?.assetPath;
      case 9:
        basePath = _data.assets.comboNumber9?.assetPath;
      default:
        basePath = null;
    }

    if (basePath == null) return fallback?.buildComboNumSpritePath(digit, raw);
    if (raw) return basePath;

    var parts = basePath?.split(Constants.LIBRARY_SEPARATOR) ?? [];
    if (parts.length < 1) return null;
    if (parts.length == 1) return parts[0];

    return parts[1];
  }

  public function getComboNumSpriteOffsets(digit:Int):Array<Float>
  {
    switch (digit)
    {
      case 0:
        var result = _data.assets.comboNumber0?.offsets;
        if (result == null) result = fallback?.getComboNumSpriteOffsets(digit) ?? [0, 0];
        return result;
      case 1:
        var result = _data.assets.comboNumber1?.offsets;
        if (result == null) result = fallback?.getComboNumSpriteOffsets(digit) ?? [0, 0];
        return result;
      case 2:
        var result = _data.assets.comboNumber2?.offsets;
        if (result == null) result = fallback?.getComboNumSpriteOffsets(digit) ?? [0, 0];
        return result;
      case 3:
        var result = _data.assets.comboNumber3?.offsets;
        if (result == null) result = fallback?.getComboNumSpriteOffsets(digit) ?? [0, 0];
        return result;
      case 4:
        var result = _data.assets.comboNumber4?.offsets;
        if (result == null) result = fallback?.getComboNumSpriteOffsets(digit) ?? [0, 0];
        return result;
      case 5:
        var result = _data.assets.comboNumber5?.offsets;
        if (result == null) result = fallback?.getComboNumSpriteOffsets(digit) ?? [0, 0];
        return result;
      case 6:
        var result = _data.assets.comboNumber6?.offsets;
        if (result == null) result = fallback?.getComboNumSpriteOffsets(digit) ?? [0, 0];
        return result;
      case 7:
        var result = _data.assets.comboNumber7?.offsets;
        if (result == null) result = fallback?.getComboNumSpriteOffsets(digit) ?? [0, 0];
        return result;
      case 8:
        var result = _data.assets.comboNumber8?.offsets;
        if (result == null) result = fallback?.getComboNumSpriteOffsets(digit) ?? [0, 0];
        return result;
      case 9:
        var result = _data.assets.comboNumber9?.offsets;
        if (result == null) result = fallback?.getComboNumSpriteOffsets(digit) ?? [0, 0];
        return result;
      default:
        return [0, 0];
    }
  }

  public function buildSplashSprite(target:NoteSplash):Void
  {
    var atlas:Null<FlxAtlasFrames> = buildSplashFrames(false);

    if (atlas == null)
    {
      throw 'Could not load spritesheet for note style: $id';
    }
    target.frames = atlas;
    target.antialiasing = !(_data.assets.noteSplash?.isPixel ?? false);

    buildSplashAnimations(target);

    target.splashFramerate = getSplashFramerate();
    target.splashFramerateVariance = getSplashFramerateVariance();
    target.alpha = _data.assets.noteSplash?.alpha ?? 1.0;
    target.blend = _data.assets.noteSplash?.data?.blendMode ?? "normal";

    var scale = getSplashScale();
    target.scale.set(scale, scale);
    target.updateHitbox();
  }

  var splashFrames:Null<FlxAtlasFrames> = null;
  var splashFramesPath:Null<String> = null;
  var splashFramesLibrary:Null<String> = null;

  function buildSplashFrames(force:Bool = false):Null<FlxAtlasFrames>
  {
    var splashAssetPath:Null<String> = getSplashAssetPath();
    if (splashAssetPath == null)
    {
      FlxG.log.warn('Note Splash asset path not found: ${id}');
      return null;
    }

    var splashLibrary = getAssetLibrary(getSplashAssetPath(true));
    if (!funkin.assets.Assets.isFlxGraphicCached(funkin.assets.Paths.file(splashAssetPath, 'png', true, splashLibrary)))
    {
      FlxG.log.warn('Note Splash texture not cached: ${splashAssetPath}');
    }

    @:nullSafety(Off)
    {
      if (splashFrames?.parent?.isDestroyed ?? true) splashFrames = null;
    }
    if (splashFramesPath != splashAssetPath || splashFramesLibrary != splashLibrary) splashFrames = null;

    if (splashFrames != null && !force) return splashFrames;

    splashFrames = Paths.getSparrowAtlas(splashAssetPath, splashLibrary);
    if (splashFrames == null)
    {
      throw 'Could not load notesplash frames for note style: $id';
    }
    splashFramesPath = splashAssetPath;
    splashFramesLibrary = splashLibrary;
    splashFrames.parent.persist = true;
    return splashFrames;
  }

  public function getSplashAssetPath(raw:Bool = false):Null<String>
  {
    if (raw)
    {
      var rawPath:Null<String> = _data?.assets?.noteSplash?.assetPath;
      if (rawPath == null) return fallback?.getSplashAssetPath(true);
      return rawPath;
    }

    var parts = getSplashAssetPath(true)?.split(Constants.LIBRARY_SEPARATOR) ?? [];
    if (parts.length == 0) return null;
    if (parts.length == 1) return getSplashAssetPath(true);
    return parts[1];
  }

  function buildSplashAnimations(target:NoteSplash):Void
  {
    final addSplashAnim:NoteDirection->Void = function(dir:NoteDirection)
    {
      var animData:Null<Array<AnimationData>> = fetchSplashAnimationData(dir);
      if (animData != null)
      {
        for (anim in animData) FlxAnimationUtil.addAtlasAnimation(target, anim);
      }
    };

    addSplashAnim(LEFT);
    addSplashAnim(RIGHT);
    addSplashAnim(UP);
    addSplashAnim(DOWN);
  }

  public function isSplashAnimated():Bool
  {
    return _data?.assets?.noteSplash?.animated ?? fallback?.isSplashAnimated() ?? false;
  }

  public function getSplashScale():Float
  {
    return _data?.assets?.noteSplash?.scale ?? fallback?.getSplashScale() ?? 1.0;
  }

  function fetchSplashAnimationData(dir:NoteDirection):Null<Array<AnimationData>>
  {
    var result:Null<Array<AnimationData>> = switch (dir)
    {
      case LEFT:
        _data.assets?.noteSplash?.data?.leftSplashes?.toNamedArray("splashLEFT");
      case DOWN:
        _data.assets?.noteSplash?.data?.downSplashes?.toNamedArray("splashDOWN");
      case UP:
        _data.assets?.noteSplash?.data?.upSplashes?.toNamedArray("splashUP");
      case RIGHT:
        _data.assets?.noteSplash?.data?.rightSplashes?.toNamedArray("splashRIGHT");
    };
    return result ?? fallback?.fetchSplashAnimationData(dir);
  }

  public function getSplashOffsets():Array<Float>
  {
    return _data?.assets?.noteSplash?.offsets ?? fallback?.getSplashOffsets() ?? [0.0, 0.0];
  }

  public function getSplashFramerate():Int
  {
    return _data?.assets?.noteSplash?.data?.framerateDefault ?? fallback?.getSplashFramerate() ?? 24;
  }

  public function getSplashFramerateVariance():Int
  {
    return _data?.assets?.noteSplash?.data?.framerateVariance ?? fallback?.getSplashFramerateVariance() ?? 2;
  }

  public function buildHoldCoverSprite(target:NoteHoldCover):Void
  {
    // NoteHoldCover has "glow" and "sparks". Right now it only implements "glow"
    // but "sparks" I believe is meant to be used for the ending of the hold note
    var glowAtlas:Null<FlxFramesCollection> = buildHoldCoverFrames(false);
    if (glowAtlas == null)
    {
      throw 'Could not load spritesheet for note style: $id';
    }
    target.glow.frames = glowAtlas;

    target.antialiasing = !(_data.assets.holdNoteCover?.isPixel ?? false);
    target.glow.antialiasing = !(_data.assets.holdNoteCover?.isPixel ?? false);
    target.scale.set(_data.assets.holdNoteCover?.scale ?? 1.0, _data.assets.holdNoteCover?.scale ?? 1.0);
    target.updateHitbox();
    target.glow.updateHitbox();

    buildHoldCoverAnimations(target);
  }

  // we use FlxFramesCollection here so we can combine em into one atlas later
  var holdCoverFrames:Null<FlxFramesCollection> = null;

  function buildHoldCoverFrames(force:Bool = false):Null<FlxFramesCollection>
  {
    // Rebuild from the current direction assets. Combined collections have no
    // parent, and a single-direction atlas may have changed since the last call.
    // Do not destroy the old collection: active sprites can still reference it.
    holdCoverFrames = null;

    for (direction in Strumline.DIRECTIONS)
    {
      // We make a FlxFramesCollection here so we can combine em into one atlas later
      var atlas:Null<FlxFramesCollection> = buildHoldCoverFrameForDirection(direction);
      if (holdCoverFrames == null) holdCoverFrames = atlas;
      else if (atlas != null) holdCoverFrames = FlxAnimationUtil.combineFramesCollections(holdCoverFrames, atlas);
    }
    return holdCoverFrames;
  }

  function buildHoldCoverFrameForDirection(direction:NoteDirection):Null<FlxFramesCollection>
  {
    var directionData = switch (direction)
    {
      case LEFT:
        _data.assets?.holdNoteCover?.data?.left;
      case DOWN:
        _data.assets?.holdNoteCover?.data?.down;
      case UP:
        _data.assets?.holdNoteCover?.data?.up;
      case RIGHT:
        _data.assets?.holdNoteCover?.data?.right;
    };

    // Animation data falls back to the parent for an absent direction; use
    // that same parent's atlas instead of leaving its animation without frames.
    if (directionData == null) return fallback?.buildHoldCoverFrameForDirection(direction);

    var holdCoverAssetPath:Null<String> = getHoldCoverDirectionAssetPath(direction) ?? fallback?.getHoldCoverDirectionAssetPath(direction);
    if (holdCoverAssetPath == null)
    {
      FlxG.log.warn('Hold Note Cover asset path not found: ${id}');
      return null;
    }

    if (!funkin.assets.Assets.isFlxGraphicCached(funkin.assets.Paths.file(holdCoverAssetPath, 'png', true, getAssetLibrary(getHoldCoverDirectionAssetPath(direction, true)))))
    {
      FlxG.log.warn('Hold Note Cover texture not cached: ${holdCoverAssetPath}');
    }

    var atlas:FlxFramesCollection = Paths.getSparrowAtlas(holdCoverAssetPath, getAssetLibrary(getHoldCoverDirectionAssetPath(direction, true)));
    if (atlas == null) return null;

    atlas.parent.persist = true;

    return atlas;
  }

  function buildHoldCoverAnimations(target:NoteHoldCover):Void
  {
    for (direction in Strumline.DIRECTIONS)
    {
      var animData:Null<Array<AnimationData>> = fetchHoldCoverAnimationData(direction);
      if (animData != null)
      {
        // Optional start/end animations may be absent, so identify the hold
        // animation by name instead of assuming it occupies the second slot.
        var holdAnimationName = 'holdCover${direction.colorName.toTitleCase()}';
        for (animation in animData)
        {
          if (animation.name == holdAnimationName) animation.looped = true;
        }
        FlxAnimationUtil.addAtlasAnimations(target.glow, animData);
      }
    }
  }

  function fetchHoldCoverAnimationData(dir:NoteDirection):Null<Array<AnimationData>>
  {
    var noteColor:String = dir.colorName.toTitleCase();
    var result:Array<Null<AnimationData>> = switch (dir)
    {
      case LEFT:
        [
          _data.assets?.holdNoteCover?.data?.left?.start?.toNamed('holdCoverStart$noteColor'),
          _data.assets?.holdNoteCover?.data?.left?.hold?.toNamed('holdCover$noteColor'),
          _data.assets?.holdNoteCover?.data?.left?.end?.toNamed('holdCoverEnd$noteColor'),
        ];
      case DOWN:
        [
          _data.assets?.holdNoteCover?.data?.down?.start?.toNamed('holdCoverStart$noteColor'),
          _data.assets?.holdNoteCover?.data?.down?.hold?.toNamed('holdCover$noteColor'),
          _data.assets?.holdNoteCover?.data?.down?.end?.toNamed('holdCoverEnd$noteColor'),
        ];
      case UP:
        [
          _data.assets?.holdNoteCover?.data?.up?.start?.toNamed('holdCoverStart$noteColor'),
          _data.assets?.holdNoteCover?.data?.up?.hold?.toNamed('holdCover$noteColor'),
          _data.assets?.holdNoteCover?.data?.up?.end?.toNamed('holdCoverEnd$noteColor'),
        ];
      case RIGHT:
        [
          _data.assets?.holdNoteCover?.data?.right?.start?.toNamed('holdCoverStart$noteColor'),
          _data.assets?.holdNoteCover?.data?.right?.hold?.toNamed('holdCover$noteColor'),
          _data.assets?.holdNoteCover?.data?.right?.end?.toNamed('holdCoverEnd$noteColor'),
        ];
      default:
        [];
    };

    // New variable so we can change the type.
    var filteredResult:Array<AnimationData> = thx.Arrays.filterNull(result);

    if (filteredResult.length == 0) return fallback?.fetchHoldCoverAnimationData(dir) ?? [];

    return filteredResult;
  }

  // fallbacks:
  // assetPath for a direction -> root assetpath -> fallback assetpath for direction -> fallback root assetpath
  // `direction` here is required, however it only is used for fallback purposes

  function getHoldCoverRootAssetPath(direction:NoteDirection, raw:Bool = false):Null<String>
  {
    if (raw)
    {
      var rawPath:Null<String> = _data?.assets?.holdNoteCover?.assetPath;
      // remember, if we need a fallback for our *root* asset path,
      // we fallback and look for the *direction* asset path first
      if (rawPath == null) return fallback?.getHoldCoverDirectionAssetPath(direction, true);
      return rawPath;
    }

    var parts:Array<String> = getHoldCoverRootAssetPath(direction, true)?.split(Constants.LIBRARY_SEPARATOR) ?? [];
    if (parts.length == 0) return null;
    if (parts.length == 1) return getHoldCoverRootAssetPath(direction, true);
    return parts[1];
  }

  public function getHoldCoverDirectionAssetPath(direction:NoteDirection, raw:Bool = false):Null<String>
  {
    if (raw)
    {
      var rawPath:Null<String> = switch (direction)
      {
        case LEFT:
          _data?.assets?.holdNoteCover?.data?.left?.assetPath;
        case DOWN:
          _data?.assets?.holdNoteCover?.data?.down?.assetPath;
        case UP:
          _data?.assets?.holdNoteCover?.data?.up?.assetPath;
        case RIGHT:
          _data?.assets?.holdNoteCover?.data?.right?.assetPath;
      };

      // we don't want to fallback directly just yet, we want to check our root assetpath first
      if (rawPath == null) return getHoldCoverRootAssetPath(direction, true);
      return rawPath;
    }

    var parts:Array<String> = getHoldCoverDirectionAssetPath(direction, true)?.split(Constants.LIBRARY_SEPARATOR) ?? [];
    if (parts.length == 0) return null;
    if (parts.length == 1) return getHoldCoverDirectionAssetPath(direction, true);
    return parts[1];
  }

  public function getHoldCoverOffsets():Array<Float>
  {
    return _data?.assets?.holdNoteCover?.offsets ?? fallback?.getHoldCoverOffsets() ?? [0.0, 0.0];
  }

  public function destroy():Void
  {
  }

  /**
   * Returns a string of the library name for the given asset id
   * `default:assets/images/awesome.png` returns `default`
   * If you pass a asset path with no library name (no `:` aka LIBRARY_SEPARATOR) it will return null
   * @param id The asset id to get the library name from
   * @return Null<String> The library name, or null if no library name is present
   */
  function getAssetLibrary(?id:String):Null<String>
  {
    var parts:Array<String> = id?.split(Constants.LIBRARY_SEPARATOR) ?? [];
    if (parts.length <= 1) return null;

    return parts[0];
  }

  public function toString():String
  {
    return 'NoteStyle($id)';
  }

  static function _fetchData(id:String):NoteStyleData
  {
    var result = NoteStyleRegistry.instance.parseEntryDataWithMigration(id, NoteStyleRegistry.instance.fetchEntryVersion(id));

    if (result == null)
    {
      throw 'Could not parse note style data for id: $id';
    }
    else
    {
      return result;
    }
  }
}
