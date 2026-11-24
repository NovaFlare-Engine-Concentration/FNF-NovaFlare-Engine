package developer.console;

import openfl.Lib;
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.events.MouseEvent;
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.text.TextFormatAlign;
import openfl.ui.Mouse;
import openfl.ui.MouseCursor;

class ConsoleToggleButton extends Sprite {
	public static var instance(get, null):ConsoleToggleButton;

	private static inline var WIDTH:Float = 68;
	private static inline var HEIGHT:Float = 28;

	private static var _instance:ConsoleToggleButton = null;
	private var label:TextField;
	private var labelFormat:TextFormat;
	private var hovering:Bool = false;

	private static function get_instance():ConsoleToggleButton {
		if (_instance == null) {
			_instance = new ConsoleToggleButton();
		}
		return _instance;
	}

	public function new() {
		super();

		buttonMode = true;
		useHandCursor = true;
		mouseChildren = false;
		visible = false;

		label = new TextField();
		labelFormat = new TextFormat(Console.theme.font, 12, 0xF4F7FA, true);
		labelFormat.align = TextFormatAlign.CENTER;
		label.defaultTextFormat = labelFormat;
		label.text = "LOG";
		label.x = 0;
		label.y = Math.max(0, (HEIGHT - 19) / 2);
		label.width = WIDTH;
		label.height = HEIGHT;
		label.selectable = false;
		label.mouseEnabled = false;
		label.setTextFormat(labelFormat);
		addChild(label);

		redraw();
		updatePosition();

		addEventListener(MouseEvent.CLICK, function(_) Console.show());
		addEventListener(MouseEvent.MOUSE_OVER, function(_) {
			hovering = true;
			Mouse.cursor = MouseCursor.BUTTON;
			redraw();
		});
		addEventListener(MouseEvent.MOUSE_OUT, function(_) {
			hovering = false;
			Mouse.cursor = MouseCursor.AUTO;
			redraw();
		});
		addEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
		addEventListener(Event.REMOVED_FROM_STAGE, onRemovedFromStage);
	}

	public static function show():Void {
		if (!Console.isAvailable() || Console.isVisible()) {
			hide();
			return;
		}

		instance.visible = true;
		instance.updatePosition();
	}

	public static function hide():Void {
		if (_instance != null) {
			_instance.visible = false;
		}
	}

	private function onAddedToStage(_:Event):Void {
		stage.addEventListener(Event.RESIZE, onStageResize);
		updatePosition();
	}

	private function onRemovedFromStage(_:Event):Void {
		if (stage != null) {
			stage.removeEventListener(Event.RESIZE, onStageResize);
		}
	}

	private function onStageResize(_:Event):Void {
		updatePosition();
	}

	private function updatePosition():Void {
		if (Lib.current == null || Lib.current.stage == null) return;
		x = Lib.current.stage.stageWidth - WIDTH - #if mobile 50 #else 14 #end;
		y = #if mobile 50 #else 14 #end;
	}

	private function redraw():Void {
		graphics.clear();
		graphics.beginFill(hovering ? Console.theme.launcherHover : Console.theme.launcher, hovering ? 0.96 : 0.88);
		graphics.drawRoundRect(0, 0, WIDTH, HEIGHT, 6, 6);
		graphics.endFill();
		graphics.lineStyle(1, Console.theme.launcherBorder, hovering ? 0.55 : 0.25);
		graphics.drawRoundRect(0.5, 0.5, WIDTH - 1, HEIGHT - 1, 6, 6);
	}
}
