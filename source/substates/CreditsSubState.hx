package substates;

import general.objects.AttachedSprite;
import general.objects.state.CreditsShape;

#if hxvlc
import hxvlc.flixel.FlxVideoSprite;
#end

class CreditsSubState extends MusicBeatSubstate
{
	public static var creditsStuff:Array<Array<String>> = [];

	var curSelected:Int = -1;

	private var grpOptions:FlxTypedGroup<Alphabet>;
	var iconArray:Array<AttachedSprite> = [];
	var iconTextArray:Array<FlxText> = [];
	var iconBGArray:Array<Rect> = [];
	var linkSpriteArray:Array<CreditsNote> = [];
	var iconNameArray:Array<String> = [];

	var bg:FlxSprite;
	var nameText:FlxText;
	var jobText:FlxText;
	var descBox:Rect;
	var bigIcon:FlxSprite;
	var descText:FlxText;
	var intendedColor:FlxColor;
	var colorTween:FlxTween;

	var nameRect:Rect;
	var jobRect:Rect;
	var bigIconRect:Rect;
	var descRect:Rect;

	var backShape:GeneralBack;

	var offsetThing:Float = -75;

	var camIcons:FlxCamera;
	var camHUD:FlxCamera;

	var iconVideo:FlxVideoSprite;

	var font = Paths.font('montserrat.ttf');

	private static var position:Float = 100 - 45;
	private static var lerpPosition:Float = 100 - 45;

	public function new()
	{
		super();
	}

	override function create()
	{
		FlxG.mouse.visible = !ClientPrefs.data.needMobileControl;
		persistentUpdate = true;
		bg = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.antialiasing = ClientPrefs.data.antialiasing;
		add(bg);
		bg.screenCenter();

		grpOptions = new FlxTypedGroup<Alphabet>();
		add(grpOptions);

		var bgwidth = 230;

		camIcons = new FlxCamera(0, 0, bgwidth, FlxG.height - 150);
		camIcons.bgColor = 0x00;

		camHUD = new FlxCamera();
		camHUD.bgColor = 0x00;

		FlxG.cameras.add(camIcons, false);
		FlxG.cameras.add(camHUD, false);

		for (i in 0...creditsStuff.length)
		{
			var isSelectable:Bool = !unselectableCheck(i);

			if (isSelectable)
			{
				var str:String = 'credits/missing_icon';
				if (creditsStuff[i][1] != null && creditsStuff[i][1].length > 0)
				{
					var fileName = 'credits/' + creditsStuff[i][1];
					if (Paths.fileExists('images/$fileName.png', IMAGE))
						str = fileName;
					else if (Paths.fileExists('images/$fileName-pixel.png', IMAGE))
						str = fileName + '-pixel';
				}
				iconNameArray.push(str);

				var icon:AttachedSprite = new AttachedSprite(str);
				icon.scale.set(0.3, 0.3);
				icon.updateHitbox();
				iconArray.push(icon);

				var iconBG:Rect = new Rect(0, 0, bgwidth, 120, 0, 0, FlxColor.GRAY, 0.7);
				iconBGArray.push(iconBG);

				var iconText:FlxText = new FlxText(0, 0, 0, creditsStuff[i][0], 22);
				iconText.antialiasing = ClientPrefs.data.antialiasing;
				iconText.setFormat(font, 22, FlxColor.BLACK, LEFT);

				if (iconText.width > 140)
					iconText.scale.x = 140 / iconText.width;
				iconText.x -= iconText.width * (1 - iconText.scale.x) / 2;
				iconText.updateHitbox();
				iconTextArray.push(iconText);

				add(iconBG);
				add(icon);
				add(iconText);

				icon.cameras = [camIcons];
				iconBG.cameras = [camIcons];
				iconText.cameras = [camIcons];

				if (curSelected == -1)
					curSelected = i;
			}
		}

		for (i in 0...iconArray.length)
		{
			RectPos(i);
		}

		backShape = new GeneralBack(0, 570, 230, 150, Language.get('back', 'main'), 0x53b7ff, backMenu);
		add(backShape);

		var BG:Rect = new Rect(0, FlxG.height - 150, bgwidth, 5, 0, 0, FlxColor.BLACK, 1);
		BG.cameras = [camHUD];
		add(BG);

		var BG:Rect = new Rect(bgwidth, 0, 5, FlxG.height, 0, 0, FlxColor.BLACK, 1);
		BG.cameras = [camHUD];
		add(BG);

		var BG:Rect = new Rect(bgwidth + 5, FlxG.height - 150, FlxG.width - bgwidth + 5, 5, 0, 0, FlxColor.BLACK, 1);
		BG.cameras = [camHUD];
		add(BG);

		var BG:Rect = new Rect(bgwidth + 5, FlxG.height * 0.1, FlxG.width - bgwidth + 5, 5, 0, 0, FlxColor.BLACK, 1);
		BG.cameras = [camHUD];
		add(BG);

		nameText = new FlxText(170, 5, 0, "");
		nameText.setFormat(font, 45, FlxColor.BLACK, CENTER);
		nameText.antialiasing = ClientPrefs.data.antialiasing;
		nameText.updateHitbox();

		jobText = new FlxText(700, 5, 0, "");
		jobText.setFormat(font, 45, FlxColor.BLACK, CENTER);
		jobText.antialiasing = ClientPrefs.data.antialiasing;
		jobText.updateHitbox();

		var dbwidth:Int = 470;

		nameRect = new Rect(265, 5, dbwidth, 60, 25, 25, FlxColor.WHITE, 0.5);
		add(nameRect);

		jobRect = new Rect(785, 5, dbwidth, 60, 25, 25, FlxColor.WHITE, 0.5);
		add(jobRect);

		bigIconRect = new Rect(290, 115, 420, 420, 0, 0, FlxColor.WHITE, 0.5);
		add(bigIconRect);

		descRect = new Rect(785, 115, dbwidth, 420, 0, 0, FlxColor.WHITE, 0.5);
		add(descRect);

		add(nameText);
		add(jobText);

		bigIcon = new FlxSprite();
		bigIcon.loadGraphic(Paths.image(mainIconExists(creditsStuff[curSelected + 1][1])));
		bigIcon.scale.set(1, 1);
		bigIcon.updateHitbox();
		bigIcon.visible = false;
		bigIcon.antialiasing = ClientPrefs.data.antialiasing;
		add(bigIcon);

		iconVideo = new FlxVideoSprite(bigIconRect.x, bigIconRect.y);
		iconVideo.bitmap.onFormatSetup.add(function():Void
		{
			if (iconVideo.bitmap != null && iconVideo.bitmap.bitmapData != null)
			{
				final scale:Float = Math.min(dbwidth / iconVideo.bitmap.bitmapData.width, 420 / iconVideo.bitmap.bitmapData.height);

				iconVideo.setGraphicSize(iconVideo.bitmap.bitmapData.width * scale, iconVideo.bitmap.bitmapData.height * scale);
				iconVideo.updateHitbox();
			}
		});
		iconVideo.antialiasing = ClientPrefs.data.antialiasing;
		add(iconVideo);

		if (FileSystem.exists(mainIconVideoExists(creditsStuff[curSelected + 1][1])))
		{
			iconVideo.load(mainIconVideoExists(creditsStuff[curSelected + 1][1]), ['input-repeat=65545']);
			iconVideo.play();
			iconVideo.alpha = 1;
		}
		else
		{
			iconVideo.alpha = 0.0001;
			bigIcon.visible = true;
		}

		descText = new FlxText(785, 115, dbwidth, "");
		descText.setFormat(font, 20, FlxColor.BLACK, LEFT);
		descText.antialiasing = ClientPrefs.data.antialiasing;
		descText.updateHitbox();

		add(descText);

		bg.color = CoolUtil.colorFromString(creditsStuff[curSelected][4]);
		intendedColor = bg.color;
		changeSelection();

		RectPosUpdate(false);

		super.create();
	}

