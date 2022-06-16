#!/bin/sh
#================================================================================
#  AUTHOR
#    Clint Box
#    https://www.youtube.com/bearcatjamboree
#
#   FUNCTION
#     Create video with a new resolution ratio and blurred outside
#
#   DETAILS
#     This script will invoke ffmpeg with parameters required to take an input
#     video and produce a new video with a new resolution ratio
#
#   USAGE
#     ${SCRIPT_NAME} "video_path" "resolution"
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
resolution="$2"

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
        echo "Usage: $0 input_file resolution"
        exit 1
    fi
fi

if ! [ -f "$input_file" ]; then
  echo "Usage: $0 input_file resolution"
  exit 1
fi

##############################################################################
# Prompt for resolution
###############################################################################
if [[ "$resolution" == "" ]]; then
    if [[ "$machine" == "Mac" ]]; then
        resolution=$(osascript -e 'set T to text returned of (display dialog "Enter new resolution (1280x720, 1920x1080, 1080x1920, etc.): " buttons {"Cancel", "OK"} default button "OK" default answer "")')
    elif [[ "$machine" == "Linux" ]]; then
        resolution=$(dialog --title "Enter new resolution (1280x720, 1920x1080, 1080x1920, etc.): " --inputbox "resolution:" 8 60)
    elif [[ "$machine" == "Cygwin" ]]; then
        resolution=$(dialog --title "Enter new resolution (1280x720, 1920x1080, 1080x1920, etc.): " --inputbox "resolution:" 8 60)
    elif [ "$#" -ne 2 ] || ! [ -f "$input_file" ]; then
        echo "Usage: $0 input_file resolution"
        exit 1
    fi
fi

if [[ "$resolution" == "" ]] ; then
  echo "Usage: $0 input_file resolution"
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
outfile="$name"_blur
newoutfile=$outfile.$ext

ffmpeg -i "$input_file" -filter_complex "[0:v]boxblur=40,scale=$resolution,setsar=1[bg];[0:v]scale=$resolution:force_original_aspect_ratio=decrease[fg];[bg][fg]overlay=y=(H-h)/2" -c:a copy "$newoutfile"