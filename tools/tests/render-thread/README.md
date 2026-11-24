# Windows 渲染线程回归测试

在仓库根目录安装渲染线程补丁，构建 Lime，再构建并运行测试。

```powershell
./tools/setup-novaflare-render-dependencies.ps1 -Component RenderThreadRepair
haxelib run lime rebuild windows -64
haxelib run lime build tools/tests/render-thread/Project.xml windows -64
& ./_build/render-thread-test/windows/bin/NovaFlareRenderThreadTest.exe
```

测试使用独立窗口，要求支持 OpenGL 的桌面会话。测试先在渲染线程模式下关闭垂直同步，再在主线程模式下开启。两段均覆盖主线程和渲染线程的绘制。在每种模式下上传纹理后改写原始字节，随后读取纹理和窗口缓冲区核对像素。程序以退出码 0 和 `PASS frames=15` 表示检查通过。

需要验证实际垂直同步时，可将 `NOVAFLARE_FRAME_TIMELINE` 设为新 CSV 的绝对路径再运行。时间线中的 `swap_interval` 应先记录值 `0` 和模式 `immediate`，再记录值 `1` 和模式 `vsync`。

`submit_us` 记录各次上传调用在应用线程中花费的微秒数。异步调用返回后，渲染线程继续处理提交的字节。
