package states.loadingState;

import haxe.Json;

import sys.thread.Mutex;

import lime.utils.Assets;
import lime.system.ThreadPool;
import lime.system.WorkOutput;

import openfl.utils.AssetType;
import openfl.utils.Assets as OpenFlAssets;
import openfl.display.BitmapData;
import openfl.display.Shape;

import luahscript.exprs.LuaExpr;
import luahscript.LuaParser;

import crowplexus.hscript.Expr;
import crowplexus.hscript.Tools;
import crowplexus.hscript.Parser;

import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxFilterFrames;

import general.backend.thread.ThreadEvent;
import general.backend.DeepDebugTracker;
import states.loadingState.backend.*;

import states.freeplayState.FreeplayState;
import states.loadingState.backend.ScriptExprTools;

import games.backend.Song;
import games.backend.StageData;
import games.backend.Rating;
import games.cutscenes.DialogueBoxPsych;

class LoadingState extends MusicBeatState
{
	public static var instance:LoadingState = null;
	public var waitPrepare:Bool = false;
	var _loaded:Int = 0;
	public var loaded(get, set):Int;
	public var loadMax:Int = 0;

	var requestedBitmaps:Map<String, BitmapData> = []; //储存下加载的纹理，再最后进入playstate的时候输出总结

	var loadThread:ThreadPool = null; //真正加载时的总线程池
	var prepareEvent:ThreadEvent = null;

	var prepareMutex:Mutex = new Mutex(); //准备资源锁，这是为了防止数据提前被主线程接收

	static var isPlayState:Bool = false; //如果是要进入playstate
	static var lastSongLoaded:String = null; //最后一次加载的歌曲/模组缓存上下文

	static function prepareSongCache():Void
	{
		if (PlayState.SONG == null)
			return;

		var modDirectory:String = Mods.currentModDirectory;
		if (modDirectory == null)
			modDirectory = '';
		var level:String = Paths.currentLevel;
		if (level == null)
			level = '';
		var cacheKey:String = '$modDirectory|$level|${PlayState.SONG.song}';

		if (lastSongLoaded != cacheKey)
		{
			lastSongLoaded = cacheKey;
			Paths.clearStoredMemory();
			Paths.clearUnusedMemory();
		}
	}

	function new(target:FlxState, stopMusic:Bool)
	{
		this.target = target;
		this.stopMusic = stopMusic;
		loaded = 0;
		super();
	}

	inline static public function loadAndSwitchState(target:FlxState, stopMusic = false, intrusive:Bool = true)
	{
		if (ClientPrefs.data.deepDebug && Std.isOfType(target, PlayState) && PlayState.SONG != null)
			DeepDebugTracker.begin(PlayState.SONG.song, Mods.currentModDirectory, Difficulty.getString());
		MusicBeatState.switchState(getNextState(target, stopMusic, intrusive));
	}

	function get_loaded():Int {
		return _loaded;
	}

	function set_loaded(v:Int):Int {
		_loaded = v;
		if (loadMax > 0)
			intendedPercent = _loaded / loadMax;
		else
			intendedPercent = 1;
		return v;
	}

	function set_curPercent(v:Float):Float {
		if (curPercent == v) return v;
		curPercent = v;

		bar.scale.x = button.width / 2 + (FlxG.width - button.width) * curPercent;
		button.x = FlxG.width * curPercent - button.width * curPercent;
		bar.updateHitbox();
		button.updateHitbox();
		var precent:Float = Math.floor(curPercent * 10000) / 100;
		if (precent % 1 == 0)
			precentText.text = precent + '.00%';
		else if ((precent * 10) % 1 == 0)
			precentText.text = precent + '0%';
		else
			precentText.text = precent + '%'; // 修复显示问题

		if (curPercent == 1)
		{
			FlxTimer.wait(0.1, () -> {
				onLoad();
			});
		}

		return v;
	}

