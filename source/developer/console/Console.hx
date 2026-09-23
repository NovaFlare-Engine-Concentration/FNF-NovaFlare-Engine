package developer.console;

import general.backend.ClientPrefs;
import general.backend.Paths;
import haxe.Timer;
import lime.system.Clipboard;
import openfl.Lib;
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.events.KeyboardEvent;
import openfl.events.MouseEvent;
import openfl.geom.Rectangle;
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.text.TextFormatAlign;
import openfl.ui.Mouse;
import openfl.ui.MouseCursor;

private typedef ConsoleLogLine = {
	var time:Float;
	var level:String;
	var message:String;
	var color:Int;
	var match:String;
	var html:Null<String>;
}

class Console extends Sprite {
	public static var consoleInstance(get, null):Console;

	private static inline var HEADER_HEIGHT:Float = 34;
	private static inline var TOOLBAR_HEIGHT:Float = 36;
	private static inline var STATUS_HEIGHT:Float = 24;
	private static inline var PADDING:Float = 10;
	private static inline var SCROLLBAR_WIDTH:Float = 9;
	private static inline var MIN_WIDTH:Float = 420;
	private static inline var MIN_HEIGHT:Float = 260;
	private static inline var MAX_PENDING_LINES:Int = 5000;
	private static inline var MAX_LINES:Int = 1500;
	private static inline var MAX_DRAIN_PER_FRAME:Int = 350;
	private static inline var RENDER_INTERVAL:Float = 0.05;

	private static inline var KEY_ESCAPE:Int = 27;
	private static inline var KEY_F10:Int = 121;
	private static inline var KEY_GRAVE:Int = 192;

	private static var _consoleInstance:Console = null;
	private static var pendingLines:Array<ConsoleLogLine> = [];

	#if sys
	private static var pendingLock:sys.thread.Mutex = new sys.thread.Mutex();
	#end

	private var titleBar:Sprite;
	private var titleLabel:TextField;
	private var output:TextField;
	private var statusLabel:TextField;
	private var scrollTrack:Sprite;
	private var scrollThumb:Sprite;
	private var resizeHandle:Sprite;

	private var pauseButton:ConsoleButton;
	private var autoButton:ConsoleButton;
	private var clearButton:ConsoleButton;
	private var copyButton:ConsoleButton;
	private var maxButton:ConsoleButton;
	private var closeButton:ConsoleButton;

	private var lines:Array<ConsoleLogLine> = [];
	private var shownLines:Int = 0;
	private var currentWidth:Float = 720;
	private var currentHeight:Float = 390;
	private var normalBounds:Rectangle = new Rectangle();
	private var captureEnabled:Bool = true;
	private var autoScroll:Bool = true;
	private var isDragging:Bool = false;
	private var isResizing:Bool = false;
	private var isDraggingScroll:Bool = false;
	private var isMaximized:Bool = false;
	private var dragOffsetX:Float = 0;
	private var dragOffsetY:Float = 0;
	private var resizeStartX:Float = 0;
	private var resizeStartY:Float = 0;
	private var resizeStartWidth:Float = 0;
	private var resizeStartHeight:Float = 0;
	private var scrollDragStartY:Float = 0;
	private var scrollDragStartV:Int = 1;
	private var needsRender:Bool = true;
	private var lastRenderTime:Float = 0;
	private var statusOverride:String = "";
	private var statusOverrideUntil:Float = 0;

	private static function get_consoleInstance():Console {
		if (_consoleInstance == null) {
			_consoleInstance = new Console();
		}
		return _consoleInstance;
	}

	public static function log(message:String):Void {
		logLevel("INFO", message, 0xD7E1EA);
	}

	public static function logWithColoredHead(head:String, message:String, color:Int):Void {
		logLevel(normalizeLevel(head), message, color);
	}

	public static function logLevel(level:String, message:String, color:Int):Void {
		queueLine(level, message, color);
	}

	public static function show():Void {
		if (!ClientPrefs.data.developerMode) return;

		var console = consoleInstance;
		console.visible = true;
		// Logs keep batching while the panel is hidden, but their expensive
		// TextField HTML representation is built only when the user opens it.
		console.needsRender = true;
		console.updateScale(resolveDevConScale());
		console.applySavedPrefs();
		console.clampToStage();

		ConsoleToggleButton.hide();
	}

	public static function refreshScaleFromPrefs():Void {
		if (_consoleInstance == null) return;
		_consoleInstance.updateScale(resolveDevConScale());
	}

