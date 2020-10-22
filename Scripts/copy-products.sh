#!/bin/sh
set -e

# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

# Clean
rm -rf "$BUILT_PRODUCTS_DIR"
mkdir -p "$BUILT_PRODUCTS_DIR"

# Universal frameworks
mkdir -p "$BUILT_PRODUCTS_DIR/iOS Framework"
cp -R "$BUILD_DIR/$CONFIGURATION-iphoneuniversal/$PROJECT_NAME.framework" "$BUILT_PRODUCTS_DIR/iOS Framework"

mkdir -p "$BUILT_PRODUCTS_DIR/tvOS Framework"
cp -R "$BUILD_DIR/$CONFIGURATION-appletvuniversal/$PROJECT_NAME.framework" "$BUILT_PRODUCTS_DIR/tvOS Framework"

# Dynamic macOS framework
mkdir -p "$BUILT_PRODUCTS_DIR/Mac OS X Framework"
cp -R "$BUILD_DIR/$CONFIGURATION-macosx/$PROJECT_NAME.framework" "$BUILT_PRODUCTS_DIR/Mac OS X Framework"

# XCFrameowrk
cp -R "$BUILD_DIR/$CONFIGURATION-xcframework/$PROJECT_NAME.xcframework" "$BUILT_PRODUCTS_DIR"
