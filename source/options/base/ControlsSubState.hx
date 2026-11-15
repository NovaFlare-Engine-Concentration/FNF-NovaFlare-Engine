package options.base;

import flixel.addons.display.FlxBackdrop;
import flixel.addons.display.FlxGridOverlay;
import flixel.input.gamepad.FlxGamepad;
import flixel.input.gamepad.FlxGamepadInputID as GamepadID;
import flixel.input.keyboard.FlxKey;

import general.backend.InputFormatter;

import general.objects.AttachedSprite;

class ControlsSubState extends MusicBeatSubstate
{
	var curSelected:Int = 0;
	var curAlt:Bool = false;
	var lastControllerMode:Bool = false;

	// Show on gamepad - Display name - Save file key - Rebind display name
	var options:Array<Dynamic> = [
		[true, 'NOTES'],
		[true, '1K', '0_key_0', '0k_0'],
		[true],
		[true, '2K 0', '1_key_0', '1k_0'],
		[true, '2K 1', '1_key_1', '1k_1'],
		[true],
		[true, '3K 0', '2_key_0', '2k_0'],
		[true, '3K 1', '2_key_1', '2k_1'],
		[true, '3K 2', '2_key_2', '2k_2'],
		[true],
		[true],
		[true, 'Left', 'note_left', 'Note Left'],
		[true, 'Down', 'note_down', 'Note Down'],
		[true, 'Up', 'note_up', 'Note Up'],
		[true, 'Right', 'note_right', 'Note Right'],
		[true],
		[true, '5K 0', '4_key_0', '4k_0'],
		[true, '5K 1', '4_key_1', '4k_1'],
		[true, '5K 2', '4_key_2', '4k_2'],
		[true, '5K 3', '4_key_3', '4k_3'],
		[true, '5K 4', '4_key_4', '4k_4'],
		[true],
		[true, '6K 0', '5_key_0', '5k_0'],
		[true, '6K 1', '5_key_1', '5k_1'],
		[true, '6K 2', '5_key_2', '5k_2'],
		[true, '6K 3', '5_key_3', '5k_3'],
		[true, '6K 4', '5_key_4', '5k_4'],
		[true, '6K 5', '5_key_5', '5k_5'],
		[true],
		[true, '7K 0', '6_key_0', '6k_0'],
		[true, '7K 1', '6_key_1', '6k_1'],
		[true, '7K 2', '6_key_2', '6k_2'],
		[true, '7K 3', '6_key_3', '6k_3'],
		[true, '7K 4', '6_key_4', '6k_4'],
		[true, '7K 5', '6_key_5', '6k_5'],
		[true, '7K 6', '6_key_6', '6k_6'],
		[true],
		[true, '8K 0', '7_key_0', '7k_0'],
		[true, '8K 1', '7_key_1', '7k_1'],
		[true, '8K 2', '7_key_2', '7k_2'],
		[true, '8K 3', '7_key_3', '7k_3'],
		[true, '8K 4', '7_key_4', '7k_4'],
		[true, '8K 5', '7_key_5', '7k_5'],
		[true, '8K 6', '7_key_6', '7k_6'],
		[true, '8K 7', '7_key_7', '7k_7'],
		[true],
		[true, '9K 0', '8_key_0', '8k_0'],
		[true, '9K 1', '8_key_1', '8k_1'],
		[true, '9K 2', '8_key_2', '8k_2'],
		[true, '9K 3', '8_key_3', '8k_3'],
		[true, '9K 4', '8_key_4', '8k_4'],
		[true, '9K 5', '8_key_5', '8k_5'],
		[true, '9K 6', '8_key_6', '8k_6'],
		[true, '9K 7', '8_key_7', '8k_7'],
		[true, '9K 8', '8_key_8', '8k_8'],
		[true],
		[true, '10K 0', '9_key_0', '9k_0'],
		[true, '10K 1', '9_key_1', '9k_1'],
		[true, '10K 2', '9_key_2', '9k_2'],
		[true, '10K 3', '9_key_3', '9k_3'],
		[true, '10K 4', '9_key_4', '9k_4'],
		[true, '10K 5', '9_key_5', '9k_5'],
		[true, '10K 6', '9_key_6', '9k_6'],
		[true, '10K 7', '9_key_7', '9k_7'],
		[true, '10K 8', '9_key_8', '9k_8'],
		[true, '10K 9', '9_key_9', '9k_9'],
		[true],
		[true, 'UI'],
		[true, 'Left', 'ui_left', 'UI Left'],
		[true, 'Down', 'ui_down', 'UI Down'],
		[true, 'Up', 'ui_up', 'UI Up'],
		[true, 'Right', 'ui_right', 'UI Right'],
		[true],
		[true, 'Reset', 'reset', 'Reset'],
		[true, 'Accept', 'accept', 'Accept'],
		[true, 'Back', 'back', 'Back'],
		[true, 'Pause', 'pause', 'Pause'],
		[false],
		[false, 'VOLUME'],
		[false, 'Mute', 'volume_mute', 'Volume Mute'],
		[false, 'Up', 'volume_up', 'Volume Up'],
		[false, 'Down', 'volume_down', 'Volume Down'],
		[false],
		[false, 'DEBUG'],
		[false, 'Key 1', 'debug_1', 'Debug Key #1'],
		[false, 'Key 2', 'debug_2', 'Debug Key #2'],
		[true, 'WINDOW'],
		[true, 'Fullscreen', 'fullscreen', 'Fullscreen Toggle']
	];
	var curOptions:Array<Int>;
	var curOptionsValid:Array<Int>;

