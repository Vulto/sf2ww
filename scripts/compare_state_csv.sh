#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -lt 2 ] || [ "$#" -gt 3 ]; then
    echo "usage: $0 <expected.csv> <actual.csv> [skip_rows]" >&2
    exit 2
fi

expected="$1"
actual="$2"
skip_rows="${3:-0}"

# Compare the numeric execution trajectory, not frame numbers.
# Consecutive identical state vectors are collapsed into one transition event.
# This makes the comparison sensitive to measured state changes while avoiding
# a false requirement that native and MAME advance on identical host/frame
# boundaries.

awk -F, -v skip="$skip_rows" '
function emit_expected(    i, key) {
    key = ""
    for (i = 2; i <= NF; ++i) if (expected_name[i] != "game_tick" && expected_name[i] != "time_ticks") key = key "|" $i
    if (key != last_expected) {
        expected_events[++expected_count] = key
        expected_frames[expected_count] = $1
        last_expected = key
    }
}
function emit_actual(    i, key) {
    key = ""
    for (i = 2; i <= NF; ++i) if (expected_name[i] != "game_tick" && expected_name[i] != "time_ticks") key = key "|" $i
    if (key != last_actual) {
        actual_events[++actual_count] = key
        actual_frames[actual_count] = $1
        last_actual = key
    }
}
NR == FNR {
    if (FNR == 1) {
        header = $0
        expected_columns = NF
        for (i = 1; i <= NF; ++i) expected_name[i] = $i
        next
    }
    if ((FNR - 1) <= skip) next
    emit_expected()
    next
}
FNR == 1 {
    if ($0 != header) {
        printf("HEADER_MISMATCH\nexpected: %s\nactual:   %s\n", header, $0)
        exit 10
    }
    next
}
{
    if (NF != expected_columns) {
        printf("COLUMN_COUNT_MISMATCH row=%d expected=%d actual=%d\n",
               FNR - 1, expected_columns, NF)
        exit 12
    }
    if ((FNR - 1) <= skip) next
    emit_actual()
}
END {
    if (actual_count < expected_count) {
        printf("NUMERIC_EVENT_COUNT_MISMATCH: expected at least %d transitions, actual %d\n",
               expected_count, actual_count)
        exit 14
    }

    for (event = 1; event <= expected_count; ++event) {
        if (expected_events[event] != actual_events[event]) {
            split(expected_events[event], e, "|")
            split(actual_events[event], a, "|")
            for (i = 2; i <= expected_columns; ++i) {
                if (e[i] != a[i]) {
                    printf("FIRST_NUMERIC_DIVERGENCE event=%d expected_row=%s actual_row=%s field=%s expected=%s actual=%s\n",
                           event, expected_frames[event], actual_frames[event],
                           expected_name[i], e[i], a[i])
                    exit 13
                }
            }
            printf("FIRST_NUMERIC_DIVERGENCE event=%d expected_row=%s actual_row=%s\n",
                   event, expected_frames[event], actual_frames[event])
            exit 13
        }
    }
}
' "$expected" "$actual"

echo "NUMERIC_STATE_MATCH: all state-transition vectors are identical"
