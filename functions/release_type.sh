#!/bin/bash

# Detect the release type of a file
# @see https://en.wikipedia.org/wiki/Pirated_movie_release_types
# $1 filename
release_type() {
    local TEMP=$(echo "$1" | sed -r 's/\./\ /g' | grep -oP '\ \d{4}\ .*')
    if [ -z "$TEMP" ]; then
        TEMP=$(echo "$1" | sed -r 's/\./\ /g' | grep -oP '\ \-\ .*')
    fi
    local RESULT=""
    # Extremely rare
    [ $(echo "$TEMP" | grep -i "\ wp\ \|\ workprint\ ") ] && RESULT="Workprint"
    [ $(echo "$TEMP" | grep -i "\ tc\ \|\ hdtc\ \|\ telecine\ ") ] && RESULT="Telecine"
    # Very rare
    [ $(echo "$TEMP" | grep -i "\ ppv\ \|\ ppvrip\ ") ] && RESULT="Pay-Per-View Rip"
    [ $(echo "$TEMP" | grep -i "\ vodrip\ \|\ vodr\ ") ] && RESULT="VODRip"
    # Rare
    [ $(echo "$TEMP" | grep -i "\ ddc\ ") ] && RESULT="Digital Distribution Copy"
    [ $(echo "$TEMP" | grep -i "\ r5\ \|\ r5\ line\ \|\ r5.ac3.5.1.hq\ ") ] && RESULT="R5"
    [ $(echo "$TEMP" | grep -i "\ web-cap\ \|\ webcap\ \|\ web\ cap\ ") ] && RESULT="WEBCap"
    # Sort of rare
    [ $(echo "$TEMP" | grep -i "\ dvdrip\ \|\ dvdmux\ ") ] && RESULT="DVD-Rip"
    # Uncommon
    [ $(echo "$TEMP" | grep -i "\ ts\ \|\ hdts\ \|\ teleync\ \|\ pdvd\ \|\ predvdrip\ ") ] && RESULT="Telesync"
    [ $(echo "$TEMP" | grep -i "\ scr\ \|\ screener\ \|\ dvdscr\ \|\ dvdscreener\ \|\ bdscr\ \|\ webscreener\ ") ] && RESULT="Screener"
    # Common
    [ $(echo "$TEMP" | grep -i "\ cam-tip\ \|\ cam\ \|\ hdcam\ ") ] && RESULT="Cam"
    [ $(echo "$TEMP" | grep -i "\ dvdr\ \|\ dvd-full\ \|\ full-rip\ \|\ iso\ rip\ \|\ lossless\ rip\ \|\ untouched\ rip\ \|\ dvd-5\ \|\ dvd-9\ ") ] && RESULT="DVD-R"
    [ $(echo "$TEMP" | grep -i "\ dsr\ \|\ dsrip\ \|\ satrip\ \|\ dthrip\ \|\ dvbrip\ \|\ hdtv\ \|\ pdtv\ \|\ dtvrip\ \|\ tvrip\ \|\ hdtvrip\ ") ] && RESULT="HDTV"
    [ $(echo "$TEMP" | grep -i "\ hc\ \|\ hd-rip\ ") ] && RESULT="HC HD-Rip"
    [ $(echo "$TEMP" | grep -i "\ hdrip\ \|\ web-dlrip\ ") ] && RESULT="HDRip"
    [ $(echo "$TEMP" | grep -i "\ webrip\ \|\ web\ rip\ \|\ WEB-Rip\ ") ] && RESULT="WEBRip"
    [ $(echo "$TEMP" | grep -i "\ webdl\ \|\ web\ dl\ \|\ web-dl\ \|\ web\ \|\ webrip\ ") ] && RESULT="Web-DL"
    [ $(echo "$TEMP" | grep -i "\ blu-ray\ \|\ bluray\ \|\ bdiso\ \|\ complete\ bluray\ ") ] && RESULT="Blu-Ray"
    [ $(echo "$TEMP" | grep -i "\ bdrip\ \|\ bd50\ \|\ bd66\ \|\ bd100\ \|\ bd9\ ") ] && RESULT="BDRip"
    [ $(echo "$TEMP" | grep -i "\ brip\ \|\ brrip\ \|\ bdr\ \|\ bd25\ \|\ bd5\ \|\ dbmv\ ") ] && RESULT="BRRip"
    [ $(echo "$TEMP" | grep -i "remux") ] && RESULT="Remux"
    echo "$RESULT"
}
