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
#     ${SCRIPT_NAME} "<video_url>" "<input folder>"
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

video_url="$1"
output_folder="$2"

##############################################################################
# Prompt for URL
###############################################################################
if [[ "$video_url" == "" ]]; then
    if [[ "$machine" == "Mac" ]]; then
        video_url=$(osascript -e 'set T to text returned of (display dialog "Enter video or playlist URL" buttons {"Cancel", "OK"} default button "OK" default answer "")')
    elif [[ "$machine" == "Linux" ]]; then
        video_url=$(dialog --title "Enter playlist location" --inputbox "URL:" 8 60)
    elif [[ "$machine" == "Cygwin" ]]; then
        video_url=$(dialog --title "Enter playlist location" --inputbox "URL:" 8 60)
    else
        echo "Usage: $0 video_url output_folder"
        exit 1
    fi
fi

if [[ "$video_url" == "" ]]; then
    echo "Usage: $0 video_url output_folder"
    exit 1
fi

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

# Download video URL metadata
youtube_data=$(yt-dlp --dump-json "$video_url" | jq -r '[.title,.id]|@csv')

# Read playlist info to array (lines)
i=0; lines=()
while IFS='' read -r value; do
    lines+=("$value")
done <<< "$youtube_data"

# Loop through and: 1) download the videos and 2)
for line in "${lines[@]}"
do

  IFS="," read -r title id <<< "$line"
  id=$(echo $id | sed 's/\"//g')
  id=$(echo $id | sed 's/^-/\\-/g')

  url="https://www.youtube.com/watch?v=$id"

  # Download description and thumbnail (as png)
  yt-dlp "$url" --write-description --write-thumbnail --convert-thumbnail png --skip-download --youtube-skip-dash-manifest -o "$output_folder/%(title)s"

  # Download video
  echo /bin/zsh ~/PycharmProjects/Video-Tools/DownloadYouTubeVideo.sh "$url" "$output_folder"
  /bin/zsh ~/PycharmProjects/Video-Tools/DownloadYouTubeVideo.sh "$url" "$output_folder"

done