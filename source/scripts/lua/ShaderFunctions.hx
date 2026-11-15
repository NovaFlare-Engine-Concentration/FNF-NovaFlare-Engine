package scripts.lua;

#if (!flash && sys)
import openfl.filters.ShaderFilter;

import flixel.addons.display.FlxRuntimeShader;
#end

#if CUSTOM_SHADERS_ALLOWED
import general.shaders.CustomShaders;
#end

class ShaderFunctions
{
	#if (!flash && MODS_ALLOWED && sys)
	private static var storedFilters:Map<String, ShaderFilter> = [];
	#end

	public static function implement(funk:FunkinLua)
	{
		// shader shit
		funk.addLocalCallback("initLuaShader", function(name:String)
		{
			if (!ClientPrefs.data.shaders)
				return false;

			#if (!flash && MODS_ALLOWED && sys)
			return funk.initLuaShader(name);
			#else
			FunkinLua.luaTrace("initLuaShader: Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
			#end
			return false;
		});

		funk.addLocalCallback("addShaderToCam", function(cam:String, shader:String, ?index:String)
		{
			if (!ClientPrefs.data.shaders)
				return false;

			if (index == null || index.length < 1)
				index = shader;

			#if (!flash && MODS_ALLOWED && sys)
			if (!funk.runtimeShaders.exists(shader) && !funk.initLuaShader(shader))
			{
				FunkinLua.luaTrace('addShaderToCam: Shader $shader is missing!', false, false, FlxColor.RED);
				return false;
			}

			var arr:Array<String> = funk.runtimeShaders.get(shader);
			var camera = getCam(cam);
			if (camera == null) return false;
			var current = getCameraFilters(camera);
			var filters:Array<openfl.filters.BitmapFilter> = current == null ? [] : current.copy();
			var filter = new ShaderFilter(new FlxRuntimeShader(arr[0], arr[1]));
			storedFilters.set(index, filter);
			filters.push(filter);
			setCameraFilters(camera, filters);
			return true;
			#else
			FunkinLua.luaTrace("addShaderToCam: Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
			#end
			return false;
		});

		funk.addLocalCallback("removeCamShader", function(cam:String, shader:String)
		{
			#if (!flash && MODS_ALLOWED && sys)
			var camera = getCam(cam);
			if (!storedFilters.exists(shader))
			{
				FunkinLua.luaTrace('removeCamShader: $shader does not exist!', false, false, FlxColor.YELLOW);
				return false;
			}

			var current = getCameraFilters(camera);
			if (current == null)
			{
				FunkinLua.luaTrace('removeCamShader: camera $cam does not have any shaders!', false, false, FlxColor.YELLOW);
				return false;
			}

			var filters:Array<openfl.filters.BitmapFilter> = current.copy();
			filters.remove(storedFilters.get(shader));
			setCameraFilters(camera, filters);
			storedFilters.remove(shader);
			return true;
			#else
			FunkinLua.luaTrace('removeCamShader: Platform unsupported for Runtime Shaders!', false, false, FlxColor.RED);
			#end
			return false;
		});

		funk.addLocalCallback("clearCamShaders", function(cam:String) getCam(cam).setFilters([]));

		funk.addLocalCallback("setSpriteShader", function(obj:String, shader:String)
		{
			if (!ClientPrefs.data.shaders)
				return false;

			#if (!flash && MODS_ALLOWED && sys)
			if (!funk.runtimeShaders.exists(shader) && !funk.initLuaShader(shader))
			{
				FunkinLua.luaTrace('setSpriteShader: Shader $shader is missing!', false, false, FlxColor.RED);
				return false;
			}

			var split:Array<String> = obj.split('.');
			var leObj:FlxSprite = LuaUtils.getObjectDirectly(split[0]);
			if (split.length > 1)
			{
				leObj = LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(split), split[split.length - 1]);
			}

			if (leObj != null)
			{
				var arr:Array<String> = funk.runtimeShaders.get(shader);
				leObj.shader = new FlxRuntimeShader(arr[0], arr[1]);
				return true;
			}
			#else
			FunkinLua.luaTrace("setSpriteShader: Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
			#end
			return false;
		});

		funk.set("removeSpriteShader", function(obj:String)
		{
			var split:Array<String> = obj.split('.');
			var leObj:FlxSprite = LuaUtils.getObjectDirectly(split[0]);
			if (split.length > 1)
			{
				leObj = LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(split), split[split.length - 1]);
			}

			if (leObj != null)
			{
				leObj.shader = null;
				return true;
			}
			return false;
		});

		funk.set("getShaderBool", function(obj:String, prop:String)
		{
			#if (!flash && MODS_ALLOWED && sys)
			var shader:FlxRuntimeShader = getShader(obj);
			if (shader == null)
			{
				FunkinLua.luaTrace("getShaderBool: Shader is not FlxRuntimeShader!", false, false, FlxColor.RED);
				return null;
			}
			return shader.getBool(prop);
			#else
			FunkinLua.luaTrace("getShaderBool: Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
			return null;
			#end
		});

		funk.set("getShaderBoolArray", function(obj:String, prop:String)
		{
			#if (!flash && MODS_ALLOWED && sys)
			var shader:FlxRuntimeShader = getShader(obj);
			if (shader == null)
			{
				FunkinLua.luaTrace("getShaderBoolArray: Shader is not FlxRuntimeShader!", false, false, FlxColor.RED);
				return null;
			}
			return shader.getBoolArray(prop);
			#else
			FunkinLua.luaTrace("getShaderBoolArray: Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
			return null;
			#end
		});
		funk.set("getShaderInt", function(obj:String, prop:String)
		{
			#if (!flash && MODS_ALLOWED && sys)
			var shader:FlxRuntimeShader = getShader(obj);
			if (shader == null)
			{
				FunkinLua.luaTrace("getShaderInt: Shader is not FlxRuntimeShader!", false, false, FlxColor.RED);
				return null;
			}
			return shader.getInt(prop);
			#else
			FunkinLua.luaTrace("getShaderInt: Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
			return null;
			#end
		});
		funk.set("getShaderIntArray", function(obj:String, prop:String)
		{
			#if (!flash && MODS_ALLOWED && sys)
			var shader:FlxRuntimeShader = getShader(obj);
			if (shader == null)
			{
				FunkinLua.luaTrace("getShaderIntArray: Shader is not FlxRuntimeShader!", false, false, FlxColor.RED);
				return null;
			}
			return shader.getIntArray(prop);
			#else
			FunkinLua.luaTrace("getShaderIntArray: Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
			return null;
			#end
		});
		funk.set("getShaderFloat", function(obj:String, prop:String)
		{
			#if (!flash && MODS_ALLOWED && sys)
			var shader:FlxRuntimeShader = getShader(obj);
			if (shader == null)
			{
				FunkinLua.luaTrace("getShaderFloat: Shader is not FlxRuntimeShader!", false, false, FlxColor.RED);
				return null;
			}
			return shader.getFloat(prop);
			#else
			FunkinLua.luaTrace("getShaderFloat: Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
			return null;
			#end
		});
		funk.set("getShaderFloatArray", function(obj:String, prop:String)
		{
			#if (!flash && MODS_ALLOWED && sys)
			var shader:FlxRuntimeShader = getShader(obj);
			if (shader == null)
			{
				FunkinLua.luaTrace("getShaderFloatArray: Shader is not FlxRuntimeShader!", false, false, FlxColor.RED);
				return null;
			}
			return shader.getFloatArray(prop);
			#else
			FunkinLua.luaTrace("getShaderFloatArray: Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
			return null;
			#end
		});

		funk.set("setShaderBool", function(obj:String, prop:String, value:Bool)
		{
			#if (!flash && MODS_ALLOWED && sys)
			var shader:FlxRuntimeShader = getShader(obj);
			if (shader == null)
			{
				FunkinLua.luaTrace("setShaderBool: Shader is not FlxRuntimeShader!", false, false, FlxColor.RED);
				return false;
			}
			shader.setBool(prop, value);
			return true;
			#else
			FunkinLua.luaTrace("setShaderBool: Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
			return false;
			#end
		});
		funk.set("setShaderBoolArray", function(obj:String, prop:String, values:Dynamic)
		{
			#if (!flash && MODS_ALLOWED && sys)
			var shader:FlxRuntimeShader = getShader(obj);
			if (shader == null)
			{
				FunkinLua.luaTrace("setShaderBoolArray: Shader is not FlxRuntimeShader!", false, false, FlxColor.RED);
				return false;
			}
			shader.setBoolArray(prop, values);
			return true;
			#else
			FunkinLua.luaTrace("setShaderBoolArray: Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
			return false;
			#end
		});
		funk.set("setShaderInt", function(obj:String, prop:String, value:Int)
		{
			#if (!flash && MODS_ALLOWED && sys)
			var shader:FlxRuntimeShader = getShader(obj);
			if (shader == null)
			{
				FunkinLua.luaTrace("setShaderInt: Shader is not FlxRuntimeShader!", false, false, FlxColor.RED);
				return false;
			}
			shader.setInt(prop, value);
			return true;
			#else
			FunkinLua.luaTrace("setShaderInt: Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
			return false;
			#end
		});
		funk.set("setShaderIntArray", function(obj:String, prop:String, values:Dynamic)
		{
			#if (!flash && MODS_ALLOWED && sys)
			var shader:FlxRuntimeShader = getShader(obj);
			if (shader == null)
			{
				FunkinLua.luaTrace("setShaderIntArray: Shader is not FlxRuntimeShader!", false, false, FlxColor.RED);
				return false;
			}
			shader.setIntArray(prop, values);
			return true;
			#else
			FunkinLua.luaTrace("setShaderIntArray: Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
			return false;
			#end
		});
		funk.set("setShaderFloat", function(obj:String, prop:String, value:Float)
		{
			#if (!flash && MODS_ALLOWED && sys)
			var shader:FlxRuntimeShader = getShader(obj);
			if (shader == null)
			{
				FunkinLua.luaTrace("setShaderFloat: Shader is not FlxRuntimeShader!", false, false, FlxColor.RED);
				return false;
			}
			shader.setFloat(prop, value);
			return true;
			#else
			FunkinLua.luaTrace("setShaderFloat: Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
			return false;
			#end
		});
		funk.set("setShaderFloatArray", function(obj:String, prop:String, values:Dynamic)
		{
			#if (!flash && MODS_ALLOWED && sys)
			var shader:FlxRuntimeShader = getShader(obj);
			if (shader == null)
			{
				FunkinLua.luaTrace("setShaderFloatArray: Shader is not FlxRuntimeShader!", false, false, FlxColor.RED);
				return false;
			}

			shader.setFloatArray(prop, values);
			return true;
			#else
			FunkinLua.luaTrace("setShaderFloatArray: Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
			return true;
			#end
		});

		funk.set("setShaderSampler2D", function(obj:String, prop:String, bitmapdataPath:String)
		{
			#if (!flash && MODS_ALLOWED && sys)
			var shader:FlxRuntimeShader = getShader(obj);
			if (shader == null)
			{
				FunkinLua.luaTrace("setShaderSampler2D: Shader is not FlxRuntimeShader!", false, false, FlxColor.RED);
				return false;
			}

			// trace('bitmapdatapath: $bitmapdataPath');
			var value = Paths.image(bitmapdataPath);
			if (value != null && value.bitmap != null)
			{
				// trace('Found bitmapdata. Width: ${value.bitmap.width} Height: ${value.bitmap.height}');
				shader.setSampler2D(prop, value.bitmap);
				return true;
			}
			return false;
			#else
			FunkinLua.luaTrace("setShaderSampler2D: Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
			return false;
			#end
		});

		// SHADER SHIT
		#if CUSTOM_SHADERS_ALLOWED
		funk.set("addChromaticEffect",
			function(tag:String, object:String, globalChromeOffset:Float = 0.005, ?redOffset:Float = 0.0, ?greenOffset:Float = 0.0, ?blueOffset:Float = 0.0)
			{
				var shader = new ChromaticAberrationEffect(globalChromeOffset, redOffset, greenOffset, blueOffset);
				resetShader(shader, tag);
				PlayState.instance.addShaderToObject(object, shader.shader);
			});

		funk.set("addScanlineEffect", function(tag:String, object:String, lockAlpha:Bool = false)
		{
			var shader = new ScanlineEffect(lockAlpha);
			resetShader(shader, tag);
			PlayState.instance.addShaderToObject(object, shader.shader);
		});
		funk.set("addGrainEffect", function(tag:String, object:String, grainSize:Float, lumAmount:Float, lockAlpha:Bool = false)
		{
			var shader = new GrainEffect(grainSize, lumAmount, lockAlpha);
			resetShader(shader, tag);
			PlayState.instance.addShaderToObject(object, shader.shader);
		});
		funk.set("addTiltshiftEffect", function(tag:String, object:String, blurAmount:Float, center:Float)
		{
			var shader = new TiltshiftEffect(blurAmount, center);
			resetShader(shader, tag);
			PlayState.instance.addShaderToObject(object, shader.shader);
		});
		funk.set("addVCREffect",
			function(tag:String, object:String, glitchFactor:Float = 0.0, distortion:Bool = true, perspectiveOn:Bool = true, vignetteMoving:Bool = true)
			{
				var shader = new VCRDistortionEffect(glitchFactor, distortion, perspectiveOn, vignetteMoving);
				resetShader(shader, tag);
				PlayState.instance.addShaderToObject(object, shader.shader);
			});

		funk.set("addGlitchEffect", function(tag:String, object:String, waveSpeed:Float = 0.1, waveFrq:Float = 0.1, waveAmp:Float = 0.1)
		{
			var shader = new GlitchEffect(waveSpeed, waveFrq, waveAmp);
			resetShader(shader, tag);
			PlayState.instance.addShaderToObject(object, shader.shader);
		});

		funk.set("addPulseEffect", function(tag:String, object:String, waveSpeed:Float = 0.1, waveFrq:Float = 0.1, waveAmp:Float = 0.1)
		{
			var shader = new PulseEffect(waveSpeed, waveFrq, waveAmp);
			resetShader(shader, tag);
			PlayState.instance.addShaderToObject(object, shader.shader);
		});

		funk.set("addDistortionEffect", function(tag:String, object:String, waveSpeed:Float = 0.1, waveFrq:Float = 0.1, waveAmp:Float = 0.1)
		{
			var shader = new DistortBGEffect(waveSpeed, waveFrq, waveAmp);
			resetShader(shader, tag);
			PlayState.instance.addShaderToObject(object, shader.shader);
		});

		funk.set("addInvertEffect", function(tag:String, object:String, lockAlpha:Bool = false)
		{
			var shader = new InvertColorsEffect();
			resetShader(shader, tag);
			PlayState.instance.addShaderToObject(object, shader.shader);
		});

		funk.set("addGrayscaleEffect", function(tag:String, object:String)
		{
			var shader = new GreyscaleEffect();
			resetShader(shader, tag);
			PlayState.instance.addShaderToObject(object, shader.shader);
		});

		funk.set("add3DEffect", function(tag:String, object:String, xrotation:Float = 0, yrotation:Float = 0, zrotation:Float = 0, depth:Float = 0)
		{
			var shader = new ThreeDEffect(xrotation, yrotation, zrotation, depth);
			resetShader(shader, tag);
			PlayState.instance.addShaderToObject(object, shader.shader);
		});

		funk.set("addBloomEffect", function(tag:String, object:String, intensity:Float = 0.35, blurSize:Float = 1.0)
		{
			var shader = new BloomEffect(blurSize / 512.0, intensity);
			resetShader(shader, tag);
			PlayState.instance.addShaderToObject(object, shader.shader);
		});

		funk.set("addBrightEffect", function(tag:String, object:String, brightness:Float, ?contrast:Float = 1.0)
		{
			var shader = new BrightEffect(brightness, contrast);
			resetShader(shader, tag);
			PlayState.instance.addShaderToObject(object, shader.shader);
		});

		funk.set("addBulgeEffect", function(tag:String, object:String, value:Float = 0.0)
		{
			var shader = new BulgeEffect(value);
			resetShader(shader, tag);
			PlayState.instance.addShaderToObject(object, shader.shader);
		});

		funk.set("addRadialBlurEffect", function(tag:String, object:String, strength:Float = 0, x:Float = 0, y:Float = 0, zoom:Float = 1.0)
		{
			var shader = new RadialBlurEffect(strength, x, y, zoom);
			resetShader(shader, tag);
			PlayState.instance.addShaderToObject(object, shader.shader);
		});

		funk.set("removeEffect", function(camera:String, effect:String)
		{
			if (PlayState.instance.modchartShader.exists(effect))
				PlayState.instance.removeShaderFromCamera(camera, PlayState.instance.modchartShader.get(effect));
		});

		funk.set("clearEffects", function(object:String)
		{
			PlayState.instance.clearObjectShaders(object);
		});

		funk.set("tweenEffectFloat", function(effect:String, floatToTween:String, duration:Float, from:Float, to:Float)
		{
			var shader:Effect = PlayState.instance.modchartShader.get(effect);
			if (shader == null)
			{
				FunkinLua.luaTrace("tweenEffectInt: the effect " + effect + " is not added to the game", false, false, FlxColor.RED);
				return;
			}
			FlxTween.num(from, to, duration, function(newValue)
			{
				shader.setFloat(floatToTween, newValue);
			});
		});

		funk.set("tweenEffectInt", function(effect:String, intToTween:String, duration:Float, from:Int, to:Int)
		{
			var shader:Effect = PlayState.instance.modchartShader.get(effect);
			if (shader == null)
			{
				FunkinLua.luaTrace("tweenEffectInt: the effect " + effect + " is not added to the game", false, false, FlxColor.RED);
				return;
			}
			FlxTween.num(from, to, duration, function(newValue)
			{
				shader.setInt(intToTween, Std.int(newValue));
			});
		});
		#end
	}

	#if (!flash && sys)
	public static function getShader(obj:String):FlxRuntimeShader
	{
		if (storedFilters.exists(obj))
			return cast(storedFilters[obj].shader, FlxRuntimeShader);

		var split:Array<String> = obj.split('.');
		var target:FlxSprite = null;
		if (split.length > 1)
			target = LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(split), split[split.length - 1]);
		else
			target = LuaUtils.getObjectDirectly(split[0]);

		if (target == null)
		{
			FunkinLua.luaTrace('Error on getting shader: Object $obj not found', false, false, FlxColor.RED);
			return null;
		}
		return cast(target.shader, FlxRuntimeShader);
	}

	// FlxCamera._filters is a property; reading it dynamically does not invoke its getter.
	private static function getCameraFilters(camera:Dynamic):Null<Array<openfl.filters.BitmapFilter>>
	{
		if (camera == null) return null;
		if (camera == FlxG.game)
		{
			@:privateAccess return FlxG.game._filters;
		}
		if (Std.isOfType(camera, flixel.FlxCamera))
		{
			var flxCamera:flixel.FlxCamera = cast camera;
			return flxCamera.filters;
		}
		return null;
	}

	private static function setCameraFilters(camera:Dynamic, filters:Array<openfl.filters.BitmapFilter>):Void
	{
		if (camera == FlxG.game) FlxG.game.setFilters(filters);
		else if (Std.isOfType(camera, flixel.FlxCamera))
		{
			var flxCamera:flixel.FlxCamera = cast camera;
			flxCamera.filters = filters;
		}
	}

	public static function getCam(obj:String):Dynamic
	{
		if (obj.toLowerCase().trim() == "global")
			return FlxG.game;
		return LuaUtils.cameraFromString(obj);
	}
	#end

	#if CUSTOM_SHADERS_ALLOWED
	public static function resetShader(shader:Effect, tag:String)
	{
		if (PlayState.instance.modchartShader.exists(tag))
		{
			PlayState.instance.removeShaderFromCamera('', PlayState.instance.modchartShader.get(tag));
			PlayState.instance.removeShaderFromCamera('game', PlayState.instance.modchartShader.get(tag));
			PlayState.instance.removeShaderFromCamera('hud', PlayState.instance.modchartShader.get(tag));
			PlayState.instance.removeShaderFromCamera('other', PlayState.instance.modchartShader.get(tag));
			PlayState.instance.modchartShader.remove(tag);
		}
		PlayState.instance.modchartShader.set(tag, shader);
	}
	#end
}
