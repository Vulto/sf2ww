#!/bin/sh
set -eu
# How to merge the sf2ua romset for use with the SF2 rewrite
#
# The source ROMs are copyrighted and are intentionally not stored in this
# repository. Supply a legally obtained sf2ua set in the current directory.
#
# The sf2ua set is distributed with two common filename variants for the
# program ROMs. Accept both variants so the merge step matches MAME's set.

command -v interleave >/dev/null 2>&1 || {
    echo "error: interleave is required and must be in PATH" >&2
    exit 1
}

pick() {
    for name in "$@"; do
        if [ -f "$name" ]; then
            printf '%s\n' "$name"
            return 0
        fi
    done
    echo "error: none of the required ROM files exists: $*" >&2
    exit 1
}

P30=$(pick sf2u.30a sf2u_30a.11e)
P37=$(pick sf2u.37a sf2u_37a.11f)
P31=$(pick sf2u.31a sf2u_31a.12e)
P38=$(pick sf2u.38a sf2u_38a.12f)
P28=$(pick sf2u.28a sf2u_28a.9e)
P35=$(pick sf2u.35a sf2u_35a.9f)
P29=$(pick sf2_29a.bin sf2_29b.10e)
P36=$(pick sf2_36a.bin sf2_36b.10f)

interleave int1 1 "$P30" "$P37"
interleave int2 1 "$P31" "$P38"
interleave int3 1 "$P28" "$P35"
interleave int4 1 "$P29" "$P36"
cat int1 int2 int3 int4 > allroms.bin
echo "4256ec60bf9eec21f4d6bb34c38990a9401af82e - expected shasum"
shasum allroms.bin

interleave gint1 2 sf2-5m.4a sf2-7m.6a sf2-1m.3a sf2-3m.5a
interleave gint2 2 sf2-6m.4c sf2-8m.6c sf2-2m.3c sf2-4m.5c
interleave gint3 2 sf2-13m.4d sf2-15m.6d sf2-9m.3d sf2-11m.5d

cat gint1 gint2 gint3 > sf2gfx.bin
echo "db52a6314b4c0cd4c48eb324720c83dd142c3bff - expected shasum"
shasum sf2gfx.bin

# Copy both generated files into the working directory used to launch the
# native executable, or into the Resources directory of the MT2.app bundle.
