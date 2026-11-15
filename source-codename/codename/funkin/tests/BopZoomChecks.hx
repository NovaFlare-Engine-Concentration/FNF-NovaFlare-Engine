package codename.funkin.tests;

#if (sys && FEATURE_DEBUG_FUNCTIONS)
import flixel.FlxG;
import flixel.FlxState;
import codename.funkin.game.PlayState;
import codename.funkin.backend.scripting.Script;
import codename.funkin.backend.scripting.ScriptPack;
import codename.funkin.backend.scripting.EventManager;
import codename.funkin.backend.scripting.events.gameplay.BopZoomEvent;
import codename.funkin.game.HudCamera;

/** Real CNE HScript/event/camera contract; no song, assets, input or score changes. */
class BopZoomChecks extends FlxState {
	static function require(value:Bool, message:String):Void {
		if (!value) throw 'CNE bop zoom check failed: $message';
		trace('[CNE bop zoom check] PASS $message');
	}

	static function near(actual:Float, expected:Float):Bool
		return Math.abs(actual - expected) < 0.00001;

	override public function create():Void {
		super.create();
		var camera = FlxG.camera;
		var originalZoom = camera.zoom;
		var previousEvent = EventManager.eventCache.get(BopZoomEvent);
		EventManager.eventCache.remove(BopZoomEvent);
		var play = new PlayState(false);
		play.camHUD = new HudCamera();
		var pack = new ScriptPack('__cne_bop_zoom_check');
		pack.setParent(play);
		play.scripts = pack;
		var script = Script.fromString('
import funkin.backend.scripting.events.gameplay.BopZoomEvent;
var mode = 0;
var pre = 0;
var post = 0;
var typed = 0;
var lastCancelled = false;
var lastStrength = 0.0;
var lastEvent = null;
function onBopZoom(event:BopZoomEvent) {
  pre++;
  if (Std.isOfType(event, BopZoomEvent)) typed++;
  if (mode == 1) { event.zoomStrength = 0.2; event.maxZoomMultiplier = 3.0; }
  if (mode == 2) event.preventDefault();
  if (mode == 3) { event.useZoomMultiplier = false; event.zoomStrength = 0.4; }
  if (mode == 4) event.useZoomMultiplier = true;
}
function onPostBopZoom(event:BopZoomEvent) {
  post++;
  lastEvent = event;
  lastCancelled = event.cancelled;
  lastStrength = event.zoomStrength;
}
', '__cne_bop_zoom_check.hx');
		pack.add(script);
		pack.load();
		try {
			play.useCamZoomMult = true;
			play.maxCamZoomMult = 2;
			play.camZoomingStrength = 0.05;
			play.camZoomingMult = 1;
			play.doBopZoom();
			require(near(play.camZoomingMult, 1.05), 'default multiplier behavior retained');
			require(script.get('pre') == 1 && script.get('post') == 1 && script.get('typed') == 1,
				'upstream import resolves and real HScript receives typed before/after events');

			script.set('mode', 1);
			play.camZoomingMult = 2.5;
			play.doBopZoom();
			require(near(play.camZoomingMult, 2.7), 'script can override strength and multiplier limit');
			require(near(play.camZoomingStrength, 0.05) && near(play.maxCamZoomMult, 2),
				'per-event overrides leave configured camera settings intact');

			script.set('mode', 2);
			play.camZoomingMult = 1;
			play.doBopZoom();
			require(near(play.camZoomingMult, 1) && script.get('lastCancelled') == true && script.get('post') == 3,
				'cancellation prevents zoom and still delivers the post callback');

			script.set('mode', 0);
			play.doBopZoom();
			require(near(play.camZoomingMult, 1.05) && script.get('lastCancelled') == false && near(script.get('lastStrength'), 0.05),
				'cached event resets cancellation and edited fields before reuse');
			require(script.get('lastEvent') == EventManager.get(BopZoomEvent), 'callbacks observe the actual cached native event');

			script.set('mode', 3);
			camera.zoom = 1;
			play.camHUD.zoom = 1;
			play.camGameZoomMult = 1.5;
			play.camHUDZoomMult = 0.5;
			play.maxCamZoom = 10;
			play.camZoomingMult = 1;
			play.doBopZoom();
			require(near(camera.zoom, 1.6) && near(play.camHUD.zoom, 1.2) && near(play.camZoomingMult, 1),
				'script can select direct game/HUD zoom with distinct strengths');

			script.set('mode', 4);
			play.useCamZoomMult = false;
			play.doBopZoom();
			require(near(play.camZoomingMult, 1.05) && near(camera.zoom, 1.6),
				'script can select multiplier zoom over configured direct zoom');

			script.set('mode', 0);
			play.useCamZoomMult = true;
			play.camZoomingMult = 2.5;
			play.doBopZoom();
			require(near(play.camZoomingMult, 2.5) && script.get('pre') == 7 && script.get('post') == 7 && script.get('typed') == 7,
				'capped zoom still delivers exactly one before/after pair');
		}
		catch (error:Dynamic) {
			camera.zoom = originalZoom;
			trace('[CNE bop zoom check] FAIL $error');
			Sys.stdout().flush();
			Sys.exit(1);
		}
		camera.zoom = originalZoom;
		pack.destroy();
		play.camHUD.destroy();
		if (previousEvent == null) EventManager.eventCache.remove(BopZoomEvent);
		else EventManager.eventCache.set(BopZoomEvent, previousEvent);
		trace('[CNE bop zoom check] ALL CHECKS PASSED');
		Sys.stdout().flush();
		Sys.exit(0);
	}
}
#end