	static var defaultKey:String = 'Reset to Default Keys';

	var bg:FlxSprite;
	var grpDisplay:FlxTypedGroup<Alphabet>;
	var grpBlacks:FlxTypedGroup<AttachedSprite>;
	var grpOptions:FlxTypedGroup<Alphabet>;
	var grpBinds:FlxTypedGroup<Alphabet>;
	var selectSpr:AttachedSprite;

	var keyboardColor:FlxColor = 0xff7192fd;

	public function new()
	{
		super();

		#if DISCORD_ALLOWED
		DiscordClient.changePresence("Controls Menu", null);
		#end

		options.push([true]);
		options.push([true]);
		options.push([true, defaultKey]);

		var bg:FlxSprite = new FlxSprite(0, 0).makeGraphic(FlxG.width, FlxG.height, FlxColor.WHITE);
		bg.scrollFactor.set();
		bg.alpha = 0;
		add(bg);
		FlxTween.tween(bg, {alpha: 0.5}, 0.5, {ease: FlxEase.circInOut});

		grpDisplay = new FlxTypedGroup<Alphabet>();
		add(grpDisplay);
		grpOptions = new FlxTypedGroup<Alphabet>();
		add(grpOptions);
		grpBlacks = new FlxTypedGroup<AttachedSprite>();
		add(grpBlacks);
		selectSpr = new AttachedSprite();
		selectSpr.makeGraphic(250, 78, FlxColor.WHITE);
		selectSpr.copyAlpha = false;
		selectSpr.alpha = 0.75;
		add(selectSpr);
		grpBinds = new FlxTypedGroup<Alphabet>();
		add(grpBinds);

		var text:Alphabet = new Alphabet(60, 90, 'CTRL', false);
		text.alignment = CENTERED;
		text.setScale(0.4);
		add(text);

		addVirtualPad(OptionStateC, OptionStateC);

		createTexts();
	}

	var lastID:Int = 0;

	function createTexts()
	{
		curOptions = [];
		curOptionsValid = [];
		grpDisplay.forEachAlive(function(text:Alphabet) text.destroy());
		grpBlacks.forEachAlive(function(black:AttachedSprite) black.destroy());
		grpOptions.forEachAlive(function(text:Alphabet) text.destroy());
		grpBinds.forEachAlive(function(text:Alphabet) text.destroy());
		grpDisplay.clear();
		grpBlacks.clear();
		grpOptions.clear();
		grpBinds.clear();

		var myID:Int = 0;
		var hideSeparator:Bool = false;
		for (i in 0...options.length)
		{
			var option:Array<Dynamic> = options[i];
			if (option[0])
			{
				if (controls.controllerMode && option.length > 2 && !ClientPrefs.gamepadBinds.exists(option[2]))
				{
					hideSeparator = true;
					continue;
				}
				if (option.length <= 1)
				{
					if (hideSeparator)
					{
						hideSeparator = false;
						continue;
					}
				}
				else
					hideSeparator = false;

				if (option.length > 1)
				{
					var isCentered:Bool = (option.length < 3);
					var isDefaultKey:Bool = (option[1] == defaultKey);
					var isDisplayKey:Bool = (isCentered && !isDefaultKey);

					var text:Alphabet = new Alphabet(200, 300, option[1], !isDisplayKey);
					text.isMenuItem = true;
					text.changeX = false;
					text.distancePerItem.y = 60;
					text.targetY = myID;
					if (isDisplayKey)
						grpDisplay.add(text);
					else
					{
						grpOptions.add(text);
						curOptions.push(i);
						curOptionsValid.push(myID);
					}
					text.ID = myID;
					lastID = myID;

					if (isCentered)
						addCenteredText(text, option, myID);
					else
						addKeyText(text, option, myID);

					text.snapToPosition();
					text.y += FlxG.height * 2;
				}
				myID++;
			}
		}
		lastControllerMode = controls.controllerMode;
		updateText();
	}

