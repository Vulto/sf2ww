#!/usr/bin/env python3
import csv
import sys

if len(sys.argv) != 3:
    raise SystemExit("usage: compare_sound_events.py <mame_sound_events.csv> <native_audio_events.csv>")

def load(path):
    with open(path, newline="") as handle:
        return list(csv.DictReader(handle))

mame = load(sys.argv[1])
native = load(sys.argv[2])

if not mame:
    raise SystemExit("MAME_SOUND_TRACE_EMPTY")

mame_commands = [
    (int(row["data"]) & 0xff, int(row["arcade_time_ns"]), row.get("event", "command"))
    for row in mame
    if row.get("event") == "command"
]
native_commands = [
    (int(row["data"]) & 0xff, int(row["arcade_time_ns"]), row.get("event", "command"))
    for row in native
    if row.get("event") == "command"
]

if not mame_commands:
    raise SystemExit("MAME_SOUND_COMMAND_TRACE_EMPTY")
if not native_commands:
    raise SystemExit("NATIVE_SOUND_COMMAND_TRACE_EMPTY")

limit = min(len(mame_commands), len(native_commands))
for index in range(limit):
    expected, mame_time, _ = mame_commands[index]
    observed, native_time, _ = native_commands[index]
    if expected != observed:
        print(
            f"FIRST_SOUND_COMMAND_DIVERGENCE sequence={index + 1} "
            f"mame={expected} native={observed} "
            f"mame_time_ns={mame_time} native_time_ns={native_time}"
        )
        raise SystemExit(12)

if len(mame_commands) != len(native_commands):
    print(
        f"SOUND_COMMAND_COUNT_MISMATCH mame={len(mame_commands)} "
        f"native={len(native_commands)}"
    )
    raise SystemExit(11)

print(f"SOUND_COMMAND_SEQUENCE_MATCH commands={len(mame_commands)}")

mame_chip = [
    (row.get("event", ""), int(row["data"]) & 0xff)
    for row in mame
    if row.get("event") in {"ym_address", "ym_data", "oki_data", "bank", "oki_pin7"}
]
native_chip = [
    (row.get("event", ""), int(row["data"]) & 0xff)
    for row in native
    if row.get("event") in {"ym_address", "ym_data", "oki_data", "bank", "oki_pin7"}
]

if native_chip:
    if not mame_chip:
        raise SystemExit("MAME_SOUND_CHIP_TRACE_EMPTY")
    limit = min(len(mame_chip), len(native_chip))
    for index in range(limit):
        if mame_chip[index] != native_chip[index]:
            print(
                f"FIRST_SOUND_CHIP_DIVERGENCE sequence={index + 1} "
                f"mame_event={mame_chip[index][0]} mame={mame_chip[index][1]} "
                f"native_event={native_chip[index][0]} native={native_chip[index][1]}"
            )
            raise SystemExit(13)
    if len(mame_chip) != len(native_chip):
        print(
            f"SOUND_CHIP_EVENT_COUNT_MISMATCH mame={len(mame_chip)} "
            f"native={len(native_chip)}"
        )
        raise SystemExit(14)
    print(f"SOUND_CHIP_SEQUENCE_MATCH events={len(mame_chip)}")
