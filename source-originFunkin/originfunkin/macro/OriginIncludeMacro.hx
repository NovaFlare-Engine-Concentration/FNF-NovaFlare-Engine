package originfunkin.macro;

#if macro
import haxe.macro.Compiler;
import haxe.macro.Context;

class OriginIncludeMacro
{
	static final FLIXEL_PACKAGES:Array<String> = [
		'flixel.util',
		'flixel.ui',
		'flixel.tweens',
		'flixel.tile',
		'flixel.text',
		'flixel.system',
		'flixel.sound',
		'flixel.path',
		'flixel.math',
		'flixel.input',
		'flixel.group',
		'flixel.graphics',
		'flixel.effects',
		'flixel.animation'
	];

	static final FLIXEL_ADDON_PACKAGES:Array<String> = [
		'flixel.addons.api',
		'flixel.addons.display',
		'flixel.addons.effects',
		'flixel.addons.ui',
		'flixel.addons.plugin',
		'flixel.addons.text',
		'flixel.addons.tile',
		'flixel.addons.transition',
		'flixel.addons.util'
	];

	static final FLIXEL_IGNORE:Array<String> = [
		'flixel.system.macros.*',
		'flixel.addons.editors.spine.*',
		'flixel.addons.nape.*',
		'flixel.addons.tile.FlxRayCastTilemap'
	];

	static final FUNKIN_IGNORE:Array<String> = [
		'funkin.mobile.*',
		'funkin.ui.credits.CreditsDataMacro',
		'funkin.ui.debug.anim.*',
		'funkin.ui.debug.charting.*',
		'funkin.ui.debug.stage.*',
		'funkin.ui.debug.stageeditor.*',
		'funkin.ui.haxeui.*'
	];

	static final FUNKIN_PACKAGES:Array<String> = [
		'funkin.api',
		'funkin.assets',
		'funkin.audio',
		'funkin.data',
		'funkin.effects',
		'funkin.external',
		'funkin.graphics',
		'funkin.group',
		'funkin.input',
		'funkin.memory',
		'funkin.modding',
		'funkin.play',
		'funkin.save',
		'funkin.touch',
		'funkin.tweens',
		'funkin.util',
		'funkin.ui'
	];

	public static function includeFlixel():Void
	{
		for (pack in FLIXEL_PACKAGES)
		{
			Compiler.include(pack, true, FLIXEL_IGNORE);
		}

		for (pack in FLIXEL_ADDON_PACKAGES)
		{
			Compiler.include(pack, true, FLIXEL_IGNORE);
		}
	}

	public static function includeFunkin():Void
	{
		for (pack in FUNKIN_PACKAGES)
		{
			Compiler.include(pack, true, FUNKIN_IGNORE);
		}

		if (Context.defined('mobile'))
		{
			Compiler.include('funkin.mobile');
		}
	}
}
#end