	function descPosUpdate()
	{
		nameText.text = iconTextArray[curSelected].text;
		if (nameText.width > 470)
			nameText.scale.x = 470 / nameText.width;
		nameText.updateHitbox();
		nameText.x = nameRect.x + nameRect.width / 2 - nameText.width / 2;

		jobText.text = creditsStuff[curSelected + 1][2];
		jobText.scale.x = 1;
		if (jobText.width > 470)
			jobText.scale.x = 470 / jobText.width;
		jobText.updateHitbox();
		jobText.x = jobRect.x + jobRect.width / 2 - jobText.width / 2;

		if (mainIconVideoExists(creditsStuff[curSelected + 1][1]) != null)
		{
			bigIcon.visible = false;
			iconVideo.load(mainIconVideoExists(creditsStuff[curSelected + 1][1]), ['input-repeat=65545']);
			iconVideo.play();
			new FlxTimer().start(0.1, function(tmr:FlxTimer)
			{
				iconVideo.alpha = 1;
			});
			trace(mainIconVideoExists(creditsStuff[curSelected + 1][1]));
		}
		else
		{
			iconVideo.play();
			iconVideo.pause();
			iconVideo.alpha = 0.0001;
			bigIcon.visible = true;

			bigIcon.loadGraphic(Paths.image(mainIconExists(creditsStuff[curSelected + 1][1])));
			bigIcon.setGraphicSize(420, 420);
			bigIcon.updateHitbox();

			trace(mainIconExists(creditsStuff[curSelected + 1][1]));
		}

		bigIcon.x = bigIconRect.x + bigIconRect.width / 2 - bigIcon.width / 2;
		bigIcon.y = bigIconRect.y + bigIconRect.height / 2 - bigIcon.height / 2;

		descText.text = creditsStuff[curSelected + 1][3];
		descText.updateHitbox();

		Recognizelink();
	}

	function mainIconVideoExists(file):String
	{
		var filepath:String = Paths.video("credits/" + file);

		if (FileSystem.exists(filepath))
			return filepath;
		else
			return null;
	}

