package originfunkin;

import haxe.Json;
import haxe.io.Path;

#if sys
import sys.FileSystem;
import sys.io.File;
#end

/**
 * Small engine-owned configuration that is readable before either frontend
 * creates its own save system.
 */
class OriginFunkinConfig
{
	public static inline final MODE_AUTO:String = "auto";
	public static inline final MODE_NOVFLARE:String = "novaflare";
	public static inline final MODE_ORIGIN:String = "origin";
	public static inline final MODE_CODENAME:String = "codename";
	public static inline final CONTAINER_FOLDER_NAME:String = "Funkin";
	public static inline final MOD_FOLDER_NAME:String = "mods-vslice";

	static inline final CONFIG_FILE_NAME:String = "chain.json";
	static inline final LEGACY_CONFIG_FILE_NAME:String = ".originFunkin.json";

	public static var preferredMode(default, null):String = MODE_AUTO;
	public static var hasEnteredOrigin(default, null):Bool = false;
	public static var originNoticeAcknowledged(default, null):Bool = false;
	public static var configPath(default, null):Null<String>;

	static var loadedPath:Null<String>;

	public static function load(force:Bool = false):Void
	{
		#if sys
		var path:String = resolveConfigPath();
		configPath = path;
		if (!force && loadedPath == path)
		{
			return;
		}
		loadedPath = path;
		resetDefaults();

		if (!FileSystem.exists(path) || FileSystem.isDirectory(path))
		{
			return;
		}

		try
		{
			var data:Dynamic = Json.parse(File.getContent(path));
			var savedMode:Dynamic = Reflect.field(data, "preferredMode");
			if (savedMode == MODE_NOVFLARE || savedMode == MODE_ORIGIN || savedMode == MODE_CODENAME || savedMode == MODE_AUTO)
			{
				preferredMode = savedMode;
			}
			hasEnteredOrigin = readBool(data, "hasEnteredOrigin");
			originNoticeAcknowledged = readBool(data, "originNoticeAcknowledged");
		}
		catch (error:Dynamic)
		{
			trace('[originFunkin] Could not read "$path": $error');
		}
		#else
		resetDefaults();
		#end
	}

	public static function shouldStartOrigin():Bool
	{
		load();
		return isDebugLaunch() || preferredMode == MODE_ORIGIN || preferredMode == MODE_AUTO;
	}

	public static function shouldStartCodeName():Bool
	{
		load();
		return !isDebugLaunch() && preferredMode == MODE_CODENAME;
	}

	/** Explicit test launches select Origin for this process without saving a mode. */
	static function isDebugLaunch():Bool
	{
		#if (sys && FEATURE_DEBUG_FUNCTIONS)
		for (argument in Sys.args())
			if (StringTools.startsWith(argument, "--origin-test=")) return true;
		#end
		return false;
	}

	public static function requestOrigin():Bool
	{
		load();
		preferredMode = MODE_ORIGIN;
		return save();
	}

	public static function requestNovaFlare():Bool
	{
		load();
		preferredMode = MODE_NOVFLARE;
		return save();
	}

	public static function requestCodeName():Bool
	{
		load();
		preferredMode = MODE_CODENAME;
		return save();
	}

	public static function markOriginEntered():Void
	{
		load();
		if (hasEnteredOrigin) return;
		hasEnteredOrigin = true;
		save();
	}

	public static function acknowledgeOriginNotice():Void
	{
		load();
		if (originNoticeAcknowledged) return;
		originNoticeAcknowledged = true;
		save();
	}

	public static function getModRoot(originAssetsRoot:String):String
	{
		return Path.join([Path.directory(originAssetsRoot), MOD_FOLDER_NAME]);
	}

	public static function save():Bool
	{
		#if sys
		if (configPath == null || configPath.length == 0)
		{
			configPath = resolveConfigPath();
		}

		try
		{
			var parent:String = Path.directory(configPath);
			if (parent != null && parent.length > 0 && !FileSystem.exists(parent))
			{
				FileSystem.createDirectory(parent);
			}
			File.saveContent(configPath, Json.stringify({
				version: 2,
				preferredMode: preferredMode,
				hasEnteredOrigin: hasEnteredOrigin,
				originNoticeAcknowledged: originNoticeAcknowledged,
			}, null, "  "));
			return true;
		}
		catch (error:Dynamic)
		{
			trace('[originFunkin] Could not save "$configPath": $error');
			return false;
		}
		#else
		return false;
		#end
	}

	#if sys
	static function resolveConfigPath():String
	{
		var runtimeDirectory:String = Sys.getCwd();

		// Desktop launches may inherit an unrelated shell working directory.
		// The executable directory is the engine runtime directory there.
		#if desktop
		var programPath:String = Sys.programPath();
		if (programPath != null && programPath.length > 0)
		{
			var programDirectory:String = Path.directory(programPath);
			if (programDirectory != null && programDirectory.length > 0)
			{
				runtimeDirectory = programDirectory;
			}
		}
		#end

		var legacyCandidate:String = Path.normalize(Path.join([runtimeDirectory, LEGACY_CONFIG_FILE_NAME]));
		if (FileSystem.exists(legacyCandidate) && !FileSystem.isDirectory(legacyCandidate))
		{
			return legacyCandidate;
		}

		var candidate:String = Path.normalize(Path.join([runtimeDirectory, CONTAINER_FOLDER_NAME, CONFIG_FILE_NAME]));

		// FileSystem.fullPath() can return null for a file that does not exist yet
		// on Android. Keep the already-absolute runtime path so the first save can
		// create the configuration beside the engine's runtime files.
		#if android
		return candidate;
		#else
		var resolved:Null<String> = FileSystem.fullPath(candidate);
		return resolved == null || resolved.length == 0 ? candidate : resolved;
		#end
	}
	#end

	static function resetDefaults():Void
	{
		preferredMode = MODE_AUTO;
		hasEnteredOrigin = false;
		originNoticeAcknowledged = false;
	}

	static function readBool(data:Dynamic, field:String):Bool
	{
		return Reflect.hasField(data, field) && Reflect.field(data, field) == true;
	}
}
