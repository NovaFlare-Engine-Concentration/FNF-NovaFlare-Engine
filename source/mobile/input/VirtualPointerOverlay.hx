package mobile.input;

#if (mobile && FLX_MOUSE)
import flixel.FlxG;
import haxe.ds.IntMap;
import haxe.ds.StringMap;
import openfl.Lib;
import openfl.display.DisplayObject;
import openfl.display.InteractiveObject;
import openfl.display.Sprite;
import openfl.display.Stage;
import openfl.events.Event;
import openfl.events.KeyboardEvent;
import openfl.events.MouseEvent;
import openfl.events.TextEvent;
import openfl.events.TouchEvent;
import openfl.geom.Point;
import openfl.text.TextField;
import openfl.text.TextFieldType;
import openfl.text.TextFormat;
import openfl.text.TextFormatAlign;
import openfl.ui.Keyboard;

/** Stage-level mobile controls shared by all three engine entry points. */
class VirtualPointerOverlay extends Sprite
{
    static var instance:VirtualPointerOverlay;
    var rootStage:Stage;
    var pointer:Sprite;
    var mouseShell:Sprite;
    var ctrlHolds:Int = 0;
    var mouse:VirtualMouse;
    var active:Bool = false;
    var synthesized:Bool = false;
    var moveTouch:Int = -1;
    var lastX:Float = 0;
    var lastY:Float = 0;
    var wheelTouch:Int = -1;
    var wheelLastY:Float = 0;
    var scrollRemainder:Float = 0;
    var touches:IntMap<String> = new IntMap();
    var held:StringMap<Int> = new StringMap();
    var buttons:Array<OverlayButton> = [];
    var unit:Float = 40;
    var surfaceWidth:Int = 0;
    var surfaceHeight:Int = 0;
    var keyQueue:Array<{code:Int, character:Int, down:Bool, ctrl:Bool}> = [];
    var ime:TextField;
    #if android
    var installVolume:Dynamic;
    var consumeVolume:Dynamic;
    #end

    public static function install(stage:Stage):Void
    {
        if (instance != null || stage == null) return;
        instance = new VirtualPointerOverlay(stage);
        stage.addChild(instance);
    }

    function new(stage:Stage)
    {
        super();
        rootStage = stage;
        mouseEnabled = false;
        mouseChildren = false;
        pointer = new Sprite();
        pointer.mouseEnabled = false;
        pointer.graphics.lineStyle(1.5, 0x000000, 1);
        pointer.graphics.beginFill(0xFFFFFF, 1);
        pointer.graphics.moveTo(0, 0);
        pointer.graphics.lineTo(0, 20);
        pointer.graphics.lineTo(5, 15);
        pointer.graphics.lineTo(9, 24);
        pointer.graphics.lineTo(13, 22);
        pointer.graphics.lineTo(9, 13);
        pointer.graphics.lineTo(16, 13);
        pointer.graphics.lineTo(0, 0);
        pointer.graphics.endFill();
        ime = new TextField();
        ime.type = TextFieldType.INPUT;
        ime.width = ime.height = 2;
        ime.alpha = 0.01;
        ime.needsSoftKeyboard = true;
        ime.addEventListener(TextEvent.TEXT_INPUT, onTextInput);
        addChild(ime);
        addChild(pointer);
        visible = false;
        stage.addEventListener(Event.ENTER_FRAME, onFrame);
        stage.addEventListener(Event.RESIZE, onResize);
        stage.addEventListener(Event.DEACTIVATE, onDeactivate);
        stage.addEventListener(Event.ACTIVATE, onActivate);
        // This OpenFL version does not broadcast Lime window deactivation.
        if (stage.window != null)
        {
            stage.window.onDeactivate.add(onWindowDeactivate);
            stage.window.onActivate.add(onWindowActivate);
        }
        for (type in [TouchEvent.TOUCH_BEGIN, TouchEvent.TOUCH_MOVE, TouchEvent.TOUCH_END])
        {
            stage.addEventListener(type, onTouch, true, 1000000);
            stage.addEventListener(type, onTouch, false, 1000000);
        }
        for (type in [MouseEvent.MOUSE_DOWN, MouseEvent.MOUSE_UP, MouseEvent.MOUSE_MOVE,
            MouseEvent.MOUSE_WHEEL, MouseEvent.CLICK, MouseEvent.DOUBLE_CLICK,
            MouseEvent.RIGHT_MOUSE_DOWN, MouseEvent.RIGHT_MOUSE_UP, MouseEvent.MIDDLE_MOUSE_DOWN, MouseEvent.MIDDLE_MOUSE_UP])
        {
            stage.addEventListener(type, onPhysicalMouse, true, 1000000);
            stage.addEventListener(type, onPhysicalMouse, false, 1000000);
        }
        #if android
        try
        {
            installVolume = lime.system.JNI.createStaticMethod('org/novaflare/input/VirtualPointerVolumeKeys', 'install', '()V');
            consumeVolume = lime.system.JNI.createStaticMethod('org/novaflare/input/VirtualPointerVolumeKeys', 'consumeToggles', '()I');
            installVolume();
        }
        catch (error:Dynamic) trace('Virtual pointer volume-key observer unavailable: $error');
        #end
        layout();
    }

