package funkin.graphics.shaders;

import flixel.FlxCamera;
import flixel.FlxG;
import flixel.graphics.frames.FlxFrame;
import flixel.addons.display.FlxRuntimeShader;
import flixel.addons.system.macros.FlxRuntimeShaderMacro;
import lime.graphics.opengl.GLProgram;
import lime.utils.Log;
import openfl.display.BitmapData;
import openfl.display.ShaderInput;
import openfl.display.ShaderParameter;

class RuntimePostEffectShader extends FlxRuntimeShader
{
  static inline final POST_EFFECT_VERTEX_HEADER:String = '
		// normalized screen coord
		//   (0, 0) is the top left of the window
		//   (1, 1) is the bottom right of the window
		varying vec2 screenCoord;
	';

  static inline final POST_EFFECT_VERTEX_BODY:String = '
		screenCoord = vec2(
			openfl_TextureCoord.x > 0.0 ? 1.0 : 0.0,
			openfl_TextureCoord.y > 0.0 ? 1.0 : 0.0
		);
	';

  static inline final POST_EFFECT_FRAGMENT_HEADER:String = '
		// normalized screen coord
		//   (0, 0) is the top left of the window
		//   (1, 1) is the bottom right of the window
		varying vec2 screenCoord;

		// equals (FlxG.width, FlxG.height)
		uniform vec2 uScreenResolution;

		// equals (camera.viewLeft, camera.viewTop, camera.viewRight, camera.viewBottom)
		uniform vec4 uCameraBounds;

		// equals (frame.left, frame.top, frame.right, frame.bottom)
		uniform vec4 uFrameBounds;

		// screen coord -> world coord conversion
		// returns world coord in px
		vec2 screenToWorld(vec2 screenCoord) {
			float left = uCameraBounds.x;
			float top = uCameraBounds.y;
			float right = uCameraBounds.z;
			float bottom = uCameraBounds.w;
			vec2 scale = vec2(right - left, bottom - top);
			vec2 offset = vec2(left, top);
			return screenCoord * scale + offset;
		}

		// world coord -> screen coord conversion
		// returns normalized screen coord
		vec2 worldToScreen(vec2 worldCoord) {
			float left = uCameraBounds.x;
			float top = uCameraBounds.y;
			float right = uCameraBounds.z;
			float bottom = uCameraBounds.w;
			vec2 scale = vec2(right - left, bottom - top);
			vec2 offset = vec2(left, top);
			return (worldCoord - offset) / scale;
		}

		// screen coord -> frame coord conversion
		// returns normalized frame coord
		vec2 screenToFrame(vec2 screenCoord) {
			float left = uFrameBounds.x;
			float top = uFrameBounds.y;
			float right = uFrameBounds.z;
			float bottom = uFrameBounds.w;
			float width = right - left;
			float height = bottom - top;

			float clampedX = clamp(screenCoord.x, left, right);
			float clampedY = clamp(screenCoord.y, top, bottom);

			return vec2(
				(clampedX - left) / (width),
				(clampedY - top) / (height)
			);
		}

		// internally used to get the maximum `openfl_TextureCoordv`
		vec2 bitmapCoordScale() {
			return openfl_TextureCoordv / screenCoord;
		}

		// internally used to compute bitmap coord
		vec2 screenToBitmap(vec2 screenCoord) {
			return screenCoord * bitmapCoordScale();
		}

		// samples the frame buffer using a screen coord
		vec4 sampleBitmapScreen(vec2 screenCoord) {
			return texture2D(bitmap, screenToBitmap(screenCoord));
		}

		// samples the frame buffer using a world coord
		vec4 sampleBitmapWorld(vec2 worldCoord) {
			return sampleBitmapScreen(worldToScreen(worldCoord));
		}
	';

  public var uScreenResolution:ShaderParameter<Float>;
  public var uCameraBounds:ShaderParameter<Float>;
  public var uFrameBounds:ShaderParameter<Float>;

  static inline final DEFAULT_FRAGMENT_SOURCE:String = '
		#pragma header

