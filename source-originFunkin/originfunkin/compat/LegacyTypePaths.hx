package originfunkin.compat;

import funkin.data.dialogue.ConversationData.BackdropData;
import funkin.data.dialogue.ConversationData.OutroData;
import polymod.hscript._internal.PolymodScriptClass;

/** Resolve moved enum types to the same native enum used by current dialogue data. */
class LegacyTypePaths
{
  public static function resolveEnum(path:String):Null<Enum<Dynamic>>
  {
    var result:Null<Enum<Dynamic>> = switch (path)
    {
      case 'funkin.data.dialogue.conversation.BackdropData'
        | 'funkin.data.dialogue.conversation.ConversationData.BackdropData'
        | 'funkin.data.dialogue.ConversationData.BackdropData': cast BackdropData;
      case 'funkin.data.dialogue.conversation.OutroData'
        | 'funkin.data.dialogue.conversation.ConversationData.OutroData'
        | 'funkin.data.dialogue.ConversationData.OutroData': cast OutroData;
      default: null;
    };
    if (result == null) return Type.resolveEnum(path);
    var nativeName = Type.getEnumName(result);
    for (name in [path, nativeName, 'funkin.data.dialogue.ConversationData.' + nativeName.split('.').pop()])
      if (PolymodScriptClass.importOverrides.exists(name) && PolymodScriptClass.importOverrides.get(name) == null) return null;
    return result;
  }
}
