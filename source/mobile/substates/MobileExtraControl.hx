package mobile.substates;

import flixel.effects.FlxFlicker;

class MobileExtraControl extends MusicBeatSubstate
{
	var returnArray:Array<Array<String>> = [
		['Esc', '', 'F1', 'F2', 'F3', 'F4', '', 'F5', 'F6', 'F7', 'F8', '', 'F9', 'F10', 'F11', 'F12', '', 'PrtScrn', 'ScrLk', 'Break'],
		['`', '1', '2', '3', '4', '5', '6', '7', '8', '9', '0', '-', '+', 'BckSpc', '', 'Ins', 'Home', 'PgUp', '', 'NumLk', '#/', '#*', '#-'],
		['Tab', 'Q', 'W', 'E', 'R', 'T', 'Y', 'U', 'I', 'O', 'P', '[', ']', '\\', '', 'Del', 'End', 'PgDown', '', '#7', '#8', '#9', '#+'],
		['Caps', 'A', 'S', 'D', 'F', 'G', 'H', 'J', 'K', 'L', ';', "'", 'Enter', '', '', '', '', '', '#4', '#5', '#6', ''],
		['Shift', 'Z', 'X', 'C', 'V', 'B', 'N', 'M', ',', '.', '/', 'Shift', '', '', 'Up', '', '', '#1', '#2', '#3', ''],
		['Ctrl', 'Win', 'Alt', 'Space', 'Alt', 'Win', 'Menu', 'Ctrl', '', 'Left', 'Down', 'Right', '', '#0', '#.', ''],
	];

	var displayArray:Array<Array<String>> = [
		['Esc', '', 'F1', 'F2', 'F3', 'F4', '', 'F5', 'F6', 'F7', 'F8', '', 'F9', 'F10', 'F11', 'F12', '', 'Prt\nScrn', 'Scr\nLk', 'Break'],
		['`', '1', '2', '3', '4', '5', '6', '7', '8', '9', '0', '-', '+', 'Back\nSpace', '', 'Ins', 'Home', 'Pg\nUp', '', 'Num\nLk', '#/', '#*', '#-'],
		['Tab', 'Q', 'W', 'E', 'R', 'T', 'Y', 'U', 'I', 'O', 'P', '[', ']', '\\', '', 'Del', 'End', 'Pg\nDown', '', '#7', '#8', '#9', '#+'],
		['Caps', 'A', 'S', 'D', 'F', 'G', 'H', 'J', 'K', 'L', ';', "'", 'Enter', '', '', '', '', '', '#4', '#5', '#6', ''],
		['Shift', 'Z', 'X', 'C', 'V', 'B', 'N', 'M', ',', '.', '/', 'Shift', '', '', 'Up', '', '', '#1', '#2', '#3', ''],
		['Ctrl', 'Win', 'Alt', 'Space', 'Alt', 'Win', 'Menu', 'Ctrl', '', 'Left', 'Down', 'Right', '', '#0', '#.', ''],
	];

	var widthUnits:Array<Array<Float>> = [
		[1, 1.5, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1.5, 1.25, 1.25, 1.25],
		[1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2, 1.5, 1, 1, 1, 1.5, 1, 1, 1, 1],
		[1.5, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1.5, 1.5, 1, 1, 1, 1.5, 1, 1, 1, 1],
		[1.75, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2.37, 1.5, 1, 1, 1, 1.5, 1, 1, 1, 1],
		[2.25, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2.96, 1.5, 1, 1, 1, 1.5, 1, 1, 1, 1],
		[1.25, 1.25, 1.25, 6.25, 1.25, 1.25, 1.25, 2, 1.5, 1, 1, 1, 1.5, 2.2, 1, 1],
	];

	var titleTeam:FlxTypedGroup<ChooseButton>;
	var optionTeam:FlxTypedGroup<ChooseButton>;

	var isMain:Bool = true;

	var titleNum:Int = 0;
	var typeNum:Int = 0;
	var chooseNum:Int = 0;

