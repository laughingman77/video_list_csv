#!/bin/bash

# Detect the release type of a file
# @see https://en.wikipedia.org/wiki/Pirated_movie_release_types
# $1 filename
release_type() {
    local temp=$(echo "$1" | sed -r 's/\./\ /g' | grep -oP '\ \d{4}\ .*')
    if [ -z "$temp" ]; then
        temp=$(echo "$1" | sed -r 's/\./\ /g' | grep -oP '\ \-\ .*')
    fi
    local result=""
    # Extremely rare
    [ $(echo "$temp" | grep -i "\ wp\ \|\ workprint\ ") ] && result="Workprint"
    [ $(echo "$temp" | grep -i "\ tc\ \|\ hdtc\ \|\ telecine\ ") ] && result="Telecine"
    # Very rare
    [ $(echo "$temp" | grep -i "\ ppv\ \|\ ppvrip\ ") ] && result="Pay-Per-View Rip"
    [ $(echo "$temp" | grep -i "\ vodrip\ \|\ vodr\ ") ] && result="VODRip"
    # Rare
    [ $(echo "$temp" | grep -i "\ ddc\ ") ] && result="Digital Distribution Copy"
    [ $(echo "$temp" | grep -i "\ r5\ \|\ r5\ line\ \|\ r5.ac3.5.1.hq\ ") ] && result="R5"
    [ $(echo "$temp" | grep -i "\ web-cap\ \|\ webcap\ \|\ web\ cap\ ") ] && result="WEBCap"
    # Sort of rare
    [ $(echo "$temp" | grep -i "\ dvdrip\ \|\ dvdmux\ ") ] && result="DVD-Rip"
    # Uncommon
    [ $(echo "$temp" | grep -i "\ ts\ \|\ hdts\ \|\ teleync\ \|\ pdvd\ \|\ predvdrip\ ") ] && result="Telesync"
    [ $(echo "$temp" | grep -i "\ scr\ \|\ screener\ \|\ dvdscr\ \|\ dvdscreener\ \|\ bdscr\ \|\ webscreener\ ") ] && result="Screener"
    # Common
    [ $(echo "$temp" | grep -i "\ cam-tip\ \|\ cam\ \|\ hdcam\ ") ] && result="Cam"
    [ $(echo "$temp" | grep -i "\ dvdr\ \|\ dvd-full\ \|\ full-rip\ \|\ iso\ rip\ \|\ lossless\ rip\ \|\ untouched\ rip\ \|\ dvd-5\ \|\ dvd-9\ ") ] && result="DVD-R"
    [ $(echo "$temp" | grep -i "\ dsr\ \|\ dsrip\ \|\ satrip\ \|\ dthrip\ \|\ dvbrip\ \|\ hdtv\ \|\ pdtv\ \|\ dtvrip\ \|\ tvrip\ \|\ hdtvrip\ ") ] && result="HDTV"
    [ $(echo "$temp" | grep -i "\ hc\ \|\ hd-rip\ ") ] && result="HC HD-Rip"
    [ $(echo "$temp" | grep -i "\ hdrip\ \|\ web-dlrip\ ") ] && result="HDRip"
    [ $(echo "$temp" | grep -i "\ webrip\ \|\ web\ rip\ \|\ WEB-Rip\ ") ] && result="WEBRip"
    [ $(echo "$temp" | grep -i "\ webdl\ \|\ web\ dl\ \|\ web-dl\ \|\ web\ \|\ webrip\ ") ] && result="Web-DL"
    [ $(echo "$temp" | grep -i "\ blu-ray\ \|\ bluray\ \|\ bdiso\ \|\ complete\ bluray\ ") ] && result="Blu-Ray"
    [ $(echo "$temp" | grep -i "\ bdrip\ \|\ bd50\ \|\ bd66\ \|\ bd100\ \|\ bd9\ ") ] && result="BDRip"
    [ $(echo "$temp" | grep -i "\ brip\ \|\ brrip\ \|\ bdr\ \|\ bd25\ \|\ bd5\ \|\ dbmv\ ") ] && result="BRRip"
    [ $(echo "$temp" | grep -i "remux") ] && result="Remux"
    echo "$result"
}
