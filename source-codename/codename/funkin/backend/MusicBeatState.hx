package codename.funkin.backend;

import flixel.FlxBasic;
import flixel.FlxState;
import flixel.FlxSubState;
import codename.funkin.backend.scripting.DummyScript;
import codename.funkin.backend.scripting.Script;
import codename.funkin.backend.scripting.ScriptPack;
import codename.funkin.backend.scripting.events.*;
import codename.funkin.backend.system.Conductor;
import codename.funkin.backend.system.Controls;
import codename.funkin.backend.system.GraphicCacheSprite;
import codename.funkin.backend.system.framerate.Framerate;
import codename.funkin.backend.system.interfaces.IBeatReceiver;
import codename.funkin.backend.system.interfaces.IBeatCancellableReceiver;
import codename.funkin.options.PlayerSettings;
#if TOUCH_CONTROLS
import codename.mobile.MobileControlLayer;
import codename.mobile.MobileControlScheme;
import mobile.objects.TouchPad;
import mobile.objects.Hitbox;
#end

/**
 * Base class for all the states.
 * Handles the scripts, the transitions, and the beat and step events.
**/
class MusicBeatState extends FlxState implements IBeatCancellableReceiver
{
	private var lastBeat:Float = 0;
	private var lastStep:Float = 0;

	/**
	 * Dummy sprite used to cache graphics to GPU.
	 */
	public var graphicCache:GraphicCacheSprite = new GraphicCacheSprite();
	/**
	 * Whenever the Conductor auto update should be enabled or not.
	 */
	public var cancelConductorUpdate:Bool = false;

	/**
	 * Current step
	 */
	public var curStep(get, never):Int;
	/**
	 * Current beat
	 */
	public var curBeat(get, never):Int;
	/**
	 * Current beat
	 */
	public var curMeasure(get, never):Int;
	/**
	 * Current step, as a `Float` (ex: 4.94, instead of 4)
	 */
	public var curStepFloat(get, never):Float;
	/**
	 * Current beat, as a `Float` (ex: 1.24, instead of 1)
	 */
	public var curBeatFloat(get, never):Float;
	/**
	 * Current beat, as a `Float` (ex: 1.24, instead of 1)
	 */
	public var curMeasureFloat(get, never):Float;
	/**
	 * Current song position (in milliseconds).
	 */
	public var songPos(get, never):Float;

	inline function get_curStep():Int
		return Conductor.curStep;
	inline function get_curBeat():Int
		return Conductor.curBeat;
	inline function get_curMeasure():Int
		return Conductor.curMeasure;
	inline function get_curStepFloat():Float
		return Conductor.curStepFloat;
	inline function get_curBeatFloat():Float
		return Conductor.curBeatFloat;
	inline function get_curMeasureFloat():Float
		return Conductor.curMeasureFloat;
	inline function get_songPos():Float
		return Conductor.songPosition;

	/**
	 * Game Controls. (All players / Solo)
	 */
	public var controls(get, never):Controls;

	/**
	 * Game Controls (Player 1 only)
	 */
	public var controlsP1(get, never):Controls;

	/**
	 * Game Controls (Player 2 only)
	 */
	public var controlsP2(get, never):Controls;

	/**
	 * Current injected script attached to the state. To add one, create a file at path "data/states/stateName" (ex: data/states/FreeplayState)
	 */
	public var stateScripts:ScriptPack;

	public var scriptsAllowed:Bool = true;

	public static var lastScriptName:String = null;
	public static var lastStateName:String = null;

	public var scriptName:String = null;

	public static var skipTransOut:Bool = false;
	public static var skipTransIn:Bool = false;

	public static var ALLOW_DEV_RELOAD:Bool = true;

	inline function get_controls():Controls
		return PlayerSettings.solo.controls;
	inline function get_controlsP1():Controls
		return PlayerSettings.player1.controls;
	inline function get_controlsP2():Controls
		return PlayerSettings.player2.controls;

	#if TOUCH_CONTROLS
	var mobileControlLayer:MobileControlLayer;
	public var touchPad(get, never):TouchPad;
	public var hitbox(get, never):Hitbox;
	public var hboxCam(get, never):FlxCamera;
	public var tpadCam(get, never):FlxCamera;
	/** Allows a state to keep its mobile controls hidden across update frames. */
	public var mobileControlsVisible:Bool = true;

