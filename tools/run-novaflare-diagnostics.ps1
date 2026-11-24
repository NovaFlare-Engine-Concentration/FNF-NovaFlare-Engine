[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$RunDirectory,

    [string]$Executable = '',

    [ValidateRange(15, 3600)]
    [int]$MaximumSeconds = 180,

    [ValidateSet('Title', 'MainMenu', 'Gameplay')]
    [string]$Scenario = 'MainMenu',

    [ValidateRange(10, 90)]
    [int]$TitleDelaySeconds = 30,

    [string]$GameplaySong = 'epiphany',

    [ValidateRange(0, 32)]
    [int]$GameplayDifficulty = 2,

    [string]$GameplayMod = 'Doki Doki Takeover Plus',

    [bool]$GameplayBotplay = $true,

    [ValidateRange(3, 120)]
    [int]$UnresponsiveSeconds = 10,

    [ValidateRange(15, 300)]
    [int]$StartupUnresponsiveSeconds = 45,

    [bool]$EnableTypeTelemetry = $true,

    [bool]$CaptureFullDumpOnHang = $true,

    [bool]$CaptureEtwCpuStacks = $true,

    [switch]$CaptureFrameTimeline
)

$ErrorActionPreference = 'Stop'
$repo = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$runPath = [IO.Path]::GetFullPath($RunDirectory)
if ([string]::IsNullOrWhiteSpace($Executable)) {
    $Executable = Join-Path $repo (
        'export\release\windows\bin\NovaFlare Engine.exe')
}
$executablePath = [IO.Path]::GetFullPath($Executable)
$binDirectory = Split-Path -Parent $executablePath
$processMonitor = Join-Path $repo 'tools\monitor-novaflare-process.ps1'
$hardwareMonitor = Join-Path $repo 'tools\monitor-novaflare-hardware.ps1'
$dumpTool = Join-Path $repo 'tools\capture-novaflare-process-dump.ps1'
$frameConverter = Join-Path $repo 'tools\convert-novaflare-frame-log.ps1'

if (-not (Test-Path -LiteralPath $executablePath -PathType Leaf)) {
    throw "Executable does not exist: $executablePath"
}
if (Test-Path -LiteralPath (Join-Path $runPath 'diagnostic-manifest.json')) {
    throw "Run directory already contains a completed diagnostic run: $runPath"
}

New-Item -ItemType Directory -Path $runPath -Force | Out-Null
$dumpDirectory = Join-Path $runPath 'native-dumps'
$haxeCrashDirectory = Join-Path $runPath 'haxe-crash'
New-Item -ItemType Directory -Path $dumpDirectory -Force | Out-Null
New-Item -ItemType Directory -Path $haxeCrashDirectory -Force | Out-Null

$haxeLog = Join-Path $runPath 'haxe-stdout.log'
$nativeErrorLog = Join-Path $runPath 'native-stderr.log'
$gcCsv = Join-Path $runPath 'gc-cycles.csv'
$gcJson = Join-Path $runPath 'gc-cycles.jsonl'
$gcDiagnostics = Join-Path $runPath 'gc-diagnostics.log'
$frameCsv = Join-Path $runPath 'frame-rate-from-haxe.csv'
$frameTimeline = Join-Path $runPath 'frame-timeline.csv'
$gcPauseTimeline = Join-Path $runPath 'gc-pauses-qpc.csv'
$processLog = Join-Path $runPath 'process-samples.csv'
$monitorStdout = Join-Path $runPath 'process-monitor.stdout.log'
$monitorStderr = Join-Path $runPath 'process-monitor.stderr.log'
$hardwareLog = Join-Path $runPath 'hardware-samples.csv'
$hardwareMonitorStdout =
    Join-Path $runPath 'hardware-monitor.stdout.log'
$hardwareMonitorStderr =
    Join-Path $runPath 'hardware-monitor.stderr.log'