	static function getNextState(target:FlxState, stopMusic = false, intrusive:Bool = true):FlxState
	{
		var directory:String = 'shared';
		var weekDir:String = StageData.forceNextDirectory;
		StageData.forceNextDirectory = null;

		if (weekDir != null && weekDir.length > 0 && weekDir != '')
			directory = weekDir;

		Paths.setCurrentLevel(directory);
		trace('Setting asset folder to ' + directory);

		if (Std.isOfType(target, PlayState))
			prepareSongCache();

		var doPrecache:Bool = false; //建议别去动这个
		if (ClientPrefs.data.loadingScreen)
		{
			if (intrusive)
			{
					return new LoadingState(target, stopMusic);
			}
			else
				doPrecache = true;
		}

		if (stopMusic && FlxG.sound.music != null)
			FlxG.sound.music.stop();

		if (doPrecache)
		{
			var loader = new LoadingState(target, stopMusic);
			instance = loader;
			DataPreload.startPrepare();
			loader.startThreads();
			while (true)
			{
				if (loader.checkLoaded())
				{
					loader.imagesToPrepare = [];
					loader.soundsToPrepare = [];
					loader.musicToPrepare = [];
					loader.songsToPrepare = [];
					if (loader.loadThread != null) loader.loadThread.cancel(); // kill all workers safely
					loader.loadThread = null;
					break;
				}
				else
					Sys.sleep(0.01);
			}
		}
		return target;
	}

	var target:FlxState = null;
	var stopMusic:Bool = false;

	var filePath:String = 'menuExtend/LoadingState/';

	var bar:FlxSprite;

	var button:Rect;
	var barHeight:Int = 10;

	var intendedPercent:Float = 0;
	var curPercent(null, set):Float = 0;
	var precentText:FlxText;
	var loads:FlxSprite;

	override function create()
	{
		prepareSongCache();

		instance = this;

		var bg = new FlxSprite().loadGraphic(Paths.image(filePath + 'loadScreen'));
		bg.setGraphicSize(Std.int(FlxG.width));
		bg.antialiasing = ClientPrefs.data.antialiasing;
		bg.updateHitbox();
		add(bg);

		loads = new FlxSprite().loadGraphic(Paths.image(filePath + 'loadIcon'));
		loads.antialiasing = ClientPrefs.data.antialiasing;
		loads.updateHitbox();
		loads.x = FlxG.width - loads.width - 2;
		loads.y = 5;
		add(loads);

		var bg:FlxSprite = new FlxSprite(0, FlxG.height - barHeight).makeGraphic(1, 1, FlxColor.BLACK);
		bg.scale.set(FlxG.width, barHeight);
		bg.updateHitbox();
		bg.alpha = 0.4;
		bg.screenCenter(X);
		add(bg);

		bar = new FlxSprite(0, FlxG.height - barHeight).makeGraphic(1, 1, FlxColor.WHITE);
		bar.scale.set(0, barHeight);
		bar.alpha = 0.6;
		bar.updateHitbox();
		add(bar);

		button = new Rect(0, 0, 35, barHeight, 10, 10);
		button.y = FlxG.height - button.height;
		button.antialiasing = ClientPrefs.data.antialiasing;
		button.updateHitbox();
		add(button);

		precentText = new FlxText(520, 600, 400, '0%', 30);
		precentText.setFormat(Paths.font("loadScreen.ttf"), 25, FlxColor.WHITE, RIGHT, OUTLINE_FAST, FlxColor.TRANSPARENT);
		precentText.borderSize = 0;
		precentText.antialiasing = ClientPrefs.data.antialiasing;
		add(precentText);
		precentText.x = FlxG.width - precentText.width - 2;
		precentText.y = FlxG.height - precentText.height - barHeight - 2;

		var JustSay = new FlxText(0, FlxG.height - precentText.height - barHeight - 2, FlxG.width, '', 30);
		JustSay.setFormat(Paths.font(Language.get('fontName', 'main') + '.ttf'), 25, FlxColor.WHITE, LEFT, OUTLINE_FAST, FlxColor.TRANSPARENT);
		JustSay.antialiasing = ClientPrefs.data.antialiasing;
		JustSay.x = 10;
		add(JustSay);
		try {
			var filename = 'language/JustSay/JustSay-' + Language.get('justsayLang', 'main') + '.txt';
			var file = File.getContent(Paths.getSharedPath(filename));
			var lines = file.split('
');
			JustSay.text = 'Tags: ' + lines[FlxG.random.int(0, lines.length)];
		} catch (e) { JustSay.text = ''; }

		GCManager.enable(false);

		super.create();

		FlxG.signals.postUpdate.addOnce(function()
		{
			prepareEvent = ThreadEvent.create(function() {
				prepareMutex.acquire();
				waitPrepare = true;
				DataPreload.startPrepare();
				prepareMutex.release();
			}, startThreads);
		});
	}

	public var imagesToPrepare:Array<String> = [];
	public var soundsToPrepare:Array<String> = [];
	public var musicToPrepare:Array<String> = [];
	public var songsToPrepare:Array<String> = [];

	public var chartEvents:Array<Array<Dynamic>> = [];
	public var chartNoteTypes:Array<String> = [];

	public function prepare(images:Array<String> = null, sounds:Array<String> = null, music:Array<String> = null)
	{
		if (images != null)
			for (file in images) putPreload(imagesToPrepare, file);
		if (sounds != null)
			for (file in sounds) putPreload(soundsToPrepare, file);
		if (music != null)
			for (file in music) putPreload(musicToPrepare, file);
	}

	public static function prepareToSong()
	{
		if (!ClientPrefs.data.loadingScreen)
			return;

		isPlayState = true;
	}

	//上面为数据准备部分
	///////////////////////////////////////////
	//下面开始游戏加载流程

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		loads.angle += 1.5;

		if (curPercent != intendedPercent)
		{
			if (Math.abs(curPercent - intendedPercent) < 0.005)
				curPercent = intendedPercent;
			else
				curPercent = FlxMath.lerp(intendedPercent, curPercent, Math.exp(-elapsed * 15));
		};
	}

