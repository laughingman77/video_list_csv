#!/bin/bash

source ./functions/title.sh
source ./functions/year.sh
source ./functions/resolution.sh
source ./functions/version.sh
source ./functions/release_type.sh
source ./functions/table_headings.sh

# Import .env vars
if [ ! -e .env ]; then
    echo >&2 "Please configure the .env file"
    exit 1
fi
set -o allexport
source .env

extensions=( m2ts webm mkv flv vob ogv ogg rrc gifv mng mov avi qt wmv yuv asf amv mp4 m4p m4v mpg mp2 mpeg mpe mpv m4v svi 3gp 3g2 mxf roq nsv flv f4v f4p f4a f4b mod )

dir=$1

# Create a regex of the extensions for the find command
extensions_re="\\("${extensions[0]}
for t in "${extensions[@]:1:${#extensions[*]}}"; do
    extensions_re="${extensions_re}\\|${t}"
done
extensions_re="${extensions_re}\\)"

# Set the field separator to newline instead of space
saveifs=$IFS
IFS=$(echo -en "\n\b")

# Generate output from path and size using: $(stat -c "%s" filepath)
output=""
for filepath in $(find ${dir} -type f -regex ".*\.${extensions_re}"); do
    size=$(stat -c "%s" ${filepath})
    size_k=$(echo "scale=2; ${size} / 1024" | bc -l)
    size_m=$(echo "scale=2; ${size_k} / 1024" | bc -l)
    size_g=$(echo "scale=2; ${size_m} / 1024" | bc -l)
    filename=$(echo "${filepath##*/}")
    resolution=$(resolution $filename $filepath $detect_resolution)
    release_type=$(release_type $filename)
    year=$(year $filename)
    title=$(title $filename)
    version=$(version $filename)
    line=$(echo "\"$title\",$year,$resolution,\"$version\",$release_type,$size_g,$size_m,\"$filename\";")
    output=$output$line
done

# Generate disk usage stats
IFS='
' # split on newline only. Also IFS=$'\n' in bash/ksh93/zsh/mksh
set -o noglob  # disable globbin
output=$(table_headings "${movie_columns[@]}")$output
disk_usage=($(df -h --output=size,used,avail $dir | column -t))
output=";"$output
output=$(echo "${disk_usage[1]}" | sed -e "s/ /,/g" | sed -e "s/,,/,/g")";"$output
output=$(echo "${disk_usage[0]}" | sed -e "s/ /,/g" | sed -e "s/,,/,/g")";"$output

# Reset IFS
IFS=$saveifs

# Replace ; with \n for printing
echo $output | tr ';' '\n'
