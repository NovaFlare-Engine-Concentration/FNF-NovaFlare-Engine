package general.shaders.flixel.system;

import flixel.system.FlxAssets.FlxShader as OriginalFlxShader;

/**
 * A modded FlxShader that allows using GLSL Es 300 and GLSL 330
 * @author Mihai Alexandru (M.A. Jigsaw)
 */
class FlxShader extends OriginalFlxShader
{
	public var custom:Bool = false;
	public var save:Bool = true;

	public override function new(?save:Bool)
	{
		if (save != null)
			this.save = save;

		super();
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
			initGLforce();
	}

	public function initGLforce()
	{
		if (!custom)
			initGood(glFragmentSource, glVertexSource);
	}

	public function initGood(glFragmentSource:String, glVertexSource:String)
	{
		#if mobile
		var prefix = '';
		#elseif lime_opengles
		var prefix = "#version 300 es\n";
		#else
		var prefix = "#version 330\n";
		#end

		prefix += "#ifdef GL_ES\n"
			+ (precisionHint == FULL ? "#ifdef GL_FRAGMENT_PRECISION_HIGH\n"
				+ "precision highp float;\n"
				+ "#else\n"
				+ "precision mediump float;\n"
				+ "#endif\n" : "precision lowp float;\n")
			+ "#endif\n\n";

		#if mobile
		var vertex = prefix + glVertexSource;
		var fragment = prefix + glFragmentSource;
		@:privateAccess
		var preparedSources = __prepareMobileGLSLProgram(vertex, fragment);
		vertex = preparedSources.vertex;
		fragment = preparedSources.fragment;
		var id = preparedSources.cacheKey + '\nvertex:' + vertex.length + '\n' + vertex
			+ '\nfragment:' + fragment.length + '\n' + fragment;
		#elseif lime_opengles
		prefix += 'out vec4 output_FragColor;\n';
		var vertex = prefix
			+ glVertexSource.replace("attribute", "in")
				.replace("varying", "out")
				.replace("texture2D", "texture")
				.replace("gl_FragColor", "output_FragColor");
		var fragment = prefix + glFragmentSource.replace("varying", "in").replace("texture2D", "texture").replace("gl_FragColor", "output_FragColor");
		var id = vertex + fragment;
		#else
		var vertex = prefix + glVertexSource;
		var fragment = prefix + glFragmentSource;
		var id = vertex + fragment;
		#end
		@:privateAccess
		if (__context.__programs.exists(id) && save)
		{
			@:privateAccess
			program = __context.__programs.get(id);
		}
		else
		{
			program = __context.createProgram(GLSL);

			@:privateAccess
			program.__glProgram = __createGLProgram(vertex, fragment);
			@:privateAccess
			if (save)
				__context.__programs.set(id, program);
		}

		if (program != null)
		{
			#if mobile
			@:privateAccess
			__glTransformRevision = general.shaders.MobileShaderConverter.revision;
			@:privateAccess
			__glProgramDirty = false;
			#end
			__refreshGLBindingLocations();
		}
	}
}