	var rowSelectableIndices:Array<Array<Int>> = [];
	var selectableButtons:Array<ChooseButton> = [];
	var selectableReturnKeys:Array<String> = [];

	var titleWidth:Int = 200;
	var titleHeight:Int = 100;

	var optionWidth:Int = 80;
	var optionHeight:Int = 30;

	override function create()
	{
		// ★ 关键：子状态的 cameras 必须是主相机（FlxG.camera），不能是最后一个相机
		//   理由同 KeyBindsSubState：沉浸界面下最后相机 = chromeCam，自绘「NovaFlare Engine」条挂在它上面。
		//   与 chromeCam 共用会按 z-顺序被键盘选择 UI 盖住，改成主相机 → chromeCam 最后绘制 → 顶栏按钮始终可见。
		cameras = [FlxG.camera];

		var bg:FlxSprite = new FlxSprite(0, 0).makeGraphic(FlxG.width, FlxG.height, FlxColor.WHITE);
		bg.scrollFactor.set();
		bg.alpha = 0.5;
		add(bg);

		titleTeam = new FlxTypedGroup<ChooseButton>();
		add(titleTeam);

		for (i in 1...5)
		{
			var data:String = Reflect.field(ClientPrefs.data, "extraKeyReturn" + i);
			var _x = FlxG.width / 2 + 25 + (titleWidth + 50) * ((i - 1) - 4 / 2);
			var titleObject = new ChooseButton(_x, 150, titleWidth, titleHeight, data, "Key " + Std.string(i));
			titleTeam.add(titleObject);
		}

		optionTeam = new FlxTypedGroup<ChooseButton>();
		add(optionTeam);

		var gap:Float = 6;
		var margin:Float = 20;
		var unit:Float = 99999;
		for (row in 0...widthUnits.length)
		{
			var totalUnits:Float = 0;
			for (u in widthUnits[row])
				totalUnits += u;
			var available:Float = FlxG.width - margin * 2 - gap * (widthUnits[row].length - 1);
			unit = Math.min(unit, available / totalUnits);
		}
		unit = Math.max(18, Math.min(60, unit));
		var maxRowWidth:Float = 0;
		for (row in 0...widthUnits.length)
		{
			var totalUnits:Float = 0;
			for (u in widthUnits[row])
				totalUnits += u;
			var rowWidth:Float = totalUnits * unit + gap * (widthUnits[row].length - 1);
			maxRowWidth = Math.max(maxRowWidth, rowWidth);
		}
		var keyHeight:Int = Std.int(Math.max(24, Math.min(44, unit * 0.85)));
		var rowGap:Float = 8;
		var startY:Float = 285;
		var startX:Float = (FlxG.width - maxRowWidth) / 2;

		rowSelectableIndices = [];
		selectableButtons = [];
		selectableReturnKeys = [];

		for (row in 0...returnArray.length)
		{
			rowSelectableIndices.push([]);
			var x:Float = startX;
			var y:Float = startY + (keyHeight + rowGap) * row;

			for (col in 0...returnArray[row].length)
			{
				var w:Int = Std.int(unit * widthUnits[row][col]);
				var returnKey:String = returnArray[row][col];
				if (returnKey != null && returnKey != '')
				{
					var h:Int = keyHeight;
					if (returnKey == '#+')
						h = keyHeight * 2 + Std.int(rowGap);
					var titleObject = new ChooseButton(x, y, w, h, displayArray[row][col]);
					optionTeam.add(titleObject);
					rowSelectableIndices[row].push(selectableButtons.length);
					selectableButtons.push(titleObject);
					selectableReturnKeys.push(returnKey);
				}
				x += w + gap;
			}
		}

		updateTitle(titleNum + 1, true, 0);

		addVirtualPad(OptionStateC, OptionStateC);
		addVirtualPadCamera(false);

		super.create();
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		var accept = controls.ACCEPT;
		var right = controls.UI_RIGHT_P;
		var left = controls.UI_LEFT_P;
		var up = controls.UI_UP_P;
		var down = controls.UI_DOWN_P;
		var back = controls.BACK;
		var reset = controls.RESET || (virtualPad != null && virtualPad.buttonC.justPressed);

		if (left || right)
		{
			if (isMain)
			{
				titleNum += left ? -1 : 1;
				if (titleNum > 3)
					titleNum = 0;
				if (titleNum < 0)
					titleNum = 3;
				updateTitle(titleNum + 1, true, 1);
			}
			else
			{
				chooseNum += left ? -1 : 1;
				var rowLen = rowSelectableIndices[typeNum].length;
				if (rowLen <= 0)
					chooseNum = 0;
				else
				{
					if (chooseNum > rowLen - 1)
						chooseNum = 0;
					if (chooseNum < 0)
						chooseNum = rowLen - 1;
				}
				updateChoose();
			}
		}

		if (up || down)
		{
			if (!isMain)
			{
				var curRow = typeNum;
				var curPos = chooseNum;
				var curIndex:Int = 0;
				if (rowSelectableIndices[curRow].length > 0)
					curIndex = rowSelectableIndices[curRow][curPos];

				var curX:Float = 0;
				if (selectableButtons.length > 0 && curIndex >= 0 && curIndex < selectableButtons.length)
				{
					var btn = selectableButtons[curIndex];
					curX = btn.x + btn.bg.width / 2;
				}

				typeNum += up ? -1 : 1;
				if (typeNum > rowSelectableIndices.length - 1)
					typeNum = 0;
				if (typeNum < 0)
					typeNum = rowSelectableIndices.length - 1;

				var safety:Int = 0;
				while (rowSelectableIndices[typeNum].length <= 0 && safety < rowSelectableIndices.length + 1)
				{
					typeNum += up ? -1 : 1;
					if (typeNum > rowSelectableIndices.length - 1)
						typeNum = 0;
					if (typeNum < 0)
						typeNum = rowSelectableIndices.length - 1;
					safety++;
				}

				var best:Int = 0;
				var bestDist:Float = 999999;
				for (i in 0...rowSelectableIndices[typeNum].length)
				{
					var idx = rowSelectableIndices[typeNum][i];
					var b = selectableButtons[idx];
					var bx = b.x + b.bg.width / 2;
					var d = Math.abs(bx - curX);
					if (d < bestDist)
					{
						bestDist = d;
						best = i;
					}
				}
				chooseNum = best;
				updateChoose();
			}
		}

		if (accept)
		{
			if (isMain)
			{
				isMain = false;
				updateChoose();
			}
			else
			{
				var rowLen = rowSelectableIndices[typeNum].length;
				if (rowLen <= 0)
					return;
				if (chooseNum < 0)
					chooseNum = 0;
				if (chooseNum > rowLen - 1)
					chooseNum = rowLen - 1;
				var realIndex = rowSelectableIndices[typeNum][chooseNum];
				var chosenKey = selectableReturnKeys[realIndex];
				switch (titleNum + 1)
				{
					case 1:
						ClientPrefs.data.extraKeyReturn1 = chosenKey;
					case 2:
						ClientPrefs.data.extraKeyReturn2 = chosenKey;
					case 3:
						ClientPrefs.data.extraKeyReturn3 = chosenKey;
					case 4:
						ClientPrefs.data.extraKeyReturn4 = chosenKey;
				}
				ClientPrefs.saveSettings();
				updateTitle(titleNum + 1, false, 2, true);
			}
		}

		if (back)
		{
			if (isMain)
			{
				ClientPrefs.saveSettings();
				FlxTransitionableState.skipNextTransIn = true;
				FlxTransitionableState.skipNextTransOut = true;
				MusicBeatState.switchState(new options.OptionsState());
			}
			else
			{
				isMain = true;
				chooseNum = typeNum = 0;
				updateChoose();
			}
		}
		if (reset)
		{
			FlxG.sound.play(Paths.sound('cancelMenu'));
			ClientPrefs.data.extraKeyReturn1 = ClientPrefs.defaultData.extraKeyReturn1;
			ClientPrefs.data.extraKeyReturn2 = ClientPrefs.defaultData.extraKeyReturn2;
			ClientPrefs.data.extraKeyReturn3 = ClientPrefs.defaultData.extraKeyReturn3;
			ClientPrefs.data.extraKeyReturn4 = ClientPrefs.defaultData.extraKeyReturn4;
			resetTitle();
		}
	}

