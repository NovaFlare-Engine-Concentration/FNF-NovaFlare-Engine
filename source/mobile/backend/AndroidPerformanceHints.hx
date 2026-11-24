package mobile.backend;

#if android
class AndroidPerformanceHints
{
	static var requested:Bool = false;
	static var setRequested:Bool->Void;

	public static function setEnabled(enabled:Bool):Void
	{
		if (requested == enabled) return;
		if (setRequested == null)
		{
			setRequested = lime.system.JNI.createStaticMethod('org/haxe/lime/FramePerformanceHints', 'setEnabled', '(Z)V', false, true);
			if (setRequested == null)
			{
				trace('Android performance hints are unavailable in this build.');
				return;
			}
		}
		setRequested(enabled);
		requested = enabled;
	}
}
#end
