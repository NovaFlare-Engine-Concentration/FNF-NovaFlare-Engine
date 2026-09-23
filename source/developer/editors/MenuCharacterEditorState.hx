package developer.editors;

import haxe.Json;

import openfl.net.FileReference;
import openfl.events.Event;
import openfl.events.IOErrorEvent;
import openfl.net.FileFilter;
import openfl.display.BitmapData;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;

import flixel.addons.ui.FlxUIInputText;

import general.backend.ClientPrefs;
import general.backend.MusicBeatState;
import general.backend.Paths;
import general.backend.language.Language;

import general.objects.MenuCharacter;

/**
 * 菜单角色编辑器（NovaFlare 深色风格新 UI）
 *
 * 布局（水平居中 + 底对齐）：
 *  - 底部一条居中一级主菜单：[<] CharacterType | Character | Hint（提示）
 *  - 点按钮 → 卡片面板向上弹出（二级子菜单内容）
 *      CharacterType：三种角色类型单选行（Opponent / Boyfriend / Girlfriend）
 *      Character   ：图片名 / Idle 动画 / Start Press 动画 / 缩放 / Flip X / 重新加载
 *      Hint        ：操作提示文字，下方是 Load Character / Save Character
 *  - 按钮条最左小箭头：显示/隐藏整个新 UI（以屏幕中心为锚点收缩/展开，箭头随左缘移动）
 *  - 面板上方跟随一条状态条：当前调整角色 + 实时偏移
 *  - 旧 UI（两个 FlxUITabMenu 框 / 旧按钮 / 旧提示文字 / 左上角偏移文字）不再显示
 *
 * 视觉：NovaFlare 设计 token（AARRGGBB 深色模式）
 *  - 页面底 0xFF12141A / 卡片 0xFF1C1F28 / 通用 hover 0x147C7FFF / 分割边框 0x14FFFFFF
 *  - 一级主菜单：未选中 0xFFC9CDD4；选中渐变 0xFF4F46E5→0xFF7C3AED + 白字 + 下缘装饰条 0xFFA78BFA
 *  - 二级子菜单：hover 0x0F8B5CF6；选中底 0x268B5CF6；选中文字 0xFFA78BFA
 *  - 主按钮 Primary：渐变 0xFF6366F1→0xFF8B5CF6（hover 加深，按下更深）；文字白色
 *  - 次要按钮 Secondary：模拟边框 0x26FFFFFF + hover 底 0x147C7FFF + hover 文字 0xFFA78BFA
 *  - 文字输入框：WeekEditor 面板同款（原生 FlxUIInputText 常驻自绘框上），聚焦时边框高亮 0xFF8B5CF6
 */
class MenuCharacterEditorState extends MusicBeatState
{
	var grpWeekCharacters:FlxTypedGroup<MenuCharacter>;
	var characterFile:MenuCharacterFile = null;
	var defaultCharacters:Array<String> = ['dad', 'bf', 'gf'];

	// ============ 布局常量 ============
	static final PANEL_W:Int = 420; // 面板宽
	static final BAR_H:Int = 36; // 底部一级菜单条高
	static final ARROW_W:Int = 36; // 折叠箭头宽
	static final BTN_W:Int = 140; // 每个一级按钮宽
	static final PANEL_GAP:Int = 4; // 面板底 / 状态条底 与按钮条顶的间距
	static final CHIP_H:Int = 20; // 面板上方状态条高
	static final IN_H:Int = 22; // 输入框高
	static final PANEL_H_TYPE:Int = 122;
	static final PANEL_H_CHAR:Int = 210;
	static final PANEL_H_HINT:Int = 150;

	// ============ NovaFlare 设计 token（AARRGGBB） ============
	// 中性色
	static final C_PAGE_BG:Int = 0xFF12141A; // 页面底层背景
	static final C_CARD_BG:Int = 0xFF1C1F28; // 卡片面板背景
	static final C_HOVER_NEUTRAL:Int = 0x147C7FFF; // hover 通用底色
	static final C_BORDER:Int = 0x14FFFFFF; // 分割/边框
	static final C_TEXT_MAIN:Int = 0xFFF2F3F5; // 主文字
	static final C_TEXT_SEC:Int = 0xFFC9CDD4; // 次级文字
	static final C_TEXT_HINT:Int = 0xFF86909C; // 提示文字

	// 一级主菜单
	static final C_TITLE:Int = 0xFFC9CDD4; // 未选中文字
	static final C_MENU_G1:Int = 0xFF4F46E5; // 选中渐变起点
	static final C_MENU_G2:Int = 0xFF7C3AED; // 选中渐变终点
	static final C_ACCENT_BAR:Int = 0xFFA78BFA; // 左侧装饰条 / 链接文字

	// 二级子菜单
	static final C_ROW_HOVER:Int = 0x0F8B5CF6; // hover 底色
	static final C_ROW_SELECTED:Int = 0x268B5CF6; // 选中底色
	static final C_ROW_SELECTED_TEXT:Int = 0xFFA78BFA; // 选中文字

	// 主按钮 Primary（与 ChartEditor 同款：渐变底常显，hover 用半透明白提亮层）
	static final C_PRIMARY_G1:Int = 0xFF6366F1;
	static final C_PRIMARY_G2:Int = 0xFF8B5CF6;

	// 次要按钮 Secondary
	static final C_SEC_BORDER:Int = 0x26FFFFFF; // 模拟边框
	static final C_ACCENT:Int = 0xFF8B5CF6; // 强调紫（主渐变终点 / 输入聚焦边框）
	static final C_TITLE_HOVER:Int = 0xFFFFFFFF; // 一级菜单 hover/选中文字（白）

	// ================= 新 UI 状态 =================
	var barKeys:Array<String> = ['type', 'char', 'hint'];
	var barFolded:Bool = false;
	var barAnimating:Bool = false;
	var activePanel:String = null; // 'type' / 'char' / 'hint'；null = 全部关闭

	// ================= 底部一级菜单条成员 =================
	var barBg:FlxSprite;
	var barTopLine:FlxSprite;
	var arrowTxt:FlxText;
	var arrowHit:FlxSprite;
	var barTexts:Array<FlxText> = [];
	var barHits:Array<FlxSprite> = [];
	var barHoverOv:Array<FlxSprite> = []; // hover 底色
	var barSelGrads:Array<FlxSprite> = []; // 选中渐变底
	var barAccents:Array<FlxSprite> = []; // 选中项下缘装饰条

	// ================= 三个面板 =================
	var panelBorders:Array<FlxSprite> = [];
	var panelBgs:Array<FlxSprite> = [];
	var panelBits:Array<Array<FlxSprite>> = [[], [], []]; // 每个面板所有成员（显隐切换用）