	function mainIconExists(file):String
	{
		var str:String = 'credits/bigIcon/missing_icon';
		var fileName = 'credits/bigIcon/' + file;
		if (Paths.fileExists('images/$fileName.png', IMAGE))
			str = fileName;

		return str;
	}

	var linkArray:Array<String> = [];
	var keyArray:Array<String> = [];

	function Recognizelink()
	{
		if (creditsStuff[curSelected + 1][4] != null)
		{
			linkArray = [];
			keyArray = [];

			for (i in 0...linkSpriteArray.length)
			{
				linkSpriteArray[i].destroy();
			}

			for (i in 5...creditsStuff[curSelected + 1].length)
			{
				linkArray.push(creditsStuff[curSelected + 1][i]);
			}
			trace(linkArray);

			Recognize();

			for (i in 0...linkArray.length)
			{
				var link:CreditsNote = new CreditsNote(keyArray[i], linkArray[i]);
				link.x = 755 + 160 * i - 160 * linkArray.length / 2;
				link.y = 575;

				link.antialiasing = true;

				link.scale.set(0.7, 0.7);
				link.updateHitbox();
				add(link);
				linkSpriteArray.push(link);
			}
		}
	}

	var linkKey:Array<String> = [
		"github",
		"youtube",
		"x.com",
		"twitter",
		"discord",
		"b23.tv",
		"bilibili",
		"douyin",
		"kuaishou"
	];

	function Recognize()
	{
		for (num in 0...linkArray.length)
		{
			var alreadyGet:Bool = false;
			for (key in 0...linkKey.length)
			{
				if (linkArray[num].indexOf(linkKey[key]) != -1 && !alreadyGet)
				{
					alreadyGet = true;
					keyArray.push(linkKey[key]);
				}
			}
		}
		keyArray.push("none");
	}

	function RectPosUpdate(forceUpdate:Bool = false)
	{
		if (!forceUpdate && lerpPosition == position)
			return; // 优化
		for (i in 0...iconBGArray.length)
		{
			RectPos(i);
		}
	}

	function RectPos(i)
	{
		iconArray[i].x = 20;
		iconArray[i].y = lerpPosition + i * 120;
		iconArray[i].y = iconArray[i].y + iconBGArray[0].height / 2 - iconBGArray[0].height / 2;

		iconBGArray[i].x = 0;
		iconBGArray[i].y = lerpPosition + i * 120 - 30;

		iconTextArray[i].x = 80;
		iconTextArray[i].y = lerpPosition + i * 120 + 12;
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

		mouseMove();
		if (FlxG.mouse.x <= 230 && FlxG.mouse.y <= FlxG.height - 120)
		{
			//position += FlxG.mouse.wheel * 70;
			if (FlxG.mouse.pressed)
			{
				position += moveData;
				lerpPosition = position;
				RectPosUpdate(true);
			}

			for (i in 0...iconBGArray.length)
			{
				if (iconBGArray[i].color != FlxColor.GRAY)
				{
					iconBGArray[i].color = FlxColor.GRAY;
					iconBGArray[i].alpha = 0.7;
				}

				if (iconBGArray[curSelected].color != FlxColor.WHITE)
				{
					iconBGArray[curSelected].color = FlxColor.WHITE;
					iconBGArray[curSelected].alpha = 0.7;
				}

				if (CoolUtil.mouseOverlaps(iconBGArray[i], camIcons))
				{
					if (FlxG.mouse.justReleased && i != curSelected)
					{
						//position += avgSpeed * (0.0166 / elapsed) * Math.pow(1.1, Math.abs(avgSpeed * 0.8));
						//if (Math.abs(avgSpeed * (0.0166 / elapsed)) < 1)
						//{
							changeSelection(i);
						//}
					}
				}
			}
		}

		if (position > 360 - 330)
			position = FlxMath.lerp(360 - 330, position, Math.exp(-elapsed * 15));
		if (position < 360 - 120 * (iconBGArray.length - 2))
			position = FlxMath.lerp(360 - 120 * (iconBGArray.length - 2), position, Math.exp(-elapsed * 15));

		if (Math.abs(lerpPosition - position) < 1)
			lerpPosition = position;
		else
			lerpPosition = FlxMath.lerp(position, lerpPosition, Math.exp(-elapsed * 15));

		if (controls.BACK)
		{
			close();
		}

		RectPosUpdate(false);
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
		avgSpeed = avgSpeed * 0.75 + moveData * 0.25;
	}

	var moveTween:FlxTween = null;

	function changeSelection(change:Int = 0)
	{
		FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
		curSelected = change;

		var newColor:FlxColor = CoolUtil.colorFromString(creditsStuff[curSelected + 1][4]);
		if (newColor != intendedColor)
		{
			if (colorTween != null)
			{
				colorTween.cancel();
			}
			intendedColor = newColor;
			colorTween = FlxTween.color(bg, 1, bg.color, intendedColor, {
				onComplete: function(twn:FlxTween)
				{
					colorTween = null;
				}
			});
		}

		descPosUpdate();
	}

	private function unselectableCheck(num:Int):Bool
	{
		return creditsStuff[num].length <= 1;
	}

	function backMenu()
	{
		close();
	}
}
