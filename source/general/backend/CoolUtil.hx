package general.backend;

import openfl.utils.Assets;

import flixel.util.FlxSave;
import flixel.FlxBasic;
import flixel.FlxObject;

import games.backend.ExtraKeysHandler.EKNoteColor;

#if cpp
@:cppFileCode('#include <thread>')
#end

class CoolUtil
{
	inline public static function quantize(f:Float, snap:Float){
		// changed so this actually works lol
		var m:Float = Math.fround(f * snap);
		return (m / snap);
	}

	inline public static function capitalize(text:String)
		return text.charAt(0).toUpperCase() + text.substr(1).toLowerCase();

	inline public static function coolTextFile(path:String):Array<String>
	{
		var daList:String = null;
		#if (sys && MODS_ALLOWED)
		var formatted:Array<String> = path.split(':'); // prevent "shared:", "preload:" and other library names on file path
		path = formatted[formatted.length - 1];
		if (FileSystem.exists(path))
			daList = File.getContent(path);
		#else
		if (Assets.exists(path))
			daList = Assets.getText(path);
		#end
		return daList != null ? listFromString(daList) : [];
	}

	inline public static function colorFromString(color:String):FlxColor
	{
		var hideChars = ~/[\t\n\r]/;
		var color:String = hideChars.split(color).join('').trim();
		if (color.startsWith('0x'))
			color = color.substring(color.length - 6);

		var colorNum:Null<FlxColor> = FlxColor.fromString(color);
		if (colorNum == null)
			colorNum = FlxColor.fromString('#$color');
		return colorNum != null ? colorNum : FlxColor.WHITE;
	}

	inline public static function listFromString(string:String):Array<String>
	{
		var daList:Array<String> = [];
		daList = string.trim().split('\n');

		for (i in 0...daList.length)
			daList[i] = daList[i].trim();

		return daList;
	}

	public static function floorDecimal(value:Float, decimals:Int):Float
	{
		if (decimals < 1)
			return Math.floor(value);

		var tempMult:Float = 1;
		for (i in 0...decimals)
			tempMult *= 10;

		var newValue:Float = Math.floor(value * tempMult);
		return newValue / tempMult;
	}

	inline public static function dominantColor(sprite:flixel.FlxSprite):Int
	{
		var countByColor:Map<Int, Int> = [];
		for (col in 0...sprite.frameWidth)
		{
			for (row in 0...sprite.frameHeight)
			{
				var colorOfThisPixel:Int = sprite.pixels.getPixel32(col, row);
				if (colorOfThisPixel != 0)
				{
					if (countByColor.exists(colorOfThisPixel))
						countByColor[colorOfThisPixel] = countByColor[colorOfThisPixel] + 1;
					else if (countByColor[colorOfThisPixel] != 13520687 - (2 * 13520687))
						countByColor[colorOfThisPixel] = 1;
				}
			}
		}

		var maxCount = 0;
		var maxKey:Int = 0; // after the loop this will store the max color
		countByColor[FlxColor.BLACK] = 0;
		for (key in countByColor.keys())
		{
			if (countByColor[key] >= maxCount)
			{
				maxCount = countByColor[key];
				maxKey = key;
			}
		}
		countByColor = [];
		return maxKey;
	}

