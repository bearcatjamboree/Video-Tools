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

# --- Start updating here

channel="BearcatJamboree"

# Supported languages:  af, en, da, zh, zh, hr, nl, no, fi, fr, de, gu, hi, id,
#                       ja, jv, it, ms, ml, mr, pa, pl, pt, pt, ro, ru, sr, sk,
#                       th, ur, ca, es, sv, tl, tr, cs, kn, uk, vi, ar
language="en"

# Supported Licenses: 'Public Domain', 'Creative Commons Attribution 4.0 International',
#                     'Creative Commons Attribution-ShareAlike 4.0 International',
#                     'Creative Commons Attribution-NoDerivatives 4.0 International',
#                     'Creative Commons Attribution-NonCommercial 4.0 International',
#                     'Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International',
#                     'Creative Commons Attribution-NonCommercial-NoDerivatives 4.0 International',
#                     'Copyrighted (All rights reserved)', 'Other'
license="Copyrighted (All rights reserved)"

# Up to 5 total tags, quoted, and space separated
tags=("Minecraft" "Gaming" "Survival" "BedWars" "Shorts")

# --- Stop updating here

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

#
# Batch to load the exported videos and descriptions
# full option list:
# python3 -m lbry_batch_uploader file_directory channel_name
#     [--optimize-file] [--port PORT] [--bid BID] [--fee-amount FEE_AMOUNT]
#     [--tags TAGS [TAGS ...]] [--languages L [L ...]] [--license LICENSE]
#     [--license-url LICENSE_URL]
#
python3 -m lbry_batch_uploader \
    "$output_folder" \
    "@${channel}" \
    --tags ${tags} \
    --languages "${language}" \
    --license "${license}"