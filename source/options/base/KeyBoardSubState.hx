package options.base;

import lime.system.Clipboard;

import flixel.addons.display.shapes.FlxShapeCircle;
import flixel.input.keyboard.FlxKey;
import flixel.util.FlxGradient;
import flixel.addons.ui.FlxUIInputText;

import games.objects.KeyboardViewer;

import options.OptionsHelpers;

class KeyBoardSubState extends MusicBeatSubstate
{
	var hexTypeLine:FlxSprite;
	var hexTypeNum:Int = -1;
	var hexTypeVisibleTimer:Float = 0;

	var copyButton:FlxSprite;
	var pasteButton:FlxSprite;

	var colorGradient:FlxSprite;
	var colorGradientSelector:FlxSprite;
	var colorPalette:FlxSprite;
	var colorWheel:FlxSprite;
	var colorWheelSelector:FlxSprite;

	var alphabetR:Alphabet;
	var alphabetG:Alphabet;
	var alphabetB:Alphabet;
	var alphabetHex:Alphabet;

	var controllerPointer:FlxSprite;
	var _lastControllerMode:Bool = false;
	var tipTxt:FlxText;

	var AndroidColorGet:FlxUIInputText;
	var underline_text_BG:FlxSprite;
	var LengthCheck:String = '';
	var ColorCheck:String = '';

	var targetBGButton:FlxSprite;
	var targetTextButton:FlxSprite;
	var colorTarget:Int = 0;
	var lastColor:FlxColor = FlxColor.WHITE;

	var pendingBG:FlxColor = FlxColor.WHITE;
	var pendingText:FlxColor = FlxColor.BLACK;

	var previewKeyboard:KeyboardViewer;
	var camKey:FlxCamera;

