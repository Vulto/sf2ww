# State Map

## Confirmed CPS1 hardware map

The current MAME CPS1 driver confirms the common CPS1 main map used by Street Fighter II World Warrior:

| Address | Size | Function |
|---|---:|---|
| 0x000000–0x3FFFFF | 4 MiB | 68000 program ROM address space |
| 0x800000–0x800007 | 8 B | Player input ports |
| 0x800018–0x80001F | 8 B | System input / DIP switch reads |
| 0x800030–0x800037 | 8 B | Coin control writes |
| 0x800100–0x80013F | 64 B | CPS-A registers |
| 0x800140–0x80017F | 64 B | CPS-B registers for the standard mapping |
| 0x800180–0x800187 | 8 B | Sound command latch |
| 0x800188–0x80018F | 8 B | Sound timer/fade latch |
| 0x900000–0x92FFFF | 192 KiB | CPS graphics RAM |
| 0xFF0000–0xFFFFFF | 64 KiB | Main RAM |

MAME's CPS1 video timing is also confirmed as:
- visible area: 384x224;
- pixel clock: 8 MHz;
- total horizontal clocks: 512;
- visible horizontal range: 64..448;
- total scanlines: 262;
- visible vertical range: 16..240;
- refresh: approximately 59.6374 Hz.

Hardware clocks reported by the MAME machine description for World Warrior are 68000 10 MHz, Z80 3.579545 MHz, YM2151 3.579545 MHz and OKI MSM6295 1 MHz.

These hardware-level entries are evidence-backed and are not yet a logical-state equivalence map.

## Logical state — pending lockstep confirmation

The following fields remain pending direct MAME debugger/Lua extraction and frame-by-frame comparison:
- player X/Y;
- player state machine state;
- animation frame;
- active hitboxes/hurtboxes;
- life;
- round timer;
- RNG state;
- CPU AI decision;
- camera/scroll state;
- audio events.

The repository's existing `Game` layout contains candidate offsets for several of these fields, but those candidates are not promoted to the authoritative comparison map until lockstep instrumentation confirms them against MAME.
