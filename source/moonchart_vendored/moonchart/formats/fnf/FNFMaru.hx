package moonchart.formats.fnf;

import haxe.Json;
import moonchart.backend.FormatData;
import moonchart.backend.Optimizer;
import moonchart.backend.Timing;
import moonchart.backend.Util;
import moonchart.formats.BasicFormat.BasicChart;
import moonchart.formats.BasicFormat;
import moonchart.formats.fnf.FNFGlobal.BasicFNFNoteType;
import moonchart.formats.fnf.legacy.FNFLegacy;

using StringTools;

// hi maru!!! hi!!! love you!!!
// hi unholy!!! i love you more!!!

@:deprecated("Maru Funkin' engine is dead.")
@:noCompletion
enum abstract FNFMaruNoteType(String) from String to String
{
	var MARU_DEFAULT = "default";
	var MARU_HEY = "default-hey";
	var MARU_ALT_ANIM = "default-alt";
	var MARU_FIRE = "fire";
}

/**
 * Pretty similar to FNFLegacy although with enough changes to need a seperate implementation
 */
@:deprecated("Maru Funkin' engine is dead.")
@:noCompletion
class FNFMaru extends BasicJsonFormat<{song:FNFMaruJsonFormat}, FNFMaruMetaFormat>
{
	public static function __getFormat():FormatData
	{
		return {
			ID: FNF_MARU,
			name: "FNF (Maru)",
			description: "Like FNF Legacy but worse.",
			extension: "json",
			formatFile: formatFile,
			hasMetaFile: POSSIBLE,
			metaFileExtension: "json",
			specialValues: ['_"offsets":', '"stage":', '?"players":', '?"player3":'],
			handler: FNFMaru
		}
	}

	public static function formatFile(title:String, diff:String):Array<String>
	{
		return [diff.trim().toLowerCase()];
	}

	public static function formatTitle(title:String):String
	{
		var formattedTitle:String = "";
		title = title.trim();
		for (i in 0...title.length)
		{
			final code:Int = title.fastCodeAt(i);
			switch (code)
			{
				case ".".code | "?".code | "*".code | '"'.code | "'".code:
				case " ".code | ":".code:
					formattedTitle += "-";
				case _:
					formattedTitle += String.fromCharCode(code).toLowerCase();
			}
		}
		return formattedTitle;
	}

	// Easier to work with, same format pretty much lol
	var legacy:FNFLegacyBasic<FNFLegacyFormat>;

	public function new(?data:{song:FNFMaruJsonFormat})
	{
		super({timeFormat: MILLISECONDS, supportsDiffs: false, supportsEvents: true});
		this.data = data;

		legacy = new FNFLegacyBasic();
		legacy.bakedOffset = false;

		// Register FNF Maru note types
		var noteTypeResolver = legacy.noteTypeResolver;
		noteTypeResolver.register(FNFMaruNoteType.MARU_DEFAULT, BasicNoteType.DEFAULT);
		noteTypeResolver.register(FNFMaruNoteType.MARU_ALT_ANIM, BasicFNFNoteType.ALT_ANIM);
		noteTypeResolver.register(FNFMaruNoteType.MARU_HEY, BasicFNFNoteType.CHEER);
		noteTypeResolver.register(FNFMaruNoteType.MARU_FIRE, BasicNoteType.MINE);
	}

	override function fromBasicFormat(chart:BasicChart, ?diff:FormatDifficulty):FNFMaru
	{
		legacy.fromBasicFormat(chart, diff);
		var fnfData = legacy.data.song;

		var chartResolve = resolveDiffsNotes(chart, diff);
		var diffChart:Array<BasicNote> = chartResolve.notes.get(chartResolve.diffs[0]);

		var measures:Array<BasicMeasure> = Timing.divideNotesToMeasures(diffChart, chart.data.events, chart.meta.bpmChanges);
		var maruNotes:Array<FNFMaruSection> = [];

		for (i => section in fnfData.notes)
		{
			// Copy pasted lol
			var maruSection:FNFMaruSection = {
				sectionNotes: section.sectionNotes,
				sectionEvents: [],
				mustHitSection: section.mustHitSection,
				changeBPM: section.changeBPM,
				bpm: section.bpm
			}

			// Push events to the section
			if (i < measures.length && measures[i].events.length > 0)
			{
				var measureEvents = measures[i].events;
				var maruEvents = maruSection.sectionEvents;
				Util.resizeArray(maruEvents, measureEvents.length);

				for (i in 0...measureEvents.length)
				{
					Util.setArray(maruEvents, i, resolveMaruEvent(measureEvents[i]));
				}
			}

			maruNotes.push(maruSection);
		}

		var extra = chart.meta.extraData;

		var vocalsMap:Map<String, Float> = chart.meta.extraData.get(VOCALS_OFFSET);
		var vocalsOffset:Int = 0;
		var instOffset:Int = Std.int(chart.meta.offset ?? 0.0);

		// Check through all possible values
		if (vocalsMap != null)
		{
			for (i in [PLAYER_1, PLAYER_2, fnfData.player1, fnfData.player2])
			{
				if (vocalsMap.exists(i))
				{
					vocalsOffset = Std.int(vocalsMap.get(i));
					break;
				}
			}
		}

		this.data = {
			song: {
				song: fnfData.song,
				bpm: fnfData.bpm,
				notes: maruNotes,
				offsets: [instOffset, vocalsOffset],
				speed: fnfData.speed,
				stage: extra.get(STAGE) ?? "stage",
				players: [fnfData.player1, fnfData.player2, extra.get(PLAYER_3) ?? "gf"]
			}
		}

		this.meta = {
			events: [], // this.data.song.notes,
			offset: this.data.song.offsets,
			diffs: chartResolve.diffs
		}

		return this;
	}