	public function new()
	{
		super();

		#if DISCORD_ALLOWED
		DiscordClient.changePresence("KeyBoard Colors Menu", null);
		#end

		var bg:FlxSprite = new FlxSprite(0, 0).makeGraphic(FlxG.width, FlxG.height, FlxColor.WHITE);
		bg.scrollFactor.set();
		bg.alpha = 0.5;
		add(bg);

		var bg:FlxSprite = new FlxSprite(720).makeGraphic(FlxG.width - 720, FlxG.height, FlxColor.BLACK);
		bg.alpha = 0.25;
		add(bg);
		var bg:FlxSprite = new FlxSprite(750, 160).makeGraphic(FlxG.width - 780, 540, FlxColor.BLACK);
		bg.alpha = 0.25;
		add(bg);

		camKey = new FlxCamera(0, 0, FlxG.width, FlxG.height);
		camKey.bgColor = FlxColor.TRANSPARENT;
		FlxG.cameras.add(camKey, false);

		previewKeyboard = new KeyboardViewer(50, 300, true);

		previewKeyboard.cameras = [camKey];
		add(previewKeyboard);
		previewKeyboard.x += 300;
		previewKeyboard.y += 50;

		camKey.zoom = 1.5;

		pendingBG = OptionsHelpers.colorArray(ClientPrefs.data.keyboardBGColor);
		pendingText = OptionsHelpers.colorArray(ClientPrefs.data.keyboardTextColor);

		previewKeyboard.setBGColor(pendingBG);
		previewKeyboard.setTextColor(pendingText);

		copyButton = new FlxSprite(760, 50).loadGraphic(Paths.image('noteColorMenu/copy'));
		copyButton.alpha = 0.6;
		add(copyButton);

		pasteButton = new FlxSprite(1180, 50).loadGraphic(Paths.image('noteColorMenu/paste'));
		pasteButton.alpha = 0.6;
		add(pasteButton);

		targetBGButton = new FlxSprite(760, 110).loadGraphic(Paths.image('noteColorMenu/bg'));
		targetBGButton.alpha = 0.6;
		targetBGButton.scale.x = targetBGButton.scale.y = 0.7;
		add(targetBGButton);

		targetTextButton = new FlxSprite(1180, 110).loadGraphic(Paths.image('noteColorMenu/text'));
		targetTextButton.alpha = 0.6;
		targetTextButton.scale.x = targetTextButton.scale.y = 0.7;
		add(targetTextButton);

		colorGradient = FlxGradient.createGradientFlxSprite(60, 360, [FlxColor.WHITE, FlxColor.BLACK]);
		colorGradient.setPosition(780, 200);
		add(colorGradient);

		colorGradientSelector = new FlxSprite(770, 200).makeGraphic(80, 10, FlxColor.WHITE);
		colorGradientSelector.offset.y = 5;
		add(colorGradientSelector);

		colorPalette = new FlxSprite(820, 580).loadGraphic(Paths.imageWithOriginalPixels('noteColorMenu/palette'));
		colorPalette.scale.set(20, 20);
		colorPalette.updateHitbox();
		colorPalette.antialiasing = false;
		add(colorPalette);

		colorWheel = new FlxSprite(860, 200).loadGraphic(Paths.image('noteColorMenu/colorWheel'));
		colorWheel.setGraphicSize(360, 360);
		colorWheel.updateHitbox();
		add(colorWheel);

		colorWheelSelector = new FlxShapeCircle(0, 0, 8, {thickness: 0}, FlxColor.WHITE);
		colorWheelSelector.offset.set(8, 8);
		colorWheelSelector.alpha = 0.6;
		add(colorWheelSelector);

		var txtX = 980;
		var txtY = 90 + 20;
		alphabetR = makeColorAlphabet(txtX - 100, txtY);
		add(alphabetR);
		alphabetG = makeColorAlphabet(txtX, txtY);
		add(alphabetG);
		alphabetB = makeColorAlphabet(txtX + 100, txtY);
		add(alphabetB);
		alphabetHex = makeColorAlphabet(txtX, txtY - 40);
		add(alphabetHex);
		hexTypeLine = new FlxSprite(0, txtY - 40).makeGraphic(5, 62, FlxColor.WHITE);
		hexTypeLine.visible = false;
		add(hexTypeLine);

		FlxG.sound.play(Paths.sound('scrollMenu'), 0.6);

		var tipX = 20;
		var tipY = 660;
		var tipText:String;

		if (controls.mobileC)
		{
			tipText = "Press C to Reset the selected color.";
			tipY = 0;
		}
		else
		{
			tipText = "Press RELOAD to Reset the selected color.";
		}

		var tip:FlxText = new FlxText(tipX, tipY, 0, tipText, 16);
		tip.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		tip.borderSize = 2;
		add(tip);

		tipTxt = new FlxText(tipX, tipY + 24, 0, '', 16);
		tipTxt.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		tipTxt.borderSize = 2;
		add(tipTxt);
		updateTip();

		controllerPointer = new FlxShapeCircle(0, 0, 20, {thickness: 0}, FlxColor.WHITE);
		controllerPointer.offset.set(20, 20);
		controllerPointer.screenCenter();
		controllerPointer.alpha = 0.6;
		add(controllerPointer);

		FlxG.mouse.visible = !ClientPrefs.data.needMobileControl && !controls.controllerMode;
		controllerPointer.visible = controls.controllerMode;
		_lastControllerMode = controls.controllerMode;

		AndroidColorGet = new FlxUIInputText(940, 20, 160, '', 30);
		AndroidColorGet.focusGained = () -> FlxG.stage.window.textInputEnabled = true;
		LengthCheck = AndroidColorGet.text;
		AndroidColorGet.backgroundColor = FlxColor.TRANSPARENT;
		AndroidColorGet.fieldBorderColor = FlxColor.TRANSPARENT;
		AndroidColorGet.font = Paths.font("vcr.ttf");
		AndroidColorGet.antialiasing = ClientPrefs.data.antialiasing;
		add(AndroidColorGet);

		underline_text_BG = new FlxSprite(940, 20 + 40).makeGraphic(160, 6, FlxColor.WHITE);
		underline_text_BG.alpha = 0.6;
		add(underline_text_BG);

		addVirtualPad(NONE, B_C);
		virtualPad.buttonC.x = 0;
		virtualPad.buttonC.y = FlxG.height - 135;
		virtualPad.buttonB.x = FlxG.width - virtualPad.buttonB.width;

		updateColors();
	}

	function updateTip()
	{
		if (controls.mobileC)
		{
		}
		else
		{
			var targetName:String = switch (colorTarget)
			{
				case 0: 'Background';
				case 1: 'Text';
				default: 'None';
			};
			tipTxt.text = 'Currently editing: ' + targetName + ' color.';
		}
	}

	var _storedColor:FlxColor;
	var holdingOnObj:FlxSprite;

