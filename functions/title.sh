#!/bin/bash

# Extract the video title from a filename
# $1 filename
title() {
    local temp=$(echo $1 | sed -r 's/\./\ /g')
    local result=""
    # Title with date
    [ $(echo "$temp" | sed -n -r 's/\ [0-9]{4}\ .*$//p') ] && result=$(echo "$temp" | sed -n -r 's/\ [0-9]{4}\ .*$//p')
    # Title with date in brackets
    [ -z "$result" ] && [ $(echo "$temp" | sed -n -r 's/\ \([0-9]{4}\)\ .*$//p') ] && result=$(echo "$temp" | sed -r -n 's/\ \([0-9]{4}\)\ .*$//p')
    # Title with season and episode
    [ -z "$result" ] && [ $(echo "$temp" | sed -n -r 's/\ s[0-9]{2}e[0-9]{2}\ .*$//pI') ] && result=$(echo "$temp" | sed -n -r 's/\ s[0-9]{2}e[0-9]{2}\ .*$//Ip')
    echo "$result"
}
