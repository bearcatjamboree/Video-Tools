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
width="$2"

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
        input_file=$(dialog --title "Choose a file" --stdout --title "Please choose a file to process" --fselect /tmp/ 14 48)
    elif [[ "$machine" == "Cygwin" ]]; then
        input_file=$(dialog --title "Choose a file" --stdout --title "Please choose a file to process" --fselect /tmp/ 14 48)
    elif [ "$#" -ne 1 ] || ! [ -f "$input_file" ]; then
        echo "Usage: $0 input_file width"
        exit 1
    fi
fi

if ! [ -f "$input_file" ]; then
  echo "Usage: $0 $input_file width"
  exit 1
fi

##############################################################################
# Prompt for width
###############################################################################
if [[ "$width" == "" ]]; then
    if [[ "$machine" == "Mac" ]]; then
        width=$(osascript -e 'set T to text returned of (display dialog "Enter new video width (aspect ratio will be retained):" buttons {"Cancel", "OK"} default button "OK" default answer "")')
    elif [[ "$machine" == "Linux" ]]; then
        width=$(dialog --title "Enter new video width (aspect ratio will be retained)" --inputbox "width:" 8 60)
    elif [[ "$machine" == "Cygwin" ]]; then
        width=$(dialog --title "Enter new video width (aspect ratio will be retained)" --inputbox "width:" 8 60)
    elif [ "$#" -ne 2 ] || ! [ -f "$input_file" ]; then
        echo "Usage: $0 input_file width"
        exit 1
    fi
fi

re='^[0-9]+$'

if ! [[ $width =~ $re ]] ; then
   echo "Error: \"$width\" is not a number" >&2; exit 1
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
outfile="$name"_resized
newoutfile=$outfile.$ext

#echo "ffmpeg -i \"$input_file\" -vf scale=$width:-1 \"$newoutfile\""
ffmpeg -i "$input_file" -vf scale=$width:-1 "$newoutfile"