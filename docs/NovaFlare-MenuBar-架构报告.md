# NovaFlare 编辑器自绘菜单栏架构报告(以 CharacterEditorMenuBar 为样本)

> 工程根:`C:\Users\Admin1\Desktop\FNF-NovaFlare-Engine-1.2.1`
>
> **行号口径说明**:被分析文件为 UTF-8 / LF 换行,下文全部行号以按 `\n` 拆分的实际行数为准
> (CharacterEditorMenuBar.hx 共 **2425** 行、CharacterEditorState.hx 共 **1679** 行、CharacterEditorStatusBar.hx 共 **96** 行)。
> 若你的编辑器/工具按 ANSI/GBK 拆行会少计 CJK 行(例如 PowerShell `Get-Content` 计数为 2266/1655),引用行号时请以 UTF-8 为准。
>
> 材料文件:
> - `source/developer/editors/CharacterEditorMenuBar.hx`(2425 行)——核心样本
> - `source/developer/editors/CharacterEditorStatusBar.hx`(96 行)
> - `source/developer/editors/EditorInputStyle.hx`(93 行)
> - `source/developer/editors/CharacterEditorState.hx`(1679 行,菜单接线部分)
> - 对照:`ChartEditorMenuBar.hx`(2446 行)、`StageEditorMenuBar.hx`(2492 行)、`ChartEditorStatusBar.hx`、`StageEditorStatusBar.hx`
> - 语言文件:`assets/shared/language/Chinese/character/character.lang`(本报告中文文案均出自此文件)

---

## 0. 一句话架构总结

**菜单栏 = 一块纯自绘的 `FlxSpriteGroup`(挂在 HUD 相机上)+ 一组"只当数据源、永远隐藏、绝不渲染"的原生 FlxUI 控件。**
原生控件(FlxUICheckBox / FlxUIInputText / FlxUINumericStepper / FlxUIDropDownMenu / FlxUISlider)由
EditorState 持有并 `registerWidget` 进菜单栏;菜单栏在 `rebuildDropdown()` 时按菜单行定义查表取出控件、读取其值,
用 FlxSprite/FlxText 逐像素画出外观;点击/悬停/滚轮全部由菜单栏自己命中判定(自绘控件 `CharacterCustomControl`);
需要输入文字时才把被隐藏的原生控件临时弹出到 `overlayLayer` 上做真实输入,失焦即收回并同步回自绘显示。
"菜单内容"是**纯数据**(`menus:Array<CharacterMenuDef>`),与"渲染/交互引擎"完全分离——这就是三份 EditorMenuBar
能整份复制改名复用的根本原因。

---

## 1. CharacterEditorMenuBar 类结构(文件行号见 `CharacterEditorMenuBar.hx`)

### 1.1 声明与继承
```haxe
class CharacterEditorMenuBar extends FlxSpriteGroup   // 第 35 行
```
文件头注释(21-34)说明设计:顶栏 N 个菜单按钮 → 点击弹下拉浮窗;行类型 `sep/cmd/widget/label_widget/text`;
hover 行 → 底部描述条;自绘控件 stepper/dropdown/input/slider;原生控件只作数据源。

### 1.2 构造顺序 `public function new()`(178-195)
```haxe
scrollFactor.set();                                  // 181 不随相机滚动
uiCamera = flixel.FlxG.camera;                       // 182 默认主相机,State 会覆盖
statusBar = new CharacterEditorStatusBar();          // 185 先加状态栏(渲染在下层)
statusBar.scrollFactor.set();
add(statusBar);                                      // 187
buildMenuBar();                                      // 189 顶栏背景+分隔线
buildDropdown();                                     // 190 复用 dropGroup 容器
buildDescBar();                                      // 191 描述条
buildMenus();                                        // 193 菜单数据(行定义)
applyLang();                                         // 194 建顶栏按钮文字(语言化)
```
要点:**状态栏是 MenuBar 的内部成员**、先 add(保证下拉浮窗/描述条渲染在它之上)。

### 1.3 常量

**配色常量(39-76)**——NovaFlare 深色规范,AARRGGBB:
- 中性:`C_PAGE_BG=0xFF12141A`(39)、`C_CARD_BG=0xFF1C1F28`(40)、`C_FIELD_BG=0xFF12141A`(41)、
  `C_HOVER_OVERLAY=0x147C7FFF`(42)、`C_BORDER=0x14FFFFFF`(43)、`C_BORDER_STRONG=0x26FFFFFF`(44)、
  `C_TEXT_MAIN=0xFFF2F3F5`(45)、`C_TEXT_SEC=0xFFC9CDD4`(46)、`C_TEXT_HINT=0xFF86909C`(47)
- 一级主菜单:`C_MENU_IDLE`(50)、`C_MENU_SEL_A=0xFF4F46E5`(51,indigo)、`C_MENU_SEL_B=0xFF7C3AED`(52,violet)、
  `C_MENU_SEL_TEXT`(53)、`C_MENU_ACCENT=0xFFA78BFA`(54)
- 二级子菜单:`C_SUB_TEXT`(57)、`C_SUB_HOVER=0x0F8B5CF6`(58)、`C_SUB_SEL_BG=0x268B5CF6`(59)、`C_SUB_SEL_TEXT=0xFFA78BFA`(60)
- 主按钮渐变:`C_PRIMARY_A=0xFF6366F1`(63)、`C_PRIMARY_B=0xFF8B5CF6`(64)、hover 加深对(65-66)、`C_HOVER_LIFT`(67)
- 危险:`C_DANGER=0xFFEF4444`(70)、`C_DANGER_B=0xFFDC2626`(71);状态色 `C_SUCCESS/C_WARN/C_INFO`(74-76)

**布局常量(79-94)**
```haxe
public static final BAR_HEIGHT:Int = 36;      // 79 顶栏高
public static final STATUS_HEIGHT:Int = 25;   // 80 状态栏高(与 CharacterEditorStatusBar.HEIGHT 一致)
public static final MENU_W:Int = 88;          // 81 每个按钮宽
public static final DROP_MIN_W:Int = 420;     // 83 下拉统一最小宽
public static final DROP_MAX_W:Int = 420;     // 84 最大宽(= 最小,全部菜单等宽)
public static final DESC_MAX_W:Int = 620;     // 85 描述条最大宽
public static final ROW_H:Int = 22;           // 86 普通行高
public static final ROW_PAD_X:Int = 10;       // 87 行左右内边距
static final DROP_OPT_H:Int = 20;             // 89 自绘 dropdown 选项行高
static final MAX_DROP_OPT:Int = 20;           // 90 同时最多显示项数
static final TEXT_SCROLL_SPEED:Float = 32;    // 93 走马灯速度 px/s
static final TEXT_SCROLL_HOLD:Float = 0.9;    // 94 两端停留秒
```

