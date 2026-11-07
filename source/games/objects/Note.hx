package games.objects;

import flixel.math.FlxRect;

import general.backend.animation.PsychAnimationController;

import general.shaders.RGBPalette;
import general.shaders.ColorSwap;
import general.shaders.RGBPalette.RGBShaderReference;

import developer.editors.EditorPlayState;

import games.backend.NoteTypesConfig;
import games.objects.StrumNote;

typedef EventNote =
{
	strumTime:Float,
	event:String,
	value1:String,
	value2:String
}

typedef NoteSplashData =
{
	disabled:Bool,
	texture:String,
	useGlobalShader:Bool, // breaks r/g/b/a but makes it copy default colors for your custom note
	useRGBShader:Bool,
	antialiasing:Bool,
	r:FlxColor,
	g:FlxColor,
	b:FlxColor,
	a:Float
}

/**
 * The note object used as a data structure to spawn and manage notes during gameplay.
 * 
 * If you want to make a custom note type, you should search for: "function set_noteType"
**/
class Note extends FlxSprite
{
	// This is needed for the hardcoded note types to appear on the Chart Editor,
	// It's also used for backwards compatibility with 0.1 - 0.3.2 charts.
	public static final defaultNoteTypes:Array<String> = [
		'', // Always leave this one empty pls
		'Alt Animation',
		'Hey!',
		'Hurt Note',
		'GF Sing',
		'No Animation'
	];

	static var follow:Dynamic = null;

	public var extraData:Map<String, Dynamic> = new Map<String, Dynamic>();

	public var strumTime:Float = 0;
	public var noteData:Int = 0;

	public var mustPress:Bool = false;
	public var canBeHit:Bool = false;
	public var tooLate:Bool = false;

	public var wasGoodHit:Bool = false;
	public var missed:Bool = false;

	public var ignoreNote:Bool = false;
	public var hitByOpponent:Bool = false;
	public var noteWasHit:Bool = false;
	public var prevNote:Note;
	public var nextNote:Note;

	public var spawned:Bool = false;

	public var tail:Array<Note> = []; // for sustains
	public var killTail:Bool = false;
	public var parent:Note;
	public var blockHit:Bool = false; // only works for player

	public var sustainLength:Float = 0;
	public var canHold:Bool = false;
	public var isSustainNote:Bool = false;
	public var noteType(default, set):String = null;

	public var eventName:String = '';
	public var eventLength:Int = 0;
	public var eventVal1:String = '';
	public var eventVal2:String = '';

	public var rgbShader:RGBShaderReference;

	public static var globalRgbShaders:Array<RGBPalette> = [];

	public var colorSwap:ColorSwap;

	public var inEditor:Bool = false;

	public var animSuffix:String = '';
	public var gfNote:Bool = false;
	public var earlyHitMult:Float = 1;
	public var lateHitMult:Float = 1;
	public var lowPriority:Bool = false;

	public static var SUSTAIN_SIZE:Int = 44;
	public static var swagWidth:Float = 160 * 0.7;
	public static var swagWidthUnscaled:Float = 160;
	public static var colArray:Array<String> = ['purple', 'blue', 'green', 'red'];
	public static var defaultNoteSkin:String = 'noteSkins/NOTE_assets';

	public var noteSplashData:NoteSplashData = {
		disabled: false,
		texture: null,
		antialiasing: !PlayState.isPixelStage,
		useGlobalShader: false,
		useRGBShader: (PlayState.SONG != null) ? !(PlayState.SONG.disableNoteRGB == true) : true,
		r: -1,
		g: -1,
		b: -1,
		a: ClientPrefs.data.splashAlpha
	};

	public var trackedScale:Float = 0.7; // PsychEK的箭头缩放似乎存在问题，尝试使用这个改善

	public var offsetX:Float = 0;
	public var offsetY:Float = 0;
	public var offsetAngle:Float = 0;
	public var multAlpha:Float = 1;
	public var multSpeed(default, set):Float = 1;

