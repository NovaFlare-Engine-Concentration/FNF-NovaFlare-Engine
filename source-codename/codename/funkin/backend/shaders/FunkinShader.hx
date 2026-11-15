package codename.funkin.backend.shaders;

import flixel.graphics.FlxGraphic;
import flixel.system.FlxAssets.FlxShader;
import flixel.util.FlxSignal.FlxTypedSignal;
import haxe.Exception;
import hscript.IHScriptCustomBehaviour;
import lime.utils.Float32Array;
import openfl.display.BitmapData;
import openfl.display.ShaderInput;
import openfl.display.ShaderParameter;
import openfl.display.ShaderParameterType;
import openfl.display3D._internal.GLProgram;
import openfl.display3D._internal.GLShader;
import openfl.utils._internal.Log;
#if mobile
import general.shaders.MobileShaderConverter;
#end

using StringTools;
@:access(openfl.display3D.Context3D)
@:access(openfl.display3D.Program3D)
@:access(openfl.display.ShaderInput)
@:access(openfl.display.ShaderParameter)
class FunkinShader extends FlxShader implements IHScriptCustomBehaviour {
	private static var __instanceFields = Type.getInstanceFields(FunkinShader);
	private static var FRAGMENT_SHADER = 0;
	private static var VERTEX_SHADER = 1;

	public var onGLUpdate:FlxTypedSignal<Void->Void> = new FlxTypedSignal<Void->Void>();
	public var onProcessGLData:FlxTypedSignal<(String, String)->Void> = new FlxTypedSignal<(String, String)->Void>();

	public var glslVer:String = Flags.DEFAULT_GLSL_VERSION;
	public var fileName:String = "FunkinShader";
	public var fragFileName:String = "FunkinShader";
	public var vertFileName:String = "FunkinShader";

	public var shaderPrefix:String = Flags.FUNKIN_SHADER_CODE_PREFIX;
	public var fragmentPrefix:String = Flags.FUNKIN_SHADER_CODE_FRAGMENT_PREFIX;
	public var vertexPrefix:String = Flags.FUNKIN_SHADER_CODE_VERTEX_PREFIX;

	/**
	 * Creates a new shader from the specified fragment and vertex source.
	 * Accepts `#pragma header`.
	 * @param frag Fragment source (pass `null` to use default)
	 * @param vert Vertex source (pass `null` to use default)
	 * @param glslVer Version of GLSL to use (defaults to 120)
	 */
	public override function new(?frag:String, ?vert:String, glslVer:String = null) {
		if (glslVer == null) glslVer = Flags.DEFAULT_GLSL_VERSION;
		if (frag == null) frag = ShaderTemplates.defaultFragmentSource;
		if (vert == null) vert = ShaderTemplates.defaultVertexSource;
		this.glFragmentSource = frag;
		this.glVertexSource = vert;

		this.glslVer = glslVer;
		super();
	}

	/** Upstream's file API, using NF's existing shader compiler and mobile bridge. */
	public static function fromFile(fragmentPath:String, ?vertexPath:String, ?version:String):FunkinShader {
		return new FunkinShader().loadShaderFile(fragmentPath, vertexPath, version);
	}

	public function loadShaderFile(fragmentPath:String, ?vertexPath:String, ?version:String):FunkinShader {
		if (vertexPath == null) vertexPath = haxe.io.Path.withoutExtension(fragmentPath);
		var fragment = Assets.exists(fragmentPath) ? fragmentPath : Paths.fragShader(fragmentPath);
		var vertex = Assets.exists(vertexPath) ? vertexPath : Paths.vertShader(vertexPath);
		fileName = fragmentPath;
		fragFileName = fragment;
		vertFileName = vertex;
		glslVer = version ?? Flags.DEFAULT_GLSL_VERSION;
		glFragmentSource = Assets.exists(fragment) ? Assets.getText(fragment) : ShaderTemplates.defaultFragmentSource;
		glVertexSource = Assets.exists(vertex) ? Assets.getText(vertex) : ShaderTemplates.defaultVertexSource;
		return this;
	}

	static var IMPORT_REGEX = ~/#import\s+<(.*)>/;

