[CmdletBinding()]
param()
$ErrorActionPreference = 'Stop'
$workspace = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$fixtures = Join-Path $PSScriptRoot 'tests/nf_gameplay_eval'
$target = Join-Path $workspace '_build/nf-gameplay-regressions/unit'
New-Item -ItemType Directory -Path $target -Force | Out-Null
Copy-Item -Path (Join-Path $fixtures '*') -Destination $target -Recurse -Force

# Isolate real production method bodies from the engine bootstrap. No replacement
# implementation of the input, missed-hold or pause-clock rules is used here.
$source = [IO.File]::ReadAllText((Join-Path $workspace 'source/games/PlayState.hx'))
$masked = [regex]::Replace($source, '(?s)/\*.*?\*/|//[^\r\n]*|"(?:\\.|[^"\\])*"|''(?:\\.|[^''\\])*''', {
    param($match)
    return ' ' * $match.Length
})
$methods = foreach ($name in @('isBrokenSustain', 'checkSustainMisses', 'keyPressed', 'noteMissCommon', 'replayApplyInput', 'onFocus')) {
    $match = [regex]::Match($source, '(?m)^\t(?:(?:public|private|inline|override)\s+)*function\s+' + $name + '\(')
    if (-not $match.Success) { throw "Production method not found: $name" }
    $open = $masked.IndexOf('{', $match.Index)
    $depth = 1
    $end = $open + 1
    while ($depth -gt 0 -and $end -lt $masked.Length) {
        if ($masked[$end] -eq '{') { $depth++ }
        if ($masked[$end] -eq '}') { $depth-- }
        $end++
    }
    if ($depth -ne 0) { throw "Unclosed production method: $name" }
    $source.Substring($match.Index, $end - $match.Index).Replace('private ', 'public ')
}
$template = [IO.File]::ReadAllText((Join-Path $fixtures 'ProbePlayState.hx.in'))
[IO.File]::WriteAllText((Join-Path $target 'ProbePlayState.hx'), $template.Replace('/* METHODS */', ($methods -join "`n")))
foreach ($file in @('general/objects/screen/MouseEffect.hx', 'games/backend/GameplayVideoPause.hx')) {
    $destination = Join-Path $target $file
    New-Item -ItemType Directory -Path (Split-Path -Parent $destination) -Force | Out-Null
    Copy-Item -LiteralPath (Join-Path $workspace "source/$file") -Destination $destination -Force
}
Push-Location $workspace
try {
    & haxe -lib openfl -lib lime -cp $target -D VIDEOS_ALLOWED -D hxvlc -main Main --interp
    if ($LASTEXITCODE -ne 0) { throw 'NF gameplay regression checks failed' }
} finally { Pop-Location }
