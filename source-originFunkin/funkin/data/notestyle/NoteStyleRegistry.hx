package funkin.data.notestyle;

import funkin.play.notes.notestyle.NoteStyle;
import funkin.data.notestyle.NoteStyleData;
import funkin.util.tools.ISingleton;
import funkin.data.DefaultRegistryImpl;

@:nullSafety
class NoteStyleRegistry extends BaseRegistry<NoteStyle, NoteStyleData, NoteStyleEntryParams> implements ISingleton implements DefaultRegistryImpl
{
  /**
   * The current version string for the note style data format.
   * Handle breaking changes by incrementing this value
   * and adding migration to the `migrateNoteStyleData()` function.
   */
  public static final NOTE_STYLE_DATA_VERSION:thx.semver.Version = '1.1.0';

  public static final NOTE_STYLE_DATA_VERSION_RULE:thx.semver.VersionRule = '>=1.0.0 <1.2.0';

  public function new()
  {
    super({
      registryId: 'NOTESTYLE',
      dataFilePath: 'gameplay/notestyles/',
      nestedEntries: true,
      versionRule: NOTE_STYLE_DATA_VERSION_RULE
    });
  }

  public function fetchDefault():NoteStyle
  {
    var notestyle:Null<NoteStyle> = fetchEntry(Constants.DEFAULT_NOTE_STYLE);
    if (notestyle == null) throw 'Default notestyle was null! This should not happen!';
    return notestyle;
  }

  public function parseEntryData(id:String):Null<NoteStyleData>
  {
    return switch (loadEntryFile(id))
    {
      case {contents:contents, fileName:fileName}:
        parseEntryDataRaw(funkin.util.SerializerUtil.sanitizeJSON(contents), fileName);
      default: null;
    };
  }

  public function parseEntryDataRaw(contents:String, ?fileName:String):Null<NoteStyleData>
  {
    var parser = new json2object.JsonParser<NoteStyleData>();
    var legacyEffects = originfunkin.compat.LegacyRuntime.usesHardcodedNoteEffects('hscriptClass($fileName)');
    parser.fromJson(originfunkin.compat.LegacyNoteStyleData.migrate(contents, legacyEffects), fileName);
    if (parser.errors.length > 0)
    {
      printErrors(parser.errors, fileName);
      return null;
    }
    var data = parser.value;
    // Some ports keep an old minimum API while using newer directional splash data.
    // Honor their animated receptors when the newer data is actually present.
    var hasModernSplash = originfunkin.compat.LegacyNoteStyleData.hasModernSplash(contents);
    data.legacyStaticReceptor = originfunkin.compat.LegacyRuntime.freezesStaticReceptor('hscriptClass($fileName)')
      && !hasModernSplash;
    data.legacyNoteSizing = originfunkin.compat.LegacyRuntime.noteSizingForOrigin('hscriptClass($fileName)')
      ?? (data.version == '1.0.0' ? 1 : 0);
    // API 0.5.0 is a minimum and is also used by 0.5.1+ ports. Origin 0.5.0
    // accepts the whole 1.1.x schema, so patch 1.1.1 does not identify the
    // source engine. This is an ambiguous compatibility default, not proof of
    // the author's intended arrow size; later splash definitions likewise only
    // suggest a newer target.
    if (data.legacyNoteSizing == 2
      && (funkin.util.VersionUtil.validateVersionStr(data.version, '>=1.1.1 <1.2.0')
        || hasModernSplash))
      data.legacyNoteSizing = 0;
    return data;
  }
}

typedef NoteStyleEntryParams =
{
}
