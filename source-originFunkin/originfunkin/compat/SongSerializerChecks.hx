package originfunkin.compat;

#if (sys && FEATURE_DEBUG_FUNCTIONS)
@:access(funkin.util.FileUtil)
@:access(polymod.Polymod)
@:access(polymod.hscript._internal.PolymodScriptClass)
class SongSerializerChecks
{
  static function require(value:Bool, message:String):Void
  {
    if (!value) throw 'SongSerializer compatibility check failed: $message';
    trace('[Origin SongSerializer check] PASS $message');
  }

  public static function run(root:String):Void
  {
    var previousRoot = funkin.util.FileUtil._gameDirectory;
    // Exercise real sandboxed file reads against the explicit fixture workspace.
    funkin.util.FileUtil._gameDirectory = sys.FileSystem.fullPath(haxe.io.Path.join([root, '../origin-version-history']));
    try
    {
      for (api in ['0.1.0', '0.5.0', '0.8.8', '0.9.0'])
      {
        var name = 'SongSerializerProbe' + api.split('.').join('_');
        var path = 'assets/scripts/$name.hxc';
        polymod.hscript._internal.PolymodScriptClass.registerScriptClassByString(polymod.Polymod.assetLibrary.getText(path), path);
        var probe = funkin.modding.base.Object.scriptInit(name);
        require(probe != null && probe.scriptCall('asyncReferences', []) == true, 'API $api exposes both historical asynchronous imports');
        for (ref in ['v0.3.2', 'v0.5.0', 'v0.6.3', 'v0.7.0', 'v0.8.7'])
        {
          var metadata:funkin.data.song.SongData.SongMetadata = probe.scriptCall('metadata', ['$ref/asset-samples/metadata.json']);
          var chart:funkin.data.song.SongData.SongChartData = probe.scriptCall('chart', ['$ref/asset-samples/chart.json']);
          require(Std.isOfType(metadata, funkin.data.song.SongData.SongMetadata) && metadata.clone().songName == 'Bopeebo'
            && Std.isOfType(chart, funkin.data.song.SongData.SongChartData) && chart.notes.get('hard').length > 0,
            'API $api imports $ref into usable native metadata and chart objects');
          var charts:Map<String, funkin.data.song.SongData.SongChartData> = ['default' => chart];
          var song = funkin.play.song.Song.buildRaw('compat-serializer', [metadata], 'default', charts, false, false);
          require(song.songName == metadata.songName && song.getDifficulty('hard').notes.length == chart.notes.get('hard').length,
            'API $api imported $ref builds a native song with its hard notes');
          song.destroy();
        }
        require(probe.scriptCall('metadata', ['v0.3.2/asset-samples/character.json']) == null,
          'API $api unsupported imported metadata returns no partial native object');
        var handler = polymod.Polymod.onError;
        var errors:Array<polymod.Polymod.PolymodError> = [];
        polymod.Polymod.onError = error -> errors.push(error);
        var denied = false;
        try
        {
          var result = probe.scriptCall('outside', [haxe.io.Path.join([originfunkin.OriginFunkinMode.assetsRoot,
            'gameplay/songs/bopeebo/bopeebo-metadata.json'])]);
          denied = result == null;
        }
        catch (_:Dynamic) denied = true;
        polymod.Polymod.onError = handler;
        require(denied, 'API $api old import cannot read an absolute file outside the configured sandbox');
      }
    }
    catch (error:Dynamic)
    {
      funkin.util.FileUtil._gameDirectory = previousRoot;
      throw error;
    }
    funkin.util.FileUtil._gameDirectory = previousRoot;
  }
}
#end
