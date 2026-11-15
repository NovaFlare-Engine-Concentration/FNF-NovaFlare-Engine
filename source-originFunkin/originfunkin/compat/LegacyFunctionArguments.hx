package originfunkin.compat;

import polymod.hscript._internal.Expr;
import polymod.hscript._internal.Interp;

typedef ArgumentValues = Map<String, {present:Bool, value:Dynamic}>;

/** Temporary argument variables used by historical scripted method calls. */
@:access(polymod.hscript._internal.Interp)
class LegacyFunctionArguments
{
  public static function execute(interp:Interp, fn:FunctionDecl, name:String, args:Array<Dynamic>):Dynamic
  {
    var oldDepth = interp.depth;
    var oldLocals = interp.locals;
    var oldDeclared = interp.declared;
    var oldFunction = interp.currentFunction;
    var previous:ArgumentValues = [];
    interp.locals = [];
    interp.declared = [];
    interp.depth++;
    interp.currentFunction = name;
    var result:Dynamic = null;
    var exception:Dynamic = null;
    var failed = false;
    try
    {
      interp.setFunctionValues(fn, args ?? [], name, false, previous);
      result = interp.exprReturn(fn.expr);
    }
    catch (error:Dynamic)
    {
      failed = true;
      exception = error;
    }
    for (arg => state in previous)
    {
      if (state.present) interp.variables.set(arg, state.value);
      else interp.variables.remove(arg);
      unmark(interp, arg);
    }
    interp.depth = oldDepth;
    interp.locals = oldLocals;
    interp.declared = oldDeclared;
    interp.currentFunction = oldFunction;
    if (failed) throw exception;
    return result;
  }

  public static function assign(interp:Interp, previous:ArgumentValues, name:String, value:Dynamic):Void
  {
    if (!previous.exists(name))
    {
      previous.set(name, {present:interp.variables.exists(name), value:interp.variables.get(name)});
      mark(interp, name);
    }
    interp.variables.set(name, value);
  }

  static function mark(interp:Interp, name:String):Void
  {
    interp.originArgumentNames ??= [];
    interp.originArgumentNames.set(name, (interp.originArgumentNames.get(name) ?? 0) + 1);
  }

  static function unmark(interp:Interp, name:String):Void
  {
    var count = interp.originArgumentNames?.get(name) ?? 0;
    if (count <= 1) interp.originArgumentNames?.remove(name);
    else interp.originArgumentNames.set(name, count - 1);
    if (interp.originArgumentNames != null && !interp.originArgumentNames.iterator().hasNext()) interp.originArgumentNames = null;
  }

  public static function hasArgument(interp:Interp, name:String):Bool return (interp.originArgumentNames?.get(name) ?? 0) > 0;

  public static function capture(interp:Interp, origin:Null<String>):Null<Map<String, Dynamic>>
  {
    if (!LegacyRuntime.isLegacyOrigin(origin)) return null;
    var captured:Map<String, Dynamic> = [];
    for (name => value in interp.variables)
      if (!Interp.defaultVariables.exists(name)) captured.set(name, value);
    return captured;
  }

  public static function restoreCaptured(interp:Interp, captured:Null<Map<String, Dynamic>>):Void
  {
    if (captured == null) return;
    // Match upstream: an existing variable takes precedence over its snapshot.
    for (name => value in captured)
    {
      if (interp.variables.exists(name)) captured.remove(name);
      else
      {
        interp.variables.set(name, value);
        mark(interp, name);
      }
    }
  }

  public static function removeCaptured(interp:Interp, captured:Null<Map<String, Dynamic>>):Void
  {
    if (captured == null) return;
    for (name in captured.keys())
    {
      interp.variables.remove(name);
      unmark(interp, name);
    }
  }
}
