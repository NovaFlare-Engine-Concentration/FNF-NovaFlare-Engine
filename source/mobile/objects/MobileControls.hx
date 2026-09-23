package mobile.objects;

import haxe.ds.Map;
import haxe.extern.EitherType;

import mobile.flixel.input.FlxMobileInputManager;
import mobile.flixel.FlxButton;

class MobileControls extends FlxTypedSpriteGroup<FlxMobileInputManager>
{
	public var virtualPad:FlxVirtualPad = new FlxVirtualPad(NONE, NONE);
	public var hitbox:FlxHitbox = new FlxHitbox();
	// YOU CAN'T CHANGE PROPERTIES USING THIS EXCEPT WHEN IN RUNTIME!!
	public var current:CurrentManager;

	public static var mode(get, set):Int;
	public static var forcedControl:Null<Int>;

	public function new(?forceType:Int, ?extra:Bool = true)
	{
		super();

		if (forceType != null)
			forcedControl = forceType;
		else
			forcedControl = get_mode();

		switch (forcedControl)
		{
			case 0: // RIGHT_FULL
				initControler(0);
			case 1: // LEFT_FULL
				initControler(1);
			case 2: // CUSTOM
				initControler(2);
			case 3: // BOTH
				initControler(3);
			case 4: // HITBOX
				initControler(4);
			case 5: // KEYBOARD
		}
		current = new CurrentManager(this);
		// Options related stuff
		// alpha = ClientPrefs.data.controlsAlpha;
		if (forcedControl != 5) updateButtonsColors();
	}

	private function initControler(virtualPadMode:Int = 0):Void
	{
		switch (virtualPadMode)
		{
			case 0:
				virtualPad = new FlxVirtualPad(RIGHT_FULL_GAME, controlExtend);
				add(virtualPad);
				virtualPad = getExtraCustomMode(virtualPad);
			case 1:
				virtualPad = new FlxVirtualPad(LEFT_FULL_GAME, controlExtend);
				add(virtualPad);
				virtualPad = getExtraCustomMode(virtualPad);
			case 2:
				virtualPad = new FlxVirtualPad(RIGHT_FULL_GAME, controlExtend);
				virtualPad = getCustomMode(virtualPad);
				virtualPad = getExtraCustomMode(virtualPad);
				add(virtualPad);
			case 3:
				virtualPad = new FlxVirtualPad(BOTH_GAME, controlExtend);
				add(virtualPad);
				virtualPad = getExtraCustomMode(virtualPad);
			case 4:
				hitbox = new FlxHitbox();
				add(hitbox);
		}
	}

	public static function setCustomMode(virtualPad:FlxVirtualPad):Void
	{
		if (FlxG.save.data.buttons == null)
		{
			FlxG.save.data.buttons = new Array();
			for (buttons in virtualPad)
				FlxG.save.data.buttons.push({x: buttons.x, y: buttons.y});
		}
		else
		{
			var tempCount:Int = 0;
			for (buttons in virtualPad)
			{
				FlxG.save.data.buttons[tempCount] = {x: buttons.x, y: buttons.y};
				tempCount++;
			}
		}

		FlxG.save.flush();
	}

	public static function getCustomMode(virtualPad:FlxVirtualPad):FlxVirtualPad
	{
		var tempCount:Int = 0;

		if (FlxG.save.data.buttons == null)
			return virtualPad;

		for (buttons in virtualPad)
		{
			if (FlxG.save.data.buttons[tempCount] != null)
			{
				buttons.x = FlxG.save.data.buttons[tempCount].x;
				buttons.y = FlxG.save.data.buttons[tempCount].y;
			}
			tempCount++;
		}

		return virtualPad;
	}

	// NOTE: store plain `{x, y}` objects here, never `FlxPoint` instances.
	// `FlxPoint` is an abstract over the runtime `flixel.math.FlxBasePoint` class, so a
	// FlxPoint pushed into save data is serialized as a `FlxBasePoint` class instance
	// (with its pool internals `_weak` / `_inPool` and its computed properties). Loading
	// it back requires haxe.Unserializer to rebuild that class instance, which does not
	// succeed, and the failure is not limited to this one field: the whole save file
	// becomes unreadable. `FlxSave.bind()` then returns false and leaves
	// `FlxG.save.data` null, so the next `FlxG.save.data.<field>` read crashes the engine
	// with EXCEPTION_ACCESS_VIOLATION during boot. Anonymous `{x, y}` objects are plain
	// data and always serialize/unserialize cleanly.
	public static function setExtraCustomMode(virtualPad:FlxVirtualPad):Void
	{
		if (FlxG.save.data.extraButtons == null)
		{
			FlxG.save.data.extraButtons = new Array();
			for (btn in virtualPad.extraKeys)
				FlxG.save.data.extraButtons.push({x: btn.x, y: btn.y});
		}
		else
		{
			var tempCount:Int = 0;
			for (btn in virtualPad.extraKeys)
			{
				FlxG.save.data.extraButtons[tempCount] = {x: btn.x, y: btn.y};
				tempCount++;
			}
		}

		FlxG.save.flush();
	}

