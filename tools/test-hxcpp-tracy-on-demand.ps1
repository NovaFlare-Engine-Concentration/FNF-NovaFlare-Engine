[CmdletBinding()]
param(
  [Parameter(Mandatory)][string]$TracyToolsDir,
  [string]$HxcppRoot
)

# Run from a Visual Studio Developer PowerShell with matching Tracy 0.12.0 tools.
# This uses isolated _build output and never changes the selected hxcpp source.
$ErrorActionPreference = 'Stop'
if (-not (Get-Command cl.exe -ErrorAction SilentlyContinue)) { throw 'Run this test from a Visual Studio Developer PowerShell with cl.exe available.' }
$workspace = Split-Path -Parent $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($HxcppRoot)) {
  $HxcppRoot = @(& haxelib path hxcpp | Where-Object {
    $_ -and -not $_.StartsWith('-') -and (Test-Path (Join-Path $_ 'include\hx\TelemetryTracy.h'))
  }) | Select-Object -First 1
}
if ([string]::IsNullOrWhiteSpace($HxcppRoot)) { throw 'Cannot locate the selected hxcpp runtime.' }
$HxcppRoot = (Resolve-Path -LiteralPath $HxcppRoot).Path
$vendor = Join-Path $HxcppRoot 'project\thirdparty\tracy-0.12.0'
$clientSource = Join-Path $vendor 'TracyClient.cpp'
$captureTool = Join-Path $TracyToolsDir 'tracy-capture.exe'
$readerTool = Join-Path $TracyToolsDir 'tracy-csvexport.exe'
foreach ($required in @($clientSource, $captureTool, $readerTool)) {
  if (-not (Test-Path -LiteralPath $required -PathType Leaf)) { throw "Missing required file: $required" }
}
$controlSource = Join-Path $PSScriptRoot 'tests\tracy-on-demand-control.cpp'
$work = Join-Path $workspace ('_build\tracy-on-demand-repro-' + [Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $work | Out-Null
$clientObject = Join-Path $work 'TracyClient.obj'
$commonFlags = @('/nologo','/MT','/O2','/Os','/EHa','/std:c++17','/DTRACY_ENABLE',"/I$vendor")
& cl.exe @commonFlags '/DTRACY_ON_DEMAND' '/c' $clientSource "/Fo$clientObject" *> (Join-Path $work 'client-build.log')
if ($LASTEXITCODE -ne 0) { throw "Tracy client compilation failed; inspect $work" }

$results = @()
foreach ($variant in @('mismatched', 'consistent')) {
  $object = Join-Path $work "$variant.obj"
  $exe = Join-Path $work "$variant.exe"
  $flags = @($commonFlags)
  if ($variant -eq 'consistent') { $flags += '/DTRACY_ON_DEMAND' }
  & cl.exe @flags $controlSource $clientObject "/Fo$object" "/Fe$exe" '/link' 'ws2_32.lib' 'dbghelp.lib' 'advapi32.lib' 'user32.lib' *> (Join-Path $work "$variant-build.log")
  if ($LASTEXITCODE -ne 0) { throw "Control compilation failed; inspect $work" }

  $trace = Join-Path $work "$variant.tracy"
  $captureLog = Join-Path $work "$variant-capture.log"
  $captureErr = Join-Path $work "$variant-capture.err"
  $csv = Join-Path $work "$variant.csv"
  $control = Start-Process -FilePath $exe -WindowStyle Hidden -PassThru
  $null = $control.Handle
  $capture = Start-Process -FilePath $captureTool -ArgumentList @('-a','127.0.0.1','-o',('"{0}"' -f $trace),'-s','3','-m','512') -WindowStyle Hidden -PassThru -RedirectStandardOutput $captureLog -RedirectStandardError $captureErr
  $null = $capture.Handle
  if (-not $capture.WaitForExit(30000)) { throw "Collector remains live (PID $($capture.Id)); inspect $work" }
  $capture.WaitForExit(); $capture.Refresh()
  if ($capture.ExitCode -ne 0 -or -not (Test-Path -LiteralPath $trace)) { throw "Collector failed; inspect $work" }
  $reader = Start-Process -FilePath $readerTool -ArgumentList @(('"{0}"' -f $trace)) -WindowStyle Hidden -PassThru -RedirectStandardOutput $csv -RedirectStandardError (Join-Path $work "$variant-reader.err")
  $null = $reader.Handle
  if (-not $reader.WaitForExit(30000)) { throw "Reader remains live (PID $($reader.Id)); inspect $work" }
  $reader.WaitForExit(); $reader.Refresh()
  if (-not $control.WaitForExit(45000)) { throw "Control remains live (PID $($control.Id)); inspect $work" }
  $control.WaitForExit(); $control.Refresh()
  $log = [string](Get-Content -LiteralPath $captureLog -Raw)
  $failed = $log -like '*Instrumentation failure: Zone is ended twice*'
  if ($capture.ExitCode -ne 0 -or $reader.ExitCode -ne 0 -or $control.ExitCode -ne 0) { throw "Control process failed; inspect $work" }
  if ($variant -eq 'mismatched' -and -not $failed) { throw "The mismatched control did not reproduce the failure; inspect $work" }
  if ($variant -eq 'consistent') {
    if ($log -like '*Instrumentation failure*') { throw "The consistent control reported an instrumentation failure; inspect $work" }
    $rows = @(Import-Csv -LiteralPath $csv)
    $named = @($rows | Where-Object { $_.name -eq 'demand consistency scoped child' -and [int]$_.counts -gt 0 })
    if ($named.Count -eq 0 -or $log -notmatch 'Frames:\s*[1-9]' -or $log -notmatch 'Zones:\s*[1-9]') { throw "The consistent trace has no usable scoped-zone data; inspect $work" }
  }
  $results += [ordered]@{variant=$variant; collectorExit=$capture.ExitCode; readerExit=$reader.ExitCode; controlExit=$control.ExitCode; doubleEnd=$failed; traceSha256=(Get-FileHash -LiteralPath $trace).Hash}
}
$results | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath (Join-Path $work 'result.json')
Write-Output "PASS mismatched flags reproduced the double-end; consistent flags produced readable frame and zone data. The controls do not test shutdown. Results: $work"
