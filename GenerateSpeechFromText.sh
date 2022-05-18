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
        set input_file to choose file with prompt "Please select SRT file:"
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

echo "$input_file"

##############################################################################
# Check for voice to use
###############################################################################
if [[ "$machine" == "Mac" ]]; then
    language=$(osascript -e 'return choose from list {"Arabic", "Spanish", "Hindi", "Mandarin"}')
elif [[ "$machine" == "Linux" ]]; then
    language=$(dialog --title "Choose a file" --stdout --title "Please choose a file to process" --fselect /tmp/ 14 48)
elif [[ "$machine" == "Cygwin" ]]; then
    language=$(dialog --title "Choose a file" --stdout --title "Please choose a file to process" --fselect /tmp/ 14 48)
else
    echo "Unknown platform"
    exit 1
fi

if [[ "$language" == "Spanish" ]]; then
  voice="carlos"
elif [[ "$language" == "Hindi" ]]; then
  voice="neel"
elif [[ "$language" == "Mandarin" ]]; then
  voice="ting-ting"
elif [[ "$language" == "Arabic" ]]; then
  voice="maged"
else
    echo "Invalid selection returned"
    exit 1
fi

echo "$voice"

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
output_file=$name.wav

python3 GenerateSpeechFromText.py --input_file "$input_file" --output_file "$output_file" --voice "$voice"