	public var copyX:Bool = true;
	public var copyY:Bool = true;
	public var copyAngle:Bool = true;
	public var copyAlpha:Bool = true;

	public var hitHealth:Float = 0.023;
	public var missHealth:Float = 0.0475;
	public var rating:String = 'unknown';
	public var ratingMod:Float = 0; // 9 = unknown, 0.25 = shit, 0.5 = bad, 0.75 = good, 1 = sick
	public var ratingDisabled:Bool = false;

	public var texture(default, set):String = null;
	public var noteSplashTexture:String = null; // just use fix old mods  XD

	public var noAnimation:Bool = false;
	public var noMissAnimation:Bool = false;
	public var hitCausesMiss:Bool = false;
	public var distance:Float = 2000; // plan on doing scroll directions soon -bb

	public var hitsoundDisabled:Bool = false;
	public var hitsoundChartEditor:Bool = true;
	public var hitsound:String = 'hitsound';

	public var noteSplashBrt:Float = 0;
	public var noteSplashSat:Float = 0;
	public var noteSplashHue:Float = 0;

	private function set_multSpeed(value:Float):Float
	{
		resizeByRatio(value / multSpeed);
		multSpeed = value;
		return value;
	}

	public function resizeByRatio(ratio:Float) // haha funny twitter shit
	{
		if (isSustainNote && animation.curAnim != null && !animation.curAnim.name.endsWith('end'))
		{
			scale.y *= ratio;
			updateHitbox();
		}
	}

	private function set_texture(value:String):String
	{
		if (texture != value)
			reloadNote(value);

		texture = value;
		return value;
	}

	public function defaultRGB()
	{
		var mania = 3;
		if (PlayState.SONG != null)
			mania = PlayState.SONG.mania;

		var arr:Array<FlxColor> = ClientPrefs.data.arrowRGB[getIndex(mania, noteData)];
		if (PlayState.isPixelStage)
			arr = ClientPrefs.data.arrowRGBPixel[getIndex(mania, noteData)];

		if (noteData > -1 /*&& noteData <= arr.length*/)
		{
			rgbShader.r = arr[0];
			rgbShader.g = arr[1];
			rgbShader.b = arr[2];
		}
	}

	private function set_noteType(value:String):String
	{
		noteSplashData.texture = PlayState.SONG != null ? PlayState.SONG.splashSkin : 'noteSplashes/noteSplashes';
		defaultRGB();
		if (ClientPrefs.data.noteColorSwap){
		colorSwap.hue = ClientPrefs.data.arrowHSV[noteData % 4][0] / 360;
		colorSwap.saturation = ClientPrefs.data.arrowHSV[noteData % 4][1] / 100;
		colorSwap.brightness = ClientPrefs.data.arrowHSV[noteData % 4][2] / 100;
		}
		if (noteData > -1 && noteType != value)
		{
			switch (value)
			{
				case 'Hurt Note':
					ignoreNote = mustPress;
					// this used to change the note texture to HURTNOTE_assets.png,
					// but i've changed it to something more optimized with the implementation of RGBPalette:

					// note colors
					rgbShader.r = 0xFF101010;
					rgbShader.g = 0xFFFF0000;
					rgbShader.b = 0xFF990022;

					// splash data and colors
					noteSplashData.r = 0xFFFF0000;
					noteSplashData.g = 0xFF101010;
					noteSplashData.texture = 'noteSplashes/noteSplashes-electric';

					// gameplay data
					lowPriority = true;
					missHealth = isSustainNote ? 0.25 : 0.1;
					hitCausesMiss = true;
					hitsound = 'cancelMenu';
					hitsoundChartEditor = false;
				case 'Alt Animation':
					animSuffix = '-alt';
				case 'No Animation':
					noAnimation = true;
					noMissAnimation = true;
				case 'GF Sing':
					gfNote = true;
			}
			if (value != null && value.length > 1)
				NoteTypesConfig.applyNoteTypeData(this, value);
			if (hitsound != 'hitsound' && ClientPrefs.data.hitsoundVolume > 0)
				Paths.sound(hitsound); // precache new sound for being idiot-proof
			noteType = value;
		}
		if (ClientPrefs.data.noteColorSwap){
		noteSplashHue = colorSwap.hue;
		noteSplashSat = colorSwap.saturation;
		noteSplashBrt = colorSwap.brightness;
		}
		return value;
	}

