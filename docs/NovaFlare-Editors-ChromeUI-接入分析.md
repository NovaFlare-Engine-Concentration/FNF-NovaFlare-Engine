# NovaFlare 自绘 Chrome UI 接入方式分析（ChartingState vs StageEditorState vs CharacterEditorState）

> 工程根：`C:\Users\Admin1\Desktop\FNF-NovaFlare-Engine-1.2.1`
> 行号以 read/grep 工具为准（LF 计行，含空行）；下表中 `ChartingState`=ChartingState.hx、`MB`=ChartEditorMenuBar.hx、`SB`=ChartEditorStatusBar.hx、`CES`=CharacterEditorState.hx、`CMB`=CharacterEditorMenuBar.hx、`SES`=StageEditorState.hx、`SMB`=StageEditorMenuBar.hx、`WCM`=WindowChromeManager.hx、`WCB`=WindowControlBar.hx、`MP`=ModInfoPopup.hx、`lang:charting`=assets/shared/language/Chinese/charting/charting.lang。

**实际文件行数**（read 工具口径）：ChartingState.hx=5316、ChartEditorMenuBar.hx=2446、StageEditorState.hx=4404、StageEditorMenuBar.hx=2492、CharacterEditorState.hx=1679、CharacterEditorMenuBar.hx=2425、ChartEditorStatusBar.hx=103、CharacterEditorStatusBar.hx=96、StageEditorStatusBar.hx=95。

---

## 0. 术语与总览

三个编辑器（Chart/Character/Stage）共用同一套“自绘 Chrome”架构，由三条代码线构成，且三个 MenuBar 是同一份模板复制衍生（证据：`SMB:22-35` 头注释仍写着“角色编辑器顶栏菜单”+ “Ghost 透明度 slider”，属复制残留；`SMB` 与 `MB` 的常量/字段/函数名几乎逐行同构）：

1. **系统标题栏隐藏（全局自动）** —— 由 `WindowChromeManager` 在 flixel `preStateCreate`/`postStateSwitch` 信号里统一处理，任何编辑器**不需要写一行代码**就能隐藏系统栏（见 §6）。
2. **编辑器自带常驻窗口条 `EditorChromeUI`** —— 是 `WindowControlBar` 的 `CONSTANT` 模式子类（EditorChromeUI.hx:15-20），钉在顶栏右上角 `[图标 NovaFlare Engine] │ 恢复默认 - □ ×`；点击标题触发 `modInfoPopup`（`onTitleClick`）。三个编辑器各自 new 一份。
3. **顶栏菜单栏 + 底部状态栏（Adobe 风格）** —— 每个编辑器一个 `XxxEditorMenuBar`（内含 `XxxEditorStatusBar`），菜单行由 `registerWidget` 注册的**隐藏原生 FlxUI 控件作数据源** + 自绘外观组成；菜单点击/开关全部自绘命中判定。

差异最大的维度（下文逐节展开）：

| 维度 | Chart | Character | Stage |
|---|---|---|---|
| 顶层菜单数 | 8 | 6 | 6 |
| 顶层菜单 key 顺序 | charting/data/event/note/section/song/test/help | char/anim/settings/ghost/file/help | stage/object/camera/view/file/help |
| MenuBar 挂哪个相机 | 默认主相机（`uiCamera=FlxG.camera`），Chrome 挂独立 camHUD | 全部 camHUD | 全部 camHUD |
| super.create() 与 chrome 创建顺序 | menuBar 在 super.create 前 add(538)、chrome 在 super.create 后(560-569) | chrome 在 super.create(227) 前(209-222) | chrome 在 super.create(390) 前(375-388) |
| F 键 | F1~F8 直接 openMenu(0..7) | 仅 F1 打开 help 菜单（查 key=='help'） | F1~F6 toggle 菜单、F7 帮助浮层、F12 选框 |
| menuBar.update 驱动 | 靠 FlxState 组链（ChartingState 结尾 super.update） | 靠组链 | **`menuBar.active=false`，State.update 开头手动 `menuBar.update(elapsed)`**(3040-3041) |
| 菜单打开时输入屏蔽 | 强：grid 鼠标整段 + 组合快捷键整段让位 | 弱：只让动画列表，其余键照常 | 弱：仅输入覆盖层活跃时屏蔽剪贴板块 |

---

## 1. ChartingState 的 chrome 接线（含行号证据）

### 1.1 字段声明
- `var menuBar:ChartEditorMenuBar;`（ChartingState:198）—— 无条件编译，所有平台都有。
- `#if (cpp && windows) var windowChrome:EditorChromeUI; var modInfoPopup:general.objects.ModInfoPopup; var camHUD:flixel.FlxCamera; #end`（ChartingState:199-203）—— **仅窗口 chrome/弹窗/HUD 相机三个成员被条件编译**。

### 1.2 create() 顺序（ChartingState:231 起）
| 步骤 | 行号 | 说明 |
|---|---|---|
| `Language.resetData()` | 234 | 强制刷新语言组（charting 等新分组） |
| 背景/网格/波形/头像等 | 280-419 | 常规场景 |
| addSongUI/addSectionUI/addNoteUI/addEventsUI/addChartingUI/addDataUI | 412-417 | 创建**原生控件（只作数据源）**并 hide |
| menuBar 创建 | 443-445 | `new ChartEditorMenuBar()`；`scrollFactor.set()`；`uiCamera = FlxG.camera` |
| onSelectTab | 446-448 | `UI_box.selected_tab = idx`（旧 tab 逻辑残留） |
| onPlaytest | 449-452 | true→startPlaytest()，false→startNormalPlay() |
| onAction | 453-455 | → `handleMenuAction(actionKey)` |
| onDropdownHoverOption | 457-461 | 仅 `w_event_type`：记录 hoveringEventIdx + refreshDynTexts |
| registerDynText('dyn_event_info') | 463-478 | 事件名+描述提供器 |
| onMenuOpened | 481-483 | → `refreshMenuWidgets(menuKey)`（菜单打开先刷 widget 值再渲染） |
| registerWidget ×45 | 487-536 | `w_metronome … w_difficulty` ↔ 隐藏原生控件 |
| **add(menuBar)** | **538** | 在 super.create() **之前**加入 |
| addLegacyWidgetsToScene / hideAllLegacyWidgets | 541-543 | 原生控件挂场景后整体隐藏（只当数据源） |
| updateGrid / addVirtualPad | 545-547 | |
| **super.create()** | **549** | MusicBeatState.create 里 `initPsychCamera()` 会 `FlxG.cameras.reset` → 所以 chrome 必须在其后创建（551-554 注释） |
| `#if (cpp && windows)` | 551-570 | |
| camHUD 创建 | 555-557 | `new FlxCamera(); bgColor.alpha=0; FlxG.cameras.add(camHUD,false)` |
| windowChrome = new EditorChromeUI() | 560-563 | scrollFactor.set；`cameras=[camHUD]`；add |
| modInfoPopup | 565-568 | 同上挂 camHUD |
| `windowChrome.onTitleClick = () -> modInfoPopup.openUnder(windowChrome)` | **569** | |

