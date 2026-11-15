package states.creditsState;

import openfl.display.BitmapData;
import openfl.geom.Matrix;
import openfl.geom.Point;
import openfl.geom.Rectangle;
import openfl.geom.Vector3D;

import foxlite.FoxCamera;
import foxlite.FoxScene;
import foxlite.FoxShader;
import foxlite.flixel.FoxFlxSprite;
import foxlite.material.FoxMaterial;
import foxlite.math.FoxMathUtil;
import foxlite.renderer.FoxRenderer;
import foxlite.loaders.FoxLoaderUtil;

import states.mainMenuState.MainMenuState;

import general.objects.state.general.GeneralBack;
#if hxvlc
import hxvlc.flixel.FlxVideoSprite;
#end

using StringTools;

typedef Credit3D = {
	var name:String;
	var icon:String;
	var role:String;
	var desc:String;
	var color:Int;
	var links:Array<Array<String>>;
}

typedef Link3D = {
	var x:Float;
	var y:Float;
	var w:Float;
	var h:Float;
	var url:String;
}

class Credits3DState extends MusicBeatState
{
	static inline var CAM_Z:Float = 3.6;
	static inline var CAM_FOV:Float = 60;

	static inline var LW:Int = 240;
	static inline var LH:Int = 540;
	static inline var RW:Int = 520;
	static inline var RH:Int = 540;
	static inline var IW:Int = 260;
	static inline var IH:Int = 260;

	static inline var LEFT_WORLD_W:Float = 1.32;
	static inline var RIGHT_WORLD_W:Float = 2.90;
	static inline var ICON_WORLD_W:Float = 1.05;

	static inline var LEFT_X:Float = -2.40;
	static inline var RIGHT_X:Float = 2.00;
	static inline var ICON_X:Float = -0.60;
	static inline var LEFT_Z:Float = 0.15;
	static inline var RIGHT_Z:Float = -0.10;
	static inline var ICON_Z:Float = 0.95;

	static inline var LEFT_YAW:Float = 16;
	static inline var RIGHT_YAW:Float = -15;
	static inline var TILT_X:Float = -5;
	static inline var ROLL_L:Float = -1.5;
	static inline var ROLL_R:Float = 1.0;

	static inline var ITEM_H:Float = 56;
	static inline var BTN_H:Float = 34;
	static inline var BTN_GAP:Float = 8;
	static inline var BTN_TOP:Float = 312;
	static inline var ROT_LIMIT:Float = 60;
	static inline var SWITCH_SPEED:Float = 540;
	static inline var SWITCH_MIN_SPEED:Float = 300;

	static inline var PLATE_BG:Int = 0x99000000;
	static inline var SELECT_BG:Int = 0x44FFFF00;
	static inline var BTN_BG:Int = 0x22FFFFFF;
	static inline var BTN_HOVER:Int = 0x44FFFFFF;
	static inline var LINE:Int = 0x33FFFFFF;

