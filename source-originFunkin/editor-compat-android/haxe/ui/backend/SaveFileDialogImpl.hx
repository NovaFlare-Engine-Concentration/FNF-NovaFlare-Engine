package haxe.ui.backend;

import haxe.ui.containers.dialogs.Dialogs;
import mobile.ui.MobileFileDialog;
import sys.io.File;

class SaveFileDialogImpl extends SaveFileDialogBase {
	public override function show():Void {
		if (fileInfo == null || (fileInfo.text == null && fileInfo.bytes == null)) throw 'Nothing to write';
		MobileFileDialog.choose({
			title: options.title ?? 'Save File',
			mode: SAVE,
			defaultPath: fileInfo.name,
			extensions: [for (filter in (options.extensions ?? [])) if (filter.extension != null) filter.extension],
			onComplete: onSelected
		});
	}

	function onSelected(paths:Array<String>):Void {
		if (paths.length == 0) {
			dialogCancelled();
			return;
		}
		final path = paths[0];
		try {
			if (fileInfo.text != null) File.saveContent(path, fileInfo.text);
			else File.saveBytes(path, fileInfo.bytes);
		} catch (error:haxe.Exception) {
			Dialogs.messageBox(error.message, 'Cannot save file', 'error');
			dialogCancelled();
			return;
		}
		fullPath = path;
		dialogConfirmed();
	}
}
