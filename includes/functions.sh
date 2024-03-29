#!/bin/sh

# Display the help text.
show_help() {
    echo 'archive_list'
    echo 'Generate a CSV file of video media within a directory'
    echo
    echo 'Usage: "./archive_list.sh [-Options...] DirName1"'
    echo
    echo 'Options:'
    echo '--help, -h, -?'
    echo '      Display this help and exit'
    echo '--scanner, -s'
    echo '      [ffrpobe,mediainfo] set media scanner program'
    echo '--type, -t'
    echo '      [tv,movie] set the archive type'
    echo
    echo 'Examples:'
    echo '      ./archive_list --scanner=mediaiinfo --type=tv' /dir/movies/'
    echo '      ./archive_list -s ffprobe -t movie' /dir/movies/'
}

# Extract the directory from a filepath
# @param $1 _filepath Absolute filepath
# @returns string|empty
get_directory() {
    _filepath="$1"
    echo "$_filepath" | sed -n 's/^.*\/\([^\/]*\)\/.*$/\1/p'
}

# Extract the parent directory from a filepath
# @param $1 _filepath Absolute filepath
# @returns string|empty
get_parent_directory() {
    _filepath="$1"
    echo "$_filepath" | sed -n 's/^.*\/\([^\/]*\)\/[^\/]*\/.*$/\1/p'
}

# Extract the grandparent directory from a filepath
# @param $1 _filepath Absolute filepath
# @returns string|empty
get_grandparent_directory() {
    _filepath="$1"
    echo "$_filepath" | sed -n 's/^.*\/\([^\/]*\)\/[^\/]*\/[^\/]*\/.*$/\1/p'
}

