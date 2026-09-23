package mobile.objects;

import flixel.FlxG;
import flixel.FlxCamera;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.group.FlxSpriteGroup;
import flixel.input.keyboard.FlxKey;
import flixel.util.FlxColor;
import flixel.util.FlxDestroyUtil;
import flixel.math.FlxPoint;

import openfl.display.Shape;
import openfl.display.BitmapData;

import general.backend.ClientPrefs;
import general.backend.Paths;
import general.backend.language.Language;
import mobile.objects.EditorMobileKeyData; // EMKButton 等次类型与本模块同文件

/**
 * Editor 内的自定义移动端按键覆盖层。
 *
 * - 从 FuckYouNFEMobile/<EditorId>NewFuckingButtonMobile.json 读取（缺失 = 空，仅隐藏默认键）；
 * - 每个按键 = 自绘圆角块 + 标签，坐标与外部窗口画布一致（左上角 [0,0]，1280x720 逻辑空间）；
 * - 覆盖层挂在自己的固定 HUD 相机上，不受谱面相机滚动/缩放影响；
 * - 触摸/鼠标按下 = 向 FlxG.keys 注入该键的 click 组合键（与默认虚拟按键同机制）；
 * - 父键（isFather + CanSwitch=T）：自身不输出；按住期间子键输出被 Switch 规则切换；
 *   SwitchNum：按 1 次开启（锁存），开启后再按满 N 次关闭（N=1 即再按一次切回）；
 *   长按只做临时切换，松手不改变锁存状态；
 * - 文件变化约 0.8 秒内自动热重载。
 */
class EditorMobileKeyOverlay extends FlxSpriteGroup
{
	public var editorId(default, null):String = '';

	static final TAP_TIME:Float = 0.28;

	// ---- 注入调试日志（环境变量 NOVAF_EMK_DEBUG=1 时开启，写到 FuckYouNFEMobile/emk_inject.log）----
	static var dbgChecked:Bool = false;
	static var dbgOn:Bool = false;

	static function debugOn():Bool
	{
		if (!dbgChecked)
		{
			dbgChecked = true;
			#if sys
			try
			{
				dbgOn = Sys.getEnv('NOVAF_EMK_DEBUG') == '1';
			}
			catch (e:Dynamic) {}
			#end
		}
		return dbgOn;
	}

	function dbgLine(msg:String):Void
	{
		if (!debugOn()) return;
		try
		{
			var f = sys.io.File.append(EditorMobileKeys.getFileDir() + 'emk_inject.log', false);
			f.writeString(Date.now().toString() + ' ' + msg + '\n');
			f.close();
		}
		catch (e:Dynamic) {}
	}

	var overlayCam:FlxCamera;

	var defs:Array<EMKButton> = [];
	var views:Array<EMKView> = [];

	var watchTimer:Float = 0;
	var fileMtime:Float = -1;
	var curHeldKeys:Array<FlxKey> = [];

	var keyCache:Map<String, FlxKey> = new Map();

	public function new(editorId:String)
	{
		super();
		this.editorId = editorId;
		scrollFactor.set();

		// 固定 HUD 相机：与谱面主相机隔离，坐标 = FlxG 逻辑屏幕坐标
		overlayCam = new FlxCamera(0, 0, Std.int(FlxG.width), Std.int(FlxG.height));
		overlayCam.bgColor.alpha = 0;
		FlxG.cameras.add(overlayCam, false);
		cameras = [overlayCam];

		reloadFromFile();
	}

	/** 是否应该显示（桌面端跟随 needMobileControl，移动端恒显示） */
	public function refreshVisibility():Void
	{
		var show:Bool = true;
		#if desktop
		show = ClientPrefs.data.needMobileControl;
		#end
		visible = show;
		active = show;
		alpha = ClientPrefs.data.controlsAlpha + 0.000001;
	}

