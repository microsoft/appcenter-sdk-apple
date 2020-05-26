#!/bin/sh

# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

# The directory for final output of the framework.
PRODUCTS_DIR="${SRCROOT}/../AppCenter-SDK-Apple/XCFramework"

# Cleaning the previous builds.
if [ -d "${PRODUCTS_DIR}/${PROJECT_NAME}.xcframework" ]; then
  rm -rf "${PRODUCTS_DIR}/${PROJECT_NAME}.xcframework"
fi

# Creates the final product folder.
mkdir -p "${PRODUCTS_DIR}"

# Create a command to build XCFramework.
FRAMEWORK_PATH="${BUILD_DIR}/${CONFIGURATION}/${PRODUCT_NAME}.framework"
[ -e "${FRAMEWORK_PATH}" ] && XC_FRAMEWORKS=(-framework "${FRAMEWORK_PATH}")
for SDK in iphoneos iphonesimulator appletvos appletvsimulator maccatalyst; do
  FRAMEWORK_PATH="${BUILD_DIR}/${CONFIGURATION}-${SDK}/${PRODUCT_NAME}.framework"
  [ -e "${FRAMEWORK_PATH}" ] && XC_FRAMEWORKS+=( -framework "${FRAMEWORK_PATH}")
done

# Build XCFramework.
xcodebuild -create-xcframework "${XC_FRAMEWORKS[@]}" -output "${PRODUCTS_DIR}/${PROJECT_NAME}.xcframework"
