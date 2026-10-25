package moonchart.formats.fnf.legacy;

import moonchart.backend.FormatData;
import moonchart.backend.Timing;
import moonchart.backend.Util;
import moonchart.formats.BasicFormat;
import moonchart.formats.fnf.FNFGlobal;

using StringTools;

class FNFLegacy extends FNFLegacyBasic<FNFLegacyFormat>
{
	/**
	 * The default must hit section value.
	 */
	public static var FNF_LEGACY_DEFAULT_MUSTHIT:Bool = true;

	public static inline var FNF_LEGACY_MUST_HIT_SECTION_EVENT:String = "FNF_MUST_HIT_SECTION";

	public static function __getFormat():FormatData
	{
		return {
			ID: FNF_LEGACY,
			name: "FNF (Legacy)",
			description: "The original section-based FNF format.",
			extension: "json",
			formatFile: formatFile,
			hasMetaFile: FALSE,
			specialValues: ['_"notes":'],
			handler: FNFLegacy
		};
	}

	public static function formatFile(title:String, diff:String):Array<String>
	{
		diff = diff.trim().toLowerCase();
		var diffSuffix:String = (diff == "normal") ? "" : "-" + diff.replace(" ", "-");
		return [title.replace(" ", "-").trim().toLowerCase() + diffSuffix];
	}

	// TODO: Maybe some add some metadata for extrakey formats?
	public static inline function mustHitLane(mustHit:Bool, lane:Int):Int
	{
		return (mustHit ? lane : (lane + 4) % 8);
	}

	public static inline function makeMustHitSectionEvent(time:Float, mustHit:Bool):BasicEvent
	{
		return {
			time: time,
			name: FNF_LEGACY_MUST_HIT_SECTION_EVENT,
			data: {
				mustHitSection: mustHit
			}
		}
	}

	public function new(?data:FNFLegacyFormat)
	{
		indexedTypes = true;
		super(data);
	}
}

@:private
@:noCompletion
typedef FNFLegacyBasic<T:FNFLegacyFormat> = FNFLegacyMetaBasic<T, Dynamic>; // basic legacy format with no metadata

@:private
@:noCompletion
class FNFLegacyMetaBasic<T:FNFLegacyFormat, M> extends BasicJsonFormat<{song:T}, M> // basic legacy format with metadata
{
	/**
	 * FNF (Legacy) handles sustains by being 1 step crochet behind their actual length.
	 * You can turn it off here if your legacy extended format doesn't have this quirk.
	 */
	public var offsetHolds:Bool = true;

	/**
	 * If to bake the song offset when loading from a basic format to the song's note times.
	 * Turn it off if your format has some sort of song offset value.
	 */
	public var bakedOffset:Bool = true;

	/**
	 * If to import the note types as ints rather than strings.
	 * Most legacy-branching formats use strings but legacy up to 0.2.7.1 used ints.
	 */
	public var indexedTypes:Bool = false;

	/**
	 * If to offset the note lanes depending on the mustHit section value.
	 * Most legacy-branching formats use this offset.
	 */
	public var offsetMustHits:Bool = true;

	/**
	 * If to keep cam focus events data when converting from another format.
	 * Useful for keeping additional cam focus data a legacy FNF format may not support by default.
	 * Such as easing data, duration, positioning, etc
	 */
	public var keepCamFocusEvents:Bool = false;

	/**
	 * Resolver for FNF note type IDs.
	 */
	public var noteTypeResolver(default, null):FNFNoteTypeResolver;

	public function new(?data:T)
	{
		super({timeFormat: MILLISECONDS, supportsDiffs: false, supportsEvents: false});
		this.data = {song: data};

		// Register FNF Legacy note types
		noteTypeResolver = FNFGlobal.createNoteTypeResolver();
		if (indexedTypes)
		{
			noteTypeResolver.register(0, BasicNoteType.DEFAULT);
			noteTypeResolver.register(1, BasicFNFNoteType.ALT_ANIM);
		}
	}

	public function resolveMustHitLane(mustHit:Bool, lane:Int):Int
	{
		return offsetMustHits ? FNFLegacy.mustHitLane(mustHit, lane) : lane;
	}

