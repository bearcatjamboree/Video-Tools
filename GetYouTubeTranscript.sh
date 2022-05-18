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

output_folder="$1"
video_provided="$2"

##############################################################################
# Check for file was passed.  Show open file dialog if no argument and on Mac
###############################################################################
if ! [ -f "output_folder" ]; then
    if [[ "$machine" == "Mac" ]]; then
        output_folder=$(osascript -e 'tell application (path to frontmost application as text)
        set output_folder to choose folder
        POSIX path of output_folder
        end')
    elif [[ "$machine" == "Linux" ]]; then
        output_folder=$(dialog --title "Choose a folder" --stdout --title "Please choose an output folder" --fselect /tmp/ 14 48)
    elif [ "$#" -ne 1 ] || ! [ -f "$output_folder" ]; then
        echo "Usage: $0 output_folder"
        exit 1
    fi
fi

##############################################################################
# Prompt for video_provided
###############################################################################
if [[ "$video_provided" == "" ]]; then
    if [[ "$machine" == "Mac" ]]; then
        video_provided=$(osascript -e 'set T to text returned of (display dialog "Enter YouTube video url or ID:" buttons {"Cancel", "OK"} default button "OK" default answer "")')
    elif [[ "$machine" == "Linux" ]]; then
        video_provided=$(dialog --title "Enter YouTube video url or ID:" --inputbox "video_provided:" 8 60)
    elif [[ "$machine" == "Cygwin" ]]; then
        video_provided=$(dialog --title "Enter YouTube video url or ID:" --inputbox "video_provided:" 8 60)
    elif [ "$#" -ne 2 ] || ! [ -f "$output_folder" ]; then
        echo "Usage: $0 output_folder video_provided"
        exit 1
    fi
fi

if [[ "$video_provided" == "" ]]; then
    echo "Usage: $0 output_folder video (url or ID)"
    exit 1
fi

query_string="${video_provided##*v=}"
video_id="${query_string%&*}"

echo "video_id = $video_id"

####################################
# Remove backslashes
####################################
file=$(echo "$output_folder"|tr -d '\\')

languages=( "ar" "en" "es" "hi" "zh" )

for lang in "${languages[@]}"
do :
  python3 GetYouTubeTranscript.py --video_id "$video_id" --output_folder "$output_folder" --language "$lang"
done