#!/bin/bash

# Function to convert Western Arabic numerals to Arabic numerals
convert_to_arabic() {
    echo "$1" | sed 's/0/٠/g; s/1/١/g; s/2/٢/g; s/3/٣/g; s/4/٤/g; s/5/٥/g; s/6/٦/g; s/7/٧/g; s/8/٨/g; s/9/٩/g'
}

# Function to convert Arabic numerals to Western Arabic numerals
convert_to_western() {
    echo "$1" | sed 's/٠/0/g; s/١/1/g; s/٢/2/g; s/٣/3/g; s/٤/4/g; s/٥/5/g; s/٦/6/g; s/٧/7/g; s/٨/8/g; s/٩/9/g'
}

# Check if input is provided
if [ -z "$1" ]; then
    echo "Usage: numeral <numerals>"
    exit 1
fi

# Detect the numeral type by checking the Unicode value of the first character
first_char=${1:0:1}
first_char_code=$(printf '%d' "'$first_char")

if (( first_char_code >= 48 && first_char_code <= 57 )); then
    # If the first character is Western Arabic (Unicode 48-57), convert to Arabic
    convert_to_arabic "$1"
elif (( first_char_code >= 1632 && first_char_code <= 1641 )); then
    # If the first character is Arabic (Unicode 1632-1641), convert to Western Arabic
    convert_to_western "$1"
else
    echo "Error: Unrecognized numeral format."
    exit 1
fi
