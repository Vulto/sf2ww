#!/usr/bin/env python3
import csv
import sys

if len(sys.argv) != 3:
    raise SystemExit("usage: compare_sound_events.py <mame_sound_commands.csv> <native_audio_events.csv>")

def load(path):
    with open(path, newline="") as f:
        return list(csv.DictReader(f))

mame = load(sys.argv[1])
native = load(sys.argv[2])

expected = [(int(r["data"]) & 0xff) for r in mame]
observed = [(int(r["data"]) & 0xff) for r in native if r.get("event") == "command"]

if not mame:
    raise SystemExit("MAME_SOUND_TRACE_EMPTY")
if not observed:
    raise SystemExit("NATIVE_SOUND_COMMAND_TRACE_EMPTY")

limit = min(len(expected), len(observed))
for i in range(limit):
    if expected[i] != observed[i]:
        print(f"FIRST_SOUND_COMMAND_DIVERGENCE sequence={i+1} mame={expected[i]} native={observed[i]}")
        raise SystemExit(12)

if len(expected) != len(observed):
    print(f"SOUND_COMMAND_COUNT_MISMATCH mame={len(expected)} native={len(observed)}")
    raise SystemExit(11)

print(f"SOUND_COMMAND_SEQUENCE_MATCH commands={len(expected)}")