	static var CREDITS:Array<Credit3D> = [
		{name:"Beihu", icon:"beihu", role:"Main Programmer", desc:"Head of NovaFlare Engine\n\nNothing special.", color:0xFFFFC0CB,
			links:[["BILIBILI", "https://b23.tv/QfPKw2o"], ["YOUTUBE", "https://youtube.com/@beihu235"], ["GITHUB", "https://github.com/beihu235"]]},
		{name:"MaoPou", icon:"maopou", role:"Programmer", desc:"Code help\n\nA crumb who likes to write code, but doesn't like to look at code :)", color:0xFFFFFFFF,
			links:[["BILIBILI", "https://space.bilibili.com/1548393523"], ["GITHUB", "https://github.com/MaoPou"]]},
		{name:"VapireMox", icon:"vapiremox", role:"Programmer", desc:"hscript-iris-improved Developer\n\nYou're right about everything, and you've done everything correctly. I will obey you.", color:0xFF090C1A,
			links:[["GITHUB", "https://github.com/VapireMox"], ["BILIBILI", "https://b23.tv/LD5ekXY"]]},
		{name:"Kangel", icon:"kangel", role:"Programmer", desc:"Code help\n\nThis is a message.", color:0xFFFFFFFF,
			links:[["GITHUB", "https://github.com/kangeluwu"], ["YOUTUBE", "https://www.youtube.com/@kannoYuki0524"]]},
		{name:"Chiny", icon:"chiny", role:"Programmer", desc:"Credit state logic creator\n\nBanG Dream & Touhou player.", color:0xFF800080,
			links:[["BILIBILI", "https://space.bilibili.com/3493288327777064"], ["GITHUB", "https://github.com/dmmchh"]]},
		{name:"TieGuo", icon:"tieguo", role:"Ex-Programmer", desc:"Pause Menu creator\n\nI like coding shit.", color:0xFFFF6600,
			links:[["BILIBILI", "https://b23.tv/7OVWzAO"]]},
		{name:"Careful_Scarf_487", icon:"Careful_Scarf_487", role:"Main Artist", desc:"Main Artist of the engine\n\nI'm probably the least present in the whole production crew.", color:0xFF990000,
			links:[["BILIBILI", "https://b23.tv/DQ1a0jO"]]},
		{name:"MengQi", icon:"mengqi", role:"Artist", desc:"Pause menu artist\n\n\"this is description", color:0xFF9B5A67,
			links:[["BILIBILI", "https://space.bilibili.com/2130239542"]]},
		{name:"AZjessica", icon:"AZjessica", role:"Artist", desc:"Freeplay state artist\n\nI love animation. I'm an idiot.", color:0xFFDE444B,
			links:[["BILIBILI", "https://b23.tv/GyqgrAO"], ["YOUTUBE", "https://youtube.com/@azjessica"], ["X", "https://x.com/Jessica33049821"]]},
		{name:"Ben Eyre", icon:"beneyre", role:"Artist", desc:"Freeplay / Credits state artist\n\nI can't believe I actually have the honor of being added to the production team.", color:0xFFFFCDA4,
			links:[["BILIBILI", "https://b23.tv/cB2uujD"], ["X", "https://x.com/hngstngxng83905"]]},
		{name:"als", icon:"als", role:"Animation", desc:"Opening screen animation support", color:0xFFFF0000,
			links:[["BILIBILI", "https://b23.tv/mNNX8R8"]]},
		{name:"blockDDDdark", icon:"ddd", role:"Musician", desc:"Engine sound effort support\n\nComposer, painter, meme subculture lover.", color:0xFF5123A0,
			links:[["BILIBILI", "https://space.bilibili.com/401733211"]]}
	];

	static var foxReady:Bool = false;

	var scene:FoxScene;
	var cam:FoxCamera;

	var leftCanvas:FlxSprite;
	var rightCanvas:FlxSprite;
	var iconCanvas:FlxSprite;
	var leftBoard:FoxFlxSprite;
	var rightBoard:FoxFlxSprite;
	var iconBoard:FoxFlxSprite;

	var icons:Array<FlxSprite> = [];
	var bigIcons:Array<FlxSprite> = [];
	var nameTexts:Array<FlxText> = [];
	var linkRects:Array<Link3D> = [];

	var curSelected:Int = 0;
	var position:Float = 0;
	var lerpPosition:Float = 0;
	var lastLerp:Float = 999999;
	var lastSelected:Int = -1;

	var hoverLink:Int = -1;
	var draggingList:Bool = false;
	var draggingIcon:Bool = false;
	var listTapOnLeft:Bool = false;
	var dragTotal:Float = 0;
	var lastMouseX:Float = 0;
	var lastMouseY:Float = 0;

	var iconAngle:Float = 0;
	var switchTarget:Int = -1;
	var switchPhase:Int = 0;
	var switchSwapped:Bool = false;
	var switchDir:Float = 1;
	var switchTravel:Float = 0;
	var exiting:Bool = false;

