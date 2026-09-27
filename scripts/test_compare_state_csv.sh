#!/usr/bin/env bash
set -euo pipefail

tmpDir="$(mktemp -d)"
trap 'rm -rf "$tmpDir"' EXIT

cat > "$tmpDir/expected.csv" <<'EOF'
frame,arcade_time_ns,arcade_cpu_cycles,game_mode,game_tick
1,0,0,1,9
2,16768000,167680,1,10
3,33536000,335360,2,11
EOF

cp "$tmpDir/expected.csv" "$tmpDir/actual.csv"
scripts/compare_state_csv.sh "$tmpDir/expected.csv" "$tmpDir/actual.csv" >/dev/null

awk -F, 'BEGIN { ok=0 } /^3,/ { $2=$2+1; ok=1 } { print } END { if (!ok) exit 1 }' "$tmpDir/expected.csv" > "$tmpDir/timing.csv"
if scripts/compare_state_csv.sh "$tmpDir/expected.csv" "$tmpDir/timing.csv" >/dev/null 2>&1; then
    echo "timing divergence was not detected" >&2
    exit 1
fi

awk -F, 'BEGIN { OFS=FS } /^3,/ { $3=$3+1 } { print }' "$tmpDir/expected.csv" > "$tmpDir/cycles.csv"
if scripts/compare_state_csv.sh "$tmpDir/expected.csv" "$tmpDir/cycles.csv" >/dev/null 2>&1; then
    echo "cycle divergence was not detected" >&2
    exit 1
fi

echo "COMPARATOR_TIMING_REGRESSION_OK"
