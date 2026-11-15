package codename.funkin.backend.utils;

import flixel.sound.FlxSound;
import lime.media.AudioBuffer;
import sys.thread.Mutex;
import lime.utils.ArrayBufferView.ArrayBufferIO;
import lime.utils.ArrayBuffer;

#if (lime_cffi && lime_vorbis)
import lime.media.vorbis.Vorbis;
import lime.media.vorbis.VorbisFile;
#end

#if (target.threaded)
import sys.thread.Mutex;
#end

typedef AudioAnalyzerCallback = Int->Int->Void;
typedef WindowFunction = Float->Float;

/**
 * An utility that analyze FlxSounds,
 * can be used to make waveform or real-time audio visualizer.
 * 
 * FlxSound.amplitude works so if any case if your only checking for peak of current time, use that instead.
 */
@:allow(codename.funkin.backend.utils.AudioAnalyzer)
final class WindowFunctions {
	static inline final TWO_PI:Float = 6.283185307179586;
	static inline final FOUR_PI:Float = 12.566370614359172;
	static inline final SIX_PI:Float = 18.84955592153876;
	static inline final EIGHT_PI:Float = 25.132741228718345;

	public static inline function triangular(x:Float):Float
		return 1.0 - Math.abs(x - 0.5) * 2.0;

	public static inline function hann(x:Float):Float
		return 0.5 - 0.5 * Math.cos(TWO_PI * x);

	public static inline function hamming(x:Float):Float
		return 0.53836 - 0.46164 * Math.cos(TWO_PI * x);

	public static inline function blackmanNuttall(x:Float):Float
		return 0.3635819 - 0.4891775 * Math.cos(TWO_PI * x) + 0.1365995 * Math.cos(FOUR_PI * x)
			- 0.0106411 * Math.cos(SIX_PI * x);

	public static inline function blackmanHarris(x:Float):Float
		return 0.4243801 - 0.4973406 * Math.cos(TWO_PI * x) + 0.0782793 * Math.cos(FOUR_PI * x);

	public static inline function flatTop(x:Float):Float
		return 0.21557895 - 0.41663158 * Math.cos(TWO_PI * x) + 0.277263158 * Math.cos(FOUR_PI * x)
			+ 0.083578947 * Math.cos(SIX_PI * x) + 0.006947368 * Math.cos(EIGHT_PI * x);
}

enum abstract TimeUnit(Int) from Int to Int {
	var MILLISECOND = 0;
	var SECOND = 1;
	var SAMPLE = 2;
}

/**
 * An utility that analyze FlxSound,
 * can be used to make waveform or real-time audio visualizer.
 */

final class AudioAnalyzer {
	static final _permutations:Map<Int, Array<Int>> = [];
	static final _twiddleReals:Map<Int, Array<Float>> = [];
	static final _twiddleImags:Map<Int, Array<Float>> = [];
	static final _reals:Array<Array<Float>> = [];
	static final _imags:Array<Array<Float>> = [];
	static var _freqCalculating:Int = 0;
	static final _mutex = new Mutex();

