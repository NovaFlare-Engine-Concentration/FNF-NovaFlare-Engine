package originfunkin.compat;

import funkin.data.freeplay.player.PlayerData;
import funkin.data.freeplay.player.PlayerData.PlayerResultsAnimationData;

/** Preserve the old atlas coordinate system only for migrated, unconfigured data. */
class LegacyPlayerResults
{
  public static function markLayout(data:Null<PlayerData>, source:Dynamic):Void
  {
    if (data?.results == null) return;
    var rawResults:Dynamic = Reflect.field(source, 'results');
    for (rank in ['perfectGold', 'perfect', 'excellent', 'great', 'good', 'loss'])
    {
      var animations:Array<PlayerResultsAnimationData> = Reflect.field(data.results, rank);
      var raw:Array<Dynamic> = Reflect.field(rawResults, rank);
      if (animations == null || raw == null) continue;
      for (index in 0...animations.length)
      {
        var animation = animations[index];
        if (animation == null) continue;
        var authored = raw[index];
        animation.legacyAtlasPlacement = animation.renderType == 'animateatlas' && animation.scriptClass == null
          && authored != null && !Reflect.hasField(authored, 'applyStageMatrix') && usesOldPath(animation.assetPath);
      }
    }
  }

  static function usesOldPath(path:Null<String>):Bool
  {
    if (path == null) return false;
    path = funkin.Paths.stripLibrary(path);
    if (StringTools.startsWith(path, 'assets/')) path = path.substr(7);
    return !StringTools.startsWith(path, 'gameplay/') && !StringTools.startsWith(path, 'ui/');
  }
}
