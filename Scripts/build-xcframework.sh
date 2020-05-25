#!/bin/sh

# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

# The directory where all XCFramework artifacts is stored.
PRODUCTS_DIR="${SRCROOT}/../AppCenter-SDK-Apple/XCFramework"

# Cleaning the previous builds.
if [ -d "${PRODUCTS_DIR}/${PROJECT_NAME}.xcframework" ]; then
  rm -rf "${PRODUCTS_DIR}/${PROJECT_NAME}.xcframework"
fi

# Create a command to build XCFramework.
for SDK in iphoneos iphonesimulator appletvos appletvsimulator macOS maccatalyst; do
  FRAMEWORK_PATH="${BUILD_DIR}/${CONFIGURATION}-${SDK}/${PRODUCT_NAME}.framework"
  [ -e "${FRAMEWORK_PATH}" ] && XC_FRAMEWORKS+=( -framework "${FRAMEWORK_PATH}")
done

# Build XCFramework.
xcodebuild -create-xcframework "${XC_FRAMEWORKS[@]}" -output "${PRODUCTS_DIR}/${PROJECT_NAME}.xcframework"

# Copy license and readme.
cp -f "${SRCROOT}/../LICENSE" "${PRODUCTS_DIR}"
cp -f "${SRCROOT}/../README.md" "${PRODUCTS_DIR}"
cp -f "${SRCROOT}/../CHANGELOG.md" "${PRODUCTS_DIR}"

