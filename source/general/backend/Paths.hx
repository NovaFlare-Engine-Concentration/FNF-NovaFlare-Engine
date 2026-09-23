package general.backend;

import haxe.Json;

import sys.thread.Mutex;

import openfl.display.BitmapData;
import openfl.display3D.textures.RectangleTexture;
import openfl.utils.AssetType;
import openfl.utils.Assets;
import openfl.system.System;
import openfl.geom.Rectangle;
import openfl.media.Sound;

import flixel.graphics.frames.FlxFrame.FlxFrameAngle;
import flixel.graphics.frames.FlxFramesCollection;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.graphics.FlxGraphic;
import flixel.math.FlxRect;
import flixel.graphics.frames.FlxFrame;

//import general.backend.Cache; 用于拆分path代码功能过于冗杂的问题
class Paths
{
	inline public static var SOUND_EXT = #if web "mp3" #else "ogg" #end;
	inline public static var VIDEO_EXT = "mp4";

	inline static function trackedPath(path:String):String
	{
		DeepDebugTracker.recordResolved(path);
		return path;
	}

	static function releaseGraphicWhenUnused(graphic:FlxGraphic):Void
	{
		if (graphic == null || graphic.isDestroyed)
			return;

		// Cache clearing can overlap the old state's final update/draw. Keep
		// active sprites valid and let the final owner release the graphic.
		graphic.persist = false;
		graphic.destroyOnNoUse = true;
	}

	/** ★ 置 true 后下一次 returnSound（inst/voices 等）会跳过声音缓存、强制从磁盘重新加载
	 *  （用于编谱器"重载音频"：用户改了 Inst/Voices 文件后点重载要听到新文件） */
	public static var forceReloadSounds:Bool = false;

	public static function clearStoredMemory()
	{
		var clearStarted:Float = haxe.Timer.stamp();
		@:privateAccess
		for (key in FlxG.bitmap._cache.keys())
		{
			if (key == null) continue;
			var obj = FlxG.bitmap._cache.get(key);
			if (obj != null && !Cache.currentTrackedAssets.exists(key))
			{
				releaseGraphicWhenUnused(obj);
			}
		}

		// clear all frames that are cached
		for (key in Cache.currentTrackedFrames.keys())
		{
			if (key == null) continue;
			var cached = Cache.currentTrackedFrames.get(key);
			if (cached == null) continue;

			var graphic = cached.graphic;
			if (graphic == null && cached.frame != null)
				graphic = cached.frame.parent;

			releaseGraphicWhenUnused(graphic);
		}

		for (key in Cache.currentTrackedAnims.keys())
		{
			if (key == null) continue;
			var obj = Cache.currentTrackedAnims.get(key);
			if (obj != null)
			{
				obj.destroy();
			}
		}

		// clear all sounds that are cached
		for (key in Cache.currentTrackedSounds.keys())
		{
			if (key == null) continue;
			var shouldClear = !Cache.isLocalAsset(key) && !Cache.dumpExclusions.contains(key);
			if (shouldClear)
			{
				// OpenFL 声音缓存清理：不同版本 API 行为通常安全，这里保守地包一层存在性/空值保护
				if (Assets.cache != null)
					Assets.cache.clear(key);
				// 只有当 map 中仍存在该 key 时再移除，避免竞态
				if (Cache.currentTrackedSounds.exists(key))
					Cache.currentTrackedSounds.remove(key);
			}
		}

		// flags everything to be cleared out next unused memory clear
		Cache.resetLocalAssets();
		Cache.currentTrackedFrames = [];
		Cache.currentTrackedAnims = [];
		#if !html5 openfl.Assets.cache.clear("songs"); #end
	}

