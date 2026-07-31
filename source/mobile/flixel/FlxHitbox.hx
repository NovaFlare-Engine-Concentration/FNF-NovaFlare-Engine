﻿package mobile.flixel;

import openfl.Lib;
import openfl.display.Shape;
import openfl.display.BitmapData;
import flixel.input.keyboard.FlxKey;

import mobile.flixel.input.FlxMobileInputManager;
import mobile.flixel.FlxButton;

import general.backend.InputFormatter;

/**
 * A zone with dynamic hint's based on mania.
 * 
 * @author: Mihai Alexandru
 * @modification's author: Karim Akra & Lily (mcagabe19)
 */
class FlxHitbox extends FlxMobileInputManager
{
	public var buttonNotes:Array<FlxButton> = [];
	public var buttonExtra:Array<FlxButton> = [];

	/**
	 * Create the zone.
	 */
	public function new()
	{
		super();

		// Get mania value (default to 3 for 4K)
		var mania:Int = 3;
		if (PlayState.SONG != null && PlayState.SONG.mania != null)
		{
			mania = PlayState.SONG.mania;
		}
		var keys:Int = mania + 1; // Number of keys

		var stage = Lib.current.stage;

		var newWidth:Int;
		var newHeight:Int;

		if (ClientPrefs.data.useFlixelCoords)
		{
			newWidth = Std.int(FlxG.width);
			newHeight = Std.int(FlxG.height);
		}
		else
		{
			var scale:Float = Math.min(stage.stageWidth / 1280, stage.stageHeight / 720);
			newWidth = Std.int(stage.stageWidth / scale);
			newHeight = Std.int(stage.stageHeight / scale);
		}

		if (ClientPrefs.data.extraKey == 0)
		{
			for (i in 0...keys)
			{
				var button = createHint(newWidth * i / keys, 0, Std.int(newWidth / keys), Std.int(newHeight), getColor(i, mania));
				buttonNotes.push(button);
				add(button);
			}
		}
		else
		{
			if (ClientPrefs.data.hitboxLocation == 'Bottom')
			{

				for (i in 0...keys)
				{
					var button = createHint(newWidth * i / keys, 0, Std.int(newWidth / keys), Std.int(newHeight * 0.8), getColor(i, mania));
					buttonNotes.push(button);
					add(button);
				}

				for (i in 0...ClientPrefs.data.extraKey)
				{
					var button = createHint(i * Std.int(newWidth / ClientPrefs.data.extraKey), (newHeight / 5) * 4, Std.int(newWidth / ClientPrefs.data.extraKey), Std.int(newHeight / 5), 0xFFFF00);
					buttonExtra.push(button);
					add(button);
				}
			}
			else
			{
				for (i in 0...keys)
				{
					var button = createHint(newWidth * i / keys, newHeight * 0.2, Std.int(newWidth / keys), Std.int(newHeight * 0.8),
						getColor(i, mania));
					buttonNotes.push(button);
					add(button);
				}

				for (i in 0...ClientPrefs.data.extraKey)
				{
					var button = createHint(i * Std.int(newWidth / ClientPrefs.data.extraKey), 0, Std.int(newWidth / ClientPrefs.data.extraKey), Std.int(newHeight / 5), 0xFFFF00);
					buttonExtra.push(button);
					add(button);
				}
			}
		}

		for (i in 0...buttonNotes.length)
		{
			buttonNotes[i].IDs = getInputID(mania, i);
		}

		for (i in 0...buttonExtra.length)
		{
			buttonExtra[i].IDs = getExtraID(i);
		}

		scrollFactor.set();
		updateTrackedButtons();
	}

	/**
	 * Get input ID based on mania and index
	 */
	private function getInputID(mania:Int, index:Int):Array<FlxKey>
	{
		var key:String = '';
		if (mania == 3) {
			switch (index) {
				case 0: key = 'note_left';
				case 1: key = 'note_down';
				case 2: key = 'note_up';
				case 3: key = 'note_right';
			}
		} else {
			key = '${mania}_key_${index}';
		}

		if (ClientPrefs.keyBinds.exists(key))
			return ClientPrefs.keyBinds.get(key);

		return [];
	}

	/**
	 * Get extra key ID based on index
	 */
	private function getExtraID(index:Int):Array<FlxKey>
	{
		var groupData = [];
		index = Std.int(index + 1);
		groupData.push(InputFormatter.getFlxKey(Reflect.getProperty(ClientPrefs.data, 'extraKeyReturn' + index)));

		return groupData;
	}

