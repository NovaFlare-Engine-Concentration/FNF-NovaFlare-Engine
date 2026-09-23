package games.objects;

import flixel.system.FlxAssets.FlxShader;

import general.backend.animation.PsychAnimationController;
import general.backend.Cache;

import general.shaders.RGBPalette;
import general.shaders.ColorSwap;

import games.backend.ExtraKeysHandler;

typedef RGB = {
	r:Null<Int>,
	g:Null<Int>,
	b:Null<Int>
}

typedef NoteSplashAnim = {
	name:String,
	noteData:Int,
	prefix:String,
	indices:Array<Int>,
	offsets:Array<Float>,
	fps:Array<Int>
}

typedef NoteSplashConfig = {
	animations:Map<String, NoteSplashAnim>,
	scale:Float,
	allowRGB:Bool,
	allowPixel:Bool,
	rgb:Array<Null<RGB>>
}

class NoteSplash extends FlxSprite
{
	public var rgbShader:PixelSplashShaderRef;
	public var colorSwap:ColorSwap = null;
	public var texture:String;
	public var config(default, set):NoteSplashConfig;
	public var babyArrow:StrumNote;
	public var noteData:Int = 0;

	public var copyX:Bool = true;
	public var copyY:Bool = true;
	public var inEditor:Bool = false;

	var spawned:Bool = false;
	var noteDataMap:Map<Int, String> = new Map();
	var animStride:Int = 4; // how many "lanes" a full anim set spans (4 = default, 10 = NovaFlare Extra Keys)
	var maniaScale:Float = 1; // NovaFlare Extra Keys: per-mania splash scale factor

	public static var defaultNoteSplash(default, never):String = 'noteSplashes/noteSplashes';
	public static var configs:Map<String, NoteSplashConfig> = new Map<String, NoteSplashConfig>();

	static var oldPath:Bool = false;

	/** NovaFlare: legacy 0.7-style mods keep a plain noteSplashes.png at the images root */
	public static function init()
	{
		oldPath = Paths.fileExists('images/noteSplashes.png', IMAGE);
	}

	/** NovaFlare Extra Keys: lane -> color name used inside the splash XML (falls back to the default 4 lanes) */
	public static function laneNoteNames():Array<String>
	{
		var ek:ExtraKeysHandler = ExtraKeysHandler.instance;
		if (ek != null && ek.data != null && ek.data.animations != null && ek.data.animations.length > 0)
			return [for (i in 0...ek.data.animations.length) ek.data.animations[i].note];
		return Note.colArray.copy();
	}

	public static function laneCount():Int
	{
		return laneNoteNames().length;
	}

	public function new(?x:Float = 0, ?y:Float = 0, ?splash:String)
	{
		super(x, y);

		animation = new PsychAnimationController(this);

		rgbShader = new PixelSplashShaderRef();

		// NovaFlare: note color swap support
		if (ClientPrefs.data.noteColorSwap)
		{
			colorSwap = new ColorSwap();
			shader = colorSwap.shader;
		}
		else
			shader = rgbShader.shader;

		loadSplash(splash);
	}

