package moonchart.parsers;

import moonchart.parsers.BasicParser;

using StringTools;

typedef GuitarHeroTimedObject =
{
	tick:Int,
	type:GuitarHeroTrackEvent,
	values:Array<Dynamic>
}

typedef GuitarHeroFormat =
{
	?Song:GuitarHeroSong,
	?SyncTrack:Array<GuitarHeroTimedObject>,
	?Events:Array<GuitarHeroTimedObject>,
	?Notes:Map<String, Array<GuitarHeroTimedObject>>
}

typedef GuitarHeroSong =
{
	Name:String,
	Artist:String,
	Charter:String,
	Album:String,
	Resolution:Int,
	Offset:Float
}

enum abstract GuitarHeroTrackEvent(String) from String to String
{
	var TEMPO_ANCHOR = "A";
	var TEMPO_CHANGE = "B";
	var TEXT_EVENT = "E";
	var LEGACY_HAND = "H";
	var NOTE_EVENT = "N";
	var SPECIAL_PHRASE = "S";
	var TIME_SIGNATURE_CHANGE = "TS";
}

class GuitarHeroParser extends BasicParser<GuitarHeroFormat>
{
	public override function stringify(inputData:GuitarHeroFormat):String
	{
		var result:StringBuf = new StringBuf();

		var data:Dynamic = {
			Song: inputData.Song,
			SyncTrack: inputData.SyncTrack,
			Events: inputData.Events
		}

		for (diff => notes in inputData.Notes)
		{
			var header = diff.charAt(0).toUpperCase() + diff.substr(1) + "Single";
			Reflect.setField(data, header, notes);
		}

		var headers = sortedFields(data, [
			"Song",
			"SyncTrack",
			"Events",
			"EasySingle",
			"MediumSingle",
			"HardSingle",
			"ExpertSingle"
		]);

		for (header in headers)
		{
			var headerData = Reflect.field(data, header);
			result.add('[$header]\n{\n');

			if (headerData is Array)
			{
				var array:Array<GuitarHeroTimedObject> = cast headerData;
				for (i in array)
				{
					var tick = i.tick;
					var type = i.type;
					var values = i.values.join(" ");

					result.add('\t$tick = $type $values\n');
				}
			}
			else
			{
				for (field in Reflect.fields(headerData))
				{
					var fieldData = Reflect.field(headerData, field);
					result.add('\t$field = ' + ghField(fieldData) + '\n');
				}
			}

			result.add('}\n');
		}

		return result.toString();
	}

	function ghField(field:Dynamic):String
	{
		var str = Std.string(field);
		if (field is String)
		{
			str = '"$str"';
		}
		return str;
	}

	public override function parse(string:String):GuitarHeroFormat
	{
		var lines = splitLines(string);

		var data:GuitarHeroFormat = {
			Notes: []
		}

		var headers:Map<String, Array<String>> = [];

		var i:Int = 0;
		final l:Int = lines.length;

		while (i < l)
		{
			var line = lines[i++].trim();

			if (line.startsWith("["))
			{
				var header:String = line.substring(1, line.length - 1);
				var headerLines:Array<String> = [];
				headers.set(header, headerLines);

				i++;
				while (true)
				{
					line = lines[i++].trim();
					if (line.startsWith("}"))
						break;

					headerLines.push(line);
				}
			}
		}

		// Push crap
		for (header => lines in headers)
		{
			if (header.contains("Single"))
			{
				var diff = header.substring(0, header.length - 6).toLowerCase();
				data.Notes.set(diff, resolveTrackEventsGH(header, lines));
			}
			else
			{
				Reflect.setField(data, header, switch (header)
				{
					case "Song": resolveValuesGH(header, lines);
					default: resolveTrackEventsGH(header, lines);
				});
			}
		}

		return data;
	}

	function resolveTrackEventsGH(field:String, lines:Array<String>):Array<GuitarHeroTimedObject>
	{
		var timedObjects:Array<GuitarHeroTimedObject> = [];
		var typeIndex:Int;

		for (line in lines)
		{
			var values = line.split("=");
			var typeData = values[1].ltrim().split(" ");
			typeIndex = 0;

			var tick:Int = Std.parseInt(values[0]);
			var type:String = typeData[typeIndex++];
			var other:Array<Dynamic> = [];

			while (typeIndex < typeData.length)
				other.push(resolveBasic(typeData[typeIndex++]));

			timedObjects.push({
				tick: tick,
				type: type,
				values: other
			});
		}

		return timedObjects;
	}

	function resolveValuesGH(field:String, lines:Array<String>):Dynamic
	{
		var gh:Dynamic = {};
		for (line in lines)
		{
			var values = line.split("=");
			var field = values[0].rtrim();
			var value = values[1].replace('"', '');
			Reflect.setField(gh, field, resolveBasic(value));
		}
		return gh;
	}
}
