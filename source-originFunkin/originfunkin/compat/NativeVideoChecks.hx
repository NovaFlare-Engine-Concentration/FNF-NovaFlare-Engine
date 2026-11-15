package originfunkin.compat;

#if (cpp && hxvlc && FEATURE_DEBUG_FUNCTIONS)
import flixel.FlxG;
import flixel.FlxState;
import funkin.graphics.video.FunkinVideoSprite;
import hxvlc.openfl.Video;
import lime.media.openal.AL;
using Lambda;

/** Real VLC audio/video callbacks during collections, playback and disposal. */
@:access(hxvlc.openfl.Video)
class NativeVideoChecks extends FlxState
{
  static final VIDEOS = ["rift-collab-trailer", "mobile-release", "boyfriend-everywhere"];
  var player:FunkinVideoSprite;
  var decoder:Video;
  var cycle:Int = -1;
  var frames:Int = 0;
  var sawAudio:Bool = false;
  var ended:Bool = false;
  var disposed:Bool = false;
  var elapsedCycle:Float = 0;
  var elapsedCollection:Float = 0;
  var collections:Int = 0;
  var pauseFrames:Int = -1;
  var resumed:Bool = false;
  var afterDispose:Float = 0;
  var disposedFrames:Int = 0;
  var firstCycle:Int = 0;

  override public function create():Void
  {
    super.create();
    var startArgument = Sys.args().find(value -> StringTools.startsWith(value, '--origin-video-start='));
    if (startArgument != null)
    {
      var start = Std.parseInt(startArgument.substr('--origin-video-start='.length));
      if (start == null || start < 0 || start > 8) fail('invalid video start cycle');
      firstCycle = start;
      cycle = firstCycle - 1;
    }
    openfl.Lib.application.window.onClose.add(() ->
    {
      if (cycle < 9) trace('[Origin native video check] INCOMPLETE window closed during cycle=$cycle');
    });
    FlxG.autoPause = false;
    if (FlxG.sound.music != null)
    {
      FlxG.sound.music.destroy();
      FlxG.sound.music = null;
    }
    nextVideo();
  }

  function nextVideo():Void
  {
    if (++cycle >= 9)
    {
      trace('[Origin native video check] CHECKS PASSED start=$firstCycle end=$cycle collections=$collections');
      Sys.stdout().flush();
      // Exercise the real application shutdown after all players were disposed.
      openfl.Lib.application.window.close();
      return;
    }
    frames = 0;
    sawAudio = ended = disposed = resumed = false;
    elapsedCycle = elapsedCollection = afterDispose = 0;
    pauseFrames = -1;
    player = new FunkinVideoSprite();
    decoder = player.bitmap;
    add(player);
    decoder.onDisplay.add(() -> frames++);
    decoder.onEndReached.add(() -> ended = true);
    decoder.onEncounteredError.add(message -> fail('decoder error: $message'));
    decoder.onFormatSetup.add(() ->
    {
      if (disposed) return;
      player.setGraphicSize(FlxG.width, FlxG.height);
      player.updateHitbox();
      player.screenCenter();
    });
    var path = funkin.assets.Paths.video('ui/title/attract/${VIDEOS[cycle % VIDEOS.length]}').toString();
    trace('[Origin native video check] START cycle=$cycle mode=${cycle < 3 ? "natural-end" : cycle < 6 ? "stop" : "dispose-playing"} path=$path');
    if (!player.load(path) || !player.play()) fail('could not play $path');
  }

  override public function update(elapsed:Float):Void
  {
    super.update(elapsed);
    elapsedCycle += elapsed;
    if (disposed)
    {
      afterDispose += elapsed;
      if (frames != disposedFrames) fail('display callback after disposal');
      if (decoder.mediaPlayer != null || decoder.alSource != null || decoder.alBufferPool != null)
        fail('native player or audio resources retained after disposal');
      if (afterDispose >= 0.5) nextVideo();
      return;
    }
    elapsedCollection += elapsed;
    if (elapsedCollection >= 0.2)
    {
      elapsedCollection = 0;
      // Collect while VLC threads are active, rather than only between callbacks.
      cpp.vm.Gc.run(++collections % 8 == 0);
    }
    if (decoder.alSource != null && decoder.alSampleRate > 0
      && AL.getSourcei(decoder.alSource, AL.BUFFERS_QUEUED) > 0)
      sawAudio = true;
    if (cycle == 3 && elapsedCycle >= 1 && pauseFrames < 0 && frames > 3)
    {
      player.pause();
      pauseFrames = frames;
      trace('[Origin native video check] PAUSE cycle=$cycle frames=$frames');
    }
    if (cycle == 3 && pauseFrames >= 0 && !resumed && elapsedCycle >= 1.5)
    {
      player.resume();
      resumed = true;
    }
    var shouldFinish = cycle < 3 ? ended : elapsedCycle >= 3;
    if (shouldFinish)
    {
      if (frames < 3 || !sawAudio) fail('missing decoded video/audio frames=$frames audio=$sawAudio');
      if (cycle == 3 && (!resumed || frames <= pauseFrames)) fail('playback did not resume');
      if (cycle < 6) player.stop();
      remove(player);
      player.destroy();
      player = null;
      decoder.dispose(); // The native disposal API promises repeat-call safety.
      disposed = true;
      disposedFrames = frames;
      trace('[Origin native video check] PASS cycle=$cycle frames=$frames audio=$sawAudio end=$ended collections=$collections');
    }
    else if (elapsedCycle > 180) fail('playback timed out');
  }

  function fail(message:String):Void
  {
    trace('[Origin native video check] FAIL cycle=$cycle $message');
    Sys.exit(1);
  }
}
#end