	function resolveMaruEvent(event:BasicEvent):FNFMaruEvent
	{
		var values:Array<Dynamic> = Util.resolveEventValues(event);
		return [event.time, event.name, values];
	}

	override function getNotes(?diff:String):Array<BasicNote>
	{
		legacy.data = cast this.data;
		return legacy.getNotes(diff);
	}

	override function getEvents():Array<BasicEvent>
	{
		legacy.data = cast this.data;
		var events:Array<BasicEvent> = legacy.getEvents();

		for (section in data.song.notes)
		{
			for (event in section.sectionEvents)
			{
				events.push(Util.makeArrayEvent(event.time, event.name, event.values));
			}
		}

		Timing.sortEvents(events);
		return events;
	}

	override function getChartMeta():BasicMetaData
	{
		var song = data.song;
		legacy.data = cast this.data;

		return {
			title: song.song,
			bpmChanges: legacy.getChartMeta().bpmChanges,
			offset: song.offsets[0],
			scrollSpeeds: [diffs[0] => song.speed],
			extraData: [
				PLAYER_1 => song.players.bf,
				PLAYER_2 => song.players.dad,
				PLAYER_3 => song.players.gf,
				VOCALS_OFFSET => [PLAYER_1 => song.offsets[1] ?? 0, PLAYER_2 => song.offsets[1] ?? 0],
				NEEDS_VOICES => true,
				LANES_LENGTH => 8
			]
		}
	}

	public var optimizedOutput:Bool = true;

	override function stringify()
	{
		var data:{song:FNFMaruJsonFormat} = this.data;

		if (optimizedOutput)
		{
			data = Json.parse(Json.stringify(data));

			for (section in data.song.notes)
			{
				Optimizer.removeDefaultValues(section, {
					sectionNotes: null,
					sectionEvents: null,
					mustHitSection: true,
					changeBPM: false,
					bpm: 0
				});
			}
		}

		// TODO: port over the json stringify from Maru Funkin'
		return {
			data: Json.stringify(data, formatting),
			meta: Json.stringify(meta, formatting)
		}
	}

	public override function fromFile(path:String, ?meta:String, ?diff:String):FNFMaru
	{
		return fromJson(Util.getText(path), meta, diff);
	}

	public override function fromJson(data:String, ?meta:String, ?diff:String):FNFMaru
	{
		super.fromJson(data, meta, diff);

		final s = this.data.song;
		s.players ??= [s.player1 ?? "bf", s.player2 ?? "dad", s.player3 ?? "gf"];

		// Maru format turns null some values for filesize reasons
		for (section in s.notes)
		{
			Optimizer.addDefaultValues(section, {
				bpm: 0,
				changeBPM: false,
				mustHitSection: true,
				sectionNotes: [],
				sectionEvents: []
			});
		}

		return this;
	}
}

@:deprecated("Maru Funkin' engine is dead.")
@:noCompletion
typedef FNFMaruJsonFormat =
{
	song:String,
	notes:Array<FNFMaruSection>,
	bpm:Float,
	speed:Float,
	offsets:Array<Int>,
	stage:String,
	players:FNFMaruPlayers,

	// Backwards compat
	?player1:String,
	?player2:String,
	?player3:String
}

@:deprecated("Maru Funkin' engine is dead.")
@:noCompletion
typedef FNFMaruSection =
{
	var sectionNotes:Array<FNFLegacyNote>;
	var sectionEvents:Array<FNFMaruEvent>;
	var mustHitSection:Bool;
	var bpm:Float;
	var changeBPM:Bool;
}

@:deprecated("Maru Funkin' engine is dead.")
@:noCompletion
typedef FNFMaruMetaFormat =
{
	var events:Array<FNFMaruSection>;
	var offset:Array<Int>;
	var diffs:Array<String>;
}

@:deprecated("Maru Funkin' engine is dead.")
@:noCompletion
abstract FNFMaruEvent(Array<Dynamic>) from Array<Dynamic> to Array<Dynamic>
{
	public var time(get, set):Float;
	public var name(get, set):String;
	public var values(get, set):Array<Dynamic>;

	inline function get_time():Float
		return this[0];

	inline function get_name():String
		return this[1];

	inline function get_values():Array<Dynamic>
		return this[2];

	inline function set_time(v):Float
		return this[0] = v;

	inline function set_name(v):String
		return this[1] = v;

	inline function set_values(v):Array<Dynamic>
		return this[2] = v;
}

@:deprecated("Maru Funkin' engine is dead.")
@:noCompletion
abstract FNFMaruPlayers(Array<String>) from Array<String> to Array<String>
{
	public var bf(get, set):String;
	public var dad(get, set):String;
	public var gf(get, set):String;

	inline function get_bf():String
		return this[0];

	inline function get_dad():String
		return this[1];

	inline function get_gf():String
		return this[2];

	inline function set_bf(v):String
		return this[0] = v;

	inline function set_dad(v):String
		return this[1] = v;

	inline function set_gf(v):String
		return this[2] = v;
}
