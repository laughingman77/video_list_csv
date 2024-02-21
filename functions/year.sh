#!/bin/bash

# Extract the video year from a filename
# $1 filename
year() {
    local temp=$(echo $1 | sed -r 's/\./\ /g')
    local result=""
    # Year without brackets
    [ $(echo "$temp" | sed -n -r 's/^.*\ ([0-9]{4})\ .*$/\1/p') ] && result=$(echo "$temp" | sed -n -r 's/^.*\ ([0-9]{4})\ .*$/\1/p')
    # Year with brackets
    [ -z "$result" ] && [ $(echo "$temp" | sed -n -r 's/^.*\ \(([0-9]{4})\)\ .*$/\1/p') ] && result=$(echo "$temp" | sed -r -n 's/^.*\ \(([0-9]{4})\)\ .*$/\1/p')
    echo "$result"
}
