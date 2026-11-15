package codename.funkin.backend.assets;

#if TRANSLATIONS_SUPPORT
import codename.funkin.backend.assets.TranslatedAssetLibrary;
#end
import codename.funkin.backend.assets.IModsAssetLibrary;
import codename.funkin.backend.assets.AssetSource;
import lime.utils.AssetLibrary;
import haxe.ds.Map;

class AssetsLibraryList extends AssetLibrary {

	public var libraries:Array<AssetLibrary> = [];
	public var cleanLibraries(get, never):Array<AssetLibrary>;
	function get_cleanLibraries():Array<AssetLibrary> {
		return [for (l in libraries) getCleanLibrary(l)];
	}

	public var rootDirectory:String = "./assets";
	
	// is true if any library in `libraries` contains some kind of compressed library. 
	public var hasCompressedLibrary(get, never):Bool;
	function get_hasCompressedLibrary():Bool {
		for (l in libraries) if (getCleanLibrary(l).isCompressed) return true;
		return false;
	}

	@:allow(codename.funkin.backend.system.Main)
	@:allow(codename.funkin.backend.system.MainState)
	private var __defaultLibraries:Array<AssetLibrary> = [];
	public var base:AssetLibrary;

	#if TRANSLATIONS_SUPPORT
	public var transLib:TranslatedAssetLibrary;
	#end

	private var cacheLibraryTypePaths:Map<String, Map<String, AssetLibrary>> = [];
	private var cacheTimeTypePaths:Map<String, Map<String, Float>> = [];
	private var cacheLastLibraryPaths:Map<String, AssetLibrary> = [];
	private var cacheLastLibraryTimes:Map<String, Float> = [];
	private var cacheDirectoryEntries:Map<String, Array<String>> = [];
	private var cacheDirectoryTimes:Map<String, Float> = [];
	public var cacheGeneration(default, null):Int = 0;

	// Retain NF's six-second default while honoring upstream's 0 (disabled)
	// and null (until explicit invalidation) cache lifetime settings.
	private inline function getCacheLifetime():Float
		return Flags.PATHS_CACHE_LIFETIME == null ? Math.POSITIVE_INFINITY : Flags.PATHS_CACHE_LIFETIME;

	private inline function getCacheTypeKey(type:Null<String>, source:AssetSource):String
		return '${type == null ? "<null>" : type}|${source.toString()}';
	private inline function getCachePathKey(id:String, source:AssetSource):String
		return '${source.toString()}|$id';
	private inline function getDirectoryCacheKey(kind:String, folder:String, source:AssetSource):String
		return '$kind|${source.toString()}|${folder.toLowerCase()}';

	private inline function clearExistsCache():Void {
		#if MOD_SUPPORT
		for (library in libraries) {
			var cleanLibrary = getCleanLibrary(library);
			if (cleanLibrary is ModsFolderLibrary)
				cast(cleanLibrary, ModsFolderLibrary).invalidateLookupCaches();
		}
		#end
		cacheLibraryTypePaths.clear();
		cacheTimeTypePaths.clear();
		cacheLastLibraryPaths.clear();
		cacheLastLibraryTimes.clear();
		cacheDirectoryEntries.clear();
		cacheDirectoryTimes.clear();
		cacheGeneration++;
	}

	public inline function invalidateLookupCaches():Void
		clearExistsCache();

	private inline function rememberLastLibrary(id:String, source:AssetSource, library:AssetLibrary, time:Float):Void {
		var key = getCachePathKey(id, source);
		cacheLastLibraryPaths.set(key, library);
		cacheLastLibraryTimes.set(key, time);
	}