	private function processImports(value:String, type:Int):String
	{
		var imported:Map<String, Bool> = [];
		while(IMPORT_REGEX.match(value))
		{
			var importPath = IMPORT_REGEX.matched(1);
			var importToken = IMPORT_REGEX.matched(0);
			var path = Paths.getPath("shaders/" + importPath);
			var importSource = !imported.exists(importPath) && Assets.exists(path) ? Assets.getText(path) : null;
			imported.set(importPath, true);
			if(importSource == null) {
				var fileName = type == FRAGMENT_SHADER ? fragFileName : vertFileName;
				Logs.traceColored([
					Logs.logText('[Shader] ', RED),
					Logs.logText('Failed to import shader ${importPath} in ${fileName}', RED),
				]);
			}
			value = value.replace(importToken, importSource ?? "");
		}
		return value;
	}

	static var ERROR_POS_REGEX = ~/(\d+):(\d+): (.*)/g;
	static var ERROR_REGEX = ~/ERROR: (\d+):(\d+): (.*)/g;
	static var ERROR_REGEX_2 = ~/(\d+)\((\d+)\) : error ([^:]+): (.*)/g;

	function reportShaderFailure(title:String, message:String, kind:String, ?vertexSource:String, ?fragmentSource:String):Void
	{
		Logs.error(message, RED, "Shader");
		general.shaders.ErrorHandledShader.crashSave('CNE_${fileName}_$kind', '$title\n$message', null,
			vertexSource, fragmentSource);
	}

	@:noCompletion private override function __createGLShader(source:String, type:Int):GLShader
	{
		var gl = __context.gl;

		var shader = gl.createShader(type);
		gl.shaderSource(shader, source);
		gl.compileShader(shader);
		var shaderInfoLog = gl.getShaderInfoLog(shader);
		var hasInfoLog = shaderInfoLog != null && StringTools.trim(shaderInfoLog) != "";
		var compileStatus = gl.getShaderParameter(shader, gl.COMPILE_STATUS);

		if (hasInfoLog || compileStatus == 0)
		{
			var isVertexShader = type == gl.VERTEX_SHADER;
			var messageBuf = new StringBuf();
			messageBuf.add((compileStatus == 0) ? "Error" : "Info");
			if(isVertexShader) {
				messageBuf.add(" compiling vertex shader");
				if(vertFileName != null && vertFileName.length > 0) {
					messageBuf.add(" (" + vertFileName + ")");
				}
			} else {
				messageBuf.add(" compiling fragment shader");
				if(fragFileName != null && fragFileName.length > 0) {
					messageBuf.add(" (" + fragFileName + ")");
				}
			}
			messageBuf.add("\n");
			var errorPositions = [];
			var regex = null;
			var tmp = shaderInfoLog;
			if(shaderInfoLog.contains(" : error ")) {
				regex = ERROR_REGEX_2;

				while(regex.match(tmp)) {
					errorPositions.push(new ShaderErrorPosition(regex.matched(2), regex.matched(1), regex.matched(4)));
					tmp = regex.matchedRight();
				}
			} else if(shaderInfoLog.contains("ERROR: ")) {
				regex = ERROR_REGEX;

				while(regex.match(tmp)) {
					errorPositions.push(new ShaderErrorPosition(regex.matched(2), regex.matched(1), regex.matched(3)));
					tmp = regex.matchedRight();
				}
			} else {
				regex = ERROR_POS_REGEX;

				while(regex.match(tmp)) {
					errorPositions.push(new ShaderErrorPosition(regex.matched(2), regex.matched(1), regex.matched(3)));
					tmp = regex.matchedRight();
				}
			}
			var splitSource = source.split("\n");
			for(error in errorPositions) {
				messageBuf.add("ERROR: Line: " + error.line);
				if(error.column > 0) {
					messageBuf.add(", Column: " + error.column);
				}
				messageBuf.add(", " + error.message);
				if(error.line < splitSource.length) {
					messageBuf.add("\nLine: ");
					messageBuf.add(splitSource[error.line-1].trim());
				}
				messageBuf.add("\n\n");
			}
			var hasErrorPosition = errorPositions.length > 0;
			if(hasErrorPosition) {
				messageBuf.add("Raw shader info log:\n");
			}
			messageBuf.add(shaderInfoLog);
			messageBuf.add("\n");
			messageBuf.add(source);

			var message = messageBuf.toString();
			if (compileStatus == 0) {
				reportShaderFailure("Shader Compile Error", message, "Compile",
					isVertexShader ? source : null, isVertexShader ? null : source);
			}
			else if (hasInfoLog) Log.debug(message);
		}

		return shader;
	}

