# Windows 绘制节奏回归测试

在仓库根目录安装渲染线程补丁、重建 Lime，再构建并运行测试。清空 `NOVAFLARE_UPDATE_RATE`、`NOVAFLARE_DRAW_RATE` 和 `NOVAFLARE_SPLIT_RENDER`。测试期间让窗口留在前台，避开并行构建等高负载任务。

```powershell
./tools/setup-novaflare-render-dependencies.ps1 -Component RenderThreadRepair
haxelib run lime rebuild windows -64
$env:SHOW_CONSOLE = '1'
haxelib run lime build tools/tests/render-cadence/Project.xml windows -64
& ./_build/render-cadence-test/windows/bin/NovaFlareRenderCadenceTest.exe
```

测试在更新回调中切换速率、独立绘制和 VSync。关闭 VSync 的场景核对更新与绘制速率，开启场景检查交换缓冲区等待期间更新仍达到目标速率。最后一次受控延迟会跨过两个更新截止时间，检查应用在一轮事件循环后补跑一次。测试完成时打印 `PASS render cadence` 并退出。设置 `NOVAFLARE_FRAME_TIMELINE` 为输出文件路径后，可在 `swap_interval` 行核对 SDL 读回的交换间隔。
