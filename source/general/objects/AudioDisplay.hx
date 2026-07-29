package general.objects;

import openfl.geom.Rectangle;
import funkin.vis.dsp.SpectralAnalyzer;
import funkin.vis.dsp.SpectralAnalyzer.Bar;
import lime.media.AudioBuffer;
import lime.media.AudioSource;

/**
 * Main-menu spectrum rendered as one cached sprite texture.
 *
 * The previous implementation created and submitted one FlxSprite per bar.
 * The first batched implementation still rebuilt and copied hundreds of
 * triangle values on every game frame.  At uncapped frame rates that work was
 * considerably more expensive than the rest of the menu.  This version keeps
 * all 100 bars, but rasterizes them into a private, moderately sized texture at
 * a visual refresh rate.  Normal frames only submit one cached sprite quad.
 */
class AudioDisplay extends FlxSprite
{
	var analyzer:SpectralAnalyzer;
	var boundAudioSource:AudioSource;
	var externalAudioSource:AudioSource;
	var externalAudioBuffer:AudioBuffer;
	var useExternalAudioSource:Bool = false;

	public var snd:FlxSound;
	public var symmetry:Bool = false;
	public var stopUpdate:Bool = false;
	public var amplitude:Float = 0;

	var line:Int;
	var displayWidth:Int;
	var displayHeight:Int;
	var bitmapWidth:Int;
	var bitmapHeight:Int;
	var barStep:Float;
	var barWidth:Float;
	var barHeights:Array<Float> = [];
	var barColor:FlxColor;
	var drawRect:Rectangle = new Rectangle();
	var saveTime:Float = 0;
	var motionTime:Float = 0;
	var getValues:Array<Bar>;

	static inline final MAX_VISUAL_RATE:Float = 120;
	static inline final MAX_BITMAP_WIDTH:Int = 512;

	public function new(snd:FlxSound = null, X:Float = 0, Y:Float = 0,
		Width:Int, Height:Int, line:Int, gap:Int, Color:FlxColor,
		symmetry:Bool = false)
	{
		super(X, Y);

		this.snd = snd;
		this.line = Std.int(Math.max(1, line));
		this.symmetry = symmetry;
		displayWidth = Width;
		displayHeight = Height;
		barColor = Color;

		// The texture is deliberately smaller than the display.  Spectrum bars
		// do not contain fine detail, and scaling this bitmap saves both CPU
		// raster work and GPU upload bandwidth when its shape changes.
		bitmapWidth = Std.int(Math.min(MAX_BITMAP_WIDTH, Math.max(1, Width)));
		bitmapHeight = Std.int(Math.max(1, Math.ceil(Height * bitmapWidth / Width)));
		barStep = bitmapWidth / this.line;
		barWidth = Math.max(1, barStep - gap * bitmapWidth / Width);

		makeGraphic(bitmapWidth, bitmapHeight, FlxColor.TRANSPARENT, true);
		setGraphicSize(displayWidth, displayHeight);
		updateHitbox();
		x = X;
		y = Y - displayHeight;
		buildBars();
		rasterizeBars();

		refreshAnalyzerBinding();
	}

	function buildBars():Void
	{
		final minimum = bitmapHeight / 40;
		for (i in 0...line)
			barHeights.push(minimum);
	}

	override function update(elapsed:Float):Void
	{
		// FlxSound.loadStream() disposes the old SoundChannel before installing
		// the next one. Never let the analyzer retain that disposed AudioSource.
		refreshAnalyzerBinding();

		if (stopUpdate)
			return;

		saveTime += elapsed * 1000;
		motionTime += elapsed;
		final sampleInterval = Math.max(1000 / MAX_VISUAL_RATE,
			ClientPrefs.data.audioDisplayUpdate);
		if (analyzer != null && boundAudioSource != null && saveTime >= sampleInterval)
		{
			saveTime %= sampleInterval;
			// Reuse both the level array and its Bar records. Passing null here
			// rebuilt roughly one hundred managed records on every FFT sample and
			// needlessly drove a Young collection every few seconds.
			try
			{
				getValues = analyzer.getLevels(getValues);
				updateAmplitude();
			}
			catch (e:Dynamic)
			{
				// A stream can be released between the channel check above and
				// the typed-array slice inside funkin.vis. Drop the stale source;
				// a later update will bind the replacement channel if it has one.
				invalidateAnalyzerBinding();
			}
		}

		// Visual data only needs display-rate interpolation.  The engine frame
		// loop remains uncapped, while intermediate frames reuse the texture.
		if (getValues != null && motionTime >= 1 / MAX_VISUAL_RATE)
		{
			updateLine(motionTime);
			motionTime = 0;
		}
	}

	function updateAmplitude():Void
	{
		final count = Std.int(Math.min(5, getValues.length));
		if (count == 0)
		{
			amplitude = 0;
			return;
		}

		var total:Float = 0;
		for (i in 0...count)
			total += getValues[i].value;
		amplitude = total / count;
	}