	// ---- CharacterType 面板：3 行单选 ----
	var typeRowBgs:Array<FlxSprite> = []; // 行底色（hover/选中，白底图 + 染色）
	var typeRings:Array<FlxSprite> = [];
	var typeFills:Array<FlxSprite> = [];
	var typeLabels:Array<FlxText> = [];
	var typeHits:Array<FlxSprite> = [];

	// ---- Character 面板：字段 + 缩放 + FlipX + 重新加载 ----
	var charLbls:Array<FlxText> = []; // 3 个字段标签
	var charInputs:Array<FlxUIInputText> = []; // 原生输入（常驻自绘框上，手动焦点）
	var charBoxes:Array<FlxSprite> = []; // 输入框外框（白底图 + 染色）
	var charInners:Array<FlxSprite> = [];
	var charBoxHits:Array<FlxSprite> = [];
	var scaleLbl:FlxText;
	var scaleBox:FlxSprite;
	var scaleInner:FlxSprite;
	var scaleSelfTxt:FlxText;
	var scaleMinus:FlxSprite; // [-] 渐变底（常显）
	var scaleMinusHov:FlxSprite; // [-] hover 提亮层
	var scaleMinusTxt:FlxText;
	var scalePlus:FlxSprite;
	var scalePlusHov:FlxSprite; // [+] hover 提亮层
	var scalePlusTxt:FlxText;
	var scaleVal:Float = 1;
	var flipBorder:FlxSprite;
	var flipBg:FlxSprite;
	var flipHit:FlxSprite;
	var flipRing:FlxSprite;
	var flipFill:FlxSprite;
	var flipLbl:FlxText;
	var reloadBorder:FlxSprite;
	var reloadBg:FlxSprite;
	var reloadHit:FlxSprite;
	var reloadLbl:FlxText;

	// ---- Hint 面板：提示文字 + Load/Save ----
	var hintLbls:Array<FlxText> = [];
	var loadBorder:FlxSprite;
	var loadBg:FlxSprite;
	var loadHit:FlxSprite;
	var loadLbl:FlxText;
	var saveIdle:FlxSprite; // Primary 渐变底（常显）
	var saveHov:FlxSprite; // hover 提亮层（半透明白）
	var saveHit:FlxSprite;
	var saveLbl:FlxText;

	// ---- 面板上方状态条（当前调整角色 + 偏移） ----
	var chipBorder:FlxSprite;
	var chipBg:FlxSprite;
	var chipPrefixTxt:FlxText;
	var chipValueTxt:FlxText;

	// ---- 输入框文本缓存（原生输入实时同步数据用） ----
	var inputCaches:Array<String> = [];

	var curTypeSelected:Int = 0; // 0 = Opponent, 1 = Boyfriend, 2 = Girlfriend

	override function create()
	{
		// 强制刷新语言数据，确保 menuchar 分组被加载（多语言文案）
		Language.resetData();
		// 页面底层背景（NovaFlare 深色）
		FlxG.camera.bgColor = C_PAGE_BG;

		characterFile = {
			image: 'Menu_Dad',
			scale: 1,
			position: [0, 0],
			idle_anim: 'M Dad Idle',
			confirm_anim: 'M Dad Idle',
			flipX: false
		};

		#if DISCORD_ALLOWED
		// Updating Discord Rich Presence
		DiscordClient.changePresence("Menu Character Editor", "Editting: " + characterFile.image);
		#end

		grpWeekCharacters = new FlxTypedGroup<MenuCharacter>();
		for (char in 0...3)
		{
			var weekCharacterThing:MenuCharacter = new MenuCharacter((FlxG.width * 0.25) * (1 + char) - 150, defaultCharacters[char]);
			weekCharacterThing.y += 70;
			weekCharacterThing.alpha = 0.2;
			grpWeekCharacters.add(weekCharacterThing);
		}

		add(new FlxSprite(0, 56).makeGraphic(FlxG.width, 386, 0xFFF9CF51));
		add(grpWeekCharacters);

		buildNewUI();

		FlxG.mouse.visible = true;
		updateCharTypeBox();

		addVirtualPad(MENU_CHARACTER, MENU_CHARACTER);

		super.create();
	}

	// ================= 几何 =================
	function barTop():Float
	{
		return FlxG.height - BAR_H;
	}

	function barTotalW():Int
	{
		return ARROW_W + BTN_W * barKeys.length;
	}

	function barX():Float
	{
		return (FlxG.width - barTotalW()) / 2;
	}

	function panelX():Float
	{
		return (FlxG.width - PANEL_W) / 2;
	}

	function panelIdxOf(key:String):Int
	{
		switch (key)
		{
			case 'char':
				return 1;
			case 'hint':
				return 2;
			default:
				return 0;
		}
	}

	function panelHOf(key:String):Int
	{
		switch (key)
		{
			case 'char':
				return PANEL_H_CHAR;
			case 'hint':
				return PANEL_H_HINT;
			default:
				return PANEL_H_TYPE;
		}
	}

	function panelTopY(key:String):Float
	{
		return barTop() - PANEL_GAP - panelHOf(key);
	}

	function uiFont():String
	{
		return Paths.font(Language.get('fontName', 'main') + '.ttf');
	}

	function tr(key:String):String
	{
		var t:String = Language.get(key, 'menuchar');
		if (t == key || t == key + ' (404)')
			t = key;
		return t;
	}

	// ================= 自绘控件基础 =================
	/** 纯色块（颜色含 alpha 时直接写入位图） */
	function mkBox(x:Float, y:Float, w:Int, h:Int, argb:Int):FlxSprite
	{
		var s:FlxSprite = new FlxSprite(x, y).makeGraphic(w, h, argb);
		s.scrollFactor.set();
		add(s);
		return s;
	}

	/** 生成 上→下 / 左→右 线性渐变位图（与 ChartEditorMenuBar.makeGradSprite 同款实现） */
	function makeGradSprite(w:Int, h:Int, c1:Int, c2:Int, horizontal:Bool = false):FlxSprite
	{
		var s:FlxSprite = new FlxSprite().makeGraphic(w, h, FlxColor.WHITE);
		var bd:BitmapData = s.pixels;
		if (bd != null)
		{
			bd.lock();
			for (y in 0...h)
			{
				for (x in 0...w)
				{
					var t:Float = 0;
					if (horizontal && w > 1)
						t = x / (w - 1);
					else if (h > 1)
						t = y / (h - 1);
					bd.setPixel32(x, y, FlxColor.interpolate(c1, c2, t));
				}
			}
			bd.unlock();
			s.dirty = true;
		}
		s.scrollFactor.set();
		add(s);
		return s;
	}

