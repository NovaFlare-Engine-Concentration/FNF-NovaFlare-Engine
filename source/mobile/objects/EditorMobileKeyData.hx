package mobile.objects;

import haxe.Json;
import flixel.util.FlxColor;
import flixel.input.keyboard.FlxKey;
import mobile.flixel.FlxVirtualPad;
import mobile.backend.Data;
/**
 * 移动端 Editor 自定义按键的数据层。
 *
 * 文档结构（标准 JSON，与外部窗口保持一致）：
 * {
 *   "editor": "ChartEditor",
 *   "screenW": 1280, "screenH": 720,
 *   "buttons": [ {
 *      "name": "A",            // 按键唯一名（“Button.click” 里的 Button）
 *      "click": ["ENTER"],     // Button.click = 绑定组合键数组；多个 = 同时按下（可组合）
 *      "x": 1148, "y": 585,    // 左上角 [0,0] 基准
 *      "w": 120, "h": 120,
 *      "color": "#FF0000",
 *      "isFather": true,       // 仅父键
 *      "FuckItKey": ["A","B"], // 仅父键：子键名列表
 *      "CanSwitch": true,      // 仅父键；T = 父键不输出 click，只切换子键键值对
 *      "SwitchNum": 1,         // CanSwitch=T 时默认 1、最小 1：按 1 次开启切换，开启后每按 1 次计数，按满 N 次关闭
 *      "Switch": { "A": { "ENTER": ["SHIFT","ENTER"] } }  // 子键名 → { 原绑定: 新绑定 }
 *   } ]
 * }
 * 省略规则：非父键不写 isFather 之后字段；CanSwitch=F 不写 SwitchNum / Switch。
 */
class EditorMobileKeyData
{
	public static inline final SCREEN_W:Int = 1280;
	public static inline final SCREEN_H:Int = 720;

	// =====================================================================
	// 各 Editor 默认移动端虚拟按键的「键值对语义」表。
	// 顺序必须与 FlxVirtualPad 对应模式的按钮创建顺序完全一致
	// （DPad 先、Action 后）；模板生成时按序 zip 到每个按钮上：
	//   name = 推荐显示名；keys = 该键在编辑器代码里等价的固定键盘键/组合
	//   （引擎自定义模式走键盘分支，注入这些键即可还原原版行为）；
	//   desc = 中文含义，仅作为模板/页面里的提示。
	// =====================================================================
	static final S_CHART:Array<EMKSem> = [
		new EMKSem('UP', ['W'], '向上滚动时间轴'),
		new EMKSem('LEFT', ['A'], '上一小节（按住 Y 加速）'),
		new EMKSem('RIGHT', ['D'], '下一小节（按住 Y 加速）'),
		new EMKSem('DOWN', ['S'], '向下滚动时间轴'),
		new EMKSem('S', ['L'], '切换 Note 放置/移动模式'),
		new EMKSem('G', ['TAB'], '打开/聚焦顶部菜单'),
		new EMKSem('K', [], '原版布局存在但未绑定操作（可删除）'),
		new EMKSem('L', [], '原版布局存在但未绑定操作（可删除）'),
		new EMKSem('P', ['Q'], '缩短选中 Note 尾长'),
		new EMKSem('E', ['E'], '加长选中 Note 尾长'),
		new EMKSem('V', ['CONTROL', 'Z'], '撤销（原版长按另含变速重置）'),
		new EMKSem('D', ['X'], '放大网格'),
		new EMKSem('X', ['SPACE'], '播放/暂停歌曲'),
		new EMKSem('C', ['ESCAPE'], '试玩当前谱面（编辑器内）'),
		new EMKSem('Y', ['SHIFT'], '按住 = 4倍速 / 自由放置'),
		new EMKSem('B', ['BACKSPACE'], '退出编谱器（带保存提示）'),
		new EMKSem('Z', ['Z'], '缩小网格'),
		new EMKSem('A', ['ENTER'], '整曲播放')
	];

