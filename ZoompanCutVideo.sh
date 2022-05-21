#!/bin/sh

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
width="$2"

##############################################################################
# Check for file was passed.  Show open file dialog if no argument and on Mac
###############################################################################
if ! [ -f "$input_file" ]; then
    if [[ "$machine" == "Mac" ]]; then
        input_file=$(osascript -e 'tell application (path to frontmost application as text)
        set input_file to choose file with prompt "Please choose a video file to process"
        POSIX path of input_file
        end')
    elif [[ "$machine" == "Linux" ]]; then
        input_file=$(dialog --title "Choose a file" --stdout --title "Please choose a file to process" --fselect /tmp/ 14 48)
    elif [[ "$machine" == "Cygwin" ]]; then
        input_file=$(dialog --title "Choose a file" --stdout --title "Please choose a file to process" --fselect /tmp/ 14 48)
    elif [ "$#" -ne 1 ] || ! [ -f "$input_file" ]; then
        echo "Usage: $0 input_file width"
        exit 1
    fi
fi

if ! [ -f "$input_file" ]; then
  echo "Usage: $0 $input_file width"
  exit 1
fi

##############################################################################
# Prompt for block_time
###############################################################################
if [[ "$block_time" == "" ]]; then
    if [[ "$machine" == "Mac" ]]; then
        block_time=$(osascript -e 'set T to text returned of (display dialog "Enter the block_time (seconds from begin to end of each zoom cut):" buttons {"Cancel", "OK"} default button "OK" default answer "")')
    elif [[ "$machine" == "Linux" ]]; then
        block_time=$(dialog --title "Enter the block_time (seconds from begin to end of each zoom cut):" --inputbox "block_time:" 8 60)
    elif [[ "$machine" == "Cygwin" ]]; then
        block_time=$(dialog --title "Enter the block_time (seconds from begin to end of each zoom cut):" --inputbox "block_time:" 8 60)
    elif [ "$#" -ne 2 ] || ! [ -f "$input_file" ]; then
        echo "Usage: $0 input_file block_time"
        exit 1
    fi
fi

re='^[0-9]+$'

if ! [[ $block_time =~ $re ]] ; then
   echo "Error: \"$block_time\" is not a number" >&2; exit 1
fi

##############################################################################
# Prompt for zoom_time
###############################################################################
if [[ "$zoom_time" == "" ]]; then
    if [[ "$machine" == "Mac" ]]; then
        zoom_time=$(osascript -e 'set T to text returned of (display dialog "Enter the hold time (seconds) of each zoom cut:" buttons {"Cancel", "OK"} default button "OK" default answer "")')
    elif [[ "$machine" == "Linux" ]]; then
        zoom_time=$(dialog --title "Enter the hold time (seconds) of each zoom cut:" --inputbox "zoom_time:" 8 60)
    elif [[ "$machine" == "Cygwin" ]]; then
        zoom_time=$(dialog --title "Enter the hold time (seconds) of each zoom cut:" --inputbox "zoom_time:" 8 60)
    elif [ "$#" -ne 2 ] || ! [ -f "$input_file" ]; then
        echo "Usage: $0 input_file zoom_time"
        exit 1
    fi
fi

re='^[0-9]+$'

if ! [[ $zoom_time =~ $re ]] ; then
   echo "Error: \"$zoom_time\" is not a number" >&2; exit 1
fi

##############################################################################
# Prompt for zoom_scale
###############################################################################
if [[ "$zoom_scale" == "" ]]; then
    if [[ "$machine" == "Mac" ]]; then
        zoom_scale=$(osascript -e 'set T to text returned of (display dialog "Enter new video zoom_scale (aspect ratio will be retained):" buttons {"Cancel", "OK"} default button "OK" default answer "")')
    elif [[ "$machine" == "Linux" ]]; then
        zoom_scale=$(dialog --title "Enter new video zoom_scale (aspect ratio will be retained)" --inputbox "zoom_scale:" 8 60)
    elif [[ "$machine" == "Cygwin" ]]; then
        zoom_scale=$(dialog --title "Enter new video zoom_scale (aspect ratio will be retained)" --inputbox "zoom_scale:" 8 60)
    elif [ "$#" -ne 2 ] || ! [ -f "$input_file" ]; then
        echo "Usage: $0 input_file zoom_scale"
        exit 1
    fi
fi

if [[ "$zoom_scale" -lt "1" ]] ; then
   echo "Error: Zoom scale must be between 1 and 10" >&2; exit 1
fi

# get frame rate from ffmpeg
frame_rate=$(ffmpeg -i "$input_file" 2>&1 | sed -n "s/.*, \(.*\) fp.*/\1/p")
video_res=$(ffprobe -v error -select_streams v:0 -show_entries stream=width,height -of csv=s=x:p=0 "$input_file")

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
outfile="$name"_zoomcut
newoutfile=$outfile.$ext

ffmpeg -r $frame_rate -i "$input_file" -vf "zoompan=s=$video_res:z='if(lte(mod(time,$block_time),$zoom_time),$zoom_scale,1)':d=1:x=iw/$zoom_scale-(iw/zoom/$zoom_scale):y=ih/$zoom_scale-(ih/zoom/$zoom_scale):fps=$frame_rate" "$newoutfile"