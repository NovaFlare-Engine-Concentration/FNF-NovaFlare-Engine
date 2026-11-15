package llua;

#if !cpp
#error 'LuaJIT supports only C++ target platforms.'
#end
import haxe.DynamicAccess;
import llua.Macro.*;
import llua.State;
import llua.Lua;

#if scriptable
typedef Convert = Convert_internal;
@:hscriptBaseCreated
private class Convert_internal {
#else
class Convert {
#end
	public static function toLua(l:State, val:Dynamic):Void {
		switch (Type.typeof(val)) {
			case TNull:
				Lua.pushnil(l);
			case TInt:
				Lua.pushinteger(l, cast(val, Int));
			case TFloat:
				Lua.pushnumber(l, cast(val, Float));
			case TBool:
				Lua.pushboolean(l, val);
			case TClass(Array):
				arrayToLua(l, val);
			case TClass(haxe.ds.ObjectMap) | TClass(haxe.ds.StringMap):
				var map:Map<String, Dynamic> = val;

				Lua.createtable(l, Lambda.count(map), 0);

				for (key => value in map) {
					Lua.pushstring(l, Std.isOfType(key, String) ? key : Std.string(key));
					toLua(l, value);
					Lua.settable(l, -3);
				}
			case TClass(String):
				Lua.pushstring(l, cast(val, String));
			case TObject:
				Lua.createtable(l, Reflect.fields(val).length, 0);

				for (key in Reflect.fields(val)) {
					Lua.pushstring(l, key);
					toLua(l, Reflect.field(val, key));
					Lua.settable(l, -3);
				}
			default:
				Sys.println('Couldn\'t convert "${Type.typeof(val)}" to Lua.');
		}
	}

	public static function fromLua(l:State, idx:Int):Dynamic {
		switch (Lua.type(l, idx)) {
			case type if (type == Lua.LUA_TNIL):
				return null;
			case type if (type == Lua.LUA_TBOOLEAN):
				return Lua.toboolean(l, idx);
			case type if (type == Lua.LUA_TNUMBER):
				return Lua.tonumber(l, idx);
			case type if (type == Lua.LUA_TSTRING):
				return cast(Lua.tostring(l, idx), String);
			case type if (type == Lua.LUA_TTABLE):
				var count = 0;
				var array = true;

				loopTable(l, idx, {
					if (array) {
						if (Lua.type(l, -2) != Lua.LUA_TNUMBER)
							array = false;
						else {
							var index = Lua.tonumber(l, -2);
							if (index < 0 || Std.int(index) != index)
								array = false;
						}
					}
					count++;
				});

				return if (count == 0) {
					{};
				} else if (array) {
					var v = [];
					loopTable(l, idx, {
						var index = Std.int(Lua.tonumber(l, -2)) - 1;
						v[index] = fromLua(l, -1);
					});
					cast v;
				} else {
					var v:DynamicAccess<Any> = {};
					loopTable(l, idx, {
						switch Lua.type(l, -2) {
							case t if (t == Lua.LUA_TSTRING): v.set(cast(Lua.tostring(l, -2), String), fromLua(l, -1));
							case t if (t == Lua.LUA_TNUMBER): v.set(Std.string(Lua.tonumber(l, -2)), fromLua(l, -1));
						}
					});
					cast v;
				}
			case type if (type == Lua.LUA_TFUNCTION):
				return new LuaCallback(cpp.Pointer.fromRaw(l), LuaL.ref(l, Lua.LUA_REGISTRYINDEX));
			default:
				Sys.println('Couldn\'t convert "${cast (Lua.typename(l, idx), String)}" to Haxe.');
		}

		return null;
	}
	
	public static inline function arrayToLua(l:State, arr:Array<Dynamic>)
	{
		Lua.createtable(l, arr.length, 0);

		for (i in 0...arr.length)
		{
			Lua.pushinteger(l, i + 1);
			toLua(l, arr[i]);
			Lua.settable(l, -3);
		}
	}
}
