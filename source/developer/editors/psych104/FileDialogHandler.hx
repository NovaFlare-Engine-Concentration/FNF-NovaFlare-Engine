// Port in progress from Psych Engine Mobile 1.0.4 Archive, commit 8e33eafecb7e3460a35cd73583fb02476dbf3c33 (Apache-2.0).
package developer.editors.psych104;

import developer.editors.EditorFileReference;
import openfl.events.Event;
import openfl.events.IOErrorEvent;
import openfl.net.FileFilter;

import haxe.Exception;
import sys.io.File;
import lime.ui.*;

import flixel.FlxBasic;

class FileDialogHandler extends FlxBasic
{
	var _fileRef:FileReferenceCustom;
	public function new()
	{
		_fileRef = new FileReferenceCustom();
		_fileRef.addEventListener(Event.CANCEL, onCancelFn);
		_fileRef.addEventListener(IOErrorEvent.IO_ERROR, onErrorFn);

		super();
	}

	// callbacks
	public var onComplete:Void->Void;
	public var onCancel:Void->Void;
	public var onError:Void->Void;

	var _currentEvent:openfl.events.Event->Void;
	var _currentEventType:String;

	public function save(?fileName:String = '', ?dataToSave:String = '', ?onComplete:Void->Void, ?onCancel:Void->Void, ?onError:Void->Void)
	{
		if(!completed)
		{
			throw new Exception('You must finish previous operation before starting a new one.');
		}

		_startUp(onComplete, onCancel, onError);

		listenFor(#if desktop Event.SELECT #else Event.COMPLETE #end, onSaveComplete);
		_fileRef.save(dataToSave, fileName);
	}

	public function open(?defaultName:String = null, ?title:String = null, ?filter:Array<FileFilter> = null, ?onComplete:Void->Void, ?onCancel:Void->Void, ?onError:Void->Void)
	{
		if(!completed)
		{
			throw new Exception('You must finish previous operation before starting a new one.');
		}

		_startUp(onComplete, onCancel, onError);
		if(filter == null) filter = [new FileFilter('JSON', 'json')];
		#if mac
		filter = [];
		#end

		listenFor(#if (desktop || android) Event.SELECT #else Event.COMPLETE #end, onLoadComplete);
		_fileRef.browseEx(OPEN, defaultName, title, filter);
	}

	public function openDirectory(?title:String = null, ?onComplete:Void->Void, ?onCancel:Void->Void, ?onError:Void->Void)
	{
		if(!completed)
		{
			throw new Exception('You must finish previous operation before starting a new one.');
		}

		_startUp(onComplete, onCancel, onError);

		listenFor(#if (desktop || android) Event.SELECT #else Event.COMPLETE #end, onLoadDirectoryComplete);
		_fileRef.browseEx(OPEN_DIRECTORY, null, title);
	}

	public var data:String;
	public var path:String;
	public var completed:Bool = true;
	function onSaveComplete(_)
	{
		@:privateAccess
		this.path = _fileRef._trackSavedPath;
		this.completed = true;
		trace('Saved file to: $path');

		removeEvents();
		this.completed = true;
		if(onComplete != null) onComplete();
	}

	function onLoadComplete(_)
	{
		final selectedPath = @:privateAccess _fileRef.__path;
		try this.data = File.getContent(selectedPath)
		catch (error:Exception)
		{
			trace('Could not load $selectedPath: ${error.message}');
			onErrorFn(null);
			return;
		}
		this.path = selectedPath;
		this.completed = true;
		trace('Loaded file from: $path');

		removeEvents();
		this.completed = true;
		if(onComplete != null)
			onComplete();
	}

	function onLoadDirectoryComplete(_)
	{
		@:privateAccess
		this.path = _fileRef.__path;
		this.completed = true;
		trace('Loaded directory: $path');

		removeEvents();
		this.completed = true;
		if(onComplete != null)
			onComplete();
	}

	function onCancelFn(_)
	{
		removeEvents();
		this.completed = true;
		if(onCancel != null) onCancel();
	}

	function onErrorFn(_)
	{
		removeEvents();
		this.completed = true;
		if(onError != null) onError();
	}

	function _startUp(onComplete:Void->Void, onCancel:Void->Void, onError:Void->Void)
	{
		this.onComplete = onComplete;
		this.onCancel = onCancel;
		this.onError = onError;
		this.completed = false;

		this.data = null;
		this.path = null;
	}

	function listenFor(type:String, callback:openfl.events.Event->Void):Void
	{
		removeEvents();
		_currentEventType = type;
		_currentEvent = callback;
		_fileRef.addEventListener(type, callback);
	}

	function removeEvents()
	{
		if(_currentEvent == null) return;
		_fileRef.removeEventListener(_currentEventType, _currentEvent);
		_currentEvent = null;
		_currentEventType = null;
	}

	override function destroy()
	{
		removeEvents();
		_fileRef.removeEventListener(Event.CANCEL, onCancelFn);
		_fileRef.removeEventListener(IOErrorEvent.IO_ERROR, onErrorFn);
		_fileRef = null;
		onComplete = null;
		onCancel = null;
		onError = null;
		data = null;
		path = null;
		completed = true;
		super.destroy();
	}
}

//Only way I could find to keep the path after saving a file
class FileReferenceCustom extends EditorFileReference
{
	@:allow(developer.editors.psych104.FileDialogHandler)
	var _trackSavedPath:String;
	override function saveFileDialog_onSelect(path:String):Void
	{
		_trackSavedPath = path;
		super.saveFileDialog_onSelect(path);
	}
	
	public function browseEx(browseType:FileDialogType = OPEN, ?defaultName:String, ?title:String = null, ?typeFilter:Array<FileFilter> = null):Bool
	{
		#if android
		return switch (browseType)
		{
			case OPEN: browsePath(OPEN, defaultName, title, typeFilter);
			case OPEN_DIRECTORY: browsePath(DIRECTORY, defaultName, title);
			default: false;
		};
		#else
		__data = null;
		__path = null;

		#if desktop
		var filter = null;

		if (typeFilter != null)
		{
			var filters = [];

			for (type in typeFilter)
			{
				filters.push(StringTools.replace(StringTools.replace(type.extension, "*.", ""), ";", ","));
			}

			filter = filters.join(";");
		}

		var openFileDialog = new FileDialog();
		openFileDialog.onCancel.add(openFileDialog_onCancel);
		openFileDialog.onSelect.add(openFileDialog_onSelect);
		openFileDialog.browse(browseType, filter, defaultName, title);
		return true;
		#elseif (js && html5)
		var filter = null;
		if (typeFilter != null)
		{
			var filters = [];
			for (type in typeFilter)
			{
				filters.push(StringTools.replace(StringTools.replace(type.extension, "*.", "."), ";", ","));
			}
			filter = filters.join(",");
		}
		if (filter != null)
		{
			__inputControl.setAttribute("accept", filter);
		}
		__inputControl.onchange = function()
		{
			var file = __inputControl.files[0];
			modificationDate = Date.fromTime(file.lastModified);
			creationDate = modificationDate;
			size = file.size;
			type = "." + Path.extension(file.name);
			name = Path.withoutDirectory(file.name);
			__path = file.name;
			dispatchEvent(new Event(Event.SELECT));
		}
		__inputControl.click();
		return true;
		#end

		return false;
		#end
	}
}