		void main(void)
		{
			gl_FragColor = flixel_texture2D(bitmap, openfl_TextureCoordv);
		}
	';

  static inline final DEFAULT_VERTEX_SOURCE:String = '
		#pragma header

		attribute float alpha;
		attribute vec4 colorMultiplier;
		attribute vec4 colorOffset;
		uniform bool hasColorTransform;

		void main(void)
		{
			#pragma body

			openfl_Alphav = openfl_Alpha * alpha;

			if (hasColorTransform)
			{
				openfl_ColorOffsetv = colorOffset / 255.0;
				openfl_ColorMultiplierv = colorMultiplier;
			}
		}
	';

  static function resolveFragmentSource(fragmentSource:String):String
  {
    final source:String = fragmentSource ?? DEFAULT_FRAGMENT_SOURCE;
    return StringTools.replace(
      source,
      '#pragma header',
      FlxRuntimeShaderMacro.retrieveMetadata('glFragmentHeader') + POST_EFFECT_FRAGMENT_HEADER
    );
  }

  static function resolveVertexSource():String
  {
    var source:String = StringTools.replace(
      DEFAULT_VERTEX_SOURCE,
      '#pragma header',
      FlxRuntimeShaderMacro.retrieveMetadata('glVertexHeader') + POST_EFFECT_VERTEX_HEADER
    );
    return StringTools.replace(
      source,
      '#pragma body',
      FlxRuntimeShaderMacro.retrieveMetadata('glVertexBody') + POST_EFFECT_VERTEX_BODY
    );
  }

  public function new(fragmentSource:String = null, glVersion:String = null)
  {
    // NovaFlare's selected flixel-addons predates the optional glVersion
    // constructor argument. It also falls back to FlxRuntimeShader's own
    // metadata when a null source is passed, which drops this subclass's three
    // post-effect uniforms. Resolve this subclass's header/body metadata before
    // entering super() so its runtime parser creates the official bindings.
    super(resolveFragmentSource(fragmentSource), resolveVertexSource());

    uScreenResolution = cast Reflect.field(data, 'uScreenResolution');
    uCameraBounds = cast Reflect.field(data, 'uCameraBounds');
    uFrameBounds = cast Reflect.field(data, 'uFrameBounds');
    if (uScreenResolution == null || uCameraBounds == null || uFrameBounds == null)
    {
      throw 'Could not initialize the FNF 0.8.4 post-effect shader uniforms.';
    }

    uScreenResolution.value = [FlxG.width, FlxG.height];
    uCameraBounds.value = [0, 0, FlxG.width, FlxG.height];
    uFrameBounds.value = [0, 0, FlxG.width, FlxG.height];
  }

  /**
   * Compatibility with FNF's pinned FlxRuntimeShader. NovaFlare's selected
   * flixel-addons predates this helper, but exposes the same ShaderInput data.
   */
  public function setBitmapData(name:String, value:BitmapData):Void
  {
    var prop:ShaderInput<BitmapData> = Reflect.field(this.data, name);
    if (prop == null)
    {
      trace('[WARN] Shader sampler2D property ${name} not found.');
      return;
    }
    prop.input = value;
  }

  // basically `updateViewInfo(FlxG.width, FlxG.height, FlxG.camera)` is good
  public function updateViewInfo(screenWidth:Float, screenHeight:Float, camera:FlxCamera):Void
  {
    uScreenResolution.value = [screenWidth, screenHeight];
    uCameraBounds.value = [camera.viewLeft, camera.viewTop, camera.viewRight, camera.viewBottom];
  }

  public function updateFrameInfo(frame:FlxFrame)
  {
    // NOTE: uv.right is actually the right pos and uv.bottom is the bottom pos
    uFrameBounds.value = [frame.uv.left, frame.uv.top, frame.uv.right, frame.uv.bottom];
  }

  override function __createGLProgram(vertexSource:String, fragmentSource:String):GLProgram
  {
    try
    {
      final res = super.__createGLProgram(vertexSource, fragmentSource);
      return res;
    }
    catch (error)
    {
      Log.warn(error); // prevent the app from dying immediately
      return null;
    }
  }
}
