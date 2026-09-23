package developer.editors;

import flixel.util.FlxAxes;

/**
 * 通用确认弹窗（桌面端操作前警告）。
 * 按键：空格 / Enter / Y = 确认；X / Esc = 取消。
 * 也可用鼠标点击按钮。
 */
class StageEditorConfirmSubstate extends MusicBeatSubstate
{
	var bg:FlxSprite;
	var confirmCallback:Void->Void;
	var blockInput:Float = 0.25;

	public function new(message:String, confirmCallback:Void->Void = null)
	{
		this.confirmCallback = confirmCallback;
		super();
		_message = message;
	}

	var _message:String;

	override function create()
	{
		cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];

		var bg:FlxSprite = new FlxSprite().makeGraphic(1, 1, FlxColor.BLACK);
		bg.alpha = 0.7;
		bg.scale.set(460, 170);
		bg.updateHitbox();
		bg.screenCenter();
		add(bg);

		var txt:FlxText = new FlxText(0, bg.y + 26, 430, _message, 16);
		txt.screenCenter(X);
		txt.alignment = CENTER;
		txt.setFormat(Paths.font(Language.get('fontName', 'main') + '.ttf'), 16, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		add(txt);

		var hint:FlxText = new FlxText(0, bg.y + 78, 430, '空格 / Enter / Y - 确认     X / Esc - 取消', 12);
		hint.screenCenter(X);
		hint.alignment = CENTER;
		hint.setFormat(Paths.font(Language.get('fontName', 'main') + '.ttf'), 12, 0xFF9A9A9A, CENTER);
		add(hint);

		var btnY:Float = bg.y + 105;
		var confirmBtn:PsychUIButton = new PsychUIButton(0, btnY, 'Confirm', function()
		{
			doConfirm();
		});
		confirmBtn.normalStyle.bgColor = FlxColor.RED;
		confirmBtn.normalStyle.textColor = FlxColor.WHITE;
		confirmBtn.screenCenter(X);
		confirmBtn.x -= 110;
		confirmBtn.cameras = cameras;
		add(confirmBtn);

		var cancelBtn:PsychUIButton = new PsychUIButton(0, btnY, 'Cancel', function() close());
		cancelBtn.screenCenter(X);
		cancelBtn.x += 110;
		cancelBtn.cameras = cameras;
		add(cancelBtn);

		super.create();
	}

	function doConfirm():Void
	{
		close();
		if (confirmCallback != null)
			confirmCallback();
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		blockInput = Math.max(0, blockInput - elapsed);
		if (blockInput > 0)
			return;

		// 确认：空格 / Enter / Y
		if (FlxG.keys.justPressed.SPACE || FlxG.keys.justPressed.ENTER || FlxG.keys.justPressed.Y)
			doConfirm();
		// 取消：X / Esc
		else if (FlxG.keys.justPressed.X || FlxG.keys.justPressed.ESCAPE)
			close();
	}
}
