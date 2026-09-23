package options.objects.others;

/**
 * 面板标题栏右上角的重置按钮。
 *
 * ★ 外观对齐 web 原型标题栏右上那枚幽灵按钮（原型里是 `.pclose`）：
 *   background:rgba(255,255,255,.035) + 1px 描边 + 暗灰文字（--dim #9BA1B8），
 *   悬停时才泛起强调色（rgba(255,144,220,.16) + 白字）。
 *   以前这里画的是 `OptionsState.mainColor` + alpha 1 —— 一整块实心深色板，
 *   在标题栏里比分类名还抢眼（用户："数据重置这四个字未免太显眼了"）。
 */
class ResetButton extends FlxSpriteGroup
{
	/** 常态底色（原型 .pclose 的 .035，这里给到 .045 保证在深底上能看出边界） */
	inline static var IDLE_BG:Float = 0.045;
	/** 悬停底色（原型 .pclose:hover） */
	inline static var HOVER_BG:Float = 0.16;
	/** 二次确认时的底色（同族强调色） */
	inline static var CONFIRM_BG:Float = 0.22;
	inline static var IDLE_TEXT:Int = 0x9BA1B8;
	inline static var HOVER_TEXT:Int = 0xFFFFFF;
	inline static var CONFIRM_TINT:Int = 0xFF90DC;

	var rect:Rect;
	var text:FlxText;

	/** 当前的底色 alpha（由悬停/确认状态决定，再乘上淡入淡出系数） */
	var bgAlpha:Float = IDLE_BG;
	/** 内容整体淡入淡出系数 */
	var fade:Float = 1;

	var waitingForConfirm:Bool = false;
	var confirmTimer:Float = 0;

	public function new(x:Float, y:Float, width:Float, height:Float)
	{
		super(x, y);

		rect = new Rect(0, 0, width, height, height / 3, height / 3, 0xFFFFFF, IDLE_BG);
		add(rect);

		text = new FlxText(0, 0, 0, Language.get('Reset'), Std.int(height * 0.44));
		text.font = Paths.font(Language.get('fontName', 'main') + '.ttf');
		text.antialiasing = ClientPrefs.data.antialiasing;
		text.color = IDLE_TEXT;
		text.x += rect.width / 2 - text.width / 2;
		text.y += rect.height / 2 - text.height / 2;
		add(text);
	}

	public var onFocus:Bool = false;

	/**
	 * 内容淡入淡出。
	 * ★ 不要用 `FlxTween.tween(this, {alpha: v})` —— FlxSpriteGroup 的 alpha 会把
	 *   变化比例乘到子元素上，还会把 alpha==0 的子元素写成 1/比例，一块 0.045 的
	 *   底板会被放大成不透明的白块（详见 Option.setFade 的长注释）。
	 */
	public function setFade(v:Float):Void
	{
		fade = v;
		rect.alpha = bgAlpha * v;
		text.alpha = v;
	}

	function getConfirmText():String
	{
		var t = Language.get('ResetConfirm', 'options');
		// Fallback if translation key doesn't exist
		if (t == 'ResetConfirm' || t == 'ResetConfirm (404)')
			t = 'Sure?';
		return t;
	}

	function getResetText():String
	{
		return Language.get('Reset');
	}

	function updateTextDisplay(newText:String)
	{
		text.text = newText;
		text.x = rect.x + rect.width / 2 - text.width / 2;
		text.y = rect.y + rect.height / 2 - text.height / 2;
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		var mouse = OptionsState.instance.mouseEvent;

		onFocus = mouse.overlaps(this);

		if (waitingForConfirm)
		{
			confirmTimer += elapsed;
			if (confirmTimer > 2.0)
			{
				waitingForConfirm = false;
				confirmTimer = 0;
				updateTextDisplay(getResetText());
			}
		}

		if (onFocus)
		{
			rect.color = waitingForConfirm ? CONFIRM_TINT : 0xFFFFFF;
			bgAlpha = waitingForConfirm ? CONFIRM_BG : HOVER_BG;
			text.color = HOVER_TEXT;
			if (mouse.justReleased)
			{
				if (!waitingForConfirm)
				{
					waitingForConfirm = true;
					confirmTimer = 0;
					updateTextDisplay(getConfirmText());
				}
				else
				{
					waitingForConfirm = false;
					confirmTimer = 0;
					updateTextDisplay(getResetText());
					OptionsState.instance.resetData();
				}
			}
		}
		else
		{
			rect.color = 0xFFFFFF;
			bgAlpha = IDLE_BG;
			text.color = IDLE_TEXT;
			if (waitingForConfirm)
			{
				waitingForConfirm = false;
				confirmTimer = 0;
				updateTextDisplay(getResetText());
			}
		}

		rect.alpha = bgAlpha * fade;
	}

	public function changeLanguage()
	{
		waitingForConfirm = false;
		confirmTimer = 0;
		text.text = Language.get('Reset');
		text.setFormat(Paths.font(Language.get('fontName', 'main') + '.ttf'), Std.int(rect.height * 0.44), IDLE_TEXT);
		text.borderStyle = NONE;
		text.antialiasing = ClientPrefs.data.antialiasing;
		text.x = rect.x + rect.width / 2 - text.width / 2;
		text.y = rect.y + rect.height / 2 - text.height / 2;
	}
}
