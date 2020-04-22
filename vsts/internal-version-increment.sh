#!/bin/bash

# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

help() {
  echo "Usage: $0 -a <azure-storage-account> -k <azure-storage-access-key>"
}

## I. Check Parameters
while getopts 'a:k:' flag; do
  case "${flag}" in
    a)
      export AZURE_STORAGE_ACCOUNT=${OPTARG}
      ;;
    k)
      export AZURE_STORAGE_ACCESS_KEY=${OPTARG}
      ;;
    *)
      help
      exit 1
      ;;
  esac
done

if [ "$AZURE_STORAGE_ACCOUNT" == "" ] || [ "$AZURE_STORAGE_ACCESS_KEY" == "" ]; then
  help
  exit 1
fi

## II. Get the latest version
echo "Get the latest version to determine a build number"
publish_version="$(grep "VERSION_STRING" $VERSION_FILENAME | head -1 | awk -F "[= ]" '{print $4}')"
echo "Getting the latest build number for the version: $publish_version"
zip_filename="$(echo $FRAMEWORKS_ZIP_FILENAME | cut -d. -f1)"
azure telemetry --disable

# Get all filenames for the version
resp="$(echo "Y" | azure storage blob list sdk -p $zip_filename-$publish_version --json)"

# Exit if response contains an error
if [ -z "$resp" ] || [ "$resp" == "" ] || [ "$resp" == "null" ]; then
  echo "Cannot retrieve the latest version"
  exit 1
fi

# Get the latest build number from an array of filenames
previous_filenames="$(echo $resp | jq '[ .[] | .name]')"
latest_build_number=-1
for previous_filename in $previous_filenames
do
  build_number="$(echo $previous_filename | awk -F "[-+]" '{print $5}')"
  if [ "$build_number" ] && [ $build_number -gt $latest_build_number ]; then
    latest_build_number=$build_number
  fi
done

# Increment the build number
latest_build_number=$(($latest_build_number + 1))
publish_version=$publish_version-$latest_build_number
echo "New version:" $publish_version
echo $publish_version > $CURRENT_BUILD_VERSION_FILENAME

## III. Upload placeholder for the version to avoid conflicts with ongoing merge builds
placeholder=$(echo $FRAMEWORKS_ZIP_FILENAME | sed 's/.zip/-'${publish_version}'+'$BUILD_SOURCEVERSION'.zip/g')
touch $placeholder
resp="$(echo "N" | azure storage blob upload ${placeholder} sdk | grep overwrite)"
if [ "$resp" ]; then
    echo "${placeholder} already exists"
    exit 1
fi

## IV. Update version for frameworks

if [ "$BUILD_SOURCEBRANCHNAME" != "master" ]; then
  sed -i '' 's/\(VERSION_STRING[[:space:]]*=[[:space:]]*\).*/\1'$publish_version'/g' $VERSION_FILENAME
fi
sed '/define("APP_CENTER_C_VERSION"*/c\'$'\n''dd'$'\n''' Package.swift
package_version_text='"\"'$publish_version'\""'
latest_build_number_text='"\"'$latest_build_number'\""'
sed 's/\(define("APP_CENTER_C_VERSION",[[:space:]]*to:*\).*/\1'$package_version_text'/g' Package.swift
sed 's/\(define("APP_CENTER_C_BUILD",[[:space:]]*to:*\).*/\1'$latest_build_number_text'/g' Package.swift
