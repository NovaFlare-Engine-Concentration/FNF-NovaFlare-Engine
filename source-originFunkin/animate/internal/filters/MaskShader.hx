package animate.internal.filters;

#if !flash
import flixel.util.FlxDestroyUtil;
import openfl.display.BitmapData;
import openfl.display.GraphicsShader;
import openfl.geom.Rectangle;

class MaskShader extends GraphicsShader
{
	@:glFragmentSource('
		#pragma header

		uniform sampler2D maskBitmap;
		uniform vec2 maskUVOffset;
		uniform vec2 maskUVScale;

		vec4 animate_mask()
		{
			vec2 maskCoord = (openfl_TextureCoordv * maskUVScale) + maskUVOffset;			
			vec4 maskerColor = texture2D(maskBitmap, maskCoord);

			if (maskerColor.a <= 0.0)
				return vec4(0.0);
		
			vec4 color = texture2D(bitmap, openfl_TextureCoordv);
	' +
		#if html5
		'color.a *= maskerColor.a;'
		#else
		'color *= maskerColor.a;'
		#end
		+ '
		return color;
		}
		
		void main()
		{
			gl_FragColor = animate_mask();
		}
	')
	public function new()
	{
		super();

		this.maskUVOffset.value = [];
		this.maskUVScale.value = [];
	}

	public function setup(masked:BitmapData, masker:BitmapData, x:Float, y:Float)
	{
		this.maskBitmap.input = masker;

		this.maskUVOffset.value[0] = x / masker.width;
		this.maskUVOffset.value[1] = y / masker.height;

		this.maskUVScale.value[0] = masked.width / masker.width;
		this.maskUVScale.value[1] = masked.height / masker.height;

		return this;
	}

	static var shader(get, null):MaskShader;

	inline static function get_shader()
	{
		return shader ?? (shader = new MaskShader());
	}

	public static function maskAlpha(masked:BitmapData, masker:BitmapData, rect:Rectangle) @:privateAccess
	{
		if (masked == null || masker == null || masked.width <= 0 || masked.height <= 0 || masker.width <= 0 || masker.height <= 0)
			return;

		// Preparing the shader and extra bitmaps needed
		var shader = shader.setup(masked, masker, rect.x, rect.y);
		var maskedClone = masked.clone();

		// Render the mask
		FilterRenderer.renderWithShader(masked, maskedClone, shader);

		// Dispose crap after rendering
		maskedClone = FlxDestroyUtil.dispose(maskedClone);
		shader.maskBitmap.input = null;
	}
}
#end
