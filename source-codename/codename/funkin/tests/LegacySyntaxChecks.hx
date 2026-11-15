package codename.funkin.tests;

#if (sys && FEATURE_DEBUG_FUNCTIONS)
import flixel.FlxState;
import codename.funkin.backend.scripting.HScript;
import codename.funkin.backend.scripting.LegacySyntaxCompat;
import codename.funkin.backend.scripting.Script;
using Lambda;

/** Exercise actual CNE script normalization and interpretation without changing a mod. */
class LegacySyntaxChecks extends FlxState {
  static function require(value:Bool, message:String):Void {
    if (!value) throw 'CNE syntax check failed: $message';
    trace('[CNE syntax check] PASS $message');
  }

  static function checkStrumAtlas(base:String, fallbackExpected:Bool):Void {
    var bitmap = openfl.display.BitmapData.fromFile(base + '.png');
    require(bitmap != null, 'strum atlas image loads');
    var atlas = flixel.graphics.frames.FlxAtlasFrames.fromSparrow(bitmap, sys.io.File.getContent(base + '.xml'));
    require(atlas != null, 'strum atlas XML loads');
    var strums:Array<codename.funkin.game.Strum> = [];
    for (direction in ['left', 'down', 'up', 'right']) {
      var strum = new codename.funkin.game.Strum();
      strums.push(strum);
      strum.frames = atlas;
      strum.animation.addByPrefix('static', 'arrow' + direction.toUpperCase());
      var idle = strum.animation.getByName('static');
      require(idle != null, 'idle strum exists for ' + direction);
      codename.funkin.game.StrumLine.addPressedAnimation(strum, direction);
      var pressed = strum.animation.getByName('pressed');
      require(pressed != null, 'pressed strum exists for ' + direction);
      require((pressed.frames.join(',') == idle.frames.join(',')) == fallbackExpected, 'pressed frame selection for ' + direction);
      strum.animation.play('static');
      strum.updatePlayerInput(true, true, false);
      require(strum.animation.name == 'pressed', 'press state for ' + direction);
      strum.updatePlayerInput(false, false, true);
      require(strum.animation.name == 'static', 'release state for ' + direction);
    }
    for (strum in strums) strum.destroy();
  }