	function updateChoose(soundsType:Int = 0)
	{
		FlxG.sound.play(Paths.sound('scrollMenu'));
		for (i in 0...selectableButtons.length)
			selectableButtons[i].changeColor(FlxColor.BLACK);

		if (isMain)
			return;

		if (typeNum < 0 || typeNum > rowSelectableIndices.length - 1)
			return;
		if (rowSelectableIndices[typeNum].length <= 0)
			return;
		if (chooseNum < 0)
			chooseNum = 0;
		if (chooseNum > rowSelectableIndices[typeNum].length - 1)
			chooseNum = rowSelectableIndices[typeNum].length - 1;

		var idx = rowSelectableIndices[typeNum][chooseNum];
		selectableButtons[idx].changeColor(FlxColor.WHITE);
	}

	function updateTitle(number:Int = 0, changeBG:Bool = false, soundsType:Int = 0, needFlicker:Bool = false)
	{
		switch (soundsType)
		{
			case 0: // nothing happened
			case 1:
				FlxG.sound.play(Paths.sound('scrollMenu'));
			case 2:
				FlxG.sound.play(Paths.sound('confirmMenu'));
		}

		for (i in 0...titleTeam.length)
		{
			var title:ChooseButton = titleTeam.members[i];

			if (i == titleNum)
			{
				title.changeExtraText(Reflect.field(ClientPrefs.data, "extraKeyReturn" + number));
				if (needFlicker)
					FlxFlicker.flicker(title, 0.6, 0.075, true, true);
				if (changeBG)
					title.changeColor(FlxColor.WHITE);
			}
			else
			{
				if (changeBG)
					title.changeColor(FlxColor.BLACK);
			}
		}
	}

