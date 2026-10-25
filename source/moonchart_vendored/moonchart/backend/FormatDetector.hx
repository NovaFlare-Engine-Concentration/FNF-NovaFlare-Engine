package moonchart.backend;

import haxe.io.Path;
import moonchart.backend.FormatData;
import moonchart.backend.Util;
import moonchart.formats.BasicFormat;

using StringTools;

@:keep // Should fix the DCE?
class FormatDetector
{
	/**
	 * Used as the default file formatter for formats without specific file formatting.
	 * Stored as a variable so it can be changed depending on your needs.
	 * Can also be overriden using the ``fileFormatter`` value in ``FormatCheckSettings``.
	 */
	public static var defaultFileFormatter:(String, String) -> Array<String> = (title:String, diff:String) ->
	{
		return [title];
	}

	/**
	 * Initializes the format detector.
	 * More info on ``moonchart.Moonchart``
	 */
	public static function init(?initFormats:Array<FormatData>):Void
	{
		if (initialized)
			return;

		loadFormats();
		if (initFormats != null)
		{
			for (format in initFormats)
				registerFormat(format);
		}
	}

	@:noCompletion
	public static var initialized(default, null):Bool = false;
	public static var formatMap(get, null):Map<Format, FormatData> = [];

	// Make sure all formats are loaded any time formatMap is called
	inline static function get_formatMap()
	{
		loadFormats();
		return formatMap;
	}

	@:noCompletion
	private static function loadFormats():Void
	{
		if (initialized)
			return;

		initialized = true;

		// Load up all the default formats
		var list = Format.getList();
		for (format in list)
			registerFormat(format);
	}

	/**
	 * @return A list of the IDs of all the currently available formats.
	 */
	public static function getList():Array<Format>
	{
		var formatList:Array<Format> = Util.mapKeyArray(formatMap);
		formatList.sort((a, b) -> Util.sortString(a, b));
		return formatList;
	}

	/**
	 * @param extension The extension ``String`` of the formats you want to list.
	 * @return A list of the IDs of all the currently available formats of a file extension.
	 */
	public static function getExtensionList(extension:String):Array<Format>
	{
		extension = extension.trim().toLowerCase();
		return getList().filter((f) ->
		{
			var format = getFormatData(f);
			return format.extension.endsWith(extension);
		});
	}

	/**
	 * Adds a format to the formatMap list so it can be used in format detection.
	 * Also loads up any extension data the format may contain.
	 * @param data The ``FormatData`` to register into the format detector.
	 */
	public inline static function registerFormat(data:FormatData):Void
	{
		__registerWithInheritance(data);
	}

	/**
	 * @param format The format ID ``String`` to get data from.
	 * @return The ``FormatData`` from a format ID.
	 */
	public inline static function getFormatData(format:Format):FormatData
	{
		return formatMap.get(format);
	}

	/**
	 * @param format The format ID ``String`` to get the class from.
	 * @return The format ``Class`` from a format ID.
	 */
	public inline static function getFormatClass(format:Format):Class<DynamicFormat>
	{
		return getFormatData(format).handler;
	}

	/**
	 * @param format The format ID ``String`` to get an instance from.
	 * @return A new ``DynamicFormat`` instance from a format ID.
	 */
	public inline static function createFormatInstance(format:Format):DynamicFormat
	{
		return Type.createInstance(getFormatClass(format), []);
	}

	/**
	 * @param formatClass The format ``Class`` to get a format ID from.
	 * @return The format ID ``String`` from a format class, an empty string if not found.
	 */
	public static function getClassFormat(formatClass:Class<DynamicFormat>):Format
	{
		for (format => data in formatMap)
		{
			if (data.handler == formatClass)
				return format;
		}

		// throw 'Registered format not found for class $input.';
		return "";
	}

	/**
	 * @param formatInstance The format instance to get a format ID from.
	 * @return The format ID ``String`` from a format class, an empty string if not found.
	 */
	public static function getInstanceFormat(formatInstance:DynamicFormat):Format
	{
		return getClassFormat(Type.getClass(formatInstance));
	}

	/**
	 * Identifies and returns the instance of a format from an input of file paths.
	 * Still VERY experimental and may not be always accurate.
	 */
	public static function instanceFromFiles(inputFiles:StringInput, ?diff:FormatDifficulty):DynamicFormat
	{
		var format:Format = findFormat(inputFiles);
		var instance:DynamicFormat = createFormatInstance(format);

		var files:Array<String> = inputFiles.resolve();
		return instance.fromFile(files[0], files[1], diff);
	}

