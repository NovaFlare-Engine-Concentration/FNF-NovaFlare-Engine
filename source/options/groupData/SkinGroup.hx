package options.groupData;

class SkinGroup extends OptionCata
{
	public function new(X:Float, Y:Float, width:Float, height:Float)
	{
		super(X, Y, width, height);

		var option:Option = new Option(this, 'Skin', TITLE);
		addOption(option);

		var option:Option = new Option(this, 'Note', TEXT);
		addOption(option);

		var noteSkins:Array<String> = addNoteSkins();

		if (noteSkins.length > 0)
		{
			noteSkins.insert(0, ClientPrefs.defaultData.noteSkin);

			var option:Option = new Option(this, 'noteSkin', STRING, noteSkins);
			addOption(option);
		}

		// 着色体系三态：auto = 谱面皮肤优先 + 自动甄别 / legacy = 沿用谱面皮肤 + 强制 HSV /
		// new = 忽略谱面皮肤（换玩家皮肤）+ 强制 RGB。取代旧的 noteRGB + noteColorSwap 两个开关。
		var option:Option = new Option(this, 'noteSystem', STRING, [NOTE_SYSTEM_VALUES, noteSystemNames()]);
		addOption(option);

		var option:Option = new Option(this, 'NotesSubState', STATE);
		option.onChange = function() { changeState(2); };
		addOption(option);

		// 只对 legacy（烤色）贴图生效的 HSV 调色板
		var option:Option = new Option(this, 'NotesSubStateLegacy', STATE);
		option.onChange = function() { changeState(7); };
		addOption(option);

		/////--Splash--\\\\\

		var option:Option = new Option(this, 'Splash', TEXT);
		addOption(option);

		var option:Option = new Option(this, 'showSplash', BOOL);
		addOption(option);

		var noteSplashes:Array<String> = addNoteSplashes();
		if (noteSplashes.length > 0)
		{
			noteSplashes.insert(0, ClientPrefs.defaultData.splashSkin);

			var option:Option = new Option(this, 'splashSkin', STRING, noteSplashes);
			addOption(option);
		}

		var option:Option = new Option(this, 'splashSystem', STRING, [NOTE_SYSTEM_VALUES, noteSystemNames()]);
		addOption(option);

		var option:Option = new Option(this, 'splashAlpha', FLOAT, [0, 1, 1]);
		addOption(option);

		changeHeight(0); //初始化真正的height
	}

	// 三态的取值顺序；显示名走 lang，顺序必须一一对应
	static var NOTE_SYSTEM_VALUES:Array<String> = ['auto', 'legacy', 'new'];

	static function noteSystemNames():Array<String>
	{
		return [
			Language.get('noteSystem-auto', 'options'),
			Language.get('noteSystem-legacy', 'options'),
			Language.get('noteSystem-new', 'options')
		];
	}

	function addNoteSkins():Array<String> {
		var output:Array<String> = [];
		if (Mods.mergeAllTextsNamed('images/noteSkins/list.txt', 'shared').length > 0)
			output = Mods.mergeAllTextsNamed('images/noteSkins/list.txt', 'shared');
		else
			output = CoolUtil.coolTextFile(Paths.getSharedPath('images/noteSkins/list.txt'));
		return output;
	}

	function addNoteSplashes():Array<String> {
		var output:Array<String> = [];
		if (Mods.mergeAllTextsNamed('images/noteSplashes/list.txt', 'shared').length > 0)
			output = Mods.mergeAllTextsNamed('images/noteSplashes/list.txt', 'shared');
		else
			output = CoolUtil.coolTextFile(Paths.getSharedPath('images/noteSplashes/list.txt'));
		return output;
	}
	
	function changeState(type:Int) {
		OptionsState.instance.moveState(type);
	}
}