	public function getIndex(mania:Int, note:Int):Int
	{
		return ExtraKeysHandler.instance.data.keys[mania].notes[note];
	}

	public function getAnimSet(index:Int):EKAnimation
	{
		return ExtraKeysHandler.instance.data.animations[index];
	}
	

	public function new(strumTime:Float, noteData:Int, ?prevNote:Note, ?sustainNote:Bool = false, ?inEditor:Bool = false, ?createdFrom:Dynamic = null)
	{
		super();

		if (PlayState.SONG != null)
		{
			trackedScale = ExtraKeysHandler.instance.data.scales[PlayState.SONG.mania];
			if (PlayState.isPixelStage)
			{
				trackedScale = ExtraKeysHandler.instance.data.pixelScales[PlayState.SONG.mania];
			}
		}

		if (ClientPrefs.data.hitsoundType != ClientPrefs.defaultData.hitsoundType)
			hitsound = 'hitsounds/' + ClientPrefs.data.hitsoundType;

		animation = new PsychAnimationController(this);

		antialiasing = ClientPrefs.data.antialiasing;
		if (createdFrom == null)
			createdFrom = PlayState.instance;

		if (prevNote == null)
			prevNote = this;

		this.prevNote = prevNote;
		isSustainNote = sustainNote;
		this.inEditor = inEditor;
		this.moves = false;

		x += (ClientPrefs.data.middleScroll ? PlayState.STRUM_X_MIDDLESCROLL : PlayState.STRUM_X) + 50;
		// MAKE SURE ITS DEFINITELY OFF SCREEN?
		y -= 2000;
		this.strumTime = strumTime;
		if (!inEditor)
			this.strumTime += ClientPrefs.data.noteOffset;

		this.noteData = noteData;

		if (noteData > -1)
		{
			try {
				texture = '';
			} catch (e:Dynamic) {
				trace('Error loading note skin: ' + e);
				//reloadNote();
			}

			rgbShader = new RGBShaderReference(this, initializeGlobalRGBShader(noteData));
			if (PlayState.SONG != null && (PlayState.SONG.disableNoteRGB || !ClientPrefs.data.noteRGB || ClientPrefs.data.noteColorSwap))
				rgbShader.enabled = false;
			if (ClientPrefs.data.noteColorSwap){
			colorSwap = new ColorSwap();
			shader = colorSwap.shader;

			}
			x += swagWidth * (noteData);
			if (!isSustainNote /* && noteData < colArray.length*/)
			{ // Doing this 'if' check to fix the warnings on Senpai songs
				var animToPlay:String = '';
				var mania = 3;
				if (PlayState.SONG != null)
					mania = PlayState.SONG.mania;
				animToPlay = getAnimSet(getIndex(mania, noteData)).note;
				animation.play(animToPlay + 'Scroll');
			}
		}

		if (prevNote != null)
			prevNote.nextNote = this;

		if (isSustainNote && prevNote != null)
		{
			alpha = 0.6;
			multAlpha = 0.6;
			hitsoundDisabled = true;
			if (ClientPrefs.data.downScroll)
				flipY = true;

			offsetX += width / 2;
			//copyAngle = false;

			var mania = 3;
			if (PlayState.SONG != null)
				mania = PlayState.SONG.mania;
			var animToPlay = getAnimSet(getIndex(mania, noteData)).note;
			animation.play(animToPlay + 'holdend');

			updateHitbox();

			offsetX -= width / 2;

			if (PlayState.isPixelStage)
				offsetX += 30;

			if (prevNote.isSustainNote)
			{
				prevNote.animation.play(animToPlay + 'hold');

				prevNote.scale.y *= Conductor.stepCrochet / 100 * 1.05;
				if (createdFrom != null && createdFrom.songSpeed != null)
					prevNote.scale.y *= createdFrom.songSpeed;

				if (PlayState.isPixelStage)
				{
					prevNote.scale.y *= 1.19;
					prevNote.scale.y *= (6 / height); // Auto adjust note size
				}
				prevNote.updateHitbox();
				// prevNote.setGraphicSize();
			}

			if (PlayState.isPixelStage)
			{
				scale.y *= PlayState.daPixelZoom;
				updateHitbox();
			}
		}
		else if (!isSustainNote)
		{
			centerOffsets();
			centerOrigin();
		}
		x += offsetX;
	}

