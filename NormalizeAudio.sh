#!/bin/sh
#================================================================================
#  AUTHOR
#    Clint Box
#    https://www.youtube.com/bearcatjamboree
#
#   FUNCTION
#     Normalize a audio files in a source folder
#
#   DETAILS
#     This script will invoke sox with parameters required to take a folder containing
#     audio files and produce a folder containing normalized audio files
#
#   USAGE
#     ${SCRIPT_NAME} "<input folder>" "normalizationValue"
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
normalizationValue="$2"

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
        echo "Usage: $0 input_folder normalizationValue"
        exit 1
    fi
fi

if ! [ -d "$input_folder" ]; then
  echo "Usage: $0 input_folder normalizationValue"
  exit 1
fi

##############################################################################
# Prompt for aspect
###############################################################################
if [[ "$normalizationValue" == "" ]]; then
    if [[ "$machine" == "Mac" ]]; then
        normalizationValue=$(osascript -e 'set T to text returned of (display dialog "Enter normalization value: " buttons {"Cancel", "OK"} default button "OK" default answer "-0.1")')
    elif [[ "$machine" == "Linux" ]]; then
        normalizationValue=$(dialog --title "Enter normalization value: " --inputbox "aspect:" 8 60)
    elif [[ "$machine" == "Cygwin" ]]; then
        normalizationValue=$(dialog --title "Enter normalization value: " --inputbox "aspect:" 8 60)
    elif [ "$#" -ne 2 ] || ! [ -f "$input_file" ]; then
        echo "Usage: $0 input_file normalizationValue"
        exit 1
    fi
fi

if [[ "$normalizationValue" == "" ]] ; then
  echo "Usage: $0 input_file aspect"
  exit 1
fi

input_folder=$(echo "$input_folder" | sed 's/\(.*\)\//\1/g')
echo "${input_folder}"

find "${input_folder}" -type f -name "*.mp3" -o -name "*.ogg" -o -name "*.wav" -o -name "*.ogg" |
while read f; do
  normalizedFolder="$(dirname "$f")/Normalized ${normalizationValue}"
	fileName=$(basename "$f")
	if [ ! -d "${normalizedFolder}" ]; then
    mkdir "${normalizedFolder}"
	fi
	/opt/homebrew/bin/sox --norm=${normalizationValue} "$f" "${normalizedFolder}/${fileName}"
	#echo /opt/homebrew/bin/sox --norm=${normalizationValue} "$f" "${normalizedFolder}/${fileName}"
done