package developer.editors;

import flixel.util.FlxSpriteUtil;

/**
 * 确认弹窗的可选配置。**所有字段都可省略**，省略时按下面的顺序取文案：
 *
 *   1. `title` / `message` / `confirmLabel` / `cancelLabel` / `hint` 直接给的值
 *   2. `xxxKey` 指定的语言键
 *   3. 内置默认语言键（confirm_unsaved_title / _message / _btn_confirm / _btn_cancel / _hint）
 *   4. 内置中英文兜底字面量
 *
 * `langGroup` 决定去哪个语言组取键（'dialogue' / 'dialoguechar' / 'stage' …）；
 * 该组里没有这个键时自动回退到公共组 'editors'，再没有才用内置字面量。
 */
typedef ConfirmDialogOptions =
{
	/** 语言组名，默认 'editors'。 */
	?langGroup:String,
	/** 语言键覆盖。 */
	?titleKey:String,
	?messageKey:String,
	?confirmKey:String,
	?cancelKey:String,
	?hintKey:String,
	/** 直接指定文案（优先于对应语言键）。 */
	?title:String,
	?message:String,
	?confirmLabel:String,
	?cancelLabel:String,
	?hint:String,
	/** 徽标字形，默认 '!'。 */
	?icon:String,
	/** 危险操作：顶部装饰条 / 徽标 / 主按钮改用红色渐变。 */
	?danger:Bool,
	/** 卡片宽度（像素），默认 520；过宽时自动收窄到屏幕内。 */
	?width:Int
}

/**
 * 编辑器通用确认弹窗（NovaFlare 深色设计规范）。
 *
 * 视觉对齐 `DialogueEditorMenuBar` / `DialogueCharacterEditorMenuBar` 的设计令牌：
 *   - 全屏半透明遮罩 + 居中圆角卡片（1px 半透明白描边 + 投影）
 *   - 卡片顶部 3px 渐变装饰条（常规 indigo→violet；危险操作走红色渐变）
 *   - 左侧渐变圆角徽标（!），右侧标题 + 自动换行正文
 *   - 分隔线下方：左侧快捷键提示，右侧「取消 / 确认」按钮
 *   - 主按钮为渐变实心，取消按钮为描边幽灵按钮，均有 hover / 按下态
 *
 * 交互：鼠标点击按钮；Enter / Y 确认，Esc / X 取消；打开与关闭都有淡入淡出。
 *
 * 兼容性：构造函数第一个参数仍是原来的退出回调，第二个参数（配置）可省略，
 * 因此 StageEditorState 等既有调用点无需修改即可获得新外观与本地化文案。
 */
class ConfirmationPopupSubstate extends MusicBeatSubstate
{
	// ============ 设计令牌（与 *EditorMenuBar 同源）============
	public static final C_TEXT_SEC:FlxColor = 0xFFC9CDD4;   // 次级文字
	static final C_CARD_BG:FlxColor = 0xFF1C1F28;           // 卡片底色
	static final C_CARD_EDGE:FlxColor = 0x26FFFFFF;         // 卡片描边（半透明白）
	static final C_SHADOW:FlxColor = 0x73000000;            // 投影
	static final C_DIVIDER:FlxColor = 0x14FFFFFF;           // 分隔线
	static final C_TEXT_MAIN:FlxColor = 0xFFF2F3F5;         // 主文字
	static final C_TEXT_HINT:FlxColor = 0xFF86909C;         // 提示文字
	static final C_ACCENT_A:FlxColor = 0xFF6366F1;          // 常规渐变起点（indigo）
	static final C_ACCENT_B:FlxColor = 0xFF8B5CF6;          // 常规渐变终点（violet）
	static final C_DANGER_A:FlxColor = 0xFFEF4444;          // 危险渐变起点
	static final C_DANGER_B:FlxColor = 0xFFDC2626;          // 危险渐变终点

