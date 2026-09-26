#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 1 ]; then
    echo "usage: $0 <port_timing.csv>" >&2
    exit 2
fi

awk -F, '
NR == 1 {
    if ($1 != "frame" || $2 != "arcade_time_ns" || $3 != "arcade_cpu_cycles" ||
        $4 != "host_logic_ns" || $5 != "host_start_late_ns") exit 20
    next
}
{
    if ($1 !~ /^[0-9]+$/ || $2 !~ /^[0-9]+$/ || $3 !~ /^[0-9]+$/ ||
        $4 !~ /^[0-9]+$/ || $5 !~ /^[0-9]+$/) exit 21
    if ($4 > 16768000) {
        printf("HOST_LOGIC_DEADLINE_EXCEEDED frame=%s logic_ns=%s budget_ns=16768000\n", $1, $4)
        exit 22
    }
    count++
    logic[count] = $4
    late[count] = $5
}
END {
    if (count == 0) exit 23
    max = 0
    late_count = 0
    for (i = 1; i <= count; ++i) {
        if (logic[i] > max) max = logic[i]
        if (late[i] > 0) late_count++
    }
    printf("HOST_TIMING_OK frames=%d max_logic_ns=%d late_frames=%d\n", count, max, late_count)
}
' "$1"
