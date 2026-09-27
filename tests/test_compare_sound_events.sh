#!/usr/bin/env bash
set -euo pipefail
root="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

cat > "$tmp/mame.csv" <<'CSV'
seq,arcade_time_ns,arcade_cpu_cycles,pc,sr,address,data,mem_mask
1,100,1,1000,0,8388864,32,255
2,200,2,1004,0,8388864,116,255
3,300,3,1008,0,8388864,37,255
CSV

cat > "$tmp/native.csv" <<'CSV'
sequence,arcade_time_ns,arcade_cpu_cycles,event,data,game_tick
1,0,0,command,32,0
2,0,0,drain,32,0
3,1,1,command,372,1
4,1,1,command,37,1
CSV

python3 "$root/scripts/compare_sound_events.py" "$tmp/mame.csv" "$tmp/native.csv" > "$tmp/out" && grep -F "SOUND_COMMAND_SEQUENCE_MATCH commands=3" "$tmp/out"

cat > "$tmp/native_bad.csv" <<'CSV'
sequence,arcade_time_ns,arcade_cpu_cycles,event,data,game_tick
1,0,0,command,32,0
2,1,1,command,99,1
3,2,2,command,37,2
CSV

set +e
python3 "$root/scripts/compare_sound_events.py" "$tmp/mame.csv" "$tmp/native_bad.csv" > "$tmp/bad"
status=$?
set -e
test "$status" -eq 12
grep -F "FIRST_SOUND_COMMAND_DIVERGENCE sequence=2" "$tmp/bad" >/dev/null

echo "SOUND_COMPARATOR_REGRESSIONS_OK"
