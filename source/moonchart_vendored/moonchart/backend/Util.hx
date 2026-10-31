package moonchart.backend;

import haxe.io.Bytes;
import haxe.io.Path;
import moonchart.formats.BasicFormat.BasicEvent;

using StringTools;

#if sys
import sys.FileSystem;
import sys.io.File;
#end
#if openfl
import openfl.utils.Assets;
#end
#if cpp
import cpp.NativeArray;
#end

/**
 * Main util class most Moonchart formats should use.
 * 
 * All file reading functions Moonchart uses are stored here as ``dynamic`` functions.
 * This way they can be changed at any time with your own file reading implementation.
 */
class Util
{
	/**
	 * The current moonchart library version
	 */
	public static inline var version:String = "Moonchart 0.5.1";

	/**
	 * Returns a list of files from a folder
	 */
	public static dynamic function readFolder(path:String):Array<String>
	{
		#if sys
		return FileSystem.readDirectory(path);
		#else
		return [];
		#end
	}

	public static dynamic function fileExists(path:String):Bool
	{
		#if sys
		return FileSystem.exists(path);
		#elseif openfl
		return Assets.exists(path);
		#else
		return false;
		#end
	}

	/**
	 * Returns if a given path is a folder or not
	 */
	public static dynamic function isFolder(path:String):Bool
	{
		#if sys
		return FileSystem.isDirectory(path);
		#else
		return false;
		#end
	}

	/**
	 * Saves bytes to a file path
	 */
	public static dynamic function saveBytes(path:String, bytes:Bytes):Void
	{
		#if sys
		File.saveBytes(path, bytes);
		#end
	}

	/**
	 * Saves text to a file path
	 */
	public static dynamic function saveText(path:String, text:String):Void
	{
		#if sys
		File.saveContent(path, text);
		#end
	}

	/**
	 * Gets bytes from a file path
	 */
	public static dynamic function getBytes(path:String):Bytes
	{
		#if sys
		return File.getBytes(path);
		#elseif openfl
		return Assets.getBytes(path);
		#else
		return null;
		#end
	}

	/**
	 * Gets text from a file path
	 */
	public static dynamic function getText(path:String):String
	{
		#if sys
		return File.getContent(path);
		#elseif openfl
		return Assets.getText(path);
		#else
		return "";
		#end
	}

	/**
	 * Sanitizes a directory path string
	 */
	public static function resolveFolder(path:String):String
	{
		path = path.trim();

		if (path.endsWith("/"))
			path = path.substr(0, path.length - 1);

		return path;
	}

	/**
	 * Adds an extension to a directory path, if it's not there yet
	 */
	public static function resolveExtension(?path:String, extension:String):Null<String>
	{
		if (path == null)
			return path;

		var ext = '.$extension';
		if (Path.extension(path).length <= 0)
			path += ext;

		return path;
	}

	/**
	 * Adds an extra folder to a directory path
	 */
	public static function extendPath(?path:String, ?extension:String):Null<String>
	{
		if (path == null)
			return path;

		if (!path.endsWith("/"))
			path += "/";

		if (extension != null)
			path += extension;

		return path;
	}

	/**
	 * Like ``Math.min`` but int casted
	 */
	public static inline function minInt(a:Int, b:Int):Int
	{
		return Std.int(Math.min(a, b));
	}

	/**
	 * Like ``Math.max`` but int casted
	 */
	public static inline function maxInt(a:Int, b:Int):Int
	{
		return Std.int(Math.max(a, b));
	}

	/**
	 * Sorts the order of items from an array based on the items of another array
	 */
	public static function customSort(array:Array<String>, sort:Array<String>)
	{
		var result:Array<String> = [];

		// Add items based on sort
		for (i in sort)
		{
			if (array.contains(i))
			{
				result.push(i);
				array.remove(i);
			}
		}

		// Add any missed items not included in the sort
		for (i in array)
			result.push(i);

		return result;
	}

	/**
	 * String array alphabetical sorting
	 */
	public static inline function sortString(a:String, b:String, isAscending:Bool = true):Int
	{
		final order:Int = (isAscending ? -1 : 1);
		var result:Int = 0;

		a = a.toUpperCase();
		b = b.toUpperCase();

		if (a < b)
		{
			result = order;
		}
		else if (a > b)
		{
			result = -order;
		}

		return result;
	}

	/**
	 * Float array sorting
	 */
	public static inline function sortValues(a:Float, b:Float, isAscending:Bool = true):Int
	{
		final order:Int = (isAscending ? -1 : 1);
		var result:Int = 0;

		if (a < b)
		{
			result = order;
		}
		else if (a > b)
		{
			result = -order;
		}

		return result;
	}

