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
# Prompt for bitrate
###############################################################################
if [[ "$bitrate" == "" ]]; then
    if [[ "$machine" == "Mac" ]]; then
        bitrate=$(osascript -e 'set T to text returned of (display dialog "Enter new audio bitrate value (ex: 96, 112, 128, 160, 192, 256, 320) :" buttons {"Cancel", "OK"} default button "OK" default answer "")')
    elif [[ "$machine" == "Linux" ]]; then
        bitrate=$(dialog --title "Enter new audio bitrate value (ex: 96, 112, 128, 160, 192, 256, 320) :" --inputbox "bitrate:" 8 60)
    elif [[ "$machine" == "Cygwin" ]]; then
        bitrate=$(dialog --title "Enter new audio bitrate value (ex: 96, 112, 128, 160, 192, 256, 320) :" --inputbox "bitrate:" 8 60)
    elif [ "$#" -ne 2 ] || ! [ -f "$output_folder" ]; then
        echo "Usage: $0 output_folder bitrate"
        exit 1
    fi
fi

if [[ "$bitrate" == "" ]]; then
    echo "Usage: $0 output_folder bitrate"
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