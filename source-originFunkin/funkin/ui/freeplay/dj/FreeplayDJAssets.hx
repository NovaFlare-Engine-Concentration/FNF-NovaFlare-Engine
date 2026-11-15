package funkin.ui.freeplay.dj;

import funkin.assets.Assets.AssetType;
import funkin.assets.Paths.AssetPath;
import funkin.data.freeplay.player.PlayerRegistry;

/** Resource queries share the same relative path rules as the DJ renderers. */
class FreeplayDJAssets
{
  public static function query(type:AssetType, characterId:String, renderer:String):Array<AssetPath>
  {
    var player = PlayerRegistry.instance.fetchEntry(characterId);
    var data = player?.getFreeplayDJData();
    if (data == null) return [];
    var isAnimate = renderer == 'animateatlas';
    var base = 'gameplay/playable-characters/$characterId';
    var root = funkin.assets.Paths.formatRelative(data.getAssetPath(), base, isAnimate ? null : 'png');
    if (isAnimate)
      return switch (type)
      {
        case IMAGE: funkin.assets.Paths.animateAtlas(root).image();
        case JSON: funkin.assets.Paths.animateAtlas(root).json();
        default: [];
      }
    var paths:Array<String> = [root];
    if (renderer == 'multisparrow')
      for (animation in data.getAnimationsList())
        if (animation.assetPath != null)
        {
          var path = funkin.assets.Paths.formatRelative(animation.assetPath, base, 'png');
          if (!paths.contains(path)) paths.push(path);
        }
    var result:Array<AssetPath> = [];
    for (path in paths)
      switch (type)
      {
        case IMAGE: result.push(funkin.assets.Paths.image(path));
        case XML if (renderer != 'packer'): result.push(funkin.assets.Paths.xml(path));
        case TEXT if (renderer == 'packer'): result.push(funkin.assets.Paths.txt(path));
        default:
      }
    return result;
  }
}