### 1.4 成员字段分类(全部私有,除注明外)

| 类别 | 字段 | 行号 | 说明 |
|---|---|---|---|
| 菜单数据 | `public var menus:Array<CharacterMenuDef>` | 97 | 菜单定义(纯数据) |
| | `public var activeMenu:Int = -1` | 98 | 当前打开的菜单下标,-1=无 |
| 顶栏视觉 | `barBg` / `menuTitleSprites` / `menuTitleHits` / `menuTabActives` / `menuTabHovers` / `menuUnderline` | 101-106 | 背景、按钮文字、透明 hitbox、选中渐变底、hover 底、下缘装饰条 |
| 下拉浮窗 | `dropGroup:FlxSpriteGroup` / `dropBg` / `dropBorder` / `dropRows:Array<CharacterDropdownRow>` | 109-112 | 复用容器 |
| | `dropGroupMembers:Array<Dynamic>` | 114 | 记入 dropGroup 的临时成员,cleanup 用 |
| | `activeLabelWidgets:Array<Dynamic>` | 117 | 独立跟踪的 FlxUI 控件(绝不塞进 FlxSpriteGroup) |
| | `customControls:Array<CharacterCustomControl>` | 120 | 自绘控件(stepper/dropdown/input/slider) |
| 动态文本 | `dynTexts:Map<String,FlxText>` / `dynTextProviders:Map<String,Void->String>` | 122-123 | DynText 行 |
| hover 守卫 | `lastHoverSwitchIdx` | 126 | 只在 hover 下标变化时切菜单 |
| 描述条 | `descBg/descIcon/descText/curDescKey/lastDescCacheKey/lastDescH` | 129-135 | 弹性高度缓存 |
| 状态栏 | `public var statusBar:CharacterEditorStatusBar` | 138 | **成员**(非独立挂载) |
| 输入覆盖层 | `activeEditWidget` / `activeEditPrevX/Y/Visible` | 141-144 | 被临时弹出的原生输入框及其原坐标/显隐 |
| stepper 覆盖层 | `stepperOverlay:FlxUIInputText` / `stepperOverlayCtrl` | 149-150 | 独立创建的输入框实例 |
| 鼠标视图坐标 | `mViewX/mViewY` | 155-156 | 每帧以 uiCamera 换算 |
| 下拉面板拖拽 | `panelPressCtrl/panelPressY/panelPressScroll/panelDragMoved` | 161-164 | 按下→移动超阈值变拖拽→松开未拖=点击 |
| 回调 | `public var onAction:String->Void` | 168 | actionKey → State |
| | `public var onMenuOpened:String->Void` | 170 | 菜单打开后先让 State 刷新 widget 值 |
| 相机/层 | `public var uiCamera:flixel.FlxCamera` | 173 | 鼠标命中用视图相机 |
| | `public var overlayLayer:FlxSpriteGroup` | 176 | 覆盖层容器(State 赋值),输入层渲染于菜单之上 |
| widget 注册表 | `var widgetRefs:Map<String,Dynamic>` | 487 | key→原生控件 |

### 1.5 Public API 完整清单(签名 + 语义)

```haxe
public function new()                                                // 178 构造(见 1.2)
public static function langFont():String                             // 198 = EditorInputStyle.langFontFileName()
public function buildMenus():Void                                    // 273 重灌 menus 数组(语言无关,键都是翻译 key)
public function applyLang():Void                                     // 404 重建顶栏按钮/渐变/hitbox + statusBar.applyLang()
public function registerWidget(key:String, widget:Dynamic):Void      // 488 原生控件 → widgetRefs
public function registerDynText(key:String, provider:Void->String):Void // 494
public function refreshDynTexts():Void                               // 500 所有 DynText 行文本 = provider()
public function isMouseInsideUI(mx:Float, my:Float):Bool             // 1546 点是否落在菜单任何 UI(顶栏/浮窗/描述条/覆盖层/自绘控件/展开面板)
public function openMenu(idx:Int):Void                               // 1592 打开/切换菜单
public function closeMenu():Void                                     // 1622 关闭并清理
override function update(elapsed:Float):Void                         // 526 主交互循环(见 §6)
override function destroy():Void                                     // 2333 清理 widgetRefs
```

**`openMenu(idx)` 内部顺序(1592-1620)——蓝图关键**,注释已强调:
```haxe
clearActiveEditWidget();            // 1595 收回上次输入覆盖层
if (stepperOverlayCtrl != null) commitStepperOverlay();  // 1596-1597
activeMenu = idx;                   // 1600
var menuKey = menus[idx].key;
if (onMenuOpened != null) onMenuOpened(menuKey);  // 1606-1607 ① 先让 State 把 widget 数据刷到位(读)
dropGroup.visible = true;           // 1614    ② 先置可见(防止 group visible 级联把勾选 √ 全改 true)
rebuildDropdown();                  // 1616    ③ 再渲染行(读到的才是新值)
refreshCharacterCustomControlDisplays();  // 1619 ④ 自绘控件显示同步
```
`closeMenu()`(1622-1634):清覆盖层/stepper 覆盖层/拖拽状态 → `activeMenu=-1` → `dropGroup.visible=false`
→ `clearCharacterDropdownRows()` → `hideDescBar()`。

**动作回调辅助(内部,517-523)**
```haxe
function callAction(actionKey:String):Void {
    if (onAction != null) onAction(actionKey);
    if (menus[activeMenu].key != 'help') closeMenu();   // help 菜单(纯文本行)不关闭
}
```
所有 Cmd 行的 onClick 都是 `() -> callAction('xxx')`。

---

## 2. 菜单/命令如何定义

### 2.1 数据结构(2341-2425,文件底部 typedef)

