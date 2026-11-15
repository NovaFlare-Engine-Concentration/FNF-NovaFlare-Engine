package originfunkin.compat;

#if (sys && FEATURE_DEBUG_FUNCTIONS)
import funkin.play.scoring.Scoring;
import funkin.play.scoring.Scoring.ScoringSystem;
import funkin.play.scoring.Scoring.ScoringRank;

/** Regression coverage for restored historical public APIs. */
class LegacyPublicApiChecks
{
  static function require(value:Bool, description:String):Void
  {
    if (!value) throw 'Legacy public API check failed: $description';
    trace('[Origin legacy public API] PASS $description');
  }

  public static function run():Void
  {
    var vocalOffsets = new funkin.data.song.SongData.SongOffsets();
    vocalOffsets.vocals.set('bf', 250);
    vocalOffsets.altVocals.set('alt', ['bf' => 600.0]);
    require(vocalOffsets.getVocalOffset('bf') == 250 && vocalOffsets.getVocalOffset('bf', '') == 250
      && vocalOffsets.getVocalOffset('bf', 'alt') == 600 && vocalOffsets.getVocalOffset('bf', 'missing') == 0,
      'default and alternate instrumental vocal offsets remain distinct');
    var keyboardEvent = new openfl.events.KeyboardEvent(openfl.events.KeyboardEvent.KEY_DOWN, true, false, 0, 65);
    var keyboardPayload = new funkin.modding.events.ScriptEvent.KeyboardInputScriptEvent(
      funkin.modding.events.ScriptEventType.KEY_DOWN, keyboardEvent);
    require(keyboardPayload.event == keyboardEvent && keyboardPayload.keyEvent == keyboardEvent
      && keyboardPayload.event.keyCode == 65, 'historical keyboard event alias retains the original payload');

    var boundary = Scoring.LEGACY_HIT_WINDOW * Scoring.LEGACY_SICK_THRESHOLD;
    require(Scoring.scoreNote(100, LEGACY) == 200 && Scoring.scoreNote(100, WEEK7) == 100,
      'legacy and week7 select their own historical thresholds');
    require(Scoring.scoreNote(boundary, LEGACY) == 200 && Scoring.judgeNote(boundary, LEGACY) == 'sick',
      'historical score and judgement use strict and inclusive boundaries');
    require(Scoring.scoreNote(30) == Scoring.scoreNote(30, PBOT1) && Scoring.judgeNote(30) == Scoring.judgeNote(30, PBOT1),
      'default scoring continues to use PBOT1');
    require(Scoring.getMissScore(LEGACY) == -10 && Scoring.getMissScore(WEEK7) == -10 && Scoring.getMissScore() == Scoring.PBOT1_MISS_SCORE,
      'historical miss scores and current default are distinct');
    require(ScoringRank.PERFECT_GOLD.getMusicPath() == 'resultsPERFECT'
      && ScoringRank.EXCELLENT.hasMusicIntro() && !ScoringRank.SHIT.shouldMusicLoop(), 'early results music methods');

    var merged:Dynamic = funkin.util.StructureUtil.merge({a: 1}, {b: 2});
    require(Reflect.field(merged, 'a') == 1 && Reflect.field(merged, 'b') == 2, 'historical structure merge');
    var protectedObject = new funkin.util.LegacyStructureBlacklistProbe();
    require(Reflect.fields(protectedObject).indexOf('secret') >= 0, 'blacklist fixture exposes its test field');
    require(funkin.util.ReflectUtil.field(protectedObject, 'secret') == 7, 'blacklist fixture starts accessible');
    polymod.Polymod.blacklistInstanceFields(funkin.util.LegacyStructureBlacklistProbe, ['secret']);
    @:privateAccess funkin.util.ReflectUtil.blacklistedFieldsCache.clear();
    var denied = 0;
    try funkin.util.StructureUtil.toMap(protectedObject) catch (_:Dynamic) denied++;
    try funkin.util.StructureUtil.merge({}, protectedObject) catch (_:Dynamic) denied++;
    try funkin.util.StructureUtil.deepMerge({}, protectedObject) catch (_:Dynamic) denied++;
    polymod.hscript._internal.PolymodScriptClass.blacklistedInstanceFields.remove(Type.getClassName(funkin.util.LegacyStructureBlacklistProbe));
    polymod.hscript._internal.PolymodScriptClass.bumpBlacklistGeneration();
    @:privateAccess funkin.util.ReflectUtil.blacklistedFieldsCache.clear();
    require(denied == 3, 'historical structure helpers enforce field blacklists');
    require(funkin.util.FlxColorUtil.interpolate(0xFF000000, 0xFFFFFFFF, 0) == 0xFF000000, 'historical color helper');
    require(funkin.util.assets.DataAssets.listDataFilesInPath('characters/')
      .join('|') == funkin.assets.Assets.listDataFilesInPath('data/characters/').join('|'), 'historical data enumerator');
    require(funkin.play.event.SongEventHelper.easeDirList.contains('sine')
      && funkin.play.event.SongEventHelper.easeDirs.contains('InOut'), 'historical easing list names');
    require(funkin.play.notes.notekind.NoteKindManager.listNoteStyles([]).length == 0, 'historical note style list contract');
    require(funkin.Conductor.instance.inputOffset == funkin.Preferences.globalOffset, 'historical input offset uses saved global offset');

    var legacyEvent = new funkin.data.song.SongData.SongEventDataRaw(1000, 'unknown-legacy-event', 25);
    var namedValue:Dynamic = legacyEvent.valueAsStruct('legacyValue');
    var unnamedValue:Dynamic = legacyEvent.valueAsStruct();
    require(Reflect.field(namedValue, 'legacyValue') == 25 && Reflect.field(unnamedValue, 'key') == 25,
      'historical event scalar keys and unknown-schema fallback');
    require(legacyEvent.getStepTime(true) == legacyEvent.getStepTime(null, true),
      'historical boolean step-time flag and current conductor signature');

    var previousKinds = funkin.play.notes.notekind.NoteKindManager.listNoteKinds();
    funkin.play.notes.notekind.NoteKindManager.registerBaseNoteKinds();
    funkin.play.notes.notekind.NoteKindManager.registerScriptedNoteKinds();
    var registeredKinds = funkin.play.notes.notekind.NoteKindManager.listNoteKinds();
    require(previousKinds.filter(kind -> registeredKinds.indexOf(kind) < 0).length == 0,
      'historical note kind registration retains existing entries');

    var song = new funkin.play.song.Song('legacy-split');
    var available = song.variations;
    require(available.length > 0 && song.getVariationsByCharId(available[0]).join('|') == available[0]
      && song.getVariationsByCharId('__missing_variation__').length == available.length,
      'early character variation lookup matches and falls back');

    var levelRegistry = funkin.data.story.level.LevelRegistry.instance;
    require(levelRegistry.listBaseGameLevelIds().join('|') == levelRegistry.listBaseGameEntryIds().join('|')
      && levelRegistry.listModdedLevelIds().join('|') == levelRegistry.listModdedEntryIds().join('|'), 'historical level list names');
    var playerRegistry = funkin.data.freeplay.player.PlayerRegistry.instance;
    require(playerRegistry.listBaseGamePlayerIds().join('|') == playerRegistry.listBaseGameEntryIds().join('|')
      && playerRegistry.listModdedPlayerIds().join('|') == playerRegistry.listModdedEntryIds().join('|'), 'historical player list names');

    var style = funkin.data.notestyle.NoteStyleRegistry.instance.fetchDefault();
    var lane = new funkin.play.notes.Strumline(style, false, 1);
    var previousFlag = funkin.play.notes.Strumline.USE_CUSTOM_RENDER_DISTANCE;
    var previousDistance = funkin.play.notes.Strumline.CUSTOM_RENDER_DISTANCE_MS;
    funkin.play.notes.Strumline.USE_CUSTOM_RENDER_DISTANCE = true;
    funkin.play.notes.Strumline.CUSTOM_RENDER_DISTANCE_MS = 1234;
    @:privateAccess var legacyDistance = lane.renderDistanceMs;
    lane.useCustomRenderDistance = true;
    lane.customRenderDistanceMs = 4321;
    @:privateAccess var instanceDistance = lane.renderDistanceMs;
    funkin.play.notes.Strumline.USE_CUSTOM_RENDER_DISTANCE = previousFlag;
    funkin.play.notes.Strumline.CUSTOM_RENDER_DISTANCE_MS = previousDistance;
    require(legacyDistance == 1234 && instanceDistance == 4321, 'legacy render distance and modern instance override');
    var direction = funkin.play.notes.NoteDirection.LEFT;
    lane.pressKey(direction);
    lane.pressKey(direction);
    lane.pressKey(direction, 13);
    lane.releaseKey(direction, 13);
    require(lane.isKeyHeld(direction), 'old no-keycode press remains held after another key is released');
    lane.releaseKey(direction);
    require(!lane.isKeyHeld(direction), 'old no-keycode release clears its held direction');
    var delta = lane.calculateNoteYPos(100) - lane.calculateNoteYPos(200);
    var expectedDelta = 100 * funkin.util.Constants.PIXELS_PER_MS * (funkin.Preferences.downscroll ? 1 : -1);
    require(Math.abs(delta - expectedDelta) < 0.001, 'historical note position direction and scale');
    lane.destroy();

    if (style.isNoteSplashEnabled())
    {
      funkin.play.notes.NoteSplash.preloadFrames();
      var splash = new funkin.play.notes.NoteSplash();
      require(splash.frames != null, 'historical no-argument splash uses default style');
      splash.destroy();
    }
    if (style.isHoldNoteCoverEnabled())
    {
      funkin.play.notes.NoteHoldCover.preloadFrames();
      var cover = new funkin.play.notes.NoteHoldCover();
      require(cover.glow.frames != null, 'historical no-argument hold cover uses default style');
      cover.destroy();
    }

    // Run through real Polymod script origins, including the new API boundary.
    var pathDifficulty = new funkin.play.song.Song.SongDifficulty(new funkin.play.song.Song('compat'), 'normal', 'default');
    pathDifficulty.legacyNeedsVoices = false;
    pathDifficulty.characters = new funkin.data.song.SongData.SongCharacterData('', '', '', 'default', ['declared']);
    require(pathDifficulty.getPlaybackInstPath(null).toString() == funkin.Paths.inst('compat'),
      'empty playback selection resolves the same default instrumental used by playInst');
    require(pathDifficulty.getPlaybackInstPath('declared').toString() == funkin.Paths.inst('compat', '-declared'),
      'explicit playback selection resolves the same instrumental used by playInst');
    var nativePath = pathDifficulty.getInstPath();
    require(nativePath != null, 'path fixture resolves a real instrumental');
    var pathEvent = new funkin.data.song.SongData.SongEventDataRaw(0, 'FocusCamera', 25);
    var schema = pathEvent.getSchema();
    require(schema != null && schema.getFirstField() != null && schema.getFirstField().name != 'key',
      'event fixture has a named modern schema field');
    for (api in ['0.8.0', '0.9.0'])
    {
      var name = 'HistoricalSongPath' + api.split('.').join('_');
      var path = 'assets/scripts/$name.hxc';
      var styleMethods = [
        {name: 'getNoteAssetPath', arg: ''}, {name: 'getHoldNoteAssetPath', arg: ''},
        {name: 'getStrumlineAssetPath', arg: ''}, {name: 'getSplashAssetPath', arg: ''},
        {name: 'getHoldCoverDirectionAssetPath', arg: 'direction'},
        {name: 'buildCountdownSpritePath', arg: 'step'},
        {name: 'buildJudgementSpritePath', arg: '"sick"'},
        {name: 'buildComboNumSpritePath', arg: '0'}, {name: 'getCountdownSoundPath', arg: 'step'}
      ];
      var scriptSource = @:privateAccess polymod.Polymod.assetLibrary.getText(path);
      // Append test-only methods in memory so the fixture retains its real mod origin.
      var classEnd = scriptSource.lastIndexOf('}');
      require(classEnd >= 0, 'API $api historical path probe has a class body');
      var stepArgs = api == '0.8.0' ? 'true' : 'conductor, true';
      var probes = '\n public function eventStep(event, conductor) { return event.getStepTime($stepArgs); }'
        + '\n public function savedEventStep(event, conductor) { var fn = event.getStepTime; return fn($stepArgs); }'
        + '\n public function dialogueText(box, value) { box.text = value; return box.text; }'
        + '\n public function dialogueSpeed(box, value) { box.speed = value; box.speed += 1; return box.speed; }'
        + '\n public function noteStylePath(style) { return style.getNoteAssetPath(); }'
        + '\n public function savedNoteStylePath(style) { var fn = style.getNoteAssetPath; return fn(); }\n';
      for (i in 0...styleMethods.length)
      {
        var methodName = styleMethods[i].name;
        var methodArgs = styleMethods[i].arg;
        probes += '\n public function styleDirect$i(style, direction, step) { return style.$methodName($methodArgs); }'
          + '\n public function styleSaved$i(style, direction, step) { var fn = style.$methodName; return fn($methodArgs); }';
      }
      scriptSource = scriptSource.substr(0, classEnd) + probes + scriptSource.substr(classEnd);
      if (api == '0.9.0')
      {
        // The extra class shares this probe's real mod origin; no files are changed.
        scriptSource = 'import funkin.play.notes.notestyle.NoteStyle;\n' + scriptSource
          + '\nclass OriginPreviewParentProbe extends NoteStyle {'
          + '\n public var compatProbeResult:Dynamic = null;'
          + '\n public var compatProbeCalls:Int = 0;'
          + '\n public function new(id) { super(id); }'
          + '\n public override function getNoteAssetPath(raw = false) { compatProbeCalls++; return compatProbeResult; }'
          + '\n}';
      }
      @:privateAccess polymod.hscript._internal.PolymodScriptClass.registerScriptClassByString(scriptSource, path);
      var instance = funkin.modding.base.Object.scriptInit(name);
      require(instance != null, 'API $api historical path probe constructs');
      var result:Dynamic = instance.scriptCall('path', [pathDifficulty]);
      require(api == '0.8.0' ? Std.isOfType(result, String) && result == nativePath.toString()
        : Std.isOfType(result, funkin.assets.Paths.AssetPath), 'API $api song path type');
      var stepEvent = new funkin.data.song.SongData.SongEventDataRaw(1000, 'FocusCamera', 25);
      var defaultStep = funkin.Conductor.instance.getTimeInSteps(stepEvent.time);
      var alternateConductor = new funkin.Conductor();
      alternateConductor.forceBPM((Math.abs(defaultStep) + 2) * 15);
      var alternateStep = alternateConductor.getTimeInSteps(stepEvent.time);
      require(alternateStep != defaultStep, 'API $api alternate conductor differs from the global one');
      var expectedStep = api == '0.8.0' ? defaultStep : alternateStep;
      require(instance.scriptCall('eventStep', [stepEvent, alternateConductor]) == expectedStep,
        'API $api event step-time direct call');
      require(instance.scriptCall('savedEventStep', [stepEvent, alternateConductor]) == expectedStep,
        'API $api event step-time saved call');
      // The text property does not need loaded graphics; use an empty instance
      // to test script field access without opening a dialogue or changing mods.
      var dialogueBox = Type.createEmptyInstance(funkin.play.cutscene.dialogue.DialogueBox);
      require(instance.scriptCall('dialogueText', [dialogueBox, 'compat text']) == 'compat text',
        'API $api dialogue text property script read/write');
      require(instance.scriptCall('dialogueSpeed', [dialogueBox, 2.0]) == 3.0,
        'API $api dialogue speed assignment and compound update');
      var dialogueDelay:Null<Float> = @:privateAccess dialogueBox.configuredTypingDelay;
      var expectedDelay = api == '0.8.0' ? 0.15 : 0.05 / 3.0;
      require(dialogueDelay != null && Math.abs(dialogueDelay - expectedDelay) < 0.000001,
        'API $api dialogue speed uses its version-specific timing');
      var noteStyle = funkin.data.notestyle.NoteStyleRegistry.instance.fetchEntry('funkin');
      require(noteStyle != null && noteStyle.getNoteAssetPath() != null, 'default note style has a note texture');
      for (method in ['noteStylePath', 'savedNoteStylePath'])
      {
        var notePath:Dynamic = instance.scriptCall(method, [noteStyle]);
        require(api == '0.8.0' ? Std.isOfType(notePath, String) && notePath == noteStyle.getNoteAssetPath()
          : Std.isOfType(notePath, funkin.assets.Paths.AssetPath) && cast(notePath, funkin.assets.Paths.AssetPath).exists(),
          'API $api $method returns its version-specific note path');
      }
      var direction:funkin.play.notes.NoteDirection = funkin.play.notes.NoteDirection.LEFT;
      var countdownStep:funkin.play.Countdown.CountdownStep = funkin.play.Countdown.CountdownStep.THREE;
      for (i in 0...styleMethods.length)
      {
        var pathMethod = styleMethods[i].name;
        var nativeArgs:Array<Dynamic> = switch (pathMethod)
        {
          case 'getHoldCoverDirectionAssetPath': [direction];
          case 'buildCountdownSpritePath' | 'getCountdownSoundPath': [countdownStep];
          case 'buildJudgementSpritePath': ['sick'];
          case 'buildComboNumSpritePath': [0];
          default: [];
        }
        var nativeMethod:Dynamic = Reflect.field(noteStyle, pathMethod);
        var legacyPath:Dynamic = Reflect.callMethod(noteStyle, nativeMethod, nativeArgs);
        var expected:Dynamic = api == '0.9.0' && legacyPath != null
          ? @:privateAccess noteStyle.resolvePreviewAssetPath(pathMethod, nativeArgs) : legacyPath;
        for (probe in ['styleDirect$i', 'styleSaved$i'])
        {
          var actual:Dynamic = instance.scriptCall(probe, [noteStyle, direction, countdownStep]);
          var matches = expected == null ? actual == null : api == '0.8.0'
            ? Std.isOfType(actual, String) && actual == expected
            : Std.isOfType(actual, funkin.assets.Paths.AssetPath)
              && cast(actual, funkin.assets.Paths.AssetPath).toString() == cast(expected, funkin.assets.Paths.AssetPath).toString();
          require(matches, 'API $api $probe matches $pathMethod contract');
        }
      }
      if (api == '0.9.0')
      {
        var registry = funkin.data.notestyle.NoteStyleRegistry.instance;
        var parentId = '__origin_preview_parent_probe__';
        require(!(@:privateAccess registry.entries.exists(parentId)), 'preview parent probe registry key is unused');
        var parent = funkin.play.notes.notestyle.NoteStyle.scriptInit('OriginPreviewParentProbe', 'funkin');
        require(parent != null, 'preview parent script constructs');
        var child = new funkin.play.notes.notestyle.NoteStyle('funkin');
        require(child._data != noteStyle._data && child._data.assets.note != null, 'preview child has independent note data');
        child._data.fallback = parentId;
        Reflect.setField(child._data.assets.note, 'assetPath', null);
        var expectedParent = @:privateAccess noteStyle.resolvePreviewAssetPath('getNoteAssetPath', []);
        require(expectedParent != null, 'preview parent probe has a real asset path');
        @:privateAccess registry.entries.set(parentId, parent);
        try
        {
          for (probe in ['styleDirect0', 'styleSaved0'])
          {
            parent.scriptSet('compatProbeResult', expectedParent);
            parent.scriptSet('compatProbeCalls', 0);
            var inherited:Dynamic = instance.scriptCall(probe, [child, direction, countdownStep]);
            require(inherited == expectedParent && parent.scriptGet('compatProbeCalls') == 1,
              'API $api $probe preserves a scripted parent object exactly once');
          }
          parent.scriptSet('compatProbeResult', null);
          parent.scriptSet('compatProbeCalls', 0);
          require(instance.scriptCall('styleDirect0', [child, direction, countdownStep]) == null
            && parent.scriptGet('compatProbeCalls') == 1, 'preview scripted parent null is preserved');
        }
        catch (error:Dynamic)
        {
          @:privateAccess registry.entries.remove(parentId);
          child.destroy();
          parent.destroy();
          throw error;
        }
        @:privateAccess registry.entries.remove(parentId);
        child.destroy();
        parent.destroy();

        // Exercise the real registry and native subclass dispatch, not only a scripted parent.
        var nativeId = '__origin_preview_native_parent_probe__';
        require(!(@:privateAccess registry.entries.exists(nativeId)), 'preview native parent probe registry key is unused');
        var nativeRaw = noteStyle.getHoldNoteAssetPath(true);
        var expectedNative = @:privateAccess noteStyle.resolvePreviewAssetPath('getHoldNoteAssetPath', []);
        require(nativeRaw != null && expectedNative != null, 'preview native parent probe has a real hold asset');
        var nativeParent = new LegacyNativeNoteStyleProbe(nativeRaw);
        var nativeChild = new funkin.play.notes.notestyle.NoteStyle('funkin');
        require(nativeChild._data != noteStyle._data && nativeChild._data.assets.note != null,
          'preview native child has independent note data');
        nativeChild._data.fallback = nativeId;
        Reflect.setField(nativeChild._data.assets.note, 'assetPath', null);
        @:privateAccess registry.entries.set(nativeId, nativeParent);
        try
        {
          for (target in [nativeParent, nativeChild])
            for (probe in ['styleDirect0', 'styleSaved0'])
            {
              nativeParent.calls = 0;
              var actual:Dynamic = instance.scriptCall(probe, [target, direction, countdownStep]);
              require(Std.isOfType(actual, funkin.assets.Paths.AssetPath)
                && cast(actual, funkin.assets.Paths.AssetPath).toString() == expectedNative.toString()
                && nativeParent.calls == 1 && nativeParent.lastRaw,
                'API $api $probe retains a native parent override exactly once');
            }
        }
        catch (error:Dynamic)
        {
          @:privateAccess registry.entries.remove(nativeId);
          nativeChild.destroy();
          nativeParent.destroy();
          throw error;
        }
        @:privateAccess registry.entries.remove(nativeId);
        nativeChild.destroy();
        nativeParent.destroy();
      }
      var scalar:Dynamic = instance.scriptCall('scalar', [pathEvent]);
      require(Reflect.field(scalar, api == '0.8.0' ? 'key' : schema.getFirstField().name) == 25,
        'API $api event scalar uses its historical or current default key');
      if (api == '0.8.0')
      {
        var savedMethod:Dynamic = instance.scriptCall('getSaved', [pathDifficulty]);
        var cls = funkin.play.song.Song.SongDifficulty;
        var oldBlacklist = polymod.hscript._internal.PolymodScriptClass.blacklistedInstanceFields.get(Type.getClassName(cls));
        polymod.Polymod.blacklistInstanceFields(cls, (oldBlacklist ?? []).concat(['getInstPath']));
        var denied = false;
        try Reflect.callMethod(null, savedMethod, ['declared']) catch (_:Dynamic) denied = true;
        polymod.Polymod.blacklistInstanceFields(cls, oldBlacklist ?? []);
        require(denied, 'saved historical song method respects later field blacklisting');
      }
      var savedScalar:Dynamic = instance.scriptCall('savedScalar', [pathEvent]);
      require(Reflect.field(savedScalar, api == '0.8.0' ? 'key' : schema.getFirstField().name) == 25,
        'API $api saved event method keeps its own default key');
      for (suffix in ['declared', 'unknown'])
      {
        var expectedSuffix = (api == '0.8.0' && suffix == 'unknown') ? 'default' : suffix;
        var direct:Dynamic = instance.scriptCall('pathWith', [pathDifficulty, suffix]);
        var saved:Dynamic = instance.scriptCall('savedPath', [pathDifficulty, suffix]);
        var expected = pathDifficulty.getInstPath(expectedSuffix).toString();
        require(Std.string(direct) == expected && Std.string(saved) == expected
          && (api == '0.8.0' ? Std.isOfType(saved, String) : Std.isOfType(saved, funkin.assets.Paths.AssetPath)),
          'API $api direct and saved instrumental methods select $suffix');
      }
    }
    var paths:Array<Dynamic> = [nativePath];
    var legacyPaths:Array<Dynamic> = cast LegacyRuntime.historicalSongResult(pathDifficulty, 'buildVoiceList', paths,
      'hscriptClass(assets/scripts/HistoricalSongPath0_8_0.hxc)');
    require(legacyPaths != paths && legacyPaths[0] == nativePath.toString() && paths[0] == nativePath,
      'historical voice array conversion preserves native input');

    for (api in ['0.1.0', '0.5.0', '0.6.3', '0.9.0'])
    {
      var name = 'HistoricalScoring' + api.split('.').join('_');
      var path = 'assets/scripts/$name.hxc';
      @:privateAccess polymod.hscript._internal.PolymodScriptClass.registerScriptClassByString(polymod.Polymod.assetLibrary.getText(path), path);
      var instance = funkin.modding.base.Object.scriptInit(name);
      require(instance != null, 'API $api scoring probe constructs');
      var values:Array<Dynamic> = cast instance.scriptCall('values', []);
      var miss = ['0.1.0', '0.5.0'].contains(api) ? 0 : -100;
      require(values != null && values[0] == miss && values[1] == miss && values[2] == miss
        && values[3] == Scoring.scoreNote(160) && values[4] == 0,
        'API $api historical miss constant, direct and saved calls, threshold and legacy mode');
      if (api == '0.5.0')
      {
        var saved:Dynamic = instance.scriptCall('getSaved', []);
        var cls = Scoring;
        var oldBlacklist = polymod.hscript._internal.PolymodScriptClass.blacklistedStaticFields.get(cls);
        polymod.Polymod.blacklistStaticFields(cls, (oldBlacklist ?? []).concat(['scoreNote']));
        var denied = false;
        try Reflect.callMethod(null, saved, [170]) catch (_:Dynamic) denied = true;
        polymod.Polymod.blacklistStaticFields(cls, oldBlacklist ?? []);
        require(denied, 'saved historical scoring method respects later field blacklisting');
      }
    }

    var source = "import funkin.modding.base.Object; import funkin.play.scoring.Scoring; import funkin.play.scoring.Scoring.ScoringSystem; class OriginLegacyPublicApiProbe extends Object { public function new() { super(); } public function read() { return Scoring.scoreNote(100, ScoringSystem.WEEK7); } }";
    @:privateAccess polymod.hscript._internal.PolymodScriptClass.registerScriptClassByString(source, 'assets/scripts/OriginLegacyPublicApiProbe.hxc');
    var probe = funkin.modding.base.Object.scriptInit('OriginLegacyPublicApiProbe');
    require(probe != null && probe.scriptCall('read', []) == 100, 'historical scoring API is callable by an HScript mod');
  }
}

/** Native subclass used only by the explicit compatibility regression runner. */
private class LegacyNativeNoteStyleProbe extends funkin.play.notes.notestyle.NoteStyle
{
  final probeRaw:String;
  public var calls:Int = 0;
  public var lastRaw:Bool = false;

  public function new(probeRaw:String)
  {
    super('funkin');
    this.probeRaw = probeRaw;
  }

  override public function getNoteAssetPath(raw:Bool = false):Null<String>
  {
    calls++;
    lastRaw = raw;
    return probeRaw;
  }
}

#end