	@:noCompletion private override function __createGLProgram(vertexSource:String, fragmentSource:String):GLProgram
	{
		var program:GLProgram = null;
		try
		{
			var gl = __context.gl;

			var vertexShader = __createGLShader(vertexSource, gl.VERTEX_SHADER);
			var fragmentShader = __createGLShader(fragmentSource, gl.FRAGMENT_SHADER);

			program = gl.createProgram();

			// Fix support for drivers that don't draw if attribute 0 is disabled
			for (param in __paramFloat)
			{
				if (param.name.indexOf("Position") > -1 && StringTools.startsWith(param.name, "openfl_"))
				{
					gl.bindAttribLocation(program, 0, param.name);
					break;
				}
			}

			gl.attachShader(program, vertexShader);
			gl.attachShader(program, fragmentShader);
			gl.linkProgram(program);

			if (gl.getProgramParameter(program, gl.LINK_STATUS) == 0)
			{
				var messageBuf = new StringBuf();
				messageBuf.add("Unable to initialize the shader program");
				messageBuf.add("\n");
				messageBuf.add(gl.getProgramInfoLog(program));
				var message = messageBuf.toString();
				reportShaderFailure("Shader Link Error", message, "Link", vertexSource, fragmentSource);
			}
		}
		catch (error:Dynamic)
		{
			reportShaderFailure("Shader Compile Error", 'Failed to compile shader $fileName:\n${Std.string(error)}', "Exception",
				vertexSource, fragmentSource);
		}
		return program;

		return program;
	}

	var glRawFragmentSource:String;
	var glRawVertexSource:String;

	@:noCompletion override private function set_glFragmentSource(value:String):String
	{
		if(value == null)
			value = ShaderTemplates.defaultFragmentSource;
		glRawFragmentSource = value;
		value = processImports(value, FRAGMENT_SHADER);
		value = value.replace("#pragma header", ShaderTemplates.fragHeader).replace("#pragma body", ShaderTemplates.fragBody);
		if (value != __glFragmentSource)
		{
			__glSourceDirty = true;
		}

		return __glFragmentSource = value;
	}

	@:noCompletion override private function set_glVertexSource(value:String):String
	{
		if(value == null)
			value = ShaderTemplates.defaultVertexSource;
		glRawVertexSource = value;
		value = processImports(value, VERTEX_SHADER);

		var useBackCompat:Bool = true;
		for (regex in ShaderTemplates.vertBackCompatVarList) if (!regex.match(value)) {
			useBackCompat = false;
			break;
		}

		var header = useBackCompat ? ShaderTemplates.vertHeaderBackCompat : ShaderTemplates.vertHeader;
		var body = useBackCompat ? ShaderTemplates.vertBodyBackCompat : ShaderTemplates.vertBody;

		value = value.replace("#pragma header", header).replace("#pragma body", body);

		if (value != __glVertexSource)
		{
			__glSourceDirty = true;
		}

		return __glVertexSource = value;
	}

	override function __updateGL():Void {
		onGLUpdate.dispatch();
		super.__updateGL();
	}

	@:noCompletion private override function __initGL():Void
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
			var prefixBuf = new StringBuf();
			prefixBuf.add('#version ${glslVer}\n');
			prefixBuf.add(shaderPrefix);

			var gl = __context.gl;

			prefixBuf.add("#ifdef GL_ES\n");
			if (precisionHint == FULL) {
				prefixBuf.add("#ifdef GL_FRAGMENT_PRECISION_HIGH\n");
				prefixBuf.add("precision highp float;\n");
				prefixBuf.add("#else\n");
				prefixBuf.add("precision mediump float;\n");
				prefixBuf.add("#endif\n");
			} else {
				prefixBuf.add("precision lowp float;\n");
			}
			prefixBuf.add("#endif\n");

			var prefix = prefixBuf.toString();

			var vertex = prefix + vertexPrefix + glVertexSource;
			var fragment = prefix + fragmentPrefix + glFragmentSource;

