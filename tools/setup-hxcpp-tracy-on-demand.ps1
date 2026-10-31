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
    $_ -and -not $_.StartsWith('-') -and (Test-Path (Join-Path $_ 'include\hx\TelemetryTracy.h'))
  }) | Select-Object -First 1
}
if ([string]::IsNullOrWhiteSpace($HxcppRoot)) { throw 'Cannot locate the selected hxcpp runtime.' }
$HxcppRoot = (Resolve-Path -LiteralPath $HxcppRoot).Path
$target = Join-Path $HxcppRoot 'include\hx\TelemetryTracy.h'
$currentHash = (Get-FileHash -LiteralPath $target -Algorithm SHA256).Hash
# Pinned hxcpp 3f50506ae47aa801fd7e8ef7636ea2dd80b73254, full CRLF and canonical LF.
$profiles = @(
  @{original='941FD5EAF921AD8CAB0E90555482374758E7C63DC062CB6383444BDABDC84EFE'; patched='8EF026E1D83093E0C79DFDD8950F0788D587F9636F47AB30689035836EE2E536'},
  @{original='B876853E9D490A6D7ED0FF40CFEDE8141AB5DD3D9D3D61B93FD9EF8113F71A41'; patched='E9F6B836F2FB0B99277E7B701582BD1D470BBC5D2FC7184D01170BA809CBA67A'}
)
$profile = $profiles | Where-Object {$currentHash -eq $_.original -or $currentHash -eq $_.patched} | Select-Object -First 1
if (-not $profile) { throw "Unsupported hxcpp TelemetryTracy.h hash $currentHash. Preserve and review local changes before patching." }
$backup = Join-Path $workspace "_build\hxcpp-tracy-on-demand-$($profile.original).original.h"
if ($VerifyOnly) {
  if ($currentHash -ne $profile.patched) { throw 'hxcpp Tracy on-demand consistency fix is not installed.' }
  Write-Output "Verified Tracy on-demand consistency fix: $target ($currentHash)"
  return
}
if ($Rollback) {
  if ($currentHash -eq $profile.original) { Write-Output 'Already original.'; return }
  if (-not (Test-Path -LiteralPath $backup) -or (Get-FileHash -LiteralPath $backup).Hash -ne $profile.original) {
    throw 'Exact original backup is missing.'
  }
  Copy-Item -LiteralPath $backup -Destination $target
  Write-Output 'Restored the original Tracy header; rebuild before running.'
  return
}
if ($currentHash -eq $profile.patched) { Write-Output 'Tracy on-demand consistency fix already installed.'; return }
if (Test-Path -LiteralPath $backup) {
  if ((Get-FileHash -LiteralPath $backup).Hash -ne $profile.original) { throw 'Existing Tracy header backup has different contents.' }
} else {
  New-Item -ItemType Directory -Force -Path (Split-Path -Parent $backup) | Out-Null
  Copy-Item -LiteralPath $target -Destination $backup
}
$encoding = [Text.UTF8Encoding]::new($false, $true)
$source = [IO.File]::ReadAllText($target, $encoding)
$newline = if ($source.Contains("`r`n")) { "`r`n" } else { "`n" }
$anchor = '#define TRACY_ENABLE' + $newline
$replacement = @(
  '// Match the on-demand client when compiling inline C++ scoped zones.',
  '#if defined(HXCPP_TRACY_ON_DEMAND) && !defined(TRACY_ON_DEMAND)',
  '#define TRACY_ON_DEMAND',
  '#endif',
  '',
  '#define TRACY_ENABLE',
  ''
) -join $newline
if ($source.Split(@($anchor), [StringSplitOptions]::None).Count -ne 2) { throw 'Ambiguous Tracy header anchor.' }
$candidate = $encoding.GetBytes($source.Replace($anchor, $replacement))
$sha = [Security.Cryptography.SHA256]::Create()
try { $candidateHash = ([BitConverter]::ToString($sha.ComputeHash($candidate))).Replace('-', '') }
finally { $sha.Dispose() }
if ($candidateHash -ne $profile.patched) { throw "Unexpected patched Tracy header hash: $candidateHash" }
if ((Get-FileHash -LiteralPath $target).Hash -ne $profile.original) { throw 'Runtime changed during patch preparation.' }
[IO.File]::WriteAllBytes($target, $candidate)
if ((Get-FileHash -LiteralPath $target).Hash -ne $profile.patched) { throw 'Installed Tracy header differs from the candidate.' }
Write-Output "Installed Tracy on-demand consistency fix: $target"
Write-Output "Original backup: $backup"
Write-Output 'Rebuild Tracy-instrumented objects before capture. Ordinary builds do not include this header.'