	inline function get_touchPad():TouchPad return mobileControlLayer != null ? mobileControlLayer.touchPad : null;
	inline function get_hitbox():Hitbox return mobileControlLayer != null ? mobileControlLayer.hitbox : null;
	inline function get_hboxCam():FlxCamera return mobileControlLayer != null ? mobileControlLayer.hitboxCamera : null;
	inline function get_tpadCam():FlxCamera return mobileControlLayer != null ? mobileControlLayer.touchPadCamera : null;
	#end

	public function addTouchPad(DPad:String, Action:String):Void {
		#if TOUCH_CONTROLS
		mobileControlLayer.setTouchPad(DPad, Action);
		#end
	}

	public function removeTouchPad():Void {
		#if TOUCH_CONTROLS
		if (mobileControlLayer != null) mobileControlLayer.clearTouchPad();
		#end
	}

	public function addHitbox(?defaultDrawTarget:Bool = false):Void {
		#if TOUCH_CONTROLS
		mobileControlLayer.setHitbox(Options.extraHints, defaultDrawTarget);
		#end
	}

	public function removeHitbox():Void {
		#if TOUCH_CONTROLS
		if (mobileControlLayer != null) mobileControlLayer.clearHitbox();
		#end
	}

	public function addTouchPadCamera(?defaultDrawTarget:Bool = false):Void {
		#if TOUCH_CONTROLS
		mobileControlLayer.giveTouchPadCamera(defaultDrawTarget);
		#end
	}

	public function new(scriptsAllowed:Bool = true, ?scriptName:String) {
		super();
		#if TOUCH_CONTROLS
		mobileControlLayer = new MobileControlLayer(this);
		#end
		this.scriptsAllowed = #if SOFTCODED_STATES scriptsAllowed #else false #end;

		if(lastStateName != (lastStateName = Type.getClassName(Type.getClass(this)))) {
			lastScriptName = null;
		}
		this.scriptName = scriptName != null ? scriptName : lastScriptName;
		lastScriptName = this.scriptName;
	}

	function loadScript() {
		var className = Type.getClassName(Type.getClass(this));
		if (stateScripts == null)
			(stateScripts = new ScriptPack(className)).setParent(this);
		if (scriptsAllowed) {
			if (stateScripts.scripts.length == 0) {
				var scriptName = this.scriptName != null ? this.scriptName : className.substr(className.lastIndexOf(".")+1);
				for (i in codename.funkin.backend.assets.ModsFolder.getLoadedMods(true, true)) {
					var path = Paths.script('data/states/${scriptName}/LIB_$i');
					var script = Script.create(path);
					if (script is DummyScript) continue;
					script.remappedNames.set(script.fileName, '$i:${script.fileName}');
					stateScripts.add(script);
					script.load();
				}
			}
			#if EXPERMENTAL_SCRIPT_RELOADING
			else stateScripts.reload();
			#end
		}
		#if TOUCH_CONTROLS
		stateScripts.set("setTouchPadMode", function(dpadMode:String, actionMode:String, ?addCamera:Bool = false) {
			removeTouchPad();
			addTouchPad(dpadMode, actionMode);
			if (addCamera) addTouchPadCamera();
		});
		stateScripts.set("checkMobileInput", codename.mobile.CodeNameMobileInput.checkMobile);
		#end
	}

	public override function tryUpdate(elapsed:Float):Void
	{
		#if TOUCH_CONTROLS
		// Keep the state's controls ready behind transition-in. Regular substates
		// still hide them so their own controls remain the only active layer.
		var transitionOpen = Std.isOfType(subState, MusicBeatTransition);
		var showMobileControls = mobileControlsVisible && (subState == null || transitionOpen);
		mobileControlLayer.updateAvailability(showMobileControls, controls.touchC, subState == null || transitionOpen);
		codename.mobile.CodeNameMobileInput.beginConsumer(this);
		#end
		if (persistentUpdate || subState == null) {
			callOne("preUpdate", elapsed);
			update(elapsed);
			callOne("postUpdate", elapsed);
		}

		if (_requestSubStateReset) {
			_requestSubStateReset = false;
			resetSubState();
		}

		if (/*subState == null && */(ALLOW_DEV_RELOAD && controls.DEV_RELOAD)) {
			Logs.trace("Reloading Current State...", INFO, YELLOW);
			Paths.assetsTree.invalidateLookupCaches();
			FlxG.resetState();
		}
		#if TOUCH_CONTROLS
		codename.mobile.CodeNameMobileInput.endConsumer(this);
		#end

		if (subState != null)
			subState.tryUpdate(elapsed);
	}

