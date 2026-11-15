package originfunkin.compat;

import polymod.Polymod;
import polymod.hscript._internal.PolymodAbstractScriptClass;
import polymod.hscript._internal.PolymodScriptClass;
import haxe.io.Path;

/** Apply historical runtime contracts only to the mod which owns a script. */
@:access(polymod.Polymod)
@:access(polymod.hscript._internal.PolymodScriptClass)
class LegacyRuntime
{
  static var library:Dynamic;
  static var profiles:Map<String, Null<String>> = [];
  static var versionPolicies:Map<String, Map<String, Bool>> = [];
  static var originalFields:haxe.ds.ObjectMap<Dynamic, Map<String, Dynamic>> = new haxe.ds.ObjectMap();

  public static function restoreNativeWrites():Void
  {
    for (target => fields in originalFields)
      for (field => value in fields)
        try Reflect.setProperty(target, field, value)
        catch (error:Dynamic) trace('[Origin compatibility] Could not restore $field: $error');
    originalFields = new haxe.ds.ObjectMap();
  }

  public static function isLegacyOrigin(origin:Null<String>):Bool
  {
    return hasApiVersion(origin, '>=0.1.0 <0.9.0');
  }

  #if target.threaded
  static var forcedAnimationDepth:sys.thread.Tls<Null<Int>> = new sys.thread.Tls();
  static function getForcedAnimationDepth():Int return forcedAnimationDepth.value ?? 0;
  static function setForcedAnimationDepth(value:Int):Void forcedAnimationDepth.value = value == 0 ? null : value;
  #else
  static var forcedAnimationDepth:Int = 0;
  static function getForcedAnimationDepth():Int return forcedAnimationDepth;
  static function setForcedAnimationDepth(value:Int):Void forcedAnimationDepth = value;
  #end

  #if target.threaded
  static var previewDialogueSpeedWrite:sys.thread.Tls<Null<Bool>> = new sys.thread.Tls();
  static function getPreviewDialogueSpeedWrite():Bool return previewDialogueSpeedWrite.value ?? false;
  static function setPreviewDialogueSpeedWrite(value:Bool):Void previewDialogueSpeedWrite.value = value ? true : null;
  #else
  static var previewDialogueSpeedWrite:Bool = false;
  static function getPreviewDialogueSpeedWrite():Bool return previewDialogueSpeedWrite;
  static function setPreviewDialogueSpeedWrite(value:Bool):Void previewDialogueSpeedWrite = value;
  #end

  /** Keep the version rule scoped to a single script property assignment. */
  public static function withPreviewDialogueSpeedWrite(origin:Null<String>, isSpeedField:Bool, invoke:Void->Dynamic):Dynamic
  {
    if (!isSpeedField) return invoke();
    var previous = getPreviewDialogueSpeedWrite();
    setPreviewDialogueSpeedWrite(hasApiVersion(origin, '>=0.9.0 <0.10.0'));
    try
    {
      var result = invoke();
      setPreviewDialogueSpeedWrite(previous);
      return result;
    }
    catch (error:Dynamic)
    {
      setPreviewDialogueSpeedWrite(previous);
      throw error;
    }
  }

  public static function usesPreviewDialogueSpeedWrite():Bool return getPreviewDialogueSpeedWrite();

  static function nativeBopper(target:Dynamic):Null<funkin.play.stage.Bopper>
  {
    var current:Dynamic = target;
    var depth = 0;
    while (Std.isOfType(current, PolymodScriptClass) && depth++ < 32)
      current = cast(current, PolymodScriptClass).superClass;
    return Std.isOfType(current, funkin.play.stage.Bopper) ? cast current : null;
  }

