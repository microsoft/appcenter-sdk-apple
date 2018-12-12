#!/bin/sh

source $(dirname "$0")/../build-ios-framework.sh AppCenter

rm -r "${WRK_DIR}"

# Copy license and readme.
cp -f "${SRCROOT}/../LICENSE" "${PRODUCTS_DIR}"
cp -f "${SRCROOT}/../README.md" "${PRODUCTS_DIR}"
cp -f "${SRCROOT}/../CHANGELOG.md" "${PRODUCTS_DIR}"