	public static function getExtraCustomMode(virtualPad:FlxVirtualPad):FlxVirtualPad
	{
		var tempCount:Int = 0;

		if (FlxG.save.data.extraButtons == null)
			return virtualPad;

		for (btn in virtualPad.extraKeys)
		{
			if (FlxG.save.data.extraButtons[tempCount] != null)
			{
				btn.x = FlxG.save.data.extraButtons[tempCount].x;
				btn.y = FlxG.save.data.extraButtons[tempCount].y;
			}
			tempCount++;
		}

		return virtualPad;
	}

	override public function destroy():Void
	{
		super.destroy();

		if (virtualPad != null)
		{
			virtualPad = FlxDestroyUtil.destroy(virtualPad);
			virtualPad = null;
		}

		if (hitbox != null)
		{
			hitbox = FlxDestroyUtil.destroy(hitbox);
			hitbox = null;
		}
	}

	public static function set_mode(mode:Int = 0)
	{
		FlxG.save.data.mobileControlsMode = mode;
		FlxG.save.flush();
		return mode;
	}

	public static function get_mode():Int
	{
		if (FlxG.save.data.mobileControlsMode == null)
		{
			FlxG.save.data.mobileControlsMode = 0;
			FlxG.save.flush();
		}

		return FlxG.save.data.mobileControlsMode;
	}

	public function updateButtonsColors()
	{
		// Dynamic Controls Color
		var buttonsColors:Array<FlxColor> = [];
		var data:Dynamic;
		if (ClientPrefs.data.dynamicColors)
			data = ClientPrefs.data;
		else
			data = ClientPrefs.defaultData;

		// ★ 防御：配色表可能少于 4 项（老存档 / 模组只提供部分配色）—— 旧代码直接
		//   `data.arrowRGB[3][0]` 会越界读到 null 继而 NPE。
		var tbl:Array<Array<FlxColor>> = data.arrowRGB;
		for (i in 0...4)
		{
			var row:Array<FlxColor> = null;
			if (tbl != null && tbl.length > 0)
			{
				var idx:Int = (i < tbl.length) ? i : tbl.length - 1;
				row = tbl[idx];
			}
			buttonsColors.push((row != null && row.length > 0) ? row[0] : 0xFFFFFFFF);
		}
		if (mode == 3)
		{
			virtualPad.buttonLeft2.color = buttonsColors[0];
			virtualPad.buttonDown2.color = buttonsColors[1];
			virtualPad.buttonUp2.color = buttonsColors[2];
			virtualPad.buttonRight2.color = buttonsColors[3];
		}
		current.buttonLeft.color = buttonsColors[0];
		current.buttonDown.color = buttonsColors[1];
		current.buttonUp.color = buttonsColors[2];
		current.buttonRight.color = buttonsColors[3];
	}
}

class CurrentManager
{
	public var buttonLeft:FlxButton;
	public var buttonDown:FlxButton;
	public var buttonUp:FlxButton;
	public var buttonRight:FlxButton;
	public var target:FlxMobileInputManager;

	public function new(control:MobileControls)
	{
		if (MobileControls.mode == 4)
		{
			target = control.hitbox;
			// Use buttonNotes array instead of individual button fields
			buttonLeft = control.hitbox.buttonNotes[0];
			buttonDown = control.hitbox.buttonNotes[1];
			buttonUp = control.hitbox.buttonNotes[2];
			buttonRight = control.hitbox.buttonNotes[3];
		}
		else
		{
			target = control.virtualPad;
			buttonLeft = control.virtualPad.buttonLeft;
			buttonDown = control.virtualPad.buttonDown;
			buttonUp = control.virtualPad.buttonUp;
			buttonRight = control.virtualPad.buttonRight;
		}
	}
}
