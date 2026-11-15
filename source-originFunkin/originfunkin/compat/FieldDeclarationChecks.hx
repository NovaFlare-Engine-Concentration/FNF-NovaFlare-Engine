package originfunkin.compat;

#if (sys && FEATURE_DEBUG_FUNCTIONS)
import polymod.hscript._internal.PolymodScriptClass;
using Lambda;

@:access(polymod.hscript._internal.PolymodScriptClass)
@:access(polymod.Polymod)
class FieldDeclarationChecks
{
  public static function run():Void
  {
    for (api in ['0.1.0', '0.5.0', '0.6.3', '0.7.0', '0.7.2', '0.8.8', '0.9.0'])
    {
      var name = 'RepeatedFields' + api.split('.').join('_');
      var path = 'assets/scripts/$name.hxc';
      var allowed = ['0.1.0', '0.5.0', '0.6.3', '0.7.0'].contains(api);
      PolymodScriptClass.registerScriptClassByString(polymod.Polymod.assetLibrary.getText(path), path);
      var handler = polymod.Polymod.onError;
      var errors:Array<polymod.Polymod.PolymodError> = [];
      polymod.Polymod.onError = error -> errors.push(error);
      var instance = funkin.modding.base.Object.scriptInit(name);
      polymod.Polymod.onError = handler;
      if (allowed)
      {
        var result:Array<Dynamic> = instance?.scriptCall('probe', []);
        if (errors.length != 0 || result == null || result.join(',') != '12,2,5,2')
          throw 'Repeated fields API $api lost declaration order/initializers: $result, ${errors.map(error -> error.message)}';
        trace('[Origin field declaration check] PASS API $api preserves repeated fields and initializer order');
      }
      else
      {
        if (!errors.exists(error -> error.message.indexOf('Duplicate field name') >= 0))
          throw 'Repeated fields API $api lost its current duplicate-field diagnostic';
        trace('[Origin field declaration check] PASS API $api retains duplicate-field diagnostics');
      }
    }
  }
}
#end
