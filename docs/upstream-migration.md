# CNE / Origin 上游迁移

本次合并使用提供的 ZIP 快照，不更换 NF 的应用入口和 SDL2 底层依赖。

| 侧 | 源码目录 | 上游快照 |
| --- | --- | --- |
| NF | `source` | 保留现有实现 |
| CNE | `source-codename` | `2289c833aa4d9a6a7f9f98a49fe994101ab75c16` |
| Origin | `source-originFunkin` | `92b437886e1ef1b5c7a0fa184be92a66b14e2cd3` |
| Origin assets | 用户外置 | `0b28106619ecf017af57c54dfde8653350b66128` |

合并以此前记录的 CNE `2456a91a41ae40245d0042c271ebddf38f012f9c` 和 Origin `b2215482c25c5e98a72ac47b4807018934480d01` 为基线，保留本项目对命名空间、入口、存档、移动控制和资源优先级的修改。上游独立入口不覆盖 NF 的 `Main`。

Origin 的原始版权及许可文本保存在 `source-originFunkin/LICENSE.md`，CNE 的原始许可文本保存在 `source-codename/LICENSE`，均逐字节取自对应 ZIP。Origin 文本的 Git blob 为 `c4d5ba1e332f441d53d5d0e91d623d64ee6e139b`，与该提交的 Git 树一致。两侧 README 说明本地适配范围；外置游戏资源沿用各自的来源及许可信息。

### 导入范围审查

2026-10-31 直接核对用户提供 ZIP 的提交注释及 `source/` 文件，补齐两个 CNE 事件后重新核对的结果保存在本机 `_build/upstream-import-audit-104.json`（此前基线为92）。后续 `_build/upstream-import-audit-208.json` 将 CNE 的 `hscript/Config.hx` 按实际类路径修正为 `source-codename/hscript/Config.hx`：文件已存在且有本地适配，不再计为缺失。下表只表示文件路径和内容比较，不能据此认定语义相同或运行验收完成。Origin 的两个 HaxeUI 基类按实际 `editor-compat` 类路径核对，CNE 的 `external/` 按保留的顶层包核对。

| 侧 | 快照源码文件 | 字节相同 | 仅换行差异 | 对应路径有本地修改 | 未找到对应仓库路径 |
| --- | ---: | ---: | ---: | ---: | ---: |
| Origin | 671 | 472 | 22 | 170 | 7 |
| CNE | 375 | 6 | 0 | 351 | 18 |

Origin 未对应的路径包括独立 `Main`、上下游构建脚本、由当前 Haxe 工具链提供的 Tracy 接口，以及 Apple 键盘桥和移动控制菜单；后两类仍需结合平台适配核对，Windows 构建不证明其完整迁移。CNE 的剩余项包括共享标准库覆盖文件、旧 shader 备份，以及尚未导入的控制台/inspector、ImGui 工具、`UIImageList` 和 `FolderOption`。后续审查需区分本项目有意保留的共用实现和实际遗漏，再分别补齐及验收。

`BopZoomEvent` 已接入实际节拍更新和公开的 `PlayState.doBopZoom()`，派发 `onBopZoom` / `onPostBopZoom`。构建103的 `cne-bop-zoom` 运行检查通过，进程20056退出0：真实 CNE HScript 使用上游导入路径，验证默认缩放、参数覆盖、取消及后回调、缓存事件复用、游戏/HUD 独立缩放与上限。该检查不加载歌曲，不能代替完整 CNE 曲目验收。

`PauseGameEvent` 已接入；`pauseGame()` 向暂停子状态传递脚本修改的 `excludeList` 和 `allowGitaroo`。暂停资源管理器新增第三个可选参数，保留原有的两个恢复控制参数、触屏和菜单行为；排除列表只保留原本已注册的 tween/timer，替换恢复时不复活暂停期间已结束的对象。构建106的 `cne-pause` 检查通过，进程15904退出0：真实 HScript 覆盖取消、强制彩蛋概率下的允许/禁止、缓存重置与子状态参数；实际 Flixel 计时器、补间、镜头和静音 PCM 音频覆盖排除、暂停、恢复及旧有销毁参数。检查使用独立资源列表和暂停入口探针，不加载歌曲或实际创建暂停菜单，也不构成键盘暂停操作验收。

最新模组缓存修复后的构建再次运行了上述两项 CNE 专项检查：`cne-bop-zoom-current-193.log` 和 `cne-pause-current-193.log` 均有完整通过标记且进程退出码为0，三个原有存档的字节未变。测试范围仍限于上述脚本和探针，不扩大为完整歌曲或全部 CNE 模组验收。

### 已安装 CNE 模组的静态检查

