#!/bin/bash

source ./functions/title.sh
source ./functions/year.sh
source ./functions/resolution.sh
source ./functions/version.sh
source ./functions/release_type.sh

# Import .env vars
if [ ! -e .env ]; then
    echo >&2 "Please configure the .env file"
    exit 1
fi
set -o allexport
source .env

EXTENSIONS=( m2ts webm mkv flv vob ogv ogg rrc gifv mng mov avi qt wmv yuv asf amv mp4 m4p m4v mpg mp2 mpeg mpe mpv m4v svi 3gp 3g2 mxf roq nsv flv f4v f4p f4a f4b mod )

DIR=$1

# Create a regex of the extensions for the find command
EXTENSIONS_RE="\\("${EXTENSIONS[0]}
for t in "${EXTENSIONS[@]:1:${#EXTENSIONS[*]}}"; do
    EXTENSIONS_RE="${EXTENSIONS_RE}\\|${t}"
done
EXTENSIONS_RE="${EXTENSIONS_RE}\\)"

# Set the field separator to newline instead of space
SAVEIFS=$IFS
IFS=$(echo -en "\n\b")

# Generate output from path and size using: $(stat -c "%s" filepath)
OUTPUT=""
for FILEPATH in $(find ${DIR} -type f -regex ".*\.${EXTENSIONS_RE}"); do
    SIZE=$(stat -c "%s" ${FILEPATH})
    SIZEK=$(echo "scale=2; ${SIZE} / 1024" | bc -l)
    SIZEM=$(echo "scale=2; ${SIZEK} / 1024" | bc -l)
    SIZEG=$(echo "scale=2; ${SIZEM} / 1024" | bc -l)
    FILENAME=$(echo "${FILEPATH##*/}")
    RESOLUTION=$(resolution $FILENAME $FILEPATH $DETECT_RESOLUTION)
    RELEASE_TYPE=$(release_type $FILENAME)
    YEAR=$(year $FILENAME)
    TITLE=$(title $FILENAME)
    VERSION=$(version $FILENAME)
    LINE=$(echo "\"$TITLE\",$YEAR,$RESOLUTION,\"$VERSION\",$RELEASE_TYPE,$SIZEG,$SIZEM,\"$FILENAME\";")
    OUTPUT=$OUTPUT$LINE
done

# Generate disk usage stats
IFS='
' # split on newline only. Also IFS=$'\n' in bash/ksh93/zsh/mksh
set -o noglob  # disable globbin
OUTPUT="Title,Year,Resolution,Version,Release Type,Size (GB),Size (MB),Filename;"$OUTPUT
DISK_USAGE=($(df -h --output=size,used,avail $DIR | column -t))
OUTPUT=";"$OUTPUT
OUTPUT=$(echo "${DISK_USAGE[1]}" | sed -e "s/ /,/g" | sed -e "s/,,/,/g")";"$OUTPUT
OUTPUT=$(echo "${DISK_USAGE[0]}" | sed -e "s/ /,/g" | sed -e "s/,,/,/g")";"$OUTPUT


# Reset IFS
IFS=$SAVEIFS

# Replace ; with \n for printing
echo $OUTPUT | tr ';' '\n'
