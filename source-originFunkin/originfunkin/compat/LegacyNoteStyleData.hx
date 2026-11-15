package originfunkin.compat;

/** Materialize the hard-coded effects/UI used by the earliest note-style schema. */
class LegacyNoteStyleData
{
  public static function migrate(contents:String, hardcodedEffects:Bool = false):String
  {
    var document:Dynamic;
    try document = haxe.Json.parse(contents)
    catch (_:Dynamic) return contents; // Leave malformed input to the normal registry diagnostics.
    if (!isObject(document) || !isObject(document.assets)) return contents;
    var earlySchema = document.version == '1.0.0';
    if (!earlySchema && !hardcodedEffects) return contents;
    var assets:Dynamic = document.assets;
    var splash = placeholder(assets.noteSplash, ['leftSplashes', 'downSplashes', 'upSplashes', 'rightSplashes']);
    var cover = placeholder(assets.holdNoteCover, ['left', 'down', 'up', 'right']);
    if (!splash && !cover) return contents;

    if (splash && assets.noteSplash.data.enabled != false)
    {
      assets.noteSplash.assetPath = 'noteSplashes';
      fillMissing(assets.noteSplash, {
        alpha:0.6, scale:1.0, animated:true, isPixel:false,
        data:{framerateDefault:24, framerateVariance:2,
          leftSplashes:[{prefix:'note impact 1 purple0'}, {prefix:'note impact 2 purple0'}],
          downSplashes:[{prefix:'note impact 1  blue0'}, {prefix:'note impact 2 blue0'}],
          upSplashes:[{prefix:'note impact 1 green0'}, {prefix:'note impact 2 green0'}],
          rightSplashes:[{prefix:'note impact 1 red0'}, {prefix:'note impact 2 red0'}]}
      });
    }
    if (cover && assets.holdNoteCover.data.enabled != false)
    {
      var directions:Dynamic = {};
      for (direction in [{name:'left', color:'Purple'}, {name:'down', color:'Blue'},
        {name:'up', color:'Green'}, {name:'right', color:'Red'}])
        Reflect.setField(directions, direction.name, {
          assetPath:'holdCover${direction.color}',
          start:{prefix:'holdCoverStart${direction.color}0', frameRate:24},
          hold:{prefix:'holdCover${direction.color}0', frameRate:24, looped:true},
          end:{prefix:'holdCoverEnd${direction.color}0', frameRate:24}
        });
      fillMissing(assets.holdNoteCover, {scale:1.0, isPixel:false, data:directions});
    }

    if (!earlySchema) return haxe.Json.stringify(document);

    var pixel:Bool = assets.note?.isPixel == true || assets.noteStrumline?.isPixel == true;
    var prefix = pixel ? 'weeb/pixelUI/' : '';
    var suffix = pixel ? '-pixel' : '';
    for (step in [{name:'Three', image:null, sound:'intro3'}, {name:'Two', image:'ready', sound:'intro2'},
      {name:'One', image:'set', sound:'intro1'}, {name:'Go', image:pixel ? 'date' : 'go', sound:'introGo'}])
      setMissing(assets, 'countdown${step.name}', {
        assetPath:step.image == null ? null : prefix + step.image + suffix,
        scale:pixel ? 6.0 : 1.0, isPixel:pixel, data:{audioPath:step.sound + suffix}
      });
    for (rating in ['sick', 'good', 'bad', 'shit'])
      setMissing(assets, 'judgement' + rating.charAt(0).toUpperCase() + rating.substr(1), {
        assetPath:prefix + rating + suffix, scale:pixel ? 4.2 : 0.65, isPixel:pixel
      });
    for (digit in 0...10)
      setMissing(assets, 'comboNumber$digit', {assetPath:'${prefix}num$digit$suffix', scale:pixel ? 4.2 : 0.45, isPixel:pixel});
    return haxe.Json.stringify(document);
  }

  /** An authored four-direction splash is evidence of the post-0.5 effect format.
   * Mod API metadata is a minimum, not the exact game version. */
  public static function hasModernSplash(contents:String):Bool
  {
    var document:Dynamic;
    try document = haxe.Json.parse(contents) catch (_:Dynamic) return false;
    if (!isObject(document) || !isObject(document.assets)) return false;
    var splash:Dynamic = document.assets.noteSplash;
    if (!isObject(splash) || !Std.isOfType(splash.assetPath, String) || splash.assetPath == '' || !isObject(splash.data)) return false;
    for (direction in ['leftSplashes', 'downSplashes', 'upSplashes', 'rightSplashes'])
    {
      var animations:Dynamic = Reflect.field(splash.data, direction);
      if (!Std.isOfType(animations, Array) || (cast animations:Array<Dynamic>).length == 0) return false;
    }
    return true;
  }

  static function placeholder(asset:Dynamic, directions:Array<String>):Bool
  {
    if (!isObject(asset) || asset.assetPath != '' || !isObject(asset.data)) return false;
    for (direction in directions) if (Reflect.hasField(asset.data, direction)) return false;
    return true;
  }

  static function isObject(value:Dynamic):Bool
  {
    return value != null && Reflect.isObject(value) && !Std.isOfType(value, Array) && !Std.isOfType(value, String);
  }

  static function setMissing(target:Dynamic, name:String, value:Dynamic):Void
  {
    if (!Reflect.hasField(target, name)) Reflect.setField(target, name, value);
  }

  static function fillMissing(target:Dynamic, defaults:Dynamic):Void
  {
    for (name in Reflect.fields(defaults))
    {
      var value = Reflect.field(defaults, name);
      if (!Reflect.hasField(target, name)) Reflect.setField(target, name, value);
      else if (name == 'data' && Reflect.field(target, name) != null) fillMissing(Reflect.field(target, name), value);
    }
  }
}
