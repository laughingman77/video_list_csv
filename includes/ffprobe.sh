#!/bin/sh

# Replace control charaters with a space.
#
# This fixes potential issues in tag fields that contain newlines and tabs,
# which causes ffprobe to produce invalid JSON which in turn breaks JQ.
#
# $1 String to clean
#
# @returns string
#
# Example:
#   metadata=$(strip_control_chars "$(ffprobe -v error -print_format json -show_format -show_streams "$_video_file")")
strip_control_chars() {
    _result=$(echo "$1" | tr -d "\r" | tr -d "\n" | tr -d "\t")
    printf "%s" "$_result"
}

# Return video file metadata using ffprobe in JSON format.
#
# $1 _video_file Path to the video file
#
# @returns JSON string
#
# Example:
#   video_data "/path/to/video.mkv"
video_data() {
    _video_file="$1"
    _result=$(strip_control_chars "$(ffprobe -v error -print_format json -show_format -show_streams "$_video_file")")
    echo "$_result"
}

# Return the resolution of each video stream in a video file, using pre-generated JSON metadata.
# @see video_data()
#
# $1 _metadata ffrpobe JSON
# $2 _default_stream Display default stream
#
# @returns Resolution string
#
# Example:
#   foobar=$(resolution "$metadata" 1)
resolution() {
    _metadata=$1
    _default_stream=$2
    _video_streams=$(printf "%s" "$_metadata" | jq -c '.streams[] | select(.codec_type == "video") | {ID: .index, Width: .width, Default: .disposition.default}')
    _linecount=$(echo "$_video_streams" | wc -l)
    _result=''
    _results=''
    IFS='
'
    for _video_stream in $_video_streams; do
        # Extract field values for a stream
        _id=$(echo "$_video_stream" | sed 's/.*"ID":\([0-9]*\),.*/\1/')
        _width=$(echo "$_video_stream" | sed 's/.*"Width":\([0-9]*\).*/\1/')
        _default=$(echo "$_video_stream" | sed -n 's/.*"Default":\([0-9]*\).*/\1/p')
        # Map width to a resolution
        _resolution='480p'
        test "$_width" -gt 640 && _resolution='720p'
        test "$_width" -gt 720 && _resolution='1080p'
        test "$_width" -gt 1920 && _resolution='2160p'
        test "$_width" -gt 3840 && _resolution='4320p'
        # Concatenate info parts into the field line
        if [ "$_default"  -eq 1 ] || [ "$_linecount" -eq 1 ]; then
            _result="${_resolution}"
        fi
        _results="${_results}stream_${_id}: ${_resolution}, "
    done
    
    if { [ "$_default_stream" -eq 1 ] && [ ! "$_result" = '' ]; } || [ "$_linecount" -eq 1 ]; then
        echo "$_result"
    else
        # Strip trailing characters and bad spaces
        _results=$(echo "$_results" | sed 's/,\ $//')
        echo "$_results"
    fi
}

# Return the colour mode of each video stream in a video file, using pre-generated JSON metadata.
# @see ffprobe does not currently support this.
#
# $1 _metadata ffrpobe JSON
# $2 _default_stream Display default stream
#
# @returns Video colour mode string
#
# Example:
#   foobar=$(video "$colour_mode" 1)
colour_mode() {
    _metadata=$1
    _default_stream=$2
    echo ""
}

