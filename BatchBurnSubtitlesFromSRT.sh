#!/bin/zsh
#================================================================================
#  AUTHOR
#    Clint Box
#    https://www.youtube.com/bearcatjamboree
#
#   FUNCTION
#     Burn subtitles from SRT files to videos found in a specified path
#
#   DETAILS
#     This script will scan recursively for .SRT files and try
#     to match them with an mp4 file located in the same
#     directory.  If no video with the *.mp4 mask can
#     be located then the script goes onto the next .SRT file.
#     If a video is located but there is already a subtitled video
#     Then the script to skip this file and go on to the next .SRT file.
#
#   USAGE
#     ${SCRIPT_NAME} [path to *.srt and *.mp4 files]"
#
#   NOTE
#     change strings below to your default: font, font size, and font color
#================================================================================
subtitle_font="Bangers"
subtitle_fontsize=48 #24 or 48
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

    video_file=$(find "${srt_test_path}" -name '*.mp4' ! -name '.*')
    echo "in file: ${video_file}"

    if ! [[ $video_file == "" ]]; then

        #echo "$video_file"

        filename=$(echo "$video_file" | sed 's/\(.*\)\..*/\1/g')
        #echo "file: $filename"

        # Construct output file name
        output_video="${filename}_subtitled.mp4"
        echo "out file: $output_video"

        if ! [ -f "$output_video" ]; then
            echo ffmpeg -i "$video_file" -vf "subtitles=\'$srt_file\':force_style='FontName=$subtitle_font,Fontsize=$subtitle_fontsize,PrimaryColour=&H$subtitle_fontcolor&'" "$output_video"
            ffmpeg -i "$video_file" -vf "subtitles=\'$srt_file\':force_style='FontName=$subtitle_font,Fontsize=$subtitle_fontsize,PrimaryColour=&H$subtitle_fontcolor&'" "$output_video"
        else
            echo "Skipping $output_file"
        fi

    fi

done