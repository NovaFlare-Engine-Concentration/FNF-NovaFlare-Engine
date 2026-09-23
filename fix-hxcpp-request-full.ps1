<#
  给本地 hxcpp 补上 GCManager.requestFull() 所需的 __hxcpp_gc_request_full。

  ── 为什么需要这个脚本 ──────────────────────────────────────────────
  source/general/backend/gc/GCManager.hx 用 @:native 声明了一批 NovaGC 原生符号，
  其中实际被调用的是 5 个：
    __hxcpp_enable              (Main / PlayState / LoadingState)   -> 存在
    __hxcpp_gc_enter_gameplay   (GameplayGC)                        -> 存在
    __hxcpp_gc_leave_gameplay   (GameplayGC)                        -> 存在
    __hxcpp_gc_is_gameplay_mode (GameplayGC)                        -> 存在
    __hxcpp_gc_request_full     (Paths.hx:138)                      -> 缺失 ★
  缺这一个会让链接前的编译直接失败：
    src/general/backend/Paths.cpp(423): error C3861:
      "__hxcpp_gc_request_full": 找不到标识符
  于是整个 Windows/Android 构建都出不来。

  上游仓库 NovaFlare-Engine-haxelib/hxcpp-novagc 的 HEAD 就是本地那份
  3bc17aa（只有 "Initial NovaGC precise hxcpp runtime" 一个提交），并没有带这个
  函数的更新版本，所以只能本地补。

  ── 实现依据 ────────────────────────────────────────────────────────
  hx/GC.h 里 gPauseForCollect 的注释写得很明确：
      // If another thread wants to do a collect, it will signal this variable.
      //  0xffffffff = pause requested
  而 Immix.cpp 的 __hxcpp_gc_safe_point() 会检查它：
      if (hx::gPauseForCollect) hx::PauseForCollect();
  所以把 gPauseForCollect 置为 0xffffffff，就等于「非阻塞地排队一次 full GC」——
  与 GCManager.hx 里 requestFull 的文档完全一致
  （“Queues a concurrent full collection without making the UI thread wait.
     Repeated requests are coalesced by the native collector thread.”）：
  调用方立刻返回、不等待；重复请求自然合并成同一次收集。

  ── 使用 ────────────────────────────────────────────────────────────
  在项目根执行：  powershell -ExecutionPolicy Bypass -File .\fix-hxcpp-request-full.ps1
  脚本是幂等的，重复运行安全；但 .haxelib/ 被 .gitignore 忽略，
  重新安装 / 切换 hxcpp 之后需要再跑一次。

  若将来拿到了带该函数的官方 hxcpp，本脚本会自动跳过（检测到已存在即不改动）。
#>

$ErrorActionPreference = 'Stop'

$projectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$hxcpp       = Join-Path $projectRoot '.haxelib\hxcpp\4,3,2'
$gcHeader    = Join-Path $hxcpp 'include\hx\GC.h'
$immixSource = Join-Path $hxcpp 'src\hx\gc\Immix.cpp'

Write-Host "hxcpp root: $hxcpp"

foreach ($f in @($gcHeader, $immixSource)) {
    if (-not (Test-Path $f)) { throw "找不到文件：$f（hxcpp 路径是否变了？）" }
}

# ---------- 1) 头文件声明 ----------
$headerText = Get-Content -Path $gcHeader -Raw -Encoding UTF8
if ($headerText -match '__hxcpp_gc_request_full') {
    Write-Host "[跳过] GC.h 里已经有 __hxcpp_gc_request_full 声明"
} else {
    $anchor = 'HXCPP_EXTERN_CLASS_ATTRIBUTES void  __hxcpp_gc_safe_point();'
    if ($headerText -notmatch [regex]::Escape($anchor)) {
        throw "GC.h 里找不到锚点：$anchor"
    }
    $decl = @'
HXCPP_EXTERN_CLASS_ATTRIBUTES void  __hxcpp_gc_safe_point();
// Non-blocking request for a full collection. Signal only - the actual collect
// happens at the next safepoint / allocation slow path, so the caller (eg the
// UI thread) never waits, and repeated requests coalesce into one collection.
// Backs GCManager.requestFull() (source/general/backend/gc/GCManager.hx).
HXCPP_EXTERN_CLASS_ATTRIBUTES void  __hxcpp_gc_request_full();
'@
    $headerText = $headerText.Replace($anchor, $decl.TrimEnd("`r", "`n"))
    Set-Content -Path $gcHeader -Value $headerText -Encoding UTF8 -NoNewline
    Write-Host "[完成] 已向 GC.h 添加声明"
}

# ---------- 2) 实现 ----------
$immixText = Get-Content -Path $immixSource -Raw -Encoding UTF8
if ($immixText -match 'void\s+__hxcpp_gc_request_full\s*\(') {
    Write-Host "[跳过] Immix.cpp 里已经有 __hxcpp_gc_request_full 实现"
} else {
    $anchor = @'
void __hxcpp_gc_safe_point()
{
    if (hx::gPauseForCollect)
      hx::PauseForCollect();
}
'@
    $anchor = $anchor.TrimEnd("`r", "`n")
    if ($immixText -notmatch [regex]::Escape($anchor)) {
        throw "Immix.cpp 里找不到 __hxcpp_gc_safe_point 锚点，hxcpp 版本可能已变，请手动打补丁"
    }
    $impl = @'
void __hxcpp_gc_safe_point()
{
    if (hx::gPauseForCollect)
      hx::PauseForCollect();
}

// Non-blocking full-collection request, backing GCManager.requestFull()
// (source/general/backend/gc/GCManager.hx).
//
// 0xffffffff means "pause requested" - see the gPauseForCollect comment in
// hx/GC.h. The flag is polled both when allocating and in
// __hxcpp_gc_safe_point() above, so this returns immediately without making the
// calling (UI) thread wait, and repeated requests naturally collapse into a
// single upcoming collection.
void __hxcpp_gc_request_full()
{
   hx::gPauseForCollect = 0xffffffff;
}
'@
    $immixText = $immixText.Replace($anchor, $impl.TrimEnd("`r", "`n"))
    Set-Content -Path $immixSource -Value $immixText -Encoding UTF8 -NoNewline
    Write-Host "[完成] 已向 Immix.cpp 添加实现"
}

Write-Host ""
Write-Host "全部就绪。接着执行重建（hxcpp 的 .cpp 改了，需要重编 runtime）："
Write-Host "  haxelib run lime build windows"
