package originfunkin.compat;

#if (sys && FEATURE_DEBUG_FUNCTIONS)
import polymod.hscript._internal.Interp;
import polymod.hscript._internal.PolymodScriptClass;
using Lambda;

@:access(polymod.Polymod)
@:access(polymod.hscript._internal.PolymodScriptClass)
class CoreDependencyChecks
{
  static function require(condition:Bool, message:String):Void
  {
    if (!condition) throw 'Core dependency compatibility check failed: $message';
    trace('[Origin core dependency check] PASS $message');
  }

  public static function run(root:String):Void
  {
    var assetPaths = [for (id in ['core-dependency', 'unused-dependency', 'modern-dependency', 'blocked-dependency'])
      'assets/gameplay/characters/$id/$id.hxc'];
    assetPaths[0] = 'assets/preload/scripts/characters/core-dependency.hxc';
    LegacyCoreScripts.prepare(assetPaths, haxe.io.Path.join([root, '../origin-core-fixtures']));
    for (path in assetPaths)
      PolymodScriptClass.registerScriptClassByString(polymod.Polymod.assetLibrary.getText(path), path);
    for (name in ['CoreConsumer', 'ModernHelperConsumer', 'BlockedHelperConsumer', 'ProvidedCoreHelper'])
    {
      var path = 'assets/scripts/$name.hxc';
      PolymodScriptClass.registerScriptClassByString(polymod.Polymod.assetLibrary.getText(path), path);
    }
    polymod.Polymod.blacklistImport('compat.blocked.BlockedBase');
    LegacyCoreScripts.registerDependencies();
    var classes = PolymodScriptClass.listScriptClasses();
    require(classes.contains('compat.current.CurrentBase') && !classes.contains('compat.unused.UnusedBase'),
      'only referenced shadowed core modules are retained');
    require(!classes.contains('compat.modern.ModernBase') && !classes.contains('compat.blocked.BlockedBase'),
      'current API overrides and import blacklists do not acquire fallback core definitions');
    var handler = polymod.Polymod.onError;
    var errors:Array<polymod.Polymod.PolymodError> = [];
    polymod.Polymod.onError = error -> errors.push(error);
    Interp.validateImports();
    polymod.Polymod.onError = handler;
    require(errors.exists(error -> error.message.indexOf('compat.modern.ModernBase') >= 0)
      && errors.exists(error -> error.message.indexOf('compat.blocked.BlockedBase') >= 0),
      'unavailable modern and blocked imports retain their normal diagnostics');
    polymod.Polymod.removeImportAlias('compat.blocked.BlockedBase');
    var consumer = funkin.modding.base.Object.scriptInit('CoreConsumer');
    require(consumer != null && consumer.scriptCall('value', []) == 119,
      'retained core inheritance and enums execute while authored helper definitions keep priority');
    var metadata:funkin.data.song.SongData.SongMetadata = consumer.scriptCall('currentMetadata', []);
    require(metadata.charter == 'Core charter' && metadata.variation == 'default',
      'retained core expressions keep current constructor semantics instead of the overriding mod policy');
    var entries = LegacyCoreScripts.entryClasses(classes);
    require(!entries.contains('compat.current.CurrentBase') && entries.contains('CoreConsumer') && entries.contains('OldCoreReplacement')
      && entries.contains('compat.current.Provided'), 'dependency-only classes stay available for inheritance without entering registry discovery');
  }
}
#end
