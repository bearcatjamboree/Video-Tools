#!/bin/zsh
#================================================================================
#  AUTHOR
#    Clint Box
#    https://www.youtube.com/bearcatjamboree
#
#   FUNCTION
#     Merge subtitled video files with translated wav files
#
#   DETAILS
#     This script will scan recursively for *_novocals_subtitled.mp4 files
#     and attempt to locate a .wav file in the same directory.  If a _merged.mp4
#     file already exist then the script will skip the file and go on to the next
#     *_novocals_subtitled.mp4 file.
#
#   USAGE
#     ${SCRIPT_NAME} "[path to *_novocals_subtitled.mp4]"
#================================================================================
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

for input_image in $(find $input_folder -name '*.jpg'); do

    echo "input video: ${input_image}"

    folder_path="${input_image%/*}"
    #echo "folder path: $folder_path"

    input_audio=$(find "${folder_path}" -name '*.mp3')
    echo "input audio: ${input_audio}"

    if ! [[ $input_audio == "" ]]; then

        #echo "$input_audio"

        # Construct output file name
        output_video="${input_audio%.*}.mp4"
        echo "output video $output_video"
        #exit 1

        if ! [ -f "$output_video" ]; then
            ffmpeg -loop 1 -i "$input_image" -i "$input_audio" -c:v libx264 -tune stillimage -c:a aac -vf "crop=1920:1080:x:y,format=yuv420p" -shortest -movflags +faststart "$output_video"
        else
            echo "Skipping $input_image"
        fi

    fi

done