package developer.editors;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.text.FlxText;
import flixel.util.FlxColor;

import general.backend.language.Language;
import general.backend.Paths;

/**
 * 对话编辑器底部状态栏（与 CharacterEditorStatusBar 同款）。
 * 显示：行 x/y | 角色 | 动画 | 语速
 *
 * 由 DialogueEditorState 每次变更时通过 setXXX() 更新各字段值。
 * 为避免播放时每帧重绘导致的文字抽搐/闪烁，只在拼接后的整串文本
 * 与上一帧不同时才刷新 rootLabel.text。
 */
class DialogueEditorStatusBar extends FlxSpriteGroup
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
	public var lineStr:String = '-';
	public var charStr:String = '-';
	public var animStr:String = '-';
	public var speedStr:String = '-';

	// 缓存上一帧的完整文本，用于判断是否需要重绘
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
		rootLabel.setFormat(Paths.font(DialogueEditorMenuBar.langFont()), 13, TEXT_VAL, LEFT);
		add(rootLabel);

		applyLang();
	}

	public function applyLang():Void
	{
		rootLabel.font = Paths.font(DialogueEditorMenuBar.langFont());
		// 语言切换强制刷新
		_lastFullText = '';
		refreshText();
	}

	public function setLine(v:String) { lineStr = v; refreshText(); }
	public function setChar(v:String) { charStr = v; refreshText(); }
	public function setAnim(v:String) { animStr = v; refreshText(); }
	public function setSpeed(v:String) { speedStr = v; refreshText(); }

	function refreshText():Void
	{
		var parts:Array<String> = [
			Language.get('status_line', 'dialogue') + ' ' + lineStr,
			Language.get('status_char', 'dialogue') + ' ' + charStr,
			Language.get('status_anim', 'dialogue') + ' ' + animStr,
			Language.get('status_speed', 'dialogue') + ' ' + speedStr,
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
		this.y = DialogueEditorMenuBar.BAR_HEIGHT;
	}
}
