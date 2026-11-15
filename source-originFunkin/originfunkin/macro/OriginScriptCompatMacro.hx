package originfunkin.macro;

#if macro
import haxe.macro.Compiler;

/** Keep Polymod's generated script bridge out of the other two engines. */
class OriginScriptCompatMacro
{
  public static function configure():Void
  {
    OriginCppiaNativeWrappers.configure();
    if (haxe.macro.Context.defined("cpp") && haxe.macro.Context.defined("windows") && haxe.macro.Context.defined("scriptable"))
      Compiler.addGlobalMetadata("lime.utils.ArrayBufferView", "@:build(originfunkin.macro.OriginLimeArrayBufferCompat.build())", false, true, false);
    for (pack in ["codename", "codenamechain", "general", "games", "states", "mobile",
      "options", "psychlua", "objects", "backend", "external", "flx3d", "foxlite", "hscript",
      "gameanalytics", "originfunkin", "crowplexus", "developer", "modchart", "native", "scripts", "server", "substates",
      "hxvlc", "hxdiscord_rpc", "hxdiscord_social_sdk", "grig.audio.cpp", "extension", "funkin.api.discord", "funkin.external",
      "funkin.mobile.util", "funkin.modding.install", "funkin.util.tasks", "hx", "lime"])
    {
      Compiler.addGlobalMetadata(pack, "@:hscriptBaseCreated", true, true, false);
    }
    for (cls in ["Main", "MainInstance", "Watermark", "FPSViewer", "FlxTransWindow"])
      Compiler.addGlobalMetadata(cls, "@:hscriptBaseCreated", false, true, false);

    // Polymod reflects abstracts under its own nested `hx` namespace. Older
    // hxcpp closure macros use hx::MarkMember/VisitMember without a root prefix.
    // Make those GC helpers visible without changing script class identities.
    Compiler.addGlobalMetadata("polymod.hscript._internal._abstract.hx",
      '@:cppFileCode("namespace polymod { namespace hscript { namespace _internal { namespace _abstract { namespace hx { using namespace ::hx; } } } } }")',
      true, true, false);

    Compiler.addGlobalMetadata("polymod.hscript._internal.PolymodStaticInterfaceReference",
      "@:build(originfunkin.macro.OriginScriptCompatMacro.compatibleInterfaceInheritance())", false, true, false);
    Compiler.addGlobalMetadata("polymod.backends.PolymodAssetLibrary",
      "@:build(originfunkin.macro.OriginScriptCompatMacro.compatibleAssetPaths())", false, true, false);
    Compiler.addGlobalMetadata("polymod.Polymod",
      "@:build(originfunkin.macro.OriginScriptCompatMacro.uniqueScriptSources())", false, true, false);
    Compiler.addGlobalMetadata("polymod.backends",
      "@:build(originfunkin.macro.OriginScriptCompatMacro.completeAsyncReadsOnMainThread())", true, true, false);
    Compiler.addGlobalMetadata("polymod.hscript._internal.Interp",
      "@:build(originfunkin.macro.OriginScriptCompatMacro.legacyNativeWrites())", false, true, false);
    Compiler.addGlobalMetadata("polymod.hscript._internal.Interp",
      "@:build(originfunkin.macro.OriginScriptCompatMacro.historicalConstructors())", false, true, false);
    Compiler.addGlobalMetadata("polymod.hscript._internal.PolymodScriptClass",
      "@:build(originfunkin.macro.OriginScriptCompatMacro.historicalConstructors())", false, true, false);
    Compiler.addGlobalMetadata("polymod.hscript._internal.Interp",
      "@:build(originfunkin.macro.OriginScriptCompatMacro.legacySwitchConstants())", false, true, false);
    Compiler.addGlobalMetadata("polymod.hscript._internal.Interp",
      "@:build(originfunkin.macro.OriginScriptCompatMacro.historicalEnumPaths())", false, true, false);
    Compiler.addGlobalMetadata("polymod.hscript._internal.Interp",
      "@:build(originfunkin.macro.OriginScriptCompatMacro.historicalAnimationReads())", false, true, false);
    Compiler.addGlobalMetadata("flxanimate.animate.FlxAnim",
      "@:build(originfunkin.macro.OriginScriptCompatMacro.animationCallbackState())", false, true, false);
    Compiler.addGlobalMetadata("polymod.hscript._internal.PolymodScriptClass",
      "@:build(originfunkin.macro.OriginScriptCompatMacro.legacySongOverrides())", false, true, false);
    Compiler.addGlobalMetadata("polymod.hscript._internal.Interp",
      "@:build(originfunkin.macro.OriginScriptCompatMacro.historicalFieldDeclarations())", false, true, false);
    Compiler.addGlobalMetadata("polymod.hscript._internal.PolymodScriptClass",
      "@:build(originfunkin.macro.OriginScriptCompatMacro.historicalFieldDeclarations())", false, true, false);
    Compiler.addGlobalMetadata("polymod.hscript._internal.Interp",
      "@:build(originfunkin.macro.OriginScriptCompatMacro.implicitVariables())", false, true, false);
    Compiler.addGlobalMetadata("polymod.hscript._internal.ScriptPreheater",
      "@:build(originfunkin.macro.OriginScriptCompatMacro.implicitVariables())", false, true, false);
    Compiler.addGlobalMetadata("polymod.hscript._internal.Interp",
      "@:build(originfunkin.macro.OriginScriptCompatMacro.legacyArgumentScopes())", false, true, false);
    Compiler.addGlobalMetadata("polymod.hscript._internal.Interp",
      "@:build(originfunkin.macro.OriginScriptCompatMacro.historicalSongPaths())", false, true, false);
    Compiler.addGlobalMetadata("polymod.hscript._internal.Interp",
      "@:build(originfunkin.macro.OriginScriptCompatMacro.nullDeprecationSafety())", false, true, false);
    Compiler.addGlobalMetadata("polymod.hscript._internal.Interp",
      "@:build(originfunkin.macro.OriginScriptCompatMacro.staticScriptContextSafety())", false, true, false);
  }

