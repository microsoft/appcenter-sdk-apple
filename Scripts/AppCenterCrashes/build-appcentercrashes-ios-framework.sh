#!/bin/sh

source $(dirname "$0")/../build-ios-framework.sh AppCenterCrashes

# Add PLCrashReporter.
if [ -z $(otool -L "${INSTALL_DIR}/${FMK_NAME}" | grep 'libCrashReporter') ]
then
if [ -z "$MS_ARM64E_XCODE_PATH" ] || [ ! -d "$MS_ARM64E_XCODE_PATH" ] ; then
echo "Use legacy Xcode and link PLCR via libtool."
libtool -static  "${INSTALL_DIR}/${FMK_NAME}" "${SRCROOT}/../Vendor/iOS/PLCrashReporter/CrashReporter.framework/Versions/A/CrashReporter" -o "${INSTALL_DIR}/${FMK_NAME}"
else
echo "Use arm64e Xcode and link PLCR via libtool."
env DEVELOPER_DIR="$MS_ARM64E_XCODE_PATH" /usr/bin/libtool -static  "${INSTALL_DIR}/${FMK_NAME}" "${SRCROOT}/../Vendor/iOS/PLCrashReporter/CrashReporter.framework/Versions/A/CrashReporter" -o "${INSTALL_DIR}/${FMK_NAME}"
fi
fi

rm -r "${WRK_DIR}"