	var desat:FlxSprite;
	var desatColor:Int = 0;
	var hasVideo:Bool = false;
	#if hxvlc
	var videoSprite:FlxVideoSprite;
	#end
	var mediaGen:Int = 0;
	var iconVel:Float = 0;
	var lastIconAngle:Float = 0;
	var backBtn:GeneralBack;

	var homL:Array<Float> = null;
	var homR:Array<Float> = null;
	var homI:Array<Float> = null;

	static var _rect:Rectangle = new Rectangle();
	static var _point:Point = new Point();
	static var _matrix:Matrix = new Matrix();

	override function create()
	{
		super.create();
		initFox();

		desat = new FlxSprite();
		var desatGfx = Paths.image('menuDesat');
		if (desatGfx != null) desat.loadGraphic(desatGfx);
		else desat.makeGraphic(FlxG.width, FlxG.height, 0xFF222831);
		desat.setGraphicSize(FlxG.width, FlxG.height);
		desat.updateHitbox();
		desat.scrollFactor.set(0, 0);
		desat.color = CREDITS[0].color;
		desatColor = desat.color;
		add(desat);

		var bg = new FlxSprite();
		var gfx = Paths.image('credits3d/bg');
		if (gfx != null) bg.loadGraphic(gfx);
		else bg.makeGraphic(FlxG.width, FlxG.height, 0xFF1A1D22);
		bg.setGraphicSize(FlxG.width, FlxG.height);
		bg.updateHitbox();
		bg.scrollFactor.set(0, 0);
		bg.alpha = 0.5;
		add(bg);

		scene = new FoxScene(FlxG.width, FlxG.height);
		scene.scrollFactor.set(0, 0);

		cam = new FoxCamera(0, 0, CAM_Z, 0x00000000);
		cam.fov = CAM_FOV;
		cam.scene = scene;
		scene.foxCameras.push(cam);

		var shader = FoxShader.fromAsset(FoxShader.BASIC, ["UNSHADED"]);

		leftCanvas = makeCanvas(LW, LH);
		rightCanvas = makeCanvas(RW, RH);
		iconCanvas = makeCanvas(IW, IH);

		leftBoard = new FoxFlxSprite(leftCanvas, FoxMaterial.create(shader), LEFT_WORLD_W / LW);
		rightBoard = new FoxFlxSprite(rightCanvas, FoxMaterial.create(shader), RIGHT_WORLD_W / RW);
		iconBoard = new FoxFlxSprite(iconCanvas, FoxMaterial.create(shader), ICON_WORLD_W / IW);

		leftBoard.material.renderPriority = 2;
		rightBoard.material.renderPriority = 3;
		iconBoard.material.renderPriority = 4;
		leftBoard.material.alphaScissor = 0.02;
		rightBoard.material.alphaScissor = 0.02;
		iconBoard.material.alphaScissor = 0.02;

		leftBoard.setPosition(LEFT_X, 0.06, LEFT_Z);
		rightBoard.setPosition(RIGHT_X, 0.06, RIGHT_Z);
		iconBoard.setPosition(ICON_X, 0.02, ICON_Z);
		leftBoard.setAngle(TILT_X, LEFT_YAW, ROLL_L);
		rightBoard.setAngle(TILT_X, RIGHT_YAW, ROLL_R);
		iconBoard.setAngle(TILT_X, 0, 0);

		scene.add(leftBoard);
		scene.add(rightBoard);
		scene.add(iconBoard);
		add(scene);

		backBtn = new GeneralBack(20, FlxG.height - 95, 250, 75, Language.get('back', 'main'), 0x53b7ff, exitToMenu);
		add(backBtn);

		buildCreditArt();
		redrawList();
		redrawDetail();
		redrawIcon();
		lastLerp = lerpPosition;
		lastSelected = curSelected;
		refreshHomographies();
		positionBackButton();
		loadMemberMedia(curSelected);
	}

	static function initFox():Void
	{
		if (foxReady) return;
		foxReady = true;
		FoxRenderer.initLibs();
		FoxLoaderUtil.initPathClass(Assets.exists('assets/shared/shaders/foxlite/basic.vert') ? Paths : null);
	}

