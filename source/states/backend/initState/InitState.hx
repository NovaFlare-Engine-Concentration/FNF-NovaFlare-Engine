package states.backend.initState;

import sys.thread.Thread;

import lime.app.Application;
import lime.system.System as LimeSystem;
import lime.graphics.opengl.GL;
import lime.graphics.Image;

import openfl.display.Bitmap;
import openfl.display.BitmapData;
import openfl.events.KeyboardEvent;

import flixel.input.gamepad.FlxGamepad;

import states.storyMenuState.StoryMenuState;
import states.backend.flashingState.FlashingState;
import states.backend.outdatedState.OutdatedState;
import states.mainMenuState.MainMenuState;
import states.freeplayState.FreeplayState;
import states.titleState.TitleState;

import scripts.init.InitScriptData;

import mobile.objects.EditorMobileKeys;
import mobile.server.EditorKeyServer;

import general.shaders.ColorblindFilter;
import gameanalytics.GABridge;

import games.backend.WeekData;
import games.backend.Highscore;
import games.backend.Song;

#if mobile
import mobile.states.CopyState;
#end

#if hxvlc
import hxvlc.flixel.FlxVideoSprite;
#end

#if android
import general.backend.device.AppData;
import states.backend.pirateState.PirateState;
#end

class InitState extends MusicBeatState
{
	var skipVideo:FlxText;

	var mustUpdate:Bool = false;

	public static var updateVersion:String = '';

	public static var ignoreCopy = false; //用于copystate，别删

	#if sys
	/**
	 * 【临时诊断实验】在 stage 顶层叠加"光栅化分辨率对比"图案。
	 *
	 * 三块图案的**视觉尺寸完全相同**（都是 240x120 逻辑像素，再按 1280→1920
	 * 的 1.5 倍放大显示），唯一差别是内部位图的光栅化倍率：
	 *   A = 1 倍（= 当前引擎：按 1280 逻辑空间 1:1 生成，然后放大 1.5 倍）
	 *   B = 2 倍（= 若把内容按 2K 光栅化，再缩回原视觉尺寸）
	 *   C = 4 倍
	 * 截图后测量细条纹的峰谷对比度与笔画的过渡宽度，即可量化回答
	 * "提高光栅化分辨率能不能真的让 1920 全屏变清晰"。
	 */
	public static function renderProbePattern():Void
	{
		try
		{
			var stage = FlxG.stage;
			if (stage == null) return;

			var logW:Int = 240;
			var logH:Int = 120;
			var zoom:Float = 1.5;   // 1280 逻辑 → 1920 屏幕
			var gap:Int = 40;
			var factors:Array<Int> = [1, 2, 4];

			var holder = new openfl.display.Sprite();
			holder.x = 60;
			holder.y = 60;
			stage.addChild(holder);

			var shownW:Float = logW * zoom;
			var label = new openfl.text.TextField();
			label.defaultTextFormat = new openfl.text.TextFormat(null, 15, 0x00FF00);

			var line1:String = '';
			for (i in 0...factors.length)
			{
				var bmp = detailBitmap(logW * factors[i], logH * factors[i], factors[i]);
				var spr = new Bitmap(bmp);
				spr.scaleX = spr.scaleY = zoom / factors[i];   // 视觉尺寸恒等
				spr.x = i * (shownW + gap);
				spr.y = 0;
				holder.addChild(spr);
			}

			line1 = 'A = raster x1 (current engine)      B = raster x2      C = raster x4      -- all shown at identical size on 1920'
				+ '\n[A .. x=' + Std.int(60 + shownW) + ']  [B .. x=' + Std.int(60 + 2 * shownW + gap) + ']  [C .. x=' + Std.int(60 + 3 * shownW + 2 * gap) + ']';
			label.text = line1;
			label.x = 0;
			label.y = logH * zoom + 12;
			holder.addChild(label);

			// ── FlxText 高清字形对照 ──────────────────────────────
			// 同一段文字、同一个逻辑字号，唯一差别是字形光栅化倍率：
			//   T1 = renderScale 1.0（原版：字形按逻辑字号光栅化）
			//   T2 = renderScale 1.5（位图 ×1.5，再缩回相同逻辑尺寸显示）
			// 两者视觉尺寸完全一致，只有"每个字有多少真实像素"不同。
			final sample:String = 'FlxText AaBbGg 0123 中文测试';
			final prevRS:Float = FlxText.renderScale;

			FlxText.renderScale = 1.0;
			var t1 = new FlxText(0, 0, 0, sample);
			t1.setFormat(null, 16, 0xFFFFFF);
			@:privateAccess t1.regenGraphic();
			final bmp1 = t1.graphic.bitmap;

			FlxText.renderScale = 1.5;
			var t2 = new FlxText(0, 0, 0, sample);
			t2.setFormat(null, 16, 0xFFFFFF);
			@:privateAccess t2.regenGraphic();
			final bmp2 = t2.graphic.bitmap;

			FlxText.renderScale = prevRS;

			var pair = new openfl.display.Sprite();
			pair.x = 60;
			pair.y = 60 + logH * zoom + 44;
			stage.addChild(pair);

			// T1：位图即逻辑尺寸，按 zoom 放到屏幕
			var s1 = new Bitmap(bmp1);
			s1.scaleX = s1.scaleY = zoom;
			pair.addChild(s1);

			// T2：位图是 1.5 倍，按 zoom/1.5 缩回**相同的逻辑/屏幕尺寸**
			var s2 = new Bitmap(bmp2);
			s2.scaleX = s2.scaleY = zoom / 1.5;
			s2.x = 40;
			pair.addChild(s2);

			L_probeNote = 'textPair t1bitmap=' + bmp1.width + 'x' + bmp1.height
				+ ' t2bitmap=' + bmp2.width + 'x' + bmp2.height
				+ ' at pair(60,' + Std.int(60 + logH * zoom + 44) + ')';
		}
		catch (e:Dynamic)
		{
			trace('renderProbePattern failed: $e');
		}
	}

