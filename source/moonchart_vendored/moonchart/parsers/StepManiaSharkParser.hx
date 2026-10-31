package moonchart.parsers;

import moonchart.parsers.StepManiaParser;

using StringTools;

typedef SSCDelay =
{
	beat:Float,
	secs_duration:Float
}

typedef SSCWarp =
{
	beat:Float, // stored as row in the format. Stored as beat here for simplicity
	beat_duration:Float // stored as row in the format. Stored as beat here for simplicity
}

typedef SSCLabel =
{
	beat:Float, // Stored as row in the format. Stored as beat here for simplicity
	label:String
}

typedef SSCFormat = StepManiaFormat &
{
	DELAYS:Array<SSCDelay>,
	WARPS:Array<SSCWarp>,
	LABELS:Array<SSCLabel>
}

/**
 * @author Nebula_Zorua
 * For the SSC format aka Spinal Shark Collective format
 * The new (SM5+) format
 */
class StepManiaSharkParser extends BasicStepManiaParser<SSCFormat>
{
	override function getEmpty():SSCFormat
	{
		return {
			TITLE: Moonchart.DEFAULT_TITLE,
			ARTIST: Moonchart.DEFAULT_ARTIST,
			MUSIC: "",
			OFFSET: 0,
			BPMS: [],
			STOPS: [],
			DELAYS: [],
			WARPS: [],
			LABELS: [],
			NOTES: []
		}
	}

	override function stringifyNotes(sm:StringBuf, notes:StepManiaNotes):Void
	{
		var header:String = "#NOTEDATA:;\n";
		header += "#STEPSTYPE:" + notes.dance + ";\n";
		header += "#DESCRIPTION:" + notes.desc + ";\n";
		header += "#DIFFICULTY:" + notes.diff + ";\n";
		header += "#METER:" + notes.meter + ";\n";
		header += "#RADARVALUES:" + notes.radar.join(",") + ";\n";
		header += "#NOTES:\n";

		sm.add(header);
		stringifyMeasures(sm, notes.notes);
	}

	override function parseMap(title:String, value:String, formatted:SSCFormat, currentMapData:StepManiaNotes):Void
	{
		switch (title)
		{
			case 'DIFFICULTY':
				currentMapData.diff = value;
			case 'STEPSTYPE':
				currentMapData.dance = value;
			case 'DESCRIPTION':
				currentMapData.desc = value;
			case 'METER':
				currentMapData.meter = Std.parseInt(value);
			case 'RADARVALUES':
				currentMapData.radar = value.split(",").map(Std.parseFloat);
			case 'NOTES' | 'NOTES2':
				parseState = SONG_INFO;
				readNoteData(currentMapData, value); // Load in note data!!
				formatted.NOTES.set(currentMapData.diff, currentMapData);
			default:
				// TODO: Store chart-based warps, stops, etc!!
		}
	}

	override function parseSong(title:String, value:String, formatted:SSCFormat, currentMapData:StepManiaNotes):Void
	{
		switch (title)
		{
			case 'NOTEDATA': // No longer reading song data! Start reading map data!!
				parseState = MAP_INFO;
				currentMapData = getDefaultMap();
			case 'WARPS':
				var data = value.split(",");
				for (warp_data in data)
				{
					var workable_data:Array<String> = warp_data.trim().replace("\n", "").split("="); // beat=duration
					if (workable_data.length == 0)
						continue;
					formatted.WARPS.push({
						beat: Std.parseFloat(workable_data[0]),
						beat_duration: Std.parseFloat(workable_data[1])
					});
				}
			case 'DELAYS':
				var data = value.split(",");
				for (delay_data in data)
				{
					var workable_data:Array<String> = delay_data.trim().replace("\n", "").split("="); // beat=duration
					if (workable_data.length == 0)
						continue;
					formatted.DELAYS.push({
						beat: Std.parseFloat(workable_data[0]),
						secs_duration: Std.parseFloat(workable_data[1])
					});
				}
			case 'LABELS':
				var data = value.split(",");
				for (label_data in data)
				{
					var workable_data:Array<String> = label_data.trim().replace("\n", "").split("="); // beat=label
					if (workable_data.length == 0)
						continue;
					formatted.LABELS.push({
						beat: Std.parseFloat(workable_data[0]),
						label: workable_data[1]
					});
				}
			default:
				super.parseSong(title, value, formatted, currentMapData);
		}
	}
}
