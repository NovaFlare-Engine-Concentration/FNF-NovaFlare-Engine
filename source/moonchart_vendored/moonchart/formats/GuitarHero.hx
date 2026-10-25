package moonchart.formats;

import moonchart.backend.FormatData;
import moonchart.backend.Timing;
import moonchart.backend.Util;
import moonchart.formats.BasicFormat;
import moonchart.parsers.GuitarHeroParser;

using StringTools;

typedef GhBpmChange =
{
	tick:Int,
	bpm:Float,
	beatsPerMeasure:Int,
	stepsPerBeat:Int
}

class GuitarHero extends BasicFormat<GuitarHeroFormat, {}>
{
	public static function __getFormat():FormatData
	{
		return {
			ID: GUITAR_HERO,
			name: "Guitar Hero",
			description: "Guitar solo fuck yeah.",
			extension: "chart",
			hasMetaFile: FALSE,
			handler: GuitarHero
		}
	}

	var parser:GuitarHeroParser;

	public function new(?data:GuitarHeroFormat)
	{
		super({timeFormat: TICKS, supportsDiffs: true, supportsEvents: true});
		this.data = data;
		parser = new GuitarHeroParser();
	}

	public inline static var GUITAR_HERO_RESOLUTION:Int = 192;

	inline function getTickCrochet(bpm:Float, res:Int = GUITAR_HERO_RESOLUTION):Float
	{
		return Timing.stepCrochet(bpm, res);
	}

	inline function getTick(lastTick:Int, diff:Float, tickCrochet:Float)
	{
		return Std.int(lastTick + (diff / tickCrochet));
	}

	function formatGhDiff(diff:String):String
	{
		diff = diff.toLowerCase();

		if (diff.endsWith("Single"))
			diff = diff.substring(0, diff.length - 6);

		return diff;
	}

	function getSyncTrack(bpmChanges:Array<BasicBPMChange>):Array<GuitarHeroTimedObject>
	{
		var syncTrack:Array<GuitarHeroTimedObject> = [];

		var initChange = bpmChanges[0];
		var tickCrochet:Float = getTickCrochet(initChange.bpm);
		var lastTime:Float = initChange.time;
		var lastTick:Int = getTick(0, lastTime, tickCrochet);

		var lastBeats:Int = -1;
		var lastDenExp:Int = -1;

		for (change in bpmChanges)
		{
			var changeTick:Int = getTick(lastTick, change.time - lastTime, tickCrochet);
			var changeBeats:Int = Std.int(change.beatsPerMeasure);
			var denExp:Int = Std.int(Math.log(change.stepsPerBeat) / Math.log(2));

			tickCrochet = getTickCrochet(change.bpm);
			lastTick = changeTick;
			lastTime = change.time;

			if (changeBeats != lastBeats || denExp != lastDenExp)
			{
				syncTrack.push({
					tick: changeTick,
					type: TIME_SIGNATURE_CHANGE,
					values: [changeBeats, denExp]
				});

				lastBeats = changeBeats;
				lastDenExp = denExp;
			}

			syncTrack.push({
				tick: changeTick,
				type: TEMPO_CHANGE,
				values: [Std.int(change.bpm * 1000)]
			});
		}

		return syncTrack;
	}

	override function fromBasicFormat(chart:BasicChart, ?diff:FormatDifficulty):GuitarHero
	{
		var chartResolve = resolveDiffsNotes(chart, diff).notes;
		var bpmChanges = Timing.sortBPMChanges(chart.meta.bpmChanges);

		var chartSingles:Map<String, Array<GuitarHeroTimedObject>> = [];
		var events:Array<GuitarHeroTimedObject> = [];
		var syncTrack = getSyncTrack(bpmChanges);

		// Parse through all the difficulties
		for (chartDiff => chart in chartResolve)
		{
			var chartSingle:Array<GuitarHeroTimedObject> = [];
			var noteIndex:Int = 0;

			var tickCrochet:Float = getTickCrochet(bpmChanges[0].bpm);
			var lastTick:Int = syncTrack[0].tick;
			var lastTime:Float = bpmChanges[0].time;

			final pushGhNote = () ->
			{
				var note = chart[noteIndex++];
				var tick:Int = getTick(lastTick, note.time - lastTime, tickCrochet);
				var length:Int = getTick(0, note.length, tickCrochet);

				chartSingle.push({
					tick: tick,
					type: NOTE_EVENT,
					values: [note.lane, length]
				});
			}

			// Since GH works based on ticks we gotta push notes in queue with the bpm changes
			for (change in bpmChanges)
			{
				lastTick = getTick(lastTick, change.time - lastTime, tickCrochet);
				lastTime = change.time;

				while (noteIndex < chart.length && chart[noteIndex].time < change.time)
					pushGhNote();

				tickCrochet = getTickCrochet(change.bpm);
			}

			// Push any leftover notes after the last bpm change
			while (noteIndex < chart.length)
				pushGhNote();

			var ghDiff:String = formatGhDiff(chartDiff);
			chartSingles.set(ghDiff, chartSingle);
		}

		var offset:Float = chart.meta.offset ?? 0.0;
		offset /= 1000;

		this.data = {
			Song: {
				Name: chart.meta.title,
				Artist: chart.meta.extraData.get(SONG_ARTIST) ?? Moonchart.DEFAULT_ARTIST,
				Charter: chart.meta.extraData.get(SONG_CHARTER) ?? Moonchart.DEFAULT_CHARTER,
				Album: chart.meta.extraData.get(SONG_ALBUM) ?? Moonchart.DEFAULT_ALBUM,
				Resolution: GUITAR_HERO_RESOLUTION,
				Offset: offset
			},
			SyncTrack: syncTrack,
			Events: events,
			Notes: chartSingles
		}

		return this;
	}