```haxe
enum CharacterItemType {            // 2341-2350
    Sep;        // 分隔线
    Cmd;        // 命令行(点击→onClick→onAction)
    Check;      // 已废弃(2345,现用 Widget)
    Widget;     // 无标签行:直接嵌入原生控件(实际= FlxUICheckBox 等,带勾选框)
    LabelWidget;// 带标签的原生控件(input/stepper/dropdown/slider 自绘化)
    TextLine;   // 纯文本行(帮助菜单;无 hitbox 不可点)
    DynText;    // 动态文本行(内容来自外部 provider)
}

typedef CharacterMenuItemDef = {    // 2352-2361
    type:CharacterItemType,
    labelKey:String,   // Widget 时=widgetKey;LabelWidget/TextLine/Cmd 时=翻译 key
    descKey:String,
    ?getChecked:Void->Bool,
    ?onCheck:Bool->Void,
    ?onClick:Void->Void,
    ?widgetKey:String  // LabelWidget 时从 widgetRefs 取控件
}

typedef CharacterMenuDef = { key:String, isTest:Bool, items:Array<CharacterMenuItemDef> }  // 2363-2368

typedef CharacterDropdownRow = {    // 2370-2382 渲染产物(一次菜单展开生成一行)
    type, labelKey, descKey, def:CharacterMenuItemDef,
    hit:FlxSprite, ?checkIcon:Dynamic, ?checkTxt:FlxText, ?label:FlxText,
    ?hoverBg:FlxSprite, ?widget:Dynamic }

typedef CharacterCustomControl = {  // 2386-2415 自绘控件状态
    key:String, ctype:String /* 'stepper'|'dropdown'|'input'|'slider' */,
    widget:Dynamic /* 原生数据源 */, box:FlxSprite, text:FlxText, row:CharacterDropdownRow,
    ?btnMinus:FlxSprite, ?btnPlus:FlxSprite,          // stepper
    ?arrow:FlxText, ?open:Bool, ?options:Array<String>, ?scrollIdx:Int,
    ?panelBorder:FlxSprite, ?panelBg:FlxSprite, ?panelRows:Array<CharacterDropdownOption>, ?panelH:Int,  // dropdown
    ?track:FlxSprite, ?fill:FlxSprite, ?thumb:FlxSprite, ?dragging:Bool,  // slider
    ?isScrolling:Bool, ?scrollT:Float, ?scrollDelay:Float }               // 走马灯
```

### 2.2 构建函数(行类型辅助,345-371)
```haxe
static var SEP:CharacterMenuItemDef = {type: Sep, ...};          // 346
function item_cmd(labelKey, descKey, onClick:Void->Void)          // 348 → {type:Cmd, onClick}
function item_widget(widgetKey, descKey)                          // 353 → {type:Widget, labelKey:widgetKey, widgetKey}
function item_label_widget(widgetKey, labelKey, descKey)          // 358 → {type:LabelWidget, widgetKey, labelKey}
function item_text(textKey, descKey)                              // 363 → {type:TextLine}
function item_dyn_text(dynKey, descKey)                           // 368 → {type:DynText}(当前角色菜单未用)
```

### 2.3 条目→actionKey 触发链
- **Cmd 行**:定义处 onClick 闭包 `() -> callAction('actionKey')`(例 279 `item_cmd('reload_image', 'desc_reload_image', () -> callAction('reload_image'))`)。
  actionKey 字符串格式:**小写 snake_case 动作名**('save' / 'anim_add_update' / 'make_ghost' / …),由
  `onAction` 转发给 `CharacterEditorState.handleMenuAction`(见 §7)。
- **Widget(checkbox)/LabelWidget 行**:不产生 actionKey;状态修改走**原生控件值 + FlxUI 事件广播**
  (`FlxUI.event(CHANGE_EVENT…)`,见 stepper 1391/1096、slider 1137),由 State 的 `getEvent`(CharacterEditorState 893)接住写回数据模型。

### 2.4 渲染阶段(rebuildDropdown,1637-2133)两遍扫描
- 第一遍(1645-1712):估算总高 `totalH` 与下拉宽 `dropW`——Widget 行按 `widget.width(+stepper 额外 42)`(1665-1672);
  LabelWidget 标签估宽按 `lbl.length*8+140`(1676-1680);TextLine 按字符数估行数(上限 3 行,1682-1695);
  DynText 预留 4 行(1696-1702);Cmd/其余固定 `ROW_H`(1703-1710)。
- 定位:`dropX = activeMenu*MENU_W`,`dropY = BAR_HEIGHT + STATUS_HEIGHT + 2`(1715-1716,**下拉在状态栏下方**)。
- 第二遍(1721-2121)逐行画:Sep→2px 线(1727-1730);Widget→左标签(1772-1781)+ 右装饰勾选方块/√(1784-1798)
  + 整行透明 hitbox(1801);LabelWidget→左标签固定宽 120(1827-1831)+ 右侧自绘控件区,并按 `Std.is(widget,…)`
  分流四种外观(见下表);TextLine→header(粗体白)/普通行(2001-2010);Cmd→危险/主按钮特殊着色
  (`isDanger: labelKey=='anim_remove'` 2073、`isPrimary: labelKey=='save'` 2074,渐变主按钮 2077-2084)。
- 收尾:按实际高度 `finalH` 重建 `dropBg/dropBorder`(2124-2132)。

**LabelWidget 四种自绘控件(1861-1962)**
| 原生类型判定 | ctype | 外观 | 交互入口 |
|---|---|---|---|
| `Std.is(widget, FlxUINumericStepper)` | `stepper` | box + 右侧横排 [-] [+](渐变,1874-1894) | `handleCharacterCustomControlClick` → `stepperPlus/Minus` 或点文本区弹 `openStepperOverlay` |
| `FlxUIDropDownMenu` | `dropdown` | box + ▼ 箭头(1903) | 点 box 展开 `renderCharacterDropdownOptions` 自绘面板 |
| `FlxUIInputText` | `input` | box + 文本 | 点 box → `openInputOverlay` 弹原生输入 |
| `FlxUISlider` | `slider` | track/fill/thumb + 数值(1928-1956) | 按下 `sliderDrag` |
每类构建后都会隐藏原生本体:`widget.visible=false; widget.active=false`(1965-1966;Widget 行同理 1770-1771)。

---

## 3. 完整菜单结构转录(顶栏 6 菜单,键顺序=渲染顺序)

菜单标题由 `Language.get('menu_'+key,'character')`(457)得出;下表 label 列直接给中文(= `character.lang` 译文)。
行号一律为 `buildMenus()` 内的定义行(275-342);`type` 列中文含义见 §2.1。

### 菜单 0:`char` 角色(276-283)
| 定义行 | type | key(widgetKey/actionKey) | labelKey→中文 label | descKey |
|---|---|---|---|---|
| 277 | LabelWidget | w_char_select | label_char_select→**角色:**(角色下拉) | desc_char_select |
| 278 | LabelWidget | w_image | label_image→**图像:**(输入框) | desc_image |
| 279 | Cmd | actionKey=`reload_image` | item_reload_image→**重新加载图像** | desc_reload_image |
| 280 | LabelWidget | w_health_icon | label_health_icon→**图标:** | desc_health_icon |
| 281 | Cmd | actionKey=`get_icon_color` | item_get_icon_color→**获取图标颜色** | desc_get_icon_color |
| 282 | LabelWidget | w_vocals | label_vocals→**人声:** | desc_vocals |

