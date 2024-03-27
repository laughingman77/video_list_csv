#!/bin/sh

# Generate a progress bar
#
# The bar autosizes to the terminal width and crops the length displayed with ellipsis
# An optinal argument can be added to set the width of the progress bar (default: 30)
#
# $1 _done Progress so far (integer)
# $2 _todo Total progress to do (integer)
# $3 _phrase Phrase to append after the progress bar (string - optional)
#
# Example:
# kount=0
# whhile [ "$kount" -lt 10 ]; then
#     kount=$((kount + 1))
#     progressbar --bar-width=50 $kount $10 "Kount - $kount"
# done
progressbar() {
    _Default_Bar_Width=30
    if echo "$1" | grep -q -- '--bar-width='; then
        _bar_width=$(echo "$1" | sed 's/^--bar-width=\(.*\)/\1/')
        _done=$2
        _todo=$3
        [ -z "$4" ] && _phrase='' || _phrase=$4
    else
        _bar_width=$_Default_Bar_Width
        _done=$1
        _todo=$2
        [ -z "$3" ] && _phrase='' || _phrase=$3
    fi
    if [ -z "$_done" ] || [ "$_done" != "${_done#*[!0123456789]}" ] ; then echo "progressbar: _done ($_done) is not an integer."; exit 1; fi
    if [ -z "$_todo" ] || [ "$_todo" != "${_todo#*[!0123456789]}" ] ; then echo "progressbar: _todo ($_todo) is not an integer."; exit 1; fi
    _col_width=$(($(tput cols) - 4))
    _progress_line='DONE!'
    if test "$_done" -lt "$_todo"; then
        # Calculate percentage done
        _percentage_done=$((100 * _done / _todo))
        # Calculate progress as a percentage of the bar width
        _bar_done=$((_percentage_done * _bar_width / 100))
        # Generate the progress bar
        _remaining=$((_bar_width - _bar_done))
        # shellcheck disable=SC2183
        _progress_bar=$(printf '%*s' "$_bar_done" | tr ' ' "#")$(printf '%*s' "$_remaining" | tr ' ' ".")
        # Create the line for the progress bar
        _progress_line="[$_progress_bar] ($_percentage_done%) $_phrase"
    fi
    # Trim the prpgress bar so that the line does not exceed the terminal width
    _progress_line=$(echo "$_progress_line" | sed -E "s/(.{${_col_width}})(.+)$/\1.../" )
    # Pad the line with spaces to terminal width chars
    _progress_line=$_progress_line$(printf -- \ %.s $(seq -s ' ' $((_col_width+3-${#_progress_line}))))"\r\c"
    printf "%b" "$_progress_line"
}