# Return the codecs of each video stream in a video file, using pre-generated JSON metadata.
# @see video_data()
#
# $1 _metadata ffrpobe JSON
# $2 _default_stream Display default stream
#
# @returns Video codec string
#
# Example:
#   foobar=$(video "$metadata" 1)
video() {
    _metadata=$1
    _default_stream=$2
    _video_streams=$(echo "$_metadata" | jq -c '.streams[] | select(.codec_type == "video") | {"ID": .index, "codec_long_name": .codec_long_name, color_transfer: .color_transfer, default: .disposition.default}')
    _linecount=$(echo "$_video_streams" | wc -l)
    _result=''
    _results=''
    IFS='
'
    for _video_stream in $_video_streams; do
        _additional_info=''
        # Extract field values for a stream
        _id=$(echo "$_video_stream" | sed 's/.*"ID":\([0-9]*\),.*/\1/')
        _color_transfer=$(echo "$_video_stream" | sed -n 's/.*"color_transfer":"\([^"]*\)".*/\1/p')
        _codec=$(echo "$_video_stream" | sed -n 's/.*"codec_long_name":"\([^"]*\)".*/\1/p')
        _default=$(echo "$_video_stream" | sed -n 's/.*"default":\([0-9]*\).*/\1/p')
        # Tidy Codec text
        test "${_codec#*"/ AVC /"}" != "$_codec" && _codec='AVC'
        test "${_codec#*"PNG"}" != "$_codec" && _codec='PNG'
        test "${_codec#*"HEVC"}" != "$_codec" && _codec='HEVC'
        test "${_codec#*"VC-1"}" != "$_codec" && _codec='VC-1'
        test "${_codec#*"MPEG-2"}" != "$_codec" && _codec='MPEG-2'
        test "${_codec#*"MPEG-4"}" != "$_codec" && _codec='MPEG-4'
        test "${_codec#*"Motion JPEG"}" != "$_codec" && _codec='MJPEG'
        test "${_codec#*"VP9"}" != "$_codec" && _codec='VP9'
        test "${_color_transfer#*"arib-std-b67"}" != "$_color_transfer" && _additional_info="${_additional_info}HLG "
        if [ "$( echo "$_metadata" | jq '.streams[] | select(.codec_type == "video") | has("side_data_list")' )" = 'true' ]; then
            if [ ! "$(echo "$_metadata" | jq '.streams[] | select(.codec_type == "video") | .side_data_list[] | select(.side_data_type == "DOVI configuration record") // false')" = 'false' ]; then
                _additional_info="${_additional_info}DV "
            fi
        fi
        # @TODO 3D, HDR10, HDR10+
        # Concatenate the stream info parts into the field
        if [ "$_default" -eq 1 ] || [ "$_linecount" -eq 1 ]; then
            _result="${_codec}"
            if [ -n "$_additional_info" ]; then
                _result="${_result} ${_additional_info}"
            fi
        fi
        _results="${_results}stream_${_id}: ${_codec}"
        if [ -n "$_additional_info" ]; then
            _results="${_results} ${_additional_info}"
        fi
        _results="${_results}, "
    done

    if { [ "$_default_stream" -eq 1 ] && [ ! "$_result" = '' ]; } || [ "$_linecount" -eq 1 ]; then
        _result=$(echo "$_result" | sed 's/\ $//')
        echo "$_result"
    else
        # Strip trailing characters and bad spaces
        _results=$(echo "$_results" | sed 's/,\ $//' | sed 's/\ ,\ /,\ /g' | sed 's/\ $//')
        echo "$_results"
    fi
}

