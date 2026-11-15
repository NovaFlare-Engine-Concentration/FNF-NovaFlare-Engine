package originfunkin.compat;

#if (cpp && hxvlc && FEATURE_DEBUG_FUNCTIONS)
import flixel.FlxG;
import flixel.FlxState;
import funkin.graphics.video.FunkinVideoSprite;
import funkin.ui.title.AttractState;

/** State teardown checks without loading or playing a video. */
@:access(funkin.ui.title.AttractState)
@:access(flixel.FlxGame)
class AttractLifecycleChecks extends FlxState
{
  static function require(value:Bool, message:String):Void
  {
    if (!value) throw 'Attract lifecycle check failed: $message';
    trace('[Attract lifecycle check] PASS $message');
  }

  override public function create():Void
  {
    super.create();
    var originalNext = FlxG.game._nextState;
    try
    {
      var state = new AttractState();
      var video = new AttractProbeVideo();
      state.vid = video;
      state.add(video);
      video.duringStop = () ->
      {
        require(state.vid == null, 'player detached before stop callback');
        state.onAttractEnd();
      };
      video.duringDestroy = state.onAttractEnd;
      state.onAttractEnd();
      var titleRequest = FlxG.game._nextState;
      require(titleRequest != null, 'completion requests Title');
      require(video.stopCount == 1 && video.destroyCount == 1 && video.bitmap == null,
        'reentrant completion stops and destroys the unloaded player once');
      require(state.members.indexOf(video) == -1, 'disposed player removed from state');
      state.onAttractEnd();
      require(FlxG.game._nextState == titleRequest, 'repeated completion preserves the first transition');
      state.destroy();
      state.onAttractEnd();
      require(video.destroyCount == 1 && FlxG.game._nextState == titleRequest,
        'late completion after teardown does not destroy or transition again');

      FlxG.game._nextState = originalNext;
      var abandoned = new AttractState();
      var abandonedVideo = new AttractProbeVideo();
      abandoned.vid = abandonedVideo;
      abandoned.add(abandonedVideo);
      abandonedVideo.duringStop = abandoned.onAttractEnd;
      abandonedVideo.duringDestroy = abandoned.onAttractEnd;
      abandoned.destroy();
      abandoned.onAttractEnd();
      require(abandoned.vid == null && abandonedVideo.stopCount == 1 && abandonedVideo.destroyCount == 1,
        'external state teardown releases the unloaded player once');
      require(FlxG.game._nextState == originalNext, 'external teardown and late callbacks do not reopen Title');

      var empty = new AttractState();
      empty.onAttractEnd();
      require(empty.ending && FlxG.game._nextState != null, 'completion without a player remains safe');
      empty.destroy();
    }
    catch (error:Dynamic)
    {
      FlxG.game._nextState = originalNext;
      throw error;
    }
    // Do not instantiate Title or enter an attract video during this check.
    FlxG.game._nextState = originalNext;
    trace('[Attract lifecycle check] ALL CHECKS PASSED (no media loaded)');
    Sys.exit(0);
  }
}

private class AttractProbeVideo extends FunkinVideoSprite
{
  public var stopCount:Int = 0;
  public var destroyCount:Int = 0;
  public var duringStop:Void->Void;
  public var duringDestroy:Void->Void;

  override public function stop():Void
  {
    stopCount++;
    if (duringStop != null) duringStop();
    super.stop();
  }

  override public function destroy():Void
  {
    destroyCount++;
    if (duringDestroy != null) duringDestroy();
    super.destroy();
  }
}
#end
