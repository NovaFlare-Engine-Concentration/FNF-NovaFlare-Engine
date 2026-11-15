package originfunkin.compat;

using Lambda;

#if (sys && FEATURE_DEBUG_FUNCTIONS)
/** Real filesystem/archive checks, invoked explicitly with external fixtures. */
@:access(polymod.Polymod)
@:access(polymod.hscript._internal.PolymodScriptClass)
@:access(flxanimate.animate.FlxAnim)
@:access(funkin.play.GameOverSubState)
@:access(funkin.play.stage.Bopper)
@:access(funkin.data.event.SongEventRegistry)
class CompatibilityChecks
{
  static function require(condition:Bool, message:String):Void
  {
    if (!condition) throw 'Origin compatibility check failed: $message';
    trace('[Origin compatibility check] PASS $message');
  }

  public static function run():Void
  {
    var arg = Sys.args().find(value -> StringTools.startsWith(value, '--origin-fixtures='));
    if (arg == null) throw 'Provide --origin-fixtures=<fixture directory> for compatibility checks.';
    var root = arg.substr('--origin-fixtures='.length);
    verifyHistoricalData(root);
    verifyLegacySections(root);
    var fs = new LegacyModFileSystem({modRoot:root, autoScan:true});
    var mods = polymod.Polymod.scan({modRoot:root, fileSystem:fs, apiVersionRule:funkin.modding.PolymodHandler.API_VERSION_RULE});
    for (version in ['0.1.0', '0.5.0', '0.6.3', '0.7.0', '0.8.0', '0.8.8', '0.9.0'])
      require(mods.exists(mod -> mod.id == 'api-$version'), 'metadata API $version admitted');
    require(!mods.exists(mod -> mod.id == 'api-0.0.9'), 'pre-Polymod API rejected');
    require(!mods.exists(mod -> mod.id == 'api-1.0.0'), 'future API rejected');

    var entries = fs.readModDirectory('api-0.1.0');
    var oldAudio = haxe.io.Path.join([root, 'api-0.1.0/songs/compat/Inst.ogg']);
    var newAudio = haxe.io.Path.join([root, 'api-0.1.0/gameplay/songs/compat/Inst.ogg']);
    require(entries.contains('gameplay/songs/compat/Inst.ogg'), 'legacy song audio indexed under canonical ID');
    require(fs.getFileBytes(oldAudio).compare(fs.getFileBytes(newAudio)) == 0, 'alias reads original audio bytes');
    require(fs.resolveAlias(newAudio) == oldAudio, 'alias exposes a real file path to native audio/video');
    require(entries.contains('gameplay/characters/compat/compat.json'), 'flat character registry indexed under nested ID');
    require(fs.getFileContent(haxe.io.Path.join([root, 'api-0.1.0/gameplay/songs/override/Inst.ogg'])) == 'modern',
      'modern file wins over legacy alias within one mod');

    var zipMod = mods.find(mod -> mod.id == 'zip-legacy');
    require(zipMod != null, 'ZIP metadata scanned');
    fs.readModDirectory(zipMod.dirName);
    verifyCharacterProfiles(fs, root);
    require(fs.getFileContent(haxe.io.Path.join([root, zipMod.dirName, 'gameplay/songs/zip/Inst.ogg'])) == 'zip-audio',
      'ZIP alias reads archived bytes');

    // Exercise Polymod's real indexing and precedence, not just filesystem methods.
    polymod.Polymod.init({modRoot:root, modIds:['api-0.1.0', 'api-0.5.0', 'api-0.5.1', 'api-0.6.3', 'api-0.7.0', 'api-0.7.2', 'api-0.8.0', 'api-0.8.1', 'api-0.8.2', 'api-0.8.8', 'api-0.9.0', 'zip-legacy', 'zip-case-256', 'profile-modern'], framework:OPENFL,
      apiVersionRule:funkin.modding.PolymodHandler.API_VERSION_RULE, customFilesystem:fs,
      frameworkParams:{assetLibraryPaths:['default' => '']}, useScriptedClasses:false});
    require(polymod.Polymod.assetLibrary.getBytes('assets/gameplay/songs/compat/Inst.ogg').toString() == 'later-mod',
      'Polymod preserves order between legacy mods using canonical IDs');
    var caseMetadata = 'assets/gameplay/songs/CompatMixed/CompatMixed-metadata.json';
    var caseChart = 'assets/gameplay/songs/CompatMixed/CompatMixed-chart.json';
    var caseIds = funkin.modding.compat.RegistryData.listEntryIds('gameplay/songs/', '-metadata', true);
    require(caseIds.contains('CompatMixed') && openfl.utils.Assets.exists(caseMetadata) && openfl.utils.Assets.exists(caseChart),
      'old mixed-case directory and filename are registered without changing original files');
    require(polymod.Polymod.assetLibrary.getText(caseMetadata).indexOf('Its Ok') >= 0
      && polymod.Polymod.assetLibrary.getText('assets/gameplay/songs/CompatModern/CompatModern-metadata.json').indexOf('Explicit Modern Priority') >= 0,
      'case alias reads the original metadata and explicit modern metadata takes priority');
    var caseSong = new funkin.play.song.Song('CompatMixed');
    caseSong.cacheCharts();
    require(caseSong.getDifficulty('hard') != null && caseSong.getDifficulty('hard').notes.length > 0,
      'mixed-case legacy metadata and chart load through the real song parser');
    var queriedSongData = funkin.data.song.SongRegistry.instance.queryAssets(funkin.assets.Assets.AssetType.JSON, 'CompatMixed');
    require(queriedSongData.exists(path -> StringTools.endsWith(path.toString(), '/CompatMixed-metadata.json'))
      && queriedSongData.exists(path -> StringTools.endsWith(path.toString(), '/CompatMixed-chart.json')),
      'song registry queries legacy aliased metadata and chart');
    var zipCase = new funkin.play.song.Song('ZipMixed');
    zipCase.cacheCharts();
    require(caseIds.contains('ZipMixed') && zipCase.getDifficulty('hard') != null && zipCase.getDifficulty('hard').notes.length > 0,
      'mixed-case legacy metadata and chart load from ZIP');
    require(polymod.Polymod.assetLibrary.getText('assets/gameplay/songs/LayerMixed/LayerMixed-metadata.json').indexOf('Later Mod Wins') >= 0,
      'later mod modern metadata wins over an earlier mixed-case alias');
    require(polymod.Polymod.assetLibrary.getBytes('assets/gameplay/characters/bf/bf.png').toString() == 'legacy-character-image',
      'historical image type directory maps to its canonical asset');
    require(polymod.Polymod.assetLibrary.getBytes('assets/ui/title/gf-dance-title.png').toString() == 'legacy-preload-image',
      'earliest assets/preload image layout overrides a canonical asset');
    require(polymod.Polymod.assetLibrary.getText('assets/ui/title/intro-text.txt').split('append-marker').length == 2,
      'legacy text append applies once through canonical ID');
    var entry = funkin.modding.compat.RegistryData.loadEntryData('compat', '', 'gameplay/characters/', true);
    require(entry.contents.split('merge-marker').length == 2, 'legacy registry merge applies once through canonical ID');
    funkin.assets.FunkinAssetCache.instance.cacheAssetLists(true);
    verifyCharacterScriptPaths();
    verifyLegacySongMount(root);
    verifyLegacyRuntime();
    verifyPreviewDialogueData();
    verifyMalformedMetadataCompatibility();
    verifyScriptAnonymousArgument();
    verifyPreviewRegistryAssetScript();
    verifyPreviewEventAssetScript();
    verifyPreviewPathAndEventApi();
    verifyHistoricalConstructors();
    verifyNativeConstructors();
    verifySongMethods();
    verifyLegacySwitchConstants();
    verifyHistoricalEnums();
    verifyAnimationCallbacks();
    verifyForcedAnimationPolicy();
    verifyLegacyCharacterTimer();
    verifyGameOverCalls();
    SongSerializerChecks.run(root);
    #if hxvlc
    var folderVideo:Dynamic = LegacyVideoLocation.resolve('assets/videos/folder.mp4');
    require(Std.isOfType(folderVideo, String) && sys.FileSystem.exists(folderVideo), 'folder video asset resolves to a real VLC path');
    var zipVideo:Dynamic = LegacyVideoLocation.resolve('assets/videos/archive.mp4');
    require(Std.isOfType(zipVideo, haxe.io.Bytes) && cast(zipVideo, haxe.io.Bytes).toString() == 'archive-video',
      'archive video asset resolves to VLC byte input');
    #end
    CoreDependencyChecks.run(root);
    FieldDeclarationChecks.run();
    NoteStyleDataChecks.run(root);
    #if (windows && cpp)
    AstcSoftwareChecks.run();
    #end
    PlayerDataChecks.run(root);
    LegacyCharacterChecks.inspectHistoricalAtlases();
    LegacyPublicApiChecks.run();
    ImplicitVariableChecks.run();
    ArgumentScopeChecks.run();
    verifyPolicyReload(fs, root);
    // Use the actual asynchronous backend, including its worker/main-thread handoff.
    var mainThread = sys.thread.Thread.current();
    var callbacks = [for (_ in 0...32) 0];
    var wrongThread = false;
    var reads:Array<lime.app.Future<haxe.io.Bytes>> = [];
    for (i in 0...callbacks.length)
    {
      var index = i;
      var read = polymod.backends.LimeBackend.LimeAsyncHandler.loadBytesFromFileSystem(oldAudio, fs);
      read.onComplete(bytes ->
      {
        callbacks[index]++;
        if (sys.thread.Thread.current() != mainThread) wrongThread = true;
        require(bytes.toString() == 'legacy-audio', 'async read $index returns original bytes');
      });
      reads.push(read);
    }
    lime.app.Future.all(reads).onComplete(_ -> haxe.Timer.delay(() ->
    {
      require(!wrongThread, 'async filesystem callbacks run on the main thread');
      require(callbacks.foreach(count -> count == 1), 'each async filesystem callback runs exactly once');
      trace('[Origin compatibility check] ALL FOUNDATION CHECKS PASSED');
      // This target intentionally replaced the active libraries with test fixtures.
      Sys.exit(0);
    }, 200));
  }

