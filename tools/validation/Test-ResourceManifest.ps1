[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string] $ManifestPath,
    [switch] $SkipGeneratedCheck
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$manifestFile = (Resolve-Path -LiteralPath $ManifestPath).Path
$profileDirectory = Split-Path $manifestFile -Parent
$resourceRoot = Split-Path (Split-Path $profileDirectory -Parent) -Parent
$manifest = Get-Content -Raw -LiteralPath $manifestFile | ConvertFrom-Json

if ($manifest.profile -ne (Split-Path $profileDirectory -Leaf)) {
    throw "Profile '$($manifest.profile)' does not match directory name."
}
if ($manifest.architecture -notin @('x86', 'x64')) {
    throw "Unsupported architecture: $($manifest.architecture)"
}
if ($manifest.outputName -notmatch '^[^/\\]+\.dll$') {
    throw "Invalid DLL output name: $($manifest.outputName)"
}
$requiredMetadata = @('comments', 'companyName', 'fileDescription', 'internalName', 'legalCopyright', 'productName', 'url')
foreach ($property in $requiredMetadata) {
    if ([string]::IsNullOrWhiteSpace($manifest.metadata.$property)) {
        throw "Profile metadata is missing '$property'."
    }
    if ($manifest.metadata.$property -match '["\r\n]') {
        throw "Profile metadata '$property' cannot contain quotes or newlines."
    }
}
if ($manifest.version.Count -ne 4 -or ($manifest.version | Where-Object { $_ -lt 0 -or $_ -gt 65535 })) {
    throw 'Version must contain four integers from 0 through 65535.'
}
if (-not $manifest.resources) {
    throw 'A profile must contain at least one resource.'
}

$ids = @{}
$symbols = @{}
$expectedExtensions = @{ ICON = '.ico'; WAVE = '.wav'; RCDATA = '.mp3' }
foreach ($resource in $manifest.resources) {
    if ($resource.id -lt 1 -or $resource.id -gt 65535 -or $ids.ContainsKey([string] $resource.id)) {
        throw "Invalid or duplicate resource ID: $($resource.id)"
    }
    if ($resource.symbol -notmatch '^[A-Z][A-Z0-9_]+$' -or $symbols.ContainsKey($resource.symbol)) {
        throw "Invalid or duplicate resource symbol: $($resource.symbol)"
    }
    if (-not $expectedExtensions.ContainsKey($resource.type)) {
        throw "Unsupported resource type: $($resource.type)"
    }
    if ([IO.Path]::IsPathRooted($resource.path) -or $resource.path.Contains('\\') -or $resource.path -match '(^|/)\.\.(/|$)') {
        throw "Resource paths must be safe, relative, and slash-separated: $($resource.path)"
    }
    if ([IO.Path]::GetExtension($resource.path).ToLowerInvariant() -ne $expectedExtensions[$resource.type]) {
        throw "Resource type/extension mismatch: $($resource.path)"
    }
    $asset = [IO.Path]::GetFullPath((Join-Path $resourceRoot $resource.path))
    if (-not $asset.StartsWith($resourceRoot, [StringComparison]::OrdinalIgnoreCase) -or -not (Test-Path -LiteralPath $asset -PathType Leaf)) {
        throw "Referenced asset does not exist beneath resource-dll: $($resource.path)"
    }
    $ids[[string] $resource.id] = $true
    $symbols[$resource.symbol] = $true
}

$voice = @($manifest.resources | Where-Object type -eq 'RCDATA' | Sort-Object id)
if ($manifest.profile -eq 'v2603') {
    if ($manifest.resources.Count -ne 80) { throw "The v2603 contract must contain 80 resources; found $($manifest.resources.Count)." }
    if ($voice.Count -ne 48) { throw "Expected 48 voice resources; found $($voice.Count)." }
    for ($index = 0; $index -lt 48; $index++) {
        $hour = [math]::Floor($index / 2)
        $minute = if ($index % 2 -eq 0) { '00' } else { '30' }
        $expectedId = 300 + $index
        $expectedName = 'Time_{0:00}_{1}.mp3' -f $hour, $minute
        if ($voice[$index].id -ne $expectedId -or (Split-Path $voice[$index].path -Leaf) -cne $expectedName) {
            throw "Voice mapping $index must be ID $expectedId and $expectedName."
        }
    }
}

if (-not $SkipGeneratedCheck) {
    $temporary = Join-Path ([IO.Path]::GetTempPath()) ("mello-resource-check-" + [guid]::NewGuid().ToString('N'))
    try {
        New-Item -ItemType Directory -Path $temporary | Out-Null
        $generatedHeader = Join-Path $temporary 'resource.h'
        $generatedRc = Join-Path $temporary 'ResourceMap.rc'
        & (Join-Path $PSScriptRoot 'New-ResourceFiles.ps1') -ManifestPath $manifestFile -HeaderPath $generatedHeader -RcPath $generatedRc
        foreach ($pair in @(@($generatedHeader, (Join-Path $resourceRoot 'resource.h')), @($generatedRc, (Join-Path $resourceRoot 'ResourceMap.rc')))) {
            $expected = (Get-Content -Raw -LiteralPath $pair[0]) -replace "`r`n", "`n"
            $actual = (Get-Content -Raw -LiteralPath $pair[1]) -replace "`r`n", "`n"
            if ($actual -cne $expected) { throw "$($pair[1]) is stale; regenerate it from the profile manifest." }
        }
    }
    finally {
        if (Test-Path -LiteralPath $temporary) { Remove-Item -LiteralPath $temporary -Recurse -Force }
    }
}

Write-Host "Validated $($manifest.profile): $($manifest.resources.Count) resources and all referenced assets."
