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
# GU9_ED1bE3s
echo 'Enter Video ID:'
# shellcheck disable=SC2162
read video_id

####################################
# Remove backslashes
####################################
file=$(echo "$output_folder"|tr -d '\\')

python3 GetYouTubeTranscript.py --video_id "$video_id" --output_folder "$output_folder" --language "es"
python3 GetYouTubeTranscript.py --video_id "$video_id" --output_folder "$output_folder" --language "hi"
python3 GetYouTubeTranscript.py --video_id "$video_id" --output_folder "$output_folder" --language "zh-Hans"