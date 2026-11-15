[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)] [string] $AssetsRoot
)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Net.Http
$compatAssetsRoot = (Resolve-Path -LiteralPath $AssetsRoot).Path
$compatProfileRoot = Join-Path $compatAssetsRoot 'compatibility/origin-v0.3.2'
$compatManifestPath = Join-Path $compatProfileRoot 'manifest.json'
$compatOldManifest = if (Test-Path -LiteralPath $compatManifestPath) {
    Get-Content -Raw -LiteralPath $compatManifestPath | ConvertFrom-Json
} else { $null }
$compatSources = [System.Collections.Generic.List[object]]::new()
$compatUtf8 = [System.Text.UTF8Encoding]::new($false)

function Get-CompatHash([byte[]] $Bytes) {
    $algorithm = [System.Security.Cryptography.SHA256]::Create()
    try { return ([BitConverter]::ToString($algorithm.ComputeHash($Bytes))).Replace('-', '').ToLowerInvariant() }
    finally { $algorithm.Dispose() }
}

function Save-CompatResource([string] $RelativePath, [byte[]] $Bytes, [string] $Source) {
    $destination = [IO.Path]::GetFullPath((Join-Path $compatProfileRoot $RelativePath))
    $prefix = [IO.Path]::GetFullPath($compatProfileRoot).TrimEnd('\', '/') + [IO.Path]::DirectorySeparatorChar
    if (-not $destination.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase)) {
        throw "Compatibility resource escapes its assets directory: $RelativePath"
    }
    $hash = Get-CompatHash $Bytes
    if (Test-Path -LiteralPath $destination) {
        $currentHash = (Get-FileHash -LiteralPath $destination -Algorithm SHA256).Hash.ToLowerInvariant()
        $managed = @($compatOldManifest.sources | Where-Object { $_.path -eq $RelativePath })
        if ($currentHash -ne $hash -and ($managed.Count -ne 1 -or $currentHash -ne $managed[0].sha256)) {
            throw "Preserving a locally modified or unmanaged profile file: $destination"
        }
    }
    [IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($destination)) | Out-Null
    [IO.File]::WriteAllBytes($destination, $Bytes)
    $compatSources.Add([ordered]@{ path = $RelativePath; source = $Source; sha256 = $hash })
}

