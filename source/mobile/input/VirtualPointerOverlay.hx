package mobile.input;

#if (mobile && FLX_MOUSE)
import flixel.FlxG;
import haxe.ds.IntMap;
import haxe.ds.StringMap;
import openfl.display.InteractiveObject;
import openfl.display.Sprite;
import openfl.display.Stage;
import openfl.events.Event;
import openfl.events.MouseEvent;
import openfl.events.TouchEvent;
import openfl.geom.Point;

/** Stage-level mobile controls shared by all three engine entry points. */
class VirtualPointerOverlay extends Sprite
{
    static inline final VIRTUAL_POINTER_HINT = "SDL_NOVAFLARE_VIRTUAL_POINTER";
    static final MODIFIERS = ['key:shift', 'key:ctrl', 'key:alt', 'key:caps'];
    static var instance:VirtualPointerOverlay;
    var rootStage:Stage;
    var pointer:Sprite;
    final panel:VirtualPointerPanel;
    final keyboardInput:VirtualPointerKeyboardInput;
    var mouse:VirtualMouse;
    var active:Bool = false;
    var closeRequested:Bool = false;
    var keyboardVisible:Bool = false;
    var sensitivity:Float = 0.5;
    var synthesized:Bool = false;
    var suppressCleanupClick:Bool = false;
    var moveTouch:Int = -1;
    var lastX:Float = 0;
    var lastY:Float = 0;
    var wheelTouch:Int = -1;
    var sensitivityTouch:Int = -1;
    var wheelLastY:Float = 0;
    var scrollRemainder:Float = 0;
    var touches:IntMap<String> = new IntMap();
    var held:StringMap<Int> = new StringMap();
    var surfaceWidth:Int = 0;
    var surfaceHeight:Int = 0;
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
        panel = new VirtualPointerPanel();
        keyboardInput = new VirtualPointerKeyboardInput(stage);
        addChild(panel);
        addChild(keyboardInput.ime);
        addChild(pointer);
        visible = false;
        stage.addEventListener(Event.ENTER_FRAME, onFrame);
        stage.addEventListener(Event.RESIZE, onResize);
        stage.addEventListener(Event.DEACTIVATE, onDeactivate);
        stage.addEventListener(Event.ACTIVATE, onActivate);
        FlxG.signals.preUpdate.add(processKeyQueue);
        // This OpenFL version does not broadcast Lime window deactivation.
        if (stage.window != null)
        {
            var window = stage.window;
            window.onDeactivate.add(onWindowDeactivate);
            window.onActivate.add(onWindowActivate);
            // Stop SDL touch-generated mouse input before it updates OpenFL's mouse state.
            window.onMouseDown.add((_, _, _) -> { if (active) window.onMouseDown.cancel(); }, false, 1000000);
            window.onMouseUp.add((_, _, _) -> { if (active) window.onMouseUp.cancel(); }, false, 1000000);
            window.onMouseMove.add((_, _) -> { if (active) window.onMouseMove.cancel(); }, false, 1000000);
            window.onMouseWheel.add((_, _, _) -> { if (active) window.onMouseWheel.cancel(); }, false, 1000000);
        }
        for (type in [TouchEvent.TOUCH_BEGIN, TouchEvent.TOUCH_MOVE, TouchEvent.TOUCH_END, TouchEvent.TOUCH_TAP])
        {
            stage.addEventListener(type, onTouch, true, 1000000);
            stage.addEventListener(type, onTouch, false, 1000000);
        }
        for (type in [MouseEvent.MOUSE_DOWN, MouseEvent.MOUSE_UP, MouseEvent.MOUSE_MOVE,
            MouseEvent.MOUSE_WHEEL, MouseEvent.CLICK, MouseEvent.DOUBLE_CLICK,
            MouseEvent.RIGHT_CLICK, MouseEvent.MIDDLE_CLICK,
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
        if (closeRequested) setActive(false);
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
        closeRequested = false;
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
            mouse.setVirtualActive(true);
            active = true;
            keyboardVisible = false;
            lime.system.System.setHint(VIRTUAL_POINTER_HINT, "1");
            cancelNativeMousePress();
            visible = true;
            layout();
        }
        else
        {
            releaseAll();
            active = false;
            lime.system.System.setHint(VIRTUAL_POINTER_HINT, "0");
            visible = false;
            if (mouse != null) mouse.setVirtualActive(false);
            #if FLX_TOUCH
            if (FlxG.touches != null) FlxG.touches.reset();
            #end
        }
    }

