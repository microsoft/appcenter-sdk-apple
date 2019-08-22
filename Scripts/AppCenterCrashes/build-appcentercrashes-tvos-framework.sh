#!/bin/sh

# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

source $(dirname "$0")/../build-tvos-framework.sh

if [ -z $(otool -L "${PRODUCTS_DIR}/${PROJECT_NAME}.framework/${PROJECT_NAME}" | grep 'libCrashReporter') ]; then
 libtool -static -o "${PRODUCTS_DIR}/${PROJECT_NAME}.framework/${PROJECT_NAME}" "${PRODUCTS_DIR}/${PROJECT_NAME}.framework/${PROJECT_NAME}" "${SRCROOT}/../Vendor/tvOS/PLCrashReporter/CrashReporter.framework/Versions/A/CrashReporter"
fi

rm -r "${WORK_DIR}"
