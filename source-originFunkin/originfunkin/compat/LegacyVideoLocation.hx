package originfunkin.compat;

#if hxvlc
import hxvlc.util.Location;
import polymod.Polymod;

/** Resolve asset IDs for VLC, including videos stored inside mod archives. */
@:access(polymod.Polymod)
class LegacyVideoLocation
{
  public static function resolve(location:Location):Location
  {
    if (!Std.isOfType(location, String) || Polymod.assetLibrary == null) return location;
    var id:String = cast location;
    if (!Polymod.assetLibrary.exists(id)) return location;
    var path = Polymod.assetLibrary.getPath(id);
    #if sys
    if (path != null && sys.FileSystem.exists(path) && !sys.FileSystem.isDirectory(path)) return path;
    #end
    // VLC supports seekable byte streams, so archives need no persistent extraction.
    var bytes = Polymod.assetLibrary.getBytes(id);
    return bytes != null ? bytes : location;
  }
}
#end
