package funkin.graphics;
import funkin.graphics.shaders.RuntimeCustomBlendShader;
import funkin.graphics.framebuffer.FixedBitmapData;
import flixel.system.FlxAssets.FlxShader;
import animate.internal.RenderTexture;

import flixel.FlxCamera;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxFrame;
import flixel.graphics.tile.FlxDrawQuadsItem;
import flixel.graphics.tile.FlxDrawTrianglesItem;
import flixel.math.FlxMatrix;
import flixel.math.FlxRect;
import flixel.graphics.tile.FlxGraphicsShader;
import funkin.graphics.framebuffer.FunkinBufferRenderer;
import openfl.Lib;
import openfl.geom.ColorTransform;
import openfl.display.BitmapData;
import openfl.display.BlendMode;
import openfl.display.OpenGLRenderer;


using funkin.graphics.framebuffer.BitmapDataUtil;

/**
 * A FlxCamera with additional powerful features:
 * - Added the ability to grab the camera screen as a `BitmapData` and use it as a texture.
 */
@:nullSafety
@:access(openfl.display.DisplayObject)
@:access(openfl.display.BitmapData)
@:access(openfl.display3D.Context3D)
@:access(openfl.display3D.textures.TextureBase)
@:access(flixel.graphics.FlxGraphic)
@:access(flixel.graphics.frames.FlxFrame)
@:access(openfl.display.OpenGLRenderer)
@:access(openfl.geom.ColorTransform)
@:access(funkin.graphics.framebuffer.FunkinBufferRenderer)
class FunkinCamera extends FlxCamera
{
  /**
   * The ID of this camera, used for debugging.
   */
  public var id:String;

  /**
   * If `true` the camera will render the previous frame to a buffer before rendering the current frame.
   * This buffer can then be accessed via `camera.texture`.
   *
   * Disabled by default since this can impact performance.
   */
  public var renderBuffer:Bool = false;

  /**
   * If `true`, and `renderBuffer` is on, the camera only draws into its buffer and never onto the
   * screen.
   */
  public var bufferOnly:Bool = false;

  /**
   * The renderer used to render the buffer.
   */
  @:nullSafety(Off)
  public var bufferRenderer:FunkinBufferRenderer = null;

  /**
   * The shader to use on all objects rendering through this camera (only if the incoming objects do not define a shader).
   * If null defaults to `FlxGraphicsShader`
   */
  public var defaultShader:Null<FlxGraphicsShader> = null;

  /**
   * The rendered buffer texture.
   */
  public var texture(get, never):BitmapData;

  function get_texture():BitmapData
  {
    return bufferRenderer.texture;
  }

  @:nullSafety(Off)
  public function new(id:String = 'unknown', x:Int = 0, y:Int = 0, width:Int = 0, height:Int = 0, zoom:Float = 0)
  {
    super(x, y, width, height, zoom);

    this.id = id;

    bufferRenderer = new FunkinBufferRenderer(this);
  }

  /**
   * Allocates the render textures and shader used by the shader blend fallback.
   */
  @:nullSafety(Off) @:nullSafety(Off)
  override function startQuadBatch(graphic:FlxGraphic,
    colored:Bool,
    hasColorOffsets:Bool = false,
    ?blend:BlendMode,
    smooth:Bool = false,
    ?shader:FlxGraphicsShader):FlxDrawQuadsItem
  {
    if (shader == null) shader = defaultShader;

    return super.startQuadBatch(graphic, colored, hasColorOffsets, blend, smooth, shader);
  }

  public var blackListKeys:Array<String> = [];
  public var whiteListKeys:Array<String> = [];
  public var useWhitelist:Bool = false;

  function shouldRender(graphic:FlxGraphic):Bool
  {
    if (blackListKeys.contains(graphic.key))
    {
      return false;
    }

    if (useWhitelist && !whiteListKeys.contains(graphic.key))
    {
      return false;
    }

    return !graphic.isDestroyed;
  }

  @:allow(flixel.system.frontEnds.CameraFrontEnd)
  override function render():Void
  {
    // The pass that would go to the screen, on a camera that only exists to fill its buffer. The
    // buffer's own pass is the one with `dirty` set, and it is left alone.
    if (renderBuffer && bufferOnly && !bufferRenderer.dirty) return;



    var currItem:flixel.graphics.tile.FlxDrawBaseItem<Dynamic> = _headOfDrawStack;
    while (currItem != null)
    {
      if (renderBuffer && bufferRenderer.dirty)
      {
        if (!bufferRenderer.shouldRender(currItem.graphics))
        {
          currItem = currItem.next;
          continue;
        }
      }

      if (!shouldRender(currItem.graphics))
      {
        currItem = currItem.next;
        continue;
      }

      currItem.render(this);
      currItem = currItem.next;
    }
  }

  override function startTrianglesBatch(graphic:FlxGraphic,
    smoothing:Bool = false,
    isColored:Bool = false,
    ?blend:BlendMode,
    ?hasColorOffsets:Bool,
    ?shader:FlxGraphicsShader):FlxDrawTrianglesItem
  {
    if (shader == null) shader = defaultShader;

    return super.startTrianglesBatch(graphic, smoothing, isColored, blend, hasColorOffsets, shader);
  }

  override function clearDrawStack():Void
  {
    if (renderBuffer && bufferRenderer.active)
    {
      bufferRenderer.render();
    }

    super.clearDrawStack();
  }


