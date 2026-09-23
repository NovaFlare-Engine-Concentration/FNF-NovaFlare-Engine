package general.shaders;

#if CUSTOM_SHADERS_ALLOWED
import openfl.display.ShaderParameter;
import openfl.display.ShaderParameterType;
import openfl.display.BitmapData;
import openfl.display.ShaderInput;
import openfl.Lib;

import general.shaders.openfl.filters.ShaderFilter;

typedef ShaderEffect =
{
	var shader:Dynamic;
}

class RadialBlurEffect extends Effect
{
	public var shader:ShaderFilter = new ShaderFilter(new RadialBlurShader());

	public function new(strength:Float = 10, x:Float = 0.0, y:Float = 0.0, zoom:Float = 1.0)
	{
		super();
		daShader = shader;
		setStrength(strength);
		setPos(x, y);
		setZoom(zoom);
	}

	public function setStrength(value:Float = 10)
	{
		shader.shader.data.strength.value = [value];
	}

	public function setPos(x:Float = 0.0, y:Float = 0.0)
	{
		shader.shader.data.xPos.value = [x];
		shader.shader.data.yPos.value = [y];
	}

	public function setZoom(zoom:Float = 1.0)
	{
		shader.shader.data.zoom.value = [zoom];
	}
}

class RadialBlurShader extends FlxShader
{
	// https://www.shadertoy.com/view/XsfSDs with some modifications
	@:glFragmentSource('
	#pragma header
	vec2 fragCoord = openfl_TextureCoordv*openfl_TextureSize;
    vec2 iResolution = openfl_TextureSize;
	uniform float strength;
	uniform float xPos;
	uniform float yPos;
	uniform float zoom; // idfk what to call this shit
	
	
	void main()
	{
		vec2 pos = vec2(xPos, yPos); 
		vec2 center = pos / iResolution.xy;
		float blurStart = zoom;
		float blurWidth = blurStart * 0.1;
	
		
		vec2 uv = fragCoord.xy / iResolution.xy;
		
		uv -= center;
		float precompute = blurWidth * (1.14 / strength);
		
		vec4 color = vec4(0.0);
		for(float i = 0.0; i < strength; i++)
		{
			float scale = blurStart + (float(i)* precompute);
			color += flixel_texture2D(bitmap, uv * scale + center);
		}
		
		
		color /= float(strength);
		
		gl_FragColor = color;
	}
  ')
	public function new()
	{
		super();
	}
}

class BulgeEffect extends Effect
{
	public var shader:ShaderFilter = new ShaderFilter(new BulgeShader());

	public function setValue(value:Float)
	{
		shader.shader.data.value.value = [value];
	}

	public function new(value:Float)
	{
		super();
		daShader = shader;
		setValue(value);
	}
}

// MY FIRST TIME PORTING SHADERS FROM SHADERTOY IDFK -karim
class BulgeShader extends FlxShader
{
	// https://www.shadertoy.com/view/XsVSW1  with some modifications
	@:glFragmentSource('
	#pragma header
    uniform float value;
    vec2 fragCoord = openfl_TextureCoordv*openfl_TextureSize;
    vec2 iResolution = openfl_TextureSize;

 void main() {
    vec2 p = fragCoord.xy/iResolution.xy - 0.5;

      // cartesian to polar coordinates
      float r = length(p);
      float a = atan(p.y, p.x);
  
    // distort
    if(value == 0.0) {
        vec2 guh = fragCoord.xy/iResolution.xy - 0.5;
        r = length(guh);
    } else {
        r = r*r* value; // bulge
    }
  
    p = r * vec2(cos(a), sin(a));
  
    vec4 color = flixel_texture2D(bitmap, p + 0.5);
    gl_FragColor = color;
    }
  ')
	public function new()
	{
		super();
	}
}

class BuildingEffect
{
	public var shader:ShaderFilter = new ShaderFilter(new BuildingShader());

	public function new()
	{
		shader.shader.data.alphaShit.value = [0];
	}

	public function addAlpha(alpha:Float)
	{
		shader.shader.data.alphaShit.value[0] += alpha;
	}

	public function setAlpha(alpha:Float)
	{
		shader.shader.data.alphaShit.value[0] = alpha;
	}
}

class BuildingShader extends FlxShader
{
	@:glFragmentSource('
    #pragma header
    uniform float alphaShit;
    void main()
    {

      vec4 color = flixel_texture2D(bitmap,openfl_TextureCoordv);
      if (color.a > 0.0)
        color-=alphaShit;

      gl_FragColor = color;
    }
  ')
	public function new()
	{
		super();
	}
}

class ChromaticAberrationShader extends FlxShader
{
	@:glFragmentSource('
		#pragma header

		uniform float rOffset;
		uniform float gOffset;
		uniform float bOffset;

		void main()
		{
			vec4 col1 = texture2D(bitmap, openfl_TextureCoordv.st - vec2(rOffset, 0.0));
			vec4 col2 = texture2D(bitmap, openfl_TextureCoordv.st - vec2(gOffset, 0.0));
			vec4 col3 = texture2D(bitmap, openfl_TextureCoordv.st - vec2(bOffset, 0.0));
			vec4 toUse = texture2D(bitmap, openfl_TextureCoordv);
			toUse.r = col1.r;
			toUse.g = col2.g;
			toUse.b = col3.b;

			gl_FragColor = toUse;
		}')
	public function new()
	{
		super();
	}
}

class ChromaticAberrationEffect extends Effect
{
	public var shader:ShaderFilter = new ShaderFilter(new ChromaticAberrationShader());

	public function setChrome(globalChromeOffset:Float, ?redOffset:Float = 0.0, ?greenOffset:Float = 0.0, ?blueOffset:Float = 0.0):Void
	{
		if (globalChromeOffset != 0.0)
		{
			shader.shader.data.rOffset.value = [globalChromeOffset];
			shader.shader.data.gOffset.value = [0.0];
			shader.shader.data.bOffset.value = [-globalChromeOffset];
		}
		else
		{
			shader.shader.data.rOffset.value = [redOffset];
			shader.shader.data.gOffset.value = [greenOffset];
			shader.shader.data.bOffset.value = [blueOffset];
		}
	}

	public function new(globalChromeOffset:Float, ?redOffset:Float = 0.0, ?greenOffset:Float = 0.0, ?blueOffset:Float = 0.0)
	{
		super();
		daShader = shader;
		if (globalChromeOffset != 0.0)
		{
			shader.shader.data.rOffset.value = [globalChromeOffset];
			shader.shader.data.gOffset.value = [0.0];
			shader.shader.data.bOffset.value = [-globalChromeOffset];
		}
		else
		{
			shader.shader.data.rOffset.value = [redOffset];
			shader.shader.data.gOffset.value = [greenOffset];
			shader.shader.data.bOffset.value = [blueOffset];
		}
	}
}

class ScanlineEffect extends Effect
{
	public var shader:ShaderFilter = new ShaderFilter(new Scanline());

