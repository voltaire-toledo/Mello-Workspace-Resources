# Resource DLL

`profiles/v2603/manifest.json` authoritatively maps numeric IDs and symbols to runtime assets. `resource.h` and `ResourceMap.rc` are generated snapshots checked by repository validation; do not hand-edit them.

From a Visual Studio Developer PowerShell:

```powershell
./resource-dll/Build-ResourceDll.ps1 -Profile v2603
```

The shared script validates the profile, regenerates build-local RC files, invokes `rc.exe` and `link.exe` for x86, and writes `dist/v2603/MOResources.dll`. Use `-Force` to replace an existing DLL. Add new versions as profiles rather than copying the build script or creating per-version Makefiles.
