# Gemini Memory & Context: Mello.Ops Resource DLL

This document maintains the context, standards, and memory for the `_Custom-ResourceDLL` directory. Use this to guide all future modifications.

## 🧠 Project Memory (Recent Changes)

*   **Renaming:** The output DLL was renamed from `Mello_Ops.dll` / `MelloOpsIcons.dll` to **`MOResources.dll`** (Dec 2025).
*   **Structure:** Icons were reorganized into `ico_Mello.Ops` (App/Status) and `ico_OtherApps` (3rd party).
*   **Audio Added:**
    *   **WAV:** `wav_Mello.Ops/` (IDs 200+)
    *   **MP3:** `mp3_Voice/` (IDs 300+)
*   **Automation:** Python scripts are preferred for generating large batches of resource entries (like the 48 time announcements).

## 📏 Standards & Conventions

### 1. Naming & Paths
*   **DLL Name:** Always `MOResources.dll`.
*   **Resource File:** `ResourceMap.rc` (Source) -> `MOResources.res` (Intermediate).
*   **Path Separators:** **CRITICAL:** Always use **forward slashes** (`/`) in `.rc` files (e.g., `ico_files/icon.ico`). Backslashes (`\`) cause `RC1110` "file not found" errors due to escape sequence misinterpretation.

### 2. Resource IDs (`resource.h`)
Maintain strict sequential ranges:
*   **101-129:** Core Icons (App, Tray, Menu).
*   **130-199:** 3rd Party Icons.
*   **200-299:** WAV Sounds (Sound Effects).
*   **300-399:** MP3 Sounds (Voice Announcements).

### 3. Compilation Rules (`build.bat`)
*   **Architecture:** Must link as `/machine:x86` for AutoHotkey compatibility.
*   **Trailing Newlines:** `resource.h` **MUST** end with 1-2 empty newlines. Failing to do so causes `RC1004: unexpected end of file`.
*   **Toolchain:** Uses `rc.exe` and `link.exe` via `build.bat`. Do NOT suggest `MSBuild` or `.vcxproj` solutions.

### 4. DLL Metadata
The `VS_VERSION_INFO` block in `ResourceMap.rc` must be preserved:
*   **InternalName:** `MOResources`
*   **OriginalFilename:** `MOResources.dll`
*   **Comments:** `https://github.com/voltaire-toledo/Mello.Ops.Local`
*   **Company:** `Proventuras`

## 🤖 Agent Directives
*   **Check First:** When asked to "update", always list files in `ico_*` or `mp3_*` directories first to see what's actually there.
*   **Verify Build:** After any RC/Header modification, always run `.\build.bat` to confirm validity.
*   **Test Scripts:** If adding new resource types, update or create a corresponding `.ahk` test script (like `TestAudioMP3.ahk`).