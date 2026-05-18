package options.groupData;

class UIGroup extends OptionCata
{
	public function new(X:Float, Y:Float, width:Float, height:Float)
	{
		super(X, Y, width, height);

		var option:Option = new Option(this, 'GameUI', TITLE);
		addOption(option);
		
		/////--Visble--\\\\\

		var option:Option = new Option(this, 'Visble', TEXT);
		addOption(option);

		var option:Option = new Option(this, 'hideHud', BOOL);
		addOption(option);

		var option:Option = new Option(this, 'showComboNum', BOOL);
		addOption(option);

		var option:Option = new Option(this, 'showRating', BOOL);
		addOption(option);

		var option:Option = new Option(this, 'opponentStrums', BOOL);
		addOption(option);

		var option:Option = new Option(this, 'judgementCounter', BOOL);
		addOption(option);

		var option:Option = new Option(this, 'keyboardViewer', BOOL);
		addOption(option);

		/////--TimeBar--\\\\\

		var option:Option = new Option(this, 'TimeBar', TEXT);
		addOption(option);

		var TimeBarArray:Array<String> = ['Time Left', 'Time Elapsed', 'Song Name', 'Disabled'];
		var option:Option = new Option(this, 'timeBarType', STRING, TimeBarArray);
		addOption(option);

		/////--HealthBar--\\\\\

		var option:Option = new Option(this, 'HealthBar', TEXT);
		addOption(option);

		var option:Option = new Option(this, 'healthBarAlpha', FLOAT, [0, 1, 1]);
		addOption(option);

		var option:Option = new Option(this, 'oldHealthBarVersion', BOOL);
		addOption(option);

		/////--Combo--\\\\\

		var option:Option = new Option(this, 'Combo', TEXT);
		addOption(option);

		var option:Option = new Option(this, 'comboColor', BOOL);
		addOption(option);

		var option:Option = new Option(this, 'comboOffsetFix', BOOL);
		addOption(option);
		
		/////--KeyBoard--\\\\\
		
		var option:Option = new Option(this, 'KeyBoard', TEXT);
		addOption(option);

		var option:Option = new Option(this, 'keyboardTimeDisplay', BOOL);
		addOption(option);

		var option:Option = new Option(this, 'keyboardAlpha', FLOAT, [0, 1, 1]);
		addOption(option);

		var option:Option = new Option(this, 'keyboardTime', INT, [0, 1000, 'MS']);
		addOption(option);

		var colorStingArray = [
			'BLACK', 'WHITE', 'GRAY', 'RED', 'GREEN', 'BLUE', 'YELLOW', 'PINK', 'ORANGE', 'PURPLE', 'BROWN', 'CYAN'
		];

		var option:Option = new Option(this, 'keyboardBGColor', STRING, colorStingArray);
		addOption(option);

		var option:Option = new Option(this, 'keyboardTextColor', STRING, colorStingArray);
		addOption(option);
		
		/////--Camera--\\\\\
		
		var option:Option = new Option(this, 'Camera', TEXT);
		addOption(option);

		var option:Option = new Option(this, 'camZooms', BOOL);
		addOption(option);

		var option:Option = new Option(this, 'scoreZoom', BOOL);
		addOption(option);

		/////--PauseButton--\\\\\

		var option:Option = new Option(this, 'pauseButton', BOOL);
		addOption(option);

		var option:Option = new Option(this, 'CompulsionPause', BOOL);
		addOption(option);

		var option:Option = new Option(this, 'CompulsionPauseNumber', INT, [1, 10]);
		addOption(option);

		changeHeight(0); //初始化真正的height
	}
}
