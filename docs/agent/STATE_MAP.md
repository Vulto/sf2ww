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

## Logical state — field addresses confirmed, equivalence pending

The MAME/ROM field addresses below are now confirmed against the World Warrior fighter layout; byte-for-byte semantic equivalence with the native port remains pending real lockstep execution.
- P1 base: `0xFF83C6`; P2 base: `0xFF86C6`;
- player X/Y: offsets `0x06/0x08` (32-bit fixed-point);
- player state machine: offsets `0x02/0x03/0x04`;
- animation control: offset `0x14`;
- life/energy: offset `0x2A`;
- move: offset `0x180`;
- stand/crouch/jump classification: offset `0x188`;
- round timer: `0xFF0ACE/0xFF0ACF`;
- round count: `0xFF0A4C`;
- stage: `0xFF09E4`;
- fight-over flag: `0xFF0AE1`;
- RNG seeds: `0xFF02C4/0xFF02C5`;
- frame counter: `0xFF001C`;
- CPU AI decision, hitboxes/hurtboxes, camera/scroll state and audio events remain pending direct lockstep validation.

The repository's existing `Game` layout contains candidate offsets for several of these fields, but those candidates are not promoted to the authoritative comparison map until lockstep instrumentation confirms them against MAME.
