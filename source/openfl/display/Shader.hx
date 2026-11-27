package openfl.display;

#if !flash
import openfl.display3D._internal.GLProgram;
import openfl.display3D._internal.GLShader;
import openfl.display._internal.ShaderBuffer;
import openfl.utils._internal.Float32Array;
import openfl.utils._internal.Log;
import openfl.display3D.Context3D;
import openfl.display3D.Program3D;
import openfl.utils.ByteArray;

#if cpp
import sys.thread.Tls;
#end

#if (cpp && lime_cffi && (lime_opengl || lime_opengles) && !lime_webgl && !disable_cffi)
import haxe.ds.WeakMap;
import lime.graphics.opengl.GL.GLObject;
#end

#if mobile
import general.shaders.MobileShaderConverter;
#end

#if (cpp && lime_cffi && (lime_opengl || lime_opengles) && !lime_webgl && !disable_cffi)
private typedef ShaderBindingLocations = {
	final uniforms:Map<String, Int>;
	final attributes:Map<String, Int>;
}
#end

/**
	// TODO: Document GLSL Shaders
	A Shader instance represents a Pixel Bender shader kernel in ActionScript.
	To use a shader in your application, you create a Shader instance for it.
	You then use that Shader instance in the appropriate way according to the
	effect you want to create. For example, to use the shader as a filter, you
	assign the Shader instance to the `shader` property of a ShaderFilter
	object.
	A shader defines a function that executes on all the pixels in an image,
	one pixel at a time. The result of each call to the function is the output
	color at that pixel coordinate in the image. A shader can specify one or
	more input images, which are images whose content can be used in
	determining the output of the function. A shader can also specify one or
	more parameters, which are input values that can be used in calculating
	the function output. In a single shader execution, the input and parameter
	values are constant. The only thing that varies is the coordinate of the
	pixel whose color is the function result. Shader function calls for
	multiple output pixel coordinates execute in parallel to improve shader
	execution performance.

	The shader bytecode can be loaded at run time using a URLLoader instance.
	The following example demonstrates loading a shader bytecode file at run
	time and linking it to a Shader instance.

	```as3
	var loader:URLLoader = new URLLoader();
	loader.dataFormat = URLLoaderDataFormat.BINARY;
	loader.addEventListener(Event.COMPLETE, onLoadComplete);
	loader.load(new URLRequest("myShader.pbj"));
	var shader:Shader;

	function onLoadComplete(event:Event):void {
		// Create a new shader and set the loaded data as its bytecode
		shader = new Shader();
		shader.byteCode = loader.data;

		// You can also pass the bytecode to the Shader() constructor like this:
		// shader = new Shader(loader.data);

		// do something with the shader
	}
	```

	You can also embed the shader into the SWF at compile time using the
	`[Embed]` metadata tag. The `[Embed]` metadata tag is only available if
	you use the Flex SDK to compile the SWF. The `[Embed]` tag's `source`
	parameter points to the shader file, and its `mimeType` parameter is
	`"application/octet-stream"`, as in this example:

	```as3
	[Embed(source="myShader.pbj", mimeType="application/octet-stream)] var MyShaderClass:Class;

	// ...

	// create a new shader and set the embedded shader as its bytecode var
	shaderShader = new Shader();
	shader.byteCode = new MyShaderClass();

	// You can also pass the bytecode to the Shader() constructor like this:
	// var shader:Shader = new Shader(new MyShaderClass());

	// do something with the shader
	```

	In either case, you link the raw shader (the `URLLoader.data` property or
	an instance of the `[Embed]` data class) to the Shader instance. As the
	previous examples demonstrate, you can do this in two ways. You can pass
	the shader bytecode as an argument to the `Shader()` constructor.
	Alternatively, you can set it as the Shader instance's `byteCode`
	property.

	Once a Shader instance is created, it can be used in one of several ways:

	* A shader fill: The output of the shader is used as a fill for content
	drawn with the drawing API. Pass the Shader instance as an argument to the
	`Graphics.beginShaderFill()` method.
	* A shader filter: The output of the shader is used as a graphic filter
	applied to a display object. Assign the Shader instance to the `shader`
	property of a ShaderFilter instance.
	* A blend mode: The output of the shader is rendered as the blending
	between two overlapping display objects. Assign the Shader instance to the
	`blendShader` property of the upper of the two display objects.
	* Background shader processing: The shader executes in the background,
	avoiding the possibility of freezing the display, and dispatches an event
	when processing is complete. Assign the Shader instance to the `shader`
	property of a ShaderJob instance.

	Shader fills, filters, and blends are not supported under GPU rendering.

	**Mobile Browser Support:** This feature is not supported in mobile
	browsers.

	_Adobe AIR profile support:_ This feature is supported on all desktop operating
	systems, but it is not supported on all mobile devices. It is not
	supported on AIR for TV devices. See
	[AIR Profile Support](https://help.adobe.com/en_US/air/build/WS144092a96ffef7cc16ddeea2126bb46b82f-8000.html)
	for more information regarding API support across multiple profiles.
**/
#if !openfl_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end
@:access(openfl.display3D.Context3D)
@:access(openfl.display3D.Program3D)
@:access(openfl.display.ShaderInput)
@:access(openfl.display.ShaderParameter)
// #if (!display && !macro)
#if !macro
@:autoBuild(openfl.utils._internal.ShaderMacro.build())
#end
class Shader
{
	#if (cpp && lime_cffi && (lime_opengl || lime_opengles) && !lime_webgl && !disable_cffi)
	static final __glBindingLocations = new WeakMap<GLObject, ShaderBindingLocations>();
	#end