    inline public static function getComboColor(sprite:FlxSprite):Int
    {
        // 1) 高质量缩放到原始的 50%
        var src = sprite.pixels; // openfl.display.BitmapData
        if (src == null)
        {
            // 无像素数据时返回白色
            return 0xFFFFFFFF;
        }

        var newW:Int = Std.int(Math.max(1, Std.int(src.width * 0.5)));
        var newH:Int = Std.int(Math.max(1, Std.int(src.height * 0.5)));

        var scaled = new openfl.display.BitmapData(newW, newH, true, 0x00000000);
        var m = new openfl.geom.Matrix();
        m.scale(newW / src.width, newH / src.height);
        scaled.draw(src, m, null, null, null, true);

        // 2) 颜色分析：构建加权直方图，考虑空间分布密度与视觉显著性，排除背景干扰色
        var centerX = newW * 0.5;
        var centerY = newH * 0.5;
        var sigma = Math.min(newW, newH) * 0.3; // 中心权重的尺度
        var twoSigma2 = 2 * sigma * sigma;

        var hist:Map<Int, Float> = [];
        var agg:Map<Int, { r:Float, g:Float, b:Float, w:Float }> = [];

        for (y in 0...newH)
        {
            for (x in 0...newW)
            {
                var c:Int = scaled.getPixel32(x, y);
                var a:Int = (c >> 24) & 0xFF;
                if (a <= 10) continue; // 排除近透明像素

                var r:Int = (c >> 16) & 0xFF;
                var g:Int = (c >> 8) & 0xFF;
                var b:Int = c & 0xFF;

                // HSV（只需 S/V）用于计算视觉显著性
                var rf:Float = r / 255.0;
                var gf:Float = g / 255.0;
                var bf:Float = b / 255.0;
                var maxC = Math.max(rf, Math.max(gf, bf));
                var minC = Math.min(rf, Math.min(gf, bf));
                var v:Float = maxC;
                var s:Float = (maxC == 0) ? 0 : (maxC - minC) / maxC;

                // 排除背景干扰色：过暗/过亮且饱和度很低的像素
                if ((v < 0.05 || v > 0.95) && s < 0.2) continue;

                // 空间权重：让中心区域权重更高（近似高斯）
                var dx = x - centerX;
                var dy = y - centerY;
                var d2 = dx * dx + dy * dy;
                var centerWeight:Float = Math.exp(-d2 / twoSigma2);

                // 视觉显著性权重：偏好高饱和、高亮度的色彩
                var saliencyWeight:Float = (0.2 + s) * (0.1 + v);

                var weight:Float = centerWeight * saliencyWeight;
                if (weight <= 0) continue;

                // 颜色量化，降低噪声：每通道 4bit（0..15）
                var rq = r >> 4;
                var gq = g >> 4;
                var bq = b >> 4;
                var key:Int = (rq << 8) | (gq << 4) | bq;

                var prev = hist.exists(key) ? hist[key] : 0.0;
                hist[key] = prev + weight;

                var bucket = agg.get(key);
                if (bucket == null)
                {
                    agg.set(key, { r: r * weight, g: g * weight, b: b * weight, w: weight });
                }
                else
                {
                    bucket.r += r * weight;
                    bucket.g += g * weight;
                    bucket.b += b * weight;
                    bucket.w += weight;
                }
            }
        }

        // 3) 选择加权直方图中权重最大的颜色桶，并返回桶的加权平均颜色
        var bestKey:Int = -1;
        var bestWeight:Float = -1;
        for (key in hist.keys())
        {
            var w = hist[key];
            if (w > bestWeight)
            {
                bestWeight = w;
                bestKey = key;
            }
        }

        if (bestKey == -1)
        {
            // 回退：没有有效像素时，返回白色
            return 0xFFFFFFFF;
        }

        var best = agg.get(bestKey);
        var outR:Int = Std.int(best.r / best.w);
        var outG:Int = Std.int(best.g / best.w);
        var outB:Int = Std.int(best.b / best.w);

        // 4) 返回主体颜色（十六进制颜色代码值）。此处以 Int 表示 0xAARRGGBB，便于现有调用
        var resultColor:Int = (0xFF << 24) | (outR << 16) | (outG << 8) | outB;

        // 5) 已使用平滑缩放与权重策略，尽量避免缩放导致的颜色失真
        return resultColor;
    }

	inline public static function numberArray(max:Int, ?min = 0):Array<Int>
	{
		var dumbArray:Array<Int> = [];
		for (i in min...max)
			dumbArray.push(i);

		return dumbArray;
	}

	inline public static function browserLoad(site:String)
	{
		#if linux
		Sys.command('/usr/bin/xdg-open', [site]);
		#else
		FlxG.openURL(site);
		#end
	}