	public function new(lockAlpha:Bool)
	{
		super();
		daShader = shader;
		shader.shader.data.lockAlpha.value = [lockAlpha];
	}
}

class Scanline extends FlxShader
{
	@:glFragmentSource('
		#pragma header
		const float scale = 1.0;
	uniform bool lockAlpha;
		void main()
		{
			if (mod(floor(openfl_TextureCoordv.y * openfl_TextureSize.y / scale), 2.0) == 0.0 ){
				float bitch = 1.0;
	
				vec4 texColor = texture2D(bitmap, openfl_TextureCoordv);
				if (lockAlpha) bitch = texColor.a;
				gl_FragColor = vec4(0.0, 0.0, 0.0, bitch);
			}else{
				gl_FragColor = texture2D(bitmap, openfl_TextureCoordv);
			}
		}')
	public function new()
	{
		super();
	}
}

class TiltshiftEffect extends Effect
{
	public var shader:ShaderFilter = new ShaderFilter(new Tiltshift());

	public function new(blurAmount:Float, center:Float)
	{
		super();
		daShader = shader;
		shader.shader.data.bluramount.value = [blurAmount];
		shader.shader.data.center.value = [center];
	}
}

class Tiltshift extends FlxShader
{
	@:glFragmentSource('
		#pragma header
		 
		// I am hardcoding the constants like a jerk
			
		uniform float bluramount;
		uniform float center;
		const float stepSize = 0.004;
		const float steps = 3.0;
		 
		const float minOffs = (float(steps-1.0)) / -2.0;
		const float maxOffs = (float(steps-1.0)) / +2.0;
		 
		void main() {
			float amount;
			vec4 blurred;
				
			// Work out how much to blur based on the mid point 
			amount = pow((openfl_TextureCoordv.y * center) * 2.0 - 1.0, 2.0) * bluramount;
				
			// This is the accumulation of color from the surrounding pixels in the texture
			blurred = vec4(0.0, 0.0, 0.0, 1.0);
				
			// From minimum offset to maximum offset
			for (float offsX = minOffs; offsX <= maxOffs; ++offsX) {
				for (float offsY = minOffs; offsY <= maxOffs; ++offsY) {
		 
					// copy the coord so we can mess with it
					vec2 temp_tcoord = openfl_TextureCoordv.xy;
		 
					//work out which uv we want to sample now
					temp_tcoord.x += offsX * amount * stepSize;
					temp_tcoord.y += offsY * amount * stepSize;
		 
					// accumulate the sample 
					blurred += texture2D(bitmap, temp_tcoord);
				}
			} 
				
			// because we are doing an average, we divide by the amount (x AND y, hence steps * steps)
			blurred /= float(steps * steps);
		 
			// return the final blurred color
			gl_FragColor = blurred;
		}')
	public function new()
	{
		super();
	}
}

class GreyscaleEffect extends Effect
{
	public var shader:ShaderFilter = new ShaderFilter(new GreyscaleShader());

	public function new()
	{
		super();
		daShader = shader;
	}
}

class GreyscaleShader extends FlxShader
{
	@:glFragmentSource('
	#pragma header
	void main() {
		vec4 color = texture2D(bitmap, openfl_TextureCoordv);
		float gray = dot(color.rgb, vec3(0.299, 0.587, 0.114));
		gl_FragColor = vec4(vec3(gray), color.a);
	}
	
	
	')
	public function new()
	{
		super();
	}
}

class BrightEffect extends Effect
{
	public var shader:ShaderFilter = new ShaderFilter(new BrightShader());

	public function setup()
	{
	}

	public function setBrightness(brightness:Float):Void
	{
		shader.shader.data.brightness.value = [brightness];
	}

	public function setContrast(contrast:Float):Void
	{
		shader.shader.data.contrast.value = [contrast];
	}

	public function new(brightness:Float, contrast:Float)
	{
		super();
		daShader = shader;
		setBrightness(brightness);
		setContrast(contrast);
	}
}

class BrightShader extends FlxShader
{
	@:glFragmentSource('
		#pragma header

		uniform float brightness;
		uniform float contrast;

		void main()
		{
			vec4 col = texture2D(bitmap, openfl_TextureCoordv);
			col.rgb = col.rgb * contrast;
			col.rgb = col.rgb + brightness;

			gl_FragColor = col;
		}')
	public function new()
	{
		super();
	}
}

class GrainEffect extends Effect
{
	public var shader:ShaderFilter = new ShaderFilter(new Grain());

	public function update(elapsed:Float)
	{
		shader.shader.data.uTime.value[0] += elapsed;
	}