	public static function hide():Void {
		if (_consoleInstance != null) {
			_consoleInstance.visible = false;
			if (ClientPrefs.data.developerMode) {
				ConsoleToggleButton.show();
			}
		}
	}

	public static function isVisible():Bool {
		return _consoleInstance != null && _consoleInstance.visible;
	}

	public static function toggle():Void {
		if (isVisible()) hide();
		else show();
	}

	public function new() {
		super();

		scaleX = scaleY = normalizeScale(resolveDevConScale());
		pickInitialSize();
		createUI();
		redraw();
		visible = false;

		addEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
		addEventListener(Event.REMOVED_FROM_STAGE, onRemovedFromStage);
	}

	public function updateScale(newScale:Float):Void {
		newScale = normalizeScale(newScale);
		var actualWidth = currentWidth * scaleX;
		var actualHeight = currentHeight * scaleY;

		scaleX = scaleY = newScale;

		if (isMaximized) {
			fillStage();
		} else {
			currentWidth = Math.max(MIN_WIDTH, actualWidth / newScale);
			currentHeight = Math.max(MIN_HEIGHT, actualHeight / newScale);
			clampSizeToStage();
			clampToStage();
			redraw();
		}
	}

	private static function queueLine(level:String, message:String, color:Int):Void {
		var cleanLevel = normalizeLevel(level);
		var cleanMessage = Std.string(message);
		var line:ConsoleLogLine = {
			time: Date.now().getTime(),
			level: cleanLevel,
			message: cleanMessage,
			color: color,
			match: (cleanLevel + " " + cleanMessage).toLowerCase(),
			html: null
		};

		#if sys
		pendingLock.acquire();
		#end

		pendingLines.push(line);
		if (pendingLines.length > MAX_PENDING_LINES) {
			pendingLines.splice(0, pendingLines.length - MAX_PENDING_LINES);
		}

		#if sys
		pendingLock.release();
		#end
	}

	private static function takePending(max:Int):Array<ConsoleLogLine> {
		#if sys
		pendingLock.acquire();
		#end

		var amount = pendingLines.length > max ? max : pendingLines.length;
		var result = amount > 0 ? pendingLines.splice(0, amount) : [];

		#if sys
		pendingLock.release();
		#end

		return result;
	}

	private static function clearPending():Void {
		#if sys
		pendingLock.acquire();
		#end

		pendingLines = [];

		#if sys
		pendingLock.release();
		#end
	}

	private static function normalizeLevel(value:String):String {
		if (value == null || value.length == 0) return "INFO";
		var level = StringTools.trim(value);
		while (StringTools.endsWith(level, ":")) {
			level = StringTools.trim(level.substr(0, level.length - 1));
		}
		return level.length == 0 ? "INFO" : level.toUpperCase();
	}

	private static function normalizeScale(value:Float):Float {
		if (Math.isNaN(value) || !Math.isFinite(value) || value <= 0) return 1;
		return Math.max(0.5, Math.min(3, value));
	}

	private static function resolveDevConScale():Float {
		var fallbackScale:Float = #if mobile 1.8 #else 1.5 #end;
		if (ClientPrefs.data == null) return fallbackScale;

		var raw:Dynamic = Reflect.field(ClientPrefs.data, "devConScale");
		var parsed = Std.parseFloat(Std.string(raw));
		if (Math.isNaN(parsed) || !Math.isFinite(parsed)) return fallbackScale;
		return parsed;
	}

	private function pickInitialSize():Void {
		var sw = stageWidth();
		var sh = stageHeight();
		currentWidth = Math.max(MIN_WIDTH, Math.min(820, (sw - 48) / scaleX));
		currentHeight = Math.max(MIN_HEIGHT, Math.min(440, (sh - 88) / scaleY));
		x = Math.max(16, sw - currentWidth * scaleX - 24);
		y = Math.max(42, Math.min(72, sh - currentHeight * scaleY - 16));
		normalBounds.setTo(x, y, currentWidth, currentHeight);
	}

	/** 恢复用户上次拖动/缩放后的位置尺寸（未自定义则保持默认） */
	private function applySavedPrefs():Void {
		if (isMaximized) return;

		var savedX:Float = ClientPrefs.data.consoleX;
		var savedY:Float = ClientPrefs.data.consoleY;
		var savedW:Float = ClientPrefs.data.consoleW;
		var savedH:Float = ClientPrefs.data.consoleH;
		if (savedX >= 0 && savedY >= 0) {
			x = savedX;
			y = savedY;
		}
		if (savedW >= MIN_WIDTH && savedH >= MIN_HEIGHT) {
			currentWidth = savedW;
			currentHeight = savedH;
		}
		clampSizeToStage();
		normalBounds.setTo(x, y, currentWidth, currentHeight);
		redraw();
		needsRender = true;
	}

