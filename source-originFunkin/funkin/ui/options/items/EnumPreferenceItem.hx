package funkin.ui.options.items;

import funkin.ui.TextMenuList.TextMenuItem;
import funkin.ui.AtlasText;
import funkin.input.Controls;
#if FEATURE_TOUCH_CONTROLS
import funkin.util.SwipeUtil;
#end

/**
 * Preference item that allows the player to pick a value from an enum (list of values)
 */
class EnumPreferenceItem<T> extends TextMenuItem
{
  function controls():Controls
  {
    return PlayerSettings.player1.controls;
  }

  public var lefthandText:AtlasText;
  public var currentKey:String;
  public var onChangeCallback:Null<String->T->Void>;
  public var map:Map<String, T>;
  public var keys:Array<String> = [];
  public var touchControlsEnabled:Bool = true;

  var index = 0;

  public function new(x:Float, y:Float, name:String, map:Map<String, T>, defaultKey:String, ?callback:String->T->Void)
  {
    super(x, y, name, function()
    {
      var value = map.get(this.currentKey);
      callback(this.currentKey, value);
    });

    updateHitbox();

    this.map = map;
    this.currentKey = defaultKey;
    this.onChangeCallback = callback;

    var i:Int = 0;
    for (key in map.keys())
    {
      this.keys.push(key);
      if (this.currentKey == key) index = i;
      i += 1;
    }

    lefthandText = new AtlasText(x + 15, y, formatted(defaultKey), AtlasFont.DEFAULT);

    this.fireInstantly = true;
  }

  override function update(elapsed:Float):Void
  {
    super.update(elapsed);

    // var fancyTextFancyColor:Color;
    if (selected)
    {
      var shouldDecrease:Bool = controls().UI_LEFT_P #if mobile || (touchControlsEnabled && SwipeUtil.justSwipedLeft) #end;
      var shouldIncrease:Bool = controls().UI_RIGHT_P #if mobile || (touchControlsEnabled && SwipeUtil.justSwipedRight) #end;
      if (shouldDecrease != shouldIncrease) changeBySteps(shouldDecrease ? -1 : 1);
    }

    lefthandText.text = formatted(currentKey);
  }

  public function changeBySteps(count:Int):Void
  {
    if (keys.length == 0) return;
    var nextIndex = ((index + count) % keys.length + keys.length) % keys.length;
    if (nextIndex == index) return;
    index = nextIndex;
    currentKey = keys[index];
    lefthandText.text = formatted(currentKey);
    if (onChangeCallback != null) onChangeCallback(currentKey, map.get(currentKey));
  }

  function formatted(key:String):String
  {
    // FIXME: Can't add arrows around the text because the font doesn't support < >
    // var leftArrow:String = selected ? '<' : '';
    // var rightArrow:String = selected ? '>' : '';
    return '${key}';
  }
}