    function releaseAll():Void
    {
        for (id in touches.keys()) release(touches.get(id), true);
        touches = new IntMap();
        held = new StringMap();
        moveTouch = -1;
        wheelTouch = -1;
        sensitivityTouch = -1;
        scrollRemainder = 0;
        keyboardInput.reset();
        updateModifierHighlights();
        panel.setPressed('wheel', false);
        panel.setPressed('sensitivity', false);
        if (mouse != null) mouse.cancelPendingButtons();
    }

    function cancelNativeMousePress():Void
    {
        @:privateAccess rootStage.__pendingMouseEvent = false;
        if (@:privateAccess rootStage.__mouseDownLeft == null) return;
        var position = @:privateAccess new Point(rootStage.__untransformedMouseX, rootStage.__untransformedMouseY);
        dispatchStageMouse(MouseEvent.MOUSE_UP, position, 0, true);
    }

    function onPhysicalMouse(event:MouseEvent):Void
    {
        if (!active) return;
        if (!synthesized)
        {
            event.stopImmediatePropagation();
            return;
        }
        if (suppressCleanupClick)
        {
            switch (event.type)
            {
                case MouseEvent.CLICK, MouseEvent.DOUBLE_CLICK, MouseEvent.RIGHT_CLICK, MouseEvent.MIDDLE_CLICK:
                    event.stopImmediatePropagation();
                default:
            }
        }
    }

    function onTouch(event:TouchEvent):Void
    {
        if (!active || mouse == null) return;
        event.stopImmediatePropagation();
        var id = event.touchPointID;
        if (event.type == TouchEvent.TOUCH_BEGIN)
        {
            beginTouch(event);
        }
        else if (event.type == TouchEvent.TOUCH_MOVE)
        {
            var action = touches.get(id);
            if (action == 'move' && moveTouch == id)
            {
                movePointer(event.stageX, event.stageY);
            }
            else if (action == 'wheel' && wheelTouch == id)
            {
                scrollRemainder += wheelLastY - event.stageY;
                wheelLastY = event.stageY;
                var step = Math.max(8.0, Math.min(surfaceWidth / 56, surfaceHeight / 36));
                var ticks = Std.int(scrollRemainder / step);
                if (ticks != 0) { mouse.scroll(ticks); dispatchMouse(MouseEvent.MOUSE_WHEEL, ticks); scrollRemainder -= ticks * step; }
            }
            else if (action == 'sensitivity' && sensitivityTouch == id)
            {
                changeSensitivity(event.stageX);
            }
        }
        else if (event.type == TouchEvent.TOUCH_END)
        {
            var action = touches.get(id);
            if (action == 'move' && moveTouch == id)
            {
                moveTouch = -1;
            }
            else if (action == 'wheel' && wheelTouch == id)
            {
                wheelTouch = -1;
                scrollRemainder = 0;
                panel.setPressed('wheel', false);
            }
            else if (action == 'sensitivity' && sensitivityTouch == id)
            {
                sensitivityTouch = -1;
                panel.setPressed('sensitivity', false);
            }
            else if (action == 'close')
            {
                release(action);
                // OpenFL dispatches TOUCH_TAP after TOUCH_END for the same touch.
                closeRequested = panel.actionAt(event.stageX, event.stageY) == 'close';
            }
            else if (action != null) release(action);
            touches.remove(id);
        }
    }

    function beginTouch(event:TouchEvent):Void
    {
        var id = event.touchPointID;
        switch (panel.actionAt(event.stageX, event.stageY))
        {
            case 'idle':
            case 'wheel':
                if (wheelTouch != -1) return;
                wheelTouch = id;
                wheelLastY = event.stageY;
                scrollRemainder = 0;
                touches.set(id, 'wheel');
                panel.setPressed('wheel', true);
            case 'sensitivity':
                if (sensitivityTouch != -1) return;
                sensitivityTouch = id;
                touches.set(id, 'sensitivity');
                changeSensitivity(event.stageX);
                panel.setPressed('sensitivity', true);
            case null:
                if (moveTouch != -1) return;
                moveTouch = id;
                lastX = event.stageX;
                lastY = event.stageY;
                touches.set(id, 'move');
            case action:
                touches.set(id, action);
                press(action);
        }
    }

