[CmdletBinding()]
param([switch]$SkipGeneration)

$ErrorActionPreference = 'Stop'
$workspace = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$buildRoot = Join-Path $workspace '_build/nf-gameplay-regressions'
New-Item -ItemType Directory -Path $buildRoot -Force | Out-Null
Push-Location $workspace
try {
    # Use current library paths rather than a previously generated release.hxml.
    if (-not $SkipGeneration) {
        $hxml = & haxelib run lime display windows -final
        if ($LASTEXITCODE -ne 0) { throw 'lime display failed' }
        $hxml += '-cp tools/tests/nf_gameplay'
        $hxml += '--macro RegressionBoot.install()'
        $hxml += '-D no-compilation'
        $hxmlPath = Join-Path $buildRoot 'native.hxml'
        [IO.File]::WriteAllLines($hxmlPath, [string[]]$hxml)
        & haxe $hxmlPath *> (Join-Path $buildRoot 'generate.log')
        if ($LASTEXITCODE -ne 0) { throw "Haxe generation failed; see $buildRoot/generate.log" }
    }

    # Reuse the normal native object cache, without replacing the game in bin.
    $objectRoot = Join-Path $workspace 'export/release/windows/obj'
    $optionsPath = Join-Path $buildRoot 'Options.txt'
    Get-Content (Join-Path $objectRoot 'Options.txt') |
        Where-Object { $_ -notmatch '^no_compilation=' } |
        Set-Content -LiteralPath $optionsPath
    # Match Lime's normal Windows executable cache (display omits this flag).
    Add-Content -LiteralPath $optionsPath -Value 'no_console=1'
    Push-Location $objectRoot
    try {
        & haxelib run hxcpp Build.xml -options $optionsPath *> (Join-Path $buildRoot 'build.log')
        if ($LASTEXITCODE -ne 0) { throw "Native build failed; see $buildRoot/build.log" }
    } finally { Pop-Location }

    $videoPath = Join-Path $buildRoot 'fixture.mp4'
    & ffmpeg -hide_banner -loglevel error -y -f lavfi -i 'color=c=blue:s=64x64:r=30' -t 8 -c:v libx264 -pix_fmt yuv420p $videoPath
    if ($LASTEXITCODE -ne 0) { throw 'ffmpeg fixture generation failed' }

    $previousVideo = $env:NOVAFLARE_REGRESSION_VIDEO
    $previousPath = $env:PATH
    $previousPlugins = $env:VLC_PLUGIN_PATH
    try {
        $env:NOVAFLARE_REGRESSION_VIDEO = $videoPath
        $env:PATH = (Join-Path $workspace 'export/release/windows/bin') + ';' + $env:PATH
        $env:VLC_PLUGIN_PATH = Join-Path $workspace 'export/release/windows/bin/plugins'
        $logPath = Join-Path $buildRoot 'runtime.log'
        $process = Start-Process -FilePath (Join-Path $objectRoot 'ApplicationMain.exe') `
            -WorkingDirectory (Join-Path $workspace 'export/release/windows/bin') `
            -WindowStyle Hidden -PassThru -RedirectStandardOutput $logPath `
            -RedirectStandardError (Join-Path $buildRoot 'runtime.stderr.log')
        if (-not $process.WaitForExit(45000)) {
            Stop-Process -Id $process.Id
            throw 'Native regression checks timed out'
        }
        $process.WaitForExit()
        $process.Refresh()
        $log = Get-Content -LiteralPath $logPath -Raw
        Get-Content -LiteralPath $logPath -Tail 35
        if ($process.ExitCode -ne 0 -or $log -notmatch '\[NF regression\] ALL CHECKS PASSED') {
            throw "Native regression checks failed; see $buildRoot/runtime.log"
        }
    } finally {
        $env:NOVAFLARE_REGRESSION_VIDEO = $previousVideo
        $env:PATH = $previousPath
        $env:VLC_PLUGIN_PATH = $previousPlugins
    }
} finally { Pop-Location }