	/** ★ 挂起：释放所有注入键并隐藏（编辑器打开子状态如 ESC 试玩时调用，
	 *  避免编辑器按键与试玩界面混合显示、以及按住中的组合键残留影响后续点击） */
	public function suspend():Void
	{
		releaseAllHeldKeys();
		visible = false;
		active = false;
	}

	/** ★ 命中检测：坐标 (x,y)（逻辑屏幕坐标）是否落在某个按键上（供编辑器判断“本次点击被虚拟键吃掉”） */
	public function hitTest(x:Float, y:Float):Bool
	{
		for (view in views)
		{
			if (view == null || view.def == null) continue;
			if (x >= view.def.x && x <= view.def.x + view.def.w && y >= view.def.y && y <= view.def.y + view.def.h)
				return true;
		}
		return false;
	}

	// ==================== 加载 ====================

	public function reloadFromFile():Void
	{
		var path:String = EditorMobileKeys.getFilePath(editorId);
		fileMtime = statMtime(path);

		// 回退链：存储文件 → APK 内置（随包发布的 Windows 配置）→ 默认模板键位。
		// 保证任何 Editor 在功能开启时都有一组可用键位，不会空白。
		var text:Null<String> = EditorMobileKeys.readFileWithFallback(editorId);
		var newDefs:Array<EMKButton> = [];
		if (text != null && text.length > 0)
		{
			try
			{
				var doc:Dynamic = haxe.Json.parse(text);
				var rawBtns:Dynamic = Reflect.field(doc, 'buttons');
				if (rawBtns != null && Std.isOfType(rawBtns, Array))
				{
					var seen:Array<String> = [];
					for (raw in cast(rawBtns, Array<Dynamic>))
					{
						var def:EMKButton = EditorMobileKeyData.parseButton(raw);
						if (def.name == null || def.name == '') continue;
						if (seen.contains(def.name)) continue;
						seen.push(def.name);
						newDefs.push(def);
					}
				}
			}
			catch (e:Dynamic)
			{
				trace('[EditorMobileKeyOverlay] parse failed for $path: $e');
			}
		}

		defs = newDefs;
		rebuildViews();
	}

	function statMtime(path:String):Float
	{
		try
		{
			if (FileSystem.exists(path))
			{
				var st = FileSystem.stat(path);
				if (st != null && st.mtime != null)
					return st.mtime.getTime();
			}
		}
		catch (e:Dynamic) {}
		return -1;
	}

	function rebuildViews():Void
	{
		releaseAllHeldKeys();

		for (view in views)
		{
			try
			{
				remove(view.sprite);
				remove(view.label);
				view.sprite.destroy();
				view.label.destroy();
			}
			catch (e:Dynamic) {}
		}
		views = [];

		for (def in defs)
		{
			if (def.w <= 0 || def.h <= 0) continue;
			var view = new EMKView(def);

			view.sprite = new FlxSprite(def.x, def.y);
			view.sprite.loadGraphic(roundedGraphic(def.w, def.h));
			view.sprite.color = def.color;
			view.sprite.scrollFactor.set();
			view.sprite.antialiasing = ClientPrefs.data.antialiasing;
			add(view.sprite);

			view.label = new FlxText(def.x + 2, def.y + 2, def.w - 4, def.name, 14);
			// 文字颜色：textColor（老文件缺省 = 白 0xFFFFFFFF）
			view.label.setFormat(font(), 14, def.textColor, CENTER, FlxTextBorderStyle.OUTLINE, 0xFF000000);
			view.label.borderStyle = FlxTextBorderStyle.OUTLINE;
			view.label.scrollFactor.set();
			view.label.antialiasing = ClientPrefs.data.antialiasing;
			add(view.label);

			views.push(view);
		}
	}

	static function font():String
	{
		var name:String = 'chillax';
		try
		{
			var n:String = Language.get('fontName', 'main');
			if (n != null && n != '' && n.indexOf('fontName') == -1 && n.indexOf('404') == -1)
				name = n;
		}
		catch (e:Dynamic) {}
		return Paths.font(name + '.ttf');
	}

