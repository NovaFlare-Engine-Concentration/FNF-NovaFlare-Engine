package codenamechain.macros;

#if macro
import haxe.macro.Compiler;
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;

using StringTools;

class CNEAbstractHandler
{
  static final generatedWrappers:Map<String, Bool> = [];

  static function hasWrapperSource(wrapperPath:String):Bool
  {
    try
    {
      Context.resolvePath(wrapperPath.split(".").join("/") + ".hx");
      return true;
    }
    catch (_:Dynamic) return false;
  }

  public static function init():Void
  {
    if (!Context.defined("CODENAME_ENGINE_COMPAT") || Context.defined("display")) return;

    generatedWrappers.clear();

    var paths = hscript.Config.ALLOWED_ABSTRACT_AND_ENUM.copy();

    // Secondary abstracts are compiled into a private _Module package even
    // though their public module path contains no underscore. Register the
    // handler for all script-facing library packages, not individual types.
    for (packageName in ["flixel", "openfl", "lime", "haxe.xml", "codename.funkin"])
      Compiler.addGlobalMetadata(packageName, "@:build(codenamechain.macros.CNEAbstractHandler.build())", true);

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
              var moduleLeaf = implementation.module.split(".").pop();
              var isSecondary = moduleLeaf != abstractType.name
                && implementation.pack.length > 0
                && implementation.pack[implementation.pack.length - 1] == "_" + moduleLeaf;
              if (isSecondary && !hscript.Config.DISALLOW_ABSTRACT_AND_ENUM.contains(implementation.module)
                && !hscript.Config.DISALLOW_ABSTRACT_AND_ENUM.contains(implementation.module + "." + abstractType.name))
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
    var secondaryModule = leaf != abstractName && cls.pack.length > 0
      && cls.pack[cls.pack.length - 1] == "_" + leaf;
    var fullPath = cls.module + "." + abstractName;
    var shortPath = parts.slice(0, parts.length - 1).concat([abstractName]).join(".");
    var allowed = Lambda.exists(hscript.Config.ALLOWED_ABSTRACT_AND_ENUM, path ->
      path == fullPath || path == shortPath || StringTools.startsWith(fullPath, path + "."));
    var automaticEnum = !allowed && cls.meta.has(":enum");
    var handledByUpstream = !cls.module.contains("_")
      && Lambda.exists(hscript.Config.ALLOWED_ABSTRACT_AND_ENUM, path ->
        cls.module == path || StringTools.startsWith(cls.module, path + "."));
    if (handledByUpstream) return fields;

    // The upstream handler already handles configured primary abstracts.
    if (!secondaryModule && !automaticEnum && !(cls.module.startsWith("flixel.addons.") && cls.module.contains("_"))) return fields;

    // Generic abstracts cannot be represented by this non-generic runtime
    // wrapper. Check the abstract itself: the generated implementation class
    // does not necessarily expose the original type parameters.
    switch (cls.kind)
    {
      case KAbstractImpl(ref) if (ref.get().isPrivate || ref.get().params.length > 0): return fields;
      default:
    }

    if (secondaryModule)
    {
      // Enum abstracts expose their values through the same generated
      // implementation, even when they are not explicitly listed in Config.
      if (!allowed && !automaticEnum) return fields;
    }

    var modulePath:String;
    var abstractPath:String;
    if (secondaryModule)
    {
      var packageParts = parts.slice(0, parts.length - 1);
      modulePath = packageParts.concat([abstractName + "_HSC"]).join(".");
      abstractPath = packageParts.concat([leaf, abstractName]).join(".");
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

    var wrapperPath = parts.slice(0, parts.length - 1).concat([abstractName + "_HSC"]).join(".");
    if (generatedWrappers.exists(wrapperPath) || hasWrapperSource(wrapperPath)) return fields;
    generatedWrappers.set(wrapperPath, true);

    var wrapper = macro class {};
    wrapper.kind = TDClass();
    wrapper.params = null;
    wrapper.name = abstractName + "_HSC";
    wrapper.meta.push({name: ":keep", params: [], pos: Context.currentPos()});

    var imports = Context.getLocalImports().copy();
    // Inspecting the entire containing module while an enum abstract is
    // being typed can recursively load its still-incomplete main class.
    if (!cls.meta.has(":enum")) hscript.macros.Utils.setupMetas(wrapper, imports);
    else if (secondaryModule && Lambda.exists(fields, field -> switch (field.kind) {
      case FFun(fn): field.access.contains(AStatic) && fn.expr != null;
      default: false;
    }))
      imports.push({path: [for (part in abstractPath.split(".")) {name: part, pos: Context.currentPos()}], mode: INormal});

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
          if (cls.meta.has(":enum"))
          {
            // Getter names are safe from platform macros such as IN and OUT;
            // HScript reads properties through Reflect.getProperty.
            wrapper.fields.push({
              name: field.name, access: [APublic, AStatic], pos: field.pos,
              kind: FProp("get", "never", macro:Dynamic)
            });
            wrapper.fields.push({
              name: "get_" + field.name, access: [APublic, AStatic], pos: field.pos,
              kind: FFun({args: [], ret: macro:Dynamic, expr: macro return $e{value}})
            });
          }
          else
          {
            wrapper.fields.push({
              name: field.name, access: [APublic, AStatic], pos: field.pos,
              doc: field.doc, meta: field.meta, kind: FVar(type, value)
            });
          }
        default:
      }
    }

    Context.defineModule(modulePath, [wrapper], imports);
    return fields;
  }
}
#end
