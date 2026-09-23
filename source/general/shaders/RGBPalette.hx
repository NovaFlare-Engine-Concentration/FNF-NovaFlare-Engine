package general.shaders;

import flixel.system.FlxAssets.FlxShader;

import games.objects.Note;

class RGBPalette
{
	public var shader(default, null):RGBPaletteShader = new RGBPaletteShader();
	public var r(default, set):FlxColor;
	public var g(default, set):FlxColor;
	public var b(default, set):FlxColor;
	public var mult(default, set):Float;

	/**
	 * ★ 建槽上下文签名（像素模式 + mania + 该轨当前配色）。
	 *
	 * 共享调色板（`Note.globalRgbShaders`）是跨歌曲、跨场景长期存活的静态对象，而它的
	 * 颜色依赖 `PlayState.isPixelStage` / `PlayState.SONG.mania` / `ClientPrefs.data.arrowRGB`
	 * 三个会变的外部状态。以前没有任何失效检测：先玩过 4K 再进 10K、先玩像素谱再进常规谱、
	 * 或在选项里改过配色，槽位里留的都是上一次的旧色 —— 音符拿到「脏调色板」后
	 * `defaultRGB()` 赋真实颜色就会与 `_original` 不一致，触发无谓的 palette 克隆。
	 * 0 表示「从未按上下文取过色」，必定刷新一次。
	 */
	public var context:Int = 0;

	private function set_r(color:FlxColor)
	{
		r = color;
		shader.r.value = [color.redFloat, color.greenFloat, color.blueFloat];
		return color;
	}

	private function set_g(color:FlxColor)
	{
		g = color;
		shader.g.value = [color.redFloat, color.greenFloat, color.blueFloat];
		return color;
	}

	private function set_b(color:FlxColor)
	{
		b = color;
		shader.b.value = [color.redFloat, color.greenFloat, color.blueFloat];
		return color;
	}

	private function set_mult(value:Float)
	{
		mult = FlxMath.bound(value, 0, 1);
		shader.mult.value = [mult];
		return mult;
	}

	public function new()
	{
		r = 0xFFFF0000;
		g = 0xFF00FF00;
		b = 0xFF0000FF;
		mult = 1.0;
	}
}

// automatic handler for easy usability
class RGBShaderReference
{
	/**
	 * 颜色通道 —— ★ 读取端直读父调色板（read-through），不缓存快照。
	 *
	 * 旧实现是 `(default, set)` 属性：构造时把 parent 的 r/g/b 拷进自己的字段，此后只有
	 * 「经过本引用赋值」才会更新。于是任何直接写调色板的代码（选项里的配色编辑器
	 * `applyWorkToGlobal()`、`Note.globalRgbShaders[i].r = …`、脚本写调色板、共享槽刷新）
	 * 都会让「脚本用 getPropertyFromGroup('notes', n, 'rgbShader.r') 读到的颜色」
	 * 与「画面上真正渲染的颜色」不一致 —— 也就是玩家反馈的「Lua 里读出来的音符颜色是错的」。
	 * 现在读取一律转发到 parent，读到的就是正在渲染的那份颜色。
	 */
	public var r(get, set):FlxColor;
	public var g(get, set):FlxColor;
	public var b(get, set):FlxColor;
	public var mult(get, set):Float;
	public var enabled(default, set):Bool = true;

	public var parent:RGBPalette;

	private var _owner:FlxSprite;
	private var _original:RGBPalette;

	// parent 缺失时的兜底存储（正常流程里 parent 永不为 null）
	private var _r:FlxColor = 0xFFFFFFFF;
	private var _g:FlxColor = 0xFFFFFFFF;
	private var _b:FlxColor = 0xFFFFFFFF;
	private var _mult:Float = 1.0;

	// ★ 刻意不写 inline：Lua/HScript 通过 Reflect.setProperty/getProperty 走 hxcpp 的属性表，
	//   只有真实存在的访问器方法才保证能被反射解析。
	private function get_r():FlxColor return (parent != null) ? parent.r : _r;
	private function get_g():FlxColor return (parent != null) ? parent.g : _g;
	private function get_b():FlxColor return (parent != null) ? parent.b : _b;
	private function get_mult():Float return (parent != null) ? parent.mult : _mult;