  /** Restore Polymod's caller context when a static script exits through an error. */
  public static macro function staticScriptContextSafety():Array<haxe.macro.Expr.Field>
  {
    var fields = haxe.macro.Context.getBuildFields();
    var changed = 0;
    function rewrite(expr:haxe.macro.Expr):haxe.macro.Expr
    {
      var mapped = haxe.macro.ExprTools.map(expr, rewrite);
      return switch (mapped.expr)
      {
        case ETry(body, catches) if (catches.length == 1 && catches[0].name == 'err'):
          var errorType = switch (catches[0].type)
          {
            case TPath(path): path.name == 'Error' || (path.name == 'Expr' && path.sub == 'Error');
            default: false;
          };
          if (!errorType) mapped;
          else
          {
            var originalCatch = catches[0].expr;
            catches[0].expr = macro { this._classDeclOverride = previousClassDecl; $e{originalCatch}; };
            catches.push({
              name: '__originStaticError',
              type: macro:Dynamic,
              expr: macro { this._classDeclOverride = previousClassDecl; throw __originStaticError; }
            });
            changed++;
            {expr: ETry(body, catches), pos: mapped.pos};
          }
        default: mapped;
      }
    }
    for (field in fields) switch (field.kind)
    {
      case FFun(fn) if (field.name == 'callScriptClassStaticFunction' && fn.expr != null): fn.expr = rewrite(fn.expr);
      default:
    }
    if (changed != 1) haxe.macro.Context.error('Review Polymod static script context compatibility after its interpreter changed.', haxe.macro.Context.currentPos());
    return fields;
  }

  /** Native objects have no script class name; do not query deprecation maps with a null key. */
  public static macro function nullDeprecationSafety():Array<haxe.macro.Expr.Field>
  {
    var fields = haxe.macro.Context.getBuildFields();
    var found = 0;
    for (field in fields) switch (field.kind)
    {
      case FFun(fn) if (field.name == "checkTypeForDeprecation" || field.name == "checkFieldForDeprecation"):
        if (fn.args.length == 0 || fn.args[0].name != "cls" || fn.expr == null)
          haxe.macro.Context.error("Review Polymod deprecation compatibility after its signature changed.", field.pos);
        var original = fn.expr;
        fn.expr = macro { if (cls == null) return; $e{original}; };
        found++;
      default:
    }
    if (found != 2) haxe.macro.Context.error("Review Polymod deprecation compatibility after its methods changed.", haxe.macro.Context.currentPos());
    return fields;
  }