	public static function calculateFrequencies(samples:Array<Float>, ?window:WindowFunction, ?frequencies:Array<Float>, ?fftN:Int):Array<Float> {
		if (fftN == null) fftN = samples.length;

		var bits = 0;
		while ((fftN >>= 1) > 0) bits++;
		if (bits == 0) throw "AudioAnalyzer.calculateFrequencies: Cannot insert a sample length or fftN of 1";

		fftN = 1 << bits;
		var fftN2 = fftN >> 1, scale = 1.0 / fftN;

		var permutation:Array<Int>, twiddleReal:Array<Float>, twiddleImag:Array<Float>;
		_mutex.acquire();

		var real:Array<Float> = _reals[_freqCalculating], imag:Array<Float> = _imags[_freqCalculating];
		if (real == null) {
			_reals.push(real = []);
			_imags.push(imag = []);
		}
		_freqCalculating++;

		if (_permutations.exists(bits)) {
			permutation = _permutations.get(bits);
			twiddleReal = _twiddleReals.get(bits);
			twiddleImag = _twiddleImags.get(bits);
		}
		else {
			(permutation = []).resize(fftN);
			(twiddleReal = []).resize(fftN2);
			(twiddleImag = []).resize(fftN2);

			var ang:Float;
			for (i in 0...fftN) {
				permutation[i] = _bitReverse(i, bits);
				if (i < fftN2) {
					twiddleReal[i] = Math.cos((ang = -6.283185307179586 * i / fftN));
					twiddleImag[i] = Math.sin(ang);
				}
			}

			_permutations.set(bits, permutation);
			_twiddleReals.set(bits, twiddleReal);
			_twiddleImags.set(bits, twiddleImag);
		}

		_mutex.release();

		if (fftN > real.length) {
			real.resize(fftN);
			imag.resize(fftN);
		}

		if (frequencies == null) frequencies = [];
		if (frequencies.length < fftN2) frequencies.resize(fftN2);

		var g = samples.length, tr:Float;
		for (i in 0...fftN) {
			if (i < g) {
				tr = samples[i];
				if (window != null) tr *= window(i * scale);
			}
			else tr = 0.0;

			real[permutation[i]] = tr;
			imag[i] = 0;
		}

		var half = 1, b:Int, r:Int, i0:Int, i1:Int, ti:Float;
		bits = fftN2;
		while (bits > 0) {
			g = 0;
			while (g < fftN) {
				b = r = 0;
				while (b < half) {
					i1 = (i0 = g + b) + half;
					tr = real[i1] * twiddleReal[r] - imag[i1] * twiddleImag[r];
					ti = real[i1] * twiddleImag[r] + imag[i1] * twiddleReal[r];
					real[i1] = real[i0] - tr;
					imag[i1] = imag[i0] - ti;
					real[i0] += tr;
					imag[i0] += ti;
					b++;
					r += bits;
				}
				g += half << 1;
			}
			half <<= 1;
			bits >>= 1;
		}

		frequencies[0] = Math.sqrt(real[0] * real[0] + imag[0] * imag[0]) * scale;
		for (i in 1...fftN2) frequencies[i] = 2 * Math.sqrt(real[i] * real[i] + imag[i] * imag[i]) * scale;

		_mutex.acquire();
		_freqCalculating--;
		_mutex.release();

		return frequencies;
	}
	static function _bitReverse(x:Int, bits:Int):Int {
		var y = 0, i = bits;
		while (i > 0) {
			y = (y << 1) | (x & 1);
			x >>= 1;
			i--;
		}
		return y;
	}
	public static function getSpectrumFromFrequencies(frequencies:Array<Float>, sampleRate:Int, barCount:Int, ?spectrum:Array<Float>, ratio = 0.0, minDb = -63.0, maxDb = -10.0, minFreq = 20.0, maxFreq = 20000.0, logScale = true):Array<Float> {
		if (spectrum == null) spectrum = [];
		if (spectrum.length < barCount) spectrum.resize(barCount);

		var n = frequencies.length - 1;

		var base = logScale ? Math.log(minFreq) : minFreq;
		var span = (logScale ? Math.log(maxFreq) : maxFreq) - base;

		var dbRangeRate = 1.0 / (maxDb - minDb), rate = frequencies.length * 2.0 / sampleRate;

		inline function calculateScale(i:Int) {
			var t = base + span * i / (barCount + 1);
			return CoolUtil.bound((logScale ? Math.exp(t) : t) * rate, 0, n);
		}

		var s1 = calculateScale(0), s2;
		var i1 = Math.floor(s1), i2;
		var v, range;
		for (i in 0...barCount) {
			if ((range = (s2 = calculateScale(i + 1)) - s1) < 1.0) {
				var c = (s1 + s2) * 0.5;
			    var s = Math.floor(c);
			    var e = s + 1;
			    if (e > n) e = n;
			    v = frequencies[s] + (frequencies[e] - frequencies[s]) * (c - s);
			}
			else {
				v = frequencies[i1] * (Math.ceil(s1) - s1);
				if (i1 != (i2 = Math.floor(s2))) {
					while (++i1 < i2) v += frequencies[i1];
					v += frequencies[i2] * (s2 - Math.floor(s2));
				}
			}
			i1 = Math.floor(s1 = s2);

			v = CoolUtil.bound((Math.log(v) * 8.685889638065035/*20 / 2.302585092994046*/ - minDb) * dbRangeRate, 0, 1);
			if (ratio > 0 && ratio < 1 && v < spectrum[i]) spectrum[i] -= (spectrum[i] - v) * ratio;
			else spectrum[i] = v;
		}

		return spectrum;
	}
	public function getRMSFromSamples(samples:Array<Float>, sampleRate:Int, ?window:WindowFunction, ?minDb:Float = -63.0, ?maxDb:Float = -10.0, ?minFreq:Float = 20.0, ?maxFreq:Float = 22000.0):Float {
		final aLP = Math.min(1, WindowFunctions.TWO_PI * maxFreq / sampleRate);
		final aHP = 1 / (1 + WindowFunctions.TWO_PI * minFreq / sampleRate);
		final hasLP = aLP < 1, hasHP = aHP > 0;

		var sum = 0.0, lp = 0.0, hp = 0.0, x = 0.0, xPrev = 0.0;
		for (i in 0...fftN) {
			x = samples[i];
			if (hasHP) {
				hp = aHP * (hp + x - xPrev);
				xPrev = x;
				x = hp;
			}
			if (hasLP) lp += aLP * (x - lp);
			else lp = x;
			sum += lp * lp;
		}

		final rms = Math.sqrt(sum / fftN);
		return CoolUtil.bound((Math.log(rms) * 8.685889638065035/*20 / 2.302585092994046*/ - minDb) / (maxDb - minDb), 0, 1);
	}
	public function getRMS(?pos:Float, ?timeUnit:TimeUnit, gain:Float = 1.0, ?window:WindowFunction, minDb:Float = -63.0, maxDb:Float = -10.0, minFreq:Float = 20.0, maxFreq:Float = 22000.0):Float {
		if (buffer == null || sound == null) return 0;
		if (pos == null) pos = sound.time;
		else if (timeUnit == SECOND) pos *= 1000;
		else if (timeUnit == SAMPLE) pos = pos * 1000 / buffer.sampleRate;
		return getRMSFromSamples(getSamples(pos, fftN, true, -1, gain), buffer.sampleRate, window, minDb, maxDb, minFreq, maxFreq);
	}
	public function getSpectrum(?pos:Float, ?timeUnit:TimeUnit, gain:Float = 1.0, ?window:WindowFunction, barCount:Int, ?spectrum:Array<Float>, ratio:Float = 0.0, minDb:Float = -63.0, maxDb:Float = -10.0, minFreq:Float = 20.0, maxFreq:Float = 20000.0, logScale:Bool = true):Array<Float> {
		if (buffer == null || sound == null) return [];
		if (pos == null) pos = sound.time;
		else if (timeUnit == SECOND) pos *= 1000;
		else if (timeUnit == SAMPLE) pos = pos * 1000 / buffer.sampleRate;
		var samples = getSamples(pos, fftN, true, -1, gain);
		var frequencies = calculateFrequencies(samples, window, null, fftN);
		return getSpectrumFromFrequencies(frequencies, buffer.sampleRate, barCount, spectrum, ratio, minDb, maxDb, minFreq, maxFreq, logScale);
	}

