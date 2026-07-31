package general.backend;

import openfl.Lib;

import flixel.addons.ui.FlxUIState;

import general.backend.PsychCamera;

import general.shaders.ColorblindFilter;
import gameanalytics.GABridge;

#if hxvlc
import VideoHandler;
#end

class MusicBeatState extends FlxUIState
{
	public static var instance:MusicBeatState;

	private var curSection:Int = 0;
	private var stepsToDo:Int = 0;

	private var curStep:Int = 0;
	private var curBeat:Int = 0;

	private var curDecStep:Float = 0;
	private var curDecBeat:Float = 0;

	public var controls(get, never):Controls;

	private function get_controls()
	{
		return Controls.instance;
	}

	public var virtualPad:FlxVirtualPad;
	public var mobileControls:MobileControls;
	public var camControls:FlxCamera;
	public var vpadCam:FlxCamera;

	public function addVirtualPad(DPad:FlxDPadMode, Action:FlxActionMode)
	{
		virtualPad = new FlxVirtualPad(DPad, Action);
		virtualPad.alpha = ClientPrefs.data.controlsAlpha + 0.000001;
		add(virtualPad);
		#if desktop
		if (!ClientPrefs.data.needMobileControl)
		{
			virtualPad.alpha = 0;
			virtualPad.active = virtualPad.visible = false;
		}
		#end
	}

	public function removeVirtualPad()
	{
		if (virtualPad != null)
			remove(virtualPad);
	}

	public function addMobileControls(DefaultDrawTarget:Bool = true):Void
	{
		controls.isInSubstate = false;
		mobileControls = new MobileControls();

		var stage = Lib.current.stage;

		var scale:Float;
		var newWidth:Int;
		var newHeight:Int;

		if (ClientPrefs.data.useFlixelCoords)
		{
			newWidth = Std.int(FlxG.width);
			newHeight = Std.int(FlxG.height);
		}
		else
		{
			scale = Math.min((stage.stageWidth / FlxG.width), (stage.stageHeight / FlxG.height));
			newWidth = Std.int(stage.stageWidth / scale);
			newHeight = Std.int(stage.stageHeight / scale);
		}

		camControls = new FlxCamera(0, 0, newWidth, newHeight);

		camControls.x = (FlxG.width - newWidth) / 2;
		camControls.y = (FlxG.height - newHeight) / 2;
		camControls.bgColor.alpha = 0;
		FlxG.cameras.add(camControls, DefaultDrawTarget);

		mobileControls.cameras = [camControls];
		mobileControls.alpha = ClientPrefs.data.playControlsAlpha + 0.000001;
		add(mobileControls);
		#if desktop
		if (!ClientPrefs.data.needMobileControl)
		{
			mobileControls.alpha = 0;
			mobileControls.active = mobileControls.visible = false;
		}
		#end
	}

	public function removeMobileControls()
	{
		if (mobileControls != null)
			mobileControls = FlxDestroyUtil.destroy(mobileControls);
	}

	public function addVirtualPadCamera(DefaultDrawTarget:Bool = true):Void
	{
		if (virtualPad != null)
		{
			var stage = Lib.current.stage;

			var scale:Float;
			var newWidth:Int;
			var newHeight:Int;

			if (ClientPrefs.data.useFlixelCoords)
			{
				newWidth = Std.int(FlxG.width);
				newHeight = Std.int(FlxG.height);
			}
			else
			{
				scale = Math.min((stage.stageWidth / FlxG.width), (stage.stageHeight / FlxG.height));
				newWidth = Std.int(stage.stageWidth / scale);
				newHeight= Std.int(stage.stageHeight / scale);
			}
			vpadCam = new FlxCamera(0, 0, newWidth, newHeight);
			vpadCam.bgColor.alpha = 0;
			FlxG.cameras.add(vpadCam, DefaultDrawTarget);
			virtualPad.cameras = [vpadCam];
		}
	}