  static function verifyPreviewDialogueData():Void
  {
    var registry = funkin.data.dialogue.ConversationRegistry.instance;
    var base:Dynamic = {version: '1.0.0', backdrop: {type: 'solid', color: '#00000000'},
      dialogue: [{speaker: 'bf', box: 'roses', text: ['first']}]};
    var legacy = registry.parseEntryDataRaw(haxe.Json.stringify(base), 'legacy conversation');
    require(legacy != null && legacy.dialogue.length == 1 && !legacy.dialogue[0].autoAdvance,
      'legacy dialogue retains manual advancement when new fields are absent');
    base.version = '1.1.0';
    base.dialogue[0].sounds = ['dialogue/test'];
    base.dialogue[0].autoAdvance = true;
    base.dialogue[0].autoAdvanceFromLine = 1;
    base.dialogue[0].speed = 2.0;
    var preview = registry.parseEntryDataRaw(haxe.Json.stringify(base), 'preview conversation');
    require(preview != null && preview.dialogue.length == 1 && preview.dialogue[0].sounds[0] == 'dialogue/test'
      && preview.dialogue[0].autoAdvance && preview.dialogue[0].autoAdvanceFromLine == 1 && preview.dialogue[0].speed == 2.0,
      'preview dialogue accepts custom typing sound, auto-advance and speed');
    base.dialogue[0].sounds = [];
    var silent = registry.parseEntryDataRaw(haxe.Json.stringify(base), 'silent preview conversation');
    require(silent != null && silent.dialogue[0].sounds != null && silent.dialogue[0].sounds.length == 0,
      'preview dialogue preserves explicitly silent typing');
  }

  static function verifyMalformedMetadataCompatibility():Void
  {
    var malformed = '{"title":"preview", "api_version":"0.9.0", "mod_version":"3.0.0(beta1)", "contributors":[{"name":"x",}],}';
    var normalized = LegacyMetadataCompat.normalize(malformed);
    var parsed = polymod.Polymod.ModMetadata.fromJsonStr(normalized);
    require(parsed != null && parsed.apiVersion.toString() == '0.9.0' && parsed.modVersion.toString() == '3.0.0-beta1',
      'metadata fallback repairs trailing commas and parenthesized prerelease');
    var valid = '{"title":"punctuation ,]", "api_version":"0.9.0", "mod_version":"1.0.0"}';
    require(LegacyMetadataCompat.normalize(valid) == valid, 'valid metadata and punctuation inside strings stay unchanged');
    var invalid = '{"title":}';
    require(LegacyMetadataCompat.normalize(invalid) == invalid, 'metadata fallback does not hide unrelated malformed JSON');
  }

  static function verifyScriptAnonymousArgument():Void
  {
    var path = 'compat/PreviewAnonymousQuery.hxc';
    var script = 'import funkin.play.song.Song; class PreviewAnonymousQuery extends Song {'
      + ' public static function queryAssets(type, id, params) { return [type, id, params.variation]; } }';
    polymod.hscript._internal.PolymodScriptClass.registerScriptClassByString(script, path);
    var values:Array<Dynamic> = cast polymod.hscript._internal.PolymodScriptClass.callScriptClassStaticFunction(
      'PreviewAnonymousQuery', 'queryAssets', ['IMAGE', 'test-song', {variation: 'alt'}]);
    require(values != null && values.length == 3 && values[0] == 'IMAGE' && values[1] == 'test-song' && values[2] == 'alt',
      'script static query reads native anonymous arguments without null deprecation lookup');
    polymod.hscript._internal.PolymodScriptClass.registerScriptClassByString(
      'class PreviewAnonymousChild extends PreviewAnonymousQuery {}', 'compat/PreviewAnonymousChild.hxc');
    require(!polymod.hscript._internal.PolymodScriptClass.hasScriptClassStaticFunction('PreviewAnonymousChild', 'queryAssets'),
      'script child follows Haxe static method inheritance semantics');
  }

  static function verifyPreviewRegistryAssetScript():Void
  {
    var path = 'compat/PreviewRegistryQuery.hxc';
    var script = 'import funkin.play.song.Song; import funkin.assets.Paths; class PreviewRegistryQuery extends Song {'
      + ' public static function queryAssets(type, id, params) { return [Paths.image("ui/" + params.variation, false)]; } }';
    polymod.hscript._internal.PolymodScriptClass.registerScriptClassByString(script, path);
    var registry = funkin.data.song.SongRegistry.instance;
    @:privateAccess var scripts = registry.scriptedEntryIds;
    var id = '__compat_preview_query__';
    var previous = scripts.get(id);
    scripts.set(id, 'PreviewRegistryQuery');
    var values = registry.queryAssets(funkin.assets.Assets.AssetType.IMAGE, id, {variation: 'alt'});
    if (previous == null) scripts.remove(id); else scripts.set(id, previous);
    require(values.length == 1 && StringTools.endsWith(values[0].toString(), '/ui/alt.png'),
      'real song registry dispatches 0.9 script static asset query with variation');
  }

  static function verifyPreviewEventAssetScript():Void
  {
    var path = 'assets/scripts/PreviewAssetEvent.hxc';
    polymod.hscript._internal.PolymodScriptClass.registerScriptClassByString(polymod.Polymod.assetLibrary.getText(path), path);
    var handler = funkin.play.event.SongEvent.scriptInit('PreviewAssetEvent', 'unused');
    require(handler != null && handler.id == 'preview-asset-event', 'preview asset event script constructs');
    var cache = funkin.data.event.SongEventRegistry.EVENT_CACHE;
    var prior = cache.get(handler.id);
    cache.set(handler.id, handler);
    var data = new funkin.data.song.SongData.SongEventDataRaw(0, handler.id, {id: 'bf'});
    var paths = funkin.data.event.SongEventRegistry.queryAssets(funkin.assets.Assets.AssetType.IMAGE, data);
    if (prior == null) cache.remove(handler.id); else cache.set(handler.id, prior);
    require(paths.length == 1 && StringTools.endsWith(paths[0].toString(), '/gameplay/characters/bf/bf.png'),
      'preview HScript song event declares its image through the registry');
  }

  static function verifyPreviewPathAndEventApi():Void
  {
    var oldId = 'characters/BOYFRIEND.png';
    var rawPath = 'assets/characters/BOYFRIEND.png';
    require(funkin.modding.compat.Paths.getPath(oldId, 'default', false, false) == rawPath,
      'preview path opt-out returns the original normalized path');
    require(funkin.modding.compat.Paths.getPath(oldId, 'default', false) == 'assets/gameplay/characters/bf/bf.png',
      'default path resolution still redirects historical assets');
    require(funkin.modding.compat.Paths.getAnimateAtlasPath('no-such-atlas') == 'assets/no-such-atlas',
      'preview Animate atlas helper returns the resolved metadata directory');
    var event = new funkin.data.song.SongData.SongEventDataRaw(0, 'compat', {labels: ['one', 'two'], rates: [0.5, 1.25]});
    var typedEvent:funkin.data.song.SongData.SongEventData = event;
    var labels:Array<String> = typedEvent.getStringArray('labels');
    var rates:Array<Float> = typedEvent.getFloatArray('rates');
    require(labels != null && labels.length == 2 && labels[0] == 'one' && labels[1] == 'two'
      && rates != null && rates.length == 2 && rates[0] == 0.5 && rates[1] == 1.25,
      'event abstract forwards preview string and float array getters');
    var sharedParams:Array<funkin.data.song.SongData.NoteParamData> = [];
    var attack:funkin.data.song.SongData.SongNoteData = new funkin.data.song.SongData.SongNoteData(100, 0, 0, 'attack', sharedParams);
    var other:funkin.data.song.SongData.SongNoteData = new funkin.data.song.SongData.SongNoteData(100, 0, 0, 'other', sharedParams);
    var remaining = funkin.data.song.SongDataUtils.subtractNotes([attack, other], [attack.clone()]);
    require(attack != other && !(attack == other) && remaining.length == 1 && remaining[0] == other,
      'note matching distinguishes custom kinds while preserving clone-based editor subtraction');
  }