	static function makeCanvas(w:Int, h:Int):FlxSprite
	{
		var s = new FlxSprite(0, 0);
		s.makeGraphic(w, h, 0x00000000);
		s.updateHitbox();
		s.centerOrigin();
		return s;
	}

	function buildCreditArt():Void
	{
		var font = Paths.font('montserrat.ttf');
		for (i in 0...CREDITS.length)
		{
			var c = CREDITS[i];

			var small = new FlxSprite();
			var smallGfx = Paths.image('credits/${c.icon}');
			if (smallGfx == null) smallGfx = Paths.image('credits/missing_icon');
			if (smallGfx != null) small.loadGraphic(smallGfx);
			else small.makeGraphic(40, 40, 0xFF333333);
			icons.push(small);

			var big = new FlxSprite();
			var bigGfx = Paths.image('credits/bigIcon/${c.icon}');
			if (bigGfx == null) bigGfx = Paths.image('credits/bigIcon/missing_icon');
			if (bigGfx != null) big.loadGraphic(bigGfx);
			else big.makeGraphic(150, 150, 0xFF333333);
			bigIcons.push(big);

			var n = new FlxText(0, 0, 0, c.name, 13);
			n.setFormat(font, 13, 0xFFFFFFFF, "left");
			n.antialiasing = true;
			n.drawFrame(true);
			nameTexts.push(n);
		}
	}

	function redrawList():Void
	{
		var bd = leftCanvas.pixels;
		_rect.setTo(0, 0, LW, LH);
		bd.fillRect(_rect, 0x00000000);
		bd.fillRect(_rect, PLATE_BG);

		var selY = lerpPosition + curSelected * ITEM_H;
		var y0 = Math.max(0, selY);
		var y1 = Math.min(LH, selY + ITEM_H);
		if (y1 > y0)
		{
			_rect.setTo(0, y0, LW, y1 - y0);
			bd.fillRect(_rect, SELECT_BG);
		}

		for (i in 0...CREDITS.length)
		{
			var iy = lerpPosition + i * ITEM_H;
			if (iy + ITEM_H < 0 || iy > LH) continue;
			paint(bd, icons[i].pixels, 8, iy + (ITEM_H - 32) * 0.5, 32, 32);
			paint(bd, nameTexts[i].framePixels, 48, iy + (ITEM_H - 16) * 0.5);
		}
		upload(leftBoard);
	}

	function redrawDetail():Void
	{
		var c = CREDITS[curSelected];
		var bd = rightCanvas.pixels;
		_rect.setTo(0, 0, RW, RH);
		bd.fillRect(_rect, 0x00000000);
		bd.fillRect(_rect, PLATE_BG);

		var name = makeText(c.name, 28, 0xFFFFFFFF);
		paint(bd, name, 28, 26);
		name.dispose();
		var role = makeText(c.role.toUpperCase(), 13, c.color);
		paint(bd, role, 28, 72);
		role.dispose();

		_rect.setTo(28, 104, RW - 56, 1);
		bd.fillRect(_rect, LINE);

		var desc = new FlxText(0, 0, RW - 56, c.desc, 17);
		desc.setFormat(Paths.font('montserrat.ttf'), 17, 0xFFC7D0DC, "left");
		desc.wordWrap = true;
		desc.antialiasing = true;
		desc.drawFrame(true);
		paint(bd, desc.framePixels, 28, 126);
		desc.destroy();

		linkRects.resize(0);
		var by = BTN_TOP;
		for (link in c.links)
		{
			var r:Link3D = {x:28, y:by, w:RW - 56, h:BTN_H, url:link[1]};
			var idx = linkRects.length;
			_rect.setTo(r.x, r.y, r.w, r.h);
			bd.fillRect(_rect, idx == hoverLink ? BTN_HOVER : BTN_BG);
			var label = makeText(link[0], 13, 0xFFFFFFFF);
			paint(bd, label, r.x + 12, r.y + 9);
			label.dispose();
			linkRects.push(r);
			by += BTN_H + BTN_GAP;
			if (by + BTN_H > RH) break;
		}
		upload(rightBoard);
	}