	/**
		The raw shader bytecode for this Shader instance.
	**/
	public var byteCode(null, default):ByteArray;

	/**
		Provides access to parameters, input images, and metadata for the
		Shader instance. ShaderParameter objects representing parameters for
		the shader, ShaderInput objects representing the input images for the
		shader, and other values representing the shader's metadata are
		dynamically added as properties of the `data` property object when the
		Shader instance is created. Those properties can be used to introspect
		the shader and to set parameter and input values.
		For information about accessing and manipulating the dynamic
		properties of the `data` object, see the ShaderData class description.
	**/
	public var data(get, set):ShaderData;

	/**
		Get or set the fragment source used when compiling with GLSL.

		This property is not available on the Flash target.
	**/
	public var glFragmentSource(get, set):String;

	/**
		The compiled GLProgram if available.

		This property is not available on the Flash target.
	**/
	@SuppressWarnings("checkstyle:Dynamic") public var glProgram(default, null):GLProgram;

	/**
		Get or set the vertex source used when compiling with GLSL.

		This property is not available on the Flash target.
	**/
	public var glVertexSource(get, set):String;

	/**
		The precision of math operations performed by the shader.
		The set of possible values for the `precisionHint` property is defined
		by the constants in the ShaderPrecision class.

		The default value is `ShaderPrecision.FULL`. Setting the precision to
		`ShaderPrecision.FAST` can speed up math operations at the expense of
		precision.

		Full precision mode (`ShaderPrecision.FULL`) computes all math
		operations to the full width of the IEEE 32-bit floating standard and
		provides consistent behavior on all platforms. In this mode, some math
		operations such as trigonometric and exponential functions can be
		slow.

		Fast precision mode (`ShaderPrecision.FAST`) is designed for maximum
		performance but does not work consistently on different platforms and
		individual CPU configurations. In many cases, this level of precision
		is sufficient to create graphic effects without visible artifacts.

		The precision mode selection affects the following shader operations.
		These operations are faster on an Intel processor with the SSE
		instruction set:

		* `sin(x)`
		* `cos(x)`
		* `tan(x)`
		* `asin(x)`
		* `acos(x)`
		* `atan(x)`
		* `atan(x, y)`
		* `exp(x)`
		* `exp2(x)`
		* `log(x)`
		* `log2(x)`
		* `pow(x, y)`
		* `reciprocal(x)`
		* `sqrt(x)`
	**/
	public var precisionHint:ShaderPrecision;

	/**
		The compiled Program3D if available.

		This property is not available on the Flash target.
	**/
	public var program:Program3D;

	@:noCompletion private var __alpha:ShaderParameter<Float>;
	@:noCompletion private var __bitmap:ShaderInput<BitmapData>;
	@:noCompletion private var __colorMultiplier:ShaderParameter<Float>;
	@:noCompletion private var __colorOffset:ShaderParameter<Float>;
	@:noCompletion private var __context:Context3D;
	@:noCompletion private var __data:ShaderData;
	@:noCompletion private var __glFragmentSource:String;
	@:noCompletion private var __glSourceDirty:Bool;
	@:noCompletion private var __glVertexSource:String;
	#if mobile
	@:noCompletion private var __glProgramDirty:Bool;
	@:noCompletion private var __glRawFragmentSource:String;
	@:noCompletion private var __glRawVertexSource:String;
	@:noCompletion private var __glTransformRevision:Int;
	#end
	@:noCompletion private var __hasColorTransform:ShaderParameter<Bool>;
	@:noCompletion private var __inputBitmapData:Array<ShaderInput<BitmapData>>;
	@:noCompletion private var __isGenerated:Bool;
	@:noCompletion private var __matrix:ShaderParameter<Float>;
	#if novaflare_threaded_projection_matrix
	private var __activeProjectionMatrix:ShaderParameter<Float>;
	#end
	@:noCompletion private var __numPasses:Int;
	@:noCompletion private var __paramBool:Array<ShaderParameter<Bool>>;
	@:noCompletion private var __paramFloat:Array<ShaderParameter<Float>>;
	@:noCompletion private var __paramInt:Array<ShaderParameter<Int>>;
	@:noCompletion private var __position:ShaderParameter<Float>;
	@:noCompletion private var __textureCoord:ShaderParameter<Float>;
	@:noCompletion private var __texture:ShaderInput<BitmapData>;
	@:noCompletion private var __textureSize:ShaderParameter<Float>;