	/// haya I love you for the base cache dump I took to the max
	public static function clearUnusedMemory(?requestMajorGc:Bool = false)
	{
		var clearStarted:Float = haxe.Timer.stamp();
		// clear non local assets in the tracked assets list
		for (key in Cache.currentTrackedAssets.keys())
		{
			// if it is not currently contained within the used local assets
			if (!Cache.isLocalAsset(key) && !Cache.dumpExclusions.contains(key))
			{
				var obj = Cache.currentTrackedAssets.get(key);
				@:privateAccess
				if (obj != null)
				{
					Cache.currentTrackedAssets.remove(key);
					releaseGraphicWhenUnused(obj);
				}
			}
		}

		// Ordinary page transitions only release caches. A forced full cycle can
		// still have a short remark pause, so let NovaGC's allocation/promotion
		// policy schedule it unless a caller explicitly requests memory pressure
		// relief. This prevents every menu switch from creating a GC hitch.
		if (requestMajorGc)
			#if legacy_gc_compare
			cpp.vm.Gc.run(true);
			#else
			GCManager.requestFull();
			#end
	}

	///////////////////////////////////////////上面是缓存清除功能，下面是路径功能
	static public var currentLevel:String;
	static public function setCurrentLevel(name:String)
	{
		currentLevel = name.toLowerCase();
	}

	#if (sys && !windows)
	inline static function isJsonPath(file:String):Bool
	{
		return file != null && file.toLowerCase().endsWith('.json');
	}

	/**
	 * Resolves a relative path below a known root without changing the logical
	 * asset ID. Non-Windows filesystems preserve filename case, while Psych/NF
	 * chart IDs are deliberately normalized to lowercase.
	 */
	static function resolveCaseInsensitiveChild(root:String, relativePath:String):Null<String>
	{
		if (root == null || relativePath == null || !FileSystem.exists(root) || !FileSystem.isDirectory(root))
			return null;

		var relative:String = relativePath.replace('\\', '/');
		var exact:String = (root.endsWith('/') ? root : root + '/') + relative;
		if (FileSystem.exists(exact))
			return exact;

		var current:String = root;
		for (segment in relative.split('/'))
		{
			if (segment.length == 0 || segment == '.')
				continue;
			// All callers provide asset-relative paths. Never let a compatibility
			// lookup escape the mod/shared root.
			if (segment == '..' || !FileSystem.exists(current) || !FileSystem.isDirectory(current))
				return null;

			var direct:String = (current.endsWith('/') ? current : current + '/') + segment;
			if (FileSystem.exists(direct))
			{
				current = direct;
				continue;
			}

			var matched:String = null;
			var lowerSegment:String = segment.toLowerCase();
			var entries:Array<String>;
			try
			{
				entries = FileSystem.readDirectory(current);
			}
			catch (_:Dynamic)
			{
				return null;
			}

			for (entry in entries)
			{
				if (entry.toLowerCase() != lowerSegment)
					continue;

				// If two entries differ only by case, do not guess which file the
				// mod intended. An exact path would already have returned above.
				if (matched != null && matched != entry)
					return null;
				matched = entry;
			}

			if (matched == null)
				return null;
			current = (current.endsWith('/') ? current : current + '/') + matched;
		}

		return FileSystem.exists(current) ? current : null;
	}

	static function resolveCaseInsensitiveModFile(key:String):Null<String>
	{
		var roots:Array<String> = [];
		if (Mods.currentModDirectory != null && Mods.currentModDirectory.length > 0)
			roots.push(mods(Mods.currentModDirectory));

		for (mod in Mods.getGlobalMods())
		{
			var root:String = mods(mod);
			if (!roots.contains(root))
				roots.push(root);
		}

		var modsRoot:String = mods();
		if (!roots.contains(modsRoot))
			roots.push(modsRoot);

		var sharedRoot:String = #if mobile Sys.getCwd() + #end 'assets/shared';
		if (!roots.contains(sharedRoot))
			roots.push(sharedRoot);

		for (root in roots)
		{
			var resolved:String = resolveCaseInsensitiveChild(root, key);
			if (resolved != null)
				return trackedPath(resolved);
		}
		return null;
	}

	static function resolveCaseInsensitiveAssetId(path:String, type:AssetType):String
	{
		if (Assets.exists(path, type))
			return path;

		var matched:String = null;
		var lowerPath:String = path.toLowerCase();
		for (assetId in Assets.list(type))
		{
			if (assetId.toLowerCase() != lowerPath)
				continue;
			if (matched != null && matched != assetId)
				return path;
			matched = assetId;
		}
		return matched != null ? matched : path;
	}
	#end

