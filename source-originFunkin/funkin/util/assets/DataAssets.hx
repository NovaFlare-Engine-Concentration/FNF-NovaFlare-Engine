package funkin.util.assets;

/** Historical data-file enumeration entry point. */
class DataAssets
{
  public static function listDataFilesInPath(path:String, suffix:String = '.json'):Array<String>
  {
    return funkin.assets.Assets.listDataFilesInPath('data/$path', suffix);
  }
}
