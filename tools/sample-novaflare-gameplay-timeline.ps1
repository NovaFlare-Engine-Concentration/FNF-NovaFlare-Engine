[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string]$Executable,
    [Parameter(Mandatory)] [string]$RunDirectory,
    [Parameter(Mandatory)] [ValidateSet('0', '1')] [string]$RenderThread,
    [ValidateRange(1, 2000)] [int]$UpdateRate = 240,
    [ValidateRange(1, 2000)] [int]$DrawRate = 1200,
    [ValidateSet('0', '1')] [string]$SplitRender = '1',
    [string]$RenderResolution = '',
    [string]$PythonExecutable = '',
    [ValidateRange(1, 300)] [int]$StartupSeconds = 60,
    [ValidateRange(1, 1800)] [int]$SongSeconds = 135,
    [string]$PresentMonExecutable = '',
    [string]$PreferencesFile = '',
    [switch]$GcBreakdown,
    [switch]$HaxePerfTrace,
    [switch]$RenderAttachmentTrace,
    [switch]$KeepDisabledColorFilter,
    [ValidateSet('0', '1')] [string]$VSync = '0'
)

$ErrorActionPreference = 'Stop'
$analyzer = Join-Path $PSScriptRoot 'analyze-novaflare-frame-timeline.py'

function Resolve-Python([string]$requested) {
    $nativeErrorAction = $ErrorActionPreference
    try {
        $ErrorActionPreference = 'Continue'
        $probe = 'import sys; print(sys.executable) if sys.version_info >= (3, 10) else sys.exit(1)'
        if ($requested) {
            $candidates = @((Get-Command $requested -CommandType Application -ErrorAction Stop |
                Select-Object -First 1).Source)
        } else {
            $candidates = @(Get-Command python -CommandType Application -All -ErrorAction SilentlyContinue |
                Where-Object { $_.Source -notmatch '\\Microsoft\\WindowsApps\\' } |
                Select-Object -ExpandProperty Source -Unique)
        }
        foreach ($candidate in $candidates) {
            $path = & $candidate -c $probe 2>$null
            if ($LASTEXITCODE -eq 0 -and $path -and (Test-Path -LiteralPath $path -PathType Leaf)) { return $path }
        }
        if (!$requested) {
            $launcher = Get-Command py -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
            if ($launcher) {
                $path = & $launcher.Source -3 -c $probe 2>$null
                if ($LASTEXITCODE -eq 0 -and $path -and (Test-Path -LiteralPath $path -PathType Leaf)) { return $path }
            }
        }
    } finally {
        $ErrorActionPreference = $nativeErrorAction
    }
    throw 'Python 3.10 or newer is required. Pass a usable path with -PythonExecutable.'
}