	public function new(grainsize:Float, lumamount:Float, lockAlpha:Bool)
	{
		super();
		daShader = shader;
		shader.shader.data.lumamount.value = [lumamount];
		shader.shader.data.grainsize.value = [grainsize];
		shader.shader.data.lockAlpha.value = [lockAlpha];
		shader.shader.data.uTime.value = [FlxG.random.float(0, 8)];
		PlayState.instance.shaderUpdates.push(update);
	}
}

class Grain extends FlxShader
{
	@:glFragmentSource('
		#pragma header

		uniform float uTime;

		const float permTexUnit = 1.0/256.0;        // Perm texture texel-size
		const float permTexUnitHalf = 0.5/256.0;    // Half perm texture texel-size

		const float grainamount = 0.05; //grain amount
		bool colored = false; //colored noise?
		uniform float coloramount;
		uniform float grainsize; //grain particle size (1.5 - 2.5)
		uniform float lumamount;
	        uniform bool lockAlpha;

		//a random texture generator, but you can also use a pre-computed perturbation texture
	
		vec4 rnm(in vec2 tc)
		{
			float noise =  sin(dot(tc + vec2(uTime,uTime),vec2(12.9898,78.233))) * 43758.5453;

			float noiseR =  fract(noise)*2.0-1.0;
			float noiseG =  fract(noise*1.2154)*2.0-1.0;
			float noiseB =  fract(noise * 1.3453) * 2.0 - 1.0;
			float noiseA =  (fract(noise * 1.3647) * 2.0 - 1.0);

			return vec4(noiseR,noiseG,noiseB,noiseA);
		}

		float fade(in float t) {
			return t*t*t*(t*(t*6.0-15.0)+10.0);
		}

		float pnoise3D(in vec3 p)
		{
			vec3 pi = permTexUnit*floor(p)+permTexUnitHalf; // Integer part, scaled so +1 moves permTexUnit texel
			// and offset 1/2 texel to sample texel centers
			vec3 pf = fract(p);     // Fractional part for interpolation

			// Noise contributions from (x=0, y=0), z=0 and z=1
			float perm00 = rnm(pi.xy).a ;
			vec3  grad000 = rnm(vec2(perm00, pi.z)).rgb * 4.0 - 1.0;
			float n000 = dot(grad000, pf);
			vec3  grad001 = rnm(vec2(perm00, pi.z + permTexUnit)).rgb * 4.0 - 1.0;
			float n001 = dot(grad001, pf - vec3(0.0, 0.0, 1.0));

			// Noise contributions from (x=0, y=1), z=0 and z=1
			float perm01 = rnm(pi.xy + vec2(0.0, permTexUnit)).a ;
			vec3  grad010 = rnm(vec2(perm01, pi.z)).rgb * 4.0 - 1.0;
			float n010 = dot(grad010, pf - vec3(0.0, 1.0, 0.0));
			vec3  grad011 = rnm(vec2(perm01, pi.z + permTexUnit)).rgb * 4.0 - 1.0;
			float n011 = dot(grad011, pf - vec3(0.0, 1.0, 1.0));

			// Noise contributions from (x=1, y=0), z=0 and z=1
			float perm10 = rnm(pi.xy + vec2(permTexUnit, 0.0)).a ;
			vec3  grad100 = rnm(vec2(perm10, pi.z)).rgb * 4.0 - 1.0;
			float n100 = dot(grad100, pf - vec3(1.0, 0.0, 0.0));
			vec3  grad101 = rnm(vec2(perm10, pi.z + permTexUnit)).rgb * 4.0 - 1.0;
			float n101 = dot(grad101, pf - vec3(1.0, 0.0, 1.0));

			// Noise contributions from (x=1, y=1), z=0 and z=1
			float perm11 = rnm(pi.xy + vec2(permTexUnit, permTexUnit)).a ;
			vec3  grad110 = rnm(vec2(perm11, pi.z)).rgb * 4.0 - 1.0;
			float n110 = dot(grad110, pf - vec3(1.0, 1.0, 0.0));
			vec3  grad111 = rnm(vec2(perm11, pi.z + permTexUnit)).rgb * 4.0 - 1.0;
			float n111 = dot(grad111, pf - vec3(1.0, 1.0, 1.0));

			// Blend contributions along x
			vec4 n_x = mix(vec4(n000, n001, n010, n011), vec4(n100, n101, n110, n111), fade(pf.x));

			// Blend contributions along y
			vec2 n_xy = mix(n_x.xy, n_x.zw, fade(pf.y));

			// Blend contributions along z
			float n_xyz = mix(n_xy.x, n_xy.y, fade(pf.z));

			// We are done, return the final noise value.
			return n_xyz;
		}

		//2d coordinate orientation thing
		vec2 coordRot(in vec2 tc, in float angle)
		{
			float aspect = openfl_TextureSize.x/openfl_TextureSize.y;
			float rotX = ((tc.x*2.0-1.0)*aspect*cos(angle)) - ((tc.y*2.0-1.0)*sin(angle));
			float rotY = ((tc.y*2.0-1.0)*cos(angle)) + ((tc.x*2.0-1.0)*aspect*sin(angle));
			rotX = ((rotX/aspect)*0.5+0.5);
			rotY = rotY*0.5+0.5;
			return vec2(rotX,rotY);
		}

		void main()
		{
			vec2 texCoord = openfl_TextureCoordv.st;

			vec3 rotOffset = vec3(1.425,3.892,5.835); //rotation offset values
			vec2 rotCoordsR = coordRot(texCoord, uTime + rotOffset.x);
			vec3 noise = vec3(pnoise3D(vec3(rotCoordsR*vec2(openfl_TextureSize.x/grainsize,openfl_TextureSize.y/grainsize),0.0)));

			if (colored)
			{
				vec2 rotCoordsG = coordRot(texCoord, uTime + rotOffset.y);
				vec2 rotCoordsB = coordRot(texCoord, uTime + rotOffset.z);
				noise.g = mix(noise.r,pnoise3D(vec3(rotCoordsG*vec2(openfl_TextureSize.x/grainsize,openfl_TextureSize.y/grainsize),1.0)),coloramount);
				noise.b = mix(noise.r,pnoise3D(vec3(rotCoordsB*vec2(openfl_TextureSize.x/grainsize,openfl_TextureSize.y/grainsize),2.0)),coloramount);
			}

			vec3 col = texture2D(bitmap, openfl_TextureCoordv).rgb;

			//noisiness response curve based on scene luminance
			vec3 lumcoeff = vec3(0.299,0.587,0.114);
			float luminance = mix(0.0,dot(col, lumcoeff),lumamount);
			float lum = smoothstep(0.2,0.0,luminance);
			lum += luminance;


			noise = mix(noise,vec3(0.0),pow(lum,4.0));
			col = col+noise*grainamount;

				float bitch = 1.0;
			vec4 texColor = texture2D(bitmap, openfl_TextureCoordv);
				if (lockAlpha) bitch = texColor.a;
			gl_FragColor =  vec4(col,bitch);
		}')
	public function new()
	{
		super();
	}
}

class VCRDistortionEffect extends Effect
{
	public var shader:ShaderFilter = new ShaderFilter(new VCRDistortionShader());

	public function new(glitchFactor:Float, distortion:Bool = true, perspectiveOn:Bool = true, vignetteMoving:Bool = true)
	{
		super();
		daShader = shader;
		shader.shader.data.iTime.value = [0];
		shader.shader.data.vignetteOn.value = [true];
		shader.shader.data.perspectiveOn.value = [perspectiveOn];
		shader.shader.data.distortionOn.value = [distortion];
		shader.shader.data.scanlinesOn.value = [true];
		shader.shader.data.vignetteMoving.value = [vignetteMoving];
		shader.shader.data.glitchModifier.value = [glitchFactor];
		shader.shader.data.iResolution.value = [Lib.current.stage.stageWidth, Lib.current.stage.stageHeight];
		PlayState.instance.shaderUpdates.push(update);
	}

	public function update(elapsed:Float)
	{
		shader.shader.data.iTime.value[0] += elapsed;
		shader.shader.data.iResolution.value = [Lib.current.stage.stageWidth, Lib.current.stage.stageHeight];
	}

	public function setVignette(state:Bool)
	{
		shader.shader.data.vignetteOn.value[0] = state;
	}

