#if LUA_ALLOWED
package scripts.lua;

import general.backend.DeepDebugTracker;

import haxe.Json;

import openfl.Lib;
import openfl.utils.Assets;

#if (!flash && sys)
import flixel.addons.display.FlxRuntimeShader;
#end
import flixel.FlxBasic;
import flixel.FlxObject;
import flixel.input.keyboard.FlxKey;
import flixel.input.gamepad.FlxGamepadInputID;
import flixel.math.FlxMatrix;

import states.mainMenuState.MainMenuState;
import states.storyMenuState.StoryMenuState;
import states.freeplayState.FreeplayState;

import substates.PauseSubState;
import substates.GameOverSubstate;

#if HSCRIPT_ALLOWED
import scripts.hscript.HScriptBase;
#end

import scripts.lua.LuaUtils;
import scripts.lua.LuaUtils.LuaTweenOptions;
import scripts.lua.DebugLuaText;
import scripts.lua.ModchartSprite;

import games.backend.WeekData;
import games.backend.Highscore;
import games.backend.Song;
import games.cutscenes.DialogueBoxPsych;
import games.objects.StrumNote;
import games.objects.Note;
import games.objects.NoteSplash;
import games.objects.Character;

class FunkinLua
{
	public var lua:State = null;
	public var camTarget:FlxCamera;
	public var scriptName:String = '';
	public var modFolder:String = null;
	public var closed:Bool = false;

	#if HSCRIPT_ALLOWED
	public var hscriptBase:HScriptBase = null;
	#end

	public var callbacks:Map<String, Dynamic> = new Map<String, Dynamic>();
	private var reportedRuntimeErrors:Map<String, Bool> = new Map<String, Bool>();

	public static var customFunctions:Map<String, Dynamic> = new Map<String, Dynamic>();

	/**
	 * Lua 运行环境加固开关。
	 *
	 * LuaL.openlibs() 会打开 LuaJIT 的**全部**标准库，其中若干项对一个
	 * "只应该操作游戏对象"的 mod 脚本而言是纯粹的越权面：
	 *   - os.execute / os.exit          → 任意命令执行
	 *   - os.remove / os.rename         → 任意文件删除/改名
	 *   - io.popen                      → 命令执行
	 *   - package.loadlib / loaders[3]  → 加载任意 DLL
	 *   - debug.setupvalue/setfenv/sethook/getregistry → 篡改任意 upvalue、绕过下面的清理
	 *   - LuaJIT 的 ffi                 → require('ffi') 即拿到完整 FFI：
	 *                                     任意内存读写 + 调用任意已加载 DLL 的导出函数
	 *
	 * 刻意**保留** io.open / io.lines / require(纯 Lua 模块) 与 os.time/date/clock：
	 * 现有 mod 生态大量用它们读写自定义数据文件，一刀切掉会大面积破坏兼容性。
	 * 这里只封堵"代码执行 + 内存破坏 + 动态库加载"三类真正危险的通道。
	 */
	public static var sandboxEnabled:Bool = true;

	/** 设为 true 则进一步移除 io.* / require / load*，适用于"只跑可信 mod"的发行版。 */
	public static var sandboxStrict:Bool = false;

	static final SANDBOX_LUA:String = '
os.execute = nil
os.exit = nil
os.remove = nil
os.rename = nil
os.tmpname = nil
if io ~= nil then
	io.popen = nil
end
if package ~= nil then
	package.loadlib = nil
	if package.preload ~= nil then package.preload.ffi = nil end
	if package.loaded ~= nil then package.loaded.ffi = nil end
	if package.loaders ~= nil then
		package.loaders[3] = nil
		package.loaders[4] = nil
	end
end
if debug ~= nil then
	debug.setupvalue = nil
	debug.setfenv = nil
	debug.sethook = nil
	debug.getregistry = nil
end
if ffi ~= nil then ffi = nil end
';

	static final SANDBOX_STRICT_LUA:String = '
io = nil
require = nil
package = nil
dofile = nil
loadfile = nil
loadstring = nil
load = nil
';

	static function runSandboxChunk(lua:State, code:String):Void
	{
		var status:Int = LuaL.dostring(lua, code);
		if (status != Lua.LUA_OK)
		{
			var top:Int = Lua.gettop(lua);
			var err:String = (top > 0) ? Lua.tostring(lua, -1) : null;
			if (top > 0)
				Lua.pop(lua, top);
			trace('[FunkinLua] 沙箱加固脚本执行失败(status $status)：$err');
		}
	}

	static function applySandbox(lua:State):Void
	{
		if (!sandboxEnabled)
			return;
		runSandboxChunk(lua, SANDBOX_LUA);
		if (sandboxStrict)
			runSandboxChunk(lua, SANDBOX_STRICT_LUA);
	}

