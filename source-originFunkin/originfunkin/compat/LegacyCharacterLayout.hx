package originfunkin.compat;

#if sys
import haxe.io.Path;

/** Match image-only stock skins to external renderer/data profiles. */
class LegacyCharacterLayout
{
  static function key(path:String):String
  {
    var value = Path.normalize(path);
    #if windows
    value = value.toLowerCase();
    #end
    return value;
  }

  static function profileFile(root:String, relative:String):String
  {
    if (relative == null || Path.isAbsolute(relative) || relative.indexOf('..') >= 0) throw 'Invalid legacy profile path: $relative';
    return sys.io.File.getContent(Path.join([root, relative]));
  }

  public static function mount(fs:LegacyModFileSystem, root:String, files:Array<String>):Void
  {
    var assets = originfunkin.OriginFunkinMode.assetsRoot;
    if (assets == null) return;
    var profilesRoot = Path.join([assets, 'compatibility/origin-v0.3.2']);
    var manifestPath = Path.join([profilesRoot, 'manifest.json']);
    if (!sys.FileSystem.exists(manifestPath)) return;
    try
    {
      var manifest:Dynamic = haxe.Json.parse(sys.io.File.getContent(manifestPath));
      if (manifest.version != 1) throw 'Unsupported legacy character profile manifest version';
      var profiles:Array<Dynamic> = manifest.profiles;
      var present:Map<String, Bool> = [];
      for (file in files) present.set(key(file), true);
      for (profile in profiles)
      {
        var id:String = profile.id;
        if (id == null || !(~/^[a-zA-Z0-9_-]+$/).match(id)) throw 'Invalid legacy profile character ID';
        var metadataPath = 'gameplay/characters/$id/$id.json';
        var scriptPath = 'gameplay/characters/$id/$id.hxc';
        if (profile.scriptAsset != null && profile.scriptAsset != scriptPath) throw 'Invalid legacy profile script asset';
        var images:Array<String> = profile.images;
        var prefixes:Array<String> = profile.modernPrefixes == null ? [] : cast profile.modernPrefixes;
        var hasLegacyImage = false;
        var hasModernAtlas = false;
        for (image in images) if (present.exists(key(image))) hasLegacyImage = true;
        for (file in files)
          for (prefix in prefixes)
            if (StringTools.startsWith(key(file), key(prefix) + '/') && (StringTools.endsWith(file.toLowerCase(), '.png')
              || StringTools.endsWith(file.toLowerCase(), 'animation.json'))) hasModernAtlas = true;
        var hasMetadata = present.exists(key(metadataPath));
        if (!hasLegacyImage && !hasModernAtlas && !hasMetadata) continue;
        var dataText:String;
        if (hasMetadata) dataText = fs.getFileContent(Path.join([root, metadataPath]));
        else if (hasModernAtlas) dataText = sys.io.File.getContent(Path.join([assets, metadataPath]));
        else dataText = profileFile(profilesRoot, profile.metadata);
        var data:Dynamic = haxe.Json.parse(dataText);
        var renderer:String = data.renderType ?? 'sparrow';
        var baseClass = switch (renderer)
        {
          case 'sparrow': 'SparrowCharacter';
          case 'multisparrow': 'MultiSparrowCharacter';
          case 'animateatlas': 'AnimateAtlasCharacter';
          case 'multianimateatlas': 'MultiAnimateAtlasCharacter';
          default: null;
        };
        if (baseClass == null) continue;
        var script:Null<String> = null;
        if (!present.exists(key(scriptPath)) && profile.script != null)
        {
          var currentData = haxe.Json.parse(sys.io.File.getContent(Path.join([assets, metadataPath])));
          var currentScript = Path.join([assets, scriptPath]);
          if (renderer == currentData.renderType && sys.FileSystem.exists(currentScript))
            script = sys.io.File.getContent(currentScript);
          else
          {
            var scriptBase:String = profile.scriptBase ?? 'MultiSparrowCharacter';
            if (!['SparrowCharacter', 'MultiSparrowCharacter', 'AnimateAtlasCharacter', 'MultiAnimateAtlasCharacter'].contains(scriptBase))
              throw 'Invalid legacy profile script base';
            script = StringTools.replace(profileFile(profilesRoot, profile.script), scriptBase, baseClass);
          }
        }
        // Publish both only after every required profile file has been read.
        if (!hasMetadata)
        {
          fs.publishText(Path.join([root, metadataPath]), dataText);
          files.push(metadataPath);
          present.set(key(metadataPath), true);
        }
        if (script != null)
        {
          fs.publishText(Path.join([root, scriptPath]), script);
          files.push(scriptPath);
          present.set(key(scriptPath), true);
        }
        trace('[Origin compatibility] ${Path.withoutDirectory(root)}: selected $renderer profile for $id.');
      }
    }
    catch (error:Dynamic) trace('[Origin compatibility] Could not mount external character profiles for $root: $error');
  }
}
#end