# Add a leading zero if a string is only one char
# @param $1 _string
# @returns string
add_leading_zero() {
    _string="$1"
    [ ${#_string} -eq 1 ] && _string="0${_string}"
    echo "$_string"
}

# Trim the extension from a filename.
# @param $1 _spaced_filename Filename with '.' replaced by ' '
# @returns string
trim_extension() {
    _spaced_filename="$1"
    echo "$_spaced_filename" | sed -n 's/^\(.*\) [0-9a-z][0-9a-z]*$/\1/Ip'
}

# Extract the season from a directory name
# @param $1 _directory Directory name.
# @returns string
get_season_from_dir() {
    _directory="$1"
    _season=$(echo "$_directory" | sed -n 's/^season \([0-9][0-9]*\)$/\1/Ip')
    _season=$(add_leading_zero "$_season")
    [ "$_season" = '00' ] && _season='extra'
    echo "$_season"
}

# Extract the season from a filename
# @param $1 _spaced_filename Filename with '.' replaced by ' '
# @returns string|empty
get_season_from_filename() {
    _spaced_filename="$1"
    _season=$(echo "$_spaced_filename" | sed -n 's/^.* s\([0-9][0-9]*\)e[0-9][0-9]* .*$/\1/Ip')
    _season=$(add_leading_zero "$_season")
    echo "$_season"
}

# Extract the extras special (Jellyfin)
# @param $1 _spaced_filename Filename with '.' replaced by ' '
# @returns string|empty
get_extra_special() {
    _spaced_filename="$1"
    _spaced_filename=$(trim_extension "$_spaced_filename")
    echo "$_spaced_filename" | grep -io '^sample$\|^trailer$\|^theme$'
}

# Extract the extras suffix from a filename (jellyfin/plex)
# @param $1 _spaced_filename Filename with '.' replaced by ' '
# @returns string|empty
get_extra_suffix() {
    _spaced_filename="$1"
    _spaced_filename=$(trim_extension "$_spaced_filename")
    echo "$_spaced_filename" | sed -n 's/^.*[-_\ ]\(trailer\|sample\|scene\|clip\|interview\|behindthescenes\|deleted\|deletedscene\|featurette\|short\|other\|extra\)$/\1/Ip'
}

# Detect if a directory is an extras directory (jellyfin/plex)
# @param $1 _dir_name Directory name
# @returns string|empty
get_extra_dir() {
    _dir_name="$1"
    _extra_dir=$(echo "$_dir_name" | grep -io '^behind the scenes$\|^deleted scenes$\|^interviews$\|^scenes$\|^samples$\|^shorts$\|^featurettes$\|^clips$\|^other$\|^extras$\|^trailers$\|^specials\|^season 00$')
    [ "$_extra_dir" = 'Season 00' ] && _extra_dir='extra'
    echo "$_extra_dir"
}

# Get a file extra type
# @param $1 _spaced_filename Filename with '.' replaced by ' '
# @param $2 _filepath
# @returns string|empty
get_extra_all() {
    _spaced_filename="$1"
    _filepath="$2"
    _extra=$(get_extra_special "$_spaced_filename")
    [ -z "$_extra" ] && _extra=$(get_extra_suffix "$_spaced_filename")
    if [ -z "$_extra" ]; then
        _dir=$(get_directory "$_filepath")
        _extra=$(get_extra_dir "$_dir")
    fi
    echo "$_extra"
}

# Get a season extra fromn a filepath
# @param $1 _spaced_filename Filename with '.' replaced by ' '
# @param $2 _filepath
# @returns string|empty
get_extra_season() {
    _spaced_filename="$1"
    _filepath="$2"
    _extra=$(get_extra_special "$_spaced_filename")
    [ -z "$_extra" ] && _extra=$(get_extra_suffix "$_spaced_filename")
    if [ -z "$_extra" ]; then
        _dir=$(get_directory "$_filepath")
        _extra=$(get_extra_dir "$_dir")
        if [ -n "$_extra" ]; then
            _dir=$(get_parent_directory "$_filepath")
            _season=$(get_season_from_dir "$_dir")
            [ -z "$_season" ] && _extra=''
        fi
    fi
    echo "$_extra"
}

# Extract a movie title from a string
# @param $1 _string Spaced filename or directory name
# @returns string
get_title() {
    _string="$1"
    # Title with date in brackets
    _title=$(echo "$_string" | sed -n 's/^\(.*\) ([0-9][0-9][0-9][0-9]).*/\1/p')
    # Title with date
    [ -z "$_title" ] && _title=$(echo "$_string" | sed -n 's/^\(.*\) [0-9][0-9][0-9][0-9] .*/\1/p')
    # Fallback - filename minus the extension
    [ -z "$_title" ] && _title=$(trim_extension "$_string")
    echo "$_title"
}

# Extract a movie year from a string
# @param $1 _string Spaced filename or directory name
# @returns string
get_year() {
    # Add space at end for strings that end in date (i.e. directories)
    _string="$1 "
    # Year with brackets
    _year=$(echo "$_string" |  sed -n 's/^.* (\([0-9][0-9][0-9][0-9]\)) .*$/\1/p')
    # Year without brackets
    [ -z "$_year" ] && _year=$(echo "$_string" | sed -n 's/^.* \([0-9][0-9][0-9][0-9]\) .*$/\1/p')
    echo "$_year"
}

# Extract a TV series name from a filename or filepath
# @param $1 _extra_season Extras type at the season level
# @param $2 _extra_series Extras type at the series level
# @param $1 _spaced_filename Filename with '.' replaced by ' '
# @param $3 _filepath Full filepath
# @returns string
get_series() {
    _extra_season="$1"
    _extra_series="$2"
    _spaced_filename="$3"
    _filepath="$4"
    _series=''
    if [ -z "$_extra_season" ] && [ -z "$_extra_series" ]; then
        _series=$(echo "$_spaced_filename" | grep -ioP '.*?(?= s\d{2}e\d{2} )')
    else
        _dir=$(get_directory "$_filepath")
        _dir_season=$(get_season_from_dir "$_dir")
        _parent_dir=$(get_parent_directory "$_filepath")
        _parent_dir_season=$(get_season_from_dir "$_parent_dir")
        _grandparent_dir=$(get_grandparent_directory "$_filepath")
        _grandparent_dir_season=$(get_season_from_dir "$_grandparent_dir")
        if [ -n "$_parent_dir_season" ]; then
            _series="$_grandparent_dir"
        elif [ -n "$_dir_season" ];then
            _series="$_parent_dir"
        fi
    fi
    echo "$_series"
}

# Extract the season from a filename or filepath
# @param $1 _extra_series Extras type at the series level
# @param $2 _spaced_filename Filename with '.' replaced by ' '
# @param $3 _filepath Full filepath
# @returns string
get_season() {
    _extra_series="$1"
    _spaced_filename="$2"
    _filepath="$3"
    _season=''
    if [ -n "$_extra_series" ]; then
        _season="$_extra_series"
    else
        _season=$(echo "$_spaced_filename" | sed -n 's/^.*s\([0-9][0-9]*\)e[0-9][0-9]*.*$/\1/Ip')
        if [ -z "$_season" ]; then
            _dir=$(get_directory "$_filepath")
            _season=$(get_season_from_dir "$_dir")
        fi
        if [ -z "$_season" ]; then
            _dir=$(get_parent_directory "$_filepath")
            _season=$(get_season_from_dir "$_dir")
        fi
        if [ -z "$_season" ]; then
            _dir=$(get_grandparent_directory "$_filepath")
            _season=$(get_season_from_dir "$_dir")
        fi
    fi
    _season=$(add_leading_zero "$_season")
    echo "$_season"
}

# Extract the episode from a filename
# @param $1 _extra_season Extras type at the season level
# @param $2 _extra_series Extras type at the series level
# @param $3 _spaced_filename Filename with '.' replaced by ' '
# @returns string
get_episode() {
    _extra_season="$1"
    _extra_series="$2"
    _spaced_filename="$3"
    _spaced_filename=$(trim_extension "$_spaced_filename")
    _episode=''
    if [ -n "$_extra_season" ]; then
        _episode="$_extra_season - $_spaced_filename"
    elif [ -n "$_extra_series" ]; then
        _episode=$(echo "$_spaced_filename" | sed -n 's/^.* s[0-9]\{2\}e[0-9]\{2\} \(.*\)$/\1/Ip')
        [ -z "$_episode" ] && _episode="$_spaced_filename"
    else
        _episode=$(echo "$_spaced_filename" | sed -r 's/^.*s[0-9]{2}e([0-9]{2}).*$/\1/I')
    fi
    echo "$_episode"
}