	public function setPerspective(state:Bool)
	{
		shader.shader.data.perspectiveOn.value[0] = state;
	}

	public function setGlitchModifier(modifier:Float)
	{
		shader.shader.data.glitchModifier.value[0] = modifier;
	}

	public function setDistortion(state:Bool)
	{
		shader.shader.data.distortionOn.value[0] = state;
	}

	public function setScanlines(state:Bool)
	{
		shader.shader.data.scanlinesOn.value[0] = state;
	}

	public function setVignetteMoving(state:Bool)
	{
		shader.shader.data.vignetteMoving.value[0] = state;
	}
}

class VCRDistortionShader extends FlxShader // https://www.shadertoy.com/view/ldjGzV and https://www.shadertoy.com/view/Ms23DR and https://www.shadertoy.com/view/MsXGD4 and https://www.shadertoy.com/view/Xtccz4
{
	@:glFragmentSource('
    #pragma header

    uniform float iTime;
    uniform bool vignetteOn;
    uniform bool perspectiveOn;
    uniform bool distortionOn;
    uniform bool scanlinesOn;
    uniform bool vignetteMoving;
    uniform float glitchModifier;
    uniform vec3 iResolution;

    float onOff(float a, float b, float c)
    {
    	return step(c, sin(iTime + a*cos(iTime*b)));
    }

    float ramp(float y, float start, float end)
    {
    	float inside = step(start,y) - step(end,y);
    	float fact = (y-start)/(end-start)*inside;
    	return (1.-fact) * inside;

    }

    vec4 getVideo(vec2 uv)
      {
      	vec2 look = uv;
        if(distortionOn){
        	float window = 1./(1.+20.*(look.y-mod(iTime/4.,1.))*(look.y-mod(iTime/4.,1.)));
        	look.x = look.x + (sin(look.y*10. + iTime)/50.*onOff(4.,4.,.3)*(1.+cos(iTime*80.))*window)*(glitchModifier*2.0);
        	float vShift = 0.4*onOff(2.,3.,.9)*(sin(iTime)*sin(iTime*20.) + (0.5 + 0.1*sin(iTime*200.)*cos(iTime)));
        	look.y = mod(look.y + vShift*glitchModifier, 1.);
        }
      	vec4 video = flixel_texture2D(bitmap,look);

      	return video;
      }

    vec2 screenDistort(vec2 uv)
    {
      if(perspectiveOn){
        uv = (uv - 0.5) * 2.0;
      	uv *= 1.1;
      	uv.x *= 1.0 + pow((abs(uv.y) / 5.0), 2.0);
      	uv.y *= 1.0 + pow((abs(uv.x) / 4.0), 2.0);
      	uv  = (uv / 2.0) + 0.5;
      	uv =  uv *0.92 + 0.04;
      	return uv;
      }
    	return uv;
    }
    float random(vec2 uv)
    {
     	return fract(sin(dot(uv, vec2(15.5151, 42.2561))) * 12341.14122 * sin(iTime * 0.03));
    }
    float noise(vec2 uv)
    {
     	vec2 i = floor(uv);
        vec2 f = fract(uv);

        float a = random(i);
        float b = random(i + vec2(1.,0.));
    	float c = random(i + vec2(0., 1.));
        float d = random(i + vec2(1.));

        vec2 u = smoothstep(0., 1., f);

        return mix(a,b, u.x) + (c - a) * u.y * (1. - u.x) + (d - b) * u.x * u.y;

    }


    vec2 scandistort(vec2 uv) {
    	float scan1 = clamp(cos(uv.y * 2.0 + iTime), 0.0, 1.0);
    	float scan2 = clamp(cos(uv.y * 2.0 + iTime + 4.0) * 10.0, 0.0, 1.0) ;
    	float amount = scan1 * scan2 * uv.x;

    	return uv;

    }
    void main()
    {
    	vec2 uv = openfl_TextureCoordv;
      vec2 curUV = screenDistort(uv);
    	uv = scandistort(curUV);
    	vec4 video = getVideo(uv);
      float vigAmt = 1.0;
      float x =  0.;


      video.r = getVideo(vec2(x+uv.x+0.001,uv.y+0.001)).x+0.05;
      video.g = getVideo(vec2(x+uv.x+0.000,uv.y-0.002)).y+0.05;
      video.b = getVideo(vec2(x+uv.x-0.002,uv.y+0.000)).z+0.05;
      video.r += 0.08*getVideo(0.75*vec2(x+0.025, -0.027)+vec2(uv.x+0.001,uv.y+0.001)).x;
      video.g += 0.05*getVideo(0.75*vec2(x+-0.022, -0.02)+vec2(uv.x+0.000,uv.y-0.002)).y;
      video.b += 0.08*getVideo(0.75*vec2(x+-0.02, -0.018)+vec2(uv.x-0.002,uv.y+0.000)).z;

      video = clamp(video*0.6+0.4*video*video*1.0,0.0,1.0);
      if(vignetteMoving)
    	  vigAmt = 3.+.3*sin(iTime + 5.*cos(iTime*5.));

    	float vignette = (1.-vigAmt*(uv.y-.5)*(uv.y-.5))*(1.-vigAmt*(uv.x-.5)*(uv.x-.5));

      if(vignetteOn)
    	 video *= float(vignette);


      gl_FragColor = mix(video,vec4(noise(uv * 75.)), 0.05);

      if (curUV.x < 0.0 || curUV.x > 1.0 || curUV.y < 0.0 || curUV.y > 1.0) {
        gl_FragColor = vec4(0.0, 0.0, 0.0, 0.0);
      }
    }')
	public function new()
	{
		super();
	}
}

class ThreeDEffect extends Effect
{
	public var shader:ShaderFilter = new ShaderFilter(new ThreeDShader());

