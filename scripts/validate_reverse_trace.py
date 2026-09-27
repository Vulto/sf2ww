#!/usr/bin/env python3
import csv
from pathlib import Path

REQUIRED = {
    "reverse_frames.csv": ["frame", "arcade_time_ns", "arcade_cpu_cycles", "pc", "sr"],
    "reverse_memory_reads.csv": ["seq", "arcade_time_ns", "arcade_cpu_cycles", "pc", "address", "data", "mem_mask"],
    "reverse_memory_writes.csv": ["seq", "arcade_time_ns", "arcade_cpu_cycles", "pc", "address", "data", "mem_mask"],
    "reverse_ram_changes.csv": ["frame", "arcade_time_ns", "arcade_cpu_cycles", "address", "value"],
    "reverse_registers.csv": ["frame", "arcade_time_ns", "arcade_cpu_cycles", "name", "value"],
    "reverse_audiocpu_reads.csv": ["seq", "arcade_time_ns", "cpu", "address", "data", "mem_mask", "pc"],
    "reverse_audiocpu_writes.csv": ["seq", "arcade_time_ns", "cpu", "address", "data", "mem_mask", "pc"],
    "reverse_sound_commands.csv": ["seq", "arcade_time_ns", "arcade_cpu_cycles", "pc", "sr", "address", "data", "mem_mask"],
    "reverse_registers.csv": ["frame", "arcade_time_ns", "arcade_cpu_cycles", "name", "value"],
}

def fail(message):
    raise SystemExit(message)

for filename, fields in REQUIRED.items():
    path = Path(filename)
    if not path.is_file() or path.stat().st_size == 0:
        fail(f"MISSING_REVERSE_TRACE {filename}")
    with path.open(newline="") as handle:
        reader = csv.DictReader(handle)
        if reader.fieldnames is None:
            fail(f"EMPTY_HEADER {filename}")
        missing = [field for field in fields if field not in reader.fieldnames]
        if missing:
            fail(f"HEADER_MISSING {filename} fields={missing}")
        count = 0
        previous_time = -1
        previous_cycles = -1
        for row in reader:
            count += 1
            try:
                time_ns = int(row["arcade_time_ns"])
                cycles = int(row["arcade_cpu_cycles"])
            except ValueError:
                fail(f"INVALID_TIMING {filename} row={count + 1}")
            if time_ns < previous_time or cycles < previous_cycles:
                fail(f"NON_MONOTONIC_TIMING {filename} row={count + 1}")
            previous_time = time_ns
            previous_cycles = cycles
        if count == 0:
            fail(f"NO_DATA_ROWS {filename}")

with Path("reverse_frames.csv").open(newline="") as handle:
    frames = sum(1 for _ in csv.DictReader(handle))
if frames < 3600:
    fail(f"REVERSE_TRACE_TOO_SHORT frames={frames} required=3600")

with Path("reverse_registers.csv").open(newline="") as handle:
    register_names = set()
    for row in csv.DictReader(handle):
        register_names.add(row["name"])
    if "CURPC" not in register_names or "D0" not in register_names or "A7" not in register_names:
        fail("INCOMPLETE_CPU_REGISTER_TRACE")

with Path("reverse_frames.csv").open(newline="") as handle:
    modes = {int(row["game_mode"], 0) for row in csv.DictReader(handle)}
required_modes = {0x0, 0x2, 0x4, 0x6, 0x8, 0xA, 0xC, 0xE, 0x10, 0x12}
missing_modes = required_modes - modes
if missing_modes:
    fail("ATTRACT_SEQUENCE_INCOMPLETE missing_modes=" + ",".join(hex(value) for value in sorted(missing_modes)))

with Path("reverse_registers.csv").open(newline="") as handle:
    register_names = set()
    for row in csv.DictReader(handle):
        register_names.add(row["name"])
    if "CURPC" not in register_names or "D0" not in register_names or "A7" not in register_names:
        fail("INCOMPLETE_CPU_REGISTER_TRACE")

with Path("reverse_frames.csv").open(newline="") as handle:
    modes = {int(row["game_mode"], 0) for row in csv.DictReader(handle)}
required_modes = {0x0, 0x2, 0x4, 0x6, 0x8, 0xA, 0xC, 0xE, 0x10, 0x12}
missing_modes = required_modes - modes
if missing_modes:
    fail("ATTRACT_SEQUENCE_INCOMPLETE missing_modes=" + ",".join(hex(value) for value in sorted(missing_modes)))

for filename in ("reverse_memory_reads.csv", "reverse_memory_writes.csv", "reverse_audiocpu_reads.csv", "reverse_audiocpu_writes.csv", "reverse_sound_commands.csv"):
    with Path(filename).open(newline="") as handle:
        for row in csv.DictReader(handle):
            address = int(row["address"])
            if address < 0 or address > 0xffffff:
                fail(f"ADDRESS_OUT_OF_RANGE {filename} address={address}")

print(f"REVERSE_TRACE_FORMAT_OK frames={frames}")
