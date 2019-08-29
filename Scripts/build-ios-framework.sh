#!/bin/sh

# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.
set -e

# Load custom build config.
if [ -r "${SRCROOT}/../.build_config" ]; then
  source "${SRCROOT}/../.build_config"
  echo "MS_ARM64E_XCODE_PATH: " $MS_ARM64E_XCODE_PATH
else
  echo "Couldn't find custom build config"
fi

# Sets the target folders and the final framework product.
TARGET_NAME="${PROJECT_NAME} iOS Framework"
RESOURCE_BUNDLE="${PROJECT_NAME}Resources"

echo "Building ${TARGET_NAME}."

# Install dir will be the final output to the framework.
# The following line create it in the root folder of the current project.
PRODUCTS_DIR="${SRCROOT}/../AppCenter-SDK-Apple/iOS"

# Working dir will be deleted after the framework creation.
WORK_DIR=build
DEVICE_DIR="${WORK_DIR}/Release-iphoneos/"
SIMULATOR_DIR="${WORK_DIR}/Release-iphonesimulator/"

# Make sure we're inside $SRCROOT.
cd "${SRCROOT}"

# Cleaning previous build.
xcodebuild -project "${PROJECT_NAME}.xcodeproj" -configuration "Release" -target "${TARGET_NAME}" clean

# Building both architectures.
xcodebuild -project "${PROJECT_NAME}.xcodeproj" -configuration "Release" -target "${TARGET_NAME}" -sdk iphoneos
xcodebuild -project "${PROJECT_NAME}.xcodeproj" -configuration "Release" -target "${TARGET_NAME}" -sdk iphonesimulator

# Cleaning the previous build.
if [ -d "${PRODUCTS_DIR}/${PROJECT_NAME}.framework" ]; then
  rm -rf "${PRODUCTS_DIR}/${PROJECT_NAME}.framework"
fi

# Creates and renews the final product folder.
mkdir -p "${PRODUCTS_DIR}"

# Copy framework.
cp -R "${DEVICE_DIR}/${PROJECT_NAME}.framework" "${PRODUCTS_DIR}"

# Copy the resource bundle for App Center Distribute.
if [ -d "${SRCROOT}/${DEVICE_DIR}/${RESOURCE_BUNDLE}.bundle" ]; then
  echo "Copying resource bundle."
  cp -R "${SRCROOT}/${DEVICE_DIR}/${RESOURCE_BUNDLE}.bundle" "${PRODUCTS_DIR}" || true
fi

# Create the arm64e slice in Xcode 10.1 and lipo it with the device binary that was created with oldest supported Xcode version.
if [ -z "$MS_ARM64E_XCODE_PATH" ] || [ ! -d "$MS_ARM64E_XCODE_PATH" ]; then
  echo "Environment variable MS_ARM64E_XCODE_PATH not set or not a valid path."
  echo "Use current Xcode version and lipo -create the fat binary."
  lipo -create "${DEVICE_DIR}/${PROJECT_NAME}.framework/${PROJECT_NAME}" "${SIMULATOR_DIR}/${PROJECT_NAME}.framework/${PROJECT_NAME}" -output "${PRODUCTS_DIR}/${PROJECT_NAME}.framework/${PROJECT_NAME}"
else

  # Grep the output of `lipo -archs` if it contains "arm64e". If it does, don't build for arm64e again.
# DOES_CONTAIN_ARM64E=`env DEVELOPER_DIR="$MS_ARM64E_XCODE_PATH" /usr/bin/lipo -archs "${LIB_IPHONEOS_FINAL}" | grep arm64e`
#if [ ! -z "${DOES_CONTAIN_ARM64E}" ]; then
#echo "The binary already contains an arm64e slice."
#else
# echo "Building the arm64e slice."

    # Move binary that was create with old Xcode to temp location.
    DEVICE_TEMP_DIR="${DEVICE_DIR}/temp"
    mkdir -p "${DEVICE_TEMP_DIR}"
    mv "${DEVICE_DIR}/${PROJECT_NAME}.framework/${PROJECT_NAME}" "${DEVICE_TEMP_DIR}/${PROJECT_NAME}"

    # Build with the Xcode version that supports arm64e.
    env DEVELOPER_DIR="${MS_ARM64E_XCODE_PATH}" /usr/bin/xcodebuild ARCHS="arm64e" -project "${PROJECT_NAME}.xcodeproj" -configuration "Release" -target "${TARGET_NAME}" --verbose

    # Lipo the binaries that were built with various Xcode versions.
    env DEVELOPER_DIR="${MS_ARM64E_XCODE_PATH}" lipo -create "${DEVICE_TEMP_DIR}/${PROJECT_NAME}" "${DEVICE_DIR}/${PROJECT_NAME}.framework/${PROJECT_NAME}" -output "${PRODUCTS_DIR}/${PROJECT_NAME}.framework/${PROJECT_NAME}"
  fi

  echo "Use arm64e Xcode and lipo -create the fat binary."
  env DEVELOPER_DIR="$MS_ARM64E_XCODE_PATH" lipo -create "${DEVICE_DIR}/${PROJECT_NAME}.framework/${PROJECT_NAME}" "${SIMULATOR_DIR}/${PROJECT_NAME}.framework/${PROJECT_NAME}" -output "${PRODUCTS_DIR}/${PROJECT_NAME}.framework/${PROJECT_NAME}"

# End of arm64e code block.
fi
