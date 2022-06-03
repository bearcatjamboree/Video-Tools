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
# Make temp directory
####################################
tmp_dir=$(mktemp -d -t ci-$(date +%Y-%m-%d-%H-%M-%S)-XXXXXXXXXX)

ffmpeg -i "$input_video" -c:a copy -c:v libx264 -an "$tmp_dir/video.mp4" -vn "$tmp_dir/audio.mp3"
ffmpeg -i "$tmp_dir/audio.mp3" -i "$input_audio" -filter_complex amerge -c:a libmp3lame -q:a 4 "$tmp_dir/audiofinal.mp3"
ffmpeg -i "$tmp_dir/video.mp4" -i "$tmp_dir/audiofinal.mp3" "$output_video"

rm -rf $tmp_dir