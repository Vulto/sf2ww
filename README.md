# MustardTiger

C99 rewrite of Street Fighter II World Warrior (MAME romset sf2ua)

## Read this first!

This is a work in progress, not a complete game. It currently only builds in Xcode, and even then the whole game is riddled with bugs.

If you're after a complete, breathtaking gaming experience, *this repo is not for you*.

This repo is for people who'd like to learn what a game like SF2 looks like inside, and those that can help complete it. If you don't understand why someone would do this, go back to Reddit please.

## Want to learn more?

Check out the [blog](https://sf2platinum.wordpress.com). I'd always intended to write more (don't we all) but I've been very short of time lately, which is why I decided to open this repo up. It'd be a waste if I did all this work and noone ever saw it.

## ROMs required to run

The source code does not include the original Street Fighter II World Warrior arcade ROM data. To run the native PC port, provide the ROM images separately and prepare the two combined files expected by the program:

- `allroms.bin` — combined 68000 program ROM image
- `sf2gfx.bin` — combined graphics ROM image

The repository's `bin/mt2-merge.sh` script accepts both the original filenames used by the old merge instructions and the canonical filenames commonly found inside an `sf2ua` MAME set. In particular, the program ROMs may be named:

- `sf2u.30a`, `sf2u.37a`, `sf2u.31a`, `sf2u.38a`, `sf2u.28a`, `sf2u.35a`, `sf2_29a.bin`, `sf2_36a.bin`
- or `sf2u_30a.11e`, `sf2u_37a.11f`, `sf2u_31a.12e`, `sf2u_38a.12f`, `sf2u_28a.9e`, `sf2u_35a.9f`, `sf2_29b.10e`, `sf2_36b.10f`

The graphics ROM names are the `sf2-*.4a/.6a/.3a/.5a`, `sf2-*.4c/.6c/.3c/.5c`, and `sf2-*.4d/.6d/.3d/.5d` files used by the script.

### Prepare the ROMs

Install the `interleave` utility and place the legally obtained source ROM files in one working directory. Then run:

```bash
sh bin/mt2-merge.sh
```

The script prints the expected SHA-1 values. A correct set produces:

```text
allroms.bin: 4256ec60bf9eec21f4d6bb34c38990a9401af82e
sf2gfx.bin:  db52a6314b4c0cd4c48eb324720c83dd142c3bff
```

Keep these generated files in the repository root, or in the working directory from which you launch `glutBasics`. They are ignored by Git and are not distributed with this repository.

## Building and running

### Linux / macOS using CMake

From the repository root:

```bash
cmake -DCMAKE_POLICY_VERSION_MINIMUM=3.5 -S . -B build
cmake --build build --parallel
./build/glutBasics
```

The native runner loads `allroms.bin` and `sf2gfx.bin` using relative paths, so they must be present in its current working directory.

### With Xcode

Open the MT2.xcodeproj project and build either the MT2 (a Cocoa app) or MT2GLUT (command line app) target.

#### MT2 Cocoa app

After building, open the compiled bundle in Finder by using Show Package Contents, and copy your `allroms.bin` and `sf2gfx.bin` files to the `Contents/Resources` directory.

#### MT2GLUT app

Ensure `allroms.bin` and `sf2gfx.bin` are in the current directory when running `glutBasics`.

## Components of the project

### Fistblue

The actual game code from the M68k ROMs, anything that's not a rewrite of the original game shouldn't be in here. In theory, this component should be able to be compiled back to m68k, burned to EPROMS and run on a real CPS.

In theory.

todo: gfx_glut.\\[c|h\\] are not part of the M68k code and should be moved to RedHammer.

### RedHammer

OpenGL + pthreads wrapper for running the game on POSIX systems

All original work, no CAPCOM code in here

### SwiftBeam

An abandoned windowing GUI toolkit. I thought it might be fun to try writing a basic window manager from scratch. It wasn't. I thought I'd use it to manage debug windows, etc. Might pull this out one day.

## Issues right now

* The project is a bit of a mess and needs organising
* ~~No instructions on how to run it, which ROMs are required, etc. out of the box~~
* No unit tests. Most game functions are tightly coupled to the game state and have side effects, making unit testing almost impossible
* The project should be split up into RedHammer, FistBlue, and one combining them, so that RedHammer can be

## About the code

### Endianness

CPS SF2 runs on a big-endian m68k CPU. When we're running natively on a little-endian CPU, this creates complications when trying to keep binary compatibility with in-memory structures. Endian swapping is mostly done at runtime except where it can be easily cached beforehand. The code has been tested on a big-endian PowerPC G4, but not for some time.
