package scripts.hscript;

import flixel.FlxBasic;

#if LUA_ALLOWED
import scripts.lua.FunkinLua;
#end

import scripts.lua.LuaUtils;
import scripts.lua.CustomSubstate;

import games.objects.Character;

#if HSCRIPT_ALLOWED
import haxe.Exception;
import haxe.ValueException;

import crowplexus.hscript.Interp;
import crowplexus.hscript.Expr;
import crowplexus.hscript.Parser;

#if (LUA_ALLOWED && cpp && (windows || android))
private typedef NativeHScriptSnapshotEntry =
{
	var code:String;
	var where:String;
	var context:String;
	var func:String;
	var slot:Int;
	var snapshot:String;
}
#end

class HScriptBase
{
	public static var parser:Parser = new Parser();
	public static var syntaxFixEnabled:Bool = true;
	private static var _syntaxFixRegex:EReg = ~/(\bvar\s+)?(\b[a-zA-Z0-9_]+)\s*=\s*new\s+([a-zA-Z0-9_]+)/g;

	public static function fixSyntax(code:String):String
	{
		if (!syntaxFixEnabled) return code;
		return _syntaxFixRegex.replace(code, "var $2:$3 = new $3");
	}

	/**
	 * HScript 脚本报错出口 —— 受「设置 › 维护设置 › HScript 语法错误提示」控制
	 * （ClientPrefs.hscriptErrorOverlay，默认关闭），与 Lua 那个开关各自独立。
	 *
	 * 只给**脚本报错**用（runHaxeCode 执行抛错、addHaxeLibrary 解析失败）。
	 * ★ HScript 的 debugPrint 走 FunkinLua.luaTrace → PlayState.addTextToDebug，**不经过这里**，
	 *   所以写 HScript 时调 debugPrint 绝不会被这个开关吞掉。
	 * ★「HScript isn't supported on this platform」这类**平台能力提示**也刻意不走这里，保持常显。
	 *
	 * 注意：HScript 脚本自身的报错（Iris.error / Iris.warn）根本不在这条链上 ——
	 * 它们走 Iris.logLevel → Sys.println + 开发者控制台 + 1145 trace 客户端，本来就不上屏。
	 */
	public static function reportHScriptError(text:String):Void
	{
		if (PlayState.instance != null)
			PlayState.instance.addHScriptErrorToDebug(text);
		else
			trace(text);
	}

	public var interp:Interp;

	public var variables(get, never):Map<String, Dynamic>;
	public var parentLua:FunkinLua;

	private static function resolveLuaContext(funk:FunkinLua):String
	{
		return (funk.lastCalledFunction != null && funk.lastCalledFunction != '') ? funk.lastCalledFunction : '<unknown-lua-function>';
	}

	#if (LUA_ALLOWED && cpp && (windows || android))
	private static final NATIVE_SOURCE_PREVIEW_CHARS:Int = 1024;
	private static final NATIVE_SOURCE_PREVIEW_LINES:Int = 24;
	private static final NATIVE_SNAPSHOT_CACHE_LIMIT:Int = 32;
	private static final NATIVE_FUNCTION_SNAPSHOT_CACHE_LIMIT:Int = 32;
	public var activeNativeSnapshotSlot(default, null):Int = -1;
	public var activeNativeSnapshotText(default, null):String = null;
	private var nativeSnapshotCache:Array<NativeHScriptSnapshotEntry> = [];
	private var nativeFunctionOrigins:Map<String, NativeHScriptSnapshotEntry> = [];
	private var nativeFunctionSnapshotSlots:Map<String, Int> = [];
	private var nativeFunctionSnapshotTexts:Map<String, String> = [];
	private var nativeFunctionSnapshotCount:Int = 0;

