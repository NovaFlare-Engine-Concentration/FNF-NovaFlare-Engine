package options.base;

import flixel.addons.display.FlxBackdrop;
import flixel.addons.display.FlxGridOverlay;
import flixel.input.keyboard.FlxKey;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;

import general.backend.InputFormatter;
import general.backend.language.Language;

import general.objects.AttachedSprite;

class ControlsSubState extends MusicBeatSubstate
{
	var curSelected:Int = 0;
	var curAlt:Bool = false;

	// Show on gamepad - Display name - Save file key - Rebind display name - (optional) Language key
	var options:Array<Dynamic> = [
		[true, 'NOTES', null, null, 'notes'],
		[true],
		[true, '1K+2K+3K', null, null],
		[true, '1K', null, null, 'key_1k'],
		[true, '[key]', '0_key_0', '0k_0'],
		[true],
		[true, '2K', null, null, 'key_2k'],
		[true, 'left/左', '1_key_0', '1k_0'],
		[true, 'right/右', '1_key_1', '1k_1'],
		[true],
		[true, '3K', null, null, 'key_3k'],
		[true, 'left/左', '2_key_0', '2k_0'],
		[true, 'middle/中', '2_key_1', '2k_1'],
		[true, 'right/右', '2_key_2', '2k_2'],
		[true],
		[true, '4K+5K', null, null],
		[true, '4K', null, null, 'key_4k'],
		[true, 'left/左', 'note_left', 'Note Left', 'note_left'],
		[true, 'down/下', 'note_down', 'Note Down', 'note_down'],
		[true, 'up/上面', 'note_up', 'Note Up', 'note_up'],
		[true, 'right/右', 'note_right', 'Note Right', 'note_right'],
		[true],
		[true, '5K', null, null, 'key_5k'],
		[true, 'left/左', '4_key_0', '4k_0'],
		[true, 'down/下', '4_key_1', '4k_1'],
		[true, 'middle/中', '4_key_2', '4k_2'],
		[true, 'up/上面', '4_key_3', '4k_3'],
		[true, 'right/右', '4_key_4', '4k_4'],
		[true],
		[true, '6k', null, null, 'key_6k'],
		[true, 'left1/左1', '5_key_0', '5k_0'],
		[true, 'down/下', '5_key_1', '5k_1'],
		[true, 'right1/右1', '5_key_2', '5k_2'],
		[true, 'left2/左2', '5_key_3', '5k_3'],
		[true, 'up/上', '5_key_4', '5k_4'],
		[true, 'right2/右2', '5_key_5', '5k_5'],
		[true],
		[true, '7k', null, null, 'key_7k'],
		[true, 'left1/左1', '6_key_0', '6k_0'],
		[true, 'down/下', '6_key_1', '6k_1'],
		[true, 'right1/右1', '6_key_2', '6k_2'],
		[true, 'middle/中', '6_key_3', '6k_3'],
		[true, 'left2/左2', '6_key_4', '6k_4'],
		[true, 'up/上', '6_key_5', '6k_5'],
		[true, 'right2/右2', '6_key_6', '6k_6'],
		[true],
		[true, '8k', null, null, 'key_8k'],
		[true, 'left1/左1', '7_key_0', '7k_0'],
		[true, 'down/下1', '7_key_1', '7k_1'],
		[true, 'up1/上1', '7_key_2', '7k_2'],
		[true, 'right1/右1', '7_key_3', '7k_3'],
		[true, 'left2/左2', '7_key_4', '7k_4'],
		[true, 'down2/下2', '7_key_5', '7k_5'],
		[true, 'up2/上2', '7_key_6', '7k_6'],
		[true, 'right2/右2', '7_key_7', '7k_7'],
		[true],
		[true, '9k', null, null, 'key_9k'],
		[true, 'left1/左1', '8_key_0', '8k_0'],
		[true, 'down/下1', '8_key_1', '8k_1'],
		[true, 'up1/上1', '8_key_2', '8k_2'],
		[true, 'right1/右1', '8_key_3', '8k_3'],
		[true, 'middle/中', '8_key_4', '8k_4'],
		[true, 'left2/左2', '8_key_5', '8k_5'],
		[true, 'down2/下2', '8_key_6', '8k_6'],
		[true, 'up2/上2', '8_key_7', '8k_7'],
		[true, 'right2/右2', '8_key_8', '8k_8'],
		[true],
		[true, '10k', null, null, 'key_10k'],
		[true, 'left1/左1', '9_key_0', '9k_0'],
		[true, 'down/下1', '9_key_1', '9k_1'],
		[true, 'up1/上1', '9_key_2', '9k_2'],
		[true, 'right1/右1', '9_key_3', '9k_3'],
		[true, 'middle/中1', '9_key_4', '9k_4'],
		[true, 'middle/中2', '9_key_5', '9k_5'],
		[true, 'left2/左2', '9_key_6', '9k_6'],
		[true, 'down2/下2', '9_key_7', '9k_7'],
		[true, 'up2/上2', '9_key_8', '9k_8'],
		[true, 'right2/右2', '9_key_9', '9k_9'],
		[true],
		[true, 'UI', null, null, 'ui'],
		[true, 'left/左', 'ui_left', 'UI Left', 'ui_left'],
		[true, 'down/下', 'ui_down', 'UI Down', 'ui_down'],
		[true, 'up/上面', 'ui_up', 'UI Up', 'ui_up'],
		[true, 'right/右', 'ui_right', 'UI Right', 'ui_right'],
		[true],
		[true, 'Reset', 'reset', 'Reset', 'reset'],
		[true, 'Accept', 'accept', 'Accept', 'accept'],
		[true, 'Back', 'back', 'Back', 'back'],
		[true, 'Pause', 'pause', 'Pause', 'pause'],
		[true],
		[true, 'WINDOW', null, null, 'window'],
		[true, 'Fullscreen', 'fullscreen', 'Fullscreen Toggle', 'fullscreen']
	];
	var curOptions:Array<Int>;
	var curOptionsValid:Array<Int>;