	public static function initializeGlobalRGBShader(noteData:Int)
	{
		if (globalRgbShaders[noteData] == null)
		{
			var newRGB:RGBPalette = new RGBPalette();
			globalRgbShaders[noteData] = newRGB;

			var mania = 3;
			if (PlayState.SONG != null)
				mania = PlayState.SONG.mania;

			var arr:Array<FlxColor> = (!PlayState.isPixelStage) ? ClientPrefs.data.arrowRGB[ExtraKeysHandler.instance.data.keys[mania].notes[noteData]] : ClientPrefs.data.arrowRGBPixel[ExtraKeysHandler.instance.data.keys[mania].notes[noteData]];
			if (noteData > -1 /*&& noteData <= arr.length*/)
			{
				newRGB.r = arr[0];
				newRGB.g = arr[1];
				newRGB.b = arr[2];
			}
		}
		return globalRgbShaders[noteData];
	}

	var _lastNoteOffX:Float = 0;

	public var originalHeight:Float = 6;
	public var correctionOffset:Float = 0; // dont mess with this

	public function reloadNote(texture:String = null, postfix:String = null)
	{
		reloadPath(texture, postfix);

		var lastScaleY:Float = scale.y;

		var animName:String = null;
		if (animation.curAnim != null)
		{
			animName = animation.curAnim.name;
		}

		if (PlayState.isPixelStage)
		{
			skinPixel = skin;

			if (isSustainNote)
			{
				var graphic = Paths.image('pixelUI/' + skinPixel + 'ENDS' + skinPostfix, null, false);
				loadGraphic(graphic, true, Math.floor(graphic.width / 4), Math.floor(graphic.height / 2));
				originalHeight = graphic.height / 2;
			}
			else
			{
				var graphic = Paths.image('pixelUI/' + skinPixel + skinPostfix, null, false);
				loadGraphic(graphic, true, Math.floor(graphic.width / 4), Math.floor(graphic.height / 5));
			}

			var mania = 3;
			if (PlayState.SONG != null)
				mania = PlayState.SONG.mania;
			setGraphicSize((width * (ExtraKeysHandler.instance.data.pixelScales[mania] + 0.3)) * PlayState.daPixelZoom);

			loadPixelNoteAnims();
			antialiasing = false;

			if (isSustainNote)
			{
				offsetX += _lastNoteOffX;
				_lastNoteOffX = (width - 7) * (PlayState.daPixelZoom / 2);
				offsetX -= _lastNoteOffX;
			}
		}
		else
		{
			if (!Cache.checkFrame(skin + skinPostfix)) addSkinCache(skin + skinPostfix);
				
			frames = Cache.getFrame(skin + skinPostfix);

			if (Cache.currentTrackedAnims.get(skin + skinPostfix) != null) {
			    animation.copyFrom(Cache.currentTrackedAnims.get(skin + skinPostfix));
            	setGraphicSize(Std.int(frameWidth * trackedScale));
				updateHitbox();
			}
			else loadNoteAnims();

			if (!isSustainNote)
			{
				centerOffsets();
				centerOrigin();
			}
		}

		if (isSustainNote)
		{
			scale.y = lastScaleY;
		}
		updateHitbox();

		if (animName != null)
			animation.play(animName, true);
	}

