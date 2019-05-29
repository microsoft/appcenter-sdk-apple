#!/bin/bash

networksetup -getwebproxy "$1"
networksetup -getftpproxy "$1"
networksetup -getsecurewebproxy "$1"
networksetup -getsocksfirewallproxy "$1"