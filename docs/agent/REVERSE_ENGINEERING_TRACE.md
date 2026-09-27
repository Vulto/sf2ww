# Deep Reverse-Engineering Observation

The repository has two complementary observation paths.

## MAME reference

`scripts/run_mame_reverse_trace.sh` runs the private `sf2ua` fixture for 7200 emulated frames with MAME's debugger enabled and DRC disabled.

It records:

- `reverse_68000.tr`: every executed 68000 instruction with PC, SR, D0-D7, A0-A7, exact debugger `totalcycles` and `lastinstructioncycles`;
- `reverse_memory_reads.csv`: program-space read accesses over the complete 24-bit 68000 address space;
- `reverse_memory_writes.csv`: program-space write accesses over the complete 24-bit 68000 address space;
- `reverse_registers.csv`: every register/state entry exposed by MAME at every frame boundary;
- `reverse_frames.csv`: frame timing, CPU timing, primary game-state values and state-machine mode;
- `reverse_ram_changes.csv`: every byte changed in the 64 KiB main RAM between frame boundaries;
- `reverse_memory_map.csv`: address-map entries, regions, shares and banks;
- `reverse_manifest.csv`: provenance and instrumentation configuration.

The memory access records include the access address, data, mask, PC and arcade timing.

MAME exposes the main CPU's `totalcycles` debugger symbol and supports uncondensed instruction tracing. Its Lua memory API also exposes read/write taps for address ranges and address-map metadata. These are the primary sources for causal reverse engineering.

## Native port

When `SF2_REVERSE_NATIVE_TRACE=1` is set, the native port records the complete native `Game` object at every interrupt in:

- `native_reverse_state.bin`: versioned binary records containing the complete `Game` bytes for every interrupt;
- `native_reverse_manifest.csv`: `Game` size and field offsets for decoding the binary records.

This is deliberately a raw state capture rather than a hand-selected semantic subset. Native pointers are marked as native addresses and must not be treated as stable identities between processes.

## Attract-cycle coverage

The deep validator fails unless the observed native/reference trace contains all attract state-manager values documented by the port:

`0, 2, 4, 6, 8, A, C, E, 10, 12`.

In the current source:

- `mode0=2` enters the title/logo animation;
- `mode0=6` runs the winner sequence;
- `mode0=A` runs the demo fight;
- `mode0=E` runs the high-score/rank display;
- `mode0=12` resets the attract sequence.

This makes coverage an observed state-machine criterion instead of an assumption based on elapsed time.

## Timing interpretation

Deep-trace timing is **not** compared against a normal uninstrumented run. Instruction tracing and memory taps intentionally add overhead.

The trace's arcade timing remains useful for ordering and causal analysis within the same instrumentation configuration. The normal lockstep test remains the authoritative exact timing gate between the port and the MAME reference.

## Persistence

The full deep traces are uploaded by the scheduled GitHub Actions run as `sf2ww-reverse-engineering-<commit>` artifacts. The repository contains the collectors, schemas, validators and decoding metadata so future agents can reproduce the data rather than relying on an opaque one-off capture.

Raw traces are intentionally not committed blindly: instruction and bus traces can grow by many gigabytes. Future agents should promote compact, proven excerpts into the repository only after identifying a reproducible divergence or a stable reverse-engineering fact.
