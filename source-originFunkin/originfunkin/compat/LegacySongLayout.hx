package originfunkin.compat;

#if sys
import funkin.data.song.SongData.SongMetadata;
import funkin.data.song.SongData.SongChartData;
import funkin.data.song.SongData.SongEventData;
import funkin.data.song.SongRegistry;
import funkin.data.song.importer.FNFLegacyImporter;
import funkin.data.song.importer.FNFLegacyData;
import haxe.io.Path;
import polymod.Polymod;

typedef LegacySongDifficulty =
{
  metadata:SongMetadata,
  events:Array<SongEventData>,
  ?needsVoices:Bool,
  ?voiceList:Array<String>
}

typedef LegacySongRecord =
{
  metadata:SongMetadata,
  chart:SongChartData,
  difficulties:Map<String, LegacySongDifficulty>
}

typedef LegacySongSnapshot =
{
  metadata:Null<SongMetadata>,
  chart:Null<SongChartData>,
  difficulties:Map<String, LegacySongDifficulty>,
  ?patched:Bool
}

/** In-memory views of pre-registry charts. No generated files are written into mods. */
@:access(polymod.Polymod)
@:access(polymod.backends.PolymodAssetLibrary)
class LegacySongLayout
{
  static function assetPath(id:String, metadata:Bool):String
  {
    return 'gameplay/songs/$id/$id-${metadata ? 'metadata' : 'chart'}.json';
  }

  public static function mount(fs:LegacyModFileSystem, root:String, files:Array<String>, result:Array<String>):Void
  {
    var candidates:Map<String, Map<String, String>> = [];
    var pattern = ~/^(?:assets\/)?(?:(?:preload|shared|tutorial|week[1-8]|weekend1)\/)?data\/([^\/]+)\/([^\/]+)\.json$/;
    for (file in files)
    {
      if (!pattern.match(Path.normalize(file))) continue;
      var id = pattern.matched(1);
      var name = pattern.matched(2);
      var diff = name == id ? 'normal' : name.substr(id.length + 1);
      if (name != id && (!StringTools.startsWith(name, '$id-') || !['easy', 'normal', 'hard'].contains(diff))) continue;
      var song = candidates.get(id);
      if (song == null) candidates.set(id, song = []);
      // Prefer the shortest path when a package contains both a library and root copy.
      var previous = song.get(diff);
      var isRoot = name == id;
      var previousIsRoot = previous != null && Path.withoutExtension(Path.withoutDirectory(previous)) == id;
      if (previous == null || (isRoot && !previousIsRoot) || (isRoot == previousIsRoot && file.length < previous.length)) song.set(diff, file);
    }
    for (id => candidatesByDiff in candidates)
    {
      var record:LegacySongRecord = {metadata:null, chart:new SongChartData([], [], []), difficulties:[]};
      var grouped = false;
      for (diff in ['normal', 'easy', 'hard'])
      {
        if (grouped) break;
        var file = candidatesByDiff.get(diff);
        if (file == null) continue;
        var fullPath = Path.join([root, file]);
        try
        {
          var text = fs.getFileContent(fullPath);
          // Do not feed arbitrary data JSON to the legacy typed parser.
          var raw:Dynamic = haxe.Json.parse(text);
          if (raw.song == null || raw.song.notes == null || raw.song.bpm == null) continue;
          var data = FNFLegacyImporter.parseLegacyDataRaw(text, fullPath);
          if (data == null) continue;
          var metadata = FNFLegacyImporter.migrateMetadata(data, diff);
          var chart = FNFLegacyImporter.migrateChartData(data, diff);
          if (record.metadata == null) record.metadata = metadata;
          for (difficulty in metadata.playData.difficulties)
          {
            var diffMeta = FNFLegacyImporter.migrateMetadata(data, difficulty);
            var diffChart = FNFLegacyImporter.migrateChartData(data, difficulty);
            record.difficulties.set(difficulty, {metadata:diffMeta, events:diffChart.events,
              needsVoices:data.song.needsVoices, voiceList:data.song.voiceList ?? ['']});
            record.chart.notes.set(difficulty, chart.notes.get(difficulty) ?? []);
            record.chart.scrollSpeed.set(difficulty, diffChart.getScrollSpeed(difficulty));
          }
          grouped = switch (data.song.notes) {case Right(_): true; default: false;};
        }
        catch (error:Dynamic) trace('[Origin compatibility] Could not migrate $fullPath: $error');
      }
      if (record.metadata == null) continue;
      record.metadata.playData.difficulties = [for (diff in ['easy', 'normal', 'hard']) if (record.difficulties.exists(diff)) diff];
      record.chart.events = record.difficulties.get(record.difficulties.exists('normal') ? 'normal' : record.metadata.playData.difficulties[0]).events;
      for (metadata in [true, false])
      {
        var relative = assetPath(id, metadata);
        // Includes physical current-format aliases registered before this conversion.
        if (result.contains(relative)) continue;
        var text = metadata ? new json2object.JsonWriter<SongMetadata>({ignoreNullOptionals:true}).write(record.metadata)
          : new json2object.JsonWriter<SongChartData>({ignoreNullOptionals:true}).write(record.chart);
        fs.publishSong(Path.join([root, relative]), text, record);
        result.push(relative);
      }
      trace('[Origin compatibility] ${Path.withoutDirectory(root)}: mounted legacy song $id (${record.metadata.playData.difficulties.join(", ")}).');
    }
  }

