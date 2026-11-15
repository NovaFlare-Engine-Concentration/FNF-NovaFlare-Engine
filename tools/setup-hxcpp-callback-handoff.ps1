[CmdletBinding()]
param(
  [string]$HxcppRoot,
  [switch]$VerifyOnly,
  [switch]$Rollback
)

$ErrorActionPreference = 'Stop'
if ($VerifyOnly -and $Rollback) { throw 'Choose verification or rollback.' }
$workspace = Split-Path -Parent $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($HxcppRoot)) {
  $HxcppRoot = @(& haxelib path hxcpp | Where-Object {
    $_ -and -not $_.StartsWith('-') -and (Test-Path (Join-Path $_ 'src\hx\gc\Immix.cpp'))
  }) | Select-Object -First 1
}
if ([string]::IsNullOrWhiteSpace($HxcppRoot)) { throw 'Cannot locate the selected hxcpp runtime.' }
$HxcppRoot = (Resolve-Path -LiteralPath $HxcppRoot).Path
$target = Join-Path $HxcppRoot 'src\hx\gc\Immix.cpp'
$currentHash = (Get-FileHash -LiteralPath $target -Algorithm SHA256).Hash
# Pinned hxcpp 3f50506ae47aa801fd7e8ef7636ea2dd80b73254: existing Windows bytes,
# canonical Git LF, and Git's full CRLF checkout. All outputs are checked in full.
$profiles = @(
  @{original='A77D3459BCAF82FE74F4415F09E5E16A62055D15AC221F82EF5152B7041C14DA'; patched='FBBF094A4117E82CFA9E0F15CB8063F56045E8975A4F6870B50BF78988CD77FE'},
  @{original='854BD5341A52B93DF3A4EE8017FDF2914AB2351EEB9E622AB21EFCFD9D9CE338'; patched='83734C3CE5B81298F67078F50DE39DFDC366717B250C3C433C63D82382FF6E66'},
  @{original='DECE5DF063FE725152FC4405E6F97271F80ADA2752A5D12A1DAB79B6E77D552C'; patched='FB3216E027A213CCE54A0FCBA33A8C055BFF7A78E2E00E32490C0ECAD92067D4'}
)
$profile = $profiles | Where-Object {$currentHash -eq $_.original -or $currentHash -eq $_.patched} | Select-Object -First 1
if (-not $profile) {
  throw "Unsupported hxcpp Immix.cpp hash $currentHash. Preserve local changes and review the runtime before patching."
}
$originalHash = $profile.original
$patchedHash = $profile.patched
$backup = Join-Path $workspace "_build\hxcpp-callback-handoff-$originalHash.original.cpp"
if ($VerifyOnly) {
  if ($currentHash -ne $patchedHash) { throw 'hxcpp callback handoff fix is not installed.' }
  Write-Output "Verified callback handoff fix: $target ($currentHash)"
  return
}
if ($Rollback) {
  if ($currentHash -eq $originalHash) { Write-Output 'Already original.'; return }
  if (-not (Test-Path -LiteralPath $backup) -or
      (Get-FileHash -LiteralPath $backup -Algorithm SHA256).Hash -ne $originalHash) {
    throw 'Exact original backup is missing.'
  }
  Copy-Item -LiteralPath $backup -Destination $target
  Write-Output 'Restored the original callback handoff implementation; rebuild before running.'
  return
}
if ($currentHash -eq $patchedHash) { Write-Output 'Callback handoff fix already installed.'; return }
if (Test-Path -LiteralPath $backup) {
  if ((Get-FileHash -LiteralPath $backup -Algorithm SHA256).Hash -ne $originalHash) {
    throw 'Existing callback handoff backup has different contents.'
  }
} else {
  New-Item -ItemType Directory -Force -Path (Split-Path -Parent $backup) | Out-Null
  Copy-Item -LiteralPath $target -Destination $backup
}
$encoding = [Text.UTF8Encoding]::new($false, $true)
$source = [IO.File]::ReadAllText($target, $encoding)
$newline = if ($source.Contains("`r`n")) { "`r`n" } else { "`n" }
$anchor = 'void RegisterCurrentThread(void *inTopOfStack)' + $newline + '{' + $newline
$replacement = $anchor +
  '   // Keep the pooled allocator visible to GC throughout callback-thread handoff.' + $newline +
  '   // GetPooledAllocator and AttachThread use the same recursive mutex.' + $newline +
  '   AutoLock callbackHandoffLock(*gThreadStateChangeLock);' + $newline
if ($source.Split(@($anchor), [StringSplitOptions]::None).Count -ne 2) { throw 'Ambiguous handoff function.' }
$candidate = $encoding.GetBytes($source.Replace($anchor, $replacement))
$sha = [Security.Cryptography.SHA256]::Create()
try { $candidateHash = ([BitConverter]::ToString($sha.ComputeHash($candidate))).Replace('-', '') }
finally { $sha.Dispose() }
if ($candidateHash -ne $patchedHash) { throw "Unexpected patched runtime hash: $candidateHash" }
if ((Get-FileHash -LiteralPath $target -Algorithm SHA256).Hash -ne $originalHash) {
  throw 'Runtime changed during patch preparation.'
}
[IO.File]::WriteAllBytes($target, $candidate)
if ((Get-FileHash -LiteralPath $target -Algorithm SHA256).Hash -ne $patchedHash) {
  throw 'Installed runtime hash does not match the candidate.'
}
Write-Output "Installed callback handoff fix: $target"
Write-Output "Original backup: $backup"
Write-Output 'Rebuild Windows before runtime verification.'
