#!/bin/bash

# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

# Creates zip archives from frameworks.
# Usage: build-archive.sh

PROJECT_DIR="$(dirname "$0")/.."
PRODUCT_NAME="AppCenter-SDK-Apple"
PRODUCTS_DIR="$PROJECT_DIR/$PRODUCT_NAME"

# Check if the frameworks are already built.
if [ ! -d "$PRODUCTS_DIR/iOS" ] || [ ! -d "$PRODUCTS_DIR/macOS" ] || \
    [ ! -d "$PRODUCTS_DIR/tvOS" ] || [ ! -d "$PRODUCTS_DIR/XCFramework" ]; then
  echo "Cannot find frameworks to archive, please run build first"
  exit 1
fi

# Check if resource bundles are there.
if [ ! -d "$PRODUCTS_DIR/iOS/AppCenterDistributeResources.bundle" ] || \
    [ ! -d "$PRODUCTS_DIR/XCFramework/AppCenterDistributeResources.bundle" ]; then
  echo "Cannot find resource bundles to archive, please run build first"
  exit 1
fi

# Verify bitcode.
function verify_bitcode() {
  name=${1##*/}
  name=${name%.*}
  otool -l "$1/$name" | grep __LLVM > /dev/null
}
for framework in \
    $PRODUCTS_DIR/iOS/*.framework \
    $PRODUCTS_DIR/tvOS/*.framework \
    $PRODUCTS_DIR/XCFramework/*.xcframework/ios-arm*/*.framework \
    $PRODUCTS_DIR/XCFramework/*.xcframework/tvos-arm*/*.framework; do
  verify_bitcode "$framework" || invalid_bitcode+=(${framework#"$PRODUCTS_DIR"/})
done
if [ ${#invalid_bitcode[@]} -ne 0 ]; then
  echo "There are iOS/tvOS binaries without valid bitcode: ${invalid_bitcode[@]}"
  exit 1
fi
for framework in \
    $PRODUCTS_DIR/macOS/*.framework \
    $PRODUCTS_DIR/XCFramework/*.xcframework/macos-*/*.framework \
    $PRODUCTS_DIR/XCFramework/*.xcframework/*-maccatalyst/*.framework; do
  verify_bitcode "$framework" && invalid_bitcode+=(${framework#"$PRODUCTS_DIR"/})
done
if [ ${#invalid_bitcode[@]} -ne 0 ]; then
  echo "There are macOS binaries with bitcode (it should not be there): ${invalid_bitcode[@]}"
  exit 1
fi

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
  (cd "$temp_dir" && zip -ryq9 "$1" "$PRODUCT_NAME")
  mv "$temp_dir/$1" "$PRODUCTS_DIR"

  # Remove temporary directory.
  rm -rf "$temp_dir"
}

# Get current version.
VERSION="$($(dirname "$0")/framework-version.sh)"

# Archive fat frameworks for CocoaPods.
archive "$PRODUCT_NAME-$VERSION.zip" "$PRODUCT_NAME/iOS" "$PRODUCT_NAME/macOS" "$PRODUCT_NAME/tvOS"

# Archive fat frameworks for Carthage.
mv "$PRODUCTS_DIR/iOS/AppCenterDistributeResources.bundle" "$PRODUCTS_DIR/iOS/AppCenterDistribute.framework"
archive "$PRODUCT_NAME-$VERSION.carthage.framework.zip" "$PRODUCT_NAME/iOS" "$PRODUCT_NAME/macOS" "$PRODUCT_NAME/tvOS"
mv "$PRODUCTS_DIR/iOS/AppCenterDistribute.framework/AppCenterDistributeResources.bundle" "$PRODUCTS_DIR/iOS"

# Archive XCFrameworks.
archive "$PRODUCT_NAME-XCFramework-$VERSION.zip" $(ls -d "$PRODUCT_NAME/XCFramework"/*)

# Verify result archives.
function verify_symlinks() {
  read symlinks
  name=${1##*/}
  name=${name%.*}
  for symlink in Resources Versions/Current Headers Modules $name; do
    echo $symlinks | grep -q "$1/$symlink" || return $?
  done
}
function verify_archive() {
  echo "Verify archive: ${1##*/}"
  frameworks=$(unzip -Z1 "$1" | grep "^$PRODUCT_NAME/.*\.framework/$")

  # Verify symlinks in macOS frameworks.
  mac_frameworks=$(echo "$frameworks" | grep '/macOS/\|macos-\|-maccatalyst')
  symlinks=$(unzip -Z "$1" | grep ^l | awk '{print $9}')
  for framework in $mac_frameworks; do
    if ! verify_symlinks ${framework%/} <<< $symlinks; then
      invalid_symlinks+=(${framework%/})
    fi
  done
  if [ ${#invalid_symlinks[@]} -ne 0 ]; then
    echo "Archive contains frameworks with invalid symlinks: ${invalid_symlinks[@]}"
    return 1
  fi

  # Verify that there are no invalid files.
  invalid_files=$(unzip -Z1 "$1" | grep "$(echo \\.{a,xconfig,sh,md,txt}$ | sed 's/ /\\|/g')")
  if [ $? -eq 0 ]; then
    echo "Archive contains invalid files: $invalid_files"
    return 1
  fi
}
exit_code=0
verify_archive "$PRODUCTS_DIR/$PRODUCT_NAME-$VERSION.zip" || exit_code=$?
verify_archive "$PRODUCTS_DIR/$PRODUCT_NAME-$VERSION.carthage.framework.zip" || exit_code=$?
verify_archive "$PRODUCTS_DIR/$PRODUCT_NAME-XCFramework-$VERSION.zip" || exit_code=$?
exit $exit_code