    function onActivate(_:Event):Void
    {
        #if android
        if (installVolume != null) installVolume();
        #end
    }

    function onDeactivate(_:Event):Void
    {
        if (active) releaseAll();
    }

    function onWindowDeactivate():Void
    {
        if (active) releaseAll();
    }

    function onWindowActivate():Void
    {
        #if android
        if (installVolume != null) installVolume();
        #end
    }

    function onResize(_:Event):Void layout();

    function onFrame(_:Event):Void
    {
        #if android
        if (consumeVolume != null && (Std.int(consumeVolume()) & 1) != 0) setActive(!active);
        #end
        if (parent == rootStage && rootStage.getChildIndex(this) != rootStage.numChildren - 1)
            rootStage.setChildIndex(this, rootStage.numChildren - 1);
        if (!active) return;
        if (rootStage.stageWidth != surfaceWidth || rootStage.stageHeight != surfaceHeight) layout();
        if (mouse == null || FlxG.mouse != mouse)
        {
            mouse = VirtualMouse.install();
            if (mouse == null) return;
            mouse.onInputStep = processKeyQueue;
            mouse.setVirtualActive(true);
        }
        pointer.visible = !mouse.visible;
        var position = FlxG.game.localToGlobal(new Point(mouse.virtualX, mouse.virtualY));
        pointer.x = position.x;
        pointer.y = position.y;
        setChildIndex(pointer, numChildren - 1);
    }

    public function setActive(value:Bool):Void
    {
        if (active == value) return;
        if (value)
        {
            mouse = VirtualMouse.install();
            if (mouse == null) return;
            var center = FlxG.game.globalToLocal(new Point(rootStage.stageWidth * 0.5, rootStage.stageHeight * 0.5));
            mouse.virtualX = center.x;
            mouse.virtualY = center.y;
            #if FLX_TOUCH
            if (FlxG.touches != null) FlxG.touches.reset();
            #end
            mouse.onInputStep = processKeyQueue;
            mouse.setVirtualActive(true);
            active = true;
            visible = true;
            layout();
        }
        else
        {
            releaseAll();
            active = false;
            visible = false;
            if (mouse != null) mouse.setVirtualActive(false);
            #if FLX_TOUCH
            if (FlxG.touches != null) FlxG.touches.reset();
            #end
            if (rootStage.focus == ime) rootStage.focus = null;
        }
    }

    function releaseAll():Void
    {
        for (id in touches.keys()) release(touches.get(id));
        touches = new IntMap();
        held = new StringMap();
        ctrlHolds = 0;
        moveTouch = -1;
        wheelTouch = -1;
        scrollRemainder = 0;
        // Ensure synthesized keyboard keys cannot remain held across focus/mode changes.
        for (code in [Keyboard.CONTROL, Keyboard.C, Keyboard.V, Keyboard.SPACE, Keyboard.UP,
            Keyboard.DOWN, Keyboard.LEFT, Keyboard.RIGHT, Keyboard.ENTER, Keyboard.ESCAPE])
            sendKey(code, 0, false, false);
        #if android
        sendKey(cast flixel.input.android.FlxAndroidKey.BACK, 0, false, false);
        #end
        keyQueue = [];
        if (mouse != null) mouse.reset();
    }

    function onPhysicalMouse(event:MouseEvent):Void
    {
        if (active && !synthesized) event.stopImmediatePropagation();
    }