	// ============ 布局常量 ============
	public static final BTN_RADIUS:Int = 8;
	static final ACCENT_H:Int = 3;      // 顶部装饰条厚度
	static final PAD:Int = 24;          // 卡片内边距
	static final BADGE:Int = 34;        // 徽标边长
	static final BADGE_GAP:Int = 14;    // 徽标与文本间距
	static final BTN_W:Int = 120;       // 按钮宽
	static final BTN_H:Int = 34;        // 按钮高
	static final BTN_GAP:Int = 10;      // 按钮间距
	static final CARD_RADIUS:Int = 14;
	static final TITLE_SIZE:Int = 17;
	static final BODY_SIZE:Int = 13;
	static final BTN_LABEL_SIZE:Int = 13;
	static final HINT_SIZE:Int = 11;
	static final SCRIM_ALPHA:Float = 0.62;
	static final INTRO_TIME:Float = 0.14;   // 淡入时长（秒）
	static final OUTRO_TIME:Float = 0.09;   // 淡出时长（秒）

	// ============ 运行时状态 ============
	var finishCallback:Void->Void;
	var options:ConfirmDialogOptions;

	var cam:FlxCamera;
	var scrim:FlxSprite;
	var fadeItems:Array<FlxSprite> = [];
	var confirmBtn:ConfirmDialogButton;
	var cancelBtn:ConfirmDialogButton;
	var confirmLabelText:FlxText;
	var cancelLabelText:FlxText;
	var confirmLabelY:Float = 0;
	var cancelLabelY:Float = 0;

	var _title:String = '';
	var _message:String = '';
	var _confirmLabel:String = '';
	var _cancelLabel:String = '';
	var _hint:String = '';
	var _icon:String = '!';
	var _danger:Bool = false;
	var _cardW:Int = 520;

	var _blockInput:Float = 0.14;
	var _intro:Float = 0;
	var _closing:Bool = false;
	var _outro:Float = 1;
	var _pending:Void->Void = null;
	var _mousePoint:FlxPoint = new FlxPoint();

	public function new(?finishCallback:Void->Void, ?options:ConfirmDialogOptions)
	{
		this.finishCallback = finishCallback;
		this.options = options;
		super();
	}

	// ==================== 文案解析 ====================

	/** 读取语言键；缺失（含开发者模式下的 "key (404)"）时返回 def。 */
	static function langText(key:String, group:String, def:String):String
	{
		if (key == null || key == '' || group == null || group == '')
			return def;
		var v:String = null;
		try
		{
			v = Language.get(key, group);
		}
		catch (e:Dynamic)
		{
			v = null;
		}
		if (isMissing(v, key))
			return def;
		return v;
	}

	static function isMissing(v:String, key:String):Bool
	{
		if (v == null || v == '')
			return true;
		if (v == key)
			return true;
		if (StringTools.endsWith(v, ' (404)'))
			return true;
		return false;
	}

	/** 语言键按 langGroup → editors → 内置字面量 的顺序回退。 */
	static function pick(explicit:String, key:String, defaultKey:String, group:String, fallback:String):String
	{
		if (explicit != null && explicit != '')
			return explicit;
		var k:String = (key != null && key != '') ? key : defaultKey;
		var v:String = langText(k, group, null);
		if (v == null)
			v = langText(k, 'editors', null);
		if (v == null)
			v = fallback;
		return v;
	}

	static function isChinese():Bool
	{
		var zh:Bool = false;
		try
		{
			zh = (ClientPrefs.data.language == 'Chinese');
		}
		catch (e:Dynamic) {}
		return zh;
	}

