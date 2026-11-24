[CmdletBinding()]
param(
    [ValidateSet('Timeline', 'Resolution', 'AndroidHints', 'GcBreakdown', 'RenderAttachmentTrace', 'VSync', 'FocusCadence', 'VirtualPointer', 'RenderState', 'GenerationalGC', 'ImmixReclaim', 'ImmixMark', 'RenderThreadRepair', 'ImageCoordinates')]
    [string[]]$Component = @('Resolution')
)

$ErrorActionPreference = 'Stop'
$workspace = Split-Path -Parent $PSScriptRoot

function Find-DependencyRoot([string]$name, [string]$marker) {
    foreach ($line in (& haxelib path $name)) {
        if ([string]::IsNullOrWhiteSpace($line) -or $line.StartsWith('-')) { continue }
        $candidate = $line.Trim()
        foreach ($root in @($candidate, (Split-Path -Parent $candidate))) {
            if ($root -and (Test-Path -LiteralPath (Join-Path $root $marker) -PathType Leaf)) {
                return (Resolve-Path -LiteralPath $root).Path
            }
        }
    }
    throw "Could not find the selected $name checkout. Run hmm install in the project first."
}

function Test-DependencyPatch([string]$root, [string]$patchName) {
    $previousErrorAction = $ErrorActionPreference
    try {
        $ErrorActionPreference = 'Continue'
        & git -C $root apply --reverse --check (Join-Path $PSScriptRoot $patchName) 2>$null
        return ($LASTEXITCODE -eq 0)
    }
    finally {
        $ErrorActionPreference = $previousErrorAction
    }
}

function Install-DependencyPatch([string]$root, [string]$patchName, [string]$marker) {
    $patch = Join-Path $PSScriptRoot $patchName
    if ($marker -and (Test-Path -LiteralPath (Join-Path $root $marker) -PathType Leaf)) {
        & git -C $root apply --reverse --check `
            '--include=project/include/graphics/FrameTimeline.h' `
            '--include=project/src/graphics/FrameTimeline.cpp' $patch
        if ($LASTEXITCODE -ne 0) { throw "The installed $patchName schema differs from $patch in $root" }
        Write-Output "Verified $patchName schema in $root"
        return
    }
    if (Test-DependencyPatch $root $patchName) {
        Write-Output "Already applied $patchName in $root"
        return
    }
    & git -C $root apply --check $patch
    if ($LASTEXITCODE -ne 0) { throw "Patch $patchName does not match $root" }
    & git -C $root apply --whitespace=nowarn $patch
    if ($LASTEXITCODE -ne 0) { throw "Could not apply $patchName in $root" }
    Write-Output "Applied $patchName in $root"
}

