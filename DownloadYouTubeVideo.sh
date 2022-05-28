#!/bin/zsh

unameOut="$(uname -s)"
case "${unameOut}" in
    Linux*)     machine=Linux;;
    Darwin*)    machine=Mac;;
    CYGWIN*)    machine=Cygwin;;
    MINGW*)     machine=MinGw;;
    *)          machine="UNKNOWN:${unameOut}"
esac

echo ${machine}

url="$1"
output_folder="$2"

##############################################################################
# Prompt for url
###############################################################################
if [[ "$url" == "" ]]; then
    if [[ "$machine" == "Mac" ]]; then
        url=$(osascript -e 'set T to text returned of (display dialog "Enter YouTube video url:" buttons {"Cancel", "OK"} default button "OK" default answer "")')
    elif [[ "$machine" == "Linux" ]]; then
        url=$(dialog --title "Enter YouTube video url:" --inputbox "url:" 8 60)
    elif [[ "$machine" == "Cygwin" ]]; then
        url=$(dialog --title "Enter YouTube video url:" --inputbox "url:" 8 60)
    else
        echo "Usage: $0 language [video URL or ID] output_folder"
        exit 1
    fi
fi

if [[ "$url" == "" ]]; then
    echo "Usage: $0 output_folder [video URL]"
    exit 1
fi

url="${url##*v=}"
url="${url##*/}"
video_id="${url%&*}"

echo "video_id = $video_id"

##############################################################################
# Check for file was passed.  Show open file dialog if no argument and on Mac
###############################################################################
if ! [ -d "$output_folder" ]; then
    if [[ "$machine" == "Mac" ]]; then
        output_folder=$(osascript -e 'tell application (path to frontmost application as text)
        set output_folder to choose folder with prompt "Please choose an _output folder"
        POSIX path of output_folder
        end')
    elif [[ "$machine" == "Linux" ]]; then
        output_folder=$(dialog --title "Choose a folder" --stdout --title "Please select output folder:" --fselect ~/ 14 48)
    elif [[ "$machine" == "Cygwin" ]]; then
        output_folder=$(dialog --title "Choose a folder" --stdout --title "Please select output folder:" --fselect ~/ 14 48)
    else
        echo "Usage: $0 language [video URL or ID] output_folder"
        exit 1
    fi
fi

echo "$output_folder"

if ! [ -d "$output_folder" ]; then
  echo "Usage: $0 output_folder [video URL or ID] "
  exit 1
fi

#yt-dlp "ytsearch:$url" -f "bv*[ext=mp4]+ba[ext=m4a]/b[ext=mp4] / bv*+ba/b" -o "$output_folder%(title)s.%(ext)s"
yt-dlp "$url" -f "bv*[ext=mp4]+ba[ext=m4a]/b[ext=mp4] / bv*+ba/b" -o "$output_folder%(title)s.%(ext)s"