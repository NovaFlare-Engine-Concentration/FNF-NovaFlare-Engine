[CmdletBinding()]
param(
  [Parameter(Mandatory = $true)] [string]$PolymodRoot,
  [ValidateSet('Check', 'Install', 'Verify', 'Rollback')] [string]$Action = 'Check'
)
$ErrorActionPreference = 'Stop'
$PolymodRoot = (Resolve-Path -LiteralPath $PolymodRoot).Path
$relative = 'polymod/hscript/_internal/DependencyOrder.hx'
$target = Join-Path $PolymodRoot $relative
$patch = Join-Path $PSScriptRoot 'polymod-origin-cppia-segment-order.patch'
if ((Get-FileHash -LiteralPath $patch -Algorithm SHA256).Hash -ne '96309A6FDE2CDBE12AD6A557A5C8682E6066B8F248DD674297A539C57BF603E9') { throw 'Unexpected patch contents.' }
$original = '10b32b9ddb0b89fb168c36ed20f0f63b822ab7dac5d6ce3f2b498d15d8e87681'
$patched = '54f8fd8d9a188e50ce79bbf59089d4108b3d2f658a90ce53fb620e335c9b17a6'
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
$backup = Join-Path (Split-Path -Parent $PSScriptRoot) "_build/polymod-cppia-segment-order-backup-$identity"
$saved = Join-Path $backup 'DependencyOrder.hx.original'
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
