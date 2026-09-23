package general.backend.language;

/**
 * 语言系统。
 *
 * 移动端注意：APK 内的 assets 无法用 FileSystem 读取/列目录（安卓 assets
 * 压缩在 APK 里），所以除了 FileSystem 分支外，这里还提供 openfl 资源清单
 * 回退（Assets.list 编译期清单 + Assets.getText 从 APK 读取），保证安卓上
 * 所有语言组（options / main / editors / charting …）都能正常加载。
 */
class Language
{
	static var groups:Map<String, CustomLangGroup> = [];

	/** 资源清单缓存（Assets.list 每次调用都会重建数组，组多时开销大） */
	static var assetIdCache:Array<String> = null;

	public static function get(value:String, type:String = 'options'):String
	{
		var group = groups.get(type);
		if (group != null)
			return group.get(value);
		return ClientPrefs.data.developerMode ? value + ' (404)' : value;
	}

	public static function resetData()
	{
		check();
		discoverGroups();
		for (group in groups)
			group.updateLang();
	}

	static function discoverGroups()
	{
		var basePath = Paths.getPath('language') + '/' + ClientPrefs.data.language;
		if (FileSystem.isDirectory(basePath))
		{
			for (entry in FileSystem.readDirectory(basePath))
			{
				if (FileSystem.isDirectory(basePath + '/' + entry))
				{
					if (!groups.exists(entry))
						groups.set(entry, new CustomLangGroup(entry));
				}
			}
			return;
		}

		// 移动端：assets 目录不可列 → 从资源清单推断语言目录下有哪些组
		var baseNorm:String = normalize(basePath);
		for (id in getAssetIds())
		{
			if (!id.startsWith(baseNorm) || !id.toLowerCase().endsWith('.lang'))
				continue;
			var rest:String = id.substr(baseNorm.length);
			var slash:Int = rest.indexOf('/');
			if (slash <= 0)
				continue;
			var groupName:String = rest.substring(0, slash);
			if (!groups.exists(groupName))
				groups.set(groupName, new CustomLangGroup(groupName));
		}
	}

	public static function check()
	{
		if (FileSystem.isDirectory(Paths.getPath('language') + '/' + ClientPrefs.data.language))
			return;
		// 移动端 assets 不可列目录：检查当前语言目录下是否存在 .lang 资源
		var baseNorm:String = normalize(Paths.getPath('language') + '/' + ClientPrefs.data.language);
		for (id in getAssetIds())
		{
			if (id.startsWith(baseNorm) && id.toLowerCase().endsWith('.lang'))
				return; // 语言目录存在
		}
		ClientPrefs.data.language = 'English';
	}

	public static function setupData(follow:CustomLangGroup, directoryPath:Array<String>)
	{
		for (path in 0...directoryPath.length)
		{
			var dir:String = directoryPath[path];
			var files:Array<String> = [];

			if (FileSystem.isDirectory(dir))
			{
				for (file in FileSystem.readDirectory(dir))
				{
					if (file.toLowerCase().endsWith('.lang'))
						files.push(dir + '/' + file);
				}
			}
			else
			{
				// 移动端：从资源清单找该目录下的 .lang
				var baseNorm:String = normalize(dir);
				if (baseNorm.length > 0 && !StringTools.endsWith(baseNorm, '/'))
					baseNorm += '/';
				for (id in getAssetIds())
				{
					if (id.startsWith(baseNorm) && id.toLowerCase().endsWith('.lang'))
						files.push(id);
				}
			}

			for (filePath in files)
			{
				var content:String = null;
				try
				{
					if (FileSystem.exists(filePath))
						content = sys.io.File.getContent(filePath);
				}
				catch (e:Dynamic) {}
				if (content == null)
				{
					try
					{
						if (openfl.utils.Assets.exists(filePath))
							content = openfl.utils.Assets.getText(filePath);
					}
					catch (e:Dynamic) {}
				}
				if (content == null)
					continue;

				var outputData:Array<String> = CoolUtil.listFromString(content);
				for (list in 0...outputData.length)
				{
					var line = outputData[list];
					if (line.length > 0 && line.indexOf(' => ') != -1)
					{
						var key:String = line.substr(0, line.indexOf(' => '));
						var value:String = line.substr(line.indexOf(' => ') + 4, line.length);
						if (path == 0)
							follow.defaultData.set(key, value);
						else
							follow.data.set(key, value);
					}
				}
			}
		}
	}

	/** 路径统一为 '/' 分隔 */
	static function normalize(path:String):String
	{
		return path.split('\\').join('/');
	}

	/** 编译期资源清单（缓存） */
	static function getAssetIds():Array<String>
	{
		if (assetIdCache == null)
		{
			assetIdCache = [];
			try
			{
				#if (sys || js)
				var list:Array<String> = openfl.utils.Assets.list(openfl.utils.AssetType.TEXT);
				if (list != null)
				{
					for (id in list)
					{
						var norm:String = normalize(id);
						if (norm.indexOf('assets/shared/language/') == 0)
							assetIdCache.push(norm);
					}
				}
				#end
			}
			catch (e:Dynamic) {}
		}
		return assetIdCache;
	}
}
