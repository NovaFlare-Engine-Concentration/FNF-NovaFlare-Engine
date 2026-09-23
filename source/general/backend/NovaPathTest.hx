package general.backend;

#if sys
import sys.FileSystem;
import sys.io.File;
#end

#if LUA_ALLOWED
import llua.Lua;
import llua.LuaL;
#end

/**
 * 中文 / 非 ASCII 路径兼容自检。
 *
 * 用途：把「中文路径到底能不能正确加载」从口头结论变成可复现的实测数据。
 * 设环境变量 `NOVAF_PATHTEST=1` 启动游戏，会在 `Main.main()` 最开始（早于
 * lime/openfl 初始化）跑完下面所有用例，并把报告写到工作目录的
 * `nova_pathtest.txt`，同时 trace 到控制台。
 *
 * 覆盖的分层（每一层坏掉的表现都不一样，必须分开测）：
 *   1. 进程 ANSI 代码页（GetACP）—— 验证 windows/NovaFlare.manifest 的
 *      activeCodePage=UTF-8 是否真的生效。65001 = 生效；936 = 清单没进去。
 *   2. hxcpp 的 sys.io.File / sys.FileSystem —— 内部走 _wfopen /
 *      GetFileAttributesW / FindFirstFileW / _wmkdir，理论上是 Unicode 安全的。
 *   3. 绝对路径（FileSystem.fullPath）—— 引擎拼绝对路径时最容易出问题的地方。
 *   4. LuaJIT —— 路径经 Haxe String → cpp.ConstCharStar → CRT 窄字符 fopen。
 *      （★ 注意 `cpp.ConstCharStar` 传的是 String 的内部缓冲区，在 HX_SMART_STRINGS
 *        下非 ASCII 字符串内部是 UTF-16，所以这一层有「编码」和「代码页」两重风险。）
 *   5. 含空格 / 括号 / 超长中文路径。
 *
 * 全程只用到 sys 与 llua，不依赖 lime，因此可以在进程最早期运行。
 *
 * 结果判定全部走「数值 / 布尔」而不是把 Lua 返回的字符串取回来 —— 避免自检自身的
 * 字符串转换又引入一个不确定因素。
 */
#if (cpp && windows)
// GetACP() 需要 windows.h；按本工程既有做法（Native.hx）只放进本类自己的 .cpp，
// 不写进共享头文件，避免 Win32 宏污染其他翻译单元。
// ★ 不要在里面套 `#ifdef NEKO_WINDOWS`：@:cppFileCode 插在 hxcpp.h 之前，
//   那时 NEKO_WINDOWS 还没定义，include 会被整段跳过（GetACP 找不到标识符）。
//   用 Haxe 侧的 `#if (cpp && windows)` 来门控即可。
@:cppFileCode('#include <windows.h>')
#end
class NovaPathTest
{
	public static inline var ENV_FLAG:String = 'NOVAF_PATHTEST';
	public static inline var REPORT_FILE:String = 'nova_pathtest.txt';

	/** 全部用例共用的中文根目录（含空格与括号，一次把三类风险都压进去） */
	static inline var ROOT:String = 'NF路径自检 (测试)';

	static var lines:Array<String> = [];
	static var passed:Int = 0;
	static var failed:Int = 0;

	/** 由 Main.main() 调用：只有设了环境变量才真正执行 */
	public static function runIfRequested():Void
	{
		var flag:String = null;
		try
		{
			flag = Sys.getEnv(ENV_FLAG);
		}
		catch (e:Dynamic)
		{
			return;
		}

		if (flag == null || flag == '' || flag == '0' || flag == 'false')
			return;

		try
		{
			run();
		}
		catch (e:Dynamic)
		{
			// 自检本身绝不能阻断启动
			write('[FATAL]', '自检过程抛出异常，已中止：' + Std.string(e));
			flush();
		}
	}

	// ------------------------------------------------------------------ 用例

