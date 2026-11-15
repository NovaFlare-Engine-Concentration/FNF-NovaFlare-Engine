package codename.funkin.backend.system.framerate;

import codename.funkin.backend.system.Logs;
import codename.funkin.backend.utils.MemoryUtil;
#if !mobile
import codename.funkin.backend.utils.native.HiddenProcess;
#end
#if android
import android.os.Build;
import android.os.Build.VERSION;
import android.os.Build.VERSION_CODES;
#end
#if cpp
import cpp.Float64;
import cpp.UInt64;
#end
#if windows
import codename.funkin.backend.utils.native.Windows;
#end

using StringTools;
import codename.funkin.backend.system.macros.StringMacro;

class SystemInfo extends FramerateCategory {
	public static var osInfo:String = "Unknown";
	public static var gpuName:String = "Unknown";
	public static var vRAM:String = "Unknown";
	public static var cpuName:String = "Unknown";
	public static var totalMem:String = "Unknown";
	public static var memType:String = "Unknown";
	public static var gpuMaxSize:String = "Unknown";

	static var __formattedSysText:String = "";

	public static function init() {
		#if android
		osInfo = 'Android ${VERSION.RELEASE} (API ${VERSION.SDK_INT})';
		#elseif linux
		var process = new HiddenProcess("cat", ["/etc/os-release"]);
		if (process.exitCode() != 0) Logs.error('Unable to grab OS Label');
		else {
			var osName = "";
			var osVersion = "";
			for (line in process.stdout.readAll().toString().split("\n")) {
				if (line.startsWith("PRETTY_NAME=")) {
					var index = line.indexOf('"');
					if (index != -1)
						osName = line.substring(index + 1, line.lastIndexOf('"'));
					else {
						var arr = line.split("=");
						arr.shift();
						osName = arr.join("=");
					}
				}
				if (line.startsWith("VERSION=")) {
					var index = line.indexOf('"');
					if (index != -1)
						osVersion = line.substring(index + 1, line.lastIndexOf('"'));
					else {
						var arr = line.split("=");
						arr.shift();
						osVersion = arr.join("=");
					}
				}
			}
			if (osName != "")
				osInfo = '${osName} ${osVersion}'.trim();
		}
		#else
		#if windows
		final buildNumber = Windows.getBuildNumber();

		if (buildNumber >= 9200) {
			final windowsCurrentVersionPath = "SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion";
			var edition = RegistryUtil.get(HKEY_LOCAL_MACHINE, windowsCurrentVersionPath, "ProductName");

			var lcuKey = "WinREVersion"; // Last Cumulative Update Key On Older Windows Versions
			if (buildNumber >= 22000) {
				edition = edition.replace("Windows 10", "Windows 11");
				lcuKey = "LCUVer";
			}

			final lcuVersion = RegistryUtil.get(HKEY_LOCAL_MACHINE, windowsCurrentVersionPath, lcuKey);

			osInfo = edition;
			if (lcuVersion != null && lcuVersion != "")
				osInfo += ' ${lcuVersion}';
			else if (lime.system.System.platformVersion != null && lime.system.System.platformVersion != "")
				osInfo += ' ${lime.system.System.platformVersion}';
		}
		else
		#end
		if (lime.system.System.platformLabel != null && lime.system.System.platformLabel != "" && lime.system.System.platformVersion != null && lime.system.System.platformVersion != "")
			osInfo = '${lime.system.System.platformLabel.replace(lime.system.System.platformVersion, "").trim()} ${lime.system.System.platformVersion}';
		else
			Logs.error('Unable to grab OS Label');
		#end

		try {
			#if android
			cpuName = VERSION.SDK_INT >= VERSION_CODES.S ? Build.SOC_MODEL : Build.HARDWARE;
			#elseif ios
			cpuName = lime.system.System.deviceModel;
			#elseif windows
			if (buildNumber >= 9200) {
				cpuName = RegistryUtil.get(HKEY_LOCAL_MACHINE, "HARDWARE\\DESCRIPTION\\System\\CentralProcessor\\0", "ProcessorNameString");
			}
			else {
				var process = new HiddenProcess("wmic", ["cpu", "get", "name"]);
				if (process.exitCode() != 0) throw 'Could not fetch CPU information';

				cpuName = process.stdout.readAll().toString().trim().split("\n")[1].trim();
			}
			#elseif (mac && !mobile)
			var process = new HiddenProcess("sysctl -a | grep brand_string"); // Somehow this isn't able to use the args but it still works
			if (process.exitCode() != 0) throw 'Could not fetch CPU information';

			cpuName = process.stdout.readAll().toString().trim().split(":")[1].trim();
			#elseif (linux && !mobile)
			var process = new HiddenProcess("cat", ["/proc/cpuinfo"]);
			if (process.exitCode() != 0) throw 'Could not fetch CPU information';

			for (line in process.stdout.readAll().toString().split("\n")) {
				if (line.indexOf("model name") == 0) {
					cpuName = line.substring(line.indexOf(":") + 2);
					break;
				}
			}
			#end
		} catch (e) {
			Logs.error('Unable to grab CPU Name: $e');
		}

		@:privateAccess if(FlxG.renderTile) { // Blit doesn't enable the gpu. Idk if we should fix this
			if (flixel.FlxG.stage.context3D != null && flixel.FlxG.stage.context3D.gl != null) {
				gpuName = Std.string(flixel.FlxG.stage.context3D.gl.getParameter(flixel.FlxG.stage.context3D.gl.RENDERER)).split("/")[0].trim();
				#if !flash
				var size = FlxG.bitmap.maxTextureSize;
				gpuMaxSize = size+"x"+size;
				#end

				if(openfl.display3D.Context3D.__glMemoryTotalAvailable != -1) {
					var vRAMBytes:Int = cast flixel.FlxG.stage.context3D.gl.getParameter(openfl.display3D.Context3D.__glMemoryTotalAvailable);
					if (vRAMBytes == 1000 || vRAMBytes == 1 || vRAMBytes <= 0)
						Logs.trace('Unable to grab GPU VRAM', ERROR, RED);
					else {
						vRAM = getSizeString(vRAMBytes / 1024);
					}
				}
			} else
				Logs.error('Unable to grab GPU Info');
		}

		#if cpp
		var totalMemoryMB = MemoryUtil.getTotalMem();
		if (totalMemoryMB > 0)
			totalMem = Std.string(Math.round(totalMemoryMB / 10.24) / 100) + " GB";
		else
			Logs.error('Unable to grab RAM Amount');
		#else
		Logs.error('Unable to grab RAM Amount');
		#end

		try {
			memType = MemoryUtil.getMemType();
		} catch (e) {
			Logs.error('Unable to grab RAM Type: $e');
		}
		formatSysInfo();
	}