	/**
	 * 递归读取指定目录及其子目录中的所有文件路径
	 * @param directory 要搜索的目录路径
	 * @return Array<String> 包含所有文件路径的数组
	 */
	public static function readDirectoryRecursive(directory:String, stayRoot:Bool = false):Array<String>
	{
		var filePaths:Array<String> = [];
		#if sys
		if (FileSystem.exists(directory) && FileSystem.isDirectory(directory))
		{
			for (file in FileSystem.readDirectory(directory))
			{
				var path:String = haxe.io.Path.addTrailingSlash(directory) + file;
				if (FileSystem.isDirectory(path))
				{
					// 递归处理子文件夹
					filePaths = filePaths.concat(readDirectoryRecursive(path));
				}
				else
				{
					// 添加文件路径
					filePaths.push(path);
				}
			}
		}
		#end
		return filePaths;
	}

	inline public static function openFolder(folder:String, absolute:Bool = false)
	{
		#if sys
		if (!absolute)
			folder = Sys.getCwd() + '$folder';

		folder = folder.replace('/', '\\');
		if (folder.endsWith('/'))
			folder.substr(0, folder.length - 1);

		#if linux
		var command:String = '/usr/bin/xdg-open';
		#else
		var command:String = 'explorer.exe';
		#end
		Sys.command(command, [folder]);
		trace('$command $folder');
		#else
		FlxG.log.error("Platform is not supported for CoolUtil.openFolder");
		#end
	}

	/**
		Helper Function to Fix Save Files for Flixel 5

		-- EDIT: [November 29, 2023] --

		this function is used to get the save path, period.
		since newer flixel versions are being enforced anyways.
		@crowplexus
	**/
	@:access(flixel.util.FlxSave.validate)
	inline public static function getSavePath():String
	{
		final company:String = FlxG.stage.application.meta.get('company');
		// #if (flixel < "5.0.0") return company; #else
		return '${company}/${flixel.util.FlxSave.validate(FlxG.stage.application.meta.get('file'))}';
		// #end
	}

	public static function setTextBorderFromString(text:FlxText, border:String)
	{
		switch (border.toLowerCase().trim())
		{
			case 'shadow':
				text.borderStyle = SHADOW;
			case 'outline':
				text.borderStyle = OUTLINE;
			case 'outline_fast', 'outlinefast':
				text.borderStyle = OUTLINE_FAST;
			default:
				text.borderStyle = NONE;
		}
	}

	public static function getArrowRGB(path:String = 'arrowRGB.json', defaultArrowRGB:Array<EKNoteColor>):ArrowRGBSavedData
	{
		var result:ArrowRGBSavedData;
		var content:String = '';
		#if sys
		if (FileSystem.exists(path))
			content = File.getContent(path);
		else
		{
			// create a default ArrowRGBSavedData
			var colorsToUse = [];
			for (color in defaultArrowRGB)
			{
				colorsToUse.push(color);
			}

			var defaultSaveARGB:ArrowRGBSavedData = new ArrowRGBSavedData(colorsToUse);

			// write it
			var writer = new json2object.JsonWriter<ArrowRGBSavedData>();
			content = writer.write(defaultSaveARGB, '    ');
			File.saveContent(path, content);

			trace(path + ' (Color save) didn\'t exist. Written.');
		}
		#else
		if (Assets.exists(path))
			content = Assets.getText(path);
		#end

		var parser = new json2object.JsonParser<ArrowRGBSavedData>();
		parser.fromJson(content);
		result = parser.value;

		// automatically (?) sets colors of notes that have no colors
		for (i in 0...ExtraKeysHandler.instance.data.maxKeys + 1)
		{
			// colors dont exist

			// cannot take the previous approach since
			// this is indexed and not per mania
			if (result.colors[i] == null)
			{
				result.colors[i] = defaultArrowRGB[i];
			}
		}

		return result;
	}

