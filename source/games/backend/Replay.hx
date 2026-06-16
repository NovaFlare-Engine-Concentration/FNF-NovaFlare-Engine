package games.backend;

import flixel.input.keyboard.FlxKey;
import flixel.FlxBasic;
import general.backend.KeyBlocker;
import server.util.EncryptUtil;
import haxe.Json;
#if sys
import sys.io.File;
import sys.FileSystem;
#end

typedef NoteJudgment = {
	var strumTime:Float;
	var noteData:Int;
	var hitDiff:Float;
	var rating:String;
	var isSustain:Bool;
}

typedef FrameSave = {
	var time:Float;
	var songSpeed:Float;
	var playbackRate:Float;
	var pressKey:Array<String>;
	var releaseKey:Array<String>;
	@:optional var noteJudgments:Array<NoteJudgment>;
}

typedef StateRecord = {
	var songName:String;
	var difficulty:String;
	var playDate:String;
	var songLength:Float;

	var songSpeed:Float;
	var playbackRate:Float;
	var healthGain:Float;
	var healthLoss:Float;
	var cpuControlled:Bool;
	var practiceMode:Bool;
	var instakillOnMiss:Bool;
	var playOpponent:Bool;
	var flipChart:Bool;

	var songScore:Int;
	var ratingPercent:Float;
	var ratingFC:String;
	var songHits:Int;
	var highestCombo:Int;
	var songMisses:Int;
	var hitMapTime:Array<Float>;
	var hitMapMs:Array<Float>;
	var replayVersion:Int;
	var sickCount:Int;
	var goodCount:Int;
	var badCount:Int;
	var shitCount:Int;
	var mania:Int;
	var safeFrames:Float;
	var ratingOffset:Int;
	var noteOffset:Int;
	var botPlay:Bool;
	var gameplaySettingsJson:String;
}

class Replay extends FlxBasic
{
	private var frameData:Array<FrameSave> = [];
	private var follow:Dynamic;
	private var isRecording:Bool = true;
	public static var preparedPath:String;
	private var keysHeld:Map<FlxKey, Bool> = new Map<FlxKey, Bool>();
	private var keyToLane:Map<FlxKey, Int> = null;
	private var laneCount:Int = 0;
	private var tmpPressLanes:Array<Int> = [];
	private var tmpReleaseLanes:Array<Int> = [];
	private var tmpHeldLanes:Array<Bool> = [];
	private static var cachedKeyNames:Array<String> = null;
	public static var songSpeedResyncThreshold:Float = 0.1;
	public static var playbackRateResyncThreshold:Float = 0.1;
	public static var songSpeedResyncDelayMs:Float = 250;
	public static var playbackRateResyncDelayMs:Float = 250;
	private var lastReplayTimeForResync:Float = Math.NaN;
	private var songSpeedDesyncMs:Float = 0;
	private var playbackRateDesyncMs:Float = 0;

	// High-quality replay: pre-recorded judgments for override
	public var hasJudgments(default, null):Bool = false;
	private var judgmentMap:Map<String, NoteJudgment> = new Map<String, NoteJudgment>();
	public var recordedSongSpeed(default, null):Float = 0;
	public var recordedPlaybackRate(default, null):Float = 0;
	public var replayVersion(default, null):Int = 1;

	/////////////////////////////////////////////

	public function new(follow:Dynamic)
	{
		super();
		this.follow = follow;
	}

	public function load() {
		isRecording = false;
		frameData = ReplaySave.loadPlayRecord();
		buildJudgmentMap();

		if (ReplaySave.loadedStateRecord != null) {
			var result:String = verifyIntegrity(ReplaySave.loadedStateRecord);
			if (result != null) trace('REPLAY INTEGRITY WARNING: $result');
			// Always continue playback regardless of integrity
		}

		blockKeys();
		ensureLaneMap();
	}

	private function buildJudgmentMap():Void
	{
		judgmentMap.clear();
		hasJudgments = false;
		for (frame in frameData)
		{
			if (frame.noteJudgments != null)
			{
				for (j in frame.noteJudgments)
				{
					var key:String = '${j.strumTime}_${j.noteData}';
					if (!judgmentMap.exists(key))
						judgmentMap.set(key, j);
				}
				hasJudgments = true;
			}
		}
	}

	public function getRecordedJudgment(strumTime:Float, noteData:Int):NoteJudgment
	{
		return judgmentMap.get('${strumTime}_${noteData}');
	}

