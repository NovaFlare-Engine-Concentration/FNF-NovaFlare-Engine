package states.loadingState.backend;

import luahscript.LuaParser;
import luahscript.exprs.LuaExpr;
import luahscript.exprs.LuaToken;

@:access(luahscript.LuaParser)
class LuaPreloadParser extends LuaParser
{
	override function parseExpr(?getValue:Bool = false):LuaExpr
	{
		if (getValue) return super.parseExpr(true);
		var first = token();
		var anonymousFunction = false;
		if (first.match(TId('function')))
		{
			var following = token();
			anonymousFunction = following == TPOpen;
			push(following);
		}
		push(first);
		// Only anonymous functions continue as operands. Named functions are statements.
		return super.parseExpr(anonymousFunction);
	}

	override function parseIdent(id:String):LuaExpr
	{
		if (id != 'return') return super.parseIdent(id);
		var following = token();
		push(following);
		return switch (following)
		{
			case TEof, TSemicolon, TId('end' | 'until' | 'else' | 'elseif'): mk(EReturn(null));
			default: mk(EReturn(parseExpr(true)));
		};
	}
}
