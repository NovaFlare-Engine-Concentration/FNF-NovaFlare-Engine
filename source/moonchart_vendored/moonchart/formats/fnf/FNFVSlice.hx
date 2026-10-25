package moonchart.formats.fnf;

import moonchart.backend.FormatData;
import moonchart.backend.Timing;
import moonchart.backend.Util;
import moonchart.formats.BasicFormat;
import moonchart.formats.fnf.FNFGlobal.BasicFNFCamFocusData;
import moonchart.formats.fnf.FNFGlobal.BasicFNFEvent;
import moonchart.formats.fnf.FNFGlobal.BasicFNFNoteType;
import moonchart.formats.fnf.FNFGlobal.BasicFNFPlayAnimEvent;
import moonchart.formats.fnf.FNFGlobal.BasicFNFPositionCameraEvent;
import moonchart.formats.fnf.FNFGlobal.BasicFNFSetCameraBopEvent;
import moonchart.formats.fnf.FNFGlobal.BasicFNFZoomCameraEvent;
import moonchart.formats.fnf.FNFGlobal.FNFNoteTypeResolver;
import moonchart.formats.fnf.legacy.FNFLegacy.FNFLegacyMetaValues;
import moonchart.parsers._internal.ZipFile;

using StringTools;

enum abstract FNFVSliceMetaValues(String) from String to String
{
	var SONG_VARIATIONS = "FNF_SONG_VARIATIONS";
	var SONG_RATINGS = "FNF_SONG_RATINGS";
	var SONG_PREVIEW_START = "FNF_SONG_PREVIEW_START";
	var SONG_PREVIEW_END = "FNF_SONG_PREVIEW_END";

	var SONG_INSTRUMENTAL = "FNF_SONG_INSTRUMENTAL";
	var SONG_ALT_INSTRUMENTALS = "FNF_SONG_ALT_INSTRUMENTALS";
	var SONG_OPPONENT_VOCALS = "FNF_SONG_OPPONENT_VOCALS";
	var SONG_PLAYER_VOCALS = "FNF_SONG_PLAYER_VOCALS";
}

enum abstract FNFVSliceNoteType(String) from String to String
{
	var VSLICE_DEFAULT = "normal";
	var VSLICE_MOM = "mom";
}

class FNFVSlice extends BasicJsonFormat<FNFVSliceFormat, FNFVSliceMeta>
{
	// FNF V-Slice constants
	public static inline var VSLICE_PREVIEW_END:Int = 15000;
	public static inline var VSLICE_DEFAULT_NOTE_SKIN:String = "funkin";
	public static inline var VSLICE_FOCUS_EVENT:String = "FocusCamera";
	public static inline var VSLICE_PLAY_ANIMATION_EVENT:String = "PlayAnimation";
	public static inline var VSLICE_CAMERA_ZOOM_EVENT:String = "ZoomCamera";
	public static inline var VSLICE_SET_CAMERA_BOP_EVENT:String = "SetCameraBop";

	public static inline var VSLICE_CHART_VERSION:String = "2.0.0";
	public static inline var VSLICE_META_VERSION:String = "2.2.4";

	// public static inline var VSLICE_MANIFEST_VERSION:String = "1.0.0";

	public static function __getFormat():FormatData
	{
		return {
			ID: FNF_VSLICE,
			name: "FNF (V-Slice)",
			description: "The new and handsome FNF format.",
			extension: "json",
			packedExtension: "fnfc",
			formatFile: formatFile,
			hasMetaFile: TRUE,
			metaFileExtension: "json",
			specialValues: ['"scrollSpeed":', '"version":'],
			findMeta: (files) ->
			{
				for (file in files)
				{
					if (Util.getText(file).contains('"playData":'))
						return file;
				}
				return files[0];
			},
			handler: FNFVSlice
		}
	}

	public static function formatFile(title:String, diff:String):Array<String>
	{
		title = title.trim().toLowerCase();
		return ['$title-chart', '$title-metadata'];
	}

	public var noteTypeResolver(default, null):FNFNoteTypeResolver;

