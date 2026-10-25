package moonchart.formats;

import haxe.Json;
import haxe.io.Bytes;
import moonchart.backend.*;
import moonchart.backend.FormatData.Format;
import moonchart.backend.Util;

using StringTools;

typedef BasicTimingObject =
{
	time:Float
}

typedef BasicNote = BasicTimingObject &
{
	lane:Int,
	length:Float,
	type:String
}

typedef BasicEvent = BasicTimingObject &
{
	name:String,
	data:Dynamic
}

typedef BasicBPMChange = BasicTimingObject &
{
	bpm:Float,
	beatsPerMeasure:Float, // numerator
	stepsPerBeat:Float // denominator
}

typedef BasicMeasure =
{
	notes:Array<BasicNote>, // Notes inside of the measure
	events:Array<BasicEvent>, // Events inside of the measure
	bpmChanges:Array<BasicBPMChange>, // BPM changes that happened inside the measure's duration
	bpm:Float, // Current bpm during this measure
	beatsPerMeasure:Float, // Current beatsPerMeasure during this measure
	stepsPerBeat:Float, // Current stepsPerBeat during this measure
	startTime:Float, // The measure's start time in milliseconds
	endTime:Float, // The measure's end time in milliseconds
	length:Float, // The measure's duration in milliseconds
	snap:Int // Automatic snap for the notes inside the measure
}

typedef BasicChartDiffs = Map<String, Array<BasicNote>>;

typedef BasicChart =
{
	data:BasicChartData,
	meta:BasicMetaData
}

typedef BasicChartData =
{
	diffs:BasicChartDiffs,
	events:Array<BasicEvent>,
}

typedef BasicMetaData =
{
	title:String,
	bpmChanges:Array<BasicBPMChange>,
	scrollSpeeds:Map<String, Float>,
	offset:Float,
	extraData:Map<String, Dynamic>, // Mainly for extra bullshit variables that may not exist among all formats
	?inputFormats:Array<Format>, // NOTE: Only added on ``getFormat`` at the moment
	?inputInstances:Array<DynamicFormat> // NOTE: Only added on ``getFormat`` at the moment
}

enum abstract BasicNoteType(String) from String to String
{
	var DEFAULT = "";
	var ROLL;
	var MINE;
	var FAKE;
}

enum abstract TimeFormat(Int)
{
	var MILLISECONDS;
	var SECONDS;
	var STEPS; // Stepmania
	var TICKS; // Guitar hero
}

enum abstract BasicMetaValues(String) from String to String
{
	var LANES_LENGTH; // usually 4 or 8
	var STRUMLINE_LANES; // individual number of strumlines, usually 1 or 2, can be int or array int
	var STRUMLINE_KEYS; // individual number of keys per strumline, usually 4, can be int or array int

	var AUDIO_FILE;
	var SONG_ARTIST;
	var SONG_ALBUM;
	var SONG_CHARTER;
	var SONG_NOTE_SKIN;
}

typedef BasicFormatMetadata =
{
	timeFormat:TimeFormat,
	supportsDiffs:Bool, // If the format contains multiple diffs inside one file
	supportsEvents:Bool, // If the format supports events
	?isBinary:Bool, // If the format files are binary (normally false)
	?supportsPacks:Bool // If the format supports zip packs
}

typedef FormatDifficulty = Null<OneOfArray<String>>;

typedef FormatSave =
{
	output:OneOfTwo<FormatStringify, FormatEncode>,
	dataPath:String,
	?metaPath:String
}

typedef FormatStringify =
{
	data:String,
	?meta:OneOfArray<String>, // TODO: fully implement multiple metadata files
}

typedef FormatEncode =
{
	data:Bytes,
	?meta:OneOfArray<Bytes>,
}

typedef DiffNotesOutput =
{
	diffs:Array<String>,
	notes:Map<String, Array<BasicNote>>
}

typedef DynamicFormat = BasicFormat<Dynamic, Dynamic>;

@:keep
@:private
abstract class BasicFormat<D, M>
{
	/**
	 * Format instance data.
	 */
	public var data(default, set):D;

	/**
	 * Format instance metadata.
	 */
	public var meta(default, set):M;

	/**
	 * Format instance difficulties.
	 */
	public var diffs(default, set):Array<String>;

	inline function set_diffs(diff:FormatDifficulty):Array<String>
		return this.diffs = resolveDiffs(diff);