> **要点**：Chart 的菜单栏加在主相机上（滚动跟随网格的主相机，靠 scrollFactor=0 保持屏幕固定），只有窗口条/Mod 弹窗挂独立固定 camHUD（551-554 注释明说“自绘窗口条必须挂独立的固定 HUD 相机”）。

### 1.3 update() 中 menuBar 相关（ChartingState:2154-3003）
- 2157：`var menuBarOpen:Bool = (menuBar != null && menuBar.activeMenu >= 0);`（2158-2161 仅留注释位）。
- **菜单打开 = grid 鼠标操作整段让位**：2306-2402 `if (!menuBarOpen) { …右键拖 note/左键加删 note/dummyArrow… }`（注释 2346「菜单栏下拉打开时已在外层 if (!menuBarOpen) 跳过整段」）。
- 文本输入屏蔽（2405-2443）：扫描 `blockPressWhileTypingOn`（hasFocus）/ stepper 内部 input / 展开中的 dropdown，命中 → `ClientPrefs.toggleVolumeKeys(false); blockInput=true`。
- 全局快捷键区（2444-2547，仅 `!blockInput`）：
  - 2447 再取 `menuOpen`；
  - **2448-2455：F1~F8 → `menuBar.openMenu(0..7)`**（先于其它快捷键；即使菜单已开也重开）；
  - 2456 `else if (!menuOpen)` 之后的组合键（见 §3）在菜单打开时不执行。
- 2606-2628：TAB/Shift+TAB —— 菜单开着（activeMenu>=0）时放行给下拉控件，否则切 UI_box 旧 tab。
- 2657-2684：滚轮擦时间 —— `!controls.mobileC && !(activeMenu>=0)` 才生效（菜单打开滚轮归菜单）。
- 2708/2588/2550 等单键（ESC/Enter/Q/E/Space/Z/X/A/D/W/S/方向键/R）**没有**被 `menuOpen` 包住——菜单打开时仍会触发（除非正有输入框聚焦 blockInput）。ESC 在 2550-2553 直接 `startPlaytest()`。
- **状态栏刷新点**：每帧末尾 2921-2931 同步 `setTempo/setClock/setSection/setBeat/setSnap/setMove`；缩放单独在 `updateZoom()` 内 3042-3043 调 `setZoom`（旧 zoomTxt 已隐藏，字段保留，见 436、437-440）。
- 3002：`super.update(elapsed)` 收尾（menuBar 靠 FlxState 组链驱动 update——与 Stage 手动驱动不同）。

### 1.4 handleMenuAction 完整 actionKey 列表（ChartingState:4373-4476）
共 **23 个 case，无 default**：

| actionKey | 行号 | 行为 |
|---|---|---|
| save | 4377-4378 | saveLevel() |
| reload_audio | 4379-4385 | 按标题框歌名重读音频（绕过缓存） |
| reload_json | 4386-4391 | loadJson(歌名) |
| engine | 4392-4411 | 切换 Pe-0.7.3/Pe-1.0.4 并重载 |
| load_autosave | 4412-4413 | loadFromAutosave() |
| load_events | 4414-4415 | loadEventsFromFile() |
| save_events | 4416-4417 | saveEvents() |
| clear_events | 4418-4419 | Prompt 确认后 clearEvents |
| clear_notes | 4420-4428 | Prompt 确认后清空全曲音符 |
| apply_notes | 4429-4430 | applyNoteSkinSelection() |
| copy_section | 4431-4432 | copyCurrentSection() |
| paste_section | 4433-4437 | Prompt(`prompt_paste_section`)→pasteToCurrentSection |
| clear_section | 4438-4442 | Prompt(`prompt_clear_section`)→clearCurrentSection |
| swap_section | 4443-4447 | Prompt(`prompt_swap_section`)→swapSectionSides |
| do_copy_beat | 4448-4452 | Prompt(`prompt_copy_beat`)→copyBeat |
| copy_last_section | 4453-4454 | copyLastSectionToCurrent（**菜单未挂，仅预留？见 §2**） |
| duet_notes | 4455-4459 | Prompt(`prompt_duet_notes`)→duetCurrentSection |
| mirror_notes | 4460-4464 | Prompt(`prompt_mirror_notes`)→mirrorCurrentSection |
| undo | 4465-4466 | undo()（pushUndo 4165/redo 4172 并存，菜单只有 undo） |
| add_event / del_event / prev_event / next_event | 4467-4474 | 事件 CRUD/选择 |

### 1.5 refreshMenuWidgets（ChartingState:4483-4554）
`onMenuOpened(menuKey)` → 按打开的菜单 key 把隐藏原生控件的显示值刷成数据：
- `song`(4487-4491)：歌名/BPM/速度/人声轨道 checkbox；
- `section`(4493-4500)：小节 BPM + mustHit/gfSection/altAnim/changeBPM（include_notes/events 是用户复制设置不刷新）；
- `note`(4502-4513)：sus 长度（相等时 +0.001 强制刷新）、strumTime；
- `event`(4515-4531)：value1/value2（带 Array 类型守卫防原生空指针）；
- `charting`(4533-4544)：节拍器/自动滚动/波形/静音类外全从 FlxG.save.data 读回（mute_* 是运行时状态不刷）；
- `data`(4546-4552)：gameOver 四输入 + disableNoteRGB。

