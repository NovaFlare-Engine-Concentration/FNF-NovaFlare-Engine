package moonchart.formats.fnf.legacy;

import haxe.Json;
import moonchart.backend.FormatData;
import moonchart.backend.Timing;
import moonchart.backend.Util;
import moonchart.formats.BasicFormat;
import moonchart.formats.fnf.FNFGlobal;
import moonchart.formats.fnf.legacy.FNFLegacy;

using StringTools;

enum abstract FNFPsychEvent(String) from String to String
{
	var GF_SECTION = "FNF_PSYCH_GF_SECTION";
}

enum abstract FNFPsychNoteType(String) from String to String
{
	var PSYCH_ALT_ANIM = "Alt Animation";
	var PSYCH_HURT_NOTE = "Hurt Note";
	var PSYCH_NO_ANIM = "No Animation";
	var PSYCH_GF_SING = "GF Sing";
}

class FNFPsych extends FNFPsychBasic<PsychJsonFormat>
{
	public static function __getFormat():FormatData
	{
		return {
			ID: FNF_LEGACY_PSYCH,
			name: "FNF (Psych Engine)",
			description: "The most common FNF Legacy branching format.",
			extension: "json",
			formatFile: FNFLegacy.formatFile,
			hasMetaFile: POSSIBLE,
			metaFileExtension: "json",
			specialValues: ['?"events":', '?"gfVersion":', '?"gfSection":', '"stage":'],
			handler: FNFPsych
		}
	}

	override function fromJson(data:String, ?meta:String, ?diff:FormatDifficulty):FNFPsych
	{
		return cast super.fromJson(data, meta, diff);
	}
}

@:private
@:noCompletion
class FNFPsychBasic<T:PsychJsonFormat> extends FNFLegacyMetaBasic<T, {song:T}>
{
	/**
	 * If to stack the values of events with more than 2 values due to psych's 2 value event limit.
	 * Turn it off to limit your values to just the first 2 found in the data array.
	 * The string separator for the stacked events is accesible through ``stackEventsSeparator``.
	 */
	public var stackEvents:Bool = true;

	/**
	 * String separator used when a event is stacked.
	 * Set to ``","`` by default.
	 * Only used if ``stackEvents`` is true.
	 */
	public var stackEventsSeparator:String = ",";

	/**
	 * If to use the legacy Psych engine format for output.
	 * Turn off to use the Psych V1 chart format.
	 * Turned on by default.
	 */
	public var legacyExport:Bool = true;

	public function new(?data:T)
	{
		super(data);
		this.formatMeta.supportsEvents = true;
		beautify = true;

		// Register FNF Psych note types
		noteTypeResolver.register(FNFPsychNoteType.PSYCH_ALT_ANIM, BasicFNFNoteType.ALT_ANIM);
		noteTypeResolver.register(FNFPsychNoteType.PSYCH_NO_ANIM, BasicFNFNoteType.NO_ANIM);
		noteTypeResolver.register(FNFPsychNoteType.PSYCH_HURT_NOTE, BasicNoteType.MINE);
		noteTypeResolver.register(FNFPsychNoteType.PSYCH_GF_SING, BasicFNFNoteType.GF_SING);
	}

	function resolvePsychEvent(event:BasicEvent):PsychEvent
	{
		// resolve basic fnf events
		switch (event.name)
		{
			case BasicFNFEvent.PLAY_ANIMATION:
				var data:BasicFNFPlayAnimEvent = event.data;

				if (data.anim == "hey")
				{
					return makePsychEvent(event.time, "Hey!", data.target, "");
				}

				return makePsychEvent(event.time, "Play Animation", data.anim, data.target);

			case BasicFNFEvent.POSITION_CAMERA:
				var data:BasicFNFPositionCameraEvent = event.data;
				return makePsychEvent(event.time, "Camera Follow Pos", Std.string(data.x), Std.string(data.y));
		}

		final values:Array<Dynamic> = Util.resolveEventValues(event);
		var value1:String = "";
		var value2:String = "";

		if (stackEvents && values.length > 2)
		{
			value1 = values.join(stackEventsSeparator);
		}
		else
		{
			if (values[0] != null)
				value1 = Std.string(values[0]);
			if (values[1] != null)
				value2 = Std.string(values[1]);
		}

		return makePsychEvent(event.time, event.name, value1, value2);
	}

	function makePsychEvent(time:Float, name:String, value1:String, value2:String):PsychEvent
	{
		return [time, [[name, value1, value2]]];
	}