	function resetTitle()
	{
		for (i in 0...titleTeam.length)
		{
			var title:ChooseButton = titleTeam.members[i];
			var number = i + 1;
			title.changeExtraText(Reflect.field(ClientPrefs.data, "extraKeyReturn" + number));
		}
	}
}

class ChooseButton extends FlxSpriteGroup
{
	public var bg:FlxSprite;
	public var titleObject:FlxText;
	public var extendTitleObject:FlxText;

	public function new(x:Float, y:Float, width:Int, height:Int, title:String, ?extendTitle:String = null)
	{
		super(x, y);

		bg = new FlxSprite(0, 0).makeGraphic(width, height, FlxColor.WHITE);
		bg.color = FlxColor.BLACK;
		bg.alpha = 0.4;
		bg.scrollFactor.set();
		add(bg);

		titleObject = new FlxText(0, 0, width, title);
		titleObject.setFormat("VCR OSD Mono", 20, FlxColor.WHITE, FlxTextAlign.CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		titleObject.antialiasing = ClientPrefs.data.antialiasing;
		titleObject.borderSize = 2;
		titleObject.x = bg.width / 2 - titleObject.width / 2;
		titleObject.y = bg.height / 2 - titleObject.height / 2;
		add(titleObject);

		if (extendTitle != null)
		{
			extendTitleObject = new FlxText(0, 0, width, extendTitle);
			extendTitleObject.setFormat("VCR OSD Mono", 30, FlxColor.WHITE, FlxTextAlign.CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			extendTitleObject.antialiasing = ClientPrefs.data.antialiasing;
			extendTitleObject.borderSize = 2;
			extendTitleObject.x = bg.width / 2 - extendTitleObject.width / 2;
			extendTitleObject.y = 30;
			add(extendTitleObject);

			titleObject.y = extendTitleObject.y + 30;
		}
	}

	public function changeColor(color:FlxColor)
	{
		bg.color = color;
		bg.alpha = 0.4;
	}

	public function changeExtraText(text:String)
	{
		titleObject.text = text;
	}
}