Push-Location $workspace
try {
    if ('ImageCoordinates' -in $Component) {
        $flixel = Find-DependencyRoot 'flixel' 'flixel/graphics/FlxGraphic.hx'
        Install-DependencyPatch $flixel 'flixel-image-frame-coordinates.patch' ''
        $lime = Find-DependencyRoot 'lime' 'project/Build.xml'
        Install-DependencyPatch $lime 'lime-scaled-image-decode.patch' ''
        $Component = @($Component | Where-Object { $_ -ne 'ImageCoordinates' })
        if ($Component.Count -eq 0) { return }
    }
    if ('GenerationalGC' -in $Component -or 'ImmixReclaim' -in $Component -or 'ImmixMark' -in $Component) {
        $runtime = Find-DependencyRoot 'hxcpp' 'src/hx/gc/Immix.cpp'
        $supportedRevisions = @(
            '3f50506ae47aa801fd7e8ef7636ea2dd80b73254'
            'ac2af3cdc20ce3173b26a56d845a264b0a372ac3'
        )
        $revision = & git -C $runtime rev-parse HEAD
        if ($LASTEXITCODE -ne 0 -or $revision -notin $supportedRevisions) {
            throw "The Immix patches require the pinned NovaFlare hxcpp checkout. Run hmm install. Found: $revision"
        }
        if ('GenerationalGC' -in $Component) {
            Install-DependencyPatch $runtime 'hxcpp-immix-generational-preference.patch' ''
        }
        if ('ImmixReclaim' -in $Component) {
            Install-DependencyPatch $runtime 'hxcpp-immix-reclaim.patch' ''
        }
        if ('ImmixMark' -in $Component) {
            Install-DependencyPatch $runtime 'hxcpp-immix-mark.patch' ''
        }
        if (@($Component | Where-Object { $_ -notin @('GenerationalGC', 'ImmixReclaim', 'ImmixMark') }).Count -eq 0) { return }
    }
    $lime = Find-DependencyRoot 'lime' 'project/Build.xml'
    $asyncTimelinePatch = 'lime-frame-timeline-async.patch'
    if (Test-DependencyPatch $lime $asyncTimelinePatch) {
        & git -C $lime apply --reverse --check '--include=project/include/graphics/FrameTimeline.h' `
            (Join-Path $PSScriptRoot 'lime-frame-timeline.patch')
        if ($LASTEXITCODE -ne 0) { throw "The installed frame timeline header differs in $lime" }
        Write-Output "Already applied $asyncTimelinePatch in $lime"
    } else {
        Install-DependencyPatch $lime 'lime-frame-timeline.patch' 'project/include/graphics/FrameTimeline.h'
        Install-DependencyPatch $lime $asyncTimelinePatch ''
    }
    $threadRepairPatch = 'lime-render-thread-repair.patch'
    $cadencePatch = 'lime-render-cadence.patch'
    $backpressurePatch = 'lime-vsync-render-backpressure.patch'
    $backpressureInstalled = Test-DependencyPatch $lime $backpressurePatch
    $cadenceInstalled = $backpressureInstalled -or (Test-DependencyPatch $lime $cadencePatch)
    $threadRepairInstalled = $cadenceInstalled -or (Test-DependencyPatch $lime $threadRepairPatch)
    $installThreadRepair = 'RenderThreadRepair' -in $Component -and !$threadRepairInstalled
    if ('Timeline' -in $Component -or 'GcBreakdown' -in $Component) {
        $runtime = Find-DependencyRoot 'hxcpp' 'src/hx/gc/Immix.cpp'
        $breakdownPatch = 'hxcpp-immix-gc-breakdown.patch'
        if (Test-DependencyPatch $runtime $breakdownPatch) {
            Write-Output "Already applied $breakdownPatch in $runtime"
        } else {
            Install-DependencyPatch $runtime 'hxcpp-immix-frame-timeline.patch' ''
            if ('GcBreakdown' -in $Component) { Install-DependencyPatch $runtime $breakdownPatch '' }
        }
    }
    if (!$threadRepairInstalled -and ('Resolution' -in $Component -or $installThreadRepair)) {
        Install-DependencyPatch $lime 'lime-render-target-query.patch' ''
    }
    if ('Resolution' -in $Component) {
        $openfl = Find-DependencyRoot 'openfl' 'src/openfl/display/Stage.hx'
        Install-DependencyPatch $openfl 'openfl-stage-render-target.patch' ''
    }
    if ('RenderAttachmentTrace' -in $Component) {
        $openfl = Find-DependencyRoot 'openfl' 'src/openfl/display/BitmapData.hx'
        Install-DependencyPatch $openfl 'openfl-bitmap-depth-trace.patch' ''
    }
    if (!$threadRepairInstalled -and ('AndroidHints' -in $Component -or $installThreadRepair)) {
        $hintPreferencePatch = 'lime-android-performance-hint-preference.patch'
        if (Test-DependencyPatch $lime $hintPreferencePatch) {
            Write-Output "Already applied $hintPreferencePatch in $lime"
        } else {
            Install-DependencyPatch $lime 'lime-android-performance-hints.patch' ''
            Install-DependencyPatch $lime $hintPreferencePatch ''
        }
        Install-DependencyPatch $lime 'lime-android-adpf-frame-cycles.patch' ''
    }
    if (!$threadRepairInstalled -and ('VSync' -in $Component -or $installThreadRepair)) {
        Install-DependencyPatch $lime 'lime-swap-interval-owner.patch' ''
    }
    if ('FocusCadence' -in $Component) {
        $flixel = Find-DependencyRoot 'flixel' 'flixel/FlxGame.hx'
        Install-DependencyPatch $flixel 'flixel-focus-draw-rate.patch' ''
    }
    if ('VirtualPointer' -in $Component) {
        Install-DependencyPatch $lime 'lime-sdl-touch-mouse-filter.patch' ''
    }
    if (!$threadRepairInstalled -and ('RenderState' -in $Component -or $installThreadRepair)) {
        Install-DependencyPatch $lime 'lime-render-state-per-batch.patch' ''
    }
    if ('RenderState' -in $Component) {
        $openfl = Find-DependencyRoot 'openfl' 'src/openfl/display3D/textures/TextureBase.hx'
        Install-DependencyPatch $openfl 'openfl-sampler-binding.patch' ''
        Install-DependencyPatch $openfl 'openfl-shader-buffer-overwrite.patch' ''
    }
    Install-DependencyPatch $lime 'lime-render-thread-build-dependencies.patch' ''
    if ('RenderThreadRepair' -in $Component) {
        if (!$cadenceInstalled) { Install-DependencyPatch $lime $threadRepairPatch '' }
        if ($backpressureInstalled) {
            Write-Output "Already applied $backpressurePatch in $lime"
        } else {
            Install-DependencyPatch $lime $cadencePatch ''
            Install-DependencyPatch $lime $backpressurePatch ''
        }
        $openfl = Find-DependencyRoot 'openfl' 'src/openfl/display3D/textures/TextureBase.hx'
        Install-DependencyPatch $openfl 'openfl-queued-texture-upload.patch' ''
        Install-DependencyPatch $openfl 'openfl-quad-upload-size.patch' ''
        $flixel = Find-DependencyRoot 'flixel' 'flixel/FlxG.hx'
        Install-DependencyPatch $flixel 'flixel-render-cadence.patch' ''
    }
}
finally {
    Pop-Location
}
