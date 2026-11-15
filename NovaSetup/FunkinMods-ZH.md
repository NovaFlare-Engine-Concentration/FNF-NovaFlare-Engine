# Funkin 目录与引擎入口说明

本文说明 NovaFlare Engine 的 `Funkin` 运行目录应放在哪里、OriginFunkin 与 CodeName Engine 的资源和模组如何摆放，以及如何从 NovaFlare Engine 进入对应引擎。

## Funkin 目录放在哪里

Windows 下，`Funkin` 与 `NovaFlare Engine.exe` 同级。例如本项目普通 Windows 构建的运行目录是 `export/release/windows/bin/`：

```text
NovaFlare Engine.exe
assets/
manifest/
mods/
replays/
Funkin/ <---这里
```

不要把 `Funkin` 放进 NovaFlare 自己的 `assets`、`mods` 或其他子目录。

Origin 与 CNE 的完整资源都需要用户自行下载、外置放置，不随引擎发行包附带；配置教程不会自动下载资源。

## 完整目录结构

```text
Funkin/
├─ chain.json
│
├─ OriginFunkin/
│  ├─ assets/
│  │  ├─ gameplay/           # 歌曲、角色、舞台等游戏资源
│  │  ├─ ui/                 # 菜单、字体等界面资源
│  │  ├─ exclude/            # 编辑器布局、样式等辅助资源
│  │  └─ LICENSE.md
│  │
│  └─ mods-vslice/
│
└─ CodeName/
   ├─ assets/
   │  ├─ data/
   │  ├─ fonts/
   │  ├─ images/
   │  ├─ languages/
   │  ├─ music/
   │  ├─ shaders/
   │  ├─ songs/
   │  ├─ sounds/
   │  └─ videos/
   │
   ├─ addons/
   └─ mods-codename/
```

CodeName Engine 运行时可能自动创建 `.temp`，这是正常的临时目录，无需手动准备。

## 资源与模组位置

### OriginFunkin

