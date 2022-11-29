#!/bin/env bash

set -e

base=$(cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P)/../
uuid=$(date '+%s')
voice_file=/tmp/${uuid}_voice.mp3
music_file=/tmp/${uuid}_music.mp3
music_final_file=/tmp/${uuid}_music_final.mp3
beta_file=/tmp/${uuid}_beta.mp3
gamma_file=/tmp/${uuid}_gamma.mp4

# Generate voiceover.
# BEST VOICES: BDL, CLB, FEM, SLT
voice_vox="$base/assets/flitevox/cmu_us_fem.flitevox"
flite -voice $voice -t "$1" -o $voice_file

# Get random music file.
ls $base/assets/background |sort -R |tail -$N |while read music_file_prime; do
    cp $base/assets/background/$music_file_prime $music_file
done

# Generate beta audio.
ffmpeg -i $music_file -filter:a "volume=0.1" $music_final_file
ffmpeg -i $voice_file -i $music_final_file -filter_complex amix=inputs=2:duration=longest $beta_file

# Generate background video.
ffmpeg -i $beta_file -filter_complex showspectrum=mode=separate:color=intensity:slide=1:scale=cbrt -y -acodec copy $gamma_file

# Done.
cp $gamma_file .

# Cleaning up
rm /tmp/${uuid}*.mp3

