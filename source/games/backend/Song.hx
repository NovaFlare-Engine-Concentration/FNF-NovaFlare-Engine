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
	@:optional var keyCount:Int;
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

	/**
	 * 把 Legacy（0.7.x）的相对 lane 语义转成 psych_v1 的绝对 lane 语义。
	 *
	 * Legacy:  note[1] ∈ 0..cols-1 表示 mustHitSection 那一侧，cols..2*cols-1 表示反侧。
	 * psych_v1: note[1] ∈ 0..cols-1 = 玩家侧，cols.. = 对手侧。
	 * 方向与 PE 1.0.4 的 Song.convert 一致，区别是这里按谱面实际列数算（支持 mania），
	 * 官方那边写死 4 键。
	 *
	 * 不能塞进 convert()：parseJSON 无条件调 convert，那样老谱面会被转 lane
	 * 却仍按 Pe-0.7.3 解释（双重转换）。只在"显式升级到 psych_v1"的路径调用。
	 */
	public static function convertNoteLanesToPsychV1(songJson:Dynamic, cols:Int = 4):Void
	{
		var sectionsData:Array<SwagSection> = songJson.notes;
		if (sectionsData == null) return;
		if (cols < 1) cols = 4;

		for (section in sectionsData)
		{
			var mustHit:Bool = (section.mustHitSection == true);
			for (note in section.sectionNotes)
			{
				if (note[1] < 0) continue; // 事件 note 用负数 lane，不参与
				var gottaHitNote:Bool = (note[1] < cols) ? mustHit : !mustHit;
				note[1] = (Std.int(note[1]) % cols) + (gottaHitNote ? 0 : cols);
			}
		}
	}

	/**
	 * convertNoteLanesToPsychV1 的逆运算：psych_v1 绝对 lane → Legacy 相对 lane。
	 * 供编辑器写 Legacy 谱面用，保证按 mustHitSection 解释的老引擎读出来归属不变。
	 */
	public static function convertNoteLanesToLegacy(songJson:Dynamic, cols:Int = 4):Void
	{
		var sectionsData:Array<SwagSection> = songJson.notes;
		if (sectionsData == null) return;
		if (cols < 1) cols = 4;

		for (section in sectionsData)
		{
			var mustHit:Bool = (section.mustHitSection == true);
			for (note in section.sectionNotes)
			{
				if (note[1] < 0) continue;
				var isPlayerSide:Bool = (note[1] < cols);
				var sameSide:Bool = (isPlayerSide == mustHit);
				note[1] = (Std.int(note[1]) % cols) + (sameSide ? 0 : cols);
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
		{
			var keyCount:Null<Float> = cast songJson.keyCount;
			if (keyCount != null && !Math.isNaN(keyCount) && keyCount > 0)
				songJson.mania = Std.int(keyCount) - 1;
			else
				songJson.mania = 3;
		}

		if (Reflect.hasField(songJson, 'keyCount'))
			Reflect.deleteField(songJson, 'keyCount');

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

	/**
	 * 当前谱面在内存里的 lane 语义：
	 *  - 'legacy'：相对 lane，note[1] 相对 mustHitSection 那一侧（0.7.x / legacy 编辑器输出）
	 *  - 'absolute'：绝对 lane，0..cols-1 玩家侧、cols.. 对手侧（psych_v1）
	 *
	 * 由 parseJSON 按文件结构（有无 {"song":...} 包裹层）判定，不看 format 字段。
	 */
	public static var chartLaneSemantics:String = 'absolute';

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

	/**
	 * 读取并解析一份谱面 JSON。
	 *
	 * `isSidecar` 用于附属文件（events.json / picospeaker.json）：
	 * 附属文件与主谱面共用 parseJSON，而 parseJSON 会写全局 chartEngineVersion；
	 * 运行期 events 的加载时机早于音符解析（PlayState.generateSong），
	 * 一旦它把版本冲掉，104 谱就会被按 073 规则解释，note 归属侧系统性反转。
	 * 所以附属文件走 writeGlobalVersion=false 的旁路，版本一律以主谱面为准。
	 */
	public static function getChart(jsonInput:String, ?folder:String, ?isSidecar:Bool = false):SwagSong
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

		return rawData != null ? parseJSON(rawData, jsonInput, 'psych_v1', !isSidecar) : null;
	}

	/**
	 * Parse a chart JSON string. Auto-detects format and converts if needed.
	 *
	 * Supports:
	 *   - psych_v1 (1.0+): { "song": {...}, "format": "psych_v1" } or top-level format
	 *   - Old format (0.7.x): { "song": {...} } without format field → auto-converted
	 *   - Already converted: format "psych_v1_convert" → skip conversion
	 */
	public static function parseJSON(rawData:String, ?nameForError:String = null, ?convertTo:String = 'psych_v1',
			?writeGlobalVersion:Bool = true):SwagSong
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
		var localVersion:String = (forceEngineVersion != null && forceEngineVersion.length > 0)
			? forceEngineVersion
			: ((detectedFormat == 'Pe-1.0.x') ? 'Pe-1.0.4' : 'Pe-0.7.3');

		// 附属文件（events / picospeaker）只贡献内容，不参与版本判定，也不覆盖主谱面的版本。
		if (writeGlobalVersion)
		{
			chartEngineVersion = localVersion;

			// lane 语义只看文件结构：带 {"song":...} 包裹层就是 legacy 输出（PE 0.7.3 /
			// legacy 编辑器），lane 是"相对 + mustHitSection"语义。
			// format 字段不可信 —— legacy 编辑器保存时会把 psych_v1 的 format 一并写进包裹层，
			// 按它判定会当成绝对 lane 解释，音符整侧反转。
			chartLaneSemantics = hasWrapper ? 'legacy' : 'absolute';
		}
		else if (chartEngineVersion != null && localVersion != chartEngineVersion)
		{
			// 开发期辅助：Release 下 trace 走隐藏 Console，看不见，仅供排查。
			// 玩家可见的告警在暂停菜单（PauseSubState 的 Event Format 行）。
			trace('NovaFlare: chart/sidecar version mismatch -> chart=$chartEngineVersion file=$localVersion');
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