# Return the codecs of each audio stream in a video file, using pre-generated JSON metadata.
# @see video_data()
#
# $1 _metadata ffprobe JSON
# $2 _default_stream Display default stream
#
# @returns Video codec string
#
# Example:
#   foobar=$(audio "$metadata" "1")
audio() {
    _metadata=$1
    _default_stream=$2
    _audio_streams=$(echo "$_metadata" | jq -c '.streams[] | select(.codec_type == "audio") | { ID: .index, profile: .profile, codec_long_name: .codec_long_name, channel_layout: .channel_layout, channels: .channels, language: .tags.language, default: .disposition.default }')
    _linecount=$(echo "$_audio_streams" | wc -l)
    _result=''
    _results=''
    IFS='
'
    for _audio_stream in $_audio_streams; do
        # Extract field values for the stream
        _id=$(echo "$_audio_stream" | sed 's/.*"ID":\([0-9]*\).*/\1/')
        _profile=$(echo "$_audio_stream" | sed -n 's/.*"profile":"\([^"]*\)".*/\1/p')
        _codec_long_name=$(echo "$_audio_stream" | sed -n 's/.*"codec_long_name":"\([^"]*\)".*/\1/p')
        _language=$(echo "$_audio_stream" | sed -n 's/.*"language":"\([^"]*\)".*/\1/p')
        _default=$(echo "$_audio_stream" | sed -n 's/.*"default":\([0-9]*\).*/\1/p')
        # Tidy Codec text
        test -n "$_profile" && _codec="$_profile" || _codec="$_codec_long_name"
        test "${_codec#*"PCM"}" != "$_codec" && _codec='PCM'
        test "${_codec#*"Atmos"}" != "$_codec" && _codec='Atmos'
        test "${_codec#*"DTS:X"}" != "$_codec" && _codec='DTS:X'
        test "${_codec#*"AC-3"}" != "$_codec" && _codec='AC-3'
        test "${_codec#*"Opus"}" != "$_codec" && _codec='Opus'
        test "${_codec#*"Windows Media Audio"}" != "$_codec" && _codec='WMA'
        test "${_codec#*"MP2"}" != "$_codec" && _codec='MP2'
        test "${_codec#*"MP3"}" != "$_codec" && _codec='MP3'
        test "${_codec#*"FLAC"}" != "$_codec" && _codec='FLAC'
        test "${_codec_long_name#*"AAC"}" != "$_codec_long_name" && _codec='AAC'
        test "${_codec_long_name#*"PCM"}" != "$_codec_long_name" && _codec='PCM'
        # Tidy Channels text
        _channel_layout=$(echo "$_audio_stream" | sed -n 's/.*"channel_layout":"\([^"]*\)".*/\1/p' | sed 's/(side)//' | sed 's/stereo/2.0/' | sed 's/mono/1.0/')
        if [ -z "$_channel_layout" ]; then
            _channel_layout=$(echo "$_audio_stream" | sed 's/.*"channels":\([0-9]*\).*/\1/')
            test "$_channel_layout" = '1' && _channel_layout='1.0'
            test "$_channel_layout" = '2' && _channel_layout='2.0'
            test "$_channel_layout" = '4' && _channel_layout='3.1'
            test "$_channel_layout" = '5' && _channel_layout='4.1'
            test "$_channel_layout" = '6' && _channel_layout='5.1'
            test "$_channel_layout" = '7' && _channel_layout='6.1'
            test "$_channel_layout" = '8' && _channel_layout='7.1'
        fi
        test ! "$_language" = '' && _language=" (${_language})"
        # Concatenate the stream info parts into the field
        if [ "$_default"  -eq 1 ] || [ "$_linecount" -eq 1 ]; then
            _result="${_codec} ${_channel_layout}${_language}"
        fi
        _results="${_results}stream_${_id}: ${_codec} ${_channel_layout}${_language}, "
    done

    if { [ "$_default_stream" -eq 1 ] && [ ! "$_result" = '' ]; } || [ "$_linecount" -eq 1 ]; then
        echo "$_result"
    else
        # Strip trailing characters and bad spaces
        _results=$(echo "$_results" | sed 's/,\ $//'  | sed 's/\ ,\ /,\ /g' | sed 's/\ $//')
        echo "$_results"
    fi
}

# Return the languages for each subtitle stream of a video file, using pre-generated JSON metadata.
# @see video_data()
#
# $1 _metadata ffprobe JSON
#
# @returns string of comma separtated subtitle languageas
#
# Example:
#   foobar=$(subtitle "$metadata")
subtitle() {
    _metadata=$1
    _result=$(echo "$_metadata" | jq -c '[.streams[] | select(.codec_type == "subtitle") .tags .language] | unique' | sed 's/,/,\ /g' | sed 's/[]["]//g')
    echo "$_result"
}

# Return the running time in seconds of a video file, using pre-generated JSON metadata.
# @see video_data()
#
# $1 _metadata mediainfo JSON
#
# @returns string of the runtime in seconds without any decimal places.
#
# Example:
#   foobar=$(running_time "$metadata")
running_time_s() {
    _metadata=$1
    _seconds=$(echo "$_metadata" | jq -c '.format.duration' | sed 's/\.[0-9]*//g' | bc)
    echo "$_seconds"
}
