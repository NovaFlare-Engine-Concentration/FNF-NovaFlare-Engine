package developer.display;

#if sys
import sys.thread.Mutex;
import sys.thread.Thread;
#end

class DataCalc
{
	#if sys
	static var perfTraceEnabled:Bool = Sys.getEnv("NOVAGC_PERF_TRACE") != null;
	#else
	static var perfTraceEnabled:Bool = false;
	#end
	static var perfTraceTime:Float = 0;

	static public var updateFPS:Float = 0;
	static public var updateFrameTime:Float = 0;

	static public var appMem:Float = 0;
	static public var gcMem:Float = 0;

	static public var drawFPS:Float = 0;
	static public var drawFrameTime:Float = 0;

	/////////////////////////////////////////

	static public var updateTimeSave:Float = 0;
	static public var updateMember:Float = 0;
	static var updateInitialized:Bool = false;
	static var memoryTimeSave:Float = 0;
	#if sys
	static var memorySampleMutex:Mutex = new Mutex();
	static var memorySampleThread:Thread;
	static var memorySamplePending:Bool = false;
	static var memorySampleReady:Bool = false;
	static var memorySampleApp:Float = 0;
	static var memorySampleGc:Float = 0;
	#end

	static public function update()
	{
		updateMember++;

		var time = Lib.getTimer();
		var stamp = haxe.Timer.stamp() * 1000;
		if (updateLastStamp > 0)
		{
			var frameDelta = stamp - updateLastStamp;
			if (frameDelta > updateWorstSample)
				updateWorstSample = frameDelta;
		}
		updateLastStamp = stamp;
		// The first update can arrive after asset loading has taken many
		// seconds. Treat it as the clock origin instead of averaging that load
		// time into live TPS for the next several minutes.
		if (!updateInitialized)
		{
			updateInitialized = true;
			updateTimeSave = time;
			updateLowTime = time;
			updateMember = 0;
			return;
		}
		if (time - updateLowTime >= 1000)
		{
			updateWorstFrameTime = updateWorstSample;
			updateLowFPS = updateWorstSample > 0
				? Math.floor(1000 / updateWorstSample + 0.5)
				: updateFPS;
			updateWorstSample = 0;
			updateLowTime = time;
		}
		if (time - updateTimeSave < 100)
			return;

		var updateWait:Float = time - updateTimeSave;
		var currentMember:Float = updateMember;
		var targetFramerate:Int = ClientPrefs.data.framerate;

		updateTimeSave = time;
		updateMember = 0;
		/////////////////// →更新
		// Report the real 100 ms throughput window. The previous 90% smoothing
		// hid a 100+ ms stop-the-world hitch behind a still-high number for
		// several seconds, which made the counter visibly disagree with motion.
		updateFrameTime = updateWait / currentMember;

		var newFPS = Math.floor(1000 / updateFrameTime + 0.5);
		if (newFPS > targetFramerate)
			newFPS = targetFramerate;
		
		updateFPS = newFPS;

		/////////////////// →fps计算

		// Flixel keeps reseting this to 60 on focus gained
		//if (FlxG.stage.window.frameRate != ClientPrefs.data.framerate && FlxG.stage.window.frameRate != FlxG.game.focusLostFramerate) {
		//	FlxG.stage.window.frameRate = ClientPrefs.data.framerate;
		//}

		updateMemorySample(time);

		if (perfTraceEnabled && time - perfTraceTime >= 1000)
		{
			perfTraceTime = time;
			var wallTimeMs:Float = Date.now().getTime();
			Sys.println('frame:time_ms=${time} update_fps=${updateFPS} draw_fps=${drawFPS} update_low_fps=${updateLowFPS} draw_low_fps=${drawLowFPS} update_ms=${updateFrameTime} draw_ms=${drawFrameTime} update_worst_ms=${updateWorstFrameTime} draw_worst_ms=${drawWorstFrameTime} app_mb=${appMem} gc_mb=${gcMem} wall_time_ms=${wallTimeMs}');
		}

		/////////////////// →memory计算

		////////////////// 数据初始化
	}

	/**
	 * Heap statistics need a consistent NovaGC region snapshot. Large asset
	 * sets can contain thousands of regions, so taking that snapshot on the
	 * stage/update thread creates a visible one-second hitch. Keep the same
	 * 1 Hz display accuracy, but let one persistent worker take the snapshot
	 * and only publish its completed result from the main thread.
	 */
	static function updateMemorySample(time:Float):Void
	{
		#if sys
		var worker:Thread = null;
		memorySampleMutex.acquire();
		if (memorySampleReady)
		{
			appMem = memorySampleApp;
			gcMem = memorySampleGc;
			memorySampleReady = false;
		}

		if (!memorySamplePending &&
			(memoryTimeSave == 0 || time - memoryTimeSave >= 1000))
		{
			memoryTimeSave = time;
			memorySamplePending = true;
			if (memorySampleThread == null)
				memorySampleThread = Thread.create(memorySampleWorker);
			worker = memorySampleThread;
		}
		memorySampleMutex.release();

		if (worker != null)
			worker.sendMessage(true);
		#else
		if (memoryTimeSave == 0 || time - memoryTimeSave >= 1000)
		{
			memoryTimeSave = time;
			appMem = getAppMem();
			gcMem = getGcMem();
		}
		#end
	}

