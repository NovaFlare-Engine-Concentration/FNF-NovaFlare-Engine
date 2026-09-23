package mobile.server;

#if sys
import sys.net.Host;
import sys.net.Socket;
import sys.thread.Thread;
#end

import haxe.Json;
import mobile.objects.EditorMobileKeys;
import mobile.objects.EditorMobileKeyData;

/**
 * 外部按键编辑器用的本地 HTTP 服务（127.0.0.1:1146，独立线程）。
 *
 * 路由：
 *   GET  /                  → 编辑器页面（HTML，内嵌常量）
 *   GET  /api/status        → 服务/目录/Editor 清单/最近 Editor
 *   GET  /api/load?id=X     → 读取 FuckYouNFEMobile/<X>NewFuckingButtonMobile.json
 *   POST /api/save?id=X     → 写入（body = JSON 文本）
 *   GET  /api/template?id=X → 生成“从默认键位开始”的模板 JSON
 *
 * 线程内只做 Socket / 文件 / JSON 读写，绝不碰 FlxG。
 */
class EditorKeyServer
{
	#if sys
	static var server:Socket = null;
	static var running:Bool = false;
	static var boundPort:Int = 0;
	static var serverThread:Thread = null;
	#end

	public static function startServer():Void
	{
		#if sys
		if (running) return;

		// 与 TraceServer 同构：bind/listen 必须在主线程完成（hxcpp 子线程里
		// bind 可能失败），子线程只负责 accept 与请求处理。
		boundPort = 0;
		var sock:Socket = null;
		var bindLog:String = '';
		for (tryPort in 1146...1166)
		{
			var candidate:Socket = null;
			try
			{
				candidate = new Socket();
				candidate.bind(new Host('0.0.0.0'), tryPort);
				candidate.listen(16);
				sock = candidate;
				boundPort = tryPort;
				break;
			}
			catch (e:Dynamic)
			{
				bindLog += tryPort + ':' + Std.string(e) + ' | ';
				if (candidate != null)
				{
					try
					{
						candidate.close();
					}
					catch (e2:Dynamic) {}
				}
			}
		}
		try
		{
			sys.io.File.saveContent(Sys.getCwd() + '/emk_bind_log.txt', bindLog);
		}
		catch (e:Dynamic) {}

		if (sock == null)
		{
			trace('[EditorKeyServer] cannot bind any port in 1146..1165');
			return;
		}

		server = sock;
		running = true;
		trace('[EditorKeyServer] listening on http://127.0.0.1:$boundPort/');
		serverThread = Thread.create(acceptLoop);
		#end
	}

	public static function stopServer():Void
	{
		#if sys
		running = false;
		if (server != null)
		{
			try
			{
				server.close();
			}
			catch (e:Dynamic) {}
			server = null;
		}
		#end
	}

	/** 实际绑定到的端口（未启动/失败为 0） */
	public static function getPort():Int
	{
		#if sys
		return boundPort;
		#else
		return 0;
		#end
	}

	public static function isRunning():Bool
	{
		#if sys
		return running;
		#else
		return false;
		#end
	}

	#if sys
	/** 子线程：只 accept 与处理请求（bind/listen 已由 startServer 在主线程完成） */
	static function acceptLoop():Void
	{
		var sock:Socket = server;
		if (sock == null) return;

		while (running)
		{
			var client:Socket = null;
			try
			{
				client = sock.accept();
			}
			catch (e:Dynamic)
			{
				if (!running) break;
				Sys.sleep(0.02);
				continue;
			}
			if (client == null) continue;
			try
			{
				handleClient(client);
			}
			catch (e:Dynamic)
			{
				trace('[EditorKeyServer] client error: $e');
			}
			try
			{
				client.close();
			}
			catch (e:Dynamic) {}
		}

		server = null;
	}

