#!/usr/bin/env python3
import csv, sys

if len(sys.argv) != 3:
    raise SystemExit("usage: compare_semantic_frames.py <mame.csv> <port.csv>")

def rows(path):
    with open(path, newline="") as f:
        r=csv.DictReader(f)
        return list(r), r.fieldnames

a, ah = rows(sys.argv[1])
b, bh = rows(sys.argv[2])
if ah != bh:
    raise SystemExit(f"HEADER_MISMATCH expected={ah} actual={bh}")
if len(b) < len(a):
    raise SystemExit(f"FRAME_COUNT_MISMATCH expected={len(a)} actual={len(b)}")

ignore={"arcade_time_ns","arcade_cpu_cycles"}
for i,(ea,ba) in enumerate(zip(a,b),1):
    for k in ah:
        if k in ignore:
            continue
        if ea[k] != ba[k]:
            print(f"FIRST_FRAME_DIVERGENCE frame={i} field={k} expected={ea[k]} actual={ba[k]}")
            # Emit all differing fields for the same frame.
            diffs=[f"{k}:{ea[k]}!={ba[k]}" for k in ah if k not in ignore and ea[k]!=ba[k]]
            print("FRAME_DIFFS " + " ".join(diffs))
            raise SystemExit(13)

print(f"SEMANTIC_FRAME_MATCH frames={len(a)}")