	public static function run():Void
	{
		lines = [];
		passed = 0;
		failed = 0;

		head('NovaFlare Engine — 中文 / 非 ASCII 路径兼容自检');
		write('', 'cwd = ' + safeStr(() -> Sys.getCwd()));
		write('', 'exe = ' + safeStr(() -> Sys.programPath()));

		// ---- 1. 进程 ANSI 代码页 ------------------------------------------
		#if (cpp && windows)
		var acp:Int = -1;
		try
		{
			acp = untyped __cpp__('(int)::GetACP()');
		}
		catch (e:Dynamic)
		{
			acp = -1;
		}
		if (acp == 65001)
			ok('进程 ANSI 代码页 = UTF-8 (65001)', 'windows/NovaFlare.manifest 的 activeCodePage 已生效');
		else
			bad('进程 ANSI 代码页 = UTF-8 (65001)', '实测 = ' + acp + (acp == 936 ? '（GBK → exe 里没有 UTF-8 清单）' : '')
				+ '；窄字符 API（LuaJIT 的 fopen、第三方 DLL）拿到的 UTF-8 字节会被当成当前代码页解析');
		#else
		skip('进程 ANSI 代码页 = UTF-8', '非 Windows 目标，不适用');
		#end

		// ---- 2. 目录创建 ---------------------------------------------------
		var baseDir:String = ROOT;
		var subDir:String = baseDir + '/子目录/深层';
		cleanup(baseDir);

		var created:Bool = true;
		for (dir in [baseDir, baseDir + '/子目录', subDir])
		{
			try
			{
				if (!FileSystem.exists(dir))
					FileSystem.createDirectory(dir);
			}
			catch (e:Dynamic)
			{
				created = false;
				bad('创建中文目录 ' + dir, Std.string(e));
				break;
			}
		}
		if (created)
			ok('创建中文目录（多级 + 空格 + 括号）', subDir);
		else
		{
			flush();
			return;
		}

		// ---- 3. 读写往返 ---------------------------------------------------
		var txtPath:String = subDir + '/音符颜色.json';
		var payload:String = '{"中文键":"中文值 with ascii","sym":"\u2714"}';

		var writeOk:Bool = true;
		try
		{
			File.saveContent(txtPath, payload);
		}
		catch (e:Dynamic)
		{
			writeOk = false;
			bad('写入中文路径文本文件 File.saveContent', Std.string(e));
		}
		if (writeOk)
			ok('写入中文路径文本文件 File.saveContent', txtPath);

		if (writeOk)
		{
			var readBack:String = safeStr(() -> File.getContent(txtPath));
			if (readBack == payload)
				ok('读回中文路径文本内容 File.getContent', '逐字节一致（' + payload.length + ' 字符）');
			else
				bad('读回中文路径文本内容 File.getContent',
					readBack == null ? '返回 null' : '内容不一致（读回 ' + readBack.length + ' vs 写入 ' + payload.length + ' 字符）');

			var byteLen:Int = -1;
			try
			{
				var b = File.getBytes(txtPath);
				if (b != null) byteLen = b.length;
			}
			catch (e:Dynamic) {}
			if (byteLen > 0)
				ok('读取中文路径二进制 File.getBytes', byteLen + ' 字节');
			else
				bad('读取中文路径二进制 File.getBytes', '失败或返回空');
		}

		// ---- 4. 存在性 / 类型判断 -------------------------------------------
		if (FileSystem.exists(txtPath))
			ok('FileSystem.exists(中文文件)', 'true');
		else
			bad('FileSystem.exists(中文文件)', 'false —— 文件明明刚写成功');

		var isDir:Bool = false;
		try
		{
			isDir = FileSystem.isDirectory(subDir);
		}
		catch (e:Dynamic) {}
		if (FileSystem.exists(subDir) && isDir)
			ok('FileSystem.isDirectory(中文目录)', 'true');
		else
			bad('FileSystem.isDirectory(中文目录)', 'exists=' + FileSystem.exists(subDir) + ' isDirectory=' + isDir);

		// ---- 5. 目录枚举（模组 / 歌曲扫描全靠它）-----------------------------
		var names:Array<String> = null;
		try
		{
			names = FileSystem.readDirectory(subDir);
		}
		catch (e:Dynamic) {}

		if (names == null)
			bad('FileSystem.readDirectory(中文目录)', '返回 null（路径打不开）');
		else if (names.indexOf('音符颜色.json') >= 0)
			ok('readDirectory 返回未被破坏的中文文件名', '枚举到 [' + names.join(', ') + ']');
		else
			bad('readDirectory 返回未被破坏的中文文件名', '枚举到 [' + names.join(', ') + ']，期望含「音符颜色.json」');

		// ---- 6. 绝对路径（引擎拼绝对路径的热点）------------------------------
		var abs:String = safeStr(() -> FileSystem.fullPath(txtPath));
		if (abs != null && FileSystem.exists(abs))
			ok('FileSystem.fullPath 结果可用（绝对路径）', abs);
		else
			bad('FileSystem.fullPath 结果可用（绝对路径）', abs == null ? 'fullPath 返回 null' : 'exists=false: ' + abs);

		// ---- 7. 超长中文文件名 ----------------------------------------------
		var longName:String = '';
		for (i in 0...12) longName += '长路径测试';
		var longPath:String = baseDir + '/' + longName + '.txt';
		var longOk:Bool = false;
		try
		{
			File.saveContent(longPath, 'x');
			longOk = FileSystem.exists(longPath);
		}
		catch (e:Dynamic) {}
		if (longOk)
			ok('超长中文文件名（' + longName.length + ' 字符）', 'OK');
		else
			bad('超长中文文件名（' + longName.length + ' 字符）', '失败（MAX_PATH / longPathAware 相关）');

		// ---- 7b. 超出 MAX_PATH(260) 的超长路径：验证「优雅失败、不崩进程」--------
		// 只调 exists / readDirectory，不真的创建目录 —— 避免留下无法删除的深层垃圾。
		// 判定标准：hxcpp 的目录枚举用固定 MAX_PATH 缓冲，超长时返回 null，Haxe 层
		// 再抛一个**可捕获**的 "Invalid directory" —— 那是优雅降级，不是崩溃。
		var deep:String = baseDir;
		for (i in 0...40) deep += '/深目录名测试段';
		var deepLen:Int = deep.length;
		var hardFailure:String = null;
		var existsResult:String = '?';
		var readResult:String = '?';
		try
		{
			existsResult = Std.string(FileSystem.exists(deep));
		}
		catch (e:Dynamic)
		{
			hardFailure = 'exists 抛出：' + Std.string(e);
		}
		try
		{
			var r = FileSystem.readDirectory(deep);
			readResult = (r == null) ? 'null' : '返回 ' + r.length + ' 项';
		}
		catch (e:Dynamic)
		{
			readResult = '可捕获异常「' + Std.string(e) + '」（优雅降级，进程存活）';
		}

		if (hardFailure != null)
			bad('超长路径（' + deepLen + ' 字符）优雅失败', hardFailure);
		else
			ok('超长路径（' + deepLen + ' 字符）优雅失败、不崩进程',
				'exists=' + existsResult + '；readDirectory=' + readResult
				+ '  → 已知上限：hxcpp 目录枚举固定 MAX_PATH 缓冲，路径超 260 字符读不到（清单的 longPathAware 不改变该缓冲）');


		// ---- 8. LuaJIT -------------------------------------------------------
		#if LUA_ALLOWED
		testLua(baseDir);
		#else
		skip('LuaJIT 中文路径加载脚本', '本次构建未启用 LUA_ALLOWED');
		#end

		// ---- 9. 清理 ---------------------------------------------------------
		if (cleanup(baseDir))
			ok('清理自检目录', '已删除');
		else
			bad('清理自检目录', '残留：' + baseDir);

		head(null);
		flush();
	}

