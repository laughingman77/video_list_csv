#!/bin/sh

EXITCODE=0

if ! test -f ./.env; then
  echo ".env does not exist, generating the default .env..."
  cp example.env .env
fi

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