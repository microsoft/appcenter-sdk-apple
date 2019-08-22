#!/bin/sh

# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

source $(dirname "$0")/../build-ios-framework.sh

# Add PLCrashReporter.
if [ -z $(otool -L "${PRODUCTS_DIR}/${PROJECT_NAME}.framework/${PROJECT_NAME}" | grep 'libCrashReporter') ]; then
  if [ -z "$MS_ARM64E_XCODE_PATH" ] || [ ! -d "$MS_ARM64E_XCODE_PATH" ]; then
    echo "Use legacy Xcode and link PLCR via libtool."
    libtool -static  "${PRODUCTS_DIR}/${PROJECT_NAME}.framework/${PROJECT_NAME}" "${SRCROOT}/../Vendor/iOS/PLCrashReporter/CrashReporter.framework/Versions/A/CrashReporter" -o "${PRODUCTS_DIR}/${PROJECT_NAME}.framework/${PROJECT_NAME}"
  else
    echo "Use arm64e Xcode and link PLCR via libtool."
    env DEVELOPER_DIR="$MS_ARM64E_XCODE_PATH" /usr/bin/libtool -static "${PRODUCTS_DIR}/${PROJECT_NAME}.framework/${PROJECT_NAME}" "${SRCROOT}/../Vendor/iOS/PLCrashReporter/CrashReporter.framework/Versions/A/CrashReporter" -o "${PRODUCTS_DIR}/${PROJECT_NAME}.framework/${PROJECT_NAME}"
  fi
fi

rm -r "${WORK_DIR}"
