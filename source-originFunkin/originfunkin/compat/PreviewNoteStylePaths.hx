package originfunkin.compat;

import funkin.assets.Paths;
import funkin.play.Countdown.CountdownStep;
import funkin.play.notes.NoteDirection;
import funkin.play.notes.notestyle.NoteStyle;
import funkin.util.Constants;
import polymod.hscript.PolymodScriptBridge;

/** Reproduce preview path dispatch without changing the historical native String API. */
@:access(funkin.play.notes.notestyle.NoteStyle)
@:nullSafety(Off)
class PreviewNoteStylePaths
{
  public static final UNHANDLED:Dynamic = {};

  public static function resolve(style:Null<NoteStyle>, method:String, args:Array<Dynamic>, skipOverride:Bool = false):Dynamic
  {
    if (style == null) return null;
    if (!skipOverride)
    {
      var script = PolymodScriptBridge.findOverride(style._asc, style._skipAscFrom, method);
      if (script != null)
      {
        var value:Dynamic = PolymodScriptBridge.callOn(script, method, args);
        return Std.isOfType(value, String) ? fromRaw(method, cast value) : value;
      }
    }
    if (Type.getClass(style) != NoteStyle)
    {
      var fn:Dynamic = Reflect.field(style, method);
      if (fn == null || !Reflect.isFunction(fn)) return UNHANDLED;
      var rawArgs:Array<Dynamic> = switch (method)
      {
        case 'getNoteAssetPath' | 'getHoldNoteAssetPath' | 'getStrumlineAssetPath' | 'getSplashAssetPath': [true];
        case 'buildCountdownSpritePath': [args[0]];
        default: [args[0], true];
      };
      var nativeValue:Dynamic = Reflect.callMethod(style, fn, rawArgs);
      if (method == 'buildCountdownSpritePath' && Std.isOfType(nativeValue, String))
        return countdownFromNative(style, args, cast nativeValue);
      return Std.isOfType(nativeValue, String) ? fromRaw(method, cast nativeValue) : nativeValue;
    }
    var field:Null<String> = switch (method)
    {
      case 'getNoteAssetPath': 'note';
      case 'getHoldNoteAssetPath': 'holdNote';
      case 'getStrumlineAssetPath': 'noteStrumline';
      case 'getSplashAssetPath': 'noteSplash';
      case 'buildJudgementSpritePath':
        switch (cast(args[0], String)) { case 'sick': 'judgementSick'; case 'good': 'judgementGood'; case 'bad': 'judgementBad'; case 'shit': 'judgementShit'; default: null; }
      case 'buildComboNumSpritePath':
        var digit:Int = cast args[0]; digit >= 0 && digit <= 9 ? 'comboNumber$digit' : null;
      case 'buildCountdownSpritePath' | 'getCountdownSoundPath':
        switch (cast(args[0], CountdownStep)) { case THREE: 'countdownThree'; case TWO: 'countdownTwo'; case ONE: 'countdownOne'; case GO: 'countdownGo'; default: null; }
      case 'getHoldCoverDirectionAssetPath' | 'getHoldCoverRootAssetPath': 'holdNoteCover';
      default: throw 'Unsupported preview NoteStyle path method: $method';
    };
    var assets:Dynamic = style._data?.assets;
    var item:Dynamic = assets == null || field == null ? null : Reflect.field(assets, field);
    var raw:Null<String> = null;
    if (item != null)
    {
      if (method == 'getCountdownSoundPath') raw = item.data == null ? null : item.data.audioPath;
      else if (method == 'getHoldCoverDirectionAssetPath')
      {
        var key = switch (cast(args[0], NoteDirection)) { case LEFT: 'left'; case DOWN: 'down'; case UP: 'up'; case RIGHT: 'right'; };
        var direction:Dynamic = item.data == null ? null : Reflect.field(item.data, key);
        raw = direction == null ? null : direction.assetPath;
      }
      else raw = item.assetPath;
    }
    if (raw != null) return fromRaw(method, raw);
    if (method == 'getHoldCoverDirectionAssetPath') return resolve(style, 'getHoldCoverRootAssetPath', args);
    var parentArgs:Array<Dynamic> = switch (method)
    {
      case 'getNoteAssetPath' | 'getHoldNoteAssetPath' | 'getStrumlineAssetPath' | 'getSplashAssetPath': [];
      default: args;
    };
    return resolve(style.fallback, method, parentArgs);
  }

  /** Restore the inherited library only when the native result matches its data path. */
  public static function countdownFromNative(style:NoteStyle, args:Array<Dynamic>, value:String):Dynamic
  {
    var raw:Null<String> = style.resolvePreviewRawPath('buildCountdownSpritePath', args);
    var parts:Array<String> = raw == null ? [] : raw.split(Constants.LIBRARY_SEPARATOR);
    var inherited:Null<String> = parts.length == 0 ? null : (parts.length == 1 ? parts[0] : parts[1]);
    return fromRaw('buildCountdownSpritePath', inherited == value && raw != null ? raw : value);
  }

  static function fromRaw(method:String, raw:String):Dynamic
  {
    var parts = haxe.io.Path.withoutExtension(raw).split(Constants.LIBRARY_SEPARATOR);
    var library:Null<String> = parts.length == 2 ? parts[0] : null;
    var file = parts.length == 2 ? parts[1] : parts.join(Constants.LIBRARY_SEPARATOR);
    var path = Paths.file(file, method == 'getCountdownSoundPath' ? Constants.EXT_SOUND : 'png', false, library);
    return path.exists() ? path : null;
  }
}
