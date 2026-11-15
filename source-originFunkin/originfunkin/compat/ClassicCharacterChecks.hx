package originfunkin.compat;

#if (sys && FEATURE_DEBUG_FUNCTIONS)
/** Explicit runtime check with a PNG-only mod and the external classic profiles. */
@:access(polymod.Polymod)
class ClassicCharacterChecks extends flixel.FlxState
{
  var characters:Array<funkin.play.character.BaseCharacter> = [];
  var names:Array<Array<String>> = [];
  var tick = 0;
  var elapsedTime = 0.0;
  var reported = false;

  override public function create():Void
  {
    super.create();
    bgColor = 0xFF202632;
    var root = haxe.io.Path.join([originfunkin.OriginFunkinMode.assetsRoot, 'compatibility/origin-v0.3.2']);
    var manifest:Dynamic = haxe.Json.parse(sys.io.File.getContent(haxe.io.Path.join([root, 'manifest.json'])));
    var profiles:Array<Dynamic> = manifest.profiles;
    for (profile in profiles)
    {
      var data:Dynamic = haxe.Json.parse(sys.io.File.getContent(haxe.io.Path.join([root, profile.metadata])));
      var character = funkin.data.character.CharacterRegistry.instance.fetchEntry(profile.id);
      if (character == null || character.renderType != data.renderType || character.frames == null || character.frames.frames.length == 0)
        throw 'Classic character did not construct its historical renderer: ${profile.id}';
      var asset = 'assets/${data.assetPath}.png';
      var selected = polymod.Polymod.assetLibrary.file(asset);
      if (selected == '') throw 'Classic character did not select a PNG from the test mod: ${profile.id}';
      var animations:Array<String> = [];
      var definitions:Array<Dynamic> = data.animations;
      for (definition in definitions)
      {
        if (!character.hasAnimation(definition.name)) throw 'Classic ${profile.id} missing animation ${definition.name}';
        // BF's scripted fakeout needs a live GameOverSubState; its complete
        // lifecycle is covered by the separate normal/fakeout game-over probes.
        if (profile.id != 'bf' || definition.name != 'fakeoutDeath') animations.push(definition.name);
      }
      var index = characters.length;
      var cellX = (index % 4) * 320;
      var cellY = Std.int(index / 4) * 240;
      character.setGraphicSize(0, 150);
      character.updateHitbox();
      character.setPosition(cellX + (320 - character.width) / 2, cellY + 35);
      character.playAnimation(animations[0], true, true);
      add(character);
      add(new flixel.text.FlxText(cellX + 8, cellY + 205, 304, '${profile.id} (${definitions.length})', 16));
      characters.push(character);
      names.push(animations);
      trace('[Origin classic profiles check] Loaded ${profile.id} renderer=${character.renderType} animations=${animations.length} frames=${character.frames.frames.length} image=$selected');
    }
  }

  override public function update(elapsed:Float):Void
  {
    super.update(elapsed);
    elapsedTime += elapsed;
    if (elapsedTime < 0.5 || reported) return;
    elapsedTime = 0;
    tick++;
    var done = true;
    for (i in 0...characters.length)
      if (tick < names[i].length)
      {
        done = false;
        characters[i].playAnimation(names[i][tick], true, true);
      }
    if (done)
    {
      reported = true;
      trace('[Origin classic profiles check] ALL ${characters.length} CHARACTERS PASSED');
    }
  }
}
#end