	/**
	 * Get bytes from an audio buffer with specified position and wordSize
	 * @param buffer The audio buffer to get byte from.
	 * @param position The specified position to get the byte from the audio buffer.
	 * @param wordSize How many bytes to get with to one byte (Usually it's bitsPerSample / 8 or bitsPerSample >> 3).
	 * @return Byte from the audio buffer with specified position.
	 */
	public static function getByte(buffer:ArrayBuffer, position:Int, wordSize:Int):Int {
		if (wordSize == 2) return inline ArrayBufferIO.getInt16(buffer, position);
		else if (wordSize == 3) {
			var b = inline ArrayBufferIO.getUint16(buffer, position) | (buffer.get(position + 2) << 16);
			if (b & 0x800000 != 0) return b - 0x1000000;
			else return b;
		}
		else if (wordSize == 4) return inline ArrayBufferIO.getInt32(buffer, position);
		else return inline ArrayBufferIO.getUint8(buffer, position) - 128;
	}

	/**
	 * Gets levels from the frequencies with specified sample rate.
	 * @param frequencies Frequencies input.
	 * @param sampleRate Sample Rate input.
	 * @param barCount How much bars to get.
	 * @param levels The output for getting the values, to avoid memory leaks (Optional).
	 * @param ratio How much ratio for smoothen the values from the previous levels values (Optional, use CoolUtil.getFPSRatio(1 - ratio) to simulate web AnalyserNode.smoothingTimeConstant, 0.35 of smoothingTime works most of the time).
	 * @param minDb The minimum decibels to cap (Optional, default -63.0, -120 is pure silence).
	 * @param maxDb The maximum decibels to cap (Optional, default -10.0, Above 0 is not recommended).
	 * @param minFreq The minimum frequency to cap (Optional, default 20.0, Below 8.0 is not recommended).
	 * @param maxFreq The maximum frequency to cap (Optional, default 22000.0, Above 23000.0 is not recommended).
	 * @return Output of levels/bars that ranges from 0 to 1.
	 */
	public static function getLevelsFromFrequencies(frequencies:Array<Float>, sampleRate:Int, barCount:Int, ?levels:Array<Float>, ratio = 0.0, minDb = -63.0, maxDb = -10.0, minFreq = 20.0, maxFreq = 22000.0):Array<Float>
		return inline getSpectrumFromFrequencies(frequencies, sampleRate, barCount, levels, ratio, minDb, maxDb, minFreq, maxFreq);

