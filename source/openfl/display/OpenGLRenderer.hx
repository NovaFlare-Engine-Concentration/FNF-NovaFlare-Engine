package openfl.display;

#if !flash
import openfl.display._internal.Context3DBitmap;
import openfl.display._internal.Context3DBitmapData;
import openfl.display._internal.Context3DDisplayObject;
import openfl.display._internal.Context3DDisplayObjectContainer;
import openfl.display._internal.Context3DGraphics;
import openfl.display._internal.Context3DMaskShader;
import openfl.display._internal.Context3DSimpleButton;
import openfl.display._internal.Context3DTextField;
import openfl.display._internal.Context3DTilemap;
import openfl.display._internal.Context3DVideo;
import openfl.display._internal.ShaderBuffer;
import openfl.utils.ObjectPool;
import openfl.display3D.Context3DClearMask;
import openfl.display3D.Context3D;
import openfl.geom.ColorTransform;
import openfl.geom.Matrix;
import openfl.geom.Rectangle;
#if lime
import lime.graphics.opengl.ext.KHR_debug;
import lime.graphics.WebGLRenderContext;
import lime.math.Matrix4;
#end

/**
	**BETA**

	The OpenGLRenderer API exposes support for OpenGL render instructions within the
	`RenderEvent.RENDER_OPENGL` event.
**/
#if !openfl_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end
@:access(lime.graphics.GLRenderContext)
@:access(openfl.display._internal.ShaderBuffer)
@:access(openfl.display3D.Context3D)
@:access(openfl.display.BitmapData)
@:access(openfl.display.DisplayObject)
@:access(openfl.display.Graphics)
@:access(openfl.display.IBitmapDrawable)
@:access(openfl.display.Shader)
@:access(openfl.display.ShaderParameter)
@:access(openfl.display.Stage3D)
@:access(openfl.geom.ColorTransform)
@:access(openfl.geom.Matrix)
@:access(openfl.geom.Rectangle)
@:allow(openfl.display._internal)
@:allow(openfl.display3D.textures)
@:allow(openfl.display3D)
@:allow(openfl.display)
@:allow(openfl.text)
class OpenGLRenderer extends DisplayObjectRenderer
{
	@:noCompletion private static var __alphaValue:Array<Float> = [1];
	@:noCompletion private static var __colorMultipliersValue:Array<Float> = [0, 0, 0, 0];
	@:noCompletion private static var __colorOffsetsValue:Array<Float> = [0, 0, 0, 0];
	@:noCompletion private static var __defaultColorMultipliersValue:Array<Float> = [1, 1, 1, 1];
	@:noCompletion private static var __emptyColorValue:Array<Float> = [0, 0, 0, 0];
	@:noCompletion private static var __emptyAlphaValue:Array<Float> = [1];
	@:noCompletion private static var __hasColorTransformValue:Array<Bool> = [false];
	@:noCompletion private static var __scissorRectangle:Rectangle = new Rectangle();
	@:noCompletion private static var __textureSizeValue:Array<Float> = [0, 0];
	#if sys
	@:noCompletion private static var __novaPerfTrace:Bool = Sys.getEnv("NOVAGC_PERF_TRACE") != null;
	@:noCompletion private static var __novaPerfWindowStart:Float = 0.0;
	@:noCompletion private static var __novaPerfCount:Int = 0;
	@:noCompletion private static var __novaPerfTotal:Float = 0.0;
	@:noCompletion private static var __novaPerfSetup:Float = 0.0;
	@:noCompletion private static var __novaPerfDrawable:Float = 0.0;
	@:noCompletion private static var __novaPerfPresent:Float = 0.0;
	@:noCompletion private static var __novaPerfMax:Float = 0.0;
	#end

	/**
		The current OpenGL render context
	**/
	@SuppressWarnings("checkstyle:Dynamic")
	public var gl:#if lime WebGLRenderContext #else Dynamic #end;

	@:noCompletion private static var __staticDefaultDisplayShader:DisplayObjectShader;
	@:noCompletion private static var __staticDefaultGraphicsShader:GraphicsShader;
	@:noCompletion private static var __staticMaskShader:Context3DMaskShader;

	@:noCompletion private var __context3D:Context3D;
	@:noCompletion private var __clipRects:Array<Rectangle>;
	@:noCompletion private var __currentDisplayShader:Shader;
	@:noCompletion private var __currentGraphicsShader:Shader;
	@:noCompletion private var __currentRenderTarget:BitmapData;
	@:noCompletion private var __currentShader:Shader;
	@:noCompletion private var __currentShaderBuffer:ShaderBuffer;
	@:noCompletion private var __defaultDisplayShader:DisplayObjectShader;
	@:noCompletion private var __defaultGraphicsShader:GraphicsShader;
	@:noCompletion private var __defaultRenderTarget:BitmapData;
	@:noCompletion private var __defaultShader:Shader;
	@:noCompletion private var __displayHeight:Int;
	@:noCompletion private var __displayWidth:Int;
	@:noCompletion private var __flipped:Bool;
	@SuppressWarnings("checkstyle:Dynamic") @:noCompletion private var __gl:#if lime WebGLRenderContext #else Dynamic #end;
	@:noCompletion private var __height:Int;
	@:noCompletion private var __maskShader:Context3DMaskShader;
	@SuppressWarnings("checkstyle:Dynamic") @:noCompletion private var __matrix:#if lime Matrix4 #else Dynamic #end;
	@:noCompletion private var __maskObjects:Array<DisplayObject>;
	@:noCompletion private var __numClipRects:Int;
	@:noCompletion private var __offsetX:Int;
	@:noCompletion private var __offsetY:Int;
	@:noCompletion private var __projectionScaleX:Float = Math.POSITIVE_INFINITY;
	@:noCompletion private var __projectionScaleY:Float = Math.POSITIVE_INFINITY;
	@:noCompletion private var __scrollRectMasks:ObjectPool<Shape>;
	@:noCompletion private var __softwareRenderer:DisplayObjectRenderer;
	@:noCompletion private var __stencilReference:Int;
	@:noCompletion private var __tempRect:Rectangle;
	@:noCompletion private var __updatedStencil:Bool;
	@:noCompletion private var __upscaled:Bool;
	@:noCompletion private var __values:Array<Float>;
	#if novaflare_threaded_projection_matrix
	private var __queuedProjectionMatrix:ShaderParameter<Float>;
	#end
	#if (novaflare_threaded_projection_matrix && cpp && lime && lime_cffi && !disable_cffi && !optional_cffi && !lime_webgl && !macro && (lime_opengl || lime_opengles))
	private final __projectionInputs:Array<Float> = [];
	#end
	@:noCompletion private var __width:Int;

