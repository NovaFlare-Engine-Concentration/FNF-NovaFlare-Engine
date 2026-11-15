package originfunkin.compat;

#if (sys && FEATURE_DEBUG_FUNCTIONS)
@:access(polymod.Polymod)
@:access(funkin.play.GameOverSubState)
class LegacyCharacterChecks
{
  /** Check indexed Sparrow animation fallback without relying on an installed mod. */
  public static function inspectIndexedAnimations():Void
  {
    var xml = '<TextureAtlas><SubTexture name="walk 10000" x="0" y="0" width="1" height="1"/>'
      + '<SubTexture name="walk 10001" x="1" y="0" width="1" height="1"/></TextureAtlas>';
    var bitmap = new openfl.display.BitmapData(2, 1, true, 0xFFFFFFFF);
    var frames = flixel.graphics.frames.FlxAtlasFrames.fromSparrow(bitmap, xml);
    var sprite = new flixel.FlxSprite();
    sprite.frames = frames;
    sprite.animation.addByPrefix('__origin_index_probe', 'walk');
    funkin.util.assets.FlxAnimationUtil.addAtlasAnimation(sprite, {name: 'fallback', prefix: 'walk', frameIndices: [1]});
    var fallback = sprite.animation.getByName('fallback');
    if (fallback == null || fallback.frames.length != 1 || frames.frames[fallback.frames[0]].name != 'walk 10001')
      throw 'Indexed animation did not recover the requested position.';
    if (sprite.animation.getByName('__origin_index_probe') == null || sprite.animation.getByName('__origin_index_probe_') != null)
      throw 'Indexed animation fallback overwrote or leaked a temporary animation.';
    funkin.util.assets.FlxAnimationUtil.addAtlasAnimation(sprite, {name: 'fallback', prefix: 'walk', frameIndices: [9]});
    if (sprite.animation.getByName('fallback') != fallback) throw 'Invalid replacement changed an existing animation.';
    funkin.util.assets.FlxAnimationUtil.addAtlasAnimation(sprite, {name: 'exact', prefix: 'walk 1', frameIndices: [0]});
    var exact = sprite.animation.getByName('exact');
    if (exact == null || frames.frames[exact.frames[0]].name != 'walk 10000') throw 'Exact animation index changed.';
    sprite.destroy();
    trace('[Origin legacy character check] PASS indexed animation fallback and exact matching');
  }

  /** Ensure atlas metadata survives the public animation conversion helpers. */
  public static function inspectAnimationConversions():Void
  {
    var source:funkin.data.animation.AnimationData.UnnamedAnimationData = {
      prefix: 'idle', animType: 'symbol', renderType: 'animateatlas',
      atlasSettings: {swfMode: true, applyStageMatrix: true}
    };
    var named = funkin.data.animation.AnimationData.AnimationDataUtil.toNamed(source, 'idle');
    var unnamed = funkin.data.animation.AnimationData.AnimationDataUtil.toUnnamed(named);
    if (named.name != 'idle' || named.animType != 'symbol' || named.renderType != 'animateatlas'
      || named.atlasSettings?.applyStageMatrix != true || unnamed.animType != 'symbol'
      || unnamed.renderType != 'animateatlas' || unnamed.atlasSettings?.swfMode != true)
      throw 'Animation conversion lost atlas metadata.';
    var namedArray = funkin.data.animation.AnimationData.AnimationDataUtil.toNamedArray([source, source], 'anim');
    var unnamedArray = funkin.data.animation.AnimationData.AnimationDataUtil.toUnnamedArray(namedArray);
    if (namedArray.length != 2 || namedArray[1].name != 'anim1' || unnamedArray.length != 2
      || unnamedArray[1].animType != 'symbol' || unnamedArray[1].atlasSettings?.applyStageMatrix != true)
      throw 'Animation array conversion lost atlas metadata.';
    trace('[Origin legacy character check] PASS animation atlas metadata conversions');
  }

