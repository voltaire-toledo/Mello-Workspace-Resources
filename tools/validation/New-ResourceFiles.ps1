[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string] $ManifestPath,
    [Parameter(Mandatory)] [string] $HeaderPath,
    [Parameter(Mandatory)] [string] $RcPath,
    [switch] $AbsoluteAssetPaths
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$manifestFile = (Resolve-Path -LiteralPath $ManifestPath).Path
$profileDirectory = Split-Path $manifestFile -Parent
$resourceRoot = Split-Path (Split-Path $profileDirectory -Parent) -Parent
$manifest = Get-Content -Raw -LiteralPath $manifestFile | ConvertFrom-Json
$versionComma = $manifest.version -join ','
$versionDot = $manifest.version -join '.'

$header = [Collections.Generic.List[string]]::new()
$header.Add('// Generated from the active profile manifest. Do not edit by hand.')
$header.Add('#pragma once')
$header.Add('')
foreach ($resource in ($manifest.resources | Sort-Object id)) {
    $header.Add(('#define {0,-28} {1}' -f $resource.symbol, $resource.id))
}
$header.Add('')

$rc = [Collections.Generic.List[string]]::new()
$rc.Add('// Generated from the active profile manifest. Do not edit by hand.')
$rc.Add('#include "resource.h"')
$rc.Add('')
foreach ($resource in ($manifest.resources | Sort-Object id)) {
    $assetPath = if ($AbsoluteAssetPaths) {
        [IO.Path]::GetFullPath((Join-Path $resourceRoot $resource.path)).Replace('\', '/')
    }
    else {
        $resource.path
    }
    $rc.Add(('{0,-28} {1,-7} "{2}"' -f $resource.symbol, $resource.type, $assetPath))
}
$rc.Add('')
$rc.Add('VS_VERSION_INFO VERSIONINFO')
$rc.Add(" FILEVERSION $versionComma")
$rc.Add(" PRODUCTVERSION $versionComma")
$rc.Add(' FILEFLAGSMASK 0x3fL')
$rc.Add(' FILEFLAGS 0x0L')
$rc.Add(' FILEOS 0x40004L')
$rc.Add(' FILETYPE 0x2L')
$rc.Add(' FILESUBTYPE 0x0L')
$rc.Add('BEGIN')
$rc.Add('    BLOCK "StringFileInfo"')
$rc.Add('    BEGIN')
$rc.Add('        BLOCK "040904b0"')
$rc.Add('        BEGIN')
$rc.Add(('            VALUE "Comments", "{0}"' -f $manifest.metadata.comments))
$rc.Add(('            VALUE "CompanyName", "{0}"' -f $manifest.metadata.companyName))
$rc.Add(('            VALUE "FileDescription", "{0}"' -f $manifest.metadata.fileDescription))
$rc.Add(('            VALUE "FileVersion", "{0}"' -f $versionDot))
$rc.Add(('            VALUE "InternalName", "{0}"' -f $manifest.metadata.internalName))
$rc.Add(('            VALUE "LegalCopyright", "{0}"' -f $manifest.metadata.legalCopyright))
$rc.Add(('            VALUE "OriginalFilename", "{0}"' -f $manifest.outputName))
$rc.Add(('            VALUE "ProductName", "{0}"' -f $manifest.metadata.productName))
$rc.Add(('            VALUE "ProductVersion", "{0}"' -f $versionDot))
$rc.Add(('            VALUE "URL", "{0}"' -f $manifest.metadata.url))
$rc.Add('        END')
$rc.Add('    END')
$rc.Add('    BLOCK "VarFileInfo"')
$rc.Add('    BEGIN')
$rc.Add('        VALUE "Translation", 0x409, 1200')
$rc.Add('    END')
$rc.Add('END')
$rc.Add('')

$headerDirectory = Split-Path ([IO.Path]::GetFullPath($HeaderPath)) -Parent
$rcDirectory = Split-Path ([IO.Path]::GetFullPath($RcPath)) -Parent
New-Item -ItemType Directory -Path $headerDirectory, $rcDirectory -Force | Out-Null
Set-Content -LiteralPath $HeaderPath -Value $header -Encoding utf8
Set-Content -LiteralPath $RcPath -Value $rc -Encoding utf8
