package funkin.ui.debug;

#if FEATURE_TOUCH_CONTROLS
import flixel.util.FlxColor;
import originfunkin.input.OptionsTouchController;
#else
import flixel.math.FlxPoint;
import flixel.FlxObject;
#end
import flixel.FlxSprite;
import funkin.ui.MusicBeatSubState;
import funkin.ui.FullScreenScaleMode;
import funkin.audio.FunkinSound;
import funkin.ui.TextMenuList;
import flixel.addons.transition.FlxTransitionableState;
#if FEATURE_CHART_EDITOR
import funkin.ui.debug.charting.ChartEditorState;
#end
#if (sys && desktop)
import funkin.util.logging.CrashHandler;
import funkin.util.FileUtil;
#end

class DebugMenuSubState extends MusicBeatSubState
{
  var items:TextMenuList;
  static inline final ROW_SPACING:Int = 100;

  #if FEATURE_TOUCH_CONTROLS
  var touchController:OptionsTouchController;
  #else
  /**
   * Camera focus point
   */
  var camFocusPoint:FlxObject;
  #end

  override function create():Void
  {
    FlxTransitionableState.skipNextTransIn = true;
    super.create();

    bgColor = 0x00000000;

    #if !FEATURE_TOUCH_CONTROLS
    // Create an object for the camera to track.
    camFocusPoint = new FlxObject(0, 0);
    add(camFocusPoint);

    // Follow the camera focus as we scroll.
    FlxG.camera.follow(camFocusPoint, null, 0.06);
    #end

    // Create the green background.
    var menuBG = new FlxSprite().loadGraphic(Paths.image('ui/main-menu/menu-desat'));
    menuBG.color = 0xFF4CAF50;
    menuBG.setGraphicSize(Std.int(menuBG.width * 1.1 * FullScreenScaleMode.wideScale.x));
    menuBG.updateHitbox();
    menuBG.screenCenter();
    menuBG.scrollFactor.set(0, 0);
    add(menuBG);

    // Create the list for menu items.
    items = new TextMenuList();
    #if !FEATURE_TOUCH_CONTROLS
    // Move the camera when the menu is scrolled.
    items.onChange.add(onMenuChange);
    #end
    add(items);

    FlxTransitionableState.skipNextTransIn = true;

    // Create each menu item.
    // Call onMenuChange when the first item is created to move the camera .
    #if FEATURE_CHART_EDITOR
    createItem("CHART EDITOR", openChartEditor);
    #end
    #if FEATURE_CAMERA_EDITOR
    createItem("CAMERA EDITOR", openCameraEditor);
    #end
    #if (FEATURE_POLYMOD_MODS || android)
    createItem("MOD MENU", openModMenu);
    #end
    #if android
    createItem("CHARACTER SELECT", openCharSelect);
    #end
    #if FEATURE_ANIMATION_EDITOR
    createItem("ANIMATION EDITOR", openAnimationEditor);
    #end
    #if FEATURE_STAGE_EDITOR
    createItem("STAGE EDITOR", openStageEditor);
    #end
    #if FEATURE_RESULTS_DEBUG
    createItem("RESULTS SCREEN DEBUG", openTestResultsScreen);
    #end
    #if (sys && desktop)
    createItem("OPEN CRASH LOG FOLDER", openLogFolder);
    #end
    #if FEATURE_TOUCH_CONTROLS
    var backButtonTop = FlxG.height - 200;
    touchController = new OptionsTouchController(items, FlxG.camera, backButtonTop, ROW_SPACING);
    addBackButton(FlxG.width - 230, backButtonTop, FlxColor.WHITE, exitDebugMenu, 1.0);
    if (backButton != null)
    {
      backButton.requireFreshPress = true;
      backButton.onConfirmStart.add(() -> items.busy = true);
    }
    #else
    onMenuChange(items.members[0]);
    FlxG.camera.focusOn(new FlxPoint(camFocusPoint.x, camFocusPoint.y + 500));
    #end

    #if (FEATURE_HAXEUI && !android)
    // Remove the "user" stylesheet to prevent components using incorrect style data when entering an editor.
    haxe.ui.Toolkit.styleSheet.clear("user");
    #end
  }

  #if !FEATURE_TOUCH_CONTROLS
  function onMenuChange(selected:TextMenuItem)
  {
    camFocusPoint.setPosition(selected.x + selected.width / 2, selected.y + selected.height / 2);
  }
  #end

  override function update(elapsed:Float):Void
  {
    super.update(elapsed);

    if (controls.BACK_P)
    {
      FunkinSound.playOnce(Paths.sound('ui/main-menu/cancel-menu'));
      exitDebugMenu();
      return;
    }
    #if FEATURE_TOUCH_CONTROLS
    touchController.update(elapsed, subState == null);
    #end
  }

  #if FEATURE_TOUCH_CONTROLS
  override public function destroy():Void
  {
    if (touchController != null) touchController.destroy();
    super.destroy();
  }
  #end

  function createItem(name:String, callback:Void->Void, fireInstantly = false):TextMenuItem
  {
    var item = items.createItem(0, ROW_SPACING + items.length * ROW_SPACING, name, BOLD, callback);
    item.fireInstantly = fireInstantly;
    item.screenCenter(X);
    return item;
  }

  #if FEATURE_CHART_EDITOR
  function openChartEditor():Void
  {
    if (!prepareEditor()) return;
    FlxTransitionableState.skipNextTransIn = true;

    FlxG.switchState(() -> new ChartEditorState());
  }
  #end

  function openCharSelect():Void
  {
    FlxG.switchState(() -> new funkin.ui.charSelect.CharacterSelectState());
  }

  #if FEATURE_ANIMATION_EDITOR
  function openAnimationEditor():Void
  {
    if (!prepareEditor()) return;
    FlxG.switchState(() -> new funkin.ui.debug.anim.DebugBoundingState());
    trace('Animation Editor');
  }
  #end

  function testStickers():Void
  {
    openSubState(new funkin.ui.transition.stickers.StickerSubState({
    }));
    trace('opened stickers');
  }

  #if FEATURE_STAGE_EDITOR
  function openStageEditor():Void
  {
    if (!prepareEditor()) return;
    trace('Stage Editor');
    FlxG.switchState(() -> new funkin.ui.debug.stageeditor.StageEditorState());
  }
  #end

  #if (FEATURE_POLYMOD_MODS || android)
  function openModMenu():Void
  {
    FlxG.switchState(() -> new funkin.ui.modmenu.ModMenuState());
  }
  #end

  #if FEATURE_CAMERA_EDITOR
  function openCameraEditor():Void
  {
    if (!prepareEditor()) return;
    FlxG.switchState(() -> new funkin.ui.debug.cameraeditor.CameraEditorState());
  }
  #end

  #if origin_editors
  function prepareEditor():Bool
  {
    #if android
    try
    {
      originfunkin.OriginFunkinEditors.initialize();
      haxe.ui.Toolkit.styleSheet.clear("user");
    }
    catch (error:haxe.Exception)
    {
      funkin.util.WindowUtil.showError("Origin Editor", error.message);
      return false;
    }
    #end
    return true;
  }
  #end

  #if FEATURE_RESULTS_DEBUG
  function openTestResultsScreen():Void
  {
    FlxG.switchState(() -> new funkin.ui.debug.results.ResultsDebugSubState());
  }
  #end

  #if (sys && desktop)
  function openLogFolder()
  {
    FileUtil.openFolder(CrashHandler.LOG_FOLDER);
  }
  #end

  function exitDebugMenu()
  {
    // TODO: Add a transition?
    this.close();
  }
}
