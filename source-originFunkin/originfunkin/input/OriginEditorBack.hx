package originfunkin.input;

#if android
import flixel.FlxG;
import haxe.ui.containers.dialogs.Dialog;
import haxe.ui.containers.dialogs.Dialog.DialogButton;
import haxe.ui.core.Screen;
import haxe.ui.focus.FocusManager;

class OriginEditorBack
{
  public static function handle(exit:Void->Void, ?welcomeDialog:Class<Dialog>):Bool
  {
    if (!FlxG.android.justPressed.BACK) return false;

    final dialog = Std.downcast(Screen.instance.topComponent, Dialog);
    if (dialog != null && dialog.modal)
    {
      if (dialog.closable) dialog.hideDialog(DialogButton.CANCEL);
      else if (welcomeDialog != null && Std.isOfType(dialog, welcomeDialog)) exit();
      return true;
    }

    if (FocusManager.instance.focus != null)
    {
      FocusManager.instance.focus = null;
      return true;
    }

    exit();
    return true;
  }
}
#end
