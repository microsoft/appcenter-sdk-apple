#!/bin/bash

services=$(networksetup -listnetworkserviceorder | grep 'Hardware Port')
file=$1
if [ -e "$file" ]; then
    rm "$file"
fi

while read line; do
    sname=$(echo $line | awk -F  "(, )|(: )|[)]" '{print $2}')
    sdev=$(echo $line | awk -F  "(, )|(: )|[)]" '{print $4}')
    #echo "Current service: $sname, $sdev, $currentservice"
    if [ -n "$sdev" ]; then
        ifconfig $sdev 2>/dev/null | grep 'status: active' > /dev/null 2>&1
        rc="$?"
        if [ "$rc" -eq 0 ]; then
            currentservice="$sname"
            break
        fi
    fi
done <<< "$(echo "$services")"

if [ -n "$currentservice" ]; then
    echo "$currentservice" > "$file"
else
    >&2 echo "Could not find current service"
    exit 1
fi