	#if sys
	static function memorySampleWorker():Void
	{
		while (true)
		{
			Thread.readMessage(true);
			var nextApp = getAppMem();
			var nextGc = getGcMem();

			memorySampleMutex.acquire();
			memorySampleApp = nextApp;
			memorySampleGc = nextGc;
			memorySampleReady = true;
			memorySamplePending = false;
			memorySampleMutex.release();
		}
	}
	#end

	static public var drawTimeSave:Float = 0;
	static public var drawCount:Float = 0;
	static var drawInitialized:Bool = false;

	// Keep the six legacy FPS/memory statics above contiguous. The external
	// first-frame sampler deliberately reads that stable block without calling
	// into the game process. New hitch telemetry lives after the legacy block.
	static public var updateLowFPS:Float = 0;
	static public var updateWorstFrameTime:Float = 0;
	static var updateLastStamp:Float = 0;
	static var updateWorstSample:Float = 0;
	static var updateLowTime:Float = 0;
	static public var drawLowFPS:Float = 0;
	static public var drawWorstFrameTime:Float = 0;
	static var drawLastStamp:Float = 0;
	static var drawWorstSample:Float = 0;
	static var drawLowTime:Float = 0;

	static public function draw()
	{
		drawCount++;
		
		var time = Lib.getTimer();
		var stamp = haxe.Timer.stamp() * 1000;
		if (drawLastStamp > 0)
		{
			var frameDelta = stamp - drawLastStamp;
			if (frameDelta > drawWorstSample)
				drawWorstSample = frameDelta;
		}
		drawLastStamp = stamp;
		if (!drawInitialized)
		{
			drawInitialized = true;
			drawTimeSave = time;
			drawLowTime = time;
			drawCount = 0;
			return;
		}
		if (time - drawLowTime >= 1000)
		{
			drawWorstFrameTime = drawWorstSample;
			drawLowFPS = drawWorstSample > 0
				? Math.floor(1000 / drawWorstSample + 0.5)
				: drawFPS;
			drawWorstSample = 0;
			drawLowTime = time;
		}
		if (time - drawTimeSave < 100)
			return;
		
		var drawWait:Float = time - drawTimeSave;
		var currentCount:Float = drawCount;
		var lockRender:Bool = ClientPrefs.data.lockRender;
		var drawFramerate:Int = ClientPrefs.data.drawFramerate;
		var framerate:Int = ClientPrefs.data.framerate;

		drawTimeSave = time;
		drawCount = 0;

		/////////////////// →更新
		drawFrameTime = drawWait / currentCount;

		var newFPS = Math.floor(1000 / drawFrameTime + 0.5);
		if (lockRender) {
			if (newFPS > drawFramerate) {
				newFPS = drawFramerate;
			}
		} else {
			if (newFPS > framerate) {
				newFPS = framerate;
			}
		}
		drawFPS = newFPS;

		////////////////////////////// 数据初始化
	}

	static public function getAppMem():Float
	{
		#if hxcpp_zgc
		return FlxMath.roundDecimal(Gc.memInfo64(8) / 1024 / 1024, 2);
		#else
		return FlxMath.roundDecimal(Gc.memInfo64(4) / 1024 / 1024, 2);
		#end
	}

	static function getCommittedGcMem():Float
	{
		return FlxMath.roundDecimal(Gc.memInfo64(4) / 1024 / 1024, 2); //转化为MB
	}

	static public function getGcMem():Float
	{
		return FlxMath.roundDecimal(Gc.memInfo64(2) / 1024 / 1024, 2);
	}

	static function getLargeGcMem():Float
	{
		return FlxMath.roundDecimal(Gc.memInfo64(3) / 1024 / 1024, 2); //转化为MB
	}
}

class Display
{
	static public function fix(data:Float, decimal:Int):String
	{
		var returnString:String = '';
		var zeros:String= '';

		for (i in 0...decimal)
			zeros += '0';

		if (data % 1 == 0)
			returnString = Std.string(data) + '.' + zeros;
		else
			returnString = Std.string(data);

		return returnString;
	}
}

class ColorReturn
{
	static public function transfer(data:Float, maxData:Float):FlxColor
	{
		var red = 0;
		var green = 0;
		var blue = 126;

		if (data < maxData / 2)
		{
			red = 255;
			green = Std.int(255 * data / maxData * 2);
		}
		else
		{
			red = Std.int(255 * (maxData - data) / maxData * 2);
			green = 255;
		}

		return FlxColor.fromRGB(red, green, blue, 255);
	}
}