### 菜单 1:`anim` 动画(284-294)
| 行 | type | key | label | 备注 |
|---|---|---|---|---|
| 285 | LabelWidget | w_anim_select | **动画:**(下拉) | desc_anim_select |
| 286 | LabelWidget | w_anim_name | **名称:** | desc_anim_name |
| 287 | LabelWidget | w_anim_symbol | **符号:** | desc_anim_symbol |
| 288 | LabelWidget | w_anim_fps | **帧率:**(stepper) | desc_anim_fps |
| 289 | Widget | w_anim_loop | item_anim_loop→**是否循环播放?** | 勾选 |
| 290 | LabelWidget | w_anim_indices | **索引:** | desc_anim_indices |
| 291 | Sep | — | 分隔 | |
| 292 | Cmd | actionKey=`anim_add_update` | item_anim_add_update→**添加/更新** | |
| 293 | Cmd | actionKey=`anim_remove` | item_anim_remove→**删除**(危险红) | |

### 菜单 2:`settings` 设置(295-311)
| 行 | type | key | label | 备注 |
|---|---|---|---|---|
| 296 | Widget | w_playable | item_playable→**可游玩角色** | |
| 297 | Sep | | | |
| 298 | Widget | w_flip_x | item_flip_x→**水平翻转** | |
| 299 | Widget | w_no_aa | item_no_aa→**关闭抗锯齿** | |
| 300 | LabelWidget | w_scale | label_scale→**缩放:** | stepper |
| 301 | LabelWidget | w_sing_duration | label_sing_duration→**唱歌时长:** | stepper |
| 302 | Sep | | | |
| 303-306 | LabelWidget | w_pos_x/w_pos_y/w_cam_x/w_cam_y | **位置 X:/位置 Y:/相机 X:/相机 Y:** | stepper(Shift 微调特殊名单 1384) |
| 307 | Sep | | | |
| 308-310 | LabelWidget | w_health_r/w_health_g/w_health_b | **血条 R:/血条 G:/血条 B:** | 三者共用 desc_healthbar_colors |

### 菜单 3:`ghost` 外观(312-316)
| 行 | type | key | label |
|---|---|---|---|
| 313 | Cmd | actionKey=`make_ghost` | item_make_ghost→**生成 Ghost 帧** |
| 314 | Widget | w_highlight_ghost | item_highlight_ghost→**高亮 Ghost 帧** |
| 315 | LabelWidget | w_ghost_alpha | label_ghost_alpha→**不透明度:**(slider) |

### 菜单 4:`file` 文件(317-321)
| 行 | type | actionKey | label |
|---|---|---|---|
| 318 | Cmd | `save` | item_save→**保存角色**(渐变主按钮) |
| 319 | Cmd | `load_template` | item_load_template→**加载模板** |
| 320 | Cmd | `reload_char` | item_reload_char→**重新加载角色** |

### 菜单 5:`help` 帮助(322-341,全部 TextLine 不可点)
`labelKey` = help_camera/help_cam_zoom/help_cam_move/help_cam_reset(323-326)、help_char/help_char_anim/help_char_offset/
help_char_offset_keys/help_char_replay/help_char_frame(328-333)、help_other/help_other_sil/help_other_shift/
help_other_ctrl/help_other_help/help_other_exit(335-340),行文本取 `item_<labelKey>`(如 item_help_cam_zoom→"E/Q - 相机放大/缩小")。
其中 labelKey 为 `help_camera|help_char|help_other` 的三行渲染为**加粗白色小标题**(2001-2006)。
hover 时描述条显示 `desc_<labelKey>`(如 desc_help_char_offset_keys→"Ctrl+C 复制、Ctrl+V 粘贴、Ctrl+R 重置…")。

### 快捷键真相(重要结论)
菜单栏**自身不监听任何菜单级快捷键**。全文件键盘读取仅三处:
`FlxG.keys.justPressed.ENTER`(772,提交 stepper 输入覆盖层)、`FlxG.keys.pressed.SHIFT`(1382,stepper 微调)、以及依赖聚焦的输入逻辑。
不存在 ESC 关菜单 / 键盘→actionKey 映射——**键盘全部由外层 State 处理**(详见 §6.3 与 §7 周边):
- 角色编辑器里 ESC 是**退出编辑器**(CharacterEditorState 1412-1423),不关菜单;
- F1 打开 help 菜单(1403-1411:在 `menuBar.menus` 里找 key=='help' 的下标再 `openMenu`);
- Ctrl+Z/C/V/R/S 是偏移量快捷(1205-1237,非菜单动作);F12 切换剪影(1400-1401);
- 唯一"菜单内键盘"来自临时弹出的原生输入框(stage 级 KEY_DOWN + hasFocus)。
对照:谱面编辑器 ChartingState 有 F1~F8→`openMenu(0..7)` 的键→菜单映射(ChartingState 2448-2455),
以及 `!menuOpen` 时 Ctrl/Shift/Alt 组合→`handleMenuAction('save_events'|'clear_events'…)` 的**键→actionKey** 映射(2456-2505)。
这些都属于 State 层,不属于 MenuBar。**给三个新编辑器仿写时,若想支持"ESC 关菜单/F1 帮助/键直达菜单项",必须在各自 State 的 update 里加,菜单栏本身没有钩子。**

---

## 4. StatusBar:成员?挂载?刷新?

**是 MenuBar 的成员,不是独立挂载的兄弟组件。**
- 类型声明:`public var statusBar:CharacterEditorStatusBar`(CharacterEditorMenuBar 138);
- 创建:`new CharacterEditorStatusBar()` 在 MenuBar 构造器里(185),`statusBar.scrollFactor.set(); add(statusBar)`(186-187),
  先 add 保证菜单浮层渲染在上;
