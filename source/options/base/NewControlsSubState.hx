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
		[true],
		[true, '1K+2K+3K'],
		[true, '1K'],
		[true, '[key]', '0_key_0', '0k_0'],
		[true],
		[true, '2K'],
		[true, 'left/左', '1_key_0', '1k_0'],
		[true, 'right/右', '1_key_1', '1k_1'],
		[true],
		[true, '3K'],
		[true, 'left/左', '2_key_0', '2k_0'],
		[true, 'middle/中', '2_key_1', '2k_1'],
		[true, 'right/右', '2_key_2', '2k_2'],
		[true],
		[true, '4K+5K'],
		[true, '4K'],
		[true, 'left/左', 'note_left', 'Note Left'],
		[true, 'down/下', 'note_down', 'Note Down'],
		[true, 'up/上面', 'note_up', 'Note Up'],
		[true, 'right/右', 'note_right', 'Note Right'],
		[true],
		[true, '5K'],
		[true, 'left/左', '4_key_0', '4k_0'],
		[true, 'down/下', '4_key_1', '4k_1'],
		[true, 'middle/中', '4_key_2', '4k_2'],
		[true, 'up/上面', '4_key_3', '4k_3'],
		[true, 'right/右', '4_key_4', '4k_4'],
		[true],
		[true, '6k'],
		[true, 'left1/左1', '5_key_0', '5k_0'],
		[true, 'down/下', '5_key_1', '5k_1'],
		[true, 'right1/右1', '5_key_2', '5k_2'],
		[true, 'left2/左2', '5_key_3', '5k_3'],
		[true, 'up/上', '5_key_4', '5k_4'],
		[true, 'right2/右2', '5_key_5', '5k_5'],
		[true],
		[true, '7k'],
		[true, 'left1/左1', '6_key_0', '6k_0'],
		[true, 'down/下', '6_key_1', '6k_1'],
		[true, 'right1/右1', '6_key_2', '6k_2'],
		[true, 'middle/中', '6_key_3', '6k_3'],
		[true, 'left2/左2', '6_key_4', '6k_4'],
		[true, 'up/上', '6_key_5', '6k_5'],
		[true, 'right2/右2', '6_key_6', '6k_6'],
		[true],
		[true, '8k'],
		[true, 'left1/左1', '7_key_0', '7k_0'],
		[true, 'down/下1', '7_key_1', '7k_1'],
		[true, 'up1/上1', '7_key_2', '7k_2'],
		[true, 'right1/右1', '7_key_3', '7k_3'],
		[true, 'left2/左2', '7_key_4', '7k_4'],
		[true, 'down2/下2', '7_key_5', '7k_5'],
		[true, 'up2/上2', '7_key_6', '7k_6'],
		[true, 'right2/右2', '7_key_7', '7k_7'],
		[true],
		[true, '9k'],
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
		[true, '10k'],
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
		[true, 'UI'],
		[true, 'left/左', 'ui_left', 'UI Left'],
		[true, 'down/下', 'ui_down', 'UI Down'],
		[true, 'up/上面', 'ui_up', 'UI Up'],
		[true, 'right/右', 'ui_right', 'UI Right'],
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
	private var background:FlxSprite; // 1.2.0 里是 FlxSprite，这里 new 的是 ControlsSprite（继承 FlxSpriteGroup → FlxBasic），其实存为 ControlsSprite 更准，但保持 1.2.0 风格就 FlxSprite 好了

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

		FlxG.mouse.visible = !ClientPrefs.data.needMobileControl;

		instance = this;

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
        setOptionText.setFormat(Alphabet.getFont(), 51, FlxColor.WHITE, "left");
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

					// 使用 opn[i][1] 作为按钮标题，格式化描述文本
					// 对于 '[key]' 占位符，使用 opn[2] 作为描述（如 '0_key_0' -> 'key_0'）
					// 对于其他按钮行，描述格式化为 "变量名称: xxx"
					var desc:String;
					if (opn[i][1] == '[key]') {
						desc = 'key_' + opn[i][2]; // 格式化为 'key_0', 'key_1' 等
					} else {
						desc = '变量名称: ' + opn[i][2]; // 格式化为 "变量名称: xxx"
					}
					createOptionsButton(opn[i][1], xpos, ypos, array, desc);
				}
			}
			else {
				createOptionsResetButton(Language.get('reset_to_default', 'controls') + ' (SPACE x 3)', xpos, ypos);
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
			if (allowFade) {
				if (controls.BACK)
				{
					visible = false;
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

					if (FlxG.mouse.justPressed) {
						if (buttonNpos == 0 && !optionsButtonArray[buttonNpos].scaleBool || buttonNpos != 0 && !optionsButtonArray[buttonNpos-1].scaleBool || buttonNpos != 0 && i != buttonNpos-1)
						{
							selectNote();
						}
					}
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
			if (holdingEsc > 2.0)
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
	}

	function updateCSNote(text:String)
	{
		noteParent.noteSprite.updateText(curAlt, text);
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

		var rebindText:String = Language.get('rebinding', 'controls');
		if (rebindText == '' || rebindText.indexOf('(404)') >= 0) rebindText = 'Rebinding';
		funnyText += rebindText + text + '\n';

		if (controls.mobileC)
		{
			var bCancel:String = Language.get('holdBCancel', 'controls');
			if (bCancel == '' || bCancel.indexOf('(404)') >= 0) bCancel = 'Hold B to Cancel';
			var cDelete:String = Language.get('holdCDelete', 'controls');
			if (cDelete == '' || cDelete.indexOf('(404)') >= 0) cDelete = 'Hold C to Delete';
			funnyText += bCancel + '\n' + cDelete;
		}
		else
		{
			var escCancel:String = Language.get('holdEscCancel', 'controls');
			if (escCancel == '' || escCancel.indexOf('(404)') >= 0) escCancel = 'Hold ESC 2 Seconds to Cancel';
			var backDelete:String = Language.get('holdBackspaceDelete', 'controls');
			if (backDelete == '' || backDelete.indexOf('(404)') >= 0) backDelete = 'Hold Backspace to Delete the key';
			funnyText += '[ Please Enter Key Here ]\n（' + escCancel + '）\n（' + backDelete + '）';
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

		// 保存 Y 坐标，避免 screenCenter 意外重置
		var savedY = optionText.y;
		optionText.text = optionTextStrStatic;
		optionText.screenCenter(X);
		optionText.y = savedY; // 恢复 Y 坐标
	}

    public function createOptionsButton(text:String, x:Float, y:Float, array:Array<String>, ?description:String = ""):Void
    {
        var optionsButton = new ControlsSprite(0, y, 1000, 50, 15, 0xFF7A75A0, text);
		optionsButton.screenCenter(X);
        add(optionsButton);
        optionsButtonArray.push(optionsButton);
		optionsButton.centerSpriteX();
		optionsButton.createNoteArray(array);

		// 使用传入的描述文本，如果没有则使用 optionTextStr
		var desc = (description != "") ? description : optionTextStr;
		optionsButton.createOptionText(desc);
		
		optionsButton.cameras = [camControls];
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
