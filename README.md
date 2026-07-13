# Mello Workspace Resources

This repository is the standalone, version-aware media build system for the Mello Workspace resource DLL. The initial explicit profile is `v2603`; its [manifest](resource-dll/profiles/v2603/manifest.json) is the source of truth for resource IDs and assets.

## Layout

| Path | Purpose |
| --- | --- |
| `resource-dll/` | Runtime assets, profiles, and the shared DLL build entry point |
| `sources/` | Editable and reference artwork, including preserved v2602 material |
| `tools/` | Validation, icon generation, audio generation, and vendored references |
| `tests/manual/` | AutoHotkey smoke tests for the built DLL |
| `archive/legacy-builds/` | Pre-migration binaries and build evidence; never build inputs |

## Quick start

```powershell
./tools/validation/Test-Repository.ps1
./resource-dll/Build-ResourceDll.ps1 -Profile v2603
```

The DLL build requires `rc.exe` and `link.exe` from a Visual Studio Developer PowerShell. Output is written to `dist/v2603/MOResources.dll`; intermediates go to `build/v2603/`.

Icon generation requires ImageMagick 7. Voice generation requires Python, the pinned dependency in `tools/audio-generation/requirements.txt`, and network access to Microsoft's variable Edge TTS service. See the README in each tool directory before regenerating media.

## Releases

Profiles are mutable during development; annotated Git tags are immutable release markers:

```powershell
git tag -a resources/v2603.0 -m "Mello Workspace resources v2603.0"
git push origin resources/v2603.0
```

Tags matching `resources/v*` trigger the Windows release workflow. CI uploads generated artifacts but never commits them.

## Licensing

Repository-authored code is MIT licensed. Media and vendored/reference material may have separate ownership or terms; see [THIRD-PARTY-NOTICES.md](THIRD-PARTY-NOTICES.md).
