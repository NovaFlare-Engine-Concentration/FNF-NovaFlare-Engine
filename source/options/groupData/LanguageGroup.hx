package options.groupData;

class LanguageGroup extends OptionCata
{
	public function new(X:Float, Y:Float, width:Float, height:Float)
	{
		super(X, Y, width, height);

		var option:Option = new Option(this, 'Language', TITLE);
		addOption(option);

		var langArray:Array<String> = languageArray();
		var option:Option = new Option(this, 'language', STRING, langArray);
		addOption(option);
		option.onChange = onChangeLanguage;

		changeHeight(0);
	}

	function languageArray():Array<String>
	{
		var output:Array<String> = [];
		var contents:Array<String> = FileSystem.readDirectory(Paths.getPath('language'));
		for (item in contents)
		{
			if (item == "JustSay")
				continue;
			var itemPath = Paths.getPath('language') + '/' + item;
			if (FileSystem.isDirectory(itemPath))
			{
				output.push(item);
			}
		}
		Language.check();
		return output;
	}

	function onChangeLanguage()
	{
		Language.resetData();
		OptionsState.instance.changeLanguage();
		optionArray[1].changeLangNation();
	}
}