	static function roundedGraphic(w:Int, h:Int):BitmapData
	{
		var shape:Shape = new Shape();
		shape.graphics.beginFill(0xFFFFFF, 0.55);
		shape.graphics.drawRoundRect(0, 0, w, h, w / 3, h / 3);
		shape.graphics.endFill();

		var bmp:BitmapData = new BitmapData(w, h, true, 0x00000000);
		bmp.draw(shape);

		var border:Shape = new Shape();
		border.graphics.lineStyle(3, 0xFFFFFF, 1);
		border.graphics.drawRoundRect(1.5, 1.5, w - 3, h - 3, w / 3 - 2, h / 3 - 2);
		bmp.draw(border);
		return bmp;
	}

	// ==================== 更新 ====================

	/** 固定 HUD 相机被外部销毁（如 MusicBeatState.initPsychCamera 的 FlxG.cameras.reset）时自动重建 */
	function ensureOverlayCam():Void
	{
		if (overlayCam != null && overlayCam.scroll != null)
			return;
		// overlayCam 已被 destroy（scroll 被 FlxDestroyUtil.put 置 null）：
		// 若仍在 FlxG.cameras 里先移除，再重建固定 HUD 相机
		if (overlayCam != null)
		{
			try
			{
				FlxG.cameras.remove(overlayCam, false);
			}
			catch (e:Dynamic) {}
			overlayCam = null;
		}
		overlayCam = new FlxCamera(0, 0, Std.int(FlxG.width), Std.int(FlxG.height));
		overlayCam.bgColor.alpha = 0;
		FlxG.cameras.add(overlayCam, false);
		cameras = [overlayCam];
		dbgLine('OVERLAY-CAM-REBUILT');
	}

	override function update(elapsed:Float)
	{
		if (visible && active)
		{
			ensureOverlayCam();
			watchTimer += elapsed;
			if (watchTimer >= 0.8)
			{
				watchTimer = 0;
				var mtime:Float = statMtime(EditorMobileKeys.getFilePath(editorId));
				if (mtime != fileMtime)
					reloadFromFile();
			}
			pollPointers();
			updateViews(elapsed);
			updateLabels();
			refreshInjectedKeys();
		}
		super.update(elapsed);
	}

	// ---- 指针收集（overlayCam 固定，world == 逻辑屏幕坐标） ----

	function pollPointers():Void
	{
		for (view in views)
			view.wasPressed = view.pressed;

		// 先收集“当前仍按住”的指针：若某个已按下的 view 找不到它的指针
		// （触点丢失/切出窗口等），强制释放，避免按键卡死。
		var downPointers:Array<Int> = [];
		var touches = FlxG.touches.list;
		if (touches != null)
			for (touch in touches)
				if (touch != null && touch.pressed)
					downPointers.push(touch.touchPointID);
		#if desktop
		if (FlxG.mouse != null && FlxG.mouse.pressed)
			downPointers.push(-1);
		#end
		for (view in views)
		{
			if (view.pressed && !downPointers.contains(view.pointerId))
			{
				view.pressed = false;
				view.pointerId = -2;
				view.justReleased = true;
				dbgLine('UP-FORCED name=' + view.def.name);
			}
		}

		if (touches != null)
		{
			for (touch in touches)
			{
				if (touch == null) continue;
				var pt:FlxPoint = touch.getWorldPosition(overlayCam, FlxPoint.get());
				var x:Float = pt.x;
				var y:Float = pt.y;
				pt.put();
				applyPointer(touch.touchPointID, x, y, touch.justPressed, touch.pressed, touch.justReleased);
			}
		}

		// 桌面/模拟器：鼠标当指针（便于在 Windows 上直接测试）
		#if desktop
		var mouse = FlxG.mouse;
		if (mouse != null && (mouse.justPressed || mouse.pressed || mouse.justReleased))
		{
			var pt:FlxPoint = mouse.getWorldPosition(overlayCam, FlxPoint.get());
			var x:Float = pt.x;
			var y:Float = pt.y;
			pt.put();
			applyPointer(-1, x, y, mouse.justPressed, mouse.pressed, mouse.justReleased);
		}
		#end
	}

