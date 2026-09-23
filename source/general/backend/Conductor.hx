package general.backend;

import games.backend.Song;
import games.backend.Section;
import games.objects.Note;
import games.backend.Rating;

typedef BPMChangeEvent =
{
	var stepTime:Int;
	var songTime:Float;
	var bpm:Float;
	@:optional var stepCrochet:Float;
}

class Conductor
{
	public static var bpm(default, set):Float = 100;
	public static var crochet:Float = ((60 / bpm) * 1000); // beats in milliseconds
	public static var stepCrochet:Float = crochet / 4; // steps in milliseconds
	public static var songPosition(default, set):Float = 0;
	public static var offset:Float = 0;

	/**
	 * 外部（脚本 / 其它状态）把 songPosition 跳到别处时的回调，由 PlayState 在 create() 里注入。
	 *
	 * 为什么需要这个回调：本引擎的歌曲时钟是 PlayState.timing 那套独立时钟，
	 * handleInput 每帧都会执行 `Conductor.songPosition = timing.getPositionMs()`。
	 * 于是 mod 里最经典的"跳时间"写法
	 *
	 *     setPropertyFromClass('Conductor', 'songPosition', X)
	 *     setPropertyFromClass('flixel.FlxG', 'sound.music.time', X)
	 *
	 * 会在下一帧被时钟原样覆盖回去 —— 表现出来就是「过场视频播完之后谱面从 0 重新开始，
	 * 视频却不会再播一次」。有了这个回调，PlayState 就能把引擎时钟一起锚定到新位置。
	 */
	public static var onExternalSeek:Float->Void = null;

	/** 正常播放时每帧只差十几毫秒；超过这个差值才认定为"外部跳变"。 */
	public static inline var SEEK_JUMP_EPSILON:Float = 150;

	static function set_songPosition(value:Float):Float
	{
		var previous:Float = songPosition;
		songPosition = value;
		if (onExternalSeek != null && !Math.isNaN(value) && Math.abs(value - previous) > SEEK_JUMP_EPSILON)
			onExternalSeek(value);
		return value;
	}

	// public static var safeFrames:Int = 10;
	public static var safeZoneOffset:Float = 0; // is calculated in create(), is safeFrames in milliseconds

	public static var bpmChangeMap:Array<BPMChangeEvent> = [];

	public static function judgeNote(arr:Array<Rating>, diff:Float = 0):Rating // die
	{
		var data:Array<Rating> = arr;

		if (ClientPrefs.data.marvelousRating && diff <= data[4].hitWindow)
			return data[4]; // is marvelous check

		var dataFix:Int = ClientPrefs.data.marvelousRating ? 2 : 1;
		for (i in 0...data.length - dataFix) // skips last window (Shit also and marvelous)
			if (diff <= data[i].hitWindow)
				return data[i];

		return data[data.length - dataFix];
	}

	public static function getCrotchetAtTime(time:Float)
	{
		var lastChange = getBPMFromSeconds(time);
		return lastChange.stepCrochet * 4;
	}

	public static function getBPMFromSeconds(time:Float)
	{
		var lastChange:BPMChangeEvent = {
			stepTime: 0,
			songTime: 0,
			bpm: bpm,
			stepCrochet: stepCrochet
		}
		for (i in 0...Conductor.bpmChangeMap.length)
		{
			if (time >= Conductor.bpmChangeMap[i].songTime)
				lastChange = Conductor.bpmChangeMap[i];
		}

		return lastChange;
	}

	public static function getBPMFromStep(step:Float)
	{
		var lastChange:BPMChangeEvent = {
			stepTime: 0,
			songTime: 0,
			bpm: bpm,
			stepCrochet: stepCrochet
		}
		for (i in 0...Conductor.bpmChangeMap.length)
		{
			if (Conductor.bpmChangeMap[i].stepTime <= step)
				lastChange = Conductor.bpmChangeMap[i];
		}

		return lastChange;
	}

	public static function beatToSeconds(beat:Float):Float
	{
		var step = beat * 4;
		var lastChange = getBPMFromStep(step);
		return lastChange.songTime
			+ ((step - lastChange.stepTime) / (lastChange.bpm / 60) / 4) * 1000; // TODO: make less shit and take BPM into account PROPERLY
	}

	public static function getStep(time:Float)
	{
		var lastChange = getBPMFromSeconds(time);
		return lastChange.stepTime + (time - lastChange.songTime) / lastChange.stepCrochet;
	}

	public static function getStepRounded(time:Float)
	{
		var lastChange = getBPMFromSeconds(time);
		return lastChange.stepTime + Math.floor(time - lastChange.songTime) / lastChange.stepCrochet;
	}

	public static function getBeat(time:Float)
	{
		return getStep(time) / 4;
	}

	public static function getBeatRounded(time:Float):Int
	{
		return Math.floor(getStepRounded(time) / 4);
	}

	public static function mapBPMChanges(song:SwagSong)
	{
		bpmChangeMap = [];

		var curBPM:Float = song.bpm;
		var totalSteps:Int = 0;
		var totalPos:Float = 0;
		for (i in 0...song.notes.length)
		{
			if (song.notes[i].changeBPM && song.notes[i].bpm != curBPM)
			{
				curBPM = song.notes[i].bpm;
				var event:BPMChangeEvent = {
					stepTime: totalSteps,
					songTime: totalPos,
					bpm: curBPM,
					stepCrochet: calculateCrochet(curBPM) / 4
				};
				bpmChangeMap.push(event);
			}

			var deltaSteps:Int = Math.round(getSectionBeats(song, i) * 4);
			totalSteps += deltaSteps;
			totalPos += ((60 / curBPM) * 1000 / 4) * deltaSteps;
		}
	}

	static function getSectionBeats(song:SwagSong, section:Int)
	{
		var val:Null<Float> = null;
		if (song.notes[section] != null)
			val = song.notes[section].sectionBeats;
		return val != null ? val : 4;
	}

	inline public static function calculateCrochet(bpm:Float)
	{
		return (60 / bpm) * 1000;
	}

	public static function set_bpm(newBPM:Float):Float
	{
		crochet = calculateCrochet(newBPM);
		stepCrochet = crochet / 4;
		return bpm = newBPM;
	}
}

