import flixel.FlxG;
import flixel.FlxState;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.sound.FlxSound;
import games.PlayState;
import games.backend.GameplayVideoPause;
import games.backend.Replay;
import games.backend.TimingSystem;
import games.objects.Character;
import games.objects.KeyboardViewer;
import games.objects.Note;
import games.objects.StrumNote;
import general.backend.ClientPrefs;
import general.backend.Conductor;
import general.objects.screen.MouseEffect;
import general.objects.screen.MouseEffect.ClickEffect;
import haxe.Timer;
import hxvlc.flixel.FlxVideoSprite;
import openfl.display.BitmapData;
import openfl.display.Sprite;
import openfl.events.MouseEvent;
import openfl.geom.Point;

/** Native regressions: actual gameplay methods, OpenFL transforms and libVLC. */
@:access(games.PlayState)
@:access(general.objects.screen.MouseEffect)
@:access(games.objects.KeyboardViewer)
class GameplayRegressionChecks extends FlxState
{
	var phase = 0;
	var deadline:Float;
	var settleUntil:Float;
	var playing:FlxVideoSprite;
	var manual:FlxVideoSprite;
	var idle:FlxVideoSprite;
	var videos = new GameplayVideoPause();

	static function require(value:Bool, message:String):Void
	{
		if (!value) throw message;
		trace('[NF regression] PASS ' + message);
	}

	static function closeTo(a:Float, b:Float):Bool return Math.abs(a - b) < 0.001;

	function mouseChecks():Void
	{
		var bitmap = new BitmapData(64, 48, true, 0xFFFFFFFF);
		var click = new ClickEffect(bitmap, bitmap);
		click.init(0, 0);
		@:privateAccess click.clickTimer -= 0.2;
		@:privateAccess click.circleTimer -= 0.2;
		click.update();
		click.init(100, 100);
		for (i in 0...click.numChildren)
		{
			var child = click.getChildAt(i);
			require(closeTo(child.x + child.width / 2, 0) && closeTo(child.y + child.height / 2, 0),
				'reused click layer is centered before its first animation frame');
		}
		var parent = new Sprite();
		parent.x = 73; parent.y = 31; parent.scaleX = 1.5; parent.scaleY = 1.25;
		FlxG.game.addChild(parent);
		var effect = new MouseEffect(bitmap, bitmap, bitmap);
		parent.addChild(effect);
		var event = new MouseEvent(MouseEvent.MOUSE_DOWN);
		event.stageX = 300; event.stageY = 200;
		effect.onMouseDown(event);
		var actual = effect.getChildAt(0).localToGlobal(new Point());
		require(closeTo(actual.x, 300) && closeTo(actual.y, 200), 'click uses local coordinates under a scaled, translated parent');
		effect.onMouseMove(event);
		require(effect.activeTrailEffects.length == 0, 'first movement establishes the trail anchor');
		event.stageX += 120;
		effect.onMouseMove(event);
		require(effect.activeTrailEffects.length == 1, 'moving past the distance threshold creates a trail');
		effect.onMouseLeave(null);
		event.stageX += 500;
		effect.onMouseMove(event);
		require(effect.activeTrailEffects.length == 1, 're-entering the window resets the trail anchor');
		effect.clearEffects();
		parent.removeChild(effect);
		FlxG.game.removeChild(parent);
		bitmap.dispose();
	}

	static function note(time:Float, sustain:Bool, parent:Note = null):Note
	{
		var note = Type.createEmptyInstance(Note);
		// Build only the data used by input/miss handling; no skin or song load.
		note.exists = true; note.alive = true; note.alpha = 1;
		note.strumTime = time; note.noteData = 0; note.mustPress = true;
		note.isSustainNote = sustain; note.parent = parent; note.tail = [];
		note.lateHitMult = 1; note.earlyHitMult = 1; note.canHold = true;
		note.missHealth = 0.05;
		return note;
	}

