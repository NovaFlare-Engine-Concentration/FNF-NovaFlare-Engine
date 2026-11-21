package options.base;

import flixel.addons.display.FlxBackdrop;
import flixel.addons.display.FlxGridOverlay;
import flixel.input.keyboard.FlxKey;

import games.objects.Note;
import general.shaders.NoteHSV;
import general.backend.NoteSkinStyle;

/**
 * 旧版（legacy）音符贴图的 HSV 调色板：每轨 hue / saturation / brightness 三个值。
 *
 * 只影响被判定为 legacy 的音符贴图（见 general.backend.NoteSkinStyle）—— RGB 通道贴图走 Note Colors
 * 那套 RGB 调色板，两者不是一回事。交互沿用 Psych 0.6.3 的 NotesSubState：
 * 上下选轨、左右选通道、ACCEPT 进入微调、微调里左右 +/-（长按加速）、RESET 归零。
 * 另外加了鼠标点选 / 悬停 / 滚轮，以及键盘直输数字。
 *
 * 16 轨分页显示（每页 4 行），多键谱面也不会跑出屏幕。
 */
class NotesHSVSubState extends MusicBeatSubstate
{
	static var curSelected:Int = 0; // 全局轨道下标 0..(laneCount-1)
	static var typeSelected:Int = 0; // 0 hue / 1 saturation / 2 brightness

	static inline var NOTES_PER_PAGE:Int = 4;
	static inline var VALUE_W:Int = 120;

	// 选中反馈分两档，压暗幅度拉开差距，一眼分清"选了"和"正在改"：
	//   单纯选中 —— 选中行亮、其它行压暗；
	//   微调（changing / typing）—— 整个格子区域压暗，只留当前格单独亮 + 强调色。
	// 标题 / 描述 / 提示文字不属于格子区域，永远不压。
	static inline var DIM_ROW:Float = 0.4; // 单纯选中时：其它行
	static inline var DIM_CHANNEL:Float = 0.65; // 单纯选中时：选中行内其它通道
	static inline var DIM_GLOBAL:Float = 0.2; // 微调时：除当前格外全部压到这么暗
	static inline var DIM_HEADER:Float = 0.45; // 单纯选中时：非选中通道的表头
	static inline var ACCENT:FlxColor = 0xFFFFD84A; // 微调中当前格的强调色（黄）
	static inline var ROW_PANEL_X:Float = 290;
	static inline var ROW_PANEL_W:Float = 640; // valueX(2)+VALUE_W-ROW_PANEL_X

	var laneCount:Int = 16;
	var notePage:Int = 0;
	var totalPages:Int = 1;

	var previews:Array<FlxSprite> = [];
	var previewBaseScales:Array<Float> = [];
	var valueTexts:Array<FlxText> = [];
	var headers:Array<FlxText> = [];

	var rowHighlight:FlxSprite; // 选中行的底板，压暗全局时是唯一的"亮区"锚点
	var cursor:FlxSprite;
	var pageText:FlxText;
	var descText:FlxText;

	// 鼠标悬停：只在非微调态做提示（可点），微调态全局压暗优先
	var hoverValue:Int = -1;
	var hoverPreview:Int = -1;
	var popTween:FlxTween;

	var changing:Bool = false;
	var holdTime:Float = 0;
	var holdAccum:Float = 0; // 长按加速的余数累加（跟帧率无关，见 updateChanging）
	var nextAccept:Int = 0;

	// 键盘直接输入数字：0-9 与负号，Numpad 也认
	var typing:Bool = false;
	var typedText:String = '';
	var typeTimer:Float = 0;
	static inline var TYPE_TIMEOUT:Float = 1.5;
	static inline var HOLD_DELAY:Float = 0.35;

