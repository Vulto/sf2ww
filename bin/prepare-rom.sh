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

pick_sound() {
    for name in "$@"; do
        if [ -f "$TempDir/roms/$name" ]; then
            printf '%s\\n' "$TempDir/roms/$name"
            return 0
        fi
    done
    echo "error: none of the required sound ROM files exists: $*" >&2
    exit 1
}

cp "$(pick_sound sf2_9.12a sf2_09.bin sf2_09.rom)" "$RootDir/sf2_09.bin"
cp "$(pick_sound sf2_18.11c sf2_18.bin sf2_18.rom)" "$RootDir/sf2_18.bin"
cp "$(pick_sound sf2_19.12c sf2_19.bin sf2_19.rom)" "$RootDir/sf2_19.bin"

echo "ROM preparation complete."
echo "allroms.bin, sf2gfx.bin, sf2_09.bin, sf2_18.bin and sf2_19.bin are ready in $RootDir"