	#if LUA_ALLOWED
	static function testLua(baseDir:String):Void
	{
		var luaDir:String = baseDir + '/lua';
		try
		{
			if (!FileSystem.exists(luaDir))
				FileSystem.createDirectory(luaDir);
		}
		catch (e:Dynamic) {}

		// 脚本内容刻意全部用 ASCII，把「路径编码」和「源码编码」两个变量分开：
		// 只有 dofile 失败才能归因到路径。
		var luaFile:String = luaDir + '/中文脚本.lua';
		var wrote:Bool = true;
		try
		{
			File.saveContent(luaFile, 'local a = 40\nreturn a + 2\n');
		}
		catch (e:Dynamic)
		{
			wrote = false;
			bad('写入中文命名 Lua 脚本', Std.string(e));
		}
		if (!wrote) return;

		var lua = null;
		try
		{
			lua = LuaL.newstate();
			LuaL.openlibs(lua);
		}
		catch (e:Dynamic)
		{
			bad('创建 Lua state', Std.string(e));
			return;
		}
		if (lua == null)
		{
			bad('创建 Lua state', '返回 null');
			return;
		}

		// 8a. luaL_dofile（路径经 ConstCharStar → CRT fopen）
		var status:Int = LuaL.dofile(lua, luaFile);
		if (status == Lua.LUA_OK)
		{
			var got:Int = -1;
			if (Lua.gettop(lua) > 0)
			{
				var f:Float = Lua.tonumber(lua, -1);
				got = Std.int(f);
				Lua.pop(lua, Lua.gettop(lua));
			}
			if (got == 42)
				ok('LuaJIT luaL_dofile 加载「中文路径」脚本', '成功且返回值 = 42');
			else
				bad('LuaJIT luaL_dofile 加载「中文路径」脚本', '加载成功但返回值 = ' + got + '（期望 42）');
		}
		else
		{
			if (Lua.gettop(lua) > 0) Lua.pop(lua, Lua.gettop(lua));
			bad('LuaJIT luaL_dofile 加载「中文路径」脚本',
				'status=' + status + '（非 0 = 失败）—— 中文文件名的 Lua 脚本加载不了，'
				+ 'linc_luajit 的 dofile 走 CRT 窄字符 fopen');
		}

		// 8b. 兜底路径：把脚本源码用 hxcpp 的 File.getContent 读出来（内部 _wfopen，
		//     Unicode 安全，完全不依赖进程代码页），再交给 luaL_dostring。
		//     这正是 FunkinLua 里为老系统准备的那条兜底分支，必须验证它真能救回来。
		var fbOk:Bool = false;
		var fbReason:String = '';
		try
		{
			var src:String = File.getContent(luaFile);
			if (src == null || src.length == 0)
			{
				fbReason = 'File.getContent 返回空';
			}
			else
			{
				var stFb:Int = LuaL.dostring(lua, src);
				if (stFb == Lua.LUA_OK)
				{
					var got:Int = -1;
					if (Lua.gettop(lua) > 0)
					{
						var f:Float = Lua.tonumber(lua, -1);
						got = Std.int(f);
						Lua.pop(lua, Lua.gettop(lua));
					}
					fbOk = (got == 42);
					fbReason = '返回值 = ' + got;
				}
				else
				{
					if (Lua.gettop(lua) > 0) Lua.pop(lua, Lua.gettop(lua));
					fbReason = 'dostring status=' + stFb;
				}
			}
		}
		catch (e:Dynamic)
		{
			fbReason = Std.string(e);
		}

		if (fbOk)
			ok('兜底：File.getContent + luaL_dostring 加载中文路径脚本', '成功，' + fbReason);
		else
			bad('兜底：File.getContent + luaL_dostring 加载中文路径脚本', fbReason);

		// 8c. luaL_dostring 直接接收含中文的源码字符串（测 Haxe→Lua 的编码通道）。
		//     "中文源码" 的 UTF-8 字节数是 12；若按其他编码传会得到别的数字。
		var src:String = 'return #"\u4e2d\u6587\u6e90\u7801"';
		var st2:Int = LuaL.dostring(lua, src);
		if (st2 == Lua.LUA_OK)
		{
			var n:Int = -1;
			if (Lua.gettop(lua) > 0)
			{
				var f:Float = Lua.tonumber(lua, -1);
				n = Std.int(f);
				Lua.pop(lua, Lua.gettop(lua));
			}
			if (n == 12)
				ok('LuaJIT 接收含中文的源码字符串', '"中文源码" 字节数 = 12，UTF-8 传输正确');
			else
				bad('LuaJIT 接收含中文的源码字符串',
					'字节数 = ' + n + '（期望 12）—— Haxe String → cpp.ConstCharStar 的编码通道被破坏了，'
					+ '所有「Haxe 主动推给 Lua 的中文文本」都会乱码');
		}
		else
		{
			if (Lua.gettop(lua) > 0) Lua.pop(lua, Lua.gettop(lua));
			bad('LuaJIT 接收含中文的源码字符串',
				'status=' + st2 + '（非 0 = Lua 解析失败）—— 源码里的中文已把 Lua 解析器弄崩');
		}

		try
		{
			Lua.close(lua);
		}
		catch (e:Dynamic) {}
	}
	#end

