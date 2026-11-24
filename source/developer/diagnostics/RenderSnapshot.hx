package developer.diagnostics;

#if (windows && cpp && lime && novaflare_render_snapshot)
import flixel.util.FlxTimer;
import haxe.io.Bytes;
import haxe.io.Path;
import lime.utils.UInt8Array;
import openfl.display.Stage;
import sys.FileSystem;
import sys.io.File;

@:access(openfl.display3D.Context3D)
class RenderSnapshot
{
	public static function schedule(stage:Stage):Void
	{
		if (Sys.getEnv('NOVAFLARE_RENDER_SNAPSHOT') != '1' || !Sys.args().contains('--cne-isolated-storage')) return;
		var directory = Sys.getEnv('NOVAFLARE_DIAGNOSTIC_DIR');
		if (directory == null || !Path.isAbsolute(directory) || !FileSystem.isDirectory(directory)) return;
		var path = Path.join([directory, 'render-snapshot.ppm']);
		if (FileSystem.exists(path)) return;
		new FlxTimer().start(8, _ -> @:privateAccess stage.__novaRenderSnapshot = () -> capture(stage, path));
	}

	static function capture(stage:Stage, path:String):Void
	{
		try
		{
			var context = stage.context3D;
			if (context == null || context.gl == null) return;
			var width = Math.round(stage.window.width * stage.window.scale);
			var height = Math.round(stage.window.height * stage.window.scale);
			if (width <= 0 || height <= 0) return;

			context.setRenderToBackBuffer();
			context.__flushGLFramebuffer();
			var gl = context.gl;
			var pixels = new UInt8Array(width * height * 4);
			gl.readPixels(0, 0, width, height, gl.RGBA, gl.UNSIGNED_BYTE, pixels);
			var nonBlackPixels = savePortablePixmap(path, pixels.toBytes(), width, height);
			if (nonBlackPixels == 0) throw new haxe.Exception('The captured framebuffer was black');
			Sys.println('diagnostic:render_snapshot width=$width height=$height non_black_pixels=$nonBlackPixels path=$path');
		}
		catch (error:haxe.Exception)
		{
			Sys.println('diagnostic:render_snapshot error=${error.message}');
		}
	}

	static function savePortablePixmap(path:String, rgba:Bytes, width:Int, height:Int):Int
	{
		var header = Bytes.ofString('P6\n$width $height\n255\n');
		var output = Bytes.alloc(header.length + width * height * 3);
		output.blit(0, header, 0, header.length);
		var nonBlackPixels = 0;
		for (row in 0...height)
		{
			var readOffset = (height - 1 - row) * width * 4;
			var writeOffset = header.length + row * width * 3;
			for (column in 0...width)
			{
				var red = rgba.get(readOffset);
				var green = rgba.get(readOffset + 1);
				var blue = rgba.get(readOffset + 2);
				if ((red | green | blue) != 0) nonBlackPixels++;
				output.set(writeOffset, red);
				output.set(writeOffset + 1, green);
				output.set(writeOffset + 2, blue);
				readOffset += 4;
				writeOffset += 3;
			}
		}
		File.saveBytes(path, output);
		return nonBlackPixels;
	}
}
#end
