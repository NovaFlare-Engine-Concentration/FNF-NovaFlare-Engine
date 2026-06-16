package states.freeplayState.objects.replay;

import haxe.Json;
import haxe.ds.ArraySort;
import sys.FileSystem;
import sys.io.File;
import server.util.EncryptUtil;
import games.backend.Replay.StateRecord;

enum ReplaySortMode
{
	DATE_DESC;
	DATE_ASC;
	SCORE_DESC;
	SCORE_ASC;
	ACC_DESC;
	ACC_ASC;
	COMBO_DESC;
	COMBO_ASC;
}

typedef ReplayData = {
	var songName:String;
	var difficulty:String;
	var playDate:String;
	var songScore:Int;
	var ratingPercent:Float;
	var ratingFC:String;
	var songHits:Int;
	var highestCombo:Int;
	var songMisses:Int;
	var rsdPath:String;
	var replayVersion:Int;
	var sickCount:Int;
	var goodCount:Int;
	var badCount:Int;
	var shitCount:Int;
	var botPlay:Bool;
}

class ReplayRect extends FlxSpriteGroup
{
	static public final fixWidth:Int = 640;
	static public final fixHeight:Int = 54;

	public var data(default, null):ReplayData;
	public var onClick:Void->Void;
	public var onClickSettings:Void->Void;
	public var isHovered(default, null):Bool = false;

	var bg:FlxSprite;
    var bg2:FlxSprite;

	var settingsIcon:FlxSprite;
	var gradeText:FlxText;
	var scoreText:FlxText;
	var dateText:FlxText;
	var entryWidth:Float;
	var entryHeight:Float;

	public var realY:Float = 0;
	public var targetY:Float = 0;

	public function new(x:Float, y:Float, w:Float, h:Float, data:ReplayData)
	{
		super(x, y);
		realY = y;
		targetY = y;
		this.data = data;
		entryWidth = w;
		entryHeight = h;

        bg = new FlxSprite().loadGraphic(Paths.image(FreeplayState.filePath + "history/bg"));
		add(bg);

        bg2 = new FlxSprite().loadGraphic(Paths.image(FreeplayState.filePath + "history/light"));
		add(bg2);

        bg.scale.x = bg2.scale.x = 0.8;
        bg.scale.y = bg2.scale.y = 0.8;

		var grade:String = getGradeStr();
		var gradeColor:Int = getGradeColor(grade);

        bg2.color = gradeColor;

		// Settings icon on the far left
		settingsIcon = new FlxSprite(5, h / 2 - 12);
		settingsIcon.loadGraphic(Paths.image(FreeplayState.filePath + "function/options"));
		settingsIcon.setGraphicSize(24, 24);
		settingsIcon.updateHitbox();
		settingsIcon.antialiasing = ClientPrefs.data.antialiasing;
		add(settingsIcon);

		// Score - keep original position
		scoreText = new FlxText(340, h / 2 - 9, 105, Std.string(data.songScore), 20);
		scoreText.setFormat(Paths.font(Language.get('fontName', 'main') + '.ttf'), 20, 0xFFFFFFFF, LEFT);
		scoreText.borderStyle = NONE;
		scoreText.antialiasing = ClientPrefs.data.antialiasing;
		add(scoreText);

		// Rating grade - keep original position
		gradeText = new FlxText(430, h / 2 - 12, 42, grade, 25);
		gradeText.setFormat(Paths.font(Language.get('fontName', 'main') + '.ttf'), 25, 0xFFFFFFFF, LEFT);
		gradeText.borderStyle = NONE;
		gradeText.antialiasing = ClientPrefs.data.antialiasing;
		add(gradeText);

		// Time/Date - keep original position
		try
		{
			var date:Date = Date.fromString(data.playDate);
			var dateStr:String = DateTools.format(date, "%Y-%m-%d %H:%M");
			dateText = new FlxText(20, h / 2 - 9, w - 370, dateStr, 20);
			dateText.setFormat(Paths.font(Language.get('fontName', 'main') + '.ttf'), 20, 0x88FFFFFF, RIGHT);
			dateText.borderStyle = NONE;
			dateText.antialiasing = ClientPrefs.data.antialiasing;
			add(dateText);
		}
		catch (e:Dynamic)
		{
			dateText = new FlxText(20, h / 2 - 9, w - 370, data.playDate, 20);
			dateText.setFormat(Paths.font(Language.get('fontName', 'main') + '.ttf'), 20, 0x88FFFFFF, RIGHT);
			dateText.borderStyle = NONE;
			dateText.antialiasing = ClientPrefs.data.antialiasing;
			add(dateText);
		}
	}