	override function fromBasicFormat(chart:BasicChart, ?diff:FormatDifficulty):FNFLegacyMetaBasic<T, M>
	{
		var chartResolve = resolveDiffsNotes(chart, diff);
		var diff:String = chartResolve.diffs[0];
		var basicNotes:Array<BasicNote> = chartResolve.notes.get(diff);

		final meta = chart.meta;
		final initBpm = meta.bpmChanges[0].bpm;

		final notes:Array<FNFLegacySection> = [];
		final measures = Timing.divideNotesToMeasures(basicNotes, chart.data.events, meta.bpmChanges);

		final lanesLength:Int = (meta.extraData.get(LANES_LENGTH) ?? 8) <= 7 ? 4 : 8;
		final offset:Float = meta.offset;

		// Take out must hit events
		chart.data.events = filterEvents(chart.data.events);

		var lastBpm = initBpm;
		var lastMustHit:Bool = FNFLegacy.FNF_LEGACY_DEFAULT_MUSTHIT;
		var nextMustHit:Null<Bool> = null;

		for (measure in measures)
		{
			var mustHit:Bool = lastMustHit;

			if (nextMustHit != null)
			{
				mustHit = nextMustHit;
				nextMustHit = null;
			}

			// Push must hit events
			for (event in measure.events)
			{
				// Check if measure has a must hit event
				if (FNFGlobal.isCamFocus(event))
				{
					var eventMustHit = FNFGlobal.resolveCamFocus(event) == BF;
					var eventTime = (event.time - measure.startTime);
					if (eventTime < measure.length / 2)
					{
						mustHit = eventMustHit;
						nextMustHit = null;
					}
					else
					{
						// Event happens too late, save it for the next measure (aprox)
						nextMustHit = eventMustHit;
					}
				}
			}

			// Create legacy section
			var section:FNFLegacySection = {
				sectionNotes: [],
				mustHitSection: mustHit,
				lengthInSteps: Std.int(measure.stepsPerBeat * measure.beatsPerMeasure),
				altAnim: false,
				changeBPM: false,
				bpm: 0.0
			}

			lastMustHit = mustHit;

			// Section has a bpm change event (aprox)
			if (measure.bpm != lastBpm)
			{
				section.changeBPM = true;
				section.bpm = measure.bpm;
				lastBpm = measure.bpm;
			}

			final stepCrochet:Float = offsetHolds ? getHoldOffset(measure.bpm, measure.stepsPerBeat) : 0;

			// Push notes to section
			for (note in measure.notes)
			{
				final lane:Int = resolveMustHitLane(mustHit, (note.lane + 4 + lanesLength) % 8);
				final length:Float = note.length > 0 ? Math.max(note.length - stepCrochet, 0) : 0;
				final type:FNFLegacyNoteType = resolveBasicNoteType(note.type);

				final hasType = (type is String) ? (type != DEFAULT) : (type != 0);
				final fnfNote:FNFLegacyNote = hasType ? [note.time, lane, length, type] : [note.time, lane, length];

				if (bakedOffset)
				{
					fnfNote.time -= offset;
				}

				section.sectionNotes.push(fnfNote);
			}

			resolveBasicMeasure(measure, section, notes);
		}

		this.data = cast {
			song: {
				song: meta.title,
				bpm: initBpm,
				speed: meta.scrollSpeeds.get(diff) ?? Util.mapFirst(meta.scrollSpeeds) ?? 1.0,
				needsVoices: meta.extraData.get(NEEDS_VOICES) ?? false,
				validScore: true,
				player1: meta.extraData.get(PLAYER_1) ?? "bf",
				player2: meta.extraData.get(PLAYER_2) ?? "dad",
				notes: notes
			}
		};

		return this;
	}

	public function resolveBasicMeasure(measure:BasicMeasure, section:FNFLegacySection, list:Array<FNFLegacySection>):Void
	{
		list.push(section);
	}

	public function filterEvents(events:Array<BasicEvent>):Array<BasicEvent>
	{
		if (keepCamFocusEvents)
			return events;
		return FNFGlobal.filterEvents(events);
	}

	public function resolveBasicNoteType(type:BasicFNFNoteType):FNFLegacyNoteType
	{
		var noteType:FNFLegacyNoteType = noteTypeResolver.fromBasic(type);
		return (indexedTypes && !(noteType is Int)) ? 0 : noteType;
	}

	public function resolveNoteType(note:FNFLegacyNote):BasicFNFNoteType
	{
		return noteTypeResolver.toBasic(note.type);
	}

	function getHoldOffset(bpm:Float, stepsPerBeat:Float):Float
	{
		return Timing.stepCrochet(bpm, stepsPerBeat);
	}

	override function getNotes(?diff:String):Array<BasicNote>
	{
		var notes:Array<BasicNote> = [];
		var stepCrochet = offsetHolds ? getHoldOffset(data.song.bpm, 4) : 0;

		for (section in data.song.notes)
		{
			if (section.changeBPM && offsetHolds)
			{
				stepCrochet = getHoldOffset(section.bpm, 4);
			}

			for (note in section.sectionNotes)
			{
				final lane:Int = resolveMustHitLane(section.mustHitSection, (note.lane + 4) % 8);
				final length:Float = note.length > 0 ? note.length + stepCrochet : 0;
				final type:String = section.altAnim ? ALT_ANIM : resolveNoteType(note);

				notes.push({
					time: note.time,
					lane: lane,
					length: length,
					type: type
				});
			}
		}

		Timing.sortNotes(notes);

		return notes;
	}

	override function getEvents():Array<BasicEvent>
	{
		var events:Array<BasicEvent> = [];
		var lastMustHit:Bool = FNFLegacy.FNF_LEGACY_DEFAULT_MUSTHIT;

		// Push musthit events
		forEachSection(data.song.notes, (section, startTime, endTime) ->
		{
			if (section.mustHitSection != lastMustHit)
			{
				events.push(FNFLegacy.makeMustHitSectionEvent(startTime, section.mustHitSection));
				lastMustHit = section.mustHitSection;
			}
		});

		return events;
	}

