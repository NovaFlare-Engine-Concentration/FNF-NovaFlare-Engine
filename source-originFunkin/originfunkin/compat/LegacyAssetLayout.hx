package originfunkin.compat;

import haxe.io.Path;
using StringTools;

/** Virtual asset aliases; original mod directories and archives stay untouched. */
@:access(funkin.modding.compat.Paths)
class LegacyAssetLayout
{
  public static function resolveFilesystemPath(fs:polymod.fs.PolymodFileSystem.IFileSystem, path:String):String
  {
    #if sys
    if (Std.isOfType(fs, LegacyModFileSystem)) return cast(fs, LegacyModFileSystem).resolveAlias(path);
    #end
    return path;
  }

  static final LIBRARIES = ['preload', 'shared', 'tutorial', 'week1', 'week2', 'week3', 'week4', 'week5', 'week6', 'week7', 'week8', 'weekend1'];
  static final CLASSIC_CHARACTERS:Map<String, String> = [
    'daddyDearest' => 'dad', 'GF_assets' => 'gf', 'bfCar' => 'bf-car', 'gfCar' => 'gf-car',
    'gfChristmas' => 'gf-christmas', 'momCar' => 'mom-car', 'Monster_Assets' => 'monster',
    'monsterChristmas' => 'monster-christmas', 'mom_dad_christmas_assets' => 'parents-christmas',
    'Pico_Basic' => 'pico', 'tankmanCaptain' => 'tankman', 'Nene' => 'nene'
  ];
  static final SCRIPT_MOVES:Map<String, String> = [
    'scripts/stages/props/ABotAtlasSprite.hxc' => 'gameplay/characters/nene/ABotAtlasSprite.hxc',
    'scripts/stages/props/ABotVisualizer.hxc' => 'gameplay/characters/nene/ABotVisualizer.hxc',
    'scripts/stages/props/CasingSprite.hxc' => 'gameplay/characters/pico-playable/CasingSprite.hxc',
    'scripts/stages/props/SpraycanAtlasSprite.hxc' => 'gameplay/songs/2hot/SpraycanAtlasSprite.hxc',
    'scripts/stages/props/TankmanSprite.hxc' => 'gameplay/stages/tankmanBattlefield/TankmanSprite.hxc',
    'scripts/stages/props/TankmanSpriteGroup.hxc' => 'gameplay/stages/tankmanBattlefield/TankmanSpriteGroup.hxc'
  ];
  static final REGISTRIES:Map<String, {path:String, nested:Bool}> = [
    'characters' => {path:'gameplay/characters/', nested:true},
    'stages' => {path:'gameplay/stages/', nested:true},
    'notestyles' => {path:'gameplay/notestyles/', nested:true},
    'levels' => {path:'ui/story-mode/levels/', nested:false},
    'players' => {path:'gameplay/playable-characters/', nested:true},
    'ui/freeplay/albums' => {path:'ui/freeplay/albums/', nested:false},
    'ui/freeplay/styles' => {path:'ui/freeplay/styles/', nested:true},
    'dialogue/boxes' => {path:'gameplay/dialogue/boxes/', nested:true},
    'dialogue/conversations' => {path:'gameplay/dialogue/conversations/', nested:true},
    'dialogue/speakers' => {path:'gameplay/dialogue/speakers/', nested:true},
    'stickerpacks' => {path:'ui/loading/stickers/stickerpacks/', nested:false}
  ];

