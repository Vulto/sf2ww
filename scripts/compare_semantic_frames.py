#!/usr/bin/env python3
import csv, sys

if len(sys.argv) != 3:
    raise SystemExit("usage: compare_semantic_frames.py <mame.csv> <port.csv>")

IGNORE = {"arcade_time_ns", "arcade_cpu_cycles", "game_tick", "time_ticks", "seq", "frame"}

def load(path):
    with open(path, newline="") as f:
        r = csv.DictReader(f)
        rows = list(r)
        return r.fieldnames, rows

def semantic(row, fields):
    return tuple(row[k] for k in fields if k not in IGNORE)

mf, mame = load(sys.argv[1])
pf, port = load(sys.argv[2])
if mf != pf and not set(mf).issubset(pf):
    raise SystemExit(f"HEADER_MISMATCH mame={mf} port={pf}")
fields = mf

# MAME emits only semantic transitions. Collapse the native per-frame trace
# to the same transition representation before comparing it.
port_events = []
prev = None
for idx, row in enumerate(port, 1):
    cur = semantic(row, fields)
    if cur != prev:
        port_events.append((idx, row, cur))
        prev = cur

if len(port_events) < len(mame):
    raise SystemExit(f"TRANSITION_COUNT_MISMATCH expected_at_least={len(mame)} actual={len(port_events)}")

for i, mrow in enumerate(mame):
    msem = semantic(mrow, fields)
    _, prow, psem = port_events[i]
    if msem != psem:
        diffs = []
        for k in fields:
            if k in IGNORE:
                continue
            if mrow[k] != prow[k]:
                diffs.append(f"{k}:{mrow[k]}!={prow[k]}")
        print(f"FIRST_TRANSITION_DIVERGENCE transition={i+1} mame_time_ns={mrow['arcade_time_ns']} port_time_ns={prow.get('arcade_time_ns','?')}")
        print("TRANSITION_DIFFS " + " ".join(diffs))
        raise SystemExit(13)
    mt = int(mrow["arcade_time_ns"])
    pt = int(prow.get("arcade_time_ns", "0"))
    if mt != pt:
        print(f"FIRST_TIMING_DIVERGENCE transition={i+1} mame_time_ns={mt} port_time_ns={pt}")
        raise SystemExit(14)

print(f"SEMANTIC_TRANSITION_MATCH transitions={len(mame)}")