  static function verifyGameOverCalls():Void
  {
    var probes:Map<String, funkin.modding.base.Object> = [];
    for (api in ['0.1.0', '0.5.0', '0.8.8', '0.9.0'])
    {
      var name = 'GameOverCalls' + api.split('.').join('_');
      var path = 'assets/scripts/$name.hxc';
      polymod.hscript._internal.PolymodScriptClass.registerScriptClassByString(polymod.Polymod.assetLibrary.getText(path), path);
      var instance = funkin.modding.base.Object.scriptInit(name);
      require(instance != null, 'game-over call probe API $api loads');
      probes.set(api, instance);
    }
    var first = new funkin.play.GameOverSubState({transparent:false, isChartingMode:false});
    var second = new funkin.play.GameOverSubState({transparent:false, isChartingMode:false});
    funkin.play.GameOverSubState.instance = first;
    for (api in ['0.1.0', '0.5.0', '0.8.8'])
    {
      funkin.play.GameOverSubState.blueballed = false;
      probes.get(api).scriptCall('direct', []);
      require(first.gameOverSfx != null && funkin.play.GameOverSubState.blueballed,
        'API $api old static death sound calls the current game-over instance');
      first.destroyGameOverSfx();
    }
    var saved:Dynamic = probes.get('0.1.0').scriptCall('saved', []);
    require(Reflect.isFunction(saved) && Reflect.compareMethods(saved, probes.get('0.8.8').scriptCall('saved', [])),
      'historical static death sound references retain stable function identity');
    funkin.play.GameOverSubState.instance = second;
    Reflect.callMethod(null, saved, []);
    require(first.gameOverSfx == null && second.gameOverSfx != null,
      'a saved historical function uses the new game-over instance instead of retaining the old one');
    second.destroyGameOverSfx();
    for (api in ['0.1.0', '0.9.0'])
    {
      probes.get(api).scriptCall('instanceCall', [second]);
      require(second.gameOverSfx != null, 'API $api current instance method remains callable');
      second.destroyGameOverSfx();
    }
    var strict = probes.get('0.9.0');
    var handler = polymod.Polymod.onError;
    var errors:Array<polymod.Polymod.PolymodError> = [];
    polymod.Polymod.onError = error -> errors.push(error);
    var modern:Dynamic = strict.scriptCall('saved', []);
    polymod.Polymod.onError = handler;
    require(!Reflect.isFunction(modern), 'current API does not acquire a removed static method');
    var cls = funkin.play.GameOverSubState;
    var previous = polymod.hscript._internal.PolymodScriptClass.blacklistedStaticFields.get(cls) ?? [];
    polymod.Polymod.blacklistStaticFields(cls, previous.concat(['playBlueBalledSFX']));
    errors = [];
    polymod.Polymod.onError = error -> errors.push(error);
    probes.get('0.5.0').scriptCall('blocked', []);
    polymod.Polymod.onError = handler;
    polymod.Polymod.blacklistStaticFields(cls, previous);
    require(errors.exists(error -> error.message.toLowerCase().indexOf('blacklisted') >= 0) && second.gameOverSfx == null,
      'historical static method alias respects static field blacklists');
    var oldInstanceFields = polymod.hscript._internal.PolymodScriptClass.blacklistedInstanceFields.get(Type.getClassName(cls)) ?? [];
    polymod.Polymod.blacklistInstanceFields(cls, oldInstanceFields.concat(['playBlueBalledSFX']));
    var denied = false;
    try Reflect.callMethod(null, saved, []) catch (_:Dynamic) denied = true;
    polymod.Polymod.blacklistInstanceFields(cls, oldInstanceFields);
    require(denied && second.gameOverSfx == null, 'saved static compatibility functions cannot bypass native instance field blacklists');
    funkin.play.GameOverSubState.instance = null;
    funkin.play.GameOverSubState.blueballed = false;
    Reflect.callMethod(null, saved, []);
    require(funkin.play.GameOverSubState.blueballed, 'historical static death sound can execute outside a game-over instance');
    first.destroy();
    second.destroy();
    funkin.play.GameOverSubState.reset();
  }

  static function verifyPolicyReload(fs:LegacyModFileSystem, root:String):Void
  {
    var origin = 'hscriptClass(assets/scripts/PolicyReloadProbe.hxc)';
    for (id in ['policy-old', 'policy-current', 'policy-old'])
    {
      polymod.Polymod.init({modRoot:root, modIds:[id], framework:OPENFL,
        apiVersionRule:funkin.modding.PolymodHandler.API_VERSION_RULE, customFilesystem:fs,
        frameworkParams:{assetLibraryPaths:['default' => '']}, useScriptedClasses:false});
      var expected = id == 'policy-old';
      // Repeat both true and false lookups, then replace the library while keeping
      // the same source asset ID. Mod Menu reloads must not retain the old owner.
      for (_ in 0...3)
        require(LegacyRuntime.isLegacyOrigin(origin) == expected && LegacyRuntime.usesAnimationCallbacks(origin) == expected,
          'version policy cache follows $id after rebuilding the asset library');
    }
  }

  static function verifyCharacterProfiles(fs:LegacyModFileSystem, root:String):Void
  {
    var legacyData = haxe.Json.parse(fs.getFileContent(haxe.io.Path.join([root, 'api-0.1.0/gameplay/characters/bf/bf.json'])));
    var legacyScript = fs.getFileContent(haxe.io.Path.join([root, 'api-0.1.0/gameplay/characters/bf/bf.hxc']));
    require(legacyData.renderType == 'multisparrow' && legacyScript.indexOf('extends MultiSparrowCharacter') >= 0,
      'image-only old BF skins receive matching external metadata and stock script');
    fs.readModDirectory('profile-own');
    require(fs.getFileContent(haxe.io.Path.join([root, 'profile-own/gameplay/characters/bf/bf.hxc'])).indexOf('own-character-script-marker') >= 0,
      'an authored historical character script takes precedence over the stock profile');
    fs.readModDirectory('profile-explicit');
    var explicitData = fs.getFileContent(haxe.io.Path.join([root, 'profile-explicit/gameplay/characters/bf/bf.json']));
    require(explicitData.indexOf('explicit-marker') >= 0
      && fs.getFileContent(haxe.io.Path.join([root, 'profile-explicit/gameplay/characters/bf/bf.hxc'])).indexOf('extends SparrowCharacter') >= 0,
      'explicit legacy character data is preserved while the stock script matches its renderer');
    fs.readModDirectory('profile-modern');
    var modernData = haxe.Json.parse(fs.getFileContent(haxe.io.Path.join([root, 'profile-modern/gameplay/characters/bf/bf.json'])));
    require(modernData.renderType == 'multianimateatlas'
      && fs.getFileContent(haxe.io.Path.join([root, 'profile-modern/gameplay/characters/bf/bf.hxc'])).indexOf('extends MultiAnimateAtlasCharacter') >= 0,
      'a modern atlas override restores current stock renderer and script data');
    fs.readModDirectory('profile-stock');
    var stockRoot = haxe.io.Path.join([root, 'profile-stock']);
    var dadData = haxe.Json.parse(fs.getFileContent('$stockRoot/gameplay/characters/dad/dad.json'));
    var gfScript = fs.getFileContent('$stockRoot/gameplay/characters/gf/gf.hxc');
    require(dadData.renderType == 'sparrow' && !fs.exists('$stockRoot/gameplay/characters/dad/dad.hxc'),
      'stock profiles without core scripts publish metadata without inventing script classes');
    require(gfScript.indexOf('extends SparrowCharacter') >= 0
      && fs.getFileContent('$stockRoot/compatibility/origin-v0.3.2/sprites/gf.png') == 'legacy-gf-image',
      'historical stock image names select external atlas profiles and matching scripted renderers');
  }

  static function verifyCharacterScriptPaths():Void
  {
    var paths = LegacyScriptSources.unique(['assets/scripts/characters/legacy-path.hxc',
      'assets/gameplay/characters/legacy-path/legacy-path.hxc', 'assets/scripts/characters/shadowed-path.hxc',
      'assets/gameplay/characters/shadowed-path/shadowed-path.hxc', 'assets/scripts/stages/layout-stage.hxc',
      'assets/gameplay/stages/layout-stage/layout-stage.hxc', 'assets/scripts/songs/layout-song.hxc',
      'assets/gameplay/songs/layout-song/layout-song.hxc', 'assets/scripts/levels/layout-level.hxc',
      'assets/ui/story-mode/levels/layout-level.hxc']);
    require(paths.length == 5 && !paths.contains('assets/scripts/characters/shadowed-path.hxc')
      && !paths.contains('assets/scripts/stages/layout-stage.hxc'),
      'moved character scripts are loaded once and later canonical overrides hide old sources');
    for (path in paths)
      polymod.hscript._internal.PolymodScriptClass.registerScriptClassByString(polymod.Polymod.assetLibrary.getText(path), path);
    require(funkin.modding.base.Object.scriptInit('LegacyPathProbe').scriptCall('value', []) == 'old-path'
      && funkin.modding.base.Object.scriptInit('ShadowedPathProbe').scriptCall('value', []) == 'new-shadowed',
      'real script registration uses the selected historical or current source');
    require(funkin.modding.base.Object.scriptInit('LayoutStageProbe').scriptCall('value', []) == 'new-stage'
      && funkin.modding.base.Object.scriptInit('LayoutSongProbe').scriptCall('value', []) == 'old-song'
      && funkin.modding.base.Object.scriptInit('LayoutLevelProbe').scriptCall('value', []) == 'old-level',
      'moved stage, song and flat level scripts register once with canonical override priority');
    require(polymod.Polymod.assetLibrary.getText('assets/ui/shaders/AddColorShader.hxc').indexOf('old shader layout probe') >= 0
      && polymod.Polymod.assetLibrary.getText('assets/gameplay/characters/nene/ABotAtlasSprite.hxc').indexOf('old prop layout probe') >= 0
      && LegacyScriptSources.unique(['assets/scripts/shaders/AddColorShader.hxc', 'assets/ui/shaders/AddColorShader.hxc']).length == 1
      && LegacyScriptSources.unique(['assets/scripts/stages/props/ABotAtlasSprite.hxc',
        'assets/gameplay/characters/nene/ABotAtlasSprite.hxc']).length == 1,
      'moved shader and character prop scripts share their selected canonical source');
    var selected = haxe.Json.parse(polymod.Polymod.assetLibrary.getText('assets/gameplay/characters/bf/bf.json'));
    require(selected.renderType == 'multianimateatlas', 'later modern atlas mods supersede earlier image-only skin profiles');
  }