  public static macro function historicalSongPaths():Array<haxe.macro.Expr.Field>
  {
    var fields = haxe.macro.Context.getBuildFields();
    var found = 0;
    for (field in fields) switch (field.kind)
    {
      case FFun(_) if (field.name == "fcall"): field.name = "originHistoricalFcall"; found++;
      case FFun(_) if (field.name == "get"): field.name = "originHistoricalGet"; found++;
      default:
    }
    if (found != 2) haxe.macro.Context.error("Review historical song path bridge after Interp field access changed.", haxe.macro.Context.currentPos());
    fields.push({name:"fcall", access:[APrivate], pos:haxe.macro.Context.currentPos(), kind:FFun({
      args:[{name:"o",type:macro:Dynamic},{name:"f",type:macro:String},{name:"args",type:macro:Array<Dynamic>}],
      ret:macro:Dynamic, expr:macro {
        var origin = curExpr?.origin;
        var adaptedArgs = originfunkin.compat.LegacyRuntime.historicalSongArguments(o, f, args, origin);
        // Polymod clears its super-call skip list before fcall returns.
        var nativeSuper = _proxy != null && o == _proxy.superClass
          && !Std.isOfType(o, polymod.hscript._internal.PolymodScriptClass)
          && (originfunkin.compat.LegacyRuntime.isPreviewNoteStylePathTarget(o, f, origin) || originfunkin.compat.LegacyRuntime.isPreviewNoteStylePrivateSuperTarget(o, f, origin))
          && !(_proxy.findSuperFunction(f) == null && hasUsingFallback(o, f));
        var isScriptSuper = _proxy != null && o == _proxy.superClass && !Std.isOfType(o, polymod.hscript._internal.PolymodScriptClass);
        var result = originfunkin.compat.LegacyRuntime.withForcedAnimationRule(origin, o, f, () -> {
          if (nativeSuper && Std.isOfType(o, funkin.play.notes.notestyle.NoteStyle)) {
            var nativeClass = Type.getClass(o);
            var nativeName = nativeClass == null ? null : Type.getClassName(nativeClass);
            if (nativeName != null && polymod.hscript._internal.PolymodScriptClass.blacklistedInstanceFieldsOf(nativeName).contains(f))
              throw 'Cannot access blacklisted field $f';
            var candidate = originfunkin.compat.PreviewNoteStylePaths.resolve(cast o, f, args, true);
            if (candidate != originfunkin.compat.PreviewNoteStylePaths.UNHANDLED) return candidate;
          }
          return isScriptSuper ? originfunkin.compat.LegacyRuntime.withSafeScriptSuper(o, f, () -> originHistoricalFcall(o, f, adaptedArgs))
            : originHistoricalFcall(o, f, adaptedArgs);
        });
        result = originfunkin.compat.LegacyRuntime.historicalSongResult(o, f, result, origin);
        result = originfunkin.compat.LegacyRuntime.previewNoteStylePathResult(o, f, args, result, origin, nativeSuper);
        return originfunkin.compat.LegacyRuntime.historicalScoringResult(o, f, args, result, origin);
      }
    })});
    fields.push({name:"get", access:[APrivate], pos:haxe.macro.Context.currentPos(), kind:FFun({
      args:[{name:"o",type:macro:Dynamic},{name:"f",type:macro:String}], ret:macro:Null<Dynamic>, expr:macro {
        var origin = curExpr?.origin;
        var value = originHistoricalGet(o, f);
        var nativeSuper = _proxy != null && o == _proxy.superClass
          && !Std.isOfType(o, polymod.hscript._internal.PolymodScriptClass)
          && (originfunkin.compat.LegacyRuntime.isPreviewNoteStylePathTarget(o, f, origin) || originfunkin.compat.LegacyRuntime.isPreviewNoteStylePrivateSuperTarget(o, f, origin));
        // Polymod's normal get may return the script override even for super.
        // Keep its access checks, then bind the actual native method instead.
        if (nativeSuper && Reflect.isFunction(value))
        {
          var nativeValue = Reflect.field(o, f);
          if (Reflect.isFunction(nativeValue)) value = nativeValue;
        }
        value = originfunkin.compat.LegacyRuntime.historicalSongMethod(o, f, value, origin);
        value = originfunkin.compat.LegacyRuntime.previewNoteStylePathMethod(o, f, value, origin, nativeSuper);
        value = originfunkin.compat.LegacyRuntime.historicalForcedAnimationMethod(o, f, value, origin);
        value = originfunkin.compat.LegacyRuntime.historicalScoringRead(o, f, value, origin);
        return originfunkin.compat.LegacyRuntime.previewStaticAssetQuery(o, f, value, origin);
      }
    })});
    return fields;
  }

