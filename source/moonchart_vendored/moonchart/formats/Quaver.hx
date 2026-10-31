package moonchart.formats;

import moonchart.backend.FormatData;
import moonchart.backend.Util;
import moonchart.formats.BasicFormat;
import moonchart.formats.fnf.FNFVSlice;
import moonchart.parsers.QuaverParser;
import moonchart.parsers._internal.ZipFile;

using StringTools;

class Quaver extends BasicFormat<QuaverFormat, {}>
{
	public static final QUAVER_SLIDER_VELOCITY:String = "SLIDER_VELOCITY";

	public static function __getFormat():FormatData
	{
		return {
			ID: QUAVER,
			name: "Quaver",
			description: "",
			extension: "qua",
			packedExtension: "qp",
			hasMetaFile: FALSE,
			handler: Quaver
		}
	}

	var parser:QuaverParser;

	public function new(?data:QuaverFormat)
	{
		super({
			timeFormat: MILLISECONDS,
			supportsDiffs: false,
			supportsEvents: true,
			supportsPacks: true
		});
		this.data = data;
		parser = new QuaverParser();
	}

	override function fromBasicFormat(chart:BasicChart, ?diff:FormatDifficulty):Quaver
	{
		var chartResolve = resolveDiffsNotes(chart, diff);
		var chartDiff:String = chartResolve.diffs[0];
		var basicNotes:Array<BasicNote> = chartResolve.notes.get(chartDiff);

		var hitObjects:Array<QuaverHitObject> = Util.makeArray(basicNotes.length);
		var defaultKeySounds:Array<String> = []; // Too lazy to add support for these rn

		for (i in 0...basicNotes.length)
		{
			var note = basicNotes[i];
			Util.setArray(hitObjects, i, {
				StartTime: Std.int(note.time),
				EndTime: note.length > 0 ? Std.int(note.length) : null,
				Lane: note.lane,
				KeySounds: defaultKeySounds
			});
		}

		var basicChanges = chart.meta.bpmChanges;
		var timingPoints:Array<QuaverTimingPoint> = Util.makeArray(basicChanges.length);
		for (i in 0...basicChanges.length)
		{
			var change = basicChanges[i];
			Util.setArray(timingPoints, i, {
				StartTime: Std.int(change.time),
				Bpm: change.bpm
			});
		}

		final extra = chart.meta.extraData;

		final keysMode:String = switch (extra.get(LANES_LENGTH) ?? 4)
		{
			case 4: "Keys4";
			case _: "Keys7";
		}

		var sliders:Array<QuaverSlider> = [];
		for (event in chart.data.events)
		{
			if (event.name == QUAVER_SLIDER_VELOCITY)
			{
				sliders.push({
					StartTime: event.time,
					Multiplier: event.data.multiplier ?? 1
				});
			}
		}

		this.data = {
			AudioFile: extra.get(AUDIO_FILE) ?? "audio.mp3",
			SongPreviewTime: Std.int(extra.get(SONG_PREVIEW_START) ?? 0),
			BackgroundFile: "''",
			MapId: -1,
			MapSetId: -1,
			Mode: keysMode,
			Artist: extra.get(SONG_ARTIST) ?? Moonchart.DEFAULT_ARTIST,
			Source: "''",
			Tags: "''",
			Creator: extra.get(SONG_CHARTER) ?? Moonchart.DEFAULT_CHARTER,
			Description: "Converted with " + Util.version,
			BPMDoesNotAffectScrollVelocity: true,
			InitialScrollVelocity: chart.meta.scrollSpeeds.get(chartDiff) ?? 1.0,
			EditorLayers: [],
			CustomAudioSamples: [],
			SoundEffects: [],
			SliderVelocities: sliders,

			Title: chart.meta.title,
			TimingPoints: timingPoints,
			HitObjects: hitObjects,
			DifficultyName: chartDiff
		}

		return this;
	}

	override function getNotes(?diff:String):Array<BasicNote>
	{
		var hitObjects = data.HitObjects;
		var notes:Array<BasicNote> = Util.makeArray(hitObjects.length);

		for (i in 0...hitObjects.length)
		{
			final hitObject = hitObjects[i];
			final time:Int = (hitObject.StartTime ?? 0);
			final length:Int = (hitObject.EndTime != null) ? hitObject.EndTime - time : 0;

			Util.setArray(notes, i, {
				time: time,
				length: length,
				lane: Std.int(hitObject.Lane - 1),
				type: ""
			});
		}

		return notes;
	}

	override function getEvents():Array<BasicEvent>
	{
		var sliders = data.SliderVelocities;
		var events:Array<BasicEvent> = [];

		for (i in 0...sliders.length)
		{
			var slider = sliders[i];
			var time:Float = slider.StartTime ?? 0.0;
			var multiplier:Null<Float> = slider.Multiplier;

			if (time > 0 && multiplier != null)
			{
				events.push({
					time: time,
					name: QUAVER_SLIDER_VELOCITY,
					data: {
						multiplier: multiplier
					}
				});
			}
		}

		return events;
	}

	override function getChartMeta():BasicMetaData
	{
		var timingPoints = data.TimingPoints;
		var bpmChanges:Array<BasicBPMChange> = Util.makeArray(timingPoints.length);

		for (i in 0...timingPoints.length)
		{
			var timingPoint = timingPoints[i];
			Util.setArray(bpmChanges, i, {
				time: (timingPoint.StartTime ?? 0),
				bpm: timingPoint.Bpm,
				beatsPerMeasure: 4,
				stepsPerBeat: 4
			});
		}

		final lanesLength:Int = switch (data.Mode)
		{
			case "Keys4": 4;
			case _: 7;
		}

		return {
			title: data.Title,
			bpmChanges: bpmChanges,
			offset: 0.0,
			scrollSpeeds: [diffs[0] => data.InitialScrollVelocity],
			extraData: [
				LANES_LENGTH => lanesLength,
				STRUMLINE_LANES => 1,
				STRUMLINE_KEYS => lanesLength,
				AUDIO_FILE => data.AudioFile,
				SONG_ARTIST => data.Artist,
				SONG_CHARTER => data.Creator
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

	override public function fromFile(path:String, ?meta:String, ?diff:FormatDifficulty):Quaver
	{
		return fromQuaver(Util.getText(path), diff);
	}

	public function fromQuaver(data:String, ?diff:FormatDifficulty):Quaver
	{
		this.data = parser.parse(data);
		this.diffs = diff ?? this.data.DifficultyName;
		return this;
	}

	override public function fromPack(path:String, diff:FormatDifficulty):Quaver
	{
		var zip = new ZipFile().openFile(path);
		var chartEntries = zip.filterEntries((entry) -> return entry.fileName.endsWith(".qua"));
		var diffs = diff.resolve();

		for (entry in chartEntries)
		{
			var stringEntry = zip.unzipString(entry);
			var data = parser.parse(stringEntry);

			if (data.DifficultyName == diffs[0])
			{
				return fromQuaver(stringEntry);
				break;
			}
		}

		return this;
	}
}
