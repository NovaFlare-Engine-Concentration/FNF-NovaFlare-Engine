$ErrorActionPreference = 'Stop'
$workspace = Split-Path -Parent $PSScriptRoot
$stagedSource = Join-Path $workspace '_build/image-compression-test/source'
$modules = @('general/backend/ImageCompression.hx', 'general/backend/macros/ImageCompressionMacro.hx')

foreach ($module in $modules) {
    $target = Join-Path $stagedSource $module
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $target) | Out-Null
    Copy-Item -LiteralPath (Join-Path $workspace "source/$module") -Destination $target -Force
}

Push-Location $workspace
try {
    & haxelib run lime test tools/tests/image-compression/Project.xml neko
    if ($LASTEXITCODE -ne 0) { throw "Image compression test exited with $LASTEXITCODE" }
} finally {
    Pop-Location
}
