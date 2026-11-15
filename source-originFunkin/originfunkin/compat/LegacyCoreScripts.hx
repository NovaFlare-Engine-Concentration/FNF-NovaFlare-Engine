package originfunkin.compat;

import haxe.io.Path;
import polymod.hscript._internal.Expr;
import polymod.hscript._internal.Interp;
import polymod.hscript._internal.Parser;
import polymod.hscript._internal.PolymodScriptClass;
using Lambda;

private typedef CoreModule =
{
  var asset:String;
  var declarations:Array<ModuleDecl>;
  var types:Map<String, Bool>;
  var processed:Bool;
}

private typedef CoreScope =
{
  var pkg:Array<String>;
  var imports:Map<String, ClassImport>;
  var importsToValidate:Map<String, ClassImport>;
}

/** Retain current core dependencies omitted by a historical whole-file override. */
@:access(polymod.Polymod)
@:access(polymod.hscript._internal.Interp)
@:access(polymod.hscript._internal.PolymodScriptClass)
class LegacyCoreScripts
{
  static final DEPENDENCY_META = ':originCoreDependency';
  static var candidates:Map<String, CoreModule> = [];

  public static function prepare(paths:Array<String>, ?baseRoot:String):Array<String>
  {
    candidates.clear();
    #if sys
    baseRoot ??= originfunkin.OriginFunkinMode.assetsRoot;
    if (baseRoot == null) return paths;
    var seen:Map<String, Bool> = [];
    var canonical:Map<String, Bool> = [];
    for (path in paths)
    {
      canonical.set(path, true);
      for (alias in LegacyAssetLayout.aliases(path)) canonical.set('assets/$alias', true);
    }
    for (asset in canonical.keys())
    {
      if (!StringTools.startsWith(asset, 'assets/') || !StringTools.endsWith(asset, '.hxc')) continue;
      var relative = asset.substr(7);
      if (relative.indexOf('..') >= 0 || Path.isAbsolute(relative)) continue;
      var source = Path.join([baseRoot, relative]);
      if (!sys.FileSystem.exists(source) || sys.FileSystem.isDirectory(source)) continue;
      var physical = polymod.Polymod.assetLibrary.getPath(asset);
      if (normalize(physical) == normalize(source) || seen.exists(normalize(source))) continue;
      if (!LegacyRuntime.isLegacyOrigin('hscriptClass($asset)')) continue;
      seen.set(normalize(source), true);
      var declarations = new Parser().parseModule(sys.io.File.getContent(source), 'origin-core($asset)');
      var module:CoreModule = {asset:asset, declarations:declarations, types:[], processed:false};
      var pkg = '';
      for (decl in declarations)
      {
        switch (decl)
        {
          case DPackage(path): pkg = path.length == 0 ? '' : path.join('.') + '.';
          case DClass(c): module.types.set(pkg + c.name, true);
          case DEnum(e): module.types.set(pkg + e.name, true);
          case DInterface(i): module.types.set(pkg + i.name, true);
          default:
        }
      }
      for (name in module.types.keys()) candidates.set(name, module);
    }
    #end
    return paths;
  }

  static function normalize(path:Null<String>):String
  {
    var value = Path.normalize(path ?? '');
    #if windows
    value = value.toLowerCase();
    #end
    return value;
  }

  static function exists(name:String):Bool
  {
    return Interp._scriptClassDescriptors.exists(name) || Interp._scriptEnumDescriptors.exists(name)
      || Interp._scriptInterfaceDescriptors.exists(name) || Type.resolveClass(name) != null || Type.resolveEnum(name) != null
      || (PolymodScriptClass.importOverrides.exists(name) && PolymodScriptClass.importOverrides.get(name) != null);
  }

  static function blocked(name:String):Bool
  {
    return PolymodScriptClass.importOverrides.exists(name) && PolymodScriptClass.importOverrides.get(name) == null;
  }

  public static function registerDependencies():Void
  {
    var changed = true;
    while (changed)
    {
      changed = false;
      var needed:Map<String, Bool> = [];
      for (decl in Interp._scriptClassDescriptors)
      {
        for (imports in [decl.imports, decl.importsToValidate, decl.usings, decl.usingsToValidate]) addImports(imports, needed);
        addParent(decl.extend, decl, needed);
        for (parent in decl.implement) addParent(parent, decl, needed);
      }
      for (decl in Interp._scriptInterfaceDescriptors)
      {
        addImports(decl.imports, needed);
        addImports(decl.importsToValidate, needed);
        for (parent in decl.extend) addParent(parent, decl, needed);
      }
      for (name in needed.keys())
      {
        if (exists(name) || blocked(name)) continue;
        var candidate = name;
        var module = candidates.get(candidate);
        // A pending import can name a static member of the missing class.
        while (module == null && candidate.indexOf('.') >= 0)
        {
          candidate = candidate.substr(0, candidate.lastIndexOf('.'));
          module = candidates.get(candidate);
        }
        if (exists(candidate) || blocked(candidate)) continue;
        if (module == null || module.processed) continue;
        module.processed = true;
        var pkg = '';
        var selected:Array<ModuleDecl> = [];
        var retained:Array<String> = [];
        for (decl in module.declarations)
        {
          var type:Null<String> = null;
          switch (decl)
          {
            case DPackage(path): pkg = path.length == 0 ? '' : path.join('.') + '.';
            case DClass(c): type = pkg + c.name;
            case DEnum(e): type = pkg + e.name;
            case DInterface(i): type = pkg + i.name;
            default:
          }
          if (type != null && (exists(type) || blocked(type))) continue;
          switch (decl)
          {
            case DClass(c):
              c.meta = (c.meta ?? []).copy();
              c.meta.push({name:DEPENDENCY_META, params:[]});
            default:
          }
          selected.push(decl);
          if (type != null) retained.push(type);
        }
        if (retained.length == 0) continue;
        // Register parsed declarations directly, preserving expressions and their
        // current-core origin rather than reparsing a rewritten source string.
        PolymodScriptClass.scriptInterp.registerModules(selected, 'origin-core(${module.asset})');
        trace('[Origin compatibility] Retained current core dependencies: ${retained.join(", ")}');
        changed = true;
      }
    }
    candidates.clear();
  }

  static function addImports(imports:Null<Map<String, ClassImport>>, needed:Map<String, Bool>):Void
  {
    if (imports == null) return;
    for (imp in imports)
      if (imp.wildcard == true)
      {
        for (name in candidates.keys())
          if (StringTools.startsWith(name, imp.fullPath + '.')) needed.set(name, true);
      }
      else needed.set(imp.fullPath, true);
  }

  static function addParent(type:Null<CType>, decl:CoreScope, needed:Map<String, Bool>):Void
  {
    if (type == null) return;
    switch (type)
    {
      case CTPath(path, _):
        if (path.length > 1) needed.set(path.join('.'), true);
        else if (path.length == 1)
        {
          var name = path[0];
          var imp = decl.imports?.get(name) ?? decl.importsToValidate?.get(name);
          needed.set(imp?.fullPath ?? ((decl.pkg?.length ?? 0) == 0 ? name : decl.pkg.join('.') + '.' + name), true);
        }
      default:
    }
  }

  public static function entryClasses(classes:Array<String>):Array<String>
  {
    return classes.filter(name ->
    {
      var decl = Interp._scriptClassDescriptors.get(name);
      return decl == null || decl.meta == null || !decl.meta.exists(meta -> meta.name == DEPENDENCY_META);
    });
  }
}