	function resolveText():Void
	{
		var group:String = (options != null && options.langGroup != null) ? options.langGroup : 'editors';
		var zh:Bool = isChinese();

		if (options != null)
		{
			_danger = (options.danger == true);
			if (options.icon != null && options.icon != '')
				_icon = options.icon;
			if (options.width != null && options.width >= 320)
				_cardW = options.width;
		}

		_title = pick(options != null ? options.title : null, options != null ? options.titleKey : null, 'confirm_unsaved_title', group,
			zh ? '未保存的更改' : 'Unsaved changes');

		_message = pick(options != null ? options.message : null, options != null ? options.messageKey : null, 'confirm_unsaved_message', group,
			zh ? '当前编辑器还有未保存的修改，退出后这些改动将会丢失。确定要放弃修改并退出吗？' : 'You have unsaved changes. They will be lost if you leave now. Discard them and exit?');

		_confirmLabel = pick(options != null ? options.confirmLabel : null, options != null ? options.confirmKey : null, 'confirm_btn_confirm', group,
			zh ? '放弃并退出' : 'Discard & Exit');

		_cancelLabel = pick(options != null ? options.cancelLabel : null, options != null ? options.cancelKey : null, 'confirm_btn_cancel', group,
			zh ? '取消' : 'Cancel');

		#if mobile
		_hint = pick(options != null ? options.hint : null, options != null ? options.hintKey : null, 'confirm_hint_touch', group,
			zh ? '轻点按钮进行选择' : 'Tap a button to choose');
		#else
		_hint = pick(options != null ? options.hint : null, options != null ? options.hintKey : null, 'confirm_hint', group,
			zh ? 'Enter / Y 确认  |  Esc 取消' : 'Enter / Y confirm  |  Esc cancel');
		#end
	}

	// ==================== 绘制工具（public static，供本模块按钮复用）====================

	/** 圆角实心矩形精灵（unique 位图，避免污染同尺寸的共享位图）。 */
	public static function makeRoundRect(w:Int, h:Int, radius:Int, color:FlxColor):FlxSprite
	{
		var s:FlxSprite = new FlxSprite(0, 0).makeGraphic(w, h, FlxColor.TRANSPARENT, true);
		FlxSpriteUtil.drawRoundRect(s, 0, 0, w, h, radius, radius, color);
		return s;
	}

	/**
	 * 圆角矩形 + 线性渐变精灵。
	 * 先画白色圆角矩形，再按像素写入渐变，同时保留圆角抗锯齿边缘的 alpha。
	 */
	public static function makeRoundGrad(w:Int, h:Int, radius:Int, c1:FlxColor, c2:FlxColor, horizontal:Bool = false):FlxSprite
	{
		var s:FlxSprite = new FlxSprite(0, 0).makeGraphic(w, h, FlxColor.TRANSPARENT, true);
		FlxSpriteUtil.drawRoundRect(s, 0, 0, w, h, radius, radius, FlxColor.WHITE);
		applyGradient(s, c1, c2, horizontal);
		return s;
	}

	/**
	 * 只有上边两角是圆角的渐变条（用于卡片顶部装饰条）。
	 *
	 * 做法：在 h 只有几个像素的位图上，画一个「高度 = h + 2×radius」的圆角矩形，
	 * 超出位图的下半部分会被 BitmapData.draw 自然裁掉 —— 于是上边两角保留完整圆弧，
	 * 圆弧走向与卡片本体的圆角完全吻合（不会在卡片圆角外露出方角）。
	 */
	public static function makeTopRoundGrad(w:Int, h:Int, radius:Int, c1:FlxColor, c2:FlxColor, horizontal:Bool = false):FlxSprite
	{
		var s:FlxSprite = new FlxSprite(0, 0).makeGraphic(w, h, FlxColor.TRANSPARENT, true);
		FlxSpriteUtil.drawRoundRect(s, 0, 0, w, h + radius * 2, radius, radius, FlxColor.WHITE);
		applyGradient(s, c1, c2, horizontal);
		return s;
	}

	/** 把精灵里所有非透明像素按方向重新着色为 c1→c2 的渐变。 */
	static function applyGradient(s:FlxSprite, c1:FlxColor, c2:FlxColor, horizontal:Bool):Void
	{
		var bd:openfl.display.BitmapData = s.pixels;
		if (bd == null)
			return;
		var w:Int = bd.width;
		var h:Int = bd.height;
		bd.lock();
		for (y in 0...h)
		{
			for (x in 0...w)
			{
				var px:Int = bd.getPixel32(x, y);
				var a:Int = (px >>> 24) & 0xFF;
				if (a == 0)
					continue;
				var t:Float = horizontal ? ((w > 1) ? x / (w - 1) : 0) : ((h > 1) ? y / (h - 1) : 0);
				var rgb:Int = FlxColor.interpolate(c1, c2, t);
				bd.setPixel32(x, y, (a << 24) | (rgb & 0x00FFFFFF));
			}
		}
		bd.unlock();
		s.dirty = true;
	}