  /** The original old mod writes an instance timer through its class name. */
  static function verifyLegacyCharacterTimer():Void
  {
    var handler = polymod.Polymod.onError;
    var errors:Array<polymod.Polymod.PolymodError> = [];
    polymod.Polymod.onError = error -> errors.push(error);
    for (api in ['0.1.0', '0.5.0', '0.9.0'])
    {
      var name = 'LegacyTimerProbe' + api.split('.').join('_');
      var path = 'assets/scripts/$name.hxc';
      polymod.hscript._internal.PolymodScriptClass.registerScriptClassByString(polymod.Polymod.assetLibrary.getText(path), path);
      var character = funkin.play.character.BaseCharacter.scriptInit(name);
      require(character != null, 'character timer probe API $api loads');
      character.holdTimer = 4;
      errors.resize(0);
      Reflect.callMethod(character, Reflect.field(character, 'scriptCall'), ['assignTimer', [2.5]]);
      if (api == '0.9.0')
        require(character.holdTimer == 4 && errors.length > 0, 'current scripts retain invalid static-field diagnostics');
      else
        require(character.holdTimer == 2.5 && errors.length == 0, 'API $api static timer typo updates only its own character');
      if (api == '0.1.0')
      {
        var proxy = Reflect.field(character, '_asc');
        var oldOrigin = 'hscriptClass($path)';
        var oldInstance = polymod.hscript._internal.PolymodScriptClass.blacklistedInstanceFields.get(Type.getClassName(funkin.play.character.BaseCharacter)) ?? [];
        polymod.Polymod.blacklistInstanceFields(funkin.play.character.BaseCharacter, oldInstance.concat(['holdTimer']));
        var deniedInstance = false;
        try LegacyRuntime.setNativeField(funkin.play.character.BaseCharacter, 'holdTimer', 8, oldOrigin, proxy)
        catch (_:Dynamic) deniedInstance = true;
        polymod.Polymod.blacklistInstanceFields(funkin.play.character.BaseCharacter, oldInstance);
        var oldStatic = polymod.hscript._internal.PolymodScriptClass.blacklistedStaticFields.get(funkin.play.character.BaseCharacter) ?? [];
        polymod.Polymod.blacklistStaticFields(funkin.play.character.BaseCharacter, oldStatic.concat(['holdTimer']));
        var deniedStatic = false;
        try LegacyRuntime.setNativeField(funkin.play.character.BaseCharacter, 'holdTimer', 9, oldOrigin, proxy)
        catch (_:Dynamic) deniedStatic = true;
        polymod.Polymod.blacklistStaticFields(funkin.play.character.BaseCharacter, oldStatic);
        require(deniedInstance && deniedStatic && character.holdTimer == 2.5,
          'legacy timer recovery respects instance and static blacklists');
        var deniedUnrelated = false;
        try LegacyRuntime.setNativeField(funkin.play.character.BaseCharacter, 'holdTimer', 7, oldOrigin, null)
        catch (_:Dynamic) deniedUnrelated = true;
        require(deniedUnrelated && character.holdTimer == 2.5, 'timer recovery requires an owning character');
      }
      character.destroy();
    }
    polymod.Polymod.onError = handler;
  }

  /** Compare historical and modern HScript calls on actual native Boppers. */
  static function verifyForcedAnimationPolicy():Void
  {
    for (api in ['0.1.0', '0.5.0', '0.9.0'])
    {
      var name = 'ForceAnimationProbe' + api.split('.').join('_');
      var path = 'assets/scripts/$name.hxc';
      polymod.hscript._internal.PolymodScriptClass.registerScriptClassByString(polymod.Polymod.assetLibrary.getText(path), path);
      var probe = funkin.modding.base.Object.scriptInit(name);
      require(probe != null, 'forced animation probe API $api loads');
      for (method in ['direct', 'saved'])
      {
        var target = new funkin.play.stage.Bopper();
        target.makeGraphic(2, 2);
        target.animation.add('first', [0], 24, false);
        target.animation.add('second', [0], 24, false);
        target.setAnimationOffsets('first', 0, 0);
        target.setAnimationOffsets('second', 0, 0);
        target.animation.play('first', true);
        target.canPlayOtherAnims = false;
        probe.scriptCall(method, [target, true]);
        require(target.getCurrentAnimation() == (api == '0.1.0' ? 'second' : 'first'),
          'API $api $method uses its historical forced-animation rule');
        target.animation.play('first', true);
        target.canPlayOtherAnims = false;
        target.ignoreExclusionPref = ['second'];
        probe.scriptCall(method, [target, false]);
        require(target.getCurrentAnimation() == (api == '0.1.0' ? 'first' : 'second'),
          'API $api $method preserves its historical non-forced exclusion rule');
        target.animation.play('first', true);
        target.canPlayOtherAnims = false;
        target.ignoreExclusionPref = [];
        target.playAnimation('second', true, true);
        require(target.getCurrentAnimation() == 'first', 'API $api $method does not leak the script rule into native calls');
        target.destroy();
      }
      if (api == '0.1.0')
      {
        var target = new funkin.play.stage.Bopper();
        var saved:Dynamic = probe.scriptCall('capture', [target]);
        var previous = polymod.hscript._internal.PolymodScriptClass.blacklistedInstanceFields.get(Type.getClassName(funkin.play.stage.Bopper)) ?? [];
        polymod.Polymod.blacklistInstanceFields(funkin.play.stage.Bopper, previous.concat(['playAnimation']));
        var denied = false;
        try Reflect.callMethod(null, saved, ['second', true, true]) catch (_:Dynamic) denied = true;
        polymod.Polymod.blacklistInstanceFields(funkin.play.stage.Bopper, previous);
        require(denied, 'saved forced-animation method rechecks native field blacklist');
        var threw = false;
        try LegacyRuntime.withForcedAnimationRule('hscriptClass($path)', target, 'playAnimation', () -> { throw 'test exception'; })
        catch (_:Dynamic) threw = true;
        require(threw && !LegacyRuntime.usesForcedAnimationRule(), 'forced-animation scope is restored after an exception');
        var unrelatedScoped = LegacyRuntime.withForcedAnimationRule('hscriptClass($path)', {}, 'playAnimation',
          () -> LegacyRuntime.usesForcedAnimationRule());
        require(unrelatedScoped == false, 'unrelated playAnimation receivers do not activate the Bopper rule');
        var oldOrigin = 'hscriptClass($path)';
        var modernOrigin = 'hscriptClass(assets/scripts/ForceAnimationProbe0_9_0.hxc)';
        var nested = LegacyRuntime.withForcedAnimationRule(oldOrigin, target, 'playAnimation', () -> {
          var before = LegacyRuntime.usesForcedAnimationRule();
          var inner = LegacyRuntime.withForcedAnimationRule(modernOrigin, target, 'playAnimation',
            () -> LegacyRuntime.usesForcedAnimationRule());
          return before && inner == false && LegacyRuntime.usesForcedAnimationRule();
        });
        require(nested == true && !LegacyRuntime.usesForcedAnimationRule(),
          'nested modern calls temporarily replace and then restore the old rule');
        target.destroy();
      }
      if (api == '0.1.0')
      {
        var noOffsets = new funkin.play.stage.Bopper();
        noOffsets.makeGraphic(2, 2);
        noOffsets.animation.add('first', [0], 24, false);
        noOffsets.animation.add('second', [0], 24, false);
        noOffsets.globalOffsets = [12, -8];
        noOffsets.setAnimationOffsets('first', 4, 7);
        noOffsets.playAnimation('first', true);
        probe.scriptCall('direct', [noOffsets, true]);
        require(noOffsets.getCurrentAnimation() == 'second' && noOffsets.animOffsets[0] == 12 && noOffsets.animOffsets[1] == -8,
          'missing old animation offsets use the global anchor without retaining previous offsets');
        noOffsets.globalOffsets[0] = 20;
        require(noOffsets.animOffsets[0] == 12, 'missing animation offsets do not alias mutable global offsets');
        noOffsets.destroy();
      }
      var selfName = 'ForceAnimationSelf' + api.split('.').join('_');
      var selfPath = 'assets/scripts/$selfName.hxc';
      polymod.hscript._internal.PolymodScriptClass.registerScriptClassByString(polymod.Polymod.assetLibrary.getText(selfPath), selfPath);
      var self = funkin.play.stage.Bopper.scriptInit(selfName);
      require(self != null, 'scripted Bopper API $api loads');
      self.makeGraphic(2, 2);
      self.animation.add('first', [0], 24, false);
      self.animation.add('second', [0], 24, false);
      self.setAnimationOffsets('first', 0, 0);
      self.setAnimationOffsets('second', 0, 0);
      for (method in ['selfCall', 'superCall', 'savedSelf'])
      {
        self.animation.play('first', true);
        self.canPlayOtherAnims = false;
        Reflect.callMethod(self, Reflect.field(self, 'scriptCall'), [method, [true]]);
        require(self.getCurrentAnimation() == (api == '0.1.0' ? 'second' : 'first'),
          'API $api scripted Bopper $method follows its historical forced-animation rule');
      }
      if (api == '0.1.0')
      {
        var saved:Dynamic = Reflect.callMethod(self, Reflect.field(self, 'scriptCall'), ['captureSelf', []]);
        var proxy:Dynamic = Reflect.field(self, '_asc');
        var scriptName = polymod.util.Util.getScriptClassName(proxy);
        require(scriptName != null, 'saved self-method has a script owner');
        var blacklist = polymod.hscript._internal.PolymodScriptClass.blacklistedScriptClassInstanceFields;
        var previous = blacklist.get(scriptName);
        blacklist.set(scriptName, (previous ?? []).concat(['playAnimation']));
        var denied = false;
        try Reflect.callMethod(null, saved, ['second', true, true]) catch (_:Dynamic) denied = true;
        if (previous == null) blacklist.remove(scriptName); else blacklist.set(scriptName, previous);
        require(denied, 'saved self-method rechecks script class field blacklist');
      }
      self.destroy();
    }
  }

