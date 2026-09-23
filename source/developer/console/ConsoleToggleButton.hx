package developer.console;

import general.backend.ClientPrefs;
import general.backend.Paths;
import openfl.Lib;
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.events.MouseEvent;
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.text.TextFormatAlign;
import openfl.ui.Mouse;
import openfl.ui.MouseCursor;

/**
 * 右上角的 LOG 悬浮按钮（点击展开 Trace Console）。
 *
 * 支持按住拖动：拖动结束会记住位置（ClientPrefs.consoleButtonX/Y），
 * 下次显示/启动都停在你放的位置；点击（位移很小）才展开控制台。
 */
class ConsoleToggleButton extends Sprite {
	public static var instance(get, null):ConsoleToggleButton;

	private static inline var WIDTH:Float = 68;
	private static inline var HEIGHT:Float = 28;
	/** 拖动与点击的判定阈值（stage 像素） */
	private static inline var DRAG_THRESHOLD:Float = 5;

	private static var _instance:ConsoleToggleButton = null;
	private var label:TextField;
	private var labelFormat:TextFormat;
	private var hovering:Bool = false;

	private var isDragging:Bool = false;
	private var downStageX:Float = 0;
	private var downStageY:Float = 0;
	private var movedBeyondThreshold:Bool = false;

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
		labelFormat = new TextFormat(Paths.font("Lang-ZH.ttf"), 12, 0xF4F7FA, true);
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

		addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
		addEventListener(MouseEvent.CLICK, onClick);
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
		if (!ClientPrefs.data.developerMode || Console.isVisible()) {
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
			stage.removeEventListener(MouseEvent.MOUSE_MOVE, dragButton);
			stage.removeEventListener(MouseEvent.MOUSE_UP, stopDragButton);
		}
	}

	private function onStageResize(_:Event):Void {
		// 窗口大小变化时只保证按钮不跑出屏幕；用户拖过的位置尽量保留
		clampToStage();
	}

	private function onMouseDown(event:MouseEvent):Void {
		isDragging = true;
		movedBeyondThreshold = false;
		downStageX = event.stageX;
		downStageY = event.stageY;
		stage.addEventListener(MouseEvent.MOUSE_MOVE, dragButton);
		stage.addEventListener(MouseEvent.MOUSE_UP, stopDragButton);
		event.stopPropagation();
	}

	private function dragButton(event:MouseEvent):Void {
		if (!isDragging) return;
		var dx:Float = event.stageX - downStageX;
		var dy:Float = event.stageY - downStageY;
		if (!movedBeyondThreshold && Math.sqrt(dx * dx + dy * dy) < DRAG_THRESHOLD) return;

		movedBeyondThreshold = true;
		x = event.stageX - WIDTH / 2;
		y = event.stageY - HEIGHT / 2;
		clampToStage();
	}

	private function stopDragButton(event:MouseEvent):Void {
		if (!isDragging) return;
		isDragging = false;
		stage.removeEventListener(MouseEvent.MOUSE_MOVE, dragButton);
		stage.removeEventListener(MouseEvent.MOUSE_UP, stopDragButton);
		event.stopPropagation();

		// 拖动结束后记住位置（-1 表示未自定义；这里存实际坐标，0..stage 内）
		if (movedBeyondThreshold) {
			ClientPrefs.data.consoleButtonX = x;
			ClientPrefs.data.consoleButtonY = y;
			savePrefs();
			hovering = false;
		}
	}

	private function onClick(_:MouseEvent):Void {
		// 拖过就不算点击
		if (movedBeyondThreshold) return;
		Console.show();
	}

	private function clampToStage():Void {
		if (Lib.current == null || Lib.current.stage == null) return;
		var sw:Float = Lib.current.stage.stageWidth;
		var sh:Float = Lib.current.stage.stageHeight;
		x = Math.max(4, Math.min(sw - WIDTH - 4, x));
		y = Math.max(4, Math.min(sh - HEIGHT - 4, y));
	}

	private function updatePosition():Void {
		if (Lib.current == null || Lib.current.stage == null) return;

		if (ClientPrefs.data.consoleButtonX >= 0 && ClientPrefs.data.consoleButtonY >= 0) {
			// 用户拖过：停在记忆位置（并夹在屏幕内）
			x = ClientPrefs.data.consoleButtonX;
			y = ClientPrefs.data.consoleButtonY;
			clampToStage();
			return;
		}

		// 默认右上角（hotfix：移动端留出圆角/刘海安全距离）
		x = Lib.current.stage.stageWidth - WIDTH - #if mobile 50 #else 14 #end;
		y = #if mobile 50 #else 14 #end;
	}

	private static function savePrefs():Void {
		try {
			ClientPrefs.saveSettings();
		} catch (e:Dynamic) {}
	}

	private function redraw():Void {
		graphics.clear();
		graphics.beginFill(hovering ? 0x355A6D : 0x243746, hovering ? 0.96 : 0.88);
		graphics.drawRoundRect(0, 0, WIDTH, HEIGHT, 6, 6);
		graphics.endFill();
		graphics.lineStyle(1, 0x8BD3FF, hovering ? 0.55 : 0.25);
		graphics.drawRoundRect(0.5, 0.5, WIDTH - 1, HEIGHT - 1, 6, 6);
	}
}
