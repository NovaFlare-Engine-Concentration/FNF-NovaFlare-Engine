package developer.console;

import flixel.system.debug.log.LogStyle;
import flixel.system.frontEnds.LogFrontEnd;

#if HSCRIPT_ALLOWED
import crowplexus.iris.ErrorSeverity;
import crowplexus.iris.Iris;
#end

class TraceInterceptor {
	static var initialized:Bool = false;
	static var localOnly:Bool = false;
	static var publishing:Bool = false;
	static var originalTrace:Dynamic = haxe.Log.trace;
	static var originalFlixelLogs:(Dynamic, LogStyle, Bool)->Void;

	#if HSCRIPT_ALLOWED
	static var originalLogLevel:Dynamic = Iris.logLevel;
	#end

	public static function init():Void {
		if (initialized) return;
		initialized = true;

		haxe.Log.trace = customTrace;

		#if HSCRIPT_ALLOWED
		Iris.logLevel = customLogLevel;
		#end

		TraceServer.start(1145);
		ConsoleToggleButton.show();
	}

	public static function initLocal(traceOutput:(Dynamic, Null<haxe.PosInfos>)->Void):Void {
		if (initialized) return;
		initialized = true;
		localOnly = true;
		originalTrace = traceOutput;
		haxe.Log.trace = localTrace;
		#if CODENAME_ENGINE_COMPAT
		if (Console.mode == CodeName && codename.funkin.backend.system.Logs.routesFlixelLogs) return;
		#end
		originalFlixelLogs = LogFrontEnd.onLogs;
		LogFrontEnd.onLogs = localFlixelLog;
	}

	public static function restore():Void {
		if (!initialized) return;
		initialized = false;

		haxe.Log.trace = originalTrace;
		if (localOnly) {
			if (Reflect.compareMethods(LogFrontEnd.onLogs, localFlixelLog)) LogFrontEnd.onLogs = originalFlixelLogs;
			originalFlixelLogs = null;
			localOnly = false;
			return;
		}

		#if HSCRIPT_ALLOWED
		Iris.logLevel = originalLogLevel;
		#end

		TraceServer.stop();
	}

	static function customTrace(v:Dynamic, ?infos:haxe.PosInfos):Void {
		var message = formatMessage(v, infos);
		callOriginalTrace(v, infos);
		publish("INFO", message, 0xD7E1EA);
	}

	static function localTrace(value:Dynamic, ?infos:haxe.PosInfos):Void {
		var body = Std.string(value);
		var level = "INFO";
		var color = 0xD7E1EA;
		if (Console.mode == Origin && infos != null && infos.className == "funkin.modding.PolymodErrorHandler") {
			var errorPrefix = funkin.util.AnsiUtil.error(" ERROR ");
			var warningPrefix = funkin.util.AnsiUtil.warning(" WARNING ");
			if (StringTools.startsWith(body, errorPrefix)) {
				body = StringTools.ltrim(body.substr(errorPrefix.length));
				level = "ERROR";
				color = 0xFF6B6B;
			} else if (StringTools.startsWith(body, warningPrefix)) {
				body = StringTools.ltrim(body.substr(warningPrefix.length));
				level = "WARN";
				color = 0xFFD166;
			}
		}
		var message = formatMessage(body, infos);
		if (Console.mode == Origin && message.indexOf("\x1b") != -1)
			message = ~/\x1b\[[0-9;]*m/g.replace(message, "");
		originalTrace(value, infos);
		Console.logLevel(level, message, color);
	}

	static function localFlixelLog(data:Dynamic, style:LogStyle, fireOnce:Bool):Void {
		if (originalFlixelLogs != null) originalFlixelLogs(data, style, fireOnce);
		if (style == LogStyle.ERROR) Console.logLevel("ERROR", Std.string(data), 0xFF6B6B);
		if (style == LogStyle.WARNING) Console.logLevel("WARN", Std.string(data), 0xFFD166);
	}

	#if CODENAME_ENGINE_COMPAT
	public static function publishCodeName(level:codename.funkin.backend.system.Logs.Level, message:String):Void {
		switch (level) {
			case ERROR: Console.logLevel("ERROR", message, 0xFF6B6B);
			case WARNING: Console.logLevel("WARN", message, 0xFFD166);
			case TRACE: Console.logLevel("TRACE", message, 0xD7E1EA);
			case VERBOSE: Console.logLevel("VERBOSE", message, 0xD7E1EA);
			case SUCCESS: Console.logLevel("SUCCESS", message, 0x82D9A0);
			case FAILURE: Console.logLevel("FAILURE", message, 0xFF6B6B);
			case INFO: Console.logLevel("INFO", message, 0xD7E1EA);
		}
	}
	#end

	#if HSCRIPT_ALLOWED
	static function customLogLevel(level:ErrorSeverity, x:Dynamic, ?infos:haxe.PosInfos):Void {
		var message = formatMessage(x, infos);
		var name = severityName(level);
		var color = severityColor(level);

		callOriginalLogLevel(level, x, infos);
		publish(name, message, color);
	}
	#end

	static function publish(level:String, message:String, color:Int):Void {
		if (publishing) return;
		publishing = true;

		try {
			Console.logLevel(level, message, color);
			TraceServer.sendTraceMessage(level, message, color);
		} catch (e:Dynamic) {
			callOriginalTrace('Trace console failed: $e', null);
		}

		publishing = false;
	}

	static function callOriginalTrace(v:Dynamic, ?infos:haxe.PosInfos):Void {
		try {
			originalTrace(v, infos);
		} catch (_:Dynamic) {}
	}

	#if HSCRIPT_ALLOWED
	static function callOriginalLogLevel(level:ErrorSeverity, x:Dynamic, ?infos:haxe.PosInfos):Void {
		try {
			originalLogLevel(level, x, infos);
		} catch (_:Dynamic) {}
	}

	static function severityName(level:ErrorSeverity):String {
		return switch (level) {
			case WARN: "WARN";
			case ERROR: "ERROR";
			case FATAL: "FATAL";
			case NONE: "SCRIPT";
		}
	}

	static function severityColor(level:ErrorSeverity):Int {
		return switch (level) {
			case WARN: 0xFFD166;
			case ERROR: 0xFF6B6B;
			case FATAL: 0xF78CFF;
			case NONE: 0xD7E1EA;
		}
	}
	#end

	static function formatMessage(value:Dynamic, ?infos:haxe.PosInfos):String {
		var message = Std.string(value);

		if (infos != null && infos.customParams != null) {
			for (param in infos.customParams) {
				message += " " + Std.string(param);
			}
		}

		if (infos != null && infos.fileName != null) {
			return '${infos.fileName}:${infos.lineNumber}: $message';
		}

		return message;
	}
}