	// ------------------------------------------------------------- 基础设施

	static function head(title:String):Void
	{
		if (title == null)
		{
			lines.push('');
			lines.push('============================================================');
			lines.push('结果：PASS ' + passed + ' / FAIL ' + failed);
			lines.push(failed > 0 ? '★ 存在失败项 —— 中文路径支持并不完整，见上面 FAIL 行。' : '全部通过。');
			return;
		}

		lines.push('');
		lines.push('============================================================');
		lines.push(title);
		lines.push('============================================================');
	}

	static function ok(name:String, detail:String):Void
	{
		passed++;
		write('[PASS]', name + (detail != null && detail.length > 0 ? '  —  ' + detail : ''));
	}

	static function bad(name:String, detail:String):Void
	{
		failed++;
		write('[FAIL]', name + (detail != null && detail.length > 0 ? '  —  ' + detail : ''));
	}

	static function skip(name:String, why:String):Void
	{
		write('[SKIP]', name + '  —  ' + why);
	}

	static function write(tag:String, msg:String):Void
	{
		var line:String = (tag == null ? '' : tag + ' ') + (msg == null ? '' : msg);
		lines.push(line);
		trace('[NovaPathTest] ' + line);
	}

	static function flush():Void
	{
		#if sys
		try
		{
			File.saveContent(REPORT_FILE, lines.join('\n') + '\n');
			trace('[NovaPathTest] 报告已写入 ' + safeStr(() -> FileSystem.fullPath(REPORT_FILE)));
		}
		catch (e:Dynamic)
		{
			trace('[NovaPathTest] 报告写入失败：' + Std.string(e));
		}
		#end
	}

