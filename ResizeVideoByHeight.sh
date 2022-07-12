#!/bin/sh
#================================================================================
#  AUTHOR
#    Clint Box
#    https://www.youtube.com/bearcatjamboree
#
#   FUNCTION
#     Resize video
#
#   DETAILS
#     This script will invoke ffmpeg with parameters required to take an input
#     video file and resize it based solely on height (aspect retained)
#
#   USAGE
#     ${SCRIPT_NAME} "<input video>" "height"
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
height="$2"

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
        echo "Usage: $0 input_file height"
        exit 1
    fi
fi

if ! [ -f "$input_file" ]; then
  echo "Usage: $0 $input_file height"
  exit 1
fi

##############################################################################
# Prompt for height
###############################################################################
if [[ "$height" == "" ]]; then
    if [[ "$machine" == "Mac" ]]; then
        height=$(osascript -e 'set T to text returned of (display dialog "Enter new video height (aspect ratio will be retained):" buttons {"Cancel", "OK"} default button "OK" default answer "")')
    elif [[ "$machine" == "Linux" ]]; then
        height=$(dialog --title "Enter new video height (aspect ratio will be retained)" --inputbox "height:" 8 60)
    elif [[ "$machine" == "Cygwin" ]]; then
        height=$(dialog --title "Enter new video height (aspect ratio will be retained)" --inputbox "height:" 8 60)
    elif [ "$#" -ne 2 ] || ! [ -f "$input_file" ]; then
        echo "Usage: $0 input_file height"
        exit 1
    fi
fi

re='^[0-9]+$'

if ! [[ $height =~ $re ]] ; then
   echo "Error: \"$height\" is not a number" >&2; exit 1
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

ffmpeg -i "$input_file" -vf scale=-1:$height "$newoutfile"