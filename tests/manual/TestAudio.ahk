#Requires AutoHotkey v2.0
#SingleInstance Force

; ==============================================================================
; Config & Setup
; ==============================================================================
dllPath := A_ScriptDir "\..\..\dist\v2603\MOResources.dll"

if !FileExist(dllPath) {
    MsgBox("Error: Build v2603 first. MOResources.dll not found at:`n" dllPath, "Error", 16)
    ExitApp
}

; Load the Resource DLL
hModule := DllCall("LoadLibrary", "Str", dllPath, "Ptr")
if !hModule {
    MsgBox("Error: Failed to load DLL.", "Error", 16)
    ExitApp
}

; Define Resource IDs (Must match resource.h)
AudioResources := Map()
AudioResources["Reconnect_MO"] := 200
AudioResources["StartReload_MO"] := 201

; ==============================================================================
; GUI Creation
; ==============================================================================
myGui := Gui(, "Mello.Ops Audio Tester")
myGui.SetFont("s10", "Segoe UI")
myGui.OnEvent("Close", (*) => ExitScript(hModule))

myGui.Add("Text", "w300 center", "Click a button to play the sound from DLL")

for name, id in AudioResources {
    btn := myGui.Add("Button", "w300 h40", name " (ID: " id ")")
    btn.OnEvent("Click", PlayResourceSound.Bind(id))
}

myGui.Show()

; ==============================================================================
; Functions
; ==============================================================================
PlayResourceSound(resourceID, *) {
    ; SND_RESOURCE = 0x00040004 (SND_RESOURCE | SND_NODEFAULT)
    ; SND_ASYNC    = 0x0001
    flags := 0x00040005 ; SND_RESOURCE | SND_ASYNC | SND_NODEFAULT
    
    ; PlaySound(LPCTSTR pszSound, HMODULE hmod, DWORD fdwSound)
    ; When using SND_RESOURCE, pszSound is the Resource ID (Int)
    success := DllCall("winmm\PlaySound", "Ptr", resourceID, "Ptr", hModule, "UInt", flags)
    
    if !success
        ToolTip("Failed to play ID: " resourceID)
    else
        ToolTip("Playing ID: " resourceID)
    
    SetTimer () => ToolTip(), -1000
}

ExitScript(hMod) {
    DllCall("FreeLibrary", "Ptr", hMod)
    ExitApp
}