	function applyPointer(pointerId:Int, x:Float, y:Float, justDown:Bool, down:Bool, justUp:Bool):Void
	{
		if (justDown)
		{
			// 命中检测：最上层（后 add）优先
			var hit:EMKView = null;
			for (i in 0...views.length)
			{
				var view = views[i];
				if (view.pressed) continue; // 已被其它手指按住
				if (x >= view.def.x && x <= view.def.x + view.def.w && y >= view.def.y && y <= view.def.y + view.def.h)
					hit = view; // 越靠后（越上层）越优先
			}
			if (hit != null)
			{
				hit.pressed = true;
				hit.pointerId = pointerId;
				hit.holdTime = 0;
				hit.justPressed = true;
				dbgLine('DOWN ptr=' + pointerId + ' name=' + hit.def.name + ' at=' + Math.round(x) + ',' + Math.round(y));
			}
			else
			{
				dbgLine('DOWN-NOHIT ptr=' + pointerId + ' at=' + Math.round(x) + ',' + Math.round(y));
			}
		}

		for (view in views)
		{
			// 只处理“正被这个指针按住”的键：空闲键 pointerId 默认 -2，
			// 绝不因鼠标指针 id=-1 或滑出判定被误释放/误触发 tap
			if (!view.pressed || view.pointerId != pointerId) continue;

			if (justUp)
			{
				view.pressed = false;
				view.pointerId = -2;
				view.justReleased = true;
				dbgLine('UP ptr=' + pointerId + ' name=' + view.def.name);
				continue;
			}

			if (down && !justDown)
			{
				// 滑出太远视为松开
				var margin:Float = 40;
				if (x < view.def.x - margin || x > view.def.x + view.def.w + margin
					|| y < view.def.y - margin || y > view.def.y + view.def.h + margin)
				{
					view.pressed = false;
					view.pointerId = -2;
					view.justReleased = true;
					dbgLine('UP-SLIDEOUT name=' + view.def.name);
				}
			}
		}
	}

	// ---- 父键轮换档逻辑 ----
	// 档模型：SwitchNum/子键档列表定义 N 档。短按一次父键 → 档位 +1；
	// 到第 N 档后再按一次回到 0（默认/原输出）。按住父键期间 = 至少临时启用档 1。
	// 例：SwitchNum=1（1 档）：按一下开(档1)、再按一下回默认。SwitchNum=2：两档轮换。

	/** 父键定义的最大档数（按各子键档列表长度的最大值；无配置按 1） */
	static function maxStageOf(def:EMKButton):Int
	{
		var m:Int = 1;
		for (child in def.fuckItKey)
		{
			var stages = def.switchMap.get(child);
			if (stages != null && stages.length > m) m = stages.length;
		}
		return m;
	}

	/** 父键“当前生效档”：按住 = 至少档 1（临时）；锁存 = stage */
	static function effStageOf(view:EMKView):Int
	{
		var s:Int = view.stage;
		if (view.pressed && s < 1) s = 1;
		return s;
	}

	function updateViews(elapsed:Float):Void
	{
		for (view in views)
		{
			if (view.pressed)
				view.holdTime += elapsed;

			if (view.justReleased)
			{
				var def:EMKButton = view.def;
				if (def.isFather && def.canSwitch)
				{
					// 短按 = 档位 +1（轮换）；长按 = 只做临时切换，不改档位
					if (view.holdTime < TAP_TIME)
					{
						var maxStage:Int = maxStageOf(def);
						var oldStage:Int = view.stage;
						view.stage = (view.stage + 1) % (maxStage + 1);
						dbgLine('TAP father=' + def.name + ' stage=' + oldStage + '->' + view.stage + ' max=' + maxStage + ' hold=' + view.holdTime);
					}
					else
					{
						dbgLine('RELEASE-LONG father=' + def.name + ' stage=' + view.stage + ' hold=' + view.holdTime);
					}
				}
				view.justReleased = false;
			}

			if (view.justPressed)
				view.justPressed = false;
		}
	}

