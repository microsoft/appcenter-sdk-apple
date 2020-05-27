#!/bin/bash

# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

# Gets or sets framework version.
# Usage: framework-version.sh               - to get the current version
#        framework-version.sh <version>     - to set the version

PROJECT_DIR="$(dirname "$0")/.."
VERSION_CONFIG="$PROJECT_DIR/Config/Version.xcconfig"
if [ -z $1 ]; then
  grep "VERSION_STRING" "$VERSION_CONFIG" | head -1 | awk -F "[= ]" '{print $4}'
else
  sed -i '' 's/\(VERSION_STRING[[:space:]]*=[[:space:]]*\).*/\1'$1'/g' $VERSION_CONFIG
fi