  public static macro function legacyArgumentScopes():Array<haxe.macro.Expr.Field>
  {
    var fields = haxe.macro.Context.getBuildFields();
    var hooks = 0;
    function arguments(expr:haxe.macro.Expr):haxe.macro.Expr
    {
      var mapped = haxe.macro.ExprTools.map(expr, arguments);
      return switch (mapped.expr)
      {
        case ECall({expr:EConst(CIdent('validateArgumentCount'))}, _):
          hooks++;
          macro {
            if (originArgumentValues == null || !originfunkin.compat.LegacyRuntime.usesLooseMethodArguments(fn.expr?.origin)) $e{mapped};
          };
        case EIf({expr:EBinop(OpBoolAnd, left, {expr:EBinop(OpNotEq,
          {expr:EArray({expr:EConst(CIdent('args'))}, {expr:EConst(CIdent('i'))})}, {expr:EConst(CIdent('null'))})})}, yes, no):
          hooks++;
          var condition = macro $e{left} && (args[i] != null || (originArgumentValues != null
            && originfunkin.compat.LegacyRuntime.usesLooseMethodArguments(fn.expr?.origin)));
          {expr:EIf(condition, yes, no), pos:mapped.pos};
        case ECall({expr:EField({expr:EField({expr:EConst(CIdent('this'))}, 'locals')}, 'set')},
          [{expr:EField({expr:EConst(CIdent('a'))}, 'name')}, _]):
          hooks++;
          macro {
            if (originArgumentValues != null)
              originfunkin.compat.LegacyFunctionArguments.assign(this, originArgumentValues, a.name, value);
            else $e{mapped};
          };
        default: mapped;
      }
    }
    function closures(expr:haxe.macro.Expr):haxe.macro.Expr
    {
      var mapped = haxe.macro.ExprTools.map(expr, closures);
      return switch (mapped.expr)
      {
        case EBlock(body):
          var output:Array<haxe.macro.Expr> = [];
          for (item in body)
          {
            output.push(item);
            switch (item.expr)
            {
              case EVars(vars) if (Lambda.exists(vars, variable -> variable.name == 'capturedLocals')):
                output.push(macro var originCapturedVariables = originfunkin.compat.LegacyFunctionArguments.capture(this, curExpr?.origin));
                hooks++;
              default:
            }
          }
          {expr:EBlock(output), pos:mapped.pos};
        case EFor({expr:EBinop(OpIn, _, {expr:EBinop(OpInterval, _, {expr:EField({expr:EConst(CIdent('params'))}, 'length')})})}, _):
          hooks++;
          macro {originfunkin.compat.LegacyFunctionArguments.restoreCaptured(me, originCapturedVariables); $e{mapped};};
        case EFunction(FNamed('restoreContext', inlineFlag), fn):
          var original = fn.expr;
          fn.expr = macro {originfunkin.compat.LegacyFunctionArguments.removeCaptured(me, originCapturedVariables); $e{original};};
          hooks++;
          {expr:EFunction(FNamed('restoreContext', inlineFlag), fn), pos:mapped.pos};
        default: mapped;
      }
    }
    for (field in fields) switch (field.kind)
    {
      case FFun(fn) if (fn.expr != null):
        switch (field.name)
        {
          case 'executeFunction':
            var original = fn.expr;
            fn.expr = macro {
              if (originfunkin.compat.LegacyRuntime.isLegacyOrigin(fn.expr?.origin))
                return originfunkin.compat.LegacyFunctionArguments.execute(this, fn, fnName, args);
              $e{original};
            };
            hooks++;
          case 'setFunctionValues':
            fn.args.push({name:'originArgumentValues', opt:true,
              type:macro:Null<originfunkin.compat.LegacyFunctionArguments.ArgumentValues>});
            fn.expr = arguments(fn.expr);
          case 'expr': fn.expr = closures(fn.expr);
          case 'resetVariables':
            var original = fn.expr;
            fn.expr = macro {originArgumentNames = null; $e{original};};
            hooks++;
          default:
        }
      default:
    }
    fields.push({name:'originArgumentNames', access:[APrivate], kind:FVar(macro:Null<Map<String, Int>>), pos:haxe.macro.Context.currentPos()});
    if (hooks != 8) haxe.macro.Context.error('Review historical method argument and closure hooks after Polymod changed.', haxe.macro.Context.currentPos());
    return fields;
  }

  public static macro function implicitVariables():Array<haxe.macro.Expr.Field>
  {
    var fields = haxe.macro.Context.getBuildFields();
    var isInterp = haxe.macro.Context.getLocalClass().get().name == 'Interp';
    var hooks = 0;
    function assignUnknown(expr:haxe.macro.Expr):haxe.macro.Expr
    {
      var mapped = haxe.macro.ExprTools.map(expr, assignUnknown);
      return switch (mapped.expr)
      {
        case ECall({expr:EConst(CIdent('error'))}, [{expr:ECall({expr:EConst(CIdent('EUnknownVariable'))}, _)}]):
          hooks++;
          macro {
            if (originfunkin.compat.LegacyRuntime.isLegacyOrigin(curExpr?.origin))
            {
              originImplicitNames ??= [];
              originImplicitNames.set(id, true);
              variables.set(id, v);
              return v;
            }
            $e{mapped};
          };
        default: mapped;
      }
    }
    function scriptMembers(expr:haxe.macro.Expr, write:Bool):haxe.macro.Expr
    {
      var mapped = haxe.macro.ExprTools.map(expr, child -> scriptMembers(child, write));
      return switch (mapped.expr)
      {
        case EIf(condition = {expr:ECall({expr:EField({expr:EConst(CIdent('Std'))}, 'isOfType')},
          [{expr:EConst(CIdent('o'))}, {expr:EConst(CIdent('PolymodScriptClass'))}])}, thenExpr, elseExpr):
          hooks++;
          var access = write ? macro originfunkin.compat.LegacyImplicitVariables.writeMember(cast o, f, v)
            : macro originfunkin.compat.LegacyImplicitVariables.readMember(cast o, f);
          var block = macro {
            if (originfunkin.compat.LegacyRuntime.usesImplicitMembers(curExpr?.origin)
              && originfunkin.compat.LegacyImplicitVariables.hasMember(cast o, f)) return $e{access};
            $e{thenExpr};
          };
          {expr:EIf(condition, block, elseExpr), pos:mapped.pos};
        default: mapped;
      }
    }
    for (field in fields) switch (field.kind)
    {
      case FFun(func) if (func.expr != null):
        var original = func.expr;
        if (isInterp) switch (field.name)
        {
          case 'setVar': func.expr = assignUnknown(original);
          case 'resetVariables':
            func.expr = macro {originImplicitNames = null; $e{original};};
            hooks++;
          case 'get': func.expr = scriptMembers(original, false);
          case 'set': func.expr = scriptMembers(original, true);
          default:
        }
        else switch (field.name)
        {
          case 'preheatIdentifierExists':
            func.expr = macro {
              if (originfunkin.compat.LegacyImplicitVariables.hasIdentifier(owner, name, isStatic, locals)) return true;
              $e{original};
            };
            hooks++;
          case 'preheatWalk':
            func.expr = macro {
              switch (Tools.expr(expr))
              {
                case EField(target, name) if (!isStatic && switch (Tools.expr(target)) {case EIdent('this'): true; default: false;}):
                  if (originfunkin.compat.LegacyRuntime.usesImplicitMembers(expr.origin)
                    && originfunkin.compat.LegacyImplicitVariables.hasInstanceIdentifier(owner, name))
                  {
                    stats.checked++;
                    return;
                  }
                default: null;
              }
              $e{original};
            };
            hooks++;
          default:
        }
      default:
    }
    if (isInterp) fields.push({name:'originImplicitNames', access:[APrivate],
      kind:FVar(macro:Null<Map<String, Bool>>), pos:haxe.macro.Context.currentPos()});
    if (hooks != (isInterp ? 4 : 2))
      haxe.macro.Context.error('Review the implicit-variable runtime/preheat hooks after Polymod changed.', haxe.macro.Context.currentPos());
    return fields;
  }