	static var defaultKey:String = 'reset_to_default';

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

		var bg:FlxSprite = new FlxSprite(0, 0).makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		bg.scrollFactor.set();
		bg.alpha = 0;
		add(bg);
		FlxTween.tween(bg, {alpha: 0.8}, 0.5, {ease: FlxEase.circInOut});

		grpDisplay = new FlxTypedGroup<Alphabet>();
		add(grpDisplay);
		grpOptions = new FlxTypedGroup<Alphabet>();
		add(grpOptions);
		grpBlacks = new FlxTypedGroup<AttachedSprite>();
		add(grpBlacks);
		selectSpr = new AttachedSprite();
		selectSpr.makeGraphic(250, 55, FlxColor.WHITE);
		selectSpr.copyAlpha = false;
		selectSpr.alpha = 0.75;
		add(selectSpr);
		grpBinds = new FlxTypedGroup<Alphabet>();
		add(grpBinds);

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
		for (i in 0...options.length)
		{
			var option:Array<Dynamic> = options[i];
			if (option[0])
			{
				if (option.length > 1)
				{
					var isTitle:Bool = (option.length < 3 || option[2] == null);
					var isDefaultKey:Bool = (option.length > 1 && option[1] == defaultKey);
					var isDisplayKey:Bool = (isTitle && !isDefaultKey);

					// Translation lookup
					var displayText:String = option[1];
					if (isDefaultKey) {
						var translated:String = Language.get(defaultKey, 'controls');
						if (translated != null && translated != '' && translated != '(404) ' + defaultKey) displayText = translated;
					} else if (option.length > 4 && option[4] != null) {
						var translated:String = Language.get(option[4], 'controls');
						if (translated != null && translated != '' && translated != '(404) ' + option[4]) displayText = translated;
					}

					var text:Alphabet = new Alphabet(200, 300, displayText, !isDisplayKey);
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

					if (isTitle)
						addCenteredText(text, option, myID);
					else
						addKeyText(text, option, myID);

					text.snapToPosition();
					text.y += FlxG.height * 2;
				}
				myID++;
			}
		}
		updateText();
	}

	function addCenteredText(text:Alphabet, option:Array<Dynamic>, id:Int)
	{
		text.screenCenter(X);
	}

	function addKeyText(text:Alphabet, option:Array<Dynamic>, id:Int)
	{
		for (n in 0...2)
		{
			var textX:Float = 350 + n * 300;

			var key:String = null;
			var savKey:Array<Null<FlxKey>> = ClientPrefs.keyBinds.get(option[2]);
			key = InputFormatter.getKeyName((savKey[n] != null) ? savKey[n] : NONE);

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
			black.makeGraphic(250, 55, FlxColor.BLACK);
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
		if (timeForMoving > 0) // Fix controller bug
		{
			timeForMoving = Math.max(0, timeForMoving - elapsed);
			super.update(elapsed);
			return;
		}

		if (!binding)
		{
			if (controls.BACK)
			{
				visible = false;
				ClientPrefs.saveSettings();
				close();
				return;
			}

			if (controls.UI_LEFT_P || controls.UI_RIGHT_P)
				updateAlt(true);

			if (controls.UI_UP_P)
				updateText(-1);
			else if (controls.UI_DOWN_P)
				updateText(1);

			var resetPressed:Bool = FlxG.keys.justPressed.R || virtualPad.buttonC.justPressed;
			if (resetPressed)
			{
				ClientPrefs.resetKeys(false);
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

					var rebindText:String = Language.get('rebinding', 'controls');
					if (rebindText == '' || rebindText == '(404) rebinding') rebindText = 'Rebinding: ';
					bindingText = new Alphabet(FlxG.width / 2, 160, rebindText + "[ 请在这里键入你的按键 ]", false);
					bindingText.alignment = CENTERED;
					add(bindingText);

					var funnyText:String;

					if (controls.mobileC)
					{
						var bCancel:String = Language.get('holdBCancel', 'controls');
						if (bCancel == '' || bCancel.indexOf('(404)') >= 0) bCancel = 'Hold B to Cancel';
						var cDelete:String = Language.get('holdCDelete', 'controls');
						if (cDelete == '' || cDelete.indexOf('(404)') >= 0) cDelete = 'Hold C to Delete';
						funnyText = bCancel + '\n' + cDelete;
					}
					else
					{
						var escCancel:String = Language.get('holdEscCancel', 'controls');
						if (escCancel == '' || escCancel.indexOf('(404)') >= 0) escCancel = 'Hold ESC 2 Seconds to Cancel';
						var backDelete:String = Language.get('holdBackspaceDelete', 'controls');
						if (backDelete == '' || backDelete.indexOf('(404)') >= 0) backDelete = 'Hold Backspace to Delete the key';
						funnyText = '（' + escCancel + '）\n（' + backDelete + '）';
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
					ClientPrefs.resetKeys(false);
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
			if (virtualPad.buttonB.pressed || controls.BACK)
			{
				holdingEsc += elapsed;
				if (holdingEsc > 2.0)
				{
					FlxG.sound.play(Paths.sound('cancelMenu'));
					closeBinding();
				}
			}
			else if (virtualPad.buttonC.pressed || FlxG.keys.pressed.BACKSPACE)
			{
				holdingEsc += elapsed;
				if (holdingEsc > 0.5)
				{
					ClientPrefs.keyBinds.get(curOption[2])[altNum] = NONE;
					ClientPrefs.clearInvalidKeys(curOption[2]);
					updateBind(Math.floor(curSelected * 2) + altNum, InputFormatter.getKeyName(NONE));
					FlxG.sound.play(Paths.sound('cancelMenu'));
					closeBinding();
				}
			}
			else
			{
				holdingEsc = 0;
				var changed:Bool = false;
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

					var option:String = options[curOptions[curSelected]][2];
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
		super.update(elapsed);
	}

	function closeBinding()
	{
		binding = false;

		remove(bindingBlack);
		bindingBlack.destroy();

		remove(bindingText);
		bindingText.destroy();

		remove(bindingText2);
		bindingText2.destroy();
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
