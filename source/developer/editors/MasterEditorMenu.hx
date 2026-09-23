package developer.editors;

import states.mainMenuState.MainMenuState;
import states.freeplayState.FreeplayState;

import general.backend.language.Language;
import games.backend.WeekData;
import games.objects.Character;

class MasterEditorMenu extends MusicBeatState
{
	var options:Array<String> = [
		'chartEditor',
		'characterEditor',
		'stageEditor',
		'weekEditor',
		'menuCharEditor',
		'dialogueEditor',
		'dialoguePortraitEditor',
		'noteSplashDebug'
	];
	private var grpTexts:FlxTypedGroup<Alphabet>;
	private var directories:Array<String> = [null];

	private var curSelected = 0;
	private var curDirectory = 0;
	private var directoryTxt:FlxText;

	override function create()
	{
		FlxG.camera.bgColor = FlxColor.BLACK;
		#if DISCORD_ALLOWED
		// Updating Discord Rich Presence
		DiscordClient.changePresence("Editors Main Menu", null);
		#end

		var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.scrollFactor.set();
		bg.color = 0xFF353535;
		add(bg);

		grpTexts = new FlxTypedGroup<Alphabet>();
		add(grpTexts);

		for (i in 0...options.length)
		{
			var leText:Alphabet = new Alphabet(90, 320, Language.get(options[i], 'editors'), true);
			leText.isMenuItem = true;
			leText.targetY = i;
			grpTexts.add(leText);
			leText.snapToPosition();
		}

		#if MODS_ALLOWED
		var textBG:FlxSprite = new FlxSprite(0, FlxG.height - 42).makeGraphic(FlxG.width, 42, 0xFF000000);
		textBG.alpha = 0.6;
		add(textBG);

		directoryTxt = new FlxText(textBG.x, textBG.y + 4, FlxG.width, '', 32);
		// ★ vcr.ttf 是拉丁字体，没有中文 glyph，mod 目录名/提示带中文会直接不显示；改用语言适配字体
		directoryTxt.setFormat(Paths.font(Language.get('fontName', 'main') + '.ttf'), 32, FlxColor.WHITE, CENTER);
		directoryTxt.scrollFactor.set();
		add(directoryTxt);

		for (folder in Mods.getModDirectories())
		{
			directories.push(folder);
		}

		var found:Int = directories.indexOf(Mods.currentModDirectory);
		if (found > -1)
			curDirectory = found;
		changeDirectory();
		#end
		changeSelection();

		FlxG.mouse.visible = false;

		#if MODS_ALLOWED
		addVirtualPad(LEFT_FULL, A_B);
		#else
		addVirtualPad(UP_DOWN, A_B);
		#end

		super.create();
	}

	override function update(elapsed:Float)
	{
		if (controls.UI_UP_P)
		{
			changeSelection(-1);
		}
		if (controls.UI_DOWN_P)
		{
			changeSelection(1);
		}
		#if MODS_ALLOWED
		if (controls.UI_LEFT_P)
		{
			changeDirectory(-1);
		}
		if (controls.UI_RIGHT_P)
		{
			changeDirectory(1);
		}
		#end

		if (controls.BACK)
		{
			MusicBeatState.switchState(new MainMenuState());
		}

		if (controls.ACCEPT)
		{
			switch (options[curSelected])
			{
				case 'chartEditor': // felt it would be cool maybe
					MusicBeatState.switchState(new ChartingState());
				case 'characterEditor':
					MusicBeatState.switchState(new CharacterEditorState(Character.DEFAULT_CHARACTER));
				case 'stageEditor':
					MusicBeatState.switchState(new StageEditorState());
				case 'weekEditor':
					MusicBeatState.switchState(new WeekEditorState());
				case 'menuCharEditor':
					MusicBeatState.switchState(new MenuCharacterEditorState());
				case 'dialogueEditor':
					MusicBeatState.switchState(new DialogueEditorState());
				case 'dialoguePortraitEditor':
					MusicBeatState.switchState(new DialogueCharacterEditorState());
				case 'noteSplashDebug':
					MusicBeatState.switchState(new NoteSplashEditorState());
			}
			FlxG.sound.music.volume = 0;
			FreeplayState.destroyFreeplayVocals();
		}

		var bullShit:Int = 0;
		for (item in grpTexts.members)
		{
			item.targetY = bullShit - curSelected;
			bullShit++;

			item.alpha = 0.6;
			// item.setGraphicSize(Std.int(item.width * 0.8));

			if (item.targetY == 0)
			{
				item.alpha = 1;
				// item.setGraphicSize(Std.int(item.width));
			}
		}
		super.update(elapsed);
	}

	function changeSelection(change:Int = 0)
	{
		FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);

		curSelected += change;

		if (curSelected < 0)
			curSelected = options.length - 1;
		if (curSelected >= options.length)
			curSelected = 0;
	}

	#if MODS_ALLOWED
	function changeDirectory(change:Int = 0)
	{
		FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);

		curDirectory += change;

		if (curDirectory < 0)
			curDirectory = directories.length - 1;
		if (curDirectory >= directories.length)
			curDirectory = 0;

		WeekData.setDirectoryFromWeek();
		if (directories[curDirectory] == null || directories[curDirectory].length < 1)
			directoryTxt.text = Language.get('noModDirectory', 'editors');
		else
		{
			Mods.currentModDirectory = directories[curDirectory];
			directoryTxt.text = Language.get('loadedModDirectory', 'editors') + ' ' + Mods.currentModDirectory + ' >';
		}
		directoryTxt.text = directoryTxt.text.toUpperCase();
	}
	#end
}

