# CPS1.5 FPGA Oracle for the Native SF2 Port

This document defines the hardware-derived oracle for reverse engineering and CI validation. The goal is observable equivalence to CPS1.5, not reproduction of FPGA source architecture.

## Reference hierarchy

1. JTCPS CPS1/CPS1.5 RTL — primary hardware-behavior specification.
2. MiSTer/JTFRAME simulation and verification material — timing, VRAM, object-DMA and checkpoint methodology.
3. MAME — software-visible behavior, CPU execution evidence and ROM/state correlation.
4. Native port — implementation under test.

The JTCPS documentation identifies the core as CPS1/1.5/2 compatible and documents CPS1.5 ROM organization, CPU speed selection, MRA metadata, simulation and video verification.

## CI invariants

### CPU and bus

Record logical checkpoint, MAME 68000 PC/SR/register context, memory address and direction, wait/DTACK cycles where observable, accumulated 68000-equivalent cycles, VBLANK boundary, DMA bus ownership and equivalent native operation/data values.

Do not require x86 instruction addresses to match 68000 addresses. Native code is accepted when observable machine-level data and timing contracts match.

### CPS-A/CPS-B registers

Snapshot object VRAM base, Scroll1/2/3 VRAM bases, RowScroll VRAM base, palette base/copy control, layer control, four priority masks, enabled palette pages, game ID, graphics bank offset/mask, CPU speed and CPS1.5/Kabuki configuration whenever they initialize or change.

### Tilemaps and scroll geometry

JTCPS defines Scroll1 as 512x512 with 8x8 tiles, Scroll2 as 1024x1024 with 16x16 tiles, and Scroll3 as 2048x2048 with 32x32 tiles.

For every video checkpoint capture scroll X/Y, tilemap VRAM base, tile-map address, tile code, H/V flip, palette, graphics group, decoded pixel nibble and resulting layer/pixel selector.

This is the preferred oracle for background defects. Framebuffer comparison is only final symptom evidence.

### Tile ROM addressing

Record plane, tile code, tile size, H/V flip, graphics bank mask, bank offset and ROM address. A mismatch is a graphics-data defect even if final pixels happen to look similar.

### VRAM DMA

Treat RowScroll, OBJ, Scroll1/2/3 and palette as separate DMA tasks. Capture task activation order, VRAM address sequence, source value, destination cache/bank, object-table fill/end markers, palette pages copied, scanline/vertical position and DMA completion checkpoint.

The JTCPS RTL contains measured DMA timing information and explicitly accounts for OBJ, row-scroll and palette interaction. These measurements are preferable to host wall-clock time.

### Object/sprite path

Capture object-table entry, object code, attributes, position, bank, size, flip, line-table address, decoded tile/ROM address, per-line pixel result and priority group.

The JTCPS verification documentation notes that object DMA may require more than one frame before sprites can be completely observed; tests must account for this instead of treating the first frame as complete.

### Color mixer

Compare layer enable, source pixel, palette group/color, priority mask, selected layer and output palette entry for OBJ, Scroll1, Scroll2 and Scroll3. This makes priority/compositing defects independently detectable from framebuffer pixels.

### Timing

Use arcade-domain quantities: logical frame, scanline, VBLANK, HBLANK, CPU enable count, CPU-equivalent cycles, DMA cycles and operation checkpoint. Host nanoseconds are diagnostic only.

### Sound

For CPS1.5 record main CPU sound writes, QSound command/data sequence, logical cycle/frame, audio CPU/DSP state when available, sample/PCM address and final audio event sequence. Waveform comparison is secondary to command/state equivalence.

## Canonical CI scenarios

Each scenario specifies reset state, configuration, ROM identity, input stream, seed where controllable, start checkpoint and end checkpoint.

1. cold boot
2. attract startup
3. building/skyscraper attract sequence
4. title/attract transition
5. character select
6. each fighter/stage initialization
7. fixed-input movement primitives
8. normal attack classes
9. specials and projectiles
10. throws
11. hit/block/damage/stun
12. round timer expiration
13. round/match transitions
14. deterministic CPU-controlled sequences
15. audio command sequences
16. long deterministic attract/gameplay soak

## First-divergence protocol

The comparator must stop at the first causal difference and report scenario, checkpoint, frame, scanline, cycle, subsystem, field/address, expected value, observed value, previous matching checkpoint and next dependent operation.

A framebuffer mismatch without an upstream data mismatch is allowed only when the renderer/output stage itself is under investigation.

## Current building clue

FistBlue/scrolls/gstate.c currently assigns Scroll2Y from Scroll2 X position inside gstate_update_scroll2(). The same file identifies _GSDrawScroll2C() as the path apparently used by the attract building/skyscraper. This is a hypothesis to test against FPGA/MAME numeric traces, not a pre-approved code change.
