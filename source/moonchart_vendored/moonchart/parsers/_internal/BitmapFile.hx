package moonchart.parsers._internal;

import moonchart.backend.Util;
import haxe.io.Bytes;

typedef BitmapData = #if openfl openfl.display.BitmapData; #elseif heaps hxd.BitmapData; #else Dynamic; #end

class BitmapFile
{
	public var width:Int;
	public var height:Int;
	public var data:BitmapData;

	public function new() {}

	// Dynamic function if you wanna customize bitmap loading
	public static dynamic function fromFile(path:String):BitmapFile
	{
		var bmd = new BitmapFile();

		#if openfl
		bmd.data = #if sys BitmapData.fromFile(path); #else openfl.utils.Assets.getBitmapData(path); #end
		bmd.width = bmd.data.width;
		bmd.height = bmd.data.height;
		#elseif heaps
		bmd.data = hxd.Res.load(path).toImage().toBitmap();
		bmd.width = bmd.data.width;
		bmd.height = bmd.data.height;
		#else
		bmd.width = 0;
		bmd.height = 0;
		#end

		return bmd;
	}

	public function make(width:Int, height:Int, color:Int):BitmapFile
	{
		this.width = width;
		this.height = height;

		#if openfl
		data = new BitmapData(width, height, false, color);
		#elseif heaps
		data = new BitmapData(width, height);
		data.fill(0, 0, width, height, color);
		#end

		return this;
	}

	public function savePNG(path:String):Void
	{
		var bytes:Null<Bytes> = null;

		#if openfl
		var byteArray = new openfl.utils.ByteArray();
		data.encode(new openfl.geom.Rectangle(0, 0, width, height), new openfl.display.PNGEncoderOptions(), byteArray);
		bytes = byteArray;
		#elseif heaps
		bytes = data.toPNG();
		#end

		if (bytes != null)
			Util.saveBytes(path, bytes);
	}

	public function setPixel(x:Int, y:Int, color:Int):Void
	{
		#if openfl
		data.setPixel32(x, y, color);
		#elseif heaps
		data.setPixel(x, y, color);
		#end
	}

	public function getPixel(x:Int, y:Int):Int
	{
		#if openfl
		return data.getPixel(x, y);
		#elseif heaps
		return data.getPixel(x, y);
		#else
		return 0;
		#end
	}

	public function toCSV():String
	{
		var buf:StringBuf = new StringBuf();

		for (row in 0...height)
		{
			for (column in 0...width)
			{
				final pixel:String = Std.string(getPixel(column, row));
				buf.add((column == 0) ? ((row == 0) ? pixel : '\n$pixel') : ', $pixel');
			}
		}

		return buf.toString();
	}
}
