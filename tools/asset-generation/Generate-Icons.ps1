[CmdletBinding()]
param(
    [string] $ManifestPath = (Join-Path $PSScriptRoot 'icon-manifest.json'),
    [string] $OutputDirectory = (Join-Path $PSScriptRoot 'generated'),
    [switch] $Force
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$manifestFile = (Resolve-Path -LiteralPath $ManifestPath).Path
$manifestRoot = Split-Path $manifestFile -Parent
$manifest = Get-Content -Raw -LiteralPath $manifestFile | ConvertFrom-Json

if (-not $manifest.icons -or -not $manifest.sizes) {
    throw 'Icon manifest must define non-empty icons and sizes arrays.'
}

$seen = @{}
foreach ($icon in $manifest.icons) {
    if ([IO.Path]::IsPathRooted($icon.source) -or [IO.Path]::IsPathRooted($icon.output)) {
        throw 'Icon manifest paths must be relative.'
    }
    if ([IO.Path]::GetExtension($icon.output) -ne '.ico' -or $icon.output -match '[/\\]') {
        throw "Icon output must be a simple .ico filename: $($icon.output)"
    }
    if ($seen.ContainsKey($icon.output)) {
        throw "Duplicate icon output: $($icon.output)"
    }
    $seen[$icon.output] = $true

    $source = [IO.Path]::GetFullPath((Join-Path $manifestRoot $icon.source))
    if (-not (Test-Path -LiteralPath $source -PathType Leaf)) {
        throw "Icon source does not exist: $source"
    }
    $output = Join-Path ([IO.Path]::GetFullPath($OutputDirectory)) $icon.output
    & (Join-Path $PSScriptRoot 'ConvertTo-ICO.ps1') -SourceFilePath $source -OutputPath $output -Sizes $manifest.sizes -Force:$Force
}
