package scripts.hscript;

#if (LUA_ALLOWED && HSCRIPT_ALLOWED && hscriptPos)
private typedef LuaLongLiteral =
{
	final value:String;
	final tail:String;
	final skippedInitialLines:Int;
}

class LuaHScriptErrorLocation
{
	static final longLiteralCall = ~/^[ \t]*(?:(?:local[ \t]+)?[a-zA-Z_]\w*[ \t]*=[ \t]*)?runHaxeCode[ \t]*\([ \t]*\[(=*)\[/;
	static final literalConcat = ~/^[ \t]*\.\.[ \t]*[a-zA-Z_]\w*[ \t]*\.\.[ \t]*\[(=*)\[/;
	static final callEnd = ~/^[ \t]*\)[ \t]*;?[ \t]*(?:\n|$)/;

	public static function originalOffset(raw:String, prepared:String, offset:Int, syntaxFix:EReg):Null<Int>
	{
		if (raw == null || prepared == null || offset < 0 || offset > prepared.length) return null;
		if (raw == prepared) return offset;

		var read = 0;
		var lengthChange = 0;
		while (syntaxFix.matchSub(raw, read))
		{
			var match = syntaxFix.matchedPos();
			var relative = offset - match.pos - lengthChange;
			if (relative < 0) break;
			var name = syntaxFix.matched(2);
			var type = syntaxFix.matched(3);
			var annotation = 'var '.length + name.length + ':'.length;
			var constructor = annotation + type.length + ' = new '.length;
			var replacementLength = constructor + type.length;
			if (relative < replacementLength)
			{
				// fixSyntax duplicates the constructor name as a type annotation.
				var typeOffset = match.pos + match.len - type.length;
				if (relative >= constructor) return typeOffset + relative - constructor;
				if (relative >= annotation) return typeOffset + Std.int(Math.min(relative - annotation, type.length));
				var prefix = syntaxFix.matched(1);
				return relative < 'var '.length ? match.pos : match.pos + (prefix == null ? 0 : prefix.length) + relative - 'var '.length;
			}
			lengthChange += replacementLength - match.len;
			read = match.pos + match.len;
		}
		return offset - lengthChange;
	}

	public static function lineAt(source:String, offset:Int):Int
	{
		return normalizeLines(source.substr(0, offset)).split('\n').length;
	}

	public static function literalSourceLine(file:String, callLine:Int, raw:String, offset:Int):Null<Int>
	{
		#if sys
		if (callLine <= 0) return null;
		try
		{
			var source = normalizeLines(sys.io.File.getContent(file));
			var sourceLines = source.split('\n');
			if (callLine > sourceLines.length || !longLiteralCall.match(sourceLines[callLine - 1])) return null;
			var body = sourceLines.slice(callLine - 1).join('\n').substr(longLiteralCall.matchedPos().len);
			var first = readLongLiteral(body, longLiteralCall.matched(1));
			if (first == null || offset >= first.value.length || !matchesLiteralCall(first, raw)) return null;
			return callLine + first.skippedInitialLines + lineAt(first.value, offset) - 1;
		}
		catch (_:haxe.Exception) {}
		#end
		return null;
	}

	static function matchesLiteralCall(first:LuaLongLiteral, raw:String):Bool
	{
		if (callEnd.match(first.tail)) return raw == first.value;
		if (!literalConcat.match(first.tail) || !StringTools.startsWith(raw, first.value)) return false;
		var last = readLongLiteral(first.tail.substr(literalConcat.matchedPos().len), literalConcat.matched(1));
		return last != null && callEnd.match(last.tail) && raw.length >= first.value.length + last.value.length
			&& StringTools.endsWith(raw, last.value);
	}

	static function readLongLiteral(body:String, equals:String):Null<LuaLongLiteral>
	{
		var delimiter = ']' + equals + ']';
		var close = body.indexOf(delimiter);
		if (close < 0) return null;
		// Lua discards one newline immediately following a long-string opener.
		var start = StringTools.startsWith(body, '\n') ? 1 : 0;
		return {value: body.substring(start, close), tail: body.substr(close + delimiter.length), skippedInitialLines: start};
	}

	static function normalizeLines(source:String):String
	{
		return ~/\r\n|\n\r|\r/g.replace(source, '\n');
	}
}
#end
