package mobile.flixel;

import flixel.graphics.frames.FlxTileFrames;
import flixel.input.keyboard.FlxKey;

import mobile.flixel.input.FlxMobileInputManager;
import mobile.flixel.FlxButton;

import general.backend.InputFormatter;

import openfl.display.Shape;
import openfl.display.BitmapData;

/**
 * A gamepad.
 * It's easy to customize the layout.
 *
 * @original author Ka Wing Chin & Mihai Alexandru
 * @modification's author: Karim Akra & Lily (mcagabe19)
 */
class FlxVirtualPad extends FlxMobileInputManager
{
	public var buttonLeft:FlxButton;
	public var buttonUp:FlxButton;
	public var buttonRight:FlxButton;
	public var buttonDown:FlxButton;

	public var buttonLeft2:FlxButton;
	public var buttonUp2:FlxButton;
	public var buttonRight2:FlxButton;
	public var buttonDown2:FlxButton;

	public var buttonA:FlxButton;
	public var buttonB:FlxButton;
	public var buttonC:FlxButton;
	public var buttonD:FlxButton;
	public var buttonE:FlxButton;
	public var buttonF:FlxButton;
	public var buttonG:FlxButton;
	public var buttonS:FlxButton;
	public var buttonV:FlxButton;
	public var buttonX:FlxButton;
	public var buttonY:FlxButton;
	public var buttonZ:FlxButton;
	public var buttonP:FlxButton;

	public var extraKeys:Array<FlxButton> = [];