    function onTouch(event:TouchEvent):Void
    {
        if (!active || mouse == null) return;
        event.stopImmediatePropagation();
        var id = event.touchPointID;
        if (event.type == TouchEvent.TOUCH_BEGIN)
        {
            var action = buttonAt(event.stageX, event.stageY);
            if (action != null)
            {
                touches.set(id, action);
                if (action == 'wheel')
                {
                    if (wheelTouch != -1) touches.remove(id);
                    else { wheelTouch = id; wheelLastY = event.stageY; scrollRemainder = 0; }
                }
                else press(action);
            }
            else if (moveTouch == -1)
            {
                moveTouch = id;
                lastX = event.stageX;
                lastY = event.stageY;
                touches.set(id, 'move');
            }
        }
        else if (event.type == TouchEvent.TOUCH_MOVE)
        {
            var action = touches.get(id);
            if (action == 'move' && moveTouch == id)
            {
                var old = FlxG.game.globalToLocal(new Point(lastX, lastY));
                var next = FlxG.game.globalToLocal(new Point(event.stageX, event.stageY));
                var topLeft = FlxG.game.globalToLocal(new Point(0, 0));
                var bottomRight = FlxG.game.globalToLocal(new Point(rootStage.stageWidth, rootStage.stageHeight));
                mouse.virtualX = Math.max(Math.min(topLeft.x, bottomRight.x), Math.min(Math.max(topLeft.x, bottomRight.x), mouse.virtualX + next.x - old.x));
                mouse.virtualY = Math.max(Math.min(topLeft.y, bottomRight.y), Math.min(Math.max(topLeft.y, bottomRight.y), mouse.virtualY + next.y - old.y));
                lastX = event.stageX;
                lastY = event.stageY;
                dispatchMouse(MouseEvent.MOUSE_MOVE, held.exists('left'));
            }
            else if (action == 'wheel' && wheelTouch == id)
            {
                scrollRemainder += wheelLastY - event.stageY;
                wheelLastY = event.stageY;
                var step = Math.max(8.0, unit * 0.25);
                var ticks = Std.int(scrollRemainder / step);
                if (ticks != 0) { mouse.scroll(ticks); dispatchMouse(MouseEvent.MOUSE_WHEEL, false, ticks); scrollRemainder -= ticks * step; }
            }
        }
        else if (event.type == TouchEvent.TOUCH_END)
        {
            var action = touches.get(id);
            if (action == 'move' && moveTouch == id) moveTouch = -1;
            else if (action == 'wheel' && wheelTouch == id) { wheelTouch = -1; scrollRemainder = 0; }
            else if (action != null && action != 'wheel') release(action);
            touches.remove(id);
        }
    }

    function buttonAt(x:Float, y:Float):Null<String>
    {
        for (button in buttons)
            if (x >= button.x && y >= button.y && x < button.x + button.w && y < button.y + button.h) return button.action;
        return null;
    }

    function press(action:String):Void
    {
        var count = held.exists(action) ? held.get(action) : 0;
        held.set(action, count + 1);
        if (count != 0) return;
        switch (action)
        {
            case 'left', 'right':
                var right = action == 'right';
                mouse.queueButton(right, true);
                dispatchMouse(right ? MouseEvent.RIGHT_MOUSE_DOWN : MouseEvent.MOUSE_DOWN, true);
            case 'keyboard': showKeyboard();
            case 'copy', 'paste':
                applyClipboardToOpenFLInput(action);
                if (ctrlHolds++ == 0) enqueue(Keyboard.CONTROL, true);
                enqueue(action == 'copy' ? Keyboard.C : Keyboard.V, true, true);
            default:
                var code = keyCode(action);
                if (code != 0) enqueue(code, true);
        }
    }

    function release(action:String):Void
    {
        var count = held.exists(action) ? held.get(action) : 0;
        if (count <= 1) held.remove(action); else { held.set(action, count - 1); return; }
        if (count == 0) return;
        switch (action)
        {
            case 'left', 'right':
                var right = action == 'right';
                mouse.queueButton(right, false);
                dispatchMouse(right ? MouseEvent.RIGHT_MOUSE_UP : MouseEvent.MOUSE_UP, false);
            case 'copy', 'paste':
                enqueue(action == 'copy' ? Keyboard.C : Keyboard.V, false, true);
                ctrlHolds = Std.int(Math.max(0, ctrlHolds - 1));
                if (ctrlHolds == 0) enqueue(Keyboard.CONTROL, false);
            case 'keyboard':
            default:
                var code = keyCode(action);
                if (code != 0) enqueue(code, false);
        }
    }

