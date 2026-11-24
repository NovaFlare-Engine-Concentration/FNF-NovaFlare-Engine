package originfunkin.input;

#if FEATURE_TOUCH_CONTROLS
import flixel.FlxG;
import flixel.FlxCamera;
import flixel.input.FlxPointer;
import flixel.input.touch.FlxTouch;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import funkin.ui.MenuList.MenuTypedList;
import funkin.ui.TextMenuList;
import funkin.ui.TextMenuList.TextMenuItem;
import funkin.ui.options.items.NumberPreferenceItem;
import funkin.ui.options.items.EnumPreferenceItem;
import funkin.audio.FunkinSound;
import funkin.Paths;
#if (mobile && FLX_MOUSE)
import mobile.input.VirtualMouse;
#end

/** A settings page owns one contact until release, independently of global menu swipes. */
class OptionsTouchController
{
  static inline final DRAG_THRESHOLD:Float = 12;
  static inline final STEP_DISTANCE:Float = 40;
  var items:TextMenuList;
  var camera:FlxCamera;
  var viewportBottom:Float;
  var rowSpacing:Float;
  var point:FlxPoint = new FlxPoint();
  var contact:Null<FlxPointer>;
  #if (mobile && FLX_MOUSE)
  var virtualMouse:Null<VirtualMouse>;
  #end
  var pressTime:Int = -1;
  var startX:Float = 0;
  var startY:Float = 0;
  var previousY:Float = 0;
  var stepX:Float = 0;
  var pressedRow:Int = -1;
  var selectedAtPress:Bool = false;
  var direction:Int = 0; // 0: tap, 1: vertical scroll, 2: horizontal value adjustment
  var velocity:Float = 0;
  var lastSelected:Int;

  public function new(items:TextMenuList, camera:FlxCamera, viewportBottom:Float, rowSpacing:Float = 120)
  {
    this.items = items;
    this.camera = camera;
    this.viewportBottom = viewportBottom;
    this.rowSpacing = rowSpacing;
    lastSelected = items.selectedIndex;
    items.touchNavigationEnabled = false;
    camera.target = null;
    camera.scroll.y = 0;
    for (item in items.members)
    {
      if (Std.isOfType(item, NumberPreferenceItem)) cast(item, NumberPreferenceItem).touchControlsEnabled = false;
      else if (Std.isOfType(item, EnumPreferenceItem)) cast(item, EnumPreferenceItem<Dynamic>).touchControlsEnabled = false;
    }
  }

  public function reset():Void
  {
    contact = null;
    velocity = 0;
    direction = 0;
    selectedAtPress = false;
  }

  public function destroy():Void
  {
    reset();
    point.destroy();
  }

