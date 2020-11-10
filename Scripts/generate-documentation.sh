#!/bin/sh

# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

# Generates the documentation for the project.
# Usage: generate-documentation.sh <os-name>
# Note: it must be run from Xcode.

OS_NAME=$1
PRODUCTS_DIR="${SRCROOT}/../AppCenter-SDK-Apple/${OS_NAME}"
INSTALL_DIR="${PRODUCTS_DIR}/${PROJECT_NAME}.framework"
DOCUMENTATION_DIR="${PRODUCTS_DIR}/Documentation/${PROJECT_NAME}"

# Check if jazzy installed.
if [ ! -x "$(command -v jazzy)" ]; then
  echo "Couldn't find jazzy. Install jazzy before building frameworks"
  exit 1
fi

jazzy --config "${SRCROOT}/../Documentation/${OS_NAME}/${PROJECT_NAME}/.jazzy.yaml"

# Create Documentation directory within folder.
if [ ! -d "${DOCUMENTATION_DIR}" ]; then
  mkdir -p "${DOCUMENTATION_DIR}"
fi

# Copy generated documentation into the documentation folder.
cp -R "${SRCROOT}/../Documentation/${OS_NAME}/${PROJECT_NAME}/Generated/" "${DOCUMENTATION_DIR}"