  static function verifyAnimationCallbacks():Void
  {
    var probes:Map<String, funkin.modding.base.Object> = [];
    for (api in ['0.1.0', '0.5.0', '0.8.8', '0.9.0'])
    {
      var name = 'AnimationCallbacks' + api.split('.').join('_');
      var path = 'assets/scripts/$name.hxc';
      polymod.hscript._internal.PolymodScriptClass.registerScriptClassByString(polymod.Polymod.assetLibrary.getText(path), path);
      var instance = funkin.modding.base.Object.scriptInit(name);
      require(instance != null, 'animation callback probe API $api loads');
      probes.set(api, instance);
    }
    // Use a real current external texture atlas, including the native destroy lifecycle.
    var sprite = new funkin.graphics.adobeanimate.FlxAtlasSprite(0, 0, 'assets/gameplay/characters/bf/bf-fakeout');
    var anim = sprite.anim;
    var signal = anim.onComplete;
    var frames = anim.onFrame;
    var nativeComplete = 0;
    var nativeFrames = 0;
    signal.add(() -> nativeComplete++);
    frames.add(_ -> nativeFrames++);
    var old = probes.get('0.1.0');
    var patch = probes.get('0.8.8');
    var current = probes.get('0.5.0');
    var strict = probes.get('0.9.0');
    require(old.scriptCall('readComplete', [anim]) == null && current.scriptCall('readComplete', [anim]) == signal
      && strict.scriptCall('readComplete', [anim]) == signal, 'old callback defaults and later signal defaults remain distinct');
    current.scriptCall('signalStyle', [anim]);
    var callback:Dynamic = old.scriptCall('setComplete', [anim, 1]);
    signal.dispatch();
    require(anim.onComplete == signal && Reflect.isFunction(callback) && nativeComplete == 1
      && old.scriptCall('values', []).complete == 1 && current.scriptCall('values', []).signal == 1,
      'legacy completion assignment coexists with native and scripted signal listeners');
    old.scriptCall('setComplete', [anim, 10]);
    signal.dispatch();
    require(old.scriptCall('values', []).complete == 11 && nativeComplete == 2,
      'legacy callback reassignment removes only its previous callback');
    require(old.scriptCall('clearComplete', [anim]) == null && anim.onComplete == signal,
      'legacy callback clearing retains the native signal');
    signal.dispatch();
    require(old.scriptCall('values', []).complete == 11 && current.scriptCall('values', []).signal == 3,
      'clearing an old callback preserves other signal listeners');
    old.scriptCall('setFrame', [anim, 1]);
    frames.dispatch(7);
    var values:Dynamic = old.scriptCall('values', []);
    require(values.frame == 1 && values.number == 7 && values.name == anim.curSymbol.name && nativeFrames == 1,
      'historical frame callback receives the native symbol name and frame number');
    old.scriptCall('setFrame', [anim, 10]);
    frames.dispatch(9);
    require(old.scriptCall('values', []).frame == 11 && nativeFrames == 2,
      'historical frame callback reassignment preserves other listeners');
    old.scriptCall('clearFrame', [anim]);
    frames.dispatch(11);
    require(old.scriptCall('values', []).frame == 11 && nativeFrames == 3,
      'clearing a frame callback removes only its own listener');
    var replacement = new flixel.util.FlxSignal();
    patch.scriptCall('setComplete', [anim, 1]);
    require(Reflect.isFunction(patch.scriptCall('readComplete', [anim])) && current.scriptCall('readComplete', [anim]) == signal,
      'patch-era callback assignments do not change another script source signal reads');
    patch.scriptCall('replaceSignal', [anim, replacement]);
    require(anim.onComplete == replacement && patch.scriptCall('readComplete', [anim]) == replacement,
      'assigning a signal restores current signal semantics');
    anim.onComplete = signal;
    old.scriptCall('setComplete', [anim, 1]);
    old.scriptCall('setFrame', [anim, 1]);
    var activeCallback = anim.originLegacyCallbacks.complete;
    var previousBlacklist = polymod.hscript._internal.PolymodScriptClass.blacklistedInstanceFields.get(Type.getClassName(flxanimate.animate.FlxAnim));
    var handler = polymod.Polymod.onError;
    var errors:Array<polymod.Polymod.PolymodError> = [];
    polymod.Polymod.onError = error -> errors.push(error);
    polymod.Polymod.blacklistInstanceFields(flxanimate.animate.FlxAnim, ['onComplete', 'callback']);
    var denied = false;
    try old.scriptCall('setComplete', [anim, 99]) catch (_:Dynamic) denied = true;
    polymod.Polymod.blacklistInstanceFields(flxanimate.animate.FlxAnim, previousBlacklist ?? []);
    polymod.Polymod.onError = handler;
    require((denied || errors.exists(error -> error.message.indexOf('blacklisted') >= 0)) && anim.onComplete == signal
      && Reflect.compareMethods(anim.originLegacyCallbacks.complete, activeCallback),
      'callback compatibility remains behind native field blacklists');
    sprite.destroy();
    require(anim.originLegacyCallbacks == null, 'destroyed animation controllers release compatibility callback state');
  }

  static function verifyHistoricalEnums():Void
  {
    for (api in ['0.1.0', '0.8.8'])
    {
      var name = 'DialogueEnums' + api.split('.').join('_');
      var path = 'assets/scripts/$name.hxc';
      polymod.hscript._internal.PolymodScriptClass.registerScriptClassByString(polymod.Polymod.assetLibrary.getText(path), path);
      var instance = funkin.modding.base.Object.scriptInit(name);
      require(instance != null, 'historical dialogue enum probe API $api loads');
      var backdrop:Dynamic = instance.scriptCall('backdrop', []);
      require(Type.getEnum(backdrop) == funkin.data.dialogue.ConversationData.BackdropData && Type.enumConstructor(backdrop) == 'SOLID'
        && instance.scriptCall('classify', [backdrop]) == '#123456', 'API $api moved backdrop enum retains native identity and pattern matching');
      var outro:Dynamic = instance.scriptCall('outro', []);
      require(Type.getEnum(outro) == funkin.data.dialogue.ConversationData.OutroData && Type.enumConstructor(outro) == 'FADE'
        && Type.enumParameters(outro)[0].fadeTime == 2, 'API $api moved outro enum retains native constructor data');
      require(Type.getEnum(instance.scriptCall('dotted', [])) == funkin.data.dialogue.ConversationData.OutroData,
        'API $api fully qualified historical enum path resolves');
    }
    var current = 'funkin.data.dialogue.BackdropData';
    polymod.Polymod.addImportAlias(current, null);
    require(LegacyTypePaths.resolveEnum('funkin.data.dialogue.conversation.ConversationData.BackdropData') == null,
      'historical enum alias respects a blacklist on the current native type');
    polymod.Polymod.removeImportAlias(current);
  }

