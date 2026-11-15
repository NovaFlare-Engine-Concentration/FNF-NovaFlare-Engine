package originfunkin.compat;

#if (sys && FEATURE_DEBUG_FUNCTIONS)
import polymod.hscript._internal.PolymodScriptClass;
using Lambda;

@:access(polymod.Polymod)
@:access(polymod.hscript._internal.Interp)
@:access(polymod.hscript._internal.PolymodScriptClass)
class ArgumentScopeChecks
{
  static function require(value:Bool, message:String):Void
  {
    if (!value) throw 'Argument scope check failed: $message';
    trace('[Origin argument scope check] PASS $message');
  }

  static function clean(instance:funkin.modding.base.Object, api:String):Void
  {
    var proxy:PolymodScriptClass = cast Reflect.field(instance, '_asc');
    require(proxy != null && !proxy._interp.variables.exists('event') && !proxy._interp.variables.exists('first')
      && proxy._interp.originArgumentNames == null && proxy._interp.currentFunction == null,
      'API $api argument values and execution context are released after calls');
    var parent:PolymodScriptClass = cast proxy.superClass;
    require(parent != null && !parent._interp.variables.exists('parentArgument') && parent._interp.originArgumentNames == null,
      'API $api inherited method parameter scopes are released');
  }

  public static function run():Void
  {
    var handler = polymod.Polymod.onError;
    var errors:Array<polymod.Polymod.PolymodError> = [];
    polymod.Polymod.onError = error -> errors.push(error);
    for (api in ['0.1.0', '0.5.0', '0.7.0', '0.8.0', '0.8.1', '0.8.2', '0.8.8', '0.9.0'])
    {
      var name = 'ArgumentScope' + api.split('.').join('_');
      var early = !['0.8.2', '0.8.8', '0.9.0'].contains(api);
      var path = 'assets/scripts/$name.hxc';
      PolymodScriptClass.registerScriptClassByString(polymod.Polymod.assetLibrary.getText(path), path);
      var instance = funkin.modding.base.Object.scriptInit(name);
      var other = funkin.modding.base.Object.scriptInit(name);
      require(instance != null && other != null, 'API $api argument probe constructs');
      errors.resize(0);
      var outer = instance.scriptCall('outer', [{note:{kind:'weekend-1-lightcan'}}]);
      if (api == '0.9.0')
      {
        require(errors.length > 0 && outer == null, 'current API methods keep independent parameter locals');
        var counter:Dynamic = instance.scriptCall('makeCounter', [10]);
        require(Reflect.callMethod(null, counter, []) == 11 && Reflect.callMethod(null, counter, []) == 12,
          'current API callbacks retain mutable local references');
      }
      else
      {
        require(outer == 'weekend-1-lightcan' && errors.length == 0, 'API $api nested methods read the caller argument');
        var nested:Array<Dynamic> = instance.scriptCall('nested', ['outer']);
        require(nested != null && nested.join(',') == 'outer,inner,outer', 'API $api nested same-name parameters restore the caller value');
        require(instance.scriptCall('reassign', [1]) == 42, 'API $api reassigned arguments are visible to nested methods');
        var local:Array<Dynamic> = instance.scriptCall('local', ['argument']);
        require(local != null && local.join(',') == 'local,argument', 'API $api ordinary locals remain separate from shared parameters');
        var defaults:Array<Dynamic> = instance.scriptCall('defaults', [9]);
        require(defaults != null && defaults.join(',') == '9,9,9', 'API $api defaults can read earlier shared parameters');
        var nullDefault:Array<Dynamic> = instance.scriptCall('defaults', [9, null]);
        require(nullDefault != null && nullDefault[0] == 9 && nullDefault[1] == (early ? null : 9) && nullDefault[2] == 9,
          'API $api explicit null and absent default arguments retain their distinct historical meanings');
        var inherited:Array<Dynamic> = instance.scriptCall('inherited', ['outer']);
        require(inherited != null && inherited.join(',') == 'outer,parent', 'API $api inherited methods preserve separate caller and parent parameters');
        require(instance.scriptCall('caught', ['outer']) == 'outer', 'API $api nested throw restores the caller parameter');
        var fn:Dynamic = instance.scriptCall('make', ['saved']);
        require(Reflect.callMethod(null, fn, []) == 'saved' && Reflect.callMethod(null, fn, []) == 'saved',
          'API $api callbacks restore removed parameters on repeated calls');
        var nestedFn:Dynamic = instance.scriptCall('makeNested', ['nested saved']);
        require(Reflect.callMethod(null, nestedFn, []) == 'nested saved', 'API $api callback parameters remain visible to nested methods');
        var counter:Dynamic = instance.scriptCall('makeCounter', [10]);
        require(Reflect.callMethod(null, counter, []) == 11 && Reflect.callMethod(null, counter, []) == 11,
          'API $api parameter callback snapshots retain historical restore semantics');
        var otherFn:Dynamic = other.scriptCall('make', ['other']);
        require(Reflect.callMethod(null, fn, []) == 'saved' && Reflect.callMethod(null, otherFn, []) == 'other',
          'API $api callbacks keep separate instance argument snapshots');
        var staticFn:Dynamic = PolymodScriptClass.scriptInterp.getScriptClassStaticField(name, 'staticOuter');
        require(Reflect.callMethod(null, staticFn, [23]) == 23 && !PolymodScriptClass.scriptInterp.variables.exists('staticArgument'),
          'API $api static nested parameters restore the root interpreter');
        errors.resize(0);
        var member = instance.scriptCall('member', [5]);
        require(!early ? errors.length > 0 : member == 5 && errors.length == 0,
          'API $api explicit parameter member reads respect the historical member boundary');
        if (early)
        {
          var previous = PolymodScriptClass.blacklistedScriptClassInstanceFields.get(name);
          PolymodScriptClass.blacklistedScriptClassInstanceFields.set(name, ['event']);
          errors.resize(0);
          instance.scriptCall('member', [5]);
          if (previous == null) PolymodScriptClass.blacklistedScriptClassInstanceFields.remove(name);
          else PolymodScriptClass.blacklistedScriptClassInstanceFields.set(name, previous);
          require(errors.exists(error -> error.message.toLowerCase().indexOf('blacklisted') >= 0),
            'API $api temporary argument members still respect field blacklists');
        }
      }
      var shadow:Array<Dynamic> = instance.scriptCall('shadow', [10]);
      require(shadow != null && shadow.join(',') == (api == '0.9.0' ? '13,7' : '13,13')
        && instance.scriptCall('readValue', []) == 7, 'API $api shadowed instance fields are restored');
      require(instance.scriptCall('shadowNull', [9]) == 9 && instance.scriptCall('readNull', []) == null,
        'API $api previously present null fields are restored');
      require(instance.scriptCall('recursive', [4]) == 10, 'API $api recursive parameters restore each call depth');
      if (api != '0.9.0')
      {
        errors.resize(0);
        var invalidDefault = instance.scriptCall('badDefault', [100]);
        require(invalidDefault == null && errors.length > 0 && instance.scriptCall('readValue', []) == 7,
          'API $api default expression failures restore partially bound arguments');
        errors.resize(0);
        var missing:Array<Dynamic> = instance.scriptCall('missing', [1]);
        if (early)
        {
          require(missing != null && missing.length == 2 && missing[0] == 1 && missing[1] == null && errors.length == 0,
            'API $api early method calls fill missing required parameters with null');
          var absent:Array<Dynamic> = instance.scriptCall('allMissing', []);
          require(absent != null && absent.length == 2 && absent[0] == null && absent[1] == null,
            'API $api zero-argument calls preserve early null binding');
        }
        else require(errors.length > 0, 'API $api later method argument validation remains visible');
        require(instance.scriptCall('extras', [1, 2]) == 1, 'API $api extra method arguments keep upstream acceptance');
        clean(instance, api);
        clean(other, api);
        errors.resize(0);
        instance.scriptCall('outside', []);
        require(errors.length > 0, 'API $api caller parameters do not become permanent globals');
      }
    }
    polymod.Polymod.onError = handler;
  }
}
#end
