#!/bin/sh
#================================================================================
#  AUTHOR
#    Clint Box
#    https://www.youtube.com/bearcatjamboree
#
#   FUNCTION
#     Create video with compressed audio
#
#   DETAILS
#     This script will invoke ffmpeg with parameters required to take an input
#     video and produce a new video with compressed audo.
#
#   USAGE
#     ${SCRIPT_NAME} "video_path" "new bitrate"
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
bitrate="$2"

##############################################################################
# Check for file was passed.  Show open file dialog if no argument and on Mac
###############################################################################
if ! [ -f "$input_file" ]; then
    if [[ "$machine" == "Mac" ]]; then
        input_file=$(osascript -e 'tell application (path to frontmost application as text)
        set input_file to choose file with prompt "Please choose a file to process"
        POSIX path of input_file
        end')
    elif [[ "$machine" == "Linux" ]]; then
        input_file=$(dialog --title "Choose a file" --stdout --title "Please choose a file to process" --fselect /tmp/ 14 48)
    elif [[ "$machine" == "Cygwin" ]]; then
        input_file=$(dialog --title "Choose a file" --stdout --title "Please choose a file to process" --fselect /tmp/ 14 48)
    elif [ "$#" -ne 1 ] || ! [ -f "$input_file" ]; then
        echo "Usage: $0 input_file bit_rate"
        exit 1
    fi
fi

if ! [ -f "$input_file" ]; then
  echo "Usage: $0 input_file bit_rate"
  exit 1
fi

##############################################################################
# Prompt for bitrate
###############################################################################
if [[ "$bitrate" == "" ]]; then
    if [[ "$machine" == "Mac" ]]; then
        bitrate=$(osascript -e 'set T to text returned of (display dialog "Enter new audio bitrate value (ex: 96, 112, 128, 160, 192, 256, 320) :" buttons {"Cancel", "OK"} default button "OK" default answer "")')
    elif [[ "$machine" == "Linux" ]]; then
        bitrate=$(dialog --title "Enter new audio bitrate value (ex: 96, 112, 128, 160, 192, 256, 320) :" --inputbox "bitrate:" 8 60)
    elif [[ "$machine" == "Cygwin" ]]; then
        bitrate=$(dialog --title "Enter new audio bitrate value (ex: 96, 112, 128, 160, 192, 256, 320) :" --inputbox "bitrate:" 8 60)
    elif [ "$#" -ne 2 ] || ! [ -f "$input_file" ]; then
        echo "Usage: $0 input_file bitrate"
        exit 1
    fi
fi

if [[ "$bitrate" == "" ]]; then
    echo "Usage: $0 input_file bitrate"
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
outfile="$name"_audiocompressed
newoutfile=$outfile.$ext

ffmpeg -i "$input_file" -ab $bitrate "$newoutfile"