  static function verifyLegacySongMount(root:String):Void
  {
    var library = polymod.Polymod.assetLibrary;
    var generatedPath = library.getPath('assets/gameplay/songs/legacy-grouped/legacy-grouped-chart.json');
    require(!sys.FileSystem.exists(generatedPath) && library.getText('assets/gameplay/songs/legacy-grouped/legacy-grouped-chart.json') != null,
      'section charts are exposed as virtual assets without writing generated files');
    var visibleChart = funkin.data.song.SongRegistry.instance.parseEntryChartData('legacy-split');
    require(visibleChart.events.length == 3 && visibleChart.events[1].time == 2000,
      'canonical chart consumers receive the representative legacy camera timeline');
    for (id in ['legacy-grouped', 'legacy-zip'])
    {
      var song = new funkin.play.song.Song(id);
      song.cacheCharts();
      require(song.getDifficulty('easy').notes.length == 110 && song.getDifficulty('normal').notes.length == 118
        && song.getDifficulty('hard').notes.length == 124, '$id runtime loads every official grouped difficulty');
      require(song.getDifficulty('hard').getStartingBPM() == 100 && song.getDifficulty('hard').scrollSpeed == 1.3,
        '$id grouped chart wins stale siblings and preserves hard scroll speed');
    }
    var split = new funkin.play.song.Song('legacy-split');
    require(split.getDifficulty('hard').getStartingBPM() == 171 && split.getDifficulty('normal').getStartingBPM() == 120,
      'legacy difficulty metadata is available before chart caching');
    split.getDifficulty('normal').noteStyle = 'script-style';
    split.getDifficulty('normal').stage = 'script-stage';
    split.cacheCharts();
    var normal = split.getDifficulty('normal');
    var hard = split.getDifficulty('hard');
    require(normal.notes.length == 3 && normal.events[1].time == 2000 && normal.timeChanges[1].bpm == 240
      && hard.notes.length == 1 && hard.stage == 'school' && hard.noteStyle == 'pixel' && hard.characters.girlfriend == 'gf-pixel',
      'sibling difficulty files retain distinct notes, section events, BPM and stage defaults');
    require(normal.noteStyle == 'script-style' && normal.stage == 'script-stage',
      'chart caching preserves live note style and stage changes made after metadata initialization');
    var previousEvent:funkin.data.song.SongData.SongEventDataRaw = normal.events[0];
    var previousCamera = normal.events[0].getInt('char');
    previousEvent.activated = true;
    Reflect.setField(previousEvent.value, 'char', 99);
    split.cacheCharts(true);
    var nextEvent:funkin.data.song.SongData.SongEventDataRaw = normal.events[0];
    require(nextEvent != previousEvent && !nextEvent.activated && normal.events[0].getInt('char') == previousCamera,
      'recaching legacy charts creates independent unactivated camera event data');
    normal.characters.player = 'script-player';
    var secondSplit = new funkin.play.song.Song('legacy-split');
    require(secondSplit.getDifficulty('normal').characters.player == 'bf',
      'separate legacy Song instances do not share mutable character metadata');
    require(split.getDifficulty('easy').notes.length == 0, 'empty authored legacy difficulties remain playable chart entries');
    require(hard.buildVoiceList().length == 0 && hard.buildVocals().members.length == 0,
      'needsVoices false disables both vocal caching and playback');
    var voices = split.getDifficulty('easy').buildVoiceList();
    require(voices.length == 2 && StringTools.endsWith(voices[0].toString(), 'Voices-customA.ogg')
      && StringTools.endsWith(voices[1].toString(), 'Voices-customB.ogg'), 'historical voiceList uses literal suffixes');
    require(normal.buildVoiceList().length == 1 && StringTools.endsWith(normal.buildVoiceList()[0].toString(), '/Voices.ogg'),
      'legacy combined voice file is used by a section-chart song');
    var partial = new funkin.play.song.Song('bopeebo');
    partial.cacheCharts();
    var base = funkin.data.song.SongRegistry.instance.parseEntryChartDataRaw(sys.io.File.getContent(
      haxe.io.Path.join([originfunkin.OriginFunkinMode.assetsRoot, 'gameplay/songs/bopeebo/bopeebo-chart.json'])));
    require(partial.getDifficulty('normal').notes.length == base.notes.get('normal').length
      && partial.getDifficulty('easy').notes.length == base.notes.get('easy').length && partial.getDifficulty('hard').notes.length == 1,
      'a hard-only legacy replacement retains untouched stock easy and normal charts');
    require(partial.getDifficulty('normal').getStartingBPM() == 100 && partial.getDifficulty('hard').getStartingBPM() == 171,
      'partial replacement retains stock timing independently from legacy hard timing');
    require(partial.songArtist == 'Kawai Sprite' && partial.getDifficulty('hard').album == 'volume1',
      'partial legacy replacement retains artist and album fields absent from the old format');
    require(partial.getDifficulty('normal').buildVoiceList().length == 1
      && StringTools.endsWith(partial.getDifficulty('normal').buildVoiceList()[0].toString(), '/Voices.ogg'),
      'legacy audio override outranks lower-layer stock split vocals');
    var modern = new funkin.play.song.Song('legacy-modern');
    modern.cacheCharts();
    require(modern.songName == 'Modern Metadata Wins' && modern.getDifficulty('normal').getStartingBPM() == 222
      && modern.getDifficulty('normal').notes.length == 1 && modern.getDifficulty('normal').notes[0].time == 99,
      'physical modern chart and metadata win within the same package');
    var overrideSong = new funkin.play.song.Song('legacy-metadata-override');
    overrideSong.cacheCharts();
    require(overrideSong.getDifficulty('normal').getStartingBPM() == 222 && overrideSong.getDifficulty('normal').notes.length == 3,
      'later modern metadata overrides generated timing without losing earlier legacy notes');
    require(overrideSong.getDifficulty('normal').legacyVoiceList == null && overrideSong.getDifficulty('normal').legacyNeedsVoices == null,
      'explicit later modern metadata restores its current vocal policy');
    var layered = new funkin.play.song.Song('legacy-layered');
    layered.cacheCharts();
    require(layered.getDifficulty('normal').notes.length == 3 && layered.getDifficulty('normal').getStartingBPM() == 120
      && layered.getDifficulty('hard').notes.length == 1 && layered.getDifficulty('hard').getStartingBPM() == 171,
      'partial legacy charts compose in Polymod order across packages');
    var patched = new funkin.play.song.Song('legacy-patched');
    patched.cacheCharts();
    var patchedNormal = patched.getDifficulty('normal');
    var patchedHard = patched.getDifficulty('hard');
    require(patchedNormal.notes.length == 4 && patchedHard.notes.length == 1 && patchedNormal.notes[3].time == 9999,
      'JSON Patch edits generated notes exactly once without losing other difficulties');
    require(patchedNormal.events.length == 4 && patchedHard.events.length == 2
      && patchedNormal.events.filter(event -> event.time == 3999).length == 1
      && patchedHard.events.filter(event -> event.time == 3999).length == 1,
      'JSON Patch edits each legacy camera timeline once and retains its section boundaries');
    require(patched.songArtist == 'Patch Artist' && patchedNormal.songArtist == 'Patch Artist' && patchedHard.songArtist == 'Patch Artist'
      && patchedNormal.timeChanges.length == 3 && patchedHard.timeChanges.length == 2
      && patchedNormal.getStartingBPM() == 120 && patchedHard.getStartingBPM() == 171,
      'metadata patches preserve distinct legacy difficulty timing');
    var voicePriority = new funkin.play.song.Song('legacy-voice-priority');
    require(voicePriority.getDifficulty('normal').buildVoiceList().length == 2,
      'later modern split vocal tracks win over earlier combined legacy vocals');
    var voiceFallback = new funkin.play.song.Song.SongDifficulty(voicePriority, 'normal', 'erect');
    voiceFallback.characters = new funkin.data.song.SongData.SongCharacterData('gf-car', '', 'dad-car');
    var playerFallback = voiceFallback.buildPlayerVoiceList();
    var opponentFallback = voiceFallback.buildOpponentVoiceList();
    require(playerFallback.length == 1 && StringTools.endsWith(playerFallback[0].toString(), '/Voices-gf.ogg')
      && opponentFallback.length == 1 && StringTools.endsWith(opponentFallback[0].toString(), '/Voices-dad.ogg'),
      'variation vocals fall back to unsuffixed shortened player and opponent IDs');
    voiceFallback.characters.player = 'bf-car';
    voiceFallback.characters.playerVocals = null;
    var playerVariant = voiceFallback.buildPlayerVoiceList();
    require(playerVariant.length == 1 && StringTools.endsWith(playerVariant[0].toString(), '/Voices-bf-erect.ogg'),
      'shortened variation-specific vocals take priority over unsuffixed vocals');
    var rawMetadata = new funkin.data.song.SongData.SongMetadata('Raw Song', 'Raw Artist');
    rawMetadata.playData.difficulties = ['normal'];
    rawMetadata.timeChanges[0].bpm = 333;
    var rawChart = new funkin.data.song.SongData.SongChartData(['normal' => 1.0], [],
      ['normal' => [new funkin.data.song.SongData.SongNoteData(10, 0)]]);
    var rawSong = funkin.play.song.Song.buildRaw('legacy-patched', [rawMetadata], 'default', ['default' => rawChart], false);
    require(rawSong.getDifficulty('normal').getStartingBPM() == 333 && rawSong.getDifficulty('normal').events.length == 0
      && rawSong.getDifficulty('normal').notes.length == 1 && rawSong.songArtist == 'Raw Artist',
      'explicit raw editor song data is independent from matching runtime legacy assets');
  }

  static function verifyLegacySections(root:String):Void
  {
    var official = funkin.data.song.importer.FNFLegacyImporter.parseLegacyDataRaw(sys.io.File.getContent(
      haxe.io.Path.join([root, 'official-samples/first-api-assets/bopeebo.json'])));
    require(official != null && official.song.needsVoices == true, 'official first-API-era grouped chart parses and retains its vocal flag');
    var officialChart = funkin.data.song.importer.FNFLegacyImporter.migrateChartData(official);
    var officialMeta = funkin.data.song.importer.FNFLegacyImporter.migrateMetadata(official);
    require(officialChart.notes.get('normal')?.length == 118 && officialChart.notes.get('hard')?.length == 124
      && officialChart.notes.get('easy')?.length == 110 && officialChart.scrollSpeed.get('hard') == 1.3,
      'official early grouped Bopeebo preserves all three difficulty note counts and hard scroll speed');
    require(officialMeta.playData.stage == 'mainStage' && officialMeta.playData.difficulties.length == 3
      && officialMeta.timeChanges[0].bpm == 100 && officialChart.events[0].time == 0 && officialChart.events[1].time == 2400,
      'official early Bopeebo stage alias, BPM and section camera boundaries migrate');
    var officialSingle = funkin.data.song.importer.FNFLegacyImporter.parseLegacyDataRaw(sys.io.File.getContent(
      haxe.io.Path.join([root, 'official-samples/first-api-assets/bopeebo-hard.json'])));
    require(officialSingle != null, 'official early single-difficulty chart tolerates extra root metadata');
    var singleChart = funkin.data.song.importer.FNFLegacyImporter.migrateChartData(officialSingle, 'hard');
    var singleNotes = singleChart.notes.get('hard');
    require(singleNotes != null && singleNotes.length == 124 && singleNotes[0].data == 6 && singleNotes[1].length == 600,
      'official early hard chart preserves opponent note direction and sustain duration');
    var raw = sys.io.File.getContent(haxe.io.Path.join([root, 'legacy-sections-single.json']));
    var single = funkin.data.song.importer.FNFLegacyImporter.parseLegacyDataRaw(raw);
    require(single != null, 'pre-VSlice single-difficulty section data parses');
    var meta = funkin.data.song.importer.FNFLegacyImporter.migrateMetadata(single);
    var chart = funkin.data.song.importer.FNFLegacyImporter.migrateChartData(single);
    require(meta.timeChanges.length == 2 && meta.timeChanges[1].timeStamp == 2000 && meta.timeChanges[1].bpm == 240
      && meta.timeChanges[1].beatTime == 4, 'empty legacy sections preserve BPM changes at their exact section boundary');
    require(chart.events.length == 3 && chart.events[0].time == 0 && chart.events[1].time == 2000 && chart.events[2].time == 2500
      && chart.events[0].getInt('char') == 1 && chart.events[1].getInt('char') == 0 && chart.events[2].getInt('char') == 1,
      'legacy focus changes include empty sections and do not wait for the first note');
    var notes = chart.notes.get('normal');
    require(notes != null && notes.length == 3 && notes[0].data == 4 && notes[1].data == 0 && notes[2].data == 5
      && notes[0].length == 100 && chart.scrollSpeed.get('normal') == 1.4, 'legacy note sides, sustain duration and scroll speed are preserved');
    var grouped = funkin.data.song.importer.FNFLegacyImporter.parseLegacyDataRaw(
      sys.io.File.getContent(haxe.io.Path.join([root, 'legacy-sections-grouped.json'])));
    require(grouped != null, 'earliest grouped-difficulty section data parses');
    var normal = funkin.data.song.importer.FNFLegacyImporter.migrateMetadata(grouped);
    var hard = funkin.data.song.importer.FNFLegacyImporter.migrateMetadata(grouped, 'hard');
    var hardChart = funkin.data.song.importer.FNFLegacyImporter.migrateChartData(grouped, 'hard');
    require(normal.timeChanges.length == 2 && normal.timeChanges[1].timeStamp == 2000
      && hard.timeChanges.length == 2 && hard.timeChanges[1].timeStamp == 1000 && hard.timeChanges[1].bpm == 180
      && hard.timeChanges[1].beatTime == 2 && normal.playData.difficulties.length == 3,
      'grouped legacy charts choose the requested difficulty timeline while preserving all difficulty IDs');
    require(hardChart.events.length == 2 && hardChart.events[1].time == 1000 && hardChart.notes.get('hard')?.length == 2
      && hardChart.scrollSpeed.get('hard') == 2 && hardChart.scrollSpeed.get('easy') == 0.8,
      'grouped legacy charts preserve difficulty scroll speeds and select the requested camera timeline');
    var firstChange:Dynamic = haxe.Json.parse(raw);
    firstChange.song.notes = [{mustHitSection:false, lengthInSteps:16, changeBPM:true, bpm:200, sectionNotes:[]}];
    var first = funkin.data.song.importer.FNFLegacyImporter.parseLegacyDataRaw(haxe.Json.stringify(firstChange));
    var firstMeta = funkin.data.song.importer.FNFLegacyImporter.migrateMetadata(first);
    require(firstMeta.timeChanges.length == 1 && firstMeta.timeChanges[0].bpm == 200 && firstMeta.timeChanges[0].beatTime == 0,
      'a first-section BPM change replaces the initial value without duplicate zero-time entries');
    firstChange.song.bpm = 0;
    var invalid = funkin.data.song.importer.FNFLegacyImporter.parseLegacyDataRaw(haxe.Json.stringify(firstChange));
    var rejected = false;
    try funkin.data.song.importer.FNFLegacyImporter.migrateMetadata(invalid)
    catch (error:Dynamic) rejected = Std.string(error).indexOf('Invalid legacy song BPM') >= 0;
    require(rejected, 'invalid legacy BPM is rejected before it can generate non-finite timestamps');
    firstChange.song.bpm = 120;
    firstChange.song.stage = 'school';
    firstChange.song.gfVersion = null;
    var pixel = funkin.data.song.importer.FNFLegacyImporter.parseLegacyDataRaw(haxe.Json.stringify(firstChange));
    var pixelMeta = funkin.data.song.importer.FNFLegacyImporter.migrateMetadata(pixel);
    require(pixelMeta.playData.noteStyle == 'pixel' && pixelMeta.playData.characters.girlfriend == 'gf-pixel',
      'legacy school stages retain their pixel note style and girlfriend');
    Reflect.deleteField(firstChange.song, 'stage');
    for (sample in [
      {song:'South', stage:'spookyMansion', gf:'gf'},
      {song:'Philly', stage:'phillyTrain', gf:'gf'},
      {song:'High', stage:'limoRide', gf:'gf-car'},
      {song:'Eggnog', stage:'mallXmas', gf:'gf-christmas'},
      {song:'Winter-Horrorland', stage:'mallEvil', gf:'gf-christmas'},
      {song:'Senpai', stage:'school', gf:'gf-pixel'},
      {song:'Thorns', stage:'schoolEvil', gf:'gf-pixel'},
      {song:'Ugh', stage:'tankmanBattlefield', gf:'gf-tankmen'},
      {song:'Stress', stage:'tankmanBattlefield', gf:'pico-speaker'},
      {song:'Darnell', stage:'phillyStreets', gf:'gf'}])
    {
      firstChange.song.song = sample.song;
      var data = funkin.data.song.importer.FNFLegacyImporter.parseLegacyDataRaw(haxe.Json.stringify(firstChange));
      var metadata = funkin.data.song.importer.FNFLegacyImporter.migrateMetadata(data);
      require(metadata.playData.stage == sample.stage && metadata.playData.characters.girlfriend == sample.gf,
        'pre-stage-metadata song ${sample.song} retains its original stage and girlfriend');
    }
    firstChange.song.player1 = 'pico';
    firstChange.song.song = 'Custom Song';
    var picoData = funkin.data.song.importer.FNFLegacyImporter.parseLegacyDataRaw(haxe.Json.stringify(firstChange));
    require(funkin.data.song.importer.FNFLegacyImporter.migrateMetadata(picoData).playData.characters.girlfriend == 'nene',
      'earliest playable Pico charts select Nene when no girlfriend was authored');
    firstChange.song.stage = 'mainStage';
    firstChange.song.gfVersion = 'gf';
    firstChange.song.song = 'Stress';
    var explicitData = funkin.data.song.importer.FNFLegacyImporter.parseLegacyDataRaw(haxe.Json.stringify(firstChange));
    var explicitMeta = funkin.data.song.importer.FNFLegacyImporter.migrateMetadata(explicitData);
    require(explicitMeta.playData.stage == 'mainStage' && explicitMeta.playData.characters.girlfriend == 'gf',
      'explicit legacy stage and girlfriend fields take precedence over song defaults');
  }