	public function new(?data:FNFVSliceFormat, ?meta:FNFVSliceMeta)
	{
		super({timeFormat: MILLISECONDS, supportsDiffs: true, supportsEvents: true});
		this.data = data;
		this.meta = meta;
		beautify = true;

		if (this.data != null)
			this.diffs = this.data.notes.keys();

		// Register FNF V-Slice note types
		noteTypeResolver = FNFGlobal.createNoteTypeResolver();
		noteTypeResolver.register(FNFVSliceNoteType.VSLICE_DEFAULT, BasicNoteType.DEFAULT);
		noteTypeResolver.register(FNFVSliceNoteType.VSLICE_MOM, BasicFNFNoteType.ALT_ANIM);
	}

	// Could be useful converting erect mixes
	public var defaultSongVariations:Array<String> = [];

	override function fromBasicFormat(chart:BasicChart, ?diff:FormatDifficulty):FNFVSlice
	{
		var chartResolve = resolveDiffsNotes(chart, diff).notes;
		var meta = chart.meta;

		var notes:JsonMap<Array<FNFVSliceNote>> = {};
		var scrollSpeed:JsonMap<Float> = {};

		var basicBpmChanges = meta.bpmChanges.copy();
		var timeChanges:Array<FNFVSliceTimeChange> = [];

		for (change in basicBpmChanges)
		{
			timeChanges.push({
				t: change.time,
				bpm: change.bpm,
				n: Std.int(change.stepsPerBeat),
				d: Std.int(change.beatsPerMeasure)
			});
		}

		timeChanges.sort((a, b) -> return Util.sortValues(a.t, b.t));
		final lanesLength:Int = (meta.extraData.get(BasicMetaValues.LANES_LENGTH) ?? 8) <= 7 ? 4 : 8;

		for (chartDiff => chart in chartResolve)
		{
			var timeChangeIndex = 1;
			var stepCrochet:Float = Timing.stepCrochet(timeChanges[0].bpm, 4);
			var chartNotes:Array<FNFVSliceNote> = Util.makeArray(chart.length);

			for (i in 0...chart.length)
			{
				var note = Util.getArray(chart, i);
				var time = note.time;
				var length = note.length;

				// Find the last bpm change
				while (timeChangeIndex < timeChanges.length && timeChanges[timeChangeIndex].t <= time)
				{
					stepCrochet = Timing.stepCrochet(timeChanges[timeChangeIndex++].bpm, 4);
				}

				var kind = noteTypeResolver.fromBasic(note.type);
				var length = length > 0 ? length - (stepCrochet * 0.5) : 0;

				var vsliceNote:FNFVSliceNote = {
					t: time,
					d: (note.lane + 4 + lanesLength) % 8
				}

				if (length > 0)
					vsliceNote.l = length;

				if (kind != "normal")
					vsliceNote.k = kind;

				// Offset sustain length, vslice starts a step crochet later
				Util.setArray(chartNotes, i, vsliceNote);
			}

			var speed:Float = meta.scrollSpeeds.get(chartDiff) ?? 1.0;
			notes.set(chartDiff, chartNotes);
			scrollSpeed.set(chartDiff, speed);
		}

		final extraCamData:Array<String> = ['duration', 'mode', 'x', 'y', 'zoom']; // im too lazy to type these out manually lol
		var chartEvents = chart.data.events;
		var events:Array<FNFVSliceEvent> = Util.makeArray(chartEvents.length);

		for (i in 0...chartEvents.length)
		{
			var event = Util.getArray(chartEvents, i);
			var isBasicFocus:Bool = ((event.name != VSLICE_FOCUS_EVENT) && FNFGlobal.isCamFocus(event));

			if (!isBasicFocus)
			{
				Util.setArray(events, i, resolveVSliceEvent(event));
			}
			else
			{
				var camFocusData:BasicFNFCamFocusData = {
					char: FNFGlobal.resolveCamFocus(event),
					ease: event.data.ease ?? "CLASSIC"
				}

				for (value in extraCamData)
				{
					if (Reflect.hasField(event.data, value))
						Reflect.setField(camFocusData, value, Reflect.field(event.data, value));
				}

				Util.setArray(events, i, {
					t: event.time,
					e: VSLICE_FOCUS_EVENT,
					v: camFocusData
				});
			}
		}

		this.data = {
			scrollSpeed: scrollSpeed,
			notes: notes,
			events: events,
			version: VSLICE_CHART_VERSION,
			generatedBy: Util.version
		}

		var difficulties:Array<String> = Util.mapKeyArray(chart.data.diffs);
		var extra = meta.extraData;

		var p1:String = extra.get(FNFLegacyMetaValues.PLAYER_1) ?? "bf";
		var p2:String = extra.get(FNFLegacyMetaValues.PLAYER_2) ?? "dad";

		var vocalsMap:Null<Map<String, Float>> = extra.get(FNFLegacyMetaValues.VOCALS_OFFSET);
		var vocalsOffset:JsonMap<Float> = {};
		if (vocalsMap != null)
		{
			for (vocal => offset in vocalsMap)
			{
				switch (vocal)
				{
					case FNFLegacyMetaValues.PLAYER_1:
						vocalsOffset.set(p1, offset);
					case FNFLegacyMetaValues.PLAYER_2:
						vocalsOffset.set(p2, offset);
					default:
						vocalsOffset.set(vocal, offset);
				}
			}
		}

		var ratingsMap:Null<Map<String, Int>> = extra.get(SONG_RATINGS);
		var ratings:JsonMap<Int> = {};

		final noteStyle:String = OneOfArray.nullResolve(extra.get(BasicMetaValues.SONG_NOTE_SKIN), VSLICE_DEFAULT_NOTE_SKIN);

		this.meta = {
			timeFormat: "ms",
			artist: extra.get(BasicMetaValues.SONG_ARTIST) ?? Moonchart.DEFAULT_ARTIST,
			charter: extra.get(BasicMetaValues.SONG_CHARTER) ?? Moonchart.DEFAULT_CHARTER,
			playData: {
				album: extra.get(BasicMetaValues.SONG_ALBUM) ?? Moonchart.DEFAULT_ALBUM,
				previewStart: extra.get(FNFVSliceMetaValues.SONG_PREVIEW_START) ?? 0,
				previewEnd: extra.get(FNFVSliceMetaValues.SONG_PREVIEW_END) ?? 15000,
				ratings: ratings.fromMap(ratingsMap),
				stage: extra.get(FNFLegacyMetaValues.STAGE) ?? "mainStage",
				difficulties: difficulties,
				characters: {
					player: p1,
					opponent: p2,
					girlfriend: extra.get(FNFLegacyMetaValues.PLAYER_3) ?? "gf",
					instrumental: extra.get(FNFVSliceMetaValues.SONG_INSTRUMENTAL) ?? "",
					altInstrumentals: extra.get(FNFVSliceMetaValues.SONG_ALT_INSTRUMENTALS) ?? new Array<String>(),
					opponentVocals: extra.get(FNFVSliceMetaValues.SONG_OPPONENT_VOCALS),
					playerVocals: extra.get(FNFVSliceMetaValues.SONG_PLAYER_VOCALS)
				},
				songVariations: extra.get(FNFVSliceMetaValues.SONG_VARIATIONS) ?? defaultSongVariations,
				noteStyle: noteStyle
			},
			songName: meta.title,
			offsets: {
				vocals: vocalsOffset,
				instrumental: meta.offset,
				// TODO: whatever this is
				altInstrumentals: {},
				altVocals: {}
			},
			timeChanges: timeChanges,
			generatedBy: Util.version,
			version: VSLICE_META_VERSION,
			looped: false
		}

		return this;
	}