	/** 白底图块：颜色 = 目标 RGB，alpha = 目标 alpha（用于每帧 hover/选中变色） */
	function mkTintBox(x:Float, y:Float, w:Int, h:Int, argb:Int):FlxSprite
	{
		var s:FlxSprite = new FlxSprite(x, y).makeGraphic(w, h, 0xFFFFFFFF);
		s.scrollFactor.set();
		tintTo(s, argb);
		add(s);
		return s;
	}

	/** 把 ARGB 目标色（含 alpha）应用到白底图块 */
	function tintTo(s:FlxSprite, argb:Int):Void
	{
		if (s == null)
			return;
		s.color = argb;
		s.alpha = ((argb >>> 24) & 0xFF) / 255;
	}

	/** 透明命中区 */
	function mkHit(x:Float, y:Float, w:Int, h:Int):FlxSprite
	{
		var s:FlxSprite = new FlxSprite(x, y).makeGraphic(w, h, FlxColor.TRANSPARENT);
		s.scrollFactor.set();
		add(s);
		return s;
	}

	/** 文本 */
	function mkTxt(x:Float, y:Float, w:Int, str:String, size:Int, color:Int, align:FlxTextAlign):FlxText
	{
		var t:FlxText = new FlxText(x, y, w, str, size);
		t.setFormat(uiFont(), size, color, align);
		t.wordWrap = false;
		t.scrollFactor.set();
		add(t);
		return t;
	}

	// ================= 构建新 UI =================
	function buildNewUI():Void
	{
		buildBar();
		buildTypePanel();
		buildCharPanel();
		buildHintPanel();
		buildChip();
		// 初始全关面板
		for (i in 0...3)
			setPanelVisible(i, false);
		refreshTypeRows();
		refreshCharPanel();
	}

	/** 底部一级菜单条：[<]  CharacterType | Character | Hint */
	function buildBar():Void
	{
		var x0:Float = barX();
		var y0:Float = barTop();

		barBg = mkBox(x0, y0, barTotalW(), BAR_H, C_CARD_BG);
		barTopLine = mkBox(x0, y0, barTotalW(), 1, C_BORDER);

		arrowTxt = mkTxt(x0, 0, ARROW_W, '<', 18, C_TEXT_SEC, FlxTextAlign.CENTER);
		arrowTxt.y = y0 + (BAR_H - arrowTxt.height) / 2;
		arrowHit = mkHit(x0, y0, ARROW_W, BAR_H);

		for (i in 0...barKeys.length)
		{
			var bx:Float = x0 + ARROW_W + i * BTN_W;

			// 选中态：主渐变背景（4F46E5 → 7C3AED，左→右；ChartEditor 同款）
			var grad:FlxSprite = makeGradSprite(BTN_W, BAR_H, C_MENU_G1, C_MENU_G2, true);
			grad.x = bx;
			grad.y = y0;
			grad.visible = false;
			barSelGrads.push(grad);

			// 选中装饰条（A78BFA，位于选中项下缘）
			var accent:FlxSprite = mkBox(bx + 12, y0 + BAR_H - 2, BTN_W - 24, 2, C_ACCENT_BAR);
			accent.visible = false;
			barAccents.push(accent);

			// hover 底色（通用 hover 半透明蓝）
			var hov:FlxSprite = mkBox(bx, y0, BTN_W, BAR_H, C_HOVER_NEUTRAL);
			hov.visible = false;
			barHoverOv.push(hov);

			var t:FlxText = mkTxt(bx, 0, BTN_W, tr('menu_' + barKeys[i]), 14, C_TITLE, FlxTextAlign.CENTER);
			t.y = y0 + (BAR_H - t.height) / 2;
			barTexts.push(t);
			barHits.push(mkHit(bx, y0, BTN_W, BAR_H));
		}
	}

	/** CharacterType 面板：三行单选（二级子菜单样式） */
	function buildTypePanel():Void
	{
		var idx:Int = 0;
		var px:Float = panelX();
		var py:Float = panelTopY('type');
		panelBorders[idx] = mkBox(px - 1, py - 1, PANEL_W + 2, PANEL_H_TYPE + 2, C_BORDER);
		panelBgs[idx] = mkBox(px, py, PANEL_W, PANEL_H_TYPE, C_CARD_BG);
		panelBits[idx].push(panelBorders[idx]);
		panelBits[idx].push(panelBgs[idx]);

		var typeKey:Array<String> = ['opponent', 'boyfriend', 'girlfriend'];
		var rowYs:Array<Float> = [8, 42, 76];
		for (i in 0...3)
		{
			var ry:Float = py + rowYs[i];

			// 行底色（白底图，hover/选中每帧染色；默认全透明）
			var rowBg:FlxSprite = mkTintBox(px, ry, PANEL_W, 34, 0x00000000);
			typeRowBgs.push(rowBg);
			panelBits[idx].push(rowBg);

			// 选中方块（16×16，边框 + 内填充）
			var ring:FlxSprite = mkBox(px + 16, ry + 9, 16, 16, C_SEC_BORDER);
			var fill:FlxSprite = mkBox(px + 19, ry + 12, 10, 10, 0x00000000);
			typeRings.push(ring);
			typeFills.push(fill);
			panelBits[idx].push(ring);
			panelBits[idx].push(fill);

			var lbl:FlxText = mkTxt(px + 46, ry, PANEL_W - 58, tr('type_' + typeKey[i]), 14, C_TEXT_SEC, FlxTextAlign.LEFT);
			lbl.y = ry + (34 - lbl.height) / 2 + 1;
			typeLabels.push(lbl);
			panelBits[idx].push(lbl);

			var hit:FlxSprite = mkHit(px, ry, PANEL_W, 34);
			typeHits.push(hit);
			panelBits[idx].push(hit);
		}
	}

