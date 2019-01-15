#!/bin/sh

source $(dirname "$0")/../build-tvos-framework.sh AppCenterCrashes

if [ -z $(otool -L "${INSTALL_DIR}/${FMK_NAME}" | grep 'libCrashReporter') ]
then
libtool -static -o "${INSTALL_DIR}/${FMK_NAME}" "${INSTALL_DIR}/${FMK_NAME}" "${SRCROOT}/../Vendor/tvOS/PLCrashReporter/CrashReporter.framework/Versions/A/CrashReporter"
fi

rm -r "${WRK_DIR}"
