package originfunkin.compat;

#if (windows && cpp && sys)
import haxe.io.Bytes;
import lime.graphics.Image;
import lime.graphics.ImageBuffer;
import lime.utils.UInt8Array;
import openfl.display.BitmapData;

/** Best-effort static WebP decoding using an installed Windows WIC codec. */
@:build(originfunkin.macro.OriginWicMacro.attach())
class WicWebp
{
  public static function decode(bytes:Bytes):Null<BitmapData>
  {
    if (bytes == null || bytes.length < 16 || bytes.getString(0, 4) != 'RIFF' || bytes.getString(8, 4) != 'WEBP') return null;
    var input = bytes.getData();
    var dimensions = Bytes.alloc(8);
    var dims = dimensions.getData();
    var ok:Int = untyped __cpp__('nf_origin_wic_webp((const uint8_t*){0}->GetBase(), {1}, (int*){2}->GetBase(), nullptr, 0)', input, bytes.length, dims);
    if (ok != 1) return null;
    var width = dimensions.getInt32(0), height = dimensions.getInt32(4);
    if (width <= 0 || height <= 0 || width > 4096 || height > 4096 || width * 1.0 * height > 16777216) return null;
    var pixels = Bytes.alloc(width * height * 4);
    var output = pixels.getData();
    ok = untyped __cpp__('nf_origin_wic_webp((const uint8_t*){0}->GetBase(), {1}, (int*){2}->GetBase(), (uint8_t*){3}->GetBase(), {4})',
      input, bytes.length, dims, output, pixels.length);
    if (ok != 1 || dimensions.getInt32(0) != width || dimensions.getInt32(4) != height) return null;
    var buffer = new ImageBuffer(UInt8Array.fromBytes(pixels), width, height, 32);
    return BitmapData.fromImage(new Image(buffer));
  }
}
#end
