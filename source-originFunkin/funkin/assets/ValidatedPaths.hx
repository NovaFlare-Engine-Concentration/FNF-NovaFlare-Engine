package funkin.assets;

// NOTE: This module is compiled with macro context.
// If you try to import anything it will almost certainly throw a bunch of errors.
import haxe.macro.Context;
import haxe.macro.Expr;
import funkin.util.macro.MacroUtil;

using haxe.macro.ExprTools;

/**
 * We alias this class over the `Paths` class, then implement macro functions which redirect the originals.
 * This provides identical behavior while providing additional compile-time functionality via macros.
 *
 * Note this can't be combined with Paths.hx because the macro functions can't be accessed from HScript,
 * and scripted classes need to be able to access the Paths functions too.
 */
@:nullSafety
class ValidatedPaths
{
  /**
   * Constructs an asset path for a `.txt` text file.
   * @param key The path to the text file, without file extension.
   * @param validate Whether to try to validate that the file path exists at compile time. Defaults to `true`.
   * @return An AssetPath pointing to the text file.
   */
  public static macro function txt(key:Expr, ?validate:Expr):Expr
  {
    var shouldValidate:Bool = MacroUtil.extractBooleanConstant(validate) ?? true;
    if (!shouldValidate)
    {
      Context.info('[ASSETS] Skipping validation for asset path...', key.pos);
    }
    else
    {
      var staticPath:Null<String> = MacroUtil.extractStringConstant(key);
      if (staticPath != null) validateAssetPath(staticPath, ['txt'], key.pos);
    }

    // This expression gets inserted at the location that `ValidatedPaths.txt(key)` got called.
    if (!shouldValidate || !MacroUtil.isNullExpr(validate))
    {
      return macro @:pos(haxe.macro.Context.currentPos()) funkin.assets.Paths.txt($e{key}, $e{validate});
    }
    else
    {
      return macro @:pos(haxe.macro.Context.currentPos()) funkin.assets.Paths.txt($e{key});
    }
  }

  /**
   * Constructs an asset path for a `.frag` shader file.
   * @param key The path to the shader file, without file extension.
   * @return An AssetPath pointing to the shader file.
   */
  public static macro function frag(key:Expr, ?validate:Expr):Expr
  {
    var shouldValidate:Bool = MacroUtil.extractBooleanConstant(validate) ?? true;
    if (!shouldValidate)
    {
      Context.info('[ASSETS] Skipping validation for asset path...', key.pos);
    }
    else
    {
      var staticPath:Null<String> = MacroUtil.extractStringConstant(key);
      if (staticPath != null) validateAssetPath(staticPath, ['frag'], key.pos);
    }

    // This expression gets inserted at the location that `ValidatedPaths.frag(key)` got called.
    if (!shouldValidate || !MacroUtil.isNullExpr(validate))
    {
      return macro @:pos(haxe.macro.Context.currentPos()) funkin.assets.Paths.frag($e{key}, $e{validate});
    }
    else
    {
      return macro @:pos(haxe.macro.Context.currentPos()) funkin.assets.Paths.frag($e{key});
    }
  }

  /**
   * Constructs an asset path for a `.vert` shader file.
   * @param key The path to the shader file, without file extension.
   * @return An AssetPath pointing to the shader file.
   */
  public static macro function vert(key:Expr, ?validate:Expr):Expr
  {
    var shouldValidate:Bool = MacroUtil.extractBooleanConstant(validate) ?? true;
    if (!shouldValidate)
    {
      Context.info('[ASSETS] Skipping validation for asset path...', key.pos);
    }
    else
    {
      var staticPath:Null<String> = MacroUtil.extractStringConstant(key);
      if (staticPath != null) validateAssetPath(staticPath, ['vert'], key.pos);
    }

    // This expression gets inserted at the location that `ValidatedPaths.vert(key)` got called.
    if (!shouldValidate || !MacroUtil.isNullExpr(validate))
    {
      return macro @:pos(haxe.macro.Context.currentPos()) funkin.assets.Paths.vert($e{key}, $e{validate});
    }
    else
    {
      return macro @:pos(haxe.macro.Context.currentPos()) funkin.assets.Paths.vert($e{key});
    }
  }

