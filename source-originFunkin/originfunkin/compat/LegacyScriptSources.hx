package originfunkin.compat;

using Lambda;

@:access(polymod.Polymod)
class LegacyScriptSources
{
  public static function unique(paths:Array<String>):Array<String>
  {
    var seen:Map<String, String> = [];
    return paths.filter(path ->
    {
      if (!polymod.PolymodConfig.scriptClassExt.exists(ext -> StringTools.endsWith(path, ext))) return true;
      var physical = polymod.Polymod.assetLibrary.getPath(path);
      // A moved script's canonical ID can be replaced by a later/current-format
      // file. Do not register the shadowed old path as another class definition.
      for (alias in LegacyAssetLayout.aliases(path))
        if ((StringTools.startsWith(alias, 'gameplay/') || StringTools.startsWith(alias, 'ui/')) && StringTools.endsWith(alias, '.hxc'))
        {
          var selected = polymod.Polymod.assetLibrary.getPath('assets/$alias');
          if (selected != null && selected != '' && normalize(selected) != normalize(physical)) return false;
        }
      var key = haxe.io.Path.normalize(physical == null || physical == '' ? path : physical);
      #if windows
      key = key.toLowerCase();
      #end
      if (seen.exists(key))
      {
        trace('[Origin compatibility] Script alias "$path" shares source with "${seen.get(key)}"; loading once.');
        return false;
      }
      seen.set(key, path);
      return true;
    });
  }

  static function normalize(path:String):String
  {
    var result = haxe.io.Path.normalize(path ?? '');
    #if windows
    result = result.toLowerCase();
    #end
    return result;
  }
}
