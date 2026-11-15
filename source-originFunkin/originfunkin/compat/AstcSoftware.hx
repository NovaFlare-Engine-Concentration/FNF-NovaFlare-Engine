package originfunkin.compat;

#if (windows && cpp && sys)
import haxe.io.Bytes;
import format.png.Data;
import format.png.Writer;
import haxe.io.BytesOutput;
import haxe.zip.Compress;
import sys.thread.Mutex;

/** CPU fallback for 2D ASTC textures from Origin mods on Windows. */
@:build(originfunkin.macro.OriginAstcMacro.attach())
class AstcSoftware
{
  static final lock:Mutex = new Mutex();
  static final blockSizes:Array<Array<Int>> = [[4,4], [5,4], [5,5], [6,5], [6,6], [8,5], [8,6], [8,8],
    [10,5], [10,6], [10,8], [10,10], [12,10], [12,12]];

  static inline function int24(bytes:Bytes, at:Int):Int
  {
    return bytes.get(at) | (bytes.get(at + 1) << 8) | (bytes.get(at + 2) << 16);
  }

  /** Returns null for invalid headers, unsupported shapes, or excessive dimensions. */
  public static function toPng(bytes:Null<Bytes>):Null<Bytes>
  {
    if (bytes == null || bytes.length < 16 || bytes.get(0) != 0x13 || bytes.get(1) != 0xab
      || bytes.get(2) != 0xa1 || bytes.get(3) != 0x5c) return null;
    var bw = bytes.get(4), bh = bytes.get(5);
    if (bytes.get(6) != 1 || int24(bytes, 13) != 1) return null;
    var valid = false;
    for (size in blockSizes) if (size[0] == bw && size[1] == bh) { valid = true; break; }
    if (!valid) return null;
    var width = int24(bytes, 7), height = int24(bytes, 10);
    if (width <= 0 || height <= 0 || width > 8192 || height > 8192 || width * 1.0 * height > 16777216) return null;
    var expected:Float = 16.0 + Math.ceil(width / bw) * Math.ceil(height / bh) * 16.0;
    if (expected > bytes.length) return null;

    // The backend may request several images concurrently. Bound temporary pixel memory.
    lock.acquire();
    try
    {
      var pixels = Bytes.alloc(width * height * 4);
      var input = bytes.getData();
      var output = pixels.getData();
      var success:Int = untyped __cpp__('decode_astc((const uint8_t*){0}->GetBase()+16, {1}, {2}, {3}, {4}, (uint32_t*){5}->GetBase())',
        input, width, height, bw, bh, output);
      if (success != 1) { lock.release(); return null; }
      // Lime's native PNG encoder is not guaranteed to be built into the
      // selected runtime. Encode through the existing Haxe format library.
      var rows = Bytes.alloc((width * 4 + 1) * height);
      var scanlines = rows.getData();
      untyped __cpp__('{ const uint8_t* src=(const uint8_t*){0}->GetBase(); uint8_t* dst=(uint8_t*){1}->GetBase(); for (int y=0;y<{3};++y) { *dst++=0; for (int x=0;x<{2};++x) { dst[0]=src[2]; dst[1]=src[1]; dst[2]=src[0]; dst[3]=src[3]; src+=4; dst+=4; } } }', output, scanlines, width, height);
      var chunks:Data = new List();
      chunks.add(CHeader({width:width, height:height, colbits:8, color:ColTrue(true), interlaced:false}));
      chunks.add(CData(Compress.run(rows, 3)));
      chunks.add(CEnd);
      var result = new BytesOutput();
      new Writer(result).write(chunks);
      lock.release();
      return result.getBytes();
    }
    catch (error:Dynamic)
    {
      lock.release();
      trace('[Origin ASTC] CPU decode failed: $error');
      return null;
    }
  }
}
#end