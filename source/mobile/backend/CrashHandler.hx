package mobile.backend;

import openfl.events.UncaughtErrorEvent;
import openfl.events.ErrorEvent;
import openfl.errors.Error;
import flixel.FlxSubState;
import substates.ErrorSubState;
import states.MainMenuState;
#if sys
import sys.FileSystem;
import sys.io.File;
#end

using StringTools;
using backend.CoolUtil;

/**
 * Crash Handler.
 * @author YoshiCrafter29, Ne_Eo and MAJigsaw77
 */
class CrashHandler
{
	public static function init():Void
	{
		openfl.Lib.current.loaderInfo.uncaughtErrorEvents.addEventListener(UncaughtErrorEvent.UNCAUGHT_ERROR, onUncaughtError);
		#if cpp
		untyped __global__.__hxcpp_set_critical_error_handler(onError);
		#elseif hl
		hl.Api.setErrorHandler(onError);
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
		var stack = haxe.CallStack.exceptionStack();
		var stackLabelArr:Array<String> = [];
		var stackLabel:String = "";
		var errorText:String = "Oh Shit!";
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
			if (!FileSystem.exists('crash'))
				FileSystem.createDirectory('crash');
			var saveError = '$m\n$stackLabel';

			File.saveContent('crash/' + Date.now().toString().replace(' ', '-').replace(':', "'") + '.txt', saveError);
			errorText = Std.string(saveError);
			FlxG.state.openSubState(new ErrorSubState(errorText));
		}
		catch (e:haxe.Exception)
			trace('Couldn\'t save error message. (${e.message})');
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
