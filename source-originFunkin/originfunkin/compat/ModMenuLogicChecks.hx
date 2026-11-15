package originfunkin.compat;

#if (sys && FEATURE_DEBUG_FUNCTIONS)
import funkin.ui.modmenu.ModMenuState;
import funkin.ui.modmenu.ModMenuItem;

using Lambda;

/** Exercise menu list operations and transitions; OS keyboard delivery is separate. */
@:access(funkin.ui.modmenu.ModMenuState)
class ModMenuLogicChecks extends ModMenuState
{
  var checkPhase:Int = 0;
  var checkElapsed:Float = 0;
  var originalOrder:Array<String> = [];
  var probe:Null<ModMenuItem>;
  var probeIndex:Int = -1;

  static function require(condition:Bool, message:String):Void
  {
    if (!condition)
    {
      trace('[Origin mod menu check] FAIL $message');
      Sys.exit(1);
    }
    trace('[Origin mod menu check] PASS $message');
  }

  function enabledIds():Array<String>
  {
    return enabledModItems.modItems.map(item -> item.getModId());
  }

  override public function create():Void
  {
    super.create();
    originalOrder = enabledIds();
    probe = disabledModItems.modItems.find(item -> item.getModId() == 'YOURSELF');
    require(probe != null && originalOrder.length >= 2 && originalOrder[0] == ModMenuState.BASE_GAME_MOD_ID,
      'installed disabled YOURSELF and pinned base game are available');
  }

  override public function update(elapsed:Float):Void
  {
    super.update(elapsed);
    if (checkPhase >= 5) return;
    checkElapsed += elapsed;
    if (checkElapsed < 0.6 || hasTransitions()) return;
    checkElapsed = 0;
    switch (checkPhase)
    {
      case 0:
        require(enableMod(probe), 'enable accepts compatible installed metadata');
      case 1:
        require(enabledModItems.modItems.filter(item -> item == probe).length == 1
          && !disabledModItems.modItems.contains(probe), 'enable transition moves exactly one item between lists');
        probeIndex = enabledModItems.modItems.indexOf(probe);
        require(probeIndex > 1, 'enabled probe can exchange priority with another mod');
        orderMod(probe, false);
        require(enabledModItems.modItems.indexOf(probe) == probeIndex - 1
          && enabledIds()[0] == ModMenuState.BASE_GAME_MOD_ID, 'lower priority changes one slot and preserves pinned base game');
      case 2:
        orderMod(probe, true);
        require(enabledModItems.modItems.indexOf(probe) == probeIndex
          && enabledModItems.selectedModItem == probe, 'raise priority restores one slot and retains selection');
        var before = enabledIds().join('|');
        orderMod(enabledModItems.getPinnedTopItem(), true);
        require(enabledIds().join('|') == before, 'pinned base game cannot be reordered');
      case 3:
        disableMod(probe);
      case 4:
        require(enabledIds().join('|') == originalOrder.join('|')
          && disabledModItems.modItems.filter(item -> item == probe).length == 1,
          'disable transition restores original enabled order and one disabled item');
        trace('[Origin mod menu check] LIST CHECKS PASSED; original selection restored; ready for the real Done button');
      default:
    }
    checkPhase++;
  }
}
#end
