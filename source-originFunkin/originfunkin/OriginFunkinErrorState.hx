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

		var title:FlxText = new FlxText(48, 92, FlxG.width - 96, "originFunkin 0.8.4");
		title.setFormat(null, 42, FlxColor.WHITE, CENTER);
		add(title);

		var message:String = OriginFunkinMode.preparationError;
		if (message == null || message.length == 0)
		{
			message = "The external FNF assets could not be loaded.";
		}

		var details:FlxText = new FlxText(80, 190, FlxG.width - 160,
			'$message\n\nPlace the unmodified FNF 0.8.4 asset folders inside:\n'
			+ '${OriginFunkinMode.assetsRoot}\n\n'
			+ "Remove the originFunkin folder to start NovaFlare normally.");
		details.setFormat(null, 24, FlxColor.LIME, CENTER);
		details.screenCenter(X);
		add(details);
	}
}
