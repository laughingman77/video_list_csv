#!/bin/bash

# Import .env vars
if [ ! -e .env ]; then
    echo >&2 "Please configure the .env file"
    exit 1
fi
set -o allexport
source .env

extensions=( m2ts webm mkv flv vob ogv ogg rrc gifv mng mov avi qt wmv yuv asf amv mp4 m4p m4v mpg mp2 mpeg mpe mpv m4v svi 3gp 3g2 mxf roq nsv flv f4v f4p f4a f4b mod )

dir=$1

# Create a regex of the extensions for the find command
extensions_re="\\("${extensions[0]}
for t in "${extensions[@]:1:${#extensions[*]}}"; do
    extensions_re="${extensions_re}\\|${t}"
done
extensions_re="${extensions_re}\\)"

# Set the field separator to newline instead of space
saveifs=$IFS
IFS=$(echo -en "\n\b")

# Generate output from path and size using: $(stat -c "%s" filepath)
output=""
columns=( )
for filepath in $(find ${dir} -type f -regex ".*\.${extensions_re}"); do
    filename=$(echo "${filepath##*/}")
    spaced_filename=$(echo "$filename" | sed -r 's/\./\ /g')
    # Detect if dir contains movies or TV shows
    if [ -z $columns ]; then
        $(echo "$spaced_filename" | grep -Piq 's\d{2}e\d{2}') && columns=( "${tv_columns[@]}" ) || columns=( "${movie_columns[@]}" )
    fi
    line=""
    for col in "${columns[@]}"; do
        field=""
        case "$col" in
            "Title")
                # Title with date in brackets
                field=$(echo "$spaced_filename" | sed -r -n 's/\ \([0-9]{4}\)\ .*$//p')
                # Title with date
                [ -z "$field" ] && field=$(echo "$spaced_filename" | sed -n -r 's/\ [0-9]{4}\ .*$//p')
                ;;
            "Series")
                field=""
                if [ "$display_series_for_1" = 1 ]; then
                    episode=$(echo "$spaced_filename" | sed -r 's/^.*s[0-9]{2}e([0-9]{2}).*$/\1/I')
                    season=$(echo "$spaced_filename" | sed -r 's/^.*s([0-9]{2})e[0-9]{2}.*$/\1/I')
                    if [[ "$season" = "01" && "$episode" = "01" ]]; then
                        # Series name with date in brackets
                        field=$(echo "$spaced_filename" | sed -r -n 's/\ \([0-9]{4}\)\ .*$//p')
                        # Series with season and episode
                        [ -z "$field" ] && field=$(echo "$spaced_filename" | sed -n -r 's/\ s[0-9]{2}e[0-9]{2}\ .*$//Ip')
                    fi
                else
                    # Title with date in brackets
                    field=$(echo "$spaced_filename" | sed -r -n 's/\ \([0-9]{4}\)\ .*$//p')
                    # Title with date
                    [ -z "$field" ] && field=$(echo "$spaced_filename" | sed -n -r 's/\ [0-9]{4}\ .*$//p')
                    # Title with season and episode
                    [ -z "$field" ] && field=$(echo "$spaced_filename" | sed -n -r 's/\ s[0-9]{2}e[0-9]{2}\ .*$//Ip')
                fi
                ;;
            "Season")
                field=""
                if [ "$display_season_for_1" = 1 ]; then
                    episode=$(echo "$spaced_filename" | sed -r 's/^.*s[0-9]{2}e([0-9]{2}).*$/\1/I')
                    [ "$episode" = "01" ] && field=$(echo "$spaced_filename" | sed -r 's/^.*s([0-9]{2})e[0-9]{2}.*$/\1/I')
                else
                    field=$(echo "$spaced_filename" | sed -r 's/^.*s([0-9]{2})e[0-9]{2}.*$/\1/I')
                fi
                ;;
            "Episode")
                field=$(echo "$spaced_filename" | sed -r 's/^.*s[0-9]{2}e([0-9]{2}).*$/\1/I')
                ;;
            "Year")
                # Year with brackets
                field=$(echo "$spaced_filename" | sed -r -n 's/^.*\ \(([0-9]{4})\)\ .*$/\1/p')
                # Year without brackets
                [ -z "$field" ] && field=$(echo "$spaced_filename" | sed -n -r 's/^.*\ ([0-9]{4})\ .*$/\1/p')
                ;;
            "Resolution")
                field=$(echo "$spaced_filename" | grep -oP '\d+p')
                if [[ -z "$field" && "$detect_resolution" == 1 && -f "$filepath" ]]; then
                    width=$(ffprobe -v error -select_streams v -show_entries stream=width,height -of json "$filepath" | jq '.streams[0] .width')
                    if [ -z "$width" ]; then
                        field=""
                    else
                        [ "$width" -le 7680 ] && field="4320p"
                        [ "$width" -le 3840 ] && field="2160p"
                        [ "$width" -le 1920 ] && field="1080p"
                        [ "$width" -le 720 ] && field="720p"
                        [ "$width" -le 640 ] && field="480p"
                    fi
                fi
                ;;
            "Version")
                # Strip the file extension
                part_filename=$(echo "$spaced_filename" | sed -r 's/\ [0-9a-z]*$//I')
                # Version after title and date in brackets
                field=$(echo "$part_filename" | sed -n -r 's/^.*\ \([0-9]{4}\)\ -\ //p')
                # Version after title and date in brackets and tmdbid
                [ -z "$field" ] && field=$(echo "$part_filename" | sed -n -r 's/^.*\ \([0-9]{4}\)\ \[tmdbid-[0-9]*\]\ -\ //p')
                # Version after title and date in brackets and imdbid
                [ -z "$field" ] && field=$(echo "$part_filename" | sed -n -r 's/^.*\ \([0-9]{4}\)\ \[imdbid-[0-9]*\]\ -\ //p')
                # Version without year or tmdbid/imdbid code (false positives here)
                [ -z "$field" ] && field=$(echo "$part_filename" | sed -n -r 's/^.*\ -\ //p')
                ;;
            "Release Type")
                part_filename=$(echo "$spaced_filename" grep -oP '\ \d{4}\ .*')
                [ -z "$part_filename" ] && temp=$(echo "$spaced_filename" grep -oP '\ \-\ .*')
                # Extremely rare
                [ $(echo "$part_filename" | grep -i "\ wp\ \|\ workprint\ ") ] && field="Workprint"
                [ $(echo "$part_filename" | grep -i "\ tc\ \|\ hdtc\ \|\ telecine\ ") ] && field="Telecine"
                # Very rare
                [ $(echo "$part_filename" | grep -i "\ ppv\ \|\ ppvrip\ ") ] && field="Pay-Per-View Rip"
                [ $(echo "$part_filename" | grep -i "\ vodrip\ \|\ vodr\ ") ] && field="VODRip"
                # Rare
                [ $(echo "$part_filename" | grep -i "\ ddc\ ") ] && field="Digital Distribution Copy"
                [ $(echo "$part_filename" | grep -i "\ r5\ \|\ r5\ line\ \|\ r5.ac3.5.1.hq\ ") ] && field="R5"
                [ $(echo "$part_filename" | grep -i "\ web-cap\ \|\ webcap\ \|\ web\ cap\ ") ] && field="WEBCap"
                # Sort of rare
                [ $(echo "$part_filename" | grep -i "\ dvdrip\ \|\ dvdmux\ ") ] && field="DVD-Rip"
                # Uncommon
                [ $(echo "$part_filename" | grep -i "\ ts\ \|\ hdts\ \|\ teleync\ \|\ pdvd\ \|\ predvdrip\ ") ] && field="Telesync"
                [ $(echo "$part_filename" | grep -i "\ scr\ \|\ screener\ \|\ dvdscr\ \|\ dvdscreener\ \|\ bdscr\ \|\ webscreener\ ") ] && field="Screener"
                # Common
                [ $(echo "$part_filename" | grep -i "\ cam-tip\ \|\ cam\ \|\ hdcam\ ") ] && field="Cam"
                [ $(echo "$part_filename" | grep -i "\ dvdr\ \|\ dvd-full\ \|\ full-rip\ \|\ iso\ rip\ \|\ lossless\ rip\ \|\ untouched\ rip\ \|\ dvd-5\ \|\ dvd-9\ ") ] && field="DVD-R"
                [ $(echo "$part_filename" | grep -i "\ dsr\ \|\ dsrip\ \|\ satrip\ \|\ dthrip\ \|\ dvbrip\ \|\ hdtv\ \|\ pdtv\ \|\ dtvrip\ \|\ tvrip\ \|\ hdtvrip\ ") ] && field="HDTV"
                [ $(echo "$part_filename" | grep -i "\ hc\ \|\ hd-rip\ ") ] && field="HC HD-Rip"
                [ $(echo "$part_filename" | grep -i "\ hdrip\ \|\ web-dlrip\ ") ] && field="HDRip"
                [ $(echo "$part_filename" | grep -i "\ webrip\ \|\ web\ rip\ \|\ WEB-Rip\ ") ] && field="WEBRip"
                [ $(echo "$part_filename" | grep -i "\ webdl\ \|\ web\ dl\ \|\ web-dl\ \|\ web\ \|\ webrip\ ") ] && field="Web-DL"
                [ $(echo "$part_filename" | grep -i "\ blu-ray\ \|\ bluray\ \|\ bdiso\ \|\ complete\ bluray\ ") ] && field="Blu-Ray"
                [ $(echo "$part_filename" | grep -i "\ bdrip\ \|\ bd50\ \|\ bd66\ \|\ bd100\ \|\ bd9\ ") ] && field="BDRip"
                [ $(echo "$part_filename" | grep -i "\ brip\ \|\ brrip\ \|\ bdr\ \|\ bd25\ \|\ bd5\ \|\ dbmv\ ") ] && field="BRRip"
                [ $(echo "$part_filename" | grep -i "remux") ] && field="Remux"
                ;;
            "Size (GB)")
                size_b=$(stat -c "%s" "${filepath}")
                field=$(echo "scale=2; ${size_b} / 1024 / 1024 / 1024" | bc -l)
                ;;
            "Size (MB)")
                size_b=$(stat -c "%s" "${filepath}")
                field=$(echo "scale=2; ${size_b} / 1024 / 1024" | bc -l)
                ;;
            "Size (KB)")
                size_b=$(stat -c "%s" "${filepath}")
                field=$(echo "scale=2; ${size_b} / 1024" | bc -l)
                ;;
            "Size (B)")
                field=$(stat -c "%s" "${filepath}")
                ;;
            "Filename")
                field="$filename"
                ;;
            "Full Path")
                field="$filepath"
                ;;
        esac
        if [ ! -z "$line" ]; then
            line=${line}",\""${field}"\""
        else
            line="\""${field}"\""
        fi
    done
    output=${output}${line}";"
done

# Generate disk usage stats
IFS='
' # split on newline only. Also IFS=$'\n' in bash/ksh93/zsh/mksh
set -o noglob  # disable globbin
line=""
for col in "${columns[@]}"; do
    if [ ! -z "$line" ]; then
        line=${line}",\""${col}"\""
    else
        line="\""${col}"\""
    fi
done
output="${line};${output}"
disk_usage=($(df -h --output=size,used,avail $dir | column -t))
output=";"$output
output=$(echo "${disk_usage[1]}" | sed -e "s/ /,/g" | sed -e "s/,,/,/g")";"$output
output=$(echo "${disk_usage[0]}" | sed -e "s/ /,/g" | sed -e "s/,,/,/g")";"$output

# Reset IFS
IFS=$saveifs

# Replace ; with \n for printing
echo $output | tr ';' '\n'