### 1.6 destroy（3047-3052）
只清 `Note.globalRgbShaders` 与 NoteTypesConfig，**无 chrome 清理**——windowChrome/modInfoPopup 随 state members 一并销毁。

---

## 2. ChartEditorMenuBar：顶栏菜单键 + 各菜单条目完整转录

文件 2446 行。布局常量：`BAR_HEIGHT=36`(80)、`STATUS_HEIGHT=25`(81)、`MENU_W=88`(82)、`ROW_H=22`(86)、`DROP_MIN_W/DROP_MAX_W=280/420`(83-84)。状态栏在构造里**最先 add**（179-181，注释 178“确保下拉菜单和描述条在其之上渲染”）；`menus` 数据（270-404）；构造 new()=172-189（statusBar→buildMenuBar→buildDropdown→buildDescBar→buildMenus→applyLang）。

### 2.1 顶栏菜单键（8 个，`menus[i].key`，即视觉顺序 & `openMenu(0..7)` 索引）

| 索引 | key | 顶栏中文 | 定义行 | 对应 F 键 | 映射旧 tab(menuKeyToTabIdx:1484-1496) |
|---|---|---|---|---|---|
| 0 | charting | 谱面 | 273-296 | F1 | 4 |
| 1 | data | 数据 | 297-308 | F2 | 5 |
| 2 | event | 事件 | 309-321 | F3 | 3 |
| 3 | note | 音符 | 322-326 | F4 | 2 |
| 4 | section | 小节 | 327-349 | F5 | 1 |
| 5 | song | 歌曲 | 350-374 | F6 | 0 |
| 6 | test | 测试(isTest:true) | 375-379 | F7 | -1 |
| 7 | help | 帮助 | 380-402 | F8 | -1 |

标题文字：`Language.get('menu_'+m.key, 'charting')`（518）。中文来自 charting.lang 4-11（menu_charting=谱面…menu_help=帮助）。
**翻译约定（全文件统一，分组 'charting'）**：顶栏 `menu_*`；Cmd/TextLine 行 `item_*`（1575/1597/1951/1879）；Widget 行经 `translateItemKey`(436-447)：`w_xxx → item_xxx`（miss 再退 `xxx`）；LabelWidget 行经 `translateLabelKey`(450-462) 直查/加 `label_` 前缀/原样，渲染时拼 `:`(1747)；描述条 `desc_*`(2186)。缺 key 框架回退 `key (404)`/原 key（Language.hx:18-23）。

> lang:charting 的 label_* 键在文件内重复定义两次（106-131 与 242-270，后写覆盖前写），生效版带冒号，代码又拼 `:` → 个别行可能显示 `BPM::`（记录为已知瑕疵）。

### 2.2 菜单① charting 谱面（MB:273-296）
| 条目(labelKey/widgetKey) | 类型 | 中文标签 | 动作/绑定 | 快捷键提示 | lang 行 |
|---|---|---|---|---|---|
| w_metronome | Widget(勾选) | 节拍器 | 原生 checkbox 作数据源；点击 toggle | — | 29 |
| w_autoscroll | Widget | 禁用自动滚动（不建议） | checkbox | — | 30 |
| ─ SEP(276) | | | | | |
| w_bpm_stepper | LabelWidget(stepper) | BPM | stepper | — | 106/242 |
| w_metronome_offset | LabelWidget(stepper) | 偏移 (ms) | stepper | — | 107/243 |
| ─ SEP(279) | | | | | |
| w_waveform_inst | Widget | 波形图 器乐 | checkbox | Alt+I | 33 |
| w_waveform_main | Widget | 波形图 主音 | checkbox | Alt+U | 34 |
| w_waveform_opp | Widget | 波形图 对手音 | checkbox | Alt+O | 35 |
| ─ SEP(283) | | | | | |
| w_mute_inst | Widget | 静音器乐 | checkbox | Alt+Ctrl+I | 36 |
| w_mute_main | Widget | 静音主音 | checkbox | Alt+Ctrl+U | 37 |
| w_mute_opp | Widget | 静音对手音 | checkbox | Alt+Ctrl+O | 38 |
| ─ SEP(287) | | | | | |
| w_vortex | Widget | Vortex 编辑器 | checkbox | Ctrl+Shift+Tab | 39 |
| w_ignore_warnings | Widget | 忽略进度警告 | checkbox | — | 40 |
| w_sfx_bf | Widget | 校对 BF 音符 | checkbox | Ctrl+Shift+U | 41 |
| w_sfx_opp | Widget | 校对 对手音符 | checkbox | Ctrl+Shift+O | 42 |
| ─ SEP(292) | | | | | |
| w_inst_volume / w_voices_volume / w_voices_opp_volume | LabelWidget(stepper)×3 | 器乐/主音/对手音量 | stepper | — | 108-110/244-246 |

### 2.3 菜单② data 数据（MB:297-308）
| 条目 | 类型 | 中文 | 动作 | lang |
|---|---|---|---|---|
| w_go_char / w_go_sound / w_go_loop / w_go_end | LabelWidget(input)×4 | 游戏结束角色/死亡音效/循环音乐/重试音乐 | input | 111-114/247-250 |
| ─ SEP(302) | | | | |
| w_no_rgb | Widget | 禁用音符 RGB | checkbox | 49 |
| ─ SEP(304) | | | | |
| w_note_skin / w_note_splash | LabelWidget(input)×2 | 音符皮肤/音符溅射 | input | 115-116/251-252 |
| **apply_notes** | **Cmd** | 应用音符更改 | callAction('apply_notes')→CS 4429 | 52 |

### 2.4 菜单③ event 事件（MB:309-321）
| 条目 | 类型 | 中文 | 动作 | lang |
|---|---|---|---|---|
| w_event_type | LabelWidget(dropdown) | 事件类型 | dropdown；hover 触发 onDropdownHoverOption + **右侧浮动描述面板**（311-312 注释：原 dyn_event_info 行改浮动面板；面板实现 2242-2347） | 117/253 |
| ─ SEP(313) | | | | |
| w_value1 / w_value2 | LabelWidget(input)×2 | 值 1 / 值 2 | input | 118-119/254-255 |
| ─ SEP(316) | | | | |
| add_event / del_event / prev_event / next_event | Cmd×4 | 添加/删除事件、上一个、下一个 | callAction→CS 4467-4474 | 58-61 |

