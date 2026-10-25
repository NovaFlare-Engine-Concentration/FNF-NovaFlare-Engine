package moonchart.formats;

import moonchart.backend.FormatData;
import moonchart.backend.Timing;
import moonchart.backend.Util;
import moonchart.formats.BasicFormat;
import moonchart.parsers.BasicParser;
import moonchart.parsers.StepManiaParser;

using StringTools;

enum abstract StepManiaNote(Int) from Int to Int
{
	var EMPTY = "0".code;
	var NOTE = "1".code;
	var HOLD_HEAD = "2".code;
	var HOLD_TAIL = "3".code;
	var ROLL_HEAD = "4".code;
	var MINE = "M".code;
	var FAKE = "F".code;
}

class StepMania extends StepManiaBasic<StepManiaFormat>
{
	// StepMania Constants
	public static inline var STEPMANIA_SCROLL_SPEED:Float = 0.017775; // 0.00355555555;

	// Format description by burgerballs
	public static function __getFormat():FormatData
	{
		return {
			ID: STEPMANIA,
			name: "StepMania",
			description: 'The original format used for most Stepmania versions and forks like "NotITG".',
			extension: "sm",
			hasMetaFile: FALSE,
			handler: StepMania
		}
	}

	public function new(?data:StepManiaFormat)
	{
		super(data);
		parser = new StepManiaParser();
	}

	override public function fromFile(path:String, ?meta:String, ?diff:FormatDifficulty):StepMania
	{
		return fromStepMania(Util.getText(path), diff);
	}

	public function fromStepMania(data:String, ?diff:FormatDifficulty):StepMania
	{
		this.data = cast parser.parse(data);
		this.diffs = diff ?? Util.mapKeyArray(this.data.NOTES);
		return this;
	}
}

@:private
@:noCompletion
abstract class StepManiaBasic<T:StepManiaFormat> extends BasicFormat<T, {}>
{
	var parser:BasicParser<T>;

	public function new(?data:T)
	{
		super({timeFormat: STEPS, supportsDiffs: true, supportsEvents: true});
		this.data = data;
	}

	function createMeasure(step:StepManiaStep, snap:Int):StepManiaMeasure
	{
		var measure:StepManiaMeasure = Util.makeArray(snap);

		for (i in 0...snap)
			Util.setArray(measure, i, step);

		return measure;
	}

	function writeStep(measure:StepManiaMeasure, step:Int, lane:Int, code:Int):Void
	{
		if (step >= measure.length)
			return;

		// Not sure if this is the best way to replace a char at an index from a string
		// Please lemme know if theres a better way out there
		final str:String = measure[step];
		measure[step] = str.substr(0, lane) + String.fromCharCode(code) + str.substr(lane + 1);
	}