	@:noCompletion private function new(context:Context3D, defaultRenderTarget:BitmapData = null)
	{
		super();

		__context3D = context;
		__context = context.__context;

		gl = context.__context.webgl;
		__gl = gl;

		this.__defaultRenderTarget = defaultRenderTarget;
		this.__flipped = (__defaultRenderTarget == null);

		if (Graphics.maxTextureWidth == null)
		{
			Graphics.maxTextureWidth = Graphics.maxTextureHeight = __gl.getParameter(__gl.MAX_TEXTURE_SIZE);
		}

		#if lime
		__matrix = new Matrix4();
		#end

		__values = new Array();

		#if gl_debug
		var ext:KHR_debug = __gl.getExtension("KHR_debug");
		if (ext != null)
		{
			gl.enable(ext.DEBUG_OUTPUT);
			gl.enable(ext.DEBUG_OUTPUT_SYNCHRONOUS);
		}
		#end

		#if (js && html5)
		__softwareRenderer = new CanvasRenderer(null);
		#else
		__softwareRenderer = new CairoRenderer(null);
		#end

		#if lime
		__type = OPENGL;
		#end

		__setBlendMode(NORMAL);
		__context3D.__setGLBlend(true);

		__clipRects = new Array();
		__maskObjects = new Array();
		__numClipRects = 0;
		__stencilReference = 0;
		__tempRect = new Rectangle();

		if (__staticDefaultDisplayShader == null) __staticDefaultDisplayShader = new DisplayObjectShader();
		if (__staticDefaultGraphicsShader == null) __staticDefaultGraphicsShader = new GraphicsShader();
		if (__staticMaskShader == null) __staticMaskShader = new Context3DMaskShader();

		__defaultDisplayShader = __staticDefaultDisplayShader;
		__defaultGraphicsShader = __staticDefaultGraphicsShader;
		__defaultShader = __defaultDisplayShader;

		__initShader(__defaultShader);

		__scrollRectMasks = new ObjectPool<Shape>(function() return new Shape());
		__maskShader = __staticMaskShader;
	}

	/**
		Applies an alpha value to the active shader, if compatible with OpenFL core shaders
	**/
	public function applyAlpha(alpha:Float):Void
	{
		__alphaValue[0] = alpha * __worldAlpha;

		if (__currentShaderBuffer != null)
		{
			__currentShaderBuffer.addFloatOverride("openfl_Alpha", __alphaValue);
		}
		else if (__currentShader != null)
		{
			if (__currentShader.__alpha != null) __currentShader.__alpha.value = __alphaValue;
		}
	}

	/**
		Binds a BitmapData object as the first active texture of the current active shader,
		if compatible with OpenFL core shaders
	**/
	public function applyBitmapData(bitmapData:BitmapData, smooth:Bool, repeat:Bool = false):Void
	{
		if (__currentShaderBuffer != null)
		{
			if (bitmapData != null)
			{
				__textureSizeValue[0] = bitmapData.__textureWidth;
				__textureSizeValue[1] = bitmapData.__textureHeight;

				__currentShaderBuffer.addFloatOverride("openfl_TextureSize", __textureSizeValue);
			}
		}
		else if (__currentShader != null)
		{
			if (__currentShader.__bitmap != null)
			{
				__currentShader.__bitmap.input = bitmapData;
				__currentShader.__bitmap.filter = (smooth && __allowSmoothing) ? LINEAR : NEAREST;
				__currentShader.__bitmap.mipFilter = MIPNONE;
				__currentShader.__bitmap.wrap = repeat ? REPEAT : CLAMP;
			}

			if (__currentShader.__texture != null)
			{
				__currentShader.__texture.input = bitmapData;
				__currentShader.__texture.filter = (smooth && __allowSmoothing) ? LINEAR : NEAREST;
				__currentShader.__texture.mipFilter = MIPNONE;
				__currentShader.__texture.wrap = repeat ? REPEAT : CLAMP;
			}

			if (__currentShader.__textureSize != null)
			{
				if (bitmapData != null)
				{
					__textureSizeValue[0] = bitmapData.__textureWidth;
					__textureSizeValue[1] = bitmapData.__textureHeight;

					__currentShader.__textureSize.value = __textureSizeValue;
				}
				else
				{
					__currentShader.__textureSize.value = null;
				}
			}
		}
	}

	/**
		Applies a color transform value to the active shader, if compatible with OpenFL
		core shaders
	**/
	public function applyColorTransform(colorTransform:ColorTransform):Void
	{
		var enabled = (colorTransform != null && !colorTransform.__isDefault(true));
		applyHasColorTransform(enabled);

		if (enabled)
		{
			colorTransform.__setArrays(__colorMultipliersValue, __colorOffsetsValue);

			if (__currentShaderBuffer != null)
			{
				__currentShaderBuffer.addFloatOverride("openfl_ColorMultiplier", __colorMultipliersValue);
				__currentShaderBuffer.addFloatOverride("openfl_ColorOffset", __colorOffsetsValue);
			}
			else if (__currentShader != null)
			{
				if (__currentShader.__colorMultiplier != null) __currentShader.__colorMultiplier.value = __colorMultipliersValue;
				if (__currentShader.__colorOffset != null) __currentShader.__colorOffset.value = __colorOffsetsValue;
			}
		}
		else
		{
			if (__currentShaderBuffer != null)
			{
				__currentShaderBuffer.addFloatOverride("openfl_ColorMultiplier", __emptyColorValue);
				__currentShaderBuffer.addFloatOverride("openfl_ColorOffset", __emptyColorValue);
			}
			else if (__currentShader != null)
			{
				if (__currentShader.__colorMultiplier != null) __currentShader.__colorMultiplier.value = __emptyColorValue;
				if (__currentShader.__colorOffset != null) __currentShader.__colorOffset.value = __emptyColorValue;
			}
		}
	}

