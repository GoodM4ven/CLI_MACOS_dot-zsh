#!/bin/bash

normalize_url() {
    local url="$1"
    # Remove 'http://' or 'https://'
    url="${url#http://}"
    url="${url#https://}"
    # Remove 'www.' if it exists
    url="${url#www.}"
    # Remove trailing '/' only if there's nothing after it
    url="${url%/}"

    echo "$url"
}

# If called with an argument, normalize it, otherwise read from stdin (for piping)
if [[ -n "$1" ]]; then
    normalize_url "$1"
else
    while IFS= read -r line; do
        normalize_url "$line"
    done
fi
