#!/bin/zsh

unameOut="$(uname -s)"
case "${unameOut}" in
    Linux*)     machine=Linux;;
    Darwin*)    machine=Mac;;
    CYGWIN*)    machine=Cygwin;;
    MINGW*)     machine=MinGw;;
    *)          machine="UNKNOWN:${unameOut}"
esac

echo "${machine}"
input_folder="$1"

declare -A voices=(
	["ar"]="maged"
	["en"]="alex"
	["hi"]="neel"
	["id"]="damayanti"
	["zh-Hans"]="tingting"
	["es"]="carlos"
	["de"]="markus"
)

# Sort languages to alphabetical order
joined=$(printf ", \"%s\"" $(echo "${(@k)voices}" | tr " " "\n" | sort | tr "\n" " "))
echo "${joined:2}"

##############################################################################
#  Prompt for input folder
###############################################################################
if ! [ -d "$input_folder" ]; then
    if [[ "$machine" == "Mac" ]]; then
        input_folder=$(osascript -e 'tell application (path to frontmost application as text)
        set input_folder to choose folder with prompt "Please choose an input folder"
        POSIX path of input_folder
        end')
    elif [[ "$machine" == "Linux" ]]; then
        input_folder=$(dialog --title "Choose a folder" --stdout --title "Please choose an input folder" --fselect ~/ 14 48)
    elif [[ "$machine" == "Cygwin" ]]; then
        input_folder=$(dialog --title "Choose a folder" --stdout --title "Please choose an input folder" --fselect ~/ 14 48)
    else
        echo "Usage: $0 input_file input_folder format"
        exit 1
    fi
fi

if ! [ -d "$input_folder" ]; then
  echo "Usage: $0 input_folder"
  exit 1
fi

# Remove trailing slash for path
input_folder="${input_folder%/}"

###################################
#  Process each input folder file
###################################
IFS=$'\n'

for filename in $(find $input_folder -name '*.srt'); do

    file="${filename##*/}"
    file="${file%.*}"

    language="${filename##*_}"
    language="${language%.*}"

    # Construct output file name
    output_file="${filename%.*}.wav"

    voice=${voices[$language]}

  if ! [ -f "$output_file" ]; then
    echo python3 GenerateSpeechFromText.py --input_file "$filename" --output_file "$output_file" --voice "$voice"
    python3 GenerateSpeechFromText.py --input_file "$filename" --output_file "$output_file" --voice "$voice"
    # Kill to prevent hangs from mullitple calls
    killall com.apple.speech.speechsynthesisd
  else
    echo "Skipping $output_file"
  fi

done