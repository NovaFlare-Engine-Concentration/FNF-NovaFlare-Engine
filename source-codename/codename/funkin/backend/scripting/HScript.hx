package codename.funkin.backend.scripting;

import hscript.*;
import hscript.Expr.Error;
import hscript.Parser;
import openfl.Assets;

class HScript extends Script {
	public var interp:Interp;
	public var parser:Parser;
	public var expr:Expr;
	public var code:String = null;
	//public var folderlessPath:String;
	var __importedPaths:Map<String, Bool>;

	public static function initParser() {
		var parser = new Parser();
		parser.allowJSON = parser.allowMetadata = parser.allowTypes = true;
		parser.preprocessorValues = Script.getDefaultPreprocessors();
		return parser;
	}

	/** Reuse idle parsers instead of constructing one for every script. */
	private static var __parserPool:Array<Parser> = [];
	private static function getParser():Parser {
		var parser = __parserPool.pop();
		if (parser == null) return initParser();
		parser.line = 1;
		return parser;
	}

	private static inline function returnParser(parser:Parser):Void {
		if (parser != null) __parserPool.push(parser);
	}

	public override function onCreate(path:String) {
		super.onCreate(path);

		interp = new Interp();
		// Legacy mods also read static fields through live instances.
		interp.useRedirects = true;

		try {
			if(Assets.exists(rawPath)) code = Assets.getText(rawPath);
		} catch(e) Logs.error('Error while reading $path: ${Std.string(e)}');

		parser = getParser();
		//folderlessPath = Path.directory(path);
		__importedPaths = [path => true];

		interp.errorHandler = _errorHandler;
		interp.warnHandler = _warnHandler;
		interp.importFailedCallback = importFailedCallback;
		interp.staticVariables = Script.staticVariables;
		interp.allowStaticVariables = interp.allowPublicVariables = true;

		interp.variables.set("trace", Reflect.makeVarArgs((args) -> {
			var v:String = Std.string(args.shift());
			for (a in args) v += ", " + Std.string(a);
			this.trace(v);
		}));

		#if GLOBAL_SCRIPT
		codename.funkin.backend.scripting.GlobalScript.call("onScriptCreated", [this, "hscript"]);
		#end
		loadFromString(code);
	}

	public override function loadFromString(code:String) {
		try {
			code = normalizeCodeNameImports(code);
			if (code != null && code.length > 0)
				expr = registerAbstractImports(parser.parseString(code, fileName));
		} catch(e:Error) {
			_errorHandler(e);
		} catch(e) {
			_errorHandler(new Error(ECustom(e.toString()), 0, 0, fileName, 0));
		}

		return this;
	}

	static function normalizeCodeNameImports(code:String):String {
		if (code == null) return code;
		if (code.indexOf("funkin.") != -1) {
			var declaration = ~/\b(import|using|package|extends|implements)(\s+)funkin\./g;
			code = declaration.map(code, function(match:EReg):String {
				return match.matched(1) + match.matched(2) + "codename.funkin.";
			});
		}
		return LegacySyntaxCompat.normalizeUntypedCatch(code);
	}

	/** Resolve generated HScript abstract wrappers without per-type aliases. */
	function registerAbstractImports(expression:Expr):Expr {
		if (expression == null || interp == null) return expression;
		switch (hscript.Tools.expr(expression)) {
			case EImport(path, alias, isUsing):
				var resolved = resolveAbstractImport(path, isUsing == true);
				#if hscriptPos
				expression.e = EImport(resolved, alias, isUsing);
				#else
				return EImport(resolved, alias, isUsing);
				#end
			#if hscriptPos
			case ECast(value, _):
				registerAbstractImports(value);
			case EFunction(arguments, body, _, _):
				for (argument in arguments)
					if (argument.value != null) registerAbstractImports(argument.value);
				registerAbstractImports(body);
			#end
			default:
				#if hscriptPos
				hscript.Tools.iter(expression, function(child:Expr) registerAbstractImports(child));
				#else
				switch (hscript.Tools.expr(expression)) {
					case EBlock(expressions):
						for (index in 0...expressions.length) expressions[index] = registerAbstractImports(expressions[index]);
					default:
				}
				#end
		}
		return expression;
	}

