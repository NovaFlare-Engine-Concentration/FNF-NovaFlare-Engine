package originfunkin;

#if FEATURE_HAXEUI
import haxe.ui.Toolkit;
import haxe.ui.themes.ThemeManager;
import openfl.utils.Assets;

class OriginFunkinEditors
{
  public static function initialize():Void
  {
    Toolkit.init();
    funkin.input.Cursor.setupHaxeUICursors();
    var themes = ThemeManager.instance;
    for (name in ["buttons", "compact", "dialogs", "notifs", "text", "general", "playbar", "toolbox"])
    {
      var path = 'assets/exclude/ui/editors/style/$name.css';
      if (!Assets.exists(path, TEXT)) throw 'Origin editor style is missing: $path. Install the complete external assets pack.';
      var priority = switch (name)
      {
        case "general": 15;
        case "playbar", "toolbox": 20;
        default: 10;
      };
      themes.addStyleResource("funkin-dark", path, priority);
    }
    Toolkit.theme = "funkin-dark";
  }
}
#end
