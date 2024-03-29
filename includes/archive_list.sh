#!/bin/sh

saveifs=${IFS}

# shellcheck source=./progressbar.sh
. ./includes/progressbar.sh || exit 1
# shellcheck source=./functions.sh
. ./includes/functions.sh || exit 1
command -v jq >/dev/null 2>&1 || { echo >&2 "I require jq but it's not installed."; exit 1; }

# Import .env vars
if [ ! -e .env ]; then
    echo >&2 'Please configure the .env file'
    exit 1
fi
set -a
# shellcheck source=../.env
. ./.env
set +a

# Reset all variables that might be set
[ -z "$scanner" ] && scanner=''
columns=''

while :; do
    case $1 in
        -h|-\?|--help) 
            show_help
            exit 0
            ;;
        -s|--scanner)       # Takes an option argument, ensuring it has been specified.
            if [ -n "$2" ]; then
                scanner=$2
                shift
            else
                printf 'ERROR: "--scanner" requires a non-empty option argument.\n' >&2
                exit 1
            fi
            ;;
        --scanner=?*)
            scanner=${1#*=} # Delete everything up to "=" and assign the remainder.
            ;;
        --scanner=)         # Handle the case of an empty --file=
            printf 'ERROR: "--scanner" requires a non-empty option argument.\n' >&2
            exit 1
            ;;
        -t|--type)       # Takes an option argument, ensuring it has been specified.
            if [ -n "$2" ]; then
                [ "$2" = "tv" ] && columns="$tv_columns"
                [ "$2" = "movie" ] && columns="$movie_columns"
                if [ -z "$columns" ]; then
                    echo "Invalid archive type: $2"
                    echo "Usage: $(basename "$0") -t [tv,movie]"
                    exit 1
                fi
                shift
            else
                printf 'ERROR: "--file" requires a non-empty option argument.\n' >&2
                exit 1
            fi
            ;;
        --type=?*)
            type=${1#*=} # Delete everything up to "=" and assign the remainder.
            [ "$type" = "tv" ] && columns="$tv_columns"
            [ "$type" = "movie" ] && columns="$movie_columns"
            if [ -z "$columns" ]; then
                echo "Invalid archive type: $2"
                echo "Usage: $(basename "$0") -t [tv,movie]"
                exit 1
            fi
            ;;
        --type=)         # Handle the case of an empty --file=
            printf 'ERROR: "--type" requires a non-empty option argument.\n' >&2
            exit 1
            ;;
        --)              # End of all options.
            shift
            break
            ;;
        -?*)
            printf 'WARN: Unknown option (ignored): %s\n' "$1" >&2
            ;;
        *)               # Default case: If no more options then break out of the loop.
            break
    esac

    shift
done

dir="$1"

if [ -z "$dir" ]; then
    echo 'source directory not defined.'
    echo "Usage: $(basename "$0") /path/to/media/"
    exit 1
fi

# Set the scanner
if test -n "$scanner" && { test "$scanner" = 'ffprobe' || test "$scanner" = 'mediainfo'; }; then
    command -v "$scanner" >/dev/null 2>&1 || { echo "Scanner is set to '$scanner', but it's not installed." >&2; exit 1; }
else
    if command -v ffprobe >/dev/null 2>&1; then
        scanner="ffprobe"
    else
        if command -v mediainfo >/dev/null 2>&1 ; then
            scanner="mediainfo"
        else
            echo "I need at least one scanner, but none found. See the README."
            exit 1
        fi
    fi
fi
printf "setting scanner to %s\n\n" "$scanner" 1>&2
# shellcheck source=./ffprobe.sh
. "./includes/${scanner}.sh" || exit 1


# Create a regex of the extensions for the find command
extensions='m2ts|webm|mkv|flv|vob|ogv|ogg|rrc|gifv|mng|mov|avi|qt|wmv|yuv|asf|amv|mp4|m4p|m4v|mpg|mp2|mpeg|mpe|mpv|m4v|svi|3gp|3g2|mxf|roq|nsv|flv|f4v|f4p|f4a|f4b|mod'
extensions_re="\\($(echo "$extensions" | sed -r 's/\|/\\\|/g')\\)"

