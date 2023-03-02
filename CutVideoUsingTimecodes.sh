#!/bin/sh
#================================================================================
#  AUTHOR
#    Clint Box
#    https://www.youtube.com/bearcatjamboree
#
#   FUNCTION
#     Cut out video frames using time codes
#
#   DETAILS
#     This script will create a frame list using time codes and extract only those
#     frames from the provided video file
#
#   USAGE
#     ${SCRIPT_NAME} "input_file" "srt_file"
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
input_file="$1"
srt_file="$2"

##############################################################################
# Check for file was passed.  Show open file dialog if no argument and on Mac
###############################################################################
if ! [ -f "$input_file" ]; then
    if [[ "$machine" == "Mac" ]]; then
        input_file=$(osascript -e 'tell application (path to frontmost application as text)
        set input_file to choose file with prompt "Please choose a video file to process"
        POSIX path of input_file
        end')
    elif [[ "$machine" == "Linux" ]]; then
        input_file=$(dialog --title "Choose a file" --stdout --title "Please choose a video file to process" --fselect ~/ 14 48)
    elif [[ "$machine" == "Cygwin" ]]; then
        input_file=$(dialog --title "Choose a file" --stdout --title "Please choose a video file to process" --fselect ~/ 14 48)
    elif [ "$#" -ne 1 ] || ! [ -f "$input_file" ]; then
        echo "Usage: $0 input_file"
        exit 1
    fi
fi

if ! [ -f "$input_file" ]; then
  echo "Usage: $0 input_file srt_file"
  exit 1
fi

##############################################################################
# Check for file was passed.  Show open file dialog if no argument and on Mac
###############################################################################
if ! [ -f "$srt_file" ]; then
    if [[ "$machine" == "Mac" ]]; then
        srt_file=$(osascript -e 'tell application (path to frontmost application as text)
        set srt_file to choose file with prompt "Please choose an SRT file to process"
        POSIX path of srt_file
        end')
    elif [[ "$machine" == "Linux" ]]; then
        srt_file=$(dialog --title "Choose a file" --stdout --title "Please choose an SRT file to process" --fselect ~/ 14 48)
    elif [[ "$machine" == "Cygwin" ]]; then
        srt_file=$(dialog --title "Choose a file" --stdout --title "Please choose an SRT file to process" --fselect ~/ 14 48)
    elif [ "$#" -ne 1 ] || ! [ -f "$srt_file" ]; then
        echo "Usage: $0 srt_file"
        exit 1
    fi
fi

if ! [ -f "$srt_file" ]; then
  echo "Usage: $0 input_file srt_file"
  exit 1
fi

####################################
# Remove backlashes from filepaths
####################################
file=$(echo "$input_file"|tr -d '\\')

####################################
# Separate file name from extension
####################################
ext="${file##*.}"
name="${file%.*}"

############################
# Get file path information
############################
outfile="$name"_timecut
newoutfile=$outfile.$ext

frame_rate=$(ffmpeg -i "$input_file" 2>&1 | sed -n "s/.*, \(.*\) fp.*/\1/p")

python CutVideoUsingTimecodes.py --frame_rate "$frame_rate" --input_file "$input_file" --srt_file "$srt_file"  --output_file "$newoutfile"