package funkin.graphics.shaders;

import flixel.graphics.tile.FlxGraphicsShader;

class MultiBufferShader extends FlxGraphicsShader
{
  #if ORIGIN_SDL2_COMPAT
  @:glFragmentSource('
    #pragma header
    void main() {
      gl_FragColor = flixel_texture2D(bitmap, openfl_TextureCoordv);
    }')
  #else
  @:glFragmentSource('
		#pragma header

		void main()
		{
			vec4 color = flixel_texture2D(bitmap, openfl_TextureCoordv);

      if (sampleAttachment)
      {
        gl_FragData[1] = color;
      }
      else
      {
        gl_FragData[1] = vec4(0.0, 0.0, 0.0, 0.0);
      }

      gl_FragData[0] = color;
		}')
  #end
  public function new()
  {
    super();
  }
}