### 2.5 菜单④ note 音符（MB:322-326）
w_sus_length（持续长度，stepper，lang 256）、w_strum_time（击打时间 (ms)，input，257）、w_note_type（音符类型，dropdown，258）。纯“编辑当前选中音符”面板。

### 2.6 菜单⑤ section 小节（MB:327-349）
| 条目 | 类型 | 中文 | 动作 | 快捷键提示 |
|---|---|---|---|---|
| w_must_hit | Widget | 玩家小节 | checkbox | U |
| w_gf_section | Widget | GF 小节 | checkbox | I |
| w_alt_anim | Widget | 替身动画 | checkbox | — |
| ─ SEP(331) | | | | |
| w_beats_per_section | LabelWidget(stepper) | 当前小节节拍 | stepper | — |
| w_change_bpm | Widget | 更改 BPM | checkbox | — |
| w_section_bpm | LabelWidget(stepper) | 小节 BPM | stepper | — |
| ─ SEP(335) | | | | |
| copy_section | Cmd | 复制小节 | CS 4431 | Ctrl+C |
| paste_section | Cmd | 粘贴小节 | Prompt→CS 4433 | Ctrl+V |
| clear_section | Cmd | 清空小节(危险红) | Prompt→CS 4438 | — |
| swap_section | Cmd | 交换小节 | Prompt→CS 4443 | Ctrl+U |
| w_copy_beat | LabelWidget(stepper) | 复制节拍 | stepper | — |
| do_copy_beat | Cmd | 执行复制 | CS 4448 | — |
| duet_notes | Cmd | 二重奏音符 | CS 4455 | Ctrl+I |
| mirror_notes | Cmd | 镜像音符 | CS 4460 | Ctrl+O |
| ─ SEP(344) | | | | |
| undo | Cmd | 撤销上一步 | CS 4465 undo() | Ctrl+Z |
| ─ SEP(346) | | | | |
| w_include_notes / w_include_events | Widget×2 | 包含音符/包含事件（复制设置） | checkbox | — |

> 该菜单是 Chart 独有的核心机制区：**section 复制/粘贴/清空/交换/复制节拍/二重奏/镜像 + undo**；所有破坏性动作先弹 Prompt（4419 起）。

### 2.7 菜单⑥ song 歌曲（MB:350-374）
| 条目 | 类型 | 中文 | 动作 | 快捷键提示 |
|---|---|---|---|---|
| w_song_title | LabelWidget(input) | 歌曲名 | input | — |
| w_difficulty | LabelWidget(input) | 难度 | input（留空=歌名.json，填了=歌名-难度.json） | — |
| w_has_voice | Widget | 人声轨道 | checkbox | — |
| ─ SEP(354) | | | | |
| save | Cmd | 保存 | CS 4377 saveLevel | **Ctrl+S** |
| reload_audio | Cmd | 重载音频 | CS 4379 | Ctrl+Shift+Q |
| reload_json | Cmd | 重载 JSON | CS 4386 | Ctrl+Shift+W |
| engine | Cmd | 引擎 | CS 4392 | — |
| load_autosave | Cmd | 载入自动保存 | CS 4412 | Ctrl+Shift+E |
| load_events | Cmd | 载入事件 | CS 4414 | Ctrl+Shift+R |
| save_events | Cmd | 保存事件 | CS 4416 | Ctrl+Shift+S |
| ─ SEP(362) | | | | |
| clear_events | Cmd | 清空事件 | Prompt→CS 4418 | Shift+Del |
| clear_notes | Cmd | 清空音符 | Prompt→CS 4420 | Ctrl+Del |
| ─ SEP(365) | | | | |
| w_bpm | LabelWidget(stepper) | BPM(label_song_bpm) | stepper | — |
| w_speed | LabelWidget(stepper) | 速度(label_song_speed) | stepper | — |
| w_mania | LabelWidget(stepper) | 键数(label_song_mania) | stepper（数据 0=1K…实际 4K 存 3） | K+数字 |
| ─ SEP(369) | | | | |
| w_stage / w_player1 / w_gf / w_player2 | LabelWidget(dropdown)×4 | 舞台/对手/女友/玩家 | dropdown | — |

### 2.8 菜单⑦ test 测试（MB:375-379，isTest=true）
- `test_mode`（以测试模式进行）主按钮渐变样式，`Esc`；`() -> callPlaytest(true)` → CS:449-452 startPlaytest()（EditorPlayState）。
- `normal_mode`（以正常模式进行）链接样式，`Enter`；callPlaytest(false) → startNormalPlay()（PlayState）。

### 2.9 菜单⑧ help 帮助（MB:380-402）
标题行用 `item_label_widget('help_nav'…,'label_help_nav'…)`——widgetKey 未注册 → 只渲染标签（右侧留白）；正文为 `item_text` 的 TextLine 行（导航/音符/播放/编辑四组，lang 216-239）。文本行点击**不关菜单**（589-591：help 菜单特判）。

### 2.10 相比 CharacterEditorMenuBar 独有的机制（差异清单）
1. **菜单数量/结构**：8 个菜单且带“事件/音符/小节/歌曲/谱面/数据”数据型面板 vs Character 6 个（char/anim/settings/ghost/file/help）。
2. **快捷键提示列**：Cmd 行(1993-2000)、Widget 行(1706-1713)右侧灰色小字（如 Ctrl+S/Alt+I）；Character 的 item_cmd 无 shortcut 参数。
3. **undo/section 操作**：小节复制/粘贴/交换/二重奏/镜像 + undo（见 2.6）；Character 无小节概念、无菜单级 undo（Ctrl+Z 只在 CES 里做 offset 撤销）。
4. **音符网格/mania**：song 菜单 w_mania stepper + `K+数字`；修改 → CS 2012-2019 → reloadGridLayer(3130)。Character 无网格。
5. **测试菜单（Esc/Enter 试玩）**：Character/Stage 都没有（isTest 字段在 MB 也从未读取，样式靠 labelKey 特判 1953-1956）。
6. **事件信息浮动面板 + dyn_event_info provider**（MB:2242-2347；CS:463-478）；Character 的 DynText 机制是死代码（有实现零使用，CMB 无 item_dyn_text 条目、CES 不调 registerDynText）。
7. **onSelectTab / onPlaytest / onDropdownHoverOption 回调**（MB:159/163/125）被 Chart 使用；Character 全部未用（CMB 只有 onAction/onMenuOpened）。
8. **菜单打开刷新数据粒度**：CS 的 refreshMenuWidgets 按 menuKey 分 6 组精确刷新；CES 的 refreshMenuWidgets 不分菜单全量 reload（CES:495-500）。
9. **危险操作确认**：Chart 每个 destructive 命令包 Prompt 子状态（带 Language prompt_* 文案）；Character 的删除动画等无 Prompt。