			#if mobile
			// FunkinShader owns its complete GL program path, so OpenFL's base
			// Shader converter never sees these sources. Convert the final,
			// pragma-expanded program here before it reaches the mobile driver.
			var glVersion = MobileShaderConverter.configureFromGL(gl);
			// The user-facing converter toggle may disable compatibility work for
			// ordinary OpenFL shaders, but FunkinShader always prepends desktop GLSL
			// (`#version 120`). That source is never legal on OpenGL ES as-is, so the
			// CNE-owned program path must always perform its platform conversion.
			var preparedSources = MobileShaderConverter.prepareProgram(vertex, fragment, glVersion, true);
			for (diagnostic in preparedSources.diagnostics)
				Log.warn('NovaFlare GLSL ES conversion [${diagnostic.stage}:${diagnostic.line}]: ${diagnostic.message}', null);
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
				program.__glProgram = __createGLProgram(vertex, fragment);
				__context.__programs.set(id, program);
			}

			if (program != null)
			{
				#if mobile
				@:privateAccess {
					__glTransformRevision = MobileShaderConverter.revision;
					__glProgramDirty = false;
				}
				#end
				glProgram = program.__glProgram;

				for (input in __inputBitmapData) {

					if (input.__isUniform) {
						input.index = gl.getUniformLocation(glProgram, input.name);
					} else {
						input.index = gl.getAttribLocation(glProgram, input.name);
					}
				}

				for (parameter in __paramBool) {
					if (parameter.__isUniform) {
						parameter.index = gl.getUniformLocation(glProgram, parameter.name);
					} else {
						parameter.index = gl.getAttribLocation(glProgram, parameter.name);
					}
				}

				for (parameter in __paramFloat) {
					if (parameter.__isUniform) {
						parameter.index = gl.getUniformLocation(glProgram, parameter.name);
					} else {
						parameter.index = gl.getAttribLocation(glProgram, parameter.name);
					}
				}

				for (parameter in __paramInt) {
					if (parameter.__isUniform) {
						parameter.index = gl.getUniformLocation(glProgram, parameter.name);
					} else {
						parameter.index = gl.getAttribLocation(glProgram, parameter.name);
					}
				}
			}
			// initInstance(vertex, fragment); // btw make sure to disable the prefixes for ._isInstance
		}
	}

	var __cancelNextProcessGLData:Bool = false;
	@:noCompletion private override function __processGLData(source:String, storageType:String):Void
	{
		onProcessGLData.dispatch(source, storageType);
		if (__cancelNextProcessGLData != (__cancelNextProcessGLData = false))
			return;
		var lastMatch = 0, position, regex, name, type;

		if (storageType == "uniform")
		{
			regex = ~/uniform ([A-Za-z0-9]+) ([A-Za-z0-9_]+)/;
		}
		else
		{
			regex = ~/attribute ([A-Za-z0-9]+) ([A-Za-z0-9_]+)/;
		}

		while (regex.matchSub(source, lastMatch))
		{
			type = regex.matched(1);
			name = regex.matched(2);

			if (StringTools.startsWith(name, "gl_"))
			{
				continue;
			}

			var isUniform = (storageType == "uniform");
			registerParameter(name, type, isUniform);

			position = regex.matchedPos();
			lastMatch = position.pos + position.len;
		}
	}

	function registerParameter(name:String, type:String, isUniform:Bool):Void
	{
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
			try{Reflect.setField(this, name, input);} catch(e) {}
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
					try{Reflect.setField(this, name, parameter);} catch(e) {}

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
					try{Reflect.setField(this, name, parameter);} catch(e) {}

				default:
					var parameter = new ShaderParameter<Float>();
					parameter.name = name;
					parameter.type = parameterType;
					parameter.__arrayLength = arrayLength;
					#if lime
					if (arrayLength > 0) parameter.__uniformMatrix = new Float32Array(arrayLength * arrayLength);
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
					try{Reflect.setField(this, name, parameter);} catch(e) {}
			}
		}
	}

	#if cpp
	static final __paramTypeCache:haxe.ds.ObjectMap<Dynamic, Int> = new haxe.ds.ObjectMap();
	#else
	static final __paramTypeCache:Map<String, Int> = [];
	#end

	static function __paramTypeOf(cls:Class<Dynamic>):Int {
		if (cls == null) return 0;
		var name = Type.getClassName(cls);
		var key = #if cpp cls #else name #end;
		var kind = __paramTypeCache.get(key);
		if (kind == null) {
			kind = name.startsWith("openfl.display.ShaderParameter") ? 1 : (name.startsWith("openfl.display.ShaderInput") ? 2 : 0);
			__paramTypeCache.set(key, kind);
		}
		return kind;
	}

	public function hget(name:String):Dynamic {
		if (__instanceFields.contains(name) || __instanceFields.contains('get_${name}'))
			return Reflect.getProperty(this, name);
		if (!Reflect.hasField(data, name))
			return null;
		var field:Dynamic = Reflect.field(data, name);
		var kind = __paramTypeOf(Type.getClass(field));

		// little problem we are facing boys...

		// cant do "field is ShaderInput" because ShaderInput has the @:generic metadata
		// aka instead of ShaderInput<Float> it gets built as ShaderInput_Float
		// this should be fine tho because we check the class, and the fields don't vary based on the type

		// thanks for looking in the code cne fans :D!! -lunar

		if (kind == 1)
			return (field.__length > 1) ? field.value : field.value[0];
		else if (kind == 2)
			return field.input;
		return field;
	}

	public function hset(name:String, val:Dynamic):Dynamic {
		if (__instanceFields.contains(name) || __instanceFields.contains('set_${name}')) {
			Reflect.setProperty(this, name, val);
			return val;
		}

		if (!Reflect.hasField(data, name)) {
			Reflect.setField(data, name, val);
			return val;
		}

		var field = Reflect.field(data, name);
		var kind = __paramTypeOf(Type.getClass(field));
		var isNotNull = val != null;
		// cant do "field is ShaderInput" for some reason
		if (kind == 1) {
			if (field.__length <= 1) {
				// that means we wait for a single number, instead of an array
				if (field.__isInt && isNotNull && !(val is Int)) {
					throw new ShaderTypeException(name, Type.getClass(val), 'Int');
					return null;
				} else
				if (field.__isBool && isNotNull && !(val is Bool)) {
					throw new ShaderTypeException(name, Type.getClass(val), 'Bool');
					return null;
				} else
				if (field.__isFloat && isNotNull && !(val is Float)) {
					throw new ShaderTypeException(name, Type.getClass(val), 'Float');
					return null;
				}
				return field.value = isNotNull ? [val] : null;
			} else {
				if (isNotNull && !(val is Array)) {
					throw new ShaderTypeException(name, Type.getClass(val), Array);
					return null;
				}
				return field.value = val;
			}
		} else if (kind == 2) {
			// shader input!!
			var bitmap:BitmapData;
			if (!isNotNull) bitmap = null;
			else if (val is BitmapData) bitmap = val;
			else if (val is FlxGraphic) bitmap = val.bitmap;
			else {
				throw new ShaderTypeException(name, Type.getClass(val), BitmapData);
				return null;
			}
			field.input = bitmap;
		}

		return val;
	}
}