$errorsLog = Join-Path $runPath 'errors-and-stacks.log'
$windowsEventsPath = Join-Path $runPath 'windows-error-events.json'
$etwPath = Join-Path $runPath 'cpu-stacks.etl'
$etwLog = Join-Path $runPath 'cpu-stacks-wpr.log'
$manifestPath = Join-Path $runPath 'diagnostic-manifest.json'

# The child process receives these settings. The calling shell is a separate
# process, so an interrupted run cannot pollute the user's later game launches.
@(
    'HXCPP_NOVAGC_TELEMETRY',
    'HXCPP_NOVAGC_CSV_LOG',
    'HXCPP_NOVAGC_JSON_LOG',
    'HXCPP_NOVAGC_DIAGNOSTIC_LOG',
    'HXCPP_NOVAGC_TYPE_TELEMETRY',
    'NOVAGC_PERF_TRACE',
    'NOVAFLARE_FRAME_TIMELINE',
    'NOVAFLARE_GC_PAUSE_TIMELINE',
    'NOVAFLARE_DIAGNOSTIC_DIR',
    'NOVAFLARE_NATIVE_DUMP_DIR',
    'NOVAFLARE_DIAGNOSTIC_SONG',
    'NOVAFLARE_DIAGNOSTIC_DIFFICULTY',
    'NOVAFLARE_DIAGNOSTIC_MOD',
    'NOVAFLARE_DIAGNOSTIC_BOTPLAY'
) | ForEach-Object {
    Remove-Item -LiteralPath "Env:$_" -ErrorAction SilentlyContinue
}
$env:HXCPP_NOVAGC_CSV_LOG = $gcCsv
$env:HXCPP_NOVAGC_JSON_LOG = $gcJson
$env:HXCPP_NOVAGC_DIAGNOSTIC_LOG = $gcDiagnostics
$env:NOVAGC_PERF_TRACE = '1'
if ($CaptureFrameTimeline) {
    $env:NOVAFLARE_FRAME_TIMELINE = $frameTimeline
    $env:NOVAFLARE_GC_PAUSE_TIMELINE = $gcPauseTimeline
}
$env:NOVAFLARE_DIAGNOSTIC_DIR = $runPath
$env:NOVAFLARE_NATIVE_DUMP_DIR = $dumpDirectory
if ($EnableTypeTelemetry) {
    $env:HXCPP_NOVAGC_TYPE_TELEMETRY = '1'
}
if ($Scenario -eq 'Gameplay') {
    if ([string]::IsNullOrWhiteSpace($GameplaySong)) {
        throw 'GameplaySong must not be empty for the Gameplay scenario.'
    }
    $env:NOVAFLARE_DIAGNOSTIC_SONG = $GameplaySong
    $env:NOVAFLARE_DIAGNOSTIC_DIFFICULTY =
        $GameplayDifficulty.ToString(
            [Globalization.CultureInfo]::InvariantCulture)
    $env:NOVAFLARE_DIAGNOSTIC_MOD = $GameplayMod
    $env:NOVAFLARE_DIAGNOSTIC_BOTPLAY =
        if ($GameplayBotplay) { '1' } else { '0' }
}

if (-not ('NovaFlareDiagnosticInput.Native' -as [type])) {
    Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
namespace NovaFlareDiagnosticInput {
    public static class Native {
        [DllImport("user32.dll")]
        public static extern bool PostMessage(
            IntPtr window, uint message, IntPtr key, IntPtr state);
    }
}
'@
}

$startedUtc = [DateTime]::UtcNow
$startedLocal = [DateTime]::Now
$stopwatch = [Diagnostics.Stopwatch]::StartNew()
$process = $null
$processMonitorProcess = $null
$hardwareMonitorProcess = $null
$enteredScenario = $Scenario -ne 'MainMenu'
$hangDumpAttempted = $false
$hangDumpSucceeded = $false
$unresponsiveSince = $null
$runtimeHangDetectionArmed = $Scenario -ne 'Gameplay'
$runtimeHangDetectionArmedElapsedSeconds =
    if ($runtimeHangDetectionArmed) { 0.0 } else { $null }