	/**
	 * Identifies and returns the closest format ID from an input of file paths.
	 *
	 * Still VERY experimental and may not be always accurate.
	 * @return Detected format ID ``String`` from the file paths input.
	 */
	public static function findFormat(inputFiles:StringInput, ?settings:FormatCheckSettings):Format
	{
		settings = resolveSettings(settings);

		final files:Array<String> = inputFiles.resolve();

		for (possibleFile in files)
		{
			if (!Util.fileExists(possibleFile))
			{
				files.remove(possibleFile);
			}
		}
		var possibleFormats:Array<Format> = settings.possibleFormats;

		var hasMeta:Bool = (files.length > 1);
		var isFolder:Bool;
		var fileExtension:String;

		if (hasMeta)
		{
			isFolder = false;
		}
		else if (files.length == 1)
		{
			// Folder charts are forced to have meta
			isFolder = Util.isFolder(files[0]);
			hasMeta = isFolder;
		}
		else
		{
			throw 'Not enough files found for input: $inputFiles';
		}

		fileExtension = (isFolder ? "" : Path.extension(files[0]));

		// Check based on simple data like extensions, folders, needs metadata, etc
		possibleFormats = possibleFormats.filter((format) ->
		{
			final data = getFormatData(format);

			// Setting up some format crap
			final forcedMeta:Bool = (data.hasMetaFile == TRUE);
			final possibleMeta:Bool = (data.hasMetaFile == POSSIBLE);
			final needsFolder:Bool = data.extension.startsWith("folder");
			final extension:String = (needsFolder ? data.extension.split("::").pop() : data.extension);

			// Do the checks for matching formats
			final metaMatch:Bool = ((forcedMeta == hasMeta) || possibleMeta);
			final folderMatch:Bool = (needsFolder == isFolder);
			final extensionMatch:Bool = (isFolder ? true : (extension == fileExtension));

			// Finally, filter in or out matching formats
			return metaMatch && folderMatch && extensionMatch;
		});

		// Check if we got the format with the first filter
		if (possibleFormats.length <= 0)
		{
			throw "Format not found for file(s) " + files;
			return null;
		}
		else if (possibleFormats.length == 1)
		{
			return possibleFormats[0];
		}

		// If we didnt get it then we are close and gotta do some extra more indepth content checks
		if (settings.checkContents)
		{
			var contents:Array<String> = [];
			for (i in files)
				contents.push(Util.getText(i));

			return findFromContents(contents, {possibleFormats: possibleFormats});
		}

		// Fuck it we ball
		return possibleFormats[possibleFormats.length - 1];
	}

	/**
	 * Identifies and returns the closest format ID and files from a folder input.
	 *
	 * Still VERY experimental and may not be always accurate.
	 * @return Detected format ID ``String`` and files from the folder input.
	 */
	public static function findInFolder(folder:String, title:String, diff:String, ?settings:FormatCheckSettings):DetectedFormatFiles
	{
		settings = resolveSettings(settings);

		// First filter out any duplicate extensions
		var extensions:Array<String> = [];
		for (format => data in formatMap)
		{
			if (!format.contains(data.extension))
				extensions.push(data.extension);
		}

		// Find all the possible chart files from the folder
		var folderFiles = Util.readFolder(folder);
		folderFiles = folderFiles.filter((path) -> return extensions.contains(Path.extension(path)));

		if (folderFiles.length <= 0)
		{
			throw "No valid charts files were found inside the folder: " + folder;
			return null;
		}

		// Find which formats match the input files
		var possibleFormats:Array<String> = getList();
		var matchFormats:Map<Format, Array<String>> = [];
		var fileFormatter = settings.fileFormatter;

		possibleFormats = possibleFormats.filter((format) ->
		{
			final data = getFormatData(format);
			final possibleFiles:Array<String> = (data.formatFile != null ? data.formatFile(title, diff) : fileFormatter(title, diff));

			for (i in 0...possibleFiles.length)
			{
				possibleFiles[i] += '.${data.extension}';
			}

			for (file in possibleFiles)
			{
				if (folderFiles.contains(file))
				{
					matchFormats.set(format, possibleFiles);
					return true;
				}
			}

			return false;
		});

		// Format the matched files with their folder
		for (format => files in matchFormats)
		{
			for (i => file in files)
			{
				files[i] = folder + (folder.endsWith("/") ? "" : "/") + file;
			}
		}

		// Check if we got the format with the first filter
		if (possibleFormats.length <= 0)
		{
			throw 'No formats could be detected matching the files. (folder: $folder, title: $title, diff: $diff)';
			return null;
		}
		else if (possibleFormats.length == 1)
		{
			return {
				format: possibleFormats[0],
				files: matchFormats.get(possibleFormats[0])
			}
		}

		// If we didnt get it there then theres a format conflict which findFormat should resolve
		var matchedFiles = matchFormats.get(possibleFormats[0]);
		return {
			format: findFormat(matchedFiles, settings),
			files: matchedFiles
		}
	}