	// 以下各表由源码梳理后填写（顺序与对应模式按钮一致）
	static final S_WEEK:Array<EMKSem> = [
		new EMKSem('UP', [], '原版布局中存在但未绑定操作（代码无引用，仅保留布局）'),
		new EMKSem('DOWN', [], '原版布局中存在但未绑定操作（代码无引用，仅保留布局）'),
		new EMKSem('B', ['ESCAPE'], '返回：关闭当前打开的编辑面板；无面板时退出周目编辑器（并列检查 ESCAPE）')
	];

	static final S_DIALOGUE:Array<EMKSem> = [
		new EMKSem('UP', ['W'], '切换上一个角色动画/表情（动画列表向上滚动）'),
		new EMKSem('LEFT', ['A'], '切换到上一条对话行'),
		new EMKSem('RIGHT', ['D'], '切换至下一条对话行'),
		new EMKSem('DOWN', ['S'], '切换下一个角色动画/表情（动画列表向下滚动）'),
		new EMKSem('X', ['P'], '在当前对话行之后插入一条新行并选中'),
		new EMKSem('B', ['ESCAPE'], '退出对话编辑器，返回主编辑器菜单'),
		new EMKSem('Y', ['SPACE'], '重播/刷新当前对话行文字（重新打字动画）'),
		new EMKSem('A', ['O'], '删除当前对话行')
	];

	static final S_DIALOGUE_CHAR:Array<EMKSem> = [
		new EMKSem('UP', ['UP'], 'Animations 页：↑ 微调选中动画的 Idle/闲置 偏移（Y 轴，按住 Z 步长 ×10）'),
		new EMKSem('LEFT', ['LEFT'], 'Animations 页：← 微调 Idle/闲置 偏移（X 轴）'),
		new EMKSem('RIGHT', ['RIGHT'], 'Animations 页：→ 微调 Idle/闲置 偏移（X 轴）'),
		new EMKSem('DOWN', ['DOWN'], 'Animations 页：↓ 微调 Idle/闲置 偏移（Y 轴）'),
		new EMKSem('UP2', ['W'], 'Animations 页：W 微调选中动画的 Loop/循环 偏移（Y 轴）'),
		new EMKSem('LEFT2', ['A'], 'Animations 页：A 微调 Loop/循环 偏移（X 轴）'),
		new EMKSem('RIGHT2', ['D'], 'Animations 页：D 微调 Loop/循环 偏移（X 轴）'),
		new EMKSem('DOWN2', ['S'], 'Animations 页：S 微调 Loop/循环 偏移（Y 轴）'),
		new EMKSem('X', ['R'], '重置相机视图：缩放恢复 1、内容位置归零并显示 HUD'),
		new EMKSem('C', [], '原版布局中存在但未绑定操作（代码无引用，仅保留布局）'),
		new EMKSem('Y', ['H'], 'Character 页：切换对话气泡 HUD 显示；Animations 页：循环切换 Loop/Idle 幽灵显示'),
		new EMKSem('B', ['ESCAPE'], '退出对话立绘编辑器，返回主编辑器菜单'),
		new EMKSem('Z', ['SHIFT'], '按住加速：角色移动速度与偏移微调步长提升（×10）'),
		new EMKSem('A', ['SPACE'], 'Character 页：重播当前动画并重置对话文字打字')
	];

	static final S_MENU_CHAR:Array<EMKSem> = [
		new EMKSem('UP', ['UP'], '调整选中角色偏移 Y +1（按住 A/SHIFT 为 ×10）'),
		new EMKSem('LEFT', ['LEFT'], '调整选中角色偏移 X +1'),
		new EMKSem('RIGHT', ['RIGHT'], '调整选中角色偏移 X -1'),
		new EMKSem('DOWN', ['DOWN'], '调整选中角色偏移 Y -1'),
		new EMKSem('C', ['SPACE'], '选中 Boyfriend 时播放 confirm(Start Press) 动画预览'),
		new EMKSem('B', ['ESCAPE'], '返回：面板开着先收起面板，否则退出到主编辑器菜单'),
		new EMKSem('A', ['SHIFT'], '按住 = 偏移步进 ×10 的修饰键（原版把 accept 键复用为加速键）')
	];

