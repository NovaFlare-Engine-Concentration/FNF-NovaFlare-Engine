package originfunkin;

#if FEATURE_HAXEUI
import haxe.ui.Toolkit;
import haxe.ui.themes.ThemeManager;
import openfl.utils.Assets;

class OriginFunkinEditors
{
  static final STYLES = ["buttons", "compact", "dialogs", "notifs", "text", "general", "playbar", "toolbox"];
  static var initialized = false;

  public static function initialize(requireStyles:Bool = true):Void
  {
    if (initialized) return;
    for (name in STYLES)
    {
      final path = 'assets/exclude/ui/editors/style/$name.css';
      if (!Assets.exists(path, TEXT))
      {
        if (requireStyles) throw 'Origin editor style is missing: $path. Install the complete external assets pack.';
        return;
      }
    }

    #if android
    mobile.ui.MobileHaxeUI.initialize();
    #else
    if (!Toolkit.initialized) Toolkit.init();
    #end
    funkin.input.Cursor.setupHaxeUICursors();
    var themes = ThemeManager.instance;
    for (name in STYLES)
    {
      var path = 'assets/exclude/ui/editors/style/$name.css';
      var priority = switch (name)
      {
        case "general": 15;
        case "playbar", "toolbox": 20;
        default: 10;
      };
      themes.addStyleResource("funkin-dark", path, priority);
    }
    Toolkit.theme = "funkin-dark";
    initialized = true;
  }
}
#end
