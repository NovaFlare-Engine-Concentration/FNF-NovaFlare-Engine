package codename.funkin.backend.system.framerate;

import flixel.math.FlxPoint;
import openfl.display.Bitmap;
import openfl.display.BitmapData;
import openfl.display.DisplayObject;
import openfl.display.Sprite;
import openfl.events.KeyboardEvent;
import openfl.text.TextFormat;
import openfl.ui.Keyboard;
#if ios
import flixel.util.FlxTimer;
#end

class Framerate extends Sprite {
	public static var instance:Framerate;
	public static var isLoaded:Bool = false;

	public static var textFormat:TextFormat;
	public static var fpsCounter:FramerateCounter;
	public static var memoryCounter:MemoryCounter;
	#if SHOW_BUILD_ON_FPS
	public static var codenameBuildField:CodenameBuildField;
	#end

	public static var defaultFontName(default, never):String = #if windows '${Sys.getEnv("windir")}\\Fonts\\consola.ttf' #else "_typewriter" #end;

	public static var fontName:String = defaultFontName;

	/**
	 * 0: FPS INVISIBLE
	 * 1: FPS VISIBLE
	 * 2: FPS & DEBUG INFO VISIBLE
	 */
	public static var debugMode:Int = 1;
	public static var offset:FlxPoint = new FlxPoint();

	public var bgSprite:Bitmap;

	public var categories:Array<FramerateCategory> = [];

	@:isVar public static var __bitmap(get, null):BitmapData = null;

	private static function get___bitmap():BitmapData {
		if (__bitmap == null)
			__bitmap = new BitmapData(1, 1, 0xFF000000);
		return __bitmap;
	}

	#if android
	var backTapCount:Int = 0;
	var backTapExpiresAt:Float = 0;
	#end
	#if ios
	public var sillyTimer:FlxTimer = new FlxTimer();
	#end

	public function new() {
		super();
		if (instance != null) throw "Cannot create another instance";
		instance = this;
		textFormat = new TextFormat(fontName, 12, -1);

		isLoaded = true;

		x = 10;
		y = 2;

		if (__bitmap == null)
			__bitmap = new BitmapData(1, 1, 0xFF000000);

		bgSprite = new Bitmap(__bitmap);
		bgSprite.alpha = 0;
		addChild(bgSprite);

		__addToList(fpsCounter = new FramerateCounter());
		__addToList(memoryCounter = new MemoryCounter());
		#if SHOW_BUILD_ON_FPS
		__addToList(codenameBuildField = new CodenameBuildField());
		#end
		__addCategory(new ConductorInfo());
		__addCategory(new FlixelInfo());
		__addCategory(new SystemInfo());
		__addCategory(new AssetTreeInfo());

		#if (gl_stats && !disable_cffi && (!html5 || !canvas))
		__addCategory(new StatsInfo());
		#end
	}

	public function reload() {
		for(c in categories)
			c.reload();

		#if SHOW_BUILD_ON_FPS
		codenameBuildField.reload();
		#end
		memoryCounter.reload();
		fpsCounter.reload();
	}

	private function __addCategory(category:FramerateCategory) {
		categories.push(category);
		__addToList(category);
	}
	private var __lastAddedSprite:DisplayObject = null;
	private function __addToList(spr:DisplayObject) {
		spr.x = 0;
		spr.y = __lastAddedSprite != null ? (__lastAddedSprite.y + __lastAddedSprite.height) : 4;
		//spr.y += offset.y;
		__lastAddedSprite = spr;
		addChild(spr);
	}


	var debugAlpha:Float = 0;
	public override function __enterFrame(t:Float) {
		alpha = CoolUtil.fpsLerp(alpha, debugMode > 0 ? 1 : 0, 0.5);
		debugAlpha = CoolUtil.fpsLerp(debugAlpha, debugMode > 1 ? 1 : 0, 0.5);
		#if android
		if (FlxG.android.justReleased.BACK) {
			var now = haxe.Timer.stamp();
			if (now > backTapExpiresAt) backTapCount = 0;
			backTapExpiresAt = now + 0.45;
			if (++backTapCount == 3) {
				backTapCount = 0;
				backTapExpiresAt = 0;
				cycleDebugMode();
				return;
			}
		}
		#elseif ios
		for (camera in FlxG.cameras.list) {
			var pos = FlxG.mouse.getScreenPosition(camera);
			if (pos.x >= FlxG.game.x + 10 + offset.x && pos.x <= FlxG.game.x + offset.x + 80
				&& pos.y >= FlxG.game.y + 2 + offset.y && pos.y <= FlxG.game.y + 2 + offset.y + 60) {
				if (FlxG.mouse.justPressed)
					sillyTimer.start(0.4, (timer:FlxTimer) -> debugMode = (debugMode + 1) % 3);
				if (FlxG.mouse.justReleased) sillyTimer.cancel();
			} else if (sillyTimer.active && !sillyTimer.finished) sillyTimer.cancel();
		}
		#end

		if (alpha < 0.05) return;
		super.__enterFrame(t);
		bgSprite.alpha = debugAlpha * 0.5;

		x = #if mobile FlxG.game.x + #end 10 + offset.x * FlxG.scaleMode.scale.x;
		y = #if mobile FlxG.game.y + #end 2 + offset.y * FlxG.scaleMode.scale.y;

		var width = MathUtil.maxSmart(fpsCounter.width, memoryCounter.width #if SHOW_BUILD_ON_FPS , codenameBuildField.width #end) + (x*2);
		var height = #if SHOW_BUILD_ON_FPS codenameBuildField.y + codenameBuildField.height #else memoryCounter.y + memoryCounter.height #end;
		bgSprite.x = -x;
		bgSprite.y = offset.x;
		bgSprite.scaleX = width;
		bgSprite.scaleY = height;

		var selectable = debugMode == 2;
		{  // idk i tried to make it more readable:sob:  - Nex
			memoryCounter.memoryText.selectable = memoryCounter.memoryPeakText.selectable =
			fpsCounter.fpsNum.selectable = fpsCounter.fpsLabel.selectable =
			#if SHOW_BUILD_ON_FPS codenameBuildField.selectable = #end selectable;
		}

		var y:Float = height + 4;
		for(c in categories) {
			c.title.selectable = c.text.selectable = selectable;
			c.alpha = debugAlpha;
			c.x = FlxMath.lerp(-c.width - offset.x, 0, debugAlpha);
			c.y = y;
			y = c.y + c.height + 4;
		}
	}

	inline function cycleDebugMode():Void
		debugMode = (debugMode + 1) % 3;

	#if mobile
	public inline function setScale(?scale:Float):Void {
		// Framerate is a sibling of FlxGame, so it needs FlxGame's scale in the
		// current OpenFL Stage coordinate space. Using the physical Lime window
		// size here applies NovaFlare's logical Stage scale a second time.
		if (scale == null) {
			var stageWidth = FlxG.stage.stageWidth;
			var stageHeight = FlxG.stage.stageHeight;
			scale = stageWidth > 0 && stageHeight > 0
				? Math.min(stageWidth / FlxG.width, stageHeight / FlxG.height)
				: (FlxG.game != null ? Math.min(FlxG.game.scaleX, FlxG.game.scaleY) : 1);
		}
		scaleX = scaleY = scale;
	}
	#end
}
