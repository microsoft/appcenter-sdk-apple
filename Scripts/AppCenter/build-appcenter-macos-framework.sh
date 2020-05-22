#!/bin/sh

# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

source $(dirname "$0")/../build-macos-framework.sh

rm -r "${WORK_DIR}"

# Copy license and readme
cp -f "${SRCROOT}/../LICENSE" "${BUILD_DIR}"
cp -f "${SRCROOT}/../README.md" "${BUILD_DIR}"
cp -f "${SRCROOT}/../CHANGELOG.md" "${BUILD_DIR}"
