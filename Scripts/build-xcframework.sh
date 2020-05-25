#!/bin/sh

# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

# Work dir is directory where all XCFramework artifacts is stored.
PRODUCTS_DIR="${SRCROOT}/../AppCenter-SDK-Apple/${ROOT_DIR}/XCFramework"

# Cleaning the previous builds.
if [ -d "${PRODUCTS_DIR}/${PROJECT_NAME}.xcframework" ]; then
  rm -rf "${PRODUCTS_DIR}/${PROJECT_NAME}.xcframework"
fi

# Build and move mac catalyst framework
MACCATALYST_BUILD_DIR="${BUILD_DIR}/${CONFIGURATION}-maccatalyst"
if [ -d "${MACCATALYST_BUILD_DIR}/${PROJECT_NAME}.framework" ]; then
  rm -rf "${MACCATALYST_BUILD_DIR}/${PROJECT_NAME}.framework"
fi
xcodebuild \
  SYMROOT="${SYMROOT}" OBJROOT="${BUILT_PRODUCTS_DIR}" PROJECT_TEMP_DIR="${PROJECT_TEMP_DIR}" ONLY_ACTIVE_ARCH=NO \
  -project "${SRCROOT}/${PROJECT_NAME}.xcodeproj" -configuration "${CONFIGURATION}" -scheme "${PROJECT_NAME} iOS Framework" -destination 'platform=macOS,variant=Mac Catalyst'

# Create a command to build XCFramework.
for SDK in iphoneos iphonesimulator appletvos appletvsimulator macOS maccatalyst; do
  FRAMEWORK_PATH="${BUILD_DIR}/${CONFIGURATION}-${SDK}/${PRODUCT_NAME}.framework"
  XC_FRAMEWORKS+=( -framework "${FRAMEWORK_PATH}")
done

# Build XCFramework.
xcodebuild -create-xcframework "${XC_FRAMEWORKS[@]}" -output "${PRODUCTS_DIR}/${PROJECT_NAME}.xcframework"

# Copy license and readme.
cp -f "${SRCROOT}/../LICENSE" "${PRODUCTS_DIR}"
cp -f "${SRCROOT}/../README.md" "${PRODUCTS_DIR}"
cp -f "${SRCROOT}/../CHANGELOG.md" "${PRODUCTS_DIR}"

