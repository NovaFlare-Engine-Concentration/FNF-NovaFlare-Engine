package originfunkin.compat;

#if (sys && FEATURE_DEBUG_FUNCTIONS)
/** Run actual native file pickers explicitly; canceling leaves the test pending. */
class SongSerializerImportChecks extends flixel.FlxState
{
  var label:flixel.text.FlxText;
  var metadataCalls = 0;
  var chartCalls = 0;
  var metadata:funkin.data.song.SongData.SongMetadata;

  override public function create():Void
  {
    super.create();
    bgColor = 0xFF202632;
    label = new flixel.text.FlxText(40, 40, 1200, 'Select an official Bopeebo metadata JSON, then its chart JSON.', 24);
    add(label);
    haxe.Timer.delay(() -> funkin.play.song.SongSerializer.importSongMetadataAsync(onMetadata), 250);
  }

  function onMetadata(value:funkin.data.song.SongData.SongMetadata):Void
  {
    metadataCalls++;
    if (metadataCalls != 1 || !Std.isOfType(value, funkin.data.song.SongData.SongMetadata) || value.clone().songName != 'Bopeebo')
      throw 'Historical asynchronous metadata import did not yield one native Bopeebo object.';
    metadata = value;
    trace('[Origin SongSerializer async check] Metadata callback once: ${value.songName}');
    label.text = 'Metadata loaded: ${value.songName}. Select its chart JSON.';
    haxe.Timer.delay(() -> funkin.play.song.SongSerializer.importSongChartDataAsync(onChart), 250);
  }

  function onChart(value:funkin.data.song.SongData.SongChartData):Void
  {
    chartCalls++;
    if (chartCalls != 1 || !Std.isOfType(value, funkin.data.song.SongData.SongChartData) || value.notes.get('hard').length == 0)
      throw 'Historical asynchronous chart import did not yield one usable native chart.';
    var charts:Map<String, funkin.data.song.SongData.SongChartData> = ['default' => value];
    var song = funkin.play.song.Song.buildRaw('compat-serializer-async', [metadata], 'default', charts, false, false);
    label.text = 'PASSED: ${song.songName}, ${song.getDifficulty("hard").notes.length} hard notes. Both callbacks fired once.';
    song.destroy();
    trace('[Origin SongSerializer async check] ALL ASYNC IMPORT CHECKS PASSED');
  }
}
#end