	function getCurrentAudioSource():AudioSource
	{
		if (useExternalAudioSource)
			return externalAudioSource;

		var source:AudioSource = null;
		@:privateAccess
		if (snd != null && snd._channel != null && snd._channel.__audioSource != null)
		{
			var candidate:AudioSource = snd._channel.__audioSource;
			if (candidate.buffer != null && candidate.buffer.data != null
				&& candidate.buffer.data.length > 0)
				source = candidate;
		}
		return source;
	}

	function refreshAnalyzerBinding():Void
	{
		var source = getCurrentAudioSource();
		if (source == boundAudioSource)
			return;

		getValues = null;
		amplitude = 0;
		saveTime = 0;
		motionTime = 0;
		clearUpdate();

		if (source == null)
		{
			if (analyzer != null)
				analyzer.changeSnd(null);
			boundAudioSource = null;
			return;
		}

		if (analyzer == null)
		{
			analyzer = new SpectralAnalyzer(source,
				Std.int(line + Math.abs(0.05 *
					(4 - ClientPrefs.data.audioDisplayQuality))), 1, 5);
			analyzer.fftN = 256 * ClientPrefs.data.audioDisplayQuality;
		}
		else
			analyzer.changeSnd(source);
		boundAudioSource = source;
	}

	function invalidateAnalyzerBinding():Void
	{
		if (analyzer != null)
			analyzer.changeSnd(null);
		boundAudioSource = null;
		getValues = null;
		amplitude = 0;
		clearUpdate();
	}

	function releaseExternalAudioBuffer():Void
	{
		if (externalAudioSource != null)
		{
			externalAudioSource.dispose();
			externalAudioSource = null;
		}
		if (externalAudioBuffer != null)
		{
			externalAudioBuffer.dispose();
			externalAudioBuffer = null;
		}
	}

	function updateLine(elapsed:Float):Void
	{
		if (getValues == null || getValues.length == 0)
			return;

		final minimum = bitmapHeight / 40;
		final blend = Math.exp(-elapsed * 16);
		final volume = FlxG.sound.volume;
		for (i in 0...line)
		{
			var valueIndex = symmetry && i >= line / 2 ? line - 1 - i : i;
			if (valueIndex >= getValues.length)
				valueIndex = getValues.length - 1;
			final target = Math.round(
				getValues[valueIndex].value * bitmapHeight * volume);
			final height = Math.max(minimum,
				FlxMath.lerp(target, barHeights[i], blend));
			barHeights[i] = height;
		}
		rasterizeBars();
	}

	function rasterizeBars():Void
	{
		final bitmap = pixels;
		if (bitmap == null)
			return;

		bitmap.lock();
		bitmap.fillRect(bitmap.rect, FlxColor.TRANSPARENT);
		for (i in 0...line)
		{
			final x0 = Std.int(barStep * i);
			final x1 = Std.int(Math.min(bitmapWidth, Math.ceil(barStep * i + barWidth)));
			final height = Std.int(Math.min(bitmapHeight, Math.ceil(barHeights[i])));
			drawRect.setTo(x0, bitmapHeight - height, Math.max(1, x1 - x0), height);
			bitmap.fillRect(drawRect, barColor);
		}
		bitmap.unlock();
		dirty = true;
	}

	public function changeAnalyzer(snd:FlxSound):Void
	{
		invalidateAnalyzerBinding();
		releaseExternalAudioBuffer();
		useExternalAudioSource = false;
		this.snd = snd;
		refreshAnalyzerBinding();
		stopUpdate = false;
	}

	/**
	 * Supplies decoded PCM for players such as hxvlc whose placeholder
	 * SoundChannel does not expose a Lime AudioSource. The buffer is used only
	 * for FFT sampling; playback time still comes from FlxG.sound.music.
	 */
	public function changeAudioBuffer(buffer:AudioBuffer):Void
	{
		invalidateAnalyzerBinding();
		releaseExternalAudioBuffer();
		useExternalAudioSource = true;

		if (buffer != null && buffer.data != null && buffer.data.length > 0)
		{
			externalAudioBuffer = buffer;
			// Construct the backend without a buffer so the analysis copy is not
			// uploaded to OpenAL or played a second time.
			externalAudioSource = new AudioSource();
			externalAudioSource.buffer = buffer;
		}

		refreshAnalyzerBinding();
		stopUpdate = false;
	}

	public function clearUpdate():Void
	{
		final minimum = bitmapHeight / 40;
		for (i in 0...line)
			barHeights[i] = minimum;
		rasterizeBars();
	}

	override public function destroy():Void
	{
		if (analyzer != null)
			analyzer.changeSnd(null);
		releaseExternalAudioBuffer();
		analyzer = null;
		boundAudioSource = null;
		getValues = null;
		snd = null;
		super.destroy();
	}
}