  /** Preserve pre-0.5 timing for scripted boppers with an identifiable source. */
  public static function usesLegacyBeatTiming(target:Dynamic):Bool
  {
    if (target == null) return false;
    var script = Reflect.field(target, '_asc');
    var name = 'onBeatHit';
    var owner = polymod.hscript.PolymodScriptBridge.findScript(script, name);
    if (owner == null)
    {
      name = 'onStepHit';
      owner = polymod.hscript.PolymodScriptBridge.findScript(script, name);
    }
    if (owner == null)
    {
      // A script without either callback still owns its constructor. Its
      // origin identifies the historical timing expected by that object.
      name = 'new';
      owner = polymod.hscript.PolymodScriptBridge.findScript(script, name);
    }
    if (owner == null)
    {
      if (!Std.isOfType(script, PolymodScriptClass)) return false;
      var declarationOwner:PolymodScriptClass = cast script;
      return hasApiVersion(LegacyFieldDeclarations.originOf(declarationOwner._c), '>=0.1.0 <0.5.0');
    }
    var declaration = cast(owner, PolymodScriptClass).findFunction(name);
    return declaration != null && hasApiVersion(declaration.expr?.origin, '>=0.1.0 <0.5.0');
  }

  /** Scope the old Bopper rule to an old script call and restore it on errors. */
  public static function withForcedAnimationRule(origin:Null<String>, target:Dynamic, name:String, invoke:Void->Dynamic):Dynamic
  {
    if (name != 'playAnimation') return invoke();
    var previous = getForcedAnimationDepth();
    var useLegacy = nativeBopper(target) != null && hasApiVersion(origin, '>=0.1.0 <0.5.0');
    setForcedAnimationDepth(useLegacy ? 1 : 0);
    try
    {
      var value = invoke();
      setForcedAnimationDepth(previous);
      return value;
    }
    catch (error:Dynamic)
    {
      setForcedAnimationDepth(previous);
      throw error;
    }
  }

  public static function usesForcedAnimationRule():Bool return getForcedAnimationDepth() > 0;

  /** Wrap saved native Bopper methods after normal interpreter access checks. */
  public static function historicalForcedAnimationMethod(target:Dynamic, name:String, value:Dynamic, origin:Null<String>):Dynamic
  {
    if (name != 'playAnimation' || !Reflect.isFunction(value) || !hasApiVersion(origin, '>=0.1.0 <0.5.0')) return value;
    var nativeTarget = nativeBopper(target);
    if (nativeTarget == null) return value;
    return Reflect.makeVarArgs(function(args:Array<Dynamic>):Dynamic {
      var scriptName = polymod.util.Util.getScriptClassName(target);
      if (scriptName != null && ((PolymodScriptClass.blacklistedScriptClassStaticFields.get(scriptName)?.contains(name) ?? false)
        || (PolymodScriptClass.blacklistedScriptClassInstanceFields.get(scriptName)?.contains(name) ?? false)))
        throw 'Cannot access blacklisted field $name';
      var cls = Type.getClass(nativeTarget);
      var clsName = cls == null ? null : Type.getClassName(cls);
      if (clsName != null && PolymodScriptClass.blacklistedInstanceFieldsOf(clsName).contains(name))
        throw 'Cannot access blacklisted field $name';
      return withForcedAnimationRule(origin, target, name, () -> Reflect.callMethod(target, value, args));
    });
  }

  /** Preserve the old default scalar key without changing native or current callers. */
  public static function historicalSongArguments(target:Dynamic, name:String, args:Array<Dynamic>, origin:Null<String>):Array<Dynamic>
  {
    if (!isLegacyOrigin(origin)) return args;
    if (name == "valueAsStruct" && Std.isOfType(target, funkin.data.song.SongData.SongEventDataRaw)
      && (args.length == 0 || (args.length == 1 && args[0] == null))) return ["key"];
    if (name == "getInstPath" && Std.isOfType(target, funkin.play.song.Song.SongDifficulty)
      && args.length == 1 && Std.isOfType(args[0], String) && args[0] != "")
    {
      var difficulty:funkin.play.song.Song.SongDifficulty = cast target;
      var characters = difficulty.characters;
      if (characters == null || characters.altInstrumentals == null || !characters.altInstrumentals.contains(cast args[0])) return [""];
    }
    return args;
  }

