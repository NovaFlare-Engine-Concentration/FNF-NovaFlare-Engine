# 音符着色体系：RGB Note / Legacy Note

引擎里两代音符贴图用两套互不兼容的着色方式，选错了就是花屏。这份文档说明怎么判定、怎么覆盖、以及 HSV 调色板在哪改。

## 两代贴图

| 体系 | 代表版本 | 贴图长什么样 | 着色 |
|---|---|---|---|
| `rgb` | Psych 0.7 之后（1.0 / 1.1）、本引擎默认皮肤 | 箭头只含**纯 R/G/B 三通道掩码**，自身没有颜色 | `general.shaders.RGBPalette`，颜色来自 `ClientPrefs.arrowRGB / arrowRGBPixel` |
| `legacy` | Psych 0.6.x 及更早、多数手绘 mod 皮肤 | 箭头颜色**已经烤进贴图** | `general.shaders.ColorSwap`（HSV 偏移），参数是 `ClientPrefs.arrowHSV` |

拿错体系的后果：

- RGB 打 legacy 贴图 → 通道被重映射，颜色完全走样；
- HSV 打 RGB 掩码 → 掩码本身就是纯红/纯绿/纯蓝，色相偏移基本等于原图（而且还白搭一个 shader）。

本仓库自带皮肤的实测结果（`purple0` 帧采样）：

| 皮肤 | 纯通道像素占比 | 判定 |
|---|---|---|
| `noteSkins/NOTE_assets` | 96.6% | `rgb` |
| `noteSkins/NOTE_assets-chip` | 97.6% | `rgb` |
| `noteSkins/NOTE_assets-future` | 95.8% | `rgb` |
| `noteSkins/NOTE_assets-Classic` | 0%（白 5.4%） | `legacy` |
| `noteSkins/NOTE_assets-Stepmania` | 0%（白 28.1%） | `legacy` |

## 自动甄别（`general.backend.NoteSkinStyle`）

判定一次、按皮肤路径缓存。判据是**音符帧的像素构成**（`purple0 → blue0 → green0 → red0`，取不到才退 `arrowLEFT`）：

- RGB 掩码贴图的纯通道像素（一通道 >200、另两通道 <60）占 86%～97%；
- 0.6.x 时代的烤色贴图只有 0%～11%；
- 阈值取 35%，两头余量都很足。纯白箭头（白 ≥60%）也判 `rgb` —— HSV 对白色无效，按 RGB 才能被调色板染色。

采样用的是**音符帧而不是静态箭头**：`arrowLEFT` 在两代皮肤里都是灰的，拿它采样会把所有 RGB 皮肤判成 legacy（踩过）。

像素皮肤（`images/pixelUI/noteSkins/…`）不参与自动甄别：它是 4×5 方格图集、没有 xml，引擎一直按 RGB 处理，需要改就写 json。

> 实现细节：优先读已经载入的贴图（`Paths.image(skin, null, false)`，CPU 像素还在）。被 GPU Caching 摘掉 CPU 像素时（`bitmap.readable == false`）再从磁盘临时解一份 —— 对不可读的 BitmapData 调 `getPixel32` 会**静默返回 0**，那样会把每张 RGB 皮肤都判成 legacy。

## 皮肤自己声明

皮肤贴图旁边放一份同名 json 即可，推荐写法：

```json
{ "noteStyle": "legacy" }
```

`images/noteSkins/FOO.json` 对 `images/noteSkins/FOO.png` 生效。三种写法都认：

```json
{ "noteStyle": "rgb" | "legacy" }
{ "legacy": true }
{ "rgb": false }
```

优先级（`games.objects.Note.getNoteStyle()`）：

```
Note System = new   （强制新版）
Note System = legacy（强制旧版）
  > 皮肤 json 声明
  > 谱面 disableNoteRGB
  > 自动甄别
  > 默认 rgb
```

`Note System` 是 `auto / legacy / new` 三态（`ClientPrefs.noteSystem`），前两态直接短路整条判定链；`auto` 才往下走。

## Shader 槽位生命周期（模组兼容）

一个 sprite 只有一个 shader 槽位（openfl `DisplayObject.shader` 的固有设计），模组（Lua `setSpriteShader` / HScript）会和引擎抢这个槽。规则向老引擎对齐：**生成时挂好，之后引擎不再动**，模组中途换 shader 是模组自己的事：

| 体系 | 音符 | 轨道（StrumNote） |
|---|---|---|
| RGB（new / auto 判 RGB） | 构造时挂 RGBPalette，一直不动（0.7+ 行为） | 沿用 0.7 行为：`static` 摘下、`confirm/press` 挂回（灰色静态帧不能被染色，只能拔插） |
| legacy（legacy / auto 判 legacy） | HSV 只在生成时挂一次（0.6.x 行为），全 0 不挂，之后 `reloadNote` 不再碰槽位 | HSV 只在生成时挂一次，之后 `playAnim` 不再碰槽位 —— 模组的 strum shader（如 Pibby 的 glitch）从此常驻 |
| auto + 谱面 `disableNoteRGB` | RGB、HSV 都不挂，贴图原样 | 同左 |

代表案例：Pibby Apocalypse 在 `onCreatePost` 给对手轨道挂一次 `NewGlitch2`，之后只调 uniform —— legacy 分支下引擎永不抢槽，glitch 效果全程存活。RGB 分支（玩家强制 new 或 RGB 皮肤）下 confirm 会把槽位要回来，那是 0.7 的固有语义，模组自己兼容。

音符的拍板标志是 `Note.shaderDecided`：构造时那次 `reloadNote` 决定之后，换贴图触发的后续 `reloadNote` 只换贴图换动画。

