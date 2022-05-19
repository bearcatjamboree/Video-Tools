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
out_w="$2"
out_h="$3"
x="$4"
y="$5"

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
        echo "Usage: $0 input_file out_w out_h x y"
        exit 1
    fi
fi

if ! [ -f "$input_file" ]; then
  echo "Usage: $0 input_file out_w out_h x y"
  exit 1
fi

##############################################################################
# Prompt for out_w
###############################################################################
if [[ "$out_w" == "" ]]; then
    if [[ "$machine" == "Mac" ]]; then
        out_w=$(osascript -e 'set T to text returned of (display dialog "Enter the width of the output rectangle: " buttons {"Cancel", "OK"} default button "OK" default answer "")')
    elif [[ "$machine" == "Linux" ]]; then
        out_w=$(dialog --title "Enter the width of the output rectangle: " --inputbox "out_w:" 8 60)
    elif [[ "$machine" == "Cygwin" ]]; then
        out_w=$(dialog --title "Enter the width of the output rectangle: " --inputbox "out_w:" 8 60)
    elif [ "$#" -ne 2 ] || ! [ -f "$output_folder" ]; then
        echo "Usage: $0 input_file out_w out_h x y"
        exit 1
    fi
fi

if [[ "$out_w" == "" ]]; then
    echo "Usage: $0 input_file out_w out_h x y"
    exit 1
fi

##############################################################################
# Prompt for out_h
###############################################################################
if [[ "$out_h" == "" ]]; then
    if [[ "$machine" == "Mac" ]]; then
        out_h=$(osascript -e 'set T to text returned of (display dialog "Enter the height of the output rectangle:" buttons {"Cancel", "OK"} default button "OK" default answer "")')
    elif [[ "$machine" == "Linux" ]]; then
        out_h=$(dialog --title "Enter the height of the output rectangle:" --inputbox "out_h:" 8 60)
    elif [[ "$machine" == "Cygwin" ]]; then
        out_h=$(dialog --title "Enter the height of the output rectangle:" --inputbox "out_h:" 8 60)
    elif [ "$#" -ne 2 ] || ! [ -f "$output_folder" ]; then
        echo "Usage: $0 input_file out_w out_h x y"
        exit 1
    fi
fi

if [[ "$out_h" == "" ]]; then
    echo "Usage: $0 input_file out_w out_h x y"
    exit 1
fi

##############################################################################
# Prompt for x
###############################################################################
if [[ "$x" == "" ]]; then
    if [[ "$machine" == "Mac" ]]; then
        x=$(osascript -e 'set T to text returned of (display dialog "Enter the top left corner X-position:" buttons {"Cancel", "OK"} default button "OK" default answer "")')
    elif [[ "$machine" == "Linux" ]]; then
        x=$(dialog --title "Enter the top left corner X-position:" --inputbox "x:" 8 60)
    elif [[ "$machine" == "Cygwin" ]]; then
        x=$(dialog --title "Enter the top left corner X-position:" --inputbox "x:" 8 60)
    elif [ "$#" -ne 2 ] || ! [ -f "$output_folder" ]; then
        echo "Usage: $0 input_file out_w out_h x y"
        exit 1
    fi
fi

if [[ "$x" == "" ]]; then
    echo "Usage: $0 input_file out_w out_h x y"
    exit 1
fi

##############################################################################
# Prompt for y
###############################################################################
if [[ "$y" == "" ]]; then
    if [[ "$machine" == "Mac" ]]; then
        y=$(osascript -e 'set T to text returned of (display dialog "Enter the top left corner Y-position:" buttons {"Cancel", "OK"} default button "OK" default answer "")')
    elif [[ "$machine" == "Linux" ]]; then
        y=$(dialog --title "Enter the top left corner Y-position:" --inputbox "y:" 8 60)
    elif [[ "$machine" == "Cygwin" ]]; then
        y=$(dialog --title "Enter the top left corner Y-position:" --inputbox "y:" 8 60)
    elif [ "$#" -ne 2 ] || ! [ -f "$output_folder" ]; then
        echo "Usage: $0 input_file out_w out_h x y"
        exit 1
    fi
fi

if [[ "$y" == "" ]]; then
    echo "Usage: $0 input_file out_w out_h x y"
    exit 1
fi

re='^[0-9]+$'
input=( "$out_w" "$out_h" "$x" "$y" )

for i in "${input[@]}"
do
  if ! [[ $i =~ $re ]] ; then
     echo "Error: \"$i\" is not a number" >&2; exit 1
  fi
done

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
outfile="$name"_cropped
newoutfile=$outfile.$ext

ffmpeg -i "$input_file" -filter:v "crop=$out_w:$out_h:$x:$y" "$newoutfile"