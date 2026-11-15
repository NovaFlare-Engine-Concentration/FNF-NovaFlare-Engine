package codename.funkin.tests;

#if (sys && FEATURE_DEBUG_FUNCTIONS)
import flixel.FlxG;
import flixel.FlxState;
import flixel.FlxSubState;
import flixel.FlxCamera;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.sound.FlxSound;
import flixel.tweens.FlxTween;
import flixel.util.FlxTimer;
import lime.media.AudioBuffer;
import lime.utils.UInt8Array;
import openfl.media.Sound;
import codename.funkin.game.PlayState;
import codename.funkin.menus.PauseSubState;
import codename.funkin.backend.scripting.Script;
import codename.funkin.backend.scripting.ScriptPack;
import codename.funkin.backend.scripting.EventManager;
import codename.funkin.backend.scripting.events.gameplay.PauseGameEvent;
import codename.funkin.backend.system.Flags;
import codename.funkin.backend.utils.FunkinParentDisabler;
import codename.funkin.backend.utils.FunkinParentDisabler.ParentDisableable;

/** Native event/resource contracts. Does not load a song or drive menu input. */
@:access(flixel.FlxCamera)
@:access(flixel.util.FlxTimerManager)
@:access(codename.funkin.menus.PauseSubState)
class PauseGameChecks extends FlxState {
	static function require(value:Bool, message:String):Void {
		if (!value) throw 'CNE pause check failed: $message';
		trace('[CNE pause check] PASS $message');
	}

	static function silentSound():FlxSound {
		var buffer = new AudioBuffer();
		buffer.bitsPerSample = 16;
		buffer.channels = 1;
		buffer.sampleRate = 22050;
		buffer.data = new UInt8Array(22050 * 2);
		var sound = new FlxSound().loadEmbedded(Sound.fromAudioBuffer(buffer), true);
		sound.volume = 0;
		FlxG.sound.list.add(sound);
		sound.play();
		return sound;
	}