$hangThresholdSecondsAtDetection = $null
$hangDetectionPhaseAtDetection = $null
$forcedTermination = $false
$exitCode = $null
$exitCodeError = $null
$processHasExited = $false
$exitedBeforeMeasurementWindow = $false
$measurementWindowReached = $false
$runnerError = $null
$etwStarted = $false
$etwStopped = $false
$etwError = $null
$wpr = if ($CaptureEtwCpuStacks) {
    Get-Command 'wpr.exe' -ErrorAction SilentlyContinue
} else { $null }

try {
    if ($CaptureEtwCpuStacks) {
        if ($null -eq $wpr) {
            $etwError = 'wpr.exe is unavailable'
        }
        else {
            try {
                $startOutput = @(& $wpr.Source -start CPU -filemode 2>&1)
                $startExitCode = $LASTEXITCODE
                [IO.File]::WriteAllLines(
                    $etwLog,
                    @(
                        "start_exit_code=$startExitCode"
                        $startOutput
                    ),
                    [Text.UTF8Encoding]::new($false))
                if ($startExitCode -eq 0) {
                    $etwStarted = $true
                }
                else {
                    $etwError = "WPR start failed with exit code $startExitCode"
                }
            }
            catch {
                $etwError = $_.Exception.Message
            }
        }
    }

    $process = Start-Process -FilePath $executablePath `
        -WorkingDirectory $binDirectory `
        -RedirectStandardOutput $haxeLog `
        -RedirectStandardError $nativeErrorLog -PassThru
    Write-Output "pid=$($process.Id)"

    $monitorArguments = @(
        '-NoLogo', '-NoProfile', '-NonInteractive',
        '-ExecutionPolicy', 'Bypass',
        '-File', $processMonitor,
        '-TargetProcessId', $process.Id,
        '-RunDirectory', $runPath,
        '-MaximumSeconds', $MaximumSeconds,
        '-IntervalMilliseconds', 250
    )
    $processMonitorProcess = Start-Process -FilePath 'powershell.exe' `
        -ArgumentList $monitorArguments -WindowStyle Hidden `
        -RedirectStandardOutput $monitorStdout `
        -RedirectStandardError $monitorStderr -PassThru

    $hardwareMonitorArguments = @(
        '-NoLogo', '-NoProfile', '-NonInteractive',
        '-ExecutionPolicy', 'Bypass',
        '-File', $hardwareMonitor,
        '-TargetProcessId', $process.Id,
        '-RunDirectory', $runPath,
        '-MaximumSeconds', $MaximumSeconds,
        '-IntervalSeconds', 1
    )
    $hardwareMonitorProcess = Start-Process -FilePath 'powershell.exe' `
        -ArgumentList $hardwareMonitorArguments -WindowStyle Hidden `
        -RedirectStandardOutput $hardwareMonitorStdout `
        -RedirectStandardError $hardwareMonitorStderr -PassThru

    while ($stopwatch.Elapsed.TotalSeconds -lt $MaximumSeconds) {
        try {
            $process.Refresh()
            if ($process.HasExited) {
                $exitedBeforeMeasurementWindow = $true
                break
            }
        }
        catch {
            $exitedBeforeMeasurementWindow = $true
            break
        }

        if (-not $enteredScenario -and
            $stopwatch.Elapsed.TotalSeconds -ge $TitleDelaySeconds) {
            $process.Refresh()
            $window = $process.MainWindowHandle
            if ($window -ne [IntPtr]::Zero) {
                $down = [NovaFlareDiagnosticInput.Native]::PostMessage(
                    $window, 0x0100, [IntPtr]0x0d, [IntPtr]0x001c0001)
                Start-Sleep -Milliseconds 100
                $up = [NovaFlareDiagnosticInput.Native]::PostMessage(
                    $window, 0x0101, [IntPtr]0x0d, [IntPtr]0xc01c0001)
                $enteredScenario = $down -and $up
                Write-Output "main_menu_input=$enteredScenario"
            }
        }

        # Gameplay startup performs synchronous chart parsing and asset loading
        # before PlayState.create finishes. Windows can legitimately report the
        # window as not responding during that work, so use the longer startup
        # threshold until the Haxe log proves that the runtime scenario exists.
        if (-not $runtimeHangDetectionArmed -and
            (Test-Path -LiteralPath $haxeLog -PathType Leaf)) {
            $playStateCreateObserved = $null -ne (
                Select-String -LiteralPath $haxeLog `
                    -SimpleMatch 'perf:PlayState.create end' `
                    -ErrorAction SilentlyContinue |
                    Select-Object -First 1)
            if ($playStateCreateObserved) {
                $runtimeHangDetectionArmed = $true
                $runtimeHangDetectionArmedElapsedSeconds =
                    [Math]::Round($stopwatch.Elapsed.TotalSeconds, 3)
                # Do not carry startup unresponsiveness into the shorter
                # runtime threshold.
                $unresponsiveSince = $null
                Write-Output "runtime_hang_detection_armed_elapsed_s=$(
                    $runtimeHangDetectionArmedElapsedSeconds)"
            }
        }

        $activeUnresponsiveSeconds =
            if ($runtimeHangDetectionArmed) {
                $UnresponsiveSeconds
            }
            else {
                $StartupUnresponsiveSeconds
            }
        $responding = $process.Responding
        if ($responding) {
            $unresponsiveSince = $null
        }
        elseif ($null -eq $unresponsiveSince) {
            $unresponsiveSince = [DateTime]::UtcNow
        }
        elseif (-not $hangDumpAttempted -and
            ([DateTime]::UtcNow - $unresponsiveSince).TotalSeconds -ge
                $activeUnresponsiveSeconds) {
            $hangDumpAttempted = $true
            $hangThresholdSecondsAtDetection = $activeUnresponsiveSeconds
            $hangDetectionPhaseAtDetection =
                if ($runtimeHangDetectionArmed) { 'runtime' } else { 'startup' }
            Write-Output "hang_detected_elapsed_s=$(
                [Math]::Round($stopwatch.Elapsed.TotalSeconds, 3))"
            if ($CaptureFullDumpOnHang) {
                $dumpPath = Join-Path $dumpDirectory (
                    'hang-full-{0:yyyyMMdd-HHmmss}.dmp' -f [DateTime]::Now)
                try {
                    & $dumpTool -TargetProcessId $process.Id `
                        -OutputPath $dumpPath -DumpType Full | Out-String |
                        Write-Output
                    $hangDumpSucceeded = $true
                }
                catch {
                    Write-Output "hang_dump_error=$($_.Exception.Message)"
                }
            }
        }

        Start-Sleep -Milliseconds 500
    }
    $measurementWindowReached =
        $stopwatch.Elapsed.TotalSeconds -ge $MaximumSeconds

    $process.Refresh()
    if (-not $process.HasExited) {
        $null = $process.CloseMainWindow()
        if (-not $process.WaitForExit(10000)) {
            $forcedTermination = $true
            Stop-Process -Id $process.Id -Force
            $process.WaitForExit()
        }
    }
    try {
        $process.Refresh()
        $processHasExited = $process.HasExited
        if ($processHasExited) {
            # The parameterless call completes asynchronous redirected-stream
            # draining and makes ExitCode reliable on Windows PowerShell 5.1.
            $process.WaitForExit()
            $process.Refresh()
            $exitCode = [int]$process.ExitCode
        }
    }
    catch {
        $exitCodeError = $_.Exception.Message
    }
}
catch {
    $runnerError = $_.Exception.ToString()
    Write-Output "runner_error=$runnerError"
}
finally {
    if ($null -ne $processMonitorProcess) {
        try {
            if (-not $processMonitorProcess.WaitForExit(15000)) {
                Stop-Process -Id $processMonitorProcess.Id -Force `
                    -ErrorAction SilentlyContinue
            }
        }
        catch {}
    }
    if ($null -ne $hardwareMonitorProcess) {
        try {
            if (-not $hardwareMonitorProcess.WaitForExit(15000)) {
                Stop-Process -Id $hardwareMonitorProcess.Id -Force `
                    -ErrorAction SilentlyContinue
            }
        }
        catch {}
    }
    if ($etwStarted -and $null -ne $wpr) {
        try {
            $stopOutput = @(& $wpr.Source -stop $etwPath 2>&1)
            $stopExitCode = $LASTEXITCODE
            [IO.File]::AppendAllText(
                $etwLog,
                ((@(
                    "stop_exit_code=$stopExitCode"
                    $stopOutput
                ) -join [Environment]::NewLine) + [Environment]::NewLine),
                [Text.UTF8Encoding]::new($false))
            if ($stopExitCode -eq 0) {
                $etwStopped = $true
            }
            else {
                $etwError = "WPR stop failed with exit code $stopExitCode"
            }
        }
        catch {
            $etwError = $_.Exception.Message
        }
    }
}

