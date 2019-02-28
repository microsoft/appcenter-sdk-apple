#!/bin/sh

source $(dirname "$0")/../build-ios-framework.sh AppCenterIdentity

rm -r "${WRK_DIR}"