	public var maxAnims(default, set):Int = 0;
	public function loadSplash(?splash:String)
	{
		config = null;
		maxAnims = 0;

		if(splash == null)
		{
			splash = defaultNoteSplash + getSplashSkinPostfix();
			if (PlayState.SONG != null && PlayState.SONG.splashSkin != null && PlayState.SONG.splashSkin.length > 0) splash = PlayState.SONG.splashSkin;
			else if (oldPath && ClientPrefs.data.splashSkin == ClientPrefs.defaultData.splashSkin) splash = 'noteSplashes'; // NovaFlare legacy mods
		}

		// NovaFlare: Extra Keys per-mania scale factor
		maniaScale = 1;
		var ek:ExtraKeysHandler = ExtraKeysHandler.instance;
		if (ek != null && ek.data != null && ek.data.scales != null && PlayState.SONG != null && PlayState.SONG.mania >= 0 && PlayState.SONG.mania < ek.data.scales.length)
			maniaScale = ek.data.scales[PlayState.SONG.mania] + 0.3;

		texture = splash;
		if (!loadFramesCached(texture))
		{
			texture = defaultNoteSplash + getSplashSkinPostfix();
			if (!loadFramesCached(texture))
			{
				texture = defaultNoteSplash;
				loadFramesCached(texture);
			}
		}

		var path:String = 'images/$texture';
		if (configs.exists(path))
		{
			this.config = configs.get(path);
			return;
		}
		else if (Paths.fileExists('$path.json', TEXT))
		{
			var config:Dynamic = haxe.Json.parse(Paths.getTextFromFile('$path.json'));
			if (config != null)
			{
				var tempConfig:NoteSplashConfig = {
					animations: new Map(),
					scale: config.scale,
					allowRGB: config.allowRGB,
					allowPixel: config.allowPixel,
					rgb: config.rgb
				}

				for (i in Reflect.fields(config.animations))
				{
					var anim:NoteSplashAnim = Reflect.field(config.animations, i);
					tempConfig.animations.set(i, anim);
				}

				this.config = tempConfig;
				configs.set(path, this.config);
				return;
			}
		}

		// Splashes with no json: build from the XML (and a legacy 0.7-style .txt when present)
		var tempConfig:NoteSplashConfig = createConfig();
		var anim:String = 'note splash';
		var fps:Array<Null<Int>> = [22, 26];
		var offsets:Array<Array<Float>> = [[0, 0]];
		if (Paths.fileExists('$path.txt', TEXT)) // Backwards compatibility with 0.7 splash txts
		{
			var configFile:Array<String> = CoolUtil.coolTextFile(Paths.getPath('$path.txt', TEXT, true));
			if (configFile.length > 0)
			{
				anim = configFile[0];
				if (configFile.length > 1)
				{
					var framerates:Array<String> = configFile[1].split(' ');
					fps = [Std.parseInt(framerates[0]), Std.parseInt(framerates[1])];
					if (fps[0] == null) fps[0] = 22;
					if (fps[1] == null) fps[1] = 26;

					if (configFile.length > 2)
					{
						offsets = [];
						for (i in 2...configFile.length)
						{
							if (configFile[i].trim() != '')
							{
								var animOffs:Array<String> = configFile[i].split(' ');
								var x:Float = Std.parseFloat(animOffs[0]);
								var y:Float = Std.parseFloat(animOffs[1]);
								if (Math.isNaN(x)) x = 0;
								if (Math.isNaN(y)) y = 0;
								offsets.push([x, y]);
							}
						}
					}
				}
			}
		}

		if (offsets.length < 1)
			offsets = [[0, 0]];

		// NovaFlare: discovery walks every Extra Keys lane (default XMLs recycle the 4 base colors)
		var lanes:Array<String> = laneNoteNames();
		var laneAmt:Int = lanes.length;

		var foundSets:Int = 0;
		while (true)
		{
			var failedToFind:Bool = false;
			for (lane in 0...laneAmt)
			{
				if (!checkForAnim('$anim ${lanes[lane]} ${foundSets + 1}'))
				{
					failedToFind = true;
					break;
				}
			}
			if (failedToFind) break;
			foundSets++;
		}

		for (set in 0...foundSets)
		{
			for (lane in 0...laneAmt)
			{
				var data:Int = lane + (set * laneAmt);
				var offset:Array<Float> = offsets[FlxMath.wrap(lane + (set * Note.colArray.length), 0, Std.int(offsets.length - 1))];
				addAnimationToConfig(tempConfig, 1, 'note$lane-${set + 1}', '$anim ${lanes[lane]} ${set + 1}', fps, offset, [], data);
			}
		}

		this.config = tempConfig;
		configs.set(path, this.config);
	}

	/** NovaFlare: route atlas loading through the engine-wide frame cache */
	function loadFramesCached(skin:String):Bool
	{
		if (!Cache.checkFrame(skin))
			Cache.setFrame(skin, {graphic: null, frame: Paths.getSparrowAtlas(skin, null, false)});
		frames = Cache.getFrame(skin);
		return frames != null;
	}