# Parse the stable in-process counters rather than guessing generated static
# addresses in a stripped executable.
$frameConversion = $null
try {
    $frameConversion = & $frameConverter -InputPath $haxeLog `
        -OutputPath $frameCsv
}
catch {
    $frameConversion = [pscustomobject]@{
        output = $frameCsv
        samples = 0
        error = $_.Exception.Message
    }
}

# CrashHandler writes Haxe exception stacks relative to the game working
# directory. Copy only files created by this run.
$sourceCrashDirectory = Join-Path $binDirectory 'crash'
if (Test-Path -LiteralPath $sourceCrashDirectory -PathType Container) {
    Get-ChildItem -LiteralPath $sourceCrashDirectory -File |
        Where-Object { $_.LastWriteTimeUtc -ge $startedUtc.AddSeconds(-2) } |
        ForEach-Object {
            [IO.File]::Copy(
                $_.FullName,
                (Join-Path $haxeCrashDirectory $_.Name),
                $true)
        }
}

# Preserve Windows Application Error/WER records even when the process exits
# before stdout can flush.
$windowsEvents = @()
try {
    $windowsEvents = @(Get-WinEvent -FilterHashtable @{
        LogName = 'Application'
        StartTime = $startedLocal
    } -ErrorAction Stop | Where-Object {
        $_.Id -in @(1000, 1001, 1026) -and
        $_.TimeCreated.ToUniversalTime() -ge $startedUtc.AddSeconds(-2) -and
        $_.Message -like '*NovaFlare Engine*'
    } | Select-Object TimeCreated, Id, ProviderName, LevelDisplayName, Message)
}
catch {}
[IO.File]::WriteAllText(
    $windowsEventsPath,
    ($windowsEvents | ConvertTo-Json -Depth 5),
    [Text.UTF8Encoding]::new($false))

# Consolidate Haxe exceptions, native stderr, assertion/SEH text and stack
# lines into one triage file without deleting the full source logs.
$errorPattern =
    '(?i)(error|exception|fatal|assert|abort|access violation|' +
    'null object|stack|segmentation|seh|out of memory|allocation stall)'
$errorLines = [Collections.Generic.List[string]]::new()
foreach ($path in @($haxeLog, $nativeErrorLog, $monitorStderr, $etwLog)) {
    if (-not (Test-Path -LiteralPath $path)) {
        continue
    }
    foreach ($match in Select-String -LiteralPath $path `
        -Pattern $errorPattern -AllMatches -ErrorAction SilentlyContinue) {
        $errorLines.Add("$([IO.Path]::GetFileName($path)):$(
            $match.LineNumber): $($match.Line)")
    }
}
Get-ChildItem -LiteralPath $haxeCrashDirectory -File |
    ForEach-Object {
        $errorLines.Add("===== haxe-crash/$($_.Name) =====")
        foreach ($line in [IO.File]::ReadLines($_.FullName)) {
            $errorLines.Add($line)
        }
    }