	/** 图案布局备注（写入探针，便于定位截图区域）。 */
	public static var L_probeNote:String = '';

	/** 构造一份"细节测试图"：细条纹 + 1px 竖线 + 小字号文字 + 1px 描边。 */
	static function detailBitmap(w:Int, h:Int, f:Int):BitmapData
	{
		var bd = new BitmapData(w, h, true, 0xFF14141C);

		// 源空间 1px 线 + 1px 间隔的细条纹：最能暴露放大插值
		var stripeH:Int = f;
		var i:Int = 0;
		while (i * 2 * stripeH < Std.int(h * 0.28))
		{
			bd.fillRect(new openfl.geom.Rectangle(0, i * 2 * stripeH, w, stripeH), 0xFFFFFFFF);
			i++;
		}

		// 源空间 1px 宽的竖线组
		for (k in 0...6)
			bd.fillRect(new openfl.geom.Rectangle(Std.int((6 + k * 5) * f), Std.int(h * 0.32), f, Std.int(h * 0.14)), 0xFF00FF88);

		// 小字号文字（UI 文字是"糊"的重灾区）
		var sizes:Array<Float> = [11.0, 9.0];
		var ty:Float = h * 0.50;
		for (s in sizes)
		{
			var tf = new openfl.text.TextField();
			tf.defaultTextFormat = new openfl.text.TextFormat(null, Std.int(s * f), 0xFFFFFF);
			tf.text = 'AaBbGg 0123 ' + Std.int(s) + 'px';
			tf.autoSize = openfl.text.TextFieldAutoSize.LEFT;
			tf.x = 6 * f;
			tf.y = ty;
			bd.draw(tf);
			ty += s * 2.2 * f;
		}

		// 源空间 1px 描边的方框
		var bx:Int = Std.int(w * 0.58);
		var by:Int = Std.int(h * 0.72);
		var bw:Int = Std.int(w * 0.36);
		var bh:Int = Std.int(h * 0.22);
		bd.fillRect(new openfl.geom.Rectangle(bx, by, bw, f), 0xFF66CCFF);
		bd.fillRect(new openfl.geom.Rectangle(bx, by + bh - f, bw, f), 0xFF66CCFF);
		bd.fillRect(new openfl.geom.Rectangle(bx, by, f, bh), 0xFF66CCFF);
		bd.fillRect(new openfl.geom.Rectangle(bx + bw - f, by, f, bh), 0xFF66CCFF);

		return bd;
	}
	#end