---

## 3. 快捷键总表

### 3.1 先厘清“谁拦截”
**menuBar 本身不拦截任何全局快捷键**（MB 全文件无 FlxG.keys 监听；shortcut 字段只是“右侧灰色提示小字”，MB:2378、1706-1713、1993-2000）。所有键由各 State.update 的 FlxG.keys 轮询处理；菜单内输入聚焦（原生 input/stepper 的 hasFocus）时 State 用 blockInput/return 让位。F 键只是“转成菜单打开”，不是“转成 actionKey”；转成 actionKey 的是组合键直接调 `handleMenuAction`/等价函数。

### 3.2 ChartingState（CS:2444-2855，均在 `if (!blockInput)` 内）
| 按键 | 动作 | 行号 |
|---|---|---|
| F1~F8 | `menuBar.openMenu(0..7)`（= charting/data/event/note/section/song/test/help） | 2448-2455 |
| Shift+Del / Ctrl+Del | handleMenuAction('clear_events') / ('clear_notes') | 2463-2467 |
| Ctrl+Shift+Q / W / E / R / S | reload_audio / reload_json / load_autosave / load_events / save_events | 2472-2476 |
| Ctrl+Shift+TAB | toggleVortexShortcut() | 2477 |
| Ctrl+Shift+U / O | toggleSfxShortcut('bf'/'opp')（打击音） | 2478-2479 |
| Alt+Ctrl+U / I / O | 静音 BF / Inst / Opp | 2485-2487 |
| Alt+U / I / O | 波形图 BF / Inst / Opp | 2491-2493 |
| Ctrl+U / I / O | swapSectionSides / duetCurrentSection / mirrorCurrentSection | 2499-2501 |
| Ctrl+C / V | copyCurrentSection / pasteToCurrentSection | 2502-2503 |
| **Ctrl+S** | handleMenuAction('save')→saveLevel | 2504 |
| U / I / O（单键） | mustHit=true / gfSection 翻转 / mustHit=false | 2510-2530 |
| **K + `` ` ``/1~9** | setManiaByKey(1..10)（K+数字=键数） | 2534-2546 |
| ESC | startPlaytest()（测试模式） | 2550-2553 |
| Enter | startNormalPlay() | 2554-2557 |
| Q / E（选中音符） | 持续长度 ±stepCrochet | 2561-2568 |
| Backspace | autosave→退回 MasterEditorMenu/Freeplay | 2571-2586 |
| **Ctrl+Z** | undo() | 2588-2591 |
| Z / X | 缩放 −/+（Ctrl 按下时 Z 不缩放，转 undo） | 2595-2604 |
| Tab / Shift+Tab | 切功能页（菜单开时放行给下拉） | 2606-2628 |
| 空格 | 播放/暂停 | 2630-2647 |
| R / Shift+R | 重置小节(回曲首/当前) | 2649-2655 |
| 滚轮 | 擦时间（!menuOpen 且 !mobile） | 2657-2684 |
| W / S | 播放头上下滚动（Shift×4 / Ctrl×0.25） | 2689-2706 |
| ↑ / ↓ | 按吸附量化跳 | 2710-2729 |
| ← / → | 循环吸附精度 | 2744-2761 |
| 数字 1~8（Vortex 开） | 放置音符 doANoteThing | 2763-2777 |
| A / D | 上/下小节（Shift×4 / Alt×10） | 2842-2854 |

菜单打开（activeMenu>=0）时被让位的只有：**grid 鼠标操作（2306-2402）+ 2457-2547 组合键区 + 滚轮**；单键编辑类（ESC/Enter/Space/Z/X/A/D/W/S/方向键/R/Q/E）在菜单打开时仍执行（除非输入框聚焦）。

### 3.3 CharacterEditorState（CES:1039-1423，行号见角色子报告并经实读核对）
- J / K / L / I：相机平移；Q / E：缩放；R：重置缩放（1092-1125 一带，子报告给出 1092-1114）。
- W / S：切上一个/下一个动画（1122-1125）。
- 方向键 / 按住右键拖：offset 调整（1169-1203）。
- **Ctrl+C / V / R / Z / Y**：复制/粘贴/重置/撤销/重做当前动画 offset；**Ctrl+S**：saveCharacter()（1205-1236）。
- 空格：重播动画（1267）；A / D：逐帧（1285-1302）。
- F12：剪影开关（1400-1401）；**F1：打开 help 菜单**（1403-1411，遍历 menus 找 key=='help'）；ESC：退出（1412-1423）。
- 菜单打开（activeMenu>=0）只让动画列表 hover/滚轮/点击（1305-1344 区间），**其余键不屏蔽**；文本输入聚焦时直接 return（1072-1077）。

### 3.4 StageEditorState（SES:3036-3251）
- F1~F6：`toggleMenuHotkey(0..5)` —— 开着的再按**关闭**（3080-3086；toggle 语义 1324-1333），映射 stage/object/camera/view/file/help。
- F7：帮助浮层开/关（3121-3136）；F12：选择框（3143）。
- **Ctrl+Z / C / X / V、Delete**：undo / copy / cut / paste / delete（3088-3104）——外面包 `menuBar.isInputOverlayActive()` 判定，输入覆盖层活跃时跳过。
- W / S：对象列表上下选（3106-3119）；方向键/右键拖：移动对象（shift×4、ctrl×0.25，3146-3239）。
- Q/E、J/K/L/I、R：相机缩放/平移/重置；ESC：帮助/教程浮层优先关，其次 unsaved 时弹 `ConfirmationPopupSubstate`（3059-3078）。

### 3.5 键数汇总
| 键 | Chart | Character | Stage |
|---|---|---|---|
| ESC | 测试模式 startPlaytest | 退出编辑器 | 关浮层→退出/确认框 |
| F1 | 打开谱面菜单 | 打开帮助菜单 | toggle 舞台菜单 |
| F7/F8 | 测试/帮助菜单 | — | F7 帮助浮层 |
| Ctrl+S | saveLevel | saveCharacter | —(save 只在 file 菜单 Cmd) |
| Ctrl+Z | undo（谱面） | offset 撤销 | doUndo（stageJson 快照） |
| Ctrl+C/V | 复制/粘贴小节 | 复制/粘贴 offset | 复制/粘贴对象 |
| Delete | Ctrl/Shift+Del 清 note/事件 | — | 删除对象 |
| 数字键 | K+数字=键数；Vortex 下 1-8 放音符 | — | — |

---

## 4. ChartEditorStatusBar 字段与 setter（SB:1-103，全文件 103 行）

继承 `FlxSpriteGroup`。头注释（11-18）：显示 `Zoom | 时间(s) | mm:ss | Section | Beat | Snap | Move Note Mode`；只在整串变化时写 `rootLabel.text`（防逐帧抽搐闪烁）。

| 项目 | 值/行号 |
|---|---|
| BG_COLOR=0xFF1C1F28（卡片面板底） | 22 |
| TEXT_DIM=0xFF86909C / TEXT_VAL=0xFFF2F3F5 / SEP_COLOR=0x14FFFFFF | 23-25 |
| `public static final HEIGHT:Int = 25`（== STATUS_HEIGHT） | 27 |
| 成员 bg / rootLabel / sepText='  \|  ' | 29-31 |
| 状态字段（public var） | zoomStr='1 / 1'(34)、tempoStr='0.00s / 0.00s'(35)、clockStr='0:00 / 0:00'(36)、sectionStr='0'(37)、beatStr='0'(38)、snapStr='16th'(39)、moveStr='False'(40) |
| 缓存 `_lastFullText` | 43 |
| new() | 45-59：bg(48) + 顶线(50-52) + rootLabel(54-56)，`applyLang()` |
| **applyLang()** | 61-67：换 `ChartEditorMenuBar.langFont()`（= EditorInputStyle.langFontFileName，读 main 语言组的 fontName）、清缓存、refreshText |
| **setter（全 7 个，一行赋值+refreshText）** | setZoom(69) setTempo(70) setClock(71) setSection(72) setBeat(73) setSnap(74) setMove(75) |
| refreshText() | 77-96：parts=[`status_zoom`+zoom, **空串**, tempo, clock, `status_section`+section, `status_beat`+beat, `status_snap`+snap, `status_move`+move] 用 '  \|  ' join；diff 后写 text |
| update() | 98-102：`this.y = ChartEditorMenuBar.BAR_HEIGHT`(36) 每帧贴到顶栏正下方 |

**Language 键**（分组 `'charting'`，charting.lang 14-21）：`status_zoom`(缩放:)、`status_section`(小节:)、`status_beat`(节拍:)、`status_snap`(吸附:)、`status_move`(移动音符模式:)，另有 status_tempo 空键、status_move_on/off（未被使用——ChartingState 传 `Std.string(noteMove)` 即 true/false 原文，2921-2931）。

**三编辑器 StatusBar 对比**：三份是同一模板（文件头注释互指“同款”）。Stage/Character 版 5 段（stage/character、directory/anim、object/offset、pos/frame、zoom）+ 5 个 setter（StageEditorStatusBar.hx:66-70、CharacterEditorStatusBar.hx:67-71），BG=0xFF12141A、TEXT_VAL=0xFFC9CDD4；Chart 版 7 段卡片底（BG=0xFF1C1F28、TEXT_VAL=0xFFF2F3F5），字段/分隔符/防闪烁缓存逻辑一致。Language 分组分别是 'charting' / 'character' / 'stage'（Stage 的 status_stage/status_directory/status_object/status_pos/status_zoom 见 stage.lang 11-15；Character 的 status_character/status_anim/status_offset/status_frame/status_zoom 见 character.lang 11-15）。

---

## 5. StageEditorState / StageEditorMenuBar 差异要点（相对 Chart/Character）

**State 侧（SES=4404 行）**
1. 字段：`menuBar`(148，无条件)；`#if (cpp && windows) windowChrome/modInfoPopup #end`(149-152)；`camHUD` 与 `overlayLayer` **无条件**（68、153）—— Stage 是唯一 camHUD 不进条件编译的编辑器（Chart:199-203 条件编译含 camHUD；Character:60 无条件）。
2. create（184-391）：Language.resetData(187，还带 `Language.get('menu_stage','stage')` 自检日志 190)；camHUD 在 206-208 就建（release 用 DebugCamera 自建、手动 `_psychCameraInitialized=true`，198-204，不走 initPsychCamera）；overlayLayer 274-277；menuBar 281-355（onAction=onMenuAction 285、onMenuOpened=286、registerWidget 22 个 287-304、**registerDynText ×7（obj_name/type/image/pos/scale/alpha/angle）305-311**、**dynamicMenuKey='object' + dynamicItems 回调 314-354**（每次打开现场生成对象清单 RawCmd 行）、add 355、`menuBar.overlayLayer=overlayLayer` 356、**`menuBar.active=false` 360**（注释 357-359：State.update 有提前 return，改用 update 开头手动驱动））；windowChrome+modInfoPopup+onTitleClick 375-388；`super.create()` 在 390（chrome 在其前——因已手动置 _psychCameraInitialized 不再 reset 相机，与 Chart 相反，与 Character 相同）。
3. update（3036-3251）：**3040-3041 每帧开头手动 `menuBar.update(elapsed)`**（在所有提前 return 之前）；随后业务；**super.update 出现两次（3051 与 3242）**——普通帧双跑，疑似残留；末尾 3246-3250 刷状态栏 + `menuBar.refreshDynTexts()`。
4. 菜单打开**几乎不屏蔽键盘**：只有 `isInputOverlayActive()` 包住剪贴板块（3088-3104）；无 Chart 那种 `!menuBarOpen` 包大段。
5. 命名：无 `handleMenuAction`/`refreshMenuWidgets`；等价物是 `onMenuAction`（**1020-1100，16 个 case**：reload_stage/load_template/save/obj_new_sprite/obj_new_animated/obj_new_square/obj_delete/obj_duplicate/obj_anim/obj_move_up/obj_move_down/toggle_help/tutorial/focus_bf/focus_dad/focus_gf —— 大量复用旧隐藏 PsychUI 按钮的 onClick 回调）+ `onMenuOpened`（1289-1311，不按 menuKey 分，一次刷全部 stage 数据 checkbox/stepper）。
6. ESC：浮层优先→退出或 `ConfirmationPopupSubstate`（有 unsaved 提示，3059-3078）——Chart 的 ESC 是试玩。