  /** Wrap a saved native method only after the interpreter has checked field access. */
  public static function historicalSongMethod(target:Dynamic, name:String, value:Dynamic, origin:Null<String>):Dynamic
  {
    if (!Reflect.isFunction(value) || !isLegacyOrigin(origin)) return value;
    var isPathMethod = Std.isOfType(target, funkin.play.song.Song.SongDifficulty)
      && ["getInstPath", "buildVoiceList", "buildPlayerVoiceList", "buildOpponentVoiceList"].contains(name);
    var isEventMethod = Std.isOfType(target, funkin.data.song.SongData.SongEventDataRaw) && name == "valueAsStruct";
    var isPopupMethod = Std.isOfType(target, funkin.play.components.PopUpStuff) && name == "displayCombo"
      && hasApiVersion(origin, '>=0.1.0 <0.5.0');
    if (!isPathMethod && !isEventMethod && !isPopupMethod) return value;
    return Reflect.makeVarArgs(function(args:Array<Dynamic>):Dynamic {
      var cls = Type.getClass(target);
      var clsName = cls == null ? null : Type.getClassName(cls);
      if (clsName != null && polymod.hscript._internal.PolymodScriptClass.blacklistedInstanceFieldsOf(clsName).contains(name))
        throw 'Cannot access blacklisted field $name';
      var adapted = historicalSongArguments(target, name, args, origin);
      var result = historicalSongResult(target, name, Reflect.callMethod(target, value, adapted), origin);
      return historicalScoringResult(target, name, args, result, origin);
    });
  }

  /** Convert only historical song path results, after the normal interpreter access checks. */
  public static function historicalSongResult(target:Dynamic, name:String, value:Dynamic, origin:Null<String>):Dynamic
  {
    if (!Std.isOfType(target, funkin.play.song.Song.SongDifficulty) || !isLegacyOrigin(origin)) return value;
    if (name == "getInstPath" && Std.isOfType(value, funkin.assets.Paths.AssetPath))
      return cast(value, funkin.assets.Paths.AssetPath).toString();
    if (["buildVoiceList", "buildPlayerVoiceList", "buildOpponentVoiceList"].contains(name) && Std.isOfType(value, Array))
    {
      var paths:Array<Dynamic> = cast value;
      return paths.map(path -> Std.isOfType(path, funkin.assets.Paths.AssetPath)
        ? cast(path, funkin.assets.Paths.AssetPath).toString() : path);
    }
    return value;
  }

  /** Remove only super-call skip markers added by a failed interpreter call. */
  public static function withSafeScriptSuper(target:Dynamic, method:String, run:Void->Dynamic):Dynamic
  {
    var prior:Null<Array<String>> = cast Reflect.field(target, '_skipAscFrom');
    var before = 0;
    if (prior != null) for (entry in prior) if (entry == method) before++;
    try return run() catch (error:Dynamic)
    {
      var current:Null<Array<String>> = cast Reflect.field(target, '_skipAscFrom');
      if (current != null)
      {
        var count = 0;
        for (entry in current) if (entry == method) count++;
        var i = current.length - 1;
        while (i >= 0 && count > before)
        {
          if (current[i] == method) { current.splice(i, 1); count--; }
          i--;
        }
      }
      throw error;
    }
  }

  static final previewNoteStylePathMethods:Array<String> = [
    'getNoteAssetPath', 'getHoldNoteAssetPath', 'getStrumlineAssetPath', 'getSplashAssetPath',
    'getHoldCoverDirectionAssetPath', 'buildCountdownSpritePath', 'buildJudgementSpritePath',
    'buildComboNumSpritePath', 'getCountdownSoundPath'
  ];

  static function nativeNoteStyle(target:Dynamic):Null<funkin.play.notes.notestyle.NoteStyle>
  {
    var current:Dynamic = target;
    var depth = 0;
    while (Std.isOfType(current, PolymodScriptClass) && depth++ < 32)
      current = cast(current, PolymodScriptClass).superClass;
    return Std.isOfType(current, funkin.play.notes.notestyle.NoteStyle) ? cast current : null;
  }