[IO.File]::WriteAllLines(
    $errorsLog, $errorLines, [Text.UTF8Encoding]::new($false))

$nativeDumps = @(Get-ChildItem -LiteralPath $dumpDirectory -Filter '*.dmp' `
    -File -ErrorAction SilentlyContinue)
$nativeCrashDumps = @($nativeDumps | Where-Object {
    $_.Name -like 'native-crash-*.dmp'
})
$haxeCrashes = @(Get-ChildItem -LiteralPath $haxeCrashDirectory -File `
    -ErrorAction SilentlyContinue)
$gcCsvRows = if (Test-Path -LiteralPath $gcCsv) {
    [Math]::Max(0, ([IO.File]::ReadAllLines($gcCsv).Length - 1))
} else { 0 }
$gcJsonRows = if (Test-Path -LiteralPath $gcJson) {
    [IO.File]::ReadAllLines($gcJson).Length
} else { 0 }
$processRows = if (Test-Path -LiteralPath $processLog) {
    [Math]::Max(0, ([IO.File]::ReadAllLines($processLog).Length - 1))
} else { 0 }
$hardwareRows = if (Test-Path -LiteralPath $hardwareLog) {
    [Math]::Max(
        0,
        ([IO.File]::ReadAllLines($hardwareLog).Length - 1))
} else { 0 }
$frameSamples = if ($null -ne $frameConversion) {
    [int]$frameConversion.samples
} else { 0 }
$frameTimelineRows = if (Test-Path -LiteralPath $frameTimeline -PathType Leaf) {
    [Math]::Max(0, ([IO.File]::ReadAllLines($frameTimeline).Length - 2))
} else { 0 }
$gcPauseTimelineRows = if (Test-Path -LiteralPath $gcPauseTimeline -PathType Leaf) {
    [Math]::Max(0, ([IO.File]::ReadAllLines($gcPauseTimeline).Length - 1))
} else { 0 }
$haxeLogExists = Test-Path -LiteralPath $haxeLog -PathType Leaf
$nativeErrorLogExists =
    Test-Path -LiteralPath $nativeErrorLog -PathType Leaf
