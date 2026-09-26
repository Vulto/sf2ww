#!/usr/bin/env bash
set -euo pipefail

ArchivePath="${1:?sf2ua ZIP path is required}"
WorkRoot="$(mktemp -d)"
trap 'rm -rf "$WorkRoot"' EXIT

unzip -q -o "$ArchivePath" -d "$WorkRoot"
(
    cd "$WorkRoot"
    "$OLDPWD/bin/mt2-merge.sh"
)

ExpectedCodeSha1="4256ec60bf9eec21f4d6bb34c38990a9401af82e"
ExpectedGfxSha1="db52a6314b4c0cd4c48eb324720c83dd142c3bff"
ActualCodeSha1="$(sha1sum "$WorkRoot/allroms.bin" | awk '{print $1}')"
ActualGfxSha1="$(sha1sum "$WorkRoot/sf2gfx.bin" | awk '{print $1}')"

if [ "$ActualCodeSha1" != "$ExpectedCodeSha1" ]; then
    echo "SF2UA_CODE_LAYOUT_MISMATCH: expected $ExpectedCodeSha1 got $ActualCodeSha1" >&2
    exit 1
fi
if [ "$ActualGfxSha1" != "$ExpectedGfxSha1" ]; then
    echo "SF2UA_GFX_LAYOUT_MISMATCH: expected $ExpectedGfxSha1 got $ActualGfxSha1" >&2
    exit 1
fi

echo "SF2UA_FIXTURE_VALID: code=$ActualCodeSha1 gfx=$ActualGfxSha1"
