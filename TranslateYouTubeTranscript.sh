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

lang_code="$1"
video_provided="$2"
output_folder="$3"

declare -A languages
row=1

while IFS="|" read -r head lang code tail
do
  if [[ "$row" -gt "2" ]]; then
    lang=$(echo $lang | sed 's/^[ \t]*//;s/[ \t]*$//')
    code=$(echo $code | sed 's/^[ \t]*//;s/[ \t]*$//')
    languages[$lang]="$code"
  fi
  row=$row+1
done <  "LanguageCodes.md"

# Sort languages to alphabetical order
joined=$(printf ", \"%s\"" $(echo "${(@k)languages}" | tr " " "\n" | sort | tr "\n" " "))
#echo "${joined:2}"

##############################################################################
# Check for voice to use
###############################################################################
if [[ "$lang_code" == "" ]]; then
  if [[ "$machine" == "Mac" ]]; then
      language=$(osascript -e 'return choose from list { '${joined:2}' }')
  elif [[ "$machine" == "Linux" ]]; then
      language=$(dialog --title "Choose a file" --stdout --title "Please choose a file to process" --fselect ~/ 14 48)
  elif [[ "$machine" == "Cygwin" ]]; then
      language=$(dialog --title "Choose a file" --stdout --title "Please choose a file to process" --fselect ~/ 14 48)
  else
      echo "Usage: $0 language [video URL or ID] output_folder"
      exit 1
  fi
  lang_code="${languages[$language]}"
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
    else
        echo "Usage: $0 language [video URL or ID] output_folder"
        exit 1
    fi
fi

if [[ "$video_provided" == "" ]]; then
    echo "Usage: $0 output_folder [video URL or ID]"
    exit 1
fi

video_provided="${video_provided##*v=}"
video_provided="${video_provided##*/}"
video_id="${video_provided%&*}"

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

new_output=$output_folder/$lang_code

if ! [ -d "$new_output" ]; then
  mkdir $new_output
fi

python3 TranslateYouTubeTranscript.py --video_id "$video_id" --output_folder "$new_output" --language "$lang_code"