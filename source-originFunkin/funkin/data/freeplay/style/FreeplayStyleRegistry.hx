package funkin.data.freeplay.style;

import funkin.ui.freeplay.FreeplayStyle;
import funkin.data.freeplay.style.FreeplayStyleData;
import funkin.util.tools.ISingleton;
import funkin.data.DefaultRegistryImpl;

@:nullSafety
class FreeplayStyleRegistry extends BaseRegistry<FreeplayStyle, FreeplayStyleData, FreeplayStyleEntryParams> implements ISingleton implements DefaultRegistryImpl
{
  /**
   * The current version string for the style data format.
   * Handle breaking changes by incrementing this value
   * and adding migration to the `migrateStyleData()` function.
   */
  public static final FREEPLAYSTYLE_DATA_VERSION:thx.semver.Version = '1.0.0';

  public static final FREEPLAYSTYLE_DATA_VERSION_RULE:thx.semver.VersionRule = '1.0.x';

  public function new()
  {
    super({
      registryId: 'FREEPLAYSTYLE',
      dataFilePath: 'ui/freeplay/styles/',
      nestedEntries: true,
      versionRule: FREEPLAYSTYLE_DATA_VERSION_RULE
    });
  }

  override function queryDefaultAssets(type:funkin.assets.Assets.AssetType, id:String,
    ?params:FreeplayStyleEntryParams):Array<funkin.assets.Paths.AssetPath>
  {
    @:privateAccess var entry = this.entries.get(id);
    return queryEntryAssets(type, entry);
  }

  /** Share the default resource rules with the public entry API. */
  public static function queryEntryAssets(type:funkin.assets.Assets.AssetType, entry:Null<FreeplayStyle>):Array<funkin.assets.Paths.AssetPath>
  {
    if (entry == null) return [];
    return switch (type)
    {
      case IMAGE: [funkin.assets.Paths.image(entry.getBgAssetKey()), funkin.assets.Paths.image(entry.getNumbersAssetKey()),
        funkin.assets.Paths.image(entry.getSelectorAssetKey())];
      case XML: [funkin.assets.Paths.xml(entry.getNumbersAssetKey()), funkin.assets.Paths.xml(entry.getSelectorAssetKey())];
      default: [];
    }
  }
}

typedef FreeplayStyleEntryParams =
{
}
