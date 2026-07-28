param(
    [string]$TargetDirectory = (
        Join-Path $PSScriptRoot '..\private\gameanalytics'
    ),
    [switch]$Required
)

$ErrorActionPreference = 'Stop'

$encodedFiles = [ordered]@{
    'GameAnalytics.hx'       = $env:NOVA_GA_IMPL_B64
    'GameAnalyticsTypes.hx'  = $env:NOVA_GA_TYPES_B64
    'GameAnalyticsConfig.hx' = $env:NOVA_GA_CONFIG_B64
}

$missing = @(
    $encodedFiles.GetEnumerator() |
        Where-Object { [string]::IsNullOrWhiteSpace($_.Value) } |
        ForEach-Object { $_.Key }
)

$githubEnvironment = $env:GITHUB_ENV

if ($missing.Count -gt 0) {
    if ($Required) {
        throw (
            'Required private GameAnalytics sources are unavailable: ' +
            ($missing -join ', ')
        )
    }

    if (-not [string]::IsNullOrWhiteSpace($githubEnvironment)) {
        [IO.File]::AppendAllText(
            $githubEnvironment,
            "NOVA_GAMEANALYTICS_DEFINE=$([Environment]::NewLine)",
            [Text.UTF8Encoding]::new($false)
        )
    }

    Write-Warning (
        'Private GameAnalytics secrets are unavailable; analytics will be ' +
        'disabled for this build.'
    )
    exit 0
}

[IO.Directory]::CreateDirectory($TargetDirectory) | Out-Null

foreach ($entry in $encodedFiles.GetEnumerator()) {
    try {
        $bytes = [Convert]::FromBase64String($entry.Value)
    }
    catch {
        throw "The encrypted source for $($entry.Key) is not valid Base64."
    }

    $target = Join-Path $TargetDirectory $entry.Key
    [IO.File]::WriteAllBytes($target, $bytes)
}

if (-not [string]::IsNullOrWhiteSpace($githubEnvironment)) {
    [IO.File]::AppendAllText(
        $githubEnvironment,
        "NOVA_GAMEANALYTICS_DEFINE=-Dgameanalytics_enabled$([Environment]::NewLine)",
        [Text.UTF8Encoding]::new($false)
    )
}

Write-Output 'Private GameAnalytics module restored for this build.'