  public static function inspectHistoricalAtlases():Void
  {
    inspectIndexedAnimations();
    inspectAnimationConversions();
    if (!LegacyAssetLayout.aliases('images/charSelect/gfChill/spritemap2.png')
      .contains('ui/character-select/characters/gf/spritemap2.png'))
      throw 'Additional moved atlas spritemap did not follow its metadata.';
    if (!LegacyAssetLayout.aliases('images/charSelect/gfChill/LIBRARY/custom.json')
      .contains('ui/character-select/characters/gf/LIBRARY/custom.json'))
      throw 'Nested moved atlas library did not follow its metadata.';
    if (LegacyAssetLayout.aliases('images/custom/unmapped/spritemap2.png')
      .contains('ui/character-select/characters/gf/spritemap2.png'))
      throw 'Unrelated atlas received a character-select alias.';
    for (patchPrefix in ['_merge/', '_append/'])
      if (!LegacyAssetLayout.aliases(patchPrefix + 'images/charSelect/gfChill/LIBRARY/custom.json')
        .contains(patchPrefix + 'ui/character-select/characters/gf/LIBRARY/custom.json'))
        throw 'Moved atlas patch did not follow its metadata: $patchPrefix';
    for (api in ['0.1.0', '0.5.0', '0.9.0'])
    {
      var data = funkin.data.character.CharacterRegistry.instance.parseEntryData('compat-atlas-${StringTools.replace(api, ".", "-")}');
      if (data == null || data.legacyAtlasPlacement != (api == '0.1.0'))
        throw 'Atlas placement did not follow the owning API $api.';
      if (data.legacyAtlasStageMatrix != (api != '0.9.0'))
        throw 'Atlas stage matrix did not follow the owning API $api.';
    }
    for (name in ['settings', 'matrix', 'sparrow'])
    {
      var data = funkin.data.character.CharacterRegistry.instance.parseEntryData('compat-atlas-$name');
      if (data == null || data.legacyAtlasPlacement || data.legacyAtlasStageMatrix) throw 'Atlas placement overrode explicit $name character data.';
    }
    if (funkin.data.character.CharacterRegistry.instance.parseEntryData('compat-atlas-forged') != null)
      throw 'The strict character parser accepted an authored runtime placement flag.';
    if (funkin.data.character.CharacterRegistry.instance.parseEntryDataRaw('{"version":"1.0.0","name":"forged","assetPath":"raw","legacyAtlasStageMatrix":true}') != null)
      throw 'The strict character parser accepted an authored stage-matrix policy.';
    var explicitMatrix = funkin.data.character.CharacterRegistry.instance.parseEntryDataRaw('{"version":"1.0.0","name":"matrix","assetPath":"raw","renderType":"animateatlas","applyStageMatrix":true,"animations":[{"name":"idle","prefix":"idle"}]}');
    if (explicitMatrix == null) throw 'Explicit top-level atlas matrix failed to parse.';
    var validatedMatrix = funkin.data.character.CharacterData.validateCharacterData('matrix', explicitMatrix);
    if (validatedMatrix?.atlasSettings?.applyStageMatrix != true)
      throw 'Explicit top-level atlas matrix did not reach the renderer settings.';
    if (funkin.data.character.CharacterData.DEFAULT_ATLASSETTINGS.applyStageMatrix)
      throw 'Explicit atlas matrix mutated the shared default settings.';
    var partialMatrix = funkin.data.character.CharacterRegistry.instance.parseEntryDataRaw('{"version":"1.0.0","name":"partial","assetPath":"raw","renderType":"animateatlas","applyStageMatrix":true,"atlasSettings":{"swfMode":false},"animations":[{"name":"idle","prefix":"idle"}]}');
    if (partialMatrix == null) throw 'Partial atlas settings failed to parse.';
    var validatedPartial = funkin.data.character.CharacterData.validateCharacterData('partial', partialMatrix);
    if (validatedPartial?.atlasSettings?.applyStageMatrix != true || validatedPartial?.atlasSettings?.swfMode != false)
      throw 'Partial atlas settings lost the top-level matrix or their own options.';
    var raw = funkin.data.character.CharacterRegistry.instance.parseEntryDataRaw('{"version":"1.0.0","name":"raw","assetPath":"raw"}');
    if (raw == null || raw.scale != null || raw.atlasSettings != null || raw.legacyAtlasPlacement || raw.legacyAtlasStageMatrix)
      throw 'Raw character parsing unexpectedly supplied defaults or a legacy ownership policy.';
    trace('[Origin legacy character check] PASS atlas placement ownership, API boundary, explicit settings, rejected runtime JSON flag and raw parser contract');
    var legacyAsset = funkin.data.character.CharacterRegistry.instance.parseEntryData('compat-anim-legacy-asset');
    var explicitAsset = funkin.data.character.CharacterRegistry.instance.parseEntryData('compat-anim-asset-precedence');
    if (legacyAsset == null || legacyAsset.animations == null || explicitAsset == null || explicitAsset.animations == null)
      throw 'Historical per-animation asset fixtures did not parse.';
    var oldDeath = legacyAsset.animations.filter(animation -> animation.name == 'firstDeath');
    var explicitDeath = explicitAsset.animations.filter(animation -> animation.name == 'firstDeath');
    if (oldDeath.length != 1 || oldDeath[0].atlasSettings?.uniqueInCache != true || oldDeath[0].assetPath != 'shared:characters/bf-death'
      || explicitDeath.length != 1 || explicitDeath[0].assetPath != 'explicit/new-asset')
      throw 'Historical animation asset mapping or explicit assetPath precedence failed.';
    if (funkin.data.character.CharacterRegistry.instance.parseEntryData('compat-anim-asset-invalid') != null
      || funkin.data.character.CharacterRegistry.instance.parseEntryData('compat-anim-modern-asset') != null)
      throw 'Historical animation asset adapter accepted invalid or modern data.';
    trace('[Origin legacy character check] PASS historical animation asset, explicit precedence and strict boundaries');
    var atlas = funkin.Paths.getSparrowAtlas('characters/Nene');
    var idle = false;
    if (atlas != null) for (frame in atlas.frames)
      if (StringTools.startsWith(frame.name, 'Idle0')) idle = true;
    if (!idle) throw 'The historical Nene Sparrow atlas has no expected Idle0 frames.';
    var relative = funkin.assets.Paths.formatRelative('characters/Nene', 'gameplay/characters/nene', 'png');
    if (!funkin.assets.Paths.image(relative, false).exists()) throw 'Historical Nene stage-relative lookup failed.';
    trace('[Origin legacy character check] PASS historical Nene atlas and native relative path resolve from external resources');
    for (name in ['darnell', 'pico'])
    {
      var oldPath = 'characters/${name}Blazin';
      var expected = 'gameplay/characters/$name-blazin/$name-blazin';
      var builder = funkin.assets.Paths.animateAtlas(oldPath, false);
      if (builder.id != expected || !builder.exists()) throw 'Historical $name Animate directory did not resolve all images and JSON files.';
      var relative = funkin.assets.Paths.formatRelative(oldPath, 'gameplay/characters/$name-blazin');
      if (relative != oldPath || funkin.Paths.animateAtlas(relative) != 'assets/$expected')
        throw 'Historical $name Animate directory was incorrectly treated as stage-relative.';
      var modern = funkin.assets.Paths.animateAtlas(expected, false);
      if (modern.id != expected || !modern.exists()) throw 'Modern $name Animate directory changed during historical path resolution.';
      trace('[Origin legacy character check] PASS original and modern $name Animate directory listings and relative paths');
    }
    var named = funkin.assets.Paths.animateAtlas('shared:compat-missing-atlas', false);
    if (named.library != 'shared' || named.toString() != 'assets/shared/compat-missing-atlas')
      throw 'Named Animate library did not resolve to its expected directory.';
    trace('[Origin legacy character check] PASS named Animate library path');
  }

