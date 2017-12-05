#!/bin/bash

## INCREMENT_VERSION environment variable is only available for publish-internal workflow.
if [ "$INCREMENT_VERSION" == "true" ]; then

  ## 1. Get the latest version
  echo "Get the latest version to determine a build number"
  publish_version="$(grep "VERSION_STRING" $BITRISE_SOURCE_DIR/$VERSION_FILENAME | head -1 | awk -F "[= ]" '{print $4}')"
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
  envman add --key SDK_PUBLISH_VERSION --value "$publish_version"

  ## 2. Update version file
  echo {\"version\":\"$publish_version\"} > ios_version.txt
  azure telemetry --disable
  echo "Y" | azure storage blob upload ios_version.txt sdk
  rm ios_version.txt

  ## 3. Update version for frameworks

  if [ "$BITRISE_GIT_BRANCH" != "master" ]; then
    sed "s/\(VERSION_STRING[[:space:]]*=[[:space:]]*\).*/\1$publish_version/g" Config/Version.xcconfig > Config/Version.xcconfig.tmp; mv Config/Version.xcconfig.tmp Config/Version.xcconfig
  fi

else

  echo "Doesn't require version increment for this build. Skip this step."

fi