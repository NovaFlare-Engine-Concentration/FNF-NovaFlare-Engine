package originfunkin.compat;

#if sys
import haxe.io.Path;
import haxe.io.Bytes;

/** Add canonical IDs while letting Polymod retain its usual mod load order. */
class LegacyModFileSystem extends polymod.fs.SysZipFileSystem
{
  var aliases:Map<String, String> = [];
  #if (windows && cpp)
  var astcImages:Map<String, String> = [];
  #end
  var generated:Map<String, Bytes> = [];
  var legacySongs:Map<String, LegacySongLayout.LegacySongRecord> = [];
  public var songSnapshots:Map<String, LegacySongLayout.LegacySongSnapshot> = [];

  override public function addZipFile(zipPath:String):Void
  {
    super.addZipFile(zipPath);
    var parser = @:privateAccess this.zipParsers.get(zipPath);
    if (parser == null) return;
    var locations = @:privateAccess this.filesLocations;
    var directories = @:privateAccess this.fileDirectories;
    var modId = Path.withoutExtension(Path.withoutDirectory(zipPath));
    for (name => header in parser.centralDirectoryRecords)
    {
      if (header.uncompressedSize != 0 || header.compressedSize < 0 || StringTools.endsWith(name, '/')) continue;
      var fullPath = Path.join([modRoot, modId, header.fileName]);
      locations.set(fullPath, zipPath);
      var directory = Path.directory(fullPath);
      while (directory != '' && !directories.contains(directory))
      {
        directories.push(directory);
        locations.set(directory, zipPath);
        directory = Path.directory(directory);
      }
    }
  }

  static function key(path:String):String
  {
    var value = Path.normalize(path);
    #if windows
    value = value.toLowerCase();
    #end
    return value;
  }

  /** Enumerate ZIP-only directories without probing a nonexistent disk directory. */
  override public function readDirectory(path:String):Array<String>
  {
    if (StringTools.endsWith(path, "/")) path = path.substr(0, path.length - 1);
    if (sys.FileSystem.exists(path)) return super.readDirectory(path);

    var directories = @:privateAccess this.fileDirectories;
    var virtualDir = Lambda.exists(directories, dir -> dir.toLowerCase() == path.toLowerCase());
    if (!virtualDir) return super.readDirectory(path);

    var insensitive = polymod.PolymodConfig.caseInsensitiveZipLoading;
    var lookup = insensitive ? path.toLowerCase() : path;
    var entries:Array<String> = [];
    var seen:Map<String, Bool> = [];
    function addEntry(candidate:String):Void
    {
      var parent = Path.directory(insensitive ? candidate.toLowerCase() : candidate);
      if (parent != lookup) return;
      var name = Path.withoutDirectory(candidate);
      var entryKey = insensitive ? name.toLowerCase() : name;
      if (seen.exists(entryKey)) return;
      seen.set(entryKey, true);
      entries.push(name);
    }
    for (file in @:privateAccess this.filesLocations.keys()) addEntry(file);
    for (dir in directories) addEntry(dir);
    return entries;
  }

