package general.backend;

import lime.graphics.Image;
import lime.graphics.ImageBuffer;
import lime.app.Future;
import lime.utils.UInt8Array;
import openfl.display.BitmapData;

#if (cpp && sys && lime_cffi && !disable_cffi)
import haxe.io.Bytes;
import lime.system.CFFI;
#end

#if ((cpp && sys && lime_cffi && !disable_cffi) || novaflare_image_live_test)
import sys.thread.Tls;
#end

#if (cpp || novaflare_image_live_test)
import sys.thread.Mutex;

private typedef DecodedImageSource = {
	final width:Int;
	final height:Int;
	final reopen:Void->Image;
}
#end

private typedef ImageCompressionSettings = {
	final maximum:Int;
	final threshold:Int;
	final ratio:Float;
}

#if (cpp && sys && lime_cffi && !disable_cffi)
private typedef ScaledDecode = {
	final buffer:ImageBuffer;
	final sourceWidth:Int;
	final sourceHeight:Int;
}
#end

class ImageCompression
{
	public static var deviceLimit(default, null):Int = 0;
	static var settings:ImageCompressionSettings = {maximum: 0, threshold: 0, ratio: 1};
	static var preferenceTimer:haxe.Timer;

	#if ((cpp && sys && lime_cffi && !disable_cffi) || novaflare_image_live_test)
	static final allowScaledDecode = new Tls<Bool>();
	#end
	#if (cpp && sys && lime_cffi && !disable_cffi)
	static var nativeScaledDecode:(Dynamic, ImageBuffer, ImageCompressionSettings)->ScaledDecode;
	static var lookedUpScaledDecode = false;
	#end

	#if (cpp || novaflare_image_live_test)
	static final sourceMutex = new Mutex();
	static final imageSources = #if cpp new haxe.ds.WeakMap<BitmapData, DecodedImageSource>() #else new haxe.ds.ObjectMap<BitmapData, DecodedImageSource>() #end;
	static var pending:Array<BitmapData> = [];
	static var revision:Int = 0;
	static var processing:Bool = false;
	#end

	public static function configure(hardwareLimit:Int, userLimit:Int, retainedRatio:Float, compressionStart:Int = 0):Bool
	{
		deviceLimit = Std.int(Math.max(0, hardwareLimit));
		var maximum = userLimit > 0 && (deviceLimit <= 0 || userLimit < deviceLimit) ? userLimit : deviceLimit;
		var threshold = Std.int(Math.max(0, deviceLimit > 0 ? Math.min(compressionStart, deviceLimit) : compressionStart));
		var ratio = Math.isFinite(retainedRatio) ? Math.max(0.1, Math.min(1, retainedRatio)) : 1;
		canDecodeScaled();
		if (maximum == settings.maximum && threshold == settings.threshold && ratio == settings.ratio) return false;
		settings = {maximum: maximum, threshold: threshold, ratio: ratio};
		return true;
	}

	@:noCompletion public static function canDecodeScaled():Bool
	{
		#if (cpp && sys && lime_cffi && !disable_cffi)
		if (!lookedUpScaledDecode && CFFI.enabled)
		{
			lookedUpScaledDecode = true;
			try
			{
				nativeScaledDecode = CFFI.load("lime", "lime_image_load_scaled", 3);
			}
			catch (error:haxe.Exception)
			{
				lime.utils.Log.warn('Scaled image decoder unavailable: ${error.message}');
			}
		}
		return nativeScaledDecode != null;
		#else
		return false;
		#end
	}

	public static function refreshPreferences():Void
	{
		#if novaflare_image_compression
		if (preferenceTimer != null) preferenceTimer.stop();
		preferenceTimer = haxe.Timer.delay(() -> {
			preferenceTimer = null;
			var prefs = ClientPrefs.data;
			if (configure(deviceLimit, 0, prefs.imageCompressionRatio, prefs.minImageCompressionSize))
				refreshLoadedImages();
		}, 180);
		#end
	}

	@:noCompletion public static function adopt(bitmap:BitmapData, image:Image):Image
	{
		#if (cpp || novaflare_image_live_test)
		var reopen = image.reopenCompressionSource;
		if (reopen != null && image.buffer != null && image.width > 0 && image.height > 0)
		{
			sourceMutex.acquire();
			imageSources.set(bitmap, {width: sourceWidth(image), height: sourceHeight(image), reopen: reopen});
			sourceMutex.release();
		}
		#end
		return resize(image);
	}

	@:noCompletion public static function trackClone(original:BitmapData, copy:BitmapData):Void
	{
		#if (cpp || novaflare_image_live_test)
		if (!original.canRefreshCompression()) return;
		sourceMutex.acquire();
		var source = imageSources.get(original);
		if (source != null) imageSources.set(copy, source);
		sourceMutex.release();
		#end
	}

