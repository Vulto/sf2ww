#!/usr/bin/env bash
set -euo pipefail
if [ "$#" -ne 2 ]; then
    echo "usage: $0 <mame_state.csv> <port_state.csv>" >&2
    exit 2
fi
awk -F, '
NR==FNR {
    if (FNR == 1) next
    mcount++
    mtime[mcount]=$2
    mcycles[mcount]=$3
    next
}
FNR==1 { next }
{
    pcount++
    ptime[pcount]=$2
    pcycles[pcount]=$3
}
END {
    if (mcount != pcount) {
        printf("TIMING_EVENT_COUNT_MISMATCH mame=%d port=%d\n", mcount, pcount)
        exit 10
    }
    for (i=1; i<=mcount; ++i) {
        if (mtime[i] != ptime[i]) {
            printf("ARCADE_TIME_DIVERGENCE event=%d mame_ns=%s port_ns=%s\n", i, mtime[i], ptime[i])
            exit 11
        }
        if (mcycles[i] != pcycles[i]) {
            printf("ARCADE_CYCLE_DIVERGENCE event=%d mame_cycles=%s port_cycles=%s\n", i, mcycles[i], pcycles[i])
            exit 12
        }
    }
    print "ARCADE_TIMING_MATCH"
}
' "$1" "$2"
