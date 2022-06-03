#!/bin/sh
#================================================================================
#  AUTHOR
#    Clint Box
#    https://www.youtube.com/bearcatjamboree
#
#   FUNCTION
#     Convert audio or video files to another format
#
#   DETAILS
#     This script loops through a user provided folder and formats the commands
#     to ffmpeg to convert the files to a user specified format and save to a
#     user specified folder
#
#   USAGE
#     ${SCRIPT_NAME} "input_folder" "output_folder" "format"
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
input_folder="$1"
output_folder="$2"
format="$3"

##############################################################################
#  Prompt for input folder
###############################################################################
if ! [ -d "$input_folder" ]; then
    if [[ "$machine" == "Mac" ]]; then
        input_folder=$(osascript -e 'tell application (path to frontmost application as text)
        set input_folder to choose folder with prompt "Please choose an input folder"
        POSIX path of input_folder
        end')
    elif [[ "$machine" == "Linux" ]]; then
        input_folder=$(dialog --title "Choose a folder" --stdout --title "Please choose an input folder" --fselect ~/ 14 48)
    elif [[ "$machine" == "Cygwin" ]]; then
        input_folder=$(dialog --title "Choose a folder" --stdout --title "Please choose an input folder" --fselect ~/ 14 48)
    else
        echo "Usage: $0 input_file input_folder format"
        exit 1
    fi
fi

if ! [ -d "$input_folder" ]; then
  echo "Usage: $0 input_folder output_folder"
  exit 1
fi

# Remove trailing slash for path
input_folder="${input_folder%/}"

##############################################################################
#  Prompt for output folder
###############################################################################
if ! [ -d "$output_folder" ]; then
    if [[ "$machine" == "Mac" ]]; then
        output_folder=$(osascript -e 'tell application (path to frontmost application as text)
        set output_folder to choose folder with prompt "Please choose an output folder"
        POSIX path of output_folder
        end')
    elif [[ "$machine" == "Linux" ]]; then
        output_folder=$(dialog --title "Choose a folder" --stdout --title "Please choose an output folder" --fselect ~/ 14 48)
    elif [[ "$machine" == "Cygwin" ]]; then
        output_folder=$(dialog --title "Choose a folder" --stdout --title "Please choose an output folder" --fselect ~/ 14 48)
    else
        echo "Usage: $0 input_file output_folder format"
        exit 1
    fi
fi

if ! [ -d "$output_folder" ]; then
  echo "Usage: $0 input_folder output_folder"
  exit 1
fi

# Remove trailing slash for path
output_folder="${output_folder%/}"

echo "Enter output format (mov, avi, etc.): "
##############################################################################
# Prompt for format
###############################################################################
if [[ "$format" == "" ]]; then
    if [[ "$machine" == "Mac" ]]; then
        format=$(osascript -e 'set T to text returned of (display dialog "Enter _output format (mov, avi, etc.):" buttons {"Cancel", "OK"} default button "OK" default answer "")')
    elif [[ "$machine" == "Linux" ]]; then
        format=$(dialog --title "Enter output format (mov, avi, etc.):" --inputbox "format:" 8 60)
    elif [[ "$machine" == "Cygwin" ]]; then
        format=$(dialog --title "Enter output format (mov, avi, etc.):" --inputbox "format:" 8 60)
    else
        echo "Usage: $0 input_file format"
        exit 1
    fi
fi

if [[ "$format" == "" ]] ; then
  echo "Usage: $0 input_file format"
  exit 1
fi

###################################
#  Process each input folder file
###################################
for filename in $input_folder/*.*; do

    # Get filiename pieces
    file="${filename##*/}"
    ext="${file##*.}"
    name=""${file%.*}

    # Construct output file name
    outfile="$output_folder/$name.$format"

    ffmpeg -i "$filename" "$outfile"

done