	override function getNotes(?diff:String):Array<BasicNote>
	{
		var chartSingle = data.Notes.get(diff);
		if (chartSingle == null)
		{
			throw "Couldn't find Guitar Hero notes for difficulty " + (diff ?? "null");
			return null;
		}

		var notes:Array<BasicNote> = [];
		chartSingle.sort((a, b) -> Util.sortValues(a.tick, b.tick));

		final tempoChanges:Array<GhBpmChange> = getTempoChanges();
		final res = data.Song.Resolution;
		final resMult = res / GUITAR_HERO_RESOLUTION;

		// Precalculate the first tempo change
		var tempoIndex:Int = 1;
		var tickCrochet:Float = getTickCrochet(tempoChanges[0].bpm, res);
		var lastChangeTick:Int = tempoChanges[0].tick;
		var lastTime:Float = lastChangeTick * tickCrochet;

		for (note in chartSingle)
		{
			if (note.type != NOTE_EVENT) // TODO: maybe could support lyric events later
				continue;

			// Calculate all tempo changes mid notes
			while (tempoIndex < tempoChanges.length && note.tick >= tempoChanges[tempoIndex].tick)
			{
				final change = tempoChanges[tempoIndex++];
				final elapsedTicks:Int = (change.tick - lastChangeTick);

				lastTime += (elapsedTicks * tickCrochet);
				tickCrochet = getTickCrochet(change.bpm, res);
				lastChangeTick = change.tick;
			}

			final time:Float = lastTime + ((note.tick - lastChangeTick) * tickCrochet);
			final lane:Int = note.values[0];
			final length:Float = note.values[1] * tickCrochet;

			notes.push({
				time: time * resMult,
				lane: lane,
				length: length * resMult,
				type: ""
			});
		}

		return notes;
	}

	function getTempoChanges():Array<GhBpmChange>
	{
		var tempoChanges:Array<GhBpmChange> = [];

		var beatsPerMeasure:Int = 4;
		var stepsPerBeat:Int = 4;

		for (event in data.SyncTrack)
		{
			switch (event.type)
			{
				case TIME_SIGNATURE_CHANGE:
					beatsPerMeasure = event.values[0];
					stepsPerBeat = Std.int(Math.pow(2, event.values[1] ?? 2));
				case TEMPO_CHANGE:
					tempoChanges.push({
						tick: event.tick,
						bpm: event.values[0] / 1000,
						beatsPerMeasure: beatsPerMeasure,
						stepsPerBeat: stepsPerBeat
					});
				default:
			}
		}

		// Make sure its sorted
		tempoChanges.sort((tempo1, tempo2) -> return Util.sortValues(tempo1.tick, tempo2.tick));

		return tempoChanges;
	}

	// TODO
	override function getEvents():Array<BasicEvent>
	{
		return [];
	}

	override function getChartMeta():BasicMetaData
	{
		// Get only the bpm change based events
		var tempoChanges:Array<GhBpmChange> = getTempoChanges();
		var bpmChanges:Array<BasicBPMChange> = Util.makeArray(tempoChanges.length + 1);

		// Pushing the first tempo change at 0 for good measure
		final initChange = tempoChanges[0];
		final res = data.Song.Resolution;
		final resMult = res / GUITAR_HERO_RESOLUTION;

		Util.setArray(bpmChanges, 0, {
			time: 0,
			bpm: initChange.bpm,
			beatsPerMeasure: tempoChanges[0].beatsPerMeasure,
			stepsPerBeat: tempoChanges[0].stepsPerBeat
		});

		var tickCrochet = getTickCrochet(initChange.bpm, res);
		var lastTick:Int = initChange.tick;
		var time:Float = lastTick * tickCrochet;

		for (i in 0...tempoChanges.length)
		{
			final change = Util.getArray(tempoChanges, i);
			final elapsedTicks:Int = (change.tick - lastTick);
			final bpm:Float = change.bpm;
			time += elapsedTicks * tickCrochet;

			Util.setArray(bpmChanges, i + 1, {
				time: time * resMult,
				bpm: bpm,
				beatsPerMeasure: change.beatsPerMeasure,
				stepsPerBeat: change.stepsPerBeat
			});

			lastTick = change.tick;
			tickCrochet = getTickCrochet(bpm, res);
		}

		// I may be blind and theres metadata for this but blehhh
		var foundLanesLength:Int = 0;
		for (diff => chart in data.Notes)
		{
			for (note in chart)
			{
				var laneLength:Int = note.values[0] + 1;
				if (laneLength > foundLanesLength)
					foundLanesLength = laneLength;
			}
		}

		return {
			title: data.Song.Name,
			bpmChanges: bpmChanges,
			scrollSpeeds: [],
			offset: data.Song.Offset * 1000,
			extraData: [
				LANES_LENGTH => foundLanesLength,
				STRUMLINE_KEYS => foundLanesLength,
				STRUMLINE_LANES => 1,
				SONG_ARTIST => data.Song.Artist,
				SONG_CHARTER => data.Song.Charter,
				SONG_ALBUM => data.Song.Album
			]
		}
	}

	override public function stringify()
	{
		return {
			data: parser.stringify(data),
			meta: null
		}
	}

	override public function fromFile(path:String, ?meta:String, ?diff:FormatDifficulty):GuitarHero
	{
		return fromGuitarHero(Util.getText(path), diff);
	}

	public function fromGuitarHero(data:String, ?diff:FormatDifficulty):GuitarHero
	{
		this.data = parser.parse(data);
		this.diffs = diff ?? Util.mapKeyArray(this.data.Notes);
		return this;
	}
}