	public function new(xrotation:Float = 0, yrotation:Float = 0, zrotation:Float = 0, depth:Float = 0)
	{
		super();
		daShader = shader;
		shader.shader.data.xrot.value = [xrotation];
		shader.shader.data.yrot.value = [yrotation];
		shader.shader.data.zrot.value = [zrotation];
		shader.shader.data.dept.value = [depth];
	}
}

class ThreeDShader extends FlxShader
{
	@:glFragmentSource('
	#pragma header
	uniform float xrot;
	uniform float yrot;
	uniform float zrot;
	uniform float dept;
	//float alph = 0.0;
float plane( in vec3 norm, in vec3 po, in vec3 ro, in vec3 rd ) {
    float de = dot(norm, rd);
    de = sign(de)*max( abs(de), 0.001);
    return dot(norm, po-ro)/de;
}

vec2 raytraceTexturedQuad(in vec3 rayOrigin, in vec3 rayDirection, in vec3 quadCenter, in vec3 quadRotation, in vec2 quadDimensions) {
    //Rotations
    float a = sin(quadRotation.x); float b = cos(quadRotation.x); 
    float c = sin(quadRotation.y); float d = cos(quadRotation.y); 
    float e = sin(quadRotation.z); float f = cos(quadRotation.z); 
    float ac = a*c;   float bc = b*c;
	
	mat3 RotationMatrix  = 
			mat3(	  d*f,      d*e,  -c,
                 ac*f-b*e, ac*e+b*f, a*d,
                 bc*f+a*e, bc*e-a*f, b*d );
    
    vec3 right = RotationMatrix * vec3(quadDimensions.x, 0.0, 0.0);
    vec3 up = RotationMatrix * vec3(0, quadDimensions.y, 0);
    vec3 normal = cross(right, up);
    normal /= length(normal);
    
    //Find the plane hit point in space
    vec3 pos = (rayDirection * plane(normal, quadCenter, rayOrigin, rayDirection)) - quadCenter;
    
    //Find the texture UV by projecting the hit point along the plane dirs
    return vec2(dot(pos, right) / dot(right, right),
                dot(pos, up)    / dot(up,    up)) + 0.5;
}

void main() {
	vec4 texColor = texture2D(bitmap, openfl_TextureCoordv);
    //Screen UV goes from 0 - 1 along each axis
    vec2 screenUV = openfl_TextureCoordv;
    vec2 p = (2.0 * screenUV) - 1.0;
    float screenAspect = 1280.0/720.0;
    p.x *= screenAspect;
    
    //Normalized Ray Dir
    vec3 dir = vec3(p.x, p.y, 1.0);
    dir /= length(dir);
    
    //Define the plane
    vec3 planePosition = vec3(0.0, 0.0, dept);
    vec3 planeRotation = vec3(xrot, yrot, zrot);//this the shit you needa change
    vec2 planeDimension = vec2(-screenAspect, 1.0);
    
    vec2 uv = raytraceTexturedQuad(vec3(0), dir, planePosition, planeRotation, planeDimension);
	
    //If we hit the rectangle, sample the texture
    if (abs(uv.x - 0.5) < 0.5 && abs(uv.y - 0.5) < 0.5) {
		
		vec3 tex = flixel_texture2D(bitmap, uv).xyz;
		float bitch = 1.0;
		if (tex.z == 0.0){
			bitch = 0.0;
		}
		
	  gl_FragColor = vec4(flixel_texture2D(bitmap, uv).xyz, bitch);
    }
}


	')
	public function new()
	{
		super();
	}
}

// Boing! by ThaeHan

class FuckingTriangleEffect extends Effect
{
	public var shader:ShaderFilter = new ShaderFilter(new FuckingTriangle());

	public function new(rotx:Float, roty:Float)
	{
		super();
		daShader = shader;
		shader.shader.data.rotX.value = [rotx];
		shader.shader.data.rotY.value = [roty];
	}
}

class FuckingTriangle extends FlxShader
{
	@:glFragmentSource('
			#pragma header
			
			const vec3 vertices[18] = vec3[18] (
			vec3(-0.5, 0.0, -0.5),
			vec3( 0.5, 0.0, -0.5),
			vec3(-0.5, 0.0,  0.5),
			
			vec3(-0.5, 0.0,  0.5),
			vec3( 0.5, 0.0, -0.5),
			vec3( 0.5, 0.0,  0.5),
			
			vec3(-0.5, 0.0, -0.5),
			vec3( 0.5, 0.0, -0.5),
			vec3( 0.0, 1.0,  0.0),
			
			vec3(-0.5, 0.0,  0.5),
			vec3( 0.5, 0.0,  0.5),
			vec3( 0.0, 1.0,  0.0),
			
			vec3(-0.5, 0.0, -0.5),
			vec3(-0.5, 0.0,  0.5),
			vec3( 0.0, 1.0,  0.0),
			
			vec3( 0.5, 0.0, -0.5),
			vec3( 0.5, 0.0,  0.5),
			vec3( 0.0, 1.0,  0.0)
		);

		const vec2 texCoords[18] = vec2[18] (
			vec2(0., 1.),
			vec2(1., 1.),
			vec2(0., 0.),
			
			vec2(0., 0.),
			vec2(1., 1.),
			vec2(1., 0.),
			
			vec2(0., 1.),
			vec2(1., 1.),
			vec2(.5, 0.),
			
			vec2(0., 1.),
			vec2(1., 1.),
			vec2(.5, 0.),
			
			vec2(0., 1.),
			vec2(1., 1.),
			vec2(.5, 0.),
			
			vec2(0., 1.),
			vec2(1., 1.),
			vec2(.5, 0.)
		);

		vec4 vertexShader(in vec3 vertex, in mat4 transform) {
			return transform * vec4(vertex, 1.);
		}

		vec4 fragmentShader(in vec2 uv) {
			return flixel_texture2D(bitmap, uv);
		}

		const float fov  = 70.0;
		const float near = 0.1;
		const float far  = 10.;

		const vec3 cameraPos = vec3(0., 0.3, 2.);

			uniform float rotX;
			uniform float rotY;
		        vec4 pixel(in vec2 ndc, in float aspect, inout float depth, in int vertexIndex) {

			mat4 proj  = perspective(fov, aspect, near, far);
			mat4 view  = translate(-cameraPos);
			mat4 model = rotateX(rotX) * rotateY(rotY);
			
			mat4 mvp  = proj * view * model;

			vec4 v0 = vertexShader(vertices[vertexIndex  ], mvp);
			vec4 v1 = vertexShader(vertices[vertexIndex+1], mvp);
			vec4 v2 = vertexShader(vertices[vertexIndex+2], mvp);
			
			vec2 t0 = texCoords[vertexIndex  ] / v0.w; float oow0 = 1. / v0.w;
			vec2 t1 = texCoords[vertexIndex+1] / v1.w; float oow1 = 1. / v1.w;
			vec2 t2 = texCoords[vertexIndex+2] / v2.w; float oow2 = 1. / v2.w;
			
			v0 /= v0.w;
			v1 /= v1.w;
			v2 /= v2.w;
			
			vec3 tri = bary(v0.xy, v1.xy, v2.xy, ndc);
			
			if(tri.x < 0. || tri.x > 1. || tri.y < 0. || tri.y > 1. || tri.z < 0. || tri.z > 1.) {
				return vec4(0.);
			}
			
			float triDepth = baryLerp(v0.z, v1.z, v2.z, tri);
			if(triDepth > depth || triDepth < -1. || triDepth > 1.) {
				return vec4(0.);
			}
			
			depth = triDepth;
			
			float oneOverW = baryLerp(oow0, oow1, oow2, tri);
			vec2 uv        = uvLerp(t0, t1, t2, tri) / oneOverW;
			return fragmentShader(uv);

		}


void main()
{
    vec2 ndc = ((gl_FragCoord.xy * 2.) / openfl_TextureSize.xy) - vec2(1.);
    float aspect = openfl_TextureSize.x / openfl_TextureSize.y;
    vec3 outColor = vec3(.4,.6,.9);
    
    float depth = 1.0;
    for(int i = 0; i < 18; i += 3) {
        vec4 tri = pixel(ndc, aspect, depth, i);
        outColor = mix(outColor.rgb, tri.rgb, tri.a);
    }
    
    gl_FragColor = vec4(outColor, 1.);
}
	
	
	
	')
	public function new()
	{
		super();
	}
}

class BloomEffect extends Effect
{
	public var shader:ShaderFilter = new ShaderFilter(new BloomShader());

