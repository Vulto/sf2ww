#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -lt 2 ] || [ "$#" -gt 3 ]; then
    echo "usage: $0 <expected.csv> <actual.csv> [skip_rows]" >&2
    exit 2
fi

expected="$1"
actual="$2"
skip_rows="${3:-0}"

awk -F, -v skip="$skip_rows" '
function semantic_key(    i, key) {
    key = ""
    for (i = 2; i <= NF; ++i) {
        if (name[i] != "game_tick" && name[i] != "time_ticks" &&
            name[i] != "arcade_time_ns" && name[i] != "arcade_cpu_cycles") {
            key = key "|" $i
        }
    }
    return key
}
function emit_expected(    key) {
    key = semantic_key()
    if (key != last_expected) {
        ++expected_count
        expected_events[expected_count] = key
        expected_time[expected_count] = $2
        expected_cycles[expected_count] = $3
        expected_rows[expected_count] = FNR
        last_expected = key
    }
}
function emit_actual(    key) {
    key = semantic_key()
    if (key != last_actual) {
        ++actual_count
        actual_events[actual_count] = key
        actual_time[actual_count] = $2
        actual_cycles[actual_count] = $3
        actual_rows[actual_count] = FNR
        last_actual = key
    }
}
NR == FNR {
    if (FNR == 1) {
        header = $0
        expected_columns = NF
        for (i = 1; i <= NF; ++i) name[i] = $i
        next
    }
    if ((FNR - 1) <= skip) next
    emit_expected()
    next
}
FNR == 1 {
    if ($0 != header) {
        printf("HEADER_MISMATCH
expected: %s
actual:   %s
", header, $0)
        exit 10
    }
    next
}
{
    if (NF != expected_columns) {
        printf("COLUMN_COUNT_MISMATCH row=%d expected=%d actual=%d
",
               FNR - 1, expected_columns, NF)
        exit 12
    }
    if ((FNR - 1) <= skip) next
    emit_actual()
}
END {
    if (actual_count < expected_count) {
        printf("NUMERIC_EVENT_COUNT_MISMATCH: expected at least %d transitions, actual %d
",
               expected_count, actual_count)
        exit 14
    }

    for (event = 1; event <= expected_count; ++event) {
        if (expected_events[event] != actual_events[event]) {
            split(expected_events[event], e, "|")
            split(actual_events[event], a, "|")
            for (i = 2; i <= expected_columns; ++i) {
                if (e[i] != a[i]) {
                    printf("FIRST_NUMERIC_DIVERGENCE event=%d expected_row=%d actual_row=%d field=%s expected=%s actual=%s expected_time_ns=%s actual_time_ns=%s
",
                           event, expected_rows[event], actual_rows[event],
                           name[i], e[i], a[i], expected_time[event], actual_time[event])
                    exit 13
                }
            }
            printf("FIRST_NUMERIC_DIVERGENCE event=%d expected_row=%d actual_row=%d expected_time_ns=%s actual_time_ns=%s
",
                   event, expected_rows[event], actual_rows[event], expected_time[event], actual_time[event])
            exit 13
        }

        if (expected_time[event] != actual_time[event]) {
            printf("FIRST_TIMING_DIVERGENCE event=%d expected_row=%d actual_row=%d expected_time_ns=%s actual_time_ns=%s delta_ns=%d
",
                   event, expected_rows[event], actual_rows[event],
                   expected_time[event], actual_time[event],
                   actual_time[event] - expected_time[event])
            exit 15
        }
        if (expected_cycles[event] != actual_cycles[event]) {
            printf("FIRST_TIMING_DIVERGENCE event=%d expected_row=%d actual_row=%d expected_cycles=%s actual_cycles=%s delta_cycles=%d
",
                   event, expected_rows[event], actual_rows[event],
                   expected_cycles[event], actual_cycles[event],
                   actual_cycles[event] - expected_cycles[event])
            exit 16
        }
    }
}
' "$expected" "$actual"

echo "NUMERIC_STATE_AND_ARCADE_TIMING_MATCH: all state-transition vectors occur at identical arcade time/cycle positions"