  static function parseMetadata(text:String, file:String):Null<SongMetadata>
  {
    var version = funkin.util.VersionUtil.getVersionFromJSON(text);
    return version == null ? null : SongRegistry.instance.parseEntryMetadataRawWithMigration(text, file, version);
  }

  static function parseChart(text:String, file:String):Null<SongChartData>
  {
    var version = funkin.util.VersionUtil.getVersionFromJSON(text);
    return version == null ? null : SongRegistry.instance.parseEntryChartDataRawWithMigration(text, file, version);
  }

  static function overlayMetadata(base:Null<SongMetadata>, legacy:SongMetadata):SongMetadata
  {
    if (base == null) return legacy.clone();
    // Old charts do not contain artist/album/ratings/offset metadata; retain those fields.
    var result = base.clone();
    result.songName = legacy.songName;
    result.timeChanges = legacy.timeChanges;
    result.playData.stage = legacy.playData.stage;
    result.playData.noteStyle = legacy.playData.noteStyle;
    result.playData.characters = legacy.playData.characters;
    for (diff in legacy.playData.difficulties)
      if (!result.playData.difficulties.contains(diff)) result.playData.difficulties.push(diff);
    return result;
  }

  static function snapshot(id:String, variation:String):Null<LegacySongSnapshot>
  {
    if (variation != 'default' || Polymod.assetLibrary == null) return null;
    var library = Polymod.assetLibrary;
    if (!Std.isOfType(library.fileSystem, LegacyModFileSystem)) return null;
    var fs:LegacyModFileSystem = cast library.fileSystem;
    var metadataPath = assetPath(id, true);
    var chartPath = assetPath(id, false);
    var selectedMetadata = library.file('assets/$metadataPath');
    var selectedChart = library.file('assets/$chartPath');
    if (fs.legacySong(selectedMetadata) == null && fs.legacySong(selectedChart) == null) return null;
    var cacheKey = '$id|$selectedMetadata|$selectedChart';
    if (fs.songSnapshots.exists(cacheKey)) return fs.songSnapshots.get(cacheKey);
    var value:LegacySongSnapshot = {metadata:null, chart:null, difficulties:[]};
    var base = originfunkin.OriginFunkinMode.assetsRoot;
    if (base != null)
    {
      var path = Path.join([base, metadataPath]);
      if (sys.FileSystem.exists(path)) value.metadata = parseMetadata(sys.io.File.getContent(path), path);
      path = Path.join([base, chartPath]);
      if (sys.FileSystem.exists(path)) value.chart = parseChart(sys.io.File.getContent(path), path);
    }
    if (value.metadata != null && value.chart != null)
      for (diff in value.chart.notes.keys()) value.difficulties.set(diff, {metadata:value.metadata, events:value.chart.events});
    var chartDone = selectedChart == '';
    var metadataDone = selectedMetadata == '';
    for (root in Polymod.getLoadedModDirs())
    {
      var fullMetadata = Path.join([root, metadataPath]);
      var fullChart = Path.join([root, chartPath]);
      var physicalMetadata:Null<SongMetadata> = null;
      if (!metadataDone && fs.exists(fullMetadata))
      {
        var legacy = fs.legacySong(fullMetadata);
        if (legacy != null)
        {
          value.metadata = overlayMetadata(value.metadata, legacy.metadata);
        }
        else
        {
          physicalMetadata = parseMetadata(fs.getFileContent(fullMetadata), fullMetadata);
          if (physicalMetadata != null)
          {
            value.metadata = physicalMetadata;
            for (difficulty in value.difficulties)
            {
              difficulty.metadata = physicalMetadata;
              difficulty.needsVoices = null;
              difficulty.voiceList = null;
            }
          }
        }
        metadataDone = library.file('assets/$metadataPath', root) == selectedMetadata;
      }
      if (!chartDone && fs.exists(fullChart))
      {
        var legacy = fs.legacySong(fullChart);
        if (legacy != null)
        {
          var hasNormal = value.chart != null && value.chart.notes.exists('normal');
          if (value.chart == null) value.chart = new SongChartData([], [], []);
          if (!hasNormal || legacy.difficulties.exists('normal')) value.chart.events = legacy.chart.events;
          for (diff => difficulty in legacy.difficulties)
          {
            value.chart.notes.set(diff, legacy.chart.notes.get(diff));
            value.chart.scrollSpeed.set(diff, legacy.chart.getScrollSpeed(diff));
            // An explicit current metadata file in this package takes precedence.
            value.difficulties.set(diff, {metadata:physicalMetadata ?? overlayMetadata(value.metadata, difficulty.metadata),
              events:difficulty.events, needsVoices:physicalMetadata == null ? difficulty.needsVoices : null,
              voiceList:physicalMetadata == null ? difficulty.voiceList : null});
          }
        }
        else
        {
          value.chart = parseChart(fs.getFileContent(fullChart), fullChart);
          value.difficulties.clear();
          if (value.chart != null && value.metadata != null)
            for (diff in value.chart.notes.keys()) value.difficulties.set(diff, {metadata:value.metadata, events:value.chart.events});
        }
        chartDone = library.file('assets/$chartPath', root) == selectedChart;
      }
      if (chartDone && metadataDone) break;
    }
    fs.songSnapshots.set(cacheKey, value);
    return value;
  }