	public function new(blurSize:Float, intensity:Float)
	{
		super();
		daShader = shader;
		shader.shader.data.blurSize.value = [blurSize];
		shader.shader.data.intensity.value = [intensity];
	}
}

class BloomShader extends FlxShader
{
	@:glFragmentSource('
	
	#pragma header
	
	uniform float intensity;
	uniform float blurSize;
	void main()
	{
		vec4 sum = vec4(0);
		vec2 texcoord = openfl_TextureCoordv;
		int j;
		int i;

		//thank you! http://www.gamerendering.com/2008/10/11/gaussian-blur-filter-shader/ for the 
		//blur tutorial
		// blur in y (vertical)
		// take nine samples, with the distance blurSize between them
		sum += flixel_texture2D(bitmap, vec2(texcoord.x - 4.0*blurSize, texcoord.y)) * 0.05;
		sum += flixel_texture2D(bitmap, vec2(texcoord.x - 3.0*blurSize, texcoord.y)) * 0.09;
		sum += flixel_texture2D(bitmap, vec2(texcoord.x - 2.0*blurSize, texcoord.y)) * 0.12;
		sum += flixel_texture2D(bitmap, vec2(texcoord.x - blurSize, texcoord.y)) * 0.15;
		sum += flixel_texture2D(bitmap, vec2(texcoord.x, texcoord.y)) * 0.16;
		sum += flixel_texture2D(bitmap, vec2(texcoord.x + blurSize, texcoord.y)) * 0.15;
		sum += flixel_texture2D(bitmap, vec2(texcoord.x + 2.0*blurSize, texcoord.y)) * 0.12;
		sum += flixel_texture2D(bitmap, vec2(texcoord.x + 3.0*blurSize, texcoord.y)) * 0.09;
		sum += flixel_texture2D(bitmap, vec2(texcoord.x + 4.0*blurSize, texcoord.y)) * 0.05;
			
			// blur in y (vertical)
		// take nine samples, with the distance blurSize between them
		sum += flixel_texture2D(bitmap, vec2(texcoord.x, texcoord.y - 4.0*blurSize)) * 0.05;
		sum += flixel_texture2D(bitmap, vec2(texcoord.x, texcoord.y - 3.0*blurSize)) * 0.09;
		sum += flixel_texture2D(bitmap, vec2(texcoord.x, texcoord.y - 2.0*blurSize)) * 0.12;
		sum += flixel_texture2D(bitmap, vec2(texcoord.x, texcoord.y - blurSize)) * 0.15;
		sum += flixel_texture2D(bitmap, vec2(texcoord.x, texcoord.y)) * 0.16;
		sum += flixel_texture2D(bitmap, vec2(texcoord.x, texcoord.y + blurSize)) * 0.15;
		sum += flixel_texture2D(bitmap, vec2(texcoord.x, texcoord.y + 2.0*blurSize)) * 0.12;
		sum += flixel_texture2D(bitmap, vec2(texcoord.x, texcoord.y + 3.0*blurSize)) * 0.09;
		sum += flixel_texture2D(bitmap, vec2(texcoord.x, texcoord.y + 4.0*blurSize)) * 0.05;

		//increase blur with intensity!
		gl_FragColor = sum*intensity + flixel_texture2D(bitmap, texcoord); 
	}
	
	
	')
	public function new()
	{
		super();
	}
}

class GlitchEffect extends Effect
{
	public var shader:ShaderFilter = new ShaderFilter(new GlitchShader());

	public var waveSpeed(default, set):Float = 0;
	public var waveFrequency(default, set):Float = 0;
	public var waveAmplitude(default, set):Float = 0;

	public function new(WaveSpeed:Float, WaveFrequency:Float, WaveAmplitude:Float)
	{
		super();
		daShader = shader;
		shader.shader.data.uTime.value = [0];
		waveSpeed = WaveSpeed;
		waveFrequency = WaveFrequency;
		waveAmplitude = WaveAmplitude;
		PlayState.instance.shaderUpdates.push(update);
	}

	public function update(elapsed:Float):Void
	{
		shader.shader.data.uTime.value[0] += elapsed;
	}

	function set_waveSpeed(v:Float):Float
	{
		waveSpeed = v;
		shader.shader.data.uSpeed.value = [waveSpeed];
		return v;
	}

	function set_waveFrequency(v:Float):Float
	{
		waveFrequency = v;
		shader.shader.data.uFrequency.value = [waveFrequency];
		return v;
	}

	function set_waveAmplitude(v:Float):Float
	{
		waveAmplitude = v;
		shader.shader.data.uWaveAmplitude.value = [waveAmplitude];
		return v;
	}
}

class DistortBGEffect extends Effect
{
	public var shader:ShaderFilter = new ShaderFilter(new DistortBGShader());

	public var waveSpeed(default, set):Float = 0;
	public var waveFrequency(default, set):Float = 0;
	public var waveAmplitude(default, set):Float = 0;

	public function new(WaveSpeed:Float, WaveFrequency:Float, WaveAmplitude:Float)
	{
		super();
		daShader = shader;
		waveSpeed = WaveSpeed;
		waveFrequency = WaveFrequency;
		waveAmplitude = WaveAmplitude;
		shader.shader.data.uTime.value = [0];
		PlayState.instance.shaderUpdates.push(update);
	}

	public function update(elapsed:Float):Void
	{
		shader.shader.data.uTime.value[0] += elapsed;
	}

	function set_waveSpeed(v:Float):Float
	{
		waveSpeed = v;
		shader.shader.data.uSpeed.value = [waveSpeed];
		return v;
	}

