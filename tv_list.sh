#!/bin/bash

source ./functions/title.sh
source ./functions/year.sh
source ./functions/resolution.sh
source ./functions/release_type.sh

# Import .env vars
if [ ! -e .env ]; then
    echo >&2 "Please configure the .env file"
    exit 1
fi
set -o allexport
source .env
set +o allexport

extensions=( m2ts webm mkv flv vob ogv ogg rrc gifv mng mov avi qt wmv yuv asf amv mp4 m4p m4v mpg mp2 mpeg mpe mpv m4v svi 3gp 3g2 mxf roq nsv flv f4v f4p f4a f4b mod )

dir=$1

# Create a regex of the extensions for the find command
extensions_re="\\("${extensions[0]}
for t in "${extensions[@]:1:${#extensions[*]}}"; do
    extensions_re="${extensions_re}\\|${t}"
done
extensions_re="${extensions_re}\\)"

# Set the field seperator to newline instead of space
saveifs=$IFS
IFS=$(echo -en "\n\b")

output=""

# Generate output from path and size using: $(stat -c "%s" filepath)
for f in $(find ${dir} -type f -regex ".*\.${extensions_re}"); do
    size=$(stat -c "%s" "${f}")
    size_k=$(echo "scale=2; ${size} / 1024" | bc -l)
    size_m=$(echo "scale=2; ${size_k} / 1024" | bc -l)
    sizeG=$(echo "scale=2; ${size_m} / 1024" | bc -l)
    filename=$(echo "${f##*/}")
    episode=$(echo "$filename" | sed -r 's/^.*S[0-9]{2}E([0-9]{2}).*$/\1/I' | sed -r 's/\./\ /g')
    season=""
    [ "$episode" == "01" ] && season=$(echo "$filename" | sed -r 's/^.*S([0-9]{2})E[0-9]{2}.*$/\1/I')
    SERIES=""
    [ "$season" == "01" ] && SERIES=$(title $filename)
    resolution=$(resolution $filename $f $detect_resolution)
    year=$(year $filename)
    release_type=$(release_type $filename)
    output=$(echo "\"$SERIES\",$year,$season,$episode,$resolution,$release_type,$size_g,$size_m,\"$filename\";"$output)
done

# Generate disk usage stats
IFS='
' # split on newline only. Also IFS=$'\n' in bash/ksh93/zsh/mksh
set -o noglob  # disable globbin
disk_usage=($(df -h --output=size,used,avail $dir | column -t))
output="Series,Year,Season,Episode,Resolution,Release Type,Size (GB),Size (MB),Filename;"$output
output=$(echo "${disk_usage[1]}" | sed -e "s/ /,/g" | sed -e "s/,,/,/g")";;"$output
output=$(echo "${disk_usage[0]}" | sed -e "s/ /,/g" | sed -e "s/,,/,/g")";"$output

# Reset IFS
IFS=$saveifs

# Reverse numeric sort the output and replace ; with \n for printing
echo $output | tr ';' '\n'

