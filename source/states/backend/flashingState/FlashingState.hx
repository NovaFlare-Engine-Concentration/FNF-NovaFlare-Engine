package states.backend.flashingState;

import lime.app.Application;

import flixel.FlxSubState;
import flixel.effects.FlxFlicker;

import states.titleState.TitleState;

class FlashingState extends MusicBeatState
{
	public static var leftState:Bool = false;

	var pressed:Bool = false;
	var warnText:FlxText;

	override function create()
	{
		super.create();

		var bg:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		add(bg);

		var guh:String = "Hey, watch out!\n
		This Mod contains some flashing lights!\n
		Press A/ENTER to disable them now or go to Options Menu.\n
		Press B/ESCAPE to ignore this message.\n
		You've been warned!";

		#if desktop
		guh += "\n\npress Keyboard will Disable touch control\n";
		#end

		warnText = new FlxText(0, 0, FlxG.width, guh, 32);
		warnText.setFormat("VCR OSD Mono", 32, FlxColor.WHITE, CENTER);
		warnText.screenCenter(Y);
		add(warnText);

		addVirtualPad(NONE, A_B);
	}

	override function update(elapsed:Float)
	{
		if (pressed)
			return;

		var back:Bool = controls.BACK;
		if (controls.ACCEPT || back)
		{
			pressed = true;
			FlxTransitionableState.skipNextTransIn = true;
			FlxTransitionableState.skipNextTransOut = true;
			if (!back)
			{
				if (!virtualPad.buttonA.justPressed)
					ClientPrefs.data.needMobileControl = false;
				ClientPrefs.data.flashing = true;
				ClientPrefs.saveSettings();
				FlxG.sound.play(Paths.sound('confirmMenu'));
				FlxFlicker.flicker(warnText, 1, 0.1, false, true, function(flk:FlxFlicker)
				{
					new FlxTimer().start(0.5, function(tmr:FlxTimer)
					{
						MusicBeatState.switchState(new TitleState());
					});
				});
			}
			else
			{
				if (!virtualPad.buttonB.justPressed)
					ClientPrefs.data.needMobileControl = false;
				ClientPrefs.data.flashing = false;
				ClientPrefs.saveSettings();
				FlxG.sound.play(Paths.sound('cancelMenu'));
				FlxTween.tween(warnText, {alpha: 0}, 1, {
					onComplete: function(twn:FlxTween)
					{
						MusicBeatState.switchState(new TitleState());
					}
				});
			}
		}
		super.update(elapsed);
	}
}
