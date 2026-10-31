package moonchart.formats;

import moonchart.backend.FormatData;
import moonchart.backend.Timing;
import moonchart.backend.Util;
import moonchart.formats.BasicFormat;
import moonchart.parsers.OsuParser;
import moonchart.parsers._internal.ZipFile;

using StringTools;

class OsuMania extends BasicFormat<OsuFormat, {}>
{
	public static function __getFormat():FormatData
	{
		return {
			ID: OSU_MANIA,
			name: "Osu! Mania",
			description: "Click the circles. To the beat.",
			extension: "osu",
			packedExtension: "osz",
			hasMetaFile: FALSE,
			handler: OsuMania
		}
	}

	// OSU Constants
	public static inline var OSU_SCROLL_SPEED:Float = 0.45; // 0.675;
	public static inline var OSU_CIRCLE_SIZE:Int = 512;
	public static inline var OSU_FORMAT_VERSION:String = "osu file format v14";

	var parser:OsuParser;

	public function new(?data:OsuFormat)
	{
		super({
			timeFormat: MILLISECONDS,
			supportsDiffs: false,
			supportsEvents: true,
			supportsPacks: true
		});

		this.data = data;
		parser = new OsuParser();

		if (data != null)
			this.diffs = data.Metadata.Version;
	}

	override function fromBasicFormat(chart:BasicChart, ?diff:FormatDifficulty):OsuMania
	{
		var chartResolve = resolveDiffsNotes(chart, diff);
		var diff:String = chartResolve.diffs[0];
		var basicNotes:Array<BasicNote> = chartResolve.notes.get(diff);

		var circleSize:Int = chart.meta.extraData.get(LANES_LENGTH) ?? 4;
		var hitObjects:Array<Array<Int>> = Util.makeArray(basicNotes.length);

		for (i in 0...basicNotes.length)
		{
			var note = basicNotes[i];

			// basic osu note variables
			var x:Int = Std.int((note.lane * OSU_CIRCLE_SIZE) / circleSize);
			var time:Int = Std.int(note.time);
			var length:Int = time + (Std.int(note.length));

			// decode osu note type
			var osuType = decodeOsuType(note.type);
			if (osuType.type != OsuType.HOLD)
			{
				if (osuType.type == OsuType.DEFAULT)
					osuType.type = NO_NEW_COMBO; // TODO: im not sure this is correct
				else
					length = osuType.sampleset; // lol
			}

			var hitObject:Array<Int> = [x, 0, time, osuType.type, osuType.hitsound, length];
			Util.setArray(hitObjects, i, hitObject);
		}

		var basicChanges = chart.meta.bpmChanges;
		var timingPoints:Array<Array<Float>> = Util.makeArray(basicChanges.length);

		for (i in 0...basicChanges.length)
		{
			var change = basicChanges[i];
			var time:Int = Std.int(change.time);
			var beatLength:Float = Timing.crochet(change.bpm);
			var meter:Int = Std.int(change.beatsPerMeasure);

			Util.setArray(timingPoints, i, [time, beatLength, meter, 1, 0, 0, 1, 0]);
		}

		/* TODO: osu events
			var events:Array<Array<Dynamic>> = [];
				for (event in chart.data.events)
				{
					if (event.name == "OSU_EVENT")
					{
						events.push([]);
					}
		}*/

		var sliderMult:Float = chart.meta.scrollSpeeds.get(diff) ?? 1.0;
		sliderMult *= OSU_SCROLL_SPEED;

		final extra = chart.meta.extraData;

		this.data = {
			General: {
				AudioFilename: extra.get(AUDIO_FILE) ?? "audio.mp3",
				AudioLeadIn: Std.int(chart.meta.offset ?? 0.0),
				PreviewTime: -1,
				Countdown: 1,
				SampleSet: "Normal",
				StackLeniency: 0.7,
				Mode: 3,
				LetterboxInBreaks: 0,
				SpecialStyle: 0,
				WidescreenStoryboard: 0
			},
			// Editor: {},
			Metadata: {
				Title: chart.meta.title,
				TitleUnicode: chart.meta.title,
				Artist: extra.get(SONG_ARTIST) ?? Moonchart.DEFAULT_ARTIST,
				ArtistUnicode: "",
				Creator: extra.get(SONG_CHARTER) ?? Moonchart.DEFAULT_CHARTER,
				Version: diff,
				Source: "",
				BeatmapID: 0,
				BeatmapSetID: 0
			},
			Difficulty: {
				HPDrainRate: 0,
				CircleSize: circleSize,
				OverallDifficulty: 0,
				ApproachRate: 0,
				SliderMultiplier: sliderMult,
				SliderTickRate: 0,
			},
			// Events: events,
			TimingPoints: timingPoints,
			HitObjects: hitObjects,
		}

		return this;
	}