	/** Character 面板：图片名 / Idle / Start Press / 缩放 / FlipX + 重新加载 */
	function buildCharPanel():Void
	{
		var idx:Int = 1;
		var px:Float = panelX();
		var py:Float = panelTopY('char');
		panelBorders[idx] = mkBox(px - 1, py - 1, PANEL_W + 2, PANEL_H_CHAR + 2, C_BORDER);
		panelBgs[idx] = mkBox(px, py, PANEL_W, PANEL_H_CHAR, C_CARD_BG);
		panelBits[idx].push(panelBorders[idx]);
		panelBits[idx].push(panelBgs[idx]);

		var lblKeys:Array<String> = ['lbl_image', 'lbl_idle', 'lbl_confirm'];
		var lblYs:Array<Float> = [2, 40, 78];
		var boxYs:Array<Float> = [20, 58, 96];
		var initVals:Array<String> = [characterFile.image, characterFile.idle_anim, characterFile.confirm_anim];

		for (i in 0...3)
		{
			var lbl:FlxText = mkTxt(px + 12, py + lblYs[i], PANEL_W - 24, tr(lblKeys[i]), 12, C_TEXT_SEC, FlxTextAlign.LEFT);
			charLbls.push(lbl);
			panelBits[idx].push(lbl);

			// 输入框底：外框（白底染色）+ 内底（页面底色，内凹感）
			var box:FlxSprite = mkTintBox(px + 12, py + boxYs[i], PANEL_W - 24, IN_H, C_BORDER);
			var inner:FlxSprite = mkBox(px + 13, py + boxYs[i] + 1, PANEL_W - 26, IN_H - 2, C_PAGE_BG);
			var hit:FlxSprite = mkHit(px + 12, py + boxYs[i], PANEL_W - 24, IN_H);
			charBoxes.push(box);
			charInners.push(inner);
			charBoxHits.push(hit);
			panelBits[idx].push(box);
			panelBits[idx].push(inner);
			panelBits[idx].push(hit);

			// 原生输入框（WeekEditor 面板同款做法）：常驻自绘框上；
			// active=false 防止它的原生鼠标聚焦逻辑与自绘命中区打架，
			// 聚焦/失焦由 updateNewUI 手动管理（文本实时同步数据）
			var native:FlxUIInputText = new FlxUIInputText(px + 15, py + boxYs[i] + 3, PANEL_W - 30, initVals[i], 12, C_TEXT_MAIN,
				FlxColor.TRANSPARENT, true);
			native.font = uiFont();
			native.scrollFactor.set();
			native.visible = true;
			native.active = false;
			add(native);
			charInputs.push(native);
			panelBits[idx].push(native);
			inputCaches.push(initVals[i]);
		}

		// 缩放行：标签 + [-][数值][+]
		scaleLbl = mkTxt(px + 12, py + 124, PANEL_W - 24, tr('lbl_scale'), 12, C_TEXT_SEC, FlxTextAlign.LEFT);
		panelBits[idx].push(scaleLbl);

		var sy:Float = py + 140;
		scaleBox = mkTintBox(px + 12, sy, PANEL_W - 24, IN_H, C_BORDER);
		scaleInner = mkBox(px + 13, sy + 1, PANEL_W - 26, IN_H - 2, C_PAGE_BG);
		scaleSelfTxt = mkTxt(px + 18, 0, PANEL_W - 96, scaleText(), 12, C_TEXT_MAIN, FlxTextAlign.LEFT);
		scaleSelfTxt.y = sy + (IN_H - scaleSelfTxt.height) / 2;

		var btnW:Int = 20;
		var plusX:Float = px + 12 + (PANEL_W - 24) - btnW - 1;
		var minusX:Float = plusX - btnW - 2;
		// 渐变迷你按钮（ChartEditor 同款：窄按钮用上→下垂直渐变，hover 半透明白提亮层）
		scalePlus = makeGradSprite(btnW, IN_H - 2, C_PRIMARY_G1, C_PRIMARY_G2);
		scalePlus.x = plusX;
		scalePlus.y = sy + 1;
		scalePlusHov = mkBox(plusX, sy + 1, btnW, IN_H - 2, 0x14FFFFFF);
		scalePlusHov.visible = false;
		scaleMinus = makeGradSprite(btnW, IN_H - 2, C_PRIMARY_G1, C_PRIMARY_G2);
		scaleMinus.x = minusX;
		scaleMinus.y = sy + 1;
		scaleMinusHov = mkBox(minusX, sy + 1, btnW, IN_H - 2, 0x14FFFFFF);
		scaleMinusHov.visible = false;
		scalePlusTxt = mkTxt(plusX, 0, btnW, '+', 13, 0xFFFFFFFF, FlxTextAlign.CENTER);
		scaleMinusTxt = mkTxt(minusX, 0, btnW, '-', 13, 0xFFFFFFFF, FlxTextAlign.CENTER);
		scalePlusTxt.y = sy + 1 + ((IN_H - 2) - scalePlusTxt.height) / 2 - 1;
		scaleMinusTxt.y = scalePlusTxt.y;

		panelBits[idx].push(scaleBox);
		panelBits[idx].push(scaleInner);
		panelBits[idx].push(scaleSelfTxt);
		panelBits[idx].push(scaleMinus);
		panelBits[idx].push(scaleMinusHov);
		panelBits[idx].push(scaleMinusTxt);
		panelBits[idx].push(scalePlus);
		panelBits[idx].push(scalePlusHov);
		panelBits[idx].push(scalePlusTxt);

		// FlipX（次级按钮 + 勾选方块）与 Reload（次级按钮）半宽并排
		var ay:Float = py + 166;
		var bw:Int = Std.int((PANEL_W - 24 - 8) / 2);

		// Flip X 块
		flipBorder = mkBox(px + 12, ay, bw, 32, C_SEC_BORDER);
		flipBg = mkTintBox(px + 13, ay + 1, bw - 2, 30, 0x00000000);
		flipRing = mkBox(px + 12 + 12, ay + 7, 16, 16, C_SEC_BORDER);
		flipFill = mkBox(px + 12 + 15, ay + 10, 10, 10, 0x00000000);
		flipLbl = mkTxt(px + 12 + 38, 0, bw - 50, tr('chk_flip_x'), 13, C_TEXT_SEC, FlxTextAlign.LEFT);
		flipLbl.y = ay + (32 - flipLbl.height) / 2;
		flipHit = mkHit(px + 12, ay, bw, 32);
		panelBits[idx].push(flipBorder);
		panelBits[idx].push(flipBg);
		panelBits[idx].push(flipRing);
		panelBits[idx].push(flipFill);
		panelBits[idx].push(flipLbl);
		panelBits[idx].push(flipHit);

		// Reload Char 块（次级按钮）
		var rx:Float = px + 12 + bw + 8;
		reloadBorder = mkBox(rx, ay, bw, 32, C_SEC_BORDER);
		reloadBg = mkTintBox(rx + 1, ay + 1, bw - 2, 30, 0x00000000);
		reloadLbl = mkTxt(rx, 0, bw, tr('btn_reload'), 13, C_TEXT_SEC, FlxTextAlign.CENTER);
		reloadLbl.y = ay + (32 - reloadLbl.height) / 2;
		reloadHit = mkHit(rx, ay, bw, 32);
		panelBits[idx].push(reloadBorder);
		panelBits[idx].push(reloadBg);
		panelBits[idx].push(reloadLbl);
		panelBits[idx].push(reloadHit);

		refreshFlipVisual();
	}

