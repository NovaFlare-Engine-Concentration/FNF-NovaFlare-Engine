package haxe.ui.backend;

import haxe.io.Path;
import haxe.ui.containers.dialogs.Dialogs;
import haxe.ui.containers.dialogs.Dialogs.SelectedFileInfo;
import mobile.ui.MobileFileDialog;
import sys.io.File;

class OpenFileDialogImpl extends OpenFileDialogBase {
	public override function show():Void {
		MobileFileDialog.choose({
			title: options.title ?? 'Open File',
			mode: options.multiple == true ? OPEN_MULTIPLE : OPEN,
			defaultPath: null,
			extensions: [for (filter in (options.extensions ?? [])) if (filter.extension != null) filter.extension],
			onComplete: onSelected
		});
	}

	function onSelected(paths:Array<String>):Void {
		if (paths.length == 0) {
			dialogCancelled();
			return;
		}
		final files:Array<SelectedFileInfo> = [];
		try {
			for (path in paths) {
				final info:SelectedFileInfo = {name: Path.withoutDirectory(path), fullPath: path, isBinary: false};
				if (options.readContents == true) {
					info.isBinary = options.readAsBinary == true;
					if (info.isBinary) info.bytes = File.getBytes(path);
					else info.text = File.getContent(path);
				}
				files.push(info);
			}
		} catch (error:haxe.Exception) {
			Dialogs.messageBox(error.message, 'Cannot open file', 'error');
			dialogCancelled();
			return;
		}
		dialogConfirmed(files);
	}
}
