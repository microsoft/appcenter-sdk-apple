#!/bin/sh

# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

# Cleaning the previous builds.
rm -rf "${BUILT_PRODUCTS_DIR}/${PROJECT_NAME}.xcframework"

# Create a command to build XCFramework.
function add_framework() {
  local framework_path="$1/${PRODUCT_NAME}.framework"
  [ -e "${framework_path}" ] && XC_FRAMEWORKS+=( -framework "${framework_path}")
}
add_framework "${BUILD_DIR}/${CONFIGURATION}"
for SDK in iphoneos iphonesimulator appletvos appletvsimulator maccatalyst; do
  add_framework "${BUILD_DIR}/${CONFIGURATION}-${SDK}"
done

# Build XCFramework.
xcodebuild -create-xcframework "${XC_FRAMEWORKS[@]}" -output "${BUILT_PRODUCTS_DIR}/${PROJECT_NAME}.xcframework"

# Copy the resource bundle.
BUNDLE_NAME="${PROJECT_NAME}Resources.bundle"
BUNDLE_PATH="${BUILD_DIR}/${CONFIGURATION}-iphoneos/${BUNDLE_NAME}"
if [ -e "${BUNDLE_PATH}" ]; then
  rm -rf "${BUILT_PRODUCTS_DIR}/${BUNDLE_NAME}"
  cp -Rv "${BUNDLE_PATH}" "${BUILT_PRODUCTS_DIR}"
fi
echo "Cleanup resource bundles inside frameworks"
rm -rfv "${BUILT_PRODUCTS_DIR}/${PROJECT_NAME}.xcframework/*/${PRODUCT_NAME}.framework/${BUNDLE_NAME}"
