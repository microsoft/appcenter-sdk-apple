#!/bin/sh

source $(dirname "$0")/../build-ios-framework.sh AppCenterDataStorage

rm -r "${WRK_DIR}"
