#!/bin/sh

# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

# Updates SDK version.
# Usage: update-version.sh -v <new-version>

help() {
  echo "Usage: $0 -v <new-version>"
}

## Check parameters
new_version=""
while getopts 'v:' flag; do
  case "${flag}" in
    v)
      new_version=${OPTARG}
      ;;
    *)
      help
      exit 1
      ;;
  esac
done

if [ "$new_version" == "" ]; then
  help
  exit 1
fi

PROJECT_DIR="$(dirname "$0")/.."
DOCUMENT_DIR="$PROJECT_DIR/Documentation"
PODSPEC_FILE="$PROJECT_DIR/AppCenter.podspec"
SWIFTPM_FILE="$PROJECT_DIR/Package.swift"

# Update framework version
$(dirname "$0")/framework-version.sh $new_version

# Update documentation version
for file in `find $DOCUMENT_DIR -name '.jazzy.yaml' -type f`; do
  sed -i '' 's/\(module_version: \).*/\1'$new_version'/g' $file
done

# Update CocoaPods version
sed -i '' "s/\(\.version[[:space:]]*= \)\'.*\'$/\1'$new_version'/1" $PODSPEC_FILE

# Update SwiftPM version
sed -i '' 's/\(define("APP_CENTER_C_VERSION",[[:space:]]*to:*\).*/\1''"\\"'$new_version'\\""),''/g' $SWIFTPM_FILE
