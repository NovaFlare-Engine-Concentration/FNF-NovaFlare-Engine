package originfunkin.compat;

/** Narrow, in-memory repairs for common malformed Polymod metadata. */
class LegacyMetadataCompat
{
  public static function normalize(raw:Null<String>):Null<String>
  {
    if (raw == null || raw == '') return raw;
    var candidate = raw;
    var parsed:Dynamic = null;
    var changed = false;
    try
    {
      parsed = haxe.Json.parse(candidate);
    }
    catch (_:Dynamic)
    {
      candidate = withoutTrailingCommas(raw);
      if (candidate == raw) return raw;
      try parsed = haxe.Json.parse(candidate) catch (_:Dynamic) return raw;
      changed = true;
    }
    if (parsed == null || !Reflect.isObject(parsed) || Std.isOfType(parsed, Array)) return raw;
    var version:Dynamic = Reflect.field(parsed, 'mod_version');
    if (Std.isOfType(version, String))
    {
      var suffix = ~/^(\d+\.\d+\.\d+)\(([A-Za-z0-9][A-Za-z0-9.-]*)\)$/;
      if (suffix.match(cast version))
      {
        Reflect.setField(parsed, 'mod_version', suffix.matched(1) + '-' + suffix.matched(2));
        changed = true;
      }
    }
    return changed ? haxe.Json.stringify(parsed) : raw;
  }

  static function withoutTrailingCommas(raw:String):String
  {
    var result = new StringBuf();
    var insideString = false;
    var escaped = false;
    var i = 0;
    while (i < raw.length)
    {
      var ch = raw.charAt(i);
      if (insideString)
      {
        result.add(ch);
        if (escaped) escaped = false;
        else if (ch == String.fromCharCode(92)) escaped = true;
        else if (ch == '"') insideString = false;
      }
      else if (ch == '"')
      {
        insideString = true;
        result.add(ch);
      }
      else if (ch == ',')
      {
        var next = i + 1;
        while (next < raw.length && ' \t\r\n'.indexOf(raw.charAt(next)) >= 0) next++;
        if (next >= raw.length || (raw.charAt(next) != ']' && raw.charAt(next) != '}')) result.add(ch);
      }
      else result.add(ch);
      i++;
    }
    return result.toString();
  }
}