	/**
	 * Registers each dynamic source only once. Repeated execution uses an
	 * immutable native slot and only switches a thread-local integer.
	 */
	private function getNativeExecutionSnapshot(funk:FunkinLua, where:String, codeToRun:String, funcToRun:String):NativeHScriptSnapshotEntry
	{
		var context = resolveLuaContext(funk);
		for (entry in nativeSnapshotCache)
			if (entry.code == codeToRun
				&& entry.where == where
				&& entry.context == context
				&& entry.func == funcToRun)
				return entry;

		// Bound both native storage and retained mod source strings. Extremely
		// dynamic code still runs normally; it simply falls back to RVA/minidump.
		if (nativeSnapshotCache.length >= NATIVE_SNAPSHOT_CACHE_LIMIT)
			return null;

		var snapshot = buildNativeExecutionSnapshot(funk, context, where, codeToRun, funcToRun);
		var slot = general.backend.NativeCrashHandler.registerHaxeRuntimeSnapshot(snapshot);
		if (slot < 0)
			return null;

		var entry:NativeHScriptSnapshotEntry = {
			code: codeToRun,
			where: where,
			context: context,
			func: funcToRun,
			slot: slot,
			snapshot: snapshot
		};
		nativeSnapshotCache.push(entry);
		return entry;
	}

	private static function buildNativeExecutionSnapshot(funk:FunkinLua, context:String, where:String, codeToRun:String, funcToRun:String):String
	{

		var snapshot = 'active_context=runHaxeCode\nscript=${funk.scriptName}\nlua_function=$context\ncallsite=$where';
		if (funcToRun != null && funcToRun.length > 0)
			snapshot += '\nhscript_function=$funcToRun';

		if (codeToRun == null)
			return snapshot + '\n[hscript_source_preview]\n<null>';

		var sourceTruncated = codeToRun.length > NATIVE_SOURCE_PREVIEW_CHARS;
		var boundedSource = sourceTruncated ? codeToRun.substr(0, NATIVE_SOURCE_PREVIEW_CHARS) : codeToRun;
		var normalized = StringTools.replace(StringTools.replace(boundedSource, "\r\n", "\n"), "\r", "\n");
		var lines = normalized.split("\n");
		var preview:Array<String> = [];
		var usedChars:Int = 0;
		var count:Int = lines.length < NATIVE_SOURCE_PREVIEW_LINES ? lines.length : NATIVE_SOURCE_PREVIEW_LINES;
		for (index in 0...count)
		{
			var prefix = '${index + 1}| ';
			var remaining = NATIVE_SOURCE_PREVIEW_CHARS - usedChars - prefix.length;
			if (remaining <= 0)
				break;
			var line = lines[index];
			if (line.length > remaining)
				line = line.substr(0, remaining);
			preview.push(prefix + line);
			usedChars += prefix.length + line.length + 1;
		}
		if (sourceTruncated || count < lines.length || usedChars >= NATIVE_SOURCE_PREVIEW_CHARS)
			preview.push('[source preview truncated]');

		return snapshot + '\n[hscript_source_preview]\n' + preview.join("\n");
	}

	/**
	 * Wrap only callbacks created by dynamic HScript. This keeps snapshot lookup
	 * out of CallbackHandler, which is shared by every built-in Lua API call.
	 */
	private function wrapPersistentCallbackSnapshot(func:Dynamic, name:String):Dynamic
	{
		if (func == null || activeNativeSnapshotText == null || activeNativeSnapshotSlot < 0)
			return func;
		var snapshotText = activeNativeSnapshotText + '\nactive_callback=' + name;
		var slot = general.backend.NativeCrashHandler.registerHaxeRuntimeSnapshot(snapshotText);
		if (slot < 0)
		{
			slot = activeNativeSnapshotSlot;
			snapshotText = activeNativeSnapshotText;
		}

		return Reflect.makeVarArgs(function(args:Array<Dynamic>):Dynamic
		{
			var previousActiveSlot = activeNativeSnapshotSlot;
			var previousActiveText = activeNativeSnapshotText;
			activeNativeSnapshotSlot = slot;
			activeNativeSnapshotText = snapshotText;
			var previous = general.backend.NativeCrashHandler.enterHaxeRuntimeSnapshot(slot);
			try
			{
				var result = Reflect.callMethod(null, func, args);
				general.backend.NativeCrashHandler.leaveHaxeRuntimeSnapshot(previous);
				activeNativeSnapshotSlot = previousActiveSlot;
				activeNativeSnapshotText = previousActiveText;
				return result;
			}
			catch (error:Dynamic)
			{
				general.backend.NativeCrashHandler.leaveHaxeRuntimeSnapshot(previous);
				activeNativeSnapshotSlot = previousActiveSlot;
				activeNativeSnapshotText = previousActiveText;
				throw error;
			}
		});
	}

