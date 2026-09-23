# ---------------------------------------------------------------------------
# NovaFlare Engine - embed the UTF-8 activeCodePage application manifest.
#
# WHY THIS EXISTS
#   On Windows every *narrow* (ANSI) file API - CRT fopen/unlink/stat, the Win32
#   *A family, and any third-party DLL that calls them (LuaJIT, libVLC, ...) -
#   interprets the bytes it receives using the process ANSI code page.  On a
#   Simplified Chinese system that is 936 (GBK), while Haxe/hxcpp stores and
#   passes UTF-8.  A path such as "mods/<chinese>/data/x.json" therefore reaches
#   the OS as mojibake and the file is never found.
#
#   Declaring <activeCodePage>UTF-8</activeCodePage> in the application manifest
#   (Windows 10 1903+) flips the whole process to UTF-8, which fixes that entire
#   class of APIs at once - including the ones inside DLLs we cannot patch.
#
# WHY A POST-BUILD STEP AND NOT hxcpp's `manifestFile` DEFINE
#   hxcpp does support `-DmanifestFile=...` (msvc-toolchain.xml ships a
#   <manifest exe="mt.exe"> block), but the BuildTool copy that this project
#   links against (.haxelib/hxcpp, a locally patched build) dropped the
#   <outPre>/<outPost> cases, so it invokes mt.exe without -outputresource: and
#   the build dies with c10100a8.  Doing it here keeps the fix in version
#   control and independent of any hxcpp internal.
#
# NOTE: This file is intentionally ASCII-only.  Windows PowerShell 5.1 decodes
#   BOM-less script files using the ANSI code page, so non-ASCII comments would
#   be silently mangled.  Chinese explanation lives in Project.xml and
#   windows/NovaFlare.manifest instead.
#
# The step is BEST EFFORT: it never fails the build.  If it cannot run it
# prints a loud warning, because silently shipping an exe without the manifest
# means Chinese paths stay broken.
# ---------------------------------------------------------------------------

$ErrorActionPreference = 'Continue'

function Write-Info([string]$msg) { Write-Host "[utf8-manifest] $msg" }
function Write-Warn([string]$msg) { Write-Host "[utf8-manifest] WARNING: $msg" -ForegroundColor Yellow }

$projectRoot = Split-Path -Parent $PSScriptRoot
$manifestPath = Join-Path $projectRoot 'windows\NovaFlare.manifest'

if (-not (Test-Path -LiteralPath $manifestPath)) {
	Write-Warn "manifest not found at $manifestPath - skipping (Chinese paths will NOT work)"
	exit 0
}

# --- 1. find the built executable -----------------------------------------
# lime builds into export/<config>/windows/bin/.  This project has SEVERAL
# configs: release, debug, and the GC-comparison variant `legacy-gc`
# (built with: haxelib run lime build windows -release -D legacy_gc_compare).
# We must embed into EVERY windows bin dir that holds an exe - missing one means
# that build silently ships without the UTF-8 code page (this actually happened:
# an earlier version only scanned release/debug and the legacy-gc build - the one
# being used for testing - never got the manifest).
$exeCandidates = @()
$exportDir = Join-Path $projectRoot 'export'
foreach ($configDir in @(Get-ChildItem -LiteralPath $exportDir -Directory -ErrorAction SilentlyContinue)) {
	$binDir = Join-Path $configDir.FullName 'windows\bin'
	if (Test-Path -LiteralPath $binDir) {
		$exeCandidates += @(Get-ChildItem -LiteralPath $binDir -Filter '*.exe' -File -ErrorAction SilentlyContinue)
	}
}

if ($exeCandidates.Count -eq 0) {
	# Not a Windows build (android/ios/...) - nothing to do, stay quiet.
	exit 0
}

# Newest first: the config that was just built is the one to report on.
$exeCandidates = @($exeCandidates | Sort-Object LastWriteTime -Descending)

# --- 2. find mt.exe (Manifest Tool) ---------------------------------------
$mt = $null

$onPath = Get-Command 'mt.exe' -ErrorAction SilentlyContinue
if ($onPath -ne $null) { $mt = $onPath.Source }

if ($mt -eq $null) {
	$sdkRoots = @()
	if ($env:ProgramFiles) { $sdkRoots += (Join-Path $env:ProgramFiles 'Windows Kits\10\bin') }
	if (${env:ProgramFiles(x86)}) { $sdkRoots += (Join-Path ${env:ProgramFiles(x86)} 'Windows Kits\10\bin') }

	$found = @()
	foreach ($root in $sdkRoots) {
		if (Test-Path -LiteralPath $root) {
			$found += @(Get-ChildItem -LiteralPath $root -Recurse -Filter 'mt.exe' -File -ErrorAction SilentlyContinue |
				Where-Object { $_.Directory.Name -eq 'x64' })
		}
	}
	if ($found.Count -gt 0) {
		# Newest SDK version wins (10.0.26100.0 > 10.0.22621.0 ...).
		$mt = ($found | Sort-Object { $_.Directory.Parent.Name } -Descending | Select-Object -First 1).FullName
	}
}

if ($mt -eq $null) {
	Write-Warn 'mt.exe (Windows SDK Manifest Tool) was not found on PATH or under Windows Kits\10\bin.'
	Write-Warn 'The exe was built WITHOUT the UTF-8 activeCodePage manifest - Chinese/non-ASCII paths may fail to load.'
	Write-Warn 'Install the Windows SDK "Desktop development with C++" workload, then re-run this script.'
	exit 0
}

Write-Info ("mt.exe     : " + $mt)

# --- 3+4. embed into every candidate, then verify by reading it back --------
# NOTE: the ;#1 suffix must stay inside the same PowerShell string, otherwise
# PowerShell splits it off as a separate token and mt.exe fails with c1010007.
$anyVerified = $false
$allVerified = $true

foreach ($exe in $exeCandidates) {
	Write-Info ("target exe : " + $exe.FullName)

	$resourceArg = '-outputresource:' + $exe.FullName + ';#1'
	& $mt '-nologo' '-manifest' $manifestPath $resourceArg | Out-Null
	$embedExit = $LASTEXITCODE

	if ($embedExit -ne 0) {
		Write-Warn ("mt.exe failed (exit $embedExit) - manifest NOT embedded into " + $exe.FullName)
		$allVerified = $false
		continue
	}

	$checkFile = Join-Path $env:TEMP ('nf_manifest_check_' + [System.Guid]::NewGuid().ToString('N') + '.xml')
	$inputArg = '-inputresource:' + $exe.FullName + ';#1'
	& $mt '-nologo' $inputArg ('-out:' + $checkFile) | Out-Null
	$verifyExit = $LASTEXITCODE

	$ok = $false
	if ($verifyExit -eq 0 -and (Test-Path -LiteralPath $checkFile)) {
		$text = Get-Content -LiteralPath $checkFile -Raw
		if ($text -match 'activeCodePage' -and $text -match 'UTF-8') { $ok = $true }
		Remove-Item -LiteralPath $checkFile -Force -ErrorAction SilentlyContinue
	}

	if ($ok) {
		$anyVerified = $true
		Write-Info '  OK - activeCodePage=UTF-8 embedded and verified.'
	} else {
		$allVerified = $false
		Write-Warn '  the manifest resource could not be verified after embedding.'
	}
}

if ($anyVerified -and $allVerified) {
	Write-Info 'OK - activeCodePage=UTF-8 embedded and verified. Chinese / non-ASCII paths are handled.'
} elseif (-not $anyVerified) {
	Write-Warn 'no exe could be verified - Chinese / non-ASCII paths may fail to load.'
}

exit 0
