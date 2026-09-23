# 把 mobile-key-editor.html 转成 source/mobile/server/EditorKeyPage.hx（单引号字符串常量）
# 用法: pwsh -File tools/gen-editor-key-page.ps1
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$htmlPath = Join-Path $root 'mobile-key-editor.html'
$outPath  = Join-Path $root 'source\mobile\server\EditorKeyPage.hx'

$content = [System.IO.File]::ReadAllText($htmlPath, [System.Text.Encoding]::UTF8)
if ($content.Length -lt 1000) { throw "html too small? $($content.Length)" }

# 转义：反斜杠、单引号（Haxe 单引号字符串字面量；换行符原样保留）
$escaped = $content.Replace('\', '\\').Replace("'", "\'")

$header = @'
package mobile.server;

/**
 * 外部按键编辑器页面（HTML/JS/CSS 内嵌常量）。
 * 源文件：mobile-key-editor.html —— 修改后用 tools/gen-editor-key-page.ps1 重新生成本文件。
 */
class EditorKeyPage
{
	public static var HTML:String = '
'@
$footer = @'
';
}
'@

$out = $header + $escaped + $footer
[System.IO.File]::WriteAllText($outPath, $out, (New-Object System.Text.UTF8Encoding($false)))
Write-Host "generated $outPath ($($out.Length) chars)"