	private function saveWindowPrefs():Void {
		try {
			ClientPrefs.data.consoleX = x;
			ClientPrefs.data.consoleY = y;
			ClientPrefs.data.consoleW = currentWidth;
			ClientPrefs.data.consoleH = currentHeight;
			ClientPrefs.saveSettings();
		} catch (e:Dynamic) {}
	}

	private function createUI():Void {
		titleBar = new Sprite();
		addChild(titleBar);

		titleLabel = makeTextField(14, 0xF4F7FA, true);
		titleLabel.text = "Trace Console";
		titleLabel.mouseEnabled = false;
		titleBar.addChild(titleLabel);

		maxButton = new ConsoleButton("Max", 46, 22, 0x426D4F);
		maxButton.addEventListener(MouseEvent.CLICK, function(_) toggleMaximize());
		addChild(maxButton);

		closeButton = new ConsoleButton("Hide", 52, 22, 0x7D3F3F);
		closeButton.addEventListener(MouseEvent.CLICK, function(_) hide());
		addChild(closeButton);

		pauseButton = new ConsoleButton("Pause", 64, 24, 0x46586C);
		pauseButton.addEventListener(MouseEvent.CLICK, function(_) toggleCapture());
		addChild(pauseButton);

		autoButton = new ConsoleButton("Auto", 58, 24, 0x426D4F);
		autoButton.addEventListener(MouseEvent.CLICK, function(_) toggleAutoScroll());
		addChild(autoButton);

		clearButton = new ConsoleButton("Clear", 58, 24, 0x5C4A68);
		clearButton.addEventListener(MouseEvent.CLICK, function(_) clearLogs());
		addChild(clearButton);

		copyButton = new ConsoleButton("Copy", 56, 24, 0x3F6678);
		copyButton.addEventListener(MouseEvent.CLICK, function(_) copyVisibleLogs());
		addChild(copyButton);

		output = makeTextField(13, 0xD7E1EA, false);
		output.multiline = true;
		output.wordWrap = true;
		output.selectable = true;
		output.background = true;
		output.backgroundColor = 0x0B1015;
		output.border = true;
		output.borderColor = 0x2D3540;
		output.addEventListener(MouseEvent.MOUSE_WHEEL, onOutputWheel);
		addChild(output);

		scrollTrack = new Sprite();
		scrollTrack.addEventListener(MouseEvent.MOUSE_DOWN, onScrollTrackDown);
		addChild(scrollTrack);

		scrollThumb = new Sprite();
		scrollThumb.buttonMode = true;
		scrollThumb.useHandCursor = true;
		scrollThumb.addEventListener(MouseEvent.MOUSE_DOWN, startScrollDrag);
		scrollThumb.addEventListener(MouseEvent.MOUSE_OVER, function(_) Mouse.cursor = MouseCursor.HAND);
		scrollThumb.addEventListener(MouseEvent.MOUSE_OUT, function(_) if (!isDraggingScroll) Mouse.cursor = MouseCursor.AUTO);
		addChild(scrollThumb);

		statusLabel = makeTextField(12, 0x9CA9B6, false);
		statusLabel.mouseEnabled = false;
		addChild(statusLabel);

		resizeHandle = new Sprite();
		resizeHandle.buttonMode = true;
		resizeHandle.useHandCursor = true;
		resizeHandle.addEventListener(MouseEvent.MOUSE_DOWN, startResize);
		resizeHandle.addEventListener(MouseEvent.MOUSE_OVER, function(_) Mouse.cursor = MouseCursor.HAND);
		resizeHandle.addEventListener(MouseEvent.MOUSE_OUT, function(_) if (!isResizing) Mouse.cursor = MouseCursor.AUTO);
		addChild(resizeHandle);

		titleBar.addEventListener(MouseEvent.MOUSE_DOWN, startDragWindow);
	}

	private function makeTextField(size:Int, color:Int, bold:Bool):TextField {
		var field = new TextField();
		field.defaultTextFormat = new TextFormat(Paths.font("Lang-ZH.ttf"), size, color, bold);
		field.embedFonts = false;
		field.selectable = false;
		return field;
	}

