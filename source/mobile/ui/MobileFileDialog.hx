package mobile.ui;

#if android
import flixel.FlxG;
import flixel.FlxState;
import flixel.FlxSubState;
import haxe.io.Path;
import haxe.ui.backend.flixel.StateHelper;
import haxe.ui.components.Button;
import haxe.ui.components.Label;
import haxe.ui.components.TextField;
import haxe.ui.containers.HBox;
import haxe.ui.containers.ListView;
import haxe.ui.containers.dialogs.Dialog;
import haxe.ui.containers.dialogs.Dialog.DialogButton;
import haxe.ui.core.Screen;
import haxe.ui.events.UIEvent;
import sys.FileSystem;

using StringTools;

enum abstract MobileFileDialogMode(String) {
	var OPEN;
	var OPEN_MULTIPLE;
	var DIRECTORY;
	var SAVE;
}

typedef MobileFileDialogRequest = {
	final title:String;
	final mode:MobileFileDialogMode;
	final defaultPath:Null<String>;
	final extensions:Array<String>;
	final onComplete:Array<String>->Void;
}

private typedef FileRow = {
	final text:String;
	final path:String;
	final directory:Bool;
}

class MobileFileDialog extends Dialog {
	static var currentDialog:Null<MobileFileDialogModal>;

	final request:MobileFileDialogRequest;
	final extensions:Array<String>;
	final fileList = new ListView();
	final location = new Label();
	final status = new Label();
	final filename = new TextField();
	final parentButton = new Button();
	final marked:Array<String> = [];
	var directory:String;
	var confirmed:Array<String> = [];
	var pendingOverwrite:Null<String>;

	public static function choose(request:MobileFileDialogRequest):Void {
		if (currentDialog != null) {
			haxe.Timer.delay(() -> request.onComplete([]), 0);
			return;
		}
		MobileHaxeUI.initialize();
		final owner = StateHelper.currentState;
		currentDialog = new MobileFileDialogModal(owner, request, (paths) -> {
			currentDialog = null;
			// Continue after Flixel has detached the substate and HaxeUI has removed the overlay.
			haxe.Timer.delay(() -> request.onComplete(paths), 0);
		});
		currentDialog.open();
	}

	private function new(request:MobileFileDialogRequest, onSelected:Array<String>->Void, onDestroyed:Void->Void) {
		super();
		this.request = request;
		extensions = normalizeExtensions(request.extensions);
		title = request.title;
		buttons = DialogButton.CANCEL;
		width = Math.min(680, Screen.instance.width * 0.94);
		addInputs();

		final home = FileSystem.absolutePath(Sys.getCwd());
		final suggested = request.defaultPath;
		if (suggested == null || suggested.length == 0) {
			showDirectory(home);
		} else {
			final absolute = Path.normalize(Path.isAbsolute(suggested) ? suggested : Path.join([home, suggested]));
			if (FileSystem.isDirectory(absolute)) {
				if (!showDirectory(absolute)) showDirectory(home);
			} else {
				if (!showDirectory(Path.directory(absolute))) showDirectory(home);
				if (request.mode == SAVE) filename.text = Path.withoutDirectory(absolute);
			}
		}

		onDialogClosed = event -> onSelected(event.button == DialogButton.OK ? confirmed : []);
		registerEvent(UIEvent.DESTROY, _ -> onDestroyed());
	}

	function addInputs():Void {
		location.percentWidth = status.percentWidth = fileList.percentWidth = 100;
		location.wordWrap = status.wordWrap = true;
		location.text = '';
		status.text = '';
		fileList.height = Math.min(400, Screen.instance.height * 0.50);
		fileList.itemHeight = 40;
		fileList.onChange = _ -> {
			final item:Null<FileRow> = fileList.selectedItem;
			if (request.mode == SAVE && item != null && !item.directory) filename.text = Path.withoutDirectory(item.path);
		};
		addComponent(location);
		addComponent(fileList);

		if (request.mode == SAVE) {
			filename.percentWidth = 100;
			filename.placeholder = 'File name';
			filename.height = 40;
			filename.onChange = _ -> pendingOverwrite = null;
			addComponent(filename);
		}

		final actions = new HBox();
		parentButton.text = 'Parent';
		parentButton.height = 40;
		parentButton.onClick = _ -> showDirectory(Path.directory(directory));
		actions.addComponent(parentButton);
		if (request.mode == DIRECTORY || request.mode == SAVE) addAction(actions, 'Open Folder', openSelectedFolder);
		if (request.mode == OPEN_MULTIPLE) addAction(actions, 'Add / Remove', toggleSelectedFile);
		final action = switch (request.mode) {
			case SAVE: 'Save';
			case DIRECTORY: 'Select';
			case OPEN, OPEN_MULTIPLE: 'Open';
		};
		addAction(actions, action, confirm);
		addComponent(actions);
		addComponent(status);
	}

	function addAction(actions:HBox, label:String, callback:Void->Void):Void {
		final button = new Button();
		button.text = label;
		button.height = 40;
		button.onClick = _ -> callback();
		actions.addComponent(button);
	}