	/**
	 * Creates an array-based moonchart basic event
	 */
	public static function makeArrayEvent(time:Float, name:String, array:Array<Dynamic>):BasicEvent
	{
		return {
			time: time,
			name: name,
			data: {
				array: array
			}
		}
	}

	/**
	 * Returns the values from a moonchart basic array as an array
	 * Keeps values order where possible
	 */
	public static function resolveEventValues(event:BasicEvent):Array<Dynamic>
	{
		var values:Array<Dynamic>;

		if (Type.typeof(event.data) == TObject)
		{
			if (event.data.VALUE_1 != null) // FNF (Psych Engine)
			{
				values = [event.data.VALUE_1, event.data.VALUE_2];
			}
			else if (event.data.array != null)
			{
				values = event.data.array.copy();
			}
			else
			{
				var fields:Array<String> = Reflect.fields(event.data);
				values = [];

				if (fields.length > 0)
				{
					fields.sort((a, b) -> return Util.sortString(a, b));

					for (field in fields)
						values.push(Reflect.field(event.data, field));
				}
			}
		}
		else
		{
			values = [event.data]; // FNF (V-Slice)
		}
		return values;
	}

	/**
	 * Resizes the length of an array
	 */
	public static inline function resizeArray<T>(array:Array<T>, size:Int):Void
	{
		#if cpp
		NativeArray.setSize(array, size);
		#else
		array.resize(size);
		#end
	}

	/**
	 * Creates an array with a specific buffered size
	 */
	public static inline function makeArray<T>(size:Int):Array<T>
	{
		#if cpp
		return NativeArray.create(size);
		#else
		var array:Array<T> = [];
		array.resize(size);
		return array;
		#end
	}

	/**
	 * Sets the value of an array at an specific index
	 * Made to take advantage of native arrays on some targets
	 */
	public static inline function setArray<T>(array:Array<T>, index:Int, value:T):Void
	{
		#if cpp
		NativeArray.unsafeSet(array, index, value);
		#else
		array[index] = value;
		#end
	}

	/**
	 * Returns the value of an array at an specific index
	 * Made to take advantage of native arrays on some targets
	 */
	public static inline function getArray<T>(array:Array<T>, index:Int):T
	{
		#if cpp
		return NativeArray.unsafeGet(array, index);
		#else
		return array[index];
		#end
	}

	/**
	 * Creates a map filled with keys all with the same value
	 */
	public static function fillMap<T>(keys:Array<String>, value:T):Map<String, T>
	{
		var map:Map<String, T> = [];
		for (key in keys)
			map.set(key, value);
		return map;
	}

	/**
	 * Returns the keys of a map as an array
	 */
	public static function mapKeyArray<K, T>(map:Map<K, T>):Array<K>
	{
		var array:Array<K> = [];
		for (key in map.keys())
			array.push(key);
		return array;
	}

	/**
	 * Returns the first known value in a map
	 */
	public static function mapFirst<K, T>(map:Map<K, T>):Null<T>
	{
		var iterator = map.iterator();
		return iterator.hasNext() ? iterator.next() : null;
	}

	/**
	 * Returns the first known key in a map
	 */
	public static function mapFirstKey<K, T>(map:Map<K, T>):Null<K>
	{
		var iterator = map.keys();
		return iterator.hasNext() ? iterator.next() : null;
	}

	/**
	 * Safely check if 2 floats are equal with 2 decimal accuracy
	 */
	public static function equalFloat(a:Float, b:Float):Bool
	{
		return (Std.int(a * 100) == Std.int(b * 100));
	}
}

typedef StringInput = OneOfArray<String>;
typedef ChartSave = OneOfTwo<String, Bytes>;
abstract OneOfTwo<T1, T2>(Dynamic) from T1 from T2 to T1 to T2 {}

/**
 * Used as a wrapper to be able to use map-type values in a json
 */
abstract JsonMap<T>(Dynamic) from Dynamic to Dynamic
{
	public function resolve():Map<String, T>
	{
		var map = new Map<String, T>();
		for (key in keys())
			map.set(key, get(key));

		return map;
	}

	public function fromMap(?map:Map<String, T>):JsonMap<T>
	{
		if (map != null)
		{
			for (key => value in map)
				set(key, value);
		}

		return this;
	}

	public inline function keys():Array<String>
	{
		return Reflect.fields(this);
	}

	public inline function get(key:String):T
	{
		return Reflect.field(this, key);
	}

	public inline function set(key:String, value:T):Void
	{
		Reflect.setField(this, key, value);
	}
}

abstract OneOfArray<T>(Dynamic) from T from Array<T> to T to Array<T>
{
	public inline function resolve():Array<T>
	{
		return ((this is Array) ? this : [this]);
	}

	public static inline function nullResolve<T>(input:Null<OneOfArray<T>>, fallback:T):T
	{
		if (input == null)
			return fallback;

		return input.resolve()[0] ?? fallback;
	}
}
