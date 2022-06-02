#!/bin/zsh

subtitle_font="Bangers"
subtitle_fontsize=48 #48
subtitle_fontcolor="ffffff"

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

# Remove trailing slash for srt_test_path
input_folder="${input_folder%/}"

###################################
#  Process each input folder file
###################################
IFS=$'\n'

for srt_file in $(find $input_folder -name '*.srt'); do

    echo "full srt file path: ${srt_file}"

    srt_test_path="${srt_file%/*}"
    echo "srt path: $srt_test_path"

    video_file=$(find "${srt_test_path}" -name '*_novocals.mp4')
    echo "video file: ${video_file}"

    if ! [[ $video_file == "" ]]; then

        echo "$video_file"

        # Construct output file name
        output_video="${video_file%.*}_subtitled.mp4"
        echo "$output_video"

        if ! [ -f "$output_video" ]; then
            echo ffmpeg -i "$video_file" -vf "subtitles=\'$srt_file\':force_style='FontName=$subtitle_font,Fontsize=$subtitle_fontsize,PrimaryColour=&H$subtitle_fontcolor&'" "$output_video"
            ffmpeg -i "$video_file" -vf "subtitles=\'$srt_file\':force_style='FontName=$subtitle_font,Fontsize=$subtitle_fontsize,PrimaryColour=&H$subtitle_fontcolor&'" "$output_video"
        else
            echo "Skipping $output_file"
        fi

    fi

done