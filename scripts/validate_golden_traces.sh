#!/bin/sh
set -eu

goldenDir="tests/golden"
comparator="scripts/compare_state_csv.sh"

test -x "$comparator"

for expected in "$goldenDir"/*.csv; do
    [ -f "$expected" ] || continue
    actual="$(mktemp)"
    trap 'rm -f "$actual"' EXIT
    cp "$expected" "$actual"
    "$comparator" "$expected" "$actual"
    rm -f "$actual"
    trap - EXIT
done

printf '%s\n' "GOLDEN_TRACES_VALID"