  /**
   * Constructs an asset path for a font file.
   * @param key The path to the font file, without file extension.
   * @param ext An optional file extension to validate against. Defaults to `ttf`.
   * @param validate Whether to validate
   * @return An AssetPath pointing to the font file.
   */
  public static macro function font(key:Expr, ?ext:Expr, ?validate:Expr):Expr
  {
    var shouldValidate:Bool = MacroUtil.extractBooleanConstant(validate) ?? true;
    if (!shouldValidate)
    {
      Context.info('[ASSETS] Skipping validation for asset path...', key.pos);
    }
    else
    {
      var staticPath:Null<String> = MacroUtil.extractStringConstant(key);
      var staticExt:Null<String> = MacroUtil.extractStringConstant(ext);
      if (staticExt == null && (ext == null || MacroUtil.isNullExpr(ext))) staticExt = 'ttf';
      if (staticPath != null && staticExt != null) validateAssetPath(staticPath, [staticExt], key.pos);
    }

    var runtimeExt:Expr = ext == null || MacroUtil.isNullExpr(ext) ? macro 'ttf' : ext;
    var runtimeValidate:Expr = validate == null || MacroUtil.isNullExpr(validate) ? macro true : validate;
    return macro @:pos(haxe.macro.Context.currentPos()) funkin.assets.Paths.font($e{key}, $e{runtimeExt}, $e{runtimeValidate});
  }

  /**
   * Constructs an asset path for a `.xml` data file.
   * @param key The path to the data file, without file extension.
   * @param validate Whether to validate
   * @return An AssetPath pointing to the data file.
   */
  public static macro function xml(key:Expr, ?validate:Expr):Expr
  {
    var shouldValidate:Bool = MacroUtil.extractBooleanConstant(validate) ?? true;
    if (!shouldValidate)
    {
      Context.info('[ASSETS] Skipping validation for asset path...', key.pos);
    }
    else
    {
      var staticPath:Null<String> = MacroUtil.extractStringConstant(key);
      if (staticPath != null) validateAssetPath(staticPath, ['xml'], key.pos);
    }

    if (!shouldValidate || !MacroUtil.isNullExpr(validate))
    {
      // This expression gets inserted at the location that `ValidatedPaths.xml(key)` got called.
      return macro @:pos(haxe.macro.Context.currentPos()) funkin.assets.Paths.xml($e{key}, $e{validate});
    }
    else
    {
      return macro @:pos(haxe.macro.Context.currentPos()) funkin.assets.Paths.xml($e{key});
    }
  }

  /**
   * Constructs an asset path for a `.json` data file.
   * @param key The path to the data file, without file extension.
   * @param validate Whether to validate
   * @return An AssetPath pointing to the data file.
   */
  public static macro function json(key:Expr, ?validate:Expr):Expr
  {
    var shouldValidate:Bool = MacroUtil.extractBooleanConstant(validate) ?? true;
    if (!shouldValidate)
    {
      Context.info('[ASSETS] Skipping validation for asset path...', key.pos);
    }
    else
    {
      var staticPath:Null<String> = MacroUtil.extractStringConstant(key);
      if (staticPath != null) validateAssetPath(staticPath, ['json'], key.pos);
    }

    if (!shouldValidate || !MacroUtil.isNullExpr(validate))
    {
      // This expression gets inserted at the location that `ValidatedPaths.json(key)` got called.
      return macro @:pos(haxe.macro.Context.currentPos()) funkin.assets.Paths.json($e{key}, $e{validate});
    }
    else
    {
      return macro @:pos(haxe.macro.Context.currentPos()) funkin.assets.Paths.json($e{key});
    }
  }

  /**
   * Constructs an asset path for a sound file.
   * @param key The path to the sound file, without file extension.
   * @return An AssetPath pointing to the sound file.
   */
  public static macro function sound(key:Expr, ?validate:Expr):Expr
  {
    var shouldValidate:Bool = MacroUtil.extractBooleanConstant(validate) ?? true;
    if (!shouldValidate)
    {
      Context.info('[ASSETS] Skipping validation for asset path...', key.pos);
    }
    else
    {
      var staticPath:Null<String> = MacroUtil.extractStringConstant(key);
      if (staticPath != null) validateAssetPath(staticPath, ['ogg'], key.pos);
    }

    if (!shouldValidate || !MacroUtil.isNullExpr(validate))
    {
      // This expression gets inserted at the location that `ValidatedPaths.sound(key)` got called.
      return macro @:pos(haxe.macro.Context.currentPos()) funkin.assets.Paths.sound($e{key}, $e{validate});
    }
    else
    {
      return macro @:pos(haxe.macro.Context.currentPos()) funkin.assets.Paths.sound($e{key});
    }
  }

