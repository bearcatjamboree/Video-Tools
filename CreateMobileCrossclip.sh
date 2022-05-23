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
    else
        echo "Usage: $0 input_file out_w out_h x y"
        exit 1
    fi
fi

if ! [ -f "$input_file" ]; then
  echo "Usage: $0 input_file out_w out_h x y"
  exit 1
fi

# Get video resolution for switch w/h to h/w
video_res=$(ffprobe -v error -select_streams v:0 -show_entries stream=width,height -of csv=s=x:p=0 "$input_file")
array=($(sed 'y/x/ /' <<<"$video_res"))

new_width="${array[2]}"
new_height="${array[1]}"

echo "$new_width"
echo "$new_height"

##############################################################################
# Prompt for out_w
###############################################################################
if [[ "$out_w" == "" ]]; then
    if [[ "$machine" == "Mac" ]]; then
        out_w=$(osascript -e 'set T to text returned of (display dialog "Enter the width of the _output rectangle: " buttons {"Cancel", "OK"} default button "OK" default answer "400")')
    elif [[ "$machine" == "Linux" ]]; then
        out_w=$(dialog --title "Enter the width of the output rectangle: " --inputbox "out_w:" 8 60)
    elif [[ "$machine" == "Cygwin" ]]; then
        out_w=$(dialog --title "Enter the width of the output rectangle: " --inputbox "out_w:" 8 60)
    elif [ "$#" -ne 2 ] || ! [ -f "$input_file" ]; then
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
        out_h=$(osascript -e 'set T to text returned of (display dialog "Enter the height of the _output rectangle:" buttons {"Cancel", "OK"} default button "OK" default answer "200")')
    elif [[ "$machine" == "Linux" ]]; then
        out_h=$(dialog --title "Enter the height of the output rectangle:" --inputbox "out_h:" 8 60)
    elif [[ "$machine" == "Cygwin" ]]; then
        out_h=$(dialog --title "Enter the height of the output rectangle:" --inputbox "out_h:" 8 60)
    elif [ "$#" -ne 2 ] || ! [ -d "$output_folder" ]; then
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
        x=$(osascript -e 'set T to text returned of (display dialog "Enter the top left corner X-position:" buttons {"Cancel", "OK"} default button "OK" default answer "880")')
    elif [[ "$machine" == "Linux" ]]; then
        x=$(dialog --title "Enter the top left corner X-position:" --inputbox "x:" 8 60)
    elif [[ "$machine" == "Cygwin" ]]; then
        x=$(dialog --title "Enter the top left corner X-position:" --inputbox "x:" 8 60)
    elif [ "$#" -ne 2 ] || ! [ -d "$output_folder" ]; then
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
        y=$(osascript -e 'set T to text returned of (display dialog "Enter the top left corner Y-position:" buttons {"Cancel", "OK"} default button "OK" default answer "320")')
    elif [[ "$machine" == "Linux" ]]; then
        y=$(dialog --title "Enter the top left corner Y-position:" --inputbox "y:" 8 60)
    elif [[ "$machine" == "Cygwin" ]]; then
        y=$(dialog --title "Enter the top left corner Y-position:" --inputbox "y:" 8 60)
    elif [ "$#" -ne 2 ] || ! [ -d "$output_folder" ]; then
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

outfile="$name"_test
newoutfile=$outfile.$ext

####################################
# Make temp directory
####################################
tmp_dir=$(mktemp -d -t ci-$(date +%Y-%m-%d-%H-%M-%S)-XXXXXXXXXX)

##############################################################################
# Check for voice to use
###############################################################################
if [[ "$style" == "" ]]; then
  if [[ "$machine" == "Mac" ]]; then
      style=$(osascript -e 'return choose from list { "Basic", "Bubble" }')
  elif [[ "$machine" == "Linux" ]]; then
      style=$(dialog --title "Select video style" --stdout --title "Please choose a file to process" --menubox /tmp/ 14 48)
  elif [[ "$machine" == "Cygwin" ]]; then
      style=$(dialog --title "Select video style" --stdout --title "Please choose a file to process" --menubox /tmp/ 14 48)
  else
      echo "Unknown platform"
      exit 1
  fi
fi

if [[ "$style" == "Basic" ]]; then

    # Create top clip
    ffmpeg -i "$input_file" -filter:v "crop=$out_w:$out_h:$x:$y" "$tmp_dir/tmp1.mp4"
    ffmpeg -i "$tmp_dir/tmp1.mp4" -vf scale=$new_width:-2 "$tmp_dir/top.mp4"

    # Create bottom clip
    #ffmpeg -i "$input_file" -vf pad="in_w:in_h+200:0:0" "$tmp_dir/tmp1.mp4"
    ffmpeg -i "$input_file" -vf scale=-2:$new_height "$tmp_dir/tmp2.mp4"
    ffmpeg -i "$tmp_dir/tmp2.mp4" -vf "crop=$new_width:$new_height" "$tmp_dir/bottom.mp4"

    ffmpeg -i "$tmp_dir/top.mp4" -i "$tmp_dir/bottom.mp4" -filter_complex vstack=inputs=2 "$newoutfile"

    rm -rf $tmp_dir

elif [[ "$style" == "Bubble" ]]; then

    ffmpeg -i "$input_file" -filter:v "crop=$out_w:$out_h:$x:$y" "$tmp_dir/top.mp4"

    # Create bottom clip
    ffmpeg -i "$input_file" -vf pad="in_w:in_h:0:0+200" "$tmp_dir/tmp1.mp4"
    ffmpeg -i "$tmp_dir/tmp1.mp4" -vf scale=-2:$new_height "$tmp_dir/tmp2.mp4"
    ffmpeg -i "$tmp_dir/tmp2.mp4" -vf "crop=$new_width:$new_height" "$tmp_dir/bottom.mp4"

    ffmpeg \
    -i "$tmp_dir/bottom.mp4" \
    -i "$tmp_dir/top.mp4" \
    -filter_complex "\
    [1]format=yuva444p,geq=lum='p(X,Y)':a='st(1,pow(min(W/2,H/2),2))+st(3,pow(X-(W/2),2)+pow(Y-(H/2),2));if(lte(ld(3),ld(1)),255,0)'[circular shaped video];\
    [circular shaped video]scale=w=-1:h=300[circular shaped video small];\
    [0][circular shaped video small]overlay" \
    -filter_complex_threads 1 \
    -map 0:a \
    -metadata:s:a:0 title="Sound main movie" \
    -disposition:a:0 default \
    -map 1:a \
    -metadata:s:a:1 title="Sound overlayed movie" \
    -disposition:a:1 none \
    -c:v libx264 \
    -preset ultrafast \
    -shortest \
    "$newoutfile"

else
    echo "Unknown style"
    exit 1
fi

rm -rf $tmp_dir
exit 1