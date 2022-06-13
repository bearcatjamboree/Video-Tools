#!/bin/sh
#================================================================================
#  AUTHOR
#    Clint Box
#    https://www.youtube.com/bearcatjamboree
#
#   FUNCTION
#     Download a channel, playlist, or video from YouTube, along with description
#     data, and upload the exported data to Odysee
#
#   DETAILS
#     This script will use yt-dlp to download your YouTube data and then invoke
#     lbry_batch_uploader with parameters required to upload the exported data
#     to LBRY using the LBRY desktop client.  This will then make the videos
#     accessible to Odysee since Odysee using LBRY as a decentralized storage.
#
#   USAGE
#     ${SCRIPT_NAME} "<input folder>"
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

output_folder="$1"

channel="BearcatJamboree"
language="en"
license="Copyrighted (All rights reserved)"
tags=("Minecraft" "Gaming")  # 5 max

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
        echo "Usage: $0 video_url output_folder"
        exit 1
    fi
fi

if ! [ -d "$output_folder" ]; then
  echo "Usage: $0 video_url output_folder"
  exit 1
fi

python3 -m lbry_batch_uploader \
    "$output_folder" \
    "@${channel}" \
    --tags ${tags} \
    --languages "${language}" \
    --license "${license}"