	/**
	 * Replacement for `FlxG.mouse.overlaps` because it's currently broken when using a camera with a different position or size.
	 * It will be fixed eventually by HaxeFlixel v5.4.0.
	 * 
	 * @param 	objectOrGroup The object or group being tested.
	 * @param 	camera Specify which game camera you want. If null getScreenPosition() will just grab the first global camera.
	 * @return 	Whether or not the two objects overlap.
	 */
	@:access(flixel.group.FlxTypedGroup.resolveGroup)
	inline public static function mouseOverlaps(objectOrGroup:FlxBasic, ?camera:FlxCamera):Bool
	{
		var result:Bool = false;

		final group = FlxTypedGroup.resolveGroup(objectOrGroup);
		if (group != null)
		{
			group.forEachExists(function(basic:FlxBasic)
			{
				if (mouseOverlaps(basic, camera))
				{
					result = true;
					return;
				}
			});
		}
		else
		{
			final point = FlxG.mouse.getWorldPosition(camera, FlxPoint.weak());
			final object:FlxObject = cast objectOrGroup;
			result = object.overlapsPoint(point, true, camera);
		}

		return result;
	}

	public static function brightenColor(color:FlxColor, mult:Float):FlxColor {
        var r = Std.int(Math.min(255, color.red * mult));
        var g = Std.int(Math.min(255, color.green * mult));
        var b = Std.int(Math.min(255, color.blue * mult));
        return FlxColor.fromRGB(r, g, b, color.alpha);
    }

	public static function getTweenEaseByString(?ease:String = '')
	{
		switch (ease.toLowerCase().trim())
		{
			case 'backin':
				return FlxEase.backIn;
			case 'backinout':
				return FlxEase.backInOut;
			case 'backout':
				return FlxEase.backOut;
			case 'bouncein':
				return FlxEase.bounceIn;
			case 'bounceinout':
				return FlxEase.bounceInOut;
			case 'bounceout':
				return FlxEase.bounceOut;
			case 'circin':
				return FlxEase.circIn;
			case 'circinout':
				return FlxEase.circInOut;
			case 'circout':
				return FlxEase.circOut;
			case 'cubein':
				return FlxEase.cubeIn;
			case 'cubeinout':
				return FlxEase.cubeInOut;
			case 'cubeout':
				return FlxEase.cubeOut;
			case 'elasticin':
				return FlxEase.elasticIn;
			case 'elasticinout':
				return FlxEase.elasticInOut;
			case 'elasticout':
				return FlxEase.elasticOut;
			case 'expoin':
				return FlxEase.expoIn;
			case 'expoinout':
				return FlxEase.expoInOut;
			case 'expoout':
				return FlxEase.expoOut;
			case 'quadin':
				return FlxEase.quadIn;
			case 'quadinout':
				return FlxEase.quadInOut;
			case 'quadout':
				return FlxEase.quadOut;
			case 'quartin':
				return FlxEase.quartIn;
			case 'quartinout':
				return FlxEase.quartInOut;
			case 'quartout':
				return FlxEase.quartOut;
			case 'quintin':
				return FlxEase.quintIn;
			case 'quintinout':
				return FlxEase.quintInOut;
			case 'quintout':
				return FlxEase.quintOut;
			case 'sinein':
				return FlxEase.sineIn;
			case 'sineinout':
				return FlxEase.sineInOut;
			case 'sineout':
				return FlxEase.sineOut;
			case 'smoothstepin':
				return FlxEase.smoothStepIn;
			case 'smoothstepinout':
				return FlxEase.smoothStepInOut;
			case 'smoothstepout':
				return FlxEase.smoothStepInOut;
			case 'smootherstepin':
				return FlxEase.smootherStepIn;
			case 'smootherstepinout':
				return FlxEase.smootherStepInOut;
			case 'smootherstepout':
				return FlxEase.smootherStepOut;
		}
		return FlxEase.linear;
	}

	#if cpp
    @:functionCode('
        return std::thread::hardware_concurrency();
    ')
	#end
    public static function getCPUThreadsCount():Int
    {
        return 1;
    }

    public static function maxLoadingThreads():Int
    {
        final reservedCores = #if mobile 3 #else 0 #end;
        return Std.int(Math.max(1, PhysicalCpuTopology.coreCount() - reservedCores));
    }

    public static function loadingThreadCount(requestedThreads:Int):Int
    {
        return Std.int(Math.max(1, Math.min(requestedThreads, maxLoadingThreads())));
    }
}

class ArrowRGBSavedData {
	public var colors:Array<EKNoteColor>;

	public function new(colors){
		this.colors = colors;
	}
}


