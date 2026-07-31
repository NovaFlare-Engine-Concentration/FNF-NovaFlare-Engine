package mobile.states;

import haxe.io.Path;

import lime.utils.Assets as LimeAssets;

import openfl.utils.Assets as OpenflAssets;
import openfl.utils.ByteArray;
import openfl.system.System;

import flixel.addons.util.FlxAsyncLoop;

import states.titleState.TitleState;
import states.backend.initState.InitState;

class CopyState extends MusicBeatState
{
	public static var locatedFiles:Array<String> = [];
	public static var maxLoopTimes:Int = 0;
	public static var to:String = '';

	public var loadingImage:FlxSprite;
	public var bottomBG:FlxSprite;
	public var loadedText:FlxText;
	public var copyLoop:FlxAsyncLoop;

	public var isOption:Bool = false;

	var loopTimes:Int = 0;
	var failedFiles:Array<String> = [];
	var canUpdate:Bool = true;
	var shouldCopy:Bool = false;

	static final textFilesExtensions:Array<String> = ['txt', 'xml', 'lua', 'hx', 'json', 'frag', 'vert'];

	public function new(isOption:Bool = false)
	{
		this.isOption = isOption;
		super();
	}

	override function create()
	{
		locatedFiles = [];
		maxLoopTimes = 0;
		if (isOption)
		{
			checkExistingFilesNew(true);
		}
		else
		{
			checkExistingFiles();
		}

		if (maxLoopTimes > 0)
		{
			shouldCopy = true;
			SUtil.showPopUp("Seems like you have some missing files that are necessary to run the game\nPress OK to begin the copy process\nyou can close it at option\n",
				"Notice!");

			add(new FlxSprite(0, 0).makeGraphic(FlxG.width, FlxG.height, 0xffcaff4d));

			loadingImage = new FlxSprite(0, 0, Paths.image('funkay'));
			loadingImage.setGraphicSize(0, FlxG.height);
			loadingImage.updateHitbox();
			loadingImage.screenCenter();
			add(loadingImage);

			bottomBG = new FlxSprite(0, FlxG.height - 26).makeGraphic(FlxG.width, 26, 0xFF000000);
			bottomBG.alpha = 0.6;
			add(bottomBG);

			loadedText = new FlxText(bottomBG.x, bottomBG.y + 4, FlxG.width, '', 16);
			loadedText.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, CENTER);
			add(loadedText);

			// FlxAsyncLoop already spreads the work across updates. Creating it
			// and adding it from a worker thread races Flixel's state/display
			// lists and can crash hxcpp on Android.
			var ticks:Int = 15;
			if (maxLoopTimes <= 15)
				ticks = 1;
			copyLoop = new FlxAsyncLoop(maxLoopTimes, copyAsset, ticks);
			add(copyLoop);
			copyLoop.start();
		}
		else
		{
			InitState.ignoreCopy = true;
			FlxTransitionableState.skipNextTransIn = FlxTransitionableState.skipNextTransOut = true;
			MusicBeatState.switchState(new InitState());
		}

