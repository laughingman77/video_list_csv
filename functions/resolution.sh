#!/bin/bash

# Detect the resolution off a file
# $1 filename
# $2 absolute filename path
# $3 detect resolution (0 or 1)
resolution() {
    local result=$(echo $1 | grep -oP '\d+p')
    if [[ -z "$result" && "$3" == 1 && -f "$2" ]]; then
        local width=$(ffprobe -v error -select_streams v -show_entries stream=width,height -of json "$2" | jq '.streams[0] .width')
        if [ -z "$width" ]; then
            result=""
        else
            [ "$width" -le 7680 ] && result="4320p"
            [ "$width" -le 3840 ] && result="2160p"
            [ "$width" -le 1920 ] && result="1080p"
            [ "$width" -le 720 ] && result="720p"
            [ "$width" -le 640 ] && result="480p"
        fi
    fi
    echo "$result"
}