	public function verifyIntegrity(stateRecord:StateRecord):String
	{
		if (stateRecord.replayVersion < 2) return null;
		var issues:Array<String> = [];

		// Force-restore all recorded settings to prevent cheating
		Reflect.setField(follow, 'songSpeed', stateRecord.songSpeed);
		Reflect.setField(follow, 'playbackRate', stateRecord.playbackRate);
		Reflect.setField(follow, 'healthGain', stateRecord.healthGain);
		Reflect.setField(follow, 'healthLoss', stateRecord.healthLoss);
		Reflect.setField(follow, 'instakillOnMiss', stateRecord.instakillOnMiss);
		Reflect.setField(follow, 'cpuControlled', stateRecord.cpuControlled);
		Reflect.setField(follow, 'practiceMode', stateRecord.practiceMode);
		ClientPrefs.data.playOpponent = stateRecord.playOpponent;
		ClientPrefs.data.flipChart = stateRecord.flipChart;
		ClientPrefs.data.ratingOffset = stateRecord.ratingOffset;
		ClientPrefs.data.noteOffset = stateRecord.noteOffset;
		if (stateRecord.gameplaySettingsJson != null && stateRecord.gameplaySettingsJson.length > 0) { try { var gs:Dynamic = haxe.Json.parse(stateRecord.gameplaySettingsJson); for (k in Reflect.fields(gs)) ClientPrefs.data.gameplaySettings.set(k, Reflect.field(gs, k)); } catch (e:Dynamic) {} }

		this.recordedSongSpeed = stateRecord.songSpeed;
		this.recordedPlaybackRate = stateRecord.playbackRate;
		this.replayVersion = stateRecord.replayVersion;

		trace('Replay v2: restored recorded environment (speed=${stateRecord.songSpeed}, rate=${stateRecord.playbackRate})');
		return issues.length > 0 ? issues.join('; ') : null;
	}

	override function destroy() {
		if (!isRecording) unblockKeys();
		super.destroy();
	}

	private var pendingJudgments:Array<NoteJudgment> = [];
	private var lastSaveTime:Float = 0;
	override function update(elapsed:Float)
	{
		super.update(elapsed);
		if (!isRecording) return;

		if (FlxG.keys.justPressed.ANY || FlxG.keys.justReleased.ANY || pendingJudgments.length > 0 || lastSaveTime >= 0.01666) {
			lastSaveTime = 0;
			var frame:FrameSave = inputUpload();
			if (ClientPrefs.data.replayQuality && pendingJudgments.length > 0) {
				frame.noteJudgments = pendingJudgments.copy();
				pendingJudgments = [];
			}
			frameData.push(frame);
		} else {
			lastSaveTime += elapsed;
		}
	}

	public function recordJudgment(strumTime:Float, noteData:Int, hitDiff:Float, rating:String, isSustain:Bool):Void
	{
		if (!isRecording || !ClientPrefs.data.replayQuality) return;
		pendingJudgments.push({
			strumTime: strumTime,
			noteData: noteData,
			hitDiff: hitDiff,
			rating: rating,
			isSustain: isSustain
		});
	}

