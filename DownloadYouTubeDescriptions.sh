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
output_folder="$1"
url="$2"

#echo "Input video to merge"

##############################################################################
# Check for file was passed.  Show open file dialog if no argument and on Mac
###############################################################################
if ! [ -f "$output_folder" ]; then
    if [[ "$machine" == "Mac" ]]; then
        output_folder=$(osascript -e 'tell application (path to frontmost application as text)
        set output_folder to choose folder with prompt "Please select output folder:"
        POSIX path of output_folder
        end')
    elif [[ "$machine" == "Linux" ]]; then
        output_folder=$(dialog --title "Choose a folder" --stdout --title "Please select output folder:" --fselect /tmp/ 14 48)
    elif [[ "$machine" == "Cygwin" ]]; then
        output_folder=$(dialog --title "Choose a folder" --stdout --title "Please select output folder:" --fselect /tmp/ 14 48)
    elif [ "$#" -ne 2 ] || ! [ -f "$output_folder" ]; then
        echo "Usage: $0 output_folder url"
        exit 1
    fi
fi

##############################################################################
# Prompt for URL
###############################################################################
if [[ "$url" == "" ]]; then
    if [[ "$machine" == "Mac" ]]; then
        url=$(osascript -e 'set T to text returned of (display dialog "Enter playlist URL:" buttons {"Cancel", "OK"} default button "OK" default answer "")')
    elif [[ "$machine" == "Linux" ]]; then
        url=$(dialog --title "Enter playlist location" --inputbox "URL:" 8 60)
    elif [[ "$machine" == "Cygwin" ]]; then
        url=$(dialog --title "Enter playlist location" --inputbox "URL:" 8 60)
    elif [ "$#" -ne 2 ] || ! [ -f "$output_folder" ]; then
        echo "Usage: $0 output_folder url"
        exit 1
    fi
fi

if [[ "$url" == "" ]]; then
    echo "Usage: $0 output_folder url"
    exit 1
fi

# download descriptions from all videos in playlist
youtube-dl "$url" --write-description --skip-download --youtube-skip-dash-manifest -o "$output_folder%(title)s"

# rename the .descripton to .txt in the output file names
for file in $output_folder/*.description ; do mv "$file" "${file%.*}.txt" ; done