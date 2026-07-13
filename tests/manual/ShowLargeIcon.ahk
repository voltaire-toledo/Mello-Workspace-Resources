#Requires AutoHotkey v2.0
#SingleInstance Force

; Configuration
dllPath := A_ScriptDir "\..\..\dist\v2603\MOResources.dll"
iconID := 101 ; IDI_APP_MAIN

if !FileExist(dllPath) {
    MsgBox "DLL not found: " dllPath
    ExitApp
}

; GUI Setup
myGui := Gui(, "Large Icon Test")
myGui.BackColor := "White"
myGui.SetFont("s12 w700")
myGui.Add("Text", "w300 Center", "256x256 Preview (ID: " iconID ")")

; Create a large picture control
; SS_ICON (0x3) style can help with icon rendering
hPic := myGui.Add("Picture", "w256 h256 Center +0x3")

try {
    ; Load the 256x256 version specifically
    ; If 256 doesn't exist, it will load the largest available and scale up
    hIcon := LoadPicture(dllPath, "w256 h256 Icon" . -iconID, &imgType)
    
    if !hIcon
        throw Error("Could not load icon handle.")

    ; Set the image via SendMessage (STM_SETIMAGE = 0x172, IMAGE_ICON = 1)
    SendMessage(0x172, 1, hIcon, hPic)
    
    ; Note: For this simple test, we won't DestroyIcon immediately 
    ; to ensure the control keeps the reference while showing.
} catch as e {
    MsgBox "Error: " e.Message
}

myGui.Show()
myGui.OnEvent("Close", (*) => ExitApp())