	/**
	 * 量出 FlxText 换行后的真实高度。
	 * openfl 的 textHeight 是按 FlxText.renderScale 放大后的像素值，必须除回去。
	 */
	public static function measureTextH(t:FlxText, fallback:Float):Float
	{
		var h:Float = fallback;
		if (t != null && t.textField != null)
		{
			try
			{
				h = t.textField.textHeight / FlxText.renderScale;
			}
			catch (e:Dynamic) {}
		}
		if (h < fallback)
			h = fallback;
		return h;
	}

	// ==================== 构建 ====================

	override function create()
	{
		if (cameras == null || cameras.length == 0)
			cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];
		cam = cameras[cameras.length - 1];

		resolveText();

		var cw:Int = _cardW;
		if (cw > FlxG.width - 40)
			cw = Std.int(FlxG.width - 40);
		if (cw < 320)
			cw = 320;
		var contentW:Int = cw - PAD * 2;
		var textW:Int = contentW - BADGE - BADGE_GAP;
		if (textW < 160)
			textW = 160;

		var font:String = Paths.font(EditorInputStyle.langFontFileName());

		// ---- 先建文本并量高：卡片高度完全由内容决定 ----
		var titleText:FlxText = new FlxText(0, 0, textW, _title, TITLE_SIZE);
		titleText.setFormat(font, TITLE_SIZE, C_TEXT_MAIN, LEFT);
		var titleH:Float = measureTextH(titleText, TITLE_SIZE + 5);

		var hasBody:Bool = (_message != null && _message != '');
		var bodyText:FlxText = null;
		var bodyH:Float = 0;
		if (hasBody)
		{
			bodyText = new FlxText(0, 0, textW, _message, BODY_SIZE);
			bodyText.setFormat(font, BODY_SIZE, C_TEXT_SEC, LEFT);
			bodyH = measureTextH(bodyText, BODY_SIZE + 6) + 10; // +10 = 标题与正文的间距
		}

		var headerH:Float = Math.max(BADGE, titleH);
		var contentTop:Float = ACCENT_H + PAD;
		var dividerY:Float = contentTop + headerH + bodyH + 20;
		var footerTop:Float = dividerY + 1 + 16;
		var cardH:Int = Std.int(footerTop + BTN_H + PAD);

		var cx:Float = Math.round((FlxG.width - cw) / 2);
		var cy:Float = Math.round((FlxG.height - cardH) / 2);

		// ---- 遮罩（吞掉下层编辑器的鼠标事件）----
		scrim = new FlxSprite(-2, -2).makeGraphic(Std.int(FlxG.width) + 4, Std.int(FlxG.height) + 4, FlxColor.BLACK, true);
		scrim.alpha = 0;
		add(scrim);

		// ---- 卡片投影 ----
		var shadow:FlxSprite = makeRoundRect(cw, cardH, CARD_RADIUS, C_SHADOW);
		shadow.x = cx;
		shadow.y = cy + 6;
		regFade(shadow);
		add(shadow);

		// ---- 卡片描边 + 底色（1px 描边 = 外层描边色圆角块 + 内层底色圆角块偏移 1px）----
		var edge:FlxSprite = makeRoundRect(cw, cardH, CARD_RADIUS, C_CARD_EDGE);
		edge.x = cx;
		edge.y = cy;
		regFade(edge);
		add(edge);

		var card:FlxSprite = makeRoundRect(cw - 2, cardH - 2, CARD_RADIUS - 1, C_CARD_BG);
		card.x = cx + 1;
		card.y = cy + 1;
		regFade(card);
		add(card);

		// ---- 顶部渐变装饰条（上圆角与卡片圆角吻合）+ 下方 1px 分隔 ----
		var accentA:FlxColor = _danger ? C_DANGER_A : C_ACCENT_A;
		var accentB:FlxColor = _danger ? C_DANGER_B : C_ACCENT_B;