	function resolveAbstractImport(originalPath:String, isUsing:Bool):String {
		var path = interp.getLocalImportRedirect(originalPath);
		if (interp.importBlocklist.contains(originalPath) || interp.importBlocklist.contains(path)) return originalPath;
		var wrapper = resolveAbstractWrapper(path);
		if (wrapper != null) {
			interp.localImportRedirects.set(path, Type.getClassName(wrapper));
			return originalPath;
		}
		if (isUsing) return originalPath;
		var separator = path.lastIndexOf(".");
		if (separator < 0) return originalPath;
		var parent = path.substr(0, separator);
		var originalParent = originalPath.substr(0, originalPath.lastIndexOf("."));
		var resolvedParent = interp.getLocalImportRedirect(parent);
		if (interp.importBlocklist.contains(originalParent) || interp.importBlocklist.contains(parent)
			|| interp.importBlocklist.contains(resolvedParent)) return originalPath;
		wrapper = resolveAbstractWrapper(resolvedParent);
		if (wrapper == null) return originalPath;
		var field = path.substr(separator + 1);
		var wrapperPath = Type.getClassName(wrapper);
		if (interp.importBlocklist.contains(wrapperPath) || interp.importBlocklist.contains(wrapperPath + "." + field)) return originalPath;
		var fields = Type.getClassFields(wrapper);
		return fields.contains(field) || fields.contains("get_" + field) ? wrapperPath + "." + field : originalPath;
	}

	static function resolveAbstractWrapper(path:String):Class<Dynamic> {
		var wrapper = Type.resolveClass(path + "_HSC");
		if (wrapper != null) return wrapper;
		var parts = path.split(".");
		if (parts.length < 2) return null;
		parts.splice(parts.length - 2, 1);
		return Type.resolveClass(parts.join(".") + "_HSC");
	}

	private function importFailedCallback(cl:Array<String>, ?asName:String):Bool {
		if(_importFailedCallback(cl, "source/") || _importFailedCallback(cl, "")) {
			return true;
		}
		return false;
	}
	private function _importFailedCallback(cl:Array<String>, prefix:String):Bool {
		var assetsPath = 'assets/$prefix${cl.join("/")}';
		for(hxExt in ["hx", "hscript", "hsc", "hxs"]) {
			var p = '$assetsPath.$hxExt';
			if (__importedPaths.exists(p))
				return true; // no need to reimport again
			if (Assets.exists(p)) {
				var code = Assets.getText(p);
				var expr:Expr = null;
				try {
					if (code != null && code.length > 0) {
						code = normalizeCodeNameImports(code);
						parser.line = 1; // fun fact: this is all you need to reuse a parser without issues. all the other vars get reset on parse.
						expr = registerAbstractImports(parser.parseString(code, cl.join("/") + "." + hxExt));
					}
				} catch(e:Error) {
					_errorHandler(e);
				} catch(e) {
					_errorHandler(new Error(ECustom(e.toString()), 0, 0, fileName, 0));
				}
				if (expr != null) {
					@:privateAccess
					interp.exprReturn(expr);
					__importedPaths.set(p, true);
				}
				return true;
			}
		}
		return false;
	}

	private function _errorHandler(error:Error) {
		var fileName = error.origin;
		var oldfn = '$fileName:${error.line}: ';
		if(remappedNames.exists(fileName))
			fileName = remappedNames.get(fileName);
		var fn = '$fileName:${error.line}: ';
		var err = error.toString();
		while(err.startsWith(oldfn) || err.startsWith(fn)) {
			if (err.startsWith(oldfn)) err = err.substr(oldfn.length);
			if (err.startsWith(fn)) err = err.substr(fn.length);
		}

		Logs.traceColored([
			Logs.logText(fn, GREEN),
			Logs.logText(err, RED)
		], ERROR);
	}

	private function _warnHandler(error:Error) {
		var fileName = error.origin;
		var oldfn = '$fileName:${error.line}: ';
		if(remappedNames.exists(fileName))
			fileName = remappedNames.get(fileName);
		var fn = '$fileName:${error.line}: ';
		var err = error.toString();
		while(err.startsWith(oldfn) || err.startsWith(fn)) {
			if (err.startsWith(oldfn)) err = err.substr(oldfn.length);
			if (err.startsWith(fn)) err = err.substr(fn.length);
		}

		Logs.traceColored([
			Logs.logText(fn, GREEN),
			Logs.logText(err, YELLOW)
		], WARNING);
	}