	function redrawIcon():Void
	{
		var bd = iconCanvas.pixels;
		_rect.setTo(0, 0, IW, IH);
		bd.fillRect(_rect, 0x00000000);
		paint(bd, bigIcons[curSelected].pixels, 0, 0, IW, IH);
		upload(iconBoard);
	}

	static function upload(board:FoxFlxSprite):Void
	{
		if (board == null) return;
		var bd = board.getSpriteTexture();
		if (bd == null) return;
		var ctx = FoxRenderer.getContext();
		if (ctx != null) bd.getTexture(ctx);
		var tex = board.texture;
		if (tex != null) tex.take(bd);
	}

	static function makeText(str:String, size:Int, color:Int):BitmapData
	{
		var t = new FlxText(0, 0, 0, str, size);
		t.setFormat(Paths.font('montserrat.ttf'), size, color, "left");
		t.antialiasing = true;
		t.drawFrame(true);
		var bd = t.framePixels.clone();
		t.destroy();
		return bd;
	}

	static function paint(target:BitmapData, src:BitmapData, x:Float, y:Float, w:Float = 0, h:Float = 0):Void
	{
		if (src == null || target == null) return;
		if (w <= 0 || h <= 0)
		{
			_rect.setTo(0, 0, src.width, src.height);
			_point.setTo(x, y);
			target.copyPixels(src, _rect, _point, null, null, true);
		}
		else
		{
			_matrix.identity();
			_matrix.scale(w / src.width, h / src.height);
			_matrix.translate(x, y);
			target.draw(src, _matrix, null, null, null, true);
		}
	}

	override function update(elapsed:Float)
	{
		updateIconMotion(elapsed);
		super.update(elapsed);
		refreshHomographies();
		handleCreditsInput(elapsed);
		updateScrollLimits(elapsed);

		if (desat != null && desat.color != desatColor)
			desat.color = FlxColor.interpolate(desat.color, desatColor, 1 - Math.exp(-elapsed * 3.2));

		paintVideoFrame();

		if (Math.abs(lerpPosition - lastLerp) > 0.3 || curSelected != lastSelected)
		{
			redrawList();
			lastLerp = lerpPosition;
			lastSelected = curSelected;
		}
	}

	function updateIconMotion(elapsed:Float):Void
	{
		if (switchPhase != 0)
		{
			iconVel = FlxMath.lerp(iconVel, switchDir * SWITCH_SPEED, 1 - Math.exp(-elapsed * 5));
			var step = iconVel * elapsed;
			iconAngle += step;
			switchTravel += Math.abs(step);
			var n = normalizeAngle(iconAngle);
			if (!switchSwapped && Math.abs(n) >= 90)
			{
				if (switchTarget != -1 && switchTarget != curSelected)
					swapMember(switchTarget);
				switchSwapped = true;
			}
			if ((switchSwapped || switchTarget == curSelected) && Math.abs(n) < 3)
			{
				iconAngle = Math.round(iconAngle / 360) * 360;
				iconVel = 0; switchPhase = 0; switchSwapped = false; switchTravel = 0; switchTarget = -1;
			}
			applyIconAngle();
			lastIconAngle = iconAngle;
			return;
		}

		if (draggingIcon)
		{
			var d = iconAngle - lastIconAngle;
			if (elapsed > 0) iconVel = FlxMath.lerp(iconVel, d / elapsed, 0.35);
			clampRotation();
			lastIconAngle = iconAngle;
			applyIconAngle();
			return;
		}

		if (Math.abs(iconVel) > 0.01)
		{
			iconAngle += iconVel * elapsed;
			iconVel *= Math.exp(-elapsed * 3.2);
			if (Math.abs(iconVel) < 0.4) iconVel = 0;
			clampRotation();
			applyIconAngle();
		}
		lastIconAngle = iconAngle;
	}

