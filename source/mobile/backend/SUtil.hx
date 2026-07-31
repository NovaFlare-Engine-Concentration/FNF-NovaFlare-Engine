package mobile.backend;

import lime.system.System as LimeSystem;

#if android
import android.jni.JNICache;
import android.os.Build.VERSION as AndroidVersion;
import android.os.Build.VERSION_CODES as AndroidVersionCode;
#end

/**
 * A storage class for mobile.
 * @author Mihai Alexandru (M.A. Jigsaw) and Lily (mcagabe19)
 */
class SUtil
{
	#if sys
	public static function getStorageDirectory(type:StorageType = EXTERNAL, ?folderOverride:String = null):String
	{
		var daPath:String = '';
		#if android
			var folderName:String = (folderOverride != null) ? folderOverride : lime.app.Application.current.meta.get("file");
		switch (type)
		{
			case EXTERNAL:
				daPath = AndroidEnvironment.getExternalStorageDirectory() + '/.' + folderName;
		}
		#elseif ios
		var folderName:String = (folderOverride != null) ? folderOverride : lime.app.Application.current.meta.get("file");
		if (folderName != null && folderName != '')
			daPath = haxe.io.Path.addTrailingSlash(LimeSystem.documentsDirectory) + folderName;
		else
			daPath = LimeSystem.documentsDirectory;
		#else
		daPath = Sys.getCwd();
		#end
		daPath = haxe.io.Path.addTrailingSlash(daPath);
		return daPath;
	}

	public static function mkDirs(directory:String):Void
	{
		var total:String = '';
		if (directory.substr(0, 1) == '/')
			total = '/';

		var parts:Array<String> = directory.split('/');
		if (parts.length > 0 && parts[0].indexOf(':') > -1)
			parts.shift();

		for (part in parts)
		{
			if (part != '.' && part != '')
			{
				if (total != '' && total != '/')
					total += '/';

				total += part;

				try
				{
					if (!FileSystem.exists(total))
						FileSystem.createDirectory(total);
				}
				catch (e:haxe.Exception)
					trace('Error while creating folder. (${e.message}');
			}
		}
	}

	public static function saveContent(fileName:String = 'file', fileExtension:String = '.json',
			fileData:String = 'You forgor to add somethin\' in yo code :3'):Void
	{
		try
		{
			if (!FileSystem.exists('saves'))
				FileSystem.createDirectory('saves');

			File.saveContent('saves/' + fileName + fileExtension, fileData);
			showPopUp(fileName + " file has been saved.", "Success!");
		}
		catch (e:haxe.Exception)
			trace('File couldn\'t be saved. (${e.message})');
	}

	#if android
	public static function doPermissionsShit():Void
	{
		if (AndroidVersion.SDK_INT >= AndroidVersionCode.R) // Android 11 (API 30) and above
		{
			if (!AndroidEnvironment.isExternalStorageManager())
				AndroidSettings.requestSetting('MANAGE_APP_ALL_FILES_ACCESS_PERMISSION');
		}
		else // Android 10 and below
		{
			if (!AndroidPermissions.getGrantedPermissions().contains('android.permission.READ_EXTERNAL_STORAGE')
				|| !AndroidPermissions.getGrantedPermissions().contains('android.permission.WRITE_EXTERNAL_STORAGE'))
			{
				AndroidPermissions.requestPermissions(['READ_EXTERNAL_STORAGE', 'WRITE_EXTERNAL_STORAGE']);
			}
		}

		if ((AndroidVersion.SDK_INT >= AndroidVersionCode.R
			&& !AndroidEnvironment.isExternalStorageManager())
			|| (AndroidVersion.SDK_INT < AndroidVersionCode.R
				&& (!AndroidPermissions.getGrantedPermissions().contains('android.permission.READ_EXTERNAL_STORAGE')
					|| !AndroidPermissions.getGrantedPermissions().contains('android.permission.WRITE_EXTERNAL_STORAGE'))))
			showPopUp('If you accepted the permissions you are all good!' + '\nIf you didn\'t then expect a crash' + '\nPress OK to see what happens',
				'Notice!');

		try
		{
			if (!FileSystem.exists(SUtil.getStorageDirectory()))
				FileSystem.createDirectory(SUtil.getStorageDirectory());
		}
		catch (e:Dynamic)
		{
			showPopUp("Please create folder to\n"
				+ #if EXTERNAL "/storage/emulated/0/."
				+ lime.app.Application.current.meta.get('file') #elseif MEDIA "/storage/emulated/0/Android/media/"
				+ lime.app.Application.current.meta.get('packageName') #else SUtil.getStorageDirectory() #end
				+ "\nPress OK to close the game",
				"Error!");
			LimeSystem.exit(1);
		}
	}
	#end

	public static function showPopUp(message:String, title:String):Void
	{
		#if android
		// AndroidTools wraps even a null callback in a temporary HaxeObject.
		// The Java dialog can outlive that wrapper and call an invalid native
		// object when OK is pressed. Pass null callback objects to Java instead.
		JNICache.createStaticMethod('org/haxe/extension/Tools', 'showAlertDialog',
			'(Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;Lorg/haxe/lime/HaxeObject;Ljava/lang/String;Lorg/haxe/lime/HaxeObject;)V')(title,
				message, 'OK', null, null, null);
		#else
		FlxG.stage.window.alert(message, title);
		#end
	}
	#end
}

enum StorageType
{
	EXTERNAL;
}