**MenuBar 侧（SMB=2492 行）**
1. 头注释错写成“角色编辑器”（22-35），含 slider/Ghost 描述 —— 模板复制残留。
2. 6 个顶层菜单（buildMenus 243-318，全 isTest:false）：
   - stage(246-253)：w_stage_select(dropdown 选舞台)/w_directory(资源目录)/w_hide_gf/w_default_zoom/w_cam_speed；
   - object(254-275)：8 个 Cmd（new_sprite/new_animated/new_square/delete/duplicate/anim 动画编辑器/move_up/move_down）+ **7 行 item_dyn_text（obj_name/type/image/pos/scale/alpha/angle）** + 3 个角色显隐 Widget（w_show_bf/dad/gf）；
   - camera(276-285)：w_cam_zoom/w_cam_target + bf/dad/gf 六个相机偏移 stepper；
   - view(286-293)：w_low_quality/w_high_quality + focus_bf/dad/gf 三个 Cmd；
   - file(294-298)：save/reload_stage/load_template（无 chart 的 engine/events/autosave 等）；
   - help(299-316)：tutorial Cmd + 文本行（help_camera/obj/other 三组）。
3. **动态菜单机制**（Chart/Character 都没有）：`dynamicMenuKey`+`dynamicItems`（241-242、1638-1647），打开 object 菜单时 `dynamicItems()` 生成的对象清单 **RawCmd 行 concat 到静态 items 之后**（1635-1647）；RawCmd 行不翻译、getChecked 驱动左侧选中标记（2074-2117、2410-2423）；Cmd 点完关菜单、**RawCmd/Widget/LabelWidget 保持打开**（622）。
4. 无 shortcut 提示列（item_cmd/item_widget 无 shortcut 参数，323-335）；无 onSelectTab/onPlaytest；有 `isInputOverlayActive()`（1579）供 State 查询输入覆盖层。
5. 下拉固定宽 `DROP_MIN_W=DROP_MAX_W=420`（73-75，Chart 是 280~420 自适应）；dropY=`BAR_HEIGHT+2`（1720，紧贴顶栏覆盖状态栏）vs Chart `BAR_HEIGHT+STATUS_HEIGHT+2`（1608，状态栏下方）。
6. 菜单标题 `Language.get('menu_'+key,'stage')`（447）；行文本/描述全走 'stage' 组（1680/1688/1709/2132/2344）。
7. 自绘控件含 slider 能力（ctype 'slider'，1958/763-768/1117-1154），但 Stage 菜单数据未用（该能力来自 Character 的 w_ghost_alpha，属复制带过来的能力）。

