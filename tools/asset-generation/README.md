# Icon Generation

ImageMagick 7 is the production dependency. Convert one SVG or PNG to a multi-frame ICO:

```powershell
./tools/asset-generation/ConvertTo-ICO.ps1 sources/icons/working/TrayIco-suspend-m.svg -OutputPath dist/generated-icons/TrayIco-suspend-m.ico
```

The default frames are 256, 64, 48, 32, 24, and 16 pixels. Pass `-Sizes 256,48,32,16` to customize them and `-Force` to replace an existing output. The script writes a temporary file, validates the frame dimensions, then atomically promotes it.

`icon-manifest.json` drives CI generation of representative profile artwork. `Generate-Icons.ps1` processes that manifest. The Windows Terminal script under `tools/vendor/` is reference-only.