  /**
   * Constructs an asset path for a music file.
   * @param key The path to the folder containing the track and its metadata.
   * @param suffix An optional suffix to apply to the track name.
   *   For example, you can use this to fetch a `-start` variant of a track.
   * @param validate Whether to validate the file exists, and throw a warning if it doesn't.
   * @return An AssetPath pointing to the music file.
   */
  public static macro function music(key:Expr, ?suffix:Expr, ?validate:Expr):Expr
  {
    var shouldValidate:Bool = MacroUtil.extractBooleanConstant(validate) ?? true;
    if (!shouldValidate)
    {
      Context.info('[ASSETS] Skipping validation for asset path...', key.pos);
    }
    else
    {
      var staticPath:Null<String> = MacroUtil.extractStringConstant(key);

      var staticSuffix:Null<String> = MacroUtil.extractStringConstant(suffix);
      if (staticSuffix == null && (suffix == null || MacroUtil.isNullExpr(suffix))) staticSuffix = '';
      if (staticPath != null && staticSuffix != null)
      {
        var suffix:String = staticSuffix;

        var parts:Array<String> = staticPath.split('/');
        var staticId:String = parts[parts.length - 1];
        var staticDir:String = parts.slice(0, (parts.length - 1)).join('/');

        var audioPath:String = haxe.io.Path.extension(staticPath).toLowerCase() == 'ogg'
          ? haxe.io.Path.withoutExtension(staticPath) + suffix
          : '$staticDir/$staticId/$staticId$suffix';
        validateAssetPath(audioPath, ['ogg'], key.pos);

        var metadataPath:String = '$audioPath-metadata';
        validateAssetPath(metadataPath, ['json'], key.pos);
      }
    }

    var runtimeSuffix:Expr = suffix == null || MacroUtil.isNullExpr(suffix) ? macro null : suffix;
    var runtimeValidate:Expr = validate == null || MacroUtil.isNullExpr(validate) ? macro true : validate;
    return macro @:pos(haxe.macro.Context.currentPos()) funkin.assets.Paths.music($e{key}, $e{runtimeSuffix}, $e{runtimeValidate});
  }

  /**
   * Constructs an asset path for a video file.
   * @param key The path to the video file, without file extension.
   * @return An AssetPath pointing to the video file.
   */
  public static macro function video(key:Expr, ?ext:Expr, ?validate:Expr):Expr
  {
    var shouldValidate:Bool = MacroUtil.extractBooleanConstant(validate) ?? true;
    if (!shouldValidate)
    {
      Context.info('[ASSETS] Skipping validation for asset path...', key.pos);
    }
    else
    {
      var staticPath:Null<String> = MacroUtil.extractStringConstant(key);
      var staticExt:Null<String> = MacroUtil.extractStringConstant(ext);
      if (staticExt == null && (ext == null || MacroUtil.isNullExpr(ext))) staticExt = 'mp4';
      if (staticPath != null && staticExt != null) validateAssetPath(staticPath, [staticExt], key.pos);
    }

    // The runtime method takes extension before validation. Forward both
    // arguments, filling omitted or explicit null values with its defaults.
    var runtimeExt:Expr = ext == null || MacroUtil.isNullExpr(ext) ? macro 'mp4' : ext;
    var runtimeValidate:Expr = validate == null || MacroUtil.isNullExpr(validate) ? macro true : validate;
    return macro @:pos(haxe.macro.Context.currentPos()) funkin.assets.Paths.video($e{key}, $e{runtimeExt}, $e{runtimeValidate});
  }

  /**
   * Constructs an asset path for a `.png` image file.
   * @param key The path to the image file, without file extension.
   * @return An AssetPath pointing to the image file.
   */
  public static macro function image(key:Expr, ?validate:Expr):Expr
  {
    var shouldValidate:Bool = MacroUtil.extractBooleanConstant(validate) ?? true;
    if (!shouldValidate)
    {
      Context.info('[ASSETS] Skipping validation for asset path...', key.pos);
    }
    else
    {
      var staticPath:Null<String> = MacroUtil.extractStringConstant(key);
      if (staticPath != null) validateAssetPath(staticPath, ['png'], key.pos);
    }

    if (!shouldValidate || !MacroUtil.isNullExpr(validate))
    {
      Context.info('[ASSETS] validate = "${validate.toString()}"', key.pos);
      // This expression gets inserted at the location that `ValidatedPaths.image(key)` got called.
      return macro @:pos(haxe.macro.Context.currentPos()) funkin.assets.Paths.image($e{key}, $e{validate});
    }
    else
    {
      return macro @:pos(haxe.macro.Context.currentPos()) funkin.assets.Paths.image($e{key});
    }
  }