class ShaderTemplates {
	public static final fragHeader:String = "varying float openfl_Alphav;
varying vec4 openfl_ColorMultiplierv;
varying vec4 openfl_ColorOffsetv;
varying vec2 openfl_TextureCoordv;

uniform bool openfl_HasColorTransform;
uniform vec2 openfl_TextureSize;
uniform sampler2D bitmap;

uniform bool hasTransform;
uniform bool hasColorTransform;

vec4 applyFlixelEffects(vec4 color) {
	if(!hasTransform) {
		return color;
	}

	if(color.a == 0.0) {
		return vec4(0.0, 0.0, 0.0, 0.0);
	}

	if(!hasColorTransform) {
		return color * openfl_Alphav;
	}

	color.rgb = color.rgb / color.a;
	color = clamp(openfl_ColorOffsetv + (color * openfl_ColorMultiplierv), 0.0, 1.0);

	if(color.a > 0.0) {
		return vec4(color.rgb * color.a * openfl_Alphav, color.a * openfl_Alphav);
	}
	return vec4(0.0, 0.0, 0.0, 0.0);
}

vec4 flixel_texture2D(sampler2D bitmap, vec2 coord) {
	vec4 color = texture2D(bitmap, coord);
	return applyFlixelEffects(color);
}

uniform vec4 _camSize;

float map(float value, float min1, float max1, float min2, float max2) {
	return min2 + (value - min1) * (max2 - min2) / (max1 - min1);
}

vec2 getCamPos(vec2 pos) {
	vec4 size = _camSize / vec4(openfl_TextureSize, openfl_TextureSize);
	return vec2(map(pos.x, size.x, size.x + size.z, 0.0, 1.0), map(pos.y, size.y, size.y + size.w, 0.0, 1.0));
}
vec2 camToOg(vec2 pos) {
	vec4 size = _camSize / vec4(openfl_TextureSize, openfl_TextureSize);
	return vec2(map(pos.x, 0.0, 1.0, size.x, size.x + size.z), map(pos.y, 0.0, 1.0, size.y, size.y + size.w));
}
vec4 textureCam(sampler2D bitmap, vec2 pos) {
	return flixel_texture2D(bitmap, camToOg(pos));
}";

