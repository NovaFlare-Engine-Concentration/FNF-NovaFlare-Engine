[CmdletBinding()]
param(
  [Parameter(Mandatory = $true)] [string]$HxcppRoot,
  [ValidateSet('Check', 'Install', 'Verify', 'Rollback')] [string]$Action = 'Check'
)
$ErrorActionPreference = 'Stop'
$HxcppRoot = (Resolve-Path -LiteralPath $HxcppRoot).Path
$patch = Join-Path $PSScriptRoot 'hxcpp-origin-cppia.patch'
if ((Get-FileHash -LiteralPath $patch -Algorithm SHA256).Hash -ne '1A1861EBEBAD23580E4DCE21CA115BD82B5A4234BA5E600224E8EE6E3615F38D') { throw 'Unexpected patch contents.' }
$profiles = @(
  @('include/hx/Scriptable.h','8713852a4cb19b7e3b84a980f367d7ec8a6ad72679df55063bdf6d68e5471dc3','5e9ebbc1c363ab6b50a260199c6c6bbc8c0a850e82ceda1a3dc8e863f02c5263'),
  @('src/hx/cppia/Cppia.h','4f47b7415da9ecd0d5a979b78c868d6b2b662bd3b1ac4265f794942630cfb0ba','f08ad1559b51dd5193365d8fd0a4ddc966333e99f8aae0fce5cb3e68ccb3aecd'),
  @('src/hx/cppia/Cppia.cpp','43b98fd10507e6e08a6c19ec0460f40562fc8b7436d94f481f7cadd6132bd735','7b4c6b4b5681009287d9481ac2735424ada7e4236677758395a5e78d80fd3761'),
  @('src/hx/cppia/CppiaClasses.cpp','60ca410f4a2ebcec4af9dfc8c0ef658433f9b78480667e7526b5f6519c6d5a9f','634a2a5e64d2773462ac5b42f4b57e4d10875d81082912d85526fec990dd60b3'),
  @('src/hx/cppia/CppiaFunction.cpp','b8841a7f18c318b7f37b332b2b00c78cc67a2d3d5b358a0a0aa40bdc2ea1ad98','8740c79b1e98f304ded393569d08679e96d4f080e316229beabf20c5fcd36f2a'),
  @('src/hx/cppia/CppiaModule.cpp','a48e72c4a44d89964b30ff7ad05703b6e702b72d2cf9bf0bf84b5e86389121bd','347d7e1fcbd8b3b4a438c0308f582e0ee94adbfa218642e6347cc2237c10e619'),
  @('src/hx/cppia/CppiaVars.cpp','8cfa25be6dd40c54b31ca6566d6850ef1737154d9569d19802032e40853c774f','286d5418b96752ac4a06e410d754ff2ffc4669fd6b1d8370b081a2f1ce1a5aed')
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
$backup = Join-Path (Split-Path -Parent $PSScriptRoot) "_build/hxcpp-cppia-backup-$identity"
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
