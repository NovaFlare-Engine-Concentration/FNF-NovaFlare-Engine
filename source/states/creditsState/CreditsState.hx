package states.creditsState;

import general.objects.AttachedSprite;
import general.objects.state.CreditsShape;

import substates.CreditsSubState;
import substates.PsychCreditsSubState;

import states.mainMenuState.MainMenuState;

class CreditsState extends MusicBeatState
{
	private var grpOptions:FlxTypedGroup<Alphabet>;
	private var iconArray:Array<AttachedSprite> = [];

	private var nameSave:Array<String> = [
		"NovaFlare Engine",
		"Psych Engine",
		#if mobile
		"mobile Team",
		#end
		"Funkin Team"
	];

	private var NucreditsStuff:Array<Array<Array<String>>> = [
		[
			['NovaFlare Engine Team'],
			[
				'Beihu',
				'beihu',
				'Main Programmer',
				'Head of NovaFlare Engine\n\n\nNothing special',
				'FFC0CB',
				'https://b23.tv/QfPKw2o',
				'https://youtube.com/@beihu235?si=BI2efmEcI8_mZoUp',
				'https://github.com/beihu235'
			],
			[
				'MaoPou',
				'maopou',
				'Programmer',
				"Code help\n\n\nA crumb who likes to write code, but doesn't like to look at code :)",
				'FFFFFF',
				'https://space.bilibili.com/1548393523?spm_id_from=333.1007.0.0',
				'https://github.com/MaoPou'
			],
			[
				'VapireMox',
				'vapiremox',
				'Programmer',
				"hscript-iris-improved Developer\n\n\nYou're right about everything, and you've done everything correctly. I will obey you.",
				'090C1A',
				'https://github.com/VapireMox',
				'https://b23.tv/LD5ekXY'
			],
			[
				'Kangel',
				'kangel',
				'Programmer',
				'Code help\n\n\nThis is a message.',
				'ffffff',
				'https://github.com/kangeluwu',
				'https://www.youtube.com/@kannoYuki0524'
			],
			[
				'Chiny',
				'chiny',
				'Programmer',
				'Credit state logic creator\n\n\nBanGDream Touhou Player',
				'800080',
				'https://space.bilibili.com/3493288327777064',
				'https://github.com/dmmchh'
			],
			[
				'TieGuo',
				'tieguo',
				'Ex-Programmer',
				'Pause Menu creator\n\n\nI like coding shit',
				'FF6600',
				'https://b23.tv/7OVWzAO'
			],
			[
				'Careful_Scarf_487',
				'Careful_Scarf_487',
				'Main Artist',
				"Main Artist of engine\n\n\nI'm probably the least present in the whole production crew.",
				'990000',
				'https://b23.tv/DQ1a0jO'
			],
			[
				'MengQi',
				'mengqi',
				'Artist',
				'Puase menu artist\n\n\n"this is description',
				'9b5a67',
				'https://space.bilibili.com/2130239542'
			],
			[
				'AZjessica',
				'AZjessica',
				'Artist',
				"Freeplay state artist\n\n\nI love animation. I'm an idiot",
				'DE444B',
				'https://b23.tv/GyqgrAO',
				"https://x.com/Jessica33049821?t=rOb0ZqOMQewaJAFlO4FR6g&s=09",
				'https://youtube.com/@azjessica?si=aRKuPdMHR1LLBxH1'
			],
			[
				'Ben Eyre',
				'beneyre',
				'Artist',
				"FreePlay/Credit state artist\n\n\nI can't believe I actually have the honor of being added to the production team.",
				'FFCDA4',
				'https://b23.tv/cB2uujD',
				'https://x.com/hngstngxng83905?t=GDKWYMRZsCMUMXYs0cmYrw&s=09'
			],
			[
				'als',
				'als',
				'Animation',
				'Open screen animation support',
				'ff0000',
				'https://b23.tv/mNNX8R8'
			],
			[
				'blockDDDdark',
				'ddd',
				'Musican',
				"Engine sound effort support\n\nComposer,Painter,Meme subculture lover\nI'm not very professional about creating things, I basically treat them as hobbies",
				'5123A0',
				'https://space.bilibili.com/401733211'
			]
		],
		[
			['Psych Engine Team'],
			[
				'Shadow Mario',
				'shadowmario',
				'Main Programmer and Head of Psych Engine',
				'https://ko-fi.com/shadowmario',
				'444444'
			],
			[
				'Riveren',
				'riveren',
				'Main Artist/Animator of Psych Engine',
				'https://twitter.com/riverennn',
				'14967B'
			],
			[
				'bb-panzu',
				'bb',
				'Ex-Programmer of Psych Engine',
				'https://twitter.com/bbsub3',
				'3E813A'
			],
			[
				'shubs',
				'',
				"Ex-Programmer of Psych Engine\nI don\'t support them.",
				'',
				'A1A1A1'
			],
			[
				'CrowPlexus',
				'crowplexus',
				'Input System v3, Major Help and Other PRs',
				'https://twitter.com/crowplexus',
				'A1A1A1'
			],
			[
				'Keoiki',
				'keoiki',
				'Note Splash Animations and Latin Alphabet',
				'https://twitter.com/Keoiki_',
				'D2D2D2'
			],
			[
				'SqirraRNG',
				'sqirra',
				"Crash Handler and Base code for\nChart Editor\'s Waveform",
				'https://twitter.com/gedehari',
				'E1843A'
			],
			[
				'EliteMasterEric',
				'mastereric',
				'Runtime Shaders support',
				'https://twitter.com/EliteMasterEric',
				'FFBD40'
			],
			[
				'PolybiusProxy',
				'proxy',
				'.MP4 Video Loader Library (hxCodec)',
				'https://twitter.com/polybiusproxy',
				'DCD294'
			],
			[
				'Tahir',
				'tahir',
				'Implementing & Maintaining SScript and Other PRs',
				'https://twitter.com/tahirk618',
				'A04397'
			],
			[
				'iFlicky',
				'flicky',
				'Composer of Psync and Tea Time\nMade the Dialogue Sounds',
				'https://twitter.com/flicky_i',
				'9E29CF'
			],
			[
				'KadeDev',
				'kade',
				'Fixed some issues on Chart Editor and Other PRs',
				'https://twitter.com/kade0912',
				'64A250'
			],
			[
				'superpowers04',
				'superpowers04',
				'LUA JIT Fork',
				'https://twitter.com/superpowers04',
				'B957ED'
			],
			[
				'CheemsAndFriends',
				'face',
				'Creator of FlxAnimate\n(Icon will be added later, merry christmas!)',
				'https://twitter.com/CheemsnFriendos',
				'A1A1A1'
			],
		],
		#if mobile
		[
			['Mobile Porting Team'],
			[
				'mcagabe19',
				'lily',
				'Head Porter of Psych Engine Mobile',
				'https://www.youtube.com/@mcagabe19',
				'FFE7C0'
			],
			[
				'Karim Akra',
				'karim',
				'Assistant Porter/Helper #1 of Psych Engine Mobile',
				'https://youtube.com/@Karim0690',
				'FFB4F0'
			],
			[
				'Moxie',
				'moxie',
				'Helper #2 of Psych Engine Mobile',
				'https://x.com/moxie_specalist',
				'37a8af'
			],
			[
				'MAJigsaw77',
				'jigsaw',
				'Author of Mobile Controls, New FlxRuntimeShader and Storage Stuff',
				'https://github.com/MAJigsaw77',
				'898989'
			],
			[
				'FutureDorito',
				'dorito',
				'iOS Helper/Implement',
				'https://www.youtube.com/@Futuredorito',
				'E69138'
			]
		],
		#end
		[
			["Funkin' Crew"],
			[
				'ninjamuffin99',
				'ninjamuffin99',
				"Programmer of Friday Night Funkin'",
				'https://twitter.com/ninja_muffin99',
				'CF2D2D'
			],
			[
				'PhantomArcade',
				'phantomarcade',
				"Animator of Friday Night Funkin'",
				'https://twitter.com/PhantomArcade3K',
				'FADC45'
			],
			[
				'evilsk8r',
				'evilsk8r',
				"Artist of Friday Night Funkin'",
				'https://twitter.com/evilsk8r',
				'5ABD4B'
			],
			[
				'kawaisprite',
				'kawaisprite',
				"Composer of Friday Night Funkin'",
				'https://twitter.com/kawaisprite',
				'378FC7'
			]
		]
	];

