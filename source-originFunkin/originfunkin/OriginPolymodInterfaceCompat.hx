package originfunkin;

import polymod.hscript._internal.Expr;
import polymod.hscript._internal.PolymodStaticInterfaceReference.InterfaceFields;
import polymod.hscript._internal.Printer;

/** Preserve shared interface methods such as FlxBasic / IFlxDestroyable.destroy. */
class OriginPolymodInterfaceCompat
{
  public static function appendInterfaces(current:InterfaceFields, incoming:InterfaceFields):Void
  {
    var errors:Array<String> = [];
    for (interfaceId => fields in incoming)
    {
      if (current.exists(interfaceId)) continue;
      for (existingId => existingFields in current)
      {
        for (field in fields)
        {
          for (existingField in existingFields)
          {
            if (field.name != existingField.name || compatibleMethod(field, existingField)) continue;
            errors.push('Field "${field.name}" of "$existingId" conflicts with "$interfaceId"');
          }
        }
      }
    }
    if (errors.length > 0) throw errors.join("\n");

    // Retain the entire interface, including requirements unrelated to the
    // shared method. Dropping it would also lose its identity for isOfType().
    for (interfaceId => fields in incoming)
      if (!current.exists(interfaceId)) current.set(interfaceId, fields);
  }

  static function compatibleMethod(left:FieldDecl, right:FieldDecl):Bool
  {
    if (left.access.contains(AStatic) != right.access.contains(AStatic)
      || left.access.contains(APublic) != right.access.contains(APublic)) return false;

    return switch ([left.kind, right.kind])
    {
      case [KFunction(first), KFunction(second)]:
        var compatible = first.args.length == second.args.length;
        if (compatible)
        {
          var printer = new Printer();
          for (i in 0...first.args.length)
          {
            var a = first.args[i];
            var b = second.args[i];
            // Native interface metadata omits types and optional flags. Compare
            // these only when both declarations actually provide them.
            if (a.opt != null && b.opt != null && a.opt != b.opt) compatible = false;
            if (a.t != null && b.t != null && printer.typeToString(a.t) != printer.typeToString(b.t)) compatible = false;
          }
          if (first.ret != null && second.ret != null
            && printer.typeToString(first.ret) != printer.typeToString(second.ret)) compatible = false;
        }
        compatible;
      default: false;
    };
  }
}
