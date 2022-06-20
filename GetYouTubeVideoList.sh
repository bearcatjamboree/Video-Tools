#!/bin/zsh
#================================================================================
#  AUTHOR
#    Clint Box
#    https://www.youtube.com/bearcatjamboree
#
#   FUNCTION
#     Download YouTube video list based on URL (channel/playlist)
#
#   DETAILS
#     This script will download a playlist
#
#   USAGE
#     ${SCRIPT_NAME} "<playlist URL>" "<output folder>"
#
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
# Prompt for _output folder
###############################################################################
if ! [ -d "$output_folder" ]; then
    if [[ "$machine" == "Mac" ]]; then
        output_folder=$(osascript -e 'tell application (path to frontmost application as text)
        set output_folder to choose folder with prompt "Please select _output folder:"
        POSIX path of output_folder
        end')
    elif [[ "$machine" == "Linux" ]]; then
        output_folder=$(dialog --title "Choose a folder" --stdout --title "Please select output folder:" --fselect ~/ 14 48)
    elif [[ "$machine" == "Cygwin" ]]; then
        output_folder=$(dialog --title "Choose a folder" --stdout --title "Please select output folder:" --fselect ~/ 14 48)
    else
        echo "Usage: $0 language video_url output_folder"
        exit 1
    fi
fi

if ! [ -d "$output_folder" ]; then
  echo "Usage: $0 language video_url output_folder"
  exit 1
fi

output_folder=${output_folder%/}

# download playlist info

youtube_data=$(yt-dlp --dump-json "$video_url" | jq -r '[.title,.id,.upload_date]|@csv')

# Read playlist info to array (lines)
i=0; lines=()
while IFS='' read -r value; do
    lines+=("$value")
done <<< "$youtube_data"

echo "" > "$output_folder/video_list.txt"

for line in "${lines[@]}"
do
  IFS="," read -r title id upload_date <<< "$line"

  title=$(echo $title | sed 's/\"//g')
  id=$(echo $id | sed 's/\"//g')

  url="https://www.youtube.com/watch?v=$id"
  echo "$title, $url, $upload_date" >> "$output_folder/video_list.txt"

done

sort "$output_folder/video_list.txt" > "$output_folder/video_list_sorted.txt"
