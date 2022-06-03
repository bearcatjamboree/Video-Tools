#!/bin/sh
#================================================================================
#  AUTHOR
#    Clint Box
#    https://www.youtube.com/bearcatjamboree
#
#   FUNCTION
#     Extract images from video file
#
#   DETAILS
#     This script will invoke ffmpeg with parameters required to take an input
#     video and produce an image for every second of video frames and store
#     the images in a specified output folder
#
#   USAGE
#     ${SCRIPT_NAME} "<video file>" "<output folder>" "<image format>"
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
output_folder="$2"
format="$3"

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
        echo "Usage: $0 input_file output_folder format"
        exit 1
    fi
fi

if ! [ -f "$input_file" ]; then
  echo "Usage: $0 input_file output_folder format"
  exit 1
fi

##############################################################################
# Check for folder was passed.  Show open folder dialog if no argument and on Mac
###############################################################################
if ! [ -d "$output_folder" ]; then
    if [[ "$machine" == "Mac" ]]; then
        output_folder=$(osascript -e 'tell application (path to frontmost application as text)
        set output_folder to choose folder with prompt "Please choose an _output folder"
        POSIX path of output_folder
        end')
    elif [[ "$machine" == "Linux" ]]; then
        output_folder=$(dialog --title "Choose a folder" --stdout --title "Please choose a folder to process" --fselect /tmp/ 14 48)
    elif [[ "$machine" == "Cygwin" ]]; then
        output_folder=$(dialog --title "Choose a folder" --stdout --title "Please choose a folder to process" --fselect /tmp/ 14 48)
    elif [ "$#" -ne 1 ] || ! [ -f "$input_file" ]; then
        echo "Usage: $0 input_file output_folder format"
        exit 1
    fi
fi

##############################################################################
# Prompt for format
###############################################################################
if [[ "$format" == "" ]]; then
    if [[ "$machine" == "Mac" ]]; then
        format=$(osascript -e 'set T to text returned of (display dialog "Enter _output format (jpg, png, etc.):" buttons {"Cancel", "OK"} default button "OK" default answer "")')
    elif [[ "$machine" == "Linux" ]]; then
        format=$(dialog --title "Enter output format (jpg, png, etc.):" --inputbox "format:" 8 60)
    elif [[ "$machine" == "Cygwin" ]]; then
        format=$(dialog --title "Enter output format (jpg, png, etc.):" --inputbox "format:" 8 60)
    elif [ "$#" -ne 2 ]; then
        echo "Usage: $0 input_file output_folder format"
        exit 1
    fi
fi

if [[ "$format" == "" ]] ; then
   echo "Output format is required" >&2; exit 1
fi

ffmpeg -i "$input_file" -r 1 -f image2 "$output_folder/image-%07d.$format"