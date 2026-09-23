package general.backend.language;

class CustomLangGroup
{
	public var groupName:String;
	public var data:Map<String, String> = [];
	public var defaultData:Map<String, String> = [];

	public function new(groupName:String)
	{
		this.groupName = groupName;
	}

	public function get(value:String):String
	{
		if (data.get(value) != null)
			return data.get(value);
		else if (defaultData.get(value) != null)
			return defaultData.get(value);
		else
			return ClientPrefs.data.developerMode ? value + ' (404)' : value;
	}

	public function updateLang()
	{
		data.clear();
		defaultData.clear();

		var minorPath:String = '/' + groupName;
		var directoryPath:Array<String> = [Paths.getPath('language') + '/English' + minorPath];

		// 无条件加入当前语言目录：桌面由 setupData 的 FileSystem 分支判存在性，
		// 移动端 assets 不可列目录（FileSystem.isDirectory 恒 false），
		// 交给 setupData 的资源清单回退处理
		directoryPath.push(Paths.getPath('language') + '/' + ClientPrefs.data.language + minorPath);

		Language.setupData(this, directoryPath);
	}
}
