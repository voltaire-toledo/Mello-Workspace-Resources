# Gemini Context: Mello.Ops Resource DLL

**Current State:** Active Development (Jan 2026)
**Artifact:** `MOResources.dll` (x86 Resource-only DLL)

This directory contains the source code and assets for building the resource DLL used by the Mello.Ops application. It bundles icons and audio files into a single binary for easier distribution and consumption by AutoHotkey (AHK) scripts.

## 📂 Directory Structure

| Path | Description |
| :--- | :--- |
| **`ico_Mello.Ops/`** | Core application icons (Tray, Menu, Status). |
| **`ico_OtherApps/`** | Third-party application icons used in menus. |
| **`mp3_Voice/`** | Voice announcements (e.g., time) in MP3 format. |
| **`wav_Mello.Ops/`** | Sound effects in WAV format. |
| `ResourceMap.rc` | **Master Source.** Maps filenames to Resource IDs. |
| `resource.h` | **Header.** Defines integer constants for Resource IDs. |
| `build.bat` | **Build Script.** Compiles RC -> RES -> DLL. |
| `MOResources.dll` | **Output.** The final compiled DLL. |

## 📏 Conventions

### Resource IDs (`resource.h`)
IDs are integers used to reference resources. Keep them unique and sequential within blocks.

*   **101 - 129**: **Mello.Ops Core** (AppMain, Tray states, Menu icons).
*   **130 - 199**: **Third-Party Apps** (Generic, VSCode, Teams, etc.).
*   **200+**: **Audio/Voice** (Planned range for MP3/WAV assets).

### File Naming
*   **Icons:** CamelCase or Snake_Case.
    *   `AppMain.ico`
    *   `Tray_Suspend.ico`
    *   `Menu_ReloadRED.ico`
*   **Audio:** Descriptive prefixes.
    *   `Time_12_00.mp3`

### Metadata (`VS_VERSION_INFO`)
The DLL includes extended properties. **Do not remove these.**
*   **Comments/URL:** Point to the GitHub repo.
*   **Version:** `YYYY.MM.DD` format (e.g., `2026.01.01`).
*   **Company:** Proventuras.

## 🛠️ Workflows

### 1. Adding a New Icon
1.  **Place File:** Put the `.ico` file in `ico_Mello.Ops` or `ico_OtherApps`.
2.  **Define ID:** Open `resource.h` and add a `#define IDI_NAME ###` constant.
    *   *Tip:* Keep it sorted by ID number.
3.  **Map Resource:** Open `ResourceMap.rc` and add `IDI_NAME ICON "path/to/file.ico"`.
    *   *Critical:* Use **forward slashes** (`/`) in paths to avoid RC compiler errors.
4.  **Build:** Run `.\build.bat`.

### 2. Building the DLL
Run the build script from this directory:
```powershell
.\build.bat
```
*   **Prerequisite:** Must be run from a **Visual Studio Developer Command Prompt** (requires `rc.exe` and `link.exe` in PATH).
*   **Output:** `MOResources.dll`

## ⚠️ Troubleshooting / Gemini Tips

*   **RC1004: Unexpected end of file**
    *   **Fix:** Ensure `resource.h` has **at least one (preferably two) blank lines** at the very end. The Resource Compiler is picky about this.
*   **RC1110 / File Not Found**
    *   **Fix:** Check paths in `.rc`. Ensure they use **forward slashes** (`/`) and are relative to the `.rc` file.
*   **AHK "Error loading icon"**
    *   **Fix:** Ensure the DLL is linked as `/machine:x86` (default in `build.bat`). AHK generally handles x86 DLLs better for resources even on x64.

## 🤖 Context for Gemini
*   When asked to "update icons", always scan the `ico_*` folders first.
*   If modifying `resource.h`, **ALWAYS** append a newline to the end of the file.
*   The project uses a custom `build.bat` script, not MSBuild.