	public function removeLibrary(lib:AssetLibrary) {
		if (lib != null) {
			libraries.remove(lib);
			clearExistsCache();
			#if TRANSLATIONS_SUPPORT
			// TODO: improve this code
			for(k=>l in libraries) {
				if(l == null) continue;
				if(l is TranslatedAssetLibrary) {
					var tlib = cast(l, TranslatedAssetLibrary);
					var lib:Dynamic = lib;
					if(tlib.forLibrary == lib) {
						libraries.remove(tlib);
						break;
					}
				}
			}
			#end
		}
		return lib;
	}
	public function existsSpecific(id:String, type:String, source:AssetSource = BOTH) {
		if (!id.startsWith("assets/") && existsSpecific('assets/$id', type, source))
			return true;

		// Prevent massive lags on repetitive usage. The NF integration includes
		// the source selector in the key so SOURCE, MODS and BOTH cannot collide.
		final sec = (lime.system.System.getTimer() * 0.001);
		final cacheTypeKey = getCacheTypeKey(type, source);

		var cacheLibraryPaths:Map<String, AssetLibrary> = cacheLibraryTypePaths.get(cacheTypeKey);
		var cacheTimePaths:Map<String, Float> = cacheTimeTypePaths.get(cacheTypeKey);
		if (cacheLibraryPaths == null) {
			cacheLibraryTypePaths.set(cacheTypeKey, cacheLibraryPaths = []);
			cacheTimeTypePaths.set(cacheTypeKey, cacheTimePaths = []);
		}

		if (cacheTimePaths.exists(id)) {
			final cacheSafetime = cacheTimePaths.get(id) + getCacheLifetime();
			if (cacheLibraryPaths.exists(id)) {
				if (sec < cacheSafetime) {
					rememberLastLibrary(id, source, cacheLibraryPaths.get(id), sec);
					return true;
				}

				// Once the TTL expires, rescan from the highest-priority library.
				// Revalidating only the old hit would hide a newly added mod override
				// forever as long as the lower-priority file still exists.
				cacheLibraryPaths.remove(id);
				var pathKey = getCachePathKey(id, source);
				cacheLastLibraryPaths.remove(pathKey);
				cacheLastLibraryTimes.remove(pathKey);
			}
			else if (sec < cacheSafetime) {
				return false;
			}
		}

		cacheTimePaths.set(id, sec);

		for (k=>l in libraries) {
			if (shouldSkipLib(l, source)) continue;
			if (l.exists(id, type)) {
				cacheLibraryPaths.set(id, l);
				rememberLastLibrary(id, source, l, sec);
				return true;
			}
		}

		return false;
	}
	public override inline function exists(id:String, type:String):Bool
		return existsSpecific(id, type, BOTH);

	/** Resolve through NF's priority-aware cache, including cached misses. */
	public function getAssetPathLibrary(id:String, ?type:String, source:AssetSource = BOTH):Null<AssetLibrary> {
		if (!existsSpecific(id, type, source)) return null;
		var paths = cacheLibraryTypePaths.get(getCacheTypeKey(type, source));
		if (paths == null) return null;
		if (paths.exists(id)) return paths.get(id);
		return paths.get('assets/$id');
	}

	public function getSpecificPath(id:String, source:AssetSource = BOTH) {
		var cacheKey = getCachePathKey(id, source);
		var cachedLibrary = cacheLastLibraryPaths.get(cacheKey);
		var cachedAt = cacheLastLibraryTimes.get(cacheKey);
		if (cachedLibrary != null && cachedAt != null && (lime.system.System.getTimer() * 0.001) < cachedAt + getCacheLifetime() && !shouldSkipLib(cachedLibrary, source)) {
			var cachedPath = cachedLibrary.getPath(id);
			if (cachedPath != null)
				return cachedPath;
		}
		cacheLastLibraryPaths.remove(cacheKey);
		cacheLastLibraryTimes.remove(cacheKey);

		for(k=>e in libraries) {
			if (shouldSkipLib(e, source)) continue;

			@:privateAccess
			if (e.exists(id, e.types.get(id))) {
				var path = e.getPath(id);
				if (path != null)
					return path;
			}
		}
		return null;
	}

