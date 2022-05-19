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
        set input_file to choose file with prompt "Please choose a video file to process"
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

####################################
# Remove backlashes from filepaths
####################################
file=$(echo "$input_file"|tr -d '\\')

####################################
# Separate file name from extension
####################################
ext="${file##*.}"
name="${file%.*}"

outfile="$name"_novocals
tmpfile="$name"_tmp

newoutfile=$outfile.$ext

input_file="$file"

####################################
# Empty temp directory
####################################
rm -Rf temp/*

####################################
# Extract Video
####################################
ffmpeg -i "$input_file" -c copy -an "$tmpfile.$ext"

####################################
# Extract Audio
####################################
ffmpeg -i "$input_file" -vn -acodec copy "$tmpfile.aac"

####################################
# Create separate 10 minute files
####################################
ffmpeg -i "$tmpfile.aac"  -c:a flac -f segment -segment_time 600 temp/input.%03d.flac

##################################
# Process each 10 minute file
##################################
for filename in temp/*.flac; do
    spleeter separate -p spleeter:2stems -d 600 -o temp "$filename"
done

rm file_list.txt

##################################
# Merges files back together
##################################
for filename in temp/input.*/accompaniment.wav; do
    echo "file '$filename'" >> file_list.txt;
done

ffmpeg -f concat -safe 0 -i file_list.txt -c copy "$tmpfile.wav"

ffmpeg -i "$tmpfile.$ext" -i "$tmpfile.wav" -c:v copy -c:a aac "$newoutfile"

rm "$tmpfile.$ext" "$tmpfile.wav" "$tmpfile.aac"