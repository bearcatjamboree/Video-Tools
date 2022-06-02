#!/bin/zsh

unameOut="$(uname -s)"
case "${unameOut}" in
    Linux*)     machine=Linux;;
    Darwin*)    machine=Mac;;
    CYGWIN*)    machine=Cygwin;;
    MINGW*)     machine=MinGw;;
    *)          machine="UNKNOWN:${unameOut}"
esac

echo "${machine}"
input_folder="$1"

##############################################################################
#  Prompt for input folder
###############################################################################
if ! [ -d "$input_folder" ]; then
    if [[ "$machine" == "Mac" ]]; then
        input_folder=$(osascript -e 'tell application (path to frontmost application as text)
        set input_folder to choose folder with prompt "Please choose an input folder"
        POSIX path of input_folder
        end')
    elif [[ "$machine" == "Linux" ]]; then
        input_folder=$(dialog --title "Choose a folder" --stdout --title "Please choose an input folder" --fselect ~/ 14 48)
    elif [[ "$machine" == "Cygwin" ]]; then
        input_folder=$(dialog --title "Choose a folder" --stdout --title "Please choose an input folder" --fselect ~/ 14 48)
    else
        echo "Usage: $0 input_file input_folder format"
        exit 1
    fi
fi

if ! [ -d "$input_folder" ]; then
  echo "Usage: $0 input_folder"
  exit 1
fi

# Remove trailing slash for folder_path
input_folder="${input_folder%/}"

###################################
#  Process each input folder file
###################################
IFS=$'\n'

for input_video in $(find $input_folder -name '*_novocals_subtitled.mp4'); do

    echo "input video: ${input_video}"

    folder_path="${input_video%/*}"
    #echo "folder path: $folder_path"

    input_audio=$(find "${folder_path}" -name '*.wav')
    echo "input audio: ${input_audio}"

    if ! [[ $input_audio == "" ]]; then

        #echo "$input_audio"

        # Construct output file name
        output_video="${input_video%.*}_merged.mp4"
        echo "output video $output_video"

        if ! [ -f "$output_video" ]; then

            ####################################
            # Make temp directory
            ####################################
            tmp_dir=$(mktemp -d -t ci-$(date +%Y-%m-%d-%H-%M-%S)-XXXXXXXXXX)

            ffmpeg -i "$input_video" -c:a copy -c:v libx264 -an "$tmp_dir/video.mp4" -vn "$tmp_dir/audio.mp3"
            ffmpeg -i "$tmp_dir/audio.mp3" -i "$input_audio" -filter_complex amerge -c:a libmp3lame -q:a 4 "$tmp_dir/audiofinal.mp3"
            ffmpeg -i "$tmp_dir/video.mp4" -i "$tmp_dir/audiofinal.mp3" "$output_video"

            rm -rf $tmp_dir

        else
            echo "Skipping $input_video"
        fi

    fi

done