	static var __reverseIndices:Array<Array<Int>> = [];
	static var __windows:Array<Array<Float>> = [];
	static var __twiddleReals:Array<Array<Float>> = [];
	static var __twiddleImags:Array<Array<Float>> = [];
	static var __freqReals:Array<Array<Float>> = [];
	static var __freqImags:Array<Array<Float>> = [];
	static var __freqCalculating:Int = 0;
	#if (target.threaded)
	static var __mutex:Mutex = new Mutex();
	#end

	/**
	 * Gets frequencies from the samples.
	 * @param samples The samples (can be from AudioAnalyzer.getSamples).
	 * @param fftN How much samples for the fft to get, Has to be power of two, or it won't work.
	 * @param useWindowing Should fft related stuff use blackman windowing? (Web AnalyzerNode windowing), Most of the time it's not worth it.
	 * @param frequencies The output for getting the frequencies, to avoid memory leaks (Optional).
	 * @return Output of frequencies.
	 */
	public static function getFrequenciesFromSamples(samples:Array<Float>, fftN = 2048, useWindowing = false, ?frequencies:Array<Float>):Array<Float> {
		return calculateFrequencies(samples, useWindowing ? WindowFunctions.blackmanNuttall : null, frequencies, fftN);
	}

	static function __bitReverse(x:Int, log:Int):Int {
		var y = 0, i = log;
		while (i > 0) {
			y = (y << 1) | (x & 1);
			x >>= 1;
			i--;
		}
		return y;
	}

	/**
	 * The current sound to analyze.
	 */
	public var sound:FlxSound;

	/**
	 * How much samples for the fft to get.
	 * Usually for getting the levels or frequencies of the sound.
	 * 
	 * Has to be power of two, or it won't work.
	 */
	public var fftN:Int;

	/**
	 * Should fft related stuff use blackman windowing? (Web AnalyzerNode windowing).
	 * Most of the time looks bad with this.
	 */
	public var useWindowingFFT:Bool;

