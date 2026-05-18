package options.groupData;

class InterfaceGroup extends OptionCata
{
	public function new(X:Float, Y:Float, width:Float, height:Float)
	{
		super(X, Y, width, height);

		var option:Option = new Option(this, 'User Interface', TITLE);
		addOption(option);
		
		var CustomFadeArray:Array<String> = ['Move', 'Alpha'];
		var option:Option = new Option(this, 'customFade', STRING, CustomFadeArray);
		addOption(option);

		var option:Option = new Option(this, 'customFadeText', BOOL);
		addOption(option);

		var option:Option = new Option(this, 'customFadeSound', FLOAT, [0, 1, 1]);
		addOption(option);

		var option:Option = new Option(this, 'skipTitleVideo', BOOL);
		addOption(option);

		var option:Option = new Option(this, 'resultsScreen', BOOL);
		addOption(option);

		var option:Option = new Option(this, 'loadingScreen', BOOL);
		addOption(option);

		changeHeight(0); //初始化真正的height
	}
}
