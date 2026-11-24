package mobile.ui;

#if android
import haxe.ui.Toolkit;

class MobileHaxeUI {
	public static function initialize():Void {
		// Flixel already maps the logical UI pixels to the Android display.
		Toolkit.autoScale = false;
		Toolkit.scale = 1;
		if (!Toolkit.initialized) Toolkit.init();
	}
}
#end
