#!/usr/bin/env python3
import argparse
from pathlib import Path
from PIL import Image, ImageChops, ImageStat

def metric(a, b):
    d = ImageChops.difference(a, b)
    stat = ImageStat.Stat(d)
    mae = sum(stat.mean) / 3.0
    w, h = a.size
    changed = 0
    for y in range(h):
        for x in range(w):
            if max(d.getpixel((x, y))) > 8:
                changed += 1
    return mae, changed / (w * h)

ap = argparse.ArgumentParser()
ap.add_argument("--mame-dir", required=True)
ap.add_argument("--native-dir", required=True)
args = ap.parse_args()

# These are both before the first attract-mode fight, where the two engines
# are visually in the same title-screen phases. They form a renderer
# regression anchor independent of the later attract timing offset.
anchors = {300: (3.0, 0.05), 1500: (6.0, 0.10)}
for frame, (max_mae, max_ratio) in anchors.items():
    mp = Path(args.mame_dir) / f"frame_{frame:06d}.png"
    np = Path(args.native_dir) / f"frame_{frame:06d}.ppm"
    if not mp.exists() or not np.exists():
        raise SystemExit(f"missing visual anchor frame={frame}")
    with Image.open(mp) as m, Image.open(np) as n:
        m, n = m.convert("RGB"), n.convert("RGB")
        mae, ratio = metric(m, n)
    print(f"VISUAL_ANCHOR frame={frame} mae={mae:.3f} ratio={ratio:.6f}")
    if mae > max_mae or ratio > max_ratio:
        raise SystemExit(f"VISUAL_ANCHOR_DIVERGENCE frame={frame} mae={mae:.3f} ratio={ratio:.6f}")
print("VISUAL_ANCHORS_OK")
