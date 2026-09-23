package developer.console;

#if HSCRIPT_ALLOWED
import crowplexus.iris.ErrorSeverity;
import crowplexus.iris.Iris;
#end

class TraceInterceptor {
	static var initialized:Bool = false;
	static var publishing:Bool = false;
	static var originalTrace:Dynamic = haxe.Log.trace;

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

	public static function restore():Void {
		if (!initialized) return;
		initialized = false;

		haxe.Log.trace = originalTrace;

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

		// ★ 先把消息发给 1145 trace 客户端，再喂屏幕控制台 —— 两者各自 try 隔离。
		//   原来两条写在同一个 try 里：Console.logLevel 一旦抛异常（UI 侧任何问题），
		//   后面的 sendTraceMessage 就被跳过，而且之后每一条 trace 都会这样被吞掉，
		//   表现为"客户端只收到连接问候，之后什么都收不到"（本次调 Mods 菜单时实测复现）。
		try {
			TraceServer.sendTraceMessage(level, message, color);
		} catch (e:Dynamic) {
			callOriginalTrace('Trace server publish failed: $e', null);
		}

		try {
			Console.logLevel(level, message, color);
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
