# Resolves KoordASIO version and release metadata for GitHub Actions.
# Writes results to $env:GITHUB_OUTPUT when present.

$ErrorActionPreference = 'Stop'

function Set-GhOutput {
    param(
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter(Mandatory = $true)][string]$Value
    )
    Write-Output "$Name=$Value"
    if ($env:GITHUB_OUTPUT) {
        Add-Content -Path $env:GITHUB_OUTPUT -Value "$Name=$Value"
    }
}

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot '..\..')
$versionFile = Join-Path $repoRoot 'kdASIOVersion.txt'
$versionLine = Get-Content $versionFile | Where-Object { $_ -match '^\s*VERSION\s*=\s*(.+)$' } | Select-Object -First 1
if (-not $versionLine) {
    throw "Could not parse VERSION from $versionFile"
}
$koordasioVersion = ($versionLine -replace '^\s*VERSION\s*=\s*', '').Trim()

$gitHash = (git -C $repoRoot describe --match=xxxxxxxxxxxxxxxxxxxx --always --abbrev --dirty).Trim()
if ($koordasioVersion -match 'dev') {
    $buildVersion = "$koordasioVersion-$gitHash"
    $buildType = 'intermediate'
} else {
    $buildVersion = $koordasioVersion
    $buildType = 'release'
}

Write-Output "Building $buildType version $buildVersion"
Set-GhOutput -Name 'KOORDASIO_VERSION' -Value $koordasioVersion
Set-GhOutput -Name 'BUILD_VERSION' -Value $buildVersion

$fullRef = $env:GITHUB_REF
$publishToRelease = $false
if ($fullRef -match '^refs/tags/r\d+_\d+_\d+\S*$') {
    $publishToRelease = $true
}
Set-GhOutput -Name 'PUBLISH_TO_RELEASE' -Value ($(if ($publishToRelease) { 'true' } else { 'false' }))

if ($publishToRelease) {
    $releaseTag = $fullRef.Split('/', 3)[2]
    $releaseTitle = "Release $buildVersion ($releaseTag)"
    $isPrerelease = -not ($releaseTag -match '^r\d+_\d+_\d+$')
    if (-not $isPrerelease) {
        $tagVersion = $releaseTag.Substring(1).Replace('_', '.')
        if ($buildVersion -ne $tagVersion) {
            throw "Release tag $releaseTag does not match kdASIOVersion.txt VERSION = $buildVersion"
        }
    }
    Set-GhOutput -Name 'IS_PRERELEASE' -Value ($(if ($isPrerelease) { 'true' } else { 'false' }))
    Set-GhOutput -Name 'RELEASE_TITLE' -Value $releaseTitle
    Set-GhOutput -Name 'RELEASE_TAG' -Value $releaseTag
}