	public static var loadedNote:Map<String, {texture:String, postfix:String, skin:String, skinPostfix:String}> = new Map<String, {texture:String, postfix:String, skin:String, skinPostfix:String}>();
	public static final initSkin:String = 'noteSkins/NOTE_assets';
	static var skin:String;
	static var oldMod:Bool = false;
	var skinPixel:String; //像素箭头路径（数据保存形式类似于defaultNoteSkin）
	static var skinPostfix:String = ''; //箭头设置给的后缀

	public static function reloadPath(texture:String = '', postfix:String = '')
	{
		if (texture == null || texture.length < 1)
			texture = defaultNoteSkin;
		if (postfix == null || postfix.length < 1)
			postfix = '';

		var currentKey = getLoadDataKey(texture, postfix);
		if (loadedNote.exists(currentKey)) {
			skin = loadedNote.get(currentKey).skin;
			skinPostfix = loadedNote.get(currentKey).skinPostfix;
			return;
		}

		var pathPixel = PlayState.isPixelStage ? 'pixelUI/' : '';

		skin = texture + postfix;
		if (skin == defaultNoteSkin) //如果是默认箭头路径
		{
			skin = PlayState.SONG != null ? PlayState.SONG.arrowSkin : null; //兼容了铺面json设置的箭头
			if (skin != null && skin.length > 0) {//当发现铺面json的箭头读取没问题时
				if (Paths.fileExists('images/' + skin + '.png', IMAGE)) {
					skinPostfix = ''; //返回为默认贴图
					loadedNote.set(currentKey, {texture: texture, postfix: postfix, skin: skin, skinPostfix: skinPostfix});
					return; //直接跳过后续读取,获取为铺面json的路径
				} 
			}
			skin = defaultNoteSkin;
		}

		skinPostfix = getNoteSkinPostfix(skin);

		if (!Paths.fileExists('images/' + pathPixel + skin + skinPostfix + '.png', IMAGE)) {
			skinPostfix = '';
		}

		loadedNote.set(currentKey, {texture: texture, postfix: postfix, skin: skin, skinPostfix: skinPostfix});
	}

	public static function getNoteSkinPostfix(?texture:String = ''):String
	{
		if (texture == '') texture = defaultNoteSkin;
		var skin:String = '';
		if (ClientPrefs.data.noteSkin != ClientPrefs.defaultData.noteSkin && texture == initSkin)
			skin = '-' + ClientPrefs.data.noteSkin.trim().toLowerCase().replace(' ', '_');
		return skin;
	}

	public static function getLoadDataKey(texture:String, postfix:String):String
	{
		return '${texture}::${postfix}';
	}

	function loadNoteAnims()
	{
		var mania = 3;
		if (PlayState.SONG != null)
			mania = PlayState.SONG.mania;
		var noteAnim = getAnimSet(getIndex(mania, noteData)).note;

		if (isSustainNote)
		{
			attemptToAddAnimationByPrefix('purpleholdend', 'pruple end hold', 24, true); // this fixes some retarded typo from the original note .FLA
			animation.addByPrefix(noteAnim + 'holdend', noteAnim + ' hold end', 24, true);
			animation.addByPrefix(noteAnim + 'hold', noteAnim + ' hold piece', 24, true);
		}
		else
			animation.addByPrefix(noteAnim + 'Scroll', noteAnim + '0');

		//setGraphicSize(width * ExtraKeysHandler.instance.data.scales[mania]);
		// trace(width, ExtraKeysHandler.instance.data.scales[mania]);
		
		// 改为使用trackedScale设置大小
		setGraphicSize(Std.int(frameWidth * trackedScale));

		updateHitbox();
	}

