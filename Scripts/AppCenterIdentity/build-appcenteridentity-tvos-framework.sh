#!/bin/sh

source $(dirname "$0")/../build-tvos-framework.sh AppCenterIdentity

rm -r "${WRK_DIR}"
