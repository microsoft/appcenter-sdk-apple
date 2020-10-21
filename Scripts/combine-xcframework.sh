#!/bin/sh
set -e

# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

# Remove the previous version of the xcframework.
rm -rf "${BUILT_PRODUCTS_DIR}/${PRODUCT_NAME}.xcframework"

# Combine all frameworks into xcframework.
for sdk in iphoneos iphonesimulator appletvos appletvsimulator macosx maccatalyst; do
  framework_path="${BUILD_DIR}/${CONFIGURATION}-${sdk}/${PRODUCT_NAME}.framework"
  xcframeworks+=( -framework "${framework_path}")
done
xcodebuild -create-xcframework "${xcframeworks[@]}" -output "${BUILT_PRODUCTS_DIR}/${PRODUCT_NAME}.xcframework"
