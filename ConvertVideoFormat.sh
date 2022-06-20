#!/bin/sh
#================================================================================
#  AUTHOR
#    Clint Box
#    https://www.youtube.com/bearcatjamboree
#
#   FUNCTION
#     Create video with a new video format
#
#   DETAILS
#     This script will invoke ffmpeg with parameters required to take an input
#     video and produce a new video with a new video format
#
#   USAGE
#     ${SCRIPT_NAME} "video_path" "format"
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
format="$2"

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
    else
        echo "Usage: $0 input_file format"
        exit 1
    fi
fi

if ! [ -f "$input_file" ]; then
  echo "Usage: $0 input_file format"
  exit 1
fi

echo "Enter output format (mov, avi, etc.): "
##############################################################################
# Prompt for format
###############################################################################
if [[ "$format" == "" ]]; then
    if [[ "$machine" == "Mac" ]]; then
        format=$(osascript -e 'set T to text returned of (display dialog "Enter _output format (mov, avi, etc.):" buttons {"Cancel", "OK"} default button "OK" default answer "")')
    elif [[ "$machine" == "Linux" ]]; then
        format=$(dialog --title "Enter output format (mov, avi, etc.):" --inputbox "format:" 8 60)
    elif [[ "$machine" == "Cygwin" ]]; then
        format=$(dialog --title "Enter output format (mov, avi, etc.):" --inputbox "format:" 8 60)
    else
        echo "Usage: $0 input_file format"
        exit 1
    fi
fi

if [[ "$format" == "" ]] ; then
  echo "Usage: $0 input_file format"
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
outfile=$name.$format

if [[ "$format" == "mp4" ]]; then
    ffmpeg -i "$input_file" -vcodec libx264 -acodec aac -pix_fmt yuv420p "$outfile"
elif [[ "$format" == "webm" ]]; then
    ffmpeg -i "$input_file" -c:v libvpx -crf 10 -b:v 1M -c:a libvorbis "$outfile"
elif [[ "$format" == "ogg" ]]; then
    ffmpeg -i "$input_file" -codec:v libtheora -qscale:v 7 -codec:a libvorbis -qscale:a 5 "$outfile"
else
    ffmpeg -i "$input_file" "$outfile"
fi