  public static macro function historicalFieldDeclarations():Array<haxe.macro.Expr.Field>
  {
    var fields = haxe.macro.Context.getBuildFields();
    var hooks = 0;
    function recordDeclaration(expr:haxe.macro.Expr):haxe.macro.Expr
    {
      var mapped = haxe.macro.ExprTools.map(expr, recordDeclaration);
      return switch (mapped.expr)
      {
        case ECall({expr:EConst(CIdent('registerScriptClass'))}, [decl]):
          hooks++;
          macro {originfunkin.compat.LegacyFieldDeclarations.register($e{decl}, origin); $e{mapped};};
        default: mapped;
      }
    }
    function guardDuplicates(expr:haxe.macro.Expr):haxe.macro.Expr
    {
      var mapped = haxe.macro.ExprTools.map(expr, guardDuplicates);
      return switch (mapped.expr)
      {
        case EIf(condition = {expr:ECall({expr:EField({expr:EConst(CIdent('_cachedFieldDecls'))}, 'exists')}, _)}, thenExpr, elseExpr):
          hooks++;
          // Preserve the entire original loop, including every initializer and
          // each cache's last-declaration behavior.
          {expr:EIf(macro $e{condition} && !originfunkin.compat.LegacyFieldDeclarations.allows(_c), thenExpr, elseExpr), pos:mapped.pos};
        default: mapped;
      }
    }
    var isInterp = haxe.macro.Context.getLocalClass().get().name == 'Interp';
    for (field in fields) switch (field.kind)
    {
      case FFun(func) if (func.expr != null):
        var original = func.expr;
        if (isInterp && field.name == 'registerModules')
        {
          // registerModules builds a new descriptor from the parsed DClass;
          // record that final descriptor's identity, not the parser's object.
          func.expr = recordDeclaration(original);
        }
        else if (isInterp && field.name == 'clearScriptClassDescriptors')
        {
          func.expr = macro {originfunkin.compat.LegacyFieldDeclarations.clear(); $e{original};};
          hooks++;
        }
        else if (!isInterp && field.name == 'buildCaches') func.expr = guardDuplicates(original);
      default:
    }
    if (hooks != (isInterp ? 2 : 1))
      haxe.macro.Context.error('Review Polymod repeated-field compatibility hooks.', haxe.macro.Context.currentPos());
    return fields;
  }

  public static macro function legacySongOverrides():Array<haxe.macro.Expr.Field>
  {
    var fields = haxe.macro.Context.getBuildFields();
    var changed = 0;
    for (field in fields) if (field.name == 'callFunction') switch (field.kind)
    {
      case FFun(func):
        var original = func.expr;
        func.expr = macro {
          args = originfunkin.compat.LegacyRuntime.scriptMethodArgs(this, fnName, args);
          $e{original};
        };
        changed++;
      default:
    }
    if (changed != 1) haxe.macro.Context.error('Review Polymod scripted Song overrides after its interpreter changed.', haxe.macro.Context.currentPos());
    return fields;
  }

  public static macro function legacySwitchConstants():Array<haxe.macro.Expr.Field>
  {
    var fields = haxe.macro.Context.getBuildFields();
    var changed = 0;
    for (field in fields) if (field.name == 'evalSwitchCase') switch (field.kind)
    {
      case FFun(func):
        var original = func.expr;
        func.expr = macro {
          if (originfunkin.compat.LegacyRuntime.isLegacyOrigin(v.origin)) switch (Tools.expr(v))
          {
            case EIdent(name) if (name != '_' && name != 'true' && name != 'false'):
              var decl = getClassDecl();
              var constant = decl?.staticFields.find(field -> field.name == name && switch (field.kind)
              {
                case KVar(_): true;
                default: false;
              });
              if (constant != null || locals.exists(name) || variables.exists(name)
                || _proxy?.fieldExists(name) == true || _proxy?.superHasField(name) == true)
              {
                var expected = locals.exists(name) ? locals.get(name).r : resolve(name);
                if (Reflect.isEnumValue(val) && Reflect.isEnumValue(expected)) return Type.enumEq(val, expected);
                return val == expected;
              }
            default: null;
          }
          $e{original};
        };
        changed++;
      default:
    }
    if (changed != 1) haxe.macro.Context.error('Review Polymod switch-constant compatibility after its interpreter changed.', haxe.macro.Context.currentPos());
    return fields;
  }