	static var typeKeys:Map<FlxKey, String> = [
		ZERO => '0', ONE => '1', TWO => '2', THREE => '3', FOUR => '4',
		FIVE => '5', SIX => '6', SEVEN => '7', EIGHT => '8', NINE => '9',
		NUMPADZERO => '0', NUMPADONE => '1', NUMPADTWO => '2', NUMPADTHREE => '3', NUMPADFOUR => '4',
		NUMPADFIVE => '5', NUMPADSIX => '6', NUMPADSEVEN => '7', NUMPADEIGHT => '8', NUMPADNINE => '9',
		MINUS => '-', NUMPADMINUS => '-'
	];

	public function new()
	{
		super();
	}

	override function create()
	{
		super.create();

		laneCount = (ClientPrefs.data.arrowHSV == null || ClientPrefs.data.arrowHSV.length < 1) ? 16 : ClientPrefs.data.arrowHSV.length;
		totalPages = Std.int(Math.max(1, Math.ceil(laneCount / NOTES_PER_PAGE)));
		if (curSelected >= laneCount) curSelected = 0;
		notePage = Std.int(curSelected / NOTES_PER_PAGE);

		var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.color = 0xFF7A4BD6;
		bg.screenCenter();
		bg.antialiasing = ClientPrefs.data.antialiasing;
		add(bg);

		var grid:FlxBackdrop = new FlxBackdrop(FlxGridOverlay.createGrid(80, 80, 160, 160, true, 0x33FFFFFF, 0x0));
		grid.velocity.set(-30, 40);
		grid.alpha = 0;
		FlxTween.tween(grid, {alpha: 1}, 0.5, {ease: FlxEase.quadOut});
		add(grid);

		var title:FlxText = new FlxText(60, 38, 0, Language.get('note_hsv_title', 'options'), 34);
		title.setFormat(Paths.font('vcr.ttf'), 34, FlxColor.WHITE, LEFT, OUTLINE, FlxColor.BLACK);
		title.borderSize = 2;
		title.antialiasing = ClientPrefs.data.antialiasing;
		add(title);

		descText = new FlxText(60, 84, FlxG.width - 120, Language.get('note_hsv_desc', 'options'), 16);
		descText.setFormat(Paths.font('vcr.ttf'), 16, FlxColor.WHITE, LEFT, OUTLINE, FlxColor.BLACK);
		descText.borderSize = 2;
		descText.antialiasing = ClientPrefs.data.antialiasing;
		descText.alpha = 0.85;
		add(descText);

		// 通道表头：文字全部大写，横排对齐数值列
		var headerLabels:Array<String> = [
			Language.get('note_hsv_hue', 'options'),
			Language.get('note_hsv_sat', 'options'),
			Language.get('note_hsv_brt', 'options')
		];
		for (i in 0...3)
		{
			var head:FlxText = new FlxText(valueX(i), 150, VALUE_W, headerLabels[i], 18);
			head.setFormat(Paths.font('vcr.ttf'), 18, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
			head.borderSize = 2;
			head.antialiasing = ClientPrefs.data.antialiasing;
			head.alpha = 0.8;
			add(head);
			headers.push(head);
		}

		// 选中行底板：先加（压在预览/数值/光标的下面），buildPage 稍后把行内容叠上来
		rowHighlight = new FlxSprite(ROW_PANEL_X, 0).makeGraphic(Std.int(ROW_PANEL_W), 100, FlxColor.BLACK);
		rowHighlight.visible = false;
		add(rowHighlight);

		cursor = new FlxSprite(0, 0).makeGraphic(VALUE_W, 6, FlxColor.WHITE);
		cursor.alpha = 0.9;
		add(cursor);

		pageText = new FlxText(60, FlxG.height - 70, 300, '', 20);
		pageText.setFormat(Paths.font('vcr.ttf'), 20, FlxColor.WHITE, LEFT, OUTLINE, FlxColor.BLACK);
		pageText.borderSize = 2;
		pageText.antialiasing = ClientPrefs.data.antialiasing;
		add(pageText);

		var tip:FlxText = new FlxText(60, FlxG.height - 38, FlxG.width - 120, Language.get('note_hsv_tip', 'options'), 16);
		tip.setFormat(Paths.font('vcr.ttf'), 16, FlxColor.WHITE, LEFT, OUTLINE, FlxColor.BLACK);
		tip.borderSize = 2;
		tip.antialiasing = ClientPrefs.data.antialiasing;
		tip.alpha = 0.7;
		add(tip);

		addVirtualPad(LEFT_FULL, A_B);

		buildPage();
		refreshAll();
		FlxG.sound.play(Paths.sound('scrollMenu'), 0.6);
	}

	inline function valueX(index:Int):Float return 470 + index * 170;

	inline function rowY(index:Int):Float return 200 + index * 105;

	/**
	 * 预览用的贴图：**固定用旧版音符图集**（images/NOTE_assets.png，在 images 根目录、不在 noteSkins/ 里）。
	 * 这套编辑器调的就是旧版贴图的 HSV，所以不能拿 StrumNote 的 static 帧（那是灰色轨道箭头），
	 * 也不能拿玩家当前皮肤（可能是 RGB 掩码）。旧图集缺失时才退回玩家皮肤。
	 */
	function previewSkin():String
	{
		if (NoteSkinStyle.exists(NoteSkinStyle.LEGACY_NOTE_SKIN)) return NoteSkinStyle.LEGACY_NOTE_SKIN;

		var fallback:String = Note.defaultNoteSkin + Note.getNoteSkinPostfix();
		if (Paths.fileExists('images/$fallback.png', IMAGE)) return fallback;
		return Note.defaultNoteSkin;
	}

	function buildPage():Void
	{
		if (popTween != null)
		{
			popTween.cancel();
			popTween = null;
		}

		for (note in previews)
		{
			remove(note);
			note.destroy();
		}
		previews = [];
		previewBaseScales = [];

		for (text in valueTexts)
		{
			remove(text);
			text.destroy();
		}
		valueTexts = [];

		var skin:String = previewSkin();
		var atlas = Paths.getSparrowAtlas(skin);
		var first:Int = notePage * NOTES_PER_PAGE;
		var last:Int = Std.int(Math.min(first + NOTES_PER_PAGE, laneCount));

		for (lane in first...last)
		{
			var row:Int = lane - first;
			var preview:FlxSprite = new FlxSprite(300, rowY(row) - 20);
			preview.frames = atlas;
			preview.antialiasing = ClientPrefs.data.antialiasing;

			// 取音符帧（purple0 / blue0 …），不是轨道上的 arrowLEFT static 帧
			var dir:Int = lane % Note.colArray.length;
			preview.animation.addByPrefix('idle', Note.colArray[dir] + '0');
			preview.animation.play('idle', true);
			preview.setGraphicSize(88);
			preview.updateHitbox();
			previewBaseScales.push(preview.scale.x);
			add(preview);
			previews.push(preview);

			for (type in 0...3)
			{
				var text:FlxText = new FlxText(valueX(type), rowY(row), VALUE_W, '0', 32);
				text.setFormat(Paths.font('vcr.ttf'), 32, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
				text.borderSize = 3;
				text.antialiasing = ClientPrefs.data.antialiasing;
				add(text);
				valueTexts.push(text);
			}
		}

		applyPreviewShaders();
		// 换页后悬停下标属于新页面了，旧值清掉，等下一帧重新检测
		hoverValue = -1;
		hoverPreview = -1;
		pageText.text = Std.string(notePage + 1) + ' / ' + Std.string(totalPages);
	}

	/** HSV 参数在 0 ↔ 非 0 之间切换时 shader 的挂载状态会变，预览必须重挂一遍 */
	function applyPreviewShaders():Void
	{
		for (i in 0...previews.length)
		{
			var lane:Int = notePage * NOTES_PER_PAGE + i;
			if (!NoteHSV.apply(previews[i], lane)) previews[i].shader = null;
		}
	}

	function refreshAll():Void
	{
		refreshTexts();
		refreshSelection();
	}

	function refreshTexts():Void
	{
		var first:Int = notePage * NOTES_PER_PAGE;
		for (i in 0...valueTexts.length)
		{
			var lane:Int = first + Std.int(i / 3);
			var type:Int = i % 3;
			if (lane >= laneCount)
			{
				valueTexts[i].text = '';
				continue;
			}
			var row:Array<Float> = ClientPrefs.data.arrowHSV[lane];
			valueTexts[i].text = Std.string(row == null ? 0 : Std.int(row[type]));
		}
	}

	function refreshSelection():Void
	{
		var first:Int = notePage * NOTES_PER_PAGE;
		// 直输数字也算"正在改这一格"，视觉上和 changing 同档
		var editing:Bool = (changing || typing);

		for (i in 0...valueTexts.length)
		{
			var lane:Int = first + Std.int(i / 3);
			var type:Int = i % 3;
			var isSelected:Bool = (lane == curSelected && type == typeSelected);
			valueTexts[i].color = FlxColor.WHITE;

			if (isSelected)
			{
				// 当前格：永远全亮；微调中再叠一层强调色，跟"单纯选中"拉开差距
				valueTexts[i].alpha = 1;
				valueTexts[i].color = editing ? ACCENT : FlxColor.WHITE;
			}
			else if (editing)
			{
				valueTexts[i].alpha = DIM_GLOBAL;
			}
			else if (i == hoverValue)
			{
				valueTexts[i].alpha = 0.95; // 悬停提示：这里可以点
			}
			else
			{
				valueTexts[i].alpha = (lane == curSelected) ? DIM_CHANNEL : DIM_ROW;
			}
		}

		for (i in 0...previews.length)
		{
			var lane:Int = first + i;
			var isSelected:Bool = (lane == curSelected);
			var isHovered:Bool = !editing && (i == hoverPreview
				|| (hoverValue >= 0 && first + Std.int(hoverValue / 3) == lane));

			if (isSelected) previews[i].alpha = 1;
			else if (editing) previews[i].alpha = DIM_GLOBAL;
			else if (isHovered) previews[i].alpha = 0.9;
			else previews[i].alpha = DIM_ROW;
		}

		for (i in 0...headers.length)
		{
			if (editing) headers[i].alpha = (i == typeSelected) ? 0.9 : DIM_GLOBAL;
			else headers[i].alpha = (i == typeSelected) ? 1 : DIM_HEADER;
		}

		var index:Int = (curSelected - first) * 3 + typeSelected;
		var text:FlxText = (index >= 0 && index < valueTexts.length) ? valueTexts[index] : null;
		if (text != null)
		{
			cursor.x = valueX(typeSelected);
			cursor.y = rowY(curSelected - first) + 45;
			cursor.visible = true;
			cursor.color = editing ? ACCENT : FlxColor.WHITE;
			cursor.alpha = editing ? 1 : 0.6;
		}
		else cursor.visible = false;

		if (cursor.visible && rowHighlight != null)
		{
			rowHighlight.x = ROW_PANEL_X;
			rowHighlight.y = rowY(curSelected - first) - 28;
			rowHighlight.visible = true;
			rowHighlight.alpha = editing ? 0.4 : 0.28;
		}
		else rowHighlight.visible = false;
	}

	/** 选中轨变化时的弹跳：预览从放大缩回原尺寸，选中感更明确 */
	function popPreview():Void
	{
		var idx:Int = curSelected - notePage * NOTES_PER_PAGE;
		if (idx < 0 || idx >= previews.length) return;

		var base:Float = previewBaseScales[idx];
		if (popTween != null) popTween.cancel();
		previews[idx].scale.set(base * 1.25, base * 1.25);
		popTween = FlxTween.tween(previews[idx].scale, {x: base, y: base}, 0.18, {ease: FlxEase.quadOut});
	}

	override function update(elapsed:Float)
	{
		if (nextAccept > 0) nextAccept--;

		// 键盘直输优先；提交/取消后这一帧继续往下走，让同时按下的鼠标点击直接生效
		if (typing)
		{
			handleTyping(elapsed);
			if (typing)
			{
				super.update(elapsed);
				return;
			}
		}

		if (changing)
		{
			updateChanging(elapsed);
		}
		else
		{
			// 数字键 / 负号 → 直接输入当前选中格的值
			var pressedKey:FlxKey = cast FlxG.keys.firstJustPressed();
			if (nextAccept <= 0 && typeKeys.exists(pressedKey))
			{
				beginTyping(typeKeys.get(pressedKey));
				super.update(elapsed);
				return;
			}

			if (controls.UI_UP_P) changeSelection(-1);
			else if (controls.UI_DOWN_P) changeSelection(1);

			if (controls.UI_LEFT_P) changeType(-1);
			else if (controls.UI_RIGHT_P) changeType(1);

			if (controls.ACCEPT && nextAccept <= 0)
			{
				changing = true;
				holdTime = 0;
				holdAccum = 0;
				FlxG.sound.play(Paths.sound('scrollMenu'), 0.6);
				refreshSelection(); // 进入微调 → 立刻压暗全局、点亮当前格
			}

			if (controls.RESET) resetValue();

			if (controls.BACK)
			{
				FlxG.sound.play(Paths.sound('cancelMenu'));
				close();
				return;
			}
		}

		updateHover();
		handleMouse();

		super.update(elapsed);
	}

	/** 悬停提示：微调态不做（全局压暗优先），只服务"这里可以点" */
	function updateHover():Void
	{
		var hv:Int = -1;
		var hp:Int = -1;

		if (!changing)
		{
			for (i in 0...valueTexts.length)
			{
				var lane:Int = notePage * NOTES_PER_PAGE + Std.int(i / 3);
				if (lane >= laneCount) continue;
				if (FlxG.mouse.overlaps(valueTexts[i]))
				{
					hv = i;
					break;
				}
			}

			if (hv < 0)
			{
				for (i in 0...previews.length)
				{
					if (FlxG.mouse.overlaps(previews[i]))
					{
						hp = i;
						break;
					}
				}
			}
		}

		if (hv != hoverValue || hp != hoverPreview)
		{
			hoverValue = hv;
			hoverPreview = hp;
			refreshSelection();
		}
	}

	/** 鼠标：点数值/预览直接选中（clickCell），滚轮微调（微调态里也生效） */
	function handleMouse():Void
	{
		if (FlxG.mouse.justPressed)
		{
			for (i in 0...valueTexts.length)
			{
				var lane:Int = notePage * NOTES_PER_PAGE + Std.int(i / 3);
				if (lane >= laneCount) continue;
				if (FlxG.mouse.overlaps(valueTexts[i]))
				{
					clickCell(lane, i % 3);
					return;
				}
			}

			for (i in 0...previews.length)
			{
				if (FlxG.mouse.overlaps(previews[i]))
				{
					clickCell(notePage * NOTES_PER_PAGE + i, -1);
					return;
				}
			}
		}
		else if (FlxG.mouse.wheel != 0 && (FlxG.mouse.deltaViewX == 0 && FlxG.mouse.deltaViewY == 0))
		{
			setValue(currentValue() + FlxG.mouse.wheel * (FlxG.keys.pressed.SHIFT ? 5 : 1));
		}
	}

	/**
	 * 鼠标点击语义：
	 *   点别的格 —— 直接选中（微调中则切过去继续微调）；
	 *   点已选中的格 —— 进出微调（等价 ACCEPT）。
	 */
	function clickCell(lane:Int, type:Int):Void
	{
		if (type < 0) type = typeSelected;
		var sameCell:Bool = (lane == curSelected && type == typeSelected);

		if (changing)
		{
			if (sameCell)
			{
				changing = false;
				holdTime = 0;
				holdAccum = 0;
				nextAccept = 3;
				FlxG.sound.play(Paths.sound('cancelMenu'), 0.6);
				refreshSelection();
				return;
			}
			selectCell(lane, type); // 换格继续微调
			return;
		}

		if (sameCell)
		{
			changing = true;
			holdTime = 0;
			holdAccum = 0;
			FlxG.sound.play(Paths.sound('scrollMenu'), 0.6);
			refreshSelection();
			return;
		}

		selectCell(lane, type);
	}

	/** 直接选中（不循环、不进微调）；跨页先换页 */
	function selectCell(lane:Int, type:Int):Void
	{
		if (lane < 0) lane = 0;
		if (lane >= laneCount) lane = laneCount - 1;
		if (type >= 0 && type != typeSelected) typeSelected = type;
		curSelected = lane;

		var page:Int = Std.int(lane / NOTES_PER_PAGE);
		if (page != notePage)
		{
			notePage = page;
			buildPage();
		}
		popPreview();
		refreshAll();
		FlxG.sound.play(Paths.sound('scrollMenu'), 0.6);
	}

	function updateChanging(elapsed:Float):Void
	{
		if (controls.BACK || controls.ACCEPT)
		{
			changing = false;
			holdTime = 0;
			nextAccept = 3;
			FlxG.sound.play(Paths.sound('cancelMenu'), 0.6);
			refreshSelection(); // 退出微调 → 回到"单纯选中"的亮度
			return;
		}

		var step:Int = FlxG.keys.pressed.SHIFT ? 10 : 1;
		if (controls.RESET)
		{
			resetValue();
			FlxG.sound.play(Paths.sound('scrollMenu'), 0.6);
		}

		// 单击：立刻走一步
		var dir:Int = 0;
		if (controls.UI_LEFT_P) dir = -1;
		else if (controls.UI_RIGHT_P) dir = 1;

		if (dir != 0)
		{
			setValue(currentValue() + dir * step, true);
			holdTime = 0;
			holdAccum = 0;
		}
		else if (!controls.UI_LEFT && !controls.UI_RIGHT)
		{
			holdTime = 0;
			holdAccum = 0;
		}
		else
		{
			holdTime += elapsed;
			if (holdTime >= HOLD_DELAY)
			{
				// 长按：按"秒"累积步长、余数保留。
				// 旧写法 Std.int(elapsed * speed) 在 144Hz / 无限 FPS 下每帧都是 0，所以长按完全不动。
				var speed:Float = (typeSelected == 0) ? 90 : 50;
				if (FlxG.keys.pressed.SHIFT) speed *= 3;
				holdAccum += elapsed * speed;

				var whole:Int = Std.int(holdAccum);
				if (whole != 0)
				{
					holdAccum -= whole;
					setValue(currentValue() + (controls.UI_LEFT ? -whole : whole));
				}
			}
		}

		if (controls.UI_UP_P) changeSelection(-1);
		else if (controls.UI_DOWN_P) changeSelection(1);
	}

	/**
	 * 键盘直输：数字 0-9 与负号。
	 * ACCEPT / ENTER / 1.5s 无输入 → 提交（自动夹到 ±180 / ±100）；BACKSPACE 退格；BACK 放弃。
	 */
	function beginTyping(firstChar:String):Void
	{
		typing = true;
		typedText = (firstChar == '-') ? '-' : firstChar;
		typeTimer = 0;
		showTypingText();
		refreshSelection(); // 直输也是"正在改这一格"，和微调同档压暗
		FlxG.sound.play(Paths.sound('scrollMenu'), 0.6);
	}

	function showTypingText():Void
	{
		var index:Int = (curSelected - notePage * NOTES_PER_PAGE) * 3 + typeSelected;
		if (index < 0 || index >= valueTexts.length) return;
		valueTexts[index].text = typedText.length > 0 ? typedText : '0';
	}

	function handleTyping(elapsed:Float):Void
	{
		typeTimer += elapsed;

		var key:FlxKey = cast FlxG.keys.firstJustPressed();
		if (typeKeys.exists(key))
		{
			var ch:String = typeKeys.get(key);
			var digits:String = typedText.split('-').join('');
			if (ch == '-')
			{
				if (typedText.indexOf('-') < 0) typedText = '-' + typedText;
			}
			else if (digits.length < 3)
			{
				// 首位 0 直接替换掉，别出现 007
				if (digits == '0') typedText = (typedText.charAt(0) == '-' ? '-' : '') + ch;
				else typedText += ch;
			}
			typeTimer = 0;
			showTypingText();
			FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
			return;
		}

		if (FlxG.keys.justPressed.BACKSPACE)
		{
			if (typedText.length > 0) typedText = typedText.substring(0, typedText.length - 1);
			typeTimer = 0;
			showTypingText();
			return;
		}

		if (controls.ACCEPT || FlxG.keys.justPressed.ENTER || typeTimer >= TYPE_TIMEOUT)
			commitTyping();
		else if (controls.BACK)
		{
			typing = false;
			refreshTexts();
			refreshSelection();
			FlxG.sound.play(Paths.sound('cancelMenu'), 0.6);
		}
	}

	function commitTyping():Void
	{
		typing = false;
		var parsed:Null<Int> = Std.parseInt(typedText);
		if (parsed != null) setValue(parsed);
		refreshTexts();
		refreshSelection();
		nextAccept = 3;
		FlxG.sound.play(Paths.sound('scrollMenu'), 0.6);
	}

	function changeSelection(change:Int):Void
	{
		holdTime = 0;
		holdAccum = 0;

		curSelected += change;
		if (curSelected < 0) curSelected = laneCount - 1;
		if (curSelected >= laneCount) curSelected = 0;

		var page:Int = Std.int(curSelected / NOTES_PER_PAGE);
		if (page != notePage)
		{
			notePage = page;
			buildPage();
		}

		popPreview();
		refreshAll();
		FlxG.sound.play(Paths.sound('scrollMenu'), 0.6);
	}

	function changeType(change:Int):Void
	{
		typeSelected += change;
		if (typeSelected < 0) typeSelected = 2;
		if (typeSelected >= 3) typeSelected = 0;
		refreshSelection();
		FlxG.sound.play(Paths.sound('scrollMenu'), 0.6);
	}

	function currentValue():Int
	{
		var row:Array<Float> = ClientPrefs.data.arrowHSV[curSelected];
		return (row == null) ? 0 : Std.int(row[typeSelected]);
	}

	function maxValue():Int return (typeSelected == 0) ? 180 : 100;

	function setValue(value:Int, ?playSound:Bool = false):Void
	{
		var max:Int = maxValue();
		if (value > max) value = max;
		if (value < -max) value = -max;

		var row:Array<Float> = ClientPrefs.data.arrowHSV[curSelected];
		if (row == null)
		{
			row = [0.0, 0.0, 0.0];
			ClientPrefs.data.arrowHSV[curSelected] = row;
		}
		if (row[typeSelected] == value) return;
		row[typeSelected] = value;

		// 共享调色板就地改值，已挂着的预览 / 游玩中的 sprite 会立刻跟着变；
		// 数值在 0 ↔ 非 0 之间切换时 shader 的挂载状态也变了，预览要重挂一次。
		NoteHSV.refresh();
		applyPreviewShaders();

		refreshTexts();
		if (playSound) FlxG.sound.play(Paths.sound('scrollMenu'), 0.6);
	}

	function resetValue():Void
	{
		if (FlxG.keys.pressed.SHIFT)
		{
			var keep:Int = typeSelected;
			for (i in 0...3)
			{
				typeSelected = i;
				setValue(0);
			}
			typeSelected = keep;
		}
		else setValue(0);

		refreshAll();
		FlxG.sound.play(Paths.sound('cancelMenu'), 0.6);
	}

	override function destroy()
	{
		if (popTween != null)
		{
			popTween.cancel();
			popTween = null;
		}
		previews = [];
		previewBaseScales = [];
		valueTexts = [];
		headers = [];
		hoverValue = -1;
		hoverPreview = -1;
		super.destroy();
	}
}