  public static function aliases(path:String):Array<String>
  {
    var result:Array<String> = [];
    var relative = Path.normalize(path);
    for (patchPrefix in ['_merge/', '_append/'])
      if (relative.startsWith(patchPrefix))
        return aliases(relative.substr(patchPrefix.length)).map(alias -> patchPrefix + alias);
    if (relative.startsWith('assets/')) relative = relative.substr(7);
    var slash = relative.indexOf('/');
    if (slash > 0 && LIBRARIES.contains(relative.substr(0, slash))) relative = relative.substr(slash + 1);
    if (relative != path) result.push(relative);

    var canonical = lookupCanonical(relative);
    // Some upstream table entries moved only the image, omitting the companion
    // Sparrow XML. Derive its path without claiming the XML actually exists.
    if (canonical == null && relative.endsWith('.xml'))
    {
      var image = lookupCanonical(relative.substr(0, relative.length - 4) + '.png');
      if (image != null && image.endsWith('.png')) canonical = image.substr(0, image.length - 4) + '.xml';
    }
    if (canonical == null && relative.endsWith('-metadata.json'))
    {
      var stem = relative.substr(0, relative.length - '-metadata.json'.length);
      for (extension in ['ogg', 'mp3'])
      {
        var audio = lookupCanonical('$stem.$extension');
        if (audio != null) { canonical = Path.withoutExtension(audio) + '-metadata.json'; break; }
      }
    }
    if (canonical == null) canonical = movedAtlasChild(relative);
    if (canonical != null && canonical.startsWith('assets/')) result.push(canonical.substr(7));
    addEarlyNoteStyleAlias(result, relative);
    var stageImage = relative.startsWith('images/') ? relative.substr(7) : relative;
    if (~/^philly\/win[0-4]\.png$/.match(stageImage))
      result.push('compatibility/origin-v0.3.2/stages/phillyTrain/' + Path.withoutDirectory(stageImage));
    if (~/^philly\/erect\/win[0-4]\.png$/.match(stageImage))
      result.push('compatibility/origin-v0.3.2/stages/phillyTrainErect/' + Path.withoutDirectory(stageImage));
    for (extension in ['png', 'xml'])
    {
      if (relative == 'characters/BFCheer.$extension' || relative == 'images/characters/BFCheer.$extension')
        result.push('compatibility/origin-v0.3.2/sprites/BFCheer.$extension');
      for (oldName => id in CLASSIC_CHARACTERS)
        if (relative == 'characters/$oldName.$extension' || relative == 'images/characters/$oldName.$extension')
          result.push('compatibility/origin-v0.3.2/sprites/$id.$extension');
    }

    if (relative.startsWith('songs/')) result.push('gameplay/$relative');
    if (relative.startsWith('data/songs/'))
    {
      result.push('gameplay/' + relative.substr(5));
      // Old registries discovered the directory independently of the metadata
      // filename. Preserve case-only mismatches without renaming mod files.
      var songPath = relative.substr('data/songs/'.length);
      var parts = songPath.split('/');
      if (parts.length == 2)
      {
        var id = parts[0];
        var file = parts[1];
        if (file.length > id.length && file.substr(0, id.length).toLowerCase() == id.toLowerCase())
        {
          var suffix = file.substr(id.length);
          if ((suffix.startsWith('-metadata') || suffix.startsWith('-chart')) && suffix.endsWith('.json'))
            result.push('gameplay/songs/$id/$id$suffix');
        }
      }
    }
    if (relative.startsWith('scripts/') && relative.endsWith('.hxc'))
    {
      var moved = SCRIPT_MOVES.get(relative);
      if (moved != null) result.push(moved);
      for (legacy => registry in REGISTRIES)
        addScriptAlias(result, relative, legacy, registry.path, registry.nested);
      addScriptAlias(result, relative, 'songs', 'gameplay/songs/', true);
      addScriptAlias(result, relative, 'shaders', 'ui/shaders/', false);
    }
    if (relative.startsWith('data/') && relative.endsWith('.json'))
    {
      for (legacy => registry in REGISTRIES)
      {
        var prefix = 'data/$legacy/';
        if (!relative.startsWith(prefix)) continue;
        var file = relative.substr(prefix.length);
        if (file.contains('/')) continue;
        var id = Path.withoutExtension(file);
        result.push(registry.path + (registry.nested ? '$id/$file' : file));
      }
    }
    return result.filter(alias -> alias != path && !alias.startsWith('../') && !Path.isAbsolute(alias));
  }

  /** Move any file inside a known historical atlas together with its metadata. */
  static function movedAtlasChild(relative:String):Null<String>
  {
    var parent = Path.directory(relative);
    while (parent != '' && parent != '.')
    {
      var metadata = lookupCanonical(parent + '/Animation.json');
      if (metadata != null && metadata.endsWith('/Animation.json'))
      {
        var destination = Path.directory(metadata);
        return destination + relative.substr(parent.length);
      }
      var next = Path.directory(parent);
      if (next == parent) break;
      parent = next;
    }
    return null;
  }

  static function lookupCanonical(relative:String):Null<String>
  {
    var canonical = funkin.modding.compat.Paths.PATHS.get('assets/$relative');
    // Some historical entries omit the type directory (images/music/etc.).
    // Keep the exact table entry first when both forms are present.
    if (canonical == null)
      for (typePrefix in ['images/', 'music/', 'sounds/', 'videos/', 'fonts/', 'shaders/'])
        if (relative.startsWith(typePrefix))
        {
          canonical = funkin.modding.compat.Paths.PATHS.get('assets/' + relative.substr(typePrefix.length));
          break;
        }
    return canonical;
  }

  static function addScriptAlias(result:Array<String>, relative:String, category:String, path:String, nested:Bool):Void
  {
    var prefix = 'scripts/$category/';
    if (!relative.startsWith(prefix)) return;
    var file = relative.substr(prefix.length);
    if (file.contains('/')) return;
    result.push(path + (nested ? Path.withoutExtension(file) + '/' : '') + file);
  }

  static function addEarlyNoteStyleAlias(result:Array<String>, relative:String):Void
  {
    var asset = relative;
    for (prefix in ['images/', 'sounds/']) if (asset.startsWith(prefix)) asset = asset.substr(prefix.length);
    var extension = Path.extension(asset);
    var name = Path.withoutExtension(asset);
    var pixel = name.startsWith('weeb/pixelUI/') || name.endsWith('-pixel');
    if (name.startsWith('weeb/pixelUI/')) name = name.substr('weeb/pixelUI/'.length);
    if (name.endsWith('-pixel')) name = name.substr(0, name.length - '-pixel'.length);
    var style = pixel ? 'pixel' : 'funkin';
    var target:Null<String> = null;
    if (extension == 'png')
    {
      if (['ready', 'set', 'go'].contains(name) || (pixel && name == 'date'))
        target = 'countdown/graphics/' + (name == 'date' ? 'go' : name);
      else if (['sick', 'good', 'bad', 'shit'].contains(name)) target = 'popup/$name';
      else if (~/^num[0-9]$/.match(name)) target = 'popup/digit-' + name.substr(3);
    }
    else if (extension == 'ogg' || extension == 'mp3')
    {
      target = switch (name)
      {
        case 'intro3': 'countdown/sound/intro-three';
        case 'intro2': 'countdown/sound/intro-two';
        case 'intro1': 'countdown/sound/intro-one';
        case 'introGo': 'countdown/sound/intro-go';
        default: null;
      };
    }
    if (target != null) result.push('gameplay/notestyles/$style/$target.$extension');
  }
}