谱面声明排在皮肤 json 之后：谱面的 `disableNoteRGB` 只是"这张谱配的是旧版皮肤"的代理，皮肤作者明确写了 json 就以 json 为准。自动甄别排在谱面之后，是为了尊重谱面的显式声明（哪怕甄别不出来）。

## 玩家侧开关（Skin 设置页）

**音符和溅射是两个独立的三态开关**（`noteSystem` / `splashSystem`），各自把"用谁的皮肤"和"用哪个着色器"合并成一个选项：

| 值 | 音符 | 溅射 |
|---|---|---|
| `auto` | 谱面 `arrowSkin` 优先，着色自动判 | 谱面 `splashSkin` 优先，着色自动判 |
| `legacy` | 三级回退（见下），**强制 HSV** | 三级回退（见下），**强制 HSV** |
| `new` | **忽略谱面 `arrowSkin`**（改用玩家皮肤），**强制 RGB** | **忽略谱面 `splashSkin`**（改用玩家皮肤），**强制 RGB** |

旧版整包（谱面自带烤色 `arrowSkin`）想换成新版观感就设 `new`；反过来谱面是 RGB 但想用 HSV 观感就设 `legacy`。

这两个选项取代了原来的 `noteRGB` + `noteColorSwap` + `splashRGB` 三个开关。老存档会在 `ClientPrefs.loadPrefs()` 里自动迁移：`noteColorSwap = true` 或 `noteRGB = false` → `noteSystem = legacy`，`splashRGB = false` → `splashSystem = legacy`；迁移只在存档里还没有新键时执行，不会覆盖用户后来选的 `auto`。

### legacy 的三级回退

引擎自带的旧版资源**放在 `images/` 根目录**，不在 `noteSkins/` / `noteSplashes/` 里：

| 级别 | 音符 | 溅射 |
|---|---|---|
| 1 | 谱面 `arrowSkin`（文件存在才算） | 谱面 `splashSkin` / note type 指定（文件存在才算） |
| 2 | `images/NOTE_assets.png` | `images/noteSplashes.png` |
| 3 | 默认（RGB）皮肤 + 玩家后缀 → **按 RGB 着色** | 默认（RGB）splash + 玩家后缀 → **按 RGB 着色** |

第 3 级只是兜底：跑到这一级说明连引擎自带旧版资源都没有，此时贴图是 RGB 掩码，再套 HSV 就是花屏，所以着色自动回落到 RGB。

判定"是不是落在第 3 级"用的是路径前缀（`noteSkins/NOTE_assets` / `noteSplashes/noteSplashes`），而不是像素甄别 —— 回退链本身是确定性的，不需要再猜。

皮肤解析结果按 `texture::postfix::noteSystem` 缓存（`Note.getLoadDataKey()`），否则切换三态后会读到上一个模式的缓存。

> 旧版 splash 图集如果没有配套的 `.txt`，动画前缀按 `note splash <颜色> <序号>` 自动推断，fps 用 22/26、偏移用 0；位置不对就往 `images/noteSplashes.txt` 补偏移。

## HSV 调色板

`Skin → Legacy Color Setup`（`options.base.NotesHSVSubState`）。

- 每轨 `hue(-180~180) / saturation(-100~100) / brightness(-100~100)`，存在 `ClientPrefs.arrowHSV`（**16 轨**，覆盖到本引擎 10 键上限还有余量；轨道号越界由 `NoteHSV` 取模归一）；
- 换算进 shader 时是 `/360`、`/100`、`/100`（沿用 0.6.3）；
- **全 0 = 不挂 shader**，所以 legacy 皮肤默认就等于美术原图，不白付着色器开销；
- 编辑器里的预览**固定用 `images/NOTE_assets.png` 的音符帧**（`purple0` / `blue0` …），不是轨道上的 `arrowLEFT` 静态帧 —— 那个在两代皮肤里都是灰的，调 HSV 看不出变化；
- 同轨的 note / strum / splash 共享一份 `ColorSwap`（`general.shaders.NoteHSV`），
  和 `Note.globalRgbShaders` 一个思路：一场 16K 谱几百个 Shader 实例没必要。

操作：上下选轨、左右选通道、`ACCEPT` 进入微调（长按加速、`SHIFT` 步进 10）、`RESET` 归零（按住 `SHIFT` 归零整轨）。鼠标点击直接选中格子（再点已选中的格子进出微调），悬停会高亮可点目标，滚轮微调。选中反馈分两档：单纯选中时选中行亮、其它行压暗；进入微调（含键盘直输）后整个格子区域压暗、只留当前格以强调色单独亮 —— 标题 / 描述 / 提示文字永远不压。每页 4 行，16 轨分 4 页。

> 16 轨是存档格式的一部分：老存档只有 4 项，`ClientPrefs.normalizeNoteSystems()` 会补齐到 16 项（前 4 项保留、其余归零），并重建新数组避免和 `defaultData` 共享引用。

## 相关代码

- `general/backend/NoteSkinStyle.hx` —— 判定 + 缓存 + 三态取值
- `general/shaders/NoteHSV.hx` —— 每轨共享的 HSV 调色板
- `games/objects/Note.hx` —— `noteStyle` / `useRGBShader` / `updateNoteShader()` / `getNoteStyle()` / 三级回退在 `reloadPath()`
- `games/objects/StrumNote.hx` —— 同一套判据，`playAnim()` 里分支；`new(..., ?forceSkin)` 供编辑器预览
- `games/objects/NoteSplash.hx` —— `resolveSplashTexture()` / `allowRGBShader()`，RGB 与 HSV 二选一
- `options/base/NotesHSVSubState.hx` —— HSV 调色板编辑器