	private function onAddedToStage(_:Event):Void {
		stage.addEventListener(Event.RESIZE, onStageResize);
		stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
		addEventListener(Event.ENTER_FRAME, onEnterFrame);
		clampToStage();
		redraw();
	}

	private function onRemovedFromStage(_:Event):Void {
		if (stage != null) {
			stage.removeEventListener(Event.RESIZE, onStageResize);
			stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
			stage.removeEventListener(MouseEvent.MOUSE_MOVE, dragWindow);
			stage.removeEventListener(MouseEvent.MOUSE_UP, stopDragWindow);
			stage.removeEventListener(MouseEvent.MOUSE_MOVE, resizeWindow);
			stage.removeEventListener(MouseEvent.MOUSE_UP, stopResize);
			stage.removeEventListener(MouseEvent.MOUSE_MOVE, dragScrollThumb);
			stage.removeEventListener(MouseEvent.MOUSE_UP, stopScrollDrag);
		}
		removeEventListener(Event.ENTER_FRAME, onEnterFrame);
	}

	private function onEnterFrame(_:Event):Void {
		// The console remains on the display list while hidden. Polling its
		// pending queue took two mutexes plus a native timer call on every game
		// frame even when there was no log traffic. Hidden logs tolerate a short
		// batching delay; a visible console is polled more aggressively.
		pollFrame++;
		if (pollFrame < (visible ? 4 : 32)) return;
		pollFrame = 0;

		var drained = drainPending();
		if (drained) needsRender = true;
		// The console intentionally stays on the display list so its global
		// keyboard toggle keeps working. Do not rebuild a 1500-line HTML
		// TextField while it is hidden. On large gameplay heaps, htmlEscape's
		// temporary StringBuf also used to trigger thousands of late native pins
		// and repeatedly stop the world in NovaGC.
		if (!visible) return;

		var now = Timer.stamp();
		if (needsRender && (now - lastRenderTime >= RENDER_INTERVAL || !hasPending())) {
			renderLogs();
		} else if (statusOverride.length > 0 && now > statusOverrideUntil) {
			statusOverride = "";
			updateStatus();
		}
	}

	private var pollFrame:Int = 0;

	private function drainPending():Bool {
		var incoming = takePending(MAX_DRAIN_PER_FRAME);
		if (incoming.length == 0) return false;

		if (!captureEnabled) return true;

		for (line in incoming) {
			lines.push(line);
		}

		if (lines.length > MAX_LINES) {
			lines.splice(0, lines.length - MAX_LINES);
		}

		return true;
	}

	private function hasPending():Bool {
		#if sys
		pendingLock.acquire();
		#end

		var result = pendingLines.length > 0;

		#if sys
		pendingLock.release();
		#end

		return result;
	}

	private function renderLogs():Void {
		needsRender = false;
		lastRenderTime = Timer.stamp();

		var oldScroll = output.scrollV;
		var html = new StringBuf();
		var first = true;
		shownLines = 0;

		for (line in lines) {
			if (!first) html.add("<br/>");
			html.add(lineToHtml(line));
			first = false;
			shownLines++;
		}

		output.htmlText = html.toString();
		if (autoScroll) {
			output.scrollV = output.maxScrollV;
		} else {
			output.scrollV = clampInt(oldScroll, 1, output.maxScrollV > 1 ? output.maxScrollV : 1);
		}

		updateScrollBar();
		updateStatus();
	}

	private function lineToHtml(line:ConsoleLogLine):String {
		if (line.html == null) {
			line.html = '<font color="#6F7B86">${formatTime(line.time)}</font> '
			+ '<font color="#${StringTools.hex(line.color, 6)}">[${escapeHtml(line.level)}]</font> '
				+ escapeMessage(line.message);
		}
		return line.html;
	}

	private function lineToPlain(line:ConsoleLogLine):String {
		return '${formatTime(line.time)} [${line.level}] ${line.message}';
	}

	private function escapeMessage(value:String):String {
		var escaped = escapeHtml(value);
		escaped = StringTools.replace(escaped, "\r\n", "\n");
		escaped = StringTools.replace(escaped, "\r", "\n");
		return StringTools.replace(escaped, "\n", "<br/>");
	}

	private function escapeHtml(value:String):String {
		// StringTools.htmlEscape builds an Array<Char> and turns it into a native
		// pointer on cpp. A movable NovaGC buffer must then be isolated and every
		// inbound reference remapped. The console needs only these five HTML
		// entities, so replacement avoids that native pin path entirely.
		var escaped = value == null ? "" : value;
		escaped = StringTools.replace(escaped, "&", "&amp;");
		escaped = StringTools.replace(escaped, "<", "&lt;");
		escaped = StringTools.replace(escaped, ">", "&gt;");
		escaped = StringTools.replace(escaped, '"', "&quot;");
		return StringTools.replace(escaped, "'", "&#039;");
	}

