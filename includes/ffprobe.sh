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
#
# @returns Resolution string
#
# Example:
#   foobar=$(resolution "$metadata")
resolution() {
    _metadata="$1"
    _video_streams=$(printf "%s" "$_metadata" | jq -c '.streams[] | select(.codec_type == "video") | {ID: .index, Width: .width}')
    _linecount=$(echo "$_video_streams" | wc -l)
    _result=''
    IFS='
'
    for _video_stream in $_video_streams; do
        # Extract field values for a stream
        _id=$(echo "$_video_stream" | sed 's/.*"ID":\([0-9]*\),.*/\1/')
        _width=$(echo "$_video_stream" | sed 's/.*"Width":\([^}]*\).*/\1/')
        # Map width to a resolution
        _resolution='480p'
        test "$_width" -gt 640 && _resolution='720p'
        test "$_width" -gt 720 && _resolution='1080p'
        test "$_width" -gt 1920 && _resolution='2160p'
        test "$_width" -gt 3840 && _resolution='4320p'
        # Concatenate info parts into the field line
        test "$_linecount" -gt 1 && _result="${_result}stream_${_id}: "
        _result="${_result}${_resolution}, "
    done
    # Strip trailing characters and bad spaces
    _result=$(echo "$_result" | sed 's/,\ $//')
    echo "$_result"
}

# Return the codecs of each video stream in a video file, using pre-generated JSON metadata.
# @see video_data()
#
# $1 _metadata ffrpobe JSON
#
# @returns Video codec string
#
# Example:
#   foobar=$(video "$metadata")
video() {
    _metadata=$1
    _video_streams=$(echo "$_metadata" | jq -c '.streams[] | select(.codec_type == "video") | {"ID": .index, "codec_long_name": .codec_long_name, color_transfer: .color_transfer}')
    _linecount=$(echo "$_video_streams" | wc -l)
    _result=''
    IFS='
'
    for _video_stream in $_video_streams; do
        _additional_info=''
        # Extract field values for a stream
        _id=$(echo "$_video_stream" | sed 's/.*"ID":\([0-9]*\),.*/\1/')
        _color_transfer=$(echo "$_video_stream" | sed -n 's/.*"color_transfer":"\([^"]*\)".*/\1/p')
        _codec=$(echo "$_video_stream" | sed -n 's/.*"codec_long_name":"\([^"]*\)".*/\1/p')
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
        test "$_linecount" -gt 1 && _result="${_result}stream_${_id}: "
        _result="${_result}${_codec} ${_additional_info}, "
    done
    # Strip trailing characters and bad spaces
    _result=$(echo "$_result" | sed 's/,\ $//'  | sed 's/\ ,\ /,\ /g' | sed 's/\ $//')
    echo "$_result"
}

# Return the codecs of each audio stream in a video file, using pre-generated JSON metadata.
# @see video_data()
#
# $1 _metadata ffprobe JSON
#
# @returns Video codec string
#
# Example:
#   foobar=$(audio "$metadata")
audio() {
    _metadata=$1
    _audio_streams=$(echo "$_metadata" | jq -c '.streams[] | select(.codec_type == "audio") | { ID: .index, profile: .profile, codec_long_name: .codec_long_name, channel_layout: .channel_layout, channels: .channels}')
    _linecount=$(echo "$_audio_streams" | wc -l)
    _result=''
    IFS='
'
    for _audio_stream in $_audio_streams; do
        # Extract field values for a stream
        _id=$(echo "$_audio_stream" | sed 's/.*"ID":\([0-9]*\).*/\1/')
        _profile=$(echo "$_audio_stream" | sed -n 's/.*"profile":"\([^"]*\)".*/\1/p')
        _codec_long_name=$(echo "$_audio_stream" | sed -n 's/.*"codec_long_name":"\([^"]*\)".*/\1/p')
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
        # Concatenate the stream info parts into the field
        test "$_linecount" -gt 1 && _result="${_result}stream_${_id}: "
        _result="${_result}${_codec} ${_channel_layout}, "
    done
    # Strip trailing characters and bad spaces
    _result=$(echo "$_result" | sed 's/,\ $//'  | sed 's/\ ,\ /,\ /g' | sed 's/\ $//')
    echo "$_result"
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
