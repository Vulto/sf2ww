#!/usr/bin/env bash
set -euo pipefail
root="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

cat > "$tmp/mame.csv" <<'CSV'
sequence,arcade_time_ns,arcade_cpu_cycles,cpu,address,data,event,pc
1,100,1,maincpu,8388992,32,command,1000
2,200,2,maincpu,8388992,116,command,1004
3,300,3,maincpu,8388992,37,command,1008
4,301,3,audiocpu,61440,32,ym_address,2000
5,302,3,audiocpu,61441,64,ym_data,2001
CSV

cat > "$tmp/native.csv" <<'CSV'
sequence,arcade_time_ns,arcade_cpu_cycles,event,data,game_tick
1,0,0,command,32,0
2,0,0,command,116,0
3,0,0,command,37,0
4,1,1,ym_address,32,1
5,2,1,ym_data,64,1
CSV

python3 "$root/scripts/compare_sound_events.py" "$tmp/mame.csv" "$tmp/native.csv" > "$tmp/out"
grep -F "SOUND_COMMAND_SEQUENCE_MATCH commands=3" "$tmp/out"
grep -F "SOUND_CHIP_SEQUENCE_MATCH events=2" "$tmp/out"

cat > "$tmp/native_bad.csv" <<'CSV'
sequence,arcade_time_ns,arcade_cpu_cycles,event,data,game_tick
1,0,0,command,32,0
2,0,0,command,99,0
3,0,0,command,37,0
CSV

set +e
python3 "$root/scripts/compare_sound_events.py" "$tmp/mame.csv" "$tmp/native_bad.csv" > "$tmp/bad"
status=$?
set -e
test "$status" -eq 12
grep -F "FIRST_SOUND_COMMAND_DIVERGENCE sequence=2" "$tmp/bad" >/dev/null

echo "SOUND_COMPARATOR_REGRESSIONS_OK"