	#if openfljs
	@:noCompletion private static function __init__()
	{
		untyped Object.defineProperties(Shader.prototype, {
			"data": {
				get: untyped #if haxe4 js.Syntax.code #else __js__ #end ("function () { return this.get_data (); }"),
				set: untyped #if haxe4 js.Syntax.code #else __js__ #end ("function (v) { return this.set_data (v); }")
			},
			"glFragmentSource": {
				get: untyped #if haxe4 js.Syntax.code #else __js__ #end ("function () { return this.get_glFragmentSource (); }"),
				set: untyped #if haxe4 js.Syntax.code #else __js__ #end ("function (v) { return this.set_glFragmentSource (v); }")
			},
			"glVertexSource": {
				get: untyped #if haxe4 js.Syntax.code #else __js__ #end ("function () { return this.get_glVertexSource (); }"),
				set: untyped #if haxe4 js.Syntax.code #else __js__ #end ("function (v) { return this.set_glVertexSource (v); }")
			},
		});
	}
	#end

	/**
		Creates a new Shader instance.

		@param code The raw shader bytecode to link to the Shader.
	**/
	public function new(code:ByteArray = null)
	{
		byteCode = code;
		precisionHint = FULL;

		__glSourceDirty = true;
		#if mobile
		__glProgramDirty = true;
		__glRawFragmentSource = null;
		__glRawVertexSource = null;
		__glTransformRevision = -1;
		#end
		__numPasses = 1;
		__data = new ShaderData(code);
	}

	@:noCompletion private function __clearUseArray():Void
	{
		for (parameter in __paramBool)
		{
			parameter.__useArray = false;
		}

		for (parameter in __paramFloat)
		{
			parameter.__useArray = false;
		}

		for (parameter in __paramInt)
		{
			parameter.__useArray = false;
		}
	}

	// private function __clone ():Shader {
	// var classType = Type.getClass (this);
	// var shader = Type.createInstance (classType, []);
	// for (input in __inputBitmapData) {
	// 	if (input.input != null) {
	// 		var field = Reflect.field (shader.data, input.name);
	// 		field.channels = input.channels;
	// 		field.height = input.height;
	// 		field.input = input.input;
	// 		field.smoothing = input.smoothing;
	// 		field.width = input.width;
	// 	}
	// }
	// for (param in __paramBool) {
	// 	if (param.value != null) {
	// 		Reflect.field (shader.data, param.name).value = param.value.copy ();
	// 	}
	// }
	// for (param in __paramFloat) {
	// 	if (param.value != null) {
	// 		Reflect.field (shader.data, param.name).value = param.value.copy ();
	// 	}
	// }
	// for (param in __paramInt) {
	// 	if (param.value != null) {
	// 		Reflect.field (shader.data, param.name).value = param.value.copy ();
	// 	}
	// }
	// return shader;
	// }

	private static inline var SHADER_SOURCE_PREVIEW_LINES:Int = 5;

	private static function sourceHead(source:String):String
	{
		if (source == null || source.length == 0)
			return '';

		var normalized:String = StringTools.replace(StringTools.replace(source, '\r\n', '\n'), '\r', '\n');
		var lines:Array<String> = normalized.split('\n');
		if (lines.length > SHADER_SOURCE_PREVIEW_LINES)
			lines = lines.slice(0, SHADER_SOURCE_PREVIEW_LINES);

		return '[source]\n' + lines.join('\n');
	}

	@:noCompletion private function __createGLShader(source:String, type:Int):GLShader
	{
		var gl = __context.gl;

		var shader = __compileGLShader(source, type);
		var shaderInfoLog = gl.getShaderInfoLog(shader);
		var hasInfoLog = shaderInfoLog != null && StringTools.trim(shaderInfoLog) != "";
		var compileStatus = gl.getShaderParameter(shader, gl.COMPILE_STATUS);

		if (compileStatus == 0)
		{
			var shaderType = (type == gl.VERTEX_SHADER) ? "vertex" : "fragment";
			var fullMessage = 'Error compiling ' + shaderType + ' shader: ' + shaderInfoLog + '\n' + source;

			#if sys
			try
			{
				if (!sys.FileSystem.exists('logs'))
					sys.FileSystem.createDirectory('logs');

				var dateNow:String = StringTools.replace(StringTools.replace(Date.now().toString(), " ", "_"), ":", "'");
				var logFileName = 'ShaderCompileError_${dateNow}.txt';
				sys.io.File.saveContent('logs/' + logFileName, fullMessage);
			}
			catch (e:haxe.Exception)
				Log.warn("Couldn\'t save error message. (${e.message})", null);
			#end

			var message = 'Error compiling ' + shaderType + ' shader:';
			if (shaderInfoLog != null && StringTools.trim(shaderInfoLog).length > 0)
				message += '\n' + StringTools.trim(shaderInfoLog);
			message += '\n' + sourceHead(source);

			#if sys
			mobile.backend.SUtil.showPopUp(message, 'Shader Compile Error!');
			#else
			openfl.Lib.application.window.alert(message, 'Shader Compile Error!');
			#end
		}
		else if (hasInfoLog)
		{
			var shaderType = (type == gl.VERTEX_SHADER) ? "vertex" : "fragment";
			Log.debug('Info compiling ' + shaderType + ' shader: ' + shaderInfoLog + '\n' + source);
		}

		return shader;
	}

	@:noCompletion private function __compileGLShader(source:String, type:Int):GLShader
	{
		var gl = __context.gl;

		var shader = gl.createShader(type);
		gl.shaderSource(shader, source);
		gl.compileShader(shader);

		return shader;
	}