	/**
		Applies the "has color transform" uniform value for the active shader, if
		compatible with OpenFL core shaders
	**/
	public function applyHasColorTransform(enabled:Bool):Void
	{
		__hasColorTransformValue[0] = enabled;

		if (__currentShaderBuffer != null)
		{
			__currentShaderBuffer.addBoolOverride("openfl_HasColorTransform", __hasColorTransformValue);
		}
		else if (__currentShader != null)
		{
			if (__currentShader.__hasColorTransform != null) __currentShader.__hasColorTransform.value = __hasColorTransformValue;
		}
	}

	/**
		Applies render matrix to the active shader, if compatible with OpenFL core shaders
	**/
	public function applyMatrix(matrix:Array<Float>):Void
	{
		#if novaflare_threaded_projection_matrix
		__queuedProjectionMatrix = null;
		#end
		if (__currentShaderBuffer != null)
		{
			__currentShaderBuffer.addFloatOverride("openfl_Matrix", matrix);
		}
		else if (__currentShader != null)
		{
			if (__currentShader.__matrix != null) __currentShader.__matrix.value = matrix;
		}
	}

	/**
		Converts an OpenFL two-dimensional matrix to a compatible 3D matrix for use with
		OpenGL rendering. Repeated calls to this method will return the same object with
		new values, so it will need to be cloned if the result must be cached
	**/
	@SuppressWarnings("checkstyle:Dynamic")
	public function getMatrix(transform:Matrix):#if lime Matrix4 #else Dynamic #end
	{
		if (gl != null)
		{
			var values = __getMatrix(transform, AUTO);

			for (i in 0...16)
			{
				__matrix[i] = values[i];
			}

			return __matrix;
		}
		else
		{
			__matrix.identity();
			__matrix[0] = transform.a;
			__matrix[1] = transform.b;
			__matrix[4] = transform.c;
			__matrix[5] = transform.d;
			__matrix[12] = transform.tx;
			__matrix[13] = transform.ty;

			return __matrix;
		}
	}

	/**
		Sets the current active shader, which automatically unbinds the previous shader
		if it was bound using an OpenFL Shader object
	**/
	public function setShader(shader:Shader):Void
	{
		#if novaflare_threaded_projection_matrix
		__queuedProjectionMatrix = null;
		#end
		__currentShaderBuffer = null;

		var sameShader = __currentShader == shader;
		#if mobile
		var boundProgramMatches = shader == null ? __context3D.__state.program == null : __context3D.__state.program == shader.program;
		if (sameShader && boundProgramMatches && (shader == null || !shader.__requiresInit())) return;
		#else
		if (sameShader) return;
		#end

		if (__currentShader != null)
		{
			// TODO: Integrate cleanup with Context3D
			// __currentShader.__disable ();
		}

		if (shader == null)
		{
			__currentShader = null;
			__context3D.setProgram(null);
			// __context3D.__flushGLProgram ();
			return;
		}
		else
		{
			__currentShader = shader;
			#if mobile
			// Consume a converter revision before binding. Rebuilding later in
			// Shader.__enable() would leave Context3D bound to the old program
			// and sampler uniforms would be written to the wrong object.
			shader.__setMobileContext(__context3D);
			if (shader.__requiresInit()) shader.__init();
			#else
			__initShader(shader);
			#end
			__context3D.setProgram(shader.program);
			__context3D.__flushGLProgram();
			// __context3D.__flushGLTextures ();
			__currentShader.__enable();
			__context3D.__state.shader = shader;
		}
	}

	/**
		Updates the current OpenGL viewport using the current OpenFL stage coordinates
	**/
	public function setViewport():Void
	{
		#if nova_stage_render_target
		__context3D.__setStageViewport(__offsetX, __offsetY, __displayWidth, __displayHeight);
		#else
		__gl.viewport(__offsetX, __offsetY, __displayWidth, __displayHeight);
		#end
	}

	/**
		Updates the current active shader with cached alpha, color transform,
		bitmap data and other uniform or attribute values. This should be called in advance
		of rendering
	**/
	public function updateShader():Void
	{
		if (__currentShader != null)
		{
			if (__currentShader.__position != null) __currentShader.__position.__useArray = true;
			if (__currentShader.__textureCoord != null) __currentShader.__textureCoord.__useArray = true;
			__context3D.setProgram(__currentShader.program);
			__context3D.__flushGLProgram();
			__context3D.__flushGLTextures();
			#if novaflare_threaded_projection_matrix
			if (__queuedProjectionMatrix != null)
			{
				__currentShader.__updateWithProjectionMatrix(__queuedProjectionMatrix);
				return;
			}
			#end
			__currentShader.__update();
		}
	}

	/**
		Updates the active shader to expect an alpha array, if the current shader
		is compatible with OpenFL core shaders
	**/
	public function useAlphaArray():Void
	{
		if (__currentShader != null)
		{
			if (__currentShader.__alpha != null) __currentShader.__alpha.__useArray = true;
		}
	}

	/**
		Updates the active shader to expect a color transform array, if the current shader
		is compatible with OpenFL core shaders
	**/
	public function useColorTransformArray():Void
	{
		if (__currentShader != null)
		{
			if (__currentShader.__colorMultiplier != null) __currentShader.__colorMultiplier.__useArray = true;
			if (__currentShader.__colorOffset != null) __currentShader.__colorOffset.__useArray = true;
		}
	}

