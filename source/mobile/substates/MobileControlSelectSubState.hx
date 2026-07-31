package mobile.substates;

import openfl.sensors.Accelerometer;
import openfl.utils.Assets;
import openfl.Lib;

import flixel.util.FlxSave;
import flixel.input.touch.FlxTouch;
import flixel.ui.FlxButton as UIButton;
import flixel.FlxCamera;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxAtlasFrames;

import mobile.flixel.FlxButton;

class MobileControlSelectSubState extends MusicBeatSubstate
{
	public var controlsItems:Array<String> = ['Pad-Right', 'Pad-Left', 'Pad-Custom', 'Pad-Duo', 'Hitbox', 'Keyboard'];

	var initialSelection:Null<Int>;
	var saveSelection:String->Array<Array<Float>>->Void;
	var closeSelection:Void->Void;
	var externalCustomPositions:Array<Array<Float>>;
	var usesExternalPreferences:Bool = false;
	var camControls:FlxCamera;
	var virtualPadd:FlxVirtualPad;
	var hitbox:FlxHitbox;
	var upPozition:FlxText;
	var downPozition:FlxText;
	var leftPozition:FlxText;
	var rightPozition:FlxText;
	var extra1Pozition:FlxText;
	var extra2Pozition:FlxText;
	var extra3Pozition:FlxText;
	var extra4Pozition:FlxText;
	var inputvari:FlxText;
	var funitext:FlxText;
	var leftArrow:FlxSprite;
	var rightArrow:FlxSprite;
	var curSelected:Int = 0;
	var buttonBinded:Bool = false;
	var bindButton:FlxButton;
	var resetButton:UIButton;
	var daFunny:FlxText;
	var buttonLeftColor:Array<FlxColor>;
	var buttonDownColor:Array<FlxColor>;
	var buttonUpColor:Array<FlxColor>;
	var buttonRightColor:Array<FlxColor>;

	public function new(?items:Array<String>, ?selected:Int, ?onSave:String->Array<Array<Float>>->Void, ?onClose:Void->Void,
			?customPositions:Array<Array<Float>>)
	{
		super();

		if (items != null && items.length > 0)
			controlsItems = items.copy();

		initialSelection = selected;
		saveSelection = onSave;
		closeSelection = onClose;
		externalCustomPositions = customPositions;
		usesExternalPreferences = onSave != null;
	}