$python = Resolve-Python $PythonExecutable
$sourceExe = (Resolve-Path -LiteralPath $Executable).Path
$sourceRoot = Split-Path -Parent $sourceExe
$run = [IO.Path]::GetFullPath($RunDirectory)
if ($run -eq $sourceRoot -or $run.StartsWith($sourceRoot + '\', [StringComparison]::OrdinalIgnoreCase)) {
    throw 'The capture directory must be outside the source runtime.'
}
if (Test-Path -LiteralPath $run) { throw "Capture already exists at $run" }

$preferencesSource = $null
if ($PreferencesFile) {
    $preferencesSource = Get-Item -LiteralPath $PreferencesFile
    if ($preferencesSource.PSIsContainer -or $preferencesSource.PSProvider.Name -ne 'FileSystem') {
        throw 'Pass a preferences save file with -PreferencesFile.'
    }
}

$presentMon = $null
$presentMonProcess = $null
if ($PresentMonExecutable) {
    $presentMonExe = (Get-Item -LiteralPath $PresentMonExecutable).FullName
    if ([IO.Path]::GetExtension($presentMonExe) -ne '.exe' -or $presentMonExe.StartsWith('\\')) {
        throw 'Pass a local PresentMon executable.'
    }
    $signature = Get-AuthenticodeSignature -LiteralPath $presentMonExe
    if ($signature.Status -ne 'Valid') { throw "PresentMon Authenticode status is $($signature.Status)." }
    $presentMon = [ordered]@{
        executable = $presentMonExe
        sha256 = (Get-FileHash -LiteralPath $presentMonExe).Hash
        signer = $signature.SignerCertificate.Subject
        session = 'NovaFlare-' + [Guid]::NewGuid().ToString('N')
        csv = Join-Path $run 'presentmon.csv'
        stopped = $false
    }
}

# Refuse binaries that lack the startup isolation guard before touching any saves.
$binary = [Text.Encoding]::ASCII.GetString([IO.File]::ReadAllBytes($sourceExe))
if (!$binary.Contains('--cne-isolated-storage') -or !$binary.Contains('.codex-cne-isolated-runtime')) {
    throw 'The executable does not contain the isolated storage guard.'
}
$verifyVSync = $binary.Contains('NOVAFLARE_DIAGNOSTIC_VSYNC')
if ($VSync -eq '1' -and !$verifyVSync) {
    throw 'The executable does not support the diagnostic VSync override.'
}
$binary = $null

$runtime = Join-Path $run 'runtime'
$storage = Join-Path $runtime '.isolated-saves/level-a/level-b/level-c'
$mods = Join-Path $runtime 'mods'
$crashes = Join-Path $run 'native-crash'
New-Item -ItemType Directory -Path $runtime, $storage, $mods, $crashes | Out-Null
New-Item -ItemType File -Path (Join-Path $runtime '.codex-cne-isolated-runtime') | Out-Null
New-Item -ItemType File -Path (Join-Path $runtime 'modsList.txt') | Out-Null
foreach ($entry in (Get-ChildItem -LiteralPath $sourceRoot -File)) {
    if ($entry.Name -ne 'modsList.txt') { Copy-Item -LiteralPath $entry.FullName -Destination $runtime }
}
foreach ($directory in @('assets', 'manifest', 'plugins')) {
    $target = Join-Path $sourceRoot $directory
    if (Test-Path -LiteralPath $target -PathType Container) {
        New-Item -ItemType Junction -Path (Join-Path $runtime $directory) -Target $target | Out-Null
    }
}

$preferences = $null
if ($preferencesSource) {
    $saveDirectory = Join-Path $runtime '.isolated-saves/NF-crew/NovaFlare-Engine'
    New-Item -ItemType Directory -Path $saveDirectory | Out-Null
    $seededSave = Join-Path $saveDirectory 'funkin.sol'
    Copy-Item -LiteralPath $preferencesSource.FullName -Destination $seededSave
    $preferences = [ordered]@{
        source = $preferencesSource.FullName
        source_sha256 = (Get-FileHash -LiteralPath $seededSave).Hash
        seeded_save = $seededSave
    }
}

$stdout = Join-Path $run 'stdout.log'
$stderr = Join-Path $run 'stderr.log'
$childEnv = [ordered]@{
    NOVAFLARE_DIAGNOSTIC_SONG = 'milf'
    NOVAFLARE_DIAGNOSTIC_DIFFICULTY = '2'
    NOVAFLARE_DIAGNOSTIC_MOD = $null
    NOVAFLARE_DIAGNOSTIC_BOTPLAY = '1'
    NOVAFLARE_DIAGNOSTIC_VSYNC = $VSync
    NOVAFLARE_FRAME_TIMELINE = (Join-Path $run 'frame-timeline.csv')
    NOVAFLARE_GC_PAUSE_TIMELINE = (Join-Path $run 'gc-pauses-qpc.csv')
    NOVAFLARE_GC_BREAKDOWN = $(if ($GcBreakdown) { '1' } else { $null })
    NOVAFLARE_RENDER_ATTACHMENT_TRACE = $(if ($RenderAttachmentTrace) { '1' } else { $null })
    NOVAFLARE_KEEP_DISABLED_COLOR_FILTER = $(if ($KeepDisabledColorFilter) { '1' } else { $null })
    NOVAFLARE_DIAGNOSTIC_DIR = $run
    NOVAFLARE_NATIVE_DUMP_DIR = $crashes
    NOVAGC_PERF_TRACE = $(if ($HaxePerfTrace) { '1' } else { $null })
    NOVAFLARE_RENDER_THREAD = $RenderThread
    NOVAFLARE_UPDATE_RATE = [string]$UpdateRate
    NOVAFLARE_DRAW_RATE = [string]$DrawRate
    NOVAFLARE_SPLIT_RENDER = $SplitRender
    NOVAFLARE_RENDER_RESOLUTION = $(if ($RenderResolution) { $RenderResolution } else { $null })
    HXCPP_NOVAGC_TELEMETRY = $null
    HXCPP_NOVAGC_CSV_LOG = $null
    HXCPP_NOVAGC_JSON_LOG = $null
    HXCPP_NOVAGC_DIAGNOSTIC_LOG = $null
    HXCPP_NOVAGC_TYPE_TELEMETRY = $null
}

function Start-CaptureMonitor([string]$name, [string]$interval) {
    $script = Join-Path $PSScriptRoot "monitor-novaflare-$name.ps1"
    $duration = $StartupSeconds + $SongSeconds + 15
    $arguments = "-NoProfile -NonInteractive -ExecutionPolicy Bypass -File `"$script`" " +
        "-TargetProcessId $($game.Id) -RunDirectory `"$run`" -MaximumSeconds $duration $interval"
    $process = Start-Process powershell.exe -ArgumentList $arguments -WindowStyle Hidden -PassThru `
        -RedirectStandardOutput (Join-Path $run "$name-monitor.stdout.log") `
        -RedirectStandardError (Join-Path $run "$name-monitor.stderr.log")
    $null = $process.Handle
    return $process
}

function Start-PresentMonCommand([string]$arguments, [string]$logName) {
    $process = Start-Process -FilePath $presentMon.executable -ArgumentList $arguments -WindowStyle Hidden -PassThru `
        -RedirectStandardOutput (Join-Path $run "$logName.stdout.log") `
        -RedirectStandardError (Join-Path $run "$logName.stderr.log")
    $null = $process.Handle
    return $process
}

function Wait-PresentMonChild([Diagnostics.Process]$child, [string]$label) {
    if ($child.WaitForExit(4000)) { return $true }
    $presentMon["${label}_timed_out"] = $true
    try {
        $child.Kill()
        $presentMon["${label}_force_terminated"] = $true
    } catch [InvalidOperationException] {
        if (!$child.HasExited) { throw }
    }
    return $child.WaitForExit(2000)
}

function Get-PresentMonSessionState([string]$label) {
    $logman = Join-Path $env:SystemRoot 'System32/logman.exe'
    $query = Start-Process -FilePath $logman -ArgumentList "query $($presentMon.session) -ets" -WindowStyle Hidden -PassThru `
        -RedirectStandardOutput (Join-Path $run "presentmon-$label.stdout.log") `
        -RedirectStandardError (Join-Path $run "presentmon-$label.stderr.log")
    $null = $query.Handle
    if (Wait-PresentMonChild $query $label) {
        $presentMon["${label}_exit_code"] = $query.ExitCode
        if ($query.ExitCode -eq 0) { return 'active' }
        # PLA_E_DCS_NOT_FOUND is the expected result for a removed session.
        if ($query.ExitCode -eq -2144337918) { return 'absent' }
    }
    return 'unknown'
}

function Stop-PresentMonSession([string]$label) {
    $arguments = "--session_name $($presentMon.session) --terminate_existing_session"
    $presentMon["${label}_command"] = '"{0}" {1}' -f $presentMon.executable, $arguments
    $stop = Start-PresentMonCommand $arguments "presentmon-$label"
    if (Wait-PresentMonChild $stop "${label}_helper") { $presentMon["${label}_exit_code"] = $stop.ExitCode }
}

function Complete-PresentMonCapture([Diagnostics.Process]$collector, [bool]$abnormal) {
    if ($collector) {
        try {
            if (!$collector.WaitForExit(2500)) {
                $abnormal = $true
                $presentMon['session_before_stop'] = Get-PresentMonSessionState 'session_before_stop'
                if ($presentMon.session_before_stop -eq 'active') { Stop-PresentMonSession 'stop' }
            }
        } catch { $presentMon['stop_error'] = $_.Exception.Message; $abnormal = $true }

        try {
            $presentMon['stopped'] = Wait-PresentMonChild $collector 'collector'
            if ($presentMon.stopped) { $presentMon['exit_code'] = $collector.ExitCode }
        } catch { $presentMon['collector_cleanup_error'] = $_.Exception.Message }
    }

    if (!$abnormal -and $presentMon.stopped -and $presentMon.exit_code -eq 0 -and !$presentMon.collector_timed_out) { return }
    $presentMon['session_after_cleanup'] = 'unknown'
    try {
        $presentMon['session_after_cleanup'] = Get-PresentMonSessionState 'session_after_stop'
        if ($presentMon.session_after_cleanup -eq 'active') {
            try { Stop-PresentMonSession 'retry_stop' }
            catch { $presentMon['retry_stop_error'] = $_.Exception.Message }
            $presentMon['session_after_cleanup'] = 'unknown'
            $presentMon['session_after_cleanup'] = Get-PresentMonSessionState 'session_after_retry'
        }
    } catch { $presentMon['session_query_error'] = $_.Exception.Message }
}

function Set-CaptureEnvironment([string]$name, $value) {
    if ($null -eq $value) {
        Remove-Item -LiteralPath "Env:$name" -ErrorAction SilentlyContinue
    } else {
        [Environment]::SetEnvironmentVariable($name, $value, 'Process')
    }
}

$game = $null
$gameOutput = $null
$startTick = $null
$stopTick = $null
$finishTick = $null
$closeRequested = $null
$forced = $false
$status = 'runner_error'
$frequency = [Diagnostics.Stopwatch]::Frequency
$monitors = [ordered]@{}
$monitorResults = [ordered]@{}
$recordedEnv = @{}
$manifestPath = Join-Path $run 'capture.json'
$startGeometry = $null
$captureError = $null
$cleanupError = $null

if (-not ('NovaFlareCaptureWindow' -as [type])) {
    Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;

public static class NovaFlareCaptureWindow {
    [StructLayout(LayoutKind.Sequential)]
    private struct Rect { public int Left, Top, Right, Bottom; }
    [DllImport("user32.dll")] private static extern bool GetClientRect(IntPtr window, out Rect rect);
    [DllImport("user32.dll")] private static extern uint GetDpiForWindow(IntPtr window);
    [DllImport("user32.dll")] private static extern IntPtr SetThreadDpiAwarenessContext(IntPtr context);

    public static int[] Read(IntPtr window) {
        if (window == IntPtr.Zero) return null;
        IntPtr previous = IntPtr.Zero;
        try {
            previous = SetThreadDpiAwarenessContext(new IntPtr(-4));
            Rect rect;
            if (previous == IntPtr.Zero || !GetClientRect(window, out rect)) return null;
            return new int[] { rect.Right - rect.Left, rect.Bottom - rect.Top, (int)GetDpiForWindow(window) };
        } catch (EntryPointNotFoundException) {
            return null;
        } finally {
            if (previous != IntPtr.Zero) SetThreadDpiAwarenessContext(previous);
        }
    }
}
'@
}

if (-not ('NovaFlareCaptureOutput' -as [type])) {
    Add-Type -TypeDefinition @'
using System;
using System.Diagnostics;
using System.IO;
using System.Text;
using System.Text.RegularExpressions;
using System.Threading;
using System.Threading.Tasks;

public sealed class NovaFlareCaptureOutput {
    private static readonly Regex Boundary = new Regex(@"^perf:song_(start|finish)_qpc=([0-9]+)");
    private readonly MemoryStream stdout = new MemoryStream();
    private readonly MemoryStream stderr = new MemoryStream();
    private readonly Task drain;
    private readonly byte[] linePrefix = new byte[64];
    private int prefixLength;
    private long songStart;
    private long songFinish;

    public NovaFlareCaptureOutput(Process process) {
        Stream stdoutPipe = process.StandardOutput.BaseStream;
        Stream stderrPipe = process.StandardError.BaseStream;
        drain = Task.WhenAll(
            Task.Run(() => ReadPipe(stdoutPipe, stdout, true)),
            Task.Run(() => ReadPipe(stderrPipe, stderr, false)));
    }

    public long SongStart { get { return Interlocked.Read(ref songStart); } }
    public long SongFinish { get { return Interlocked.Read(ref songFinish); } }

    private async Task ReadPipe(Stream pipe, MemoryStream log, bool findBoundaries) {
        byte[] block = new byte[64 * 1024];
        int length;
        while ((length = await pipe.ReadAsync(block, 0, block.Length).ConfigureAwait(false)) != 0) {
            lock (log) log.Write(block, 0, length);
            if (findBoundaries && (SongStart == 0 || SongFinish == 0)) {
                for (int index = 0; index < length; index++) {
                    byte value = block[index];
                    if (value == '\n') ReadBoundary();
                    else if (prefixLength < linePrefix.Length) linePrefix[prefixLength++] = value;
                }
            }
        }
        if (findBoundaries) ReadBoundary();
    }

    private void ReadBoundary() {
        if (prefixLength > 0 && (linePrefix[0] == 'p' || linePrefix[0] == 0xef)) {
            Match match = Boundary.Match(Encoding.UTF8.GetString(linePrefix, 0, prefixLength).TrimStart('\ufeff'));
            long tick;
            if (match.Success && long.TryParse(match.Groups[2].Value, out tick)) {
                if (match.Groups[1].Value == "start") Interlocked.CompareExchange(ref songStart, tick, 0);
                else Interlocked.CompareExchange(ref songFinish, tick, 0);
            }
        }
        prefixLength = 0;
    }

    public void WaitForDrain() {
        if (!drain.Wait(5000)) throw new TimeoutException("Game output pipes did not close after exit.");
    }

    public void SaveLogs(string stdoutPath, string stderrPath) {
        try { WaitForDrain(); }
        finally {
            SaveLog(stdoutPath, stdout);
            SaveLog(stderrPath, stderr);
        }
    }

    private static void SaveLog(string path, MemoryStream log) {
        byte[] bytes;
        lock (log) bytes = log.ToArray();
        File.WriteAllBytes(path, bytes);
    }
}
'@
}

try {
    foreach ($name in $childEnv.Keys) {
        $recordedEnv[$name] = [Environment]::GetEnvironmentVariable($name, 'Process')
        Set-CaptureEnvironment $name $childEnv[$name]
    }
    $launchTick = [Diagnostics.Stopwatch]::GetTimestamp()
    $launchUtc = [DateTime]::UtcNow.ToString('o')
    $exe = Join-Path $runtime (Split-Path -Leaf $sourceExe)
    $launchInfo = [Diagnostics.ProcessStartInfo]::new()
    $launchInfo.FileName = $exe
    $launchInfo.WorkingDirectory = $runtime
    $launchInfo.Arguments = '--cne-isolated-storage'
    $launchInfo.UseShellExecute = $false
    $launchInfo.RedirectStandardOutput = $true
    $launchInfo.RedirectStandardError = $true
    $game = [Diagnostics.Process]::Start($launchInfo)
    $gameOutput = [NovaFlareCaptureOutput]::new($game)
    $null = $game.Handle
    if ($presentMon) {
        $duration = $StartupSeconds + $SongSeconds + 15
        $arguments = "--process_id $($game.Id) --qpc_time --v1_metrics --no_console_stats " +
            "--timed $duration --terminate_after_timed --terminate_on_proc_exit --session_name $($presentMon.session) " +
            "--output_file `"$($presentMon.csv)`""
        $presentMon['command'] = '"{0}" {1}' -f $presentMon.executable, $arguments
        $presentMon['launch_qpc'] = [Diagnostics.Stopwatch]::GetTimestamp()
        try {
            $presentMonProcess = Start-PresentMonCommand $arguments 'presentmon'
            $presentMon['monitor_pid'] = $presentMonProcess.Id
        }
        catch { $presentMon['launch_error'] = $_.Exception.Message }
    }
    $monitors['process'] = Start-CaptureMonitor 'process' '-IntervalMilliseconds 250'

    $startupDeadline = $launchTick + $frequency * $StartupSeconds
    while (!$game.HasExited -and !$startTick -and [Diagnostics.Stopwatch]::GetTimestamp() -lt $startupDeadline) {
        $startTick = $gameOutput.SongStart
        if (!$startTick) { Start-Sleep -Milliseconds 100 }
    }
    if (!$startTick) {
        if ($game.HasExited) { $gameOutput.WaitForDrain() }
        $startTick = $(if ($gameOutput.SongStart) { $gameOutput.SongStart })
    }
    if (!$startTick -or $startTick -gt $startupDeadline) {
        $status = if ($game.HasExited) { 'exited_before_song' } else { 'song_start_timeout' }
    } else {
        $stopTick = $startTick + $frequency * $SongSeconds
        # PDH expands GPU wildcards when opening its query. The GL context is
        # active at song start and the game's GPU counter instances can exist.
        $monitors['hardware'] = Start-CaptureMonitor 'hardware' '-IntervalSeconds 1 -StopOnProcessExit'
        $game.Refresh()
        $geometry = [NovaFlareCaptureWindow]::Read($game.MainWindowHandle)
        if ($geometry) {
            $startGeometry = [ordered]@{
                qpc = [Diagnostics.Stopwatch]::GetTimestamp()
                client_width_px = $geometry[0]
                client_height_px = $geometry[1]
                window_dpi = $geometry[2]
                source = 'Win32 GetClientRect/GetDpiForWindow'
            }
        }
        while (!$game.HasExited -and [Diagnostics.Stopwatch]::GetTimestamp() -lt $stopTick) {
            Start-Sleep -Milliseconds 50
        }
        $status = if ($game.HasExited) { 'exited_during_capture' } else { 'captured' }
        if ($presentMon) {
            $presentMon['end_check_qpc'] = [Diagnostics.Stopwatch]::GetTimestamp()
            $presentMon['running_at_capture_end'] = $presentMonProcess -and !$presentMonProcess.HasExited
        }
    }
}
catch { $captureError = $_ }
finally {
    try {
        foreach ($name in $recordedEnv.Keys) {
            Set-CaptureEnvironment $name $recordedEnv[$name]
        }
        if ($game -and !$game.HasExited) {
            $closeRequested = [Diagnostics.Stopwatch]::GetTimestamp()
            $null = $game.CloseMainWindow()
            if (!$game.WaitForExit(5000)) {
                try { $game.Kill(); $forced = $true }
                catch [InvalidOperationException] { if (!$game.HasExited) { throw } }
                $game.WaitForExit()
            }
        }
        foreach ($name in $monitors.Keys) {
            $monitor = $monitors[$name]
            $stopped = $monitor.WaitForExit(4000)
            $killed = $false
            if (!$stopped) {
                try { $monitor.Kill(); $killed = $true }
                catch [InvalidOperationException] { if (!$monitor.HasExited) { throw } }
                $stopped = $monitor.WaitForExit(4000)
            }
            $samples = Join-Path $run "$name-samples.csv"
            $monitorResults[$name] = [ordered]@{
                stopped = $stopped
                forced = $killed
                exit_code = $(if ($stopped) { $monitor.ExitCode })
                has_sample = (Test-Path -LiteralPath $samples -PathType Leaf) -and
                    @(Get-Content -LiteralPath $samples -TotalCount 2).Count -eq 2
            }
        }
    } catch { $cleanupError = $_ }
    finally {
        if ($presentMon -and $presentMon.launch_qpc) {
            Complete-PresentMonCapture $presentMonProcess ($captureError -or $cleanupError -or $status -ne 'captured')
        }
    }

    $gameExitCode = $null
    try {
        if ($game -and $game.HasExited) { $gameExitCode = $game.ExitCode }
        if ($gameOutput) {
            $gameOutput.SaveLogs($stdout, $stderr)
            if ($gameOutput.SongFinish) { $finishTick = $gameOutput.SongFinish }
        }
    } catch { if (!$cleanupError) { $cleanupError = $_ } }
    $manifest = [ordered]@{
        status = $(if ($captureError -or $cleanupError) { 'runner_error' } elseif ($status -eq 'captured') { 'validation_pending' } else { $status })
        process_id = $(if ($game) { $game.Id })
        exit_code = $gameExitCode
        force_terminated = $forced
        executable = $sourceExe
        executable_sha256 = (Get-FileHash -LiteralPath $exe -ErrorAction SilentlyContinue).Hash
        lime_sha256 = (Get-FileHash -LiteralPath (Join-Path $runtime 'lime.ndll') -ErrorAction SilentlyContinue).Hash
        runtime = $runtime
        storage = $storage
        qpc_frequency = $frequency
        launch_qpc = $launchTick
        launch_utc = $launchUtc
        song_start_qpc = $startTick
        song_finish_qpc = $finishTick
        capture_end_qpc = $stopTick
        close_requested_qpc = $closeRequested
        win32_window_at_song_start = $startGeometry
        require_sdl_geometry = $true
        monitors = $monitorResults
        environment = $childEnv
    }
    if ($preferences) { $manifest['preferences'] = $preferences }
    if ($presentMon) { $manifest['presentmon'] = $presentMon }
    if ($captureError) { $manifest['capture_error'] = $captureError.Exception.Message }
    if ($cleanupError) { $manifest['cleanup_error'] = $cleanupError.Exception.Message }
    try { $manifest | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath $manifestPath -Encoding UTF8 }
    catch {
        if (!$captureError -and !$cleanupError) { throw }
        Write-Warning "Could not write $manifestPath`: $($_.Exception.Message)"
    }
}

if ($captureError) { throw $captureError }
if ($cleanupError) { throw $cleanupError }
if ($status -ne 'captured') { throw "Capture ended with $status. See $manifestPath" }

$reportPath = Join-Path $run 'frame-summary.json'
$validationErrors = Join-Path $run 'frame-validation.stderr.log'
try {
    if (@($monitorResults.Values | Where-Object { !$_.stopped -or !$_.has_sample }).Count -gt 0) {
        throw 'The process or hardware monitor did not stop with a sample.'
    }
    if ($GcBreakdown) {
        $gcColumns = (Get-Content -LiteralPath $childEnv.NOVAFLARE_GC_PAUSE_TIMELINE -TotalCount 1) -split ','
        if ($gcColumns -notcontains 'mark_passes' -or $gcColumns -notcontains 'release_ticks') {
            throw 'The executable did not produce the requested Immix phase timings.'
        }
    }
    $analysis = Start-Process -FilePath $python -WindowStyle Hidden -PassThru -Wait `
        -ArgumentList @("`"$analyzer`"", "`"$run`"") `
        -RedirectStandardOutput $reportPath -RedirectStandardError $validationErrors
    if ($analysis.ExitCode -ne 0) { throw "Analyzer exit $($analysis.ExitCode). See $validationErrors" }
    $report = Get-Content -LiteralPath $reportPath -Raw | ConvertFrom-Json
    $intervals = @($report.settings.swap_interval | Where-Object { $null -ne $_ })
    $manifest['vsync_measured'] = $false
    if ($verifyVSync -or $intervals.Count -gt 0) {
        $mode = if ($VSync -eq '1') { 'vsync' } else { 'immediate' }
        $intervalAtStart = $intervals | Where-Object { $_.qpc -le $startTick } | Select-Object -Last 1
        $intervalChanges = @($intervals | Where-Object { $_.qpc -gt $startTick -and $_.qpc -le $stopTick })
        if (!$intervalAtStart -or (@($intervalAtStart) + $intervalChanges |
                Where-Object { $_.value -ne [int]$VSync -or $_.detail -ne $mode })) {
            throw "The measured SDL swap interval did not stay at VSync=$VSync during the capture."
        }
        $manifest['vsync_measured'] = $true
    }
    if ($presentMon -and (!$presentMon.running_at_capture_end -or $presentMon.launch_qpc -gt $startTick -or
        !$presentMon.stopped -or $null -eq $presentMon.exit_code -or $presentMon.exit_code -ne 0 -or
        $presentMon.stop_helper_timed_out -or $presentMon.retry_stop_helper_timed_out -or $presentMon.collector_timed_out -or
        ($presentMon.session_after_cleanup -and $presentMon.session_after_cleanup -ne 'absent') -or
        $report.presentmon.status -ne 'captured')) {
        throw "PresentMon did not cover the capture window with validated display data. See $manifestPath and $reportPath"
    }
} catch {
    $manifest['status'] = 'invalid_capture'
    $manifest['validation_error'] = $_.Exception.Message
    $manifest | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath $manifestPath -Encoding UTF8
    throw
}

if ($report.focus.focused_at_start -ne $true -or $report.focus.focus_losses_qpc.Count -gt 0) {
    $manifest['status'] = 'invalid_focus'
    $manifest | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath $manifestPath -Encoding UTF8
    throw "Focus was unverified or changed during capture. See $reportPath"
}
$manifest['status'] = 'captured'
$manifest | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath $manifestPath -Encoding UTF8
