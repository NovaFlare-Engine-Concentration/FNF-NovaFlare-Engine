# Experimental import precedence bridge based on FunkinCrew/polymod 8f488e00.
[CmdletBinding()]
param([Parameter(Mandatory=$true)][string]$PolymodRoot,
      [ValidateSet('Check','Install','Verify','Rollback')][string]$Action='Check')
$ErrorActionPreference='Stop'
$PolymodRoot=(Resolve-Path -LiteralPath $PolymodRoot).Path
$patch=Join-Path $PSScriptRoot 'polymod-origin-import-precedence.patch'
if ((Get-FileHash -LiteralPath $patch -Algorithm SHA256).Hash -ne '62D8F1442447FF9C51B0D8900E906DAF546813ECB8B1102DA4CDC03BF72F4982') { throw 'Unexpected patch contents.' }
$original=@{ 'Expr.hx'='2bb025d2c0bc1cf5445ca2761732e03e112c226e4f8fc6326e726f02849285dd'; 'Interp.hx'='827240f228f78a986e3d53b369bd4c26e0e2841a4a353d998e34a61db31d475a' }
$patched=@{ 'Expr.hx'='85402c391ece1dbf20f1302d774662b4884e432c485930a72804cde3b48d1018'; 'Interp.hx'='4e09c7a1ff9a428a4d80f979611bc171b2220d6100edb9a981a44d4553a5654e' }
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
if ($Action -eq 'Check') { "Import precedence profile: $state"; return }
if ($Action -eq 'Verify') { if ($state -ne 'patched') { throw 'Patch not installed.' }; 'Patched loader verified.'; return }
$sha=[Security.Cryptography.SHA256]::Create()
try { $id=([BitConverter]::ToString($sha.ComputeHash([Text.Encoding]::UTF8.GetBytes($PolymodRoot.ToLowerInvariant())))).Replace('-','').Substring(0,16) } finally { $sha.Dispose() }
$backup=Join-Path (Split-Path -Parent $PSScriptRoot) "_build/polymod-import-precedence-backup-$id"
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
