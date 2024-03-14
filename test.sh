#!/bin/sh

EXITCODE=0
find . -type f -name "*.sh" | (while read -r file; do
    printf "Checking %s\n" "$file"
    if ERRORS=$(shellcheck --format=gcc "$file"); then
        printf "\e[32m%s\e[0m\n" "OK"
    else
        printf "\e[31m%s\e[0m\n" "$ERRORS"
        EXITCODE=1
    fi
done

exit $EXITCODE)