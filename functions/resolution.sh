#!/bin/bash

# Detect the resolution off a file
# $1 filename
# $2 absolute filename path
# $3 detect resolution (0 or 1)
resolution() {
    local RESULT=$(echo $1 | grep -oP '\d+p')
    if [[ -z "$RESULT" && "$3" == 1 && -f "$2" ]]; then
        local WIDTH=$(ffprobe -v error -select_streams v -show_entries stream=width,height -of json "$2" | jq '.streams[0] .width')
        if [ -z "$WIDTH" ]; then
            RESULT=""
        else
            [ "$WIDTH" -le 7680 ] && RESULT="4320p"
            [ "$WIDTH" -le 3840 ] && RESULT="2160p"
            [ "$WIDTH" -le 1920 ] && RESULT="1080p"
            [ "$WIDTH" -le 720 ] && RESULT="720p"
            [ "$WIDTH" -le 640 ] && RESULT="480p"
        fi
    fi
    echo "$RESULT"
}