	#if sys
	/**
	 * 【临时诊断】把渲染管线的真实运行参数写到 nova_render_probe.txt。
	 *
	 * 目的：确认桌面端实际走的是哪条路——
	 *   DRAW_TILES（GPU 直接变换采样，不存在中间缓冲）
	 *   BLITTING （相机持有一张 FlxG.width x FlxG.height 的 BitmapData，
	 *              再被 FlxCamera.canvas._flashBitmap 按 scaleMode.scale 放大）
	 * 后者才是"以 1280 渲染再放大"的字面情形，也才值得改渲染分辨率。
	 */
	public static function renderProbe():Void
	{
		try
		{
			var L:Array<String> = [];
			var stage = FlxG.stage;
			var win = (stage != null) ? stage.window : null;

			L.push('renderMethod=' + Std.string(FlxG.renderMethod) + ' renderTile=' + FlxG.renderTile + ' renderBlit=' + FlxG.renderBlit);
			L.push('nativeResApply=' + Main.nativeResApplyLog);
			L.push('probeNote=' + L_probeNote);
			var lw:Int = 0, lh:Int = 0;
			if (stage != null)
			{
				@:privateAccess {
					lw = stage.__logicalWidth;
					lh = stage.__logicalHeight;
				}
			}
			L.push('stageLogical=' + lw + 'x' + lh);
			final libStage = openfl.Lib.current != null ? openfl.Lib.current.stage : null;
			L.push('sameStage=' + ((stage != null && libStage == stage))
				+ ' libStage=' + ((libStage != null) ? libStage.stageWidth + 'x' + libStage.stageHeight : 'null'));
			L.push('FlxG=' + FlxG.width + 'x' + FlxG.height + ' initial=' + FlxG.initialWidth + 'x' + FlxG.initialHeight);
			L.push('stage=' + (stage != null ? stage.stageWidth + 'x' + stage.stageHeight + ' quality=' + Std.string(stage.quality) : 'null'));
			L.push('scaleMode=' + ((stage != null) ? Std.string(stage.scaleMode) + ' align=' + Std.string(stage.align) : 'null')
				+ ' nativeResEnv=' + Std.string(Main.nativeResRequested()));
			L.push('window=' + (win != null ? win.width + 'x' + win.height + ' scale=' + win.scale + ' dpi=' + win.display.dpi : 'null'));
			L.push('contextType=' + ((win != null && win.context != null) ? Std.string(win.context.type) : 'null'));
			L.push('scaleMode=' + Type.getClassName(Type.getClass(FlxG.scaleMode))
				+ ' scale=' + FlxG.scaleMode.scale.x + ',' + FlxG.scaleMode.scale.y
				+ ' gameSize=' + FlxG.scaleMode.gameSize.x + ',' + FlxG.scaleMode.gameSize.y
				+ ' deviceSize=' + FlxG.scaleMode.deviceSize.x + ',' + FlxG.scaleMode.deviceSize.y
				+ ' offset=' + FlxG.scaleMode.offset.x + ',' + FlxG.scaleMode.offset.y);

			if (FlxG.cameras != null && FlxG.cameras.list != null)
			{
				for (cam in FlxG.cameras.list)
				{
					L.push('cam#' + cam.ID + ' size=' + cam.width + 'x' + cam.height
						+ ' zoom=' + cam.zoom + ' camScale=' + cam.scaleX + ',' + cam.scaleY
						+ ' totalScale=' + cam.totalScaleX + ',' + cam.totalScaleY
						+ ' aa=' + cam.antialiasing
						+ ' buffer=' + (cam.buffer == null ? 'null' : cam.buffer.width + 'x' + cam.buffer.height)
						+ ' canvas=' + (cam.canvas == null ? 'null' : 'present'));
				}
			}

			// 1.5 倍缩放究竟发生在哪一层？
			var lib = openfl.Lib.current;
			L.push('lib.current scale=' + ((lib != null) ? lib.scaleX + ',' + lib.scaleY : 'null'));
			L.push('FlxG.game scale=' + FlxG.game.scaleX + ',' + FlxG.game.scaleY + ' pos=' + FlxG.game.x + ',' + FlxG.game.y);
			if (FlxG.cameras != null && FlxG.cameras.list != null)
			{
				for (cam in FlxG.cameras.list)
				{
					if (cam.canvas != null)
						L.push('cam#' + cam.ID + '.canvas scale=' + cam.canvas.scaleX + ',' + cam.canvas.scaleY + ' pos=' + cam.canvas.x + ',' + cam.canvas.y);
					if (cam.flashSprite != null)
						L.push('cam#' + cam.ID + '.flashSprite scale=' + cam.flashSprite.scaleX + ',' + cam.flashSprite.scaleY
							+ ' pos=' + cam.flashSprite.x + ',' + cam.flashSprite.y);
				}
			}

			// 后缓冲（GL viewport）尺寸：判断 1.5 倍放大是"后缓冲被拉伸"还是"displayMatrix 缩放"
			try
			{
				var vp = lime.graphics.opengl.GL.getParameter(lime.graphics.opengl.GL.VIEWPORT);
				if (vp != null && vp.length >= 4)
					L.push('glViewport=' + Std.int(vp[2]) + 'x' + Std.int(vp[3]));
				else
					L.push('glViewport=unexpected');
			}
			catch (e:Dynamic)
			{
				L.push('glViewport=err ' + Std.string(e));
			}

			if (stage != null)
			{
				var dmA:Float = 0, dmD:Float = 0;
				@:privateAccess {
					dmA = stage.__displayMatrix.a;
					dmD = stage.__displayMatrix.d;
				}
				L.push('displayMatrix=' + dmA + ',' + dmD);
			}

			// 【实验】FlxText 超采样自检：验证"位图 ×N、逻辑尺寸不变"
			try
			{
				var tp = new FlxText(0, 0, 0, 'SelfCheck AaBbGg 0123');
				tp.setFormat(null, 16, 0xFFFFFF);
				@:privateAccess tp.regenGraphic();
				L.push('textProbe renderScale=' + FlxText.renderScale
					+ ' bitmap=' + ((tp.graphic != null) ? tp.graphic.width + 'x' + tp.graphic.height : 'null')
					+ ' frame=' + tp.frameWidth + 'x' + tp.frameHeight
					+ ' width=' + tp.width + ' h=' + tp.height
					+ ' scale=' + tp.scale.x);
				tp.destroy();
			}
			catch (e:Dynamic)
			{
				L.push('textProbe err ' + Std.string(e));
			}

			// 【实验】makeGraphic 超采样自检
			try
			{
				var sp = new flixel.FlxSprite();
				sp.makeGraphic(100, 40, 0xFFFFFFFF);
				L.push('spriteProbe density=' + flixel.FlxSprite.pixelDensity
					+ ' bitmap=' + ((sp.graphic != null) ? sp.graphic.width + 'x' + sp.graphic.height : 'null')
					+ ' frame=' + sp.frameWidth + 'x' + sp.frameHeight
					+ ' width=' + sp.width + 'x' + sp.height
					+ ' scale=' + sp.scale.x);
				sp.destroy();
			}
			catch (e:Dynamic)
			{
				L.push('spriteProbe err ' + Std.string(e));
			}

			sys.io.File.saveContent('nova_render_probe.txt', L.join('\n') + '\n');
		}
		catch (e:Dynamic)
		{
			try sys.io.File.saveContent('nova_render_probe.txt', 'probe failed: ' + Std.string(e)) catch (e2:Dynamic) {}
		}
	}

