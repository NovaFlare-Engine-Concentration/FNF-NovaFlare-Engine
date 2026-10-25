package moonchart.formats.fnf;

import moonchart.backend.FormatData;
import moonchart.backend.Optimizer;
import moonchart.backend.Timing;
import moonchart.backend.Util;
import moonchart.formats.BasicFormat;
import moonchart.formats.fnf.FNFGlobal;
import moonchart.formats.fnf.legacy.FNFLegacy;

using StringTools;

enum abstract FNFCodenameNoteType(String) from String to String
{
	var CODENAME_ALT_ANIM = "Alt Anim Note";
	var CODENAME_NO_ANIM = "No Anim Note";
}

// TODO: support for psych gf notes / sections converted to the gf strumline?

class FNFCodename extends BasicJsonFormat<FNFCodenameFormat, FNFCodenameMeta>
{
	public static function __getFormat():FormatData
	{
		return {
			ID: FNF_CODENAME,
			name: "FNF (Codename)",
			description: "Divided per strumline FNF format with lots of metadata.",
			extension: "json",
			hasMetaFile: POSSIBLE,
			metaFileExtension: "json",
			specialValues: [
				'_"codenameChart":',
				'_"codenameChart":',
				'_"codenameChart":',
				'_"codenameChart":',
				'"strumLines":'
			],
			handler: FNFCodename
		}
	}

	public static inline var CODENAME_BPM_CHANGE:String = "BPM Change";
	public static inline var CODENAME_TIME_SIG_CHANGE:String = "Time Signature Change";
	public static inline var CODENAME_CAM_MOVEMENT:String = "Camera Movement";
	public static inline var CODENAME_CAM_POSITION:String = "Camera Position";

	public var noteTypeResolver(default, null):FNFNoteTypeResolver;

	public function new(?data:FNFCodenameFormat, ?meta:FNFCodenameMeta)
	{
		super({timeFormat: MILLISECONDS, supportsDiffs: true, supportsEvents: true});
		this.data = data;
		this.meta = meta;
		beautify = true;

		// Register FNF Codename note types
		noteTypeResolver = FNFGlobal.createNoteTypeResolver();
		noteTypeResolver.register(FNFCodenameNoteType.CODENAME_ALT_ANIM, BasicFNFNoteType.ALT_ANIM);
		noteTypeResolver.register(FNFCodenameNoteType.CODENAME_NO_ANIM, BasicFNFNoteType.NO_ANIM);
	}

	override function fromBasicFormat(chart:BasicChart, ?diff:FormatDifficulty):FNFCodename
	{
		var chartResolve = resolveDiffsNotes(chart, diff);
		var diff:String = chartResolve.diffs[0];
		var basicNotes:Array<BasicNote> = chartResolve.notes.get(diff);
		var meta = chart.meta;

		// Creating by default 3 strumlines (dad, bf, gf)
		// May need to rework the method down the line
		var strumlines:Array<FNFCodenameStrumline> = Util.makeArray(3);
		for (i in 0...3)
		{
			strumlines[i] = {
				position: switch (i)
				{
					case 0: "dad";
					case 1: "boyfriend";
					default: "girlfriend";
				},
				strumScale: 1,
				visible: (i < 2),
				type: i,
				keyCount: 4, // TODO
				characters: [
					switch (i)
					{
						case 0:
							meta.extraData.get(PLAYER_2) ?? "dad";
						case 1:
							meta.extraData.get(PLAYER_1) ?? "bf";
						default:
							meta.extraData.get(PLAYER_3) ?? "gf";
					}
				],
				strumPos: [0, 50],
				strumLinePos: switch (i)
				{
					case 1: 0.75;
					default: 0.25;
				},
				vocalsSuffix: "",
				notes: []
			}
		}

		var noteTypes:Array<String> = [];

		for (note in basicNotes)
		{
			var lane:Int = note.lane;
			var strumline:FNFCodenameStrumline = strumlines[Std.int(lane / 4)];

			if (strumline == null)
				continue;

			var type:Int = resolveCodenameType(note.type, noteTypes);
			var id:Int = lane % 4;

			strumline.notes.push({
				time: note.time,
				id: id,
				sLen: note.length,
				type: type
			});
		}

		// Push normal events / cam movement events
		var basicEvents = chart.data.events;
		var events:Array<FNFCodenameEvent> = Util.makeArray(basicEvents.length);

		for (i in 0...basicEvents.length)
		{
			Util.setArray(events, i, resolveCodenameEvent(basicEvents[i]));
		}

		// Push bpm change events
		final firstChange = chart.meta.bpmChanges[0];

		for (i in 1...chart.meta.bpmChanges.length)
		{
			final bpmChange = chart.meta.bpmChanges[i];
			events.push({
				time: bpmChange.time,
				name: CODENAME_BPM_CHANGE,
				params: [bpmChange.bpm]
			});
			events.push({
				time: bpmChange.time,
				name: CODENAME_TIME_SIG_CHANGE,
				params: [bpmChange.beatsPerMeasure, bpmChange.stepsPerBeat]
			});
		}

		events.sort((a, b) -> return Util.sortValues(a.time, b.time));

		// Finally add all the data

		this.data = {
			codenameChart: true,
			scrollSpeed: meta.scrollSpeeds.get(diff) ?? 1.0,
			stage: meta.extraData.get(STAGE) ?? "stage",
			noteTypes: noteTypes,
			strumLines: strumlines,
			events: events,
			meta: null
		}

		this.meta = {
			opponentModeAllowed: true,
			coopAllowed: true,
			stepsPerBeat: firstChange.stepsPerBeat,
			beatsPerMeasure: firstChange.beatsPerMeasure,
			bpm: firstChange.bpm,
			difficulties: this.diffs,
			needsVoices: meta.extraData.get(NEEDS_VOICES) ?? false,
			displayName: meta.title,
			customValues: {
				composers: meta.extraData.get(SONG_ARTIST) ?? Moonchart.DEFAULT_ARTIST,
				charters: meta.extraData.get(SONG_CHARTER) ?? Moonchart.DEFAULT_CHARTER
			},
			icon: "bf",
			name: formatSongName(meta.title),
			color: ""
		}

		return this;
	}