- 位置由状态栏自己保证:`override function update` 里每帧 `this.y = CharacterEditorMenuBar.BAR_HEIGHT`(CharacterEditorStatusBar 91-95);
- 语言切换联动:`CharacterEditorMenuBar.applyLang()` 末尾调 `statusBar.applyLang()`(477-478)。
- **CharacterEditorState 刷新点(每帧,CharacterEditorState.update 开头 1043-1070)**:
```haxe
menuBar.statusBar.setCharacter(_char);                                  // 1046
menuBar.statusBar.setAnim(animName);                                    // 1066
menuBar.statusBar.setOffset(Std.int(character.offset.x)+' / '+…);       // 1067
menuBar.statusBar.setFrame('$frames / ${length - 1}');                  // 1068
menuBar.statusBar.setZoom(FlxMath.roundDecimal(FlxG.camera.zoom,2)+'x');// 1069
```
五个 setter(`setCharacter/setAnim/setOffset/setFrame/setZoom`,CharacterEditorStatusBar 67-71)只存字段再 `refreshText()`;
`refreshText()`(73-89)拼接 `Language.get('status_character','character')…`(76-80)后以 `'  |  '` 连接,
**仅当整串与 `_lastFullText` 不同才写 `rootLabel.text`**(84-88),避免每帧重建 FlxText 纹理"抽搐"。

---

## 5. Widget 机制(数据源 + 自绘 + 覆盖层弹出)

### 5.1 注册(存什么)
`registerWidget(key,widget)` 只把引用写进 `var widgetRefs:Map<String,Dynamic>`(487-491)。key 必须与
`buildMenus()` 的 widget/label_widget 项 key 一致(注释 482-486);控件生命周期归 State,菜单只负责摆位/显隐。
角色编辑器注册了 25 个(CharacterEditorState.setupMenuBar 416-442),分属 4 个"UI 组"字段(addGhostUI 748 /
addSettingsUI 780 / addAnimationsUI 823 / addCharacterUI 847 创建),全部 `overlayLayer.add` 进 update 循环
(addLegacyWidgetsToScene 507-546),随后统一隐藏+禁用(`hideAllLegacyWidgets` 548-564)。

### 5.2 隐藏原生控件后,菜单如何自绘状态值
- 渲染时从 `widgetRefs.get(wKey)` 取控件(第一遍算高 1658,第二遍 1737);
- Widget(checkbox)行:读 `widget.checked`(1774)决定勾选方块底色(`C_MENU_ACCENT`)与 √ 文本(1784-1798);
  原生控件 `visible=false; active=false`(1770-1771)。**toggle 由 `activateRow` 完成**(2205-2269):
  反转 `row.widget.checked` → `Reflect.field(widget,'callback')()` 手动补回调(2233-2239)→ 更新 checkIcon 色/√(2247-2262)。
- LabelWidget 行:自绘控件显示值来自原生控件——
  `updateStepperDisplay` 读 `widget.value`(845-850);`updateDropdownDisplay` 读 `widget.header.text.text`(891,注释:selectedLabel getter 私有反射读恒空)
  并同步 `options`(899-907);`updateInputDisplay` 读 `widget.text`(910-916);`updateSliderDisplay` 用
  `readSliderValue`(919-936,优先反射 `_object`/`varString` 绑定字段,因原生 update 被 active=false 停掉)算相对位置画 fill/thumb(938-959)。
- 菜单每次打开 `openMenu` → `refreshCharacterCustomControlDisplays()`(833-843)统一刷一遍所有自绘显示。

### 5.3 覆盖层弹出(临时"借尸还魂")
| 函数 | 行号 | 作用 |
|---|---|---|
| `openInputOverlay(ctrl)` | 1434-1485 | 点击 input 行:记录原坐标/显隐(1442-1444)→ 移到 box 上并 visible(1446-1448)→ `EditorInputStyle.apply` 灰底白字(1450)→ 强制 `_regen`+`drawFrame(true)` 重建纹理(1454-1464)→ 字号 12 + fieldWidth(1459-1460)→ `stretchOverlayBackground` 撑宽(1467,1404-1431)→ **`active=false`**(1471,注释:防 FlxInputText.update 的 overlaps 判定秒清焦点,键盘走 stage KEY_DOWN)→ `overlayLayer.remove+add` 提升层级(1473)→ 记录 `activeEditWidget`(1474)→ `EditorInputStyle.setInputFocus(w,true)`(1477,hasFocus setter 私有须走 setter)→ caret 点亮(1479-1483) |
| `clearActiveEditWidget()` | 1488-1510 | 失焦/切菜单时:先把原生文本同步回自绘(1493-1497)→ 还原 x/y/visible、`active=false`(1498-1505)→ `setInputFocus(false)`(1507) |
| `openStepperOverlay(ctrl)` | 1027-1076 | stepper 的**独立**输入框覆盖层:首次惰性 new `FlxUIInputText`(1038),挂 overlayLayer(1044);定位在 box 文本区、放大字号/fieldWidth、`active=false`、聚焦(1069) |
| `commitStepperOverlay()` | 1079-1106 | ENTER/失焦:parseFloat→ clamp min/max(1092-1093)→写 `w.value`(1094)→**补广播 `FlxUI.event(FlxUINumericStepper.CHANGE_EVENT,…)`**(1096)→隐藏+失焦 |
| `positionWidget(widget,vx,vy)` | 2142-2148 | 通用摆位助手(当前流程实际少用,主要为对齐/兜底保留) |
| 每帧同步 | update 766-804 | 覆盖层开着时实时把输入文本同步到自绘(777-804);失焦检测即收(792-803) |

`isOverActiveEditWidget(mx,my)`(1530-1539)用自绘 box 判定(原生输入框 width=文本渲染宽,会误判框外);
`pointInWidget`(1513-1526)为兜底。`stretchOverlayBackground`(1404-1431)反射拿 backgroundSprite/fieldBorderSprite,
**origin 设 (0,0) 后 setGraphicSize 撑宽**(否则绕中心缩放向左扩),这是覆盖层背景与 box 等宽的保证。

### 5.4 事件回流(值变更 → 数据)
自绘 stepper/slider 等不会"真的点"原生控件,因此改值后靠手动 `FlxUI.event(CHANGE_EVENT, w, w.value, w.params)`
(stepper 1096/1391、slider 1137)通知 State;CharacterEditorState `getEvent`(893-963)过滤
`FlxUIInputText.CHANGE_EVENT`/`FlxUINumericStepper.CHANGE_EVENT` 后按 sender 写回 character 字段(healthIcon/scale/positionArray/healthColorArray…)并刷新相关 UI。

---

## 6. 键盘/鼠标交互路由(update 526-830)

`update` 内部**只处理鼠标与少数键**,顺序与要点:
1. **视图坐标基准**(530-537):`FlxG.mouse.getViewPosition(uiCamera)` → `mViewX/mViewY`。菜单挂在独立 HUD 相机
   (zoom=1/scroll=0),不能直接读 `FlxG.mouse.viewX`(主相机缩放/滚动会让 UI 命中错乱)。