	private static var probeKey:String = '';
	private static var lastWinW:Int = -1;
	private static var lastWinH:Int = -1;

	/** 【实验/修复验证】尺寸/缩放状态变化时重写探针文件，并在窗口尺寸变化后补一次 Stage.__resize()。 */
	public static function probeWatch():Void
	{
		try
		{
			FlxG.signals.postUpdate.add(function()
			{
				var s = FlxG.stage;
				if (s == null) return;
				var w = s.window;

				if (w != null && (w.width != lastWinW || w.height != lastWinH))
				{
					lastWinW = w.width;
					lastWinH = w.height;
					// 关键：OpenFL 只在窗口创建时调过一次 __setLogicalSize，
					// 之后若 resize 事件没送达，stage/后缓冲就会停在创建尺寸，
					// 画面被系统整体拉伸。这里主动补算一次。
					@:privateAccess s.__resize();
				}

				var key = s.stageWidth + 'x' + s.stageHeight + '|' + ((w != null) ? w.width + 'x' + w.height + '@' + w.scale : '');
				if (key != probeKey)
				{
					probeKey = key;
					renderProbe();
				}
			});
		}
		catch (e:Dynamic) {}
	}
	#end

	override public function create()
	{
		FlxTransitionableState.skipNextTransIn = true;
		FlxTransitionableState.skipNextTransOut = true;

		FlxG.fixedTimestep = false;
		FlxG.game.focusLostFramerate = 60;
		@:privateAccess {
			if (FlxG.game.stage != null && FlxG.game.stage.window != null)
				FlxG.game.stage.window.frameRate = FlxG.updateFramerate;
		}
		FlxG.keys.preventDefaultKeys = [TAB];

		super.create();

		// `FlxSave.bind()` clears the current `data` up-front and only fills it back in
		// when the shared object loads successfully, so a save file that fails to parse
		// (or to read) leaves `FlxG.save.data == null`. Reading any field of that null
		// Dynamic is a hard access violation on hxcpp, which used to kill the engine
		// before the first frame. Give flixel a recovery parser and then make sure the
		// container is never left null.
		FlxG.save.bind('funkin', CoolUtil.getSavePath(), ClientPrefs.recoverUnreadableSave);
		ClientPrefs.ensureSaveData();

		ClientPrefs.loadPrefs();

		#if sys
		// 【默认关闭】文字字形超采样 —— 实测会改动部分 UI 元素的排版，待查清后再启用。
		//
		// 机制说明：全屏时 OpenFL 会把整幅 1280x720 的画面按 displayMatrix 放大 1.5 倍
		// 输出（已实测 a=1.5），字形若只按逻辑字号光栅化就会发虚。本机制让字形按
		// N 倍精度光栅化，屏幕采样回到 1:1，从而恢复锐利。倍率取 1.5 最合算
		// （正好抵消 displayMatrix，位图面积 x2.25 而非 x4）。
		//
		// 为什么默认关闭：与关闭状态做同机同界面 A/B 实测，
		// 大差异像素(big>=60) 达 1.032%，而相同配置两次运行的基线噪声只有 0.013%
		// （见 20260921.md 第十节）。big 级差异意味着元素的位置/形状真的变了，
		// 不是单纯的边缘锐化 —— 用户反馈的"文字排版错位、缩放错误"即来源于此。
		// 已知遗留：文字逻辑宽度会比原来少 1px（226->225），原因是字体字距在不同
		// 字号下取整方式不同；对依赖 text.width 做布局/缩放的 UI 会造成可见偏移。
		// 排查与适配完成前，保持原版行为，需要试用时设 NOVAF_TEXT_HD=1.5。
		try
		{
			final hdV:String = Sys.getEnv('NOVAF_TEXT_HD');
			if (hdV != null && hdV != '')
			{
				final hdF:Float = Std.parseFloat(hdV);
				if (!Math.isNaN(hdF) && hdF >= 1.0 && hdF <= 4.0)
					FlxText.renderScale = hdF;
			}
		}
		catch (e:Dynamic) {}

		// 【默认关闭】程序化位图（makeGraphic）超采样。
		// 机制本身已验证有效，但开启后位图尺寸变为 N 倍，而下列代码直接操作
		// `.pixels` 并使用硬编码像素坐标，会只覆盖一部分区域而错位：
		//   substates/Prompt.hx（11 处 fillRect）、developer/editors/ChartingState.hx（波形）、
		//   general/backend/CoolUtil.hx、options/base/NotesSubState.hx、scripts/lua/FunkinLua.hx
		// 待这些调用点按倍率适配后再默认开启。现可用 NOVAF_PIXEL_DENSITY=2 手动试用。
		try
		{
			final pdV:String = Sys.getEnv('NOVAF_PIXEL_DENSITY');
			if (pdV != null && pdV != '')
			{
				final pdF:Float = Std.parseFloat(pdV);
				if (!Math.isNaN(pdF) && pdF >= 1.0 && pdF <= 4.0)
					flixel.FlxSprite.pixelDensity = pdF;
			}
		}
		catch (e:Dynamic) {}
		#end

		#if sys
		if (Main.nativeResRequested())
		{
			// 在 setupGame() 里设过一次，但那时 OpenFL 的窗口包装尚未完成，
			// 会被 Window.new() 用 attributes.width/height 覆盖回创建尺寸。
			// 这里在舞台完全就绪后再设一次，此时才会真正生效。
			Main.applyNativeLogicalSize();
		}
		// 临时诊断改为按需启用：默认不叠加测试图案、不写 nova_render_probe.txt，
		// 画面保持干净。
		//   NOVAF_PROBE=1   → 输出渲染自检与探针文件
		//   NOVAF_PATTERN=1 → 在 stage 顶层叠加"分辨率对比"测试图案
		// 注意 probeWatch() 内含"窗口尺寸变化后补一次 Stage.__resize()"的修复，
		// 若启用 NOVAF_RES=native / 2k 需要把它一并打开。
		try
		{
			if (Sys.getEnv('NOVAF_PROBE') == '1')
			{
				renderProbe();
				probeWatch();
			}
			if (Sys.getEnv('NOVAF_PATTERN') == '1')
				renderProbePattern();
		}
		catch (e:Dynamic) {}
		#end

		// 调试/自动化验证用：启动参数 -emk / --emk / emk 或环境变量 NOVAF_EMK=1
		// 等效于在维护设置里打开「调整移动端各Editor键位」（不弹浏览器）。
		#if sys
		try
		{
			var argHit:Bool = Sys.args().indexOf('-emk') != -1 || Sys.args().indexOf('--emk') != -1 || Sys.args().indexOf('emk') != -1;
			var envHit:Bool = false;
			try { envHit = Sys.getEnv('NOVAF_EMK') == '1'; } catch (e:Dynamic) {}
			if (argHit || envHit)
				EditorMobileKeys.setEnabled(true, false);
		}
		catch (e:Dynamic) {}
		#end

		#if ACHIEVEMENTS_ALLOWED Achievements.load(); #end
		GABridge.init();

		switch (ClientPrefs.data.gameQuality)
		{
			case 0:
				FlxG.game.stage.quality = openfl.display.StageQuality.LOW;
			case 1:
				FlxG.game.stage.quality = openfl.display.StageQuality.HIGH;
			case 2:
				FlxG.game.stage.quality = openfl.display.StageQuality.MEDIUM;
			case 3:
				FlxG.game.stage.quality = openfl.display.StageQuality.BEST;
		}

		#if mobile
		FlxG.fullscreen = true;
		#end

		#if desktop FlxG.stage.addEventListener(KeyboardEvent.KEY_UP, Main.toggleFullScreen); #end

		#if android FlxG.android.preventDefaultKeys = [BACK]; #end

		#if mobile
		LimeSystem.allowScreenTimeout = ClientPrefs.data.screensaver;
		#end

		#if html5
		FlxG.autoPause = false;
		FlxG.mouse.visible = false;
		#end

		// shader coords fix
		FlxG.signals.gameResized.add(function(w, h)
		{
			if (FlxG.cameras != null)
			{
				for (cam in FlxG.cameras.list)
				{
					if (cam != null && cam.filters != null)
						Main.resetSpriteCache(cam.flashSprite);
				}
			}

			if (FlxG.game != null)
				Main.resetSpriteCache(FlxG.game);
		});		

		var maxTextureSize:Int = GL.getParameter(GL.MAX_TEXTURE_SIZE);
		trace('maxTextureSize: ' + maxTextureSize);
		Image.setMaxTextureSize(maxTextureSize);

		trace("GL_VENDOR=" + GL.getString(GL.VENDOR));
		trace("GL_RENDERER=" + GL.getString(GL.RENDERER));
		trace("GL_VERSION=" + GL.getString(GL.VERSION));

		Language.resetData();

		#if CHECK_FOR_UPDATES
		if (ClientPrefs.data.checkForUpdates)
		{
			var thread = Thread.create(() ->
        	{
				try
				{
					trace('checking for update');
					// 版本检查必须指向本分支(修复版)自己的仓库，而不是已经停止维护的上游仓库
					var http = new haxe.Http("https://raw.githubusercontent.com/D-C-LushiFu/NovaFlare-Engine-LushiFuFixedsss/refs/heads/main/gitVersion.txt");

					http.onData = function(data:String)
					{
						try
						{
							// gitVersion.txt：第 1 行 = 引擎版本号(如 1.2.1)，第 2 行 = 数据版本号(如 2.9)
							var lines:Array<String> = data.split('\n');
							var onlineEngineLine:String = (lines.length > 0 ? lines[0] : '').trim();
							var onlineDataLine:String = (lines.length > 1 ? lines[1] : '').trim();
							var onlineEngine:Float = toVersionNumber(onlineEngineLine);
							var onlineData:Float = toVersionNumber(onlineDataLine);
							var localEngine:Float = toVersionNumber(MainMenuState.novaFlareEngineVersion);
							var localData:Float = toVersionNumber(Std.string(MainMenuState.novaFlareEngineDataVersion));

							trace('version online: ' + onlineEngineLine + ', your version: ' + MainMenuState.novaFlareEngineVersion);

							if (onlineEngine > localEngine || onlineData > localData)
							{
								trace('versions arent matching!');
								updateVersion = (onlineEngine > localEngine ? onlineEngineLine : onlineDataLine);
								TitleState.updateVersion = updateVersion;
								mustUpdate = true;
							}
						}
						catch (e:Dynamic)
						{
							// 解析失败不能影响游戏，只记录日志
							trace('update check parse error: $e');
						}
					}

					http.onError = function(error)
					{
						trace('update check error: $error');
					}

					http.request();
				}
				catch (e:Dynamic)
				{
					// 更新检查里的任何异常都绝不能让整个程序崩溃，只记录日志
					trace('update check exception: $e');
				}
			});
		}
		#end

		#if mobile
		// hotfix：iOS 上自动复制只尝试一次，失败或被中断后不再反复弹窗
		//（配套 CopyState.hasAttemptedIOSCopy / markIOSCopyAttempted）
		var allowAutomaticCopy:Bool = #if ios !CopyState.hasAttemptedIOSCopy() #else true #end;
		if (allowAutomaticCopy && ClientPrefs.data.filesCheck && !ignoreCopy)
		{
			if (!CopyState.checkExistingFiles())
			{
				#if ios
				CopyState.markIOSCopyAttempted();
				#end
				FlxG.switchState(new CopyState());
				return;
			}
		}
		ignoreCopy = false;

        // 检查assets/version.txt存不存在且里面保存的上一个版本号与当前的版本号一不一致，如果不一致或不存在，强制启动copy。
        if (allowAutomaticCopy && !FileSystem.exists(Paths.getSharedPath('version.txt')))
        {
            sys.io.File.saveContent(Paths.getSharedPath('version.txt'), 'now version: ' + Std.string(states.mainMenuState.MainMenuState.novaFlareEngineVersion) + '\n' + 'commit: ' + Std.string(states.mainMenuState.MainMenuState.novaFlareEngineCommit));
            #if ios
            CopyState.markIOSCopyAttempted();
            #end
            FlxG.switchState(new CopyState(true));
            return;
        }
        else if (allowAutomaticCopy)
        {
            var expectedContent = 'now version: ' + Std.string(states.mainMenuState.MainMenuState.novaFlareEngineVersion) + '\n' + 'commit: ' + Std.string(states.mainMenuState.MainMenuState.novaFlareEngineCommit);
            var actualContent = sys.io.File.getContent(Paths.getSharedPath('version.txt'));
            
            if (actualContent != expectedContent)
            {
                sys.io.File.saveContent(Paths.getSharedPath('version.txt'), expectedContent);
                #if ios
                CopyState.markIOSCopyAttempted();
                #end
                FlxG.switchState(new CopyState(true));
                return;
            }
        }

		#end

		Highscore.load();

		#if LUA_ALLOWED
		#if (android && EXTERNAL || MEDIA)
		try
		{
		#end
			Mods.pushGlobalMods();
		#if (android && EXTERNAL || MEDIA)
		}
		catch (e:Dynamic)
		{
			SUtil.showPopUp("permission is not obtained, restart the application", "Error!");
			Sys.exit(1);
		}
		#end
		#end

		Mods.loadTopMod();

		// 窗口固定以默认窗口化启动（不再从存档恢复全屏/旧窗口状态，
		// 避免旧存档数据把窗口状态“污染”成奇怪的全屏/尺寸）
		persistentUpdate = true;
		persistentDraw = true;

		InitScriptData.init();
		Main.initScriptModules();
		#if HSCRIPT_ALLOWED
		scripts.stages.modules.ModuleHandler.init();
		scripts.stages.GlobalHandler.init();
		#end

		ColorblindFilter.UpdateColors();
	
		if (FlxG.save.data.weekCompleted != null)
		{
			StoryMenuState.weekCompleted = FlxG.save.data.weekCompleted;
		}

		#if sys
		if (startDiagnosticGameplay())
			return;
		#end
	
		FlxG.mouse.visible = false;
		#if FREEPLAY
		MusicBeatState.switchState(new FreeplayState());
		#elseif CHARTING
		MusicBeatState.switchState(new ChartingState());
		#else
		if (FlxG.save.data.openedFlash == null)
		{
			FlxG.save.data.openedFlash = true;
			//ClientPrefs.saveSettings();
			FlxTransitionableState.skipNextTransIn = true;
			FlxTransitionableState.skipNextTransOut = true;
			MusicBeatState.switchState(new FlashingState());
		}
		else
		{
			startCutscenesIn();
		}
		#end
	}