	/**
	 * Small metadata values of the format instance used for some internal functions.
	 *
	 * To access more format data of the format instance use ``getFormatData``
	 */
	public var formatMeta(default, null):BasicFormatMetadata;

	/**
	 * Format data values of the format instance used in ``FormatDetector`` for file detection.
	 *
	 * Contains basic values like extensions, file formatting, etc ...
	 * @return The ``FormatData`` of the format instance, ``null`` if not found.
	 */
	public function getFormatData():Null<FormatData>
	{
		var formatID:String = FormatDetector.getClassFormat(Type.getClass(this));
		return (formatID.length > 0) ? FormatDetector.getFormatData(formatID) : null;
	}

	public function new(formatMeta:BasicFormatMetadata)
	{
		this.diffs = Moonchart.DEFAULT_DIFF;
		this.formatMeta = Optimizer.addDefaultValues(formatMeta, {
			timeFormat: MILLISECONDS,
			supportsDiffs: false,
			supportsEvents: true,
			isBinary: false,
			supportsPacks: false
		});
	}

	/**
	 * Loads the chart of the current format from a file.
	 * @param path The file path ``String`` of the chart to load.
	 * @param meta (Optional) The file path(s) ``String`` or ``Array<String>`` of the chart to load.
	 * @param diff (Optional) The difficulties ``String`` or ``Array<String>`` of the chart to load.
	 * @return The format instance after loading the file (if not failed).
	 */
	public function fromFile(path:String, ?meta:StringInput, ?diff:FormatDifficulty):BasicFormat<D, M>
	{
		throw "fromFile needs to be implemented in this format!";
		return null;
	}

	/**
	 * Loads the chart of the current format from a pack.
	 *
	 * Note that most formats don't support pack loading, if so check out ``fromFile``.
	 * @param path The pack path ``String`` of the chart to load.
	 * @param diff The difficulties ``String`` or ``Array<String>`` of the chart to load.
	 * @return The format instance after loading the pack (if not failed).
	 */
	public function fromPack(path:String, diff:FormatDifficulty):BasicFormat<D, M>
	{
		if (formatMeta.supportsPacks)
			throw "fromPack needs to be implemented in this format!";

		return null;
	}

	public function fromBasicFormat(chart:BasicChart, ?diff:FormatDifficulty):BasicFormat<D, M>
	{
		throw "fromBasicFormat needs to be implemented in this format!";
		return null;
	}

	/**
	 * Loads the basic data from another format into this format instance.
	 * @param format The format or list of format instances to load data from.
	 * @param diffs (Optional) The list of difficulties to load from the input format(s), leave null to load all found diffs.
	 * @return The format instance after loading the data from the input format(s).
	 */
	public function fromFormat(format:OneOfArray<DynamicFormat>, ?diffs:FormatDifficulty):BasicFormat<D, M>
	{
		var formats:Array<DynamicFormat> = format.resolve();
		var basics:Array<BasicChart> = [];
		var inputFormats:Array<Format> = [];

		for (i in formats)
		{
			basics.push(i.toBasicFormat());
			inputFormats.push(FormatDetector.getInstanceFormat(i)); // TODO: maybe i shouldnt push duplicate ones?
		}

		var first:BasicChart = basics[0];
		var formatDiffs:Map<String, Array<BasicNote>> = [];
		var formatSpeeds:Map<String, Float> = [];

		for (basic in basics)
		{
			for (diff => notes in basic.data.diffs)
				formatDiffs.set(diff, notes);

			for (diff => speed in basic.meta.scrollSpeeds)
				formatSpeeds.set(diff, speed);
		}

		var basic:BasicChart = {
			data: {
				diffs: formatDiffs,
				events: first.data.events
			},
			meta: {
				title: first.meta.title,
				bpmChanges: Timing.cleanBPMChanges(first.meta.bpmChanges),
				scrollSpeeds: formatSpeeds,
				offset: first.meta.offset,
				extraData: first.meta.extraData,
				inputFormats: inputFormats,
				inputInstances: formats
			}
		}

		this.fromBasicFormat(basic, diffs);
		return this;
	}

	/**
	 * Internal function used for getting basic data on ``fromData`` conversion.
	 * You probably won't ever need to use this function.
	 * @return A ``BasicChart`` with the basic data and meta of the format instance.
	 */
	public function toBasicFormat():BasicChart
	{
		return {
			data: getChartData(),
			meta: getChartMeta()
		};
	}

