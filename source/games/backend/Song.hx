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

	// 新增：格式检测相关
	public static var detectedFormat:String = 'unknown';
	public static var chartEngineVersion:String = 'Pe-0.7.3';
	public static var forceEngineVersion:String = null; // null=auto, 'Pe-0.7.3' or 'Pe-1.0.4' to force
	public static var isNewFormat:Bool = false; // 是否为新版本格式

	private static function onLoadJson(songJson:Dynamic) //修复铺面json缺少数据的问题
	{
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
		{
			songJson.mania = 3;
		}
	}

	public function new(song, notes, bpm)
	{
		this.song = song;
		this.notes = notes;
		this.bpm = bpm;
	}

	public static var chartPath:String;
	public static var loadedSongName:String;

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

	public static function parseJSON(rawData:String, ?nameForError:String = null, convertTo:String = 'psych_v1'):SwagSong
	{
		var parsedJson:Dynamic = Json.parse(rawData);
		
		// ========== 新版检测逻辑 ==========
		var hasWrapper:Bool = Reflect.hasField(parsedJson, 'song');
		
		// 先尝试从外层或内层获取format
		var fmt:String = null;
		if (Reflect.hasField(parsedJson, 'format'))
			fmt = parsedJson.format;
		else if (hasWrapper)
		{
			var subSong:Dynamic = Reflect.field(parsedJson, 'song');
			if (subSong != null && Reflect.hasField(subSong, 'format'))
				fmt = subSong.format;
		}
		
		// 检测是否为psych_v1格式（新版本）
		isNewFormat = (fmt != null && (fmt.startsWith('psych_v1') || fmt == 'psych_v1_convert'));
		
		if (fmt != null && fmt.startsWith('psych_v1'))
			detectedFormat = 'Pe-1.0.x';
		else
			detectedFormat = hasWrapper ? 'Pe-0.7.3' : 'Pe-1.0.x';
		
		if (forceEngineVersion != null && forceEngineVersion.length > 0)
		{
			chartEngineVersion = forceEngineVersion;
		}
		else
		{
			chartEngineVersion = (detectedFormat == 'Pe-1.0.x') ? 'Pe-1.0.4' : 'Pe-0.7.3';
		}
		// ========== 检测逻辑结束 ==========

		// ========== 旧版逻辑（添加新格式跳过转换） ==========
		var songJson:SwagSong = cast parsedJson;
		
		if (Reflect.hasField(songJson, 'format')) {
			// pe1.0没song包裹
			if (songJson.format.length > 0 && songJson.format.indexOf(convertTo) != -1)
			{
				// 只有非新格式才执行转换
				if (!isNewFormat)
					castVersion(songJson);
			}
		} else {
			var subSong:SwagSong = Reflect.field(songJson, 'song');
			if (subSong != null && Type.typeof(subSong) == TObject)
			{
				songJson = subSong;
			}

			if (Reflect.hasField(songJson, 'format'))
				if (songJson.format.length > 0 && songJson.format.indexOf(convertTo) != -1)
				{
					// 只有非新格式才执行转换
					if (!isNewFormat)
						castVersion(songJson);
				}
		}

		onLoadJson(songJson);
		// ========== 旧版逻辑结束 ==========

		return songJson;
	}

	public static function castVersion(songJson:SwagSong):SwagSong
	{
		// 旧版的完整转换逻辑
		for (i in 0...songJson.notes.length)
		{
			for (ii in 0...songJson.notes[i].sectionNotes.length)
			{
				var gottaHitNote:Bool = songJson.notes[i].mustHitSection;
				if (!gottaHitNote)
				{
					if (songJson.notes[i].sectionNotes[ii][1] >= 4)
					{
						songJson.notes[i].sectionNotes[ii][1] -= 4;
					}
					else if (songJson.notes[i].sectionNotes[ii][1] <= 3)
					{
						songJson.notes[i].sectionNotes[ii][1] += 4;
					}
				}
			}
		}
		return songJson;
	}
}