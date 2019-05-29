#!/bin/bash

numberOfArguments="$#"
networksetup -setwebproxy "$1" $2 $3
networksetup -setwebproxystate "$1" $4
networksetup -setsecurewebproxy "$1" $5 $6
networksetup -setsecurewebproxystate "$1" $7

if [ $numberOfArguments == "7" ]; then
    exit 0
else
    networksetup -setftpproxy "$1" $8 $9
    networksetup -setftpproxystate "$1" ${10}
    networksetup -setsocksfirewallproxy "$1" ${11} ${12}
    networksetup -setsocksfirewallproxystate "$1" ${13}
fi