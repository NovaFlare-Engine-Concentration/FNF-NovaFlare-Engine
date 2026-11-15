package funkin.data.freeplay.album;

import funkin.ui.freeplay.Album;
import funkin.data.freeplay.album.AlbumData;
import funkin.util.tools.ISingleton;
import funkin.data.DefaultRegistryImpl;

@:nullSafety
class AlbumRegistry extends BaseRegistry<Album, AlbumData, AlbumEntryParams> implements ISingleton implements DefaultRegistryImpl
{
  /**
   * The current version string for the album data format.
   * Handle breaking changes by incrementing this value
   * and adding migration to the `migrateAlbumData()` function.
   */
  public static final ALBUM_DATA_VERSION:thx.semver.Version = '1.0.3';

  public static final ALBUM_DATA_VERSION_RULE:thx.semver.VersionRule = '1.0.x';

  public function new()
  {
    super({
      registryId: 'ALBUM',
      dataFilePath: 'ui/freeplay/albums/',
      nestedEntries: false,
      versionRule: ALBUM_DATA_VERSION_RULE
    });
  }

  override function queryDefaultAssets(type:funkin.assets.Assets.AssetType, id:String,
    ?params:AlbumEntryParams):Array<funkin.assets.Paths.AssetPath>
  {
    @:privateAccess var entry = this.entries.get(id);
    return queryEntryAssets(type, entry);
  }

  /** Share the default resource rules with the public entry API. */
  public static function queryEntryAssets(type:funkin.assets.Assets.AssetType, entry:Null<Album>):Array<funkin.assets.Paths.AssetPath>
  {
    if (entry == null) return [];
    return switch (type)
    {
      case IMAGE: [funkin.assets.Paths.image(entry.getAlbumArtAssetKey()), funkin.assets.Paths.image(entry.getAlbumTitleAssetKey())];
      case XML:
        var result:Array<funkin.assets.Paths.AssetPath> = [];
        for (key in [entry.getAlbumArtAssetKey(), entry.getAlbumTitleAssetKey()])
        {
          var path = funkin.assets.Paths.xml(key, false);
          if (path.exists()) result.push(path);
        }
        result;
      default: [];
    }
  }
}

typedef AlbumEntryParams =
{
}
