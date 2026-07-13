#Requires AutoHotkey v2.0
#SingleInstance Force

; Configuration
dllPath := A_ScriptDir "\..\..\dist\v2603\MOResources.dll"
cycleInterval := 3000 ; 3 seconds

; Define the icons and their Resource IDs (must match resource.h)
icons := [{ id: 101, name: "AppMain" }, { id: 102, name: "Tray_Grey" }, { id: 103, name: "Tray_Grey_RDS" }, { id: 104, name: "Tray_Grey_RDS_MKBD" }, { id: 105, name: "Tray_MKBD" }, { id: 106, name: "Tray_Suspend" }, { id: 107, name: "Tray_Suspend_MKBD" }
]

currentIdx := 1

; Validation
if !FileExist(dllPath) {
  MsgBox "Error: DLL not found at:`n" dllPath, "Error", 16
  ExitApp
}

; GUI Setup
myGui := Gui(, "Icon Viewer")
myGui.OnEvent("Close", (*) => ExitApp())
myGui.SetFont("s10", "Segoe UI")
myGui.BackColor := "White"

hLabelID := myGui.Add("Text", "w250 Center vLabelID", "Initializing...")
hLabelName := myGui.Add("Text", "w250 Center vLabelName", "Please wait...")

; Add Picture control (w128 h128). We initialize it empty to avoid creation errors.

hPic := myGui.Add("Picture", "w128 h128 Center")


; Add a manual step button

myGui.Add("Button", "w250", "Next Icon").OnEvent("Click", (*) => UpdateIcon())


myGui.Show()

; Start the timer
UpdateIcon() ; Run immediately
SetTimer UpdateIcon, cycleInterval

; --- Functions ---
UpdateIcon() {
    global currentIdx, lastIconHandle, icons, dllPath, hPic, hLabelID, hLabelName
    
    thisIcon := icons[currentIdx]
    
    ; 1. Update System Tray Icon
    try {
        ; Use negative ID to specify Resource ID instead of Index
        TraySetIcon dllPath, -thisIcon.id
        A_IconTip := "ID: " thisIcon.id " - " thisIcon.name
    } catch as e {
        ; Ignore errors if tray is busy
    }
    
    ; 2. Update GUI Picture using LoadPicture
    try {
        ; Load the icon handle. 
        ; Request w128 h128 explicitly.
        hIcon := LoadPicture(dllPath, "w128 h128 Icon" . -thisIcon.id, &imgType)
        
        if !hIcon
            throw Error("LoadPicture returned 0 handle")

        ; Use SendMessage to set the image directly (STM_SETIMAGE = 0x172, IMAGE_ICON = 1)
        SendMessage(0x172, 1, hIcon, hPic)
        
        ; NOW it is safe to destroy the PREVIOUS handle, because the control is using the new one.
        if (lastIconHandle != 0)
            DllCall("DestroyIcon", "Ptr", lastIconHandle)
            
        ; Save the current handle for next time
        lastIconHandle := hIcon
        
        ; Update labels
        hLabelID.Text := "Resource ID: " thisIcon.id
        hLabelName.Text := thisIcon.name
        
    } catch as e {
        hLabelName.Text := "Error loading icon: " . e.Message
    }
    
    ; Increment index
    currentIdx++
    if (currentIdx > icons.Length)
        currentIdx := 1
}
