[CmdletBinding()]
param([string]$AssetsRoot)

$ErrorActionPreference = 'Stop'
$workspace = Split-Path -Parent $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($AssetsRoot)) {
  $AssetsRoot = Join-Path $workspace '_build\origin-editor-build-assets'
}
$AssetsRoot = [IO.Path]::GetFullPath($AssetsRoot)
$manifest = Get-Content -LiteralPath (Join-Path $PSScriptRoot 'origin-editor-layouts.json') -Raw | ConvertFrom-Json
if ($manifest.repository -ne 'FunkinCrew/funkin.assets' -or $manifest.commit -ne '0b28106619ecf017af57c54dfde8653350b66128') {
  throw 'Review the pinned Origin layout source before changing the manifest.'
}
function Get-GitBlobSha([byte[]]$Bytes) {
  $header = [Text.Encoding]::UTF8.GetBytes("blob $($Bytes.Length)" + [char]0)
  $blob = [byte[]]::new($header.Length + $Bytes.Length)
  [Buffer]::BlockCopy($header, 0, $blob, 0, $header.Length)
  [Buffer]::BlockCopy($Bytes, 0, $blob, $header.Length, $Bytes.Length)
  $sha = [Security.Cryptography.SHA1]::Create()
  try { return ([BitConverter]::ToString($sha.ComputeHash($blob))).Replace('-', '').ToLowerInvariant() }
  finally { $sha.Dispose() }
}
Add-Type -AssemblyName System.Net.Http
$client = [System.Net.Http.HttpClient]::new()
try {
  $client.DefaultRequestHeaders.UserAgent.ParseAdd('NovaFlare-Origin-Editor-Layout-Setup/1.0')
  $count = 0
  foreach ($entry in $manifest.files) {
    if ($entry.path -notmatch '^(exclude/)?ui/editors/[A-Za-z0-9_./-]+\.(xml|css)$' -or $entry.path.Contains('..')) {
      throw "Unexpected build-layout path: $($entry.path)"
    }
    $target = [IO.Path]::GetFullPath((Join-Path $AssetsRoot $entry.path))
    $prefix = $AssetsRoot.TrimEnd('\','/') + [IO.Path]::DirectorySeparatorChar
    if (-not $target.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase)) { throw 'Layout path escapes its root.' }
    if (Test-Path -LiteralPath $target) {
      if ((Get-GitBlobSha ([IO.File]::ReadAllBytes($target))) -ne $entry.gitBlobSha) {
        throw "Preserving a differing local layout: $target"
      }
    } else {
      $url = "https://raw.githubusercontent.com/$($manifest.repository)/$($manifest.commit)/$($entry.path)"
      $bytes = $client.GetByteArrayAsync($url).GetAwaiter().GetResult()
      if ($bytes.Length -ne $entry.size -or (Get-GitBlobSha $bytes) -ne $entry.gitBlobSha) {
        throw "Pinned layout content mismatch: $($entry.path)"
      }
      [IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($target)) | Out-Null
      $temporary = $target + '.' + [guid]::NewGuid().ToString('N') + '.tmp'
      try {
        [IO.File]::WriteAllBytes($temporary, $bytes)
        Move-Item -LiteralPath $temporary -Destination $target
      } finally {
        if (Test-Path -LiteralPath $temporary) { Remove-Item -LiteralPath $temporary }
      }
    }
    $count++
  }
  Write-Output "Verified $count pinned XML/CSS source layouts: $AssetsRoot"
  Write-Output "Compile with -DORIGIN_ASSETS_PATH=$AssetsRoot. Runtime assets remain external."
} finally { $client.Dispose() }