	function resolveVSliceEvent(event:BasicEvent):FNFVSliceEvent
	{
		// resolve basic fnf events
		switch (event.name)
		{
			case BasicFNFEvent.PLAY_ANIMATION:
				var basic:BasicFNFPlayAnimEvent = event.data;
				return {
					t: event.time,
					e: FNFVSlice.VSLICE_PLAY_ANIMATION_EVENT,
					v: {
						target: switch (basic.target.toLowerCase())
						{
							case "bf" | "boyfriend": "boyfriend";
							case "gf" | "girlfriend": "girlfriend";
							case "dad": "dad";
							default: basic.target;
						},
						force: basic.force,
						anim: basic.anim
					}
				}
			case BasicFNFEvent.ZOOM_CAMERA:
				var basic:BasicFNFZoomCameraEvent = event.data;
				return {
					t: event.time,
					e: FNFVSlice.VSLICE_CAMERA_ZOOM_EVENT,
					v: basic
				}
			case BasicFNFEvent.SET_CAMERA_BOP:
				var basic:BasicFNFSetCameraBopEvent = event.data;
				return {
					t: event.time,
					e: FNFVSlice.VSLICE_SET_CAMERA_BOP_EVENT,
					v: basic
				}
		}

		return {
			t: event.time,
			e: event.name,
			v: event.data
		};
	}

