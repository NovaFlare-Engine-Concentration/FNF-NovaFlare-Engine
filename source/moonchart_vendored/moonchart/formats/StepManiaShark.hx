package moonchart.formats;

import moonchart.backend.FormatData;
import moonchart.backend.Util;
import moonchart.backend.Timing;
import moonchart.formats.BasicFormat;
import moonchart.parsers.StepManiaSharkParser;
import moonchart.formats.StepMania.StepManiaBasic;

// Extension of StepMania
class StepManiaShark extends StepManiaBasic<SSCFormat>
{
	// Format description by burgerballs
	public static function __getFormat():FormatData
	{
		return {
			ID: STEPMANIA_SHARK,
			name: "StepManiaShark",
			description: 'The format used for Stepmania 5, previously known as "StepMania Spinal Shark Collective".',
			extension: "ssc",
			hasMetaFile: FALSE,
			handler: StepManiaShark
		}
	}

	public function new(?data:SSCFormat)
	{
		super(data);
		this.data = data;
		parser = new StepManiaSharkParser();
	}

	// Mark labels as events cus that makes it usable for shit like FNF
	override function getEvents():Array<BasicEvent>
	{
		var events = super.getEvents();
		var bpmChanges = getChartMeta().bpmChanges;
		var labels = data.LABELS;

		if (labels.length <= 0)
			return events;

		var l:Int = 0;
		var lastTime:Float = 0;
		var lastBeat:Float = 0;
		var crochet:Float = Timing.crochet(bpmChanges[0].bpm);
		var _data:Dynamic = {}; // Reuse empty dynamic instances

		// Add labels between bpm changes
		for (i in 1...bpmChanges.length)
		{
			final change = bpmChanges[i];
			var elapsedTime:Float = change.time - lastTime;
			var curBeat = lastBeat + (elapsedTime * crochet);

			while (l < labels.length && labels[l].beat <= curBeat)
			{
				final label = labels[l++];
				events.push({
					time: change.time + ((label.beat - curBeat) * crochet),
					name: label.label,
					data: _data
				});
			}

			crochet = Timing.crochet(change.bpm);
			lastTime = change.time;
			lastBeat = curBeat;
		}

		// Add any left over labels
		while (l < labels.length)
		{
			var label = labels[l++];
			events.push({
				time: lastTime + ((label.beat - lastBeat) * crochet),
				name: label.label,
				data: _data
			});
		}

		Timing.sortEvents(events);

		return events;
	}

	override public function fromFile(path:String, ?meta:String, ?diff:FormatDifficulty):StepManiaShark
	{
		return fromStepManiaShark(Util.getText(path), diff);
	}

	public function fromStepManiaShark(data:String, ?diff:FormatDifficulty):StepManiaShark
	{
		this.data = parser.parse(data);
		this.diffs = diff ?? Util.mapKeyArray(this.data.NOTES);
		return this;
	}
}
