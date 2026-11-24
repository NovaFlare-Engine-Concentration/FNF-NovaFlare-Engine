package developer.editors;

import openfl.net.FileReference;

#if android
import haxe.io.Bytes;
import haxe.io.Path;
import mobile.ui.MobileFileDialog;
import mobile.ui.MobileFileDialog.MobileFileDialogMode;
import openfl.events.Event;
import openfl.events.IOErrorEvent;
import openfl.net.FileFilter;
import openfl.utils.ByteArray.ByteArrayData;
import sys.FileSystem;
import sys.io.File;
using StringTools;
#end

class EditorFileReference extends FileReference
{
	#if android
	var pendingSaveBytes:Bytes;

	override public function browse(?typeFilter:Array<FileFilter>):Bool
	{
		return browsePath(OPEN, null, null, typeFilter);
	}

	public function browsePath(mode:MobileFileDialogMode, ?defaultPath:String, ?title:String, ?typeFilter:Array<FileFilter>):Bool
	{
		__data = null;
		__path = null;
		MobileFileDialog.choose({
			title: title ?? (mode == DIRECTORY ? "Select folder" : "Open file"),
			mode: mode,
			defaultPath: defaultPath,
			extensions: extensionsFromFilters(typeFilter),
			onComplete: paths -> {
				if (paths.length == 0) openFileDialog_onCancel();
				else selectPath(paths[0]);
			}
		});
		return true;
	}

	function selectPath(path:String):Void
	{
		if (!FileSystem.exists(path))
		{
			notifyIOError('The selected path no longer exists: $path');
			return;
		}
		openFileDialog_onSelect(path);
	}

	override public function save(data:Dynamic, ?defaultFileName:String):Void
	{
		__data = null;
		__path = null;
		if (data == null) return;
		pendingSaveBytes = data is ByteArrayData ? cast data : Bytes.ofString(Std.string(data));

		var extension = defaultFileName == null ? "" : Path.extension(defaultFileName);
		MobileFileDialog.choose({
			title: "Save file",
			mode: SAVE,
			defaultPath: defaultFileName,
			extensions: extension == "" ? [] : [extension],
			onComplete: paths -> {
				if (paths.length > 0) saveFileDialog_onSelect(paths[0]);
				else
				{
					pendingSaveBytes = null;
					saveFileDialog_onCancel();
				}
			}
		});
	}

	override function saveFileDialog_onSelect(path:String):Void
	{
		var bytes = pendingSaveBytes;
		pendingSaveBytes = null;
		try File.saveBytes(path, bytes)
		catch (error:haxe.Exception)
		{
			notifyIOError('Could not save $path: ${error.message}');
			return;
		}
		__path = path;
		name = Path.withoutDirectory(path);
		dispatchEvent(new Event(Event.COMPLETE));
	}

	function notifyIOError(message:String):Void
	{
		dispatchEvent(new IOErrorEvent(IOErrorEvent.IO_ERROR, false, false, message));
	}

	static function extensionsFromFilters(filters:Null<Array<FileFilter>>):Array<String>
	{
		if (filters == null) return [];
		var extensions = [];
		for (filter in filters)
			for (pattern in filter.extension.replace(",", ";").split(";"))
			{
				var extension = pattern.trim().toLowerCase();
				if (extension.startsWith("*.")) extension = extension.substr(2);
				else if (extension.startsWith(".")) extension = extension.substr(1);
				if (extension != "") extensions.push(extension);
			}
		return extensions;
	}
	#end
}
