package moonchart.backend;

import moonchart.backend.Util;
import moonchart.formats.BasicFormat;

class Timing
{
	public static function sortTiming<T:BasicTimingObject>(objects:Array<T>):Array<T>
	{
		objects.sort((a, b) -> Util.sortValues(a.time, b.time));
		return objects;
	}

	public static inline function sortNotes(notes:Array<BasicNote>):Array<BasicNote>
	{
		return sortTiming(notes);
	}

	public static inline function sortEvents(events:Array<BasicEvent>):Array<BasicEvent>
	{
		return sortTiming(events);
	}

	public static inline function sortBPMChanges(bpmChanges:Array<BasicBPMChange>):Array<BasicBPMChange>
	{
		return sortTiming(bpmChanges);
	}

	/**
	 * Removes duplicate unnecesary bpm changes from a bpm array
	 * Checks for bpm and time signature changes	
	 */
	public static function cleanBPMChanges(bpmChanges:Array<BasicBPMChange>):Array<BasicBPMChange>
	{
		if (bpmChanges.length <= 1)
			return bpmChanges;

		var lastChange:BasicBPMChange = bpmChanges[0];

		for (i in 1...bpmChanges.length)
		{
			final newChange = bpmChanges[i];
			final bpm = Util.equalFloat(newChange.bpm, lastChange.bpm);
			final steps = Util.equalFloat(newChange.stepsPerBeat, lastChange.stepsPerBeat);
			final beats = Util.equalFloat(newChange.beatsPerMeasure, lastChange.beatsPerMeasure);

			if (bpm && steps && beats)
			{
				bpmChanges[i] = null;
				continue;
			}

			lastChange = newChange;
		}

		while (true)
		{
			final index:Int = bpmChanges.indexOf(null);
			if (index == -1)
				break;

			bpmChanges.splice(index, 1);
		}

		return bpmChanges;
	}

	public static inline function crochet(bpm:Float):Float
	{
		return (60 / bpm) * 1000;
	}

	public static inline function stepCrochet(bpm:Float, stepsPerBeat:Float):Float
	{
		return crochet(bpm) / stepsPerBeat;
	}

	public static inline function measureCrochet(bpm:Float, beatsPerMeasure:Float):Float
	{
		return crochet(bpm) * beatsPerMeasure;
	}

	public static inline function snappedStepCrochet(bpm:Float, stepsPerBeat:Float, stepsPerMeasure:Float):Float
	{
		return crochet(bpm) * (stepsPerBeat / stepsPerMeasure);
	}

	public static function divideNotesToMeasures(notes:Array<BasicNote>, events:Array<BasicEvent>, bpmChanges:Array<BasicBPMChange>,
			?snaps:Array<Int>):Array<BasicMeasure>
	{
		notes = sortNotes(notes);
		events = sortEvents(events);
		bpmChanges = sortBPMChanges(bpmChanges);

		if (bpmChanges.length <= 0)
			return [];

		var endTime:Float = bpmChanges[bpmChanges.length - 1].time;
		var curTime:Float = 0.0;

		if (notes.length > 0)
		{
			var lastNote = notes[notes.length - 1];
			endTime = Math.max(lastNote.time + lastNote.length, endTime);
		}

		if (events.length > 0)
		{
			endTime = Math.max(events[events.length - 1].time, endTime);
		}

		var measures:Array<BasicMeasure> = [];
		var noteIndex:Int = 0;
		var eventIndex:Int = 0;
		var bpmIndex:Int = 0;

		var lastChange:BasicBPMChange = bpmChanges[0];

		while (curTime < endTime)
		{
			var measureStartTime:Float = curTime;

			var beatsRemaining:Float = lastChange.beatsPerMeasure ?? 4;
			var beatTime:Float = measureStartTime;
			var changeIndex:Int = bpmIndex;
			var curChange:BasicBPMChange = lastChange;

			while (beatsRemaining > 0)
			{
				var nextChange:BasicBPMChange = null;
				var nextTime:Float = Math.POSITIVE_INFINITY;

				while (changeIndex < bpmChanges.length)
				{
					var change = bpmChanges[changeIndex];
					if (change.time > beatTime)
					{
						nextChange = change;
						nextTime = change.time;
						break;
					}
					changeIndex++;
				}

				var curCrochet:Float = crochet(curChange.bpm);

				if (nextTime == Math.POSITIVE_INFINITY) // nothing else here
				{
					beatTime += beatsRemaining * curCrochet;
					beatsRemaining = 0;
				}
				else
				{
					final nextChangeTime:Float = nextTime - beatTime;
					final beatsInSegment:Float = nextChangeTime / curCrochet;

					if (beatsInSegment >= beatsRemaining) // bpm change after this measure (?)
					{
						beatTime += beatsRemaining * curCrochet;
						beatsRemaining = 0;
					}
					else // bpm change inside of the measure
					{
						beatTime += nextChangeTime;
						beatsRemaining -= beatsInSegment;

						curChange = nextChange;
						changeIndex++;
					}
				}
			}

			var measureEndTime:Float = beatTime;

			var measureNotes:Array<BasicNote> = [];
			var measureEvents:Array<BasicEvent> = [];
			var measureBpmChanges:Array<BasicBPMChange> = [];

			// Add notes to the current measure
			while (noteIndex < notes.length && (notes[noteIndex].time + 1) < roundFloat(measureEndTime))
				measureNotes.push(notes[noteIndex++]);

			// Add events to the current measure
			while (eventIndex < events.length && (events[eventIndex].time + 1) < roundFloat(measureEndTime))
				measureEvents.push(events[eventIndex++]);

			var measure:BasicMeasure = {
				notes: measureNotes,
				events: measureEvents,
				bpmChanges: measureBpmChanges,
				bpm: lastChange.bpm,
				beatsPerMeasure: lastChange.beatsPerMeasure,
				stepsPerBeat: lastChange.stepsPerBeat,
				startTime: measureStartTime,
				endTime: measureEndTime,
				length: measureEndTime - measureStartTime,
				snap: 0
			};

			// Calculate snap and push measure
			measure.snap = findMeasureSnap(measure, snaps);
			measures.push(measure);

			// Advance time to the next measure
			curTime = measureEndTime;

			// Run through all bpm changes that happened in the measure
			while (bpmIndex < bpmChanges.length && roundFloat(bpmChanges[bpmIndex].time) < roundFloat(measureEndTime))
			{
				lastChange = bpmChanges[bpmIndex++];
				measureBpmChanges.push(lastChange);
				measure.bpm = lastChange.bpm;
			}
		}

		return measures;
	}