	function sustainChecks():Void
	{
		var play = new RegressionPlayState();
		play.guitarHeroSustains = true; play.startedCountdown = true; play.generatedMusic = true;
		play.startingSong = true;
		play.notes = new FlxTypedGroup<Note>();
		play.vocals = new FlxSound();
		play.replayExam = Type.createEmptyInstance(Replay);
		play.keyboardViewer = Type.createEmptyInstance(KeyboardViewer);
		play.keyboardViewer.destroyed = true;
		play.boyfriend = Type.createEmptyInstance(Character);
		play.dad = Type.createEmptyInstance(Character);
		play.playerStrums = new FlxTypedGroup<StrumNote>();
		play.opponentStrums = new FlxTypedGroup<StrumNote>();
		play.strumsBlocked = [false]; play.keysArray = ['note_left'];
		play.NoteMs = []; play.NoteTime = [];
		PlayState.SONG = cast {notes: []};
		ClientPrefs.data.playOpponent = false; ClientPrefs.data.ghostTapping = true;
		Conductor.safeZoneOffset = 100;
		var head = note(0, false); head.wasGoodHit = true;
		var expired = note(1000, true, head);
		var future = note(1200, true, head);
		head.tail = [expired, future];
		play.notes.add(expired); play.notes.add(future);
		play.checkSustainMisses(1099);
		require(!head.missed, 'hold remains recoverable inside its late hit window');
		play.checkSustainMisses(1101);
		require(head.missed && expired.missed && future.missed && !future.canHold && play.songMisses == 1,
			'expired hold breaks the entire chain before noteKillOffset');
		Conductor.songPosition = 1200;
		play.keyPressed(0);
		require(!future.canHold, 'pressing again cannot re-arm a broken hold');
		play.goodNoteHit(future);
		play.opponentNoteHitForOpponent(future);
		require(!future.wasGoodHit, 'both player hit entry points reject a broken hold');
		play.replayApplyInput(1200, [0], [], [true]);
		require(!future.wasGoodHit && play.songMisses == 1, 'replay cannot recover or count a second miss for the broken chain');
		ClientPrefs.data.playOpponent = true;
		expired.mustPress = false; future.mustPress = false;
		play.keyPressed(0);
		require(!future.canHold, 'opponent play mode cannot re-arm a broken hold');
		play.guitarHeroSustains = false;
		play.keyPressed(0);
		require(future.canHold, 'turning the option off preserves hold recovery');
		play.timing = new TimingSystem(); play.timing.play(); play.timing.pause(); play.paused = true;
		FlxG.autoPause = true;
		play.onFocus();
		require(!play.timing.isPlaying, 'focus gain cannot resume the song clock behind the pause menu');
		play.vocals.destroy();
		ClientPrefs.data.playOpponent = false;
	}

	function video():FlxVideoSprite
	{
		var video = new FlxVideoSprite();
		require(video.load(Sys.getEnv('NOVAFLARE_REGRESSION_VIDEO'), ['input-repeat=65545']), 'load native video fixture');
		return video;
	}

	override function create():Void
	{
		super.create();
		try
		{
			mouseChecks();
			sustainChecks();
			playing = video(); manual = video(); idle = video();
			playing.play(); manual.play();
			deadline = Timer.stamp() + 20;
		}
		catch (error:Dynamic) fail(error);
	}

	function fail(error:Dynamic):Void
	{
		trace('[NF regression] FAIL ' + error);
		trace(haxe.CallStack.toString(haxe.CallStack.exceptionStack()));
		Sys.exit(1);
	}

	override function update(elapsed:Float):Void
	{
		super.update(elapsed);
		try
		{
			var now = Timer.stamp();
			if (now > deadline) throw 'native video phase ' + phase + ' timed out';
			switch (phase)
			{
				case 0 if (playing.bitmap.isPlaying && manual.bitmap.isPlaying):
					manual.pause(); phase = 1;
				case 1 if (!manual.bitmap.isPlaying):
					FlxG.signals.focusLost.dispatch();
					videos.pause(); videos.pause();
					FlxG.signals.focusGained.dispatch();
					settleUntil = now + 0.4; phase = 2;
				case 2 if (now > settleUntil):
					require(!playing.bitmap.isPlaying && !manual.bitmap.isPlaying && !idle.bitmap.isPlaying,
						'focus gain leaves all videos paused while the gameplay menu is open');
					videos.resume(); phase = 3;
				case 3 if (playing.bitmap.isPlaying):
					require(!manual.bitmap.isPlaying && !idle.bitmap.isPlaying, 'resume preserves manually paused and unstarted videos');
					videos.pause();
					idle.play();
					settleUntil = now + 0.8; phase = 4;
				case 4 if (now > settleUntil):
					require(!idle.bitmap.isPlaying, 'video that starts or finishes loading during pause is held paused');
					playing.destroy();
					videos.resume(); phase = 5;
				case 5 if (idle.bitmap.isPlaying):
					require(playing.bitmap == null && !manual.bitmap.isPlaying, 'resume ignores destroyed videos and preserves manual pause');
					videos.pause(); videos.destroy();
					manual.destroy(); idle.destroy();
					trace('[NF regression] ALL CHECKS PASSED');
					Sys.exit(0);
				default:
			}
		}
		catch (error:Dynamic) fail(error);
	}
}

class RegressionPlayState extends PlayState
{
	// Exercise real input/miss handling without loading a HUD or stage assets.
	override public function RecalculateRating(badHit:Bool = false):Void {}
}
