package originfunkin.macro;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
#end

/** Include the vendored ASTC decoder in its Haxe bridge translation unit. */
class OriginAstcMacro
{
  #if macro
  public static macro function attach():Array<Field>
  {
    var source = sys.FileSystem.fullPath(Context.resolvePath('originfunkin/compat/astc/astc.cpp')).split('\\').join('/');
    Context.getLocalClass().get().meta.add(':cppFileCode', [macro $v{'// ASTC bounded block decoder v1\n#include "' + source + '"'}], Context.currentPos());
    return Context.getBuildFields();
  }
  #end
}