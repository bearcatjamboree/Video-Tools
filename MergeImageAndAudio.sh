#!/bin/sh
#================================================================================
#  AUTHOR
#    Clint Box
#    https://www.youtube.com/bearcatjamboree
#
#   FUNCTION
#     Merge video and audio
#
#   DETAILS
#     This script will invoke ffmpeg with parameters required to take an input
#     video file and input audio file, and merge them together, retaining audio
#     channels from both the video and audio files.
#
#   USAGE
#     ${SCRIPT_NAME} "<input video>" "<input audio>"
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
input_image="$1"
input_audio="$2"

##############################################################################
# Check for file was passed.  Show open file dialog if no argument and on Mac
###############################################################################
if ! [ -f "$input_image" ]; then
    if [[ "$machine" == "Mac" ]]; then
        input_image=$(osascript -e 'tell application (path to frontmost application as text)
        set input_image to choose file with prompt "Please select an image to include:"
        POSIX path of input_image
        end')
    elif [[ "$machine" == "Linux" ]]; then
        input_image=$(dialog --title "Choose a file" --stdout --title "Please select an image to include:" --fselect /tmp/ 14 48)
    elif [[ "$machine" == "Cygwin" ]]; then
        input_image=$(dialog --title "Choose a file" --stdout --title "Please select an image to include:" --fselect /tmp/ 14 48)
    elif [ "$#" -ne 2 ] || ! [ -f "$input_image" ]; then
        echo "Usage: $0 input_image input_audio"
        exit 1
    fi
fi

if ! [ -f "$input_image" ]; then
  echo "Usage: $0 input_image input_audio"
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
        echo "Usage: $0 input_image input_audio"
        exit 1
    fi
fi

if ! [ -f "$input_audio" ]; then
  echo "Usage: $0 input_image input_audio"
  exit 1
fi

####################################
# Remove backlashes from filepaths
####################################
file=$(echo "$input_audio"|tr -d '\\')

####################################
# Separate file name from extension
####################################
ext="${file##*.}"
name="${file%.*}"

############################
# Get file path information
############################
outfile="$name"
output_video=$outfile.mp4

ffmpeg -loop 1 -i "$input_image" -i "$input_audio" -c:v libx264 -tune stillimage -c:a aac -vf "crop=1920:1080:x:y,format=yuv420p" -shortest -movflags +faststart "$output_video"