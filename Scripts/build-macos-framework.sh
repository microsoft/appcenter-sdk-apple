#!/bin/sh

# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

# Sets the target folders and the final framework product.
TARGET_NAME="${PROJECT_NAME} macOS Framework"

echo "Building ${TARGET_NAME}."

# Install dir will be the final output to the framework.
# The following line create it in the root folder of the current project.
PRODUCTS_DIR=${SRCROOT}/../AppCenter-SDK-Apple/macOS

# Working dir will be deleted after the framework creation.
WORK_DIR=build
DEVICE_DIR="${WORK_DIR}/Release/${PROJECT_NAME}"

# Make sure we're inside $SRCROOT.
cd "${SRCROOT}"

# Cleaning previous build.
xcodebuild -project "${PROJECT_NAME}.xcodeproj" -configuration "Release" -target "${TARGET_NAME}" clean

# Building both architectures.
xcodebuild -project "${PROJECT_NAME}.xcodeproj" -configuration "Release" -target "${TARGET_NAME}"

# Cleaning the previous build.
if [ -d "${PRODUCTS_DIR}/${PROJECT_NAME}.framework" ]; then
  rm -rf "${PRODUCTS_DIR}/${PROJECT_NAME}.framework"
fi

# Creates and renews the final product folder.
mkdir -p "${PRODUCTS_DIR}"

# Copy framework.
cp -R "${DEVICE_DIR}/${PROJECT_NAME}.framework" "${PRODUCTS_DIR}"
