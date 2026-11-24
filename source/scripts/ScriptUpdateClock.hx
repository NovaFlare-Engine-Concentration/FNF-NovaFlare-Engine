package scripts;

class ScriptUpdateClock
{
	var phase = 0.0;
	var pendingElapsed = 0.0;

	public function new() {}

	public function reset():Void
	{
		phase = 0;
		pendingElapsed = 0;
	}

	public function advance(elapsed:Float, unscaledElapsed:Float, rate:Int):Null<Float>
	{
		if (rate <= 0) return elapsed;

		pendingElapsed += elapsed;
		phase += unscaledElapsed * rate;
		if (phase < 1 - 1e-9) return null;

		final result = pendingElapsed;
		pendingElapsed = 0;
		phase = phase < 1 ? 0 : phase % 1;
		return result;
	}
}