	override function getNotes(?diff:String):Array<BasicNote>
	{
		var chartNotes:Array<FNFVSliceNote> = data.notes.get(diff);
		if (chartNotes == null)
		{
			throw "Couldn't find FNF (V-Slice) notes for difficulty " + (diff ?? "null");
			return null;
		}

		var timeChanges = meta.timeChanges;
		var stepCrochet = Timing.stepCrochet(timeChanges[0].bpm, 4);
		var i:Int = 1;

		// Make sure all notes are in order
		chartNotes.sort((a, b) -> Util.sortValues(a.t, b.t));
		var notes:Array<BasicNote> = Util.makeArray(chartNotes.length);

		for (n in 0...chartNotes.length)
		{
			var note = chartNotes[n];
			var time = note.t;
			var length = note.l ?? 0.0;
			var kind = note.k ?? "";

			// Find the current bpm change
			while (i < timeChanges.length)
			{
				if (timeChanges[i].t > time)
					break;

				stepCrochet = Timing.stepCrochet(timeChanges[i++].bpm, 4);
			}

			Util.setArray(notes, n, {
				time: time,
				lane: (note.d + 4) % 8,
				length: length > 0 ? length + (stepCrochet * 0.5) : 0,
				type: resolveNoteType(kind)
			});
		}

		Timing.sortNotes(notes);

		return notes;
	}

	function resolveNoteType(type:String):BasicNoteType
	{
		return noteTypeResolver.toBasic(type);
	}

	override function getEvents():Array<BasicEvent>
	{
		var vsliceEvents = data.events;
		var eventsLength:Int = vsliceEvents.length;
		var events:Array<BasicEvent> = [];

		for (i in 0...eventsLength)
		{
			final event = Util.getArray(vsliceEvents, i);
			events.push(encodeVSliceEvent(event));

			// Push a camera position after a regular FocusCamera event
			// since Codename's version of the "Camera Position" event doesn't specify
			// a character and instead just offsets from current cam pos, we have to focus
			// on a character first so there is something to offset from
			if(event.e == FNFVSlice.VSLICE_FOCUS_EVENT) {
                final combinedEase:String = !(event.v is Int) ? ((event.v.ease ?? "CLASSIC") + (event.v.easeDir ?? "")) : "CLASSIC";
                if (!(event.v is Int) && ((event.v.x != null && event.v.x != 0) || (event.v.y != null && event.v.y != 0)))
    			{
    				final data:BasicFNFPositionCameraEvent = {
    					char: (event.v is Int) ? event.v : event.v.char ?? -1,
    					x: event.v.x ?? 0.0,
    					y: event.v.y ?? 0.0,
    					ease: combinedEase,
    					duration: event.v.duration ?? 4.0,
    					isOffset: true
    				}
    				events.push({
    					time: event.t,
    					name: BasicFNFEvent.POSITION_CAMERA,
    					data: data
     				});
    			}
			}
		}

		return events;
	}