	#if sys
	function startDiagnosticGameplay():Bool
	{
		var requestedSong:String = Sys.getEnv('NOVAFLARE_DIAGNOSTIC_SONG');
		if (requestedSong == null || requestedSong.trim().length == 0)
			return false;

		requestedSong = Paths.formatToSongPath(requestedSong.trim());

		var requestedMod:String = Sys.getEnv('NOVAFLARE_DIAGNOSTIC_MOD');
		if (requestedMod != null && requestedMod.trim().length > 0)
			Mods.currentModDirectory = requestedMod.trim();

		Difficulty.resetList();
		var difficulty:Int = 1;
		var requestedDifficulty:String = Sys.getEnv('NOVAFLARE_DIAGNOSTIC_DIFFICULTY');
		if (requestedDifficulty != null && requestedDifficulty.trim().length > 0)
		{
			var requestedDifficultyValue:String = requestedDifficulty.trim();
			var parsedDifficulty:Null<Int> = Std.parseInt(requestedDifficultyValue);
			if (parsedDifficulty != null)
				difficulty = parsedDifficulty;
			else
			{
				Difficulty.copyFrom([requestedDifficultyValue]);
				difficulty = 0;
			}
		}
		difficulty = Std.int(Math.max(0, Math.min(Difficulty.list.length - 1, difficulty)));

		var botplayValue:String = Sys.getEnv('NOVAFLARE_DIAGNOSTIC_BOTPLAY');
		var botplay:Bool = botplayValue == null
			|| !['0', 'false', 'off', 'no'].contains(botplayValue.trim().toLowerCase());

		try
		{
			PlayState.isStoryMode = false;
			PlayState.storyDifficulty = difficulty;
			PlayState.replayMode = false;
			PlayState.chartingMode = false;
			PlayState.changedDifficulty = false;
			PlayState.deathCounter = 0;
			PlayState.seenCutscene = true;
			PlayState.startOnTime = 0;
			ClientPrefs.data.gameplaySettings.set('practice', false);
			ClientPrefs.data.gameplaySettings.set('botplay', botplay);
			if (FlxG.sound.music == null)
				FlxG.sound.playMusic(Paths.music('none'), 0, true);

			var chartName:String = Highscore.formatSong(requestedSong, difficulty);
			PlayState.SONG = Song.loadFromJson(chartName, requestedSong);
			trace('diagnostic:gameplay prepared song=$requestedSong chart=$chartName '
				+ 'difficulty=$difficulty mod=${Mods.currentModDirectory} botplay=$botplay');

			LoadingState.prepareToSong();
			FlxTransitionableState.skipNextTransIn = true;
			FlxTransitionableState.skipNextTransOut = true;
			LoadingState.loadAndSwitchState(new PlayState());
			return true;
		}
		catch (error:Dynamic)
		{
			trace('diagnostic:gameplay error=$error stack=${haxe.CallStack.exceptionStack()}');
			throw error;
		}
	}
	#end
	
