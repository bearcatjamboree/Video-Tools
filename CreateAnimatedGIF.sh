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
start="$2"
duration="$3"
width="$4"

##############################################################################
# Check for file was passed.  Show open file dialog if no argument and on Mac
###############################################################################
if ! [ -f "$input_file" ]; then
    if [[ "$machine" == "Mac" ]]; then
        input_file=$(osascript -e 'tell application (path to frontmost application as text)
        set input_file to choose file with prompt "Please choose a file to process"
        POSIX path of input_file
        end')
    elif [[ "$machine" == "Linux" ]]; then
        input_file=$(dialog --title "Choose a file" --stdout --title "Please choose a file to process" --fselect /tmp/ 14 48)
    elif [[ "$machine" == "Cygwin" ]]; then
        input_file=$(dialog --title "Choose a file" --stdout --title "Please choose a file to process" --fselect /tmp/ 14 48)
    elif [ "$#" -ne 1 ] || ! [ -f "$input_file" ]; then
        echo "Usage: $0 input_file start duration width"
        exit 1
    fi
fi

if ! [ -f "$input_file" ]; then
  echo "Usage: $0 input_file start duration width"
  exit 1
fi

##############################################################################
# Prompt for start
###############################################################################
if [[ "$start" == "" ]]; then
    if [[ "$machine" == "Mac" ]]; then
        start=$(osascript -e 'set T to text returned of (display dialog "Start Time [hh:mm:ss]: " buttons {"Cancel", "OK"} default button "OK" default answer "")')
    elif [[ "$machine" == "Linux" ]]; then
        start=$(dialog --title "Start Time [hh:mm:ss]: " --inputbox "start:" 8 60)
    elif [[ "$machine" == "Cygwin" ]]; then
        start=$(dialog --title "Start Time [hh:mm:ss]: " --inputbox "start:" 8 60)
    elif [ "$#" -ne 2 ] || ! [ -f "$input_file" ]; then
        echo "Usage: $0 input_file start duration width"
        exit 1
    fi
fi

if [[ "$start" == "" ]] ; then
  echo "Usage: $0 input_file start duration width"
  exit 1
fi

echo 'Clip Duration [hh:mm:ss]: '

##############################################################################
# Prompt for duration
###############################################################################
if [[ "$duration" == "" ]]; then
    if [[ "$machine" == "Mac" ]]; then
        duration=$(osascript -e 'set T to text returned of (display dialog "Clip Duration [hh:mm:ss]: " buttons {"Cancel", "OK"} default button "OK" default answer "")')
    elif [[ "$machine" == "Linux" ]]; then
        duration=$(dialog --title "Clip Duration [hh:mm:ss]: " --inputbox "duration:" 8 60)
    elif [[ "$machine" == "Cygwin" ]]; then
        duration=$(dialog --title "Clip Duration [hh:mm:ss]: " --inputbox "duration:" 8 60)
    elif [ "$#" -ne 2 ] || ! [ -d "$output_folder" ]; then
        echo "Usage: $0 input_file start duration width"
        exit 1
    fi
fi

if [[ "$duration" == "" ]] ; then
  echo "Usage: $0 input_file start duration width"
  exit 1
fi

##############################################################################
# Prompt for width
###############################################################################
if [[ "$width" == "" ]]; then
    if [[ "$machine" == "Mac" ]]; then
        width=$(osascript -e 'set T to text returned of (display dialog "Clip width:" buttons {"Cancel", "OK"} default button "OK" default answer "")')
    elif [[ "$machine" == "Linux" ]]; then
        width=$(dialog --title "Clip width:" --inputbox "width:" 8 60)
    elif [[ "$machine" == "Cygwin" ]]; then
        width=$(dialog --title "Clip width:" --inputbox "width:" 8 60)
    elif [ "$#" -ne 2 ] || ! [ -d "$output_folder" ]; then
        echo "Usage: $0 input_file start duration width"
        exit 1
    fi
fi

if [[ "$width" == "" ]] ; then
  echo "Usage: $0 input_file start duration width"
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
outfile=$name.gif

ffmpeg -ss "$start" -t "$duration" -i "$input_file" -vf "fps=10,scale=$width:-1:flags=lanczos,split[s0][s1];[s0]palettegen[p];[s1][p]paletteuse" -loop 0 "$outfile"