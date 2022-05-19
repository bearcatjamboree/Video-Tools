#!/bin/sh

subtitle_font="Bangers"
subtitle_fontsize=48 #48
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
        set video_file to choose file with prompt "Please select video file:"
        POSIX path of video_file
        end')
    elif [[ "$machine" == "Linux" ]]; then
        video_file=$(dialog --title "Choose a file" --stdout --title "Please choose a file to process" --fselect /tmp/ 14 48)
    elif [[ "$machine" == "Cygwin" ]]; then
        video_file=$(dialog --title "Choose a file" --stdout --title "Please choose a file to process" --fselect /tmp/ 14 48)
    elif [ "$#" -ne 1 ] || ! [ -f "$video_file" ]; then
        echo "Usage: $0 video_file srt_file"
        exit 1
    fi
fi

##############################################################################
# Check for file was passed.  Show open file dialog if no argument and on Mac
###############################################################################
if ! [ -f "$srt_file" ]; then
    if [[ "$machine" == "Mac" ]]; then
        srt_file=$(osascript -e 'tell application (path to frontmost application as text)
        set srt_file to choose file with prompt "Please select SRT file:"
        POSIX path of srt_file
        end')
    elif [[ "$machine" == "Linux" ]]; then
        srt_file=$(dialog --title "Choose a file" --stdout --title "Please choose a file to process" --fselect /tmp/ 14 48)
    elif [[ "$machine" == "Cygwin" ]]; then
        srt_file=$(dialog --title "Choose a file" --stdout --title "Please choose a file to process" --fselect /tmp/ 14 48)
    elif [ "$#" -ne 1 ] || ! [ -f "$srt_file" ]; then
        echo "Usage: $0 srt_file srt_file"
        exit 1
    fi
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


ffmpeg -i "$video_file" -vf "subtitles=\'$srt_file\':force_style='FontName=$subtitle_font,Fontsize=$subtitle_fontsize,PrimaryColour=&H$subtitle_fontcolor&'" "$output_video"