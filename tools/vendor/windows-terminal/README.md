# Windows Terminal Reference Script

`Generate-Icons.ps1` is preserved byte-for-byte from Microsoft Terminal as a reference implementation. It is not used by this repository's supported build or CI workflows because it depends on WSL, Inkscape, and ImageMagick's legacy `convert` command.

Use `../../asset-generation/ConvertTo-ICO.ps1` for production ICO generation. Attribution and licensing details are in the repository's `THIRD-PARTY-NOTICES.md`.