	public function moveY(target:Float)
	{
		targetY = target;
		realY = targetY;
		y = realY;
	}

	public function updateHover(mouseX:Float, mouseY:Float):Bool
	{
		var hovering:Bool = (mouseX >= x && mouseX <= x + entryWidth
			&& mouseY >= y && mouseY <= y + entryHeight);

		// Left ~50px zone = settings/data view, right side = replay
		var inSettingsZone:Bool = hovering && (mouseX >= x && mouseX <= x + 50);

		if (hovering && !isHovered)
		{
			isHovered = true;
			bg.color = 0x30FFFFFF;
		}
		else if (!hovering && isHovered)
		{
			isHovered = false;
			bg.color = 0x12FFFFFF;
		}

		if (hovering && FlxG.mouse.justPressed)
		{
			if (inSettingsZone && onClickSettings != null)
			{
				onClickSettings();
				return true;
			}
			if (!inSettingsZone && onClick != null)
			{
				onClick();
				return true;
			}
		}
		return false;
	}

	function getGradeStr():String
	{
		var p:Float = data.ratingPercent * 100;
		if (p >= 100)
			return 'SS';
		if (p >= 95)
			return 'S';
		if (p >= 90)
			return 'A';
		if (p >= 80)
			return 'B';
		if (p >= 70)
			return 'C';
		return 'D';
	}

	function getGradeColor(grade:String):Int
	{
		return switch (grade)
		{
			case 'SS': 0xFFFFBB33;
			case 'S': 0xFFFFDD55;
			case 'A': 0xFF88DD44;
			case 'B': 0xFF6699FF;
			case 'C': 0xFFBB88FF;
			default: 0xFFFF6666;
		}
	}

	////////////////////////////////////////////////////////////////////////////////

	public static function loadReplayData(songName:String, difficulty:String, modFolder:String):Array<ReplayData>
	{
		var data:Array<ReplayData> = [];

		#if sys
		var songPath:String = Paths.formatToSongPath(songName);
		var diffFolder:String = difficulty.toUpperCase();
		var seen:Map<String, Bool> = new Map<String, Bool>();

		if (!FileSystem.exists('replays/') || !FileSystem.isDirectory('replays/'))
			return data;

		var modDirs:Array<String> = [];
		for (mod in FileSystem.readDirectory('replays/'))
		{
			if (FileSystem.isDirectory('replays/$mod'))
				modDirs.push(mod);
		}

		// Try the current mod first, then all others
		var currentMod:String = (modFolder == '' || modFolder == null) ? 'originFunkin' : modFolder;
		var sortedMods:Array<String> = [];
		sortedMods.push(currentMod);
		for (mod in modDirs)
		{
			if (mod != currentMod && sortedMods.indexOf(mod) < 0)
				sortedMods.push(mod);
		}

		for (modDir in sortedMods)
		{
			var searchDir:String = 'replays/$modDir/$songPath/$diffFolder/';
			if (!FileSystem.exists(searchDir) || !FileSystem.isDirectory(searchDir))
				continue;

			for (file in FileSystem.readDirectory(searchDir))
			{
				if (!StringTools.endsWith(file, '.txt'))
					continue;

				var txtPath:String = searchDir + file;
				var rsdFile:String = StringTools.replace(file, '.txt', '.rsd');
				var rsdPath:String = searchDir + rsdFile;

				if (!FileSystem.exists(rsdPath))
					continue;

				// Avoid duplicate entries (same rsd file name)
				var key:String = file;
				if (seen.exists(key))
					continue;
				seen.set(key, true);

				var parsed:ReplayData = parseReplayTxt(txtPath, rsdPath);
				if (parsed != null)
					data.push(parsed);
			}
		}
		#end

		return data;
	}

