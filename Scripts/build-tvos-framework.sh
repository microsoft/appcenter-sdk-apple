#!/bin/sh

# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.
set -e

# Sets the target folders and the final framework product.
TARGET_NAME="${PROJECT_NAME} tvOS Framework"

echo "Building ${TARGET_NAME}."

# Install dir will be the final output to the framework.
# The following line create it in the root folder of the current project.
PRODUCTS_DIR=${SRCROOT}/../AppCenter-SDK-Apple/tvOS

# Dir to gather all frameworks and build it into xcframework.
XCFRAMEWORK_DIR="${SRCROOT}/../AppCenter-SDK-Apple/xcframework"

# Working dir will be deleted after the framework creation.
WORK_DIR=build
DEVICE_DIR="${WORK_DIR}/Release-appletvos/"
SIMULATOR_DIR="${WORK_DIR}/Release-appletvsimulator/"

# Make sure we're inside $SRCROOT.
cd "${SRCROOT}"

# Cleaning previous build.
xcodebuild -project "${PROJECT_NAME}.xcodeproj" -configuration "Release" -target "${TARGET_NAME}" clean

# Building both architectures.
xcodebuild -project "${PROJECT_NAME}.xcodeproj" -configuration "Release" -target "${TARGET_NAME}" -sdk appletvos 
xcodebuild -project "${PROJECT_NAME}.xcodeproj" -configuration "Release" -target "${TARGET_NAME}" -sdk appletvsimulator 

# Cleaning the previous build.
if [ -d "${PRODUCTS_DIR}/${PROJECT_NAME}.framework" ]; then
  rm -rf "${PRODUCTS_DIR}/${PROJECT_NAME}.framework"
fi

# Creates and renews the final product folder.
mkdir -p "${PRODUCTS_DIR}"

# Copy framework.
cp -R "${DEVICE_DIR}/${PROJECT_NAME}.framework" "${PRODUCTS_DIR}"

mkdir -p "${XCFRAMEWORK_DIR}"

# Copy all framework files to use them for xcframework file creation.
cp -R "${WORK_DIR}/" "${XCFRAMEWORK_DIR}"

# Uses the Lipo Tool to merge both binary files (i386/x86_64 + armv7/armv7s/arm64) into one Universal final product.
lipo -create "${DEVICE_DIR}/${PROJECT_NAME}.framework/${PROJECT_NAME}" "${SIMULATOR_DIR}/${PROJECT_NAME}.framework/${PROJECT_NAME}" -output "${PRODUCTS_DIR}/${PROJECT_NAME}.framework/${PROJECT_NAME}"
