package llua;

#if !cpp
#error 'LuaJIT supports only C++ target platforms.'
#end
import hxluajit.Types;

#if scriptable
typedef LuaCallback = LuaCallback_internal;
@:hscriptBaseCreated
private class LuaCallback_internal {
#else
class LuaCallback {
#end
	private final L:cpp.RawPointer<Lua_State>;

	public var ref(default, null):Int;

	public function new(lua:cpp.Pointer<Lua_State>, ref:Int) {
		this.L = lua.raw;
		this.ref = ref;
	}

	public function call(args:Array<Dynamic> = null) {
		Lua.rawgeti(L, Lua.LUA_REGISTRYINDEX, this.ref);
		if (Lua.isfunction(L, -1)) {
			if (args == null)
				args = [];
			for (arg in args)
				Convert.toLua(L, arg);
			var status:Int = Lua.pcall(L, args.length, 0, 0);
			if (status != Lua.LUA_OK) {
				var err:String = Lua.tostring(L, -1);
				Lua.pop(L, 1);
				if (err == null || err == "") {
					switch (status) {
						case Lua.LUA_ERRRUN:
							err = "Runtime Error";
						case Lua.LUA_ERRMEM:
							err = "Memory Allocation Error";
						case Lua.LUA_ERRERR:
							err = "Critical Error";
						default:
							err = "Unknown Error";
					}
				}
				Sys.println("Error on callback: " + err);
			}
		}
	}

	public function dispose()
		LuaL.unref(L, Lua.LUA_REGISTRYINDEX, ref);
}