当前外置目录可见 `3d`、`irida-modpack-main`、`MCM`、`VMU` 和 `Vs Ross`。使用项目的 HScript 解析器、当前构建选项的近似预处理值，对这五个目录下291个 `.hx` 文件做只读语法解析；未启动模组、解析导入或执行脚本。原始检查有3个失败；加入无类型 `catch` 兼容处理后，`_build/cne-installed-syntax-audit-210.json` 中289个文件可解析、2个仍失败，且记录了每个文件的 SHA256。可解析不等于模组运行兼容。

剩余两处均在 Vs Ross：`data/states/ross/scrapped/FirstTimeState.hx` 存在未闭合的预处理块，`data/states/ross/substates/BuildWarningSubState.hx` 的 `applyMarkup` 调用缺少第一个参数。没有修改用户模组，也未假设这两个文件一定会在当前路径被加载。`songs/Nuts N Bolts/scripts/events.hx` 使用 `catch (e)`，引擎当前的兼容处理将这种未标类型的捕获按 `Dynamic` 解析；这是本项目的语法扩展。Windows 原生检查 `_build/batch-213-cne-legacy-syntax.log` 已通过实际 HScript 解析该模组脚本，并执行独立的无类型捕获测试；没有执行该模组脚本或验证整首歌曲。完整构建和批量检查结果见 `_build/cne-syntax-batch-lime-212.exit` 和 `_build/batch-213-results.json`。

Vs Ross 的 `data/states/ross/backend/CrashHandler.hx` 导入旧路径 `funkin.menus.ui.Alphabet.AlphabetAlignment`。为该枚举提供脚本运行时包装后，`_build/batch-217-cne-legacy-syntax.log` 已从该模组文件读取实际导入行，并在原生 HScript 中验证 `LEFT`、`CENTER`、`RIGHT` 和 `fromString`；这没有执行整个错误处理脚本。增量构建及相关批量检查结果见 `_build/cne-alignment-lime-216.exit`、`_build/batch-217-results.json`。导入静态清单 `_build/cne-mod-import-audit-refined-215.json` 仅为线索，其中 `IntervalShake` 与 `FlxSoundFilterType` 导入位于 `ROSS_BUILD` 条件内，未验证启用该构建选项的行为。

只读资源核对 `_build/cne-literal-assets-audit-218.json` 扫描已安装 CNE 脚本中的静态字面量引用：483 处中，482 处能在对应模组或 CNE 基础资源中找到，1 处是待确认候选。VMU 的 `songs/Welcome/scripts/Normal.hx:93` 在 `postCreate` 中引用 `images/game/mickeyText.png`，当前模组、CNE 基础目录和已安装 CNE 目录中未发现同名图片或图集描述文件；脚本自身在存在 variation 时会提前禁用。此检查不覆盖动态路径、条件分支、额外资源库或自定义扩展名，尚未运行该歌曲，不能断言所有路径均可用或该缺失必然触发崩溃。没有修改该模组的文件。

### 已安装 CNE 模组的隔离运行检查

调试入口 `--cne-isolated-storage` 要求可执行文件旁存在专用标记和预建的嵌套存档目录；其 FlxSave 写入重定向至测试副本。由于 Flixel 会从 Lime 存储路径向上回退，验证时额外核对了副本存档实际位置、目录外的哨兵文件以及原用户 CNE/Vs Ross 存档的 SHA256。测试使用资源及模组副本，并排除了视频文件；这不覆盖视频相关路径，也不代表完整通关。原模组 291 个 `.hx` 文件的哈希与静态检查前一致。

- `3d` 和 `MCM` 进入各自加载后的标题画面；VMU 进入内容提示画面，提示后的流程尚未验证。Irida 的原始副本显示内容提示后，自动键盘确认没有产生可见响应；为检查后续画面，仅在副本的三个状态脚本中临时增加鼠标确认，实际进入多页模组演示说明。期间检测到外部输入，后续状态未验收；结束后依照 `_build/cne-irida-input-adapter-225/manifest.json` 的哈希恢复副本。该对照不算键盘或完整启动通过。日志位于 `_build/cne-isolated-runtime-219/mod-*-v220.log` 和 `mod-irida-modpack-main-v225.log`。
- MCM 的原 `global.hx:34` 通过实例访问静态字段曾导致脚本错误并阻止自定义标题加载；启用解释器已有的静态字段回退后，`mod-MCM-v224.log` 中该错误消失，实际显示了 MCM 自定义标题。日志中 `darkma.mp4` 预载报错来自测试副本有意排除视频，不能用于判断真实资源是否缺失。
- Vs Ross 的 Cake Race 使用原始脚本进入自由游玩、歌曲画面和死亡画面（`mod-Vs_Ross-v224.log`）。其 `NoteDataHandler.hx` 与 `GeneralGameplay.hx` 分别向状态 `add()` 传入数组和非 `FlxBasic` 脚本对象；此前两处触发原生异常并导致黑屏。CNE 游玩状态的脚本入口现在拒绝这些非法参数并记录警告，合法的 `FlxBasic` 对象仍按原方式添加。对照测试仅临时修改副本并随后以哈希保护恢复，最终验证使用未改动的模组脚本。
- Vs Ross 的 `songs/Middlescroll .hx:36` 仍报告 `ratingNumGroup` 不存在；该脚本还引用当前 CNE 未提供的评分对象，相关界面定位尚未验证。旧音符图集 `BFBirdNote.xml` 等包含静止和命中帧，但没有四个方向的 `pressed` 帧；此前对应按键动画缺失。现在仅在按下帧不存在且静止帧有效时，以同方向静止帧创建 `pressed`，保留按下/松开状态；已有按下帧仍使用原帧。`_build/batch-227-cne-legacy-syntax.log` 在原生运行时读取实际旧图集和基础 `default` 图集，对四方向的帧选择及按下/松开状态逐项通过；本次未重新进入完整歌曲。不能将进入歌曲或死亡画面视作整首歌曲、结算和退出流程通过。