	private function formatTime(time:Float):String {
		var date = Date.fromTime(time);
		return two(date.getHours()) + ":" + two(date.getMinutes()) + ":" + two(date.getSeconds());
	}

	private function two(value:Int):String {
		return value < 10 ? "0" + value : Std.string(value);
	}

	private function redraw():Void {
		graphics.clear();
		graphics.beginFill(0x111820, 0.94);
		graphics.drawRoundRect(0, 0, currentWidth, currentHeight, 8, 8);
		graphics.endFill();
		graphics.lineStyle(1, 0x40505F, 0.95);
		graphics.drawRoundRect(0, 0, currentWidth, currentHeight, 8, 8);

		titleBar.graphics.clear();
		titleBar.graphics.beginFill(0x1D2A35, 0.98);
		titleBar.graphics.drawRoundRect(0, 0, currentWidth, HEADER_HEIGHT, 8, 8);
		titleBar.graphics.endFill();
		titleBar.graphics.beginFill(0x1D2A35, 0.98);
		titleBar.graphics.drawRect(0, HEADER_HEIGHT - 8, currentWidth, 8);
		titleBar.graphics.endFill();

		titleLabel.x = PADDING;
		titleLabel.y = 8;
		titleLabel.width = Math.max(120, currentWidth - 170);
		titleLabel.height = 20;

		closeButton.x = currentWidth - closeButton.buttonWidth - PADDING;
		closeButton.y = 6;
		maxButton.x = closeButton.x - maxButton.buttonWidth - 6;
		maxButton.y = 6;
		maxButton.setLabel(isMaximized ? "Dock" : "Max");

		layoutToolbar();
		layoutOutput();
		drawResizeHandle();
		updateScrollBar();
		updateStatus();
	}

	private function layoutToolbar():Void {
		var yPos = HEADER_HEIGHT + 6;
		var xPos = PADDING;

		pauseButton.x = xPos;
		pauseButton.y = yPos;
		pauseButton.setLabel(captureEnabled ? "Pause" : "Resume");
		pauseButton.setActive(!captureEnabled);
		xPos += pauseButton.buttonWidth + 6;

		autoButton.x = xPos;
		autoButton.y = yPos;
		autoButton.setActive(autoScroll);
		xPos += autoButton.buttonWidth + 6;

		clearButton.x = xPos;
		clearButton.y = yPos;
		xPos += clearButton.buttonWidth + 6;

		copyButton.x = xPos;
		copyButton.y = yPos;
	}

	private function layoutOutput():Void {
		var outputX = PADDING;
		var outputY = HEADER_HEIGHT + TOOLBAR_HEIGHT + PADDING;
		var outputW = currentWidth - PADDING * 2 - SCROLLBAR_WIDTH - 7;
		var outputH = currentHeight - outputY - STATUS_HEIGHT - PADDING;

		output.x = outputX;
		output.y = outputY;
		output.width = Math.max(80, outputW);
		output.height = Math.max(80, outputH);

		scrollTrack.x = output.x + output.width + 6;
		scrollTrack.y = output.y;
		drawScrollTrack(output.height);

		statusLabel.x = PADDING;
		statusLabel.y = currentHeight - STATUS_HEIGHT + 1;
		statusLabel.width = currentWidth - PADDING * 2 - 28;
		statusLabel.height = STATUS_HEIGHT;

		resizeHandle.x = currentWidth - 28;
		resizeHandle.y = currentHeight - 28;
	}

	private function drawScrollTrack(height:Float):Void {
		scrollTrack.graphics.clear();
		scrollTrack.graphics.beginFill(0x151E27, 0.9);
		scrollTrack.graphics.drawRoundRect(0, 0, SCROLLBAR_WIDTH, height, 5, 5);
		scrollTrack.graphics.endFill();
	}

	private function drawResizeHandle():Void {
		resizeHandle.graphics.clear();
		resizeHandle.graphics.beginFill(0x000000, 0);
		resizeHandle.graphics.drawRect(0, 0, 28, 28);
		resizeHandle.graphics.endFill();
		resizeHandle.graphics.lineStyle(1, 0x71808F, 0.75);
		resizeHandle.graphics.moveTo(12, 22);
		resizeHandle.graphics.lineTo(22, 12);
		resizeHandle.graphics.moveTo(17, 23);
		resizeHandle.graphics.lineTo(23, 17);
	}

