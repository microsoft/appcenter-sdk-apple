#!/bin/sh

# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.
set -e

# The directory for final output of the framework.
PRODUCTS_DIR="${SRCROOT}/../AppCenter-SDK-Apple/macOS"

# Cleaning the previous builds.
if [ -d "${PRODUCTS_DIR}/${PROJECT_NAME}.framework" ]; then
  rm -rf "${PRODUCTS_DIR}/${PROJECT_NAME}.framework"
fi

# Creates the final product folder.
mkdir -p "${PRODUCTS_DIR}"

# Copy framework.
cp -R "${BUILD_DIR}/${CONFIGURATION}/${PROJECT_NAME}.framework" "${PRODUCTS_DIR}"
