package originfunkin.compat;

#if (sys && FEATURE_DEBUG_FUNCTIONS)
import flixel.FlxG;
import funkin.play.GameOverSubState;
import funkin.play.PlayState;
using Lambda;

/** Explicit practice/bot-play flow checks; these do not emulate keyboard acceptance. */
@:access(funkin.play.PlayState)
@:access(funkin.play.GameOverSubState)
class GameplayFlowChecks
{
  static var phase:Int = 0;
  static var started:Float;
  static var mode:String;
  static var characterId:String;
  static var renderer:String;
  static var pixel:Bool;
  static var restartSeen:Null<Float>;

  public static function install(state:PlayState):Void
  {
    var argument = Sys.args().find(value -> StringTools.startsWith(value, '--origin-test-flow='));
    if (argument == null || phase != 0) return;
    mode = argument.substr('--origin-test-flow='.length);
    require(mode == 'death' || mode == 'fakeout', 'recognized flow mode');
    require(state.isPracticeMode && state.isBotPlayMode, 'practice and bot play protect scores');
    var character = state.currentStage?.getBoyfriend();
    require(character != null, 'actual stage has a player character');
    characterId = character.characterId;
    renderer = character.renderType;
    pixel = StringTools.contains(characterId, 'pixel');
    FlxG.autoPause = false;
    started = haxe.Timer.stamp();
    phase = 1;
    trace('[Origin gameplay flow check] START mode=$mode character=$characterId renderer=$renderer pixel=$pixel');
    trace('[Origin gameplay flow check] Flow methods are called directly; this is not a keyboard-input test.');
    haxe.Timer.delay(() ->
    {
      require(FlxG.state == state && state.initialized && !state.criticalFailure, 'gameplay reached the death trigger');
      state.moveToGameOver();
      poll();
    }, 6000);
  }

  static function poll():Void
  {
    if (haxe.Timer.stamp() - started > 60) fail('flow timed out');
    var death = GameOverSubState.instance;
    if (phase == 1 && death != null)
    {
      require(death.isFakeout == (mode == 'fakeout'), 'selected death branch executed');
      var character = death.boyfriend;
      var animation = character?.getCurrentAnimation() ?? '';
      if (character != null && !death.mustNotExit && (death.gameOverMusic?.playing ?? false)
        && StringTools.startsWith(animation, 'deathLoop'))
      {
        require(character.characterId == characterId, 'game over uses the actual stage character');
        require(character.frames != null && character.frames.frames.length > 0, 'death renderer has real frames');
        if (pixel)
        {
          require(GameOverSubState.musicSuffix == '-pixel', 'pixel death music suffix');
          require(GameOverSubState.blueBallSuffix == '-pixel', 'pixel loss sound suffix');
        }
        var confirmAnimation = 'deathConfirm' + GameOverSubState.animationSuffix;
        require(character.hasAnimation(confirmAnimation), 'authored death-confirm animation exists');
        trace('[Origin gameplay flow check] LOOP mode=$mode character=$characterId renderer=${character.renderType} animation=$animation music=${death.gameOverMusic?.playing}');
        phase = 2;
        haxe.Timer.delay(() ->
        {
          require(GameOverSubState.instance == death, 'death state remained active before confirmation');
          death.confirmDeath();
          require(death.isEnding, 'native confirmation started the restart transition');
          poll();
        }, 1200);
        return;
      }
    }
    else if (phase == 2 && death == null)
    {
      var state = PlayState.instance;
      if (state != null && state.initialized && !state.isGameOverState && !state.criticalFailure)
      {
        var character = state.currentStage?.getBoyfriend();
        if (character == null || character.isDead || character.characterId != characterId)
          fail('restart did not retain the alive authored player');
        if (restartSeen == null)
        {
          restartSeen = haxe.Timer.stamp();
          trace('[Origin gameplay flow check] PASS restart retained the alive authored player');
        }
        if (haxe.Timer.stamp() - restartSeen >= 3)
        {
          require(funkin.modding.ScriptGuard.brokenCount == 0, 'no broken script after death and restart');
          trace('[Origin gameplay flow check] CHECKS PASSED mode=$mode character=$characterId renderer=$renderer pixel=$pixel');
          Sys.stdout().flush();
          Sys.exit(0);
        }
      }
    }
    haxe.Timer.delay(poll, 100);
  }

  static function require(condition:Bool, message:String):Void
  {
    if (!condition) fail(message);
    trace('[Origin gameplay flow check] PASS $message');
  }

  static function fail(message:String):Void
  {
    trace('[Origin gameplay flow check] FAIL $message');
    Sys.stdout().flush();
    Sys.exit(1);
  }
}
#end