  public static function isPreviewNoteStylePathTarget(target:Dynamic, name:String, origin:Null<String>):Bool
  {
    return previewNoteStylePathMethods.contains(name) && nativeNoteStyle(target) != null
      && hasApiVersion(origin, '>=0.9.0 <0.10.0');
  }

  public static function isPreviewNoteStylePrivateSuperTarget(target:Dynamic, name:String, origin:Null<String>):Bool
  {
    return name == 'getHoldCoverRootAssetPath' && nativeNoteStyle(target) != null && hasApiVersion(origin, '>=0.9.0 <0.10.0');
  }

  public static function previewNoteStylePathResult(target:Dynamic, name:String, args:Array<Dynamic>, value:Dynamic,
    origin:Null<String>, nativeSuper:Bool = false):Dynamic
  {
    if (value == null || !Std.isOfType(value, String) || !previewNoteStylePathMethods.contains(name)) return value;
    var style = nativeNoteStyle(target);
    if (style == null || !hasApiVersion(origin, '>=0.9.0 <0.10.0')) return value;
    // A scripted override can return a different path from the style data.
    // Keep that result; when calling super, Polymod's skip list selects data.
    var script = Reflect.field(style, '_asc');
    var skip:Null<Array<String>> = cast Reflect.field(style, '_skipAscFrom');
    var overridden = !nativeSuper && script != null && polymod.hscript.PolymodScriptBridge.findOverride(script, skip, name) != null;
    if (!overridden && name == 'buildCountdownSpritePath' && Type.getClass(style) != funkin.play.notes.notestyle.NoteStyle)
    {
      // This older virtual method has no raw flag. Preserve the data's library
      // when its result matches the inherited implementation, but respect a
      // native subclass which actually returned a different path.
      return PreviewNoteStylePaths.countdownFromNative(style, args, cast value);
    }
    return @:privateAccess style.resolvePreviewAssetPath(name, args, overridden ? cast value : null);
  }

  /** Preserve origin and recheck access when a script stores a bound method. */
  public static function previewNoteStylePathMethod(target:Dynamic, name:String, value:Dynamic, origin:Null<String>,
    nativeSuper:Bool = false):Dynamic
  {
    if (!Reflect.isFunction(value) || !(previewNoteStylePathMethods.contains(name) || (nativeSuper && isPreviewNoteStylePrivateSuperTarget(target, name, origin))) || nativeNoteStyle(target) == null
      || !hasApiVersion(origin, '>=0.9.0 <0.10.0')) return value;
    return Reflect.makeVarArgs(function(args:Array<Dynamic>):Dynamic {
      var scriptName = polymod.util.Util.getScriptClassName(target);
      if (scriptName != null && ((PolymodScriptClass.blacklistedScriptClassStaticFields.get(scriptName)?.contains(name) ?? false)
        || (PolymodScriptClass.blacklistedScriptClassInstanceFields.get(scriptName)?.contains(name) ?? false)))
        throw 'Cannot access blacklisted field $name';
      var native = nativeNoteStyle(target);
      var cls = native == null ? null : Type.getClass(native);
      var clsName = cls == null ? null : Type.getClassName(cls);
      if (clsName != null && PolymodScriptClass.blacklistedInstanceFieldsOf(clsName).contains(name))
        throw 'Cannot access blacklisted field $name';
      if (native != null)
      {
        var script = Reflect.field(native, '_asc');
        var skip:Null<Array<String>> = cast Reflect.field(native, '_skipAscFrom');
        if (nativeSuper || script == null || polymod.hscript.PolymodScriptBridge.findOverride(script, skip, name) == null)
        {
          var candidate = PreviewNoteStylePaths.resolve(native, name, args, true);
          if (candidate != PreviewNoteStylePaths.UNHANDLED) return candidate;
        }
      }
      var result:Dynamic;
      if (nativeSuper && native != null)
      {
        // A saved super method runs after Polymod has removed its skip marker.
        // Restore it only for this invocation, even when the method throws.
        var skip:Null<Array<String>> = cast Reflect.field(native, '_skipAscFrom');
        if (skip == null)
        {
          skip = [];
          Reflect.setField(native, '_skipAscFrom', skip);
        }
        skip.push(name);
        try
        {
          result = Reflect.callMethod(target, value, args);
          skip.pop();
        }
        catch (error:Dynamic)
        {
          skip.pop();
          throw error;
        }
      }
      else result = Reflect.callMethod(target, value, args);
      return previewNoteStylePathResult(target, name, args, result, origin, nativeSuper);
    });
  }

