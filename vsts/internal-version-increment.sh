#!/bin/bash

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
build_number=0
resp="$(curl -s $INTERNAL_RELEASE_VERSION_FILENAME)"
version="$(echo $resp | jq -r '.version')"

# Exit if response doesn't contain an array
if [ -z $version ] || [ "$version" == "" ] || [ "$version" == "null" ]; then
  echo "Cannot retrieve the latest version"
  echo "Response:" $resp
  exit 1
fi

# Determine the next version
if [[ "$version" == $publish_version-* ]]; then
  build_number="$(echo $version | awk -F "[-]" '{print $2}')"
  build_number=$(($build_number + 1))
fi

publish_version=$publish_version-$build_number
echo "New version:" $publish_version
echo "##vso[task.setvariable variable=SDK_PUBLISH_VERSION]$publish_version"

## III. Update version file
echo {\"version\":\"$publish_version\"} > $AZURE_APPLE_VERSION_FILE
azure telemetry --disable
echo "Y" | azure storage blob upload $AZURE_APPLE_VERSION_FILE sdk
rm $AZURE_APPLE_VERSION_FILE

## IV. Update version for frameworks

if [ "$BUILD_SOURCEBRANCHNAME" != "master" ]; then
  sed -i '' 's/\(VERSION_STRING[[:space:]]*=[[:space:]]*\).*/\1'$publish_version'/g' $VERSION_FILENAME
fi