	override function update(elapsed:Float)
	{
		LengthCheck = AndroidColorGet.text;

		if (controls.BACK)
		{
			if (AndroidColorGet.hasFocus)
			{

			}
			else
			{
				ClientPrefs.data.keyboardBGColor = pendingBG.toHexString(false, false);
				ClientPrefs.data.keyboardTextColor = pendingText.toHexString(false, false);
				FlxG.mouse.visible = !ClientPrefs.data.needMobileControl;
				FlxG.sound.play(Paths.sound('cancelMenu'));
				ClientPrefs.saveSettings();
				
				close();
				return;
			}
		}

		super.update(elapsed);

		if (FlxG.gamepads.anyJustPressed(ANY))
			controls.controllerMode = true;
		else if (FlxG.mouse.justPressed || FlxG.mouse.deltaScreenX != 0 || FlxG.mouse.deltaScreenY != 0)
			controls.controllerMode = false;

		var changedToController:Bool = false;
		if (controls.controllerMode != _lastControllerMode)
		{
			FlxG.mouse.visible = !ClientPrefs.data.needMobileControl && !controls.controllerMode;
			controllerPointer.visible = controls.controllerMode;

			if (controls.controllerMode)
			{
				controllerPointer.x = FlxG.mouse.x;
				controllerPointer.y = FlxG.mouse.y;
				changedToController = true;
			}
			_lastControllerMode = controls.controllerMode;
			updateTip();
		}

		var analogX:Float = 0;
		var analogY:Float = 0;
		var analogMoved:Bool = false;
		if (controls.controllerMode && (changedToController || FlxG.gamepads.anyInput()))
		{
			for (gamepad in FlxG.gamepads.getActiveGamepads())
			{
				analogX = gamepad.getXAxis(LEFT_ANALOG_STICK);
				analogY = gamepad.getYAxis(LEFT_ANALOG_STICK);
				analogMoved = (analogX != 0 || analogY != 0);
				if (analogMoved)
					break;
			}
			controllerPointer.x = Math.max(0, Math.min(FlxG.width, controllerPointer.x + analogX * 1000 * elapsed));
			controllerPointer.y = Math.max(0, Math.min(FlxG.height, controllerPointer.y + analogY * 1000 * elapsed));
		}
		var controllerPressed:Bool = (controls.controllerMode && controls.ACCEPT);

		if (LengthCheck.length == 6 && ColorCheck != LengthCheck)
		{
			ColorCheck = LengthCheck;

			var newColor:String = AndroidColorGet.text;

			var colorHex:FlxColor = FlxColor.fromString('#' + newColor);
			setShaderColor(colorHex);
			_storedColor = getShaderColor();
			updateColors();
		}

		if (hexTypeNum > -1)
		{
			var keyPressed:FlxKey = cast(FlxG.keys.firstJustPressed(), FlxKey);
			hexTypeVisibleTimer += elapsed;
			var changed:Bool = false;
			if (changed = FlxG.keys.justPressed.LEFT)
				hexTypeNum--;
			else if (changed = FlxG.keys.justPressed.RIGHT)
				hexTypeNum++;
			else if (FlxG.keys.justPressed.ENTER)
				hexTypeNum = -1;

			var end:Bool = false;
			if (changed)
			{
				if (hexTypeNum > 5)
				{
					hexTypeNum = -1;
					end = true;
					hexTypeLine.visible = false;
				}
				else
				{
					if (hexTypeNum < 0)
						hexTypeNum = 0;
					else if (hexTypeNum > 5)
						hexTypeNum = 5;
					centerHexTypeLine();
					hexTypeLine.visible = false;
				}
				FlxG.sound.play(Paths.sound('scrollMenu'), 0.6);
			}
			if (!end)
				hexTypeLine.visible = false;
		}
		else
		{
			hexTypeLine.visible = false;
		}

		var generalMoved:Bool = (FlxG.mouse.justMoved || analogMoved);
		var generalPressed:Bool = (FlxG.mouse.justPressed || controllerPressed);
		if (generalMoved)
		{
			copyButton.alpha = 0.6;
			pasteButton.alpha = 0.6;
			targetBGButton.alpha = 0.6;
			targetTextButton.alpha = 0.6;
		}

		if (pointerOverlaps(targetBGButton))
		{
			targetBGButton.alpha = 1;
			if (generalPressed)
			{
				colorTarget = 0;
				updateColors();
				updateTip();
				FlxG.sound.play(Paths.sound('scrollMenu'), 0.6);
			}
		}
		else if (pointerOverlaps(targetTextButton))
		{
			targetTextButton.alpha = 1;
			if (generalPressed)
			{
				colorTarget = 1;
				updateColors();
				updateTip();
				FlxG.sound.play(Paths.sound('scrollMenu'), 0.6);
			}
		}

		if (pointerOverlaps(copyButton))
		{
			copyButton.alpha = 1;
			if (generalPressed)
			{
				Clipboard.text = getShaderColor().toHexString(false, false);
				FlxG.sound.play(Paths.sound('scrollMenu'), 0.6);
				trace('copied: ' + Clipboard.text);
			}
			hexTypeNum = -1;
		}
		else if (pointerOverlaps(pasteButton))
		{
			pasteButton.alpha = 1;
			if (generalPressed)
			{
				var formattedText = Clipboard.text.trim().toUpperCase().replace('#', '').replace('0x', '');
				var newColor:Null<FlxColor> = FlxColor.fromString('#' + formattedText);
				if (newColor != null && formattedText.length == 6)
				{
					setShaderColor(newColor);
					FlxG.sound.play(Paths.sound('scrollMenu'), 0.6);
					_storedColor = getShaderColor();
					updateColors();
				}
				else
					FlxG.sound.play(Paths.sound('cancelMenu'), 0.6);
			}
			hexTypeNum = -1;
		}

		if (generalPressed)
		{
			hexTypeNum = -1;
			if (pointerOverlaps(colorWheel))
			{
				_storedColor = getShaderColor();
				holdingOnObj = colorWheel;
			}
			else if (pointerOverlaps(colorGradient))
			{
				_storedColor = getShaderColor();
				holdingOnObj = colorGradient;
			}
			else if (pointerOverlaps(colorPalette))
			{
				setShaderColor(colorPalette.pixels.getPixel32(Std.int((pointerX() - colorPalette.x) / colorPalette.scale.x),
					Std.int((pointerY() - colorPalette.y) / colorPalette.scale.y)));
				FlxG.sound.play(Paths.sound('scrollMenu'), 0.6);
				updateColors();
			}
			else if (pointerY() >= hexTypeLine.y && pointerY() < hexTypeLine.y + hexTypeLine.height && Math.abs(pointerX() - 1000) <= 84)
			{
				FlxG.stage.window.textInputEnabled = true;
				hexTypeNum = 0;
				for (letter in alphabetHex.letters)
				{
					if (letter.x - letter.offset.x + letter.width <= pointerX())
						hexTypeNum++;
					else
						break;
				}
				if (hexTypeNum > 5)
					hexTypeNum = 5;
				hexTypeLine.visible = true;
				centerHexTypeLine();
			}
			else
				holdingOnObj = null;
		}
		if (holdingOnObj != null)
		{
			if (FlxG.mouse.justReleased || (controls.controllerMode && controls.justReleased('accept')))
			{
				holdingOnObj = null;
				_storedColor = getShaderColor();
				updateColors();
				FlxG.sound.play(Paths.sound('scrollMenu'), 0.6);
			}
			else if (generalMoved || generalPressed)
			{
				if (holdingOnObj == colorGradient)
				{
					var newBrightness = 1 - FlxMath.bound((pointerY() - colorGradient.y) / colorGradient.height, 0, 1);
					_storedColor.alpha = 1;
					if (_storedColor.brightness == 0)
						setShaderColor(FlxColor.fromRGBFloat(newBrightness, newBrightness, newBrightness));
					else
						setShaderColor(FlxColor.fromHSB(_storedColor.hue, _storedColor.saturation, newBrightness));
					updateColors(_storedColor);
				}
				else if (holdingOnObj == colorWheel)
				{
					var center:FlxPoint = FlxPoint.weak(colorWheel.x + colorWheel.width / 2, colorWheel.y + colorWheel.height / 2);
					var mouse:FlxPoint = pointerFlxPoint();
					var hue:Float = FlxMath.wrap(FlxMath.wrap(Std.int(mouse.degreesTo(center)), 0, 360) - 90, 0, 360);
					var sat:Float = FlxMath.bound(mouse.dist(center) / colorWheel.width * 2, 0, 1);
					if (sat != 0)
						setShaderColor(FlxColor.fromHSB(hue, sat, _storedColor.brightness));
					else
						setShaderColor(FlxColor.fromRGBFloat(_storedColor.brightness, _storedColor.brightness, _storedColor.brightness));
					updateColors();
				}
			}
		}
		else if (virtualPad.buttonC.justPressed || controls.RESET && hexTypeNum < 0)
		{
			if (FlxG.keys.pressed.SHIFT || FlxG.gamepads.anyJustPressed(LEFT_SHOULDER))
			{
				pendingBG = FlxColor.WHITE;
				pendingText = FlxColor.BLACK;
				if (previewKeyboard != null)
				{
					previewKeyboard.setBGColor(pendingBG);
					previewKeyboard.setTextColor(pendingText);
				}
			}
			else
			{
				if (colorTarget == 0)
					setShaderColor(FlxColor.WHITE);
				else
					setShaderColor(FlxColor.BLACK);
			}
			FlxG.sound.play(Paths.sound('cancelMenu'), 0.6);
			updateColors();
		}
	}

