#!/bin/sh
set -eu

goldenDir="tests/golden"
comparator="scripts/compare_state_csv.sh"

test -f "$comparator"

for expected in "$goldenDir"/*.csv; do
    [ -f "$expected" ] || continue
    actual="$(mktemp)"
    trap 'rm -f "$actual"' EXIT
    cp "$expected" "$actual"
    bash "$comparator" "$expected" "$actual"
    awk -F, 'BEGIN { prevFrame = -1; prevTick = -1 }
        NR == 1 { if ($1 != "frame") exit 20; next }
        NF < 4 { exit 21 }
        $1 !~ /^[0-9]+$/ { exit 22 }
        $2 !~ /^-?[0-9]+$/ || $3 !~ /^-?[0-9]+$/ || $4 !~ /^-?[0-9]+$/ { exit 23 }
        prevFrame >= 0 && $1 <= prevFrame { exit 24 }
        prevTick >= 0 && $3 < prevTick { exit 25 }
        prevFrame = $1
        prevTick = $3
        END { if (NR < 2) exit 26 }
    ' "$expected"
    rm -f "$actual"
    trap - EXIT
done

printf '%s\n' "GOLDEN_TRACES_VALID"