	public static function getPath(file:String, ?type:AssetType = TEXT, ?library:Null<String> = null, ?modsAllowed:Bool = true):String
	{
		#if MODS_ALLOWED
		if (modsAllowed)
		{
			var customFile:String = file;
			if (library != null)
				customFile = '$library/$file';

			var modded:String = #if (sys && !windows) isJsonPath(customFile)
				? resolveCaseInsensitiveModFile(customFile) : modFolders(customFile) #else modFolders(customFile) #end;
			if (modded != null && FileSystem.exists(modded))
				return modded;
		}
		#end

		if (library != null)
		{
			var libraryPath:String = getLibraryPath(file, library);
			#if (sys && !windows)
			if (isJsonPath(file))
				libraryPath = resolveCaseInsensitiveAssetId(libraryPath, type);
			#end
			return libraryPath;
		}

		if (currentLevel != null)
		{
			var levelPath:String = '';
			if (currentLevel != 'shared')
			{
				levelPath = getLibraryPathForce(file, 'week_assets', currentLevel);
				#if (sys && !windows)
				if (isJsonPath(file))
					levelPath = resolveCaseInsensitiveAssetId(levelPath, type);
				#end
				if (Assets.exists(levelPath, type))
					return levelPath;
			}
		}
		var sharedPath:String = getSharedPath(file);
		#if (sys && !windows)
		if (isJsonPath(file))
			sharedPath = resolveCaseInsensitiveAssetId(sharedPath, type);
		#end
		return sharedPath;
	}

	static public function getLibraryPath(file:String, library = "shared")
	{
		return if (library == "shared") getSharedPath(file); else getLibraryPathForce(file, library);
	}

	inline static function getLibraryPathForce(file:String, library:String, ?level:String)
	{
		if (level == null)
			level = library;
		var returnPath = '$library:assets/$level/$file';
		return trackedPath(returnPath);
	}

	inline public static function getSharedPath(file:String = '')
	{
		return trackedPath('assets/shared/$file');
	}

	inline static public function txt(key:String, ?library:String)
	{
		return getPath('data/$key.txt', TEXT, library);
	}

	inline static public function xml(key:String, ?library:String)
	{
		return getPath('data/$key.xml', TEXT, library);
	}

	inline static public function json(key:String, ?library:String)
	{
		return getPath('data/$key.json', TEXT, library);
	}

	inline static public function shaderFragment(key:String, ?library:String)
	{
		return getPath('shaders/$key.frag', TEXT, library);
	}

	inline static public function shaderVertex(key:String, ?library:String)
	{
		return getPath('shaders/$key.vert', TEXT, library);
	}

	inline static public function lua(key:String, ?library:String)
	{
		return getPath('$key.lua', TEXT, library);
	}

	static public function video(key:String)
	{
		#if MODS_ALLOWED
		var file:String = modsVideo(key);
		if (FileSystem.exists(file))
		{
			return file;
		}
		#end
		return trackedPath('assets/videos/$key.$VIDEO_EXT');
	}

	static public function sound(key:String, ?library:String, ?threadLoad:Bool):Sound
	{
		var sound:Sound = returnSound('sounds', key, library, threadLoad);
		return sound;
	}

	inline static public function soundRandom(key:String, min:Int, max:Int, ?library:String)
	{
		return sound(key + FlxG.random.int(min, max), library);
	}

	inline static public function music(key:String, ?library:String, ?threadLoad:Bool):Sound
	{
		var file:Sound = returnSound('music', key, library, threadLoad);
		return file;
	}

	inline static public function songPath(song:String, ?postfix:String):String
	{
		var separator:Int = song.lastIndexOf('/');
		var key:String = separator >= 0
			? '${formatToSongPath(song.substr(0, separator))}/${song.substr(separator + 1)}'
			: formatToSongPath(song);
		if (postfix != null && postfix.length > 0)
			key += '-' + postfix;

		#if MODS_ALLOWED
		var file:String = modsSounds('songs/', key);

		if (FileSystem.exists(file))
		{
			return file;
		}
		#end

		return 'assets/songs/$key.$SOUND_EXT';
	}