	/** Hint 面板：提示文字（上）+ Load（次级）/ Save（Primary） */
	function buildHintPanel():Void
	{
		var idx:Int = 2;
		var px:Float = panelX();
		var py:Float = panelTopY('hint');
		panelBorders[idx] = mkBox(px - 1, py - 1, PANEL_W + 2, PANEL_H_HINT + 2, C_BORDER);
		panelBgs[idx] = mkBox(px, py, PANEL_W, PANEL_H_HINT, C_CARD_BG);
		panelBits[idx].push(panelBorders[idx]);
		panelBits[idx].push(panelBgs[idx]);

		var keys:Array<String> = ['h_arrow', 'h_space1', 'h_space2', 'h_esc'];
		for (i in 0...4)
		{
			var t:FlxText = mkTxt(px + 12, py + 8 + i * 20, PANEL_W - 24, tr(keys[i]), 12, C_TEXT_HINT, FlxTextAlign.LEFT);
			hintLbls.push(t);
			panelBits[idx].push(t);
		}

		var sep:FlxSprite = mkBox(px + 12, py + 92, PANEL_W - 24, 1, C_BORDER);
		panelBits[idx].push(sep);

		var ay:Float = py + 100;
		var bw:Int = Std.int((PANEL_W - 24 - 8) / 2);

		// Load Character：次级按钮（模拟边框 + hover）
		loadBorder = mkBox(px + 12, ay, bw, 34, C_SEC_BORDER);
		loadBg = mkTintBox(px + 13, ay + 1, bw - 2, 32, 0x00000000);
		loadLbl = mkTxt(px + 12, 0, bw, tr('btn_load'), 13, C_TEXT_SEC, FlxTextAlign.CENTER);
		loadLbl.y = ay + (34 - loadLbl.height) / 2;
		loadHit = mkHit(px + 12, ay, bw, 34);
		panelBits[idx].push(loadBorder);
		panelBits[idx].push(loadBg);
		panelBits[idx].push(loadLbl);
		panelBits[idx].push(loadHit);

		// Save Character：Primary 渐变按钮（ChartEditor 同款：渐变底常显 + hover 提亮层）
		var sx:Float = px + 12 + bw + 8;
		saveIdle = makeGradSprite(bw, 34, C_PRIMARY_G1, C_PRIMARY_G2, true);
		saveIdle.x = sx;
		saveIdle.y = ay;
		saveHov = mkBox(sx, ay, bw, 34, 0x14FFFFFF);
		saveHov.visible = false;
		saveLbl = mkTxt(sx, 0, bw, tr('btn_save'), 13, 0xFFFFFFFF, FlxTextAlign.CENTER);
		saveLbl.y = ay + (34 - saveLbl.height) / 2;
		saveHit = mkHit(sx, ay, bw, 34);
		panelBits[idx].push(saveIdle);
		panelBits[idx].push(saveHov);
		panelBits[idx].push(saveLbl);
		panelBits[idx].push(saveHit);
	}

	/** 面板上方状态条（背景/边框大小随文本变化；前缀次级色 + 角色名/偏移强调色） */
	function buildChip():Void
	{
		chipBorder = mkBox(0, 0, 2, CHIP_H + 2, C_BORDER);
		chipBg = mkBox(0, 0, 2, CHIP_H, C_CARD_BG);
		chipPrefixTxt = mkTxt(0, 0, 0, '', 12, C_TEXT_SEC, FlxTextAlign.LEFT);
		chipValueTxt = mkTxt(0, 0, 0, '', 12, C_ACCENT_BAR, FlxTextAlign.LEFT);
		updateChip();
	}

	/** 粗略量文本宽（用于状态条自适应背景） */
	function measureTextWidth(txt:String):Float
	{
		var w:Float = 0;
		for (i in 0...txt.length)
		{
			w += (txt.charCodeAt(i) > 127) ? 12 : 6.8;
		}
		return w;
	}

	function offsetStr():String
	{
		var p:Array<Int> = characterFile.position;
		if (ClientPrefs.data.language == 'Chinese')
			return '【' + p[0] + '，' + p[1] + '】';
		return '[' + p[0] + ', ' + p[1] + ']';
	}

	/** 刷新状态条：文案 + 位置（面板开着贴面板上方，否则贴按钮条上方） */
	function updateChip():Void
	{
		var show:Bool = !barFolded;
		chipBorder.visible = show;
		chipBg.visible = show;
		chipPrefixTxt.visible = show;
		chipValueTxt.visible = show;
		if (!show)
			return;

		var names:Array<String> = [tr('type_opponent'), tr('type_boyfriend'), tr('type_girlfriend')];
		var prefix:String = tr('cur_role');
		var value:String = names[curTypeSelected] + offsetStr();
		chipPrefixTxt.text = prefix;
		chipValueTxt.text = value;

		var w:Int = Std.int(measureTextWidth(prefix + value)) + 22;
		if (w < 80)
			w = 80;
		chipBg.makeGraphic(w, CHIP_H, C_CARD_BG);
		chipBorder.makeGraphic(w + 2, CHIP_H + 2, C_BORDER);

		var cx:Float = FlxG.width / 2;
		chipBg.x = cx - w / 2;
		chipBorder.x = chipBg.x - 1;

		var top:Float = barTop() - PANEL_GAP - CHIP_H;
		if (activePanel != null)
			top = panelTopY(activePanel) - PANEL_GAP - CHIP_H;
		chipBorder.y = top - 1;
		chipBg.y = top;

		chipPrefixTxt.x = chipBg.x + 10;
		chipPrefixTxt.y = top + (CHIP_H - chipPrefixTxt.height) / 2;
		chipValueTxt.x = chipPrefixTxt.x + Std.int(measureTextWidth(prefix)) + 2;
		chipValueTxt.y = chipPrefixTxt.y;
	}

	// ================= 面板显隐 =================
	function setPanelVisible(idx:Int, on:Bool):Void
	{
		// Character 面板（原生输入所在）：隐藏时收起输入焦点（防止继续打字/占焦点）
		if (idx == 1 && !on)
			blurCharInputs();

		for (s in panelBits[idx])
		{
			if (s != null)
				s.visible = on;
		}
		if (on && idx == 0)
		{
			// 单选行底色每帧由 hover/选中状态刷新
			for (b in typeRowBgs)
				tintTo(b, 0x00000000);
		}
	}

	function openPanel(key:String):Void
	{
		activePanel = key;
		for (i in 0...3)
			setPanelVisible(i, i == panelIdxOf(key));
		if (key == 'type')
			refreshTypeRows();
		else if (key == 'char')
			refreshCharPanel();
		updateChip();
	}

	function closePanel():Void
	{
		activePanel = null;
		for (i in 0...3)
			setPanelVisible(i, false);
		updateChip();
	}

	// ================= 折叠箭头（显示/隐藏新 UI，带动画） =================
	/** 按当前条宽缩放把整条（底条/顶线/箭头）居中摆放，箭头跟随左缘移动 */
	function layoutBarAnchored():Void
	{
		var cx:Float = FlxG.width / 2;
		var s:Float = barBg.scale.x;
		barBg.x = cx - barBg.width * s / 2;
		barTopLine.x = barBg.x;
		arrowHit.x = barBg.x;
		arrowTxt.x = barBg.x;
	}