	override function destroy()
	{
		if (camKey != null)
		{
			FlxG.cameras.remove(camKey);
			camKey = null;
		}
		super.destroy();
	}

	function pointerOverlaps(obj:Dynamic)
	{
		if (!controls.controllerMode)
			return FlxG.mouse.overlaps(obj);
		return FlxG.overlap(controllerPointer, obj);
	}

	function pointerX():Float
	{
		if (!controls.controllerMode)
			return FlxG.mouse.x;
		return controllerPointer.x;
	}

	function pointerY():Float
	{
		if (!controls.controllerMode)
			return FlxG.mouse.y;
		return controllerPointer.y;
	}

	function pointerFlxPoint():FlxPoint
	{
		if (!controls.controllerMode)
			return FlxG.mouse.getScreenPosition();
		return controllerPointer.getScreenPosition();
	}

	function centerHexTypeLine()
	{
		if (hexTypeNum > 0)
		{
			var letter = alphabetHex.letters[hexTypeNum - 1];
			hexTypeLine.x = letter.x - letter.offset.x + letter.width;
		}
		else
		{
			var letter = alphabetHex.letters[0];
			hexTypeLine.x = letter.x - letter.offset.x;
		}
		hexTypeLine.x += hexTypeLine.width;
		hexTypeVisibleTimer = 0;
	}

