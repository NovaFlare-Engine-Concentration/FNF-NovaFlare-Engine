[CmdletBinding()]
param(
  [Parameter(Mandatory = $true)] [string]$PolymodRoot,
  [ValidateSet('Check', 'Install', 'Verify', 'Rollback')] [string]$Action = 'Check'
)
$ErrorActionPreference = 'Stop'
$PolymodRoot = (Resolve-Path -LiteralPath $PolymodRoot).Path
$relative = 'polymod/Polymod.hx'
$target = Join-Path $PolymodRoot $relative
$patch = Join-Path $PSScriptRoot 'polymod-origin-cppia-empty-async.patch'
if ((Get-FileHash -LiteralPath $patch -Algorithm SHA256).Hash -ne 'F80C199A8E7701BAF3871FC4EEC3EFC60DFEA5E186379B0004C8FBA6F9800176') { throw 'Unexpected patch contents.' }
$original = 'a421da1ae928736b8838bf9c513f79c232aec0450a9e2a12ca1f43943b216ad2'
$patched = '5749b68f6e33dd5d7c56ad2e178850ba7633669ded2caa7a93cb371acc68cf38'
function Get-NormalizedHash([string]$Path) {
  $text = [Text.UTF8Encoding]::new($false, $true).GetString([IO.File]::ReadAllBytes($Path)).Replace("`r`n", "`n")
  $sha = [Security.Cryptography.SHA256]::Create()
  try { return ([BitConverter]::ToString($sha.ComputeHash([Text.Encoding]::UTF8.GetBytes($text)))).Replace('-', '').ToLowerInvariant() }
  finally { $sha.Dispose() }
}
function Get-State {
  $hash = Get-NormalizedHash $target
  if ($hash -eq $original) { return 'original' }
  if ($hash -eq $patched) { return 'patched' }
  throw "Unexpected loader contents; preserving local changes: $target"
}
$state = Get-State
if ($Action -eq 'Check') { Write-Output "Polymod CPPIA loader profile: $state"; return }
if ($Action -eq 'Verify') { if ($state -ne 'patched') { throw 'Patch is not installed.' }; Write-Output 'Patched loader verified.'; return }
$sha = [Security.Cryptography.SHA256]::Create()
try { $identity = ([BitConverter]::ToString($sha.ComputeHash([Text.Encoding]::UTF8.GetBytes($PolymodRoot.ToLowerInvariant())))).Replace('-', '').Substring(0, 16) }
finally { $sha.Dispose() }
$backup = Join-Path (Split-Path -Parent $PSScriptRoot) "_build/polymod-cppia-empty-backup-$identity"
$saved = Join-Path $backup 'Polymod.hx.original'
$manifest = Join-Path $backup 'original.sha256'
if ($Action -eq 'Rollback') {
  if ($state -eq 'original') { Write-Output 'Already original.'; return }
  if (-not (Test-Path -LiteralPath $saved) -or -not (Test-Path -LiteralPath $manifest)) { throw 'Exact backup is missing.' }
  if ((Get-NormalizedHash $saved) -ne $original -or (Get-FileHash -LiteralPath $saved).Hash -ne (Get-Content -LiteralPath $manifest -Raw).Trim()) { throw 'Backup verification failed.' }
  Copy-Item -LiteralPath $saved -Destination $target -Force
  if ((Get-State) -ne 'original') { throw 'Rollback verification failed.' }
  Write-Output 'Original loader restored.'; return
}
if ($state -eq 'patched') { Write-Output 'Already patched.'; return }
& git -C $PolymodRoot apply --check $patch
if ($LASTEXITCODE -ne 0) { throw 'Patch check failed; file was not changed.' }
New-Item -ItemType Directory -Force -Path $backup | Out-Null
if (Test-Path -LiteralPath $saved) {
  if ((Get-FileHash -LiteralPath $saved).Hash -ne (Get-FileHash -LiteralPath $target).Hash) { throw 'Existing backup differs.' }
} else { Copy-Item -LiteralPath $target -Destination $saved }
$exact = (Get-FileHash -LiteralPath $saved).Hash
if (Test-Path -LiteralPath $manifest) {
  if ((Get-Content -LiteralPath $manifest -Raw).Trim() -ne $exact) { throw 'Existing backup manifest differs.' }
} else { Set-Content -LiteralPath $manifest -Value $exact -Encoding utf8 }
try {
  & git -C $PolymodRoot apply $patch
  if ($LASTEXITCODE -ne 0 -or (Get-State) -ne 'patched') { throw 'Patch installation verification failed.' }
} catch {
  Copy-Item -LiteralPath $saved -Destination $target -Force
  throw
}
Write-Output "Patched loader installed; exact original saved at $backup."