	public static function sortReplays(data:Array<ReplayData>, mode:ReplaySortMode):Array<ReplayData>
	{
		ArraySort.sort(data, function(a:ReplayData, b:ReplayData):Int
		{
			return switch (mode)
			{
				case DATE_DESC:
					try { Reflect.compare(Date.fromString(b.playDate).getTime(), Date.fromString(a.playDate).getTime()); }
					catch (e:Dynamic) { 0; }
				case DATE_ASC:
					try { Reflect.compare(Date.fromString(a.playDate).getTime(), Date.fromString(b.playDate).getTime()); }
					catch (e:Dynamic) { 0; }
				case SCORE_DESC:
					Reflect.compare(b.songScore, a.songScore);
				case SCORE_ASC:
					Reflect.compare(a.songScore, b.songScore);
				case ACC_DESC:
					Reflect.compare(b.ratingPercent, a.ratingPercent);
				case ACC_ASC:
					Reflect.compare(a.ratingPercent, b.ratingPercent);
				case COMBO_DESC:
					Reflect.compare(b.highestCombo, a.highestCombo);
				case COMBO_ASC:
					Reflect.compare(a.highestCombo, b.highestCombo);
			}
		});
		return data;
	}

	static function parseReplayTxt(txtPath:String, rsdPath:String):ReplayData
	{
		#if sys
		try
		{
			var content:String = File.getContent(txtPath);
			var lines:Array<String> = content.split('\n');
			var map:Map<String, String> = new Map<String, String>();

			for (line in lines)
			{
				var idx:Int = line.indexOf(': ');
				if (idx > 0)
				{
					map.set(line.substring(0, idx), line.substring(idx + 2));
				}
			}

			var ratingStr:String = map.get('Rating');
			var ratingPercent:Float = 0;
			var ratingFC:String = 'N/A';
			if (ratingStr != null)
			{
				var parts:Array<String> = ratingStr.split(' (');
				ratingPercent = Std.parseFloat(parts[0]);
				if (parts.length > 1)
					ratingFC = StringTools.replace(parts[1], ')', '');
			}

		var version:Int = Std.parseInt(map.get('Replay Version'));
			if (Math.isNaN(version)) version = 1; // old replays default to v1

			return {
				songName: map.get('Song Name'),
				difficulty: map.get('Difficulty'),
				playDate: map.get('Date'),
				songScore: Std.parseInt(map.get('Score')),
				ratingPercent: ratingPercent,
				ratingFC: ratingFC,
				songHits: Std.parseInt(map.get('Hits')),
				highestCombo: Std.parseInt(map.get('Highest Combo')),
				songMisses: Std.parseInt(map.get('Misses')),
				rsdPath: rsdPath,
				replayVersion: version,
				sickCount: version >= 2 ? Std.parseInt(map.get('Sick Count')) : 0,
				goodCount: version >= 2 ? Std.parseInt(map.get('Good Count')) : 0,
				badCount: version >= 2 ? Std.parseInt(map.get('Bad Count')) : 0,
				shitCount: version >= 2 ? Std.parseInt(map.get('Shit Count')) : 0,
				botPlay: version >= 2 ? (map.get('Bot Play') == 'true') : false
			};
		}
		catch (e:Dynamic) {}
		#end
		return null;
	}

	public static function loadStateRecord(rsdPath:String):StateRecord
	{
		#if sys
		try
		{
			var content:String = File.getContent(rsdPath);
			content = EncryptUtil.aesDecrypt(content);
			var json:Dynamic = Json.parse(content);
			return json.stateRecord;
		}
		catch (e:Dynamic)
		{
			trace('Failed to load StateRecord from: $rsdPath, error: $e');
		}
		#end
		return null;
	}
}