	function set_waveFrequency(v:Float):Float
	{
		waveFrequency = v;
		shader.shader.data.uFrequency.value = [waveFrequency];
		return v;
	}

	function set_waveAmplitude(v:Float):Float
	{
		waveAmplitude = v;
		shader.shader.data.uWaveAmplitude.value = [waveAmplitude];
		return v;
	}
}

class PulseEffect extends Effect
{
	public var shader:ShaderFilter = new ShaderFilter(new PulseShader());

	public var waveSpeed(default, set):Float = 0;
	public var waveFrequency(default, set):Float = 0;
	public var waveAmplitude(default, set):Float = 0;

	public function new(WaveSpeed:Float, WaveFrequency:Float, WaveAmplitude:Float)
	{
		super();
		daShader = shader;
		waveSpeed = WaveSpeed;
		waveFrequency = WaveFrequency;
		waveAmplitude = WaveAmplitude;
		shader.shader.data.uTime.value = [0];
		shader.shader.data.uampmul.value = [1];
		PlayState.instance.shaderUpdates.push(update);
	}

	public function update(elapsed:Float):Void
	{
		shader.shader.data.uTime.value[0] += elapsed;
	}

	function set_waveSpeed(v:Float):Float
	{
		waveSpeed = v;
		shader.shader.data.uSpeed.value = [waveSpeed];
		return v;
	}

	function set_waveFrequency(v:Float):Float
	{
		waveFrequency = v;
		shader.shader.data.uFrequency.value = [waveFrequency];
		return v;
	}

	function set_waveAmplitude(v:Float):Float
	{
		waveAmplitude = v;
		shader.shader.data.uWaveAmplitude.value = [waveAmplitude];
		return v;
	}
}

class InvertColorsEffect extends Effect
{
	public var shader:ShaderFilter = new ShaderFilter(new InvertShader());

	public function new()
	{
		super();
		daShader = shader;
	}
}

class GlitchShader extends FlxShader
{
	@:glFragmentSource('
    #pragma header
    //uniform float tx, ty; // x,y waves phase

    //modified version of the wave shader to create weird garbled corruption like messes
    uniform float uTime;
    
    /**
     * How fast the waves move over time
     */
    uniform float uSpeed;
    
    /**
     * Number of waves over time
     */
    uniform float uFrequency;
    
    /**
     * How much the pixels are going to stretch over the waves
     */
    uniform float uWaveAmplitude;

    vec2 sineWave(vec2 pt)
    {
        float x = 0.0;
        float y = 0.0;
        
        float offsetX = sin(pt.y * uFrequency + uTime * uSpeed) * (uWaveAmplitude / pt.x * pt.y);
        float offsetY = sin(pt.x * uFrequency - uTime * uSpeed) * (uWaveAmplitude / pt.y * pt.x);
        pt.x += offsetX; // * (pt.y - 1.0); // <- Uncomment to stop bottom part of the screen from moving
        pt.y += offsetY;

        return vec2(pt.x + x, pt.y + y);
    }

    void main()
    {
        vec2 uv = sineWave(openfl_TextureCoordv);
        gl_FragColor = texture2D(bitmap, uv);
    }')
	public function new()
	{
		super();
	}
}

class InvertShader extends FlxShader
{
	@:glFragmentSource('
    #pragma header
    
    vec4 sineWave(vec4 pt)
    {
	
	return vec4(1.0 - pt.x, 1.0 - pt.y, 1.0 - pt.z, pt.w);
    }

    void main()
    {
        vec2 uv = openfl_TextureCoordv;
        gl_FragColor = sineWave(texture2D(bitmap, uv));
		gl_FragColor.a = 1.0 - gl_FragColor.a;
    }')
	public function new()
	{
		super();
	}
}

class DistortBGShader extends FlxShader
{
	@:glFragmentSource('
    #pragma header

    //gives the character a glitchy, distorted outline
    uniform float uTime;
    
    /**
     * How fast the waves move over time
     */
    uniform float uSpeed;
    
    /**
     * Number of waves over time
     */
    uniform float uFrequency;
    
    /**
     * How much the pixels are going to stretch over the waves
     */
    uniform float uWaveAmplitude;

    vec2 sineWave(vec2 pt)
    {
        float x = 0.0;
        float y = 0.0;
        
        float offsetX = sin(pt.x * uFrequency + uTime * uSpeed) * (uWaveAmplitude / pt.x * pt.y);
        float offsetY = sin(pt.y * uFrequency - uTime * uSpeed) * (uWaveAmplitude);
        pt.x += offsetX; // * (pt.y - 1.0); // <- Uncomment to stop bottom part of the screen from moving
        pt.y += offsetY;

        return vec2(pt.x + x, pt.y + y);
    }

    vec4 makeBlack(vec4 pt)
    {
        return vec4(0, 0, 0, pt.w);
    }

    void main()
    {
        vec2 uv = sineWave(openfl_TextureCoordv);
        gl_FragColor = makeBlack(texture2D(bitmap, uv)) + texture2D(bitmap,openfl_TextureCoordv);
    }')
	public function new()
	{
		super();
	}
}

class PulseShader extends FlxShader
{
	@:glFragmentSource('
    #pragma header
    uniform float uampmul;

    //modified version of the wave shader to create weird garbled corruption like messes
    uniform float uTime;
    
    /**
     * How fast the waves move over time
     */
    uniform float uSpeed;
    
    /**
     * Number of waves over time
     */
    uniform float uFrequency;

    uniform bool uEnabled;
    
    /**
     * How much the pixels are going to stretch over the waves
     */
    uniform float uWaveAmplitude;

    vec4 sineWave(vec4 pt, vec2 pos)
    {
        if (uampmul > 0.0)
        {
            float offsetX = sin(pt.y * uFrequency + uTime * uSpeed);
            float offsetY = sin(pt.x * (uFrequency * 2.0) - (uTime / 2.0) * uSpeed);
            float offsetZ = sin(pt.z * (uFrequency / 2.0) + (uTime / 3.0) * uSpeed);
            pt.x = mix(pt.x,sin(pt.x / 2.0 * pt.y + (5.0 * offsetX) * pt.z),uWaveAmplitude * uampmul);
            pt.y = mix(pt.y,sin(pt.y / 3.0 * pt.z + (2.0 * offsetZ) - pt.x),uWaveAmplitude * uampmul);
            pt.z = mix(pt.z,sin(pt.z / 6.0 * (pt.x * offsetY) - (50.0 * offsetZ) * (pt.z * offsetX)),uWaveAmplitude * uampmul);
        }

        return vec4(pt.x, pt.y, pt.z, pt.w);
    }

    void main()
    {
        vec2 uv = openfl_TextureCoordv;
        gl_FragColor = sineWave(texture2D(bitmap, uv),uv);
    }')
	public function new()
	{
		super();
	}
}

class Effect
{
	public var daShader:ShaderFilter;

