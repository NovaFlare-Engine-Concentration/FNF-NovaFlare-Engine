package codename.funkin.backend.scripting;

/** Narrow syntax compatibility for legacy mod scripts, without rewriting their files. */
class LegacySyntaxCompat {
  static inline function isIdentifierStart(c:Int):Bool
    return (c >= 65 && c <= 90) || (c >= 97 && c <= 122) || c == 95 || c == 36;

  static inline function isIdentifierPart(c:Int):Bool
    return isIdentifierStart(c) || (c >= 48 && c <= 57);

  static inline function isSpace(c:Int):Bool
    return c == 32 || c == 9 || c == 10 || c == 13;

  /** Add Dynamic only to bare catch identifiers outside strings, comments and regex literals. */
  public static function normalizeUntypedCatch(code:String):String {
    if (code == null || code.indexOf('catch') < 0) return code;
    var output = new StringBuf();
    var length = code.length;
    var segment = 0;
    var i = 0;
    while (i < length) {
      var c = code.charCodeAt(i);
      var next = i + 1 < length ? code.charCodeAt(i + 1) : -1;
      if (c == 34 || c == 39) {
        var quote = c;
        i++;
        while (i < length) {
          var ch = code.charCodeAt(i++);
          if (ch == 92 && i < length) i++;
          else if (ch == quote) break;
        }
        continue;
      }
      if (c == 47 && next == 47) {
        i += 2;
        while (i < length && code.charCodeAt(i) != 10) i++;
        continue;
      }
      if (c == 47 && next == 42) {
        i += 2;
        while (i < length) {
          if (code.charCodeAt(i) == 42 && i + 1 < length && code.charCodeAt(i + 1) == 47) { i += 2; break; }
          i++;
        }
        continue;
      }
      if (c == 126 && next == 47) {
        i += 2;
        var inClass = false;
        while (i < length) {
          var ch = code.charCodeAt(i++);
          if (ch == 92 && i < length) i++;
          else if (ch == 91) inClass = true;
          else if (ch == 93) inClass = false;
          else if (ch == 47 && !inClass) break;
        }
        while (i < length && isIdentifierPart(code.charCodeAt(i))) i++;
        continue;
      }
      if (isIdentifierStart(c)) {
        var start = i++;
        while (i < length && isIdentifierPart(code.charCodeAt(i))) i++;
        if (code.substr(start, i - start) != 'catch') continue;
        var previous = start - 1;
        while (previous >= 0 && isSpace(code.charCodeAt(previous))) previous--;
        if (previous >= 0 && code.charCodeAt(previous) == 46) continue;
        var j = i;
        while (j < length && isSpace(code.charCodeAt(j))) j++;
        if (j >= length || code.charCodeAt(j++) != 40) continue;
        while (j < length && isSpace(code.charCodeAt(j))) j++;
        if (j >= length || !isIdentifierStart(code.charCodeAt(j))) continue;
        j++;
        while (j < length && isIdentifierPart(code.charCodeAt(j))) j++;
        var insertAt = j;
        while (j < length && isSpace(code.charCodeAt(j))) j++;
        if (j >= length || code.charCodeAt(j) != 41) continue;
        output.addSub(code, segment, insertAt - segment);
        output.add(':Dynamic');
        segment = insertAt;
        continue;
      }
      i++;
    }
    output.addSub(code, segment, length - segment);
    return output.toString();
  }
}
