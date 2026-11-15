# Experimental follow-up to hxcpp-origin-cppia.patch (upstream 2c38e141).
# Roll back this patch before camera-defaults, notestyle, null-args and base CPPIA patches.
[CmdletBinding()]
param(
  [Parameter(Mandatory = $true)] [string]$HxcppRoot,
  [ValidateSet('Check', 'Install', 'Verify', 'Rollback')] [string]$Action = 'Check'
)
$ErrorActionPreference = 'Stop'
$HxcppRoot = (Resolve-Path -LiteralPath $HxcppRoot).Path
$patch = Join-Path $PSScriptRoot 'hxcpp-origin-cppia-notestyle-zero.patch'
if ((Get-FileHash -LiteralPath $patch -Algorithm SHA256).Hash -ne '2EDB401E18181DCC353A30DC6861FF86E981C07A947080E7B1935F487EE9C1A1') { throw 'Unexpected patch contents.' }
$profiles = @(
  ,@('src/hx/cppia/Cppia.cpp','42e11f1512ef21753a512ffec970da8cec54628b91719e8631d97a793b2540f3','25f2c253c6932009c28cbabeab9a1e62471e81681140849453990473e0f54da2')
)
function Get-NormalizedHash([string]$Path) {
  $bytes = [IO.File]::ReadAllBytes($Path)
  $text = [Text.UTF8Encoding]::new($false, $true).GetString($bytes).Replace("`r`n", "`n")
  $sha = [Security.Cryptography.SHA256]::Create()
  try { return ([BitConverter]::ToString($sha.ComputeHash([Text.Encoding]::UTF8.GetBytes($text)))).Replace('-', '').ToLowerInvariant() }
  finally { $sha.Dispose() }
}
function Get-ProfileState {
  $states = @($profiles | ForEach-Object {
    $hash = Get-NormalizedHash (Join-Path $HxcppRoot $_[0])
    if ($hash -eq $_[1]) { 'original' } elseif ($hash -eq $_[2]) { 'patched' } else { throw "Unexpected source contents: $($_[0]); preserving local changes." }
  } | Select-Object -Unique)
  if ($states.Count -ne 1) { throw 'Mixed original and patched files; preserving local changes.' }
  return $states[0]
}
$state = Get-ProfileState
if ($Action -eq 'Check') { Write-Output "CPPIA runtime profile: $state"; return }
if ($Action -eq 'Verify') { if ($state -ne 'patched') { throw 'CPPIA patch is not installed.' }; Write-Output 'CPPIA patch verified.'; return }
$rootHash = [Security.Cryptography.SHA256]::Create()
try { $identity = ([BitConverter]::ToString($rootHash.ComputeHash([Text.Encoding]::UTF8.GetBytes($HxcppRoot.ToLowerInvariant())))).Replace('-', '').Substring(0, 16) }
finally { $rootHash.Dispose() }
$backup = Join-Path (Split-Path -Parent $PSScriptRoot) "_build/hxcpp-cppia-notestyle-zero-backup-$identity"
if ($Action -eq 'Rollback') {
  if ($state -eq 'original') { Write-Output 'Already original.'; return }
  $manifestPath = Join-Path $backup 'manifest.json'
  if (-not (Test-Path -LiteralPath $manifestPath)) { throw 'Exact backup manifest is missing.' }
  $manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
  foreach ($entry in $profiles) {
    $saved = Join-Path $backup $entry[0]
    if ((Get-NormalizedHash $saved) -ne $entry[1] -or (Get-FileHash -LiteralPath $saved).Hash -ne $manifest.($entry[0])) { throw "Missing or changed backup: $($entry[0])" }
  }
  foreach ($entry in $profiles) { Copy-Item -LiteralPath (Join-Path $backup $entry[0]) -Destination (Join-Path $HxcppRoot $entry[0]) -Force }
  if ((Get-ProfileState) -ne 'original') { throw 'Rollback verification failed.' }
  Write-Output 'Original files restored.'; return
}
if ($state -eq 'patched') { Write-Output 'Already patched.'; return }
& git -C $HxcppRoot apply --check $patch
if ($LASTEXITCODE -ne 0) { throw 'Patch check failed; files were not changed.' }
foreach ($entry in $profiles) {
  $saved = Join-Path $backup $entry[0]
  if (Test-Path -LiteralPath $saved) { if ((Get-FileHash -LiteralPath $saved).Hash -ne (Get-FileHash -LiteralPath (Join-Path $HxcppRoot $entry[0])).Hash) { throw "Existing backup differs: $saved" } }
  else { New-Item -ItemType Directory -Force -Path (Split-Path -Parent $saved) | Out-Null; Copy-Item -LiteralPath (Join-Path $HxcppRoot $entry[0]) -Destination $saved }
}
$manifestPath = Join-Path $backup 'manifest.json'
$expectedManifest = [ordered]@{}
foreach ($entry in $profiles) { $expectedManifest[$entry[0]] = (Get-FileHash -LiteralPath (Join-Path $backup $entry[0])).Hash }
if (Test-Path -LiteralPath $manifestPath) {
  $manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
  foreach ($entry in $profiles) { if ($manifest.($entry[0]) -ne $expectedManifest[$entry[0]]) { throw "Existing backup manifest differs: $($entry[0])" } }
} else { $expectedManifest | ConvertTo-Json | Set-Content -LiteralPath $manifestPath -Encoding utf8 }
try {
  & git -C $HxcppRoot apply $patch
  if ($LASTEXITCODE -ne 0 -or (Get-ProfileState) -ne 'patched') { throw 'Patch installation verification failed.' }
} catch {
  foreach ($entry in $profiles) { Copy-Item -LiteralPath (Join-Path $backup $entry[0]) -Destination (Join-Path $HxcppRoot $entry[0]) -Force }
  throw
}
Write-Output "Experimental CPPIA patch installed; originals saved at $backup. Rebuild and validate before use."
