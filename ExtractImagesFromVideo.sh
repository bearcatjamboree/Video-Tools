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
input_file="$1"

##############################################################################
# Check for file was passed.  Show open file dialog if no argument and on Mac
###############################################################################
if ! [ -f "$input_file" ]; then
    if [[ "$machine" == "Mac" ]]; then
        input_file=$(osascript -e 'tell application (path to frontmost application as text)
        set input_file to choose file
        POSIX path of input_file
        end')
    elif [[ "$machine" == "Linux" ]]; then
        input_file=$(dialog --title "Choose a file" --stdout --title "Please choose a file to process" --fselect /tmp/ 14 48)
    elif [[ "$machine" == "Cygwin" ]]; then
        input_file=$(dialog --title "Choose a file" --stdout --title "Please choose a file to process" --fselect /tmp/ 14 48)
    elif [ "$#" -ne 1 ] || ! [ -f "$input_file" ]; then
        echo "Usage: $0 input_file"
        exit 1
    fi
fi

##############################################################################
# Check for folder was passed.  Show open folder dialog if no argument and on Mac
###############################################################################
if ! [ -f "$output_folder" ]; then
    if [[ "$machine" == "Mac" ]]; then
        output_folder=$(osascript -e 'tell application (path to frontmost application as text)
        set output_folder to choose folder
        POSIX path of output_folder
        end')
    elif [[ "$machine" == "Linux" ]]; then
        output_folder=$(dialog --title "Choose a folder" --stdout --title "Please choose a folder to process" --fselect /tmp/ 14 48)
    elif [[ "$machine" == "Cygwin" ]]; then
        output_folder=$(dialog --title "Choose a folder" --stdout --title "Please choose a folder to process" --fselect /tmp/ 14 48)
    elif [ "$#" -ne 1 ] || ! [ -f "$output_folder" ]; then
        echo "Usage: $0 output_folder"
        exit 1
    fi
fi

##############################################################################
# Prompt for format
###############################################################################
if [[ "$format" == "" ]]; then
    if [[ "$machine" == "Mac" ]]; then
        format=$(osascript -e 'set T to text returned of (display dialog "Enter output format (jpg, png, etc.):" buttons {"Cancel", "OK"} default button "OK" default answer "")')
    elif [[ "$machine" == "Linux" ]]; then
        format=$(dialog --title "Enter output format (jpg, png, etc.):" --inputbox "format:" 8 60)
    elif [[ "$machine" == "Cygwin" ]]; then
        format=$(dialog --title "Enter output format (jpg, png, etc.):" --inputbox "format:" 8 60)
    elif [ "$#" -ne 2 ]; then
        echo "Usage: $0 output_folder format"
        exit 1
    fi
fi

if [[ "$format" == "" ]] ; then
   echo "Output format is required" >&2; exit 1
fi

ffmpeg -i "$input_file" -r 1 -f image2 "$output_folder/image-%07d.$format"