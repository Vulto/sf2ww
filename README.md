# MustardTiger

C99 rewrite of Street Fighter II World Warrior (MAME romset sf2ua)

## Read this first!

This is a work in progress native PC port.

## ROMs required to run

The source code does not include the original arcade ROM data. Provide a legally obtained MAME `sf2ua` ROM set as a ZIP file.

### Prepare and run

From the repository root:

```bash
sh bin/prepare-rom.sh /path/to/sf2ua.zip
cmake -DCMAKE_POLICY_VERSION_MINIMUM=3.5 -S . -B build
cmake --build build --parallel
./build/glutBasics
```

`prepare-rom.sh` extracts the ZIP, merges the ROMs, verifies the expected images, and places `allroms.bin` and `sf2gfx.bin` in the repository root.

A valid set produces these SHA-1 values:

```text
allroms.bin  4256ec60bf9eec21f4d6bb34c38990a9401af82e
sf2gfx.bin   db52a6314b4c0cd4c48eb324720c83dd142c3bff
```

The generated files are ignored by Git and are not distributed with this repository.

## Building and running

### Linux / macOS using CMake

The complete workflow is:

```bash
sh bin/prepare-rom.sh /path/to/sf2ua.zip
cmake -DCMAKE_POLICY_VERSION_MINIMUM=3.5 -S . -B build
cmake --build build --parallel
./build/glutBasics
```

The native runner loads `allroms.bin` and `sf2gfx.bin` from its current working directory.

### With Xcode

Open the MT2.xcodeproj project and build either the MT2 (Cocoa app) or MT2GLUT (command line app) target.

For MT2, place `allroms.bin` and `sf2gfx.bin` in the application's `Contents/Resources` directory.

For MT2GLUT, launch `glutBasics` with the generated ROM files in the current directory.

## Components of the project

### Fistblue

The game code derived from the original M68k ROMs.

### RedHammer

OpenGL + pthreads wrapper for running the game on POSIX systems.

### SwiftBeam

An abandoned windowing GUI toolkit.

## About the code

### Endianness

CPS SF2 runs on a big-endian m68k CPU. When running natively on a little-endian CPU, this creates complications for binary-compatible in-memory structures. Endian swapping is mostly done at runtime except where it can be cached beforehand.