	function onLoad() //加载完毕进行跳转
	{
		if (!checkLoaded()) return;

		if (stopMusic && FlxG.sound.music != null)
			FlxG.sound.music.stop();
		if (FreeplayState.vocalsPlayer1 != null)
			FreeplayState.destroyFreeplayVocals();

		imagesToPrepare = [];
		soundsToPrepare = [];
		musicToPrepare = [];
		songsToPrepare = [];
		requestedBitmaps.clear();

		if (loadThread != null) {
			loadThread.cancel();
			loadThread = null;
		}
		if (prepareEvent != null) {
			prepareEvent.cancel();
			prepareEvent.destroy();
			prepareEvent = null;
		}
		
		// PlayState performs the matching enable at the end of its create()
		// method. Resuming here lets the collector race the heaviest state
		// construction and turns the loading debt into a visible catch-up pause.
		if (!isPlayState)
			GCManager.enable(true);

		if (isPlayState)
		{
			isPlayState = false;
			FlxTransitionableState.skipNextTransIn = true;
			FlxTransitionableState.skipNextTransOut = true;
			MusicBeatState.switchState(new PlayState());
		}
		else
		{
			requestedBitmaps.clear();
			MusicBeatState.switchState(target);
		}
	}

	function checkLoaded():Bool
	{
		for (key => bitmap in requestedBitmaps)
		{
			if (bitmap != null && Paths.cacheBitmap(key, bitmap, false) != null) {
				trace('IMAGE: finished preloading image $key');
			} else
				trace('IMAGE: failed to cache image $key');
		}
		return (loaded >= loadMax);
	}

	public function startThreads()
	{
		clearInvalids();
		requestedBitmaps.clear();
		loadMax = imagesToPrepare.length + soundsToPrepare.length + musicToPrepare.length + songsToPrepare.length;
		loaded = 0;

		//trace('LoadingState: startThreads, loadMax: $loadMax');
		loadThread = new ThreadPool(ClientPrefs.data.loadThreads, ClientPrefs.data.loadThreads, MULTI_THREADED);
		threadInit();

		for (sound in soundsToPrepare)
			threadWork(() -> 
			{
				return {type:'sound', path:sound, file:Paths.sound(sound, true), alreadyLoaded: false, error: null};
			});

		for (music in musicToPrepare)
			threadWork(() ->
			{
				return {type:'music', path:music, file:Paths.music(music, true), alreadyLoaded: false, error: null};
			});
		for (song in songsToPrepare)
			threadWork(() ->
			{
				return {type:'song', path:song, file:Paths.returnSound(null, song, 'songs', true), alreadyLoaded: false, error: null};
			});

		
		for (image in imagesToPrepare) {
			threadWork(() -> 
			{
				var bitmap:BitmapData = null;
				var realPath:String = null;

				#if MODS_ALLOWED
				realPath = Paths.modsImages(image);
				if (Cache.currentTrackedAssets.exists(realPath))
				{
					return {type:'image', path: realPath, file: null, alreadyLoaded: true, error: null};
				}
				else if (FileSystem.exists(realPath)) {
					try { 
						bitmap = BitmapData.fromFile(realPath, true); 
					} catch(e) {
						return {type:'image', path: realPath, file: null, alreadyLoaded: false, error: e};
					}
				}
				else
				#end
				{
					realPath = Paths.getPath('images/$image.png', IMAGE);
					if (Cache.currentTrackedAssets.exists(realPath))
					{
						return {type:'image', path: realPath, file: null, alreadyLoaded: true, error: null};
					}
					else if (OpenFlAssets.exists(realPath, IMAGE)) {
						try { 
							bitmap = OpenFlAssets.getBitmapData(realPath); 
							bitmap.disposeOnUpload = true;
						} catch(e) {
							return {type:'image', path: realPath, file: null, alreadyLoaded: false, error: e};
						}
					}
				}
				return {type:'image', path: realPath, file: bitmap, alreadyLoaded: false, error: null};
			});
		};
	}

