package moonchart.parsers._internal;

import moonchart.backend.Util;

using StringTools;

typedef MSDValues = Array<Array<String>>;

/**
 * @author Nebula_Zorua
 * Based on the MSD parser found in Stepmania.
 * Could probably be rewritten to take advantage of Haxe systems and reduce complexity
 * but I want as accurate as possible reading
 */
class MSDFile
{
	public var values:MSDValues = [];

	public function new(fileContents:String)
	{
		parseContents(fileContents);
	}

	public function parseContents(content:String)
	{
		var currentlyReadingValue:Bool = false;
		var currentValue:StringBuf = new StringBuf();

		// Strip comments
		final regex = ~/(\/\/).+/;
		var strippedContent = content.split("\n").map((line) -> return regex.replace(line, "").rtrim()).join("\n");

		var data:Array<String> = strippedContent.split(""); // all of the characters in the file
		var len:Int = data.length;
		var idx = 0;

		while (idx < len)
		{
			final char = data[idx].fastCodeAt(0);

			if (currentlyReadingValue)
			{
				if (char == '#'.code)
				{
					// Malformed MSD file that forgot to include a ; to end the last param
					// We can check if this is the first char on a new line, and if it IS then we can just end the value where it was.

					var jdx = currentValue.length - 1;
					var valueData:Array<String> = currentValue.toString().split("");
					var isFirst:Bool = true;

					while (jdx > 0 && valueData[jdx] != '\r' && valueData[jdx] != '\n')
					{
						if (valueData[jdx].isSpace(0))
						{
							jdx--;
							continue;
						}
						isFirst = false;
						break;
					}

					// Not the first char on a new line so we just continue
					if (!isFirst)
					{
						currentValue.addChar(char);
						idx++;
						continue;
					}

					// this WAS the first char, so push the param
					values[values.length - 1].push(currentValue.toString().trim());
					currentValue = new StringBuf();
					currentlyReadingValue = false;
				}
			}

			if (!currentlyReadingValue && char == '#'.code)
			{
				values.push([]); // New params!!
				currentlyReadingValue = true;
			}

			// Move the index into the file up by 1
			if (!currentlyReadingValue)
			{
				if (char == '\\'.code)
					idx += 2;
				else
					idx++;

				continue; // And end since no value is being read. Doesn't FUCKIN MATTER WHATS HERE!!
			}

			if (char == ':'.code || char == ';'.code)
			{
				values[values.length - 1].push(currentValue.toString());
				currentValue = new StringBuf();
			}

			if (char == '#'.code || char == ':'.code || char == ';'.code)
			{
				if (char == ';'.code)
					currentlyReadingValue = false;
				idx++;
				continue;
			}

			if (idx < len && data[idx] == '\\')
				idx++;

			if (idx < len)
			{
				currentValue.add(data[idx]);
				idx++;
			}
		}

		if (currentlyReadingValue)
			values[values.length - 1].push(currentValue.toString());
	}

	public static function msdValue(value:Dynamic, buf:StringBuf):Void
	{
		if (value is Array)
		{
			var array:Array<Dynamic> = value;
			final l = array.length;

			for (i in 0...l)
			{
				buf.add(msdBasic(Util.getArray(array, i)));
				buf.addChar("\n".code);
				if (i < l - 1)
					buf.addChar(",".code);
			}

			return;
		}

		buf.add(msdBasic(value));
	}

	public static function msdBasic(value:Dynamic):String
	{
		// BPM Changes, some nice and sloppy unsafe code here for ya
		if (Reflect.hasField(value, "beat"))
		{
			return msdBasic(Reflect.field(value, "beat")) + "=" + msdBasic(Reflect.field(value, "bpm"));
		}

		if (value is Float || value is Int)
		{
			var num:Int = Std.int(value);
			var decimals:String = Std.string(Std.int((value - num) * 1000));
			while (decimals.length < 3)
				decimals += "0";

			return num + "." + decimals;
		}

		return Std.string(value);
	}
}