	public function new(scriptName:String)
	{
		#if LUA_ALLOWED
		var times:Float = Date.now().getTime();
		lua = LuaL.newstate();
		LuaL.openlibs(lua);
		// openlibs 之后立刻加固，必须早于任何 set() 与 dofile（即早于脚本代码执行）。
		// 注：原来这里留着一行 `// LuaL.dostring(lua, CLENSE);`，但 CLENSE 在全工程
		// 从未定义，属于失效的历史残留，已由 applySandbox() 取代。
		applySandbox(lua);

		// trace('Lua version: ' + Lua.version());
		// trace("LuaJIT version: " + Lua.versionJIT());

		this.scriptName = scriptName.trim();
		var game:PlayState = PlayState.instance;
		if (game != null)
			game.luaArray.push(this);

		var myFolder:Array<String> = this.scriptName.split('/');
		#if MODS_ALLOWED
		if (myFolder[0] + '/' == Paths.mods()
			&& (Mods.currentModDirectory == myFolder[1] || Mods.getGlobalMods().contains(myFolder[1]))) // is inside mods folder
			this.modFolder = myFolder[1];
		#end
		// Lua shit
		set('Function_StopLua', LuaUtils.Function_StopLua);
		set('Function_StopHScript', LuaUtils.Function_StopHScript);
		set('Function_StopAll', LuaUtils.Function_StopAll);
		set('Function_Stop', LuaUtils.Function_Stop);
		set('Function_Continue', LuaUtils.Function_Continue);
		set('luaDebugMode', false);
		set('luaDeprecatedWarnings', true);
		set('inChartEditor', false);

		// Song/Week shit
		set('curBpm', Conductor.bpm);
		set('bpm', PlayState.SONG.bpm);
		set('scrollSpeed', PlayState.SONG.speed);
		set('crochet', Conductor.crochet);
		set('stepCrochet', Conductor.stepCrochet);
		set('songLength', FlxG.sound.music.length);
		set('songName', PlayState.SONG.song);
		set('songPath', Paths.formatToSongPath(PlayState.SONG.song));
		set('startedCountdown', false);
		set('curStage', PlayState.SONG.stage);

		set('isStoryMode', PlayState.isStoryMode);
		set('difficulty', PlayState.storyDifficulty);

		set('difficultyName', Difficulty.getString());
		set('difficultyPath', Paths.formatToSongPath(Difficulty.getString()));
		set('weekRaw', PlayState.storyWeek);
		set('week', WeekData.weeksList[PlayState.storyWeek]);
		set('seenCutscene', PlayState.seenCutscene);
		set('hasVocals', PlayState.SONG.needsVoices);

		// Camera poo
		set('cameraX', 0);
		set('cameraY', 0);

		// Screen stuff
		set('screenWidth', FlxG.width);
		set('screenHeight', FlxG.height);

		// PlayState variables
		set('curSection', 0);
		set('curBeat', 0);
		set('curStep', 0);
		set('curDecBeat', 0);
		set('curDecStep', 0);

		set('score', 0);
		set('misses', 0);
		set('hits', 0);
		set('combo', 0);

		set('rating', 0);
		set('ratingName', '');
		set('ratingFC', '');
		set('version', MainMenuState.psychEngineVersion.trim());

		set('inGameOver', false);
		set('mustHitSection', false);
		set('altAnim', false);
		set('gfSection', false);

		// Gameplay settings
		set('healthGainMult', game.healthGain);
		set('healthLossMult', game.healthLoss);

		#if FLX_PITCH
		set('playbackRate', game.playbackRate);
		#else
		set('playbackRate', 1);
		#end

		set('guitarHeroSustains', game.guitarHeroSustains);
		set('instakillOnMiss', game.instakillOnMiss);
		set('botPlay', game.cpuControlled);
		set('practice', game.practiceMode);

		for (i in 0...4)
		{
			set('defaultPlayerStrumX' + i, 0);
			set('defaultPlayerStrumY' + i, 0);
			set('defaultOpponentStrumX' + i, 0);
			set('defaultOpponentStrumY' + i, 0);
		}

		// Default character
		set('defaultBoyfriendX', game.BF_X);
		set('defaultBoyfriendY', game.BF_Y);
		set('defaultOpponentX', game.DAD_X);
		set('defaultOpponentY', game.DAD_Y);
		set('defaultGirlfriendX', game.GF_X);
		set('defaultGirlfriendY', game.GF_Y);

		// Character shit
		set('boyfriendName', PlayState.SONG.player1);
		set('dadName', PlayState.SONG.player2);
		set('gfName', PlayState.SONG.gfVersion);

		// Other settings
		set('downscroll', ClientPrefs.data.downScroll);
		set('middlescroll', ClientPrefs.data.middleScroll);
		set('framerate', ClientPrefs.data.framerate);
		set('ghostTapping', ClientPrefs.data.ghostTapping);
		set('hideHud', ClientPrefs.data.hideHud);
		set('timeBarType', ClientPrefs.data.timeBarType);
		set('scoreZoom', ClientPrefs.data.scoreZoom);
		set('cameraZoomOnBeat', ClientPrefs.data.camZooms);
		set('flashingLights', ClientPrefs.data.flashing);
		set('noteOffset', ClientPrefs.data.noteOffset);
		set('healthBarAlpha', ClientPrefs.data.healthBarAlpha);
		set('noResetButton', ClientPrefs.data.noReset);
		set('lowQuality', ClientPrefs.data.lowQuality);
		set('shadersEnabled', ClientPrefs.data.shaders);
		set('scriptName', scriptName);
		set('currentModDirectory', Mods.currentModDirectory);

		// Noteskin/Splash
		set('noteSkin', ClientPrefs.data.noteSkin);
		set('noteSkinPostfix', Note.getNoteSkinPostfix());
		set('splashSkin', ClientPrefs.data.splashSkin);
		set('splashSkinPostfix', NoteSplash.getSplashSkinPostfix());
		set('splashAlpha', ClientPrefs.data.splashAlpha);

		// build target (windows, mac, linux, etc.)
		set('buildTarget', LuaUtils.getBuildTarget());

		for (name => func in customFunctions)
		{
			if (func != null)
				set(name, func);
		}

		//
		set("getRunningScripts", function()
		{
			var runningScripts:Array<String> = [];
			for (script in game.luaArray)
				runningScripts.push(script.scriptName);

			return runningScripts;
		});

		addLocalCallback("setOnScripts", function(varName:String, arg:Dynamic, ?ignoreSelf:Bool = false, ?exclusions:Array<String> = null)
		{
			if (exclusions == null)
				exclusions = [];
			if (ignoreSelf && !exclusions.contains(scriptName))
				exclusions.push(scriptName);
			game.setOnScripts(varName, arg, exclusions);
		});
		addLocalCallback("setOnHScript", function(varName:String, arg:Dynamic, ?ignoreSelf:Bool = false, ?exclusions:Array<String> = null)
		{
			if (exclusions == null)
				exclusions = [];
			if (ignoreSelf && !exclusions.contains(scriptName))
				exclusions.push(scriptName);
			game.setOnHScript(varName, arg, exclusions);
		});
		addLocalCallback("setOnLuas", function(varName:String, arg:Dynamic, ?ignoreSelf:Bool = false, ?exclusions:Array<String> = null)
		{
			if (exclusions == null)
				exclusions = [];
			if (ignoreSelf && !exclusions.contains(scriptName))
				exclusions.push(scriptName);
			game.setOnLuas(varName, arg, exclusions);
		});

		addLocalCallback("callOnScripts",
			function(funcName:String, ?args:Array<Dynamic> = null, ?ignoreStops = false, ?ignoreSelf:Bool = true, ?excludeScripts:Array<String> = null,
					?excludeValues:Array<Dynamic> = null)
			{
				if (excludeScripts == null)
					excludeScripts = [];
				if (ignoreSelf && !excludeScripts.contains(scriptName))
					excludeScripts.push(scriptName);
				game.callOnScripts(funcName, args, ignoreStops, excludeScripts, excludeValues);
				return true;
			});
		addLocalCallback("callOnLuas",
			function(funcName:String, ?args:Array<Dynamic> = null, ?ignoreStops = false, ?ignoreSelf:Bool = true, ?excludeScripts:Array<String> = null,
					?excludeValues:Array<Dynamic> = null)
			{
				if (excludeScripts == null)
					excludeScripts = [];
				if (ignoreSelf && !excludeScripts.contains(scriptName))
					excludeScripts.push(scriptName);
				game.callOnLuas(funcName, args, ignoreStops, excludeScripts, excludeValues);
				return true;
			});
		addLocalCallback("callOnHScript",
			function(funcName:String, ?args:Array<Dynamic> = null, ?ignoreStops = false, ?ignoreSelf:Bool = true, ?excludeScripts:Array<String> = null,
					?excludeValues:Array<Dynamic> = null)
			{
				if (excludeScripts == null)
					excludeScripts = [];
				if (ignoreSelf && !excludeScripts.contains(scriptName))
					excludeScripts.push(scriptName);
				game.callOnHScript(funcName, args, ignoreStops, excludeScripts, excludeValues);
				return true;
			});
		
		set("readJson", function(jsonFile:String)
		{
			////var path:String = jsonFile;
			var path:String = Paths.getPath(jsonFile, TEXT);
			#if MODS_ALLOWED
			if (!FileSystem.exists(path))
				if (!FileSystem.exists(path+'.json'))
					return {};
			return Json.parse(File.getContent(path));
			#else
			if (!Assets.exists(path))
				if (!Assets.exists(path+'.json'))
					return {};
			return Json.parse(Assets.getText(path));
			#end
		});

		set("callScript", function(luaFile:String, funcName:String, ?args:Array<Dynamic> = null)
		{
			if (args == null)
			{
				args = [];
			}

			var foundScript:String = findScript(luaFile);
			if (foundScript != null)
				for (luaInstance in game.luaArray)
					if (luaInstance.scriptName == foundScript)
					{
						luaInstance.call(funcName, args);
						return;
					}
		});

		set("getGlobalFromScript", function(luaFile:String, global:String)
		{ // returns the global from a script
			var foundScript:String = findScript(luaFile);
			if (foundScript != null)
				for (luaInstance in game.luaArray)
					if (luaInstance.scriptName == foundScript)
					{
						Lua.getglobal(luaInstance.lua, global);
						if (Lua.isnumber(luaInstance.lua, -1))
							Lua.pushnumber(lua, Lua.tonumber(luaInstance.lua, -1));
						else if (Lua.isstring(luaInstance.lua, -1))
							Lua.pushstring(lua, Lua.tostring(luaInstance.lua, -1));
						else if (Lua.isboolean(luaInstance.lua, -1))
							Lua.pushboolean(lua, Lua.toboolean(luaInstance.lua, -1));
						else
							Lua.pushnil(lua);

						// TODO: table

						Lua.pop(luaInstance.lua, 1); // remove the global

						return;
					}
		});
		set("setGlobalFromScript", function(luaFile:String, global:String, val:Dynamic)
		{ // returns the global from a script
			var foundScript:String = findScript(luaFile);
			if (foundScript != null)
				for (luaInstance in game.luaArray)
					if (luaInstance.scriptName == foundScript)
						luaInstance.set(global, val);
		});
		/*set("getGlobals", function(luaFile:String) { // returns a copy of the specified file's globals
			var foundScript:String = findScript(luaFile);
			if(foundScript != null)
			{
				for (luaInstance in game.luaArray)
				{
					if(luaInstance.scriptName == foundScript)
					{
						Lua.newtable(lua);
						var tableIdx = Lua.gettop(lua);

						Lua.pushvalue(luaInstance.lua, Lua.LUA_GLOBALSINDEX);
						while(Lua.next(luaInstance.lua, -2) != 0) {
							// key = -2
							// value = -1

							var pop:Int = 0;

							// Manual conversion
							// first we convert the key
							if(Lua.isnumber(luaInstance.lua,-2)){
								Lua.pushnumber(lua, Lua.tonumber(luaInstance.lua, -2));
								pop++;
							}else if(Lua.isstring(luaInstance.lua,-2)){
								Lua.pushstring(lua, Lua.tostring(luaInstance.lua, -2));
								pop++;
							}else if(Lua.isboolean(luaInstance.lua,-2)){
								Lua.pushboolean(lua, Lua.toboolean(luaInstance.lua, -2));
								pop++;
							}
							// TODO: table


							// then the value
							if(Lua.isnumber(luaInstance.lua,-1)){
								Lua.pushnumber(lua, Lua.tonumber(luaInstance.lua, -1));
								pop++;
							}else if(Lua.isstring(luaInstance.lua,-1)){
								Lua.pushstring(lua, Lua.tostring(luaInstance.lua, -1));
								pop++;
							}else if(Lua.isboolean(luaInstance.lua,-1)){
								Lua.pushboolean(lua, Lua.toboolean(luaInstance.lua, -1));
								pop++;
							}
							// TODO: table

							if(pop==2)Lua.rawset(tableIdx); // then set it
							Lua.pop(luaInstance.lua, 1); // for the loop
						}
						Lua.pop(luaInstance.lua,1); // end the loop entirely
						Lua.pushvalue(lua, tableIdx); // push the table onto the stack so it gets returned

						return;
					}

				}
			}
		});*/
		set("isRunning", function(luaFile:String)
		{
			var foundScript:String = findScript(luaFile);
			if (foundScript != null)
				for (luaInstance in game.luaArray)
					if (luaInstance.scriptName == foundScript)
						return true;
			return false;
		});

		set("setVar", function(varName:String, value:Dynamic)
		{
			PlayState.instance.variables.set(varName, value);
			return value;
		});
		set("getVar", PlayState.instance.variables.get);

		set("addLuaScript", function(luaFile:String, ?ignoreAlreadyRunning:Bool = false)
		{ // would be dope asf.
			var foundScript:String = findScript(luaFile);
			if (foundScript != null)
			{
				if (!ignoreAlreadyRunning)
					for (luaInstance in game.luaArray)
						if (luaInstance.scriptName == foundScript)
						{
							luaTrace('addLuaScript: The script "' + foundScript + '" is already running!');
							return;
						}

				new FunkinLua(foundScript);
				return;
			}
			luaTrace("addLuaScript: Script doesn't exist!", false, false, FlxColor.RED);
		});
		set("addHScript", function(luaFile:String, ?ignoreAlreadyRunning:Bool = false)
		{
			#if HSCRIPT_ALLOWED
			var foundScript:String = findScript(luaFile, '.hx');
			if (foundScript != null)
			{
				if (!ignoreAlreadyRunning)
					for (script in game.hscriptArray)
						if (script.origin == foundScript)
						{
							luaTrace('addHScript: The script "' + foundScript + '" is already running!');
							return;
						}

				PlayState.instance.initHScript(foundScript);
				return;
			}
			luaTrace("addHScript: Script doesn't exist!", false, false, FlxColor.RED);
			#else
			luaTrace("addHScript: HScript is not supported on this platform!", false, false, FlxColor.RED);
			#end
		});
		set("removeLuaScript", function(luaFile:String, ?ignoreAlreadyRunning:Bool = false)
		{
			var foundScript:String = findScript(luaFile);
			if (foundScript != null)
			{
				if (!ignoreAlreadyRunning)
					for (luaInstance in game.luaArray)
						if (luaInstance.scriptName == foundScript)
						{
							luaInstance.stop();
							trace('Closing script ' + luaInstance.scriptName);
							return true;
						}
			}
			luaTrace('removeLuaScript: Script $luaFile isn\'t running!', false, false, FlxColor.RED);
			return false;
		});
		Lua_helper.add_callback(lua, "removeHScript", function(luaFile:String, ?ignoreAlreadyRunning:Bool = false)
		{
			#if HSCRIPT_ALLOWED
			var foundScript:String = findScript(luaFile, '.hx');
			if (foundScript != null)
			{
				if (!ignoreAlreadyRunning)
					for (script in game.hscriptArray)
						if (script.origin == foundScript)
						{
							trace('Closing script ' + (script.origin != null ? script.origin : luaFile));
							script.destroy();
							return true;
						}
			}
			luaTrace('removeHScript: Script $luaFile isn\'t running!', false, false, FlxColor.RED);
			return false;
			#else
			luaTrace("removeHScript: HScript is not supported on this platform!", false, false, FlxColor.RED);
			#end
		});

		set("loadSong", function(?name:String = null, ?difficultyNum:Int = -1)
		{
			if (name == null || name.length < 1)
				name = PlayState.SONG.song;
			if (difficultyNum == -1)
				difficultyNum = PlayState.storyDifficulty;

			var poop = Highscore.formatSong(name, difficultyNum);
			PlayState.SONG = Song.loadFromJson(poop, name);
			PlayState.storyDifficulty = difficultyNum;
			game.persistentUpdate = false;
			LoadingState.loadAndSwitchState(new PlayState());

			FlxG.sound.music.pause();
			FlxG.sound.music.volume = 0;
			if (game.vocals != null)
			{
				game.vocals.pause();
				game.vocals.volume = 0;
			}
			FlxG.camera.followLerp = 0;
		});

		set("loadGraphic", function(variable:String, image:String, ?gridX:Int = 0, ?gridY:Int = 0, ?disposeOnUpload:Bool = true)
		{
			var split:Array<String> = variable.split('.');
			var spr:FlxSprite = LuaUtils.getObjectDirectly(split[0]);
			var animated = gridX != 0 || gridY != 0;

			if (split.length > 1)
			{
				spr = LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(split), split[split.length - 1]);
			}

			if (spr != null && image != null && image.length > 0)
			{
				spr.loadGraphic(Paths.image(image, null, null, disposeOnUpload), animated, gridX, gridY);
			}
		});
		set("loadFrames", function(variable:String, image:String, spriteType:String = "sparrow")
		{
			var split:Array<String> = variable.split('.');
			var spr:FlxSprite = LuaUtils.getObjectDirectly(split[0]);
			if (split.length > 1)
			{
				spr = LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(split), split[split.length - 1]);
			}

			if (spr != null && image != null && image.length > 0)
			{
				LuaUtils.loadFrames(spr, image, spriteType);
			}
		});

		// shitass stuff for epic coders like me B)  *image of obama giving himself a medal*
		set("getObjectOrder", function(obj:String)
		{
			var split:Array<String> = obj.split('.');
			var leObj:FlxBasic = LuaUtils.getObjectDirectly(split[0]);
			if (split.length > 1)
			{
				leObj = LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(split), split[split.length - 1]);
			}

			if (leObj != null)
			{
				return LuaUtils.getTargetInstance().members.indexOf(leObj);
			}
			luaTrace("getObjectOrder: Object " + obj + " doesn't exist!", false, false, FlxColor.RED);
			return -1;
		});
		set("setObjectOrder", function(obj:String, position:Int)
		{
			var split:Array<String> = obj.split('.');
			var leObj:FlxBasic = LuaUtils.getObjectDirectly(split[0]);
			if (split.length > 1)
			{
				leObj = LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(split), split[split.length - 1]);
			}

			if (leObj != null)
			{
				LuaUtils.getTargetInstance().remove(leObj, true);
				LuaUtils.getTargetInstance().insert(position, leObj);
				return;
			}
			luaTrace("setObjectOrder: Object " + obj + " doesn't exist!", false, false, FlxColor.RED);
		});

		// gay ass tweens
		set("startTween", function(tag:String, vars:String, values:Any = null, duration:Float, options:Any = null)
		{
			var penisExam:Dynamic = LuaUtils.tweenPrepare(tag, vars);
			if (penisExam != null)
			{
				if (values != null)
				{
					var myOptions:LuaTweenOptions = LuaUtils.getLuaTween(options);
					game.modchartTweens.set(tag, FlxTween.tween(penisExam, values, duration, {
						type: myOptions.type,
						ease: myOptions.ease,
						startDelay: myOptions.startDelay,
						loopDelay: myOptions.loopDelay,

						onUpdate: function(twn:FlxTween)
						{
							if (myOptions.onUpdate != null)
								game.callOnLuas(myOptions.onUpdate, [tag, vars]);
						},
						onStart: function(twn:FlxTween)
						{
							if (myOptions.onStart != null)
								game.callOnLuas(myOptions.onStart, [tag, vars]);
						},
						onComplete: function(twn:FlxTween)
						{
							if (myOptions.onComplete != null)
								game.callOnLuas(myOptions.onComplete, [tag, vars]);
							if (twn.type == FlxTweenType.ONESHOT || twn.type == FlxTweenType.BACKWARD)
								game.modchartTweens.remove(tag);
						}
					}));
				}
				else
				{
					luaTrace('startTween: No values on 2nd argument!', false, false, FlxColor.RED);
				}
			}
			else
			{
				luaTrace('startTween: Couldnt find object: ' + vars, false, false, FlxColor.RED);
			}
		});

		set("doTweenX", function(tag:String, vars:String, value:Dynamic, duration:Float, ease:String)
		{
			oldTweenFunction(tag, vars, {x: value}, duration, ease, 'doTweenX');
		});
		set("doTweenY", function(tag:String, vars:String, value:Dynamic, duration:Float, ease:String)
		{
			oldTweenFunction(tag, vars, {y: value}, duration, ease, 'doTweenY');
		});
		set("doTweenAngle", function(tag:String, vars:String, value:Dynamic, duration:Float, ease:String)
		{
			oldTweenFunction(tag, vars, {angle: value}, duration, ease, 'doTweenAngle');
		});
		set("doTweenAlpha", function(tag:String, vars:String, value:Dynamic, duration:Float, ease:String)
		{
			oldTweenFunction(tag, vars, {alpha: value}, duration, ease, 'doTweenAlpha');
		});
		set("doTweenZoom", function(tag:String, vars:String, value:Dynamic, duration:Float, ease:String)
		{
			oldTweenFunction(tag, vars, {zoom: value}, duration, ease, 'doTweenZoom');
		});
		set("doTweenColor", function(tag:String, vars:String, targetColor:String, duration:Float, ease:String)
		{
			var penisExam:Dynamic = LuaUtils.tweenPrepare(tag, vars);
			if (penisExam != null)
			{
				var curColor:FlxColor = penisExam.color;
				curColor.alphaFloat = penisExam.alpha;
				game.modchartTweens.set(tag, FlxTween.color(penisExam, duration, curColor, CoolUtil.colorFromString(targetColor), {
					ease: LuaUtils.getTweenEaseByString(ease),
					onComplete: function(twn:FlxTween)
					{
						game.modchartTweens.remove(tag);
						game.callOnLuas('onTweenCompleted', [tag, vars]);
					}
				}));
			}
			else
			{
				luaTrace('doTweenColor: Couldnt find object: ' + vars, false, false, FlxColor.RED);
			}
		});

		// Tween shit, but for strums
		set("noteTweenX", function(tag:String, note:Int, value:Dynamic, duration:Float, ease:String)
		{
			LuaUtils.cancelTween(tag);
			if (note < 0)
				note = 0;
			var testicle:StrumNote = game.strumLineNotes.members[note % game.strumLineNotes.length];

			if (testicle != null)
			{
				game.modchartTweens.set(tag, FlxTween.tween(testicle, {x: value}, duration, {
					ease: LuaUtils.getTweenEaseByString(ease),
					onComplete: function(twn:FlxTween)
					{
						game.callOnLuas('onTweenCompleted', [tag]);
						game.modchartTweens.remove(tag);
					}
				}));
			}
		});
		set("noteTweenY", function(tag:String, note:Int, value:Dynamic, duration:Float, ease:String)
		{
			LuaUtils.cancelTween(tag);
			if (note < 0)
				note = 0;
			var testicle:StrumNote = game.strumLineNotes.members[note % game.strumLineNotes.length];

			if (testicle != null)
			{
				game.modchartTweens.set(tag, FlxTween.tween(testicle, {y: value}, duration, {
					ease: LuaUtils.getTweenEaseByString(ease),
					onComplete: function(twn:FlxTween)
					{
						game.callOnLuas('onTweenCompleted', [tag]);
						game.modchartTweens.remove(tag);
					}
				}));
			}
		});
		set("noteTweenAngle", function(tag:String, note:Int, value:Dynamic, duration:Float, ease:String)
		{
			LuaUtils.cancelTween(tag);
			if (note < 0)
				note = 0;
			var testicle:StrumNote = game.strumLineNotes.members[note % game.strumLineNotes.length];

			if (testicle != null)
			{
				game.modchartTweens.set(tag, FlxTween.tween(testicle, {angle: value}, duration, {
					ease: LuaUtils.getTweenEaseByString(ease),
					onComplete: function(twn:FlxTween)
					{
						game.callOnLuas('onTweenCompleted', [tag]);
						game.modchartTweens.remove(tag);
					}
				}));
			}
		});
		set("noteTweenDirection", function(tag:String, note:Int, value:Dynamic, duration:Float, ease:String)
		{
			LuaUtils.cancelTween(tag);
			if (note < 0)
				note = 0;
			var testicle:StrumNote = game.strumLineNotes.members[note % game.strumLineNotes.length];

			if (testicle != null)
			{
				game.modchartTweens.set(tag, FlxTween.tween(testicle, {direction: value}, duration, {
					ease: LuaUtils.getTweenEaseByString(ease),
					onComplete: function(twn:FlxTween)
					{
						game.callOnLuas('onTweenCompleted', [tag]);
						game.modchartTweens.remove(tag);
					}
				}));
			}
		});

		set("noteTweenScale", function(tag:String, note:Int, scale:Float, duration:Float, ease:String)
		{
			LuaUtils.cancelTween(tag);
			if (note < 0)
				note = 0;
			var testicle:StrumNote = game.strumLineNotes.members[note % game.strumLineNotes.length];

			if (testicle != null)
			{
				game.modchartTweens.set(tag, FlxTween.tween(testicle.scale, {x: scale, y: scale}, duration, {
					ease: LuaUtils.getTweenEaseByString(ease),
					onComplete: function(twn:FlxTween)
					{
						game.callOnLuas('onTweenCompleted', [tag]);
						game.modchartTweens.remove(tag);
					}
				}));
			}
		});

		set("mouseClicked", function(button:String)
		{
			var click:Bool = FlxG.mouse.justPressed;
			switch (button)
			{
				case 'middle':
					click = FlxG.mouse.justPressedMiddle;
				case 'right':
					click = FlxG.mouse.justPressedRight;
			}
			return click;
		});
		set("mousePressed", function(button:String)
		{
			var press:Bool = FlxG.mouse.pressed;
			switch (button)
			{
				case 'middle':
					press = FlxG.mouse.pressedMiddle;
				case 'right':
					press = FlxG.mouse.pressedRight;
			}
			return press;
		});
		set("mouseReleased", function(button:String)
		{
			var released:Bool = FlxG.mouse.justReleased;
			switch (button)
			{
				case 'middle':
					released = FlxG.mouse.justReleasedMiddle;
				case 'right':
					released = FlxG.mouse.justReleasedRight;
			}
			return released;
		});
		set("noteTweenAlpha", function(tag:String, note:Int, value:Dynamic, duration:Float, ease:String)
		{
			LuaUtils.cancelTween(tag);
			if (note < 0)
				note = 0;
			var testicle:StrumNote = game.strumLineNotes.members[note % game.strumLineNotes.length];

			if (testicle != null)
			{
				game.modchartTweens.set(tag, FlxTween.tween(testicle, {alpha: value}, duration, {
					ease: LuaUtils.getTweenEaseByString(ease),
					onComplete: function(twn:FlxTween)
					{
						game.callOnLuas('onTweenCompleted', [tag]);
						game.modchartTweens.remove(tag);
					}
				}));
			}
		});

		set("cancelTween", LuaUtils.cancelTween);
		set("runTimer", function(tag:String, time:Float = 1, loops:Int = 1)
		{
			LuaUtils.cancelTimer(tag);
			game.modchartTimers.set(tag, new FlxTimer().start(time, function(tmr:FlxTimer)
			{
				if (tmr.finished)
				{
					game.modchartTimers.remove(tag);
				}
				game.callOnLuas('onTimerCompleted', [tag, tmr.loops, tmr.loopsLeft]);
				// trace('Timer Completed: ' + tag);
			}, loops));
		});
		set("cancelTimer", LuaUtils.cancelTimer);

		// stupid bietch ass functions
		set("addScore", function(value:Int = 0)
		{
			game.songScore += value;
			game.RecalculateRating();
		});
		set("addMisses", function(value:Int = 0)
		{
			game.songMisses += value;
			game.RecalculateRating();
		});
		set("addHits", function(value:Int = 0)
		{
			game.songHits += value;
			game.RecalculateRating();
		});
		set("setScore", function(value:Int = 0)
		{
			game.songScore = value;
			game.RecalculateRating();
		});
		set("setMisses", function(value:Int = 0)
		{
			game.songMisses = value;
			game.RecalculateRating();
		});
		set("setHits", function(value:Int = 0)
		{
			game.songHits = value;
			game.RecalculateRating();
		});
		set("getScore", function()
		{
			return game.songScore;
		});
		set("getMisses", function()
		{
			return game.songMisses;
		});
		set("getHits", function()
		{
			return game.songHits;
		});

		set("setHealth", function(value:Float = 0)
		{
			game.health = value;
		});
		set("addHealth", function(value:Float = 0)
		{
			game.health += value;
		});
		set("getHealth", function()
		{
			return game.health;
		});

		// Identical functions
		set("FlxColor", FlxColor.fromString);
		set("getColorFromName", FlxColor.fromString);
		set("getColorFromString", FlxColor.fromString);
		set("getColorFromHex", function(color:String) return FlxColor.fromString('#$color'));

		// precaching
		set("addCharacterToList", function(name:String, type:String)
		{
			var charType:Int = 0;
			switch (type.toLowerCase())
			{
				case 'dad':
					charType = 1;
				case 'gf' | 'girlfriend':
					charType = 2;
			}
			game.addCharacterToList(name, charType);
		});
		set("precacheImage", function(name:String, ?allowGPU:Bool = true, ?disposeOnUpload:Bool = true)
		{
			Paths.image(name, null, allowGPU, disposeOnUpload);
		});
		// Precache callbacks are commands. Returning the loaded OpenFL Sound to
		// Lua makes linc_luajit try to serialize a native Sound object and emits
		// "Couldn't convert TClass(openfl.media.Sound)" once per asset.
		set("precacheSound", function(name:String):Void {
			Paths.sound(name);
		});
		set("precacheMusic", function(name:String):Void {
			Paths.music(name);
		});

		// others
		set("triggerEvent", function(name:String, arg1:Dynamic, arg2:Dynamic)
		{
			var value1:String = arg1;
			var value2:String = arg2;
			game.triggerEvent(name, value1, value2, Conductor.songPosition);
			// trace('Triggered event: ' + name + ', ' + value1 + ', ' + value2);
			return true;
		});

		set("startCountdown", game.startCountdown);

		set("endSong", function()
		{
			game.KillNotes();
			game.endSong();
			return true;
		});
		set("restartSong", function(?skipTransition:Bool = false)
		{
			game.persistentUpdate = false;
			FlxG.camera.followLerp = 0;
			PauseSubState.restartSong(skipTransition);
			return true;
		});
		set("exitSong", function(?skipTransition:Bool = false)
		{
			if (skipTransition)
			{
				FlxTransitionableState.skipNextTransIn = true;
				FlxTransitionableState.skipNextTransOut = true;
			}

			if (PlayState.isStoryMode)
				MusicBeatState.switchState(new StoryMenuState());
			else
				MusicBeatState.switchState(new FreeplayState());
			#if DISCORD_ALLOWED DiscordClient.resetClientID(); #end

			FlxG.sound.playMusic(Paths.music('freakyMenu'));
			PlayState.changedDifficulty = false;
			PlayState.chartingMode = false;
			game.transitioning = true;
			FlxG.camera.followLerp = 0;
			Mods.loadTopMod();
			return true;
		});
		set("getSongPosition", function()
		{
			return Conductor.songPosition;
		});

		set("getCharacterX", function(type:String)
		{
			switch (type.toLowerCase())
			{
				case 'dad' | 'opponent':
					return game.dadGroup.x;
				case 'gf' | 'girlfriend':
					return game.gfGroup.x;
				default:
					return game.boyfriendGroup.x;
			}
		});
		set("setCharacterX", function(type:String, value:Float)
		{
			switch (type.toLowerCase())
			{
				case 'dad' | 'opponent':
					game.dadGroup.x = value;
				case 'gf' | 'girlfriend':
					game.gfGroup.x = value;
				default:
					game.boyfriendGroup.x = value;
			}
		});
		set("getCharacterY", function(type:String)
		{
			switch (type.toLowerCase())
			{
				case 'dad' | 'opponent':
					return game.dadGroup.y;
				case 'gf' | 'girlfriend':
					return game.gfGroup.y;
				default:
					return game.boyfriendGroup.y;
			}
		});
		set("setCharacterY", function(type:String, value:Float)
		{
			switch (type.toLowerCase())
			{
				case 'dad' | 'opponent':
					game.dadGroup.y = value;
				case 'gf' | 'girlfriend':
					game.gfGroup.y = value;
				default:
					game.boyfriendGroup.y = value;
			}
		});
		set("cameraSetTarget", function(target:String)
		{
			var isDad:Bool = false;
			if (target == 'dad')
			{
				isDad = true;
			}
			game.moveCamera(isDad);
			return isDad;
		});
		set("cameraShake", function(camera:String, intensity:Float, duration:Float)
		{
			LuaUtils.cameraFromString(camera).shake(intensity, duration);
		});

		set("cameraFlash", function(camera:String, color:String, duration:Float, forced:Bool)
		{
			LuaUtils.cameraFromString(camera).flash(CoolUtil.colorFromString(color), duration, null, forced);
		});
		set("cameraFade", function(camera:String, color:String, duration:Float, forced:Bool)
		{
			LuaUtils.cameraFromString(camera).fade(CoolUtil.colorFromString(color), duration, false, null, forced);
		});
		set("setRatingPercent", function(value:Float)
		{
			game.ratingPercent = value;
		});
		set("setRatingName", function(value:String)
		{
			game.ratingName = value;
		});
		set("setRatingFC", function(value:String)
		{
			game.ratingFC = value;
		});
		set("getMouseX", function(camera:String)
		{
			var cam:FlxCamera = LuaUtils.cameraFromString(camera);
			return FlxG.mouse.getScreenPosition(cam).x;
		});
		set("getMouseY", function(camera:String)
		{
			var cam:FlxCamera = LuaUtils.cameraFromString(camera);
			return FlxG.mouse.getScreenPosition(cam).y;
		});

		set("getMidpointX", function(variable:String)
		{
			var split:Array<String> = variable.split('.');
			var obj:FlxSprite = LuaUtils.getObjectDirectly(split[0]);
			if (split.length > 1)
			{
				obj = LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(split), split[split.length - 1]);
			}
			if (obj != null)
				return obj.getMidpoint().x;

			return 0;
		});
		set("getMidpointY", function(variable:String)
		{
			var split:Array<String> = variable.split('.');
			var obj:FlxSprite = LuaUtils.getObjectDirectly(split[0]);
			if (split.length > 1)
			{
				obj = LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(split), split[split.length - 1]);
			}
			if (obj != null)
				return obj.getMidpoint().y;

			return 0;
		});
		set("getGraphicMidpointX", function(variable:String)
		{
			var split:Array<String> = variable.split('.');
			var obj:FlxSprite = LuaUtils.getObjectDirectly(split[0]);
			if (split.length > 1)
			{
				obj = LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(split), split[split.length - 1]);
			}
			if (obj != null)
				return obj.getGraphicMidpoint().x;

			return 0;
		});
		set("getGraphicMidpointY", function(variable:String)
		{
			var split:Array<String> = variable.split('.');
			var obj:FlxSprite = LuaUtils.getObjectDirectly(split[0]);
			if (split.length > 1)
			{
				obj = LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(split), split[split.length - 1]);
			}
			if (obj != null)
				return obj.getGraphicMidpoint().y;

			return 0;
		});
		set("getScreenPositionX", function(variable:String, ?camera:String)
		{
			var split:Array<String> = variable.split('.');
			var obj:FlxSprite = LuaUtils.getObjectDirectly(split[0]);
			if (split.length > 1)
			{
				obj = LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(split), split[split.length - 1]);
			}
			if (obj != null)
				return obj.getScreenPosition().x;

			return 0;
		});
		set("getScreenPositionY", function(variable:String, ?camera:String)
		{
			var split:Array<String> = variable.split('.');
			var obj:FlxSprite = LuaUtils.getObjectDirectly(split[0]);
			if (split.length > 1)
			{
				obj = LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(split), split[split.length - 1]);
			}
			if (obj != null)
				return obj.getScreenPosition().y;

			return 0;
		});
		set("characterDance", function(character:String)
		{
			switch (character.toLowerCase())
			{
				case 'dad':
					game.dad.dance();
				case 'gf' | 'girlfriend':
					if (game.gf != null)
						game.gf.dance();
				default:
					game.boyfriend.dance();
			}
		});

		set("makeLuaSprite", function(tag:String, ?image:String = null, ?x:Float = 0, ?y:Float = 0, ?disposeOnUpload:Bool = true)
		{
			tag = tag.replace('.', '');
			if (LuaUtils.checkSpriteTag(game.modchartSprites.get(tag), image)) {
				LuaUtils.resetSpriteTag(tag);
				var leSprite:ModchartSprite = new ModchartSprite(x, y);
				if (image != null && image.length > 0)
				{
					var graphic = Paths.image(image, null, null, disposeOnUpload);
					if (graphic == null)
					{
						reportRuntimeErrorOnce('makeLuaSprite:missing:$image',
							'makeLuaSprite("$tag"): image "$image" could not be loaded.');
						leSprite.destroy();
						return;
					}
					leSprite.loadGraphic(graphic);
				}
				leSprite.imageName = image;
				game.modchartSprites.set(tag, leSprite);
				leSprite.active = true;
			} /*else {
				trace('stop make sprite: ' + tag);
			} */
		});
		set("makeAnimatedLuaSprite", function(tag:String, ?image:String = null, ?x:Float = 0, ?y:Float = 0, ?spriteType:String = "sparrow")
		{
			tag = tag.replace('.', '');
			if (LuaUtils.checkSpriteTag(game.modchartSprites.get(tag), image)) {
				LuaUtils.resetSpriteTag(tag);
				var leSprite:ModchartSprite = new ModchartSprite(x, y);

				if (image == null || image.length == 0 || Paths.image(image) == null)
				{
					reportRuntimeErrorOnce('makeAnimatedLuaSprite:missing:$image',
						'makeAnimatedLuaSprite("$tag"): image "$image" could not be loaded.');
					leSprite.destroy();
					return;
				}

				try
				{
					LuaUtils.loadFrames(leSprite, image, spriteType);
				}
				catch (error:Dynamic)
				{
					reportRuntimeErrorOnce('makeAnimatedLuaSprite:atlas:$image',
						'makeAnimatedLuaSprite("$tag"): atlas "$image" could not be loaded (${Std.string(error)}).');
					leSprite.destroy();
					return;
				}

				if (leSprite.frames == null || leSprite.numFrames <= 0)
				{
					reportRuntimeErrorOnce('makeAnimatedLuaSprite:frames:$image',
						'makeAnimatedLuaSprite("$tag"): atlas "$image" contains no usable frames.');
					leSprite.destroy();
					return;
				}
				leSprite.imageName = image;
				game.modchartSprites.set(tag, leSprite);
			} /*else {
				trace('stop make sprite: ' + tag);
			} */
		});

		set("makeGraphic", function(obj:String, width:Int = 256, height:Int = 256, color:String = 'FFFFFF')
		{
			var spr:FlxSprite = LuaUtils.getObjectDirectly(obj, false);
			if (spr != null)
				spr.makeGraphic(width, height, CoolUtil.colorFromString(color));
		});
		set("addAnimationByPrefix", function(obj:String, name:String, prefix:String, framerate:Int = 24, loop:Bool = true)
		{
			// A reflected FlxAnimationController.frameName is nullable while its
			// sprite has no atlas/frame. Never forward that null into Flixel's
			// prefix matcher; an empty prefix remains supported for legacy mods.
			if (prefix == null)
			{
				reportRuntimeErrorOnce('addAnimationByPrefix:null:$obj:$name',
					'addAnimationByPrefix("$obj", "$name"): prefix is nil because the source sprite has no current frame.');
				return;
			}

			if (PlayState.instance.getLuaObject(obj, false) != null)
			{
				var cock:FlxSprite = PlayState.instance.getLuaObject(obj, false);
				cock.animation.addByPrefix(name, prefix, framerate, loop);
				if (cock.animation.curAnim == null)
				{
					cock.animation.play(name, true);
				}
				return;
			}
		});

		set("addAnimation", function(obj:String, name:String, frames:Array<Int>, framerate:Int = 24, loop:Bool = true)
		{
			var obj:Dynamic = LuaUtils.getObjectDirectly(obj, false);
			if (obj != null && obj.animation != null)
			{
				obj.animation.add(name, frames, framerate, loop);
				if (obj.animation.curAnim == null)
				{
					obj.animation.play(name, true);
				}
				return true;
			}
			return false;
		});

		set("addAnimationByIndices", function(obj:String, name:String, prefix:String, indices:String, framerate:Int = 24, loop:Bool = false)
		{
			return LuaUtils.addAnimByIndices(obj, name, prefix, indices, framerate, loop);
		});

		set("playAnim", function(obj:String, name:String, forced:Bool = false, ?reverse:Bool = false, ?startFrame:Int = 0)
		{
			var obj:Dynamic = LuaUtils.getObjectDirectly(obj, false);
			if (obj == null)
				return false;

			if (obj.playAnim != null)
			{
				obj.playAnim(name, forced, reverse, startFrame);
				return true;
			}

			if (obj.anim != null)
			{
				obj.anim.play(name, forced, reverse, startFrame); // FlxAnimate
				return true;
			}

			if (obj.animation != null)
			{
				obj.animation.play(name, forced, reverse, startFrame);
				return true;
			}

			return false;
		});
		set("addOffset", function(obj:String, anim:String, x:Float, y:Float)
		{
			var obj:Dynamic = LuaUtils.getObjectDirectly(obj, false);
			if (obj != null && obj.addOffset != null)
			{
				obj.addOffset(anim, x, y);
				return true;
			}
			return false;
		});

		set("setScrollFactor", function(obj:String, scrollX:Float, scrollY:Float)
		{
			if (game.getLuaObject(obj, false) != null)
			{
				game.getLuaObject(obj, false).scrollFactor.set(scrollX, scrollY);
				return;
			}

			var object:FlxObject = Reflect.getProperty(LuaUtils.getTargetInstance(), obj);
			if (object != null)
			{
				object.scrollFactor.set(scrollX, scrollY);
			}
		});

		set("addLuaSprite", function(tag:String, front:Bool = false)
		{
			var mySprite:FlxSprite = null;
			if (game.modchartSprites.exists(tag))
				mySprite = game.modchartSprites.get(tag);
			else if (game.variables.exists(tag))
				mySprite = game.variables.get(tag);

			if (mySprite == null)
				return false;

			if (mySprite.alreadyAdded) {
				//trace('already added: ' + tag);
				return false;
			}

			if (front)
				LuaUtils.getTargetInstance().add(mySprite);
			else
			{
				if (!game.isDead)
					game.insert(game.members.indexOf(LuaUtils.getLowestCharacterGroup()), mySprite);
				else
					GameOverSubstate.instance.insert(GameOverSubstate.instance.members.indexOf(GameOverSubstate.instance.boyfriend), mySprite);
			}
			mySprite.alreadyAdded = true;
			return true;
		});
		set("setGraphicSize", function(obj:String, x:Int, y:Int = 0, updateHitbox:Bool = true)
		{
			if (game.getLuaObject(obj) != null)
			{
				var shit:FlxSprite = game.getLuaObject(obj);
				shit.setGraphicSize(x, y);
				if (updateHitbox)
					shit.updateHitbox();
				return;
			}

			var split:Array<String> = obj.split('.');
			var poop:FlxSprite = LuaUtils.getObjectDirectly(split[0]);
			if (split.length > 1)
			{
				poop = LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(split), split[split.length - 1]);
			}

			if (poop != null)
			{
				poop.setGraphicSize(x, y);
				if (updateHitbox)
					poop.updateHitbox();
				return;
			}
			luaTrace('setGraphicSize: Couldnt find object: ' + obj, false, false, FlxColor.RED);
		});
		set("scaleObject", function(obj:String, x:Float, y:Float, updateHitbox:Bool = true)
		{
			if (game.getLuaObject(obj) != null)
			{
				var shit:FlxSprite = game.getLuaObject(obj);
				shit.scale.set(x, y);
				if (updateHitbox)
					shit.updateHitbox();
				return;
			}

			var split:Array<String> = obj.split('.');
			var poop:FlxSprite = LuaUtils.getObjectDirectly(split[0]);
			if (split.length > 1)
			{
				poop = LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(split), split[split.length - 1]);
			}

			if (poop != null)
			{
				poop.scale.set(x, y);
				if (updateHitbox)
					poop.updateHitbox();
				return;
			}
			luaTrace('scaleObject: Couldnt find object: ' + obj, false, false, FlxColor.RED);
		});
		set("updateHitbox", function(obj:String)
		{
			if (game.getLuaObject(obj) != null)
			{
				var shit:FlxSprite = game.getLuaObject(obj);
				shit.updateHitbox();
				return;
			}

			var poop:FlxSprite = Reflect.getProperty(LuaUtils.getTargetInstance(), obj);
			if (poop != null)
			{
				poop.updateHitbox();
				return;
			}
			luaTrace('updateHitbox: Couldnt find object: ' + obj, false, false, FlxColor.RED);
		});
		set("updateHitboxFromGroup", function(group:String, index:Int)
		{
			if (Std.isOfType(Reflect.getProperty(LuaUtils.getTargetInstance(), group), FlxTypedGroup))
			{
				Reflect.getProperty(LuaUtils.getTargetInstance(), group).members[index].updateHitbox();
				return;
			}
			Reflect.getProperty(LuaUtils.getTargetInstance(), group)[index].updateHitbox();
		});

		set("removeLuaSprite", function(tag:String, destroy:Bool = true)
		{
			if (!game.modchartSprites.exists(tag))
			{
				return;
			}

			var pee:ModchartSprite = game.modchartSprites.get(tag);
			FlxTween.cancelTweensOf(pee);
			LuaUtils.getTargetInstance().remove(pee, true);
			pee.alreadyAdded = false;
			if (destroy)
			{
				pee.kill();
				pee.destroy();
				game.modchartSprites.remove(tag);
			}
		});

		set("luaSpriteExists", game.modchartSprites.exists);
		set("luaTextExists", game.modchartTexts.exists);
		set("luaSoundExists", game.modchartSounds.exists);

		set("setHealthBarColors", function(left:String, right:String)
		{
			game.healthBar.setColors(CoolUtil.colorFromString(left), CoolUtil.colorFromString(right));
		});
		set("setTimeBarColors", function(left:String, right:String)
		{
			game.timeBar.setColors(CoolUtil.colorFromString(left), CoolUtil.colorFromString(right));
		});

		set("setObjectCamera", function(obj:String, camera:String = '')
		{
			var real = game.getLuaObject(obj);
			if (real != null)
			{
				real.cameras = [LuaUtils.cameraFromString(camera)];
				return true;
			}

			var split:Array<String> = obj.split('.');
			var object:FlxSprite = LuaUtils.getObjectDirectly(split[0]);
			if (split.length > 1)
			{
				object = LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(split), split[split.length - 1]);
			}

			if (object != null)
			{
				object.cameras = [LuaUtils.cameraFromString(camera)];
				return true;
			}
			luaTrace("setObjectCamera: Object " + obj + " doesn't exist!", false, false, FlxColor.RED);
			return false;
		});
		set("setBlendMode", function(obj:String, blend:String = '')
		{
			var real = game.getLuaObject(obj);
			if (real != null)
			{
				real.blend = LuaUtils.blendModeFromString(blend);
				return true;
			}

			var split:Array<String> = obj.split('.');
			var spr:FlxSprite = LuaUtils.getObjectDirectly(split[0]);
			if (split.length > 1)
			{
				spr = LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(split), split[split.length - 1]);
			}

			if (spr != null)
			{
				spr.blend = LuaUtils.blendModeFromString(blend);
				return true;
			}
			luaTrace("setBlendMode: Object " + obj + " doesn't exist!", false, false, FlxColor.RED);
			return false;
		});
		set("screenCenter", function(obj:String, pos:String = 'xy')
		{
			var spr:FlxSprite = game.getLuaObject(obj);

			if (spr == null)
			{
				var split:Array<String> = obj.split('.');
				spr = LuaUtils.getObjectDirectly(split[0]);
				if (split.length > 1)
				{
					spr = LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(split), split[split.length - 1]);
				}
			}

			if (spr != null)
			{
				switch (pos.trim().toLowerCase())
				{
					case 'x':
						spr.screenCenter(X);
						return;
					case 'y':
						spr.screenCenter(Y);
						return;
					default:
						spr.screenCenter(XY);
						return;
				}
			}
			luaTrace("screenCenter: Object " + obj + " doesn't exist!", false, false, FlxColor.RED);
		});
		set("objectsOverlap", function(obj1:String, obj2:String)
		{
			var namesArray:Array<String> = [obj1, obj2];
			var objectsArray:Array<FlxSprite> = [];
			for (i in 0...namesArray.length)
			{
				var real = game.getLuaObject(namesArray[i]);
				if (real != null)
				{
					objectsArray.push(real);
				}
				else
				{
					objectsArray.push(Reflect.getProperty(LuaUtils.getTargetInstance(), namesArray[i]));
				}
			}

			if (!objectsArray.contains(null) && FlxG.overlap(objectsArray[0], objectsArray[1]))
			{
				return true;
			}
			return false;
		});
		set("getPixelColor", function(obj:String, x:Int, y:Int)
		{
			var split:Array<String> = obj.split('.');
			var spr:FlxSprite = LuaUtils.getObjectDirectly(split[0]);
			if (split.length > 1)
			{
				spr = LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(split), split[split.length - 1]);
			}

			if (spr != null)
				return spr.pixels.getPixel32(x, y);
			return FlxColor.BLACK;
		});
		set("startDialogue", function(dialogueFile:String, music:String = null)
		{
			var path:String;
			#if MODS_ALLOWED
			path = Paths.modsJson(Paths.formatToSongPath(PlayState.SONG.song) + '/' + dialogueFile);
			if (!FileSystem.exists(path))
			#end
			path = Paths.json(Paths.formatToSongPath(PlayState.SONG.song) + '/' + dialogueFile);

			luaTrace('startDialogue: Trying to load dialogue: ' + path);

			#if MODS_ALLOWED
			if (FileSystem.exists(path))
			#else
			if (Assets.exists(path))
			#end
			{
				var shit:DialogueFile = DialogueBoxPsych.parseDialogue(path);
				if (shit.dialogue.length > 0)
				{
					game.startDialogue(shit, music);
					luaTrace('startDialogue: Successfully loaded dialogue', false, false, FlxColor.GREEN);
					return true;
				}
				else
				{
					luaTrace('startDialogue: Your dialogue file is badly formatted!', false, false, FlxColor.RED);
				}
			}
		else
		{
			luaTrace('startDialogue: Dialogue file not found', false, false, FlxColor.RED);
			if (game.endingSong)
			{
				game.endSong();
			}
			else
			{
				game.startCountdown();
			}
		}
			return false;
		});
		Lua_helper.add_callback(lua, "startVideo",
			function(videoFile:String, ?canSkip:Bool = true, ?forMidSong:Bool = false, ?shouldLoop:Bool = false, ?playOnLoad:Bool = true)
			{
				#if VIDEOS_ALLOWED
				if (FileSystem.exists(Paths.video(videoFile)))
				{
					if (game.videoCutscene != null)
					{
						game.remove(game.videoCutscene);
						game.videoCutscene.destroy();
					}
					game.videoCutscene = game.startVideo(videoFile, forMidSong, canSkip, shouldLoop, playOnLoad);
					return true;
				}
				else
				{
					luaTrace('startVideo: Video file not found: ' + videoFile, false, false, FlxColor.RED);
				}
				return false;
				#else
				PlayState.instance.inCutscene = true;
				new FlxTimer().start(0.1, function(tmr:FlxTimer)
				{
					PlayState.instance.inCutscene = false;
					if (game.endingSong)
						game.endSong();
					else
						game.startCountdown();
				});
				return true;
				#end
			});

		set("playMusic", function(sound:String, volume:Float = 1, loop:Bool = false)
		{
			FlxG.sound.playMusic(Paths.music(sound), volume, loop);
		});
		set("playSound", function(sound:String, volume:Float = 1, ?tag:String = null)
		{
			if (tag != null && tag.length > 0)
			{
				tag = tag.replace('.', '');
				if (game.modchartSounds.exists(tag))
				{
					game.modchartSounds.get(tag).stop();
				}
				game.modchartSounds.set(tag, FlxG.sound.play(Paths.sound(sound), volume, false, null, true, function()
				{
					game.modchartSounds.remove(tag);
					game.callOnLuas('onSoundFinished', [tag]);
				}));
				return;
			}
			FlxG.sound.play(Paths.sound(sound), volume);
		});
		set("stopSound", function(tag:String)
		{
			if (tag != null && tag.length > 1 && game.modchartSounds.exists(tag))
			{
				game.modchartSounds.get(tag).stop();
				game.modchartSounds.remove(tag);
			}
		});
		set("pauseSound", function(tag:String)
		{
			if (tag != null && tag.length > 1 && game.modchartSounds.exists(tag))
			{
				game.modchartSounds.get(tag).pause();
			}
		});
		set("resumeSound", function(tag:String)
		{
			if (tag != null && tag.length > 1 && game.modchartSounds.exists(tag))
			{
				game.modchartSounds.get(tag).play();
			}
		});
		set("soundFadeIn", function(tag:String, duration:Float, fromValue:Float = 0, toValue:Float = 1)
		{
			if (tag == null || tag.length < 1)
			{
				FlxG.sound.music.fadeIn(duration, fromValue, toValue);
			}
			else if (game.modchartSounds.exists(tag))
			{
				game.modchartSounds.get(tag).fadeIn(duration, fromValue, toValue);
			}
		});
		set("soundFadeOut", function(tag:String, duration:Float, toValue:Float = 0)
		{
			if (tag == null || tag.length < 1)
			{
				FlxG.sound.music.fadeOut(duration, toValue);
			}
			else if (game.modchartSounds.exists(tag))
			{
				game.modchartSounds.get(tag).fadeOut(duration, toValue);
			}
		});
		set("soundFadeCancel", function(tag:String)
		{
			if (tag == null || tag.length < 1)
			{
				if (FlxG.sound.music.fadeTween != null)
				{
					FlxG.sound.music.fadeTween.cancel();
				}
			}
			else if (game.modchartSounds.exists(tag))
			{
				var theSound:FlxSound = game.modchartSounds.get(tag);
				if (theSound.fadeTween != null)
				{
					theSound.fadeTween.cancel();
					game.modchartSounds.remove(tag);
				}
			}
		});
		set("getSoundVolume", function(tag:String)
		{
			if (tag == null || tag.length < 1)
			{
				if (FlxG.sound.music != null)
				{
					return FlxG.sound.music.volume;
				}
			}
			else if (game.modchartSounds.exists(tag))
			{
				return game.modchartSounds.get(tag).volume;
			}
			return 0;
		});
		set("setSoundVolume", function(tag:String, value:Float)
		{
			if (tag == null || tag.length < 1)
			{
				if (FlxG.sound.music != null)
				{
					FlxG.sound.music.volume = value;
				}
			}
			else if (game.modchartSounds.exists(tag))
			{
				game.modchartSounds.get(tag).volume = value;
			}
		});
		set("getSoundTime", function(tag:String)
		{
			if (tag != null && tag.length > 0 && game.modchartSounds.exists(tag))
			{
				return game.modchartSounds.get(tag).time;
			}
			return 0;
		});
		set("setSoundTime", function(tag:String, value:Float)
		{
			if (tag != null && tag.length > 0 && game.modchartSounds.exists(tag))
			{
				var theSound:FlxSound = game.modchartSounds.get(tag);
				if (theSound != null)
				{
					var wasResumed:Bool = theSound.playing;
					theSound.pause();
					theSound.time = value;
					if (wasResumed)
						theSound.play();
				}
			}
		});

		#if FLX_PITCH
		set("getSoundPitch", function(tag:String)
		{
			if (tag != null && tag.length > 0 && game.modchartSounds.exists(tag))
			{
				return game.modchartSounds.get(tag).pitch;
			}
			return 0;
		});
		set("setSoundPitch", function(tag:String, value:Float, doPause:Bool = false)
		{
			if (tag != null && tag.length > 0 && game.modchartSounds.exists(tag))
			{
				var theSound:FlxSound = game.modchartSounds.get(tag);
				if (theSound != null)
				{
					var wasResumed:Bool = theSound.playing;
					if (doPause)
						theSound.pause();
					theSound.pitch = value;
					if (doPause && wasResumed)
						theSound.play();
				}
			}
		});
		#end

		// mod settings
		#if MODS_ALLOWED
		addLocalCallback("getModSetting", function(saveTag:String, ?modName:String = null)
		{
			if (modName == null)
			{
				if (this.modFolder == null)
				{
					FunkinLua.luaTrace('getModSetting: Argument #2 is null and script is not inside a packed Mod folder!', false, false, FlxColor.RED);
					return null;
				}
				modName = this.modFolder;
			}
			return LuaUtils.getModSetting(saveTag, modName);
		});
		#end
		//

		set("debugPrint", function(text:Dynamic = '', color:String = 'WHITE') PlayState.instance.addTextToDebug(text, CoolUtil.colorFromString(color)));

		addLocalCallback("close", function()
		{
			closed = true;
			trace('Closing script $scriptName');
			return closed;
		});

		#if DISCORD_ALLOWED DiscordClient.addLuaCallbacks(this); #end
		#if HSCRIPT_ALLOWED
		HScriptBase.implement(this);
		#end
		#if ACHIEVEMENTS_ALLOWED Achievements.addLuaCallbacks(this); #end
		#if flxanimate FlxAnimateFunctions.implement(this); #end
		ReflectionFunctions.implement(this);
		TextFunctions.implement(this);
		ExtraFunctions.implement(this);
		CustomSubstate.implement(this);
		ShaderFunctions.implement(this);
		DeprecatedFunctions.implement(this);

		try
		{
			var isString:Bool = !FileSystem.exists(scriptName);
			// LuaL.dofile / dostring 返回的是【状态码】（@:native('luaL_dofile')，
			// 语义等同 (luaL_loadfile || lua_pcall)，0 == LUA_OK），不是栈索引。
			// 旧代码把它当成 Lua.tostring(lua, result) 的索引：
			// 出错时 result 例如为 3，而栈上只有 1 个值，lua_tostring(L, 3) 会越过
			// 栈顶读取（release 构建下 api_check 为空），通常返回 null。后果有三个：
			//   1) 语法/运行期出错的脚本被当作"加载成功"；
			//   2) 失败脚本既不 close 也不移出 luaArray，成为 closed=false / lua!=null
			//      但 chunk 未加载的 zombie，之后每次 call() 都会命中它；
			//   3) 错误对象永久留在 Lua 栈上，而 call() 假设栈上只有参数，
			//      于是每次回调都让栈净增长 1 个值 → 长时间内存增长 + 栈语义串位。
			var status:Int = isString
				? LuaL.dostring(lua, scriptName)
				: LuaL.dofile(lua, scriptName);

			// ★ 中文 / 非 ASCII 路径兜底。
			//   `luaL_dofile` 内部是 CRT 的窄字符 `fopen`，会把路径字节按「进程 ANSI
			//   代码页」解释。简中系统上那是 936(GBK)，而 Haxe 传下去的是 UTF-8，
			//   于是 `mods/中文模组/script.lua` 打不开（实测 status=1）。新构建的 exe
			//   带 windows/NovaFlare.manifest 的 activeCodePage=UTF-8（Win10 1903+），
			//   已经把这条路径修好了；这里再兜一层，覆盖老系统 / 清单没生效的情况。
			//
			//   判定依据：`isString`（= FileSystem.exists 为 false）用的是 hxcpp 的
			//   Unicode 安全实现，所以「文件存在但 dofile 失败」几乎必然是路径编码问题。
			//   此时改用 File.getContent（内部 _wfopen，Unicode 安全）读源码再 dostring。
			//   代价：错误信息里的 chunk 名会变成源码片段而不是文件路径 —— 但总比
			//   「脚本根本加载不了」好。清单生效的正常情况下这条分支永远不会走到。
			if (status != Lua.LUA_OK && !isString)
			{
				// 先把 dofile 压进来的错误对象弹掉，避免污染后面 call() 的栈假设
				var failedTop:Int = Lua.gettop(lua);
				if (failedTop > 0)
					Lua.pop(lua, failedTop);

				var recovered:Bool = false;
				try
				{
					var src:String = File.getContent(scriptName);
					if (src != null && src.length > 0)
					{
						status = LuaL.dostring(lua, src);
						recovered = (status == Lua.LUA_OK);
						if (recovered)
							trace('[Lua] luaL_dofile 失败（路径含非 ASCII 字符？）→ 已用 File.getContent + dostring 兜底加载：$scriptName');
					}
				}
				catch (e:Dynamic)
				{
					trace('[Lua] 中文路径兜底加载失败：$scriptName — ' + Std.string(e));
				}

				if (!recovered && Lua.gettop(lua) > 0)
					Lua.pop(lua, Lua.gettop(lua));
			}

			if (status != Lua.LUA_OK)
			{
				var stackTop:Int = Lua.gettop(lua);
				var errorMsg:String = (stackTop > 0) ? Lua.tostring(lua, -1) : null;
				if (stackTop > 0)
					Lua.pop(lua, 1);

				var report:String = '$scriptName\n'
					+ (errorMsg != null ? errorMsg : 'Unknown Lua error (status $status)');
				trace(report);
				#if (windows || mobile || js || wasm)
				SUtil.showPopUp(report, 'Error on lua script!');
				#else
				luaTrace(report, true, false, FlxColor.RED);
				#end

				// 必须真正收尾：关闭 Lua 状态并移出 luaArray，避免留下 zombie。
				stop();
				if (PlayState.instance != null)
					PlayState.instance.luaArray.remove(this);
				return;
			}

			// dofile/dostring 走 LUA_MULTRET，chunk 的返回值会留在栈上。
			// call() 假设栈平衡，这里必须清干净（llua.Lua 未导出 lua_settop，
			// 用 lua_pop(L, n) 等价于 lua_settop(L, -(n)-1)）。
			var leftover:Int = Lua.gettop(lua);
			if (leftover > 0)
				Lua.pop(lua, leftover);

			if (!isString)
				DeepDebugTracker.recordScript('Lua', scriptName);
			else
				scriptName = 'unknown';
		}
		catch (e:Dynamic)
		{
			trace(e);
			stop();
			if (PlayState.instance != null)
				PlayState.instance.luaArray.remove(this);
			return;
		}
		call('onCreate', []);
		trace('lua file loaded succesfully: $scriptName (${Std.int(Date.now().getTime() - times)}ms)');
		#end
	}

	// main
	public var lastCalledFunction:String = '';

	public static var lastCalledScript:FunkinLua = null;

	public function call(func:String, args:Array<Dynamic>):Dynamic
	{
		if (closed)
			return LuaUtils.Function_Continue;

		var result:Dynamic = LuaUtils.Function_Continue;
		lastCalledFunction = func;
		lastCalledScript = this;
		try
		{
			if (lua == null)
				result = LuaUtils.Function_Continue;

			else
			{
				Lua.getglobal(lua, func);
				var type:Int = Lua.type(lua, -1);

				if (type != Lua.LUA_TFUNCTION)
				{
					if (type > Lua.LUA_TNIL)
						reportRuntimeErrorOnce('lua-call-type:$func:$type',
							'attempt to call a ${LuaUtils.typeToString(type)} value.');

					Lua.pop(lua, 1);
					result = LuaUtils.Function_Continue;
				}
				else
				{
					for (arg in args)
						Convert.toLua(lua, arg);
					var status:Int = Lua.pcall(lua, args.length, 1, 0);

					// Checks if it's not successful, then show a error.
					if (status != Lua.LUA_OK)
					{
						var error:String = getErrorMessage(status);
						reportRuntimeErrorOnce('lua-runtime:$func:$error', error);
						result = LuaUtils.Function_Continue;
					}
					else
					{
						// If successful, pass and then return the result.
						var luaResult:Dynamic = cast Convert.fromLua(lua, -1);
						if (luaResult == null)
							luaResult = LuaUtils.Function_Continue;

						Lua.pop(lua, 1);
						if (closed)
						{
							stop();
							result = LuaUtils.Function_Continue;
						}
						else
						{
							result = luaResult;
						}
					}
				}
			}
		}
		catch (e:Dynamic)
		{
			trace(e);
			reportRuntimeErrorOnce('callback:$func:${Std.string(e)}', Std.string(e));
			result = LuaUtils.Function_Continue;
		}

		return result;
	}

	public function set(variable:String, data:Dynamic)
	{
	#if LUA_ALLOWED
	if (lua == null)
		return;

	if (Type.typeof(data) == TFunction)
	{
		Lua_helper.add_callback(lua, variable, data);
		return;
	}

	Convert.toLua(lua, data);
	Lua.setglobal(lua, variable);
	} public function stop()

	{
		closed = true;
		if (lastCalledScript == this)
			lastCalledScript = null;
		if (callbacks != null)
			callbacks.clear();
		if (reportedRuntimeErrors != null)
			reportedRuntimeErrors.clear();

		if (lua == null)
		{
			return;
		}
		Lua.close(lua);
		lua = null;
	#end
		#if HSCRIPT_ALLOWED
		if (hscriptBase != null)
			hscriptBase.interp = null;
		hscriptBase = null;
		#end
	}

	function oldTweenFunction(tag:String, vars:String, tweenValue:Any, duration:Float, ease:String, funcName:String)
	{
		var target:Dynamic = LuaUtils.tweenPrepare(tag, vars);
		if (target != null)
		{
			PlayState.instance.modchartTweens.set(tag, FlxTween.tween(target, tweenValue, duration, {
				ease: LuaUtils.getTweenEaseByString(ease),
				onComplete: function(twn:FlxTween)
				{
					PlayState.instance.modchartTweens.remove(tag);
					PlayState.instance.callOnLuas('onTweenCompleted', [tag, vars]);
				}
			}));
		}
		else
		{
			luaTrace('$funcName: Couldnt find object: $vars', false, false, FlxColor.RED);
		}
	}

	public function reportRuntimeErrorOnce(key:String, message:String):Void
	{
		if (key == null || key.length == 0)
			key = message;
		if (reportedRuntimeErrors.exists(key))
			return;

		reportedRuntimeErrors.set(key, true);
		var callbackName:String = lastCalledFunction != null && lastCalledFunction.length > 0 ? lastCalledFunction : 'unknown callback';
		var sourceName:String = scriptName != null && scriptName.length > 0 ? scriptName : 'unknown Lua script';
		var errorText:String = 'ERROR ($callbackName) [$sourceName]: $message';
		if (PlayState.instance != null)
			// 走报错专用通道：受「维护设置 › Lua 语法错误提示」控制（关闭时只写日志、不上屏）
			PlayState.instance.addScriptErrorToDebug(errorText);
		else
			trace(errorText);
	}

	public static function luaTrace(text:String, ignoreCheck:Bool = false, deprecated:Bool = false, color:FlxColor = FlxColor.WHITE)
	{
		if (ignoreCheck || getBool('luaDebugMode'))
		{
			if (deprecated && !getBool('luaDeprecatedWarnings'))
			{
				return;
			}
			PlayState.instance.addTextToDebug(text, color);
		}
	}

	public static function getBool(variable:String)
	{
		if (lastCalledScript == null)
			return false;

		var lua:State = lastCalledScript.lua;
		if (lua == null)
			return false;

		var result:String = null;
		Lua.getglobal(lua, variable);
		result = Convert.fromLua(lua, -1);
		Lua.pop(lua, 1);

		if (result == null)
		{
			return false;
		}
		return (result == 'true');
	}

	function findScript(scriptFile:String, ext:String = '.lua')
	{
		if (!scriptFile.endsWith(ext))
			scriptFile += ext;
		var preloadPath:String = Paths.getSharedPath(scriptFile);
		#if MODS_ALLOWED
		var path:String = Paths.modFolders(scriptFile);
		if (FileSystem.exists(scriptFile))
			return scriptFile;
		else if (FileSystem.exists(path))
			return path;

		if (FileSystem.exists(preloadPath))
		#else
		if (Assets.exists(preloadPath))
		#end
		{
			return preloadPath;
		}
		return null;
	}

	public function getErrorMessage(status:Int):String
	{
		var v:String = Lua.tostring(lua, -1);
		Lua.pop(lua, 1);

		if (v != null)
			v = v.trim();
		if (v == null || v == "")
		{
			switch (status)
			{
				case Lua.LUA_ERRRUN:
					return "Runtime Error";
				case Lua.LUA_ERRMEM:
					return "Memory Allocation Error";
				case Lua.LUA_ERRERR:
					return "Critical Error";
			}
			return "Unknown Error";
		}

		return v;
		return null;
	}

	public function addLocalCallback(name:String, myFunction:Dynamic)
	{
		callbacks.set(name, myFunction);
		Lua_helper.add_callback(lua, name, null); // just so that it gets called
	}

	#if (MODS_ALLOWED && !flash && sys)
	public var runtimeShaders:Map<String, Array<String>> = new Map<String, Array<String>>();
	#end

	public function initLuaShader(name:String)
	{
		if (!ClientPrefs.data.shaders)
			return false;

		#if (MODS_ALLOWED && !flash && sys)
		if (runtimeShaders.exists(name))
		{
			luaTrace('Shader $name was already initialized!');
			return true;
		}

		var foldersToCheck:Array<String> = [Paths.mods('shaders/')];
		if (Mods.currentModDirectory != null && Mods.currentModDirectory.length > 0)
			foldersToCheck.insert(0, Paths.mods(Mods.currentModDirectory + '/shaders/'));

		for (mod in Mods.getGlobalMods())
			foldersToCheck.insert(0, Paths.mods(mod + '/shaders/'));

		for (folder in foldersToCheck)
		{
			if (FileSystem.exists(folder))
			{
				var frag:String = folder + name + '.frag';
				var vert:String = folder + name + '.vert';
				var found:Bool = false;
				if (FileSystem.exists(frag))
				{
					frag = File.getContent(frag);
					found = true;
				}
				else
					frag = null;

				if (FileSystem.exists(vert))
				{
					vert = File.getContent(vert);
					found = true;
				}
				else
					vert = null;

				if (found)
				{
					runtimeShaders.set(name, [frag, vert]);
					// trace('Found shader $name!');
					return true;
				}
			}
		}
		luaTrace('Missing shader $name .frag AND .vert files!', false, false, FlxColor.RED);
		#else
		luaTrace('This platform doesn\'t support Runtime Shaders!', false, false, FlxColor.RED);
		#end
		return false;
	}
}
#end
