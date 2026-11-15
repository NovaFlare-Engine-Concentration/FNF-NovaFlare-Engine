package originfunkin.compat;

#if (sys && FEATURE_DEBUG_FUNCTIONS)
import polymod.hscript._internal.PolymodScriptClass;
using Lambda;

@:access(polymod.Polymod)
@:access(polymod.hscript._internal.PolymodScriptClass)
class ImplicitVariableChecks
{
  static function require(value:Bool, message:String):Void
  {
    if (!value) throw 'Implicit variable check failed: $message';
    trace('[Origin implicit variable check] PASS $message');
  }

  public static function run():Void
  {
    var handler = polymod.Polymod.onError;
    var errors:Array<polymod.Polymod.PolymodError> = [];
    polymod.Polymod.onError = error -> errors.push(error);
    for (api in ['0.1.0', '0.5.0', '0.6.3', '0.7.0', '0.7.2', '0.8.0', '0.8.1', '0.8.2', '0.8.8', '0.9.0'])
    {
      var suffix = api.split('.').join('_');
      var name = 'ImplicitVariables' + suffix;
      var path = 'assets/scripts/$name.hxc';
      PolymodScriptClass.registerScriptClassByString(polymod.Polymod.assetLibrary.getText(path), path);
      var first = funkin.modding.base.Object.scriptInit(name);
      var second = funkin.modding.base.Object.scriptInit(name);
      errors.resize(0);
      first.scriptCall('readBefore', []);
      require(errors.exists(error -> error.message.indexOf('implicitValue') >= 0), 'API $api uninitialized reads still fail');
      errors.resize(0);
      var seeded = first.scriptCall('seed', [10]);
      if (api == '0.9.0')
      {
        require(seeded == null && errors.length > 0, 'current API rejects undeclared assignments');
        continue;
      }
      require(seeded == 10 && errors.length == 0, 'API $api allows historical bare assignment');
      require(second.scriptCall('seed', [20]) == 20 && first.scriptCall('bump', []) == 11
        && second.scriptCall('read', []) == 20, 'API $api interpreter variables are isolated per instance');
      require(first.scriptCall('nullable', []) == null && errors.length == 0, 'API $api assigned null remains present');
      require(first.scriptCall('local', []) == 103 && first.scriptCall('argument', [10]) == 14
        && first.scriptCall('read', []) == 11, 'API $api locals and arguments shadow implicit variables');
      var closure:Dynamic = first.scriptCall('closure', []);
      require(Reflect.callMethod(null, closure, []) == 13 && first.scriptCall('read', []) == 13,
        'API $api closures retain their owning interpreter');
      var early = !['0.8.2', '0.8.8'].contains(api);
      errors.resize(0);
      var member = first.scriptCall('memberRead', []);
      require(early ? member == 13 && errors.length == 0 : errors.length > 0,
        'API $api retains its historical explicit member boundary');
      errors.resize(0);
      first.scriptCall('memberWrite', [31]);
      require(early ? first.scriptCall('read', []) == 31 && errors.length == 0
        : errors.length > 0 && first.scriptCall('read', []) == 13, 'API $api explicit writes follow the same boundary');
      if (early)
      {
        var previous = PolymodScriptClass.blacklistedScriptClassInstanceFields.get(name);
        PolymodScriptClass.blacklistedScriptClassInstanceFields.set(name, ['implicitValue']);
        errors.resize(0);
        first.scriptCall('blockedRead', []);
        first.scriptCall('blockedWrite', []);
        if (previous == null) PolymodScriptClass.blacklistedScriptClassInstanceFields.remove(name);
        else PolymodScriptClass.blacklistedScriptClassInstanceFields.set(name, previous);
        require(errors.filter(error -> error.message.toLowerCase().indexOf('blacklisted') >= 0).length == 2
          && first.scriptCall('read', []) == 31, 'API $api implicit member reads and writes respect blacklists');
      }
      errors.resize(0);
      var child = funkin.modding.base.Object.scriptInit('ImplicitChild' + suffix);
      child.scriptCall('parentSeed', [6]);
      child.scriptCall('childSeed', [9]);
      require(child.scriptCall('parentRead', []) == 6 && child.scriptCall('childRead', []) == 9 && errors.length == 0,
        'API $api implicit variables do not become inherited declarations');
      var seed:Dynamic = PolymodScriptClass.scriptInterp.getScriptClassStaticField(name, 'staticSeed');
      var read:Dynamic = PolymodScriptClass.scriptInterp.getScriptClassStaticField(name, 'staticRead');
      require(Reflect.callMethod(null, seed, []) == 42 && Reflect.callMethod(null, read, []) == 42,
        'API $api historical static assignments persist');
    }
    errors.resize(0);
    polymod.hscript._internal.ScriptPreheater.run();
    for (api in ['0_1_0', '0_8_1', '0_8_2', '0_8_8'])
    {
      var text = errors.map(error -> error.message).join('\n');
      for (name in ['argumentOnly', 'localOnly', 'loopOnly', 'catchOnly', 'nestedOnly', 'neverAssigned'])
        require(text.indexOf('ImplicitScopes$api: unresolved identifier "$name"') >= 0,
          'preheater keeps API $api out-of-scope $name diagnostics');
      require(text.indexOf('ImplicitVariables$api: unresolved identifier "implicitValue"') < 0,
        'preheater recognizes API $api historical variable assignments');
    }
    polymod.Polymod.onError = handler;
  }
}
#end