上述引擎改动的 Windows 增量构建 `_build/cne-safe-add-build-224.exit` 为 0，脚本、图片/音频/图集热重载与 CNE 行为共六项检查见 `_build/batch-224-results.json`。有效对象加入和非法对象拒绝有单独的原生检查。图集回退的增量构建及六项回归分别见 `_build/cne-strum-fallback-build-227.exit`、`_build/batch-227-results.json`；首次图集测试因夹具过早释放共享图集失败，修正夹具后全部通过。更早一次脚本检查启动超时，重试通过，相关日志均保留。

## 外置资源

发行包不附带 Origin 或 CNE 的完整资源。`Project.xml` 没有为 Origin 添加资源复制或嵌入条目。

运行目录结构：

```text
NovaFlare Engine.exe
Funkin/
  chain.json
  CodeName/
    assets/                 # CNE 外部资源
    addons/
    mods-codename/
  OriginFunkin/
    assets/
      gameplay/             # 当前 Origin 资源包
      ui/
      exclude/              # 编辑器编译布局及样式
    mods-vslice/
```

解压时将资源包根目录的内容放进 `assets`，不要额外套一层 ZIP 顶层文件夹。旧 Origin 资源布局的检测入口保留，但新的上游内容和编辑器以当前资源快照为准。

Origin 默认清单在启动时挂载 `gameplay/` 和 `ui/`；编辑器构建额外挂载外部 CSS。注册表的本体 ID 列表也在运行时读取外部目录，因此不依赖编译机器上是否有游戏资源。模组加载和安装都使用 `mods-vslice`，不会写入 NF 的 `mods`。

## SDL2 与共用依赖

保留项目现有的 Lime、OpenFL、Flixel、音频及移动输入后端，启用 `ORIGIN_SDL2_COMPAT`。主要适配包括：

- 键盘沿用即时 OpenFL 事件，手柄沿用 SDL2 轮询；使用同一纳秒时钟，避免把 SDL2 的毫秒时间戳当成纳秒。
- Origin 的菜单键盘单独保留同一更新间隔内完成的快速按下和释放，避免共享 Flixel 丢掉短按；音符计时仍使用即时事件。
- 音频保留负时间起播、暂停和恢复逻辑，并接入上游的新缓存释放逻辑。
- 图形适配现有 OpenFL 绘制签名和纹理接口；高级混合保留 shader 回退，不要求 SDL3 的附加渲染目标。
- Adobe Animate 绘制在共享 FlxAnimate 的旧接口下逐帧初始化矩阵，避免沿用上一帧变换造成角色裁切、缩放累积或标题元素不可见。
- 文件对话框、缓存接口和线程任务适配现有 Lime API；VSync 通过本项目 SDL2 的 `SDL_GL_SetSwapInterval` 接口设置。
- Polymod 的脚本包装限制在兼容范围内，避免改写 NF/CNE 自己的脚本系统及底层原生类；保留 Origin 游戏类的脚本继承。

`hmm.json` 更新并固定 Polymod、json2object 和新增的 haxe-concurrent 版本。其他共享库继续使用本项目版本。不要直接用 Origin 上游整套依赖覆盖 `.haxelib`。

当前共享 hxcpp 的回调线程注册需要一个独立的小修补。旧实现从分配器池取出对象到 `AttachThread` 重新注册之间没有持有 GC 状态锁；这段间隔发生回收后，线程可能继续使用已经重新分配给其他对象的旧地址范围。`tools/setup-hxcpp-callback-handoff.ps1` 对已核实的 `Immix.cpp` 完整哈希应用三行修补，用同一递归锁保护整个交接过程，保留分配器复用及现有 GC 配置。它拒绝未知源码，备份原文件，并支持 `-VerifyOnly` 与 `-Rollback`。重新安装 hxcpp 后需要重新检查；不更换 SDL2、Lime 或 hxcpp 分支。

