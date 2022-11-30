#!/bin/env bash

set -e

base=$(cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P)/../
uuid=$(date '+%s')
vox_file=/tmp/${uuid}_vox.mp3
voice_file=/tmp/${uuid}_voice.mp3
voice_for_vid_gen_file=/tmp/${uuid}_voice_fvg.mp3
base_voice_fragment_file=/tmp/${uuid}_voice
music_file=/tmp/${uuid}_music.mp3
music_tmp_file=/tmp/${uuid}_music_tmp.mp3
beta_file=/tmp/${uuid}_beta.mp3
gamma_file=/tmp/${uuid}_gamma.mp4
gamma_final_file=/tmp/${uuid}_gamma_final.mp4
gameplay_file=/tmp/${uuid}_gameplay.mp4
gameplay_cut_file=/tmp/${uuid}_gameplay_cut.mp4
final_video=/tmp/${uuid}_final_video.mp4
final_tmp_video=/tmp/${uuid}_final_tmp_video.mp4
ffmpeg_subtitle=/tmp/${uuid}_subtitle.ffmpeg

script="$1"

# Generate voiceover.
ls $base/assets/flitevox |sort -R |tail -1 |while read vox; do
    echo $base/assets/flitevox/$vox > $vox_file
done
voice_vox=$(cat $vox_file)
echo "[Info] Using voice (vox) $voice_vox."
IFS='.' read -ra ADDR <<< "$1"
i=0
previous_fragment_end_time=0
for line in "${ADDR[@]}"; do
    line=$(echo $line | xargs -0)
    output=${base_voice_fragment_file}_$i.mp3

    echo "[Info] Generating line $line."
    flite -voice $voice_vox -t "$line" -o $output
    fragment_length=$(ffprobe -i $output -show_entries format=duration -v quiet -of csv="p=0")
    fragment_start=$previous_fragment_end_time
    fragment_end=$(echo "$previous_fragment_end_time + $fragment_length" | bc | awk '{printf "%f", $0}')
    previous_fragment_end_time=$fragment_end

    num_characters=$(echo -n "$line" | wc -c)
    if (( num_characters < 50 )); then
        echo "[in]drawtext=fontfile=$base/assets/fonts/roboto/Roboto-Regular.ttf:text='$line.':fontcolor=white:fontsize=52:x=(w-text_w)/2:y=(h-text_h)/2:enable='between(t,$fragment_start,$fragment_end)'[out]" >> $ffmpeg_subtitle
    else
        echo -n "[in]" >> $ffmpeg_subtitle

        IFS=' ' read -ra words <<< "$line"
        num_words=${#words[@]}
        num_sub_lines=$(((num_words+4)/5))
        current_sub_line=0
        for i in $(seq $num_sub_lines); do
            text=${words[@]:$((current_sub_line*5)):5}
            echo -e "\tFrom $((current_sub_line*5)):5"
            echo -e "\t$text"

            if (( i != num_sub_lines )); then
                echo -n "drawtext=fontfile=$base/assets/fonts/roboto/Roboto-Regular.ttf:text='$text':fontcolor=white:fontsize=52:x=(w-text_w)/2:y=(h-text_h)/2+$((current_sub_line*75)):enable='between(t,$fragment_start,$fragment_end)'" >> $ffmpeg_subtitle
                echo -n "," >> $ffmpeg_subtitle
            else
                echo -n "drawtext=fontfile=$base/assets/fonts/roboto/Roboto-Regular.ttf:text='$text.':fontcolor=white:fontsize=52:x=(w-text_w)/2:y=(h-text_h)/2+$((current_sub_line*75)):enable='between(t,$fragment_start,$fragment_end)'" >> $ffmpeg_subtitle
            fi

            current_sub_line=$((current_sub_line+1))
        done

        echo [out] >> $ffmpeg_subtitle
    fi

    i=$((i+1))
done

# This is a fucking mess.
echo "[Info] Combining voiceover fragments."
ffmpeg_concat_inputs=$(find ${base_voice_fragment_file}* | awk '{ for (i=1;i<=NF;i++) { printf " -i "; printf $i } }')
ffmpeg_num_inputs=$(find ${base_voice_fragment_file}* | wc -l)
ffmpeg_filter_complex_prefix=$(echo $ffmpeg_num_inputs | awk '{ for(i=0;i<$1;i++) { printf "["; printf i; printf ":0]" } }')
ffmpeg -y -loglevel error -stats \
    $ffmpeg_concat_inputs \
    -filter_complex ${ffmpeg_filter_complex_prefix}concat=n=$ffmpeg_num_inputs:v=0:a=1[out] \
    -map '[out]' \
    $voice_file
echo "[Info] Regenerating full voiceover."
flite -voice $voice_vox -t "$1" -o $voice_for_vid_gen_file

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
echo "[Info] Cutting down music length."
ffmpeg -y -loglevel error -stats -ss 0 \
    -i $music_file -t $(($voiceover_length + 1)) -c copy $music_tmp_file

# Generate beta audio.
echo "[Info] Reducing music volume levels."
ffmpeg -y -loglevel error -stats \
    -i $music_tmp_file -filter:a "volume=0.05" $music_file
echo "[Info] Combining voiceover and music."
ffmpeg -y -loglevel error -stats \
    -i $voice_file -i $music_file -filter_complex amix=inputs=2:duration=longest $beta_file

# Generate background video of audio.
echo "[Info] Generating waveform video."
ffmpeg -y -loglevel error -stats \
    -i $beta_file -filter_complex \
    "[0:a]avectorscope=s=1080x1920:scale=cbrt:draw=line:rc=0:gc=200:bc=0:rf=0:gf=40:bf=0,format=yuv420p [out]" \
    -map "[out]" -map 0:a \
    -b:v 700k -b:a 360k $gamma_file
echo "[Info] Resizing waveform video."
ffmpeg -y -loglevel error -stats \
    -i $gamma_file -vf scale=1080:1920 -preset slow -crf 18 $gamma_final_file

# Get gameplay video.
ls $base/assets/gameplay/*.mp4 |sort -R |tail -1 |while read gameplay_video_path; do
    cp $gameplay_video_path $gameplay_file
done

echo "[Info] Cutting down gameplay length."
ffmpeg -y -loglevel error -stats -ss 0 -i $gameplay_file -t $(($voiceover_length + 1)) -c copy $gameplay_cut_file

echo "[Info] Rendering final video."
ffmpeg -y -loglevel error -stats \
    -i $gamma_final_file -i $gameplay_cut_file -filter_complex " \
        [0:v]setpts=PTS-STARTPTS, scale=1080x1920[top]; \
        [1:v]setpts=PTS-STARTPTS, scale=1080x1920, \
             format=yuva420p,colorchannelmixer=aa=0.25[bottom]; \
        [top][bottom]overlay=shortest=1" \
    $final_video

echo "[Info] Mapping final video audio."
ffmpeg -y -loglevel error -stats \
    -i $final_video -i $beta_file -c:v copy -map 0:v:0 -map 1:a:0 $final_tmp_video

echo "[Info] Setting final video volume."
ffmpeg -y -loglevel error -stats \
    -i $final_tmp_video -filter:a "volume=5.0" $final_video

# This can just go in the video description.
# echo "[Info] Drawing disclaimer on final video."
# ffmpeg -y -loglevel error -stats \
#     -i $final_video -vf \
#     "drawtext=fontfile=$base/assets/fonts/roboto/Roboto-Regular.ttf:text='This is computer generated.':fontcolor=white:fontsize=32:box=1:boxcolor=black@0.5:boxborderw=5:x=(w-text_w)/2:y=h-text_h-200" \
#     -codec:a copy $final_tmp_video

echo "[Info] Drawing subtitles."
num_subtitles=$(cat $ffmpeg_subtitle | wc -l)
for i in $(seq $num_subtitles)
do
    ffmpeg_command=$(cat $ffmpeg_subtitle | head -$i | tail -1)
    echo "FOO: $ffmpeg_command"
    ffmpeg -y -loglevel error -stats \
        -i $final_tmp_video -vf \
        "$ffmpeg_command" \
        -codec:a copy $final_video

    cp $final_video $final_tmp_video
done

echo "[Info] Final video rendered to ./$(basename $final_tmp_video)."

# Done.
cp $final_tmp_video final.mp4

# Cleaning up
rm /tmp/${uuid}*