	private var globalTick:Int = 0; // 跨帧累加的全局tick，用于精准判断"下一回放帧"
	private var lastFrameCount:Int = 0;
	private var time:Float;
	override function handleInput(elapsed:Float) 
	{
		super.handleInput(elapsed);
		if (isRecording) return;

		var targetSongPos:Float = Conductor.songPosition;
		ensureLaneMap();

		while (lastFrameCount < frameData.length && frameData[lastFrameCount].time <= targetSongPos) {
			var frame = frameData[lastFrameCount];

			this.time = frame.time;
			var dtMs:Float = 0;
			if (!Math.isNaN(lastReplayTimeForResync)) {
				dtMs = frame.time - lastReplayTimeForResync;
				if (dtMs < 0) dtMs = 0;
			}
			lastReplayTimeForResync = frame.time;
			applyRateResync(frame, dtMs);

			tmpPressLanes.resize(0);
			tmpReleaseLanes.resize(0);

			for (keyName in frame.pressKey) {
				var flxKey = FlxKey.fromString(keyName);
				var lane = keyToLane.get(flxKey);
				if (lane != null) tmpPressLanes.push(lane);
				
				var keyObj = @:privateAccess FlxG.keys.getKey(flxKey);
				if (keyObj != null) {
					@:privateAccess keyObj.current = 2;
					@:privateAccess keyObj.reTick = globalTick;
				}
				
				keysHeld.set(flxKey, true);
			}

			for (flxKey in keysHeld.keys()) {
				var keyObj = @:privateAccess FlxG.keys.getKey(flxKey);
				if (keyObj != null) {
					if (keyObj.reTick != -9999 && globalTick - keyObj.reTick >= 1) {
						@:privateAccess keyObj.current = 1;
					}
				}
			}

			tmpHeldLanes.resize(laneCount);
			for (i in 0...laneCount) tmpHeldLanes[i] = false;
			for (flxKey in keysHeld.keys()) {
				var keyObj = @:privateAccess FlxG.keys.getKey(flxKey);
				if (keyObj != null && keyObj.reTick != -9999 && globalTick - keyObj.reTick >= 1) {
					var lane = keyToLane.get(flxKey);
					if (lane != null && lane >= 0 && lane < laneCount) tmpHeldLanes[lane] = true;
				}
			}

			for (keyName in frame.releaseKey) {
				var flxKey = FlxKey.fromString(keyName);
				var lane = keyToLane.get(flxKey);
				if (lane != null) tmpReleaseLanes.push(lane);
				
				var keyObj = @:privateAccess FlxG.keys.getKey(flxKey);
				if (keyObj != null) {
					@:privateAccess keyObj.current = -1;
					@:privateAccess keyObj.reTick = -9999;
				}
				
				keysHeld.remove(flxKey);
			}

			Reflect.callMethod(follow, Reflect.field(follow, "replayApplyInput"), [frame.time, tmpPressLanes, tmpReleaseLanes, tmpHeldLanes]);
			
			lastFrameCount++;
			globalTick++;
		}
	}

	private function ensureLaneMap():Void
	{
		if (keyToLane != null && laneCount > 0) return;
		if (keyToLane == null) keyToLane = new Map<FlxKey, Int>();
		laneCount = 0;

		var keysList:Array<String> = null;
		if (Reflect.hasField(follow, "keysArray")) keysList = Reflect.field(follow, "keysArray");
		if (keysList == null) keysList = Reflect.getProperty(follow, "keysArray");
		if (keysList == null || keysList.length <= 0) return;

		laneCount = keysList.length;
		for (lane in 0...keysList.length)
		{
			var bindName = keysList[lane];
			var keys = ClientPrefs.keyBinds.get(bindName);
			if (keys != null) {
				for (key in keys) {
					if (key != FlxKey.NONE && !keyToLane.exists(key)) keyToLane.set(key, lane);
				}
			}
		}
	}

	private function applyRateResync(frame:FrameSave, dtMs:Float):Void
	{
		if (Reflect.hasField(follow, "songSpeed")) {
			var curSongSpeed:Float = Reflect.field(follow, "songSpeed");
			if (Math.abs(curSongSpeed - frame.songSpeed) > songSpeedResyncThreshold) songSpeedDesyncMs += dtMs; else songSpeedDesyncMs = 0;
			if (songSpeedDesyncMs >= songSpeedResyncDelayMs) {
				Reflect.setProperty(follow, "songSpeed", frame.songSpeed);
				songSpeedDesyncMs = 0;
			}
		}
		if (Reflect.hasField(follow, "playbackRate")) {
			var curPlaybackRate:Float = Reflect.field(follow, "playbackRate");
			if (Math.abs(curPlaybackRate - frame.playbackRate) > playbackRateResyncThreshold) playbackRateDesyncMs += dtMs; else playbackRateDesyncMs = 0;
			if (playbackRateDesyncMs >= playbackRateResyncDelayMs) {
				Reflect.setProperty(follow, "playbackRate", frame.playbackRate);
				playbackRateDesyncMs = 0;
			}
		}
	}

	private var pressKey:Array<String> = [];
	private var releaseKey:Array<String> = [];
	private function inputUpload():FrameSave
	{
		ensureLaneMap();
		var pressKey:Array<String> = [];
		var releaseKey:Array<String> = [];
		if (cachedKeyNames == null) cachedKeyNames = [for (k in FlxKey.toStringMap.keys()) k];
		
		for (keyName in cachedKeyNames) 
		{
			var key:FlxKey = FlxKey.toStringMap.get(keyName);
			
			if (key == FlxKey.ANY || key == FlxKey.NONE || checkPauseKey(key)) continue;

			if (FlxG.keys.checkStatus(key, JUST_PRESSED)) {
				pressKey.push(keyName);
			}
			if (FlxG.keys.checkStatus(key, JUST_RELEASED)) {
				releaseKey.push(keyName);
			}
		}
		return {
			time: Conductor.songPosition,
			songSpeed: follow.songSpeed,
			playbackRate: follow.playbackRate,
			pressKey: pressKey,
			releaseKey: releaseKey
		};
	}

