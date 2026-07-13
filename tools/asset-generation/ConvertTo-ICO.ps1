<#
.SYNOPSIS
Converts one SVG or PNG image to a validated multi-resolution ICO.

.DESCRIPTION
Uses ImageMagick 7 to render configured square frames. The ICO is produced in
the destination directory as a temporary file, validated with `magick identify`,
and atomically promoted. Existing output is protected unless -Force is supplied.

.PARAMETER SourceFilePath
Path to an SVG or PNG source image.

.PARAMETER OutputPath
Destination ICO path. By default, `<name>_<extension>.ico` beside the source.

.PARAMETER Sizes
ICO frame sizes in pixels. Defaults to 256, 64, 48, 32, 24, and 16.

.PARAMETER Force
Atomically replaces an existing destination.

.EXAMPLE
./ConvertTo-ICO.ps1 -SourceFilePath ./logo.svg

.EXAMPLE
./ConvertTo-ICO.ps1 ./logo.png -OutputPath ./generated/logo.ico -Sizes 256,48,32,16 -Force
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory, Position = 0)]
    [ValidateNotNullOrEmpty()]
    [string] $SourceFilePath,

    [Parameter()]
    [string] $OutputPath,

    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [int[]] $Sizes = @(256, 64, 48, 32, 24, 16),

    [Parameter()]
    [switch] $Force
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$magick = Get-Command magick -CommandType Application -ErrorAction SilentlyContinue
if (-not $magick) {
    throw 'ImageMagick 7 is required. Install it and ensure magick.exe is available on PATH.'
}

$LASTEXITCODE = 0
$versionText = (& $magick.Source -version | Select-Object -First 1)
if ($LASTEXITCODE -ne 0 -or $versionText -notmatch 'ImageMagick 7\.') {
    throw "ImageMagick 7 is required; detected: $versionText"
}

if (-not (Test-Path -LiteralPath $SourceFilePath -PathType Leaf)) {
    throw "Source file not found: $SourceFilePath"
}

$source = (Resolve-Path -LiteralPath $SourceFilePath).Path
$extension = [IO.Path]::GetExtension($source).ToLowerInvariant()
if ($extension -notin @('.svg', '.png')) {
    throw "Unsupported source extension '$extension'. Expected .svg or .png."
}

$normalizedSizes = @($Sizes | Sort-Object -Unique -Descending)
if ($normalizedSizes.Count -ne $Sizes.Count -or ($normalizedSizes | Where-Object { $_ -lt 1 -or $_ -gt 256 })) {
    throw 'Sizes must be unique integers from 1 through 256.'
}

if ([string]::IsNullOrWhiteSpace($OutputPath)) {
    $name = [IO.Path]::GetFileNameWithoutExtension($source)
    $OutputPath = Join-Path ([IO.Path]::GetDirectoryName($source)) "$name`_$($extension.TrimStart('.')).ico"
}

$output = [IO.Path]::GetFullPath($OutputPath)
if ($output -eq $source) {
    throw 'OutputPath must differ from SourceFilePath.'
}
if ([IO.Path]::GetExtension($output) -ne '.ico') {
    throw 'OutputPath must use the .ico extension.'
}
if ((Test-Path -LiteralPath $output) -and -not $Force) {
    throw "Output already exists: $output. Use -Force to replace it."
}

$outputDirectory = [IO.Path]::GetDirectoryName($output)
if (-not (Test-Path -LiteralPath $outputDirectory)) {
    New-Item -ItemType Directory -Path $outputDirectory -Force | Out-Null
}

$temporary = Join-Path $outputDirectory ".$([IO.Path]::GetFileName($output)).$([guid]::NewGuid().ToString('N')).tmp.ico"
try {
    $sizeList = $normalizedSizes -join ','
    $LASTEXITCODE = 0
    & $magick.Source -background none $source -define "icon:auto-resize=$sizeList" $temporary
    if ($LASTEXITCODE -ne 0) {
        throw "ImageMagick conversion failed with exit code $LASTEXITCODE."
    }
    if (-not (Test-Path -LiteralPath $temporary -PathType Leaf) -or (Get-Item -LiteralPath $temporary).Length -eq 0) {
        throw 'ImageMagick did not produce a non-empty ICO.'
    }

    $LASTEXITCODE = 0
    $identifyOutput = (& $magick.Source identify -format "%wx%h`n" $temporary) -join "`n"
    if ($LASTEXITCODE -ne 0) {
        throw "ImageMagick frame inspection failed with exit code $LASTEXITCODE."
    }
    $actualSizes = @([regex]::Matches($identifyOutput, '(?m)^(\d+)x\1$') | ForEach-Object { [int] $_.Groups[1].Value } | Sort-Object -Unique -Descending)
    if (($actualSizes -join ',') -ne ($normalizedSizes -join ',')) {
        throw "ICO frame validation failed. Expected $($normalizedSizes -join ','); found $($actualSizes -join ',')."
    }

    if (Test-Path -LiteralPath $output) {
        # The overwrite overload uses the same-volume MoveFileEx path on Windows.
        [IO.File]::Move($temporary, $output, $true)
    }
    else {
        [IO.File]::Move($temporary, $output)
    }

    Get-Item -LiteralPath $output
}
finally {
    if (Test-Path -LiteralPath $temporary) {
        Remove-Item -LiteralPath $temporary -Force
    }
}
