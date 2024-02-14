#!/bin/bash

# fill with more extensions or have it as a cmd line arg
TYPES=( m2ts webm mkv flv vob ogv ogg rrc gifv mng mov avi qt wmv yuv asf amv mp4 m4p m4v mpg mp2 mpeg mpe mpv m4v svi 3gp 3g2 mxf roq nsv flv f4v f4p f4a f4b mod )
OUTPUT_FILE="movie_list.csv"

DIR=$1

# Create a regex of the extensions for the find command
TYPES_RE="\\("${TYPES[0]}
for t in "${TYPES[@]:1:${#TYPES[*]}}"; do
    TYPES_RE="${TYPES_RE}\\|${t}"
done
TYPES_RE="${TYPES_RE}\\)"

# Set the field seperator to newline instead of space
SAVEIFS=$IFS
IFS=$(echo -en "\n\b")

# Generate output from path and size using: `stat -c "%s" filepath`
OUTPUT=""
for f in `find ${DIR} -type f -regex ".*\.${TYPES_RE}"`; do
SIZE=`stat -c "%s" ${f}`
    SIZEK=`echo "scale=2; ${SIZE} / 1024" | bc -l`
    SIZEM=`echo "scale=2; ${SIZEK} / 1024" | bc -l`
    SIZEG=`echo "scale=2; ${SIZEM} / 1024" | bc -l`
    FILENAME=`echo "${f##*/}"`
    MOVIE_YEAR=`echo $FILENAME | sed -r 's/^[a-zA-Z\.\ ]*([0-9]{4}).*/\1/'`
    MOVIE_NAME=`echo $FILENAME | sed -r 's/[0-9]{4}.*$//' | sed -r 's/\./\ /g'`
    OUTPUT=`echo ${MOVIE_NAME},${MOVIE_YEAR},${SIZEG},${SIZEM},${FILENAME}`";"$OUTPUT
done

# Generate disk usage stats
IFS='
' # split on newline only. Also IFS=$'\n' in bash/ksh93/zsh/mksh
set -o noglob  # disable globbin
DISK_USAGE=($(df -h --output=size,used,avail $DIR | column -t))
OUTPUT="Movie,Year,Size (GB),Size (MB),Filename;"$OUTPUT
OUTPUT=`echo "${DISK_USAGE[1]}" | sed -e "s/ /,/g" | sed -e "s/,,/,/g"`";;"$OUTPUT
OUTPUT=`echo "${DISK_USAGE[0]}" | sed -e "s/ /,/g" | sed -e "s/,,/,/g"`";"$OUTPUT


# Reset IFS
IFS=$SAVEIFS

# Reverse numeric sort the output and replace ; with \n for printing
echo $OUTPUT | tr ';' '\n'

