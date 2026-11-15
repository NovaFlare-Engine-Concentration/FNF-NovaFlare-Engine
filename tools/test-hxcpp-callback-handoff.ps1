[CmdletBinding()]
param([string]$HxcppRoot, [switch]$MemberLayout, [switch]$CrashOnCorruption)

$ErrorActionPreference = 'Stop'
if ($CrashOnCorruption -and -not $MemberLayout) { throw '-CrashOnCorruption requires -MemberLayout.' }
$workspace = Split-Path -Parent $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($HxcppRoot)) {
  $HxcppRoot = @(& haxelib path hxcpp | Where-Object {
    $_ -and -not $_.StartsWith('-') -and (Test-Path (Join-Path $_ 'src\hx\gc\Immix.cpp'))
  }) | Select-Object -First 1
}
if ([string]::IsNullOrWhiteSpace($HxcppRoot)) { throw 'Cannot locate hxcpp.' }
$HxcppRoot = (Resolve-Path -LiteralPath $HxcppRoot).Path
$sourcePath = Join-Path $HxcppRoot 'src\hx\gc\Immix.cpp'
$sourceHash = (Get-FileHash -LiteralPath $sourcePath -Algorithm SHA256).Hash
# Same pinned source and newline profiles as setup-hxcpp-callback-handoff.ps1.
$profiles = @(
  @{original='A77D3459BCAF82FE74F4415F09E5E16A62055D15AC221F82EF5152B7041C14DA'; patched='FBBF094A4117E82CFA9E0F15CB8063F56045E8975A4F6870B50BF78988CD77FE'},
  @{original='854BD5341A52B93DF3A4EE8017FDF2914AB2351EEB9E622AB21EFCFD9D9CE338'; patched='83734C3CE5B81298F67078F50DE39DFDC366717B250C3C433C63D82382FF6E66'},
  @{original='DECE5DF063FE725152FC4405E6F97271F80ADA2752A5D12A1DAB79B6E77D552C'; patched='FB3216E027A213CCE54A0FCBA33A8C055BFF7A78E2E00E32490C0ECAD92067D4'}
)
$profile = $profiles | Where-Object {$sourceHash -eq $_.original -or $sourceHash -eq $_.patched} | Select-Object -First 1
if (-not $profile) { throw "Unsupported runtime source: $sourceHash" }
$originalHash = $profile.original
$patchedHash = $profile.patched
$source = [IO.File]::ReadAllText($sourcePath)
$newline = if ($source.Contains("`r`n")) { "`r`n" } else { "`n" }
$fix = '   // Keep the pooled allocator visible to GC throughout callback-thread handoff.' + $newline +
  '   // GetPooledAllocator and AttachThread use the same recursive mutex.' + $newline +
  '   AutoLock callbackHandoffLock(*gThreadStateChangeLock);' + $newline