    function keyCode(action:String):Int
    {
        return switch (action)
        {
            case 'up': Keyboard.UP;
            case 'down': Keyboard.DOWN;
            case 'arrowLeft': Keyboard.LEFT;
            case 'arrowRight': Keyboard.RIGHT;
            case 'space': Keyboard.SPACE;
            case 'enter': Keyboard.ENTER;
            case 'back': #if android (cast flixel.input.android.FlxAndroidKey.BACK : Int) #else Keyboard.ESCAPE #end;
            default: 0;
        }
    }

    function processKeyQueue():Void
    {
        if (!active || keyQueue.length == 0) return;
        var item = keyQueue.shift();
        sendKey(item.code, item.character, item.down, item.ctrl);
    }

    function enqueue(code:Int, down:Bool, ctrl:Bool = false, character:Int = 0):Void
    {
        keyQueue.push({code: code, character: character, down: down, ctrl: ctrl});
    }

    function sendKey(code:Int, character:Int, down:Bool, ctrl:Bool):Void
    {
        // Flixel's native key correction treats zero-char C/V as PageDown/F7.
        // Supply the corresponding letter for synthetic alphabetic keys.
        if (character == 0 && code >= Keyboard.A && code <= Keyboard.Z) character = code + 32;
        var event = new KeyboardEvent(down ? KeyboardEvent.KEY_DOWN : KeyboardEvent.KEY_UP, true, false,
            character, code, null, ctrl);
        var target:InteractiveObject = rootStage.focus != null ? rootStage.focus : rootStage;
        target.dispatchEvent(event);
    }

    function applyClipboardToOpenFLInput(action:String):Void
    {
        if (rootStage.focus == ime || !Std.isOfType(rootStage.focus, TextField)) return;
        var field:TextField = cast rootStage.focus;
        if (field.type != TextFieldType.INPUT) return;
        if (action == 'copy')
        {
            if (!field.displayAsPassword && field.selectionEndIndex > field.selectionBeginIndex)
                lime.system.Clipboard.text = field.text.substring(field.selectionBeginIndex, field.selectionEndIndex);
        }
        else
        {
            var value = lime.system.Clipboard.text;
            if (value == null) return;
            var textEvent = new TextEvent(TextEvent.TEXT_INPUT, true, true, value);
            if (!field.dispatchEvent(textEvent) || textEvent.isDefaultPrevented()) return;
            var before = field.text;
            // Match OpenFL's native paste path, including restrict/maxChars.
            @:privateAccess field.__replaceSelectedText(value, true);
            if (field.text != before) field.dispatchEvent(new Event(Event.CHANGE, true));
        }
    }

    function showKeyboard():Void
    {
        var current = rootStage.focus;
        if (!Std.isOfType(current, TextField) || cast(current, TextField).type != TextFieldType.INPUT)
            rootStage.focus = ime;
        // The installed OpenFL requestSoftKeyboard() is a stub. Lime's SDL
        // text-input switch is the platform path that actually opens the IME.
        if (rootStage.window != null) rootStage.window.textInputEnabled = true;
    }

    function onTextInput(event:TextEvent):Void
    {
        if (!active || rootStage.focus != ime) return;
        event.preventDefault();
        for (i in 0...event.text.length)
        {
            var character = event.text.charCodeAt(i);
            if (character == null) continue;
            var key = character >= 97 && character <= 122 ? character - 32 : character;
            enqueue(key, true, false, character);
            enqueue(key, false, false, character);
        }
    }

    function dispatchMouse(type:String, down:Bool, delta:Int = 0):Void
    {
        mouse.syncPosition();
        var position = FlxG.game.localToGlobal(new Point(mouse.virtualX, mouse.virtualY));
        // OpenFL uses this path for hit testing, focus, hover, click and drag state.
        var nativePosition = @:privateAccess rootStage.__displayMatrix.transformPoint(position);
        var button = (type == MouseEvent.RIGHT_MOUSE_DOWN || type == MouseEvent.RIGHT_MOUSE_UP) ? 2 : 0;
        synthesized = true;
        try
        {
            if (type == MouseEvent.MOUSE_WHEEL)
            {
                @:privateAccess rootStage.__onMouse(null, nativePosition.x, nativePosition.y, 0);
                @:privateAccess rootStage.__onMouseWheel(0, delta, lime.ui.MouseWheelMode.LINES);
            }
            else
                @:privateAccess rootStage.__onMouse(type, nativePosition.x, nativePosition.y, button);
        }
        catch (error:Dynamic) { synthesized = false; throw error; }
        synthesized = false;
    }

