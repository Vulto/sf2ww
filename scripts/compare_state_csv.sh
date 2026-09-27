#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -lt 2 ] || [ "$#" -gt 3 ]; then
    echo "usage: $0 <expected.csv> <actual.csv> [skip_rows]" >&2
    exit 2
fi

expected="$1"
actual="$2"
skipRows="${3:-0}"

awk -F, -v skip="$skipRows" '
function semanticKey(    i, key) {
    key = ""
    for (i = 2; i <= NF; ++i) {
        if (name[i] != "game_tick" && name[i] != "time_ticks" &&
            name[i] != "arcade_time_ns" && name[i] != "arcade_cpu_cycles") {
            key = key "|" $i
        }
    }
    return key
}
function emitExpected(    key) {
    key = semanticKey()
    if (key != lastExpected) {
        ++expectedCount
        expectedEvents[expectedCount] = key
        expectedTime[expectedCount] = $2
        expectedCycles[expectedCount] = $3
        expectedRows[expectedCount] = FNR
        lastExpected = key
    }
}
function emitActual(    key) {
    key = semanticKey()
    if (key != lastActual) {
        ++actualCount
        actualEvents[actualCount] = key
        actualTime[actualCount] = $2
        actualCycles[actualCount] = $3
        actualRows[actualCount] = FNR
        lastActual = key
    }
}
NR == FNR {
    if (FNR == 1) {
        header = $0
        expectedColumns = NF
        for (i = 1; i <= NF; ++i) name[i] = $i
        next
    }
    if ((FNR - 1) <= skip) next
    emitExpected()
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
    if (NF != expectedColumns) {
        printf("COLUMN_COUNT_MISMATCH row=%d expected=%d actual=%d\n",
               FNR - 1, expectedColumns, NF)
        exit 12
    }
    if ((FNR - 1) <= skip) next
    emitActual()
}
END {
    if (actualCount < expectedCount) {
        printf("NUMERIC_EVENT_COUNT_MISMATCH: expected at least %d transitions, actual %d\n",
               expectedCount, actualCount)
        exit 14
    }

    for (event = 1; event <= expectedCount; ++event) {
        if (expectedEvents[event] != actualEvents[event]) {
            split(expectedEvents[event], expectedFields, "|")
            split(actualEvents[event], actualFields, "|")
            for (i = 2; i <= expectedColumns; ++i) {
                if (expectedFields[i] != actualFields[i]) {
                    printf("FIRST_NUMERIC_DIVERGENCE event=%d expected_row=%d actual_row=%d field=%s expected=%s actual=%s expectedTime_ns=%s actualTime_ns=%s\n",
                           event, expectedRows[event], actualRows[event],
                           name[i], expectedFields[i], actualFields[i],
                           expectedTime[event], actualTime[event])
                    exit 13
                }
            }
            printf("FIRST_NUMERIC_DIVERGENCE event=%d expected_row=%d actual_row=%d expectedTime_ns=%s actualTime_ns=%s\n",
                   event, expectedRows[event], actualRows[event],
                   expectedTime[event], actualTime[event])
            exit 13
        }

        if (expectedTime[event] != actualTime[event]) {
            printf("FIRST_TIMING_DIVERGENCE event=%d expected_row=%d actual_row=%d expectedTime_ns=%s actualTime_ns=%s delta_ns=%d\n",
                   event, expectedRows[event], actualRows[event],
                   expectedTime[event], actualTime[event],
                   actualTime[event] - expectedTime[event])
            exit 15
        }
        if (expectedCycles[event] != actualCycles[event]) {
            printf("FIRST_TIMING_DIVERGENCE event=%d expected_row=%d actual_row=%d expectedCycles=%s actualCycles=%s delta_cycles=%d\n",
                   event, expectedRows[event], actualRows[event],
                   expectedCycles[event], actualCycles[event],
                   actualCycles[event] - expectedCycles[event])
            exit 16
        }
    }
}
' "$expected" "$actual"

echo "NUMERIC_STATE_AND_ARCADE_TIMING_MATCH: all state-transition vectors occur at identical arcade time/cycle positions"