	static final S_NOTE_SPLASH:Array<EMKSem> = [
		new EMKSem('UP', ['UP'], '调整当前动画 offset Y +1（按住 Z 为 ×10，支持长按连发）'),
		new EMKSem('LEFT', ['LEFT'], '调整当前动画 offset X +1（按住 Z 为 ×10）'),
		new EMKSem('RIGHT', ['RIGHT'], '调整当前动画 offset X -1（按住 Z 为 ×10）'),
		new EMKSem('DOWN', ['DOWN'], '调整当前动画 offset Y -1（按住 Z 为 ×10）'),
		new EMKSem('B', ['BACKSPACE', 'ESCAPE'], '返回/退出到主编辑器菜单（back 键位）'),
		new EMKSem('E', [], '原版布局中存在但未绑定操作（可删除）'),
		new EMKSem('X', [], '原版布局中存在但未绑定操作（可删除）'),
		new EMKSem('Y', [], '原版布局中存在但未绑定操作（可删除）'),
		new EMKSem('Z', ['SHIFT'], '按住 = 偏移移动 ×10（另支持手柄左肩键）'),
		new EMKSem('A', [], '原版布局中存在但未绑定操作（可删除）'),
		new EMKSem('C', ['CONTROL', 'C'], '复制当前动画偏移'),
		new EMKSem('V', ['CONTROL', 'V'], '粘贴已复制的偏移到当前动画')
	];

	static final S_NOTE_SPLASH_DEBUG:Array<EMKSem> = [
		// 注意：这一组方向键是“错位映射”——UP/LEFT/RIGHT/DOWN 分别等价 A/S/W/D
		new EMKSem('UP', ['A'], '切换选中上一列 Note'),
		new EMKSem('LEFT', ['S'], '切换到上一个动画'),
		new EMKSem('RIGHT', ['W'], '切换到下一个动画'),
		new EMKSem('DOWN', ['D'], '切换选中下一列 Note'),
		new EMKSem('UP2', ['UP'], '调整当前偏移 Y +1（按住 Z/SHIFT 为 ×10）'),
		new EMKSem('LEFT2', ['LEFT'], '调整当前偏移 X -1（按住 Z/SHIFT 为 ×10）'),
		new EMKSem('RIGHT2', ['RIGHT'], '调整当前偏移 X +1（按住 Z/SHIFT 为 ×10）'),
		new EMKSem('DOWN2', ['DOWN'], '调整当前偏移 Y -1（按住 Z/SHIFT 为 ×10）'),
		new EMKSem('B', ['BACKSPACE', 'ESCAPE'], '返回/退出到主编辑器菜单（back 键位）'),
		new EMKSem('E', ['E'], '强制播放帧 +1'),
		new EMKSem('X', ['Q'], '强制播放帧 -1'),
		new EMKSem('Y', ['SPACE'], '重置/回到当前动画'),
		new EMKSem('Z', ['SHIFT'], '按住 = 偏移移动 ×10'),
		new EMKSem('A', ['ENTER'], '保存到 txt（0.5 秒内连按两次确认）'),
		new EMKSem('C', ['CONTROL', 'C'], '复制当前选中偏移'),
		new EMKSem('V', ['CONTROL', 'V'], '粘贴已复制偏移到当前选中项')
	];

	static final S_CHARACTER:Array<EMKSem> = [
		new EMKSem('UP', ['UP'], '微调动画 offset 上移；与 G 同按 = 上移摄像机（桌面 I）'),
		new EMKSem('LEFT', ['LEFT'], '微调动画 offset 左移；与 G 同按 = 左移摄像机（桌面 J）'),
		new EMKSem('RIGHT', ['RIGHT'], '微调动画 offset 右移；与 G 同按 = 右移摄像机（桌面 L）'),
		new EMKSem('DOWN', ['DOWN'], '微调动画 offset 下移；与 G 同按 = 下移摄像机（桌面 K）'),
		new EMKSem('V', ['W'], '切换到上一个动画'),
		new EMKSem('D', ['S'], '切换到下一个动画'),
		new EMKSem('X', ['E'], '放大摄像机（按住连续放大）'),
		new EMKSem('C', ['SHIFT'], '按住加速：位移/缩放步长 ×4（offset 长按 ×10）'),
		new EMKSem('S', ['F12'], '显示/隐藏参照剪影'),
		new EMKSem('G', [], '修饰键：按住 G + 方向键 = 平移摄像机（对应桌面 I/J/K/L）；单独按无键盘等价——建议把它设成父键(CanSwitch)来切换方向键输出'),
		new EMKSem('F', ['F1'], '打开顶栏帮助菜单'),
		new EMKSem('Y', ['Q'], '缩小摄像机（按住连续缩小）'),
		new EMKSem('B', ['ESCAPE'], '返回/退出角色编辑器，回到主编辑器菜单'),
		new EMKSem('Z', ['R'], '重置摄像机缩放为 1x'),
		new EMKSem('A', ['CONTROL', 'V'], '粘贴已复制的动画 offset（桌面 Ctrl+V）')
	];