	function applyIconAngle():Void
	{
		iconBoard.angleY = iconAngle;
		var show = Math.abs(normalizeAngle(iconAngle)) < 89;
		if (iconBoard.visible != show) iconBoard.visible = show;
	}

	function clampRotation():Void
	{
		if (iconAngle > ROT_LIMIT)
		{
			iconAngle = ROT_LIMIT;
			if (iconVel > 0) iconVel = 0;
		}
		else if (iconAngle < -ROT_LIMIT)
		{
			iconAngle = -ROT_LIMIT;
			if (iconVel < 0) iconVel = 0;
		}
	}

	static inline function normalizeAngle(a:Float):Float
	{
		return ((a % 360) + 540) % 360 - 180;
	}

	function positionBackButton():Void
	{
		if (backBtn == null || leftBoard == null) return;
		var hh = LH * (LEFT_WORLD_W / LW) * 0.5;
		var local = new Vector3D(0, -hh, 0, 1);
		var world = leftBoard.transform.transformVector(local);
		var s = project(world);
		backBtn.x = s[0] - 125;
		backBtn.y = s[1] + 16;
	}

	function swapMember(i:Int):Void
	{
		curSelected = i;
		hoverLink = -1;
		redrawIcon();
		redrawDetail();
		redrawList();
		lastLerp = lerpPosition;
		lastSelected = curSelected;

		var iy = curSelected * ITEM_H;
		var minY = Math.min(0, LH - ITEM_H * CREDITS.length);
		if (iy + position < 20 || iy + position + ITEM_H > LH - 10)
			position = FlxMath.bound(LH * 0.4 - iy, minY, 0);

		loadMemberMedia(curSelected);
	}

	function selectMember(i:Int):Void
	{
		if (i < 0 || i >= CREDITS.length) return;
		if (i == curSelected && switchPhase == 0) return;
		if (switchPhase == 0)
		{
			switchDir = (iconVel >= 0) ? 1 : -1;
			if (iconVel * switchDir < SWITCH_MIN_SPEED) iconVel = switchDir * SWITCH_MIN_SPEED;
			switchPhase = 1;
			switchTravel = 0;
			switchSwapped = false;
		}
		else
		{
			if (switchSwapped) switchSwapped = false;
		}
		switchTarget = i;
		FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
	}

	function handleCreditsInput(elapsed:Float):Void
	{
		var mx = FlxG.mouse.x;
		var my = FlxG.mouse.y;
		var spinning = (switchPhase != 0);
		var uvL = mapToBoard(mx, my, homL);
		var uvR = mapToBoard(mx, my, homR);
		var uvI = mapToBoard(mx, my, homI);
		var onLeft = inside(uvL);
		var onRight = inside(uvR);
		var onIcon = inside(uvI);

		var hover = -1;
		if (onRight)
		{
			var px = uvR[0] * RW;
			var py = uvR[1] * RH;
			for (i in 0...linkRects.length)
			{
				var b = linkRects[i];
				if (px >= b.x && px <= b.x + b.w && py >= b.y && py <= b.y + b.h)
				{
					hover = i;
					break;
				}
			}
		}
		if (hover != hoverLink)
		{
			hoverLink = hover;
			redrawDetail();
		}

		if (controls.UI_UP_P) selectMember(curSelected - 1);
		if (controls.UI_DOWN_P) selectMember(curSelected + 1);

		if (FlxG.mouse.justPressed)
		{
			lastMouseX = mx; lastMouseY = my; dragTotal = 0;
			listTapOnLeft = onLeft;
			if (!spinning)
			{
				if (onIcon) draggingIcon = true;
				else if (onRight && hover >= 0) CoolUtil.browserLoad(linkRects[hover].url);
				else if (onLeft) draggingList = true;
			}
		}

		if (!spinning)
		{
			if (FlxG.mouse.wheel != 0) position += FlxG.mouse.wheel * 46;

			if (draggingIcon && FlxG.mouse.pressed)
			{
				iconAngle += (mx - lastMouseX) * 0.55;
				applyIconAngle();
			}
			if (draggingList && FlxG.mouse.pressed)
			{
				var dy = my - lastMouseY;
				position += dy;
				lerpPosition = position;
				dragTotal += Math.abs(dy);
			}
			lastMouseX = mx;
			lastMouseY = my;
		}
		else
		{
			lastMouseX = mx;
			lastMouseY = my;
		}

		if (FlxG.mouse.justReleased)
		{
			if (((draggingList && !spinning) || (spinning && listTapOnLeft)) && dragTotal < 8 && onLeft)
				selectMember(Std.int(Math.floor((uvL[1] * LH - lerpPosition) / ITEM_H)));
			draggingList = false;
			draggingIcon = false;
		}

		if (controls.BACK && !exiting)
		{
			exitToMenu();
		}
	}