filenames_file="$(mktemp)"
find "$dir" -type f -regex ".*\.$extensions_re" 2>&1 > "$filenames_file" | grep -v 'Permission denied' >&2
files_total=$(grep -c . "$filenames_file")
processing_file=0
while IFS= read -r filepath; do
    line=''
    title=''
    series=''
    episode=''
    season=''
    size=0
    metadata=''
    filename=${filepath##*/}
    processing_file=$((processing_file + 1))
    progressbar "$processing_file" "$files_total" "$filename" >&2
    spaced_filename=$(echo "$filename" | sed 's/\./\ /g')
    extra_season=$(get_extra_season "$spaced_filename" "$filepath")
    [ -z "$extra_season" ] && extra_all=$(get_extra_all "$spaced_filename" "$filepath") || extra_all=''
    # Detect if dir contains movies or TV shows
    if [ -z "$columns" ]; then
        echo "$spaced_filename" | grep -Piq ' s\d{2}e\d{2} ' && columns="$tv_columns" || columns="$movie_columns"
    fi
    col_arr="$columns|"
    # For each column
    while [ -n "$col_arr" ]; do 
        column=${col_arr%%|*}
        field=''
        case "$column" in
            'Title')
                title=$(get_title "$spaced_filename")
                directory=$(get_directory "$filepath")
                extras_suffix=$(get_extra_suffix "$spaced_filename")
                if [ "$(get_extra_special "$title")" ]; then
                    # Jellyfin extras special filename
                    if (get_extra_dir "$directory"); then
                        # Edge case of extras special filename in an extras directory 
                        parent_directory=$(get_directory "$filepath")
                        parent_directory=$(get_title "$parent_directory ")
                        title="$parent_directory - $directory - $title"
                    else
                        directory=$(get_title "$directory")
                        title="$directory - $title"
                    fi
                elif [ -n "$(get_extra_dir "$directory")" ]; then
                    # Jellyfin/plex/kodi extras directory
                    parent_directory=$(get_parent_directory "$filepath")
                    parent_directory=$(get_title "$parent_directory ")
                    title="$parent_directory - $directory - $title"
                elif test -n "$extras_suffix"; then
                    # Jellyfin/plex extras filename suffix
                    title=$(title "$directory")" - $extras_suffix"
                fi
                field="$title"
                ;;
            'Series')
                [ -z "$series" ] && series=$(get_series "$extra_season" "$extra_all" "$spaced_filename" "$filepath")
                [ -z "$season" ] && season=$(get_season "$extra_all" "$spaced_filename" "$filepath")
                [ -z "$episode" ] && episode=$(get_episode "$extra_season" "$extra_all" "$spaced_filename")
                if test "$display_series_for_1" -eq 0 || { test "$season" = "01" && test "$episode" = "01"; }; then
                    field="$series"
                fi
                ;;
            'Season')
                [ -z "$series" ] && series=$(get_series "$extra_season" "$extra_all" "$spaced_filename" "$filepath")
                [ -z "$season" ] && season=$(get_season "$extra_all" "$spaced_filename" "$filepath")
                [ -z "$episode" ] && episode=$(get_episode "$extra_season" "$extra_all" "$spaced_filename")
                if [ "$display_season_for_1" -eq 0 ] || [ "$episode" = '01' ] || [ "$season" = 'extra' ]; then
                    field="$season"
                fi
                ;;
            'Episode')
                [ -z "$episode" ] && episode=$(get_episode "$extra_season" "$extra_all" "$spaced_filename")
                field="$episode"
                ;;
            'Year')
                year=$(get_year "$spaced_filename")
                # no year from filename, test parent directories
                if [ -z "$year" ]; then
                    directory=$(get_directory "$filepath")
                    year=$(get_year "$directory")
                fi
                if [ -z "$year" ]; then
                    directory=$(get_parent_directory "$filepath")
                    year=$(get_year "$directory")
                fi
                if [ -z "$year" ]; then
                    directory=$(get_grandparent_directory "$filepath")
                    year=$(get_year "$directory")
                fi
                field="$year"
                ;;
            'Resolution')
                field=$(echo "$spaced_filename" | grep -oP '\d+p')
                if { test -n "$force_detect" && test "$force_detect" -eq 1; } || { test "$detect_if_not_in_filename" -eq 1  && test -z "$field"; }; then
                    [ -z "$metadata" ] && metadata=$(video_data "$filepath")
                    field=$(resolution "$metadata")
                fi
                ;;
            'Edition')
                # Edition in curly brackets (Plex)
                field=$(echo "$spaced_filename" | sed -nr 's/.*\{edition-(.*)\}.*/\1/p' | tr '[:upper:]' '[:lower:]')
                # Edition after date in brackets and hyphen (jellyin & kodi)
                [ -z "$field" ] && field=$(echo "$spaced_filename" | sed -nr 's/.*\([0-9]{4}\)\ -\ (.*)/\1/p' | tr '[:upper:]' '[:lower:]')
                # Edition after date in brackets, tmdbid/imdbid in square brackets and hyphen (jellyin)
                [ -z "$field" ] && field=$(echo "$spaced_filename" | sed -nr 's/.*\([0-9]{4}\)\ \[[t|i]mdbid-.*\]\ -\ (.*)/\1/p' | tr '[:upper:]' '[:lower:]')
                # Fallback
                [ -z "$field" ] && field=$(echo "$spaced_filename" | grep -E -io '(remastered|theatrical cut|special edition|cinematic cut|extended cut|director'\''?s cut|producer'\''?s cut|unrated|uncut)' | tr '\n' ' ' | sed 's/^\ //' | sed 's/\ $//' | tr '[:upper:]' '[:lower:]')
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
    sort_col=''
    if [ -n "$title" ]; then
        sort_col="$title"
        [ -n "$extra_all" ] && sort_col="$sort_col $extra_all"
    elif [ -n "$series" ]; then
        sort_col="$series"
        if [ -n "$extra_all" ]; then
            sort_col="$sort_col extra"
        elif [ -n "$season" ]; then
            sort_col="$sort_col $season"
        fi
        if [ -n "$episode" ]; then
            sort_col="$sort_col $episode"
        fi
    fi
    output="${output}${line},\"$sort_col\";"
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
output="$line,\"Sort\";$output"

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
