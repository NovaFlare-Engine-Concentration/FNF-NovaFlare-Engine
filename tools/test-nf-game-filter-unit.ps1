[CmdletBinding()]
param()
$ErrorActionPreference = 'Stop'
$workspace = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$fixture = Join-Path $workspace 'tools/tests/nf_game_filters'
$build = Join-Path $workspace '_build/nf-global-filter-unit'
New-Item -ItemType Directory -Force -Path (Join-Path $build 'general/shaders') | Out-Null
$source = Join-Path $workspace 'source/general/shaders/ColorblindFilter.hx'
Copy-Item -LiteralPath $source -Destination (Join-Path $build 'general/shaders/ColorblindFilter.hx') -Force
if ((Get-FileHash -LiteralPath $source).Hash -ne (Get-FileHash -LiteralPath (Join-Path $build 'general/shaders/ColorblindFilter.hx')).Hash) { throw 'Test copy does not match production source.' }
Push-Location $workspace
try {
  & haxe -cp $fixture -cp $build -main Main --interp
  if ($LASTEXITCODE -ne 0) { throw 'Global filter preservation regression failed.' }
} finally { Pop-Location }
