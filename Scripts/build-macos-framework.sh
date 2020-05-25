#!/bin/sh

# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.
set -e

# Sets the target folders and the final framework product.
TARGET_NAME="${PROJECT_NAME} macOS Framework"

echo "Building ${TARGET_NAME}."

# Working dir will be deleted after the framework creation.
WORK_DIR=build

# Install dir will be the final output to the framework.
# The following line create it in the root folder of the current project.
PRODUCTS_DIR="${SRCROOT}/../AppCenter-SDK-Apple/macOS"
OUTPUT_DEVICE_DIR="${WORK_DIR}/${CONFIGURATION}"

# Make sure we're inside $SRCROOT.
cd "${SRCROOT}"

# Creates and renews the final product folder.
if [ -d "${PRODUCTS_DIR}/${PROJECT_NAME}.framework" ]; then
  rm -rf "${PRODUCTS_DIR}/${PROJECT_NAME}.framework"
fi

# Creates and renews the final product folder.
mkdir -p "${PRODUCTS_DIR}"

# Build framework.
xcodebuild -project "${PROJECT_NAME}.xcodeproj" -configuration "${CONFIGURATION}" -target "${TARGET_NAME}"

# Copy framework.
cp -R "${OUTPUT_DEVICE_DIR}/${PROJECT_NAME}.framework" "${PRODUCTS_DIR}"