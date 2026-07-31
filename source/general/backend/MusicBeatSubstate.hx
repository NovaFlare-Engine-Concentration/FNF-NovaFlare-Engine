package general.backend;

import openfl.Lib;

import flixel.FlxSubState;

import general.shaders.ColorblindFilter;

class MusicBeatSubstate extends FlxSubState
{
	public static var instance:MusicBeatSubstate;

	public function new()
	{
		instance = this;
		super();
	}

	override function create()
	{
		super.create();
		var currentControls = controls;
		if (currentControls != null)
			currentControls.isInSubstate = true;
		ColorblindFilter.UpdateColors();
	}

	private var curSection:Int = 0;
	private var stepsToDo:Int = 0;

	private var lastBeat:Float = 0;
	private var lastStep:Float = 0;

	private var curStep:Int = 0;
	private var curBeat:Int = 0;

	private var curDecStep:Float = 0;
	private var curDecBeat:Float = 0;
	private var controls(get, never):Controls;

	inline function get_controls():Controls
		return Controls.instance;

	public var virtualPad:FlxVirtualPad;
	public var mobileControls:MobileControls;

	public function addMobileControls(DefaultDrawTarget:Bool = true):Void
	{
		controls.isInSubstate = true;
		mobileControls = new MobileControls();

		var stage = Lib.current.stage;
		var scale:Float = 0;
		var newWidth:Int = 0;
		var newHeight:Int = 0;

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

		var camControls = new FlxCamera(newWidth, newHeight);
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
			remove(mobileControls);
	}

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

	public function addVirtualPadCamera(DefaultDrawTarget:Bool = true):Void
	{
		if (virtualPad != null)
		{
			var camControls:FlxCamera = new FlxCamera();
			camControls.bgColor.alpha = 0;
			FlxG.cameras.add(camControls, DefaultDrawTarget);
			virtualPad.cameras = [camControls];
		}
	}

	override function destroy()
	{
		super.destroy();

		var currentControls = controls;
		if (currentControls != null)
			currentControls.isInSubstate = false;
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

	override function close()
	{
		super.close();
		controls.isInSubstate = false;
	}

	override function update(elapsed:Float)
	{
		// everyStep();
		if (!persistentUpdate)
			MusicBeatState.timePassedOnState += elapsed;
		var oldStep:Int = curStep;

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

		super.update(elapsed);
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

	public function stepHit():Void
	{
		if (curStep % 4 == 0)
			beatHit();
	}

	public function beatHit():Void
	{
		// do literally nothing dumbass
	}

	public function sectionHit():Void
	{
		// yep, you guessed it, nothing again, dumbass
	}

	function getBeatsOnSection()
	{
		var val:Null<Float> = 4;
		if (PlayState.SONG != null && PlayState.SONG.notes[curSection] != null)
			val = PlayState.SONG.notes[curSection].sectionBeats;
		return val == null ? 4 : val;
	}
}