	/**
	 * Get color for key based on index and mania
	 */
	private function getColor(index:Int, mania:Int):Int
	{
		// Origin mode does not initialize NovaFlare's ExtraKeysHandler. The
		// mobile controls selector still creates a FlxHitbox for its preview,
		// so treat the extra-keys palette as optional and use the built-in
		// four-colour fallback when it is unavailable.
		var extraKeysData = ExtraKeysHandler.instance == null ? null : ExtraKeysHandler.instance.data;
		var keyMode = extraKeysData != null
			&& extraKeysData.keys != null
			&& mania >= 0
			&& mania < extraKeysData.keys.length ? extraKeysData.keys[mania] : null;

		if (keyMode != null && keyMode.notes != null && index >= 0 && index < keyMode.notes.length)
		{
			var noteIndex = keyMode.notes[index];

			// 动态颜色设置优先
			if (ClientPrefs.data.dynamicColors
				&& ClientPrefs.data.arrowRGB != null
				&& noteIndex >= 0
				&& noteIndex < ClientPrefs.data.arrowRGB.length)
			{
				var rgb = ClientPrefs.data.arrowRGB[noteIndex];
				if (rgb != null && rgb.length > 0)
					return rgb[0];
			}

			// 使用extrakeys.json中的默认颜色
			if (extraKeysData.colors != null && noteIndex >= 0 && noteIndex < extraKeysData.colors.length)
			{
				var colorObj = extraKeysData.colors[noteIndex];
				if (colorObj != null && colorObj.inner != null)
				{
					var parsedColor = FlxColor.fromString('#' + colorObj.inner);
					if (parsedColor != null)
						return parsedColor;
				}
			}
		}

		return switch (mania)
		{
			case 0: 0xFFC24B99; // 1K - Purple
			case 1: index == 0 ? 0xFFC24B99 : 0xFFF9393F; // 2K - Purple/Red
			case 2: [0xFFC24B99, 0xFF12FA05, 0xFFF9393F][index]; // 3K - Purple/Green/Red
			default: [0xFFC24B99, 0xFF00FFFF, 0xFF12FA05, 0xFFF9393F][index % 4]; // 4K+ colors
		}
	}

	/**
	 * Clean up memory.
	 */
	override function destroy()
	{
		super.destroy();

		for (button in buttonNotes)
		{
			button = FlxDestroyUtil.destroy(button);
		}
		for (button in buttonExtra)
		{
			button = FlxDestroyUtil.destroy(button);
		}
	}

	private function createHint(X:Float, Y:Float, Width:Int, Height:Int, Color:Int = 0xFFFFFF):FlxButton
	{
		var hint = new FlxButton(X, Y);
		hint.loadGraphic(createHintGraphic(Width, Height));
		hint.color = Color;
		hint.solid = false;
		hint.immovable = true;
		hint.multiTouch = true;
		hint.moves = false;
		hint.scrollFactor.set();
		hint.alpha = 0.5;
		hint.antialiasing = ClientPrefs.data.antialiasing;
		
		if (ClientPrefs.data.playControlsAlpha >= 0)
		{
			hint.onDown.callback = function()
			{
				hint.alpha = ClientPrefs.data.playControlsAlpha;
			}
			hint.onUp.callback = function()
			{
				hint.alpha = 0.00001;
			}
			hint.onOut.callback = function()
			{
				hint.alpha = 0.00001;
			}
		}
		#if FLX_DEBUG
		hint.ignoreDrawDebug = true;
		#end
		return hint;
	}

	function createHintGraphic(Width:Int, Height:Int):BitmapData
	{
		var shape:Shape = new Shape();

		var guh = ClientPrefs.data.playControlsAlpha;
		if (guh >= 0.9)
			guh = ClientPrefs.data.playControlsAlpha - 0.07;

		shape.graphics.beginFill(0xFFFFFF);
		shape.graphics.lineStyle(3, 0xFFFFFF, 1);
		shape.graphics.drawRect(0, 0, Width, Height);
		shape.graphics.lineStyle(0, 0, 0);
		shape.graphics.drawRect(3, 3, Width - 6, Height - 6);
		shape.graphics.endFill();
		shape.graphics.drawRect(3, 3, Width - 6, Height - 6);
		shape.graphics.endFill();

		var bitmap:BitmapData = new BitmapData(Width, Height, true, 0);
		bitmap.draw(shape);
		return bitmap;
	}
}

