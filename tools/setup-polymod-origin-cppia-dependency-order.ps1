[CmdletBinding()]
param(
  [Parameter(Mandatory = $true)] [string]$PolymodRoot,
  [ValidateSet('Check', 'Install', 'Verify', 'Rollback')] [string]$Action = 'Check'
)
$ErrorActionPreference = 'Stop'
$PolymodRoot = (Resolve-Path -LiteralPath $PolymodRoot).Path
$patch = Join-Path $PSScriptRoot 'polymod-origin-cppia-dependency-order.patch'
$main = Join-Path $PolymodRoot 'polymod/Polymod.hx'
$manifest = Join-Path $PolymodRoot 'polymod/hscript/_internal/ManifestExports.hx'
$order = Join-Path $PolymodRoot 'polymod/hscript/_internal/DependencyOrder.hx'
if ((Get-FileHash -LiteralPath $patch -Algorithm SHA256).Hash -ne '8E90315C929636F9000D0485E27E5AFE3F2E550ECBE5B869EA3815F5C668A940') { throw 'Unexpected patch contents.' }
function Get-NormalizedHash([string]$Path) {
  $text = [Text.UTF8Encoding]::new($false, $true).GetString([IO.File]::ReadAllBytes($Path)).Replace("`r`n", "`n")
  $sha = [Security.Cryptography.SHA256]::Create()
  try { return ([BitConverter]::ToString($sha.ComputeHash([Text.Encoding]::UTF8.GetBytes($text)))).Replace('-', '').ToLowerInvariant() }
  finally { $sha.Dispose() }
}
function Get-State {
  $hash=Get-NormalizedHash $main
  $hasManifest=Test-Path -LiteralPath $manifest
  $hasOrder=Test-Path -LiteralPath $order
  if ($hash -eq '5749b68f6e33dd5d7c56ad2e178850ba7633669ded2caa7a93cb371acc68cf38' -and -not $hasManifest -and -not $hasOrder) { return 'original' }
  if ($hash -eq 'd98f491e2f5d94c882d06245ec9a951e61d5d95fef997646bfb61fe64c527ac7' -and $hasManifest -and $hasOrder -and
      (Get-NormalizedHash $manifest) -eq '9ee1817a1d4dd8ba5ae8e0a4ef2682d8cdb74dddc58a3ede256a7a0137f06462' -and
      (Get-NormalizedHash $order) -eq '10b32b9ddb0b89fb168c36ed20f0f63b822ab7dac5d6ce3f2b498d15d8e87681') { return 'patched' }
  throw 'Unexpected loader or helper contents; preserving local changes.'
}
$state=Get-State
if ($Action -eq 'Check') { Write-Output "CPPIA dependency order profile: $state"; return }
if ($Action -eq 'Verify') { if ($state -ne 'patched') { throw 'Patch is not installed.' }; Write-Output 'Dependency order patch verified.'; return }
$sha=[Security.Cryptography.SHA256]::Create()
try { $identity=([BitConverter]::ToString($sha.ComputeHash([Text.Encoding]::UTF8.GetBytes($PolymodRoot.ToLowerInvariant())))).Replace('-','').Substring(0,16) } finally { $sha.Dispose() }
$backup=Join-Path (Split-Path -Parent $PSScriptRoot) "_build/polymod-cppia-dependency-order-backup-$identity"
$saved=Join-Path $backup 'Polymod.hx.original'
$hashFile=Join-Path $backup 'original.sha256'
if ($Action -eq 'Rollback') {
  if ($state -eq 'original') { Write-Output 'Already original.'; return }
  if (-not (Test-Path -LiteralPath $saved) -or -not (Test-Path -LiteralPath $hashFile)) { throw 'Exact backup missing.' }
  if ((Get-FileHash -LiteralPath $saved).Hash -ne (Get-Content -LiteralPath $hashFile -Raw).Trim()) { throw 'Backup checksum mismatch.' }
  & git -C $PolymodRoot apply --reverse --check $patch
  if ($LASTEXITCODE -ne 0) { throw 'Reverse patch check failed; no changes made.' }
  & git -C $PolymodRoot apply --reverse $patch
  if ($LASTEXITCODE -ne 0) { throw 'Reverse patch failed; inspect before retrying.' }
  Copy-Item -LiteralPath $saved -Destination $main -Force
  if ((Get-State) -ne 'original') { throw 'Rollback verification failed.' }
  Write-Output 'Original loader and helper layout restored.'; return
}
if ($state -eq 'patched') { Write-Output 'Already patched.'; return }
& git -C $PolymodRoot apply --check $patch
if ($LASTEXITCODE -ne 0) { throw 'Patch check failed; no changes made.' }
New-Item -ItemType Directory -Force -Path $backup | Out-Null
if (Test-Path -LiteralPath $saved) {
  if ((Get-FileHash -LiteralPath $saved).Hash -ne (Get-FileHash -LiteralPath $main).Hash) { throw 'Existing backup differs.' }
} else { Copy-Item -LiteralPath $main -Destination $saved }
$exact=(Get-FileHash -LiteralPath $saved).Hash
if (Test-Path -LiteralPath $hashFile) {
  if ((Get-Content -LiteralPath $hashFile -Raw).Trim() -ne $exact) { throw 'Existing backup manifest differs.' }
} else { Set-Content -LiteralPath $hashFile -Value $exact -Encoding utf8 }
& git -C $PolymodRoot apply $patch
if ($LASTEXITCODE -ne 0 -or (Get-State) -ne 'patched') { throw 'Patch installation verification failed; inspect before retrying.' }
Write-Output "Dependency order patch installed; exact original saved at $backup."