	/**
	 * Create a gamepad.
	 *
	 * @param   DPadMode     The D-Pad mode. `LEFT_FULL` for example.
	 * @param   ActionMode   The action buttons mode. `A_B_C` for example.
	 */
	public function new(DPad:FlxDPadMode, Action:FlxActionMode)
	{
		super();

		var BTN_W:Int = 120;
		var BTN_H:Int = 120;

		switch (DPad)
		{
			case UP_DOWN:
				add(buttonUp = createButton(0, FlxG.height - 255, BTN_W, BTN_H, 'up', keybindSet('ui_up'), 0xFF12FA05));
				add(buttonDown = createButton(0, FlxG.height - 135, BTN_W, BTN_H, 'down', keybindSet('ui_down'), 0xFF00FFFF));
			case LEFT_RIGHT:
				add(buttonLeft = createButton(0, FlxG.height - 135, BTN_W, BTN_H, 'left', keybindSet('ui_left'), 0xFFC24B99));
				add(buttonRight = createButton(127, FlxG.height - 135, BTN_W, BTN_H, 'right', keybindSet('ui_right'), 0xFFF9393F));
			case UP_LEFT_RIGHT:
				add(buttonUp = createButton(105, FlxG.height - 243, BTN_W, BTN_H, 'up', keybindSet('ui_up'), 0xFF12FA05));
				add(buttonLeft = createButton(0, FlxG.height - 135, BTN_W, BTN_H, 'left', keybindSet('ui_left'), 0xFFC24B99));
				add(buttonRight = createButton(207, FlxG.height - 135, BTN_W, BTN_H, 'right', keybindSet('ui_right'), 0xFFF9393F));
			case LEFT_FULL:
				add(buttonUp = createButton(105, FlxG.height - 345, BTN_W, BTN_H, 'up', keybindSet('ui_up'), 0xFF12FA05));
				add(buttonLeft = createButton(0, FlxG.height - 243, BTN_W, BTN_H, 'left', keybindSet('ui_left'), 0xFFC24B99));
				add(buttonRight = createButton(207, FlxG.height - 243, BTN_W, BTN_H, 'right', keybindSet('ui_right'), 0xFFF9393F));
				add(buttonDown = createButton(105, FlxG.height - 135, BTN_W, BTN_H, 'down', keybindSet('ui_down'), 0xFF00FFFF));
			case LEFT_FULL_GAME:
				add(buttonUp = createButton(105, FlxG.height - 345, BTN_W, BTN_H, 'up', keybindSet('note_up'), 0xFF12FA05));
				add(buttonLeft = createButton(0, FlxG.height - 243, BTN_W, BTN_H, 'left', keybindSet('note_left'), 0xFFC24B99));
				add(buttonRight = createButton(207, FlxG.height - 243, BTN_W, BTN_H, 'right', keybindSet('note_right'), 0xFFF9393F));
				add(buttonDown = createButton(105, FlxG.height - 135, BTN_W, BTN_H, 'down', keybindSet('note_down'), 0xFF00FFFF));
			case RIGHT_FULL:
				add(buttonUp = createButton(FlxG.width - 258, FlxG.height - 408, BTN_W, BTN_H, 'up', keybindSet('ui_up'), 0xFF12FA05));
				add(buttonLeft = createButton(FlxG.width - 384, FlxG.height - 309, BTN_W, BTN_H, 'left', keybindSet('ui_left'), 0xFFC24B99));
				add(buttonRight = createButton(FlxG.width - 132, FlxG.height - 309, BTN_W, BTN_H, 'right', keybindSet('ui_right'), 0xFFF9393F));
				add(buttonDown = createButton(FlxG.width - 258, FlxG.height - 201, BTN_W, BTN_H, 'down', keybindSet('ui_down'), 0xFF00FFFF));
			case RIGHT_FULL_GAME:
				add(buttonUp = createButton(FlxG.width - 258, FlxG.height - 408, BTN_W, BTN_H, 'up', keybindSet('note_up'), 0xFF12FA05));
				add(buttonLeft = createButton(FlxG.width - 384, FlxG.height - 309, BTN_W, BTN_H, 'left', keybindSet('note_left'), 0xFFC24B99));
				add(buttonRight = createButton(FlxG.width - 132, FlxG.height - 309, BTN_W, BTN_H, 'right', keybindSet('note_right'), 0xFFF9393F));
				add(buttonDown = createButton(FlxG.width - 258, FlxG.height - 201, BTN_W, BTN_H, 'down', keybindSet('note_down'), 0xFF00FFFF));
			case BOTH:
				add(buttonUp = createButton(105, FlxG.height - 345, BTN_W, BTN_H, 'up', keybindSet('ui_up'), 0xFF12FA05));
				add(buttonLeft = createButton(0, FlxG.height - 243, BTN_W, BTN_H, 'left', keybindSet('ui_left'), 0xFFC24B99));
				add(buttonRight = createButton(207, FlxG.height - 243, BTN_W, BTN_H, 'right', keybindSet('ui_right'), 0xFFF9393F));
				add(buttonDown = createButton(105, FlxG.height - 135, BTN_W, BTN_H, 'down', keybindSet('ui_down'), 0xFF00FFFF));
				add(buttonUp2 = createButton(FlxG.width - 258, FlxG.height - 408, BTN_W, BTN_H, 'up', keybindSet('ui_up'), 0xFF12FA05));
				add(buttonLeft2 = createButton(FlxG.width - 384, FlxG.height - 309, BTN_W, BTN_H, 'left', keybindSet('ui_left'), 0xFFC24B99));
				add(buttonRight2 = createButton(FlxG.width - 132, FlxG.height - 309, BTN_W, BTN_H, 'right', keybindSet('ui_right'), 0xFFF9393F));
				add(buttonDown2 = createButton(FlxG.width - 258, FlxG.height - 201, BTN_W, BTN_H, 'down', keybindSet('ui_down'), 0xFF00FFFF));
			case BOTH_GAME:
				add(buttonUp = createButton(105, FlxG.height - 345, BTN_W, BTN_H, 'up', keybindSet('note_up'), 0xFF12FA05));
				add(buttonLeft = createButton(0, FlxG.height - 243, BTN_W, BTN_H, 'left', keybindSet('note_left'), 0xFFC24B99));
				add(buttonRight = createButton(207, FlxG.height - 243, BTN_W, BTN_H, 'right', keybindSet('note_right'), 0xFFF9393F));
				add(buttonDown = createButton(105, FlxG.height - 135, BTN_W, BTN_H, 'down', keybindSet('note_down'), 0xFF00FFFF));
				add(buttonUp2 = createButton(FlxG.width - 258, FlxG.height - 408, BTN_W, BTN_H, 'up', keybindSet('note_up', 1), 0xFF12FA05));
				add(buttonLeft2 = createButton(FlxG.width - 384, FlxG.height - 309, BTN_W, BTN_H, 'left', keybindSet('note_left', 1), 0xFFC24B99));
				add(buttonRight2 = createButton(FlxG.width - 132, FlxG.height - 309, BTN_W, BTN_H, 'right', keybindSet('note_right', 1), 0xFFF9393F));
				add(buttonDown2 = createButton(FlxG.width - 258, FlxG.height - 201, BTN_W, BTN_H, 'down', keybindSet('note_down', 1), 0xFF00FFFF));
			case PauseSubstateC:
				add(buttonUp = createButton(0, FlxG.height - 255, BTN_W, BTN_H, "up", keybindSet('ui_up'), 0x00FF00));
				add(buttonDown = createButton(0, FlxG.height - 135, BTN_W, BTN_H, "down", keybindSet('ui_down'), 0x00FFFF));
				add(buttonLeft = createButton(126, FlxG.height - 135, BTN_W, BTN_H, "left", keybindSet('ui_left'), 0xFF00FF));
				add(buttonRight = createButton(252, FlxG.height - 135, BTN_W, BTN_H, "right", keybindSet('ui_right'), 0xFF0000));
			case OptionStateC:
				add(buttonUp = createButton(0, FlxG.height - 255, BTN_W, BTN_H, "up", keybindSet('ui_up'), 0x00FF00));
				add(buttonDown = createButton(0, FlxG.height - 135, BTN_W, BTN_H, "down", keybindSet('ui_down'), 0x00FFFF));
			case MainMenuStateC:
				add(buttonUp = createButton(FlxG.width - 132, FlxG.height - 495, BTN_W, BTN_H, 'up', keybindSet('ui_up'), 0xFF12FA05));
				add(buttonDown = createButton(FlxG.width - 132, FlxG.height - 375, BTN_W, BTN_H, 'down', keybindSet('ui_down'), 0xFF00FFFF));
			case ChartingStateC:
				add(buttonUp = createButton(0, FlxG.height - 255, BTN_W, BTN_H, 'up', keybindSet('ui_up'), 0xFF12FA05));
				add(buttonLeft = createButton(132, FlxG.height - 255, BTN_W, BTN_H, 'left', keybindSet('ui_left'), 0xFFC24B99));
				add(buttonRight = createButton(132, FlxG.height - 135, BTN_W, BTN_H, 'right', keybindSet('ui_right'), 0xFFF9393F));
				add(buttonDown = createButton(0, FlxG.height - 135, BTN_W, BTN_H, 'down', keybindSet('ui_down'), 0xFF00FFFF));
			case DIALOGUE_PORTRAIT:
				add(buttonUp = createButton(105, FlxG.height - 345, BTN_W, BTN_H, 'up', keybindSet('ui_up'), 0xFF12FA05));
				add(buttonLeft = createButton(0, FlxG.height - 243, BTN_W, BTN_H, 'left', keybindSet('ui_left'), 0xFFC24B99));
				add(buttonRight = createButton(207, FlxG.height - 243, BTN_W, BTN_H, 'right', keybindSet('ui_right'), 0xFFF9393F));
				add(buttonDown = createButton(105, FlxG.height - 135, BTN_W, BTN_H, 'down', keybindSet('ui_down'), 0xFF00FFFF));
				add(buttonUp2 = createButton(105, 0, BTN_W, BTN_H, 'up', keybindSet('ui_up'), 0xFF12FA05));
				add(buttonLeft2 = createButton(0, 82, BTN_W, BTN_H, 'left', keybindSet('ui_left'), 0xFFC24B99));
				add(buttonRight2 = createButton(207, 82, BTN_W, BTN_H, 'right', keybindSet('ui_right'), 0xFFF9393F));
				add(buttonDown2 = createButton(105, 190, BTN_W, BTN_H, 'down', keybindSet('ui_down'), 0xFF00FFFF));
			case MENU_CHARACTER:
				add(buttonUp = createButton(105, 0, BTN_W, BTN_H, 'up', keybindSet('ui_up'), 0xFF12FA05));
				add(buttonLeft = createButton(0, 82, BTN_W, BTN_H, 'left', keybindSet('ui_left'), 0xFFC24B99));
				add(buttonRight = createButton(207, 82, BTN_W, BTN_H, 'right', keybindSet('ui_right'), 0xFFF9393F));
				add(buttonDown = createButton(105, 190, BTN_W, BTN_H, 'down', keybindSet('ui_down'), 0xFF00FFFF));
			case NOTE_SPLASH_DEBUG:
				add(buttonUp = createButton(0, 125, BTN_W, BTN_H, 'up', keybindSet('ui_up'), 0xFF12FA05));
				add(buttonLeft = createButton(0, 0, BTN_W, BTN_H, 'left', keybindSet('ui_left'), 0xFFC24B99));
				add(buttonRight = createButton(127, 0, BTN_W, BTN_H, 'right', keybindSet('ui_right'), 0xFFF9393F));
				add(buttonDown = createButton(127, 125, BTN_W, BTN_H, 'down', keybindSet('ui_down'), 0xFF00FFFF));
				add(buttonUp2 = createButton(127, 393, BTN_W, BTN_H, 'up', keybindSet('ui_up', 1), 0xFF12FA05));
				add(buttonLeft2 = createButton(0, 393, BTN_W, BTN_H, 'left', keybindSet('ui_left', 1), 0xFFC24B99));
				add(buttonRight2 = createButton(1145, 393, BTN_W, BTN_H, 'right', keybindSet('ui_right', 1), 0xFFF9393F));
				add(buttonDown2 = createButton(1015, 393, BTN_W, BTN_H, 'down', keybindSet('ui_down', 1), 0xFF00FFFF));
			case NONE: // do nothing
		}

		switch (Action)
		{
			case A:
				add(buttonA = createButton(FlxG.width - 132, FlxG.height - 135, BTN_W, BTN_H, 'a', keybindSet('accept'), 0xFF0000));
			case B:
				add(buttonB = createButton(FlxG.width - 132, FlxG.height - 135, BTN_W, BTN_H, 'b', keybindSet('back'), 0xFFCB00));
			case B_X:
				add(buttonB = createButton(FlxG.width - 258, FlxG.height - 135, BTN_W, BTN_H, 'b', keybindSet('back'), 0xFFCB00));
				add(buttonX = createButton(FlxG.width - 132, FlxG.height - 135, BTN_W, BTN_H, 'x', null, 0x99062D));
			case A_B:
				add(buttonB = createButton(FlxG.width - 258, FlxG.height - 135, BTN_W, BTN_H, 'b', keybindSet('back'), 0xFFCB00));
				add(buttonA = createButton(FlxG.width - 132, FlxG.height - 135, BTN_W, BTN_H, 'a', keybindSet('accept'), 0xFF0000));
			case A_B_C:
				add(buttonC = createButton(FlxG.width - 384, FlxG.height - 135, BTN_W, BTN_H, 'c', null, 0x44FF00));
				add(buttonB = createButton(FlxG.width - 258, FlxG.height - 135, BTN_W, BTN_H, 'b', keybindSet('back'), 0xFFCB00));
				add(buttonA = createButton(FlxG.width - 132, FlxG.height - 135, BTN_W, BTN_H, 'a', keybindSet('accept'), 0xFF0000));
			case A_B_E:
				add(buttonE = createButton(FlxG.width - 384, FlxG.height - 135, BTN_W, BTN_H, 'e', null, 0xFF7D00));
				add(buttonB = createButton(FlxG.width - 258, FlxG.height - 135, BTN_W, BTN_H, 'b', keybindSet('back'), 0xFFCB00));
				add(buttonA = createButton(FlxG.width - 132, FlxG.height - 135, BTN_W, BTN_H, 'a', keybindSet('accept'), 0xFF0000));
			case A_B_X_Y:
				add(buttonX = createButton(FlxG.width - 510, FlxG.height - 135, BTN_W, BTN_H, 'x', null, 0x99062D));
				add(buttonB = createButton(FlxG.width - 258, FlxG.height - 135, BTN_W, BTN_H, 'b', keybindSet('back'), 0xFFCB00));
				add(buttonY = createButton(FlxG.width - 384, FlxG.height - 135, BTN_W, BTN_H, 'y', null, 0x4A35B9));
				add(buttonA = createButton(FlxG.width - 132, FlxG.height - 135, BTN_W, BTN_H, 'a', keybindSet('accept'), 0xFF0000));
			case A_B_C_X_Y:
				add(buttonC = createButton(FlxG.width - 384, FlxG.height - 135, BTN_W, BTN_H, 'c', null, 0x44FF00));
				add(buttonX = createButton(FlxG.width - 258, FlxG.height - 255, BTN_W, BTN_H, 'x', null, 0x99062D));
				add(buttonB = createButton(FlxG.width - 258, FlxG.height - 135, BTN_W, BTN_H, 'b', keybindSet('back'), 0xFFCB00));
				add(buttonY = createButton(FlxG.width - 132, FlxG.height - 255, BTN_W, BTN_H, 'y', null, 0x4A35B9));
				add(buttonA = createButton(FlxG.width - 132, FlxG.height - 135, BTN_W, BTN_H, 'a', keybindSet('accept'), 0xFF0000));
			case A_B_C_X_Y_Z:
				add(buttonX = createButton(FlxG.width - 384, FlxG.height - 255, BTN_W, BTN_H, 'x', null, 0x99062D));
				add(buttonC = createButton(FlxG.width - 384, FlxG.height - 135, BTN_W, BTN_H, 'c', null, 0x44FF00));
				add(buttonY = createButton(FlxG.width - 258, FlxG.height - 255, BTN_W, BTN_H, 'y', null, 0x4A35B9));
				add(buttonB = createButton(FlxG.width - 258, FlxG.height - 135, BTN_W, BTN_H, 'b', keybindSet('back'), 0xFFCB00));
				add(buttonZ = createButton(FlxG.width - 132, FlxG.height - 255, BTN_W, BTN_H, 'z', null, 0xCCB98E));
				add(buttonA = createButton(FlxG.width - 132, FlxG.height - 135, BTN_W, BTN_H, 'a', keybindSet('accept'), 0xFF0000));
			case A_B_C_D_V_X_Y_Z:
				add(buttonV = createButton(FlxG.width - 510, FlxG.height - 255, BTN_W, BTN_H, 'v', null, 0x49A9B2));
				add(buttonD = createButton(FlxG.width - 510, FlxG.height - 135, BTN_W, BTN_H, 'd', null, 0x0078FF));
				add(buttonX = createButton(FlxG.width - 384, FlxG.height - 255, BTN_W, BTN_H, 'x', null, 0x99062D));
				add(buttonC = createButton(FlxG.width - 384, FlxG.height - 135, BTN_W, BTN_H, 'c', null, 0x44FF00));
				add(buttonY = createButton(FlxG.width - 258, FlxG.height - 255, BTN_W, BTN_H, 'y', null, 0x4A35B9));
				add(buttonB = createButton(FlxG.width - 258, FlxG.height - 135, BTN_W, BTN_H, 'b', keybindSet('back'), 0xFFCB00));
				add(buttonZ = createButton(FlxG.width - 132, FlxG.height - 255, BTN_W, BTN_H, 'z', null, 0xCCB98E));
				add(buttonA = createButton(FlxG.width - 132, FlxG.height - 135, BTN_W, BTN_H, 'a', keybindSet('accept'), 0xFF0000));
			case controlExtend:
				var keyNames:Array<String> = [
					ClientPrefs.data.extraKeyReturn1,
					ClientPrefs.data.extraKeyReturn2,
					ClientPrefs.data.extraKeyReturn3,
					ClientPrefs.data.extraKeyReturn4
				];
				var startX:Float = FlxG.width * 0.5 - 258;
				for (i in 0...ClientPrefs.data.extraKey)
				{
					var btn = createButton(startX + i * 126, FlxG.height * 0.5 - 63, BTN_W, BTN_H, keyNames[i], keyboardSet(keyNames[i]), 0xFFAA66CC);
					extraKeys.push(btn);
					add(btn);
				}
			case OptionStateC:
				add(buttonLeft = createButton(FlxG.width - 258, FlxG.height - 255, BTN_W, BTN_H, "left", keybindSet('ui_left'), 0xFF00FF));
				add(buttonRight = createButton(FlxG.width - 132, FlxG.height - 255, BTN_W, BTN_H, "right", keybindSet('ui_right'), 0xFF0000));
				add(buttonC = createButton(FlxG.width - 384, FlxG.height - 135, BTN_W, BTN_H, 'c', null, 0x44FF00));
				add(buttonB = createButton(FlxG.width - 258, FlxG.height - 135, BTN_W, BTN_H, 'b', keybindSet('back'), 0xFFCB00));
				add(buttonA = createButton(FlxG.width - 132, FlxG.height - 135, BTN_W, BTN_H, 'a', keybindSet('accept'), 0xFF0000));
			case ChartingStateC:
				add(buttonS = createButton(FlxG.width - 132, FlxG.height - 375, BTN_W, BTN_H, 's', null, 0x49A9B2));
				add(buttonG = createButton(FlxG.width - 258, 25, BTN_W, BTN_H, 'g', null, 0x49A9B2));
				add(buttonP = createButton(FlxG.width - 636, FlxG.height - 255, BTN_W, BTN_H, 'up', null, 0x49A9B2));
				add(buttonE = createButton(FlxG.width - 636, FlxG.height - 135, BTN_W, BTN_H, 'down', null, 0x49A9B2));
				add(buttonV = createButton(FlxG.width - 510, FlxG.height - 255, BTN_W, BTN_H, 'v', null, 0x49A9B2));
				add(buttonD = createButton(FlxG.width - 510, FlxG.height - 135, BTN_W, BTN_H, 'd', null, 0x0078FF));
				add(buttonX = createButton(FlxG.width - 384, FlxG.height - 255, BTN_W, BTN_H, 'x', null, 0x99062D));
				add(buttonC = createButton(FlxG.width - 384, FlxG.height - 135, BTN_W, BTN_H, 'c', null, 0x44FF00));
				add(buttonY = createButton(FlxG.width - 258, FlxG.height - 255, BTN_W, BTN_H, 'y', null, 0x4A35B9));
				add(buttonB = createButton(FlxG.width - 258, FlxG.height - 135, BTN_W, BTN_H, 'b', keybindSet('back'), 0xFFCB00));
				add(buttonZ = createButton(FlxG.width - 132, FlxG.height - 255, BTN_W, BTN_H, 'z', null, 0xCCB98E));
				add(buttonA = createButton(FlxG.width - 132, FlxG.height - 135, BTN_W, BTN_H, 'a', keybindSet('accept'), 0xFF0000));
			case CHARACTER_EDITOR:
				add(buttonV = createButton(FlxG.width - 510, FlxG.height - 255, BTN_W, BTN_H, 'v', null, 0x49A9B2));
				add(buttonD = createButton(FlxG.width - 510, FlxG.height - 135, BTN_W, BTN_H, 'd', null, 0x0078FF));
				add(buttonX = createButton(FlxG.width - 384, FlxG.height - 255, BTN_W, BTN_H, 'x', null, 0x99062D));
				add(buttonC = createButton(FlxG.width - 384, FlxG.height - 135, BTN_W, BTN_H, 'c', null, 0x44FF00));
				add(buttonS = createButton(FlxG.width - 636, FlxG.height - 135, BTN_W, BTN_H, 's', null, 0xEA00FF));
				add(buttonG = createButton(FlxG.width - 636, FlxG.height - 255, BTN_W, BTN_H, 'g', null, 0xEA00FF));
				add(buttonF = createButton(FlxG.width - 410, 0, BTN_W, BTN_H, 'f', null, 0xFF009D));
				add(buttonY = createButton(FlxG.width - 258, FlxG.height - 255, BTN_W, BTN_H, 'y', null, 0x4A35B9));
				add(buttonB = createButton(FlxG.width - 258, FlxG.height - 135, BTN_W, BTN_H, 'b', keybindSet('back'), 0xFFCB00));
				add(buttonZ = createButton(FlxG.width - 132, FlxG.height - 255, BTN_W, BTN_H, 'z', null, 0xCCB98E));
				add(buttonA = createButton(FlxG.width - 132, FlxG.height - 135, BTN_W, BTN_H, 'a', keybindSet('accept'), 0xFF0000));
			case DIALOGUE_PORTRAIT:
				add(buttonX = createButton(FlxG.width - 384, 0, BTN_W, BTN_H, 'x', null, 0x99062D));
				add(buttonC = createButton(FlxG.width - 384, 125, BTN_W, BTN_H, 'c', null, 0x44FF00));
				add(buttonY = createButton(FlxG.width - 258, 0, BTN_W, BTN_H, 'y', null, 0x4A35B9));
				add(buttonB = createButton(FlxG.width - 258, 125, BTN_W, BTN_H, 'b', keybindSet('back'), 0xFFCB00));
				add(buttonZ = createButton(FlxG.width - 132, 0, BTN_W, BTN_H, 'z', null, 0xCCB98E));
				add(buttonA = createButton(FlxG.width - 132, 125, BTN_W, BTN_H, 'a', keybindSet('accept'), 0xFF0000));
			case MENU_CHARACTER:
				add(buttonC = createButton(FlxG.width - 384, 0, BTN_W, BTN_H, 'c', null, 0x44FF00));
				add(buttonB = createButton(FlxG.width - 258, 0, BTN_W, BTN_H, 'b', keybindSet('back'), 0xFFCB00));
				add(buttonA = createButton(FlxG.width - 132, 0, BTN_W, BTN_H, 'a', keybindSet('accept'), 0xFF0000));
			case NOTE_SPLASH_DEBUG:
				add(buttonB = createButton(FlxG.width - 258, FlxG.height - 135, BTN_W, BTN_H, 'b', keybindSet('back'), 0xFFCB00));
				add(buttonE = createButton(FlxG.width - 132, 0, BTN_W, BTN_H, 'e', null, 0xFF7D00));
				add(buttonX = createButton(FlxG.width - 258, 0, BTN_W, BTN_H, 'x', null, 0x99062D));
				add(buttonY = createButton(FlxG.width - 132, 250, BTN_W, BTN_H, 'y', null, 0x4A35B9));
				add(buttonZ = createButton(FlxG.width - 258, 250, BTN_W, BTN_H, 'z', null, 0xCCB98E));
				add(buttonA = createButton(FlxG.width - 132, FlxG.height - 135, BTN_W, BTN_H, 'a', keybindSet('accept'), 0xFF0000));
				add(buttonC = createButton(FlxG.width - 132, 125, BTN_W, BTN_H, 'c', null, 0x44FF00));
				add(buttonV = createButton(FlxG.width - 258, 125, BTN_W, BTN_H, 'v', null, 0x49A9B2));
			case P:
				add(buttonP = createButton(FlxG.width - 132, 0, BTN_W, BTN_H, 'x', null, 0x99062D));
			case B_C:
				add(buttonC = createButton(FlxG.width - 132, FlxG.height - 135, BTN_W, BTN_H, 'c', null, 0x44FF00));
				add(buttonB = createButton(FlxG.width - 258, FlxG.height - 135, BTN_W, BTN_H, 'b', keybindSet('back'), 0xFFCB00));
			case NONE: // do nothing
		}

		scrollFactor.set();
		updateTrackedButtons();
	}

