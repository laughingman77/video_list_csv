#!/bin/bash

# Extract the video version from a filename
# $1 filename
version() {
    # Strip the file extension amd replace all "." wuth " "
    local temp=$(echo "$1" | sed -r 's/\./\ /g' | sed -r 's/\ [0-9a-z]*$//I')
    # Version after title and date in brackets
    local result=$(echo "$temp" | sed -n -r 's/^.*\ \([0-9]{4}\)\ -\ //p')
    if [ -z "$result" ]; then
        # Version after title and date in brackets and tmdbid
        result=$(echo "$temp" | sed -n -r 's/^.*\ \([0-9]{4}\)\ \[tmdbid-[0-9]*\]\ -\ //p')
    fi
    if [ -z "$result" ]; then
        # Version after title and date in brackets and imdbid
        result=$(echo "$temp" | sed -n -r 's/^.*\ \([0-9]{4}\)\ \[imdbid-[0-9]*\]\ -\ //p')
    fi
    if [ -z "$result" ]; then
        # Version without year or tmdbid/imdbid code (false positives here)
        result=$(echo "$temp" | sed -n -r 's/^.*\ -\ //p')
    fi
    echo "$result"
}
