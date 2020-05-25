#!/bin/sh

# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.
set -e

# Install dir will be the final output to the framework.
# The following line create it in the root folder of the current project.
PRODUCTS_DIR="${SRCROOT}/../AppCenter-SDK-Apple/macOS"

# Creates and renews the final product folder.
if [ -d "${PRODUCTS_DIR}/${PROJECT_NAME}.framework" ]; then
  rm -rf "${PRODUCTS_DIR}/${PROJECT_NAME}.framework"
fi

# Creates and renews the final product folder.
mkdir -p "${PRODUCTS_DIR}"

# Copy framework.
cp -R "${BUILD_DIR}/${CONFIGURATION}/${PROJECT_NAME}.framework" "${PRODUCTS_DIR}"
