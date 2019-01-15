#!/bin/sh

source $(dirname "$0")/../build-macos-framework.sh AppCenterCrashes

if [ -z $(otool -L "${INSTALL_DIR}/${FMK_NAME}" | grep 'libCrashReporter') ]
then
libtool -static -o "${INSTALL_DIR}/${FMK_NAME}" "${INSTALL_DIR}/${FMK_NAME}" "${SRCROOT}/../Vendor/macOS/PLCrashReporter/libCrashReporter-MacOSX-Static.a"
fi

rm -r "${WRK_DIR}"
