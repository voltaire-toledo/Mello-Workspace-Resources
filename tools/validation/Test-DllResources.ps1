[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string] $DllPath,
    [Parameter(Mandatory)] [string] $ManifestPath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if (-not ('ResourceProbe' -as [type])) {
    Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
public static class ResourceProbe {
    [DllImport("kernel32.dll", SetLastError=true, CharSet=CharSet.Unicode)]
    public static extern IntPtr LoadLibraryEx(string file, IntPtr reserved, uint flags);
    [DllImport("kernel32.dll", SetLastError=true)]
    public static extern bool FreeLibrary(IntPtr module);
    [DllImport("kernel32.dll", SetLastError=true)]
    public static extern IntPtr FindResource(IntPtr module, IntPtr name, IntPtr type);
    [DllImport("kernel32.dll", EntryPoint="FindResourceW", SetLastError=true, CharSet=CharSet.Unicode)]
    public static extern IntPtr FindResourceByTypeName(IntPtr module, IntPtr name, string type);
}
'@
}

$dll = (Resolve-Path -LiteralPath $DllPath).Path
$manifest = Get-Content -Raw -LiteralPath $ManifestPath | ConvertFrom-Json
$module = [ResourceProbe]::LoadLibraryEx($dll, [IntPtr]::Zero, 0x00000002)
if ($module -eq [IntPtr]::Zero) { throw "Unable to load DLL as data file: $dll" }

$missing = [Collections.Generic.List[string]]::new()
try {
    foreach ($resource in $manifest.resources) {
        $typePointer = switch ($resource.type) {
            'ICON' { [IntPtr] 14 }
            'RCDATA' { [IntPtr] 10 }
            'WAVE' { [IntPtr]::Zero }
        }
        if ($resource.type -eq 'WAVE') {
            $found = [ResourceProbe]::FindResourceByTypeName($module, [IntPtr] $resource.id, 'WAVE')
        }
        else {
            $found = [ResourceProbe]::FindResource($module, [IntPtr] $resource.id, $typePointer)
        }
        if ($found -eq [IntPtr]::Zero) { $missing.Add("$($resource.id):$($resource.symbol)") }
    }
}
finally {
    [void] [ResourceProbe]::FreeLibrary($module)
}

if ($missing.Count) { throw "DLL is missing resources: $($missing -join ', ')" }
Write-Host "Verified $($manifest.resources.Count) manifest resource identifiers in $dll."
