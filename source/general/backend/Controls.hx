package general.backend;

import flixel.input.gamepad.FlxGamepadButton;
import flixel.input.gamepad.FlxGamepadInputID;
import flixel.input.gamepad.mappings.FlxGamepadMapping;
import flixel.input.keyboard.FlxKey;

class Controls
{
	// Keeping same use cases on stuff for it to be easier to understand/use
	// I'd have removed it but this makes it a lot less annoying to use in my opinion
	// You do NOT have to create these variables/getters for adding new keys,
	// but you will instead have to use:
	//   controls.justPressed("ui_up")   instead of   controls.UI_UP
	// Dumb but easily usable code, or Smart but complicated? Your choice.
	// Also idk how to use macros they're weird as fuck lol
	// Pressed buttons (directions)
	public var UI_UP_P(get, never):Bool;
	public var UI_DOWN_P(get, never):Bool;
	public var UI_LEFT_P(get, never):Bool;
	public var UI_RIGHT_P(get, never):Bool;
	public var NOTE_UP_P(get, never):Bool;
	public var NOTE_DOWN_P(get, never):Bool;
	public var NOTE_LEFT_P(get, never):Bool;
	public var NOTE_RIGHT_P(get, never):Bool;

	private function get_UI_UP_P()
		return justPressed('ui_up');

	private function get_UI_DOWN_P()
		return justPressed('ui_down');

	private function get_UI_LEFT_P()
		return justPressed('ui_left');

	private function get_UI_RIGHT_P()
		return justPressed('ui_right');

	private function get_NOTE_UP_P()
		return justPressed('note_up');

	private function get_NOTE_DOWN_P()
		return justPressed('note_down');

	private function get_NOTE_LEFT_P()
		return justPressed('note_left');

	private function get_NOTE_RIGHT_P()
		return justPressed('note_right');

	// Held buttons (directions)
	public var UI_UP(get, never):Bool;
	public var UI_DOWN(get, never):Bool;
	public var UI_LEFT(get, never):Bool;
	public var UI_RIGHT(get, never):Bool;
	public var NOTE_UP(get, never):Bool;
	public var NOTE_DOWN(get, never):Bool;
	public var NOTE_LEFT(get, never):Bool;
	public var NOTE_RIGHT(get, never):Bool;

	private function get_UI_UP()
		return pressed('ui_up');

	private function get_UI_DOWN()
		return pressed('ui_down');

	private function get_UI_LEFT()
		return pressed('ui_left');

	private function get_UI_RIGHT()
		return pressed('ui_right');

	private function get_NOTE_UP()
		return pressed('note_up');

	private function get_NOTE_DOWN()
		return pressed('note_down');

	private function get_NOTE_LEFT()
		return pressed('note_left');

	private function get_NOTE_RIGHT()
		return pressed('note_right');

	// Released buttons (directions)
	public var UI_UP_R(get, never):Bool;
	public var UI_DOWN_R(get, never):Bool;
	public var UI_LEFT_R(get, never):Bool;
	public var UI_RIGHT_R(get, never):Bool;
	public var NOTE_UP_R(get, never):Bool;
	public var NOTE_DOWN_R(get, never):Bool;
	public var NOTE_LEFT_R(get, never):Bool;
	public var NOTE_RIGHT_R(get, never):Bool;

	private function get_UI_UP_R()
		return justReleased('ui_up');

	private function get_UI_DOWN_R()
		return justReleased('ui_down');

	private function get_UI_LEFT_R()
		return justReleased('ui_left');

	private function get_UI_RIGHT_R()
		return justReleased('ui_right');

	private function get_NOTE_UP_R()
		return justReleased('note_up');

	private function get_NOTE_DOWN_R()
		return justReleased('note_down');

	private function get_NOTE_LEFT_R()
		return justReleased('note_left');

	private function get_NOTE_RIGHT_R()
		return justReleased('note_right');

	// Pressed buttons (others)
	public var ACCEPT(get, never):Bool;
	public var BACK(get, never):Bool;
	public var PAUSE(get, never):Bool;
	public var RESET(get, never):Bool;

	private function get_ACCEPT()
		return justPressed('accept');

	private function get_BACK()
		return justPressed('back');

	private function get_PAUSE()
		return justPressed('pause');

	private function get_RESET()
		return justPressed('reset');

	// Gamepad, Keyboard & Mobile stuff
	public var keyboardBinds:Map<String, Array<FlxKey>>;

	public function justPressed(key:String)
	{
		var result:Bool = (FlxG.keys.anyJustPressed(keyboardBinds[key]) == true);

		return result;
	}

	public function pressed(key:String)
	{
		var result:Bool = (FlxG.keys.anyPressed(keyboardBinds[key]) == true);

		return result;
	}

	public function justReleased(key:String)
	{
		var result:Bool = (FlxG.keys.anyJustReleased(keyboardBinds[key]) == true);

		return result;
	}

	public var controllerMode:Bool = false;

	public var isInSubstate:Bool = false; // don't worry about this it becomes true and false on it's own in MusicBeatSubstate
	public var requested(get, default):Dynamic; // is set to MusicBeatState or MusicBeatSubstate when the constructor is called
	public var gameplayRequest(get, default):Dynamic; // for PlayState and EditorPlayState (hitbox and virtualPad)
	public var mobileC(get, never):Bool;

	@:noCompletion
	private function get_requested():Dynamic
	{
		if (isInSubstate)
			return MusicBeatSubstate.instance;
		else
			return MusicBeatState.instance;
	}

	@:noCompletion
	private function get_gameplayRequest():Dynamic
	{
		if (isInSubstate)
			return MusicBeatSubstate.instance.mobileControls.current.target;
		else
			return MusicBeatState.instance.mobileControls.current.target;
	}

	@:noCompletion
	private function get_mobileC():Bool
	{
		// “调整移动端各Editor键位”开启期间：Editor 默认虚拟按键被隐藏并由外部窗口
		// 自定义按键接管（注入 FlxG.keys），因此这里按桌面键盘分支走，让自定义
		// 组合键能驱动 Editor 的全部操作。
		if (ClientPrefs.data.adjustMobileEditorKeys)
			return false;

		if (ClientPrefs.data.controlsAlpha >= 0.1 #if desktop && ClientPrefs.data.needMobileControl #end)
			return true;
		else
			return false;
	}

	// IGNORE THESE/ karim: no.
	public static var instance:Controls;

	public function new()
	{
		keyboardBinds = ClientPrefs.keyBinds;
	}
}