从源码编译前，在仓库根目录执行：

```powershell
./tools/setup-hxcpp-callback-handoff.ps1
./tools/setup-hxcpp-callback-handoff.ps1 -VerifyOnly
```

`tools/hxcpp-callback-handoff.patch` 保存可审查的实际差异。`tools/test-hxcpp-callback-handoff.ps1` 在 `_build` 内编译原始和修补后的隔离运行库副本，强制线程交接与 GC 交错；原始副本必须复现存活对象内存重叠，修补副本必须证明交接锁生效、无重叠且数组初始指针为零。测试不修改选中的 hxcpp。实际游戏视频和三侧回归仍需另外完成。

CNE 保留 NF 的资源缓存失效和模组优先级逻辑，同时提供新上游的路径和 shader 文件接口。`PATHS_CACHE_LIFETIME` 默认沿用 NF 的 6 秒，支持上游的 `0` 禁用缓存和 `null` 等待主动失效设置。

## Origin 编辑器

Windows 桌面构建默认启用 Origin 本地测试功能，直接运行：

```powershell
lime test windows
```

编译布局默认读取 `export/release/windows/bin/Funkin/OriginFunkin/assets`。使用其他外部目录时，传入 `-DORIGIN_ASSETS_PATH=C:/path/to/external/assets`，该目录需要保留上游的 `ui/editors/` 和 `exclude/ui/editors/`。编译宏直接读取外部 XML；CSS 和游戏资源仍从运行目录下的外置包读取。输出沿用项目原有目录，Windows 普通构建为 `export/release/windows/bin`，不另建编辑器输出目录。

只做源码编译时，可先运行 `./tools/setup-origin-editor-layouts.ps1`，再运行 `lime build windows -DORIGIN_ASSETS_PATH=D:/path/to/repository/_build/origin-editor-build-assets`。脚本仅下载固定 assets 提交的95份 XML/CSS，并逐个核对 Git blob SHA 和大小，保留不同内容的本地文件；不下载完整游戏资源，不把这些文件复制进发行目录。Windows CI 使用同一流程。本机构建81已用该独立布局根目录完成编译；远程 CI 尚未在本轮运行。

最新角色与文本缓存修复后，普通 `lime test windows` 再次运行并实际显示 NF 标题画面，关闭后命令退出0（`_build/ordinary-lime-test-195.log`、`.exit`）；`chain.json` 和两个 Origin 存档字节未变，NF 存档重序列化但逐字段内容不变。此检查不代表完整游玩验收。

图片、音频和图集缓存调整后的整批构建再次运行 `lime test windows`（`_build/batched-lime-test-204.log`），实际显示 NF 主菜单并退出0；同一构建的三项临时模组资源检查均通过（`_build/origin-reload-batch-204.json`）。构建中的图标替换警告再次出现；已对生成程序重试并核对32像素图标，首次失败原因尚未确定。三个存档逐字段内容与测试前一致，`chain.json` 字节未变。

生命周期保护调整后，`lime test windows`（`_build/batch-lifecycle-lime-205.log`）实际显示 NF 标题并退出0；资源图片、音频、图集检查及 CNE 暂停检查通过。CNE 节拍缩放首次运行未进入测试状态、超时结束；`_build/cne-bop-zoom-206.log` 重跑通过并退出0，首次超时原因未确认。测试前后存档语义不变、`chain.json` 字节不变。构建图标替换警告再次出现，已重试并核对当前程序32像素图标。

启用调试菜单、谱面、舞台、摄像机、动画编辑器、结算测试、模组菜单、调试快捷键、性能显示选项、截图和文件日志。在 Origin 主菜单按反引号键（通常与 `~` 同键）打开测试菜单，`F2` 打开 Flixel 调试器。日志写入可执行文件旁的 `logs/`。独立的 Tracy 性能采样构建使用 `lime test windows -Dorigin_tracy`，需要带 `cpp.vm.tracy.TracyProfiler` 的 Haxe 和配套 hxcpp；当前安装的工具链提供了这些接口，开关启用按需连接。保留当前 GC 配置，未开启与分代 GC 冲突的 Tracy 内存采样。输出仍沿用现有目录。

准备 Tracy 构建时，还需执行 `./tools/setup-hxcpp-tracy-on-demand.ps1`，并加 `-VerifyOnly` 验证。固定版本 hxcpp 的 Tracy 客户端启用按需连接，但 Haxe 生成代码内的 C++ 采样区间没有接收到相同开关；连接跨越已进入的区间时可能产生错误的结束事件。脚本对已核实的 `TelemetryTracy.h` 完整哈希应用修补，备份原文件，拒绝未知内容，并支持 `-Rollback`；可审查差异在 `tools/hxcpp-tracy-on-demand.patch`，手动使用 Git 应用该零上下文补丁时须加 `--unidiff-zero`。修补后必须重新编译使用该头文件的对象；只运行普通发行包的玩家不需要此步骤。