  /** Supply the complete virtual document before the backend applies normal merge/append rules. */
  public static function generatedBytes(fs:LegacyModFileSystem, path:String, original:haxe.io.Bytes):haxe.io.Bytes
  {
    var library = Polymod.assetLibrary;
    if (library == null || library.fileSystem != fs) return original;
    var id = Path.withoutDirectory(Path.directory(path));
    var metadata = StringTools.endsWith(path, '-metadata.json');
    if (library.file('assets/' + assetPath(id, metadata)) != path) return original;
    var value = snapshot(id, 'default');
    if (value == null) return original;
    var text = metadata
      ? (value.metadata == null ? null : new json2object.JsonWriter<SongMetadata>({ignoreNullOptionals:true}).write(value.metadata))
      : (value.chart == null ? null : new json2object.JsonWriter<SongChartData>({ignoreNullOptionals:true}).write(value.chart));
    return text == null ? original : haxe.io.Bytes.ofString(text);
  }

  public static function difficulty(id:String, variation:String, diff:String):Null<LegacySongDifficulty>
  {
    var value = snapshot(id, variation);
    if (value == null) return null;
    if (value.patched != true)
    {
      var library = Polymod.assetLibrary;
      for (metadata in [true, false])
      {
        var relative = assetPath(id, metadata);
        var patched = false;
        for (root in Polymod.getLoadedModDirs())
          for (prefix in [polymod.PolymodConfig.mergeFolder, polymod.PolymodConfig.appendFolder])
            if (library.fileSystem.exists(Path.join([root, prefix, relative]))) patched = true;
        if (!patched) continue;
        for (difficulty in value.difficulties)
        {
          var text:String;
          if (metadata) text = new json2object.JsonWriter<SongMetadata>({ignoreNullOptionals:true}).write(difficulty.metadata);
          else
          {
            var chart = value.chart.clone();
            chart.events = difficulty.events;
            text = new json2object.JsonWriter<SongChartData>({ignoreNullOptionals:true}).write(chart);
          }
          // Bypass the library's ID-only text cache: every difficulty has its own old timeline.
          text = polymod.util.Util.mergeAndAppendText(text, 'assets/$relative', library.modIds,
            library.getTextDirectly, library.fileSystem, library.parseRules);
          if (metadata)
          {
            var updated = parseMetadata(text, relative);
            if (updated != null) difficulty.metadata = updated;
          }
          else
          {
            var updated = parseChart(text, relative);
            if (updated != null) difficulty.events = updated.events;
          }
        }
      }
      value.patched = true;
    }
    return value.difficulties.get(diff);
  }

