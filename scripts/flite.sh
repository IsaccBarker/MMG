#!/bin/env bash

set -e

# BEST VOICES: BDL, CLB, FEM, SLT
VOICE="$(cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P)/flitevox/cmu_us_fem.flitevox"
OUT=/tmp/$(date '+%s').mp3

flite -voice $VOICE -t "$1" -o $OUT
echo "$OUT"

# for vox in $(find ~/Downloads/*.flitevox);
# do
#     flite -voice "$vox" "The quick brown fox jumps over the lazy dog." text_$(basename $vox).wav
# done