	function toggleBarFolded():Void
	{
		if (barAnimating)
			return;
		if (!barFolded && activePanel != null)
			closePanel();
		barAnimating = true;
		barFolded = !barFolded;

		var dur:Float = 0.2;
		var targetScale:Float = barFolded ? (ARROW_W / barTotalW()) : 1;

		// 箭头字符切换 + 缩放脉动
		arrowTxt.text = barFolded ? '>' : '<';
		arrowTxt.scale.set(1.35, 1.35);
		FlxTween.cancelTweensOf(arrowTxt.scale);
		FlxTween.tween(arrowTxt.scale, {x: 1, y: 1}, dur * 1.5, {ease: FlxEase.backOut});

		// 一级按钮文字淡入/淡出（其余按钮层由 updateNewUI 按状态显隐）
		for (i in 0...barTexts.length)
		{
			var t:FlxText = barTexts[i];
			FlxTween.cancelTweensOf(t);
			if (barFolded)
			{
				FlxTween.tween(t, {alpha: 0}, dur);
			}
			else
			{
				t.visible = true;
				t.alpha = 0;
				FlxTween.tween(t, {alpha: 1}, dur);
			}
		}
		// 折叠后按钮点击区立即失效，展开等动画完成再生效
		if (barFolded)
		{
			for (h in barHits)
				h.visible = false;
		}

		// 按钮条宽收缩/展开：以屏幕中心为锚点，箭头（条最左）随左缘一起移动
		FlxTween.cancelTweensOf(barBg.scale);
		FlxTween.tween(barBg.scale, {x: targetScale}, dur, {
			onUpdate: function(_)
			{
				layoutBarAnchored();
			},
			onComplete: function(_)
			{
				barBg.scale.x = targetScale;
				barTopLine.scale.x = targetScale;
				layoutBarAnchored();
				if (!barFolded)
				{
					for (h in barHits)
						h.visible = true;
				}
				barAnimating = false;
			}
		});
		FlxTween.cancelTweensOf(barTopLine.scale);
		FlxTween.tween(barTopLine.scale, {x: targetScale}, dur);

		// 状态条随折叠隐藏/显示
		updateChip();
	}

	// ================= 原生输入框（常驻自绘框上，WeekEditor 面板同款） =================
	/** 是否有输入框正在聚焦输入（阻塞编辑器方向键/音量键等） */
	function anyInputFocused():Bool
	{
		for (w in charInputs)
		{
			var f:Bool = false;
			try { f = w.hasFocus; } catch (e:Dynamic) {}
			if (f)
				return true;
		}
		return false;
	}

	/** 收起所有输入框焦点 */
	function blurCharInputs():Void
	{
		for (w in charInputs)
		{
			try { w.hasFocus = false; } catch (e:Dynamic) {}
		}
	}

	/** 聚焦某个输入框（点击自绘框区域时调用；已聚焦则不打断光标位置） */
	function focusCharInput(idx:Int):Void
	{
		if (idx < 0 || idx >= charInputs.length)
			return;
		var f:Bool = false;
		try { f = charInputs[idx].hasFocus; } catch (e:Dynamic) {}
		if (f)
			return;
		blurCharInputs();
		try { charInputs[idx].hasFocus = true; } catch (e:Dynamic) {}
	}

	/** 每帧：原生输入框文本变化 → 实时写回数据（等价旧版 CHANGE_EVENT 行为） */
	function updateCharInputTexts():Void
	{
		for (i in 0...3)
		{
			var t:String = charInputs[i].text;
			if (t != inputCaches[i])
			{
				inputCaches[i] = t;
				switch (i)
				{
					case 0:
						characterFile.image = t;
					case 1:
						characterFile.idle_anim = t;
					case 2:
						characterFile.confirm_anim = t;
				}
			}
		}
	}

	/** 程序化设置输入框文本后同步缓存（如加载文件） */
	function cacheCharInputs():Void
	{
		for (i in 0...3)
			inputCaches[i] = charInputs[i].text;
	}

	// ================= 面板控件值刷新 =================
	function refreshTypeRows():Void
	{
		for (i in 0...3)
		{
			var sel:Bool = (i == curTypeSelected);
			typeRings[i].makeGraphic(16, 16, sel ? C_ACCENT_BAR : C_SEC_BORDER);
			typeFills[i].makeGraphic(10, 10, sel ? C_ACCENT_BAR : 0x00000000);
			typeLabels[i].color = sel ? C_ROW_SELECTED_TEXT : C_TEXT_SEC;
			if (!sel)
				tintTo(typeRowBgs[i], 0x00000000);
		}
	}

	function refreshFlipVisual():Void
	{
		var on:Bool = characterFile.flipX;
		flipRing.makeGraphic(16, 16, on ? C_ACCENT_BAR : C_SEC_BORDER);
		flipFill.makeGraphic(10, 10, on ? C_ACCENT_BAR : 0x00000000);
	}

	function refreshCharPanel():Void
	{
		scaleSelfTxt.text = scaleText();
		refreshFlipVisual();
	}

	function scaleText():String
	{
		return Std.string(Math.round(scaleVal * 100) / 100);
	}

	// ================= 面板动作 =================
	function setType(i:Int):Void
	{
		curTypeSelected = i;
		updateCharTypeBox();
		refreshTypeRows();
		updateChip();
	}

	function scaleStep(dir:Int):Void
	{
		var v:Float = Math.round((scaleVal + 0.05 * dir) * 100) / 100;
		if (v < 0.1)
			v = 0.1;
		if (v > 30)
			v = 30;
		scaleVal = v;
		characterFile.scale = v;
		scaleSelfTxt.text = scaleText();
		reloadSelectedCharacter();
	}

	function toggleFlip():Void
	{
		characterFile.flipX = !characterFile.flipX;
		refreshFlipVisual();
		grpWeekCharacters.members[curTypeSelected].flipX = characterFile.flipX;
	}

	// ================= 角色数据逻辑 =================
	function updateCharTypeBox()
	{
		updateCharacters();
		refreshTypeRows();
	}

	function updateCharacters()
	{
		for (i in 0...3)
		{
			var char:MenuCharacter = grpWeekCharacters.members[i];
			char.alpha = 0.2;
			char.character = '';
			char.changeCharacter(defaultCharacters[i]);
		}
		reloadSelectedCharacter();
	}

	function reloadSelectedCharacter()
	{
		var char:MenuCharacter = grpWeekCharacters.members[curTypeSelected];

		char.alpha = 1;
		char.frames = Paths.getSparrowAtlas('menucharacters/' + characterFile.image);
		char.animation.addByPrefix('idle', characterFile.idle_anim, 24);
		if (curTypeSelected == 1)
			char.animation.addByPrefix('confirm', characterFile.confirm_anim, 24, false);
		char.flipX = (characterFile.flipX == true);

		char.scale.set(characterFile.scale, characterFile.scale);
		char.updateHitbox();
		char.animation.play('idle');
		updateOffset();

		#if DISCORD_ALLOWED
		// Updating Discord Rich Presence
		DiscordClient.changePresence("Menu Character Editor", "Editting: " + characterFile.image);
		#end
	}