	function exitToMenu():Void
	{
		if (exiting) return;
		exiting = true;
		FlxG.sound.play(Paths.sound('cancelMenu'));
		MusicBeatState.switchState(new MainMenuState());
	}

	#if hxvlc
	function loadMemberMedia(i:Int):Void
	{
		var c = CREDITS[i];
		desatColor = c.color;
		mediaGen++;
		var myGen = mediaGen;

		if (videoSprite == null)
		{
			videoSprite = new FlxVideoSprite();
			add(videoSprite);
			videoSprite.visible = false;
		}

		hasVideo = false;
		var vp = Paths.video("credits/" + c.icon);
		try
		{
			if (videoSprite.bitmap != null)
			{
				videoSprite.bitmap.stop();
				videoSprite.bitmap.onFormatSetup.add(function():Void
				{
					if (myGen == mediaGen && videoSprite != null && videoSprite.bitmap != null
						&& videoSprite.bitmap.bitmapData != null)
					{
						hasVideo = true;
					}
				});
				videoSprite.bitmap.load(vp, ['input-repeat=65545']);
				videoSprite.bitmap.play();
				videoSprite.bitmap.volumeAdjust = FlxG.sound.volume;
			}
		}
		catch (e:Dynamic)
		{
			hasVideo = false;
			trace('Credits3D video load failed: ' + e);
		}
	}

	function paintVideoFrame():Void
	{
		if (!hasVideo || videoSprite == null || videoSprite.bitmap == null || videoSprite.bitmap.bitmapData == null)
			return;
		if (Math.abs(normalizeAngle(iconAngle)) >= 89)
			return;

		var src = videoSprite.bitmap.bitmapData;
		var sw = src.width, sh = src.height;
		if (sw <= 0 || sh <= 0) return;
		var scale = Math.max(IW / sw, IH / sh);
		var dw = sw * scale, dh = sh * scale;
		var dx = (IW - dw) * 0.5, dy = (IH - dh) * 0.5;

		var bd = iconCanvas.pixels;
		_rect.setTo(0, 0, IW, IH);
		bd.fillRect(_rect, 0x00000000);
		paint(bd, src, dx, dy, dw, dh);
		upload(iconBoard);
	}
	#end

	function updateScrollLimits(elapsed:Float):Void
	{
		var minY = Math.min(0, LH - ITEM_H * CREDITS.length);
		var decay = Math.exp(-elapsed * 15);
		if (position > 0) position = FlxMath.lerp(0, position, decay);
		if (position < minY) position = FlxMath.lerp(minY, position, decay);

		if (Math.abs(lerpPosition - position) < 0.5) lerpPosition = position;
		else lerpPosition = FlxMath.lerp(lerpPosition, position, 1 - decay);
	}

	function project(p:Vector3D):Array<Float>
	{
		var d = CAM_Z - p.z;
		if (d < 0.05) d = 0.05;
		var f = 1 / Math.tan(CAM_FOV * Math.PI / 360);
		var aspect = FlxG.width / FlxG.height;
		return [FlxG.width * 0.5 * (1 + p.x * f / (aspect * d)),
			FlxG.height * 0.5 * (1 - p.y * f / d)];
	}