  /**
   * Constructs an asset path for a subtitle file.
   * @param key The path to the subtitle file, without file extension.
   * @return An AssetPath pointing to the subtitle file.
   */
  public static macro function srt(key:Expr, ?validate:Expr):Expr
  {
    var shouldValidate:Bool = MacroUtil.extractBooleanConstant(validate) ?? true;
    if (!shouldValidate)
    {
      Context.info('[ASSETS] Skipping validation for asset path...', key.pos);
    }
    else
    {
      var staticPath:Null<String> = MacroUtil.extractStringConstant(key);
      if (staticPath != null) validateAssetPath(staticPath, ['srt'], key.pos);
    }

    if (!shouldValidate || !MacroUtil.isNullExpr(validate))
    {
      // This expression gets inserted at the location that `ValidatedPaths.srt(key)` got called.
      return macro @:pos(haxe.macro.Context.currentPos()) funkin.assets.Paths.srt($e{key}, $e{validate});
    }
    else
    {
      return macro @:pos(haxe.macro.Context.currentPos()) funkin.assets.Paths.srt($e{key});
    }
  }

  /**
   * Constructs an asset path for an Adobe Animate texture atlas.
   * @param key The path to the texture atlas, without file extension.
   * @return A AnimateAtlasAssetPath pointing to the spritesheet file.
   */
  public static macro function animateAtlas(key:Expr, ?validate:Expr):Expr
  {
    var shouldValidate:Bool = MacroUtil.extractBooleanConstant(validate) ?? true;
    if (!shouldValidate)
    {
      Context.info('[ASSETS] Skipping validation for asset path...', key.pos);
    }
    else
    {
      var staticPath:Null<String> = MacroUtil.extractStringConstant(key);
      if (staticPath != null)
      {
        // Check if `Animation.json` exists.
        validateAssetPath('${staticPath}/Animation', ['json'], key.pos);
        // TODO: Possibly check for other files at compile time?
      }
    }

    if (!shouldValidate || !MacroUtil.isNullExpr(validate))
    {
      // This expression gets inserted at the location that `ValidatedPaths.animateAtlas(key)` got called.
      return macro @:pos(haxe.macro.Context.currentPos()) funkin.assets.Paths.animateAtlas($e{key}, $e{validate});
    }
    else
    {
      return macro @:pos(haxe.macro.Context.currentPos()) funkin.assets.Paths.animateAtlas($e{key});
    }
  }

  #if macro
  /**
   * Throw a warning if the given asset cannot be found in the file system.
   * @param key The asset to query.
   * @param ext The file extension of the asset.
   * @param currentPos The position that the asset was queried at. Used to make error messages useful.
   */
  static function validateAssetPath(key:String, extensions:Array<String>, currentPos:Position, verbose:Bool = false):Void
  {
    // Origin's asset pack is supplied by the player beside the executable.
    // Paths.build performs the same existence checks after that pack is mounted.
    if (Context.defined("ORIGIN_FUNKIN_COMPAT")) return;
    // Directory to check relative to the project root when building.
    #if ios
    static final CORE_FOLDER:Null<String> = "../../../../../assets";
    #else
    static final CORE_FOLDER:Null<String> = "assets";
    #end

    for (ext in extensions)
    {
      var path:String = '$CORE_FOLDER/$key.$ext';
      var excludePath:String = '$CORE_FOLDER/exclude/$key.$ext';

      var fileExists:Bool = sys.FileSystem.exists(path) || sys.FileSystem.exists(excludePath);

      if (fileExists)
      {
        if (verbose) Context.info('[ASSET] "${path}": File exists', currentPos);
        return;
      }
    }

    if (extensions.length == 1)
    {
      var ext = extensions[0];
      Context.warning('[ASSET] "$key.$ext": File does not exist', currentPos);
    }
    else
    {
      var exts = extensions.join(', ');
      Context.warning('[ASSET] "$key": File does not exist, expected one of these extensions: ${exts}', currentPos);
    }
  }
  #end
}