	public function spawnSplashNote(?x:Float = 0, ?y:Float = 0, ?noteData:Int = 0, ?note:Note, ?randomize:Bool = true)
	{
		if (note != null && note.noteSplashData.disabled)
			return;

		aliveTime = 0;

		if (!inEditor)
		{
			var loadedTexture:String = defaultNoteSplash + getSplashSkinPostfix();
			if (note != null && note.noteSplashData.texture != null) loadedTexture = note.noteSplashData.texture;
			else if (PlayState.SONG != null && PlayState.SONG.splashSkin != null && PlayState.SONG.splashSkin.length > 0) loadedTexture = PlayState.SONG.splashSkin;

			if (texture != loadedTexture) loadSplash(loadedTexture);
		}

		setPosition(x, y);

		if (babyArrow != null)
			setPosition(babyArrow.x - Note.swagWidth * 0.95, babyArrow.y - Note.swagWidth); // To prevent it from being misplaced for one game tick

		if (note != null)
			noteData = note.noteData;

		// ★ 取色必须用「随机化之前」的原始按键轨号：
		//   下面 randomize 会把 noteData 换成 `lane + 随机套数*animStride`（可能是 15、27…），
		//   旧代码拿它去 `% Note.colArray.length` 取色，>4K 时（animStride=10）算出的
		//   下标与真实轨道毫无关系 —— 溅射颜色错乱的直接原因。
		var colorLane:Int = noteData;

		if (randomize && maxAnims > 1)
			noteData = (noteData % animStride) + (FlxG.random.int(0, maxAnims - 1) * animStride);

		this.noteData = noteData;
		var anim:String = playDefaultAnim();

		var tempShader:RGBPalette = null;
		var mania:Int = (PlayState.SONG != null) ? PlayState.SONG.mania : 3;
		// · config.allowRGB 缺省（老 json 没写这个字段）视为允许
		// · 溅射编辑器（inEditor）必须按配置原样预览，否则在「谱面禁用 RGB」的歌曲里
		//   打开编辑器会完全看不到颜色，没法调色；
		// · 正常游戏 / 编辑器试玩走统一策略（谱面 disableNoteRGB + 玩家 splashRGB + 色相替换）。
		var useSplashRGB:Bool = (config.allowRGB != false) && (inEditor || Note.splashRGBAllowed(note));
		if (useSplashRGB)
		{
			var arr:Array<FlxColor> = Note.colorRow(mania, colorLane);

			tempShader = new RGBPalette();

			// ★★★ 关键：先把三个通道全部置成「不替换」的默认值，再让 config.rgb 覆盖。
			//
			//   RGBPalette 的构造器默认值是【纯红 FF0000 / 纯绿 00FF00 / 纯蓝 0000FF】，
			//   而着色器算的是 newColor.rgb = color.r*r + color.g*g + color.b*b ——
			//   只要 config.rgb 里少了某个通道（数组短于 3 项，或某项为 null），
			//   那个通道就会原样保留一个「满强度纯色」。
			//
			//   而 config.rgb 少项是**正常情况**：编辑器里的「No Replace（不替换该通道）」
			//   就是往 config.rgb 里写 null（见 NoteSplashEditorState.setConfigRGB）。
			//   结果就是溅射恒定带上纯绿 + 纯蓝两个满强度通道，怎么调 R 都看不出变化
			//   —— 也就是玩家反馈的「被设置成了纯红+纯绿，无论如何调整都是如此」。
			//
			//   修复方式：用「本轨默认配色行」把三通道预填成 不替换 状态（这与旧代码里
			//   `if (rgb == null) tempShader.r = arr[0]` 的语义一致），再按 config 覆盖。
			//   这样任何缺失项都不会再泄漏出构造器里那两个刺眼的纯色。
			applyDefaultSplashChannels(tempShader, arr);

			// If Note RGB is enabled:
			if (note == null || !note.noteSplashData.useGlobalShader)
			{
				var colors = config.rgb;
				if (colors != null)
				{
					for (i in 0...colors.length)
					{
						if (i > 2) break;

						var rgb = colors[i];
						// null = 该通道「不替换」，已由 applyDefaultSplashChannels 填好默认值
						if (rgb == null) continue;

						var r:Null<Int> = rgb.r;
						var g:Null<Int> = rgb.g;
						var b:Null<Int> = rgb.b;

						// ★ arr 可能为 null（arrowRGB 缺失/为空）——旧代码在这里直接 arr[0] 会 NPE
						if (arr != null && arr.length > 2)
						{
							if (r == null || Math.isNaN(r) || r < 0) r = arr[0];
							if (g == null || Math.isNaN(g) || g < 0) g = arr[1];
							if (b == null || Math.isNaN(b) || b < 0) b = arr[2];
						}
						if (r == null || Math.isNaN(r) || r < 0) r = 0xFFFFFF;
						if (g == null || Math.isNaN(g) || g < 0) g = 0xFFFFFF;
						if (b == null || Math.isNaN(b) || b < 0) b = 0xFFFFFF;

						var color:FlxColor = FlxColor.fromRGB(r, g, b);
						if (i == 0) tempShader.r = color;
						else if (i == 1) tempShader.g = color;
						else if (i == 2) tempShader.b = color;
					}
				}
				else
					copyGlobalLaneColors(tempShader, mania, colorLane);

				if (note != null)
				{
					if (note.noteSplashData.r != -1) tempShader.r = note.noteSplashData.r;
					if (note.noteSplashData.g != -1) tempShader.g = note.noteSplashData.g;
					if (note.noteSplashData.b != -1) tempShader.b = note.noteSplashData.b;
				}
			}
			else
				copyGlobalLaneColors(tempShader, mania, colorLane);
		}
		rgbShader.copyValues(tempShader);
		if (!config.allowPixel) rgbShader.pixelAmount = 1;
		else if (PlayState.isPixelStage) rgbShader.pixelAmount = PlayState.daPixelZoom;

		// NovaFlare: note color swap (hue/sat/brt from arrow HSV or the note's own values)
		if (colorSwap != null)
		{
			var hue:Float = 0;
			var sat:Float = 0;
			var brt:Float = 0;

			// ★ 旧代码写死 `arrowHSV[noteData % 4]`：>4K 高轨会套到错误的基础色 HSV
			var hsv:Array<Float> = Note.hsvRow(mania, colorLane);
			if (hsv != null && hsv.length > 2)
			{
				hue = hsv[0] / 360;
				sat = hsv[1] / 100;
				brt = hsv[2] / 100;
			}

			if (note != null)
			{
				hue = note.noteSplashHue;
				sat = note.noteSplashSat;
				brt = note.noteSplashBrt;
			}

			colorSwap.hue = hue;
			colorSwap.saturation = sat;
			colorSwap.brightness = brt;
		}

		offset.set(10, 10);
		var conf:NoteSplashAnim = config.animations.get(anim);
		var offsets:Array<Float> = [0, 0];
		if (conf != null) offsets = conf.offsets;
		if (offsets != null)
		{
			offset.x += offsets[0] * maniaScale;
			offset.y += offsets[1] * maniaScale;
		}

		animation.finishCallback = function(name:String) {
			kill();
			spawned = false;
		}

		alpha = ClientPrefs.data.splashAlpha;
		if (note != null) alpha = note.noteSplashData.a;

		antialiasing = ClientPrefs.data.antialiasing;
		if (note != null) antialiasing = note.noteSplashData.antialiasing;
		if (PlayState.isPixelStage && config.allowPixel) antialiasing = false;

		var minFps:Int = 22;
		var maxFps:Int = 26;
		if (conf != null)
		{
			minFps = conf.fps[0];
			if (minFps < 0) minFps = 0;

			maxFps = conf.fps[1];
			if (maxFps < 0) maxFps = 0;
		}

		if (animation.curAnim != null)
			animation.curAnim.frameRate = FlxG.random.int(minFps, maxFps);

		spawned = true;
	}

