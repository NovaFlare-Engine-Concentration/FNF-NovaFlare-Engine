package funkin.play.character;

import flixel.graphics.FlxGraphic;

/** Keeps every source graphic alive for as long as its character uses it. */
class CharacterAtlasLease
{
  var graphics:Array<FlxGraphic> = [];

  public function new() {}

  public function hold(graphic:FlxGraphic):Void
  {
    if (graphic == null || graphics.contains(graphic)) return;
    graphic.incrementUseCount();
    graphics.push(graphic);
  }

  public function release():Void
  {
    var releasing = graphics;
    graphics = [];
    for (graphic in releasing) graphic.decrementUseCount();
  }
}
