package developer.editors;

import haxe.Json;

import lime.system.Clipboard;

import openfl.utils.Assets;
import openfl.net.FileReference;
import openfl.events.Event;
import openfl.events.IOErrorEvent;
import openfl.net.FileFilter;

import flixel.addons.ui.FlxInputText;
import flixel.addons.ui.FlxUI9SliceSprite;
import flixel.addons.ui.FlxUI;
import flixel.addons.ui.FlxUICheckBox;
import flixel.addons.ui.FlxUIInputText;
import flixel.addons.ui.FlxUITabMenu;
import flixel.ui.FlxButton;

import general.objects.MenuCharacter;
import general.objects.MenuItem;

import developer.editors.MasterEditorMenu;

import games.objects.HealthIcon;
import games.backend.WeekData;

class WeekEditorState extends MusicBeatState
{
	var txtWeekTitle:FlxText;
	var bgSprite:FlxSprite;
	var lock:FlxSprite;
	var txtTracklist:FlxText;
	var grpWeekCharacters:FlxTypedGroup<MenuCharacter>;
	var weekThing:MenuItem;
	var missingFileText:FlxText;

	var weekFile:WeekFile = null;

	public function new(weekFile:WeekFile = null)
	{
		super();
		this.weekFile = WeekData.createWeekFile();
		if (weekFile != null)
			this.weekFile = weekFile;
		else
			weekFileName = 'week1';
	}

	override function create()
	{
		// 强制刷新语言数据，确保 week 等语言分组被加载（多语言文案）
		general.backend.language.Language.resetData();

		txtWeekTitle = new FlxText(FlxG.width * 0.7, 10, 0, "", 32);
		txtWeekTitle.setFormat(Paths.font(EditorInputStyle.langFontFileName()), 32, FlxColor.WHITE, RIGHT);
		txtWeekTitle.alpha = 0.7;

		var ui_tex = Paths.getSparrowAtlas('campaign_menu_UI_assets');
		var bgYellow:FlxSprite = new FlxSprite(0, 56).makeGraphic(FlxG.width, 386, 0xFFF9CF51);
		bgSprite = new FlxSprite(0, 56);
		bgSprite.antialiasing = ClientPrefs.data.antialiasing;

		weekThing = new MenuItem(0, bgSprite.y + 396, weekFileName);
		weekThing.y += weekThing.height + 20;
		weekThing.antialiasing = ClientPrefs.data.antialiasing;
		add(weekThing);

		var blackBarThingie:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, 56, FlxColor.BLACK);
		add(blackBarThingie);

		grpWeekCharacters = new FlxTypedGroup<MenuCharacter>();

		lock = new FlxSprite();
		lock.frames = ui_tex;
		lock.animation.addByPrefix('lock', 'lock');
		lock.animation.play('lock');
		lock.antialiasing = ClientPrefs.data.antialiasing;
		add(lock);

		missingFileText = new FlxText(0, 0, FlxG.width, "");
		missingFileText.setFormat(Paths.font(EditorInputStyle.langFontFileName()), 24, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		missingFileText.borderSize = 2;
		missingFileText.visible = false;
		add(missingFileText);

		var charArray:Array<String> = weekFile.weekCharacters;
		for (char in 0...3)
		{
			var weekCharacterThing:MenuCharacter = new MenuCharacter((FlxG.width * 0.25) * (1 + char) - 150, charArray[char]);
			weekCharacterThing.y += 70;
			grpWeekCharacters.add(weekCharacterThing);
		}

		add(bgYellow);
		add(bgSprite);
		add(grpWeekCharacters);

		var tracksSprite:FlxSprite = new FlxSprite(FlxG.width * 0.07, bgSprite.y + 435).loadGraphic(Paths.image('Menu_Tracks'));
		tracksSprite.antialiasing = ClientPrefs.data.antialiasing;
		add(tracksSprite);

		txtTracklist = new FlxText(FlxG.width * 0.05, tracksSprite.y + 60, 0, "", 32);
		txtTracklist.alignment = CENTER;
		txtTracklist.font = Paths.font(EditorInputStyle.langFontFileName());
		txtTracklist.color = 0xFFe55777;
		add(txtTracklist);
		add(txtWeekTitle);

		addEditorBox();
		reloadAllShit();

		FlxG.mouse.visible = true;

		super.create();

		// ★ addVirtualPad 必须在 super.create() 之后：MusicBeatState.create 里的
		// initPsychCamera() 会 FlxG.cameras.reset 清掉所有旧相机；移动端“调整各
		// 移动 Editor 键位”开启时，addVirtualPad → EditorMobileKeys 会立刻创建
		// 按键覆盖层及其固定相机，提前创建会被 reset 销毁（scroll 置 null），
		// 之后每次点击 overlay 都会读已销毁相机 → 原生崩溃。
		addVirtualPad(UP_DOWN, B);
	}

	// ============ NovaFlare 深色设计规范色板（AARRGGBB） ============
	static final COL_BG:Int = 0xFF12141A; // 页面底层背景
	static final COL_CARD:Int = 0xFF1C1F28; // 卡片/面板背景
	static final COL_HOVER:Int = 0x147C7FFF; // hover 通用底色（半透明）
	static final COL_BORDER:Int = 0x14FFFFFF; // 分割线/边框（半透明）
	static final COL_TEXT_MAIN:Int = 0xFFF2F3F5; // 主文字
	static final COL_TEXT_SEC:Int = 0xFFC9CDD4; // 次级文字
	static final COL_TEXT_HINT:Int = 0xFF86909C; // 提示文字
	// 一级主菜单
	static final COL_MENU_OFF:Int = 0xFFC9CDD4; // 未选中文字
	static final COL_MENU_SEL1:Int = 0xFF4F46E5; // 选中渐变起
	static final COL_MENU_SEL2:Int = 0xFF7C3AED; // 选中渐变止
	static final COL_MENU_SEL_TEXT:Int = 0xFFFFFFFF; // 选中文字
	static final COL_ACCENT:Int = 0xFFA78BFA; // 装饰条/链接/强调
	// 二级子菜单
	static final COL_SUB_HOVER:Int = 0x0F8B5CF6;
	static final COL_SUB_SEL:Int = 0x268B5CF6;
	static final COL_SUB_SEL_TEXT:Int = 0xFFA78BFA;
	// 主按钮（渐变）
	static final COL_PRIMARY1:Int = 0xFF6366F1;
	static final COL_PRIMARY2:Int = 0xFF8B5CF6;
	static final COL_PRIMARY_H1:Int = 0xFF4F46E5;
	static final COL_PRIMARY_H2:Int = 0xFF7C3AED;
	// 次要按钮
	static final COL_SEC_BORDER:Int = 0x26FFFFFF;
	// 危险按钮
	static final COL_DANGER1:Int = 0xFFEF4444;
	static final COL_DANGER2:Int = 0xFFDC2626;

	/** 生成 左→右 / 上→下 平滑线性渐变 sprite（与 ChartEditorMenuBar.makeGradSprite 同款：逐像素 FlxColor.interpolate） */
	static function makeGradSprite(w:Int, h:Int, c1:Int, c2:Int, horizontal:Bool = true):FlxSprite
	{
		var s:FlxSprite = new FlxSprite().makeGraphic(w, h, FlxColor.WHITE);
		var bd:openfl.display.BitmapData = s.pixels;
		if (bd != null)
		{
			bd.lock();
			for (y in 0...h)
			{
				for (x in 0...w)
				{
					var t:Float = 0;
					if (horizontal && w > 1) t = x / (w - 1);
					else if (h > 1) t = y / (h - 1);
					bd.setPixel32(x, y, FlxColor.interpolate(c1, c2, t));
				}
			}
			bd.unlock();
			s.dirty = true;
		}
		return s;
	}

	// ============ 新 UI：右下角一级菜单按钮 + 弹出面板 ============
	// 设计：新 UI 只做「输入端」（按钮 + 面板显隐），面板内容与逻辑
	// 完全复用旧 UI 的原生控件（FlxUI 组），事件仍走 getEvent。
	// 这样渲染/交互全部走旧 UI 已验证的管线，避免自绘控件崩溃问题。
	//
	// 布局约束：
	//  - 面板不遮挡周目展示背景（bgYellow/bgSprite 底 y≈442）→ 面板顶 ≥ 背景底
	//  - 面板底部贴按钮条上方（向上弹出）
	static final PANEL_W:Int = 360; // 面板宽（行式布局：标签+输入）
	static final BAR_BTN_W:Int = 110; // 一级菜单按钮宽
	static final ARROW_W:Int = 36; // 折叠箭头按钮宽
	static final BAR_H:Int = 36;
	// 面板内容行高
	static final ROW_H:Int = 24;
	// 各面板高度（面板底贴按钮条、顶不遮挡周目背景）
	static final PANEL_H_WEEK:Int = 230;
	static final PANEL_H_OTHER:Int = 158;
	static final PANEL_H_FILE:Int = 152;

	var panelBg:FlxSprite; // 面板背景
	var panelBorder:FlxSprite;
	var tabWeek:FlxUI; // Week 面板内容（原生控件组）
	var tabOther:FlxUI; // Other 面板内容
	var tabFile:FlxUI; // File 面板内容（Load/Freeplay/Save）
	var barKeys:Array<String> = ['week', 'other', 'file']; // 一级菜单 key
	var barTexts:Array<FlxText> = [];
	var barHits:Array<FlxSprite> = [];
	var barSels:Array<FlxSprite> = []; // 选中平滑渐变底（4F46E5→7C3AED，左→右，与 ChartEditor 同款逐像素渐变）
	var barUnderline:FlxSprite; // 选中装饰线（A78BFA 2px，贴选中按钮下缘，同 ChartEditor menuUnderline）
	var barHoverBg:Array<FlxSprite> = []; // hover 半透明底 0x147C7FFF
	var barBg:FlxSprite;
	var barTopLine:FlxSprite;
	var arrowTxt:FlxText; // 折叠箭头
	var arrowHit:FlxSprite;
	var barFolded:Bool = false; // 一级菜单是否折叠（只留箭头）
	var activePanel:String = null; // 当前打开的面板 key；null = 全部关闭

	var blockPressWhileTypingOn:Array<FlxUIInputText> = [];

	/** 面板底部 y（贴按钮条上方） */
	function panelBottomY():Float
	{
		return FlxG.height - BAR_H - 4;
	}

	/** 行式布局：标签 x 与输入框 x/宽（内容区左右各留 12） */
	function rowLabelX():Float
	{
		return panelBg.x + 12;
	}

	function rowInputX():Float
	{
		return panelBg.x + 12 + 150;
	}

	function rowInputW():Int
	{
		return PANEL_W - 24 - 156;
	}

