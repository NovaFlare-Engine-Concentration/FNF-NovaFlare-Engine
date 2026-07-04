package options.groupData;

class FEFeaturesGroup extends OptionCata
{
	public function new(X:Float, Y:Float, width:Float, height:Float)
	{
		super(X, Y, width, height);

		var option:Option = new Option(this, 'FEFeatures', TITLE);
		addOption(option);

		var option:Option = new Option(this, 'showMS', BOOL);
		addOption(option);

		var option:Option = new Option(this, 'hitErrorBarVisible', BOOL);
		addOption(option);

		var option:Option = new Option(this, 'hitBarLines', INT, [0, 20, 1]);
		addOption(option);	

		var option:Option = new Option(this, 'hitBarLineTime', FLOAT, [0.1, 5, 0.1]);
		addOption(option);

		var option:Option = new Option(this, 'hitErrorBarOffsetX', FLOAT, [-200, 200, 1]);
		addOption(option);

		var option:Option = new Option(this, 'hitErrorBarOffsetY', FLOAT, [-200, 200, 1]);
		addOption(option);

		var option:Option = new Option(this, 'guideLineAlpha', FLOAT, [0, 1, 0.01]);
		addOption(option);

		changeHeight(0);
	}

}