  public static function applyDifficulty(target:funkin.play.song.Song.SongDifficulty, populateMetadata:Bool = true):Void
  {
    var data = difficulty(target.song.id, target.variation, target.difficulty);
    if (data == null) return;
    target.events = [for (event in data.events) new SongEventData(event.time, event.eventKind,
      haxe.Json.parse(haxe.Json.stringify(event.value)), event.editorLayer)];
    if (!populateMetadata) return;
    var metadata = data.metadata.clone();
    target.songName = metadata.songName;
    target.songArtist = metadata.artist;
    target.charter = metadata.charter ?? funkin.util.Constants.DEFAULT_CHARTER;
    target.timeFormat = metadata.timeFormat;
    target.divisions = metadata.divisions;
    target.timeChanges = metadata.timeChanges;
    target.looped = metadata.looped;
    target.generatedBy = metadata.generatedBy;
    target.offsets = metadata.offsets ?? new funkin.data.song.SongData.SongOffsets();
    target.stage = metadata.playData.stage;
    target.noteStyle = metadata.playData.noteStyle;
    target.characters = metadata.playData.characters;
    target.legacyNeedsVoices = data.needsVoices;
    target.legacyVoiceList = data.voiceList;
  }

  /** A legacy combined track must not be masked by stock split vocals from a lower layer. */
  public static function preferCombinedVoice(id:String, split:Array<funkin.assets.Paths.AssetPath>, legacyChart:Bool):Bool
  {
    var library = Polymod.assetLibrary;
    if (library == null) return legacyChart;
    var relative = 'gameplay/songs/$id/Voices.${funkin.util.Constants.EXT_SOUND}';
    var selected = library.file('assets/$relative');
    var combinedIndex = -1;
    var splitIndex = -1;
    var isLegacyAlias = false;
    var roots = Polymod.getLoadedModDirs();
    for (i in 0...roots.length)
    {
      var root = roots[i];
      if (library.file('assets/$relative', root) == selected)
      {
        combinedIndex = i;
        isLegacyAlias = Path.normalize(selected) != Path.normalize(Path.join([root, relative]));
      }
      for (voice in split)
      {
        var path = library.file(voice.toString());
        if (path != '' && library.file(voice.toString(), root) == path) splitIndex = i;
      }
    }
    return (legacyChart || isLegacyAlias) && (combinedIndex > splitIndex || (legacyChart && combinedIndex == -1 && splitIndex == -1));
  }
}
#end