	override function create()
	{
		if (ClientPrefs.data.dynamicColors)
		{
			buttonLeftColor = ClientPrefs.data.arrowRGB[0];
			buttonDownColor = ClientPrefs.data.arrowRGB[1];
			buttonUpColor = ClientPrefs.data.arrowRGB[2];
			buttonRightColor = ClientPrefs.data.arrowRGB[3];
		}
		else
		{
			buttonLeftColor = ClientPrefs.defaultData.arrowRGB[0];
			buttonDownColor = ClientPrefs.defaultData.arrowRGB[1];
			buttonUpColor = ClientPrefs.defaultData.arrowRGB[2];
			buttonRightColor = ClientPrefs.defaultData.arrowRGB[3];
		}

		curSelected = initialSelection != null ? initialSelection : MobileControls.get_mode();
		if (curSelected < 0 || curSelected >= controlsItems.length)
			curSelected = 0;

		var bg:FlxSprite = new FlxSprite(0, 0).makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		bg.scrollFactor.set();
		bg.alpha = 0;
		add(bg);

		var newWidth:Int;
		var newHeight:Int;

		if (ClientPrefs.data.useFlixelCoords)
		{
			newWidth = Std.int(FlxG.width);
			newHeight = Std.int(FlxG.height);
		}
		else
		{
			var stage = Lib.current.stage;
			var scale:Float = Math.min((stage.stageWidth / FlxG.width), (stage.stageHeight / FlxG.height));
			newWidth = Std.int(stage.stageWidth / scale);
			newHeight = Std.int(stage.stageHeight / scale);
		}

		camControls = new FlxCamera(0, 0, newWidth, newHeight);
		camControls.x = (FlxG.width - newWidth) / 2;
		camControls.y = (FlxG.height - newHeight) / 2;
		camControls.bgColor.alpha = 0;
		FlxG.cameras.add(camControls, false);

		var exit = new UIButton(FlxG.width - 300, 50, "Exit & Save", () ->
		{
			final choice:String = controlsItems[Math.floor(curSelected)];

			if (saveSelection != null)
			{
				saveSelection(choice, getCustomPositions());
			}
			else
			{
				MobileControls.set_mode(curSelected);

				if (choice == 'Pad-Custom')
					MobileControls.setCustomMode(virtualPadd);

				if (virtualPadd.visible == true)
					MobileControls.setExtraCustomMode(virtualPadd);
			}

			FlxG.sound.play(Paths.sound('cancelMenu'));
			if (closeSelection != null)
			{
				closeSelection();
			}
			else
			{
				FlxTransitionableState.skipNextTransIn = true;
				FlxTransitionableState.skipNextTransOut = true;
				MusicBeatState.switchState(new options.OptionsState());
			}
		});
		exit.color = FlxColor.LIME;
		exit.setGraphicSize(Std.int(exit.width) * 3);
		exit.updateHitbox();
		exit.label.setFormat(Paths.font('vcr.ttf'), 28, FlxColor.WHITE, FlxTextAlign.CENTER);
		exit.label.fieldWidth = exit.width;
		exit.label.x = ((exit.width - exit.label.width) / 2) + exit.x;
		exit.label.offset.y = -10; // WHY THE FUCK I CAN'T CHANGE THE LABEL Y
		add(exit);

		resetButton = new UIButton(exit.x, exit.height + exit.y + 20, "Reset", () ->
		{
			if (resetButton.visible)
			{
				var daChoice:String = controlsItems[Math.floor(curSelected)];
				if (daChoice == 'Pad-Custom')
				{
					virtualPadd.buttonUp.x = FlxG.width - 258;
					virtualPadd.buttonUp.y = FlxG.height - 408;
					virtualPadd.buttonDown.x = FlxG.width - 258;
					virtualPadd.buttonDown.y = FlxG.height - 201;
					virtualPadd.buttonRight.x = FlxG.width - 132;
					virtualPadd.buttonRight.y = FlxG.height - 309;
					virtualPadd.buttonLeft.x = FlxG.width - 384;
					virtualPadd.buttonLeft.y = FlxG.height - 309;
				}
				else
				{
				}

				if (virtualPadd.extraKeys.length >= 4)
				{
					var BTN:Int = 130;
					var ratio:Float = 1.01;
					for (i in 0...virtualPadd.extraKeys.length)
					{
						virtualPadd.extraKeys[i].x = FlxG.width - (BTN * (1 + i) * ratio);
						virtualPadd.extraKeys[i].y = FlxG.height - (BTN * 4 * ratio);
					}
				}
			}
		});
		resetButton.color = FlxColor.RED;
		resetButton.setGraphicSize(Std.int(resetButton.width) * 3);
		resetButton.updateHitbox();
		resetButton.label.setFormat(Paths.font('vcr.ttf'), 28, FlxColor.WHITE, FlxTextAlign.CENTER);
		resetButton.label.fieldWidth = resetButton.width;
		resetButton.label.x = ((resetButton.width - resetButton.label.width) / 2) + resetButton.x;
		resetButton.label.offset.y = -10;
		add(resetButton);

		virtualPadd = new FlxVirtualPad(NONE, NONE);
		virtualPadd.visible = false;
		virtualPadd.cameras = [camControls];
		add(virtualPadd);

		hitbox = new FlxHitbox();

		hitbox.alpha = 0.6;
		hitbox.visible = false;
		hitbox.cameras = [camControls];
		add(hitbox);

		funitext = new FlxText(0, 50, 0, 'No Mobile Controls!', 32);
		funitext.setFormat('VCR OSD Mono', 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		funitext.borderSize = 2.4;
		funitext.screenCenter();
		funitext.visible = false;
		add(funitext);

		inputvari = new FlxText(0, 100, 0, '', 32);
		inputvari.setFormat('VCR OSD Mono', 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		inputvari.borderSize = 2.4;
		inputvari.screenCenter(X);
		add(inputvari);

		leftArrow = new FlxSprite(inputvari.x - 60, inputvari.y - 25);
		leftArrow.frames = getCampaignMenuFrames();
		leftArrow.animation.addByPrefix('idle', 'arrow left');
		leftArrow.animation.addByPrefix('press', "arrow push left");
		leftArrow.animation.play('idle');
		add(leftArrow);

		rightArrow = new FlxSprite(inputvari.x + inputvari.width + 10, inputvari.y - 25);
		rightArrow.frames = getCampaignMenuFrames();
		rightArrow.animation.addByPrefix('idle', 'arrow right');
		rightArrow.animation.addByPrefix('press', "arrow push right", 24, false);
		rightArrow.animation.play('idle');
		add(rightArrow);

		rightPozition = new FlxText(10, FlxG.height - 44, 0, '', 16);
		rightPozition.setFormat('VCR OSD Mono', 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		rightPozition.borderSize = 2.4;
		add(rightPozition);

		leftPozition = new FlxText(10, FlxG.height - 64, 0, '', 16);
		leftPozition.setFormat('VCR OSD Mono', 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		leftPozition.borderSize = 2.4;
		add(leftPozition);

		downPozition = new FlxText(10, FlxG.height - 84, 0, '', 16);
		downPozition.setFormat('VCR OSD Mono', 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		downPozition.borderSize = 2.4;
		add(downPozition);

		upPozition = new FlxText(10, FlxG.height - 104, 0, '', 16);
		upPozition.setFormat('VCR OSD Mono', 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		upPozition.borderSize = 2.4;
		add(upPozition);

		extra1Pozition = new FlxText(10, FlxG.height - 124, 0, '', 16);
		extra1Pozition.setFormat('VCR OSD Mono', 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		extra1Pozition.borderSize = 2.4;
		add(extra1Pozition);

		extra2Pozition = new FlxText(10, FlxG.height - 144, 0, '', 16);
		extra2Pozition.setFormat('VCR OSD Mono', 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		extra2Pozition.borderSize = 2.4;
		add(extra2Pozition);

		extra3Pozition = new FlxText(10, FlxG.height - 164, 0, '', 16);
		extra3Pozition.setFormat('VCR OSD Mono', 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		extra3Pozition.borderSize = 2.4;
		add(extra3Pozition);

		extra4Pozition = new FlxText(10, FlxG.height - 184, 0, '', 16);
		extra4Pozition.setFormat('VCR OSD Mono', 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		extra4Pozition.borderSize = 2.4;
		add(extra4Pozition);

		daFunny = new FlxText(0, 75, 0, 'Pad-Extras is not a control mode\nPlease selecte a valid mode such as hitbox, Pad-Left...', 35);
		daFunny.setFormat('VCR OSD Mono', 35, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		daFunny.screenCenter();
		daFunny.borderSize = 2.4;
		add(daFunny);
		daFunny.alpha = 0;

		changeSelection();

		super.create();

		FlxTween.tween(bg, {alpha: 0.5}, 0.5, {ease: FlxEase.circInOut});
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		inputvari.screenCenter(X);
		leftArrow.x = inputvari.x - 60;
		rightArrow.x = inputvari.x + inputvari.width + 10;

		var mouse = FlxG.mouse;

		if (mouse.overlaps(leftArrow) && mouse.pressed)
			leftArrow.animation.play('press');
		else
			leftArrow.animation.play('idle');

		if (mouse.overlaps(rightArrow) && mouse.pressed)
			rightArrow.animation.play('press')
		else
			rightArrow.animation.play('idle');

		if (mouse.overlaps(leftArrow) && mouse.justPressed)
			changeSelection(-1);
		else if (mouse.overlaps(rightArrow) && mouse.justPressed)
			changeSelection(1);

		for (touch in FlxG.touches.list)
		{
			

			if (controlsItems[Math.floor(curSelected)] == 'Pad-Custom')
			{
				if (buttonBinded)
				{
					if (touch.justReleased)
					{
						bindButton = null;
						buttonBinded = false;
					}
					else
						moveButton(touch, bindButton);
				}
				else
				{
					if (virtualPadd.buttonUp.justPressed)
						moveButton(touch, virtualPadd.buttonUp);

					if (virtualPadd.buttonDown.justPressed)
						moveButton(touch, virtualPadd.buttonDown);

					if (virtualPadd.buttonRight.justPressed)
						moveButton(touch, virtualPadd.buttonRight);

					if (virtualPadd.buttonLeft.justPressed)
						moveButton(touch, virtualPadd.buttonLeft);
				}
			}
			if (controlsItems[Math.floor(curSelected)] != 'Hitbox')
			{
				if (buttonBinded)
				{
					if (touch.justReleased)
					{
						bindButton = null;
						buttonBinded = false;
					}
					else
						moveButton(touch, bindButton);
				}
			}

			if (virtualPadd.visible == true)
			{
				if (buttonBinded)
				{
					if (touch.justReleased)
					{
						bindButton = null;
						buttonBinded = false;
					}
					else
						moveButton(touch, bindButton);
				}
				else
				{
					for (ek in virtualPadd.extraKeys)
					{
						if (ek != null && ek.justPressed)
							moveButton(touch, ek);
					}
				}
			}
		}

		if (virtualPadd.visible == true)
		{
			if (virtualPadd.buttonUp != null)
				upPozition.text = 'Button Up X:' + virtualPadd.buttonUp.x + ' Y:' + virtualPadd.buttonUp.y;

			if (virtualPadd.buttonDown != null)
				downPozition.text = 'Button Down X:' + virtualPadd.buttonDown.x + ' Y:' + virtualPadd.buttonDown.y;

			if (virtualPadd.buttonLeft != null)
				leftPozition.text = 'Button Left X:' + virtualPadd.buttonLeft.x + ' Y:' + virtualPadd.buttonLeft.y;

			if (virtualPadd.buttonRight != null)
				rightPozition.text = 'Button Right X:' + virtualPadd.buttonRight.x + ' Y:' + virtualPadd.buttonRight.y;

			for (i in 0...virtualPadd.extraKeys.length)
			{
				var ek = virtualPadd.extraKeys[i];
				if (ek != null)
				{
					switch (i)
					{
						case 0: extra1Pozition.text = 'Extra 1 X:' + ek.x + ' Y:' + ek.y;
						case 1: extra2Pozition.text = 'Extra 2 X:' + ek.x + ' Y:' + ek.y;
						case 2: extra3Pozition.text = 'Extra 3 X:' + ek.x + ' Y:' + ek.y;
						case 3: extra4Pozition.text = 'Extra 4 X:' + ek.x + ' Y:' + ek.y;
					}
				}
			}
		}
	}

	function destroyVirtualPad():Void
	{
		if (virtualPadd == null)
			return;

		// A destroyed FlxTypedSpriteGroup must not remain in this SubState's
		// members, otherwise FlxState.update() will visit it on the next frame.
		remove(virtualPadd, true);
		virtualPadd.destroy();
		virtualPadd = null;
	}

	function changeSelection(change:Int = 0):Void
	{
		if (usesExternalPreferences && change != 0 && controlsItems[Math.floor(curSelected)] == 'Pad-Custom')
			externalCustomPositions = getCustomPositions();

		if (!usesExternalPreferences && change != 0 && virtualPadd.visible == true)
			MobileControls.setExtraCustomMode(virtualPadd);

		curSelected += change;

		buttonBinded = false;

		if (curSelected < 0)
			curSelected = controlsItems.length - 1;
		if (curSelected >= controlsItems.length)
			curSelected = 0;

		inputvari.text = controlsItems[curSelected];

		var daChoice:String = controlsItems[Math.floor(curSelected)];

		switch (daChoice)
		{
			case 'Pad-Right':
				hitbox.visible = false;

				destroyVirtualPad();
				virtualPadd = new FlxVirtualPad(RIGHT_FULL, controlExtend);
				if (!usesExternalPreferences)
					virtualPadd = MobileControls.getExtraCustomMode(virtualPadd);
				virtualPadd.alpha = ClientPrefs.data.playControlsAlpha;
				virtualPadd.cameras = [camControls];
				add(virtualPadd);
				virtualPadd.buttonLeft.color = buttonLeftColor[0];
				virtualPadd.buttonDown.color = buttonDownColor[0];
				virtualPadd.buttonUp.color = buttonUpColor[0];
				virtualPadd.buttonRight.color = buttonRightColor[0];
			case 'Pad-Left':
				hitbox.visible = false;

				destroyVirtualPad();
				virtualPadd = new FlxVirtualPad(LEFT_FULL, controlExtend);
				if (!usesExternalPreferences)
					virtualPadd = MobileControls.getExtraCustomMode(virtualPadd);
				virtualPadd.alpha = ClientPrefs.data.playControlsAlpha;
				virtualPadd.cameras = [camControls];
				add(virtualPadd);
				virtualPadd.buttonLeft.color = buttonLeftColor[0];
				virtualPadd.buttonDown.color = buttonDownColor[0];
				virtualPadd.buttonUp.color = buttonUpColor[0];
				virtualPadd.buttonRight.color = buttonRightColor[0];
			case 'Pad-Custom':
				hitbox.visible = false;

				destroyVirtualPad();
				virtualPadd = new FlxVirtualPad(RIGHT_FULL, controlExtend);
				if (usesExternalPreferences)
					applyCustomPositions(virtualPadd);
				else
				{
					virtualPadd = MobileControls.getCustomMode(virtualPadd);
					virtualPadd = MobileControls.getExtraCustomMode(virtualPadd);
				}
				virtualPadd.alpha = ClientPrefs.data.playControlsAlpha;
				virtualPadd.cameras = [camControls];
				add(virtualPadd);
				virtualPadd.buttonLeft.color = buttonLeftColor[0];
				virtualPadd.buttonDown.color = buttonDownColor[0];
				virtualPadd.buttonUp.color = buttonUpColor[0];
				virtualPadd.buttonRight.color = buttonRightColor[0];
			case 'Pad-Duo':
				hitbox.visible = false;

				destroyVirtualPad();
				virtualPadd = new FlxVirtualPad(BOTH, controlExtend);
				if (!usesExternalPreferences)
					virtualPadd = MobileControls.getExtraCustomMode(virtualPadd);
				virtualPadd.alpha = ClientPrefs.data.playControlsAlpha;
				virtualPadd.cameras = [camControls];
				add(virtualPadd);
				virtualPadd.buttonLeft.color = buttonLeftColor[0];
				virtualPadd.buttonDown.color = buttonDownColor[0];
				virtualPadd.buttonUp.color = buttonUpColor[0];
				virtualPadd.buttonRight.color = buttonRightColor[0];
				virtualPadd.buttonLeft2.color = buttonLeftColor[0];
				virtualPadd.buttonDown2.color = buttonDownColor[0];
				virtualPadd.buttonUp2.color = buttonUpColor[0];
				virtualPadd.buttonRight2.color = buttonRightColor[0];

			case 'Hitbox':
				hitbox.visible = true;
				virtualPadd.visible = false;
				hitbox.alpha = ClientPrefs.data.playControlsAlpha;
				hitbox.cameras = [camControls];

			case 'Keyboard':
				hitbox.visible = false;
				virtualPadd.visible = false;

			case 'Origin':
				hitbox.visible = false;

				destroyVirtualPad();
				virtualPadd = new FlxVirtualPad(RIGHT_FULL, controlExtend);
				virtualPadd.alpha = ClientPrefs.data.playControlsAlpha;
				virtualPadd.cameras = [camControls];
				add(virtualPadd);

				final buttonWidth:Float = virtualPadd.buttonLeft.width;
				final spacing:Float = 16;
				final startX:Float = (FlxG.width - buttonWidth * 4 - spacing * 3) * 0.5;
				final buttonY:Float = FlxG.height - virtualPadd.buttonLeft.height - 24;
				virtualPadd.buttonLeft.setPosition(startX, buttonY);
				virtualPadd.buttonDown.setPosition(startX + (buttonWidth + spacing), buttonY);
				virtualPadd.buttonUp.setPosition(startX + (buttonWidth + spacing) * 2, buttonY);
				virtualPadd.buttonRight.setPosition(startX + (buttonWidth + spacing) * 3, buttonY);
				virtualPadd.buttonLeft.color = buttonLeftColor[0];
				virtualPadd.buttonDown.color = buttonDownColor[0];
				virtualPadd.buttonUp.color = buttonUpColor[0];
				virtualPadd.buttonRight.color = buttonRightColor[0];
		}

		funitext.visible = daChoice == 'Keyboard';
		if (daChoice != 'Keyboard' || daChoice != 'Hitbox')
			resetButton.visible = true;
		else
			resetButton.visible = false;

		upPozition.visible = daChoice == 'Pad-Custom';
		downPozition.visible = daChoice == 'Pad-Custom';
		leftPozition.visible = daChoice == 'Pad-Custom';
		rightPozition.visible = daChoice == 'Pad-Custom';

		var showExtras:Bool = daChoice != 'Keyboard' && daChoice != 'Hitbox';
		extra1Pozition.visible = showExtras;
		extra2Pozition.visible = showExtras;
		extra3Pozition.visible = showExtras;
		extra4Pozition.visible = showExtras;
	}

	function applyCustomPositions(pad:FlxVirtualPad):Void
	{
		if (externalCustomPositions == null || externalCustomPositions.length < 4)
			return;

		final buttons:Array<FlxButton> = [pad.buttonLeft, pad.buttonDown, pad.buttonUp, pad.buttonRight];
		for (i in 0...buttons.length)
		{
			final position = externalCustomPositions[i];
			if (position != null && position.length >= 2)
				buttons[i].setPosition(position[0], position[1]);
		}
	}

	function getCustomPositions():Array<Array<Float>>
	{
		if (virtualPadd == null || controlsItems[Math.floor(curSelected)] != 'Pad-Custom')
			return externalCustomPositions == null ? [] : externalCustomPositions.copy();

		return [
			[virtualPadd.buttonLeft.x, virtualPadd.buttonLeft.y],
			[virtualPadd.buttonDown.x, virtualPadd.buttonDown.y],
			[virtualPadd.buttonUp.x, virtualPadd.buttonUp.y],
			[virtualPadd.buttonRight.x, virtualPadd.buttonRight.y]
		];
	}

	function getCampaignMenuFrames():FlxAtlasFrames
	{
		#if sys
		if (originfunkin.OriginFunkinMode.active)
		{
			final imagePath:String = haxe.io.Path.join([Sys.getCwd(), 'assets/shared/images/campaign_menu_UI_assets.png']);
			final atlasPath:String = haxe.io.Path.join([Sys.getCwd(), 'assets/shared/images/campaign_menu_UI_assets.xml']);
			if (FileSystem.exists(imagePath) && FileSystem.exists(atlasPath))
			{
				final graphic = FlxGraphic.fromBitmapData(openfl.display.BitmapData.fromFile(imagePath), false, imagePath);
				return FlxAtlasFrames.fromSparrow(graphic, File.getContent(atlasPath));
			}
		}
		#end

		return Paths.getSparrowAtlas('campaign_menu_UI_assets');
	}

	function moveButton(touch:FlxTouch, button:FlxButton):Void
	{
		bindButton = button;
		bindButton.x = touch.x - camControls.x - Std.int(bindButton.width / 2);
		bindButton.y = touch.y - camControls.y - Std.int(bindButton.height / 2);
		buttonBinded = true;
	}

	override function destroy()
	{
		super.destroy();

		if (camControls != null)
		{
			FlxG.cameras.remove(camControls, false);
			camControls.destroy();
			camControls = null;
		}
	}
}