	public function playDefaultAnim()
	{
		var anim:String = noteDataMap.get(noteData);
		if (anim != null && animation.exists(anim))
			animation.play(anim, true);

		return anim;
	}

	/**
	 * 把三个通道预填成「不替换」状态（= 本轨默认配色行的 内色/边色/描边色）。
	 *
	 * 之所以必须先填：`new RGBPalette()` 的默认值是纯红/纯绿/纯蓝三个满强度向量，
	 * 而 config.rgb 允许缺项（数组短于 3 项、或某项为 null —— 编辑器里
	 * 「No Replace 不替换该通道」就会写 null）。缺项若保留构造器默认值，
	 * 溅射就恒带纯绿+纯蓝两个满强度通道，调 R 根本看不出变化。
	 *
	 * arr 为 null（arrowRGB 表缺失/为空）时保持构造器默认 —— 那正好是恒等矩阵
	 * (1,0,0)/(0,1,0)/(0,0,1)，等价于「完全不做替换」。
	 */
	static function applyDefaultSplashChannels(target:RGBPalette, arr:Array<FlxColor>):Void
	{
		if (target == null) return;
		if (arr == null || arr.length < 3) return;
		target.r = arr[0];
		target.g = arr[1];
		target.b = arr[2];
	}

	/**
	 * 把某条轨道在「全局 RGB 调色板」里的当前颜色拷进 tempShader。
	 *
	 * NovaFlare 的 RGBPalette 没有 copyValues（它是 PsychEK 风格、还有一个 shader 构造函数），
	 * 所以这里手动逐通道拷贝。轨道 → 槽位的映射走 Note.initializeGlobalRGBShader，
	 * 与 Note / StrumNote 完全一致（旧代码用 `noteData % Note.colArray.length`，
	 * >4K 时会取到别的轨道的颜色）。
	 */
	function copyGlobalLaneColors(target:RGBPalette, mania:Int, lane:Int):Void
	{
		if (target == null) return;
		var pal:RGBPalette = Note.initializeGlobalRGBShader(lane, mania);
		if (pal == null) return;
		target.r = pal.r;
		target.g = pal.g;
		target.b = pal.b;
		target.mult = pal.mult;
	}

