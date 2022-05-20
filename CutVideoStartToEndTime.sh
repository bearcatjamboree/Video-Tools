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
start="$2"
end="$3"

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
        echo "Usage: $0 input_file start end"
        exit 1
    fi
fi

if ! [ -f "$input_file" ]; then
  echo "Usage: $0 input_file start end"
  exit 1
fi

##############################################################################
# Prompt for start
###############################################################################
if [[ "$start" == "" ]]; then
    if [[ "$machine" == "Mac" ]]; then
        start=$(osascript -e 'set T to text returned of (display dialog "Start Time [hh:mm:ss]: " buttons {"Cancel", "OK"} default button "OK" default answer "")')
    elif [[ "$machine" == "Linux" ]]; then
        start=$(dialog --title "Start Time [hh:mm:ss]: " --inputbox "start:" 8 60)
    elif [[ "$machine" == "Cygwin" ]]; then
        start=$(dialog --title "Start Time [hh:mm:ss]: " --inputbox "start:" 8 60)
    elif [ "$#" -ne 2 ] || ! [ -f "$input_file" ]; then
        echo "Usage: $0 input_file start end"
        exit 1
    fi
fi

if [[ "$start" == "" ]] ; then
   echo "Error: Start Time is a required input" >&2; exit 1
fi

##############################################################################
# Prompt for end
###############################################################################
if [[ "$end" == "" ]]; then
    if [[ "$machine" == "Mac" ]]; then
        end=$(osascript -e 'set T to text returned of (display dialog "End Time [hh:mm:ss]: " buttons {"Cancel", "OK"} default button "OK" default answer "")')
    elif [[ "$machine" == "Linux" ]]; then
        end=$(dialog --title "End Time [hh:mm:ss]: " --inputbox "end:" 8 60)
    elif [[ "$machine" == "Cygwin" ]]; then
        end=$(dialog --title "End Time [hh:mm:ss]: " --inputbox "end:" 8 60)
    elif [ "$#" -ne 2 ] || ! [ -f "$input_file" ]; then
        echo "Usage: $0 input_file start end"
        exit 1
    fi
fi

if [[ "$end" == "" ]] ; then
   echo "Error: End Time is a required input" >&2; exit 1
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
outfile="$name"_clipped
newoutfile=$outfile.$ext

ffmpeg -i "$input_file" -ss "$start" -to "$end" -async 1 "$newoutfile"