	function resolveCodenameEvent(event:BasicEvent):FNFCodenameEvent
	{
		final isFocus:Bool = event.name != CODENAME_CAM_MOVEMENT && FNFGlobal.isCamFocus(event);

		if (isFocus)
		{
			return resolveCamFocus(event);
		}

		switch (event.name)
		{
			case BasicFNFEvent.PLAY_ANIMATION:
				var data:BasicFNFPlayAnimEvent = event.data;
				var target:Int = switch (data.target)
				{
					case 'boyfriend' | 'bf' | 'player': 1;
					case 'dad' | 'opponent': 0;
					default: 2;
				}
				return {
					time: event.time,
					name: "Play Animation",
					params: [target, data.anim, data.force]
				}

			case BasicFNFEvent.ZOOM_CAMERA:
				var data:BasicFNFZoomCameraEvent = event.data;

				var easing = resolveEase(data.ease, "linear");

				return {
					time: event.time,
					name: "Camera Zoom",
					params: [
						data.ease != "INSTANT",
						data.zoom,
						"camGame",
						data.duration,
						easing[0],
						easing[1]
					] // TODO: add missing params
				}

			case BasicFNFEvent.POSITION_CAMERA:
				var data:BasicFNFPositionCameraEvent = event.data;

				var easing = resolveEase(data.ease);

				return {
					time: event.time,
					name: "Camera Position",
					params: [
						data.x,
						data.y,
						data.ease != "INSTANT",
						data.duration,
						easing[0],
						easing[1],
						data.isOffset
					]
				}

			case BasicFNFEvent.SET_CAMERA_BOP:
				var data:BasicFNFSetCameraBopEvent = event.data;
				return {
					time: event.time,
					name: "Camera Modulo Change",
					params: [data.rate, data.intensity]
				}
		}

		return {
			time: event.time,
			name: event.name,
			params: Util.resolveEventValues(event)
		}
	}

	function resolveCamFocus(event:BasicEvent):FNFCodenameEvent
	{
		var isPosition:Bool = false;
		final char:Int = switch (FNFGlobal.resolveCamFocus(event))
		{
			case DAD: 0;
			case BF: 1;
			case GF: 2;
			case -1:
				isPosition = true;
				-1;
			default: 2;
		}

		final easing:Array<String> = resolveEase(event.data.ease);

		final duration:Int = event.data.duration ?? 4;
		final doLerp:Bool = easing[0] != "INSTANT";

		// character(int), lerp(bool), duration(int), ease(string), easeSuffix(?string)

		// TODO: add "Camera Position" event

		return {
			time: event.time,
			name: CODENAME_CAM_MOVEMENT,
			params: [char, doLerp, duration, easing[0], easing[1]]
		}
	}

