package originfunkin.compat;

import funkin.play.GameOverSubState;

/** The historical static call must not capture a destroyed game-over instance. */
@:access(funkin.play.GameOverSubState)
class LegacyGameOver
{
  public static function playBlueBalledSFX():Void
  {
    if (polymod.hscript._internal.PolymodScriptClass.blacklistedInstanceFieldsOf('funkin.play.GameOverSubState')
      .contains('playBlueBalledSFX')) throw 'Cannot access blacklisted field playBlueBalledSFX';
    var state = GameOverSubState.instance;
    if (state != null)
    {
      state.playBlueBalledSFX();
      return;
    }
    // Earlier static implementations could also play outside a game-over state.
    GameOverSubState.blueballed = true;
    var sound = funkin.Paths.sound('gameplay/gameover/fnf_loss_sfx' + GameOverSubState.blueBallSuffix);
    if (funkin.assets.Assets.exists(sound)) funkin.audio.FunkinSound.playOnce(sound);
    else flixel.FlxG.log.error('Missing blue ball sound effect: $sound');
  }
}
