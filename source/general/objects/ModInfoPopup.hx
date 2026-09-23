package general.objects;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.graphics.FlxGraphic;
import flixel.math.FlxRect;
import flixel.text.FlxText;
import flixel.util.FlxColor;

import general.backend.Achievements;
import general.backend.ClientPrefs;
import general.backend.Mods;
import general.backend.Paths;
import general.backend.language.Language;

/**
 * Mod 信息下拉面板（编辑器顶栏点击标题时在标题正下方展开）：
 * 宽度 = 标题块（图标 + NovaFlare Engine）宽度；描述区高度约 20 行。
 * 内容：当前 mod 名字 / pack 图标 / 介绍，介绍支持滚轮与按住拖拽滚动。
 * 点击面板外任意处关闭。没有选中 mod 时显示占位文案并解锁成就“自欺欺人”。
 */
class ModInfoPopup extends FlxSpriteGroup
{
	static inline var HEADER_H:Int = 58; // 名字行 + 图标行
	static inline var DESC_LINES:Int = 20; // 描述区行数
	static inline var LINE_H:Int = 18;
	static inline var PAD:Int = 10;
	static inline var ICON_PX:Float = 48; // 头部图标尺寸

	/** 当前语言对应的字体（中文等非拉丁文字需要 Lang-ZH.ttf，montserrat 无中文字形） */
	static function langFont():String
	{
		var n:String = 'chillax';
		try
		{
			n = Language.get('fontName', 'main');
		}
		catch (e:Dynamic) {}
		if (n == null || n == '' || n.indexOf('fontName') != -1 || n.indexOf('404') != -1)
			n = (ClientPrefs.data.language == 'Chinese') ? 'Lang-ZH' : 'chillax';
		return Paths.font(n + '.ttf');
	}

	var bg:FlxSprite;
	var titleTxt:FlxText;
	var iconSpr:FlxSprite;
	var descTxt:FlxText;

	var panelW:Float = 240;
	var panelH:Float = 0;

	// 面板左上角的绝对（逻辑屏幕）坐标。
	// 注意：本 flixel fork 的 FlxSpriteGroup 在设置 group.x/y 时会把偏移
	// 平移给子对象（transformChildren），而之后给子对象显式赋值又会覆盖
	// 该平移 —— 所以本组件一律不用 group 平移，子对象全部使用绝对坐标。
	var panelX:Float = 0;
	var panelY:Float = 0;

	// 描述滚动
	var descAreaX:Float = 0;
	var descAreaY:Float = 0;
	var descAreaW:Float = 0;
	var descAreaH:Float = 0;
	var descScrollY:Float = 0;
	var descMaxScroll:Float = 0;
	var descDragY:Float = 0;
	var descDragging:Bool = false;

	var openedNoMod:Bool = false;
	var layoutReady:Bool = false;

	public function new()
	{
		super();
		scrollFactor.set();
		visible = false;

		bg = new FlxSprite().makeGraphic(1, 1, 0xFF202024);
		add(bg);

		titleTxt = new FlxText(0, 0, 0, '', 15);
		titleTxt.setFormat(langFont(), 15, 0xFFFFFFFF);
		add(titleTxt);

		iconSpr = new FlxSprite(0, 0);
		add(iconSpr);

		descTxt = new FlxText(0, 0, 0, '');
		descTxt.setFormat(langFont(), 13, 0xFFC8C8C8);
		add(descTxt);

		// 注意：visible 需在子对象 add 之后再设置 —— 本 fork 的 SpriteGroup
		// 会把 visible 传递给子对象（transformChildren），提前设置会漏掉它们。
		visible = false;
	}

