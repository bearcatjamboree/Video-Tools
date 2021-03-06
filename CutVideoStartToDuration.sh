#!/bin/sh
#================================================================================
#  AUTHOR
#    Clint Box
#    https://www.youtube.com/bearcatjamboree
#
#   FUNCTION
#     Cut video from start point to duration
#
#   DETAILS
#     This script will invoke ffmpeg with parameters required to take an input
#     video and create a clip at the starting point until a specified duration
#
#   USAGE
#     ${SCRIPT_NAME} "video_path" "start" "duration"
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
start="$2"
duration="$3"

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
        echo "Usage: $0 input_file start duration"
        exit 1
    fi
fi

if ! [ -f "$input_file" ]; then
  echo "Usage: $0 input_file start duration"
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
        echo "Usage: $0 input_file start duraton"
        exit 1
    fi
fi

if [[ "$start" == "" ]] ; then
  echo "Usage: $0 input_file start duraton"
  exit 1
fi

echo 'Clip Duration [hh:mm:ss]: '

##############################################################################
# Prompt for duration
###############################################################################
if [[ "$duration" == "" ]]; then
    if [[ "$machine" == "Mac" ]]; then
        duration=$(osascript -e 'set T to text returned of (display dialog "Clip Duration [hh:mm:ss]: " buttons {"Cancel", "OK"} default button "OK" default answer "")')
    elif [[ "$machine" == "Linux" ]]; then
        duration=$(dialog --title "Clip Duration [hh:mm:ss]: " --inputbox "duration:" 8 60)
    elif [[ "$machine" == "Cygwin" ]]; then
        duration=$(dialog --title "Clip Duration [hh:mm:ss]: " --inputbox "duration:" 8 60)
    elif [ "$#" -ne 2 ] || ! [ -d "$output_folder" ]; then
        echo "Usage: $0 input_file start duration"
        exit 1
    fi
fi

if [[ "$duration" == "" ]] ; then
  echo "Usage: $0 input_file start duraton"
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
outfile="$name"_clipped
newoutfile=$outfile.$ext

ffmpeg -ss "$start" -fflags +genpts -i "$input_file" -t "$duration" -c copy "$newoutfile"