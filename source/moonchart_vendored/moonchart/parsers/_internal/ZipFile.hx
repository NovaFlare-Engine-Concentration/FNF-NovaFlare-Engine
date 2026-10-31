package moonchart.parsers._internal;

import haxe.io.Bytes;
import moonchart.backend.Util;
import haxe.ds.List;
import haxe.zip.*;

class ZipFile
{
	var entries:List<Entry>;

	public function new() {}

	public function openFile(path:String):ZipFile
	{
		#if sys
		var input = sys.io.File.read(path);
		entries = Reader.readZip(input);
		input.close();
		#else
		entries = new List<Entry>();
		#end

		return this;
	}

	public function filesList():Array<String>
	{
		var files:Array<String> = [];

		for (entry in entries)
		{
			files.push(entry.fileName);
		}

		return files;
	}

	public function filterEntries(filter:Entry->Bool):Array<Entry>
	{
		var filteredEntries:Array<Entry> = [];

		for (entry in entries)
		{
			if (filter(entry))
				filteredEntries.push(entry);
		}

		return filteredEntries;
	}

	public inline function unzipEntries(?input:List<Entry>):Map<String, Bytes>
	{
		var map:Map<String, Bytes> = [];
		input ??= this.entries;

		for (entry in input)
			map.set(entry.fileName, unzipEntry(entry));

		return map;
	}

	public inline function unzipString(entry:Entry):String
	{
		return unzipEntry(entry).toString();
	}

	public inline function unzipEntry(entry:Entry):Bytes
	{
		return Reader.unzip(entry);
	}
}