	static function handleClient(client:Socket):Void
	{
		client.setTimeout(8);

		// ---- 读请求头 ----
		var head:String = '';
		while (head.indexOf('\r\n\r\n') == -1)
		{
			if (head.length >= 65536) return;
			try
			{
				var b:Int = client.input.readByte();
				if (b < 0) return;
				head += String.fromCharCode(b);
			}
			catch (e:Dynamic)
			{
				return;
			}
		}

		var lines:Array<String> = head.split('\r\n');
		if (lines.length < 1) return;
		var requestLine:Array<String> = lines[0].split(' ');
		if (requestLine.length < 2) return;
		var method:String = requestLine[0].toUpperCase();
		var pathFull:String = requestLine[1];

		// ---- Content-Length ----
		var contentLength:Int = 0;
		for (i in 1...lines.length)
		{
			var idx:Int = lines[i].indexOf(':');
			if (idx <= 0) continue;
			var name:String = lines[i].substring(0, idx).toLowerCase();
			var value:String = StringTools.trim(lines[i].substring(idx + 1));
			if (name == 'content-length')
				contentLength = Std.parseInt(value);
		}

		// ---- POST body（按 UTF-8 字节收集再解码，避免中文被逐字节拆坏） ----
		var body:String = '';
		if (method == 'POST' && contentLength > 0)
		{
			if (contentLength > 2 * 1024 * 1024) return; // 上限 2MB
			var buf:haxe.io.Bytes = haxe.io.Bytes.alloc(contentLength);
			var got:Int = 0;
			while (got < contentLength)
			{
				try
				{
					var n:Int = client.input.readBytes(buf, got, contentLength - got);
					if (n <= 0) return;
					got += n;
				}
				catch (e:Dynamic)
				{
					return;
				}
			}
			body = buf.toString(); // UTF-8 → Haxe String
		}

		// ---- 路由 ----
		var queryIndex:Int = pathFull.indexOf('?');
		var path:String = (queryIndex == -1) ? pathFull : pathFull.substring(0, queryIndex);
		var query:String = (queryIndex == -1) ? '' : pathFull.substring(queryIndex + 1);
		var params:Map<String, String> = new Map();
		if (query != '')
		{
			for (pair in query.split('&'))
			{
				var eq:Int = pair.indexOf('=');
				if (eq > 0)
					params.set(pair.substring(0, eq), urlDecode(pair.substring(eq + 1)));
			}
		}

		var response:String = null;
		var binBytes:haxe.io.Bytes = null; // 二进制响应（/api/bg）
		var mime:String = 'application/json';
		var respStatus:Int = 200;

		if (method == 'GET' && (path == '/' || path == '/index.html'))
		{
			mime = 'text/html; charset=utf-8';
			// 开发迭代友好：若 FuckYouNFEMobile/editor.html 存在则优先用磁盘版本，
			// 改页面只需替换该文件并刷新浏览器，无需重新编译（正式发布仍回退内嵌常量）。
			response = EditorKeyPage.HTML;
			try
			{
				var diskPage:String = EditorMobileKeys.getFileDir() + 'editor.html';
				if (FileSystem.exists(diskPage))
					response = sys.io.File.getContent(diskPage);
			}
			catch (e:Dynamic) {}
		}
		else if (method == 'GET' && path == '/api/bg')
		{
			// 外部窗口画布背景：FuckYouNFEMobile/bg/<EditorId>.png
			var id:String = params.get('id');
			var entry = EditorMobileKeyData.entryOf(id);
			if (entry == null)
			{
				respStatus = 404;
				response = errJson('unknown editor: $id');
			}
			else
			{
				var bgPath:String = EditorMobileKeys.getFileDir() + 'bg/' + id + '.png';
				try
				{
					if (FileSystem.exists(bgPath))
					{
						binBytes = sys.io.File.getBytes(bgPath);
						mime = 'image/png';
					}
					else
					{
						respStatus = 404;
						response = errJson('no bg for: $id');
					}
				}
				catch (e:Dynamic)
				{
					respStatus = 404;
					response = errJson('bg read failed: $e');
				}
			}
		}
		else if (method == 'GET' && path == '/api/status')
		{
			response = statusJson();
		}
		else if (method == 'GET' && path == '/api/load')
		{
			var id:String = params.get('id');
			var entry = EditorMobileKeyData.entryOf(id);
			if (entry == null)
				response = errJson('unknown editor: $id');
			else
			{
				var text:Null<String> = EditorMobileKeys.readFile(id);
				response = Json.stringify({ok: true, id: id, exists: text != null, text: text});
			}
		}
		else if (method == 'POST' && path == '/api/save')
		{
			var id:String = params.get('id');
			var entry = EditorMobileKeyData.entryOf(id);
			if (entry == null)
				response = errJson('unknown editor: $id');
			else
			{
				// 校验 body 是合法 JSON 且含 buttons 数组
				try
				{
					var doc:Dynamic = Json.parse(body);
					var btns:Dynamic = Reflect.field(doc, 'buttons');
					if (btns == null || !Std.isOfType(btns, Array))
						throw 'missing buttons array';
					var ok:Bool = EditorMobileKeys.writeFile(id, body);
					response = ok
						? Json.stringify({ok: true, id: id, file: EditorMobileKeys.getFilePath(id)})
						: errJson('write failed');
				}
				catch (e:Dynamic)
				{
					response = errJson('invalid json body: $e');
				}
			}
		}
		else if (method == 'GET' && path == '/api/template')
		{
			var id:String = params.get('id');
			var entry = EditorMobileKeyData.entryOf(id);
			if (entry == null)
				response = errJson('unknown editor: $id');
			else
			{
				var text:Null<String> = EditorMobileKeys.getTemplateJson(id);
				if (text == null)
					response = errJson('template not ready (enable the maintenance toggle again)');
				else
					response = Json.stringify({ok: true, id: id, text: text});
			}
		}
		else
		{
			response = errJson('not found: $method $path');
		}

		if (response == null && binBytes == null) return;

		// 用 UTF-8/二进制字节发送：Content-Length 必须以“实际写出的字节数”为准，
		// 直接按 String.length 算会因中文多字节编码导致响应被截断。
		var bodyBytes:haxe.io.Bytes = binBytes != null ? binBytes : haxe.io.Bytes.ofString(response, UTF8);
		var reason:String = respStatus == 200 ? 'OK' : (respStatus == 404 ? 'Not Found' : 'OK');

		var header:String = 'HTTP/1.1 $respStatus $reason\r\n'
			+ 'Content-Type: $mime' + (binBytes == null ? '; charset=utf-8' : '') + '\r\n'
			+ 'Content-Length: ${bodyBytes.length}\r\n'
			+ 'Cache-Control: no-store\r\n'
			+ 'Connection: close\r\n'
			+ 'Access-Control-Allow-Origin: *\r\n'
			+ '\r\n';
		try
		{
			client.write(header);
			client.output.writeBytes(bodyBytes, 0, bodyBytes.length);
			client.output.flush();
		}
		catch (e:Dynamic) {}
	}

	static function statusJson():String
	{
		var editors:Array<Dynamic> = [];
		for (entry in EditorMobileKeyData.EDITORS)
		{
			editors.push({
				id: entry.id,
				displayName: entry.displayName,
				fileName: EditorMobileKeyData.fileNameOf(entry.id),
				exists: EditorMobileKeys.fileExists(entry.id)
			});
		}
		return Json.stringify({
			running: running,
			port: boundPort,
			folder: EditorMobileKeys.getFileDir(),
			current: EditorMobileKeys.lastEditorId,
			editors: editors
		});
	}

	static function errJson(msg:String):String
	{
		return Json.stringify({ok: false, error: msg});
	}

	static function urlDecode(s:String):String
	{
		return StringTools.urlDecode(s);
	}
	#end
}
