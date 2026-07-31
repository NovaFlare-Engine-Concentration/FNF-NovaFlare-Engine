[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [int]$TargetProcessId,

    [Parameter(Mandatory = $true)]
    [string]$RunDirectory,

    [ValidateRange(1, 3600)]
    [int]$MaximumSeconds = 480,

    [ValidateRange(10, 5000)]
    [int]$IntervalMilliseconds = 25,

    [int64]$CounterBaseRvaHint = 0x48c3ae8
)

$ErrorActionPreference = 'Stop'
$runPath = [IO.Path]::GetFullPath($RunDirectory)
New-Item -ItemType Directory -Path $runPath -Force | Out-Null
$csvPath = Join-Path $runPath 'frame-rate-samples.csv'
$statusPath = Join-Path $runPath 'frame-rate-monitor-status.txt'

if (-not ('NovaFlareFrameMonitor.Native' -as [type])) {
    Add-Type -TypeDefinition @'
using System;
using System.Collections.Generic;
using System.Runtime.InteropServices;

namespace NovaFlareFrameMonitor {
    public static class Native {
        [StructLayout(LayoutKind.Sequential)]
        public struct MEMORY_BASIC_INFORMATION {
            public IntPtr BaseAddress;
            public IntPtr AllocationBase;
            public uint AllocationProtect;
            public UIntPtr RegionSize;
            public uint State;
            public uint Protect;
            public uint Type;
        }

        [DllImport("kernel32.dll", SetLastError = true)]
        public static extern IntPtr OpenProcess(uint access, bool inherit, int pid);

        [DllImport("kernel32.dll", SetLastError = true)]
        [return: MarshalAs(UnmanagedType.Bool)]
        public static extern bool ReadProcessMemory(
            IntPtr process, IntPtr address, byte[] buffer, int size,
            out IntPtr bytesRead);

        [DllImport("kernel32.dll")]
        public static extern UIntPtr VirtualQueryEx(
            IntPtr process, IntPtr address,
            out MEMORY_BASIC_INFORMATION information, UIntPtr length);

        [DllImport("kernel32.dll")]
        [return: MarshalAs(UnmanagedType.Bool)]
        public static extern bool CloseHandle(IntPtr handle);

        private const long DrawFrameDelta = 0x1b858;
        private const long DrawFpsDelta = 0x1b860;
        private const long UpdateFrameDelta = 0x1b878;
        private const long UpdateFpsDelta = 0x1b880;

        private static bool Read(IntPtr process, long address, byte[] buffer) {
            IntPtr read;
            return ReadProcessMemory(process, new IntPtr(address), buffer,
                                     buffer.Length, out read) &&
                   read.ToInt64() == buffer.Length;
        }

        public static double ReadDouble(IntPtr process, long address) {
            byte[] bytes = new byte[8];
            if (!Read(process, address, bytes)) return double.NaN;
            return BitConverter.ToDouble(bytes, 0);
        }

        public static int ReadInt32(IntPtr process, long address) {
            byte[] bytes = new byte[4];
            if (!Read(process, address, bytes)) return Int32.MinValue;
            return BitConverter.ToInt32(bytes, 0);
        }

        private static bool Plausible(IntPtr process, long drawTarget) {
            int drawTargetValue = ReadInt32(process, drawTarget);
            int updateTargetValue = ReadInt32(process, drawTarget + 4);
            if (drawTargetValue < 60 || drawTargetValue > 10000 ||
                updateTargetValue != drawTargetValue) return false;
            double draw = ReadDouble(process, drawTarget + DrawFpsDelta);
            double update = ReadDouble(process, drawTarget + UpdateFpsDelta);
            double drawMs = ReadDouble(process, drawTarget + DrawFrameDelta);
            double updateMs = ReadDouble(process, drawTarget + UpdateFrameDelta);
            return !double.IsNaN(draw) && !double.IsNaN(update) &&
                   draw >= 0 && draw <= 20000 && update >= 0 && update <= 20000 &&
                   drawMs >= 0 && drawMs <= 10000 &&
                   updateMs >= 0 && updateMs <= 10000 &&
                   (draw > 0 || update > 0);
        }

        public static long ResolveDrawTarget(
                IntPtr process, long moduleBase, long moduleSize,
                long rvaHint, long radius) {
            long moduleEnd = moduleBase + moduleSize;
            long start = Math.Max(moduleBase, moduleBase + rvaHint - radius);
            long end = Math.Min(moduleEnd, moduleBase + rvaHint + radius);
            long cursor = start;
            int mbiSize = Marshal.SizeOf(typeof(MEMORY_BASIC_INFORMATION));
            byte[] buffer = new byte[1024 * 1024 + 7];
            while (cursor < end) {
                MEMORY_BASIC_INFORMATION mbi;
                UIntPtr queried = VirtualQueryEx(
                    process, new IntPtr(cursor), out mbi,
                    new UIntPtr((uint)mbiSize));
                if (queried == UIntPtr.Zero) break;
                long regionStart = Math.Max(cursor, mbi.BaseAddress.ToInt64());
                long regionEnd = Math.Min(
                    end, mbi.BaseAddress.ToInt64() +
                         unchecked((long)mbi.RegionSize.ToUInt64()));
                bool committed = mbi.State == 0x1000;
                bool inaccessible = (mbi.Protect & 0x01) != 0 ||
                                    (mbi.Protect & 0x100) != 0;
                if (committed && !inaccessible) {
                    long chunk = regionStart;
                    while (chunk < regionEnd) {
                        int count = (int)Math.Min(1024 * 1024,
                                                  regionEnd - chunk);
                        byte[] current = count == 1024 * 1024
                            ? buffer : new byte[count];
                        IntPtr read;
                        if (ReadProcessMemory(process, new IntPtr(chunk), current,
                                              count, out read)) {
                            int actual = (int)read.ToInt64();
                            for (int i = 0; i + 8 <= actual; ++i) {
                                int first = BitConverter.ToInt32(current, i);
                                if (first < 60 || first > 10000) continue;
                                if (BitConverter.ToInt32(current, i + 4) != first)
                                    continue;
                                long candidate = chunk + i;
                                if (Plausible(process, candidate))
                                    return candidate;
                            }
                        }
                        chunk += count;
                    }
                }
                cursor = Math.Max(cursor + 4096, regionEnd);
            }
            return 0;
        }

        public static long CounterBaseFromDrawTarget(long drawTarget) {
            return drawTarget + DrawFrameDelta;
        }

        private static bool CounterValuesPlausible(
                double drawFrame, double drawFps,
                double updateFrame, double updateFps) {
            if (double.IsNaN(drawFps) || double.IsNaN(updateFps) ||
                drawFps < 1 || drawFps > 5000 ||
                updateFps < 1 || updateFps > 5000 ||
                drawFrame <= 0 || drawFrame > 1000 ||
                updateFrame <= 0 || updateFrame > 1000) return false;
            double ratio = drawFps / updateFps;
            if (ratio < 0.05 || ratio > 20.0) return false;
            double drawProduct = drawFrame * drawFps;
            double updateProduct = updateFrame * updateFps;
            return drawProduct >= 500 && drawProduct <= 2000 &&
                   updateProduct >= 500 && updateProduct <= 2000;
        }

        public static bool CounterBlockStillPlausible(
                IntPtr process, long counterBase) {
            double drawFrame = ReadDouble(process, counterBase);
            double drawFps = ReadDouble(process, counterBase + 8);
            double updateFrame = ReadDouble(process, counterBase + 32);
            double updateFps = ReadDouble(process, counterBase + 40);
            return CounterValuesPlausible(
                drawFrame, drawFps, updateFrame, updateFps);
        }

        public static bool PlausibleCounterBlock(
                IntPtr process, long counterBase) {
            double drawFrame = ReadDouble(process, counterBase);
            double drawFps = ReadDouble(process, counterBase + 8);
            double updateFrame = ReadDouble(process, counterBase + 32);
            double updateFps = ReadDouble(process, counterBase + 40);
            if (!CounterValuesPlausible(
                    drawFrame, drawFps, updateFrame, updateFps)) return false;
            // DataCalc publishes its rolling counters once per 100 ms. A
            // 25 ms re-read can therefore see a perfectly live block as
            // unchanged and reject it during startup. Span one publication
            // interval before applying the live-change check.
            System.Threading.Thread.Sleep(125);
            double drawAgain = ReadDouble(process, counterBase + 8);
            double updateAgain = ReadDouble(process, counterBase + 40);
            double drawFrameAgain = ReadDouble(process, counterBase);
            double updateFrameAgain = ReadDouble(process, counterBase + 32);
            bool changed = drawAgain != drawFps || updateAgain != updateFps ||
                           drawFrameAgain != drawFrame ||
                           updateFrameAgain != updateFrame;
            return changed && CounterValuesPlausible(
                drawFrameAgain, drawAgain, updateFrameAgain, updateAgain);
        }

        public static long ResolveCounterBase(
                IntPtr process, long moduleBase, long moduleSize,
                long rvaHint, long radius) {
            long moduleEnd = moduleBase + moduleSize;
            long hint = moduleBase + rvaHint;
            for (long distance = 0; distance <= radius; distance += 8) {
                long lower = hint - distance;
                if (lower >= moduleBase && lower + 48 <= moduleEnd &&
                    PlausibleCounterBlock(process, lower)) {
                    return lower;
                }
                if (distance == 0) continue;
                long upper = hint + distance;
                if (upper >= moduleBase && upper + 48 <= moduleEnd &&
                    PlausibleCounterBlock(process, upper)) {
                    return upper;
                }
            }
            return 0;
        }

        public static long ResolveCounterBaseFast(
                IntPtr process, long moduleBase, long moduleSize) {
            long moduleEnd = moduleBase + moduleSize;
            long cursor = moduleBase;
            int mbiSize = Marshal.SizeOf(typeof(MEMORY_BASIC_INFORMATION));
            byte[] buffer = new byte[1024 * 1024 + 47];
            while (cursor < moduleEnd) {
                MEMORY_BASIC_INFORMATION mbi;
                UIntPtr queried = VirtualQueryEx(
                    process, new IntPtr(cursor), out mbi,
                    new UIntPtr((uint)mbiSize));
                if (queried == UIntPtr.Zero) break;
                long regionStart = Math.Max(cursor, mbi.BaseAddress.ToInt64());
                long regionEnd = Math.Min(
                    moduleEnd, mbi.BaseAddress.ToInt64() +
                    unchecked((long)mbi.RegionSize.ToUInt64()));
                bool committed = mbi.State == 0x1000;
                bool inaccessible = (mbi.Protect & 0x01) != 0 ||
                                    (mbi.Protect & 0x100) != 0;
                if (committed && !inaccessible) {
                    long chunk = regionStart;
                    while (chunk < regionEnd) {
                        int count = (int)Math.Min(
                            1024 * 1024, regionEnd - chunk);
                        byte[] current = count == 1024 * 1024
                            ? buffer : new byte[count];
                        IntPtr read;
                        if (ReadProcessMemory(process, new IntPtr(chunk),
                                              current, count, out read)) {
                            int actual = (int)read.ToInt64();
                            int alignment = (int)((8 - (chunk & 7)) & 7);
                            for (int i = alignment; i + 48 <= actual; i += 8) {
                                double drawFrame = BitConverter.ToDouble(current, i);
                                double drawFps = BitConverter.ToDouble(current, i + 8);
                                double gcMem = BitConverter.ToDouble(current, i + 16);
                                double appMem = BitConverter.ToDouble(current, i + 24);
                                double updateFrame = BitConverter.ToDouble(current, i + 32);
                                double updateFps = BitConverter.ToDouble(current, i + 40);
                                if (!CounterValuesPlausible(
                                        drawFrame, drawFps,
                                        updateFrame, updateFps)) continue;
                                if (double.IsNaN(gcMem) || double.IsInfinity(gcMem) ||
                                    double.IsNaN(appMem) || double.IsInfinity(appMem) ||
                                    gcMem < 1 || gcMem > 100000 ||
                                    appMem < 1 || appMem > 100000) continue;
                                long candidate = chunk + i;
                                if (PlausibleCounterBlock(process, candidate))
                                    return candidate;
                            }
                        }
                        chunk += count;
                    }
                }
                cursor = Math.Max(cursor + 4096, regionEnd);
            }
            return 0;
        }

        public static double CounterDrawFrame(IntPtr p, long b) {
            return ReadDouble(p, b);
        }
        public static double CounterDrawFps(IntPtr p, long b) {
            return ReadDouble(p, b + 8);
        }
        public static double CounterGcMem(IntPtr p, long b) {
            return ReadDouble(p, b + 16);
        }
        public static double CounterAppMem(IntPtr p, long b) {
            return ReadDouble(p, b + 24);
        }
        public static double CounterUpdateFrame(IntPtr p, long b) {
            return ReadDouble(p, b + 32);
        }
        public static double CounterUpdateFps(IntPtr p, long b) {
            return ReadDouble(p, b + 40);
        }
        public static double CounterUpdateLowFps(IntPtr p, long b) {
            return ReadDouble(p, b - 0x68);
        }
        public static double CounterDrawLowFps(IntPtr p, long b) {
            return ReadDouble(p, b - 0x90);
        }
        public static double CounterUpdateWorstFrame(IntPtr p, long b) {
            return ReadDouble(p, b - 0x70);
        }
        public static double CounterDrawWorstFrame(IntPtr p, long b) {
            return ReadDouble(p, b - 0x98);
        }

        public static double DrawFrame(IntPtr p, long t) {
            return ReadDouble(p, t + DrawFrameDelta);
        }
        public static double DrawFps(IntPtr p, long t) {
            return ReadDouble(p, t + DrawFpsDelta);
        }
        public static double UpdateFrame(IntPtr p, long t) {
            return ReadDouble(p, t + UpdateFrameDelta);
        }
        public static double UpdateFps(IntPtr p, long t) {
            return ReadDouble(p, t + UpdateFpsDelta);
        }
    }
}
'@
}

