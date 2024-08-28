#!/bin/sh

# Return video file metadata using mediainfo in JSON format.
#
# $1 _video_file Path to the video file
#
# @returns JSON string
#
# Example:
#   video_data "/path/to/video.mkv"
video_data() {
    _video_file=$1
    _result=$(mediainfo --Output=JSON "$_video_file")
    echo "$_result"
}

# Return the resolution of each video stream in a video file, using pre-generated JSON metadata.
# @see video_data()
#
# $1 _metadata mediainfo JSON
# $2 _default_stream Display default stream
#
# @returns Resolution string
#
# Example:
#   foobar=$(resolution "$metadata" 0)
resolution() {
    _metadata=$1
    _default_stream=$2
    _video_streams=$(echo "$_metadata" | jq -c '.media .track[] | select(."@type" == "Video") | {ID: .ID, Width: .Width, Default: .Default}')
    _linecount=$(echo "$_video_streams" | wc -l)
    _result=''
    _results=''
    IFS='
'
    for _video_stream in $_video_streams; do
        # Extract field values for a stream
        _id=$(echo "$_video_stream" | sed -n 's/.*"ID":"\([0-9]*\)".*/\1/p')
        _width=$(echo "$_video_stream" | sed -n 's/.*"Width":"\([^"]*\)".*/\1/p')
        _default=$(echo "$_video_stream" | sed -n 's/.*"Default":"\([^"]*\)".*/\1/p')
        # Map width to a resolution
        _resolution='480p'
        test "$_width" -gt 640 && _resolution='720p'
        test "$_width" -gt 720 && _resolution='1080p'
        test "$_width" -gt 1920 && _resolution='2160p'
        test "$_width" -gt 3840 && _resolution='4320p'
        # Concatenate info parts into the field line
        if [ "$_default"  = 'Yes' ] || [ "$_linecount" -eq 1 ]; then
            _result="${_resolution}"
        fi
        _results="${_results}stream_${_id}: ${_resolution}, "
    done
    # Strip trailing characters and bad spaces
    _results=$(echo "$_result" | sed 's/,\ $//')
    
    if { [ "$_default_stream" -eq 1 ] && [ ! "$_result" = '' ]; } || [ "$_linecount" -eq 1 ]; then
        echo "$_result"
    else
        # Strip trailing characters and bad spaces
        _results=$(echo "$_results" | sed 's/,\ $//'  | sed 's/\ ,\ /,\ /g' | sed 's/\ $//')
        echo "$_results"
    fi
}

# Return the colour mode of each video stream in a video file, using pre-generated JSON metadata.
# @see video_data()
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
    _video_streams=$(echo "$_metadata" | jq -c '.media .track[] | select(."@type" == "Video") | {ID: .ID, Format: .Format, transfer_characteristics: .transfer_characteristics, HDR_Format: .HDR_Format, Format_Version: .Format_Version, HDR_Format_Compatibility: .HDR_Format_Compatibility, Default: .Default}')
    _linecount=$(echo "$_video_streams" | wc -l)
    _result=''
    _results=''
    IFS='