	public static function getBeatAtTime(time:Float, bpmChanges:Array<BasicBPMChange>):Float
	{
		if (bpmChanges.length <= 0.0 || time <= 0.0)
			return 0.0;

		var beat:Float = 0.0;
		var lastTime:Float = bpmChanges[0].time;
		var lastBpm:Float = bpmChanges[0].bpm;

		for (i in 1...bpmChanges.length)
		{
			final change = bpmChanges[i];
			if (time < change.time)
				break;

			beat += ((change.time - lastTime) * lastBpm) / (60 * 1000);
			lastTime = change.time;
			lastBpm = change.bpm;
		}

		final duration:Float = time - lastTime;
		if (duration > 0)
			beat += (duration * lastBpm) / (60 * 1000);

		return beat;
	}

	public static inline function roundFloat(value:Float, accuracy:Int = 3):Float
	{
		return Math.round(value * Math.pow(10, 3)) / Math.pow(10, 3);
	}

	public static final snaps:Array<Int> = [4, 8, 12, 16, 24, 32, 48, 64, 192];

	public static function getSnapBeat(snap:Int):Float
	{
		return switch (snap)
		{
			case 4: 1;
			case 8: 1 / 2;
			case 12: 1 / 3;
			case 16: 1 / 4;
			case 24: 1 / 6;
			case 32: 1 / 8;
			case 48: 1 / 12;
			case 64: 1 / 16;
			default: 1 / 48; // 192
		}
	}

	public static inline function snapTime(time:Float, startTime:Float, duration:Float, snap:Int):Int
	{
		return Math.round((time - startTime) / duration * snap);
	}

	public static inline function snapTimeMeasure(time:Float, measure:BasicMeasure, snap:Int):Int
	{
		return snapTime(time, measure.startTime, measure.length, snap);
	}

	public static function findMeasureSnap(measure:BasicMeasure, ?allowedSnaps:Array<Int>):Int
	{
		final measureDuration:Float = measure.length;
		final measureTime:Float = measure.startTime;
		// final measureEnd:Float = measure.endTime;

		var snaps = allowedSnaps ?? Timing.snaps;
		var curSnap:Int = snaps[0];
		var maxSnap:Float = Math.POSITIVE_INFINITY;

		for (snap in snaps)
		{
			var snapScore:Float = 0;

			for (note in measure.notes)
			{
				// Calculate note snap
				var noteTime = Math.min(note.time - measureTime, measureDuration);
				var aproxPos = (noteTime / measureDuration) * snap;
				var snapPos = Math.round(aproxPos);
				snapScore += Math.abs(snapPos - aproxPos);

				// Calculate hold snap too
				if (note.length > 0)
				{
					var holdTime = (note.time + note.length) - measureTime;
					if (holdTime <= measureDuration)
					{
						var aproxPos = (holdTime / measureDuration) * snap;
						var snapPos = Math.round(aproxPos);
						snapScore += Math.abs(snapPos - aproxPos);
					}
				}
			}

			if (snapScore < maxSnap)
			{
				maxSnap = snapScore;
				curSnap = snap;
			}
		}

		return curSnap;
	}
}
