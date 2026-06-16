package options.objects.others;

class ResetButton extends FlxSpriteGroup
{
	var rect:Rect;
	var text:FlxText;

	var waitingForConfirm:Bool = false;
	var confirmTimer:Float = 0;

	public function new(x:Float, y:Float, width:Float, height:Float)
	{
		super(x, y);

		rect = new Rect(0, 0, width, height, height / 5, height / 5, OptionsState.instance.mainColor, 1);
		add(rect);

		text = new FlxText(0, 0, 0, Language.get('Reset'), 25);
		text.font = Paths.font(Language.get('fontName', 'main') + '.ttf');
		text.antialiasing = ClientPrefs.data.antialiasing;
		text.y += rect.height / 2 - text.height / 2;
		text.x += rect.width / 2 - text.width / 2;
		add(text);

	}

	public var onFocus:Bool = false;

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
			rect.color = EngineSet.mainColor;
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
			rect.color = OptionsState.instance.mainColor;
			if (waitingForConfirm)
			{
				waitingForConfirm = false;
				confirmTimer = 0;
				updateTextDisplay(getResetText());
			}
		}
	}

	public function changeLanguage() {
		waitingForConfirm = false;
		confirmTimer = 0;
		text.text = Language.get('Reset');
		text.font = Paths.font(Language.get('fontName', 'main') + '.ttf');
	}
}