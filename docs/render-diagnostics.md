# 渲染线程在交还 OpenGL 上下文前完成已接收的命令。

在项目目录运行 `tools/setup-novaflare-render-dependencies.ps1 -Component RenderThreadRepair`。随后运行 `haxelib run lime rebuild windows -64` 或 `haxelib run lime rebuild android`，再构建游戏。Windows、Android、iOS、Linux 和 macOS 的构建流程会安装补丁并重建相应的 Lime 原生库。

上下文交接期间，持有上下文的应用线程可以直接执行 GL 调用。上下文暂时不可用时，同步调用会返回失败值。关闭渲染线程会取消尚未开始的命令，窗口资源在正在执行的驱动调用返回后释放。窗口曝光和尺寸变化合并到应用线程的绘制调度，队列满时保留请求，到下一次调度时检查。

OpenFL 的紧密排列 32 位 RGBA 或 BGRA 图像在确认缓冲区范围后复制像素，由渲染线程按提交顺序上传。其他格式和裸指针上传继续使用同步接口。需要查询 GL 结果的操作也继续同步等待。

同步 GL 日志仍可用于定位前一帧交换缓冲区传给主线程的等待。渲染批次使用固定数量的命令容器，`pool_wait` 记录等待空闲容器的时间，分析脚本仍可读取旧版日志中的 `submit_wait`。

上下文交接超时后，前台应用循环定期检查渲染线程是否已释放上下文。确认释放后，应用线程可接回上下文并恢复绘制。设备重置时，应用先派发丢失通知，再等待上下文可用后通知资源重建。

游戏更新和独立绘制分别维护截止时间。回调中调整速率会立即替换对应的截止时间。短暂延迟允许下一轮事件循环补跑一次更新，较长延迟从当前时刻排期。独立绘制会跳过过期帧。关闭独立绘制后，定时绘制随游戏更新派发。绘制回调使用浮点毫秒计算间隔，亚毫秒间隔仍会传给动画与脚本。

Windows、Linux、macOS 和 Android 在 SDL 确认开启 VSync 且使用 OpenGL 渲染线程时，上一批绘制完成后才开始下一次绘制派发。iOS 的 UIKit 后端通过屏幕刷新回调安排绘制，OpenGL 渲染线程采用同一条单批规则。游戏更新继续按原截止时间调度。独立绘制错过截止时间时保留一次绘制请求，渲染线程完成上一批后再派发。OpenGL 同步查询和渲染命令保持原提交顺序。

应用仅在当前 OpenGL 上下文成功设置交换间隔后记录新的 VSync 值。修改渲染帧率不会重新开启独立绘制。核对锁帧时同时查看 `swap_interval`、`split_render`、更新与绘制周期，以及窗口焦点。 [Windows 渲染线程回归测试](../tools/tests/render-thread/README.md) [Windows 绘制节奏回归测试](../tools/tests/render-cadence/README.md)

OpenFL 的原生四边形绘制会复用 CPU 顶点容量，只上传本帧实际使用的顶点前缀。三角形、Tilemap 和浏览器继续通过各自的上传入口。

在 Windows 上重建 Lime 后，运行以下命令检查图形缩小后的上传字节数、缓冲区复用和像素结果。测试会额外执行一次完整容量上传，打印两种上传方式的字节数。

```powershell
$env:SHOW_CONSOLE = '1'
haxelib run lime build tools/tests/render-geometry/Project.xml windows -64
& ./_build/render-geometry-test/windows/bin/NovaFlareRenderGeometryTest.exe
```

# 逐帧诊断使用同一个 Windows 性能计数器。

在项目目录运行 `tools/setup-novaflare-render-dependencies.ps1 -Component Timeline`，然后执行 `haxelib run lime rebuild windows -64`。用 `SHOW_CONSOLE=1` 重新构建游戏，并确认 Windows 产物目录装入了新生成的 `lime.ndll`。Immix 暂停计时随游戏的 hxcpp 编译进入可执行文件，Lime 负责采集 SDL 和 OpenGL 的时间戳。存档和模组目录由独立采样脚本创建。

```powershell
& .\tools\sample-novaflare-gameplay-timeline.ps1 `
    -Executable '<frozen runtime>/NovaFlare Engine.exe' `
    -RunDirectory '<new run directory>' `
    -RenderThread 0 -UpdateRate 240 -DrawRate 1200 -SplitRender 1
