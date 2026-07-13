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

; Define Base ID for Time Files (From resource.h: IDR_TIME_00_00 = 300)
START_ID := 300
; We have 48 files (00:00 to 23:30)

; ==============================================================================
; GUI Creation
; ==============================================================================
myGui := Gui(, "MP3 Resource Player")
myGui.SetFont("s9", "Segoe UI")
myGui.OnEvent("Close", (*) => ExitScript(hModule))

myGui.Add("Text", "w600 center", "Click a button to play MP3 from DLL (Extracted to Temp)")

; Create a Grid of Buttons
y := 40
x := 10
count := 0

Loop 48 {
    ; Calculate Time String
    totalMinutes := (A_Index - 1) * 30
    hh := Format("{:02}", Floor(totalMinutes / 60))
    mm := Format("{:02}", Mod(totalMinutes, 60))
    timeStr := hh ":" mm
    
    currentID := START_ID + (A_Index - 1)
    
    if (Mod(count, 4) == 0 && count > 0) {
        y += 40
        x := 10
    }
    
    myGui.Add("Button", "x" x " y" y " w140 h30", timeStr " (ID: " currentID ")").OnEvent("Click", PlayMp3Resource.Bind(currentID, timeStr))
    
    x += 150
    count++
}

myGui.Show("w620 h" y + 50)

; ==============================================================================
; Functions
; ==============================================================================
PlayMp3Resource(resourceID, name, *) {
    ; 1. Find Resource
    ; RT_RCDATA = 10
    hResInfo := DllCall("FindResource", "Ptr", hModule, "Ptr", resourceID, "Ptr", 10, "Ptr")
    if !hResInfo {
        ToolTip("Error: Resource not found " resourceID)
        SetTimer () => ToolTip(), -1000
        return
    }
    
    ; 2. Load Resource
    hResData := DllCall("LoadResource", "Ptr", hModule, "Ptr", hResInfo, "Ptr")
    pData := DllCall("LockResource", "Ptr", hResData, "Ptr")
    size := DllCall("SizeofResource", "Ptr", hModule, "Ptr", hResInfo, "UInt")
    
    if !pData || !size {
        ToolTip("Error: Could not lock resource")
        return
    }
    
    ; 3. Write to Temp File
    tempPath := A_Temp "\mello_ops_voice.mp3"
    
    try {
        if FileExist(tempPath)
            FileDelete(tempPath)
            
        f := FileOpen(tempPath, "w")
        f.RawWrite(pData, size)
        f.Close()
        
        ; 4. Play
        ToolTip("Playing: " name)
        SoundPlay(tempPath)
        
    } catch as e {
        ToolTip("Error writing/playing: " e.Message)
    }
    
    SetTimer () => ToolTip(), -2000
}

ExitScript(hMod) {
    DllCall("FreeLibrary", "Ptr", hMod)
    ExitApp
}