  /** Pre-0.6.3 PBOT1 gave zero for an out-of-window note; later versions use -100. */
  public static function historicalScoringResult(target:Dynamic, name:String, args:Array<Dynamic>, value:Dynamic, origin:Null<String>):Dynamic
  {
    if (Std.isOfType(target, funkin.play.components.PopUpStuff) && name == 'displayCombo'
      && hasApiVersion(origin, '>=0.1.0 <0.5.0')) return args.length == 0 || args[0] == null ? 0 : args[0];
    if (target != funkin.play.scoring.Scoring || name != 'scoreNote' || !hasApiVersion(origin, '>=0.1.0 <0.6.0')) return value;
    if (args.length == 0 || !(Std.isOfType(args[0], Int) || Std.isOfType(args[0], Float))) return value;
    if (args.length > 1 && args[1] != null && args[1] != 'PBOT1') return value;
    var timing:Float = cast args[0];
    return Math.abs(timing) > funkin.play.scoring.Scoring.PBOT1_MISS_THRESHOLD ? 0 : value;
  }

  /** Apply the same rule to reads and saved methods, after normal static-field checks. */
  public static function historicalScoringRead(target:Dynamic, name:String, value:Dynamic, origin:Null<String>):Dynamic
  {
    if (target != funkin.play.scoring.Scoring || !hasApiVersion(origin, '>=0.1.0 <0.6.0')) return value;
    if (name == 'PBOT1_MISS_SCORE') return 0;
    if (name != 'scoreNote' || !Reflect.isFunction(value)) return value;
    return Reflect.makeVarArgs(function(args:Array<Dynamic>):Dynamic {
      var blacklist = polymod.hscript._internal.PolymodScriptClass.blacklistedStaticFields.get(target);
      if (blacklist != null && blacklist.contains(name)) throw 'Cannot access blacklisted field $name';
      var result = Reflect.callMethod(target, value, args);
      return historicalScoringResult(target, name, args, result, origin);
    });
  }

  public static function usesAnimationCallbacks(origin:Null<String>):Bool
  {
    return hasApiVersion(origin, '>=0.1.0 <0.5.0');
  }

  /** v0.3/v0.4 placed atlas characters before the renderer's first bounds calculation. */
  public static function usesInitialAtlasPlacement(origin:Null<String>):Bool
  {
    return hasApiVersion(origin, '>=0.1.0 <0.5.0');
  }

  /** The child atlas renderer through 0.7 retained the exported stage instance matrix. */
  public static function usesHistoricalAtlasStageMatrix(origin:Null<String>):Bool
  {
    return hasApiVersion(origin, '>=0.1.0 <0.8.0');
  }

  public static function usesRepeatedFields(origin:Null<String>):Bool
  {
    return hasApiVersion(origin, '>=0.1.0 <0.7.2');
  }

  public static function usesImplicitMembers(origin:Null<String>):Bool
  {
    return hasApiVersion(origin, '>=0.1.0 <0.8.2');
  }

  public static function usesLooseMethodArguments(origin:Null<String>):Bool
  {
    return hasApiVersion(origin, '>=0.1.0 <0.8.2');
  }

  /** Before v0.6.0 note effects were hard-coded, even for newer style schemas. */
  public static function usesHardcodedNoteEffects(origin:Null<String>):Bool
  {
    return hasApiVersion(origin, '>=0.1.0 <0.6.0');
  }

