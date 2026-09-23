# Embed Windows-configured mobile Editor key JSON files as a Haxe constant class.
# Source: export/legacy-gc/windows/bin/FuckYouNFEMobile/<EditorId>NewFuckingButtonMobile.json
# Output: source/mobile/objects/EditorMobileKeyDefaults.hx
# Usage: pwsh -File tools/gen-editor-key-defaults.ps1
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$srcDir = Join-Path $root 'export\legacy-gc\windows\bin\FuckYouNFEMobile'
$outPath = Join-Path $root 'source\mobile\objects\EditorMobileKeyDefaults.hx'

$files = Get-ChildItem $srcDir -Filter '*NewFuckingButtonMobile.json' -File |
    Where-Object { $_.Length -gt 0 } |
    Sort-Object Name

if ($files.Count -eq 0) { throw "no configured key files under $srcDir" }

$sb = New-Object System.Text.StringBuilder
[void]$sb.AppendLine('package mobile.objects;')
[void]$sb.AppendLine('')
[void]$sb.AppendLine('/**')
[void]$sb.AppendLine(' * Built-in mobile Editor key configs shipped inside the APK.')
[void]$sb.AppendLine(' * First enable writes these into the device storage folder.')
[void]$sb.AppendLine(' * Regenerate with: tools/gen-editor-key-defaults.ps1')
[void]$sb.AppendLine(' */')
[void]$sb.AppendLine('class EditorMobileKeyDefaults')
[void]$sb.AppendLine('{')

foreach ($f in $files) {
    $editorId = $f.Name -replace 'NewFuckingButtonMobile\.json$', ''
    $content = [System.IO.File]::ReadAllText($f.FullName, [System.Text.Encoding]::UTF8)
    # Haxe single-quoted string escaping: backslash and single quote.
    $escaped = $content.Replace('\', '\\').Replace("'", "\'")
    [void]$sb.AppendLine("	static final C_${editorId}:String = '$escaped';")
    Write-Host "embedded $($f.Name) ($($content.Length) chars)"
}

[void]$sb.AppendLine('')
[void]$sb.AppendLine('	/** Built-in config for an Editor id, or null when none was embedded. */')
[void]$sb.AppendLine('	public static function get(editorId:String):Null<String>')
[void]$sb.AppendLine('	{')
[void]$sb.AppendLine('		switch (editorId)')
[void]$sb.AppendLine('		{')
foreach ($f in $files) {
    $editorId = $f.Name -replace 'NewFuckingButtonMobile\.json$', ''
    [void]$sb.AppendLine("			case '$editorId': return C_${editorId};")
}
[void]$sb.AppendLine('		}')
[void]$sb.AppendLine('		return null;')
[void]$sb.AppendLine('	}')
[void]$sb.AppendLine('}')
[void]$sb.AppendLine('')

[System.IO.File]::WriteAllText($outPath, $sb.ToString(), (New-Object System.Text.UTF8Encoding($false)))
Write-Host "generated $outPath"
