[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [int]$TargetProcessId,

    [Parameter(Mandatory = $true)]
    [string]$RunDirectory,

    [ValidateRange(15, 3600)]
    [int]$MaximumSeconds = 480,

    [ValidateRange(1, 10)]
    [int]$IntervalSeconds = 1,

    [switch]$StopOnProcessExit
)

$ErrorActionPreference = 'Stop'
$runPath = [IO.Path]::GetFullPath($RunDirectory)
New-Item -ItemType Directory -Path $runPath -Force | Out-Null
$csvPath = Join-Path $runPath 'hardware-samples.csv'
$statusPath = Join-Path $runPath 'hardware-monitor-status.txt'
$sample = 0
$maximumSamples =
    [Math]::Ceiling($MaximumSeconds / $IntervalSeconds) + 5
$pidPrefix = "pid_$($TargetProcessId)_"
$targetProcess = if ($StopOnProcessExit) {
    [Diagnostics.Process]::GetProcessById($TargetProcessId)
}

$counters = @(
    '\Processor Information(_Total)\Processor Frequency',
    '\Processor Information(_Total)\% Processor Performance',
    '\Processor Information(_Total)\% Processor Utility',
    '\Processor Information(_Total)\Parking Status',
    '\GPU Engine(*)\Utilization Percentage',
    '\GPU Process Memory(*)\Dedicated Usage',
    '\GPU Process Memory(*)\Shared Usage',
    '\GPU Process Memory(*)\Total Committed'
)

function Get-CounterValue(
    [object[]]$CounterSamples,
    [string]$CounterSuffix
) {
    $counter = $CounterSamples |
        Where-Object {
            $_.Path.EndsWith(
                $CounterSuffix,
                [StringComparison]::OrdinalIgnoreCase)
        } |
        Select-Object -First 1
    if ($null -eq $counter) {
        return 0.0
    }
    return [double]$counter.CookedValue
}

function Get-GpuEngineValue(
    [object[]]$CounterSamples,
    [string]$EngineType
) {
    $total = (
        $CounterSamples |
            Where-Object {
                $_.InstanceName.StartsWith(
                    $pidPrefix,
                    [StringComparison]::OrdinalIgnoreCase) -and
                $_.InstanceName.EndsWith(
                    "engtype_$EngineType",
                    [StringComparison]::OrdinalIgnoreCase) -and
                $_.Path.EndsWith(
                    '\utilization percentage',
                    [StringComparison]::OrdinalIgnoreCase)
            } |
            Measure-Object CookedValue -Sum
    ).Sum
    if ($null -eq $total) {
        return 0.0
    }
    return [double]$total
}

function Get-GpuMemoryValue(
    [object[]]$CounterSamples,
    [string]$CounterSuffix
) {
    $total = (
        $CounterSamples |
            Where-Object {
                $_.InstanceName.StartsWith(
                    $pidPrefix,
                    [StringComparison]::OrdinalIgnoreCase) -and
                $_.Path.EndsWith(
                    $CounterSuffix,
                    [StringComparison]::OrdinalIgnoreCase)
            } |
            Measure-Object CookedValue -Sum
    ).Sum
    if ($null -eq $total) {
        return 0.0
    }
    return [double]$total
}

$writer = [IO.StreamWriter]::new(
    $csvPath,
    $false,
    [Text.UTF8Encoding]::new($false))
try {
    $writer.WriteLine(
        'sample,utc,cpu_frequency_mhz,cpu_performance_percent,' +
        'cpu_utility_percent,cpu_parking_percent,gpu_total_percent,' +
        'gpu_3d_percent,gpu_copy_percent,gpu_compute_percent,' +
        'gpu_video_decode_percent,gpu_video_encode_percent,' +
        'gpu_dedicated_mb,gpu_shared_mb,gpu_total_committed_mb,' +
        'gpu_engine_counter_samples,gpu_memory_counter_samples')
    $writer.Flush()

    Get-Counter -Counter $counters `
        -SampleInterval $IntervalSeconds `
        -MaxSamples $maximumSamples `
        -ErrorAction SilentlyContinue |
        ForEach-Object {
            if ($targetProcess -and $targetProcess.HasExited) {
                throw [OperationCanceledException]::new('Target process exited')
            }
            $sample++
            $counterSamples = @($_.CounterSamples)
            $gpuCounters = @($counterSamples | Where-Object {
                $_.InstanceName.StartsWith($pidPrefix, [StringComparison]::OrdinalIgnoreCase)
            })
            $engineCounterCount = @($gpuCounters | Where-Object {
                $_.Path.EndsWith('\utilization percentage', [StringComparison]::OrdinalIgnoreCase)
            }).Count
            $memoryCounterCount = @($gpuCounters | Where-Object {
                $_.Path.EndsWith('\total committed', [StringComparison]::OrdinalIgnoreCase)
            }).Count
            $gpu3d =
                Get-GpuEngineValue $counterSamples '3d'
            $gpuCopy =
                Get-GpuEngineValue $counterSamples 'copy'
            $gpuCompute =
                Get-GpuEngineValue $counterSamples 'compute'
            $gpuVideoDecode =
                Get-GpuEngineValue $counterSamples 'videodecode'
            $gpuVideoEncode =
                Get-GpuEngineValue $counterSamples 'videoencode'
            $gpuTotal =
                $gpu3d + $gpuCopy + $gpuCompute +
                $gpuVideoDecode + $gpuVideoEncode

            $row = @(
                $sample,
                $_.Timestamp.ToUniversalTime().ToString('o'),
                [Math]::Round((
                        Get-CounterValue $counterSamples `
                            '\processor frequency'), 2),
                [Math]::Round((
                        Get-CounterValue $counterSamples `
                            '\% processor performance'), 2),
                [Math]::Round((
                        Get-CounterValue $counterSamples `
                            '\% processor utility'), 2),
                [Math]::Round((
                        Get-CounterValue $counterSamples `
                            '\parking status'), 2),
                [Math]::Round($gpuTotal, 3),
                [Math]::Round($gpu3d, 3),
                [Math]::Round($gpuCopy, 3),
                [Math]::Round($gpuCompute, 3),
                [Math]::Round($gpuVideoDecode, 3),
                [Math]::Round($gpuVideoEncode, 3),
                [Math]::Round((
                        Get-GpuMemoryValue $counterSamples `
                            '\dedicated usage') / 1MB, 2),
                [Math]::Round((
                        Get-GpuMemoryValue $counterSamples `
                            '\shared usage') / 1MB, 2),
                [Math]::Round((
                        Get-GpuMemoryValue $counterSamples `
                            '\total committed') / 1MB, 2),
                $engineCounterCount,
                $memoryCounterCount
            )
            $writer.WriteLine(($row -join ','))
            $writer.Flush()
        }
}
catch [OperationCanceledException] {
    if (!$targetProcess -or !$targetProcess.HasExited) { throw }
}
finally {
    $writer.Dispose()
    if ($targetProcess) { $targetProcess.Dispose() }
    [IO.File]::WriteAllText(
        $statusPath,
        "state=stopped`r`nsamples=$sample`r`n",
        [Text.UTF8Encoding]::new($false))
}
