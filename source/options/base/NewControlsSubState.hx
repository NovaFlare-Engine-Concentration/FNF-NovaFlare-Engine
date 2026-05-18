package options.base;

import flixel.addons.display.FlxBackdrop;
import flixel.addons.display.FlxGridOverlay;
import flixel.input.keyboard.FlxKey;
import flixel.util.FlxSpriteUtil;

import general.backend.InputFormatter;

import general.objects.AttachedSprite;

import options.objects.controlsSubState.*;

class NewControlsSubState extends MusicBeatSubstate
{
	public var allowFade:Bool = false;

	public static var allowControlsMode:Bool = false; // 启用设置按键模式
	public static var updateNoteModeBool:Bool = false; // 开始设置按键
	public static var keybootBool:Bool = true; // 是否键盘控制 按键设置时会自动关闭

	// 键盘操控

	public static var curSelected:Int = 0;
	public static var buttonSelected:Int = 0; // 0 - 3
	public static var buttonAltBool:Bool = false;

	public static var instance:NewControlsSubState;

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
		[false, 'WINDOW'],
		[false, 'Fullscreen', 'fullscreen', 'Fullscreen Toggel']
	];

    public var optionsButtonArray:Array<ControlsSprite> = [];

    public var camControls:FlxCamera;
	public var camHUD:FlxCamera;

    var bg:FlxSprite;
    private var background:FlxSprite;

	public var buttonMouseMove:MouseMove;

    private static var position:Float = 100 - 30;
	private static var lerpPosition:Float = 100 - 30;

    public static var optionText:FlxText;
	public static var optionTextStrStatic:String = "";

	public static var setOptionText:FlxText;

	var optionTextStr:String = "";

    public function new()
    {
        super();

		instance = this;

        //camGame = initPsychCamera();

        #if DISCORD_ALLOWED
        DiscordClient.changePresence("Controls Menu", null);
        #end

		camControls = new FlxCamera(0, 130, 1200, 500);
		camHUD = new FlxCamera();

		camControls.bgColor.alpha = 0;
		camHUD.bgColor.alpha = 0;

		FlxG.cameras.add(camControls, false);
		FlxG.cameras.add(camHUD, false);

        var bg:FlxSprite = new FlxSprite(0, 0).makeGraphic(1, 1, FlxColor.BLACK);
		bg.scale.set(FlxG.width, FlxG.height);
		bg.screenCenter();
		bg.scrollFactor.set();
		bg.alpha = 0;
		add(bg);

        background = new ControlsSprite(0, 0, 1025, 600, 16);
        background.screenCenter();
        add(background);

        optionText = new FlxText(background.x, background.y, 600, optionTextStrStatic);
        optionText.setFormat(Paths.font(Language.get('fontName', 'main') + '.ttf'), 25, FlxColor.BLACK, "center");
        add(optionText);
		optionText.antialiasing = true;
		optionText.screenCenter(X);

		setOptionText = new FlxText(0, 0, 1000, "");
        setOptionText.setFormat((Language.get('fontName', 'main') + '.ttf'), 51, FlxColor.WHITE, "left");
		setOptionText.scale.x = 0.3;
		setOptionText.antialiasing = true;
		add(setOptionText);

		setOptionText.scale.y = 0;
		setOptionText.text = returnText("111");
		setOptionText.updateHitbox();

		setOptionText.cameras = [camControls];

        var opn = options;

        for (i in 0...opn.length+1)
        {
            var xpos:Float;
            var ypos:Float;

			xpos = 0;
			ypos = background.y + 20 + (i * 55);

			if (i != opn.length) {
				if (opn[i][1] != null && opn[i][2] == null)
				{
					createOnOptionsText(opn[i][1], xpos, ypos + 20);
					optionTextStr = opn[i][1];
				}
				else if (opn[i][1] != null && opn[i][2] != null)
				{
					var array:Array<String> = [];

					for (j in 0...opn[i].length)
					{
						if (j == 0) continue;
						array.push(opn[i][j]);
					}

					createOptionsButton(opn[i][1], xpos, ypos, array);
				}
			}
			else {
				createOptionsResetButton("Reset to Default", xpos, ypos);
			}
        }

		songsRectPosUpdate(true);

		var intmove:Int = 500;

		background.y += intmove;
		camControls.y += intmove;
		optionText.y += intmove;

		FlxTween.tween(background, {y: background.y - intmove}, 0.5, {ease: FlxEase.circInOut});
		FlxTween.tween(camControls, {y: camControls.y - intmove}, 0.5, {ease: FlxEase.circInOut});
		FlxTween.tween(optionText, {y: optionText.y - intmove}, 0.5, {ease: FlxEase.circInOut});

		FlxTween.tween(bg, {alpha: 0.5}, 0.5, {ease: FlxEase.circInOut,
		onComplete: function(twn:FlxTween)
		{
			allowFade = true;
		}});

		buttonMouseMove = new MouseMove(NewControlsSubState, 'position',
					[FlxG.height + 20 - 71 * optionsButtonArray.length, -70],
					[
						[0, FlxG.width],
						[0, FlxG.height]
					]);
		buttonMouseMove.tweenTime = 0.4;
		add(buttonMouseMove);
    }

	public var curOption:Array<String> = [];
	public var curAlt:Int;
	var holdingEsc:Float = 0;

	public var doneBool:Bool = false;

    override function update(elapsed:Float):Void
    {
		if (!updateNoteModeBool) {
			/*if (position > -70)
				position = FlxMath.lerp(-70, position, Math.exp(-elapsed * 15));
			if (position < FlxG.height + 20 - 71 * optionsButtonArray.length)
				position = FlxMath.lerp(FlxG.height + 20 - 71 * optionsButtonArray.length, position, Math.exp(-elapsed * 15));

			if (Math.abs(lerpPosition - position) < 1)
				lerpPosition = position;
			else
				lerpPosition = FlxMath.lerp(position, lerpPosition, Math.exp(-elapsed * 15));*/

			if (allowFade) {
				if (controls.BACK)
				{
					//FlxTween.tween(bg, {alpha: 0}, 0.35, {ease: FlxEase.linear});

					close();
				}
				else if (!FlxG.mouse.overlaps(background) && FlxG.mouse.justPressed)
				{
					close();
				}
			}

			songsRectPosUpdate(true, elapsed);
		}
		else {
			if (updateNoteModeBool)
			{
				updateBind(elapsed);
			}
			else {
				if (controls.BACK)
				{
					backAllowControlsMode();
				}
			}

			songsRectPosUpdate(true, elapsed);
		}

		if (!updateNoteModeBool) {
			position += FlxG.mouse.wheel * 70;
			position += moveData;
			lerpPosition = position;

			// 键盘操控

			if (!buttonAltBool) {
				if (controls.UI_DOWN_P)
				{
					selSected(1);
				}
				else if (controls.UI_UP_P)
				{
					selSected(-1);
				}
			}
			if (controls.ACCEPT)
			{
				if (!optionsButtonArray[curSelected].scaleBool && optionsButtonArray[curSelected].optionUpdateBool)
				{
					selectNote();
				}
			}

			if (optionsButtonArray[curSelected].scaleBool && optionsButtonArray[curSelected].optionUpdateBool)
			{
				if (controls.UI_LEFT_P)
				{
					selsetButton(-1, 0);
				}
				else if (controls.UI_RIGHT_P)
				{
					selsetButton(1, 0);
				}
				else if (controls.UI_DOWN_P)
				{
					selsetButton(-1, 1);
				}
				else if (controls.UI_UP_P)
				{
					selsetButton(1, 1);
				}
			}

			for (i in 0...optionsButtonArray.length)
			{
				if (FlxG.mouse.overlaps(optionsButtonArray[i]))
				{
					position += avgSpeed * 1.5 * (0.0166 / elapsed) * Math.pow(1.1, Math.abs(avgSpeed * 0.8));
				}

				if (optionsButtonArray[i].optionUpdateBool)
				{
					var background = optionsButtonArray[i].background;

					if (allowFade && CoolUtil.mouseOverlaps(optionsButtonArray[i], camControls) && curSelected != i) {
						curSelected = i;

						//trace("curSelected:" + curSelected);
					}

					if (curSelected == i)
					{
						if (background.alpha != 1)
							background.alpha = 1;
					}
					else {
						if (background.alpha != 0.8)
							background.alpha = 0.8;
					}
				}

				if (allowFade && CoolUtil.mouseOverlaps(optionsButtonArray[i], camControls) && optionsButtonArray[i].optionUpdateBool)
				{
					optionsButtonArray[i].updateOptionText();

					//trace("overlaps:" + i);

					if (FlxG.mouse.justPressed) {
						if (buttonNpos == 0 && !optionsButtonArray[buttonNpos].scaleBool || buttonNpos != 0 && !optionsButtonArray[buttonNpos-1].scaleBool || buttonNpos != 0 && i != buttonNpos-1)
						{
							selectNote();
						}
					}
				}
				else {
					
				}
			}
		}

        super.update(elapsed);
    }

	function updateBind(elapsed:Float) // 按下更改按键按钮后界面update  # 手机和手柄端兼容基本没写。 -- chh
	{
		if (FlxG.keys.pressed.ESCAPE)
		{
			holdingEsc += elapsed;
			if (holdingEsc > 0.5)
			{
				FlxG.sound.play(Paths.sound('cancelMenu'));
				
				closeBinding();
			}
		}
		else if (FlxG.keys.pressed.BACKSPACE)
		{
			holdingEsc += elapsed;
			if (holdingEsc > 0.5)
			{
				ClientPrefs.keyBinds.get(curOption[1])[curAlt] = NONE;
			ClientPrefs.clearInvalidKeys(curOption[1]);
			updateCSNote(InputFormatter.getKeyName(NONE));
			FlxG.sound.play(Paths.sound('cancelMenu'));
			closeBinding();
			}
		}
		else
		{
			holdingEsc = 0;
			var changed:Bool = false;
			var curKeys:Array<FlxKey> = ClientPrefs.keyBinds.get(curOption[1]);

			if (FlxG.keys.justPressed.ANY || FlxG.keys.justReleased.ANY)
			{
				var keyPressed:Int = FlxG.keys.firstJustPressed();
				var keyReleased:Int = FlxG.keys.firstJustReleased();
				if (keyPressed > -1 && keyPressed != FlxKey.ESCAPE && keyPressed != FlxKey.BACKSPACE)
				{
					curKeys[curAlt] = keyPressed;
					changed = true;
				}
				else if (keyReleased > -1 && (keyReleased == FlxKey.ESCAPE || keyReleased == FlxKey.BACKSPACE))
				{
					curKeys[curAlt] = keyReleased;
					changed = true;
				}
			}

			if (changed)
			{
				if (curKeys[curAlt] == curKeys[1 - curAlt])
					curKeys[1 - curAlt] = FlxKey.NONE;

				var option:String = curOption[1];
				ClientPrefs.clearInvalidKeys(option);

				var n:Int = curAlt;
				var key:String = null;

				var savKey:Array<Null<FlxKey>> = ClientPrefs.keyBinds.get(option);
				key = InputFormatter.getKeyName(savKey[n] != null ? savKey[n] : NONE);

				updateCSNote(key);

				FlxG.sound.play(Paths.sound('confirmMenu'));
				closeBinding();
			}
		}
	}

	public function selSected(i:Int)
	{
		if (!keybootBool) return;

		FlxG.sound.play(Paths.sound('scrollMenu'));
		curSelected += i;

		curSelected = returnNoteInt(curSelected, i);

		var intvalue:Float = 65;

		buttonMouseMove.tweenData = -intvalue * curSelected;
	}

	public var acceptBool:Bool = false;
	public var acceptTimer:FlxTimer;

	public function selectNote()
	{
		if (acceptTimer != null)
		{
			acceptTimer.cancel();
		}

		allowControlsMode = true;
		buttonAltBool = true;

		if (buttonNpos != 0 && curSelected != buttonNpos-1 && doneBool)
		{
			backAllowControlsMode(false);
		}

		optionsButtonArray[curSelected].moveBG(curSelected, optionsButtonArray);

		acceptTimer = new FlxTimer().start(0.1, function(tmr:FlxTimer)
		{
			acceptBool = true;
		});

		doneBool = true;
	}

	public function selsetButton(i:Int, type:Int = 0)
	{
		if (!keybootBool) return;

		FlxG.sound.play(Paths.sound('scrollMenu'));
		if (type == 0)
			buttonSelected += i;
		else if (type == 1)
			buttonSelected += 2;
		else if (type == 2)
			buttonSelected = i;

		if (buttonSelected > 3)
		{
			buttonSelected = 0;
		}
		else if (buttonSelected < 0)
		{
			buttonSelected = 1;
		}

		//trace(buttonSelected);
	}

	function returnNoteInt(index:Int, cur:Int):Int
	{
		if (optionsButtonArray[index].optionUpdateBool)
		{
			return index;
		}
		else {
			index += cur;

			if (index > optionsButtonArray.length - 1)
			{
				index = 0;
				index = returnNoteInt(index, cur);
			}
			else if (index <= 0)
			{
				index = optionsButtonArray.length - 1;
				index = returnNoteInt(index, cur);
			}

			returnNoteInt(index, cur);
		}

		return index;
	}

	public function backAllowControlsMode(tweenBool:Bool = true)
	{
		buttonAltBool = false;
		allowControlsMode = false;

		optionsButtonArray[buttonNpos-1].moveBG(buttonNpos-1, optionsButtonArray, tweenBool);

		doneBool = false;
		
		//trace("doneBool:" + doneBool);
	}

	function updateCSNote(text:String)
	{
		noteParent.noteSprite.updateText(curAlt, text);
		//trace(text);
	}

	public function closeBinding()
	{
		updateNoteModeBool = false;
		keybootBool = true;

		setOptionText.text = "Idle...";
		setOptionText.updateHitbox();

		ClientPrefs.reloadVolumeKeys();
	}

	public var bindingBlack:FlxSprite;
	public var bindingText:FlxText;
	public var noteParent:ControlsSprite;

	public function updateNoteMode(text:String, strArray:Array<String>, alt:Int, parent:ControlsSprite)
	{
		updateNoteModeBool = true;
		keybootBool = false;

		curOption = strArray;
		curAlt = alt;
		noteParent = parent;
		setOptionText.text = returnText(text);
		setOptionText.updateHitbox();

		holdingEsc = 0;
		ClientPrefs.toggleVolumeKeys(false);
		FlxG.sound.play(Paths.sound('scrollMenu'));
	}

	public function returnText(text:String):String
	{
		var funnyText:String = '';

		funnyText += 'Rebinding ${text}\n';

		if (controls.mobileC)
		{
			funnyText += "Hold B to Cancel\nHold C to Delete";
		}
		else
		{
			funnyText += "Hold ESC to Cancel\nHold Backspace to Delete";
		}

		return funnyText;
	}

    public function createOnOptionsText(text:String, x:Float, y:Float):Void
    {
		var optionsButton = new ControlsSprite(0, y, 150, 2, 1, 0xFF7A75A0, text);
		optionsButton.screenCenter(X);
        add(optionsButton);
        optionsButtonArray.push(optionsButton);
		optionsButton.cameras = [camControls];
		optionsButton.centerTextX(23);
    }

	public static function updateOptionsText(text:String):Void
	{
		optionTextStrStatic = text;

		optionText.text = optionTextStrStatic;
		optionText.screenCenter(X);
	}

    public function createOptionsButton(text:String, x:Float, y:Float, array:Array<String>):Void
    {
        var optionsButton = new ControlsSprite(0, y, 1000, 50, 15, 0xFF7A75A0, text);
		optionsButton.screenCenter(X);
        add(optionsButton);
        optionsButtonArray.push(optionsButton);
		optionsButton.centerSpriteX();
		optionsButton.createNoteArray(array);

		optionsButton.createOptionText(optionTextStr);
		
		optionsButton.cameras = [camControls];

		// 按键生成 可能会有点乱 -- chh
    }

	public function createOptionsResetButton(text:String, x:Float, y:Float):Void
	{
		var optionsButton = new ControlsSprite(0, y, 100, 2, 16, 0xFF7A75A0, "");
		optionsButton.funReNote(text);
		optionsButton.text.screenCenter(X);
		add(optionsButton);
		optionsButtonArray.push(optionsButton);
		optionsButton.cameras = [camControls];
	}

	public static function returnStr(array:Array<String>):Array<String> // 给ControlsSprite传递key -- chh
	{
		var keyArray:Array<String> = [];

		for (n in 0...2) {

			//keyArray.push(key);
		}
		return keyArray;
	}

	// 下面是移动面板的更新函数 -- chh

	var saveMouseY:Int = 0;
	var moveData:Int = 0;
	var avgSpeed:Float = 0;

	function mouseMove()
	{
		if (FlxG.mouse.justPressed)
		{
			saveMouseY = FlxG.mouse.y;
			avgSpeed = 0;
		}
		moveData = FlxG.mouse.y - saveMouseY;
		saveMouseY = FlxG.mouse.y;
		avgSpeed = avgSpeed * 0.8 + moveData * 0.2;
	}

	var pos:Float;

	public var buttonYpos:Float = 0;
	public var buttonNpos:Int = 0;
	
	var odButtonNpos:Int = 0;
	var odButtonBool:Bool = false;

    function songsRectPosUpdate(forceUpdate:Bool = false, elapsed:Float = 0)
    {
        if (!forceUpdate && lerpPosition == position)
            return; // 优化

		//trace(buttonYpos, buttonNpos);

		pos = 1;

        for (i in 0...optionsButtonArray.length)
        {
			if (i >= buttonNpos)
			{
				optionsButtonArray[i].y = lerpPosition + i * pos + buttonYpos;
			}
			else {
				optionsButtonArray[i].y = lerpPosition + i * pos;
			}
        }
    }
}
