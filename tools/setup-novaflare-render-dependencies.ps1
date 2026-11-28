[CmdletBinding()]
param(
    [ValidateSet('Timeline', 'Resolution', 'AndroidHints', 'GcBreakdown', 'RenderAttachmentTrace', 'VSync', 'FocusCadence', 'VirtualPointer', 'RenderState', 'GenerationalGC', 'ImmixReclaim', 'ImmixMark', 'RenderThreadRepair', 'ImageCoordinates', 'Android16K', 'CairoGC')]
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
    if ('CairoGC' -in $Component) {
        $lime = Find-DependencyRoot 'lime' 'project/Build.xml'
        Install-DependencyPatch $lime 'lime-cairo-handle-registry.patch' ''
        $Component = @($Component | Where-Object { $_ -ne 'CairoGC' })
        if ($Component.Count -eq 0) { return }
    }
    if ('Android16K' -in $Component) {
        $runtime = Find-DependencyRoot 'hxcpp' 'toolchain/android-toolchain-clang.xml'
        Install-DependencyPatch $runtime 'hxcpp-android-16k.patch' ''
        $lime = Find-DependencyRoot 'lime' 'project/Build.xml'
        Install-DependencyPatch $lime 'lime-android-16k.patch' ''
        $Component = @($Component | Where-Object { $_ -ne 'Android16K' })
        if ($Component.Count -eq 0) { return }
    }
    if ('ImageCoordinates' -in $Component) {
        $flixel = Find-DependencyRoot 'flixel' 'flixel/graphics/FlxGraphic.hx'
        Install-DependencyPatch $flixel 'flixel-image-frame-coordinates.patch' ''
        $lime = Find-DependencyRoot 'lime' 'project/Build.xml'
        $sideRatioPatch = 'lime-image-compression-side-ratio.patch'
        if (-not (Test-DependencyPatch $lime $sideRatioPatch)) {
            Install-DependencyPatch $lime 'lime-scaled-image-decode.patch' ''
            Install-DependencyPatch $lime $sideRatioPatch ''
        }
        $Component = @($Component | Where-Object { $_ -ne 'ImageCoordinates' })
        if ($Component.Count -eq 0) { return }
    }
    $immixComponents = @('GenerationalGC', 'ImmixReclaim', 'ImmixMark')
    if (@($Component | Where-Object { $_ -in $immixComponents }).Count -gt 0) {
        $runtime = Find-DependencyRoot 'hxcpp' 'src/hx/gc/Immix.cpp'
        $revision = & git -C $runtime rev-parse HEAD
        if ($LASTEXITCODE -ne 0) { throw "Could not identify the selected hxcpp checkout: $runtime" }
        if ($revision -eq 'c3494237281cb5fd81042da9a312bc3ee2160371') {
            & git -C $runtime diff --quiet HEAD -- src/hx/gc/Immix.cpp include/hx/GC.h toolchain/common-defines.xml
            if ($LASTEXITCODE -ne 0) { throw "Integrated Immix sources differ from the pinned hxcpp revision in $runtime" }
            Write-Output "Verified integrated NovaFlare Immix patches in $runtime"
        } else {
            $supportedRevisions = @(
                '3f50506ae47aa801fd7e8ef7636ea2dd80b73254'
                'ac2af3cdc20ce3173b26a56d845a264b0a372ac3'
            )
            if ($revision -notin $supportedRevisions) {
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
        }
        $Component = @($Component | Where-Object { $_ -notin $immixComponents })
        if ($Component.Count -eq 0) { return }
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
    $androidRenderPacingPatch = 'lime-android-render-pacing.patch'
    $androidDeadlinePhasePatch = 'lime-android-deadline-phase.patch'
    $androidRenderRetryPatch = 'lime-android-render-retry.patch'
    $androidRenderRetryInstalled = Test-DependencyPatch $lime $androidRenderRetryPatch
    $backpressureInstalled = $androidRenderRetryInstalled -or (Test-DependencyPatch $lime $androidRenderPacingPatch) -or (Test-DependencyPatch $lime $backpressurePatch)
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
        Install-DependencyPatch $openfl 'openfl-stage-filter-scale.patch' ''
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
    if (!$androidRenderRetryInstalled) { Install-DependencyPatch $lime 'lime-render-thread-build-dependencies.patch' '' }
    if ('RenderThreadRepair' -in $Component) {
        if (!$cadenceInstalled) { Install-DependencyPatch $lime $threadRepairPatch '' }
        if ($backpressureInstalled) {
            Write-Output "Already applied $backpressurePatch in $lime"
        } else {
            Install-DependencyPatch $lime $cadencePatch ''
            Install-DependencyPatch $lime $backpressurePatch ''
        }
        if (!$androidRenderRetryInstalled) { Install-DependencyPatch $lime $androidRenderPacingPatch '' }
        Install-DependencyPatch $lime $androidDeadlinePhasePatch ''
        Install-DependencyPatch $lime $androidRenderRetryPatch ''
        $threadedMeshPatch = 'lime-threaded-mesh-upload.patch'
        $threadedShaderPatch = 'lime-threaded-shader-inputs.patch'
        $limeShaderTicketPatch = 'lime-shader-param-ticket-reuse.patch'
        $limeCompactQuadPatch = 'lime-compact-quad-shader-attributes.patch'
        $limeProjectionPatch = 'lime-threaded-projection-matrix.patch'
        $limeProjectionInstalled = Test-DependencyPatch $lime $limeProjectionPatch
        $limeCompactQuadInstalled = $limeProjectionInstalled -or (Test-DependencyPatch $lime $limeCompactQuadPatch)
        $limeShaderTicketInstalled = $limeCompactQuadInstalled -or (Test-DependencyPatch $lime $limeShaderTicketPatch)
        if (!$limeShaderTicketInstalled -and !(Test-DependencyPatch $lime $threadedShaderPatch)) {
            if (!(Test-DependencyPatch $lime $threadedMeshPatch)) {
                Install-DependencyPatch $lime 'lime-threaded-quad-upload.patch' ''
            }
            Install-DependencyPatch $lime $threadedMeshPatch ''
        }
        if (!$limeShaderTicketInstalled) { Install-DependencyPatch $lime $threadedShaderPatch '' }
        if (!$limeCompactQuadInstalled) { Install-DependencyPatch $lime $limeShaderTicketPatch '' }
        if (!$limeProjectionInstalled) { Install-DependencyPatch $lime $limeCompactQuadPatch '' }
        Install-DependencyPatch $lime $limeProjectionPatch ''
        $openfl = Find-DependencyRoot 'openfl' 'src/openfl/display3D/textures/TextureBase.hx'
        Install-DependencyPatch $openfl 'openfl-queued-texture-upload.patch' ''
        $threadedQuadPatch = 'openfl-threaded-quad-upload.patch'
        $threadedTrianglePatch = 'openfl-threaded-triangle-upload.patch'
        $threadedTilePatch = 'openfl-threaded-tile-upload.patch'
        if (!(Test-DependencyPatch $openfl $threadedTrianglePatch) -and !(Test-DependencyPatch $openfl $threadedTilePatch)) {
            if (!(Test-DependencyPatch $openfl $threadedQuadPatch)) {
                Install-DependencyPatch $openfl 'openfl-quad-upload-size.patch' ''
            }
            Install-DependencyPatch $openfl $threadedQuadPatch ''
        }
        Install-DependencyPatch $openfl $threadedTrianglePatch ''
        Install-DependencyPatch $openfl $threadedTilePatch ''
        $openflShaderTicketPatch = 'openfl-shader-param-ticket-reuse.patch'
        $openflCompactQuadPatch = 'openfl-compact-quad-shader-attributes.patch'
        $openflProjectionPatch = 'openfl-threaded-projection-matrix.patch'
        if (!(Test-DependencyPatch $openfl $openflProjectionPatch)) {
            if (!(Test-DependencyPatch $openfl $openflCompactQuadPatch)) {
                if (!(Test-DependencyPatch $openfl $openflShaderTicketPatch)) {
                    Install-DependencyPatch $openfl 'openfl-threaded-shader-inputs.patch' ''
                }
                Install-DependencyPatch $openfl $openflShaderTicketPatch ''
            }
            Install-DependencyPatch $openfl $openflCompactQuadPatch ''
        }
        Install-DependencyPatch $openfl 'openfl-threaded-uniform-matrix.patch' ''
        Install-DependencyPatch $openfl $openflProjectionPatch ''
        $flixel = Find-DependencyRoot 'flixel' 'flixel/FlxG.hx'
        Install-DependencyPatch $flixel 'flixel-render-cadence.patch' ''
        Install-DependencyPatch $flixel 'flixel-compact-quad-shader-attributes.patch' ''
    }
}
finally {
    Pop-Location
}