	private function createButton(X:Float, Y:Float, Width:Int, Height:Int, Graphic:String,  ?IDs:Array<FlxKey> = null, ?Color:Int = 0xFFFFFF):FlxButton
	{
		var button = new FlxButton(X, Y, IDs, Graphic);
		button.loadGraphic(createHintGraphic(Width, Height));
		button.saveColor = Color;
		button.solid = false;
		button.immovable = true;
		button.moves = false;
		button.scrollFactor.set();
		button.color = Color;
		button.antialiasing = ClientPrefs.data.antialiasing;
		button.tag = Graphic.toUpperCase();
		#if FLX_DEBUG
		button.ignoreDrawDebug = true;
		#end

		button.updateLabelSize(Width, Height);

		button.onDown.callback = function()
		{
			button.color = 0xFFFFFF;
		}
		button.onUp.callback = function()
		{
			button.color = button.saveColor;
		}
		button.onOut.callback = function()
		{
			button.color = button.saveColor;
		}

		return button;
	}

	function createHintGraphic(Width:Int, Height:Int):BitmapData
	{
		var guh = ClientPrefs.data.controlsAlpha;
		return drawRect(Width, Height, Width / 3, Height / 3, 3, 0xFFFFFF);
	}

	var shape:Shape = new Shape();
	function drawRect(width:Float, height:Float, roundWidth:Float, roundHeight:Float, lineStyle:Int, lineColor:FlxColor):BitmapData
	{
		shape = new Shape();

		shape.graphics.beginFill(0xFFFFFF, 0.5);
		shape.graphics.drawRoundRect(0, 0, Std.int(width), Std.int(height), roundWidth, roundHeight);
		shape.graphics.endFill();

		var bitmap:BitmapData = new BitmapData(Std.int(width), Std.int(height), true, 0);
		bitmap.draw(shape);
		if (lineStyle > 0) drawLine(bitmap, lineStyle, roundWidth, roundHeight, lineColor);
		return bitmap;
	}

