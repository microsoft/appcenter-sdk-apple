#!/bin/sh

source $(dirname "$0")/../build-macos-framework.sh AppCenterIdentity

rm -r "${WRK_DIR}"