	inline static public function voices(song:String, postfix:String = null):Any
	{
		var songKey:String = '${formatToSongPath(song)}/Voices';
		if (postfix != null)
			songKey += '-' + postfix;

		var voices = returnSound(null, songKey, 'songs');
		return voices;
	}

	inline static public function inst(song:String):Any
	{
		var songKey:String = '${formatToSongPath(song)}/Inst';
		var inst = returnSound(null, songKey, 'songs');
		return inst;
	}

	static public function image(key:String, ?library:String = null, ?allowGPU:Bool = true, disposeOnUpload:Bool = false):FlxGraphic
	{
		var bitmap:BitmapData = null;
		var file:String = null;

		#if MODS_ALLOWED
		file = modsImages(key);

		if (Cache.currentTrackedAssets.exists(file))
		{
			// 缓存可能已被释放（如 clearStoredMemory 标记 persist=false 后精灵销毁触发 destroy），
			// 命中已销毁的 graphic 会导致渲染崩溃，这里校验 bitmap 有效性
			var cached:FlxGraphic = Cache.currentTrackedAssets.get(file);
			if (cached != null && cached.bitmap != null)
			{
				Cache.trackLocalAsset(file);
				return cached;
			}
			Cache.currentTrackedAssets.remove(file);
		}
		if (FileSystem.exists(file))
			bitmap = BitmapData.fromFile(file, disposeOnUpload);
		else
		#end
		{
			file = getPath('images/$key.png', IMAGE, library);
			if (Cache.currentTrackedAssets.exists(file))
			{
				var cached:FlxGraphic = Cache.currentTrackedAssets.get(file);
				if (cached != null && cached.bitmap != null)
				{
					Cache.trackLocalAsset(file);
					return cached;
				}
				Cache.currentTrackedAssets.remove(file);
			}
			else if (Assets.exists(file, IMAGE)) {
				bitmap = Assets.getBitmapData(file);
				bitmap.disposeOnUpload = disposeOnUpload;
			}
		}

		if (bitmap != null)
			return cacheBitmap(file, bitmap, allowGPU);

		return null;
	}

	static public function imageEX(key:String, ?library:String = null, ?allowGPU:Bool = true, disposeOnUpload:Bool = false):FlxGraphic
	{
		var bitmap:BitmapData = null;
		var file:String = null;

		#if MODS_ALLOWED
		file = modsExImages(key);

		if (Cache.currentTrackedAssets.exists(file))
		{
			var cached:FlxGraphic = Cache.currentTrackedAssets.get(file);
			if (cached != null && cached.bitmap != null)
			{
				Cache.trackLocalAsset(file);
				return cached;
			}
			Cache.currentTrackedAssets.remove(file);
		}
		if (FileSystem.exists(file))
			bitmap = BitmapData.fromFile(file, disposeOnUpload);
		else
		#end
		{
			file = getPath('images/$key.png', IMAGE, library);
			if (Cache.currentTrackedAssets.exists(file))
			{
				var cached:FlxGraphic = Cache.currentTrackedAssets.get(file);
				if (cached != null && cached.bitmap != null)
				{
					Cache.trackLocalAsset(file);
					return cached;
				}
				Cache.currentTrackedAssets.remove(file);
			}
			else if (Assets.exists(file, IMAGE)) {
				bitmap = Assets.getBitmapData(file);
				bitmap.disposeOnUpload = disposeOnUpload;
			}
		}

		if (bitmap != null)
			return cacheBitmap(file, bitmap, allowGPU);

		return null;
	}

