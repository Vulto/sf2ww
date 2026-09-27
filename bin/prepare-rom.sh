#!/bin/sh
set -eu

ArchivePath="${1:?usage: bin/prepare-rom.sh /path/to/sf2ua.zip}"
RootDir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
TempDir=$(mktemp -d)
trap 'rm -rf "$TempDir"' EXIT

unzip -q -o "$ArchivePath" -d "$TempDir/roms"
(
  cd "$TempDir/roms"
  sh "$RootDir/bin/mt2-merge.sh"
)

mv "$TempDir/roms/allroms.bin" "$RootDir/allroms.bin"
mv "$TempDir/roms/sf2gfx.bin" "$RootDir/sf2gfx.bin"
cp "$TempDir/roms/sf2_09.bin" "$RootDir/sf2_09.bin"
cp "$TempDir/roms/sf2_18.bin" "$RootDir/sf2_18.bin"
cp "$TempDir/roms/sf2_19.bin" "$RootDir/sf2_19.bin"

echo "ROM preparation complete."
echo "allroms.bin, sf2gfx.bin, sf2_09.bin, sf2_18.bin and sf2_19.bin are ready in $RootDir"
