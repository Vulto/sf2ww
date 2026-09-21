#!/usr/bin/env python3
"""Interleave equal-sized binary ROMs by a byte or word stride.

Mode 1 interleaves one byte from each input.
Mode 2 interleaves one 16-bit word (two bytes) from each input.
"""
import argparse
from pathlib import Path


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("mode", type=int, choices=(1, 2))
    parser.add_argument("output", type=Path)
    parser.add_argument("inputs", nargs="+", type=Path)
    args = parser.parse_args()

    if len(args.inputs) < 2:
        parser.error("at least two input files are required")

    chunk = args.mode
    data = [p.read_bytes() for p in args.inputs]
    size = len(data[0])
    if any(len(d) != size for d in data):
        parser.error("all input files must have equal sizes")
    if size % chunk:
        parser.error("input size must be divisible by the interleave mode")

    out = bytearray()
    for offset in range(0, size, chunk):
        for d in data:
            out.extend(d[offset:offset + chunk])
    args.output.write_bytes(out)


if __name__ == "__main__":
    main()
