#!/bin/bash

file=$2
if [ -e "$file" ]; then
    rm "$file"
fi

result=$(bash "$3" "$1" > "$file")
echo $1