  public function update(elapsed:Float, enabled:Bool):Void
  {
    if (!enabled || !items.enabled || items.busy || MenuTypedList.pauseInput || !Math.isFinite(elapsed) || elapsed <= 0)
    {
      reset();
      return;
    }

    #if (mobile && FLX_MOUSE)
    var activeMouse = VirtualMouse.getActive();
    if (virtualMouse != activeMouse)
    {
      reset();
      virtualMouse = activeMouse;
    }
    #end

    // Keyboard and gamepad selection remains visible, without snapping a touch scroll back.
    if (lastSelected != items.selectedIndex)
    {
      reset();
      var item = items.selectedItem;
      if (item.y < camera.scroll.y + 20) camera.scroll.y = item.y - 20;
      else if (item.y + item.height > camera.scroll.y + viewportBottom - 20)
        camera.scroll.y = item.y + item.height - viewportBottom + 20;
      lastSelected = items.selectedIndex;
    }

    if (contact == null)
    {
      #if (mobile && FLX_MOUSE)
      if (virtualMouse != null)
      {
        if (virtualMouse.justPressed) beginContact(virtualMouse, virtualMouse.justPressedTimeInTicks);
      }
      else
      #end
      {
        for (touch in FlxG.touches.list)
        {
          if (!touch.justPressed || funkin.mobile.ui.FunkinButton.buttonsTouchID.exists(touch.touchPointID)) continue;
          if (beginContact(touch, touch.justPressedTimeInTicks)) break;
        }
      }
      if (contact == null)
      {
        scrollBy(velocity * elapsed);
        velocity *= Math.exp(-8 * elapsed);
        if (Math.abs(velocity) < 5) velocity = 0;
        return;
      }
    }

    var pressed:Bool;
    var released:Bool;
    #if (mobile && FLX_MOUSE)
    if (virtualMouse != null)
    {
      if (contact != virtualMouse || virtualMouse.justPressedTimeInTicks != pressTime)
      {
        reset();
        return;
      }
      pressed = virtualMouse.pressed;
      released = virtualMouse.justReleased;
    }
    else
    #end
    {
      var touch:FlxTouch = cast contact;
      if (FlxG.touches.list.indexOf(touch) < 0 || touch.justPressedTimeInTicks != pressTime)
      {
        reset();
        return;
      }
      pressed = touch.pressed;
      released = touch.justReleased;
    }
    if (!pressed && !released)
    {
      reset();
      return;
    }
    contact.getViewPosition(camera, point);
    var dx = point.x - startX;
    var dy = point.y - startY;
    if (direction == 0 && (Math.abs(dx) >= DRAG_THRESHOLD || Math.abs(dy) >= DRAG_THRESHOLD))
    {
      direction = Math.abs(dy) >= Math.abs(dx) ? 1 : 2;
      if (direction == 2 && pressedRow >= 0) selectRow(pressedRow);
    }

    if (direction == 1)
    {
      var delta = previousY - point.y;
      scrollBy(delta);
      if (delta != 0) velocity = FlxMath.bound(delta / elapsed, -2200, 2200);
      else velocity *= Math.exp(-12 * elapsed);
    }
    else if (direction == 2 && pressedRow >= 0 && selectedAtPress)
    {
      var steps = Std.int((point.x - stepX) / STEP_DISTANCE);
      if (steps != 0)
      {
        stepX += steps * STEP_DISTANCE;
        adjust(items.members[pressedRow], steps);
      }
    }
    previousY = point.y;
    scrollBy(0);

    if (released)
    {
      contact = null;
      if (direction == 0 && point.x >= 0 && point.x <= camera.width && point.y >= 0 && point.y < viewportBottom
        && pressedRow >= 0 && rowAt(point.y) == pressedRow)
      {
        if (!selectedAtPress)
        {
          selectRow(pressedRow);
        }
        else
        {
          var item = items.members[pressedRow];
          if (!adjust(item, point.x < camera.width / 2 ? -1 : 1, true)) items.acceptInstantly();
        }
      }
      if (direction != 1) velocity = 0;
    }
  }

  function beginContact(pointer:FlxPointer, tick:Int):Bool
  {
    pointer.getViewPosition(camera, point);
    if (point.x < 0 || point.x > camera.width || point.y < 0 || point.y >= viewportBottom) return false;
    contact = pointer;
    pressTime = tick;
    startX = stepX = point.x;
    startY = previousY = point.y;
    pressedRow = rowAt(point.y);
    selectedAtPress = pressedRow >= 0 && pressedRow == items.selectedIndex;
    direction = 0;
    velocity = 0;
    return true;
  }

  function selectRow(index:Int):Void
  {
    if (items.selectedIndex != index)
    {
      FunkinSound.playOnce(Paths.sound('scrollMenu'), 0.4);
      items.selectItem(index);
    }
    lastSelected = items.selectedIndex;
  }

  function rowAt(viewY:Float):Int
  {
    var worldY = viewY + camera.scroll.y;
    for (i in 0...items.members.length)
    {
      var item = items.members[i];
      if (item != null && item.available && worldY >= item.y - 20 && worldY < item.y + rowSpacing - 20) return i;
    }
    return -1;
  }

  function adjust(item:TextMenuItem, steps:Int, confirm:Bool = false):Bool
  {
    var changed = false;
    if (Std.isOfType(item, NumberPreferenceItem))
    {
      var number = cast(item, NumberPreferenceItem);
      var previousValue = number.currentValue;
      number.changeBySteps(steps);
      changed = number.currentValue != previousValue;
    }
    else if (Std.isOfType(item, EnumPreferenceItem))
    {
      var choice = cast(item, EnumPreferenceItem<Dynamic>);
      var previousKey = choice.currentKey;
      choice.changeBySteps(steps);
      changed = choice.currentKey != previousKey;
    }
    else return false;
    if (changed) FunkinSound.playOnce(Paths.sound(confirm ? 'confirmMenu' : 'scrollMenu'), confirm ? 1.0 : 0.4);
    return true;
  }

  function scrollBy(delta:Float):Void
  {
    var last = items.members[items.members.length - 1];
    var maxScroll = last == null ? 0 : Math.max(0, last.y + Math.max(last.height, rowSpacing - 20) + 20 - viewportBottom);
    var requested = camera.scroll.y + delta;
    camera.scroll.y = FlxMath.bound(requested, 0, maxScroll);
    if (camera.scroll.y != requested) velocity = 0;
  }
}
#end
