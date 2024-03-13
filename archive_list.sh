#!/bin/sh

saveifs=${IFS}

. ./progressbar.sh || exit 1
command -v jq >/dev/null 2>&1 || { echo >&2 "I require jq but it's not installed."; exit 1; }

# Import .env vars
if [ ! -e .env ]; then
    echo >&2 'Please configure the .env file'
    exit 1
fi
set -a
. ./.env
set +a

# Set the scanner
if test -n "$scanner" && { test "$scanner" = 'ffprobe' || test "$scanner" = 'mediainfo'; }; then
    command -v "$scanner" >/dev/null 2>&1 || { echo "$scanner is specified in the config, but it's not installed." >&2; exit 0; }
elif test -n "$scanner" && test "$scanner" != 'auto'; then
    echo "Invalid scanner config: '$scanner'. See the README." 2>&1
    exit 0
else
    if command -v ffprobe >/dev/null 2>&1; then
        scanner="ffprobe"
    else
        if command -v mediainfo >/dev/null 2>&1 ; then
            scanner="mediainfo"
        else
            echo "I need at least one scanner, but none found. See the README."
            exit 0
        fi
    fi
fi
printf "setting scanner to %s\n\n" "$scanner" 1>&2
# shellcheck source=ffprobe.sh
. "./${scanner}.sh" || exit 1

extensions='m2ts|webm|mkv|flv|vob|ogv|ogg|rrc|gifv|mng|mov|avi|qt|wmv|yuv|asf|amv|mp4|m4p|m4v|mpg|mp2|mpeg|mpe|mpv|m4v|svi|3gp|3g2|mxf|roq|nsv|flv|f4v|f4p|f4a|f4b|mod'
dir=$1

# Create a regex of the extensions for the find command
extensions_re="\\($(echo "$extensions" | sed -r 's/\|/\\\|/g')\\)"

