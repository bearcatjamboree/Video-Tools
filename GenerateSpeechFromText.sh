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
input_file="$1"
language="$2"

declare -A voices=(
	["Arabic"]="maged"
	["English"]="alex"
	["Hindi"]="neel"
	["Indonesian"]="damayanti"
	["Mandarin"]="tingting"
	["Spanish"]="carlos"
)

# Sort languages to alphabetical order
joined=$(printf ", \"%s\"" $(echo "${(@k)voices}" | tr " " "\n" | sort | tr "\n" " "))
echo "${joined:2}"

##############################################################################
# Check for file was passed.  Show open file dialog if no argument and on Mac
###############################################################################
if ! [ -f "$input_file" ]; then
    if [[ "$machine" == "Mac" ]]; then
        input_file=$(osascript -e 'tell application (path to frontmost application as text)
        set input_file to choose file with prompt "Please select an SRT file"
        POSIX path of input_file
        end')
    elif [[ "$machine" == "Linux" ]]; then
        input_file=$(dialog --title "Choose a file" --stdout --title "Please choose a file to process" --fselect /tmp/ 14 48)
    elif [[ "$machine" == "Cygwin" ]]; then
        input_file=$(dialog --title "Choose a file" --stdout --title "Please choose a file to process" --fselect /tmp/ 14 48)
    elif [ "$#" -ne 1 ] || ! [ -f "$input_file" ]; then
        echo "Usage: $0 input_file language"
        exit 1
    fi
fi

if ! [ -f "$input_file" ]; then
  echo "Usage: $0 input_file language"
  exit 1
fi

##############################################################################
# Check for voice to use
###############################################################################
if [[ "$language" == "" ]]; then
  if [[ "$machine" == "Mac" ]]; then
      language=$(osascript -e 'return choose from list { '${joined:2}' }')
  elif [[ "$machine" == "Linux" ]]; then
      language=$(dialog --title "Choose a file" --stdout --title "Please choose a file to process" --fselect /tmp/ 14 48)
  elif [[ "$machine" == "Cygwin" ]]; then
      language=$(dialog --title "Choose a file" --stdout --title "Please choose a file to process" --fselect /tmp/ 14 48)
  else
      echo "Unknown platform"
      exit 1
  fi
fi

if [[ "$language" == "" ]]; then
	echo "Usage: $0 input_file language"
	exit 1
fi

voice=${voices[$language]}
echo "$voice"

####################################
# Remove backlashes from filepaths
####################################
file=$(echo "$input_file"|tr -d '\\')

####################################
# Separate file name from extension
####################################
ext="${file##*.}"
name="${file%.*}"

############################
# Get file path information
############################
output_file=$name.wav

python3 GenerateSpeechFromText.py --input_file "$input_file" --output_file "$output_file" --voice "$voice"