	/** 在窗口条标题块正下方展开 */
	public function openUnder(bar:WindowControlBar):Void
	{
		// 先刷新数据（名字/图标/介绍），名字宽度用于决定面板宽度
		refresh();

		// —— 测量名字自然宽度（临时给超大 fieldWidth 避免换行）——
		titleTxt.wordWrap = false;
		titleTxt.fieldWidth = 4000;
		titleTxt.updateHitbox();
		var nameW:Float = titleTxt.width;

		// —— 面板宽度：至少容纳标题块；名字更长时面板跟着加宽（上限为屏宽）——
		panelW = Math.max(180, bar.titleBlockWidth() + PAD * 2);
		panelW = Math.max(panelW, nameW + ICON_PX + PAD * 3 + 6);
		panelW = Math.min(panelW, FlxG.width - 60);
		panelH = HEADER_H + DESC_LINES * LINE_H + PAD;

		// 锚点：标题块左缘、条底部；若面板会超出视口底部则上移
		var px:Float = bar.titleAnchorX();
		var py:Float = WindowControlBar.BAR_HEIGHT;
		if (py + panelH > FlxG.height - 4)
			py = FlxG.height - 4 - panelH;
		if (px + panelW > FlxG.width - 2)
			px = FlxG.width - 2 - panelW;
		if (px < 2)
			px = 2;
		panelX = px;
		panelY = py;

		// 先把组坐标归零，抵消上次 openUnder 可能留下的平移（transformChildren）
		if (x != 0)
			x = 0;
		if (y != 0)
			y = 0;

		// 面板背景尺寸（绝对定位）
		bg.makeGraphic(Std.int(panelW), Std.int(panelH), 0xFF202024);
		bg.x = panelX;
		bg.y = panelY;
		redrawBorder();

		// 头部：图标（右，48px 垂直居中）+ 名字（左，单行）
		iconSpr.x = panelX + panelW - PAD - ICON_PX;
		iconSpr.y = panelY + PAD + (ICON_PX - iconSpr.height) / 2;

		// 名字可用宽度：面板被屏宽卡住时先缩小字号（15 → 最小 10），
		// 仍放不下才截断省略号（兜底）
		titleTxt.fieldWidth = panelW - PAD * 3 - ICON_PX;
		titleTxt.updateHitbox();
		while (titleTxt.size > 10 && titleTxt.width > titleTxt.fieldWidth)
		{
			titleTxt.setFormat(langFont(), titleTxt.size - 1, 0xFFFFFFFF);
			titleTxt.updateHitbox();
		}
		titleTxt.x = panelX + PAD;
		titleTxt.y = panelY + PAD + (ICON_PX - titleTxt.height) / 2;
		truncateTitle();

		// 描述区域（相对面板左上角的偏移，判定时再加 panelX/panelY）
		descAreaX = PAD;
		descAreaY = HEADER_H;
		descAreaW = panelW - PAD * 2;
		descAreaH = panelH - HEADER_H - PAD;

		descTxt.x = panelX + descAreaX;
		descTxt.y = panelY + descAreaY;
		descTxt.fieldWidth = descAreaW;
		descTxt.updateHitbox();

		var contentH:Float = descTxt.height;
		descMaxScroll = Math.max(0, contentH - descAreaH);
		descScrollY = 0;
		applyDescClip();
		layoutReady = true;

		visible = true;
		descDragging = false;
	}

	/** 名字超宽时截断为省略号（单行） */
	function truncateTitle():Void
	{
		var maxW:Float = titleTxt.fieldWidth;
		titleTxt.updateHitbox();
		if (titleTxt.width <= maxW)
			return;
		var t:String = titleTxt.text;
		while (t.length > 1 && titleTxt.width > maxW)
		{
			t = t.substring(0, t.length - 1);
			titleTxt.text = t + '…';
			titleTxt.updateHitbox();
		}
	}

	public function closePopup():Void
	{
		visible = false;
		descDragging = false;
	}

