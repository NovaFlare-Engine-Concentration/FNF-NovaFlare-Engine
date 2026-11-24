package funkin.ui.options;

import flixel.FlxCamera;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.FlxG;
import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;
import flixel.math.FlxPoint;
import funkin.ui.AtlasText.AtlasFont;
import funkin.ui.Page;
import funkin.graphics.FunkinCamera;
import funkin.graphics.FunkinSprite;
import funkin.ui.TextMenuList.TextMenuItem;
import funkin.ui.options.items.CheckboxPreferenceItem;
import funkin.ui.options.items.NumberPreferenceItem;
import funkin.ui.options.items.EnumPreferenceItem;
import funkin.ui.debug.FunkinDebugDisplay.DebugDisplayMode;
#if mobile
import funkin.mobile.ui.FunkinBackButton;
import funkin.mobile.input.ControlsHandler;
import funkin.mobile.ui.FunkinHitbox.FunkinHitboxControlSchemes;
import funkin.util.TouchUtil;
import funkin.util.SwipeUtil;
import general.shaders.MobileShaderConverter;
#end
import funkin.util.HapticUtil;
import originfunkin.OriginVSyncMode;
import originfunkin.OriginFunkinConfig;
import originfunkin.OriginFunkinDialog;
import originfunkin.OriginFunkinMode;

import funkin.save.Save;
import developer.display.FPSViewer;
import general.backend.ClientPrefs;
import general.objects.screen.MouseEffect;

class ExtraOptionsMenu extends Page<OptionsState.OptionsMenuPageName>
{
  var items:TextMenuList;
  var preferenceItems:FlxTypedSpriteGroup<FlxSprite>;
  var preferenceDesc:Array<String> = [];
  var itemDesc:FlxText;
  var itemDescBox:FunkinSprite;

  var menuCamera:FlxCamera;
  var hudCamera:FlxCamera;
  var camFollow:FlxObject;
  #if FEATURE_TOUCH_CONTROLS
  var touchController:originfunkin.input.OptionsTouchController;
  #end

  public function new()
  {
    super();

    menuCamera = new FunkinCamera('prefMenu');
    FlxG.cameras.add(menuCamera, false);
    menuCamera.bgColor = 0x0;

    hudCamera = new FlxCamera();
    FlxG.cameras.add(hudCamera, false);
    hudCamera.bgColor = 0x0;

    camera = menuCamera;

    add(items = new TextMenuList());
    add(preferenceItems = new FlxTypedSpriteGroup<FlxSprite>());

    add(itemDescBox = new FunkinSprite());
    itemDescBox.cameras = [hudCamera];

    add(itemDesc = new FlxText(0, 0, 1180, null, 32));
    itemDesc.cameras = [hudCamera];

    createPrefItems();
    createPrefDescription();

    camFollow = new FlxObject(FlxG.width / 2, 0, 140, 70);

    menuCamera.follow(camFollow, null, 0.085);
    var margin = 160;
    menuCamera.deadzone.set(0, margin, menuCamera.width, menuCamera.height - margin * 2);
    menuCamera.minScrollY = 0;

    items.onChange.add(function(selected)
    {
      itemDesc.text = preferenceDesc[items.selectedIndex];
      #if FEATURE_TOUCH_CONTROLS
      resizeDescriptionBox();
      #end
    });

    #if FEATURE_TOUCH_CONTROLS
    touchController = new originfunkin.input.OptionsTouchController(items, menuCamera, FlxG.height - 190);
    var hint = new FlxText(20, FlxG.height - 28, FlxG.width - 260,
      'Tap to select, tap again to change | Selected value: swipe left/right', 16);
    hint.cameras = [hudCamera];
    add(hint);
    var backButton:FunkinBackButton = new FunkinBackButton(FlxG.width - 230, FlxG.height - 200, FlxColor.WHITE, exit, 1.0);
    backButton.cameras = [hudCamera];
    backButton.requireFreshPress = true;
    add(backButton);
    #end
  }