	static final S_STAGE:Array<EMKSem> = [
		new EMKSem('UP', ['UP'], '移动选中精灵上移 5px（按住 C 为 ×4；与 G 同按 = 上移摄像机，桌面 I）'),
		new EMKSem('LEFT', ['LEFT'], '移动选中精灵左移 5px（按住 C 为 ×4；与 G 同按 = 左移摄像机，桌面 J）'),
		new EMKSem('RIGHT', ['RIGHT'], '移动选中精灵右移 5px（按住 C 为 ×4；与 G 同按 = 右移摄像机，桌面 L）'),
		new EMKSem('DOWN', ['DOWN'], '移动选中精灵下移 5px（按住 C 为 ×4；与 G 同按 = 下移摄像机，桌面 K）'),
		new EMKSem('V', ['W'], '对象列表选中上一个精灵'),
		new EMKSem('D', ['S'], '对象列表选中下一个精灵'),
		new EMKSem('X', ['E'], '放大摄像机（按住连续放大）'),
		new EMKSem('C', ['SHIFT'], '按住加速：移动/缩放步长 ×4'),
		new EMKSem('S', ['F12'], '显示/隐藏选区框'),
		new EMKSem('G', [], '修饰键：按住 G + 方向键 = 平移摄像机（对应桌面 I/J/K/L），按住期间屏蔽精灵移动；单独按无键盘等价——建议把它设成父键(CanSwitch)来切换方向键输出'),
		new EMKSem('F', ['F7'], '打开/关闭帮助浮层'),
		new EMKSem('Y', ['Q'], '缩小摄像机（按住连续缩小）'),
		new EMKSem('B', ['ESCAPE'], '返回：帮助/浮层开着先关闭，否则退出舞台编辑器（带未保存确认）'),
		new EMKSem('Z', ['R'], '重置摄像机缩放为舞台默认值'),
		new EMKSem('A', [], '原版默认布局存在但未被代码引用（无操作；可删除）')
	];

	/** 每个 Editor 一条：外部窗口用的 id / 界面名 / 引擎状态类名 / 默认虚拟按键模板模式 */
	public static final EDITORS:Array<EditorEntry> = [
		new EditorEntry('ChartEditor', '编谱器', 'developer.editors.ChartingState', FlxDPadMode.ChartingStateC, FlxActionMode.ChartingStateC, S_CHART),
		new EditorEntry('CharacterEditor', '角色编辑器', 'developer.editors.CharacterEditorState', FlxDPadMode.LEFT_FULL, FlxActionMode.CHARACTER_EDITOR, S_CHARACTER),
		new EditorEntry('StageEditor', '舞台编辑器', 'developer.editors.StageEditorState', FlxDPadMode.LEFT_FULL, FlxActionMode.CHARACTER_EDITOR, S_STAGE),
		new EditorEntry('WeekEditor', '周目编辑器', 'developer.editors.WeekEditorState', FlxDPadMode.UP_DOWN, FlxActionMode.B, S_WEEK),
		new EditorEntry('DialogueEditor', '对话编辑器', 'developer.editors.DialogueEditorState', FlxDPadMode.LEFT_FULL, FlxActionMode.A_B_X_Y, S_DIALOGUE),
		new EditorEntry('DialogueCharacterEditor', '对话立绘编辑器', 'developer.editors.DialogueCharacterEditorState', FlxDPadMode.DIALOGUE_PORTRAIT, FlxActionMode.DIALOGUE_PORTRAIT, S_DIALOGUE_CHAR),
		new EditorEntry('MenuCharacterEditor', '菜单角色编辑器', 'developer.editors.MenuCharacterEditorState', FlxDPadMode.MENU_CHARACTER, FlxActionMode.MENU_CHARACTER, S_MENU_CHAR),
		new EditorEntry('NoteSplashEditor', 'NoteSplash 编辑器', 'developer.editors.NoteSplashEditorState', FlxDPadMode.LEFT_FULL, FlxActionMode.NOTE_SPLASH_DEBUG, S_NOTE_SPLASH),
		new EditorEntry('NoteSplashDebug', 'NoteSplash 调试', 'developer.editors.NoteSplashEditorState', FlxDPadMode.NOTE_SPLASH_DEBUG, FlxActionMode.NOTE_SPLASH_DEBUG, S_NOTE_SPLASH_DEBUG)
	];