	/** 读取当前 mod（或空状态）并刷新内容 */
	function refresh():Void
	{
		var folder:String = Mods.currentModDirectory;
		var hasMod:Bool = (folder != null && folder.length > 0);
		var pack:Dynamic = hasMod ? Mods.getPack() : null;

		var name:String = (pack != null && pack.name != null) ? Std.string(pack.name) : (hasMod ? folder : Language.get('modInfoEmpty', 'main'));
		titleTxt.text = name;

		loadIcon(folder, hasMod);

		var desc:String = (pack != null && pack.description != null) ? Std.string(pack.description) : '';
		if (!hasMod)
			desc = Language.get('modInfoEmptyDesc', 'main');
		descTxt.text = (desc == null) ? '' : desc;

		if (!hasMod && !openedNoMod)
		{
			openedNoMod = true;
			#if ACHIEVEMENTS_ALLOWED
			try
			{
				if (Achievements.exists('self_deception') && !Achievements.isUnlocked('self_deception'))
					Achievements.unlock('self_deception');
			}
			catch (e:Dynamic) {}
			#end
		}
	}

	function loadIcon(folder:String, hasMod:Bool):Void
	{
		var graphic:FlxGraphic = null;
		if (hasMod)
		{
			graphic = Paths.cacheBitmap(Paths.mods('$folder/pack.png'));
			if (graphic == null)
				graphic = Paths.cacheBitmap(Paths.mods('$folder/pack-pixel.png'));
		}
		if (graphic == null)
			graphic = Paths.image('unknownMod');
		if (graphic == null)
		{
			iconSpr.visible = false;
			return;
		}
		iconSpr.visible = true;
		iconSpr.loadGraphic(graphic, true, 150, 150);
		var frames:Int = Math.floor(graphic.width / 150) * Math.floor(graphic.height / 150);
		if (frames > 1)
		{
			iconSpr.animation.add('icon', [for (i in 0...frames) i], 10);
			iconSpr.animation.play('icon');
		}
		iconSpr.setGraphicSize(48, 48);
		iconSpr.updateHitbox();
	}

	var borderSprites:Array<FlxSprite> = [];
	function redrawBorder():Void
	{
		for (s in borderSprites)
			remove(s, true);
		borderSprites = [];
		var addLine = function(w:Int, h:Int, px:Float, py:Float) {
			var s = new FlxSprite().makeGraphic(w, h, 0xFF4A4A52);
			s.x = panelX + px;
			s.y = panelY + py;
			add(s);
			borderSprites.push(s);
		};
		addLine(Std.int(panelW), 1, 0, 0);
		addLine(Std.int(panelW), 1, 0, panelH - 1);
		addLine(1, Std.int(panelH), 0, 0);
		addLine(1, Std.int(panelH), panelW - 1, 0);
	}

	function applyDescClip():Void
	{
		if (descTxt == null)
			return;
		var s:Float = Math.max(0, Math.min(descScrollY, descMaxScroll));
		descTxt.clipRect = FlxRect.get(0, s, descAreaW, descAreaH);
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		if (!visible)
			return;

		// 鼠标相对面板左上角的位置（子对象全部绝对定位，故用 panelX/panelY）
		var mx:Float = FlxG.mouse.x - panelX;
		var my:Float = FlxG.mouse.y - panelY;

		// 滚轮滚动（悬停在描述区）
		if (descMaxScroll > 0 && FlxG.mouse.wheel != 0)
		{
			if (mx >= descAreaX && mx < descAreaX + descAreaW && my >= descAreaY && my < descAreaY + descAreaH)
			{
				descScrollY -= FlxG.mouse.wheel * 40;
				descScrollY = Math.max(0, Math.min(descScrollY, descMaxScroll));
				applyDescClip();
			}
		}

		// 按住拖拽滚动
		if (descDragging)
		{
			if (!FlxG.mouse.pressed)
				descDragging = false;
			else
			{
				descScrollY += (descDragY - my);
				descScrollY = Math.max(0, Math.min(descScrollY, descMaxScroll));
				descDragY = my;
				applyDescClip();
			}
		}

		if (FlxG.mouse.justPressed)
		{
			var inside:Bool = mx >= 0 && mx < panelW && my >= 0 && my < panelH;

			// 描述区拖拽滚动
			if (inside && descMaxScroll > 0 && mx >= descAreaX && mx < descAreaX + descAreaW && my >= descAreaY && my < descAreaY + descAreaH)
			{
				descDragging = true;
				descDragY = my;
				return;
			}
			// 点击面板外 → 关闭
			if (!inside)
				closePopup();
		}
	}
}