  public static final hasKhronosExtension:Bool = false;
  static final KHR_BLEND_MODES:Array<BlendMode> = [DARKEN, HARDLIGHT, OVERLAY, DIFFERENCE];
  static final SHADER_REQUIRED_BLEND_MODES:Array<BlendMode> = [INVERT];
  public var crossCameraBlending:Bool = false;
  var _blendShader:Null<RuntimeCustomBlendShader> = null;
  var _backgroundFrame:Null<FlxFrame> = null;
  var _blendRenderTexture:Null<RenderTexture> = null;
  var _backgroundRenderTexture:Null<RenderTexture> = null;
  var _cameraTexture:Null<FixedBitmapData> = null;
  var _cameraMatrix:Null<FlxMatrix> = null;

  @:nullSafety(Off)
  function ensureBlendTextures():Void
  {
    if (_blendShader != null) return;
    _backgroundFrame = new FlxFrame(new FlxGraphic('', null));
    _backgroundFrame.frame = new FlxRect();
    _blendShader = new RuntimeCustomBlendShader();
    _backgroundRenderTexture = new RenderTexture(width, height);
    _blendRenderTexture = new RenderTexture(width, height);
    _cameraMatrix = new FlxMatrix();
    _cameraTexture = FixedBitmapData.create(width, height);
  }

  @:nullSafety(Off)
  override function drawPixels(?frame:FlxFrame, ?pixels:BitmapData, matrix:FlxMatrix, ?transform:ColorTransform, ?blend:BlendMode, ?smoothing:Bool = false,
      ?shader:FlxShader):Void
  {
    if (shader == null) shader = defaultShader;
    var shouldUseShader:Bool = (!hasKhronosExtension && KHR_BLEND_MODES.contains(blend)) || SHADER_REQUIRED_BLEND_MODES.contains(blend);

    // Fallback to the shader implementation if the device doesn't support `KHR_blend_equation_advanced`, or if
    // the specified blend mode requires the shader.
    if (shouldUseShader)
    {
      ensureBlendTextures();
      if (crossCameraBlending)
      {
        var camerasUnderneath:Array<FlxCamera> = FlxG.cameras.list.copy();

        for (i in camerasUnderneath.length - 1...-1)
        {
          if (i > FlxG.cameras.list.indexOf(this))
          {
            camerasUnderneath.remove(camerasUnderneath[i]);
          }
        }

        _cameraTexture.drawCameraScreens(camerasUnderneath);

        for (camera in camerasUnderneath)
        {
          camera.clearDrawStack();
          camera.canvas.graphics.clear();
        }
      }
      else
      {
        _cameraTexture.drawCameraScreen(this);
      }

      _backgroundFrame.frame.set(0, 0, this.width, this.height);

      // Clear the camera's graphics
      // It'll get redrawn anyway
      this.clearDrawStack();
      this.canvas.graphics.clear();

      _blendRenderTexture.init(this.width, this.height);
      _blendRenderTexture.drawToCamera((camera, frameMatrix) ->
      {
        var pivotX:Float = width / 2;
        var pivotY:Float = height / 2;

        frameMatrix.copyFrom(matrix);
        frameMatrix.translate(-pivotX, -pivotY);
        frameMatrix.scale(this.scaleX, this.scaleY);
        frameMatrix.translate(pivotX, pivotY);
        camera.drawPixels(frame, pixels, frameMatrix, transform, null, smoothing, shader);
      });
      _blendRenderTexture.render();

      _blendShader.sourceSwag = _blendRenderTexture.graphic.bitmap;
      _blendShader.backgroundSwag = _cameraTexture;

      _blendShader.blendSwag = blend;
      _blendShader.updateViewInfo(width, height, this);

      _backgroundFrame.parent.bitmap = _blendRenderTexture.graphic.bitmap;

      // On some displays, the DPI can be less than 1, which causes the blend shader to look bad
      // We just clamp the scale to 1 to avoid this!
      var clampedScale:Float = Math.max(1, Lib.current.stage.window.scale);

      _backgroundRenderTexture.init(Std.int(this.width * clampedScale), Std.int(this.height * clampedScale));
      _backgroundRenderTexture.drawToCamera((camera, matrix) ->
      {
        camera.zoom = this.zoom;
        matrix.scale(clampedScale, clampedScale);
        camera.drawPixels(_backgroundFrame, null, matrix, canvas.transform.colorTransform, null, false, _blendShader);
      });

      _backgroundRenderTexture.render();

      // Resize the frame so it always fills the screen
      _cameraMatrix.identity();
      _cameraMatrix.scale(1 / (this.scaleX * clampedScale), 1 / (this.scaleY * clampedScale));
      _cameraMatrix.translate(((width - width / this.scaleX) * 0.5), ((height - height / this.scaleY) * 0.5));

      super.drawPixels(_backgroundRenderTexture.graphic.imageFrame.frame, null, _cameraMatrix, null, null, smoothing, null);
    }
    else
    {
      super.drawPixels(frame, pixels, matrix, transform, blend, smoothing, shader);
    }
  }

  var _destroyed:Bool = false;

  override function destroy():Void
  {
    if (_destroyed) return;
    _destroyed = true;
    if (FlxG.cameras.list.contains(this)) FlxG.cameras.remove(this, false);
    renderBuffer = false;

    super.destroy();

    bufferRenderer.destroy();
    if (_blendRenderTexture != null) _blendRenderTexture.destroy();
    if (_backgroundRenderTexture != null) _backgroundRenderTexture.destroy();
    if (_cameraTexture != null) _cameraTexture.dispose();
  }
}
