package codename.funkin.menus.ui;

import codename.funkin.menus.ui.Alphabet.AlphabetAlignment;

/** Runtime-visible values for legacy scripts importing Alphabet.AlphabetAlignment. */
class AlphabetAlignment_HSC {
  public static final LEFT:Int = cast AlphabetAlignment.LEFT;
  public static final CENTER:Int = cast AlphabetAlignment.CENTER;
  public static final RIGHT:Int = cast AlphabetAlignment.RIGHT;

  public static function fromString(value:String):Int {
    return cast AlphabetAlignment.fromString(value);
  }
}