  /** Treat declared pre-0.5.2 API styles as using the original static receptor behavior. */
  public static function freezesStaticReceptor(origin:Null<String>):Bool
  {
    return hasApiVersion(origin, '>=0.1.0 <0.5.2');
  }

  /** Old note/receptor sizing changed at v0.5.1 without changing schema 1.1.0. */
  public static function noteSizingForOrigin(origin:Null<String>):Null<Int>
  {
    if (apiVersionForOrigin(origin) == null) return null;
    if (hasApiVersion(origin, '>=0.1.0 <0.5.0')) return 1;
    if (hasApiVersion(origin, '>=0.5.0 <0.5.1')) return 2;
    return 0;
  }

  static function hasApiVersion(origin:Null<String>, rule:String):Bool
  {
    var text = apiVersionForOrigin(origin);
    if (text == null) return false;
    var policies = versionPolicies.get(origin);
    if (policies != null && policies.exists(rule)) return policies.get(rule);
    var version:thx.semver.Version = text;
    var matches = funkin.util.VersionUtil.validateVersion(version, rule);
    if (policies == null)
    {
      policies = [];
      versionPolicies.set(origin, policies);
    }
    policies.set(rule, matches);
    return matches;
  }

  static function apiVersionForOrigin(origin:Null<String>):Null<String>
  {
    if (origin == null || !StringTools.startsWith(origin, 'hscriptClass(') || !StringTools.endsWith(origin, ')')) return null;
    if (library != Polymod.assetLibrary)
    {
      library = Polymod.assetLibrary;
      profiles.clear();
      versionPolicies.clear();
    }
    if (library == null) return null;
    var id = origin.substring('hscriptClass('.length, origin.length - 1);
    if (profiles.exists(id)) return profiles.get(id);
    if (!StringTools.startsWith(id, 'assets/'))
    {
      profiles.set(id, null);
      return null;
    }
    var apiVersion:Null<String> = null;
    try
    {
      var physical = Polymod.assetLibrary.getPath(id);
      if (physical == null)
      {
        profiles.set(id, null);
        return null;
      }
      var source = Path.normalize(physical);
      #if windows
      source = source.toLowerCase();
      #end
      for (dir in Polymod.getLoadedModDirs())
      {
        var prefix = Path.normalize(dir) + '/';
        #if windows
        prefix = prefix.toLowerCase();
        #end
        if (!StringTools.startsWith(source, prefix)) continue;
        var raw = Polymod.getFileSystem().getFileContent(Path.join([dir, polymod.PolymodConfig.modMetadataFile]));
        apiVersion = haxe.Json.parse(raw).api_version;
        break;
      }
    }
    catch (_:Dynamic) {}
    profiles.set(id, apiVersion);
    return apiVersion;
  }

  /** Adapt argument positions at the native boundary, after normal import checks. */
  public static function constructorArgs(cls:Class<Dynamic>, args:Array<Dynamic>, origin:Null<String>):Array<Dynamic>
  {
    if (cls == null) return args;
    switch (Type.getClassName(cls))
    {
      case 'funkin.data.song.SongMetadata':
        if (args.length == 3 && hasApiVersion(origin, '>=0.1.0 <0.7.0'))
          return [args[0], args[1], null, args[2]];
      case 'funkin.play.character.BaseCharacter':
        if (args.length == 2 && Std.isOfType(args[1], String) && isLegacyOrigin(origin))
          return [args[0], {renderType:args[1]}];
      case 'funkin.play.components.HealthIcon':
        // Up to 0.5.0 the no-argument constructor selected the BF icon.
        if (args.length == 0 && hasApiVersion(origin, '>=0.1.0 <0.5.1')) return ['bf'];
      case 'funkin.play.stage.Bopper':
        // Before 0.5.0 the default was to dance every beat.
        if (args.length == 0 && hasApiVersion(origin, '>=0.1.0 <0.5.0')) return [1];
      case 'funkin.modding.events.HitNoteScriptEvent':
        if (args.length >= 4 && args.length <= 5 && hasApiVersion(origin, '>=0.1.0 <0.5.0'))
          return [args[0], args[1], args[2], args[3], false, args.length == 5 ? args[4] : 0];
      case 'funkin.modding.events.HoldNoteScriptEvent':
        if (args.length == 6 && Std.isOfType(args[5], Bool) && hasApiVersion(origin, '>=0.1.0 <0.7.0'))
          return [args[0], args[1], args[2], args[3], args[4], 0, args[5]];
      default:
    }
    return args;
  }

