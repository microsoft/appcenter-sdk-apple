#!/bin/sh

# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.
set -e

# Sets the target folders and the final framework product.
TARGET_NAME="${PROJECT_NAME} tvOS Framework"

# The directory for final output of the framework.
PRODUCTS_DIR="${SRCROOT}/../AppCenter-SDK-Apple/tvOS"

# Build result paths.
SCRIPT_BUILD_DIR="${SRCROOT}/build"
DEVICE_SDK="appletvos"
SIMULATOR_SDK="appletvsimulator"
OUTPUT_DEVICE_DIR="${SCRIPT_BUILD_DIR}/${CONFIGURATION}-${DEVICE_SDK}"
OUTPUT_SIMULATOR_DIR="${SCRIPT_BUILD_DIR}/${CONFIGURATION}-${SIMULATOR_SDK}"

# Building both architectures.
build() {
  # Print only target name and issues. Mimic Xcode output to make prettify tools happy.
  echo "=== BUILD TARGET $1 OF PROJECT ${PROJECT_NAME} WITH CONFIGURATION ${CONFIGURATION} ==="

  # Clean building result folder.
  rm -rf "${SCRIPT_BUILD_DIR}/${CONFIGURATION}-$2"

  # OBJROOT must be customized to avoid conflicts with the current process.
  xcodebuild OBJROOT="${CONFIGURATION_TEMP_DIR}" PROJECT_TEMP_DIR="${PROJECT_TEMP_DIR}" ONLY_ACTIVE_ARCH=NO \
    -project "${SRCROOT}/${PROJECT_NAME}.xcodeproj" -configuration "${CONFIGURATION}" -target "$1" -sdk "$2"
}
build "${TARGET_NAME}" "${DEVICE_SDK}"
build "${TARGET_NAME}" "${SIMULATOR_SDK}"

# Clean the previous build and copy the framework.
rm -rf "${PRODUCTS_DIR}/${PROJECT_NAME}.framework"
mkdir -p "${PRODUCTS_DIR}"
cp -RHv "${OUTPUT_DEVICE_DIR}/${PROJECT_NAME}.framework" "${PRODUCTS_DIR}"

# Uses the Lipo Tool to combine both binary files (i386/x86_64 + arm64) into one universal final product.
echo "Combine binary files into universal final product"
lipo -create \
  "${OUTPUT_DEVICE_DIR}/${PROJECT_NAME}.framework/${PROJECT_NAME}" \
  "${OUTPUT_SIMULATOR_DIR}/${PROJECT_NAME}.framework/${PROJECT_NAME}" \
  -output "${PRODUCTS_DIR}/${PROJECT_NAME}.framework/${PROJECT_NAME}"
lipo -info "${PRODUCTS_DIR}/${PROJECT_NAME}.framework/${PROJECT_NAME}"