	@:noCompletion private function __cleanup():Void
	{
		if (__stencilReference > 0)
		{
			__stencilReference = 0;
			__context3D.setStencilActions();
			__context3D.setStencilReferenceValue(0, 0, 0);
		}

		if (__numClipRects > 0)
		{
			__numClipRects = 0;
			__scissorRect();
		}
	}

	@:noCompletion private override function __clear():Void
	{
		if (__stage == null || __stage.__transparent)
		{
			__context3D.clear(0, 0, 0, 0, 0, 0, Context3DClearMask.COLOR);
		}
		else
		{
			__context3D.clear(__stage.__colorSplit[0], __stage.__colorSplit[1], __stage.__colorSplit[2], 1, 0, 0, Context3DClearMask.COLOR);
		}

		__cleared = true;
	}

	@:noCompletion private function __clearShader():Void
	{
		#if novaflare_threaded_projection_matrix
		__queuedProjectionMatrix = null;
		#end
		if (__currentShader != null)
		{
			if (__currentShaderBuffer == null)
			{
				if (__currentShader.__bitmap != null) __currentShader.__bitmap.input = null;
			}
			else
			{
				__currentShaderBuffer.clearOverride();
			}

			if (__currentShader.__texture != null) __currentShader.__texture.input = null;
			if (__currentShader.__textureSize != null) __currentShader.__textureSize.value = null;
			if (__currentShader.__hasColorTransform != null) __currentShader.__hasColorTransform.value = null;
			if (__currentShader.__position != null) __currentShader.__position.value = null;
			if (__currentShader.__matrix != null) __currentShader.__matrix.value = null;
			// Core render paths only enable these five array-backed attributes.
			// Reset them directly so every Graphics batch does not scan all custom
			// shader parameter arrays and create another precise root scope.
			if (__currentShader.__position != null) __currentShader.__position.__useArray = false;
			if (__currentShader.__textureCoord != null) __currentShader.__textureCoord.__useArray = false;
			if (__currentShader.__alpha != null) __currentShader.__alpha.__useArray = false;
			if (__currentShader.__colorMultiplier != null) __currentShader.__colorMultiplier.__useArray = false;
			if (__currentShader.__colorOffset != null) __currentShader.__colorOffset.__useArray = false;
		}
	}

	@:noCompletion private function __copyShader(other:OpenGLRenderer):Void
	{
		#if novaflare_threaded_projection_matrix
		__queuedProjectionMatrix = null;
		#end
		__currentShader = other.__currentShader;
		__currentShaderBuffer = other.__currentShaderBuffer;
		__currentDisplayShader = other.__currentDisplayShader;
		__currentGraphicsShader = other.__currentGraphicsShader;

		// __gl.glProgram = other.__gl.glProgram;
	}

	@:noCompletion private function __applyTransformMatrix(transform:Matrix, pixelSnapping:PixelSnapping):Void
	{
		#if (novaflare_threaded_projection_matrix && cpp && lime && lime_cffi && !disable_cffi && !optional_cffi && !lime_webgl && !macro && (lime_opengl || lime_opengles))
		if (__tryQueueProjectionMatrix(transform, pixelSnapping)) return;
		#end
		applyMatrix(__getMatrix(transform, pixelSnapping));
	}

	#if (novaflare_threaded_projection_matrix && cpp && lime && lime_cffi && !disable_cffi && !optional_cffi && !lime_webgl && !macro && (lime_opengl || lime_opengles))
	private function __tryQueueProjectionMatrix(transform:Matrix, pixelSnapping:PixelSnapping):Bool
	{
		final shader = __currentShader;
		if (shader == null || shader.__context != __context3D) return false;
		#if CODENAME_ENGINE_COMPAT
		// onGLUpdate listeners can inspect or replace the matrix before the shader uploads it.
		if (shader is codename.funkin.backend.shaders.FunkinShader) return false;
		#end

		final parameter = shader.__matrix;
		if (parameter == null || !parameter.__isUniform || parameter.type != MATRIX4X4 || parameter.index == null) return false;
		final location:Int = parameter.index;
		if (location < 0) return false;

		// The recorded program bind must precede the GL uniform command in the same queue.
		final program = shader.program;
		if (program == null || __context3D.__state.program != program || __context3D.__contextState.program != program) return false;

		final world = __worldTransform;
		final values = __projectionInputs;
		values[0] = transform.a;
		values[1] = transform.b;
		values[2] = transform.c;
		values[3] = transform.d;
		values[4] = transform.tx;
		values[5] = transform.ty;
		values[6] = world.a;
		values[7] = world.b;
		values[8] = world.c;
		values[9] = world.d;
		values[10] = world.tx;
		values[11] = world.ty;
		values[12] = __projectionScaleX;
		values[13] = __projectionScaleY;
		final snappingMode = switch (pixelSnapping)
		{
			case ALWAYS: 2;
			case AUTO: 1;
			default: 0;
		}
		final flags = snappingMode | (__flipped ? 4 : 0);
		if (!lime._internal.backend.native.NativeCFFI.tryQueueProjectionMatrix(location, values, flags)) return false;

		__queuedProjectionMatrix = parameter;
		return true;
	}
	#end

	@:noCompletion private function __getMatrix(transform:Matrix, pixelSnapping:PixelSnapping):Array<Float>
	{
		var _matrix = Matrix.__pool.get();
		_matrix.copyFrom(transform);
		_matrix.concat(__worldTransform);

		if (pixelSnapping == ALWAYS
			|| (pixelSnapping == AUTO
				&& _matrix.b == 0
				&& _matrix.c == 0
				&& (_matrix.a < 1.001 && _matrix.a > 0.999)
				&& (_matrix.d < 1.001 && _matrix.d > 0.999)))
		{
			_matrix.tx = Math.round(_matrix.tx);
			_matrix.ty = Math.round(_matrix.ty);
		}

		// The renderer projection is always the orthographic matrix created in
		// __resize. Building a temporary Matrix4 used to perform dozens of
		// individual Float32Array reads/writes here. On a moving collector each
		// scalar access has to pin the backing byte array, which dominated complex
		// UI pages. Multiply the 2D transform by that sparse projection directly.
		var projectionX = __projectionScaleX;
		var projectionY = __flipped ? -__projectionScaleY : __projectionScaleY;

		__values[0] = _matrix.a * projectionX;
		__values[1] = _matrix.b * projectionY;
		__values[2] = 0;
		__values[3] = 0;
		__values[4] = _matrix.c * projectionX;
		__values[5] = _matrix.d * projectionY;
		__values[6] = 0;
		__values[7] = 0;
		__values[8] = 0;
		__values[9] = 0;
		__values[10] = -0.001;
		__values[11] = 0;
		__values[12] = _matrix.tx * projectionX - 1;
		__values[13] = _matrix.ty * projectionY + (__flipped ? 1 : -1);
		__values[14] = 0;
		__values[15] = 1;

		Matrix.__pool.release(_matrix);

		return __values;
	}

