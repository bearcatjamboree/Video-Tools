#!/bin/zsh
#================================================================================
#  AUTHOR
#    Clint Box
#    https://www.youtube.com/bearcatjamboree
#
#   FUNCTION
#     Download YouTube video and add translated subtitles in different languages
#
#   DETAILS
#     This script will go through a list of languages and perform the following tasks:
#     1. Download highest quality video from YouTube for a provided URL
#     2. Get the YouTube video description in each language
#     3. Get the YouTube transcript (and subtitles file) in each language
#     4. Burn the subtitles from the translated SRT file to the video
#
#   USAGE
#     ${SCRIPT_NAME} "<language code>" "<video URL or YouTube ID>" "<output folder>"
# ================================================================================
unameOut="$(uname -s)"
case "${unameOut}" in
    Linux*)     machine=Linux;;
    Darwin*)    machine=Mac;;
    CYGWIN*)    machine=Cygwin;;
    MINGW*)     machine=MinGw;;
    *)          machine="UNKNOWN:${unameOut}"
esac

echo ${machine}

# make this the full list of languages (codes) you want to convert (other than your language)
languages=( "ar" "es" "hi" "id" "zh-Hans" )

# These language codes must correspond with LanguageCodes.md.
# Labels must match GenerateSpeechFromText otherwise system voice will not be found.
declare -A language_names=(
	["ar"]="Arabic"
	["es"]="Spanish"
	["en"]="English"
	["hi"]="Hindi"
	["id"]="Indonesian"
	["zh-Hans"]="Mandarin"
)

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

# handle feature= url format
if [[ "$url" == *"?feature=share"* ]]; then
    url=$(echo "$url" 2>&1 | sed -n "s/\(.*\)?feature=share/\1/p")
fi

echo "$url"

# handle watch?v=
video_id="${url##*v=}"
echo "$video_id"

video_id="${video_id##*/}"
echo "$video_id"

# handle video id followed by additional args
video_id="${video_id%&*}"
echo "$video_id"

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

# get title
title=$( yt-dlp --flat-playlist --print "%(title)s" "$url")
title=$(echo $title | sed 's/\"//g')
title=$(echo $title | sed "s/\'//g")
title=$(echo $title | sed 's/\#/\_/g')
title=$(echo $title | sed 's/\!//g')
echo "Title: $title"

# download the video in best mp4 format
video=$(yt-dlp "$url" -f "bv*[ext=mp4]+ba[ext=m4a]/b[ext=mp4] / bv*+ba/b" -o "$output_folder$title.%(ext)s")
video="$output_folder$title.mp4"

ext="${video##*.}"
name="${video%.*}"
name="${name##*/}"

video_file="${name}.${ext}"
srt_file="${name}.srt"
wav_file="${name}.wav"

echo "$video_file"
echo "$srt_file"
echo "$wav_file"

for language in "${languages[@]}"
do
  new_output=$output_folder$language

  # Don't reprocess the language if rerun
  if ! [ -d "$new_output" ]; then

    mkdir $new_output

    # copy vocal only file to language specific folder
    cp "$output_folder$video_file" "$new_output"

    new_video_file="$new_output/${name}.${ext}"
    srt_file="$new_output/${video_id}_$language.srt"

    # Get translated description and subtitles; then burn subtitles
    echo /bin/zsh ~/PycharmProjects/Video-Tools/TranslateYouTubeDescription.sh "$language" "$url" "$output_folder"
    /bin/zsh ~/PycharmProjects/Video-Tools/TranslateYouTubeDescription.sh "$language" "$url" "$output_folder"

    echo /bin/zsh ~/PycharmProjects/Video-Tools/TranslateYouTubeTranscript.sh "$language" "$url" "$output_folder"
    /bin/zsh ~/PycharmProjects/Video-Tools/TranslateYouTubeTranscript.sh "$language" "$url" "$output_folder"

    echo /bin/zsh ~/PycharmProjects/Video-Tools/BurnSubtitlesFromSRT.sh "$new_video_file" "$srt_file"
    /bin/zsh ~/PycharmProjects/Video-Tools/BurnSubtitlesFromSRT.sh "$new_video_file" "$srt_file"

  fi

done