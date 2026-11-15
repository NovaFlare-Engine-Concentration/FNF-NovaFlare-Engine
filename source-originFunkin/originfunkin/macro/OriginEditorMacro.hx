package originfunkin.macro;

#if macro
import haxe.io.Path;
import haxe.macro.Context;
import haxe.macro.Expr;
import sys.FileSystem;

/** Resolve editor source layouts without adding Origin's assets to Project.xml. */
@:access(haxe.ui.macros.ComponentMacros)
class OriginEditorMacro
{
  static function getAssetsRoot():String
  {
    var root = Context.definedValue("ORIGIN_ASSETS_PATH");
    if (root == null || root == "")
    {
      // Layouts are read at compile time; the assets themselves stay external.
      root = "export/release/windows/bin/Funkin/OriginFunkin/assets";
    }
    return FileSystem.fullPath(root);
  }

  public static function configure():Void
  {
    var layouts = Path.join([getAssetsRoot(), "exclude/ui/editors"]);
    if (!FileSystem.exists(layouts) || !FileSystem.isDirectory(layouts))
    {
      Context.error('Origin editor layouts were not found in "$layouts". Use the complete external assets pack.', Context.currentPos());
    }
  }

  public static function build(path:String):Array<Field>
  {
    var relative = StringTools.startsWith(path, "assets/") ? path.substr("assets/".length) : path;
    var absolute = Path.join([getAssetsRoot(), relative]);
    var fields = haxe.ui.macros.ComponentMacros.buildCommon(absolute);
    // The existing HaxeUI version emits px/semicolon dimension attributes as
    // strings. Normalize only numeric layout assignments in its generated AST.
    for (field in fields)
    {
      switch (field.kind)
      {
        case FFun(func) if (func.expr != null): func.expr = adaptDimensions(func.expr);
        default:
      }
    }
    return fields;
  }

  static function adaptDimensions(expr:Expr):Expr
  {
    var mapped = haxe.macro.ExprTools.map(expr, adaptDimensions);
    switch (mapped.expr)
    {
      case EBinop(OpAssign, target = {expr: EField(_, name)}, value)
        if (["width", "height", "minWidth", "minHeight", "maxWidth", "maxHeight", "paddingLeft", "paddingRight", "paddingTop", "paddingBottom"].contains(name)):
        mapped.expr = EBinop(OpAssign, target, numericDimension(value));
      default:
    }
    return mapped;
  }

  static function numericDimension(value:Expr):Expr
  {
    switch (value.expr)
    {
      case EMeta(meta, inner): return {expr: EMeta(meta, numericDimension(inner)), pos: value.pos};
      case EConst(CString(text, _)) if (~/^[+-]?[0-9]+(\.[0-9]+)?(px)?;?$/.match(text)):
        return {expr: EConst(CFloat(Std.string(Std.parseFloat(text)))), pos: value.pos};
      default: return value;
    }
  }
}
#end
