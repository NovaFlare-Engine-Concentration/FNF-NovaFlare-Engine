package scripts.hscript;

import flixel.FlxBasic;
import general.backend.DeepDebugTracker;

#if LUA_ALLOWED
import scripts.lua.FunkinLua;
#end

import scripts.lua.LuaUtils;
import scripts.lua.CustomSubstate;

import games.objects.Character;

#if HSCRIPT_ALLOWED
import crowplexus.iris.Iris;
import crowplexus.hscript.Tools;
import crowplexus.hscript.Expr;
import crowplexus.hscript.Parser;
import crowplexus.hscript.Interp;
import crowplexus.hscript.Printer;
import crowplexus.hscript.ISharedScript;

import scripts.stages.modules.ScriptedModuleNotify;
import scripts.stages.modules.ModuleAgency;

class HScript implements ISharedScript {
	public static var instances: Map<String, HScript> = new Map<String, HScript>();

	public var standard(get, never): Dynamic;

	public function get_standard(): Dynamic {
		return this;
	}

	public var active: Bool;
	public var loaded: Bool;

	public var filePath(default, null): String;
	public var modFolder: String;
	public var origin(default, null): String;

	private var withoutExtension: String;
	var manualRun: Bool;

	var scriptCode(default, null): Null<String>;
	var expr: Expr;
	var interp: Interp;
	var parser: Parser;

	public function new(file: String, ?parent: Dynamic, ?manualRun: Bool = false) {
		active = true;

		filePath = file;
		withoutExtension = haxe.io.Path.withoutExtension(file);
		origin = Mods.toDisplayPath(file);
		#if MODS_ALLOWED
		var myFolder: Array<String> = filePath.split('/');
		if (myFolder.contains("mods")) {
			var indexPack = myFolder.indexOf("mods") + 1;
			if (myFolder[indexPack] != null
				&& (Mods.currentModDirectory == myFolder[indexPack] || Mods.getGlobalMods().contains(myFolder[indexPack]))) {
				this.modFolder = myFolder[indexPack];
			}
		}
		#end

		interp = new Interp();
		interp.importHandler = _importHandler;
		parser = new Parser();
		parser.preprocesorValues = crowplexus.iris.macro.DefineMacro.defines;
		parser.allowTypes = parser.allowMetadata = parser.allowInterpolation = parser.allowJSON = true;
		preset(parent);

		loadFile();
		if (expr != null)
			DeepDebugTracker.recordScript('HScript', filePath);
		this.manualRun = manualRun;
		if (this.manualRun)
			execute();

		if (!instances.exists(this.withoutExtension))
			instances.set(this.withoutExtension, this);
	}

	public function execute(): Dynamic {
		var ret: Dynamic = null;
		if (active && expr != null && !loaded) {
			try {
				ret = interp.execute(expr);
				loaded = true;
			}
			#if hscriptPos
			catch (e:Error) {
				Iris.error(Printer.errorToString(e, false), cast {fileName: e.origin, lineNumber: e.line});
				active = false;
			}
			#end
		catch (e)
			{
				Iris.error(Std.string(e), cast this.interp.posInfos());
				active = false;
			}
		}
		return ret;
	}

	public function get(name: String): Dynamic {
		if (active && interp.directorFields.get(name) != null)
			return interp.directorFields.get(name).value;
		else
			return interp.variables.get(name);
	}

	public function exists(name: String): Bool {
		return active && (interp.variables.exists(name) || interp.directorFields.get(name) != null);
	}