  override public function readDirectoryRecursive(path:String):Array<String>
  {
    var files = super.readDirectoryRecursive(path);
    var rootPrefix = key(modRoot) + '/';
    var relative = key(path).substr(rootPrefix.length);
    if (!StringTools.startsWith(key(path), rootPrefix) || relative == '' || relative.indexOf('/') >= 0) return files;
    if (aliases == null) aliases = [];
    #if (windows && cpp)
    if (astcImages == null) astcImages = [];
    #end
    if (generated == null) generated = [];
    if (legacySongs == null) legacySongs = [];
    if (songSnapshots == null) songSnapshots = [];
    songSnapshots.clear();
    var root = Path.normalize(path);
    var prefix = key(root) + '/';
    for (oldKey in [for (aliasKey in aliases.keys()) aliasKey])
      if (StringTools.startsWith(oldKey, prefix)) aliases.remove(oldKey);
    #if (windows && cpp)
    for (oldKey in [for (entryKey in astcImages.keys()) entryKey])
      if (StringTools.startsWith(oldKey, prefix)) astcImages.remove(oldKey);
    #end
    for (oldKey in [for (entryKey in generated.keys()) entryKey])
      if (StringTools.startsWith(oldKey, prefix))
      {
        generated.remove(oldKey);
        legacySongs.remove(oldKey);
      }
    var actual:Map<String, Bool> = [];
    for (file in files) actual.set(key(file), true);
    var virtual:Map<String, Bool> = [];
    var result = files.copy();
    for (file in files)
    {
      for (alias in LegacyAssetLayout.aliases(file))
      {
        if (actual.exists(key(alias))) continue;
        if (virtual.exists(key(alias)))
        {
          // Windows treats case-only aliases as the same filesystem key, but
          // Polymod's asset index still needs each exact spelling. Never let
          // an alias from another source displace the first selected source.
          var mapped = aliases.get(key(Path.join([root, alias])));
          if (mapped != null && key(mapped) == key(Path.join([root, file])) && result.indexOf(alias) < 0) result.push(alias);
          continue;
        }
        aliases.set(key(Path.join([root, alias])), Path.join([root, file]));
        virtual.set(key(alias), true);
        result.push(alias);
      }
    }
    #if (windows && cpp)
    // Expose a virtual PNG only when this mod has no PNG at that path. Preserve
    // Polymod's normal mod ordering and resolve historical aliases first.
    for (file in result.copy())
    {
      if (Path.extension(file).toLowerCase() != 'astc') continue;
      var png = Path.withExtension(file, 'png');
      if (actual.exists(key(png)) || virtual.exists(key(png))) continue;
      var source = resolveAlias(Path.join([root, file]));
      astcImages.set(key(Path.join([root, png])), source);
      virtual.set(key(png), true);
      result.push(png);
    }
    #end
    LegacySongLayout.mount(this, root, files, result);
    LegacyCharacterLayout.mount(this, root, result);
    if (virtual.iterator().hasNext()) trace('[Origin compatibility] ${Path.withoutDirectory(root)}: mounted ${result.length - files.length} legacy asset aliases.');
    return result;
  }

  public function resolveAlias(path:String):String
  {
    return aliases == null ? path : aliases.get(key(path)) ?? path;
  }

  public function publishSong(path:String, text:String, record:LegacySongLayout.LegacySongRecord):Void
  {
    publishText(path, text);
    legacySongs.set(key(path), record);
  }

  public function publishText(path:String, text:String):Void
  {
    generated.set(key(path), Bytes.ofString(text));
  }

  public function legacySong(path:String):Null<LegacySongLayout.LegacySongRecord>
  {
    return legacySongs == null ? null : legacySongs.get(key(path));
  }

  override public function exists(path:String):Bool
  {
    if (path == null) return false;
    #if (windows && cpp)
    if (astcImages != null && astcImages.exists(key(path))) return true;
    #end
    return (generated != null && generated.exists(key(path))) || super.exists(resolveAlias(path));
  }

  override public function isDirectory(path:String):Bool
  {
    #if (windows && cpp)
    if (astcImages != null && astcImages.exists(key(path))) return false;
    #end
    return (generated == null || !generated.exists(key(path))) && super.isDirectory(resolveAlias(path));
  }

  override public function getFileContent(path:String):Null<String>
  {
    var raw = super.getFileContent(path);
    if (Path.withoutDirectory(path).toLowerCase() != '_polymod_meta.json') return raw;
    return LegacyMetadataCompat.normalize(raw);
  }

  override public function getFileBytes(path:String):Null<Bytes>
  {
    #if (windows && cpp)
    var astcPath = astcImages == null ? null : astcImages.get(key(path));
    if (astcPath != null) return AstcSoftware.toPng(readModFileBytes(astcPath));
    #end
    var bytes = generated == null ? null : generated.get(key(path));
    if (bytes != null) return legacySongs.exists(key(path)) ? LegacySongLayout.generatedBytes(this, path, bytes) : bytes;
    return readModFileBytes(resolveAlias(path));
  }

