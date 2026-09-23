package developer.editors;

import haxe.Json;

import openfl.events.KeyboardEvent;
import openfl.utils.Assets as OpenFlAssets;

import flixel.util.FlxSort;
import flixel.util.FlxStringUtil;
import flixel.animation.FlxAnimationController;
import flixel.input.keyboard.FlxKey;

import games.objects.Character;
import games.backend.Song;
import games.backend.Section;
import games.backend.Rating;
import games.backend.KeyChange;
import games.backend.KeyChangePoint;
import games.objects.Note;
import games.objects.NoteSplash;
import games.objects.StrumNote;
import games.backend.TimingSystem;

class EditorPlayState extends MusicBeatSubstate
{

	public static var instance:EditorPlayState;

    var timing:TimingSystem;
	// Borrowed from original PlayState
	var finishTimer:FlxTimer = null;
	var noteKillOffset:Float = 350;
	var spawnTime:Float = 2000;
	var startingSong:Bool = true;

	var playbackRate:Float = 1;
	var vocals:FlxSound;
	var opponentVocals:FlxSound;
	var inst:FlxSound;

	var notes:FlxTypedGroup<Note>;
	var unspawnNotes:Array<Note> = [];
	var killNotes:Array<Note> = [];
	var killNotesBudget:Int = 20;
	var ratingsData:Array<Rating> = Rating.loadDefault();

	var strumLineNotes:FlxTypedGroup<StrumNote>;
	var opponentStrums:FlxTypedGroup<StrumNote>;
	var playerStrums:FlxTypedGroup<StrumNote>;
	var grpNoteSplashes:FlxTypedGroup<NoteSplash>;

	var combo:Int = 0;
	var lastRating:FlxSprite;
	var lastCombo:FlxSprite;
	var lastScore:Array<FlxSprite> = [];
	var keysArray:Array<String> = ['note_left', 'note_down', 'note_up', 'note_right'];

	var songHits:Int = 0;
	var songMisses:Int = 0;
	var songLength:Float = 0;

	public var songSpeed:Float = 1;

	var totalPlayed:Int = 0;
	var totalNotesHit:Float = 0.0;
	var ratingPercent:Float;
	var ratingFC:String;

	var showCombo:Bool = false;
	var showComboNum:Bool = true;
	var showRating:Bool = true;

	// Originals
	var startOffset:Float = 0;
	var startPos:Float = 0;
	var timerToStart:Float = 0;

	var scoreTxt:FlxText;
	var dataTxt:FlxText;
	var guitarHeroSustains:Bool = false;
	// ★ 3,2,1,GO 倒计时文字
	var countdownText:FlxText;

	var _hold:Array<Bool> = [];
	var _press:Array<Bool> = [];
	var _release:Array<Bool> = [];
	var strumsBlocked:Array<Bool> = [];
	var keysPressed:Array<Int> = [];

	// ★ KeyChange(MoreKey) 段支持：试玩跟随谱面事件切换键数（与正式玩法一致）
	var keyChangePoints:Array<KeyChangePoint> = [];
	var keyChangeIdx:Int = 0;
	var currentMania:Int = 3;