	@:noCompletion private function __initShader(shader:Shader):Shader
	{
		if (shader != null)
		{
			// TODO: Change of GL context?

			#if mobile
			if (shader.__context != __context3D)
			{
				shader.__setMobileContext(__context3D);
				shader.__init();
			}
			#else
			if (shader.__context == null)
			{
				shader.__context = __context3D;
				shader.__init();
			}
			#end

			// currentShader = shader;
			return shader;
		}

		return __defaultShader;
	}

	@:noCompletion private function __initDisplayShader(shader:Shader):Shader
	{
		if (shader != null)
		{
			// TODO: Change of GL context?

			#if mobile
			if (shader.__context != __context3D)
			{
				shader.__setMobileContext(__context3D);
				shader.__init();
			}
			#else
			if (shader.__context == null)
			{
				shader.__context = __context3D;
				shader.__init();
			}
			#end

			// currentShader = shader;
			return shader;
		}

		return __defaultDisplayShader;
	}

	@:noCompletion private function __initGraphicsShader(shader:Shader):Shader
	{
		if (shader != null)
		{
			// TODO: Change of GL context?

			#if mobile
			if (shader.__context != __context3D)
			{
				shader.__setMobileContext(__context3D);
				shader.__init();
			}
			#else
			if (shader.__context == null)
			{
				shader.__context = __context3D;
				shader.__init();
			}
			#end

			// currentShader = shader;
			return shader;
		}

		return __defaultGraphicsShader;
	}

	@:noCompletion private function __initShaderBuffer(shaderBuffer:ShaderBuffer):Shader
	{
		if (shaderBuffer != null)
		{
			return __initGraphicsShader(shaderBuffer.shader);
		}

		return __defaultGraphicsShader;
	}

	@:noCompletion private override function __popMask():Void
	{
		if (__stencilReference == 0) return;

		var mask = __maskObjects.pop();

		if (__stencilReference > 1)
		{
			__context3D.setStencilActions(FRONT_AND_BACK, EQUAL, DECREMENT_SATURATE, DECREMENT_SATURATE, KEEP);
			__context3D.setStencilReferenceValue(__stencilReference, 0xFF, 0xFF);
			__context3D.setColorMask(false, false, false, false);

			__renderDrawableMask(mask);
			__stencilReference--;

			__context3D.setStencilActions(FRONT_AND_BACK, EQUAL, KEEP, KEEP, KEEP);
			__context3D.setStencilReferenceValue(__stencilReference, 0xFF, 0);
			__context3D.setColorMask(true, true, true, true);
		}
		else
		{
			__stencilReference = 0;
			__context3D.setStencilActions();
			__context3D.setStencilReferenceValue(0, 0, 0);
		}
	}

	@:noCompletion private override function __popMaskObject(object:DisplayObject, handleScrollRect:Bool = true):Void
	{
		if (object.__mask != null)
		{
			__popMask();
		}

		if (handleScrollRect && object.__scrollRect != null)
		{
			if (object.__renderTransform.b != 0 || object.__renderTransform.c != 0)
			{
				__scrollRectMasks.release(cast __maskObjects[__maskObjects.length - 1]);
				__popMask();
			}
			else
			{
				__popMaskRect();
			}
		}
	}

	@:noCompletion private override function __popMaskRect():Void
	{
		if (__numClipRects > 0)
		{
			__numClipRects--;

			if (__numClipRects > 0)
			{
				__scissorRect(__clipRects[__numClipRects - 1]);
			}
			else
			{
				__scissorRect();
			}
		}
	}

	@:noCompletion private override function __pushMask(mask:DisplayObject):Void
	{
		if (__stencilReference == 0)
		{
			__context3D.clear(0, 0, 0, 0, 0, 0, Context3DClearMask.STENCIL);
			__updatedStencil = true;
		}

		__context3D.setStencilActions(FRONT_AND_BACK, EQUAL, INCREMENT_SATURATE, KEEP, KEEP);
		__context3D.setStencilReferenceValue(__stencilReference, 0xFF, 0xFF);
		__context3D.setColorMask(false, false, false, false);

		__renderDrawableMask(mask);
		__maskObjects.push(mask);
		__stencilReference++;

		__context3D.setStencilActions(FRONT_AND_BACK, EQUAL, KEEP, KEEP, KEEP);
		__context3D.setStencilReferenceValue(__stencilReference, 0xFF, 0);
		__context3D.setColorMask(true, true, true, true);
	}

	@:noCompletion private override function __pushMaskObject(object:DisplayObject, handleScrollRect:Bool = true):Void
	{
		if (handleScrollRect && object.__scrollRect != null)
		{
			if (object.__renderTransform.b != 0 || object.__renderTransform.c != 0)
			{
				var shape = __scrollRectMasks.get();
				shape.graphics.clear();
				shape.graphics.beginFill(0x00FF00);
				shape.graphics.drawRect(object.__scrollRect.x, object.__scrollRect.y, object.__scrollRect.width, object.__scrollRect.height);
				shape.__renderTransform.copyFrom(object.__renderTransform);
				__pushMask(shape);
			}
			else
			{
				__pushMaskRect(object.__scrollRect, object.__renderTransform);
			}
		}

		if (object.__mask != null)
		{
			__pushMask(object.__mask);
		}
	}

