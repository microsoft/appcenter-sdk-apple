#!/bin/sh

# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

source $(dirname "$0")/../build-macos-framework.sh

if [ -z $(otool -L "${PRODUCTS_DIR}/${PROJECT_NAME}.framework/${PROJECT_NAME}" | grep 'libCrashReporter') ]; then
  libtool -static -o "${PRODUCTS_DIR}/${PROJECT_NAME}.framework/${PROJECT_NAME}" "${PRODUCTS_DIR}/${PROJECT_NAME}.framework/${PROJECT_NAME}" "${SRCROOT}/../Vendor/macOS/PLCrashReporter/libCrashReporter-MacOSX-Static.a"
fi

rm -r "${WORK_DIR}"