	@:noCompletion public static function finishAdopting(bitmap:BitmapData):Void
	{
		#if (cpp || novaflare_image_live_test)
		var width = bitmap.imageSourceWidth > 0 ? bitmap.imageSourceWidth : bitmap.width;
		var height = bitmap.imageSourceHeight > 0 ? bitmap.imageSourceHeight : bitmap.height;
		if (hasTargetSize(bitmap, width, height)) return;
		haxe.MainLoop.runInMainThread(() -> {
			if (!pending.contains(bitmap)) pending.push(bitmap);
			processNext();
		});
		#end
	}

	@:noCompletion public static function refreshLoadedImages():Void
	{
		#if (cpp || novaflare_image_live_test)
		revision++;
		sourceMutex.acquire();
		pending = [for (bitmap in imageSources.keys()) bitmap];
		sourceMutex.release();
		processNext();
		#end
	}

	#if (cpp || novaflare_image_live_test)
	static function processNext():Void
	{
		if (processing) return;
		while (pending.length > 0)
		{
			var bitmap = pending.pop();
			if (!bitmap.canRefreshCompression()) continue;
			sourceMutex.acquire();
			var source = imageSources.get(bitmap);
			sourceMutex.release();
			if (source == null) continue;
			if (hasTargetSize(bitmap, source.width, source.height)) continue;
			refreshBitmap(bitmap, source);
			return;
		}
	}

	static function refreshBitmap(bitmap:BitmapData, source:DecodedImageSource):Void
	{
		var currentRevision = revision;
		processing = true;
		new Future(() -> {
			var image = withScaledDecode(source.reopen);
			return image != null && sourceWidth(image) == source.width && sourceHeight(image) == source.height ? resize(image) : null;
		}, true).onComplete(image -> applyWhenReady(bitmap, image, currentRevision)).onError(_ -> finishRefresh());
	}

	static function applyWhenReady(bitmap:BitmapData, image:Image, expectedRevision:Int):Void
	{
		if (expectedRevision == revision && image != null && bitmap.canRefreshCompression()
			&& (image.width != bitmap.width || image.height != bitmap.height))
		{
			if (bitmap.imageCompressionUploads > 0)
			{
				haxe.Timer.delay(() -> applyWhenReady(bitmap, image, expectedRevision), 32);
				return;
			}
			bitmap.applyRefreshedCompression(image);
		}
		finishRefresh();
	}

	static function finishRefresh():Void
	{
		processing = false;
		processNext();
	}
	#end

	inline static function sourceWidth(image:Image):Int
		return image.imageSourceWidth > 0 ? image.imageSourceWidth : image.width;

	inline static function sourceHeight(image:Image):Int
		return image.imageSourceHeight > 0 ? image.imageSourceHeight : image.height;

	static function scaleFor(width:Int, height:Int):Float
	{
		var policy = settings;
		var longest = Math.max(width, height);
		var scale = longest < policy.threshold ? 1.0 : Math.sqrt(policy.ratio);
		return policy.maximum > 0 ? Math.min(scale, policy.maximum / longest) : scale;
	}

	inline static function scaledSide(size:Int, scale:Float):Int
		return Std.int(Math.max(1, Math.floor(size * scale + 1e-9)));

	static function hasTargetSize(bitmap:BitmapData, width:Int, height:Int):Bool
	{
		var scale = scaleFor(width, height);
		return bitmap.width == scaledSide(width, scale) && bitmap.height == scaledSide(height, scale);
	}

	@:noCompletion public static function hasScaledDecodeScope():Bool
	{
		#if ((cpp && sys && lime_cffi && !disable_cffi) || novaflare_image_live_test)
		return allowScaledDecode.value == true;
		#else
		return false;
		#end
	}

	@:noCompletion public static function withScaledDecode<T>(decode:Void->T, enabled:Bool = true):T
	{
		#if ((cpp && sys && lime_cffi && !disable_cffi) || novaflare_image_live_test)
		var previous = allowScaledDecode.value;
		allowScaledDecode.value = enabled #if (cpp && sys && lime_cffi && !disable_cffi && !novaflare_image_live_test) && nativeScaledDecode != null #end;
		try
		{
			var result = decode();
			allowScaledDecode.value = previous;
			return result;
		}
		catch (error:Dynamic)
		{
			allowScaledDecode.value = previous;
			throw error;
		}
		#else
		return decode();
		#end
	}

	@:noCompletion public static function loadScopedFile(path:String):Future<Image>
	{
		#if ((cpp && sys && lime_cffi && !disable_cffi) || novaflare_image_live_test)
		if (path.indexOf("http://") >= 0 || path.indexOf("https://") >= 0)
		{
			var request = new lime.net.HTTPRequest<haxe.io.Bytes>();
			return request.load(path).then(bytes -> withScaledDecode(() -> Image.loadFromBytes(bytes))).then(image -> {
				return image != null ? Future.withValue(image) : cast Future.withError('Cannot decode image: $path');
			});
		}

		var queryStart = path.indexOf("?");
		var localPath = queryStart < 0 ? path : path.substring(0, queryStart);
		#if !windows
		if (StringTools.startsWith(localPath, "~/"))
			localPath = haxe.io.Path.join([lime.system.System.userDirectory, localPath.substr(2)]);
		#end
		return new Future(() -> withScaledDecode(() -> Image.fromFile(localPath)), true).then(image -> {
			return image != null ? Future.withValue(image) : withScaledDecode(() -> Image.loadFromFile(path), false);
		});
		#else
		return Image.loadFromFile(path);
		#end
	}