	private function updateScrollBar():Void {
		var trackH = output.height;
		var maxScroll = Math.max(1, output.maxScrollV);
		var numLines = Math.max(1, output.numLines);
		var visibleLines = Math.max(1, output.bottomScrollV - output.scrollV + 1);
		var ratio = Math.min(1, visibleLines / numLines);
		var thumbH = maxScroll <= 1 ? trackH : Math.max(24, trackH * ratio);
		var scrollRatio = maxScroll <= 1 ? 0 : (output.scrollV - 1) / (maxScroll - 1);
		var thumbY = scrollTrack.y + (trackH - thumbH) * scrollRatio;

		scrollThumb.visible = maxScroll > 1;
		scrollThumb.x = scrollTrack.x;
		scrollThumb.y = thumbY;
		scrollThumb.graphics.clear();
		scrollThumb.graphics.beginFill(0x6F879C, 0.88);
		scrollThumb.graphics.drawRoundRect(0, 0, SCROLLBAR_WIDTH, thumbH, 5, 5);
		scrollThumb.graphics.endFill();
	}

	private function updateStatus():Void {
		if (statusOverride.length > 0 && Timer.stamp() <= statusOverrideUntil) {
			statusLabel.text = statusOverride;
			return;
		}

		if (statusOverride.length > 0) statusOverride = "";

		var capture = captureEnabled ? "capturing" : "paused";
		statusLabel.text = '${lines.length} lines | $capture | F10 or Ctrl+` toggles';
	}

	private function setStatus(message:String):Void {
		statusOverride = message;
		statusOverrideUntil = Timer.stamp() + 1.7;
		updateStatus();
	}

	private function toggleCapture():Void {
		captureEnabled = !captureEnabled;
		if (!captureEnabled) clearPending();
		layoutToolbar();
		updateStatus();
	}

	private function toggleAutoScroll():Void {
		autoScroll = !autoScroll;
		if (autoScroll) output.scrollV = output.maxScrollV;
		layoutToolbar();
		updateScrollBar();
		updateStatus();
	}

	private function clearLogs():Void {
		lines = [];
		clearPending();
		output.htmlText = "";
		output.scrollV = 1;
		needsRender = true;
		setStatus("Console cleared");
	}

	private function copyVisibleLogs():Void {
		var text = new StringBuf();
		var copied = 0;

		for (line in lines) {
			if (copied > 0) text.add("\n");
			text.add(lineToPlain(line));
			copied++;
		}

		Clipboard.text = text.toString();
		setStatus(copied > 0 ? 'Copied $copied lines' : "Nothing to copy");
	}

	private function onOutputWheel(event:MouseEvent):Void {
		if (output.maxScrollV <= 1) return;
		output.scrollV = clampInt(output.scrollV - event.delta * 3, 1, output.maxScrollV);
		autoScroll = output.scrollV >= output.maxScrollV;
		layoutToolbar();
		updateScrollBar();
		updateStatus();
		event.stopPropagation();
	}

	private function onScrollTrackDown(event:MouseEvent):Void {
		if (output.maxScrollV <= 1) return;
		var localY = event.stageY - scrollTrack.localToGlobal(new openfl.geom.Point()).y;
		var thumbCenter = scrollThumb.y - scrollTrack.y + scrollThumb.height / 2;
		if (localY < thumbCenter) output.scrollV = output.scrollV - 8 < 1 ? 1 : output.scrollV - 8;
		else output.scrollV = output.scrollV + 8 > output.maxScrollV ? output.maxScrollV : output.scrollV + 8;
		autoScroll = output.scrollV >= output.maxScrollV;
		updateScrollBar();
		updateStatus();
	}

	private function startScrollDrag(event:MouseEvent):Void {
		isDraggingScroll = true;
		scrollDragStartY = event.stageY;
		scrollDragStartV = output.scrollV;
		stage.addEventListener(MouseEvent.MOUSE_MOVE, dragScrollThumb);
		stage.addEventListener(MouseEvent.MOUSE_UP, stopScrollDrag);
		event.stopPropagation();
	}

