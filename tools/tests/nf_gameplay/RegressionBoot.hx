import haxe.macro.Context;
import haxe.macro.Expr;

/** Test-only bootstrap; leaves the normal game entry point unchanged. */
class RegressionBoot
{
	public static function install():Void
	{
		haxe.macro.Compiler.addMetadata('@:build(RegressionBoot.build())', 'Main');
	}

	public static function build():Array<Field>
	{
		var fields = Context.getBuildFields();
		for (field in fields)
			if (field.name == 'setupGame')
				switch (field.kind)
				{
					case FFun(fn):
						fn.expr = macro {
							addChild(new flixel.FlxGame(1280, 720, GameplayRegressionChecks, 60, 60, true));
						};
					default:
				}
		return fields;
	}
}
