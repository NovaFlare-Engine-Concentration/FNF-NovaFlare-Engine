package states.loadingState.backend;

import luahscript.LuaTools;
import luahscript.exprs.LuaExpr;

/** Resolves simple resource arguments without running the Lua script. */
class LuaPreloadValues
{
	static final UNKNOWN:Dynamic = {};
	final onCall:(String, Array<Dynamic>) -> Void;
	final eventInputs:Null<Array<Array<String>>>;

	public static function scan(root:LuaExpr, eventInputs:Null<Array<Array<String>>>, onCall:(String, Array<Dynamic>) -> Void):Void
	{
		new LuaPreloadValues(eventInputs, onCall).visit(root, newScope());
	}

	function new(eventInputs:Null<Array<Array<String>>>, onCall:(String, Array<Dynamic>) -> Void)
	{
		this.eventInputs = eventInputs;
		this.onCall = onCall;
	}

	static function newScope(?parent:LuaValueScope):LuaValueScope
	{
		return {values: parent == null ? new Map() : parent.values.copy(), locals: []};
	}

	function visit(expression:LuaExpr, scope:LuaValueScope):Bool
	{
		if (expression == null) return false;
		switch (expression.expr)
		{
			case ETd(statements, true):
				final block:LuaValueScope = newScope(scope);
				final returned = visitStatements(statements, block);
				scope.values = exportedValues(block, scope);
				return returned;
			case ETd(statements, _):
				return visitStatements(statements, scope);
			case EFunction(args, body, info):
				final name = info != null && info.names.length == 1 ? info.names[0] : null;
				visitFunction(args, body, name, scope);
			case ELocal(local):
				switch (local.expr)
				{
					case EBinop('=', targets, values): visitAssignment(targets, values, scope, true);
					case EIdent(name): declareLocal(name, null, scope);
					case EAnd(targets):
						for (target in targets) switch (target.expr)
						{
							case EIdent(name): declareLocal(name, null, scope);
							case _:
						}
					case _: visit(local, scope);
				}
			case EBinop('=', targets, values): visitAssignment(targets, values, scope, false);
			case EIf(condition, body, elseIfs, otherwise):
				final branches:Array<LuaElseIf> = [{cond: condition, body: body}];
				if (elseIfs != null) for (branch in elseIfs) branches.push(branch);
				return visitIf(branches, otherwise, scope);
			case EForNum(name, body, start, end, step):
				visit(start, scope);
				visit(end, scope);
				visit(step, scope);
				visitLoop(body, scope, [name]);
			case EForGen(body, iterator, first, second):
				visit(iterator, scope);
				visitLoop(body, scope, second != null ? [first, second] : [first]);
			case EWhile(condition, body), ERepeat(body, condition):
				visit(condition, scope);
				visitLoop(body, scope, []);
			case ECall(target, params):
				final name = identifier(target);
				if (name != null)
					onCall(name, [for (param in params) {
						final value = getValue(param, scope.values);
						value == UNKNOWN ? null : value;
					}]);
				LuaTools.iter(expression, child -> visit(child, scope));
			case EReturn(result):
				visit(result, scope);
				return true;
			case _:
				LuaTools.iter(expression, child -> visit(child, scope));
		}
		return false;
	}

	function visitStatements(statements:Array<LuaExpr>, scope:LuaValueScope):Bool
	{
		for (statement in statements) if (visit(statement, scope)) return true;
		return false;
	}

	function visitFunction(args:Array<String>, body:LuaExpr, name:Null<String>, scope:LuaValueScope):Void
	{
		if (name == 'onEvent' && eventInputs != null && eventInputs.length > 0)
		{
			for (values in eventInputs)
			{
				final instance = newScope(scope);
				for (index => arg in args)
					instance.values.set(arg, index < values.length ? values[index] : UNKNOWN);
				visit(body, instance);
			}
			return;
		}
		final instance = newScope(scope);
		for (arg in args) instance.values.set(arg, UNKNOWN);
		visit(body, instance);
	}

	function visitAssignment(targets:LuaExpr, values:LuaExpr, scope:LuaValueScope, isLocal:Bool):Void
	{
		final targetList = switch (targets.expr) { case EAnd(items): items; case _: [targets]; };
		final valueList = switch (values.expr) { case EAnd(items): items; case _: [values]; };
		final resolved = [for (value in valueList) getValue(value, scope.values)];
		for (index => value in valueList)
		{
			final targetName = index < targetList.length ? identifier(targetList[index]) : null;
			switch (value.expr)
			{
				case EFunction(args, body, _): visitFunction(args, body, targetName, scope);
				case _: visit(value, scope);
			}
		}
		for (index => target in targetList)
		{
			final name = identifier(target);
			if (name == null)
			{
				visit(target, scope);
				continue;
			}
			final value = index < resolved.length ? resolved[index] : UNKNOWN;
			if (isLocal) declareLocal(name, value, scope);
			else scope.values.set(name, value);
		}
	}