	function checkForAnim(anim:String)
	{
		var animFrames = [];
		@:privateAccess
		animation.findByPrefix(animFrames, anim); // adds valid frames to animFrames

		return animFrames.length > 0;
	}

	var aliveTime:Float = 0;
	static var buggedKillTime:Float = 0.5; //automatically kills note splashes if they break to prevent it from flooding your HUD
	override function update(elapsed:Float)
	{
		if (spawned)
		{
			aliveTime += elapsed;
			if (animation.curAnim == null && aliveTime >= buggedKillTime)
			{
				kill();
				spawned = false;
			}
		}

		if (babyArrow != null)
		{
			if (copyX)
				x = babyArrow.x - Note.swagWidth * 0.95;

			if (copyY)
				y = babyArrow.y - Note.swagWidth;
		}
		super.update(elapsed);
	}

	public static function getSplashSkinPostfix()
	{
		var skin:String = '';
		if (ClientPrefs.data.splashSkin != ClientPrefs.defaultData.splashSkin)
			skin = '-' + ClientPrefs.data.splashSkin.trim().toLowerCase().replace(' ', '_');
		return skin;
	}

	public static function createConfig():NoteSplashConfig
	{
		return {
			animations: new Map(),
			scale: 1,
			allowRGB: true,
			allowPixel: true,
			rgb: null
		}
	}

	public static function addAnimationToConfig(config:NoteSplashConfig, scale:Float, name:String, prefix:String, fps:Array<Int>, offsets:Array<Float>, indices:Array<Int>, noteData:Int):NoteSplashConfig
	{
		if (config == null) config = createConfig();

		config.animations.set(name, {name: name, noteData: noteData, prefix: prefix, indices: indices, offsets: offsets, fps: fps});
		config.scale = scale;
		return config;
	}