  /** Expose the 0.9 static query where an older native instance method has the same name. */
  public static function previewStaticAssetQuery(target:Dynamic, field:String, value:Dynamic, origin:Null<String>):Dynamic
  {
    if (field != 'queryAssets' || value != null || !Std.isOfType(target, Class)
      || !hasApiVersion(origin, '>=0.9.0 <0.10.0')) return value;
    var className = Type.getClassName(cast target);
    if (!["funkin.play.song.Song", "funkin.play.stage.Stage", "funkin.play.notes.notestyle.NoteStyle",
      "funkin.play.character.BaseCharacter", "funkin.play.character.SparrowCharacter", "funkin.play.character.PackerCharacter",
      "funkin.play.character.AnimateAtlasCharacter", "funkin.play.character.MultiSparrowCharacter",
      "funkin.play.character.MultiAnimateAtlasCharacter"].contains(className)) return value;

    return Reflect.makeVarArgs(function(args:Array<Dynamic>):Dynamic
    {
      // A script can save the returned method before the blacklist changes.
      var blocked = PolymodScriptClass.blacklistedStaticFields.get(target);
      var objectType = polymod.util.Util.getTypeNameOf(target);
      var scriptName = polymod.util.Util.getScriptClassName(target);
      if ((blocked != null && blocked.contains(field))
        || (objectType != null && objectType != '' && objectType != 'Object'
          && PolymodScriptClass.blacklistedInstanceFieldsOf(objectType).contains(field))
        || (scriptName != null && ((PolymodScriptClass.blacklistedScriptClassStaticFields.get(scriptName)?.contains(field) ?? false)
          || (PolymodScriptClass.blacklistedScriptClassInstanceFields.get(scriptName)?.contains(field) ?? false))))
        throw 'Cannot access blacklisted field $field';
      if (args.length < 2 || args[1] == null) return [];
      var type:funkin.assets.Assets.AssetType = cast args[0];
      var id:String = cast args[1];
      var params:Dynamic = args.length > 2 ? args[2] : null;
      return switch (className)
      {
        case "funkin.play.song.Song": @:privateAccess funkin.data.song.SongRegistry.instance.queryDefaultAssets(type, id, params);
        case "funkin.play.stage.Stage": @:privateAccess funkin.data.stage.StageRegistry.instance.queryDefaultAssets(type, id, params);
        case "funkin.play.notes.notestyle.NoteStyle": @:privateAccess funkin.data.notestyle.NoteStyleRegistry.instance.queryDefaultAssets(type, id, params);
        case "funkin.play.character.BaseCharacter": @:privateAccess funkin.data.character.CharacterRegistry.instance.queryDefaultAssets(type, id, params);
        case "funkin.play.character.SparrowCharacter": funkin.data.character.CharacterRegistry.instance.queryCharacterAssets(type, id, params, 'sparrow');
        case "funkin.play.character.PackerCharacter": funkin.data.character.CharacterRegistry.instance.queryCharacterAssets(type, id, params, 'packer');
        case "funkin.play.character.AnimateAtlasCharacter": funkin.data.character.CharacterRegistry.instance.queryCharacterAssets(type, id, params, 'animateatlas');
        case "funkin.play.character.MultiSparrowCharacter": funkin.data.character.CharacterRegistry.instance.queryCharacterAssets(type, id, params, 'multisparrow');
        case "funkin.play.character.MultiAnimateAtlasCharacter": funkin.data.character.CharacterRegistry.instance.queryCharacterAssets(type, id, params, 'multianimateatlas');
        default: [];
      }
    });
  }

