#!/bin/sh

# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

# The directory for final output of the framework.
PRODUCTS_DIR="${SRCROOT}/../AppCenter-SDK-Apple/XCFramework"

# Build result paths.
SCRIPT_BUILD_DIR="${SRCROOT}/build"

# Cleaning the previous builds.
if [ -e "${PRODUCTS_DIR}/${PROJECT_NAME}.xcframework" ]; then
  rm -rf "${PRODUCTS_DIR}/${PROJECT_NAME}.xcframework"
fi

# Creates the final product folder.
mkdir -p "${PRODUCTS_DIR}"

# Create a command to build XCFramework.
function add_framework() {
  local framework_path="$1/${PRODUCT_NAME}.framework"
  [ -e "${framework_path}" ] && XC_FRAMEWORKS+=( -framework "${framework_path}")
}
add_framework "${BUILD_DIR}/${CONFIGURATION}"
for SDK in iphoneos iphonesimulator appletvos appletvsimulator maccatalyst; do
  add_framework "${SCRIPT_BUILD_DIR}/${CONFIGURATION}-${SDK}"
done

# Build XCFramework.
xcodebuild -create-xcframework "${XC_FRAMEWORKS[@]}" -output "${PRODUCTS_DIR}/${PROJECT_NAME}.xcframework"

# Copy the resource bundle.
BUNDLE_NAME="${PROJECT_NAME}Resources.bundle"
BUNDLE_PATH="${SCRIPT_BUILD_DIR}/${CONFIGURATION}-iphoneos/${BUNDLE_NAME}"
if [ -e "${BUNDLE_PATH}" ]; then
  echo "Copying resource bundle."
  cp -R "${BUNDLE_PATH}" "${PRODUCTS_DIR}" || true
fi

# Cleanup resource bundles inside frameworks.
rm -rf "${PRODUCTS_DIR}/${PROJECT_NAME}.xcframework/**/${BUNDLE_NAME}"
