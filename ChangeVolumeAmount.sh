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
volume="$2"

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
        echo "Usage: $0 input_file volume"
        exit 1
    fi
fi

if ! [ -f "$input_file" ]; then
  echo "Usage: $0 input_file volume"
  exit 1
fi

##############################################################################
# Prompt for volume
###############################################################################
if [[ "$volume" == "" ]]; then
    if [[ "$machine" == "Mac" ]]; then
        volume=$(osascript -e 'set T to text returned of (display dialog "Enter volume adjustment amount (expressed as a decimal or dB value):" buttons {"Cancel", "OK"} default button "OK" default answer "")')
    elif [[ "$machine" == "Linux" ]]; then
        volume=$(dialog --title "Enter volume adjustment amount (expressed as a decimal or dB value):" --inputbox "volume:" 8 60)
    elif [[ "$machine" == "Cygwin" ]]; then
        volume=$(dialog --title "Enter volume adjustment amount (expressed as a decimal or dB value):" --inputbox "volume:" 8 60)
    elif [ "$#" -ne 2 ] || ! [ -f "$output_folder" ]; then
        echo "Usage: $0 input_file volume"
        exit 1
    fi
fi

if [[ "$volume" == "" ]] ; then
  echo "Usage: $0 input_file volume"
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
outfile="$name"_volume
newoutfile=$outfile.$ext

ffmpeg -i "$input_file" -filter:a "volume=$volume" "$newoutfile"