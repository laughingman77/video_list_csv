#!/bin/sh

# Manual testing: Find all script files and shellcheck them
# @see https://github.com/koalaman/shellcheck/issues/143
for f in $({ find . -type f -regex '.*\.\w*sh'
    file ./* | grep 'shell script' | cut -d: -f1
    } | sort -u); do
  shellcheck "$f"
done
