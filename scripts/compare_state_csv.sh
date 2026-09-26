#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -lt 2 ] || [ "$#" -gt 3 ]; then
    echo "usage: $0 <expected.csv> <actual.csv> [skip_frames]" >&2
    exit 2
fi

expected="$1"
actual="$2"
skip_frames="${3:-0}"

awk -F, -v skip="$skip_frames" '
NR == FNR {
    if (FNR == 1) {
        header = $0
        expected_columns = NF
        for (i = 1; i <= NF; ++i) {
            expected_name[i] = $i
        }
        next
    }

    row = FNR - 1
    if (row <= skip) {
        next
    }

    expected_row[row - skip] = $0
    expected_nf[row - skip] = NF
    for (i = 1; i <= NF; ++i) {
        expected_value[row - skip, i] = $i
    }
    expected_rows = row - skip
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
    actual_row = FNR - 1
    if (actual_row <= skip) {
        next
    }
    row = actual_row - skip

    if (!(row in expected_row)) {
        # The expected MAME probe is a fixed prefix. The native process may
        # produce additional frames before timeout; compare the common prefix
        # and require at least the full expected sequence in the final check.
        next
    }

    if (NF != expected_nf[row]) {
        printf("COLUMN_COUNT_MISMATCH at frame %s: expected %d actual %d\n", $1, expected_nf[row], NF)
        exit 12
    }

    for (i = 1; i <= NF; ++i) {
        if ($i != expected_value[row, i]) {
            printf("FIRST_DIVERGENCE frame=%s field=%s expected=%s actual=%s\n",
                   $1, expected_name[i], expected_value[row, i], $i)
            exit 13
        }
    }
    actual_rows = row
}

END {
    if (actual_rows < expected_rows) {
        printf("ROW_COUNT_MISMATCH: expected at least %d rows after skip, actual %d\n",
               expected_rows, actual_rows)
        exit 14
    }
}
' "$expected" "$actual"

echo "STATE_MATCH: all compared frames and fields are identical"