	// stolen from FlxRuntimeShader-

	/**
	 * Modify a float parameter of the shader.
	 *
	 * @param name The name of the parameter to modify.
	 * @param value The new value to use.
	 */
	public function setFloat(name:String, value:Float):Void
	{
		var prop:ShaderParameter<Float> = Reflect.field(daShader.shader.data, name);

		if (prop == null)
		{
			FlxG.log.warn('Shader float property "$name" not found.');
			return;
		}

		prop.value = [value];
	}

	/**
	 * Retrieve a float parameter of the shader.
	 *
	 * @param name The name of the parameter to retrieve.
	 */
	public function getFloat(name:String):Null<Float>
	{
		var prop:ShaderParameter<Float> = Reflect.field(daShader.shader.data, name);

		if (prop == null)
		{
			FlxG.log.warn('Shader float property "$name" not found.');
			return null;
		}

		return prop.value[0];
	}

	/**
	 * Modify a float array parameter of the shader.
	 *
	 * @param name The name of the parameter to modify.
	 * @param value The new value to use.
	 */
	public function setFloatArray(name:String, value:Array<Float>):Void
	{
		var prop:ShaderParameter<Float> = Reflect.field(daShader.shader.data, name);

		if (prop == null)
		{
			FlxG.log.warn('Shader float[] property "$name" not found.');
			return;
		}

		prop.value = value;
	}

	/**
	 * Retrieve a float array parameter of the shader.
	 *
	 * @param name The name of the parameter to retrieve.
	 */
	public function getFloatArray(name:String):Null<Array<Float>>
	{
		var prop:ShaderParameter<Float> = Reflect.field(daShader.shader.data, name);

		if (prop == null)
		{
			FlxG.log.warn('Shader float[] property "$name" not found.');
			return null;
		}

		return prop.value;
	}

	/**
	 * Modify an integer parameter of the shader.
	 *
	 * @param name The name of the parameter to modify.
	 * @param value The new value to use.
	 */
	public function setInt(name:String, value:Int):Void
	{
		var prop:ShaderParameter<Int> = Reflect.field(daShader.shader.data, name);

		if (prop == null)
		{
			FlxG.log.warn('Shader int property "$name" not found.');
			return;
		}

		prop.value = [value];
	}

	/**
	 * Retrieve an integer parameter of the shader.
	 *
	 * @param name The name of the parameter to retrieve.
	 */
	public function getInt(name:String):Null<Int>
	{
		var prop:ShaderParameter<Int> = Reflect.field(daShader.shader.data, name);

		if (prop == null)
		{
			FlxG.log.warn('Shader int property "$name" not found.');
			return null;
		}

		return prop.value[0];
	}

	/**
	 * Modify an integer array parameter of the shader.
	 *
	 * @param name The name of the parameter to modify.
	 * @param value The new value to use.
	 */
	public function setIntArray(name:String, value:Array<Int>):Void
	{
		var prop:ShaderParameter<Int> = Reflect.field(daShader.shader.data, name);

		if (prop == null)
		{
			FlxG.log.warn('Shader int[] property "$name" not found.');
			return;
		}

		prop.value = value;
	}

	/**
	 * Retrieve an integer array parameter of the shader.
	 *
	 * @param name The name of the parameter to retrieve.
	 */
	public function getIntArray(name:String):Null<Array<Int>>
	{
		var prop:ShaderParameter<Int> = Reflect.field(daShader.shader.data, name);

		if (prop == null)
		{
			FlxG.log.warn('Shader int[] property "$name" not found.');
			return null;
		}

		return prop.value;
	}

	/**
	 * Modify a bool parameter of the shader.
	 *
	 * @param name The name of the parameter to modify.
	 * @param value The new value to use.
	 */
	public function setBool(name:String, value:Bool):Void
	{
		var prop:ShaderParameter<Bool> = Reflect.field(daShader.shader.data, name);

		if (prop == null)
		{
			FlxG.log.warn('Shader bool property "$name" not found.');
			return;
		}

		prop.value = [value];
	}

	/**
	 * Retrieve a bool parameter of the shader.
	 *
	 * @param name The name of the parameter to retrieve.
	 */
	public function getBool(name:String):Null<Bool>
	{
		var prop:ShaderParameter<Bool> = Reflect.field(daShader.shader.data, name);

		if (prop == null)
		{
			FlxG.log.warn('Shader bool property "$name" not found.');
			return null;
		}

		return prop.value[0];
	}

	/**
	 * Modify a bool array parameter of the shader.
	 *
	 * @param name The name of the parameter to modify.
	 * @param value The new value to use.
	 */
	public function setBoolArray(name:String, value:Array<Bool>):Void
	{
		var prop:ShaderParameter<Bool> = Reflect.field(daShader.shader.data, name);

		if (prop == null)
		{
			FlxG.log.warn('Shader bool[] property "$name" not found.');
			return;
		}

		prop.value = value;
	}

	/**
	 * Retrieve a bool array parameter of the shader.
	 *
	 * @param name The name of the parameter to retrieve.
	 */
	public function getBoolArray(name:String):Null<Array<Bool>>
	{
		var prop:ShaderParameter<Bool> = Reflect.field(daShader.shader.data, name);

		if (prop == null)
		{
			FlxG.log.warn('Shader bool[] property "$name" not found.');
			return null;
		}

		return prop.value;
	}

	/**
	 * Modify a bitmap data parameter of the shader.
	 *
	 * @param name The name of the parameter to modify.
	 * @param value The new value to use.
	 */
	public function setSampler2D(name:String, value:BitmapData):Void
	{
		var prop:ShaderInput<BitmapData> = Reflect.field(daShader.shader.data, name);

		if (prop == null)
		{
			FlxG.log.warn('Shader sampler2D property "$name" not found.');
			return;
		}

		prop.input = value;
	}

	/**
	 * Retrieve a bitmap data parameter of the shader.
	 *
	 * @param name The name of the parameter to retrieve.
	 * @return The value of the parameter.
	 */
	public function getSampler2D(name:String):Null<BitmapData>
	{
		var prop:ShaderInput<BitmapData> = Reflect.field(daShader.shader.data, name);

		if (prop == null)
		{
			FlxG.log.warn('Shader sampler2D property "$name" not found.');
			return null;
		}

		return prop.input;
	}

	public function new()
	{
	}
}
#end
