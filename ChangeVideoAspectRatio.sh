#!/bin/sh
#================================================================================
#  AUTHOR
#    Clint Box
#    https://www.youtube.com/bearcatjamboree
#
#   FUNCTION
#     Create video with a new aspect ratio
#
#   DETAILS
#     This script will invoke ffmpeg with parameters required to take an input
#     video and produce a new video with a new aspect ratio
#
#   USAGE
#     ${SCRIPT_NAME} "video_path" "aspect ratio"
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
aspect="$2"

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
        echo "Usage: $0 input_file aspect"
        exit 1
    fi
fi

if ! [ -f "$input_file" ]; then
  echo "Usage: $0 input_file aspect"
  exit 1
fi

##############################################################################
# Prompt for aspect
###############################################################################
if [[ "$aspect" == "" ]]; then
    if [[ "$machine" == "Mac" ]]; then
        aspect=$(osascript -e 'set T to text returned of (display dialog "Enter new aspect ratio (16:9, 4:3, 16:10, 5:4, 2:21:1, 2:35:1, 2:39:1, etc.): " buttons {"Cancel", "OK"} default button "OK" default answer "")')
    elif [[ "$machine" == "Linux" ]]; then
        aspect=$(dialog --title "Enter new aspect ratio (16:9, 4:3, 16:10, 5:4, 2:21:1, 2:35:1, 2:39:1, etc.): " --inputbox "aspect:" 8 60)
    elif [[ "$machine" == "Cygwin" ]]; then
        aspect=$(dialog --title "Enter new aspect ratio (16:9, 4:3, 16:10, 5:4, 2:21:1, 2:35:1, 2:39:1, etc.): " --inputbox "aspect:" 8 60)
    elif [ "$#" -ne 2 ] || ! [ -f "$input_file" ]; then
        echo "Usage: $0 input_file aspect"
        exit 1
    fi
fi

if [[ "$aspect" == "" ]] ; then
  echo "Usage: $0 input_file aspect"
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
outfile="$name"_newaspect
newoutfile=$outfile.$ext

ffmpeg -i "$input_file" -aspect "$aspect" "$newoutfile"