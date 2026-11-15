package funkin.data.stage;

import funkin.play.stage.Stage;
import funkin.util.tools.ISingleton;
import funkin.data.DefaultRegistryImpl;

@:nullSafety
class StageRegistry extends BaseRegistry<Stage, StageData, StageEntryParams> implements ISingleton implements DefaultRegistryImpl
{
  /**
   * The current version string for the stage data format.
   * Handle breaking changes by incrementing this value
   * and adding migration to the `migrateStageData()` function.
   */
  public static final STAGE_DATA_VERSION:thx.semver.Version = '1.0.2';

  public static final STAGE_DATA_VERSION_RULE:thx.semver.VersionRule = '>=1.0.0 <1.1.0';

  public function new()
  {
    super({
      registryId: 'STAGE',
      dataFilePath: 'gameplay/stages/',
      nestedEntries: true,
      versionRule: STAGE_DATA_VERSION_RULE
    });
  }

  @:nullSafety(Off)
  override function queryDefaultAssets(type:funkin.assets.Assets.AssetType, id:String,
    ?params:StageEntryParams):Array<funkin.assets.Paths.AssetPath>
  {
    if (type != IMAGE && type != XML && type != JSON && type != TEXT) return [];
    @:privateAccess var entry = this.entries.get(id);
    if (entry == null || entry._data == null || entry._data.props == null) return [];
    var result:Array<funkin.assets.Paths.AssetPath> = [];
    var seen:Map<String, Bool> = [];
    function add(path:funkin.assets.Paths.AssetPath):Void
    {
      if (path == null || !path.exists() || seen.exists(path.toString())) return;
      seen.set(path.toString(), true);
      result.push(path);
    }
    for (prop in entry._data.props)
    {
      if (prop == null || prop.assetPath == null || prop.assetPath == '' || StringTools.startsWith(prop.assetPath, '#')) continue;
      var animated = prop.animations != null && prop.animations.length > 0;
      var animateAtlas = animated && prop.animType == 'animateatlas';
      var key = funkin.assets.Paths.formatRelative(prop.assetPath, 'gameplay/stages/$id', animateAtlas ? null : 'png');
      if (animateAtlas)
      {
        var atlas = funkin.assets.Paths.animateAtlas(key, false);
        if (type == IMAGE) for (path in atlas.image()) add(path);
        if (type == JSON) for (path in atlas.json()) add(path);
      }
      else if (type == IMAGE) add(funkin.assets.Paths.image(key, false));
      else if (animated && prop.animType == 'packer' && type == TEXT) add(funkin.assets.Paths.txt(key, false));
      else if (animated && prop.animType != 'packer' && type == XML) add(funkin.assets.Paths.xml(key, false));
    }
    return result;
  }

  public function listBaseGameStageIds():Array<String> return listBaseGameEntryIds();
  public function listModdedStageIds():Array<String> return listModdedEntryIds();
}

typedef StageEntryParams =
{
}