$compatCommit = '962130b2243a839106607d08a11599b1857bf8b3'
$compatSourceRoot = "https://raw.githubusercontent.com/FunkinCrew/funkin.assets/$compatCommit"
$compatClient = [System.Net.Http.HttpClient]::new()
try {
    $compatClient.DefaultRequestHeaders.UserAgent.ParseAdd('NovaFlare-Origin-Compatibility-Setup/1.0')
    $dataUrl = "$compatSourceRoot/preload/data/characters/bf.json"
    $oldBfText = $compatClient.GetStringAsync($dataUrl).GetAwaiter().GetResult()
    $oldBf = $oldBfText | ConvertFrom-Json
    if ($oldBf.renderType -ne 'multisparrow') { throw 'Unexpected historical BF renderer.' }
    $oldBf.assetPath = 'gameplay/characters/bf/bf'
    $currentDataPath = Join-Path $compatAssetsRoot 'gameplay/characters/bf/bf.json'
    $currentData = Get-Content -Raw -LiteralPath $currentDataPath | ConvertFrom-Json
    $currentFakeout = @($currentData.animations | Where-Object { $_.name -eq 'fakeoutDeath' })
    if ($currentFakeout.Count -ne 1) { throw 'Review current BF fakeout animation before installing a classic profile.' }
    $currentFakeout[0] | Add-Member -NotePropertyName renderType -NotePropertyValue 'animateatlas' -Force
    $oldBf.animations = @($oldBf.animations | ForEach-Object {
        if ($_.name -eq 'fakeoutDeath') { $currentFakeout[0] }
        else {
            if ($_.assetPath -eq 'characters/BFCheer') {
                $_.assetPath = 'compatibility/origin-v0.3.2/sprites/BFCheer'
            }
            elseif ($_.assetPath -eq 'characters/BOYFRIEND') { $_.assetPath = 'gameplay/characters/bf/bf' }
            $_
        }
    })
    Save-CompatResource 'characters/bf.json' $compatUtf8.GetBytes(($oldBf | ConvertTo-Json -Depth 64)) $dataUrl

    # Store templates as text so inactive profiles cannot register duplicate script classes.
    $currentScriptPath = Join-Path $compatAssetsRoot 'gameplay/characters/bf/bf.hxc'
    $currentScript = Get-Content -Raw -LiteralPath $currentScriptPath
    if ([regex]::Matches($currentScript, '\bMultiAnimateAtlasCharacter\b').Count -ne 2) {
        throw 'Review current BoyfriendCharacter before adapting its renderer.'
    }
    $classicScript = $currentScript.Replace('MultiAnimateAtlasCharacter', 'MultiSparrowCharacter')
    if ([regex]::Matches($classicScript, "case 'IMAGE':").Count -ne 1 -or [regex]::Matches($classicScript, "case 'SOUND':").Count -ne 1) {
        throw 'Review stock character asset queries before adding classic atlas dependencies.'
    }
    $classicScript = $classicScript.Replace("case 'IMAGE':", "case 'IMAGE':`n        results.push(NewPaths.image('compatibility/origin-v0.3.2/sprites/BFCheer'));")
    $classicScript = $classicScript.Replace("case 'SOUND':", "case 'XML':`n        results.push(NewPaths.file('compatibility/origin-v0.3.2/sprites/BFCheer', 'xml'));`n      case 'SOUND':")
    Save-CompatResource 'scripts/bf.hxc.txt' $compatUtf8.GetBytes($classicScript) 'current external gameplay/characters/bf/bf.hxc; renderer adapted only'

    foreach ($extension in @('png', 'xml')) {
        $url = "$compatSourceRoot/shared/images/characters/BFCheer.$extension"
        $bytes = $compatClient.GetByteArrayAsync($url).GetAwaiter().GetResult()
        if ($extension -eq 'png' -and ($bytes.Length -lt 8 -or [BitConverter]::ToString($bytes[0..7]) -ne '89-50-4E-47-0D-0A-1A-0A')) {
            throw 'Historical cheer image is not a PNG.'
        }
        if ($extension -eq 'xml') {
            $xmlText = $compatUtf8.GetString($bytes).TrimStart([char]0xFEFF)
            [xml] $validatedXml = $xmlText
            $bytes = $compatUtf8.GetBytes($xmlText)
        }
        Save-CompatResource "sprites/BFCheer.$extension" $bytes $url
    }

    $manifest = [ordered]@{
        version = 1
        upstreamAssetsCommit = $compatCommit
        profiles = @([ordered]@{
            id = 'bf'
            images = @('gameplay/characters/bf/bf.png', 'compatibility/origin-v0.3.2/sprites/BFCheer.png')
            modernPrefixes = @($currentData.assetPath.TrimEnd('/') + '/')
            metadata = 'characters/bf.json'
            script = 'scripts/bf.hxc.txt'
            scriptAsset = 'gameplay/characters/bf/bf.hxc'
        })
        sources = @($compatSources.ToArray())
    }
    # PNG-only replacements need the matching old XML/animation definitions. These
    # resources remain external, alongside the user's current Origin asset pack.
    $stock = [ordered]@{
        'dad' = 'daddyDearest'; 'gf' = 'GF_assets'; 'bf-car' = 'bfCar'; 'gf-car' = 'gfCar'
        'gf-christmas' = 'gfChristmas'; 'mom-car' = 'momCar'; 'monster' = 'Monster_Assets'
        'monster-christmas' = 'monsterChristmas'; 'parents-christmas' = 'mom_dad_christmas_assets'
        'pico' = 'Pico_Basic'; 'tankman' = 'tankmanCaptain'
    }
    foreach ($id in $stock.Keys) {
        $url = "$compatSourceRoot/preload/data/characters/$id.json"
        $old = $compatClient.GetStringAsync($url).GetAwaiter().GetResult() | ConvertFrom-Json
        if ($old.assetPath -ne "characters/$($stock[$id])") { throw "Review historical $id asset path." }
        if (-not $old.renderType) { $old | Add-Member -NotePropertyName renderType -NotePropertyValue 'sparrow' -Force }
        if ($old.renderType -notin @('sparrow', 'multisparrow')) { throw "Review historical $id renderer." }
        $old.assetPath = "compatibility/origin-v0.3.2/sprites/$id"
        foreach ($animation in $old.animations) {
            if ($animation.assetPath -eq 'characters/BOYFRIEND') { $animation.assetPath = 'gameplay/characters/bf/bf' }
            elseif ($animation.assetPath) { throw "Review historical $id additional atlas: $($animation.assetPath)" }
        }
        Save-CompatResource "characters/$id.json" $compatUtf8.GetBytes(($old | ConvertTo-Json -Depth 64)) $url
        foreach ($extension in @('png', 'xml')) {
            $url = "$compatSourceRoot/shared/images/characters/$($stock[$id]).$extension"
            $bytes = $compatClient.GetByteArrayAsync($url).GetAwaiter().GetResult()
            if ($extension -eq 'png' -and ($bytes.Length -lt 8 -or [BitConverter]::ToString($bytes[0..7]) -ne '89-50-4E-47-0D-0A-1A-0A')) {
                throw "Historical $id image is not a PNG."
            }
            if ($extension -eq 'xml') {
                $xmlText = $compatUtf8.GetString($bytes).TrimStart([char]0xFEFF)
                [xml] $validatedXml = $xmlText
                $bytes = $compatUtf8.GetBytes($xmlText)
            }
            Save-CompatResource "sprites/$id.$extension" $bytes $url
        }
        $current = Get-Content -Raw -LiteralPath (Join-Path $compatAssetsRoot "gameplay/characters/$id/$id.json") | ConvertFrom-Json
        $profile = [ordered]@{
            id = $id
            images = @("compatibility/origin-v0.3.2/sprites/$id.png")
            modernPrefixes = @($current.assetPath.TrimEnd('/') + '/')
            metadata = "characters/$id.json"
        }
        $currentScriptPath = Join-Path $compatAssetsRoot "gameplay/characters/$id/$id.hxc"
        if (Test-Path -LiteralPath $currentScriptPath) {
            $currentScript = Get-Content -Raw -LiteralPath $currentScriptPath
            if ($id -eq 'monster') {
                # The current script only hides Animate-specific hat layers.
                # Old Sparrow frames already have the original appearance.
                $methods = @([regex]::Matches($currentScript, '\bfunction\s+(\w+)') | ForEach-Object { $_.Groups[1].Value })
                if (($methods -join ',') -ne 'new,getAtlasSettings') { throw 'Review current MonsterCharacter behavior.' }
                $classicScript = "import funkin.play.character.SparrowCharacter;`nclass MonsterCharacter extends SparrowCharacter {`n  public function new() { super('monster'); }`n}`n"
                $scriptBase = 'SparrowCharacter'
            } else {
                $base = [regex]::Match($currentScript, '\bextends\s+(MultiAnimateAtlasCharacter|AnimateAtlasCharacter)\b').Groups[1].Value
                if (-not $base -or [regex]::Matches($currentScript, "\b$base\b").Count -ne 2) {
                    throw "Review current $id script renderer before adapting it."
                }
                $scriptBase = if ($old.renderType -eq 'multisparrow') { 'MultiSparrowCharacter' } else { 'SparrowCharacter' }
                $classicScript = $currentScript.Replace($base, $scriptBase)
            }
            Save-CompatResource "scripts/$id.hxc.txt" $compatUtf8.GetBytes($classicScript) "current external gameplay/characters/$id/$id.hxc; classic renderer adapter"
            $profile.script = "scripts/$id.hxc.txt"
            $profile.scriptAsset = "gameplay/characters/$id/$id.hxc"
            $profile.scriptBase = $scriptBase
        }
        $manifest.profiles += @($profile)
    }
    # The modern stage replaced five colored window images with one texture.
    # Old stage scripts still address each original image independently.
    foreach ($light in 0..4) {
        $url = "$compatSourceRoot/week3/images/philly/win$light.png"
        $bytes = $compatClient.GetByteArrayAsync($url).GetAwaiter().GetResult()
        if ($bytes.Length -lt 8 -or [BitConverter]::ToString($bytes[0..7]) -ne '89-50-4E-47-0D-0A-1A-0A') {
            throw "Historical Philly light $light is not a PNG."
        }
        Save-CompatResource "stages/phillyTrain/win$light.png" $bytes $url
    }
    # The Erect variant used different original textures, fixed to the official 0.5.1 assets revision.
    $erectRoot = 'https://raw.githubusercontent.com/FunkinCrew/funkin.assets/b2404b6b1cba47da8eef4910f49985d54318186b/week3/images/philly/erect'
    $erectHashes = @(
        'c774ff42667c8736862bbbb6191eb934849d2270cbcacde9012533a32c82151b',
        '9ac729b7229943fac6e8d0412a2066195aa46a4f9ff64f5af33bc7261aea446b',
        '438aefa57d39ea863eb1d95f76e74098a59f2a2f898f83479e161fb6266c87ef',
        '1b05314ea2592dcad2995708c2eecff21cdccf5e3b8b66c5fd8530947837d935',
        '1111d5a75c17d7ccdae983e50ca0aee3403ead201e04bbfd42e4b2fe8cbb706e'
    )
    foreach ($light in 0..4) {
        $url = "$erectRoot/win$light.png"
        $bytes = $compatClient.GetByteArrayAsync($url).GetAwaiter().GetResult()
        if ((Get-CompatHash $bytes) -ne $erectHashes[$light]) { throw "Historical Philly Erect light $light failed hash verification." }
        Save-CompatResource "stages/phillyTrainErect/win$light.png" $bytes $url
    }
    # Historical Nene scripts/data explicitly select a Sparrow renderer.
    # Keep its atlas available without replacing the current Animate profile.
    foreach ($extension in @('png', 'xml')) {
        $url = "$compatSourceRoot/shared/images/characters/Nene.$extension"
        $bytes = $compatClient.GetByteArrayAsync($url).GetAwaiter().GetResult()
        if ($extension -eq 'png' -and ($bytes.Length -lt 8 -or [BitConverter]::ToString($bytes[0..7]) -ne '89-50-4E-47-0D-0A-1A-0A')) {
            throw 'Historical Nene image is not a PNG.'
        }
        if ($extension -eq 'xml') {
            $xmlText = $compatUtf8.GetString($bytes).TrimStart([char]0xFEFF)
            [xml] $validatedXml = $xmlText
            $bytes = $compatUtf8.GetBytes($xmlText)
        }
        Save-CompatResource "sprites/nene.$extension" $bytes $url
    }
    $manifest.sources = @($compatSources.ToArray())
    # Retain other installed profiles and their source records when extending this pack.
    if ($null -ne $compatOldManifest) {
        $newIds = @($manifest.profiles | ForEach-Object { $_.id })
        $manifest.profiles = @($manifest.profiles) + @($compatOldManifest.profiles | Where-Object { $_.id -notin $newIds })
        $newPaths = @($compatSources | ForEach-Object { $_.path })
        $manifest.sources = @($manifest.sources) + @($compatOldManifest.sources | Where-Object { $_.path -notin $newPaths })
    }
    [IO.File]::WriteAllText($compatManifestPath, ($manifest | ConvertTo-Json -Depth 64), $compatUtf8)
    Write-Output "Installed $($manifest.profiles.Count) external Origin classic character profiles, ten Philly stage lights and the historical Nene atlas: $compatProfileRoot"
}
finally { $compatClient.Dispose() }
