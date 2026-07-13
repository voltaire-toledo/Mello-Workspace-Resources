<#
.SYNOPSIS
    Enumerates programs in shell:AppsFolder and extracts their icons to .\icons directory.
.DESCRIPTION
    Uses Shell.Application COM to list all apps in shell:AppsFolder, extracts icons from shortcuts, and saves them as .ico files in the .\icons folder.
.NOTES
    Requires Windows PowerShell and .NET Framework (System.Drawing).
#>

# Ensure icons directory exists
$iconsDir = Join-Path $PSScriptRoot 'icons'
if (!(Test-Path $iconsDir)) {
    New-Item -ItemType Directory -Path $iconsDir | Out-Null
}

Add-Type -AssemblyName System.Drawing

$shell = New-Object -ComObject Shell.Application
$appsFolder = $shell.Namespace('shell:AppsFolder')

function Get-ShortcutIconPath($lnkPath) {
    $wsh = New-Object -ComObject WScript.Shell
    $shortcut = $wsh.CreateShortcut($lnkPath)
    $iconLocation = $shortcut.IconLocation
    if ($iconLocation) {
        $parts = $iconLocation.Split(',')
        $iconPath = $parts[0]
        $iconIndex = if ($parts.Count -gt 1) { [int]$parts[1] } else { 0 }
        return @{Path=$iconPath; Index=$iconIndex}
    }
    return $null
}

foreach ($item in $appsFolder.Items()) {
    $name = $item.Name
    $iconSourcePath = $null
    $iconIndex = 0

    if ($item.IsLink) {
        $lnkPath = $item.Path
        $iconInfo = Get-ShortcutIconPath($lnkPath)
        if ($iconInfo -and (Test-Path $iconInfo.Path)) {
            $iconSourcePath = $iconInfo.Path
            $iconIndex = $iconInfo.Index
        } elseif (Test-Path $lnkPath) {
            # Try to extract icon from the shortcut file itself
            $iconSourcePath = $lnkPath
        }
    } else {
        $iconSourcePath = $item.Path
    }

    if ($iconSourcePath -and (Test-Path $iconSourcePath)) {
        try {
            # Only extract the associated icon (index 0) for simplicity
            $icon = [System.Drawing.Icon]::ExtractAssociatedIcon($iconSourcePath)
            if ($icon) {
                $safeName = $name -replace '[\\/:*?"<>|]', '_'
                $icoFile = Join-Path $iconsDir ("$safeName.ico")
                $stream = New-Object System.IO.FileStream($icoFile, [System.IO.FileMode]::Create)
                $icon.Save($stream)
                $stream.Close()
                Write-Host "Extracted icon for $name to $icoFile"
            }
        } catch {
            Write-Warning "Could not extract icon from ${iconSourcePath}: $_"
        }
    } else {
        Write-Warning "No valid icon source for $iconSourcePath"
    }
}