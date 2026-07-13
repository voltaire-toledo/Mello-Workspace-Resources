# Third-Party Notices

## Microsoft Terminal asset-generation reference

`tools/vendor/windows-terminal/Generate-Icons.ps1` is preserved unchanged as a reference implementation from the [Microsoft Terminal repository](https://github.com/microsoft/terminal). Microsoft Terminal is copyright Microsoft Corporation and contributors and is distributed under the MIT License. The repository's MIT license and notices apply to that vendored file.

The script is not part of the supported build path: it depends on WSL, Inkscape, and ImageMagick. Production ICO generation uses `tools/asset-generation/ConvertTo-ICO.ps1` and native ImageMagick instead.

## Media assets

Third-party product names, logos, and icons under `resource-dll/assets/icons/third-party/` and `sources/icons/working/others-icons/` remain the property of their respective owners. Inclusion here does not imply endorsement or transfer of trademark rights. Review the source and distribution terms before redistributing those assets.

## Edge TTS

The optional audio generator uses the separately installed `edge-tts` Python package, licensed under LGPL-3.0. Generated speech depends on Microsoft's online Edge TTS service and is subject to the service's availability and applicable terms.