	private function captureNativeFunctions():Map<String, Dynamic>
	{
		var functions:Map<String, Dynamic> = [];
		for (name => value in interp.variables)
			if (Reflect.isFunction(value))
				functions.set(name, value);
		return functions;
	}

	private function rememberNativeFunctionOrigins(before:Map<String, Dynamic>, source:NativeHScriptSnapshotEntry):Void
	{
		if (before == null || source == null)
			return;

		for (name => oldValue in before)
		{
			var current = interp.variables.get(name);
			if (!Reflect.isFunction(current))
			{
				nativeFunctionOrigins.remove(name);
				nativeFunctionSnapshotSlots.remove(name);
				nativeFunctionSnapshotTexts.remove(name);
			}
		}

		for (name => value in interp.variables)
		{
			if (!Reflect.isFunction(value))
				continue;
			if (!before.exists(name) || before.get(name) != value)
			{
				nativeFunctionOrigins.set(name, source);
				nativeFunctionSnapshotSlots.remove(name);
				nativeFunctionSnapshotTexts.remove(name);
			}
		}
	}

	private function getNativeFunctionSnapshotSlot(name:String):Int
	{
		if (name == null || name.length == 0)
			return -1;
		if (nativeFunctionSnapshotSlots.exists(name))
			return nativeFunctionSnapshotSlots.get(name);

		var origin = nativeFunctionOrigins.get(name);
		if (origin == null)
			return -1;
		if (nativeFunctionSnapshotCount >= NATIVE_FUNCTION_SNAPSHOT_CACHE_LIMIT)
			return origin.slot;
		var displayName = StringTools.replace(StringTools.replace(name, "\r", ""), "\n", "");
		if (displayName.length > 128)
			displayName = displayName.substr(0, 128);
		var snapshotText = origin.snapshot + '\nexecution_phase=runHaxeFunction\nactive_hscript_function=' + displayName;
		var registeredSlot = general.backend.NativeCrashHandler.registerHaxeRuntimeSnapshot(snapshotText);
		var slot = registeredSlot;
		if (slot < 0)
			slot = origin.slot;
		nativeFunctionSnapshotSlots.set(name, slot);
		nativeFunctionSnapshotTexts.set(name, registeredSlot >= 0 ? snapshotText : origin.snapshot);
		nativeFunctionSnapshotCount++;
		return slot;
	}

	private function getNativeFunctionSnapshotText(name:String):String
	{
		if (nativeFunctionSnapshotTexts.exists(name))
			return nativeFunctionSnapshotTexts.get(name);
		var origin = nativeFunctionOrigins.get(name);
		return origin != null ? origin.snapshot : null;
	}

	private function executeFunctionWithNativeSnapshot(name:String, args:Array<Dynamic>):Dynamic
	{
		var slot = getNativeFunctionSnapshotSlot(name);
		if (slot < 0)
			return executeFunction(name, args);

		var previousActiveSlot = activeNativeSnapshotSlot;
		var previousActiveText = activeNativeSnapshotText;
		activeNativeSnapshotSlot = slot;
		activeNativeSnapshotText = getNativeFunctionSnapshotText(name);
		var previous = general.backend.NativeCrashHandler.enterHaxeRuntimeSnapshot(slot);
		try
		{
			var result = executeFunction(name, args);
			general.backend.NativeCrashHandler.leaveHaxeRuntimeSnapshot(previous);
			activeNativeSnapshotSlot = previousActiveSlot;
			activeNativeSnapshotText = previousActiveText;
			return result;
		}
		catch (error:Dynamic)
		{
			general.backend.NativeCrashHandler.leaveHaxeRuntimeSnapshot(previous);
			activeNativeSnapshotSlot = previousActiveSlot;
			activeNativeSnapshotText = previousActiveText;
			throw error;
		}
	}
	#end

	public function get_variables()
	{
		return interp.variables;
	}

	public static function initHaxeModule(parent:FunkinLua)
	{
		#if HSCRIPT_ALLOWED
		if (parent.hscriptBase == null)
		{
			// trace('initializing haxe interp for: $scriptName');
			parent.hscriptBase = new HScriptBase(parent); // TO DO: Fix issue with 2 scripts not being able to use the same variable names
		}
		#end
	}