	private function checkPauseKey(key:FlxKey):Bool {
		for (pauseKey in ClientPrefs.keyBinds.get('pause')) {
			if (key == pauseKey) {
				return true;
			}	
		}
		return false;
	}

	public function savePlayRecord(stateRecord:StateRecord) {
		ReplaySave.savePlayRecord(frameData, stateRecord);
	}

	private function blockKeys():Void {
		var keysList:Array<String> = null;
		if (Reflect.hasField(follow, 'keysArray')) {
			keysList = Reflect.field(follow, 'keysArray');
		}

		if (keysList != null && keysList.length > 0) {
			for (keyName in keysList) {
				var keys = ClientPrefs.keyBinds.get(keyName);
				if (keys != null) {
					for (key in keys) {
						if (key != FlxKey.NONE) KeyBlocker.block(key);
					}
				}
			}
		} else {
			for (keyName => keys in ClientPrefs.keyBinds) {
				if (StringTools.startsWith(keyName, "note_") || keyName.indexOf("_key_") != -1) {
					for (key in keys) {
						if (key != FlxKey.NONE) KeyBlocker.block(key);
					}
				}
			}
		}
	}

	private function unblockKeys():Void {
		var keysList:Array<String> = null;
		if (Reflect.hasField(follow, 'keysArray')) {
			keysList = Reflect.field(follow, 'keysArray');
		}

		if (keysList != null && keysList.length > 0) {
			for (keyName in keysList) {
				var keys = ClientPrefs.keyBinds.get(keyName);
				if (keys != null) {
					for (key in keys) {
						if (key != FlxKey.NONE) KeyBlocker.unblock(key);
					}
				}
			}
		} else {
			for (keyName => keys in ClientPrefs.keyBinds) {
				if (StringTools.startsWith(keyName, "note_") || keyName.indexOf("_key_") != -1) {
					for (key in keys) {
						if (key != FlxKey.NONE) KeyBlocker.unblock(key);
					}
				}
			}
		}
	}
}

class ReplaySave {
	public static var loadedStateRecord:StateRecord = null;

	public static function loadPlayRecord():Array<FrameSave>
	{
		#if sys
		var content:String = File.getContent(Replay.preparedPath);
		content = EncryptUtil.aesDecrypt(content);
		var json:Dynamic = Json.parse(content);

		if (json.stateRecord != null)
			loadedStateRecord = json.stateRecord;
		else
			loadedStateRecord = null;

		return json.frameRecord;
		#else
		return null;
		#end
	}