  static function verifyHistoricalData(root:String):Void
  {
    for (ref in ['v0.3.2', 'v0.5.0', 'v0.6.3', 'v0.7.0', 'v0.8.7'])
      for (kind in ['character', 'stage', 'notestyle', 'metadata', 'chart'])
      {
        var path = haxe.io.Path.join([root, 'official-samples', ref, '$kind.json']);
        var raw = sys.io.File.getContent(path);
        var versionText:String = haxe.Json.parse(raw).version;
        var version:thx.semver.Version = versionText;
        var valid = switch (kind)
        {
          case 'character':
            var value = funkin.data.character.CharacterRegistry.instance.parseEntryDataRaw(raw, path);
            value != null && value.name == 'Boyfriend' && value.animations.length > 0;
          case 'stage':
            var value = funkin.data.stage.StageRegistry.instance.parseEntryDataRaw(raw, path);
            value != null && value.characters.bf != null;
          case 'notestyle':
            var value = funkin.data.notestyle.NoteStyleRegistry.instance.parseEntryDataRaw(raw, path);
            value != null && value.assets.note != null;
          case 'metadata':
            var value = funkin.data.song.SongRegistry.instance.parseEntryMetadataRawWithMigration(raw, path, version);
            value != null && value.songName == 'Bopeebo' && value.timeChanges.length > 0;
          case 'chart':
            var value = funkin.data.song.SongRegistry.instance.parseEntryChartDataRawWithMigration(raw, path, version);
            value != null && value.notes.get('normal')?.length > 0;
          default: false;
        };
        require(valid, 'official $ref $kind schema $version parses with its essential data');
      }
    for (versionText in ['2.0.0', '2.1.0'])
    {
      var path = haxe.io.Path.join([root, 'official-samples', 'metadata-$versionText.json']);
      var raw = sys.io.File.getContent(path);
      var version:thx.semver.Version = versionText;
      var value = funkin.data.song.SongRegistry.instance.parseEntryMetadataRawWithMigration(raw, path, version);
      require(value != null && value.songName == 'Bopeebo' && value.playData.characters.player == 'bf'
        && value.playData.characters.girlfriend == 'gf' && value.playData.characters.opponent == 'dad'
        && value.playData.noteStyle == 'funkin', 'official metadata $versionText migrates characters and Normal note skin');
      var pixel:Dynamic = haxe.Json.parse(raw);
      pixel.playData.noteSkin = 'Pixel';
      value = funkin.data.song.SongRegistry.instance.parseEntryMetadataRawWithMigration(haxe.Json.stringify(pixel), path, version);
      require(value != null && value.playData.noteStyle == 'pixel', 'metadata $versionText preserves the Pixel note skin');
    }
  }

  static function verifySongMethods():Void
  {
    for (api in ['0.1.0', '0.5.0', '0.8.8', '0.9.0'])
    {
      var name = 'SongMethods' + StringTools.replace(api, '.', '_');
      var path = 'assets/scripts/$name.hxc';
      polymod.hscript._internal.PolymodScriptClass.registerScriptClassByString(polymod.Polymod.assetLibrary.getText(path), path);
      var instance = funkin.modding.base.Object.scriptInit(name);
      require(instance != null, 'song-method probe for API $api loads');
      for (stored in [false, true])
      {
        var song:funkin.play.song.Song = instance.scriptCall('build', [stored]);
        require(song != null && song.getRawMetadata().length == 2 && song.variations.length == 2
          && song.getDifficulty('normal', 'default') != null && song.getDifficulty('normal', 'erect') != null
          && song.variation == (api == '0.1.0' ? 'default' : 'erect') && !song.validScore,
          'API $api raw song preserves every variation through ${stored ? "stored" : "direct"} calls');
        song.destroy();
        require(instance.scriptCall('select', [stored, false]) == 'erect' && instance.scriptCall('select', [stored, true]) == null,
          'API $api variation array selects matches and rejects nonmatches through ${stored ? "stored" : "direct"} calls');
      }
      var albums:Map<String, String> = instance.scriptCall('albums', []);
      require(albums != null && albums.get('normal') == 'compat-album', 'API $api listAlbums still supports its old zero-argument form');
      require(instance.scriptCall('identity', []) == true, 'API $api native function references retain their identity');
    }
    for (name in ['OldSongOverride', 'NewSongOverride'])
    {
      var path = 'assets/scripts/$name.hxc';
      polymod.hscript._internal.PolymodScriptClass.registerScriptClassByString(polymod.Polymod.assetLibrary.getText(path), path);
      var song:funkin.play.song.Song = funkin.play.song.Song.scriptInit(name);
      require(song != null, '$name constructs its native song base');
      require(song.getFirstValidVariation('normal', null, ['erect']) == 'erect', '$name receives native callbacks with the correct argument positions');
      require(song.getFirstValidVariation('normal', ['legacy-array']) == 'legacy-array', '$name receives the historical two-argument form');
      song.destroy();
    }
  }

  static function verifyNativeConstructors():Void
  {
    // Native renderer subclasses still pass the historic string directly.
    var nativeCharacter = new funkin.play.character.BaseCharacter('gf-pixel', 'sparrow');
    require(nativeCharacter.renderType == 'sparrow', 'native character accepts the historical renderer string');
    nativeCharacter.destroy();
    var nativeMismatch = false;
    try
    {
      var unexpected = new funkin.play.character.BaseCharacter('gf-pixel', 'animateatlas');
      unexpected.destroy();
    }
    catch (error:Dynamic)
    {
      nativeMismatch = Std.string(error).indexOf('Render type mismatch') >= 0;
    }
    require(nativeMismatch, 'native character rejects a mismatched historical renderer string');

    for (api in ['0.1.0', '0.5.0', '0.6.3', '0.7.0', '0.8.8', '0.9.0'])
    {
      var name = 'NativeConstructor' + StringTools.replace(api, '.', '_');
      var path = 'assets/scripts/$name.hxc';
      polymod.hscript._internal.PolymodScriptClass.registerScriptClassByString(polymod.Polymod.assetLibrary.getText(path), path);
      var instance = funkin.modding.base.Object.scriptInit(name);
      require(instance != null, 'native constructor probe for API $api loads');
      var character:funkin.play.character.BaseCharacter = instance.scriptCall('character', []);
      require(character != null && character.characterId == 'gf-pixel' && character.renderType == 'sparrow',
        'API $api character render-type argument constructs its native character');
      character.destroy();
      var errors:Array<polymod.Polymod.PolymodError> = [];
      var handler = polymod.Polymod.onError;
      polymod.Polymod.onError = error -> errors.push(error);
      var mismatch = '';
      try instance.scriptCall('mismatch', [])
      catch (error:Dynamic) mismatch = Std.string(error);
      polymod.Polymod.onError = handler;
      require(mismatch.indexOf('Render type mismatch') >= 0 || errors.exists(error -> error.message.indexOf('Render type mismatch') >= 0),
        'API $api mismatched character render type is rejected instead of ignored');
      var hit:funkin.modding.events.ScriptEvent.HitNoteScriptEvent = instance.scriptCall('hit', []);
      require(hit != null && hit.comboCount == 42 && hit.score == 350 && hit.judgement == 'sick'
        && hit.isComboBreak == (api != '0.1.0') && hit.hitDiff == (api == '0.1.0' ? 0 : 12.5),
        'API $api hit-note constructor preserves combo, judgement and score');
      var defaultHit:funkin.modding.events.ScriptEvent.HitNoteScriptEvent = instance.scriptCall('hitDefault', []);
      require(defaultHit != null && defaultHit.comboCount == 0 && !defaultHit.isComboBreak,
        'API $api hit-note constructor defaults remain valid');
      var hold:funkin.modding.events.ScriptEvent.HoldNoteScriptEvent = instance.scriptCall('hold', []);
      var oldHold = api == '0.1.0' || api == '0.5.0' || api == '0.6.3';
      require(hold != null && hold.comboCount == (oldHold ? 0 : 42) && hold.score == 20 && !hold.isComboBreak,
        'API $api hold-note constructor preserves the shifted optional arguments');
    }
  }

