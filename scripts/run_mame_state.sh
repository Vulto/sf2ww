#!/usr/bin/env bash
set -euo pipefail

: "${SF2_MAME_ROMPATH:?SF2_MAME_ROMPATH must point to an external/private MAME ROM directory}"
MAME_BIN="${MAME_BIN:-mame}"
MAME_SET="${SF2_MAME_SET:-sf2ua}"
STATE_SCRIPT="${SF2_MAME_STATE_SCRIPT:-scripts/mame_state_dump.lua}"

exec "$MAME_BIN" "$MAME_SET"     -rompath "$SF2_MAME_ROMPATH"     -autoboot_script "$STATE_SCRIPT"     -video opengl     -sound none     -window     -skip_gameinfo     -noreadconfig     -cfg_directory "${TMPDIR:-/tmp}/sf2ww-mame-cfg"     -nvram_directory "${TMPDIR:-/tmp}/sf2ww-mame-nvram"     -input_directory "${TMPDIR:-/tmp}/sf2ww-mame-input"     -nothrottle