	/**
	 * The current buffer from sound.
	 */
	public var buffer(default, null):AudioBuffer;

	/**
	 * The current byteSize from buffer.
	 * Example the byteSize of 16 BitsPerSample is 32768 (1 << 16-1)
	 */
	public var byteSize(default, null):Int;

	var __toBits:Float;
	var __wordSize:Int;
	var __sampleSize:Int;

	#if (lime_cffi && lime_vorbis)
	var __vorbis:VorbisFile;
	var __buffer:ArrayBuffer;
	var __bufferSize:Int;
	var __bufferLastSize:Int;
	var __bufferTime:Float;
	var __bufferLastTime:Float;
	#end

	// analyze
	var __min:Array<Int> = [];
	var __max:Array<Int> = [];
	var __minByte:Int;
	var __maxByte:Int;

	// samples
	var __sampleIndex:Int;
	var __sampleChannel:Int;
	var __sampleToValue:Float;
	var __sampleOutputMerge:Bool;
	var __sampleOutputLength:Int;
	var __sampleOutput:Array<Float>;

	// frequencies
	var __freqSamples:Array<Float>;
	var __frequencies:Array<Float>;

	/**
	 * Creates an analyzer for specified FlxSound
	 * @param sound An FlxSound to analyze.
	 * @param fftN How much samples for fft to get (Optional, default 2048, 4096 is recommended for highest quality).
	 * @param useWindowingFFT Should fft related stuff use blackman windowing? (Web AnalyzerNode windowing).
	 */
	public function new(sound:FlxSound, fftN = 2048, useWindowingFFT = false) {
		this.sound = sound;
		this.fftN = fftN;
		this.useWindowingFFT = useWindowingFFT;
		__check();
	}

	function __check() if (sound != null && sound.buffer != buffer) {
		byteSize = 1 << ((buffer = sound.buffer).bitsPerSample - 1);

		#if (lime_cffi && lime_vorbis)
		__vorbis = null;
		__bufferLastSize = 0;
		__bufferTime = Math.NaN;
		__bufferLastTime = Math.NaN;
		#end

		__toBits = buffer.sampleRate / 1000 * (__sampleSize = buffer.channels * (__wordSize = buffer.bitsPerSample >> 3));
		__min.resize(buffer.channels);
		__max.resize(buffer.channels);
	}

	/**
	 * Gets levels from an attached FlxSound from startPos, basically a minimized of frequencies.
	 * @param startPos Start Position to get from sound in milliseconds.
	 * @param volume How much volume multiplier will it affect the output. (Optional, default 1.0).
	 * @param barCount How much bars to get.
	 * @param levels The output for getting the values, to avoid memory leaks (Optional).
	 * @param ratio How much ratio for smoothen the values from the previous levels values (Optional, use CoolUtil.getFPSRatio(1 - ratio) to simulate web AnalyserNode.smoothingTimeConstant, 0.35 of smoothingTime works most of the time).
	 * @param minDb The minimum decibels to cap (Optional, default -63.0, -120 is pure silence).
	 * @param maxDb The maximum decibels to cap (Optional, default -10.0, Above 0 is not recommended).
	 * @param minFreq The minimum frequency to cap (Optional, default 20.0, Below 8.0 is not recommended).
	 * @param maxFreq The maximum frequency to cap (Optional, default 22000.0, Above 23000.0 is not recommended).
	 * @return Output of levels/bars that ranges from 0 to 1.
	 */
	public function getLevels(?startPos:Float, ?volume:Float, barCount:Int, ?levels:Array<Float>, ?ratio:Float, ?minDb:Float, ?maxDb:Float, ?minFreq:Float, ?maxFreq:Float):Array<Float>
		return inline getLevelsFromFrequencies(__frequencies = getFrequencies(startPos, volume, __frequencies), buffer.sampleRate, barCount, levels, ratio, minDb, maxDb, minFreq, maxFreq);