  static function verifyLegacySwitchConstants():Void
  {
    for (api in ['0.1.0', '0.5.0', '0.8.8', '0.9.0'])
    {
      var name = 'SwitchConstant' + StringTools.replace(api, '.', '_');
      var path = 'assets/scripts/$name.hxc';
      polymod.hscript._internal.PolymodScriptClass.registerScriptClassByString(polymod.Polymod.assetLibrary.getText(path), path);
      var instance = funkin.modding.base.Object.scriptInit(name);
      require(instance != null, 'switch-constant probe for API $api loads');
      if (api == '0.9.0')
      {
        var errors:Array<polymod.Polymod.PolymodError> = [];
        var handler = polymod.Polymod.onError;
        polymod.Polymod.onError = error -> errors.push(error);
        instance.scriptCall('select', ['Song Name']);
        polymod.Polymod.onError = handler;
        require(errors.exists(error -> error.message.indexOf('Pattern variable') >= 0), 'later API retains its current pattern-matching rules');
      }
      else
      {
        require(instance.scriptCall('select', ['Song Name']) == 1 && instance.scriptCall('select', ['Time Left']) == 2
          && instance.scriptCall('select', ['other']) == 3, 'API $api switch compares static constants without capturing nonmatches');
        require(instance.scriptCall('localConstant', ['local']) == 4 && instance.scriptCall('localConstant', ['other']) == 5,
          'API $api switch compares local final constants');
        require(instance.scriptCall('variable', [1]) == 6 && instance.scriptCall('variable', [2]) == 7
          && instance.scriptCall('variable', [3]) == 8 && instance.scriptCall('variable', [99]) == 9,
          'API $api switch compares mutable instance and static values without capturing nonmatches');
        require(instance.scriptCall('reassign', []) == 6 && instance.scriptCall('variable', [1]) == 9,
          'API $api switch reads the current value after reassignment');
        require(instance.scriptCall('localVariable', [6]) == 10 && instance.scriptCall('localVariable', [5]) == 11,
          'API $api switch compares mutable local values');
        require(instance.scriptCall('inherited', [7]) == 12 && instance.scriptCall('inherited', [8]) == 13,
          'API $api switch resolves inherited instance values');
      }
      require(instance.scriptCall('wildcard', ['captured value']) == 'captured value', 'API $api wildcard pattern still binds its value');
      var binding:Array<Dynamic> = instance.scriptCall('explicitBinding', [17]);
      require(binding != null && binding.join(',') == '17,123', 'API $api explicit pattern bindings preserve the outer local');
      var errors:Array<polymod.Polymod.PolymodError> = [];
      var handler = polymod.Polymod.onError;
      polymod.Polymod.onError = error -> errors.push(error);
      instance.scriptCall('unknown', [1]);
      if (api == '0.9.0') instance.scriptCall('variable', [1]);
      polymod.Polymod.onError = handler;
      require(errors.length > 0, 'API $api unresolved uppercase switch names still report errors');
    }
  }

  static function verifyHistoricalConstructors():Void
  {
    for (api in ['0.5.0', '0.6.3', '0.7.0', '0.8.8'])
    {
      var name = 'MetadataConstructor' + StringTools.replace(api, '.', '_');
      var path = 'assets/scripts/$name.hxc';
      polymod.hscript._internal.PolymodScriptClass.registerScriptClassByString(polymod.Polymod.assetLibrary.getText(path), path);
      var instance = funkin.modding.base.Object.scriptInit(name);
      require(instance != null, 'metadata constructor probe for API $api loads');
      var three:funkin.data.song.SongData.SongMetadata = instance.scriptCall('threeArguments', []);
      var old = api == '0.5.0' || api == '0.6.3';
      require(three != null && three.songName == 'Probe' && three.artist == 'Artist'
        && three.variation == (old ? 'third' : 'default') && three.charter == (old ? null : 'third'),
        'API $api preserves the meaning of SongMetadata third argument through the interpreter');
      var four:funkin.data.song.SongData.SongMetadata = instance.scriptCall('fourArguments', []);
      require(four != null && four.charter == 'Charter' && four.variation == 'variation',
        'API $api explicit four-argument metadata stays unchanged');
      var two:funkin.data.song.SongData.SongMetadata = instance.scriptCall('twoArguments', []);
      require(two != null && two.charter == null && two.variation == 'default', 'API $api default metadata stays unchanged');
    }
    var args:Array<Dynamic> = ['Probe', 'Artist', 'Charter'];
    require(LegacyRuntime.constructorArgs(funkin.data.song.SongData.SongMetadata, args, 'hscript') == args,
      'unowned native constructors retain the current contract');
  }

  static function verifyLegacyRuntime():Void
  {
    var legacyPath = 'assets/scripts/LegacyRuntimeProbe.hxc';
    var modernOrigin = 'hscriptClass(assets/scripts/ModernRuntimeProbe.hxc)';
    require(LegacyRuntime.isLegacyOrigin('hscriptClass($legacyPath)'), 'script profile follows the owning legacy mod');
    require(!LegacyRuntime.isLegacyOrigin(modernOrigin), 'modern mod retains current native-write rules');
    require(!LegacyRuntime.isLegacyOrigin('hscript'), 'unowned script has current native-write rules');
    var original = funkin.util.Constants.STRUMLINE_X_OFFSET;
    polymod.hscript._internal.PolymodScriptClass.registerScriptClassByString(polymod.Polymod.assetLibrary.getText(legacyPath), legacyPath);
    var instance = funkin.modding.base.Object.scriptInit('LegacyRuntimeProbe');
    require(instance != null, 'old ScriptedObject import constructs its native base');
    var result:Dynamic = instance.scriptCall('probe', []);
    LegacyRuntime.restoreNativeWrites();
    require(result == original + 1, 'legacy native write executes through the real script interpreter');
    require(funkin.util.Constants.STRUMLINE_X_OFFSET == original, 'legacy native writes restore before changing mods');
    var point:flixel.math.FlxPoint = instance.scriptCall('pointProbe', []);
    LegacyRuntime.restoreNativeWrites();
    require(point != null && point.x == 73, 'instance writes follow object lifetime instead of static restoration');
    var patchPath = 'assets/scripts/PatchRuntimeProbe.hxc';
    polymod.hscript._internal.PolymodScriptClass.registerScriptClassByString(polymod.Polymod.assetLibrary.getText(patchPath), patchPath);
    var patchInstance = funkin.modding.base.Object.scriptInit('PatchRuntimeProbe');
    require(patchInstance != null && patchInstance.scriptCall('probe', []) == original + 2,
      'API 0.8.8 patch-level mods retain the 0.8 native-write contract');
    LegacyRuntime.restoreNativeWrites();
    require(funkin.util.Constants.STRUMLINE_X_OFFSET == original, 'API 0.8.8 native writes restore before changing mods');
    var rejected = false;
    try LegacyRuntime.setNativeField(funkin.util.Constants, 'STRUMLINE_X_OFFSET', original, modernOrigin)
    catch (_:Dynamic) rejected = true;
    require(rejected, 'modern script cannot assign a final native field');

    var modernPath = 'assets/scripts/ModernRuntimeProbe.hxc';
    polymod.hscript._internal.PolymodScriptClass.registerScriptClassByString(polymod.Polymod.assetLibrary.getText(modernPath), modernPath);
    var modernInstance = funkin.modding.base.Object.scriptInit('ModernRuntimeProbe');
    var errors:Array<polymod.Polymod.PolymodError> = [];
    var handler = polymod.Polymod.onError;
    polymod.Polymod.onError = error -> errors.push(error);
    modernInstance.scriptCall('probe', []);
    polymod.Polymod.onError = handler;
    require(errors.exists(error -> error.message.indexOf('final field') >= 0)
      && funkin.util.Constants.STRUMLINE_X_OFFSET == original, 'modern readonly rule holds through the actual script interpreter');

    var blacklisted = polymod.hscript._internal.PolymodScriptClass.blacklistedStaticFields.get(funkin.util.Constants) ?? [];
    polymod.Polymod.blacklistStaticFields(funkin.util.Constants, blacklisted.concat(['STRUMLINE_X_OFFSET']));
    errors = [];
    polymod.Polymod.onError = error -> errors.push(error);
    instance.scriptCall('assignOnly', []);
    polymod.Polymod.onError = handler;
    polymod.Polymod.blacklistStaticFields(funkin.util.Constants, blacklisted);
    require(errors.exists(error -> error.message.toLowerCase().indexOf('blacklisted') >= 0)
      && funkin.util.Constants.STRUMLINE_X_OFFSET == original, 'legacy native writes still respect field blacklists');
  }
}
#end
