package substates;

import flixel.FlxSubState;

import states.freeplayState.FreeplayState;
import states.mainMenuState.MainMenuState;

class ErrorSubState extends FlxSubState
{
	var failedState:flixel.FlxState;
	var exitTimer:FlxTimer;
	var exiting:Bool = false;
	var errorText:FlxText;
	var tips:FlxText;
	var error:String = "Oh Shit!";
	var bg:FlxSprite;
	var subcameras:FlxCamera;

	var saveMouseY:Int = 0;
	var moveData:Int = 0;
	var avgSpeed:Float = 0;

	var pressas:Int = 0;

	public function new(stack:String)
	{
		super();
		error = stack + "\n\nError message saved";
		FlxG.mouse.visible = !ClientPrefs.data.needMobileControl;
	}

	override function create()
	{
		super.create();
		failedState = FlxG.state;
		failedState.persistentUpdate = false;
		failedState.persistentDraw = false;

		subcameras = new FlxCamera();

		bg = originfunkin.OriginFunkinMode.active
			? new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK)
			: new FlxSprite().loadGraphic(Paths.image('egg'));
		bg.width = FlxG.width;
		bg.height = FlxG.height;
		bg.alpha = 0;
		add(bg);

		errorText = new FlxText(0, 0, FlxG.width, error, 50);
		if (!originfunkin.OriginFunkinMode.active) errorText.font = Paths.font('Lang-ZH.ttf');
		add(errorText);

		tips = new FlxText(0, 0, FlxG.width, 'Wait 10 second or press back / ENTER\nstate will close', 25);
		if (!originfunkin.OriginFunkinMode.active) tips.font = Paths.font('Lang-ZH.ttf');
		tips.x = FlxG.width - tips.width;
		tips.alignment = FlxTextAlign.RIGHT;
		add(tips);

		bg.cameras = [subcameras];
		errorText.cameras = [subcameras];
		tips.cameras = [subcameras];

		FlxG.cameras.add(subcameras, false);
		subcameras.bgColor.alpha = 0;

		exitTimer = new FlxTimer().start(10, function(tmr:FlxTimer)
		{
			close();
		});
	}

	override function update(elapsed:Float)
	{
		bg.alpha += elapsed * 1.5;
		if (bg.alpha > 0.6)
			bg.alpha = 0.6;
		if (FlxG.keys.justPressed.ENTER #if android || FlxG.android.justReleased.BACK #end)
		{
			pressas++;
		}

		if (pressas >= 1)
		{
			close();
			return;
		}

		if (FlxG.mouse.pressed)
		{
			if (errorText.height > FlxG.height)
			{
				if (FlxG.mouse.justPressed)
					saveMouseY = FlxG.mouse.y;
				moveData = FlxG.mouse.y - saveMouseY;
				saveMouseY = FlxG.mouse.y;

				errorText.y += moveData;
			}
			if (errorText.y < (FlxG.height - errorText.height))
				errorText.y = FlxG.height - errorText.height;
			if (errorText.y > 0)
				errorText.y = 0;
			// 限制错误信息可以滑动的范围
		}
		super.update(elapsed);
	}

	override function close()
	{
		if (exiting) return;
		exiting = true;
		if (exitTimer != null) exitTimer.cancel();
		if (originfunkin.OriginFunkinMode.active)
		{
			originfunkin.OriginFunkinMode.reportRuntimeError(error);
			FlxG.switchState(() -> new originfunkin.OriginFunkinErrorState());
			return;
		}

		// Leave the failed state frozen until the replacement is ready. Both
		// timeout and keyboard dismissal follow the same engine-specific route.
		#if CODENAME_ENGINE_COMPAT
		if (codenamechain.CodeNameMode.active)
		{
			codename.funkin.backend.MusicBeatState.skipTransOut = true;
			codename.funkin.backend.MusicBeatState.skipTransIn = true;
			FlxG.switchState(Std.isOfType(failedState, codename.funkin.game.PlayState)
				? new codename.funkin.menus.FreeplayState()
				: new codename.funkin.menus.MainMenuState());
			return;
		}
		#end
		flixel.addons.transition.FlxTransitionableState.skipNextTransOut = true;
		flixel.addons.transition.FlxTransitionableState.skipNextTransIn = true;
		FlxG.switchState(Std.isOfType(failedState, PlayState) ? new FreeplayState() : new MainMenuState());
	}

	override function destroy()
	{
		exitTimer = FlxDestroyUtil.destroy(exitTimer);
		if (subcameras != null && FlxG.cameras.list.contains(subcameras))
			FlxG.cameras.remove(subcameras);
		subcameras = null;
		failedState = null;
		FlxG.mouse.visible = false;
		super.destroy();
		bg = null;
		errorText = null;
		tips = null;
	}
}
