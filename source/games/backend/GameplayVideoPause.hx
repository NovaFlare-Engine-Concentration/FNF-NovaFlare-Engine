package games.backend;

#if (VIDEOS_ALLOWED && hxvlc)
import flixel.FlxG;
import hxvlc.flixel.FlxInternalVideo;

/** Owns video playback while the gameplay pause menu is open. */
class GameplayVideoPause
{
	private var videos:Array<PausedVideo> = [];

	public function new() {}

	public function pause():Void
	{
		// FlxVideoSprite attaches its bitmap here, including sprites created by
		// mod scripts or nested in groups outside PlayState.videoCutscene.
		for (i in 0...FlxG.game.numChildren)
		{
			var video = Std.downcast(FlxG.game.getChildAt(i), FlxInternalVideo);
			if (video == null) continue;
			var tracked = false;
			for (entry in videos)
				if (entry.video == video) { tracked = true; break; }
			if (!tracked) videos.push(new PausedVideo(video));
		}
	}

	public function resume():Void
	{
		for (entry in videos) entry.release(true);
		videos.resize(0);
	}

	public function destroy():Void
	{
		for (entry in videos) entry.release(false);
		videos.resize(0);
	}
}

// hxvlc normally resumes on focusGained BEFORE PlayState.onFocus runs.
// Temporarily detach that handler so focus cannot resume a paused song's video.
@:access(hxvlc.flixel.FlxInternalVideo)
private class PausedVideo
{
	public final video:FlxInternalVideo;
	private var shouldResume:Bool;
	private var restoreFocusHandler:Bool = false;

	public function new(video:FlxInternalVideo)
	{
		this.video = video;
		// focusLost is dispatched before PlayState opens its pause menu, so
		// hxvlc may already have paused this video and recorded resume intent.
		shouldResume = video.isPlaying || video.resumeOnFocus;
		takeFocusHandler();
		video.onOpening.add(onOpening);
		video.onPlaying.add(onPlaying);
		video.pause();
	}

	private function takeFocusHandler():Void
	{
		if (FlxG.signals.focusGained.has(video.onFocusGained))
		{
			restoreFocusHandler = true;
			FlxG.signals.focusGained.remove(video.onFocusGained);
		}
		video.resumeOnFocus = false;
	}

	private function onOpening():Void
	{
		// Opening/buffering can finish after the game was paused. hxvlc also
		// registers its focus handler again in its own onOpening callback.
		shouldResume = true;
		takeFocusHandler();
		video.pause();
	}

	private function onPlaying():Void
	{
		shouldResume = true;
		takeFocusHandler();
		video.pause();
	}

	public function release(resume:Bool):Void
	{
		video.onOpening.remove(onOpening);
		video.onPlaying.remove(onPlaying);
		video.resumeOnFocus = false;
		// Destroyed FlxVideoSprites remove and dispose their bitmap. Never
		// restore their signal listener or try to restart them on menu exit.
		if (video.parent != FlxG.game) return;
		if (restoreFocusHandler && !FlxG.signals.focusGained.has(video.onFocusGained))
			FlxG.signals.focusGained.add(video.onFocusGained);
		if (resume && shouldResume) video.resume();
	}
}
#end