	public static final fragBody:String = "gl_FragColor = flixel_texture2D(bitmap, openfl_TextureCoordv);";
	public static final vertHeader:String = "attribute float openfl_Alpha;
attribute vec4 openfl_ColorMultiplier;
attribute vec4 openfl_ColorOffset;
attribute vec4 openfl_Position;
attribute vec2 openfl_TextureCoord;

varying float openfl_Alphav;
varying vec4 openfl_ColorMultiplierv;
varying vec4 openfl_ColorOffsetv;
varying vec2 openfl_TextureCoordv;

uniform mat4 openfl_Matrix;
uniform bool openfl_HasColorTransform;
uniform vec2 openfl_TextureSize;

attribute float alpha;
attribute vec4 colorMultiplier;
attribute vec4 colorOffset;
uniform bool hasColorTransform;";

	public static final vertBody:String = "openfl_Alphav = openfl_Alpha;
openfl_TextureCoordv = openfl_TextureCoord;

if(openfl_HasColorTransform) {
	openfl_ColorMultiplierv = openfl_ColorMultiplier;
	openfl_ColorOffsetv = openfl_ColorOffset / 255.0;
}

openfl_Alphav = openfl_Alpha * alpha;

if(hasColorTransform) {
	openfl_ColorOffsetv = colorOffset / 255.0;
	openfl_ColorMultiplierv = colorMultiplier;
}

gl_Position = openfl_Matrix * openfl_Position;";

// TODO: make this ignore comments
public static final vertBackCompatVarList:Array<EReg> = [
	~/attribute float alpha/,
	~/attribute vec4 colorMultiplier/,
	~/attribute vec4 colorOffset/,
	~/uniform bool hasColorTransform/
];

public static final vertHeaderBackCompat:String = "attribute float openfl_Alpha;
attribute vec4 openfl_ColorMultiplier;
attribute vec4 openfl_ColorOffset;
attribute vec4 openfl_Position;
attribute vec2 openfl_TextureCoord;

varying float openfl_Alphav;
varying vec4 openfl_ColorMultiplierv;
varying vec4 openfl_ColorOffsetv;
varying vec2 openfl_TextureCoordv;

uniform mat4 openfl_Matrix;
uniform bool openfl_HasColorTransform;
uniform vec2 openfl_TextureSize;";

public static final vertBodyBackCompat:String = "openfl_Alphav = openfl_Alpha;
openfl_TextureCoordv = openfl_TextureCoord;

if(openfl_HasColorTransform) {
	openfl_ColorMultiplierv = openfl_ColorMultiplier;
	openfl_ColorOffsetv = openfl_ColorOffset / 255.0;
}

gl_Position = openfl_Matrix * openfl_Position;";

	public static final defaultVertexSource:String = "#pragma header

void main(void) {
	#pragma body
}";

	public static final defaultFragmentSource:String = "#pragma header

void main(void) {
	#pragma body
}";
}

class ShaderTypeException extends Exception {
	var has:Class<Dynamic>;
	var want:Class<Dynamic>;
	var name:String;

	public function new(name:String, has:Class<Dynamic>, want:Dynamic) {
		this.has = has;
		this.want = want;
		this.name = name;
		super('ShaderTypeException - Tried to set the shader uniform "${name}" as a ${Type.getClassName(has)}, but the shader uniform is a ${Std.string(want)}.');
	}
}

class ShaderErrorPosition {
	public var column:Int;
	public var line:Int;
	public var message:String;

	public function new(line:String, column:String, message:String) {
		this.line = Std.parseInt(line);
		this.column = Std.parseInt(column);
		this.message = message;
	}
}