	function loadPixelNoteAnims()
	{
		var mania = 3;
		if (PlayState.SONG != null)
			mania = PlayState.SONG.mania;
		var noteAnimStr = getAnimSet(getIndex(mania, noteData)).note;
		var noteAnimInt = getAnimSet(getIndex(mania, noteData)).pixel;

		if (isSustainNote)
		{
			animation.add(noteAnimStr + 'holdend', [noteAnimInt + 4], 24, true);
			animation.add(noteAnimStr + 'hold', [noteAnimInt], 24, true);
		}
		else
			animation.add(noteAnimStr + 'Scroll', [noteAnimInt + 4], 24, true);
	}

	function attemptToAddAnimationByPrefix(name:String, prefix:String, framerate:Float = 24, doLoop:Bool = true)
	{
		var animFrames = [];
		@:privateAccess
		animation.findByPrefix(animFrames, prefix); // adds valid frames to animFrames
		if (animFrames.length < 1)
			return;

		animation.addByPrefix(name, prefix, framerate, doLoop);
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (mustPress)
		{
			if (!ClientPrefs.data.playOpponent)
			{
				canBeHit = (strumTime > Conductor.songPosition - (Conductor.safeZoneOffset * lateHitMult)
					&& strumTime < Conductor.songPosition + (Conductor.safeZoneOffset * earlyHitMult));

				if (strumTime < Conductor.songPosition - Conductor.safeZoneOffset && !wasGoodHit)
					tooLate = true;
			}
			else
			{
				canBeHit = false;

				if (strumTime < Conductor.songPosition + (Conductor.safeZoneOffset * earlyHitMult))
				{
					if ((isSustainNote && prevNote.wasGoodHit) || strumTime <= Conductor.songPosition)
						wasGoodHit = true;
				}
			}
		}
		else
		{
			if (ClientPrefs.data.playOpponent)
			{
				canBeHit = (strumTime > Conductor.songPosition - (Conductor.safeZoneOffset * lateHitMult)
					&& strumTime < Conductor.songPosition + (Conductor.safeZoneOffset * earlyHitMult));

				if (strumTime < Conductor.songPosition - Conductor.safeZoneOffset && !wasGoodHit)
					tooLate = true;
			}
			else
			{
				canBeHit = false;

				if (strumTime < Conductor.songPosition + (Conductor.safeZoneOffset * earlyHitMult))
				{
					if ((isSustainNote && prevNote.wasGoodHit) || strumTime <= Conductor.songPosition)
						wasGoodHit = true;
				}
			}
		}
	}

	override public function destroy()
	{
		super.destroy();
	}

	public function followStrumNote(myStrum:StrumNote, fakeCrochet:Float, songSpeed:Float = 1)
	{
		if (!FlxG.isFullFrame) return;

		var mania = 3;
		if (PlayState.SONG != null)	mania = PlayState.SONG.mania;
		var Mscale = ExtraKeysHandler.instance.data.scales[mania];
		if (PlayState.isPixelStage) Mscale = ExtraKeysHandler.instance.data.pixelScales[mania];
		var sWidth = Note.swagWidthUnscaled * Mscale;

		var strumX:Float = myStrum.x;
		var strumY:Float = myStrum.y;
		var strumAngle:Float = myStrum.angle;
		var strumAlpha:Float = myStrum.alpha;
		var strumDirection:Float = myStrum.direction;

		distance = (0.45 * (Conductor.songPosition - strumTime) * songSpeed * multSpeed);
		if (!myStrum.downScroll)
			distance *= -1;

		var angleDir = strumDirection * Math.PI / 180;
		if (copyAngle) {
			if (!isSustainNote)
				angle = strumDirection - 90 + strumAngle + offsetAngle;
			else
				angle = strumDirection - 90 + offsetAngle;
		}

		if (copyAlpha)
			alpha = strumAlpha * multAlpha;

		if (copyX)
			x = strumX + offsetX + Math.cos(angleDir) * distance;

		if (copyY)
		{
			y = strumY + offsetY + correctionOffset + Math.sin(angleDir) * distance;
			if (myStrum.downScroll && isSustainNote)
			{
				if (PlayState.isPixelStage)
				{
					y -= PlayState.daPixelZoom * 9.5;
				}
				y -= (frameHeight * scale.y) - (sWidth / 2);
			}
		}
	}

