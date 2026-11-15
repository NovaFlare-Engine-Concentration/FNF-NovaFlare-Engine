package originfunkin.macro;
#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
#end
class OriginWicMacro
{
  #if macro
  public static macro function attach():Array<Field>
  {
    var source = sys.FileSystem.fullPath(Context.resolvePath('originfunkin/compat/wic/webp.h')).split('\\').join('/');
    Context.getLocalClass().get().meta.add(':cppFileCode', [macro $v{'#include "' + source + '"'}], Context.currentPos());
    return Context.getBuildFields();
  }
  #end
}