	public static function fileNameOf(editorId:String):String
	{
		return editorId + 'NewFuckingButtonMobile.json';
	}

	public static function entryOf(editorId:String):EditorEntry
	{
		for (entry in EDITORS)
			if (entry.id == editorId)
				return entry;
		return null;
	}

	/** 通过引擎状态类名反查 Editor id（找不到返回 null） */
	public static function editorIdOfClassName(className:String):String
	{
		for (entry in EDITORS)
			if (entry.stateClassName == className)
				return entry.id;
		return null;
	}

	/** 解析按钮定义（对 Dynamic 宽容，字段缺失给默认值） */
	public static function parseButton(raw:Dynamic):EMKButton
	{
		var btn = new EMKButton();
		if (raw == null) return btn;

		btn.name = Reflect.field(raw, 'name');
		if (btn.name == null) btn.name = '';

		btn.click = parseStringArray(Reflect.field(raw, 'click'));

		var descRaw:Dynamic = Reflect.field(raw, 'desc');
		if (descRaw != null) btn.desc = Std.string(descRaw);

		btn.x = readFloat(raw, 'x', 0);
		btn.y = readFloat(raw, 'y', 0);
		btn.w = Std.int(readFloat(raw, 'w', 120));
		btn.h = Std.int(readFloat(raw, 'h', 120));
		if (btn.w < 20) btn.w = 120;
		if (btn.h < 20) btn.h = 120;

		btn.color = parseHexColor(Reflect.field(raw, 'color'), 0xFF8B5CF6);
		// textColor：按键文字颜色，默认白 0xFFFFFFFF（老文件没有该字段也按白处理）
		btn.textColor = parseHexColor(Reflect.field(raw, 'textColor'), 0xFFFFFFFF);

		btn.isFather = Reflect.field(raw, 'isFather') == true;
		btn.canSwitch = Reflect.field(raw, 'CanSwitch') == true;
		btn.switchNum = Std.int(readFloat(raw, 'SwitchNum', btn.canSwitch ? 1 : 0));
		if (btn.canSwitch && btn.switchNum < 1) btn.switchNum = 1; // CanSwitch=T：默认 1 且不小于 1

		btn.fuckItKey = parseStringArray(Reflect.field(raw, 'FuckItKey'));

		// Switch.<子键名> = [ 档1, 档2, ... ]（有序档：每按一次父键切到下一档）
		// 每档可以是：纯键数组 ["I"]，或带显示名的对象 { "keys":["I"], "NameChinese":"摄像机上移", "NameEnglish":"Camera Up" }
		// 兼容旧格式：{ "原绑定": [目标键..] } → 视作单档。
		var swRaw:Dynamic = Reflect.field(raw, 'Switch');
		if (swRaw != null)
		{
			for (childName in Reflect.fields(swRaw))
			{
				var rules:Dynamic = Reflect.field(swRaw, childName);
				if (rules == null) continue;
				var stages:Array<EMKStage> = [];
				if (Std.isOfType(rules, Array))
				{
					for (item in cast(rules, Array<Dynamic>))
					{
						var stage:EMKStage = parseStage(item);
						if (stage != null && stage.keys.length > 0) stages.push(stage);
					}
				}
				else if (Std.isOfType(rules, String))
				{
					// "A,B" 简写 = 单档
					var arr:Array<String> = parseStringArray(rules);
					if (arr.length > 0) stages.push(new EMKStage(arr));
				}
				else
				{
					// 旧对象格式 { "原绑定": [目标..], ... } → 每个目标当一档
					for (fromStr in Reflect.fields(rules))
					{
						var arr:Array<String> = parseStringArray(Reflect.field(rules, fromStr));
						if (arr.length > 0) stages.push(new EMKStage(arr));
					}
				}
				if (stages.length > 0)
					btn.switchMap.set(childName, stages);
			}
		}
		return btn;
	}

