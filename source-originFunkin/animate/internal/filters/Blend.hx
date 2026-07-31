package animate.internal.filters;

import flixel.FlxG;
import openfl.display.BitmapData;
import openfl.display.BlendMode;
import openfl.display.GraphicsShader;
import openfl.display.OpenGLRenderer;
import openfl.display.Shader;
import openfl.display.ShaderInput;
import openfl.display.ShaderParameter;
import openfl.geom.ColorTransform;
import openfl.geom.Matrix;

class Blend
{
	public static function resolve(?blend:BlendMode, ?drawBlend:BlendMode):Null<BlendMode>
	{
		if (Frame.__isDirtyCall)
			return NORMAL;

		if (blend == null || blend == NORMAL)
			return drawBlend;

		return blend;
	}

	public static function fromInt(blend:Null<Int>):BlendMode
	{
		if (blend == null)
			return NORMAL;

		return switch (blend)
		{
			case 0: ADD;
			case 1: ALPHA;
			case 2: DARKEN;
			case 3: DIFFERENCE;
			case 4: ERASE;
			case 5: HARDLIGHT;
			case 6: INVERT;
			case 7: LAYER;
			case 8: LIGHTEN;
			case 9: MULTIPLY;
			case 10: NORMAL;
			case 11: OVERLAY;
			case 12: SCREEN;
			case 13: SHADER;
			case 14: SUBTRACT;
			case _: NORMAL;
		};
	}

	#if !flash
	public static function isGpuSupported(blend:BlendMode):Bool
	{
		return switch (blend)
		{
			case NORMAL | ADD | MULTIPLY | SCREEN | SUBTRACT #if desktop | LIGHTEN /**| DARKEN**/ #end: true;
			case _: false;
		}
	}

	public static function blend(target:BitmapData, bitmap1:BitmapData, bitmap2:BitmapData, blend:BlendMode):Void
	{
		if (blend == NORMAL || blend == LAYER || blend == SHADER)
		{
			target.draw(bitmap1);
			target.draw(bitmap2);
			return;
		}

		var shader = new BlendShader(bitmap1, bitmap2, cast blend);
		FilterRenderer.renderWithShader(target, bitmap1, shader);
	}
	#end
}

#if !flash
class BlendShader extends GraphicsShader
{
	@:glFragmentSource('
        #pragma header
        
        uniform sampler2D bitmap2;
        uniform int blendMode;
        
        float screen(float a, float b) {
            return 1.0 - (1.0 - a) * (1.0 - b);
        }
        
        float hardlight(float a, float b) {
            return (b > 0.5) ? (1.0 - (1.0 - a) * (1.0 - 2.0 * (b - 0.5))) : (a * (2.0 * b));
        }
        
        float overlay(float a, float b) {
            return (a < 0.5) ? (2.0 * a * b) : (1.0 - 2.0 * (1.0 - a) * (1.0 - b));
        }
        
        vec4 applyBlend(vec4 a, vec4 b, int mode)
		{
            if (mode == -1) return a; // NORMAL/LAYER/SHADER
            if (a.a == 0.0) return a;
            
            vec4 result = a;
            
			switch (mode) {
				case 0: // ADD
					result.rgb = a.rgb + b.rgb;
					break;
				case 1: // ALPHA
					result.a = b.a;
					break;
				case 2: // DARKEN
					result.rgb = min(a.rgb, b.rgb);
					break;
				case 3: // DIFFERENCE
					result.rgb = abs(a.rgb - b.rgb);
					break;
				case 4: // ERASE
					result.a = a.a * (1.0 - b.a);
					result.rgb = a.rgb;
					break;
				case 5: // HARDLIGHT
					result.r = hardlight(a.r, b.r);
					result.g = hardlight(a.g, b.g);
					result.b = hardlight(a.b, b.b);
					break;
				case 6: // INVERT
					result.rgb = vec3(1.0) - a.rgb;
					break;
				case 8: // LIGHTEN
					result.rgb = max(a.rgb, b.rgb);
					break;
				case 9: // MULTIPLY
					result.rgb = a.rgb * b.rgb;
					break;
				case 11: // OVERLAY
					result.r = overlay(a.r, b.r);
					result.g = overlay(a.g, b.g);
					result.b = overlay(a.b, b.b);
					break;
				case 12: // SCREEN
					result.r = screen(a.r, b.r);
					result.g = screen(a.g, b.g);
					result.b = screen(a.b, b.b);
					break;
				case 14: // SUBTRACT
					result.rgb = a.rgb - b.rgb;
					break;
			}
            
            result.rgb = mix(a.rgb, result.rgb, b.a);
            return result;
        }
        
        void main() {
			vec4 bg = texture2D(bitmap, openfl_TextureCoordv);
			vec4 fg = texture2D(bitmap2, openfl_TextureCoordv);
            gl_FragColor = applyBlend(bg, fg, blendMode);
        }
    ')
	public function new(bitmap1:BitmapData, bitmap2:BitmapData, blendInt:Int)
	{
		super();

		this.bitmap.input = bitmap1;
		this.bitmap2.input = bitmap2;
		this.blendMode.value = [blendInt];
	}
}
#end