	override function destroy()
	{
		super.destroy();

		// Script-created VideoHandlers live below the mouse in FlxG.game rather
		// than inside this state's member list. A number of hxcodec-era mods
		// call stop() from onDestroy(), but hxvlc's stop() only halts playback:
		// it does not release VLC, its buffers, or the display-tree reference.
		#if hxvlc
		if (variables != null)
		{
			for (value in variables)
			{
				if (Std.isOfType(value, VideoHandler))
				try
				{
					cast(value, VideoHandler).finishVideo();
				}
				catch (e:Dynamic)
				{
					FlxG.log.warn('Could not dispose script video: $e');
				}
			}
		}
		#end

		if (variables != null)
			variables.clear();

		if (virtualPad != null)
		{
			virtualPad = FlxDestroyUtil.destroy(virtualPad);
			virtualPad = null;
		}

		if (mobileControls != null)
		{
			mobileControls = FlxDestroyUtil.destroy(mobileControls);
			mobileControls = null;
		}
	}

	var _psychCameraInitialized:Bool = false;

	public var variables:Map<String, Dynamic> = new Map<String, Dynamic>();

	public static function getVariables()
		return getState().variables;

	override function create()
	{
		instance = this;

		var skip:Bool = FlxTransitionableState.skipNextTransOut;
		#if MODS_ALLOWED Mods.updatedOnState = false; #end

		if (!_psychCameraInitialized)
			initPsychCamera();

		ColorblindFilter.UpdateColors();

		super.create();

		if (!skip)
		{
			openSubState(new CustomFadeTransition(0.6, true));
		}
		FlxTransitionableState.skipNextTransOut = false;
		timePassedOnState = 0;
	}

	public function initPsychCamera():PsychCamera
	{
		var camera = new PsychCamera();
		FlxG.cameras.reset(camera);
		FlxG.cameras.setDefaultDrawTarget(camera, true);
		_psychCameraInitialized = true;
		// trace('initialized psych camera ' + Sys.cpuTime());
		return camera;
	}

	public static var timePassedOnState:Float = 0;
	public var allowMinorGc:Bool = true;
	private var gameAnalyticsElapsed:Float = 0;
	private var lastSavedFullscreen:Null<Bool> = null;

	override function update(elapsed:Float)
	{
		// everyStep();
		var oldStep:Int = curStep;
		timePassedOnState += elapsed;
		// Analytics has no useful 2000 Hz signal.  Preserve the complete elapsed
		// time while removing thousands of bridge/dynamic calls per second from
		// every state.
		gameAnalyticsElapsed += elapsed;
		if (gameAnalyticsElapsed >= 1 / 60)
		{
			GABridge.update(gameAnalyticsElapsed);
			gameAnalyticsElapsed = 0;
		}

		updateCurStep();
		updateBeat();

		if (oldStep != curStep)
		{
			if (curStep > 0)
				stepHit();

			if (PlayState.SONG != null)
			{
				if (oldStep < curStep)
					updateSection();
				else
					rollbackSection();
			}
		}

		if (FlxG.save.data != null && lastSavedFullscreen != FlxG.fullscreen)
		{
			lastSavedFullscreen = FlxG.fullscreen;
			FlxG.save.data.fullscreen = lastSavedFullscreen;
		}

		// This is the hottest stage dispatch in the engine.  Avoid allocating a
		// closure on every update; event/beat dispatches remain on the generic
		// helper because they are infrequent.
		for (stage in stages)
			if (stage != null && stage.exists && stage.active)
				stage.update(elapsed);

		super.update(elapsed);
	}

	override function draw()
	{
		super.draw();
		
		#if TRACY_ALLOWED
			cpp.vm.tracy.TracyProfiler.frameMark();
		#end
	}

	private function updateSection():Void
	{
		if (stepsToDo < 1)
			stepsToDo = Math.round(getBeatsOnSection() * 4);
		while (curStep >= stepsToDo)
		{
			curSection++;
			var beats:Float = getBeatsOnSection();
			stepsToDo += Math.round(beats * 4);
			sectionHit();
		}
	}