	/** 解析单个档：纯键数组 / {keys, NameChinese, NameEnglish} */
	static function parseStage(item:Dynamic):EMKStage
	{
		var stage:EMKStage = null;
		if (Std.isOfType(item, Array))
		{
			var arr:Array<String> = parseStringArray(item);
			if (arr.length > 0) stage = new EMKStage(arr);
		}
		else if (Std.isOfType(item, String))
		{
			var arr:Array<String> = parseStringArray(item);
			if (arr.length > 0) stage = new EMKStage(arr);
		}
		else if (item != null && Reflect.isObject(item))
		{
			var keys:Array<String> = parseStringArray(Reflect.field(item, 'keys'));
			var zhRaw:Dynamic = Reflect.field(item, 'NameChinese');
			var enRaw:Dynamic = Reflect.field(item, 'NameEnglish');
			stage = new EMKStage(keys,
				zhRaw != null ? Std.string(zhRaw) : '',
				enRaw != null ? Std.string(enRaw) : '');
		}
		return stage;
	}

	/** 把定义序列化为文档（按省略规则输出干净 JSON） */
	public static function toJson(editorId:String, buttons:Array<EMKButton>, includeHints:Bool = false):String
	{
		var doc:Array<Dynamic> = [];
		for (btn in buttons)
			doc.push(cleanObject(btn, includeHints));

		var out = {
			editor: editorId,
			screenW: SCREEN_W,
			screenH: SCREEN_H,
			buttons: doc
		};
		return Json.stringify(out, '  ');
	}

	static function cleanObject(btn:EMKButton, includeHints:Bool = false):Dynamic
	{
		var o:Dynamic = {
			name: btn.name,
			click: btn.click.copy(),
			x: Math.round(btn.x),
			y: Math.round(btn.y),
			w: btn.w,
			h: btn.h,
			color: '#' + StringTools.hex((btn.color & 0xFFFFFF), 6).toUpperCase()
		};
		// desc 只是模板/页面里的语义提示，正常保存不写盘
		if (includeHints && btn.desc != null && btn.desc != '')
			Reflect.setField(o, 'desc', btn.desc);
		// textColor：只有非默认白色才写盘（老文件没有该字段 = 白色，向前兼容）
		if (btn.textColor != 0xFFFFFFFF)
			Reflect.setField(o, 'textColor', '#' + StringTools.hex((btn.textColor & 0xFFFFFF), 6).toUpperCase());
		if (btn.isFather)
		{
			Reflect.setField(o, 'isFather', true);
			Reflect.setField(o, 'FuckItKey', btn.fuckItKey.copy());
			Reflect.setField(o, 'CanSwitch', btn.canSwitch);
			if (btn.canSwitch)
			{
				Reflect.setField(o, 'SwitchNum', btn.switchNum < 1 ? 1 : btn.switchNum);
				// Switch.<子键名> = [档1, 档2, ...]（有序）；档无显示名时保持纯键数组（干净/兼容），
				// 有显示名时输出 { "keys":[...], "NameChinese":..., "NameEnglish":... }
				var sw:Dynamic = {};
				for (childName in btn.switchMap.keys())
				{
					if (!btn.fuckItKey.contains(childName)) continue;
					var stages = btn.switchMap.get(childName);
					if (stages == null) continue;
					var outStages:Array<Dynamic> = [];
					for (stage in stages)
					{
						if (stage == null || stage.keys == null || stage.keys.length == 0) continue;
						var hasName:Bool = (stage.nameZh != null && stage.nameZh != '')
							|| (stage.nameEn != null && stage.nameEn != '');
						if (!hasName)
						{
							outStages.push(stage.keys.copy());
						}
						else
						{
							var so:Dynamic = { keys: stage.keys.copy() };
							if (stage.nameZh != null && stage.nameZh != '')
								Reflect.setField(so, 'NameChinese', stage.nameZh);
							if (stage.nameEn != null && stage.nameEn != '')
								Reflect.setField(so, 'NameEnglish', stage.nameEn);
							outStages.push(so);
						}
					}
					if (outStages.length > 0)
						Reflect.setField(sw, childName, outStages);
				}
				if (Reflect.fields(sw).length > 0) Reflect.setField(o, 'Switch', sw);
			}
		}
		return o;
	}