---

## 6. 系统窗口标题栏：编辑器运行时是否隐藏？由谁、在哪隐藏？

**结论：运行时系统标题栏隐藏（沉浸式），且是全局默认，三个编辑器 + 所有普通界面都一样。**

调用链（给出文件:行号）：

1. `MusicBeatState.create()` 里 `general.backend.device.WindowChromeManager.onStateChanged(this);`（MusicBeatState.hx:198-202，`#if cpp&&windows`）。
2. `WCM.onStateChanged`（WCM:125-132）→ `ensureInit()`（WCM:259-291）订阅三个 flixel 全局信号：
   - `FlxG.signals.preStateCreate` → `onPreStateCreate` → `applyChromeForState`（WCM:138-144/186-203）——**在新状态 create() 之前**切换系统栏/视口（保证 UI 按扩展逻辑尺寸布局，WCM:25-27 注释）；
   - `FlxG.signals.postStateSwitch` → `onPostStateSwitch`（WCM:147-171）——状态 create 完成后，若该状态不在 `editorScreens` 里则自动挂一条 AUTO_HIDE `WindowControlBar`；
   - `FlxG.signals.postUpdate` → `tickChrome`（WCM:289/61-91）——chrome 相机对齐 + 窗口模式变化后重建自绘条。
3. `applyChromeForState`：`immersive = !isStateIn(state, keepChromeScreens)`；`keepChromeScreens=[]`（WCM:32）→ **默认所有界面沉浸 → `setSystemChrome(false)`**（WCM:186-203/206-238）。
4. `WCM.setSystemChrome(false)` → `Native.setWindowChromeVisible(false)`（Native.hx:1248-1261）→ cpp `setWindowChromeNative(show)`（Native.hx:104-143）：`SetWindowLongPtr(GWL_STYLE)` 去掉 `WS_CAPTION|WS_THICKFRAME`（128-136）、`SetWindowPos` 保持外框不动让客户区上扩（137-141），并同步 SDL `win.borderless=true`（1258-1260）。
5. **编辑器特例**：`editorScreens = [ChartingState, CharacterEditorState, StageEditorState]`（WCM:35-37）只影响“不自动挂 AUTO_HIDE 条”（WCM:154-155），因为编辑器**自带常驻 CONSTANT 窗口条**。隐藏系统栏本身是全局默认，无需编辑器做任何事。

