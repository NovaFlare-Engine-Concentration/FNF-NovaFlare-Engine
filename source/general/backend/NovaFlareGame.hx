package general.backend;

import flixel.FlxG;
import flixel.FlxGame;
import flixel.FlxState;
import openfl.events.Event;
import scripts.ScriptUpdateClock;
import scripts.stages.GlobalHandler;
import scripts.stages.modules.ModuleHandler;

class NovaFlareGame extends FlxGame
{
	public static var scriptUpdateActive(default, null) = false;
	public static var scriptUpdateElapsed(default, null):Float = 0;
	public static var scriptUpdatesFollowDraw(default, null) = false;
	static var scriptTickElapsed:Null<Float>;
	static var insideUpdate = false;
	final scriptClock = new ScriptUpdateClock();
	var scriptRate = 0;
	var scriptClockState:FlxState;
	var manualUpdatePending = false;
	var resetScriptElapsed = false;

	override function create(event:Event):Void
	{
		if (stage == null) return;
		FlxG.signals.preDraw.add(finishScriptUpdate);
		addEventListener(Event.REMOVED_FROM_STAGE, detachScriptUpdates);
		super.create(event);
	}

	function detachScriptUpdates(_:Event):Void
	{
		FlxG.signals.preDraw.remove(finishScriptUpdate);
		removeEventListener(Event.REMOVED_FROM_STAGE, detachScriptUpdates);
		scriptUpdateActive = false;
	}

	override function onFocus(event:Event):Void
	{
		super.onFocus(event);
		RenderResolution.applyDrawRate(stage);
	}

	override function onFocusLost(event:Event):Void
	{
		if (FlxG.autoPause)
		{
			resetScriptElapsed = true;
			scriptClock.reset();
		}
		super.onFocusLost(event);
	}

	public static function scriptElapsedForUpdate(elapsed:Float):Null<Float>
	{
		if (scriptUpdatesFollowDraw) return null;
		return insideUpdate ? scriptTickElapsed : elapsed;
	}

	override function update():Void
	{
		if (FlxG.state.active && FlxG.state.exists)
		{
			// A setting change during a script callback takes effect at the next Update boundary.
			final followDraw = ClientPrefs.data.scriptUpdateFrameLimit;
			final rate = Std.int(Math.max(0, Math.min(2000, ClientPrefs.data.scriptUpdateRate)));
			if (followDraw != scriptUpdatesFollowDraw || rate != scriptRate) scriptClock.reset();
			scriptUpdatesFollowDraw = followDraw;
			scriptRate = rate;
			if (FlxG.vcr.paused) manualUpdatePending = true;
		}
		else scriptClock.reset();
		insideUpdate = true;
		try
		{
			super.update();
		}
		catch (error:Dynamic)
		{
			insideUpdate = false;
			throw error;
		}
		insideUpdate = false;
	}

	override function updateElapsed():Void
	{
		super.updateElapsed();
		if (scriptClockState != FlxG.state)
		{
			scriptClockState = FlxG.state;
			scriptClock.reset();
		}
		if (scriptUpdatesFollowDraw) return;
		final unscaled = #if CODENAME_ENGINE_COMPAT FlxG.rawElapsed #else unscaledElapsed(FlxG.elapsed, FlxG.updateFramerate) #end;
		scriptTickElapsed = scriptClock.advance(FlxG.elapsed, unscaled, scriptRate);
	}

	inline function unscaledElapsed(elapsed:Float, rate:Int):Float
	{
		return FlxG.timeScale > 0 ? elapsed / FlxG.timeScale : 1 / Math.max(1, rate);
	}

	override function draw():Void
	{
		if (!FlxG.state.visible || !FlxG.state.exists) resetScriptElapsed = true;
		try
		{
			super.draw();
		}
		catch (error:Dynamic)
		{
			scriptUpdateActive = false;
			throw error;
		}
		scriptUpdateActive = false;
	}

	override function updateDrawElapsed():Void
	{
		super.updateDrawElapsed();
		final manuallyAdvanced = manualUpdatePending;
		manualUpdatePending = false;
		if (!scriptUpdatesFollowDraw) return;
		if (!FlxG.state.active || (@:privateAccess _lostFocus && FlxG.autoPause) || (FlxG.vcr.paused && !manuallyAdvanced))
		{
			resetScriptElapsed = true;
			return;
		}

		if (resetScriptElapsed) scriptClock.reset();
		final elapsed = resetScriptElapsed ? 0 : FlxG.drawElapsed;
		resetScriptElapsed = false;
		final scriptElapsed = scriptClock.advance(elapsed, unscaledElapsed(elapsed, FlxG.drawFramerate), scriptRate);
		if (scriptElapsed == null) return;
		scriptUpdateElapsed = scriptElapsed;
		scriptUpdateActive = true;
		ModuleHandler.dispatchScriptUpdate("onUpdate", scriptUpdateElapsed);
		GlobalHandler.dispatchScriptUpdate("onUpdate", scriptUpdateElapsed);
	}

	// preDraw runs immediately after the state's drawUpdate traversal.
	function finishScriptUpdate():Void
	{
		if (!scriptUpdateActive) return;
		scriptUpdateActive = false;
		ModuleHandler.dispatchScriptUpdate("onUpdatePost", scriptUpdateElapsed);
		GlobalHandler.dispatchScriptUpdate("onUpdatePost", scriptUpdateElapsed);
	}
}