	static var bitmapMutex:Mutex = new Mutex();
	static public function cacheBitmap(file:String, ?bitmap:BitmapData = null, ?allowGPU:Bool = true, ?threadLoad:Bool = false)
	{
		if (bitmap == null)
		{
			#if MODS_ALLOWED
			if (FileSystem.exists(file))
				bitmap = BitmapData.fromFile(file);
			else
			#end
			{
				if (Assets.exists(file, IMAGE))
					bitmap = Assets.getBitmapData(file);
			}

			if (bitmap == null)
				return null;
		}
		DeepDebugTracker.recordResolved(file);

		var thread:Bool = false;
		if (threadLoad != null) thread = threadLoad;

		Cache.trackLocalAsset(file);
		
		if (allowGPU && ClientPrefs.data.cacheOnGPU && !thread)
		{
			var texture:RectangleTexture = FlxG.stage.context3D.createRectangleTexture(bitmap.width, bitmap.height, BGRA, true);
			texture.uploadFromBitmapData(bitmap);
			bitmap.image.data = null;
			bitmap.dispose();
			bitmap.disposeImage();
			bitmap = BitmapData.fromTexture(texture);
		}
		var newGraphic:FlxGraphic = FlxGraphic.fromBitmapData(bitmap, false, file);
		newGraphic.persist = true;
		newGraphic.destroyOnNoUse = false;
		newGraphic.bitmap.getTexture(FlxG.stage.context3D);
		if (thread) bitmapMutex.acquire();
			Cache.currentTrackedAssets.set(file, newGraphic);
			
		if (thread) bitmapMutex.release();
		
		return newGraphic;
	}

	static public function cacheBitmapPBO(file:String, bitmap:BitmapData,
		?onPBODeleted:Void->Void = null, ?sliceSize:Int = 512)
	{
		DeepDebugTracker.recordResolved(file);
		Cache.trackLocalAsset(file);
		var newGraphic:FlxGraphic = FlxGraphic.fromBitmapData(bitmap, false, file);
		newGraphic.persist = true;
		newGraphic.destroyOnNoUse = false;
		newGraphic.bitmap.getTextureAsync(FlxG.stage.context3D, function(tex) {
			if (onPBODeleted != null) onPBODeleted();
		}, sliceSize);
		Cache.currentTrackedAssets.set(file, newGraphic);
		
		return newGraphic;
	}

	static public function getMultiImage(key:String, ?library:String = null, ?allowGPU:Bool = true):FlxAtlasFrames
	{
		var myFrames = new FlxAtlasFrames(null);
		var pngList:Array<String> = [];
		var files:Array<String> = general.backend.CoolUtil.readDirectoryRecursive(Paths.getPath('images/' + key, null, library));
		for (file in files){
		var root = Paths.getPath('images/' + key) + '/';
			if (file.endsWith('.png'))
			{
				if (file.startsWith(root))
				{
				file = file.substr(root.length,file.length);
				}
			file = file.substr(0,file.length - 4);
			if (!pngList.contains(file))
			pngList.push(file);
			}
		}
		for (fileName in pngList){
                             var image:FlxGraphic = image(key + '/' + fileName, null, allowGPU);
		@:privateAccess
      		var anim = new FlxFrame(image);
    		anim.name = fileName;
    		anim.frame = FlxRect.get(0, 0, image.bitmap.width, image.bitmap.height);
    		anim.sourceSize.set(image.bitmap.width, image.bitmap.height);
    		anim.offset.set(0, 0);
    		myFrames.pushFrame(anim);
    		}
		
		return myFrames;
	}

	static public function getTextFromFile(key:String, ?ignoreMods:Bool = false):String
	{
		#if sys
		#if MODS_ALLOWED
		if (!ignoreMods && FileSystem.exists(modFolders(key)))
			return File.getContent(modFolders(key));
		#end

		if (FileSystem.exists(getSharedPath(key)))
			return File.getContent(getSharedPath(key));

		if (currentLevel != null)
		{
			var levelPath:String = '';
			if (currentLevel != 'shared')
			{
				levelPath = getLibraryPathForce(key, 'week_assets', currentLevel);
				if (FileSystem.exists(levelPath))
					return File.getContent(levelPath);
			}
		}
		#end
		var path:String = getPath(key, TEXT);
		if (Assets.exists(path, TEXT))
			return Assets.getText(path);
		return null;
	}

	inline static public function font(key:String)
	{
		#if MODS_ALLOWED
		var file:String = modsFont(key);
		if (FileSystem.exists(file))
		{
			return file;
		}
		#end
		return trackedPath('assets/fonts/$key');
	}