- 将本项目已导入的 Origin 运行时基线对应的官方资源放入 `Funkin/OriginFunkin/assets/`。该固定基线不一定等同于上游最新公开预览版。
- V-Slice 模组放入 `Funkin/OriginFunkin/mods-vslice/`。
- `assets` 与 `mods-vslice` 必须同级。
- 不要把 `mods-vslice` 放进 `assets`。
- 本次对应的资源版本为 `0b28106619ecf017af57c54dfde8653350b66128`。
- [Funkin Assets 资源页面](https://github.com/FunkinCrew/funkin.assets/tree/0b28106619ecf017af57c54dfde8653350b66128)
- [资源 ZIP 下载直链](https://github.com/FunkinCrew/funkin.assets/archive/0b28106619ecf017af57c54dfde8653350b66128.zip)

当前源码包含旧版 Origin 模组兼容和部分 0.9 预览 API 适配；具体支持情况取决于模组及其功能，近期改动尚未完成完整原生构建和全游戏验收。详见[兼容证据与未完成检查](../docs/origin-mod-compatibility.md)。

解压步骤：

1. 解压资源 ZIP，打开最外层的 `funkin.assets-0b28106619ecf017af57c54dfde8653350b66128` 文件夹。
2. 将里面的 `gameplay`、`ui`、`exclude` 文件夹，以及 `LICENSE.md` 等说明文件放入 `Funkin/OriginFunkin/assets/`。不要把 ZIP 最外层文件夹一起套进去，也不要再多套一层 `assets`。
3. 升级旧资源时，先将旧版 `fonts`、`preload`、`shared`、`songs`、`week*` 等目录移出 `assets` 并自行备份，再放入新版资源，避免新旧布局混用。`mods-vslice` 是独立的模组目录，不需要随资源更换。
4. 保留 `exclude`。它包含编辑器需要的布局和样式，复制资源本身不会自动开启编辑器。

本项目当前指定的实际目录是：

```text
D:\game\FNF-NovaFlare-Engine\export\release\windows\bin\Funkin\OriginFunkin\assets\
```

放好后应能直接找到：

```text
assets/gameplay/songs/tutorial/tutorial-metadata.json
assets/gameplay/songs/tutorial/Inst.ogg
assets/ui/fonts/
assets/ui/title/logo-bumpin.png
assets/exclude/ui/editors/
```

Origin 的源码 ZIP `Funkin-miniaudio-public-playtest.zip` 不能代替资源 ZIP。V-Slice 模组应单独解压到 `mods-vslice/<模组名>/`，保持模组自己的目录结构；不要把模组直接覆盖进本体 `assets`。

#### 旧版角色贴图模组的补充资源

部分旧模组只替换 PNG，而新版原版角色已改用 Animate 格式。此类模组还需要对应的旧 XML 和动画定义。在项目根目录运行：

```powershell
./tools/setup-origin-legacy-assets.ps1 -AssetsRoot 'D:/game/FNF-NovaFlare-Engine/export/release/windows/bin/Funkin/OriginFunkin/assets'
```

脚本从固定的官方 assets 提交下载旧版资源，写入外部 `assets/compatibility/origin-v0.3.2/`，生成来源和 SHA256 清单。补充包覆盖 BF、Dad、GF、Pico、Tankman 及汽车/圣诞变体，共 12 个角色配置，并补回旧 Philly 普通和 Erect 舞台各五张 `win0`–`win4` 灯光图，以及旧 Nene 脚本/JSON 使用的 Sparrow 图集。Nene 图集不替换新版原角色配置；这些补充不代表所有历史模组已经兼容。发行时可由用户单独放置这个 `compatibility` 文件夹，资源仍不随引擎打包。基础资源仍使用上面指定的新版资源包，模组仍放在 `mods-vslice`。

运行时根据模组实际提供的图片选择旧配置；模组自带的角色 JSON/脚本保持优先，较后加载的新版 atlas 可以恢复新版角色配置。脚本可重复运行；检测到补充资源被本地修改时会停止并保留该文件。更新基础资源后，应重新运行脚本以重新适配其中的原版角色脚本。

### CodeName Engine

- CodeName Engine 官方资源放入 `Funkin/CodeName/assets/`。
- CodeName 模组放入 `Funkin/CodeName/mods-codename/`。
- `assets`、`mods-codename`必须同级。
- [CodeName Engine 对应上游快照](https://github.com/CodenameCrew/CodenameEngine/tree/2289c833aa4d9a6a7f9f98a49fe994101ab75c16)
- [ZIP 下载直链](https://github.com/CodenameCrew/CodenameEngine/archive/2289c833aa4d9a6a7f9f98a49fe994101ab75c16.zip)。下载后只将其中 `assets` 文件夹的内容放到 `Funkin/CodeName/assets/`，不要把整个源码包放进去，也不要形成 `assets/assets/`。

### NovaFlare Engine 自身内容

`Funkin` 只存放外部引擎内容。NovaFlare Engine 自己的资源和模组仍使用可执行文件旁边的：

```text
assets/
mods/
```

不要把 NovaFlare 的 `assets` 或 `mods` 移入 `Funkin`。

## 游戏内入口

在 NovaFlare Engine 中依次进入：

```text
设置
└─ User Interface（用户界面）
   └─ SelectGameSubState（引擎选择）
```

打开引擎选择界面后：

1. 选择 `Origin Funkin` 或 `CodeName Engine`。
2. PC 上按确认键进入；手机上可以点击当前显示的引擎介绍图。
3. NovaFlare Engine 会保存选择并退出。
4. 再次启动 `NovaFlare Engine`，程序会进入所选引擎。

**CodeName Engine 现在同时支持 PC 与手机；手机版复用 NovaFlare Engine 的触控布局和控制设置。**

## 启动配置入口

当前启动目标记录在：

```text
Funkin/chain.json
```

其中 `preferredMode` 支持以下值：

| 值 | 启动目标 |
| --- | --- |
| `novaflare` | NovaFlare Engine |
| `origin` | OriginFunkin |
| `codename` | CodeName Engine |
| `auto` | 优先尝试 OriginFunkin；资源不可用时回到 NovaFlare Engine |

建议通过游戏内的引擎选择界面修改，不建议在程序运行时手动编辑 `chain.json`。


## Origin 编辑器与测试功能

Windows 桌面构建默认开启谱面、舞台、摄像机、动画编辑器及结算测试。进入 Origin 主菜单后按反引号键（通常与 `~` 同键）打开测试菜单，按 `F2` 打开 Flixel 调试器。运行日志位于程序旁的 `logs/`。

编译使用 `lime test windows`，编辑器布局默认从 `export/release/windows/bin/Funkin/OriginFunkin/assets` 读取，需要同时保留上游的 `ui/editors/` 和 `exclude/ui/editors/` 目录。若编译时的资源位于其他目录，使用 `lime test windows -DORIGIN_ASSETS_PATH=C:/path/to/assets`。这只指定编译时的布局来源；运行时仍按上述目录放置完整外置资源。

从源码编译前，在仓库根目录运行 `./tools/setup-hxcpp-callback-handoff.ps1`，安装已核实的 hxcpp 原生回调线程交接修补；随后用相同命令加 `-VerifyOnly` 检查。脚本备份原文件并拒绝未知版本；重新安装 hxcpp 后需要再次检查。只运行发行包的玩家无需执行此开发步骤。

如果需要单独构建 Tracy 性能采样版，还要运行 `./tools/setup-hxcpp-tracy-on-demand.ps1` 并加 `-VerifyOnly` 检查，随后重新编译；普通发行包用户无需执行。切换普通版和 Tracy 版需要全量重建原生对象，具体步骤见 `docs/upstream-migration.md`，不要清空包含外置资源的输出目录。

只需编译源码、暂未安装完整资源时，可以运行 `./tools/setup-origin-editor-layouts.ps1`，再用 `lime build windows -DORIGIN_ASSETS_PATH=D:/path/to/repository/_build/origin-editor-build-assets`。此开发脚本只下载并校验固定提交的95份编辑器 XML/CSS，供编译宏使用。运行游戏仍需按前文放置完整外置资源。

编译完成并关闭本轮游戏窗口后，也可以从运行目录直接启动测试入口，例如：

```powershell
Set-Location export/release/windows/bin
& '.\NovaFlare Engine.exe' '--origin-test=chart'
```

将 `chart` 换为 `menu`（调试菜单）、`main`（主菜单）、`mods`（Mod Menu）、`camera`（摄像机）、`stage`（舞台）、`animation`（动画）、`results`（结算参数菜单）、`result-screen`（默认结算画面）、`play`（Bopeebo 练习与自动演奏）或 `input`（主菜单与键盘诊断日志）。`play` 不计成绩。启用调试功能时，显式测试参数仅为本次进程选择 Origin，不改变 `chain.json` 中的启动偏好。`attract` 可测试真实标题视频；`native-video` 执行较长的视频、音频与销毁回归，以最终 `CHECKS PASSED` 日志判定完成。重新编译前请关闭游戏，避免 Windows 锁住正在使用的 DLL。

## 常见错误

- 错误：`Funkin/OriginFunkin/gameplay/`

  正确：`Funkin/OriginFunkin/assets/gameplay/`

- 错误：`Funkin/OriginFunkin/assets/funkin.assets-0b28106619ecf017af57c54dfde8653350b66128/gameplay/` 或 `assets/assets/gameplay/`。

  正确：`Funkin/OriginFunkin/assets/gameplay/`，`ui` 和 `exclude` 与 `gameplay` 同级。

- 错误：`Funkin/OriginFunkin/assets/mods-vslice/`

  正确：`Funkin/OriginFunkin/mods-vslice/`

- 错误：`Funkin/CodeName/assets/mods-codename/`

  正确：`Funkin/CodeName/mods-codename/`

- 错误：把 OriginFunkin 和 CodeName 的资源混在同一个 `assets` 中。

  正确：两个引擎各自使用自己的 `assets`。

> 编译模组支持仍在实验中：普通 Windows 构建不会自动启用 CPPIA。单独的 `Project-OriginCPPIA.xml` 构建依赖经过适配的 hxcpp 和 Polymod；目前只验证了有限的模组加载和启动，不能保证所有 0.9 模组或 modchart 正常运行。

开发者可在实验性 CPPIA 构建前运行 `tools/check-origin-cppia-dependencies.ps1 -PolymodRoot <Polymod目录> -HxcppRoot <hxcpp目录>`。它只读取文件并核对已验证本机补丁组合的指纹，不会安装或覆盖依赖；不同版本或额外更改会被报告，不能据此认定依赖损坏。各层安装器依赖精确的上一层，叠加后旧层的单独 Verify 可能不再适用；回滚必须按相反顺序并保留各层备份。当前重新安装整套依赖的流程尚未完成端到端验证。

Windows 开发构建可用 `./tools/build-origin-cppia-windows.ps1` 启用实验性 CPPIA；使用 `-CheckOnly` 只检查当前选中的依赖组合。构建脚本使用 `Project-OriginCPPIA.xml` 和普通 Windows 输出目录，单线程编译，并在可用物理内存低于 200 MiB 时终止该次构建进程树。`-CheckOnly` 和完整构建已在当前 Windows 环境检查；低内存终止路径尚未单独验证。