	function refreshHomographies():Void
	{
		FoxMathUtil.transformMatrix(leftBoard.transform, leftBoard.position, leftBoard.rotation, leftBoard.scale);
		FoxMathUtil.transformMatrix(rightBoard.transform, rightBoard.position, rightBoard.rotation, rightBoard.scale);
		FoxMathUtil.transformMatrix(iconBoard.transform, iconBoard.position, iconBoard.rotation, iconBoard.scale);
		homL = computeHomography(leftBoard, LW, LH, LEFT_WORLD_W / LW);
		homR = computeHomography(rightBoard, RW, RH, RIGHT_WORLD_W / RW);
		homI = computeHomography(iconBoard, IW, IH, ICON_WORLD_W / IW);
	}

	function computeHomography(board:FoxFlxSprite, cw:Float, ch:Float, ps:Float):Array<Float>
	{
		var hw = cw * ps * 0.5;
		var hh = ch * ps * 0.5;
		var corners:Array<Array<Float>> = [
			[0, 0, -hw, hh], [1, 0, hw, hh],
			[1, 1, hw, -hh], [0, 1, -hw, -hh]
		];
		var A:Array<Array<Float>> = [];
		var B:Array<Float> = [];
		for (c in corners)
		{
			var u = c[0], v = c[1];
			var p = board.transform.transformVector(new Vector3D(c[2], c[3], 0, 1));
			var s = project(p);
			A.push([u, v, 1, 0, 0, 0, -u * s[0], -v * s[0]]);
			B.push(s[0]);
			A.push([0, 0, 0, u, v, 1, -u * s[1], -v * s[1]]);
			B.push(s[1]);
		}
		return solve(A, B);
	}

	static inline function inside(uv:Array<Float>):Bool
	{
		return uv != null && uv[0] >= 0 && uv[0] <= 1 && uv[1] >= 0 && uv[1] <= 1;
	}

	static function mapToBoard(mx:Float, my:Float, h:Array<Float>):Array<Float>
	{
		if (h == null) return null;
		var a = h[0], b = h[1], c = h[2], d = h[3], e = h[4], f = h[5], g = h[6], hh = h[7];
		var A11 = a - g * mx, A12 = b - hh * mx;
		var A21 = d - g * my, A22 = e - hh * my;
		var B1 = mx - c, B2 = my - f;
		var det = A11 * A22 - A12 * A21;
		if (Math.abs(det) < 1e-9) return null;
		return [(B1 * A22 - A12 * B2) / det, (A11 * B2 - B1 * A21) / det];
	}

	static function solve(A:Array<Array<Float>>, B:Array<Float>):Array<Float>
	{
		var n = B.length;
		for (i in 0...n)
		{
			var pivot = i;
			for (r in i + 1...n) if (Math.abs(A[r][i]) > Math.abs(A[pivot][i])) pivot = r;
			if (pivot != i)
			{
				var row = A[i]; A[i] = A[pivot]; A[pivot] = row;
				var val = B[i]; B[i] = B[pivot]; B[pivot] = val;
			}
			if (Math.abs(A[i][i]) < 1e-9) return null;
			for (r in i + 1...n)
			{
				var k = A[r][i] / A[i][i];
				if (k == 0) continue;
				for (col in i...n) A[r][col] -= k * A[i][col];
				B[r] -= k * B[i];
			}
		}
		var x:Array<Float> = [for (i in 0...n) 0.0];
		var i = n - 1;
		while (i >= 0)
		{
			var sum = B[i];
			for (col in i + 1...n) sum -= A[i][col] * x[col];
			x[i] = sum / A[i][i];
			i--;
		}
		return x;
	}

	override function destroy()
	{
		#if hxvlc
		if (videoSprite != null)
		{
			try { videoSprite.stop(); } catch (e:Dynamic) {}
			videoSprite = null;
		}
		#end
		super.destroy();
		for (s in icons) s.destroy();
		for (s in bigIcons) s.destroy();
		for (t in nameTexts) t.destroy();
		leftCanvas.destroy();
		rightCanvas.destroy();
		iconCanvas.destroy();
	}
}