	function updateOffset()
	{
		var char:MenuCharacter = grpWeekCharacters.members[curTypeSelected];
		char.offset.set(characterFile.position[0], characterFile.position[1]);
		updateChip();
	}

	// ================= 每帧交互 =================
	function pointIn(mx:Float, my:Float, s:FlxSprite):Bool
	{
		if (s == null)
			return false;
		return (mx >= s.x && mx <= s.x + s.width && my >= s.y && my <= s.y + s.height);
	}

	/** hover 视觉 + 点击处理（箭头折叠 / 一级按钮 / 面板控件 / 点外关闭） */
	function updateNewUI():Void
	{
		var mx:Float = FlxG.mouse.viewX;
		var my:Float = FlxG.mouse.viewY;

		// —— 一级菜单条状态（箭头 / hover / 选中） ——
		var onArrow:Bool = pointIn(mx, my, arrowHit);
		arrowTxt.color = onArrow ? 0xFFFFFFFF : C_TEXT_SEC;

		var hoverBtn:Int = -1;
		for (i in 0...barHits.length)
		{
			var h:FlxSprite = barHits[i];
			if (!h.visible)
				continue;
			if (pointIn(mx, my, h))
			{
				hoverBtn = i;
				break;
			}
		}
		for (i in 0...barTexts.length)
		{
			var isOpen:Bool = (activePanel != null && barKeys[i] == activePanel);
			var hovered:Bool = (i == hoverBtn);
			barSelGrads[i].visible = (!barFolded && isOpen);
			barAccents[i].visible = (!barFolded && isOpen);
			barHoverOv[i].visible = (!barFolded && hovered && !isOpen);
			// ★ NovaFlare 规范（ChartEditor 同款）：选中 = 主渐变底 + 白字；hover = 通用 hover 底 + 白字
			barTexts[i].color = (isOpen || hovered) ? C_TITLE_HOVER : C_TITLE;
		}

		// —— 面板内容 hover / 状态视觉 ——
		if (activePanel == 'type')
		{
			for (i in 0...typeHits.length)
			{
				var sel:Bool = (i == curTypeSelected);
				var hov:Bool = pointIn(mx, my, typeHits[i]);
				if (sel)
					tintTo(typeRowBgs[i], C_ROW_SELECTED);
				else
					tintTo(typeRowBgs[i], hov ? C_ROW_HOVER : 0x00000000);
			}
		}
		else if (activePanel == 'char')
		{
			for (i in 0...charBoxHits.length)
			{
				var focused:Bool = false;
				try { focused = charInputs[i].hasFocus; } catch (e:Dynamic) {}
				var hov:Bool = pointIn(mx, my, charBoxHits[i]);
				if (focused)
					tintTo(charBoxes[i], C_ACCENT);
				else
					tintTo(charBoxes[i], hov ? C_SEC_BORDER : C_BORDER);
			}
			tintTo(scaleBox, pointIn(mx, my, scaleBox) ? C_SEC_BORDER : C_BORDER);

			// [-] [+]（渐变底常显，hover 提亮层）
			scaleMinusHov.visible = pointIn(mx, my, scaleMinus);
			scalePlusHov.visible = pointIn(mx, my, scalePlus);

			// Flip X：开启=选中底；hover=通用 hover；文字 hover 用强调色
			var flipOn:Bool = characterFile.flipX;
			var flipHov:Bool = pointIn(mx, my, flipHit);
			if (flipOn)
				tintTo(flipBg, C_ROW_SELECTED);
			else
				tintTo(flipBg, flipHov ? C_HOVER_NEUTRAL : 0x00000000);
			flipLbl.color = (flipOn || flipHov) ? C_ACCENT_BAR : C_TEXT_SEC;

			// Reload Char（次级按钮）
			var relHov:Bool = pointIn(mx, my, reloadHit);
			tintTo(reloadBg, relHov ? C_HOVER_NEUTRAL : 0x00000000);
			reloadLbl.color = relHov ? C_ACCENT_BAR : C_TEXT_SEC;
		}
		else if (activePanel == 'hint')
		{
			// Load（次级）
			var loadHov:Bool = pointIn(mx, my, loadHit);
			tintTo(loadBg, loadHov ? C_HOVER_NEUTRAL : 0x00000000);
			loadLbl.color = loadHov ? C_ACCENT_BAR : C_TEXT_SEC;

			// Save（Primary：渐变底常显 + hover 半透明白提亮层，ChartEditor 同款）
			saveHov.visible = pointIn(mx, my, saveHit);
		}

		if (!FlxG.mouse.justPressed)
			return;
		if (barAnimating)
			return;

		// 输入框聚焦中：点击输入框外任意处 → 收起焦点（文本已实时同步，无丢失）
		if (anyInputFocused())
		{
			var onInput:Bool = false;
			if (activePanel == 'char')
			{
				for (h in charBoxHits)
				{
					if (pointIn(mx, my, h))
					{
						onInput = true;
						break;
					}
				}
			}
			if (!onInput)
				blurCharInputs();
		}

		if (onArrow)
		{
			toggleBarFolded();
			return;
		}

		if (hoverBtn >= 0)
		{
			var key:String = barKeys[hoverBtn];
			if (activePanel == key)
				closePanel();
			else
				openPanel(key);
			return;
		}

		if (activePanel != null)
		{
			if (activePanel == 'type')
			{
				for (i in 0...typeHits.length)
				{
					if (pointIn(mx, my, typeHits[i]))
					{
						setType(i);
						return;
					}
				}
			}
			else if (activePanel == 'char')
			{
				// 原生输入框本身处理点击聚焦/光标；这里兜底保证点中自绘框边缘也能聚焦
				for (i in 0...charBoxHits.length)
				{
					if (pointIn(mx, my, charBoxHits[i]))
					{
						focusCharInput(i);
						return;
					}
				}
				if (pointIn(mx, my, scaleMinus))
				{
					scaleStep(-1);
					return;
				}
				if (pointIn(mx, my, scalePlus))
				{
					scaleStep(1);
					return;
				}
				if (pointIn(mx, my, flipHit))
				{
					toggleFlip();
					return;
				}
				if (pointIn(mx, my, reloadHit))
				{
					reloadSelectedCharacter();
					return;
				}
			}
			else if (activePanel == 'hint')
			{
				if (pointIn(mx, my, loadHit))
				{
					loadCharacter();
					return;
				}
				if (pointIn(mx, my, saveHit))
				{
					saveCharacter();
					return;
				}
			}

			// 面板内空白不关；点击面板外 → 关闭
			var insidePanel:Bool = pointIn(mx, my, panelBgs[panelIdxOf(activePanel)]);
			if (!insidePanel)
				closePanel();
			return;
		}
	}

