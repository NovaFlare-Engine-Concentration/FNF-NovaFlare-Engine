package funkin.audio.waveform;

@:nullSafety
class WaveformDataParser
{
  @:native('int16_max')
  static final INT16_MAX:Int = 32767;
  @:native('int16_min')
  static final INT16_MIN:Int = -32768;
  @:native('int8_max')
  static final INT8_MAX:Int = 127;
  @:native('int8_min')
  static final INT8_MIN:Int = -128;

  public static function interpretFlxSound(sound:Null<flixel.sound.FlxSound>):Null<WaveformData>
  {
    if (sound == null) return null;

    // Method 1. This only works if the sound has been played before.
    @:privateAccess
    var soundBuffer:Null<lime.media.AudioBuffer> = sound?._source?.buffer;
    // SDL2/OpenFL creates the AudioSource only when playback starts. Editors
    // also need waveforms for loaded, stopped and paused sounds.
    @:privateAccess
    if (soundBuffer == null) soundBuffer = sound._sound?.__buffer;

    if (soundBuffer == null)
    {
      trace('[WAVEFORM] Failed to interpret FlxSound: ${sound}');
      return null;
    }

    return interpretAudioBuffer(soundBuffer);
  }

  public static function interpretAudioBuffer(soundBuffer:lime.media.AudioBuffer):Null<WaveformData>
  {
    var channels = soundBuffer.channels;
    var bitsPerSample = soundBuffer.bitsPerSample;
    var samplesPerPoint:Int = 256; // I don't think we need to configure this.

    var soundData = soundBuffer.data;
    if (soundData == null || channels <= 0 || (bitsPerSample != 8 && bitsPerSample != 16)) return null;
    var bytes = soundData.toBytes();
    var bytesPerSample = bitsPerSample == 16 ? 2 : 1;

    var soundDataSampleCount:Int = Std.int(soundData.byteLength / channels / bytesPerSample);
    var outputPointCount:Int = Std.int(Math.ceil(soundDataSampleCount / samplesPerPoint));

    // Pre-allocate Vector with exact final size for better performance and memory efficiency
    var outputDataLength:Int = outputPointCount * channels * 2;
    var outputData = new haxe.ds.Vector<Int>(outputDataLength);

    // Reusable min/max tracking arrays to avoid allocation in the loop
    var minValues = new haxe.ds.Vector<Int>(channels);
    var maxValues = new haxe.ds.Vector<Int>(channels);

    for (pointIndex in 0...outputPointCount)
    {
      var rangeStart:Int = pointIndex * samplesPerPoint;
      var rangeEnd:Int = Std.int(Math.min(rangeStart + samplesPerPoint, soundDataSampleCount));

      // Reset min/max values for this range
      for (i in 0...channels)
      {
        minValues[i] = bitsPerSample == 16 ? INT16_MAX : INT8_MAX;
        maxValues[i] = bitsPerSample == 16 ? INT16_MIN : INT8_MIN;
      }

      // Process all samples in this range
      for (sampleIndex in rangeStart...rangeEnd)
      {
        for (channelIndex in 0...channels)
        {
          var byteIndex = soundData.byteOffset + (sampleIndex * channels + channelIndex) * bytesPerSample;
          var sampleValue:Int = bitsPerSample == 16 ? bytes.getUInt16(byteIndex) : bytes.get(byteIndex) - 128;
          if (bitsPerSample == 16 && sampleValue >= 32768) sampleValue -= 65536;

          if (sampleValue < minValues[channelIndex]) minValues[channelIndex] = sampleValue;
          if (sampleValue > maxValues[channelIndex]) maxValues[channelIndex] = sampleValue;
        }
      }

      // Write directly to final positions in output Vector
      var baseIndex:Int = pointIndex * channels * 2;
      for (channelIndex in 0...channels)
      {
        outputData[baseIndex + channelIndex * 2] = minValues[channelIndex];
        outputData[baseIndex + channelIndex * 2 + 1] = maxValues[channelIndex];
      }
    }

    var result = new WaveformData(null, channels, soundBuffer.sampleRate, samplesPerPoint, bitsPerSample, outputPointCount, outputData.toArray());

    return result;
  }

  public static function parseWaveformData(path:String):Null<WaveformData>
  {
    var rawJson:String = openfl.Assets.getText(path).trim();
    return parseWaveformDataString(rawJson, path);
  }

  public static function parseWaveformDataString(contents:String, ?fileName:String):Null<WaveformData>
  {
    var parser = new json2object.JsonParser<WaveformData>();
    trace('[WAVEFORM] Parsing waveform data: ${contents}');
    parser.fromJson(contents, fileName);

    if (parser.errors.length > 0)
    {
      printErrors(parser.errors, fileName);
      return null;
    }
    return parser.value;
  }

  static function printErrors(errors:Array<json2object.Error>, id:String = ''):Void
  {
    trace('[WAVEFORM] Failed to parse waveform data: ${id}');

    for (error in errors)
    {
      funkin.data.DataError.printError(error);
    }
  }
}