	function addEditorBox()
	{
		// ===== 1) 折叠箭头 + 三个一级菜单按钮条（右下角） =====
		barBg = new FlxSprite().makeGraphic(1, BAR_H, COL_CARD);
		barBg.scrollFactor.set();
		add(barBg);
		barTopLine = new FlxSprite().makeGraphic(1, 1, COL_BORDER);
		barTopLine.scrollFactor.set();
		add(barTopLine);

		// 折叠箭头（Week 左侧）
		arrowTxt = new FlxText(0, 0, ARROW_W, '<', 18);
		arrowTxt.setFormat(Paths.font(EditorInputStyle.langFontFileName()), 18, COL_TEXT_MAIN, CENTER);
		arrowTxt.scrollFactor.set();
		add(arrowTxt);
		arrowHit = new FlxSprite().makeGraphic(ARROW_W, BAR_H, FlxColor.TRANSPARENT);
		arrowHit.scrollFactor.set();
		add(arrowHit);

		for (i in 0...barKeys.length)
		{
			var key:String = barKeys[i];
			var label:String = Language.get('menu_' + key, 'week');
			if (label == 'menu_' + key || label == 'menu_' + key + ' (404)')
				label = key;

			// 选中渐变底（4F46E5→7C3AED 平滑渐变，同 ChartEditor 一级菜单）
			var selBg:FlxSprite = makeGradSprite(BAR_BTN_W, BAR_H, COL_MENU_SEL1, COL_MENU_SEL2, true);
			selBg.scrollFactor.set();
			selBg.visible = false;
			add(selBg);
			barSels.push(selBg);
			// hover 半透明底
			var hov:FlxSprite = new FlxSprite().makeGraphic(BAR_BTN_W, BAR_H, COL_HOVER);
			hov.scrollFactor.set();
			hov.visible = false;
			add(hov);
			barHoverBg.push(hov);

			var txt:FlxText = new FlxText(0, 0, BAR_BTN_W, label, 14);
			txt.setFormat(Paths.font(EditorInputStyle.langFontFileName()), 14, COL_MENU_OFF, CENTER);
			txt.scrollFactor.set();
			add(txt);
			barTexts.push(txt);

			var hit:FlxSprite = new FlxSprite().makeGraphic(BAR_BTN_W, BAR_H, FlxColor.TRANSPARENT);
			hit.scrollFactor.set();
			add(hit);
			barHits.push(hit);
		}
		// 选中装饰线（同 ChartEditor：宽为按钮宽 - 24、2px、A78BFA、贴下缘）
		barUnderline = new FlxSprite().makeGraphic(BAR_BTN_W - 24, 2, COL_ACCENT);
		barUnderline.scrollFactor.set();
		barUnderline.visible = false;
		add(barUnderline);

		layoutBar();

		// ===== 2) 面板背景（贴按钮条上方向上弹出；不遮挡周目背景） =====
		panelBorder = new FlxSprite().makeGraphic(PANEL_W + 2, PANEL_H_WEEK + 2, COL_BORDER);
		panelBorder.scrollFactor.set();
		panelBorder.visible = false;
		add(panelBorder);

		panelBg = new FlxSprite().makeGraphic(PANEL_W, PANEL_H_WEEK, COL_CARD);
		panelBg.scrollFactor.set();
		panelBg.visible = false;
		add(panelBg);

		// ===== 3) 三个原生控件组（旧 UI 内容，行式布局） =====
		addWeekUI();
		addOtherUI();
		addFileUI();
	}

	/** 统一摆放按钮条各元素（折叠/展开时重新布局） */
	function layoutBar():Void
	{
		var barH:Float = FlxG.height - BAR_H;
		var totalW:Int = ARROW_W + BAR_BTN_W * barKeys.length;
		if (barFolded)
			totalW = ARROW_W;
		var barX:Float = FlxG.width - totalW;

		barBg.makeGraphic(totalW, BAR_H, COL_CARD);
		barBg.x = barX;
		barBg.y = barH;
		barTopLine.makeGraphic(totalW, 1, COL_BORDER);
		barTopLine.x = barX;
		barTopLine.y = barH;

		var curX:Float = barX;
		arrowHit.x = curX;
		arrowHit.y = barH;
		arrowTxt.x = curX;
		arrowTxt.y = barH + (BAR_H - arrowTxt.height) / 2;
		arrowTxt.text = barFolded ? '>' : '<';
		arrowTxt.color = COL_TEXT_SEC;
		curX += ARROW_W;

		for (i in 0...barKeys.length)
		{
			var show:Bool = !barFolded;
			barTexts[i].visible = show;
			barHits[i].visible = show;
			barSels[i].visible = show;
			barHoverBg[i].visible = show;
			if (show)
			{
				barSels[i].x = curX;
				barSels[i].y = barH;
				barHoverBg[i].x = curX;
				barHoverBg[i].y = barH;
				barTexts[i].x = curX;
				barTexts[i].y = barH + (BAR_H - barTexts[i].height) / 2;
				barHits[i].x = curX;
				barHits[i].y = barH;
			}
			curX += BAR_BTN_W;
		}
	}

	/** 折叠/展开一级菜单（带条宽收缩 + 文字淡入淡出 + 箭头脉动动画） */
	var barAnimating:Bool = false;

