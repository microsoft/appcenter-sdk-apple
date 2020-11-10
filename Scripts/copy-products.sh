#!/bin/sh

# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

set -e

# The directory for final output.
PRODUCTS_DIR="${SRCROOT}/../AppCenter-SDK-Apple"

copy_framework() {
  if [ ! -e "$1/${PROJECT_NAME}.$3" ]; then
    return
  fi
  rm -rf "$2/${PROJECT_NAME}.$3"
  mkdir -p "$2"
  cp -RHv "$1/${PROJECT_NAME}.$3" "$2"
  if [ -e "$1/${PROJECT_NAME}Resources.bundle" ]; then
    rm -rf "$2/${PROJECT_NAME}Resources.bundle"
    cp -Rv "$1/${PROJECT_NAME}Resources.bundle" "$2"
  fi
}
copy_framework "${BUILD_DIR}/${CONFIGURATION}-iphoneuniversal" "${PRODUCTS_DIR}/iOS" "framework"
copy_framework "${BUILD_DIR}/${CONFIGURATION}" "${PRODUCTS_DIR}/macOS" "framework"
copy_framework "${BUILD_DIR}/${CONFIGURATION}-appletvuniversal" "${PRODUCTS_DIR}/tvOS" "framework"
copy_framework "${BUILD_DIR}/${CONFIGURATION}-xcframework" "${PRODUCTS_DIR}/XCFramework" "xcframework"
