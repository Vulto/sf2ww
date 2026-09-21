#!/bin/sh
# How to merge the sf2ua romset for use with the SF2 rewrite

# Basically, you need to merge the ROMs together the same was as they're mapped on the real
# hardware.

# First, get the interleave tool from https://www.romhacking.net/forum/index.php?topic=26264.0

python3 bin/interleave.py 1 int1 sf2u_30a.11e sf2u_37a.11f
python3 bin/interleave.py 1 int2 sf2u_31a.12e sf2u_38a.12f
python3 bin/interleave.py 1 int3 sf2u_28a.9e sf2u_35a.9f
python3 bin/interleave.py 1 int4 sf2_29b.10e sf2_36b.10f
cat int1 int2 int3 int4 > allroms.bin
echo "4256ec60bf9eec21f4d6bb34c38990a9401af82e - expected shasum"
shasum allroms.bin 

python3 bin/interleave.py 2 gint1 sf2-5m.4a sf2-7m.6a sf2-1m.3a sf2-3m.5a
python3 bin/interleave.py 2 gint2 sf2-6m.4c sf2-8m.6c sf2-2m.3c sf2-4m.5c
python3 bin/interleave.py 2 gint3 sf2-13m.4d sf2-15m.6d sf2-9m.3d sf2-11m.5d

cat gint1 gint2 gint3 > sf2gfx.bin
echo "db52a6314b4c0cd4c48eb324720c83dd142c3bff - expected shasum"
shasum sf2gfx.bin  # should be db52a6314b4c0cd4c48eb324720c83dd142c3bff 

# Copy both these ROMs into the `Resources` directory in the MT2.app bundle, 
# or leave them in the current directory if running the app from the terminal

