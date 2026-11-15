package funkin.data.dialogue;

import funkin.play.cutscene.dialogue.DialogueBox;
import funkin.data.dialogue.DialogueBoxData;
import funkin.util.tools.ISingleton;
import funkin.data.DefaultRegistryImpl;

@:nullSafety
class DialogueBoxRegistry extends BaseRegistry<DialogueBox, DialogueBoxData, DialogueBoxEntryParams> implements ISingleton implements DefaultRegistryImpl
{
  /**
   * The current version string for the dialogue box data format.
   * Handle breaking changes by incrementing this value
   * and adding migration to the `migrateDialogueBoxData()` function.
   */
  public static final DIALOGUEBOX_DATA_VERSION:thx.semver.Version = '1.1.0';

  public static final DIALOGUEBOX_DATA_VERSION_RULE:thx.semver.VersionRule = '>=1.0.0 <1.2.0';

  public function new()
  {
    super({
      registryId: 'DIALOGUEBOX',
      dataFilePath: 'gameplay/dialogue/boxes/',
      nestedEntries: true,
      versionRule: DIALOGUEBOX_DATA_VERSION_RULE
    });
  }

  override function queryDefaultAssets(type:funkin.assets.Assets.AssetType, id:String,
    ?params:DialogueBoxEntryParams):Array<funkin.assets.Paths.AssetPath>
  {
    @:privateAccess var entry = this.entries.get(id);
    if (entry == null) return [];
    var data = entry._data;
    if (data == null || data.assetPath == null || data.assetPath == '') return [];
    return switch (type)
    {
      case IMAGE: [funkin.assets.Paths.image(data.assetPath)];
      case XML:
        var path = funkin.assets.Paths.xml(data.assetPath, false);
        path.exists() ? [path] : [];
      default: [];
    }
  }
}

typedef DialogueBoxEntryParams = Dynamic;
