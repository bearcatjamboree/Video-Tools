#!/bin/sh

unameOut="$(uname -s)"
case "${unameOut}" in
    Linux*)     machine=Linux;;
    Darwin*)    machine=Mac;;
    CYGWIN*)    machine=Cygwin;;
    MINGW*)     machine=MinGw;;
    *)          machine="UNKNOWN:${unameOut}"
esac

echo "${machine}"
input_video="$1"
input_audio="$2"

##############################################################################
# Check for file was passed.  Show open file dialog if no argument and on Mac
###############################################################################
if ! [ -f "$input_video" ]; then
    if [[ "$machine" == "Mac" ]]; then
        input_video=$(osascript -e 'tell application (path to frontmost application as text)
        set input_video to choose file with prompt "Please select a video to include:"
        POSIX path of input_video
        end')
    elif [[ "$machine" == "Linux" ]]; then
        input_video=$(dialog --title "Choose a file" --stdout --title "Please select a video to include:" --fselect /tmp/ 14 48)
    elif [[ "$machine" == "Cygwin" ]]; then
        input_video=$(dialog --title "Choose a file" --stdout --title "Please select a video to include:" --fselect /tmp/ 14 48)
    elif [ "$#" -ne 2 ] || ! [ -f "$input_video" ]; then
        echo "Usage: $0 input_video input_audio"
        exit 1
    fi
fi

if ! [ -f "$input_video" ]; then
  echo "Usage: $0 input_video input_audio"
  exit 1
fi

##############################################################################
# Check for file was passed.  Show open file dialog if no argument and on Mac
###############################################################################
if ! [ -f "$input_audio" ]; then
    if [[ "$machine" == "Mac" ]]; then
        input_audio=$(osascript -e 'tell application (path to frontmost application as text)
        set input_audio to choose file with prompt "Please select a audio to include:"
        POSIX path of input_audio
        end')
    elif [[ "$machine" == "Linux" ]]; then
        input_audio=$(dialog --title "Choose a file" --stdout --title "Please select a audio to include:" --fselect /tmp/ 14 48)
    elif [[ "$machine" == "Cygwin" ]]; then
        input_audio=$(dialog --title "Choose a file" --stdout --title "Please select a audio to include:" --fselect /tmp/ 14 48)
    elif [ "$#" -ne 2 ] || ! [ -f "$input_audio" ]; then
        echo "Usage: $0 input_video input_audio"
        exit 1
    fi
fi

if ! [ -f "$input_audio" ]; then
  echo "Usage: $0 input_video input_audio"
  exit 1
fi

####################################
# Remove backlashes from filepaths
####################################
file=$(echo "$input_video"|tr -d '\\')

####################################
# Separate file name from extension
####################################
ext="${file##*.}"
name="${file%.*}"

############################
# Get file path information
############################
outfile="$name"_merged
output_video=$outfile.$ext

####################################
# Create temp directory
####################################
if [[ ! -e "TEMP" ]]; then
    mkdir TEMP
else
    echo "TEMP already exists but is not a directory" 1>&2
    exit 1
fi

ffmpeg -i "$input_video" -c:a copy -c:v libx264 -an "TEMP/video.mp4" -vn "TEMP/audio.mp3"
ffmpeg -i "TEMP/audio.mp3" -i "$input_audio" -filter_complex amerge -c:a libmp3lame -q:a 4 "TEMP/audiofinal.mp3"
ffmpeg -i "TEMP/video.mp4" -i "TEMP/audiofinal.mp3" "$output_video"

rm -Rf TEMP