```

采样脚本从 MILF Hard 伴奏启动处计时 135 秒，使用难度索引 2 和机器人演奏。`capture.json` 记录启用的环境变量、可执行文件与 `lime.ndll` 的 SHA-256、退出状态，以及歌曲和采样边界的原始计数。`frame-timeline.csv` 记录更新、生成 OpenGL 命令、同步等待、队列深度、GL 命令执行、实际 `SDL_GL_SwapWindow` 的调用区间和窗口焦点。`gc-pauses-qpc.csv` 记录 Immix 暂停区间。`clock` 行的 `value` 是每秒计数，两个 CSV 的计数可以直接比较。游戏线程和渲染线程把帧时间线数据交给后台写入，应用退出时排空。分析器检查异步时间线的结束记录，并拒绝丢失数据的采样。尾部窗口焦点由 SDL 事件与 `process-samples.csv` 一同核对。

普通游戏默认打开垂直同步。准备支持运行时切换的构建时，执行 `tools/setup-novaflare-render-dependencies.ps1 -Component VSync`，用 `haxelib run lime rebuild windows -64` 或 `haxelib run lime rebuild android` 更新相应平台的 Lime 原生产物，再构建游戏。独立 Windows 采样默认传入 `-VSync 0`，可用 `-VSync 1` 测量开启档。脚本在采样区间核对 SDL 实际交换间隔，报告用 `vsync_measured` 标记是否测得。旧程序缺少交换间隔记录时，该值为 `false`。

执行 `tools/setup-novaflare-render-dependencies.ps1 -Component FocusCadence` 安装 Flixel 的失焦帧率补丁，然后重新构建游戏。测试自动暂停的失焦与恢复行为时，从普通游戏启动，留空 `NOVAFLARE_UPDATE_RATE` 和 `NOVAFLARE_DRAW_RATE`，分别观察 SDL 更新和绘制周期。安装移动虚拟指针的触摸事件过滤时，执行 `tools/setup-novaflare-render-dependencies.ps1 -Component VirtualPointer`，并重建移动端 Lime 和游戏。

运行 `tools/setup-novaflare-render-dependencies.ps1 -Component RenderState` 安装渲染状态优化，再重建 Lime 和游戏。每批命令仍会提交第一次视口和纹理单元设置。纹理的过滤、寻址和多级纹理生成继续由 OpenFL 设置。

依赖安装脚本会在 Lime 的 `project/Build.xml` 登记 `RenderThread.h`。头文件变更后，hxcpp 会重新编译使用它的六个编译单元，避免增量链接混入旧布局的对象文件。

普通采样的 `gc-pauses-qpc.csv` 保持六列。需要记录 Immix 阶段时，运行 `tools/setup-novaflare-render-dependencies.ps1 -Component GcBreakdown`，重新构建 Windows 游戏，再给采样命令加上 `-GcBreakdown`。该开关设置 `NOVAFLARE_GC_BREAKDOWN=1`，日志额外记录线程就绪、根与线程栈扫描、标记遍历、终结器、回收、碎片整理、释放线程及收集时的堆状态。`*_ticks` 使用同一 QPC 时钟。给采样命令加上 `-HaxePerfTrace` 可开启 Stage、Flixel 和 OpenFL 的细分日志。采样脚本在后台排空游戏输出管道，进程退出后保存原始日志。给采样命令加上 `-PreferencesFile '<funkin.sol>'` 可复制指定存档到隔离环境。采集清单记录复制字节的 SHA-256。

普通 Windows 和 Android 构建需要先运行 `tools/setup-novaflare-render-dependencies.ps1 -Component GenerationalGC`。项目固定的 NovaFlare hxcpp `c349423` 内置分代 GC、块回收和数组标记修改，脚本会检查相关源码。使用 `3f50506` 或 `ac2af3c` 时，脚本仍安装对应补丁。首次启用这一构建配置时，重新生成应用 C++ 并重新编译所有使用 hxcpp 布局的编译单元。`HXCPP_GC_GENERATIONAL` 会同时编译分配布局和写屏障。选项默认关闭，关闭时 Immix 使用全堆收集，已编译的分配布局和写屏障仍会使用。退出设置页面时保存，下次启动从 `funkin.sol` 读取并应用。NovaGC 和其他平台的构建不显示此选项。

Windows、Android、iOS、Linux 和 macOS 的 Immix 构建通过 `-Component ImmixReclaim` 准备全量块回收优化。全量回收读取对象起点位图，只检查登记了对象起点的位置，并按这一轮的标记更新位图和存活字节数。手动安装补丁后需重建游戏的原生可执行文件。使用 `-GcBreakdown` 采样时，可在 `full_reclaim=1` 的记录中用 `reclaim_ticks` 比较块回收阶段。

Android ARM64 构建通过 `-Component ImmixMark` 准备数组标记优化。每次扫描对象数组时读取一次当前 GC 标记掩码，标记条件与对象晋升逻辑沿用 Immix 的原有规则。补丁随应用原生库重编生效。

Lime 在首次交换缓冲区和窗口尺寸或显示器变化时记录 `window_size` 与 `drawable_size`。`display_dpi_milli` 记录可获得的水平和垂直显示 DPI，每单位表示千分之一 DPI。`capture.json` 另记录歌曲开始时的 Win32 客户区和窗口 DPI。硬件查询在歌曲启动后创建，开始时可看到驱动为当前进程建立的计数器实例。GPU 峰值报告仅使用该进程存在对应计数器的样本。

`render_commands` 的 `value` 关联最近一次更新，`auxiliary` 标识是否使用渲染线程。`queue` 的 `value` 是包括当前提交在内的待处理批次数，`auxiliary` 是该批 OpenGL 命令数。`queue`、`driver_batch` 和同步调用按 `batch` 关联。`phase` 指示批次在更新还是绘制阶段提交。已有命令待提交时跨越阶段，记录附带 `_mixed`。`driver_batch` 包含该批内的 SDL 交换缓冲区时间。`gpu_elapsed` 的 `value` 是两条 OpenGL GPU 时间戳的纳秒差，日志行的计数表示取到该结果的 CPU 时间。显示器实际呈现需要另行采集 Windows 图形与桌面合成事件。

采样脚本使用 Python 3.10 或更新版本生成 `frame-summary.json`。可用 `-PythonExecutable` 指定解释器路径。报告包括更新帧、绘制派发与交换缓冲区的延迟分位数、长帧重叠阶段、焦点、资源峰值以及伴奏结束后的采样覆盖。`long_update_gaps` 按相邻两次更新的起点记录长间隔，`overlaps_recorded_gc` 标记该间隔是否与已记录的 Immix 暂停相交。`phase_overlap_ms` 列出各阶段独立重叠的时长，同一段时间可同时属于多个阶段。另行运行 `python tools/analyze-novaflare-frame-timeline.py '<run directory>'` 时，可以加 `--song-only` 限制到伴奏结束，或用 `--long-gap-ms` 调整列入报告的交换间隔。

`coverage` 按帧编号统计更新、绘制派发和交换返回序列内部的编号间隔。绘制与交换以及交换与 GPU 时间戳分别按帧编号匹配。报告区分采样窗内匹配、原日志中处于采样窗外的匹配和原日志无匹配，并单独列出 GPU 查询积压的记录数。

给 Windows 采样命令加上 `-PresentMonExecutable '<local signed PresentMon 2.6.0 executable>'`，即可同时采集 Windows 图形事件。采样目录保留 `presentmon.csv`、控制台日志和 `capture.json` 中的命令及会话状态。`frame-summary.json` 按交换链和呈现模式统计两个端点均在采样窗内的显示区间，单独记录未显示的提交、缺失值和截断行。显示时间来自 Windows ETW 事件，光学扫描输出需要外部硬件测量。

有效的 PresentMon 采样要求目标进程的呈现记录从采样窗开始前延续到至少窗口结束前 100 毫秒。存在截断尾行时，最后一条有效目标记录还须到达采样窗结束。采样排除有中间坏行、明确 ETW 丢失或呈现记录溢出的运行。PresentMon 未报告的丢失计数为 `null`。零显示延迟单独计为未解析的显示时间。

用 `-Dnovaflare_transition_trace` 重新构建 Windows 游戏，再用相同的独立采样脚本运行，可在 `stdout.log` 读取歌曲结束阶段的 `perf:transition_phase` 区间。`begin_qpc` 和 `end_qpc` 与逐帧 CSV 使用同一个性能计数器。成绩界面分支记录构造、打开请求及菜单音乐准备和播放，回调区间覆盖完整的 `endCallback` 调用。移除玩法 GC 接管后，游戏不再产生 `gameplay_gc_finish` 区间，旧日志仍可读取。

需要追踪 OpenGL 深度附件首次分配时，运行 `tools/setup-novaflare-render-dependencies.ps1 -Component RenderAttachmentTrace`，用 `-Dnovaflare_render_attachment_trace` 重新构建 Windows 游戏，再给采样命令加上 `-RenderAttachmentTrace`。`stdout.log` 中的 `perf:render_attachment_allocation` 记录附件分配区间。`perf:render_attachment` 记录可关联的位图绘制区间、显示对象与父对象，以及缓存位图和滤镜信息。用纹理、帧缓冲区和深度附件编号关联两条记录，并按 QPC 核对区间。只有分配记录时，当前日志未识别出显示对象。

# 分辨率选项调整 OpenGL 缓冲区的像素尺寸。

运行 `tools/setup-novaflare-render-dependencies.ps1 -Component Resolution` 后重新构建 Lime 和应用。OpenFL 依赖启用 `nova_stage_render_target`，应用才会切换到渲染缓冲区实现。Windows 保持 1280×720 的逻辑尺寸基准。移动端优先使用有效的主显示器逻辑尺寸。视口和裁剪框根据缓冲区尺寸缩放，指针和触控继续使用舞台坐标。

固定档位给出宽高上限，缓冲区按窗口可绘制像素区域的宽高比等比缩放。1600P 档位上限为 2560×1600。16:9 窗口使用 2560×1440，21:9 窗口使用 2560×1097，4:3 窗口使用 2133×1600。Native、同尺寸档位、分配失败及非 OpenGL 路径直接绘制到窗口。`NOVAFLARE_RENDER_RESOLUTION=640x360` 或 `native` 可单独覆盖测试分辨率。`NOVAFLARE_RENDER_TARGET_TRACE=1` 记录 OpenGL 颜色附件和视口尺寸。OpenGL ES 低于 3.1 时，日志可能只能记录通过完整性检查的目标分配尺寸与实际视口。

窗口尺寸已变化但 SDL 调整尺寸事件尚未送达时，OpenGL 固定档位会在绘制前更新舞台变换、窗口缓冲区和渲染器尺寸。`Event.RENDER` 监听器执行后也会检查窗口尺寸。动态窗口测试可用 `viewport_origin` 检查首个和稳定视口的原点，并用 `viewport` 核对实际颜色附件尺寸。

在常规 Android 包的构建命令中加入 `-Dnovaflare_render_target_trace`，可从 `adb logcat -s trace` 读取 `perf:render_target`。此开关沿用常规包名、应用存储和界面内的分辨率选项。

Windows 视觉验收使用带 `-Dnovaflare_render_snapshot` 的独立构建。设置 `NOVAFLARE_RENDER_SNAPSHOT=1` 后用隔离采样脚本启动。歌曲开始约 8 秒后，采样目录中的 `render-snapshot.ppm` 保存当前合成后的完整窗口画面。可以用 `ffmpeg -i render-snapshot.ppm render-snapshot.png` 转成 PNG。截图日志记录非黑像素数。普通构建直接省去截图逻辑，正式性能对照使用普通构建。

# Android 会话由 SDL 游戏线程管理。

运行 `tools/setup-novaflare-render-dependencies.ps1 -Component Resolution,AndroidHints`，然后执行 `haxelib run lime rebuild android` 和 `haxelib run lime build android -Dnovaflare_render_diagnostics`。构建和安装 `com.NovaFlareEngineNew.renderdiagnostics` 的 APK。该测试包专用的启动参数控制测试，文件和存档使用应用私有目录。

```powershell
adb shell am start -n com.NovaFlareEngineNew.renderdiagnostics/.MainActivity `
    --es nova_song milf --es nova_resolution 640x360 --ez nova_adpf true
adb logcat -s NovaFlareADPF NovaFlareTimeline trace
```

常规 Android 包在「常规设置」提供「性能提示」，默认关闭。Origin 和 Codename 启动时读取相同的 NovaFlare 偏好。诊断包使用 `nova_adpf=true` 开启或 `nova_adpf=false` 关闭。会话在 Android API 31 及以上且设备报告支持时创建，包含实际的 SDL 游戏线程和启用的 GL 渲染线程。耗时从绘制派发到当前交换开始，并计入此前的游戏更新时间。统计扣除了可确认发生在当前线程提交完成后的前一帧交换等待。设备不提供会话时使用常规调度。关闭「性能提示」或应用进入后台时关闭会话。
