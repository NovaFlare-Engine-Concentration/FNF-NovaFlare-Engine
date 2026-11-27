package states.loadingState.backend;

import general.backend.ClientPrefs;
import general.backend.Mods;
import general.backend.Paths;
import games.backend.Rating;
import games.backend.Song;
import games.backend.StageData;
import games.cutscenes.DialogueBoxPsych;
import games.PlayState;
import states.loadingState.LoadingState;
import sys.FileSystem;
import sys.io.File;
import lime.utils.Assets;
import haxe.Json;
import haxe.ds.StringMap;
import openfl.utils.AssetType;
import crowplexus.hscript.Parser;
import crowplexus.hscript.Expr;
import crowplexus.hscript.Tools;

using StringTools;

class DataPreload
{
	static final scannedScripts = new StringMap<Bool>();
	static final scannedCharacters = new StringMap<Bool>();
	static var scriptEventInputs:Array<Array<String>> = [];

	public static function startPrepare()
	{
		var song:SwagSong = PlayState.SONG;
		var folder:String = Paths.formatToSongPath(song.song);
		scannedScripts.clear();
		scannedCharacters.clear();
		var eventNames = collectEvents(song.events, folder);
		try
		{
			var path:String = Paths.json('$folder/preload');
			var json:Dynamic = null;

			#if MODS_ALLOWED
			var moddyFile:String = Paths.modsJson('$folder/preload');
			if (FileSystem.exists(moddyFile))
				json = Json.parse(File.getContent(moddyFile));
			else if (FileSystem.exists(path))
				json = Json.parse(File.getContent(path));
			#else
			json = Json.parse(Assets.getText(path));
			#end

			if (json != null)
				LoadingState.instance.prepare((!ClientPrefs.data.lowQuality || json.images_low) ? json.images : json.images_low, json.sounds, json.music);
		}
		catch (e:Dynamic){}

		if (song.stage == null || song.stage.length < 1)
			song.stage = StageData.vanillaSongStage(folder);

		var stageData:StageFile = StageData.getStageFile(song.stage);
		if (stageData != null)
		{
			var imgs:Array<String> = [];
			var snds:Array<String> = [];
			var mscs:Array<String> = [];
			if(stageData.preload != null)
			{
				for (asset in Reflect.fields(stageData.preload))
				{
					var filters:Int = Reflect.field(stageData.preload, asset);
					var asset:String = asset.trim();

					if(filters < 0 || StageData.validateVisibility(filters))
					{
						if(asset.startsWith('images/'))
							imgs.push(asset.substr('images/'.length));
						else if(asset.startsWith('sounds/'))
							snds.push(asset.substr('sounds/'.length));
						else if(asset.startsWith('music/'))
							mscs.push(asset.substr('music/'.length));
					}
				}
			}
			
			if (stageData.objects != null)
			{
				for (sprite in stageData.objects)
				{
					if(sprite.type == 'sprite' || sprite.type == 'animatedSprite')
						if((sprite.filters < 0 || StageData.validateVisibility(sprite.filters)) && !imgs.contains(sprite.image))
							imgs.push(sprite.image);
				}
			}
			LoadingState.instance.prepare(imgs, snds, mscs);
		}

		LoadingState.instance.putPreload(LoadingState.instance.songsToPrepare, '$folder/Inst');

		var player1:String = song.player1;
		var player2:String = song.player2;
		var gfVersion:String = song.gfVersion;
		var needsVoices:Bool = song.needsVoices;
		var prefixVocals:String = needsVoices ? '$folder/Voices' : null;
		if (gfVersion == null)
			gfVersion = 'gf';

		preloadCharacter(player1, prefixVocals);

		if (prefixVocals != null)
		{
			LoadingState.instance.putPreload(LoadingState.instance.songsToPrepare, prefixVocals);
			LoadingState.instance.putPreload(LoadingState.instance.songsToPrepare, '$prefixVocals-Player');
			LoadingState.instance.putPreload(LoadingState.instance.songsToPrepare, '$prefixVocals-Opponent');
		}

		if (player2 != player1)
			preloadCharacter(player2, prefixVocals);
		if (stageData != null && !stageData.hide_girlfriend && gfVersion != player2 && gfVersion != player1)
			preloadCharacter(gfVersion);

		LoadingState.instance.chartNoteTypes = [];
		for (section in PlayState.SONG.notes)
		{
			for (songNotes in section.sectionNotes)
			{
				if (!LoadingState.instance.chartNoteTypes.contains(songNotes[3]))
				{
					LoadingState.instance.chartNoteTypes.push(songNotes[3]);
				}
			}
		}
		for (event in scriptEventInputs)
			if (event[0] == 'Change Character') preloadCharacter(event[2]);

		preloadMisc();
		preloadScript(folder, eventNames);
		scriptEventInputs = [];
		scannedScripts.clear();
		scannedCharacters.clear();
	}

