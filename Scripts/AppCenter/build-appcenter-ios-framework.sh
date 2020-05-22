#!/bin/sh

# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

source $(dirname "$0")/../build-ios-framework.sh

rm -r "${WORK_DIR}"

# Copy license and readme.
cp -f "${SRCROOT}/../LICENSE" "${PRODUCTS_DIR}"
cp -f "${SRCROOT}/../README.md" "${PRODUCTS_DIR}"
cp -f "${SRCROOT}/../CHANGELOG.md" "${PRODUCTS_DIR}"