	/**
	 * Function used to export text-based formats.
	 * @returns A ``FormatStringify`` with the data and meta ``String``s of the chart format. 
	 */
	public function stringify():FormatStringify
	{
		if (!formatMeta.isBinary)
			throw "stringify needs to be implemented in this format!";

		return null;
	}

	/**
	 * Function used to export binary-based formats.
	 * @returns A ``FormatEncode`` with the data and meta ``Bytes``s of the chart format. 
	 */
	public function encode():FormatEncode
	{
		if (formatMeta.isBinary)
			throw "encode needs to be implemented in this format!";

		return null;
	}

	/**
	 * Automatically stringifies / encodes and saves the format instance file(s) to a path.
	 *
	 * @param path The path to save the chart to, can either input the whole path
	 * or just the folder with the file formatter doing the work automatically.
	 * @param metaPath (Optional) Works the same as the ``path`` param but for
	 * the metadata file, leave null to be automatically set.
	 * @return A ``FormatSave`` with the output data and final file paths, ``null`` if failed.
	 */
	public function save(path:String, ?metaPath:StringInput):FormatSave
	{
		final formatData:Null<FormatData> = getFormatData();
		var metaPath:Null<String> = (metaPath != null) ? metaPath.resolve()[0] : null;

		// Auto file formatting with format data
		if (formatData != null && !(formatData.extension.startsWith("folder::")))
		{
			var isPathFolder:Bool = Util.isFolder(path);
			var isMetaFolder:Bool = (metaPath == null) ? false : Util.isFolder(metaPath);

			// Formatting files if the path is a folder
			if (isPathFolder || isMetaFolder)
			{
				final meta = getChartMeta();
				final fileFormatting = formatData.formatFile ?? FormatDetector.defaultFileFormatter;
				final formatFiles = fileFormatting(meta.title, diffs[0]);

				if (isMetaFolder || (metaPath == null))
					metaPath = Util.extendPath(metaPath ?? path, formatFiles[1]);

				if (isPathFolder)
					path = Util.extendPath(path, formatFiles[0]);
			}

			// Add file extension if missing
			path = Util.resolveExtension(path, formatData.extension);
			metaPath = Util.resolveExtension(metaPath, formatData.metaFileExtension ?? formatData.extension);
		}

		if (formatMeta.isBinary)
		{
			final bytes = encode();
			Util.saveBytes(path, bytes.data);
			if (metaPath != null)
			{
				if (bytes.meta != null)
					Util.saveBytes(metaPath, bytes.meta.resolve()[0]);
				else
					trace("[WARN] Couldn't find meta to save for path: " + metaPath);
			}

			return {
				output: bytes,
				dataPath: path,
				metaPath: metaPath
			}
		}
		else
		{
			final string = stringify();
			Util.saveText(path, string.data);
			if (metaPath != null)
			{
				if (string.meta != null)
					Util.saveText(metaPath, string.meta.resolve()[0]);
				else
					trace("[WARN] Couldn't find meta to save for path: " + metaPath);
			}

			return {
				output: string,
				dataPath: path,
				metaPath: metaPath
			}
		}

		return null;
	}

	// TODO:
	// public function pack(path:String):Void
	// {
	//	if (formatMeta.supportsPacks)
	//		throw "pack needs to be implemented in this format!";
	// }

	/**
	 * ESSENTIAL function when creating a format in Moonchart.
	 * @param diff (Optional) Diff to get notes from, can be ignored if the chart format can only hold one diff per file.
	 * @return A list of all the converted ``BasicNote``s found in the format's chart data.
	 */
	public function getNotes(?diff:String):Array<BasicNote>
	{
		return [];
	}

	/**
	 * ESSENTIAL function when creating a format in Moonchart.
	 * @return A list of all the converted ``BasicEvent``s found in the format's chart data.
	 */
	public function getEvents():Array<BasicEvent>
	{
		if (formatMeta.supportsEvents)
		{
			throw "getEvents needs to be implemented in this format!";
			return null;
		}

		return [];
	}

	/**
	 * ESSENTIAL function when creating a format in Moonchart.
	 * @return A ``BasicMetaData`` with the basic converted metadata found in the format's chart data.
	 */
	public function getChartMeta():BasicMetaData
	{
		throw "getChartMeta needs to be implemented in this format!";
		return null;
	}