	function addCenteredText(text:Alphabet, option:Array<Dynamic>, id:Int)
	{
		text.screenCenter(X);
		text.y -= 55;
		text.startPosition.y -= 55;
	}

	function addKeyText(text:Alphabet, option:Array<Dynamic>, id:Int)
	{
		for (n in 0...2)
		{
			var textX:Float = 350 + n * 300;

			var key:String = null;
			if (controls.controllerMode)
			{
				var savButton:Array<GamepadID> = ClientPrefs.gamepadBinds.get(option[2]);
				var button:GamepadID = (n < savButton.length) ? savButton[n] : GamepadID.NONE;
				key = InputFormatter.getGamepadName(button);
			}
			else
			{
				var savKey:Array<Null<FlxKey>> = ClientPrefs.keyBinds.get(option[2]);
				key = InputFormatter.getKeyName((savKey[n] != null) ? savKey[n] : NONE);
			}

			var attach:Alphabet = new Alphabet(textX + 210, 248, key, false);
			attach.isMenuItem = true;
			attach.changeX = false;
			attach.distancePerItem.y = 60;
			attach.targetY = text.targetY;
			attach.ID = Math.floor(grpBinds.length / 2);
			attach.snapToPosition();
			attach.y += FlxG.height * 2;
			grpBinds.add(attach);

			attach.scaleX = Math.min(1, 230 / attach.width);
			// attach.text = key;

			// spawn black bars at the right of the key name
			var black:AttachedSprite = new AttachedSprite();
			black.makeGraphic(250, 78, FlxColor.BLACK);
			black.alphaMult = 0.4;
			black.sprTracker = text;
			black.yAdd = -6;
			black.xAdd = textX;
			grpBlacks.add(black);
		}
	}

	function updateBind(num:Int, text:String)
	{
		var bind:Alphabet = grpBinds.members[num];
		var attach:Alphabet = new Alphabet(350 + (num % 2) * 300, 248, text, false);
		attach.isMenuItem = true;
		attach.changeX = false;
		attach.distancePerItem.y = 60;
		attach.targetY = bind.targetY;
		attach.ID = bind.ID;
		attach.x = bind.x;
		attach.y = bind.y;

		attach.scaleX = Math.min(1, 230 / attach.width);
		// attach.text = text;

		grpBinds.remove(bind);
		grpBinds.insert(num, attach);
		bind.destroy();
	}

	var binding:Bool = false;
	var holdingEsc:Float = 0;
	var bindingBlack:FlxSprite;
	var bindingText:Alphabet;
	var bindingText2:Alphabet;

	var timeForMoving:Float = 0.1;