	function encodeVSliceEvent(event:FNFVSliceEvent):BasicEvent
	{
		switch (event.e)
		{
		    case FNFVSlice.VSLICE_FOCUS_EVENT:
			    final combinedEase:String = !(event.v is Int) ? ((event.v.ease ?? "CLASSIC") + (event.v.easeDir ?? "")) : "CLASSIC";
				final data:BasicFNFCamFocusData = {
   					char: (event.v is Int) ? event.v : event.v.char ?? -1,
   					ease: combinedEase
				}
				final extraCamData:Array<String> = ['duration', 'mode', 'x', 'y', 'zoom']; // im too lazy to type these out manually lol
				for (value in extraCamData)
				{
   					if (Reflect.hasField(event.v, value))
  						Reflect.setField(data, value, Reflect.field(event.v, value));
				}
				return {
   					time: event.t,
   					name: event.e,
   					data: data
				}
			case FNFVSlice.VSLICE_PLAY_ANIMATION_EVENT:
				final data:BasicFNFPlayAnimEvent = {
					target: event.v.target,
					anim: event.v.anim,
					force: event.v.force
				}
				return {
					time: event.t,
					name: BasicFNFEvent.PLAY_ANIMATION,
					data: data
				}
			case FNFVSlice.VSLICE_CAMERA_ZOOM_EVENT:
				final data:BasicFNFZoomCameraEvent = {
					zoom: event.v.zoom ?? 1.0,
					duration: event.v.duration ?? 4,
					ease: (event.v.ease ?? "linear") + (event.v.easeDir ?? ""),
					mode: "stage"
				}
				return {
					time: event.t,
					name: BasicFNFEvent.ZOOM_CAMERA,
					data: data
				}
			case FNFVSlice.VSLICE_SET_CAMERA_BOP_EVENT:
				final data:BasicFNFSetCameraBopEvent = {
					rate: event.v.rate ?? 4,
					offset: event.v.offset ?? 0,
					intensity: event.v.intensity ?? 1.0
				}
				return {
					time: event.t,
					name: BasicFNFEvent.SET_CAMERA_BOP,
					data: data
				}
		}

		return {
			time: event.t,
			name: event.e,
			data: event.v
		}
	}

	override function getChartMeta():BasicMetaData
	{
		var timeChanges = meta.timeChanges;
		var bpmChanges:Array<BasicBPMChange> = Util.makeArray(timeChanges.length);

		for (i in 0...timeChanges.length)
		{
			final change = Util.getArray(timeChanges, i);
			Util.setArray(bpmChanges, i, {
				time: Math.max(change.t, 0.0), // Just making sure they all start at 0 lol
				bpm: change.bpm,
				beatsPerMeasure: change.d ?? 4,
				stepsPerBeat: change.n ?? 4
			});
		}

		var chars = meta.playData.characters;
		var vocalsOffset:Map<String, Float> = (meta.offsets?.vocals != null) ? meta.offsets.vocals.resolve() : [];
		var songRatings:Map<String, Int> = (meta.playData?.ratings != null) ? meta.playData.ratings.resolve() : [];
		var scrollSpeeds:Map<String, Float> = data.scrollSpeed.resolve();

		return {
			title: meta.songName,
			bpmChanges: bpmChanges,
			scrollSpeeds: scrollSpeeds,
			offset: meta.offsets?.instrumental ?? 0.0,
			extraData: [
				BasicMetaValues.SONG_ARTIST => meta.artist,
				BasicMetaValues.SONG_CHARTER => meta.charter,
				BasicMetaValues.SONG_ALBUM => meta.playData.album ?? Moonchart.DEFAULT_ALBUM,
				BasicMetaValues.SONG_NOTE_SKIN => meta.playData.noteStyle ?? VSLICE_DEFAULT_NOTE_SKIN,

				// vslice is strictly 2 lane 4 key
				BasicMetaValues.LANES_LENGTH => 8,
				BasicMetaValues.STRUMLINE_LANES => 2,
				BasicMetaValues.STRUMLINE_KEYS => 4,

				FNFLegacyMetaValues.PLAYER_1 => chars.player,
				FNFLegacyMetaValues.PLAYER_2 => chars.opponent,
				FNFLegacyMetaValues.PLAYER_3 => chars.girlfriend,
				FNFLegacyMetaValues.STAGE => meta.playData.stage,
				FNFLegacyMetaValues.VOCALS_OFFSET => vocalsOffset,
				FNFLegacyMetaValues.NEEDS_VOICES => true,

				FNFVSliceMetaValues.SONG_VARIATIONS => meta.playData.songVariations ?? [],
				FNFVSliceMetaValues.SONG_RATINGS => songRatings,
				FNFVSliceMetaValues.SONG_PREVIEW_START => meta.playData.previewStart ?? 0,
				FNFVSliceMetaValues.SONG_PREVIEW_END => meta.playData.previewEnd ?? 15000,
				FNFVSliceMetaValues.SONG_INSTRUMENTAL => meta.playData.characters.instrumental,
				FNFVSliceMetaValues.SONG_ALT_INSTRUMENTALS => meta.playData.characters.altInstrumentals,
				FNFVSliceMetaValues.SONG_OPPONENT_VOCALS => meta.playData.characters.opponentVocals,
				FNFVSliceMetaValues.SONG_PLAYER_VOCALS => meta.playData.characters.playerVocals,
			]
		}
	}