    function movePointer(x:Float, y:Float):Void
    {
        var old = FlxG.game.globalToLocal(new Point(lastX, lastY));
        var next = FlxG.game.globalToLocal(new Point(x, y));
        var topLeft = FlxG.game.globalToLocal(new Point(0, 0));
        var bottomRight = FlxG.game.globalToLocal(new Point(surfaceWidth, surfaceHeight));
        var gain = 0.4 + sensitivity * 1.2;
        mouse.virtualX = clampPosition(mouse.virtualX + (next.x - old.x) * gain, topLeft.x, bottomRight.x);
        mouse.virtualY = clampPosition(mouse.virtualY + (next.y - old.y) * gain, topLeft.y, bottomRight.y);
        lastX = x;
        lastY = y;
        dispatchMouse(MouseEvent.MOUSE_MOVE);
    }

    inline function clampPosition(value:Float, start:Float, end:Float):Float
    {
        return Math.max(Math.min(start, end), Math.min(Math.max(start, end), value));
    }

    function changeSensitivity(x:Float):Void
    {
        sensitivity = panel.sensitivityAt(x);
        panel.setSensitivity(sensitivity);
    }

    function press(action:String):Void
    {
        var count = held.exists(action) ? held.get(action) : 0;
        held.set(action, count + 1);
        if (count != 0) return;
        panel.setPressed(action, true);
        switch (action)
        {
            case 'left', 'right':
                var right = action == 'right';
                mouse.queueButton(right, true);
                dispatchMouse(right ? MouseEvent.RIGHT_MOUSE_DOWN : MouseEvent.MOUSE_DOWN);
            case 'keyboard':
                releaseAll();
                keyboardVisible = !keyboardVisible;
                layout();
            case 'close':
            default:
                keyboardInput.press(action);
                updateModifierHighlights();
        }
    }

    function release(action:String, cancelClick:Bool = false):Void
    {
        var count = held.exists(action) ? held.get(action) : 0;
        if (count <= 1) held.remove(action); else { held.set(action, count - 1); return; }
        if (count == 0) return;
        panel.setPressed(action, keyboardInput.isLatched(action));
        switch (action)
        {
            case 'left', 'right':
                var right = action == 'right';
                mouse.queueButton(right, false);
                dispatchMouse(right ? MouseEvent.RIGHT_MOUSE_UP : MouseEvent.MOUSE_UP, 0, cancelClick);
            default: keyboardInput.release(action);
        }
    }

    function updateModifierHighlights():Void
    {
        for (action in MODIFIERS) panel.setPressed(action, keyboardInput.isLatched(action));
    }

    function processKeyQueue():Void
    {
        if (active) keyboardInput.update();
    }

    function dispatchMouse(type:String, delta:Int = 0, cancelClick:Bool = false):Void
    {
        mouse.syncPosition();
        var position = FlxG.game.localToGlobal(new Point(mouse.virtualX, mouse.virtualY));
        // OpenFL uses this path for hit testing, focus, hover, click and drag state.
        var nativePosition = @:privateAccess rootStage.__displayMatrix.transformPoint(position);
        dispatchStageMouse(type, nativePosition, delta, cancelClick);
    }

    function dispatchStageMouse(type:String, nativePosition:Point, delta:Int, cancelClick:Bool):Void
    {
        var button = (type == MouseEvent.RIGHT_MOUSE_DOWN || type == MouseEvent.RIGHT_MOUSE_UP) ? 2 : 0;
        var wasSynthesized = synthesized;
        var wasSuppressingClick = suppressCleanupClick;
        var clickHistory = cancelClick ? @:privateAccess {target: rootStage.__lastClickTarget, time: rootStage.__lastClickTime} : null;
        synthesized = true;
        suppressCleanupClick = wasSuppressingClick || cancelClick;
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
        catch (error:Dynamic)
        {
            restoreMouseDispatch(wasSynthesized, wasSuppressingClick, clickHistory);
            throw error;
        }
        restoreMouseDispatch(wasSynthesized, wasSuppressingClick, clickHistory);
    }

    function restoreMouseDispatch(wasSynthesized:Bool, wasSuppressingClick:Bool, history:Null<{target:InteractiveObject, time:Int}>):Void
    {
        synthesized = wasSynthesized;
        suppressCleanupClick = wasSuppressingClick;
        if (history != null)
        {
            @:privateAccess rootStage.__lastClickTarget = history.target;
            @:privateAccess rootStage.__lastClickTime = history.time;
        }
    }

    function layout():Void
    {
        surfaceWidth = rootStage.stageWidth;
        surfaceHeight = rootStage.stageHeight;
        panel.layout(surfaceWidth, surfaceHeight, keyboardVisible, sensitivity);
        for (action in held.keys()) panel.setPressed(action, true);
        panel.setPressed('wheel', wheelTouch != -1);
        updateModifierHighlights();
    }
}
#end