	function makeColorAlphabet(x:Float = 0, y:Float = 0):Alphabet
	{
		var text:Alphabet = new Alphabet(x, y, '', true);
		text.alignment = CENTERED;
		text.setScale(0.6);
		add(text);
		return text;
	}

	function updateColors(specific:Null<FlxColor> = null)
	{
		var color:FlxColor = getShaderColor();
		var wheelColor:FlxColor = specific == null ? getShaderColor() : specific;
		alphabetR.text = Std.string(color.red);
		alphabetG.text = Std.string(color.green);
		alphabetB.text = Std.string(color.blue);
		alphabetHex.text = color.toHexString(false, false);
		for (letter in alphabetHex.letters)
			letter.color = color;

		colorWheel.color = FlxColor.fromHSB(0, 0, color.brightness);
		colorWheelSelector.setPosition(colorWheel.x + colorWheel.width / 2, colorWheel.y + colorWheel.height / 2);
		if (wheelColor.brightness != 0)
		{
			var hueWrap:Float = wheelColor.hue * Math.PI / 180;
			colorWheelSelector.x += Math.sin(hueWrap) * colorWheel.width / 2 * wheelColor.saturation;
			colorWheelSelector.y -= Math.cos(hueWrap) * colorWheel.height / 2 * wheelColor.saturation;
		}
		colorGradientSelector.y = colorGradient.y + colorGradient.height * (1 - color.brightness);
	}

	function setShaderColor(value:FlxColor)
	{
		lastColor = value;

		if (colorTarget == 0)
		{
			pendingBG = value;
			if (previewKeyboard != null)
				previewKeyboard.setBGColor(value);
		}
		else
		{
			pendingText = value;
			if (previewKeyboard != null)
				previewKeyboard.setTextColor(value);
		}
	}

	function getShaderColor():FlxColor
	{
		return colorTarget == 0 ? pendingBG : pendingText;
	}
}
