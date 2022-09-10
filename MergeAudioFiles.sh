#!/bin/zsh
#================================================================================
#  AUTHOR
#    Clint Box
#    https://www.youtube.com/bearcatjamboree
#
#   FUNCTION
#     Merge subtitled video files with translated wav files
#
#   DETAILS
#     This script will scan recursively for *_novocals_subtitled.mp4 files
#     and attempt to locate a .wav file in the same directory.  If a _merged.mp4
#     file already exist then the script will skip the file and go on to the next
#     *_novocals_subtitled.mp4 file.
#
#   USAGE
#     ${SCRIPT_NAME} "[path to *_novocals_subtitled.mp4]"
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
input_folder="$1"

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

# Remove trailing slash for folder_path
input_folder="${input_folder%/}"

# Make temp directory
tmp_dir=$(mktemp -d -t ci-$(date +%Y-%m-%d-%H-%M-%S)-XXXXXXXXXX)

###########################################################################
# Standardize the audio frequence and then build list of videos to combine
###########################################################################
for filename in $input_folder/*.mp3; do
  file="${filename##*/}"
  echo "file '$input_folder/$file'" >> $tmp_dir/file_list.txt;
done

###########################################################################
# Combine output files into one video
###########################################################################
ffmpeg -loglevel error -f concat -safe 0 -i $tmp_dir/file_list.txt -c copy "$input_folder/merged.mp3"

# Cleanup
rm -rf $tmp_dir