		super.create();
	}

	override function update(elapsed:Float)
	{
		if (shouldCopy && copyLoop != null)
		{
			if (copyLoop.finished && canUpdate)
			{
				if (failedFiles.length > 0)
				{
					SUtil.showPopUp(failedFiles.join('\n'), 'Failed To Copy ${failedFiles.length} File.');
					if (!FileSystem.exists('logs'))
						FileSystem.createDirectory('logs');
					File.saveContent('logs/' + Date.now().toString().replace(' ', '-').replace(':', "'") + '-CopyState' + '.txt', failedFiles.join('\n'));
				}
				if (!isOption && !checkExistingFiles())
				{
					trace('reloaded CopyState...');
					FlxG.resetState();
					return;
				}
				if (isOption)
				{
					if (!checkExistingFilesNew())
					{
						trace('reloaded CopyState...');
						FlxG.resetState();
						return;
					}
				}

				canUpdate = false;
				FlxG.sound.play(Paths.sound('confirmMenu'));
				var black = new FlxSprite(0, 0).makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
				black.alpha = 0;
				add(black);
				FlxTween.tween(black, {alpha: 1}, 0.9, {
					onComplete: function(twn:FlxTween)
					{
						System.gc();
						InitState.ignoreCopy = true;
						FlxTransitionableState.skipNextTransIn = FlxTransitionableState.skipNextTransOut = true;
						MusicBeatState.switchState(new InitState());
					},
					ease: FlxEase.linear,
					startDelay: 0.4
				});
			}
			if (maxLoopTimes == 0)
				loadedText.text = "Completed!";
			else
				loadedText.text = '$loopTimes/$maxLoopTimes';
		}
		super.update(elapsed);
	}

	public function copyAsset()
	{
		var file = locatedFiles[loopTimes];
		var toFile = Path.join([to, file]);
		var assetId = getFile(file);
		loopTimes++;
		if (!FileSystem.exists(toFile))
		{
			var directory = Path.directory(toFile);
			if (!FileSystem.exists(directory))
				SUtil.mkDirs(directory);
			try
			{
				if (OpenflAssets.exists(assetId))
				{
					if (textFilesExtensions.contains(Path.extension(file)))
						createContentFromInternal(file);
					else
					{
						var assetBytes:ByteArray = getFileBytes(assetId);
						if (assetBytes == null)
						{
							failedFiles.push('$assetId (Asset bytes are null)');
							return;
						}

						var outputBytes:haxe.io.Bytes = assetBytes;
						if (outputBytes == null)
						{
							failedFiles.push('$assetId (Could not convert asset bytes)');
							return;
						}
						File.saveBytes(toFile, outputBytes);
					}
				}
				else
				{
					failedFiles.push(assetId + " (File Doesn't Exist)");
				}
			}
			catch (err:Dynamic)
			{
				failedFiles.push('$assetId ($err)');
			}
		}
	}

	public static function getFileBytes(file:String):ByteArray
	{
		// Assets.getBytes() only accepts assets declared as BINARY. Images,
		// sounds and fonts have other manifest types even though their original
		// packaged files still need to be copied byte-for-byte. Read through the
		// owning Lime library without imposing an AssetType.
		var colonIndex = file.indexOf(':');
		var libraryName = colonIndex == -1 ? '' : file.substring(0, colonIndex);
		var symbolName = colonIndex == -1 ? file : file.substring(colonIndex + 1);
		var library = LimeAssets.getLibrary(libraryName);
		if (library != null)
		{
			var bytes:haxe.io.Bytes = library.getBytes(symbolName);
			if (bytes != null)
				return ByteArray.fromBytes(bytes);
		}

		// Keep a path fallback for custom libraries whose getBytes
		// implementation does not expose non-binary asset types.
		var path = OpenflAssets.getPath(file);
		return path == null ? null : ByteArray.fromFile(path);
	}

	public static function getFile(file:String):String
	{
		@:privateAccess
		for (library in LimeAssets.libraries.keys())
		{
			if (OpenflAssets.exists('$library:$file') && library != 'default')
				return '$library:$file';
		}
		return file;
	}

	public function createContentFromInternal(file:String = 'assets/file.txt')
	{
		var fileName = Path.withoutDirectory(file);
		var directory = Path.directory(Path.join([to, file]));
		try
		{
			var fileData:String = OpenflAssets.getText(getFile(file));
			if (fileData == null)
				fileData = '';
			if (!FileSystem.exists(directory))
				SUtil.mkDirs(directory);
			File.saveContent(Path.join([directory, fileName]), fileData);
		}
		catch (error:Dynamic)
		{
			failedFiles.push('${getFile(file)} ($error)');
		}
	}

	public static function checkExistingFiles():Bool
	{
		locatedFiles = OpenflAssets.list();
		// removes unwanted assets
		var assets = locatedFiles.filter(folder -> folder.startsWith('assets/') && !folder.contains('assets/shared/images/menuExtendHide/'));
		var mods = locatedFiles.filter(folder -> folder.startsWith('mods/'));
		locatedFiles = assets.concat(mods);

		var filesToRemove:Array<String> = [];
		for (file in locatedFiles)
		{
			var toFile = Path.join([to, file]);
			if (FileSystem.exists(toFile))
			{
				filesToRemove.push(file);
			}
		}

		for (file in filesToRemove)
			locatedFiles.remove(file);

		maxLoopTimes = locatedFiles.length;

		return (maxLoopTimes <= 0);
	}

	public static function checkExistingFilesNew(delete:Bool = false):Bool
	{
		// delete变量是规定了他是什么状态，是只检查文件有没有问题，还是把有问题的文件换掉。
		// 当delete为true的时候为检查+替换，为false的时候为检查。
		#if !ios
		locatedFiles = OpenflAssets.list();
		// removes unwanted assets
		var assets = locatedFiles.filter(folder -> folder.startsWith('assets/') && !folder.contains('assets/shared/images/menuExtendHide/'));
		var mods = locatedFiles.filter(folder -> folder.startsWith('mods/'));
		locatedFiles = assets.concat(mods);

		var filesToRemove:Array<String> = [];
		for (file in locatedFiles)
		{
			var toFile = Path.join([to, file]);

			if (FileSystem.exists(toFile))
			{
				var internalBytes:ByteArray = getFileBytes(getFile(file));
				var externalBytes:haxe.io.Bytes = File.getBytes(toFile);
				// If the installed asset library cannot expose bytes for an
				// existing external file, preserve that file instead of
				// dereferencing null or repeatedly re-entering CopyState.
				if (internalBytes == null || internalBytes.length == externalBytes.length)
				{
					filesToRemove.push(file);
				}
				else
				{
					if (delete)
					{
						FileSystem.deleteFile(toFile);
					}
				}
			}
		}

		for (file in filesToRemove)
			locatedFiles.remove(file);

		maxLoopTimes = locatedFiles.length;

		return (maxLoopTimes <= 0);
		#else
		locatedFiles = OpenflAssets.list();
		// removes unwanted assets
		var assets = locatedFiles.filter(folder -> folder.startsWith('assets/') && !folder.contains('unwantedFolder/'));
		var mods = locatedFiles.filter(folder -> folder.startsWith('mods/') && !folder.contains('unwantedFolder/'));
		locatedFiles = assets.concat(mods);

		var filesToRemove:Array<String> = [];
		for (file in locatedFiles)
		{
			var toFile = Path.join([to, file]);
			if (FileSystem.exists(toFile))
			{
				filesToRemove.push(file);
			}
		}

		for (file in filesToRemove)
			locatedFiles.remove(file);

		maxLoopTimes = locatedFiles.length;

		return (maxLoopTimes <= 0);
		#end
	}
}
