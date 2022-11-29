#!/bin/env bash

set -e

base=$(cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P)/../
uuid=$(date '+%s')
voice_file=/tmp/${uuid}_voice.mp3
music_file=/tmp/${uuid}_music.mp3
music_cut_file=/tmp/${uuid}_music_cut.mp3
music_final_file=/tmp/${uuid}_music_final.mp3
beta_file=/tmp/${uuid}_beta.mp3
gamma_file=/tmp/${uuid}_gamma.mp4
gamma_final_file=/tmp/${uuid}_gamma_final.mp4
gameplay_file=/tmp/${uuid}_gameplay.mp4
gameplay_cut_file=/tmp/${uuid}_gameplay_cut.mp4
final_video=/tmp/${uuid}_final_video.mp4
final_final_video=/tmp/${uuid}_final_final_video.mp4

script="$1"

# Generate voiceover.
voice_vox=""
ls $base/assets/flitevox |sort -R |tail -1 |while read vox; do
    voice_vox=$vox
    echo "[Info] Using voice (vox) $vox."
done
flite -voice $voice -t "$1" -o $voice_file
voiceover_length=$(ffprobe -i $voice_file -show_entries format=duration -v quiet -of csv="p=0")
voiceover_length=$(basename $voiceover_length | cut -d"." -f1)
voiceover_length=$(($voiceover_length + 1))

if [ "$voiceover_length" -gt "60" ]; then
    echo "[Error] Voiceover exceeds 60 seconds (at $voiceover_length)."
    exit 1
fi

echo "[Info] Voiceover set at $voiceover_length seconds."

# Get random music file.
ls $base/assets/background |sort -R |tail -1 |while read music_file_prime; do
    cp $base/assets/background/$music_file_prime $music_file
done

# Cut down music file.
echo "Cutting down music length."
ffmpeg -loglevel error -stats -ss 0 -i $music_file -t $(($voiceover_length + 1)) -c copy $music_cut_file

# Generate beta audio.
echo "Reducing music volume levels."
ffmpeg -loglevel error -stats -i $music_cut_file -filter:a "volume=0.05" $music_final_file
echo "Combining voiceover and music."
ffmpeg -loglevel error -stats -i $voice_file -i $music_final_file -filter_complex amix=inputs=2:duration=longest $beta_file

# Generate background video of audio.
echo "Generating waveform video."
ffmpeg -loglevel error -stats \
    -i $beta_file -filter_complex \
    "[0:a]avectorscope=s=1080x1920:scale=cbrt:draw=line:rc=0:gc=200:bc=0:rf=0:gf=40:bf=0,format=yuv420p [out]" \
    -map "[out]" -map 0:a \
    -b:v 700k -b:a 360k $gamma_file
echo "Resizing waveform video."
ffmpeg -loglevel error -stats -i $gamma_file -vf scale=1080:1920 -preset slow -crf 18 $gamma_final_file

# Get gameplay video.
ls $base/assets/gameplay/*.mp4 |sort -R |tail -1 |while read gameplay_video_path; do
    cp $gameplay_video_path $gameplay_file
done

echo "Cutting down gameplay length."
ffmpeg -loglevel error -stats -ss 0 -i $gameplay_file -t $(($voiceover_length + 1)) -c copy $gameplay_cut_file

echo "Rendering final video."
ffmpeg -loglevel error -stats \
    -i $gamma_final_file -i $gameplay_cut_file -filter_complex " \
        [0:v]setpts=PTS-STARTPTS, scale=1080x1920[top]; \
        [1:v]setpts=PTS-STARTPTS, scale=1080x1920, \
             format=yuva420p,colorchannelmixer=aa=0.25[bottom]; \
        [top][bottom]overlay=shortest=1" \
    $final_video

ffmpeg -loglevel error -stats \
    -i $final_video -i $beta_file -c:v copy -map 0:v:0 -map 1:a:0 $final_final_video

echo "[Info] Final video rendered to $final_final_video."

# Done.
cp $final_final_video .

# Cleaning up
rm /tmp/${uuid}*.mp3
rm /tmp/${uuid}*.mp4

