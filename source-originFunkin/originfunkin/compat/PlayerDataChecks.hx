package originfunkin.compat;

#if (sys && FEATURE_DEBUG_FUNCTIONS)
using StringTools;
@:access(polymod.Polymod)
class PlayerDataChecks
{
  public static function run(root:String):Void
  {
    var registry = funkin.data.freeplay.player.PlayerRegistry.instance;
    var source = funkin.modding.compat.RegistryData.loadEntryData('compat-results', '', 'gameplay/playable-characters/', true);
    require(!Reflect.hasField(haxe.Json.parse(source.contents).results, 'perfectGold'), 'official v0.5.0 fixture remains unmodified');
    require(registry.parseEntryDataRaw(source.contents, 'expected raw v0.5.0 missing perfectGold') == null,
      'raw parser does not silently supply registry migration fields');
    var player = new funkin.ui.freeplay.charselect.PlayableCharacter('compat-results');
    var dj = player.getFreeplayDJData();
    require(dj != null && dj.getCartoonSoundClickFrame() == 80 && dj.getCartoonSoundCartoonFrame() == 85
      && dj.getCartoonLoopBlinkFrame() == 112 && dj.getCartoonLoopFrame() == 166 && dj.getCartoonChannelChangeFrame() == 60,
      'historical DJ cartoon frame markers survive player construction');
    var authored:Dynamic = haxe.Json.parse(source.contents);
    authored.results.perfectGold = authored.results.perfect;
    authored.freeplayDJ.cartoon = {soundClickFrame:1, soundCartoonFrame:2, loopBlinkFrame:3, loopFrame:4, channelChangeFrame:5};
    var authoredData = registry.parseEntryDataRaw(haxe.Json.stringify(authored), 'authored DJ markers');
    var authoredDj = authoredData?.freeplayDJ;
    require(authoredDj != null && authoredDj.getCartoonSoundClickFrame() == 1 && authoredDj.getCartoonSoundCartoonFrame() == 2
      && authoredDj.getCartoonLoopBlinkFrame() == 3 && authoredDj.getCartoonLoopFrame() == 4 && authoredDj.getCartoonChannelChangeFrame() == 5,
      'authored DJ frame overrides remain observable through the historical API');
    Reflect.deleteField(authored.freeplayDJ, 'cartoon');
    var defaults = registry.parseEntryDataRaw(haxe.Json.stringify(authored), 'optional DJ markers')?.freeplayDJ;
    require(defaults != null && defaults.getCartoonSoundClickFrame() == 80 && defaults.getCartoonSoundCartoonFrame() == 85
      && defaults.getCartoonLoopBlinkFrame() == 112 && defaults.getCartoonLoopFrame() == 166 && defaults.getCartoonChannelChangeFrame() == 60,
      'missing optional cartoon markers retain the historical defaults');
    var selectFixture:Dynamic = haxe.Json.parse(source.contents);
    selectFixture.results.perfectGold = selectFixture.results.perfect;
    selectFixture.charSelect = {assetPath: 'legacy/player'};
    var legacySelect = registry.parseEntryDataRaw(haxe.Json.stringify(selectFixture), 'legacy character-select path')?.charSelect;
    require(legacySelect != null && legacySelect.getAssetType() == 'animateatlas'
      && legacySelect.getAnimateAtlasAssetPath('bf') == 'legacy/player', 'legacy character-select asset path and renderer');
    selectFixture.charSelect.characterData = {assetPath: 'preview/player', renderType: 'sparrow'};
    var previewSelect = registry.parseEntryDataRaw(haxe.Json.stringify(selectFixture), 'preview character-select path')?.charSelect;
    require(previewSelect != null && previewSelect.getAssetType() == 'sparrow'
      && previewSelect.getAnimateAtlasAssetPath('bf') == 'preview/player', 'preview nested character-select data takes precedence');
    var perfect = player.getResultsAnimationDatas(funkin.play.scoring.Scoring.ScoringRank.PERFECT);
    var gold = player.getResultsAnimationDatas(funkin.play.scoring.Scoring.ScoringRank.PERFECT_GOLD);
    require(perfect.length == 2 && haxe.Json.stringify(perfect) == haxe.Json.stringify(gold)
      && gold[0].loopFrame == 137 && gold[1].delay == 4.41, 'actual player construction retains the historical perfect/gold layers and delay');
    require(gold[0].legacyAtlasPlacement && gold[1].legacyAtlasPlacement,
      'migrated legacy atlases retain their exported stage coordinate system');
    var explicit = registry.parseEntryDataWithMigration('compat-results-explicit', '1.0.0');
    require(explicit != null && explicit.results.perfectGold.length == 1
      && explicit.results.perfectGold[0].assetPath == 'authored/gold' && !explicit.results.perfectGold[0].legacyAtlasPlacement,
      'explicit gold animations and renderer settings keep priority');
    authored.version = '1.1.0';
    var modernRaw = registry.parseEntryDataRaw(haxe.Json.stringify(authored), 'modern raw results layout');
    require(modernRaw != null && modernRaw.results.perfectGold[0].legacyAtlasPlacement != true,
      'modern raw data retains its renderer defaults');
    authored.results.perfectGold[0].legacyAtlasPlacement = true;
    var modern = registry.parseEntryDataRaw(haxe.Json.stringify(authored), 'modern forged internal layout marker');
    require(modern == null, 'strict parser rejects authored internal layout policy');
    require(LegacyAssetLayout.aliases('shared/music/resultsNORMAL/resultsNORMAL-metadata.json')
      .contains('gameplay/playable-characters/bf/results/music/results-normal/results-normal-metadata.json'),
      'historical music metadata follows its audio alias');
    var musicMetadata = 'gameplay/playable-characters/bf/results/music/results-normal/results-normal-metadata.json';
    require(polymod.Polymod.assetLibrary.getText('assets/$musicMetadata').trim()
      == sys.io.File.getContent(haxe.io.Path.join([root, 'api-0.5.0/shared/music/resultsNORMAL/resultsNORMAL-metadata.json'])).trim(),
      'native library reads the exact historical music metadata through its modern ID');
    require(registry.parseEntryDataWithMigration('compat-results-modern', '1.1.0') == null,
      'modern schema still rejects a missing required field');
    require(registry.parseEntryDataWithMigration('compat-results-invalid', '1.0.0') == null,
      'legacy migration does not hide unrelated invalid data');
    require(funkin.modding.compat.RegistryData.loadEntryData('compat-results', '', 'gameplay/playable-characters/', true).contents == source.contents,
      'loading player data does not rewrite the mod');
    player.destroy();
  }

  static function require(condition:Bool, message:String):Void
  {
    if (!condition) throw 'Player data check failed: $message';
    trace('[Origin player data check] PASS $message');
  }
}
#end