	public function getChartData():BasicChartData
	{
		var chartDiffs = new BasicChartDiffs();

		for (diff in this.diffs)
		{
			chartDiffs.set(diff, getNotes(diff));
		}

		return {
			diffs: chartDiffs,
			events: getEvents()
		}
	}

	// Just for util
	public inline function resolveDiffs(?diff:FormatDifficulty):Array<String>
	{
		var resolve = (diff != null) ? diff.resolve() : null;
		return (resolve != null && resolve.length > 0) ? resolve : [Moonchart.DEFAULT_DIFF];
	}

	public function formatDiff(diff:String):String
	{
		if (!Moonchart.CASE_SENSITIVE_DIFFS)
			diff = diff.toLowerCase();

		if (!Moonchart.SPACE_SENSITIVE_DIFFS)
			diff = diff.replace(" ", "-");

		return diff;
	}

	/**
	 * Helper function to resolve getting specific difficulties from a ``BasicChart``.
	 * It'll use ``Moonchart.DEFAULT_DIFF``, if possible, when no others are available.
	 * Will throw an error in case no diffs could be found.
	 * @param chart The ``BasicChart`` to resolve.
	 * @param chartDiff (Optional) The diff or list of diffs to get from the chart.
	 * @return An instance of ``DiffNotesOutput`` with all the resolved diffs.
	 */
	public function resolveDiffsNotes(chart:BasicChart, ?chartDiff:FormatDifficulty):DiffNotesOutput
	{
		// Locate the available diffs
		final foundDiffs:Array<String> = Util.mapKeyArray(chart.data.diffs);
		diffs = chartDiff ?? foundDiffs;

		// Format the diffs with settings
		for (i => diff in diffs)
			diffs[i] = formatDiff(diff);

		// Find and push diffs
		var pushedDiffs:Array<String> = [];
		var chartNotes:Map<String, Array<BasicNote>> = [];

		for (diff => notes in chart.data.diffs)
		{
			diff = formatDiff(diff);
			if (diffs.contains(diff))
			{
				chartNotes.set(diff, notes);
				pushedDiffs.push(diff);
			}
		}

		if (pushedDiffs.length <= 0)
		{
			// Set diff to the default one if it exists (from a no multi-diffs format)
			if (chartDiff != null && foundDiffs[0] == Moonchart.DEFAULT_DIFF)
			{
				// Remove default data
				var defaultData = chart.data.diffs.get(Moonchart.DEFAULT_DIFF);
				chart.data.diffs.remove(Moonchart.DEFAULT_DIFF);

				// Set the default data to new found diff
				var foundDiff = resolveDiffs(chartDiff)[0];
				chart.data.diffs.set(foundDiff, defaultData);
				chartNotes.set(foundDiff, defaultData);
			}
			else
			{
				var error:String = "Couldn't find difficulties " + this.diffs + " on this chart.\n";
				error += (foundDiffs.length <= 0) ? "No other difficulties were found." : "Found other difficulties: " + foundDiffs;
				throw error;
			}
		}

		return {
			diffs: pushedDiffs,
			notes: chartNotes
		}
	}

	// Adding these for customization sake

	function set_data(v):D
	{
		return data = v;
	}

	function set_meta(v):M
	{
		return meta = v;
	}
}

@:private
abstract class BasicJsonFormat<D, M> extends BasicFormat<D, M>
{
	/**
	 * If to use the default JSON beautify formatting. (aka: \t)
	 */
	public var beautify(get, set):Bool;

	/**
	 * The custom formatting to use for JSON stringify.
	 */
	public var formatting:Null<String> = null;

	inline function set_beautify(v:Bool):Bool
	{
		formatting = v ? "\t" : null;
		return v;
	}

	inline function get_beautify():Bool
	{
		return formatting == "\t";
	}

	// Casting for easier chained code
	override function fromFormat(format:OneOfArray<DynamicFormat>, ?diffs:FormatDifficulty):BasicJsonFormat<D, M>
	{
		return cast super.fromFormat(format, diffs);
	}

	override function stringify():FormatStringify
	{
		return {
			data: data != null ? Json.stringify(data, formatting) : null,
			meta: meta != null ? Json.stringify(meta, formatting) : null
		}
	}

	public function fromJson(data:String, ?meta:StringInput, ?diff:FormatDifficulty):BasicJsonFormat<D, M>
	{
		this.diffs = diff;
		this.data = Json.parse(data);
		if (meta != null)
			this.meta = Json.parse(meta.resolve()[0]);
		return this;
	}
}
