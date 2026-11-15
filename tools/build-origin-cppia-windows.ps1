[CmdletBinding()]
param(
  [switch]$CheckOnly
)
$ErrorActionPreference = 'Stop'
$workspace = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..')).Path
$project = Join-Path $workspace 'Project-OriginCPPIA.xml'
if (-not (Test-Path -LiteralPath $project -PathType Leaf)) { throw "Missing CPPIA project: $project" }

function Find-HaxelibRoot([string]$Name, [string]$Marker) {
  $lines = @(& haxelib path $Name)
  if ($LASTEXITCODE -ne 0) { throw "Cannot resolve haxelib: $Name" }
  $matches = @($lines | Where-Object { -not $_.StartsWith('-') -and (Test-Path -LiteralPath $_ -PathType Container) } | Where-Object {
    Test-Path -LiteralPath (Join-Path $_ $Marker) -PathType Leaf
  } | ForEach-Object { (Resolve-Path -LiteralPath $_).Path } | Select-Object -Unique)
  if ($matches.Count -ne 1) { throw "Expected one $Name dependency root, found $($matches.Count)." }
  return $matches[0]
}

Push-Location $workspace
try {
  $polymodRoot = Find-HaxelibRoot 'polymod' 'polymod/Polymod.hx'
  $hxcppRoot = Find-HaxelibRoot 'hxcpp' 'src/hx/cppia/Cppia.cpp'
  & (Join-Path $PSScriptRoot 'check-origin-cppia-dependencies.ps1') -PolymodRoot $polymodRoot -HxcppRoot $hxcppRoot
  if ($CheckOnly) { Write-Output 'CPPIA build prerequisites checked; no build was started.'; return }

  $freeKiB = (Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory
  if ($null -eq $freeKiB -or $freeKiB -lt 204800) { throw 'Insufficient available memory to start the build.' }
  $buildDir = Join-Path $workspace '_build/origin-cppia-build'
  New-Item -ItemType Directory -Force -Path $buildDir | Out-Null
  $stamp = '{0}-{1}' -f (Get-Date -Format 'yyyyMMdd-HHmmss-ffff'), $PID
  $stdout = Join-Path $buildDir "build-$stamp.out.log"
  $stderr = Join-Path $buildDir "build-$stamp.err.log"
  if ((Test-Path -LiteralPath $stdout) -or (Test-Path -LiteralPath $stderr)) { throw 'Log path already exists.' }
  $previousThreads = $env:HXCPP_COMPILE_THREADS
  $previousGc = $env:OCAMLRUNPARAM
  $env:HXCPP_COMPILE_THREADS = '1'
  if ([string]::IsNullOrEmpty($env:OCAMLRUNPARAM)) { $env:OCAMLRUNPARAM = 'o=40' }
  try {
    $process = Start-Process -FilePath 'haxelib.exe' -ArgumentList 'run','lime','build','Project-OriginCPPIA.xml','windows' -WorkingDirectory $workspace -WindowStyle Hidden -PassThru -RedirectStandardOutput $stdout -RedirectStandardError $stderr
    # Keep a process handle open so Windows cannot discard the exit status
    # while the memory monitor polls the long-running compiler process.
    $null = $process.Handle
    $lowMemory = $false
    try {
      while (-not $process.HasExited) {
        $freeKiB = (Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory
        if ($null -eq $freeKiB) { throw 'Cannot monitor available memory.' }
        if ($freeKiB -lt 204800) {
          $lowMemory = $true
          & taskkill /PID $process.Id /T /F
          break
        }
        Start-Sleep -Milliseconds 500
        $process.Refresh()
      }
      $process.WaitForExit()
    } catch {
      $process.Refresh()
      if (-not $process.HasExited) { & taskkill /PID $process.Id /T /F }
      throw
    }
    Write-Output "Build logs: $stdout ; $stderr"
    if ($lowMemory) { throw 'Build stopped because available physical memory fell below 200 MiB.' }
    if ($null -eq $process.ExitCode) { throw 'CPPIA build ended without a readable exit code; inspect the logs and generated files.' }
    if ($process.ExitCode -ne 0) { throw "CPPIA build failed with exit code $($process.ExitCode)." }
    Write-Output 'CPPIA build completed. Check the logs for warnings; runtime testing is separate.'
  } finally {
    $env:HXCPP_COMPILE_THREADS = $previousThreads
    $env:OCAMLRUNPARAM = $previousGc
  }
} finally { Pop-Location }