	override function create()
	{
		loadScript();
		Framerate.offset.y = 0;
		super.create();
		#if TOUCH_CONTROLS
		// Create before createPost(), where the transition-in substate is opened.
		addDefaultMobileControls();
		#end
		call("create");
	}

	#if TOUCH_CONTROLS
	function addDefaultMobileControls():Void {
		var scheme = MobileControlScheme.forState(this);
		if (scheme == null) return;
		mobileControlLayer.apply(scheme, Options.extraHints);

		var className = Type.getClassName(Type.getClass(this));
		if (className == "codename.funkin.game.PlayState" && hitbox != null && touchPad != null)
			hitbox.forEachAlive(button -> button.deadZones.push(touchPad.buttonP));
		else if (className == "codename.funkin.menus.MainMenuState" && touchPad != null) {
			#if !MOD_SUPPORT
			touchPad.buttonM.visible = touchPad.buttonM.active = false;
			#end
			if (!Options.devMode || Flags.DISABLE_EDITORS)
				touchPad.buttonE.visible = touchPad.buttonE.active = false;
		}
	}

	function bringMobileControlsToFront():Void {
		mobileControlLayer.raise();
	}
	#end

	public override function createPost() {
		super.createPost();
		persistentUpdate = true;
		#if TOUCH_CONTROLS
		bringMobileControlsToFront();
		#end
		call("postCreate");
		if(!Flags.DISABLE_TRANSITIONS) {
			if (!skipTransIn)
				startTransition(null);
			skipTransIn = false;
			skipTransOut = false;
		}
	}

	public function startTransition(?newState:FlxState, skipSubStates:Bool = false):Bool {
		if (!skipSubStates) {
			var curCheckingSub:FlxSubState = subState;
			var found:FlxSubState = null;  // always gets the last one  - Nex

			while (curCheckingSub != null) {
				if (curCheckingSub is MusicBeatTransition) {
					found = null;  // avoiding infinite loops  - Nex
					break;
				}

				if (curCheckingSub is MusicBeatSubstate && cast(curCheckingSub, MusicBeatSubstate).canOpenCustomTransition) found = curCheckingSub;
				curCheckingSub = curCheckingSub.subState;
			}

			if (found != null) {
				found.openSubState(new MusicBeatTransition(newState));
				return true;  // "Started from a substate?"
			}
		}

		openSubState(new MusicBeatTransition(newState));
		return false;
	}

	public function call(name:String, ?args:Array<Dynamic>, ?defaultVal:Dynamic):Dynamic {
		// calls the function on the assigned script
		if(stateScripts != null)
			return stateScripts.call(name, args);
		return defaultVal;
	}

	public function callOne(name:String, arg:Dynamic, ?defaultVal:Dynamic):Dynamic {
		// calls the function on the assigned script with a single argument
		if(stateScripts != null)
			return stateScripts.callOne(name, arg);
		return defaultVal;
	}

	public function event<T:CancellableEvent>(name:String, event:T):T {
		if(stateScripts != null)
			stateScripts.event(name, event);
		return event;
	}

	override function update(elapsed:Float)
	{
		callOne("update", elapsed);

		super.update(elapsed);
	}

	@:noCompletion private var __beatReceivers:Array<IBeatReceiver> = [];
	@:noCompletion private var __beatReceiversDirty:Bool = true;
	@:noCompletion private var __lastMemberLength:Int = -1;

	function __refreshBeatReceivers():Void {
		__beatReceiversDirty = false;
		__lastMemberLength = members.length;
		__beatReceivers.resize(0);
		for (e in members)
			if (e != null && e is IBeatReceiver)
				__beatReceivers.push(cast e);
	}

