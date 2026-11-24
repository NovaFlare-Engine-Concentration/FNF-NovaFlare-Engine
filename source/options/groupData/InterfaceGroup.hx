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
		

		var option:Option = new Option(this, 'audioDisplayQuality', INT, [1, 4]);
		addOption(option);

		var option:Option = new Option(this, 'audioDisplayUpdate', INT, [0, 200, 'MS']);
		addOption(option);

		var option:Option = new Option(this, 'skipTitleVideo', BOOL);
		addOption(option);

		var option:Option = new Option(this, 'loadingScreen', BOOL);
		addOption(option);

		ClientPrefs.data.loadThreads = CoolUtil.loadingThreadCount(ClientPrefs.data.loadThreads);
		var option:Option = new Option(this, 'loadThreads', INT, [1, CoolUtil.maxLoadingThreads(), ' Thread']);
		option.onChange = () -> validateLoadingThreads(option);
		addOption(option);

		var option:Option = new Option(this, 'useFlixelCoords', BOOL);
		addOption(option);

		var option:Option = new Option(this, 'SelectGameSubState', STATE);
		option.onChange = function() { changeState(8); };
		addOption(option);

		changeHeight(0); //初始化真正的height
	}

	function changeState(type:Int) {
		OptionsState.instance.moveState(type);
	}

	function validateLoadingThreads(option:Option):Void {
		final threads = CoolUtil.loadingThreadCount(ClientPrefs.data.loadThreads);
		if (threads == ClientPrefs.data.loadThreads) return;
		option.setValue(threads);
		option.refreshNumericDisplay();
	}
}