	/** Fix support for drivers that don't draw if attribute 0 is disabled. */
	@:noCompletion private function __bindPositionAttribute(program:GLProgram):Void
	{
		for (param in __paramFloat)
		{
			if (param.name.indexOf("Position") > -1 && StringTools.startsWith(param.name, "openfl_"))
			{
				__context.gl.bindAttribLocation(program, 0, param.name);
				break;
			}
		}
	}

	#if mobile
	/**
	 * Compiles one shader without reporting anything to the player. Returns
	 * `null` when the driver rejects it, appending the driver message to
	 * `failureLog` when one is provided.
	 */
	@:noCompletion private function __tryCompileGLShader(source:String, type:Int, ?failureLog:Array<String>):Null<GLShader>
	{
		var gl = __context.gl;
		var shader = __compileGLShader(source, type);

		if (gl.getShaderParameter(shader, gl.COMPILE_STATUS) == 0)
		{
			if (failureLog != null)
			{
				var shaderType = (type == gl.VERTEX_SHADER) ? "vertex" : "fragment";
				var infoLog = gl.getShaderInfoLog(shader);
				failureLog.push(shaderType + ': ' + (infoLog != null ? StringTools.trim(infoLog) : ''));
			}
			gl.deleteShader(shader);
			return null;
		}

		var shaderInfoLog = gl.getShaderInfoLog(shader);
		if (shaderInfoLog != null && StringTools.trim(shaderInfoLog) != "")
		{
			var shaderType = (type == gl.VERTEX_SHADER) ? "vertex" : "fragment";
			Log.debug('Info compiling ' + shaderType + ' shader: ' + shaderInfoLog + '\n' + source);
		}

		return shader;
	}

	/**
	 * Compiles and links a program without reporting anything. Returns `null`
	 * when the driver rejects it; every GL object created for the attempt is
	 * released, so a source can be probed before deciding whether to keep it.
	 */
	@:noCompletion private function __tryCreateGLProgram(vertexSource:String, fragmentSource:String,
		?failureLog:Array<String>):Null<GLProgram>
	{
		var gl = __context.gl;

		var vertexShader = __tryCompileGLShader(vertexSource, gl.VERTEX_SHADER, failureLog);
		if (vertexShader == null) return null;

		var fragmentShader = __tryCompileGLShader(fragmentSource, gl.FRAGMENT_SHADER, failureLog);
		if (fragmentShader == null)
		{
			gl.deleteShader(vertexShader);
			return null;
		}

		var program = gl.createProgram();
		__bindPositionAttribute(program);
		gl.attachShader(program, vertexShader);
		gl.attachShader(program, fragmentShader);
		gl.linkProgram(program);

		gl.deleteShader(vertexShader);
		gl.deleteShader(fragmentShader);

		if (gl.getProgramParameter(program, gl.LINK_STATUS) == 0)
		{
			if (failureLog != null)
			{
				var infoLog = gl.getProgramInfoLog(program);
				failureLog.push('link: ' + (infoLog != null ? StringTools.trim(infoLog) : ''));
			}
			gl.deleteProgram(program);
			return null;
		}

		return program;
	}
	#end

	@:noCompletion private function __createGLProgram(vertexSource:String, fragmentSource:String):GLProgram
	{
		#if mobile
		// The GLSL ES conversion is only a compatibility layer. When this
		// device's driver still rejects the translated source, keep the shader
		// usable by falling back to the original OpenFL GLSL instead of
		// leaving a program the driver refused to build.
		var failureLog:Array<String> = [];
		var glProgram = __tryCreateGLProgram(vertexSource, fragmentSource, failureLog);
		if (glProgram != null) return glProgram;

		if (__glRawVertexSource != null && __glRawFragmentSource != null
			&& (vertexSource != __glRawVertexSource || fragmentSource != __glRawFragmentSource))
		{
			Log.warn('NovaFlare GLSL ES conversion was rejected by this driver (${failureLog.join("; ")});'
				+ ' falling back to the original shader source', null);
			glProgram = __tryCreateGLProgram(__glRawVertexSource, __glRawFragmentSource);
			if (glProgram != null) return glProgram;
		}
		#end

		var gl = __context.gl;

		var vertexShader = __createGLShader(vertexSource, gl.VERTEX_SHADER);
		var fragmentShader = __createGLShader(fragmentSource, gl.FRAGMENT_SHADER);

		var program = gl.createProgram();

		__bindPositionAttribute(program);

		gl.attachShader(program, vertexShader);
		gl.attachShader(program, fragmentShader);
		gl.linkProgram(program);

		if (gl.getProgramParameter(program, gl.LINK_STATUS) == 0)
		{
			var message = "Unable to initialize the shader program";
			message += "\n" + gl.getProgramInfoLog(program);
			Log.error(message);
		}

		return program;
	}

	@:noCompletion private function __disable():Void
	{
		if (program != null)
		{
			__disableGL();
		}
	}