	public function new(playbackRate:Float)
	{
		instance = this;
		super();

		Note.init(instance);

		/* setting up some important data */
		this.playbackRate = playbackRate;
		this.startPos = Conductor.songPosition;

		Conductor.safeZoneOffset = (ClientPrefs.data.safeFrames / 60) * 1000 * playbackRate;
		Conductor.songPosition -= startOffset;
		startOffset = Conductor.crochet;
		// ★ 试玩从歌曲开头开始并先走 3,2,1,GO 倒计时（共 4 拍）
		timerToStart = startOffset * 4;

		// ★ KeyChange(MoreKey) 段支持：构建事件时间线，试玩从 startPos 所在段开始；
		//   keyChangeIdx 指向倒计时起点之后的下一个事件（倒计时窗口内的事件播放到才切）
		keyChangePoints = KeyChange.scanEvents(PlayState.SONG != null ? PlayState.SONG.events : null, ClientPrefs.data.noteOffset);
		KeyChange.sortPoints(keyChangePoints);
		currentMania = KeyChange.maniaAt(startPos + ClientPrefs.data.noteOffset, keyChangePoints, PlayState.SONG != null ? PlayState.SONG.mania : 3);
		setupKeysForMania(currentMania);
		var countdownStart:Float = startPos - startOffset * 4;
		keyChangeIdx = 0;
		while (keyChangeIdx < keyChangePoints.length && keyChangePoints[keyChangeIdx].time <= countdownStart)
			keyChangeIdx++;

		/* borrowed from PlayState */
		if (FlxG.sound.music != null)
			FlxG.sound.music.stop();

		cachePopUpScore();
		guitarHeroSustains = ClientPrefs.data.guitarHeroSustains;
		if (ClientPrefs.data.hitsoundVolume > 0)
			Paths.sound('hitsound');

		/* setting up Editor PlayState stuff */
		var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.antialiasing = ClientPrefs.data.antialiasing;
		bg.scrollFactor.set();
		bg.color = 0xFF101010;
		bg.alpha = 0.9;
		add(bg);

		/**** NOTES ****/
		strumLineNotes = new FlxTypedGroup<StrumNote>();
		add(strumLineNotes);
		grpNoteSplashes = new FlxTypedGroup<NoteSplash>();
		add(grpNoteSplashes);

		var splash:NoteSplash = new NoteSplash(100, 100);
		grpNoteSplashes.add(splash);
		splash.alpha = 0.000001; // cant make it invisible or it won't allow precaching

		opponentStrums = new FlxTypedGroup<StrumNote>();
		playerStrums = new FlxTypedGroup<StrumNote>();

		generateStaticArrows(0);
		generateStaticArrows(1);
		/***************/

		scoreTxt = new FlxText(10, FlxG.height - 50, FlxG.width - 20, "", 20);
		scoreTxt.setFormat(Paths.font(Language.get('fontName', 'main') + '.ttf'), 20, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		scoreTxt.scrollFactor.set();
		scoreTxt.borderSize = 1.25;
		scoreTxt.visible = !ClientPrefs.data.hideHud;
		add(scoreTxt);

		dataTxt = new FlxText(10, 580, FlxG.width - 20, "Section: 0", 20);
		dataTxt.setFormat(Paths.font(Language.get('fontName', 'main') + '.ttf'), 20, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		dataTxt.scrollFactor.set();
		dataTxt.borderSize = 1.25;
		add(dataTxt);

		var daButton:String;
		#if android
		daButton = "BACK";
		#else
		if (controls.mobileC)
			daButton = "X";
		else
			daButton = "ESC";
		#end

		var tipText:FlxText = new FlxText(10, FlxG.height - 24, 0, 'Press ' + daButton + ' to Go Back to Chart Editor', 16);
		tipText.setFormat(Paths.font(Language.get('fontName', 'main') + '.ttf'), 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		tipText.borderSize = 2;
		tipText.scrollFactor.set();
		add(tipText);
		FlxG.mouse.visible = false;

		// ★ 3,2,1,GO 倒计时文字（居中大字，开始时显示）
		countdownText = new FlxText(0, 0, FlxG.width, '', 96);
		countdownText.setFormat(Paths.font(Language.get('fontName', 'main') + '.ttf'), 96, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		countdownText.borderSize = 5;
		countdownText.scrollFactor.set();
		countdownText.y = FlxG.height / 2 - 110;
		add(countdownText);

		generateSong(PlayState.SONG.song);

		#if DISCORD_ALLOWED
		// Updating Discord Rich Presence (with Time Left)
		DiscordClient.changePresence('Playtesting on Chart Editor', PlayState.SONG.song, null, true, songLength);
		#end

		#if !android
		addVirtualPad(NONE, P);
		addVirtualPadCamera(false);
		#end

		addMobileControls(false);
		mobileControls.visible = true;

		RecalculateRating();
	}

	/** 按 mania 重建键位输入上下文（读取 ClientPrefs.keyBinds，4K 特例 note_left 等） */
	function setupKeysForMania(mania:Int):Void
	{
		keysArray = [];
		if (mania != 3)
		{
			for (i in 0...mania + 1)
			{
				keysArray.push(mania + '_key_$i');
			}
		}
		else keysArray = ['note_left', 'note_down', 'note_up', 'note_right'];

		_hold = [];
		_press = [];
		_release = [];
		strumsBlocked = [];
		keysPressed = [];
		for (i in 0...keysArray.length)
		{
			_hold.push(false);
			_press.push(false);
			_release.push(false);
			strumsBlocked.push(false);
		}
	}

	/** 断开 note 的 prev/next/parent-tail 引用，避免销毁后悬空指针 */
	function detachNoteRefs(note:Note):Void
	{
		if (note.prevNote != null && note.prevNote.nextNote == note)
			note.prevNote.nextNote = null;
		if (note.nextNote != null && note.nextNote.prevNote == note)
			note.nextNote.prevNote = null;
		if (note.parent != null)
			note.parent.tail.remove(note);
	}

	/** ★ KeyChange(MoreKey)：播放跨过事件点时切换试玩键数（键位/strum/音符清理，与正式一致） */
	function applyEditorKeyChange(displayKeys:Int):Void
	{
		displayKeys = KeyChange.clampKeys(displayKeys);
		var newMania:Int = KeyChange.maniaFromKeys(displayKeys);
		if (newMania == currentMania)
			return;
		trace('EditorPlayState KeyChange(MoreKey): ${currentMania + 1}K -> ${displayKeys}K');
		currentMania = newMania;
		setupKeysForMania(currentMania);

		// ★ 清理规则与正式 PlayState.removeOutdatedNotes 一致：
		//   场上只清「轨号超当前键数且判定时间已过」的旧段残留；轨号超当前键数但还没到时间
		//   （未来段提前 spawn / 与事件同刻）必须保留，等后续事件触发重建 strum 后正常渲染；
		//   unspawn 队列绝不用当前键数判断（会误杀后续事件的新段音符），只清超出自身段的损坏数据
		var perKeys:Int = currentMania + 1;
		var i:Int = notes.length - 1;
		while (i >= 0)
		{
			var note:Note = notes.members[i];
			if (note != null && note.noteData >= perKeys && note.strumTime < Conductor.songPosition - 40)
			{
				detachNoteRefs(note);
				note.kill();
				notes.remove(note, true);
				note = FlxDestroyUtil.destroy(note);
			}
			i--;
		}
		var j:Int = unspawnNotes.length - 1;
		while (j >= 0)
		{
			var n:Note = unspawnNotes[j];
			var nKeys:Int = (n != null && n.generatedMania >= 0 ? n.generatedMania : currentMania) + 1;
			if (n != null && n.noteData >= nKeys)
			{
				detachNoteRefs(n);
				unspawnNotes.remove(n);
				n.destroy();
			}
			j--;
		}

		// 重建 strum（当前段键数）
		while (strumLineNotes.members.length > 0)
		{
			var spr:StrumNote = strumLineNotes.members[0];
			strumLineNotes.remove(spr, true);
		}
		for (grp in [opponentStrums, playerStrums])
		{
			while (grp.members.length > 0)
			{
				var spr:StrumNote = grp.members[0];
				grp.remove(spr, true);
				spr.destroy();
			}
		}
		generateStaticArrows(0);
		generateStaticArrows(1);
	}

    override function update(elapsed:Float)
    {
		if (#if !android virtualPad.buttonP.justPressed
			|| #end FlxG.keys.justPressed.ESCAPE #if android || FlxG.android.justPressed.BACK #end)
		{
			mobileControls.visible = false;
			endSong();
			super.update(elapsed);
			return;
		}

        if (startingSong)
        {
            timerToStart -= elapsed * 1000;
            Conductor.songPosition = startPos - timerToStart;
            if (timing == null) {
                timing = new TimingSystem();
                timing.setRate(playbackRate);
            }
            timing.setPosition(Conductor.songPosition);
            timing.enableTick();

			// ★ 3,2,1,GO 倒计时显示（4 拍：3 / 2 / 1 / GO，各 1 拍；结束即从 startPos 开播）
			if (countdownText != null)
			{
				var beatsLeft:Float = timerToStart / startOffset; // 4 → 0
				var lbl:String = '';
				var col:Int = 0xFFFFFFFF;
				if (beatsLeft > 3) { lbl = '3'; col = 0xFFFF6B6B; }
				else if (beatsLeft > 2) { lbl = '2'; col = 0xFFFFD166; }
				else if (beatsLeft > 1) { lbl = '1'; col = 0xFF4EC9F0; }
				else if (beatsLeft > 0) { lbl = 'GO'; col = 0xFF7CFC8E; }
				// ★ 只在真实倒计时文字切换时播放音效；lbl==''（归零收尾帧）不触发，
				//   否则 'GO'→'' 会把 switch('') 落到 default 再播一次 introGo
				if (lbl != '' && countdownText.text != lbl)
				{
					countdownText.text = lbl;
					countdownText.color = col;
					// ★ 3/2/1/GO 倒计时音效（Paths.sound 自动优先 mod 目录，
					//   mod 放 mods/<mod>/sounds/intro3.ogg 等即可覆盖默认音效）
					var sndName:String = switch (lbl)
					{
						case '3': 'intro3';
						case '2': 'intro2';
						case '1': 'intro1';
						default: 'introGo';
					};
					try { FlxG.sound.play(Paths.sound(sndName), 0.6); } catch (e:Dynamic) {}
				}
			}
            if (timerToStart <= 0)
			{
				if (countdownText != null) countdownText.text = '';
                startSong();
			}
        }
        else
            Conductor.songPosition = timing != null ? timing.getPositionMs() : Conductor.songPosition;

		// ★ KeyChange(MoreKey)：播放跨过事件点 → 切换键数（与正式玩法一致）
		while (keyChangeIdx < keyChangePoints.length && Conductor.songPosition >= keyChangePoints[keyChangeIdx].time)
		{
			var point:KeyChangePoint = keyChangePoints[keyChangeIdx];
			keyChangeIdx++;
			applyEditorKeyChange(point.keys);
		}

		if (unspawnNotes[0] != null)
		{
			var time:Float = spawnTime * playbackRate;
			if (songSpeed < 1)
				time /= songSpeed;
			if (unspawnNotes[0].multSpeed < 1)
				time /= unspawnNotes[0].multSpeed;

			while (unspawnNotes.length > 0 && unspawnNotes[0].strumTime - Conductor.songPosition < time)
			{
				var dunceNote:Note = unspawnNotes[0];
				// ★ KeyChange(MoreKey)：越界判定按音符「自身所属段」的键数——
				//   事件后的未来段音符（如 4K→6K 新增轨）提前进入 spawn 窗口时不能被当前旧键数误杀
				var noteKeys:Int = (dunceNote.generatedMania >= 0 ? dunceNote.generatedMania : currentMania) + 1;
				if (dunceNote.noteData >= noteKeys)
				{
					unspawnNotes.shift();
					dunceNote.destroy();
					continue;
				}
				notes.insert(0, dunceNote);
				dunceNote.spawned = true;

				var index:Int = unspawnNotes.indexOf(dunceNote);
				unspawnNotes.splice(index, 1);
			}
		}

		keysCheck();
		if (notes.length > 0)
		{
			var fakeCrochet:Float = (60 / PlayState.SONG.bpm) * 1000;
			notes.forEachAlive(function(daNote:Note)
			{
				var strumGroup:FlxTypedGroup<StrumNote> = playerStrums;
				if (!daNote.mustPress)
					strumGroup = opponentStrums;

				// ★ KeyChange(MoreKey)：事件前的未来段音符提前 spawn 时 strum 还是旧键数，
				//   轨号可能超界。不销毁（保留判定），strum 就绪后自动恢复显示
				var strum:StrumNote = (daNote.noteData >= 0 && daNote.noteData < strumGroup.members.length) ? strumGroup.members[daNote.noteData] : null;
				if (strum != null)
					daNote.followStrumNote(strum, fakeCrochet, songSpeed / playbackRate);

				if (!daNote.mustPress && daNote.wasGoodHit && !daNote.hitByOpponent && !daNote.ignoreNote)
					opponentNoteHit(daNote);

				if (strum != null && daNote.isSustainNote && strum.sustainReduce)
					daNote.clipToStrumNote(strum);

				// Kill extremely late notes and cause misses
				if (Conductor.songPosition - daNote.strumTime > noteKillOffset)
				{
					if (daNote.mustPress && !daNote.ignoreNote && (daNote.tooLate || !daNote.wasGoodHit))
						noteMiss(daNote);

					daNote.active = daNote.visible = false;
					invalidateNote(daNote);
				}
			});
		}
		destroyNotes();

		var time:Float = CoolUtil.floorDecimal((Conductor.songPosition - ClientPrefs.data.noteOffset) / 1000, 1);
		dataTxt.text = 'Time: $time / ${songLength / 1000}
						\nSection: $curSection
						\nBeat: $curBeat
						\nStep: $curStep';
		super.update(elapsed);
	}

	var lastStepHit:Int = -1;

	override function stepHit()
	{
		if (PlayState.SONG.needsVoices && FlxG.sound.music.time >= -ClientPrefs.data.noteOffset)
		{
			var timeSub:Float = Conductor.songPosition - Conductor.offset;
			var syncTime:Float = 20 * playbackRate;
			if (Math.abs(FlxG.sound.music.time - timeSub) > syncTime
				|| (vocals.length > 0 && Math.abs(vocals.time - timeSub) > syncTime)
				|| (opponentVocals.length > 0 && Math.abs(opponentVocals.time - timeSub) > syncTime))
			{
				resyncVocals();
			}
		}
		super.stepHit();

		if (curStep == lastStepHit)
		{
			return;
		}
		lastStepHit = curStep;
	}

	var lastBeatHit:Int = -1;

	override function beatHit()
	{
		if (lastBeatHit >= curBeat)
		{
			// trace('BEAT HIT: ' + curBeat + ', LAST HIT: ' + lastBeatHit);
			return;
		}
		notes.sort(FlxSort.byY, ClientPrefs.data.downScroll ? FlxSort.ASCENDING : FlxSort.DESCENDING);

		super.beatHit();
		lastBeatHit = curBeat;
	}

	override function sectionHit()
	{
		if (PlayState.SONG.notes[curSection] != null)
		{
			if (PlayState.SONG.notes[curSection].changeBPM)
				Conductor.bpm = PlayState.SONG.notes[curSection].bpm;
		}
		super.sectionHit();
	}

	override function destroy()
	{
		FlxG.mouse.visible = true;
		super.destroy();
	}

    function startSong():Void
    {
        startingSong = false;
        @:privateAccess
        FlxG.sound.playMusic(inst._sound, 1, false);
        FlxG.sound.music.time = startPos;
        #if FLX_PITCH FlxG.sound.music.pitch = playbackRate; #end
        FlxG.sound.music.onComplete = finishSong;
        vocals.volume = 1;
        vocals.time = startPos;
        vocals.play();
        opponentVocals.volume = 1;
        opponentVocals.time = startPos;
        opponentVocals.play();

		// Song duration in a float, useful for the time left feature
        songLength = FlxG.sound.music.length;
        if (timing == null) {
            timing = new TimingSystem();
            timing.setRate(playbackRate);
        }
        timing.setPosition(startPos);
        timing.play();
    }

	// Borrowed from PlayState
	function generateSong(dataPath:String)
	{
		// FlxG.log.add(ChartParser.parse());
		songSpeed = PlayState.SONG.speed;
		var songSpeedType:String = ClientPrefs.getGameplaySetting('scrolltype');
		switch (songSpeedType)
		{
			case "multiplicative":
				songSpeed = PlayState.SONG.speed * ClientPrefs.getGameplaySetting('scrollspeed');
			case "constant":
				songSpeed = ClientPrefs.getGameplaySetting('scrollspeed');
		}
		noteKillOffset = Math.max(Conductor.stepCrochet, 350 / songSpeed * playbackRate);

		var songData = PlayState.SONG;
		Conductor.bpm = songData.bpm;

		var boyfriendVocals:String = loadCharacterFile(PlayState.SONG.player1).vocals_file;
		var dadVocals:String = loadCharacterFile(PlayState.SONG.player2).vocals_file;

		vocals = new FlxSound();
		opponentVocals = new FlxSound();
		try
		{
			if (songData.needsVoices)
			{
				var playerVocals = Paths.voices(songData.song, (boyfriendVocals == null || boyfriendVocals.length < 1) ? 'Player' : boyfriendVocals);
				vocals.loadEmbedded(playerVocals != null ? playerVocals : Paths.voices(songData.song));

				var oppVocals = Paths.voices(songData.song, (dadVocals == null || dadVocals.length < 1) ? 'Opponent' : dadVocals);
				if (oppVocals != null)
					opponentVocals.loadEmbedded(oppVocals);
			}
		}
		catch (e:Dynamic)
		{
		}

		vocals.volume = 0;
		opponentVocals.volume = 0;

		#if FLX_PITCH
		vocals.pitch = playbackRate;
		opponentVocals.pitch = playbackRate;
		#end
		FlxG.sound.list.add(vocals);
		FlxG.sound.list.add(opponentVocals);

		inst = new FlxSound().loadEmbedded(Paths.inst(songData.song));
		FlxG.sound.list.add(inst);
		FlxG.sound.music.volume = 0;

		notes = new FlxTypedGroup<Note>();
		add(notes);

		var noteData:Array<SwagSection>;

		// NEW SHIT
		noteData = songData.notes;
		for (section in noteData)
		{
			for (songNotes in section.sectionNotes)
			{
				var daStrumTime:Float = songNotes[0];
				if (daStrumTime < startPos)
					continue;

				// ★ KeyChange(MoreKey) 段支持：按该音符自身时间所属段解析（与正式 PlayState 一致）
				var noteMania:Int = KeyChange.maniaAt(daStrumTime + ClientPrefs.data.noteOffset, keyChangePoints, currentMania);
				var perSideKeys:Int = noteMania + 1;

				var daNoteData:Int = Std.int(songNotes[1] % perSideKeys);
				// ★ 与正式 PlayState 解析保持一致：Pe-1.0.4 谱面 lane 0..mania 恒为玩家、
				//   mania+1.. 恒为对手（不随 mustHitSection 翻转）；Pe-0.7.3 谱面才翻转。
				//   原来这里永远按 0.7.3 语义 → 非 4K 的 1.0.4 谱 ESC 试玩时 BF/Opp 归属错乱
				var gottaHitNote:Bool;
				var isPe104:Bool = (Song.chartEngineVersion == 'Pe-1.0.4');
				if (isPe104)
					gottaHitNote = (songNotes[1] < perSideKeys);
				else
				{
					gottaHitNote = section.mustHitSection;
					if (songNotes[1] > noteMania)
						gottaHitNote = !section.mustHitSection;
				}

				var oldNote:Note;
				if (unspawnNotes.length > 0)
					oldNote = unspawnNotes[Std.int(unspawnNotes.length - 1)];
				else
					oldNote = null;

				var swagNote:Note = new Note(daStrumTime, daNoteData, oldNote, false, false, instance, noteMania);
				swagNote.mustPress = gottaHitNote;
				swagNote.sustainLength = songNotes[2];
				// gfNote 语义也跟随引擎版本（与 PlayState 一致）
				if (isPe104)
					swagNote.gfNote = (section.gfSection && gottaHitNote == section.mustHitSection);
				else
					swagNote.gfNote = (section.gfSection && (songNotes[1] < perSideKeys));
				swagNote.noteType = songNotes[3];
				if (!Std.isOfType(songNotes[3], String))
					swagNote.noteType = ChartingState.noteTypeList[songNotes[3]]; // Backward compatibility + compatibility with Week 7 charts

				swagNote.scrollFactor.set();

				unspawnNotes.push(swagNote);

				final susLength:Float = swagNote.sustainLength / Conductor.stepCrochet;
				final floorSus:Int = Math.floor(susLength);

				if (floorSus > 0)
				{
					for (susNote in 0...floorSus + 1)
					{
						oldNote = unspawnNotes[Std.int(unspawnNotes.length - 1)];

						var sustainNote:Note = new Note(daStrumTime + (Conductor.stepCrochet * susNote), daNoteData, oldNote, true, false, instance, noteMania);
						sustainNote.hitMultUpdate(susNote, floorSus);
						sustainNote.mustPress = gottaHitNote;
						if (isPe104)
							sustainNote.gfNote = (section.gfSection && gottaHitNote == section.mustHitSection);
						else
							sustainNote.gfNote = (section.gfSection && (songNotes[1] < perSideKeys));
						sustainNote.noteType = swagNote.noteType;
						sustainNote.scrollFactor.set();
						sustainNote.parent = swagNote;
						unspawnNotes.push(sustainNote);
						swagNote.tail.push(sustainNote);

						sustainNote.correctionOffset = swagNote.height / 2;
						if (!PlayState.isPixelStage)
						{
							if (oldNote.isSustainNote)
							{
								oldNote.scale.y *= Note.SUSTAIN_SIZE / oldNote.frameHeight;
								oldNote.scale.y /= playbackRate;
								oldNote.updateHitbox();
							}

							if (ClientPrefs.data.downScroll)
								sustainNote.correctionOffset = 0;
						}
						else if (oldNote.isSustainNote)
						{
							oldNote.scale.y /= playbackRate;
							oldNote.updateHitbox();
						}

						if (sustainNote.mustPress)
							sustainNote.x += FlxG.width / 2; // general offset
						else if (ClientPrefs.data.middleScroll)
						{
							sustainNote.x += 310;
							if (daNoteData > 1) // Up and Right
								sustainNote.x += FlxG.width / 2 + 25;
						}
					}
				}

				if (swagNote.mustPress)
				{
					swagNote.x += FlxG.width / 2; // general offset
				}
				else if (ClientPrefs.data.middleScroll)
				{
					swagNote.x += 310;
					if (daNoteData > 1) // Up and Right
					{
						swagNote.x += FlxG.width / 2 + 25;
					}
				}
			}
		}

		unspawnNotes.sort(PlayState.sortByTime);
	}

	private function generateStaticArrows(player:Int):Void
	{
		var strumLineX:Float = ClientPrefs.data.middleScroll ? PlayState.STRUM_X_MIDDLESCROLL : PlayState.STRUM_X;
		var strumLineY:Float = ClientPrefs.data.downScroll ? (FlxG.height - 150) : 50;
		for (i in 0...currentMania + 1)
		{
			// FlxG.log.add(i);
			var targetAlpha:Float = 1;
			if (player < 1)
			{
				if (!ClientPrefs.data.opponentStrums)
					targetAlpha = 0;
				else if (ClientPrefs.data.middleScroll)
					targetAlpha = 0.35;
			}

			// ★ KeyChange 段支持：strum 按试玩当前段键数渲染（方向/颜色/缩放/排布正确）
			var babyArrow:StrumNote = new StrumNote(strumLineX, strumLineY, i, player, currentMania);
			babyArrow.downScroll = ClientPrefs.data.downScroll;
			babyArrow.alpha = targetAlpha;

			if (player == 1)
				playerStrums.add(babyArrow);
			else
			{
				if (ClientPrefs.data.middleScroll)
				{
					babyArrow.x += 310;
					if (i > 1)
					{ // Up and Right
						babyArrow.x += FlxG.width / 2 + 25;
					}
				}
				opponentStrums.add(babyArrow);
			}

			strumLineNotes.add(babyArrow);
			babyArrow.postAddedToGroup();
		}
		// Non-pixel ExtraKeys scales are shared by receptors and falling notes.
		// Resizing only the receptors from atlas frame bounds desynchronizes custom skins.
		if (PlayState.isPixelStage)
		{
			adaptStrumline(opponentStrums);
			adaptStrumline(playerStrums);
		}

		if (ClientPrefs.data.showKeybinds)
		{
			for (i in 0...playerStrums.members.length)
			{
				var keyShowcase = new KeybindShowcase(playerStrums.members[i].x - 280,
					ClientPrefs.data.downScroll ? playerStrums.members[i].y - 390 : playerStrums.members[i].y + playerStrums.members[i].height - 350,
					ClientPrefs.keyBinds.get(keysArray[i]), FlxG.camera, playerStrums.members[i].width / 2, currentMania);
				keyShowcase.onComplete = function()
				{
					remove(keyShowcase);
				}
				add(keyShowcase);
			}
		}
	}

	public function adaptStrumline(strumline:FlxTypedGroup<StrumNote>)
	{
		var strumLineWidth:Float = 0;
		var strumLineIsBig:Bool = false;

		for (note in strumline.members)
			strumLineWidth += note.width;
		strumLineIsBig = strumLineWidth > StrumBoundaries.getBoundaryWidth().x;

		while (strumLineIsBig)
		{
			strumLineWidth = 0;
			for (note in strumline.members)
			{
				note.retryBound();
				strumLineWidth += note.width;
			}
			trace('Strumline is too big! Shrinking and retrying.');
			strumLineIsBig = strumLineWidth > StrumBoundaries.getBoundaryWidth().x;
		}
	}

	public function finishSong():Void
	{
		if (ClientPrefs.data.noteOffset <= 0)
		{
			endSong();
		}
		else
		{
			finishTimer = new FlxTimer().start(ClientPrefs.data.noteOffset / 1000, function(tmr:FlxTimer)
			{
				endSong();
			});
		}
	}

	public function endSong()
	{
		vocals.pause();
		vocals.destroy();
		opponentVocals.pause();
		opponentVocals.destroy();
		if (finishTimer != null)
		{
			finishTimer.cancel();
			finishTimer.destroy();
		}
		close();
	}

	private function cachePopUpScore()
	{
		for (rating in ratingsData)
			Paths.image(rating.image);

		for (i in 0...10)
			Paths.image('num' + i);
	}

	private function popUpScore(note:Note = null):Void
	{
		var noteDiff:Float = Math.abs(note.strumTime - Conductor.songPosition + ClientPrefs.data.ratingOffset);
		// trace(noteDiff, ' ' + Math.abs(note.strumTime - Conductor.songPosition));

		vocals.volume = 1;
		var placement:String = Std.string(combo);

		var coolText:FlxText = new FlxText(0, 0, 0, placement, 32);
		coolText.screenCenter();
		coolText.x = FlxG.width * 0.35;

		var rating:FlxSprite = new FlxSprite();
		var score:Int = 350;

		// tryna do MS based judgment due to popular demand
		var daRating:Rating = Conductor.judgeNote(ratingsData, noteDiff / playbackRate);

		totalNotesHit += daRating.ratingMod;
		note.ratingMod = daRating.ratingMod;
		if (!note.ratingDisabled)
			daRating.hits++;
		note.rating = daRating.name;
		score = daRating.score;

		if (daRating.noteSplash && !note.noteSplashData.disabled)
			spawnNoteSplashOnNote(note);

		if (!note.ratingDisabled)
		{
			songHits++;
			totalPlayed++;
			RecalculateRating(false);
		}

		var pixelShitPart1:String = "";
		var pixelShitPart2:String = '';

		rating.loadGraphic(Paths.image(pixelShitPart1 + daRating.image + pixelShitPart2));
		rating.screenCenter();
		rating.x = coolText.x - 40;
		rating.y -= 60;
		rating.acceleration.y = 550 * playbackRate * playbackRate;
		rating.velocity.y -= FlxG.random.int(140, 175) * playbackRate;
		rating.velocity.x -= FlxG.random.int(0, 10) * playbackRate;
		rating.visible = (!ClientPrefs.data.hideHud && showRating);
		rating.x += ClientPrefs.data.comboOffset[0];
		rating.y -= ClientPrefs.data.comboOffset[1];

		var comboSpr:FlxSprite = new FlxSprite().loadGraphic(Paths.image(pixelShitPart1 + 'combo' + pixelShitPart2));
		comboSpr.screenCenter();
		comboSpr.x = coolText.x;
		comboSpr.acceleration.y = FlxG.random.int(200, 300) * playbackRate * playbackRate;
		comboSpr.velocity.y -= FlxG.random.int(140, 160) * playbackRate;
		comboSpr.visible = (!ClientPrefs.data.hideHud && showCombo);
		comboSpr.x += ClientPrefs.data.comboOffset[0];
		comboSpr.y -= ClientPrefs.data.comboOffset[1];
		comboSpr.y += 60;
		comboSpr.velocity.x += FlxG.random.int(1, 10) * playbackRate;

		insert(members.indexOf(strumLineNotes), rating);

		if (!ClientPrefs.data.comboStacking)
		{
			if (lastRating != null)
				lastRating.kill();
			lastRating = rating;
		}

		rating.setGraphicSize(Std.int(rating.width * 0.7));
		rating.updateHitbox();
		comboSpr.setGraphicSize(Std.int(comboSpr.width * 0.7));
		comboSpr.updateHitbox();

		var seperatedScore:Array<Int> = [];

		if (combo >= 1000)
		{
			seperatedScore.push(Math.floor(combo / 1000) % 10);
		}
		seperatedScore.push(Math.floor(combo / 100) % 10);
		seperatedScore.push(Math.floor(combo / 10) % 10);
		seperatedScore.push(combo % 10);

		var daLoop:Int = 0;
		var xThing:Float = 0;
		if (showCombo)
		{
			insert(members.indexOf(strumLineNotes), comboSpr);
		}
		if (!ClientPrefs.data.comboStacking)
		{
			if (lastCombo != null)
				lastCombo.kill();
			lastCombo = comboSpr;
		}
		if (lastScore != null)
		{
			while (lastScore.length > 0)
			{
				lastScore[0].destroy();
				lastScore.remove(lastScore[0]);
			}
		}
		for (i in seperatedScore)
		{
			var numScore:FlxSprite = new FlxSprite().loadGraphic(Paths.image(pixelShitPart1 + 'num' + Std.int(i) + pixelShitPart2));
			numScore.screenCenter();
			numScore.x = coolText.x + (43 * daLoop) - 90 + ClientPrefs.data.comboOffset[2];
			numScore.y += 80 - ClientPrefs.data.comboOffset[3];

			if (!ClientPrefs.data.comboStacking)
				lastScore.push(numScore);

			numScore.setGraphicSize(Std.int(numScore.width * 0.5));
			numScore.updateHitbox();

			numScore.acceleration.y = FlxG.random.int(200, 300) * playbackRate * playbackRate;
			numScore.velocity.y -= FlxG.random.int(140, 160) * playbackRate;
			numScore.velocity.x = FlxG.random.float(-5, 5) * playbackRate;
			numScore.visible = !ClientPrefs.data.hideHud;

			// if (combo >= 10 || combo == 0)
			if (showComboNum)
				insert(members.indexOf(strumLineNotes), numScore);

			FlxTween.tween(numScore, {alpha: 0}, 0.2 / playbackRate, {
				onComplete: function(tween:FlxTween)
				{
					numScore.destroy();
				},
				startDelay: Conductor.crochet * 0.002 / playbackRate
			});

			daLoop++;
			if (numScore.x > xThing)
				xThing = numScore.x;
		}
		comboSpr.x = xThing + 50;
		/*
			trace(combo);
			trace(seperatedScore);
		 */

		coolText.text = Std.string(seperatedScore);
		// add(coolText);

		FlxTween.tween(rating, {alpha: 0}, 0.2 / playbackRate, {
			startDelay: Conductor.crochet * 0.001 / playbackRate
		});

		FlxTween.tween(comboSpr, {alpha: 0}, 0.2 / playbackRate, {
			onComplete: function(tween:FlxTween)
			{
				coolText.destroy();
				comboSpr.destroy();

				rating.destroy();
			},
			startDelay: Conductor.crochet * 0.002 / playbackRate
		});
	}

	private function keyPressed(key:Int)
	{
		if (startingSong || key < 0)
			return;

		var inputSongPos:Float = Conductor.songPosition;
		var bestNote:Note = null;
		var secondNote:Note = null;
		var i:Int = 0;
		while (i < notes.length)
		{
			var n:Note = notes.members[i];
			if (n != null)
			{
				var tooLateAt:Bool = n.strumTime < inputSongPos - Conductor.safeZoneOffset && !n.wasGoodHit;
				var canBeHitAt:Bool = (n.strumTime > inputSongPos - (Conductor.safeZoneOffset * n.lateHitMult)
					&& n.strumTime < inputSongPos + (Conductor.safeZoneOffset * n.earlyHitMult));
				var canHit:Bool = !strumsBlocked[n.noteData]
					&& n.mustPress
					&& canBeHitAt
					&& !tooLateAt
					&& !n.wasGoodHit
					&& !n.blockHit;
				if (canHit && !n.isSustainNote && n.noteData == key)
				{
					if (bestNote == null || n.strumTime < bestNote.strumTime)
					{
						secondNote = bestNote;
						bestNote = n;
					}
					else if (secondNote == null || n.strumTime < secondNote.strumTime)
					{
						secondNote = n;
					}
				}
			}
			i++;
		}

		var shouldMiss:Bool = !ClientPrefs.data.ghostTapping;

		if (bestNote != null)
		{
			var funnyNote:Note = bestNote;

			if (secondNote != null)
			{
				var doubleNote:Note = secondNote;

				if (doubleNote.noteData == funnyNote.noteData)
				{
					if (Math.abs(doubleNote.strumTime - funnyNote.strumTime) < 1.0)
					{
						doubleNote.killTail = true;
						invalidateNote(doubleNote);
					}
					else if (doubleNote.strumTime > funnyNote.strumTime
						&& !doubleNote.hitCausesMiss
						&& !doubleNote.ignoreNote
						&& (funnyNote.hitCausesMiss || funnyNote.ignoreNote))
					{
						funnyNote = doubleNote;
					}
				}
			}

			if (funnyNote.tail.length > 0)
			{
				for (childNote in funnyNote.tail)
				{
					childNote.canHold = true;
				}
			}
			goodNoteHit(funnyNote);
		}
		else
		{
			var holdNote:Note = null;
			var j:Int = 0;
			while (j < notes.length)
			{
				var n2:Note = notes.members[j];
				if (n2 != null)
				{
					var tooLateAt2:Bool = n2.strumTime < inputSongPos - Conductor.safeZoneOffset && !n2.wasGoodHit;
					var canBeHitAt2:Bool = (n2.strumTime > inputSongPos - (Conductor.safeZoneOffset * n2.lateHitMult)
						&& n2.strumTime < inputSongPos + (Conductor.safeZoneOffset * n2.earlyHitMult));
					var canHit2:Bool = !strumsBlocked[n2.noteData]
						&& n2.mustPress
						&& canBeHitAt2
						&& !tooLateAt2
						&& !n2.wasGoodHit
						&& !n2.blockHit;
					if (canHit2 && n2.isSustainNote && n2.noteData == key)
					{
						holdNote = n2;
						break;
					}
				}
				j++;
			}

			if (holdNote != null && holdNote.parent != null)
			{
				var parentNote:Note = holdNote.parent;
				if (parentNote.tail.length > 0)
				{
					for (child in parentNote.tail)
					{
						if (child != null)
						{
							child.canHold = true;
						}
					}
				}
			}

			if (shouldMiss)
			{
				noteMissPress(key);
			}
		}

		if (!keysPressed.contains(key))
			keysPressed.push(key);

		var spr:StrumNote = playerStrums.members[key];
		if (strumsBlocked[key] != true && spr != null && spr.animation.curAnim.name != 'confirm')
		{
			spr.playAnim('pressed');
			spr.resetAnim = 0;
		}
	}

	private function keyReleased(key:Int)
	{
		var spr:StrumNote = playerStrums.members[key];
		if (spr != null)
		{
			spr.playAnim('static');
			spr.resetAnim = 0;
		}
	}

	// Hold notes
	private function keysCheck():Void
	{
		for (i in 0...keysArray.length)
		{
			var key:String = keysArray[i];
			_hold[i] = controls.pressed(key);
			_press[i] = controls.justPressed(key);
			_release[i] = controls.justReleased(key);
		}

		if (_press.contains(true))
			for (i in 0..._press.length)
				if (_press[i] && strumsBlocked[i] != true)
					keyPressed(i);

		if (!startingSong && notes.length > 0)
		{
			var len:Int = notes.length;
			var i:Int = 0;
			while (i < len)
			{
				var daNote:Note = cast notes.members[i];
				if (daNote != null && daNote.exists && daNote.alive)
				{
					var inputSongPos:Float = Conductor.songPosition;
					var tooLateAt:Bool = daNote.strumTime < inputSongPos - Conductor.safeZoneOffset && !daNote.wasGoodHit;
					var canBeHitAt:Bool = (daNote.strumTime > inputSongPos - (Conductor.safeZoneOffset * daNote.lateHitMult)
						&& daNote.strumTime < inputSongPos + (Conductor.safeZoneOffset * daNote.earlyHitMult));
					if (strumsBlocked[daNote.noteData] != true
						&& daNote.isSustainNote
						&& _hold[daNote.noteData]
						&& canBeHitAt
						&& !tooLateAt
						&& !daNote.wasGoodHit
						&& !daNote.blockHit
						&& daNote.canHold)
					{
						if (daNote.mustPress)
							goodNoteHit(daNote);
					}
				}
				i++;
			}
		}

		if (_release.contains(true))
			for (i in 0..._release.length)
				if (_release[i] || strumsBlocked[i] == true)
					keyReleased(i);
	}

	function opponentNoteHit(note:Note):Void
	{
		if (PlayState.SONG.needsVoices && opponentVocals.length <= 0)
			vocals.volume = 1;

		var strum:StrumNote = opponentStrums.members[Std.int(Math.abs(note.noteData))];
		if (strum != null)
		{
			strum.playAnim('confirm', true);
			strum.resetAnim = Conductor.stepCrochet * 1.25 / 1000 / playbackRate;
		}
		note.hitByOpponent = true;

		if (!note.isSustainNote)
			invalidateNote(note);
	}

	function goodNoteHit(note:Note):Void
	{
		if (note.wasGoodHit)
			return;

		note.wasGoodHit = true;
		if (ClientPrefs.data.hitsoundVolume > 0 && !note.hitsoundDisabled)
			FlxG.sound.play(Paths.sound('hitsound'), ClientPrefs.data.hitsoundVolume);

		if (note.hitCausesMiss)
		{
			noteMiss(note);
			if (!note.noteSplashData.disabled && !note.isSustainNote)
				spawnNoteSplashOnNote(note);

			if (!note.isSustainNote)
				invalidateNote(note);
			return;
		}

		if (!note.isSustainNote)
		{
			combo++;
			if (combo > 9999)
				combo = 9999;
			popUpScore(note);
		}

		var spr:StrumNote = playerStrums.members[note.noteData];
		if (spr != null)
			spr.playAnim('confirm', true);
		vocals.volume = 1;

		if (!note.isSustainNote)
			invalidateNote(note);
	}

	function noteMiss(daNote:Note):Void
	{ // You didn't hit the key and let it go offscreen, also used by Hurt Notes
		// Dupe note remove
		notes.forEachAlive(function(note:Note)
		{
			if (daNote != note
				&& daNote.mustPress
				&& daNote.noteData == note.noteData
				&& daNote.isSustainNote == note.isSustainNote
				&& Math.abs(daNote.strumTime - note.strumTime) < 1)
				invalidateNote(daNote);
		});

		if (daNote != null && guitarHeroSustains && daNote.parent == null)
		{
			if (daNote.tail.length > 0)
			{
				daNote.alpha = 0.35;
				for (childNote in daNote.tail)
				{
					childNote.alpha = daNote.alpha;
					childNote.missed = true;
					childNote.canBeHit = false;
					childNote.ignoreNote = true;
					childNote.tooLate = true;
				}
				daNote.missed = true;
				daNote.canBeHit = false;
			}

			if (daNote.missed)
				return;
		}

		if (daNote != null && guitarHeroSustains && daNote.parent != null && daNote.isSustainNote)
		{
			if (daNote.missed)
				return;

			var parentNote:Note = daNote.parent;
			if (parentNote.wasGoodHit && parentNote.tail.length > 0)
			{
				for (child in parentNote.tail)
					if (child != daNote)
					{
						child.missed = true;
						child.canBeHit = false;
						child.ignoreNote = true;
						child.tooLate = true;
					}
			}
		}

		// score and data
		songMisses++;
		totalPlayed++;
		RecalculateRating(true);
		vocals.volume = 0;
		combo = 0;
	}

	function noteMissPress(direction:Int = 1):Void
	{
		if (ClientPrefs.data.ghostTapping)
			return;

		songMisses++;
		totalPlayed++;
		RecalculateRating(true);
		vocals.volume = 0;
		combo = 0;
		FlxG.sound.play(Paths.soundRandom('missnote', 1, 3), FlxG.random.float(0.1, 0.2));
	}

	public function invalidateNote(note:Note):Void
	{
		killNotes.push(note);
	}

	public function destroyNotes():Void
	{
		var count:Int = killNotes.length;
		if (count == 0) return;
		var limit:Int = killNotesBudget;
		if (limit < 1) limit = count;
		if (limit > count) limit = count;
		var idx:Int = 0;
		while (idx < limit)
		{
			var note:Note = killNotes[idx];
			if (note != null)
			{
				if (note.tail.length != 0 && note.killTail)
				{
					var t:Int = 0;
					var tailLen:Int = note.tail.length;
					while (t < tailLen)
					{
						var sustain:Note = note.tail[t];
						if (sustain != null)
						{
							sustain.kill();
							notes.remove(sustain, true);
							sustain.destroy();
						}
						t++;
					}
				}
				note.kill();
				notes.remove(note, true);
				note.destroy();
			}
			idx++;
		}
		if (idx > 0) killNotes.splice(0, idx);
	}

	function spawnNoteSplashOnNote(note:Note)
	{
		if (note != null)
		{
			var strum:StrumNote = playerStrums.members[note.noteData];
			if (strum != null)
				spawnNoteSplash(strum.x, strum.y, note.noteData, note, strum);
		}
	}

	function spawnNoteSplash(x:Float, y:Float, data:Int, ?note:Note = null, ?strum:StrumNote = null)
	{
		var splash:NoteSplash = grpNoteSplashes.recycle(NoteSplash);
		splash.babyArrow = strum;
		splash.spawnSplashNote(x, y, data, note);
		grpNoteSplashes.add(splash);
	}

	function resyncVocals():Void
	{
		if (finishTimer != null)
			return;

		FlxG.sound.music.play();
		#if FLX_PITCH FlxG.sound.music.pitch = playbackRate; #end
		Conductor.songPosition = FlxG.sound.music.time;
		if (timing != null) timing.setPosition(Conductor.songPosition);
		if (Conductor.songPosition <= vocals.length)
		{
			vocals.time = Conductor.songPosition;
			#if FLX_PITCH vocals.pitch = playbackRate; #end
		}

		if (Conductor.songPosition <= opponentVocals.length)
		{
			opponentVocals.time = Conductor.songPosition;
			#if FLX_PITCH opponentVocals.pitch = playbackRate; #end
		}
		vocals.play();
		opponentVocals.play();
	}

	function RecalculateRating(badHit:Bool = false)
	{
		if (totalPlayed != 0) // Prevent divide by 0
			ratingPercent = Math.min(1, Math.max(0, totalNotesHit / totalPlayed));

		fullComboUpdate();
		updateScore(badHit); // score will only update after rating is calculated, if it's a badHit, it shouldn't bounce -Ghost
	}

	function updateScore(miss:Bool = false)
	{
		var str:String = '?';
		if (totalPlayed != 0)
		{
			var percent:Float = CoolUtil.floorDecimal(ratingPercent * 100, 2);
			str = '$percent% - $ratingFC';
		}
		scoreTxt.text = 'Hits: $songHits | Misses: $songMisses | Rating: $str';
	}

	function fullComboUpdate()
	{
		var sicks:Int = ratingsData[0].hits;
		var goods:Int = ratingsData[1].hits;
		var bads:Int = ratingsData[2].hits;
		var shits:Int = ratingsData[3].hits;

		ratingFC = 'Clear';
		if (songMisses < 1)
		{
			if (bads > 0 || shits > 0)
				ratingFC = 'FC';
			else if (goods > 0)
				ratingFC = 'GFC';
			else if (sicks > 0)
				ratingFC = 'SFC';
		}
		else if (songMisses < 10)
			ratingFC = 'SDCB';
	}

	function loadCharacterFile(char:String):CharacterFile
	{
		var characterPath:String = 'characters/' + char + '.json';
		#if MODS_ALLOWED
		var path:String = Paths.modFolders(characterPath);
		if (!FileSystem.exists(path))
		{
			path = Paths.getSharedPath(characterPath);
		}

		if (!FileSystem.exists(path))
		#else
		var path:String = Paths.getSharedPath(characterPath);
		if (!OpenFlAssets.exists(path))
		#end
		{
			path = Paths.getSharedPath('characters/' + Character.DEFAULT_CHARACTER +
				'.json'); // If a character couldn't be found, change him to BF just to prevent a crash
		}

		#if MODS_ALLOWED
		var rawJson = File.getContent(path);
		#else
		var rawJson = OpenFlAssets.getText(path);
		#end
		return cast Json.parse(rawJson);
	}
}
