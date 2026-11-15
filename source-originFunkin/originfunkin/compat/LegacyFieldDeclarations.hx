package originfunkin.compat;

import polymod.hscript._internal.Expr;

/** Remember declaration ownership without accepting script-authored policy metadata. */
class LegacyFieldDeclarations
{
  static var early:haxe.ds.ObjectMap<ClassDecl, Bool> = new haxe.ds.ObjectMap();
  static var origins:haxe.ds.ObjectMap<ClassDecl, String> = new haxe.ds.ObjectMap();

  public static function register(decl:ClassDecl, origin:String):Void
  {
    origins.set(decl, origin);
    if (LegacyRuntime.usesRepeatedFields(origin)) early.set(decl, true);
    else early.remove(decl);
  }

  public static function allows(decl:ClassDecl):Bool return early.exists(decl);

  public static function originOf(decl:ClassDecl):Null<String> return origins.get(decl);

  public static function clear():Void
  {
    early = new haxe.ds.ObjectMap();
    origins = new haxe.ds.ObjectMap();
  }
}