	/** 生成“从默认键位开始”的模板文档（临时构建一次默认虚拟按键并读取其布局） */
	public static function buildTemplateJson(editorId:String):String
	{
		var entry = entryOf(editorId);
		var buttons:Array<EMKButton> = [];
		if (entry != null)
		{
			var pad:FlxVirtualPad = null;
			try
			{
				pad = new FlxVirtualPad(entry.dpad, entry.action);
				var usedNames:Array<String> = [];
				var semIndex:Int = 0;
				pad.forEachAlive(function(btn)
				{
					if (btn == null) return;
					// 语义表（推荐名/键值对/含义）与按钮创建顺序一一对应
					var sem:EMKSem = (semIndex < entry.semantics.length) ? entry.semantics[semIndex] : null;
					semIndex++;

					var rawName:String = btn.tag;
					if (rawName == null || rawName == '') rawName = '';
					rawName = rawName.toUpperCase();
					if (sem != null && sem.name != null && sem.name != '')
						rawName = sem.name.toUpperCase();

					var base:String = rawName;
					var name:String = base;
					var i:Int = 2;
					while (name == '' || usedNames.contains(name))
					{
						name = base + '_' + i;
						i++;
					}
					usedNames.push(name);

					var def = new EMKButton();
					def.name = name;
					def.x = btn.x;
					def.y = btn.y;
					def.w = Std.int(btn.width);
					def.h = Std.int(btn.height);
					if (def.w < 20) def.w = 120;
					if (def.h < 20) def.h = 120;
					def.color = (btn.saveColor != 0) ? btn.saveColor : 0xFF8B5CF6;

					if (sem != null)
					{
						// 有梳理好的语义：直接预填等价键值对 + 含义
						def.click = sem.keys.copy();
						def.desc = sem.desc;
					}
					else if (btn.IDs != null && btn.IDs.length > 0)
					{
						// 兜底：pad 按钮自带 keybind 时按 ID 填
						for (id in btn.IDs)
						{
							if (id == FlxKey.NONE) continue;
							var keyName:String = Std.string(id);
							if (keyName != null && keyName != '' && keyName != 'NONE' && !def.click.contains(keyName))
								def.click.push(keyName);
						}
					}
					buttons.push(def);
				});
			}
			catch (e:Dynamic)
			{
				trace('[EditorMobileKeys] template build failed: $e');
			}
			if (pad != null)
			{
				try
				{
					pad.destroy();
				}
				catch (e:Dynamic) {}
			}
		}
		return toJson(editorId, buttons, true);
	}

	static function parseHexColor(raw:Dynamic, fallback:Int):Int
	{
		var out:Int = fallback;
		if (raw == null) return out;
		var cs:String = StringTools.trim(Std.string(raw));
		if (cs.length > 0)
		{
			if (cs.charAt(0) == '#') cs = cs.substr(1);
			var v:Int = 0;
			var hexOk:Bool = true;
			for (i in 0...cs.length)
			{
				var d:Int = '0123456789abcdef'.indexOf(cs.charAt(i).toLowerCase());
				if (d < 0)
				{
					hexOk = false;
					break;
				}
				v = (v << 4) | d;
			}
			if (hexOk && cs.length == 6)
				out = 0xFF000000 | v; // #RRGGBB → 0xFFRRGGBB
			else if (hexOk && cs.length == 8)
				out = v; // #AARRGGBB
		}
		return out;
	}