需要复现这一配置问题时，可在 Visual Studio Developer PowerShell 中运行 `./tools/test-hxcpp-tracy-on-demand.ps1 -TracyToolsDir C:/path/to/tracy-0.12.0`。它在 `_build` 下构建两个隔离的原生对照，要求不一致的开关复现错误、一致的开关产生可读取的帧和 zone 数据；对照在采集结束后主动退出，不测试进程关闭过程，也不能代替实际引擎采样。

在同一输出目录切换普通版与 Tracy 版时，当前 hxcpp 的增量选项过滤会忽略大写的 `HXCPP_TRACY` / `HXCPP_TELEMETRY`，可能沿用另一种配置的对象文件。先用目标配置执行 `lime build windows` 生成 `Build.xml` 和 `Options.txt`；切换后的首次链接可能因混用对象而失败，应检查选项文件确实对应目标配置。然后进入 `export/release/windows/obj` 执行 `haxelib run hxcpp Build.xml -dirty all`，返回仓库根目录后再用相同参数运行 `lime build windows` 以复制最终程序。反向切回普通版时也应执行同一流程。不要用清空整个输出目录的方式代替，因为其中可能存放用户的外置资源。Tracy 初始化日志只表示插桩已启动；需要匹配客户端版本的采集器实际连入、生成可读取的采集文件，并确认帧或 zone 数据，才能认定采样通过。

## 验证记录

当前编译与运行验证日志保存在本机忽略目录 `_build/origin-test-*.log`。完成情况以本次任务最后的测试结果为准。

先使用 `lime test windows` 编译。关闭游戏后，在 `export/release/windows/bin` 下执行 `& '.\NovaFlare Engine.exe' '--origin-test=<target>'` 直接进入测试入口，支持 `menu`、`main`、`mods`、`chart`、`camera`、`stage`、`animation`、`results`、`result-screen`、`play`、`input`。游戏测试使用练习和自动演奏模式，不写入成绩。输入诊断只在显式指定 `input` 或为测试入口添加 `--origin-log-input` 时启用。重新编译前先关闭游戏，避免 Windows 锁住 DLL。

真实键盘菜单验收可用 `& '.\NovaFlare Engine.exe' '--origin-test=mods' '--origin-log-input'`，记录游戏实际收到的按下/释放事件、修饰键状态、菜单选择与列表变化，以及切换状态后的存档模组列表。诊断只观察事件和菜单状态，不派发按键或调用菜单动作。结合操作前后截图、操作者记录与存档对比判断结果；日志开关本身不代表输入验收通过。人工参与和自动操作的证据应分别归属。

2026-11-01 的 `keyboard-only-125.log` 记录了用户仅用实际键盘操作：空格禁用并重新启用 YOURSELF，单步上下导航，Ctrl+方向键调整并恢复顺序，再用空格确认 DONE；保存和热重载后仍按原顺序启用 Impostor、YOURSELF。用户确认上下键每次移动一项；日志记录了实际空格、方向键和 Ctrl 修饰键。两份存档在验收后与操作前语义一致；其中备用存档被热重载改写的音量字段经哈希核对后恢复，写入后的版本另有备份。窗口在进入视频前关闭，退出码未捕获。此结果不代表 Enter 或其他平台已验收。

显式 `--origin-test=` 在启用调试功能时只为本次进程选择 Origin，优先于保存的 NF/CNE 启动偏好，不改写 `chain.json`。`attract` 进入真实标题视频状态；`native-video` 对三个外置标题视频执行自然结束、停止、播放中销毁、暂停恢复、重复销毁及播放期间 GC 检查。先正常编译，再直接向生成的程序传入测试参数；本机向 Lime 转发参数曾触发 Windows 命令行长度限制。只有日志中的最终 `CHECKS PASSED` 才代表该组完成；窗口提前关闭或退出码为 0 本身不代表全部通过。

`attract-lifecycle` 检查真实 Attract 状态的结束、重复结束和外部销毁路径，使用未加载媒体的播放器，检查重入时只销毁一次且不重复请求 Title。此检查不会播放视频，也不能替代 `native-video` 或实际 Attract 播放、跳过、退出验收。

2026-10-31 的 Tracy 构建先通过全量原生重建（7081 个文件，含 `Immix.cpp`、`TelemetryTracy.cpp` 和 0.12.0 客户端），再以同一组开关完成构建91。`origin-attract-lifecycle-91.log` 的全部无媒体状态检查通过，实际进程23164退出0；这些检查覆盖重复结束、停止/销毁中的重入、外部状态销毁及迟到回调，不代表真实视频生命周期已验收。

