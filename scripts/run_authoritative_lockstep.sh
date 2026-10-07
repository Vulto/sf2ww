#!/usr/bin/env bash
set -euo pipefail

ROM_ROOT="${1:?usage: scripts/run_authoritative_lockstep.sh <rom-root> <port-executable>}"
PORT_EXECUTABLE="${2:?usage: scripts/run_authoritative_lockstep.sh <rom-root> <port-executable>}"
SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
ROOT_DIR="$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)"
MAME_BIN="${MAME_BIN:-mame}"
MAME_SET="${SF2_MAME_SET:-sf2ua}"

test -d "$ROM_ROOT/roms/$MAME_SET"
test -s "$ROM_ROOT/allroms.bin"
test -s "$ROM_ROOT/sf2gfx.bin"
test -s "$ROM_ROOT/sf2_09.bin"
test -s "$ROM_ROOT/sf2_18.bin"
test -s "$ROM_ROOT/sf2_19.bin"
test -x "$PORT_EXECUTABLE"

export SF2_MAME_ROMPATH="$ROOT_DIR/$ROM_ROOT"
export MAME_BIN
export SF2_MAME_SET="$MAME_SET"

rm -f mame_state.csv mame_exec_numeric.csv mame_exec_numeric_machineframe.csv   mame_exec_input.csv mame_seed_probe.csv mame_demo_probe.csv mame_sound_events.csv   native_audio_events.csv

SF2_MAME_STATE_SCRIPT="$SCRIPT_DIR/mame_state_dump.lua" xvfb-run -a bash "$SCRIPT_DIR/run_mame_state.sh"
test -s mame_state.csv

SF2_NUMERIC_MAX_FRAMES=12000 SF2_MAME_STATE_SCRIPT="$SCRIPT_DIR/mame_exec_numeric.lua"   xvfb-run -a bash "$SCRIPT_DIR/run_mame_state.sh"
test -s mame_exec_numeric.csv

SF2_MAME_STATE_SCRIPT="$SCRIPT_DIR/mame_exec_numeric_machineframe.lua"   xvfb-run -a bash "$SCRIPT_DIR/run_mame_state.sh"
test -s mame_exec_numeric_machineframe.csv

SF2_MAME_STATE_SCRIPT="$SCRIPT_DIR/mame_exec_input.lua"   xvfb-run -a bash "$SCRIPT_DIR/run_mame_state.sh"
test -s mame_exec_input.csv

SF2_MAME_STATE_SCRIPT="$SCRIPT_DIR/mame_seed_probe.lua"   xvfb-run -a bash "$SCRIPT_DIR/run_mame_state.sh"
test -s mame_seed_probe.csv

SF2_MAME_STATE_SCRIPT="$SCRIPT_DIR/mame_demo_probe.lua"   xvfb-run -a bash "$SCRIPT_DIR/run_mame_state.sh"
test -s mame_demo_probe.csv

SF2_SOUND_MAX_FRAMES=12000 SF2_MAME_STATE_SCRIPT="$SCRIPT_DIR/mame_sound_probe.lua"   xvfb-run -a bash "$SCRIPT_DIR/run_mame_state.sh"
test -s mame_sound_events.csv

cp "$ROM_ROOT/allroms.bin" allroms.bin
cp "$ROM_ROOT/sf2gfx.bin" sf2gfx.bin
cp "$ROM_ROOT/sf2_09.bin" sf2_09.bin
cp "$ROM_ROOT/sf2_18.bin" sf2_18.bin
cp "$ROM_ROOT/sf2_19.bin" sf2_19.bin

set +e
SF2_MAX_FRAMES=900 SF2_STATE_LOG=port_state.csv SF2_TIMING_LOG=port_timing.csv   SF2_TASK_TRACE=native_task_trace.csv timeout 30s xvfb-run -a "$PORT_EXECUTABLE" </dev/null
status=$?
set -e
test "$status" -eq 0
test -s port_state.csv
test -s port_timing.csv
test -s native_task_trace.csv

SF2_INPUT_TEST=1 SF2_MAX_FRAMES=900 SF2_STATE_LOG=port_state_input.csv   SF2_TIMING_LOG=port_timing_input.csv timeout 30s xvfb-run -a "$PORT_EXECUTABLE" </dev/null
test -s port_state_input.csv
test -s port_timing_input.csv

SF2_AUDIO_EVENT_LOG=1 SF2_MAX_FRAMES=12000 timeout 230s xvfb-run -a "$PORT_EXECUTABLE"   </dev/null >/tmp/sf2-native-audio.log 2>&1
test -s native_audio_events.csv

python3 "$SCRIPT_DIR/compare_sound_events.py" mame_sound_events.csv native_audio_events.csv
bash "$SCRIPT_DIR/compare_timing_csv.sh" mame_state.csv port_state.csv
bash "$SCRIPT_DIR/compare_mame_port_numeric.sh" mame_exec_numeric.csv port_state.csv
bash "$SCRIPT_DIR/compare_mame_port_numeric.sh" mame_exec_input.csv port_state_input.csv
bash "$SCRIPT_DIR/validate_host_timing.sh" port_timing.csv
bash "$SCRIPT_DIR/validate_host_timing.sh" port_timing_input.csv

rm -rf mame_visual native_visual
mkdir -p mame_visual native_visual
SF2_MAME_STATE_SCRIPT="$SCRIPT_DIR/mame_visual_dump.lua" SF2_VISUAL_DIR="$ROOT_DIR/mame_visual"   SF2_VISUAL_EVERY=60 SF2_VISUAL_MAX_FRAMES=12000 xvfb-run -a bash "$SCRIPT_DIR/run_mame_state.sh"
test -n "$(find mame_visual -name 'frame_*.png' -print -quit)"

set +e
SF2_MAX_FRAMES=12000 SF2_STATE_LOG=port_state_attract.csv   SF2_TIMING_LOG=port_timing_attract.csv SF2_VISUAL_DIR="$ROOT_DIR/native_visual"   SF2_VISUAL_EVERY=60 SF2_VISUAL_MAX_FRAMES=12000 timeout 230s   xvfb-run -a "$PORT_EXECUTABLE" </dev/null >/tmp/sf2-native-visual.log 2>&1
native_status=$?
set -e
test "$native_status" -eq 0
test -n "$(find native_visual -name 'frame_*.ppm' -print -quit)"

python3 "$SCRIPT_DIR/validate_visual_anchors.py" --mame-dir mame_visual --native-dir native_visual
bash "$SCRIPT_DIR/compare_mame_port_numeric.sh" mame_exec_numeric.csv port_state_attract.csv
python3 "$SCRIPT_DIR/compare_visual_frames.py"   --mame-dir mame_visual --native-dir native_visual --out visual_comparison.csv

echo "AUTHORITATIVE_MAME_NATIVE_LOCKSTEP_PASS"
