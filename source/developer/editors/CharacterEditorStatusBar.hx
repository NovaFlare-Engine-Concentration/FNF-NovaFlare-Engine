package developer.editors;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.text.FlxText;
import flixel.util.FlxColor;

import general.backend.language.Language;
import general.backend.Paths;

/**
 * 角色编辑器底部状态栏（与 ChartEditorStatusBar 同款）。
 * 显示：角色 | 动画 | Offset X/Y | 帧 | Zoom
 *
 * 由 CharacterEditorState 每帧通过 setXXX() 更新各字段值。
 * 为避免播放时每帧重绘导致的"文字抽搐/闪烁"，只在拼接后的整串文本
 * 与上一帧不同时才刷新 rootLabel.text。
 */
class CharacterEditorStatusBar extends FlxSpriteGroup
{
	// ★ NovaFlare 设计规范：页面底层背景 + 次级文字
	static final BG_COLOR:FlxColor = 0xFF12141A;  // 页面底层背景
	static final TEXT_DIM:FlxColor = 0xFF86909C;  // 提示文字（标签部分）
	static final TEXT_VAL:FlxColor = 0xFFC9CDD4;  // 次级文字（值部分）

	public static final HEIGHT:Int = 25;

	var bg:FlxSprite;
	var rootLabel:FlxText;
	var sepText:String = '  |  ';

	// 当前状态字段
	public var characterStr:String = '-';
	public var animStr:String = '-';
	public var offsetStr:String = '0 / 0';
	public var frameStr:String = '-';
	public var zoomStr:String = '1x';

	// 缓存上一帧的完整文本，用于判定是否需要重绘
	var _lastFullText:String = '';

	public function new()
	{
		super();
		bg = new FlxSprite().makeGraphic(FlxG.width, HEIGHT, BG_COLOR);
		add(bg);
		var topLine:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, 1, 0x14FFFFFF); // 半透明白边框
		topLine.y = 0;
		add(topLine);

		rootLabel = new FlxText(10, 4, FlxG.width - 20, '', 13);
		rootLabel.setFormat(Paths.font(CharacterEditorMenuBar.langFont()), 13, TEXT_VAL, LEFT);
		add(rootLabel);

		applyLang();
	}

	public function applyLang():Void
	{
		rootLabel.font = Paths.font(CharacterEditorMenuBar.langFont());
		// 语言切换强制刷新
		_lastFullText = '';
		refreshText();
	}

	public function setCharacter(v:String) { characterStr = v; refreshText(); }
	public function setAnim(v:String) { animStr = v; refreshText(); }
	public function setOffset(v:String) { offsetStr = v; refreshText(); }
	public function setFrame(v:String) { frameStr = v; refreshText(); }
	public function setZoom(v:String) { zoomStr = v; refreshText(); }

	function refreshText():Void
	{
		var parts:Array<String> = [
			Language.get('status_character', 'character') + ' ' + characterStr,
			Language.get('status_anim', 'character') + ' ' + animStr,
			Language.get('status_offset', 'character') + ' ' + offsetStr,
			Language.get('status_frame', 'character') + ' ' + frameStr,
			Language.get('status_zoom', 'character') + ' ' + zoomStr,
		];
		var full = parts.join('  |  ');
		// 只有文本真的变了才改 text 字段，否则 FlxText 每帧都会重建纹理，看起来就像在抽搐
		if (full != _lastFullText)
		{
			_lastFullText = full;
			rootLabel.text = full;
		}
	}

	override function update(elapsed:Float):Void
	{
		super.update(elapsed);
		this.y = CharacterEditorMenuBar.BAR_HEIGHT;
	}
}
