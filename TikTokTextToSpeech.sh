#!/bin/zsh
#================================================================================
#  AUTHOR
#    Clint Box
#    https://www.youtube.com/bearcatjamboree
#
#   FUNCTION
#     Produce synthesized speech file (WAV) for subtitle file
#
#   DETAILS
#     This script will take a subtitle (SRT) file as input and produce a WAV
#     file containing speech synthesized into another voice
#
#   USAGE
#     ${SCRIPT_NAME} "<input file>" "<voice>"
#
#   NOTE
#     change the voices array to the voice codes and voices you will be using
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
input_file="$1"
voice="$2"

voices=( "en_us_ghostface" "en_us_chewbacca" "en_us_c3po" "en_us_stitch" "en_us_stormtrooper" 
"en_us_rocket" "en_au_001" "en_au_002" "en_uk_001" "en_uk_003" "en_us_001" "en_us_002" "en_us_006" 
"en_us_007" "en_us_009" "en_us_010" "fr_001" "fr_002" "de_001" "de_002" "es_002" "es_mx_002" 
"br_001" "br_003" "br_004" "br_005" "id_001" "jp_001" "jp_003" "jp_005" "jp_006" "kr_002" "kr_003" 
"kr_004" "en_male_narration" "en_female_f08_salut_damour" "en_male_m03_lobby" )

joined=$(printf ", \"%s\"" $(echo "${voices}" | tr " " "\n" | sort | tr "\n" " "))

##############################################################################
# Check for file was passed.  Show open file dialog if no argument and on Mac
###############################################################################
if ! [ -f "$input_file" ]; then
    if [[ "$machine" == "Mac" ]]; then
        input_file=$(osascript -e 'tell application (path to frontmost application as text)
        set input_file to choose file with prompt "Please select an text file"
        POSIX path of input_file
        end')
    elif [[ "$machine" == "Linux" ]]; then
        input_file=$(dialog --title "Choose a file" --stdout --title "Please choose a file to process" --fselect ~/ 14 48)
    elif [[ "$machine" == "Cygwin" ]]; then
        input_file=$(dialog --title "Choose a file" --stdout --title "Please choose a file to process" --fselect ~/ 14 48)
    elif [ "$#" -ne 1 ] || ! [ -f "$input_file" ]; then
        echo "Usage: $0 voice input_file"
        exit 1
    fi
fi

if ! [ -f "$input_file" ]; then
  echo "Usage: $0 voice input_file"
  exit 1
fi

##############################################################################
# Check for voice to use
###############################################################################
if [[ "$voice" == "" ]]; then
  if [[ "$machine" == "Mac" ]]; then
      voice=$(osascript -e 'return choose from list { '${joined}' }')
  elif [[ "$machine" == "Linux" ]]; then
      voice=$(dialog --title "Choose a file" --stdout --title "Please choose a voice" --fselect ~/ 14 48)
  elif [[ "$machine" == "Cygwin" ]]; then
      voice=$(dialog --title "Choose a file" --stdout --title "Please choose a voice" --fselect ~/ 14 48)
  else
      echo "Unknown voice"
      exit 1
  fi
fi

if [[ "$voice" == "" ]]; then
	echo "Usage: $0 voice input_file"
	exit 1
fi

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
output_file=$name.mp3

python TikTokTextToSpeech.py -v "$voice" -f "$input_file" -n "$output_file"