	private function rollbackSection():Void
	{
		if (curStep < 0)
			return;

		var lastSection:Int = curSection;
		curSection = 0;
		stepsToDo = 0;
		for (i in 0...PlayState.SONG.notes.length)
		{
			if (PlayState.SONG.notes[i] != null)
			{
				stepsToDo += Math.round(getBeatsOnSection() * 4);
				if (stepsToDo > curStep)
					break;

				curSection++;
			}
		}

		if (curSection > lastSection)
			sectionHit();
	}

	private function updateBeat():Void
	{
		curBeat = Math.floor(curStep / 4);
		curDecBeat = curDecStep / 4;
	}

	private function updateCurStep():Void
	{
		var lastChange = Conductor.getBPMFromSeconds(Conductor.songPosition);

		var shit = ((Conductor.songPosition - ClientPrefs.data.noteOffset) - lastChange.songTime) / lastChange.stepCrochet;
		curDecStep = lastChange.stepTime + shit;
		curStep = lastChange.stepTime + Math.floor(shit);
	}

	public static function switchState(nextState:FlxState = null)
	{
		var basicKeys = ['ui_up', 'ui_down', 'ui_left', 'ui_right', 'accept', 'back'];
		var needReset = false;
		for (k in basicKeys) {
			var arr = ClientPrefs.keyBinds.get(k);
			if (arr == null || arr.length == 0 || (arr.length == 1 && arr[0] == NONE)) { needReset = true; break; }
		}
		if (needReset) {
			if (ClientPrefs.defaultKeys == null) ClientPrefs.loadDefaultKeys();
			ClientPrefs.keyBinds.clear();
			for (k => v in ClientPrefs.defaultKeys) ClientPrefs.keyBinds.set(k, v.copy());
		}

		if (nextState == null)
			nextState = FlxG.state;
		if (nextState == FlxG.state)
		{
			resetState();
			return;
		}

		if (FlxTransitionableState.skipNextTransIn)
			FlxG.switchState(nextState);
		else
			startTransition(nextState);
		FlxTransitionableState.skipNextTransIn = false;
	}

	public static function resetState()
	{
		if (FlxTransitionableState.skipNextTransIn)
			FlxG.resetState();
		else
			startTransition();
		FlxTransitionableState.skipNextTransIn = false;
	}

	// Custom made Trans in
	public static function startTransition(nextState:FlxState = null)
	{
		if (nextState == null)
			nextState = FlxG.state;

		FlxG.state.openSubState(new CustomFadeTransition(0.6, false));
		if (nextState == FlxG.state)
			CustomFadeTransition.finishCallback = function() FlxG.resetState();
		else
			CustomFadeTransition.finishCallback = function() FlxG.switchState(nextState);
	}

	public static function getState():MusicBeatState
	{
		return cast(FlxG.state, MusicBeatState);
	}

	public function stepHit():Void
	{
		stagesFunc(function(stage:BaseStage)
		{
			stage.curStep = curStep;
			stage.curDecStep = curDecStep;
			stage.stepHit();
		});

		if (curStep % 4 == 0)
			beatHit();
	}

	public var stages:Array<BaseStage> = [];

	public function beatHit():Void
	{
		stagesFunc(function(stage:BaseStage)
		{
			stage.curBeat = curBeat;
			stage.curDecBeat = curDecBeat;
			stage.beatHit();
		});
	}

	public function sectionHit():Void
	{
		// trace('Section: ' + curSection + ', Beat: ' + curBeat + ', Step: ' + curStep);
		stagesFunc(function(stage:BaseStage)
		{
			stage.curSection = curSection;
			stage.sectionHit();
		});
	}

	function stagesFunc(func:BaseStage->Void)
	{
		for (stage in stages)
			if (stage != null && stage.exists && stage.active)
				func(stage);
	}

	function getBeatsOnSection()
	{
		var val:Null<Float> = 4;
		if (PlayState.SONG != null && PlayState.SONG.notes[curSection] != null)
			val = PlayState.SONG.notes[curSection].sectionBeats;
		return val == null ? 4 : val;
	}
}