实际 Pico 结算采集96生成了37170237字节的 trace，但0.12.0的 CSV/图形分析器和0.12.2的 CSV读取器均发生访问异常。独立对照108在连接跨越已进入的 C++ 区间时复现了“zone 被结束两次”：当客户端与区间代码的按需连接开关不一致时失败，开关一致时可正常导出。修补后的实际 Haxe/hxcpp 对照110和引擎采集113均通过：采集113包括2247个帧标记、10409078个 zone、5.03秒跨度，0.12.0 CSV读取器正常导出1302行；其中 `ResultState.draw`、`Stage.__render` 和显式命名缓存区间均有非零数据。游戏进程及结算生命周期检查通过，结果见本机 `_build/origin-tracy-capture-113-verified.json`。这是 Pico 结算路径的采样验收，并不代表视频或全部游玩路径已验收。

2026-10-25 已实测：Windows SDL2 编译及运行；149 个脚本类、11662 个标识符/成员引用预热零错误；谱面编辑器加载并播放 Bopeebo；摄像机编辑器加载同曲、构建舞台并播放时间轴；舞台编辑器加载 Main Stage；动画编辑器切换 spritesheet/animations；Bopeebo 自动演奏整曲进入结算；结算参数菜单和实际结算画面；窗口最大化与恢复。当时仅提供 Tracy 开关；后续构建及采集结果以上述2026-10-31记录为准。


## CNE RC4 上游检查（2026-11-01）

