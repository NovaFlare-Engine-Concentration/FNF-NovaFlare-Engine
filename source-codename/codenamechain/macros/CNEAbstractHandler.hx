package codenamechain.macros;

#if macro
import haxe.macro.Compiler;
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;

using StringTools;

class CNEAbstractHandler
{
  public static function init():Void
  {
    if (!Context.defined("CODENAME_ENGINE_COMPAT") || Context.defined("display")) return;

    var paths = hscript.Config.ALLOWED_ABSTRACT_AND_ENUM.copy();

    Compiler.addGlobalMetadata("flixel.addons", "@:build(codenamechain.macros.CNEAbstractHandler.build())", true);

    Context.onAfterInitMacros(function() {
      for (path in paths)
      {

        if (Lambda.exists(path.split("."), part -> part.startsWith("_"))) continue;

        var resolved:Null<Type> = null;
        try resolved = Context.getType(path) catch (_:Dynamic) continue;

        switch (resolved)
        {
          case TAbstract(abstractRef, _):
            var abstractType = abstractRef.get();
            if (abstractType.impl != null && abstractType.params.length == 0)
            {
              var implementation = abstractType.impl.get();
              if (implementation.module.startsWith("flixel.addons.") && implementation.module.contains("_"))
              {
                var wrapperPath = abstractType.pack.concat([abstractType.name + "_HSC"]).join(".");
                try Context.getType(wrapperPath) catch (error:Dynamic)
                  Context.error('Failed to generate HScript wrapper $wrapperPath for $path: $error', abstractType.pos);
              }
            }
          default:
        }
      }
    });
  }

  public static macro function build():Array<Field>
  {
    var fields = Context.getBuildFields();
    var classRef = Context.getLocalClass();
    if (classRef == null) return fields;
    var cls = classRef.get();

    if (!cls.name.endsWith("_Impl_") || cls.params.length > 0 || cls.meta.has(":multiType") || cls.name.contains("_HSC"))
      return fields;

    var abstractName = cls.name.substr(0, cls.name.length - 6);
    var parts = cls.module.split(".");
    var leaf = parts[parts.length - 1];
    var secondaryModule = leaf.startsWith("_");

    if (!cls.module.contains("_")) return fields;

    var modulePath:String;
    var abstractPath:String;
    if (secondaryModule)
    {
      var packageParts = parts.slice(0, parts.length - 1);
      var publicModule = leaf.substr(1);
      modulePath = packageParts.concat([abstractName + "_HSC"]).join(".");
      abstractPath = packageParts.concat([publicModule, abstractName]).join(".");
    }
    else
    {
      modulePath = cls.module;
      abstractPath = abstractName;
    }

    var key = cls.module;
    var fkey = cls.module + "." + abstractName;
    if (key == "lime.system.Locale" || key == "cpp.Function" || key == "haxe.ds.Vector"
      || key == "haxe.display.Display" || key == "cpp.Callable" || key == "haxe.display.JsonAnonStatusKind"
      || key == "cpp.CharStar") return fields;
    if (hscript.Config.DISALLOW_ABSTRACT_AND_ENUM.contains(key)
      || hscript.Config.DISALLOW_ABSTRACT_AND_ENUM.contains(fkey)) return fields;

    var wrapper = macro class {};
    wrapper.kind = TDClass();
    wrapper.params = null;
    wrapper.name = abstractName + "_HSC";
    wrapper.meta.push({name: ":keep", params: [], pos: Context.currentPos()});

    var imports = Context.getLocalImports().copy();
    hscript.macros.Utils.setupMetas(wrapper, imports);

    for (field in fields)
    {
      switch (field.kind)
      {
        case FFun(fn) if (field.access.contains(AStatic) && fn.expr != null):
          fn.expr = macro @:privateAccess $e{fn.expr};
          wrapper.fields.push(field);
        case FProp(get, set, _, _) if (get == "default" && (set == "never" || set == "null")):
          wrapper.fields.push(field);
        case FVar(type, expr) if (field.access.contains(AStatic) || cls.meta.has(":enum") || field.name.toUpperCase() == field.name):
          var target = abstractPath + "." + field.name;
          var value = Context.parse("@:privateAccess (" + target + ")", field.pos);
          wrapper.fields.push({
            name: field.name,
            access: [APublic, AStatic],
            pos: field.pos,
            doc: field.doc,
            meta: field.meta,
            kind: FVar(type, value)
          });
        default:
      }
    }

    Context.defineModule(modulePath, [wrapper], imports);
    return fields;
  }
}
#end
