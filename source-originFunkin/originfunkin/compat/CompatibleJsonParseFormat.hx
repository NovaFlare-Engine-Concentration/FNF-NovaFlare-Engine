package originfunkin.compat;

import polymod.format.ParseRules.JSONParseFormat;

/** Keep a broken mod patch from preventing an otherwise valid asset from loading. */
class CompatibleJsonParseFormat extends JSONParseFormat
{
  override public function merge(baseText:String, mergeText:String, id:String):String
  {
    // Invalid base assets must still report their original error.
    parse(baseText);
    var patch = mergeText;
    try
    {
      parse(patch);
    }
    catch (_:Dynamic)
    {
      patch = removeTrailingCommas(patch);
      try
      {
        parse(patch);
        trace('[Origin compatibility] Removed trailing commas from JSON patch: $id');
      }
      catch (error:Dynamic)
      {
        trace('[Origin compatibility] Skipped invalid JSON patch for $id: $error');
        return baseText;
      }
    }
    try
    {
      return super.merge(baseText, patch, id);
    }
    catch (error:Dynamic)
    {
      trace('[Origin compatibility] Skipped failed JSON patch for $id: $error');
      return baseText;
    }
  }

  /** Remove only commas before a closing bracket outside JSON strings. */
  static function removeTrailingCommas(value:String):String
  {
    var output = new StringBuf();
    var insideString = false;
    var escaped = false;
    for (i in 0...value.length)
    {
      var char = value.charAt(i);
      if (insideString)
      {
        output.add(char);
        if (escaped) escaped = false;
        else if (char == '\\') escaped = true;
        else if (char == '"') insideString = false;
        continue;
      }
      if (char == '"')
      {
        insideString = true;
        output.add(char);
        continue;
      }
      if (char == ',')
      {
        var next = i + 1;
        while (next < value.length && ' \t\r\n'.indexOf(value.charAt(next)) >= 0) next++;
        if (next < value.length && (value.charAt(next) == ']' || value.charAt(next) == '}')) continue;
      }
      output.add(char);
    }
    return output.toString();
  }
}