	public static function savePlayRecord(frameData:Array<FrameSave>, stateRecord:StateRecord)
	{
		#if sys
		{
			var srdSave:StringBuf = new StringBuf();
			srdSave.add("{\n");
			
			// 1. stateRecord
			srdSave.add('\t"stateRecord": {\n');
			var fields = [
				"songName", "difficulty", "playDate", "songLength",
				"songSpeed", "playbackRate", "healthGain", "healthLoss",
				"cpuControlled", "practiceMode", "instakillOnMiss", "playOpponent", "flipChart",
				"songScore", "ratingPercent", "ratingFC", "songHits", "highestCombo", "songMisses",
				"hitMapTime", "hitMapMs", "replayVersion", "sickCount", "goodCount", "badCount", "shitCount",
				"mania", "safeFrames", "ratingOffset", "noteOffset", "botPlay", "gameplaySettingsJson"
			];
			for (i in 0...fields.length) {
				var key = fields[i];
				var val = Reflect.field(stateRecord, key);
				srdSave.add('\t\t"$key": ' + Json.stringify(val));
				if (i < fields.length - 1) srdSave.add(",\n");
			}
			srdSave.add("\n\t},\n");

			// 2. frameRecord
			srdSave.add('\t"frameRecord": [\n');
			for (i in 0...frameData.length) {
				var frame = frameData[i];
				srdSave.add('\t\t{\n');
				srdSave.add('\t\t\t"time": ' + frame.time + ',\n');
				srdSave.add('\t\t\t"songSpeed": ' + frame.songSpeed + ',\n');
				srdSave.add('\t\t\t"playbackRate": ' + frame.playbackRate + ',\n');
				srdSave.add('\t\t\t"pressKey": ' + Json.stringify(frame.pressKey) + ',\n');
				srdSave.add('\t\t\t"releaseKey": ' + Json.stringify(frame.releaseKey));
				if (frame.noteJudgments != null && frame.noteJudgments.length > 0) {
					srdSave.add(',\n');
					srdSave.add('\t\t\t"noteJudgments": ' + Json.stringify(frame.noteJudgments));
				}
				srdSave.add('\n\t\t}');
				if (i < frameData.length - 1) srdSave.add(",\n");
			}
			srdSave.add('\n\t]\n');
			srdSave.add("}");

			var content:String = srdSave.toString();
			content = EncryptUtil.aesEncrypt(content);

			if (!FileSystem.exists('replays/'))
				FileSystem.createDirectory('replays/');

			var folder:String = 'replays/';

			if (!FileSystem.exists(folder))
				FileSystem.createDirectory(folder);

			if (Mods.currentModDirectory == '') {
				folder = "replays/originFunkin/";
				if (!FileSystem.exists(folder))
					FileSystem.createDirectory(folder);
			} else {
				folder = "replays/" + Mods.currentModDirectory + "/";
				if (!FileSystem.exists(folder))
					FileSystem.createDirectory(folder);
			}

			folder = folder + stateRecord.songName + "/";
			if (!FileSystem.exists(folder))
				FileSystem.createDirectory(folder);

			folder = folder + Difficulty.getString().toUpperCase() + "/";
			if (!FileSystem.exists(folder))
				FileSystem.createDirectory(folder);

			var fileName:String = stateRecord.playDate + ".rsd";
			fileName = StringTools.replace(fileName, " ", "-");
			fileName = StringTools.replace(fileName, ":", ".");
			fileName = StringTools.replace(fileName, "/", "");
			fileName = StringTools.replace(fileName, "\\", "");
			
			var path:String = folder + fileName;
			Replay.preparedPath = path;
			File.saveContent(path, content);
			
			// Save as TXT
			var txtSave:StringBuf = new StringBuf();
			
			txtSave.add('Song Name: ${stateRecord.songName}\n');
			txtSave.add('Difficulty: ${stateRecord.difficulty}\n');
			txtSave.add('Song Length: ${stateRecord.songLength}\n');
			txtSave.add('Date: ${stateRecord.playDate}\n');
			txtSave.add('Song Speed: ${stateRecord.songSpeed}\n');
			txtSave.add('Playback Rate: ${stateRecord.playbackRate}\n');
			txtSave.add('Health Gain: ${stateRecord.healthGain}\n');
			txtSave.add('Health Loss: ${stateRecord.healthLoss}\n');
			txtSave.add('CPU Controlled: ${stateRecord.cpuControlled}\n');
			txtSave.add('Practice Mode: ${stateRecord.practiceMode}\n');
			txtSave.add('Instakill On Miss: ${stateRecord.instakillOnMiss}\n');
			txtSave.add('Play Opponent: ${stateRecord.playOpponent}\n');
			txtSave.add('Flip Chart: ${stateRecord.flipChart}\n');
			txtSave.add('Score: ${stateRecord.songScore}\n');
			txtSave.add('Rating: ${stateRecord.ratingPercent} (${stateRecord.ratingFC})\n');
			txtSave.add('Hits: ${stateRecord.songHits}\n');
			txtSave.add('Highest Combo: ${stateRecord.highestCombo}\n');
			txtSave.add('Misses: ${stateRecord.songMisses}\n');
			txtSave.add('Replay Version: ${stateRecord.replayVersion}\n');
			txtSave.add('Sick Count: ${stateRecord.sickCount}\n');
			txtSave.add('Good Count: ${stateRecord.goodCount}\n');
			txtSave.add('Bad Count: ${stateRecord.badCount}\n');
			txtSave.add('Shit Count: ${stateRecord.shitCount}\n');
		txtSave.add('Mania: ${stateRecord.mania}\n');
		txtSave.add('Safe Frames: ${stateRecord.safeFrames}\n');
		txtSave.add('Rating Offset: ${stateRecord.ratingOffset}\n');
		txtSave.add('Note Offset: ${stateRecord.noteOffset}\n');
		txtSave.add('Bot Play: ${stateRecord.botPlay}\n');

			var txtFileName:String = StringTools.replace(fileName, ".rsd", ".txt");
			var txtPath:String = folder + txtFileName;
			File.saveContent(txtPath, txtSave.toString());
		}
		#end
	}
}