	static function eventChecks():Void {
		var previousEvent = EventManager.eventCache.get(PauseGameEvent);
		var previousCharting = PlayState.chartingMode;
		var previousChance = Flags.GITAROO_CHANCE;
		var previousNextState = @:privateAccess FlxG.game._nextState;
		EventManager.eventCache.remove(PauseGameEvent);
		var play = new PauseProbePlayState();
		var pack = new ScriptPack('__cne_pause_check');
		pack.setParent(play);
		play.scripts = pack;
		var presenceCalls = 0;
		play.updateDiscordPresence = function() presenceCalls++;
		var keep = new FlxTimer();
		var script = Script.fromString('
import funkin.backend.scripting.events.gameplay.PauseGameEvent;
var mode = 0;
var seen = 0;
var typed = 0;
var lastEvent = null;
var keep = null;
function onGamePause(event:PauseGameEvent) {
  seen++;
  if (Std.isOfType(event, PauseGameEvent)) typed++;
  lastEvent = event;
  if (mode == 1) event.preventDefault();
  if (mode == 2) { event.allowGitaroo = false; event.excludeList = [keep]; }
  if (mode == 3) event.allowGitaroo = true;
}
', '__cne_pause_check.hx');
		pack.add(script);
		pack.load();
		script.set('keep', keep);
		PlayState.chartingMode = false;
		Flags.GITAROO_CHANCE = 100;
		play.allowGitaroo = true;
		play.persistentUpdate = true;
		play.persistentDraw = false;
		script.set('mode', 1);
		play.pauseGame();
		require(!play.paused && play.persistentUpdate && !play.persistentDraw && play.opened == null && presenceCalls == 0,
			'cancelled HScript event leaves pause state and presence untouched');
		script.set('mode', 2);
		play.pauseGame();
		var opened = Std.downcast(play.opened, PauseSubState);
		require(opened != null && play.paused && !play.persistentUpdate && play.persistentDraw && presenceCalls == 1,
			'script can suppress Gitaroo even at 100 percent configured chance');
		require(@:privateAccess opened.parentDisablerExcludeList.length == 1 && opened.parentDisablerExcludeList[0] == (cast keep:ParentDisableable),
			'actual pause event exclusions reach the PauseSubState constructor');
		require(play.allowGitaroo, 'event override leaves configured Gitaroo permission intact');
		script.set('mode', 0);
		PlayState.chartingMode = true;
		play.opened = null;
		play.pauseGame();
		opened = Std.downcast(play.opened, PauseSubState);
		var event = EventManager.get(PauseGameEvent);
		require(!event.cancelled && event.allowGitaroo && event.excludeList.length == 0 && script.get('lastEvent') == event,
			'cached pause event resets cancellation, exclusions and permission');
		require(opened != null && @:privateAccess opened.parentDisablerExcludeList.length == 0,
			'charting mode keeps the ordinary pause path with Gitaroo enabled');
		PlayState.chartingMode = false;
		play.allowGitaroo = false;
		play.opened = null;
		script.set('mode', 3);
		play.pauseGame();
		require(play.opened == null && @:privateAccess FlxG.game._nextState != previousNextState,
			'script can enable the Gitaroo state request over configured permission');
		@:privateAccess FlxG.game._nextState = previousNextState;
		require(script.get('seen') == 4 && script.get('typed') == 4 && presenceCalls == 3,
			'upstream typed import receives exactly one event per pause request');
		pack.destroy();
		keep.destroy();
		PlayState.chartingMode = previousCharting;
		Flags.GITAROO_CHANCE = previousChance;
		if (previousEvent == null) EventManager.eventCache.remove(PauseGameEvent);
		else EventManager.eventCache.set(PauseGameEvent, previousEvent);
	}

	static function resourceChecks():Void {
		// Isolate manager lists so boot-time resources cannot be changed by this check.
		var oldTweens = @:privateAccess FlxTween.globalManager._tweens;
		var oldTimers = @:privateAccess FlxTimer.globalManager._timers;
		var oldCameras = FlxG.cameras.list;
		var oldSounds = FlxG.sound.list;
		@:privateAccess FlxTween.globalManager._tweens = [];
		@:privateAccess FlxTimer.globalManager._timers = [];
		var normalCamera = new FlxCamera();
		var keepCamera = new FlxCamera();
		var pausedCamera = new FlxCamera();
		pausedCamera.paused = true;
		@:privateAccess FlxG.cameras.list = [normalCamera, keepCamera, pausedCamera];
		@:privateAccess FlxG.sound.list = new FlxTypedGroup<FlxSound>();
		var normalSound = silentSound();
		var keepSound = silentSound();
		var persistSound = silentSound();
		persistSound.persist = true;
		var pausedSound = silentSound();
		pausedSound.pause();
		require(normalSound.playing && keepSound.playing && persistSound.playing && !pausedSound.playing,
			'real silent PCM sounds start and a pre-paused sound remains paused');
		var normal = {x: 0.0};
		var kept = {x: 0.0};
		var normalTween = FlxTween.tween(normal, {x: 1.0}, 1);
		var keepTween = FlxTween.tween(kept, {x: 1.0}, 1);
		var normalTimer = new FlxTimer().start(1);
		var keepTimer = new FlxTimer().start(1);
		var unmanaged = new FlxTimer();
		var disabler = new FunkinParentDisabler(false, true, [keepTween, keepTimer, keepCamera, keepSound, unmanaged]);
		require(@:privateAccess !FlxTimer.globalManager._timers.contains(unmanaged), 'exclusions never register an unmanaged timer');
		FlxTween.globalManager.update(0.2);
		FlxTimer.globalManager.update(0.2);
		require(normal.x == 0 && kept.x > 0 && normalTimer.elapsedTime == 0 && keepTimer.elapsedTime > 0,
			'excluded tween and timer advance while ordinary resources are suspended');
		require(normalCamera.paused && !keepCamera.paused && pausedCamera.paused && !normalSound.playing && keepSound.playing && persistSound.playing,
			'camera and real sound exclusions preserve activity and persistent audio');
		disabler.destroy();
		FlxTween.globalManager.update(0.2);
		FlxTimer.globalManager.update(0.2);
		require(normal.x > 0 && normalTimer.elapsedTime > 0 && !normalCamera.paused && !keepCamera.paused && pausedCamera.paused,
			'destroy restores ordinary managers and only cameras paused by the helper');
		require(normalSound.playing && keepSound.playing && persistSound.playing && !pausedSound.playing,
			'destroy resumes suspended sound without resuming previously paused sound');
		FlxTween.globalManager.clear();
		FlxTimer.globalManager.clear();
		var original = new FlxTimer().start(10);
		var excluded = new FlxTimer().start(10);
		var ending = new FlxTimer().start(0.1);
		disabler = new FunkinParentDisabler(true, true, [excluded, ending]);
		var duringPause = new FlxTimer().start(10);
		FlxTimer.globalManager.update(0.2);
		disabler.destroy();
		require(@:privateAccess FlxTimer.globalManager._timers.contains(original) && FlxTimer.globalManager._timers.contains(excluded)
			&& !FlxTimer.globalManager._timers.contains(ending) && !FlxTimer.globalManager._timers.contains(duringPause),
			'replace mode retains live exclusions without resurrecting completed resources');
		duringPause.destroy();
		FlxTimer.globalManager.clear();
		var removed = new FlxTimer().start(10);
		var retained = new FlxTimer().start(10);
		disabler = new FunkinParentDisabler(true, false, [retained]);
		disabler.destroy();
		require(!removed.active && @:privateAccess FlxTimer.globalManager._timers.contains(retained),
			'legacy no-restore transition flags cancel suspended resources and retain exclusions');
		FlxTimer.globalManager.clear();
		unmanaged.destroy();
		for (sound in FlxG.sound.list) sound.destroy();
		FlxG.sound.list.destroy();
		for (camera in FlxG.cameras.list) camera.destroy();
		@:privateAccess FlxTween.globalManager._tweens = oldTweens;
		@:privateAccess FlxTimer.globalManager._timers = oldTimers;
		@:privateAccess FlxG.cameras.list = oldCameras;
		@:privateAccess FlxG.sound.list = oldSounds;
	}

	override public function create():Void {
		super.create();
		try {
			eventChecks();
			resourceChecks();
		}
		catch (error:Dynamic) {
			trace('[CNE pause check] FAIL $error');
			Sys.stdout().flush();
			Sys.exit(1);
		}
		trace('[CNE pause check] ALL CHECKS PASSED');
		Sys.stdout().flush();
		Sys.exit(0);
	}
}

private class PauseProbePlayState extends PlayState {
	public var opened:FlxSubState;
	public function new() super(false);
	override public function openSubState(substate:FlxSubState):Void opened = substate;
}
#end