$original = if ($sourceHash -eq $patchedHash) { $source.Replace($fix, '') } else { $source }
$signature = 'void RegisterCurrentThread(void *inTopOfStack)'
$functionStart = $signature + $newline + '{' + $newline
$fixed = $original.Replace($functionStart, $functionStart + $fix)
$encoding = [Text.UTF8Encoding]::new($false)
function Get-TextSha256([string]$Text) {
  $hash = [Security.Cryptography.SHA256]::Create()
  try { return ([BitConverter]::ToString($hash.ComputeHash($encoding.GetBytes($Text)))).Replace('-', '') }
  finally { $hash.Dispose() }
}
if ((Get-TextSha256 $original) -ne $originalHash -or (Get-TextSha256 $fixed) -ne $patchedHash) {
  throw 'Failed to reconstruct the exact original and fixed runtime sources.'
}
$baseBuildRoot = Join-Path $workspace ('_build\hxcpp-callback-handoff-' + [guid]::NewGuid().ToString('N'))
$results = @()
$templateName = if ($CrashOnCorruption) { 'OriginCallbackHandoffCrashProbe.hx.in' } elseif ($MemberLayout) { 'OriginCallbackHandoffMemberProbe.hx.in' } else { 'OriginCallbackHandoffProbe.hx.in' }
$template = [IO.File]::ReadAllText((Join-Path $PSScriptRoot $templateName))
Push-Location $workspace
try {
  New-Item -ItemType Directory -Path $baseBuildRoot | Out-Null
  foreach ($variant in @('unfixed', 'fixed')) {
    $buildRoot = Join-Path $baseBuildRoot $variant
    $copyPath = Join-Path $baseBuildRoot "$variant.cpp"
    $copy = if ($variant -eq 'unfixed') { $original } else { $fixed }
    $copy = $copy.Replace('#include "../Hash.h"', '#include "' + (Join-Path $HxcppRoot 'src\hx\Hash.h').Replace('\','/') + '"')
    $copy = $copy.Replace('#include "GcRegCapture.h"', '#include "' + (Join-Path $HxcppRoot 'src\hx\gc\GcRegCapture.h').Replace('\','/') + '"')
    # Pause only a private runtime copy, after pool removal and before registration.
    $copy = $copy.Replace($signature, 'static void (*origin_pool_hook)(LocalAllocator *) = 0;' + $newline + $signature)
    $attach = '      local->AttachThread((int *)inTopOfStack);'
    $copy = $copy.Replace($attach, '      if (origin_pool_hook) origin_pool_hook(local);' + $newline + $attach)
    [IO.File]::WriteAllText($copyPath, $copy, $encoding)
    [IO.File]::WriteAllText((Join-Path $baseBuildRoot 'OriginCallbackHandoffProbe.hx'),
      $template.Replace('@@IMMIX_SOURCE@@', $copyPath.Replace('\','/')), $encoding)
    haxe -cp $baseBuildRoot -main OriginCallbackHandoffProbe -cpp $buildRoot -D HXCPP_M64 -D HXCPP_ALIGN_ALLOC -D HXCPP_GC_GENERATIONAL -D HXCPP_STACK_TRACE -D HXCPP_STACK_LINE -D no-compilation
    if ($LASTEXITCODE -ne 0) { throw "Haxe probe generation failed: $variant" }
    $buildPath = Join-Path $buildRoot 'Build.xml'
    $xml = [IO.File]::ReadAllText($buildPath)
    $xml = $xml.Replace('</xml>', '<set name="ORIGIN_HANDOFF_PROBE" value="1" /><files id="runtime"><file name="src/hx/gc/Immix.cpp" filterout="ORIGIN_HANDOFF_PROBE" /></files></xml>')
    [IO.File]::WriteAllText($buildPath, $xml, $encoding)
    $optionsPath = Join-Path $buildRoot 'ProbeOptions.txt'
    Get-Content (Join-Path $buildRoot 'Options.txt') | Where-Object {$_ -notmatch '^no_compilation='} | Set-Content -LiteralPath $optionsPath
    Push-Location $buildRoot
    try {
      haxelib run hxcpp Build.xml -options $optionsPath *> (Join-Path $baseBuildRoot "$variant-build.log")
      if ($LASTEXITCODE -ne 0) { throw "Native probe build failed: $variant" }
      $executable = Join-Path $buildRoot 'OriginCallbackHandoffProbe.exe'
      $logPath = Join-Path $baseBuildRoot "$variant.log"
      $process = Start-Process -FilePath $executable -WorkingDirectory $buildRoot -WindowStyle Hidden -PassThru `
        -RedirectStandardOutput $logPath -RedirectStandardError (Join-Path $baseBuildRoot "$variant.stderr.log")
      if (-not $process.WaitForExit(15000)) {
        $process.Kill()
        throw "Native callback handoff probe timed out: $variant"
      }
      $process.WaitForExit()
      $report = [IO.File]::ReadAllText($logPath).Trim()
      if ($variant -eq 'unfixed') {
        if ($CrashOnCorruption) {
          $stderr = [IO.File]::ReadAllText((Join-Path $baseBuildRoot "$variant.stderr.log")).Trim()
          if ($process.ExitCode -ne -1073741819 -or $stderr -notmatch '^EXPECTED_BAD_BASE=([0-9A-Fa-f]+) FUNCTION=\1 MATCH=1\r?\nFAULT_CODE=C0000005 RIP=[0-9A-Fa-f]+ RAX=[0-9A-Fa-f]+ RCX=\1 OPCODE=FF9010010000$') {
            throw "Original runtime did not produce the expected access violation and matching function pointer: exit=$($process.ExitCode) stderr=$stderr"
          }
          $report = "access_violation=0xc0000005 $stderr"
        } else {
          if ($process.ExitCode -ne 1 -or $report -notmatch '^handoff_locked=0 overlaps=[1-9][0-9]* base=0x') {
            throw "Original runtime did not reproduce allocation overlap: $report"
          }
          if ($MemberLayout -and $report -notmatch 'functionMatch=1 slot=2 oldWord=0x[0-9a-f]+ slotMatch=1') {
            throw "Original runtime did not reproduce the member-function field overlap: $report"
          }
        }
      } elseif ($process.ExitCode -ne 0 -or $report -notmatch '^handoff_locked=1 overlaps=0 base=0x0 ') {
        throw "Fixed runtime did not protect the handoff: $report"
      }
      $results += [pscustomobject]@{variant=$variant; exitCode=$process.ExitCode; report=$report}
      Write-Output "PASS $variant : $report"
    } finally { Pop-Location }
  }
  if ((Get-FileHash -LiteralPath $sourcePath -Algorithm SHA256).Hash -ne $sourceHash) {
    throw 'Selected runtime changed during the isolated test.'
  }
  $results | ConvertTo-Json | Set-Content (Join-Path $baseBuildRoot 'results.json')
  Write-Output "ALL CALLBACK HANDOFF CHECKS PASSED; selected runtime was not modified. Results: $baseBuildRoot"
} finally { Pop-Location }
