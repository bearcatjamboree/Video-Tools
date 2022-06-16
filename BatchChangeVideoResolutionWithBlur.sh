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
#     ${SCRIPT_NAME} "video_folder" "resolution"
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
resolution="$2"

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
        echo "Usage: $0 input_file input_folder format resolution"
        exit 1
    fi
fi

if ! [ -d "$input_folder" ]; then
  echo "Usage: $0 input_folder resolution"
  exit 1
fi

##############################################################################
# Prompt for resolution
###############################################################################
if [[ "$resolution" == "" ]]; then
    if [[ "$machine" == "Mac" ]]; then
        resolution=$(osascript -e 'set T to text returned of (display dialog "Enter new resolution (1280x720, 1920x1080, 1080x1920, etc.): " buttons {"Cancel", "OK"} default button "OK" default answer "")')
    elif [[ "$machine" == "Linux" ]]; then
        resolution=$(dialog --title "Enter new resolution (1280x720, 1920x1080, 1080x1920, etc.): " --inputbox "resolution:" 8 60)
    elif [[ "$machine" == "Cygwin" ]]; then
        resolution=$(dialog --title "Enter new resolution (1280x720, 1920x1080, 1080x1920, etc.): " --inputbox "resolution:" 8 60)
    elif [ "$#" -ne 2 ] || ! [ -f "$input_folder" ]; then
        echo "Usage: $0 input_folder resolution"
        exit 1
    fi
fi

if [[ "$resolution" == "" ]] ; then
  echo "Usage: $0 input_folder resolution"
  exit 1
fi

# Remove trailing slash for folder_path
input_folder="${input_folder%/}"

###################################
#  Process each input folder file
###################################
IFS=$'\n'

for input_file in $(find $input_folder -name '*.mp4'); do

    echo "input video: ${input_file}"

    # Construct output file name
    output_video="${input_file%.*} #short.mp4"
    echo "output video $output_video"
    #exit 1

    if ! [ -f "$output_video" ]; then
        ffmpeg -i "$input_file" -filter_complex "[0:v]boxblur=40,scale=$resolution,setsar=1[bg];[0:v]scale=$resolution:force_original_aspect_ratio=decrease[fg];[bg][fg]overlay=y=(H-h)/2" -c:a copy "$output_video"
    else
        echo "Skipping $input_file"
    fi

done