	function visitIf(branches:Array<LuaElseIf>, otherwise:LuaExpr, scope:LuaValueScope):Bool
	{
		final continuations:Array<Map<String, Dynamic>> = [];
		var mayReachElse = true;
		for (branch in branches)
		{
			visit(branch.cond, scope);
			final condition = getValue(branch.cond, scope.values);
			if (condition != UNKNOWN && !isTruthy(condition)) continue;
			addContinuation(continuations, branch.body, scope);
			if (condition != UNKNOWN)
			{
				mayReachElse = false;
				break;
			}
		}
		if (mayReachElse) addContinuation(continuations, otherwise, scope);
		if (continuations.length == 0) return true;
		scope.values = mergeValues(continuations);
		return false;
	}

	function addContinuation(continuations:Array<Map<String, Dynamic>>, body:LuaExpr, scope:LuaValueScope):Void
	{
		final branch = newScope(scope);
		if (!visit(body, branch)) continuations.push(exportedValues(branch, scope));
	}

	function visitLoop(body:LuaExpr, scope:LuaValueScope, iterationVariables:Array<String>):Void
	{
		final loop = newScope(scope);
		for (name in iterationVariables) declareLocal(name, UNKNOWN, loop);
		visit(body, loop);
		scope.values = mergeValues([scope.values, exportedValues(loop, scope)]);
	}

	static function declareLocal(name:String, value:Dynamic, scope:LuaValueScope):Void
	{
		scope.locals.push(name);
		scope.values.set(name, value);
	}

	static function exportedValues(block:LuaValueScope, parent:LuaValueScope):Map<String, Dynamic>
	{
		for (name in block.locals)
		{
			if (parent.values.exists(name)) block.values.set(name, parent.values[name]);
			else block.values.remove(name);
		}
		return block.values;
	}

	static function mergeValues(continuations:Array<Map<String, Dynamic>>):Map<String, Dynamic>
	{
		if (continuations.length == 1) return continuations[0];
		final shared:Map<String, Dynamic> = new Map();
		for (name => value in continuations[0])
		{
			var matches = true;
			for (index in 1...continuations.length)
				if (!continuations[index].exists(name) || continuations[index][name] != value)
				{
					matches = false;
					break;
				}
			if (matches) shared[name] = value;
		}
		return shared;
	}

	static function identifier(expression:LuaExpr):Null<String>
	{
		return switch (expression.expr) {
			case EIdent(name): name;
			case EParent(inner): identifier(inner);
			case _: null;
		};
	}

	static function getValue(expression:LuaExpr, values:Map<String, Dynamic>):Dynamic
	{
		if (expression == null) return UNKNOWN;
		return switch (expression.expr)
		{
			case EConst(CString(value, _)): value;
			case EConst(CInt(value)): value;
			case EConst(CFloat(value)): value;
			case EIdent('nil'): null;
			case EIdent('true'): true;
			case EIdent('false'): false;
			case EIdent(name): values.exists(name) ? values[name] : UNKNOWN;
			case EParent(inner): getValue(inner, values);
			case EPrefix('not', inner):
				final value = getValue(inner, values);
				value == UNKNOWN ? UNKNOWN : !isTruthy(value);
			case EBinop(op, left, right):
				getBinaryValue(op, getValue(left, values), getValue(right, values));
			case ECall(target, params) if (identifier(target) == 'tostring' && !values.exists('tostring')):
				final value = getValue(params[0], values);
				value == UNKNOWN ? UNKNOWN : (value == null ? 'nil' : Std.string(value));
			case _: UNKNOWN;
		};
	}

	static function getBinaryValue(op:String, left:Dynamic, right:Dynamic):Dynamic
	{
		if (left == UNKNOWN) return UNKNOWN;
		if (op == 'and') return isTruthy(left) ? right : left;
		if (op == 'or') return isTruthy(left) ? left : right;
		if (right == UNKNOWN) return UNKNOWN;
		return switch (op)
		{
			case '==': left == right;
			case '~=': left != right;
			case '..' if (canConcatenate(left) && canConcatenate(right)): Std.string(left) + Std.string(right);
			case _: UNKNOWN;
		};
	}

	static inline function isTruthy(value:Dynamic):Bool
	{
		return value != null && value != false;
	}

	static inline function canConcatenate(value:Dynamic):Bool
	{
		return Std.isOfType(value, String) || Std.isOfType(value, Float);
	}
}

private typedef LuaValueScope = {
	var values:Map<String, Dynamic>;
	final locals:Array<String>;
}