	function resolveEase(ease:String, defaultEase:String = "CLASSIC"):Array<String>
	{
		var easeDir:String = "";

		var easeCheck:String = ease.toLowerCase();
		if (easeCheck.endsWith("in"))
			easeDir = "In";
		else if (easeCheck.endsWith("inout"))
			easeDir = "InOut";
		else if (easeCheck.endsWith("out"))
			easeDir = "Out";

		var easing:Array<String> = [ease.substr(0, ease.length - easeDir.length), easeDir];

		if (easing[0] == null || easing[0] == "")
			easing[0] = "linear"; // default to classic camera movement ease

		return easing;
	}

	inline function formatSongName(name:String):String
	{
		return name.toLowerCase();
	}

	function resolveCodenameType(type:String, list:Array<String>):Int
	{
		if (type.length <= 0)
			return 0;

		if (list.contains(type))
			return list.indexOf(type);

		list.push(type);
		return list.length - 1;
	}

	override function getNotes(?diff:String):Array<BasicNote>
	{
		var notes:Array<BasicNote> = [];

		for (i => strumline in data.strumLines)
		{
			for (note in strumline.notes)
			{
				var lane:Int = note.id + (4 * i);
				notes.push({
					time: note.time,
					lane: lane,
					length: note.sLen,
					type: resolveNoteType(note.type)
				});
			}
		}

		Timing.sortNotes(notes);
		return notes;
	}

	public function resolveNoteType(type:Int)
	{
		if (data.noteTypes[0] != "")
		{
			// make sure the default note type is added here otherwise
			// 0 will link to something like "Alt Animation" or any other non-default note type
			// 0 in codename is always the default note type
			data.noteTypes.insert(0, "");
		}
		var noteType = data.noteTypes[type] ?? "";
		return noteTypeResolver.toBasic(noteType);
	}

	function encodeCodenameEvent(event:FNFCodenameEvent):BasicEvent
	{
		var time:Float = event.time;
		switch (event.name)
		{
			case FNFCodename.CODENAME_CAM_POSITION:
				var data:BasicFNFPositionCameraEvent = {
					char: -1,
					x: event.params[0],
					y: event.params[1],
					ease: (event.params[2]) ? ((event.params[4] ?? "linear") + (event.params[5] ?? "")) : "CLASSIC",
					duration: (event.params[2]) ? event.params[3] : 0,
					isOffset: event.params[6]
				};
				return {
					time: time,
					name: BasicFNFEvent.POSITION_CAMERA,
					data: data
				}
		}
		return Util.makeArrayEvent(time, event.name, event.params);
	}

	override function getEvents():Array<BasicEvent>
	{
		var events:Array<BasicEvent> = [];

		for (event in data.events)
		{
			if (event.name != CODENAME_BPM_CHANGE && event.name != CODENAME_TIME_SIG_CHANGE)
				events.push(encodeCodenameEvent(event));
		}

		// Set the default init cam movement
		events.unshift({
			time: -1,
			name: CODENAME_CAM_MOVEMENT,
			data: {
				array: [0]
			}
		});

		return events;
	}

	function getStrumline(position:String):FNFCodenameStrumline
	{
		for (strumline in data.strumLines)
		{
			if (strumline.position == position)
				return strumline;
		}

		return null;
	}

