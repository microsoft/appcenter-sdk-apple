#!/bin/bash

# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

# Creates zip archives from frameworks.
# Usage: build-archive.sh

PROJECT_DIR="$(dirname "$0")/.."
PRODUCT_NAME="AppCenter-SDK-Apple"
PRODUCTS_DIR="$PROJECT_DIR/$PRODUCT_NAME"

# Creates zip archive.
# Usage: archive <result-name> <list-of-content>
function archive() {
  echo "Creating $1 archive from ${@:2}"

  # Create temporary directory.
  local temp_dir=$(mktemp -d -t $1)
  mkdir -p "$temp_dir/$PRODUCT_NAME"

  # Copy required files.
  cp "$PROJECT_DIR/LICENSE" "$temp_dir/$PRODUCT_NAME"
  cp "$PROJECT_DIR/README.md" "$temp_dir/$PRODUCT_NAME"
  cp "$PROJECT_DIR/CHANGELOG.md" "$temp_dir/$PRODUCT_NAME"
  cp -R "${@:2}" "$temp_dir/$PRODUCT_NAME"

  # Remmove old archive if exists.
  if [ -f "$PRODUCTS_DIR/$1" ]; then
    rm "$PRODUCTS_DIR/$1"
  fi

  # Zip content.
  (cd "$temp_dir" && zip -9 -r -y "$1" "$PRODUCT_NAME")
  mv "$temp_dir/$1" "$PRODUCTS_DIR"

  # Remove temporary directory.
  rm -rf "$temp_dir"
}

# Check if the frameworks are already built.
if [ ! -d "$PRODUCTS_DIR/iOS" ] || [ ! -d "$PRODUCTS_DIR/macOS" ] || [ ! -d "$PRODUCTS_DIR/macOS" ] || [ ! -d "$PRODUCTS_DIR/XCFramework" ]; then
  echo "Cannot find frameworks to archive, please run build first"
  exit 1
fi

# Get current version.
VERSION="$($(dirname "$0")/framework-version.sh)"

# Archive fat frameworks for CocoaPods.
archive "$PRODUCT_NAME-${VERSION}.zip" "$PRODUCT_NAME/iOS" "$PRODUCT_NAME/macOS" "$PRODUCT_NAME/tvOS"

# Archive fat frameworks for Carthage.
mv "$PRODUCTS_DIR/iOS/AppCenterDistributeResources.bundle" "$PRODUCTS_DIR/iOS/AppCenterDistribute.framework"
archive "$PRODUCT_NAME-${VERSION}.carthage.framework.zip" "$PRODUCT_NAME/iOS" "$PRODUCT_NAME/macOS" "$PRODUCT_NAME/tvOS"

# Archive XCFrameworks.
archive "$PRODUCT_NAME-XCFramework-${VERSION}.zip" $(ls -d "$PRODUCT_NAME/XCFramework"/*)
