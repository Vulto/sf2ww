# Autonomous Port Agent

The autonomous loop is implemented by `.github/workflows/autonomous-port.yml` and is constrained to `main`.

Each iteration installs the native toolchain and MAME, materializes JTCPS and MAME as local references, invokes Codex, validates build/tests/sanitizers/smoke, runs real MAME/native lockstep when the private fixture is available, commits only validated progress, and dispatches the next iteration.

Required Actions secrets:
- `OPENAI_API_KEY`: key used by the official Codex GitHub Action.
- `SF2_MAME_ROM_URL`: private URL for the legally obtained `sf2ua` ROM ZIP.

The ROM is never committed or uploaded as an artifact.

JTCPS reference: https://github.com/jotego/jtcps
MAME reference: https://github.com/mamedev/mame

Completion requires the objective evidence defined in `AGENTS.md`; a green compile alone is not completion.


Autonomous loop heartbeat: continue from current `main` state on every workflow invocation.