'
    for _video_stream in $_video_streams; do
        # Extract field values for a stream
        _id=$(echo "$_video_stream" | sed -n 's/.*"ID":"\([0-9]*\)".*/\1/p')
        _default=$(echo "$_video_stream" | sed -n 's/.*"Default":"\([^"]*\)".*/\1/p')
        _transfer_characteristics=$(echo "$_video_stream" | sed -n 's/.*"transfer_characteristics":"\([^"]*\)".*/\1/p')
        test "$_transfer_characteristics" = 'null' && _transfer_characteristics=''
        _hdr_format=$(echo "$_video_stream" | sed -n 's/.*"HDR_Format":"\([^",]*\)".*/\1/p')
        test "$_hdr_format" = 'null' && _hdr_format=''
        _hdr_format_compatibility=$(echo "$_video_stream" | sed -n 's/.*"HDR_Format_Compatibility":"\([^"]*\)".*/\1/p')
        test "$_hdr_format_compatibility" = 'null' && _hdr_format_compatibility=''
        # Generate stream additional info parts for the field
        _colour_mode=""
        test "$_transfer_characteristics" = 'HLG' && _colour_mode="HLG $_colour_mode"
        ( echo "$_hdr_format_compatibility" | grep -ioq 'hdr10+ ' ) && _colour_mode="HDR10+ $_colour_mode"
        ( echo "$_hdr_format_compatibility" | grep -ioq 'hdr10 ' ) && _colour_mode="HDR10 $_colour_mode"
        ( echo "$_hdr_format" | grep -ioq 'dolby vision') && _colour_mode="DV $_colour_mode"
        # Concatenate the stream info parts into the field
        if [ "$_default"  = 'Yes' ] || [ "$_linecount" -eq 1 ]; then
            _result="${_colour_mode}"
        fi
        if [ -n "$_colour_mode" ]; then 
            _results="${_results}stream_${_id}: ${_colour_mode}, "
        fi
    done
    
    if { [ "$_default_stream" -eq 1 ] && [ ! "$_result" = '' ]; } || [ "$_linecount" -eq 1 ]; then
        # Strip trailing characters and bad spaces
        _result=$(echo "$_result" | sed 's/[\ ,]*$//' | sed 's/\ ,\ /,\ /g')
        echo "$_result"
    else
        # Strip trailing characters and bad spaces
        _results=$(echo "$_results" | sed 's/,\ $//' | sed 's/\ ,\ /,\ /g' | sed 's/\ $//')
        echo "$_results"
    fi
}