    function layout():Void
    {
        surfaceWidth = rootStage.stageWidth;
        surfaceHeight = rootStage.stageHeight;
        unit = Math.max(22, Math.min(surfaceWidth / 14, surfaceHeight / 9));
        for (button in buttons) if (button.view.parent == this) removeChild(button.view);
        if (mouseShell != null && mouseShell.parent == this) removeChild(mouseShell);
        buttons = [];
        var u = unit;
        addButton('paste', 'Ctrl+V', 0, 0, u, u * 0.72);
        addButton('copy', 'Ctrl+C', u, 0, u, u * 0.72);
        addButton('keyboard', '⌨', surfaceWidth - u, 0, u, u * 0.82);
        mouseShell = new Sprite();
        mouseShell.mouseEnabled = false;
        mouseShell.graphics.lineStyle(2, 0xEAEAEA, 0.9);
        mouseShell.graphics.beginFill(0x172235, 0.72);
        mouseShell.graphics.drawRoundRect(1, 1, u * 2 - 2, u * 1.10 - 2, u * 0.52);
        mouseShell.graphics.endFill();
        mouseShell.x = 0;
        mouseShell.y = surfaceHeight - u * 1.10;
        addChildAt(mouseShell, 0);
        addButton('left', 'L', 0, surfaceHeight - u * 1.10, u, u * 0.58);
        buttons[buttons.length - 1].h = u * 1.10;
        addButton('right', 'R', u, surfaceHeight - u * 1.10, u, u * 0.58);
        buttons[buttons.length - 1].h = u * 1.10;
        addButton('space', 'SPACE', 0, surfaceHeight - u * 2.02, u * 3, u * 0.78);
        addButton('up', '↑', u, surfaceHeight - u * 4.02, u, u * 0.85);
        addButton('arrowLeft', '←', 0, surfaceHeight - u * 3.12, u, u * 0.85);
        addButton('down', '↓', u, surfaceHeight - u * 3.12, u, u * 0.85);
        addButton('arrowRight', '→', u * 2, surfaceHeight - u * 3.12, u, u * 0.85);
        addButton('enter', 'ENTER', surfaceWidth - u * 1.65, surfaceHeight - u, u * 1.65, u);
        addButton('wheel', '↕', surfaceWidth - u, surfaceHeight * 0.5 - u * 0.65, u, u * 1.75);
        addButton('back', 'BACK', surfaceWidth - u, surfaceHeight * 0.5 - u * 1.55, u, u * 0.75);
    }

    function addButton(action:String, label:String, x:Float, y:Float, w:Float, h:Float):Void
    {
        var view = new Sprite();
        view.mouseEnabled = false;
        view.mouseChildren = false;
        view.graphics.lineStyle(2, 0xEAEAEA, 0.9);
        view.graphics.beginFill(0x172235, 0.72);
        view.graphics.drawRoundRect(1, 1, w - 2, h - 2, Math.min(12, unit * 0.2));
        view.graphics.endFill();
        view.x = x;
        view.y = y;
        var text = new TextField();
        text.defaultTextFormat = new TextFormat('_sans', Std.int(Math.max(12, unit * (label.length > 4 ? 0.22 : 0.38))), 0xFFFFFF, true, null, null, null, null, TextFormatAlign.CENTER);
        text.selectable = false;
        text.mouseEnabled = false;
        text.width = w;
        text.height = h;
        text.text = label;
        text.y = Math.max(0, (h - text.textHeight) * 0.5 - 2);
        view.addChild(text);
        addChildAt(view, Std.int(Math.max(0, numChildren - 1)));
        buttons.push({action: action, x: x, y: y, w: w, h: h, view: view});
    }
}

private typedef OverlayButton = {var action:String; var x:Float; var y:Float; var w:Float; var h:Float; var view:Sprite;}
#end
