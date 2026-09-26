# MustardTiger

Native C99 PC port of Street Fighter II World Warrior, targeting behavioral and gameplay equivalence with the original arcade version (MAME `sf2ua`).

## Status

This is an active work-in-progress native PC port. The project is being validated against MAME as an empirical reference, with priority on:

- Running the complete game without crashes or undefined behavior.
- Matching gameplay state, timing, movement, combat, damage, AI, rounds, and match flow.
- Reproducing the arcade result natively on PC rather than using emulation.
- Expanding deterministic regression coverage as implementation gaps are fixed.

## ROMs required to run

The repository does not contain original arcade ROM data. Provide a legally obtained MAME `sf2ua` ROM set as a ZIP file.

### Prepare and run

From the repository root:

```bash
./bin/prepare-rom.sh /path/to/sf2ua.zip
cmake -DCMAKE_POLICY_VERSION_MINIMUM=3.5 -S . -B build
cmake --build build --parallel
./build/glutBasics
```

`prepare-rom.sh` extracts the ZIP, merges the required ROM data, verifies the resulting images, and places `allroms.bin` and `sf2gfx.bin` in the repository root.

A valid set produces these SHA-1 values:

```text
allroms.bin  4256ec60bf9eec21f4d6bb34c38990a9401af82e
sf2gfx.bin   db52a6314b4c0cd4c48eb324720c83dd142c3bff
```

The generated files are ignored by Git and are not distributed with this repository.

## Development and validation

The project uses CMake and GitHub Actions for automated validation. The CI pipeline includes:

- Native build and lint checks.
- Unit/integration tests.
- AddressSanitizer and UndefinedBehaviorSanitizer validation.
- Deterministic state-comparison tooling.
- MAME lockstep regression infrastructure.

The MAME regression job requires the legally obtained ROM fixture to be supplied privately through GitHub Actions configuration. ROM data must not be committed to or published by this repository.

## Building and running

### Linux / macOS using CMake

```bash
./bin/prepare-rom.sh /path/to/sf2ua.zip
cmake -DCMAKE_POLICY_VERSION_MINIMUM=3.5 -S . -B build
cmake --build build --parallel
./build/glutBasics
```

The native runner loads `allroms.bin` and `sf2gfx.bin` from its current working directory.

### With Xcode

Open `MT2.xcodeproj` and build either the MT2 (Cocoa app) or MT2GLUT (command line app) target.

For MT2, place `allroms.bin` and `sf2gfx.bin` in the application's `Contents/Resources` directory.

For MT2GLUT, launch `glutBasics` with the generated ROM files in the current directory.

## Components

### Fistblue

The game code derived from the original M68k ROMs.

### RedHammer

OpenGL + pthreads wrapper for running the game on POSIX systems.

### SwiftBeam

An abandoned windowing GUI toolkit.

## Architecture

The original CPS1 SF2 game runs on a big-endian Motorola 68000 CPU. The native port runs directly on the host PC architecture rather than emulating the original CPU.

Endian-sensitive data is handled explicitly where required for compatibility with the original game data. Runtime conversions are avoided where the data can be normalized or cached ahead of time.

## Development workflow

Work is performed directly on `main`. Changes are expected to be validated before integration, and meaningful progress should be committed to the repository.

For behavioral investigation, MAME is treated as the reference implementation: the objective is to reproduce the observable arcade behavior, not to preserve the original implementation technique.