	@:noCompletion private function __disableGL():Void
	{
		var gl = __context.gl;

		var textureCount = 0;

		for (input in __inputBitmapData)
		{
			input.__disableGL(__context, textureCount);
			textureCount++;
			if (textureCount == gl.MAX_TEXTURE_IMAGE_UNITS)
				break;
		}

		for (parameter in __paramBool)
		{
			parameter.__disableGL(__context);
		}

		for (parameter in __paramFloat)
		{
			parameter.__disableGL(__context);
		}

		for (parameter in __paramInt)
		{
			parameter.__disableGL(__context);
		}

		__context.__bindGLArrayBuffer(null);

		#if lime
		if (__context.__context.type == OPENGL)
		{
			gl.disable(gl.TEXTURE_2D);
		}
		#end
	}

	@:noCompletion private function __enable():Void
	{
		__init();

		if (program != null)
		{
			__enableGL();
		}
	}

	@:noCompletion private function __enableGL():Void
	{
		var textureCount = 0;

		var gl = __context.gl;

		for (input in __inputBitmapData)
		{
			gl.uniform1i(input.index, textureCount);
			textureCount++;
		}

		#if lime
		if (__context.__context.type == OPENGL && textureCount > 0)
		{
			gl.enable(gl.TEXTURE_2D);
		}
		#end
	}

	@:noCompletion private function __init():Void
	{
		if (__data == null)
		{
			__data = cast new ShaderData(null);
		}

		#if mobile
		if (__glTransformRevision != MobileShaderConverter.revision)
		{
			// A converter setting/capability change only invalidates the native
			// program. Preserve ShaderData and existing uniform values.
			__glProgramDirty = true;
			program = null;
			glProgram = null;
		}
		#end

		var requiresProgramInit = program == null || __glSourceDirty;
		#if mobile
		requiresProgramInit = requiresProgramInit || __glProgramDirty;
		#end
		if (__glFragmentSource != null && __glVertexSource != null && requiresProgramInit)
		{
			__initGL();
		}
	}

	@:noCompletion private function __requiresInit():Bool
	{
		var result = __data == null || program == null || __glSourceDirty;
		#if mobile
		result = result || __glProgramDirty || __glTransformRevision != MobileShaderConverter.revision;
		#end
		return result;
	}

	#if mobile
	@:noCompletion private function __setMobileContext(context:Context3D):Void
	{
		if (__context == context) return;
		__context = context;
		program = null;
		glProgram = null;
		__glProgramDirty = true;
		__glTransformRevision = -1;
	}

	@:noCompletion private function __prepareMobileGLSLProgram(vertexSource:String, fragmentSource:String)
	{
		var gl = __context.gl;
		var glVersion = MobileShaderConverter.configureFromGL(gl);
		var prepared = MobileShaderConverter.prepareProgram(vertexSource, fragmentSource, glVersion);
		// Remember the untranslated sources so a driver that rejects the
		// converted GLSL ES can still be handed the original OpenFL GLSL.
		__glRawVertexSource = vertexSource;
		__glRawFragmentSource = fragmentSource;
		for (diagnostic in prepared.diagnostics)
			Log.warn('NovaFlare GLSL ES conversion [${diagnostic.stage}:${diagnostic.line}]: ${diagnostic.message}', null);
		return prepared;
	}
	#end

	@:noCompletion private function __initGL():Void
	{
		if (__glSourceDirty || __paramBool == null)
		{
			__glSourceDirty = false;
			program = null;

			__inputBitmapData = new Array();
			__paramBool = new Array();
			__paramFloat = new Array();
			__paramInt = new Array();

			__processGLData(glVertexSource, "attribute");
			__processGLData(glVertexSource, "uniform");
			__processGLData(glFragmentSource, "uniform");
		}

		if (__context != null && program == null)
		{
			#if (js && html5)
			var prefix = (precisionHint == FULL ? "precision mediump float;\n" : "precision lowp float;\n");
			#else
			var prefix = "#ifdef GL_ES\n"
				+ (precisionHint == FULL ? "#ifdef GL_FRAGMENT_PRECISION_HIGH\n"
					+ "precision highp float;\n"
					+ "#else\n"
					+ "precision mediump float;\n"
					+ "#endif\n" : "precision lowp float;\n")
				+ "#endif\n\n";
			#end

			var vertex = prefix + glVertexSource;
			var fragment = prefix + glFragmentSource;

			#if mobile
			var preparedSources = __prepareMobileGLSLProgram(vertex, fragment);
			vertex = preparedSources.vertex;
			fragment = preparedSources.fragment;
			var id = preparedSources.cacheKey + '\nvertex:' + vertex.length + '\n' + vertex
				+ '\nfragment:' + fragment.length + '\n' + fragment;
			#else
			var id = vertex + fragment;
			#end

			if (__context.__programs.exists(id))
			{
				program = __context.__programs.get(id);
			}
			else
			{
				program = __context.createProgram(GLSL);

				// TODO
				// program.uploadSources (vertex, fragment);
				program.__glProgram = __createGLProgram(vertex, fragment);

				__context.__programs.set(id, program);
			}

			if (program != null)
			{
				#if mobile
				__glTransformRevision = MobileShaderConverter.revision;
				__glProgramDirty = false;
				#end
				__refreshGLBindingLocations();
			}
		}
	}

