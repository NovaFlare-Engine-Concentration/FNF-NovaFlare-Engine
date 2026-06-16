package games.backend;

import haxe.Json;

import openfl.utils.Assets;

import games.backend.Section;
import games.objects.Note;

typedef SwagSong =
{
	var song:String;
	var notes:Array<SwagSection>;
	var events:Array<Dynamic>;
	var bpm:Float;
	var needsVoices:Bool;
	var speed:Float;

	var player1:String;
	var player2:String;
	var gfVersion:String;
	var stage:String;
	var format:String;

	@:optional var gameOverChar:String;
	@:optional var gameOverSound:String;
	@:optional var gameOverLoop:String;
	@:optional var gameOverEnd:String;

	@:optional var disableNoteRGB:Bool;

	@:optional var arrowSkin:String;
	@:optional var splashSkin:String;

	@:optional var mania:Int;
	@:optional var mapper:String;
	@:optional var musican:String;
}

class Song
{
	public var song:String = null;
	public var notes:Array<SwagSection>;
	public var events:Array<Dynamic>;
	public var bpm:Float;
	public var needsVoices:Bool = true;
	public var arrowSkin:String;

	public var splashSkin:String;
	public var gameOverChar:String;
	public var gameOverSound:String;
	public var gameOverLoop:String;
	public var gameOverEnd:String;
	public var disableNoteRGB:Bool = false;
	public var speed:Float = 1;
	public var stage:String;
	public var player1:String = 'bf';
	public var player2:String = 'dad';
	public var gfVersion:String = 'gf';

	public var mapper:String = 'N/A';
	public var musican:String = 'N/A';
	public var mania:Int = 3;
	public var format:String = 'psych_v1';

	/**
	 * Convert old-format charts (0.7.x and earlier) to psych_v1 format
	 */
	public static function convert(songJson:Dynamic):Void
	{
		if (songJson.gfVersion == null)
		{
			songJson.gfVersion = songJson.player3;
			if (Reflect.hasField(songJson, 'player3'))
				Reflect.deleteField(songJson, 'player3');
		}

		if (songJson.events == null)
		{
			songJson.events = [];
			for (secNum in 0...songJson.notes.length)
			{
				var sec:SwagSection = songJson.notes[secNum];

				var i:Int = 0;
				var notes:Array<Dynamic> = sec.sectionNotes;
				var len:Int = notes.length;
				while (i < len)
				{
					var note:Array<Dynamic> = notes[i];
					if (note[1] < 0)
					{
						songJson.events.push([note[0], [[note[2], note[3], note[4]]]]);
						notes.remove(note);
						len = notes.length;
					}
					else
						i++;
				}
			}
		}

		var sectionsData:Array<SwagSection> = songJson.notes;
		if (sectionsData == null)
			return;

		for (section in sectionsData)
		{
			var beats:Null<Float> = cast section.sectionBeats;
			if (beats == null || Math.isNaN(beats))
			{
				section.sectionBeats = 4;
				if (Reflect.hasField(section, 'lengthInSteps'))
					Reflect.deleteField(section, 'lengthInSteps');
			}

			for (note in section.sectionNotes)
			{
				if (!Std.isOfType(note[3], String) && note[3] != null)
					note[3] = Note.defaultNoteTypes[note[3]];
			}
		}
	}

	private static function fixMissingFields(songJson:Dynamic):Void
	{
		if (songJson.song == null) songJson.song = 'Unknown';
		if (songJson.player2 == null) songJson.player2 = 'dad';
		if (songJson.speed == null) songJson.speed = 1;
		if (songJson.needsVoices == null) songJson.needsVoices = true;
		if (songJson.bpm == null)
		{
			if (songJson.notes != null && songJson.notes.length > 0 && songJson.notes[0].bpm != null)
				songJson.bpm = songJson.notes[0].bpm;
			else
				songJson.bpm = 100;
		}

		if (songJson.gfVersion == null)
		{
			songJson.gfVersion = songJson.player3;
			songJson.player3 = null;
		}

		if (songJson.events == null)
		{
			songJson.events = [];
			for (secNum in 0...songJson.notes.length)
			{
				var sec:SwagSection = songJson.notes[secNum];

				var i:Int = 0;
				var notes:Array<Dynamic> = sec.sectionNotes;
				var len:Int = notes.length;
				while (i < len)
				{
					var note:Array<Dynamic> = notes[i];
					if (note[1] < 0)
					{
						songJson.events.push([note[0], [[note[2], note[3], note[4]]]]);
						notes.remove(note);
						len = notes.length;
					}
					else
						i++;
				}
			}
		}

		if (songJson.mania == null)
			songJson.mania = 3;

		if (songJson.format == null)
			songJson.format = 'psych_v1_convert';
	}