	function forEachSection(sections:Array<FNFLegacySection>, call:(FNFLegacySection, Float, Float) -> Void)
	{
		var time:Float = 0;
		var crochet = Timing.measureCrochet(data.song.bpm, 4);

		for (section in sections)
		{
			if (section.changeBPM)
			{
				var beats:Float = sectionBeats(section);
				crochet = Timing.measureCrochet(section.bpm, beats);
			}

			call(section, time, time + crochet);
			time += crochet;
		}
	}

	function sectionBeats(?section:FNFLegacySection):Float
	{
		return (section?.lengthInSteps ?? 16) / 4;
	}

	override function getChartMeta():BasicMetaData
	{
		var bpmChanges:Array<BasicBPMChange> = [];

		bpmChanges.push({
			time: 0.0,
			bpm: data.song.bpm,
			beatsPerMeasure: sectionBeats(data.song.notes[0]),
			stepsPerBeat: 4
		});

		forEachSection(data.song.notes, (section, startTime, endTime) ->
		{
			if (section.changeBPM)
				bpmChanges.push({
					time: startTime,
					bpm: section.bpm,
					beatsPerMeasure: sectionBeats(section),
					stepsPerBeat: 4
				});
		});

		return {
			title: data.song.song,
			bpmChanges: bpmChanges,
			offset: 0.0,
			scrollSpeeds: Util.fillMap(diffs, data.song.speed),
			extraData: [
				PLAYER_1 => data.song.player1,
				PLAYER_2 => data.song.player2,
				NEEDS_VOICES => data.song.needsVoices,
				LANES_LENGTH => 8,
				STRUMLINE_LANES => 2,
				STRUMLINE_KEYS => 4,
			]
		}
	}

	public override function fromFile(path:String, ?meta:StringInput, ?diff:FormatDifficulty):FNFLegacyMetaBasic<T, M>
	{
		if (meta != null)
		{
			var arr = meta.resolve();
			meta = arr;
			for (i in 0...arr.length)
				arr[i] = Util.getText(arr[i]);
		}

		return fromJson(Util.getText(path), meta, diff);
	}

	public override function fromJson(data:String, ?meta:StringInput, ?diff:FormatDifficulty):FNFLegacyMetaBasic<T, M>
	{
		return cast super.fromJson(fixLegacyJson(data), meta, diff);
	}

	// Old json charts were hyper fucked with corrupted data
	function fixLegacyJson(rawJson:String):String
	{
		var split = rawJson.split("}");
		var pop = split.length - 1;

		if (split[pop].length > 0)
			split[pop] = "";

		rawJson = split.join("}");

		return rawJson;
	}
}

typedef FNFLegacyFormat =
{
	song:String,
	bpm:Float,
	speed:Float,
	needsVoices:Bool,
	validScore:Bool,
	player1:String,
	player2:String,
	notes:Array<FNFLegacySection>
}

typedef FNFLegacySection =
{
	mustHitSection:Bool,
	?lengthInSteps:Int,
	sectionNotes:Array<FNFLegacyNote>,
	?altAnim:Bool,
	?changeBPM:Bool,
	?bpm:Float
}

/*enum abstract FNFLegacyEvent(String) from String to String
	{
	var MUST_HIT_SECTION = "FNF_MUST_HIT_SECTION";
	var ALT_ANIM_SECTION = "FNF_ALT_ANIM_SECTION";
}*/
enum abstract FNFLegacyMetaValues(String) from String to String
{
	var PLAYER_1 = "FNF_P1";
	var PLAYER_2 = "FNF_P2";
	var PLAYER_3 = "FNF_P3";
	var STAGE = "FNF_STAGE";
	var NEEDS_VOICES = "FNF_NEEDS_VOICES";
	var VOCALS_OFFSET = "FNF_VOCALS_OFFSET";
}

// TODO: FNF legacy and vslice (?) have the quirk of having lengths be 1 step crochet behind their actual length
// Should prob account for those, specially since formats like stepmania exist that require very specific hold lengths

abstract FNFLegacyNote(Array<Dynamic>) from Array<Dynamic> to Array<Dynamic>
{
	public var time(get, set):Float;
	public var lane(get, set):Int;
	public var length(get, set):Float;
	public var type(get, set):FNFLegacyNoteType;

	inline function get_time():Float
		return this[0];

	inline function get_lane():Int
		return this[1];

	inline function get_length():Float
		return this[2];

	inline function get_type():FNFLegacyNoteType
		return this[3];

	inline function set_time(v):Float
		return this[0] = v;

	inline function set_lane(v):Int
		return this[1] = v;

	inline function set_length(v):Float
		return this[2] = v;

	inline function set_type(v):FNFLegacyNoteType
		return this[3] = v;

	public static inline function make():FNFLegacyNote
	{
		return [0, 0, 0, ""];
	}
}
