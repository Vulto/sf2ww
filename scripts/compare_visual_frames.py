#!/usr/bin/env python3
import argparse
import csv
import glob
import os
import statistics
from pathlib import Path

from PIL import Image, ImageChops, ImageStat


def load_native(path):
    with Image.open(path) as im:
        return im.convert("RGB")


def load_mame(path):
    with Image.open(path) as im:
        return im.convert("RGB")


def metrics(a, b):
    if a.size != b.size:
        raise ValueError(f"size mismatch: {a.size} vs {b.size}")
    diff = ImageChops.difference(a, b)
    stat = ImageStat.Stat(diff)
    # Per-channel mean absolute error.
    mae = sum(stat.mean) / 3.0
    hist = diff.histogram()
    # Histogram is concatenated RGB channels. Count pixels with any channel > 8.
    width, height = a.size
    differing = 0
    for y in range(height):
        for x in range(width):
            r, g, bl = diff.getpixel((x, y))
            if max(r, g, bl) > 8:
                differing += 1
    total = width * height
    return mae, differing, differing / total


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--mame-dir", required=True)
    ap.add_argument("--native-dir", required=True)
    ap.add_argument("--out", required=True)
    args = ap.parse_args()

    mame = {Path(p).stem: p for p in glob.glob(os.path.join(args.mame_dir, "frame_*.png"))}
    native = {Path(p).stem: p for p in glob.glob(os.path.join(args.native_dir, "frame_*.ppm"))}
    common = sorted(set(mame) & set(native))

    if not common:
        raise SystemExit("no common visual frames")

    rows = []
    for key in common:
        a = load_mame(mame[key])
        b = load_native(native[key])
        mae, pixels, ratio = metrics(a, b)
        rows.append((key, mae, pixels, ratio))

    with open(args.out, "w", newline="") as f:
        w = csv.writer(f)
        w.writerow(["frame", "mean_abs_error", "pixels_diff_gt8", "pixel_diff_ratio"])
        w.writerows(rows)

    divergent = [r for r in rows if r[3] > 0.005]
    mae_values = [r[1] for r in rows]
    ratios = [r[3] for r in rows]
    print(f"VISUAL_FRAMES={len(rows)}")
    print(f"VISUAL_DIVERGENT_FRAMES={len(divergent)}")
    print(f"VISUAL_MAX_MAE={max(mae_values):.3f}")
    print(f"VISUAL_MEAN_MAE={statistics.mean(mae_values):.3f}")
    print(f"VISUAL_MAX_PIXEL_DIFF_RATIO={max(ratios):.6f}")
    if divergent:
        first = divergent[0]
        worst = max(divergent, key=lambda r: r[3])
        print(f"VISUAL_FIRST_DIVERGENCE={first[0]} ratio={first[3]:.6f} mae={first[1]:.3f}")
        print(f"VISUAL_WORST_DIVERGENCE={worst[0]} ratio={worst[3]:.6f} mae={worst[1]:.3f}")
        raise SystemExit(2)


if __name__ == "__main__":
    main()