	public function new(parent:FunkinLua)
	{
		interp = new Interp();
		parentLua = parent;
		interp.variables.set('FlxG', flixel.FlxG);
		interp.variables.set('FlxSprite', flixel.FlxSprite);
		interp.variables.set('FlxCamera', flixel.FlxCamera);
		interp.variables.set('FlxTimer', flixel.util.FlxTimer);
		interp.variables.set('FlxTween', flixel.tweens.FlxTween);
		interp.variables.set('FlxEase', flixel.tweens.FlxEase);
		interp.variables.set('PlayState', PlayState);
		interp.variables.set('game', PlayState.instance);
		interp.variables.set('Paths', Paths);
		interp.variables.set('Conductor', Conductor);
		interp.variables.set('ClientPrefs', ClientPrefs);
		interp.variables.set('Character', Character);
		interp.variables.set('Alphabet', Alphabet);
		interp.variables.set('CustomSubstate', scripts.lua.CustomSubstate);
		#if (!flash && sys)
		interp.variables.set('FlxRuntimeShader', flixel.addons.display.FlxRuntimeShader);
		#end
		interp.variables.set('ShaderFilter', openfl.filters.ShaderFilter);
		interp.variables.set('StringTools', StringTools);

		interp.variables.set('setVar', function(name:String, value:Dynamic)
		{
			PlayState.instance.variables.set(name, value);
		});
		interp.variables.set('getVar', function(name:String)
		{
			var result:Dynamic = null;
			if (PlayState.instance.variables.exists(name))
				result = PlayState.instance.variables.get(name);
			return result;
		});
		interp.variables.set('removeVar', function(name:String)
		{
			if (PlayState.instance.variables.exists(name))
			{
				PlayState.instance.variables.remove(name);
				return true;
			}
			return false;
		});
		interp.variables.set('debugPrint', function(text:String, ?color:FlxColor = null)
		{
			if (color == null)
				color = FlxColor.WHITE;
			FunkinLua.luaTrace(text, true, false, color);
		});

		// For adding your own callbacks

		// not very tested but should work
		interp.variables.set('createGlobalCallback', function(name:String, func:Dynamic)
		{
			#if LUA_ALLOWED
			#if (cpp && (windows || android))
			func = wrapPersistentCallbackSnapshot(func, name);
			#end
			for (script in PlayState.instance.luaArray)
				if (script != null && script.lua != null && !script.closed)
					Lua_helper.add_callback(script.lua, name, func);
			#end
			FunkinLua.customFunctions.set(name, func);
		});

		// tested
		interp.variables.set('createCallback', function(name:String, func:Dynamic, ?funk:FunkinLua = null)
		{
			if (funk == null)
				funk = parentLua;
			#if (cpp && (windows || android))
			func = wrapPersistentCallbackSnapshot(func, name);
			#end
			funk.addLocalCallback(name, func);
		});

		interp.variables.set('addHaxeLibrary', function(libName:String, ?libPackage:String = '')
		{
			try
			{
				var str:String = '';
				if (libPackage.length > 0)
					str = libPackage + '.';

				interp.variables.set(libName, Type.resolveClass(str + libName));
			}
			catch (e:Dynamic)
			{
				FunkinLua.lastCalledScript = parent;
				reportHScriptError(parentLua.scriptName + ":" + resolveLuaContext(parentLua) + " - " + e);
			}
		});
		interp.variables.set('parentLua', parentLua);
	}

	public function execute(codeToRun:String, ?funcToRun:String = null, ?funcArgs:Array<Dynamic>):Dynamic
	{
		@:privateAccess
		HScriptBase.parser.line = 1;
		HScriptBase.parser.allowTypes = true;
		var expr:Expr = HScriptBase.parser.parseString(codeToRun);
		var value:Dynamic = interp.execute(expr);
		return (funcToRun != null) ? executeFunction(funcToRun, funcArgs) : value;
	}

	public function executeFunction(funcToRun:String = null, funcArgs:Array<Dynamic>)
	{
		if (funcToRun != null)
		{
			// trace('Executing $funcToRun');
			if (interp.variables.exists(funcToRun))
			{
				// trace('$funcToRun exists, executing...');
				if (funcArgs == null)
					funcArgs = [];
				return Reflect.callMethod(null, interp.variables.get(funcToRun), funcArgs);
			}
		}
		return null;
	}