	public function clipToStrumNote(myStrum:StrumNote)
	{
		if (!FlxG.isFullFrame) return;

		var mania = 3;
		if (PlayState.SONG != null)
			mania = PlayState.SONG.mania;
		var Mscale = ExtraKeysHandler.instance.data.scales[mania];
		if (PlayState.isPixelStage)
			Mscale = ExtraKeysHandler.instance.data.pixelScales[mania];

		var sWidth = Note.swagWidthUnscaled * Mscale;

		if (isSustainNote && (mustPress || !ignoreNote) && (!mustPress || (wasGoodHit || (prevNote.wasGoodHit && !canBeHit))))
		{
			var swagRect:FlxRect = clipRect;
			if (swagRect == null) swagRect = FlxRect.get(0, 0, frameWidth, frameHeight);
			
			var time:Float = FlxMath.bound((Conductor.songPosition - strumTime) / (swagRect.height * scale.y / (0.45 * FlxMath.roundDecimal(follow.songSpeed, 2))), 0, 1);
			if (time >= 1) {
				follow.invalidateNote(this);
				return;
			}

			swagRect.x = 0;
			swagRect.y = time * frameHeight;
			swagRect.width = frameWidth;
			swagRect.height = frameHeight;

			clipRect = swagRect;
		}
	}

	public function hitMultUpdate(number:Int = 0, maxNumber:Int = 0)
	{
		if (number == 0)
		{
			earlyHitMult = 0;
			lateHitMult = 1; // 写1而不是0.5是用于修复长条先miss问题
		}
		else if (number == maxNumber)
		{
			earlyHitMult = 0.75;
			lateHitMult = 0.25;
			noAnimation = true; // better anim play
		}
		else
		{
			earlyHitMult = 0.5;
			lateHitMult = 0.75;
		}
	} // this shit can make hold note work better

	@:noCompletion
	override function set_clipRect(rect:FlxRect):FlxRect
	{
		clipRect = rect;

		if (frames != null)
			frame = frames.frames[animation.frameIndex];

		return rect;
	}

	public static function init(target:Dynamic = null)
	{
		loadedNote = new Map<String, {texture:String, postfix:String, skin:String, skinPostfix:String}>();

		if (FileSystem.exists(Paths.mods(Mods.currentModDirectory + '/images/NOTE_assets.png')) && ClientPrefs.data.noteSkin == ClientPrefs.defaultData.noteSkin) {
			defaultNoteSkin = 'NOTE_assets';
			oldMod = true;
			reloadPath(defaultNoteSkin,'');
		} else {
			defaultNoteSkin = initSkin;
			oldMod = false;
			reloadPath(defaultNoteSkin);
		}

		addSkinCache(skin + skinPostfix);

		if (target != null) {
			follow = target;
		}
	}

	static function addSkinCache(skin:String)
	{
		//trace('add skin cache: ' + skin);
		var spr:FlxSprite = new FlxSprite();
		spr.frames = Paths.getSparrowAtlas(skin, null, false);

		for (data in 0...colArray.length)
		{
			if (data == 0) spr.animation.addByPrefix('purpleholdend', 'pruple end hold');
			spr.animation.addByPrefix(Note.colArray[data] + 'holdend', Note.colArray[data] + ' hold end');
			spr.animation.addByPrefix(Note.colArray[data] + 'hold', Note.colArray[data] + ' hold piece');
			spr.animation.addByPrefix(Note.colArray[data] + 'Scroll', Note.colArray[data] + '0');
		}
		Cache.setFrame(skin, {graphic:null, frame:spr.frames});
		Cache.currentTrackedAnims.set(skin, spr.animation);
	}
}

