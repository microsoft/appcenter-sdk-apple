#!/bin/bash

file=$2
if [ -e "$file" ]; then
    rm "$file"
fi
lsof -n -i4TCP:$1 | grep LISTEN > "$file"
