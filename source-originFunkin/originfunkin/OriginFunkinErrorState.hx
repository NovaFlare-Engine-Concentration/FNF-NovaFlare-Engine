package originfunkin;

import flixel.FlxG;
import flixel.FlxState;
import flixel.text.FlxText;
import flixel.util.FlxColor;

/**
 * Keeps a present-but-invalid originFunkin folder from silently starting the
 * normal NovaFlare frontend.
 */
class OriginFunkinErrorState extends FlxState
{
	override public function create():Void
	{
		super.create();

		FlxG.camera.bgColor = FlxColor.BLACK;

		var title:FlxText = new FlxText(48, 60, FlxG.width - 96, "Origin Funkin");
		title.setFormat(null, 42, FlxColor.WHITE, CENTER);
		add(title);

		var message:String = OriginFunkinMode.preparationError;
		if (message == null || message.length == 0)
		{
			message = "The external FNF assets could not be loaded.";
		}

		var details:FlxText = new FlxText(80, 190, FlxG.width - 160,
			'$message\n\nExternal Origin assets folder:\n'
			+ '${OriginFunkinMode.assetsRoot}\n\n'
			+ "Restart the game after correcting the error.");
		details.setFormat(null, 20, FlxColor.LIME, CENTER);
		details.screenCenter(X);
		add(details);
	}
}