	// TODO: look further into fucked up bpm changes timing
	override function fromBasicFormat(chart:BasicChart, ?diff:FormatDifficulty):StepManiaBasic<T>
	{
		var basicData = resolveDiffsNotes(chart, diff);
		var bpmChanges = chart.meta.bpmChanges;
		var smNotes:Map<String, StepManiaNotes> = [];

		for (diff => basicNotes in basicData.notes)
		{
			// Find dance
			final lanes:Int = chart.meta.extraData.get(LANES_LENGTH) ?? 4;
			final dance:StepManiaDance = (lanes >= 8) ? DOUBLE : resolveDance(basicNotes);

			final n = String.fromCharCode(EMPTY);
			final songStep:StepManiaStep = [for (i in 0...dance.len()) n].join("");

			// Divide notes to measures
			var basicMeasures = Timing.divideNotesToMeasures(basicNotes, [], bpmChanges);
			var measures:Array<StepManiaMeasure> = [];
			var queuedNotes:Array<BasicNote> = [];

			// Prepare the measures the song will need
			for (basicMeasure in basicMeasures)
			{
				measures.push(createMeasure(songStep, basicMeasure.snap));
			}

			final measureStartBeats:Array<Float> = [];
			var currentBeat:Float = 0.0;
			for (basicMeasure in basicMeasures)
			{
				measureStartBeats.push(currentBeat);
				currentBeat += basicMeasure.beatsPerMeasure;
			}

			final l:Int = basicMeasures.length;
			var i:Int = 0;

			while (i < l)
			{
				final basicMeasure = Util.getArray(basicMeasures, i);
				final measure = Util.getArray(measures, i);
				final snap:Int = measure.length;
				final measureStartBeat:Float = measureStartBeats[i];

				// Find notes of the current measure
				var measureNotes:Array<BasicNote>;
				if (queuedNotes.length > 0)
				{
					measureNotes = basicMeasure.notes.concat(queuedNotes);
					Util.resizeArray(queuedNotes, 0);
				}
				else
				{
					measureNotes = basicMeasure.notes;
				}

				for (note in measureNotes)
				{
					final noteBeat:Float = Timing.getBeatAtTime(note.time, bpmChanges);
					final localBeat:Float = noteBeat - measureStartBeat;
					var noteStep:Int = Math.round(localBeat * snap / basicMeasure.beatsPerMeasure);

					if (noteStep > snap - 1)
					{
						// Save notes out of the measure for the next one
						queuedNotes.push(note);
						continue;
					}
					else if (noteStep < 0)
					{
						continue;
					}

					// Normal note
					if (note.length <= 0)
					{
						writeStep(measure, noteStep, note.lane, switch (note.type)
						{
							case BasicNoteType.MINE: MINE;
							default: NOTE;
						});
					}
					// Hold note
					else
					{
						final holdBeat:Float = Timing.getBeatAtTime(note.time + note.length, bpmChanges);

						var holdIndex:Int = i;
						var holdMeasure:StepManiaMeasure = measure;
						var holdStep:Int = -1;

						// Find which measure corresponds to the hold step
						var found = false;
						for (j in i...measures.length)
						{
							final startBeat:Float = measureStartBeats[j];
							final beatsPerMeasure:Float = basicMeasures[j].beatsPerMeasure;
							final snap:Int = measures[j].length;

							final localBeat:Float = holdBeat - startBeat;
							if (localBeat >= 0 && localBeat <= beatsPerMeasure)
							{
								holdIndex = j;
								holdMeasure = measures[j];
								holdStep = Math.round(localBeat * snap / beatsPerMeasure);
								found = true;
								break;
							}
						}

						// Measure doesnt exist
						if (!found)
							holdStep = measures[measures.length - 1].length - 1;

						holdStep = Util.minInt(holdStep - 1, holdMeasure.length - 1);

						writeStep(measure, noteStep, note.lane, switch (note.type)
						{
							case BasicNoteType.ROLL: ROLL_HEAD;
							default: HOLD_HEAD;
						});

						if (holdStep == noteStep) // idk man im tired
							holdStep = holdStep = Util.minInt(holdStep + 1, holdMeasure.length - 1);

						if (holdStep > -1)
							writeStep(holdMeasure, holdStep, note.lane, HOLD_TAIL);
					}
				}

				i++;
			}

			smNotes.set(diff, {
				diff: diff,
				desc: "",
				dance: dance,
				notes: measures,
				charter: chart.meta.extraData.get(SONG_CHARTER) ?? Moonchart.DEFAULT_CHARTER,
				meter: 1,
				radar: [0, 0, 0, 0, 0]
			});
		}

		// Convert BPM milliseconds to beats
		var beats:Float = 0.0;
		var prevTime:Float = 0.0;

		var prevBpm:Float = bpmChanges[0].bpm;
		var bpms:Array<StepManiaBPM> = Util.makeArray(bpmChanges.length);

		Util.setArray(bpms, 0, {
			beat: 0,
			bpm: prevBpm
		});

		for (i in 1...bpmChanges.length)
		{
			final change = bpmChanges[i];
			beats += ((change.time - prevTime) / 60000) * prevBpm;

			Util.setArray(bpms, i, {
				beat: beats,
				bpm: change.bpm
			});

			prevTime = change.time;
			prevBpm = change.bpm;
		}

		var data:StepManiaFormat = {
			TITLE: chart.meta.title,
			ARTIST: chart.meta.extraData.get(SONG_ARTIST) ?? Moonchart.DEFAULT_ARTIST,
			MUSIC: chart.meta.extraData.get(AUDIO_FILE) ?? "",
			OFFSET: (chart.meta.offset ?? 0.0) / 1000,
			BPMS: bpms,
			STOPS: [],
			NOTES: smNotes
		}

		this.data = cast data;

		return this;
	}

	function resolveDance(notes:Array<BasicNote>):StepManiaDance
	{
		for (note in notes)
		{
			if (note.lane > 3)
			{
				return DOUBLE;
			}
		}
		return SINGLE;
	}

