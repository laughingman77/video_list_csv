#!/bin/bash

# Extract the video version from a filename
# $1 filename
version() {
    # Strip the file extension amd replace all "." wuth " "
    local TEMP=$(echo "$1" | sed -r 's/\./\ /g' | sed -r 's/\ [0-9a-z]*$//I')
    # Version after title and date in brackets
    RESULT=$(echo "$TEMP" | sed -n -r 's/^.*\ \([0-9]{4}\)\ -\ //p')
    if [ -z "$RESULT" ]; then
        # Version after title and date in brackets and tmdbid
        RESULT=$(echo "$TEMP" | sed -n -r 's/^.*\ \([0-9]{4}\)\ \[tmdbid-[0-9]*\]\ -\ //p')
    fi
    if [ -z "$RESULT" ]; then
        # Version after title and date in brackets and imdbid
        RESULT=$(echo "$TEMP" | sed -n -r 's/^.*\ \([0-9]{4}\)\ \[imdbid-[0-9]*\]\ -\ //p')
    fi
    if [ -z "$RESULT" ]; then
        # Version without year or tmdbid/imdbid code (false positives here)
        RESULT=$(echo "$TEMP" | sed -n -r 's/^.*\ -\ //p')
    fi
    echo "$RESULT"
}