  public static macro function historicalConstructors():Array<haxe.macro.Expr.Field>
  {
    var fields = haxe.macro.Context.getBuildFields();
    var isInterp = haxe.macro.Context.getLocalClass().get().name == 'Interp';
    var origin = isInterp ? macro curExpr?.origin : macro (@:privateAccess _interp.curExpr?.origin) ?? originfunkin.compat.LegacyFieldDeclarations.originOf(_c);
    var changed = 0;
    function rewrite(expr:haxe.macro.Expr):haxe.macro.Expr
    {
      return switch (expr.expr)
      {
        case ECall({expr:EField({expr:EConst(CIdent('Type'))}, 'createInstance')}, [cls, args]):
          changed++;
          macro Type.createInstance($e{cls}, originfunkin.compat.LegacyRuntime.constructorArgs($e{cls}, $e{args}, $e{origin}));
        default: haxe.macro.ExprTools.map(expr, rewrite);
      }
    }
    for (field in fields) if (field.name == (isInterp ? 'cnew' : 'createSuperClass')) switch (field.kind)
    {
      case FFun(func): func.expr = rewrite(func.expr);
      default:
    }
    if (changed != (isInterp ? 3 : 1))
      haxe.macro.Context.error('Review Polymod native constructor compatibility after its interpreter changed.', haxe.macro.Context.currentPos());
    return fields;
  }

  public static macro function legacyNativeWrites():Array<haxe.macro.Expr.Field>
  {
    var fields = haxe.macro.Context.getBuildFields();
    var changed = 0;
    var guarded = 0;
    function rewrite(expr:haxe.macro.Expr):haxe.macro.Expr
    {
      return switch (expr.expr)
      {
        case ECall({expr:EField({expr:EConst(CIdent("PolymodAbstractScriptClass"))}, "setClassObjectField")}, args):
          if (args.length != 3 && args.length != 4)
            haxe.macro.Context.error("Review Polymod's native-write arguments after its interpreter changed.", expr.pos);
          changed++;
          var bypass = args.length == 4 ? args[3] : macro false;
          macro originfunkin.compat.LegacyRuntime.setNativeField($a{args.slice(0, 3).concat([macro curExpr?.origin, macro _proxy, bypass])});
        default: haxe.macro.ExprTools.map(expr, rewrite);
      }
    }
    function rewriteImportGuards(expr:haxe.macro.Expr):haxe.macro.Expr
    {
      var mapped = haxe.macro.ExprTools.map(expr, rewriteImportGuards);
      return switch (mapped.expr)
      {
        case EIf(condition, yes, no):
          switch (condition.expr)
          {
            case ECall({expr:EField({expr:EConst(CIdent(list))}, "contains")}, _) if (list == "finals" || list == "privates"):
              guarded++;
              var compatible = macro $e{condition} && !originfunkin.compat.LegacyRuntime.isLegacyOrigin(e1.origin);
              {expr:EIf(compatible, yes, no), pos:mapped.pos};
            default: mapped;
          }
        default: mapped;
      }
    }
    var scopedUpdates = 0;
    var scopedWriteSites = 0;
    var uniqueSpeedArg = 0;
    for (field in fields) if (field.name == "set") switch (field.kind)
    {
      case FFun(func): func.expr = rewrite(func.expr);
      default:
    }
    else if (["assignValue", "evalAssignOp", "increment"].contains(field.name)) switch (field.kind)
    {
      case FFun(func):
        var target = field.name == "increment" ? macro e : macro e1;
        function scopeWrites(expr:haxe.macro.Expr):haxe.macro.Expr
        {
          var mapped = haxe.macro.ExprTools.map(expr, scopeWrites);
          switch (mapped.expr)
          {
            case ECall(callee, args):
              var isWrite = switch (callee.expr)
              {
                case EConst(CIdent(name)) if (name == "set" || name == "setVar"): true;
                case EField({expr:EConst(CIdent("_proxy"))}, "callFunction"): true;
                case EField({expr:EConst(CIdent("superClass"))}, "fieldWrite"): true;
                case EField({expr:EConst(CIdent("PolymodAbstractScriptClass"))}, "setClassObjectField"): true;
                default: false;
              }
              if (!isWrite) return mapped;
              scopedWriteSites++;
              // Resolve call arguments before setting the version context:
              // evaluating a target can itself mutate another dialogue box.
              var declarations:Array<haxe.macro.Expr> = [];
              var argRefs:Array<haxe.macro.Expr> = [];
              for (arg in args)
              {
                var name = '__originSpeedArg${uniqueSpeedArg++}';
                declarations.push({expr:EVars([{name:name, type:null, expr:arg}]), pos:arg.pos});
                argRefs.push({expr:EConst(CIdent(name)), pos:arg.pos});
              }
              var call:haxe.macro.Expr = {expr:ECall(callee, argRefs), pos:mapped.pos};
              declarations.push(macro (speedField
                ? originfunkin.compat.LegacyRuntime.withPreviewDialogueSpeedWrite($e{target}?.origin, true, () -> $e{call})
                : $e{call}));
              return {expr:EBlock(declarations), pos:mapped.pos};
            default: return mapped;
          }
        }
        var original = field.name == "assignValue" ? rewriteImportGuards(func.expr) : func.expr;
        original = scopeWrites(original);
        func.expr = macro {
          var speedField = switch (Tools.expr($e{target})) {
            case EIdent(name) | EField(_, name): name == 'speed';
            default: false;
          };
          $e{original};
        };
        scopedUpdates++;
      default:
    }
    if (scopedUpdates != 3 || scopedWriteSites < 3)
      haxe.macro.Context.error("Review Polymod's dialogue speed update bridge after its interpreter changed.", haxe.macro.Context.currentPos());
    if (changed != 1) haxe.macro.Context.error("Review Polymod's native-write compatibility bridge after its interpreter changed.", haxe.macro.Context.currentPos());
    if (guarded != 2) haxe.macro.Context.error("Review Polymod's imported-field checks after its interpreter changed.", haxe.macro.Context.currentPos());
    return fields;
  }