  /** Read ZIP entries exactly, including when the file returns a short read. */
  function readModFileBytes(path:String):Null<Bytes>
  {
    // Keep Unicode filenames intact; the upstream ZIP reader strips them.
    var cleanPath = Path.normalize(path);
    var locations = @:privateAccess this.filesLocations;
    if (!locations.exists(cleanPath))
    {
      // SysZipFileSystem filters its path before falling back to ordinary files.
      // Read an existing Unicode file directly, preserving the usual fallback for all others.
      if (polymod.util.Util.filterASCII(cleanPath) != cleanPath && sys.FileSystem.exists(cleanPath)
        && !sys.FileSystem.isDirectory(cleanPath))
      {
        try return sys.io.File.getBytes(cleanPath) catch (_:Dynamic) return null;
      }
      return super.getFileBytes(cleanPath);
    }

    var zipPath:Null<String> = locations.get(cleanPath);
    var parsers = @:privateAccess this.zipParsers;
    var parser = zipPath == null ? null : parsers.get(zipPath);
    if (zipPath == null) return null;
    if (parser == null || !parser.isValid())
    {
      @:privateAccess this.purgeZipPath(zipPath);
      return null;
    }

    var modId = Path.withoutExtension(Path.withoutDirectory(zipPath));
    var innerPath = cleanPath;
    var rootPrefix = Path.normalize(modRoot);
    if (!StringTools.endsWith(rootPrefix, '/')) rootPrefix += '/';
    var ignoreCase = polymod.PolymodConfig.caseInsensitiveZipLoading ?? true;
    var matchPath = ignoreCase ? innerPath.toLowerCase() : innerPath;
    var matchRoot = ignoreCase ? rootPrefix.toLowerCase() : rootPrefix;
    if (StringTools.startsWith(matchPath, matchRoot)) innerPath = innerPath.substr(rootPrefix.length);
    var modPrefix = modId + '/';
    var matchInner = ignoreCase ? innerPath.toLowerCase() : innerPath;
    if (StringTools.startsWith(matchInner, ignoreCase ? modPrefix.toLowerCase() : modPrefix))
      innerPath = innerPath.substr(modPrefix.length);

    var central = parser.centralDirectoryRecords.get(innerPath);
    if (central != null && central.compressedSize == 0 && central.uncompressedSize == 0)
    {
      // Polymod rejects valid empty stored headers before returning them.
      var input:Null<sys.io.FileInput> = null;
      try
      {
        input = sys.io.File.read(zipPath);
        input.seek(central.localFileHeaderOffset, sys.io.FileSeek.SeekBegin);
        var local = new polymod.util.zip.ZipParser.LocalFileHeader(input);
        var valid = local.signature.getInt32(0) == 0x04034b50 && local.fileName == central.fileName
          && local.compressionMethod == NONE && central.compressionMethod == NONE
          && local.compressedSize == 0 && local.uncompressedSize == 0;
        input.close();
        return valid ? Bytes.alloc(0) : null;
      }
      catch (_:Dynamic)
      {
        if (input != null) input.close();
        return null;
      }
    }
    var header = try parser.getLocalFileHeaderOf(innerPath) catch (error:Dynamic)
    {
      trace('[Origin compatibility] Could not inspect ZIP entry "$cleanPath": $error');
      return null;
    };
    if (header == null) return null;
    try
    {
      var input:Null<sys.io.FileInput> = @:privateAccess header.fileInput;
      if (input == null || header.compressedSize < 0 || header.uncompressedSize < 0) throw 'Invalid ZIP entry size or handle';
      var archiveSize = sys.FileSystem.stat(zipPath).size;
      if (header.dataOffset < 0 || header.dataOffset > archiveSize || header.compressedSize > archiveSize - header.dataOffset)
        throw 'ZIP entry extends beyond archive';
      input.seek(header.dataOffset, sys.io.FileSeek.SeekBegin);
      var compressed = Bytes.alloc(header.compressedSize);
      input.readFullBytes(compressed, 0, header.compressedSize);
      var result = switch (header.compressionMethod)
      {
        case DEFLATE: inflateBounded(compressed, header.uncompressedSize);
        case NONE: compressed;
      };
      if (result == null || result.length != header.uncompressedSize) throw 'ZIP entry length mismatch';
      header.cleanupFileHandle();
      return result;
    }
    catch (error:Dynamic)
    {
      header.cleanupFileHandle();
      trace('[Origin compatibility] Could not read ZIP entry "$cleanPath": $error');
      return null;
    }
  }

  /** Stop inflating immediately if a stream exceeds the size declared by its header. */
  static function inflateBounded(compressed:Bytes, expectedSize:Int):Bytes
  {
    var inflater = new haxe.zip.InflateImpl(new haxe.io.BytesInput(compressed), false, false);
    var chunks = new haxe.io.BytesBuffer();
    var buffer = Bytes.alloc(65535);
    var total = 0;
    while (true)
    {
      var remaining = expectedSize - total;
      var request = remaining >= buffer.length ? buffer.length : remaining + 1;
      var read = inflater.readBytes(buffer, 0, request);
      if (read < 0 || read > remaining) throw 'ZIP entry expands beyond declared size';
      if (read > 0) chunks.addBytes(buffer, 0, read);
      total += read;
      if (read < request) break;
    }
    if (total != expectedSize) throw 'ZIP entry length mismatch';
    return chunks.getBytes();
  }
}
#else
typedef LegacyModFileSystem = polymod.fs.ZipFileSystem;
#end
