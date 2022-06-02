#!/bin/zsh
#####################################################################################
#
# This script will go through a list of languages and perform the following tasks:
#
#   1. Download highest quality video from YouTube for a provided URL
#   2. Remove vocals from the video but retaining accompany audio
#   3. Get the YouTube video description in each language
#   4. Get the YouTube transcript (and subtitles file) in each language
#   5. Generate speech (wav file) from the translated transcript
#   6. Burn the subtitles from the translated SRT file to the video
#   7. Merge the subtitled video and translated audio together
#
# This script requires spleeter environment be active before starting.
# to start spleeter simply type:
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
#title=$( yt-dlp --flat-playlist --print "%(title)s" "ytsearch:$url")
title=$( yt-dlp --flat-playlist --print "%(title)s" "$url")
title=$(echo $title | sed 's/\"//g')
title=$(echo $title | sed 's/\#/\_/g')
title=$(echo $title | sed 's/\!//g')
echo "Title: $title"

# download the video in best mp4 format
#video=$(yt-dlp "ytsearch:$url" -f "bv*[ext=mp4]+ba[ext=m4a]/b[ext=mp4] / bv*+ba/b" -o "$output_folder$title.%(ext)s")
video=$(yt-dlp "$url" -f "bv*[ext=mp4]+ba[ext=m4a]/b[ext=mp4] / bv*+ba/b" -o "$output_folder$title.%(ext)s")
video="$output_folder$title.mp4"

echo /bin/zsh ~/PycharmProjects/Video-Tools/RBM/RemoveVocals.sh "$video"
/bin/zsh ~/PycharmProjects/Video-Tools/RBM/RemoveVocals.sh "$video"

ext="${video##*.}"
name="${video%.*}"
name="${name##*/}"

novocals_file="${name}_novocals.${ext}"
srt_file="${name}_novocals.srt"
wav_file="${name}_novocals.wav"

echo "$novocals_file"
echo "$srt_file"
echo "$wav_file"

for language in "${languages[@]}"
do
  new_output=$output_folder$language

  if ! [ -d "$new_output" ]; then
    mkdir $new_output
  fi

  # copy vocal only file to language specific folder
  cp "$output_folder$novocals_file" "$new_output"

  new_novocals_file="$new_output/${name}_novocals.${ext}"
  subtitled_file="$new_output/${name}_novocals_subtitled.${ext}"

  wav_file="$new_output/${video_id}_$language.wav"
  srt_file="$new_output/${video_id}_$language.srt"

  # Perform all transformations
  echo /bin/zsh ~/PycharmProjects/Video-Tools/TranslateYouTubeDescription.sh "$language" "$url" "$output_folder"
  /bin/zsh ~/PycharmProjects/Video-Tools/TranslateYouTubeDescription.sh "$language" "$url" "$output_folder"

  echo /bin/zsh ~/PycharmProjects/Video-Tools/TranslateYouTubeTranscript.sh "$language" "$url" "$output_folder"
  /bin/zsh ~/PycharmProjects/Video-Tools/TranslateYouTubeTranscript.sh "$language" "$url" "$output_folder"

  echo /bin/zsh ~/PycharmProjects/Video-Tools/GenerateSpeechFromText.sh "$srt_file" "$language_names[$language]"
  /bin/zsh ~/PycharmProjects/Video-Tools/GenerateSpeechFromText.sh "$srt_file" "$language_names[$language]"

  echo /bin/zsh ~/PycharmProjects/Video-Tools/BurnSubtitlesFromSRT.sh "$new_novocals_file" "$srt_file"
  /bin/zsh ~/PycharmProjects/Video-Tools/BurnSubtitlesFromSRT.sh "$new_novocals_file" "$srt_file"

  echo /bin/zsh ~/PycharmProjects/Video-Tools/MergeVideoAndAudio.sh "$subtitled_file" "$wav_file"
  /bin/zsh ~/PycharmProjects/Video-Tools/MergeVideoAndAudio.sh "$subtitled_file" "$wav_file"

done