	private function dragScrollThumb(event:MouseEvent):Void {
		if (!isDraggingScroll || output.maxScrollV <= 1) return;
		var available = Math.max(1, scrollTrack.height - scrollThumb.height);
		var scrollDelta = (event.stageY - scrollDragStartY) / available * (output.maxScrollV - 1);
		output.scrollV = clampInt(scrollDragStartV + Math.round(scrollDelta), 1, output.maxScrollV);
		autoScroll = output.scrollV >= output.maxScrollV;
		updateScrollBar();
		updateStatus();
	}

	private function stopScrollDrag(event:MouseEvent):Void {
		isDraggingScroll = false;
		stage.removeEventListener(MouseEvent.MOUSE_MOVE, dragScrollThumb);
		stage.removeEventListener(MouseEvent.MOUSE_UP, stopScrollDrag);
		Mouse.cursor = MouseCursor.AUTO;
		event.stopPropagation();
	}

	private function startDragWindow(event:MouseEvent):Void {
		isDragging = true;
		dragOffsetX = event.stageX - x;
		dragOffsetY = event.stageY - y;
		stage.addEventListener(MouseEvent.MOUSE_MOVE, dragWindow);
		stage.addEventListener(MouseEvent.MOUSE_UP, stopDragWindow);
		event.stopPropagation();
	}

	private function dragWindow(event:MouseEvent):Void {
		if (!isDragging) return;
		x = event.stageX - dragOffsetX;
		y = event.stageY - dragOffsetY;
		clampToStage();
	}

	private function stopDragWindow(event:MouseEvent):Void {
		isDragging = false;
		stage.removeEventListener(MouseEvent.MOUSE_MOVE, dragWindow);
		stage.removeEventListener(MouseEvent.MOUSE_UP, stopDragWindow);
		if (!isMaximized) {
			normalBounds.setTo(x, y, currentWidth, currentHeight);
			saveWindowPrefs();
		}
		event.stopPropagation();
	}

	private function startResize(event:MouseEvent):Void {
		if (isMaximized) return;
		isResizing = true;
		resizeStartX = event.stageX;
		resizeStartY = event.stageY;
		resizeStartWidth = currentWidth;
		resizeStartHeight = currentHeight;
		stage.addEventListener(MouseEvent.MOUSE_MOVE, resizeWindow);
		stage.addEventListener(MouseEvent.MOUSE_UP, stopResize);
		event.stopPropagation();
	}

	private function resizeWindow(event:MouseEvent):Void {
		if (!isResizing) return;
		var maxW = Math.max(MIN_WIDTH, (stageWidth() - x - 8) / scaleX);
		var maxH = Math.max(MIN_HEIGHT, (stageHeight() - y - 8) / scaleY);
		currentWidth = Math.max(MIN_WIDTH, Math.min(maxW, resizeStartWidth + (event.stageX - resizeStartX) / scaleX));
		currentHeight = Math.max(MIN_HEIGHT, Math.min(maxH, resizeStartHeight + (event.stageY - resizeStartY) / scaleY));
		normalBounds.setTo(x, y, currentWidth, currentHeight);
		redraw();
		needsRender = true;
	}

	private function stopResize(event:MouseEvent):Void {
		isResizing = false;
		stage.removeEventListener(MouseEvent.MOUSE_MOVE, resizeWindow);
		stage.removeEventListener(MouseEvent.MOUSE_UP, stopResize);
		Mouse.cursor = MouseCursor.AUTO;
		if (!isMaximized) {
			normalBounds.setTo(x, y, currentWidth, currentHeight);
			saveWindowPrefs();
		}
		event.stopPropagation();
	}

	private function toggleMaximize():Void {
		if (isMaximized) {
			isMaximized = false;
			x = normalBounds.x;
			y = normalBounds.y;
			currentWidth = normalBounds.width;
			currentHeight = normalBounds.height;
			clampSizeToStage();
			clampToStage();
			redraw();
			needsRender = true;
		} else {
			normalBounds.setTo(x, y, currentWidth, currentHeight);
			isMaximized = true;
			fillStage();
		}
	}

	private function fillStage():Void {
		x = 0;
		y = 0;
		currentWidth = stageWidth() / scaleX;
		currentHeight = stageHeight() / scaleY;
		redraw();
		needsRender = true;
	}

	private function onStageResize(_:Event):Void {
		if (isMaximized) {
			fillStage();
			return;
		}

		clampSizeToStage();
		clampToStage();
		redraw();
		needsRender = true;
	}

