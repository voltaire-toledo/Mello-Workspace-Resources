[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$repositoryRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent

if (Test-Path -LiteralPath (Join-Path $repositoryRoot 'Payload')) {
    throw 'Legacy Payload directory must not exist.'
}

$manifests = @(Get-ChildItem -LiteralPath (Join-Path $repositoryRoot 'resource-dll/profiles') -Filter manifest.json -Recurse -File)
if (-not $manifests) { throw 'No resource profile manifests found.' }
$initialManifest = Join-Path $repositoryRoot 'resource-dll/profiles/v2603/manifest.json'
foreach ($manifest in $manifests) {
    if ($manifest.FullName -eq $initialManifest) {
        & (Join-Path $PSScriptRoot 'Test-ResourceManifest.ps1') -ManifestPath $manifest.FullName
    }
    else {
        & (Join-Path $PSScriptRoot 'Test-ResourceManifest.ps1') -ManifestPath $manifest.FullName -SkipGeneratedCheck
    }
}

$iconManifestPath = Join-Path $repositoryRoot 'tools/asset-generation/icon-manifest.json'
$iconManifest = Get-Content -Raw -LiteralPath $iconManifestPath | ConvertFrom-Json
$iconRoot = Split-Path $iconManifestPath -Parent
$outputs = @{}
foreach ($icon in $iconManifest.icons) {
    $source = [IO.Path]::GetFullPath((Join-Path $iconRoot $icon.source))
    if (-not (Test-Path -LiteralPath $source -PathType Leaf)) { throw "Missing icon source: $($icon.source)" }
    if ($outputs.ContainsKey($icon.output)) { throw "Duplicate generated icon output: $($icon.output)" }
    $outputs[$icon.output] = $true
}

& python (Join-Path $repositoryRoot 'tools/audio-generation/generate_time_announcements.py') --validate-only
if ($LASTEXITCODE -ne 0) { throw 'Audio manifest validation failed.' }

$brokenLinks = [Collections.Generic.List[string]]::new()
foreach ($markdown in Get-ChildItem -LiteralPath $repositoryRoot -Filter *.md -Recurse -File | Where-Object FullName -notmatch '[\\/](\.git|build|dist|\.venv)[\\/]') {
    $content = Get-Content -Raw -LiteralPath $markdown.FullName
    foreach ($match in [regex]::Matches($content, '\[[^\]]+\]\(([^)]+)\)')) {
        $target = $match.Groups[1].Value.Trim('<', '>').Split('#')[0]
        if (-not $target -or $target -match '^(https?|mailto):') { continue }
        $resolved = [IO.Path]::GetFullPath((Join-Path $markdown.DirectoryName ([uri]::UnescapeDataString($target))))
        if (-not (Test-Path -LiteralPath $resolved)) { $brokenLinks.Add("$($markdown.FullName): $target") }
    }
}
if ($brokenLinks.Count) { throw "Broken Markdown links:`n$($brokenLinks -join "`n")" }

Write-Host "Repository validation passed: $($manifests.Count) profile(s), icon/audio manifests, and Markdown links."