2. **顶栏 hover**(539-551):遍历 `menuTitleHits` 命中 `hoverIdx`。
3. **Adobe 式 hover 切菜单**(553-560):`activeMenu>=0` 且 hover 到别的按钮且 `!justPressed` 且下标变化才 `openMenu(hoverIdx)`
   (有 `lastHoverSwitchIdx` 守卫,不每帧重建)。
4. **左键分发**(562-638):
   - 点在按钮上:同按钮已开→`closeMenu()`,否则 `openMenu`(568-575);
   - 点在外面且菜单开着:`isMouseInsideUI(mx,my)`(1546-1589:顶栏区→下拉区(含 border)→描述条→编辑覆盖层→自绘控件 box→展开面板)决定"算不算菜单内":
     - 菜单内 → 不关菜单;先让输入覆盖层处理(582-590,点覆盖层外先 `clearActiveEditWidget`),再优先 `handleDropdownPanelClick`(592,1163-1178:记录按下起点),否则找 `dropRows` 的 hitbox 命中行(596-609)→ LabelWidget 行先走 `handleCharacterCustomControlClick`(613-614,969-1023,stepper/dropdown/input/slider 各自消费)→ 未消费则 `activateRow`(617)→ Cmd/Check 关菜单、Widget/LabelWidget 保持打开(618-621);点空白 `closeCustomDropdowns()`(627);
     - **菜单外 → `closeMenu()`(632-636)——这就是"点击外部自动收起",由菜单栏自己完成,State 无需参与**。
5. **顶栏视觉每帧刷新**(641-667):选中渐变底/`menuUnderline` 下缘装饰条(651-659)/按钮文字色(661-667)。
6. **下拉行 hover → 描述条**(670-688):`FlxG.mouse.overlaps(row.hit, uiCamera)` 找 hover 行 → 切 hoverBg → `updateDescBar(hoverRow)`(688;272-2321,含弹性高度缓存与 `(404)` 语言缺失过滤 2280-2283)。
7. **展开面板**:hover 高亮(690-705)、**滚轮滚动**(708-721,`scrollIdx ± wheel`,clamp 0..maxScroll,重渲染)、
   **按住拖拽滚动**(724-753:移动 >6px 判定拖拽,按 `DROP_OPT_H` 每项滚动;松开未拖=点击,`releaseDropdownPanelClick` 1181-1208 → `selectCharacterDropdownOption` 1211-1244 直接调原生列表按钮 `b.onUp.callback()` 选值)。
8. **slider 拖拽**(756-763)+ `sliderDrag`(1109-1154,写原生值+反射绑定+callback+CHANGE_EVENT)。
9. **stepper/input 覆盖层每帧维护**(766-804,见 §5.3)。
10. **走马灯**(807-829):超宽文本 `textField.scrollH` 右→左滚动,两端停 `TEXT_SCROLL_HOLD` 秒(`applyTextScroll` 876-883,用 `_regen=true` 强制重绘、偏移没变不重绘省 CPU)。

**菜单打开(activeMenu>=0)时如何屏蔽下层编辑器输入——结论:角色编辑器并没有统一屏蔽。**
- 菜单栏内:点击菜单外会先 `closeMenu()`(632-636),避免点穿到舞台编辑;下拉面板/滚轮/拖拽都由菜单消费(707-753),State 的鼠标滚轮/拖拽与之不冲突;
- State 侧:仅"动画列表"一段用 `var menuOpen:Bool = (menuBar != null && menuBar.activeMenu >= 0)`(1306)做门禁
  (菜单开时停用列表 hover/滚轮/点击,1309-1397);**键盘(相机/动画/偏移/帧步进)在角色编辑器里并未因菜单打开而禁用**;
- 真正的"输入不串扰"来自:①任何输入框 hasFocus 时 State.update 提前 return(1072-1078);②菜单在屏幕顶部,与舞台拖拽(右键)天然不重叠。
  对照:谱面编辑器 ChartingState 门禁更严——菜单开时禁 TAB 切旧 tab(2609-2612)、禁滚轮快进谱面(2658-2684),
  且把 Ctrl 组合键整体放进 `else if (!menuOpen)`(2456-2505)。**仿写新编辑器若要"菜单开着编辑器就冻结",需照 ChartingState 模式在 State 里做,MenuBar 不提供全局输入锁。**

---

## 7. CharacterEditorState 接线(文件 `CharacterEditorState.hx`)

### 7.1 创建链路(create,115-228)
```
camHUD = new FlxCamera()(126-128) → uiLayer(FlxSpriteGroup,camHUD,131-134)
→ addGhostUI/addSettingsUI/addAnimationsUI/addCharacterUI(187-190,原生控件仅创建不显示)
→ setupMenuBar()(193)→ setupOverlayLayer()(196)→ addLegacyWidgetsToScene()(199,控件进 overlayLayer 循环)
→ hideAllLegacyWidgets()(200)
```

### 7.2 setupMenuBar(399-445)
```haxe
menuBar = new CharacterEditorMenuBar();             // 401
menuBar.scrollFactor.set();
menuBar.uiCamera = camHUD;                          // 404 覆盖默认主相机
menuBar.cameras = [camHUD];                         // 405
menuBar.onAction = (actionKey) -> handleMenuAction(actionKey);   // 406-408
menuBar.onMenuOpened = (menuKey) -> refreshMenuWidgets(menuKey); // 411-413
menuBar.registerWidget('w_char_select', charDropDown);           // 416…25 个注册(416-442)
menuBar.registerWidget('w_ghost_alpha', ghostAlphaSlider);       // 442
uiLayer.add(menuBar);                               // 444
```
`setupOverlayLayer`(447-455):`overlayLayer = new FlxSpriteGroup(); cameras=[camHUD]; add(overlayLayer); menuBar.overlayLayer=overlayLayer;`
(`overlayLayer` 在 uiLayer **之后** add,所以输入层渲染在所有 UI 之上)。

### 7.3 handleMenuAction 完整 actionKey 列表(457-492)
```haxe
switch (actionKey) {
    case 'reload_image':      // 462-469  按 imageInputText.text 重载贴图并保持当前动画
    case 'get_icon_color':    // 470-475  血条图标主色 → healthColorArray + updateHealthBar()
    case 'anim_add_update':   // 476-477  addUpdateCurrentAnimation()(633)
    case 'anim_remove':       // 478-479  removeCurrentAnimation()(681)
    case 'make_ghost':        // 480-481  makeGhost()(567)
    case 'save':              // 482-483  saveCharacter()(1641,FileReference 存 JSON)
    case 'load_template':     // 484-485  loadCharacterTemplate()(713)
    case 'reload_char':       // 486-490  addCharacter(true)+updatePointerPos()+刷新两个下拉
}
```
即角色编辑器**支持 8 个动作**。