$errorsLogExists = Test-Path -LiteralPath $errorsLog -PathType Leaf
$windowsEventsExist =
    Test-Path -LiteralPath $windowsEventsPath -PathType Leaf
$gcDiagnosticsExist =
    Test-Path -LiteralPath $gcDiagnostics -PathType Leaf
$etwExists = Test-Path -LiteralPath $etwPath -PathType Leaf
$etwBytes = if ($etwExists) {
    (Get-Item -LiteralPath $etwPath).Length
} else { 0 }
$hasNativeStacks = $nativeDumps.Count -gt 0 -or
    ($etwStopped -and $etwBytes -gt 0)
$hasHaxeExceptionEvidence = $haxeCrashes.Count -gt 0
$hasObservedError = $errorLines.Count -gt 0 -or
    $haxeCrashes.Count -gt 0 -or $nativeDumps.Count -gt 0 -or
    $windowsEvents.Count -gt 0 -or
    ($null -ne $exitCode -and $exitCode -ne 0)
$haxeStackContractSatisfied = -not $hasObservedError -or
    $hasHaxeExceptionEvidence -or $nativeDumps.Count -gt 0 -or
    $windowsEvents.Count -gt 0
$gameplayPrepared = $false
$playStateCreated = $false
if ($haxeLogExists -and $Scenario -eq 'Gameplay') {
    $gameplayPrepared = $null -ne (Select-String -LiteralPath $haxeLog `
        -SimpleMatch 'diagnostic:gameplay prepared' `
        -ErrorAction SilentlyContinue | Select-Object -First 1)
    $playStateCreated = $null -ne (Select-String -LiteralPath $haxeLog `
        -SimpleMatch 'perf:PlayState.create end' `
        -ErrorAction SilentlyContinue | Select-Object -First 1)
}
$scenarioStateConfirmed = $Scenario -ne 'Gameplay' -or
    ($gameplayPrepared -and $playStateCreated)
