package originfunkin.compat;

#if (windows && cpp && sys && FEATURE_DEBUG_FUNCTIONS)
import haxe.io.Bytes;
import lime.graphics.Image;
import lime.graphics.PixelFormat;

class AstcSoftwareChecks
{
  static function require(ok:Bool, message:String):Void
  {
    if (!ok) throw 'ASTC software check failed: $message';
    trace('[Origin ASTC check] PASS $message');
  }

  public static function run():Void
  {
    var astc = Bytes.alloc(32);
    for (i => value in [0x13,0xab,0xa1,0x5c,4,4,1,4,0,0,4,0,0,1,0,0]) astc.set(i, value);
    // ASTC void-extent block with one opaque color: R=D0 G=80 B=20.
    astc.set(16, 0xfc); astc.set(17, 1);
    astc.set(25, 0xd0); astc.set(27, 0x80); astc.set(29, 0x20); astc.set(31, 0xff);
    var png = AstcSoftware.toPng(astc);
    require(png != null, 'valid 4x4 ASTC produces PNG bytes');
    var image = Image.fromBytes(png);
    require(image != null && image.width == 4 && image.height == 4
      && image.getPixel32(1, 1, PixelFormat.ARGB32) == cast 0xffd08020,
      'decoded PNG preserves dimensions, channel order, and color');
    require(AstcSoftware.toPng(astc.sub(0, 31)) == null, 'truncated blocks are rejected');
    var invalid = astc.sub(0, astc.length);
    invalid.set(4, 0);
    require(AstcSoftware.toPng(invalid) == null, 'invalid block dimensions are rejected');
    invalid = astc.sub(0, astc.length);
    invalid.set(6, 2);
    require(AstcSoftware.toPng(invalid) == null, '3D ASTC is rejected');
    invalid = astc.sub(0, astc.length);
    invalid.set(7, 0xff); invalid.set(8, 0xff); invalid.set(9, 0xff);
    require(AstcSoftware.toPng(invalid) == null, 'oversized dimensions are rejected before allocation');
  }
}
#end