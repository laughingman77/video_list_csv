#!/bin/sh

saveifs=${IFS}

# Import .env vars
if [ ! -e .env ]; then
    echo >&2 'Please configure the .env file'
    exit 1
fi
set -a
. './.env'
set +a

extensions='m2ts:webm:mkv:flv:vob:ogv:ogg:rrc:gifv:mng:mov:avi:qt:wmv:yuv:asf:amv:mp4:m4p:m4v:mpg:mp2:mpeg:mpe:mpv:m4v:svi:3gp:3g2:mxf:roq:nsv:flv:f4v:f4p:f4a:f4b:mod'
dir=$1

# Create a regex of the extensions for the find command
extensions_re="\\($(echo "$extensions" | sed -r 's/\:/\\\|/g')\\)"

columns=''
filenames="$(mktemp)"
find "$dir" -type f -regex ".*\.$extensions_re" > "$filenames"
while IFS= read -r filepath; do
    line=''
    filename=${filepath##*/}
    spaced_filename=$(echo "$filename" | sed -r 's/\./\ /g')
    # Detect if dir contains movies or TV shows
    if [ -z "$columns" ]; then
        echo "$spaced_filename" | grep -Piq 's\d{2}e\d{2}' && columns="$tv_columns" || columns="$movie_columns"
    fi
    episode=''
    season=''
    if ( echo "$columns" | grep -Piq 's\series|season|episode' ); then
        episode=$(echo "$spaced_filename" | sed -r 's/^.*s[0-9]{2}e([0-9]{2}).*$/\1/I')
        season=$(echo "$spaced_filename" | sed -r 's/^.*s([0-9]{2})e[0-9]{2}.*$/\1/I')
    fi
    # @see https://gist.github.com/biiont/290341b29657c0bb2df6
    col_arr="$columns:"
    # For each column
    while [ -n "$col_arr" ]; do 
        column=${col_arr%%:*}
        field=''
        case "$column" in
            'Title')
                # Title with date in brackets
                field=$(echo "$spaced_filename" | sed -r -n 's/\ \([0-9]{4}\)\ .*$//p')
                # Title with date
                [ -z "$field" ] && field=$(echo "$spaced_filename" | sed -n -r 's/\ [0-9]{4}\ .*$//p')
                ;;
            'Series')
                if test "$display_series_for_1" -eq 0 || { test "$season" -eq 1 && test "$episode" -eq 1; }; then
                    # Series name with date in brackets
                    field=$(echo "$spaced_filename" | sed -r -n 's/\ \([0-9]{4}\)\ .*$//p')
                    # Series name with date
                    [ -z "$field" ] && field=$(echo "$spaced_filename" | sed -n -r 's/\ [0-9]{4}\ .*$//p')
                    # Series name with season and episode
                    [ -z "$field" ] && field=$(echo "$spaced_filename" | sed -n -r 's/\ s[0-9]{2}e[0-9]{2}\ .*$//Ip')
                fi
                ;;
            'Season')
                if test "$display_season_for_1" -eq 0 || test "$episode" -eq 1; then
                    field=$(echo "$spaced_filename" | sed -r 's/^.*s([0-9]{2})e[0-9]{2}.*$/\1/I')
                fi
                ;;
            'Episode')
                field=$(echo "$spaced_filename" | sed -r 's/^.*s[0-9]{2}e([0-9]{2}).*$/\1/I')
                ;;
            'Year')
                # Year with brackets
                field=$(echo "$spaced_filename" | sed -r -n 's/^.*\ \(([0-9]{4})\)\ .*$/\1/p')
                # Year without brackets
                [ -z "$field" ] && field=$(echo "$spaced_filename" | sed -n -r 's/^.*\ ([0-9]{4})\ .*$/\1/p')
                ;;
            'Resolution')
                field=$(echo "$spaced_filename" | grep -oP '\d+p')
                if [ "$detect_if_not_in_filename" -eq 1 ] && [ -z "$field" ]; then
                    width=$(ffprobe -v error -select_streams v -show_entries stream=width,height -of json "$filepath" | jq '.streams[0] .width')
                    if [ -n "$width" ]; then
                        [ "$width" -le 7680 ] && field='4320p'
                        [ "$width" -le 3840 ] && field='2160p'
                        [ "$width" -le 1920 ] && field='1080p'
                        [ "$width" -le 720 ] && field='720p'
                        [ "$width" -le 640 ] && field='480p'
                    fi
                    unset width
                fi
                ;;
            'Edition')
                # Strip the file extension
                part_filename=$(echo "$spaced_filename" | sed -r 's/\ [0-9a-z]*$//I')
                # Edition in curly brackets (Plex)
                field=$(echo "$part_filename" | sed -n -r 's/.*\{edition-(.*)\}.*/\1/p')
                # Edition after date in brackets and hyphen (jellyin & kodi)
                [ -z "$field" ] && field=$(echo "$part_filename" | sed -n -r 's/.*\([0-9]{4}\)\ -\ (.*)/\1/p')
                # Edition after date in brackets, tmdbid/imdbid in square nrackets and hyphen (jellyin)
                [ -z "$field" ] && field=$(echo "$part_filename" | sed -n -r 's/.*\([0-9]{4}\)\ \[[t|i]mdbid-.*\]\ -\ (.*)/\1/p')
                # Fallback
                [ -z "$field" ] && field=$(echo "$part_filename" |  sed -n -r "s/.*(remastered|theatrical\ cut|special\ edition|cinematic\ cut|extended\ cut|director'?+s\ cut|producer'?+s\ cut|unrated|uncut).*/\1/Ip")
                ;;
            'Video')
                # Strip the file extension
                part_filename=$(echo "$spaced_filename" | sed -r 's/\ [0-9a-z]*$//I')
                # H.261
                ( echo "$part_filename" | grep -i -q '\ x261\ \|\ h-261\ \|\ h261\ \|\ h\ 261\ ' ) && field='H.261'
                # MPEG-1
                ( echo "$part_filename" | grep -i -q '\ mpeg1\ \|\ mpeg-1\ \|\ mpeg\ 1\ ' ) && field='MPEG1'
                # H.263
                ( echo "$part_filename" | grep -i -q '\ x263\ \|\ h263\ \|\ h-263\ \|\ h\ 263\ ' ) && field='H.263'
                # MPEG-2
                ( echo "$part_filename" | grep -i -q '\ mpeg2\ \|\ mpeg-2\ \|\ mpeg\ 2\ \|\ h222\ \|\ h-222\ \|\ h\ 222\ \|\ h262\ \|\ h-262\ \|\ h\ 262\ ' ) && field='MPEG2'
                # MPEG-4
                ( echo "$part_filename" | grep -i -q '\ mpeg-4\ part\ 2\ visual\ \|\ mpeg-4\ \|\ mpeg\ 4\ \|\ mpeg4\ ' ) && field='MPEG4'
                # VC-1
                ( echo "$part_filename" | grep -i -q '\ vc1\ \|\ vc-1\ \|\ vc\ 1\ ' ) && field='VC-1'
                # AVC
                ( echo "$part_filename" | grep -i -q '\ avc\ \|\ x264\ \|\ h264\ \|\ h\ 264\ \|\ h-264\ \|\ mpeg-4\ part\ 10\ ' ) && field='AVC'
                # AVS1
                ( echo "$part_filename" | grep -i -q '\ avs1\ \|\ avs-1 \|\ avs\ 1\ ' ) && field='AVS1'
                # VP8
                ( echo "$part_filename" | grep -i -q '\ vp8\ \|\ vp-8\ \|\ vp\ 8\ ' ) && field='VP8'
                # VC-2
                ( echo "$part_filename" | grep -i -q '\ vc2\ \|\ vc-2\ \|\ vc\ 2\ ' ) && field='VC-2'
                # HEVC
                ( echo "$part_filename" | grep -i -q '\ hevc\ \|\ x265\ \|\ h265\ \|\ h-265\ \|\ h\ 265-\|\ mpeg-h\ part\ 2\ ' ) && field='HEVC'
                # MJPEG
                ( echo "$part_filename" | grep -i -q '\ motion\ jpeg\ \|\ mjpeg\ \|\ m-jpeg\ ' ) && field='MJPEG'
                # VP9
                ( echo "$part_filename" | grep -i -q '\ vp9\ \|\ vp-9\ \|\ vp\ 9\ ' ) && field='VP9'
                # AVS2
                ( echo "$part_filename" | grep -i -q '\ avs2 \|\ avs-2 \|\ avs\ 2\ ' ) && field='AVS2'
                # AV1
                ( echo "$part_filename" | grep -i -q '\ av1\ \|\ av-1\ \|\ av\ 1\ ' ) && field='AV1'
                # AVS3
                ( echo "$part_filename" | grep -i -q '\ avs3 \|\ avs-3 \|\ avs\ 3\ ' ) && field='AVS3'
                # VVC
                ( echo "$part_filename" | grep -i -q '\ vvc\ \|\ x266\ \|\ h266\ \|\ h-266\ \|\ h\ 266\ ' ) && field='VVC'
                # MPEG-5
                ( echo "$part_filename" | grep -i -q '\ lcevc \|\ mpeg5 \|\ mpeg-5\ \|\ mpeg\ 5\ ' ) && field='MPEG5'
                # 3D
                ( echo "$part_filename" | grep -i -q '\ 3d\ ' ) && field="$field 3D"
                # 10-bit
                ( echo "$part_filename" | grep -i -q '\ 10bit\ \|\ 10-bit\ \|\ 10\ bit\ ' ) && field="$field 10-bit"
                # DV
                ( echo "$part_filename" | grep -i -q '\ dv\ ' ) && field="$field DV"
                # HLG
                ( echo "$part_filename" | grep -i -q '\ hlg\ ' ) && field="$field HLG"
                # HDR
                ( echo "$part_filename" | grep -i -q '\ hdr\ ' ) && field="$field HDR"
                # HDR10
                ( echo "$part_filename" | grep -i -q '\ hdr10\ ' ) && field="$field HDR10"
                # HDR10+
                ( echo "$part_filename" | grep -i -q '\ hdr10+\ ' ) && field="$field HDR10+"
                field=$(echo "$field" | sed -r 's/^\ //')
                if [ "$detect_if_not_in_filename" -eq 1 ] && [ -z "$field" ]; then
                    json=$(ffprobe -v error -show_streams -select_streams v:0 -of json -i "$filepath")
                    field=$(echo "$json" | jq '.streams[0] .codec_name' | sed -r 's/\"//g'  | tr '[:lower:]' '[:upper:]')
                    # Resolve name
                    field=$(echo "$field" | sed -r 's/MPEG2VIDEO/MPEG2/' | sed -r 's/H264/AVC/')

                    # @TODO ffprobe/mediainfo unable tp detect DV/HDR10(+) yet
                    # color_space=$(echo "$json" | jq '.streams[0] .color_space' | sed -r 's/\"//g')
                    # color_transfer=$(echo "$json" | jq '.streams[0] .color_transfer' | sed -r 's/\"//g')
                    # color_primaries=$(echo "$json" | jq '.streams[0] .color_primaries' | sed -r 's/\"//g')
                    # [[ "$color_space"='bt2020nc' && "$color_transfer"='smpte2084'  && "$color_primaries"='bt2020' ]] && field="${field} HDR"
                fi
                ;;
            'Audio')
                # Strip the file extension
                part_filename=$(echo "$spaced_filename" | sed -r 's/\ [0-9a-z]*$//I')
                channel_layout=$(echo "$part_filename" | sed -n -r 's/.*\ ([0-9]\ [0-9]).*/\1/p' | tr ' ' '.')
                codec=''
                # DTS
                ( echo "$part_filename" | grep -i -q '\ dts\ ' ) && codec='DTS'
                # DTS:X
                ( echo "$part_filename" | grep -i -q '\ dts\:x\ \|\ dts-x\ ' ) && codec='DTS:X'
                # DTS-MA
                ( echo "$part_filename" | grep -i -q '\ dts-ma\ \|\ dts\ ma\ ' ) && codec='DTS-MA'
                # DTS-HD
                ( echo "$part_filename" | grep -i -q '\ dts-hd\ \|\ dts\ hd\ ' ) && codec='DTS-HD'
                # DTS HD-MA
                ( echo "$part_filename" | grep -i -q '\ dts-hd-ma\ \|\ dts-hd\ ma\ \|\ dts-hdma\ \|\ dts\ hd-ma\ \|\ dts\ hd\ ma\ \|\ dts-hd\ master\ audio\ \|\ dts++\ \|\ dca\ xll' ) && codec='DTS-HD MA'
                # TrueHD
                ( echo "$part_filename" | grep -i -q '\ truehd\ ' ) && codec='TrueHD'
                # Atmos
                ( echo "$part_filename" | grep -i -q '\ atmos\ ' ) && codec='Atmos'
                # FLAC
                ( echo "$part_filename" | grep -i -q '\ flac\ ' ) && codec='FLAC'
                # PCM
                ( echo "$part_filename" | grep -i -q '\ pcm\ \|\ lpcm\ ' ) && codec='PCM'
                # MLP
                ( echo "$part_filename" | grep -i -q '\ mlp\ \|\ ppcm\ ' ) && codec='MLP'
                # MPEG-4 ALS
                ( echo "$part_filename" | grep -i -q '\ mpeg-4\ als\ ' ) && codec='MPEG-4 ALS'
                # MPEG-4 SLS
                ( echo "$part_filename" | grep -i -q '\ mpeg-4\ sls\ ' ) && codec='MPEG-4 SLS'
                # RealAudio
                ( echo "$part_filename" | grep -i -q '\ realaudio\ ' ) && codec='RealAudio'
                # Dolby Digital
                ( echo "$part_filename" | grep -i -q '\ ac3\ \|\ atsc\ a/52\ ' ) && codec='DD'
                # Dolby Digital Plus
                ( echo "$part_filename" | grep -i -q '\ e-ac-3\ ' ) && codec='DD+'
                # Dolby AC-4
                ( echo "$part_filename" | grep -i -q '\ ac-4\ ' ) && codec='Dolby AC4'
                # MPEG Layer 1
                ( echo "$part_filename" | grep -i -q '\ mp-1\ ' ) && codec='MP1'
                # MPEG Layer 2
                ( echo "$part_filename" | grep -i -q '\ mp-2\ ' ) && codec='MP2'
                # MPEG Layer 3
                ( echo "$part_filename" | grep -i -q '\ mp-3\ ' ) && codec='MP3'
                # AAC
                ( echo "$part_filename" | grep -i -q '\ aac\ ') && codec='AAC'
                # AAC
                ( echo "$part_filename" | grep -i -q '\ aac\ ' ) && codec='AAC'
                # APE
                ( echo "$part_filename" | grep -i -q '\ ape\ ' ) && codec='APE'
                if test "$detect_if_not_in_filename" -eq 1 && { test -z "$codec" || test -z "$channel_layout"; }; then
                    json=$(ffprobe -v error -show_streams -select_streams a:0 -of json -i "$filepath")
                    channel_layout=$(echo "$json" | jq '.streams[0] .channel_layout')
                    channel_layout=$(echo "$channel_layout" | sed -r 's/\"//g' | sed -r 's/\(side\)//g' | sed -r 's/mono/1.0/g' | sed -r 's/stereo/2.0/g')
                    codec=$(echo "$json" | jq '.streams[0] .codec_name' | sed -r 's/\"//g'  | tr '[:lower:]' '[:upper:]')
                fi
                field="$codec $channel_layout"
                ;;
            'Release Type')
                part_filename=$(echo "$spaced_filename" | grep -oP '\ \d{4}\ .*')
                [ -z "$part_filename" ] && part_filename=$(echo "$spaced_filename" | grep -oP '\ \-\ .*')
                # Extremely rare
                ( echo "$part_filename" | grep -i -q '\ wp\ \|\ workprint\ ' ) && field='Workprint'
                ( echo "$part_filename" | grep -i -q '\ tc\ \|\ hdtc\ \|\ telecine\ ' ) && field='Telecine'
                # Very rare
                ( echo "$part_filename" | grep -i -q '\ ppv\ \|\ ppvrip\ ' ) && field='Pay-Per-View Rip'
                ( echo "$part_filename" | grep -i -q '\ vodrip\ \|\ vodr\ ' ) && field='VODRip'
                # Rare
                ( echo "$part_filename" | grep -i -q '\ ddc\ ' ) && field='Digital Distribution Copy'
                ( echo "$part_filename" | grep -i -q '\ r5\ \|\ r5\ line\ \|\ r5.ac3.5.1.hq\ ' ) && field='R5'
                ( echo "$part_filename" | grep -i -q '\ web-cap\ \|\ webcap\ \|\ web\ cap\ ' ) && field='WEBCap'
                # Sort of rare
                ( echo "$part_filename" | grep -i -q '\ dvdrip\ \|\ dvdmux\ ' ) && field='DVD-Rip'
                # Uncommon
                ( echo "$part_filename" | grep -i -q '\ ts\ \|\ hdts\ \|\ teleync\ \|\ pdvd\ \|\ predvdrip\ ' ) && field='Telesync'
                ( echo "$part_filename" | grep -i -q '\ scr\ \|\ screener\ \|\ dvdscr\ \|\ dvdscreener\ \|\ bdscr\ \|\ webscreener\ ' ) && field='Screener'
                # Common
                ( echo "$part_filename" | grep -i -q '\ cam-tip\ \|\ cam\ \|\ hdcam\ ' ) && field='Cam'
                ( echo "$part_filename" | grep -i -q '\ dvdr\ \|\ dvd-full\ \|\ full-rip\ \|\ iso\ rip\ \|\ lossless\ rip\ \|\ untouched\ rip\ \|\ dvd-5\ \|\ dvd-9\ ' ) && field='DVD-R'
                ( echo "$part_filename" | grep -i -q '\ dsr\ \|\ dsrip\ \|\ satrip\ \|\ dthrip\ \|\ dvbrip\ \|\ hdtv\ \|\ pdtv\ \|\ dtvrip\ \|\ tvrip\ \|\ hdtvrip\ ' ) && field='HDTV'
                ( echo "$part_filename" | grep -i -q '\ hc\ \|\ hd-rip\ ' ) && field='HC HD-Rip'
                ( echo "$part_filename" | grep -i -q '\ hdrip\ \|\ web-dlrip\ ' ) && field='HDRip'
                ( echo "$part_filename" | grep -i -q '\ webrip\ \|\ web\ rip\ \|\ WEB-Rip\ ' ) && field='WEBRip'
                ( echo "$part_filename" | grep -i -q '\ webdl\ \|\ web\ dl\ \|\ web-dl\ \|\ web\ \|\ webrip\ ' ) && field='Web-DL'
                ( echo "$part_filename" | grep -i -q '\ blu-ray\ \|\ bluray\ \|\ bdiso\ \|\ complete\ bluray\ ' ) && field='Blu-Ray'
                ( echo "$part_filename" | grep -i -q '\ bdrip\ \|\ bd50\ \|\ bd66\ \|\ bd100\ \|\ bd9\ ' ) && field='BDRip'
                ( echo "$part_filename" | grep -i -q '\ brip\ \|\ brrip\ \|\ bdr\ \|\ bd25\ \|\ bd5\ \|\ dbmv\ ' ) && field='BRRip'
                ( echo "$part_filename" | grep -i -q 'remux' ) && field='Remux'
                ;;
            'Size (GB)')
                size_b=$(stat -c '%s' "$filepath")
                field=$(echo "scale=2; $size_b / 1024 / 1024 / 1024" | bc -l)
                ;;
            'Size (MB)')
                size_b=$(stat -c '%s' "$filepath")
                field=$(echo "scale=2; $size_b / 1024 / 1024" | bc -l)
                ;;
            'Size (KB)')
                size_b=$(stat -c '%s' "$filepath")
                field=$(echo "scale=2; $size_b / 1024" | bc -l)
                ;;
            'Size (B)')
                # Generate output from path and size using: $(stat -c '%s' filepath)
                field=$(stat -c '%s' "$filepath")
                ;;
            'Filename')
                field="$filename"
                ;;
            'Full Path')
                field="$filepath"
                ;;
        esac
        col_arr=${col_arr#*:}
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
col_arr="$columns:"
while [ -n "$col_arr" ]; do 
    column=${col_arr%%:*}
    if test -z "$line"; then
        line="\"$column\""
    else
        line="$line,\"$column\""
    fi
    col_arr=${col_arr#*:}
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