	override function getChartMeta():BasicMetaData
	{
		var bpmChanges:Array<BasicBPMChange> = [
			{
				time: -1,
				bpm: meta.bpm,
				stepsPerBeat: meta.stepsPerBeat,
				beatsPerMeasure: meta.beatsPerMeasure
			}
		];

		final bpmEvents = data.events.filter((e) -> e.name == CODENAME_BPM_CHANGE);
		bpmEvents.sort((a, b) -> return Util.sortValues(a.time, b.time));

		final timeSigEvents = data.events.filter((e) -> e.name == CODENAME_TIME_SIG_CHANGE);
		timeSigEvents.sort((a, b) -> return Util.sortValues(a.time, b.time));

		// TODO: should i not do "function in function" syntax here?
		function getBPMAtMS(ms:Float):Float
		{
			var output = null;
			for (i in 0...bpmEvents.length)
			{
				var point = bpmEvents[i];
				if (ms >= point.time)
					output = point;
			}
			return output?.params[0] ?? meta.bpm; // I LOVE YOU NULL COLE E ASSING
		}
		function getTimeSigAtMS(ms:Float):Array<Float>
		{
			var output = null;
			for (i in 0...timeSigEvents.length)
			{
				var point = timeSigEvents[i];
				if (ms >= point.time)
					output = point;
			}
			if (output?.params != null)
			{
				return [
					output.params[0],
					(output.params[2])
					? output.params[1] : Math.floor(16 / output.params[1])
				];
			}
			return [meta.beatsPerMeasure, meta.stepsPerBeat]; // I LOVE YOU NULL COLE E ASSING
		}

		for (event in data.events)
		{
			switch (event.name)
			{
				case CODENAME_BPM_CHANGE:
					var appropriateTimeSig = getTimeSigAtMS(event.time);
					bpmChanges.push({
						time: event.time,
						bpm: event.params[0],
						stepsPerBeat: appropriateTimeSig[1],
						beatsPerMeasure: appropriateTimeSig[0]
					});

				case CODENAME_TIME_SIG_CHANGE:
					var appropriateBPM = getBPMAtMS(event.time);
					bpmChanges.push({
						time: event.time,
						bpm: appropriateBPM,
						stepsPerBeat: (event.params[2]) ? event.params[1] : Math.floor(16 / event.params[1]),
						beatsPerMeasure: event.params[0]
					});
			}
		}

		Timing.sortBPMChanges(bpmChanges);

		var lanesLength:Int = 0;
		var strumlineLanes:Int = 0;
		var strumlineKeys:Array<Int> = [];

		for (lane in data.strumLines)
		{
			if (!lane.visible)
				continue;

			var keys = lane.keyCount ?? 4;
			strumlineKeys.push(keys);
			lanesLength += keys;
			strumlineLanes++;
		}

		return {
			title: meta.displayName,
			bpmChanges: bpmChanges,
			offset: 0.0,
			scrollSpeeds: [diffs[0] => data.scrollSpeed],
			extraData: [
				PLAYER_1 => getStrumline("boyfriend")?.characters[0] ?? "bf",
				PLAYER_2 => getStrumline("dad")?.characters[0] ?? "bf",
				PLAYER_3 => getStrumline("girlfriend")?.characters[0] ?? "bf",
				SONG_ARTIST => meta?.customValues?.composers ?? Moonchart.DEFAULT_ARTIST,
				SONG_CHARTER => meta?.customValues?.charters ?? Moonchart.DEFAULT_CHARTER,
				STAGE => data.stage,

				LANES_LENGTH => lanesLength,
				STRUMLINE_LANES => strumlineLanes,
				STRUMLINE_KEYS => strumlineKeys
			]
		};
	}

	public override function fromFile(path:String, ?meta:String, ?diff:FormatDifficulty):FNFCodename
	{
		return fromJson(Util.getText(path), Util.getText(meta), diff);
	}

	public override function fromJson(data:String, ?meta:String, ?diff:FormatDifficulty):FNFCodename
	{
		super.fromJson(data, meta, diff);

		Optimizer.addDefaultValues(this.data, {
			events: []
		});

		this.diffs = diff ?? this.meta.difficulties;
		return this;
	}
}

typedef FNFCodenameFormat =
{
	strumLines:Array<FNFCodenameStrumline>,
	events:Array<FNFCodenameEvent>,
	meta:FNFCodenameMeta,
	codenameChart:Bool,
	stage:String,
	scrollSpeed:Float,
	noteTypes:Array<String>
}

typedef FNFCodenameStrumline =
{
	position:String,
	strumScale:Float,
	visible:Bool,
	type:Int,
	characters:Array<String>,
	strumPos:Array<Float>,
	strumLinePos:Float,
	vocalsSuffix:String,
	notes:Array<FNFCodenameNote>,
	keyCount:Int,
}

typedef FNFCodenameNote =
{
	time:Float,
	id:Int,
	sLen:Float,
	type:Int
}

typedef FNFCodenameEvent =
{
	time:Float,
	name:String,
	params:Array<Dynamic>
}

typedef FNFCodenameMeta =
{
	name:String,
	?bpm:Float,
	?displayName:String,
	?beatsPerMeasure:Float,
	?stepsPerBeat:Float,
	?needsVoices:Bool,
	?icon:String,
	?color:Dynamic,
	?difficulties:Array<String>,
	?coopAllowed:Bool,
	?opponentModeAllowed:Bool,
	?customValues:Dynamic
}