	override function update(elapsed:Float)
	{
		if (timeForMoving > 0)
		{
			timeForMoving = Math.max(0, timeForMoving - elapsed);
			super.update(elapsed);
			return;
		}

		if (!binding)
		{
			if (FlxG.gamepads.anyJustPressed(GamepadID.ANY))
				controls.controllerMode = true;
			else if (FlxG.keys.justPressed.ANY)
				controls.controllerMode = false;

			if (controls.controllerMode != lastControllerMode)
			{
				curSelected = 0;
				createTexts();
			}

			if (controls.BACK)
			{
				ClientPrefs.saveSettings();
				close();
				//FlxTransitionableState.skipNextTransIn = true;
				//FlxTransitionableState.skipNextTransOut = true;
				//MusicBeatState.switchState(new options.OptionsState());
				return;
			}

			if (controls.UI_LEFT_P)
				updateAlt(true);

			if (controls.UI_UP_P)
				updateText(-1);
			else if (controls.UI_DOWN_P)
				updateText(1);

			var resetPressed:Bool = controls.RESET || virtualPad.buttonC.justPressed;
			if (resetPressed)
			{
				ClientPrefs.resetKeys(controls.controllerMode);
				ClientPrefs.reloadVolumeKeys();
				var lastSel:Int = curSelected;
				createTexts();
				curSelected = lastSel;
				updateText();
				FlxG.sound.play(Paths.sound('cancelMenu'));
			}

			if (controls.ACCEPT)
			{
				if (options[curOptions[curSelected]][1] != defaultKey)
				{
					bindingBlack = new FlxSprite().makeGraphic(1, 1, /*FlxColor.BLACK*/ FlxColor.WHITE);
					bindingBlack.scale.set(FlxG.width, FlxG.height);
					bindingBlack.updateHitbox();
					bindingBlack.alpha = 0;
					FlxTween.tween(bindingBlack, {alpha: 0.6}, 0.35, {ease: FlxEase.linear});
					add(bindingBlack);

					bindingText = new Alphabet(FlxG.width / 2, 160, "Rebinding " + options[curOptions[curSelected]][3], false);
					bindingText.alignment = CENTERED;
					add(bindingText);

					var funnyText:String;

					if (controls.mobileC)
					{
						funnyText = "Hold B to Cancel\nHold C to Delete";
					}
					else if (controls.controllerMode)
					{
						funnyText = "Tap to Bind\nHold B: Cancel, BACK: Delete";
					}
					else
					{
						funnyText = "Hold ESC to Cancel\nHold Backspace to Delete";
					}

					bindingText2 = new Alphabet(FlxG.width / 2, 340, funnyText, true);
					bindingText2.alignment = CENTERED;
					add(bindingText2);

					binding = true;
					holdingEsc = 0;
					ClientPrefs.toggleVolumeKeys(false);
					FlxG.sound.play(Paths.sound('scrollMenu'));
				}
				else
				{
					// Reset to Default
					ClientPrefs.resetKeys(controls.controllerMode);
					ClientPrefs.reloadVolumeKeys();
					var lastSel:Int = curSelected;
					createTexts();
					curSelected = lastSel;
					updateText();
					FlxG.sound.play(Paths.sound('cancelMenu'));
				}
			}
		}
	else
	{
		var altNum:Int = curAlt ? 1 : 0;
		var curOption:Array<Dynamic> = options[curOptions[curSelected]];
		var gamepadMode:Bool = controls.controllerMode;
		if (virtualPad.buttonB.pressed || controls.BACK || (gamepadMode && FlxG.gamepads.anyPressed(GamepadID.B)))
		{
			holdingEsc += elapsed;
			if (holdingEsc > 0.5)
			{
				FlxG.sound.play(Paths.sound('cancelMenu'));
				closeBinding();
			}
		}
		else if (virtualPad.buttonC.pressed || FlxG.keys.pressed.BACKSPACE || (gamepadMode && FlxG.gamepads.anyPressed(GamepadID.BACK)))
		{
			holdingEsc += elapsed;
			if (holdingEsc > 0.5)
			{
				if (gamepadMode)
				{
					ClientPrefs.gamepadBinds.get(curOption[2])[altNum] = GamepadID.NONE;
					ClientPrefs.clearInvalidButtons(curOption[2]);
					updateBind(Math.floor(curSelected * 2) + altNum, InputFormatter.getGamepadName(GamepadID.NONE));
				}
				else
				{
					ClientPrefs.keyBinds.get(curOption[2])[altNum] = NONE;
					ClientPrefs.clearInvalidKeys(curOption[2]);
					updateBind(Math.floor(curSelected * 2) + altNum, InputFormatter.getKeyName(NONE));
				}
				FlxG.sound.play(Paths.sound('cancelMenu'));
				closeBinding();
			}
		}
		else
		{
			holdingEsc = 0;
			var changed:Bool = false;

			if (gamepadMode)
			{
				var curButtons:Array<GamepadID> = ClientPrefs.gamepadBinds.get(curOption[2]);
				while (curButtons.length < 2)
					curButtons.push(GamepadID.NONE);
				if (FlxG.gamepads.anyJustPressed(GamepadID.ANY)
					|| FlxG.gamepads.anyJustPressed(GamepadID.LEFT_TRIGGER)
					|| FlxG.gamepads.anyJustPressed(GamepadID.RIGHT_TRIGGER)
					|| FlxG.gamepads.anyJustReleased(GamepadID.ANY))
				{
					var buttonPressed:GamepadID = GamepadID.NONE;
					if (FlxG.gamepads.anyJustPressed(GamepadID.LEFT_TRIGGER))
						buttonPressed = GamepadID.LEFT_TRIGGER;
					else if (FlxG.gamepads.anyJustPressed(GamepadID.RIGHT_TRIGGER))
						buttonPressed = GamepadID.RIGHT_TRIGGER;
					else
					{
						for (i in 0...FlxG.gamepads.numActiveGamepads)
						{
							var gamepad:FlxGamepad = FlxG.gamepads.getByID(i);
							if (gamepad != null)
							{
								buttonPressed = gamepad.firstJustPressedID();
								if (buttonPressed != GamepadID.NONE)
									break;
							}
						}
						if (buttonPressed == GamepadID.NONE)
						{
							for (i in 0...FlxG.gamepads.numActiveGamepads)
							{
								var gamepad:FlxGamepad = FlxG.gamepads.getByID(i);
								if (gamepad != null)
								{
									buttonPressed = gamepad.firstJustReleasedID();
									if (buttonPressed != GamepadID.NONE)
										break;
								}
							}
						}
					}

					if (buttonPressed != GamepadID.NONE)
					{
						curButtons[altNum] = buttonPressed;
						changed = true;
					}
				}

				if (changed)
				{
					if (curButtons[altNum] == curButtons[1 - altNum])
						curButtons[1 - altNum] = GamepadID.NONE;

					var option:String = curOption[2];
					ClientPrefs.clearInvalidButtons(option);
					for (n in 0...2)
					{
						var savButton:Array<GamepadID> = ClientPrefs.gamepadBinds.get(option);
						var button:GamepadID = (n < savButton.length) ? savButton[n] : GamepadID.NONE;
						updateBind(Math.floor(curSelected * 2) + n, InputFormatter.getGamepadName(button));
					}
					FlxG.sound.play(Paths.sound('confirmMenu'));
					closeBinding();
				}
			}
			else
			{
				var curKeys:Array<FlxKey> = ClientPrefs.keyBinds.get(curOption[2]);

				if (FlxG.keys.justPressed.ANY || FlxG.keys.justReleased.ANY)
				{
					var keyPressed:Int = FlxG.keys.firstJustPressed();
					var keyReleased:Int = FlxG.keys.firstJustReleased();
					if (keyPressed > -1 && keyPressed != FlxKey.ESCAPE && keyPressed != FlxKey.BACKSPACE)
					{
						curKeys[altNum] = keyPressed;
						changed = true;
					}
					else if (keyReleased > -1 && (keyReleased == FlxKey.ESCAPE || keyReleased == FlxKey.BACKSPACE))
					{
						curKeys[altNum] = keyReleased;
						changed = true;
					}
				}

				if (changed)
				{
					if (curKeys[altNum] == curKeys[1 - altNum])
						curKeys[1 - altNum] = FlxKey.NONE;

					var option:String = curOption[2];
					ClientPrefs.clearInvalidKeys(option);
					for (n in 0...2)
					{
						var key:String = null;
						var savKey:Array<Null<FlxKey>> = ClientPrefs.keyBinds.get(option);
						key = InputFormatter.getKeyName(savKey[n] != null ? savKey[n] : NONE);
						updateBind(Math.floor(curSelected * 2) + n, key);
					}
					FlxG.sound.play(Paths.sound('confirmMenu'));
					closeBinding();
				}
			}
		}
	}
		super.update(elapsed);
	}