	@:noCompletion public static function decodeScaled(image:Image, encoded:Dynamic):Bool
	{
		#if (cpp && sys && lime_cffi && !disable_cffi)
		var policy = settings;
		if (encoded == null || nativeScaledDecode == null || !hasScaledDecodeScope() || (policy.maximum == 0 && policy.ratio == 1))
			return false;
		var decoded = nativeScaledDecode(encoded, new ImageBuffer(new UInt8Array(Bytes.alloc(0))), policy);
		if (decoded == null) return false;
		@:privateAccess image.__fromImageBuffer(decoded.buffer);
		image.imageSourceWidth = decoded.sourceWidth;
		image.imageSourceHeight = decoded.sourceHeight;
		image.buffer.graphicScale = Math.max(image.width, image.height) / Math.max(decoded.sourceWidth, decoded.sourceHeight);
		return true;
		#else
		return false;
		#end
	}

	public static function keepOriginal(image:Image):Image
	{
		if (image != null) image.isDecodedImage = false;
		return image;
	}

	public static function resize(image:Image):Image
	{
		if (image == null || image.buffer == null || image.imageSourceWidth > 0 || image.width <= 0 || image.height <= 0)
			return image;

		var scale = scaleFor(image.width, image.height);
		var width = scaledSide(image.width, scale);
		var height = scaledSide(image.height, scale);
		if (width == image.width && height == image.height) return image;
		var resized:Image;
		#if (js && html5)
		resized = image.clone();
		resized.resize(width, height);
		#else
		if (image.buffer.bitsPerPixel != 32 || image.data == null || image.offsetX != 0 || image.offsetY != 0
			|| image.width != image.buffer.width || image.height != image.buffer.height)
			return image;
		resized = resizePixels(image, width, height);
		#end
		resized.imageSourceWidth = image.width;
		resized.imageSourceHeight = image.height;
		resized.buffer.graphicScale = Math.max(width, height) / Math.max(image.width, image.height);
		return resized;
	}

	#if !(js && html5)
	static function resizePixels(image:Image, width:Int, height:Int):Image
	{
		var source = image.data;
		var pixels = new UInt8Array(width * height * 4);
		var alphaChannel = image.format == ARGB32 ? 0 : 3;
		var straightAlpha = image.transparent && !image.premultiplied;
		var stepX = image.width / width;
		var stepY = image.height / height;
		var columns = [for (x in 0...width) (x + 0.5) * stepX - 0.5];
		for (y in 0...height)
		{
			var sampleY = (y + 0.5) * stepY - 0.5;
			var top = Std.int(sampleY);
			var topRow = top * image.width * 4;
			var bottomRow = (top + 1 < image.height ? top + 1 : top) * image.width * 4;
			var vertical = sampleY - top;
			for (x in 0...width)
			{
				var sampleX = columns[x];
				var left = Std.int(sampleX);
				var right = left + 1 < image.width ? left + 1 : left;
				var horizontal = sampleX - left;
				var destination = (y * width + x) * 4;
				var topLeft = topRow + left * 4;
				var topRight = topRow + right * 4;
				var bottomLeft = bottomRow + left * 4;
				var bottomRight = bottomRow + right * 4;
				var weightTopLeft = (1 - horizontal) * (1 - vertical);
				var weightTopRight = horizontal * (1 - vertical);
				var weightBottomLeft = (1 - horizontal) * vertical;
				var weightBottomRight = horizontal * vertical;
				var alphaTopLeft = source[topLeft + alphaChannel];
				var alphaTopRight = source[topRight + alphaChannel];
				var alphaBottomLeft = source[bottomLeft + alphaChannel];
				var alphaBottomRight = source[bottomRight + alphaChannel];
				if (straightAlpha)
				{
					// Filter premultiplied colors without modifying the decoded buffer.
					pixels[destination + alphaChannel] = Math.round(alphaTopLeft * weightTopLeft + alphaTopRight * weightTopRight
						+ alphaBottomLeft * weightBottomLeft + alphaBottomRight * weightBottomRight);
					weightTopLeft *= alphaTopLeft / 255.0;
					weightTopRight *= alphaTopRight / 255.0;
					weightBottomLeft *= alphaBottomLeft / 255.0;
					weightBottomRight *= alphaBottomRight / 255.0;
				}
				for (channel in 0...4)
				{
					if (straightAlpha && channel == alphaChannel) continue;
					pixels[destination + channel] = Math.round(source[topLeft + channel] * weightTopLeft + source[topRight + channel] * weightTopRight
						+ source[bottomLeft + channel] * weightBottomLeft + source[bottomRight + channel] * weightBottomRight);
				}
			}
		}
		var buffer = new ImageBuffer(pixels, width, height, 32, image.format);
		buffer.premultiplied = true;
		buffer.transparent = image.transparent;
		return new Image(buffer);
	}
	#end
}
