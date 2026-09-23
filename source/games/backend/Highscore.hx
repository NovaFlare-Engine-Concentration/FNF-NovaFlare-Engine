package games.backend;

class Highscore
{
	public static var weekScores:Map<String, Int> = new Map(); //获取week的总分数

	public static var songKeyHit:Map<String, Array<Array<Array<Array<Float>>>>> = new Map<String, Array<Array<Array<Array<Float>>>>>(); 
	// 获取游玩所有轨道击打的数据 
	// 整个组>摁压类型>行数>时间
	public static var songDetails:Map<String, Array<Array<Array<Dynamic>>>> = new Map<String, Array<Array<Array<Dynamic>>>>(); 
	/**
		歌曲->整体排行（数据从高到低）->分4组->细节数据
		第1组array：songName，songLength，Date.now().toString()  用于记录歌曲基本信息
		第2组array：songSpeed, playbackRate, healthGain, healthLoss,
					cpuControlled, practiceMode, instakillOnMiss, ClientPrefs.data.playOpponent, 
					ClientPrefs.data.flipChart,
					用于记录歌曲游玩时的信息
		第3组array: songScore, ratingPercent, ratingFC, songHits，highestCombo, songMisses 用于记录游戏游玩的记录
		第4组array：NoteTime, NoteMs 用于记录击打的详尽数据
	**/
	public static var songPlayCount:Map<String, Int> = new Map();

	public static function resetSong(song:String, diff:Int = 0):Void
	{
		var daSong:String = formatSong(song, diff);
		songKeyHit.remove(daSong);
		songDetails.remove(daSong);
		FlxG.save.data.songKeyHit = songKeyHit;
		FlxG.save.data.songDetails = songDetails;
		FlxG.save.flush();
	}

	public static function resetWeek(week:String, diff:Int = 0):Void
	{
		var daWeek:String = formatSong(week, diff);
		setWeekScore(daWeek, 0);
	}

	////////////////////////////////////////////////////

	public static function saveWeekScore(week:String, score:Int = 0, ?diff:Int = 0):Void
	{
		var daWeek:String = formatSong(week, diff);

		if (weekScores.exists(daWeek))
		{
			if (weekScores.get(daWeek) < score)
				setWeekScore(daWeek, score);
		}
		else
			setWeekScore(daWeek, score);
	}

	public static function saveGameData(song:String, diff:Int = 0, details:Array<Array<Dynamic>>, keyHit:Array<Array<Array<Float>>>):Void
	{
		var daSong:String = formatSong(song, diff);

		if (songPlayCount.exists(daSong))
			songPlayCount.set(daSong, songPlayCount.get(daSong) + 1);
		else
			songPlayCount.set(daSong, 1);

		if (songDetails.exists(daSong))
		{
			var input:Float = 0;
			var output:Int = 0;
			var checkFlip:Bool = false; //是否要比小
			switch(ClientPrefs.data.saveScoreBase) {
				case 'Accuracy':
					input = details[2][1];
					output = 1;
				case 'Misses':
					input = details[2][5];
					output = 5;
					checkFlip = true;
				case 'highestCombo':
					input = details[2][4];
					output = 4;
					checkFlip = true;
				default: //score以及神人瞎去设置的情况
					input = details[2][0];
					output = 0;
			}

			if (checkFlip) {
				for (i in 0...songDetails.get(daSong).length) {
					if (songDetails.get(daSong)[i][2][output] > input) {
						setDetails(daSong, i, details);
						setKeyHit(daSong, i, keyHit);
						return;
						break;
					}
				}
			} else {
				for (i in 0...songDetails.get(daSong).length) {
					if (songDetails.get(daSong)[i][2][output] < input) {
						setDetails(daSong, i, details);
						setKeyHit(daSong, i, keyHit);
						return;
						break;
					}
				}
			}
			setDetails(daSong, songDetails.get(daSong).length - 1, details);
			setKeyHit(daSong, songDetails.get(daSong).length - 1, keyHit);
		}
		else
		{
			setDetails(daSong, 0, details);
			setKeyHit(daSong, 0, keyHit);
		}
	}

	public static function savePlayCount(song:String, diff:Int = 0):Void
	{
		var daSong:String = formatSong(song, diff);

		if (songPlayCount.exists(daSong))
			songPlayCount.set(daSong, songPlayCount.get(daSong) + 1);
		else
			songPlayCount.set(daSong, 1);
	}

	////////////////////////////////////////////////////////////////////////

	static function setWeekScore(week:String, score:Int):Void
	{
		weekScores.set(week, score);
		FlxG.save.data.weekScores = weekScores;
		FlxG.save.flush();
	}

	static function setDetails(song:String, sort:Int, input:Array<Array<Dynamic>>):Void
	{
		var mainGroup:Array<Array<Array<Dynamic>>> = [];
		if (songDetails.exists(song)) mainGroup = songDetails.get(song);
		mainGroup.insert(sort, input);
		songDetails.set(song, mainGroup);
		FlxG.save.data.songDetails = songDetails;
		FlxG.save.flush();
	}

	static function setKeyHit(song:String, sort:Int, input:Array<Array<Array<Float>>>):Void
	{
		var mainGroup: Array<Array<Array<Array<Float>>>> = [];
		if (songKeyHit.exists(song)) mainGroup = songKeyHit.get(song);
		mainGroup.insert(sort, input);
		songKeyHit.set(song, mainGroup);
		FlxG.save.data.songKeyHit = songKeyHit;
		FlxG.save.flush();
	}

	/////////////////////////////////////////////////////////////////////////

	public static function getWeekScore(week:String, diff:Int):Int
	{
		var daWeek:String = formatSong(week, diff);
		if (!weekScores.exists(daWeek))
			return 0;
		return weekScores.get(daWeek);
	}

	public static function getScore(song:String, diff:Int, sort:Int = 0):Int
	{
		var daSong:String = formatSong(song, diff);
		if (!songDetails.exists(daSong))
			return 0;

		return songDetails.get(daSong)[sort][2][0];
	}

	public static function getPlayCount(song:String, diff:Int):Int
	{
		var daSong:String = formatSong(song, diff);
		if (!songPlayCount.exists(daSong))
			return 0;
		return songPlayCount.get(daSong);
	}

	public static function getDetails(song:String, diff:Int, sort:Int = 0):Dynamic
	{
		var daSong:String = formatSong(song, diff);
		if (!songDetails.exists(daSong))
			return [];
		return songDetails.get(daSong)[sort];
	}

	public static function getKeyHit(song:String, diff:Int, sort:Int = 0):Dynamic
	{
		var daSong:String = formatSong(song, diff);
		if (!songKeyHit.exists(daSong))
			return [[[], [], [], []], [[], [], [], []]];
		return songKeyHit.get(daSong)[sort];
	}

	////////////////////////////////////////////////////////////////////////

	public static function load():Void
	{
		if (FlxG.save.data.weekScores != null)
		{
			weekScores = FlxG.save.data.weekScores;
		}

		if (FlxG.save.data.songDetails != null)
		{
			songDetails = FlxG.save.data.songDetails;
		}
		

		if (FlxG.save.data.songKeyHit != null)
		{
			songKeyHit = FlxG.save.data.songKeyHit;
		}
	}
	
	public static function formatSong(song:String, diff:Int):String
	{
		return Paths.formatToSongPath(song) + Difficulty.getFilePath(diff);
	}
}