	// TODO: add GF_SECTION event inputs
	override function fromBasicFormat(chart:BasicChart, ?diff:FormatDifficulty):FNFPsychBasic<T>
	{
		var basic = super.fromBasicFormat(chart, diff);
		var song = basic.data.song;

		var chartEvents = chart.data.events;
		var psychEvents:Array<PsychEvent> = [];
		song.events = psychEvents;

		var lastTime:Float = -1;
		var eventsGroup:Array<PsychEvent> = [];

		final closePsychEventPack = function()
		{
			if (eventsGroup.length > 0)
			{
				var psychEvent:PsychEvent = [lastTime, [for (psychEvent in eventsGroup) psychEvent.pack[0]]];
				psychEvents.push(psychEvent);
				eventsGroup.resize(0);
			}
		}

		for (basicEvent in chartEvents)
		{
			if (Timing.roundFloat(basicEvent.time) != lastTime)
			{
				closePsychEventPack();
				lastTime = Timing.roundFloat(basicEvent.time);
			}

			eventsGroup.push(resolvePsychEvent(basicEvent));
		}

		closePsychEventPack();

		song.gfVersion = chart.meta.extraData.get(PLAYER_3) ?? "gf";
		song.stage = chart.meta.extraData.get(STAGE) ?? "stage";

		return cast basic;
	}

	override function getEvents():Array<BasicEvent>
	{
		var events = super.getEvents();

		// Push GF section events
		var lastGfSection:Bool = false;
		forEachSection(data.song.notes, (section, startTime, endTime) ->
		{
			var psychSection:PsychSection = cast section;

			var gfSection:Bool = (psychSection.gfSection ?? false);
			if (gfSection != lastGfSection)
			{
				events.push(makeGfSectionEvent(startTime, gfSection));
				lastGfSection = gfSection;
			}
		});

		// Push normal psych events
		for (baseEvent in data.song.events)
		{
			var time:Float = baseEvent.time;
			var pack:Array<PackedPsychEvent> = baseEvent.pack;
			for (event in pack)
			{
				events.push(encodePackedPsychEvent(event, time));
			}
		}

		Timing.sortEvents(events);
		return events;
	}

	function encodePackedPsychEvent(event:PackedPsychEvent, time:Float):BasicEvent
	{
		switch (event.name)
		{
			case "Play Animation":
				var target:String = event.value2.toLowerCase().trim();

				switch (target)
				{
					case '0': target = 'dad';
					case '1': target = 'bf';
					case '2': target = 'gf';
				}

				var data:BasicFNFPlayAnimEvent = {
					target: target,
					anim: event.value1,
					force: true
				}

				return {
					time: time,
					name: BasicFNFEvent.PLAY_ANIMATION,
					data: data
				}

			case "Camera Follow Pos":
				var data:BasicFNFPositionCameraEvent = {
					char: -1,
					x: Std.parseFloat(event.value1),
					y: Std.parseFloat(event.value2),
					ease: "CLASSIC",
					duration: 0, // ease doesn't matter on the CLASSIC ease
					isOffset: false
				}
				return {
					time: time,
					name: BasicFNFEvent.POSITION_CAMERA,
					data: data
				}
		}

		return {
			time: time,
			name: event.name,
			data: {
				VALUE_1: event.value1,
				VALUE_2: event.value2
			}
		}
	}

	override function filterEvents(events:Array<BasicEvent>):Array<BasicEvent>
	{
		return super.filterEvents(events).filter((event) -> return event.name != GF_SECTION);
	}

	function makeGfSectionEvent(time:Float, gfSection:Bool):BasicEvent
	{
		return {
			time: time,
			name: GF_SECTION,
			data: {
				gfSection: gfSection
			}
		}
	}

	override function getChartMeta():BasicMetaData
	{
		var meta = super.getChartMeta();
		meta.extraData.set(PLAYER_3, data.song.gfVersion ?? data.song.player3);
		meta.extraData.set(STAGE, data.song.stage);
		return meta;
	}

	var psychOutputFormat:String = "psych_v1";
	var legacyPsychOutputFormat:String = "psych_v1_convert";

	override function stringify():FormatStringify
	{
		var psychData:Dynamic = data;

		if (legacyExport)
		{
			data.song.format = legacyPsychOutputFormat;
		}
		else
		{
			data.song.format = psychOutputFormat;
			psychData = data.song;
		}

		return {
			data: psychData != null ? Json.stringify(psychData, formatting) : null,
			meta: meta != null ? Json.stringify(meta, formatting) : null
		}
	}

	override function fromJson(data:String, ?meta:String, ?diff:FormatDifficulty):FNFPsychBasic<T>
	{
		super.fromJson(data, meta, diff);

		// Support check for Psych 1.0 format
		final hasPsychV1Format = (data:Dynamic) ->
		{
			var format = data.format;
			if (format != null && format == "psych_v1")
				return true;

			return data.song is String;
		}

		if (hasPsychV1Format(this.data))
		{
			this.data = {song: cast this.data};
			offsetMustHits = false;
		}

		if (this.meta != null && hasPsychV1Format(this.meta))
		{
			this.meta = {song: cast this.meta};
		}

		updateEvents(this.data.song, this.meta?.song);
		return this;
	}