	var lineShape:Shape = null;
    function drawLine(bitmap:BitmapData, lineStyle:Int, roundWidth:Float, roundHeight:Float, lineColor:FlxColor)
	{
		lineShape = new Shape();
		var lineSize:Int = lineStyle;
		lineShape.graphics.beginFill(lineColor);
		lineShape.graphics.lineStyle(1, lineColor, 1);
		lineShape.graphics.drawRoundRect(0, 0, bitmap.width, bitmap.height, roundWidth, roundHeight);
		lineShape.graphics.lineStyle(0, 0, 0);
		lineShape.graphics.drawRoundRect(lineSize, lineSize, bitmap.width - lineSize * 2, bitmap.height - lineSize * 2, roundWidth - lineSize * 2, roundHeight - lineSize * 2);
		lineShape.graphics.endFill();

		bitmap.draw(lineShape);
	}

	private function keybindSet(keyName:String, defaultKey:Int = 0):Array<FlxKey>
	{
		if (ClientPrefs.keyBinds.exists(keyName))
			return ClientPrefs.keyBinds.get(keyName);

		return [];
	}

	private function keyboardSet(keyName:String):Array<FlxKey>
	{
		return [InputFormatter.getFlxKey(keyName)];
	}

	override public function destroy():Void
	{
		super.destroy();

		buttonLeft = FlxDestroyUtil.destroy(buttonLeft);
		buttonUp = FlxDestroyUtil.destroy(buttonUp);
		buttonDown = FlxDestroyUtil.destroy(buttonDown);
		buttonRight = FlxDestroyUtil.destroy(buttonRight);
		buttonLeft2 = FlxDestroyUtil.destroy(buttonLeft2);
		buttonUp2 = FlxDestroyUtil.destroy(buttonUp2);
		buttonDown2 = FlxDestroyUtil.destroy(buttonDown2);
		buttonRight2 = FlxDestroyUtil.destroy(buttonRight2);
		buttonA = FlxDestroyUtil.destroy(buttonA);
		buttonB = FlxDestroyUtil.destroy(buttonB);
		buttonC = FlxDestroyUtil.destroy(buttonC);
		buttonD = FlxDestroyUtil.destroy(buttonD);
		buttonE = FlxDestroyUtil.destroy(buttonE);
		buttonF = FlxDestroyUtil.destroy(buttonF);
		buttonG = FlxDestroyUtil.destroy(buttonG);
		buttonS = FlxDestroyUtil.destroy(buttonS);
		buttonV = FlxDestroyUtil.destroy(buttonV);
		buttonX = FlxDestroyUtil.destroy(buttonX);
		buttonY = FlxDestroyUtil.destroy(buttonY);
		buttonZ = FlxDestroyUtil.destroy(buttonZ);
		buttonP = FlxDestroyUtil.destroy(buttonP);

		for (btn in extraKeys)
			FlxDestroyUtil.destroy(btn);
		extraKeys = [];
	}
}
