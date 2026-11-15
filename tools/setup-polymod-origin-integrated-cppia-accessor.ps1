# Experimental combined import precedence and CPPIA static bridge based on FunkinCrew/polymod 8f488e00.
# Requires the existing CPPIA loader and a compatible scriptable hxcpp host.
[CmdletBinding()]
param([Parameter(Mandatory=$true)][string]$PolymodRoot,
      [ValidateSet('Check','Install','Verify','Rollback')][string]$Action='Check')
$ErrorActionPreference='Stop'
$PolymodRoot=(Resolve-Path -LiteralPath $PolymodRoot).Path
$patch=Join-Path $PSScriptRoot 'polymod-origin-integrated-cppia-accessor.patch'
if ((Get-FileHash -LiteralPath $patch -Algorithm SHA256).Hash -ne '9B47FB3873E85A00B1F83289408C5BE8E2ABF198F4ED71F5E4436D2FA9695957') { throw 'Unexpected patch contents.' }
$original=@{ 'polymod/hscript/_internal/Expr.hx'='2bb025d2c0bc1cf5445ca2761732e03e112c226e4f8fc6326e726f02849285dd'; 'polymod/hscript/_internal/Interp.hx'='827240f228f78a986e3d53b369bd4c26e0e2841a4a353d998e34a61db31d475a'; 'polymod/hscript/_internal/PolymodAbstractScriptClass.hx'='d0f66dfe548efd676b6285bf9f2ba2ae405a6294c62dcdf96aa0e916caafcea0'; 'polymod/hscript/_internal/PolymodStaticClassReference.hx'='e852108a4f71c640d6aedafde71c172d875044509c8d8c10a3de726ed83fbb5f'; 'polymod/hscript/_internal/PolymodScriptClass.hx'='f2d6c1c13105cce13667e56465ea1a88e9ff7c216fbc67889b95dda356f122f5'; 'polymod/hscript/_internal/PolymodCppiaClassReference.hx'='25298c0d1d265a14632133ee5c20d248dfc94e039530ef58b0bd714ba6aebce8'; 'polymod/util/Util.hx'='f96aed3816b7c1e426e13fd9af6df9f41673359d6f1df8943ef426c808e6d3f5' }
$patched=@{ 'polymod/hscript/_internal/Expr.hx'='0620a69b8b4946a3043f5f0f07968b6da5ffa581c205f1e07350f9bf6629fd04'; 'polymod/hscript/_internal/Interp.hx'='b201666e84e44bfd0757b91c43795db4624590beb8c2c496042a58c688eb1cd3'; 'polymod/hscript/_internal/PolymodAbstractScriptClass.hx'='3357d2f1ecfc90d2cb5600c7e48888bf232d2e79a6692af4c7188a07ae03c417'; 'polymod/hscript/_internal/PolymodStaticClassReference.hx'='268eb12d4e88364c2afa6bce49c1040adff91ab3beb62c151c6a702adf3f9baf'; 'polymod/hscript/_internal/PolymodScriptClass.hx'='db521cd99dbf90587f6120cd1b1a73f24954158fe2ce594db3d972d3966010e1'; 'polymod/hscript/_internal/PolymodCppiaClassReference.hx'='86d168fd810843332abfe05b214948d6ccf6e5b061eb412cf1b78544fe3e1c05'; 'polymod/util/Util.hx'='1f5521c9fa1a4db56823d0e62a68c050d647f86ef2298de3120faf3c530f323c' }
function HashText([string]$Path) {
 $text=[Text.UTF8Encoding]::new($false,$true).GetString([IO.File]::ReadAllBytes($Path)).Replace("`r`n","`n")
 $sha=[Security.Cryptography.SHA256]::Create()
 try { return ([BitConverter]::ToString($sha.ComputeHash([Text.Encoding]::UTF8.GetBytes($text)))).Replace('-','').ToLowerInvariant() } finally { $sha.Dispose() }
}
function State {
 $allOriginal=$true; $allPatched=$true
 foreach ($n in $original.Keys) {
  $target=Join-Path $PolymodRoot $n
  $h=HashText $target
  if ($h -ne $original[$n]) { $allOriginal=$false }
  if ($h -ne $patched[$n]) { $allPatched=$false }
 }
 if ($allOriginal) { return 'original' }; if ($allPatched) { return 'patched' }
 throw 'Unknown or mixed source files; preserving local changes.'
}
$state=State
if ($Action -eq 'Check') { "Integrated import, CPPIA and accessor profile: $state"; return }
if ($Action -eq 'Verify') { if ($state -ne 'patched') { throw 'Patch not installed.' }; 'Patched loader verified.'; return }
$sha=[Security.Cryptography.SHA256]::Create()
try { $id=([BitConverter]::ToString($sha.ComputeHash([Text.Encoding]::UTF8.GetBytes($PolymodRoot.ToLowerInvariant())))).Replace('-','').Substring(0,16) } finally { $sha.Dispose() }
$backup=Join-Path (Split-Path -Parent $PSScriptRoot) "_build/polymod-integrated-cppia-accessor-backup-$id"
if ($Action -eq 'Rollback') {
 if ($state -eq 'original') { 'Already original.'; return }
 foreach ($n in $original.Keys) {
  $saved=Join-Path $backup "$($n.Replace('/','__')).original"; $manifest=Join-Path $backup "$($n.Replace('/','__')).sha256"
  if (-not (Test-Path -LiteralPath $saved) -or -not (Test-Path -LiteralPath $manifest) -or (HashText $saved) -ne $original[$n] -or (Get-FileHash -LiteralPath $saved).Hash -ne (Get-Content -Raw -LiteralPath $manifest).Trim()) { throw "Invalid backup: $n" }
 }
 foreach ($n in $original.Keys) { Copy-Item -LiteralPath (Join-Path $backup "$($n.Replace('/','__')).original") -Destination (Join-Path $PolymodRoot $n) -Force }
 if ((State) -ne 'original') { throw 'Rollback verification failed.' }; 'Original loader restored.'; return
}
if ($state -eq 'patched') { 'Already patched.'; return }
& git -C $PolymodRoot apply --check $patch
if ($LASTEXITCODE -ne 0) { throw 'Patch check failed; files unchanged.' }
New-Item -ItemType Directory -Force -Path $backup | Out-Null
foreach ($n in $original.Keys) {
 $target=Join-Path $PolymodRoot $n; $saved=Join-Path $backup "$($n.Replace('/','__')).original"; $manifest=Join-Path $backup "$($n.Replace('/','__')).sha256"
 if (Test-Path -LiteralPath $saved) { if ((Get-FileHash -LiteralPath $saved).Hash -ne (Get-FileHash -LiteralPath $target).Hash) { throw "Existing backup differs: $n" } } else { Copy-Item -LiteralPath $target -Destination $saved }
 $exact=(Get-FileHash -LiteralPath $saved).Hash
 if (Test-Path -LiteralPath $manifest) { if ((Get-Content -Raw -LiteralPath $manifest).Trim() -ne $exact) { throw "Existing manifest differs: $n" } } else { Set-Content -LiteralPath $manifest -Value $exact -Encoding utf8 }
}
try {
 & git -C $PolymodRoot apply $patch
 if ($LASTEXITCODE -ne 0 -or (State) -ne 'patched') { throw 'Patch installation verification failed.' }
} catch {
 foreach ($n in $original.Keys) { Copy-Item -LiteralPath (Join-Path $backup "$($n.Replace('/','__')).original") -Destination (Join-Path $PolymodRoot $n) -Force }; throw
}
'Patched loader installed.'
