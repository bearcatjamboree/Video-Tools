#!/bin/sh
#================================================================================
#  AUTHOR
#    Clint Box
#    https://www.youtube.com/bearcatjamboree
#
#   FUNCTION
#     Implement audio jump cut against a folder of mp4 files to generate a single
#     game highlights video
#
#   DETAILS
#     This script loop through a folder of mp4 files and execute Jumpcutter using
#     the audio jump cut method.  After execution of loop, all outputs will be
#     merged into a single highlights video.
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

###################################
#  Process each input folder file
###################################
for filename in $input_folder/*.*; do

    # Get filiename pieces
    file="${filename##*/}"
    ext="${file##*.}"
    name=""${file%.*}"_highlights"

    # Construct output file name
    output_name="$output_folder/$name.$ext"

    python VideoJumpcutter.py --input_file "$filename" --output_file "$output_name" --audio_method 1 --volume_selection "max" --audio_threshold 0.90 --frame_margin 600

done

# Make temp directory
tmp_dir=$(mktemp -d -t ci-$(date +%Y-%m-%d-%H-%M-%S)-XXXXXXXXXX)

###########################################################################
# Standardize the audio frequence and then build list of videos to combine
###########################################################################
for filename in $output_folder/*_highlights.*; do
  file="${filename##*/}"
  ffmpeg -i $filename -af "aformat=sample_rates=48000" -c:v copy $output_folder/fix_$file
  mv $output_folder/fix_$file $output_folder/$file
  echo "file '$output_folder/$file'" >> $tmp_dir/file_list.txt;
done

###########################################################################
# Combine output files into one video
###########################################################################
ffmpeg -loglevel error -f concat -safe 0 -i $tmp_dir/file_list.txt -c copy "$output_folder/Highlights.$ext"

# Cleanup
rm -rf $tmp_dir