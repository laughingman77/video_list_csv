#!/bin/bash

# Extract the video year from a filename
# $1 filename
year() {
    local TEMP=$(echo $1 | sed -r 's/\./\ /g')
    local RESULT=""
    # Year without brackets
    [ $(echo "$TEMP" | sed -n -r 's/^.*\ ([0-9]{4})\ .*$/\1/p') ] && RESULT=$(echo "$TEMP" | sed -n -r 's/^.*\ ([0-9]{4})\ .*$/\1/p')
    # Year with brackets
    [ -z "$RESULT" ] && [ $(echo "$TEMP" | sed -n -r 's/^.*\ \(([0-9]{4})\)\ .*$/\1/p') ] && RESULT=$(echo "$TEMP" | sed -r -n 's/^.*\ \(([0-9]{4})\)\ .*$/\1/p')
    echo "$RESULT"
}