	override function onMemberAdd(member:FlxBasic):Void {
		super.onMemberAdd(member);
		__beatReceiversDirty = true;
	}

	override function onMemberRemove(member:FlxBasic):Void {
		super.onMemberRemove(member);
		__beatReceiversDirty = true;
	}

	@:dox(hide) public function stepHit(curStep:Int):Void
	{
		if (__beatReceiversDirty || members.length != __lastMemberLength) __refreshBeatReceivers();
		for(e in __beatReceivers) e.stepHit(curStep);
		callOne("stepHit", curStep);
	}

	@:dox(hide) public function beatHit(curBeat:Int):Void
	{
		if (__beatReceiversDirty || members.length != __lastMemberLength) __refreshBeatReceivers();
		for(e in __beatReceivers) e.beatHit(curBeat);
		callOne("beatHit", curBeat);
	}

	@:dox(hide) public function measureHit(curMeasure:Int):Void
	{
		if (__beatReceiversDirty || members.length != __lastMemberLength) __refreshBeatReceivers();
		for(e in __beatReceivers) e.measureHit(curMeasure);
		callOne("measureHit", curMeasure);
	}

	/**
	 * Shortcut to `FlxMath.lerp` or `CoolUtil.lerp`, depending on `fpsSensitive`
	 * @param v1 Value 1
	 * @param v2 Value 2
	 * @param ratio Ratio
	 * @param fpsSensitive Whenever the ratio should not be adjusted to run at the same speed independent of framerate.
	 */
	public function lerp(v1:Float, v2:Float, ratio:Float, fpsSensitive:Bool = false) {
		if (fpsSensitive)
			return FlxMath.lerp(v1, v2, ratio);
		else
			return CoolUtil.fpsLerp(v1, v2, ratio);
	}

	/**
	 * SCRIPTING STUFF
	 */
	public override function openSubState(subState:FlxSubState) {
		var e = event("onOpenSubState", EventManager.get(StateEvent).recycle(subState));
		if (!e.cancelled)
			super.openSubState(e.substate is FlxSubState ? cast e.substate : subState);
	}
	
	public override function closeSubState() {
		var e = event("onCloseSubState", EventManager.get(StateEvent).recycle(subState));
		if (!e.cancelled)
			super.closeSubState();
	}

	public override function onResize(w:Int, h:Int) {
		super.onResize(w, h);
		event("onResize", EventManager.get(ResizeEvent).recycle(w, h, null, null));
	}

	public override function destroy() {
		#if TOUCH_CONTROLS
		if (mobileControlLayer != null) mobileControlLayer.destroy();
		#end
		super.destroy();
		graphicCache.destroy();
		call("destroy");
		stateScripts = FlxDestroyUtil.destroy(stateScripts);
	}

	public override function draw() {
		graphicCache.draw();
		var e = event("draw", EventManager.get(DrawEvent).recycle());
		if (!e.cancelled)
			super.draw();
		event("postDraw", e);
	}

	public override function switchTo(nextState:FlxState) {
		var e = event("onStateSwitch", EventManager.get(StateEvent).recycle(nextState));
		if (e.cancelled)
			return false;

		if(Flags.DISABLE_TRANSITIONS)
			return true;

		if (skipTransOut || (subState is MusicBeatTransition && cast(subState, MusicBeatTransition).newState != null))
			return true;
		startTransition(e.substate);
		persistentUpdate = false;
		return false;
	}

	public override function onFocus() {
		super.onFocus();
		call("onFocus");
	}

	public override function onFocusLost() {
		super.onFocusLost();
		call("onFocusLost");
	}

	public override function resetSubState() {
		var previousSubState = subState;
		super.resetSubState();
		#if TOUCH_CONTROLS
		// The parent's controls were inactive while the substate owned the touch.
		// Require that touch to end before those controls can become active again.
		if (previousSubState != null && subState == null) mobileControlLayer.blockCurrentTouches();
		#end
		if (subState != null && subState is MusicBeatSubstate) {
			var subState:MusicBeatSubstate = cast subState;
			subState.parent = this;
			subState.onSubstateOpen();
		}
	}
}
