package mobile.input;

#if (mobile && FLX_MOUSE)
import flixel.FlxG;
import flixel.input.mouse.FlxMouse;
import openfl.display.BitmapData;
import openfl.display.Sprite;
import openfl.events.MouseEvent;

/** A normal FlxMouse until virtual mode is enabled; the original event listeners
    are disconnected only while touch is driving the pointer. */
@:access(flixel.input.mouse.FlxMouse)
@:access(flixel.input.FlxPointer)
class VirtualMouse extends FlxMouse
{
    public var virtualActive(default, null):Bool = false;
    public var virtualX:Float = 0;
    public var virtualY:Float = 0;
    public var onInputStep:Void->Void;
    var transitions:Array<{right:Bool, down:Bool}> = [];
    var previousFrameX:Int = 0;
    var previousFrameY:Int = 0;
    var previousFrameViewX:Int = 0;
    var previousFrameViewY:Int = 0;

    public static function install():VirtualMouse
    {
        if (Std.isOfType(FlxG.mouse, VirtualMouse)) return cast FlxG.mouse;
        var old = FlxG.mouse;
        if (old == null || old.cursorContainer == null) return null;
        var container = old.cursorContainer;
        var wasVisible = old.visible;
        var wasSystem = old.useSystemCursor;
        var image:BitmapData = old.cursor != null && old.cursor.bitmapData != null ? old.cursor.bitmapData.clone() : null;
        var scale = old.cursor != null ? old.cursor.scaleX : 1.0;
        var offsetX = old.cursor != null ? Std.int(old.cursor.x) : 0;
        var offsetY = old.cursor != null ? Std.int(old.cursor.y) : 0;
        if (old.cursor != null && old.cursor.parent == container) container.removeChild(old.cursor);
        var result = new VirtualMouse(container);
        FlxG.mouse = result;
        if (FlxG.mouse != result) return null;
        if (image != null) result.load(image, scale, offsetX, offsetY);
        result.useSystemCursor = wasSystem;
        result.visible = wasVisible;
        return result;
    }

    public function new(container:Sprite)
    {
        super(container);
    }

    public function setVirtualActive(value:Bool):Void
    {
        if (virtualActive == value) return;
        transitions = [];
        reset();
        virtualActive = value;
        if (value)
        {
            previousFrameX = x;
            previousFrameY = y;
            previousFrameViewX = viewX;
            previousFrameViewY = viewY;
            detachPhysical();
        }
        else attachPhysical();
    }

    function detachPhysical():Void
    {
        _stage.removeEventListener(MouseEvent.MOUSE_DOWN, _leftButton.onDown);
        _stage.removeEventListener(MouseEvent.MOUSE_UP, _leftButton.onUp);
        _stage.removeEventListener(MouseEvent.MOUSE_WHEEL, onMouseWheel);
        #if FLX_MOUSE_ADVANCED
        _stage.removeEventListener(MouseEvent.RIGHT_MOUSE_DOWN, _rightButton.onDown);
        _stage.removeEventListener(MouseEvent.RIGHT_MOUSE_UP, _rightButton.onUp);
        _stage.removeEventListener(MouseEvent.MIDDLE_MOUSE_DOWN, _middleButton.onDown);
        _stage.removeEventListener(MouseEvent.MIDDLE_MOUSE_UP, _middleButton.onUp);
        #end
    }

    function attachPhysical():Void
    {
        _stage.addEventListener(MouseEvent.MOUSE_DOWN, _leftButton.onDown);
        _stage.addEventListener(MouseEvent.MOUSE_UP, _leftButton.onUp);
        _stage.addEventListener(MouseEvent.MOUSE_WHEEL, onMouseWheel);
        #if FLX_MOUSE_ADVANCED
        _stage.addEventListener(MouseEvent.RIGHT_MOUSE_DOWN, _rightButton.onDown);
        _stage.addEventListener(MouseEvent.RIGHT_MOUSE_UP, _rightButton.onUp);
        _stage.addEventListener(MouseEvent.MIDDLE_MOUSE_DOWN, _middleButton.onDown);
        _stage.addEventListener(MouseEvent.MIDDLE_MOUSE_UP, _middleButton.onUp);
        #end
    }

    public function queueButton(right:Bool, down:Bool):Void
    {
        if (virtualActive) transitions.push({right: right, down: down});
    }

    public function scroll(delta:Int):Void
    {
        if (!virtualActive || delta == 0 || !enabled) return;
        wheel = (_wheelUsed ? wheel : 0) + delta;
        _wheelUsed = true;
    }

    public function syncPosition():Void
    {
        if (!virtualActive) return;
        setRawPositionUnsafe(virtualX, virtualY);
        if (visible)
        {
            cursorContainer.x = virtualX;
            cursorContainer.y = virtualY;
        }
    }

    override function handleInput():Void
    {
        if (!virtualActive)
        {
            super.handleInput();
            return;
        }
        _prevX = previousFrameX;
        _prevY = previousFrameY;
        _prevViewX = previousFrameViewX;
        _prevViewY = previousFrameViewY;
        syncPosition();
        previousFrameX = x;
        previousFrameY = y;
        previousFrameViewX = viewX;
        previousFrameViewY = viewY;
        _leftButton.handleInput();
        #if FLX_MOUSE_ADVANCED
        _middleButton.handleInput();
        _rightButton.handleInput();
        #end
        if (!_wheelUsed) wheel = 0;
        _wheelUsed = false;
        // A down and up delivered between frames must still be observable.
        if (transitions.length > 0)
        {
            var item = transitions.shift();
            if (item.right)
            {
                #if FLX_MOUSE_ADVANCED
                if (item.down) _rightButton.onDown(null); else _rightButton.onUp();
                #end
            }
            else if (item.down) _leftButton.onDown(null); else _leftButton.onUp();
        }
        if (onInputStep != null) onInputStep();
    }
}
#end
