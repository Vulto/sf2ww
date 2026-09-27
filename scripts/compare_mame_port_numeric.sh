#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 2 ]; then
    echo "usage: $0 <mame_exec_numeric.csv> <port_state.csv>" >&2
    exit 2
fi

mame="$1"
port="$2"
tmp="${TMPDIR:-/tmp}/sf2ww-numeric"
rm -rf "$tmp"
mkdir -p "$tmp"
trap 'rm -rf "$tmp"' EXIT

common='arcade_time_ns,arcade_cpu_cycles,p1_x,p1_y,p1_mode0,p1_mode1,p1_mode2,p1_anim,p1_energy,p1_move,p1_stand_squat,p2_x,p2_y,p2_mode0,p2_mode1,p2_mode2,p2_anim,p2_energy,p2_move,p2_stand_squat,stage,round_cnt,fight_over,rng1,rng2'

awk -F, -v header="$common" '
NR==1 {
    for(i=1;i<=NF;i++) col[$i]=i
    n=split(header,h,",")
    printf "%s\n", header > out
    next
}
{
    for(i=1;i<=n;i++) {
        if(!(h[i] in col)) exit 20
        printf "%s%s", (i==1 ? "" : ","), $(col[h[i]]) > out
    }
    printf "\n" > out
}
' out="$tmp/mame.csv" "$mame"

awk -F, -v header="$common" '
NR==1 {
    for(i=1;i<=NF;i++) col[$i]=i
    n=split(header,h,",")
    printf "seq,%s\n", header > out
    next
}
{
    seq++
    printf "%d", seq > out
    for(i=1;i<=n;i++) {
        if(!(h[i] in col)) exit 20
        printf ",%s", $(col[h[i]]) > out
    }
    printf "\n" > out
}
' out="$tmp/port.csv" "$port"

bash scripts/compare_state_csv.sh "$tmp/mame.csv" "$tmp/port.csv"