  /** The legacy Lime Promise dispatches callbacks immediately on the completing thread. */
  public static macro function completeAsyncReadsOnMainThread():Array<haxe.macro.Expr.Field>
  {
    var fields = haxe.macro.Context.getBuildFields();
    if (haxe.macro.Context.getLocalClass().get().name != "LimeAsyncHandler") return fields;
    var removed = 0;
    function removeWorkerCompletion(expr:haxe.macro.Expr):haxe.macro.Expr
    {
      return switch (expr.expr)
      {
        case ECall({expr:EField({expr:EConst(CIdent("promise"))}, "complete")}, _):
          removed++;
          macro null;
        default: haxe.macro.ExprTools.map(expr, removeWorkerCompletion);
      }
    }
    for (field in fields)
      if (field.name == "localThreadPool_doWork") switch (field.kind)
      {
        // sendComplete already queues the same result for localThreadPool_onComplete.
        // Completing here races that callback and runs the shared script parser off-thread.
        case FFun(func):
          // Check the upstream worker shape before replacing it: Promise callbacks
          // must run on the main thread for both success and failure.
          func.expr = removeWorkerCompletion(func.expr);
          func.expr = macro {
            var promise = state.promise;
            try
            {
              switch (state.task)
              {
                case "loadBytesFromFileSystem":
                  var result = state.fileSystem.getFileBytes(state.path);
                  if (result == null)
                    localThreadPool.sendError({promise: promise, error: 'Could not read file: ${state.path}'});
                  else
                  {
                    localThreadPool.sendProgress({promise: promise, bytesLoaded: result.length, bytesTotal: result.length});
                    localThreadPool.sendComplete({promise: promise, result: result});
                  }
                default:
                  localThreadPool.sendError({promise: promise, error: 'Invalid task: ${state.task}'});
              }
            }
            catch (error:Dynamic)
            {
              localThreadPool.sendError({promise: promise, error: error});
            }
          };
        default:
      }
    if (removed != 1) haxe.macro.Context.error("Polymod's async reader changed; review its main-thread completion bridge.", haxe.macro.Context.currentPos());
    return fields;
  }

  public static macro function compatibleAssetPaths():Array<haxe.macro.Expr.Field>
  {
    var fields = haxe.macro.Context.getBuildFields();
    for (field in fields)
      if (field.name == "file") switch (field.kind)
      {
        case FFun(func): func.expr = mapPathReturns(func.expr);
        default:
      }
    return fields;
  }

  public static macro function animationCallbackState():Array<haxe.macro.Expr.Field>
  {
    var fields = haxe.macro.Context.getBuildFields();
    fields.push({name:'originLegacyCallbacks', access:[APrivate], pos:haxe.macro.Context.currentPos(),
      kind:FVar(macro:originfunkin.compat.LegacyAnimationCallbacks.AnimationCallbacksState, macro null)});
    var changed = 0;
    for (field in fields) if (field.name == 'destroy') switch (field.kind)
    {
      case FFun(func):
        var original = func.expr;
        func.expr = macro { originfunkin.compat.LegacyAnimationCallbacks.clear(this); $e{original}; };
        changed++;
      default:
    }
    if (changed != 1) haxe.macro.Context.error('Review FlxAnim callback cleanup after its lifecycle changed.', haxe.macro.Context.currentPos());
    return fields;
  }