	static function formatSysInfo() {
		var buf = new StringBuf();
		#if android
		var brand = Build.BRAND == null || Build.BRAND.length == 0
			? "Unknown"
			: Build.BRAND.charAt(0).toUpperCase() + Build.BRAND.substring(1);
		StringMacro.addLine(buf, 'Device: $brand ${Build.MODEL} (${Build.BOARD})');
		#elseif ios
		var vendor = lime.system.System.deviceVendor;
		var model = lime.system.System.deviceModel;
		StringMacro.addLine(buf, 'Device: ${vendor == null ? "Apple" : vendor} ${model == null ? "Unknown" : model}');
		#end
		if (osInfo != "Unknown") {
			#if (android || ios)
			buf.add("\n");
			#end
			StringMacro.addLine(buf, 'System: ${osInfo}');
		}
		if (cpuName != "Unknown") {
			StringMacro.addLine(buf, '\nCPU: ${cpuName} ${openfl.system.Capabilities.cpuArchitecture} ${openfl.system.Capabilities.supports64BitProcesses ? "64-Bit" : "32-Bit"}');
		}
		if (gpuName != cpuName || vRAM != "Unknown") {
			var gpuNameKnown = gpuName != "Unknown" && gpuName != cpuName;
			var vramKnown = vRAM != "Unknown";

			if(gpuNameKnown || vramKnown) buf.add("\n");

			if(gpuNameKnown) {
				StringMacro.addLine(buf, 'GPU: ${gpuName}');
			}
			if(gpuNameKnown && vramKnown) buf.add(" | ");
			if(vramKnown) {
				StringMacro.addLine(buf, 'VRAM: ${vRAM}');
			}
		}
		//if (gpuMaxSize != "Unknown") StringMacro.addLine(buf, '\nMax Bitmap Size: ',gpuMaxSize);
		if (totalMem != "Unknown") {
			StringMacro.addLine(buf, '\nTotal MEM: ${totalMem}${memType != "Unknown" ? " " + memType : ""}');
		}
		__formattedSysText = buf.toString();
	}

	static function getSizeString(size:Float):String {
		if (size < 1024)
			return Std.int(size) + " MB";
		else if (size < 1024 * 1024)
			return Std.int(size / 1024) + " GB";
		else {
			var tb = size / (1024 * 1024);
			return Std.int(tb) + "." + CoolUtil.addZeros(Std.string(Std.int((tb % 1) * 100)), 2) + " TB";
		}
	}

	public function new() {
		super("System Info");
	}

	public override function __enterFrame(t:Float) {
		if (alpha <= 0.05 || !visible) return;

		var buf = new StringBuf();
		buf.add(__formattedSysText);
		if (__formattedSysText != '') buf.add('\n');
		StringMacro.addLine(buf, 'Garbage Collector: ${MemoryUtil.disableCount > 0 ? "OFF" : "ON"} (${MemoryUtil.disableCount})');
		_text = buf.toString();

		this.text.text = _text;
		super.__enterFrame(t);
	}
}
