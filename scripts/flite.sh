for vox in $(find ~/Downloads/*.flitevox);
do
    flite -voice "$vox" "The quick brown fox jumps over the lazy dog." text_$(basename $vox).wav
done
