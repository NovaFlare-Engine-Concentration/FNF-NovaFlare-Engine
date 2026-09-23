#if LUA_ALLOWED
package scripts.lua;

class CallbackHandler
{
	/** 同一回调名连续出错的计数，用于熔断，避免每帧刷屏。 */
	static var errorCounts:Map<String, Int> = new Map<String, Int>();

	/** 达到该次数后停止逐条提示（错误仍然会让本次调用失效）。 */
	static final ERROR_FUSE_LIMIT:Int = 8;

	public static inline function call(l:State, fname:String):Int
	{
		try
		{
			// trace('calling $fname');
			var cbf:Dynamic = Lua_helper.callbacks.get(fname);

			// Local functions have the lowest priority
			// This is to prevent a "for" loop being called in every single operation,
			// so that it only loops on reserved/special functions
			if (cbf == null)
			{
				// trace('checking last script');
				var last:FunkinLua = FunkinLua.lastCalledScript;
				if (last == null || last.lua != l)
				{
					// trace('looping thru scripts');
					for (script in PlayState.instance.luaArray)
						if (script != FunkinLua.lastCalledScript && script != null && script.lua == l)
						{
							// trace('found script');
							cbf = script.callbacks.get(fname);
							break;
						}
				}
				else
					cbf = last.callbacks.get(fname);
			}

			if (cbf == null)
				return 0;

			var nparams:Int = Lua.gettop(l);
			var args:Array<Dynamic> = [];

			for (i in 0...nparams)
			{
				args[i] = Convert.fromLua(l, i + 1);
			}

			var ret:Dynamic = null;
			/* return the number of results */

			ret = Reflect.callMethod(null, cbf, args);

			if (ret != null)
			{
				Convert.toLua(l, ret);
				return 1;
			}
		}
		catch (e:Dynamic)
		{
			// 关键：绝不能把 Haxe 异常重新抛回 LuaJIT。
			// 调用链是  LuaJIT -> linc_lua.cpp 的 luaCallback()（该 C 帧没有 try/catch）
			// -> CallbackHandler.call()。LuaJIT 用 longjmp 传播错误、不认 C++ 异常，
			// 让 hxcpp 异常穿过这段 C 栈是未定义行为（实测常见后果是直接终止进程）。
			// 旧实现这里写的是 `throw(e)`，等于"mod 脚本随便报个错就整局闪退"。
			// 现在只记录并返回 0：让出错的那一次调用失效，游戏继续跑。
			reportError(fname, e);
			return 0;
		}
		return 0;
	}

	static function reportError(fname:String, e:Dynamic):Void
	{
		var n:Int = (errorCounts.exists(fname) ? errorCounts.get(fname) : 0) + 1;
		errorCounts.set(fname, n);

		// 熔断：同一回调反复出错只提示前几次，避免每帧 trace + 每帧弹调试文本拖垮帧率。
		if (n > ERROR_FUSE_LIMIT)
			return;

		var msg:String = 'Lua 回调出错 [$fname]: ' + Std.string(e)
			+ (n == ERROR_FUSE_LIMIT ? '（该回调已连续出错 $n 次，后续同类错误不再逐条提示）' : '');
		trace(msg);

		try
		{
			var game:PlayState = PlayState.instance;
			if (game != null)
				// 走报错专用通道：受「维护设置 › Lua 语法错误提示」控制（关闭时只写日志、不上屏）
				game.addScriptErrorToDebug(msg);
		}
		catch (_:Dynamic) {}
	}
}
#end