	public function new(song, notes, bpm)
	{
		this.song = song;
		this.notes = notes;
		this.bpm = bpm;
	}

	public static var chartPath:String;
	public static var loadedSongName:String;
	public static var detectedFormat:String = 'unknown';
	public static var chartEngineVersion:String = 'Pe-0.7.3';
	public static var forceEngineVersion:String = null; // null=auto, 'Pe-0.7.3' or 'Pe-1.0.4' to force

	public static function loadFromJson(jsonInput:String, ?folder:String):SwagSong
	{
		if (folder == null)
			folder = jsonInput;
		PlayState.SONG = getChart(jsonInput, folder);
		loadedSongName = folder;
		chartPath = _lastPath;
		#if windows
		chartPath = chartPath.replace('/', '\\');
		#end
		StageData.loadDirectory(PlayState.SONG);
		return PlayState.SONG;
	}

	static var _lastPath:String;

	public static function getChart(jsonInput:String, ?folder:String):SwagSong
	{
		if (folder == null)
			folder = jsonInput;
		var rawData:String = null;

		var formattedFolder:String = Paths.formatToSongPath(folder);
		var formattedSong:String = Paths.formatToSongPath(jsonInput);
		_lastPath = Paths.json('$formattedFolder/$formattedSong');

		#if MODS_ALLOWED
		if (FileSystem.exists(_lastPath))
			rawData = File.getContent(_lastPath);
		else
		#end
		rawData = Assets.getText(_lastPath);

		return rawData != null ? parseJSON(rawData, jsonInput) : null;
	}

	/**
	 * Parse a chart JSON string. Auto-detects format and converts if needed.
	 *
	 * Supports:
	 *   - psych_v1 (1.0+): { "song": {...}, "format": "psych_v1" } or top-level format
	 *   - Old format (0.7.x): { "song": {...} } without format field → auto-converted
	 *   - Already converted: format "psych_v1_convert" → skip conversion
	 */
	public static function parseJSON(rawData:String, ?nameForError:String = null, ?convertTo:String = 'psych_v1'):SwagSong
	{
		var parsedJson:Dynamic = Json.parse(rawData);
		var hasWrapper:Bool = Reflect.hasField(parsedJson, 'song');

		if (hasWrapper)
		{
			var subSong:Dynamic = Reflect.field(parsedJson, 'song');
			if (subSong != null && Type.typeof(subSong) == TObject)
				parsedJson = subSong;
		}

		var songJson:SwagSong = cast parsedJson;

		// Detect original format: check format field first, wrapper as fallback
		var fmt:String = songJson.format;
		if (fmt != null && fmt.startsWith('psych_v1'))
			detectedFormat = 'Pe-1.0.x';
		else
			detectedFormat = hasWrapper ? 'Pe-0.7.3' : 'Pe-1.0.x';
		if (fmt == null || fmt.length == 0)
			songJson.format = detectedFormat;

		// Auto-detect engine version from chart format, or use forced override
		// Both engines are supported natively at runtime (PlayState interprets notes accordingly)
		if (forceEngineVersion != null && forceEngineVersion.length > 0)
		{
			chartEngineVersion = forceEngineVersion;
		}
		else
		{
			chartEngineVersion = (detectedFormat == 'Pe-1.0.x') ? 'Pe-1.0.4' : 'Pe-0.7.3';
		}

		// Always normalize (events, gfVersion, note types) but never convert note lanes
		convert(songJson);

		fixMissingFields(songJson);

		return songJson;
	}

	public static function castVersion(songJson:SwagSong):SwagSong
	{
		convert(songJson);
		return songJson;
	}
}
