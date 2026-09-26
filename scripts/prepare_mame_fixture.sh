#!/usr/bin/env bash
set -euo pipefail

FixtureRoot="${1:?fixture root is required}"
ArchivePath="${2:?ROM archive path is required}"

rm -rf "$FixtureRoot/roms" "$FixtureRoot/extracted"
mkdir -p "$FixtureRoot/roms" "$FixtureRoot/extracted"

unzip -q -o "$ArchivePath" -d "$FixtureRoot/extracted"
cp "$ArchivePath" "$FixtureRoot/roms/sf2ua.zip"

(
  cd "$FixtureRoot/extracted"
  "$OLDPWD/bin/mt2-merge.sh"
)

mv "$FixtureRoot/extracted/allroms.bin" "$FixtureRoot/allroms.bin"
mv "$FixtureRoot/extracted/sf2gfx.bin" "$FixtureRoot/sf2gfx.bin"