	static function readFloat(raw:Dynamic, field:String, fallback:Float):Float
	{
		var v:Dynamic = Reflect.field(raw, field);
		if (v == null) return fallback;
		var n:Null<Float> = Std.parseFloat(Std.string(v));
		return n == null ? fallback : n;
	}

	static function parseStringArray(v:Dynamic):Array<String>
	{
		var out:Array<String> = [];
		if (v == null) return out;
		if (Std.isOfType(v, Array))
		{
			for (item in cast(v, Array<Dynamic>))
			{
				if (item == null) continue;
				var s:String = Std.string(item);
				if (s != null && s != '') out.push(s.toUpperCase());
			}
		}
		else if (Std.isOfType(v, String))
		{
			var s:String = cast v;
			for (part in s.split(','))
			{
				part = StringTools.trim(part).toUpperCase();
				if (part != '') out.push(part);
			}
		}
		return out;
	}
}

/** 单个按键的运行时定义 */
class EMKButton
{
	public var name:String = '';
	public var click:Array<String> = [];
	/** 语义提示（仅来自模板；正常保存不写盘） */
	public var desc:String = null;
	public var x:Float = 0;
	public var y:Float = 0;
	public var w:Int = 120;
	public var h:Int = 120;
	public var color:Int = 0xFF8B5CF6;
	/** 文字颜色（默认白，兼容老文件） */
	public var textColor:Int = 0xFFFFFFFF;
	public var isFather:Bool = false;
	public var fuckItKey:Array<String> = [];
	public var canSwitch:Bool = false;
	/** 档数（每按一次父键切到下一档；SwitchNum 档后再按回到原输出） */
	public var switchNum:Int = 1;
	/** 子键名 → 有序档列表（每档 = 目标组合键 + 可选的多语言显示名） */
	public var switchMap:Map<String, Array<EMKStage>> = new Map();

	public function new() {}

	public function toString():String
	{
		return 'EMKButton($name ${click.join("+")} @${x},${y})';
	}
}

/** 默认键位语义：推荐显示名 / 等价键值对 / 中文含义（顺序 = 对应默认 pad 按钮创建顺序） */
class EMKSem
{
	public var name:String;
	public var keys:Array<String>;
	public var desc:String;

	public function new(name:String, keys:Array<String>, desc:String)
	{
		this.name = name;
		this.keys = keys;
		this.desc = desc;
	}
}

/** Switch 的单个档：输出组合键 + 可选多语言显示名（切到该档时按钮文字显示的名字） */
class EMKStage
{
	public var keys:Array<String> = [];
	public var nameZh:String = ''; // NameChinese
	public var nameEn:String = ''; // NameEnglish

	public function new(?keys:Array<String> = null, ?nameZh:String = '', ?nameEn:String = '')
	{
		if (keys != null) this.keys = keys;
		this.nameZh = nameZh == null ? '' : nameZh;
		this.nameEn = nameEn == null ? '' : nameEn;
	}

	public function displayName(language:String):String
	{
		var isZh:Bool = language != null
			&& (language.indexOf('Chinese') != -1
				|| language.indexOf('chinese') != -1
				|| language == 'I Dont Like Haxe');
		if (isZh && nameZh != null && nameZh != '') return nameZh;
		if (nameEn != null && nameEn != '') return nameEn;
		if (nameZh != null && nameZh != '') return nameZh;
		return '';
	}
}

/** Editor 注册条目 */
class EditorEntry
{
	public var id:String;
	public var displayName:String;
	public var stateClassName:String;
	public var dpad:FlxDPadMode;
	public var action:FlxActionMode;
	/** 默认按键的键值对语义（顺序与 pad 按钮创建顺序一致；可为空） */
	public var semantics:Array<EMKSem>;

	public function new(id:String, displayName:String, stateClassName:String, dpad:FlxDPadMode, action:FlxActionMode,
			?semantics:Array<EMKSem>)
	{
		this.id = id;
		this.displayName = displayName;
		this.stateClassName = stateClassName;
		this.dpad = dpad;
		this.action = action;
		this.semantics = semantics == null ? [] : semantics;
	}
}