	private var guardedPlayStateAdd:Dynamic;
	private var warnedInvalidPlayStateAdd:Bool = false;

	/** Avoid an unsafe native cast when legacy scripts pass non-FlxBasic values. */
	public static function safeStateAdd(state:flixel.FlxState, value:Dynamic):Dynamic {
		if (value == null || !Std.isOfType(value, flixel.FlxBasic)) return null;
		return state.add(cast value);
	}

	public override function setParent(parent:Dynamic) {
		if (guardedPlayStateAdd != null && interp.variables.get("add") == guardedPlayStateAdd)
			interp.variables.remove("add");
		guardedPlayStateAdd = null;
		interp.scriptObject = parent;
		if (Std.isOfType(parent, codename.funkin.game.PlayState) && !interp.variables.exists("add")) {
			var state:flixel.FlxState = cast parent;
			guardedPlayStateAdd = function(value:Dynamic):Dynamic {
				if (value != null && !Std.isOfType(value, flixel.FlxBasic) && !warnedInvalidPlayStateAdd) {
					warnedInvalidPlayStateAdd = true;
					Logs.warn('Ignoring non-FlxBasic add() argument from $fileName');
				}
				return safeStateAdd(state, value);
			};
			interp.variables.set("add", guardedPlayStateAdd);
		}
		interp.invalidateCache();
	}

	public override function onLoad() {
		@:privateAccess
		interp.execute(parser.mk(EBlock([]), 0, 0));
		if (expr != null) {
			interp.execute(expr);
			call("new", []);
		}

		#if GLOBAL_SCRIPT
		codename.funkin.backend.scripting.GlobalScript.call("onScriptSetup", [this, "hscript"]);
		#end
	}

	public override function reload() {
		// save variables

		interp.allowStaticVariables = interp.allowPublicVariables = false;
		var savedVariables:Map<String, Dynamic> = [];
		var defaultVars = Script.getDefaultVariables(this);
		for(k=>e in interp.variables) {
			if (!Reflect.isFunction(e) && !defaultVars.exists(k)) {
				savedVariables[k] = e;
			}
		}
		var oldParent = interp.scriptObject;
		var oldPublicVariables = interp.publicVariables;
		var oldImportScript = interp.variables.get("importScript");
		returnParser(parser);
		onCreate(path);

		for(k=>e in defaultVars)
			set(k, e);
		setPublicMap(oldPublicVariables);
		if (oldImportScript != null) set("importScript", oldImportScript);
		set("disableScript", () -> { active = false; });
		set("__script__", this);
		setParent(oldParent);
		// The original Script instance was already loaded. The new interpreter
		// must execute once with its parent and shared variables in place.
		@:privateAccess this.didLoad = false;
		load();

		for(k=>e in savedVariables)
			interp.variables.set(k, e);
		interp.invalidateCache();

		interp.allowStaticVariables = interp.allowPublicVariables = true;
	}

	private override function onCall(funcName:String, parameters:Array<Dynamic>):Dynamic {
		if (interp == null) return null;

		var func = interp.variables.get(funcName);
		if (func != null && Reflect.isFunction(func))
			return Reflect.callMethod(null, func, parameters == null ? Script._EMPTY_ARGS : parameters);

		return null;
	}

	public override function get(val:String):Dynamic {
		return interp.variables.get(val);
	}

	public override function set(val:String, value:Dynamic) {
		interp.variables.set(val, value);
		// Runtime variables may shadow a cached type-resolution miss.
		interp.invalidateCache();
	}

	public override function trace(v:Dynamic) {
		var posInfo = interp.posInfos();
		Logs.traceColored([
			Logs.logText('${fileName}:${posInfo.lineNumber}: ', GREEN),
			Logs.logText(Std.isOfType(v, String) ? v : Std.string(v))
		], TRACE);
	}

	public override function setPublicMap(map:Map<String, Dynamic>) {
		this.interp.publicVariables = map;
		interp.invalidateCache();
	}

	override public function destroy() {
		returnParser(parser);
		parser = null;
		interp = null;
		super.destroy();
	}
}