	/**
	 * Gets frequencies from an attached FlxSound from startPos.
	 * @param startPos Start Position to get from sound in milliseconds.
	 * @param volume How much volume multiplier will it affect the output. (Optional, default 1.0).
	 * @param frequencies The output for getting the frequencies, to avoid memory leaks (Optional).
	 * @return Output of frequencies.
	 */
	public function getFrequencies(?startPos:Float, ?volume:Float, ?frequencies:Array<Float>):Array<Float>
		return inline getFrequenciesFromSamples(__freqSamples = getSamples(startPos != null ? startPos : sound.time, fftN, true, -1, volume, __freqSamples), fftN, useWindowingFFT, frequencies);

	/**
	 * Analyzes an attached FlxSound from startPos to endPos in milliseconds to get the amplitudes.
	 * @param startPos Start Position to get from sound in milliseconds.
	 * @param endPos End Position to get from sound in milliseconds.
	 * @param outOrOutMin The output minimum value from the analyzer, indices is in channels (0 to -0.5 -> 0 to 0.5) (Optional, if outMax doesn't get passed in, it will be [min, max] with all channels combined instead).
	 * @param outMax The output maximum value from the analyzer, indices is in channels (Optional).
	 * @return Output of amplitude from given position.
	 */
	public function analyze(startPos:Float, endPos:Float, ?outOrOutMin:Array<Float>, ?outMax:Array<Float>):Float {
		var hasOut = outOrOutMin != null;
		var hasTwoOut = hasOut && outMax != null;

		if (hasTwoOut) for (i in 0...buffer.channels) __min[i] = __max[i] = 0;
		__minByte = __maxByte = 0;

		__check();
		__read(startPos, endPos, hasTwoOut ? __analyzeCallback : __analyzeCallbackSimple);

		if (hasOut) {
			var f:Float;
			if (hasTwoOut) for (i in 0...buffer.channels) {
				if (outOrOutMin[i] < (f = __min[i] / byteSize)) outOrOutMin[i] = f;
				if (outMax[i] < (f = __max[i] / byteSize)) outMax[i] = f;
			}
			else {
				outOrOutMin.resize(2);
				if (outOrOutMin[0] < (f = __minByte / byteSize)) outOrOutMin[0] = f;
				if (outOrOutMin[1] < (f = __maxByte / byteSize)) outOrOutMin[1] = f;
			}
		}

		return (__maxByte + __minByte) / byteSize;
	}

	function __analyzeCallback(b:Int, c:Int):Void
		((b > __max[c]) ? (if ((__max[c] = b) > __maxByte) (__maxByte = b)) : (if (-b > __min[c]) (if ((__min[c] = -b) > __minByte) (__minByte = __min[c]))));

	function __analyzeCallbackSimple(b:Int, c:Int):Void
		((b > __maxByte) ? (__maxByte = b) : (if (-b > __minByte) (__minByte = -b)));

	/**
	 * Gets samples from startPos with given length of samples.
	 * @param startPos Start Position to get from sound in milliseconds.
	 * @param length Length of Samples.
	 * @param mono Merge all of the byte channels of samples in one channel instead (Optional).
	 * @param channel What channels to get from? (-1 == All Channels, Optional, this will be ignored if mono is enabled).
	 * @param volume How much volume multiplier will it affect the output. (Optional, default 1.0).
	 * @param output An Output that gets passed into this function, usually for to avoid memory leaks (Optional).
	 * @param outputMerge Merge with previous values (Optional, default false).
	 * @return Output of samples.
	 */
	public function getSamples(startPos:Float, length:Int, mono = true, channel = -1, volume = 1.0, ?output:Array<Float>, ?outputMerge = false):Array<Float> {
		__check();
		((!mono && (__sampleChannel = channel) == -1) ? (__sampleOutputLength = length * buffer.channels) : (__sampleOutputLength = length));
		((output == null) ? (__sampleOutput = output = []) : (__sampleOutput = output)).resize(__sampleOutputLength);
		if (!outputMerge) for (i in 0...__sampleOutputLength) output[i] = 0;
		((mono) ? (__sampleToValue = volume / (byteSize * buffer.channels)) : (__sampleToValue = volume / byteSize));
		__sampleOutputMerge = outputMerge;
		var leadingSamples = Std.int(Math.min(length, Math.max(0, Math.ceil(-startPos * buffer.sampleRate / 1000))));
		__sampleIndex = leadingSamples * (!mono && channel == -1 ? buffer.channels : 1);

		__read(Math.max(0, startPos), startPos + length * 1000 / buffer.sampleRate, mono ? __getSamplesCallbackMono : (channel == -1 ? __getSamplesCallback : __getSamplesCallbackChannel));

		__sampleOutput = null;
		return output;
	}