	@:noCompletion private function __refreshGLBindingLocations():Void
	{
		glProgram = program.__glProgram;
		for (input in __inputBitmapData)
			input.index = __getGLBindingLocation(__context, glProgram, input.name, input.__isUniform);

		for (parameter in __paramBool)
			parameter.index = __getGLBindingLocation(__context, glProgram, parameter.name, parameter.__isUniform);

		for (parameter in __paramFloat)
			parameter.index = __getGLBindingLocation(__context, glProgram, parameter.name, parameter.__isUniform);

		for (parameter in __paramInt)
			parameter.index = __getGLBindingLocation(__context, glProgram, parameter.name, parameter.__isUniform);
	}

	@:noCompletion private static function __getGLBindingLocation(context:Context3D, glProgram:GLProgram, name:String, uniform:Bool):Dynamic
	{
		final gl = context.gl;
		#if (cpp && lime_cffi && (lime_opengl || lime_opengles) && !lime_webgl && !disable_cffi)
		final key:GLObject = glProgram;
		if (key != null)
		{
			var locations = __glBindingLocations.get(key);
			if (locations == null)
			{
				locations = {uniforms: [], attributes: []};
				__glBindingLocations.set(key, locations);
			}
			final bindings = uniform ? locations.uniforms : locations.attributes;
			final cached = bindings.get(name);
			if (cached != null) return cached;

			final index = uniform ? gl.getUniformLocation(glProgram, name) : gl.getAttribLocation(glProgram, name);
			// Lime also returns -1 when the render thread cannot execute a query.
			if (index >= 0) bindings.set(name, index);
			return index;
		}
		#end
		if (uniform) return gl.getUniformLocation(glProgram, name);
		return gl.getAttribLocation(glProgram, name);
	}

	#if cpp
	private static final __uniformDeclarationPattern = new Tls<EReg>();
	private static final __attributeDeclarationPattern = new Tls<EReg>();
	#end

	@:noCompletion private static function __acquireGLDeclarationPattern(isUniform:Bool):EReg
	{
		#if cpp
		final threadPattern = isUniform ? __uniformDeclarationPattern : __attributeDeclarationPattern;
		var pattern = threadPattern.value;
		if (pattern != null)
		{
			// A finalizer can reenter during capture or parameter allocation.
			threadPattern.value = null;
			return pattern;
		}
		#else
		var pattern:EReg;
		#end

		if (isUniform)
		{
			pattern = ~/uniform[ \t]+(?:(?:lowp|mediump|highp)[ \t]+)?([A-Za-z0-9]+)[ \t]+([A-Za-z0-9_]+)/;
		}
		else
		{
			// Accept OpenFL's legacy `attribute` and desktop GLSL's top-level
			// `layout(...) in` without mistaking function `in` parameters for
			// vertex buffers.
			pattern = ~/(?:^|[;\r\n])[ \t]*(?:layout[ \t]*\([^\r\n)]*\)[ \t]*)?(?:attribute|in)[ \t]+(?:(?:lowp|mediump|highp)[ \t]+)?([A-Za-z0-9]+)[ \t]+([A-Za-z0-9_]+)(?:[ \t]*\[[^;\r\n]*\])?[ \t]*;/;
		}

