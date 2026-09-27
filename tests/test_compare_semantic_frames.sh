#!/usr/bin/env bash
set -euo pipefail

root="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

cat > "$tmp/mame.csv" <<'CSV'
arcade_time_ns,arcade_cpu_cycles,p1_x,p1_y
0,0,10,20
16768000,167680,11,20
33536000,335360,12,20
CSV

cat > "$tmp/port_match.csv" <<'CSV'
frame,arcade_time_ns,arcade_cpu_cycles,p1_x,p1_y
1,0,0,10,1310720
2,16768000,167680,11,1310720
3,33536000,335360,12,1310720
CSV

cat > "$tmp/port_extra.csv" <<'CSV'
frame,arcade_time_ns,arcade_cpu_cycles,p1_x,p1_y
1,0,0,10,1310720
2,16768000,167680,11,1310720
3,25152000,251520,99,1310720
4,33536000,335360,12,1310720
CSV

cat > "$tmp/port_timing.csv" <<'CSV'
frame,arcade_time_ns,arcade_cpu_cycles,p1_x,p1_y
1,0,0,10,1310720
2,16768000,167680,11,1310720
3,31859200,318592,12,1310720
CSV

cat > "$tmp/port_semantic.csv" <<'CSV'
frame,arcade_time_ns,arcade_cpu_cycles,p1_x,p1_y
1,0,0,10,1310720
2,16768000,167680,11,1310720
3,33536000,335360,13,1310720
CSV

cat > "$tmp/port_missing.csv" <<'CSV'
frame,arcade_time_ns,arcade_cpu_cycles,p1_x,p1_y
1,0,0,10,1310720
2,16768000,167680,11,1310720
CSV

cat > "$tmp/port_bad_timing.csv" <<'CSV'
frame,arcade_time_ns,arcade_cpu_cycles,p1_x,p1_y
1,0,0,10,1310720
2,not-a-number,167680,11,1310720
3,33536000,335360,12,1310720
CSV

runExpectedFailure() {
    local name="$1"
    local input="$2"
    local expected="$3"
    local output

    set +e
    output="$(python3 "$root/scripts/compare_semantic_frames.py" "$tmp/mame.csv" "$input" 2>&1)"
    status=$?
    set -e

    test "$status" -ne 0
    printf '%s\n' "$output" | grep -F "$expected" >/dev/null
    printf '%s\n' "$output"
    echo "PASS $name"
}

python3 "$root/scripts/compare_semantic_frames.py" "$tmp/mame.csv" "$tmp/port_match.csv" | grep -F "SEMANTIC_AND_TIMING_MATCH transitions=3" >/dev/null

runExpectedFailure "extra-transition-detected" "$tmp/port_extra.csv" "TRANSITION_COUNT_MISMATCH mame=3 port=4"
runExpectedFailure "timing-divergence-detected" "$tmp/port_timing.csv" "FIRST_TIMING_DIVERGENCE transition=3"
runExpectedFailure "semantic-divergence-detected" "$tmp/port_semantic.csv" "FIRST_SEMANTIC_DIVERGENCE transition=3"
runExpectedFailure "missing-transition-detected" "$tmp/port_missing.csv" "TRANSITION_COUNT_MISMATCH mame=3 port=2"
runExpectedFailure "malformed-timing-rejected" "$tmp/port_bad_timing.csv" "INVALID_ARCADE_TIME"

echo "SEMANTIC_COMPARATOR_REGRESSIONS_OK"
