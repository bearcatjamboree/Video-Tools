#!/bin/zsh
#####################################################################################
#
#  This script will download a playlist and use the id and title to construct calls
#  to TranslateYouTubeVideo.sh in order to facilitate migrating an entire playlist
#  from one language to several other languages.
#
#  This script requires spleeter environment be active before starting.
#  to start spleeter simply type:
#
#   conda activate spleeter
#
#####################################################################################
unameOut="$(uname -s)"
case "${unameOut}" in
    Linux*)     machine=Linux;;
    Darwin*)    machine=Mac;;
    CYGWIN*)    machine=Cygwin;;
    MINGW*)     machine=MinGw;;
    *)          machine="UNKNOWN:${unameOut}"
esac

echo "${machine}"

playlist_url="$1"
output_folder="$2"

##############################################################################
# Prompt for URL
###############################################################################
if [[ "$playlist_url" == "" ]]; then
    if [[ "$machine" == "Mac" ]]; then
        playlist_url=$(osascript -e 'set T to text returned of (display dialog "Enter video or playlist URL" buttons {"Cancel", "OK"} default button "OK" default answer "")')
    elif [[ "$machine" == "Linux" ]]; then
        playlist_url=$(dialog --title "Enter playlist location" --inputbox "URL:" 8 60)
    elif [[ "$machine" == "Cygwin" ]]; then
        playlist_url=$(dialog --title "Enter playlist location" --inputbox "URL:" 8 60)
    else
        echo "Usage: $0 playlist_url output_folder"
        exit 1
    fi
fi

if [[ "$playlist_url" == "" ]]; then
    echo "Usage: $0 playlist_url output_folder"
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
        echo "Usage: $0 language playlist_url output_folder"
        exit 1
    fi
fi

if ! [ -d "$output_folder" ]; then
  echo "Usage: $0 language playlist_url output_folder"
  exit 1
fi

output_folder=${output_folder%/}

# download playlist info

youtube_data=$(yt-dlp --dump-json "$playlist_url" | jq -r '[.title,.id]|@csv')

# Read playlist info to array (lines)
i=0; lines=()
while IFS='' read -r value; do
    lines+=("$value")
done <<< "$youtube_data"

for line in "${lines[@]}"
do
  IFS="," read -r title id <<< "$line"

  title=$(echo $title | sed 's/\"//g')
  title=$(echo $title | sed 's/\#/\_/g')
  id=$(echo $id | sed 's/\"//g')

  url="https://www.youtube.com/watch?v=$id"

  new_output_folder="$output_folder/$title"
  new_output_folder=$(echo $new_output_folder | sed 's/ /\ /g')

  if ! [ -d "$new_output_folder" ]; then
    mkdir $new_output_folder
    echo /bin/zsh ~/PycharmProjects/Video-Tools/TranslateYouTubeVideo.sh "$url" "$new_output_folder/"
    /bin/zsh ~/PycharmProjects/Video-Tools/TranslateYouTubeVideo.sh "$url" "$new_output_folder/"
  else
    echo "Skipping $new_output_folder"
  fi
  
done
