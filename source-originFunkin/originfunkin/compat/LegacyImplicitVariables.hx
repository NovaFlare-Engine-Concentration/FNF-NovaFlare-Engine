package originfunkin.compat;

import polymod.hscript._internal.Expr;
import polymod.hscript._internal.Interp;
import polymod.hscript._internal.PolymodScriptClass;
import polymod.hscript._internal.Tools;

private typedef ImplicitCandidates =
{
  var instance:Map<String, Bool>;
  var statics:Map<String, Bool>;
}

/** Match old interpreter variables without inventing declared script fields. */
@:access(polymod.hscript._internal.Interp)
@:access(polymod.hscript._internal.PolymodScriptClass)
@:access(polymod.Polymod)
class LegacyImplicitVariables
{
  static var stamp:Int = -1;
  static var library:Dynamic;
  static var candidates:haxe.ds.ObjectMap<ClassDecl, ImplicitCandidates> = new haxe.ds.ObjectMap();
  static var staticCandidates:Null<Map<String, Bool>>;

  public static function hasMember(target:PolymodScriptClass, name:String):Bool
  {
    return (target._interp.originImplicitNames?.exists(name) == true || LegacyFunctionArguments.hasArgument(target._interp, name))
      && target._interp.variables.exists(name);
  }

  public static function readMember(target:PolymodScriptClass, name:String):Dynamic return target._interp.variables.get(name);

  public static function writeMember(target:PolymodScriptClass, name:String, value:Dynamic):Dynamic
  {
    target._interp.variables.set(name, value);
    return value;
  }

  static function refresh():Void
  {
    if (stamp == Interp.registryStamp && library == polymod.Polymod.assetLibrary) return;
    stamp = Interp.registryStamp;
    library = polymod.Polymod.assetLibrary;
    candidates = new haxe.ds.ObjectMap();
    staticCandidates = null;
  }

  public static function hasIdentifier(owner:ClassDecl, name:String, isStatic:Bool, locals:Map<String, Bool>):Bool
  {
    if (locals.exists(name)) return false;
    refresh();
    if (!isStatic) return forClass(owner).instance.exists(name);
    // Static methods use the shared script interpreter, just as upstream did.
    if (staticCandidates == null)
    {
      staticCandidates = [];
      for (decl in Interp._scriptClassDescriptors)
        for (name in forClass(decl).statics.keys()) staticCandidates.set(name, true);
    }
    return staticCandidates.exists(name);
  }

  public static function hasInstanceIdentifier(owner:ClassDecl, name:String):Bool
  {
    refresh();
    return forClass(owner).instance.exists(name);
  }

  static function forClass(owner:ClassDecl):ImplicitCandidates
  {
    var result = candidates.get(owner);
    if (result != null) return result;
    result = {instance:[], statics:[]};
    candidates.set(owner, result);
    for (field in owner.fields.concat(owner.staticFields))
    {
      var output = field.access.contains(AStatic) ? result.statics : result.instance;
      switch (field.kind)
      {
        case KFunction(fn):
          var locals:Map<String, Bool> = [];
          for (arg in fn.args) locals.set(arg.name, true);
          collect(fn.expr, locals, output);
        case KVar(v): if (v.expr != null) collect(v.expr, [], output);
      }
    }
    return result;
  }

  static function copy(locals:Map<String, Bool>):Map<String, Bool>
  {
    return [for (name in locals.keys()) name => true];
  }

  static function collect(expr:Expr, locals:Map<String, Bool>, output:Map<String, Bool>):Void
  {
    if (expr == null) return;
    switch (Tools.expr(expr))
    {
      case EBinop('=', target, value):
        switch (Tools.expr(target))
        {
          case EIdent(name):
            if (!locals.exists(name) && LegacyRuntime.isLegacyOrigin(expr.origin)) output.set(name, true);
          default: collect(target, locals, output);
        }
        collect(value, locals, output);
      case EBlock(expressions):
        var scope = copy(locals);
        for (item in expressions)
        {
          collect(item, scope, output);
          switch (Tools.expr(item))
          {
            case EVar(name, _, _) | EFinal(name, _, _): scope.set(name, true);
            case EFunction(_, _, name, _) if (name != null): scope.set(name, true);
            default:
          }
        }
      case EFunction(args, body, name, _):
        var scope = copy(locals);
        if (name != null) scope.set(name, true);
        for (arg in args)
        {
          if (arg.value != null) collect(arg.value, scope, output);
          scope.set(arg.name, true);
        }
        collect(body, scope, output);
      case EFor(name, iterator, body):
        collect(iterator, locals, output);
        var scope = copy(locals);
        scope.set(name, true);
        collect(body, scope, output);
      case EForGen(iterator, body):
        Tools.getKeyIterator(iterator, (key, value, actualIterator) ->
        {
          collect(actualIterator, locals, output);
          var scope = copy(locals);
          if (key != null) scope.set(key, true);
          if (value != null) scope.set(value, true);
          collect(body, scope, output);
          return true;
        });
      case ETry(body, catches):
        collect(body, locals, output);
        for (catcher in catches)
        {
          var scope = copy(locals);
          scope.set(catcher.name, true);
          collect(catcher.e, scope, output);
        }
      case ESwitch(value, cases, otherwise):
        collect(value, locals, output);
        for (item in cases)
        {
          var scope = copy(locals);
          for (pattern in item.values) patternLocals(pattern, scope);
          collect(item.guard, scope, output);
          collect(item.expr, scope, output);
        }
        collect(otherwise, locals, output);
      default: Tools.iter(expr, child -> collect(child, locals, output));
    }
  }

  static function patternLocals(expr:Expr, locals:Map<String, Bool>):Void
  {
    switch (Tools.expr(expr))
    {
      case EIdent(name) if (!['true', 'false', 'null', '_'].contains(name)): locals.set(name, true);
      case ECall(_, args): for (arg in args) patternLocals(arg, locals);
      case EField(_, _): // Qualified constant, not a binding.
      default: Tools.iter(expr, child -> patternLocals(child, locals));
    }
  }
}
