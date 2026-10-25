package moonchart.parsers;

import haxe.io.Bytes;
import moonchart.backend.Util;

using StringTools;

@:keep
@:private
abstract class BasicParser<T>
{
	public function new() {}

	// For visual formats (json, yaml...)
	public function stringify(data:T):String
	{
		throw "stringify needs to be implemented in this parser!";
		return null;
	}

	// For binary formats (midi...)
	public function encode(data:T):Bytes
	{
		throw "encode needs to be implemented in this parser!";
		return null;
	}

	public function parse(string:String):T
	{
		throw "parse needs to be implemented in this parser!";
		return null;
	}

	function sortedFields(input:Dynamic, sort:Array<String>):Array<String>
	{
		return Util.customSort(Reflect.fields(input), sort);
	}

	static final numRegex = ~/^[-+]?[0-9]*\.?[0-9]+$/;

	function resolveBasic(s:String):Dynamic
	{
		// Is a number
		if (numRegex.match(s.trim()))
		{
			return Std.parseFloat(s);
		}

		// Is a boolean
		if(s == "true")
			return true;
		else if(s == "false")
			return false;

		// Is a string
		return s;
	}

	function splitLines(string:String):Array<String>
	{
		final arr:Array<String> = [];
		final split = string.split("\n");

		final l = split.length;
		var i = 0;

		while (i < l)
		{
			var line = split[i];
			i++;

			// BOM fix
			if (line.fastCodeAt(0) == 0xFEFF)
				line = line.substr(1);

			if (line.trim().length > 0)
				arr.push(line.rtrim());
		}

		return arr;
	}
}