		var accent:FlxSprite = makeTopRoundGrad(cw - 2, ACCENT_H, CARD_RADIUS - 1, accentA, accentB, true);
		accent.x = cx + 1;
		accent.y = cy + 1;
		regFade(accent);
		add(accent);

		var accentLine:FlxSprite = new FlxSprite(cx + 1, cy + 1 + ACCENT_H).makeGraphic(cw - 2, 1, C_DIVIDER, true);
		regFade(accentLine);
		add(accentLine);

		// ---- 徽标（渐变圆角方块 + 字形）----
		var badge:FlxSprite = makeRoundGrad(BADGE, BADGE, 10, accentA, accentB);
		badge.x = cx + PAD;
		badge.y = cy + contentTop;
		regFade(badge);
		add(badge);

		var icon:FlxText = new FlxText(badge.x, badge.y, BADGE, _icon, 18);
		icon.setFormat(font, 18, FlxColor.WHITE, CENTER);
		icon.y = badge.y + (BADGE - measureTextH(icon, 20)) / 2 - 1;
		regFade(icon);
		add(icon);

		// ---- 标题 / 正文 ----
		var textX:Float = cx + PAD + BADGE + BADGE_GAP;
		titleText.x = textX;
		titleText.y = cy + contentTop;
		regFade(titleText);
		add(titleText);

		if (bodyText != null)
		{
			bodyText.x = textX;
			bodyText.y = cy + contentTop + headerH + 10;
			regFade(bodyText);
			add(bodyText);
		}

		// ---- 分隔线 ----
		var divider:FlxSprite = new FlxSprite(cx + PAD, cy + dividerY).makeGraphic(contentW, 1, C_DIVIDER, true);
		regFade(divider);
		add(divider);

		// ---- 底部按钮（右对齐：取消在左，主操作在右）----
		var btnY:Float = cy + footerTop;
		var confirmX:Float = cx + cw - PAD - BTN_W;
		var cancelX:Float = confirmX - BTN_GAP - BTN_W;

		confirmBtn = new ConfirmDialogButton(confirmX, btnY, BTN_W, BTN_H, true, _danger, doConfirm);
		confirmBtn.cameras = cameras;
		add(confirmBtn);

		cancelBtn = new ConfirmDialogButton(cancelX, btnY, BTN_W, BTN_H, false, false, doCancel);
		cancelBtn.cameras = cameras;
		add(cancelBtn);

		// ★ 按钮文字不放进 ConfirmDialogButton 这个 FlxSpriteGroup 里：
		//   本引擎 tile 渲染下组内 FlxText 不会出图（只出背景块）。
		//   直接挂在 SubState 上（与标题/正文同层），按下时由 update 同步下移 1px。
		confirmLabelText = makeButtonLabel(confirmX, btnY, _confirmLabel, FlxColor.WHITE, font);
		confirmLabelY = confirmLabelText.y;
		regFade(confirmLabelText);
		add(confirmLabelText);

		cancelLabelText = makeButtonLabel(cancelX, btnY, _cancelLabel, C_TEXT_SEC, font);
		cancelLabelY = cancelLabelText.y;
		regFade(cancelLabelText);
		add(cancelLabelText);

		// ---- 快捷键提示（左对齐，与按钮同一行垂直居中）----
		if (_hint != null && _hint != '')
		{
			var hintW:Int = Std.int(cancelX - (cx + PAD) - 14);
			if (hintW < 90)
				hintW = 90;
			var hint:FlxText = new FlxText(cx + PAD, btnY, hintW, _hint, HINT_SIZE);
			hint.setFormat(font, HINT_SIZE, C_TEXT_HINT, LEFT);
			hint.y = btnY + (BTN_H - measureTextH(hint, HINT_SIZE + 4)) / 2;
			regFade(hint);
			add(hint);
		}

