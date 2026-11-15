# Experimental combined import precedence and CPPIA static bridge based on FunkinCrew/polymod 8f488e00.
# Requires the existing CPPIA loader and a compatible scriptable hxcpp host.
[CmdletBinding()]
param([Parameter(Mandatory=$true)][string]$PolymodRoot,
      [ValidateSet('Check','Install','Verify','Rollback')][string]$Action='Check')
$ErrorActionPreference='Stop'
$PolymodRoot=(Resolve-Path -LiteralPath $PolymodRoot).Path
$patch=Join-Path $PSScriptRoot 'polymod-origin-combined-import-cppia.patch'
if ((Get-FileHash -LiteralPath $patch -Algorithm SHA256).Hash -ne '68632C3370781A664D2FA09A05BB54BF0EFD428EB56A083EA33049BDB524E825') { throw 'Unexpected patch contents.' }
$original=@{ 'Expr.hx'='2bb025d2c0bc1cf5445ca2761732e03e112c226e4f8fc6326e726f02849285dd'; 'Interp.hx'='827240f228f78a986e3d53b369bd4c26e0e2841a4a353d998e34a61db31d475a' }
$patched=@{ 'Expr.hx'='0620a69b8b4946a3043f5f0f07968b6da5ffa581c205f1e07350f9bf6629fd04'; 'Interp.hx'='dd6ea92ff94f5202fb831954a392c29b415d557903e2f9286e47badcc7ae7933' }
function HashText([string]$Path) {
 $text=[Text.UTF8Encoding]::new($false,$true).GetString([IO.File]::ReadAllBytes($Path)).Replace("`r`n","`n")
 $sha=[Security.Cryptography.SHA256]::Create()
 try { return ([BitConverter]::ToString($sha.ComputeHash([Text.Encoding]::UTF8.GetBytes($text)))).Replace('-','').ToLowerInvariant() } finally { $sha.Dispose() }
}
function State {
 $allOriginal=$true; $allPatched=$true
 foreach ($n in $original.Keys) {
  $target=Join-Path $PolymodRoot "polymod/hscript/_internal/$n"
  $h=HashText $target
  if ($h -ne $original[$n]) { $allOriginal=$false }
  if ($h -ne $patched[$n]) { $allPatched=$false }
 }
 if ($allOriginal) { return 'original' }; if ($allPatched) { return 'patched' }
 throw 'Unknown or mixed source files; preserving local changes.'
}
$state=State
if ($Action -eq 'Check') { "Combined import and CPPIA profile: $state"; return }
if ($Action -eq 'Verify') { if ($state -ne 'patched') { throw 'Patch not installed.' }; 'Patched loader verified.'; return }
$sha=[Security.Cryptography.SHA256]::Create()
try { $id=([BitConverter]::ToString($sha.ComputeHash([Text.Encoding]::UTF8.GetBytes($PolymodRoot.ToLowerInvariant())))).Replace('-','').Substring(0,16) } finally { $sha.Dispose() }
$backup=Join-Path (Split-Path -Parent $PSScriptRoot) "_build/polymod-combined-import-cppia-backup-$id"
if ($Action -eq 'Rollback') {
 if ($state -eq 'original') { 'Already original.'; return }
 foreach ($n in $original.Keys) {
  $saved=Join-Path $backup "$n.original"; $manifest=Join-Path $backup "$n.sha256"
  if (-not (Test-Path -LiteralPath $saved) -or -not (Test-Path -LiteralPath $manifest) -or (HashText $saved) -ne $original[$n] -or (Get-FileHash -LiteralPath $saved).Hash -ne (Get-Content -Raw -LiteralPath $manifest).Trim()) { throw "Invalid backup: $n" }
 }
 foreach ($n in $original.Keys) { Copy-Item -LiteralPath (Join-Path $backup "$n.original") -Destination (Join-Path $PolymodRoot "polymod/hscript/_internal/$n") -Force }
 if ((State) -ne 'original') { throw 'Rollback verification failed.' }; 'Original loader restored.'; return
}
if ($state -eq 'patched') { 'Already patched.'; return }
& git -C $PolymodRoot apply --check $patch
if ($LASTEXITCODE -ne 0) { throw 'Patch check failed; files unchanged.' }
New-Item -ItemType Directory -Force -Path $backup | Out-Null
foreach ($n in $original.Keys) {
 $target=Join-Path $PolymodRoot "polymod/hscript/_internal/$n"; $saved=Join-Path $backup "$n.original"; $manifest=Join-Path $backup "$n.sha256"
 if (Test-Path -LiteralPath $saved) { if ((Get-FileHash -LiteralPath $saved).Hash -ne (Get-FileHash -LiteralPath $target).Hash) { throw "Existing backup differs: $n" } } else { Copy-Item -LiteralPath $target -Destination $saved }
 $exact=(Get-FileHash -LiteralPath $saved).Hash
 if (Test-Path -LiteralPath $manifest) { if ((Get-Content -Raw -LiteralPath $manifest).Trim() -ne $exact) { throw "Existing manifest differs: $n" } } else { Set-Content -LiteralPath $manifest -Value $exact -Encoding utf8 }
}
try {
 & git -C $PolymodRoot apply $patch
 if ($LASTEXITCODE -ne 0 -or (State) -ne 'patched') { throw 'Patch installation verification failed.' }
} catch {
 foreach ($n in $original.Keys) { Copy-Item -LiteralPath (Join-Path $backup "$n.original") -Destination (Join-Path $PolymodRoot "polymod/hscript/_internal/$n") -Force }; throw
}
'Patched loader installed.'
