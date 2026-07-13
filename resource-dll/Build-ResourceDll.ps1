[CmdletBinding()]
param(
    [ValidatePattern('^v[0-9]+$')]
    [string] $Profile = 'v2603',
    [switch] $Force
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$repositoryRoot = Split-Path $PSScriptRoot -Parent
$manifestPath = Join-Path $PSScriptRoot "profiles/$Profile/manifest.json"
if (-not (Test-Path -LiteralPath $manifestPath -PathType Leaf)) {
    throw "Unknown resource profile: $Profile"
}

& (Join-Path $repositoryRoot 'tools/validation/Test-ResourceManifest.ps1') -ManifestPath $manifestPath -SkipGeneratedCheck
$manifest = Get-Content -Raw -LiteralPath $manifestPath | ConvertFrom-Json

$rc = Get-Command rc.exe -CommandType Application -ErrorAction SilentlyContinue
$link = Get-Command link.exe -CommandType Application -ErrorAction SilentlyContinue
if (-not $rc -or -not $link) {
    throw 'rc.exe and link.exe are required. Run this script from a Visual Studio Developer PowerShell.'
}

$buildDirectory = Join-Path $repositoryRoot "build/$Profile"
$distDirectory = Join-Path $repositoryRoot "dist/$Profile"
$resourceFile = Join-Path $buildDirectory 'MOResources.res'
$buildHeader = Join-Path $buildDirectory 'resource.h'
$buildRc = Join-Path $buildDirectory 'ResourceMap.rc'
$outputFile = Join-Path $distDirectory $manifest.outputName
New-Item -ItemType Directory -Path $buildDirectory, $distDirectory -Force | Out-Null

& (Join-Path $repositoryRoot 'tools/validation/New-ResourceFiles.ps1') -ManifestPath $manifestPath -HeaderPath $buildHeader -RcPath $buildRc -AbsoluteAssetPaths

if ((Test-Path -LiteralPath $outputFile) -and -not $Force) {
    throw "Output exists: $outputFile. Use -Force to replace it."
}

Push-Location $buildDirectory
try {
    & $rc.Source /nologo "/fo$resourceFile" $buildRc
    if ($LASTEXITCODE -ne 0) { throw "rc.exe failed with exit code $LASTEXITCODE." }
    $machine = if ($manifest.architecture -eq 'x86') { 'X86' } else { 'X64' }
    & $link.Source /nologo /dll /noentry "/machine:$machine" "/out:$outputFile" $resourceFile
    if ($LASTEXITCODE -ne 0) { throw "link.exe failed with exit code $LASTEXITCODE." }
}
finally {
    Pop-Location
}

Get-Item -LiteralPath $outputFile