	public function matchesFile(path:String):Bool {
		final currentPath = haxe.io.Path.normalize(#if sys sys.FileSystem.absolutePath(filePath) #else filePath #end);
		final requestedPath = haxe.io.Path.normalize(#if sys sys.FileSystem.absolutePath(path) #else path #end);
		return #if windows currentPath.toLowerCase() == requestedPath.toLowerCase() #else currentPath == requestedPath #end;
	}

	public inline function checkType(name: String): Null<String> {
		if (active && interp.directorFields.get(name) != null) {
			return interp.directorFields.get(name).type;
		}
		return null;
	}

	public function call(name: String, ?args: Array<Dynamic>, ?excludeVar: Bool = true): Dynamic {
		var ret: Dynamic = null;
		if (active && exists(name)) {
			final func = get(name);
			if ((checkType(name) == "func" || excludeVar) && Reflect.isFunction(func)) {
				try {
					ret = Reflect.callMethod(null, func, (args == null ? [] : args));
				}
				#if hscriptPos
				catch (e:Error) {
					Iris.error(Printer.errorToString(e, false), cast {fileName: e.origin, lineNumber: e.line});
					active = false;
				}
				#end
			catch (e)
				{
					Iris.error(Std.string(e), cast #if hscriptPos this.interp.posInfos() #else cast {fileName: this.origin, lineNumber: 0} #end);
					active = false;
				}
			} else {
				Iris.error("Invalid Function -> " + '"' + name + '"');
			}
		}
		return ret;
	}

	public function set(name: String, value: Dynamic) {
		if (active) {
			if (value is Class || value is Enum)
				interp.imports.set(name, value);
			else
				interp.variables.set(name, value);
		}
	}

	public function destroy() {
		active = false;

		if (instances.exists(this.withoutExtension))
			instances.remove(this.withoutExtension);

		interp = null;
		parser = null;
		expr = null;
	}

	function loadFile() {
		if (!active)
			return;

		#if MODS_ALLOWED
		if (FileSystem.exists(filePath)) {
			scriptCode = try {
				File.getContent(filePath);
			} catch (e) {
				Iris.warn('Invalid Expected File Path -> "$filePath"', cast {fileName: this.origin, lineNumber: 0});
				null;
			}
		} else {
			Iris.warn('This File Path Was Not Exist -> "$filePath"', cast {fileName: this.origin, lineNumber: 0});
		}
		#else
		if (openfl.Assets.exists(filePath)) {
			scriptCode = try {
				openfl.Assets.getText(filePath);
			} catch (e) {
				Iris.warn('Invalid Expected This File Path -> "$filePath"', cast {fileName: this.origin, lineNumber: 0});
				null;
			}
		} else {
			Iris.warn('This File Path Was Not Exist -> "$filePath"', cast {fileName: this.origin, lineNumber: 0});
		}
		#end

		if (scriptCode != null && scriptCode.trim() != '') {
			try {
				expr = parser.parseString(scriptCode, this.origin);
			}
			#if hscriptPos
			catch (e:Error) {
				Iris.error(Printer.errorToString(e, false), cast {fileName: e.origin, lineNumber: e.line});
				active = false;
			}
			#end
		catch (e)
			{
				Iris.error(Std.string(e), cast {fileName: this.origin, lineNumber: 0});
				active = false;
			}
		}
	}

	public function hget(name: String, ?e: Expr): Dynamic {
		if (active && exists(name)) {
			var field = interp.directorFields.get(name);
			@:privateAccess
			if (interp.propertyLinks.get(name) != null && field.isPublic) {
				var l = interp.propertyLinks.get(name);
				if (l.inState)
					return l.get(name);
				else
					return l.link_getFunc();
			}

			if (field.isPublic)
				return field.value;
			else
				Iris.warn("This Script -> '" + this.origin + "', its field -> '" + name + "' is not public",
					cast #if hscriptPos (e != null ? {fileName: e.origin, lineNumber: e.line} : {fileName: "hscript",
						lineNumber: 0}) #else {fileName: "hscript", lineNumber: 0} #end);
		} else if (active && !exists(name)) {
			Iris.warn("This Script -> '" + this.origin + "' has not field -> '" + name + "'",
				cast #if hscriptPos (e != null ? {fileName: e.origin, lineNumber: e.line} : {fileName: "hscript", lineNumber: 0}) #else {fileName: "hscript",
					lineNumber: 0} #end);
		}

		return null;
	}

	public function hset(name: String, value: Dynamic, ?e: Expr): Void {
		if (active && interp != null && exists(name)) {
			var field = interp.directorFields.get(name);
			@:privateAccess
			if (interp.propertyLinks.get(name) != null && field.isPublic) {
				var l = interp.propertyLinks.get(name);
				if (l.inState)
					l.set(name, value);
				else
					l.link_setFunc(value);
				return;
			}

			if (field.isPublic)
				field.value = value;
			else
				Iris.warn("This Script -> '" + this.origin + "', its field -> '" + name + "' is not public",
					cast #if hscriptPos (e != null ? {fileName: e.origin, lineNumber: e.line} : {fileName: "hscript",
						lineNumber: 0}) #else {fileName: "hscript", lineNumber: 0} #end);
		} else if (interp != null && !exists(name)) {
			Iris.warn("This Script -> '" + this.origin + "' has not field -> '" + name + "'",
				cast #if hscriptPos (e != null ? {fileName: e.origin, lineNumber: e.line} : {fileName: "hscript", lineNumber: 0}) #else {fileName: "hscript",
					lineNumber: 0} #end);
		}
	}

	@:noCompletion
	private function _importHandler(s: String, as: String, ?star: Bool): Bool {
		var path: String = #if MODS_ALLOWED Paths.mods() + #end
		s.replace(".", "/");
		if (instances.exists(path)) {
			var sc: HScript = instances.get(path);
			if (sc.active) {
				this.interp.imports.set((as != null && as.trim() != "" ? as : Tools.last(s.split("."))), sc);
				return true;
			}
		} else {
			final last = s.lastIndexOf(".");
			final p = (star == true ? s : s.substr(0, last > -1 ? last : 0));
			#if STAR_CLASSES
			if (star == true) {
				@:privateAccess if (ScriptedModuleNotify.classSystems.exists(p)) {
					for (m in ScriptedModuleNotify.classSystems.get(p)) {
						for (id => cl in m.unusedClasses) {
							if (m._preClassesName.contains(id))
								m.unusedClasses.remove(id);
							m.__interp.execute(cl);
						}
					}
				}
			} else
			#end
			{
				final cn = (star == true ? "" : s.substr(last > -1 ? last + 1 : 0));
				@:privateAccess if (ScriptedModuleNotify.classSystems.exists(p)) {
					for (m in ScriptedModuleNotify.classSystems.get(p)) {
						if (m.unusedClasses.exists(cn)) {
							m.__interp.execute(m.unusedClasses.get(cn));
							break;
						}
					}
				}
			}
		}
		return false;
	}

	function preset(parent: Dynamic) {
		// Some very commonly used classes
		// set('Type', Type);
		if (parent != null)
			this.interp.parentInstance = parent;
		set("Application", lime.app.Application);
		#if sys
		set('File', File);
		set('FileSystem', FileSystem);
		#end
		set("Json", haxe.Json);
		set('FlxG', flixel.FlxG);
		set('FlxMath', flixel.math.FlxMath);
		set('FlxSprite', flixel.FlxSprite);
		set('FlxText', flixel.text.FlxText);
		set('FlxCamera', flixel.FlxCamera);
		set('PsychCamera', general.backend.PsychCamera);
		set('FlxTimer', flixel.util.FlxTimer);
		set('FlxTween', flixel.tweens.FlxTween);
		set('FlxEase', flixel.tweens.FlxEase);
		set('FlxColor', crowplexus.hscript.proxy.flixel.util.ProxyFlxColor);
		set('Countdown', games.stages.base.BaseStage.Countdown);
		set('PlayState', PlayState);
		set('Paths', Paths);
		// set('StorageUtil', StorageUtil); //nf引擎不支持这个玩意
		set('Conductor', Conductor);
		set('ClientPrefs', ClientPrefs);
		#if ACHIEVEMENTS_ALLOWED
		set('Achievements', Achievements);
		#end
		set('Character', Character);
		set('Alphabet', Alphabet);
		set('Note', games.objects.Note);
		set('CustomSubstate', CustomSubstate);
		#if (!flash && sys)
		set('FlxRuntimeShader', flixel.addons.display.FlxRuntimeShader);
		set('ErrorHandledRuntimeShader', general.shaders.ErrorHandledShader.ErrorHandledRuntimeShader);
		#end
		set('ShaderFilter', openfl.filters.ShaderFilter);
		// set('StringTools', StringTools);
		#if flxanimate
		set('FlxAnimate', FlxAnimate);
		#end

		// scriptedclass
		set("ScriptedBaseStage", scripts.scriptClasses.ScriptedBaseStage);
		set('ScriptedSprite', scripts.scriptClasses.ScriptedSprite);
		set('ScriptedGroup', scripts.scriptClasses.ScriptedGroup);
		set('ScriptedSpriteGroup', scripts.scriptClasses.ScriptedSpriteGroup);

		set('ScriptedState', scripts.scriptClasses.ScriptedState);
		set('ScriptedSubstate', scripts.scriptClasses.ScriptedSubstate);

		// custom state
		set("HScriptState", scripts.stages.HScriptState);
		set("HScriptSubstate", scripts.stages.HScriptSubstate);

		if (parent is MusicBeatState) {
			set('setVar', function(name: String, value: Dynamic) {
				MusicBeatState.getVariables().set(name, value);
				return value;
			});
			set('getVar', function(name: String) {
				var result: Dynamic = null;
				if (MusicBeatState.getVariables().exists(name))
					result = MusicBeatState.getVariables().get(name);
				return result;
			});
			set('removeVar', function(name: String) {
				if (MusicBeatState.getVariables().exists(name)) {
					MusicBeatState.getVariables().remove(name);
					return true;
				}
				return false;
			});

			if (parent is PlayState) {
				cast(parent, PlayState).provideSongScriptGlobals(set);
				set('debugPrint', function(text: String, ?color: FlxColor = null) {
					if (color == null)
						color = FlxColor.WHITE;
					PlayState.instance.addTextToDebug(text, color);
				});

				set('keyboardJustPressed', function(name: String) {
					name = name.toUpperCase();
					return Reflect.getProperty(FlxG.keys.justPressed, name);
				});
				set('keyboardPressed', function(name: String) {
					name = name.toUpperCase();
					return Reflect.getProperty(FlxG.keys.pressed, name);
				});
				set('keyboardReleased', function(name: String) {
					name = name.toUpperCase();
					return Reflect.getProperty(FlxG.keys.justReleased, name);
				});

				#if LUA_ALLOWED
				set('createGlobalCallback', function(name: String, func: Dynamic) {
					for (script in PlayState.instance.luaArray)
						if (script != null && script.lua != null && !script.closed)
							Lua_helper.add_callback(script.lua, name, func);

					FunkinLua.customFunctions.set(name, func);
				});

				// this one was tested
				set('createCallback', function(name: String, func: Dynamic, ?funk: FunkinLua = null) {
					if (funk == null)
						return;

					if (funk != null)
						funk.addLocalCallback(name, func);
					else
						Iris.error('createCallback ($name): 3rd argument is null', this.interp.posInfos());
				});
				#end

				set('addHaxeLibrary', function(libName: String, ?libPackage: String = '') {
					try {
						var str: String = '';
						if (libPackage.length > 0)
							str = libPackage + '.';

						set(libName, Type.resolveClass(str + libName));
					} catch (e:Error) {
						Iris.error(Printer.errorToString(e, false), this.interp.posInfos());
					}
				});

				#if LUA_ALLOWED
				set("addVirtualPad", (DPadMode: String, ActionMode: String) -> {
					PlayState.instance.makeLuaVirtualPad(DPadMode, ActionMode);
					PlayState.instance.addLuaVirtualPad();
				});

				set("removeVirtualPad", () -> {
					PlayState.instance.removeLuaVirtualPad();
				});

				set("addVirtualPadCamera", () -> {
					if (PlayState.instance.luaVirtualPad == null) {
						Iris.error('addVirtualPadCamera: TPAD does not exist.', cast this.interp.posInfos());
						return;
					}
					PlayState.instance.addLuaVirtualPadCamera();
				});

				set("virtualPadJustPressed", function(button: Dynamic): Bool {
					if (PlayState.instance.luaVirtualPad == null) {
						// FunkinLua.luaTrace('virtualPadJustPressed: TPAD does not exist.');
						return false;
					}
					return PlayState.instance.luaVirtualPadJustPressed(button);
				});

				set("virtualPadPressed", function(button: Dynamic): Bool {
					if (PlayState.instance.luaVirtualPad == null) {
						// FunkinLua.luaTrace('virtualPadPressed: TPAD does not exist.');
						return false;
					}
					return PlayState.instance.luaVirtualPadPressed(button);
				});

				set("virtualPadJustReleased", function(button: Dynamic): Bool {
					if (PlayState.instance.luaVirtualPad == null) {
						// FunkinLua.luaTrace('virtualPadJustReleased: TPAD does not exist.');
						return false;
					}
					return PlayState.instance.luaVirtualPadJustReleased(button);
				});
				#end

				set('game', FlxG.state);
				set('controls', Controls.instance);
			}
		}

		// Functions & Variables
		set('getModSetting', function(saveTag: String, ?modName: String = null) {
			if (modName == null) {
				if (this.modFolder == null) {
					Iris.error('getModSetting: Argument #2 is null and script is not inside a packed Mod folder!', this.interp.posInfos());
					return null;
				}
				modName = this.modFolder;
			}
			return LuaUtils.getModSetting(saveTag, modName);
		});

		// Keyboard & Gamepads
		set('keyboardJustPressed', function(name: String) {
			// return Reflect.getProperty(FlxG.keys.justPressed, name);

			name = name.toLowerCase();
			switch (name) {
				case 'left':
					return Controls.instance.NOTE_LEFT_P;
				case 'down':
					return Controls.instance.NOTE_DOWN_P;
				case 'up':
					return Controls.instance.NOTE_UP_P;
				case 'right':
					return Controls.instance.NOTE_RIGHT_P;
				default:
					return Controls.instance.justPressed(name);
			}
			return false;
		});
		set('keyboardPressed', function(name: String) {
			// return Reflect.getProperty(FlxG.keys.pressed, name);

			switch (name) {
				case 'left':
					return Controls.instance.NOTE_LEFT;
				case 'down':
					return Controls.instance.NOTE_DOWN;
				case 'up':
					return Controls.instance.NOTE_UP;
				case 'right':
					return Controls.instance.NOTE_RIGHT;
				default:
					return Controls.instance.pressed(name);
			}
			return false;
		});
		set('keyboardReleased', function(name: String) {
			// return Reflect.getProperty(FlxG.keys.justReleased, name);

			switch (name) {
				case 'left':
					return Controls.instance.NOTE_LEFT_R;
				case 'down':
					return Controls.instance.NOTE_DOWN_R;
				case 'up':
					return Controls.instance.NOTE_UP_R;
				case 'right':
					return Controls.instance.NOTE_RIGHT_R;
				default:
					return Controls.instance.justReleased(name);
			}
			return false;
		});

		set('anyGamepadJustPressed', function(name: String) return FlxG.gamepads.anyJustPressed(name));
		set('anyGamepadPressed', function(name: String) FlxG.gamepads.anyPressed(name));
		set('anyGamepadReleased', function(name: String) return FlxG.gamepads.anyJustReleased(name));

		set('gamepadAnalogX', function(id: Int, ?leftStick: Bool = true) {
			var controller = FlxG.gamepads.getByID(id);
			if (controller == null)
				return 0.0;

			return controller.getXAxis(leftStick ? LEFT_ANALOG_STICK : RIGHT_ANALOG_STICK);
		});
		set('gamepadAnalogY', function(id: Int, ?leftStick: Bool = true) {
			var controller = FlxG.gamepads.getByID(id);
			if (controller == null)
				return 0.0;

			return controller.getYAxis(leftStick ? LEFT_ANALOG_STICK : RIGHT_ANALOG_STICK);
		});
		set('gamepadJustPressed', function(id: Int, name: String) {
			var controller = FlxG.gamepads.getByID(id);
			if (controller == null)
				return false;

			return Reflect.getProperty(controller.justPressed, name) == true;
		});
		set('gamepadPressed', function(id: Int, name: String) {
			var controller = FlxG.gamepads.getByID(id);
			if (controller == null)
				return false;

			return Reflect.getProperty(controller.pressed, name) == true;
		});
		set('gamepadReleased', function(id: Int, name: String) {
			var controller = FlxG.gamepads.getByID(id);
			if (controller == null)
				return false;

			return Reflect.getProperty(controller.justReleased, name) == true;
		});

		// For adding your own callbacks
		// not very tested but should work

		// set('this', this);

		set('buildTarget', LuaUtils.getBuildTarget());
		set('customSubstate', CustomSubstate.instance);
		set('customSubstateName', CustomSubstate.name);

		set('Function_Stop', LuaUtils.Function_Stop);
		set('Function_Continue', LuaUtils.Function_Continue);
		set('Function_StopLua', LuaUtils.Function_StopLua); // doesnt do much cuz HScript has a lower priority than Lua
		set('Function_StopHScript', LuaUtils.Function_StopHScript);
		set('Function_StopAll', LuaUtils.Function_StopAll);
	}
}
#end