	private function onKeyDown(event:KeyboardEvent):Void {
		if (!ClientPrefs.data.developerMode) return;

		// ★ 单独的 F10 = 开关控制台；但 **Ctrl+F10 要让出去** ——
		//   设置界面拿它当「唤出隐藏的测试语言」的开关（见 OptionsState.toggleTestLanguage）。
		//   这里不吞这个组合，事件才能继续派发到 Flixel 的键盘管理器（FlxG.keys）。
		if ((event.ctrlKey && event.keyCode == KEY_GRAVE) || (!event.ctrlKey && event.keyCode == KEY_F10)) {
			toggle();
			event.stopImmediatePropagation();
			return;
		}

		if (!visible) return;

		if (event.keyCode == KEY_ESCAPE) {
			hide();
			event.stopImmediatePropagation();
			return;
		}
	}

	private function clampSizeToStage():Void {
		currentWidth = Math.max(MIN_WIDTH, Math.min(currentWidth, Math.max(MIN_WIDTH, (stageWidth() - 16) / scaleX)));
		currentHeight = Math.max(MIN_HEIGHT, Math.min(currentHeight, Math.max(MIN_HEIGHT, (stageHeight() - 16) / scaleY)));
	}

	private function clampToStage():Void {
		var maxX = Math.max(0, stageWidth() - currentWidth * scaleX);
		var maxY = Math.max(0, stageHeight() - currentHeight * scaleY);
		x = Math.max(0, Math.min(maxX, x));
		y = Math.max(0, Math.min(maxY, y));
	}

	private function stageWidth():Float {
		return Lib.current != null && Lib.current.stage != null ? Lib.current.stage.stageWidth : 1280;
	}

	private function stageHeight():Float {
		return Lib.current != null && Lib.current.stage != null ? Lib.current.stage.stageHeight : 720;
	}

	private function clampInt(value:Int, min:Int, max:Int):Int {
		if (value < min) return min;
		if (value > max) return max;
		return value;
	}
}

private class ConsoleButton extends Sprite {
	public var buttonWidth(default, null):Float;
	public var buttonHeight(default, null):Float;

	private var label:TextField;
	private var baseColor:Int;
	private var activeColor:Int;
	private var isActive:Bool = false;
	private var isHovering:Bool = false;
	private var labelFormat:TextFormat;

	public function new(text:String, width:Float, height:Float, color:Int) {
		super();

		buttonWidth = width;
		buttonHeight = height;
		baseColor = color;
		activeColor = brighten(color, 34);

		buttonMode = true;
		useHandCursor = true;
		mouseChildren = false;

		label = new TextField();
		labelFormat = new TextFormat(Paths.font("Lang-ZH.ttf"), 11, 0xF4F7FA, true);
		labelFormat.align = TextFormatAlign.CENTER;
		label.defaultTextFormat = labelFormat;
		label.selectable = false;
		label.mouseEnabled = false;
		label.x = 0;
		label.y = Math.max(0, (buttonHeight - 18) / 2);
		label.width = buttonWidth;
		label.height = buttonHeight;
		label.text = text;
		label.setTextFormat(labelFormat);
		addChild(label);

		addEventListener(MouseEvent.MOUSE_OVER, function(_) {
			isHovering = true;
			Mouse.cursor = MouseCursor.BUTTON;
			redraw();
		});
		addEventListener(MouseEvent.MOUSE_OUT, function(_) {
			isHovering = false;
			Mouse.cursor = MouseCursor.AUTO;
			redraw();
		});

		redraw();
	}

	public function setLabel(text:String):Void {
		label.text = text;
		label.setTextFormat(labelFormat);
	}

	public function setActive(value:Bool):Void {
		if (isActive == value) return;
		isActive = value;
		redraw();
	}

	private function redraw():Void {
		var color = isActive ? activeColor : baseColor;
		var alpha = isHovering ? 1 : 0.88;

		graphics.clear();
		graphics.beginFill(color, alpha);
		graphics.drawRoundRect(0, 0, buttonWidth, buttonHeight, 5, 5);
		graphics.endFill();
		graphics.lineStyle(1, 0xB7C6D5, isHovering ? 0.38 : 0.18);
		graphics.drawRoundRect(0.5, 0.5, buttonWidth - 1, buttonHeight - 1, 5, 5);
	}

	private static function brighten(color:Int, amount:Int):Int {
		var r:Int = Std.int(Math.min(255, ((color >> 16) & 0xFF) + amount));
		var g:Int = Std.int(Math.min(255, ((color >> 8) & 0xFF) + amount));
		var b:Int = Std.int(Math.min(255, (color & 0xFF) + amount));
		return (r << 16) | (g << 8) | b;
	}
}
