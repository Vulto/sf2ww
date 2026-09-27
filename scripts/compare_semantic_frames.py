#!/usr/bin/env python3
import csv
import sys

if len(sys.argv) != 3:
    raise SystemExit("usage: compare_semantic_frames.py <mame.csv> <port.csv>")

IGNORE = {"arcade_time_ns", "arcade_cpu_cycles", "game_tick", "time_ticks", "seq", "frame"}


def load(path):
    with open(path, newline="") as file:
        reader = csv.DictReader(file)
        rows = list(reader)
        return reader.fieldnames, rows


def normalized(row, key, source):
    value = row[key]
    if source == "mame" and key in {"p1_y", "p2_y"}:
        return str(int(value) << 16)
    return value


def semantic(row, fields, source):
    return tuple(
        normalized(row, key, source)
        for key in fields
        if key not in IGNORE
    )


mameFields, mameRows = load(sys.argv[1])
portFields, portRows = load(sys.argv[2])

if not mameFields:
    raise SystemExit("MAME_HEADER_EMPTY")
if not portFields:
    raise SystemExit("PORT_HEADER_EMPTY")

if mameFields != portFields and not set(mameFields).issubset(portFields):
    raise SystemExit(f"HEADER_MISMATCH mame={mameFields} port={portFields}")

fields = mameFields

portEvents = []
previous = None
for index, row in enumerate(portRows, 1):
    current = semantic(row, fields, "port")
    if current != previous:
        portEvents.append((index, row, current))
        previous = current

if not mameRows:
    raise SystemExit("MAME_TRACE_EMPTY")

for source, rows in (("mame", mameRows), ("port", portRows)):
    for rowIndex, row in enumerate(rows, 2):
        for field in ("arcade_time_ns", "arcade_cpu_cycles"):
            try:
                int(row[field])
            except (KeyError, TypeError, ValueError):
                raise SystemExit(
                    f"INVALID_ARCADE_TIME source={source} row={rowIndex} field={field} value={row.get(field, '?')}"
                )

if not portEvents:
    raise SystemExit("PORT_TRACE_HAS_NO_SEMANTIC_TRANSITIONS")

if len(portEvents) != len(mameRows):
    print(
        "TRANSITION_COUNT_MISMATCH "
        f"mame={len(mameRows)} port={len(portEvents)}"
    )
    if len(portEvents) > len(mameRows):
        extraIndex = len(mameRows)
        extraRow = portEvents[extraIndex][1]
        print(
            "UNEXPECTED_EXTRA_PORT_TRANSITION "
            f"transition={extraIndex + 1} "
            f"port_time_ns={extraRow.get('arcade_time_ns', '?')}"
        )
    else:
        missingIndex = len(portEvents)
        missingRow = mameRows[missingIndex]
        print(
            "MISSING_PORT_TRANSITION "
            f"transition={missingIndex + 1} "
            f"mame_time_ns={missingRow.get('arcade_time_ns', '?')}"
        )
    raise SystemExit(11)

for transitionIndex, mameRow in enumerate(mameRows, 1):
    _, portRow, portSemantic = portEvents[transitionIndex - 1]
    mameSemantic = semantic(mameRow, fields, "mame")

    if mameSemantic != portSemantic:
        print(
            "FIRST_SEMANTIC_DIVERGENCE "
            f"transition={transitionIndex} "
            f"mame_time_ns={mameRow['arcade_time_ns']} "
            f"port_time_ns={portRow.get('arcade_time_ns', '?')}"
        )
        for key in fields:
            if key in IGNORE:
                continue
            mameValue = normalized(mameRow, key, "mame")
            portValue = normalized(portRow, key, "port")
            if mameValue != portValue:
                print(
                    "FIELD_DIVERGENCE "
                    f"field={key} mame={mameValue} port={portValue}"
                )
        raise SystemExit(12)

    mameTime = int(mameRow["arcade_time_ns"])
    portTime = int(portRow.get("arcade_time_ns", "0"))
    mameCycles = int(mameRow["arcade_cpu_cycles"])
    portCycles = int(portRow.get("arcade_cpu_cycles", "0"))

    if mameTime != portTime or mameCycles != portCycles:
        print(
            "FIRST_TIMING_DIVERGENCE "
            f"transition={transitionIndex} "
            f"mame_time_ns={mameTime} port_time_ns={portTime} "
            f"mame_cycles={mameCycles} port_cycles={portCycles} "
            f"delta_ns={portTime - mameTime} "
            f"delta_cycles={portCycles - mameCycles}"
        )
        raise SystemExit(13)

print(f"SEMANTIC_AND_TIMING_MATCH transitions={len(mameRows)}")