	function toggleBarFolded():Void
	{
		if (barAnimating) return;
		if (!barFolded && activePanel != null)
			closePanel();
		barAnimating = true;
		barFolded = !barFolded;

		var totalW:Int = ARROW_W + BAR_BTN_W * barKeys.length;
		var targetScale:Float = barFolded ? (ARROW_W / totalW) : 1;
		var dur:Float = 0.2;

		// 箭头：字符切换 + 缩放脉动
		arrowTxt.text = barFolded ? '>' : '<';
		arrowTxt.scale.set(1.35, 1.35);
		FlxTween.cancelTweensOf(arrowTxt.scale);
		FlxTween.tween(arrowTxt.scale, {x: 1, y: 1}, dur * 1.5, {ease: FlxEase.backOut});

		// 按钮文字淡入/淡出
		for (i in 0...barTexts.length)
		{
			var t = barTexts[i];
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
		// 按钮点击区：折叠立即失效，展开等动画完成后再生效
		if (barFolded)
		{
			for (h in barHits)
				h.visible = false;
		}

		// 按钮条宽收缩/展开（右缘固定，纯色拉伸无变形；箭头跟随条左缘移动）
		FlxTween.cancelTweensOf(barBg.scale);
		FlxTween.tween(barBg.scale, {x: targetScale}, dur, {
			onUpdate: function(_)
			{
				// ★ State 销毁后 sprite 的 scale/scrollFactor 会被 put 回 FlxPoint 池并置 null，
				// 残留回调访问 barBg.scale.x 会读 null → 原生崩溃；这里统一判空退出
				if (barBg == null || barBg.scale == null || destroyed)
					return;
				barBg.x = FlxG.width - barBg.width * barBg.scale.x;
				if (barTopLine == null || barTopLine.scale == null) return;
				barTopLine.x = barBg.x;
				barTopLine.scale.x = barBg.scale.x;
				if (arrowHit != null) arrowHit.x = barBg.x;
				if (arrowTxt != null) arrowTxt.x = barBg.x;
			},
			onComplete: function(_)
			{
				if (barBg == null || barBg.scale == null || destroyed)
				{
					barAnimating = false;
					return;
				}
				barBg.scale.x = targetScale;
				barBg.x = FlxG.width - barBg.width * barBg.scale.x;
				if (barTopLine != null)
				{
					if (barTopLine.scale != null) barTopLine.scale.x = targetScale;
					barTopLine.x = barBg.x;
				}
				if (arrowHit != null) arrowHit.x = barBg.x;
				if (arrowTxt != null) arrowTxt.x = barBg.x;
				if (!barFolded)
				{
					for (h in barHits)
						h.visible = true;
				}
				barAnimating = false;
			}
		});
	}

	/** State 销毁时取消按钮条相关动画，防止 tween 回调访问已销毁（FlxPoint 已置 null）的 sprite 而崩溃 */
	override function destroy():Void
	{
		FlxTween.cancelTweensOf(arrowTxt.scale);
		FlxTween.cancelTweensOf(barBg.scale);
		for (t in barTexts)
			FlxTween.cancelTweensOf(t);
		super.destroy();
	}

	// ============ 面板开关 ============
	function getPanelHeight(key:String):Int
	{
		switch (key)
		{
			case 'week': return PANEL_H_WEEK;
			case 'other': return PANEL_H_OTHER;
			default: return PANEL_H_FILE;
		}
	}

	function openPanel(key:String):Void
	{
		activePanel = key;
		var h:Int = getPanelHeight(key);
		var px:Float = FlxG.width - PANEL_W - 8;
		var py:Float = panelBottomY() - h; // 底部贴按钮条，向上弹出（不遮挡周目背景）
		panelBorder.makeGraphic(PANEL_W + 2, h + 2, COL_BORDER);
		panelBorder.x = px - 1;
		panelBorder.y = py - 1;
		panelBg.makeGraphic(PANEL_W, h, COL_CARD);
		panelBg.x = px;
		panelBg.y = py;
		panelBorder.visible = true;
		panelBg.visible = true;

		tabWeek.visible = (key == 'week');
		tabOther.visible = (key == 'other');
		tabFile.visible = (key == 'file');
		// ★ 隐藏的面板组必须同时 active=false：否则组内 FlxUIInputText 每帧仍 update，
		// 任意鼠标点击都会触发其聚焦检查（FlxG.mouse.overlaps），
		// 隐藏控件 frame 空态下 calcFrame() 会原生崩溃（历史教训，勿删）
		tabWeek.active = (key == 'week');
		tabOther.active = (key == 'other');
		tabFile.active = (key == 'file');
		if (key == 'week')
		{
			tabWeek.x = px;
			tabWeek.y = py;
			reloadWeekWidgets();
		}
		else if (key == 'other')
		{
			tabOther.x = px;
			tabOther.y = py;
			reloadOtherWidgets();
		}
		else
		{
			tabFile.x = px;
			tabFile.y = py;
		}
	}

	function closePanel():Void
	{
		activePanel = null;
		panelBg.visible = false;
		panelBorder.visible = false;
		tabWeek.visible = false;
		tabOther.visible = false;
		tabFile.visible = false;
	}

	/** 同步 Week 面板控件值（从 reloadAllShit 抽出的赋值部分） */
	function reloadWeekWidgets():Void
	{
		var weekString:String = weekFile.songs[0][0];
		for (i in 1...weekFile.songs.length)
		{
			weekString += ', ' + weekFile.songs[i][0];
		}
		songsInputText.text = weekString;
		backgroundInputText.text = weekFile.weekBackground;
		displayNameInputText.text = weekFile.storyName;
		weekNameInputText.text = weekFile.weekName;
		weekFileInputText.text = weekFileName;
		opponentInputText.text = weekFile.weekCharacters[0];
		boyfriendInputText.text = weekFile.weekCharacters[1];
		girlfriendInputText.text = weekFile.weekCharacters[2];
		hideCheckbox.checked = weekFile.hideStoryMode;
		refreshCheckRowVisuals();
	}

	/** 同步 Other 面板控件值 */
	function reloadOtherWidgets():Void
	{
		weekBeforeInputText.text = weekFile.weekBefore;
		difficultiesInputText.text = (weekFile.difficulties != null) ? weekFile.difficulties : '';
		lockedCheckbox.checked = !weekFile.startUnlocked;
		lock.visible = lockedCheckbox.checked;
		hiddenUntilUnlockCheckbox.checked = weekFile.hiddenUntilUnlocked;
		refreshCheckRowVisuals();
	}

	var songsInputText:FlxUIInputText;
	var backgroundInputText:FlxUIInputText;
	var displayNameInputText:FlxUIInputText;
	var weekNameInputText:FlxUIInputText;
	var weekFileInputText:FlxUIInputText;

	var opponentInputText:FlxUIInputText;
	var boyfriendInputText:FlxUIInputText;
	var girlfriendInputText:FlxUIInputText;

	var hideCheckbox:FlxUICheckBox;

	public static var weekFileName:String = 'week1';

	// File 面板自绘动作行
	var fileRowBgs:Array<FlxSprite> = [];
	var fileRowHits:Array<FlxSprite> = [];
	var fileRowKeys:Array<String> = ['load_week', 'freeplay', 'save_week'];
	var fileRowTxts:Array<FlxText> = [];
	var fileRowHover:Array<FlxSprite> = [];

	var weekBeforeInputText:FlxUIInputText;
	var difficultiesInputText:FlxUIInputText;
	var lockedCheckbox:FlxUICheckBox;
	var hiddenUntilUnlockCheckbox:FlxUICheckBox;

	// ===== 自绘勾选行（文字位置完全可控，FlxUICheckBox 仅作数据源） =====
	var checkRowKeys:Array<String> = []; // 'hide_story' / 'locked' / 'hidden_unlock'
	var checkRowGroups:Array<FlxUI> = [];
	var checkRowChecks:Array<FlxUICheckBox> = [];
	var checkRowBoxes:Array<FlxSprite> = []; // 勾选框填充块
	var checkRowBorders:Array<FlxSprite> = []; // 勾选框外框
	var checkRowLabels:Array<FlxText> = [];
	var checkRowHits:Array<FlxSprite> = [];

	/** 创建一行「勾选框 + 说明文字」（数据源 FlxUICheckBox 不加入场景，仅存数据/回调） */
	function makeCheckRow(group:FlxUI, key:String, labelKey:String, y:Float, check:FlxUICheckBox):Void
	{
		var x0:Float = 12;
		// 外框（18x18）
		var border:FlxSprite = new FlxSprite().makeGraphic(18, 18, 0x33FFFFFF);
		border.x = x0;
		border.y = y + 1;
		group.add(border);
		checkRowBorders.push(border);
		// 填充块（16x16）
		var box:FlxSprite = new FlxSprite().makeGraphic(16, 16, 0xFF12141A);
		box.x = x0 + 1;
		box.y = y + 2;
		group.add(box);
		checkRowBoxes.push(box);

		// 文字（14px，垂直居中于行内）
		var labelText:String = Language.get(labelKey, 'week');
		var lbl:FlxText = new FlxText(x0 + 26, y + 3, PANEL_W - 24 - 30, labelText, 14);
		lbl.setFormat(Paths.font(EditorInputStyle.langFontFileName()), 14, COL_TEXT_MAIN, LEFT);
		group.add(lbl);
		checkRowLabels.push(lbl);

		var hit:FlxSprite = new FlxSprite().makeGraphic(PANEL_W - 24, 24, FlxColor.TRANSPARENT);
		hit.x = x0;
		hit.y = y;
		group.add(hit);
		checkRowHits.push(hit);

		checkRowKeys.push(key);
		checkRowGroups.push(group);
		checkRowChecks.push(check);
	}

	/** 刷新自绘勾选行视觉（checked 状态 + hidden_unlock 的 dim 联动） */
	function refreshCheckRowVisuals():Void
	{
		for (i in 0...checkRowKeys.length)
		{
			var checked:Bool = false;
			try { checked = checkRowChecks[i].checked; } catch (e:Dynamic) {}
			var boxC:Int = checked ? 0xFF8B5CF6 : 0xFF12141A;
			var borderC:Int = checked ? 0xFFA78BFA : 0x33FFFFFF;
			checkRowBoxes[i].makeGraphic(16, 16, boxC);
			checkRowBorders[i].makeGraphic(18, 18, borderC);

			// 「解锁前保持隐藏」仅在「开始时锁定」勾选时有效（变暗）
			var dim:Float = 1;
			if (checkRowKeys[i] == 'hidden_unlock')
				dim = (lockedCheckbox != null && lockedCheckbox.checked) ? 1 : 0.4;
			checkRowLabels[i].alpha = dim;
			checkRowBoxes[i].alpha = dim;
			checkRowBorders[i].alpha = dim;
			checkRowHits[i].alpha = dim;
		}
	}

	/** 点击自绘勾选行：翻转数据源并触发回调 */
	function toggleCheckRow(idx:Int):Void
	{
		var check = checkRowChecks[idx];
		if (check == null) return;
		var before:Bool = false;
		try { before = check.checked; } catch (e:Dynamic) {}
		try { check.checked = !before; } catch (e:Dynamic) {}
		try
		{
			var cb:Dynamic = Reflect.field(check, 'callback');
			if (cb != null) cb();
		}
		catch (e:Dynamic) {}
		refreshCheckRowVisuals();
	}

	// ============ 移动端软键盘 ============

	/** 启用/禁用系统文本输入（软键盘）。flixel-ui 的 FlxInputText 只在 #if mobile
	 *  构建里弹键盘；这里按 PsychUIInputText 的做法在聚焦回调里显式启用，
	 *  触屏模拟（Windows + 移动设置）与真移动端均生效。 */
	public static function setTextInputEnabled(on:Bool):Void
	{
		try
		{
			var win:Dynamic = (FlxG.stage != null) ? Reflect.field(FlxG.stage, 'window') : null;
			if (win != null) win.textInputEnabled = on;
		}
		catch (e:Dynamic) {}
	}

	/** 给输入框挂聚焦回调：点击聚焦 → 弹软键盘；失焦 → 收回。 */
	static function bindSoftKeyboard(w:FlxUIInputText):Void
	{
		if (w == null) return;
		try
		{
			w.focusGained = function()
			{
				setTextInputEnabled(true);
			};
			w.focusLost = function()
			{
				setTextInputEnabled(false);
			};
		}
		catch (e:Dynamic) {}
	}

	function addWeekUI()
	{
		tabWeek = new FlxUI(null, this);
		tabWeek.name = "Week";
		var x0:Float = 12;
		var lblX:Float = x0;
		var inputX:Float = x0 + 144;
		var inputW:Int = PANEL_W - 24 - 148;

		var rows:Array<String> = ['w_songs', 'w_opponent', 'w_boyfriend', 'w_girlfriend', 'w_background', 'w_display_name', 'w_week_name', 'w_week_file'];
		var inputs:Array<FlxUIInputText> = [];

		// 行输入框统一灰底白字（与编谱/角色/舞台编辑器一致）
		function makeRowInput(y:Float):FlxUIInputText
		{
			var t:FlxUIInputText = new FlxUIInputText(inputX, y, inputW, '', 12, 0xFFFFFFFF, EditorInputStyle.BG);
			EditorInputStyle.apply(t); // 修复白色文字早退问题 + 统一边框
			bindSoftKeyboard(t); // 移动端/触屏：聚焦时启用系统软键盘
			return t;
		}

		songsInputText = makeRowInput(10);
		blockPressWhileTypingOn.push(songsInputText);
		inputs.push(songsInputText);

		opponentInputText = makeRowInput(10 + ROW_H);
		blockPressWhileTypingOn.push(opponentInputText);
		inputs.push(opponentInputText);

		boyfriendInputText = makeRowInput(10 + ROW_H * 2);
		blockPressWhileTypingOn.push(boyfriendInputText);
		inputs.push(boyfriendInputText);

		girlfriendInputText = makeRowInput(10 + ROW_H * 3);
		blockPressWhileTypingOn.push(girlfriendInputText);
		inputs.push(girlfriendInputText);

		backgroundInputText = makeRowInput(10 + ROW_H * 4);
		blockPressWhileTypingOn.push(backgroundInputText);
		inputs.push(backgroundInputText);

		displayNameInputText = makeRowInput(10 + ROW_H * 5);
		blockPressWhileTypingOn.push(displayNameInputText);
		inputs.push(displayNameInputText);

		weekNameInputText = makeRowInput(10 + ROW_H * 6);
		blockPressWhileTypingOn.push(weekNameInputText);
		inputs.push(weekNameInputText);

		weekFileInputText = makeRowInput(10 + ROW_H * 7);
		blockPressWhileTypingOn.push(weekFileInputText);
		inputs.push(weekFileInputText);
		reloadWeekThing();

		// 自绘勾选行（数据源 hideCheckbox 仅存数据，不渲染）
		hideCheckbox = new FlxUICheckBox(0, 0, null, null, '', 100);
		hideCheckbox.callback = function()
		{
			weekFile.hideStoryMode = hideCheckbox.checked;
		};
		makeCheckRow(tabWeek, 'hide_story', 'w_hide_story', 10 + ROW_H * 8 + 2, hideCheckbox);

		// 行式标签：左标签（宽 140）+ 右侧输入框
		for (i in 0...rows.length)
		{
			var labelText:String = Language.get(rows[i], 'week') + ':';
			var lbl:FlxText = new FlxText(lblX, 10 + ROW_H * i + 3, 140, labelText, 12);
			lbl.setFormat(Paths.font(EditorInputStyle.langFontFileName()), 12, COL_TEXT_SEC, LEFT);
			tabWeek.add(lbl);
			tabWeek.add(inputs[i]);
		}
		add(tabWeek);
		tabWeek.visible = false;
	}

	function addOtherUI()
	{
		tabOther = new FlxUI(null, this);
		tabOther.name = "Other";

		var x0:Float = 12;

		// 自绘勾选行（数据源仅存数据，不渲染；文字位置由 makeCheckRow 精确控制）
		lockedCheckbox = new FlxUICheckBox(0, 0, null, null, '', 100);
		lockedCheckbox.callback = function()
		{
			weekFile.startUnlocked = !lockedCheckbox.checked;
			lock.visible = lockedCheckbox.checked;
		};
		makeCheckRow(tabOther, 'locked', 'w_locked', 10, lockedCheckbox);

		hiddenUntilUnlockCheckbox = new FlxUICheckBox(0, 0, null, null, '', 100);
		hiddenUntilUnlockCheckbox.callback = function()
		{
			weekFile.hiddenUntilUnlocked = hiddenUntilUnlockCheckbox.checked;
		};
		makeCheckRow(tabOther, 'hidden_unlock', 'w_hidden_unlock', 34, hiddenUntilUnlockCheckbox);

		weekBeforeInputText = new FlxUIInputText(x0 + 144, 66, PANEL_W - 24 - 148, '', 12, 0xFFFFFFFF, EditorInputStyle.BG);
		EditorInputStyle.apply(weekBeforeInputText);
		bindSoftKeyboard(weekBeforeInputText);
		blockPressWhileTypingOn.push(weekBeforeInputText);

		difficultiesInputText = new FlxUIInputText(x0 + 144, 90, PANEL_W - 24 - 148, '', 12, 0xFFFFFFFF, EditorInputStyle.BG);
		EditorInputStyle.apply(difficultiesInputText);
		bindSoftKeyboard(difficultiesInputText);
		blockPressWhileTypingOn.push(difficultiesInputText);

		var lblBefore:FlxText = new FlxText(x0, 66 + 3, 140, Language.get('w_week_before', 'week') + ':', 12);
		lblBefore.setFormat(Paths.font(EditorInputStyle.langFontFileName()), 12, COL_TEXT_SEC, LEFT);
		tabOther.add(lblBefore);
		var lblDiff:FlxText = new FlxText(x0, 90 + 3, 140, Language.get('w_difficulties', 'week') + ':', 12);
		lblDiff.setFormat(Paths.font(EditorInputStyle.langFontFileName()), 12, COL_TEXT_SEC, LEFT);
		tabOther.add(lblDiff);
		var lblHint:FlxText = new FlxText(x0, 118, PANEL_W - 24, Language.get('w_difficulties_hint', 'week'), 11);
		lblHint.setFormat(Paths.font(EditorInputStyle.langFontFileName()), 11, COL_TEXT_HINT, LEFT);
		lblHint.wordWrap = true;
		tabOther.add(lblHint);
		tabOther.add(weekBeforeInputText);
		tabOther.add(difficultiesInputText);
		add(tabOther);
		tabOther.visible = false;
	}

	/** File 面板：Load Week / Freeplay / Save Week（次要按钮风格行：暗底+半透明边框+hover 强调） */
	function addFileUI():Void
	{
		tabFile = new FlxUI(null, this);
		tabFile.name = "File";

		var rowW:Int = PANEL_W - 24;
		var rowX:Float = 12;
		var rowH:Int = 40;
		var ys:Array<Float> = [10, 56, 102];

		for (i in 0...3)
		{
			var key:String = fileRowKeys[i];
			var labelKey:String = 'item_' + key;
			var label:String = Language.get(labelKey, 'week');
			if (label == labelKey || label == labelKey + ' (404)')
				label = key;
			var isDanger:Bool = (key == 'save_week' || key == 'load_week') && false; // 全部按次要按钮

			// 模拟边框（1px 半透明白，垫底）
			var border:FlxSprite = new FlxSprite().makeGraphic(rowW, rowH, COL_SEC_BORDER);
			border.x = rowX;
			border.y = ys[i];
			tabFile.add(border);
			// 底（页面背景色，内嵌于卡片）
			var bg:FlxSprite = new FlxSprite().makeGraphic(rowW - 2, rowH - 2, COL_BG);
			bg.x = rowX + 1;
			bg.y = ys[i] + 1;
			tabFile.add(bg);
			fileRowBgs.push(bg);
			// hover 半透明底
			var hov:FlxSprite = new FlxSprite().makeGraphic(rowW - 2, rowH - 2, COL_HOVER);
			hov.x = rowX + 1;
			hov.y = ys[i] + 1;
			hov.visible = false;
			tabFile.add(hov);
			fileRowHover.push(hov);

			var txt:FlxText = new FlxText(rowX, 0, rowW, label, 15);
			txt.setFormat(Paths.font(EditorInputStyle.langFontFileName()), 15, COL_TEXT_MAIN, CENTER);
			txt.y = ys[i] + (rowH - txt.height) / 2;
			tabFile.add(txt);
			fileRowTxts.push(txt);

			var hit:FlxSprite = new FlxSprite().makeGraphic(rowW, rowH, FlxColor.TRANSPARENT);
			hit.x = rowX;
			hit.y = ys[i];
			tabFile.add(hit);
			fileRowHits.push(hit);
		}

		add(tabFile);
		tabFile.visible = false;
	}

	/** File 面板动作行点击（在 updateMenuBar 中命中后调用） */
	function onFileRowClick(key:String):Void
	{
		closePanel();
		switch (key)
		{
			case 'load_week':
				loadWeek();
			case 'freeplay':
				MusicBeatState.switchState(new WeekEditorFreeplayState(weekFile));
			case 'save_week':
				saveWeek(weekFile);
		}
	}

	// Used on onCreate and when you load a week
	function reloadAllShit()
	{
		reloadWeekWidgets();
		reloadOtherWidgets();

		reloadBG();
		reloadWeekThing();
		updateText();
	}

	function updateText()
	{
		for (i in 0...grpWeekCharacters.length)
		{
			grpWeekCharacters.members[i].changeCharacter(weekFile.weekCharacters[i]);
		}

		var stringThing:Array<String> = [];
		for (i in 0...weekFile.songs.length)
		{
			stringThing.push(weekFile.songs[i][0]);
		}

		txtTracklist.text = '';
		for (i in 0...stringThing.length)
		{
			txtTracklist.text += stringThing[i] + '\n';
		}

		txtTracklist.text = txtTracklist.text.toUpperCase();

		txtTracklist.screenCenter(X);
		txtTracklist.x -= FlxG.width * 0.35;

		txtWeekTitle.text = weekFile.storyName.toUpperCase();
		txtWeekTitle.x = FlxG.width - (txtWeekTitle.width + 10);
	}

	function reloadBG()
	{
		bgSprite.visible = true;
		var assetName:String = weekFile.weekBackground;

		var isMissing:Bool = true;
		if (assetName != null && assetName.length > 0)
		{
			if (#if MODS_ALLOWED FileSystem.exists(Paths.modsImages('menubackgrounds/menu_' +
				assetName)) || #end Assets.exists(Paths.getPath('images/menubackgrounds/menu_'
				+ assetName + '.png', IMAGE), IMAGE))
			{
				bgSprite.loadGraphic(Paths.image('menubackgrounds/menu_' + assetName));
				isMissing = false;
			}
		}

		if (isMissing)
		{
			bgSprite.visible = false;
		}
	}

	function reloadWeekThing()
	{
		weekThing.visible = true;
		missingFileText.visible = false;
		var assetName:String = weekFileInputText.text.trim();

		var isMissing:Bool = true;
		if (assetName != null && assetName.length > 0)
		{
			if (#if MODS_ALLOWED FileSystem.exists(Paths.modsImages('storymenu/' + assetName)) || #end Assets.exists(Paths.getPath('images/storymenu/'
				+ assetName + '.png', IMAGE), IMAGE))
			{
				weekThing.loadGraphic(Paths.image('storymenu/' + assetName));
				isMissing = false;
			}
		}

		if (isMissing)
		{
			weekThing.visible = false;
			missingFileText.visible = true;
			missingFileText.text = 'MISSING FILE: images/storymenu/' + assetName + '.png';
		}
		recalculateStuffPosition();

		#if DISCORD_ALLOWED
		// Updating Discord Rich Presence
		DiscordClient.changePresence("Week Editor", "Editting: " + weekFileName);
		#end
	}

	override function getEvent(id:String, sender:Dynamic, data:Dynamic, ?params:Array<Dynamic>)
	{
		if (id == FlxUIInputText.CHANGE_EVENT && (sender is FlxUIInputText))
		{
			if (sender == weekFileInputText)
			{
				weekFileName = weekFileInputText.text.trim();
				reloadWeekThing();
			}
			else if (sender == opponentInputText || sender == boyfriendInputText || sender == girlfriendInputText)
			{
				weekFile.weekCharacters[0] = opponentInputText.text.trim();
				weekFile.weekCharacters[1] = boyfriendInputText.text.trim();
				weekFile.weekCharacters[2] = girlfriendInputText.text.trim();
				updateText();
			}
			else if (sender == backgroundInputText)
			{
				weekFile.weekBackground = backgroundInputText.text.trim();
				reloadBG();
			}
			else if (sender == displayNameInputText)
			{
				weekFile.storyName = displayNameInputText.text.trim();
				updateText();
			}
			else if (sender == weekNameInputText)
			{
				weekFile.weekName = weekNameInputText.text.trim();
			}
			else if (sender == songsInputText)
			{
				var splittedText:Array<String> = songsInputText.text.trim().split(',');
				for (i in 0...splittedText.length)
				{
					splittedText[i] = splittedText[i].trim();
				}

				while (splittedText.length < weekFile.songs.length)
				{
					weekFile.songs.pop();
				}

				for (i in 0...splittedText.length)
				{
					if (i >= weekFile.songs.length)
					{ // Add new song
						weekFile.songs.push([splittedText[i], 'dad', [146, 113, 253]]);
					}
					else
					{ // Edit song
						weekFile.songs[i][0] = splittedText[i];
						if (weekFile.songs[i][1] == null || weekFile.songs[i][1])
						{
							weekFile.songs[i][1] = 'dad';
							weekFile.songs[i][2] = [146, 113, 253];
						}
					}
				}
				updateText();
			}
			else if (sender == weekBeforeInputText)
			{
				weekFile.weekBefore = weekBeforeInputText.text.trim();
			}
			else if (sender == difficultiesInputText)
			{
				weekFile.difficulties = difficultiesInputText.text.trim();
			}
		}
	}

	override function update(elapsed:Float)
	{
		if (loadedWeek != null)
		{
			weekFile = loadedWeek;
			loadedWeek = null;

			reloadAllShit();
		}

		// 一级菜单按钮点击/面板开关（不受输入框聚焦阻塞，保证编辑中也能切面板）
		updateMenuBar(elapsed);

		var blockInput:Bool = false;
		for (inputText in blockPressWhileTypingOn)
		{
			if (inputText.hasFocus)
			{
				ClientPrefs.toggleVolumeKeys(false);
				blockInput = true;

				if (FlxG.keys.justPressed.ENTER)
				{
					inputText.hasFocus = false;
					setTextInputEnabled(false); // 程序失焦不走 focusLost，手动收回软键盘
				}
				break;
			}
		}

		if (!blockInput)
		{
			ClientPrefs.toggleVolumeKeys(true);
			if (FlxG.keys.justPressed.ESCAPE || virtualPad.buttonB.justPressed)
			{
				// 面板打开时 ESC/取消键先收起面板，再按一次才退出编辑器
				if (activePanel != null)
					closePanel();
				else
				{
					MusicBeatState.switchState(new MasterEditorMenu());
					FlxG.sound.playMusic(Paths.music('freakyMenu'));
				}
			}
		}

		super.update(elapsed);

		lock.y = weekThing.y;
		missingFileText.y = weekThing.y + 36;
	}

	/** 右下角一级菜单：箭头折叠 / 按钮 hover·点击 / File 行 hover·点击 / 点面板外关闭 */
	function updateMenuBar(elapsed:Float):Void
	{
		if (barHits.length < 1) return;
		var mx:Float = FlxG.mouse.viewX;
		var my:Float = FlxG.mouse.viewY;

		// 折叠箭头 hover 高亮
		var onArrow:Bool = (mx >= arrowHit.x && mx <= arrowHit.x + arrowHit.width
			&& my >= arrowHit.y && my <= arrowHit.y + arrowHit.height);
		arrowTxt.color = onArrow ? 0xFFFFFFFF : COL_TEXT_HINT;

		var hoverBtn:Int = -1;
		for (i in 0...barHits.length)
		{
			var h = barHits[i];
			if (!h.visible) continue; // 折叠时按钮隐藏，不参与判定
			if (mx >= h.x && mx <= h.x + h.width && my >= h.y && my <= h.y + h.height)
			{
				hoverBtn = i;
				break;
			}
		}

		// 按钮视觉：选中 = 渐变底(4F46E5→7C3AED)+白字；hover(未选中) = 半透明底+白字
		var selIdx:Int = -1;
		for (i in 0...barTexts.length)
		{
			var isActive = (activePanel != null && barKeys[i] == activePanel);
			var isHover = (i == hoverBtn && !isActive);
			if (isActive) selIdx = i;
			barSels[i].visible = isActive;
			barHoverBg[i].visible = isHover;
			barTexts[i].color = (isActive || isHover) ? COL_MENU_SEL_TEXT : COL_MENU_OFF;
		}
		// 选中装饰线跟随（同 ChartEditor：x = 按钮 x + 12，贴下缘）
		if (barUnderline != null)
		{
			if (selIdx >= 0 && barSels[selIdx].visible)
			{
				barUnderline.x = barSels[selIdx].x + 12;
				barUnderline.y = barSels[selIdx].y + BAR_H - 2;
				barUnderline.visible = true;
			}
			else
				barUnderline.visible = false;
		}

		// File 面板动作行 hover 高亮（hover 底色覆盖层 + 文字换强调色）
		if (activePanel == 'file')
		{
			for (i in 0...fileRowBgs.length)
			{
				var hit = fileRowHits[i];
				var hov:Bool = (mx >= hit.x && mx <= hit.x + hit.width && my >= hit.y && my <= hit.y + hit.height);
				if (fileRowHover[i] != null)
					fileRowHover[i].visible = hov;
				if (fileRowTxts[i] != null)
					fileRowTxts[i].color = hov ? COL_ACCENT : COL_TEXT_MAIN;
			}
		}

		if (FlxG.mouse.justPressed)
		{
			if (onArrow)
			{
				toggleBarFolded();
			}
			else if (hoverBtn >= 0)
			{
				var key:String = barKeys[hoverBtn];
				if (activePanel == key)
					closePanel();
				else
					openPanel(key);
			}
			else if (activePanel != null)
			{
				// 自绘勾选行（仅命中其所属组当前可见的行）
				var checkHandled:Bool = false;
				for (i in 0...checkRowHits.length)
				{
					var hit = checkRowHits[i];
					var g = checkRowGroups[i];
					if (g == null || !g.visible) continue;
					if (mx >= hit.x && mx <= hit.x + hit.width && my >= hit.y && my <= hit.y + hit.height)
					{
						toggleCheckRow(i);
						checkHandled = true;
						break;
					}
				}
				// File 面板动作行优先于「点面板外关闭」
				var fileRowHandled:Bool = false;
				if (!checkHandled && activePanel == 'file')
				{
					for (i in 0...fileRowHits.length)
					{
						var hit = fileRowHits[i];
						if (mx >= hit.x && mx <= hit.x + hit.width && my >= hit.y && my <= hit.y + hit.height)
						{
							onFileRowClick(fileRowKeys[i]);
							fileRowHandled = true;
							break;
						}
					}
				}
				if (!checkHandled && !fileRowHandled)
				{
					// 面板开着：点面板区域外 → 关闭（面板内交给原生控件自己处理）
					var inside:Bool = (mx >= panelBorder.x && mx <= panelBorder.x + panelBorder.width
						&& my >= panelBorder.y && my <= panelBorder.y + panelBorder.height);
					if (!inside)
						closePanel();
				}
			}
		}
	}

	function recalculateStuffPosition()
	{
		weekThing.screenCenter(X);
		lock.x = weekThing.width + 10 + weekThing.x;
	}

	private static var _file:FileReference;

	public static function loadWeek()
	{
		var jsonFilter:FileFilter = new FileFilter('JSON', 'json');
		_file = new FileReference();
		_file.addEventListener(#if desktop Event.SELECT #else Event.COMPLETE #end, onLoadComplete);
		_file.addEventListener(Event.CANCEL, onLoadCancel);
		_file.addEventListener(IOErrorEvent.IO_ERROR, onLoadError);
		_file.browse([jsonFilter]);
	}

	public static var loadedWeek:WeekFile = null;
	public static var loadError:Bool = false;

	private static function onLoadComplete(_):Void
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
				loadedWeek = cast Json.parse(rawJson);
				if (loadedWeek.weekCharacters != null && loadedWeek.weekName != null) // Make sure it's really a week
				{
					var cutName:String = _file.name.substr(0, _file.name.length - 5);
					trace("Successfully loaded file: " + cutName);
					loadError = false;

					weekFileName = cutName;
					_file = null;
					return;
				}
			}
		}
		loadError = true;
		loadedWeek = null;
		_file = null;
		#else
		trace("File couldn't be loaded! You aren't on Desktop, are you?");
		#end
	}

	/**
	 * Called when the save file dialog is cancelled.
	 */
	private static function onLoadCancel(_):Void
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
	private static function onLoadError(_):Void
	{
		_file.removeEventListener(#if desktop Event.SELECT #else Event.COMPLETE #end, onLoadComplete);
		_file.removeEventListener(Event.CANCEL, onLoadCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onLoadError);
		_file = null;
		trace("Problem loading file");
	}

	public static function saveWeek(weekFile:WeekFile)
	{
		var data:String = haxe.Json.stringify(weekFile, "\t");
		if (data.length > 0)
		{
			#if mobile
			SUtil.saveContent(weekFileName, ".json", data);
			#else
			_file = new FileReference();
			_file.addEventListener(#if desktop Event.SELECT #else Event.COMPLETE #end, onSaveComplete);
			_file.addEventListener(Event.CANCEL, onSaveCancel);
			_file.addEventListener(IOErrorEvent.IO_ERROR, onSaveError);
			_file.save(data, weekFileName + ".json");
			#end
		}
	}

	private static function onSaveComplete(_):Void
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
	private static function onSaveCancel(_):Void
	{
		_file.removeEventListener(#if desktop Event.SELECT #else Event.COMPLETE #end, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
	}

	/**
	 * Called if there is an error while saving the gameplay recording.
	 */
	private static function onSaveError(_):Void
	{
		_file.removeEventListener(#if desktop Event.SELECT #else Event.COMPLETE #end, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
		FlxG.log.error("Problem saving file");
	}
}

class WeekEditorFreeplayState extends MusicBeatState
{
	// ============ NovaFlare 深色设计规范色板（AARRGGBB，与 WeekEditorState 同值） ============
	static final COL_BG:Int = 0xFF12141A; // 页面底层背景
	static final COL_CARD:Int = 0xFF1C1F28; // 卡片/面板背景
	static final COL_HOVER:Int = 0x147C7FFF; // hover 通用底色（半透明）
	static final COL_BORDER:Int = 0x14FFFFFF; // 分割线/边框（半透明）
	static final COL_TEXT_MAIN:Int = 0xFFF2F3F5; // 主文字
	static final COL_TEXT_SEC:Int = 0xFFC9CDD4; // 次级文字
	static final COL_TEXT_HINT:Int = 0xFF86909C; // 提示文字
	// 一级主菜单
	static final COL_MENU_OFF:Int = 0xFFC9CDD4; // 未选中文字
	static final COL_MENU_SEL1:Int = 0xFF4F46E5; // 选中渐变起
	static final COL_MENU_SEL2:Int = 0xFF7C3AED; // 选中渐变止
	static final COL_MENU_SEL_TEXT:Int = 0xFFFFFFFF; // 选中文字
	static final COL_ACCENT:Int = 0xFFA78BFA; // 装饰条/链接/强调
	// 二级子菜单
	static final COL_SUB_HOVER:Int = 0x0F8B5CF6;
	static final COL_SUB_SEL:Int = 0x268B5CF6;
	static final COL_SUB_SEL_TEXT:Int = 0xFFA78BFA;
	// 主按钮（渐变）
	static final COL_PRIMARY1:Int = 0xFF6366F1;
	static final COL_PRIMARY2:Int = 0xFF8B5CF6;
	static final COL_PRIMARY_H1:Int = 0xFF4F46E5;
	static final COL_PRIMARY_H2:Int = 0xFF7C3AED;
	// 次要按钮
	static final COL_SEC_BORDER:Int = 0x26FFFFFF;
	// 危险按钮
	static final COL_DANGER1:Int = 0xFFEF4444;
	static final COL_DANGER2:Int = 0xFFDC2626;

	var weekFile:WeekFile = null;

	public function new(weekFile:WeekFile = null)
	{
		super();
		this.weekFile = WeekData.createWeekFile();
		if (weekFile != null)
			this.weekFile = weekFile;
	}

	var bg:FlxSprite;

	// ===== 右侧歌曲卡片列表（直接使用原版 SongRect 的复制件 WeekSongRect） =====
	var songCards:Array<WeekSongRect> = [];
	var cardCenterY:Float = 300;
	var scrollPos:Float = 0; // 列表滚动位置（缓动）
	var scrollTarget:Float = 0;
	var curSelected = 0;

	override function create()
	{
		bg = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.antialiasing = ClientPrefs.data.antialiasing;
		bg.color = FlxColor.WHITE;
		add(bg);

		buildSongCards();
		scrollTarget = cardCenterY - WeekSongRect.fixHeight * 0.5;
		scrollPos = scrollTarget;

		addEditorBox();
		changeSelection();
		super.create();

		// ★ Freeplay 模式不再创建移动端虚拟按键（上/下/B 三个按钮已按需求移除）
	}

	/** 创建歌曲卡片（原版 SongRect 结构：缩略底 + 渐变 + 图标 + 歌名/曲师） */
	function buildSongCards():Void
	{
		for (i in 0...weekFile.songs.length)
		{
			var songArr:Array<Dynamic> = weekFile.songs[i];
			var colors:Array<Int> = (songArr[2] != null && songArr[2].length >= 3) ? songArr[2] : [146, 113, 253];
			var muscan:String = (songArr.length > 3 && songArr[3] != null) ? Std.string(songArr[3]) : 'N/A';
			var charter:Array<String> = (songArr.length > 4 && songArr[4] != null) ? cast songArr[4] : ['N/A', 'N/A', 'N/A'];
			var card:WeekSongRect = new WeekSongRect(Std.string(songArr[0]), Std.string(songArr[1]), muscan, charter, colors);
			card.id = i;
			card.scrollFactor.set();
			card.onCardClick = function(clickedId:Int)
			{
				if (colorInputActive != null)
					closeColorInputOverlay();
				if (curSelected != clickedId)
					changeSelection(clickedId - curSelected);
			};
			add(card);
			songCards.push(card);
		}
	}

	/** 每帧：列表平滑滚动 + 卡片 moveY/calcX（同原版 songMoveEvent 语义）+ 选中态 */
	function updateSongCards(elapsed:Float):Void
	{
		var step:Float = WeekSongRect.fixHeight * 0.97;
		scrollPos = FlxMath.lerp(scrollTarget, scrollPos, Math.exp(-elapsed * 8));
		if (Math.abs(scrollTarget - scrollPos) < 0.05)
			scrollPos = scrollTarget;

		for (i in 0...songCards.length)
		{
			var card = songCards[i];
			var y:Float = scrollPos + i * step;
			card.visible = (y > -WeekSongRect.fixHeight * 2 && y < FlxG.height + WeekSongRect.fixHeight);
			if (!card.visible) continue;
			card.frameTime = elapsed * 8;
			card.moveY(y);
			card.calcX();
			card.onFocus = (i == curSelected);
		}
	}

	// ============ 左下角编辑面板（无分级，内容 = 旧 Freeplay UI） ============
	static final FP_W:Int = 360;
	var fpBg:FlxSprite;
	var fpBorder:FlxSprite;
	var fpPanel:FlxUI; // 原生控件组（输入/步进器/勾选数据源等）
	var blockPressWhileTypingOn:Array<FlxUIInputText> = [];

	// 自绘 RGB 通道步进器（替代原生 FlxUINumericStepper）
	var rgbVals:Array<Int> = [255, 255, 255];
	var rgbChannelTxts:Array<FlxText> = []; // R/G/B 标签
	var rgbValTxts:Array<FlxText> = [];
	var rgbMinusHits:Array<FlxSprite> = [];
	var rgbPlusHits:Array<FlxSprite> = [];
	var rgbMinusTxts:Array<FlxText> = [];
	var rgbPlusTxts:Array<FlxText> = [];

	/** 自绘 RGB 步进器（列：通道字母 [-] 数值 [+]） */
	function buildRgbSteppers(x0:Float):Void
	{
		var channels:Array<String> = ['R', 'G', 'B'];
		var y:Float = 48;
		for (i in 0...3)
		{
			var colX:Float = x0 + i * 84;
			var lbl:FlxText = new FlxText(colX, y + 2, 16, channels[i], 13);
			lbl.setFormat(Paths.font(EditorInputStyle.langFontFileName()), 13, COL_TEXT_SEC, CENTER);
			fpPanel.add(lbl);
			rgbChannelTxts.push(lbl);

			// [-] 钮
			var minusBorder:FlxSprite = new FlxSprite().makeGraphic(18, 20, COL_SEC_BORDER);
			minusBorder.x = colX + 16;
			minusBorder.y = y;
			fpPanel.add(minusBorder);
			var minusBg:FlxSprite = new FlxSprite().makeGraphic(16, 18, COL_BG);
			minusBg.x = colX + 17;
			minusBg.y = y + 1;
			fpPanel.add(minusBg);
			var minusTxt:FlxText = new FlxText(colX + 16, 0, 18, '-', 13);
			minusTxt.setFormat(Paths.font(EditorInputStyle.langFontFileName()), 13, COL_TEXT_MAIN, CENTER);
			minusTxt.y = y + (20 - minusTxt.height) / 2;
			fpPanel.add(minusTxt);
			rgbMinusTxts.push(minusTxt);
			var minusHit:FlxSprite = new FlxSprite().makeGraphic(18, 20, FlxColor.TRANSPARENT);
			minusHit.x = colX + 16;
			minusHit.y = y;
			fpPanel.add(minusHit);
			rgbMinusHits.push(minusHit);

			// 数值
			var valTxt:FlxText = new FlxText(colX + 36, 0, 30, '255', 12);
			valTxt.setFormat(Paths.font(EditorInputStyle.langFontFileName()), 12, COL_TEXT_MAIN, CENTER);
			valTxt.y = y + (20 - valTxt.height) / 2;
			fpPanel.add(valTxt);
			rgbValTxts.push(valTxt);

			// [+] 钮
			var plusBorder:FlxSprite = new FlxSprite().makeGraphic(18, 20, COL_SEC_BORDER);
			plusBorder.x = colX + 68;
			plusBorder.y = y;
			fpPanel.add(plusBorder);
			var plusBg:FlxSprite = new FlxSprite().makeGraphic(16, 18, COL_BG);
			plusBg.x = colX + 69;
			plusBg.y = y + 1;
			fpPanel.add(plusBg);
			var plusTxt:FlxText = new FlxText(colX + 68, 0, 18, '+', 13);
			plusTxt.setFormat(Paths.font(EditorInputStyle.langFontFileName()), 13, COL_TEXT_MAIN, CENTER);
			plusTxt.y = y + (20 - plusTxt.height) / 2;
			fpPanel.add(plusTxt);
			rgbPlusTxts.push(plusTxt);
			var plusHit:FlxSprite = new FlxSprite().makeGraphic(18, 20, FlxColor.TRANSPARENT);
			plusHit.x = colX + 68;
			plusHit.y = y;
			fpPanel.add(plusHit);
			rgbPlusHits.push(plusHit);
		}
		refreshRgbSteppers();
	}

	/** 数值文本刷新 */
	function refreshRgbSteppers():Void
	{
		for (i in 0...3)
		{
			if (rgbValTxts[i] != null)
				rgbValTxts[i].text = Std.string(rgbVals[i]);
		}
	}

	/** 微调通道值（clamp 0-255）并全链路刷新 */
	function nudgeRgbChannel(ch:Int, delta:Int):Void
	{
		var v:Int = rgbVals[ch] + delta;
		if (v < 0) v = 0;
		if (v > 255) v = 255;
		rgbVals[ch] = v;
		refreshRgbSteppers();
		updateBG();
	}

	/** 直接设置三通道 */
	function setRgbAll(r:Int, g:Int, b:Int):Void
	{
		rgbVals[0] = r;
		rgbVals[1] = g;
		rgbVals[2] = b;
		refreshRgbSteppers();
		updateBG();
	}
	var fpSmallBgs:Array<FlxSprite> = [];
	var fpSmallTxts:Array<FlxText> = [];
	var fpSmallHits:Array<FlxSprite> = [];
	var fpSmallHover:Array<FlxSprite> = [];
	var fpSmallKeys:Array<String> = ['copy', 'paste'];
	var fpActionBgs:Array<FlxSprite> = [];
	var fpActionTxts:Array<FlxText> = [];
	var fpActionHits:Array<FlxSprite> = [];
	var fpActionHover:Array<FlxSprite> = [];
	var fpActionKeys:Array<String> = ['load_week', 'story_mode', 'save_week'];
	var fpCheckBox:FlxSprite;
	var fpCheckBorder:FlxSprite;
	var fpCheckLabel:FlxText;
	var fpCheckHit:FlxSprite;
	var fpTitleTxt:FlxText;
	var colorPreview:FlxSprite;
	var hideFreeplayCheckbox:FlxUICheckBox; // 数据源（不渲染）
	var fpPanelY:Float = 414;

	// 自绘输入框（ChartEditor 风格外观；原生控件只作隐藏数据源）
	var hexSelfBorder:FlxSprite;
	var hexSelfBox:FlxSprite;
	var hexSelfTxt:FlxText;
	var iconSelfBorder:FlxSprite;
	var iconSelfBox:FlxSprite;
	var iconSelfTxt:FlxText;
	var colorInputActive:Dynamic = null; // 当前弹起输入的原生控件
	var colorInputPrevX:Float = 0;
	var colorInputPrevY:Float = 0;
	var colorInputPrevVisible:Bool = false;

	/** 隐藏数据源控件（加入场景但不渲染；键盘走 stage 监听） */
	function addHiddenSource(w:Dynamic):Void
	{
		try { add(w); } catch (e:Dynamic) {}
		try { w.visible = false; } catch (e:Dynamic) {}
		try { w.active = false; } catch (e:Dynamic) {}
	}

	/** 自绘输入框边框/底板（ChartEditor 风格配色；border=深边框色，inner=内芯色） */
	function makeSelfBox(x:Float, y:Float, w:Int, group:FlxUI, color:Int = 0x14FFFFFF):FlxSprite
	{
		var s:FlxSprite = new FlxSprite().makeGraphic(w, 20, color);
		s.x = x;
		s.y = y;
		group.add(s);
		return s;
	}

	/** 自绘输入框文本（白字） */
	function makeSelfText(x:Float, y:Float, w:Int, group:FlxUI):FlxText
	{
		var t:FlxText = new FlxText(x, 0, w, '', 12);
		t.setFormat(Paths.font(EditorInputStyle.langFontFileName()), 12, COL_TEXT_MAIN, LEFT);
		t.wordWrap = false;
		t.y = y + (20 - t.height) / 2;
		group.add(t);
		return t;
	}

	/** 弹出原生输入覆盖层（自绘框位置） */
	function openColorInputOverlay(widget:Dynamic, box:FlxSprite):Void
	{
		closeColorInputOverlay();
		if (widget == null || box == null) return;
		try { colorInputPrevX = widget.x; } catch (e:Dynamic) {}
		try { colorInputPrevY = widget.y; } catch (e:Dynamic) {}
		try { colorInputPrevVisible = widget.visible; } catch (e:Dynamic) {}
		try { widget.x = box.x; } catch (e:Dynamic) {}
		try { widget.y = box.y - 2; } catch (e:Dynamic) {}
		try { widget.visible = true; } catch (e:Dynamic) {}
		// 统一灰底白字外观（与其它编辑器一致）
		EditorInputStyle.apply(widget);
		try { widget.active = false; } catch (e:Dynamic) {}
		// 提升到场景顶层
		var st:Dynamic = this;
		try { st.remove(widget); } catch (e:Dynamic) {}
		try { st.add(widget); } catch (e:Dynamic) {}
		try { widget.hasFocus = true; } catch (e:Dynamic) {}
		// 程序直接聚焦不走 FlxInputText 的 mouse 聚焦路径（focusGained 不触发），
		// 这里显式启用系统软键盘（移动端/触屏）
		WeekEditorState.setTextInputEnabled(true);
		try
		{
			var caret:Dynamic = Reflect.field(widget, 'caret');
			if (caret != null) caret.visible = true;
		}
		catch (e:Dynamic) {}
		colorInputActive = widget;
	}

	/** 收回输入覆盖层 */
	function closeColorInputOverlay():Void
	{
		if (colorInputActive != null)
		{
			try
			{
				colorInputActive.x = colorInputPrevX;
				colorInputActive.y = colorInputPrevY;
				colorInputActive.visible = colorInputPrevVisible;
				colorInputActive.active = false;
				colorInputActive.hasFocus = false;
			}
			catch (e:Dynamic) {}
			colorInputActive = null;
			WeekEditorState.setTextInputEnabled(false); // 收回软键盘
		}
	}

	/** 每帧：覆盖层失焦收回 + 自绘文本与数据源同步 */
	function updateColorInputs():Void
	{
		if (colorInputActive != null)
		{
			var focused:Bool = false;
			try { focused = colorInputActive.hasFocus; } catch (e:Dynamic) {}
			if (!focused)
				closeColorInputOverlay();
		}
		// 同步显示文本（超宽截断）
		if (hexSelfTxt != null)
		{
			var ht:String = hexInputText.text;
			if (ht.length > 6) ht = ht.substr(0, 6);
			if (hexSelfTxt.text != ht) hexSelfTxt.text = ht;
		}
		if (iconSelfTxt != null)
		{
			var it:String = iconInputText.text;
			if (it.length > 20) it = it.substr(0, 20);
			if (iconSelfTxt.text != it) iconSelfTxt.text = it;
		}
	}

	function addEditorBox()
	{
		// ===== 面板背景（左下角） =====
		var h:Int = 345;
		fpPanelY = FlxG.height - h - 10;
		fpBorder = new FlxSprite().makeGraphic(FP_W + 2, h + 2, COL_BORDER);
		fpBorder.x = 10;
		fpBorder.y = fpPanelY - 1;
		fpBorder.scrollFactor.set();
		add(fpBorder);
		fpBg = new FlxSprite().makeGraphic(FP_W, h, COL_CARD);
		fpBg.x = 11;
		fpBg.y = fpPanelY;
		fpBg.scrollFactor.set();
		add(fpBg);

		// 组坐标在成员添加后设置（FlxSpriteGroup.x/y 设置时会平移已有成员）
		fpPanel = new FlxUI(null, this);
		fpPanel.name = "FreeplayPanel";
		add(fpPanel);

		// 标题（当前编辑歌曲）
		fpTitleTxt = new FlxText(12, 8, FP_W - 24, '', 14);
		fpTitleTxt.setFormat(Paths.font(EditorInputStyle.langFontFileName()), 14, COL_ACCENT, LEFT);
		fpPanel.add(fpTitleTxt);

		addFreeplayUI();

		fpPanel.x = fpBg.x;
		fpPanel.y = fpBg.y;
	}

	function tr(key:String):String
	{
		var t = Language.get(key, 'week');
		if (t == key || t == key + ' (404)')
			t = key;
		return t;
	}

	override function getEvent(id:String, sender:Dynamic, data:Dynamic, ?params:Array<Dynamic>)
	{
		if (id == FlxUIInputText.CHANGE_EVENT && (sender is FlxUIInputText))
		{
			if (sender == iconInputText)
			{
				weekFile.songs[curSelected][1] = iconInputText.text;
				if (songCards.length > curSelected)
					songCards[curSelected].changeIcon(iconInputText.text);
			}
			else if (sender == hexInputText)
			{
				applyHexColor();
			}
		}
	}

	/** 解析十六进制输入并应用（带/不带 # 均可；非法或未输完则忽略） */
	function applyHexColor():Void
	{
		var t:String = (hexInputText != null) ? hexInputText.text : '';
		t = StringTools.trim(t);
		if (t.startsWith('#'))
			t = t.substr(1);
		if (t.length != 6)
			return;
		var r:Null<Int> = Std.parseInt('0x' + t.substr(0, 2));
		var g:Null<Int> = Std.parseInt('0x' + t.substr(2, 2));
		var b:Null<Int> = Std.parseInt('0x' + t.substr(4, 2));
		if (r == null || g == null || b == null)
			return;
		setRgbAll(r, g, b);
	}

	/** 当前颜色 → 6 位 hex 文本（不带 #；输入框聚焦时不覆盖用户输入） */
	function refreshHexDisplay():Void
	{
		if (hexInputText == null || hexInputText.hasFocus)
			return;
		hexInputText.text = StringTools.hex(rgbVals[0], 2) + StringTools.hex(rgbVals[1], 2) + StringTools.hex(rgbVals[2], 2);
	}

	var iconInputText:FlxUIInputText;
	var hexInputText:FlxUIInputText; // #RRGGBB 十六进制颜色输入

	/** 面板内容：标题 / RGB 步进 / #Hex 输入 + 预览 / Copy·Paste / 图标 / 隐藏勾选 / 动作行 */
	function addFreeplayUI()
	{
		var x0:Float = 12;

		// ===== 背景色 R/G/B 自绘步进 =====
		var lblColor:FlxText = new FlxText(x0, 30, 0, tr('fp_bg_color') + ':', 12);
		lblColor.setFormat(Paths.font(EditorInputStyle.langFontFileName()), 12, COL_TEXT_SEC, LEFT);
		fpPanel.add(lblColor);

		buildRgbSteppers(x0);

		// ===== 十六进制颜色输入（6 位，只允许 0-9/a-f/A-F；无需输入 #）+ 颜色预览 =====
		// ★ 新 UI：未聚焦时显示自绘框（灰底白字），聚焦时弹出原生输入框（同样灰底白字）
		hexInputText = new FlxUIInputText(x0, 0, 110, '', 12, 0xFFFFFFFF, 0xFF12141A);
		hexInputText.maxLength = 6; // 最多 6 位
		hexInputText.customFilterPattern = ~/[^0-9a-fA-F]/; // 过滤非法字符
		hexInputText.fieldBorderColor = 0x26FFFFFF;
		blockPressWhileTypingOn.push(hexInputText);
		addHiddenSource(hexInputText);
		hexSelfBorder = makeSelfBox(x0, 70, 112, fpPanel, 0x26FFFFFF);
		hexSelfBox = makeSelfBox(x0 + 1, 71, 110, fpPanel, 0xFF12141A);
		hexSelfTxt = makeSelfText(x0 + 8, 70, 98, fpPanel);

		colorPreview = new FlxSprite().makeGraphic(60, 22, 0xFFFFFFFF);
		colorPreview.x = x0 + 126;
		colorPreview.y = 72;
		fpPanel.add(colorPreview);

		// ===== Copy / Paste 两个半宽动作块 =====
		makeSmallRow(x0, 108, 0, 'fp_copy');
		makeSmallRow(x0 + (FP_W - 24) / 2 + 4, 108, 1, 'fp_paste');

		// ===== 图标输入行（自绘框 + 隐藏数据源，聚焦时原生框同灰底白字） =====
		var lblIcon:FlxText = new FlxText(x0, 148, 0, tr('fp_icon') + ':', 12);
		lblIcon.setFormat(Paths.font(EditorInputStyle.langFontFileName()), 12, COL_TEXT_SEC, LEFT);
		fpPanel.add(lblIcon);
		iconInputText = new FlxUIInputText(x0, 0, 160, '', 12, 0xFFFFFFFF, 0xFF12141A);
		iconInputText.fieldBorderColor = 0x26FFFFFF;
		blockPressWhileTypingOn.push(iconInputText);
		addHiddenSource(iconInputText);
		iconSelfBorder = makeSelfBox(x0 + 62, 141, 168, fpPanel, 0x26FFFFFF);
		iconSelfBox = makeSelfBox(x0 + 63, 142, 166, fpPanel, 0xFF12141A);
		iconSelfTxt = makeSelfText(x0 + 70, 141, 152, fpPanel);

		// ===== 隐藏勾选行（自绘） =====
		hideFreeplayCheckbox = new FlxUICheckBox(0, 0, null, null, '', 100);
		hideFreeplayCheckbox.checked = weekFile.hideFreeplay;
		hideFreeplayCheckbox.callback = function()
		{
			weekFile.hideFreeplay = hideFreeplayCheckbox.checked;
		};
		fpCheckBorder = new FlxSprite().makeGraphic(18, 18, 0x33FFFFFF);
		fpCheckBorder.x = x0;
		fpCheckBorder.y = 174;
		fpPanel.add(fpCheckBorder);
		fpCheckBox = new FlxSprite().makeGraphic(16, 16, 0xFF12141A);
		fpCheckBox.x = x0 + 1;
		fpCheckBox.y = 175;
		fpPanel.add(fpCheckBox);
		fpCheckLabel = new FlxText(x0 + 26, 177, FP_W - 60, tr('fp_hide_freeplay'), 14);
		fpCheckLabel.setFormat(Paths.font(EditorInputStyle.langFontFileName()), 14, COL_TEXT_MAIN, LEFT);
		fpPanel.add(fpCheckLabel);
		fpCheckHit = new FlxSprite().makeGraphic(FP_W - 24, 24, FlxColor.TRANSPARENT);
		fpCheckHit.x = x0;
		fpCheckHit.y = 172;
		fpPanel.add(fpCheckHit);

		// ===== 分隔线 =====
		var sep:FlxSprite = new FlxSprite().makeGraphic(FP_W - 24, 2, COL_BORDER);
		sep.x = x0;
		sep.y = 206;
		fpPanel.add(sep);

		// ===== 三个动作行（Load / Story / Save） =====
		makeActionRow(0, 220);
		makeActionRow(1, 260);
		makeActionRow(2, 300);
	}

	/** Copy/Paste 半宽动作块（次要按钮风格：模拟边框 + hover 强调） */
	function makeSmallRow(x:Float, y:Float, idx:Int, labelKey:String):Void
	{
		var w:Int = Std.int((FP_W - 24 - 8) / 2);
		var h:Int = 30;
		// 边框（1px 半透明白，垫底）
		var border:FlxSprite = new FlxSprite().makeGraphic(w, h, COL_SEC_BORDER);
		border.x = x;
		border.y = y;
		fpPanel.add(border);
		// 底
		var bg:FlxSprite = new FlxSprite().makeGraphic(w - 2, h - 2, COL_BG);
		bg.x = x + 1;
		bg.y = y + 1;
		fpPanel.add(bg);
		fpSmallBgs.push(bg);
		// hover 半透明底
		var hov:FlxSprite = new FlxSprite().makeGraphic(w - 2, h - 2, COL_HOVER);
		hov.x = x + 1;
		hov.y = y + 1;
		hov.visible = false;
		fpPanel.add(hov);
		fpSmallHover.push(hov);

		var txt:FlxText = new FlxText(x, 0, w, tr(labelKey), 13);
		txt.setFormat(Paths.font(EditorInputStyle.langFontFileName()), 13, COL_TEXT_SEC, CENTER);
		txt.y = y + (h - txt.height) / 2;
		fpPanel.add(txt);
		fpSmallTxts.push(txt);

		var hit:FlxSprite = new FlxSprite().makeGraphic(w, h, FlxColor.TRANSPARENT);
		hit.x = x;
		hit.y = y;
		fpPanel.add(hit);
		fpSmallHits.push(hit);
	}

	/** 底部动作行（Load Week / Story Mode / Save Week；次要按钮风格） */
	function makeActionRow(idx:Int, y:Float):Void
	{
		var x0:Float = 12;
		var w:Int = FP_W - 24;
		var h:Int = 34;
		var isDanger:Bool = (fpActionKeys[idx] == 'save_week');

		// 边框（危险行用危险色描边，其余半透明白）
		var borderC:Int = isDanger ? 0x66EF4444 : COL_SEC_BORDER;
		var border:FlxSprite = new FlxSprite().makeGraphic(w, h, borderC);
		border.x = x0;
		border.y = y;
		fpPanel.add(border);
		// 底
		var bg:FlxSprite = new FlxSprite().makeGraphic(w - 2, h - 2, COL_BG);
		bg.x = x0 + 1;
		bg.y = y + 1;
		fpPanel.add(bg);
		fpActionBgs.push(bg);
		// hover 半透明底
		var hov:FlxSprite = new FlxSprite().makeGraphic(w - 2, h - 2, COL_HOVER);
		hov.x = x0 + 1;
		hov.y = y + 1;
		hov.visible = false;
		fpPanel.add(hov);
		fpActionHover.push(hov);

		var labelKey:String = (fpActionKeys[idx] == 'story_mode') ? 'fp_story_mode' : 'item_' + fpActionKeys[idx];
		var txt:FlxText = new FlxText(x0, 0, w, tr(labelKey), 14);
		txt.setFormat(Paths.font(EditorInputStyle.langFontFileName()), 14,
			isDanger ? 0xFFF87171 : COL_TEXT_MAIN, CENTER);
		txt.y = y + (h - txt.height) / 2;
		fpPanel.add(txt);
		fpActionTxts.push(txt);

		var hit:FlxSprite = new FlxSprite().makeGraphic(w, h, FlxColor.TRANSPARENT);
		hit.x = x0;
		hit.y = y;
		fpPanel.add(hit);
		fpActionHits.push(hit);
	}

	/** 面板交互（每帧）：勾选行/小动作/动作行 hover 与点击 */
	function updateFreeplayPanel():Void
	{
		var mx:Float = FlxG.mouse.viewX;
		var my:Float = FlxG.mouse.viewY;

		// hover 高亮（overlay + 文字强调色）
		for (i in 0...fpSmallBgs.length)
		{
			var hov:Bool = (mx >= fpSmallHits[i].x && mx <= fpSmallHits[i].x + fpSmallHits[i].width
				&& my >= fpSmallHits[i].y && my <= fpSmallHits[i].y + fpSmallHits[i].height);
			if (fpSmallHover[i] != null)
				fpSmallHover[i].visible = hov;
			if (fpSmallTxts[i] != null)
				fpSmallTxts[i].color = hov ? COL_ACCENT : COL_TEXT_SEC;
		}
		for (i in 0...fpActionBgs.length)
		{
			var hov:Bool = (mx >= fpActionHits[i].x && mx <= fpActionHits[i].x + fpActionHits[i].width
				&& my >= fpActionHits[i].y && my <= fpActionHits[i].y + fpActionHits[i].height);
			if (fpActionHover[i] != null)
				fpActionHover[i].visible = hov;
			if (fpActionTxts[i] != null)
				fpActionTxts[i].color = hov ? COL_ACCENT : (fpActionKeys[i] == 'save_week' ? 0xFFF87171 : COL_TEXT_MAIN);
		}

		// RGB 自绘步进：按下 +/-（按住连续调整）
		for (i in 0...3)
		{
			if (rgbMinusHits[i] != null && mx >= rgbMinusHits[i].x && mx <= rgbMinusHits[i].x + rgbMinusHits[i].width
				&& my >= rgbMinusHits[i].y && my <= rgbMinusHits[i].y + rgbMinusHits[i].height && FlxG.mouse.pressed)
			{
				nudgeRgbChannel(i, -1);
			}
			if (rgbPlusHits[i] != null && mx >= rgbPlusHits[i].x && mx <= rgbPlusHits[i].x + rgbPlusHits[i].width
				&& my >= rgbPlusHits[i].y && my <= rgbPlusHits[i].y + rgbPlusHits[i].height && FlxG.mouse.pressed)
			{
				nudgeRgbChannel(i, 1);
			}
		}

		if (!FlxG.mouse.justPressed) return;

		// 自绘输入框（hex / 图标）：点击弹原生覆盖层输入
		if (hexSelfBox != null && mx >= hexSelfBox.x && mx <= hexSelfBox.x + hexSelfBox.width
			&& my >= hexSelfBox.y && my <= hexSelfBox.y + hexSelfBox.height)
		{
			openColorInputOverlay(hexInputText, hexSelfBox);
			return;
		}
		if (iconSelfBox != null && mx >= iconSelfBox.x && mx <= iconSelfBox.x + iconSelfBox.width
			&& my >= iconSelfBox.y && my <= iconSelfBox.y + iconSelfBox.height)
		{
			openColorInputOverlay(iconInputText, iconSelfBox);
			return;
		}
		// 点输入框之外的其它元素：先收回输入覆盖层（原生控件不 update，不会自动失焦）
		if (colorInputActive != null)
			closeColorInputOverlay();

		// 勾选行
		if (fpCheckHit != null && mx >= fpCheckHit.x && mx <= fpCheckHit.x + fpCheckHit.width
			&& my >= fpCheckHit.y && my <= fpCheckHit.y + fpCheckHit.height)
		{
			var before:Bool = false;
			try { before = hideFreeplayCheckbox.checked; } catch (e:Dynamic) {}
			try { hideFreeplayCheckbox.checked = !before; } catch (e:Dynamic) {}
			try
			{
				var cb:Dynamic = Reflect.field(hideFreeplayCheckbox, 'callback');
				if (cb != null) cb();
			}
			catch (e:Dynamic) {}
			refreshFreeplayCheckVisual();
			return;
		}
		// Copy / Paste
		for (i in 0...fpSmallHits.length)
		{
			var hit = fpSmallHits[i];
			if (mx >= hit.x && mx <= hit.x + hit.width && my >= hit.y && my <= hit.y + hit.height)
			{
				onFpSmallClick(fpSmallKeys[i]);
				return;
			}
		}
		// 动作行
		for (i in 0...fpActionHits.length)
		{
			var hit = fpActionHits[i];
			if (mx >= hit.x && mx <= hit.x + hit.width && my >= hit.y && my <= hit.y + hit.height)
			{
				onFpActionClick(fpActionKeys[i]);
				return;
			}
		}
	}

	function refreshFreeplayCheckVisual():Void
	{
		var checked:Bool = false;
		try { checked = hideFreeplayCheckbox.checked; } catch (e:Dynamic) {}
		fpCheckBox.makeGraphic(16, 16, checked ? 0xFF8B5CF6 : 0xFF12141A);
		fpCheckBorder.makeGraphic(18, 18, checked ? 0xFFA78BFA : 0x33FFFFFF);
	}

	function onFpSmallClick(key:String):Void
	{
		if (key == 'copy')
		{
			Clipboard.text = bg.color.red + ',' + bg.color.green + ',' + bg.color.blue;
		}
		else if (key == 'paste')
		{
			if (Clipboard.text != null)
			{
				var leColor:Array<Int> = [];
				var splitted:Array<String> = Clipboard.text.trim().split(',');
				for (i in 0...splitted.length)
				{
					var toPush:Int = Std.parseInt(splitted[i]);
					if (!Math.isNaN(toPush))
					{
						if (toPush > 255)
							toPush = 255;
						else if (toPush < 0)
							toPush *= -1;
						leColor.push(toPush);
					}
				}
				if (leColor.length > 2)
				{
					setRgbAll(leColor[0], leColor[1], leColor[2]);
				}
			}
		}
	}

	function onFpActionClick(key:String):Void
	{
		switch (key)
		{
			case 'load_week':
				WeekEditorState.loadWeek();
			case 'story_mode':
				MusicBeatState.switchState(new WeekEditorState(weekFile));
			case 'save_week':
				WeekEditorState.saveWeek(weekFile);
		}
	}

	function updateBG()
	{
		weekFile.songs[curSelected][2][0] = rgbVals[0];
		weekFile.songs[curSelected][2][1] = rgbVals[1];
		weekFile.songs[curSelected][2][2] = rgbVals[2];
		var rgb:Array<Int> = weekFile.songs[curSelected][2];
		var c:Int = FlxColor.fromRGB(rgb[0], rgb[1], rgb[2]);
		bg.color = c;
		if (colorPreview != null)
			colorPreview.color = c;
		// 同步当前卡片底色（占位缩略底跟随歌曲主题色）
		if (songCards.length > curSelected)
			songCards[curSelected].setCardColor(rgb);
		refreshHexDisplay();
	}

	function changeSelection(change:Int = 0)
	{
		FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);

		var oldSel:Int = curSelected;
		curSelected += change;

		if (curSelected < 0)
			curSelected = weekFile.songs.length - 1;
		if (curSelected >= weekFile.songs.length)
			curSelected = 0;

		// 列表平滑滚动到选中卡居中（同原版 songsMove.tweenData 语义）
		scrollTarget = cardCenterY - WeekSongRect.fixHeight * 0.5 - curSelected * (WeekSongRect.fixHeight * 0.97);
		if (songCards.length > curSelected && oldSel != curSelected)
			songCards[curSelected].beatHit();

		trace(weekFile.songs[curSelected]);
		iconInputText.text = weekFile.songs[curSelected][1];
		rgbVals[0] = Math.round(weekFile.songs[curSelected][2][0]);
		rgbVals[1] = Math.round(weekFile.songs[curSelected][2][1]);
		rgbVals[2] = Math.round(weekFile.songs[curSelected][2][2]);
		refreshRgbSteppers();
		if (fpTitleTxt != null)
			fpTitleTxt.text = tr('fp_editing') + ': ' + weekFile.songs[curSelected][0];
		refreshFreeplayCheckVisual();
		updateBG();
	}

	override function update(elapsed:Float)
	{
		updateSongCards(elapsed);

		if (WeekEditorState.loadedWeek != null)
		{
			super.update(elapsed);
			FlxTransitionableState.skipNextTransIn = true;
			FlxTransitionableState.skipNextTransOut = true;
			MusicBeatState.switchState(new WeekEditorFreeplayState(WeekEditorState.loadedWeek));
			WeekEditorState.loadedWeek = null;
			return;
		}

		var typing:Bool = false;
		for (t in blockPressWhileTypingOn)
		{
			if (t.hasFocus)
			{
				typing = true;
				if (FlxG.keys.justPressed.ENTER)
					t.hasFocus = false;
				break;
			}
		}
		if (typing)
		{
			ClientPrefs.toggleVolumeKeys(false);
		}
		else
		{
			ClientPrefs.toggleVolumeKeys(true);
			// 自绘输入框：失焦收回 + 文本同步
			updateColorInputs();
			// 左下编辑面板交互
			updateFreeplayPanel();
			if (FlxG.keys.justPressed.ESCAPE)
			{
				// 返回周目编辑器（不再直接跳回主菜单）
				MusicBeatState.switchState(new WeekEditorState(weekFile));
			}

			if (controls.UI_UP_P)
				changeSelection(-1);
			if (controls.UI_DOWN_P)
				changeSelection(1);

			// 鼠标滚轮选择（卡片点击由卡片自身的 hover/click 逻辑处理）
			if (FlxG.mouse.wheel != 0)
				changeSelection(FlxG.mouse.wheel > 0 ? -1 : 1);
		}
		super.update(elapsed);
	}
}
