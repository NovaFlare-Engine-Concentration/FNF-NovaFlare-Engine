package funkin.play.song;

import funkin.data.song.SongData.SongChartData;
import funkin.data.song.SongData.SongMetadata;
import funkin.data.song.SongRegistry;
import funkin.util.FileUtil.FileUtilSandboxed;
import funkin.util.VersionUtil;

/** Historical import entry points, using native data parsers and the script filesystem boundary. */
class SongSerializer
{
  public static function importSongChartDataSync(path:String):Null<SongChartData>
  {
    var bytes = FileUtilSandboxed.readBytesFromPath(path);
    return bytes == null ? null : parseChart(bytes.toString());
  }

  public static function importSongMetadataSync(path:String):Null<SongMetadata>
  {
    var bytes = FileUtilSandboxed.readBytesFromPath(path);
    return bytes == null ? null : parseMetadata(bytes.toString());
  }

  public static function importSongChartDataAsync(callback:SongChartData->Void):Void
  {
    FileUtilSandboxed.browseFileReference(file ->
    {
      if (file.data == null) return;
      var chart = parseChart(file.data.toString());
      if (chart != null) callback(chart);
    });
  }

  public static function importSongMetadataAsync(callback:SongMetadata->Void):Void
  {
    FileUtilSandboxed.browseFileReference(file ->
    {
      if (file.data == null) return;
      var metadata = parseMetadata(file.data.toString());
      if (metadata != null) callback(metadata);
    });
  }

  static function parseMetadata(contents:Null<String>):Null<SongMetadata>
  {
    if (contents == null) return null;
    try
    {
      var version = VersionUtil.getVersionFromJSON(contents);
      if (version == null) return null;
      return SongRegistry.instance.parseEntryMetadataRawWithMigration(contents, 'SongSerializer metadata', version);
    }
    catch (error:Dynamic)
    {
      trace('[SongSerializer] Could not import metadata: $error');
      return null;
    }
  }

  static function parseChart(contents:Null<String>):Null<SongChartData>
  {
    if (contents == null) return null;
    try
    {
      var version = VersionUtil.getVersionFromJSON(contents);
      if (version == null) return null;
      return SongRegistry.instance.parseEntryChartDataRawWithMigration(contents, 'SongSerializer chart', version);
    }
    catch (error:Dynamic)
    {
      trace('[SongSerializer] Could not import chart: $error');
      return null;
    }
  }
}
