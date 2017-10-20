#!/bin/bash

## Queue MobileCenter build for objective c app

## 1. Run a build
echo "Building" $MOBILE_CENTER_SASQUATCHOBJC_BUILD_APP_ID
resp="$(mobile-center build queue --token $MOBILE_CENTER_ACCESS_TOKEN --branch $BITRISE_GIT_BRANCH --app $MOBILE_CENTER_SASQUATCHOBJC_BUILD_APP_ID)"

## 2. Check an error
error="$(echo $resp | grep Error:\ failed)";
if [ "$error" ]; then
  if [ "$BITRISE_GIT_BRANCH" == "master" ] || [ "$BITRISE_GIT_BRANCH" == "develop" ]; then
    echo $error;
    exit 1;
  else
    echo "Failed to queue a build to MobileCenter."
    echo "Maybe" $BITRISE_GIT_BRANCH "doesn't have build configured yet, skip the build."
  fi
fi

# Queue MobileCenter build for swift app

## 1. Run a build
echo "Building" $MOBILE_CENTER_SASQUATCHSWIFT_BUILD_APP_ID
resp="$(mobile-center build queue --token $MOBILE_CENTER_ACCESS_TOKEN --branch $BITRISE_GIT_BRANCH --app $MOBILE_CENTER_SASQUATCHSWIFT_BUILD_APP_ID)"

## 2. Check an error
error="$(echo $resp | grep Error:\ failed)";
if [ "$error" ]; then
  if [ "$BITRISE_GIT_BRANCH" == "master" ] || [ "$BITRISE_GIT_BRANCH" == "develop" ]; then
    echo $error;
    exit 1;
  else
    echo "Failed to queue a build to MobileCenter."
    echo "Maybe" $BITRISE_GIT_BRANCH "doesn't have build configured yet, skip the build."
  fi
fi
