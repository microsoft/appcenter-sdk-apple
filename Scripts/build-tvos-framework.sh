#!/bin/sh

# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.
set -e

# Sets the target folders and the final framework product.
TARGET_NAME="${PROJECT_NAME} tvOS Framework"

echo "Building ${TARGET_NAME}."

# Install dir will be the final output to the framework.
# The following line create it in the root folder of the current project.
PRODUCTS_DIR="${SRCROOT}/../AppCenter-SDK-Apple/tvOS"
OUTPUT_DIR="${SRCROOT}/../AppCenter-SDK-Apple/output"

# Working dir will be deleted after the framework creation.
WORK_DIR=build
OUTPUT_DEVICE_DIR="${OUTPUT_DIR}/${CONFIGURATION}-appletvos/"
OUTPUT_SIMULATOR_DIR="${OUTPUT_DIR}/${CONFIGURATION}-appletvsimulator/"

# Make sure we're inside $SRCROOT.
cd "${SRCROOT}"

# Cleaning the previous build.
if [ -d "${PRODUCTS_DIR}/${PROJECT_NAME}.framework" ]; then
  rm -rf "${PRODUCTS_DIR}/${PROJECT_NAME}.framework"
fi
if [ -d "${OUTPUT_DEVICE_DIR}/${PROJECT_NAME}.framework" ]; then
  rm -rf "${OUTPUT_DEVICE_DIR}/${PROJECT_NAME}.framework"
fi
if [ -d "${OUTPUT_SIMULATOR_DIR}/${PROJECT_NAME}.framework" ]; then
  rm -rf "${OUTPUT_SIMULATOR_DIR}/${PROJECT_NAME}.framework"
fi

# Creates and renews the final product folder.
mkdir -p "${PRODUCTS_DIR}"

# Create temp directories.
mkdir -p "${OUTPUT_DEVICE_DIR}"
mkdir -p "${OUTPUT_SIMULATOR_DIR}"

# Clean build.
xcodebuild -project "${PROJECT_NAME}.xcodeproj" -configuration "${CONFIGURATION}" -target "${TARGET_NAME}" clean

# Building both architectures.
xcodebuild -project "${PROJECT_NAME}.xcodeproj" -configuration "${CONFIGURATION}" -target "${TARGET_NAME}" -sdk appletvos CONFIGURATION_BUILD_DIR="${OUTPUT_DEVICE_DIR}"
xcodebuild -project "${PROJECT_NAME}.xcodeproj" -configuration "${CONFIGURATION}" -target "${TARGET_NAME}" -sdk appletvsimulator CONFIGURATION_BUILD_DIR="${OUTPUT_SIMULATOR_DIR}"

# Copy framework.
cp -R "${OUTPUT_DEVICE_DIR}/${PROJECT_NAME}.framework" "${PRODUCTS_DIR}"

# # Uses the Lipo Tool to merge both binary files (i386/x86_64 + armv7/armv7s/arm64) into one Universal final product.
lipo -create "${OUTPUT_DEVICE_DIR}/${PROJECT_NAME}.framework/${PROJECT_NAME}" "${OUTPUT_SIMULATOR_DIR}/${PROJECT_NAME}.framework/${PROJECT_NAME}" -output "${PRODUCTS_DIR}/${PROJECT_NAME}.framework/${PROJECT_NAME}"