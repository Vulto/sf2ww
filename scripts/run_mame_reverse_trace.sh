#!/usr/bin/env bash
set -euo pipefail

: "\${SF2_MAME_ROMPATH:?SF2_MAME_ROMPATH must point to an external/private MAME ROM directory}"
MAME_BIN="\${MAME_BIN:-mame}"
MAME_SET="\${SF2_MAME_SET:-sf2ua}"
MAX_FRAMES="\${SF2_REVERSE_MAX_FRAMES:-7200}"

rm -f reverse_frames.csv reverse_memory_reads.csv reverse_memory_writes.csv
rm -f reverse_ram_changes.csv reverse_memory_map.csv reverse_manifest.csv
rm -f reverse_68000.tr

SF2_REVERSE_MAX_FRAMES="$MAX_FRAMES" \
SF2_REVERSE_TRACE_INSTRUCTIONS="\${SF2_REVERSE_TRACE_INSTRUCTIONS:-1}" \
"$MAME_BIN" "$MAME_SET" \
    -rompath "$SF2_MAME_ROMPATH" \
    -autoboot_script scripts/mame_reverse_trace.lua \
    -video opengl \
    -sound none \
    -window \
    -skip_gameinfo \
    -noreadconfig \
    -cfg_directory "\${TMPDIR:-/tmp}/sf2ww-mame-cfg" \
    -nvram_directory "\${TMPDIR:-/tmp}/sf2ww-mame-nvram" \
    -input_directory "\${TMPDIR:-/tmp}/sf2ww-mame-input" \
    -nothrottle \
    -debug \
    -nodrc

python3 scripts/validate_reverse_trace.py