		return pattern;
	}

	@:noCompletion private static function __releaseGLDeclarationPattern(isUniform:Bool, pattern:EReg):Void
	{
		#if cpp
		final threadPattern = isUniform ? __uniformDeclarationPattern : __attributeDeclarationPattern;
		threadPattern.value = pattern;
		#end
	}

	@:noCompletion private function __processGLData(source:String, storageType:String):Void
	{
		var lastMatch = 0, position, name, type;
		final isUniform = storageType == "uniform";
		final regex = __acquireGLDeclarationPattern(isUniform);

		while (regex.matchSub(source, lastMatch))
		{
			type = regex.matched(1);
			name = regex.matched(2);
			position = regex.matchedPos();
			lastMatch = position.pos + position.len;

			if (StringTools.startsWith(name, "gl_"))
			{
				continue;
			}

			if (StringTools.startsWith(type, "sampler"))
			{
				var input = new ShaderInput<BitmapData>();
				input.name = name;
				input.__isUniform = isUniform;
				__inputBitmapData.push(input);

				switch (name)
				{
					case "openfl_Texture":
						__texture = input;
					case "bitmap":
						__bitmap = input;
					default:
				}

				Reflect.setField(__data, name, input);
				if (__isGenerated)
					Reflect.setField(this, name, input);
			}
			else if (!Reflect.hasField(__data, name) || Reflect.field(__data, name) == null)
			{
				var parameterType:ShaderParameterType = switch (type)
				{
					case "bool": BOOL;
					case "double", "float": FLOAT;
					case "int", "uint": INT;
					case "bvec2": BOOL2;
					case "bvec3": BOOL3;
					case "bvec4": BOOL4;
					case "ivec2", "uvec2": INT2;
					case "ivec3", "uvec3": INT3;
					case "ivec4", "uvec4": INT4;
					case "vec2", "dvec2": FLOAT2;
					case "vec3", "dvec3": FLOAT3;
					case "vec4", "dvec4": FLOAT4;
					case "mat2", "mat2x2": MATRIX2X2;
					case "mat2x3": MATRIX2X3;
					case "mat2x4": MATRIX2X4;
					case "mat3x2": MATRIX3X2;
					case "mat3", "mat3x3": MATRIX3X3;
					case "mat3x4": MATRIX3X4;
					case "mat4x2": MATRIX4X2;
					case "mat4x3": MATRIX4X3;
					case "mat4", "mat4x4": MATRIX4X4;
					default: null;
				}

				var length = switch (parameterType)
				{
					case BOOL2, INT2, FLOAT2: 2;
					case BOOL3, INT3, FLOAT3: 3;
					case BOOL4, INT4, FLOAT4, MATRIX2X2: 4;
					case MATRIX3X3: 9;
					case MATRIX4X4: 16;
					default: 1;
				}

				var arrayLength = switch (parameterType)
				{
					case MATRIX2X2: 2;
					case MATRIX3X3: 3;
					case MATRIX4X4: 4;
					default: 1;
				}

				switch (parameterType)
				{
					case BOOL, BOOL2, BOOL3, BOOL4:
						var parameter = new ShaderParameter<Bool>();
						parameter.name = name;
						parameter.type = parameterType;
						parameter.__arrayLength = arrayLength;
						parameter.__isBool = true;
						parameter.__isUniform = isUniform;
						parameter.__length = length;
						__paramBool.push(parameter);

						if (name == "openfl_HasColorTransform")
						{
							__hasColorTransform = parameter;
						}

						Reflect.setField(__data, name, parameter);
						if (__isGenerated)
							Reflect.setField(this, name, parameter);

					case INT, INT2, INT3, INT4:
						var parameter = new ShaderParameter<Int>();
						parameter.name = name;
						parameter.type = parameterType;
						parameter.__arrayLength = arrayLength;
						parameter.__isInt = true;
						parameter.__isUniform = isUniform;
						parameter.__length = length;
						__paramInt.push(parameter);
						Reflect.setField(__data, name, parameter);
						if (__isGenerated)
							Reflect.setField(this, name, parameter);

					default:
						var parameter = new ShaderParameter<Float>();
						parameter.name = name;
						parameter.type = parameterType;
						parameter.__arrayLength = arrayLength;
						#if lime
						if (arrayLength > 0)
							parameter.__uniformMatrix = new Float32Array(arrayLength * arrayLength);
						#end
						parameter.__isFloat = true;
						parameter.__isUniform = isUniform;
						parameter.__length = length;
						__paramFloat.push(parameter);

						if (StringTools.startsWith(name, "openfl_"))
						{
							switch (name)
							{
								case "openfl_Alpha": __alpha = parameter;
								case "openfl_ColorMultiplier": __colorMultiplier = parameter;
								case "openfl_ColorOffset": __colorOffset = parameter;
								case "openfl_Matrix": __matrix = parameter;
								case "openfl_Position": __position = parameter;
								case "openfl_TextureCoord": __textureCoord = parameter;
								case "openfl_TextureSize": __textureSize = parameter;
								default:
							}
						}

						Reflect.setField(__data, name, parameter);
						if (__isGenerated)
							Reflect.setField(this, name, parameter);
				}
			}

		}
		__releaseGLDeclarationPattern(isUniform, regex);
	}

	#if novaflare_threaded_projection_matrix
	@:noCompletion private function __updateWithProjectionMatrix(matrix:ShaderParameter<Float>, ?shaderBuffer:ShaderBuffer, bufferOffset:Int = 0):Void
	{
		final previous = __activeProjectionMatrix;
		__activeProjectionMatrix = matrix;
		try
		{
			if (shaderBuffer == null) __update();
			else __updateFromBuffer(shaderBuffer, bufferOffset);
		}
		catch (error:Dynamic)
		{
			__activeProjectionMatrix = previous;
			throw error;
		}
		__activeProjectionMatrix = previous;
	}
	#end

	@:noCompletion private function __update():Void
	{
		if (program != null)
		{
			__updateGL();
		}
	}

	@:noCompletion private function __updateFromBuffer(shaderBuffer:ShaderBuffer, bufferOffset:Int):Void
	{
		if (program != null)
		{
			__updateGLFromBuffer(shaderBuffer, bufferOffset);
		}
	}

	@:noCompletion private function __updateGL():Void
	{
		var textureCount = 0;

		for (input in __inputBitmapData)
		{
			input.__updateGL(__context, textureCount);
			textureCount++;
		}

		for (parameter in __paramBool)
		{
			parameter.__updateGL(__context);
		}

		for (parameter in __paramFloat)
		{
			#if novaflare_threaded_projection_matrix
			if (parameter == __activeProjectionMatrix) continue;
			#end
			parameter.__updateGL(__context);
		}

		for (parameter in __paramInt)
		{
			parameter.__updateGL(__context);
		}
	}

	@:noCompletion private function __updateGLFromBuffer(shaderBuffer:ShaderBuffer, bufferOffset:Int):Void
	{
		var textureCount = 0;
		var input, inputData, inputFilter, inputMipFilter, inputWrap;

		for (i in 0...shaderBuffer.inputCount)
		{
			input = shaderBuffer.inputRefs[i];
			inputData = shaderBuffer.inputs[i];
			inputFilter = shaderBuffer.inputFilter[i];
			inputMipFilter = shaderBuffer.inputMipFilter[i];
			inputWrap = shaderBuffer.inputWrap[i];

			if (inputData != null)
			{
				input.__updateGL(__context, textureCount, inputData, inputFilter, inputMipFilter, inputWrap);
				textureCount++;
			}
		}

		#if novaflare_threaded_shader_inputs
		shaderBuffer.bindAndUpload(__context, true);
		#else
		var gl = __context.gl;

		if (shaderBuffer.paramDataLength > 0)
		{
			if (shaderBuffer.paramDataBuffer == null)
			{
				shaderBuffer.paramDataBuffer = gl.createBuffer();
			}

			__context.__bindGLArrayBuffer(shaderBuffer.paramDataBuffer);
			#if (lime && sys && lime_cffi && (lime_opengl || lime_opengles) && !doc_gen)
			var dataView:lime.utils.ArrayBufferView = shaderBuffer.paramData;
			__context.__context.gles2.bufferData(gl.ARRAY_BUFFER, shaderBuffer.paramDataLength * Float32Array.BYTES_PER_ELEMENT,
				dataView, gl.DYNAMIC_DRAW);
			#elseif lime
			var data = shaderBuffer.paramData;
			if (data.length != shaderBuffer.paramDataLength) data = data.subarray(0, shaderBuffer.paramDataLength);
			gl.bufferData(gl.ARRAY_BUFFER, data, gl.DYNAMIC_DRAW);
			#else
			gl.bufferData(gl.ARRAY_BUFFER, shaderBuffer.paramData, gl.DYNAMIC_DRAW);
			#end
		}
		else
		{
			// Log.verbose ("bind buffer null");

			__context.__bindGLArrayBuffer(null);
		}
		#end

		var boolIndex = 0;
		var floatIndex = 0;
		var intIndex = 0;

		var boolCount = shaderBuffer.paramBoolCount;
		var floatCount = shaderBuffer.paramFloatCount;
		var paramData = shaderBuffer.paramData;

		var boolRef, floatRef, intRef, hasOverride;
		var overrideBoolValue:Array<Bool> = null,
			overrideFloatValue:Array<Float> = null,
			overrideIntValue:Array<Int> = null;

		for (i in 0...shaderBuffer.paramCount)
		{
			hasOverride = false;

			if (i < boolCount)
			{
				boolRef = shaderBuffer.paramRefs_Bool[boolIndex];

				for (j in 0...shaderBuffer.overrideBoolCount)
				{
					if (boolRef.name == shaderBuffer.overrideBoolNames[j])
					{
						overrideBoolValue = shaderBuffer.overrideBoolValues[j];
						hasOverride = true;
						break;
					}
				}

				if (hasOverride)
				{
					boolRef.__updateGL(__context, overrideBoolValue);
				}
				else
				{
					boolRef.__updateGLFromBuffer(__context, paramData, shaderBuffer.paramPositions[i], shaderBuffer.paramLengths[i], bufferOffset);
				}

				boolIndex++;
			}
			else if (i < boolCount + floatCount)
			{
				floatRef = shaderBuffer.paramRefs_Float[floatIndex++];
				#if novaflare_threaded_projection_matrix
				if (floatRef == __activeProjectionMatrix) continue;
				#end

				for (j in 0...shaderBuffer.overrideFloatCount)
				{
					if (floatRef.name == shaderBuffer.overrideFloatNames[j])
					{
						overrideFloatValue = shaderBuffer.overrideFloatValues[j];
						hasOverride = true;
						break;
					}
				}

				if (hasOverride)
				{
					floatRef.__updateGL(__context, overrideFloatValue);
				}
				else
				{
					floatRef.__updateGLFromBuffer(__context, paramData, shaderBuffer.paramPositions[i], shaderBuffer.paramLengths[i], bufferOffset);
				}

			}
			else
			{
				intRef = shaderBuffer.paramRefs_Int[intIndex];

				for (j in 0...shaderBuffer.overrideIntCount)
				{
					if (intRef.name == shaderBuffer.overrideIntNames[j])
					{
						overrideIntValue = cast shaderBuffer.overrideIntValues[j];
						hasOverride = true;
						break;
					}
				}

				if (hasOverride)
				{
					intRef.__updateGL(__context, overrideIntValue);
				}
				else
				{
					intRef.__updateGLFromBuffer(__context, paramData, shaderBuffer.paramPositions[i], shaderBuffer.paramLengths[i], bufferOffset);
				}

				intIndex++;
			}
		}
	}

	// Get & Set Methods
	@:noCompletion private function get_data():ShaderData
	{
		if (__glSourceDirty || __data == null)
		{
			__init();
		}

		return __data;
	}

	@:noCompletion private function set_data(value:ShaderData):ShaderData
	{
		return __data = cast value;
	}

	@:noCompletion private function get_glFragmentSource():String
	{
		return __glFragmentSource;
	}

	@:noCompletion private function set_glFragmentSource(value:String):String
	{
		if (value != __glFragmentSource)
		{
			__glSourceDirty = true;
		}

		return __glFragmentSource = value;
	}

	@:noCompletion private function get_glVertexSource():String
	{
		return __glVertexSource;
	}

	@:noCompletion private function set_glVertexSource(value:String):String
	{
		if (value != __glVertexSource)
		{
			__glSourceDirty = true;
		}

		return __glVertexSource = value;
	}
}
#else
typedef Shader = flash.display.Shader;
#end