	public override inline function getPath(id:String)
		return getSpecificPath(id, BOTH);

	public function getFiles(folder:String, source:AssetSource = BOTH):Array<String> {
		var cacheKey = getDirectoryCacheKey("files", folder, source);
		var now = (lime.system.System.getTimer() * 0.001);
		if (cacheDirectoryTimes.exists(cacheKey) && now < cacheDirectoryTimes.get(cacheKey) + getCacheLifetime()) {
			var cached = cacheDirectoryEntries.get(cacheKey);
			if (cached != null) return cached.copy();
		}

		var content:Array<String> = [];
		for(k=>l in libraries) {
			if (shouldSkipLib(l, source)) continue;

			l = getCleanLibrary(l);

			// TODO: do base folder scanning
			#if MOD_SUPPORT
			if (l is IModsAssetLibrary) {
				var lib = cast(l, IModsAssetLibrary);
				for(e in lib.getFiles(folder))
					content.pushOnce(e);
			}
			#end
		}
		cacheDirectoryEntries.set(cacheKey, content.copy());
		cacheDirectoryTimes.set(cacheKey, now);
		return content;
	}

	public function getFolders(folder:String, source:AssetSource = BOTH):Array<String> {
		var cacheKey = getDirectoryCacheKey("folders", folder, source);
		var now = (lime.system.System.getTimer() * 0.001);
		if (cacheDirectoryTimes.exists(cacheKey) && now < cacheDirectoryTimes.get(cacheKey) + getCacheLifetime()) {
			var cached = cacheDirectoryEntries.get(cacheKey);
			if (cached != null) return cached.copy();
		}

		var content:Array<String> = [];
		for(k=>l in libraries) {
			if (shouldSkipLib(l, source)) continue;

			l = getCleanLibrary(l);

			// TODO: do base folder scanning
			#if MOD_SUPPORT
			if (l is IModsAssetLibrary) {
				var lib = cast(l, IModsAssetLibrary);
				for(e in lib.getFolders(folder))
					content.pushOnce(e);
			}
			#end
		}
		cacheDirectoryEntries.set(cacheKey, content.copy());
		cacheDirectoryTimes.set(cacheKey, now);
		return content;
	}

	public function getSpecificAsset(id:String, type:String, source:AssetSource = BOTH):Dynamic {
		try {
			if (!id.startsWith("assets/")) {
				var ass = getSpecificAsset('assets/$id', type, source);
				if (ass != null) {
					return ass;
				}
			}
			var cacheTypeKey = getCacheTypeKey(type, source);
			var cacheLibraryPaths = cacheLibraryTypePaths.get(cacheTypeKey);
			var cacheTimePaths = cacheTimeTypePaths.get(cacheTypeKey);
			if (cacheLibraryPaths != null && cacheTimePaths != null && cacheLibraryPaths.exists(id)
				&& cacheTimePaths.exists(id) && (lime.system.System.getTimer() * 0.001) < cacheTimePaths.get(id) + getCacheLifetime()) {
				var cachedLibrary = cacheLibraryPaths.get(id);
				if (cachedLibrary != null && !shouldSkipLib(cachedLibrary, source)) {
					var cachedAsset = cachedLibrary.getAsset(id, type);
					if (cachedAsset != null)
						return cachedAsset;
				}
			}
			for(k=>l in libraries) {
				if (shouldSkipLib(l, source)) continue;

				@:privateAccess
				if (l.exists(id, l.types.get(id))) {
					var asset = l.getAsset(id, type);
					if (asset != null) {
						return asset;
					}
				}
			}
			return null;
		} catch(e) {
			// TODO: trace the error
			throw e;
		}
		return null;
	}

	private function shouldSkipLib(lib:AssetLibrary, source:AssetSource) {
		if (source == BOTH || lib.tag == BOTH) return false;
		return source != lib.tag;
	}
	public override inline function getAsset(id:String, type:String):Dynamic
		return getSpecificAsset(id, type, BOTH);

