#!/bin/sh

source $(dirname "$0")/../build-macos-framework.sh AppCenterAuth

rm -r "${WRK_DIR}"