	private var UncreditsStuff:Array<String> = [
		"Nova Flare Engine Team",
		"Psych Engine Team",
		#if mobile
		"mobile port team",
		#end
		"Funkin Team"
	];
	private var creditsStuff:Array<Array<String>> = [];

	var bg:FlxSprite;
	var descText:FlxText;
	var intendedColor:FlxColor;
	var colorTween:FlxTween;
	var descBox:AttachedSprite;

	var modList:ModsButtonRect;
	var ModListArray:Array<ModsButtonRect> = [];

	var camSong:FlxCamera;

	var psych:Bool = true;
	var noscreen:Bool = false;

	private static var position:Float = 100 - 45;
	private static var lerpPosition:Float = 100 - 45;

	override function create()
	{
		#if DISCORD_ALLOWED
		// Updating Discord Rich Presence
		DiscordClient.changePresence("In the Menus", null);
		#end

		Mods.loadTopMod();

		persistentUpdate = true;
		bg = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.antialiasing = ClientPrefs.data.antialiasing;
		add(bg);
		bg.screenCenter();

		var back = new GeneralBack(0, 0, 250, 75, Language.get('back', 'main'), 0x53b7ff, backMenu);
		back.y = FlxG.height - 75;
		add(back);

		#if MODS_ALLOWED
		for (mod in Mods.parseList().enabled)
		{
			UncreditsStuff.push(mod);
		}
		#end

		for (i in 0...UncreditsStuff.length)
		{
			if (i <= #if mobile 3 #else 2 #end)
				modList = new ModsButtonRect(0, i * 120 + 20, 600, 90, 25, 25, nameSave[i], true, 0, FlxColor.BLACK);
			else
				modList = new ModsButtonRect(0, i * 120 + 20, 600, 90, 25, 25, UncreditsStuff[i], 0, FlxColor.BLACK);
			modList.screenCenter(X);
			add(modList);
			ModListArray.push(modList);
		}

		super.create();

		songsRectPosUpdate(true);
	}

	var quitting:Bool = false;
	var holdTime:Float = 0;

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (FlxG.sound.music.volume < 0.7)
		{
			FlxG.sound.music.volume += 0.5 * FlxG.elapsed;
		}

		if (controls.BACK && !pressCheck)
		{
			FlxG.sound.play(Paths.sound('cancelMenu'));
			backMenu();
		}

		mouseMove();
		//position += FlxG.mouse.wheel * 70;
		if (FlxG.mouse.pressed)
		{
			position += moveData;
			lerpPosition = position;
			songsRectPosUpdate(true);
		}

		for (i in 0...ModListArray.length)
		{
			if (FlxG.mouse.overlaps(ModListArray[i]))
			{
				if (FlxG.mouse.justReleased)
				{
					creditsStuff = [];

					if (i <= #if mobile 3 #else 2 #end)
					{
						noscreen = false;
						for (eg in NucreditsStuff[i])
						{
							if (eg[5] != null)
							{
								psych = false;
								if (eg[1] != null)
								{
									creditsStuff.push(eg);
								}
							}
							else
							{
								psych = true;
								creditsStuff.push(eg);
							}
						}
					}
					else
					{
						pushModCreditsToList(UncreditsStuff[i]);
					}

					if (!noscreen)
					{
						if (!psych)
						{
							if (creditsStuff != null)
							{
								CreditsSubState.creditsStuff = creditsStuff;
								persistentUpdate = false;
								Mods.currentModDirectory = UncreditsStuff[i];
								openSubState(new CreditsSubState());
								trace("false");
							}
						}
						else if (psych)
						{
							if (creditsStuff != null)
							{
								PsychCreditsSubState.creditsStuff = creditsStuff;
								persistentUpdate = false;
								Mods.currentModDirectory = UncreditsStuff[i];
								openSubState(new PsychCreditsSubState());
								trace("true");
							}
						}
					}
					else if (noscreen)
					{
						FlxG.sound.play(Paths.sound('cancelMenu'));
					}
				}
			}
		}

		if (position > 20)
			position = FlxMath.lerp(20, position, Math.exp(-elapsed * 15));
		if (position < FlxG.height + 20 - 120 * UncreditsStuff.length)
			position = FlxMath.lerp(FlxG.height + 20 - 120 * UncreditsStuff.length, position, Math.exp(-elapsed * 15));

		if (Math.abs(lerpPosition - position) < 1)
			lerpPosition = position;
		else
			lerpPosition = FlxMath.lerp(position, lerpPosition, Math.exp(-elapsed * 15));

		songsRectPosUpdate(false);
	}

	var saveMouseY:Int = 0;
	var moveData:Int = 0;
	var avgSpeed:Float = 0;

	function mouseMove()
	{
		if (FlxG.mouse.justPressed)
		{
			saveMouseY = FlxG.mouse.y;
			avgSpeed = 0;
		}
		moveData = FlxG.mouse.y - saveMouseY;
		saveMouseY = FlxG.mouse.y;
		avgSpeed = avgSpeed * 0.8 + moveData * 0.2;
	}

	function songsRectPosUpdate(forceUpdate:Bool = false)
	{
		if (!forceUpdate && lerpPosition == position)
			return; // 优化
		for (i in 0...ModListArray.length)
		{
			ModListArray[i].y = lerpPosition + i * 120;
		}
	}

	var pressCheck:Bool = false;

	function backMenu()
	{
		if (!pressCheck)
		{
			pressCheck = true;
			MusicBeatState.switchState(new MainMenuState());
		}
	}

	#if MODS_ALLOWED
	function pushModCreditsToList(folder:String)
	{
		var creditsFile:String = null;
		if (folder != null && folder.trim().length > 0)
			creditsFile = Paths.mods(folder + '/data/credits.txt');
		else
			creditsFile = Paths.mods('data/credits.txt');

		if (FileSystem.exists(creditsFile))
		{
			var firstarray:Array<String> = File.getContent(creditsFile).split('\n');
			for (i in firstarray)
			{
				var arr:Array<String> = i.replace('\\n', '\n').split(";;");
				if (arr.length != 1)
				{
					if (arr.length >= 5)
						arr.push(folder);
					creditsStuff.push(arr);
					psych = false;
				}
				else
				{
					var arrr:Array<String> = i.replace('\\n', '\n').split("::");
					if (arrr.length >= 5)
						arrr.push(folder);
					creditsStuff.push(arrr);
					psych = true;
				}
			}
			creditsStuff.push(['']);
			noscreen = false;
		}
		else
		{
			noscreen = true;
		}
	}
	#end

	private function unselectableCheck(num:Int):Bool
	{
		return creditsStuff[num].length <= 1;
	}
}