	@:noCompletion private override function __pushMaskRect(rect:Rectangle, transform:Matrix):Void
	{
		// TODO: Handle rotation?

		if (__numClipRects == __clipRects.length)
		{
			__clipRects[__numClipRects] = new Rectangle();
		}

		var _matrix = Matrix.__pool.get();
		_matrix.copyFrom(transform);
		_matrix.concat(__worldTransform);

		var clipRect = __clipRects[__numClipRects];
		rect.__transform(clipRect, _matrix);

		if (__numClipRects > 0)
		{
			var parentClipRect = __clipRects[__numClipRects - 1];
			clipRect.__contract(parentClipRect.x, parentClipRect.y, parentClipRect.width, parentClipRect.height);
		}

		if (clipRect.height < 0)
		{
			clipRect.height = 0;
		}

		if (clipRect.width < 0)
		{
			clipRect.width = 0;
		}

		Matrix.__pool.release(_matrix);

		__scissorRect(clipRect);
		__numClipRects++;
	}

	@:noCompletion private override function __render(object:IBitmapDrawable):Void
	{
		#if sys
		var __novaStarted = __novaPerfTrace ? haxe.Timer.stamp() : 0.0;
		var __novaBeforeDrawable = 0.0;
		var __novaAfterDrawable = 0.0;
		#end
		__context3D.setColorMask(true, true, true, true);
		__context3D.setCulling(NONE);
		__context3D.setDepthTest(false, ALWAYS);
		__context3D.setStencilActions();
		__context3D.setStencilReferenceValue(0, 0, 0);
		__context3D.setScissorRectangle(null);

		__blendMode = null;
		__setBlendMode(NORMAL);

		if (__defaultRenderTarget == null)
		{
			#if openfl_dpi_aware
			__scissorRectangle.setTo(__offsetX, __offsetY, __displayWidth, __displayHeight);
			#else
			if (__context3D.__backBufferWantsBestResolution)
			{
				__scissorRectangle.setTo(__offsetX / __pixelRatio, __offsetY / __pixelRatio, __displayWidth / __pixelRatio, __displayHeight / __pixelRatio);
			}
			else
			{
				__scissorRectangle.setTo(__offsetX, __offsetY, __displayWidth, __displayHeight);
			}
			#end
			__context3D.setScissorRectangle(__scissorRectangle);

			__upscaled = (__worldTransform.a != 1 || __worldTransform.d != 1);

			#if sys
			if (__novaPerfTrace) __novaBeforeDrawable = haxe.Timer.stamp();
			#end
			__renderDrawable(object);
			#if sys
			if (__novaPerfTrace) __novaAfterDrawable = haxe.Timer.stamp();
			#end

			// TODO: Handle this in Context3D as a viewport?

			if (__offsetX > 0 || __offsetY > 0)
			{
				// __context3D.__setGLScissorTest (true);

				if (__offsetX > 0)
				{
					// __gl.scissor (0, 0, __offsetX, __height);
					__scissorRectangle.setTo(0, 0, __offsetX, __height);
					__context3D.setScissorRectangle(__scissorRectangle);

					__context3D.__flushGL();
					__gl.clearColor(0, 0, 0, 1);
					__gl.clear(__gl.COLOR_BUFFER_BIT);
					// __context3D.clear (0, 0, 0, 1, 0, 0, Context3DClearMask.COLOR);

					// __gl.scissor (__offsetX + __displayWidth, 0, __width, __height);
					__scissorRectangle.setTo(__offsetX + __displayWidth, 0, __width, __height);
					__context3D.setScissorRectangle(__scissorRectangle);

					__context3D.__flushGL();
					__gl.clearColor(0, 0, 0, 1);
					__gl.clear(__gl.COLOR_BUFFER_BIT);
					// __context3D.clear (0, 0, 0, 1, 0, 0, Context3DClearMask.COLOR);
				}

				if (__offsetY > 0)
				{
					// __gl.scissor (0, 0, __width, __offsetY);
					__scissorRectangle.setTo(0, 0, __width, __offsetY);
					__context3D.setScissorRectangle(__scissorRectangle);

					__context3D.__flushGL();
					__gl.clearColor(0, 0, 0, 1);
					__gl.clear(__gl.COLOR_BUFFER_BIT);
					// __context3D.clear (0, 0, 0, 1, 0, 0, Context3DClearMask.COLOR);

					// __gl.scissor (0, __offsetY + __displayHeight, __width, __height);
					__scissorRectangle.setTo(0, __offsetY + __displayHeight, __width, __height);
					__context3D.setScissorRectangle(__scissorRectangle);

					__context3D.__flushGL();
					__gl.clearColor(0, 0, 0, 1);
					__gl.clear(__gl.COLOR_BUFFER_BIT);
					// __context3D.clear (0, 0, 0, 1, 0, 0, Context3DClearMask.COLOR);
				}

				__context3D.setScissorRectangle(null);
			}
		}
		else
		{
			#if openfl_dpi_aware
			__scissorRectangle.setTo(__offsetX, __offsetY, __displayWidth, __displayHeight);
			#else
			if (__context3D.__backBufferWantsBestResolution)
			{
				__scissorRectangle.setTo(__offsetX / __pixelRatio, __offsetY / __pixelRatio, __displayWidth / __pixelRatio, __displayHeight / __pixelRatio);
			}
			else
			{
				__scissorRectangle.setTo(__offsetX, __offsetY, __displayWidth, __displayHeight);
			}
			#end
			__context3D.setScissorRectangle(__scissorRectangle);
			// __gl.viewport (__offsetX, __offsetY, __displayWidth, __displayHeight);

			// __upscaled = (__worldTransform.a != 1 || __worldTransform.d != 1);

			// TODO: Cleaner approach?

			var cacheMask = object.__mask;
			var cacheScrollRect = object.__scrollRect;
			object.__mask = null;
			object.__scrollRect = null;

			#if sys
			if (__novaPerfTrace) __novaBeforeDrawable = haxe.Timer.stamp();
			#end
			__renderDrawable(object);
			#if sys
			if (__novaPerfTrace) __novaAfterDrawable = haxe.Timer.stamp();
			#end

			object.__mask = cacheMask;
			object.__scrollRect = cacheScrollRect;
		}

		__context3D.present();
		#if sys
		if (__novaPerfTrace)
		{
			var __novaEnded = haxe.Timer.stamp();
			var __novaTotal = __novaEnded - __novaStarted;
			var __novaSetup = __novaBeforeDrawable - __novaStarted;
			var __novaDrawable = __novaAfterDrawable - __novaBeforeDrawable;
			var __novaPresent = __novaEnded - __novaAfterDrawable;
			if (__novaPerfWindowStart == 0.0) __novaPerfWindowStart = __novaStarted;
			__novaPerfCount++;
			__novaPerfTotal += __novaTotal;
			__novaPerfSetup += __novaSetup;
			__novaPerfDrawable += __novaDrawable;
			__novaPerfPresent += __novaPresent;
			if (__novaTotal > __novaPerfMax) __novaPerfMax = __novaTotal;
			if (__novaEnded - __novaPerfWindowStart >= 1.0)
			{
				var __novaScale = 1000000.0 / __novaPerfCount;
				Sys.println('perf:OpenGLRenderer.avg frames=$__novaPerfCount total_us=${Math.round(__novaPerfTotal * __novaScale)} setup_us=${Math.round(__novaPerfSetup * __novaScale)} drawable_us=${Math.round(__novaPerfDrawable * __novaScale)} present_us=${Math.round(__novaPerfPresent * __novaScale)} max_us=${Math.round(__novaPerfMax * 1000000)}');
				__novaPerfWindowStart = __novaEnded;
				__novaPerfCount = 0;
				__novaPerfTotal = __novaPerfSetup = __novaPerfDrawable = __novaPerfPresent = __novaPerfMax = 0.0;
			}
		}
		#end
	}

