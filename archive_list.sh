#!/bin/sh

# https://stackoverflow.com/questions/592620/how-can-i-check-if-a-program-exists-from-a-bash-script
command -v mediainfo >/dev/null 2>&1 || { echo >&2 "I require mediainfo but it's not installed."; exit 1; }
command -v jq >/dev/null 2>&1 || { echo >&2 "I require jq but it's not installed."; exit 1; }

saveifs=${IFS}

# Import .env vars
if [ ! -e .env ]; then
    echo >&2 'Please configure the .env file'
    exit 1
fi
set -a
. './.env'
set +a

extensions='m2ts|webm|mkv|flv|vob|ogv|ogg|rrc|gifv|mng|mov|avi|qt|wmv|yuv|asf|amv|mp4|m4p|m4v|mpg|mp2|mpeg|mpe|mpv|m4v|svi|3gp|3g2|mxf|roq|nsv|flv|f4v|f4p|f4a|f4b|mod'
dir=$1

# Create a regex of the extensions for the find command
extensions_re="\\($(echo "$extensions" | sed -r 's/\|/\\\|/g')\\)"

columns=''
filenames="$(mktemp)"
find "$dir" -type f -regex ".*\.$extensions_re" > "$filenames"
while IFS= read -r filepath; do
    line=''
    episode=''
    season=''
    json=''
    size=0
    filename=${filepath##*/}
    spaced_filename=$(echo "$filename" | sed -r 's/\./\ /g')
    # Detect if dir contains movies or TV shows
    if [ -z "$columns" ]; then
        echo "$spaced_filename" | grep -Piq '\ s\d{2}e\d{2}\ ' && columns="$tv_columns" || columns="$movie_columns"
    fi
    # @see https://gist.github.com/biiont/290341b29657c0bb2df6
    col_arr="$columns|"
    # For each column
    while [ -n "$col_arr" ]; do 
        column=${col_arr%%|*}
        field=''
        case "$column" in
            'Title')
                # Title with date in brackets
                field=$(echo "$spaced_filename" | grep -ioP '.*?(?=\ \(\d{4}\)\ )')
                # Title with date
                [ -z "$field" ] && field=$(echo "$spaced_filename" | grep -ioP '.*?(?=\ \d{4}\ )')
                ;;
            'Series')
                test -z "$season" && season=$(echo "$1" | sed -r 's/^.*s([0-9]{2})e[0-9]{2}.*$/\1/I')
                test -z "$episode" && episode=$(echo "$1" | sed -r 's/^.*s[0-9]{2}e([0-9]{2}).*$/\1/I')
                if test "$display_series_for_1" -eq 0 || { test "$season" -eq 1 && test "$episode" -eq 1; }; then
                    field=$(echo "$spaced_filename" | grep -ioP '.*?(?=\ s\d{2}e\d{2}\ )')
                fi
                ;;
            'Season')
                test -z "$episode" && episode=$(echo "$1" | sed -r 's/^.*s[0-9]{2}e([0-9]{2}).*$/\1/I')
                if test "$display_season_for_1" -eq 0 || test "$episode" -eq 1; then
                    test -z "$season" && season=$(echo "$1" | sed -r 's/^.*s([0-9]{2})e[0-9]{2}.*$/\1/I')
                    field="$season"
                fi
                ;;
            'Episode')
                test -z "$episode" && episode=$(echo "$1" | sed -r 's/^.*s[0-9]{2}e([0-9]{2}).*$/\1/I')
                field="$episode"
                ;;
            'Year')
                # Year with brackets
                field=$(echo "$spaced_filename" | grep -ioP '\ \(\d{4}\)\ ')
                # Year without brackets
                [ -z "$field" ] && field=$(echo "$spaced_filename" | grep -ioP '\ \d{4}\ ')
                field=$(echo "$field"  | grep -ioP '\d{4}')
                ;;
            'Resolution')
                field=$(echo "$spaced_filename" | grep -oP '\d+p')
                if test "$detect_if_not_in_filename" -eq 1  && test -z "$field"; then
                    [ -z "$json" ] && json=$(mediainfo --Output=JSON "$filepath")
                    jq_query='.media .track[] | select(."@type" == "Video") | (.ID + ":" +'
                    jq_query=$jq_query' (if .Width|tonumber > 3840 then "4320p"'
                    jq_query=$jq_query' elif .Width|tonumber > 1920 then "2160p"'
                    jq_query=$jq_query' elif .Width|tonumber > 720 then "1080p"'
                    jq_query=$jq_query' elif .Width|tonumber > 640 then "720p"'
                    jq_query=$jq_query' else "480p" end))'
                    resolutions=$(echo "$json" | jq "$jq_query" | sed -r 's/\"//g')
                    linecount=$(echo "$resolutions" | tr '\n' ' ' | sed 's/[^:]//g' | awk '{ print length; }')
                    if test "$linecount" -le 1; then
                        field=$(echo "$resolutions" | sed 's/[0-9]*\:\(.*\)/\1/g')
                    else
                        field=$(echo "$resolutions" | tr '\n' ',' | sed 's/,/, /g' | sed 's/\([0-9]*\)\:/stream_\1:/g' | sed 's/, $//')
                    fi
                fi
                ;;
            'Edition')
                # Strip the file extension
                part_filename=$(echo "$spaced_filename" | sed -r 's/\ [0-9a-z]*$//I')
                # Edition in curly brackets (Plex)
                field=$(echo "$part_filename" | sed -nr 's/.*\{edition-(.*)\}.*/\1/p')
                # Edition after date in brackets and hyphen (jellyin & kodi)
                [ -z "$field" ] && field=$(echo "$part_filename" | sed -nr 's/.*\([0-9]{4}\)\ -\ (.*)/\1/p')
                # Edition after date in brackets, tmdbid/imdbid in square brackets and hyphen (jellyin)
                [ -z "$field" ] && field=$(echo "$part_filename" | sed -nr 's/.*\([0-9]{4}\)\ \[[t|i]mdbid-.*\]\ -\ (.*)/\1/p')
                # Fallback
                [ -z "$field" ] && field=$(echo "$part_filename" | grep -E -io "(remastered|theatrical cut|special edition|cinematic cut|extended cut|director'?s cut|producer'?s cut|unrated|uncut)" | tr '\n' ' ' | sed 's/^\ //' | sed 's/\ $//')
                ;;
            'Video')
                codec=''
                codec_features=''
                # H.261
                ( echo "$spaced_filename" | grep -iq '\ x261\ \|\ h-261\ \|\ h261\ \|\ h\ 261\ ' ) && codec='H.261'
                # MPEG-1
                ( echo "$spaced_filename" | grep -iq '\ mpeg1\ \|\ mpeg-1\ \|\ mpeg\ 1\ ' ) && codec='MPEG1'
                # H.263
                ( echo "$spaced_filename" | grep -iq '\ x263\ \|\ h263\ \|\ h-263\ \|\ h\ 263\ ' ) && codec='H.263'
                # MPEG-2
                ( echo "$spaced_filename" | grep -iq '\ mpeg2\ \|\ mpeg-2\ \|\ mpeg\ 2\ \|\ h222\ \|\ h-222\ \|\ h\ 222\ \|\ h262\ \|\ h-262\ \|\ h\ 262\ ' ) && codec='MPEG2'
                # MPEG-4
                ( echo "$spaced_filename" | grep -iq '\ mpeg-4\ part\ 2\ visual\ \|\ mpeg-4\ \|\ mpeg\ 4\ \|\ mpeg4\ ' ) && codec='MPEG4'
                # VC-1
                ( echo "$spaced_filename" | grep -iq '\ vc1\ \|\ vc-1\ \|\ vc\ 1\ ' ) && codec='VC-1'
                # AVC
                ( echo "$spaced_filename" | grep -iq '\ avc\ \|\ x264\ \|\ h264\ \|\ h\ 264\ \|\ h-264\ \|\ mpeg-4\ part\ 10\ ' ) && codec='AVC'
                # AVS1
                ( echo "$spaced_filename" | grep -iq '\ avs1\ \|\ avs-1 \|\ avs\ 1\ ' ) && codec='AVS1'
                # VP8
                ( echo "$spaced_filename" | grep -iq '\ vp8\ \|\ vp-8\ \|\ vp\ 8\ ' ) && codec='VP8'
                # VC-2
                ( echo "$spaced_filename" | grep -iq '\ vc2\ \|\ vc-2\ \|\ vc\ 2\ ' ) && codec='VC-2'
                # HEVC
                ( echo "$spaced_filename" | grep -iq '\ hevc\ \|\ x265\ \|\ h265\ \|\ h-265\ \|\ h\ 265-\|\ mpeg-h\ part\ 2\ ' ) && codec='HEVC'
                # MJPEG
                ( echo "$spaced_filename" | grep -iq '\ motion\ jpeg\ \|\ mjpeg\ \|\ m-jpeg\ ' ) && codec='MJPEG'
                # VP9
                ( echo "$spaced_filename" | grep -iq '\ vp9\ \|\ vp-9\ \|\ vp\ 9\ ' ) && codec='VP9'
                # AVS2
                ( echo "$spaced_filename" | grep -iq '\ avs2 \|\ avs-2 \|\ avs\ 2\ ' ) && codec='AVS2'
                # AV1
                ( echo "$spaced_filename" | grep -iq '\ av1\ \|\ av-1\ \|\ av\ 1\ ' ) && codec='AV1'
                # AVS3
                ( echo "$spaced_filename" | grep -iq '\ avs3 \|\ avs-3 \|\ avs\ 3\ ' ) && codec='AVS3'
                # VVC
                ( echo "$spaced_filename" | grep -iq '\ vvc\ \|\ x266\ \|\ h266\ \|\ h-266\ \|\ h\ 266\ ' ) && codec='VVC'
                # MPEG-5
                ( echo "$spaced_filename" | grep -iq '\ lcevc \|\ mpeg5 \|\ mpeg-5\ \|\ mpeg\ 5\ ' ) && codec='MPEG5'
                # 3D
                ( echo "$spaced_filename" | grep -iq '\ 3d\ ' ) && codec_features="$codec_features 3D"
                # 10-bit
                ( echo "$spaced_filename" | grep -iq '\ 10bit\ \|\ 10-bit\ \|\ 10\ bit\ ' ) && codec_features="$codec_features 10-bit"
                # DV
                ( echo "$spaced_filename" | grep -iq '\ dv\ ' ) && codec_features="$codec_features DV"
                # HLG
                ( echo "$spaced_filename" | grep -iq '\ hlg\ ' ) && codec_features="$codec_features HLG"
                # HDR
                ( echo "$spaced_filename" | grep -iq '\ hdr\ ' ) && codec_features="$codec_features HDR"
                # HDR10
                ( echo "$spaced_filename" | grep -iq '\ hdr10\ ' ) && codec_features="$codec_features HDR10"
                # HDR10+
                ( echo "$spaced_filename" | grep -iq '\ hdr10+\ ' ) && codec_features="$codec_features HDR10+"
                if test "$detect_if_not_in_filename" -eq 1 && test -z "$codec"; then
                    [ -z "$json" ] && json=$(mediainfo --Output=JSON "$filepath")
                    jq_query='.media .track[] | select(."@type" == "Video") | (.ID + ":" + .Format +'
                    jq_query=$jq_query' (if .transfer_characteristics == null then "" elif .transfer_characteristics|contains("HLG") then " HLG" else "" end) +'
                    jq_query=$jq_query' (if .HDR_Format == null then "" elif .HDR_Format|contains("Dolby Vision") then " DV" else "" end) +'
                    jq_query=$jq_query' (if .HDR_Format_Compatibility == null then "" elif .HDR_Format_Compatibility|contains("HDR10 ") then " HDR10" else "" end) +'
                    jq_query=$jq_query' (if .HDR_Format_Compatibility == null then "" elif .HDR_Format_Compatibility|contains("HDR10+ ") then " HDR10+" else "" end))'
                    codecs=$(echo "$json" | jq "$jq_query" | sed -r 's/\"//g' | tr '[:lower:]' '[:upper:]')
                    linecount=$(echo "$codecs" | tr '\n' ' ' | sed 's/[^:]//g' | awk '{ print length; }')
                    if test "$linecount" -le 1; then
                        field=$(echo "$codecs" | sed 's/[0-9]*\:\(.*\)/\1/g')
                    else
                        field=$(echo "$codecs" | tr '\n' ',' | sed 's/,/, /g' | sed 's/\([0-9]*\)\:/stream_\1:/g' | sed 's/, $//')
                    fi
                else
                    field="$codec$codec_features"
                fi
                ;;
            'Audio')
                channel_layout=$(echo "$spaced_filename" | sed -n -r 's/.*\ ([0-9]\ [0-9]).*/\1/p' | tr ' ' '.')
                codec=''
                # DTS
                ( echo "$spaced_filename" | grep -iq '\ dts\ ' ) && codec='DTS'
                # DTS:X
                ( echo "$spaced_filename" | grep -iq '\ dts\:x\ \|\ dts-x\ ' ) && codec='DTS:X'
                # DTS-MA
                ( echo "$spaced_filename" | grep -iq '\ dts-ma\ \|\ dts\ ma\ ' ) && codec='DTS-MA'
                # DTS-HD
                ( echo "$spaced_filename" | grep -iq '\ dts-hd\ \|\ dts\ hd\ ' ) && codec='DTS-HD'
                # DTS HD-MA
                ( echo "$spaced_filename" | grep -iq '\ dts-hd-ma\ \|\ dts-hd\ ma\ \|\ dts-hdma\ \|\ dts\ hd-ma\ \|\ dts\ hd\ ma\ \|\ dts-hd\ master\ audio\ \|\ dts++\ \|\ dca\ xll' ) && codec='DTS-HD MA'
                # TrueHD
                ( echo "$spaced_filename" | grep -iq '\ truehd\ ' ) && codec='TrueHD'
                # Atmos
                ( echo "$spaced_filename" | grep -iq '\ atmos\ ' ) && codec='Atmos'
                # FLAC
                ( echo "$spaced_filename" | grep -iq '\ flac\ ' ) && codec='FLAC'
                # PCM
                ( echo "$spaced_filename" | grep -iq '\ pcm\ \|\ lpcm\ ' ) && codec='PCM'
                # MLP
                ( echo "$spaced_filename" | grep -iq '\ mlp\ \|\ ppcm\ ' ) && codec='MLP'
                # MPEG-4 ALS
                ( echo "$spaced_filename" | grep -iq '\ mpeg-4\ als\ ' ) && codec='MPEG-4 ALS'
                # MPEG-4 SLS
                ( echo "$spaced_filename" | grep -iq '\ mpeg-4\ sls\ ' ) && codec='MPEG-4 SLS'
                # RealAudio
                ( echo "$spaced_filename" | grep -iq '\ realaudio\ ' ) && codec='RealAudio'
                # Dolby Digital
                ( echo "$spaced_filename" | grep -iq '\ ac3\ \|\ atsc\ a/52\ ' ) && codec='DD'
                # Dolby Digital Plus
                ( echo "$spaced_filename" | grep -iq '\ e-ac-3\ ' ) && codec='DD+'
                # Dolby AC-4
                ( echo "$spaced_filename" | grep -iq '\ ac-4\ ' ) && codec='Dolby AC4'
                # MPEG Layer 1
                ( echo "$spaced_filename" | grep -iq '\ mp-1\ ' ) && codec='MP1'
                # MPEG Layer 2
                ( echo "$spaced_filename" | grep -iq '\ mp-2\ ' ) && codec='MP2'
                # MPEG Layer 3
                ( echo "$spaced_filename" | grep -iq '\ mp-3\ ' ) && codec='MP3'
                # AAC
                ( echo "$spaced_filename" | grep -iq '\ aac\ ') && codec='AAC'
                # AAC
                ( echo "$spaced_filename" | grep -iq '\ aac\ ' ) && codec='AAC'
                # APE
                ( echo "$spaced_filename" | grep -iq '\ ape\ ' ) && codec='APE'

                if test "$detect_if_not_in_filename" -eq 0 || { test ! -z "$codec" && test ! -z "$channel_layout"; }; then
                    field="$codec $channel_layout"
                else
                    [ -z "$json" ] && json=$(mediainfo --Output=JSON "$filepath")
                    jq_query='.media .track[] | select(."@type" == "Audio") | (.ID + ":" + .Format'
                    jq_query=$jq_query' + (if .Channels|tonumber == 1 then " 1.0"'
                    jq_query=$jq_query' elif .Channels|tonumber == 2 then " 2.0"'
                    jq_query=$jq_query' elif .Channels|tonumber == 3 then " 2.1"'
                    jq_query=$jq_query' elif .Channels|tonumber == 4 then " 3.1"'
                    jq_query=$jq_query' elif .Channels|tonumber == 5 then " 4.1"'
                    jq_query=$jq_query' elif .Channels|tonumber == 6 then " 5.1"'
                    jq_query=$jq_query' elif .Channels|tonumber == 7 then " 6.1"'
                    jq_query=$jq_query' elif .Channels|tonumber == 8 then " 7.1"'
                    jq_query=$jq_query' elif .Channels|tonumber == 9 then " 8.1"'
                    jq_query=$jq_query' elif .Channels|tonumber == 10 then " 9.1" else "" end))'
                    codecs=$(echo "$json" | jq "$jq_query" | sed -r 's/\"//g' | tr '[:lower:]' '[:upper:]')
                    linecount=$(echo "$codecs" | tr '\n' ' ' | sed 's/[^:]//g' | awk '{ print length; }')
                    if test "$linecount" -le 1; then
                        field=$(echo "$codecs" | sed 's/[0-9]*\:\(.*\)/\1/g')
                    else
                        field=$(echo "$codecs" | tr '\n' ',' | sed 's/,/, /g' | sed 's/\([0-9]*\)\:/stream_\1:/g' | sed 's/, $//')
                    fi
                fi
                ;;
            'Release Type')
                part_filename=$(echo "$spaced_filename" | grep -oP '\ \d{4}\ .*')
                [ -z "$part_filename" ] && part_filename=$(echo "$spaced_filename" | grep -oP '\ \-\ .*')
                # Extremely rare
                ( echo "$part_filename" | grep -iq '\ wp\ \|\ workprint\ ' ) && field='Workprint'
                ( echo "$part_filename" | grep -iq '\ tc\ \|\ hdtc\ \|\ telecine\ ' ) && field='Telecine'
                # Very rare
                ( echo "$part_filename" | grep -iq '\ ppv\ \|\ ppvrip\ ' ) && field='Pay-Per-View Rip'
                ( echo "$part_filename" | grep -iq '\ vodrip\ \|\ vodr\ ' ) && field='VODRip'
                # Rare
                ( echo "$part_filename" | grep -iq '\ ddc\ ' ) && field='Digital Distribution Copy'
                ( echo "$part_filename" | grep -iq '\ r5\ \|\ r5\ line\ \|\ r5.ac3.5.1.hq\ ' ) && field='R5'
                ( echo "$part_filename" | grep -iq '\ web-cap\ \|\ webcap\ \|\ web\ cap\ ' ) && field='WEBCap'
                # Sort of rare
                ( echo "$part_filename" | grep -iq '\ dvdrip\ \|\ dvdmux\ ' ) && field='DVD-Rip'
                # Uncommon
                ( echo "$part_filename" | grep -iq '\ ts\ \|\ hdts\ \|\ teleync\ \|\ pdvd\ \|\ predvdrip\ ' ) && field='Telesync'
                ( echo "$part_filename" | grep -iq '\ scr\ \|\ screener\ \|\ dvdscr\ \|\ dvdscreener\ \|\ bdscr\ \|\ webscreener\ ' ) && field='Screener'
                # Common
                ( echo "$part_filename" | grep -iq '\ cam-tip\ \|\ cam\ \|\ hdcam\ ' ) && field='Cam'
                ( echo "$part_filename" | grep -iq '\ dvdr\ \|\ dvd-full\ \|\ full-rip\ \|\ iso\ rip\ \|\ lossless\ rip\ \|\ untouched\ rip\ \|\ dvd-5\ \|\ dvd-9\ ' ) && field='DVD-R'
                ( echo "$part_filename" | grep -iq '\ dsr\ \|\ dsrip\ \|\ satrip\ \|\ dthrip\ \|\ dvbrip\ \|\ hdtv\ \|\ pdtv\ \|\ dtvrip\ \|\ tvrip\ \|\ hdtvrip\ ' ) && field='HDTV'
                ( echo "$part_filename" | grep -iq '\ hc\ \|\ hd-rip\ ' ) && field='HC HD-Rip'
                ( echo "$part_filename" | grep -iq '\ hdrip\ \|\ web-dlrip\ ' ) && field='HDRip'
                ( echo "$part_filename" | grep -iq '\ webrip\ \|\ web\ rip\ \|\ WEB-Rip\ ' ) && field='WEBRip'
                ( echo "$part_filename" | grep -iq '\ webdl\ \|\ web\ dl\ \|\ web-dl\ \|\ web\ \|\ webrip\ ' ) && field='Web-DL'
                ( echo "$part_filename" | grep -iq '\ blu-ray\ \|\ bluray\ \|\ bdiso\ \|\ complete\ bluray\ ' ) && field='Blu-Ray'
                ( echo "$part_filename" | grep -iq '\ bdrip\ \|\ bd50\ \|\ bd66\ \|\ bd100\ \|\ bd9\ ' ) && field='BDRip'
                ( echo "$part_filename" | grep -iq '\ brip\ \|\ brrip\ \|\ bdr\ \|\ bd25\ \|\ bd5\ \|\ dbmv\ ' ) && field='BRRip'
                ( echo "$part_filename" | grep -iq 'remux' ) && field='Remux'
                ;;
            'Size (GB)')
                test -z "$size" && size=$(stat -c '%s' "$filepath")
                field=$( echo "scale=2; $size / 1073741824" | bc )
                ;;
            'Size (MB)')
                test -z "$size" && size=$(stat -c '%s' "$filepath")
                field=$( echo "scale=2; $size / 1048576" | bc )
                ;;
            'Size (KB)')
                test -z "$size" && size=$(stat -c '%s' "$filepath")
                field=$( echo "scale=2; $size / 1024" | bc )
                ;;
            'Size (B)')
                test -z "$size" && size=$(stat -c '%s' "$filepath")
                field="$size"
                ;;
            'Filename')
                field="$filename"
                ;;
            'Full Path')
                field="$filepath"
                ;;
        esac
        col_arr=${col_arr#*|}
        if test -z "$line"; then
            line="\"$field\""
        else
            line="$line,\"$field\""
        fi
    done
    unset column col_arr
    output="${output}${line};"
done < "$filenames"
rm "$filenames"

# Add column headings
line=''
col_arr="$columns|"
while [ -n "$col_arr" ]; do 
    column=${col_arr%%|*}
    if test -z "$line"; then
        line="\"$column\""
    else
        line="$line,\"$column\""
    fi
    col_arr=${col_arr#*|}
done
unset column col_arr
output="$line;$output"

# Generate disk usage stats
disk_usage=$(df -Ph "$dir" | tail -n 1)
disk_size=$(echo "$disk_usage" | awk '{print $2}')
disk_used=$(echo "$disk_usage" | awk '{print $3}')
disk_avail=$(echo "$disk_usage" | awk '{print $4}')
line="$disk_size,$disk_used,$disk_avail;;"
output="${line}${output}"
line='Size,Used,Free;'
output="${line}${output}"

# Reset IFS
IFS=${saveifs}

# Replace ; with \n for printing
echo "$output" | sed 's/;/\n/g'