	/**
	 * Identifies and returns the closest format ID from a contents input.
	 *
	 * ONLY works for formats with a ``specialValues`` format data.
	 *
	 * Still VERY experimental and may not be always accurate.
	 * @return Detected format ID ``String`` from the file contents.
	 */
	public static function findFromContents(fileContents:StringInput, ?settings:FormatCheckSettings):Format
	{
		// Matching based on points
		var matchPoints:Array<{points:Int, format:Format}> = [];
		var fileContents = fileContents.resolve();
		var possibleFormats = resolveSettings(settings).possibleFormats;

		final mainContent = fileContents[0];
		// final metaContent = fileContents[1]; TODO:

		possibleFormats = possibleFormats.filter((format) ->
		{
			final data = getFormatData(format);

			if (data.specialValues == null)
				return false;

			var match = {points: 0, format: format};
			matchPoints.push(match);

			// trace(data.ID, data.specialValues);

			for (value in data.specialValues)
			{
				var valueValidation = validateSpecialValue(mainContent, value);
				switch (valueValidation)
				{
					case POSSIBLE: // Unable to find optional value
						continue;
					case FALSE: // Unable to find forced value, invalidate format
						return false;
					case TRUE: // Found value
						var special:Bool = (value.fastCodeAt(0) == '_'.code); // Detect the importance of the matched value
						match.points += (special ? 5 : 1);
						continue;
				}
			}

			return true;
		});

		matchPoints = matchPoints.filter((v) -> return possibleFormats.contains(v.format));
		matchPoints.sort((a, b) -> return Util.sortValues(a.points, b.points, false));

		if (matchPoints.length <= 0)
		{
			throw "No formats could be detected matching the file content inputs.";
			return null;
		}

		return matchPoints[0].format;
	}

	@:noCompletion
	private static function validateSpecialValue(content:String, specialValue:String):PossibleValue
	{
		final prefix:Int = specialValue.fastCodeAt(0);

		if (prefix == '?'.code || prefix == '_'.code)
		{
			specialValue = specialValue.substring(1, specialValue.length);
			return content.contains(specialValue) ? TRUE : ((prefix == '?'.code) ? POSSIBLE : FALSE);
		}

		return content.contains(specialValue) ? TRUE : FALSE;
	}

	@:noCompletion
	private static function resolveSettings(?settings:FormatCheckSettings):FormatCheckSettings
	{
		settings = Optimizer.addDefaultValues(settings, {
			possibleFormats: getList(),
			excludedFormats: [],
			fileFormatter: defaultFileFormatter,
			checkContents: true
		});

		settings.possibleFormats = settings.possibleFormats.filter((v) -> !settings.excludedFormats.contains(v));
		return settings;
	}

	/**
	 * Internal method to register formats to the format map
	 */
	private inline static function __registerFormat(data:FormatData):Void
	{
		formatMap.set(data.ID, data);
	}

	/**
	 * Internal method to check and add any extended data the format may be missing
	 */
	private static function __registerWithInheritance(data:FormatData)
	{
		if (formatMap.exists(data.ID))
			return;

		__registerFormat(data);

		var formatClass:Class<DynamicFormat> = data.handler;
		var specialValues:Array<String> = data.specialValues;
		var formatSuper:String = '';

		final classFormatPostfixes:Array<String> = ["Basic", "Meta"];

		// find a valid super class
		var tmpClass = formatClass;
		while (true)
		{
			var superClass = Type.getSuperClass(tmpClass);
			formatSuper = Type.getClassName(superClass);

			for (postfix in classFormatPostfixes)
			{
				if (formatSuper.endsWith(postfix))
					formatSuper = formatSuper.substr(0, formatSuper.length - postfix.length);
			}

			if (formatSuper != Type.getClassName(formatClass))
				break;

			tmpClass = cast superClass;
		}

		// check if its a valid moonchart class
		var superClass:Class<DynamicFormat> = cast Type.resolveClass(formatSuper);
		var getFormatMethod = Reflect.field(superClass, '__getFormat');
		if (getFormatMethod == null)
			return;

		// check if the super class is registered and if it has any data to take from
		var baseData = getFormatMethod();
		__registerWithInheritance(baseData);
		var extendedData = getFormatData(baseData.ID);
		if (extendedData.specialValues == null || extendedData.specialValues.length <= 0)
			return;

		// add inherited data
		for (value in extendedData.specialValues)
		{
			if (specialValues.indexOf(value) == -1)
				specialValues.push(value);
		}
	}
}

typedef DetectedFormatFiles =
{
	format:Format,
	files:Array<String>
}

typedef FormatCheckSettings =
{
	?checkContents:Bool,
	?possibleFormats:Array<Format>,
	?excludedFormats:Array<Format>,
	?fileFormatter:(String, String) -> Array<String>
}