	function closeBinding()
	{
		binding = false;
		bindingBlack.destroy();
		remove(bindingBlack);

		bindingText.destroy();
		remove(bindingText);

		bindingText2.destroy();
		remove(bindingText2);
		ClientPrefs.reloadVolumeKeys();
	}

	function updateText(?move:Int = 0)
	{
		if (move != 0)
		{
			// var dir:Int = Math.round(move / Math.abs(move));
			curSelected += move;

			if (curSelected < 0)
				curSelected = curOptions.length - 1;
			else if (curSelected >= curOptions.length)
				curSelected = 0;
		}

		var num:Int = curOptionsValid[curSelected];
		var addNum:Int = 0;
		if (num < 3)
			addNum = 3 - num;
		else if (num > lastID - 4)
			addNum = (lastID - 4) - num;

		grpDisplay.forEachAlive(function(item:Alphabet)
		{
			item.targetY = item.ID - num - addNum;
		});

		grpOptions.forEachAlive(function(item:Alphabet)
		{
			item.targetY = item.ID - num - addNum;
			item.alpha = (item.ID - num == 0) ? 1 : 0.6;
		});
		grpBinds.forEachAlive(function(item:Alphabet)
		{
			var parent:Alphabet = grpOptions.members[item.ID];
			item.targetY = parent.targetY;
			item.alpha = parent.alpha;
		});

		updateAlt();
		FlxG.sound.play(Paths.sound('scrollMenu'));
	}

	function updateAlt(?doSwap:Bool = false)
	{
		if (doSwap)
		{
			curAlt = !curAlt;
			FlxG.sound.play(Paths.sound('scrollMenu'));
		}
		selectSpr.sprTracker = grpBlacks.members[Math.floor(curSelected * 2) + (curAlt ? 1 : 0)];
		selectSpr.visible = (selectSpr.sprTracker != null);
	}
}

