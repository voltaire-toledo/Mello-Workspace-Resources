
param (
    [Parameter(Mandatory=$true)]
    [string]$SourcePath,
    [Parameter(Mandatory=$false)]
    [string]$OutputDir = "$PSScriptRoot\\icons"
)

Add-Type -AssemblyName System.Drawing

if (!(Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir | Out-Null
}

# Load the file as an icon resource
$iconExtractorType = @"
using System;
using System.Drawing;
using System.Runtime.InteropServices;
public class IconExtractor {
    [DllImport("user32.dll", SetLastError=true)]
    public static extern int ExtractIconEx(string lpszFile, int nIconIndex, IntPtr[] phiconLarge, IntPtr[] phiconSmall, int nIcons);

    public static Icon ExtractIcon(string file, int index) {
        IntPtr[] largeIcons = new IntPtr[1];
        IntPtr[] smallIcons = new IntPtr[1];
        ExtractIconEx(file, index, largeIcons, smallIcons, 1);
        if (largeIcons[0] != IntPtr.Zero)
            return Icon.FromHandle(largeIcons[0]);
        if (smallIcons[0] != IntPtr.Zero)
            return Icon.FromHandle(smallIcons[0]);
        return null;
    }
    public static int GetIconCount(string file) {
        return ExtractIconEx(file, -1, null, null, 0);
    }
}
"@

Add-Type -TypeDefinition $iconExtractorType -Language CSharp

$iconCount = [IconExtractor]::GetIconCount($SourcePath)
Write-Host "Found $iconCount icons in $SourcePath"

for ($i = 0; $i -lt $iconCount; $i++) {
    $icon = [IconExtractor]::ExtractIcon($SourcePath, $i)
    if ($icon) {
        $icoFile = Join-Path $OutputDir ("icon_$i.ico")
        $stream = New-Object System.IO.FileStream($icoFile, [System.IO.FileMode]::Create)
        $icon.Save($stream)
        $stream.Close()
        Write-Host "Extracted icon $i to $icoFile"
    }
}