#!/bin/sh
#================================================================================
#  AUTHOR
#    Clint Box
#    https://www.youtube.com/bearcatjamboree
#
#   FUNCTION
#     Burn subtitles from SRT file to a specified video
#
#   DETAILS
#     This script will invoke ffmpeg with parameters required to take an input
#     video and burn subtitles to a video from a specific .SRT file
#
#   USAGE
#     ${SCRIPT_NAME} "video_path" "srt_path"
#
#   NOTE
#     change strings below to your default: font, font size, and font color
#================================================================================
subtitle_font="Komika Axis"
subtitle_fontsize=48
subtitle_fontcolor="ffffff"

unameOut="$(uname -s)"
case "${unameOut}" in
    Linux*)     machine=Linux;;
    Darwin*)    machine=Mac;;
    CYGWIN*)    machine=Cygwin;;
    MINGW*)     machine=MinGw;;
    *)          machine="UNKNOWN:${unameOut}"
esac

echo "${machine}"
video_file="$1"
srt_file="$2"

##############################################################################
# Check for file was passed.  Show open file dialog if no argument and on Mac
###############################################################################
if ! [ -f "$video_file" ]; then
    if [[ "$machine" == "Mac" ]]; then
        video_file=$(osascript -e 'tell application (path to frontmost application as text)
        set video_file to choose file with prompt "Please choose a video file to process"
        POSIX path of video_file
        end')
    elif [[ "$machine" == "Linux" ]]; then
        video_file=$(dialog --title "Choose a file" --stdout --title "Please choose a file to process" --fselect ~/ 14 48)
    elif [[ "$machine" == "Cygwin" ]]; then
        video_file=$(dialog --title "Choose a file" --stdout --title "Please choose a file to process" --fselect ~/ 14 48)
    elif [ "$#" -ne 1 ] || ! [ -f "$video_file" ]; then
        echo "Usage: $0 video_file srt_file"
        exit 1
    fi
fi

if ! [ -f "$video_file" ]; then
  echo "Usage: $0 video_file srt_file"
  exit 1
fi

##############################################################################
# Check for file was passed.  Show open file dialog if no argument and on Mac
###############################################################################
if ! [ -f "$srt_file" ]; then
    if [[ "$machine" == "Mac" ]]; then
        srt_file=$(osascript -e 'tell application (path to frontmost application as text)
        set srt_file to choose file with prompt "Please select SRT file"
        POSIX path of srt_file
        end')
    elif [[ "$machine" == "Linux" ]]; then
        srt_file=$(dialog --title "Choose a file" --stdout --title "Please choose a file to process" --fselect ~/ 14 48)
    elif [[ "$machine" == "Cygwin" ]]; then
        srt_file=$(dialog --title "Choose a file" --stdout --title "Please choose a file to process" --fselect ~/ 14 48)
    elif [ "$#" -ne 1 ] || ! [ -f "$srt_file" ]; then
        echo "Usage: $0 video_file srt_file"
        exit 1
    fi
fi

if ! [ -f "$srt_file" ]; then
  echo "Usage: $0 video_file srt_file"
  exit 1
fi

####################################
# Remove backlashes from filepaths
####################################
file=$(echo "$video_file"|tr -d '\\')

####################################
# Separate file name from extension
####################################
ext="${file##*.}"
name="${file%.*}"

############################
# Get file path information
############################
outfile="$name"_subtitled
output_video=$outfile.$ext

#ffmpeg -i "$video_file" -vf "subtitles=\'$srt_file\':force_style='FontName=$subtitle_font,Fontsize=$subtitle_fontsize,PrimaryColour=&H$subtitle_fontcolor&'" "$output_video"
ffmpeg -i "$video_file" -filter_complex "subtitles=\'$srt_file\':force_style='FontName=$subtitle_font,Fontsize=$subtitle_fontsize,PrimaryColour=&H$subtitle_fontcolor&'" "$output_video"