	function threadInit():Void {
		loadThread.onComplete.add(function(msg:{type:String, path:String, file:Dynamic, alreadyLoaded:Bool, error:Dynamic}) {
			switch (msg.type) {
				case 'sound', 'song', 'music':
					trace(msg.type.toUpperCase() + ': finished preloading ' + msg.path);
				case 'image':
					if (!msg.alreadyLoaded) {
						requestedBitmaps.set(msg.path, msg.file);
					}
			}
			addLoadCount();
		});
		loadThread.onError.add(function(msg:{type:String, path:String, error:Dynamic}) {
			if (msg.error != null) {
				switch (msg.type) {
					case 'system':
						trace('SYSTEM: data send error because of ' + msg.error);
					case _:
						trace(msg.type.toUpperCase() + ': ERROR! fail on preloading because of ' + msg.error);
				}
			} else {
				trace(msg.type.toUpperCase() + ': no such ' + msg.path + ' exists');
			}
			addLoadCount();
		});
	}

	function threadWork(func:Void->Dynamic):Void {
		loadThread.run(sendThreadData, {func: func});
	}

	static function sendThreadData(state:{func:Void->Dynamic}, out:WorkOutput):Void {
		try {
			var result:Dynamic = state.func();

			if (result.error == null) {
				switch (result.type) {
					case 'sound', 'song', 'music':
						if ((Reflect.hasField(result, "file") && result.file != null)) 
						{
							out.sendComplete({type:result.type, path: result.path, file: result.file, error: result.error});
						} else {
							out.sendError({type:result.type, path: result.path, error:null});
						}
					case 'image':
						if ((Reflect.hasField(result, "file") && result.file != null) || 
							(Reflect.hasField(result, "alreadyLoaded") && result.alreadyLoaded)) 
						{
							out.sendComplete({type:result.type, path: result.path, file: result.file, alreadyLoaded: result.alreadyLoaded, error: result.error});
						} else {
							out.sendError({type:result.type, path: result.path, error:null});
						}
				}
			}
			else out.sendError({type:result.type, path: result.path, error: result.error});
		} catch (e:Dynamic) {
			out.sendError({type: 'system', path:null, error: e});
		}
	}

	///////////////////////////////////////////////////////////////////////////////

	public function addLoadCount() {
		loaded++;
	}

	public function putPreload(tar:Dynamic, file:String) {
		if (!tar.contains(file)) tar.push(file);
	}

	//////////////////////////////////////////////

	public function clearInvalids()
	{
		clearInvalidFrom(imagesToPrepare, 'images', '.png', IMAGE);
		clearInvalidFrom(soundsToPrepare, 'sounds', '.${Paths.SOUND_EXT}', SOUND);
		clearInvalidFrom(musicToPrepare, 'music', '.${Paths.SOUND_EXT}', SOUND);
		clearInvalidFrom(songsToPrepare, 'songs', '.${Paths.SOUND_EXT}', SOUND);

		for (arr in [imagesToPrepare, soundsToPrepare, musicToPrepare, songsToPrepare])
			while (arr.contains(null))
				arr.remove(null);
	}

	function clearInvalidFrom(arr:Array<String>, prefix:String, ext:String, type:AssetType, ?library:String = null)
	{
		for (i in 0...arr.length)
		{
			var folder:String = arr[i];
			if (folder.trim().endsWith('/'))
			{
				for (subfolder in Mods.directoriesWithFile(Paths.getSharedPath(), '$prefix/$folder'))
					for (file in FileSystem.readDirectory(subfolder))
						if (file.endsWith(ext))
							arr.push(folder + file.substr(0, file.length - ext.length));
			}
		}

		var i:Int = 0;
		while (i < arr.length)
		{
			var member:String = arr[i];
			var myKey = '$prefix/$member$ext';
			// if(library == 'songs') myKey = '$member$ext';

			//trace('attempting on $prefix: $myKey');
			var doTrace:Bool = false;
			if (member.endsWith('/') || (!Paths.fileExists(myKey, type, false, library) && (doTrace = true)))
			{
				arr.remove(member);
			}
			else
				i++;
		}
	}
	
	//////////////////////////////////////////////

	
}