### 7.4 refreshMenuWidgets 语义(494-500)
```haxe
function refreshMenuWidgets(menuKey:String):Void {
    reloadCharacterOptions();      // 497  settings 类控件从 character 回读(check_player/image/…,1016-1032)
    reloadCharacterDropDown();     // 498  角色下拉重新扫 data/characterList.txt + mods characters/*.json(1569-1587)
    reloadAnimationDropDown();     // 499  动画下拉 = anims 名(1589-1598)
}
```
语义:**每次任意菜单打开,先把所有"数据源控件"从当前角色模型回读一遍**——因为控件平时 `visible=false`,赋值不触发显示刷新,
必须在 `openMenu` 的 `rebuildDropdown()` 渲染前刷成最新值(`openMenu` 顺序保证:onMenuOpened 先于渲染,1604-1619)。`menuKey` 形参目前未参与分支(全量刷新)。

### 7.5 getEvent(893-963)
只接 `FlxUIInputText.CHANGE_EVENT` / `FlxUINumericStepper.CHANGE_EVENT`(895),按 sender 写回 character(见 §5.4)。

---

## 8. 菜单文字语言:硬编码 or Language.get?

**全部走 `Language.get`,中文无任何硬编码。**
- 语言组:本菜单统一用 **`'character'` 组**——菜单标题 `Language.get('menu_'+m.key,'character')`(457);
  Widget 行 `translateItemKey`(375-386,查 `item_*`,回退 `key.substring(2)`);LabelWidget `translateLabelKey`(389-401,查 key→回退 `label_+key`);
  TextLine/Cmd 行 `Language.get('item_'+labelKey,'character')`(2000/2072);描述条 `Language.get(descKey,'character')`(2279);
  状态栏 `Language.get('status_character'|'status_anim'|'status_offset'|'status_frame'|'status_zoom','character')`(CharacterEditorStatusBar 76-80)。
- 用到的 key 清单(内容见 `assets/shared/language/Chinese/character/character.lang`,共 162 行):
  `menu_char/menu_anim/menu_settings/menu_ghost/menu_file/menu_help`(3-8);
  `status_*`(11-15);`item_char_select/image/reload_image/health_icon/get_icon_color/vocals`(18-23)、
  `item_anim_*`(26-33)、`item_playable/flip_x/no_aa/scale/sing_duration/pos_x/pos_y/cam_x/cam_y`(36-44)、
  `item_make_ghost/highlight_ghost`(47-48)、`item_save/load_template/reload_char`(51-53);
  `label_*`(56-74);`help_camera/help_char/help_other`+`item_help_*` 标题与行(77-101);
  大量 `desc_*`(117-162)。同一组还服务 F1 帮助屏与菜单共用文案。
- 语言文件组目录:`assets/shared/language/<语言>/character/character.lang`(每组一个 `.lang` 文件,`key => 文本`,`#` 注释)。
  角色编辑器 create 开头 `Language.resetData()`(120-121)强制重载以纳入新组。
- **字体**:菜单/状态栏/控件全部用 `CharacterEditorMenuBar.langFont()`(198-201)→ `EditorInputStyle.langFontFileName()`(EditorInputStyle 23-30):
  读 `main` 组 `Language.get('fontName','main')`,缺失/404 时按 `ClientPrefs.data.language` 兜底(**中文 → Lang-ZH.ttf,否则 chillax.ttf**,27-28)。
  因此三个 MenuBar 的 `langFont()` 都是同一行委托;`EditorInputStyle.apply`(38-66)负责把原生输入框染成同字体/白字/灰底(写 `_defaultFormat.color` 绕过 set_color 白色早退)。
  `setInputFocus`(76-92)用 `@:privateAccess` 走 setter(移动端弹软键盘必须走 setter)。

---

## 9. Character / Chart / Stage 三份 MenuBar 重复度判定

**结论:是同一份代码复制改名演化的,不是各自独立实现。**
证据:
1. **文件头注释原样复制**——`StageEditorMenuBar.hx` 头注释(22-34)至今写着"角色编辑器顶栏菜单…(与 ChartEditorMenuBar 同一套自绘架构)"(内容与 Character 版逐字相同);
2. 函数体几乎逐行一致(rebuildDropdown 两遍扫描、四类自绘控件、覆盖层、描述条、dropdown 面板/拖拽滚动逻辑相同);
3. 布局常量数值相同(`BAR_HEIGHT=36/STATUS_HEIGHT=25/MENU_W=88/ROW_H=22/ROW_PAD_X=10/DESC_MAX_W=620/DROP_OPT_H 20/MAX_DROP_OPT 20/TEXT_SCROLL_*`);
4. 设计色板数值一致(0xFF12141A/0xFF1C1F28/0x147C7FFF/0x14FFFFFF/0x4F46E5/0x7C3AED/0xA78BFA/0x8B5CF6…)。

**定量(启发式,按"去除注释/空行并把 Character/Chart/Stage 前缀归一"后的行集合)**
| 对比 | 行级重合(归一) | 函数名重合(深归一) |
|---|---|---|
| Character ↔ Stage | **约 87-88%**(字符侧 88%、舞台侧 87%) | 59/61(仅差 `makeGradSprite`、`releaseDropdownPanelClick`) |
| Character ↔ Chart | **约 79%** | 52/62 |
| 总行数 | Char 2425 / Chart 2446 / Stage 2492 | — |