	/** 子键被父键切档后的显示名（按当前语言；没有名字返回 ''） */
	function switchedLabel(childDef:EMKButton):String
	{
		for (father in views)
		{
			if (!father.def.isFather || !father.def.canSwitch) continue;
			if (father.stage <= 0 && !father.pressed) continue; // 未生效
			if (!father.def.fuckItKey.contains(childDef.name)) continue;
			var stages = father.def.switchMap.get(childDef.name);
			if (stages == null) continue;
			var eff:Int = effStageOf(father);
			if (eff <= 0 || eff > stages.length) continue;
			return stages[eff - 1].displayName(ClientPrefs.data.language);
		}
		return '';
	}

	/** 每帧同步按钮文字：父键显示 ◉档位；被切档的子键显示该档的多语言名称（无名称保持原名） */
	function updateLabels():Void
	{
		for (view in views)
		{
			if (view.label == null) continue;
			var def:EMKButton = view.def;
			var text:String = def.name;
			if (def.isFather && def.canSwitch)
			{
				text = def.name + (view.stage > 0 ? ' ◉' + view.stage : '');
			}
			else
			{
				var stageName:String = switchedLabel(def);
				if (stageName != null && stageName != '') text = stageName;
			}
			if (view.label.text != text)
				view.label.text = text;
		}
	}

	// ---- 组合键注入 ----

	function refreshInjectedKeys():Void
	{
		var desired:Array<FlxKey> = [];

		for (view in views)
		{
			if (!view.pressed) continue;
			var def:EMKButton = view.def;
			if (def.isFather)
			{
				// CanSwitch 父键不输出；普通父键按 click 输出
				if (!def.canSwitch)
					pushKeyList(desired, keysOf(def));
				continue;
			}

			// 普通键 / 子键：默认输出 click；生效父键把该子键切到第 N 档时用该档输出
			var out:Array<FlxKey> = keysOf(def);
			var outSrc:String = 'default';
			for (father in views)
			{
				if (!father.def.isFather || !father.def.canSwitch) continue;
				if (father.stage <= 0 && !father.pressed) continue; // 未生效
				if (!father.def.fuckItKey.contains(def.name)) continue;
				var stages = father.def.switchMap.get(def.name);
				if (stages == null || stages.length == 0) continue;
				var eff:Int = effStageOf(father);
				if (eff <= 0) continue;
				if (eff <= stages.length)
				{
					var stageKeys:Array<FlxKey> = keysOfArray(stages[eff - 1].keys);
					if (stageKeys.length > 0)
					{
						out = stageKeys;
						outSrc = 'father=' + father.def.name + ' eff=' + eff;
					}
					break;
				}
				// eff > stages.length：该子键档数不够，保持原输出并继续找其它父键
			}
			if (view.justPressed)
			{
				var names:Array<String> = [];
				for (k in out) names.push(Std.string(k));
				dbgLine('OUT child=' + def.name + ' src=' + outSrc + ' keys=[' + names.join(',') + ']');
			}
			pushKeyList(desired, out);
		}

		// diff：释放不再需要的，按下新增的
		var changed:Bool = desired.length != curHeldKeys.length;
		if (!changed)
		{
			for (i in 0...desired.length)
				if (desired[i] != curHeldKeys[i]) { changed = true; break; }
		}
		for (key in curHeldKeys)
			if (!desired.contains(key))
				releaseKey(key);
		// 本帧“新按下”的键：保持 JUST_PRESSED(2) 直到编辑器检查
		var freshKeys:Array<FlxKey> = [];
		for (key in desired)
			if (!curHeldKeys.contains(key))
			{
				pressKey(key);
				freshKeys.push(key);
			}
		curHeldKeys = desired.copy();
		if (changed)
		{
			var names:Array<String> = [];
			for (k in curHeldKeys) names.push(Std.string(k));
			dbgLine('INJECT keys=[' + names.join(',') + ']');
		}

		// 持续按住时维持 PRESSED（防止被其它输入清零）。
		// 关键：非“本帧新按”的键若还停留在 JUST_PRESSED(2) 要立刻归一为 1，
		// 否则编辑器会把同一次按下当成两帧 justPressed（表现为“按一下触发两次”）。
		for (key in curHeldKeys)
		{
			if (freshKeys.contains(key)) continue;
			var k = getKeyObj(key);
			if (k != null && k.current != 1)
				k.current = 1;
		}
	}