	function startCutscenesIn()
	{
		if (!ClientPrefs.data.skipTitleVideo)
			#if VIDEOS_ALLOWED
			startVideo('menuExtend/titleIntro');
			#else
			changeState();
			#end
		else
			changeState();
	}
	
	override function update(elapsed:Float)
	{
		if (FlxG.sound.music != null)
			Conductor.songPosition = FlxG.sound.music.time;
			
		var pressedEnter:Bool = FlxG.keys.justPressed.ENTER || controls.ACCEPT;
	
		#if ios
		for (touch in FlxG.touches.list)
		{
			if (touch.justPressed)
			{
				pressedEnter = true;
			}
		}
		#end
	
		#if android
		if (FlxG.android.justReleased.BACK)
			pressedEnter = true;
		#end
	
		var gamepad:FlxGamepad = FlxG.gamepads.lastActive;
	
		if (gamepad != null)
		{
			if (gamepad.justPressed.START)
				pressedEnter = true;
	
			#if switch
			if (gamepad.justPressed.B)
				pressedEnter = true;
			#end
		}
		
		if (pressedEnter)
		{
			#if VIDEOS_ALLOWED
			if (video != null && !videoFinished)
				videoEnd();
			else
				changeState();
			#else
			changeState();
			#end
			return;
		}
	
		super.update(elapsed);
	}
	