CodenameCrew 已发布预发布版 [v.1.1.0-rc4](https://github.com/CodenameCrew/CodenameEngine/releases/tag/v.1.1.0-rc4)（标签中的 `v` 后有一个点），固定提交 `2dd7d8114726aba9bc2a375f89f19c5cff5fdd9b`。GitHub 比较结果显示该提交是当前记录的上游基线 `2289c833aa4d9a6a7f9f98a49fe994101ab75c16` 的后代，领先 23 个提交、涉及 31 个文件；[差异](https://github.com/CodenameCrew/CodenameEngine/compare/2289c833aa4d9a6a7f9f98a49fe994101ab75c16...v.1.1.0-rc4)。主要涉及着色器、角色编辑器、Freeplay、输入设置及帧节奏，以及上游项目配置和本地化资源。发布说明以 RC3 为基线，列出的部分功能可能已包含在本地导入的中间提交中，不能全部算作本次新增差异。

此处只是只读检查，尚未把 RC4 合入本地，也未验证其与 NovaFlare SDL2、既有 CNE 适配及外置资源的交互。后续更新必须按实际源码差异逐项合并，保留用户未提交改动，不能直接覆盖 `Project.xml` 或外置资源。

这 23 个提交中，上游 `building/libs.xml` 和 `project.xml` 已移除 `FunkinModchart`，还调整 OpenFL/Lime、链接和高 DPI 定义；上游 `FreeplayState` 引入歌曲预览与 addon 歌曲列表合并。NovaFlare 共用工程配置及本地脚本兼容存在独立约束，应评估依赖移除和功能迁移的实际影响，不能把上游项目文件整份覆盖到本地。

RC4 源码只读三方预览保存在 `_build/cne-rc4-preflight-253/`：以两个固定上游提交和当前 17 份对应 CNE 源码为输入，进行初步命名空间替换并用 `git merge-file --diff3` 生成预览；其中 7 个文件出现合并冲突，包括 `FunkinShader`、`FreeplayState`、模组菜单、设置、移动端保存及脚本配置。初步预览未修改工作树，且命名空间转换尚需逐项审查；不把其结果视为可直接应用的补丁。项目配置和外置语言资源未纳入该预览，也未覆盖。两个本地工作目录的这 17 份对应文件在预览时内容一致。

进一步核对显示，当前 CNE 启动路径仍调用 `ShaderResizeFix.init()`，本地还存在 `CodeNameModchartAdapter` 和 `MODCHARTING_FEATURES` 条件代码；RC4 对旧 resize 修复及 modchart 配置的删除不能单独照搬，需连同本地依赖、运行时和调用链验证。所谓无文本冲突也不代表可以安全单独合并。

### Origin 0.9 预览目标与上游核对（2026-11-01）

用户将 Origin 模组兼容目标扩展到尽可能支持 0.9.0 预览及后续正式版，同时保留已有旧版范围与本地修改。核对 [Funkin 官方发布页](https://github.com/FunkinCrew/Funkin/releases)：目前最新正式标签为 `v0.8.7`；0.9.0 的内容与接口仍处于开发／预览，不能把加载器接受 API 0.9.0 当作完整兼容证明，也不能预先保证尚未发布的最终版本。

官方 `main` 当前为 `86cb949c74743b2bdbb58a66326acdb47a36f43a`，与先前保存的 2026-11-01 快照一致；`preview/public-playtest` 当前为 `d3fdf329faa7419dbf91afd7b3204f36e010daa2`，较本地历史引用 `88bb0eac4c65a2e564d928b320d3e6c424e26d59` 前进 107 次提交。当前导入的 miniaudio 预览基线 `92b437886e1ef1b5c7a0fa184be92a66b14e2cd3` 与新预览分支发生分叉：GitHub 比较报告新分支领先 126、基线侧独有 3 次提交。两份源码 ZIP 比较发现 227 个文件差异，其中 215 个为源码；由于 ZIP 不代表 gitlink 变更，此数字不代替完整 Git 及外部资源比较。详细文件清单保存在 `_build/origin-upstream-preview-20261101/imported-to-preview-inventory.json`。Git 拉取因网络连接失败，另以固定提交 ZIP 和 GitHub 比较接口只读获取信息；未覆盖工作树，也未直接合并上游。后续应逐项审查 0.9 预览的模组加载、脚本 API、数据格式、编辑器及资源边界，并以真实模组与可见窗口验证。

### 2026-11-14 Origin 上游检查与部分移植

官方 `main` 当前为 `94ee0f2a9386d80e445be39ee2ed4b4a630cfbac`：相较本文件上次记录的 `86cb949c74743b2bdbb58a66326acdb47a36f43a` 仅有一处上游移动编译指南语法修正，没有游戏源码变更。本项目未导入该上游指南，故无需覆盖本地文件；这不代表回退或替换现有预览代码。

`preview/public-playtest` 当前为 `08c0b800002bd50c432d4f4b5f6fdb3088ca619e`，较此前记录的 `d3fdf329faa7419dbf91afd7b3204f36e010daa2` 有 243 个提交、287 个文件差异；这两个预览快照之间的差异不能当作本地已合入的差异。资源 gitlink 分别为 main `724eba9de9e76761d9cefd52169926bc51c760a5`、新预览 `dbfb530be1a64d7ea90ce74e9c324f95e09aa694`；用户外置资源未更改。

已单独移植 [4afe885b6176b4e51677d96c48138215ab56b07e](https://github.com/FunkinCrew/Funkin/commit/4afe885b6176b4e51677d96c48138215ab56b07e) 中 `Sequence` 定时修复：计算间隔时使用排序后的实例列表，而不是构造参数原始顺序。`_build/origin-upstream-timer-931` 提取项目实际类并使用定时器替身运行 Haxe：输入事件顺序 3、1、2、倍数 2 时，旧代码间隔为 2、-2、4，新代码为 2、2、2；未进行完整构建或游戏画面验证。本地热重载已在主线程清理模块和脚本，DJ 资源查询已返回脚本提供的结果，不应直接覆盖本地兼容实现。其余预览变更及依赖、资源更新尚未逐项移植或验证，不能视为预览分支同步完成。

另移植 [1ce0de5ff067c6a15e529a0083c7177337db9e4b](https://github.com/FunkinCrew/Funkin/commit/1ce0de5ff067c6a15e529a0083c7177337db9e4b)：谱面序列化在克隆对象上删除空难度，避免破坏编辑器中的内存数据。`_build/origin-upstream-chart-932` 提取正式序列化方法，使用轻量谱面与 JSON 写入替身验证输出省略空难度、原对象保留空难度；未进行完整工程构建或编辑器运行验证。

上游修复的工程类型检查（2026-11-14）：使用现有 Windows release HXML、实际项目依赖、CPPIA 定义及 `--no-output` 检查当前 D 盘源码，退出码 0（`_build/origin-upstream-typecheck-933/result.txt`、stdout/stderr）；未链接或运行新程序，不代替编辑器和游戏内验收。

图像缓存生命周期修复（2026-11-14）：移植 Origin 预览提交 [548cdea690ae52012d0b4cd5615e8c26fd967b91](https://github.com/FunkinCrew/Funkin/commit/548cdea690ae52012d0b4cd5615e8c26fd967b91) 的永久图像保护，普通 `FlxG.bitmap.remove` 不销毁永久缓存中同一个对象，显式强制清理路径仍可移除。保留本地同键资源热重载保护，并额外处理旧、新 `FlxGraphic` 共用一个 `BitmapData` 时销毁旧包装会连带释放新图像位图的问题：仅在缓存中存在不同对象且确实共用位图时，先从旧包装解除位图引用。`_build/origin-permanent-graphic-934` 提取正式移除方法并运行实际 `StagedCache`，以图像/信号替身检查永久对象、不同图像同键、同键共享位图、普通删除和强制清除；旧代码分别触发永久对象销毁及共享位图释放，新代码通过。第一次完整 Windows Haxe 类型检查（935）暴露赋空的空值约束；缩小空值检查豁免范围后重新检查 936，退出 0，stderr 为空。没有重新链接游戏或进行 GPU/热重载运行验收。

谱面数据与事件校验 API（2026-11-14）：参考 Origin 预览提交 [4c8ef28c77674a374e8091fc206875a26f738722](https://github.com/FunkinCrew/Funkin/commit/4c8ef28c77674a374e8091fc206875a26f738722) 及预览分支 `08c0b800002bd50c432d4f4b5f6fdb3088ca619e`，补上 `SongEvent.validate`、`SongChartData.validateChartEvent(s)`、事件校验缓存读取和提示文本，并修复空事件参与相等／不等比较时的空对象访问；未注册事件维持无校验错误。同步编辑器 `_editor` 的 `subBeats` 与 `subBeatSnaps` 数据字段及克隆，旧谱面缺失字段有默认／空值处理，避免保存时丢掉新字段。`_build/origin-chart-api-937` 提取正式方法，验证空事件、难度参数、首个错误和克隆独立性，并使用实际 json2object 解析新旧编辑器数据及序列化；事件处理器和其余谱面类为轻量替身。完整工程 Windows release 配置加 CPPIA 的 Haxe `--no-output` 检查退出 0（`_build/origin-chart-api-typecheck-938`）。尚未接入上游编辑器的全部校验界面、具体事件的新增校验规则，也未重新链接游戏或用真实 0.9 模组调用这些新 API。

谱面重叠音符和滚速事件设置（2026-11-14）：移植 Origin 预览提交 [f6eb9fb80dd7eef72db37357668e0dadb999697c](https://github.com/FunkinCrew/Funkin/commit/f6eb9fb80dd7eef72db37357668e0dadb999697c) 的重叠音符扫描，按时间排序副本并跨原 2500 ms 分块边界比较，使用对象身份区分独立音符；保持用户输入数组不变。`_build/origin-stacked-notes-939` 提取正式扫描及匹配代码，音符／节拍对象为替身：旧实现漏掉 2499.8 ms 和 2500.2 ms 的同轨重叠，新实现通过该边界、乱序、不同轨道、多个音符、阈值及排除前项的检查。另参考 [d5f67f793be8b0f922632f996ff8c3679ce4dea2](https://github.com/FunkinCrew/Funkin/commit/d5f67f793be8b0f922632f996ff8c3679ce4dea2)，补回滚速事件已有 `useStart` / `startScroll` 行为对应的编辑器 schema 字段；`_build/origin-scroll-schema-940` 使用正式 schema 实现和提取的事件 schema 检查字段及默认值。完整工程 Windows release + CPPIA Haxe `--no-output` 检查 941 退出 0、stderr 为空。尚未重新链接游戏或实测编辑器画面、真实谱面的音符修正。

谱面音符解析与空参数（2026-11-14）：按 Origin 预览提交 [f6eb9fb80dd7eef72db37357668e0dadb999697c](https://github.com/FunkinCrew/Funkin/commit/f6eb9fb80dd7eef72db37357668e0dadb999697c) 接入 `songNotesMap` 解析器及相关数据解析辅助方法，显式 `p: null` 现在规范化为空参数数组，嵌套参数值保留。针对旧版解析器差异，本地额外保留空难度与空音符的解析接受行为；这不代表后续所有消费代码都能处理这些空值。`_build/origin-note-parser-942` 提取正式字段定义、候选解析方法并使用实际 json2object，对 Yippie、Eradication、Insanity 和 Mindless 四份原始模组谱面的 8,675 个音符比较时间、方向、长度与类型一致，另外验证空参数、嵌套参数和 JSON 写回再读取；这些不是游戏内运行测试。边界对照还显示，新解析器沿用上游行为接受部分旧解析器拒绝的数据（例如小数方向会截断为整数）；缺失必需时间或方向仍报错。Windows release + CPPIA 的 Haxe `--no-output` 类型检查 943 退出 0；未链接游戏，实际模组完整流程尚待验证。

批量源码审查（2026-11-14，尚未编译）：依据 Origin 预览提交 [365dee81ecad5d7b3455d14d64c0549f562863e6](https://github.com/FunkinCrew/Funkin/commit/365dee81ecad5d7b3455d14d64c0549f562863e6)，长按音符在按住及首次命中时按视觉歌曲位置裁剪，衔接已有滚速时间线。旧版 LoadingState 使用异步加载回调，销毁状态后回调仍可能触发 onLoad 并切换状态；现于销毁前标记并阻止销毁后的切换。此状态与新版上游 LoadingState 结构不同，该防护仅处理本地回调，不表示取消了底层资源请求。两项均待批量代码完成后统一编译与运行验证。上游 ABot 可视化的 dispose 修改依赖当前 funkin.vis 缺失的接口，未直接移植。