columns=''
filenames_file="$(mktemp)"
metadata=''
find "$dir" -type f -regex ".*\.$extensions_re" 2>&1 > "$filenames_file" | grep -v 'Permission denied' >&2
files_total=$(grep -c . "$filenames_file")
processing_file=0
while IFS= read -r filepath; do
    line=''
    episode=''
    season=''
    size=0
    metadata=''
    filename=${filepath##*/}
    processing_file=$((processing_file + 1))
    progressbar "$processing_file" "$files_total" "$filename" >&2
    spaced_filename=$(echo "$filename" | sed 's/\./\ /g')
    # Detect if dir contains movies or TV shows
    if [ -z "$columns" ]; then
        # shellcheck disable=SC2128
        echo "$spaced_filename" | grep -Piq ' s\d{2}e\d{2} ' && columns="$tv_columns" || columns="$movie_columns"
    fi
    col_arr="$columns|"
    # For each column
    while [ -n "$col_arr" ]; do 
        column=${col_arr%%|*}
        field=''
        case "$column" in
            'Title')
                # Title with date in brackets
                field=$(echo "$spaced_filename" | grep -ioP '.*?(?= \(\d{4}\) )')
                # Title with date
                [ -z "$field" ] && field=$(echo "$spaced_filename" | grep -ioP '.*?(?= \d{4} )')
                ;;
            'Series')
                test -z "$season" && season=$(echo "$spaced_filename" | sed -r 's/^.*s([0-9]{2})e[0-9]{2}.*$/\1/I')
                test -z "$episode" && episode=$(echo "$spaced_filename" | sed -r 's/^.*s[0-9]{2}e([0-9]{2}).*$/\1/I')
                if test "$display_series_for_1" -eq 0 || { test "$season" -eq 1 && test "$episode" -eq 1; }; then
                    field=$(echo "$spaced_filename" | grep -ioP '.*?(?= s\d{2}e\d{2} )')
                fi
                ;;
            'Season')
                test -z "$episode" && episode=$(echo "$spaced_filename" | sed -r 's/^.*s[0-9]{2}e([0-9]{2}).*$/\1/I')
                if test "$display_season_for_1" -eq 0 || test "$episode" -eq 1; then
                    test -z "$season" && season=$(echo "$spaced_filename" | sed -r 's/^.*s([0-9]{2})e[0-9]{2}.*$/\1/I')
                    field="$season"
                fi
                ;;
            'Episode')
                test -z "$episode" && episode=$(echo "$spaced_filename" | sed -r 's/^.*s[0-9]{2}e([0-9]{2}).*$/\1/I')
                field="$episode"
                ;;
            'Year')
                # Year with brackets
                field=$(echo "$spaced_filename" | grep -ioP ' \(\d{4}\) ')
                # Year without brackets
                [ -z "$field" ] && field=$(echo "$spaced_filename" | grep -ioP ' \d{4} ')
                field=$(echo "$field"  | grep -ioP '\d{4}')
                ;;
            'Resolution')
                field=$(echo "$spaced_filename" | grep -oP '\d+p')
                if { test -n "$force_detect" && test "$force_detect" -eq 1; } || { test "$detect_if_not_in_filename" -eq 1  && test -z "$field"; }; then
                    [ -z "$metadata" ] && metadata=$(video_data "$filepath")
                    field=$(resolution "$metadata")
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
                [ -z "$field" ] && field=$(echo "$part_filename" | grep -E -io '(remastered|theatrical cut|special edition|cinematic cut|extended cut|director'\''?s cut|producer'\''?s cut|unrated|uncut)' | tr '\n' ' ' | sed 's/^\ //' | sed 's/\ $//')
                ;;
            'Video')
                codec=''
                codec_features=''
                # H.261
                ( echo "$spaced_filename" | grep -iq ' x261 \| h-261 \| h261 \| h 261 ' ) && codec='H.261'
                # MPEG-1
                ( echo "$spaced_filename" | grep -iq ' mpeg1 \| mpeg-1 \| mpeg 1 ' ) && codec='MPEG1'
                # H.263
                ( echo "$spaced_filename" | grep -iq ' x263 \| h263 \| h-263 \| h 263 ' ) && codec='H.263'
                # MPEG-2
                ( echo "$spaced_filename" | grep -iq ' mpeg2 \| mpeg-2 \| mpeg 2 \| h222 \| h-222 \| h 222 \| h262 \| h-262 \| h 262 ' ) && codec='MPEG2'
                # MPEG-4
                ( echo "$spaced_filename" | grep -iq ' mpeg-4 part 2 visual \| mpeg-4 \| mpeg 4 \| mpeg4 ' ) && codec='MPEG4'
                # VC-1
                ( echo "$spaced_filename" | grep -iq ' vc1 \| vc-1 \| vc 1 ' ) && codec='VC-1'
                # AVC
                ( echo "$spaced_filename" | grep -iq ' avc \| x264 \| h264 \| h 264 \| h-264 \| mpeg-4 part 10 ' ) && codec='AVC'
                # AVS1
                ( echo "$spaced_filename" | grep -iq ' avs1 \| avs-1 \| avs 1 ' ) && codec='AVS1'
                # VP8
                ( echo "$spaced_filename" | grep -iq ' vp8 \| vp-8 \| vp 8 ' ) && codec='VP8'
                # VC-2
                ( echo "$spaced_filename" | grep -iq ' vc2 \| vc-2 \| vc 2 ' ) && codec='VC-2'
                # HEVC
                ( echo "$spaced_filename" | grep -iq ' hevc \| x265 \| h265 \| h-265 \| h 265-\| mpeg-h part 2 ' ) && codec='HEVC'
                # MJPEG
                ( echo "$spaced_filename" | grep -iq ' motion jpeg \| mjpeg \| m-jpeg ' ) && codec='MJPEG'
                # VP9
                ( echo "$spaced_filename" | grep -iq ' vp9 \| vp-9 \| vp 9 ' ) && codec='VP9'
                # AVS2
                ( echo "$spaced_filename" | grep -iq ' avs2 \| avs-2 \| avs 2 ' ) && codec='AVS2'
                # AV1
                ( echo "$spaced_filename" | grep -iq ' av1 \| av-1 \| av 1 ' ) && codec='AV1'
                # AVS3
                ( echo "$spaced_filename" | grep -iq ' avs3 \| avs-3 \| avs 3 ' ) && codec='AVS3'
                # VVC
                ( echo "$spaced_filename" | grep -iq ' vvc \| x266 \| h266 \| h-266 \| h 266 ' ) && codec='VVC'
                # MPEG-5
                ( echo "$spaced_filename" | grep -iq ' lcevc \| mpeg5 \| mpeg-5 \| mpeg 5 ' ) && codec='MPEG5'
                # 3D
                ( echo "$spaced_filename" | grep -iq ' 3d ' ) && codec_features="$codec_features 3D"
                # 10-bit
                ( echo "$spaced_filename" | grep -iq ' 10bit \| 10-bit \| 10 bit ' ) && codec_features="$codec_features 10-bit"
                # DV
                ( echo "$spaced_filename" | grep -iq ' dv ' ) && codec_features="$codec_features DV"
                # HLG
                ( echo "$spaced_filename" | grep -iq ' hlg ' ) && codec_features="$codec_features HLG"
                # HDR
                ( echo "$spaced_filename" | grep -iq ' hdr ' ) && codec_features="$codec_features HDR"
                # HDR10
                ( echo "$spaced_filename" | grep -iq ' hdr10 ' ) && codec_features="$codec_features HDR10"
                # HDR10+
                ( echo "$spaced_filename" | grep -iq ' hdr10+ ' ) && codec_features="$codec_features HDR10+"
                if { test -n "$force_detect" && test "$force_detect" -eq 1; } || { test "$detect_if_not_in_filename" -eq 1 && test -z "$codec"; }; then
                    [ -z "$metadata" ] && metadata=$(video_data "$filepath")
                    field=$(video "$metadata")
                else
                    field="${codec}${codec_features}"
                fi
                ;;
            'Audio')
                channel_layout=$(echo "$spaced_filename" | sed -n -r 's/.*\ ([0-9]\ [0-9]).*/\1/p' | tr ' ' '.')
                codec=''
                # DTS
                ( echo "$spaced_filename" | grep -iq ' dts ' ) && codec='DTS'
                # DTS:X
                ( echo "$spaced_filename" | grep -iq ' dts:x \| dts-x ' ) && codec='DTS:X'
                # DTS-MA
                ( echo "$spaced_filename" | grep -iq ' dts-ma \| dts ma ' ) && codec='DTS-MA'
                # DTS-HD
                ( echo "$spaced_filename" | grep -iq ' dts-hd \| dts hd ' ) && codec='DTS-HD'
                # DTS HD-MA
                ( echo "$spaced_filename" | grep -iq ' dts-hd-ma \| dts-hd ma \| dts-hdma \| dts hd-ma \| dts hd ma \| dts-hd master audio \| dts++ \| dca xll' ) && codec='DTS-HD MA'
                # TrueHD
                ( echo "$spaced_filename" | grep -iq ' truehd ' ) && codec='TrueHD'
                # Atmos
                ( echo "$spaced_filename" | grep -iq ' atmos ' ) && codec='Atmos'
                # FLAC
                ( echo "$spaced_filename" | grep -iq ' flac ' ) && codec='FLAC'
                # PCM
                ( echo "$spaced_filename" | grep -iq ' pcm \| lpcm ' ) && codec='PCM'
                # MLP
                ( echo "$spaced_filename" | grep -iq ' mlp \| ppcm ' ) && codec='MLP'
                # MPEG-4 ALS
                ( echo "$spaced_filename" | grep -iq ' mpeg-4 als ' ) && codec='MPEG-4 ALS'
                # MPEG-4 SLS
                ( echo "$spaced_filename" | grep -iq ' mpeg-4 sls ' ) && codec='MPEG-4 SLS'
                # RealAudio
                ( echo "$spaced_filename" | grep -iq ' realaudio ' ) && codec='RealAudio'
                # Dolby Digital
                ( echo "$spaced_filename" | grep -iq ' ac3 \| atsc a/52 ' ) && codec='DD'
                # Dolby Digital Plus
                ( echo "$spaced_filename" | grep -iq ' e-ac-3 ' ) && codec='DD+'
                # Dolby AC-4
                ( echo "$spaced_filename" | grep -iq ' ac-4 ' ) && codec='Dolby AC4'
                # MPEG Layer 1
                ( echo "$spaced_filename" | grep -iq ' mp-1 ' ) && codec='MP1'
                # MPEG Layer 2
                ( echo "$spaced_filename" | grep -iq ' mp-2 ' ) && codec='MP2'
                # MPEG Layer 3
                ( echo "$spaced_filename" | grep -iq ' mp-3 ' ) && codec='MP3'
                # AAC
                ( echo "$spaced_filename" | grep -iq ' aac ') && codec='AAC'
                # AAC
                ( echo "$spaced_filename" | grep -iq ' aac ' ) && codec='AAC'
                # APE
                ( echo "$spaced_filename" | grep -iq ' ape ' ) && codec='APE'
                if { test -n "$force_detect" && test "$force_detect" -eq 1; } || { test "$detect_if_not_in_filename" -eq 1 && { test -z "$codec" || test -z "$channel_layout"; }; }; then
                    [ -z "$metadata" ] && metadata=$(video_data "$filepath")
                    field=$(audio "$metadata")
                else
                    field="$codec $channel_layout"
                fi
                ;;
            'Subtitles')
                [ -z "$metadata" ] && metadata=$(video_data "$filepath")
                field=$(subtitle "$metadata")
                ;;
            'Release Type')
                part_filename=$(echo "$spaced_filename" | grep -oP ' \d{4} .*')
                [ -z "$part_filename" ] && part_filename=$(echo "$spaced_filename" | grep -oP ' - .*')
                # Extremely rare
                ( echo "$part_filename" | grep -iq ' wp \| workprint ' ) && field='Workprint'
                ( echo "$part_filename" | grep -iq ' tc \| hdtc \| telecine ' ) && field='Telecine'
                # Very rare
                ( echo "$part_filename" | grep -iq ' ppv \| ppvrip ' ) && field='Pay-Per-View Rip'
                ( echo "$part_filename" | grep -iq ' vodrip \| vodr ' ) && field='VODRip'
                # Rare
                ( echo "$part_filename" | grep -iq ' ddc ' ) && field='Digital Distribution Copy'
                ( echo "$part_filename" | grep -iq ' r5 \| r5 line \| r5.ac3.5.1.hq ' ) && field='R5'
                ( echo "$part_filename" | grep -iq ' web-cap \| webcap \| web cap ' ) && field='WEBCap'
                # Sort of rare
                ( echo "$part_filename" | grep -iq ' dvdrip \| dvdmux ' ) && field='DVD-Rip'
                # Uncommon
                ( echo "$part_filename" | grep -iq ' ts \| hdts \| teleync \| pdvd \| predvdrip ' ) && field='Telesync'
                ( echo "$part_filename" | grep -iq ' scr \| screener \| dvdscr \| dvdscreener \| bdscr \| webscreener ' ) && field='Screener'
                # Common
                ( echo "$part_filename" | grep -iq ' cam-tip \| cam \| hdcam ' ) && field='Cam'
                ( echo "$part_filename" | grep -iq ' dvdr \| dvd-full \| full-rip \| iso rip \| lossless rip \| untouched rip \| dvd-5 \| dvd-9 ' ) && field='DVD-R'
                ( echo "$part_filename" | grep -iq ' dsr \| dsrip \| satrip \| dthrip \| dvbrip \| hdtv \| pdtv \| dtvrip \| tvrip \| hdtvrip ' ) && field='HDTV'
                ( echo "$part_filename" | grep -iq ' hc \| hd-rip ' ) && field='HC HD-Rip'
                ( echo "$part_filename" | grep -iq ' hdrip \| web-dlrip ' ) && field='HDRip'
                ( echo "$part_filename" | grep -iq ' webrip \| web rip \| WEB-Rip ' ) && field='WEBRip'
                ( echo "$part_filename" | grep -iq ' webdl \| web dl \| web-dl \| web \| webrip ' ) && field='Web-DL'
                ( echo "$part_filename" | grep -iq ' blu-ray \| bluray \| bdiso \| complete bluray ' ) && field='Blu-Ray'
                ( echo "$part_filename" | grep -iq ' bdrip \| bd50 \| bd66 \| bd100 \| bd9 ' ) && field='BDRip'
                ( echo "$part_filename" | grep -iq ' brip \| brrip \| bdr \| bd25 \| bd5 \| dbmv ' ) && field='BRRip'
                ( echo "$part_filename" | grep -iq 'remux' ) && field='Remux'
                ;;
            'Size (GB)')
                test "$size" -eq 0 && size=$(stat -c '%s' "$filepath")
                field=$( echo "scale=2; $size / 1073741824" | bc )
                ;;
            'Size (MB)')
                test "$size" -eq 0 && size=$(stat -c '%s' "$filepath")
                field=$( echo "scale=2; $size / 1048576" | bc )
                ;;
            'Size (KB)')
                test "$size" -eq 0 && size=$(stat -c '%s' "$filepath")
                field=$( echo "scale=2; $size / 1024" | bc )
                ;;
            'Size (B)')
                test "$size" -eq 0 && size=$(stat -c '%s' "$filepath")
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
done < "$filenames_file"
rm "$filenames_file"

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
echo >&2
