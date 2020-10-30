#!/bin/bash

# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

# Creates zip archives from frameworks.
# Usage: create-archive.sh

PROJECT_DIR="$(dirname "$0")/.."
PRODUCT_NAME="AppCenter-SDK-Apple"
PRODUCTS_DIR="$PROJECT_DIR/$PRODUCT_NAME"

# Enable extended globbing.
shopt -s extglob nullglob

# Check if the frameworks are already built.
if [ ! -d "$PRODUCTS_DIR/iOS" ] || [ ! -d "$PRODUCTS_DIR/macOS" ] || \
    [ ! -d "$PRODUCTS_DIR/tvOS" ] || [ ! -d "$PRODUCTS_DIR/XCFramework" ]; then
  echo "Cannot find frameworks to archive, please run build first"
  exit 1
fi

# Check if resource bundles are there.
if [ ! -d "$PRODUCTS_DIR/iOS/AppCenterDistribute.framework/AppCenterDistributeResources.bundle" ] || \
    [ ! -d "$PRODUCTS_DIR/XCFramework/AppCenterDistributeResources.bundle" ]; then
  echo "Cannot find resource bundles to archive, please run build first"
  exit 1
fi

# Verify prefix for framework classes.
framework_classes() {
  nm -gjoUC "$1" | awk '{print $2}' | grep "_OBJC_CLASS_" | cut -d_ -f5-
}
verify_framework_prefixes() {
  local name=${1##*/}
  name=${name%.*}
  local classes=$(framework_classes "$1/$name")
  for prefix in ${@:2}; do
    classes=$(echo "$classes" | grep -v $prefix)
  done
  echo "$classes"
  [ -z "$classes" ]
}
for framework in $PRODUCTS_DIR/**/*.framework; do
  invalid_prefix_classes+=($(verify_framework_prefixes "$framework" "MSAC" "MSPL")) || invalid_prefix_framework+=(${framework#"$PRODUCTS_DIR"/})
done
if [ ${#invalid_prefix_framework[@]} -ne 0 ]; then
  echo "There are frameworks that contain classes without required prefix: ${invalid_prefix_framework[@]}"
  echo "Please fix the prefix for the following classes:"
  printf '%s\n' "${invalid_prefix_classes[@]}" | sort | uniq
  # TODO uncomment before release.
  # exit 1
fi

# Verify bitcode.
function verify_bitcode() {
  local name=${1##*/}
  name=${name%.*}
  otool -l "$1/$name" | grep __LLVM > /dev/null
}
for framework in \
    $PRODUCTS_DIR/iOS/*.framework \
    $PRODUCTS_DIR/tvOS/*.framework \
    $PRODUCTS_DIR/XCFramework/*.xcframework/ios-!(*-*)/*.framework \
    $PRODUCTS_DIR/XCFramework/*.xcframework/tvos-!(*-*)/*.framework; do
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

# Verify architectures.
function verify_framework_architectures() {
  local name=${1##*/}
  name=${name%.*}
  local archs=($(lipo -archs "$1/$name"))
  archs=($(printf '%s\n' "${archs[@]}" | sort))
  required=($(printf '%s\n' "${@:2}" | sort))
  if [[ "${archs[@]}" != "${required[@]}" ]]; then
    echo "${1#$PRODUCTS_DIR/} doesn't contain required architectures. It has '${archs[@]}' but '${required[@]}' are required."
    return 1
  fi
}
function verify_architectures() {
  for framework in $PRODUCTS_DIR/$1; do
    verify_framework_architectures "$framework" ${@:2} || return $?
  done
}
verify_architectures "iOS/*.framework" armv7 armv7s arm64 arm64e i386 x86_64 || exit $?
verify_architectures "macOS/*.framework" arm64 x86_64 || exit $?
verify_architectures "tvOS/*.framework" arm64 x86_64 || exit $?
verify_architectures "XCFramework/*.xcframework/ios-!(*-*)/*.framework" armv7 armv7s arm64 arm64e || exit $?
verify_architectures "XCFramework/*.xcframework/ios-*-maccatalyst/*.framework" arm64 x86_64 || exit $?
verify_architectures "XCFramework/*.xcframework/ios-*-simulator/*.framework" arm64 i386 x86_64 || exit $?
verify_architectures "XCFramework/*.xcframework/macos-*/*.framework" arm64 x86_64 || exit $?
verify_architectures "XCFramework/*.xcframework/tvos-!(*-*)/*.framework" arm64 || exit $?
verify_architectures "XCFramework/*.xcframework/tvos-*-simulator/*.framework" arm64 x86_64 || exit $?

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
  (cd "$PROJECT_DIR" && cp -R "${@:2}" "$temp_dir/$PRODUCT_NAME")

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

# Archive fat frameworks for Carthage.
archive "$PRODUCT_NAME-$VERSION.carthage.framework.zip" "$PRODUCT_NAME/iOS" "$PRODUCT_NAME/macOS" "$PRODUCT_NAME/tvOS"

# Archive fat frameworks for CocoaPods.
mv "$PRODUCTS_DIR/iOS/AppCenterDistribute.framework/AppCenterDistributeResources.bundle" "$PRODUCTS_DIR/iOS"
archive "$PRODUCT_NAME-$VERSION.zip" "$PRODUCT_NAME/iOS" "$PRODUCT_NAME/macOS" "$PRODUCT_NAME/tvOS"
mv "$PRODUCTS_DIR/iOS/AppCenterDistributeResources.bundle" "$PRODUCTS_DIR/iOS/AppCenterDistribute.framework"

# Archive XCFrameworks.
archive "$PRODUCT_NAME-XCFramework-$VERSION.zip" $(cd "$PROJECT_DIR" && ls -d "$PRODUCT_NAME/XCFramework"/*)

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
