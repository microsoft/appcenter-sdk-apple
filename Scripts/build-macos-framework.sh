#!/bin/sh

# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.
set -e

# Sets the target folders and the final framework product.
TARGET_NAME="${PROJECT_NAME} macOS Framework"

echo "Building ${TARGET_NAME}."

# Install dir will be the final output to the framework.
# The following line create it in the root folder of the current project.
WORK_DIR=build
BUILD_DIR="${SRCROOT}/../AppCenter-SDK-Apple/macOS"
OUTPUT_DEVICE_DIR="${SRCROOT}/../AppCenter-SDK-Apple/output/${CONFIGURATION}-macOS"

# Working dir will be deleted after the framework creation.

# Make sure we're inside $SRCROOT.
cd "${SRCROOT}"

# Creates and renews the final product folder.
if [ -d "${BUILD_DIR}/${PROJECT_NAME}.framework" ]; then
  rm -rf "${BUILD_DIR}/${PROJECT_NAME}.framework"
fi
if [ -d "${OUTPUT_DEVICE_DIR}/${PROJECT_NAME}.framework" ]; then
  rm -rf "${OUTPUT_DEVICE_DIR}/${PROJECT_NAME}.framework"
fi

# Creates and renews the final product folder.
mkdir -p "${BUILD_DIR}"
mkdir -p "${OUTPUT_DEVICE_DIR}"

# Clean and build both architectures.
xcodebuild -project "${PROJECT_NAME}.xcodeproj" -configuration "${CONFIGURATION}" -target "${TARGET_NAME}" clean
xcodebuild -project "${PROJECT_NAME}.xcodeproj" -configuration "${CONFIGURATION}" -target "${TARGET_NAME}" CONFIGURATION_BUILD_DIR="${OUTPUT_DEVICE_DIR}"

# Copy framework.
cp -R "${OUTPUT_DEVICE_DIR}/${PROJECT_NAME}.framework" "${BUILD_DIR}"
