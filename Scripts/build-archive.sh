#!/bin/bash

# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

PROJECT_DIR="$(dirname "$0")/.."
PRODUCT_NAME="AppCenter-SDK-Apple"
PRODUCTS_DIR="${PROJECT_DIR}/${PRODUCT_NAME}"
VERSION_FILE="${PROJECT_DIR}/Config/Version.xcconfig"
VERSION=`grep "VERSION_STRING" "${VERSION_FILE}" | head -1 | awk -F "[= ]" '{print $4}'`

function archive() {
    # Create temporary directory.
    local TEMP_DIR=$(mktemp -d -t $1)
    mkdir -p "${TEMP_DIR}/${PRODUCT_NAME}"

    # Copy required files.
    cp "${PROJECT_DIR}/LICENSE" "${TEMP_DIR}/${PRODUCT_NAME}"
    cp "${PROJECT_DIR}/README.md" "${TEMP_DIR}/${PRODUCT_NAME}"
    cp "${PROJECT_DIR}/CHANGELOG.md" "${TEMP_DIR}/${PRODUCT_NAME}"
    cp -R "${@:2}" "${TEMP_DIR}/${PRODUCT_NAME}"

    # Remmove old archive if exists.
    if [ -f "${PRODUCTS_DIR}/$1" ]; then
        rm "${PRODUCTS_DIR}/$1"
    fi

    # Zip content.
    (cd "${TEMP_DIR}" && zip -9 -r -y "$1" "${PRODUCT_NAME}")
    mv "${TEMP_DIR}/$1" "${PRODUCTS_DIR}"

    # Remove temporary directory.
    rm -rf "${TEMP_DIR}"
}

# Archive fat frameworks for CocoaPods.
archive "${PRODUCT_NAME}-${VERSION}.zip" "${PRODUCT_NAME}/iOS" "${PRODUCT_NAME}/macOS" "${PRODUCT_NAME}/tvOS"

# Move Distribute resources
mv "${PRODUCTS_DIR}/iOS/AppCenterDistributeResources.bundle" \
    "${PRODUCTS_DIR}/iOS/AppCenterDistribute.framework/AppCenterDistributeResources.bundle"

# Archive fat frameworks for Carthage.
archive "${PRODUCT_NAME}-${VERSION}.carthage.framework.zip" "${PRODUCT_NAME}/iOS" "${PRODUCT_NAME}/macOS" "${PRODUCT_NAME}/tvOS"

# Archive XCFrameworks.
archive "${PRODUCT_NAME}-XCFramework-${VERSION}.zip" $(ls -d "${PRODUCT_NAME}/XCFramework"/*)
