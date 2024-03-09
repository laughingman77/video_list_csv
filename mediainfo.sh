#!/bin/sh

# Return video file data using mediainfo, in JSON format.
#
# $1 _video_file path to the video file
#
# @returns JSON string
#
# Example:
#   video_data "/path/to/video.mkv"
video_data() {
    _video_file=$1
    echo $(mediainfo --Output=JSON "$_video_file")
}

# Return the resolution of a video file, using pre-generated JSON metadata JSON.
# @see video_data()
#
# $1 _metadata mediainfo JSON
#
# @returns resolution string
#
# Example:
#   foobar=$(resolution "$metadata")
resolution() {
    _metadata=$1
    _video_streams=$(echo "$_metadata" | jq -c '.media .track[] | select(."@type" == "Video") | {ID: .ID, Width: .Width}')
    _linecount=$(echo "$_video_streams" | wc -l)
    _result=''
    IFS='
'
    for _video_stream in $_video_streams; do
        # Extract field values for a stream
        _id=$(echo "$_video_stream" | sed 's/.*"ID":"\([0-9]*\)".*/\1/')
        _width=$(echo "$_video_stream" | sed 's/.*"Width":"\([^"]*\)".*/\1/')
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

# Return the video streams codecs and colouration of a video file, using pre-generated JSON metadata JSON.
# @see video_data()
#
# $1 _metadata mediainfo JSON
#
# @returns video codec string
#
# Example:
#   foobar=$(video "$metadata")
video() {
    _metadata=$1
    _video_streams=$(echo "$_metadata" | jq -c '.media .track[] | select(."@type" == "Video") | {ID: .ID, Format: .Format, transfer_characteristics: .transfer_characteristics, HDR_format: .HDR_format, HDR_Format_Compatibility: .HDR_Format_Compatibility}')
    _linecount=$(echo "$_video_streams" | wc -l)
    _result=''
    IFS='
'
    for _video_stream in $_video_streams; do
        # Extract field values for a stream
        _id=$(echo "$_video_stream" | sed 's/.*"ID":"\([0-9]*\)".*/\1/')
        _codec=$(echo "$_video_stream" | sed 's/.*"Format":"\([^"]*\)".*/\1/')
        test "$_codec" = 'MPEG Video' && _codec='MPEG'
        _transfer_characteristics=$(echo "$_video_stream" | sed 's/.*"transfer_characteristics":\([^",]*\),.*/\1/')
        test "$_transfer_characteristics" = 'null' && _transfer_characteristics='' || _transfer_characteristics=$(echo "$_transfer_characteristics" | sed 's/"//g')
        _hdr_format=$(echo "$_video_stream" | sed 's/.*"HDR_format":\([^",]*\),.*/\1/')
        test "$_hdr_format" = 'null' && _hdr_format='' || _hdr_format=$(echo "$_hdr_format" | sed 's/"//g')
        _hdr_format_compatibility=$(echo "$_video_stream" | sed 's/.*"HDR_Format_Compatibility":\([^"}]*\)}.*/\1/')
        test "$_hdr_format_compatibility" = 'null' && _hdr_format_compatibility='' || _hdr_format_compatibility=$(echo "$_hdr_format_compatibility" | sed 's/["}]//g')
        # Generate stream additional info parts for the field
        _additional_info=""
        test "$_transfer_characteristics" = 'HLG' && _additional_info="$_additional_info HLG"
        test "$(echo "$_hdr_format" | grep -iq 'dolby vision')" && _additional_info="$_additional_info DV"
        test "$(echo "$_hdr_format_compatibility" | grep -iq 'hdr10 ')" && _additional_info="$_additional_info HDR10"
        test "$(echo "$_hdr_format_compatibility" | grep -iq 'hdr10\+ ')" && _additional_info="$_additional_info HDR10+"
        # Concatenate the stream info parts into the field
        test "$_linecount" -gt 1 && _result="${_result}stream_${_id}: "
        _result="${_result}${_codec} ${_additional_info}, "
    done
    # Strip trailing characters and bad spaces
    echo $(echo "$_result" | sed 's/,\ $//'  | sed 's/\ ,\ /,\ /g' | sed 's/\ $//')
}

# Return the audio streams codecs of a video file, using pre-generated JSON metadata JSON.
# @see video_data()
#
# $1 _metadata mediainfo JSON
#
# @returns audio codec string
#
# Example:
#   foobar=$(audio "$metadata")
audio() {
    _metadata=$1
    _audio_streams=$(echo "$_metadata" | jq -c '.media .track[] | select(."@type" == "Audio") | {ID: .ID, Format: .Format, Format_Commercial_IfAny: .Format_Commercial_IfAny, Channels: .Channels}')
    # echo "$_audio_streams"; exit 0
    _linecount=$(echo "$_audio_streams" | wc -l)
    _result=''
    IFS='
'
    for _audio_stream in $_audio_streams; do
        # echo "$_audio_stream"; exit 0
        # Extract field values for a stream
        _id=$(echo "$_audio_stream" | sed 's/.*"ID":"\([0-9]*\)".*/\1/')
        _channels=$(echo "$_audio_stream" | sed 's/.*"Channels":"\([0-9]*\)".*/\1/')
        test "$_channels" = '1' && _channels='1.0'
        test "$_channels" = '2' && _channels='2.0'
        test "$_channels" = '4' && _channels='3.1'
        test "$_channels" = '5' && _channels='4.1'
        test "$_channels" = '6' && _channels='5.1'
        test "$_channels" = '7' && _channels='6.1'
        test "$_channels" = '8' && _channels='7.1'
        _format=$(echo "$_audio_stream" | sed -ne 's/.*"Format":"\([^"]*\)".*/\1/p')
        _format_commercial_ifany=$(echo "$_audio_stream" | sed -ne 's/.*"Format_Commercial_IfAny":"\([^"]*\)".*/\1/p')
        test "$_format_commercial_ifany" = 'Dolby Digital' && _format_commercial_ifany='DD'
        test "$_format_commercial_ifany" = 'DTS-HD High Resolution Audio' && _format_commercial_ifany='DTS-HD'
        test "$_format_commercial_ifany" = 'DTS-HD Master Audio' && _format_commercial_ifany='DTS-HD MA'
        test "$_format_commercial_ifany" = 'Dolby TrueHD' && _format_commercial_ifany='TrueHD'
        test "$_format_commercial_ifany" = 'Dolby Digital Plus with Dolby Atmos' && _format_commercial_ifany='Atmos'
        test -n "$_format_commercial_ifany" && _format="$_format_commercial_ifany"
        # Concatenate the stream info parts into the field
        test "$_linecount" -gt 1 && _result="${_result}stream_${_id}: "
        _result="${_result}${_format} ${_channels}, "
    done
    # Strip trailing characters and bad spaces
    echo $(echo "$_result" | sed 's/,\ $//'  | sed 's/\ ,\ /,\ /g' | sed 's/\ $//')
}