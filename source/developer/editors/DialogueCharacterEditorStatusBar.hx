package developer.editors;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.text.FlxText;
import flixel.util.FlxColor;

import general.backend.language.Language;
import general.backend.Paths;

/**
 * 对话立绘编辑器底部状态栏（与 CharacterEditorStatusBar 同款）。
 * 显示：位置 | 图像 | 动画 | 偏移 | 缩放
 */
class DialogueCharacterEditorStatusBar extends FlxSpriteGroup
{
	static final BG_COLOR:FlxColor = 0xFF12141A;  // 页面底层背景
	static final TEXT_DIM:FlxColor = 0xFF86909C;  // 提示文字（标签部分）
	static final TEXT_VAL:FlxColor = 0xFFC9CDD4;  // 次级文字（值部分）

	public static final HEIGHT:Int = 25;

	var bg:FlxSprite;
	var rootLabel:FlxText;

	// 当前状态字段
	public var sideStr:String = '-';
	public var imageStr:String = '-';
	public var animStr:String = '-';
	public var offsetStr:String = '0 / 0';
	public var scaleStr:String = '-';

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
		rootLabel.setFormat(Paths.font(DialogueCharacterEditorMenuBar.langFont()), 13, TEXT_VAL, LEFT);
		add(rootLabel);

		applyLang();
	}

	public function applyLang():Void
	{
		rootLabel.font = Paths.font(DialogueCharacterEditorMenuBar.langFont());
		_lastFullText = '';
		refreshText();
	}

	public function setSide(v:String) { sideStr = v; refreshText(); }
	public function setImage(v:String) { imageStr = v; refreshText(); }
	public function setAnim(v:String) { animStr = v; refreshText(); }
	public function setOffset(v:String) { offsetStr = v; refreshText(); }
	public function setScale(v:String) { scaleStr = v; refreshText(); }

	function refreshText():Void
	{
		var parts:Array<String> = [
			Language.get('status_side', 'dialoguechar') + ' ' + sideStr,
			Language.get('status_image', 'dialoguechar') + ' ' + imageStr,
			Language.get('status_anim', 'dialoguechar') + ' ' + animStr,
			Language.get('status_offset', 'dialoguechar') + ' ' + offsetStr,
			Language.get('status_scale', 'dialoguechar') + ' ' + scaleStr,
		];
		var full = parts.join('  |  ');
		if (full != _lastFullText)
		{
			_lastFullText = full;
			rootLabel.text = full;
		}
	}

	override function update(elapsed:Float):Void
	{
		super.update(elapsed);
		this.y = DialogueCharacterEditorMenuBar.BAR_HEIGHT;
	}
}
