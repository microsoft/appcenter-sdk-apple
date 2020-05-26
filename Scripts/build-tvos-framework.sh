#!/bin/sh

# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.
set -e

# Sets the target folders and the final framework product.
TARGET_NAME="${PROJECT_NAME} tvOS Framework"

# The directory for final output of the framework.
PRODUCTS_DIR="${SRCROOT}/../AppCenter-SDK-Apple/tvOS"

# Build result paths.
OUTPUT_DEVICE_DIR="${BUILD_DIR}/${CONFIGURATION}-appletvos/"
OUTPUT_SIMULATOR_DIR="${BUILD_DIR}/${CONFIGURATION}-appletvsimulator/"

# Building both architectures.
build() {
    # Print only target name and issues. Mimic Xcode output to make prettify tools happy.
    echo "=== BUILD TARGET $1 OF PROJECT ${PROJECT_NAME} WITH CONFIGURATION ${CONFIGURATION} ==="
    # OBJROOT must be customized to avoid conflicts with the current process.
    xcodebuild -quiet \
        SYMROOT="${SYMROOT}" OBJROOT="${OBJECT_FILE_DIR}" PROJECT_TEMP_DIR="${PROJECT_TEMP_DIR}" ONLY_ACTIVE_ARCH=NO \
        -project "${SRCROOT}/${PROJECT_NAME}.xcodeproj" -configuration "${CONFIGURATION}" -target "$1" -sdk "$2"
}
build "${TARGET_NAME}" appletvos
build "${TARGET_NAME}" appletvsimulator

# Cleaning the previous build.
if [ -d "${PRODUCTS_DIR}/${PROJECT_NAME}.framework" ]; then
  rm -rf "${PRODUCTS_DIR}/${PROJECT_NAME}.framework"
fi

# Creates the final product folder.
mkdir -p "${PRODUCTS_DIR}"

# Copy framework.
cp -R "${OUTPUT_DEVICE_DIR}/${PROJECT_NAME}.framework" "${PRODUCTS_DIR}"

# Uses the Lipo Tool to merge both binary files (i386/x86_64 + arm64) into one Universal final product.
lipo -create \
  "${OUTPUT_DEVICE_DIR}/${PROJECT_NAME}.framework/${PROJECT_NAME}" \
  "${OUTPUT_SIMULATOR_DIR}/${PROJECT_NAME}.framework/${PROJECT_NAME}" \
  -output "${PRODUCTS_DIR}/${PROJECT_NAME}.framework/${PROJECT_NAME}"