	function __getSamplesCallbackMono(b:Int, c:Int):Void if (__sampleIndex < __sampleOutputLength) {
		if (c == 0) {
			if (__sampleOutputMerge) __sampleOutput[__sampleIndex] += b * __sampleToValue;
			else __sampleOutput[__sampleIndex] = b * __sampleToValue;
		}
		else
			__sampleOutput[__sampleIndex] += b * __sampleToValue;
		if (c == buffer.channels - 1) __sampleIndex++;
	}

	function __getSamplesCallbackChannel(b:Int, c:Int):Void if (__sampleIndex < __sampleOutputLength) {
		if (c == __sampleChannel) {
			if (__sampleOutputMerge) __sampleOutput[__sampleIndex] += b * __sampleToValue;
			else __sampleOutput[__sampleIndex] = b * __sampleToValue;
			__sampleIndex++;
		}
	}

	function __getSamplesCallback(b:Int, c:Int):Void if (__sampleIndex < __sampleOutputLength) {
		if (__sampleOutputMerge) __sampleOutput[__sampleIndex] += b * __sampleToValue;
		else __sampleOutput[__sampleIndex] = b * __sampleToValue;
		__sampleIndex++;
	}

	/**
	 * Read an attached FlxSound from startPos to endPos in milliseconds with a callback.
	 * @param startPos Start Position to get from sound in milliseconds.
	 * @param endPos End Position to get from sound in milliseconds.
	 * @param callback Int->Int->Void Byte->Channels->Void Callback to get the byte of a sample.
	 */
	public function read(startPos:Float, endPos:Float, callback:AudioAnalyzerCallback) {
		__check();
		__read(startPos, endPos, callback);
	}

	inline function __read(startPos:Float, endPos:Float, callback:AudioAnalyzerCallback) {
		if (buffer.data != null) __readData(startPos, endPos, callback);
		#if lime_cffi
		else if (__canReadStream() && (startPos += __readStream(startPos, endPos, callback)) >= endPos) {}
		#if lime_vorbis
		else if (__prepareDecoder()) __readDecoder(startPos, endPos, callback);
		#end
		#end
	}

	inline function __readData(startPos:Float, endPos:Float, callback:AudioAnalyzerCallback) {
		var pos = Math.floor(startPos * __toBits), end = Math.min(Math.floor(endPos * __toBits), buffer.data.buffer.length), c = 0;
		pos -= pos % __sampleSize;
		end -= end % __sampleSize;

		while (pos < end) {
			callback(getByte(buffer.data.buffer, pos, __wordSize), c);
			if (++c >= buffer.channels) c = 0;
			pos += __wordSize;
		}
	}

	#if lime_cffi
	#if CODENAME_ENGINE_COMPAT
	inline function __canReadStream():Bool
		return false;

	inline function __readStream(startPos:Float, endPos:Float, callback:AudioAnalyzerCallback):Float
		return 0;
	#else
	inline function __canReadStream():Bool
		@:privateAccess return sound._source != null && sound._source.__backend != null && sound._source.__backend.playing;

