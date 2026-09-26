# Findings

## 2026-09-26 — sf2ua fixture layout validation

- The supplied `sf2ua` archive contains the canonical program filenames `sf2u_30a.11e`, `sf2u_37a.11f`, `sf2u_31a.12e`, `sf2u_38a.12f`, `sf2u_28a.9e`, `sf2u_35a.9f`, `sf2_29b.10e`, and `sf2_36b.10f`, plus the expected 12 graphics ROMs.
- The existing merge layout is correct for this fixture: byte-interleaving the four program pairs and 2-byte-interleaving the three graphics groups reproduces the documented SHA-1 values exactly: `allroms.bin=4256ec60bf9eec21f4d6bb34c38990a9401af82e` and `sf2gfx.bin=db52a6314b4c0cd4c48eb324720c83dd142c3bff`.
- `bin/mt2-merge.sh` now accepts both the historical names and the canonical MAME-set names without changing the generated layout.
- The original ROM data remains external to the repository, as required by `AGENTS.md`.
- Acceptance for this step: merge reproducibility and SHA-1 validation pass. Real MAME/native lockstep remains pending because the current execution environment does not provide the MAME executable.
