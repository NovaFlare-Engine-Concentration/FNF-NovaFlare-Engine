# Origin 模组测试样本和发布链接

这些记录来自 NovaFlare 的 Origin 侧历史 Windows 构建。表中的目标版本来自模组发布说明或测试样本标签，API 是模组包内声明的版本。发布页可能默认展示较新的文件，有文件编号时可以用它定位当时的样本。更多运行记录见 [Origin 模组兼容记录](origin-mod-compatibility.md)。

## 游玩测试

| 模组与发布页 | 测试包对应版本 | 运行结果 |
| --- | --- | --- |
| [Yippie V-Slice 0.3.X Port](https://gamebanana.com/mods/511184) | Origin 0.3.2 样本，API `0.1.0`，[文件 1186571](https://gamebanana.com/dl/1186571) | `Yipe` 整曲到结算，缺失的音符样式和伴奏走了回退。 |
| [VS. Tord – V-Slice Port](https://gamebanana.com/mods/511442) | Origin 0.3.2 样本，API `0.1.0`，[文件 1186977](https://gamebanana.com/dl/1186977) | `Norway` 整曲到结算，缺失的音符样式和伴奏走了回退。 |
| [The Devil’s Swing V-Slice](https://gamebanana.com/mods/419740) | Origin 0.4.1 包为 API `0.1.0`，0.5.x 包为 API `0.5.0` | 两包的 `Insanity` 都跑到结算，缺失的 `default` 音符样式回退到 `funkin`。 |
| [Pico (Chill Mix)](https://gamebanana.com/mods/569584) | Origin 0.5.1、0.5.3 两包，均声明 API `0.5.0` | 两包都跑到结算，复测检查了旧 Philly Erect 舞台灯光。 |
| [Alien Hominid Revival V-Slice](https://gamebanana.com/mods/551680) | [0.5.0–0.5.3 包](https://gamebanana.com/dl/1415824)、[0.6.0–0.6.2 包](https://gamebanana.com/dl/1415823)、[0.6.3 包](https://gamebanana.com/dl/1431108)。前两包均声明 API `0.5.0` | 前两包的 `Eradication` 跑到结算，0.6.3 包用于短测和箭头对照。0.5.x 包另测了死亡循环和重试。 |
| [My Streets V-Slice Port](https://gamebanana.com/mods/581159) | 模组 1.1.0，API `0.6.3`，[文件 1439314](https://gamebanana.com/dl/1439314) | Normal 整曲到结算，另测了舞台事件和特殊音符。 |
| [Vs. Beepie BF Lover – VSlice](https://gamebanana.com/mods/626644) | API `0.8.0`，[文件 1613641](https://gamebanana.com/dl/1613641) | `Polkka` Hard 整曲到结算，用户手动确认后看到返回。另测了 `Its-okay`。 |
| [Playable KB](https://gamebanana.com/mods/679062) | API `0.8.4`，[文件 1712578](https://gamebanana.com/dl/1712578) | 使用隔离测试副本完成 `Blammed KB` Hard 并进入结算，另测了角色切换。 |
| [Silly-Billy V-slise Port REBORN](https://gamebanana.com/mods/695361) | 本地样本目录 `YOURSELF`，模组 1.0.0，API `0.8.4`，具体下载项未确认 | 整曲到结算，另测了 Mod Menu 的键盘启停、排序、保存和热重载。原作发布页为 [Hit Single](https://gamebanana.com/mods/395039)。 |
| [Mindless Retake V-Slice Port](https://gamebanana.com/mods/711995) | Origin 0.8.5 样本，[文件 1802797](https://gamebanana.com/dl/1802797) | 整曲到结算，后续实测用引擎解码原包 ASTC 纹理，隔离环境仍补了模组缺失的设置。 |
| [Vs Impostor Scripts – V-Slice Port](https://gamebanana.com/mods/720817) | 模组 1.0.3，API `0.8.8`，[Gameplay Scripts 文件 1879550](https://gamebanana.com/dl/1879550) | 用模组的音符样式跑完原版 `Bopeebo` 并返回 Freeplay。原作发布页为 [VS IMPOSTOR: LEGACY](https://gamebanana.com/mods/55652)。 |

整曲测试主要采用练习模式和自动演奏。到达结算只覆盖表中指定曲目和当时的构建，手动计分、结算退出和其他曲目按各条记录为准。

## 局部功能和 0.9.0 预览专项

| 模组与发布页 | 测试包对应版本 | 测试内容 |
| --- | --- | --- |
| [Azzy’s BF Reskin & Others](https://gamebanana.com/mods/557592) | Origin 0.5.3 包 | 与 Devil’s Swing 组合短测。隔离覆盖层调整歌曲的玩家 ID 后，验证角色加载与歌曲开始。 |
| [Character Select GF & Nene ingame](https://gamebanana.com/mods/542560) | Origin 0.5.0，API `0.5.0`，[文件 1281225](https://gamebanana.com/dl/1281225) | 验证两套角色选择图集的旧路径解析。 |
| [Your Idol Chart（PC）](https://gamebanana.com/mods/617732) | 模组 1.2.0，API `0.7.3`。组合使用 [Stage Changer+ 1.1.0](https://gamebanana.com/mods/587120)（API `0.6.3`）和 [Extra Events 1.2.0](https://gamebanana.com/tools/19459)（API `0.7.3`） | 原包出现重复类名。在隔离副本修正后运行约 45 秒，看到歌曲开始和角色切换。 |
| [WeekEnd1 Pico Freeplay BG](https://gamebanana.com/mods/607150) | 0.9 Preview 3 测试包，API `0.9.0` | 确认原 ZIP 能读取，并在真实 Freeplay 加载 Pico 背景。 |
| [Accurate Week Order](https://gamebanana.com/mods/617450) | 2.0.4 预览包，API `0.9.0`，[文件 1849208](https://gamebanana.com/dl/1849208) | 起到主菜单，核对五项关卡数据已覆盖。故事菜单的实际排序未验收。 |
| [Hex V3](https://gamebanana.com/mods/44225) | API `0.9.0`，[作者源码快照 `c9c344d`](https://github.com/Kade-github/Hex-V3/tree/c9c344d341d03e537f019775978f8ec9f440c733) | 验证两套音符样式和原始地雷脚本子集。完整发行包和原始歌曲未运行。 |
| [Mod Engine / Modchart Engine](https://gamebanana.com/mods/725611) | 1.0.3、1.1.0；1.0.3 原记录为[文件 1845599](https://gamebanana.com/dl/1845599) | 实验性 CPPIA 构建加载后短跑 Tutorial。未运行框架的专用谱面。 |