	@:noCompletion private function __renderDrawable(object:IBitmapDrawable):Void
	{
		if (object == null) return;

		// IBitmapDrawable fields are dynamic at the generated C++ ABI. Walking
		// DisplayObject.__Field (and its long strcmp chain) once for every child
		// dominated simple scenes. BitmapData is the only non-DisplayObject
		// implementation, so split it once at the public render boundary and use
		// direct typed field access throughout the display list.
		if (Std.isOfType(object, BitmapData))
		{
			Context3DBitmapData.renderDrawable(cast object, this);
			return;
		}

		__renderDisplayObject(cast object);
	}

	@:noCompletion private function __renderDisplayObject(object:DisplayObject):Void
	{
		if (object == null) return;

		switch (object.__drawableType)
		{
			case STAGE, SPRITE:
				Context3DDisplayObjectContainer.renderDrawable(cast object, this);
			case BITMAP:
				Context3DBitmap.renderDrawable(cast object, this);
			case SHAPE:
				Context3DDisplayObject.renderDrawable(cast object, this);
			case SIMPLE_BUTTON:
				Context3DSimpleButton.renderDrawable(cast object, this);
			case TEXT_FIELD:
				Context3DTextField.renderDrawable(cast object, this);
			case VIDEO:
				Context3DVideo.renderDrawable(cast object, this);
			case TILEMAP:
				Context3DTilemap.renderDrawable(cast object, this);
			default:
		}
	}

	@:noCompletion private function __renderDrawableMask(object:IBitmapDrawable):Void
	{
		if (object == null) return;

		if (Std.isOfType(object, BitmapData))
		{
			Context3DBitmapData.renderDrawableMask(cast object, this);
			return;
		}

		__renderDisplayObjectMask(cast object);
	}

	@:noCompletion private function __renderDisplayObjectMask(object:DisplayObject):Void
	{
		if (object == null) return;

		switch (object.__drawableType)
		{
			case STAGE, SPRITE:
				Context3DDisplayObjectContainer.renderDrawableMask(cast object, this);
			case BITMAP:
				Context3DBitmap.renderDrawableMask(cast object, this);
			case SHAPE:
				Context3DDisplayObject.renderDrawableMask(cast object, this);
			case SIMPLE_BUTTON:
				Context3DSimpleButton.renderDrawableMask(cast object, this);
			case TEXT_FIELD:
				Context3DTextField.renderDrawableMask(cast object, this);
			case VIDEO:
				Context3DVideo.renderDrawableMask(cast object, this);
			case TILEMAP:
				Context3DTilemap.renderDrawableMask(cast object, this);
			default:
		}
	}

	@:noCompletion private function __renderFilterPass(source:BitmapData, shader:Shader, smooth:Bool, clear:Bool = true):Void
	{
		if (source == null || shader == null) return;
		if (__defaultRenderTarget == null) return;

		var cacheRTT = __context3D.__state.renderToTexture;
		var cacheRTTDepthStencil = __context3D.__state.renderToTextureDepthStencil;
		var cacheRTTAntiAlias = __context3D.__state.renderToTextureAntiAlias;
		var cacheRTTSurfaceSelector = __context3D.__state.renderToTextureSurfaceSelector;

		__context3D.setRenderToTexture(__defaultRenderTarget.getTexture(__context3D), false);

		if (clear)
		{
			__context3D.clear(0, 0, 0, 0, 0, 0, Context3DClearMask.COLOR);
		}

		var shader = __initShader(shader);
		setShader(shader);
		applyAlpha(1);
		applyBitmapData(source, smooth);
		applyColorTransform(null);
		__applyTransformMatrix(source.__renderTransform, AUTO);
		updateShader();

		var vertexBuffer = source.getVertexBuffer(__context3D);
		if (shader.__position != null) __context3D.setVertexBufferAt(shader.__position.index, vertexBuffer, 0, FLOAT_3);
		if (shader.__textureCoord != null) __context3D.setVertexBufferAt(shader.__textureCoord.index, vertexBuffer, 3, FLOAT_2);
		var indexBuffer = source.getIndexBuffer(__context3D);
		__context3D.drawTriangles(indexBuffer);

		if (cacheRTT != null)
		{
			__context3D.setRenderToTexture(cacheRTT, cacheRTTDepthStencil, cacheRTTAntiAlias, cacheRTTSurfaceSelector);
		}
		else
		{
			__context3D.setRenderToBackBuffer();
		}

		__clearShader();
	}