	override function getNotes(?diff:String):Array<BasicNote>
	{
		var circleSize:Int = data.Difficulty.CircleSize;
		var hitObjects = data.HitObjects;
		var notes:Array<BasicNote> = Util.makeArray(hitObjects.length);

		for (i in 0...hitObjects.length)
		{
			var note = hitObjects[i]; // x, y, time, type, hitSound, objectParams, length/hitSample
			var time:Int = note[2];
			var lane:Int = Math.floor(note[0] * circleSize / OSU_CIRCLE_SIZE);
			var length:Int = (note[5] > 0) ? (note[5] - time) : 0;

			var foundType = note[3];
			var type = BasicNoteType.DEFAULT;

			if (foundType != OsuType.DEFAULT && foundType != OsuType.HOLD)
			{
				type = encodeOsuType(foundType, note[4], note[5]);
				length = 0;
			}

			Util.setArray(notes, i, {
				time: time,
				lane: lane,
				length: length,
				type: type
			});
		}

		Timing.sortNotes(notes);

		return notes;
	}

	// TODO
	override function getEvents():Array<BasicEvent>
	{
		return [];
	}

	override function getChartMeta():BasicMetaData
	{
		var bpmChanges:Array<BasicBPMChange> = [];

		// Pushing the first bpm change at 0 for good measure
		bpmChanges.push({
			time: 0,
			bpm: Timing.crochet(data.TimingPoints[0][1]),
			beatsPerMeasure: 4,
			stepsPerBeat: 4
		});

		for (point in data.TimingPoints)
		{
			// ugly scroll speed change shit TODO: maybe implement it as an event
			if (point[6] == 0)
				continue;

			var time = point[0];
			var bpm = Timing.crochet(point[1]);

			bpmChanges.push({
				time: time,
				bpm: bpm,
				beatsPerMeasure: 4,
				stepsPerBeat: 4
			});
		}

		// TODO: im not quite sure if this is correct, double check
		var osuSpeed:Float = data.Difficulty.SliderMultiplier / OSU_SCROLL_SPEED;

		return {
			title: data.Metadata.Title,
			bpmChanges: bpmChanges,
			offset: data.General.AudioLeadIn,
			scrollSpeeds: [diffs[0] => osuSpeed],
			extraData: [
				BasicMetaValues.LANES_LENGTH => data.Difficulty.CircleSize,
				BasicMetaValues.STRUMLINE_LANES => 1,
				BasicMetaValues.STRUMLINE_KEYS => data.Difficulty.CircleSize,

				BasicMetaValues.SONG_ARTIST => data.Metadata.Artist,
				BasicMetaValues.SONG_CHARTER => data.Metadata.Creator
			]
		}
	}

	override function stringify()
	{
		return {
			data: parser.stringify(data),
			meta: null
		}
	}

	override public function fromFile(path:String, ?meta:String, ?diff:FormatDifficulty):OsuMania
	{
		return fromOsu(Util.getText(path), diff);
	}

	public function fromOsu(data:String, ?diff:FormatDifficulty):OsuMania
	{
		this.data = parser.parse(data);
		this.diffs = diff ?? this.data.Metadata.Version;

		var mode = this.data.General.Mode;
		return mode.isInvalid() ? null : this;
	}

	override public function fromPack(path:String, diff:FormatDifficulty):OsuMania
	{
		var zip = new ZipFile().openFile(path);
		var chartEntries = zip.filterEntries((entry) -> return entry.fileName.endsWith(".osu"));
		var diffs = diff.resolve();

		for (entry in chartEntries)
		{
			var stringEntry = zip.unzipString(entry);
			var data = parser.parse(stringEntry);

			if (data.Metadata.Version == diffs[0])
			{
				return fromOsu(stringEntry);
				break;
			}
		}

		return this;
	}

	public static function decodeOsuType(type:String):OsuNoteType
	{
		var split = type.split("-");
		if (split[0] != OSU_TYPE_IDENT) // Isnt an osu note type
		{
			return {
				type: DEFAULT,
				hitsound: NORMAL,
				sampleset: NORMAL
			}
		}

		return {
			type: Std.parseInt(split[1]),
			hitsound: Std.parseInt(split[2]),
			sampleset: Std.parseInt(split[3])
		}
	}

	private static inline var OSU_TYPE_IDENT:String = '__OSU';

	public static function encodeOsuType(type:OsuType, hitsound:OsuHitsound, sampleset:OsuSampleset):String
	{
		return '$OSU_TYPE_IDENT-$type-$hitsound-$sampleset';
	}
}

typedef OsuNoteType =
{
	type:OsuType,
	hitsound:OsuHitsound,
	sampleset:OsuSampleset
}

enum abstract OsuType(Int) from Int to Int
{
	var DEFAULT = 0;
	var HOLD = 128;
	var NO_NEW_COMBO = 1;
	var NEW_COMBO = 5;
}

enum abstract OsuHitsound(Int) from Int to Int
{
	var NORMAL = 0;
	var WHISTLE = 2;
	var FINISH = 4;
	var WHISTLE_FINISH = 6;
	var CLAP = 8;
	var WHISTLE_CLAP = 10;
	var FINISH_CLAP = 12;
}

enum abstract OsuSampleset(Int) from Int to Int
{
	var AUTO = 0;
	var NORMAL = 1;
	var SOFT = 2;
	var DRUM = 3;
}
