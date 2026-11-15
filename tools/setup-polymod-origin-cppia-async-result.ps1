[CmdletBinding()]
param(
  [Parameter(Mandatory = $true)] [string]$PolymodRoot,
  [ValidateSet('Check', 'Install', 'Verify', 'Rollback')] [string]$Action = 'Check'
)
$ErrorActionPreference = 'Stop'
$PolymodRoot = (Resolve-Path -LiteralPath $PolymodRoot).Path
$relative = 'polymod/Polymod.hx'
$target = Join-Path $PolymodRoot $relative
$patch = Join-Path $PSScriptRoot 'polymod-origin-cppia-async-result.patch'
if ((Get-FileHash -LiteralPath $patch -Algorithm SHA256).Hash -ne 'D9B66F0101F1C290A0EEED1917E832559CF0D9330FE096D7F827F308DE402C5F') { throw 'Unexpected patch contents.' }
$original = '7a2172036f8df203192a21312c45ebf7b9b551c5f333498bd20d78ced358ed1a'
$patched = 'f0ffda2b8341ed74cf08bf961e2e46d377e2742d0a4b161ed474225734efc9ce'
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
$backup = Join-Path (Split-Path -Parent $PSScriptRoot) "_build/polymod-cppia-async-backup-$identity"
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