# Return the codecs of each video stream in a video file, using pre-generated JSON metadata.
# @see video_data()
#
# $1 _metadata mediainfo JSON
# $2 _default_stream Display default stream
#
# @returns Video codec string
#
# Example:
#   foobar=$(video "$metadata" 1)
video() {
    _metadata=$1
    _default_stream=$2
    _video_streams=$(echo "$_metadata" | jq -c '.media .track[] | select(."@type" == "Video") | {ID: .ID, Format: .Format, transfer_characteristics: .transfer_characteristics, HDR_Format: .HDR_Format, Format_Version: .Format_Version, HDR_Format_Compatibility: .HDR_Format_Compatibility, Default: .Default}')
    _linecount=$(echo "$_video_streams" | wc -l)
    _result=''
    _results=''
    IFS='
'
    for _video_stream in $_video_streams; do
        # Extract field values for a stream
        _id=$(echo "$_video_stream" | sed -n 's/.*"ID":"\([0-9]*\)".*/\1/p')
        _codec=$(echo "$_video_stream" | sed -n 's/.*"Format":"\([^"]*\)".*/\1/p')
        _format_version=$(echo "$_video_stream" | sed -n 's/.*"Format_Version":"\([^"]*\)".*/\1/p')
        _default=$(echo "$_video_stream" | sed -n 's/.*"Default":"\([^"]*\)".*/\1/p')
        test "${_codec#*"MPEG-2"}" != "$_codec" && _codec='MPEG-2'
        test "${_codec#*"MPEG-4"}" != "$_codec" && _codec='MPEG-4'
        if [ "${_codec#*"MPEG Video"}" != "$_codec" ]; then
            _codec="MPEG-$_format_version"
        fi
        # @TODO 3D
        # Concatenate the stream info parts into the field
        if [ "$_default"  = 'Yes' ] || [ "$_linecount" -eq 1 ]; then
            _result="${_codec}"
        fi
        _results="${_results}stream_${_id}: ${_codec}, "
    done
    
    if { [ "$_default_stream" -eq 1 ] && [ ! "$_result" = '' ]; } || [ "$_linecount" -eq 1 ]; then
    # Strip trailing characters and bad spaces
        _result=$(echo "$_result" | sed 's/[\ ,]*$//' | sed 's/\ ,\ /,\ /g')
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
    _audio_streams=$(echo "$_metadata" | jq -c '.media .track[] | select(."@type" == "Audio") | {ID: .ID, Format: .Format, Format_Profile: .Format_Profile, Format_Commercial_IfAny: .Format_Commercial_IfAny, Channels: .Channels, Language: .Language, Default: .Default}')
    _linecount=$(echo "$_audio_streams" | wc -l)
    _result=''
    IFS='
'
    for _audio_stream in $_audio_streams; do
        # Extract field values for a stream
        _id=$(echo "$_audio_stream" | sed -n 's/.*"ID":"\([0-9]*\)".*/\1/p')
        _channels=$(echo "$_audio_stream" | sed -n 's/.*"Channels":"\([0-9]*\)".*/\1/p')
        _language=$(echo "$_audio_stream" | sed -n 's/.*"Language":"\([^"]*\)".*/\1/p')
        _default=$(echo "$_audio_stream" | sed -n 's/.*"Default":"\([^"]*\)".*/\1/p')
        # Tidy Text for channels
        test "$_channels" = '1' && _channels='1.0'
        test "$_channels" = '2' && _channels='2.0'
        test "$_channels" = '4' && _channels='3.1'
        test "$_channels" = '5' && _channels='4.1'
        test "$_channels" = '6' && _channels='5.1'
        test "$_channels" = '7' && _channels='6.1'
        test "$_channels" = '8' && _channels='7.1'
        _format_profile=$(echo "$_audio_stream" | sed -n 's/.*"Format_Profile":"\([^"]*\)".*/\1/p')
        _format=$(echo "$_audio_stream" | sed -n 's/.*"Format":"\([^"]*\)".*/\1/p')
        if [ "${_format#*"MPEG Audio"}" != "$_format" ]; then
            _format='MP'$(echo "$_format_profile" | sed -n 's/Layer \([0-9]*\)/\1/p')
        fi
        _format_commercial_ifany=$(echo "$_audio_stream" | sed -n 's/.*"Format_Commercial_IfAny":"\([^"]*\)".*/\1/p')
        test "${_format_commercial_ifany#*"Dolby Digital Plus"}" != "$_format_commercial_ifany" && _format_commercial_ifany='DD+'
        test "${_format_commercial_ifany#*"Dolby Digital"}" != "$_format_commercial_ifany" && _format_commercial_ifany='DD'
        test "${_format_commercial_ifany#*"DTS-HD High Resolution Audio"}" != "$_format_commercial_ifany" && _format_commercial_ifany='DTS-HD'
        test "${_format_commercial_ifany#*"DTS-HD Master Audio"}" != "$_format_commercial_ifany" && _format_commercial_ifany='DTS-HD MA'
        test "${_format_commercial_ifany#*"Atmos"}" != "$_format_commercial_ifany" && _format_commercial_ifany='Atmos'
        test "${_format_commercial_ifany#*"TrueHD"}" != "$_format_commercial_ifany" && _format_commercial_ifany='TrueHD'
        test -n "$_format_commercial_ifany" && _format="$_format_commercial_ifany"

        test ! "$_language" = '' && _language=" (${_language})"

        # Concatenate the stream info parts into the field
        if [ "$_default"  = 'Yes' ] || [ "$_linecount" -eq 1 ]; then
            _result="${_format} ${_channels}${_language}"
        fi
        _results="${_results}stream_${_id}: ${_format} ${_channels}${_language}, "
            
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
# $1 _metadata mediainfo JSON
#
# @returns string of comma separtated subtitle languageas
#
# Example:
#   foobar=$(subtitle "$metadata")
subtitle() {
    _metadata=$1
    _result=$(echo "$_metadata" | jq -c '[.media .track[] | select(."@type" == "Text") .Language] | unique' | sed 's/,/,\ /g' | sed 's/[]["]//g')
    echo "$_result"
}
