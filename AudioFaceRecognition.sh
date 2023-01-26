#!/bin/sh
#================================================================================
#  AUTHOR
#    Clint Box
#    https://www.youtube.com/bearcatjamboree
#
#   FUNCTION
#     Jump cut video using audio level and facial recognition
#
#   DETAILS
#     This script will invoke VideoJumpcutter using a specific file and will
#     perform audio jump cut and face recognition.
#
#   USAGE
#     ${SCRIPT_NAME} "video_path"
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
input_video="$1"
input_image="$2"

##############################################################################
# Check for file was passed.  Show open file dialog if no argument and on Mac
###############################################################################
if ! [ -f "$input_video" ]; then
    if [[ "$machine" == "Mac" ]]; then
        input_video=$(osascript -e 'tell application (path to frontmost application as text)
        set input_video to choose file with prompt "Please choose a file to process"
        POSIX path of input_video
        end')
    elif [[ "$machine" == "Linux" ]]; then
        input_video=$(dialog --title "Choose a file" --stdout --title "Please choose a file to process" --fselect /tmp/ 14 48)
    elif [[ "$machine" == "Cygwin" ]]; then
        input_video=$(dialog --title "Choose a file" --stdout --title "Please choose a file to process" --fselect /tmp/ 14 48)
    elif [ "$#" -ne 1 ] || ! [ -f "$input_video" ]; then
        echo "Usage: $0 input_video"
        exit 1
    fi
fi

if ! [ -f "$input_video" ]; then
  echo "Usage: $0 input_video"
  exit 1
fi

##############################################################################
# Check for file was passed.  Show open file dialog if no argument and on Mac
###############################################################################
if ! [ -f "$input_image" ]; then
    if [[ "$machine" == "Mac" ]]; then
        input_image=$(osascript -e 'tell application (path to frontmost application as text)
        set input_image to choose file with prompt "Please choose a file to process"
        POSIX path of input_image
        end')
    elif [[ "$machine" == "Linux" ]]; then
        input_image=$(dialog --title "Choose a file" --stdout --title "Please choose a file to process" --fselect /tmp/ 14 48)
    elif [[ "$machine" == "Cygwin" ]]; then
        input_image=$(dialog --title "Choose a file" --stdout --title "Please choose a file to process" --fselect /tmp/ 14 48)
    elif [ "$#" -ne 1 ] || ! [ -f "$input_image" ]; then
        echo "Usage: $0 input_image"
        exit 1
    fi
fi

if ! [ -f "$input_image" ]; then
  echo "Usage: $0 input_image"
  exit 1
fi

####################################
# Remove backlashes from filepaths
####################################
file=$(echo "$input_video"|tr -d '\\')

####################################
# Separate file name from extension
####################################
ext="${file##*.}"
name="${file%.*}"

############################
# Get file path information
############################
outfile="$name"_faceswap
newoutfile=$outfile.$ext

python VideoJumpcutter.py --input_video "$input_video" --input_image "$input_image" --output_file "$newoutfile"