  /** Native Song callbacks now have a character argument absent from old overrides. */
  public static function scriptMethodArgs(target:polymod.hscript._internal.PolymodScriptClass, name:String,
    args:Array<Dynamic>):Array<Dynamic>
  {
    if (name != 'getFirstValidVariation' || args == null || args.length != 3) return args;
    var declaration = target.findFunction(name);
    if (declaration == null) return args;
    var native:Dynamic = target.superClass;
    while (Std.isOfType(native, polymod.hscript._internal.PolymodScriptClass))
      native = cast(native, polymod.hscript._internal.PolymodScriptClass).superClass;
    if (!Std.isOfType(native, funkin.play.song.Song)) return args;
    if (declaration.args.length == 3)
    {
      if (Std.isOfType(args[1], Array)) return [args[0], null, args[2] ?? args[1]];
      return args;
    }
    if (declaration.args.length != 2 || !hasApiVersion(declaration.expr?.origin, '>=0.1.0 <0.5.0')) return args;
    var variations:Dynamic = args[2];
    if (variations == null)
    {
      if (Std.isOfType(args[1], Array)) variations = args[1];
      else if (args[1] != null) variations = cast(native, funkin.play.song.Song).getVariationsByCharacter(args[1]);
    }
    return [args[0], variations];
  }

  /** Called after the interpreter has checked all import and field blacklists. */
  public static function setNativeField(o:Dynamic, field:String, value:Dynamic, origin:Null<String>, ?proxy:Dynamic, bypassAccessor:Bool = false):Bool
  {
    // Some old character mods wrote the instance timer through BaseCharacter.
    // Only recover this unambiguous field when the current script owns a character.
    if (isLegacyOrigin(origin) && o == funkin.play.character.BaseCharacter && field == 'holdTimer'
      && (Std.isOfType(value, Int) || Std.isOfType(value, Float)))
    {
      var character = nativeBopper(proxy);
      if (Std.isOfType(character, funkin.play.character.BaseCharacter))
      {
        var scriptName = polymod.util.Util.getScriptClassName(proxy);
        var cls = Type.getClass(character);
        var clsName = cls == null ? null : Type.getClassName(cls);
        var staticBlocked = PolymodScriptClass.blacklistedStaticFields.get(o);
        if ((staticBlocked != null && staticBlocked.contains(field))
          || (clsName != null && PolymodScriptClass.blacklistedInstanceFieldsOf(clsName).contains(field))
          || (scriptName != null && ((PolymodScriptClass.blacklistedScriptClassStaticFields.get(scriptName)?.contains(field) ?? false)
            || (PolymodScriptClass.blacklistedScriptClassInstanceFields.get(scriptName)?.contains(field) ?? false))))
          throw 'Cannot access blacklisted field $field';
        if (bypassAccessor) Reflect.setField(character, field, value); else Reflect.setProperty(character, field, value);
        return true;
      }
    }
    if (!isLegacyOrigin(origin) || (!Std.isOfType(o, Class) && Type.getClass(o) == null))
      return PolymodAbstractScriptClass.setClassObjectField(o, field, value, bypassAccessor);
    if (LegacyAnimationCallbacks.trySet(o, field, value, origin)) return true;
    var fields = Std.isOfType(o, Class) ? Type.getClassFields(o) : Type.getInstanceFields(Type.getClass(o));
    if (!fields.contains(field) && !fields.contains('set_$field')) throw 'No such field $field';
    // Static changes can outlive the owning mod. Instance writes belong to the
    // object's normal lifecycle; retaining sprites here would prevent disposal.
    if (Std.isOfType(o, Class))
    {
      var originals = originalFields.get(o);
      if (originals == null)
      {
        originals = [];
        originalFields.set(o, originals);
      }
      if (!originals.exists(field)) originals.set(field, Reflect.getProperty(o, field));
    }
    if (bypassAccessor) Reflect.setField(o, field, value); else Reflect.setProperty(o, field, value);
    return true;
  }
}