	override function getNotes(?diff:String):Array<BasicNote>
	{
		diff ??= Util.mapFirstKey(data.NOTES);

		var smChart = data.NOTES.get(diff);
		if (smChart == null)
		{
			throw "Couldn't find StepMania notes for difficulty " + diff;
			return null;
		}

		var smNotes = smChart.notes;
		var notes:Array<BasicNote> = [];

		var bpms = data.BPMS;
		var bpmIndex:Int = 1;

		var stops = data.STOPS;
		var stopIndex:Int = 0;

		var bpm = bpms[0].bpm;
		var beat:Float = bpms[0].beat;
		var time:Float = beat * Timing.crochet(bpm);

		final getStepCrochet = (snap:Int) -> return Timing.snappedStepCrochet(bpm, 4, snap);
		final holdIndexes:Array<Int> = [for (i in 0...smChart.dance.len()) -1];

		for (measure in smNotes)
		{
			var steps:Int = measure.length;
			var beatsPerStep = 4.0 / steps;
			var stepCrochet = getStepCrochet(steps);

			for (step in measure)
			{
				// Do BPM changes and sum BPM intervals between steps
				while (bpmIndex < bpms.length && beat >= bpms[bpmIndex].beat)
				{
					// Calculate interval between BPM changes
					final bpmChange = Util.getArray(bpms, bpmIndex);
					var nextBeat = bpmChange.beat;
					var remainingBeats = nextBeat - beat;
					time += remainingBeats * Timing.crochet(bpm);
					time -= remainingBeats * Timing.crochet(bpmChange.bpm);

					// Update the rest of the crap
					bpm = bpmChange.bpm;
					stepCrochet = getStepCrochet(steps);
					bpmIndex++;
				}

				// Check for the current step notes
				for (lane in 0...step.length)
				{
					switch (step.fastCodeAt(lane))
					{
						case EMPTY:
						case NOTE:
							notes.push({
								time: time,
								lane: lane,
								length: 0,
								type: ""
							});
						case MINE:
							notes.push({
								time: time,
								lane: lane,
								length: 0,
								type: BasicNoteType.MINE
							});
						case FAKE:
							notes.push({
								time: time,
								lane: lane,
								length: 0,
								type: BasicNoteType.FAKE
							});
						case HOLD_HEAD:
							notes.push({
								time: time,
								lane: lane,
								length: stepCrochet,
								type: ""
							});
							holdIndexes[lane] = notes.length - 1;
						case ROLL_HEAD:
							notes.push({
								time: time,
								lane: lane,
								length: stepCrochet,
								type: BasicNoteType.ROLL
							});
							holdIndexes[lane] = notes.length - 1;
						case HOLD_TAIL:
							if (holdIndexes[lane] != -1)
							{
								notes[holdIndexes[lane]].length = time - notes[holdIndexes[lane]].time;
								holdIndexes[lane] = -1;
							}
						case _:
					}
				}

				time += stepCrochet;
				beat += beatsPerStep;

				// Do Stops between steps
				while (stopIndex < stops.length && beat >= stops[stopIndex].beat)
				{
					time += stops[stopIndex++].duration * 1000;
				}
			}
		}

		return notes;
	}

	// TODO
	override function getEvents():Array<BasicEvent>
	{
		return [];
	}

	function getBpmChanges():Array<BasicBPMChange>
	{
		var BPMS = data.BPMS;
		var bpmChanges:Array<BasicBPMChange> = Util.makeArray(BPMS.length);

		var time:Float = 0;
		var lastBeat:Float = 0;
		var lastBPM:Float = BPMS[0].bpm;

		Util.setArray(bpmChanges, 0, {
			time: 0,
			bpm: lastBPM,
			beatsPerMeasure: 4,
			stepsPerBeat: 4
		});

		// Convert the bpm changes from beats to milliseconds
		for (i in 1...BPMS.length)
		{
			var change = BPMS[i];
			time += ((change.beat - lastBeat) / lastBPM) * 60000;

			lastBeat = change.beat;
			lastBPM = change.bpm;

			Util.setArray(bpmChanges, i, {
				time: time,
				bpm: lastBPM,
				beatsPerMeasure: 4,
				stepsPerBeat: 4
			});
		}

		bpmChanges = Timing.sortBPMChanges(bpmChanges);
		return bpmChanges;
	}

	override function getChartMeta():BasicMetaData
	{
		// TODO: this may have to apply for bpm changes too, change scroll speed event?
		final bpmChanges:Array<BasicBPMChange> = getBpmChanges();
		final speed:Float = bpmChanges[0].bpm * StepMania.STEPMANIA_SCROLL_SPEED;
		final offset:Float = data.OFFSET is String ? Std.parseFloat(cast data.OFFSET) : data.OFFSET;
		final lanesLength:Int = Util.mapFirst(data.NOTES).dance.len();

		var foundCharters:Array<String> = [];
		for (diff => data in data.NOTES)
		{
			if (data.charter != null && data.charter.length > 0 && foundCharters.indexOf(data.charter) == -1)
				foundCharters.push(data.charter);
		}

		return {
			title: data.TITLE,
			bpmChanges: bpmChanges,
			offset: offset * 1000,
			scrollSpeeds: Util.fillMap(diffs, speed),
			extraData: [
				SONG_ARTIST => data.ARTIST ?? Moonchart.DEFAULT_ARTIST,
				SONG_CHARTER => foundCharters.length > 0 ? foundCharters.join(", ") : Moonchart.DEFAULT_CHARTER,
				AUDIO_FILE => data.MUSIC ?? "",
				LANES_LENGTH => lanesLength,
				STRUMLINE_LANES => lanesLength == 8 ? 2 : 1,
				STRUMLINE_KEYS => 4,
			]
		}
	}

	override function stringify()
	{
		return {
			data: parser.stringify(data),
			meta: null
		}
	}
}