	public static function fileExists(key:String, type:AssetType, ?ignoreMods:Bool = false, ?library:String = null)
	{
		#if MODS_ALLOWED
		if (!ignoreMods)
		{
			for (mod in Mods.getGlobalMods())
				if (FileSystem.exists(mods('$mod/$key')))
					return true;

			if (FileSystem.exists(mods(Mods.currentModDirectory + '/' + key)) || FileSystem.exists(mods(key)))
				return true;

			if (FileSystem.exists(mods('$key')))
				return true;
			if (FileSystem.exists('assets/shared/' + key))
				return true;
		}
		#end

		if (Assets.exists(getPath(key, type, library, false)))
		{
			return true;
		}
		return false;
	}

	static public function getAtlas(key:String, ?library:String = null, ?allowGPU:Bool = true):FlxAtlasFrames
	{
		var useMod = false;
		var imageLoaded:FlxGraphic = image(key, library, allowGPU);

		var myXml:Dynamic = getPath('images/$key.xml', TEXT, library, true);
		if (Assets.exists(myXml) #if MODS_ALLOWED || (FileSystem.exists(myXml) && (useMod = true)) #end)
		{
			#if MODS_ALLOWED
			return FlxAtlasFrames.fromSparrow(imageLoaded, (useMod ? File.getContent(myXml) : myXml));
			#else
			return FlxAtlasFrames.fromSparrow(imageLoaded, myXml);
			#end
		}
		else
		{
			var myJson:Dynamic = getPath('images/$key.json', TEXT, library, true);
			if (Assets.exists(myJson) #if MODS_ALLOWED || (FileSystem.exists(myJson) && (useMod = true)) #end)
			{
				#if MODS_ALLOWED
				return FlxAtlasFrames.fromTexturePackerJson(imageLoaded, (useMod ? File.getContent(myJson) : myJson));
				#else
				return FlxAtlasFrames.fromTexturePackerJson(imageLoaded, myJson);
				#end
			}
		}
		return getPackerAtlas(key, library);
	}

	static public function getMultiAtlas(keys:Array<String>, ?parentFolder:String = null, ?allowGPU:Bool = true):FlxAtlasFrames
	{
		var parentFrames:FlxAtlasFrames = Paths.getAtlas(keys[0].trim());
		if (keys.length > 1)
		{
			var original:FlxAtlasFrames = parentFrames;
			parentFrames = new FlxAtlasFrames(parentFrames.parent);
			parentFrames.addAtlas(original, true);
			for (i in 1...keys.length)
			{
				var extraFrames:FlxAtlasFrames = Paths.getAtlas(keys[i].trim(), parentFolder, allowGPU);
				if (extraFrames != null)
					parentFrames.addAtlas(extraFrames, true);
			}
		}
		return parentFrames;
	}

	inline static public function getSparrowAtlas(key:String, ?library:String = null, ?allowGPU:Bool = true):FlxAtlasFrames
	{
		var imageLoaded:FlxGraphic = image(key, library, allowGPU);
		#if MODS_ALLOWED
		var xmlExists:Bool = false;

		var xml:String = modsXml(key);
		if (FileSystem.exists(xml))
			xmlExists = true;

		return FlxAtlasFrames.fromSparrow(imageLoaded, (xmlExists ? File.getContent(xml) : getPath('images/$key.xml', library)));
		#else
		return FlxAtlasFrames.fromSparrow(imageLoaded, getPath('images/$key.xml', library));
		#end
	}

	inline static public function getPackerAtlas(key:String, ?library:String = null, ?allowGPU:Bool = true):FlxAtlasFrames
	{
		var imageLoaded:FlxGraphic = image(key, library, allowGPU);
		#if MODS_ALLOWED
		var txtExists:Bool = false;

		var txt:String = modsTxt(key);
		if (FileSystem.exists(txt))
			txtExists = true;

		return FlxAtlasFrames.fromSpriteSheetPacker(imageLoaded, (txtExists ? File.getContent(txt) : getPath('images/$key.txt', library)));
		#else
		return FlxAtlasFrames.fromSpriteSheetPacker(imageLoaded, getPath('images/$key.txt', library));
		#end
	}

	inline static public function getAsepriteAtlas(key:String, ?library:String = null, ?allowGPU:Bool = true):FlxAtlasFrames
	{
		var imageLoaded:FlxGraphic = image(key, library, allowGPU);
		#if MODS_ALLOWED
		var jsonExists:Bool = false;

		var json:String = modsImagesJson(key);
		if (FileSystem.exists(json))
			jsonExists = true;

		return FlxAtlasFrames.fromTexturePackerJson(imageLoaded, (jsonExists ? File.getContent(json) : getPath('images/$key.json', library)));
		#else
		return FlxAtlasFrames.fromTexturePackerJson(imageLoaded, getPath('images/$key.json', library));
		#end
	}

	inline static public function formatToSongPath(path:String)
	{
		var invalidChars = ~/[~&\\;:<>#]/;
		var hideChars = ~/[.,'"%?!]/; // '

		var path = invalidChars.split(path.replace(' ', '-')).join("-");
		return hideChars.split(path).join("").toLowerCase();
	}

	
	static var soundMutex:Mutex = new Mutex();
	public static function returnSound(path:Null<String>, key:String, ?library:String, ?threadLoad:Bool = false, ?extraLoad:Bool = false)
	{
		#if MODS_ALLOWED
		var modLibPath:String = '';
		if (library != null)
			modLibPath = '$library/';
		if (path != null)
			modLibPath += '$path/';

		var thread:Bool = threadLoad;

		var file:String = '';
		
		if (!extraLoad)
		    file = modsSounds(modLibPath, key);
		else
		    file = modFolders(path);

		if (FileSystem.exists(file))
		{
			// ★ 强制重载：清除该文件的缓存条目，下次直接重新解码磁盘文件
			if (forceReloadSounds && Cache.currentTrackedSounds.exists(file))
				Cache.currentTrackedSounds.remove(file);
			if (!Cache.currentTrackedSounds.exists(file))
			{
				var sound = Sound.fromFile(file);
				if (thread) soundMutex.acquire();
				Cache.currentTrackedSounds.set(file, sound);
				if (thread) soundMutex.release();
			}
			// currentTrackedSounds is keyed by the resolved mod file path. Track
			// that same key so clearStoredMemory() does not evict and decode the
			// song again on every state restart.
			Cache.trackLocalAsset(file);
			return Cache.currentTrackedSounds.get(file);
		}
		#end

		// I hate this so god damn much
		var gottenPath:String = '$key.$SOUND_EXT';
		if (path != null)
			gottenPath = '$path/$gottenPath';
		gottenPath = getPath(gottenPath, SOUND, library);
		gottenPath = gottenPath.substring(gottenPath.indexOf(':') + 1, gottenPath.length);
		// trace(gottenPath);

		// ★ 强制重载：清除缓存条目后重新解码磁盘文件
		if (forceReloadSounds && Cache.currentTrackedSounds.exists(gottenPath))
			Cache.currentTrackedSounds.remove(gottenPath);
		if (!Cache.currentTrackedSounds.exists(gottenPath))
		{
			var retKey:String = (path != null) ? '$path/$key' : key;
			retKey = ((path == 'songs') ? 'songs:' : '') + getPath('$retKey.$SOUND_EXT', SOUND, library);
			if (Assets.exists(retKey, SOUND)) {
				var sound:Sound = Assets.getSound(retKey);
				if (thread) soundMutex.acquire();
				Cache.currentTrackedSounds.set(gottenPath, sound);
				if (thread) soundMutex.release();
			}
		}
		Cache.trackLocalAsset(gottenPath);
		return Cache.currentTrackedSounds.get(gottenPath);
	}

	#if MODS_ALLOWED
	inline static public function mods(key:String = '')
	{
		var result:String = #if mobile Sys.getCwd() + #end 'mods/' + key;
		if (DeepDebugTracker.active && key.length > 0 && FileSystem.exists(result))
			DeepDebugTracker.recordResolved(result);
		return result;
	}

	inline static public function modsFont(key:String)
	{
		return modFolders('fonts/' + key);
	}

	inline static public function modsJson(key:String)
	{
		var relativePath:String = 'data/' + key + '.json';
		#if (sys && !windows)
		var resolved:String = resolveCaseInsensitiveModFile(relativePath);
		if (resolved != null)
			return resolved;
		#end
		return modFolders(relativePath);
	}

	inline static public function modsVideo(key:String)
	{
		return modFolders('videos/' + key + '.' + VIDEO_EXT);
	}

	inline static public function modsSounds(path:String, key:String)
	{

		return modFolders(path + key + '.' + SOUND_EXT);
	}

	inline static public function modsImages(key:String)
	{
		return modFolders('images/' + key + '.png');
	}

	inline static public function modsExImages(key:String)
	{
		return modFolders(key + '.png');
	}

	inline static public function modsXml(key:String)
	{
		return modFolders('images/' + key + '.xml');
	}

	inline static public function modsTxt(key:String)
	{
		return modFolders('images/' + key + '.txt');
	}

	inline static public function modsImagesJson(key:String)
	{
		return modFolders('images/' + key + '.json');
	}

	static public function modFolders(key:String)
	{
		if (Mods.currentModDirectory != null && Mods.currentModDirectory.length > 0)
		{
			var fileToCheck:String = mods(Mods.currentModDirectory + '/' + key);
			if (FileSystem.exists(fileToCheck))
			{
				return trackedPath(fileToCheck);
			}
		} //检测当前mods有没有这个文件
		for (mod in Mods.getGlobalMods())
		{
			var fileToCheck:String = mods(mod + '/' + key);
			if (FileSystem.exists(fileToCheck))
				return trackedPath(fileToCheck);
		} //检测全部mods有没有这个文件
		var fileToCheck:String = mods(key);
		if (FileSystem.exists(fileToCheck))
		{
			return trackedPath(fileToCheck);
		} //检测mod的根目录有没有这个文件（列如mods/images）
		return trackedPath(#if mobile Sys.getCwd() + #end 'assets/shared/' + key);
	}

	static public function modCachePath(modPath:String, key:String)
	{
		if (modPath != '') modPath = modPath + '/';
		var fileToCheck:String = mods(modPath + key);
		if (FileSystem.exists(fileToCheck))
			return fileToCheck;

		for (mod in Mods.getGlobalMods())
		{
			var fileToCheck:String = mods(mod + '/' + key);
			if (FileSystem.exists(fileToCheck))
				return fileToCheck;
		}

		return #if mobile Sys.getCwd() + #end 'assets/shared/' + key;
	}
	#end

	#if flxanimate
	public static function loadAnimateAtlas(spr:FlxAnimate, folderOrImg:Dynamic, spriteJson:Dynamic = null, animationJson:Dynamic = null)
	{
		var changedAnimJson = false;
		var changedAtlasJson = false;
		var changedImage = false;

		if (spriteJson != null)
		{
			changedAtlasJson = true;
			spriteJson = File.getContent(spriteJson);
		}

		if (animationJson != null)
		{
			changedAnimJson = true;
			animationJson = File.getContent(animationJson);
		}

		// is folder or image path
		if (Std.isOfType(folderOrImg, String))
		{
			var originalPath:String = folderOrImg;
			for (i in 0...10)
			{
				var st:String = '$i';
				if (i == 0)
					st = '';

				if (!changedAtlasJson)
				{
					spriteJson = getTextFromFile('images/$originalPath/spritemap$st.json');
					if (spriteJson != null)
					{
						// trace('found Sprite Json');
						changedImage = true;
						changedAtlasJson = true;
						folderOrImg = Paths.image('$originalPath/spritemap$st');
						break;
					}
				}
				else if (Paths.fileExists('images/$originalPath/spritemap$st.png', IMAGE))
				{
					// trace('found Sprite PNG');
					changedImage = true;
					folderOrImg = Paths.image('$originalPath/spritemap$st');
					break;
				}
			}

			if (!changedImage)
			{
				// trace('Changing folderOrImg to FlxGraphic');
				changedImage = true;
				folderOrImg = Paths.image(originalPath);
			}

			if (!changedAnimJson)
			{
				// trace('found Animation Json');
				changedAnimJson = true;
				animationJson = getTextFromFile('images/$originalPath/Animation.json');
			}
		}

		spr.loadAtlasEx(folderOrImg, spriteJson, animationJson);
	}
	#end
}