	#if LUA_ALLOWED
	public static function implement(funk:FunkinLua)
	{
		var lua:State = funk.lua;
		funk.addLocalCallback("setHaxeSyntaxFix", function(enabled:Bool) {
			HScriptBase.syntaxFixEnabled = enabled;
		});
		funk.addLocalCallback("runHaxeCode",
			function(codeToRun:String, ?varsToBring:Any = null, ?funcToRun:String = null, ?funcArgs:Array<Dynamic> = null, ?callerFile:String = null, ?callerLine:Int = 0, ?callerFunction:String = null)
			{
				var retVal:Dynamic = null;
				var where:String = buildLuaCallSite(callerFile, callerLine, callerFunction, funk);

				#if HSCRIPT_ALLOWED
				#if (cpp && (windows || android))
				var nativeSnapshotEntered:Bool = false;
				var previousNativeSnapshot:Int = -1;
				var previousRegistrationSlot:Int = -1;
				var previousRegistrationText:String = null;
				var nativeFunctionsBefore:Map<String, Dynamic> = null;
				var nativeSnapshot:NativeHScriptSnapshotEntry = null;
				#end
				try
				{
					HScriptBase.initHaxeModule(funk);
					#if (cpp && (windows || android))
					nativeSnapshot = funk.hscriptBase.getNativeExecutionSnapshot(funk, where, codeToRun, funcToRun);
					if (nativeSnapshot != null)
					{
						previousRegistrationSlot = funk.hscriptBase.activeNativeSnapshotSlot;
						previousRegistrationText = funk.hscriptBase.activeNativeSnapshotText;
						funk.hscriptBase.activeNativeSnapshotSlot = nativeSnapshot.slot;
						funk.hscriptBase.activeNativeSnapshotText = nativeSnapshot.snapshot;
						previousNativeSnapshot = general.backend.NativeCrashHandler.enterHaxeRuntimeSnapshot(nativeSnapshot.slot);
						nativeSnapshotEntered = true;
					}
					#end
					codeToRun = HScriptBase.fixSyntax(codeToRun);
					if (varsToBring != null)
					{
						for (key in Reflect.fields(varsToBring))
						{
							// trace('Key $key: ' + Reflect.field(varsToBring, key));
							funk.hscriptBase.interp.variables.set(key, Reflect.field(varsToBring, key));
						}
					}
					#if (cpp && (windows || android))
					if (nativeSnapshot != null)
						nativeFunctionsBefore = funk.hscriptBase.captureNativeFunctions();
					#end
					retVal = funk.hscriptBase.execute(codeToRun, funcToRun, funcArgs);
					#if (cpp && (windows || android))
					if (nativeSnapshot != null)
						funk.hscriptBase.rememberNativeFunctionOrigins(nativeFunctionsBefore, nativeSnapshot);
					#end
				}
				catch (e:Dynamic)
				{
					#if (cpp && (windows || android))
					if (nativeSnapshot != null && nativeFunctionsBefore != null)
						funk.hscriptBase.rememberNativeFunctionOrigins(nativeFunctionsBefore, nativeSnapshot);
					if (nativeSnapshotEntered)
					{
						general.backend.NativeCrashHandler.leaveHaxeRuntimeSnapshot(previousNativeSnapshot);
						funk.hscriptBase.activeNativeSnapshotSlot = previousRegistrationSlot;
						funk.hscriptBase.activeNativeSnapshotText = previousRegistrationText;
						nativeSnapshotEntered = false;
					}
					#end
					reportHScriptError(funk.scriptName + ":" + resolveLuaContext(funk) + where + " - " + e);
				}
				#if (cpp && (windows || android))
				if (nativeSnapshotEntered)
				{
					general.backend.NativeCrashHandler.leaveHaxeRuntimeSnapshot(previousNativeSnapshot);
					funk.hscriptBase.activeNativeSnapshotSlot = previousRegistrationSlot;
					funk.hscriptBase.activeNativeSnapshotText = previousRegistrationText;
				}
				#end
				#else
				FunkinLua.luaTrace("runHaxeCode: HScript isn't supported on this platform!", false, false, FlxColor.RED);
				#end

				if (retVal != null && !LuaUtils.isOfTypes(retVal, [Bool, Int, Float, String, Array]))
					retVal = null;
				return retVal;
			});

		// Wrap Lua-side runHaxeCode to append callsite info (script file + line) for errors.
		var wrapperStatus:Int = LuaL.dostring(lua, "
	if runHaxeCode and not _G.__novaRunHaxeCodeWrapped then
	local __nova_runHaxeCode = runHaxeCode;
	runHaxeCode = function(codeToRun, varsToBring, funcToRun, funcArgs)
		local info = nil;
		local file = 'unknown';
		local line = 0;
		local name = nil;
		if type(debug) == 'table' and type(debug.getinfo) == 'function' then
			info = debug.getinfo(2, 'Sln');
		end;
		if info ~= nil then
			file = info.short_src;
			line = info.currentline or 0;
			name = info.name;
			return __nova_runHaxeCode(codeToRun, varsToBring, funcToRun, funcArgs, file, line, name);
		else
			return __nova_runHaxeCode(codeToRun, varsToBring, funcToRun, funcArgs, file, line, name);
		end;
	end;
	_G.__novaRunHaxeCodeWrapped = true;
end
");
		if (wrapperStatus != Lua.LUA_OK)
		{
			var wrapperError = Lua.tostring(lua, -1);
			Lua.pop(lua, 1);
			FunkinLua.luaTrace('Failed to install runHaxeCode diagnostic wrapper: $wrapperError', true, false, FlxColor.RED);
		}

		funk.addLocalCallback("runHaxeFunction", function(funcToRun:String, ?funcArgs:Array<Dynamic> = null)
		{
			try
			{
				HScriptBase.initHaxeModule(funk);
				#if (cpp && (windows || android))
				return funk.hscriptBase.executeFunctionWithNativeSnapshot(funcToRun, funcArgs);
				#else
				return funk.hscriptBase.executeFunction(funcToRun, funcArgs);
				#end
			}
			catch (e:Exception)
			{
				FunkinLua.luaTrace(Std.string(e));
				return null;
			}
		});

		funk.addLocalCallback("addHaxeLibrary", function(libName:String, ?libPackage:String = '')
		{
			#if HSCRIPT_ALLOWED
			HScriptBase.initHaxeModule(funk);
			try
			{
				var str:String = '';
				if (libPackage.length > 0)
					str = libPackage + '.';

				funk.hscriptBase.variables.set(libName, Type.resolveClass(str + libName));
			}
			catch (e:Dynamic)
			{
				reportHScriptError(funk.scriptName + ":" + resolveLuaContext(funk) + " - " + e);
			}
			#end
		});
	}

	private static function buildLuaCallSite(callerFile:String, callerLine:Int, callerFunction:String, funk:FunkinLua):String
	{
		var file:String = (callerFile == null || callerFile == '') ? "unknown" : callerFile;
		var line:String = (callerLine > 0) ? (':' + callerLine) : '';
		var func:String = (callerFunction != null && callerFunction != '') ? (' #' + callerFunction) : '';
		var callSite:String = '$file$line$func';
		if (callSite == 'unknown')
			callSite = funk.scriptName;
		return ' [' + callSite + ']';
	}
	#end
}
#else
class HScriptBase
{
	#if LUA_ALLOWED
	public static function implement(funk:FunkinLua)
	{
		funk.addLocalCallback("setHaxeSyntaxFix", function(enabled:Bool) {
			PlayState.instance.addTextToDebug('HScript is not supported on this platform!', FlxColor.RED);
		});
		funk.addLocalCallback("runHaxeCode",
			function(codeToRun:String, ?varsToBring:Any = null, ?funcToRun:String = null, ?funcArgs:Array<Dynamic> = null):Dynamic
			{
				PlayState.instance.addTextToDebug('HScript is not supported on this platform!', FlxColor.RED);
				return null;
			});
		funk.addLocalCallback("runHaxeFunction", function(funcToRun:String, ?funcArgs:Array<Dynamic> = null)
		{
			PlayState.instance.addTextToDebug('HScript is not supported on this platform!', FlxColor.RED);
			return null;
		});
		funk.addLocalCallback("addHaxeLibrary", function(libName:String, ?libPackage:String = '')
		{
			PlayState.instance.addTextToDebug('HScript is not supported on this platform!', FlxColor.RED);
			return null;
		});
	}
	#end
}
#end