  override function update(elapsed:Float):Void
  {
    super.update(elapsed);

    #if FEATURE_TOUCH_CONTROLS
    touchController.update(elapsed, enabled && exists && visible && FlxG.state.subState == null);
    #else
    if (items != null) camFollow.y = items.selectedItem.y;
    #end

    items.forEach(function(daItem:TextMenuItem)
    {
      var thyOffset:Int = 0;
      var thyTextWidth:Int = 0;

      switch (Type.typeof(daItem))
      {
        case TClass(CheckboxPreferenceItem):
          thyOffset = 0;
        case TClass(EnumPreferenceItem):
          thyTextWidth = cast(daItem, EnumPreferenceItem<Dynamic>).lefthandText.getWidth();
          thyOffset = thyTextWidth - 75;
        case TClass(NumberPreferenceItem):
          thyTextWidth = cast(daItem, NumberPreferenceItem).lefthandText.getWidth();
          thyOffset = thyTextWidth - 75;
        default:
          thyOffset = 0;
      }

      if (items.selectedItem == daItem)
      {
        thyOffset += 150;
      }
      else
      {
        thyOffset += 120;
      }

      daItem.x = thyOffset + funkin.ui.FullScreenScaleMode.gameNotchSize.x;
    });
  }

  function createPrefDescription():Void
  {
    itemDescBox.makeSolidColor(1, 1, FlxColor.BLACK);
    itemDescBox.alpha = 0.6;
    itemDesc.setFormat(Paths.font('vcr.ttf'), 32, FlxColor.WHITE, FlxTextAlign.CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
    itemDesc.borderSize = 3;

    itemDesc.text = preferenceDesc[items.selectedIndex];
    itemDesc.screenCenter();
    itemDesc.y += 270;

    #if FEATURE_TOUCH_CONTROLS
    itemDesc.size = 24;
    itemDesc.fieldWidth = FlxG.width - 300;
    itemDesc.setPosition(30, FlxG.height - 170);
    #end

    resizeDescriptionBox();
  }

  function resizeDescriptionBox():Void
  {
    itemDescBox.setPosition(itemDesc.x - 10, itemDesc.y - 10);
    itemDescBox.setGraphicSize(Std.int(itemDesc.width + 20), Std.int(itemDesc.height + 25));
    itemDescBox.updateHitbox();
  }

  function createPrefItems():Void
  {
    createPrefItemEnum('FPS View Mode', 'Select the FPS display mode.\nFPS: show FPS\nTPS: Show TPS\nOff: Completely hidden',
      [
        "FPS" => "FPS",
        "TPS" => "TPS",
        "Off" => "Off"
      ],
      function(key:String, value:String):Void
      {
        var save = Save.instance;
        save.options.novaSettings.fpsViewMode = value;
        save.flush();

        applyFpsMode(value);
      },
      getCurrentFpsViewMode()
    );

    createPrefItemNumber('FPS View Scale', 'Switch the scale of the FPS display.\n0.5x: Half size\n1.0x: Normal size\n2.0x: Double size',
      function(value:Float):Void
      {
        var save = Save.instance;
        save.options.novaSettings.fpsViewScale = value;
        save.flush();

        applyFpsScale(value);
      },
      function(value:Float):String
      {
        return '${Math.round(value * 100)}%';
      },
      getCurrentFpsScale(),
      0.5,
      2.0,
      0.1,
      1
    );

    createPrefItemCheckbox('Skip Video', 'Skip video when starting the engine',
      function(value:Bool):Void
      {
        var save = Save.instance;
        save.options.novaSettings.skipVideo = value;
        save.flush();
      },
      getCurrentSkipVideo()
    );

    createPrefItemCheckbox('Mouse Effects', 'Controls pointer trails and click effects outside PlayState.',
      function(value:Bool):Void
      {
        var save = Save.instance;
        save.options.novaSettings.mouseEffects = value;
        save.flush();
        MouseEffect.setUserEffectsEnabled(value);
      },
      getCurrentMouseEffects()
    );

    createPrefItemCheckbox('Trace Console', 'Show the game log.',
      function(value:Bool):Void
      {
        final save = Save.instance;
        save.options.novaSettings ??= Save.getDefaultData().options.novaSettings;
        save.novaSettings.traceConsole = value;
        save.flush();
        developer.console.Console.setAvailability(Origin, value);
      },
      Save.instance.novaSettings?.traceConsole == true
    );

    #if mobile
    createPrefItemCheckbox('Automatic Shader Conversion',
      'Automatically converts desktop OpenFL shaders for OpenGL ES 2.0 and 3.0+.',
      function(value:Bool):Void
      {
        var save = Save.instance;
        save.options.novaSettings.autoShaderConversion = value;
        save.flush();
        MobileShaderConverter.setEnabled(value);
      },
      getCurrentAutoShaderConversion()
    );
    #end
  }

  function getCurrentFpsViewMode():String
  {
    var save = Save.instance;
    if (save.options.novaSettings == null) return "FPS";
    return save.options.novaSettings.fpsViewMode ?? "FPS";
  }

  function getCurrentFpsScale():Float
  {
    var save = Save.instance;
    if (save.options.novaSettings == null) return 1.0;
    return save.options.novaSettings.fpsViewScale ?? 1.0;
  }

  function getCurrentSkipVideo():Bool
  {
    var save = Save.instance;
    if (save.options.novaSettings == null) return false;
    return save.options.novaSettings.skipVideo ?? false;
  }

  function getCurrentMouseEffects():Bool
  {
    var settings = Save.instance.options.novaSettings;
    return settings == null ? true : settings.mouseEffects;
  }

  #if mobile
  function getCurrentAutoShaderConversion():Bool
  {
    var settings = Save.instance.options.novaSettings;
    return settings == null ? true : (settings.autoShaderConversion ?? true);
  }
  #end

  function applyFpsScale(scale:Float):Void
  {
    originfunkin.OriginFpsDisplay.applyScale(scale);
  }

  function applyFpsMode(mode:String):Void
  {
    #if sys
    var fpsCounter = FPSViewer.fpsShow;
    var extraCounter = FPSViewer.extraShow;

    if (fpsCounter != null && extraCounter != null)
    {
      switch (mode)
      {
        case "FPS":
          ClientPrefs.data.fpsDisplayMode = "FPS";
          fpsCounter.alpha = 1;
          fpsCounter.update();

        case "TPS":
          ClientPrefs.data.fpsDisplayMode = "TPS";
          fpsCounter.alpha = 1;
          fpsCounter.update();

        case "Off":
          fpsCounter.alpha = 0;
          extraCounter.alpha = 0;
          extraCounter.graphMonitor.setRenderingEnabled(false);

        default:
      }
    }

    if (Main.fpsVar != null)
    {
      Main.fpsVar.visible = (mode != "Off");
    }
    #end
  }

  function createPrefItemCheckbox(prefName:String, prefDesc:String, onChange:Bool->Void, defaultValue:Bool,
      available:Bool = true):CheckboxPreferenceItem
  {
    var checkbox:CheckboxPreferenceItem = new CheckboxPreferenceItem(funkin.ui.FullScreenScaleMode.gameNotchSize.x, 120 * (items.length - 1 + 1),
      defaultValue, available);

    items.createItem(0, (120 * items.length) + 30, prefName, AtlasFont.BOLD, function()
    {
      var value = !checkbox.currentValue;
      onChange(value);
      checkbox.currentValue = value;
    }, false, available);

    preferenceItems.add(checkbox);
    preferenceDesc.push(prefDesc);
    return checkbox;
  }

  function createPrefItemNumber(prefName:String, prefDesc:String, onChange:Float->Void, ?valueFormatter:Float->String, defaultValue:Float, min:Float,
      max:Float, step:Float = 0.1, precision:Int):Void
  {
    var item = new NumberPreferenceItem(funkin.ui.FullScreenScaleMode.gameNotchSize.x, (120 * items.length) + 30, prefName, defaultValue, min, max, step,
      precision, onChange, valueFormatter);
    items.addItem(prefName, item);
    preferenceItems.add(item.lefthandText);
    preferenceDesc.push(prefDesc);
  }

  function createPrefItemEnum<T>(prefName:String, prefDesc:String, values:Map<String, T>, onChange:String->T->Void, defaultKey:String):Void
  {
    var item = new EnumPreferenceItem<T>(funkin.ui.FullScreenScaleMode.gameNotchSize.x, (120 * items.length) + 30, prefName, values, defaultKey, onChange);
    items.addItem(prefName, item);
    preferenceItems.add(item.lefthandText);
    preferenceDesc.push(prefDesc);
  }

  override function exit():Void
  {
    #if FEATURE_TOUCH_CONTROLS
    touchController.reset();
    #else
    camFollow.setPosition(640, 30);
    menuCamera.snapToTarget();
    #end
    super.exit();
  }

  override function destroy():Void
  {
    #if FEATURE_TOUCH_CONTROLS
    touchController.destroy();
    #end
    super.destroy();
  }
}