$captureContract = [ordered]@{
    haxe_runtime_log = $haxeLogExists
    haxe_error_and_exception_stack_pipeline =
        $errorsLogExists -and $haxeStackContractSatisfied
    native_thread_stacks = $hasNativeStacks
    heap_and_gc_cycles = $gcCsvRows -gt 0 -and $gcJsonRows -gt 0
    frame_rate = $frameSamples -gt 0
    process_resources = $processRows -gt 0
    hardware_resources = $hardwareRows -gt 0
    windows_crash_events = $windowsEventsExist
}
if ($CaptureFrameTimeline) {
    $captureContract['native_frame_timeline'] = $frameTimelineRows -gt 0
}
$captureContractComplete =
    @($captureContract.Values | Where-Object { -not $_ }).Count -eq 0

$nativeCrashDetected = $nativeCrashDumps.Count -gt 0
$windowsCrashDetected = $windowsEvents.Count -gt 0
$haxeCrashDetected = $haxeCrashes.Count -gt 0
$nonzeroExitReported = $null -ne $exitCode -and $exitCode -ne 0
$runFailed =
    $null -ne $runnerError -or $nativeCrashDetected -or
    $windowsCrashDetected -or $haxeCrashDetected -or
    $nonzeroExitReported -or $hangDumpAttempted -or
    (-not $scenarioStateConfirmed)
$runStatus = if ($nativeCrashDetected -or $windowsCrashDetected -or
                  $haxeCrashDetected -or $nonzeroExitReported) {
    'crashed'
}
elseif ($hangDumpAttempted) {
    'hung'
}
elseif ($null -ne $runnerError) {
    'runner_error'
}
elseif (-not $scenarioStateConfirmed) {
    'scenario_not_confirmed'
}
elseif ($exitedBeforeMeasurementWindow) {
    'exited_early'
}
elseif ($forcedTermination) {
    'measurement_complete_forced_shutdown'
}
else {
    'measurement_complete'
}

