#!/bin/bash

## I. Check parameter
if [ -z $1 ] || ( [ "$1" != "internal" ] && [ "$1" != "external" ] ); then
  echo "Invalid parameter.";
  echo "  Usage: $0 {internal|external}";
  exit 1;
fi

## II. Get publish version for information
publish_version="$(grep "VERSION_STRING" $BITRISE_SOURCE_DIR/$VERSION_FILENAME | head -1 | awk -F "[= ]" '{print $4}')"
echo "Publishing podspec for version" $publish_version

if [ "$1" == "internal" ]; then

  ## 1. Get path of internal podspec local repo
  local_repo_path="$(pod repo | grep "$GIT_SPEC_REPO_NAME" | grep Path | head -1 | awk -F ": " '{print $2}')"

  ## 2. Update podspec to the internal podspec local repo
  resp="$(pod repo push $GIT_SPEC_REPO_NAME $BITRISE_SOURCE_DIR/$PODSPEC_FILENAME)"
  echo $resp

  # Check error from the response
  error="$(echo $resp | grep -i 'error\|fatal')"
  if [ "$error" ]; then
    echo "Cannot publish to internal repo"
    exit 1
  fi

  ## 3. Push podspec to the internal podspec remote repo
  cd $local_repo_path
  git push
  cd $BITRISE_SOURCE_DIR

  echo "Podspec published to internal repo successfully"

else

  ## 1. Run lint to validate podspec.
  resp="$(pod spec lint $BITRISE_SOURCE_DIR/$PODSPEC_FILENAME)"
  echo $resp

  # Check error from the response
  error="$(echo $resp | grep -i 'error\|fatal')"
  if [ "$error" ]; then
    echo "Cannot publish to CocoaPods due to spec validation failure"
    exit 1
  fi

  ## 2. Push podspec to CocoaPods
  resp="$(pod trunk push $BITRISE_SOURCE_DIR/$PODSPEC_FILENAME)"
  echo $resp

  # Check error from the response
  error="$(echo $resp | grep -i 'error\|fatal')"
  if [ "$error" ]; then
    echo "Cannot publish to CocoaPods"
    exit 1
  fi

  echo "Podspec published to CocoaPods successfully"

fi