  public static macro function historicalAnimationReads():Array<haxe.macro.Expr.Field>
  {
    var fields = haxe.macro.Context.getBuildFields();
    var changed = 0;
    function rewrite(expr:haxe.macro.Expr):haxe.macro.Expr
    {
      return switch (expr.expr)
      {
        case EIf({expr:ECall({expr:EField({expr:EConst(CIdent('Std'))}, 'isOfType')},
          [{expr:EConst(CIdent('o'))}, {expr:EConst(CIdent('PolymodStaticAbstractReference'))}])}, _, _):
          changed++;
          macro {
            if (originfunkin.compat.LegacyAnimationCallbacks.hasValue(o, f, curExpr?.origin))
              return originfunkin.compat.LegacyAnimationCallbacks.getValue(o, f);
              if (f == 'playBlueBalledSFX' && o == funkin.play.GameOverSubState
                && originfunkin.compat.LegacyRuntime.isLegacyOrigin(curExpr?.origin))
                return originfunkin.compat.LegacyGameOver.playBlueBalledSFX;
            $e{expr};
          };
        default: haxe.macro.ExprTools.map(expr, rewrite);
      }
    }
    for (field in fields) if (field.name == 'get') switch (field.kind)
    {
      case FFun(func): func.expr = rewrite(func.expr);
      default:
    }
    if (changed != 1) haxe.macro.Context.error('Review the interpreter callback read bridge and blacklist ordering.', haxe.macro.Context.currentPos());
    return fields;
  }

  public static macro function historicalEnumPaths():Array<haxe.macro.Expr.Field>
  {
    var fields = haxe.macro.Context.getBuildFields();
    var changed = 0;
    function rewrite(expr:haxe.macro.Expr):haxe.macro.Expr
    {
      return switch (expr.expr)
      {
        case ECall({expr:EField({expr:EConst(CIdent("Type"))}, "resolveEnum")}, [path]):
          changed++;
          macro originfunkin.compat.LegacyTypePaths.resolveEnum($e{path});
        default: haxe.macro.ExprTools.map(expr, rewrite);
      }
    }
    for (field in fields) switch (field.kind)
    {
      case FFun(func) if (func.expr != null): func.expr = rewrite(func.expr);
      default:
    }
    if (changed != 2) haxe.macro.Context.error('Review Polymod enum imports and dotted paths after its interpreter changed.', haxe.macro.Context.currentPos());
    return fields;
  }

  static function mapPathReturns(expr:haxe.macro.Expr):haxe.macro.Expr
  {
    var mapped = haxe.macro.ExprTools.map(expr, mapPathReturns);
    switch (mapped.expr)
    {
      case EReturn(value) if (value != null):
        return macro return originfunkin.compat.LegacyAssetLayout.resolveFilesystemPath(fileSystem, $e{value});
      default: return mapped;
    }
  }

  public static macro function uniqueScriptSources():Array<haxe.macro.Expr.Field>
  {
    var fields = haxe.macro.Context.getBuildFields();
    var dependencyHooks = 0;
    function registerDependencies(expr:haxe.macro.Expr):haxe.macro.Expr
    {
      var mapped = haxe.macro.ExprTools.map(expr, registerDependencies);
      return switch (mapped.expr)
      {
        case ECall({expr:EField(_, 'validateImports')}, []):
          dependencyHooks++;
          macro {originfunkin.compat.LegacyCoreScripts.registerDependencies(); $e{mapped};};
        default: mapped;
      }
    }
    for (field in fields)
      if (field.name == "registerAllScriptClasses" || field.name == "registerAllScriptClassesAsync") switch (field.kind)
      {
          case FFun(func) if (func.expr != null): func.expr = registerDependencies(mapScriptSources(func.expr));
        default:
      }
    if (dependencyHooks != 2) haxe.macro.Context.error('Review the sync/async core dependency registration hooks.', haxe.macro.Context.currentPos());
    return fields;
  }

  static function mapScriptSources(expr:haxe.macro.Expr):haxe.macro.Expr
  {
    var mapped = haxe.macro.ExprTools.map(expr, mapScriptSources);
    switch (mapped.expr)
    {
      case EVars(vars):
        for (variable in vars)
          if (variable.name == "potentialScripts" && variable.expr != null)
              variable.expr = macro originfunkin.compat.LegacyCoreScripts.prepare(originfunkin.compat.LegacyScriptSources.unique($e{variable.expr}));
      default:
    }
    return mapped;
  }

  /** Identical inherited method contracts are legal in NF's Flixel interfaces. */
  public static macro function compatibleInterfaceInheritance():Array<haxe.macro.Expr.Field>
  {
    var fields = haxe.macro.Context.getBuildFields();
    for (field in fields)
    {
      if (field.name != "appendInterfaceToList") continue;
      switch (field.kind)
      {
        case FFun(func):
          func.expr = macro originfunkin.OriginPolymodInterfaceCompat.appendInterfaces(currentFieldList, toAdd);
        default:
      }
    }
    return fields;
  }

  public static macro function allowBitmapOverrides():Array<haxe.macro.Expr.Field>
  {
    var fields = haxe.macro.Context.getBuildFields();
    for (field in fields)
      if (["addGraphic", "get", "removeKey", "stop"].indexOf(field.name) >= 0)
        field.access.remove(haxe.macro.Expr.Access.AInline);
    return fields;
  }
}
#end