	function pushKeyList(target:Array<FlxKey>, list:Array<FlxKey>):Void
	{
		for (k in list)
			if (!target.contains(k))
				target.push(k);
	}

	function keysOf(def:EMKButton):Array<FlxKey>
	{
		var out:Array<FlxKey> = [];
		for (name in def.click)
		{
			var k:FlxKey = toFlxKey(name);
			if (k != FlxKey.NONE && !out.contains(k)) out.push(k);
		}
		return out;
	}

	function keysOfArray(names:Array<String>):Array<FlxKey>
	{
		var out:Array<FlxKey> = [];
		for (name in names)
		{
			var k:FlxKey = toFlxKey(name);
			if (k != FlxKey.NONE && !out.contains(k)) out.push(k);
		}
		return out;
	}

	function toFlxKey(name:String):FlxKey
	{
		if (name == null || name == '') return FlxKey.NONE;
		var cached:Dynamic = keyCache.get(name);
		if (cached != null) return cast cached;
		var k:FlxKey = toFlxKeyStatic(name);
		keyCache.set(name, k);
		return k;
	}

	static function toFlxKeyStatic(name:String):FlxKey
	{
		if (name == null || name == '') return FlxKey.NONE;
		try
		{
			var maybe:Dynamic = FlxKey.fromString(name.toUpperCase());
			if (maybe != null) return cast maybe;
		}
		catch (e:Dynamic) {}
		return FlxKey.NONE;
	}

	// ---- 直接改 FlxG.keys 内部状态（与默认虚拟按键同一机制） ----

	static function getKeyObj(key:FlxKey):Dynamic
	{
		try
		{
			return @:privateAccess FlxG.keys.getKey(key);
		}
		catch (e:Dynamic)
		{
			return null;
		}
	}

	static function pressKey(key:FlxKey):Void
	{
		if (key == FlxKey.NONE) return;
		var k = getKeyObj(key);
		if (k != null && k.current != 1 && k.current != 2)
			k.current = 2; // JUST_PRESSED
	}

	static function releaseKey(key:FlxKey):Void
	{
		if (key == FlxKey.NONE) return;
		var k = getKeyObj(key);
		if (k != null)
			k.current = -1; // JUST_RELEASED
	}

	public function releaseAllHeldKeys():Void
	{
		for (key in curHeldKeys)
			releaseKey(key);
		curHeldKeys = [];
	}

	override function destroy():Void
	{
		releaseAllHeldKeys();
		if (overlayCam != null)
		{
			try
			{
				FlxG.cameras.remove(overlayCam, false);
			}
			catch (e:Dynamic) {}
			overlayCam = null;
		}
		super.destroy();
	}
}

/** 单个按键的视图 + 运行时状态 */
private class EMKView
{
	public var def:EMKButton;
	public var sprite:FlxSprite;
	public var label:FlxText;

	public var pressed:Bool = false;
	public var wasPressed:Bool = false;
	public var justPressed:Bool = false;
	public var justReleased:Bool = false;
	public var pointerId:Int = -2; // -2 = 空闲（鼠标指针 id 是 -1，不能撞号）
	public var holdTime:Float = 0;

	/** 父键当前档位：0 = 默认/原输出；1..N = 第几档（短按一次 +1，N 档后再按回 0） */
	public var stage:Int = 0;

	public function new(def:EMKButton)
	{
		this.def = def;
	}
}
