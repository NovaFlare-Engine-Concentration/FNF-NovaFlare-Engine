package mobile.backend;

import openfl.events.UncaughtErrorEvent;
import openfl.events.ErrorEvent;
import openfl.errors.Error;

import flixel.FlxSubState;

import states.mainMenuState.MainMenuState;

import substates.ErrorSubState;

#if sys
import haxe.io.Path;
import sys.FileSystem;
import sys.io.File;
#end

#if cpp
import cpp.vm.Gc;
#end

using general.backend.CoolUtil;

/**
 * Crash Handler.
 * @author YoshiCrafter29, Ne_Eo and MAJigsaw77
 */
class CrashHandler
{
	public static function init():Void
	{
		#if (cpp && (windows || android))
		general.backend.NativeCrashHandler.init(
			states.mainMenuState.MainMenuState.novaFlareEngineCommit);
		#end
		openfl.Lib.current.loaderInfo.uncaughtErrorEvents.addEventListener(UncaughtErrorEvent.UNCAUGHT_ERROR, onUncaughtError);
		#if cpp
		untyped __global__.__hxcpp_set_critical_error_handler(onError);
		#elseif hl
		hl.Api.setErrorHandler(onError);
		#end
	}

	public static function refreshNativeCrashDirectory():Void
	{
		#if (cpp && (windows || android))
		general.backend.NativeCrashHandler.refreshDirectory();
		#end
	}

	private static function onUncaughtError(e:UncaughtErrorEvent):Void
	{
		e.preventDefault();
		e.stopPropagation();
		e.stopImmediatePropagation();

		var m:String = e.error;
		if (Std.isOfType(e.error, Error))
		{
			var err = cast(e.error, Error);
			m = '${err.message}';
		}
		else if (Std.isOfType(e.error, ErrorEvent))
		{
			var err = cast(e.error, ErrorEvent);
			m = '${err.text}';
		}
		var stack = haxe.CallStack.exceptionStack(true);
		var callStack = haxe.CallStack.callStack();
		var stackLabelArr:Array<String> = [];
		var stackLabel:String = "";
		var errorText:String = "Oh Shit! - " + states.mainMenuState.MainMenuState.novaFlareEngineCommit;
		for (e in stack)
		{
			switch (e)
			{
				case CFunction:
					stackLabelArr.push("Non-Haxe (C) Function");
				case Module(c):
					stackLabelArr.push('Module ${c}');
				case FilePos(parent, file, line, col):
					switch (parent)
					{
						case Method(cla, func):
							stackLabelArr.push('${file.replace('.hx', '')}.$func() [line $line]');
						case _:
							stackLabelArr.push('${file.replace('.hx', '')} [line $line]');
					}
				case LocalFunction(v):
					stackLabelArr.push('Local Function ${v}');
				case Method(cl, m):
					stackLabelArr.push('${cl} - ${m}');
			}
		}
		stackLabel = stackLabelArr.join('\r\n');
		#if sys
		try
		{
			var diagnosticRoot = Sys.getEnv("NOVAFLARE_DIAGNOSTIC_DIR");
			var crashDirectory = diagnosticRoot != null && diagnosticRoot.length > 0
				? Path.join([diagnosticRoot, "haxe-crash"])
				: "crash";
			if (!FileSystem.exists(crashDirectory))
				FileSystem.createDirectory(crashDirectory);

			var nativeExceptionStack = "";
			#if cpp
			try
				nativeExceptionStack = Std.string(haxe.NativeStackTrace.exceptionStack())
			catch (_:Dynamic) {}
			#end

			var heapSnapshot = "unavailable";
			#if cpp
			try
			{
				#if hxcpp_zgc
				heapSnapshot =
					'used_bytes=${Gc.memInfo64(2)}\n' +
					'committed_bytes=${Gc.memInfo64(4)}\n' +
					'application_bytes=${Gc.memInfo64(8)}';
				#else
				heapSnapshot =
					'used_bytes=${Gc.memInfo64(2)}\n' +
					'committed_bytes=${Gc.memInfo64(1)}\n' +
					'application_bytes=${Gc.memInfo64(4)}';
				#end
			}
			catch (_:Dynamic) {}
			#end

			var saveError =
				'commit=${states.mainMenuState.MainMenuState.novaFlareEngineCommit}\n' +
				'timestamp=${Date.now()}\n' +
				'message=$m\n' +
				'\n[haxe_exception_stack]\n$stackLabel\n' +
				'\n[haxe_exception_stack_raw]\n${haxe.CallStack.toString(stack)}\n' +
				'\n[haxe_call_stack]\n${haxe.CallStack.toString(callStack)}\n' +
				'\n[native_hxcpp_exception_stack]\n$nativeExceptionStack\n' +
				'\n[heap]\n$heapSnapshot\n';
			var fileName = Date.now().toString()
				.replace(' ', '-')
				.replace(':', "'") + '.txt';
			File.saveContent(Path.join([crashDirectory, fileName]), saveError);
			Sys.println('haxe:uncaught_error message=$m');
			Sys.println(saveError);
			errorText = Std.string(saveError);
			if (originfunkin.OriginFunkinMode.active)
			{
				originfunkin.OriginFunkinMode.reportRuntimeError(errorText);
				FlxG.switchState(new originfunkin.OriginFunkinErrorState());
				return;
			}
			FlxG.state.openSubState(new ErrorSubState(errorText));
		}
		catch (e:haxe.Exception)
			trace('Couldn\'t save error message. (${e.message})');
			trace(Std.string(states.mainMenuState.MainMenuState.novaFlareEngineCommit + '\n' + '$m\n$stackLabel'));
		#end

		// mobile.backend.SUtil.showPopUp('$m\n$stackLabel', "Error!");
	}

	#if (cpp || hl)
	private static function onError(message:Dynamic):Void
	{
		throw Std.string(message);
	}
	#end
}
