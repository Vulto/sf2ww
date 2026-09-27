#!/usr/bin/env python3
"""Build deterministic diagnostic evidence from the existing MAME/native oracle."""
from __future__ import annotations
import csv, json, pathlib, sys

COMMON = [
    "arcade_time_ns", "arcade_cpu_cycles",
    "p1_x", "p1_y", "p1_mode0", "p1_mode1", "p1_mode2", "p1_anim",
    "p1_energy", "p1_move", "p1_stand_squat",
    "p2_x", "p2_y", "p2_mode0", "p2_mode1", "p2_mode2", "p2_anim",
    "p2_energy", "p2_move", "p2_stand_squat",
    "stage", "round_cnt", "fight_over", "rng1", "rng2",
]
SEMANTIC = [x for x in COMMON if x not in {"arcade_time_ns", "arcade_cpu_cycles"}]

def read_csv(path):
    with path.open(newline="") as fh:
        rows = list(csv.DictReader(fh))
    if not rows:
        raise ValueError("empty CSV: " + str(path))
    missing = [f for f in COMMON if f not in rows[0]]
    if missing:
        raise ValueError(str(path) + ": missing fields: " + ", ".join(missing))
    return rows

def norm(field, value, source):
    if field in {"p1_y", "p2_y"} and source == "mame":
        return str(int(value) << 16)
    return value

def key(row, source):
    return tuple(norm(f, row[f], source) for f in SEMANTIC)

def transitions(rows, source):
    out, last = [], None
    for row in rows:
        k = key(row, source)
        if k != last:
            out.append(row)
            last = k
    return out

def compact(row):
    if row is None:
        return None
    fields = ["arcade_time_ns", "arcade_cpu_cycles", "pc", "sr"] + SEMANTIC
    return {f: row.get(f, "") for f in fields}

def main():
    if len(sys.argv) != 4:
        print("usage: build_oracle_diagnostic.py <mame.csv> <port.csv> <output.md>", file=sys.stderr)
        return 2
    mame_path, port_path, out_path = map(pathlib.Path, sys.argv[1:])
    result = {
        "oracle": "deterministic-semantic",
        "mame_rows": 0, "port_rows": 0,
        "mame_transitions": 0, "port_transitions": 0,
        "semantic_match": False, "timing_match": False,
    }
    try:
        mame, port = read_csv(mame_path), read_csv(port_path)
        mt, pt = transitions(mame, "mame"), transitions(port, "port")
        result.update(mame_rows=len(mame), port_rows=len(port),
                      mame_transitions=len(mt), port_transitions=len(pt))
        limit = min(len(mt), len(pt))
        for i in range(limit):
            mk, pk = key(mt[i], "mame"), key(pt[i], "port")
            if mk != pk:
                fields = {}
                for f in SEMANTIC:
                    mv, pv = norm(f, mt[i][f], "mame"), norm(f, pt[i][f], "port")
                    if mv != pv:
                        fields[f] = {"mame": mv, "port": pv}
                result["semantic_diff"] = {
                    "transition": i, "fields": fields,
                    "mame_row": compact(mt[i]), "port_row": compact(pt[i]),
                }
                break
        else:
            if len(mt) != len(pt):
                result["semantic_diff"] = {
                    "transition": limit,
                    "fields": {"transition_count": {"mame": str(len(mt)), "port": str(len(pt))}},
                    "mame_row": compact(mt[limit] if limit < len(mt) else None),
                    "port_row": compact(pt[limit] if limit < len(pt) else None),
                }
            else:
                result["semantic_match"] = True

        if result["semantic_match"]:
            for i, (mr, pr) in enumerate(zip(mt, pt)):
                for f in ("arcade_time_ns", "arcade_cpu_cycles"):
                    if mr[f] != pr[f]:
                        result["timing_diff"] = {
                            "transition": i, "field": f, "mame": mr[f],
                            "port": pr[f], "delta": int(pr[f]) - int(mr[f]),
                        }
                        break
                if "timing_diff" in result:
                    break
            else:
                result["timing_match"] = True
    except Exception as exc:
        result["collection_error"] = str(exc)

    lines = [
        "# Oracle diagnostic", "",
        "Diagnostic evidence from the existing deterministic oracle. "
        "This script does not change acceptance criteria or tolerances.", "",
        "## Collection", "",
        "- MAME rows: " + str(result["mame_rows"]),
        "- Native rows: " + str(result["port_rows"]),
        "- MAME semantic transitions: " + str(result["mame_transitions"]),
        "- Native semantic transitions: " + str(result["port_transitions"]), "",
    ]
    if "collection_error" in result:
        lines += ["## Collection error", "", result["collection_error"], ""]
    elif "semantic_diff" in result:
        d = result["semantic_diff"]
        lines += ["## First semantic divergence", "", "Transition: " + str(d["transition"]), "",
                  "| Field | MAME | Native |", "|---|---:|---:|"]
        for f, v in d["fields"].items():
            lines.append("| " + f + " | " + v["mame"] + " | " + v["port"] + " |")
        lines += ["", "MAME checkpoint:", "", "JSON:",
                  json.dumps(d["mame_row"], indent=2), "",
                  "Native checkpoint:", "", "JSON:",
                  json.dumps(d["port_row"], indent=2), ""]
    elif result["semantic_match"] and "timing_diff" in result:
        d = result["timing_diff"]
        lines += ["## First timing divergence", "", "Transition: " + str(d["transition"]),
                  "Field: " + d["field"], "MAME: " + d["mame"], "Native: " + d["port"],
                  "Native minus MAME: " + str(d["delta"]), ""]
    elif result.get("semantic_match") and result.get("timing_match"):
        lines += ["## Result", "", "SEMANTIC_AND_TIMING_MATCH", ""]
    lines += ["## Machine-readable result", "", json.dumps(result, indent=2, sort_keys=True), ""]
    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_text("\n".join(lines), encoding="utf-8")
    print(json.dumps(result, sort_keys=True))
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
