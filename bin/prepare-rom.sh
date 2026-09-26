#!/bin/sh
set -eu

ArchivePath="${1:?usage: bin/prepare-rom.sh /path/to/sf2ua.zip}"
RootDir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
TempDir=$(mktemp -d)
trap 'rm -rf "$TempDir"' EXIT

unzip -q -o "$ArchivePath" -d "$TempDir/roms"
"$RootDir/bin/mt2-merge.sh" 2>&1

mv "$TempDir/roms/allroms.bin" "$RootDir/allroms.bin"
mv "$TempDir/roms/sf2gfx.bin" "$RootDir/sf2gfx.bin"

echo "ROM preparation complete."
echo "allroms.bin and sf2gfx.bin are ready in $RootDir"