  override public function create():Void {
    super.create();
    try {
      var untouched = 'var s = "catch(x)"; // catch(y)\nvar r = ~/catch[(]z[)]/; object.catch(q);';
      require(LegacySyntaxCompat.normalizeUntypedCatch(untouched) == untouched, 'strings comments regex and member calls remain unchanged');
      var typed = 'try { throw 1; } catch (e:Dynamic) { trace(e); }';
      require(LegacySyntaxCompat.normalizeUntypedCatch(typed) == typed, 'typed catches remain unchanged');
      var source = 'var result = ""; try { throw "expected"; } catch (err) { result = err; }';
      var normalized = LegacySyntaxCompat.normalizeUntypedCatch(source);
      require(normalized.indexOf('catch (err:Dynamic)') >= 0, 'bare catch receives Dynamic');
      require(LegacySyntaxCompat.normalizeUntypedCatch(normalized) == normalized, 'normalization is idempotent');
      var script = Script.fromString(source, '__cne_legacy_syntax_check.hx');
      script.load();
      require(script.get('result') == 'expected', 'actual HScript executes the catch body');
      script.destroy();
      var staticProbe = Script.fromString('var staticValue = probe.sharedValue; var instanceValue = probe.localValue;', '__cne_static_instance_check.hx');
      staticProbe.set('probe', new LegacyStaticAccessProbe());
      staticProbe.load();
      require(staticProbe.get('staticValue') == 'static-ok', 'static field resolves through an instance');
      require(staticProbe.get('instanceValue') == 'instance-ok', 'instance field retains precedence');
      staticProbe.destroy();
      var member = new flixel.FlxSprite();
      require(HScript.safeStateAdd(this, member) == member && members.contains(member), 'valid state member is added');
      require(HScript.safeStateAdd(this, []) == null && HScript.safeStateAdd(this, {}) == null, 'invalid state members are safely rejected');
      remove(member, true);
      member.destroy();
      var marks = 0;
      var imports = 0;
      var shared:Map<String, Dynamic> = ['sharedValue' => 0];
      var parent = {mark: function() { marks++; }};
      var reloaded = new LegacyReloadProbe('__cne_reload_check.hx');
      reloaded.setParent(parent);
      reloaded.setPublicMap(shared);
      reloaded.set('importScript', function(_:String) { imports++; });
      reloaded.load();
      require(marks == 1 && imports == 1 && shared.get('sharedValue') == 1, 'initial script has parent import and shared map');
      reloaded.set('retainedValue', 42);
      reloaded.reload();
      require(marks == 2 && imports == 2 && shared.get('sharedValue') == 2, 'reload executes with parent import and shared map');
      require(reloaded.get('retainedValue') == 42, 'reload retains script data');
      require(Reflect.isFunction(reloaded.get('disableScript')) && reloaded.get('__script__') == reloaded, 'reload restores built-in helpers');
      reloaded.destroy();
      var arg = Sys.args().find(value -> StringTools.startsWith(value, '--cne-syntax-file='));
      if (arg != null) {
        var path = arg.substr('--cne-syntax-file='.length);
        var fixture = Script.fromString(sys.io.File.getContent(path), '__cne_real_mod_syntax.hx');
        require(Std.isOfType(fixture, HScript) && (cast fixture:HScript).expr != null, 'installed mod script parses through actual HScript');
        fixture.destroy();
      }
      var importArg = Sys.args().find(value -> StringTools.startsWith(value, '--cne-import-file='));
      if (importArg != null) {
        var importFile = sys.io.File.getContent(importArg.substr('--cne-import-file='.length));
        var importLine = 'import funkin.menus.ui.Alphabet.AlphabetAlignment;';
        require(importFile.indexOf(importLine) >= 0, 'installed mod contains the legacy alignment import');
        var alignment = Script.fromString(importLine + '\nvar values = [AlphabetAlignment.LEFT, AlphabetAlignment.CENTER, AlphabetAlignment.RIGHT, AlphabetAlignment.fromString("center")];', '__cne_alignment_import_check.hx');
        alignment.load();
        var values:Array<Int> = cast alignment.get('values');
        require(values != null && values.length == 4 && values[0] == 0 && values[1] == 1 && values[2] == 2 && values[3] == 1, 'legacy alignment import resolves to actual enum values');
        alignment.destroy();
      }
      var atlasArg = Sys.args().find(value -> StringTools.startsWith(value, '--cne-atlas-root='));
      if (atlasArg != null) {
        var root = atlasArg.substr('--cne-atlas-root='.length);
        checkStrumAtlas(haxe.io.Path.join([root, 'mods-codename', 'Vs Ross', 'images', 'game', 'notes', 'BFBirdNote']), true);
        checkStrumAtlas(haxe.io.Path.join([root, 'assets', 'images', 'game', 'notes', 'default']), false);
        trace('[CNE syntax check] STRUM ATLASES PASSED');
      }
      trace('[CNE syntax check] CHECKS PASSED');
      Sys.stdout().flush();
      Sys.exit(0);
    } catch (e:Dynamic) {
      trace('[CNE syntax check] FAIL $e');
      Sys.stdout().flush();
      Sys.exit(1);
    }
  }
 }

private class LegacyStaticAccessProbe {
  public static var sharedValue:String = 'static-ok';
  public var localValue:String = 'instance-ok';
  public function new() {}
}
private class LegacyReloadProbe extends HScript {
  public function new(path:String) { super(path); }
  override public function onCreate(path:String) {
    super.onCreate(path);
    loadFromString('mark(); importScript("fixture"); sharedValue = sharedValue + 1;');
  }
}
#end
