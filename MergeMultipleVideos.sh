#!/bin/sh
#================================================================================
#  AUTHOR
#    Clint Box
#    https://www.youtube.com/bearcatjamboree
#
#   FUNCTION
#     Combine multiple videos into a single combined video ordered by the names of the input videos.
#
#   DETAILS
#     This script loop through a folder of mp4 files and builds a video file list and then
#     uses FFMPEG to produce a single output video of all videos concatenated together
#
#   USAGE
#     ${SCRIPT_NAME} "<path to input *.mp4>" "<output folder>"
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
output_folder="$2"

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
  echo "Usage: $0 input_folder output_folder"
  exit 1
fi

# Remove trailing slash for path
input_folder="${input_folder%/}"

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
        echo "Usage: $0 input_file output_folder format"
        exit 1
    fi
fi

if ! [ -d "$output_folder" ]; then
  echo "Usage: $0 input_folder output_folder"
  exit 1
fi

# Remove trailing slash for path
output_folder="${output_folder%/}"

# Make temp directory
tmp_dir=$(mktemp -d -t ci-$(date +%Y-%m-%d-%H-%M-%S)-XXXXXXXXXX)

###########################################################################
# Standardize the audio frequence and then build list of videos to combine
###########################################################################
IFS=$'\n'

for filename in $(find $input_folder -name '*.mp4'); do

  # Get filiename pieces
  file="${filename##*/}"
  ext="${file##*.}"

  ffmpeg -i $filename -af "aformat=sample_rates=48000" -c:v copy $output_folder/fix_$file
  #ffmpeg -i "$output_folder/fix_$file" -vf scale=720:-1 "$output_folder/$file"

  mv $output_folder/fix_$file $output_folder/$file
  echo "file '$output_folder/$file'" >> $tmp_dir/file_list.txt;

  #uncomment to added meme clip
  #echo "file '$output_folder/bigbrainmeme.mp4'" >> $tmp_dir/file_list.txt;

done

###########################################################################
# Combine output files into one video
###########################################################################
ffmpeg -loglevel error -f concat -safe 0 -i $tmp_dir/file_list.txt -c copy "$output_folder/Combined.$ext"

# Cleanup
rm -rf $tmp_dir