		applyFade(0); // 统一从全透明开始，由 update 淡入
		FlxG.mouse.visible = true;
		super.create();
	}

	function regFade(s:FlxSprite):Void
	{
		if (s == null)
			return;
		s.alpha = 0;
		fadeItems.push(s);
	}

	/** 按钮文字：文本域比按钮宽 30px 且向左多伸 15px，长文案不裁切又始终相对按钮居中。 */
	function makeButtonLabel(bx:Float, by:Float, text:String, color:FlxColor, font:String):FlxText
	{
		var t:FlxText = new FlxText(bx - 15, 0, BTN_W + 30, text, BTN_LABEL_SIZE);
		t.setFormat(font, BTN_LABEL_SIZE, color, CENTER);
		t.y = by + (BTN_H - measureTextH(t, BTN_LABEL_SIZE + 4)) / 2;
		return t;
	}

	function applyFade(k:Float):Void
	{
		if (scrim != null)
			scrim.alpha = SCRIM_ALPHA * k;
		for (s in fadeItems)
			if (s != null && s.exists)
				s.alpha = k;
		if (confirmBtn != null)
			confirmBtn.setAlpha(k);
		if (cancelBtn != null)
			cancelBtn.setAlpha(k);
	}

	static inline function easeOutCubic(t:Float):Float
	{
		var u:Float = 1 - t;
		return 1 - u * u * u;
	}

	// ==================== 关闭流程 ====================

	function doConfirm():Void
	{
		requestClose(function()
		{
			FlxG.mouse.visible = false;
			MusicBeatState.switchState(new developer.editors.MasterEditorMenu());
			FlxG.sound.playMusic(Paths.music('freakyMenu'));
			if (finishCallback != null)
				finishCallback();
		});
	}

	function doCancel():Void
	{
		requestClose(function() close());
	}

	/** 先播淡出，动画收尾后再执行动作（避免动画未收就切状态）。 */
	function requestClose(action:Void->Void):Void
	{
		if (_closing || _intro < 1)
			return;
		_closing = true;
		_pending = action;
	}

	// ==================== 每帧 ====================

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		// ---- 淡出 → 执行动作 ----
		if (_closing)
		{
			_outro -= elapsed / OUTRO_TIME;
			if (_outro <= 0)
			{
				_outro = 0;
				applyFade(0);
				var act:Void->Void = _pending;
				_pending = null;
				if (act != null)
					act();
			}
			else
				applyFade(_outro);
			return;
		}

		// ---- 淡入 ----
		if (_intro < 1)
		{
			_intro = Math.min(1, _intro + elapsed / INTRO_TIME);
			applyFade(easeOutCubic(_intro));
		}

		// ---- 鼠标悬停 / 点击（用所在相机的视图坐标，避免主相机缩放导致命中偏移）----
		var mp:FlxPoint = FlxG.mouse.getViewPosition(cam, _mousePoint);
		if (confirmBtn != null)
			confirmBtn.updatePointer(mp.x, mp.y, _intro >= 1);
		if (cancelBtn != null)
			cancelBtn.updatePointer(mp.x, mp.y, _intro >= 1);

		// 按下时文字跟着按钮下移 1px（文字是 SubState 的直接子对象，需手动同步）
		if (confirmLabelText != null && confirmBtn != null)
			confirmLabelText.y = confirmLabelY + (confirmBtn.pressed ? 1 : 0);
		if (cancelLabelText != null && cancelBtn != null)
			cancelLabelText.y = cancelLabelY + (cancelBtn.pressed ? 1 : 0);

		// 入场动画未结束时忽略键盘输入，防止误触
		if (_intro < 1)
			return;

		// ---- 键盘 ----
		_blockInput = Math.max(0, _blockInput - elapsed);
		if (_blockInput > 0)
			return;

		if (FlxG.keys.justPressed.ENTER || FlxG.keys.justPressed.Y)
			doConfirm();
		else if (FlxG.keys.justPressed.ESCAPE || FlxG.keys.justPressed.X)
			doCancel();
	}
}

