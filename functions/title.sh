#!/bin/bash

# Extract the video title from a filename
# $1 filename
title() {
    local TEMP=$(echo $1 | sed -r 's/\./\ /g')
    local RESULT=""
    # Title with date
    [ $(echo "$TEMP" | sed -n -r 's/\ [0-9]{4}\ .*$//p') ] && RESULT=$(echo "$TEMP" | sed -n -r 's/\ [0-9]{4}\ .*$//p')
    # Title with date in brackets
    [ -z "$RESULT" ] && [ $(echo "$TEMP" | sed -n -r 's/\ \([0-9]{4}\)\ .*$//p') ] && RESULT=$(echo "$TEMP" | sed -r -n 's/\ \([0-9]{4}\)\ .*$//p')
    # Title with season and episode
    [ -z "$RESULT" ] && [ $(echo "$TEMP" | sed -n -r 's/\ s[0-9]{2}e[0-9]{2}\ .*$//pI') ] && RESULT=$(echo "$TEMP" | sed -n -r 's/\ s[0-9]{2}e[0-9]{2}\ .*$//Ip')
    echo "$RESULT"
}
