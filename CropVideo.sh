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

##############################################################################
# Check for file was passed.  Show open file dialog if no argument and on Mac
###############################################################################
if ! [ -f "$input_file" ]; then
    if [[ "$machine" == "Mac" ]]; then
        input_file=$(osascript -e 'tell application (path to frontmost application as text)
        set input_file to choose file
        POSIX path of input_file
        end')
    elif [[ "$machine" == "Linux" ]]; then
        input_file=$(dialog --title "Choose a file" --stdout --title "Please choose a file to process" --fselect /tmp/ 14 48)
    elif [[ "$machine" == "Cygwin" ]]; then
        input_file=$(dialog --title "Choose a file" --stdout --title "Please choose a file to process" --fselect /tmp/ 14 48)
    elif [ "$#" -ne 1 ] || ! [ -f "$input_file" ]; then
        echo "Usage: $0 input_file"
        exit 1
    fi
fi

echo 'Enter the width of the output rectangle: '
read out_w

echo 'Enter the height of the output rectangle:'
read out_h

echo 'Enter the top left corner X-position:'
read x

echo 'Enter the top left corner Y-position:'
read y

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