	static function safeStr(f:Void->Dynamic):String
	{
		try
		{
			var v:Dynamic = f();
			return (v == null) ? null : Std.string(v);
		}
		catch (e:Dynamic)
		{
			return '<异常: ' + Std.string(e) + '>';
		}
	}

	/** 递归删除自检目录，返回是否已经清干净（目录不存在也算干净） */
	static function cleanup(dir:String):Bool
	{
		#if sys
		try
		{
			if (!FileSystem.exists(dir)) return true;

			var children:Array<String> = null;
			try
			{
				children = FileSystem.readDirectory(dir);
			}
			catch (e:Dynamic) {}

			if (children != null)
			{
				for (name in children)
				{
					var p:String = dir + '/' + name;
					var isDir:Bool = false;
					try
					{
						isDir = FileSystem.isDirectory(p);
					}
					catch (e:Dynamic) {}

					if (isDir)
						cleanup(p);
					else
					{
						try
						{
							FileSystem.deleteFile(p);
						}
						catch (e:Dynamic) {}
					}
				}
			}

			try
			{
				FileSystem.deleteDirectory(dir);
			}
			catch (e:Dynamic) {}

			return !FileSystem.exists(dir);
		}
		catch (e:Dynamic)
		{
			return false;
		}
		#else
		return true;
		#end
	}
}