	override function resolveBasicMeasure(measure:BasicMeasure, section:FNFLegacySection, list:Array<FNFLegacySection>)
	{
		final section:PsychSection = cast section;

		section.sectionBeats = section.lengthInSteps / 4;
		Reflect.deleteField(section, "lengthInSteps");

		if (!section.altAnim)
		{
			Reflect.deleteField(section, "altAnim");
		}

		if (!section.changeBPM)
		{
			Reflect.deleteField(section, "bpm");
			Reflect.deleteField(section, "changeBPM");
		}

		if (measure.bpmChanges.length > 1)
		{
			// divide multiple bpm changes inside one measure into multiple smaller measures
			// may have to add a check if to do this or not
			// idk how "recent" sectionsBeats was in the psych format

			var lastChange = measure.bpmChanges[0];
			var pushedBeats:Float = 0.0;

			for (i in 1...measure.bpmChanges.length)
			{
				var nextChange = measure.bpmChanges[i];

				var elapsed = nextChange.time - lastChange.time;
				var elapsedBeats = Timing.roundFloat(elapsed / Timing.crochet(lastChange.bpm));

				var sectionNotes:Array<FNFLegacyNote> = [];
				while (section.sectionNotes.length > 0 && section.sectionNotes[0].time < nextChange.time)
				{
					sectionNotes.push(section.sectionNotes.shift());
				}

				var newSection:PsychSection = {
					sectionNotes: sectionNotes,
					mustHitSection: section.mustHitSection,
					changeBPM: true,
					bpm: lastChange.bpm,
					sectionBeats: elapsedBeats
				};

				super.resolveBasicMeasure(measure, newSection, list);

				pushedBeats += elapsedBeats;
				lastChange = nextChange;
			}

			// add missing shit from the last change
			var sectionNotes:Array<FNFLegacyNote> = [];
			while (section.sectionNotes.length > 0)
			{
				sectionNotes.push(section.sectionNotes.shift());
			}

			var lastElapsedBeats:Float = Timing.roundFloat(section.sectionBeats - pushedBeats);
			var newSection:PsychSection = {
				sectionNotes: sectionNotes,
				mustHitSection: section.mustHitSection,
				changeBPM: true,
				bpm: lastChange.bpm,
				sectionBeats: lastElapsedBeats
			};

			super.resolveBasicMeasure(measure, newSection, list);
		}
		else
		{
			super.resolveBasicMeasure(measure, section, list);
		}
	}

	override function sectionBeats(?section:FNFLegacySection):Float
	{
		var psychSection:Null<PsychSection> = cast section;
		return psychSection?.sectionBeats ?? super.sectionBeats(section);
	}

	// Merge the events meta file and convert -1 lane notes to events
	function updateEvents(song:PsychJsonFormat, ?events:PsychJsonFormat):Void
	{
		var songNotes:Array<FNFLegacySection> = song.notes;
		song.events ??= [];
		this.meta = null;

		if (events != null)
		{
			songNotes = songNotes.concat(events.notes ?? []);
			song.events = song.events.concat(events.events ?? []);
		}

		for (section in songNotes)
		{
			var sectionNotes:Array<FNFLegacyNote> = section.sectionNotes;

			for (i => note in sectionNotes)
			{
				if (note.lane <= -1)
				{
					song.events.push([note.time, [[note[2], note[3], note[4]]]]);
					Util.setArray(sectionNotes, i, null);
				}
			}

			var index:Int = sectionNotes.indexOf(null);
			while (index != -1)
			{
				sectionNotes.splice(index, 1);
				index = sectionNotes.indexOf(null);
			}
		}
	}
}

abstract PsychEvent(Array<Dynamic>) from Array<Dynamic> to Array<Dynamic>
{
	public var time(get, never):Float;
	public var pack(get, never):Array<PackedPsychEvent>;

	inline function get_time()
		return this[0];

	inline function get_pack()
		return this[1];
}

abstract PackedPsychEvent(Array<String>) from Array<String> to Array<String>
{
	public var name(get, never):String;
	public var value1(get, never):String;
	public var value2(get, never):String;

	inline function get_name()
		return this[0];

	inline function get_value1()
		return this[1];

	inline function get_value2()
		return this[2];
}

typedef PsychSection = FNFLegacySection &
{
	?sectionBeats:Float,
	?gfSection:Bool // TODO: add as an event probably
}

typedef PsychJsonFormat = FNFLegacyFormat &
{
	?format:String,

	?events:Array<PsychEvent>,
	?gfVersion:String,
	stage:String,

	?gameOverChar:String,
	?gameOverSound:String,
	?gameOverLoop:String,
	?gameOverEnd:String,

	?disableNoteRGB:Bool,
	?arrowSkin:String,
	?splashSkin:String,

	?player3:String
}