**差异点清单**
| 维度 | Character | Stage | Chart |
|---|---|---|---|
| 类型命名 | `CharacterMenuDef/…CustomControl` 前缀 | `Stage*` 前缀 | **无前缀**(更早版本) |
| 渐变实现 | `makeGradSprite` 逐像素 setPixel32(205-226) | `FlxGradient.createGradientFlxSprite`(432)+ 顶栏 hover/选中底数组(96-98);装饰条每按钮一个(445,非单条 menuUnderline) | makeGradSprite(198)同 Character |
| 额外条目类型 | — | `RawCmd`(enum 2410,直接文本不翻译、getChecked 驱动左侧选中标记,动态对象列表) | 无(但 Cmd/Widget 支持右对齐 shortcut 列:`?shortcut` 形参 409-421、MenuItemDef.shortcut 2378) |
| 自绘控件 | stepper+dropdown+input+**slider**,带 stepper 覆盖层输入 + panel 拖拽集中式(panelPressCtrl,161-164) | 同 Character(几乎 1:1,含 slider/stepper 覆盖层),拖拽字段独立命名(dragDropdownCtrl 146) | 无 slider、无 stepper 覆盖层;dropdown 拖拽用 per-ctrl dragging 字段 + `beginDropdownPress/updateDropdownDrag/refreshDropdownHover` |
| 回调面 | onAction/onMenuOpened/uiCamera/overlayLayer | 同 Character | 额外 `onSelectTab/onPlaytest/onRequestUIBox/onDropdownHoverOption`(159-167),`getDropdownRect`、`menuKeyToTabIdx`、事件信息浮动面板(showEventInfoPanel 等) |
| 菜单内容 | 6 菜单:角色/动画/设置/外观/文件/帮助 | 6 菜单:stage/object/camera/view/file/help + `dynamicMenuKey/dynamicItems` 现场追加动态行(241-242,1638-1647) | 8 菜单:charting/data/event/note/section/song/test/help(其中 test 菜单 `isTest:true`) |
| 语言组 | 'character'(character.lang) | 'stage'(translate 360/371) | 'charting'(charting.lang) |
| 下拉宽度 | DROP_MIN=MAX=420(统一等宽) | 同 Character | MIN=280/MAX=420(可不等宽) |
| 顶栏背景 | `C_PAGE_BG`(231) | `C_CARD`(197) | `C_BG_TOP=C_CARD_BG` |
| 状态栏 | 角色/动画/偏移/帧/缩放 | stage/directory/object/pos/zoom | Zoom/时间/Section/Beat/Snap/Move(ChartingState 2921-2930 每帧 set) |
| 键盘联动 | F1 开 help(State) | F1?/菜单按钮开关由 State 手动 open/close(StageEditorState 1327-1333) | F1~F8 直达 8 个菜单(ChartingState 2448-2455) |

演化方向推断:Chart(最早,裸类型名,无 slider)→ Character(加 slider+stepper 覆盖层+overlayLayer,改名带前缀)→ Stage(在 Character 版上继续小改:RawCmd 动态列表、FlxGradient、另起命名)。

---

## 10. 仿写蓝图(对话编辑器 / 对话立绘编辑器 / 音符溅射编辑器)

目标编辑器现有文件(同一目录):`DialogueEditorState.hx`、`DialogueCharacterEditorState.hx`、`NoteSplashEditorState.hx`,
目前均**没有**自绘菜单栏(对照 `MasterEditorMenu.hx` 是另一套)。最小改造清单:

1. **复制文件与改名**
   - 复制 `CharacterEditorMenuBar.hx` → `XxxEditorMenuBar.hx`;全文把 `Character` 前缀换成 `Xxx`(类名/typedef/枚举/内部函数名);
   - 复制 `CharacterEditorStatusBar.hx` → `XxxEditorStatusBar.hx`(字段按需换成该编辑器指标);
   - 文件头注释、`isTest` 字段、`Check` 枚举、`item_dyn_text`/DynText(Stage 版有成熟用法)按需裁剪。
2. **数据层**:在 `buildMenus()`(原 273-343)里替换 6 个菜单的 items(直接抄 §3 的写法:item_cmd/item_widget/item_label_widget/item_text/item_dyn_text + SEP);
   菜单数量可增可减——顶栏按钮数 = menus.length,宽度按 `MENU_W` 平铺,下拉定位 `activeMenu*MENU_W`。
3. **语言**:新建 `assets/shared/language/{Chinese,English,…}/<group>/<group>.lang`(group 建议 'dialogue'/'dialoguechar'/'notesplash'),
   `Language.resetData()`(CharacterEditorState 120-121)后可用;菜单内所有语言组字符串统一为 `'<group>'`;
   若想沿用现有组,直接把 `Language.get(key,'character')` 全局替换成目标组。
4. **State 接线**(抄 CharacterEditorState 399-455):new MenuBar → uiCamera/cameras=camHUD → `onAction=handleMenuAction` → `onMenuOpened=refreshMenuWidgets`
   → 逐个 registerWidget(widgetKey 必须与 buildMenus 完全一致)→ uiLayer.add;再建 overlayLayer 并 `menuBar.overlayLayer=…`;原生控件全部 add 进 overlayLayer(保证进 update 循环)再统一隐藏禁用。
5. **handleMenuAction**:抄 switch 模式(457-492),列出该编辑器支持的动作;Widget 值变更通过 `getEvent`(893-963)接 CHANGE_EVENT 写模型。
6. **StatusBar**:成员即加即用(构造器 185),State 每帧 setXXX(1044-1070),文案键 `status_*` 放语言文件。
7. **键盘**:在 State.update 按 ChartingState 2444-2505 模式加"菜单开着屏蔽下层输入 + F-键直达菜单 + Ctrl 组合→handleMenuAction";
   若需 ESC 关菜单(当前三编辑器都无此行为),在 State 里先判 `menuBar.activeMenu>=0` 则 closeMenu 再 return。
8. **复用的坑(踩坑清单)**:`dropGroup.visible=true` 必须在 rebuildDropdown 前(1609-1614);隐藏控件的 graphic 会被清,弹覆盖层必须 `_regen`+`drawFrame(true)`(1454-1464);`hasFocus` 只能经 `EditorInputStyle.setInputFocus`(@:privateAccess);覆盖层必须 `active=false`(1471)防 update 抢焦点;`stretchOverlayBackground` 前 origin 置 (0,0)(1412);LabelWidget 原生控件**绝不能** add 进 FlxSpriteGroup 子链(115-116);`FlxTypedGroup.clear()` 不清底层 Array,需手动 splice(2190-2198);描述条高度用 `textField.textHeight` 实测而非按字符估算(2292-2297);`Language.get` 的 "(404)" 要过滤(2280-2283);dropdown 面板按下/拖拽/松开判定避免拖拽误选(724-753);文本超宽走 `scrollH` 走马灯(807-829)。
9. 若三个新编辑器要长期维护,建议下一步**抽出公共基类**(如 `MenuBarBase<TMenuDef,TItemDef,TControl>` 泛型化 typedef+渲染引擎,Editor 专有差异收敛成子类字段/回调),三个旧文件 79-88% 的重复代码即可消灭。

---

*报告生成基于上述源文件逐行阅读与 grep 定位,行号均为 UTF-8/LF 口径。*