	override function update(elapsed:Float)
	{
		// 输入框内容变化实时写回数据
		updateCharInputTexts();
		updateNewUI();

		var typing:Bool = anyInputFocused();
		if (typing)
		{
			ClientPrefs.toggleVolumeKeys(false);
			// ENTER / ESC / 返回键：收起输入焦点（数据已实时同步）
			if (FlxG.keys.justPressed.ENTER || FlxG.keys.justPressed.ESCAPE #if android || FlxG.android.justPressed.BACK #end)
				blurCharInputs();
		}
		else
		{
			ClientPrefs.toggleVolumeKeys(true);
			if (FlxG.keys.justPressed.ESCAPE #if android || FlxG.android.justPressed.BACK #end || virtualPad.buttonB.justPressed)
			{
				// 面板开着时 ESC/取消键先收起面板，再按一次才退出编辑器
				if (activePanel != null)
					closePanel();
				else
				{
					MusicBeatState.switchState(new developer.editors.MasterEditorMenu());
					FlxG.sound.playMusic(Paths.music('freakyMenu'));
				}
			}

			var shiftMult:Int = 1;
			if (FlxG.keys.pressed.SHIFT || virtualPad.buttonA.pressed)
				shiftMult = 10;

			if (FlxG.keys.justPressed.LEFT || virtualPad.buttonLeft.justPressed)
			{
				characterFile.position[0] += shiftMult;
				updateOffset();
			}
			if (FlxG.keys.justPressed.RIGHT || virtualPad.buttonRight.justPressed)
			{
				characterFile.position[0] -= shiftMult;
				updateOffset();
			}
			if (FlxG.keys.justPressed.UP || virtualPad.buttonUp.justPressed)
			{
				characterFile.position[1] += shiftMult;
				updateOffset();
			}
			if (FlxG.keys.justPressed.DOWN || virtualPad.buttonDown.justPressed)
			{
				characterFile.position[1] -= shiftMult;
				updateOffset();
			}

			if (FlxG.keys.justPressed.SPACE || virtualPad.buttonC.justPressed && curTypeSelected == 1)
			{
				grpWeekCharacters.members[curTypeSelected].animation.play('confirm', true);
			}
		}

		var char:MenuCharacter = grpWeekCharacters.members[1];
		if (char.animation.curAnim != null && char.animation.curAnim.name == 'confirm' && char.animation.curAnim.finished)
		{
			char.animation.play('idle', true);
		}

		super.update(elapsed);
	}

	// ================= 文件读写 =================
	var _file:FileReference = null;

	function loadCharacter()
	{
		var jsonFilter:FileFilter = new FileFilter('JSON', 'json');
		_file = new FileReference();
		_file.addEventListener(#if desktop Event.SELECT #else Event.COMPLETE #end, onLoadComplete);
		_file.addEventListener(Event.CANCEL, onLoadCancel);
		_file.addEventListener(IOErrorEvent.IO_ERROR, onLoadError);
		_file.browse([jsonFilter]);
	}

	function onLoadComplete(_):Void
	{
		_file.removeEventListener(#if desktop Event.SELECT #else Event.COMPLETE #end, onLoadComplete);
		_file.removeEventListener(Event.CANCEL, onLoadCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onLoadError);

		#if sys
		var fullPath:String = null;
		@:privateAccess
		if (_file.__path != null)
			fullPath = _file.__path;

		if (fullPath != null)
		{
			var rawJson:String = File.getContent(fullPath);
			if (rawJson != null)
			{
				var loadedChar:MenuCharacterFile = cast Json.parse(rawJson);
				if (loadedChar.idle_anim != null && loadedChar.confirm_anim != null) // Make sure it's really a character
				{
					var cutName:String = _file.name.substr(0, _file.name.length - 5);
					trace("Successfully loaded file: " + cutName);
					characterFile = loadedChar;
					scaleVal = characterFile.scale;
					charInputs[0].text = characterFile.image;
					charInputs[1].text = characterFile.idle_anim;
					charInputs[2].text = characterFile.confirm_anim;
					cacheCharInputs();
					reloadSelectedCharacter();
					refreshCharPanel();
					updateChip();
					_file = null;
					return;
				}
			}
		}
		_file = null;
		#else
		trace("File couldn't be loaded! You aren't on Desktop, are you?");
		#end
	}

	/**
	 * Called when the save file dialog is cancelled.
	 */
	function onLoadCancel(_):Void
	{
		_file.removeEventListener(#if desktop Event.SELECT #else Event.COMPLETE #end, onLoadComplete);
		_file.removeEventListener(Event.CANCEL, onLoadCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onLoadError);
		_file = null;
		trace("Cancelled file loading.");
	}

	/**
	 * Called if there is an error while saving the gameplay recording.
	 */
	function onLoadError(_):Void
	{
		_file.removeEventListener(#if desktop Event.SELECT #else Event.COMPLETE #end, onLoadComplete);
		_file.removeEventListener(Event.CANCEL, onLoadCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onLoadError);
		_file = null;
		trace("Problem loading file");
	}

	function saveCharacter()
	{
		var data:String = haxe.Json.stringify(characterFile, "\t");
		if (data.length > 0)
		{
			var splittedImage:Array<String> = charInputs[0].text.trim().split('_');
			var characterName:String = splittedImage[splittedImage.length - 1].toLowerCase().replace(' ', '');

			#if mobile
			SUtil.saveContent(characterName, ".json", data);
			#else
			_file = new FileReference();
			_file.addEventListener(#if desktop Event.SELECT #else Event.COMPLETE #end, onSaveComplete);
			_file.addEventListener(Event.CANCEL, onSaveCancel);
			_file.addEventListener(IOErrorEvent.IO_ERROR, onSaveError);
			_file.save(data, characterName + ".json");
			#end
		}
	}

	function onSaveComplete(_):Void
	{
		_file.removeEventListener(#if desktop Event.SELECT #else Event.COMPLETE #end, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
		FlxG.log.notice("Successfully saved file.");
	}

	/**
	 * Called when the save file dialog is cancelled.
	 */
	function onSaveCancel(_):Void
	{
		_file.removeEventListener(#if desktop Event.SELECT #else Event.COMPLETE #end, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
	}

	/**
	 * Called if there is an error while saving the gameplay recording.
	 */
	function onSaveError(_):Void
	{
		_file.removeEventListener(#if desktop Event.SELECT #else Event.COMPLETE #end, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
		FlxG.log.error("Problem saving file");
	}
}
