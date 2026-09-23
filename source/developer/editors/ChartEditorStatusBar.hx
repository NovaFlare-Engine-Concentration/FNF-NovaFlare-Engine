package developer.editors;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.text.FlxText;
import flixel.util.FlxColor;

import general.backend.language.Language;

/**
 * Chart 编辑器底部状态栏。
 * 显示：Zoom | 时间(s) | mm:ss | Section | Beat | Snap | Move Note Mode
 *
 * 由 ChartingState 每帧通过 setStatus() 更新各字段值。
 * 为避免播放时每帧重绘导致的"文字抽搐/闪烁"，只在拼接后的整串文本
 * 与上一帧不同时才刷新 rootLabel.text。
 */
class ChartEditorStatusBar extends FlxSpriteGroup
{
	// NovaFlare 规范：状态栏 = 卡片面板背景 + 主/提示文字
	static final BG_COLOR:FlxColor = 0xFF1C1F28;
	static final TEXT_DIM:FlxColor = 0xFF86909C;
	static final TEXT_VAL:FlxColor = 0xFFF2F3F5;
	static final SEP_COLOR:FlxColor = 0x14FFFFFF;

	public static final HEIGHT:Int = 25;

	var bg:FlxSprite;
	var rootLabel:FlxText;
	var sepText:String = '  |  ';

	// 当前状态字段
	public var zoomStr:String = '1 / 1';
	public var tempoStr:String = '0.00s / 0.00s';
	public var clockStr:String = '0:00 / 0:00';
	public var sectionStr:String = '0';
	public var beatStr:String = '0';
	public var snapStr:String = '16th';
	public var moveStr:String = 'False';

	// 缓存上一帧的完整文本，用于判定是否需要重绘
	var _lastFullText:String = '';

	public function new()
	{
		super();
		bg = new FlxSprite().makeGraphic(FlxG.width, HEIGHT, BG_COLOR);
		add(bg);
		var topLine:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, 1, 0x14FFFFFF);
		topLine.y = 0;
		add(topLine);

		rootLabel = new FlxText(10, 4, FlxG.width - 20, '', 13);
		rootLabel.setFormat(Paths.font(ChartEditorMenuBar.langFont()), 13, TEXT_VAL, LEFT);
		add(rootLabel);

		applyLang();
	}

	public function applyLang():Void
	{
		rootLabel.font = Paths.font(ChartEditorMenuBar.langFont());
		// 语言切换强制刷新
		_lastFullText = '';
		refreshText();
	}

	public function setZoom(v:String) { zoomStr = v; refreshText(); }
	public function setTempo(v:String) { tempoStr = v; refreshText(); }
	public function setClock(v:String) { clockStr = v; refreshText(); }
	public function setSection(v:String) { sectionStr = v; refreshText(); }
	public function setBeat(v:String) { beatStr = v; refreshText(); }
	public function setSnap(v:String) { snapStr = v; refreshText(); }
	public function setMove(v:String) { moveStr = v; refreshText(); }

	function refreshText():Void
	{
		var parts:Array<String> = [
			Language.get('status_zoom', 'charting') + ' ' + zoomStr,
			'',
			tempoStr,
			clockStr,
			Language.get('status_section', 'charting') + ' ' + sectionStr,
			Language.get('status_beat', 'charting') + ' ' + beatStr,
			Language.get('status_snap', 'charting') + ' ' + snapStr,
			Language.get('status_move', 'charting') + ' ' + moveStr,
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
		this.y = ChartEditorMenuBar.BAR_HEIGHT;
	}
}