**自绘窗口条本体（EditorChromeUI / WindowControlBar）**
- `EditorChromeUI extends WindowControlBar`，构造传 `WindowBarMode.CONSTANT`（EditorChromeUI.hx:15-20）。`WindowBarMode` 两值：CONSTANT（编辑器常驻，融入菜单栏右上）/ AUTO_HIDE（普通界面顶部滑入）。
- `WCB.BAR_HEIGHT=36`（WCB:40）——与各 `XxxEditorMenuBar.BAR_HEIGHT=36` 相同，窗口条贴在编辑器顶栏右侧同一高度；CONSTANT 布局：标题块右对齐到 restoreX-16（WCB:387-392），按钮列 `[恢复默认][-][□][×]` 钉右缘（closeX=w-46…WCB:367-371）；拖动区=分隔线右→restoreX（WCB:844-845）。
- **onTitleClick**：声明 `public var onTitleClick:Void->Void`（WCB:92-93，注释“CONSTANT 模式单击标题/图标区（未拖动）时触发”）；触发点 WCB:763-764（单击判定，区分拖窗 dragCandidate）；三个编辑器统一接 `windowChrome.onTitleClick = () -> modInfoPopup.openUnder(windowChrome);`（ChartingState:569 / CES:221 / SES:387）。
- **modInfoPopup.openUnder(bar)**（MP:99-176）：宽度=标题块宽（`bar.titleBlockWidth()`/`titleAnchorX()`，WCB:96-108），y=WCB.BAR_HEIGHT（MP:118）；内容=当前 mod pack 名/图标/描述（MP:201-229），无 mod 时空态文案并解锁成就“自欺欺人”（MP:217-228）；滚轮+拖拽滚动、点面板外关闭（MP:286-335）。窗口条按钮交互由 `FlxG.signals.postUpdate` 全局 ticker 驱动（WCB:50-52/131-136/149-160），不依赖某个 state 的 update 链。

**一处易踩坑**：窗口条按钮每帧由全局 ticker 驱动；若某编辑器状态切换成新 state 时没把自己的 EditorChromeUI 销毁（实例随 state members 销毁，一般无碍），残留 bar 会留在 `tickers` 里——三个编辑器均无显式 destroy chrome 的代码（ChartingState.destroy 3047-3052 只清 Note 数据）。

---

## 7. 新编辑器“自绘 Chrome”接入清单（最小步骤）

以 ChartingState 为模板（它最完整），另参照 WCM 的自动化：

1. **继承 MusicBeatState**（或走同样 create 链），不要重复实现 chrome 切换——`MusicBeatState.create` 已调 `WCM.onStateChanged`，系统标题栏自动隐藏（MusicBeatState.hx:201）。
2. 字段：`var menuBar:XxxEditorMenuBar;` + `#if (cpp && windows) var windowChrome:EditorChromeUI; var modInfoPopup:general.objects.ModInfoPopup; #end`；需要独立 HUD 相机的编辑器另加 `var camHUD:FlxCamera`（Chart 的做法；Character/Stage 则始终建 camHUD 给全部 UI 用）。
3. create() 首行 `Language.resetData()`（确保新语言组被加载；若你的菜单组是新建的必须在此触发 `discoverGroups`）。
4. 新建 `assets/shared/language/<English|中文>/<groupName>/<groupName>.lang`：顶栏标题 `menu_<key>`、行标签 `item_<labelKey>` / `label_<labelKey>`、描述 `desc_<descKey>`、状态栏 `status_*`、危险操作 `prompt_*`。语言系统=目录发现（Language.hx:34-64）+ English 作 defaultData / 当前语言作 data（CustomLangGroup.hx:24-38）。
5. 自建原生控件（FlxUICheckBox/InputText/NumericStepper/DropDownMenu）**只当数据源**，按旧 UI 创建好并 hide/active=false。
6. 拷贝一份现有 MenuBar（Chart/Stage/Character 三选一最接近的）→ 改类名/颜色常量/`buildMenus()` 菜单数据（key 顺序 = 顶栏顺序 = F1..Fn 索引）。在构造里先 add statusBar 再 build。
7. State 里接线：`menuBar.onAction=(k)->handleMenuAction(k)`、`onMenuOpened=(mk)->refreshMenuWidgets(mk)`、逐个 `registerWidget('w_xxx', nativeWidget)`；需要动态文本就 `registerDynText`。
8. `add(menuBar)` 位置：若主相机在 super.create() 里会被 `initPsychCamera` reset（MusicBeatState.create 会在你 create 后段跑），则 chrome 相关对象放 `super.create()` **之后**建并显式挂独立 camHUD（Chart 模式 551-570）；若你手动管理 `_psychCameraInitialized`，可像 Character/Stage 一样全放 super.create 前。
9. `#if (cpp && windows)`：`windowChrome=new EditorChromeUI(); cameras=[camHUD]; add(...)`；`modInfoPopup` 同相机 add；`windowChrome.onTitleClick = () -> modInfoPopup.openUnder(windowChrome);`。
10. update()：需要“菜单打开让位”就查 `menuBar.activeMenu >= 0`（Chart:2157 等）；若 update 存在提前 return，把 `menuBar.active=false` 并在 update 开头手动 `menuBar.update(elapsed)`（Stage 模式 360/3040-3041）。
11. 状态栏：State 每帧调用 `menuBar.statusBar.setXxx(...)`（各字段 diff 防闪烁逻辑内置）。
12. 可选：把新 state 加入 `WCM.editorScreens`（WCM:35-37）——不加也能跑（会自动挂 AUTO_HIDE 条），但按惯例编辑器自带 CONSTANT 条应加进去。
13. 别忘 ESC/Backspace 退出路径 + destroy 里无需 chrome 清理（随 state 销毁）。

---

## 附：值得复核的代码疑点（给后续维护）
1. `StageEditorState.update` 两次 `super.update(elapsed)`（3051 与 3242）——普通帧双跑，疑似残留（SES 子分析报告指出）。
2. `SMB` 头注释写“角色编辑器”（22-35）、`CMB` 类头注释与实际 key（“外观”=ghost）不一致（CMB:25）——模板复制残留。
3. `CMB` 的 `isMouseInsideUI` 注释声称 State 调用，实际 CES 只读 `activeMenu`（注释漂移）。
4. Chart 菜单打开时 ESC/单键编辑键仍生效（2444-2855 结构）；ESC 不关下拉而是直接进试玩——如与预期不符需在 2550 前加 `menuOpen` 判定。
5. lang:charting 的 `label_*` 键重复两段、status_tempo 空值、move 状态传 true/false 未用 status_move_on/off。