	inline function __readStream(startPos:Float, endPos:Float, callback:AudioAnalyzerCallback):Float @:privateAccess {
		final backend = sound._source.__backend;

		// TODO: Wrap it with try until i figured it out an effective way to do this...
		// So... sometimes it just uses the decoder even if it looks good?? please help
		var n = Math.floor((endPos - startPos) * __toBits);
		var i = backend.bufferLengths.length - backend.requestBuffers - 1, time:Float;
		while (++i < backend.bufferLengths.length) if (startPos >= (time = backend.bufferTimes[i] * 1000)) {
			var pos = Math.floor((startPos - time) * __toBits), buf = backend.bufferDatas[i].buffer, size = backend.bufferLengths[i], c = 0;
			while (pos >= size) {
				if (++i >= backend.bufferLengths.length) break;
				pos -= size;
				buf = backend.bufferDatas[i].buffer;
				size = backend.bufferLengths[i];
			}
			if (i >= backend.bufferLengths.length) break;
			if ((pos -= pos % __sampleSize) < 0) pos = 0;
			n -= pos % __sampleSize;

			while (n > 0) {
				callback(getByte(buf, pos, __wordSize), c);
				if (++c > buffer.channels) c = 0;
				if ((pos += __wordSize) >= size) {
					if (++i >= backend.bufferLengths.length) break;
					pos = 0;
					buf = backend.bufferDatas[i].buffer;
					size = backend.bufferLengths[i];
				}
				n -= __wordSize;
			}

			break;
		}

		return endPos - (n / __toBits);
	}
	#end

	#if lime_vorbis
	inline function __prepareDecoder():Bool @:privateAccess {
		#if CODENAME_ENGINE_COMPAT
		// NF's Lime keeps a single native Vorbis handle and cannot safely clone it.
		// Live sources are still handled by __readStream above.
		return false;
		#else
		if (buffer.__srcVorbisFile == null) return __vorbis != null;
		if (__vorbis != null) return true;
		if ((__vorbis = buffer.__srcVorbisFile.clone()) != null) { // IM HOPING IT HAVE A GC CLOSURE.
			__buffer = new ArrayBuffer(__bufferSize = (buffer.sampleRate >> 1) * __sampleSize); // 0.5 seconds of buffers.
			return true;
		}
		return false;
		#end
	}

	inline function __readDecoder(startPos:Float, endPos:Float, callback:AudioAnalyzerCallback) {
		var n = Math.floor((endPos - startPos) * __toBits);
		if ((n -= n % __sampleSize) > 0) {
			var pos = Math.floor((startPos - __bufferTime * 1000) * __toBits);
			pos -= pos % __sampleSize;

			var doRead = __bufferLastSize == 0 || (pos < 0 && pos >= __bufferSize);
			if (doRead) {
				if (startPos < 1) {
					__vorbis.rawSeek(0);
					__bufferTime = 0;
				}
				else
					__vorbis.timeSeek(__bufferTime = startPos / 1000);

				__bufferLastSize = pos = 0;
			}

			var isBigEndian = lime.system.System.endianness == lime.system.Endian.BIG_ENDIAN, ranOut = false, c = 0, result;
			while (true) {
				if (doRead) {
					result = __vorbis.read(__buffer, pos, __bufferSize - pos, isBigEndian, __wordSize, true);
					if (result == Vorbis.HOLE) continue;
					else if (result < 0) break;
					else if (!(ranOut = result == 0)) {
						__bufferLastTime = __vorbis.timeTell();
						__bufferLastSize += result;
						while (pos < __bufferLastSize) {
							callback(getByte(__buffer, pos, __wordSize), c);
							if (++c > buffer.channels) c = 0;
							pos += __wordSize;
							if ((n -= __wordSize) <= 0) break;
						}
					}
				}
				else {
					while (pos < __bufferLastSize) {
						callback(getByte(__buffer, pos, __wordSize), c);
						if (++c > buffer.channels) c = 0;
						pos += __wordSize;
						if ((n -= __wordSize) <= 0) break;
					}
					doRead = true;
					ranOut = pos >= __bufferSize;
				}

				if (n <= 0) break;
				else if (doRead && ranOut) {
					__bufferLastSize = pos = 0;
					__bufferTime = __bufferLastTime;
				}
			}
		}
	}
	#end
	#end
}
