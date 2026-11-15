package originfunkin.compat;

import flixel.FlxCamera;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import funkin.graphics.FlxFilteredSprite;
import funkin.graphics.framebuffer.FrameBufferManager;

/** An explicit GPU smoke test for historical rendering APIs on shared SDL2. */
class LegacyRenderChecks extends FlxState
{
  var buffers:FrameBufferManager;
  var bufferCamera:FlxCamera;
  var source:FlxSprite;

  override public function create():Void
  {
    super.create();
    bgColor = 0xFF202632;
    add(new FlxText(40, 30, 1100, 'Legacy rendering / SDL2\nLeft: framebuffer copy. Middle: blur filter. Right: legacy shaders.', 24));
    bufferCamera = new FlxCamera(0, 0, 64, 64, 1);
    buffers = new FrameBufferManager(bufferCamera);
    var bitmap = buffers.createFrameBuffer('legacy', FlxColor.TRANSPARENT);
    source = new FlxSprite(12, 12).makeGraphic(40, 40, 0xFFFF4040);
    buffers.copySpriteTo('legacy', source);
    var copy = new FlxSprite(100, 200).loadGraphic(bitmap);
    copy.scale.set(4, 4);
    copy.updateHitbox();
    add(copy);

    var filtered = new FlxFilteredSprite(470, 200);
    filtered.makeGraphic(100, 100, 0xFF30D0FF);
    filtered.filters = [new openfl.filters.BlurFilter(16, 16)];
    filtered.filterDirty = true;
    add(filtered);

    var outlined = new FlxSprite(820, 200).makeGraphic(100, 100, FlxColor.BLACK);
    var outline = new funkin.graphics.shaders.TitleOutline();
    outline.funnyX = 8;
    outline.funnyY = 8;
    outlined.shader = outline;
    add(outlined);
    var shadowed = new FlxSprite(1050, 200).makeGraphic(100, 100, FlxColor.TRANSPARENT, true);
    shadowed.pixels.fillRect(new openfl.geom.Rectangle(10, 10, 80, 80), 0xFF808080);
    var shadow = new funkin.graphics.shaders.DropShadowScreenspace();
    shadow.color = 0xFF804000;
    shadow.angle = 90;
    shadow.angleOffset = 0;
    shadow.setAdjustColor(-10, 0, 10, 0);
    shadow.antialiasAmt = 4;
    shadow.curZoom = 1;
    shadowed.shader = shadow;
    if (Math.abs(shadow.ang.value[0] - Math.PI / 2) > 0.00001 || shadow.brightness.value[0] != -10
      || shadow.contrast.value[0] != 10 || shadow.AA_STAGES.value[0] != 4)
      throw 'Legacy screenspace shader parameters were not preserved.';
    add(shadowed);
    if (bitmap == null || bitmap.width != 64 || bitmap.height != 64) throw 'Legacy framebuffer allocation failed.';
    trace('[Origin legacy rendering check] GPU fixtures created; verify all three panels.');
  }

  override public function draw():Void
  {
    buffers.lock();
    buffers.unlock();
    super.draw();
  }

  override public function destroy():Void
  {
    buffers.dispose();
    bufferCamera.destroy();
    source.destroy();
    super.destroy();
  }
}
