#!/bin/sh

#
# this script requires spleeter environment be active before starting
# to start spleeter simply type:
#
#   conda activate spleeter
#
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
        input_file=$(dialog --title "Choose a file" --stdout --title "Please choose a file to process" --fselect ~/ 14 48)
    elif [[ "$machine" == "Cygwin" ]]; then
        input_file=$(dialog --title "Choose a file" --stdout --title "Please choose a file to process" --fselect ~/ 14 48)
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

outfile="$name"_vocals
tmpfile="$name"_tmp

newoutfile=$outfile.$ext

input_file="$file"

####################################
# Make temp directory
####################################
tmp_dir=$(mktemp -d -t ci-$(date +%Y-%m-%d-%H-%M-%S)-XXXXXXXXXX)

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
ffmpeg -i "$tmpfile.aac"  -c:a flac -f segment -segment_time 600 $tmp_dir/input.%03d.flac

##################################
# Process each 10 minute file
##################################
for filename in $tmp_dir/*.flac; do
    spleeter separate -p spleeter:2stems -d 600 -o $tmp_dir "$filename"
done

rm $tmp_dir/file_list.txt

##################################
# Merges files back together
##################################
for filename in $tmp_dir/input.*/vocals.wav; do
    echo "file '$filename'" >> $tmp_dir/file_list.txt;
done

ffmpeg -f concat -safe 0 -i $tmp_dir/file_list.txt -c copy "$tmpfile.wav"

ffmpeg -i "$tmpfile.$ext" -i "$tmpfile.wav" -c:v copy -c:a aac "$newoutfile"

rm "$tmpfile.$ext" "$tmpfile.wav" "$tmpfile.aac"
rm -rf $tmp_dir