	public function new(owner:FlxSprite, ref:RGBPalette)
	{
		parent = ref;
		_owner = owner;
		_original = ref;

		if (owner != null && ref != null)
			owner.shader = ref.shader;

		if (ref != null)
		{
			_r = ref.r;
			_g = ref.g;
			_b = ref.b;
			_mult = ref.mult;
		}
	}

	private function set_r(value:FlxColor)
	{
		_r = value;
		if (parent == null) return value;
		if (allowNew && _original != null && value != _original.r)
			cloneOriginal();
		return (parent.r = value);
	}

	private function set_g(value:FlxColor)
	{
		_g = value;
		if (parent == null) return value;
		if (allowNew && _original != null && value != _original.g)
			cloneOriginal();
		return (parent.g = value);
	}

	private function set_b(value:FlxColor)
	{
		_b = value;
		if (parent == null) return value;
		if (allowNew && _original != null && value != _original.b)
			cloneOriginal();
		return (parent.b = value);
	}

	private function set_mult(value:Float)
	{
		_mult = value;
		if (parent == null) return value;
		if (allowNew && _original != null && value != _original.mult)
			cloneOriginal();
		return (parent.mult = value);
	}

	/**
	 * 开关 RGB 着色器。
	 *
	 * ★ 关闭时同时记住「用户/引擎明确要求关闭」这一意图：`cloneOriginal()` 之后不会
	 *   再偷偷把着色器挂回去（见该函数的注释）。显式赋值 `enabled = true`（脚本
	 *   强制开色）依旧有效 —— 这是唯一的重新启用入口。
	 */
	private function set_enabled(value:Bool)
	{
		_engineDisabled = !value;
		if (_owner != null)
			_owner.shader = (value && parent != null) ? parent.shader : null;
		return (enabled = value);
	}

	/** 引擎是否明确关闭了该 RGB 引用（关闭后 cloneOriginal 不得复活着色器） */
	private var _engineDisabled:Bool = false;

	public var allowNew = true;

	private function cloneOriginal()
	{
		if (!allowNew)
			return;

		allowNew = false;
		if (_original != parent)
			return;

		parent = new RGBPalette();
		parent.r = _original.r;
		parent.g = _original.g;
		parent.b = _original.b;
		parent.mult = _original.mult;
		parent.context = _original.context;

		// ★★★ 关键修复：以前这里无条件 `_owner.shader = parent.shader`。
		//   于是「谱面 disableNoteRGB / 玩家 noteRGB 关闭」把着色器摘掉之后，只要还有
		//   任何一处给 r/g/b 赋值（defaultRGB、Hurt Note 类型、KeyChange 换轨、
		//   Lua 着色、编辑器预览、globalRgbShaders 脏槽导致的取值不一致……），
		//   克隆就会把 RGB 着色器重新挂回 sprite —— 表现为「RGB 关不掉，音符/受体
		//   照样被染色」。禁用状态下克隆只更新颜色数据，不碰 owner.shader。
		if (!_engineDisabled && enabled && _owner != null)
			_owner.shader = parent.shader;
		// trace('created new shader');
	}
}

class RGBPaletteShader extends FlxShader
{
	@:glFragmentHeader('
		#pragma header
		
		uniform vec3 r;
		uniform vec3 g;
		uniform vec3 b;
		uniform float mult;

		vec4 flixel_texture2DCustom(sampler2D bitmap, vec2 coord) {
			vec4 color = flixel_texture2D(bitmap, coord);
			if (!hasTransform || color.a == 0.0 || mult == 0.0) {
				return color;
			}

			vec4 newColor = color;
			newColor.rgb = min(color.r * r + color.g * g + color.b * b, vec3(1.0));
			newColor.a = color.a;
			
			color = mix(color, newColor, mult);
			
			if(color.a > 0.0) {
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