$manifest = [ordered]@{
    schema = 4
    required_capture_objectives = @(
        'Haxe runtime stdout and trace log',
        'Haxe error text and exception/call stacks when an error occurs',
        'native sampled thread stacks or crash/hang dump',
        'heap composition and GC cycle telemetry',
        'frame-rate/update/draw telemetry',
        'process CPU, memory, responsiveness and thread-count telemetry',
        'CPU frequency, foreground window and process GPU telemetry',
        'Windows crash/error events'
    )
    capture_contract = $captureContract
    capture_contract_complete = $captureContractComplete
    run_outcome = [ordered]@{
        status = $runStatus
        failed = $runFailed
        measurement_window_reached = $measurementWindowReached
        exited_before_measurement_window =
            $exitedBeforeMeasurementWindow
        native_crash_detected = $nativeCrashDetected
        native_crash_dumps = $nativeCrashDumps.Count
        windows_crash_detected = $windowsCrashDetected
        haxe_crash_detected = $haxeCrashDetected
        hang_detected = $hangDumpAttempted
        reported_exit_code = $exitCode
        reported_nonzero_exit = $nonzeroExitReported
        exit_code_may_be_unreliable_after_native_crash =
            $nativeCrashDetected -or $windowsCrashDetected
    }
    started_utc = $startedUtc.ToString('o')
    finished_utc = [DateTime]::UtcNow.ToString('o')
    duration_seconds = [Math]::Round($stopwatch.Elapsed.TotalSeconds, 3)
    executable = $executablePath
    executable_sha256 = (Get-FileHash -Algorithm SHA256 `
        -LiteralPath $executablePath).Hash
    process_id = if ($null -ne $process) { $process.Id } else { $null }
    exit_code = $exitCode
    exit_code_error = $exitCodeError
    process_has_exited = $processHasExited
    forced_termination = $forcedTermination
    scenario = $Scenario
    scenario_input_sent = $enteredScenario
    scenario_state_confirmed = $scenarioStateConfirmed
    hang_detection = [ordered]@{
        runtime_unresponsive_seconds = $UnresponsiveSeconds
        startup_unresponsive_seconds = $StartupUnresponsiveSeconds
        runtime_armed = $runtimeHangDetectionArmed
        runtime_armed_elapsed_seconds =
            $runtimeHangDetectionArmedElapsedSeconds
        threshold_seconds_at_detection =
            $hangThresholdSecondsAtDetection
        phase_at_detection = $hangDetectionPhaseAtDetection
    }
    scenario_details = [ordered]@{
        gameplay_song = if ($Scenario -eq 'Gameplay') {
            $GameplaySong
        } else { $null }
        gameplay_difficulty = if ($Scenario -eq 'Gameplay') {
            $GameplayDifficulty
        } else { $null }
        gameplay_mod = if ($Scenario -eq 'Gameplay') {
            $GameplayMod
        } else { $null }
        gameplay_botplay = if ($Scenario -eq 'Gameplay') {
            $GameplayBotplay
        } else { $null }
        gameplay_prepared = $gameplayPrepared
        play_state_created = $playStateCreated
    }
    runner_error = $runnerError
    capture = [ordered]@{
        haxe_stdout = [ordered]@{
            path = $haxeLog
            exists = $haxeLogExists
        }
        native_stderr = [ordered]@{
            path = $nativeErrorLog
            exists = $nativeErrorLogExists
        }
        haxe_exception_stacks = [ordered]@{
            path = $haxeCrashDirectory
            files = $haxeCrashes.Count
        }
        native_crash_or_hang_dumps = [ordered]@{
            path = $dumpDirectory
            files = $nativeDumps.Count
            native_crash_files = $nativeCrashDumps.Count
            total_bytes = [uint64](($nativeDumps |
                Measure-Object Length -Sum).Sum)
            hang_dump_attempted = $hangDumpAttempted
            hang_dump_succeeded = $hangDumpSucceeded
        }
        errors_and_stacks = [ordered]@{
            path = $errorsLog
            lines = $errorLines.Count
        }
        gc_csv = [ordered]@{
            path = $gcCsv
            rows = $gcCsvRows
        }
        gc_json_and_type_census = [ordered]@{
            path = $gcJson
            rows = $gcJsonRows
            type_telemetry_enabled = $EnableTypeTelemetry
        }
        gc_type_census_and_handshake = [ordered]@{
            path = $gcDiagnostics
            exists = $gcDiagnosticsExist
        }
        frame_log = [ordered]@{
            path = $frameCsv
            samples = $frameSamples
            source = 'NOVAGC_PERF_TRACE'
        }
        frame_timeline = [ordered]@{
            requested = [bool]$CaptureFrameTimeline
            path = $frameTimeline
            rows = $frameTimelineRows
            immix_pause_path = $gcPauseTimeline
            immix_pauses = $gcPauseTimelineRows
        }
        process_log = [ordered]@{
            path = $processLog
            rows = $processRows
        }
        hardware_log = [ordered]@{
            path = $hardwareLog
            rows = $hardwareRows
            process_monitor_stderr = $monitorStderr
            hardware_monitor_stderr = $hardwareMonitorStderr
        }
        windows_error_events = [ordered]@{
            path = $windowsEventsPath
            events = $windowsEvents.Count
        }
        etw_cpu_stacks = [ordered]@{
            requested = $CaptureEtwCpuStacks
            started = $etwStarted
            stopped = $etwStopped
            path = $etwPath
            exists = $etwExists
            bytes = $etwBytes
            log = $etwLog
            error = $etwError
        }
    }
}
[IO.File]::WriteAllText(
    $manifestPath,
    ($manifest | ConvertTo-Json -Depth 8),
    [Text.UTF8Encoding]::new($false))

$manifest | ConvertTo-Json -Depth 8