	public override function fromFile(path:String, ?meta:String, ?diff:FormatDifficulty):FNFVSlice
	{
		return fromJson(Util.getText(path), Util.getText(meta), diff);
	}

	public override function fromJson(data:String, ?meta:String, ?diff:FormatDifficulty):FNFVSlice
	{
		super.fromJson(data, meta, diff);
		this.diffs = diff ?? this.data.notes.keys();
		return this;
	}

	override public function fromPack(path:String, diff:FormatDifficulty):FNFVSlice
	{
		var zip = new ZipFile().openFile(path);
		var chartEntries = zip.filterEntries((entry) -> return entry.fileName.endsWith(".json"));

		var chart:String = "";
		var metadata:String = "";
		var manifest:String = "";

		for (entry in chartEntries)
		{
			if (entry.fileName.contains("chart"))
				chart = zip.unzipString(entry);
			else if (entry.fileName.contains("metadata"))
				metadata = zip.unzipString(entry);
			else if (entry.fileName.contains("manifest"))
				manifest = zip.unzipString(entry);
		}

		return fromJson(chart, metadata, diff);
	}
}

typedef FNFVSliceFormat =
{
	version:String,
	generatedBy:String,

	scrollSpeed:JsonMap<Float>,
	notes:JsonMap<Array<FNFVSliceNote>>,
	events:Array<FNFVSliceEvent>
}

typedef FNFVSliceNote =
{
	t:Float,
	d:Int,
	?l:Float,
	?k:String
}

typedef FNFVSliceEvent =
{
	t:Float,
	e:String,
	v:Dynamic
}

typedef FNFVSliceMeta =
{
	timeFormat:String,
	artist:String,
	charter:String,
	generatedBy:String,
	version:String,
	looped:Bool,

	playData:FNFVSlicePlayData,
	songName:String,
	offsets:FNFVSliceOffsets,
	timeChanges:Array<FNFVSliceTimeChange>
}

typedef FNFVSliceTimeChange =
{
	t:Float,
	bpm:Float,
	n:Int,
	d:Int
}

typedef FNFVSliceOffsets =
{
	instrumental:Float,
	vocals:JsonMap<Float>,
	altInstrumentals:JsonMap<Float>,
	altVocals:JsonMap<JsonMap<Float>>
}

typedef FNFVSliceManifest =
{
	version:String,
	songId:String
}

typedef FNFVSlicePlayData =
{
	album:String,
	previewStart:Int,
	previewEnd:Int,
	ratings:JsonMap<Int>,
	characters:
	{
		player:String, girlfriend:String, opponent:String, //
		instrumental:String, altInstrumentals:Array<String>, //
		opponentVocals:Array<String>, playerVocals:Array<String>
	},
	difficulties:Array<String>,
	songVariations:Array<String>,
	noteStyle:String,
	stage:String
}
