[CmdletBinding()]
param(
  [Parameter(Mandatory=$true)][string]$PolymodRoot,
  [Parameter(Mandatory=$true)][string]$HxcppRoot
)
$ErrorActionPreference = 'Stop'
$manifest = Get-Content -LiteralPath (Join-Path $PSScriptRoot 'origin-cppia-dependencies.json') -Raw -Encoding UTF8 | ConvertFrom-Json
function TextHash([string]$Path) {
  $bytes = [IO.File]::ReadAllBytes($Path)
  $text = [Text.UTF8Encoding]::new($false,$true).GetString($bytes).Replace("`r`n", "`n")
  $sha = [Security.Cryptography.SHA256]::Create()
  try { return ([BitConverter]::ToString($sha.ComputeHash([Text.Encoding]::UTF8.GetBytes($text)))).Replace('-', '').ToLowerInvariant() }
  finally { $sha.Dispose() }
}
$failures = [Collections.Generic.List[string]]::new()
foreach ($group in @(@($manifest.polymod, $PolymodRoot), @($manifest.hxcpp, $HxcppRoot))) {
  $base = (Resolve-Path -LiteralPath $group[1]).Path
  foreach ($entry in $group[0]) {
    $file = Join-Path $base $entry.path
    if (-not (Test-Path -LiteralPath $file -PathType Leaf)) { $failures.Add("Missing: $file"); continue }
    if ((TextHash $file) -ne $entry.sha256_lf) { $failures.Add("Different: $file") }
  }
}
foreach ($entry in $manifest.patches) {
  $file = Join-Path $PSScriptRoot $entry.name
  if (-not (Test-Path -LiteralPath $file -PathType Leaf)) { $failures.Add("Missing: $file"); continue }
  if ((Get-FileHash -LiteralPath $file -Algorithm SHA256).Hash.ToLowerInvariant() -ne $entry.sha256) { $failures.Add("Different: $file") }
}
if ($failures.Count -gt 0) { $failures | ForEach-Object { Write-Error $_ -ErrorAction Continue }; throw 'CPPIA dependency stack differs; no files were changed.' }
Write-Output 'CPPIA dependency and patch fingerprints match; runtime compatibility is not implied.'