	public static function preloadCharacter(char:String, ?prefixVocals:String)
	{
		if (char == null || char == '') return;
		if (prefixVocals == null && scannedCharacters.exists(char)) return;
		scannedCharacters.set(char, true);
		try
		{
			var path:String = Paths.getPath('characters/$char.json', TEXT);
			#if MODS_ALLOWED
			var character:Dynamic = Json.parse(File.getContent(path));
			#else
			var character:Dynamic = Json.parse(Assets.getText(path));
			#end

			var isAnimateAtlas:Bool = false;
			var img:String = character.image;
			img = img.trim();
			#if flxanimate
			var animToFind:String = Paths.getPath('images/$img/Animation.json', TEXT);
			if (#if MODS_ALLOWED FileSystem.exists(animToFind) || #end Assets.exists(animToFind))
				isAnimateAtlas = true;
			#end

			if(!isAnimateAtlas)
			{
				var split:Array<String> = img.split(',');
				for (file in split)
				{
					LoadingState.instance.putPreload(LoadingState.instance.imagesToPrepare, file.trim());
				}
			}
			#if flxanimate
			else
			{
				for (i in 0...10)
				{
					var st:String = '$i';
					if(i == 0) st = '';
	
					if(Paths.fileExists('images/$img/spritemap$st.png', IMAGE))
					{
						//trace('found Sprite PNG');
						LoadingState.instance.putPreload(LoadingState.instance.imagesToPrepare, '$img/spritemap$st');
						break;
					}
				}
			}
			#end

			LoadingState.instance.putPreload(LoadingState.instance.imagesToPrepare, 'icons/' + character.healthicon);
			LoadingState.instance.putPreload(LoadingState.instance.imagesToPrepare, 'icons/icon-' + character.healthicon);

			if (prefixVocals != null && character.vocals_file != null && character.vocals_file.length > 0)
			{
				LoadingState.instance.putPreload(LoadingState.instance.songsToPrepare, prefixVocals + "-" + character.vocals_file);
			}
			startLuaNamed('characters/' + char + '.lua');
			startHscriptNamed('characters/' + char + '.hx');
		}
		catch (e:Dynamic)
		{
		}
	}

	static function preloadMisc()
	{
		var ratingsData:Array<Rating> = Rating.loadDefault();
		var stageData:StageFile = StageData.getStageFile(PlayState.SONG.stage);

		var uiPrefix:String = '';
		var uiSuffix:String = '';

		if (stageData == null)
		{ // Stage couldn't be found, create a dummy stage for preventing a crash
			stageData = StageData.dummy();
		}

		PlayState.stageUI = 'normal'; // fix
		if (stageData.stageUI != null && stageData.stageUI.trim().length > 0)
			PlayState.stageUI = stageData.stageUI;
		else
		{
			if (stageData.isPixelStage)
				PlayState.stageUI = "pixel";
		}
		if (PlayState.stageUI != "normal")
		{
			uiPrefix = PlayState.stageUI + 'UI/';
			if (PlayState.isPixelStage)
				uiSuffix = '-pixel';
		}

		for (rating in ratingsData)
		{
			LoadingState.instance.putPreload(LoadingState.instance.imagesToPrepare, uiPrefix + rating.image + uiSuffix);
		}

		for (i in 0...10)
			LoadingState.instance.putPreload(LoadingState.instance.imagesToPrepare, uiPrefix + 'num' + i + uiSuffix);

		LoadingState.instance.putPreload(LoadingState.instance.imagesToPrepare, uiPrefix + 'ready' + uiSuffix);
		LoadingState.instance.putPreload(LoadingState.instance.imagesToPrepare, uiPrefix + 'set' + uiSuffix);
		LoadingState.instance.putPreload(LoadingState.instance.imagesToPrepare, uiPrefix + 'go' + uiSuffix);
		LoadingState.instance.putPreload(LoadingState.instance.imagesToPrepare, 'healthBar');

		if (PlayState.isStoryMode)  {
			LoadingState.instance.putPreload(LoadingState.instance.imagesToPrepare, 'speech_bubble');
		}
	}

	static function collectEvents(chartEvents:Array<Dynamic>, songFolder:String):Array<String>
	{
		var names:Array<String> = [];
		var seen = new StringMap<Bool>();
		scriptEventInputs = [];
		addEventInputs(names, seen, chartEvents);
		try
		{
			var sidecar = Song.getChart('events', songFolder, true);
			if (sidecar != null) addEventInputs(names, seen, sidecar.events);
		}
		catch (error:haxe.Exception) {} // A song may have no separate events file.
		return names;
	}

	static function addEventInputs(names:Array<String>, seen:StringMap<Bool>, groups:Array<Dynamic>):Void
	{
		if (groups == null) return;
		for (group in groups)
		{
			if (!Std.isOfType(group, Array) || !Std.isOfType(group[1], Array)) continue;
			for (entry in (cast group[1]:Array<Dynamic>))
			{
				if (!Std.isOfType(entry, Array) || !Std.isOfType(entry[0], String) || entry[0] == '') continue;
				var event:Array<String> = [entry[0], entry[1] == null ? '' : Std.string(entry[1]), entry[2] == null ? '' : Std.string(entry[2])];
				var key = Json.stringify(event);
				if (seen.exists(key)) continue;
				seen.set(key, true);
				if (!names.contains(event[0])) names.push(event[0]);
				scriptEventInputs.push(event);
			}
		}
	}

	static function preloadScript(songFolder:String, eventNames:Array<String>)
	{
		#if ((LUA_ALLOWED || HSCRIPT_ALLOWED) && sys)
		scanScriptDirectory('scripts/');
		scanScriptDirectory('data/$songFolder/');

		startLuaNamed('stages/' + PlayState.SONG.stage + '.lua');
		startHscriptNamed('stages/' + PlayState.SONG.stage + '.hx');

		for (noteType in LoadingState.instance.chartNoteTypes)
		{
			startLuaNamed('custom_notetypes/' + noteType + '.lua');
			startHscriptNamed('custom_notetypes/' + noteType + '.hx');
		}

		for (event in eventNames)
		{
			startLuaNamed('custom_events/' + event + '.lua');
			startHscriptNamed('custom_events/' + event + '.hx');
		}
		#end
	}

	static function scanScriptDirectory(directory:String):Void
	{
		for (folder in Mods.directoriesWithFile(Paths.getSharedPath(), directory))
		{
			if (!FileSystem.exists(folder) || !FileSystem.isDirectory(folder)) continue;
			for (file in FileSystem.readDirectory(folder))
			{
				var name = file.toLowerCase();
				#if LUA_ALLOWED
				if (name.endsWith('.lua')) luaFilesCheck(folder + file, scriptEventInputs);
				#end
				#if HSCRIPT_ALLOWED
				if (name.endsWith('.hx')) hscriptFilesCheck(folder + file);
				#end
			}
		}
	}

	static function startLuaNamed(filePath:String):Void
	{
		#if (LUA_ALLOWED && sys)
		luaFilesCheck(namedScriptPath(filePath), scriptEventInputs);
		#end
	}

	static function namedScriptPath(filePath:String):String
	{
		#if MODS_ALLOWED
		var modPath = Paths.modFolders(filePath);
		if (FileSystem.exists(modPath)) return modPath;
		#end
		return Paths.getSharedPath(filePath);
	}

	static function readScript(path:String):Null<String>
	{
		var onDisk = FileSystem.exists(path) && !FileSystem.isDirectory(path);
		if (!onDisk && !Assets.exists(path, TEXT)) return null;
		var canonical = onDisk ? FileSystem.fullPath(path) : path;
		if (scannedScripts.exists(canonical)) return null;
		scannedScripts.set(canonical, true);
		return onDisk ? File.getContent(path) : Assets.getText(path);
	}

	static function stripScriptBOM(input:String):String
	{
		return input.charCodeAt(0) == 0xFEFF ? input.substr(1) : input;
	}

	static function luaFilesCheck(path:String, events:Array<Array<String>>):Void
	{
		#if (LUA_ALLOWED && sys)
		try
		{
			var input = readScript(path);
			if (input == null) return;
			var root = new LuaPreloadParser().parseFromString(stripScriptBOM(input));
			if (root != null) LuaPreloadValues.scan(root, events, collectLuaCall);
		}
		catch (error:haxe.Exception)
		{
			trace('Could not scan Lua preload references in $path: ${error.message}');
		}
		#end
	}

	static function collectLuaCall(name:String, params:Array<Dynamic>):Void
	{
		var first = assetKey(params[0]);
		var second = assetKey(params[1]);
		var loading = LoadingState.instance;
		switch (name)
		{
			case 'makeLuaSprite', 'makeAnimatedLuaSprite', 'loadGraphic', 'loadFrames':
				if (second != null) loading.putPreload(loading.imagesToPrepare, second);
			case 'precacheImage':
				if (first != null) loading.putPreload(loading.imagesToPrepare, first);
			case 'addCharacterToList':
				if (first != null) preloadCharacter(first);
			case 'precacheSound', 'playSound':
				if (first != null) loading.putPreload(loading.soundsToPrepare, first);
			case 'precacheMusic', 'playMusic':
				if (first != null) loading.putPreload(loading.musicToPrepare, first);
			case 'addLuaScript':
				if (first != null) startLuaNamed(first.toLowerCase().endsWith('.lua') ? first : first + '.lua');
			case 'addHScript':
				if (first != null) startHscriptNamed(first.toLowerCase().endsWith('.hx') ? first : first + '.hx');
			case 'runHaxeCode':
				if (first != null) hscriptFilesCheck(first, false);
			case 'startDialogue':
				if (PlayState.isStoryMode)
				{
					if (first != null) preloadDialogue(first);
					if (second != null) loading.putPreload(loading.musicToPrepare, second);
				}
			default:
		}
	}

	static function assetKey(value:Dynamic):Null<String>
	{
		if (value == null) return null;
		if (!Std.isOfType(value, String) && !Std.isOfType(value, Int) && !Std.isOfType(value, Float)) return null;
		var key = Std.string(value);
		return key.trim() == '' ? null : key;
	}

	static function preloadDialogue(file:String):Void
	{
		var folder = Paths.formatToSongPath(PlayState.SONG.song);
		var path = Paths.json('$folder/$file');
		if (!FileSystem.exists(path) && !Assets.exists(path)) return;
		var dialogue:DialogueFile = DialogueBoxPsych.parseDialogue(path);
		if (dialogue == null || dialogue.dialogue == null) return;
		var loading = LoadingState.instance;
		for (line in dialogue.dialogue)
		{
			if (line == null) continue;
			if (line.portrait != null) loading.putPreload(loading.imagesToPrepare, 'dialogue/' + line.portrait);
			if (line.sound != null) loading.putPreload(loading.soundsToPrepare, line.sound);
		}
	}

	static function startHscriptNamed(filePath:String):Void
	{
		#if (HSCRIPT_ALLOWED && sys)
		hscriptFilesCheck(namedScriptPath(filePath));
		#end
	}

	static function hscriptFilesCheck(file:String, isFile:Bool = true):Void
	{
		#if (HSCRIPT_ALLOWED && sys)
		try
		{
			var input = isFile ? readScript(file) : file;
			if (input == null) return;
			var parser = new Parser();
			parser.allowTypes = parser.allowMetadata = parser.allowJSON = true;
			var root = parser.parseString(stripScriptBOM(input));
			ScriptExprTools.hx_searchCallback(root, collectHscriptCall);
		}
		catch (error:haxe.Exception)
		{
			var origin = isFile ? file : 'inline Lua runHaxeCode';
			trace('Could not scan HScript preload references in $origin: ${error.message}');
		}
		#end
	}

	static function collectHscriptCall(call:Expr, params:Array<Expr>):Void
	{
		switch (Tools.expr(call))
		{
			case EField(target, name, _):
				ScriptExprTools.hx_recursion(target, function (target)
				{
					if (!Tools.expr(target).match(EIdent('Paths'))) return;
					var key = assetKey(ScriptExprTools.hx_getValue(params[0]));
					if (key == null) return;
					var loading = LoadingState.instance;
					switch (name)
					{
						case 'image', 'cacheBitmap', 'getAtlas', 'getSparrowAtlas', 'getPackerAtlas', 'getAsepriteAtlas':
							loading.putPreload(loading.imagesToPrepare, key);
						case 'sound':
							loading.putPreload(loading.soundsToPrepare, key);
						case 'music':
							loading.putPreload(loading.musicToPrepare, key);
						default:
					}
				});
			default:
		}
	}
}
