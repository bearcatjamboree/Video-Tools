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

language="$1"
url="$2"
output_folder="$3"

declare -A languages
row=1

while IFS="|" read -r head lang code tail
do
  if [[ "$row" -gt "2" ]]; then
    lang=$(echo $lang | sed 's/^[ \t]*//;s/[ \t]*$//')
    code=$(echo $code | sed 's/^[ \t]*//;s/[ \t]*$//')
    languages[$lang]="$code"
  fi
  row=$row+1
done <  "LanguageCodes.md"

# Sort languages to alphabetical order
joined=$(printf ", \"%s\"" $(echo "${(@k)languages}" | tr " " "\n" | sort | tr "\n" " "))
#echo "${joined:2}"

##############################################################################
# Check for voice to use
###############################################################################
if [[ "$language" == "" ]]; then
  if [[ "$machine" == "Mac" ]]; then
      language=$(osascript -e 'return choose from list { '${joined:2}' }')
  elif [[ "$machine" == "Linux" ]]; then
      language=$(dialog --title "Choose a file" --stdout --title "Please choose a file to process" --fselect /tmp/ 14 48)
  elif [[ "$machine" == "Cygwin" ]]; then
      language=$(dialog --title "Choose a file" --stdout --title "Please choose a file to process" --fselect /tmp/ 14 48)
  else
      echo "Unknown platform"
      exit 1
  fi
fi

lang_code="${languages[$language]}"

##############################################################################
# Prompt for URL
###############################################################################
if [[ "$url" == "" ]]; then
    if [[ "$machine" == "Mac" ]]; then
        url=$(osascript -e 'set T to text returned of (display dialog "Enter video or playlist URL" buttons {"Cancel", "OK"} default button "OK" default answer "")')
    elif [[ "$machine" == "Linux" ]]; then
        url=$(dialog --title "Enter playlist location" --inputbox "URL:" 8 60)
    elif [[ "$machine" == "Cygwin" ]]; then
        url=$(dialog --title "Enter playlist location" --inputbox "URL:" 8 60)
    else
        echo "Usage: $0 language url output_folder"
        exit 1
    fi
fi

if [[ "$url" == "" ]]; then
    echo "Usage: $0 output_folder url"
    exit 1
fi

##############################################################################
# Prompt for _output folder
###############################################################################
if ! [ -d "$output_folder" ]; then
    if [[ "$machine" == "Mac" ]]; then
        output_folder=$(osascript -e 'tell application (path to frontmost application as text)
        set output_folder to choose folder with prompt "Please select _output folder:"
        POSIX path of output_folder
        end')
    elif [[ "$machine" == "Linux" ]]; then
        output_folder=$(dialog --title "Choose a folder" --stdout --title "Please select output folder:" --fselect /tmp/ 14 48)
    elif [[ "$machine" == "Cygwin" ]]; then
        output_folder=$(dialog --title "Choose a folder" --stdout --title "Please select output folder:" --fselect /tmp/ 14 48)
    else
        echo "Usage: $0 language url output_folder"
        exit 1
    fi
fi

if ! [ -d "$output_folder" ]; then
  echo "Usage: $0 language url output_folder"
  exit 1
fi

output_folder=${output_folder%/}

# download descriptions from all videos in playlist
yt-dlp "ytsearch:$url" --write-description --skip-download --youtube-skip-dash-manifest -o "$output_folder/%(title)s_descripton"

# rename the .descripton to .txt in the _output file names
for file in $output_folder/*.description ; do mv "$file" "${file%.*}.txt" ; done

new_output=$output_folder/$lang_code
if ! [ -d "$new_output" ]; then
  mkdir $new_output
fi
# translate each file
for file in $output_folder/*_descripton.txt ;
  do
    name="${file##*/}"
    echo "cat \"$file\" | trans -s \"en\" -b :$lang_code > \"$new_output/$name\""
    cat "$file" | trans -s "en" -b :$lang_code > "$new_output/$name"
  done