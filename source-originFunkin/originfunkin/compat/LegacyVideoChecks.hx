package originfunkin.compat;

#if (sys && hxvlc && FEATURE_DEBUG_FUNCTIONS)
import flixel.FlxState;
import funkin.graphics.video.FunkinVideoSprite;
import polymod.Polymod;
using Lambda;

/** Decode real external media through both folder and ZIP asset IDs. */
class LegacyVideoChecks extends FlxState
{
  var player:FunkinVideoSprite;
  var complete:Bool = false;

  override public function create():Void
  {
    super.create();
    var argument = Sys.args().find(value -> StringTools.startsWith(value, '--origin-fixtures='));
    if (argument == null) throw 'Provide --origin-fixtures=<fixture directory> for video checks.';
    var root = argument.substr('--origin-fixtures='.length);
    Polymod.init({modRoot:root, modIds:['api-0.1.0', 'zip-legacy'], framework:OPENFL,
      customFilesystem:new LegacyModFileSystem({modRoot:root, autoScan:true}),
      apiVersionRule:funkin.modding.PolymodHandler.API_VERSION_RULE,
      frameworkParams:{assetLibraryPaths:['default' => '']}, useScriptedClasses:false});
    haxe.Timer.delay(() ->
    {
      if (!complete)
      {
        trace('[Origin video check] FAIL decoder timed out');
        Sys.exit(1);
      }
    }, 15000);
    decode('assets/videos/real-sample.mp4', false, () ->
      decode('assets/videos/real-archive.mp4', true, () ->
      {
        complete = true;
        trace('[Origin video check] ALL VIDEO CHECKS PASSED');
        Sys.exit(0);
      }));
  }

  function decode(id:String, archive:Bool, next:Void->Void):Void
  {
    var location:Dynamic = LegacyVideoLocation.resolve(id);
    if (archive != Std.isOfType(location, haxe.io.Bytes)) throw 'Video location has the wrong native representation: $id';
    player = new FunkinVideoSprite();
    add(player);
    var current = player;
    var frames = 0;
    var finished = false;
    current.bitmap.onDisplay.add(() ->
    {
      if (finished || ++frames < 3) return;
      finished = true;
      if (current.bitmap.bitmapData == null || current.bitmap.bitmapData.width <= 0 || current.bitmap.bitmapData.height <= 0)
        throw 'Decoded video has no frame: $id';
      trace('[Origin video check] PASS decoded $id frames=$frames width=${current.bitmap.bitmapData.width} height=${current.bitmap.bitmapData.height}');
      // Dispose after the display callback, so the native decoder is out of dispatch.
      haxe.Timer.delay(() ->
      {
        remove(current);
        current.destroy();
        player = null;
        next();
      }, 1);
    });
    if (!current.load(id)) throw 'VLC rejected video asset $id';
    current.bitmap.volume = 0;
    if (!current.play()) throw 'VLC could not start video asset $id';
  }
}
#end