	@:noCompletion private override function __resize(width:Int, height:Int):Void
	{
		__width = width;
		__height = height;

		var w = (__defaultRenderTarget == null) ? __stage.stageWidth : __defaultRenderTarget.width;
		var h = (__defaultRenderTarget == null) ? __stage.stageHeight : __defaultRenderTarget.height;

		__offsetX = __defaultRenderTarget == null ? Math.round(__worldTransform.__transformX(0, 0)) : 0;
		__offsetY = __defaultRenderTarget == null ? Math.round(__worldTransform.__transformY(0, 0)) : 0;
		__displayWidth = __defaultRenderTarget == null ? Math.round(__worldTransform.__transformX(w, 0) - __offsetX) : w;
		__displayHeight = __defaultRenderTarget == null ? Math.round(__worldTransform.__transformY(0, h) - __offsetY) : h;

		__projectionScaleX = 2.0 / (__displayWidth + __offsetX * 2);
		__projectionScaleY = 2.0 / (__displayHeight + __offsetY * 2);
	}

	@:noCompletion private function __resumeClipAndMask(childRenderer:OpenGLRenderer):Void
	{
		if (__stencilReference > 0)
		{
			__context3D.setStencilActions(FRONT_AND_BACK, EQUAL, KEEP, KEEP, KEEP);
			__context3D.setStencilReferenceValue(__stencilReference, 0xFF, 0);
		}
		else
		{
			__context3D.setStencilActions();
			__context3D.setStencilReferenceValue(0, 0, 0);
		}

		if (__numClipRects > 0)
		{
			__scissorRect(__clipRects[__numClipRects - 1]);
		}
		else
		{
			__scissorRect();
		}
	}

	@:noCompletion private function __scissorRect(clipRect:Rectangle = null):Void
	{
		if (clipRect != null)
		{
			var x = Math.ffloor(clipRect.x);
			var y = Math.ffloor(clipRect.y);
			var width = (clipRect.width > 0 ? Math.fceil(clipRect.right) - x : 0);
			var height = (clipRect.height > 0 ? Math.fceil(clipRect.bottom) - y : 0);
			#if !openfl_dpi_aware
			if (__context3D.__backBufferWantsBestResolution)
			{
				var uv = 1.5 / __pixelRatio;
				x = clipRect.x / __pixelRatio;
				y = clipRect.y / __pixelRatio;
				width = (clipRect.width > 0 ? (clipRect.right / __pixelRatio) - x + uv : 0);
				height = (clipRect.height > 0 ? (clipRect.bottom / __pixelRatio) - y + uv : 0);
			}
			#end

			if (width < 0) width = 0;
			if (height < 0) height = 0;

			// __scissorRectangle.setTo (x, __flipped ? __height - y - height : y, width, height);
			__scissorRectangle.setTo(x, y, width, height);
			__context3D.setScissorRectangle(__scissorRectangle);
		}
		else
		{
			__context3D.setScissorRectangle(null);
		}
	}

	@:noCompletion private override function __setBlendMode(value:BlendMode):Void
	{
		if (__overrideBlendMode != null) value = __overrideBlendMode;
		if (__blendMode == value) return;

		__blendMode = value;

		switch (value)
		{
			case ADD:
				__context3D.setBlendFactors(ONE, ONE);

			case MULTIPLY:
				__context3D.setBlendFactors(DESTINATION_COLOR, ONE_MINUS_SOURCE_ALPHA);

			case SCREEN:
				__context3D.setBlendFactors(ONE, ONE_MINUS_SOURCE_COLOR);

			case SUBTRACT:
				__context3D.setBlendFactors(ONE, ONE);
				__context3D.__setGLBlendEquation(__gl.FUNC_REVERSE_SUBTRACT);

			#if desktop
			case DARKEN:
				__context3D.setBlendFactors(ONE, ONE);
				__context3D.__setGLBlendEquation(0x8007); // GL_MIN

			case LIGHTEN:
				__context3D.setBlendFactors(ONE, ONE);
				__context3D.__setGLBlendEquation(0x8008); // GL_MAX
			#end

			default:
				__context3D.setBlendFactors(ONE, ONE_MINUS_SOURCE_ALPHA);
		}
	}

	@:noCompletion private function __setRenderTarget(renderTarget:BitmapData):Void
	{
		__defaultRenderTarget = renderTarget;
		__flipped = (renderTarget == null);

		if (renderTarget != null)
		{
			__resize(renderTarget.width, renderTarget.height);
		}
	}

	@:noCompletion private function __setShaderBuffer(shaderBuffer:ShaderBuffer):Void
	{
		setShader(shaderBuffer.shader);
		__currentShaderBuffer = shaderBuffer;
	}

	@:noCompletion private function __suspendClipAndMask():Void
	{
		if (__stencilReference > 0)
		{
			__context3D.setStencilActions();
			__context3D.setStencilReferenceValue(0, 0, 0);
		}

		if (__numClipRects > 0)
		{
			__scissorRect();
		}
	}

	@:noCompletion private function __updateShaderBuffer(bufferOffset:Int):Void
	{
		if (__currentShader != null && __currentShaderBuffer != null)
		{
			#if novaflare_threaded_projection_matrix
			if (__queuedProjectionMatrix != null)
			{
				__currentShader.__updateWithProjectionMatrix(__queuedProjectionMatrix, __currentShaderBuffer, bufferOffset);
				return;
			}
			#end
			__currentShader.__updateFromBuffer(__currentShaderBuffer, bufferOffset);
		}
	}
}
#else
typedef OpenGLRenderer = Dynamic;
#end