  public static function inspectPlay(state:funkin.play.PlayState):Void
  {
    var character = state.currentStage?.getBoyfriend();
    if (character == null || character.renderType != 'multisparrow'
      || !Std.isOfType(character, funkin.play.character.MultiSparrowCharacter)) throw 'Legacy BF image check did not select MultiSparrow.';
    for (name in ['idle', 'singLEFT', 'singDOWN', 'singUP', 'singRIGHT', 'cheer', 'firstDeath', 'deathLoop', 'deathConfirm', 'fakeoutDeath'])
      if (!character.hasAnimation(name)) throw 'Legacy BF image check is missing animation $name';
    var path = polymod.Polymod.assetLibrary.file('assets/gameplay/characters/bf/bf.png');
    if (path == '') throw 'Legacy BF image check did not select a mod image.';
    trace('[Origin legacy character check] Loaded ${character.characterId} renderer=${character.renderType} frames=${character.frames?.frames.length} image=$path');
  }

  public static function inspectGameOver(state:funkin.play.GameOverSubState):Void
  {
    if (funkin.play.GameOverSubState.instance != state || state.boyfriend == null) throw 'Legacy game-over check lost its character.';
    var animation = state.boyfriend.getCurrentAnimation();
    trace('[Origin legacy game-over check] fakeout=${state.isFakeout} renderer=${state.boyfriend.renderType} animation=$animation locked=${state.mustNotExit} music=${state.gameOverMusic?.playing}');
    if (state.mustNotExit || !(state.gameOverMusic?.playing ?? false) || !StringTools.startsWith(animation, 'deathLoop'))
      throw 'Legacy game-over intro did not reach its unlocked music loop.';
    trace('[Origin legacy game-over check] PASSED');
  }
}
#end