	function showDirectory(path:String):Bool {
		// Path.directory("/sdcard") is empty. Preserve the filesystem root.
		if (path.length == 0) path = '/';
		var names:Array<String>;
		try {
			names = FileSystem.readDirectory(path);
		} catch (_:haxe.Exception) {
			status.text = 'Cannot open folder.';
			return false;
		}
		names.sort((left, right) -> Reflect.compare(left.toLowerCase(), right.toLowerCase()));
		final folders:Array<FileRow> = [];
		final files:Array<FileRow> = [];
		for (name in names) {
			final fullPath = Path.join([path, name]);
			if (FileSystem.isDirectory(fullPath)) {
				folders.push({text: name + '/', path: fullPath, directory: true});
			} else if (request.mode != DIRECTORY && (extensions.length == 0 || extensions.contains(Path.extension(name).toLowerCase()))) {
				files.push({text: (marked.contains(fullPath) ? '[+] ' : '') + name, path: fullPath, directory: false});
			}
		}
		directory = path;
		pendingOverwrite = null;
		location.text = path;
		status.text = marked.length == 0 ? '' : '${marked.length} selected';
		parentButton.disabled = path == '/';
		fileList.selectedIndex = -1;
		fileList.dataSource.clear();
		for (entry in folders) fileList.dataSource.add(entry);
		for (entry in files) fileList.dataSource.add(entry);
		return true;
	}

	function openSelectedFolder():Void {
		final item:Null<FileRow> = fileList.selectedItem;
		if (item != null && item.directory) showDirectory(item.path);
	}

	function toggleSelectedFile():Void {
		final item:Null<FileRow> = fileList.selectedItem;
		if (item == null || item.directory) return;
		if (!marked.remove(item.path)) marked.push(item.path);
		showDirectory(directory);
	}

	function confirm():Void {
		if (directory == null) return;
		final item:Null<FileRow> = fileList.selectedItem;
		switch (request.mode) {
			case SAVE:
				confirmSave();
			case DIRECTORY:
				accept([item != null ? item.path : directory]);
			case OPEN, OPEN_MULTIPLE:
				if (item != null && item.directory) showDirectory(item.path);
				else if (marked.length > 0) accept(marked);
				else if (item != null) accept([item.path]);
		}
	}

	function confirmSave():Void {
		var name = filename.text.trim();
		if (name.length == 0 || name == '.' || name == '..' || name.contains('/') || name.contains('\\')) {
			status.text = 'Enter a valid file name.';
			return;
		}
		if (Path.extension(name).length == 0 && extensions.length > 0) name += '.' + extensions[0];
		final path = Path.join([directory, name]);
		if (FileSystem.isDirectory(path)) {
			status.text = 'A folder has this name.';
			return;
		}
		if (FileSystem.exists(path) && pendingOverwrite != path) {
			pendingOverwrite = path;
			status.text = 'File exists. Tap Save again to overwrite.';
			return;
		}
		accept([path]);
	}

	function accept(paths:Array<String>):Void {
		confirmed = paths;
		hideDialog(DialogButton.OK);
	}

	static function normalizeExtensions(patterns:Array<String>):Array<String> {
		final result:Array<String> = [];
		for (pattern in patterns) {
			for (token in ~/[;,\s]+/g.split(pattern)) {
				if (token == '*' || token == '*.*') return [];
				final extension = ~/^[*.]+/.replace(token.toLowerCase(), '');
				if (extension.length > 0 && !result.contains(extension)) result.push(extension);
			}
		}
		return result;
	}
}

private class MobileFileDialogModal extends FlxSubState {
	final owner:FlxState;
	final request:MobileFileDialogRequest;
	final onComplete:Array<String>->Void;
	final suspendedStates:Array<FlxState> = [];
	var dialog:Null<MobileFileDialog>;
	var previousDraw:Bool;
	var mounted = false;
	var closing = false;
	var finished = false;
	var selection:Array<String> = [];

	public function new(owner:FlxState, request:MobileFileDialogRequest, onComplete:Array<String>->Void) {
		super();
		this.owner = owner;
		this.request = request;
		this.onComplete = onComplete;
		closeCallback = finish;
	}

	public function open():Void {
		FlxG.signals.preStateSwitch.add(abort);
		owner.openSubState(this);
	}

	override public function create():Void {
		super.create();
		mounted = true;
		previousDraw = owner.persistentDraw;
		owner.persistentDraw = true;
		var state = FlxG.state;
		while (state != this && state != null) {
			if (state.persistentUpdate) {
				suspendedStates.push(state);
				state.persistentUpdate = false;
			}
			state = state.subState;
		}
		dialog = @:privateAccess new MobileFileDialog(request, closeWith, onDialogDestroyed);
		dialog.showDialog(true);
	}

	override public function update(elapsed:Float):Void {
		if (FlxG.android.justPressed.BACK && !closing && dialog != null) {
			dialog.hideDialog(DialogButton.CANCEL);
			return;
		}
		super.update(elapsed);
	}

	function closeWith(paths:Array<String>):Void {
		if (closing) return;
		closing = true;
		selection = paths;
		close();
	}

	function onDialogDestroyed():Void {
		dialog = null;
		closeWith([]);
	}

	function finish():Void {
		if (finished) return;
		finished = true;
		FlxG.signals.preStateSwitch.remove(abort);
		if (!closing && dialog != null) {
			closing = true;
			dialog.hideDialog(DialogButton.CANCEL);
		}
		if (mounted) {
			owner.persistentDraw = previousDraw;
			for (state in suspendedStates) state.persistentUpdate = true;
		}
		onComplete(selection);
	}

	function abort():Void {
		if (finished) return;
		selection = [];
		finish();
	}

	override public function destroy():Void {
		abort();
		super.destroy();
	}
}
#end
