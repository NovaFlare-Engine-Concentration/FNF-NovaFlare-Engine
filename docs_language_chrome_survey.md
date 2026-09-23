# NovaFlare(Haxe/FNF)语言系统与窗口 Chrome 机制盘点报告

> 目的:为三个新编辑器(DialogueEditorState / DialogueCharacterEditorState / NoteSplashEditorState,均位于 `source\developer\editors\`)接入"自绘顶栏菜单 + 自绘窗口控制条"做准备。
> 工程根:`C:\Users\Admin1\Desktop\FNF-NovaFlare-Engine-1.2.1`。所有结论均附 `文件:行号` 证据。

---

## 0. 结论速览(为三个新编辑器直接可用的要点)

| 事项 | 现状 | 结论 |
|---|---|---|
| 语言包格式 | 不是 JSON,是 `.lang` 行格式 `key => value`(每行一条,`#` 注释) | 新增键 = 往对应语言包的 `.lang` 里加行 |
| 语言包位置 | `assets/shared/language/<语言名>/<组名>/*.lang` | 最少必须保证 English;其它语言缺键自动回落 English |
| 三个新编辑器现状 | 只用 `Language.get('fontName','main')` 取字体;所有 UI 文案均为硬编码英文 | 需要新建语言组(如 `dialogue` / `noteSplash`)或并入既有组 |
| 系统标题栏 | 全状态默认"沉浸式":进任意状态自动隐藏系统标题栏;编辑器额外挂自绘 CONSTANT 窗口条 | 三个新编辑器目前会被自动挂 AUTO_HIDE 条;接菜单栏后应把它们登记进 `editorScreens` 并自挂 `EditorChromeUI` |
| 移动端 | 键盘/虚拟键双分支;自绘下拉菜单本身是纯鼠标交互 | 三个新编辑器无 virtualPad,移动端默认走 EMK 自定义按键注入 FlxG.keys 的分支 |
| MasterEditorMenu | 三个新编辑器都已有入口键(editors.lang) | 无需加菜单项 |

---

## 1. 语言包位置与格式、编谱器/角色编辑器使用的组与键

### 1.1 代码入口

- `source\general\backend\language\Language.hx`
  - `get(value, type='options')`:`type` 就是"组名",缺组/缺键时开发者模式返回 `value + ' (404)'`,否则原样返回键名(Language.hx:18-24)。
  - `discoverGroups()`(Language.hx:34-64):扫 `Paths.getPath('language')/<ClientPrefs.data.language>/` 下的**子目录**,每个目录名 = 一个组。
  - `check()`(Language.hx:66-78):语言目录不存在则把 `ClientPrefs.data.language` 重置为 `'English'`。
  - 移动端回退:APK assets 不能列目录,改用编译期资源清单 `Assets.list` 找 `assets/shared/language/.../*.lang`(Language.hx:50-64,154-177)。
- `source\general\backend\language\CustomLangGroup.hx`
  - `updateLang()`(CustomLangGroup.hx:24-38):**永远先载 English 组目录到 `defaultData`,再载当前语言目录到 `data`**。
  - `get()` 查询顺序:`data` → `defaultData`(English 兜底)→ 键名/(404)(CustomLangGroup.hx:14-22)。
- `Language.setupData`(Language.hx:80-145):把目录内所有 `.lang` 文件按行解析(`key => value`,`value` 取第一个 ` => ` 之后全部内容),逐行 `map.set(key, value)`;同一组多个文件按读入顺序后者覆盖前者。
- 路径基准 `Paths.getPath('language')`(Paths.hx:268-314):默认解析到 `assets/shared/language`(getSharedPath,Paths.hx:329-332),MODS_ALLOWED 且当前 mod 里存在同名文件/目录时优先返回 mod 路径(`modFolders`,Paths.hx:918-940)——即 mod 可覆盖/补充语言包。
- 语言下拉菜单的候选列表来自 `FileSystem.readDirectory(Paths.getPath('language'))` 的目录名,跳过 `JustSay`(options\groupData\LanguageGroup.hx:20-36)。

### 1.2 语言根目录与包文件(实测)

语言根:`assets\shared\language\`,共 5 个语言目录 + 1 个特殊目录:

- `English`(必选,是全部组的 fallback 基准)
- `Chinese`
- `Portuguese (Brazil)`
- `I Dont Like Haxe`(整活语言,键不全,靠 English 兜底)
- `JustSay`(特殊:目录下不是"语言组子目录"而是 `JustSay-Lang-*.txt`;不出现在语言下拉里,被 LanguageGroup.hx:26-27 显式跳过)

组目录结构示例(组名 = 语言目录下的第一级子目录名):

```
assets\shared\language\English\charting\charting.lang
assets\shared\language\English\character\character.lang
assets\shared\language\English\stage\stage.lang
assets\shared\language\English\editors\editors.lang
assets\shared\language\English\menuchar\menuchar.lang
assets\shared\language\English\week\week.lang
assets\shared\language\English\main\main.lang
assets\shared\language\English\options\*.lang        (Audio/General/… 多个文件共用一个组)
assets\shared\language\English\optionTips\*.lang     (同上)
assets\shared\language\English\controls\controls.lang
assets\shared\language\English\freeplay\freeplay.lang
…(Chinese / Portuguese (Brazil) / I Dont Like Haxe 下结构相同但组可能不全)
```

各组在哪些语言下存在(实测):
- `charting`:**English / Chinese / Portuguese (Brazil)**(无 `I Dont Like Haxe`;其 `charting.lang` 英文 16581B、中文 18339B)。
- `character`:**English / Chinese** 两个语言包。
- `editors`、`main`、`options`、`optionTips`、`freeplay`、`mainmenu`、`controls` 等:English/Chinese/Portuguese/IDLH 基本都有。
- `stage`、`menuchar`、`week`、`gameplay` 等:**English / Chinese** 等 2~3 语言。
- 缺语言包 = 缺键时统一由 English `defaultData` 兜底(CustomLangGroup.hx:29-38),所以新增键**至少补 English**,其它语言可选。

### 1.3 文件内格式(实测,`assets\shared\language\English\charting\charting.lang`)

```
charting => Charting

# ===== Menu titles =====
menu_charting => Charting
…
status_zoom => Zoom:
item_metronome => Metronome
desc_metronome => …(说明文字,悬停下显示)
```

- 分隔符为 ` => `(源码按 `line.indexOf(' => ')` 切,Language.hx:133-137)。
- 支持 `#` 注释与空行;键=值都 `trim`(CoolUtil.listFromString,CoolUtil.hx:55-64)。
- 文本文件建议 UTF-8(中文包正常显示;PowerShell 控制台直读中文会乱码属显示问题)。
- 另注意 `main\main.lang` 里有每语言配置键:`languageName`、`fontName`(中文为 `Lang-ZH`)、`justsayLang` 以及通用 UI 文案(play/back/optionsTitle/…/modInfoEmpty/modInfoEmptyDesc)。编辑器字体统一走 `Language.get('fontName','main')`(见 1.5)。

### 1.4 编谱器 / 角色编辑器 / 相关编辑器用到的组与键全清单

组→使用方:
- `charting` → ChartingState + ChartEditorMenuBar + ChartEditorStatusBar
- `character` → CharacterEditorState + CharacterEditorMenuBar + CharacterEditorStatusBar
- `stage` → StageEditorState + StageEditorMenuBar + StageEditorStatusBar
- `editors` → MasterEditorMenu(入口列表 + mod 目录提示)
- `menuchar` → MenuCharacterEditorState;`week` → WeekEditorState
- `main` → 全编辑器共用的 `fontName` + 通用文案
- 三个目标编辑器目前只碰 `main` 组(取字体)。

**`charting` 组全部键(依据 English/charting/charting.lang):**

```
菜单标题:  menu_charting menu_data menu_event menu_note menu_section menu_song menu_test menu_help
状态栏:    status_zoom status_section status_beat status_snap status_move status_move_on status_move_off
事件:      event_tag event_value1 event_value2
条目(item_): item_metronome item_autoscroll item_bpm item_offset item_waveform_inst/main/opp
            item_mute_inst/main/opp item_vortex item_ignore_warnings item_sfx_bf item_sfx_opp
            item_go_char item_go_sound item_go_loop item_go_end item_no_rgb item_note_skin item_note_splash
            item_apply_notes item_event_type item_value1 item_value2 item_add_event item_del_event
            item_prev_event item_next_event item_sustain_len item_strum_time item_note_type item_must_hit
            item_gf_section item_alt_anim item_beats_per_section item_change_bpm item_section_bpm
            item_copy_section item_paste_section item_clear_section item_swap_section item_do_copy_beat
            item_undo item_include_notes item_include_events item_duet_notes item_mirror_notes
            item_song_title item_has_voice item_save item_reload_audio item_reload_json item_engine
            item_load_autosave item_load_events item_save_events item_clear_events item_clear_notes
            item_speed item_mania item_opponent item_girlfriend item_player item_stage
            item_test_mode item_normal_mode
说明(desc_): desc_metronome desc_autoscroll desc_bpm desc_offset desc_waveform_* desc_mute_* desc_vortex
            desc_ignore_warnings desc_sfx_bf desc_sfx_opp desc_go_* desc_no_rgb desc_note_skin desc_note_splash
            desc_apply_notes desc_event_type desc_event_info desc_value1 desc_value2 desc_add_event desc_del_event
            desc_prev_event desc_next_event desc_sustain_len desc_strum_time desc_note_type desc_must_hit
            desc_gf_section desc_alt_anim desc_beats_per_section desc_change_bpm desc_section_bpm
            desc_copy_section desc_paste_section desc_clear_section desc_swap_section desc_copy_beat
            desc_do_copy_beat desc_undo desc_include_notes desc_include_events desc_duet_notes
            desc_mirror_notes desc_song_title desc_has_voice desc_save desc_reload_audio desc_reload_json
            desc_engine desc_load_autosave desc_load_events desc_save_events desc_clear_events desc_clear_notes
            desc_speed desc_mania desc_opponent desc_girlfriend desc_player desc_stage desc_test_mode desc_normal_mode
帮助(help): item_help_nav item_help_nav_ws/ad/lr item_help_note item_help_note_add/move/del/sus
            item_help_play item_help_play_test/norm/stop/zoom item_help_edit item_help_edit_undo/save/section
行标签(label_): label_bpm label_offset label_inst_vol label_voices_vol label_voices_opp_vol label_go_char/sound/loop/end
            label_note_skin label_note_splash label_event_type label_value1 label_value2 label_sustain_len
            label_strum_time label_note_type label_beats label_section_bpm label_copy_beat label_song_title
            label_song_bpm label_song_speed label_song_mania label_stage label_player1 label_gf label_player2
确认弹窗:  prompt_paste_section prompt_clear_section prompt_swap_section prompt_copy_beat prompt_duet_notes prompt_mirror_notes
```

**`character` 组全部键(依据 English/character/character.lang,162 行):**

```
菜单标题:  menu_char menu_anim menu_settings menu_ghost menu_file menu_help
状态栏:    status_character status_anim status_offset status_frame status_zoom
条目(item_): item_char_select item_image item_reload_image item_health_icon item_get_icon_color item_vocals
            item_anim_select item_anim_name item_anim_symbol item_anim_fps item_anim_loop item_anim_indices
            item_anim_add_update item_anim_remove item_playable item_flip_x item_no_aa item_scale
            item_sing_duration item_pos_x item_pos_y item_cam_x item_cam_y item_make_ghost
            item_highlight_ghost item_save item_load_template item_reload_char
            item_help_camera item_help_char item_help_other(重复项,菜单行用)
行标签(label_): label_char_select label_image label_health_icon label_vocals label_anim_select label_anim_name
            label_anim_symbol label_anim_fps label_anim_indices label_scale label_sing_duration label_pos_x
            label_pos_y label_cam_x label_cam_y label_ghost_alpha label_health_r/g/b
帮助标题:  help_camera help_char help_other
帮助行(menu+F1 屏): item_help_cam_zoom/cam_move/cam_reset item_help_char_ctrl_r/ctrl_c/ctrl_v/ctrl_z/anim/replay/offset/offset_keys/frame
            item_help_other_sil/shift/ctrl/help/exit
帮助行(mobile): item_help_m_cam_zoom/cam_reset/char_reset/char_anim/char_offset/other_sil/other_shift
提示:      tip_help_f1 tip_help_f
说明(desc_,52 条): desc_char_select desc_image desc_reload_image desc_health_icon desc_get_icon_color desc_vocals
            desc_anim_select desc_anim_name desc_anim_symbol desc_anim_fps desc_anim_loop desc_anim_indices
            desc_anim_add_update desc_anim_remove desc_playable desc_flip_x desc_no_aa desc_scale
            desc_sing_duration desc_healthbar_colors desc_pos_x desc_pos_y desc_cam_x desc_cam_y
            desc_make_ghost desc_highlight_ghost desc_ghost_alpha desc_save desc_load_template desc_reload_char
            desc_help_camera desc_help_cam_zoom desc_help_cam_move desc_help_cam_reset desc_help_char
            desc_help_char_anim desc_help_char_offset desc_help_char_offset_keys desc_help_char_replay
            desc_help_char_frame desc_help_other desc_help_other_sil desc_help_other_shift desc_help_other_ctrl
            desc_help_other_help desc_help_other_exit
```

> 注:实测 Chinese/character.lang 缺约 50 个 `desc_*` 和少量 `item_*`(对比脚本结果"EN only"长清单),运行时会自动用 English 兜底,不影响显示但说明翻译维护是"按需补齐"而非强制全量。

**`stage` 组键(节选全量,依据 English/stage/stage.lang,约 120 键)**:`menu_stage/menu_object/menu_camera/menu_view/menu_file/menu_help`;`status_stage/status_directory/status_object/status_pos/status_zoom`;`item_*`(stage_select、reload_stage、load_template、directory、hide_gf、default_zoom、cam_speed、obj_new_sprite/animated/square、obj_delete、obj_duplicate、obj_anim、obj_move_up/down、show_bf/dad/gf、low/high_quality、toggle_help、focus_bf/dad/gf、save);`label_*`/`desc_*` 与之一一对应(desc_obj_list_item 等);帮助 `help_camera/cam_zoom/cam_move/cam_reset/obj/obj_move/obj_sel/obj_scale/other/other_shift/other_help/other_exit` + 对应 `desc_help_*`。

**`editors` 组(MasterEditorMenu 用,English/editors/editors.lang,13 行)**:`chartEditor / characterEditor / stageEditor / weekEditor / menuCharEditor / dialogueEditor / dialoguePortraitEditor / noteSplashDebug` + `noModDirectory / loadedModDirectory`。中文包键一致(Chinese/editors/editors.lang)。

**`menuchar` 组(MenuCharacterEditorState)**:`menu_type/menu_char/menu_hint`;`type_opponent/type_boyfriend/type_girlfriend`;`cur_role`;`lbl_image/lbl_idle/lbl_confirm/lbl_scale`;`chk_flip_x/btn_reload/btn_load/btn_save`;`h_arrow/h_space1/h_space2/h_esc`。

**`main` 组(全局字体/通用文案)**:`languageName fontName justsayLang play back optionsTitle optionsMenuTitle rebinding holdBCancel holdCDelete holdEscCancel holdBackspaceDelete modInfoEmpty modInfoEmptyDesc`。Mod 信息下拉面板文案即来自此组(ModInfoPopup.hx:207,214)。

### 1.5 编辑器取字体/取文案的规范写法(可照抄)

```haxe
Paths.font(Language.get('fontName', 'main') + '.ttf')   // 字体:随语言切换
Language.get('menu_' + m.key, 'charting')               // 顶栏按钮标题
Language.get('item_' + it.labelKey, 'charting')         // 下拉行文本
Language.get('label_' + key, 'character')               // LabelWidget 左标签
Language.get('desc_' + key, 'charting')                 // 底部描述条(hover 说明)
Language.get('status_zoom', 'charting') + ' ' + zoomStr // 状态栏字段
```
例:ChartEditorMenuBar.hx:436-462(translateItemKey/translateLabelKey 的 `w_`/`item_`/`label_` 前缀回退逻辑)、:518、:1567-1597;ChartEditorStatusBar.hx:79-88;CharacterEditorStatusBar.hx:75-81;StageEditorStatusBar.hx:75-79;MasterEditorMenu.hx:47。

---

## 2. 给新编辑器加键:改哪些文件、什么结构、缓存/重启问题

### 2.1 要改/建的文件

按"一个组一个目录、一组文件"的约定,推荐为三个新编辑器新建独立语言组,例如:

```
assets\shared\language\English\dialogue\dialogue.lang      # 对话编辑器 + 对话立绘编辑器(或拆成两组)
assets\shared\language\Chinese\dialogue\dialogue.lang
assets\shared\language\English\noteSplash\noteSplash.lang   # 音符溅射编辑器
assets\shared\language\Chinese\noteSplash\noteSplash.lang
```

规则:
1. **组目录必须建在** `assets\shared\language\<Language>\<组名>\` 下;组名会被 `discoverGroups()` 自动发现(Language.hx:34-64)。
2. 文件后缀 `.lang`;文件名任意(同组可多文件,如 `options` 组有 Audio/General 多个 `.lang`,合并进同一 Map)。
3. 行格式 `key => value`;键名习惯带语义前缀:`menu_*`(顶栏)、`status_*`(状态栏)、`item_*`/`label_*`(行文本/左标签)、`desc_*`(悬停说明)、`help_*`/`tip_*`、`prompt_*`(确认框)。与既有三个编辑器保持一致,新菜单栏组件才能直接复用 `translateItemKey`/`translateLabelKey` 的 `item_`/`label_`/`desc_` 拼键约定(ChartEditorMenuBar.hx:436-462)。
4. **English 必补**(它是全语言 fallback 的 defaultData 源);Chinese/Portuguese/IDLH 缺键自动回落英文(CustomLangGroup.hx:29-38),但仍建议补齐中文。
5. 若只写运行时下拉/状态栏文本(不经菜单栏),代码里直接 `Language.get(key, 'dialogue')` 即可;注意 `Language.get` 默认组是 `'options'`,调用时**必须显式传组名**。

### 2.2 加载时机 / 缓存 / 是否需要重启

- 组 Map 是 `static` 缓存(Language.hx:13);`groups` 只增不清。
- 文本在 `Language.resetData()` 时**全量重读**(先清 `data`/`defaultData` 再重读两个目录,CustomLangGroup.hx:24-38)。
- `resetData()` 调用点:
  - 启动:`InitState.hx:150`;
  - 选项里切语言:`LanguageGroup.hx:38-43`(onChangeLanguage → `Language.resetData()` + `OptionsState.changeLanguage()`);
  - 各编辑器进入时主动刷一次:ChartingState.hx:234、StageEditorState.hx:187、CharacterEditorState.hx:121、WeekEditorState.hx:54、MenuCharacterEditorState.hx:179。
- **桌面开发(loose 文件)**:改了 `.lang` 不需要重启程序——重新进入编辑器(create 里 resetData)或切一次语言选项即生效。但**顶栏 tab 标题等"建好即缓存"的文本**不会自动刷新,需要重新进状态或调用菜单栏的 `applyLang()`(ChartEditorMenuBar.hx:465-540 会重建全部 tab 文本并刷新状态栏)。
- **打包平台(APK/HTML5)**:`.lang` 编译进 assets,`Assets.getText` 读取;改包内文本必须重新构建;已运行会话里新增组(目录)不会被发现(资源清单缓存 Language.hx:154-177),须重启。
- fallback 链(无缓存歧义):当前语言 `data` → English `defaultData` → 开发者模式 `value + ' (404)'` / 否则原键(Language.hx:18-24;CustomLangGroup.hx:14-22)。
- 语言候选列表:来自目录枚举,新语言 = 新目录(JustSay 除外)。

---

## 3. WindowControlBar / WindowBarMode / EditorChromeUI / WindowChromeManager 机制

### 3.1 角色划分

| 文件 | 角色 |
|---|---|
| `source\general\objects\WindowBarMode.hx` | 枚举:`CONSTANT=0`(编辑器常驻,融入顶栏右侧) / `AUTO_HIDE=1`(普通界面,鼠标贴近顶边滑入)(WindowBarMode.hx:6-12) |
| `source\general\objects\WindowControlBar.hx` | 自绘窗口控制条本体(FlxSpriteGroup,38 行起):- □ × 按钮、悬停高亮、拖窗、双击最大化、点击标题回调 `onTitleClick`(93 行);`BAR_HEIGHT=36 / BTN_W=46`(40-41);由 `FlxG.signals.postUpdate` 全局驱动(134 行、149-160 行);`refreshAllBars()` 静态重排(167-181);CONSTANT 布局标题右对齐到按钮左侧(363-402);单击标题触发 `onTitleClick` 在 756-766 行;destroy 自动摘除(862-870) |
| `source\developer\editors\EditorChromeUI.hx` | 编辑器专用壳:`class EditorChromeUI extends WindowControlBar`,构造即 `CONSTANT` 模式(15-20 行),无其它逻辑 |
| `source\general\backend\device\WindowChromeManager.hx` | 全局调度:按状态切系统标题栏显隐 + 决定是否自动挂 AUTO_HIDE 条 |

### 3.2 系统标题栏怎么隐藏/恢复

- 入口:`MusicBeatState.create()` 里调用 `WindowChromeManager.onStateChanged(this)`(MusicBeatState.hx:198-202,`#if (cpp && windows)`),仅 MusicBeatState 子类调用;WindowChromeManager 另外用 flixel 信号覆盖所有状态:
  - `FlxG.signals.preStateCreate` → `onPreStateCreate`(状态 create **前**切好 chrome,保证 UI 按扩展后的逻辑尺寸布局;WindowChromeManager.hx:138-144、283);
  - `FlxG.signals.postStateSwitch` → `onPostStateSwitch`(create 后挂 AUTO_HIDE 条;147-171、286);
  - `win.onResize/onFullscreen` → `reassert()`(275-280)。
- 判定逻辑:`applyChromeForState`(186-203):
  - `immersive = !isStateIn(state, keepChromeScreens)`;`keepChromeScreens` 默认空数组(31-32)= **所有界面都沉浸、系统标题栏全隐藏**。
  - 非沉浸 → `setSystemChrome(true)` 恢复系统栏;沉浸 → `setSystemChrome(false)` 隐藏。
- `setSystemChrome(show)`(206-238)→ `Native.setWindowChromeVisible(show)`;隐藏时记录标题栏高、重置客户区到默认矩形(`windowSetClientSize`/`captureDefaultWindowRect`,228-232),再 remeasure。
- 原生层:`Native.hx` 的 `setWindowChromeVisible`(1248-1262)调 C++ `setWindowChromeNative`,并同步 `win.borderless = !show` 防 SDL 全屏样式打架;另有 `titleBarHeightPx`(886 行附近)、`windowSetClientSize`(1225-1230)、`captureDefaultWindowRect`(1209-1214)、`windowRestoreDefault`(1217-1222)。
- 编辑器专属名单:`WindowChromeManager.editorScreens = [ChartingState, CharacterEditorState, StageEditorState]`(35-37)。命中名单的状态:**不自动挂 AUTO_HIDE 条**(154-155),由编辑器自己 `new EditorChromeUI()` 挂 CONSTANT 条(即顶栏里那组 - □ ×)。

### 3.3 编辑器里如何挂(三个现役编辑器的标准三段式)

以 CharacterEditorState 为例(CharacterEditorState.hx:209-222,StageEditorState.hx:375-388 相同):

```haxe
#if (cpp && windows)
windowChrome = new EditorChromeUI();
windowChrome.scrollFactor.set();
windowChrome.cameras = [camHUD];     // ★ 必须与 UI 同相机,否则点击/层级乱
add(windowChrome);
modInfoPopup = new general.objects.ModInfoPopup();
modInfoPopup.scrollFactor.set();
modInfoPopup.cameras = [camHUD];
add(modInfoPopup);
windowChrome.onTitleClick = () -> modInfoPopup.openUnder(windowChrome);
#end
```

- ChartingState 不同点:它的主相机随网格滚动,所以 `camHUD` 与窗口条都放 `super.create()` **之后**创建(MusicBeatState.create 里 `initPsychCamera()` 会 `FlxG.cameras.reset`,ChartingState.hx:551-570 注释)。
- `onTitleClick` 类型:`Void->Void`(WindowControlBar.hx:93),单击标题(未拖动)后约 0.3s 判定触发(WindowControlBar.hx:756-766)。
- `ModInfoPopup.openUnder(bar:WindowControlBar)`(ModInfoPopup.hx:99 起):面板宽取 `bar.titleBlockWidth() + 20`、左缘对齐 `bar.titleAnchorX()`(ModInfoPopup.hx:111、117;辅助函数 WindowControlBar.hx:96-108),即"标题块正下方下拉"。
- 注意 EditorChromeUI / ModInfoPopup 的声明在 CharacterEditorState.hx:64-67、StageEditorState.hx:150-151、ChartingState.hx:200-201 都是 `#if (cpp && windows)` 包着的字段。

### 3.4 对三个新编辑器意味着什么

- 它们继承 MusicBeatState → 进状态时系统标题栏会被隐藏(immersive),且因不在 `editorScreens` 里,`postStateSwitch` 会给它们自动挂一条 **AUTO_HIDE** 条(平时藏、靠近顶边滑出)。
- 接"自绘顶栏菜单"时:应把 `DialogueEditorState / DialogueCharacterEditorState / NoteSplashEditorState` 加进 `WindowChromeManager.editorScreens`(WindowChromeManager.hx:35-37),并在各自 create 里按 3.3 的三段式自挂 `EditorChromeUI` + `ModInfoPopup`,否则会出现两条窗口条并存。
- WindowControlBar 全在 `#if (cpp && windows)` 下工作;`tickers` 全局数组 + destroy 摘除,编辑器切走自动清理(WindowControlBar.hx:51-52、862-870),不会泄漏。

---

## 4. 现役三个编辑器的 F1/帮助实现对比

| 编辑器 | 帮助入口 | 实现 | 内容是否走 Language |
|---|---|---|---|
| **ChartingState** | **F1~F8 各开一个一级菜单**(F1=0 谱面 … F8=7 帮助)(ChartingState.hx:2446-2455);帮助是**最后一个一级菜单**的下拉面板 | 下拉 = "行列表";帮助行是 `item_text`/`item_label_widget` 只读行;hover 行在底部描述条显示 `desc_help_*`;行点击不会关菜单(`menus[activeMenu].key != 'help'` 才 close,ChartEditorMenuBar.hx:586-592) | **是**:menu_*/item_help_*/desc_help_* 全部 charting.lang |
| **CharacterEditorState** | **F1(或虚拟键 F)直接打开 help 菜单**(CharacterEditorState.hx:1403-1411):遍历 `menuBar.menus` 找 `key=='help'` 得 helpIdx → `menuBar.openMenu(helpIdx)` | 同上,下拉即帮助屏;帮助行来自 character.lang(菜单行文字/移动端帮助行/desc 都有) | **是**:item_help_*(桌面/移动两组)+ desc_help_* |
| **StageEditorState** | 双入口:(a) F1~F6 开一级菜单(F6=help)(StageEditorState.hx:3080-3086);(b) **F7 全屏帮助浮层**(桌面 F7,移动端虚拟键 F 映射 F7)(3121-3136) | (a) help 下拉行文本取 stage.lang(StageEditorMenuBar.hx:299-316);(b) 浮层 `helpBg/helpTexts`,内容是**硬编码英文字符串数组**(StageEditorState.hx:1647-1673),按 `controls.mobileC` 选桌面/移动版文案——**未语言化**,是已知的不一致点 | 下拉:是;F7 浮层:否(硬编码) |

小结:CharacterEditor / ChartEditor 的"F1 帮助"不是独立弹层/SubState,而是**复用顶栏下拉菜单的 help 菜单 + 描述条**,内容全部是语言键;Stage 额外保留了一个 F7 硬编码浮层。NoteSplash 编辑器则是旧式 `MusicBeatSubstate` 帮助(见第 7 节)。

---

## 5. MasterEditorMenu 入口现状

`source\developer\editors\MasterEditorMenu.hx`(MusicBeatState):
- 选项数组 `options`(12-21 行)含 8 项:`chartEditor / characterEditor / stageEditor / weekEditor / menuCharEditor / dialogueEditor / dialoguePortraitEditor / noteSplashDebug`;**三个目标编辑器都已有入口**。
- 显示文本 `Language.get(options[i], 'editors')`(47 行)→ editors.lang 的 `dialogueEditor=对话编辑器 / dialoguePortraitEditor=对话立绘编辑器 / noteSplashDebug=音符溅射调试`。
- ACCEPT 分发(114-137):`dialogueEditor→new DialogueEditorState()`、`dialoguePortraitEditor→new DialogueCharacterEditorState()`、`noteSplashDebug→new NoteSplashEditorState()`(128-133)。
- 底部 mod 目录条(54-74、169-191)用 `noModDirectory / loadedModDirectory`;`addVirtualPad(LEFT_FULL, A_B)`(MODS_ALLOWED)/`UP_DOWN, A_B`(80-83)。
- 主菜单进入点:MainMenuState.hx:477(`MusicBeatState.switchState(new MasterEditorMenu())`,对应"Editors/按 7")。

---

## 6. 移动端注意点(virtualPad / EditorMobileKeys / 菜单栏)

### 6.1 基础:addVirtualPad 与键盘双分支

- `MusicBeatState.addVirtualPad(DPad, Action)`(MusicBeatState.hx:44-57):建 FlxVirtualPad;桌面且 `needMobileControl=false` 时 pad 全透明且 `active=false`(49-55)——所以桌面也能安全引用 `virtualPad.buttonX`(值为 false,不误触);随后调 `EditorMobileKeys.onVirtualPadAdded(this)`(56)。
- 自定义 pad 模式定义在 `source\mobile\flixel\FlxVirtualPad.hx`(buttonA/B/C/D/F/G/S/V/X/Y/Z + 方向键双组,26-44 行;模式常量 `CHARACTER_EDITOR/DIALOGUE_PORTRAIT/NOTE_SPLASH_DEBUG/ChartingStateC/A_B_X_Y…` 的布局在 60-280 行)。
- 各编辑器 update 里 pad 与键盘等价判定,例:
  - CharacterEditorState:`buttonS=F12 剪影`、`buttonF=F1 帮助`、`buttonB=ESC 退出`(1400-1423);`buttonA=粘贴 offset`(1238-1244);`buttonV/D=上一/下一动画`(1122-1124);`buttonC=SHIFT 加速`(1083-1087);`buttonZ=R 重置缩放`(1101);组合键 `buttonX/Y=Q/E 缩放`、`buttonG + 方向键=平移相机`(1092-1114,注意相机部分包了 `#if mobile`)。
  - ChartingState:pad 键(ChingStateC 模式)`buttonE/Q=尾长±`、`buttonX=SPACE 播放`、`buttonZ/D=缩放`、`buttonV=Ctrl+Z 撤销`、`buttonA=ENTER 整曲播`、`buttonB=BACKSPACE 退出`、`buttonC=ESC 试玩`(ChartingState.hx:2550-2630),`buttonG=TAB 打开/聚焦顶部菜单`(2606-2628)。
  - StageEditorState:`buttonF=F7 帮助`、`buttonS=F12 选区框`、`buttonC=加速`、`G+方向=平移相机`(3121-3163)。

### 6.2 "调整移动端各 Editor 键位"(EditorMobileKeys)会接管 pad

- 开关 `adjustMobileEditorKeys`(ClientPrefs.hx:185;维护设置 MaintenanceGroup.hx:38-40),开启后:
  - 默认 virtualPad 被隐藏(`pad.visible=false; pad.active=false`,EditorMobileKeys.hx:287-298);
  - 换成 `EditorMobileKeyOverlay`(自绘按键,EditorMobileKeys.hx:300-320),触摸/鼠标按下 = **向 FlxG.keys 注入该键绑定的组合键**(EditorMobileKeyOverlay.hx:27 注释;按键定义文件 `FuckYouNFEMobile/<EditorId>NewFuckingButtonMobile.json`,回退链:用户文件 → APK 内置 → 默认模板,EditorMobileKeys.hx:122-153);
  - `Controls.mobileC` 在开启期间强制返回 false(Controls.hx:187-199)→ 编辑器一律走"键盘分支",自定义组合键即可驱动全部编辑操作。
- 语义表(每编辑器每个 pad 按钮 ↔ 等价键/组合/中文含义):`EditorMobileKeyData.hx:43-178`。**三个目标编辑器已登记**:`DialogueEditor / DialogueCharacterEditor / NoteSplashEditor` 均有 EDITORS 条目与语义表(71-97 行 S_DIALOGUE、S_DIALOGUE_CHAR;109-122 行 S_NOTE_SPLASH;181-191 行 EDITORS),也即移动端键位体系已为它们预留。
- MusicBeatState.update 每帧调 `EditorMobileKeys.frameUpdate(this)`(MusicBeatState.hx:242)做启停/挂 overlay。

### 6.3 菜单栏与 pad 的交互/冲突处理(现状 = 没有菜单专用 pad 导航)

- 三个现役自绘菜单栏(`ChartEditorMenuBar / CharacterEditorMenuBar / StageEditorMenuBar`)的行/下拉**只响应鼠标 hover + 点击**(内部大量 `FlxG.mouse` 判定,如 ChartEditorMenuBar.hx:599-650、openMenu 1448 起);菜单栏代码里**没有**针对 virtualPad 的导航(全文件搜不到 `virtualPad`/`controls.`/`UI_UP` 之类)。
- 冲突处理是"状态层"做的:
  - 菜单开着时,多数全局快捷键暂停:`if (!menuOpen)` 才处理 F1~F8 之外的编辑快捷键(ChartingState.hx:2446-2456);CharacterEditorState 动画列表交互让位(`var menuOpen… !menuOpen && inAnimList`,1306-1396);
  - 下拉开着时 TAB 被吞、交还给下拉内控件(`if (menuBar.activeMenu >= 0){ /* 让 TAB 给 widget */ }`,ChartingState.hx:2606-2612);滚轮不再滚谱面时间(`!controls.mobileC && !(menuBar.activeMenu>=0)`,2657-2660);
  - **StageEditorState 有最具体的"浮层 vs pad"处理**:F7 帮助浮层开时,移动端把除 F 外所有 pad 按钮隐藏(`virtualPad.forEachAlive … tag!='F' → visible=false`,3122-3131),ESC 优先关浮层而非退出(3061-3068);且 Stage 的 menuBar 因 update 有提前 return 路径,被置 `active=false` 后由状态**手动驱动**:`menuBar.update(elapsed)`(StageEditorState.hx:357-360、3036-3041)。
- 结论:新编辑器菜单栏若要做到移动端可用,现状只能靠"pad/EMK 注入键盘 + 菜单鼠标点击"的组合——下拉本身无键盘导航,建议新菜单组件自带上/下/回车/ESC 导航(可供键注入驱动),并沿用 Stage 的"浮层打开时隐藏无关 pad 键"策略。

---

## 7. 三个目标编辑器"可迁移到菜单栏"的功能点清单(按当前源码)

> 三者现状:都是 `MusicBeatState` + 右侧 PsychUIBox 原生控件 + 硬编码英文文案;只通过 `Language.get('fontName','main')` 取字体。ESCAPE 返回 MasterEditorMenu 前有未保存确认(ConfirmationPopupSubstate;对话两编辑器用,NoteSplash 直接切)。

### 7.1 DialogueEditorState(对话行编辑器,source\developer\editors\DialogueEditorState.hx,524 行)

PsychUIBox "Dialogue Line"(88-145):`characterInputText`(角色 json 名)、`lineInputText`(正文,Shift+Enter 换行)、`angryCheckbox`(气泡 type normal/angry)、`speedStepper`(打字速度)、`soundInputText`(音效文件)、按钮 Load Dialogue / Save Dialogue(127-132)。
顶部提示三行文本(66-79):操作提示(addLineText)、行号/动画信息(selectedText、animText)——全部硬编码。
可入菜单的字段/动作:
- **File 菜单**:Load Dialogue JSON、Save Dialogue JSON(系统文件对话框,415-523)、Exit(带确认);
- **Line 菜单(当前行字段)**:Character、Text、Speed、Box State(angry)、Sound;
- **Action/行导航**:Add Line After Current(P)、Delete Current(O)、Prev/Next Line(A/D,changeText 362-403)、重播文字(Space)、切换表情动画(W/S);
- **View 字段(只读信息条)**:当前行 n/m、当前动画名 x/y。
对应键盘:W/S=动画、A/D=行、P=增、O=删、Space=重播、ESC=退出(update 307-357)。

### 7.2 DialogueCharacterEditorState(对话立绘偏移编辑器,748 行)

两个 PsychUIBox(141-158):
- 左 "Character Type" 盒:radio Left/Center/Right(`dialogue_pos`);
- 主盒 tab:"Animations"(187-286):动画下拉、name/loop_name/idle_name 输入、Add/Update、Remove;"Character"(302-340):image 文件名、位置 X/Y stepper、Scale、No AA 勾选、Reload Image / Load Character / Save Character 按钮。
HUD 状态文本(20-34、100-124):tipText(两套硬编码操作提示 TIP_TEXT_MAIN/OFFSET 按 tab 切换)、offsetLoopText/offsetIdleText、animText。
键盘(update 439-616):J/K/L/I(+Shift)平移、Q/E 缩放、R 复位、H(Character tab:显隐气泡 HUD;Animations tab:循环切换 Loop/Idle 幽灵显隐)、Animations tab:WASD 调 loop 偏移 + 方向键调 idle 偏移(Shift ×10)、Character tab:W/S 滚动画、Space 重播、ESC 退出(带确认)。
可入菜单:File(Save/Load/Reload Image/Exit)、Type(Left/Center/Right radio)、Character 字段(Image/Pos X/Y/Scale/No AA)、Animations 字段与 Add/Update/Remove、View(toggle 气泡/幽灵、缩放提示)。

### 7.3 NoteSplashEditorState(音符溅射调试器,989 行)

三个 PsychUIBox(53-72):
- "Animation"(129-272):动画名、前缀、NoteData、可选 Indices、Min/Max FPS、动画下拉、Add/Update、Remove;点击轨道=溅射预览(599-625);
- "Properties"(323-385):Image、Reload Image、Scale、Allow RGB? / Allow Pixel?、Save、Template、Convert TXT;
- "Shader"(395-488):RGB 三组 stepper + "Replacing Color / Do not replace" 下拉(Red/Green/Blue)。
屏幕文本(74-118):tipText("Press F1 for Help")、errorText、curText(底部 Copied Offsets / Current Animation / offsets)。
键盘(update 498-631):方向键微调当前动画 offset(长按连发,Shift/肩键 ×10)、Ctrl+C/V/R 复制/粘贴/重置偏移、Space=重播溅射、F1=帮助 SubState、Back/ESC=退出。
**F1 帮助是独立 `MusicBeatSubstate`**:`NoteSplashEditorHelpSubState`(933-989),硬编码英文行,非 Language 键——这是可迁移成"help 菜单"的现成对象。
可入菜单:File(Save json / Convert TXT→json / Reload Image / Template / Exit)、Animation 字段与增删改、Properties(scale/allowRGB/allowPixel)、Shader 配置、Offset 快捷(复制/粘贴/重置)、Help(F1 内容)。

---

## 8. 附:接入新菜单栏的落地清单(基于以上调查)

1. 语言:新建 `English/Chinese` 下 `dialogue`、`noteSplash` 组(或并入既有组),按 2.1 命名 `menu_/status_/item_/label_/desc_/help_`;至少 English 全量。
2. 桌面 chrome:把三个状态类加进 `WindowChromeManager.editorScreens`(WindowChromeManager.hx:35-37);每个 create 末尾(或按 Charting 模式在 `super.create()` 后)自建 `camHUD` + `EditorChromeUI` + `ModInfoPopup`,`onTitleClick = () -> modInfoPopup.openUnder(windowChrome)`,全部 `#if (cpp && windows)`。
3. 参考布局常量:`BAR_HEIGHT=36 / STATUS_HEIGHT=25 / MENU_W=88`(ChartEditorMenuBar.hx:80-83);颜色规范(0xFF12141A 页面底 / 0xFF1C1F28 卡片 / 0x147C7FFF hover / 主渐变 0xFF4F46E5→0xFF7C3AED)同一文件 33-77 行。
4. 复用路径:三个现役 MenuBar 均为独立复制品(无公共基类,typedef 各自定义:ChartEditorMenuBar.hx:2369-2393、CharacterEditorMenuBar.hx:2352-2375、StageEditorMenuBar.hx:2418-2442),新编辑器可考虑抽一个公共菜单栏组件再实例化三份。
5. 移动端:状态里照旧读 `virtualPad.buttonX`(桌面 inactive 恒 false 无害)或依赖 EMK overlay 注入键盘;新菜单栏建议内置键盘/方向键导航并处理"下拉开时吞 TAB/滚轮/全局快捷键"与 Stage 式浮层隐藏 pad。