	#if VIDEOS_ALLOWED
	var video:FlxVideoSprite;
	var videoFinished:Bool = false;
	var videoHasFrame:Bool = false;
	var videoWatchdog:FlxTimer;
	
	function startVideo(name:String)
	{
		videoFinished = false;
		videoHasFrame = false;
		skipVideo = new FlxText(0, FlxG.height - 26, 0, "Press " + #if android "Back on your Phone " #else "Enter " #end + "to skip", 18);
		skipVideo.setFormat(Assets.getFont("assets/fonts/montserrat.ttf").fontName, 18);
		skipVideo.alpha = 0;
		skipVideo.alignment = CENTER;
		skipVideo.screenCenter(X);
		skipVideo.scrollFactor.set();
		skipVideo.antialiasing = ClientPrefs.data.antialiasing;
	
		#if VIDEOS_ALLOWED
		var filepath:String = Paths.video(name);
		#if sys
		if (!FileSystem.exists(filepath))
		#else
		if (!OpenFlAssets.exists(filepath))
		#end
		{
			FlxG.log.warn('Couldnt find video file: ' + name);
			videoEnd();
			return;
		}
	
		video = new FlxVideoSprite(0, 0);
		video.antialiasing = true;
		if (!ClientPrefs.data.useFlixelCoords)
		{
			video.bitmap.x -= FlxG.game.x;
			video.bitmap.y -= FlxG.game.y;
		}
		video.bitmap.onFormatSetup.add(function():Void
		{
			if (video.bitmap != null && video.bitmap.bitmapData != null)
			{
				final scale:Float = Math.min(FlxG.width / video.bitmap.bitmapData.width, FlxG.height / video.bitmap.bitmapData.height);
	
				video.setGraphicSize(video.bitmap.bitmapData.width * scale, video.bitmap.bitmapData.height * scale);
				video.updateHitbox();
				video.screenCenter();
			}
		});
		video.bitmap.onEndReached.add(videoEnd);
		video.bitmap.onEncounteredError.add(function(message:String):Void
		{
			FlxG.log.error('Video playback failed: ' + message);
			videoEnd();
		});
		video.bitmap.onDisplay.add(function():Void
		{
			if (videoHasFrame)
				return;
			videoHasFrame = true;
			if (videoWatchdog != null)
			{
				videoWatchdog.cancel();
				videoWatchdog = null;
			}
		});
		add(video);
		if (!video.load(filepath))
		{
			FlxG.log.warn('Couldnt load video file: ' + filepath);
			videoEnd();
			return;
		}
		new FlxTimer().start(0.001, function(_):Void
		{
			if (video != null && video.bitmap != null && FlxG.state == this)
			{
				if (!video.play())
				{
					FlxG.log.error('Video player refused to start: ' + filepath);
					videoEnd();
					return;
				}
				if (!videoHasFrame)
				{
					videoWatchdog = new FlxTimer().start(8, function(_):Void
					{
						if (!videoFinished && !videoHasFrame && FlxG.state == this)
						{
							FlxG.log.error('Video produced no display frame: ' + filepath);
							videoEnd();
						}
					});
				}
			}
		});
	
		showText();
		#else
		FlxG.log.warn('Platform not supported!');
		videoEnd();
		return;
		#end
	}
	
	function videoEnd()
	{
		if (videoFinished)
			return;
		videoFinished = true;
		if (videoWatchdog != null)
		{
			videoWatchdog.cancel();
			videoWatchdog = null;
		}
		if (skipVideo != null) skipVideo.visible = false;
		var oldVideo:FlxVideoSprite = video;
		video = null;
		if (oldVideo != null) {
			if (oldVideo.bitmap != null)
				oldVideo.bitmap.onEndReached.remove(videoEnd);
			oldVideo.stop();
			remove(oldVideo, true);
			oldVideo.destroy();
		}
		changeState();
		trace("end");
	}
	
	function showText()
	{
		add(skipVideo);
		FlxTween.tween(skipVideo, {alpha: 1}, 1, {ease: FlxEase.quadIn});
		FlxTween.tween(skipVideo, {alpha: 0}, 1, {ease: FlxEase.quadIn, startDelay: 4});
	}
	#end

	var changingState:Bool = false;

	/**
	 * 把版本号字符串(如 "1.2.1"、"2.9")转成可比较的数字，最多支持 3 段。
	 * 解析失败时返回 NaN，任何比较结果都为 false，不会误报更新。
	 */
	static function toVersionNumber(value:String):Float
	{
		if (value == null)
			return Math.NaN;

		var parts:Array<String> = value.split('.');
		var result:Float = 0;
		var weight:Float = 1000000;
		var parsed:Bool = false;

		for (i in 0...3)
		{
			if (i >= parts.length)
				break;

			var part:Null<Int> = Std.parseInt(parts[i]);
			if (part == null || part < 0)
				break;

			result += part * weight;
			weight /= 1000;
			parsed = true;
		}

		return parsed ? result : Math.NaN;
	}

	function changeState() {
		if (changingState)
			return;
		changingState = true;
		if (mustUpdate && !OutdatedState.leftState)
		{
			FlxTransitionableState.skipNextTransIn = true;
			FlxTransitionableState.skipNextTransOut = true;
			MusicBeatState.switchState(new OutdatedState());
		}
		else
		{
			FlxTransitionableState.skipNextTransIn = true;
			FlxTransitionableState.skipNextTransOut = true;
			MusicBeatState.switchState(new TitleState());
		}
	}
}