$process = Get-Process -Id $TargetProcessId -ErrorAction Stop
$moduleBase = $process.MainModule.BaseAddress.ToInt64()
$moduleSize = [int64]$process.MainModule.ModuleMemorySize
$handle = [NovaFlareFrameMonitor.Native]::OpenProcess(0x410, $false, $TargetProcessId)
if ($handle -eq [IntPtr]::Zero) {
    throw "OpenProcess failed: $([Runtime.InteropServices.Marshal]::GetLastWin32Error())"
}

$writer = [IO.StreamWriter]::new($csvPath, $false, [Text.UTF8Encoding]::new($false))
try {
    $writer.WriteLine('sample,elapsed_ms,utc,tps,fps,update_ms,draw_ms,gc_used_mb,app_private_mb,update_low_fps,draw_low_fps,update_worst_ms,draw_worst_ms')
    $writer.Flush()
    $counterBase = $moduleBase + $CounterBaseRvaHint
    if (-not [NovaFlareFrameMonitor.Native]::PlausibleCounterBlock(
            $handle, $counterBase)) {
        $counterBase = 0L
    }
    # On a cold start DataCalc is created only after the large asset bootstrap.
    # Keep process/GC monitoring active and wait for the first real counter
    # publication instead of giving up before the title screen exists.
    $resolveDeadline = [DateTime]::UtcNow.AddSeconds(240)
    do {
        $counterBase = [NovaFlareFrameMonitor.Native]::ResolveCounterBaseFast(
            $handle, $moduleBase, $moduleSize)
        if ($counterBase -eq 0) {
            # Generated hxcpp static RVAs move whenever compiled classes change.
            # Scan committed module pages in large blocks for the adjacent
            # draw/update target-FPS fields, then derive DataCalc's counter
            # block using the stable generated-data layout.
            $drawTarget = [NovaFlareFrameMonitor.Native]::ResolveDrawTarget(
                $handle, $moduleBase, $moduleSize,
                [int64]($moduleSize / 2), [int64]$moduleSize)
            if ($drawTarget -ne 0) {
                $candidate = [NovaFlareFrameMonitor.Native]::CounterBaseFromDrawTarget(
                    $drawTarget)
                if ([NovaFlareFrameMonitor.Native]::PlausibleCounterBlock(
                        $handle, $candidate)) {
                    $counterBase = $candidate
                }
            }
        }
        if ($counterBase -eq 0) { Start-Sleep -Milliseconds 250 }
    } while ($counterBase -eq 0 -and [DateTime]::UtcNow -lt $resolveDeadline)
    if ($counterBase -eq 0) {
        throw 'Could not resolve live FPS/TPS counters near the generated-data RVA'
    }

    $started = [Diagnostics.Stopwatch]::StartNew()
    $sample = 0
    $counterInvalid = $false
    while ($started.Elapsed.TotalSeconds -lt $MaximumSeconds -and
           (Get-Process -Id $TargetProcessId -ErrorAction SilentlyContinue)) {
        if (($sample % 40) -eq 0 -and
            -not [NovaFlareFrameMonitor.Native]::CounterBlockStillPlausible(
                $handle, $counterBase)) {
            $counterInvalid = $true
            break
        }
        $sample++
        $row = @(
            $sample,
            [Math]::Round($started.Elapsed.TotalMilliseconds, 3),
            [DateTime]::UtcNow.ToString('o'),
            [Math]::Round([NovaFlareFrameMonitor.Native]::CounterUpdateFps($handle, $counterBase), 3),
            [Math]::Round([NovaFlareFrameMonitor.Native]::CounterDrawFps($handle, $counterBase), 3),
            [Math]::Round([NovaFlareFrameMonitor.Native]::CounterUpdateFrame($handle, $counterBase), 6),
            [Math]::Round([NovaFlareFrameMonitor.Native]::CounterDrawFrame($handle, $counterBase), 6),
            [Math]::Round([NovaFlareFrameMonitor.Native]::CounterGcMem($handle, $counterBase), 3),
            [Math]::Round([NovaFlareFrameMonitor.Native]::CounterAppMem($handle, $counterBase), 3),
            [Math]::Round([NovaFlareFrameMonitor.Native]::CounterUpdateLowFps($handle, $counterBase), 3),
            [Math]::Round([NovaFlareFrameMonitor.Native]::CounterDrawLowFps($handle, $counterBase), 3),
            [Math]::Round([NovaFlareFrameMonitor.Native]::CounterUpdateWorstFrame($handle, $counterBase), 6),
            [Math]::Round([NovaFlareFrameMonitor.Native]::CounterDrawWorstFrame($handle, $counterBase), 6)
        )
        $writer.WriteLine(($row -join ','))
        if (($sample % 40) -eq 0) { $writer.Flush() }
        Start-Sleep -Milliseconds $IntervalMilliseconds
    }
    $writer.Flush()
    [IO.File]::WriteAllText(
        $statusPath,
        "state=$(if($counterInvalid){'invalid-counter-block'}else{'complete'})`r`nsamples=$sample`r`ncounter_base_rva=0x$(($counterBase - $moduleBase).ToString('x'))`r`n",
        [Text.UTF8Encoding]::new($false))
}
finally {
    $writer.Dispose()
    [void][NovaFlareFrameMonitor.Native]::CloseHandle($handle)
}