/**
 * 弹窗按钮底板（本模块内部使用）。
 *
 * 主按钮 = 渐变实心（危险操作走红色渐变）；次按钮 = 描边幽灵按钮。
 * 两者都预生成 idle / hover / press 三套底图，靠 visible 切换，运行时零重绘。
 *
 * ★ 这里**只画底板**，不放文字：本引擎 tile 渲染下 FlxSpriteGroup 里的 FlxText
 *   不会出图（只会画出背景块）。按钮文字由 ConfirmationPopupSubstate 作为
 *   SubState 的直接子对象创建并定位，按下时读 `pressed` 同步下移 1px。
 */
private class ConfirmDialogButton extends FlxSpriteGroup
{
	public var onPress:Void->Void = null;
	/** 当前是否处于按下态（供外部同步按钮文字位置）。 */
	public var pressed(default, null):Bool = false;

	var hitW:Float;
	var hitH:Float;
	var bgIdle:FlxSprite;
	var bgHover:FlxSprite;
	var bgPress:FlxSprite;

	var hovered:Bool = false;

	public function new(x:Float, y:Float, w:Int, h:Int, primary:Bool, danger:Bool, onPress:Void->Void)
	{
		super(x, y);
		this.onPress = onPress;
		hitW = w;
		hitH = h;

		var idleA:FlxColor = danger ? 0xFFEF4444 : 0xFF6366F1;
		var idleB:FlxColor = danger ? 0xFFDC2626 : 0xFF8B5CF6;
		var hovA:FlxColor = danger ? 0xFFDC2626 : 0xFF4F46E5;
		var hovB:FlxColor = danger ? 0xFFB91C1C : 0xFF7C3AED;
		var prsA:FlxColor = danger ? 0xFFB91C1C : 0xFF4338CA;
		var prsB:FlxColor = danger ? 0xFF991B1B : 0xFF6D28D9;

		var r:Int = ConfirmationPopupSubstate.BTN_RADIUS;

		if (primary)
		{
			bgIdle = ConfirmationPopupSubstate.makeRoundGrad(w, h, r, idleA, idleB);
			add(bgIdle);
			bgHover = ConfirmationPopupSubstate.makeRoundGrad(w, h, r, hovA, hovB);
			add(bgHover);
			bgPress = ConfirmationPopupSubstate.makeRoundGrad(w, h, r, prsA, prsB);
			add(bgPress);
		}
		else
		{
			// 幽灵按钮：外层描边圆角块 + 内层底色圆角块（偏移 1px 形成 1px 描边）
			add(ConfirmationPopupSubstate.makeRoundRect(w, h, r, 0x33FFFFFF));
			bgIdle = ConfirmationPopupSubstate.makeRoundRect(w - 2, h - 2, r - 1, 0xFF12141A);
			bgHover = ConfirmationPopupSubstate.makeRoundRect(w - 2, h - 2, r - 1, 0xFF232838);
			bgPress = ConfirmationPopupSubstate.makeRoundRect(w - 2, h - 2, r - 1, 0xFF0C0E13);
			for (s in [bgIdle, bgHover, bgPress])
			{
				s.x = 1;
				s.y = 1;
				add(s);
			}
		}

		refreshState();
	}

	/** 每帧更新悬停 / 按下状态。`active` 为 false 时（入场动画中）不响应鼠标。 */
	public function updatePointer(mx:Float, my:Float, active:Bool):Void
	{
		var inside:Bool = active && mx >= x && mx <= x + hitW && my >= y && my <= y + hitH;

		if (pressed && !FlxG.mouse.pressed)
		{
			pressed = false;
			y -= 1;
		}

		hovered = inside;

		if (inside && FlxG.mouse.justPressed)
		{
			pressed = true;
			y += 1;
			if (onPress != null)
				onPress();
		}

		refreshState();
	}

	function refreshState():Void
	{
		bgIdle.visible = !hovered && !pressed;
		bgHover.visible = hovered && !pressed;
		bgPress.visible = pressed;
	}

	/** 供弹窗做入场淡入：整组一起改透明度。 */
	public function setAlpha(a:Float):Void
	{
		for (m in members)
			if (m != null)
				m.alpha = a;
	}
}