	public override function list(type:String):Array<String> {
		// idk if there's a more efficient way tbh, correct if u find better
		var files:Map<String, Bool> = [];
		for(k=>l in libraries) {
			for(f in l.list(type))
				files.set(f, false);
		}
		return [for(k=>e in files) k];
	}

	public override function isLocal(id:String, type:String) {
		return true;
	}

	public function new(?base:AssetLibrary) {
		super();
		if (base == null) (this.base = Assets.getLibrary("default")).tag = SOURCE;
		else this.base = base;
		__defaultLibraries.push(this.base);

		#if CODENAME_ENGINE_COMPAT
		// Keep CNE-only packaged fallbacks outside NovaFlare's default library,
		// then mount them underneath the external CodeName asset folder.
		var fallbackLibrary = Assets.getLibrary("codename_fallback");
		if (fallbackLibrary != null) {
			fallbackLibrary.tag = SOURCE;
			__defaultLibraries.push(fallbackLibrary);
		}
		#if mobile
		var mobileLibrary = Assets.getLibrary("codename_mobile");
		if (mobileLibrary != null) {
			mobileLibrary.tag = SOURCE;
			__defaultLibraries.push(mobileLibrary);
		}
		#end
		#end

		#if sys

		#if CODENAME_ENGINE_COMPAT
		var externalAssetsRoot:String = codenamechain.CodeNameMode.assetsRoot;
		if (externalAssetsRoot == null || externalAssetsRoot.length == 0)
			throw "CodeName external assets were not prepared before its asset library was created.";
		rootDirectory = externalAssetsRoot;
		#elseif TEST_BUILD
		Logs.infos("Used cne test / cne build. Switching into source assets.");
		switchToSourceAssets();
		#elseif USE_ADAPTED_ASSETS
		if (sys.FileSystem.exists('./${Main.pathBack}assets/') && !sys.FileSystem.exists('./assets/')) {
			Logs.infos("Source assets detected. Switching into source assets.");
			switchToSourceAssets();
		}
		#end

		__defaultLibraries.push(ModsFolder.loadLibraryFromFolder('assets', rootDirectory, true, null, SOURCE));

		#end

		for (d in __defaultLibraries) addLibrary(d);
	}

	#if sys
	inline function switchToSourceAssets() {
		#if MOD_SUPPORT
		ModsFolder.modsPath = './${Main.pathBack}mods/';
		ModsFolder.addonsPath = './${Main.pathBack}addons/';
		#end

		rootDirectory = './${Main.pathBack}assets/';
	}
	#end

	public function unloadLibraries() {
		for(l in libraries)
			if (!__defaultLibraries.contains(l))
				l.unload();
	}

	public function reset() {
		unloadLibraries();

		clearExistsCache();

		libraries.resize(0);

		// adds default libraries in again
		for (d in __defaultLibraries) addLibrary(d);
	}

	public function addLibrary(lib:AssetLibrary, ?tag:AssetSource, ?addTransLib:Bool = true) {
		libraries.insert(0, lib);
		clearExistsCache();
		if (tag != null) lib.tag = tag;
		else if (lib.tag == null) lib.tag = MODS;
		#if TRANSLATIONS_SUPPORT
		if(addTransLib) {
			var cleanLib = getCleanLibrary(lib);
			if(cleanLib != null && (cleanLib is IModsAssetLibrary)) {
				var transLib = new TranslatedAssetLibrary(cast(cleanLib, IModsAssetLibrary));
				transLib.tag = cleanLib.tag;
				libraries.insert(0, transLib);
			}
		}
		#end
		return lib;
	}

	public static function getCleanLibrary(e:AssetLibrary):AssetLibrary {
		var l = e;
		if (l is openfl.utils.AssetLibrary) {
			var al = cast(l, openfl.utils.AssetLibrary);
			@:privateAccess
			if (al.__proxy != null) l = al.__proxy;
		}
		return l;
	}
}
