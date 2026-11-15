package codenamechain;

#if CODENAME_ENGINE_COMPAT
import flixel.text.FlxText.FlxTextFormatRange;

/**
 * Retains runtime classes that CNE mods instantiate only through HScript.
 * Haxe does not compile an otherwise unreachable class merely because a script
 * contains its name, even with DCE disabled.
 */
class CodeNameScriptRuntime
{
	static final retainedClasses:Array<Class<Dynamic>> = [
		cast hxvlc.flixel.FlxVideo,
		cast FlxTextFormatRange,
		cast flixel.addons.util.FlxSimplex,
		cast flixel.tweens.FlxTweenType_HSC,
		cast flixel.text.FlxTextAlign_HSC,
		cast codename.funkin.menus.ui.AlphabetAlignment_HSC,
		cast flixel.input.keyboard.FlxKey_HSC,
		cast flixel.input.gamepad.FlxGamepadInputID_HSC,
		cast openfl.ui.MouseCursor_HSC,
		cast codename.funkin.backend.utils.CoolSfx_HSC,
		cast codename.funkin.backend.scripting.events.sprite.PlayAnimContext_HSC
	];

	public static function init():Void
	{
		if (retainedClasses.length == 0)
			throw "CodeName script runtime registry was not generated";
	}
}
#end
