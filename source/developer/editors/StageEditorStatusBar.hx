package developer.editors;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.text.FlxText;
import flixel.util.FlxColor;

import general.backend.language.Language;
import general.backend.Paths;

/**
 * 舞台编辑器底部状态栏（与 ChartEditorStatusBar 同款）。
 * 显示：舞台 | 目录 | 对象 | 坐标 X/Y | 缩放
 *
 * 由 StageEditorState 每帧通过 setXXX() 更新各字段值。
 * 为避免播放时每帧重绘导致的"文字抽搐/闪烁"，只在拼接后的整串文本
 * 与上一帧不同时才刷新 rootLabel.text。
 */
class StageEditorStatusBar extends FlxSpriteGroup
{
	static final BG_COLOR:FlxColor = 0xFF12141A;    // 页面底层背景
	static final TEXT_DIM:FlxColor = 0xFF86909C;    // 提示文字
	static final TEXT_VAL:FlxColor = 0xFFC9CDD4;    // 次级文字
	static final BORDER_COLOR:FlxColor = 0x14FFFFFF; // 分割/边框

	public static final HEIGHT:Int = 25;

	var bg:FlxSprite;
	var rootLabel:FlxText;

	// 当前状态字段
	public var stageStr:String = '-';
	public var directoryStr:String = '-';
	public var objectStr:String = '-';
	public var posStr:String = '-';
	public var zoomStr:String = '1 / 1';

	// 缓存上一帧的完整文本，用于判定是否需要重绘
	var _lastFullText:String = '';

	public function new()
	{
		super();
		bg = new FlxSprite().makeGraphic(FlxG.width, HEIGHT, BG_COLOR);
		add(bg);
		var topLine:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, 1, BORDER_COLOR);
		topLine.y = 0;
		add(topLine);

		rootLabel = new FlxText(10, 4, FlxG.width - 20, '', 13);
		rootLabel.setFormat(Paths.font(StageEditorMenuBar.langFont()), 13, TEXT_VAL, LEFT);
		add(rootLabel);

		applyLang();
	}

	public function applyLang():Void
	{
		rootLabel.font = Paths.font(StageEditorMenuBar.langFont());
		// 语言切换强制刷新
		_lastFullText = '';
		refreshText();
	}

	public function setStage(v:String) { stageStr = v; refreshText(); }
	public function setDirectory(v:String) { directoryStr = v; refreshText(); }
	public function setObject(v:String) { objectStr = v; refreshText(); }
	public function setPos(v:String) { posStr = v; refreshText(); }
	public function setZoom(v:String) { zoomStr = v; refreshText(); }

	function refreshText():Void
	{
		var parts:Array<String> = [
			Language.get('status_stage', 'stage') + ' ' + stageStr,
			Language.get('status_directory', 'stage') + ' ' + directoryStr,
			Language.get('status_object', 'stage') + ' ' + objectStr,
			Language.get('status_pos', 'stage') + ' ' + posStr,
			Language.get('status_zoom', 'stage') + ' ' + zoomStr,
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
		this.y = StageEditorMenuBar.BAR_HEIGHT;
	}
}