	function set_config(value:NoteSplashConfig):NoteSplashConfig
	{
		if (value == null) value = createConfig();

		@:privateAccess
		animation.clearAnimations();
		noteDataMap.clear();
		maxAnims = 0;

		// NovaFlare: detect the legacy "note<lane>-<set>" naming so randomization matches its lane stride
		animStride = Note.colArray.length;
		for (i in value.animations)
		{
			if (i.name != null && ~/^note\d+-\d+$/.match(i.name))
			{
				animStride = laneCount();
				break;
			}
		}

		for (i in value.animations)
		{
			var key:String = i.name;
			if (i.prefix.length > 0 && key != null && key.length > 0)
			{
				if (i.indices != null && i.indices.length > 0)
					animation.addByIndices(key, i.prefix, i.indices, "", i.fps[1], false);
				else
					animation.addByPrefix(key, i.prefix, i.fps[1], false);

				noteDataMap.set(i.noteData, key);
				if (i.noteData % animStride == 0)
					maxAnims++;
			}
		}

		scale.set(value.scale * maniaScale, value.scale * maniaScale);
		return config = value;
	}

	function set_maxAnims(value:Int)
	{
		if (value > 0)
			noteData = Std.int(FlxMath.wrap(noteData, 0, (value * animStride) - 1));
		else
			noteData = 0;

		return maxAnims = value;
	}
}

class PixelSplashShaderRef
{
	public var shader:PixelSplashShader = new PixelSplashShader();
	public var enabled(default, set):Bool = true;
	public var pixelAmount(default, set):Float = 1;

	public function copyValues(tempShader:RGBPalette)
	{
		if (tempShader == null)
		{
			enabled = false;
			return;
		}

		for (i in 0...3)
		{
			shader.r.value[i] = tempShader.shader.r.value[i];
			shader.g.value[i] = tempShader.shader.g.value[i];
			shader.b.value[i] = tempShader.shader.b.value[i];
		}
		// ★ 顺序很重要：set_enabled 会把 mult 强制成 1/0，所以先更新 enabled 标志、
		//   再写 mult 的真实值。旧代码只写 mult 不更新 enabled，回收复用时标志会一直
		//   停在 false，语义与真实渲染状态不一致。
		enabled = (tempShader.shader.mult.value[0] != 0);
		shader.mult.value[0] = tempShader.shader.mult.value[0];
	}

	public function set_enabled(value:Bool)
	{
		enabled = value;
		shader.mult.value = [value ? 1 : 0];
		return value;
	}

	public function set_pixelAmount(value:Float)
	{
		pixelAmount = value;
		shader.uBlocksize.value = [value, value];
		return value;
	}

	public function reset()
	{
		shader.r.value = [0, 0, 0];
		shader.g.value = [0, 0, 0];
		shader.b.value = [0, 0, 0];
	}

	public function new()
	{
		reset();
		enabled = true;

		if (!PlayState.isPixelStage) pixelAmount = 1;
		else pixelAmount = PlayState.daPixelZoom;
	}
}

class PixelSplashShader extends FlxShader
{
	@:glFragmentHeader('
		#pragma header

		uniform vec3 r;
		uniform vec3 g;
		uniform vec3 b;
		uniform float mult;
		uniform vec2 uBlocksize;

		vec4 flixel_texture2DCustom(sampler2D bitmap, vec2 coord) {
			vec2 blocks = openfl_TextureSize / uBlocksize;
			vec4 color = flixel_texture2D(bitmap, floor(coord * blocks) / blocks);
			if (!hasTransform) {
				return color;
			}

			if (color.a == 0.0 || mult == 0.0) {
				return color * openfl_Alphav;
			}

			vec4 newColor = color;
			newColor.rgb = min(color.r * r + color.g * g + color.b * b, vec3(1.0));
			newColor.a = color.a;

			color = mix(color, newColor, mult);

			if (color.a > 0.0) {
				return vec4(color.rgb, color.a);
			}
			return vec4(0.0, 0.0, 0.0, 0.0);
		}')

	@:glFragmentSource('
		#pragma header

		void main() {
			gl_FragColor = flixel_texture2DCustom(bitmap, openfl_TextureCoordv);
		}')

	public function new()
	{
		super();
	}
}
