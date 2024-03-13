#!/bin/sh

# Find all script files and shellcheck them
# @see https://github.com/koalaman/shellcheck/issues/143
for f in $({ find . -type f -regex ".*\.\w*sh"
    file ./* | grep '#!\(/usr/bin/env \|/bin/\)sh' | cut -d: -f1
    } | sort -u); do
  shellcheck "$f"
done
