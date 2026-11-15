package funkin.data.dialogue;

import funkin.play.cutscene.dialogue.Conversation;
import funkin.util.tools.ISingleton;
import funkin.data.DefaultRegistryImpl;

@:nullSafety
class ConversationRegistry extends BaseRegistry<Conversation, ConversationData, ConversationEntryParams> implements ISingleton implements DefaultRegistryImpl
{
  /**
   * The current version string for the dialogue box data format.
   * Handle breaking changes by incrementing this value
   * and adding migration to the `migrateConversationData()` function.
   */
  public static final CONVERSATION_DATA_VERSION:thx.semver.Version = '1.1.0';

  public static final CONVERSATION_DATA_VERSION_RULE:thx.semver.VersionRule = '>=1.0.0 <1.2.0';

  public function new()
  {
    super({
      registryId: 'CONVERSATION',
      dataFilePath: 'gameplay/dialogue/conversations/',
      nestedEntries: true,
      versionRule: CONVERSATION_DATA_VERSION_RULE
    });
  }

  @:nullSafety(Off)
  override function queryDefaultAssets(type:funkin.assets.Assets.AssetType, id:String,
    ?params:ConversationEntryParams):Array<funkin.assets.Paths.AssetPath>
  {
    @:privateAccess var entry = this.entries.get(id);
    return queryDataAssets(type, entry?._data);
  }

  /** Shared by the native static API and the registry's cached-entry fallback. */
  @:nullSafety(Off)
  public static function queryDataAssets(type:funkin.assets.Assets.AssetType, data:Null<ConversationData>):Array<funkin.assets.Paths.AssetPath>
  {
    if (data == null) return [];
    var result:Array<funkin.assets.Paths.AssetPath> = [];
    var seen:Map<String, Bool> = [];
    function add(paths:Array<funkin.assets.Paths.AssetPath>):Void
    {
      for (path in paths)
      {
        if (path == null || seen.exists(path.toString())) continue;
        seen.set(path.toString(), true);
        result.push(path);
      }
    }
    for (line in data.dialogue)
    {
      add(SpeakerRegistry.instance.queryAssets(type, line.speaker));
      add(DialogueBoxRegistry.instance.queryAssets(type, line.box));
      if (type == SOUND)
      {
        var sounds = line.sounds ?? ['gameplay/dialogue/boxes/roses/click'];
        for (sound in sounds)
          if (sound != null && sound != '') add([funkin.assets.Paths.sound(sound)]);
      }
    }
    var music = data.music?.asset;
    if (music != null && music != '') switch (type)
    {
      case SOUND: add([funkin.assets.Paths.music(music).audio()]);
      case JSON: add([funkin.assets.Paths.music(music).metadata()]);
      default:
    }
    return result;
  }
}

typedef ConversationEntryParams =
{
  var placeholder:String;
}
